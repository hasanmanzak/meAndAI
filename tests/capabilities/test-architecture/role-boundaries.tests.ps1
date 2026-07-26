[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/role-boundaries.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$contractPath = Join-Path $root 'tests/test-role-boundaries.psd1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures/role-boundaries'
$scenarioIntentFixturePath = Join-Path $fixtureRoot `
    'scenario-intent.psd1.fixture'
$protocolPath = Join-Path $root 'PROTOCOL.md'
$featureTemplatePath = Join-Path $root 'templates/feature/README.md'
$testTemplatePath = Join-Path $root 'templates/feature/test-cases.md'
$featureIssueTemplatePath = Join-Path $root '.github/ISSUE_TEMPLATE/feature.yml'
$intentDecisionPath = Join-Path $root `
    'docs/decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md'

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

function Get-ScenarioIntentViolationCode {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Case,
        [Parameter(Mandatory)][string[]]$Relationship
    )

    $violations = [System.Collections.Generic.List[string]]::new()
    foreach ($required in @(
        'Name', 'Relationship', 'NearestSibling', 'Intent', 'SiblingIntent',
        'Oracle', 'InputKind', 'CanonicalOwner', 'SupersededOwner',
        'ActiveIdentityCount', 'ExpectedViolationCodes'
    )) {
        if (-not $Case.Contains($required)) {
            $violations.Add('MissingField')
        }
    }
    if ($violations.Count -gt 0) {
        return @(Get-OrdinalUniqueString -Value $violations)
    }

    [string]$relationshipName = [string]$Case.Relationship
    if ([string]::IsNullOrWhiteSpace($relationshipName)) {
        $violations.Add('MissingRelationship')
    }
    elseif ($Relationship -cnotcontains $relationshipName) {
        $violations.Add('UnknownRelationship')
    }
    if ([string]::IsNullOrWhiteSpace([string]$Case.NearestSibling)) {
        $violations.Add('MissingNearestSibling')
    }

    $tupleFields = @('Contract', 'Risk', 'EvidenceLevel', 'ExercisedBoundary')
    foreach ($tuple in @($Case.Intent, $Case.SiblingIntent)) {
        if ($tuple -isnot [System.Collections.IDictionary]) {
            $violations.Add('MalformedIntentTuple')
            continue
        }
        foreach ($field in $tupleFields) {
            if (-not $tuple.Contains($field) -or
                [string]::IsNullOrWhiteSpace([string]$tuple[$field])) {
                $violations.Add('MalformedIntentTuple')
            }
        }
    }
    if ($violations -ccontains 'MalformedIntentTuple') {
        return @(Get-OrdinalUniqueString -Value $violations)
    }

    [string]$oracle = [string]$Case.Oracle
    if ([string]::IsNullOrWhiteSpace($oracle)) {
        $violations.Add('MissingOracle')
        return @(Get-OrdinalUniqueString -Value $violations)
    }
    if ($oracle -cin @(
        'AnotherTestSource', 'AnotherTestAssertion', 'AnotherTestPassMarker',
        'AnotherTestResult'
    )) {
        $violations.Add('AnotherTestOracle')
        return @(Get-OrdinalUniqueString -Value $violations)
    }

    $tupleEqual = @($tupleFields | Where-Object {
        [string]$Case.Intent[$_] -cne [string]$Case.SiblingIntent[$_]
    }).Count -eq 0
    [long]$activeIdentityCount = [long]$Case.ActiveIdentityCount
    switch ($relationshipName) {
        'Distinct' {
            if ($tupleEqual) { $violations.Add('IndistinctActiveIntent') }
        }
        'ParameterizedVariant' {
            if (-not $tupleEqual -or $activeIdentityCount -ne 1 -or
                [string]::IsNullOrWhiteSpace([string]$Case.CanonicalOwner)) {
                $violations.Add('NonCanonicalVariant')
            }
        }
        'InfrastructureContract' {
            if ($oracle -cne 'OwnedInfrastructureContract' -or
                [string]$Case.InputKind -cne 'Inert' -or
                $activeIdentityCount -ne 1 -or
                [string]::IsNullOrWhiteSpace([string]$Case.CanonicalOwner)) {
                $violations.Add('InvalidInfrastructureContract')
            }
        }
        'SupersededDuplicate' {
            if (-not $tupleEqual -or $activeIdentityCount -ne 1 -or
                [string]::IsNullOrWhiteSpace([string]$Case.CanonicalOwner) -or
                [string]::IsNullOrWhiteSpace([string]$Case.SupersededOwner)) {
                $violations.Add('InvalidSupersession')
            }
        }
    }

    return @(Get-OrdinalUniqueString -Value $violations)
}

