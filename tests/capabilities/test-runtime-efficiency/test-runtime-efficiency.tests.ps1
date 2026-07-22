[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$contractPath = Join-Path $root 'tests/fixture-operation-budgets.psd1'
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestRuntime.psm1') -Force
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) { Add-Failure $Message }
}

function Assert-Equal {
    param(
        [AllowNull()][object]$Actual,
        [AllowNull()][object]$Expected,
        [Parameter(Mandatory)][string]$Message
    )
    if ($Actual -cne $Expected) {
        Add-Failure "$Message Expected='$Expected' Actual='$Actual'."
    }
}

function Assert-ThrowsLike {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Message
    )
    try {
        & $Action
        Add-Failure $Message
    }
    catch {
        if ($_.Exception.Message -cnotlike $Pattern) {
            Add-Failure "$Message Wrong error: $($_.Exception.Message)"
        }
    }
}

function Assert-InvalidObservation {
    param(
        [Parameter(Mandatory)][object[]]$Lines,
        [Parameter(Mandatory)][object]$Expectation,
        [Parameter(Mandatory)][string]$Message
    )
    $result = Read-MeAndAITestOperationObservationRecord -Output $Lines `
        -ExpectedOwner $Expectation.Owner -ExpectedRoute $Expectation.Route `
        -ExpectedRuntime $Expectation.Runtime `
        -ExpectedCounters $Expectation.Counters
    if ($result.Valid) { Add-Failure $Message }
}

function Replace-FirstOrdinal {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OldValue,
        [Parameter(Mandatory)][string]$NewValue
    )
    $index = $Source.IndexOf($OldValue, [StringComparison]::Ordinal)
    if ($index -lt 0) { throw "Synthetic manifest token '$OldValue' is absent." }
    return $Source.Substring(0, $index) + $NewValue +
        $Source.Substring($index + $OldValue.Length)
}

function Remove-ContractTempRoot {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $fullPath = [IO.Path]::GetFullPath($Path)
    $tempPath = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $comparison = [StringComparison]::Ordinal
    if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        $comparison = [StringComparison]::OrdinalIgnoreCase
    }
    if (-not $fullPath.StartsWith($tempPath, $comparison) -or
        [IO.Path]::GetFileName($fullPath) -cnotlike
            'meandai-operation-contract-*') {
        throw "Refusing to remove unexpected test root '$fullPath'."
    }
    Remove-Item -LiteralPath $fullPath -Recurse -Force
}

function Get-ParsedTestAst {
    param([Parameter(Mandatory)][string]$Path)
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path, [ref]$tokens, [ref]$errors
    )
    if ($errors.Count -gt 0) {
        throw "Hotspot source '$Path' does not parse: $($errors[0].Message)"
    }
    return $ast
}

function Get-ParentFunctionName {
    param([Parameter(Mandatory)][object]$Node)
    $parent = $Node.Parent
    while ($null -ne $parent -and
        $parent -isnot
            [System.Management.Automation.Language.FunctionDefinitionAst]) {
        $parent = $parent.Parent
    }
    if ($null -eq $parent) { return '<script>' }
    return [string]$parent.Name
}

function Get-ReviewedOperationInventory {
    param(
        [Parameter(Mandatory)]$Ast,
        [Parameter(Mandatory)][string[]]$CommandNames
    )

    $inventory = [System.Collections.Generic.Dictionary[string, int]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($command in @($Ast.FindAll({
        param($node)
        if ($node -isnot [System.Management.Automation.Language.CommandAst] -or
            $CommandNames -cnotcontains $node.GetCommandName()) {
            return $false
        }
        return @($node.FindAll({
            param($element)
            $element -is
                [System.Management.Automation.Language.StringConstantExpressionAst] -and
            @('init', 'clone', 'bundle', 'push', 'worktree') -ccontains
                $element.Value.ToLowerInvariant()
        }, $true)).Count -gt 0
    }, $true))) {
        $operation = @($command.FindAll({
            param($element)
            $element -is
                [System.Management.Automation.Language.StringConstantExpressionAst] -and
            @('init', 'clone', 'bundle', 'push', 'worktree') -ccontains
                $element.Value.ToLowerInvariant()
        }, $true))[0].Value.ToLowerInvariant()
        $identity = '{0}|{1}|{2}' -f
            $operation,
            (Get-ParentFunctionName -Node $command),
            $command.GetCommandName()
        if (-not $inventory.ContainsKey($identity)) {
            $inventory[$identity] = 0
        }
        $inventory[$identity]++
    }
    return $inventory
}

function Get-ReviewedDynamicInvocationInventory {
    param([Parameter(Mandatory)]$Ast)

    $inventory = [System.Collections.Generic.Dictionary[string, int]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($command in @($Ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.InvocationOperator -eq
            [System.Management.Automation.Language.TokenKind]::Ampersand -and
        $node.CommandElements.Count -gt 0 -and
        $node.CommandElements[0] -is
            [System.Management.Automation.Language.VariableExpressionAst]
    }, $true))) {
        $identity = '{0}|{1}' -f
            $command.CommandElements[0].Extent.Text,
            (Get-ParentFunctionName -Node $command)
        if (-not $inventory.ContainsKey($identity)) {
            $inventory[$identity] = 0
        }
        $inventory[$identity]++
    }
    return $inventory
}

function Get-ReviewedUnclassifiedGitSplatInventory {
    param([Parameter(Mandatory)]$Ast)

    $inventory = [System.Collections.Generic.Dictionary[string, int]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($command in @($Ast.FindAll({
        param($node)
        if ($node -isnot [System.Management.Automation.Language.CommandAst] -or
            @('git', 'Invoke-Git', 'Invoke-TestGit') -cnotcontains
                $node.GetCommandName()) {
            return $false
        }
        $hasSplat = @($node.CommandElements | Where-Object {
            $_ -is
                [System.Management.Automation.Language.VariableExpressionAst] -and
            $_.Splatted
        }).Count -gt 0
        $hasReviewedOperation = @($node.FindAll({
            param($element)
            $element -is
                [System.Management.Automation.Language.StringConstantExpressionAst] -and
            @('init', 'clone', 'bundle', 'push', 'worktree') -ccontains
                $element.Value.ToLowerInvariant()
        }, $true)).Count -gt 0
        return $hasSplat -and -not $hasReviewedOperation
    }, $true))) {
        $splats = @($command.CommandElements | Where-Object {
            $_ -is
                [System.Management.Automation.Language.VariableExpressionAst] -and
            $_.Splatted
        })
        foreach ($splat in $splats) {
            $identity = '{0}|{1}|{2}' -f
                $splat.Extent.Text,
                (Get-ParentFunctionName -Node $command),
                $command.GetCommandName()
            if (-not $inventory.ContainsKey($identity)) {
                $inventory[$identity] = 0
            }
            $inventory[$identity]++
        }
    }
    return $inventory
}

function Get-ReviewedRecursiveCleanupInventory {
    param([Parameter(Mandatory)]$Ast)

    $inventory = [System.Collections.Generic.Dictionary[string, int]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($command in @($Ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -ceq 'Remove-Item' -and
        @($node.CommandElements | Where-Object {
            $_ -is
                [System.Management.Automation.Language.CommandParameterAst] -and
            $_.ParameterName -ceq 'Recurse'
        }).Count -gt 0
    }, $true))) {
        $identity = 'Remove-Item|{0}' -f
            (Get-ParentFunctionName -Node $command)
        if (-not $inventory.ContainsKey($identity)) {
            $inventory[$identity] = 0
        }
        $inventory[$identity]++
    }
    return $inventory
}

function Assert-ReviewedOperationInventory {
    param(
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)][hashtable]$Expected,
        [Parameter(Mandatory)][string]$Label
    )

    Assert-Equal $Actual.Count $Expected.Count `
        "TEST-0159 $Label reviewed operation identity count differs."
    foreach ($entry in $Expected.GetEnumerator()) {
        Assert-True $Actual.ContainsKey([string]$entry.Key) `
            "TEST-0159 $Label operation '$($entry.Key)' is absent."
        if ($Actual.ContainsKey([string]$entry.Key)) {
            Assert-Equal ([int]$Actual[[string]$entry.Key]) `
                ([int]$entry.Value) `
                "TEST-0159 $Label operation '$($entry.Key)' count differs."
        }
    }
    foreach ($identity in @($Actual.Keys)) {
        Assert-True $Expected.Contains([string]$identity) `
            "TEST-0159 $Label operation '$identity' is not reviewed."
    }
}

