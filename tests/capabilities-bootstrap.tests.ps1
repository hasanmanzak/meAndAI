[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
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
            [int]$OpenPullRequestCount = 0
        )

        Resolve-MeAndAICapabilitiesLifecycle -Snapshot ([pscustomobject]@{
            SchemaVersion = 1
            LocalUpdaterState = $LocalUpdaterState
            SeedWorkflowState = $SeedWorkflowState
            Collisions = @($Collisions)
            ManifestExists = $ManifestExists
            RemoteBranchExists = $RemoteBranchExists
            OpenPullRequestCount = $OpenPullRequestCount
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

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true -OpenPullRequestCount 1
    Assert-Equal 'PendingAdoption' $plan.State 'TEST-0031 one pending adoption proposal should remain idempotent'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0031 pending work must not be replaced'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 orphan adoption branch must block'

    $plan = Invoke-LifecyclePlan -OpenPullRequestCount 1
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 PR without deterministic branch must block'

    $plan = Invoke-LifecyclePlan -ManifestExists $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 existing manifest ownership must block'

    $plan = Invoke-LifecyclePlan -SeedWorkflowState 'Drifted'
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 seed workflow drift must block remote execution'
}

if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($required in @(
        'BOOTSTRAP_PROTOCOL_TAG: v0.7.0',
        'ref: ${{ env.BOOTSTRAP_PROTOCOL_TAG }}',
        'MeAndAI.ProtocolUpdate.psm1',
        'Invoke-MeAndAIProtocolUpdate.ps1',
        'Invoke-MeAndAICapabilitiesBootstrap.ps1',
        'Local updater installation is partial',
        'MEANDAI_UPDATER_TOKEN',
        'MEANDAI_PROTOCOL_TOKEN'
    )) {
        if (-not $workflow.Contains($required)) {
            Add-Failure "TEST-0027 workflow is missing '$required'"
        }
    }
    foreach ($forbidden in @('pull_request_target:', 'issues: write', 'gh pr merge', 'actions/checkout@v')) {
        if ($workflow.Contains($forbidden)) {
            Add-Failure "TEST-0032 workflow contains forbidden behavior '$forbidden'"
        }
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
        'BlockedManualReview'
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

Write-Host 'AI capabilities lifecycle tests passed: TEST-0027 through TEST-0032 and TEST-0044.' -ForegroundColor Green
