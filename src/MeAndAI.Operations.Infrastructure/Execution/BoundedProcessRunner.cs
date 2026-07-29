using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Operations.Infrastructure.Execution;

internal sealed class BoundedProcessRequest
{
    private readonly ReadOnlyCollection<string> _arguments;
    private readonly byte[] _standardInput;
    private readonly ReadOnlyCollection<KeyValuePair<string, string?>>
        _environmentOverrides;

    private BoundedProcessRequest(
        string executable,
        string[] arguments,
        string workingDirectory,
        byte[] standardInput,
        TimeSpan timeout,
        int maximumStandardOutputBytes,
        int maximumStandardErrorBytes,
        KeyValuePair<string, string?>[] environmentOverrides)
    {
        Executable = executable;
        _arguments = Array.AsReadOnly(arguments);
        WorkingDirectory = workingDirectory;
        _standardInput = standardInput;
        Timeout = timeout;
        MaximumStandardOutputBytes = maximumStandardOutputBytes;
        MaximumStandardErrorBytes = maximumStandardErrorBytes;
        _environmentOverrides = Array.AsReadOnly(environmentOverrides);
    }

    internal string Executable { get; }

    internal IReadOnlyList<string> Arguments => _arguments;

    internal string WorkingDirectory { get; }

    internal ReadOnlyMemory<byte> StandardInput => _standardInput.ToArray();

    internal TimeSpan Timeout { get; }

    internal int MaximumStandardOutputBytes { get; }

    internal int MaximumStandardErrorBytes { get; }

    internal IReadOnlyList<KeyValuePair<string, string?>> EnvironmentOverrides =>
        _environmentOverrides;

    internal static BoundedProcessRequest Create(
        string executable,
        IEnumerable<string> arguments,
        string workingDirectory,
        ReadOnlyMemory<byte> standardInput,
        TimeSpan timeout,
        int maximumStandardOutputBytes,
        int maximumStandardErrorBytes,
        IEnumerable<KeyValuePair<string, string?>>? environmentOverrides = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(executable);
        if (executable.Contains('\0', StringComparison.Ordinal))
        {
            throw new ArgumentException(
                "Executable contains an invalid character.",
                nameof(executable));
        }

        ArgumentNullException.ThrowIfNull(arguments);
        var copiedArguments = arguments.ToArray();
        if (copiedArguments.Any(argument => argument is null))
        {
            throw new ArgumentException(
                "Arguments cannot contain null values.",
                nameof(arguments));
        }

        if (copiedArguments.Any(argument =>
                argument.Contains('\0', StringComparison.Ordinal)))
        {
            throw new ArgumentException(
                "Arguments contain an invalid character.",
                nameof(arguments));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(workingDirectory);
        if (workingDirectory.Contains('\0', StringComparison.Ordinal) ||
            !Path.IsPathFullyQualified(workingDirectory))
        {
            throw new ArgumentException(
                "Working directory must be an absolute path.",
                nameof(workingDirectory));
        }

        ArgumentOutOfRangeException.ThrowIfLessThanOrEqual(
            timeout,
            TimeSpan.Zero);
        ArgumentOutOfRangeException.ThrowIfLessThanOrEqual(
            maximumStandardOutputBytes,
            0);
        ArgumentOutOfRangeException.ThrowIfLessThanOrEqual(
            maximumStandardErrorBytes,
            0);

        var copiedEnvironment = CopyEnvironmentOverrides(environmentOverrides);
        return new BoundedProcessRequest(
            executable,
            copiedArguments,
            Path.GetFullPath(workingDirectory),
            standardInput.ToArray(),
            timeout,
            maximumStandardOutputBytes,
            maximumStandardErrorBytes,
            copiedEnvironment);
    }

    private static KeyValuePair<string, string?>[] CopyEnvironmentOverrides(
        IEnumerable<KeyValuePair<string, string?>>? environmentOverrides)
    {
        if (environmentOverrides is null)
        {
            return [];
        }

        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var copied = new List<KeyValuePair<string, string?>>();
        foreach (var pair in environmentOverrides)
        {
            if (string.IsNullOrEmpty(pair.Key) ||
                pair.Key.Contains('=', StringComparison.Ordinal) ||
                pair.Key.Contains('\0', StringComparison.Ordinal))
            {
                throw new ArgumentException(
                    "Environment override name is invalid.",
                    nameof(environmentOverrides));
            }

            if (pair.Value?.Contains('\0', StringComparison.Ordinal) == true)
            {
                throw new ArgumentException(
                    "Environment override value is invalid.",
                    nameof(environmentOverrides));
            }

            if (!names.Add(pair.Key))
            {
                throw new ArgumentException(
                    "Environment override names must be unique.",
                    nameof(environmentOverrides));
            }

            copied.Add(new KeyValuePair<string, string?>(pair.Key, pair.Value));
        }

        return
        [
            .. copied
                .OrderBy(pair => pair.Key, StringComparer.OrdinalIgnoreCase)
                .ThenBy(pair => pair.Key, StringComparer.Ordinal),
        ];
    }
}

internal sealed class BoundedProcessResult
{
    private readonly byte[] _standardOutput;
    private readonly byte[] _standardError;

