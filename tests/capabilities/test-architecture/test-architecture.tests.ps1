[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestDiscovery.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

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
if ($adapterFixtures.Count -ne 2 -or @($adapterFixtures | Where-Object {
    $_.Name -like '*.tests.ps1'
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

if ($failures.Count -gt 0) {
    Write-Host "Test-architecture validation failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities/test-architecture/test-architecture.tests.ps1' `
    -SourcePaths @($PSCommandPath) -AuthorityPath $authorityPath
Write-Host 'Test-architecture topology and isolation contracts passed.' -ForegroundColor Green
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
