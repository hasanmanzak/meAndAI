[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$suiteOwner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
$caseOwner = 'tests/capabilities/initial-adoption/source-graph-dispatch.case.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$caseContext = New-MeAndAICaseEvidenceContext -SuiteOwner $suiteOwner `
    -CaseOwner $caseOwner -TestIds @('TEST-0153') `
    -AuthorityPath $scenarioAuthorityPath
$protocolReleasePath = Join-Path $root `
    'scripts/quick-adoption/Private/ProtocolReleaseAndAssets.ps1'
$proposalOwnershipPath = Join-Path $root `
    'scripts/quick-adoption/Private/ProposalOwnership.ps1'
$nativeProcessPath = Join-Path $root `
    'scripts/quick-adoption/Private/OutputAndNativeProcess.ps1'
$repositoryAssessmentPath = Join-Path $root `
    'scripts/quick-adoption/Private/RepositoryAssessment.ps1'
$capabilitiesModulePath = Join-Path $root `
    'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$currentWorkflowPath = Join-Path $root `
    'templates/project/.github/workflows/meandai-protocol-update.yml'
$immutableGraphUnawareCommit =
    '252488a88d2a64ea8816239bbf6d953f506b8840'
$immutableWorkflowPath =
    'templates/project/.github/workflows/meandai-protocol-update.yml'

foreach ($path in @(
    $protocolReleasePath, $proposalOwnershipPath, $nativeProcessPath,
    $repositoryAssessmentPath, $capabilitiesModulePath, $currentWorkflowPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "TEST-0153 dispatch fixture is missing '$path'."
    }
}

. $protocolReleasePath
. $proposalOwnershipPath
. $repositoryAssessmentPath

function Get-GitObjectBytes {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Object
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = "show $Object"
    $startInfo.WorkingDirectory = $Repository
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $output = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) {
            throw "git show $Object did not start."
        }
        $process.StandardOutput.BaseStream.CopyTo($output)
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "git show $Object failed: $errorText"
        }
        return ,([byte[]]$output.ToArray())
    }
    finally {
        $output.Dispose()
        $process.Dispose()
    }
}

$script:DispatchArguments = @()
$script:DispatchInputText = $null
$script:DispatchCorrelationId = ''
$script:DispatchHead = ''
$script:RunListCalls = 0
$workflowTargetPath =
    '.github/workflows/meandai-protocol-update.yml'
$WorkflowTimeoutMinutes = 1

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][object[]]$Arguments,
        [AllowNull()][string]$InputText = $null,
        [switch]$AllowFailure
    )

    if ($Command -cne 'gh') {
        throw "TEST-0153 dispatch fixture received unexpected command '$Command'."
    }
    $arguments = @($Arguments | ForEach-Object { [string]$_ })
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'workflow' -and
        $arguments[1] -ceq 'view') {
        return [pscustomobject]@{ ExitCode = 0; Output = @('name: fixture') }
    }
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'workflow' -and
        $arguments[1] -ceq 'run') {
        $script:DispatchArguments = @($arguments)
        $hasInputText = $PSBoundParameters.ContainsKey('InputText')
        $script:DispatchInputText = if ($hasInputText) { $InputText } else { $null }
        if ($hasInputText) {
            try {
                $dispatchInputs = $InputText | ConvertFrom-Json
            }
            catch {
                throw 'TEST-0153 dispatch fixture received invalid JSON stdin.'
            }
            if ($null -ne $dispatchInputs.PSObject.Properties['correlation_id']) {
                $script:DispatchCorrelationId =
                    [string]$dispatchInputs.correlation_id
            }
        }
        else {
            foreach ($argument in $arguments) {
                if ($argument -match '^correlation_id=(?<id>[0-9a-f]{32})$') {
                    $script:DispatchCorrelationId = [string]$Matches.id
                }
            }
        }
        return [pscustomobject]@{ ExitCode = 0; Output = @() }
    }
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'run' -and
        $arguments[1] -ceq 'list') {
        $script:RunListCalls++
        if ($script:RunListCalls -eq 1) {
            return [pscustomobject]@{ ExitCode = 0; Output = @('[]') }
        }
        $candidate = @([ordered]@{
            databaseId = 7001
            createdAt = [DateTimeOffset]::UtcNow.ToString('o')
            displayTitle =
                "meAndAI AI capabilities lifecycle [$($script:DispatchCorrelationId)]"
            headSha = $script:DispatchHead
            status = 'completed'
            conclusion = 'success'
            url = 'https://github.com/owner/consumer/actions/runs/7001'
        }) | ConvertTo-Json -Depth 5 -Compress
        return [pscustomobject]@{ ExitCode = 0; Output = @($candidate) }
    }
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'run' -and
        $arguments[1] -ceq 'view') {
        $detail = [ordered]@{
            databaseId = 7001
            displayTitle =
                "meAndAI AI capabilities lifecycle [$($script:DispatchCorrelationId)]"
            headSha = $script:DispatchHead
            status = 'completed'
            conclusion = 'success'
            url = 'https://github.com/owner/consumer/actions/runs/7001'
        } | ConvertTo-Json -Compress
        return [pscustomobject]@{ ExitCode = 0; Output = @($detail) }
    }
    throw "TEST-0153 dispatch fixture received unexpected gh call '$($arguments -join ' ')'."
}

