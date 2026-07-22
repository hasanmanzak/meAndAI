Set-StrictMode -Version Latest

function New-MeAndAITestGitBlobBatchSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repository,
        [long]$MaximumBlobBytes = 262144,
        [long]$MaximumAggregateBlobBytes = 4194304,
        [int]$SessionTimeoutMilliseconds = 120000,
        [int]$AbortTimeoutMilliseconds = 5000,
        [int]$MaximumHeaderBytes = 128,
        [int]$MaximumStandardErrorBytes = 65536
    )

    if (-not (Test-Path -LiteralPath $Repository -PathType Container) -or
        $MaximumBlobBytes -lt 0 -or
        $MaximumAggregateBlobBytes -lt 0 -or
        $SessionTimeoutMilliseconds -le 0 -or
        $AbortTimeoutMilliseconds -le 0 -or
        $MaximumHeaderBytes -le 0 -or
        $MaximumStandardErrorBytes -lt 0) {
        throw 'The test Git blob batch-session inputs are invalid.'
    }

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $state = [pscustomobject][ordered]@{
        Lifecycle = 'NotStarted'
        Busy = $false
        Process = $null
        ProcessStarted = $false
        InputStream = $null
        InputClosed = $false
        OutputStream = $null
        ErrorStream = $null
        StartedAt = [long]0
        StdoutBuffer = [byte[]]::new(8192)
        StdoutOffset = [int]0
        StdoutCount = [int]0
        StderrBuffer = [byte[]]::new(8192)
        StderrTask = $null
        StderrEof = $false
        StderrBytes = [long]0
        StderrMemory = [IO.MemoryStream]::new()
        PendingPrimaryTask = $null
        ProcessStarts = [long]0
        Requests = [long]0
        ResponseBytes = [long]0
    }

    $getRemainingMilliseconds = {
        [long]$elapsed = [long]$stopwatch.ElapsedMilliseconds -
            [long]$state.StartedAt
        [long]$remaining = [long]$SessionTimeoutMilliseconds - $elapsed
        if ($remaining -lt 0) {
            throw 'The test Git blob batch-session deadline was exceeded.'
        }
        return [int][Math]::Min($remaining, [int]::MaxValue)
    }.GetNewClosure()

    $startStderrRead = {
        if ($state.StderrEof -or $null -ne $state.StderrTask) { return }
        [long]$remainingEvidence = [long]$MaximumStandardErrorBytes -
            [long]$state.StderrBytes
        if ($remainingEvidence -lt 0) {
            throw 'The test Git blob batch-session stderr budget was exceeded.'
        }
        [int]$readCount = [int][Math]::Min(
            [long]$state.StderrBuffer.Length,
            $remainingEvidence + 1
        )
        $task = $state.ErrorStream.ReadAsync(
            $state.StderrBuffer, 0, $readCount
        )
        if ($task -isnot [Threading.Tasks.Task]) {
            throw 'The test Git blob batch-session stderr read is invalid.'
        }
        $state.StderrTask = $task
    }.GetNewClosure()

    $consumeStderrRead = {
        if ($null -eq $state.StderrTask) { return }
        $task = $state.StderrTask
        $state.StderrTask = $null
        [int]$read = $task.GetAwaiter().GetResult()
        if ($read -lt 0 -or $read -gt $state.StderrBuffer.Length) {
            throw 'The test Git blob batch-session stderr length is invalid.'
        }
        if ($read -eq 0) {
            $state.StderrEof = $true
            return
        }
        if ($state.StderrBytes -gt
            ([long]$MaximumStandardErrorBytes - $read)) {
            throw 'The test Git blob batch-session stderr budget was exceeded.'
        }
        $state.StderrMemory.Write($state.StderrBuffer, 0, $read)
        $state.StderrBytes += $read
        & $startStderrRead
    }.GetNewClosure()

    $waitTask = {
        param([Parameter(Mandatory)][Threading.Tasks.Task]$Task)

        $state.PendingPrimaryTask = $Task
        try {
            while ($true) {
                [int]$remaining = & $getRemainingMilliseconds
                if ($null -ne $state.StderrTask) {
                    [int]$completed = [Threading.Tasks.Task]::WaitAny(
                        [Threading.Tasks.Task[]]@($state.StderrTask, $Task),
                        $remaining
                    )
                    if ($completed -lt 0) {
                        throw 'The test Git blob batch-session deadline was exceeded.'
                    }
                    if ($completed -eq 0) {
                        & $consumeStderrRead
                        continue
                    }
                }
                else {
                    [int]$completed = [Threading.Tasks.Task]::WaitAny(
                        [Threading.Tasks.Task[]]@($Task), $remaining
                    )
                    if ($completed -lt 0) {
                        throw 'The test Git blob batch-session deadline was exceeded.'
                    }
                }
                return $Task.GetAwaiter().GetResult()
            }
        }
        finally {
            if ($Task.IsCompleted) { $state.PendingPrimaryTask = $null }
        }
    }.GetNewClosure()

    $readOutputChunk = {
        if ($state.StdoutOffset -lt $state.StdoutCount) { return $true }
        $state.StdoutOffset = 0
        $state.StdoutCount = 0
        $task = $state.OutputStream.ReadAsync(
            $state.StdoutBuffer, 0, $state.StdoutBuffer.Length
        )
        [int]$read = & $waitTask $task
        if ($read -lt 0 -or $read -gt $state.StdoutBuffer.Length) {
            throw 'The test Git blob batch-session stdout length is invalid.'
        }
        $state.StdoutCount = $read
        return $read -gt 0
    }.GetNewClosure()

    $readOutputByte = {
        if (-not (& $readOutputChunk)) { return [int]-1 }
        [int]$value = $state.StdoutBuffer[$state.StdoutOffset]
        $state.StdoutOffset++
        return $value
    }.GetNewClosure()

    $readOutputExact = {
        param([Parameter(Mandatory)][byte[]]$Buffer)

        [int]$written = 0
        while ($written -lt $Buffer.Length) {
            if ($state.StdoutOffset -lt $state.StdoutCount) {
                [int]$available = $state.StdoutCount - $state.StdoutOffset
                [int]$copy = [Math]::Min(
                    $available, $Buffer.Length - $written
                )
                [Array]::Copy(
                    $state.StdoutBuffer, $state.StdoutOffset,
                    $Buffer, $written, $copy
                )
                $state.StdoutOffset += $copy
                $written += $copy
                continue
            }
            $task = $state.OutputStream.ReadAsync(
                $Buffer, $written, $Buffer.Length - $written
            )
            [int]$read = & $waitTask $task
            if ($read -le 0 -or $read -gt ($Buffer.Length - $written)) {
                throw 'The test Git blob batch payload ended before its declared length.'
            }
            $written += $read
        }
    }.GetNewClosure()

    $ensureStarted = {
        if ($state.Lifecycle -cne 'NotStarted') { return }
        $state.StartedAt = [long]$stopwatch.ElapsedMilliseconds

        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = 'git'
        $startInfo.Arguments = 'cat-file --batch'
        $startInfo.WorkingDirectory = $Repository
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        # Windows PowerShell 5.1 returns null from the first legacy getter.
        [void]$startInfo.EnvironmentVariables
        $startInfo.EnvironmentVariables['GIT_NO_REPLACE_OBJECTS'] = '1'

        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        $state.Process = $process
        $originalInputEncoding = [Console]::InputEncoding
        try {
            [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
            if (-not $process.Start()) {
                throw 'The test Git blob batch child did not start.'
            }
            $state.ProcessStarted = $true
            # PowerShell 5.1 has no StandardInputEncoding. Capture the raw
            # pipe while its enclosing writer is initialized without a BOM.
            $state.InputStream = $process.StandardInput.BaseStream
        }
        finally {
            [Console]::InputEncoding = $originalInputEncoding
        }
        $state.OutputStream = $process.StandardOutput.BaseStream
        $state.ErrorStream = $process.StandardError.BaseStream
        [void](& $getRemainingMilliseconds)
        $state.ProcessStarts++
        $state.Lifecycle = 'Running'
        & $startStderrRead
    }.GetNewClosure()

    $getGitBlobSha = {
        param([Parameter(Mandatory)][byte[]]$Bytes)

        [byte[]]$header = [Text.Encoding]::ASCII.GetBytes(
            "blob $($Bytes.Length)`0"
        )
        $sha = [Security.Cryptography.SHA1]::Create()
        try {
            [void]$sha.TransformBlock(
                $header, 0, $header.Length, $header, 0
            )
            [void]$sha.TransformFinalBlock($Bytes, 0, $Bytes.Length)
            return ([BitConverter]::ToString(
                $sha.Hash
            )).Replace('-', '').ToLowerInvariant()
        }
        finally { $sha.Dispose() }
    }.GetNewClosure()

    $readBlob = {
        param([Parameter(Mandatory)]$Entry)

        if ($state.Busy) {
            $state.Lifecycle = 'Faulted'
            throw 'The test Git blob batch-session does not allow reentrancy.'
        }
        if ($state.Lifecycle -cin @('Faulted', 'Aborted', 'Completed')) {
            throw "The test Git blob batch-session is terminal: $($state.Lifecycle)."
        }
        $state.Busy = $true
        try {
            if ([string]$Entry.Type -cne 'blob' -or
                @('100644', '100755') -cnotcontains [string]$Entry.Mode -or
                [string]$Entry.Sha -cnotmatch '^[0-9a-f]{40}$') {
                throw 'The test Git blob batch-session request is invalid.'
            }
            & $ensureStarted

            [byte[]]$request = [byte[]]::new(41)
            [byte[]]$oidBytes = [Text.Encoding]::ASCII.GetBytes(
                [string]$Entry.Sha
            )
            [Array]::Copy($oidBytes, 0, $request, 0, 40)
            $request[40] = 10
            $writeTask = $state.InputStream.WriteAsync(
                $request, 0, $request.Length
            )
            [void](& $waitTask $writeTask)
            $flushTask = $state.InputStream.FlushAsync()
            [void](& $waitTask $flushTask)
            if ($state.Lifecycle -cne 'Running') {
                throw 'The test Git blob batch-session faulted during a read.'
            }
            $state.Requests++

            $headerBytes = [Collections.Generic.List[byte]]::new()
            while ($true) {
                [int]$value = & $readOutputByte
                if ($value -lt 0) {
                    throw 'The test Git blob batch response ended before its header.'
                }
                if ($value -eq 10) { break }
                if ($value -gt 127 -or
                    $headerBytes.Count -ge $MaximumHeaderBytes) {
                    throw 'The test Git blob batch response header is invalid.'
                }
                $headerBytes.Add([byte]$value)
            }

            $headerText = [Text.Encoding]::ASCII.GetString(
                $headerBytes.ToArray()
            )
            $headerMatch = [regex]::Match(
                $headerText,
                '^(?<oid>[0-9a-f]{40}) blob (?<size>0|[1-9][0-9]*)$'
            )
            [long]$size = 0
            if (-not $headerMatch.Success -or
                [string]$headerMatch.Groups['oid'].Value -cne
                    [string]$Entry.Sha -or
                -not [long]::TryParse(
                    [string]$headerMatch.Groups['size'].Value,
                    [Globalization.NumberStyles]::None,
                    [Globalization.CultureInfo]::InvariantCulture,
                    [ref]$size
                ) -or $size -gt $MaximumBlobBytes -or
                $size -gt ($MaximumAggregateBlobBytes -
                    [long]$state.ResponseBytes) -or
                $size -gt [int]::MaxValue) {
                throw 'The test Git blob batch response identity or size is invalid.'
            }

            [byte[]]$payload = [byte[]]::new([int]$size)
            if ($payload.Length -gt 0) { & $readOutputExact $payload }
            if ((& $readOutputByte) -ne 10) {
                throw 'The test Git blob batch response lacks its exact LF trailer.'
            }
            if ((& $getGitBlobSha $payload) -cne [string]$Entry.Sha) {
                throw 'The test Git blob batch payload identity is invalid.'
            }
            if ($state.Lifecycle -cne 'Running') {
                throw 'The test Git blob batch-session faulted during a read.'
            }
            $state.ResponseBytes += $size
            return ,$payload
        }
        catch {
            $state.Lifecycle = 'Faulted'
            throw
        }
        finally { $state.Busy = $false }
    }.GetNewClosure()

    $complete = {
        param(
            [Parameter(Mandatory)]$Graph
        )

        if ($state.Busy -or
            $state.Lifecycle -cin @('Faulted', 'Aborted', 'Completed')) {
            throw "The test Git blob batch-session cannot complete from '$($state.Lifecycle)'."
        }
        try {
            if ($state.Lifecycle -ceq 'NotStarted') {
                if ([long]$Graph.counts.parsedBlobs -ne 0 -or
                    [long]$Graph.counts.parsedBlobBytes -ne 0) {
                    throw 'The test Git blob batch zero-process evidence differs from the graph.'
                }
                $state.StderrMemory.Dispose()
                $state.Lifecycle = 'Completed'
                return
            }

            $state.InputStream.Close()
            $state.InputClosed = $true
            [void](& $getRemainingMilliseconds)
            if ((& $readOutputByte) -ne -1) {
                throw 'The test Git blob batch response contains extra output.'
            }
            while (-not $state.StderrEof) {
                if ($null -eq $state.StderrTask) { & $startStderrRead }
                $task = $state.StderrTask
                $state.PendingPrimaryTask = $task
                [int]$remaining = & $getRemainingMilliseconds
                [int]$completed = [Threading.Tasks.Task]::WaitAny(
                    [Threading.Tasks.Task[]]@($task), $remaining
                )
                if ($completed -lt 0) {
                    throw 'The test Git blob batch-session deadline was exceeded.'
                }
                $state.PendingPrimaryTask = $null
                & $consumeStderrRead
            }
            [int]$remaining = & $getRemainingMilliseconds
            if (-not $state.Process.WaitForExit($remaining)) {
                throw 'The test Git blob batch child exceeded its reap deadline.'
            }
            if ($state.Process.ExitCode -ne 0) {
                $stderrText = [Text.Encoding]::UTF8.GetString(
                    $state.StderrMemory.ToArray()
                )
                throw "The test Git blob batch child failed: $stderrText"
            }
            if ($state.Requests -ne [long]$Graph.counts.parsedBlobs -or
                $state.ResponseBytes -ne
                    [long]$Graph.counts.parsedBlobBytes) {
                throw 'The test Git blob batch observation differs from the graph.'
            }
            $state.Process.Dispose()
            $state.Process = $null
            $state.StderrMemory.Dispose()
            $state.Lifecycle = 'Completed'
        }
        catch {
            $state.Lifecycle = 'Faulted'
            throw
        }
    }.GetNewClosure()

    $abort = {
        if ($state.Lifecycle -cin @('Completed', 'Aborted')) { return }
        $problems = [Collections.Generic.List[Exception]]::new()
        $abortWatch = [Diagnostics.Stopwatch]::StartNew()
        try {
            if ($null -ne $state.InputStream -and -not $state.InputClosed) {
                try {
                    $state.InputStream.Close()
                    $state.InputClosed = $true
                }
                catch { $problems.Add($_.Exception) }
            }

            $hasExited = -not $state.ProcessStarted
            if ($state.ProcessStarted) {
                try { $hasExited = [bool]$state.Process.HasExited }
                catch { $problems.Add($_.Exception) }
            }
            if ($state.ProcessStarted -and -not $hasExited) {
                try { $state.Process.Kill() }
                catch {
                    $killFailure = $_.Exception
                    try { $hasExited = [bool]$state.Process.HasExited }
                    catch { $problems.Add($_.Exception) }
                    if (-not $hasExited) { $problems.Add($killFailure) }
                }
                try {
                    [int]$remainingAbort = [Math]::Max(
                        0,
                        $AbortTimeoutMilliseconds -
                            [int]$abortWatch.ElapsedMilliseconds
                    )
                    if (-not $state.Process.WaitForExit($remainingAbort)) {
                        $problems.Add([TimeoutException]::new(
                            'The test Git blob batch child survived abort.'
                        ))
                    }
                    else { $hasExited = $true }
                }
                catch { $problems.Add($_.Exception) }
            }

            $pendingTasks = @(
                $state.PendingPrimaryTask, $state.StderrTask
            ) | Where-Object { $null -ne $_ } | Select-Object -Unique
            foreach ($pending in $pendingTasks) {
                if ($pending.IsCompleted) { continue }
                try {
                    [int]$remainingAbort = [Math]::Max(
                        0,
                        $AbortTimeoutMilliseconds -
                            [int]$abortWatch.ElapsedMilliseconds
                    )
                    if (-not $pending.Wait($remainingAbort)) {
                        $problems.Add([TimeoutException]::new(
                            'The test Git blob batch I/O task survived abort.'
                        ))
                    }
                }
                catch {
                    if (-not $pending.IsCompleted) {
                        $problems.Add($_.Exception)
                    }
                }
            }
            if ($null -ne $state.Process) {
                try { $state.Process.Dispose() }
                catch { $problems.Add($_.Exception) }
                $state.Process = $null
            }
        }
        finally {
            $state.StderrMemory.Dispose()
            $state.Lifecycle = 'Aborted'
        }
        if ($problems.Count -eq 1) { throw $problems[0] }
        if ($problems.Count -gt 1) {
            throw [AggregateException]::new(
                'The test Git blob batch-session cleanup failed.',
                [Exception[]]$problems.ToArray()
            )
        }
    }.GetNewClosure()

    $getObservation = {
        return [pscustomobject][ordered]@{
            Lifecycle = [string]$state.Lifecycle
            ProcessStarts = [long]$state.ProcessStarts
            Requests = [long]$state.Requests
            ResponseBytes = [long]$state.ResponseBytes
        }
    }.GetNewClosure()

    return [pscustomobject][ordered]@{
        ReadBlob = $readBlob
        Complete = $complete
        Abort = $abort
        GetObservation = $getObservation
    }
}

Export-ModuleMember -Function 'New-MeAndAITestGitBlobBatchSession'
