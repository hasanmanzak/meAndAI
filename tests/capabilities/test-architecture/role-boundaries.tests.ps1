[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/role-boundaries.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$contractPath = Join-Path $root 'tests/test-role-boundaries.psd1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures/role-boundaries'

Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestAssertions.psm1') -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestRole.psm1') -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force

function Get-OrdinalUniqueString {
    param([AllowEmptyCollection()][string[]]$Value)

    $set = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($entry in @($Value)) {
        if (-not [string]::IsNullOrWhiteSpace($entry)) {
            [void]$set.Add([string]$entry)
        }
    }
    [string[]]$ordered = @($set)
    [Array]::Sort($ordered, [StringComparer]::Ordinal)
    return $ordered
}

function ConvertTo-RepositoryRelativePath {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $resolved = (Resolve-Path -LiteralPath $LiteralPath).Path
    $prefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Test-role source escapes the repository: '$resolved'."
    }
    return $resolved.Substring($prefix.Length).Replace('\', '/')
}

function Get-ViolationCode {
    param([AllowEmptyCollection()][string[]]$Violation)

    return @(Get-OrdinalUniqueString -Value @($Violation | ForEach-Object {
        ([string]$_).Split(':')[0]
    }))
}

function Assert-RoleObservation {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)]
        [ValidateSet('Runner', 'Harness', 'Case', 'Support', 'Fixture', 'Mock')]
        [string]$Role,
        [AllowEmptyCollection()][string[]]$ExpectedViolationCodes = @(),
        [string[]]$AllowedAssertionCommand = @()
    )

    $result = Test-MeAndAITestRoleSource -LiteralPath $LiteralPath -Role $Role `
        -AllowedAssertionCommand $AllowedAssertionCommand
    [string[]]$expected = @(Get-OrdinalUniqueString `
        -Value $ExpectedViolationCodes)
    [string[]]$actual = @(Get-ViolationCode -Violation $result.Violations)
    Assert-MeAndAITestSequenceEqual -Actual $actual -Expected $expected `
        -Message ("Role violations differ for '{0}' as {1}." -f `
            (ConvertTo-RepositoryRelativePath -LiteralPath $LiteralPath), $Role)
    Assert-MeAndAITestEqual -Actual ([bool]$result.Valid) `
        -Expected ($expected.Count -eq 0) `
        -Message ("Role validity differs for '{0}' as {1}." -f `
            (ConvertTo-RepositoryRelativePath -LiteralPath $LiteralPath), $Role)
}

$contract = Import-PowerShellDataFile -LiteralPath $contractPath
Assert-MeAndAITestEqual -Actual ([long]$contract.SchemaVersion) -Expected 1L `
    -Message 'Test-role contract schema changed.'
Assert-MeAndAITestEqual -Actual ([string]$contract.RootRunner) `
    -Expected 'tests/protocol.tests.ps1' `
    -Message 'The exact root runner changed.'

$scenarioContext = New-MeAndAIScenarioEvidenceContext -Owner $owner `
    -AuthorityPath $authorityPath

$rootRunnerPath = Join-Path $root ([string]$contract.RootRunner)
[string[]]$runnerAggregationCommands = @(Get-OrdinalUniqueString `
    -Value @($contract.RunnerAggregationCommands | ForEach-Object {
        [string]$_
    }))
Assert-MeAndAITestSequenceEqual -Actual $runnerAggregationCommands `
    -Expected @('Assert-MeAndAITestSuiteOperationEvidence') `
    -Message 'The root runner aggregation-command allowance changed.'
Assert-RoleObservation -LiteralPath $rootRunnerPath -Role Runner `
    -AllowedAssertionCommand $runnerAggregationCommands

[string[]]$actualHarnesses = @(Get-OrdinalUniqueString -Value @(
    Get-ChildItem -LiteralPath `
    (Join-Path $root 'tests/infrastructure') -File -Filter '*.psm1' |
    ForEach-Object { ConvertTo-RepositoryRelativePath -LiteralPath $_.FullName }
))
[string[]]$expectedHarnesses = @(Get-OrdinalUniqueString `
    -Value @($contract.Harnesses | ForEach-Object { [string]$_ }))
Assert-MeAndAITestSequenceEqual -Actual $actualHarnesses `
    -Expected $expectedHarnesses `
    -Message 'The exact harness-module inventory changed.'
foreach ($path in $expectedHarnesses) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Harness
}

foreach ($path in @($contract.Supports | ForEach-Object { [string]$_ })) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Support
}
foreach ($path in @($contract.Mocks | ForEach-Object { [string]$_ })) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Mock
}
[string[]]$expectedCases = @(Get-OrdinalUniqueString `
    -Value @($contract.Cases | ForEach-Object { [string]$_ }))
[string[]]$actualCases = @(Get-OrdinalUniqueString -Value @(
    Get-ChildItem -LiteralPath (Join-Path $root 'tests/capabilities') `
        -Recurse -File -Filter '*.case.ps1' | ForEach-Object {
            ConvertTo-RepositoryRelativePath -LiteralPath $_.FullName
        }
))
Assert-MeAndAITestSequenceEqual -Actual $actualCases -Expected $expectedCases `
    -Message 'The exact executable Case inventory changed.'
foreach ($path in $expectedCases) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Case
}
foreach ($path in @($contract.InertFixtures | ForEach-Object { [string]$_ })) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Fixture
}

