$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/consumer-update/protocol-update-reliability.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$adapterPath = Join-Path $root `
    'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$nativeHelperPath = Join-Path $root `
    'tests/capabilities/consumer-update/fixtures/Invoke-MockProtocolUpdateGh.ps1'
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

function Assert-Equal {
    param($Expected, $Actual, [Parameter(Mandatory)][string]$Message)
    if ($Expected -cne $Actual) {
        Add-Failure "$Message; expected '$Expected', found '$Actual'"
    }
}

function Invoke-ExpectedFailure {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$MessagePattern,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    try {
        & $Action | Out-Null
    }
    catch {
        if ($_.Exception.Message -like $MessagePattern) {
            return $_.Exception.Message
        }
        Add-Failure "$FailureMessage; unexpected error: $($_.Exception.Message)"
        return $_.Exception.Message
    }
    Add-Failure "$FailureMessage; no error was thrown"
    return ''
}

if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) {
    Add-Failure 'TEST-0148 production protocol-update adapter is missing.'
}
if (-not (Test-Path -LiteralPath $nativeHelperPath -PathType Leaf)) {
    Add-Failure 'TEST-0149 real native GitHub CLI fixture is missing.'
}
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Host "FAIL: $failure" -ForegroundColor Red }
    exit 1
}

$tokens = $null
$parseErrors = $null
$adapterAst = [Management.Automation.Language.Parser]::ParseFile(
    $adapterPath, [ref]$tokens, [ref]$parseErrors
)
if (@($parseErrors).Count -ne 0) {
    Add-Failure "TEST-0148 production adapter does not parse: $($parseErrors[0].Message)"
}
$adapterContent = Get-Content -LiteralPath $adapterPath -Raw
$adapterFunctions = @($adapterAst.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst]
}, $true))

function Get-AdapterFunctionDefinition {
    param([Parameter(Mandatory)][string]$Name)

    $matches = @($adapterFunctions | Where-Object { $_.Name -ceq $Name })
    if ($matches.Count -ne 1) { return '' }
    return [string]$matches[0].Extent.Text
}

$requiredFunctions = @(
    'Invoke-Native',
    'Get-GhReadFailureClassification',
    'Invoke-GhReadNative',
    'Invoke-GhReadJson',
    'Invoke-GhPagedReadJson',
    'Invoke-GhJson',
    'Invoke-GhMutationWithBodyFile',
    'Invoke-GhPullRequestCreateWithBodyFile',
    'Get-ManagedUpdateIssueMarker',
    'Get-ManagedUpdateIssueContract',
    'Get-ManagedUpdateIssueInventory',
    'Test-ExactLegacyQuoteStrippedProtocolUpdateIssue',
    'Repair-LegacyQuoteStrippedProtocolUpdateIssue',
    'Ensure-ProtocolUpdateIssue'
)
$definitions = @{}
foreach ($name in $requiredFunctions) {
    $definition = Get-AdapterFunctionDefinition -Name $name
    if (-not $definition) {
        $testId = if ($name -like '*BodyFile*' -or
            $name -like '*LegacyQuoteStripped*') { 'TEST-0149' } else { 'TEST-0148' }
        Add-Failure "$testId production adapter is missing focused helper '$name'."
    }
    else { $definitions[$name] = $definition }
}

function Get-EnclosingAdapterFunctionName {
    param([Parameter(Mandatory)]$Node)

    $current = $Node.Parent
    while ($null -ne $current) {
        if ($current -is
            [Management.Automation.Language.FunctionDefinitionAst]) {
            return [string]$current.Name
        }
        $current = $current.Parent
    }
    return ''
}

$stringNodes = @($adapterAst.FindAll({
    param($node)
    $node -is [Management.Automation.Language.StringConstantExpressionAst] -or
        $node -is [Management.Automation.Language.ExpandableStringExpressionAst]
}, $true))
foreach ($node in $stringNodes) {
    $value = [string]$node.Value
    $functionName = Get-EnclosingAdapterFunctionName -Node $node
    if ($value -ceq '--body' -or $value -ceq '--input') {
        Add-Failure "TEST-0149 production adapter retains forbidden structured-body argv token '$value' in '$functionName'."
        continue
    }
    if ($value.StartsWith('body=', [StringComparison]::Ordinal)) {
        if ($functionName -cne 'Invoke-GhMutationWithBodyFile' -or
            ($value -cne 'body=' -and
                -not $value.StartsWith('body=@', [StringComparison]::Ordinal))) {
            Add-Failure "TEST-0149 production adapter constructs a structured body outside the safe REST body-file helper '$functionName'."
        }
        continue
    }
    if ($value -ceq '--body-file' -and
        $functionName -cne 'Invoke-GhPullRequestCreateWithBodyFile') {
        Add-Failure "TEST-0149 production adapter uses --body-file outside its cleanup-owning helper '$functionName'."
    }
}

