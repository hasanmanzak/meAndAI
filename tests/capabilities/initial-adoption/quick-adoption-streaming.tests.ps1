[CmdletBinding()]
param(
    [ValidateSet('All', 'WindowsNative')]
    [string]$Shard = 'All'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$launcherSourcePaths = @(
    'scripts/quick-adoption/Private/OutputAndNativeProcess.ps1',
    'scripts/quick-adoption/Private/CodexRuntime.ps1',
    'scripts/quick-adoption/Private/CompletionAndPublication.ps1',
    'scripts/quick-adoption/Public/Invoke-MeAndAIQuickAdoption.ps1'
) | ForEach-Object {
    Join-Path $root ($_ -replace '/', [IO.Path]::DirectorySeparatorChar)
}
$fixturePath = Join-Path $root 'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodexEventProcess.ps1'
$owner = 'tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $scenarioAuthorityPath
$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures

if ($Shard -ceq 'WindowsNative' -and $env:OS -cne 'Windows_NT') {
    throw 'WindowsNative streaming compatibility requires Windows.'
}

function ConvertTo-SingleQuotedLiteral {
    param([Parameter(Mandatory)][string]$Value)

    return "'" + $Value.Replace("'", "''") + "'"
}

function Test-OwnedProcessAlive {
    param([int]$ProcessId)

    if ($ProcessId -le 0) {
        return $false
    }
    try {
        $process = [Diagnostics.Process]::GetProcessById($ProcessId)
        try { return -not $process.HasExited }
        finally { $process.Dispose() }
    }
    catch {
        return $false
    }
}

$test0105FailureCount = $failures.Count
$test0106FailureCount = $failures.Count
foreach ($launcherSourcePath in $launcherSourcePaths) {
    if (-not (Test-Path -LiteralPath $launcherSourcePath -PathType Leaf)) {
        Add-Failure "TEST-0105 launcher source is missing: $launcherSourcePath"
    }
}
if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf)) {
    Add-Failure 'TEST-0106 process/event fixture is missing.'
}

