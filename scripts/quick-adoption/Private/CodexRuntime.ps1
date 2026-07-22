# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function Set-AdoptionIssueReadyForReview {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Issue
    )

    Invoke-External -Command 'gh' -Arguments @(
        'issue', 'edit', [string]$Issue.number, '--repo', $Repository,
        '--remove-label', 'status:in-progress',
        '--add-label', 'status:needs-review'
    ) | Out-Null
}

function ConvertTo-ProcessArgument {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Value)

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void]$builder.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashes -gt 0) {
        [void]$builder.Append(('\' * ($backslashes * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function New-ExternalProcessRunner {
    param(
        [Parameter(Mandatory)]$CommandInfo,
        [string[]]$PrefixArguments = @(),
        [Parameter(Mandatory)][string]$Description
    )

    if ($CommandInfo.CommandType -eq [Management.Automation.CommandTypes]::Application) {
        $extension = [IO.Path]::GetExtension([string]$CommandInfo.Source)
        if ($extension -in @('.cmd', '.bat')) {
            if ($env:OS -cne 'Windows_NT' -or -not $env:ComSpec) {
                throw "The $Description resolved to a Windows command wrapper on a non-Windows host."
            }
            return [pscustomobject]@{
                Command = [string]$env:ComSpec
                PrefixArguments = @('/d', '/c', 'call', [string]$CommandInfo.Source) + @($PrefixArguments)
                Description = $Description
            }
        }
        return [pscustomobject]@{
            Command = [string]$CommandInfo.Source
            PrefixArguments = @($PrefixArguments)
            Description = $Description
        }
    }
    throw "The $Description must resolve to a native executable or command wrapper."
}

function Resolve-LocalCodexRunner {
    param(
        [string]$ExplicitCommand,
        [Parameter(Mandatory)][string]$FallbackVersion
    )

    if ($FallbackVersion -cnotmatch '^\d+\.\d+\.\d+$') {
        throw 'TemporaryCodexVersion must use the M.m.rev form.'
    }

    $installedName = if ($ExplicitCommand) { $ExplicitCommand } else { 'codex' }
    $installed = @(Get-Command $installedName -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq [Management.Automation.CommandTypes]::Application } |
        Select-Object -First 1)
    if ($installed.Count -eq 1) {
        return New-ExternalProcessRunner -CommandInfo $installed[0] `
            -Description 'installed local Codex CLI'
    }

    if ($ExplicitCommand) {
        throw "The explicitly selected Codex command '$ExplicitCommand' is not available."
    }

    $npxCandidates = @(Get-Command 'npx' -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq [Management.Automation.CommandTypes]::Application })
    $npx = if ($env:OS -eq 'Windows_NT') {
        @($npxCandidates | Where-Object { [IO.Path]::GetExtension([string]$_.Source) -ieq '.cmd' } |
            Select-Object -First 1)
    }
    else {
        @($npxCandidates | Select-Object -First 1)
    }
    if ($npx.Count -eq 1) {
        return New-ExternalProcessRunner -CommandInfo $npx[0] `
            -PrefixArguments @('-y', "@openai/codex@$FallbackVersion") `
            -Description "temporary @openai/codex@$FallbackVersion through npx"
    }

    throw 'Codex CLI is not installed and npx is unavailable for the pinned temporary fallback.'
}

function New-ExternalProcessContainment {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    if ($env:OS -cne 'Windows_NT') {
        return $null
    }
    $typeName = 'MeAndAI.QuickAdoption.ProcessJob'
    if ($null -eq ($typeName -as [type])) {
        try {
            Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace MeAndAI.QuickAdoption
{
    public sealed class ProcessJob : IDisposable
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct BasicLimits
        {
            public long PerProcessUserTimeLimit;
            public long PerJobUserTimeLimit;
            public uint LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public uint ActiveProcessLimit;
            public UIntPtr Affinity;
            public uint PriorityClass;
            public uint SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IoCounters
        {
            public ulong ReadOperationCount;
            public ulong WriteOperationCount;
            public ulong OtherOperationCount;
            public ulong ReadTransferCount;
            public ulong WriteTransferCount;
            public ulong OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct ExtendedLimits
        {
            public BasicLimits BasicLimitInformation;
            public IoCounters IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr CreateJobObject(IntPtr attributes, string name);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetInformationJobObject(
            IntPtr job, int informationClass, IntPtr information, uint length);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

        [DllImport("kernel32.dll")]
        private static extern bool CloseHandle(IntPtr handle);

        private IntPtr handle;

        private ProcessJob(IntPtr jobHandle)
        {
            handle = jobHandle;
        }

        public static ProcessJob TryCreate(Process process)
        {
            const uint KillOnJobClose = 0x00002000;
            const int ExtendedLimitInformation = 9;
            IntPtr job = CreateJobObject(IntPtr.Zero, null);
            if (job == IntPtr.Zero) return null;

            ExtendedLimits limits = new ExtendedLimits();
            limits.BasicLimitInformation.LimitFlags = KillOnJobClose;
            int size = Marshal.SizeOf(typeof(ExtendedLimits));
            IntPtr buffer = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(limits, buffer, false);
                if (!SetInformationJobObject(job, ExtendedLimitInformation, buffer, (uint)size) ||
                    !AssignProcessToJobObject(job, process.Handle))
                {
                    CloseHandle(job);
                    return null;
                }
                return new ProcessJob(job);
            }
            finally
            {
                Marshal.FreeHGlobal(buffer);
            }
        }

        public void Dispose()
        {
            IntPtr owned = handle;
            handle = IntPtr.Zero;
            if (owned != IntPtr.Zero) CloseHandle(owned);
        }
    }
}
'@ -ErrorAction Stop
        }
        catch {
            return $null
        }
    }
    try {
        return [MeAndAI.QuickAdoption.ProcessJob]::TryCreate($Process)
    }
    catch {
        return $null
    }
}

function Stop-ExternalProcessTree {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    try {
        if ($Process.HasExited) {
            return $true
        }
    }
    catch {
        return $false
    }

    $killTreeMethod = $Process.GetType().GetMethod(
        'Kill',
        [type[]]@([bool])
    )
    if ($null -ne $killTreeMethod) {
        try {
            [void]$killTreeMethod.Invoke($Process, [object[]]@($true))
        }
        catch { }
    }
    else {
        $descendants = [System.Collections.Generic.List[Diagnostics.Process]]::new()
        if ($env:OS -ceq 'Windows_NT') {
            $searcher = $null
            $records = $null
            try {
                $searcher = [System.Management.ManagementObjectSearcher]::new(
                    'SELECT ProcessId, ParentProcessId FROM Win32_Process'
                )
                $records = $searcher.Get()
                $childrenByParent = @{}
                foreach ($record in $records) {
                    $parentId = [int][uint32]$record.ParentProcessId
                    $processId = [int][uint32]$record.ProcessId
                    if (-not $childrenByParent.ContainsKey($parentId)) {
                        $childrenByParent[$parentId] = `
                            [System.Collections.Generic.List[int]]::new()
                    }
                    $childrenByParent[$parentId].Add($processId)
                }
                $pending = [System.Collections.Generic.Stack[int]]::new()
                $visited = [System.Collections.Generic.HashSet[int]]::new()
                $pending.Push($Process.Id)
                [void]$visited.Add($Process.Id)
                while ($pending.Count -gt 0) {
                    $parentId = $pending.Pop()
                    if (-not $childrenByParent.ContainsKey($parentId)) {
                        continue
                    }
                    foreach ($childId in $childrenByParent[$parentId]) {
                        if (-not $visited.Add($childId)) {
                            continue
                        }
                        try {
                            $child = [Diagnostics.Process]::GetProcessById($childId)
                            $descendants.Add($child)
                            $pending.Push($childId)
                        }
                        catch { }
                    }
                }
            }
            catch { }
            finally {
                if ($null -ne $records) { $records.Dispose() }
                if ($null -ne $searcher) { $searcher.Dispose() }
            }
        }

        try { $Process.Kill() } catch { }
        for ($index = $descendants.Count - 1; $index -ge 0; $index--) {
            try {
                if (-not $descendants[$index].HasExited) {
                    $descendants[$index].Kill()
                }
            }
            catch { }
        }
        foreach ($descendant in $descendants) {
            try { [void]$descendant.WaitForExit(5000) } catch { }
            finally { $descendant.Dispose() }
        }
    }

    try {
        [void]$Process.WaitForExit(5000)
        return $Process.HasExited
    }
    catch {
        return $false
    }
}

