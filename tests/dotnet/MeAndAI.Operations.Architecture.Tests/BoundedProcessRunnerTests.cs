using System.Diagnostics;
using System.Globalization;
using System.Reflection;
using System.Text.Json;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class BoundedProcessRunnerTests
{
    private static readonly string FixtureAssembly =
        typeof(ChildProcessFixtureProgram).Assembly.Location;

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task ExactBinaryStreamsAndNonzeroExitRemainAResult()
    {
        using var fixture = ProcessTestDirectory.Create();
        var result = await BoundedProcessRunner.ExecuteAsync(
            CreateRequest(fixture, ["binary"]))
            .ConfigureAwait(true);

        Assert.Equal(23, result.ExitCode);
        Assert.Equal(
            Enumerable.Range(0, 256).Select(value => (byte)value),
            result.StandardOutput.ToArray());
        Assert.Equal(
            Enumerable.Range(0, 256).Reverse().Select(value => (byte)value),
            result.StandardError.ToArray());
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task RequestCopiesArgumentsInputAndEnvironmentWithoutParentMutation()
    {
        using var fixture = ProcessTestDirectory.Create();
        var setName = "MEANDAI_SET_" + Guid.NewGuid().ToString("N");
        var emptyName = "MEANDAI_EMPTY_" + Guid.NewGuid().ToString("N");
        var parentPath = Environment.GetEnvironmentVariable("PATH");
        var input = Enumerable.Range(0, 256).Select(value => (byte)value).ToArray();
        var expectedInput = input.ToArray();
        var error = new byte[] { 0x00, 0xff, 0x0a };
        var processArguments = new List<string>
        {
            FixtureAssembly,
            "observe",
            "17",
            Convert.ToBase64String(error),
            "3",
            setName,
            emptyName,
            "PATH",
            "plain",
            "two words",
            "quote\"value",
        };
        var environment = new List<KeyValuePair<string, string?>>
        {
            new(setName, "exact-value"),
            new(emptyName, string.Empty),
            new("PATH", null),
        };
        var request = BoundedProcessRequest.Create(
            DotnetExecutable,
            processArguments,
            fixture.Root,
            input,
            TimeSpan.FromSeconds(10),
            64 * 1024,
            64 * 1024,
            environment);

        input[0] = 0xff;
        processArguments[^1] = "mutated";
        environment[0] = new KeyValuePair<string, string?>(setName, "mutated");

        var result = await BoundedProcessRunner.ExecuteAsync(request)
            .ConfigureAwait(true);

        Assert.Equal(17, result.ExitCode);
        Assert.Equal(error, result.StandardError.ToArray());
        Assert.Equal(parentPath, Environment.GetEnvironmentVariable("PATH"));
        Assert.Null(Environment.GetEnvironmentVariable(setName));
        Assert.Null(Environment.GetEnvironmentVariable(emptyName));
        using var observation = JsonDocument.Parse(result.StandardOutput);
        var root = observation.RootElement;
        Assert.Equal(fixture.Root, root.GetProperty("workingDirectory").GetString());
        Assert.Equal(
            ["plain", "two words", "quote\"value"],
            root.GetProperty("arguments")
                .EnumerateArray()
                .Select(element => element.GetString()));
        Assert.Equal(
            expectedInput,
            Convert.FromBase64String(
                root.GetProperty("standardInput").GetString()
                    ?? throw new InvalidDataException("Fixture stdin is absent.")));
        var observedEnvironment = root.GetProperty("environment");
        Assert.Equal("exact-value", observedEnvironment.GetProperty(setName).GetString());
        Assert.Equal(string.Empty, observedEnvironment.GetProperty(emptyName).GetString());
        Assert.Equal(JsonValueKind.Null, observedEnvironment.GetProperty("PATH").ValueKind);
    }

    [Theory]
    [Trait("Scenario", "TEST-0192")]
    [InlineData(8192, 8192, false)]
    [InlineData(8193, 8192, true)]
    [InlineData(8192, 8193, true)]
    public async Task ConcurrentStreamLimitsAreInclusiveAndFailOnTheNextByte(
        int outputCount,
        int errorCount,
        bool expectOverflow)
    {
        using var fixture = ProcessTestDirectory.Create();
        var marker = fixture.PathFor("flood-ready");
        var verb = expectOverflow ? "flood-block" : "flood";
        var arguments = expectOverflow
            ? new[]
            {
                verb,
                outputCount.ToString(CultureInfo.InvariantCulture),
                errorCount.ToString(CultureInfo.InvariantCulture),
                marker,
            }
            :
            [
                verb,
                outputCount.ToString(CultureInfo.InvariantCulture),
                errorCount.ToString(CultureInfo.InvariantCulture),
            ];
        var run = BoundedProcessRunner.ExecuteAsync(CreateRequest(
            fixture,
            arguments,
            maximumStandardOutputBytes: 8192,
            maximumStandardErrorBytes: 8192));

        if (expectOverflow)
        {
            var exception = await Assert.ThrowsAsync<OperationalDependencyException>(
                () => run).ConfigureAwait(true);
            Assert.Equal("Process dependency exceeded its output limit.", exception.Message);
            Assert.Null(exception.InnerException);
            return;
        }

        var result = await run.ConfigureAwait(true);
        Assert.Equal(Enumerable.Repeat((byte)0x41, outputCount), result.StandardOutput.ToArray());
        Assert.Equal(Enumerable.Repeat((byte)0x42, errorCount), result.StandardError.ToArray());
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task PreCanceledRequestStartsNoProcessAndPreservesCallerToken()
    {
        using var fixture = ProcessTestDirectory.Create();
        var marker = fixture.PathFor("must-not-start");
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();

        var exception = await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            BoundedProcessRunner.ExecuteAsync(
                CreateRequest(fixture, ["touch", marker]),
                cancellation.Token)).ConfigureAwait(true);

        Assert.Equal(cancellation.Token, exception.CancellationToken);
        Assert.False(File.Exists(marker));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task TimeoutKillsAndDrainsTheOwnedProcess()
    {
        using var fixture = ProcessTestDirectory.Create();
        var marker = fixture.PathFor("timeout-ready");
        var run = BoundedProcessRunner.ExecuteAsync(CreateRequest(
            fixture,
            ["hang", marker],
            timeout: TimeSpan.FromSeconds(3)));

        await WaitForFileAsync(marker, TimeSpan.FromSeconds(2)).ConfigureAwait(true);
        var processId = ReadProcessId(marker);
        var exception = await Assert.ThrowsAsync<OperationalDependencyException>(() => run)
            .ConfigureAwait(true);

        Assert.Equal("Process dependency exceeded its runtime limit.", exception.Message);
        Assert.Null(exception.InnerException);
        await AssertProcessExitedAsync(processId, TimeSpan.FromSeconds(2))
            .ConfigureAwait(true);
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task CallerCancellationKillsActiveDescendantAndPreservesToken()
    {
        using var fixture = ProcessTestDirectory.Create();
        var childReady = fixture.PathFor("child-ready");
        using var cancellation = new CancellationTokenSource();
        var run = BoundedProcessRunner.ExecuteAsync(
            CreateRequest(
                fixture,
                ["tree-block", childReady],
                timeout: TimeSpan.FromSeconds(20)),
            cancellation.Token);

        await WaitForFileAsync(childReady, TimeSpan.FromSeconds(5)).ConfigureAwait(true);
        var childId = ReadProcessId(childReady);
        cancellation.Cancel();
        var exception = await Assert.ThrowsAnyAsync<OperationCanceledException>(() => run)
            .ConfigureAwait(true);

        Assert.Equal(cancellation.Token, exception.CancellationToken);
        await AssertProcessExitedAsync(childId, TimeSpan.FromSeconds(2))
            .ConfigureAwait(true);
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task CleanCompletionWaitsForInheritedPipeEofAfterParentExit()
    {
        using var fixture = ProcessTestDirectory.Create();
        var childReady = fixture.PathFor("pipe-child-ready");
        var parentExiting = fixture.PathFor("pipe-parent-exiting");
        var release = fixture.PathFor("pipe-release");
        var run = BoundedProcessRunner.ExecuteAsync(CreateRequest(
            fixture,
            ["inherited-pipe", childReady, parentExiting, release],
            timeout: TimeSpan.FromSeconds(20)));

        try
        {
            await WaitForFileAsync(childReady, TimeSpan.FromSeconds(5)).ConfigureAwait(true);
            await WaitForFileAsync(parentExiting, TimeSpan.FromSeconds(5)).ConfigureAwait(true);
            var childId = ReadProcessId(childReady);
            await AssertProcessExitedAsync(
                    ReadProcessId(parentExiting),
                    TimeSpan.FromSeconds(5))
                .ConfigureAwait(true);
            Assert.False(run.IsCompleted);

            File.WriteAllBytes(release, []);
            var result = await run.ConfigureAwait(true);

            Assert.Equal(0, result.ExitCode);
            Assert.Equal(new byte[] { 0x5a }, result.StandardOutput.ToArray());
            Assert.Equal(new byte[] { 0x5b }, result.StandardError.ToArray());
            await AssertProcessExitedAsync(childId, TimeSpan.FromSeconds(2))
                .ConfigureAwait(true);
        }
        finally
        {
            File.WriteAllBytes(release, []);
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task InvalidRequestsAndStartFailuresFailClosedWithoutDisclosure()
    {
        using var fixture = ProcessTestDirectory.Create();
        Assert.Throws<ArgumentException>(() => BoundedProcessRequest.Create(
            DotnetExecutable,
            [FixtureAssembly, "touch", fixture.PathFor("relative")],
            ".",
            ReadOnlyMemory<byte>.Empty,
            TimeSpan.FromSeconds(1),
            1,
            1));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            BoundedProcessRequest.Create(
                DotnetExecutable,
                [FixtureAssembly, "binary"],
                fixture.Root,
                ReadOnlyMemory<byte>.Empty,
                TimeSpan.Zero,
                1,
                1));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            BoundedProcessRequest.Create(
                DotnetExecutable,
                [FixtureAssembly, "binary"],
                fixture.Root,
                ReadOnlyMemory<byte>.Empty,
                TimeSpan.FromSeconds(1),
                0,
                1));
        Assert.Throws<ArgumentException>(() => BoundedProcessRequest.Create(
            DotnetExecutable,
            [FixtureAssembly, "binary"],
            fixture.Root,
            ReadOnlyMemory<byte>.Empty,
            TimeSpan.FromSeconds(1),
            1,
            1,
            [new("CaseKey", "first"), new("casekey", "second")]));
        Assert.Throws<ArgumentException>(() => BoundedProcessRequest.Create(
            DotnetExecutable,
            [FixtureAssembly, "invalid\0argument"],
            fixture.Root,
            ReadOnlyMemory<byte>.Empty,
            TimeSpan.FromSeconds(1),
            1,
            1));

        var secret = "secret-" + Guid.NewGuid().ToString("N");
        var missingExecutable = Path.Combine(fixture.Root, secret);
        var exception = await Assert.ThrowsAsync<OperationalDependencyException>(() =>
            BoundedProcessRunner.ExecuteAsync(BoundedProcessRequest.Create(
                missingExecutable,
                ["argument-" + secret],
                fixture.Root,
                ReadOnlyMemory<byte>.Empty,
                TimeSpan.FromSeconds(1),
                1,
                1,
                [new("MEANDAI_SECRET", secret)]))).ConfigureAwait(true);

        Assert.Equal("Process dependency could not be started.", exception.Message);
        Assert.DoesNotContain(secret, exception.ToString(), StringComparison.Ordinal);
        Assert.Null(exception.InnerException);
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void TestOnlyChildEntryPointIsExplicitAndInertToXunitDiscovery()
    {
        var fixtureType = typeof(ChildProcessFixtureProgram);
        var entryPoint = fixtureType.Assembly.EntryPoint;

        Assert.False(fixtureType.IsPublic);
        Assert.NotNull(entryPoint);
        Assert.Equal(fixtureType, entryPoint.DeclaringType);
        Assert.Equal("Main", entryPoint.Name);
        Assert.Empty(fixtureType.GetMethods(
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Static)
            .SelectMany(method => method.GetCustomAttributes(inherit: false))
            .Where(attribute =>
                attribute is FactAttribute || attribute is TheoryAttribute));
    }

    private static string DotnetExecutable =>
        Environment.GetEnvironmentVariable("DOTNET_HOST_PATH") ?? "dotnet";

    private static BoundedProcessRequest CreateRequest(
        ProcessTestDirectory fixture,
        IReadOnlyList<string> arguments,
        TimeSpan? timeout = null,
        int maximumStandardOutputBytes = 64 * 1024,
        int maximumStandardErrorBytes = 64 * 1024) =>
        BoundedProcessRequest.Create(
            DotnetExecutable,
            [FixtureAssembly, .. arguments],
            fixture.Root,
            ReadOnlyMemory<byte>.Empty,
            timeout ?? TimeSpan.FromSeconds(10),
            maximumStandardOutputBytes,
            maximumStandardErrorBytes);

    private static async Task WaitForFileAsync(string path, TimeSpan timeout)
    {
        using var cancellation = new CancellationTokenSource(timeout);
        while (!File.Exists(path))
        {
            await Task.Delay(TimeSpan.FromMilliseconds(20), cancellation.Token)
                .ConfigureAwait(true);
        }
    }

    private static int ReadProcessId(string path) =>
        int.Parse(File.ReadAllText(path), CultureInfo.InvariantCulture);

    private static async Task AssertProcessExitedAsync(int processId, TimeSpan timeout)
    {
        Process? process = null;
        try
        {
            process = Process.GetProcessById(processId);
            using var cancellation = new CancellationTokenSource(timeout);
            await process.WaitForExitAsync(cancellation.Token).ConfigureAwait(true);
        }
        catch (ArgumentException)
        {
            return;
        }
        finally
        {
            process?.Dispose();
        }

        Assert.True(process.HasExited);
    }

    private sealed class ProcessTestDirectory : IDisposable
    {
        private ProcessTestDirectory(string root)
        {
            Root = root;
        }

        internal string Root { get; }

        internal static ProcessTestDirectory Create()
        {
            var root = Path.Combine(
                Path.GetTempPath(),
                "meandai-process-tests-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            return new ProcessTestDirectory(root);
        }

        internal string PathFor(string name) => Path.Combine(Root, name);

        public void Dispose()
        {
            if (Directory.Exists(Root))
            {
                Directory.Delete(Root, recursive: true);
            }
        }
    }
}