$contract = Import-MeAndAITestOperationContract -Path $contractPath
Assert-Equal $contract.SchemaVersion ([long]1) `
    'TEST-0159 contract schema differs.'
Assert-Equal $contract.Measurement.BaseCommit `
    '6b01299cfe484c900944b7435d4fef43b11fc38d' `
    'TEST-0159 exact measurement base differs.'
Assert-Equal $contract.Measurement.ObserverDigest `
    'sha256:ed9a8290b24b191274f35c4bef2cd9af14157e2927be94848a2561a54294e04b' `
    'TEST-0159 observer identity differs.'
Assert-Equal @($contract.ObservationOwners).Count 3 `
    'TEST-0159 observation owner count differs.'
Assert-Equal @($contract.ClosureTargets).Count 7 `
    'TEST-0159 closure target count differs.'

$expectedTargets = [ordered]@{
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1|Shard=All|reusable-fixture-family.init' = '47/11'
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.init' = '38/3'
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.clone' = '72/2'
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.bundle' = '2/2'
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.push' = '36/36'
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|process.child' = '6/4'
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|graph.acquisition' = '5/3'
}
foreach ($target in @($contract.ClosureTargets)) {
    $identity = "$($target.Owner)|$($target.Route)|$($target.Counter)"
    Assert-True $expectedTargets.Contains($identity) `
        "TEST-0159 unexpected closure target '$identity'."
    if ($expectedTargets.Contains($identity)) {
        Assert-Equal "$($target.Baseline)/$($target.Maximum)" `
            $expectedTargets[$identity] `
            "TEST-0159 closure target '$identity' differs."
    }
    Assert-True ([bool]$target.Instrumented) `
        "TEST-0159 wired target '$identity' lacks instrumentation authority."
}

$quickOwner = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
$bootstrapOwner =
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
$quickExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $quickOwner -SuiteArguments @()
$quickNativeExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $quickOwner `
    -SuiteArguments @('-Shard', 'WindowsNative')
$bootstrapExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $bootstrapOwner -SuiteArguments @()
$selfExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $owner -SuiteArguments @()
Assert-Equal $quickExpectation.Route 'Shard=All' `
    'TEST-0159 quick default invocation did not resolve Shard=All.'
Assert-Equal $quickNativeExpectation.Route 'Shard=WindowsNative' `
    'TEST-0159 quick WindowsNative invocation lacks a reviewed route.'
Assert-Equal $bootstrapExpectation.Route 'Shard=All' `
    'TEST-0159 bootstrap default invocation did not resolve Shard=All.'
Assert-Equal $selfExpectation.Route 'default' `
    'TEST-0159 focused contract invocation did not resolve default.'
Assert-Equal $selfExpectation.Runtime (Get-MeAndAITestRuntimeClass) `
    'TEST-0159 resolved runtime class differs.'
Assert-True ([bool]$quickExpectation.RequiresObservation) `
    'TEST-0159 budgeted quick route is not observation-required.'
Assert-True (-not [bool]$quickNativeExpectation.RequiresObservation) `
    'TEST-0159 reviewed WindowsNative route unexpectedly requires observation.'
Assert-Equal @($quickNativeExpectation.Counters).Count 0 `
    'TEST-0159 reviewed non-observing route contains operation counters.'
Assert-ThrowsLike -Action {
    Resolve-MeAndAITestOperationExpectation -Contract $contract `
        -Owner $quickOwner `
        -SuiteArguments @('-Shard', 'Unreviewed') | Out-Null
} -Pattern '*has no reviewed operation route*' `
    -Message 'TEST-0159 known owner accepted an unreviewed argument signature.'
$undeclaredOwner = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract `
    -Owner 'tests/capabilities/unknown/unknown.tests.ps1' `
    -SuiteArguments @()
Assert-True ($null -eq $undeclaredOwner) `
    'TEST-0159 nonapplicable owner resolved an observation expectation.'

$manifestRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-operation-contract-' + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($manifestRoot) | Out-Null
    $manifestSource = [IO.File]::ReadAllText($contractPath)
    $badSources = @(
        $manifestSource.Replace(
            "    Capability = 'test-runtime-efficiency'",
            "    Unexpected = 'value'`r`n    Capability = 'test-runtime-efficiency'"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue 'SchemaVersion = [long]1' `
            -NewValue 'SchemaVersion = 1'),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue "Name = 'reusable-fixture-family.bundle'" `
            -NewValue "Name = 'z.unsorted'"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue 'Maximum = [long]11' `
            -NewValue 'Maximum = [long]12'),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue 'Instrumented = $true' `
            -NewValue "Instrumented = 'true'"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue 'RequiresObservation = $false' `
            -NewValue "RequiresObservation = 'false'"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue 'Counters = @()' `
            -NewValue "Counters = @(@{ Name = 'unreviewed'; Maximum = [long]0 })")
    )
    for ($index = 0; $index -lt $badSources.Count; $index++) {
        $path = Join-Path $manifestRoot ("bad-$index.psd1")
        [IO.File]::WriteAllText($path, [string]$badSources[$index],
            [Text.UTF8Encoding]::new($false))
        Assert-ThrowsLike -Action {
            Import-MeAndAITestOperationContract -Path $path
        } -Pattern '*' `
            -Message "TEST-0159 malformed manifest $index was accepted."
    }
}
finally {
    Remove-ContractTempRoot -Path $manifestRoot
}

$twoCounterExpectation = @(
    [pscustomobject][ordered]@{ Name = 'alpha'; Maximum = [long]1 },
    [pscustomobject][ordered]@{ Name = 'beta'; Maximum = [long]2 }
)
$twoCounterActual = @(
    [pscustomobject][ordered]@{
        name = 'alpha'; actual = [long]1; maximum = [long]1
    },
    [pscustomobject][ordered]@{
        name = 'beta'; actual = [long]2; maximum = [long]2
    }
)
$observation = Format-MeAndAITestOperationObservation -Owner $owner `
    -Route default -Runtime $selfExpectation.Runtime `
    -Counters $twoCounterActual
$scenarioFinal = 'MEANDAI_SCENARIO_RESULTS=' +
    ('{"schema":1,"owner":"' + $owner +
     '","passed":["TEST-0158","TEST-0159"]}')
$compatibilityFinal =
    'MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
    '{"schema":1,"suite":"synthetic","shard":"All","passed":true}'
$positive = Read-MeAndAITestOperationObservationRecord `
    -Output @('diagnostic', $observation, $scenarioFinal) `
    -ExpectedOwner $owner -ExpectedRoute default `
    -ExpectedRuntime $selfExpectation.Runtime `
    -ExpectedCounters $twoCounterExpectation
Assert-True $positive.Valid `
    "TEST-0159 valid operation observation was rejected: $($positive.Message)"
$positiveCompatibility = Read-MeAndAITestOperationObservationRecord `
    -Output @($observation, $compatibilityFinal) -ExpectedOwner $owner `
    -ExpectedRoute default -ExpectedRuntime $selfExpectation.Runtime `
    -ExpectedCounters $twoCounterExpectation
Assert-True $positiveCompatibility.Valid `
    'TEST-0159 valid compatibility-final observation was rejected.'

foreach ($badFormat in @(
    [pscustomobject]@{
        Name = 'string value'
        Counters = @([pscustomobject][ordered]@{
            name = 'alpha'; actual = '1'; maximum = [long]1
        })
    },
    [pscustomobject]@{
        Name = 'negative value'
        Counters = @([pscustomobject][ordered]@{
            name = 'alpha'; actual = [long]-1; maximum = [long]1
        })
    },
    [pscustomobject]@{
        Name = 'over maximum'
        Counters = @([pscustomobject][ordered]@{
            name = 'alpha'; actual = [long]2; maximum = [long]1
        })
    },
    [pscustomobject]@{
        Name = 'unsorted'
        Counters = @($twoCounterActual[1], $twoCounterActual[0])
    },
    [pscustomobject]@{
        Name = 'extra property'
        Counters = @([pscustomobject][ordered]@{
            name = 'alpha'; actual = [long]1; maximum = [long]1
            success = $true
        })
    },
    [pscustomobject]@{
        Name = 'random path property'
        Counters = @([pscustomobject][ordered]@{
            name = 'alpha'; actual = [long]1; maximum = [long]1
            path = 'C:\random\fixture'
        })
    }
)) {
    Assert-ThrowsLike -Action {
        Format-MeAndAITestOperationObservation -Owner $owner -Route default `
            -Runtime $selfExpectation.Runtime -Counters $badFormat.Counters
    } -Pattern '*' `
        -Message "TEST-0159 formatter accepted $($badFormat.Name)."
}

$wrongOwner = $observation.Replace(
    'test-runtime-efficiency/test-runtime-efficiency.tests.ps1',
    'test-runtime-efficiency/wrong.tests.ps1')
$wrongRoute = $observation.Replace('"route":"default"',
    '"route":"Shard=All"')
$otherRuntime = 'PowerShell7'
if ($selfExpectation.Runtime -ceq 'PowerShell7') {
    $otherRuntime = 'WindowsPowerShell5.1'
}
$wrongRuntime = $observation.Replace(
    ('"runtime":"' + $selfExpectation.Runtime + '"'),
    ('"runtime":"' + $otherRuntime + '"'))
$stringValue = $observation.Replace('"actual":1', '"actual":"1"')
$negativeValue = $observation.Replace('"actual":1', '"actual":-1')
$overMaximum = $observation.Replace('"actual":1', '"actual":2')
$unsorted = $observation.Replace(
    '[{"name":"alpha","actual":1,"maximum":1},{"name":"beta","actual":2,"maximum":2}]',
    '[{"name":"beta","actual":2,"maximum":2},{"name":"alpha","actual":1,"maximum":1}]')
$extraProperty = $observation.Replace('"counters":',
    '"success":true,"counters":')
$randomProperty = $observation.Replace('"counters":',
    '"path":"C:\\random\\fixture","counters":')
foreach ($badObservation in @(
    [pscustomobject]@{ Name = 'missing'; Lines = @($scenarioFinal) },
    [pscustomobject]@{
        Name = 'duplicate'
        Lines = @($observation, $observation, $scenarioFinal)
    },
    [pscustomobject]@{
        Name = 'malformed'
        Lines = @('MEANDAI_OPERATION_OBSERVATION={', $scenarioFinal)
    },
    [pscustomobject]@{
        Name = 'not penultimate'
        Lines = @($observation, 'noise', $scenarioFinal)
    },
    [pscustomobject]@{ Name = 'wrong owner'; Lines = @($wrongOwner, $scenarioFinal) },
    [pscustomobject]@{ Name = 'wrong route'; Lines = @($wrongRoute, $scenarioFinal) },
    [pscustomobject]@{ Name = 'wrong runtime'; Lines = @($wrongRuntime, $scenarioFinal) },
    [pscustomobject]@{
        Name = 'scenario plus compatibility final'
        Lines = @($observation, $scenarioFinal, $compatibilityFinal)
    },
    [pscustomobject]@{ Name = 'string'; Lines = @($stringValue, $scenarioFinal) },
    [pscustomobject]@{ Name = 'negative'; Lines = @($negativeValue, $scenarioFinal) },
    [pscustomobject]@{ Name = 'over maximum'; Lines = @($overMaximum, $scenarioFinal) },
    [pscustomobject]@{ Name = 'unsorted'; Lines = @($unsorted, $scenarioFinal) },
    [pscustomobject]@{ Name = 'extra'; Lines = @($extraProperty, $scenarioFinal) },
    [pscustomobject]@{ Name = 'random'; Lines = @($randomProperty, $scenarioFinal) }
)) {
    Assert-InvalidObservation -Lines $badObservation.Lines `
        -Expectation ([pscustomobject]@{
            Owner = $owner
            Route = 'default'
            Runtime = $selfExpectation.Runtime
            Counters = $twoCounterExpectation
        }) -Message "TEST-0159 parser accepted $($badObservation.Name)."
}

# These checks protect only the required integration seams. The owning suites
# remain responsible for executable fixture, child-process, and graph evidence.
$quickPath = Join-Path $root `
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
$bootstrapPath = Join-Path $root `
    ('tests/capabilities/initial-adoption/' +
     'capabilities-bootstrap-adapter' + '.fixture.ps1')
$runnerPath = Join-Path $root 'tests/protocol.tests.ps1'
$quickAst = Get-ParsedTestAst -Path $quickPath
$quickOperationInventory = Get-ReviewedOperationInventory -Ast $quickAst `
    -CommandNames @(
        'git', 'Invoke-Git', 'Invoke-TestGit',
        'Invoke-QuickAdoptionFixtureFamilyGitInit'
    )
$expectedQuickOperationInventory = [ordered]@{
    'clone|<script>|Invoke-Git' = 1
    'clone|<script>|Invoke-TestGit' = 3
    'clone|Add-MockRootRuleGitlink|Invoke-TestGit' = 1
    'clone|Advance-MockPublishedDefaultBranch|Invoke-TestGit' = 1
    'clone|global:gh|git' = 1
    'clone|Invoke-External|git' = 1
    'clone|Publish-MockAdoptionBranch|Invoke-TestGit' = 1
    'init|<script>|git' = 26
    'init|global:gh|git' = 1
    'init|Invoke-QuickAdoptionFixtureFamilyGitInit|git' = 1
    'init|New-MockEmptyRemoteConsumer|git' = 2
    'push|<script>|Invoke-Git' = 10
    'push|<script>|Invoke-TestGit' = 8
    'push|Add-MockRootRuleGitlink|Invoke-TestGit' = 1
    'push|Advance-MockPublishedDefaultBranch|Invoke-TestGit' = 1
    'push|New-MockConnectedManagedConsumerPair|Invoke-TestGit' = 1
    'push|New-MockConnectedSeedConsumerPair|Invoke-TestGit' = 2
    'push|Publish-MockAdoptionBranch|Invoke-TestGit' = 1
    'push|Reset-MockAdoptionProposal|Invoke-TestGit' = 1
}
Assert-ReviewedOperationInventory -Actual $quickOperationInventory `
    -Expected $expectedQuickOperationInventory -Label 'quick-adoption'
$quickGitAliases = @($quickAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    @('Set-Alias', 'New-Alias') -ccontains $node.GetCommandName() -and
    $node.Extent.Text -cmatch '(?i)\b(?:git|Invoke-Git|Invoke-TestGit)\b'
}, $true))
Assert-Equal $quickGitAliases.Count 0 `
    'TEST-0159 quick-adoption declares an unreviewed Git alias.'
$quickDynamicInvocations = Get-ReviewedDynamicInvocationInventory -Ast $quickAst
$expectedQuickDynamicInvocations = [ordered]@{
    '$Builder|Get-QuickAdoptionReusableFixture' = 1
    '$Builder|Get-TestCommittedInstructionGraph' = 1
    '$changeSetValidator|<script>' = 7
    '$closureResolver|<script>' = 17
    '$completionContract|<script>' = 12
    '$gitBinary|Get-TestCommittedInstructionGraph' = 1
    '$graphIdentityGetter|<script>' = 1
    '$graphRecordConverter|<script>' = 1
    '$graphRecordConverter|global:gh' = 1
    '$identityValidator|global:gh' = 1
    '$launcherPath|<script>' = 79
    '$launcherPath|New-MockCompletedAdoptionConsumer' = 1
    '$manifestValidationModule|<script>' = 1
    '$manifestValidator|<script>' = 2
    '$markerCultureModule|<script>' = 1
    '$markerValidator|<script>' = 1
    '$migrationManifestValidator|<script>' = 1
    '$postValidationClosureResolver|<script>' = 1
    '$proposalMarkerContract|<script>' = 2
    '$recoveryModule|<script>' = 2
    '$rootStrategyContract|<script>' = 1
    '$rootSurfaceContract|<script>' = 1
    '$ruleGraphBuilder|<script>' = 1
    '$strategyResolver|<script>' = 4
    '$surfaceInventoryContract|<script>' = 2
    '$targetCommand|New-TestQuickAdoptionCompletionContractFixture' = 1
    '$targetPathGetter|<script>' = 1
    '$Validator|Get-TestCommittedInstructionGraph' = 1
}
Assert-ReviewedOperationInventory -Actual $quickDynamicInvocations `
    -Expected $expectedQuickDynamicInvocations `
    -Label 'quick-adoption dynamic invocation'
$quickUnclassifiedGitSplats =
    Get-ReviewedUnclassifiedGitSplatInventory -Ast $quickAst
Assert-ReviewedOperationInventory -Actual $quickUnclassifiedGitSplats `
    -Expected ([ordered]@{
        '@Arguments|Invoke-Git|git' = 1
        '@Arguments|Invoke-TestGit|git' = 1
    }) -Label 'quick-adoption unclassified Git splat'
$syntheticTokens = $null
$syntheticErrors = $null
$syntheticDynamicGitAst =
    [System.Management.Automation.Language.Parser]::ParseInput(
        'function Invoke-Escape { & git @gitArguments }',
        [ref]$syntheticTokens,
        [ref]$syntheticErrors
    )
Assert-Equal @($syntheticErrors).Count 0 `
    'TEST-0159 synthetic dynamic Git negative did not parse.'
$syntheticDynamicGitInventory =
    Get-ReviewedUnclassifiedGitSplatInventory -Ast $syntheticDynamicGitAst
Assert-ReviewedOperationInventory -Actual $syntheticDynamicGitInventory `
    -Expected ([ordered]@{ '@gitArguments|Invoke-Escape|git' = 1 }) `
    -Label 'synthetic dynamic Git negative'
$quickRecursiveCleanup = Get-ReviewedRecursiveCleanupInventory -Ast $quickAst
Assert-ReviewedOperationInventory -Actual $quickRecursiveCleanup `
    -Expected ([ordered]@{ 'Remove-Item|<script>' = 3 }) `
    -Label 'quick-adoption recursive cleanup'
$quickCalls = @($quickAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Invoke-QuickAdoptionFixtureFamilyGitInit'
}, $true))
$quickParents = @(
    'Initialize-QuickAdoptionImmutableFixture',
    'New-MockConnectedManagedConsumerPair',
    'New-MockConnectedSeedConsumerPair'
)
$expectedQuickCalls = [ordered]@{
    'Initialize-QuickAdoptionImmutableFixture' = 1
    'New-MockConnectedManagedConsumerPair' = 2
    'New-MockConnectedSeedConsumerPair' = 2
}
foreach ($call in $quickCalls) {
    $parentName = Get-ParentFunctionName -Node $call
    Assert-True ($quickParents -ccontains $parentName) `
        "TEST-0159 quick fixture-family init escaped its reviewed owner: $parentName."
}
foreach ($entry in $expectedQuickCalls.GetEnumerator()) {
    Assert-Equal @($quickCalls | Where-Object {
        (Get-ParentFunctionName -Node $_) -ceq [string]$entry.Key
    }).Count ([int]$entry.Value) `
        "TEST-0159 quick fixture-family init call count differs for '$($entry.Key)'."
}
$quickDirectInitCalls = @($quickAst.FindAll({
    param($node)
    if ($node -isnot [System.Management.Automation.Language.CommandAst] -or
        @('git', 'Invoke-Git', 'Invoke-TestGit') -cnotcontains
            $node.GetCommandName() -or
        $node.Extent.Text -cnotmatch
            '(?i)(?:^|[\s''"])init(?:$|[\s''",])') {
        return $false
    }
    return $quickParents -ccontains (Get-ParentFunctionName -Node $node)
}, $true))
Assert-Equal $quickDirectInitCalls.Count 0 `
    'TEST-0159 reviewed quick fixture-family owners bypass the counted init wrapper.'

$bootstrapAst = Get-ParsedTestAst -Path $bootstrapPath
$bootstrapOperationInventory = Get-ReviewedOperationInventory `
    -Ast $bootstrapAst -CommandNames @('git', 'Invoke-Git')
$expectedBootstrapOperationInventory = [ordered]@{
    'bundle|New-ImmutableBootstrapBaseline|Invoke-Git' = 4
    'clone|<script>|Invoke-Git' = 1
    'clone|global:gh|Invoke-Git' = 1
    'clone|New-ImmutableBootstrapBaseline|Invoke-Git' = 2
    'init|New-BootstrapFixture|Invoke-Git' = 1
    'init|New-ImmutableBootstrapBaseline|Invoke-Git' = 3
    'push|<script>|Invoke-Git' = 15
    'push|global:gh|Invoke-Git' = 2
    'push|Install-CompleteLocalUpdaterFixture|Invoke-Git' = 1
    'push|Install-StrategyCompletionTree|Invoke-Git' = 1
    'push|New-BootstrapFixture|Invoke-Git' = 1
}
Assert-ReviewedOperationInventory -Actual $bootstrapOperationInventory `
    -Expected $expectedBootstrapOperationInventory -Label 'bootstrap'
$bootstrapGitAliases = @($bootstrapAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    @('Set-Alias', 'New-Alias') -ccontains $node.GetCommandName() -and
    $node.Extent.Text -cmatch '(?i)\b(?:git|Invoke-Git)\b'
}, $true))
Assert-Equal $bootstrapGitAliases.Count 0 `
    'TEST-0159 bootstrap declares an unreviewed Git alias.'
$bootstrapDynamicInvocations =
    Get-ReviewedDynamicInvocationInventory -Ast $bootstrapAst
$expectedBootstrapDynamicInvocations = [ordered]@{
    '$adapterPath|Invoke-BootstrapFixture' = 2
    '$engine|Get-FixtureInstructionGraphIdentity' = 1
    '$engine|Invoke-IsolatedGraphDriftFixture' = 1
    '$engine|Invoke-IsolatedGraphSuccessFixture' = 1
}
Assert-ReviewedOperationInventory -Actual $bootstrapDynamicInvocations `
    -Expected $expectedBootstrapDynamicInvocations `
    -Label 'bootstrap dynamic invocation'
$bootstrapRecursiveCleanup =
    Get-ReviewedRecursiveCleanupInventory -Ast $bootstrapAst
Assert-ReviewedOperationInventory -Actual $bootstrapRecursiveCleanup `
    -Expected ([ordered]@{ 'Remove-Item|<script>' = 2 }) `
    -Label 'bootstrap recursive cleanup'
$bootstrapChildProcesses = @($bootstrapAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.InvocationOperator -eq
        [System.Management.Automation.Language.TokenKind]::Ampersand -and
    $node.CommandElements.Count -gt 0 -and
    $node.CommandElements[0].Extent.Text -ceq '$engine'
}, $true))
$expectedBootstrapChildParents = [ordered]@{
    'Get-FixtureInstructionGraphIdentity' = 1
    'Invoke-IsolatedGraphDriftFixture' = 1
    'Invoke-IsolatedGraphSuccessFixture' = 1
}
Assert-Equal $bootstrapChildProcesses.Count 3 `
    'TEST-0159 bootstrap child-process call-site count differs.'
foreach ($entry in $expectedBootstrapChildParents.GetEnumerator()) {
    Assert-Equal @($bootstrapChildProcesses | Where-Object {
        (Get-ParentFunctionName -Node $_) -ceq [string]$entry.Key
    }).Count ([int]$entry.Value) `
        "TEST-0159 bootstrap child-process count differs for '$($entry.Key)'."
}
$bootstrapIncrements = @($bootstrapAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.UnaryExpressionAst] -and
    $node.TokenKind -eq
        [System.Management.Automation.Language.TokenKind]::PostfixPlusPlus -and
    $node.Extent.Text -cmatch
        '^\$script:BootstrapFixtureOperations\.[A-Za-z]+\+\+$'
}, $true))
$bootstrapParents = @(
    'New-ImmutableBootstrapBaseline',
    'New-BootstrapFixture',
    'Get-FixtureInstructionGraphIdentity',
    'Invoke-IsolatedGraphDriftFixture',
    'Invoke-IsolatedGraphSuccessFixture'
)
Assert-True ($bootstrapIncrements.Count -gt 0) `
    'TEST-0159 bootstrap operation counters have no increment sites.'
foreach ($increment in $bootstrapIncrements) {
    $parentName = Get-ParentFunctionName -Node $increment
    Assert-True ($bootstrapParents -ccontains $parentName) `
        "TEST-0159 bootstrap operation counter escaped its reviewed owner: $parentName."
}
$expectedBootstrapIncrements = [ordered]@{
    FixtureInit = 3
    FixtureClone = 2
    FixtureBundleCreate = 2
    FixturePublicationPush = 1
    GraphChildProcess = 3
    GraphIsolatedAcquisition = 2
}
foreach ($entry in $expectedBootstrapIncrements.GetEnumerator()) {
    Assert-Equal @($bootstrapIncrements | Where-Object {
        $_.Extent.Text -ceq
            "`$script:BootstrapFixtureOperations.$($entry.Key)++"
    }).Count ([int]$entry.Value) `
        "TEST-0159 bootstrap counter increment count differs for '$($entry.Key)'."
}

$runnerAst = Get-ParsedTestAst -Path $runnerPath
$operationReads = @($runnerAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq
        'Read-MeAndAITestOperationObservationRecord'
}, $true))
$scenarioReads = @($runnerAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Read-MeAndAIScenarioResultRecord'
}, $true))
$compatibilityReads = @($runnerAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Read-MeAndAICompatibilityShardResultRecord'
}, $true))
$operationRequirementReads = @($runnerAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.MemberExpressionAst] -and
    $node.Member -is
        [System.Management.Automation.Language.StringConstantExpressionAst] -and
    $node.Member.Value -ceq 'RequiresObservation'
}, $true))
Assert-Equal $operationReads.Count 1 `
    'TEST-0159 root runner operation parser call count differs.'
Assert-Equal $scenarioReads.Count 1 `
    'TEST-0159 root runner scenario parser call count differs.'
Assert-Equal $compatibilityReads.Count 1 `
    'TEST-0159 root runner compatibility parser call count differs.'
Assert-Equal $operationRequirementReads.Count 1 `
    'TEST-0159 root runner does not enforce reviewed route observation policy.'
if ($operationReads.Count -eq 1 -and $scenarioReads.Count -eq 1 -and
    $compatibilityReads.Count -eq 1) {
    Assert-True ($operationReads[0].Extent.StartOffset -lt
        $scenarioReads[0].Extent.StartOffset) `
        'TEST-0159 root runner parses scenario success before operation evidence.'
    Assert-True ($operationReads[0].Extent.StartOffset -lt
        $compatibilityReads[0].Extent.StartOffset) `
        'TEST-0159 root runner parses compatibility success before operation evidence.'
}

$hotspotContracts = @(
    [pscustomobject]@{
        Path = $quickPath
        Tokens = @(
            'function Invoke-QuickAdoptionFixtureFamilyGitInit',
            'function Get-QuickAdoptionReusableFixture',
            'function Get-QuickAdoptionStringSha256',
            'function Get-QuickAdoptionFixtureEntryMode',
            'function New-QuickAdoptionMutableDerivative',
            'function Assert-QuickAdoptionFixtureReuse',
            'OwnerSourceDigest',
            'InputRecords',
            'fingerprint ignored a mode-only mutation',
            'quick-adoption recovery fixture cleanup leaked root',
            'conflicts with its canonical builder or input digest'
        )
    },
    [pscustomobject]@{
        Path = $bootstrapPath
        Tokens = @(
            'function New-ImmutableBootstrapBaseline',
            'function Get-BootstrapFixtureEntryMode',
            'function Assert-ImmutableBootstrapBaseline',
            'function Assert-BootstrapPreparedSeedContract',
            'function Assert-BootstrapFixtureOperationClosure',
            'bootstrap fingerprint ignored a mode-only mutation',
            'bootstrap fixture cleanup leaked roots'
        )
    }
)
foreach ($hotspot in $hotspotContracts) {
    $source = [IO.File]::ReadAllText($hotspot.Path)
    foreach ($token in $hotspot.Tokens) {
        Assert-True $source.Contains($token) `
            "TEST-0158 required hotspot contract '$token' is absent."
    }
}

