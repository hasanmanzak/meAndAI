using System.Diagnostics;

namespace MeAndAI.Operations.Packaging;

internal static class BoundedProcess
{
    private const int MaximumCapturedCharacters = 1024 * 1024;

    internal static ProcessResult Run(
        string executable,
        IEnumerable<string> arguments,
        string workingDirectory,
        TimeSpan timeout)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(executable);
        ArgumentNullException.ThrowIfNull(arguments);
        ArgumentException.ThrowIfNullOrWhiteSpace(workingDirectory);
        ArgumentOutOfRangeException.ThrowIfLessThanOrEqual(
            timeout,
            TimeSpan.Zero);

        var startInfo = new ProcessStartInfo
        {
            FileName = executable,
            WorkingDirectory = workingDirectory,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
        };
        foreach (var argument in arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        using var process = new Process { StartInfo = startInfo };
        if (!process.Start())
        {
            throw new InvalidOperationException(
                $"Process '{executable}' could not be started.");
        }

        var standardOutput = process.StandardOutput.ReadToEndAsync();
        var standardError = process.StandardError.ReadToEndAsync();
        using var cancellation = new CancellationTokenSource(timeout);
        try
        {
            process.WaitForExitAsync(cancellation.Token).GetAwaiter().GetResult();
        }
        catch (OperationCanceledException exception)
        {
            TryKill(process);
            throw new TimeoutException(
                $"Process '{executable}' exceeded its bounded runtime.",
                exception);
        }

        var output = standardOutput.GetAwaiter().GetResult();
        var error = standardError.GetAwaiter().GetResult();
        if (output.Length > MaximumCapturedCharacters ||
            error.Length > MaximumCapturedCharacters)
        {
            throw new InvalidDataException(
                $"Process '{executable}' exceeded its output limit.");
        }

        return new ProcessResult(process.ExitCode, output, error);
    }

    private static void TryKill(Process process)
    {
        try
        {
            if (!process.HasExited)
            {
                process.Kill(entireProcessTree: true);
                process.WaitForExit();
            }
        }
        catch (InvalidOperationException)
        {
        }
    }
}

internal sealed record ProcessResult(
    int ExitCode,
    string StandardOutput,
    string StandardError);
