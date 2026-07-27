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
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $authorityPath
$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    Assert-MeAndAITestCollectedTrue -Context $failureContext `
        -Condition $Condition -Message $Message
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

function Swap-FirstOrdinal {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$First,
        [Parameter(Mandatory)][string]$Second
    )

    $placeholder = '__MEANDAI_OPERATION_CONTRACT_SWAP__'
    if ($Source.Contains($placeholder)) {
        throw 'Synthetic manifest swap placeholder already exists.'
    }
    $result = Replace-FirstOrdinal -Source $Source -OldValue $First `
        -NewValue $placeholder
    $result = Replace-FirstOrdinal -Source $result -OldValue $Second `
        -NewValue $First
    return Replace-FirstOrdinal -Source $result -OldValue $placeholder `
        -NewValue $Second
}

function Get-OptionalPropertyValue {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Value) { return $null }
    $property = $Value.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-CanonicalTargetMeasurementBindings {
    param(
        [Parameter(Mandatory)][object[]]$Targets,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Expected
    )

    if ($Targets.Count -ne $Expected.Count) { return $false }
    foreach ($target in $Targets) {
        $identity = "$($target.Owner)|$($target.Route)|$($target.Counter)"
        if (-not $Expected.Contains($identity)) { return $false }
        $parts = @(([string]$Expected[$identity]).Split('|'))
        if ($parts.Count -ne 3 -or
            [string]$target.MeasurementId -cne $parts[1]) {
            return $false
        }
    }
    return $true
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

function Assert-TestOwnedRawGitBatchStdinContract {
    param(
        [Parameter(Mandatory)]
        [Management.Automation.Language.FunctionDefinitionAst]$FunctionAst,
        [Parameter(Mandatory)][string]$Label
    )

    $source = [string]$FunctionAst.Extent.Text
    $encodingTries = @($FunctionAst.Body.FindAll({
        param($node)
        if ($node -isnot
                [Management.Automation.Language.TryStatementAst] -or
            $null -eq $node.Finally) {
            return $false
        }
        $bodySource = [string]$node.Body.Extent.Text
        $finallySource = [string]$node.Finally.Extent.Text
        return $bodySource -cmatch (
            '(?s)\[Console\]::InputEncoding\s*=\s*' +
            '\[Text\.UTF8Encoding\]::new\(\$false\)'
        ) -and $bodySource -cmatch '\$process\.Start\(\)' -and
            $bodySource -cmatch (
                '(?s)\$state\.InputStream\s*=\s*' +
                '\$process\.StandardInput\.BaseStream'
            ) -and $finallySource -cmatch (
                '(?s)\[Console\]::InputEncoding\s*=\s*' +
                '\$originalInputEncoding'
            )
    }, $true))
    Assert-Equal $encodingTries.Count 1 `
        "TEST-0162 $Label lacks one scoped no-BOM capture try/finally."
    if ($encodingTries.Count -eq 1) {
        $encodingTry = $encodingTries[0]
        $bodySource = [string]$encodingTry.Body.Extent.Text
        $noBomEncoding = [regex]::Match(
            $bodySource,
            '(?s)\[Console\]::InputEncoding\s*=\s*' +
            '\[Text\.UTF8Encoding\]::new\(\$false\)'
        )
        $processStart = [regex]::Match($bodySource, '\$process\.Start\(\)')
        $rawInputCapture = [regex]::Match(
            $bodySource,
            '(?s)\$state\.InputStream\s*=\s*' +
            '\$process\.StandardInput\.BaseStream'
        )
        Assert-True (
            $noBomEncoding.Success -and $processStart.Success -and
            $rawInputCapture.Success -and
            $noBomEncoding.Index -lt $processStart.Index -and
            $processStart.Index -lt $rawInputCapture.Index
        ) "TEST-0162 $Label no-BOM start/capture order differs."
        $lastTryStatement = @($encodingTry.Body.Statements)[-1]
        Assert-True (
            [string]$lastTryStatement.Extent.Text -cmatch (
                '(?s)^\s*\$state\.InputStream\s*=\s*' +
                '\$process\.StandardInput\.BaseStream\s*$'
            )
        ) "TEST-0162 $Label does not restore ambient encoding immediately after capture."
        $finallyStatements = @($encodingTry.Finally.Statements)
        Assert-True (
            $finallyStatements.Count -eq 1 -and
            [string]$finallyStatements[0].Extent.Text -cmatch (
                '(?s)^\s*\[Console\]::InputEncoding\s*=\s*' +
                '\$originalInputEncoding\s*$'
            )
        ) "TEST-0162 $Label ambient restore is not the exact finally action."
        $encodingSaves = @($FunctionAst.Body.FindAll({
            param($node)
            return $node -is
                    [Management.Automation.Language.AssignmentStatementAst] -and
                [string]$node.Extent.Text -cmatch (
                    '(?s)^\s*\$originalInputEncoding\s*=\s*' +
                    '\[Console\]::InputEncoding\s*$'
                )
        }, $true))
        Assert-True (
            $encodingSaves.Count -eq 1 -and
            $encodingSaves[0].Extent.EndOffset -le
                $encodingTry.Extent.StartOffset
        ) "TEST-0162 $Label does not save ambient encoding before the capture scope."
    }
    $standardInputAccesses = @($FunctionAst.Body.FindAll({
        param($node)
        return $node -is
                [Management.Automation.Language.MemberExpressionAst] -and
            [string]$node.Extent.Text -cmatch '(?s)\.StandardInput\s*$'
    }, $true))
    Assert-Equal $standardInputAccesses.Count 1 `
        "TEST-0162 $Label has an alternate StandardInput access."
    Assert-True ($source -cmatch
        '(?s)\$state\.InputStream\.Write(?:Async)?\s*\(') `
        "TEST-0162 $Label does not write through its raw stdin pipe."
    Assert-True ($source -cmatch
        '(?s)\$state\.InputStream\.Flush(?:Async)?\s*\(') `
        "TEST-0162 $Label does not flush its raw stdin pipe."
    Assert-True ($source -cmatch
        '(?s)\$state\.InputStream\.Close\s*\(') `
        "TEST-0162 $Label does not close its raw stdin pipe."
    Assert-True ($source -cnotmatch '(?s)\.StandardInput\.Close\s*\(') `
        "TEST-0162 $Label closes the StreamWriter-backed stdin."
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

$test0162FailureCount = $failures.Count
$test0159FailureCount = $failures.Count
$contract = Import-MeAndAITestOperationContract -Path $contractPath
Assert-Equal (Get-OptionalPropertyValue -Value $contract `
    -Name 'SchemaVersion') ([long]2) `
    'TEST-0162 operation contract schema differs.'
Assert-Equal ($contract.PSObject.Properties.Name -join ',') `
    'SchemaVersion,Capability,Measurements,ObservationOwners,ClosureTargets' `
    'TEST-0162 normalized contract property shape differs.'

$measurements = @(
    Get-OptionalPropertyValue -Value $contract -Name 'Measurements'
)
Assert-Equal $measurements.Count 3 `
    'TEST-0162 measurement authority count differs.'
$expectedMeasurements = @(
    [pscustomobject][ordered]@{
        Id = 'feat-0039-v0127-fixtures'
        BaseCommit = '6b01299cfe484c900944b7435d4fef43b11fc38d'
        ObserverDigest =
            'sha256:ed9a8290b24b191274f35c4bef2cd9af14157e2927be94848a2561a54294e04b'
    },
    [pscustomobject][ordered]@{
        Id = 'feat-0040-v0130-graph-transport'
        BaseCommit = '299b8982cd57961e2b3a6136b07af3bfb49a16d1'
        ObserverDigest =
            'sha256:1f0471fbe882ce959afe52f65713a4f3332c3ba0bc1616db0c5b256687fcf4a8'
    },
    [pscustomobject][ordered]@{
        Id = 'feat-0054-v0152-quick-adoption'
        BaseCommit = '9bc12e394725a86d29efb745cbdfa26407ffd3d2'
        ObserverDigest =
            'sha256:cf8e5e2745c0bd2db12c405b282c19900131ead3776c39e942432a17360b9d63'
    }
)
for ($index = 0; $index -lt $expectedMeasurements.Count; $index++) {
    if ($index -ge $measurements.Count -or $null -eq $measurements[$index]) {
        Add-Failure "TEST-0162 measurement authority $index is absent."
        continue
    }
    $measurement = $measurements[$index]
    $expectedMeasurement = $expectedMeasurements[$index]
    Assert-Equal ($measurement.PSObject.Properties.Name -join ',') `
        'Id,BaseCommit,ObserverDigest' `
        "TEST-0162 measurement authority $index property shape differs."
    foreach ($propertyName in @('Id', 'BaseCommit', 'ObserverDigest')) {
        Assert-Equal (Get-OptionalPropertyValue -Value $measurement `
            -Name $propertyName) $expectedMeasurement.$propertyName `
            "TEST-0162 measurement authority $index $propertyName differs."
    }
}

$observationOwners = @(
    Get-OptionalPropertyValue -Value $contract -Name 'ObservationOwners'
)
$closureTargets = @(
    Get-OptionalPropertyValue -Value $contract -Name 'ClosureTargets'
)
Assert-Equal $observationOwners.Count 4 `
    'TEST-0162 observation owner count differs.'
Assert-Equal $closureTargets.Count 11 `
    'TEST-0162 closure target count differs.'

$fixtureMeasurement = 'feat-0039-v0127-fixtures'
$graphMeasurement = 'feat-0040-v0130-graph-transport'
$quickMeasurement = 'feat-0054-v0152-quick-adoption'
$expectedTargets = [ordered]@{
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1|Shard=All|credential-containment.git-process-per-scan' = "5/3|$quickMeasurement|SUBF-0103"
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1|Shard=All|github-cli-version.full-launcher' = "7/2|$quickMeasurement|SUBF-0104"
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1|Shard=All|reusable-fixture-family.init' = "47/11|$fixtureMeasurement|SUBF-0075"
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.init' = "38/3|$fixtureMeasurement|SUBF-0076"
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.clone' = "72/2|$fixtureMeasurement|SUBF-0076"
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.bundle' = "2/2|$fixtureMeasurement|SUBF-0076"
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|reusable-fixture-family.push' = "36/36|$fixtureMeasurement|SUBF-0076"
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|process.child' = "6/4|$fixtureMeasurement|SUBF-0076"
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1|Shard=All|graph.acquisition' = "5/3|$fixtureMeasurement|SUBF-0076"
    'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1|default|instruction-graph.blob-process-start' = "4/2|$graphMeasurement|SUBF-0078"
    'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1|default|instruction-graph.blob-request' = "4/4|$graphMeasurement|SUBF-0078"
}
Assert-True (Test-CanonicalTargetMeasurementBindings `
    -Targets $closureTargets -Expected $expectedTargets) `
    'TEST-0162 canonical target-to-measurement bindings differ.'
foreach ($target in $closureTargets) {
    $identity = "$($target.Owner)|$($target.Route)|$($target.Counter)"
    Assert-True $expectedTargets.Contains($identity) `
        "TEST-0162 unexpected closure target '$identity'."
    if ($expectedTargets.Contains($identity)) {
        $measurementId = Get-OptionalPropertyValue -Value $target `
            -Name 'MeasurementId'
        Assert-Equal ("$($target.Baseline)/$($target.Maximum)|" +
            "$measurementId|$($target.WorkId)") `
            $expectedTargets[$identity] `
            "TEST-0162 closure target '$identity' differs."
    }
    Assert-True ([bool]$target.Instrumented) `
        "TEST-0159 wired target '$identity' lacks instrumentation authority."
}

$quickOwner = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
$bootstrapOwner =
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
$graphOwner =
    'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1'
$quickExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $quickOwner -SuiteArguments @()
$quickNativeExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $quickOwner `
    -SuiteArguments @('-Shard', 'WindowsNative')
$bootstrapExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $bootstrapOwner -SuiteArguments @()
$graphExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $graphOwner -SuiteArguments @()
$selfExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $contract -Owner $owner -SuiteArguments @()
Assert-Equal $quickExpectation.Route 'Shard=All' `
    'TEST-0159 quick default invocation did not resolve Shard=All.'
Assert-Equal $quickNativeExpectation.Route 'Shard=WindowsNative' `
    'TEST-0159 quick WindowsNative invocation lacks a reviewed route.'
Assert-Equal $bootstrapExpectation.Route 'Shard=All' `
    'TEST-0159 bootstrap default invocation did not resolve Shard=All.'
Assert-True ($null -ne $graphExpectation) `
    'TEST-0162 instruction-graph owner has no reviewed default route.'
if ($null -ne $graphExpectation) {
    Assert-Equal $graphExpectation.Route 'default' `
        'TEST-0162 instruction-graph route differs.'
    Assert-True ([bool]$graphExpectation.RequiresObservation) `
        'TEST-0162 instruction-graph route is not observation-required.'
    $expectedGraphCounters = @(
        'instruction-graph.blob-process-start|2',
        'instruction-graph.blob-request|4'
    )
    $actualGraphCounters = @($graphExpectation.Counters | ForEach-Object {
        "$($_.Name)|$($_.Maximum)"
    })
    Assert-Equal ($actualGraphCounters -join ',') `
        ($expectedGraphCounters -join ',') `
        'TEST-0162 instruction-graph route counters differ.'
}
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
    $typedSchemaToken = 'SchemaVersion = [long]1'
    $untypedSchemaToken = 'SchemaVersion = 1'
    if ($manifestSource.Contains('SchemaVersion = [long]2')) {
        $typedSchemaToken = 'SchemaVersion = [long]2'
        $untypedSchemaToken = 'SchemaVersion = 2'
    }
    $badSources = @(
        $manifestSource.Replace(
            "    Capability = 'test-runtime-efficiency'",
            "    Unexpected = 'value'`r`n    Capability = 'test-runtime-efficiency'"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue $typedSchemaToken `
            -NewValue $untypedSchemaToken),
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
            -NewValue "Counters = @(@{ Name = 'unreviewed'; Maximum = [long]0 })"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue "Id = 'feat-0039-v0127-fixtures'" `
            -NewValue '# Id intentionally absent'),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue "MeasurementId = 'feat-0039-v0127-fixtures'" `
            -NewValue '# MeasurementId intentionally absent'),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue "MeasurementId = 'feat-0039-v0127-fixtures'" `
            -NewValue "MeasurementId = 'feat-9999-v9999-unknown'"),
        (Replace-FirstOrdinal -Source $manifestSource `
            -OldValue "Id = 'feat-0040-v0130-graph-transport'" `
            -NewValue "Id = 'feat-0039-v0127-fixtures'"),
        (Swap-FirstOrdinal -Source $manifestSource `
            -First "Id = 'feat-0039-v0127-fixtures'" `
            -Second "Id = 'feat-0040-v0130-graph-transport'")
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

    $crossWorkSource = Replace-FirstOrdinal -Source $manifestSource `
        -OldValue "MeasurementId = 'feat-0039-v0127-fixtures'" `
        -NewValue "MeasurementId = 'feat-0040-v0130-graph-transport'"
    $crossWorkPath = Join-Path $manifestRoot 'cross-work.psd1'
    [IO.File]::WriteAllText($crossWorkPath, $crossWorkSource,
        [Text.UTF8Encoding]::new($false))
    $crossWorkContract = Import-MeAndAITestOperationContract `
        -Path $crossWorkPath
    Assert-True (-not (Test-CanonicalTargetMeasurementBindings `
        -Targets @($crossWorkContract.ClosureTargets) `
        -Expected $expectedTargets)) `
        'TEST-0162 canonical bindings accepted a valid-known cross-work measurement swap.'
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
     '","passed":["TEST-0158","TEST-0159","TEST-0162"]}')
$compatibilityFinal =
    'MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
    '{"schema":1,"suite":"synthetic","shard":"All","passed":true}'
$selfObservation = Format-MeAndAITestOperationObservation -Owner $owner `
    -Route default -Runtime $selfExpectation.Runtime -Counters @(
        [pscustomobject][ordered]@{
            name = 'contract.self-check'
            actual = [long]1
            maximum = [long]1
        }
    )
