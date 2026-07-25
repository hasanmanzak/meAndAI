[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/runtime-scenario-identity.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$fixtureAuthorityPath = Join-Path $PSScriptRoot `
    'fixtures/runtime-scenario-identity/scenario-ownership.psd1.fixture'

Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestAssertions.psm1') -Force

$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures

try {
    $exactOwner = 'fixtures/runtime-scenario-identity/exact.tests.ps1'
    $exactContext = New-MeAndAIScenarioEvidenceContext `
        -Owner $exactOwner -AuthorityPath $fixtureAuthorityPath
    Confirm-MeAndAIScenarioEvidence -Context $exactContext `
        -TestId 'TEST-9001'
    $exactResult = New-MeAndAIScenarioResult -Context $exactContext
    Assert-MeAndAITestSequenceEqual -Actual @($exactResult.Keys) `
        -Expected @('schema', 'owner', 'passed') `
        -Message 'TEST-0185 scenario result exposes non-canonical fields.'
    Assert-MeAndAITestEqual -Actual ([long]$exactResult.schema) `
        -Expected ([long]1) -Message 'TEST-0185 scenario result schema changed.'
    Assert-MeAndAITestEqual -Actual ([string]$exactResult.owner) `
        -Expected $exactOwner -Message 'TEST-0185 scenario result owner changed.'
    Assert-MeAndAITestSequenceEqual -Actual @($exactResult.passed) `
        -Expected @('TEST-9001') `
        -Message 'TEST-0185 exact runtime evidence was not emitted once.'
}
catch {
    Add-Failure "TEST-0185 exact success failed: $($_.Exception.Message)"
}

try {
    $missingContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/missing.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAIScenarioEvidence -Context $missingContext `
            -TestId 'TEST-9999'
    } -Pattern '*is not owned by*' `
        -Message 'TEST-0185 unexpected runtime identity was accepted.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $missingContext
    } -Pattern '*missing or unexecuted: TEST-9002*' `
        -Message 'TEST-0185 missing runtime evidence was accepted.'
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAIScenarioEvidence -Context $missingContext `
            -TestId 'TEST-9002'
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 failed finalization allowed context mutation.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $missingContext
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 failed finalization allowed re-finalization.'
}
catch {
    Add-Failure "TEST-0185 missing-case guard failed: $($_.Exception.Message)"
}

try {
    $duplicateContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/duplicate.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    Confirm-MeAndAIScenarioEvidence -Context $duplicateContext `
        -TestId 'TEST-9003'
    $duplicateProbe = @{ ActionRan = $false }
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAIScenarioEvidence -Context $duplicateContext `
            -TestId 'TEST-9003'
        $duplicateProbe.ActionRan = $true
    } -Pattern '*confirmed more than once*' `
        -Message 'TEST-0185 duplicate confirmation was accepted.'
    Assert-MeAndAITestTrue -Condition (-not $duplicateProbe.ActionRan) `
        -Message 'TEST-0185 duplicate evidence was not rejected before action.'
    [void](New-MeAndAIScenarioResult -Context $duplicateContext)
}
catch {
    Add-Failure "TEST-0185 duplicate-case guard failed: $($_.Exception.Message)"
}

try {
    $sourceStringContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/source-string.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    $sourceString = "throw 'TEST-9004 source text is not runtime evidence'"
    Assert-MeAndAITestTrue -Condition $sourceString.Contains('TEST-9004') `
        -Message 'TEST-0185 source-string control is invalid.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $sourceStringContext
    } -Pattern '*missing or unexecuted: TEST-9004*' `
        -Message 'TEST-0185 source-string inference was accepted.'

    $constantContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/test-constant.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    $testConstant = 'TEST-9005'
    Assert-MeAndAITestEqual -Actual $testConstant -Expected 'TEST-9005' `
        -Message 'TEST-0185 TEST-constant control is invalid.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $constantContext
    } -Pattern '*missing or unexecuted: TEST-9005*' `
        -Message 'TEST-0185 TEST-constant inference was accepted.'

    $unexecutedContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/unexecuted.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $unexecutedContext
    } -Pattern '*missing or unexecuted: TEST-9006*' `
        -Message 'TEST-0185 unexecuted scenario was accepted.'
}
catch {
    Add-Failure "TEST-0185 inference guard failed: $($_.Exception.Message)"
}

try {
    $failedActionContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/failed-action.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    $failedActionObserved = $false
    try {
        & { throw 'synthetic action failed' }
        Confirm-MeAndAIScenarioEvidence -Context $failedActionContext `
            -TestId 'TEST-9007'
    }
    catch {
        $failedActionObserved = $_.Exception.Message -ceq
            'synthetic action failed'
    }
    Assert-MeAndAITestTrue -Condition $failedActionObserved `
        -Message 'TEST-0185 failed-action control did not fail.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $failedActionContext
    } -Pattern '*missing or unexecuted: TEST-9007*' `
        -Message 'TEST-0185 failed action produced runtime evidence.'
}
catch {
    Add-Failure "TEST-0185 failed-action guard failed: $($_.Exception.Message)"
}

try {
    $collectedScenarioContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/collected-failure.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    $collectedActionContext = New-MeAndAITestContext
    Assert-MeAndAITestCollectedTrue -Context $collectedActionContext `
        -Condition $false -Message 'synthetic collected failure'
    if (@(Get-MeAndAITestFailures -Context $collectedActionContext).Count `
        -eq 0) {
        Confirm-MeAndAIScenarioEvidence -Context $collectedScenarioContext `
            -TestId 'TEST-9008'
    }
    Assert-MeAndAITestSequenceEqual `
        -Actual @(Get-MeAndAITestFailures -Context $collectedActionContext) `
        -Expected @('synthetic collected failure') `
        -Message 'TEST-0185 collected-failure control is invalid.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $collectedScenarioContext
    } -Pattern '*missing or unexecuted: TEST-9008*' `
        -Message 'TEST-0185 collected failure produced runtime evidence.'
}
catch {
    Add-Failure "TEST-0185 collected-failure guard failed: $($_.Exception.Message)"
}

try {
    $finalizedContext = New-MeAndAIScenarioEvidenceContext `
        -Owner 'fixtures/runtime-scenario-identity/post-finalization.tests.ps1' `
        -AuthorityPath $fixtureAuthorityPath
    Confirm-MeAndAIScenarioEvidence -Context $finalizedContext `
        -TestId 'TEST-9009'
    [void](New-MeAndAIScenarioResult -Context $finalizedContext)
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAIScenarioEvidence -Context $finalizedContext `
            -TestId 'TEST-9009'
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 post-finalization mutation was accepted.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAIScenarioResult -Context $finalizedContext
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 duplicate finalization was accepted.'
}
catch {
    Add-Failure "TEST-0185 finalization guard failed: $($_.Exception.Message)"
}

$outerContext = $null
try {
    $outerContext = New-MeAndAIScenarioEvidenceContext `
        -Owner $owner -AuthorityPath $authorityPath
}
catch {
    Add-Failure "TEST-0185 executable authority is invalid: $($_.Exception.Message)"
}

if ($failures.Count -gt 0) {
    Write-Host "Runtime scenario identity validation failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -Context $outerContext -TestId 'TEST-0185'
$scenarioResult = New-MeAndAIScenarioResult -Context $outerContext
Write-Host 'Exact-once runtime scenario identity contracts passed.' `
    -ForegroundColor Green
Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
    ($scenarioResult | ConvertTo-Json -Compress))