function Get-NearestScriptBlockAst {
    param(
        [Parameter(Mandatory)]
        [Management.Automation.Language.Ast]$Ast
    )

    $current = $Ast
    while ($null -ne $current -and
        $current -isnot [Management.Automation.Language.ScriptBlockAst]) {
        $current = $current.Parent
    }
    return $current
}

function Get-CrossCanonicalSuiteDispatch {
    [CmdletBinding(DefaultParameterSetName = 'File')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$LiteralPath,
        [Parameter(Mandatory, ParameterSetName = 'Source')]
        [string]$SourceText,
        [Parameter(Mandatory)][string[]]$CanonicalOwner,
        [Parameter(ParameterSetName = 'Source')]
        [string]$CurrentOwner = '<synthetic-dispatch-fixture>'
    )

    $tokens = $null
    $parseErrors = $null
    if ($PSCmdlet.ParameterSetName -ceq 'File') {
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            (Resolve-Path -LiteralPath $LiteralPath).Path,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $CurrentOwner = ConvertTo-RepositoryRelativePath `
            -LiteralPath $LiteralPath
    }
    else {
        $ast = [Management.Automation.Language.Parser]::ParseInput(
            $SourceText,
            [ref]$tokens,
            [ref]$parseErrors
        )
    }
    Assert-MeAndAITestEqual -Actual @($parseErrors).Count -Expected 0 `
        -Message "Canonical suite does not parse: '$CurrentOwner'."

    $violations = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $assignmentIndex = @{}
    foreach ($assignmentAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.AssignmentStatementAst] -and
            $node.Left -is [Management.Automation.Language.VariableExpressionAst]
    }, $true))) {
        $scopeAst = Get-NearestScriptBlockAst -Ast $assignmentAst
        if ($null -eq $scopeAst) { continue }
        [string]$variableName =
            ([string]$assignmentAst.Left.VariablePath.UserPath).ToLowerInvariant()
        [string]$indexKey = '{0}:{1}|{2}' -f `
            $scopeAst.Extent.StartOffset,
            $scopeAst.Extent.EndOffset,
            $variableName
        [string[]]$assignedValues = @(
            Get-MeAndAIStaticStringValue -Ast $assignmentAst.Right |
                ForEach-Object { ([string]$_).Replace('\', '/') }
        )
        if ($assignedValues.Count -eq 0) { continue }
        if (-not $assignmentIndex.ContainsKey($indexKey)) {
            $assignmentIndex[$indexKey] =
                [System.Collections.Generic.List[object]]::new()
        }
        $assignmentIndex[$indexKey].Add([pscustomobject]@{
            Offset = [int]$assignmentAst.Extent.StartOffset
            Values = $assignedValues
        })
    }

    foreach ($commandAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.CommandAst]
    }, $true))) {
        [string]$commandName = [string]$commandAst.GetCommandName()
        $dynamicInvocation = [string]$commandAst.InvocationOperator -cin @(
            'Ampersand', 'Dot'
        )
        $dispatchCommand = $commandName -ieq
            'Invoke-MeAndAITestSuiteProcess' -or
            $commandName -match
                '^(?i:powershell|powershell\.exe|pwsh|pwsh\.exe)$' -or
            $commandName -match '(?i)(?:^|[\\/])[^\\/]+\.tests\.ps1$' -or
            $dynamicInvocation
        if (-not $dispatchCommand) { continue }

        $candidateSet = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($candidate in @(
            @($commandName)
            @(Get-MeAndAIStaticStringValue -Ast $commandAst)
        )) {
            [void]$candidateSet.Add(([string]$candidate).Replace('\', '/'))
        }
        foreach ($variableAst in @($commandAst.FindAll({
            param($node)
            $node -is [Management.Automation.Language.VariableExpressionAst]
        }, $true))) {
            [string]$variableName =
                ([string]$variableAst.VariablePath.UserPath).ToLowerInvariant()
            $scopeAst = Get-NearestScriptBlockAst -Ast $commandAst
            if ($null -eq $scopeAst) { continue }
            [string]$indexKey = '{0}:{1}|{2}' -f `
                $scopeAst.Extent.StartOffset,
                $scopeAst.Extent.EndOffset,
                $variableName
            if (-not $assignmentIndex.ContainsKey($indexKey)) { continue }
            $nearestAssignment = $null
            foreach ($entry in $assignmentIndex[$indexKey]) {
                if ($entry.Offset -lt $commandAst.Extent.StartOffset -and
                    ($null -eq $nearestAssignment -or
                        $entry.Offset -gt $nearestAssignment.Offset)) {
                    $nearestAssignment = $entry
                }
            }
            if ($null -eq $nearestAssignment) { continue }
            foreach ($value in @($nearestAssignment.Values)) {
                [void]$candidateSet.Add([string]$value)
            }
        }
        [string[]]$candidates = @($candidateSet)
        foreach ($targetOwner in @($CanonicalOwner | Where-Object {
            [string]$_ -ine $CurrentOwner
        })) {
            [string]$normalizedTarget = ([string]$targetOwner).Replace('\', '/')
            [string]$targetLeaf = $normalizedTarget.Substring(
                $normalizedTarget.LastIndexOf('/') + 1
            )
            if (@($candidates | Where-Object {
                [string]$candidate = [string]$_
                $candidate -ieq $normalizedTarget -or
                $candidate.EndsWith('/' + $normalizedTarget,
                    [StringComparison]::OrdinalIgnoreCase) -or
                $candidate -ieq $targetLeaf
            }).Count -gt 0) {
                [void]$violations.Add($normalizedTarget)
            }
        }
    }

    [string[]]$ordered = @($violations)
    [Array]::Sort($ordered, [StringComparer]::Ordinal)
    return $ordered
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

