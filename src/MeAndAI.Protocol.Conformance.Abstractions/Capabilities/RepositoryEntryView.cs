namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RepositoryEntryView
{
    private RepositoryEntryView(
        string repositoryRelativePath,
        RepositoryEntryKind kind,
        QualifiedEvidenceHandle evidence)
    {
        RepositoryRelativePath = repositoryRelativePath;
        Kind = kind;
        Evidence = evidence;
    }

    public string RepositoryRelativePath { get; }

    public RepositoryEntryKind Kind { get; }

    public QualifiedEvidenceHandle Evidence { get; }

    internal static RepositoryEntryView Create(
        string repositoryRelativePath,
        RepositoryEntryKind kind,
        QualifiedEvidenceHandle evidence)
    {
        ArgumentNullException.ThrowIfNull(repositoryRelativePath);
        ArgumentNullException.ThrowIfNull(kind);
        ArgumentNullException.ThrowIfNull(evidence);

        return new RepositoryEntryView(repositoryRelativePath, kind, evidence);
    }
}