Assert-MeAndAITestSuiteOperationEvidence -Contract $contract -Owner $owner `
    -SuiteArguments @() -Output @($selfObservation, $scenarioFinal)
Assert-ThrowsLike -Action {
    Assert-MeAndAITestSuiteOperationEvidence -Contract $contract `
        -Owner $owner -SuiteArguments @() -Output @($scenarioFinal)
} -Pattern '*invalid operation evidence*' `
    -Message 'TEST-0159 parent contract accepted missing required operation evidence.'
Assert-MeAndAITestSuiteOperationEvidence -Contract $contract `
    -Owner $quickOwner -SuiteArguments @('-Shard', 'WindowsNative') `
    -Output @($compatibilityFinal)
Assert-ThrowsLike -Action {
    Assert-MeAndAITestSuiteOperationEvidence -Contract $contract `
        -Owner $quickOwner -SuiteArguments @('-Shard', 'WindowsNative') `
        -Output @($selfObservation, $compatibilityFinal)
} -Pattern '*reviewed non-observing route*' `
    -Message 'TEST-0159 parent contract accepted evidence on a non-observing route.'
Assert-ThrowsLike -Action {
    Assert-MeAndAITestSuiteOperationEvidence -Contract $contract `
        -Owner $quickOwner -SuiteArguments @('-Shard', 'Unreviewed') `
        -Output @($compatibilityFinal)
} -Pattern '*has no reviewed operation route*' `
    -Message 'TEST-0159 parent contract accepted an unknown known-owner route.'
$unknownOwner = 'tests/capabilities/unknown/unknown.tests.ps1'
Assert-MeAndAITestSuiteOperationEvidence -Contract $contract `
    -Owner $unknownOwner -SuiteArguments @() -Output @($scenarioFinal)
