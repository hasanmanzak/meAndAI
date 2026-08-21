using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CompleteCatalogEvaluation
{
    internal CompleteCatalogEvaluation(
        CompleteCatalogSnapshot catalog,
        NamedExecutionProfile profile,
        EvaluationClosure closure,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> evaluations,
        bool hasKnownViolation,
        bool hasUnresolvedRequiredEvaluation,
        ConformanceVerdict verdict)
    {
        Catalog = catalog;
        Profile = profile;
        Closure = closure;
        Acquisitions = Array.AsReadOnly(acquisitions.ToArray());
        Evaluations = Array.AsReadOnly(evaluations.ToArray());
        HasKnownViolation = hasKnownViolation;
        HasUnresolvedRequiredEvaluation = hasUnresolvedRequiredEvaluation;
        Verdict = verdict;
    }

    public CompleteCatalogSnapshot Catalog { get; }

    public NamedExecutionProfile Profile { get; }

    internal EvaluationClosure Closure { get; }

    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }

    public IReadOnlyList<RuleEvaluation> Evaluations { get; }

    public bool HasKnownViolation { get; }

    public bool HasUnresolvedRequiredEvaluation { get; }

    public ConformanceVerdict Verdict { get; }
}
