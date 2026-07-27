[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Stream', 'Tree', 'Child')]
    [string]$Mode,
    [string]$StreamIdentity = '',
    [string]$ParentPidPath = '',
    [string]$ChildPidPath = ''
)

$ErrorActionPreference = 'Stop'

function Write-JsonLine {
    param([Parameter(Mandatory)]$Value)

    [Console]::Out.WriteLine(($Value | ConvertTo-Json -Compress -Depth 8))
    [Console]::Out.Flush()
}

if ($Mode -ceq 'Stream') {
    if ($StreamIdentity -cnotmatch '^[0-9a-f]{32}$') {
        throw 'Stream mode requires one exact lowercase run identity.'
    }
    Write-JsonLine ([ordered]@{
        type = 'thread.started'
        thread_id = 'mock-thread'
        fixture_process_id = $PID
        fixture_stream_identity = $StreamIdentity
    })
    Start-Sleep -Seconds 5

    Write-JsonLine ([ordered]@{ type = 'turn.started' })
    Write-JsonLine ([ordered]@{
        type = 'item.started'
        item = [ordered]@{
            id = 'reasoning-1'
            type = 'reasoning'
            text = 'MEANDAI_TEST_HIDDEN_REASONING'
        }
    })
    Write-JsonLine ([ordered]@{
        type = 'item.started'
        item = [ordered]@{
            id = 'command-1'
            type = 'command_execution'
            command = 'git status --porcelain; echo MEANDAI_TEST_HIDDEN_COMMAND'
            aggregated_output = 'MEANDAI_TEST_HIDDEN_COMMAND_OUTPUT'
            status = 'in_progress'
        }
    })
    Write-JsonLine ([ordered]@{
        type = 'item.completed'
        item = [ordered]@{
            id = 'message-1'
            type = 'agent_message'
            text = "Inspecting project records.`nPreparing adoption evidence."
        }
    })
    Write-JsonLine ([ordered]@{
        type = 'item.completed'
        item = [ordered]@{
            id = 'file-1'
            type = 'file_change'
            changes = @([ordered]@{ path = 'docs/ai-adoption.md'; kind = 'update' })
        }
    })
    Write-JsonLine ([ordered]@{
        type = 'item.completed'
        item = [ordered]@{
            id = 'plan-1'
            type = 'plan_update'
            text = 'MEANDAI_TEST_HIDDEN_PLAN_DETAIL'
        }
    })
    [Console]::Out.WriteLine('not-json-MEANDAI_TEST_HIDDEN_RAW')
    [Console]::Out.Flush()
    Write-JsonLine ([ordered]@{
        type = 'future.event'
        payload = 'MEANDAI_TEST_HIDDEN_UNKNOWN'
    })
    Write-JsonLine ([ordered]@{
        type = 'turn.completed'
        usage = [ordered]@{ input_tokens = 1; output_tokens = 1 }
    })
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ParentPidPath) -or
    [string]::IsNullOrWhiteSpace($ChildPidPath)) {
    throw 'Tree and child modes require both PID paths.'
}

if ($Mode -ceq 'Child') {
    [IO.File]::WriteAllText(
        $ChildPidPath,
        [string]$PID,
        [Text.UTF8Encoding]::new($false)
    )
    Start-Sleep -Seconds 120
    exit 0
}

[IO.File]::WriteAllText(
    $ParentPidPath,
    [string]$PID,
    [Text.UTF8Encoding]::new($false)
)
$engine = (Get-Process -Id $PID).Path
$child = Start-Process -FilePath $engine -ArgumentList @(
    '-NoProfile', '-File', $PSCommandPath,
    '-Mode', 'Child',
    '-ParentPidPath', $ParentPidPath,
    '-ChildPidPath', $ChildPidPath
) -PassThru

$deadline = [DateTime]::UtcNow.AddSeconds(5)
while (-not (Test-Path -LiteralPath $ChildPidPath -PathType Leaf) -and
    [DateTime]::UtcNow -lt $deadline) {
    Start-Sleep -Milliseconds 50
}
if (-not (Test-Path -LiteralPath $ChildPidPath -PathType Leaf)) {
    try { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue } catch { }
    throw 'The mock descendant did not start.'
}
Start-Sleep -Seconds 120