$authority = Import-PowerShellDataFile -LiteralPath $authorityPath
$executableSuiteOwners = @($authority.Authorities | Where-Object {
    [string]$_.Evidence -ceq 'ExecutableSuite'
} | ForEach-Object { [string]$_.Owner })
foreach ($path in $executableSuiteOwners) {
    [string[]]$crossDispatch = @(Get-CrossCanonicalSuiteDispatch `
        -LiteralPath (Join-Path $root $path) `
        -CanonicalOwner $executableSuiteOwners)
    Assert-MeAndAITestSequenceEqual -Actual $crossDispatch -Expected @() `
        -Message "Canonical suite '$path' directly dispatches another canonical suite."
}

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
Assert-MeAndAITestEqual -Actual $expectedCases.Count -Expected 5 `
    -Message 'The canonical executable Case inventory must contain exactly five owners.'
foreach ($path in $expectedCases) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Case
}
foreach ($path in @($contract.InertFixtures | ForEach-Object { [string]$_ })) {
    Assert-RoleObservation -LiteralPath (Join-Path $root $path) -Role Fixture
}

Assert-MeAndAITestTrue -Condition (
    -not $contract.Contains('TransitionalExecutableFixtures')
) -Message 'The completed executable-fixture transition key must not remain active.'
Assert-MeAndAITestTrue -Condition (
    -not $contract.Contains('LegacyScenarioEvidenceOwners')
) -Message 'The completed legacy scenario-evidence owner key must not remain active.'

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

$intentFixture = Import-PowerShellDataFile `
    -LiteralPath $scenarioIntentFixturePath
Assert-MeAndAITestEqual -Actual ([long]$intentFixture.SchemaVersion) `
    -Expected 1L -Message 'Scenario-intent fixture schema changed.'
