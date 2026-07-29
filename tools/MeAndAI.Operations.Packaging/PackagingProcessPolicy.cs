using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Packaging;

internal static class PackagingProcessPolicy
{
    private const int MaximumTextOutputBytes = 1024 * 1024;
    private const int MaximumDescriptorOutputBytes = 64 * 1024;

    internal static TimeSpan GitTimeout { get; } = TimeSpan.FromSeconds(30);

    internal static TimeSpan PublishTimeout { get; } = TimeSpan.FromMinutes(3);

    internal static TimeSpan VerificationTimeout { get; } =
        TimeSpan.FromSeconds(30);

    internal static BoundedProcessRequest CreateTextRequest(
        string executable,
        IEnumerable<string> arguments,
        string workingDirectory,
        TimeSpan timeout) =>
        BoundedProcessRequest.Create(
            executable,
            arguments,
            workingDirectory,
            ReadOnlyMemory<byte>.Empty,
            timeout,
            MaximumTextOutputBytes,
            MaximumTextOutputBytes);

    internal static BoundedProcessRequest CreateDescriptorRequest(
        string executable,
        IEnumerable<string> arguments,
        string workingDirectory) =>
        BoundedProcessRequest.Create(
            executable,
            arguments,
            workingDirectory,
            ReadOnlyMemory<byte>.Empty,
            VerificationTimeout,
            MaximumDescriptorOutputBytes,
            MaximumDescriptorOutputBytes);
}
