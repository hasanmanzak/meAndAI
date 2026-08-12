namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RepositoryTargetResolutionDemandItem
{
    private RepositoryTargetResolutionDemandItem(
        int itemId,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment)
    {
        ItemId = itemId;
        OwningRepositoryIdentity = owningRepositoryIdentity;
        CommitObjectId = commitObjectId;
        NormalizedTagName = normalizedTagName;
        CapturedSnapshotIdentity = capturedSnapshotIdentity;
        NormalizedRepositoryRelativePath = normalizedRepositoryRelativePath;
        NormalizedFragment = normalizedFragment;
    }

    public int ItemId { get; }

    public string OwningRepositoryIdentity { get; }

    public string? CommitObjectId { get; }

    public string? NormalizedTagName { get; }

    public string? CapturedSnapshotIdentity { get; }

    public string? NormalizedRepositoryRelativePath { get; }

    public string? NormalizedFragment { get; }

    internal static RepositoryTargetResolutionDemandItem Create(
        int itemId,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment)
    {
        ArgumentNullException.ThrowIfNull(owningRepositoryIdentity);

        return new RepositoryTargetResolutionDemandItem(
            itemId,
            owningRepositoryIdentity,
            commitObjectId,
            normalizedTagName,
            capturedSnapshotIdentity,
            normalizedRepositoryRelativePath,
            normalizedFragment);
    }
}