$transitionalEntries = @($contract.TransitionalExecutableFixtures)
Assert-MeAndAITestEqual -Actual $transitionalEntries.Count -Expected 4 `
    -Message 'The SUBF-0098 transitional fixture debt must contain exactly four paths.'
foreach ($entry in $transitionalEntries) {
    Assert-MeAndAITestEqual -Actual ([string]$entry.Role) -Expected 'Case' `
        -Message "Transitional source '$($entry.Path)' has the wrong semantic role."
    Assert-MeAndAITestEqual -Actual ([string]$entry.RemovalSlice) `
        -Expected 'SUBF-0098' `
        -Message "Transitional source '$($entry.Path)' has the wrong removal slice."
    Assert-RoleObservation -LiteralPath (Join-Path $root ([string]$entry.Path)) `
        -Role Case
}

foreach ($entry in @($contract.ReviewedInertExceptions)) {
    Assert-MeAndAITestTrue -Condition (
        -not [string]::IsNullOrWhiteSpace([string]$entry.Reason) -and
        -not [string]::IsNullOrWhiteSpace([string]$entry.ReviewAuthority)
    ) -Message "Reviewed inert exception '$($entry.Path)' lacks authority."
    Assert-RoleObservation -LiteralPath (Join-Path $root ([string]$entry.Path)) `
        -Role ([string]$entry.Role) `
        -ExpectedViolationCodes @($entry.ExpectedViolationCodes)
}

foreach ($example in @($contract.Examples)) {
    Assert-RoleObservation -LiteralPath (Join-Path $fixtureRoot `
        ([string]$example.Path)) -Role ([string]$example.Role) `
        -ExpectedViolationCodes @($example.ExpectedViolationCodes)
}

$declaredFixtureSources = @(
    @($contract.Supports | ForEach-Object { [string]$_ })
    @($contract.Mocks | ForEach-Object { [string]$_ })
    @($contract.Cases | ForEach-Object { [string]$_ })
    @($contract.InertFixtures | ForEach-Object { [string]$_ })
    @($contract.TransitionalExecutableFixtures | ForEach-Object {
        [string]$_.Path
    })
    @($contract.ReviewedInertExceptions | ForEach-Object { [string]$_.Path })
    @($contract.Examples | ForEach-Object {
        'tests/capabilities/test-architecture/fixtures/role-boundaries/' +
            [string]$_.Path
    })
)
[string[]]$expectedFixtureSources = @(Get-OrdinalUniqueString `
    -Value $declaredFixtureSources)
[string[]]$actualFixtureSources = @(Get-OrdinalUniqueString -Value @(
    Get-ChildItem -LiteralPath `
    (Join-Path $root 'tests/capabilities') -Recurse -File | Where-Object {
        $relative = ConvertTo-RepositoryRelativePath -LiteralPath $_.FullName
        $isPowerShellSource = $_.Name -match
            '(?i)\.(?:ps1|psm1|psd1)(?:\.fixture)?$'
        $isPowerShellSource -and (
            $relative.Contains('/fixtures/') -or
            $_.Name.EndsWith('.case.ps1',
                [StringComparison]::OrdinalIgnoreCase) -or
            $_.Name.EndsWith('.fixture.ps1',
                [StringComparison]::OrdinalIgnoreCase)
        )
    } | ForEach-Object {
        ConvertTo-RepositoryRelativePath -LiteralPath $_.FullName
    }
))
Assert-MeAndAITestSequenceEqual -Actual $actualFixtureSources `
    -Expected $expectedFixtureSources `
    -Message 'The exact PowerShell fixture/mock/support inventory changed.'

[string[]]$expectedLegacyOwners = @(Get-OrdinalUniqueString `
    -Value @($contract.LegacyScenarioEvidenceOwners | ForEach-Object {
        [string]$_
    }))
Assert-MeAndAITestEqual -Actual $expectedLegacyOwners.Count -Expected 2 `
    -Message 'Legacy scenario evidence must have exactly two hotspot owners.'

$legacyOwners = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
$testSources = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') `
    -Recurse -File | Where-Object { $_.Extension -cin @('.ps1', '.psm1') })
foreach ($source in $testSources) {
    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        $source.FullName, [ref]$tokens, [ref]$parseErrors
    )
    Assert-MeAndAITestEqual -Actual @($parseErrors).Count -Expected 0 `
        -Message "Legacy-evidence source does not parse: $($source.FullName)."
    $usesLegacyModule = @($ast.FindAll({
        param($node)
        ($node -is [Management.Automation.Language.StringConstantExpressionAst] -or
            $node -is [Management.Automation.Language.ExpandableStringExpressionAst]) -and
            [string]$node.Value -match
                '(?i)(?:^|[\\/])MeAndAI\.LegacyScenarioEvidence\.psm1$'
    }, $true)).Count -gt 0
    $usesLegacyCommand = @($ast.FindAll({
        param($node)
        if ($node -isnot [Management.Automation.Language.CommandAst]) {
            return $false
        }
        $name = [string]$node.GetCommandName()
        return $name -match
            '(?i)(?:Legacy.*ScenarioEvidence|ScenarioEvidence.*Legacy)'
    }, $true)).Count -gt 0
    if ($usesLegacyModule -or $usesLegacyCommand) {
        [void]$legacyOwners.Add((ConvertTo-RepositoryRelativePath `
            -LiteralPath $source.FullName))
    }
}
[string[]]$actualLegacyOwners = @($legacyOwners)
[Array]::Sort($actualLegacyOwners, [StringComparer]::Ordinal)
Assert-MeAndAITestSequenceEqual -Actual $actualLegacyOwners `
    -Expected $expectedLegacyOwners `
    -Message 'Legacy scenario-evidence owners differ from the exact hotspot allowlist.'

Confirm-MeAndAIScenarioEvidence -Context $scenarioContext -TestId 'TEST-0186'
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioContext
Write-Host 'Test role-boundary contracts passed.' -ForegroundColor Green
Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
    ($scenarioResult | ConvertTo-Json -Compress))
