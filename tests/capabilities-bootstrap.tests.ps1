[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force
$modulePath = Join-Path $root 'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$adoptionPath = Join-Path $root 'docs/adoption.md'
$protocolPath = Join-Path $root 'PROTOCOL.md'
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        Add-Failure "$Message; expected '$Expected', found '$Actual'"
    }
}

foreach ($path in @($modulePath, $adapterPath, $workflowPath, $adoptionPath, $protocolPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "TEST-0027 missing lifecycle asset: $path"
    }
}

if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
    Import-Module $modulePath -Force

    function Invoke-LifecyclePlan {
        param(
            [string]$LocalUpdaterState = 'Absent',
            [string]$SeedWorkflowState = 'Exact',
            [string[]]$Collisions = @(),
            [bool]$ManifestExists = $false,
            [bool]$RemoteBranchExists = $false,
            [int]$OpenPullRequestCount = 0,
            [bool]$ExistingProposalValid = $false
        )

        Resolve-MeAndAICapabilitiesLifecycle -Snapshot ([pscustomobject]@{
            SchemaVersion = 1
            LocalUpdaterState = $LocalUpdaterState
            SeedWorkflowState = $SeedWorkflowState
            Collisions = @($Collisions)
            ManifestExists = $ManifestExists
            RemoteBranchExists = $RemoteBranchExists
            OpenPullRequestCount = $OpenPullRequestCount
            ExistingProposalValid = $ExistingProposalValid
        })
    }

    $plan = Invoke-LifecyclePlan -LocalUpdaterState 'Complete'
    Assert-Equal 'Update' $plan.State 'TEST-0027 complete local updater should own the update path'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0027 update path must not create an adoption proposal'

    $plan = Invoke-LifecyclePlan
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0028 collision-free seed should bootstrap'
    Assert-Equal 'Full' $plan.ProposalMode 'TEST-0028 collision-free seed should propose full core assets'

    $plan = Invoke-LifecyclePlan -LocalUpdaterState 'Partial' -Collisions @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    )
    Assert-Equal 'AdoptionReviewRequired' $plan.State 'TEST-0027 partial updater must not execute as complete'
    Assert-Equal 'ManifestOnly' $plan.ProposalMode 'TEST-0030 partial adoption should preserve existing targets'

    $plan = Invoke-LifecyclePlan -Collisions @('AGENTS.md', '.gitmodules')
    Assert-Equal 'AdoptionReviewRequired' $plan.State 'TEST-0030 collisions should require semantic review'
    Assert-Equal 'AGENTS.md,.gitmodules' (@($plan.Collisions) -join ',') 'TEST-0030 collision paths should remain exact and deterministic'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true -OpenPullRequestCount 1 `
        -ExistingProposalValid $true
    Assert-Equal 'PendingAdoption' $plan.State 'TEST-0031 one pending adoption proposal should remain idempotent'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0031 pending work must not be replaced'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true -OpenPullRequestCount 1
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0047 an unverified existing proposal must block'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 orphan adoption branch must block'

    $plan = Invoke-LifecyclePlan -OpenPullRequestCount 1
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 PR without deterministic branch must block'

    $plan = Invoke-LifecyclePlan -ManifestExists $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 existing manifest ownership must block'

    $plan = Invoke-LifecyclePlan -SeedWorkflowState 'Drifted'
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 seed workflow drift must block remote execution'

    $manifestValidator = Get-Command -Name 'Test-MeAndAIExactAdoptionManifest' `
        -CommandType Function -ErrorAction SilentlyContinue
    $targetPathGetter = Get-Command -Name 'Get-MeAndAIAdoptionTargetPaths' `
        -CommandType Function -ErrorAction SilentlyContinue
    $proposedPathGetter = Get-Command -Name 'Get-MeAndAIAdoptionProposedPaths' `
        -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $manifestValidator -or $null -eq $targetPathGetter -or
        $null -eq $proposedPathGetter) {
        Add-Failure 'TEST-0080 pure lifecycle module does not export the canonical adoption path contract and validator.'
    }
    else {
        $protocolSha = ('a' * 40) -join ''
        $expectedCollisions = @('AGENTS.md')
        $expectedTargetPaths = @(
            '.gitmodules', '.ai/protocol', '.ai/meandai-update-state.json', 'AGENTS.md',
            '.ai/memory/README.md', '.ai/memory/project.md',
            '.ai/memory/log/README.md', 'docs/ideas/README.md',
            '.github/ISSUE_TEMPLATE/bug.yml',
            '.github/ISSUE_TEMPLATE/epic.yml',
            '.github/ISSUE_TEMPLATE/feature.yml',
            '.github/ISSUE_TEMPLATE/finding.yml',
            '.github/ISSUE_TEMPLATE/subfeature.yml',
            '.github/ISSUE_TEMPLATE/task.yml',
            '.github/PULL_REQUEST_TEMPLATE.md',
            '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        )
        $expectedProposedPaths = @(
            '.github/workflows/meandai-protocol-update.yml'
        ) + @($expectedTargetPaths)
        $actualTargetPaths = @(& $targetPathGetter)
        $actualProposedPaths = @(& $proposedPathGetter)
        if (($actualTargetPaths -join "`n") -cne ($expectedTargetPaths -join "`n")) {
            Add-Failure 'TEST-0080 canonical adoption target path inventory is not exact.'
        }
        if (($actualProposedPaths -join "`n") -cne ($expectedProposedPaths -join "`n")) {
            Add-Failure 'TEST-0080 canonical adoption proposed path inventory is not exact.'
        }
        $requiredTasks = @(
            'Create or reconcile the repository labels required by the protocol.',
            'Create project-owned feature and decision records for adoption.',
            'Tailor project-local memory without importing protocol-repository facts.',
            'Resolve every collision through semantic review; do not overwrite blindly.',
            'Create and run the project test evidence required by DoR and DoD.',
            'Verify all documentation links and traceability references.',
            'Remove the manifest before marking the pull request ready or merging it.'
        )
        $validManifest = [pscustomobject][ordered]@{
            schema = 1
            operation = 'ai-capabilities-adoption'
            state = 'AdoptionReviewRequired'
            repository = 'owner/consumer'
            targetTag = 'v0.9.7'
            protocolSha = $protocolSha
            collisions = $expectedCollisions
            proposedPaths = $expectedProposedPaths
            requiredTasks = $requiredTasks
        }
        function Test-ManifestFixture {
            param([Parameter(Mandatory)]$Manifest)

            return Test-MeAndAIExactAdoptionManifest -Manifest $Manifest `
                -Repository 'owner/consumer' -TargetTag 'v0.9.7' `
                -ProtocolSha $protocolSha -ExpectedState 'AdoptionReviewRequired' `
                -ExpectedCollisions $expectedCollisions
        }

        if (-not (Test-ManifestFixture -Manifest $validManifest)) {
            Add-Failure 'TEST-0080 exact canonical adoption manifest was rejected.'
        }

        $invalidManifests = [ordered]@{}
        $extraProperty = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $extraProperty | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        $invalidManifests['additional property'] = $extraProperty
        $missingProperty = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $missingProperty.PSObject.Properties.Remove('requiredTasks')
        $invalidManifests['missing property'] = $missingProperty
        $wrongTasks = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongTasks.requiredTasks = @('Remove the manifest before readiness.')
        $invalidManifests['wrong required task inventory'] = $wrongTasks
        $wrongPaths = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongPaths.proposedPaths = @($expectedProposedPaths | Select-Object -Skip 1)
        $invalidManifests['wrong proposed path inventory'] = $wrongPaths
        $wrongCollisions = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongCollisions.collisions = @('docs/ideas/README.md')
        $invalidManifests['wrong collision inventory'] = $wrongCollisions
        $invalidManifests['array root type'] = [object[]]@(
            $validManifest,
            $validManifest
        )
        foreach ($identityVariant in @(
            @{ Name = 'repository identity'; Property = 'repository'; Value = 'other/consumer' },
            @{ Name = 'target-tag identity'; Property = 'targetTag'; Value = 'v0.8.4' },
            @{ Name = 'protocol-SHA identity'; Property = 'protocolSha'; Value = ('b' * 40) },
            @{ Name = 'state identity'; Property = 'state'; Value = 'BootstrapReady' },
            @{ Name = 'operation identity'; Property = 'operation'; Value = 'other-operation' },
            @{ Name = 'schema value'; Property = 'schema'; Value = 2 },
            @{ Name = 'schema type'; Property = 'schema'; Value = '1' },
            @{ Name = 'collision property type'; Property = 'collisions'; Value = 'AGENTS.md' }
        )) {
            $variant = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
            $variant.($identityVariant.Property) = $identityVariant.Value
            $invalidManifests[$identityVariant.Name] = $variant
        }

        foreach ($entry in $invalidManifests.GetEnumerator()) {
            if (Test-ManifestFixture -Manifest $entry.Value) {
                Add-Failure "TEST-0080 manifest with $($entry.Key) was accepted."
            }
        }
    }
}

if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($required in @(
        'BOOTSTRAP_PROTOCOL_TAG: v0.10.3',
        'run-name: meAndAI AI capabilities lifecycle [${{ inputs.correlation_id || github.event_name }}]',
        'correlation_id:',
        'Verify immutable protocol release',
        "'X-GitHub-Api-Version' = '2026-03-10'",
        'immutable',
        'published_at',
        'ref: ${{ env.BOOTSTRAP_PROTOCOL_TAG }}',
        'MeAndAI.ProtocolUpdate.psm1',
        'Invoke-MeAndAIProtocolUpdate.ps1',
        'Invoke-MeAndAICapabilitiesBootstrap.ps1',
        'Local updater installation is partial',
        'MEANDAI_UPDATER_TOKEN',
        'MEANDAI_PROTOCOL_TOKEN',
        'PROTOCOL_TOKEN: ${{ secrets.MEANDAI_PROTOCOL_TOKEN || github.token }}'
    )) {
        if (-not $workflow.Contains($required)) {
            Add-Failure "TEST-0027 workflow is missing '$required'"
        }
    }
    foreach ($forbidden in @('pull_request_target:', 'gh pr merge', 'actions/checkout@v')) {
        if ($workflow.Contains($forbidden)) {
            Add-Failure "TEST-0032 workflow contains forbidden behavior '$forbidden'"
        }
    }
    $proposalJobStart = $workflow.IndexOf('  propose-update:', [StringComparison]::Ordinal)
    $finalizerJobStart = $workflow.IndexOf('  finalize-managed-merge:', [StringComparison]::Ordinal)
    if ($proposalJobStart -lt 0 -or $finalizerJobStart -le $proposalJobStart -or
        -not $workflow.Substring(
            $proposalJobStart, $finalizerJobStart - $proposalJobStart
        ).Contains('issues: write') -or
        -not $workflow.Substring(
            $proposalJobStart, $finalizerJobStart - $proposalJobStart
        ).Contains('ISSUE_TOKEN: ${{ github.token }}')) {
        Add-Failure 'TEST-0111 proposal issue authority is not isolated to the job-scoped token.'
    }
    $trustedPreflightIndex = $workflow.IndexOf('-ValidateLocalUpdaterOnly', [StringComparison]::Ordinal)
    $localUpdaterInvocationIndex = $workflow.IndexOf('& "./$adapterPath"', [StringComparison]::Ordinal)
    if ($trustedPreflightIndex -lt 0 -or $localUpdaterInvocationIndex -lt 0 -or
        $trustedPreflightIndex -ge $localUpdaterInvocationIndex) {
        Add-Failure 'TEST-0077 trusted-source updater validation must run before the local updater adapter.'
    }
}

if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
    $module = Get-Content -LiteralPath $modulePath -Raw
    foreach ($forbidden in @('Invoke-Native', 'Invoke-RestMethod', 'Invoke-WebRequest', "& git", "& gh")) {
        if ($module.Contains($forbidden)) {
            Add-Failure "TEST-0030 pure lifecycle planner contains live-operation token '$forbidden'"
        }
    }
}

if (Test-Path -LiteralPath $adapterPath -PathType Leaf) {
    $adapter = Get-Content -LiteralPath $adapterPath -Raw
    foreach ($required in @(
        '.ai/adoption/meandai-capabilities.json',
        'Resolve-MeAndAICapabilitiesLifecycle',
        '--force-with-lease=',
        "'pr', 'create'",
        '--draft',
        'BootstrapReady',
        'AdoptionReviewRequired',
        'PendingAdoption',
        'BlockedManualReview',
        'ValidateLocalUpdaterOnly'
    )) {
        if (-not $adapter.Contains($required)) {
            Add-Failure "TEST-0028 bootstrap adapter is missing '$required'"
        }
    }
    foreach ($forbidden in @("'issue', 'create'", "'label', 'create'", "'pr', 'merge'")) {
        if ($adapter.Contains($forbidden)) {
            Add-Failure "TEST-0032 bootstrap adapter contains forbidden mutation '$forbidden'"
        }
    }
}

if (Test-Path -LiteralPath $adoptionPath -PathType Leaf) {
    $adoption = Get-Content -LiteralPath $adoptionPath -Raw
    foreach ($required in @(
        'AI capabilities lifecycle',
        'BootstrapReady',
        'AdoptionReviewRequired',
        'PendingAdoption',
        '.ai/adoption/meandai-capabilities.json',
        'does not start an AI agent',
        'remove the manifest'
    )) {
        if (-not $adoption.Contains($required)) {
            Add-Failure "TEST-0032 adoption contract is missing '$required'"
        }
    }
}

if (Test-Path -LiteralPath $protocolPath -PathType Leaf) {
    $protocol = Get-Content -LiteralPath $protocolPath -Raw
    foreach ($required in @(
        'AI-capabilities lifecycle',
        'deterministic adoption discovery',
        'transient handoff manifest',
        'MUST NOT imply that an AI agent is running'
    )) {
        if (-not $protocol.Contains($required)) {
            Add-Failure "TEST-0032 protocol lifecycle contract is missing '$required'"
        }
    }
}

$adapterTestPath = Join-Path $root 'tests/capabilities-bootstrap-adapter.tests.ps1'
if (-not (Test-Path -LiteralPath $adapterTestPath -PathType Leaf)) {
    Add-Failure 'TEST-0028 missing bootstrap adapter integration tests.'
}
elseif ($failures.Count -eq 0) {
    $engine = (Get-Process -Id $PID).Path
    & $engine -NoProfile -ExecutionPolicy Bypass -File $adapterTestPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

if ($failures.Count -gt 0) {
    Write-Host "AI capabilities lifecycle tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'AI capabilities lifecycle tests passed for all declared scenarios in this suite.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities-bootstrap.tests.ps1' `
    -SourcePaths @($PSCommandPath, $adapterTestPath) `
    -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
