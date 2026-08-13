using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class EvaluationIntentCore
{
    internal static IReadOnlyList<RuleEvaluation> Mint(
        EvaluationClosure closure,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(closure);
        cancellationToken.ThrowIfCancellationRequested();
        var applicability = closure.Applicability;
        if (applicability.Plan.EvidenceSession is not KernelPlanningSession)
        {
            InvalidPlan();
        }

        var session = (KernelPlanningSession)applicability.Plan.EvidenceSession;
        if (!ReferenceEquals(applicability.Plan.EvidenceSession, session) ||
            !ReferenceEquals(applicability.Plan.AuthorityKind, session.AuthorityKind) ||
            !closure.Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !closure.Context.CatalogVersion.Equals(session.CatalogVersion) ||
            !ReferenceEquals(applicability.Context.AuthorityKind, session.AuthorityKind) ||
            !applicability.Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !applicability.Context.CatalogVersion.Equals(session.CatalogVersion))
        {
            InvalidPlan();
        }

        var rules = session.Rules
            .OrderBy(rule => rule.RuleId.Value, StringComparer.Ordinal)
            .ThenBy(rule => rule.RuleRevision.Value)
            .ToArray();
        if (rules.Count() != applicability.Plan.RuleIds.Count ||
            !rules.Select(rule => rule.RuleId).SequenceEqual(
                applicability.Plan.RuleIds.OrderBy(
                    ruleId => ruleId.Value,
                    StringComparer.Ordinal)))
        {
            InvalidPlan();
        }

        var terminalByRule = new Dictionary<RuleId, RuleEvaluation>();
        foreach (var terminal in closure.TerminalEvaluations)
        {
            var rule = rules.SingleOrDefault(candidate =>
                candidate.RuleId.Equals(terminal.RuleId));
            if (rule is null ||
                !rule.RuleRevision.Equals(terminal.RuleRevision) ||
                !terminalByRule.TryAdd(rule.RuleId, terminal) ||
                (!terminal.Status.Equals(RuleEvaluationStatus.NotApplicable) &&
                 !terminal.Status.Equals(RuleEvaluationStatus.NotEvaluated)))
            {
                InvalidPlan();
            }
        }

        var readyRules = rules
            .Where(rule => !terminalByRule.ContainsKey(rule.RuleId))
            .ToArray();
        var activeSlots = readyRules
            .SelectMany(rule => EvaluationSlots(rule, applicability.Plan.Profile))
            .GroupBy(slot => slot.SlotKey, StringComparer.Ordinal)
            .Select(group =>
            {
                var values = group.ToArray();
                if (values.Skip(1).Any(slot =>
                        !RuleDeclaration.SlotsEqual(values[0], slot)))
                {
                    InvalidPlan();
                }

                return values[0];
            })
            .OrderBy(slot => slot.SlotKey, StringComparer.Ordinal)
            .ToArray();
        var outcomes = closure.Acquisitions.ToArray();
        if (outcomes.Any(outcome => outcome is null) ||
            outcomes.Select(outcome => outcome.Slot.SlotKey)
                .Distinct(StringComparer.Ordinal).Count() != outcomes.Length ||
            !outcomes.Select(outcome => outcome.Slot.SlotKey)
                .Order(StringComparer.Ordinal)
                .SequenceEqual(
                    activeSlots.Select(slot => slot.SlotKey),
                    StringComparer.Ordinal))
        {
            InvalidPlan();
        }

        var outcomeBySlot = outcomes.ToDictionary(
            outcome => outcome.Slot.SlotKey,
            StringComparer.Ordinal);
        foreach (var slot in activeSlots)
        {
            var outcome = outcomeBySlot[slot.SlotKey];
            if (!RuleDeclaration.SlotsEqual(slot, outcome.Slot) ||
                (outcome.Status.Equals(AcquisitionStatus.Complete)
                    ? outcome.ContextProof is null
                    : outcome.ContextProof is not null))
            {
                InvalidPlan();
            }
        }

        var handlesBySlot = new Dictionary<string, QualifiedEvidenceHandle>(
            StringComparer.Ordinal);
        var references = new Dictionary<QualifiedEvidenceHandle,
            QualifiedEvidenceReference>(ReferenceEqualityComparer.Instance);
        foreach (var outcome in outcomes.Where(outcome =>
                     outcome.Status.Equals(AcquisitionStatus.Complete)))
        {
            var handle = QualifiedEvidenceHandle.Create();
            handlesBySlot.Add(outcome.Slot.SlotKey, handle);
            references.Add(handle, outcome.ContextProof!);
        }

        var result = terminalByRule.Values.ToList();
        foreach (var rule in readyRules)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var slots = EvaluationSlots(rule, applicability.Plan.Profile);
            var unresolved = slots
                .Where(slot => !outcomeBySlot[slot.SlotKey].Status.Equals(
                    AcquisitionStatus.Complete))
                .Select(slot => slot.SlotKey)
                .Order(StringComparer.Ordinal)
                .ToArray();
            if (unresolved.Length != 0)
            {
                result.Add(new RuleEvaluation(
                    rule.RuleId,
                    rule.RuleRevision,
                    RuleEvaluationStatus.NotEvaluated,
                    false,
                    [],
                    unresolved,
                    [],
                    []));
                continue;
            }

            var registrations = session.ProducerGraph.EvaluatorRegistrations
                .Where(registration =>
                    ReferenceEquals(registration.Declaration, rule))
                .ToArray();
            if (registrations.Length != 1)
            {
                InvalidIntent();
            }

            var access = RuleInputAccess.Create(
                [],
                slots.ToDictionary(
                    slot => slot.SlotKey,
                    slot => handlesBySlot[slot.SlotKey],
                    StringComparer.Ordinal),
                RejectingReferenceLookup.Instance);
            var intent = registrations[0].Evaluator.Evaluate(
                RuleEvaluationInput.Create(
                    rule.RuleId,
                    rule.RuleRevision,
                    applicability.Plan.Profile,
                    access),
                cancellationToken) ?? InvalidIntent<EvaluationIntent>();
            result.Add(Mint(rule, intent, references));
        }

        cancellationToken.ThrowIfCancellationRequested();
        var canonical = Array.AsReadOnly(result
            .OrderBy(item => item.RuleId.Value, StringComparer.Ordinal)
            .ThenBy(item => item.RuleRevision.Value)
            .ToArray());
        return canonical;
    }

    private static IReadOnlyList<EvidenceSlotDeclaration> EvaluationSlots(
        RuleDeclaration rule,
        ExecutionProfile profile) => Array.AsReadOnly(rule.EvaluationSlots
        .Where(slot => slot.ProfileSurfaces.Values.Any(
            profile.Surfaces.Values.Contains))
        .OrderBy(slot => slot.SlotKey, StringComparer.Ordinal)
        .ToArray());

    private static RuleEvaluation Mint(
        RuleDeclaration rule,
        EvaluationIntent intent,
        IReadOnlyDictionary<QualifiedEvidenceHandle,
            QualifiedEvidenceReference> references)
    {
        var findings = intent.Findings.Select(finding =>
        {
            var declarations = rule.Findings.Where(declaration =>
                declaration.Code.Equals(finding.Code)).ToArray();
            if (declarations.Length != 1)
            {
                return InvalidIntent<RuleFinding>();
            }

            var declaration = declarations[0];
            var primary = Resolve(finding.PrimaryReference, references);
            var related = Resolve(finding.RelatedReferences, references);
            if (!declaration.AllowedPrimaryReferenceKinds.Contains(primary.Kind) ||
                related.Any(reference =>
                    !declaration.AllowedRelatedReferenceKinds.Contains(
                        reference.Kind)))
            {
                return InvalidIntent<RuleFinding>();
            }

            return new RuleFinding(
                rule.RuleId,
                rule.RuleRevision,
                declaration.Code,
                declaration.Severity,
                declaration.Remediation,
                primary,
                related.Order(ReferenceComparer.Instance));
        }).OrderBy(finding => finding.Code.Value, StringComparer.Ordinal)
            .ThenBy(finding => finding.PrimaryReference, ReferenceComparer.Instance)
            .ToArray();
        var failures = intent.Failures.Select(failure =>
        {
            if (!rule.EvaluationFailureCodes.Contains(failure.Code))
            {
                return InvalidIntent<RuleEvaluationFailure>();
            }

            return new RuleEvaluationFailure(
                rule.RuleId,
                rule.RuleRevision,
                failure.Code,
                Resolve(failure.PrimaryReference, references),
                Resolve(failure.RelatedReferences, references)
                    .Order(ReferenceComparer.Instance));
        }).OrderBy(failure => failure.Code.Value, StringComparer.Ordinal)
            .ThenBy(failure => failure.PrimaryReference, ReferenceComparer.Instance)
            .ToArray();
        var status = failures.Length != 0
            ? RuleEvaluationStatus.NotEvaluated
            : findings.Length != 0
                ? RuleEvaluationStatus.Violated
                : RuleEvaluationStatus.Satisfied;
        return new RuleEvaluation(
            rule.RuleId,
            rule.RuleRevision,
            status,
            false,
            [],
            [],
            findings,
            failures);
    }

    private static QualifiedEvidenceReference Resolve(
        QualifiedEvidenceHandle handle,
        IReadOnlyDictionary<QualifiedEvidenceHandle,
            QualifiedEvidenceReference> references) =>
        references.TryGetValue(handle, out var reference)
            ? reference
            : InvalidIntent<QualifiedEvidenceReference>();

    private static IReadOnlyList<QualifiedEvidenceReference> Resolve(
        IEnumerable<QualifiedEvidenceHandle> handles,
        IReadOnlyDictionary<QualifiedEvidenceHandle,
            QualifiedEvidenceReference> references) => Array.AsReadOnly(handles
        .Select(handle => Resolve(handle, references))
        .ToArray());

    private static void InvalidPlan() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    private static void InvalidIntent() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.IntentInvalid);

    private static T InvalidIntent<T>()
    {
        InvalidIntent();
        return default!;
    }

    private sealed class RejectingReferenceLookup : IExpectedReferenceLookup
    {
        internal static RejectingReferenceLookup Instance { get; } = new();

        public QualifiedEvidenceHandle Require(
            string selectorKey,
            QualifiedEvidenceHandle parent) =>
            throw new InvalidOperationException(
                "Expected references are unavailable during intent minting.");
    }

    private sealed class ReferenceComparer :
        IComparer<QualifiedEvidenceReference>
    {
        internal static ReferenceComparer Instance { get; } = new();

        public int Compare(
            QualifiedEvidenceReference? left,
            QualifiedEvidenceReference? right)
        {
            if (ReferenceEquals(left, right))
            {
                return 0;
            }

            if (left is null)
            {
                return -1;
            }

            if (right is null)
            {
                return 1;
            }

            return Compare(
                [
                    left.Kind.Value,
                    left.SlotKey,
                    left.RequirementKey,
                    left.Scope.Target.SubjectIdentity,
                    left.Scope.Target.SourceIdentity,
                    left.Scope.Target.Surface.Value,
                    left.Scope.Target.SnapshotKind.Value,
                    left.Scope.Target.TargetIdentity,
                    left.QualificationProofDigest.Value,
                ],
                [
                    right.Kind.Value,
                    right.SlotKey,
                    right.RequirementKey,
                    right.Scope.Target.SubjectIdentity,
                    right.Scope.Target.SourceIdentity,
                    right.Scope.Target.Surface.Value,
                    right.Scope.Target.SnapshotKind.Value,
                    right.Scope.Target.TargetIdentity,
                    right.QualificationProofDigest.Value,
                ]);
        }

        private static int Compare(
            IReadOnlyList<string> left,
            IReadOnlyList<string> right)
        {
            for (var index = 0; index < left.Count; index++)
            {
                var comparison = StringComparer.Ordinal.Compare(
                    left[index],
                    right[index]);
                if (comparison != 0)
                {
                    return comparison;
                }
            }

            return 0;
        }
    }
}
