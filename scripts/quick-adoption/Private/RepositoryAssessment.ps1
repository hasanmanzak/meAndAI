# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function Test-QuickAdoptionCanonicalRepositoryPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        $Path.StartsWith('/', [StringComparison]::Ordinal) -or
        $Path -match '^[A-Za-z]:' -or
        $Path.Contains('\') -or $Path -match '[\x00-\x1f]') {
        return $false
    }
    $segments = @($Path.Split('/'))
    return $segments.Count -gt 0 -and
        @($segments | Where-Object {
            $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..'
        }).Count -eq 0
}

function Get-InitialAdoptionPolicyCommand {
    param([Parameter(Mandatory)][string]$Name)

    if ($null -eq $script:InitialAdoptionPolicy -or
        $null -eq $script:InitialAdoptionPolicy.Commands -or
        -not $script:InitialAdoptionPolicy.Commands.ContainsKey($Name)) {
        throw "The exact initial-adoption policy command '$Name' is unavailable."
    }
    return $script:InitialAdoptionPolicy.Commands[$Name]
}

function Assert-QuickAdoptionCanonicalPathCasing {
    param([Parameter(Mandatory)][string]$Path)

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Assert-MeAndAIProtocolAssessmentPathCasing'
    & $command -Path $Path
}

function Get-QuickAdoptionProtocolSurfaceInventory {
    param([AllowNull()][AllowEmptyCollection()][object[]]$Paths = @())

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Get-MeAndAIProtocolSurfaceInventory'
    $arguments = @{ Paths = [object[]]@($Paths) }
    return @(& $command @arguments)
}

function Get-QuickAdoptionCanonicalCollisions {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Paths)

    $pathValues = @($Paths | ForEach-Object { [string]$_ })
    $collisions = [System.Collections.Generic.List[string]]::new()
    foreach ($targetPath in $adoptionCanonicalTargetPaths) {
        $found = @($pathValues | Where-Object {
            $_.Equals($targetPath, [StringComparison]::OrdinalIgnoreCase) -or
            $_.StartsWith("$targetPath/", [StringComparison]::OrdinalIgnoreCase) -or
            $targetPath.StartsWith("$($_)/", [StringComparison]::OrdinalIgnoreCase)
        }).Count -gt 0
        if ($found) {
            $collisions.Add($targetPath)
        }
    }
    $result = @($collisions | Select-Object -Unique)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return @($result)
}

function Test-QuickAdoptionAssessmentRelevantPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetPaths
    )

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAIProtocolAssessmentRelevantPath'
    return [bool](& $command -Path $Path -TargetPaths @($TargetPaths))
}

function Test-QuickAdoptionExactPullRequestMarker {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$RemoteHead,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$TargetSha,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [Parameter(Mandatory)][string]$ExpectedState,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedProtocolSurfaces,
        [Parameter(Mandatory)][bool]$ExpectedProtocolRecordLossAcknowledgement,
        [AllowNull()]$ExpectedSourceGraphIdentity = $null,
        [Parameter(Mandatory)][ValidateSet('Proposed', 'Completed')]
        [string]$ExpectedPhase
    )

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAIExactAdoptionPullRequestMarker'
    return [bool](& $command @PSBoundParameters)
}

function Test-QuickAdoptionCompletedChangeSet {
    param(
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$Changes,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$ProtocolSurfaces,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$TargetPaths,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$FinalEntries,
        [AllowNull()]$SourceGraph = $null
    )

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAICompletedAdoptionChangeSet'
    return [bool](& $command @PSBoundParameters)
}

function Test-QuickAdoptionReservedSubmoduleContract {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Rows,
        [Parameter(Mandatory)]$ProtocolEntry,
        [Parameter(Mandatory)][string]$ProtocolRepository
    )

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAIReservedProtocolSubmoduleContract'
    return [bool](& $command @PSBoundParameters)
}