if ($definitions.ContainsKey('Invoke-GhMutationWithBodyFile')) {
    $definition = [string]$definitions['Invoke-GhMutationWithBodyFile']
    if (-not [regex]::IsMatch(
            $definition, '["'']-F["'']\s*,\s*["'']body=@'
        )) {
        Add-Failure 'TEST-0149 REST body transport does not use a typed -F @file field.'
    }
}
if ($definitions.ContainsKey('Invoke-GhPullRequestCreateWithBodyFile')) {
    $definition = [string]$definitions['Invoke-GhPullRequestCreateWithBodyFile']
    if (-not $definition.Contains('--body-file')) {
        Add-Failure 'TEST-0149 pull-request creation does not use the native --body-file contract.'
    }
}
if ($definitions.ContainsKey('Ensure-ProtocolUpdateIssue')) {
    $definition = [string]$definitions['Ensure-ProtocolUpdateIssue']
    $repairIndex = $definition.IndexOf(
        'Repair-LegacyQuoteStrippedProtocolUpdateIssue',
        [StringComparison]::Ordinal
    )
    $labelsIndex = $definition.IndexOf(
        'Ensure-ManagedUpdateLabels', [StringComparison]::Ordinal
    )
    if ($repairIndex -lt 0 -or $labelsIndex -lt 0 -or
        $repairIndex -gt $labelsIndex) {
        Add-Failure 'TEST-0149 malformed-issue repair is not a preflight before label or issue mutation.'
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'Protocol-update reliability tests failed before execution:' -ForegroundColor Red
    foreach ($failure in $failures) { Write-Host " - $failure" -ForegroundColor Red }
    exit 1
}

# Load exact production helpers without executing the adapter's top-level lifecycle.
foreach ($name in $requiredFunctions) {
    . ([scriptblock]::Create([string]$definitions[$name]))
}

function Get-MockInvocationLog {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    return @(Get-Content -LiteralPath $Path | Where-Object { $_ } |
        ForEach-Object { $_ | ConvertFrom-Json })
}

function Reset-NativeMock {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Mode,
        [string]$FailureKind = '',
        [int]$FailuresBeforeSuccess = 0
    )

    $statePath = Join-Path $FixtureRoot 'state.txt'
    $logPath = Join-Path $FixtureRoot 'calls.jsonl'
    Remove-Item -LiteralPath $statePath, $logPath -Force -ErrorAction SilentlyContinue
    [Environment]::SetEnvironmentVariable('MEANDAI_TEST_GH_MODE', $Mode, 'Process')
    [Environment]::SetEnvironmentVariable(
        'MEANDAI_TEST_GH_FAILURE_KIND', $FailureKind, 'Process'
    )
    [Environment]::SetEnvironmentVariable(
        'MEANDAI_TEST_GH_FAILURES', [string]$FailuresBeforeSuccess, 'Process'
    )
    [Environment]::SetEnvironmentVariable('MEANDAI_TEST_GH_STATE', $statePath, 'Process')
    [Environment]::SetEnvironmentVariable('MEANDAI_TEST_GH_LOG', $logPath, 'Process')
    return [pscustomobject]@{ State = $statePath; Log = $logPath }
}

function Assert-MockCallsAreGetOnly {
    param(
        [Parameter(Mandatory)][object[]]$Invocation,
        [Parameter(Mandatory)][string]$Context
    )

    foreach ($call in $Invocation) {
        $arguments = @($call.arguments | ForEach-Object { [string]$_ })
        if ($arguments.Count -eq 0 -or $arguments[0] -cne 'api') {
            Add-Failure "TEST-0148 $Context left the explicit GitHub API read boundary."
            continue
        }
        $endpointCount = 0
        for ($index = 1; $index -lt $arguments.Count; $index++) {
            $argument = [string]$arguments[$index]
            if ($argument -cin @('--method', '-X')) {
                if ($index + 1 -ge $arguments.Count -or
                    [string]$arguments[$index + 1] -cne 'GET') {
                    Add-Failure "TEST-0148 $Context attempted a non-GET method."
                }
                $index++
                continue
            }
            if ($argument -cin @('-H', '--header')) {
                if ($index + 1 -ge $arguments.Count -or
                    [string]::IsNullOrWhiteSpace(
                        [string]$arguments[$index + 1]
                    )) {
                    Add-Failure "TEST-0148 $Context used an invalid read header."
                }
                $index++
                continue
            }
            if ($argument -ceq '--paginate') { continue }
            if ($argument -ceq '--jq') {
                if ($index + 1 -ge $arguments.Count -or
                    [string]$arguments[$index + 1] -cne '.[] | @base64') {
                    Add-Failure "TEST-0148 $Context used an unsafe pagination projection."
                }
                $index++
                continue
            }
            if ($argument.StartsWith('-', [StringComparison]::Ordinal) -or
                [string]::IsNullOrWhiteSpace($argument)) {
                Add-Failure "TEST-0148 $Context used forbidden read argument '$argument'."
                continue
            }
            $endpointCount++
        }
        if ($endpointCount -ne 1) {
            Add-Failure "TEST-0148 $Context did not contain exactly one GET endpoint."
        }
    }
}

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-adapter-reliability-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixtureRoot)
$originalPath = [Environment]::GetEnvironmentVariable('PATH', 'Process')
$originalToken = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')