function Invoke-BoundedProcess {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string[]]$Arguments,
        [AllowEmptyString()][string]$StandardInput = '',
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription,
        [Parameter(Mandatory)][string]$Operation,
        [string]$ProgressActivity = '',
        [scriptblock]$OutputLineHandler = $null,
        [switch]$RequireProcessTreeContainment
    )

    $allArguments = @($Runner.PrefixArguments) + @($Arguments)
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$Runner.Command
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $argumentListProperty = $startInfo.GetType().GetProperty('ArgumentList')
    if ($null -ne $argumentListProperty) {
        $nativeArgumentList = $argumentListProperty.GetValue($startInfo, $null)
        foreach ($argument in $allArguments) {
            [void]$nativeArgumentList.Add([string]$argument)
        }
    }
    else {
        $startInfo.Arguments = (@($allArguments | ForEach-Object {
            ConvertTo-ProcessArgument -Value ([string]$_)
        }) -join ' ')
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $processStarted = $false
    $processContainment = $null
    try {
        if (-not $process.Start()) {
            throw "Unable to start $Operation."
        }
        $processStarted = $true
        $processContainment = New-ExternalProcessContainment -Process $process
        if ($RequireProcessTreeContainment -and $env:OS -ceq 'Windows_NT' -and
            $null -eq $processContainment) {
            [void](Stop-ExternalProcessTree -Process $process)
            throw "Unable to establish kill-on-close process-tree containment for $Operation."
        }
        $stdoutLines = [System.Collections.Generic.List[string]]::new()
        $stdoutReadTask = $process.StandardOutput.ReadLineAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if ($StandardInput) {
            $process.StandardInput.Write($StandardInput)
        }
        $process.StandardInput.Close()
        $completed = $false
        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        $nextHeartbeatMilliseconds = 15000
        while (-not $completed -and $stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
            while ($null -ne $stdoutReadTask -and $stdoutReadTask.IsCompleted) {
                $line = $stdoutReadTask.GetAwaiter().GetResult()
                if ($null -eq $line) {
                    $stdoutReadTask = $null
                    break
                }
                $stdoutLines.Add([string]$line)
                if ($null -ne $OutputLineHandler) {
                    [void](& $OutputLineHandler ([string]$line))
                }
                $stdoutReadTask = $process.StandardOutput.ReadLineAsync()
            }
            $remaining = [int][Math]::Max(
                1,
                [Math]::Min(200, $TimeoutMilliseconds - $stopwatch.ElapsedMilliseconds)
            )
            $completed = $process.WaitForExit($remaining)
            if (-not $completed -and $ProgressActivity -and
                $stopwatch.ElapsedMilliseconds -ge $nextHeartbeatMilliseconds) {
                $elapsed = [Math]::Floor($stopwatch.Elapsed.TotalSeconds)
                Set-QuickAdoptionChildProgress -Activity $ProgressActivity `
                    -Status "Elapsed: $elapsed second(s); limit: $TimeoutDescription"
                $nextHeartbeatMilliseconds += 15000
            }
        }
        $stopwatch.Stop()
        if (-not $completed) {
            $terminationConfirmed = Stop-ExternalProcessTree -Process $process
            if (-not $terminationConfirmed) {
                throw "$Operation exceeded the $TimeoutDescription limit, and process-tree termination could not be confirmed."
            }
            throw "$Operation exceeded the $TimeoutDescription limit and was terminated."
        }
        $process.WaitForExit()
        while ($null -ne $stdoutReadTask) {
            $line = $stdoutReadTask.GetAwaiter().GetResult()
            if ($null -eq $line) {
                $stdoutReadTask = $null
                break
            }
            $stdoutLines.Add([string]$line)
            if ($null -ne $OutputLineHandler) {
                [void](& $OutputLineHandler ([string]$line))
            }
            $stdoutReadTask = $process.StandardOutput.ReadLineAsync()
        }
        return [pscustomobject]@{
            ExitCode = [int]$process.ExitCode
            StdOut = [string](@($stdoutLines) -join [Environment]::NewLine)
            StdErr = [string]$stderrTask.GetAwaiter().GetResult()
        }
    }
    finally {
        if ($null -ne $processContainment) {
            try { $processContainment.Dispose() } catch { }
            $processContainment = $null
        }
        if ($processStarted) {
            $stillRunning = $false
            try { $stillRunning = -not $process.HasExited } catch { }
            if ($stillRunning -and
                -not (Stop-ExternalProcessTree -Process $process)) {
                Write-Warning "$Operation was interrupted, but child-process-tree termination could not be confirmed."
            }
        }
        if ($ProgressActivity) {
            Complete-QuickAdoptionChildProgress
        }
        $process.Dispose()
    }
}

function Get-ProcessFailureDetail {
    param([Parameter(Mandatory)]$Result)

    $detail = (@($Result.StdOut, $Result.StdErr) -join [Environment]::NewLine).Trim()
    if ($detail.Length -gt 1200) {
        $detail = $detail.Substring(0, 1200) + '...'
    }
    return $detail
}

function Get-LocalCodexFailureDetail {
    param([Parameter(Mandatory)]$Result)

    $details = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($line in @([string]$Result.StdOut -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        try { $event = $line | ConvertFrom-Json -ErrorAction Stop }
        catch { continue }
        $eventType = [string](Get-QuickAdoptionObjectProperty `
            -InputObject $event -Name 'type')
        $message = ''
        if ($eventType -ceq 'error') {
            $message = [string](Get-QuickAdoptionObjectProperty `
                -InputObject $event -Name 'message')
        }
        elseif ($eventType -ceq 'turn.failed') {
            $errorValue = Get-QuickAdoptionObjectProperty -InputObject $event -Name 'error'
            $message = if ($errorValue -is [string]) {
                [string]$errorValue
            }
            else {
                [string](Get-QuickAdoptionObjectProperty `
                    -InputObject $errorValue -Name 'message')
            }
        }
        elseif ($eventType -ceq 'item.completed') {
            $item = Get-QuickAdoptionObjectProperty -InputObject $event -Name 'item'
            if ([string](Get-QuickAdoptionObjectProperty `
                -InputObject $item -Name 'type') -ceq 'agent_message') {
                $message = [string](Get-QuickAdoptionObjectProperty `
                    -InputObject $item -Name 'text')
            }
        }
        $message = ConvertTo-QuickAdoptionDisplayText -Value $message -MaximumLength 300
        if ($message -and $seen.Add($message)) {
            $details.Add($message)
        }
    }

    $stderr = ConvertTo-QuickAdoptionDisplayText `
        -Value ([string]$Result.StdErr) -MaximumLength 600
    if ($stderr -and $seen.Add($stderr)) {
        $details.Add($stderr)
    }
    $detail = (@($details) -join ' | ').Trim()
    if (-not $detail) {
        return 'No structured error detail was emitted.'
    }
    if ($detail.Length -gt 1200) {
        return $detail.Substring(0, 1197) + '...'
    }
    return $detail
}

function Assert-LocalCodexLogin {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments @('login', 'status') `
        -TimeoutMilliseconds $TimeoutMilliseconds `
        -TimeoutDescription $TimeoutDescription `
        -Operation 'Local Codex authentication check'
    if ($result.ExitCode -ne 0) {
        $detail = Get-ProcessFailureDetail -Result $result
        throw "Local Codex authentication check failed with code $($result.ExitCode). $detail"
    }
}