[string[]]$relationships = @(Get-OrdinalUniqueString `
    -Value @($intentFixture.Relationships | ForEach-Object { [string]$_ }))
Assert-MeAndAITestSequenceEqual -Actual $relationships -Expected @(
    'Distinct', 'InfrastructureContract', 'ParameterizedVariant',
    'SupersededDuplicate'
) -Message 'Scenario-intent relationship vocabulary changed.'
foreach ($case in @($intentFixture.Cases)) {
    [string[]]$actualViolations = @(Get-ScenarioIntentViolationCode `
        -Case $case -Relationship $relationships)
    [string[]]$expectedViolations = @(Get-OrdinalUniqueString `
        -Value @($case.ExpectedViolationCodes | ForEach-Object { [string]$_ }))
    Assert-MeAndAITestSequenceEqual -Actual $actualViolations `
        -Expected $expectedViolations `
        -Message "Scenario-intent case '$($case.Name)' differs."
}
foreach ($dispatchCase in @($intentFixture.DispatchCases)) {
    [string[]]$actualTargets = @(Get-CrossCanonicalSuiteDispatch `
        -SourceText ([string]$dispatchCase.Source) `
        -CurrentOwner ('fixture:' + [string]$dispatchCase.Name) `
        -CanonicalOwner $executableSuiteOwners)
    [string[]]$expectedTargets = @(Get-OrdinalUniqueString `
        -Value @($dispatchCase.ExpectedTargets | ForEach-Object { [string]$_ }))
    Assert-MeAndAITestSequenceEqual -Actual $actualTargets `
        -Expected $expectedTargets `
        -Message "Canonical-suite dispatch case '$($dispatchCase.Name)' differs."
}

$normalizedProtocol = [regex]::Replace(
    (Get-Content -LiteralPath $protocolPath -Raw), '\s+', ' '
)
foreach ($required in @(
    'Before adding or changing a numbered scenario, identify its nearest same-contract sibling and review its contract, risk, evidence level, and exercised boundary.',
    'The reviewed relationship MUST be exactly one of `Distinct`, `ParameterizedVariant`, `InfrastructureContract`, or `SupersededDuplicate`.',
    'A canonical suite MUST NOT invoke another canonical suite or use another test''s source text, assertion wording, pass marker, or successful result as product-behavior evidence.',
    'A direct infrastructure-contract test MAY validate discovery, ownership, role, evidence, or lifecycle behavior when that infrastructure invariant is itself the contract under test.'
)) {
    Assert-MeAndAITestTrue -Condition $normalizedProtocol.Contains($required) `
        -Message "The protocol lacks scenario-intent clause '$required'."
}

$normalizedFeatureTemplate = [regex]::Replace(
    (Get-Content -LiteralPath $featureTemplatePath -Raw), '\s+', ' '
)
foreach ($required in @(
    'Numbered scenario intent:',
    'nearest same-contract sibling',
    '`Distinct`, `ParameterizedVariant`, `InfrastructureContract`, or `SupersededDuplicate`',
    'contract, risk, evidence level, and exercised boundary'
)) {
    Assert-MeAndAITestTrue `
        -Condition $normalizedFeatureTemplate.Contains($required) `
        -Message "The feature template lacks scenario-intent field '$required'."
}

$testTemplate = Get-Content -LiteralPath $testTemplatePath -Raw
Assert-MeAndAITestTrue -Condition $testTemplate.Contains('| Intent review |') `
    -Message 'The test-scenario template lacks the intent-review column.'
foreach ($required in @(
    'Nearest same-contract sibling', 'Relationship disposition',
    'Distinct intent tuple'
)) {
    Assert-MeAndAITestTrue -Condition $testTemplate.Contains($required) `
        -Message "The test-scenario template lacks '$required'."
}

$featureIssueTemplate = Get-Content `
    -LiteralPath $featureIssueTemplatePath -Raw
$intentField = [regex]::Match(
    $featureIssueTemplate,
    '(?ms)^  - type: textarea\r?\n    id: scenario_intent\r?\n(?<body>.*?)(?=^  - type: |\z)'
)
Assert-MeAndAITestTrue -Condition $intentField.Success `
    -Message 'The feature issue form lacks one scenario-intent field.'