try {
    $fakeBin = Join-Path $fixtureRoot 'bin'
    [void](New-Item -ItemType Directory -Path $fakeBin)
    $engine = [string](Get-Process -Id $PID).Path
    if ($env:OS -eq 'Windows_NT') {
        $wrapperPath = Join-Path $fakeBin 'gh.cmd'
        $wrapper = @(
            '@echo off',
            "`"$engine`" -NoProfile -ExecutionPolicy Bypass -File `"$nativeHelperPath`" %*",
            'exit /b %ERRORLEVEL%'
        ) -join "`r`n"
        [IO.File]::WriteAllText(
            $wrapperPath, ($wrapper + "`r`n"), [Text.ASCIIEncoding]::new()
        )
    }
    else {
        $wrapperPath = Join-Path $fakeBin 'gh'
        if ($engine.Contains("'") -or $nativeHelperPath.Contains("'")) {
            throw 'Native fixture paths cannot be represented safely by the shell wrapper.'
        }
        $wrapper = "#!/bin/sh`nexec '$engine' -NoProfile -File '$nativeHelperPath' `"`$@`"`n"
        [IO.File]::WriteAllText(
            $wrapperPath, $wrapper, [Text.UTF8Encoding]::new($false)
        )
        & chmod +x $wrapperPath
        if ($LASTEXITCODE -ne 0) { throw 'Unable to make fake gh executable.' }
    }
    [Environment]::SetEnvironmentVariable(
        'PATH', $fakeBin + [IO.Path]::PathSeparator + $originalPath, 'Process'
    )

    foreach ($kind in @(
        'Connectex', 'Timeout', 'Reset', 'Eof',
        '408', '429', '500', '502', '503', '599'
    )) {
        $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode Read `
            -FailureKind $kind -FailuresBeforeSuccess 1
        try {
            $result = Invoke-GhReadJson -Endpoint 'repos/owner/consumer'
            Assert-Equal 2 ([int]$result.attempt) `
                "TEST-0148 retryable '$kind' read did not converge on attempt two"
        }
        catch {
            Add-Failure "TEST-0148 retryable '$kind' read failed: $($_.Exception.Message)"
        }
        $readLog = @(Get-MockInvocationLog -Path $mock.Log)
        Assert-Equal 2 $readLog.Count `
            "TEST-0148 retryable '$kind' read used the wrong attempt count"
        Assert-MockCallsAreGetOnly -Invocation $readLog `
            -Context "retryable '$kind' read"
    }

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode Read `
        -FailureKind Timeout -FailuresBeforeSuccess 2
    try {
        $thirdAttemptResult = Invoke-GhReadJson `
            -Endpoint 'repos/owner/consumer'
        Assert-Equal 3 ([int]$thirdAttemptResult.attempt) `
            'TEST-0148 two transient failures did not converge on attempt three'
    }
    catch {
        Add-Failure "TEST-0148 attempt-three convergence failed: $($_.Exception.Message)"
    }
    $thirdAttemptLog = @(Get-MockInvocationLog -Path $mock.Log)
    Assert-Equal 3 $thirdAttemptLog.Count `
        'TEST-0148 attempt-three convergence used the wrong attempt count'
    Assert-MockCallsAreGetOnly -Invocation $thirdAttemptLog `
        -Context 'attempt-three convergence'

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode Read `
        -FailureKind Connectex -FailuresBeforeSuccess 9
    $exhaustionError = Invoke-ExpectedFailure -Action {
        Invoke-GhReadJson -Endpoint 'repos/owner/consumer'
    } -MessagePattern '*connectex*' `
        -FailureMessage 'TEST-0148 exhausted transient read did not preserve its final diagnostic'
    $exhaustedLog = @(Get-MockInvocationLog -Path $mock.Log)
    Assert-Equal 3 $exhaustedLog.Count `
        'TEST-0148 exhausted transient read did not stop at three total attempts'
    if ($exhaustedLog.Count -eq 3) {
        $firstGapMs = ([long]$exhaustedLog[1].utcTicks -
            [long]$exhaustedLog[0].utcTicks) / [TimeSpan]::TicksPerMillisecond
        $secondGapMs = ([long]$exhaustedLog[2].utcTicks -
            [long]$exhaustedLog[1].utcTicks) / [TimeSpan]::TicksPerMillisecond
        if ($firstGapMs -lt 200 -or $secondGapMs -lt 450) {
            Add-Failure "TEST-0148 retry backoff did not preserve the bounded 250/500 ms schedule: $firstGapMs/$secondGapMs ms."
        }
    }
    if ($exhaustionError -notlike '*attempt*3*') {
        Add-Failure 'TEST-0148 exhausted transient diagnostic does not report the three-attempt boundary.'
    }

    foreach ($kind in @('401', '403', '404', '422')) {
        $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode Read `
            -FailureKind $kind -FailuresBeforeSuccess 9
        [void](Invoke-ExpectedFailure -Action {
            Invoke-GhReadJson -Endpoint 'repos/owner/consumer'
        } -MessagePattern "*$kind*" `
            -FailureMessage "TEST-0148 permanent HTTP $kind read was not rejected")
        Assert-Equal 1 @(Get-MockInvocationLog -Path $mock.Log).Count `
            "TEST-0148 permanent HTTP $kind read was retried"
    }

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode InvalidJson
    [void](Invoke-ExpectedFailure -Action {
        Invoke-GhReadJson -Endpoint 'repos/owner/consumer'
    } -MessagePattern '*' `
        -FailureMessage 'TEST-0148 invalid successful JSON was accepted')
    Assert-Equal 1 @(Get-MockInvocationLog -Path $mock.Log).Count `
        'TEST-0148 semantic JSON failure was retried'

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode Paged `
        -FailureKind Reset -FailuresBeforeSuccess 1
    try {
        $paged = @(Invoke-GhPagedReadJson `
            -Endpoint 'repos/owner/consumer/issues?per_page=100')
        Assert-Equal 2 $paged.Count `
            'TEST-0148 paged retry retained partial output from a failed attempt'
        Assert-Equal '1,2' (@($paged | ForEach-Object { [string]$_.id }) -join ',') `
            'TEST-0148 paged retry did not restart as one clean attempt'
    }
    catch {
        Add-Failure "TEST-0148 paged retry failed unexpectedly: $($_.Exception.Message)"
    }
    Assert-Equal 2 @(Get-MockInvocationLog -Path $mock.Log).Count `
        'TEST-0148 paged transient read used the wrong attempt count'
    Assert-MockCallsAreGetOnly `
        -Invocation @(Get-MockInvocationLog -Path $mock.Log) `
        -Context 'paged transient read'

    $unicodeText = -join @(
        [char]0x011F, [char]0x00FC, [char]0x015F,
        [char]0x0069, [char]0x00F6, [char]0x00E7
    )
    $canonicalBody = @(
        '<!-- meandai-protocol-update-issue:{"schema":2,"kind":"update"} -->',
        "JSON must keep `"quotes`", Unicode: $unicodeText, and line breaks.",
        'Last line.'
    ) -join [Environment]::NewLine
    $expectedBodyBytes = [Text.UTF8Encoding]::new($false).GetBytes($canonicalBody)

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode Mutation
    try {
        [void](Invoke-GhMutationWithBodyFile -Method POST `
            -Endpoint 'repos/owner/consumer/issues' -Body $canonicalBody `
            -Fields @('title=TEST-0149', 'labels[]=type:task'))
    }
    catch {
        Add-Failure "TEST-0149 REST body-file mutation failed: $($_.Exception.Message)"
    }
    $mutationLog = @(Get-MockInvocationLog -Path $mock.Log)
    Assert-Equal 1 $mutationLog.Count `
        'TEST-0149 REST body-file mutation used the wrong native call count'
    if ($mutationLog.Count -eq 1) {
        $call = $mutationLog[0]
        $actualBytes = [Convert]::FromBase64String([string]$call.bodyBase64)
        if ([Convert]::ToBase64String($actualBytes) -cne
            [Convert]::ToBase64String($expectedBodyBytes)) {
            Add-Failure 'TEST-0149 REST structured body did not cross the native boundary byte-for-byte.'
        }
        if ([bool]$call.bodyHasBom) {
            Add-Failure 'TEST-0149 REST structured body transport added a UTF-8 BOM.'
        }
        if ([string]$call.bodyMode -cne 'RestField') {
            Add-Failure 'TEST-0149 REST structured body did not use -F immediately before body=@file.'
        }
        if (-not [string]$call.bodyPath -or
            (Test-Path -LiteralPath ([string]$call.bodyPath))) {
            Add-Failure 'TEST-0149 REST body transport file was not removed after success.'
        }
        $argv = @($call.arguments | ForEach-Object { [string]$_ })
        if ($argv -contains $canonicalBody -or
            @($argv | Where-Object {
                $_.StartsWith('body=', [StringComparison]::Ordinal) -and
                -not $_.StartsWith('body=@', [StringComparison]::Ordinal)
            }).Count -ne 0) {
            Add-Failure 'TEST-0149 REST structured body leaked onto native argv.'
        }
    }

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode MutationFailure
    [void](Invoke-ExpectedFailure -Action {
        Invoke-GhMutationWithBodyFile -Method PATCH `
            -Endpoint 'repos/owner/consumer/issues/7' -Body $canonicalBody
    } -MessagePattern '*PermanentMutation*' `
        -FailureMessage 'TEST-0148 mutation failure did not surface once')
    $failedMutationLog = @(Get-MockInvocationLog -Path $mock.Log)
    Assert-Equal 1 $failedMutationLog.Count `
        'TEST-0148 a failed mutation was automatically retried'
    if ($failedMutationLog.Count -eq 1 -and
        (Test-Path -LiteralPath ([string]$failedMutationLog[0].bodyPath))) {
        Add-Failure 'TEST-0149 REST body transport file was not removed after failure.'
    }

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode MutationFailure
    [void](Invoke-ExpectedFailure -Action {
        Invoke-GhJson -Arguments @(
            'api', '--method', 'DELETE',
            'repos/owner/consumer/git/refs/heads/test-branch'
        )
    } -MessagePattern '*PermanentMutation*' `
        -FailureMessage 'TEST-0148 DELETE mutation failure did not surface once')
    Assert-Equal 1 @(Get-MockInvocationLog -Path $mock.Log).Count `
        'TEST-0148 a failed DELETE mutation was automatically retried'

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot -Mode PullRequest
    try {
        $url = Invoke-GhPullRequestCreateWithBodyFile -Base main `
            -Head automation/meandai-protocol-v0.12.1-recovery `
            -Title 'Upgrade protocol' -Body $canonicalBody
        Assert-Equal 'https://github.com/owner/consumer/pull/123' `
            ([string]$url).Trim() `
            'TEST-0149 pull-request body-file helper changed native output'
    }
    catch {
        Add-Failure "TEST-0149 pull-request body-file creation failed: $($_.Exception.Message)"
    }
    $pullLog = @(Get-MockInvocationLog -Path $mock.Log)
    Assert-Equal 1 $pullLog.Count `
        'TEST-0149 pull-request body-file helper used the wrong native call count'
    if ($pullLog.Count -eq 1) {
        $call = $pullLog[0]
        $actualBytes = [Convert]::FromBase64String([string]$call.bodyBase64)
        if ([Convert]::ToBase64String($actualBytes) -cne
            [Convert]::ToBase64String($expectedBodyBytes)) {
            Add-Failure 'TEST-0149 pull-request body did not cross the native boundary byte-for-byte.'
        }
        $argv = @($call.arguments | ForEach-Object { [string]$_ })
        if ($argv -contains $canonicalBody -or $argv -notcontains '--body-file') {
            Add-Failure 'TEST-0149 pull-request structured body was not isolated behind --body-file.'
        }
        if ([string]$call.bodyMode -cne 'PullRequestBodyFile') {
            Add-Failure 'TEST-0149 pull-request body was not read from --body-file.'
        }
        if ([bool]$call.bodyHasBom -or
            (Test-Path -LiteralPath ([string]$call.bodyPath))) {
            Add-Failure 'TEST-0149 pull-request body transport was BOM-prefixed or not cleaned.'
        }
    }

    $mock = Reset-NativeMock -FixtureRoot $fixtureRoot `
        -Mode PullRequestFailure
    [void](Invoke-ExpectedFailure -Action {
        Invoke-GhPullRequestCreateWithBodyFile -Base main `
            -Head automation/meandai-protocol-v0.12.1-recovery `
            -Title 'Upgrade protocol' -Body $canonicalBody
    } -MessagePattern '*PermanentPullRequest*' `
        -FailureMessage 'TEST-0149 pull-request body-file failure did not surface')
    $failedPullLog = @(Get-MockInvocationLog -Path $mock.Log)
    Assert-Equal 1 $failedPullLog.Count `
        'TEST-0149 a failed pull-request creation was automatically retried'
    if ($failedPullLog.Count -eq 1) {
        if ([string]$failedPullLog[0].bodyMode -cne 'PullRequestBodyFile' -or
            (Test-Path -LiteralPath ([string]$failedPullLog[0].bodyPath))) {
            Add-Failure 'TEST-0149 pull-request body transport file was not cleaned after failure.'
        }
    }
}
catch {
    Add-Failure "TEST-0148 native-boundary fixture failed unexpectedly: $($_.Exception.Message)"
}
finally {
    [Environment]::SetEnvironmentVariable('PATH', $originalPath, 'Process')
    [Environment]::SetEnvironmentVariable('GH_TOKEN', $originalToken, 'Process')
    foreach ($name in @(
        'MEANDAI_TEST_GH_MODE', 'MEANDAI_TEST_GH_FAILURE_KIND',
        'MEANDAI_TEST_GH_FAILURES', 'MEANDAI_TEST_GH_STATE',
        'MEANDAI_TEST_GH_LOG'
    )) {
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

# Replace only the live GitHub boundaries; the repair logic remains the exact
# production function extracted above.
$script:RepairState = $null
function Get-RemoteBranchHead {
    param([string]$Branch)
    if ($Branch -cne $script:RepairState.Branch) {
        throw "Unexpected repair branch lookup '$Branch'."
    }
    [void]($script:RepairState.BranchLookupCount++)
    return $script:RepairState.BranchHead
}
function Invoke-GhReadJson {
    param([string]$Endpoint, [AllowNull()][string]$Token = $null)
    $script:RepairState.ReadEndpoints.Add($Endpoint)
    if ($Endpoint -ceq "repos/$($script:RepairState.Repository)") {
        return [pscustomobject]@{ full_name = $script:RepairState.LiveRepository }
    }
    if ($Endpoint -ceq (
            "repos/$($script:RepairState.Repository)/issues/" +
            [string]$script:RepairState.Issue.number
        )) {
        [void]($script:RepairState.RefetchCount++)
        $script:RepairState.Events.Add('read-issue')
        return $script:RepairState.Issue
    }
    throw "Unexpected repair JSON endpoint '$Endpoint'."
}
function Invoke-GhPagedReadJson {
    param([string]$Endpoint, [AllowNull()][string]$Token = $null)
    $script:RepairState.ReadEndpoints.Add($Endpoint)
    if ($Endpoint.StartsWith(
            "repos/$($script:RepairState.Repository)/issues/",
            [StringComparison]::Ordinal
        ) -and $Endpoint.Contains('/comments?')) {
        return @($script:RepairState.Comments)
    }
    if ($Endpoint.StartsWith(
            "repos/$($script:RepairState.Repository)/issues?",
            [StringComparison]::Ordinal
        )) {
        return @($script:RepairState.Issues)
    }
    if ($Endpoint.StartsWith(
            "repos/$($script:RepairState.Repository)/pulls?",
            [StringComparison]::Ordinal
        )) {
        return @($script:RepairState.Pulls)
    }
    throw "Unexpected repair paged endpoint '$Endpoint'."
}
function Invoke-GhMutationWithBodyFile {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Body,
        [string[]]$Fields = @(),
        [AllowNull()][string]$Token = $null
    )
    [void]($script:RepairState.MutationCount++)
    $script:RepairState.Events.Add('patch')
    $script:RepairState.PatchedBody = $Body
    if ($Method -cne 'PATCH' -or
        $Endpoint -cne (
            "repos/$($script:RepairState.Repository)/issues/" +
            [string]$script:RepairState.Issue.number
        )) {
        throw "Unexpected repair mutation '$Method $Endpoint'."
    }
    $storedBody = if ($null -ne $script:RepairState.PostPatchBody) {
        [string]$script:RepairState.PostPatchBody
    }
    else { $Body }
    $script:RepairState.Issue.body = $storedBody
    foreach ($inventoryIssue in $script:RepairState.Issues) {
        if ([int]$inventoryIssue.number -eq
            [int]$script:RepairState.Issue.number) {
            $inventoryIssue.body = $storedBody
        }
    }
    return $script:RepairState.Issue
}

$repository = 'owner/consumer'
$script:CurrentLauncher = $true
$targetTag = 'v0.12.1'
$protocolSha = 'c1e70901749d7c34a747b765134f668232b9d2ca'
$migrationPlanSha = '7e582674f9c6b771b0a06fcf17cd1c7b55ac4b02d1c732b1cd14901ced0aa7f2'
$branch = 'automation/meandai-protocol-v0.12.1-recovery'
$trustedActor = 'owner'
$contract = Get-ManagedUpdateIssueContract -Repository $repository `
    -TargetTag $targetTag -ProtocolSha $protocolSha -Branch $branch `
    -ProposalKind Update -MigrationPlanSha $migrationPlanSha
$poisonedBody = $contract.Body.Replace('"', '')

function New-RepairIssue {
    param(
        [int]$Number = 7,
        [string]$Title = $contract.Title,
        [string]$Body = $poisonedBody,
        [string]$Author = $trustedActor,
        [string]$State = 'open',
        [switch]$PullRequest
    )
    $issue = [pscustomobject][ordered]@{
        number = $Number
        title = $Title
        body = $Body
        state = $State
        user = [pscustomobject]@{ login = $Author }
    }
    if ($PullRequest) {
        $issue | Add-Member -NotePropertyName pull_request `
            -NotePropertyValue ([pscustomobject]@{ url = 'https://example.invalid' })
    }
    return $issue
}

