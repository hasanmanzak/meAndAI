[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/test-architecture.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$runtimeModulePath = Join-Path $root 'tests/infrastructure/MeAndAI.TestRuntime.psm1'
$testContextModulePath = Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestDiscovery.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module $runtimeModulePath -Force
Import-Module $testContextModulePath -Force
$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $authorityPath
$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures

$test0137FailureCount = $failures.Count
$suites = @(Get-MeAndAITestSuite -RepositoryRoot $root)
$ownerSet = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($suite in $suites) {
    if ($suite.Owner -cnotmatch '^tests/capabilities/[a-z0-9]+(?:-[a-z0-9]+)*/[^/]+(?:/[^/]+)*\.tests\.ps1$') {
        Add-Failure "TEST-0137 canonical suite is not capability-owned: $($suite.Owner)."
    }
    if (-not $ownerSet.Add([string]$suite.Owner)) {
        Add-Failure "TEST-0137 canonical nested suite owner is duplicated: $($suite.Owner)."
    }
}

$rootLevelSuites = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') `
    -File -Filter '*.tests.ps1')
if ($rootLevelSuites.Count -ne 1 -or
    $rootLevelSuites[0].Name -cne 'protocol.tests.ps1') {
    Add-Failure 'TEST-0137 tests/protocol.tests.ps1 must be the only root-level test entry point.'
}
$authority = Import-PowerShellDataFile -LiteralPath $authorityPath
foreach ($entry in @($authority.Authorities | Where-Object {
    [string]$_.Evidence -ceq 'ExecutableSuite'
})) {
    if (-not $ownerSet.Contains([string]$entry.Owner)) {
        Add-Failure "TEST-0137 executable scenario authority is not a nested canonical suite: $($entry.Owner)."
    }
}
if ($failures.Count -eq $test0137FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0137'
}

$test0138FailureCount = $failures.Count
$runnerPath = Join-Path $root 'tests/protocol.tests.ps1'
$runnerLines = @(Get-Content -LiteralPath $runnerPath)
$runnerSource = $runnerLines -join "`n"
if ($runnerLines.Count -gt 180 -or
    -not $runnerSource.Contains('Get-MeAndAITestSuite') -or
    -not $runnerSource.Contains('Import-MeAndAITestExecutionProfile') -or
    -not $runnerSource.Contains('Invoke-MeAndAITestSuiteProcess')) {
    Add-Failure 'TEST-0138 stable root runner is not a thin discovery/profile/process orchestrator.'
}
$authorityGuardIndex = $runnerSource.IndexOf(
    'foreach ($owner in $selectedOwners)', [StringComparison]::Ordinal
)
$suiteExecutionIndex = $runnerSource.IndexOf(
    'foreach ($selectedSuite in @($selectedProfiles[0].Suites))',
    [StringComparison]::Ordinal
)
if ($authorityGuardIndex -lt 0 -or $suiteExecutionIndex -lt 0 -or
    $authorityGuardIndex -ge $suiteExecutionIndex) {
    Add-Failure 'TEST-0138 selected suite authority is not validated before child execution.'
}
$exactAuthorityGuardIndex = $runnerSource.IndexOf(
    '$ownerComparison = Compare-Object', [StringComparison]::Ordinal
)
$firstChildInvocationIndex = $runnerSource.IndexOf(
    '[void](Invoke-SuiteAndRelay', [StringComparison]::Ordinal
)
if ($exactAuthorityGuardIndex -lt 0 -or $firstChildInvocationIndex -lt 0 -or
    $exactAuthorityGuardIndex -ge $firstChildInvocationIndex -or
    -not $runnerSource.Contains('Scenario authority must expose one canonical authority array.') -or
    -not $runnerSource.Contains('Executable scenario authority test ID is duplicated:')) {
    Add-Failure 'TEST-0138 exact authority shape, IDs, and owner inventory are not validated before every child.'
}
$runtimeSource = Get-Content -LiteralPath (
    Join-Path $root 'tests/infrastructure/MeAndAI.TestRuntime.psm1'
) -Raw
if (-not $runtimeSource.Contains('& $EnginePath @processArguments') -or
    -not $runtimeSource.Contains("'-NoProfile', '-ExecutionPolicy', 'Bypass', '-File'")) {
    Add-Failure 'TEST-0138 canonical suites are not executed through one isolated child process each.'
}

