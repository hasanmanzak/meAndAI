using System.Collections.ObjectModel;
using System.Text;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Governance;

internal sealed record ExactGitRepositoryBoundary(
    string RepositoryRoot,
    string GitDirectory,
    string CommonGitDirectory);

internal sealed class ExactGitObjectDatabaseReader
{
    private static readonly Encoding StrictUtf8 = new UTF8Encoding(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);
    private readonly string repositoryRoot;
    private readonly ExactRepositoryAcquisitionLimits limits;

    internal ExactGitObjectDatabaseReader(
        string repositoryRoot,
        ExactRepositoryAcquisitionLimits limits)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(repositoryRoot);
        ArgumentNullException.ThrowIfNull(limits);
        this.repositoryRoot = Path.GetFullPath(repositoryRoot);
        this.limits = limits;
    }

    internal async ValueTask<ExactGitRepositoryBoundary> OpenAsync(
        CancellationToken cancellationToken)
    {
        var output = await ExecuteAsync(
            ExactGitProcessPolicy.CreateBoundaryRequest(repositoryRoot),
            cancellationToken).ConfigureAwait(false);
        var lines = ParseBoundaryLines(output.Span);
        if (!string.Equals(lines[0], "true", StringComparison.Ordinal))
        {
            throw DependencyFailure();
        }

        var topLevel = NormalizeAbsolutePath(lines[1]);
        var gitDirectory = NormalizeAbsolutePath(lines[2]);
        var commonGitDirectory = NormalizeAbsolutePath(lines[3]);
        if (!PathsEqual(topLevel, repositoryRoot) ||
            !Directory.Exists(gitDirectory) ||
            !Directory.Exists(commonGitDirectory))
        {
            throw DependencyFailure();
        }

        EnsureOrdinaryDirectory(gitDirectory);
        EnsureOrdinaryDirectory(commonGitDirectory);
        return new ExactGitRepositoryBoundary(
            repositoryRoot,
            gitDirectory,
            commonGitDirectory);
    }

    internal async ValueTask<IReadOnlyList<ExactGitTreeEntry>?>
        TryReadCommitTreeAsync(
            ExactGitCommitId commit,
            CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(commit);
        var objectId = ExactGitObjectId.Parse(commit.Value);
        var metadata = await ReadMetadataAsync(
            objectId,
            cancellationToken).ConfigureAwait(false);
        if (metadata.IsMissing ||
            metadata.ObjectType != ExactGitObjectType.Commit)
        {
            return null;
        }

        var output = await ExecuteAsync(
            ExactGitProcessPolicy.CreateTreeRequest(
                repositoryRoot,
                [
                    "ls-tree",
                    "-r",
                    "-t",
                    "-z",
                    "--full-tree",
                    "--no-abbrev",
                    commit.Value,
                ],
                limits),
            cancellationToken).ConfigureAwait(false);
        return ExactGitOutputParser.ParseTree(output.Span, limits);
    }

    internal async ValueTask<ExactGitTreeEntry?> ReadRootEntryAsync(
        ExactGitCommitId commit,
        string relativePath,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(commit);
        var objectId = ExactGitObjectId.Parse(commit.Value);
        var metadata = await ReadMetadataAsync(
            objectId,
            cancellationToken).ConfigureAwait(false);
        if (metadata.IsMissing ||
            metadata.ObjectType != ExactGitObjectType.Commit)
        {
            return null;
        }

        var path = RepositoryRelativePath.FromExactGit(relativePath);
        if (path.Value.Contains('/', StringComparison.Ordinal))
        {
            throw new ArgumentException(
                "The bounded exact Git path lookup accepts one root entry.",
                nameof(relativePath));
        }

        var output = await ExecuteAsync(
            ExactGitProcessPolicy.CreateTreeRequest(
                repositoryRoot,
                [
                    "ls-tree",
                    "-z",
                    "--full-tree",
                    "--no-abbrev",
                    commit.Value,
                    "--",
                    path.Value,
                ],
                limits),
            cancellationToken).ConfigureAwait(false);
        var entries = ExactGitOutputParser.ParseTree(output.Span, limits);
        if (entries.Count > 1 ||
            (entries.Count == 1 && entries[0].Path != path))
        {
            throw DependencyFailure();
        }

        return entries.Count == 0 ? null : entries[0];
    }

    internal async ValueTask<
        IReadOnlyDictionary<string, ReadOnlyMemory<byte>>?>
        TryReadSelectedBlobsAsync(
            IReadOnlyList<ExactGitTreeEntry> selectedEntries,
            bool missingIsUnavailable,
            CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(selectedEntries);
        if (selectedEntries.Any(entry => entry is null || !entry.IsFileBlob))
        {
            throw new ArgumentException(
                "Exact Git blob capture accepts only selected regular blobs.",
                nameof(selectedEntries));
        }

        var objectIds = selectedEntries
            .Select(entry => entry.ObjectId)
            .Distinct()
            .OrderBy(objectId => objectId.Value, StringComparer.Ordinal)
            .ToArray();
        if (objectIds.Length == 0)
        {
            return new ReadOnlyDictionary<string, ReadOnlyMemory<byte>>(
                new Dictionary<string, ReadOnlyMemory<byte>>(
                    StringComparer.Ordinal));
        }

        var standardInput = Encoding.ASCII.GetBytes(
            string.Join('\n', objectIds.Select(objectId => objectId.Value)) +
            "\n");
        var output = await ExecuteAsync(
            ExactGitProcessPolicy.CreateBatchContentsRequest(
                repositoryRoot,
                standardInput,
                limits),
            cancellationToken).ConfigureAwait(false);
        var contents = ExactGitOutputParser.ParseBatchContents(
            output.Span,
            objectIds,
            limits);
        var byObjectId = contents.ToDictionary(
            content => content.Metadata.RequestedObjectId,
            content => content);
        if (contents.Any(content =>
                content.IsMissing ||
                content.Metadata.ObjectType != ExactGitObjectType.Blob))
        {
            return missingIsUnavailable
                ? null
                : throw DependencyFailure();
        }

        long aggregateSelectedBytes = 0;
        var byPath = new Dictionary<string, ReadOnlyMemory<byte>>(
            StringComparer.Ordinal);
        foreach (var entry in selectedEntries)
        {
            var content = byObjectId[entry.ObjectId].Content;
            aggregateSelectedBytes = checked(
                aggregateSelectedBytes + content.Length);
            if (aggregateSelectedBytes >
                limits.MaximumAggregateSelectedBlobBytes ||
                !byPath.TryAdd(entry.RelativePath, content.ToArray()))
            {
                throw DependencyFailure();
            }
        }

        return new ReadOnlyDictionary<string, ReadOnlyMemory<byte>>(byPath);
    }

    private async ValueTask<ExactGitObjectMetadata> ReadMetadataAsync(
        ExactGitObjectId objectId,
        CancellationToken cancellationToken)
    {
        var standardInput = Encoding.ASCII.GetBytes(objectId.Value + "\n");
        var output = await ExecuteAsync(
            ExactGitProcessPolicy.CreateBatchCheckRequest(
                repositoryRoot,
                standardInput),
            cancellationToken).ConfigureAwait(false);
        return ExactGitOutputParser.ParseBatchCheck(output.Span, objectId);
    }

    private static async ValueTask<ReadOnlyMemory<byte>> ExecuteAsync(
        BoundedProcessRequest request,
        CancellationToken cancellationToken)
    {
        var result = await BoundedProcessRunner.ExecuteAsync(
            request,
            cancellationToken).ConfigureAwait(false);
        if (result.ExitCode != 0 || !result.StandardError.IsEmpty)
        {
            throw DependencyFailure();
        }

        return result.StandardOutput;
    }

    private static string[] ParseBoundaryLines(ReadOnlySpan<byte> output)
    {
        string text;
        try
        {
            text = StrictUtf8.GetString(output);
        }
        catch (DecoderFallbackException exception)
        {
            throw new InvalidDataException(
                "Git repository boundary output is not valid UTF-8.",
                exception);
        }

        if (!text.EndsWith('\n') ||
            text.Contains('\r', StringComparison.Ordinal) ||
            text.StartsWith('\uFEFF'))
        {
            throw DependencyFailure();
        }

        var lines = text[..^1].Split('\n');
        if (lines.Length != 4 || lines.Any(string.IsNullOrEmpty))
        {
            throw DependencyFailure();
        }

        return lines;
    }

    private static string NormalizeAbsolutePath(string value)
    {
        if (value.Any(char.IsControl) || !Path.IsPathFullyQualified(value))
        {
            throw DependencyFailure();
        }

        return Path.GetFullPath(value)
            .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
    }

    private static void EnsureOrdinaryDirectory(string path)
    {
        var directory = new DirectoryInfo(path);
        if (!directory.Exists ||
            directory.LinkTarget is not null ||
            directory.Attributes.HasFlag(FileAttributes.ReparsePoint))
        {
            throw DependencyFailure();
        }
    }

    private static bool PathsEqual(string left, string right) =>
        string.Equals(
            NormalizeAbsolutePath(left),
            NormalizeAbsolutePath(right),
            OperatingSystem.IsWindows()
                ? StringComparison.OrdinalIgnoreCase
                : StringComparison.Ordinal);

    private static OperationalDependencyException DependencyFailure() =>
        new("Exact Git object acquisition failed.");
}