function Copy-RepairIssue {
    param([Parameter(Mandatory)]$Issue)
    return ($Issue | ConvertTo-Json -Depth 8 -Compress | ConvertFrom-Json)
}

function New-RepairState {
    param(
        [object[]]$Issues = @((New-RepairIssue)),
        [AllowNull()][object]$RefetchedIssue = $null,
        [AllowNull()][object]$PostPatchBody = $null,
        [AllowNull()][object]$BranchHead = $null,
        [object[]]$Pulls = @(),
        [object[]]$Comments = @(),
        [string]$LiveRepository = $repository
    )
    $primary = if ($Issues.Count -gt 0) { $Issues[0] } else { New-RepairIssue }
    $liveIssue = if ($null -ne $RefetchedIssue) {
        Copy-RepairIssue -Issue $RefetchedIssue
    }
    else { Copy-RepairIssue -Issue $primary }
    return [pscustomobject]@{
        Repository = $repository
        LiveRepository = $LiveRepository
        Branch = $branch
        BranchHead = $BranchHead
        Pulls = @($Pulls)
        Comments = @($Comments)
        Issues = @($Issues)
        Issue = $liveIssue
        PostPatchBody = $PostPatchBody
        MutationCount = 0
        PatchedBody = ''
        RefetchCount = 0
        BranchLookupCount = 0
        ReadEndpoints = [System.Collections.Generic.List[string]]::new()
        Events = [System.Collections.Generic.List[string]]::new()
    }
}

