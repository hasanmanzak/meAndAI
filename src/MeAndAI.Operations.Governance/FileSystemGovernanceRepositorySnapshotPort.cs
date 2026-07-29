using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Governance;

internal sealed class FileSystemGovernanceRepositorySnapshotPort :
    IGovernanceRepositorySnapshotPort
{
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

        var entries = new List<GovernanceRepositoryEntry>();
        CaptureFeatureEntries(
            root,
            docsDirectory,
            entries,
            cancellationToken);
        CaptureDecisionEntries(
            root,
            docsDirectory,
            entries,
            cancellationToken);

        return GovernanceRepositorySnapshot.CreateCandidate(entries);
    }

    private static void CaptureFeatureEntries(
        DirectoryInfo root,
        DirectoryInfo docsDirectory,
        List<GovernanceRepositoryEntry> entries,
        CancellationToken cancellationToken)
    {
        var featuresDirectory = FindExactOrdinaryDirectory(
            docsDirectory,
            "features");
        if (featuresDirectory is null)
        {
            return;
        }

        foreach (var entry in EnumerateOrdinal(featuresDirectory))
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

            foreach (var child in EnumerateOrdinal(directory))
            {
                cancellationToken.ThrowIfCancellationRequested();
                EnsureOrdinaryEntry(child);
                if (child is FileInfo file && file.Exists)
                {
                    entries.Add(GovernanceRepositoryEntry.File(
                        $"{relativeDirectory}/{file.Name}",
                        File.ReadAllBytes(file.FullName)));
                }
            }
        }
    }

    private static void CaptureDecisionEntries(
        DirectoryInfo root,
        DirectoryInfo docsDirectory,
        List<GovernanceRepositoryEntry> entries,
        CancellationToken cancellationToken)
    {
        var decisionsDirectory = FindExactOrdinaryDirectory(
            docsDirectory,
            "decisions");
        if (decisionsDirectory is null)
        {
            return;
        }

        foreach (var entry in EnumerateOrdinal(decisionsDirectory))
        {
            cancellationToken.ThrowIfCancellationRequested();
            EnsureOrdinaryEntry(entry);
            if (entry is not FileInfo file || !file.Exists)
            {
                continue;
            }

            entries.Add(GovernanceRepositoryEntry.File(
                NormalizeRelativePath(
                    Path.GetRelativePath(root.FullName, file.FullName)),
                File.ReadAllBytes(file.FullName)));
        }
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

    private static IEnumerable<FileSystemInfo> EnumerateOrdinal(
        DirectoryInfo directory) =>
        directory
            .EnumerateFileSystemInfos("*", SearchOption.TopDirectoryOnly)
            .OrderBy(entry => entry.Name, StringComparer.Ordinal);
}