$test0144FailureCount = $failures.Count
$runtimeFixtureRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-test-runtime-' + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($runtimeFixtureRoot) | Out-Null
    $successChild = Join-Path $runtimeFixtureRoot 'success.ps1'
    $failureChild = Join-Path $runtimeFixtureRoot 'failure.ps1'
    [IO.File]::WriteAllText($successChild, `
        "Write-Output 'alpha'`nWrite-Output 'omega'`nexit 0`n", `
        [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($failureChild, `
        "Write-Output 'expected failure'`nexit 7`n", `
        [Text.UTF8Encoding]::new($false))

    $enginePath = (Get-Process -Id $PID).Path
    $successfulProcess = Invoke-MeAndAITestSuiteProcess `
        -EnginePath $enginePath -SuitePath $successChild
    $failedProcess = Invoke-MeAndAITestSuiteProcess `
        -EnginePath $enginePath -SuitePath $failureChild
    foreach ($processCase in @(
        [pscustomobject]@{
            Name = 'successful'
            Result = $successfulProcess
            ExitCode = 0
            Output = @('alpha', 'omega')
        },
        [pscustomobject]@{
            Name = 'failed'
            Result = $failedProcess
            ExitCode = 7
            Output = @('expected failure')
        }
    )) {
        $elapsedProperty = $processCase.Result.PSObject.Properties['ElapsedMilliseconds']
        if ($null -eq $elapsedProperty -or
            $elapsedProperty.Value -isnot [long] -or
            [long]$elapsedProperty.Value -lt 0) {
            Add-Failure "TEST-0144 $($processCase.Name) child has no normalized non-negative Int64 elapsed observation."
        }
        if ([int]$processCase.Result.ExitCode -ne $processCase.ExitCode -or
            (@($processCase.Result.Output) -join "`n") -cne `
                (@($processCase.Output) -join "`n")) {
            Add-Failure "TEST-0144 $($processCase.Name) child timing changed exit or output authority."
        }
    }

    $formatter = Get-Command -Name 'Format-MeAndAITestSuiteObservation' `
        -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $formatter) {
        Add-Failure 'TEST-0144 canonical suite observation formatter is missing.'
    }
    else {
        $expectedOwner = 'tests/capabilities/test-architecture/test-architecture.tests.ps1'
        $line = & $formatter -Owner $expectedOwner -ElapsedMilliseconds ([long]42)
        if ($line -isnot [string] -or
            -not $line.StartsWith('MEANDAI_SUITE_OBSERVATION=', `
                [StringComparison]::Ordinal)) {
            Add-Failure 'TEST-0144 suite observation line has no canonical prefix.'
        }
        else {
            try {
                $observation = $line.Substring(
                    'MEANDAI_SUITE_OBSERVATION='.Length) | ConvertFrom-Json
                $observationProperties = @(
                    $observation.PSObject.Properties | ForEach-Object { $_.Name }
                )
                if ($observationProperties.Count -ne 3 -or
                    $observationProperties -cnotcontains 'schema' -or
                    $observationProperties -cnotcontains 'owner' -or
                    $observationProperties -cnotcontains 'elapsedMs' -or
                    [long]$observation.schema -ne 1 -or
                    [string]$observation.owner -cne $expectedOwner -or
                    [long]$observation.elapsedMs -ne 42 -or
                    $observationProperties -contains 'passed' -or
                    $observationProperties -contains 'exitCode' -or
                    $observationProperties -contains 'status') {
                    Add-Failure 'TEST-0144 suite observation schema or authority boundary is invalid.'
                }
            }
            catch {
                Add-Failure "TEST-0144 suite observation JSON is invalid: $($_.Exception.Message)"
            }
        }

        foreach ($invalidObservation in @(
            [pscustomobject]@{ Owner = ''; Elapsed = [long]0; Name = 'empty owner' },
            [pscustomobject]@{ Owner = $expectedOwner; Elapsed = [long]-1; Name = 'negative elapsed time' },
            [pscustomobject]@{ Owner = $expectedOwner; Elapsed = [double]1.5; Name = 'fractional elapsed time' }
        )) {
            $rejected = $false
            try {
                [void](& $formatter -Owner $invalidObservation.Owner `
                    -ElapsedMilliseconds $invalidObservation.Elapsed)
            }
            catch { $rejected = $true }
            if (-not $rejected) {
                Add-Failure "TEST-0144 formatter accepted $($invalidObservation.Name)."
            }
        }
    }

    if (-not $runnerSource.Contains('Format-MeAndAITestSuiteObservation')) {
        Add-Failure 'TEST-0144 stable runner does not emit the production suite observation contract.'
    }
}
catch {
    Add-Failure "TEST-0144 runtime fixture failed: $($_.Exception.Message) [$($_.ScriptStackTrace)]"
}
finally {
    if (Test-Path -LiteralPath $runtimeFixtureRoot) {
        Remove-Item -LiteralPath $runtimeFixtureRoot -Recurse -Force `
            -ErrorAction SilentlyContinue
    }
}
if ($failures.Count -eq $test0144FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0144'
}
$governanceSource = Get-Content -LiteralPath (Join-Path $root `
    'tests/capabilities/protocol-governance/protocol-governance.tests.ps1') -Raw
if ($governanceSource.Contains('function Compare-ExactScenarioIds') -or
    $governanceSource.Contains('function Read-ScenarioResultRecord') -or
    $governanceSource.Contains('function Read-CompatibilityShardResultRecord') -or
    -not $governanceSource.Contains('MeAndAI.TestRuntime.psm1')) {
    Add-Failure 'TEST-0138 common scenario/runtime logic is duplicated outside infrastructure.'
}

$fixtureRoot = Join-Path $root 'tests/fixtures'
if (Test-Path -LiteralPath $fixtureRoot) {
    $orphanedFixtures = @(Get-ChildItem -LiteralPath $fixtureRoot -Recurse -File)
    if ($orphanedFixtures.Count -gt 0) {
        Add-Failure 'TEST-0138 mutable fixtures remain outside a capability owner.'
    }
}
$adapterFixtures = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests/capabilities') `
    -Recurse -File -Filter '*.fixture.ps1')
$adapterFixturePaths = @($adapterFixtures | ForEach-Object {
    $_.FullName.Substring($root.Length + 1).Replace('\', '/')
})
[Array]::Sort($adapterFixturePaths, [StringComparer]::Ordinal)
$expectedAdapterFixturePaths = @()
if (($adapterFixturePaths -join "`0") -cne
    ($expectedAdapterFixturePaths -join "`0") -or
    @($adapterFixturePaths | Where-Object {
        $ownerSet.Contains([string]$_)
    }).Count -ne 0) {
    Add-Failure 'TEST-0138 adapter fixtures are not isolated from canonical suite discovery.'
}

$legacyFixture = Join-Path $root `
    'tests/capabilities/consumer-update/fixtures/legacy-pre-engine-consumer/Verify-MeAndAIAdoption.ps1'
$legacyBlob = @(& git -C $root hash-object -- $legacyFixture 2>&1)
if ($LASTEXITCODE -ne 0 -or $legacyBlob.Count -ne 1 -or
    [string]$legacyBlob[0] -cne '1dffab9c6b6d6f22aedb83c313b95d7b0f275183') {
    Add-Failure 'TEST-0138 frozen legacy fixture bytes changed during capability isolation.'
}
$shellFixtureOwner = 'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.sh'
$shellFixture = Join-Path $root $shellFixtureOwner
$shellFixtureBlob = @(& git -C $root hash-object -- $shellFixture 2>&1)
$shellFixtureIndex = @(& git -C $root ls-files --stage -- $shellFixtureOwner 2>&1)
if ($LASTEXITCODE -ne 0 -or $shellFixtureBlob.Count -ne 1 -or
    [string]$shellFixtureBlob[0] -cne '7a1d8a42cc0492ff1511a31da6f44c389a3bf279' -or
    $shellFixtureIndex.Count -ne 1 -or
    [string]$shellFixtureIndex[0] -cnotmatch '^100755 7a1d8a42cc0492ff1511a31da6f44c389a3bf279 0\s+') {
    Add-Failure 'TEST-0138 relocated shell fixture lost its executable mode or exact bytes.'
}
if ($failures.Count -eq $test0138FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0138'
}

if ($failures.Count -gt 0) {
    Write-Host "Test-architecture validation failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
Write-Host 'Test-architecture topology and isolation contracts passed.' -ForegroundColor Green
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
