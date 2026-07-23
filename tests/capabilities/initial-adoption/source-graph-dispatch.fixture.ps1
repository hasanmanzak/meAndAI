[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$protocolReleasePath = Join-Path $root `
    'scripts/quick-adoption/Private/ProtocolReleaseAndAssets.ps1'
$proposalOwnershipPath = Join-Path $root `
    'scripts/quick-adoption/Private/ProposalOwnership.ps1'
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
    $protocolReleasePath, $proposalOwnershipPath, $repositoryAssessmentPath,
    $capabilitiesModulePath, $currentWorkflowPath
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
        foreach ($argument in $arguments) {
            if ($argument -match '^correlation_id=(?<id>[0-9a-f]{32})$') {
                $script:DispatchCorrelationId = [string]$Matches.id
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
    $script:DispatchCorrelationId = ''
    $script:DispatchHead = 'a' * 40
    $script:RunListCalls = 0
    $compactIdentity =
        '{"schema":1,"graphBase":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}'
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
    $fields = @($script:DispatchArguments | Where-Object {
        [string]$_ -match '^[a-z_]+='
    })
    $sourceGraphFields = @($fields | Where-Object {
        [string]$_ -like 'source_graph_identity=*'
    })
    $expectedFieldCount = if ($ExpectedGraphSupport) { 5 } else { 4 }
    if ($fields.Count -ne $expectedFieldCount -or
        $sourceGraphFields.Count -ne [int]$ExpectedGraphSupport -or
        ($ExpectedGraphSupport -and
         [string]$sourceGraphFields[0] -cne
            "source_graph_identity=$compactIdentity")) {
        throw "TEST-0153 $Label dispatch did not preserve its exact graph-input compatibility envelope."
    }
}

$currentWorkflowBytes = [IO.File]::ReadAllBytes($currentWorkflowPath)
$legacyWorkflowBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphUnawareCommit`:$immutableWorkflowPath"
Invoke-DispatchCase -WorkflowBytes $currentWorkflowBytes `
    -ExpectedGraphSupport $true -Label 'current v0.14.0'
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

Write-Host 'TEST-0153 current/legacy dispatch and actual quick-wrapper callback passed.' -ForegroundColor Green
