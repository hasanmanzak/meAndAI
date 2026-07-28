namespace MeAndAI.Operations.Governance.Core.Repository;

public enum GovernanceRepositoryEntryKind
{
    Directory,
    File,
}

public sealed record GovernanceRepositoryEntry
{
    private GovernanceRepositoryEntry(
        string relativePath,
        GovernanceRepositoryEntryKind kind)
    {
        Path = RepositoryRelativePath.From(relativePath);
        Kind = kind;
    }

    public RepositoryRelativePath Path { get; }

    public string RelativePath => Path.Value;

    public GovernanceRepositoryEntryKind Kind { get; }

    public static GovernanceRepositoryEntry Directory(string relativePath) =>
        new(relativePath, GovernanceRepositoryEntryKind.Directory);

    public static GovernanceRepositoryEntry File(string relativePath) =>
        new(relativePath, GovernanceRepositoryEntryKind.File);

}
