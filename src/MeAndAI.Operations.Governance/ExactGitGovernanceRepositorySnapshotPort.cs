using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Governance;

internal sealed class ExactGitGovernanceRepositorySnapshotPort :
    IExactGovernanceRepositorySnapshotPort
{
    private readonly string repositoryRoot;
    private readonly ExactRepositoryAcquisitionLimits limits;

    internal ExactGitGovernanceRepositorySnapshotPort(
        string repositoryRoot,
        ExactRepositoryAcquisitionLimits limits)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(repositoryRoot);
        ArgumentNullException.ThrowIfNull(limits);
        this.repositoryRoot = Path.GetFullPath(repositoryRoot);
        this.limits = limits;
    }

    public async ValueTask<ExactGovernanceRepositoryCapture>
        CaptureSubjectAsync(
            GovernanceRequest request,
            CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(request);
        cancellationToken.ThrowIfCancellationRequested();

        try
        {
            EnsureRepositoryRoot(repositoryRoot, unavailableAllowed: false);
            var reader = new ExactGitObjectDatabaseReader(
                repositoryRoot,
                limits);
            _ = await reader.OpenAsync(cancellationToken).ConfigureAwait(false);
            var treeEntries = await reader.TryReadCommitTreeAsync(
                request.SubjectCommit,
                cancellationToken).ConfigureAwait(false);
            if (treeEntries is null)
            {
                throw DependencyFailure();
            }

            var selectedEntries =
                BoundedGovernanceRepositoryProjection.SelectBlobEntries(
                    treeEntries,
                    request.Profile);
            var selectedBlobs = await reader.TryReadSelectedBlobsAsync(
                selectedEntries,
                missingIsUnavailable: false,
                cancellationToken).ConfigureAwait(false)
                ?? throw DependencyFailure();
            var projectedEntries =
                BoundedGovernanceRepositoryProjection.CreateEntries(
                    treeEntries,
                    selectedBlobs);
            var snapshot = GovernanceRepositorySnapshot.CreateExact(
                request.SubjectCommit,
                projectedEntries);
            return ExactGovernanceRepositoryCapture.Create(
                request.SubjectCommit,
                snapshot,
                treeEntries,
                selectedBlobs.Select(pair =>
                    new KeyValuePair<string, ReadOnlyMemory<byte>>(
                        pair.Key,
                        pair.Value)));
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (OperationalDependencyException)
        {
            throw;
        }
        catch (Exception exception) when (IsAcquisitionFailure(exception))
        {
            throw new OperationalDependencyException(
                "Exact Git repository snapshot capture failed.",
                exception);
        }
    }

    public async ValueTask<ExactIntegratedPolicyVersionCapture>
        CaptureIntegratedPolicyVersionAsync(
            ExactGitCommitId policyCommit,
            CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(policyCommit);
        cancellationToken.ThrowIfCancellationRequested();

        try
        {
            var providerRoot = Path.GetFullPath(Path.Combine(
                repositoryRoot,
                ProtocolIntegrationPath.Canonical.Replace(
                    '/',
                    Path.DirectorySeparatorChar)));
            if (!EnsureIntegratedPathBoundary(providerRoot))
            {
                return ExactIntegratedPolicyVersionCapture.Unavailable(
                    policyCommit);
            }

            if (!EnsureRepositoryRoot(
                    providerRoot,
                    unavailableAllowed: true))
            {
                return ExactIntegratedPolicyVersionCapture.Unavailable(
                    policyCommit);
            }

            EnsureRepositoryRoot(repositoryRoot, unavailableAllowed: false);
            var subjectReader = new ExactGitObjectDatabaseReader(
                repositoryRoot,
                limits);
            var subjectBoundary = await subjectReader.OpenAsync(
                cancellationToken).ConfigureAwait(false);
            var providerReader = new ExactGitObjectDatabaseReader(
                providerRoot,
                limits);
            var providerBoundary = await providerReader.OpenAsync(
                cancellationToken).ConfigureAwait(false);
            EnsureCanonicalSubmoduleAdministration(
                subjectBoundary,
                providerBoundary);

            var versionEntry = await providerReader.ReadRootEntryAsync(
                policyCommit,
                GovernanceRepositoryPath.Version,
                cancellationToken).ConfigureAwait(false);
            if (versionEntry is null || !versionEntry.IsFileBlob)
            {
                return ExactIntegratedPolicyVersionCapture.Unavailable(
                    policyCommit);
            }

            var selected = await providerReader.TryReadSelectedBlobsAsync(
                [versionEntry],
                missingIsUnavailable: true,
                cancellationToken).ConfigureAwait(false);
            if (selected is null ||
                !selected.TryGetValue(
                    GovernanceRepositoryPath.Version,
                    out var content))
            {
                return ExactIntegratedPolicyVersionCapture.Unavailable(
                    policyCommit);
            }

            return ExactIntegratedPolicyVersionCapture.Available(
                policyCommit,
                versionEntry,
                content);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (OperationalDependencyException)
        {
            throw;
        }
        catch (Exception exception) when (IsAcquisitionFailure(exception))
        {
            throw new OperationalDependencyException(
                "Integrated policy Git object capture failed.",
                exception);
        }
    }

    private static bool EnsureRepositoryRoot(
        string root,
        bool unavailableAllowed)
    {
        if (!Directory.Exists(root))
        {
            return unavailableAllowed
                ? false
                : throw DependencyFailure();
        }

        EnsureOrdinary(new DirectoryInfo(root));
        var markerPath = Path.Combine(root, ".git");
        FileSystemInfo? marker = Directory.Exists(markerPath)
            ? new DirectoryInfo(markerPath)
            : File.Exists(markerPath)
                ? new FileInfo(markerPath)
                : null;
        if (marker is null)
        {
            return unavailableAllowed
                ? false
                : throw DependencyFailure();
        }

        EnsureOrdinary(marker);
        return true;
    }

    private bool EnsureIntegratedPathBoundary(string providerRoot)
    {
        var current = new DirectoryInfo(repositoryRoot);
        foreach (var segment in ProtocolIntegrationPath.Canonical.Split('/'))
        {
            current = new DirectoryInfo(Path.Combine(current.FullName, segment));
            if (!current.Exists)
            {
                return false;
            }

            EnsureOrdinary(current);
        }

        if (!PathsEqual(current.FullName, providerRoot))
        {
            throw DependencyFailure();
        }

        return true;
    }

    private static void EnsureCanonicalSubmoduleAdministration(
        ExactGitRepositoryBoundary subject,
        ExactGitRepositoryBoundary provider)
    {
        var modulesRoot = Path.GetFullPath(Path.Combine(
            subject.CommonGitDirectory,
            "modules"));
        if (!IsDescendant(provider.CommonGitDirectory, modulesRoot))
        {
            throw DependencyFailure();
        }
    }

    private static bool IsDescendant(string path, string parent)
    {
        var normalizedPath = Path.GetFullPath(path)
            .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var normalizedParent = Path.GetFullPath(parent)
            .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar) +
            Path.DirectorySeparatorChar;
        return normalizedPath.StartsWith(
            normalizedParent,
            OperatingSystem.IsWindows()
                ? StringComparison.OrdinalIgnoreCase
                : StringComparison.Ordinal);
    }

    private static bool PathsEqual(string left, string right) =>
        string.Equals(
            Path.GetFullPath(left).TrimEnd(
                Path.DirectorySeparatorChar,
                Path.AltDirectorySeparatorChar),
            Path.GetFullPath(right).TrimEnd(
                Path.DirectorySeparatorChar,
                Path.AltDirectorySeparatorChar),
            OperatingSystem.IsWindows()
                ? StringComparison.OrdinalIgnoreCase
                : StringComparison.Ordinal);

    private static void EnsureOrdinary(FileSystemInfo entry)
    {
        if (!entry.Exists ||
            entry.LinkTarget is not null ||
            entry.Attributes.HasFlag(FileAttributes.ReparsePoint))
        {
            throw DependencyFailure();
        }
    }

    private static bool IsAcquisitionFailure(Exception exception) =>
        exception is ArgumentException or
        ArithmeticException or
        IOException or
        InvalidDataException or
        InvalidOperationException or
        NotSupportedException or
        System.Security.SecurityException or
        UnauthorizedAccessException;

    private static OperationalDependencyException DependencyFailure() =>
        new("Exact Git repository acquisition failed.");
}
