namespace MeAndAI.Operations.Governance.Core.Repository;

public enum GovernanceRepositoryEntryKind
{
    Directory,
    File,
}

public sealed record GovernanceRepositoryEntry
{
    private readonly byte[] _content;

    private GovernanceRepositoryEntry(
        string relativePath,
        GovernanceRepositoryEntryKind kind,
        ReadOnlyMemory<byte> content)
    {
        Path = RepositoryRelativePath.From(relativePath);
        Kind = kind;
        _content = content.ToArray();
    }

    public RepositoryRelativePath Path { get; }

    public string RelativePath => Path.Value;

    public GovernanceRepositoryEntryKind Kind { get; }

    public ReadOnlyMemory<byte> Content => _content.ToArray();

    internal ReadOnlySpan<byte> CapturedContent => _content;

    public static GovernanceRepositoryEntry Directory(string relativePath) =>
        new(
            relativePath,
            GovernanceRepositoryEntryKind.Directory,
            ReadOnlyMemory<byte>.Empty);

    public static GovernanceRepositoryEntry File(string relativePath) =>
        File(relativePath, ReadOnlyMemory<byte>.Empty);

    public static GovernanceRepositoryEntry File(
        string relativePath,
        ReadOnlyMemory<byte> content) =>
        new(relativePath, GovernanceRepositoryEntryKind.File, content);
}