function Get-ConfiguredWindowsSandboxMode {
    if ($env:OS -cne 'Windows_NT') {
        return ''
    }

    $codexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
    if ([string]::IsNullOrWhiteSpace($codexHome)) {
        $userProfile = [Environment]::GetFolderPath(
            [Environment+SpecialFolder]::UserProfile
        )
        $codexHome = Join-Path $userProfile '.codex'
    }
    $configPath = Join-Path $codexHome 'config.toml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return 'elevated'
    }

    $insideWindowsSection = $false
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($rawLine in [IO.File]::ReadAllLines($configPath)) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#', [StringComparison]::Ordinal)) {
            continue
        }
        $section = [regex]::Match($line, '^\[(?<name>[^\]]+)\]\s*(?:#.*)?$')
        if ($section.Success) {
            $insideWindowsSection = $section.Groups['name'].Value.Trim() -ceq 'windows'
            continue
        }
        if (-not $insideWindowsSection) {
            continue
        }
        $sandbox = [regex]::Match(
            $line,
            '^sandbox\s*=\s*[\"''](?<value>[^\"'']+)[\"'']\s*(?:#.*)?$'
        )
        if ($sandbox.Success) {
            $values.Add($sandbox.Groups['value'].Value)
            continue
        }
        if ($line -match '^sandbox\s*=') {
            throw "Codex config '$configPath' contains an invalid [windows].sandbox value."
        }
    }

    if ($values.Count -eq 0) {
        return 'elevated'
    }
    if ($values.Count -ne 1 -or $values[0] -cnotin @('elevated', 'unelevated')) {
        throw "Codex config '$configPath' must contain at most one supported [windows].sandbox value."
    }
    return $values[0]
}

