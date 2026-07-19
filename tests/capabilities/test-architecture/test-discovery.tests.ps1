$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/test-discovery.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestDiscovery.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) {
        throw "$Message Expected '$Expected', observed '$Actual'."
    }
}

function Assert-SequenceEqual {
    param([object[]]$Actual, [object[]]$Expected, [string]$Message)
    if ($Actual.Count -ne $Expected.Count) {
        throw "$Message Count differs: $($Actual.Count) != $($Expected.Count)."
    }
    for ($index = 0; $index -lt $Actual.Count; $index++) {
        if ([string]$Actual[$index] -cne [string]$Expected[$index]) {
            throw "$Message Element $index differs: '$($Actual[$index])' != '$($Expected[$index])'."
        }
    }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)
    try {
        & $Action
    }
    catch {
        if ($_.Exception.Message -like $Pattern) { return }
        throw "$Message Unexpected error: $($_.Exception.Message)"
    }
    throw "$Message No error was thrown."
}

function Write-TestFile {
    param([string]$Path, [string]$Content = "Set-StrictMode -Version Latest`n")

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
}

function New-TestRepository {
    param([string]$Path)

    [void](New-Item -ItemType Directory -Path `
        (Join-Path $Path 'tests/capabilities') -Force)
    return $Path
}

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-test-discovery-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixtureRoot)

try {
    $validRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'valid')
    Write-TestFile -Path (Join-Path $validRoot `
        'tests/capabilities/zeta/same.tests.ps1')
    Write-TestFile -Path (Join-Path $validRoot `
        'tests/capabilities/alpha/same.tests.ps1')
    Write-TestFile -Path (Join-Path $validRoot `
        'tests/capabilities/alpha/deep/a.tests.ps1')
    Write-TestFile -Path (Join-Path $validRoot `
        'tests/capabilities/alpha/helper.fixture.ps1')
    Write-TestFile -Path (Join-Path $validRoot `
        'tests/capabilities/alpha/helper.support.ps1')

    $suites = @(Get-MeAndAITestSuite -RepositoryRoot $validRoot)
    Assert-SequenceEqual -Actual @($suites.Owner) -Expected @(
        'tests/capabilities/alpha/deep/a.tests.ps1',
        'tests/capabilities/alpha/same.tests.ps1',
        'tests/capabilities/zeta/same.tests.ps1'
    ) -Message 'TEST-0136 recursive discovery is not normalized and ordinal.'
    Assert-True -Condition ($suites.FullName -notcontains (
        Join-Path $validRoot 'tests/capabilities/alpha/helper.fixture.ps1'
    )) -Message 'TEST-0136 a fixture support file was treated as canonical.'

    $profilePath = Join-Path $validRoot 'tests/execution-profiles.psd1'
    Write-TestFile -Path $profilePath -Content @'
@{
    SchemaVersion = 1
    Profiles = @(
        @{
            Name = 'Full'
            Selection = 'All'
            Suites = @()
        }
        @{
            Name = 'Native'
            Selection = 'Explicit'
            Suites = @(
                @{
                    Owner = 'tests/capabilities/alpha/deep/a.tests.ps1'
                    Arguments = @('-Shard', 'Native')
                }
            )
        }
    )
}
'@
    $profiles = @(Import-MeAndAITestExecutionProfile -LiteralPath $profilePath `
        -DiscoveredSuite $suites)
    $full = @($profiles | Where-Object { $_.Name -ceq 'Full' })
    $native = @($profiles | Where-Object { $_.Name -ceq 'Native' })
    Assert-Equal -Actual $full.Count -Expected 1 `
        -Message 'TEST-0136 the all-suite profile is missing or ambiguous.'
    Assert-SequenceEqual -Actual @($full[0].Suites.Owner) `
        -Expected @($suites.Owner) `
        -Message 'TEST-0136 the all-suite profile changed discovery order.'
    Assert-Equal -Actual $native.Count -Expected 1 `
        -Message 'TEST-0136 the explicit profile is missing or ambiguous.'
    Assert-SequenceEqual -Actual @($native[0].Suites.Arguments) `
        -Expected @('-Shard', 'Native') `
        -Message 'TEST-0136 explicit profile arguments were not preserved.'

    Write-TestFile -Path $profilePath -Content @'
@{
    SchemaVersion = 1
    Profiles = @(
        @{
            Name = 'Missing'
            Selection = 'Explicit'
            Suites = @(
                @{
                    Owner = 'tests/capabilities/missing/missing.tests.ps1'
                    Arguments = @()
                }
            )
        }
    )
}
'@
    Assert-ThrowsLike -Action {
        Import-MeAndAITestExecutionProfile -LiteralPath $profilePath `
            -DiscoveredSuite $suites
    } -Pattern '*not a discovered canonical suite*' `
        -Message 'TEST-0136 an explicit profile accepted an unknown owner.'

    Write-TestFile -Path $profilePath -Content @'
@{
    SchemaVersion = 1
    Profiles = @(
        @{
            Name = 'WrongCase'
            Selection = 'Explicit'
            Suites = @(
                @{
                    Owner = 'tests/capabilities/Alpha/deep/a.tests.ps1'
                    Arguments = @()
                }
            )
        }
    )
}
'@
    Assert-ThrowsLike -Action {
        Import-MeAndAITestExecutionProfile -LiteralPath $profilePath `
            -DiscoveredSuite $suites
    } -Pattern '*unsafe or noncanonical*' `
        -Message 'TEST-0136 an explicit profile accepted a case alias.'

    Assert-ThrowsLike -Action {
        Resolve-MeAndAITestOwnerSet -Owner @(
            'tests/capabilities/Case/a.tests.ps1',
            'tests/capabilities/case/a.tests.ps1'
        )
    } -Pattern '*noncanonical*' `
        -Message 'TEST-0136 a non-lowercase capability owner was accepted.'
    Assert-ThrowsLike -Action {
        Resolve-MeAndAITestOwnerSet -Owner @(
            'tests/capabilities/alpha/a.tests.ps1',
            'tests/capabilities/alpha/a.tests.ps1'
        )
    } -Pattern '*duplicate owner*' `
        -Message 'TEST-0136 duplicate normalized owners were accepted.'
    Assert-ThrowsLike -Action {
        Resolve-MeAndAITestOwnerSet -Owner `
            @('tests/capabilities/../outside.tests.ps1')
    } -Pattern '*unsafe*' `
        -Message 'TEST-0136 an unsafe owner path was accepted.'
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $validRoot `
            -CapabilityRootRelativePath '../outside'
    } -Pattern '*unsafe*' `
        -Message 'TEST-0136 an unsafe capability root was accepted.'

    $emptyRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'empty')
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $emptyRoot
    } -Pattern '*no canonical test suites*' `
        -Message 'TEST-0136 an empty capability root was accepted.'

    $parseRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'parse')
    Write-TestFile -Path (Join-Path $parseRoot `
        'tests/capabilities/broken/broken.tests.ps1') -Content 'function {'
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $parseRoot
    } -Pattern '*does not parse*' `
        -Message 'TEST-0136 a malformed canonical suite was accepted.'

    $masqueradeRoot = New-TestRepository -Path `
        (Join-Path $fixtureRoot 'masquerade')
    Write-TestFile -Path (Join-Path $masqueradeRoot `
        'tests/capabilities/alpha/alpha.tests.ps1')
    Write-TestFile -Path (Join-Path $masqueradeRoot `
        'tests/capabilities/alpha/fixtures/helper.tests.ps1')
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $masqueradeRoot
    } -Pattern '*support path masquerades as a canonical suite*' `
        -Message 'TEST-0136 a support-path suite masquerade was accepted.'

    $rootSuiteRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'root-suite')
    Write-TestFile -Path (Join-Path $rootSuiteRoot `
        'tests/capabilities/alpha/alpha.tests.ps1')
    Write-TestFile -Path (Join-Path $rootSuiteRoot `
        'tests/capabilities/rogue.tests.ps1')
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $rootSuiteRoot
    } -Pattern '*unsafe or noncanonical*' `
        -Message 'TEST-0136 a direct capability-root suite was accepted.'

    $adapterRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'adapter')
    Write-TestFile -Path (Join-Path $adapterRoot `
        'tests/capabilities/alpha/alpha.tests.ps1')
    Write-TestFile -Path (Join-Path $adapterRoot `
        'tests/capabilities/alpha/helper-adapter.tests.ps1')
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $adapterRoot
    } -Pattern '*support filename masquerades as a canonical suite*' `
        -Message 'TEST-0136 an adapter filename masquerade was accepted.'

    $pluralRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'plural')
    Write-TestFile -Path (Join-Path $pluralRoot `
        'tests/capabilities/alpha/alpha.tests.ps1')
    Write-TestFile -Path (Join-Path $pluralRoot `
        'tests/capabilities/alpha/fixtures.tests.ps1')
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $pluralRoot
    } -Pattern '*support filename masquerades as a canonical suite*' `
        -Message 'TEST-0136 a plural fixture filename masquerade was accepted.'

    $suffixCaseRoot = New-TestRepository -Path `
        (Join-Path $fixtureRoot 'suffix-case')
    Write-TestFile -Path (Join-Path $suffixCaseRoot `
        'tests/capabilities/alpha/alpha.tests.ps1')
    Write-TestFile -Path (Join-Path $suffixCaseRoot `
        'tests/capabilities/alpha/wrong.Tests.ps1')
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $suffixCaseRoot
    } -Pattern '*suffix case does not match*' `
        -Message 'TEST-0136 a case-aliased suite suffix was ignored.'

    $linkRoot = New-TestRepository -Path (Join-Path $fixtureRoot 'link')
    Write-TestFile -Path (Join-Path $linkRoot `
        'tests/capabilities/alpha/alpha.tests.ps1')
    $linkTarget = Join-Path $linkRoot 'linked-target'
    [void](New-Item -ItemType Directory -Path $linkTarget)
    Write-TestFile -Path (Join-Path $linkTarget 'linked.tests.ps1')
    $linkPath = Join-Path $linkRoot 'tests/capabilities/linked'
    $linkCreated = $false
    foreach ($itemType in @('Junction', 'SymbolicLink')) {
        try {
            [void](New-Item -ItemType $itemType -Path $linkPath `
                -Target $linkTarget -ErrorAction Stop)
            if (Test-Path -LiteralPath $linkPath) {
                $linkCreated = $true
                break
            }
        }
        catch { }
    }
    Assert-True -Condition $linkCreated `
        -Message 'TEST-0136 could not create the link-safety fixture.'
    Assert-ThrowsLike -Action {
        Get-MeAndAITestSuite -RepositoryRoot $linkRoot
    } -Pattern '*reparse point*' `
        -Message 'TEST-0136 a linked capability path was accepted.'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0136'
$scenarioResult = New-MeAndAIScenarioResult -Owner $owner `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Output ('MEANDAI_SCENARIO_RESULTS=' + `
    ($scenarioResult | ConvertTo-Json -Compress))
