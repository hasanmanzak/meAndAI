namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RepositoryTargetResolutionView
{
    private RepositoryTargetResolutionView(
        QualifiedEvidenceHandle reference,
        GovernedReferenceResolution resolution,
        QualifiedEvidenceHandle resolutionEvidence,
        QualifiedEvidenceHandle? commit,
        QualifiedEvidenceHandle? tag,
        QualifiedEvidenceHandle? target)
    {
        Reference = reference;
        Resolution = resolution;
        ResolutionEvidence = resolutionEvidence;
        Commit = commit;
        Tag = tag;
        Target = target;
    }

    public QualifiedEvidenceHandle Reference { get; }

    public GovernedReferenceResolution Resolution { get; }

    public QualifiedEvidenceHandle ResolutionEvidence { get; }

    public QualifiedEvidenceHandle? Commit { get; }

    public QualifiedEvidenceHandle? Tag { get; }

    public QualifiedEvidenceHandle? Target { get; }

    internal static RepositoryTargetResolutionView Create(
        QualifiedEvidenceHandle reference,
        GovernedReferenceResolution resolution,
        QualifiedEvidenceHandle resolutionEvidence,
        QualifiedEvidenceHandle? commit,
        QualifiedEvidenceHandle? tag,
        QualifiedEvidenceHandle? target)
    {
        ArgumentNullException.ThrowIfNull(reference);
        ArgumentNullException.ThrowIfNull(resolution);
        ArgumentNullException.ThrowIfNull(resolutionEvidence);

        return new RepositoryTargetResolutionView(
            reference,
            resolution,
            resolutionEvidence,
            commit,
            tag,
            target);
    }
}