function Assert-LocalCodexWorkspaceWrite {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds
    )

    if ($env:OS -cne 'Windows_NT') {
        return ''
    }

    $preferredMode = Get-ConfiguredWindowsSandboxMode
    $candidateModes = if ($preferredMode -ceq 'elevated') {
        @('elevated', 'unelevated')
    }
    else {
        @('unelevated')
    }
    $probeTimeout = [int][Math]::Min($TimeoutMilliseconds, 60000)
    $probeTimeoutDescription = "$([Math]::Ceiling($probeTimeout / 1000.0)) second(s)"
    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($mode in $candidateModes) {
        $probeName = ".meandai-codex-sandbox-probe-$([guid]::NewGuid().ToString('N')).tmp"
        $probePath = Join-Path $WorkingDirectory $probeName
        $probeScript = @(
            '$ErrorActionPreference = ''Stop'''
            '$probe = Join-Path (Get-Location).Path ''__MEANDAI_PROBE_NAME__'''
            '[IO.File]::WriteAllText($probe, ''meandai-workspace-write-probe'', [Text.UTF8Encoding]::new($false))'
            'if ([IO.File]::ReadAllText($probe) -cne ''meandai-workspace-write-probe'') { throw ''probe verification failed'' }'
            '[IO.File]::Delete($probe)'
        ) -join '; '
        $probeScript = $probeScript.Replace('__MEANDAI_PROBE_NAME__', $probeName)
        $result = $null
        try {
            $result = Invoke-BoundedProcess -Runner $Runner -Arguments @(
                'sandbox', '--config', "windows.sandbox=`"$mode`"",
                '-P', ':workspace', '-C', $WorkingDirectory,
                'powershell.exe', '-NoProfile', '-NonInteractive',
                '-Command', $probeScript
            ) -TimeoutMilliseconds $probeTimeout `
                -TimeoutDescription $probeTimeoutDescription `
                -Operation "Local Codex $mode Windows sandbox workspace-write preflight"
        }
        catch {
            $failures.Add("${mode}: $($_.Exception.Message)")
        }

        $residue = Test-Path -LiteralPath $probePath
        if ($residue) {
            Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
        }
        if ($null -ne $result -and $result.ExitCode -eq 0 -and -not $residue) {
            if ($mode -cne $preferredMode) {
                Write-Warning "Local Codex '$preferredMode' Windows sandbox failed its token-free workspace-write preflight; using '$mode' for this run."
            }
            Write-Host "Local Codex sandbox preflight succeeded with Windows '$mode' mode."
            return $mode
        }
        if ($null -ne $result) {
            $detail = Get-ProcessFailureDetail -Result $result
            if ($residue) {
                $detail = "Sandbox left its probe file behind. $detail".Trim()
            }
            $failures.Add("${mode}: exit $($result.ExitCode). $detail".Trim())
        }
    }

    $failureText = (@($failures) -join ' | ')
    throw "Local Codex cannot write inside its native Windows workspace sandbox; semantic adoption was not started. Verify the Codex [windows].sandbox configuration or run Codex sandbox setup, then rerun. $failureText"
}

function Invoke-LocalCodexExec {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription,
        [string]$WindowsSandboxMode = ''
    )

    # codex exec receives the scoped prompt through stdin and is bounded by the launcher.
    $arguments = @(
        'exec',
        '--ephemeral',
        '--ignore-user-config',
        '--sandbox', 'workspace-write',
        '--config', 'approval_policy="never"',
        '--config', 'sandbox_workspace_write.network_access=false',
        '--config', 'shell_environment_policy.inherit="core"'
    )
    if ($WindowsSandboxMode) {
        $arguments += @('--config', "windows.sandbox=`"$WindowsSandboxMode`"")
    }
    $arguments += @(
        '--cd', $WorkingDirectory,
        '--json',
        '--output-last-message', $OutputPath,
        '-'
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments $arguments `
        -StandardInput $Prompt -TimeoutMilliseconds $TimeoutMilliseconds `
        -TimeoutDescription $TimeoutDescription `
        -Operation 'Local Codex adoption execution' `
        -ProgressActivity 'Running local Codex' `
        -RequireProcessTreeContainment `
        -OutputLineHandler {
            param([string]$Line)
            Write-LocalCodexEvent -Line $Line
        }
    if ($result.ExitCode -ne 0) {
        $detail = Get-LocalCodexFailureDetail -Result $result
        throw "Local Codex exited with code $($result.ExitCode). $detail"
    }
}

function Get-ProtocolSourceSnapshot {
    param(
        [string]$Token = '',
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$Destination
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest contains an invalid protocol commit.'
    }
    $sourceRoot = $null
    if ($Token) {
        $archivePath = Join-Path $Destination 'protocol-source.zip'
        $extractPath = Join-Path $Destination 'protocol-source'
        [IO.Directory]::CreateDirectory($extractPath) | Out-Null
        $headers = @{
            Accept = 'application/vnd.github+json'
            Authorization = "Bearer $Token"
            'X-GitHub-Api-Version' = '2026-03-10'
            'User-Agent' = 'meAndAI-quick-adoption'
        }
        $uri = "https://api.github.com/repos/$ProtocolRepository/zipball/$Commit"
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers $headers -OutFile $archivePath
            Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force
        }
        catch {
            throw 'Unable to download the exact protocol source snapshot required for semantic adoption.'
        }

        $roots = @(Get-ChildItem -LiteralPath $extractPath -Directory)
        if ($roots.Count -eq 1) {
            $sourceRoot = $roots[0].FullName
        }
    }
    else {
        $sourceRoot = Join-Path $Destination 'protocol-source'
        try {
            Invoke-External -Command 'gh' -Arguments @(
                'repo', 'clone', $ProtocolRepository, $sourceRoot, '--',
                '--branch', $ProtocolTag, '--single-branch', '--depth', '1'
            ) | Out-Null
            $resolvedCommit = ((@(Invoke-Git -Repository $sourceRoot -Arguments @(
                'rev-parse', 'HEAD'
            )).Output -join '').Trim())
        }
        catch {
            throw 'Unable to clone the exact protocol source snapshot through the authenticated local GitHub CLI.'
        }
        if ($resolvedCommit -cne $Commit) {
            throw 'The authenticated protocol source snapshot does not match the adoption manifest commit.'
        }
    }

    if (-not $sourceRoot -or
        -not (Test-Path -LiteralPath (Join-Path $sourceRoot 'PROTOCOL.md') -PathType Leaf)) {
        throw 'The exact protocol source snapshot has an unexpected structure.'
    }
    $versionPath = Join-Path $sourceRoot 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or
        [IO.File]::ReadAllText($versionPath).Trim() -cne $ProtocolTag.Substring(1)) {
        throw 'The protocol source snapshot version does not match the requested tag.'
    }
    return $sourceRoot
}

