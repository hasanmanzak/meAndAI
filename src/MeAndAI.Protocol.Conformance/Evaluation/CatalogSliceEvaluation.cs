using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CatalogSliceEvaluation
{
    internal CatalogSliceEvaluation(
        CatalogSliceDeclaration catalog,
        ExactSha256Digest manifestDigest,
        ExecutionProfile profile,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> evaluations,
        bool hasKnownViolation,
        bool hasUnresolvedRequiredEvaluation)
    {
        Catalog = catalog;
        ManifestDigest = manifestDigest;
        Profile = profile;
        Acquisitions = Array.AsReadOnly(acquisitions.ToArray());
        Evaluations = Array.AsReadOnly(evaluations.ToArray());
        HasKnownViolation = hasKnownViolation;
        HasUnresolvedRequiredEvaluation = hasUnresolvedRequiredEvaluation;
    }

    public CatalogSliceDeclaration Catalog { get; }

    public ExactSha256Digest ManifestDigest { get; }

    public ExecutionProfile Profile { get; }

    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }

    public IReadOnlyList<RuleEvaluation> Evaluations { get; }

    public bool HasKnownViolation { get; }

    public bool HasUnresolvedRequiredEvaluation { get; }
}