function Invoke-DispatchCase {
    param(
        [Parameter(Mandatory)][byte[]]$WorkflowBytes,
        [Parameter(Mandatory)][bool]$ExpectedGraphSupport,
        [Parameter(Mandatory)][string]$Label
    )

    $actualGraphSupport = Test-CanonicalWorkflowSupportsSourceGraphIdentity `
        -Bytes $WorkflowBytes
    if ($actualGraphSupport -ne $ExpectedGraphSupport) {
        throw "TEST-0153 $Label workflow graph-input feature detection was incorrect."
    }
    $script:DispatchArguments = @()
    $script:DispatchInputText = $null
    $script:DispatchCorrelationId = ''
    $script:DispatchHead = 'a' * 40
    $script:RunListCalls = 0
    $compactIdentity = [ordered]@{
        schema = 1
        graphBase = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        protocolSurfaces = @('docs/özellik.md')
    } | ConvertTo-Json -Depth 5 -Compress
    $selectedIdentity = if ($actualGraphSupport) {
        $compactIdentity
    }
    else { '' }
    $run = Invoke-LifecycleWorkflow -Repository 'owner/consumer' `
        -Branch 'main' -HeadSha $script:DispatchHead `
        -ResolvedAdoptionStrategy 'FullMigration' `
        -ProtocolRecordLossAcknowledged $false `
        -SourceGraphIdentityJson $selectedIdentity
    if ([long]$run.databaseId -ne 7001) {
        throw "TEST-0153 $Label dispatch did not converge to its exact run."
    }
    if ($script:DispatchArguments -cnotcontains '--json' -or
        $script:DispatchArguments -ccontains '--field' -or
        $script:DispatchArguments -ccontains '--raw-field' -or
        $null -eq $script:DispatchInputText) {
        throw "TEST-0153 $Label dispatch did not use one JSON stdin payload."
    }
    try {
        $inputs = $script:DispatchInputText | ConvertFrom-Json
    }
    catch {
        throw "TEST-0153 $Label dispatch stdin was invalid JSON."
    }
    $expectedProperties = @(
        'acknowledge_protocol_record_loss', 'adoption_strategy',
        'correlation_id', 'expected_base_sha'
    )
    if ($ExpectedGraphSupport) {
        $expectedProperties += 'source_graph_identity'
    }
    $actualProperties = @(
        $inputs.PSObject.Properties.Name | Sort-Object
    )
    $expectedProperties = @($expectedProperties | Sort-Object)
    if (($actualProperties -join '|') -cne ($expectedProperties -join '|')) {
        throw "TEST-0153 $Label dispatch property envelope was incorrect."
    }
    foreach ($property in $inputs.PSObject.Properties) {
        if ($property.Value -isnot [string]) {
            throw "TEST-0153 $Label dispatch input '$($property.Name)' was not a string."
        }
    }
    if ([string]$inputs.correlation_id -cnotmatch '^[0-9a-f]{32}$' -or
        [string]$inputs.adoption_strategy -cne 'FullMigration' -or
        [string]$inputs.acknowledge_protocol_record_loss -cne 'false' -or
        [string]$inputs.expected_base_sha -cne $script:DispatchHead) {
        throw "TEST-0153 $Label dispatch did not preserve its required string inputs."
    }
    if ($ExpectedGraphSupport -and
        [string]$inputs.source_graph_identity -cne $compactIdentity) {
        throw "TEST-0153 $Label dispatch did not preserve its exact graph identity."
    }
}

$currentWorkflowBytes = [IO.File]::ReadAllBytes($currentWorkflowPath)
$legacyWorkflowBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphUnawareCommit`:$immutableWorkflowPath"
Invoke-DispatchCase -WorkflowBytes $currentWorkflowBytes `
    -ExpectedGraphSupport $true -Label 'current v0.15.4'
Invoke-DispatchCase -WorkflowBytes $legacyWorkflowBytes `
    -ExpectedGraphSupport $false -Label 'immutable v0.12.5'

$callbackRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-test0153-quick-callback-$([guid]::NewGuid().ToString('N'))"
$loadedPolicy = $null
try {
    New-Item -ItemType Directory -Path $callbackRoot -Force | Out-Null
    & git -C $callbackRoot init -b main | Out-Null
    & git -C $callbackRoot config user.name 'TEST-0153 Fixture'
    & git -C $callbackRoot config user.email 'fixture@example.invalid'
    & git -C $callbackRoot config commit.gpgsign false
    & git -C $callbackRoot config core.autocrlf false
    [IO.File]::WriteAllText(
        (Join-Path $callbackRoot 'AGENTS.md'),
        "Required reading: [memory](MEMORY.md).`n",
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $callbackRoot 'MEMORY.md'),
        "# Project memory`n",
        [Text.UTF8Encoding]::new($false)
    )
    & git -C $callbackRoot add -- AGENTS.md MEMORY.md
    & git -C $callbackRoot commit -m 'Create callback fixture' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'TEST-0153 quick callback repository could not be committed.'
    }
    $callbackHead = ((& git -C $callbackRoot rev-parse HEAD) -join '').Trim()
    $loadedPolicy = @(Import-Module $capabilitiesModulePath -Force -PassThru)
    if ($loadedPolicy.Count -ne 1) {
        throw 'TEST-0153 quick callback policy did not load exactly once.'
    }
    $script:InitialAdoptionPolicy = [pscustomobject]@{
        Commands = $loadedPolicy[0].ExportedCommands
    }
    $callbackGraph = Get-QuickAdoptionInstructionGraph `
        -Repository $callbackRoot -Commit $callbackHead
    if ([string]$callbackGraph.baseHead -cne $callbackHead -or
        @($callbackGraph.nodes.path) -cnotcontains 'AGENTS.md' -or
        @($callbackGraph.nodes.path) -cnotcontains 'MEMORY.md') {
        throw 'TEST-0153 actual quick wrapper did not cross the dynamic policy-module callback with its exact graph.'
    }
}
finally {
    $script:InitialAdoptionPolicy = $null
    if ($null -ne $loadedPolicy -and $loadedPolicy.Count -eq 1) {
        Remove-Module -ModuleInfo $loadedPolicy[0] -Force `
            -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $callbackRoot) {
        Remove-Item -LiteralPath $callbackRoot -Recurse -Force `
            -ErrorAction SilentlyContinue
    }
}

# Load the real native-process owner only after every mocked lifecycle call.
. $nativeProcessPath
$childExecutable = if ($PSVersionTable.PSEdition -ceq 'Desktop') {
    Join-Path $PSHOME 'powershell.exe'
}
else {
    (Get-Command pwsh -ErrorAction Stop).Source
}
$childSource = @'
$inputStream = [Console]::OpenStandardInput()
$buffer = [IO.MemoryStream]::new()
try {
    $inputStream.CopyTo($buffer)
    [Convert]::ToBase64String($buffer.ToArray())
}
finally {
    $buffer.Dispose()
}
'@
$encodedChildSource = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($childSource)
)
$unicodeInput =
    '{"source_graph_identity":"{\"path\":\"docs/özellik.md\"}"}'
$encodingBeforeInvocation = $OutputEncoding
$nativeResult = Invoke-External -Command $childExecutable -Arguments @(
    '-NoProfile', '-NonInteractive', '-EncodedCommand', $encodedChildSource
) -InputText $unicodeInput
if (-not [object]::ReferenceEquals(
    $encodingBeforeInvocation, $OutputEncoding
)) {
    throw 'TEST-0153 native stdin dispatch did not restore OutputEncoding.'
}
$stdinBytes = [Convert]::FromBase64String(
    ((@($nativeResult.Output) -join '').Trim())
)
if ($stdinBytes.Length -ge 3 -and
    $stdinBytes[0] -eq 0xEF -and $stdinBytes[1] -eq 0xBB -and
    $stdinBytes[2] -eq 0xBF) {
    throw 'TEST-0153 native stdin dispatch emitted a UTF-8 BOM.'
}
$payloadLength = $stdinBytes.Length
while ($payloadLength -gt 0 -and
    $stdinBytes[$payloadLength - 1] -in @(0x0A, 0x0D)) {
    $payloadLength--
}
$payloadBytes = if ($payloadLength -eq 0) {
    [byte[]]@()
}
else {
    [byte[]]$stdinBytes[0..($payloadLength - 1)]
}
$strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
try {
    $decodedInput = $strictUtf8.GetString($payloadBytes)
}
catch {
    throw 'TEST-0153 native stdin dispatch was not valid UTF-8.'
}
if ($decodedInput -cne $unicodeInput) {
    throw 'TEST-0153 native stdin dispatch did not preserve its Unicode JSON bytes.'
}

Write-Host 'TEST-0153 JSON dispatch, UTF-8 stdin, compatibility, and callback passed.' -ForegroundColor Green
Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0153'
$caseResult = New-MeAndAICaseResult -Context $caseContext
Write-Host ('MEANDAI_CASE_RESULTS=' +
    ($caseResult | ConvertTo-Json -Compress))
