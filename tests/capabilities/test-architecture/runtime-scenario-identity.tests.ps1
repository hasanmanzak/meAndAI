[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/runtime-scenario-identity.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$fixtureAuthorityPath = Join-Path $PSScriptRoot `
    'fixtures/runtime-scenario-identity/scenario-ownership.psd1.fixture'
$scenarioEvidenceModulePath = Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1'
$testRuntimeModulePath = Join-Path $root `
    'tests/infrastructure/MeAndAI.TestRuntime.psm1'

Import-Module $scenarioEvidenceModulePath -Force
Import-Module $testRuntimeModulePath -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestAssertions.psm1') -Force

$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures
$exactOwner = 'fixtures/runtime-scenario-identity/exact.tests.ps1'

try {
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
    $caseOwner = 'fixtures/runtime-scenario-identity/exact.case.ps1'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAICaseEvidenceContext -SuiteOwner $exactOwner `
            -CaseOwner 'fixtures/runtime-scenario-identity/not-a-case.ps1' `
            -TestIds @('TEST-9001') -AuthorityPath $fixtureAuthorityPath
    } -Pattern '*canonical repository-relative path*' `
        -Message 'TEST-0185 accepted a non-canonical Case owner.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAICaseEvidenceContext -SuiteOwner $exactOwner `
            -CaseOwner $caseOwner -TestIds @('TEST-9001', 'TEST-9001') `
            -AuthorityPath $fixtureAuthorityPath
    } -Pattern '*duplicates*' `
        -Message 'TEST-0185 accepted a duplicate Case subset.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAICaseEvidenceContext -SuiteOwner $exactOwner `
            -CaseOwner $caseOwner -TestIds @('TEST-9002') `
            -AuthorityPath $fixtureAuthorityPath
    } -Pattern '*not owned by suite*' `
        -Message 'TEST-0185 accepted a non-canonical Case subset.'

    $caseContext = New-MeAndAICaseEvidenceContext -SuiteOwner $exactOwner `
        -CaseOwner $caseOwner -TestIds @('TEST-9001') `
        -AuthorityPath $fixtureAuthorityPath
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-9002'
    } -Pattern '*not assigned to case*' `
        -Message 'TEST-0185 accepted an unexpected Case identity.'
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-9001'
    $caseResult = New-MeAndAICaseResult -Context $caseContext
    Assert-MeAndAITestSequenceEqual -Actual @($caseResult.Keys) `
        -Expected @('schema', 'suite', 'case', 'passed') `
        -Message 'TEST-0185 Case result exposes non-canonical fields.'
    Assert-MeAndAITestEqual -Actual ([long]$caseResult.schema) `
        -Expected ([long]1) -Message 'TEST-0185 Case result schema changed.'
    Assert-MeAndAITestEqual -Actual ([string]$caseResult.suite) `
        -Expected $exactOwner -Message 'TEST-0185 Case suite identity changed.'
    Assert-MeAndAITestEqual -Actual ([string]$caseResult.case) `
        -Expected $caseOwner -Message 'TEST-0185 Case owner identity changed.'
    Assert-MeAndAITestSequenceEqual -Actual @($caseResult.passed) `
        -Expected @('TEST-9001') `
        -Message 'TEST-0185 exact Case runtime evidence changed.'
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-9001'
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 allowed finalized Case mutation.'
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAICaseResult -Context $caseContext
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 allowed Case re-finalization.'

    $duplicateCaseContext = New-MeAndAICaseEvidenceContext `
        -SuiteOwner $exactOwner -CaseOwner $caseOwner `
        -TestIds @('TEST-9001') -AuthorityPath $fixtureAuthorityPath
    Confirm-MeAndAICaseEvidence -Context $duplicateCaseContext `
        -TestId 'TEST-9001'
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAICaseEvidence -Context $duplicateCaseContext `
            -TestId 'TEST-9001'
    } -Pattern '*confirmed more than once*' `
        -Message 'TEST-0185 accepted duplicate Case evidence.'
    [void](New-MeAndAICaseResult -Context $duplicateCaseContext)

    $missingCaseContext = New-MeAndAICaseEvidenceContext `
        -SuiteOwner $exactOwner -CaseOwner $caseOwner `
        -TestIds @('TEST-9001') -AuthorityPath $fixtureAuthorityPath
    Assert-MeAndAITestThrowsLike -Action {
        New-MeAndAICaseResult -Context $missingCaseContext
    } -Pattern '*missing or unexecuted: TEST-9001*' `
        -Message 'TEST-0185 accepted missing Case evidence.'
    Assert-MeAndAITestThrowsLike -Action {
        Confirm-MeAndAICaseEvidence -Context $missingCaseContext `
            -TestId 'TEST-9001'
    } -Pattern '*already finalized*' `
        -Message 'TEST-0185 allowed failed-finalization Case mutation.'
}
catch {
    Add-Failure "TEST-0185 Case context contract failed: $($_.Exception.Message)"
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

$caseProcessRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-test-0185-case-' + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($caseProcessRoot) | Out-Null
    $caseProcessPath = Join-Path $caseProcessRoot 'runtime-evidence.case.ps1'
    $processCaseOwner = 'fixtures/runtime-scenario-identity/process.case.ps1'
    $caseProcessSource = @'
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$EvidenceModulePath,
    [Parameter(Mandatory)][string]$AuthorityPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module $EvidenceModulePath -Force
$suiteOwner = 'fixtures/runtime-scenario-identity/exact.tests.ps1'
$caseOwner = 'fixtures/runtime-scenario-identity/process.case.ps1'
$context = New-MeAndAICaseEvidenceContext -SuiteOwner $suiteOwner `
    -CaseOwner $caseOwner -TestIds @('TEST-9001') `
    -AuthorityPath $AuthorityPath
Confirm-MeAndAICaseEvidence -Context $context -TestId 'TEST-9001'
$result = New-MeAndAICaseResult -Context $context
Write-Output ('MEANDAI_CASE_RESULTS=' + ($result | ConvertTo-Json -Compress))
'@
    [IO.File]::WriteAllText(
        $caseProcessPath, $caseProcessSource,
        [Text.UTF8Encoding]::new($false)
    )
    Assert-MeAndAITestThrowsLike -Action {
        Invoke-MeAndAITestCaseProcess `
            -EnginePath ([string](Get-Process -Id $PID).Path) `
            -CasePath (Join-Path $caseProcessRoot 'runtime-evidence.CASE.PS1')
    } -Pattern "*must end exactly in '.case.ps1'*" `
        -Message 'TEST-0185 accepted a non-exact Case process suffix.'
    $caseProcess = Invoke-MeAndAITestCaseProcess `
        -EnginePath ([string](Get-Process -Id $PID).Path) `
        -CasePath $caseProcessPath -Arguments @(
            '-EvidenceModulePath', $scenarioEvidenceModulePath,
            '-AuthorityPath', $fixtureAuthorityPath
        )
    Assert-MeAndAITestEqual -Actual ([int]$caseProcess.ExitCode) `
        -Expected 0 -Message 'TEST-0185 synthetic Case process failed.'
    $parsedCase = Read-MeAndAICaseResultRecord -Output @($caseProcess.Output) `
        -ExpectedSuite $exactOwner -ExpectedCase $processCaseOwner `
        -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition ([bool]$parsedCase.Valid) `
        -Message "TEST-0185 rejected exact Case output: $($parsedCase.Message)"
    Assert-MeAndAITestSequenceEqual `
        -Actual @($parsedCase.Record.PSObject.Properties.Name) `
        -Expected @('schema', 'suite', 'case', 'passed') `
        -Message 'TEST-0185 normalized Case record shape changed.'
    Assert-MeAndAITestEqual -Actual ([long]$parsedCase.Record.schema) `
        -Expected ([long]1) -Message 'TEST-0185 normalized Case schema changed.'
    Assert-MeAndAITestEqual -Actual ([string]$parsedCase.Record.suite) `
        -Expected $exactOwner -Message 'TEST-0185 normalized Case suite changed.'
    Assert-MeAndAITestEqual -Actual ([string]$parsedCase.Record.case) `
        -Expected $processCaseOwner -Message 'TEST-0185 normalized Case owner changed.'
    Assert-MeAndAITestSequenceEqual -Actual @($parsedCase.Record.passed) `
        -Expected @('TEST-9001') `
        -Message 'TEST-0185 normalized Case IDs changed.'

    $caseResultLines = @($caseProcess.Output | ForEach-Object { [string]$_ } |
        Where-Object {
            $_.StartsWith('MEANDAI_CASE_RESULTS=', [StringComparison]::Ordinal)
        })
    Assert-MeAndAITestEqual -Actual $caseResultLines.Count -Expected 1 `
        -Message 'TEST-0185 synthetic Case emitted a non-exact marker count.'
    $caseResultLine = $caseResultLines[0]

    $missingCaseRecord = Read-MeAndAICaseResultRecord -Output @('noise') `
        -ExpectedSuite $exactOwner -ExpectedCase $processCaseOwner `
        -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition (-not $missingCaseRecord.Valid) `
        -Message 'TEST-0185 accepted missing Case result output.'
    $duplicateCaseRecord = Read-MeAndAICaseResultRecord `
        -Output @($caseResultLine, $caseResultLine) `
        -ExpectedSuite $exactOwner -ExpectedCase $processCaseOwner `
        -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition (-not $duplicateCaseRecord.Valid) `
        -Message 'TEST-0185 accepted duplicate Case result output.'
    $nonFinalCaseRecord = Read-MeAndAICaseResultRecord `
        -Output @($caseResultLine, 'trailing output') `
        -ExpectedSuite $exactOwner -ExpectedCase $processCaseOwner `
        -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition (-not $nonFinalCaseRecord.Valid) `
        -Message 'TEST-0185 accepted a non-final Case result.'
    $mixedCaseRecord = Read-MeAndAICaseResultRecord -Output @(
            'MEANDAI_SCENARIO_RESULTS={}', $caseResultLine
        ) -ExpectedSuite $exactOwner -ExpectedCase $processCaseOwner `
        -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition (-not $mixedCaseRecord.Valid) `
        -Message 'TEST-0185 accepted a suite result in the Case channel.'

    $compatibilityLine = 'MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
        ([ordered]@{
            schema = 1
            suite = $exactOwner
            shard = 'synthetic-shard'
            passed = $true
        } | ConvertTo-Json -Compress)
    $compatibilityRecord = Read-MeAndAICompatibilityShardResultRecord `
        -Output @($compatibilityLine) -ExpectedSuite $exactOwner `
        -ExpectedShard 'synthetic-shard'
    Assert-MeAndAITestTrue -Condition ([bool]$compatibilityRecord.Valid) `
        -Message 'TEST-0185 rejected exact compatibility output.'
    $compatibilityWithScenario = Read-MeAndAICompatibilityShardResultRecord `
        -Output @('MEANDAI_SCENARIO_RESULTS={}', $compatibilityLine) `
        -ExpectedSuite $exactOwner -ExpectedShard 'synthetic-shard'
    Assert-MeAndAITestTrue -Condition (-not $compatibilityWithScenario.Valid) `
        -Message 'TEST-0185 compatibility output accepted a scenario channel.'
    $compatibilityWithCase = Read-MeAndAICompatibilityShardResultRecord `
        -Output @($caseResultLine, $compatibilityLine) `
        -ExpectedSuite $exactOwner -ExpectedShard 'synthetic-shard'
    Assert-MeAndAITestTrue -Condition (-not $compatibilityWithCase.Valid) `
        -Message 'TEST-0185 compatibility output accepted a Case channel.'

    $wrongSuiteRecord = Read-MeAndAICaseResultRecord `
        -Output @($caseResultLine) -ExpectedSuite 'wrong.tests.ps1' `
        -ExpectedCase $processCaseOwner -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition (-not $wrongSuiteRecord.Valid) `
        -Message 'TEST-0185 accepted the wrong Case suite identity.'
    $wrongCaseRecord = Read-MeAndAICaseResultRecord `
        -Output @($caseResultLine) -ExpectedSuite $exactOwner `
        -ExpectedCase 'fixtures/runtime-scenario-identity/wrong.case.ps1' `
        -ExpectedTestIds @('TEST-9001')
    Assert-MeAndAITestTrue -Condition (-not $wrongCaseRecord.Valid) `
        -Message 'TEST-0185 accepted the wrong Case owner identity.'
    $wrongIdsRecord = Read-MeAndAICaseResultRecord `
        -Output @($caseResultLine) -ExpectedSuite $exactOwner `
        -ExpectedCase $processCaseOwner -ExpectedTestIds @('TEST-9002')
    Assert-MeAndAITestTrue -Condition (-not $wrongIdsRecord.Valid) `
        -Message 'TEST-0185 accepted the wrong Case ID subset.'
}
catch {
    Add-Failure "TEST-0185 Case process contract failed: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $caseProcessRoot) {
        Remove-Item -LiteralPath $caseProcessRoot -Recurse -Force
    }
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
