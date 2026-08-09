namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class GovernedReferenceView
{
    private GovernedReferenceView(
        GovernedReferenceKind kind,
        GovernedReferenceSyntax syntax,
        GovernedReferenceResolution resolution,
        string? owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        QualifiedEvidenceHandle reference,
        QualifiedEvidenceHandle? target)
    {
        Kind = kind;
        Syntax = syntax;
        Resolution = resolution;
        OwningRepositoryIdentity = owningRepositoryIdentity;
        CommitObjectId = commitObjectId;
        NormalizedTagName = normalizedTagName;
        CapturedSnapshotIdentity = capturedSnapshotIdentity;
        NormalizedRepositoryRelativePath = normalizedRepositoryRelativePath;
        NormalizedFragment = normalizedFragment;
        Reference = reference;
        Target = target;
    }

    public GovernedReferenceKind Kind { get; }

    public GovernedReferenceSyntax Syntax { get; }

    public GovernedReferenceResolution Resolution { get; }

    public string? OwningRepositoryIdentity { get; }

    public string? CommitObjectId { get; }

    public string? NormalizedTagName { get; }

    public string? CapturedSnapshotIdentity { get; }

    public string? NormalizedRepositoryRelativePath { get; }

    public string? NormalizedFragment { get; }

    public QualifiedEvidenceHandle Reference { get; }

    public QualifiedEvidenceHandle? Target { get; }

    internal static GovernedReferenceView Create(
        GovernedReferenceKind kind,
        GovernedReferenceSyntax syntax,
        GovernedReferenceResolution resolution,
        string? owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        QualifiedEvidenceHandle reference,
        QualifiedEvidenceHandle? target)
    {
        ArgumentNullException.ThrowIfNull(kind);
        ArgumentNullException.ThrowIfNull(syntax);
        ArgumentNullException.ThrowIfNull(resolution);
        ArgumentNullException.ThrowIfNull(reference);

        return new GovernedReferenceView(
            kind,
            syntax,
            resolution,
            owningRepositoryIdentity,
            commitObjectId,
            normalizedTagName,
            capturedSnapshotIdentity,
            normalizedRepositoryRelativePath,
            normalizedFragment,
            reference,
            target);
    }
}