if ($intentField.Success) {
    foreach ($required in @(
        'label: Numbered scenario intent review',
        'nearest same-contract sibling',
        'contract, risk, evidence level, and exercised boundary',
        'required: true'
    )) {
        Assert-MeAndAITestTrue `
            -Condition $intentField.Value.Contains($required) `
            -Message "The feature issue scenario-intent field lacks '$required'."
    }
}

$normalizedDecision = [regex]::Replace(
    (Get-Content -LiteralPath $intentDecisionPath -Raw), '\s+', ' '
)
foreach ($required in @(
    'One behavioral contract has one canonical scenario family.',
    'No scenario requires a second scenario merely to prove that it exists or ran.',
    'no second permanent scenario registry or semantic clone detector is created.'
)) {
    Assert-MeAndAITestTrue -Condition $normalizedDecision.Contains($required) `
        -Message "The intent decision lacks '$required'."
}

$declaredFixtureSources = @(
    @($contract.Supports | ForEach-Object { [string]$_ })
    @($contract.Mocks | ForEach-Object { [string]$_ })
    @($contract.Cases | ForEach-Object { [string]$_ })
    @($contract.InertFixtures | ForEach-Object { [string]$_ })
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
    -Expected @() `
    -Message 'Legacy scenario-evidence references must remain absent after transition closure.'

[string[]]$legacyExecutableCasePaths = @($expectedCases | ForEach-Object {
    $_.Substring(0, $_.Length - '.case.ps1'.Length) + '.fixture.ps1'
})
$syntheticLegacyPath = $legacyExecutableCasePaths[0]
$syntheticSplit = [Math]::Max(1, $syntheticLegacyPath.Length - 12)
$syntheticSource = ("'{0}' + '{1}'" -f `
    $syntheticLegacyPath.Substring(0, $syntheticSplit),
    $syntheticLegacyPath.Substring($syntheticSplit))
$syntheticTokens = $null
$syntheticErrors = $null
$syntheticAst = [Management.Automation.Language.Parser]::ParseInput(
    $syntheticSource, [ref]$syntheticTokens, [ref]$syntheticErrors
)
Assert-MeAndAITestEqual -Actual @($syntheticErrors).Count -Expected 0 `
    -Message 'The split legacy-path detection vector does not parse.'
Assert-MeAndAITestTrue -Condition (
    @(Get-MeAndAIStaticStringValue -Ast $syntheticAst) -ccontains
        $syntheticLegacyPath
) -Message 'Static string folding no longer detects split legacy paths.'

$legacyCaseReferences = [System.Collections.Generic.List[string]]::new()
$referenceSources = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') `
    -Recurse -File | Where-Object { $_.Extension -cin @('.ps1', '.psm1', '.psd1') })
foreach ($source in $referenceSources) {
    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        $source.FullName, [ref]$tokens, [ref]$parseErrors
    )
    Assert-MeAndAITestEqual -Actual @($parseErrors).Count -Expected 0 `
        -Message "Executable-case reference source does not parse: $($source.FullName)."
    [string[]]$staticValues = @(Get-MeAndAIStaticStringValue -Ast $ast |
        ForEach-Object { ([string]$_).Replace('\', '/') })
    foreach ($legacyPath in $legacyExecutableCasePaths) {
        if (@($staticValues | Where-Object {
            $_.IndexOf($legacyPath,
                [StringComparison]::OrdinalIgnoreCase) -ge 0
        }).Count -gt 0) {
            $legacyCaseReferences.Add(('{0} -> {1}' -f `
                (ConvertTo-RepositoryRelativePath -LiteralPath $source.FullName),
                $legacyPath))
        }
    }
}
Assert-MeAndAITestSequenceEqual -Actual @($legacyCaseReferences) `
    -Expected @() `
    -Message 'Retired executable fixture paths must remain absent from test code and contracts.'

Confirm-MeAndAIScenarioEvidence -Context $scenarioContext -TestId 'TEST-0186'
Confirm-MeAndAIScenarioEvidence -Context $scenarioContext -TestId 'TEST-0187'
Confirm-MeAndAIScenarioEvidence -Context $scenarioContext -TestId 'TEST-0190'
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioContext
Write-Host 'Test role-boundary contracts passed.' -ForegroundColor Green
Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
    ($scenarioResult | ConvertTo-Json -Compress))