$workflowPath = Join-Path $root '.github/workflows/protocol-tests.yml'
$workflowSource = [IO.File]::ReadAllText($workflowPath)
$windowsPowerShell7Step =
    'Run runtime-efficiency contract on Windows PowerShell 7'
Assert-Equal ([regex]::Matches(
    $workflowSource,
    [regex]::Escape("- name: $windowsPowerShell7Step")
)).Count 1 `
    'TEST-0160 Windows PowerShell 7 focused step count differs.'
foreach ($requiredWorkflowToken in @(
    "- name: $windowsPowerShell7Step",
    'shell: pwsh',
    './tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1'
)) {
    Assert-True $workflowSource.Contains($requiredWorkflowToken) `
        "TEST-0160 hosted workflow lacks '$requiredWorkflowToken'."
}

if ($failures.Count -gt 0) {
    Write-Host "Test-runtime-efficiency validation failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$selfCounters = @([pscustomobject][ordered]@{
    name = 'contract.self-check'
    actual = [long]1
    maximum = [long]$selfExpectation.Counters[0].Maximum
})
$selfObservation = Format-MeAndAITestOperationObservation -Owner $owner `
    -Route $selfExpectation.Route -Runtime $selfExpectation.Runtime `
    -Counters $selfCounters
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0158'
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0159'
$scenarioResult = New-MeAndAIScenarioResult -Owner $owner `
    -SourcePaths @($PSCommandPath) -AuthorityPath $authorityPath
Write-Host 'Test-runtime operation contracts passed.' -ForegroundColor Green
Write-Host $selfObservation
Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
    ($scenarioResult | ConvertTo-Json -Compress))
