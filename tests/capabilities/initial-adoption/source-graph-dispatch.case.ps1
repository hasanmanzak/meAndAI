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
$immutableMinimumGraphUnawareCommit =
    'edf443744e3a72bcc951008bf1b3ba4727104a27'
$immutableGraphUnawareCommit =
    '252488a88d2a64ea8816239bbf6d953f506b8840'
$immutableGraphSchema1Commit =
    '1883a2315529e7493343c07eebb4c74ed77a62b4'
$immutableGraphSchema2Commit =
    '11c56aac369767202835c4e9d6cc83aa321f4070'
$immutableWorkflowPath =
    'templates/project/.github/workflows/meandai-protocol-update.yml'
$immutablePolicyPath =
    'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'

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

function Get-TestPolicyGraphContract {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $decoder = [Text.UTF8Encoding]::new($false, $true)
    $module = $null
    try {
        $source = $decoder.GetString($Bytes)
        $module = New-Module `
            -Name "MeAndAI.Test0153.Policy.$([guid]::NewGuid().ToString('N'))" `
            -ScriptBlock ([scriptblock]::Create($source))
        $loaded = @(Import-Module -ModuleInfo $module -Force -PassThru)
        if ($loaded.Count -ne 1) {
            throw 'TEST-0153 policy contract probe did not load exactly once.'
        }
        $commands = $loaded[0].ExportedCommands
        $limits = & $commands['Get-MeAndAIInstructionGraphLimits']
        $graph = & $commands['New-MeAndAIInstructionGraph'] `
            -BaseHead ('0' * 40) -TreeEntries @() -ReadBlob {
                throw 'TEST-0153 empty graph probe unexpectedly requested a blob.'
            }
        if (-not [bool](& $commands['Test-MeAndAIExactInstructionGraph'] `
                -Graph $graph)) {
            throw 'TEST-0153 policy contract probe did not produce an exact empty graph.'
        }
        return [pscustomobject]@{
            Schema = [int]$graph.schema
            MaximumBlobBytes = [int]$limits.MaximumBlobBytes
            IdentityJson = ((& $commands[
                'Get-MeAndAIInstructionGraphIdentity'
            ] -Graph $graph) | ConvertTo-Json -Depth 10 -Compress)
        }
    }
    finally {
        if ($null -ne $module) {
            Remove-Module -ModuleInfo $module -Force `
                -ErrorAction SilentlyContinue
        }
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
        [Parameter(Mandatory)][string]$Label,
        [AllowEmptyString()][string]$SourceGraphIdentityJson = ''
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
    if ($actualGraphSupport -and
        [string]::IsNullOrWhiteSpace($SourceGraphIdentityJson)) {
        throw "TEST-0153 $Label graph-aware dispatch has no policy-built identity."
    }
    $selectedIdentity = if ($actualGraphSupport) {
        $SourceGraphIdentityJson
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
        [string]$inputs.source_graph_identity -cne
            $SourceGraphIdentityJson) {
        throw "TEST-0153 $Label dispatch did not preserve its exact graph identity."
    }
}

$currentWorkflowBytes = [IO.File]::ReadAllBytes($currentWorkflowPath)
$minimumLegacyWorkflowBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableMinimumGraphUnawareCommit`:$immutableWorkflowPath"
$legacyWorkflowBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphUnawareCommit`:$immutableWorkflowPath"
$schema1WorkflowBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphSchema1Commit`:$immutableWorkflowPath"
$schema1PolicyBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphSchema1Commit`:$immutablePolicyPath"
$schema2PriorWorkflowBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphSchema2Commit`:$immutableWorkflowPath"
$schema2PriorPolicyBytes = Get-GitObjectBytes -Repository $root `
    -Object "$immutableGraphSchema2Commit`:$immutablePolicyPath"
$legacyGraphMarkerPolicyBytes = Get-GitObjectBytes -Repository $root `
    -Object "v0.14.1`:$immutablePolicyPath"
$schema1PolicyContract = Get-TestPolicyGraphContract -Bytes $schema1PolicyBytes
$schema2PriorPolicyContract = Get-TestPolicyGraphContract `
    -Bytes $schema2PriorPolicyBytes
$schema2PolicyContract = Get-TestPolicyGraphContract `
    -Bytes ([IO.File]::ReadAllBytes($capabilitiesModulePath))
if ($schema1PolicyContract.Schema -ne 1 -or
    $schema1PolicyContract.MaximumBlobBytes -ne 262144 -or
    $schema2PriorPolicyContract.Schema -ne 2 -or
    $schema2PriorPolicyContract.MaximumBlobBytes -ne 524288 -or
    $schema2PolicyContract.Schema -ne 2 -or
    $schema2PolicyContract.MaximumBlobBytes -ne 524288) {
    throw 'TEST-0153 immutable schema-1 and candidate schema-2 policy probes were not exact.'
}

$transitionFailures = [Collections.Generic.List[string]]::new()
$policyTagSelector = Get-Command `
    -Name 'Resolve-QuickAdoptionInitialPolicyTag' `
    -CommandType Function -ErrorAction SilentlyContinue
if ($null -eq $policyTagSelector) {
    $transitionFailures.Add(
        'target-policy selector is missing'
    )
}
else {
    $schema1PolicyTag = & $policyTagSelector `
        -WorkflowBytes $schema1WorkflowBytes -TargetTag 'v0.15.4' `
        -RuntimePolicyTag 'v0.15.6'
    $schema2PriorPolicyTag = & $policyTagSelector `
        -WorkflowBytes $schema2PriorWorkflowBytes -TargetTag 'v0.15.5' `
        -RuntimePolicyTag 'v0.15.6'
    $legacyPolicyTag = & $policyTagSelector `
        -WorkflowBytes $legacyWorkflowBytes -TargetTag 'v0.12.5' `
        -RuntimePolicyTag 'v0.15.6'
    $minimumLegacyPolicyTag = & $policyTagSelector `
        -WorkflowBytes $minimumLegacyWorkflowBytes -TargetTag 'v0.12.4' `
        -RuntimePolicyTag 'v0.15.6'
    if ([string]$schema1PolicyTag -cne 'v0.15.4' -or
        [string]$schema2PriorPolicyTag -cne 'v0.15.5' -or
        [string]$legacyPolicyTag -cne 'v0.15.6' -or
        [string]$minimumLegacyPolicyTag -cne 'v0.15.6') {
        $transitionFailures.Add(
            'graph-aware target or graph-unaware fallback selected the wrong policy tag'
        )
    }
    foreach ($unsupportedLegacyTag in @('v0.12.3', 'v1.0.0')) {
        $unsupportedLegacyFailure = $null
        try {
            [void](& $policyTagSelector `
                -WorkflowBytes $legacyWorkflowBytes `
                -TargetTag $unsupportedLegacyTag `
                -RuntimePolicyTag 'v0.15.6')
        }
        catch { $unsupportedLegacyFailure = $_.Exception.Message }
        if ($unsupportedLegacyFailure -notlike
                '*outside the reviewed v0.12.4-v0.12.5*') {
            $transitionFailures.Add(
                "graph-unaware target '$unsupportedLegacyTag' did not fail outside the bounded historical fallback"
            )
        }
    }
}
$proposalTokens = $null
$proposalParseErrors = $null
$proposalAst = [Management.Automation.Language.Parser]::ParseFile(
    $proposalOwnershipPath, [ref]$proposalTokens, [ref]$proposalParseErrors
)
$markerFunctions = @($proposalAst.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -ceq 'Get-ValidatedAdoptionMarker'
}, $true))
if ($proposalParseErrors.Count -ne 0 -or $markerFunctions.Count -ne 1 -or
    $markerFunctions[0].Extent.Text -match '(?m)^\s*schema\s*=\s*2\s*$' -or
    -not $markerFunctions[0].Extent.Text.Contains(
        '$script:InitialAdoptionPolicy.GraphSchema'
    )) {
    $transitionFailures.Add(
        'proposal identity reconstruction is not owned by the imported policy schema'
    )
}
if ($transitionFailures.Count -ne 0) {
    throw "TEST-0153 target-policy transition failed with $($transitionFailures.Count) problem(s): $($transitionFailures -join '; ')."
}
Invoke-DispatchCase -WorkflowBytes $currentWorkflowBytes `
    -ExpectedGraphSupport $true -Label 'candidate v0.15.6' `
    -SourceGraphIdentityJson $schema2PolicyContract.IdentityJson
Invoke-DispatchCase -WorkflowBytes $schema2PriorWorkflowBytes `
    -ExpectedGraphSupport $true -Label 'immutable v0.15.5' `
    -SourceGraphIdentityJson $schema2PriorPolicyContract.IdentityJson
Invoke-DispatchCase -WorkflowBytes $schema1WorkflowBytes `
    -ExpectedGraphSupport $true -Label 'immutable v0.15.4' `
    -SourceGraphIdentityJson $schema1PolicyContract.IdentityJson
Invoke-DispatchCase -WorkflowBytes $legacyWorkflowBytes `
    -ExpectedGraphSupport $false -Label 'immutable v0.12.5'

$schema1MarkerModule = $null
try {
    $schema1MarkerSource = [Text.UTF8Encoding]::new(
        $false, $true
    ).GetString($schema1PolicyBytes)
    $schema1MarkerModule = New-Module `
        -Name "MeAndAI.Test0153.Schema1Marker.$([guid]::NewGuid().ToString('N'))" `
        -ScriptBlock ([scriptblock]::Create($schema1MarkerSource))
    $schema1MarkerModules = @(Import-Module -ModuleInfo $schema1MarkerModule `
        -Force -PassThru)
    if ($schema1MarkerModules.Count -ne 1) {
        throw 'TEST-0153 schema-1 marker policy did not load exactly once.'
    }
    $script:InitialAdoptionPolicy = [pscustomobject]@{
        GraphSchema = 1
        Commands = $schema1MarkerModules[0].ExportedCommands
    }
    $ProtocolTag = 'v0.15.4'
    $markerRepository = 'owner/consumer'
    $markerActor = 'owner'
    $markerBranch = 'automation/meandai-capabilities-v0.15.4'
    $markerHead = 'c' * 40
    $plannedMarkerHead = 'd' * 40
    $schema1Identity = $schema1PolicyContract.IdentityJson | ConvertFrom-Json
    $schema1MarkerCases = @(
        [pscustomobject]@{
            Label = 'schema-9 Proposed'
            ExpectedSchema = 9
            ExpectedMarkerHead = $markerHead
            Record = [ordered]@{
                schema = 9
                phase = 'Proposed'
                state = 'AdoptionReviewRequired'
                target = $ProtocolTag
                protocolSha = $immutableGraphSchema1Commit
                head = $markerHead
                branch = $markerBranch
                adoptionStrategy = 'FullMigration'
                protocolRecordLossAcknowledged = $false
                graphBase = [string]$schema1Identity.graphBase
                graphDigest = [string]$schema1Identity.graphDigest
                graphCounts = $schema1Identity.graphCounts
                graphLimits = $schema1Identity.graphLimits
                repository = $markerRepository
                actor = $markerActor
            }
        },
        [pscustomobject]@{
            Label = 'schema-10 Publishing'
            ExpectedSchema = 10
            ExpectedMarkerHead = $markerHead
            Record = [ordered]@{
                schema = 10
                phase = 'Publishing'
                state = 'AdoptionReviewRequired'
                target = $ProtocolTag
                protocolSha = $immutableGraphSchema1Commit
                head = $markerHead
                previousHead = $markerHead
                plannedHead = $plannedMarkerHead
                branch = $markerBranch
                adoptionStrategy = 'FullMigration'
                protocolRecordLossAcknowledged = $false
                graphBase = [string]$schema1Identity.graphBase
                graphDigest = [string]$schema1Identity.graphDigest
                graphCounts = $schema1Identity.graphCounts
                graphLimits = $schema1Identity.graphLimits
                repository = $markerRepository
                actor = $markerActor
            }
        }
    )
    foreach ($markerCase in $schema1MarkerCases) {
        $markerJson = $markerCase.Record | ConvertTo-Json -Depth 20 -Compress
        $markerBody = @(
            "<!-- meandai-capabilities-adoption:$markerJson -->",
            '### Detected protocol and governance surfaces',
            '',
            '- None'
        ) -join "`n"
        $markerPullRequest = [pscustomobject][ordered]@{
            number = 42
            url = 'https://github.com/owner/consumer/pull/42'
            isDraft = $true
            state = 'OPEN'
            baseRefName = 'main'
            headRefName = $markerBranch
            headRefOid = $markerHead
            headRepository = [pscustomobject]@{
                name = 'consumer'
                nameWithOwner = $markerRepository
            }
            headRepositoryOwner = [pscustomobject]@{ login = $markerActor }
            isCrossRepository = $false
            author = [pscustomobject]@{ login = $markerActor }
            body = $markerBody
        }
        $validatedMarker = Get-ValidatedAdoptionMarker `
            -PullRequest $markerPullRequest -Repository $markerRepository `
            -Branch $markerBranch -BaseBranch 'main' `
            -ExpectedActor $markerActor `
            -ExpectedMarkerHead $markerCase.ExpectedMarkerHead `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ExpectedProtocolSurfaces @() `
            -ExpectedProtocolRecordLossAcknowledgement $false
        if ([int]$validatedMarker.schema -ne
                [int]$markerCase.ExpectedSchema -or
            [int]$validatedMarker.graphLimits.maximumBlobBytes -ne 262144) {
            throw "TEST-0153 $($markerCase.Label) did not retain runtime schema-1 marker identity."
        }
    }
}
finally {
    $script:InitialAdoptionPolicy = $null
    if ($null -ne $schema1MarkerModule) {
        Remove-Module -ModuleInfo $schema1MarkerModule -Force `
            -ErrorAction SilentlyContinue
    }
}

$legacyTransitionPolicy = $null
$originalCanonicalAsset = (Get-Command `
    -Name 'Get-CanonicalProtocolAsset' -CommandType Function).ScriptBlock
$originalPullRequestBodySetter = (Get-Command `
    -Name 'Set-AdoptionPullRequestBody' -CommandType Function).ScriptBlock
$originalProtocolTag = $ProtocolTag
try {
    $initialAdoptionPolicySourcePath =
        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
    $initialAdoptionPolicyTag = 'v0.15.6'
    $adoptionManifestPath = '.ai/adoption/meandai-capabilities.json'
    $ProtocolRepository = 'hasanmanzak/meAndAI'
    $script:Test0153LegacyPolicyBytes = [byte[]]$legacyGraphMarkerPolicyBytes
    $script:Test0153RuntimePolicyBytes =
        [IO.File]::ReadAllBytes($capabilitiesModulePath)
    function Get-CanonicalProtocolAsset {
        param(
            [Parameter(Mandatory)][string]$Tag,
            [Parameter(Mandatory)][string]$TemplatePath,
            [string]$ProtocolToken = ''
        )

        if ($TemplatePath -cne
                'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1' -or
            -not [string]::IsNullOrEmpty($ProtocolToken) -or
            $Tag -cnotin @('v0.14.1', 'v0.15.6')) {
            throw 'TEST-0153 legacy marker transition requested an unexpected policy asset.'
        }
        return [pscustomobject][ordered]@{
            Tag = $Tag
            TemplatePath = $TemplatePath
            Bytes = if ($Tag -ceq 'v0.14.1') {
                [byte[]]$script:Test0153LegacyPolicyBytes
            }
            else { [byte[]]$script:Test0153RuntimePolicyBytes }
            Sha = if ($Tag -ceq 'v0.14.1') { 'a' * 40 } else { 'b' * 40 }
        }
    }
    function Set-AdoptionPullRequestBody {
        param(
            [Parameter(Mandatory)][string]$Repository,
            [Parameter(Mandatory)]$PullRequest,
            [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
            [Parameter(Mandatory)][string]$TemporaryDirectory,
            [Parameter(Mandatory)][string]$FileName
        )
        return $Body
    }

    $legacyTransitionPolicy = Import-CanonicalInitialAdoptionPolicy `
        -Tag 'v0.14.1'
    $script:InitialAdoptionPolicy = $legacyTransitionPolicy
    $ProtocolTag = 'v0.14.1'
    $legacyGraphBase = 'c' * 40
    $legacyPlannedHead = 'd' * 40
    $legacyRepository = 'owner/consumer'
    $legacyActor = 'owner'
    $legacyBranch = 'automation/meandai-capabilities-v0.14.1'
    $legacyBlobText = @{
        'AGENTS.md' = 'Required reading: `.ai/memory/project.md`.'
        '.ai/memory/project.md' = '# Project memory'
    }
    $legacyBlobBytes = @{}
    $legacyBlobSha = @{}
    foreach ($legacyBlobPath in @($legacyBlobText.Keys)) {
        [byte[]]$legacyBytes = [Text.UTF8Encoding]::new($false).GetBytes(
            [string]$legacyBlobText[$legacyBlobPath]
        )
        $legacyBlobBytes[$legacyBlobPath] = $legacyBytes
        [byte[]]$legacyHeader = [Text.Encoding]::ASCII.GetBytes(
            "blob $($legacyBytes.Length)`0"
        )
        [byte[]]$legacyGitObject =
            [byte[]]::new($legacyHeader.Length + $legacyBytes.Length)
        [Array]::Copy(
            $legacyHeader, 0, $legacyGitObject, 0, $legacyHeader.Length
        )
        [Array]::Copy(
            $legacyBytes, 0, $legacyGitObject, $legacyHeader.Length,
            $legacyBytes.Length
        )
        $legacySha1 = [Security.Cryptography.SHA1]::Create()
        try {
            $legacyBlobSha[$legacyBlobPath] =
                -join @($legacySha1.ComputeHash($legacyGitObject) |
                    ForEach-Object { $_.ToString('x2') })
        }
        finally { $legacySha1.Dispose() }
    }
    $legacyTreeEntries = @(
        [pscustomobject][ordered]@{
            Path = 'AGENTS.md'; Mode = '100644'; Type = 'blob'
            Sha = [string]$legacyBlobSha['AGENTS.md']
        },
        [pscustomobject][ordered]@{
            Path = '.ai/memory/project.md'; Mode = '100644'; Type = 'blob'
            Sha = [string]$legacyBlobSha['.ai/memory/project.md']
        }
    )
    $legacyBlobReader = {
        param($entry)
        return [byte[]]$legacyBlobBytes[[string]$entry.Path]
    }.GetNewClosure()
    $legacyGraphBuilder = Get-InitialAdoptionPolicyCommand `
        -Name 'New-MeAndAIInstructionGraph'
    $legacyIdentityBuilder = Get-InitialAdoptionPolicyCommand `
        -Name 'Get-MeAndAIInstructionGraphIdentity'
    $legacyGraph = & $legacyGraphBuilder -BaseHead $legacyGraphBase `
        -TreeEntries $legacyTreeEntries -ReadBlob $legacyBlobReader
    $legacyIdentity = & $legacyIdentityBuilder -Graph $legacyGraph
    if (@($legacyIdentity.protocolSurfaces).Count -eq 0) {
        throw 'TEST-0153 legacy marker transition fixture did not produce a nonempty protocol surface.'
    }
    $legacyMarkerRecord = [ordered]@{
        schema = 7
        phase = 'Proposed'
        state = 'AdoptionReviewRequired'
        target = $ProtocolTag
        protocolSha = 'a' * 40
        head = $legacyGraphBase
        branch = $legacyBranch
        adoptionStrategy = 'FullMigration'
        protocolSurfaces = @($legacyIdentity.protocolSurfaces)
        protocolRecordLossAcknowledged = $false
        graphBase = [string]$legacyIdentity.graphBase
        graphDigest = [string]$legacyIdentity.graphDigest
        graphCounts = $legacyIdentity.graphCounts
        graphLimits = $legacyIdentity.graphLimits
        repository = $legacyRepository
        actor = $legacyActor
    }
    $legacyMarkerJson = $legacyMarkerRecord |
        ConvertTo-Json -Depth 20 -Compress
    $legacyMarkerBody = @(
        "<!-- meandai-capabilities-adoption:$legacyMarkerJson -->",
        '### Detected protocol and governance surfaces',
        ''
    ) + @($legacyIdentity.protocolSurfaces | ForEach-Object {
        '- `' + [string]$_ + '`'
    })
    $legacyPullRequest = [pscustomobject][ordered]@{
        number = 43
        url = 'https://github.com/owner/consumer/pull/43'
        isDraft = $true
        state = 'OPEN'
        baseRefName = 'main'
        headRefName = $legacyBranch
        headRefOid = $legacyGraphBase
        headRepository = [pscustomobject]@{
            name = 'consumer'; nameWithOwner = $legacyRepository
        }
        headRepositoryOwner = [pscustomobject]@{ login = $legacyActor }
        isCrossRepository = $false
        author = [pscustomobject]@{ login = $legacyActor }
        body = $legacyMarkerBody -join "`n"
        meAndAIMarker = [pscustomobject]$legacyMarkerRecord
    }
    $legacyTransitionCases = @(
        [pscustomobject]@{
            Phase = 'Proposed'; Schema = 7; Head = $legacyGraphBase
        },
        [pscustomobject]@{
            Phase = 'Publishing'; Schema = 8; Head = $legacyGraphBase
        },
        [pscustomobject]@{
            Phase = 'Completed'; Schema = 7; Head = $legacyPlannedHead
        }
    )
    foreach ($legacyTransitionCase in $legacyTransitionCases) {
        $legacyBody = switch ($legacyTransitionCase.Phase) {
            'Proposed' {
                Set-AdoptionPullRequestProposedMarker `
                    -Repository $legacyRepository `
                    -PullRequest $legacyPullRequest `
                    -PreviousHead $legacyGraphBase `
                    -TemporaryDirectory ([IO.Path]::GetTempPath())
            }
            'Publishing' {
                Set-AdoptionPullRequestPublishingMarker `
                    -Repository $legacyRepository `
                    -PullRequest $legacyPullRequest `
                    -PreviousHead $legacyGraphBase `
                    -PlannedHead $legacyPlannedHead `
                    -TemporaryDirectory ([IO.Path]::GetTempPath())
            }
            'Completed' {
                Set-AdoptionPullRequestCompletedMarker `
                    -Repository $legacyRepository `
                    -PullRequest $legacyPullRequest `
                    -PublishedHead $legacyPlannedHead `
                    -TemporaryDirectory ([IO.Path]::GetTempPath()) `
                    -IssueNumber 99
            }
        }
        $legacyMarkerMatch = [regex]::Match(
            [string]$legacyBody,
            '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if (-not $legacyMarkerMatch.Success) {
            throw "TEST-0153 legacy $($legacyTransitionCase.Phase) transition lost its marker."
        }
        $legacyPullRequest.body = [string]$legacyBody
        $legacyPullRequest.meAndAIMarker =
            $legacyMarkerMatch.Groups['json'].Value | ConvertFrom-Json
        $legacyPullRequest.headRefOid = [string]$legacyTransitionCase.Head
        $validatedLegacyMarker = Get-ValidatedAdoptionMarker `
            -PullRequest $legacyPullRequest `
            -Repository $legacyRepository -Branch $legacyBranch `
            -BaseBranch 'main' -ExpectedActor $legacyActor `
            -ExpectedMarkerHead ([string]$legacyTransitionCase.Head) `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ExpectedProtocolSurfaces @($legacyIdentity.protocolSurfaces) `
            -ExpectedProtocolRecordLossAcknowledgement $false
        if ([int]$validatedLegacyMarker.schema -ne
                [int]$legacyTransitionCase.Schema -or
            [string]$validatedLegacyMarker.phase -cne
                [string]$legacyTransitionCase.Phase -or
            @($validatedLegacyMarker.protocolSurfaces).Count -eq 0) {
            throw "TEST-0153 legacy $($legacyTransitionCase.Phase) transition did not preserve schema-7/8 graph identity."
        }
    }
}
finally {
    $ProtocolTag = $originalProtocolTag
    $script:InitialAdoptionPolicy = $null
    if ($null -ne $legacyTransitionPolicy) {
        [object[]]$legacyTransitionModules =
            @($legacyTransitionPolicy.Modules)
        [array]::Reverse($legacyTransitionModules)
        foreach ($legacyTransitionModule in $legacyTransitionModules) {
            Remove-Module -ModuleInfo $legacyTransitionModule -Force `
                -ErrorAction SilentlyContinue
        }
    }
    Set-Item -Path Function:Get-CanonicalProtocolAsset `
        -Value $originalCanonicalAsset
    Set-Item -Path Function:Set-AdoptionPullRequestBody `
        -Value $originalPullRequestBodySetter
    Remove-Variable -Name Test0153LegacyPolicyBytes `
        -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name Test0153RuntimePolicyBytes `
        -Scope Script -ErrorAction SilentlyContinue
}

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
$originalConsoleInputEncoding = [Console]::InputEncoding
try {
    [Console]::InputEncoding = [Text.UTF8Encoding]::new($true)
    $ambientInputPreamble = [Console]::InputEncoding.GetPreamble()
    if ($ambientInputPreamble.Length -ne 3 -or
        $ambientInputPreamble[0] -ne 0xEF -or
        $ambientInputPreamble[1] -ne 0xBB -or
        $ambientInputPreamble[2] -ne 0xBF) {
        throw 'TEST-0153 ambient stdin encoding lacks the UTF-8 BOM.'
    }
    $encodingBeforeInvocation = $OutputEncoding
    $nativeResult = Invoke-External -Command $childExecutable -Arguments @(
        '-NoProfile', '-NonInteractive', '-EncodedCommand', $encodedChildSource
    ) -InputText $unicodeInput
    if (-not [object]::ReferenceEquals(
        $encodingBeforeInvocation, $OutputEncoding
    )) {
        throw 'TEST-0153 native stdin dispatch did not restore OutputEncoding.'
    }
    $restoredInputPreamble = [Console]::InputEncoding.GetPreamble()
    if ($restoredInputPreamble.Length -ne 3 -or
        $restoredInputPreamble[0] -ne 0xEF -or
        $restoredInputPreamble[1] -ne 0xBB -or
        $restoredInputPreamble[2] -ne 0xBF) {
        throw 'TEST-0153 native stdin dispatch did not restore Console.InputEncoding.'
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
}
finally {
    [Console]::InputEncoding = $originalConsoleInputEncoding
}

Write-Host 'TEST-0153 JSON dispatch, UTF-8 stdin, compatibility, and callback passed.' -ForegroundColor Green
Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0153'
$caseResult = New-MeAndAICaseResult -Context $caseContext
Write-Host ('MEANDAI_CASE_RESULTS=' +
    ($caseResult | ConvertTo-Json -Compress))