Assert-ThrowsLike -Action {
    Assert-MeAndAITestSuiteOperationEvidence -Contract $contract `
        -Owner $unknownOwner -SuiteArguments @() `
        -Output @($selfObservation, $scenarioFinal)
} -Pattern '*without a reviewed owner contract*' `
    -Message 'TEST-0159 parent contract accepted unowned operation evidence.'
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
$quickActorPath = Join-Path $root `
    'scripts/quick-adoption/Private/RepositoryAssessment.ps1'
$hostedActorPath = Join-Path $root `
    'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$actorTransportContracts = @(
    [pscustomobject][ordered]@{
        Label = 'quick-adoption actor'
        Path = $quickActorPath
        Factory = 'New-QuickAdoptionInstructionGraphBatchSession'
        Graph = 'Get-QuickAdoptionInstructionGraph'
        Tree = 'Get-QuickAdoptionInstructionGraphTreeEntries'
        Legacy = 'Get-QuickAdoptionInstructionGraphBlobBytes'
    },
    [pscustomobject][ordered]@{
        Label = 'hosted bootstrap actor'
        Path = $hostedActorPath
        Factory = 'New-InstructionGraphBatchSession'
        Graph = 'Get-InstructionGraphForCommit'
        Tree = 'Get-InstructionGraphTreeEntries'
        Legacy = 'Get-InstructionGraphBlobBytes'
    }
)
foreach ($actorContract in $actorTransportContracts) {
    $actorSource = [IO.File]::ReadAllText($actorContract.Path)
    $actorAst = Get-ParsedTestAst -Path $actorContract.Path
    $actorFunctions = @($actorAst.FindAll({
        param($node)
        $node -is
            [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true))
    $factoryDefinitions = @($actorFunctions | Where-Object {
        $_.Name -ceq $actorContract.Factory
    })
    Assert-Equal $factoryDefinitions.Count 1 `
        "TEST-0162 $($actorContract.Label) batch-session factory count differs."
    $legacyDefinitions = @($actorFunctions | Where-Object {
        $_.Name -ceq $actorContract.Legacy
    })
    Assert-Equal $legacyDefinitions.Count 0 `
        "TEST-0162 $($actorContract.Label) retains its per-blob reader."

    $factoryCalls = @($actorAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -ceq $actorContract.Factory
    }, $true))
    Assert-Equal $factoryCalls.Count 1 `
        "TEST-0162 $($actorContract.Label) batch-session acquisition count differs."
    if ($factoryCalls.Count -eq 1) {
        Assert-Equal (Get-ParentFunctionName -Node $factoryCalls[0]) `
            $actorContract.Graph `
            "TEST-0162 $($actorContract.Label) batch session escaped its graph owner."
    }

    $perBlobLiteralCount = [regex]::Matches(
        $actorSource, '(?i)cat-file\s+blob(?:\s|[$"''])'
    ).Count
    Assert-Equal $perBlobLiteralCount 0 `
        "TEST-0162 $($actorContract.Label) retains direct per-blob cat-file transport."

    $transportOwners = @($actorFunctions | Where-Object {
        $_.Name -cmatch 'InstructionGraph' -and
        $_.Body.Extent.Text -cmatch '(?i)(?:ProcessStartInfo|cat-file)'
    })
    $unexpectedTransportOwners = @($transportOwners | Where-Object {
        $_.Name -cne $actorContract.Factory -and
        $_.Name -cne $actorContract.Tree
    })
    Assert-Equal $unexpectedTransportOwners.Count 0 `
        "TEST-0162 $($actorContract.Label) has an alternate instruction-graph transport owner."
    if ($factoryDefinitions.Count -eq 1) {
        Assert-True ($factoryDefinitions[0].Body.Extent.Text -cmatch
            '(?i)cat-file\s+--batch(?:\s|["''])') `
            "TEST-0162 $($actorContract.Label) factory lacks canonical cat-file --batch transport."
    }
}

$quickPath = Join-Path $root `
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
$bootstrapPath = Join-Path $root `
    ('tests/capabilities/initial-adoption/' +
     'capabilities-bootstrap-adapter' + '.case.ps1')
$bootstrapGraphIdentityPath = Join-Path $root `
    ('tests/capabilities/initial-adoption/' +
     'capabilities-bootstrap-graph-' + 'identity.case.ps1')
$testGitBatchPath = Join-Path $root `
    'tests/infrastructure/MeAndAI.TestGitBatch.psm1'
$instructionGraphPath = Join-Path $root `
    ('tests/capabilities/instruction-graph-discovery/' +
     'instruction-graph-discovery' + '.tests.ps1')
$runnerPath = Join-Path $root 'tests/protocol.tests.ps1'
$quickAst = Get-ParsedTestAst -Path $quickPath
$quickGraphReaders = @($quickAst.FindAll({
    param($node)
    return $node -is
        [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq 'Get-TestCommittedInstructionGraph'
}, $true))
Assert-Equal $quickGraphReaders.Count 1 `
    'TEST-0162 quick expected graph reader is missing or ambiguous.'
if ($quickGraphReaders.Count -eq 1) {
    $quickGraphReaderSource =
        [string]$quickGraphReaders[0].Extent.Text
    Assert-True ($quickGraphReaderSource -cmatch
        '(?i)New-MeAndAITestGitBlobBatchSession\b') `
        'TEST-0162 quick expected graph reader lacks the shared batch transport.'
    Assert-True ($quickGraphReaderSource -cnotmatch
        '(?i)cat-file\s+(?:--batch|blob)(?:\s|["''])') `
        'TEST-0162 quick expected graph reader bypasses the shared transport.'
}
$bootstrapGraphIdentitySource =
    [IO.File]::ReadAllText($bootstrapGraphIdentityPath)
Assert-Equal @([regex]::Matches($bootstrapGraphIdentitySource,
    '(?i)New-MeAndAITestGitBlobBatchSession\b')).Count 1 `
    'TEST-0162 bootstrap expected graph reader lacks one shared batch session.'
Assert-True ($bootstrapGraphIdentitySource -cnotmatch
    '(?i)cat-file\s+(?:--batch|blob)(?:\s|["''])') `
    'TEST-0162 bootstrap expected graph reader bypasses the shared transport.'
$testGitBatchAst = Get-ParsedTestAst -Path $testGitBatchPath
$testGitBatchFactories = @($testGitBatchAst.FindAll({
    param($node)
    return $node -is
        [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq 'New-MeAndAITestGitBlobBatchSession'
}, $true))
Assert-Equal $testGitBatchFactories.Count 1 `
    'TEST-0162 shared test Git batch factory is missing or ambiguous.'
if ($testGitBatchFactories.Count -eq 1) {
    $testGitBatchSource = [string]$testGitBatchFactories[0].Extent.Text
    Assert-Equal @([regex]::Matches(
        $testGitBatchSource,
        '(?i)cat-file\s+--batch(?:\s|["''])'
    )).Count 1 `
        'TEST-0162 shared test Git reader lacks one batch transport.'
    Assert-True ($testGitBatchSource -cnotmatch
        '(?i)cat-file\s+blob(?:\s|["''])') `
        'TEST-0162 shared test Git reader restored per-blob processes.'
    Assert-TestOwnedRawGitBatchStdinContract `
        -FunctionAst $testGitBatchFactories[0] `
        -Label 'shared test Git reader'
}
$instructionGraphAst = Get-ParsedTestAst -Path $instructionGraphPath
$instructionGraphExpectedReaders = @($instructionGraphAst.FindAll({
    param($node)
    return $node -is
        [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq 'Get-TestCommittedGraphFixture'
}, $true))
Assert-Equal $instructionGraphExpectedReaders.Count 1 `
    'TEST-0162 instruction-graph expected reader is missing or ambiguous.'
if ($instructionGraphExpectedReaders.Count -eq 1) {
    $instructionGraphExpectedReaderSource =
        [string]$instructionGraphExpectedReaders[0].Extent.Text
    Assert-Equal @([regex]::Matches(
        $instructionGraphExpectedReaderSource,
        '(?i)cat-file\s+--batch(?:\s|["''])'
    )).Count 1 `
        'TEST-0162 instruction-graph expected reader lacks one batch transport.'
    Assert-True ($instructionGraphExpectedReaderSource -cnotmatch
        '(?i)cat-file\s+blob(?:\s|["''])') `
        'TEST-0162 instruction-graph expected reader restored per-blob processes.'
    Assert-TestOwnedRawGitBatchStdinContract `
        -FunctionAst $instructionGraphExpectedReaders[0] `
        -Label 'instruction-graph expected reader'
}
if ($failures.Count -eq $test0162FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0162'
}
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
    'push|<script>|Invoke-TestGit' = 10
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
    '$contractAdapterPath|<script>' = 2
    '$graphIdentityGetter|<script>' = 1
    '$graphRecordConverter|<script>' = 1
    '$graphRecordConverter|global:gh' = 1
    '$identityValidator|global:gh' = 1
    # TEST-0069/TEST-0176 retain bounded real-launcher ownership slices plus
    # pure historical classification, inventory, and snapshot adapters.
    '$launcherPath|<script>' = 91
    '$historicalMutationCallCount|<script>' = 2
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
    '$script:GetQuickAdoptionHarnessGitBlobSha1|<script>' = 2
    '$script:GetQuickAdoptionHarnessGitBlobSha1|Get-TestQuickAdoptionGitBlobSha1' = 1
    '$script:ImportQuickAdoptionCapabilityCatalog|Copy-CanonicalProtocolFixture' = 1
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
    -Expected ([ordered]@{
        'Remove-Item|<script>' = 3
        'Remove-Item|Copy-ImmutableProtocolPolicyFixture' = 1
    }) `
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
}
Assert-ReviewedOperationInventory -Actual $bootstrapDynamicInvocations `
    -Expected $expectedBootstrapDynamicInvocations `
    -Label 'bootstrap dynamic invocation'
$bootstrapRecursiveCleanup =
    Get-ReviewedRecursiveCleanupInventory -Ast $bootstrapAst
Assert-ReviewedOperationInventory -Actual $bootstrapRecursiveCleanup `
    -Expected ([ordered]@{ 'Remove-Item|<script>' = 2 }) `
    -Label 'bootstrap recursive cleanup'
$bootstrapChildCases = @($bootstrapAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Invoke-BootstrapChildCase'
}, $true))
$expectedBootstrapChildParents = [ordered]@{
    'Get-FixtureInstructionGraphIdentity' = 1
    'Invoke-IsolatedGraphDriftFixture' = 1
    'Invoke-IsolatedGraphSuccessFixture' = 1
}
Assert-Equal $bootstrapChildCases.Count 3 `
    'TEST-0159 bootstrap child-Case call-site count differs.'
foreach ($entry in $expectedBootstrapChildParents.GetEnumerator()) {
    Assert-Equal @($bootstrapChildCases | Where-Object {
        (Get-ParentFunctionName -Node $_) -ceq [string]$entry.Key
    }).Count ([int]$entry.Value) `
        "TEST-0159 bootstrap child-Case count differs for '$($entry.Key)'."
}
$bootstrapProcessOwners = @($bootstrapAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Invoke-MeAndAITestCaseProcess'
}, $true))
Assert-Equal $bootstrapProcessOwners.Count 1 `
    'TEST-0159 bootstrap canonical child-process owner count differs.'
if ($bootstrapProcessOwners.Count -eq 1) {
    Assert-Equal (Get-ParentFunctionName -Node $bootstrapProcessOwners[0]) `
        'Invoke-BootstrapChildCase' `
        'TEST-0159 bootstrap child process escaped its canonical owner.'
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
    'Invoke-BootstrapChildCase',
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
    GraphChildProcess = 1
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
$operationAssertions = @($runnerAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq
        'Assert-MeAndAITestSuiteOperationEvidence'
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
Assert-Equal $operationAssertions.Count 1 `
    'TEST-0159 root runner operation assertion call count differs.'
Assert-Equal $scenarioReads.Count 1 `
    'TEST-0159 root runner scenario parser call count differs.'
Assert-Equal $compatibilityReads.Count 1 `
    'TEST-0159 root runner compatibility parser call count differs.'
if ($operationAssertions.Count -eq 1 -and $scenarioReads.Count -eq 1 -and
    $compatibilityReads.Count -eq 1) {
    Assert-True ($operationAssertions[0].Extent.StartOffset -lt
        $scenarioReads[0].Extent.StartOffset) `
        'TEST-0159 root runner parses scenario success before operation evidence.'
    Assert-True ($operationAssertions[0].Extent.StartOffset -lt
        $compatibilityReads[0].Extent.StartOffset) `
        'TEST-0159 root runner parses compatibility success before operation evidence.'
}
if ($failures.Count -eq $test0159FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0159'
}

$test0158FailureCount = $failures.Count
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
if ($failures.Count -eq $test0158FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0158'
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
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
Write-Host 'Test-runtime operation contracts passed.' -ForegroundColor Green
Write-Host $selfObservation
Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
    ($scenarioResult | ConvertTo-Json -Compress))