    internal BoundedProcessResult(
        int exitCode,
        ReadOnlySpan<byte> standardOutput,
        ReadOnlySpan<byte> standardError)
    {
        ExitCode = exitCode;
        _standardOutput = standardOutput.ToArray();
        _standardError = standardError.ToArray();
    }

    internal int ExitCode { get; }

    internal ReadOnlyMemory<byte> StandardOutput => _standardOutput.ToArray();

    internal ReadOnlyMemory<byte> StandardError => _standardError.ToArray();
}

internal static class BoundedProcessRunner
{
    private const int BufferSize = 8192;
    private static readonly TimeSpan CleanupGrace = TimeSpan.FromSeconds(5);
    private static readonly TimeSpan CleanupSettleGrace = TimeSpan.FromSeconds(1);
    private static readonly TimeSpan MaximumTimerDelay =
        TimeSpan.FromMilliseconds(int.MaxValue);

    internal static async Task<BoundedProcessResult> ExecuteAsync(
        BoundedProcessRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);
        cancellationToken.ThrowIfCancellationRequested();

        var terminal = new TaskCompletionSource<TerminalReason>(
            TaskCreationOptions.RunContinuationsAsynchronously);
        using var timeoutStop = new CancellationTokenSource();
        using var cancellationRegistration = cancellationToken.Register(
            static state =>
            {
                var completion =
                    (TaskCompletionSource<TerminalReason>)state!;
                completion.TrySetResult(TerminalReason.CallerCanceled);
            },
            terminal);
        var timeoutObserver = SignalTimeoutAsync(
            request.Timeout,
            terminal,
            timeoutStop.Token);

        Process? process = null;
        try
        {
            if (terminal.Task.IsCompleted)
            {
                var earlyReason = await terminal.Task.ConfigureAwait(false);
                await StopTimeoutObserverAsync(timeoutStop, timeoutObserver)
                    .ConfigureAwait(false);
                ThrowTerminalFailure(earlyReason, cancellationToken);
            }

            try
            {
                process = new Process
                {
                    StartInfo = BuildStartInfo(request),
                };
                if (!terminal.Task.IsCompleted && !process.Start())
                {
                    terminal.TrySetResult(TerminalReason.StartFailed);
                }
            }
            catch (Exception exception) when (IsStartFailure(exception))
            {
                terminal.TrySetResult(TerminalReason.StartFailed);
            }

            if (process is null || !IsStarted(process))
            {
                var startReason = await terminal.Task.ConfigureAwait(false);
                await StopTimeoutObserverAsync(timeoutStop, timeoutObserver)
                    .ConfigureAwait(false);
                ThrowTerminalFailure(startReason, cancellationToken);
            }

            using var inputOutputAbort = new CancellationTokenSource();
            var lifecycle = RunLifecycleAsync(
                process,
                request,
                terminal,
                inputOutputAbort.Token);
            var reason = await terminal.Task.ConfigureAwait(false);
            await StopTimeoutObserverAsync(timeoutStop, timeoutObserver)
                .ConfigureAwait(false);

            if (reason == TerminalReason.Completed)
            {
                var completed = await lifecycle.ConfigureAwait(false);
                return new BoundedProcessResult(
                    process.ExitCode,
                    completed.StandardOutput,
                    completed.StandardError);
            }

            var cleanupConfirmed = await StopAndDrainAsync(
                    process,
                    lifecycle,
                    inputOutputAbort)
                .ConfigureAwait(false);
            if (!cleanupConfirmed)
            {
                throw CleanupFailure();
            }

            ThrowTerminalFailure(reason, cancellationToken);
            throw new UnreachableException();
        }
        finally
        {
            process?.Dispose();
        }
    }