function Get-QuickAdoptionRelevantTreePaths {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetPaths
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Bounded tree assessment requires one canonical commit.'
    }
    $paths = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $maximumRelevantCount =
        [int]$script:InitialAdoptionPolicy.Limits.MaximumSurfaceCount +
        @($TargetPaths).Count + 2
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $global:LASTEXITCODE = 0
        & git -C $Repository ls-tree -r --name-only $Commit -- 2>&1 |
            ForEach-Object {
                $path = [string]$_
                Assert-QuickAdoptionCanonicalPathCasing -Path $path
                if (-not (Test-QuickAdoptionAssessmentRelevantPath `
                    -Path $path -TargetPaths $TargetPaths)) {
                    return
                }
                if (-not (Test-QuickAdoptionCanonicalRepositoryPath -Path $path) -or
                    -not $seen.Add($path)) {
                    throw "Protocol inventory path '$path' is invalid or case-ambiguous."
                }
                $paths.Add($path)
                if ($paths.Count -gt $maximumRelevantCount) {
                    throw 'Protocol inventory exceeds the bounded assessment budget; maintainer review is required.'
                }
            }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "Git tree assessment failed with exit code $exitCode."
    }
    return @($paths)
}

function Get-QuickAdoptionInstructionGraphTreeEntries {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Instruction-graph tree acquisition requires one canonical commit.'
    }
    $limitsCommand = Get-InitialAdoptionPolicyCommand `
        -Name 'Get-MeAndAIInstructionGraphLimits'
    $limits = & $limitsCommand
    $entries = [System.Collections.Generic.List[object]]::new()
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = "ls-tree -r -t -z --full-tree $Commit --"
    $startInfo.WorkingDirectory = $Repository
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $record = [IO.MemoryStream]::new()
    [long]$treePathUtf8Bytes = 0
    $started = $false
    try {
        if (-not $process.Start()) {
            throw 'Unable to start exact instruction-graph tree acquisition.'
        }
        $started = $true
        $errorTask = $process.StandardError.ReadToEndAsync()
        $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
        while (($value = $process.StandardOutput.BaseStream.ReadByte()) -ne -1) {
            if ($value -ne 0) {
                if ($record.Length -ge
                    ([long]$limits.MaximumPathUtf8Bytes + 64)) {
                    throw 'Exact instruction-graph tree output contains an overlong record.'
                }
                $record.WriteByte([byte]$value)
                continue
            }
            $bytes = $record.ToArray()
            $record.SetLength(0)
            $tab = [Array]::IndexOf($bytes, [byte]9)
            if ($tab -le 0 -or $tab -ge ($bytes.Length - 1)) {
                throw 'Exact instruction-graph tree output is malformed or contains an unsafe path.'
            }
            $pathByteLength = $bytes.Length - $tab - 1
            if ($pathByteLength -gt [int]$limits.MaximumPathUtf8Bytes -or
                $treePathUtf8Bytes -gt
                    ([long]$limits.MaximumTreePathUtf8Bytes - $pathByteLength)) {
                throw 'Exact instruction-graph tree output exceeds its path budget.'
            }
            $treePathUtf8Bytes += $pathByteLength
            $header = [Text.Encoding]::ASCII.GetString($bytes, 0, $tab)
            $match = [regex]::Match(
                $header,
                '^(?<mode>[0-9]{6})\s+(?<type>blob|tree|commit)\s+(?<sha>[0-9a-f]{40})$'
            )
            if (-not $match.Success) {
                throw 'Exact instruction-graph tree output contains an invalid entry identity.'
            }
            try {
                $path = $strictUtf8.GetString(
                    $bytes, $tab + 1, $pathByteLength
                )
            }
            catch {
                throw 'Exact instruction-graph tree output contains a non-UTF-8 path.'
            }
            if (-not (Test-QuickAdoptionCanonicalRepositoryPath -Path $path)) {
                throw "Exact instruction-graph tree path '$path' is not canonical."
            }
            $entries.Add([pscustomobject]@{
                Path = $path
                Mode = [string]$match.Groups['mode'].Value
                Type = [string]$match.Groups['type'].Value
                Sha = [string]$match.Groups['sha'].Value
            })
            if ($entries.Count -gt [int]$limits.MaximumTreeEntries) {
                throw 'Instruction graph exceeds the tracked-tree budget; maintainer review is required.'
            }
        }
        if ($record.Length -ne 0) {
            throw 'Exact instruction-graph tree output is missing its final record terminator.'
        }
        $process.WaitForExit()
        $errorText = [string]$errorTask.Result
        if ($process.ExitCode -ne 0) {
            throw "Exact instruction-graph tree acquisition failed: $errorText"
        }
        return @($entries)
    }
    finally {
        if ($started -and -not $process.HasExited) { $process.Kill() }
        $record.Dispose()
        $process.Dispose()
    }
}

function New-QuickAdoptionInstructionGraphBatchSession {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][long]$MaximumBlobBytes,
        [Parameter(Mandatory)][long]$MaximumAggregateBlobBytes,
        [Parameter(Mandatory)][int]$SessionTimeoutMilliseconds,
        [Parameter(Mandatory)][int]$AbortTimeoutMilliseconds,
        [Parameter(Mandatory)][int]$MaximumHeaderBytes,
        [Parameter(Mandatory)][int]$MaximumStandardErrorBytes,
        [AllowNull()]$InternalTestHooks = $null
    )

    if ($MaximumBlobBytes -lt 0 -or $MaximumAggregateBlobBytes -lt 0 -or
        $SessionTimeoutMilliseconds -le 0 -or
        $AbortTimeoutMilliseconds -le 0 -or $MaximumHeaderBytes -le 0 -or
        $MaximumStandardErrorBytes -lt 0) {
        throw 'Instruction-graph batch-session limits are invalid.'
    }

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $getMonotonicMilliseconds = {
        return [long]$stopwatch.ElapsedMilliseconds
    }.GetNewClosure()
    $transportFactory = {
        param([string]$WorkingRepository)

        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = 'git'
        $startInfo.Arguments = 'cat-file --batch'
        $startInfo.WorkingDirectory = $WorkingRepository
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        # Windows PowerShell 5.1 initializes this legacy dictionary lazily.
        [void]$startInfo.EnvironmentVariables
        $startInfo.EnvironmentVariables['GIT_NO_REPLACE_OBJECTS'] = '1'
        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        $streamState = [pscustomobject]@{
            Input = $null
            Output = $null
            Error = $null
        }
        return [pscustomobject][ordered]@{
            Start = {
                # Windows PowerShell 5.1 has no
                # ProcessStartInfo.StandardInputEncoding property. Capture
                # its StreamWriter-backed pipe while Console.InputEncoding is
                # explicitly no-BOM so ambient encodings cannot prefix raw
                # batch requests.
                $started = $false
                try {
                    $originalInputEncoding = [Console]::InputEncoding
                    try {
                        [Console]::InputEncoding =
                            [Text.UTF8Encoding]::new($false)
                        if (-not $process.Start()) { return $false }
                        $started = $true
                        $streamState.Input =
                            $process.StandardInput.BaseStream
                    }
                    finally {
                        [Console]::InputEncoding = $originalInputEncoding
                    }
                    $streamState.Output =
                        $process.StandardOutput.BaseStream
                    $streamState.Error =
                        $process.StandardError.BaseStream
                    return $true
                }
                catch {
                    $primaryFailure = $_.Exception
                    if ($started) {
                        $cleanupProblems =
                            [System.Collections.Generic.List[string]]::new()
                        $hasExited = $false
                        try { $hasExited = [bool]$process.HasExited }
                        catch { $cleanupProblems.Add($_.Exception.Message) }
                        if (-not $hasExited) {
                            try { $process.Kill() }
                            catch { $cleanupProblems.Add($_.Exception.Message) }
                        }
                        try {
                            if (-not $process.WaitForExit(
                                $AbortTimeoutMilliseconds
                            )) {
                                $cleanupProblems.Add(
                                    'Instruction-graph batch child survived failed stream capture.'
                                )
                            }
                        }
                        catch { $cleanupProblems.Add($_.Exception.Message) }
                        try { $process.Dispose() }
                        catch { $cleanupProblems.Add($_.Exception.Message) }
                        if ($cleanupProblems.Count -gt 0) {
                            throw ($primaryFailure.Message +
                                ' Stream-capture cleanup failed: ' +
                                ($cleanupProblems -join ' '))
                        }
                    }
                    throw $primaryFailure
                }
            }.GetNewClosure()
            WriteInputAsync = {
                param([byte[]]$Buffer, [int]$Offset, [int]$Count)
                return $streamState.Input.WriteAsync(
                    $Buffer, $Offset, $Count
                )
            }.GetNewClosure()
            FlushInputAsync = {
                return $streamState.Input.FlushAsync()
            }.GetNewClosure()
            ReadStandardOutputAsync = {
                param([byte[]]$Buffer, [int]$Offset, [int]$Count)
                return $streamState.Output.ReadAsync(
                    $Buffer, $Offset, $Count
                )
            }.GetNewClosure()
            ReadStandardErrorAsync = {
                param([byte[]]$Buffer, [int]$Offset, [int]$Count)
                return $streamState.Error.ReadAsync(
                    $Buffer, $Offset, $Count
                )
            }.GetNewClosure()
            # Close the raw pipe. Closing the enclosing StreamWriter can emit
            # an encoding preamble after the exact ASCII-LF batch requests.
            CloseInput = {
                $streamState.Input.Close()
            }.GetNewClosure()
            WaitForExit = {
                param([int]$Milliseconds)
                return [bool]$process.WaitForExit($Milliseconds)
            }.GetNewClosure()
            GetHasExited = { return [bool]$process.HasExited }.GetNewClosure()
            GetExitCode = { return [int]$process.ExitCode }.GetNewClosure()
            Kill = { $process.Kill() }.GetNewClosure()
            Dispose = { $process.Dispose() }.GetNewClosure()
        }
    }.GetNewClosure()

    if ($null -ne $InternalTestHooks) {
        $hookNames = @($InternalTestHooks.PSObject.Properties.Name)
        [Array]::Sort($hookNames, [StringComparer]::Ordinal)
        if ($hookNames.Count -ne 2 -or
            $hookNames[0] -cne 'GetMonotonicMilliseconds' -or
            $hookNames[1] -cne 'TransportFactory' -or
            $InternalTestHooks.TransportFactory -isnot [scriptblock] -or
            $InternalTestHooks.GetMonotonicMilliseconds -isnot [scriptblock]) {
            throw 'Instruction-graph batch-session test hooks are invalid.'
        }
        $transportFactory = $InternalTestHooks.TransportFactory
        $getMonotonicMilliseconds =
            $InternalTestHooks.GetMonotonicMilliseconds
    }

    $state = [pscustomobject][ordered]@{
        Lifecycle = 'NotStarted'
        Busy = $false
        Transport = $null
        ProcessStarted = $false
        ProcessStarts = [long]0
        Requests = [long]0
        ResponseBytes = [long]0
        StartedAt = [long]0
        LastClock = [long]-1
        StdoutBuffer = [byte[]]::new(8192)
        StdoutOffset = [int]0
        StdoutCount = [int]0
        StderrBuffer = [byte[]]::new(8192)
        StderrTask = $null
        StderrEof = $false
        StderrBytes = [long]0
        StderrMemory = [IO.MemoryStream]::new()
        PendingPrimaryTask = $null
    }
    $requiredTransportCallbacks = @(
        'Start', 'WriteInputAsync', 'FlushInputAsync',
        'ReadStandardOutputAsync', 'ReadStandardErrorAsync', 'CloseInput',
        'WaitForExit', 'GetHasExited', 'GetExitCode', 'Kill', 'Dispose'
    )

    $getNow = {
        $raw = & $getMonotonicMilliseconds
        if ($raw -isnot [ValueType]) {
            throw 'Instruction-graph batch-session clock is invalid.'
        }
        [long]$now = $raw
        if ($now -lt 0 -or
            ($state.LastClock -ge 0 -and $now -lt $state.LastClock)) {
            throw 'Instruction-graph batch-session clock is not monotonic.'
        }
        $state.LastClock = $now
        return $now
    }.GetNewClosure()
    $getRemainingMilliseconds = {
        [long]$elapsed = (& $getNow) - $state.StartedAt
        [long]$remaining = [long]$SessionTimeoutMilliseconds - $elapsed
        if ($remaining -lt 0) {
            throw 'Instruction-graph batch session deadline exceeded.'
        }
        if ($remaining -gt [int]::MaxValue) { return [int]::MaxValue }
        return [int]$remaining
    }.GetNewClosure()
    $startStderrRead = {
        if ($state.StderrEof -or $null -ne $state.StderrTask) { return }
        [long]$remainingEvidenceBytes =
            [long]$MaximumStandardErrorBytes - $state.StderrBytes
        if ($remainingEvidenceBytes -lt 0) {
            throw 'Instruction-graph batch standard error exceeds its budget.'
        }
        # One byte beyond the retained ceiling is the bounded overflow
        # sentinel. Never consume a full extra buffer merely to detect it.
        [int]$readCount = [int][Math]::Min(
            [long]$state.StderrBuffer.Length,
            $remainingEvidenceBytes + 1
        )
        $task = & $state.Transport.ReadStandardErrorAsync `
            $state.StderrBuffer 0 $readCount
        if ($task -isnot [Threading.Tasks.Task]) {
            throw 'Instruction-graph batch stderr reader returned an invalid task.'
        }
        $state.StderrTask = $task
    }.GetNewClosure()
    $consumeStderrRead = {
        if ($null -eq $state.StderrTask) { return }
        $task = $state.StderrTask
        $state.StderrTask = $null
        [int]$read = $task.GetAwaiter().GetResult()
        if ($read -lt 0 -or $read -gt $state.StderrBuffer.Length) {
            throw 'Instruction-graph batch stderr reader returned an invalid length.'
        }
        if ($read -eq 0) {
            $state.StderrEof = $true
            return
        }
        if ($state.StderrBytes -gt
            ([long]$MaximumStandardErrorBytes - $read)) {
            throw 'Instruction-graph batch standard error exceeds its budget.'
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
                    $tasks = [Threading.Tasks.Task[]]@(
                        $state.StderrTask, $Task
                    )
                    [int]$completed = [Threading.Tasks.Task]::WaitAny(
                        $tasks, $remaining
                    )
                    if ($completed -lt 0) {
                        throw 'Instruction-graph batch session deadline exceeded.'
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
                        throw 'Instruction-graph batch session deadline exceeded.'
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
        $task = & $state.Transport.ReadStandardOutputAsync `
            $state.StdoutBuffer 0 $state.StdoutBuffer.Length
        if ($task -isnot [Threading.Tasks.Task]) {
            throw 'Instruction-graph batch stdout reader returned an invalid task.'
        }
        [int]$read = & $waitTask $task
        if ($read -lt 0 -or $read -gt $state.StdoutBuffer.Length) {
            throw 'Instruction-graph batch stdout reader returned an invalid length.'
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
                [int]$copy = [Math]::Min($available, $Buffer.Length - $written)
                [Array]::Copy($state.StdoutBuffer, $state.StdoutOffset,
                    $Buffer, $written, $copy)
                $state.StdoutOffset += $copy
                $written += $copy
                continue
            }
            $task = & $state.Transport.ReadStandardOutputAsync `
                $Buffer $written ($Buffer.Length - $written)
            if ($task -isnot [Threading.Tasks.Task]) {
                throw 'Instruction-graph batch stdout reader returned an invalid task.'
            }
            [int]$read = & $waitTask $task
            if ($read -le 0 -or $read -gt ($Buffer.Length - $written)) {
                throw 'Instruction-graph batch response ended before its declared payload.'
            }
            $written += $read
        }
    }.GetNewClosure()
    $ensureStarted = {
        if ($state.Lifecycle -cne 'NotStarted') { return }
        $state.StartedAt = & $getNow
        $transport = & $transportFactory $Repository
        if ($null -eq $transport) {
            throw 'Instruction-graph batch transport factory returned no transport.'
        }
        $state.Transport = $transport
        $actualNames = @($transport.PSObject.Properties.Name)
        [Array]::Sort($actualNames, [StringComparer]::Ordinal)
        $expectedNames = @($requiredTransportCallbacks)
        [Array]::Sort($expectedNames, [StringComparer]::Ordinal)
        if (($actualNames -join "`0") -cne ($expectedNames -join "`0")) {
            throw 'Instruction-graph batch transport callback shape is invalid.'
        }
        foreach ($callbackName in $requiredTransportCallbacks) {
            if ($transport.$callbackName -isnot [scriptblock]) {
                throw "Instruction-graph batch transport callback '$callbackName' is invalid."
            }
        }
        if (-not (& $transport.Start)) {
            throw 'Unable to start exact instruction-graph batch acquisition.'
        }
        $state.ProcessStarted = $true
        $state.ProcessStarts++
        $state.Lifecycle = 'Running'
        & $startStderrRead
    }.GetNewClosure()
    $getGitBlobSha = {
        param([Parameter(Mandatory)][byte[]]$Bytes)

        $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
        $combined = [byte[]]::new($header.Length + $Bytes.Length)
        [Array]::Copy($header, 0, $combined, 0, $header.Length)
        [Array]::Copy($Bytes, 0, $combined, $header.Length, $Bytes.Length)
        $sha = [Security.Cryptography.SHA1]::Create()
        try {
            return ([BitConverter]::ToString(
                $sha.ComputeHash($combined)
            )).Replace('-', '').ToLowerInvariant()
        }
        finally { $sha.Dispose() }
    }.GetNewClosure()

    $readBlob = {
        param([Parameter(Mandatory)]$Entry)

        if ($state.Busy) {
            $state.Lifecycle = 'Faulted'
            throw 'Instruction-graph batch session does not allow reentrant reads.'
        }
        if ($state.Lifecycle -ceq 'Faulted' -or
            $state.Lifecycle -ceq 'Aborted' -or
            $state.Lifecycle -ceq 'Completed') {
            throw "Instruction-graph batch session is terminal: $($state.Lifecycle)."
        }
        $state.Busy = $true
        try {
            if ([string]$Entry.Type -cne 'blob' -or
                @('100644', '100755') -cnotcontains [string]$Entry.Mode -or
                [string]$Entry.Sha -cnotmatch '^[0-9a-f]{40}$') {
                throw "Instruction graph entry '$([string]$Entry.Path)' is not a canonical regular blob."
            }
            & $ensureStarted
            $requestBytes = [byte[]]::new(41)
            $oidBytes = [Text.Encoding]::ASCII.GetBytes([string]$Entry.Sha)
            [Array]::Copy($oidBytes, 0, $requestBytes, 0, 40)
            $requestBytes[40] = 10
            $writeTask = & $state.Transport.WriteInputAsync `
                $requestBytes 0 $requestBytes.Length
            if ($writeTask -isnot [Threading.Tasks.Task]) {
                throw 'Instruction-graph batch stdin writer returned an invalid task.'
            }
            [void](& $waitTask $writeTask)
            if ($state.Lifecycle -cne 'Running') {
                throw 'Instruction-graph batch session faulted during a reentrant read.'
            }
            $flushTask = & $state.Transport.FlushInputAsync
            if ($flushTask -isnot [Threading.Tasks.Task]) {
                throw 'Instruction-graph batch stdin flusher returned an invalid task.'
            }
            [void](& $waitTask $flushTask)
            if ($state.Lifecycle -cne 'Running') {
                throw 'Instruction-graph batch session faulted during a reentrant read.'
            }
            $state.Requests++

            $headerBytes = [System.Collections.Generic.List[byte]]::new()
            while ($true) {
                [int]$value = & $readOutputByte
                if ($value -lt 0) {
                    throw 'Instruction-graph batch response ended before its header.'
                }
                if ($value -eq 10) { break }
                if ($value -gt 127 -or $headerBytes.Count -ge $MaximumHeaderBytes) {
                    throw 'Instruction-graph batch response header is invalid or over budget.'
                }
                $headerBytes.Add([byte]$value)
            }
            $headerText = [Text.Encoding]::ASCII.GetString(
                $headerBytes.ToArray()
            )
            $headerMatch = [regex]::Match($headerText,
                '^(?<oid>[0-9a-f]{40}) blob (?<size>0|[1-9][0-9]*)$')
            if (-not $headerMatch.Success -or
                [string]$headerMatch.Groups['oid'].Value -cne
                    [string]$Entry.Sha) {
                throw 'Instruction-graph batch response identity or type is invalid.'
            }
            [long]$size = 0
            if (-not [long]::TryParse(
                [string]$headerMatch.Groups['size'].Value,
                [Globalization.NumberStyles]::None,
                [Globalization.CultureInfo]::InvariantCulture,
                [ref]$size
            ) -or $size -gt $MaximumBlobBytes -or
                $size -gt ([long]$MaximumAggregateBlobBytes -
                    $state.ResponseBytes) -or $size -gt [int]::MaxValue) {
                throw 'Instruction-graph batch response size exceeds its budget.'
            }
            $payload = [byte[]]::new([int]$size)
            if ($payload.Length -gt 0) { & $readOutputExact $payload }
            if ((& $readOutputByte) -ne 10) {
                throw 'Instruction-graph batch response is missing its exact LF trailer.'
            }
            if ((& $getGitBlobSha $payload) -cne [string]$Entry.Sha) {
                throw 'Instruction-graph batch payload does not match its exact tree identity.'
            }
            if ($state.Lifecycle -cne 'Running') {
                throw 'Instruction-graph batch session faulted during a reentrant read.'
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
        param([Parameter(Mandatory)]$Graph)

        if ($state.Busy -or $state.Lifecycle -ceq 'Faulted' -or
            $state.Lifecycle -ceq 'Aborted' -or
            $state.Lifecycle -ceq 'Completed') {
            throw "Instruction-graph batch session cannot complete from '$($state.Lifecycle)'."
        }
        try {
            if ($state.Lifecycle -ceq 'NotStarted') {
                if ([long]$Graph.counts.parsedBlobs -ne 0 -or
                    [long]$Graph.counts.parsedBlobBytes -ne 0) {
                    throw 'Instruction-graph batch zero-process evidence does not match the graph.'
                }
                $state.StderrMemory.Dispose()
                $state.Lifecycle = 'Completed'
                return
            }
            & $state.Transport.CloseInput
            if ((& $readOutputByte) -ne -1) {
                throw 'Instruction-graph batch response contains extra output.'
            }
            while (-not $state.StderrEof) {
                if ($null -eq $state.StderrTask) { & $startStderrRead }
                $stderrTask = $state.StderrTask
                $state.PendingPrimaryTask = $stderrTask
                [int]$remaining = & $getRemainingMilliseconds
                [int]$completed = [Threading.Tasks.Task]::WaitAny(
                    [Threading.Tasks.Task[]]@($stderrTask), $remaining
                )
                if ($completed -lt 0) {
                    throw 'Instruction-graph batch session deadline exceeded.'
                }
                $state.PendingPrimaryTask = $null
                & $consumeStderrRead
            }
            [int]$remaining = & $getRemainingMilliseconds
            if (-not (& $state.Transport.WaitForExit $remaining)) {
                throw 'Instruction-graph batch session deadline exceeded while reaping the child.'
            }
            if ((& $state.Transport.GetExitCode) -ne 0) {
                $stderrText = [Text.Encoding]::UTF8.GetString(
                    $state.StderrMemory.ToArray()
                )
                throw "Instruction-graph batch child failed: $stderrText"
            }
            if ($state.Requests -ne [long]$Graph.counts.parsedBlobs -or
                $state.ResponseBytes -ne
                    [long]$Graph.counts.parsedBlobBytes) {
                throw 'Instruction-graph batch request/byte evidence does not match the graph.'
            }
            & $state.Transport.Dispose
            $state.Transport = $null
            $state.StderrMemory.Dispose()
            $state.Lifecycle = 'Completed'
        }
        catch {
            $state.Lifecycle = 'Faulted'
            throw
        }
    }.GetNewClosure()

    $abort = {
        if ($state.Lifecycle -ceq 'Completed' -or
            $state.Lifecycle -ceq 'Aborted') { return }
        $cleanupProblems = [System.Collections.Generic.List[string]]::new()
        try {
            if ($null -ne $state.Transport) {
                $hasExited = $false
                if ($state.ProcessStarted) {
                    try { $hasExited = [bool](& $state.Transport.GetHasExited) }
                    catch { $cleanupProblems.Add($_.Exception.Message) }
                    if (-not $hasExited) {
                        try { & $state.Transport.Kill }
                        catch { $cleanupProblems.Add($_.Exception.Message) }
                        try {
                            if (-not (& $state.Transport.WaitForExit `
                                $AbortTimeoutMilliseconds)) {
                                $cleanupProblems.Add(
                                    'Instruction-graph batch child survived abort.'
                                )
                            }
                        }
                        catch { $cleanupProblems.Add($_.Exception.Message) }
                    }
                }
                foreach ($pending in @(
                    $state.PendingPrimaryTask, $state.StderrTask
                )) {
                    if ($null -ne $pending -and -not $pending.IsCompleted) {
                        $cleanupProblems.Add(
                            'Instruction-graph batch I/O task did not join after abort.'
                        )
                    }
                }
                try { & $state.Transport.Dispose }
                catch { $cleanupProblems.Add($_.Exception.Message) }
                $state.Transport = $null
            }
        }
        finally {
            $state.StderrMemory.Dispose()
            $state.Lifecycle = 'Aborted'
        }
        if ($cleanupProblems.Count -gt 0) {
            throw ($cleanupProblems -join ' ')
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

function Get-QuickAdoptionInstructionGraph {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    $entries = @(Get-QuickAdoptionInstructionGraphTreeEntries `
        -Repository $Repository -Commit $Commit)
    $limitsCommand = Get-InitialAdoptionPolicyCommand `
        -Name 'Get-MeAndAIInstructionGraphLimits'
    $limits = & $limitsCommand
    $builder = Get-InitialAdoptionPolicyCommand `
        -Name 'New-MeAndAIInstructionGraph'
    $validator = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAIExactInstructionGraph'
    $session = New-QuickAdoptionInstructionGraphBatchSession `
        -Repository $Repository `
        -MaximumBlobBytes ([long]$limits.MaximumBlobBytes) `
        -MaximumAggregateBlobBytes ([long]$limits.MaximumAggregateBlobBytes) `
        -SessionTimeoutMilliseconds 120000 `
        -AbortTimeoutMilliseconds 5000 `
        -MaximumHeaderBytes 128 `
        -MaximumStandardErrorBytes 65536
    $primaryFailure = $null
    $cleanupFailure = $null
    $graph = $null
    try {
        $graph = & $builder -BaseHead $Commit -TreeEntries $entries `
            -ReadBlob $session.ReadBlob
        & $session.Complete $graph
        if (-not (& $validator -Graph $graph)) {
            throw 'Exact instruction-graph discovery returned an invalid graph.'
        }
    }
    catch { $primaryFailure = $_.Exception }
    finally {
        try { & $session.Abort }
        catch { $cleanupFailure = $_.Exception }
    }
    if ($null -ne $primaryFailure) {
        if ($null -ne $cleanupFailure) {
            throw ($primaryFailure.Message + ' Cleanup failed: ' +
                $cleanupFailure.Message)
        }
        throw $primaryFailure
    }
    if ($null -ne $cleanupFailure) { throw $cleanupFailure }
    return $graph
}

function Get-QuickAdoptionWorkingTreePaths {
    param([Parameter(Mandatory)][string]$Root)

    $paths = [System.Collections.Generic.List[string]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $maximumRelevantCount =
        [int]$script:InitialAdoptionPolicy.Limits.MaximumSurfaceCount +
        $adoptionCanonicalTargetPaths.Count + 2
    # Traverse the no-HEAD tree once so every retained path uses its actual
    # casing. Do not follow repository metadata or reparse points, and fail
    # closed at finite directory/entry ceilings instead of assuming freshness.
    $pendingDirectories = [System.Collections.Generic.Queue[string]]::new()
    $pendingDirectories.Enqueue($Root)
    $directoryCount = 0
    $entryCount = 0
    while ($pendingDirectories.Count -gt 0) {
        $directory = $pendingDirectories.Dequeue()
        $directoryCount++
        if ($directoryCount -gt $protocolSurfaceTraversalMaximumDirectoryCount) {
            throw 'Protocol working-tree assessment exceeds the bounded directory budget; maintainer review is required.'
        }
        foreach ($item in @(Get-ChildItem -LiteralPath $directory -Force)) {
            $entryCount++
            if ($entryCount -gt $protocolSurfaceTraversalMaximumEntryCount) {
                throw 'Protocol working-tree assessment exceeds the bounded entry budget; maintainer review is required.'
            }
            $relativePath = $item.FullName.Substring($Root.Length).TrimStart('\', '/') `
                -replace '\\', '/'
            if ($item.PSIsContainer) {
                if ($item.Name.Equals('.git', [StringComparison]::OrdinalIgnoreCase)) {
                    continue
                }
                Assert-QuickAdoptionCanonicalPathCasing -Path $relativePath
                if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "A repository without a committed HEAD may contain only the two local credential files and the exact canonical seed workflow; linked directory '$relativePath' must be removed or replaced with committed project history before adoption."
                }
                $pendingDirectories.Enqueue($item.FullName)
                continue
            }
            Assert-QuickAdoptionCanonicalPathCasing -Path $relativePath
            $allowedUncommittedSeedInput = $relativePath -ceq $workflowTargetPath -or
                @($tokenMappings.Keys | Where-Object {
                    $relativePath -ceq [string]$_
                }).Count -eq 1
            if (-not $allowedUncommittedSeedInput) {
                throw "A repository without a committed HEAD may contain only the two local credential files and the exact canonical seed workflow; commit project files before adoption. Unexpected path: '$relativePath'."
            }
            if (-not (Test-QuickAdoptionAssessmentRelevantPath -Path $relativePath `
                -TargetPaths $adoptionCanonicalTargetPaths)) {
                continue
            }
            [void](Assert-ContainedManagedDestination -Root $Root `
                -RelativePath $relativePath)
            if (-not $seenPaths.Add($relativePath)) {
                throw "Protocol inventory path '$relativePath' is case-ambiguous."
            }
            $paths.Add($relativePath)
            if ($paths.Count -gt $maximumRelevantCount) {
                throw 'Protocol inventory exceeds the bounded assessment budget; maintainer review is required.'
            }
        }
    }
    return @($paths)
}

function Assert-QuickAdoptionSeedWorkflowPathIdentity {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Paths)

    $matches = @($Paths | Where-Object {
        ([string]$_).Equals(
            $workflowTargetPath, [StringComparison]::OrdinalIgnoreCase
        )
    })
    if ($matches.Count -gt 1 -or
        ($matches.Count -eq 1 -and [string]$matches[0] -cne $workflowTargetPath)) {
        throw "The lifecycle seed workflow path must be exactly '$workflowTargetPath'; remove case variants before adoption."
    }
}

function Test-QuickAdoptionCompletedConsumerCandidate {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$HeadSha
    )

    $manifestEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path $adoptionManifestPath
    if ($manifestEntry.Path) {
        return $false
    }
    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path '.ai/protocol'
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit') {
        return $false
    }
    $requiredAssets = @(
        [pscustomobject]@{ Path = '.gitmodules'; Mode = '100644'; Type = 'blob' }
    ) + @($managedUpdaterAssets | ForEach-Object {
        [pscustomobject]@{
            Path = [string]$_.ConsumerPath
            Mode = '100644'
            Type = 'blob'
        }
    })
    foreach ($asset in $requiredAssets) {
        $entry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $HeadSha -Path ([string]$asset.Path)
        if ($entry.Mode -cne [string]$asset.Mode -or
            $entry.Type -cne [string]$asset.Type) {
            return $false
        }
    }
    return $true
}

function Assert-QuickAdoptionSeedWorkflowCandidate {
    param(
        [Parameter(Mandatory)][string]$Root,
        [AllowEmptyString()][string]$Commit = ''
    )

    $text = if ($Commit) {
        $entry = Get-AdoptionTreeEntry -Repository $Root -Commit $Commit `
            -Path $workflowTargetPath
        if (-not $entry.Path) { return $false }
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob') {
            throw 'The seed workflow candidate is not one regular committed file.'
        }
        (@(Invoke-Git -Repository $Root -Arguments @(
            'show', "${Commit}:$workflowTargetPath"
        )).Output -join "`n")
    }
    else {
        $path = Assert-ContainedManagedDestination -Root $Root `
            -RelativePath $workflowTargetPath
        if (-not (Test-Path -LiteralPath $path)) { return $false }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw 'The seed workflow candidate is not one regular file.'
        }
        [IO.File]::ReadAllText($path)
    }
    $names = [regex]::Matches(
        $text, '(?m)^name: meAndAI AI capabilities lifecycle\r?$'
    )
    $tags = [regex]::Matches(
        $text,
        '(?m)^  BOOTSTRAP_PROTOCOL_TAG: (?<tag>v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))\r?$'
    )
    if ($names.Count -ne 1 -or $tags.Count -ne 1 -or
        [string]$tags[0].Groups['tag'].Value -cne $ProtocolTag) {
        throw "The existing seed workflow candidate is not recognizable as the $ProtocolTag launcher seed."
    }
    return $true
}

function Get-QuickAdoptionPreflightAssessment {
    param([Parameter(Mandatory)][string]$Root)

    $inside = Invoke-Git -Repository $Root `
        -Arguments @('rev-parse', '--is-inside-work-tree') -AllowFailure
    $headSha = ''
    $paths = @()
    $completedCandidate = $false
    $instructionGraph = $null
    if ($inside.ExitCode -eq 0 -and
        ((@($inside.Output) -join '').Trim() -ceq 'true')) {
        $rootResult = Invoke-Git -Repository $Root `
            -Arguments @('rev-parse', '--show-toplevel')
        $gitRoot = Get-NormalizedPath -Path ((@($rootResult.Output) -join '').Trim())
        if (-not $gitRoot.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'TargetPath is nested inside another Git repository; select that repository root explicitly.'
        }
        # Credential containment is part of the mutation-free preflight. A
        # tracked-but-clean token file does not appear in porcelain status, so
        # reject tracked, staged, shallow, or reachable-history evidence before
        # gh authentication or .git/info/exclude reconciliation can run.
        Assert-TokenFilesAreLocalOnly -Repository $Root
        $headResult = Invoke-Git -Repository $Root `
            -Arguments @('rev-parse', '--verify', 'HEAD') -AllowFailure
        if ($headResult.ExitCode -eq 0) {
            $headSha = ((@($headResult.Output) -join '').Trim())
            if ($headSha -cnotmatch '^[0-9a-f]{40}$') {
                throw 'The initial-adoption preflight resolved an invalid HEAD.'
            }
            $statusLines = @((Invoke-Git -Repository $Root -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
            foreach ($line in $statusLines) {
                $isLocalCredential = @($tokenMappings.Keys | Where-Object {
                    $line -ceq "?? $_"
                }).Count -eq 1
                $isSeedCandidate = $line -ceq "?? $workflowTargetPath" -or
                    $line -ceq "A  $workflowTargetPath"
                if (-not $isLocalCredential -and -not $isSeedCandidate) {
                    throw 'Commit or discard working-tree changes before initial-adoption strategy assessment.'
                }
            }
            $paths = @(Get-QuickAdoptionRelevantTreePaths -Repository $Root `
                -Commit $headSha -TargetPaths $adoptionCanonicalTargetPaths)
            Assert-AdoptionReservedProtocolSubmoduleAvailable `
                -Repository $Root -Commit $headSha
            $completedCandidate = Test-QuickAdoptionCompletedConsumerCandidate `
                -Repository $Root -HeadSha $headSha
            if (-not $completedCandidate) {
                # Completed consumers retain their existing current/update
                # route. Graph-aware initial-adoption policy is prospective
                # and must not retroactively reassess a completed topology.
                $instructionGraph = Get-QuickAdoptionInstructionGraph `
                    -Repository $Root -Commit $headSha
                $hasWorkingSeed = @($statusLines | Where-Object {
                    $_ -ceq "?? $workflowTargetPath" -or
                    $_ -ceq "A  $workflowTargetPath"
                }).Count -gt 0
                if ($hasWorkingSeed) {
                    [void](Assert-QuickAdoptionSeedWorkflowCandidate -Root $Root)
                }
                else {
                    [void](Assert-QuickAdoptionSeedWorkflowCandidate `
                        -Root $Root -Commit $headSha)
                }
            }
            $protocolEntry = Get-AdoptionTreeEntry -Repository $Root `
                -Commit $headSha -Path '.ai/protocol'
            if ($protocolEntry.Mode -ceq '160000' -and -not $completedCandidate) {
                throw 'A protocol gitlink candidate exists with an incomplete managed adoption footprint; reconcile it before rerunning.'
            }
        }
        else {
            $paths = @(Get-QuickAdoptionWorkingTreePaths -Root $Root)
            [void](Assert-QuickAdoptionSeedWorkflowCandidate -Root $Root)
        }
    }
    else {
        $paths = @(Get-QuickAdoptionWorkingTreePaths -Root $Root)
        [void](Assert-QuickAdoptionSeedWorkflowCandidate -Root $Root)
    }

    Assert-QuickAdoptionSeedWorkflowPathIdentity -Paths $paths
    $surfaces = @(
        if ($completedCandidate) { @() }
        elseif ($null -ne $instructionGraph) {
            @($instructionGraph.protocolSurfaces)
        }
        else { Get-QuickAdoptionProtocolSurfaceInventory -Paths $paths }
    )
    $collisions = @(
        if ($completedCandidate) { @() }
        else { Get-QuickAdoptionCanonicalCollisions -Paths $paths }
    )
    if (-not $headSha -and ($surfaces.Count -gt 0 -or $collisions.Count -gt 0)) {
        throw 'Uncommitted protocol or governance evidence cannot be handed to the isolated adoption clone; commit the repository history before migration.'
    }
    return [pscustomobject]@{
        SchemaVersion = if ($null -eq $instructionGraph) { 2 } else { 3 }
        HeadSha = $headSha
        ProtocolSurfaces = @($surfaces)
        Collisions = @($collisions)
        CompletedConsumerCandidate = [bool]$completedCandidate
        InstructionGraph = $instructionGraph
        GraphBase = if ($null -eq $instructionGraph) {
            ''
        }
        else { [string]$instructionGraph.baseHead }
        GraphDigest = if ($null -eq $instructionGraph) {
            ''
        }
        else { [string]$instructionGraph.digest }
    }
}

function Assert-QuickAdoptionPreflightAssessmentUnchanged {
    param(
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    if ([long]$Actual.SchemaVersion -ne [long]$Expected.SchemaVersion -or
        [string]$Actual.HeadSha -cne [string]$Expected.HeadSha -or
        [string]$Actual.GraphBase -cne [string]$Expected.GraphBase -or
        [string]$Actual.GraphDigest -cne [string]$Expected.GraphDigest -or
        [bool]$Actual.CompletedConsumerCandidate -ne
            [bool]$Expected.CompletedConsumerCandidate -or
        -not (Test-ExactOrdinalPathSet `
            -Actual @($Actual.ProtocolSurfaces) `
            -Expected @($Expected.ProtocolSurfaces)) -or
        -not (Test-ExactOrdinalPathSet `
            -Actual @($Actual.Collisions) -Expected @($Expected.Collisions))) {
        throw $FailureMessage
    }
}

function Resolve-QuickAdoptionStrategy {
    param(
        [Parameter(Mandatory)]$Assessment,
        [Parameter(Mandatory)][string]$RequestedStrategy,
        [Parameter(Mandatory)][bool]$IsNonInteractive,
        [Parameter(Mandatory)][bool]$LossAcknowledged
    )

    if ($Assessment.CompletedConsumerCandidate) {
        if ($RequestedStrategy -cne 'Auto' -or $LossAcknowledged) {
            throw 'Initial-adoption strategy options do not apply to a completed meAndAI consumer.'
        }
        return [pscustomobject]@{
            State = 'DeferredCompletedConsumer'
            AdoptionStrategy = 'LegacyUnspecified'
            ProtocolSurfaces = @()
            ProtocolRecordLossAcknowledged = $false
        }
    }

    $surfaces = @($Assessment.ProtocolSurfaces)
    $collisions = @($Assessment.Collisions)
    $resolvedRequest = $RequestedStrategy
    if ($resolvedRequest -ceq 'Auto' -and $surfaces.Count -gt 0) {
        if ($IsNonInteractive -or [Console]::IsInputRedirected) {
            throw 'Existing protocol or governance evidence requires an explicit adoption strategy in non-interactive mode.'
        }
        Write-Host 'Detected protocol/governance surfaces:'
        @($surfaces | ForEach-Object { Write-Host "  - $_" })
        Write-Host 'Canonical adoption collisions:'
        @($collisions | ForEach-Object { Write-Host "  - $_" })
        $choice = Read-Host 'Choose FullMigration (F), HybridReconciliation (H), CleanStart (C), or Abort (A)'
        $resolvedRequest = switch -CaseSensitive ($choice) {
            { $_ -cin @('F', 'FullMigration') } { 'FullMigration'; break }
            { $_ -cin @('H', 'HybridReconciliation') } { 'HybridReconciliation'; break }
            { $_ -cin @('C', 'CleanStart') } { 'CleanStart'; break }
            { $_ -cin @('A', 'Abort') } { 'Abort'; break }
            default { throw 'The interactive adoption strategy selection was not recognized.' }
        }
    }
    if ($resolvedRequest -ceq 'CleanStart' -and $surfaces.Count -gt 0 -and
        -not $LossAcknowledged) {
        if ($IsNonInteractive -or [Console]::IsInputRedirected) {
            throw 'CleanStart requires explicit acknowledgement of protocol record loss.'
        }
        $confirmation = Read-Host 'Type CLEANSTART to acknowledge that detected governance records may be discarded'
        if ($confirmation -cne 'CLEANSTART') {
            throw 'CleanStart protocol record loss was not acknowledged exactly.'
        }
        $LossAcknowledged = $true
    }

    $resolver = Get-InitialAdoptionPolicyCommand `
        -Name 'Resolve-MeAndAIAdoptionStrategy'
    $result = & $resolver -RequestedStrategy $resolvedRequest `
        -ProtocolSurfaces @($surfaces) -Collisions @($collisions) `
        -AcknowledgeProtocolRecordLoss ([bool]$LossAcknowledged)
    if ($null -eq $result -or $result -is [array] -or
        [string]$result.State -cnotin @('Resolved', 'Aborted')) {
        $diagnostic = @()
        if ($null -ne $result -and $result -isnot [array] -and
            $null -ne $result.PSObject.Properties['Diagnostics']) {
            $diagnostic = @($result.Diagnostics | Where-Object { $_ } |
                Select-Object -First 1)
        }
        if ($diagnostic.Count -eq 1) {
            throw [string]$diagnostic[0]
        }
        throw 'The exact initial-adoption policy could not resolve the requested strategy.'
    }
    return [pscustomobject]@{
        State = [string]$result.State
        AdoptionStrategy = [string]$result.AdoptionStrategy
        ProtocolSurfaces = @($result.ProtocolSurfaces)
        ProtocolRecordLossAcknowledged =
            [bool]$result.ProtocolRecordLossAcknowledged
    }
}

function Get-AdoptionTreeEntry {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Path,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one adoption tree source must be selected.'
    }
    $result = if ($UseIndex) {
        Invoke-Git -Repository $Repository -Arguments @('ls-files', '--stage', '--', $Path)
    }
    else {
        Invoke-Git -Repository $Repository -Arguments @('ls-tree', $Commit, '--', $Path)
    }
    $lines = @($result.Output | Where-Object { $_ })
    $empty = [pscustomobject]@{ Mode = ''; Type = ''; Sha = ''; Path = '' }
    if ($lines.Count -ne 1) {
        return $empty
    }
    $pattern = if ($UseIndex) {
        '^(?<mode>[0-9]{6})\s+(?<sha>[0-9a-f]{40})\s+0\t(?<path>.+)$'
    }
    else {
        '^(?<mode>[0-9]{6})\s+(?<type>[^\s]+)\s+(?<sha>[0-9a-f]{40})\t(?<path>.+)$'
    }
    $match = [regex]::Match([string]$lines[0], $pattern)
    if (-not $match.Success -or [string]$match.Groups['path'].Value -cne $Path) {
        return $empty
    }
    return [pscustomobject]@{
        Mode = [string]$match.Groups['mode'].Value
        Type = if ($UseIndex) { 'blob' } else { [string]$match.Groups['type'].Value }
        Sha = [string]$match.Groups['sha'].Value
        Path = [string]$match.Groups['path'].Value
    }
}

function Get-SingleCommitParent {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    $line = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-list', '--parents', '-n', '1', $Commit
    )).Output -join '').Trim())
    $parts = @($line -split ' ' | Where-Object { $_ })
    if ($parts.Count -ne 2 -or $parts[0] -cne $Commit -or
        $parts[1] -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption proposal must contain one exact parent commit.'
    }
    return $parts[1]
}

function Get-ExpectedAdoptionManifestContract {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string[]]$TargetPaths
    )

    $baseHead = Get-SingleCommitParent -Repository $Repository -Commit $ProposalHead
    $basePaths = @(Get-QuickAdoptionRelevantTreePaths -Repository $Repository `
        -Commit $baseHead -TargetPaths $TargetPaths)
    $pathLookup = [System.Collections.Generic.Dictionary[string, string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($path in $basePaths) {
        if ([string]::IsNullOrWhiteSpace($path) -or $pathLookup.ContainsKey($path)) {
            throw "The adoption proposal parent contains an empty or case-ambiguous path '$path'."
        }
        $pathLookup.Add($path, $path)
    }
    if ($pathLookup.ContainsKey($adoptionManifestPath)) {
        throw 'The adoption proposal parent already contains the transient adoption manifest.'
    }

    $collisions = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $TargetPaths) {
        $collisionFound = $pathLookup.ContainsKey($path) -or
            @($basePaths | Where-Object {
                $_.StartsWith("$path/", [StringComparison]::OrdinalIgnoreCase) -or
                $path.StartsWith("$($_)/", [StringComparison]::OrdinalIgnoreCase)
            }).Count -gt 0
        if ($collisionFound) {
            $collisions.Add([string]$path)
        }
    }
    $protocolSurfaces = @(
        Get-QuickAdoptionProtocolSurfaceInventory -Paths $basePaths
    )
    $updaterCount = @($adoptionUpdaterAssets | Where-Object {
        $pathLookup.ContainsKey([string]$_.ConsumerPath)
    }).Count
    return [pscustomobject]@{
        BaseHead = $baseHead
        BasePaths = @($basePaths)
        LocalUpdaterState = if ($updaterCount -eq 0) {
            'Absent'
        }
        elseif ($updaterCount -eq $adoptionUpdaterAssets.Count) { 'Complete' }
        else { 'Partial' }
        Collisions = @($collisions)
        ProtocolSurfaces = @($protocolSurfaces)
    }
}

function Get-ExactProtocolSourceBlobSha {
    param(
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$TemplatePath
    )

    $sourcePath = Join-Path $ProtocolSource `
        ($TemplatePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Exact protocol source is missing asset '$TemplatePath'."
    }
    if (Test-Path -LiteralPath (Join-Path $ProtocolSource '.git')) {
        $sourceEntry = Get-AdoptionTreeEntry -Repository $ProtocolSource `
            -Commit $ProtocolSha -Path $TemplatePath
        if ($sourceEntry.Mode -cne '100644' -or $sourceEntry.Type -cne 'blob') {
            throw "Exact protocol source asset '$TemplatePath' is not a regular blob."
        }
        return [string]$sourceEntry.Sha
    }
    return & $script:GetQuickAdoptionGitBlobSha1 `
        -Bytes ([IO.File]::ReadAllBytes($sourcePath))
}

function Get-ExactConsumerMigrationBaseline {
    param(
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    $contentIdentitySha = Get-ExactProtocolSourceBlobSha `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
        -TemplatePath $consumerMigrationContentIdentityPath
    $moduleSha = Get-ExactProtocolSourceBlobSha `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
        -TemplatePath $consumerMigrationModulePath
    $indexSha = Get-ExactProtocolSourceBlobSha `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
        -TemplatePath $consumerMigrationIndexPath
    $modulePath = Join-Path $ProtocolSource `
        ($consumerMigrationModulePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $indexPath = Join-Path $ProtocolSource `
        ($consumerMigrationIndexPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $modules = @(Import-Module -Name $modulePath -Force -PassThru)
    if ($modules.Count -ne 1) {
        throw 'The exact protocol consumer migration module could not be loaded unambiguously.'
    }
    $module = $modules[0]
    try {
        $importCatalog = $module.ExportedCommands[
            'Import-MeAndAIConsumerMigrationCatalog'
        ]
        $newBaseline = $module.ExportedCommands[
            'New-MeAndAIConsumerMigrationBaseline'
        ]
        if ($null -eq $importCatalog -or $null -eq $newBaseline) {
            throw 'The exact protocol consumer migration module lacks its baseline contract.'
        }
        $catalog = & $importCatalog -IndexPath $indexPath
        if ([string]$catalog.IndexBlob -cne $indexSha -or
            $moduleSha -cnotmatch '^[0-9a-f]{40}$' -or
            $contentIdentitySha -cnotmatch '^[0-9a-f]{40}$') {
            throw 'The exact protocol consumer migration catalog, engine, or identity dependency is not immutable.'
        }
        foreach ($migration in @($catalog.Migrations)) {
            $definitionPath = "migrations/$([string]$migration.Definition)"
            $definitionSha = Get-ExactProtocolSourceBlobSha `
                -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
                -TemplatePath $definitionPath
            if ($definitionSha -cne [string]$migration.DefinitionBlob) {
                throw "Consumer migration definition '$definitionPath' differs from the exact protocol source."
            }
        }
        $baseline = & $newBaseline -Catalog $catalog
        if ([string]$baseline.Path -cne $consumerMigrationLedgerPath -or
            $baseline.Bytes -isnot [byte[]] -or
            [string]$baseline.Blob -cnotmatch '^[0-9a-f]{40}$') {
            throw 'The exact protocol produced an invalid consumer migration baseline.'
        }
        return $baseline
    }
    finally {
        Remove-Module -Name ([string]$module.Name) -Force `
            -ErrorAction SilentlyContinue
    }
}

function Assert-AdoptionUpdaterAssetsExact {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one updater validation tree source must be selected.'
    }
    foreach ($asset in $adoptionUpdaterAssets) {
        $sourceSha = Get-ExactProtocolSourceBlobSha -ProtocolSource $ProtocolSource `
            -ProtocolSha $ProtocolSha -TemplatePath ([string]$asset.TemplatePath)
        $consumerEntry = if ($UseIndex) {
            Get-AdoptionTreeEntry -Repository $Repository -Path ([string]$asset.ConsumerPath) `
                -UseIndex
        }
        else {
            Get-AdoptionTreeEntry -Repository $Repository -Path ([string]$asset.ConsumerPath) `
                -Commit $Commit
        }
        if ($consumerEntry.Mode -cne '100644' -or $consumerEntry.Type -cne 'blob' -or
            $consumerEntry.Sha -cne $sourceSha) {
            throw "Consumer updater asset '$($asset.ConsumerPath)' does not match the exact protocol source."
        }
    }
}

function Test-ExactOrdinalPathSet {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Actual,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Expected
    )

    if ($Actual.Count -ne $Expected.Count) {
        return $false
    }
    $remaining = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $Expected) {
        if (-not $remaining.Add([string]$path)) {
            return $false
        }
    }
    foreach ($path in $Actual) {
        if (-not $remaining.Remove([string]$path)) {
            return $false
        }
    }
    return $remaining.Count -eq 0
}

function Assert-ExactAdoptionProposal {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
        [Parameter(Mandatory)][ValidateSet('Full', 'ManifestOnly')]
        [string]$ProposalMode,
        [Parameter(Mandatory)][string[]]$TargetPaths,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    if ($CanonicalBaseHead -cnotmatch '^[0-9a-f]{40}$' -or
        $ProtocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The exact adoption proposal received an invalid base or protocol commit.'
    }
    $proposalParent = Get-SingleCommitParent -Repository $Repository `
        -Commit $ProposalHead
    if ($proposalParent -cne $CanonicalBaseHead) {
        throw 'The adoption proposal is not based on the canonical consumer head.'
    }

    $mappedTargetPaths = @(
        '.gitmodules', '.ai/protocol', $consumerMigrationLedgerPath
    ) + @(
        $adoptionAssets | ForEach-Object { [string]$_.ConsumerPath }
    )
    if (-not (Test-ExactOrdinalPathSet -Actual @($TargetPaths) `
        -Expected $mappedTargetPaths)) {
        throw 'The exact protocol target paths do not match the launcher asset mapping.'
    }
    $expectedChangedPaths = if ($ProposalMode -ceq 'Full') {
        @($TargetPaths) + @($adoptionManifestPath)
    }
    else {
        @($adoptionManifestPath)
    }
    Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--check', $CanonicalBaseHead, $ProposalHead, '--'
    ) | Out-Null
    $actualChangedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--no-renames', '--name-only', '--diff-filter=ACMRTD',
        $CanonicalBaseHead, $ProposalHead, '--'
    )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if (-not (Test-ExactOrdinalPathSet -Actual $actualChangedPaths `
        -Expected $expectedChangedPaths)) {
        throw 'The adoption proposal does not contain the exact lifecycle change set.'
    }

    if ($ProposalMode -ceq 'ManifestOnly') {
        return
    }

    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path '.ai/protocol'
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cne $ProtocolSha) {
        throw 'The exact adoption proposal protocol reference is not the pinned gitlink.'
    }

    $gitmodulesText = @(
        '[submodule ".ai/protocol"]',
        "`tpath = .ai/protocol",
        "`turl = https://github.com/$ProtocolRepository.git",
        ''
    ) -join "`n"
    $gitmodulesSha = & $script:GetQuickAdoptionGitBlobSha1 -Bytes (
        [Text.UTF8Encoding]::new($false).GetBytes($gitmodulesText)
    )
    $gitmodulesEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path '.gitmodules'
    if ($gitmodulesEntry.Mode -cne '100644' -or
        $gitmodulesEntry.Type -cne 'blob' -or
        $gitmodulesEntry.Sha -cne $gitmodulesSha) {
        throw 'The exact adoption proposal submodule metadata is not canonical.'
    }

    foreach ($asset in $adoptionAssets) {
        $sourceSha = Get-ExactProtocolSourceBlobSha `
            -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
            -TemplatePath ([string]$asset.TemplatePath)
        $proposalEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $ProposalHead -Path ([string]$asset.ConsumerPath)
        if ($proposalEntry.Mode -cne '100644' -or
            $proposalEntry.Type -cne 'blob' -or
            $proposalEntry.Sha -cne $sourceSha) {
            throw "Adoption proposal asset '$($asset.ConsumerPath)' does not match the exact protocol source."
        }
    }
    $migrationBaseline = Get-ExactConsumerMigrationBaseline `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha
    $ledgerEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path $consumerMigrationLedgerPath
    if ($ledgerEntry.Mode -cne '100644' -or
        $ledgerEntry.Type -cne 'blob' -or
        $ledgerEntry.Sha -cne [string]$migrationBaseline.Blob) {
        throw 'The adoption proposal consumer migration ledger is not the exact target baseline.'
    }
}
