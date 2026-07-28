using System.Text.RegularExpressions;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Governance;

internal sealed partial class FileSystemGovernanceRepositorySnapshotPort :
    IGovernanceRepositorySnapshotPort
{
    private static readonly string[] RequiredFeatureFiles =
        ["README.md", "test-cases.md"];

    private readonly string repositoryPath;

    public FileSystemGovernanceRepositorySnapshotPort(string repositoryPath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(repositoryPath);
        this.repositoryPath = repositoryPath;
    }

    public ValueTask<GovernanceRepositorySnapshot> CaptureCandidateAsync(
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        try
        {
            return ValueTask.FromResult(Capture(cancellationToken));
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception) when (
            exception is IOException or
            UnauthorizedAccessException or
            System.Security.SecurityException or
            ArgumentException)
        {
            throw new OperationalDependencyException(
                "Repository snapshot capture failed.",
                exception);
        }
    }

    private GovernanceRepositorySnapshot Capture(
        CancellationToken cancellationToken)
    {
        var root = new DirectoryInfo(Path.GetFullPath(repositoryPath));
        if (!root.Exists)
        {
            throw new DirectoryNotFoundException(
                "The repository directory does not exist.");
        }

        EnsureOrdinaryEntry(root);

        var docsDirectory = FindExactOrdinaryDirectory(root, "docs");
        if (docsDirectory is null)
        {
            return GovernanceRepositorySnapshot.CreateCandidate([]);
        }

        var featuresDirectory = FindExactOrdinaryDirectory(
            docsDirectory,
            "features");
        if (featuresDirectory is null)
        {
            return GovernanceRepositorySnapshot.CreateCandidate([]);
        }

        var entries = new List<GovernanceRepositoryEntry>();
        foreach (var entry in featuresDirectory
                     .EnumerateFileSystemInfos("*", SearchOption.TopDirectoryOnly)
                     .Where(item => FeatureDirectoryNamePattern().IsMatch(item.Name))
                     .OrderBy(item => item.Name, StringComparer.Ordinal))
        {
            cancellationToken.ThrowIfCancellationRequested();
            EnsureOrdinaryEntry(entry);
            if (entry is not DirectoryInfo directory || !directory.Exists)
            {
                continue;
            }

            var relativeDirectory = NormalizeRelativePath(
                Path.GetRelativePath(root.FullName, directory.FullName));
            entries.Add(GovernanceRepositoryEntry.Directory(relativeDirectory));

            var children = directory
                .EnumerateFileSystemInfos("*", SearchOption.TopDirectoryOnly)
                .ToArray();

            foreach (var requiredFile in RequiredFeatureFiles)
            {
                var exactEntry = children.SingleOrDefault(child =>
                    string.Equals(
                        child.Name,
                        requiredFile,
                        StringComparison.Ordinal));
                if (exactEntry is null)
                {
                    continue;
                }

                EnsureOrdinaryEntry(exactEntry);
                if (exactEntry is FileInfo file && file.Exists)
                {
                    entries.Add(GovernanceRepositoryEntry.File(
                        $"{relativeDirectory}/{file.Name}"));
                }
            }
        }

        return GovernanceRepositorySnapshot.CreateCandidate(entries);
    }

    private static void EnsureOrdinaryEntry(FileSystemInfo entry)
    {
        if (entry.LinkTarget is not null ||
            entry.Attributes.HasFlag(FileAttributes.ReparsePoint))
        {
            throw new IOException(
                "Repository snapshot entries cannot be links or reparse points.");
        }
    }

    private static DirectoryInfo? FindExactOrdinaryDirectory(
        DirectoryInfo parent,
        string name)
    {
        var entry = parent
            .EnumerateFileSystemInfos("*", SearchOption.TopDirectoryOnly)
            .SingleOrDefault(item => string.Equals(
                item.Name,
                name,
                StringComparison.Ordinal));
        if (entry is null)
        {
            return null;
        }

        EnsureOrdinaryEntry(entry);
        return entry is DirectoryInfo directory && directory.Exists
            ? directory
            : null;
    }

    private static string NormalizeRelativePath(string path) =>
        path.Replace('\\', '/');

    [GeneratedRegex(
        "^FEAT-[0-9]{4}-[^/]+$",
        RegexOptions.CultureInvariant)]
    private static partial Regex FeatureDirectoryNamePattern();
}
