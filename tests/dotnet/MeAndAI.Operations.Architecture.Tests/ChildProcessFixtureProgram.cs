using System.Diagnostics;
using System.Globalization;
using System.Reflection;
using System.Text.Json;

namespace MeAndAI.Operations.Architecture.Tests;

internal static class ChildProcessFixtureProgram
{
    private static readonly TimeSpan SafetyLimit = TimeSpan.FromSeconds(30);

    private static int Main(string[] arguments) =>
        RunAsync(arguments).GetAwaiter().GetResult();

    private static Task<int> RunAsync(IReadOnlyList<string> arguments) =>
        arguments.Count == 0
            ? Task.FromResult(64)
            : arguments[0] switch
            {
                "binary" => WriteBinaryAsync(),
                "observe" => ObserveAsync(arguments),
                "flood" => FloodAsync(arguments, blockAfterWrite: false),
                "flood-block" => FloodAsync(arguments, blockAfterWrite: true),
                "touch" => TouchAsync(arguments),
                "hang" => HangAsync(arguments),
                "tree-block" => TreeBlockAsync(arguments),
                "leaf-block" => LeafBlockAsync(arguments),
                "inherited-pipe" => InheritedPipeAsync(arguments),
                "leaf-release" => LeafReleaseAsync(arguments),
                _ => Task.FromResult(64),
            };

    private static async Task<int> WriteBinaryAsync()
    {
        var standardOutput = Enumerable.Range(0, 256)
            .Select(value => (byte)value)
            .ToArray();
        var standardError = standardOutput.Reverse().ToArray();

        await Task.WhenAll(
            Console.OpenStandardOutput().WriteAsync(standardOutput).AsTask(),
            Console.OpenStandardError().WriteAsync(standardError).AsTask())
            .ConfigureAwait(false);
        return 23;
    }

    private static async Task<int> ObserveAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count < 4 ||
            !int.TryParse(arguments[1], CultureInfo.InvariantCulture, out var exitCode) ||
            !int.TryParse(arguments[3], CultureInfo.InvariantCulture, out var environmentCount) ||
            environmentCount < 0 ||
            arguments.Count < 4 + environmentCount)
        {
            return 64;
        }

        var environment = arguments
            .Skip(4)
            .Take(environmentCount)
            .ToDictionary(
                name => name,
                Environment.GetEnvironmentVariable,
                StringComparer.Ordinal);
        using var input = new MemoryStream();
        await Console.OpenStandardInput().CopyToAsync(input).ConfigureAwait(false);

        var observation = JsonSerializer.SerializeToUtf8Bytes(new
        {
            workingDirectory = Directory.GetCurrentDirectory(),
            arguments = arguments.Skip(4 + environmentCount).ToArray(),
            standardInput = Convert.ToBase64String(input.ToArray()),
            environment,
        });
        var standardError = Convert.FromBase64String(arguments[2]);

        await Task.WhenAll(
            Console.OpenStandardOutput().WriteAsync(observation).AsTask(),
            Console.OpenStandardError().WriteAsync(standardError).AsTask())
            .ConfigureAwait(false);
        return exitCode;
    }

    private static async Task<int> FloodAsync(
        IReadOnlyList<string> arguments,
        bool blockAfterWrite)
    {
        if (arguments.Count != (blockAfterWrite ? 4 : 3) ||
            !int.TryParse(arguments[1], CultureInfo.InvariantCulture, out var outputCount) ||
            !int.TryParse(arguments[2], CultureInfo.InvariantCulture, out var errorCount) ||
            outputCount < 0 ||
            errorCount < 0)
        {
            return 64;
        }

        await Task.WhenAll(
            WriteRepeatedAsync(Console.OpenStandardOutput(), 0x41, outputCount),
            WriteRepeatedAsync(Console.OpenStandardError(), 0x42, errorCount))
            .ConfigureAwait(false);

        if (blockAfterWrite)
        {
            WriteAtomic(arguments[3], Environment.ProcessId);
            await Task.Delay(SafetyLimit).ConfigureAwait(false);
        }

        return 0;
    }

    private static Task<int> TouchAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 2)
        {
            return Task.FromResult(64);
        }

        WriteAtomic(arguments[1], Environment.ProcessId);
        return Task.FromResult(0);
    }

    private static async Task<int> HangAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 2)
        {
            return 64;
        }

        WriteAtomic(arguments[1], Environment.ProcessId);
        await Task.Delay(SafetyLimit).ConfigureAwait(false);
        return 0;
    }

    private static async Task<int> TreeBlockAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 2)
        {
            return 64;
        }

        using var child = StartSelf("leaf-block", arguments[1]);
        await WaitForFileAsync(arguments[1], SafetyLimit).ConfigureAwait(false);
        await Task.Delay(SafetyLimit).ConfigureAwait(false);
        return 0;
    }

    private static async Task<int> LeafBlockAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 2)
        {
            return 64;
        }

        WriteAtomic(arguments[1], Environment.ProcessId);
        await Task.Delay(SafetyLimit).ConfigureAwait(false);
        return 0;
    }

    private static async Task<int> InheritedPipeAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 4)
        {
            return 64;
        }

        using var child = StartSelf("leaf-release", arguments[1], arguments[3]);
        await WaitForFileAsync(arguments[1], SafetyLimit).ConfigureAwait(false);
        WriteAtomic(arguments[2], Environment.ProcessId);
        return 0;
    }

    private static async Task<int> LeafReleaseAsync(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 3)
        {
            return 64;
        }

        WriteAtomic(arguments[1], Environment.ProcessId);
        await WaitForFileAsync(arguments[2], SafetyLimit).ConfigureAwait(false);
        await Task.WhenAll(
            Console.OpenStandardOutput().WriteAsync(new byte[] { 0x5a }).AsTask(),
            Console.OpenStandardError().WriteAsync(new byte[] { 0x5b }).AsTask())
            .ConfigureAwait(false);
        return 0;
    }

    private static Process StartSelf(params string[] arguments)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = Environment.GetEnvironmentVariable("DOTNET_HOST_PATH") ?? "dotnet",
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        startInfo.ArgumentList.Add(Assembly.GetExecutingAssembly().Location);
        foreach (var argument in arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        return Process.Start(startInfo)
            ?? throw new InvalidOperationException("Fixture child could not be started.");
    }

    private static async Task WriteRepeatedAsync(
        Stream stream,
        byte value,
        int count)
    {
        var buffer = Enumerable.Repeat(value, 4096).ToArray();
        var remaining = count;
        while (remaining > 0)
        {
            var length = Math.Min(buffer.Length, remaining);
            await stream.WriteAsync(buffer.AsMemory(0, length)).ConfigureAwait(false);
            remaining -= length;
        }

        await stream.FlushAsync().ConfigureAwait(false);
    }

    private static async Task WaitForFileAsync(string path, TimeSpan timeout)
    {
        using var cancellation = new CancellationTokenSource(timeout);
        while (!File.Exists(path))
        {
            await Task.Delay(TimeSpan.FromMilliseconds(20), cancellation.Token)
                .ConfigureAwait(false);
        }
    }

    private static void WriteAtomic(string path, int processId)
    {
        var temporaryPath = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        File.WriteAllText(
            temporaryPath,
            processId.ToString(CultureInfo.InvariantCulture));
        File.Move(temporaryPath, path);
    }
}