    private static ProcessStartInfo BuildStartInfo(BoundedProcessRequest request)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = request.Executable,
            WorkingDirectory = request.WorkingDirectory,
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
        };
        foreach (var argument in request.Arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        foreach (var pair in request.EnvironmentOverrides)
        {
            var matchingNames = startInfo.Environment.Keys
                .Where(name => string.Equals(
                    name,
                    pair.Key,
                    StringComparison.OrdinalIgnoreCase))
                .ToArray();
            foreach (var matchingName in matchingNames)
            {
                startInfo.Environment.Remove(matchingName);
            }

            if (pair.Value is not null)
            {
                startInfo.Environment.Add(pair.Key, pair.Value);
            }
        }

        return startInfo;
    }

    private static async Task<LifecycleResult> RunLifecycleAsync(
        Process process,
        BoundedProcessRequest request,
        TaskCompletionSource<TerminalReason> terminal,
        CancellationToken inputOutputAbort)
    {
        try
        {
            var standardOutput = ObserveTransportAsync(
                DrainAsync(
                    process.StandardOutput.BaseStream,
                    request.MaximumStandardOutputBytes,
                    TerminalReason.StandardOutputLimitExceeded,
                    terminal,
                    inputOutputAbort),
                terminal,
                inputOutputAbort);
            var standardError = ObserveTransportAsync(
                DrainAsync(
                    process.StandardError.BaseStream,
                    request.MaximumStandardErrorBytes,
                    TerminalReason.StandardErrorLimitExceeded,
                    terminal,
                    inputOutputAbort),
                terminal,
                inputOutputAbort);
            var exit = ObserveTransportAsync(
                process.WaitForExitAsync(CancellationToken.None),
                terminal,
                inputOutputAbort);
            var input = ObserveTransportAsync(
                WriteAndCloseInputAsync(
                    process.StandardInput.BaseStream,
                    request.StandardInput,
                    inputOutputAbort),
                terminal,
                inputOutputAbort);

            await Task.WhenAll(standardOutput, standardError, exit, input)
                .ConfigureAwait(false);
            var result = new LifecycleResult(
                await standardOutput.ConfigureAwait(false),
                await standardError.ConfigureAwait(false));
            terminal.TrySetResult(TerminalReason.Completed);
            return result;
        }
        catch (OperationCanceledException)
            when (inputOutputAbort.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception exception) when (IsTransportFailure(exception))
        {
            terminal.TrySetResult(TerminalReason.TransportFailed);
            throw TransportFailure();
        }
    }

    private static async Task ObserveTransportAsync(
        Task operation,
        TaskCompletionSource<TerminalReason> terminal,
        CancellationToken inputOutputAbort)
    {
        try
        {
            await operation.ConfigureAwait(false);
        }
        catch (OperationCanceledException)
            when (inputOutputAbort.IsCancellationRequested)
        {
            throw;
        }
        catch (OperationCanceledException)
        {
            terminal.TrySetResult(TerminalReason.TransportFailed);
            throw TransportFailure();
        }
        catch (Exception exception) when (IsTransportFailure(exception))
        {
            terminal.TrySetResult(TerminalReason.TransportFailed);
            throw TransportFailure();
        }
    }

    private static async Task<T> ObserveTransportAsync<T>(
        Task<T> operation,
        TaskCompletionSource<TerminalReason> terminal,
        CancellationToken inputOutputAbort)
    {
        try
        {
            return await operation.ConfigureAwait(false);
        }
        catch (OperationCanceledException)
            when (inputOutputAbort.IsCancellationRequested)
        {
            throw;
        }
        catch (OperationCanceledException)
        {
            terminal.TrySetResult(TerminalReason.TransportFailed);
            throw TransportFailure();
        }
        catch (Exception exception) when (IsTransportFailure(exception))
        {
            terminal.TrySetResult(TerminalReason.TransportFailed);
            throw TransportFailure();
        }
    }

    private static async Task WriteAndCloseInputAsync(
        Stream stream,
        ReadOnlyMemory<byte> standardInput,
        CancellationToken inputOutputAbort)
    {
        try
        {
            if (!standardInput.IsEmpty)
            {
                await stream.WriteAsync(standardInput, inputOutputAbort)
                    .ConfigureAwait(false);
                await stream.FlushAsync(inputOutputAbort).ConfigureAwait(false);
            }
        }
        finally
        {
            stream.Close();
        }
    }

    private static async Task<byte[]> DrainAsync(
        Stream stream,
        int maximumBytes,
        TerminalReason overflowReason,
        TaskCompletionSource<TerminalReason> terminal,
        CancellationToken inputOutputAbort)
    {
        using var captured = new MemoryStream(
            capacity: Math.Min(maximumBytes, BufferSize));
        var buffer = new byte[BufferSize];
        long capturedCount = 0;
        var overflowed = false;

        while (true)
        {
            var remaining = maximumBytes - capturedCount;
            var requested = overflowed
                ? buffer.Length
                : (int)Math.Min(buffer.Length, remaining + 1L);
            var read = await stream.ReadAsync(
                    buffer.AsMemory(0, requested),
                    inputOutputAbort)
                .ConfigureAwait(false);
            if (read == 0)
            {
                return captured.ToArray();
            }

            if (overflowed)
            {
                continue;
            }

            var accepted = (int)Math.Min(read, remaining);
            if (accepted > 0)
            {
                await captured.WriteAsync(
                        buffer.AsMemory(0, accepted),
                        CancellationToken.None)
                    .ConfigureAwait(false);
                capturedCount += accepted;
            }

            if (accepted != read)
            {
                overflowed = true;
                terminal.TrySetResult(overflowReason);
            }
        }
    }

    private static async Task<bool> StopAndDrainAsync(
        Process process,
        Task lifecycle,
        CancellationTokenSource inputOutputAbort)
    {
        CloseStandardInput(process);
        var killAccepted = TryKillTree(process);
        if (await CompletesWithinAsync(lifecycle, CleanupGrace)
                .ConfigureAwait(false))
        {
            await ObserveAsync(lifecycle).ConfigureAwait(false);
            return killAccepted && IsExited(process);
        }

        var abortAccepted = TryCancel(inputOutputAbort);
        CloseRedirectedStreams(process);
        if (await CompletesWithinAsync(lifecycle, CleanupSettleGrace)
                .ConfigureAwait(false))
        {
            await ObserveAsync(lifecycle).ConfigureAwait(false);
            return abortAccepted && killAccepted && IsExited(process);
        }

        _ = lifecycle.ContinueWith(
            static completed => _ = completed.Exception,
            CancellationToken.None,
            TaskContinuationOptions.OnlyOnFaulted |
            TaskContinuationOptions.ExecuteSynchronously,
            TaskScheduler.Default);
        return false;
    }

    private static async Task<bool> CompletesWithinAsync(
        Task task,
        TimeSpan timeout)
    {
        using var graceStop = new CancellationTokenSource();
        var grace = Task.Delay(timeout, graceStop.Token);
        if (await Task.WhenAny(task, grace).ConfigureAwait(false) != task)
        {
            return false;
        }

        graceStop.Cancel();
        try
        {
            await grace.ConfigureAwait(false);
        }
        catch (OperationCanceledException) when (graceStop.IsCancellationRequested)
        {
        }

        return true;
    }

    private static async Task SignalTimeoutAsync(
        TimeSpan timeout,
        TaskCompletionSource<TerminalReason> terminal,
        CancellationToken timeoutStop)
    {
        try
        {
            var elapsed = Stopwatch.StartNew();
            var remaining = timeout;
            while (remaining > TimeSpan.Zero)
            {
                var delay = remaining > MaximumTimerDelay
                    ? MaximumTimerDelay
                    : remaining;
                await Task.Delay(delay, timeoutStop).ConfigureAwait(false);
                remaining = timeout - elapsed.Elapsed;
            }

            terminal.TrySetResult(TerminalReason.TimedOut);
        }
        catch (OperationCanceledException) when (timeoutStop.IsCancellationRequested)
        {
        }
    }

    private static async Task StopTimeoutObserverAsync(
        CancellationTokenSource timeoutStop,
        Task timeoutObserver)
    {
        timeoutStop.Cancel();
        await timeoutObserver.ConfigureAwait(false);
    }

    private static async Task ObserveAsync(Task task)
    {
        try
        {
            await task.ConfigureAwait(false);
        }
        catch (Exception)
        {
        }
    }

    private static bool TryKillTree(Process process)
    {
        try
        {
            if (!process.HasExited)
            {
                process.Kill(entireProcessTree: true);
            }

            return true;
        }
        catch (InvalidOperationException)
        {
            return IsExited(process);
        }
        catch (Win32Exception)
        {
            return false;
        }
        catch (NotSupportedException)
        {
            return false;
        }
    }

    private static bool IsStarted(Process process)
    {
        try
        {
            _ = process.Id;
            return true;
        }
        catch (InvalidOperationException)
        {
            return false;
        }
    }

    private static bool IsExited(Process process)
    {
        try
        {
            return process.HasExited;
        }
        catch (InvalidOperationException)
        {
            return false;
        }
        catch (Win32Exception)
        {
            return false;
        }
    }

    private static bool TryCancel(CancellationTokenSource cancellation)
    {
        try
        {
            cancellation.Cancel();
            return true;
        }
        catch (AggregateException)
        {
            return false;
        }
    }

    private static void CloseStandardInput(Process process)
    {
        try
        {
            process.StandardInput.Close();
        }
        catch (InvalidOperationException)
        {
        }
        catch (IOException)
        {
        }
        catch (NotSupportedException)
        {
        }
        catch (Win32Exception)
        {
        }
    }

    private static void CloseRedirectedStreams(Process process)
    {
        CloseStandardInput(process);
        try
        {
            process.StandardOutput.Close();
        }
        catch (InvalidOperationException)
        {
        }
        catch (IOException)
        {
        }
        catch (NotSupportedException)
        {
        }
        catch (Win32Exception)
        {
        }

        try
        {
            process.StandardError.Close();
        }
        catch (InvalidOperationException)
        {
        }
        catch (IOException)
        {
        }
        catch (NotSupportedException)
        {
        }
        catch (Win32Exception)
        {
        }
    }

    private static bool IsStartFailure(Exception exception) =>
        exception is ArgumentException or
        IOException or
        InvalidOperationException or
        NotSupportedException or
        UnauthorizedAccessException or
        Win32Exception;

    private static bool IsTransportFailure(Exception exception) =>
        exception is IOException or
        InvalidOperationException or
        NotSupportedException or
        UnauthorizedAccessException or
        Win32Exception;

    [DoesNotReturn]
    private static void ThrowTerminalFailure(
        TerminalReason reason,
        CancellationToken cancellationToken)
    {
        switch (reason)
        {
            case TerminalReason.CallerCanceled:
                cancellationToken.ThrowIfCancellationRequested();
                throw new OperationCanceledException(cancellationToken);
            case TerminalReason.StartFailed:
                throw StartFailure();
            case TerminalReason.TimedOut:
                throw TimeoutFailure();
            case TerminalReason.StandardOutputLimitExceeded:
            case TerminalReason.StandardErrorLimitExceeded:
                throw OutputLimitFailure();
            case TerminalReason.TransportFailed:
                throw TransportFailure();
            default:
                throw new UnreachableException();
        }
    }

    private static OperationalDependencyException StartFailure() =>
        new("Process dependency could not be started.");

    private static OperationalDependencyException TimeoutFailure() =>
        new("Process dependency exceeded its runtime limit.");

    private static OperationalDependencyException OutputLimitFailure() =>
        new("Process dependency exceeded its output limit.");

    private static OperationalDependencyException TransportFailure() =>
        new("Process dependency communication failed.");

    private static OperationalDependencyException CleanupFailure() =>
        new("Process dependency cleanup could not be confirmed.");

    private enum TerminalReason
    {
        Completed,
        CallerCanceled,
        TimedOut,
        StandardOutputLimitExceeded,
        StandardErrorLimitExceeded,
        TransportFailed,
        StartFailed,
    }

    private sealed class LifecycleResult(
        byte[] standardOutput,
        byte[] standardError)
    {
        internal byte[] StandardOutput { get; } = standardOutput;

        internal byte[] StandardError { get; } = standardError;
    }
}