function Assert-CredentialFilesAbsent {
    param([Parameter(Mandatory)][string]$Repository)

    $files = @(Get-ChildItem -LiteralPath $Repository -Recurse -Force -File)
    foreach ($name in $tokenMappings.Keys) {
        $matches = @($files | Where-Object {
            ([string]$_.Name).Equals($name, [StringComparison]::OrdinalIgnoreCase)
        })
        if ($matches.Count -gt 0) {
            throw "Credential file '$name' must not exist in the isolated Codex clone."
        }
    }
}

function Invoke-LocalCurrentLauncherRecovery {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$HeadSha,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$TargetCommit,
        [Parameter(Mandatory)][string]$MaintainerRepository
    )

    if ($Repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or
        $Branch -cnotmatch '^[A-Za-z0-9._/-]+$' -or
        $Branch.Contains('..') -or $Branch.StartsWith('/') -or
        $Branch.EndsWith('/') -or
        $HeadSha -cnotmatch '^[0-9a-f]{40}$' -or
        $TargetTag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$' -or
        $TargetCommit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Current-launcher recovery received a noncanonical repository, branch, release, or commit identity.'
    }

    $maintainerHeadBefore = ((@(Invoke-Git -Repository $MaintainerRepository `
        -Arguments @('rev-parse', '--verify', 'HEAD')).Output -join '').Trim())
    $maintainerBranchBefore = ((@(Invoke-Git -Repository $MaintainerRepository `
        -Arguments @('branch', '--show-current')).Output -join '').Trim())
    $maintainerStatusBefore = @((Invoke-Git -Repository $MaintainerRepository `
        -Arguments @('status', '--porcelain=v1', '--untracked-files=all')).Output |
        ForEach-Object { [string]$_ }) -join "`n"
    if ($maintainerHeadBefore -cne $HeadSha -or
        $maintainerBranchBefore -cne $Branch) {
        throw 'The maintainer checkout no longer matches the captured default-branch identity.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-update-recovery-$([guid]::NewGuid().ToString('N'))"
    $consumerClone = Join-Path $temporaryRoot 'consumer'
    $protocolSource = Join-Path $temporaryRoot 'protocol-source'
    $operationError = $null
    $cleanupError = $null
    $preservationError = $null
    $previousRepository = [Environment]::GetEnvironmentVariable(
        'GITHUB_REPOSITORY', 'Process'
    )
    $previousWorkspace = [Environment]::GetEnvironmentVariable(
        'GITHUB_WORKSPACE', 'Process'
    )
    $previousDefaultBranch = [Environment]::GetEnvironmentVariable(
        'DEFAULT_BRANCH', 'Process'
    )
    $previousGitHubToken = [Environment]::GetEnvironmentVariable(
        'GH_TOKEN', 'Process'
    )
    $previousIssueToken = [Environment]::GetEnvironmentVariable(
        'ISSUE_TOKEN', 'Process'
    )
    $previousProtocolToken = [Environment]::GetEnvironmentVariable(
        'PROTOCOL_TOKEN', 'Process'
    )
    $previousGitHubHost = [Environment]::GetEnvironmentVariable(
        'GH_HOST', 'Process'
    )
    $callerLocationBefore = (Get-Location).Path
    $locationPushed = $false
    $restorationErrors = [System.Collections.Generic.List[string]]::new()

    try {
        [IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
        Invoke-External -Command 'gh' -Arguments @(
            'repo', 'clone', $Repository, $consumerClone, '--',
            '--branch', $Branch, '--single-branch'
        ) | Out-Null
        $clonedHead = ((@(Invoke-Git -Repository $consumerClone -Arguments @(
            'rev-parse', '--verify', 'HEAD'
        )).Output -join '').Trim())
        if ($clonedHead -cne $HeadSha) {
            throw 'The consumer default branch changed before its isolated recovery clone was bound.'
        }
        $consumerStatus = @((Invoke-Git -Repository $consumerClone -Arguments @(
            'status', '--porcelain=v1', '--untracked-files=all'
        )).Output | Where-Object { $_ })
        if ($consumerStatus.Count -ne 0) {
            throw 'The isolated consumer recovery clone is not clean.'
        }
        Assert-CredentialFilesAbsent -Repository $consumerClone

        Invoke-External -Command 'gh' -Arguments @(
            'repo', 'clone', $ProtocolRepository, $protocolSource, '--',
            '--no-checkout'
        ) | Out-Null
        $tagCommit = ((@(Invoke-Git -Repository $protocolSource -Arguments @(
            'rev-parse', '--verify', "refs/tags/$TargetTag^{commit}"
        )).Output -join '').Trim())
        if ($tagCommit -cne $TargetCommit) {
            throw 'The cloned protocol tag does not match the verified immutable release commit.'
        }
        Invoke-Git -Repository $protocolSource -Arguments @(
            'checkout', '--quiet', '--detach', $TargetCommit
        ) | Out-Null
        $sourceHead = ((@(Invoke-Git -Repository $protocolSource -Arguments @(
            'rev-parse', '--verify', 'HEAD'
        )).Output -join '').Trim())
        $versionPath = Join-Path $protocolSource 'VERSION'
        if ($sourceHead -cne $TargetCommit -or
            -not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or
            [IO.File]::ReadAllText($versionPath).Trim() -cne $TargetTag.Substring(1)) {
            throw 'The isolated protocol source does not match the verified target release.'
        }
        $adapterPath = Join-Path $protocolSource `
            'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) {
            throw 'The verified target release does not contain its current-launcher adapter.'
        }
        $tokenResult = Invoke-External -Command 'gh' -Arguments @(
            'auth', 'token', '--hostname', 'github.com'
        )
        $localGitHubToken = ((@($tokenResult.Output) -join '').Trim())
        if ([string]::IsNullOrWhiteSpace($localGitHubToken)) {
            throw 'The authenticated local GitHub identity did not expose a recovery token.'
        }

        [Environment]::SetEnvironmentVariable(
            'GITHUB_REPOSITORY', $Repository, 'Process'
        )
        [Environment]::SetEnvironmentVariable(
            'GITHUB_WORKSPACE', $consumerClone, 'Process'
        )
        [Environment]::SetEnvironmentVariable(
            'DEFAULT_BRANCH', $Branch, 'Process'
        )
        foreach ($tokenName in @('GH_TOKEN', 'ISSUE_TOKEN', 'PROTOCOL_TOKEN')) {
            [Environment]::SetEnvironmentVariable(
                $tokenName, $localGitHubToken, 'Process'
            )
        }
        [Environment]::SetEnvironmentVariable(
            'GH_HOST', 'github.com', 'Process'
        )
        Push-Location -LiteralPath $consumerClone
        $locationPushed = $true
        & $adapterPath -RecoverMergedPullRequests
        & $adapterPath -CurrentLauncher `
            -RequestedTargetTag $TargetTag `
            -RequestedTargetCommit $TargetCommit `
            -RequestedBaseSha $HeadSha `
            -ProtocolSourcePath $protocolSource
    }
    catch {
        $operationError = $_.Exception
    }
    finally {
        if ($locationPushed) {
            try {
                Pop-Location
            }
            catch {
                $restorationErrors.Add(
                    "Location-stack restoration failed: $($_.Exception.Message)"
                )
                try {
                    Microsoft.PowerShell.Management\Pop-Location `
                        -ErrorAction Stop
                }
                catch {
                    try {
                        Set-Location -LiteralPath $callerLocationBefore
                    }
                    catch {
                        $restorationErrors.Add(
                            "Caller-location recovery failed: $($_.Exception.Message)"
                        )
                    }
                }
            }
        }
        foreach ($binding in @(
            [pscustomobject]@{ Name = 'GITHUB_REPOSITORY'; Value = $previousRepository },
            [pscustomobject]@{ Name = 'GITHUB_WORKSPACE'; Value = $previousWorkspace },
            [pscustomobject]@{ Name = 'DEFAULT_BRANCH'; Value = $previousDefaultBranch },
            [pscustomobject]@{ Name = 'GH_TOKEN'; Value = $previousGitHubToken },
            [pscustomobject]@{ Name = 'ISSUE_TOKEN'; Value = $previousIssueToken },
            [pscustomobject]@{ Name = 'PROTOCOL_TOKEN'; Value = $previousProtocolToken },
            [pscustomobject]@{ Name = 'GH_HOST'; Value = $previousGitHubHost }
        )) {
            try {
                [Environment]::SetEnvironmentVariable(
                    [string]$binding.Name, $binding.Value, 'Process'
                )
            }
            catch {
                $restorationErrors.Add(
                    "Environment restoration for '$([string]$binding.Name)' failed: $($_.Exception.Message)"
                )
            }
        }
        try {
            if (Test-Path -LiteralPath $temporaryRoot) {
                Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
            }
        }
        catch {
            $cleanupError = $_.Exception
        }
        try {
            $maintainerHeadAfter = ((@(Invoke-Git `
                -Repository $MaintainerRepository `
                -Arguments @('rev-parse', '--verify', 'HEAD')).Output -join '').Trim())
            $maintainerBranchAfter = ((@(Invoke-Git `
                -Repository $MaintainerRepository `
                -Arguments @('branch', '--show-current')).Output -join '').Trim())
            $maintainerStatusAfter = @((Invoke-Git `
                -Repository $MaintainerRepository `
                -Arguments @(
                    'status', '--porcelain=v1', '--untracked-files=all'
                )).Output | ForEach-Object { [string]$_ }) -join "`n"
            if ($maintainerHeadAfter -cne $maintainerHeadBefore -or
                $maintainerBranchAfter -cne $maintainerBranchBefore -or
                $maintainerStatusAfter -cne $maintainerStatusBefore) {
                throw 'The maintainer checkout changed during isolated current-launcher recovery.'
            }
        }
        catch {
            $preservationError = $_.Exception
        }
    }

    $failureDetails = @(
        if ($null -ne $operationError) { $operationError.Message }
        if ($null -ne $cleanupError) {
            "Temporary recovery cleanup failed: $($cleanupError.Message)"
        }
        if ($null -ne $preservationError) { $preservationError.Message }
        foreach ($restorationError in $restorationErrors) { $restorationError }
    )
    if ($failureDetails.Count -gt 0) {
        throw ($failureDetails -join ' ')
    }
    return [pscustomobject]@{
        TargetTag = $TargetTag
        TargetCommit = $TargetCommit
        BaseSha = $HeadSha
    }
}