$launcher = @($launcherSourcePaths | Where-Object {
    Test-Path -LiteralPath $_ -PathType Leaf
} | ForEach-Object {
    Get-Content -LiteralPath $_ -Raw
}) -join [Environment]::NewLine
$tokens = $null
$parseErrors = $null
$launcherAst = [Management.Automation.Language.Parser]::ParseInput(
    $launcher, [ref]$tokens, [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    Add-Failure "TEST-0105 launcher parse failed: $($parseErrors -join '; ')"
}

function Get-LauncherFunctionText {
    param([Parameter(Mandatory)][string]$Name)

    $matches = @($launcherAst.FindAll({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq $Name
    }, $true))
    if ($matches.Count -ne 1) {
        Add-Failure "TEST-0105/TEST-0106 launcher function '$Name' is missing or ambiguous."
        return ''
    }
    return [string]$matches[0].Extent.Text
}

$functionNames = @(
    'ConvertTo-QuickAdoptionDisplayText',
    'Write-QuickAdoptionLine',
    'Set-QuickAdoptionProgress',
    'Set-QuickAdoptionChildProgress',
    'Complete-QuickAdoptionChildProgress',
    'Complete-QuickAdoptionProgress',
    'Get-QuickAdoptionObjectProperty',
    'Get-QuickAdoptionCommandIdentity',
    'Write-LocalCodexEvent',
    'ConvertTo-ProcessArgument',
    'New-ExternalProcessContainment',
    'Stop-ExternalProcessTree',
    'Invoke-BoundedProcess',
    'Invoke-LocalCodexExec',
    'Complete-AdoptionWithLocalCodex'
)
$functionText = @{}
foreach ($name in $functionNames) {
    $functionText[$name] = Get-LauncherFunctionText -Name $name
}

$writeProgressCalls = @($launcherAst.FindAll({
    param($node)
    $node -is [Management.Automation.Language.CommandAst] -and
    $node.GetCommandName() -ceq 'Write-Progress'
}, $true))
if ($writeProgressCalls.Count -ne 0) {
    Add-Failure 'TEST-0105 launcher still invokes the host-overlay Write-Progress renderer.'
}

$execText = [string]$functionText['Invoke-LocalCodexExec']
if (-not $execText.Contains("'--json'") -or
    -not $execText.Contains('Write-LocalCodexEvent') -or
    -not $execText.Contains('OutputLineHandler')) {
    Add-Failure 'TEST-0105 semantic Codex execution does not bind --json to its incremental event consumer.'
}
$boundedText = [string]$functionText['Invoke-BoundedProcess']
if (-not $boundedText.Contains('ReadLineAsync') -or
    -not $boundedText.Contains('OutputLineHandler')) {
    Add-Failure 'TEST-0105 bounded process execution does not consume stdout lines while the child is active.'
}
$stopIndex = $boundedText.LastIndexOf(
    'Stop-ExternalProcessTree', [StringComparison]::Ordinal
)
$disposeIndex = $boundedText.LastIndexOf('.Dispose()', [StringComparison]::Ordinal)
if ($stopIndex -lt 0 -or $disposeIndex -lt 0 -or $stopIndex -gt $disposeIndex) {
    Add-Failure 'TEST-0106 bounded-process finalization does not stop the active child tree before disposal.'
}
$completionText = [string]$functionText['Complete-AdoptionWithLocalCodex']
if ($completionText.IndexOf('Invoke-AdoptionCodexCompletion', [StringComparison]::Ordinal) -lt 0 -or
    $completionText.LastIndexOf('Remove-Item', [StringComparison]::Ordinal) -lt 0 -or
    $completionText.LastIndexOf('finally', [StringComparison]::Ordinal) -lt 0) {
    Add-Failure 'TEST-0106 adoption completion does not retain its owned temporary-root cleanup boundary.'
}

$runtimeDefinitions = @(
    'ConvertTo-QuickAdoptionDisplayText',
    'Write-QuickAdoptionLine',
    'Set-QuickAdoptionProgress',
    'Set-QuickAdoptionChildProgress',
    'Complete-QuickAdoptionChildProgress',
    'Complete-QuickAdoptionProgress',
    'Get-QuickAdoptionObjectProperty',
    'Get-QuickAdoptionCommandIdentity',
    'Write-LocalCodexEvent',
    'ConvertTo-ProcessArgument',
    'New-ExternalProcessContainment',
    'Stop-ExternalProcessTree',
    'Invoke-BoundedProcess'
)
$runtimeReady = @($runtimeDefinitions | Where-Object {
    [string]::IsNullOrWhiteSpace([string]$functionText[$_])
}).Count -eq 0

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-stream-test-$([guid]::NewGuid().ToString('N'))"
$ackPath = Join-Path $tempRoot 'stream-ack.txt'
$parentPidPath = Join-Path $tempRoot 'parent.pid'
$childPidPath = Join-Path $tempRoot 'child.pid'
$ownedCancellationRoot = Join-Path $tempRoot 'owned-cancellation-root'
$ownedParentPid = 0
$ownedChildPid = 0

try {
    [IO.Directory]::CreateDirectory($tempRoot) | Out-Null
    if ($runtimeReady) {
        foreach ($name in $runtimeDefinitions) {
            . ([scriptblock]::Create([string]$functionText[$name]))
        }

        $script:QuickAdoptionProgressEnabled = $true
        $script:QuickAdoptionLastProgressKey = ''
        $script:QuickAdoptionLastChildKey = ''
        $phaseOutput = @(& {
            Set-QuickAdoptionProgress -Status 'Testing line progress' -PercentComplete 50
        } 6>&1 | ForEach-Object { [string]$_ })
        $phaseText = $phaseOutput -join "`n"
        if (-not $phaseText.Contains('meAndAI [') -or
            -not $phaseText.Contains('50%') -or
            -not $phaseText.Contains('Testing line progress')) {
            Add-Failure "TEST-0105 line-oriented phase renderer produced unexpected output: $phaseText"
        }

        $engine = (Get-Process -Id $PID).Path
        $runner = [pscustomobject]@{
            Command = $engine
            PrefixArguments = @()
            Description = 'mock JSONL event process'
        }
        $script:QuickAdoptionTestAckPath = $ackPath
        $script:QuickAdoptionStreamResult = $null
        $streamOutput = @(& {
            $script:QuickAdoptionStreamResult = Invoke-BoundedProcess `
                -Runner $runner `
                -Arguments @(
                    '-NoProfile', '-File', $fixturePath,
                    '-Mode', 'Stream', '-AckPath', $ackPath
                ) `
                -TimeoutMilliseconds 10000 `
                -TimeoutDescription '10 second(s)' `
                -Operation 'Mock Codex JSONL stream' `
                -ProgressActivity 'Running local Codex' `
                -OutputLineHandler {
                    param([string]$Line)
                    Write-LocalCodexEvent -Line $Line
                    if (-not (Test-Path -LiteralPath $script:QuickAdoptionTestAckPath)) {
                        [IO.File]::WriteAllText(
                            $script:QuickAdoptionTestAckPath,
                            'ack',
                            [Text.UTF8Encoding]::new($false)
                        )
                    }
                }
        } 6>&1 | ForEach-Object { [string]$_ })
        $streamText = $streamOutput -join "`n"
        if ($null -eq $script:QuickAdoptionStreamResult -or
            $script:QuickAdoptionStreamResult.ExitCode -ne 0 -or
            -not (Test-Path -LiteralPath $ackPath -PathType Leaf)) {
            Add-Failure 'TEST-0105 JSONL stdout was not acknowledged and consumed while the process was active.'
        }
        foreach ($required in @(
            'Codex | Session started',
            'Codex | Working',
            'Codex | Analyzing repository',
            'Codex | Running command: git',
            'Codex | Inspecting project records. Preparing adoption evidence.',
            'Codex | Changed file: docs/ai-adoption.md',
            'Codex | Plan updated',
            'Codex | Completed'
        )) {
            if (-not $streamText.Contains($required)) {
                Add-Failure "TEST-0105 live activity output is missing '$required': $streamText"
            }
        }
        if ($streamText.Contains('MEANDAI_TEST_HIDDEN') -or
            $streamText.Length -gt 2400) {
            Add-Failure 'TEST-0105 live presentation exposed a raw/unsafe event field or exceeded its bounded fixture output.'
        }

        $script:QuickAdoptionProgressEnabled = $false
        $quietOutput = @(& {
            Set-QuickAdoptionProgress -Status 'Hidden phase' -PercentComplete 60
            Write-LocalCodexEvent -Line '{"type":"turn.started"}'
        } 6>&1 | ForEach-Object { [string]$_ })
        if ($quietOutput.Count -ne 0) {
            Add-Failure 'TEST-0105 -NoProgress-equivalent state did not suppress phase and Codex activity presentation.'
        }
        if ($Shard -ceq 'All' -and
            $failures.Count -eq $test0105FailureCount) {
            Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
                -TestId 'TEST-0105'
        }
        [IO.Directory]::CreateDirectory($ownedCancellationRoot) | Out-Null
        $engineLiteral = ConvertTo-SingleQuotedLiteral -Value $engine
        $fixtureLiteral = ConvertTo-SingleQuotedLiteral -Value $fixturePath
        $parentLiteral = ConvertTo-SingleQuotedLiteral -Value $parentPidPath
        $childLiteral = ConvertTo-SingleQuotedLiteral -Value $childPidPath
        $ownedRootLiteral = ConvertTo-SingleQuotedLiteral -Value $ownedCancellationRoot
        $cancellationHarness = @(
            [string]$functionText['ConvertTo-ProcessArgument'],
            [string]$functionText['New-ExternalProcessContainment'],
            [string]$functionText['Stop-ExternalProcessTree'],
            [string]$functionText['Invoke-BoundedProcess'],
            "`$runner = [pscustomobject]@{ Command = $engineLiteral; PrefixArguments = @(); Description = 'mock process tree' }",
            'try {',
            "  Invoke-BoundedProcess -Runner `$runner -Arguments @('-NoProfile','-File',$fixtureLiteral,'-Mode','Tree','-ParentPidPath',$parentLiteral,'-ChildPidPath',$childLiteral) -TimeoutMilliseconds 120000 -TimeoutDescription '120 second(s)' -Operation 'Mock cancellable process tree' -RequireProcessTreeContainment | Out-Null",
            '}',
            'finally {',
            "  if (Test-Path -LiteralPath $ownedRootLiteral) { Remove-Item -LiteralPath $ownedRootLiteral -Recurse -Force }",
            '}'
        ) -join "`n"

        $pipeline = [PowerShell]::Create()
        try {
            [void]$pipeline.AddScript($cancellationHarness)
            $async = $pipeline.BeginInvoke()
            $deadline = [DateTime]::UtcNow.AddSeconds(10)
            while ((-not (Test-Path -LiteralPath $parentPidPath -PathType Leaf) -or
                -not (Test-Path -LiteralPath $childPidPath -PathType Leaf)) -and
                [DateTime]::UtcNow -lt $deadline) {
                Start-Sleep -Milliseconds 50
            }
            if (-not (Test-Path -LiteralPath $parentPidPath -PathType Leaf) -or
                -not (Test-Path -LiteralPath $childPidPath -PathType Leaf)) {
                Add-Failure 'TEST-0106 mock process tree did not start before cancellation.'
            }
            else {
                $ownedParentPid = [int][IO.File]::ReadAllText($parentPidPath)
                $ownedChildPid = [int][IO.File]::ReadAllText($childPidPath)
                $pipeline.Stop()
                try { [void]$pipeline.EndInvoke($async) } catch { }

                $exitDeadline = [DateTime]::UtcNow.AddSeconds(5)
                while (((Test-OwnedProcessAlive -ProcessId $ownedParentPid) -or
                    (Test-OwnedProcessAlive -ProcessId $ownedChildPid)) -and
                    [DateTime]::UtcNow -lt $exitDeadline) {
                    Start-Sleep -Milliseconds 50
                }
                $parentAlive = Test-OwnedProcessAlive -ProcessId $ownedParentPid
                $childAlive = Test-OwnedProcessAlive -ProcessId $ownedChildPid
                if ($parentAlive -or $childAlive) {
                    Add-Failure "TEST-0106 pipeline cancellation left the owned process tree running (parent=$ownedParentPid alive=$parentAlive; child=$ownedChildPid alive=$childAlive)."
                }
                if (Test-Path -LiteralPath $ownedCancellationRoot) {
                    Add-Failure 'TEST-0106 pipeline cancellation did not reach owned temporary-root cleanup.'
                }
            }
        }
        finally {
            $pipeline.Dispose()
        }
    }
}
finally {
    foreach ($processId in @($ownedChildPid, $ownedParentPid)) {
        if (Test-OwnedProcessAlive -ProcessId $processId) {
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Variable -Scope Script -Name QuickAdoptionTestAckPath,QuickAdoptionStreamResult `
        -ErrorAction SilentlyContinue
}
if ($Shard -ceq 'All' -and
    $failures.Count -eq $test0106FailureCount) {
    Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
        -TestId 'TEST-0106'
}

if ($failures.Count -gt 0) {
    Write-Host "Quick-adoption streaming tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

if ($Shard -ceq 'All') {
    Write-Host 'Quick-adoption streaming tests passed for TEST-0105 and TEST-0106.' `
        -ForegroundColor Green
    $scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
    Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
        ($scenarioResult | ConvertTo-Json -Compress))
}
else {
    Write-Host 'Quick-adoption Windows-native streaming compatibility passed.' `
        -ForegroundColor Green
    $compatibilityResult = [ordered]@{
        schema = 1
        suite = 'tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1'
        shard = 'WindowsNative'
        passed = $true
    }
    Write-Host ('MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
        ($compatibilityResult | ConvertTo-Json -Compress))
}
