using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class EvaluationAggregationCore
{
    internal static CatalogSliceEvaluation EvaluateSlice(
        KernelPlanningSession session,
        CatalogSliceDeclaration catalog,
        EvaluationClosure closure,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        var aggregation = Evaluate(session, closure, cancellationToken);
        return new CatalogSliceEvaluation(
            catalog,
            session.ManifestDigest,
            closure.Applicability.Plan.Profile,
            aggregation.Acquisitions,
            aggregation.Evaluations,
            aggregation.HasKnownViolation,
            aggregation.HasUnresolvedRequiredEvaluation);
    }

    internal static CompleteCatalogEvaluation EvaluateComplete(
        KernelPlanningSession session,
        CompleteCatalogSnapshot catalog,
        EvaluationClosure closure,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(closure);
        var profile = session.GetNamedProfile(closure.Applicability.Plan);
        var aggregation = Evaluate(session, closure, cancellationToken);
        var verdict = aggregation.HasUnresolvedRequiredEvaluation
            ? ConformanceVerdict.Indeterminate
            : aggregation.HasKnownViolation
                ? ConformanceVerdict.NonConforming
                : ConformanceVerdict.Conforming;
        return new CompleteCatalogEvaluation(
            catalog,
            profile,
            aggregation.Acquisitions,
            aggregation.Evaluations,
            aggregation.HasKnownViolation,
            aggregation.HasUnresolvedRequiredEvaluation,
            verdict);
    }

    private static Aggregation Evaluate(
        KernelPlanningSession session,
        EvaluationClosure closure,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(closure);
        cancellationToken.ThrowIfCancellationRequested();
        var applicability = closure.Applicability;
        if (!ReferenceEquals(applicability.Plan.EvidenceSession, session) ||
            !ReferenceEquals(applicability.Plan.AuthorityKind, session.AuthorityKind) ||
            !ReferenceEquals(applicability.Context.AuthorityKind, session.AuthorityKind) ||
            !applicability.Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !applicability.Context.CatalogVersion.Equals(session.CatalogVersion) ||
            !closure.Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !closure.Context.CatalogVersion.Equals(session.CatalogVersion))
        {
            Invalid();
        }

        session.BeginEvaluate(closure);
        try
        {
            var acquisitions = closure.Acquisitions.ToArray();
            if (acquisitions.Any(item => item is null) ||
                acquisitions.Select(item => item.Slot.SlotKey)
                    .Distinct(StringComparer.Ordinal).Count() != acquisitions.Length)
            {
                Invalid();
            }

            var orderedAcquisitions = acquisitions
                .OrderBy(item => item.Slot.SlotKey, StringComparer.Ordinal)
                .ToArray();
            var evaluations = EvaluationIntentCore.Mint(
                closure,
                cancellationToken).ToArray();
            var rules = session.Rules
                .OrderBy(item => item.RuleId.Value, StringComparer.Ordinal)
                .ThenBy(item => item.RuleRevision.Value)
                .ToArray();
            if (evaluations.Any(item => item is null) ||
                evaluations.Length != rules.Length ||
                !evaluations.Select(item => (item.RuleId, item.RuleRevision))
                    .SequenceEqual(rules.Select(item =>
                        (item.RuleId, item.RuleRevision))))
            {
                Invalid();
            }

            cancellationToken.ThrowIfCancellationRequested();
            var result = new Aggregation(
                Array.AsReadOnly(orderedAcquisitions),
                Array.AsReadOnly(evaluations),
                evaluations.Any(item =>
                    item.Status.Equals(RuleEvaluationStatus.Violated)),
                orderedAcquisitions.Any(item =>
                    !item.Status.Equals(AcquisitionStatus.Complete)) ||
                evaluations.Any(item =>
                    item.Status.Equals(RuleEvaluationStatus.NotEvaluated)));
            session.CompleteEvaluate(closure);
            return result;
        }
        catch
        {
            session.AbandonEvaluate(closure);
            throw;
        }
    }

    private static void Invalid() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    private sealed record Aggregation(
        IReadOnlyList<SealedAcquisitionOutcome> Acquisitions,
        IReadOnlyList<RuleEvaluation> Evaluations,
        bool HasKnownViolation,
        bool HasUnresolvedRequiredEvaluation);
}