$exactIssue = New-RepairIssue
$exactPredicate = Test-ExactLegacyQuoteStrippedProtocolUpdateIssue `
    -Issue $exactIssue -Contract $contract -Repository $repository `
    -TrustedActor $trustedActor
if ($exactPredicate -isnot [bool] -or -not [bool]$exactPredicate) {
    Add-Failure 'TEST-0149 pure repair predicate rejected the exact historical quote-stripped issue.'
}
foreach ($nearIssue in @(
    (New-RepairIssue -Title ($contract.Title + ' drift')),
    (New-RepairIssue -Body ($poisonedBody + [Environment]::NewLine + 'drift')),
    (New-RepairIssue -Author 'foreign-owner'),
    (New-RepairIssue -State closed),
    (New-RepairIssue -PullRequest)
)) {
    $nearPredicate = Test-ExactLegacyQuoteStrippedProtocolUpdateIssue `
        -Issue $nearIssue -Contract $contract -Repository $repository `
        -TrustedActor $trustedActor
    if ($nearPredicate -isnot [bool] -or [bool]$nearPredicate) {
        Add-Failure 'TEST-0149 pure repair predicate accepted a changed title, prose, actor, state, or issue type.'
    }
}

$script:RepairState = New-RepairState
try {
    $repaired = Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $repository -TargetTag $targetTag `
        -ProtocolSha $protocolSha -Branch $branch -ProposalKind Update `
        -MigrationPlanSha $migrationPlanSha -TrustedActor $trustedActor
    if ($repaired -isnot [bool] -or -not [bool]$repaired) {
        Add-Failure 'TEST-0149 exact historical quote-stripped issue was not repaired.'
    }
}
catch {
    Add-Failure "TEST-0149 exact historical issue repair failed: $($_.Exception.Message)"
}
Assert-Equal 1 $script:RepairState.MutationCount `
    'TEST-0149 exact historical issue repair did not perform one PATCH'
Assert-Equal $contract.Body $script:RepairState.PatchedBody `
    'TEST-0149 exact historical issue repair did not replace the complete canonical body'
