using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Governance;

internal static class ExactGitProcessPolicy
{
    private const int MaximumBoundaryOutputBytes = 128 * 1024;
    private const int MaximumBatchCheckOutputBytes = 1024;
    private const int MaximumStandardErrorBytes = 64 * 1024;
    private const int TreeRecordFramingBytes = 64;
    private const int BatchRecordFramingBytes = 96;
    private static readonly TimeSpan GitTimeout = TimeSpan.FromSeconds(30);

    internal static BoundedProcessRequest CreateBoundaryRequest(
        string repositoryRoot) =>
        Create(
            repositoryRoot,
            [
                "rev-parse",
                "--path-format=absolute",
                "--is-inside-work-tree",
                "--show-toplevel",
                "--git-dir",
                "--git-common-dir",
            ],
            ReadOnlyMemory<byte>.Empty,
            MaximumBoundaryOutputBytes);

    internal static BoundedProcessRequest CreateBatchCheckRequest(
        string repositoryRoot,
        ReadOnlyMemory<byte> standardInput) =>
        Create(
            repositoryRoot,
            ["cat-file", "--batch-check"],
            standardInput,
            MaximumBatchCheckOutputBytes);

    internal static BoundedProcessRequest CreateTreeRequest(
        string repositoryRoot,
        IReadOnlyList<string> commandArguments,
        ExactRepositoryAcquisitionLimits limits)
    {
        ArgumentNullException.ThrowIfNull(limits);
        var maximumOutputBytes = checked(
            limits.MaximumAggregateTreePathUtf8Bytes +
            (limits.MaximumTreeEntries * TreeRecordFramingBytes) +
            1);
        return Create(
            repositoryRoot,
            commandArguments,
            ReadOnlyMemory<byte>.Empty,
            maximumOutputBytes);
    }

    internal static BoundedProcessRequest CreateBatchContentsRequest(
        string repositoryRoot,
        ReadOnlyMemory<byte> standardInput,
        ExactRepositoryAcquisitionLimits limits)
    {
        ArgumentNullException.ThrowIfNull(limits);
        var maximumOutputBytes = checked(
            limits.MaximumAggregateSelectedBlobBytes +
            (limits.MaximumTreeEntries * BatchRecordFramingBytes) +
            1);
        return Create(
            repositoryRoot,
            ["cat-file", "--batch"],
            standardInput,
            maximumOutputBytes);
    }

    private static BoundedProcessRequest Create(
        string repositoryRoot,
        IReadOnlyList<string> commandArguments,
        ReadOnlyMemory<byte> standardInput,
        int maximumStandardOutputBytes)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(repositoryRoot);
        ArgumentNullException.ThrowIfNull(commandArguments);

        return BoundedProcessRequest.Create(
            "git",
            [
                "--no-pager",
                "--no-replace-objects",
                "-C",
                repositoryRoot,
                .. commandArguments,
            ],
            repositoryRoot,
            standardInput,
            GitTimeout,
            maximumStandardOutputBytes,
            MaximumStandardErrorBytes,
            EnvironmentOverrides());
    }

    private static IEnumerable<KeyValuePair<string, string?>>
        EnvironmentOverrides()
    {
        var nullConfiguration = OperatingSystem.IsWindows()
            ? "NUL"
            : "/dev/null";
        var overrides = new Dictionary<string, string?>(
            StringComparer.OrdinalIgnoreCase)
        {
            ["GIT_ALTERNATE_OBJECT_DIRECTORIES"] = null,
            ["GIT_CEILING_DIRECTORIES"] = null,
            ["GIT_COMMON_DIR"] = null,
            ["GIT_CONFIG_COUNT"] = "0",
            ["GIT_CONFIG_GLOBAL"] = nullConfiguration,
            ["GIT_CONFIG_NOSYSTEM"] = "1",
            ["GIT_CONFIG_PARAMETERS"] = null,
            ["GIT_DIR"] = null,
            ["GIT_GLOB_PATHSPECS"] = null,
            ["GIT_ICASE_PATHSPECS"] = null,
            ["GIT_INDEX_FILE"] = null,
            ["GIT_LITERAL_PATHSPECS"] = null,
            ["GIT_NOGLOB_PATHSPECS"] = null,
            ["GIT_NO_LAZY_FETCH"] = "1",
            ["GIT_NO_REPLACE_OBJECTS"] = "1",
            ["GIT_OBJECT_DIRECTORY"] = null,
            ["GIT_OPTIONAL_LOCKS"] = "0",
            ["GIT_TERMINAL_PROMPT"] = "0",
            ["GIT_TRACE"] = null,
            ["GIT_TRACE2"] = null,
            ["GIT_TRACE2_EVENT"] = null,
            ["GIT_TRACE2_PERF"] = null,
            ["GIT_WORK_TREE"] = null,
            ["GCM_INTERACTIVE"] = "Never",
            ["LANG"] = "C",
            ["LC_ALL"] = "C",
        };

        foreach (var name in Environment.GetEnvironmentVariables()
                     .Keys
                     .OfType<string>()
                     .Where(name => name.StartsWith(
                         "GIT_TRACE",
                         StringComparison.OrdinalIgnoreCase)))
        {
            overrides[name] = null;
        }

        return overrides;
    }
}
