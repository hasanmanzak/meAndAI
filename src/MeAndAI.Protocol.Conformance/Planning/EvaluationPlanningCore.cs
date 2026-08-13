using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class EvaluationPlanningCore
{
    private const string RepositoryTargetSlot =
        "protocol.slot.repository-target-resolution";

    internal static EvaluationAdvanceResult Plan(
        KernelPlanningSession session,
        ApplicabilityClosure closure,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(closure);
        cancellationToken.ThrowIfCancellationRequested();
        if (!ReferenceEquals(closure.Plan.EvidenceSession, session) ||
            !ReferenceEquals(closure.Plan.AuthorityKind, session.AuthorityKind) ||
            !closure.Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !closure.Context.CatalogVersion.Equals(session.CatalogVersion))
        {
            Invalid();
        }

        session.BeginEvaluationPlan(closure);
        try
        {
            var terminalIds = closure.TerminalEvaluations
                .Select(item => item.RuleId)
                .ToHashSet();
            var readyRules = closure.Plan.RuleIds
                .Where(ruleId => !terminalIds.Contains(ruleId))
                .Select(ruleId => session.Rules.Single(rule =>
                    rule.RuleId.Equals(ruleId)))
                .OrderBy(rule => rule.RuleId.Value, StringComparer.Ordinal)
                .ThenBy(rule => rule.RuleRevision.Value)
                .ToArray();
            var slots = CanonicalSlots(readyRules, closure.Plan.Profile);
            var instructions = new List<AcquisitionInstruction>();
            foreach (var slot in slots)
            {
                cancellationToken.ThrowIfCancellationRequested();
                if (closure.Context.AdmittedSlotKeys.Contains(
                        slot.SlotKey,
                        StringComparer.Ordinal))
                {
                    continue;
                }

                var target = ResolveTarget(closure, slot);
                if (!string.Equals(
                        slot.SlotKey,
                        RepositoryTargetSlot,
                        StringComparison.Ordinal))
                {
                    instructions.Add(AcquisitionInstruction.CreateEvaluation(
                        session.ManifestDigest,
                        slot,
                        target,
                        0,
                        []));
                    continue;
                }

                var candidates = Project(session, slot, target, cancellationToken);
                var items = CandidateShape.CanonicalItems(candidates);
                foreach (var ownerShard in items
                             .GroupBy(item => item.OwningRepositoryIdentity,
                                 StringComparer.Ordinal)
                             .OrderBy(group => group.Key, StringComparer.Ordinal))
                {
                    instructions.Add(AcquisitionInstruction.CreateEvaluation(
                        session.ManifestDigest,
                        slot,
                        target,
                        0,
                        ownerShard.OrderBy(item => item.ItemId)));
                }
            }

            instructions = instructions
                .OrderBy(item => item.Slot.SlotKey, StringComparer.Ordinal)
                .ThenBy(item => item.Target.SubjectIdentity, StringComparer.Ordinal)
                .ThenBy(item => item.Target.SourceIdentity, StringComparer.Ordinal)
                .ThenBy(item => item.DemandItems.Count == 0 ? 0 : 1)
                .ThenBy(item => item.DemandItems.FirstOrDefault()
                    ?.OwningRepositoryIdentity, StringComparer.Ordinal)
                .ThenBy(item => item.DemandItems.FirstOrDefault()?.ItemId ?? -1)
                .ToList();

            EvaluationAdvanceResult result = instructions.Count == 0
                ? new EvaluationClosure(
                    0,
                    closure,
                    closure.Context,
                    closure.Acquisitions,
                    closure.TerminalEvaluations)
                : new EvaluationPlan(
                    0,
                    closure,
                    slots,
                    instructions,
                    session);
            if (result is null)
            {
                session.AbandonEvaluationPlan(closure);
                return null!;
            }

            session.CompleteEvaluationPlan(closure, result);
            return result;
        }
        catch
        {
            session.AbandonEvaluationPlan(closure);
            throw;
        }
    }

    private static IReadOnlyList<EvidenceSlotDeclaration> CanonicalSlots(
        IReadOnlyList<RuleDeclaration> rules,
        ExecutionProfile profile)
    {
        var slots = new Dictionary<string, EvidenceSlotDeclaration>(
            StringComparer.Ordinal);
        foreach (var slot in rules
                     .SelectMany(rule => rule.EvaluationSlots)
                     .Where(slot => slot.ProfileSurfaces.Values.Any(
                         profile.Surfaces.Values.Contains)))
        {
            if (slots.TryGetValue(slot.SlotKey, out var existing) &&
                !RuleDeclaration.SlotsEqual(existing, slot))
            {
                Invalid();
            }

            slots[slot.SlotKey] = slot;
        }

        return Array.AsReadOnly(slots.Values
            .OrderBy(slot => slot.SlotKey, StringComparer.Ordinal)
            .ToArray());
    }

    private static AcquisitionTarget ResolveTarget(
        ApplicabilityClosure closure,
        EvidenceSlotDeclaration slot)
    {
        var surface = slot.TargetSelectorKey switch
        {
            "protocol.target.repository-snapshot" or
            "protocol.target.repository-governed-body-set" or
            "protocol.target.repository-target-resolution-set" =>
                SurfaceKind.Repository,
            "protocol.target.provider-governed-body-set" => SurfaceKind.Provider,
            _ => throw Error(),
        };
        var matches = closure.Plan.Targets
            .Where(target => target.Surface.Equals(surface))
            .ToArray();
        return matches.Length == 1 ? matches[0] : throw Error();
    }

    private static IReadOnlyList<RepositoryTargetResolutionDemandCandidate> Project(
        KernelPlanningSession session,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        CancellationToken cancellationToken)
    {
        var registrations = session.ProducerGraph.DemandProjectorRegistrations
            .Where(item => string.Equals(
                item.Declaration.OutputSlotKey,
                slot.SlotKey,
                StringComparison.Ordinal))
            .ToArray();
        if (registrations.Length != 1)
        {
            Invalid();
        }

        return registrations[0].Accept(
            new ProjectionRegistrationVisitor(slot, target, cancellationToken));
    }

    private sealed class ProjectionRegistrationVisitor(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        CancellationToken cancellationToken) :
        IDemandProjectorRegistrationVisitor<
            IReadOnlyList<RepositoryTargetResolutionDemandCandidate>>
    {
        public IReadOnlyList<RepositoryTargetResolutionDemandCandidate>
            Visit<TCapability>(DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability
        {
            var allowance = SemanticResourceAllowance.Create(
                registration.Declaration.Budget,
                SemanticResourceUsage.Create(0, 0, 0, 0));
            var input = DemandProjectionInput<TCapability>.Create(
                slot,
                target,
                [],
                [],
                [],
                [],
                allowance);
            var intent = registration.Projector.Project(input, cancellationToken) ??
                throw Error();
            return intent.Accept(ProjectionIntentVisitor.Instance);
        }
    }

    private sealed class ProjectionIntentVisitor :
        IDemandProjectionIntentVisitor<
            IReadOnlyList<RepositoryTargetResolutionDemandCandidate>>
    {
        internal static ProjectionIntentVisitor Instance { get; } = new();

        public IReadOnlyList<RepositoryTargetResolutionDemandCandidate>
            VisitProjected(DemandProjectionProduct product) => product.Candidates;

        public IReadOnlyList<RepositoryTargetResolutionDemandCandidate>
            VisitFailed(SemanticFailureIntent failure) => throw Error();
    }

    private sealed record CandidateShape(
        string Owner,
        int Kind,
        string? Commit,
        string? Tag,
        string? Capture,
        string? Path,
        string? Fragment)
    {
        internal static IReadOnlyList<RepositoryTargetResolutionDemandItem>
            CanonicalItems(
                IReadOnlyList<RepositoryTargetResolutionDemandCandidate> candidates)
        {
            if (candidates.Any(candidate => candidate is null))
            {
                Invalid();
            }

            var shapes = candidates
                .Select(candidate => candidate.Accept(CandidateVisitor.Instance))
                .OrderBy(item => item.Owner, StringComparer.Ordinal)
                .ThenBy(item => item.Kind)
                .ThenBy(item => item.Commit, StringComparer.Ordinal)
                .ThenBy(item => item.Tag, StringComparer.Ordinal)
                .ThenBy(item => item.Capture, StringComparer.Ordinal)
                .ThenBy(item => item.Path, StringComparer.Ordinal)
                .ThenBy(item => item.Fragment, StringComparer.Ordinal)
                .ToArray();
            return Array.AsReadOnly(shapes.Select((item, index) =>
                RepositoryTargetResolutionDemandItem.Create(
                    index,
                    item.Owner,
                    item.Commit,
                    item.Tag,
                    item.Capture,
                    item.Path,
                    item.Fragment)).ToArray());
        }
    }

    private sealed class CandidateVisitor :
        IRepositoryTargetResolutionDemandCandidateVisitor<CandidateShape>
    {
        internal static CandidateVisitor Instance { get; } = new();

        public CandidateShape VisitCommitObject(
            string owner,
            string commit,
            string? path,
            string? fragment,
            QualifiedEvidenceHandle sourceReference,
            QualifiedEvidenceHandle sourceAuthority) =>
            new(owner, 0, commit, null, null, path, fragment);

        public CandidateShape VisitTagRoot(
            string owner,
            string tag,
            QualifiedEvidenceHandle sourceReference,
            QualifiedEvidenceHandle sourceAuthority) =>
            new(owner, 1, null, tag, null, null, null);

        public CandidateShape VisitCapturedSnapshotPath(
            string owner,
            string capture,
            string path,
            string fragment,
            string expectedContentIdentity,
            QualifiedEvidenceHandle sourceReference,
            QualifiedEvidenceHandle sourceAuthority) =>
            new(owner, 2, null, null, capture, path, fragment);
    }

    private static void Invalid() => throw Error();

    private static CatalogIntegrityException Error() =>
        new(CatalogIntegrityCode.PlanStateInvalid);
}