if ($script:RepairState.RefetchCount -lt 2) {
    Add-Failure 'TEST-0149 exact historical issue repair did not refetch before and after PATCH.'
}
$firstRefetch = $script:RepairState.Events.IndexOf('read-issue')
$patchEvent = $script:RepairState.Events.IndexOf('patch')
$lastRefetch = $script:RepairState.Events.LastIndexOf('read-issue')
if ($firstRefetch -lt 0 -or $patchEvent -le $firstRefetch -or
    $lastRefetch -le $patchEvent) {
    Add-Failure 'TEST-0149 exact historical issue repair did not bracket PATCH with fresh refetches.'
}
if ($script:RepairState.BranchLookupCount -lt 1) {
    Add-Failure 'TEST-0149 exact historical issue repair did not prove the reserved branch absent.'
}
if (-not $script:RepairState.ReadEndpoints.Contains("repos/$repository")) {
    Add-Failure 'TEST-0149 exact historical issue repair omitted the repository-identity read.'
}
$issueInventoryReads = @($script:RepairState.ReadEndpoints | Where-Object {
    $_.StartsWith("repos/$repository/issues?", [StringComparison]::Ordinal) -and
    $_.Contains('state=all') -and $_.Contains('per_page=100')
})
if ($issueInventoryReads.Count -eq 0) {
    Add-Failure 'TEST-0149 exact historical issue repair omitted the all-state issue inventory.'
}
$pullInventoryReads = @($script:RepairState.ReadEndpoints | Where-Object {
    $_.StartsWith("repos/$repository/pulls?", [StringComparison]::Ordinal) -and
    $_.Contains('state=all') -and $_.Contains("head=owner`:$branch") -and
    $_.Contains('per_page=100')
})
if ($pullInventoryReads.Count -eq 0) {
    Add-Failure 'TEST-0149 exact historical issue repair omitted the all-state exact-head pull-request proof.'
}
$commentReads = @($script:RepairState.ReadEndpoints | Where-Object {
    $_.StartsWith(
        "repos/$repository/issues/7/comments?", [StringComparison]::Ordinal
    ) -and $_.Contains('per_page=100')
})
if ($commentReads.Count -eq 0) {
    Add-Failure 'TEST-0149 exact historical issue repair omitted the managed-backlink comment proof.'
}
try {
    $canonicalMarker = Get-ManagedUpdateIssueMarker `
        -Body ([string]$script:RepairState.Issue.body)
    Assert-Equal $contract.Marker $canonicalMarker.CanonicalLine `
        'TEST-0149 repaired issue did not converge through the canonical parser'
}
catch {
    Add-Failure "TEST-0149 repaired issue failed canonical parsing: $($_.Exception.Message)"
}

