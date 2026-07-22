[CmdletBinding()]
param(
    [switch]$StructureOnly,
    [ValidateSet('Full', 'WindowsNative')]
    [string]$ExecutionProfile = 'Full'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($StructureOnly -and $ExecutionProfile -cne 'Full') {
    throw 'StructureOnly cannot be combined with a partial execution profile.'
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$discoveryModule = Join-Path $root 'tests/infrastructure/MeAndAI.TestDiscovery.psm1'
$runtimeModule = Join-Path $root 'tests/infrastructure/MeAndAI.TestRuntime.psm1'
$operationPath = Join-Path $root 'tests/fixture-operation-budgets.psd1'
$profilePath = Join-Path $root 'tests/execution-profiles.psd1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module $discoveryModule -Force
Import-Module $runtimeModule -Force
$operationContract = Import-MeAndAITestOperationContract -Path $operationPath

$suites = @(Get-MeAndAITestSuite -RepositoryRoot $root)
$profiles = @(Import-MeAndAITestExecutionProfile -LiteralPath $profilePath `
    -DiscoveredSuite $suites)
$selectedProfiles = @($profiles | Where-Object { $_.Name -ceq $ExecutionProfile })
if ($selectedProfiles.Count -ne 1) {
    throw "Execution profile '$ExecutionProfile' is missing or ambiguous."
}

$governanceOwner = 'tests/capabilities/protocol-governance/protocol-governance.tests.ps1'
$governanceSuites = @($suites | Where-Object { $_.Owner -ceq $governanceOwner })
if ($governanceSuites.Count -ne 1) {
    throw "Canonical protocol-governance suite '$governanceOwner' is missing or ambiguous."
}

$engine = (Get-Process -Id $PID).Path
function Invoke-SuiteAndRelay {
    param(
        [Parameter(Mandatory)]$Suite,
        [string[]]$Arguments = @()
    )

    $result = Invoke-MeAndAITestSuiteProcess -EnginePath $engine `
        -SuitePath $Suite.FullName -Arguments $Arguments
    foreach ($line in @($result.Output)) {
        Write-Host ([string]$line)
    }
    Write-Host (Format-MeAndAITestSuiteObservation -Owner $Suite.Owner `
        -ElapsedMilliseconds $result.ElapsedMilliseconds)
    if ($result.ExitCode -ne 0) {
        throw "Child test suite failed: $($Suite.Owner)"
    }
    return $result
}

$authority = Import-PowerShellDataFile -LiteralPath $authorityPath
if ([long]$authority.SchemaVersion -ne 1) {
    throw 'Scenario authority schema version must be 1.'
}
if ($authority.Authorities -isnot [Array]) {
    throw 'Scenario authority must expose one canonical authority array.'
}
$authorityByOwner = [System.Collections.Generic.Dictionary[string,object]]::new(
    [System.StringComparer]::Ordinal
)
$authorityTestIds = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($entry in @($authority.Authorities | Where-Object {
    [string]$_.Evidence -ceq 'ExecutableSuite'
})) {
    $owner = @(Resolve-MeAndAITestOwnerSet -Owner @([string]$entry.Owner))[0]
    if ($authorityByOwner.ContainsKey($owner)) {
        throw "Executable scenario authority owner is duplicated: '$owner'."
    }
    $testIds = @($entry.TestIds | ForEach-Object { [string]$_ })
    if ($testIds.Count -eq 0) {
        throw "Executable scenario authority '$owner' has no test IDs."
    }
    foreach ($testId in $testIds) {
        if ($testId -cnotmatch '^TEST-[0-9]{4}$') {
            throw "Executable scenario authority '$owner' has malformed test ID '$testId'."
        }
        if (-not $authorityTestIds.Add($testId)) {
            throw "Executable scenario authority test ID is duplicated: '$testId'."
        }
    }
    $authorityByOwner.Add($owner, $testIds)
}

$discoveredOwners = @(Resolve-MeAndAITestOwnerSet -Owner @($suites.Owner))
$authorityOwners = @(Resolve-MeAndAITestOwnerSet -Owner @($authorityByOwner.Keys))
$ownerComparison = Compare-Object -ReferenceObject $discoveredOwners `
    -DifferenceObject $authorityOwners -CaseSensitive
if ($null -ne $ownerComparison) {
    throw 'Discovered canonical suites and executable scenario authority owners do not match exactly.'
}
$selectedOwners = @(Resolve-MeAndAITestOwnerSet `
    -Owner @($selectedProfiles[0].Suites.Owner))
foreach ($owner in $selectedOwners) {
    if (-not $authorityByOwner.ContainsKey($owner)) {
        throw "Selected canonical suite has no executable scenario authority: '$owner'."
    }
}

if ($StructureOnly) {
    [void](Invoke-SuiteAndRelay -Suite $governanceSuites[0] `
        -Arguments @('-StructureOnly'))
    Write-Host 'Protocol structure validation passed for all discovered contracts.' `
        -ForegroundColor Green
    exit 0
}

if ($ExecutionProfile -cne 'Full') {
    [void](Invoke-SuiteAndRelay -Suite $governanceSuites[0] `
        -Arguments @('-StructureOnly'))
}

$completedOwners = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($selectedSuite in @($selectedProfiles[0].Suites)) {
    $result = Invoke-SuiteAndRelay -Suite $selectedSuite `
        -Arguments @($selectedSuite.Arguments)
    $operationExpectation = Resolve-MeAndAITestOperationExpectation `
        -Contract $operationContract -Owner $selectedSuite.Owner `
        -SuiteArguments @($selectedSuite.Arguments)
    if ($null -ne $operationExpectation -and
        $operationExpectation.RequiresObservation) {
        $operationRecord = Read-MeAndAITestOperationObservationRecord `
            -Output @($result.Output) `
            -ExpectedOwner $operationExpectation.Owner `
            -ExpectedRoute $operationExpectation.Route `
            -ExpectedRuntime $operationExpectation.Runtime `
            -ExpectedCounters @($operationExpectation.Counters)
        if (-not $operationRecord.Valid) {
            throw "Suite '$($selectedSuite.Owner)' has invalid operation evidence: $($operationRecord.Message)."
        }
    }
    elseif ($null -ne $operationExpectation) {
        $unexpectedOperationEvidence = @($result.Output | ForEach-Object {
            [string]$_
        } | Where-Object {
            $_.StartsWith('MEANDAI_OPERATION_OBSERVATION=',
                [StringComparison]::Ordinal)
        })
        if ($unexpectedOperationEvidence.Count -ne 0) {
            throw "Suite '$($selectedSuite.Owner)' emitted operation evidence on reviewed non-observing route '$($operationExpectation.Route)'."
        }
    }
    if ($ExecutionProfile -ceq 'Full') {
        $record = Read-MeAndAIScenarioResultRecord -Output @($result.Output) `
            -ExpectedOwner $selectedSuite.Owner `
            -ExpectedTestIds @($authorityByOwner[$selectedSuite.Owner])
        if (-not $record.Valid) {
            throw "Suite '$($selectedSuite.Owner)' has invalid scenario evidence: $($record.Message)."
        }
    }
    else {
        $record = Read-MeAndAICompatibilityShardResultRecord `
            -Output @($result.Output) -ExpectedSuite $selectedSuite.Owner `
            -ExpectedShard $ExecutionProfile
        if (-not $record.Valid) {
            throw "Suite '$($selectedSuite.Owner)' has invalid compatibility evidence: $($record.Message)."
        }
    }
    [void]$completedOwners.Add($selectedSuite.Owner)
}

if ($ExecutionProfile -ceq 'Full') {
    foreach ($owner in @($authorityByOwner.Keys | Sort-Object)) {
        if (-not $completedOwners.Contains([string]$owner)) {
            throw "Canonical suite has no successful completion evidence: $owner."
        }
    }
    Write-Host 'All discovered protocol test suites passed.' -ForegroundColor Green
}
else {
    Write-Host "$ExecutionProfile compatibility profile passed." -ForegroundColor Green
    $compatibilityResult = [ordered]@{
        schema = 1
        suite = 'tests/protocol.tests.ps1'
        shard = $ExecutionProfile
        passed = $true
    }
    Write-Host ('MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
        ($compatibilityResult | ConvertTo-Json -Compress))
}