$mutationCountBeforeRerun = $script:RepairState.MutationCount
try {
    $rerunResult = Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $repository -TargetTag $targetTag `
        -ProtocolSha $protocolSha -Branch $branch -ProposalKind Update `
        -MigrationPlanSha $migrationPlanSha -TrustedActor $trustedActor
    if ($rerunResult -isnot [bool] -or [bool]$rerunResult -or
        $script:RepairState.MutationCount -ne $mutationCountBeforeRerun) {
        Add-Failure 'TEST-0149 canonical second repair call was not an exact no-op.'
    }
}
catch {
    Add-Failure "TEST-0149 canonical second repair call failed: $($_.Exception.Message)"
}

$script:RepairState = New-RepairState
try {
    $staleRepaired = Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $repository -TargetTag 'v0.12.4' `
        -ProtocolSha ('b' * 40) `
        -Branch 'automation/meandai-protocol-v0.12.4-recovery' `
        -ProposalKind Update -MigrationPlanSha ('c' * 64) `
        -TrustedActor $trustedActor
    if ($staleRepaired -isnot [bool] -or -not [bool]$staleRepaired -or
        $script:RepairState.MutationCount -ne 1 -or
        $script:RepairState.PatchedBody -cne $contract.Body) {
        Add-Failure 'TEST-0149 a stale exact poisoned issue did not repair before a newer target contract.'
    }
}
catch {
    Add-Failure "TEST-0149 stale exact poisoned issue repair failed: $($_.Exception.Message)"
}

$prePatchDriftIssue = New-RepairIssue `
    -Body ($poisonedBody + [Environment]::NewLine + 'refetch drift')
$script:RepairState = New-RepairState -Issues @((New-RepairIssue)) `
    -RefetchedIssue $prePatchDriftIssue
[void](Invoke-ExpectedFailure -Action {
    Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $repository -TargetTag $targetTag `
        -ProtocolSha $protocolSha -Branch $branch -ProposalKind Update `
        -MigrationPlanSha $migrationPlanSha -TrustedActor $trustedActor
} -MessagePattern '*' `
    -FailureMessage 'TEST-0149 issue drift on the fresh pre-PATCH refetch was accepted')
Assert-Equal 0 $script:RepairState.MutationCount `
    'TEST-0149 issue drift on the fresh pre-PATCH refetch reached mutation'

$postPatchDriftBody = $contract.Body + [Environment]::NewLine + 'post-PATCH drift'
$script:RepairState = New-RepairState -PostPatchBody $postPatchDriftBody
[void](Invoke-ExpectedFailure -Action {
    Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $repository -TargetTag $targetTag `
        -ProtocolSha $protocolSha -Branch $branch -ProposalKind Update `
        -MigrationPlanSha $migrationPlanSha -TrustedActor $trustedActor
} -MessagePattern '*' `
    -FailureMessage 'TEST-0149 issue drift on the post-PATCH refetch was accepted')
Assert-Equal 1 $script:RepairState.MutationCount `
    'TEST-0149 post-PATCH drift fixture did not reach exactly one repair mutation'
if ($script:RepairState.Events.LastIndexOf('read-issue') -le
    $script:RepairState.Events.IndexOf('patch')) {
    Add-Failure 'TEST-0149 post-PATCH drift was not observed through a final refetch.'
}

$noPoison = New-RepairIssue -Body 'Ordinary maintainer issue.' -Title 'Ordinary issue'
$script:RepairState = New-RepairState -Issues @($noPoison)
try {
    $repaired = Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $repository -TargetTag $targetTag `
        -ProtocolSha $protocolSha -Branch $branch -ProposalKind Update `
        -MigrationPlanSha $migrationPlanSha -TrustedActor $trustedActor
    if ($repaired -isnot [bool] -or [bool]$repaired -or
        $script:RepairState.MutationCount -ne 0) {
        Add-Failure 'TEST-0149 repair mutated or claimed an unrelated issue.'
    }
}
catch {
    Add-Failure "TEST-0149 unrelated issue did not remain a no-op: $($_.Exception.Message)"
}

$caseVariantBranchContract = Get-ManagedUpdateIssueContract `
    -Repository $repository -TargetTag $targetTag -ProtocolSha $protocolSha `
    -Branch 'Automation/meandai-protocol-v0.12.1-recovery' `
    -ProposalKind Update -MigrationPlanSha $migrationPlanSha

$nearMatchCases = @(
    [pscustomobject]@{
        Name = 'changed marker field'
        State = New-RepairState -Issues @((New-RepairIssue `
            -Body ($poisonedBody.Replace($targetTag, 'v0.12.2'))))
    },
    [pscustomobject]@{
        Name = 'changed prose'
        State = New-RepairState -Issues @((New-RepairIssue `
            -Body ($poisonedBody.Replace(
                'This issue is the canonical same-repository work record',
                'This issue is a changed work record'
            ))))
    },
    [pscustomobject]@{
        Name = 'case-variant reserved branch'
        State = New-RepairState -Issues @((New-RepairIssue `
            -Body $caseVariantBranchContract.Body.Replace('"', '')))
    },
    [pscustomobject]@{
        Name = 'foreign actor'
        State = New-RepairState -Issues @((New-RepairIssue -Author foreign))
    },
    [pscustomobject]@{
        Name = 'duplicate poison'
        State = New-RepairState -Issues @(
            (New-RepairIssue -Number 7), (New-RepairIssue -Number 8)
        )
    },
    [pscustomobject]@{
        Name = 'canonical duplicate'
        State = New-RepairState -Issues @(
            (New-RepairIssue -Number 7),
            (New-RepairIssue -Number 8 -Body $contract.Body)
        )
    },
    [pscustomobject]@{
        Name = 'reserved branch exists'
        State = New-RepairState -BranchHead ('b' * 40)
    },
    [pscustomobject]@{
        Name = 'paired pull request exists'
        State = New-RepairState -Pulls @([pscustomobject]@{ number = 6 })
    },
    [pscustomobject]@{
        Name = 'managed backlink exists'
        State = New-RepairState -Comments @([pscustomobject]@{
            body = '<!-- meandai-protocol-update-proposal:pr-6:head-' +
                ('a' * 40) + ' -->'
        })
    },
    [pscustomobject]@{
        Name = 'repository identity changed'
        State = New-RepairState -LiveRepository 'owner/redirected'
    },
    [pscustomobject]@{
        Name = 'closed poisoned issue'
        State = New-RepairState -Issues @((New-RepairIssue -State closed))
    }
)

foreach ($case in $nearMatchCases) {
    $script:RepairState = $case.State
    [void](Invoke-ExpectedFailure -Action {
        Repair-LegacyQuoteStrippedProtocolUpdateIssue `
            -Repository $repository -TargetTag $targetTag `
            -ProtocolSha $protocolSha -Branch $branch -ProposalKind Update `
            -MigrationPlanSha $migrationPlanSha -TrustedActor $trustedActor
    } -MessagePattern '*' `
        -FailureMessage "TEST-0149 managed-looking near match '$($case.Name)' did not fail closed")
    Assert-Equal 0 $script:RepairState.MutationCount `
        "TEST-0149 managed-looking near match '$($case.Name)' reached mutation"
}

if ($failures.Count -gt 0) {
    Write-Host "Protocol-update reliability tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    foreach ($failure in $failures) { Write-Host " - $failure" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0148'
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0149'
$scenarioResult = New-MeAndAIScenarioResult -Owner $owner `
    -SourcePaths @($PSCommandPath, $nativeHelperPath) `
    -AuthorityPath $scenarioAuthorityPath
Write-Output ('MEANDAI_SCENARIO_RESULTS=' + `
    ($scenarioResult | ConvertTo-Json -Compress))
