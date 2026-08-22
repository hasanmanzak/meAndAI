using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal sealed class KernelPlanningSession : IPlanBoundEvidenceSession
{
    private readonly object _stateGate = new();
    private readonly HashSet<ApplicabilityPlan> _closing =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<ApplicabilityPlan> _closed =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<ApplicabilityClosure> _planningEvaluation =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<ApplicabilityClosure> _plannedEvaluation =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<EvaluationPlan> _advancingEvaluation =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<EvaluationPlan> _issuedEvaluationPlans =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<EvaluationPlan> _advancedEvaluation =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<EvaluationClosure> _issuedEvaluationClosures =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<EvaluationClosure> _evaluating =
        new(ReferenceEqualityComparer.Instance);
    private readonly HashSet<EvaluationClosure> _evaluated =
        new(ReferenceEqualityComparer.Instance);
    private readonly Dictionary<ApplicabilityPlan, NamedExecutionProfile>
        _namedProfiles = new(ReferenceEqualityComparer.Instance);

    internal KernelPlanningSession(
        FinalizedPolicyManifest manifest,
        IPolicyActivationProof activationProof,
        CatalogAuthorityKind authorityKind,
        ExactSha256Digest manifestDigest,
        CatalogVersion catalogVersion,
        IEnumerable<RuleDeclaration> rules,
        CatalogSliceProducerGraph producerGraph)
    {
        Manifest = manifest ?? throw new ArgumentNullException(nameof(manifest));
        ActivationProof = activationProof ??
            throw new ArgumentNullException(nameof(activationProof));
        AuthorityKind = authorityKind ??
            throw new ArgumentNullException(nameof(authorityKind));
        ManifestDigest = manifestDigest ??
            throw new ArgumentNullException(nameof(manifestDigest));
        CatalogVersion = catalogVersion ??
            throw new ArgumentNullException(nameof(catalogVersion));
        ArgumentNullException.ThrowIfNull(rules);
        Rules = Array.AsReadOnly(rules.ToArray());
        ProducerGraph = producerGraph ??
            throw new ArgumentNullException(nameof(producerGraph));
    }

    internal CatalogAuthorityKind AuthorityKind { get; }

    internal ExactSha256Digest ManifestDigest { get; }

    internal FinalizedPolicyManifest Manifest { get; }

    internal IPolicyActivationProof ActivationProof { get; }

    internal CatalogVersion CatalogVersion { get; }

    internal IReadOnlyList<RuleDeclaration> Rules { get; }

    internal CatalogSliceProducerGraph ProducerGraph { get; }

    internal void RegisterNamedProfile(
        ApplicabilityPlan plan,
        NamedExecutionProfile profile)
    {
        lock (_stateGate)
        {
            if (!_namedProfiles.TryAdd(plan, profile))
            {
                throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
            }
        }
    }

    internal NamedExecutionProfile GetNamedProfile(ApplicabilityPlan plan)
    {
        lock (_stateGate)
        {
            return _namedProfiles.TryGetValue(plan, out var profile)
                ? profile
                : throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
        }
    }

    internal void BeginClose(ApplicabilityPlan plan)
    {
        lock (_stateGate)
        {
            if (_closed.Contains(plan) || !_closing.Add(plan))
            {
                throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
            }
        }
    }

    internal void CompleteClose(ApplicabilityPlan plan)
    {
        lock (_stateGate)
        {
            _closing.Remove(plan);
            _closed.Add(plan);
        }
    }

    internal void AbandonClose(ApplicabilityPlan plan)
    {
        lock (_stateGate)
        {
            _closing.Remove(plan);
        }
    }

    internal void BeginEvaluationPlan(ApplicabilityClosure closure)
    {
        lock (_stateGate)
        {
            if (_plannedEvaluation.Contains(closure) ||
                !_planningEvaluation.Add(closure))
            {
                throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
            }
        }
    }

    internal void CompleteEvaluationPlan(
        ApplicabilityClosure closure,
        EvaluationAdvanceResult result)
    {
        lock (_stateGate)
        {
            _planningEvaluation.Remove(closure);
            _plannedEvaluation.Add(closure);
            if (result is EvaluationPlan plan)
            {
                _issuedEvaluationPlans.Add(plan);
            }
            else if (result is EvaluationClosure evaluationClosure)
            {
                _issuedEvaluationClosures.Add(evaluationClosure);
            }
        }
    }

    internal void AbandonEvaluationPlan(ApplicabilityClosure closure)
    {
        lock (_stateGate)
        {
            _planningEvaluation.Remove(closure);
        }
    }

    internal void BeginEvaluationAdvance(EvaluationPlan plan)
    {
        lock (_stateGate)
        {
            if (!_issuedEvaluationPlans.Contains(plan) ||
                _advancedEvaluation.Contains(plan) ||
                !_advancingEvaluation.Add(plan))
            {
                throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
            }
        }
    }

    internal void CompleteEvaluationAdvance(
        EvaluationPlan plan,
        EvaluationAdvanceResult result)
    {
        lock (_stateGate)
        {
            _advancingEvaluation.Remove(plan);
            _issuedEvaluationPlans.Remove(plan);
            _advancedEvaluation.Add(plan);
            if (result is EvaluationClosure closure)
            {
                _issuedEvaluationClosures.Add(closure);
            }
        }
    }

    internal void AbandonEvaluationAdvance(EvaluationPlan plan)
    {
        lock (_stateGate)
        {
            _advancingEvaluation.Remove(plan);
        }
    }

    internal EvaluationClosure ReplaceIssuedEvaluationClosure(
        EvaluationClosure source,
        ProtectedEvaluationInput protectedInput)
    {
        lock (_stateGate)
        {
            if (source is null ||
                protectedInput is null ||
                source.ProtectedInput is not null ||
                !_issuedEvaluationClosures.Contains(source) ||
                _evaluating.Contains(source) ||
                _evaluated.Contains(source))
            {
                throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
            }

            var replacement = new EvaluationClosure(
                source.CompletedRoundCount,
                source.Applicability,
                source.Context,
                source.Acquisitions,
                source.TerminalEvaluations,
                protectedInput);
            _issuedEvaluationClosures.Remove(source);
            _issuedEvaluationClosures.Add(replacement);
            return replacement;
        }
    }

    internal void BeginEvaluate(EvaluationClosure closure)
    {
        lock (_stateGate)
        {
            if (!_issuedEvaluationClosures.Contains(closure) ||
                _evaluated.Contains(closure) ||
                !_evaluating.Add(closure))
            {
                throw new CatalogIntegrityException(
                    CatalogIntegrityCode.PlanStateInvalid);
            }
        }
    }

    internal void CompleteEvaluate(EvaluationClosure closure)
    {
        lock (_stateGate)
        {
            _evaluating.Remove(closure);
            _issuedEvaluationClosures.Remove(closure);
            _evaluated.Add(closure);
        }
    }

    internal void AbandonEvaluate(EvaluationClosure closure)
    {
        lock (_stateGate)
        {
            _evaluating.Remove(closure);
        }
    }
}

internal static class ApplicabilityPlanningCore
{
    private const string RepositorySnapshot =
        "protocol.target.repository-snapshot";
    private const string RepositoryGoverned =
        "protocol.target.repository-governed-body-set";
    private const string RepositoryTarget =
        "protocol.target.repository-target-resolution-set";
    private const string ProviderGoverned =
        "protocol.target.provider-governed-body-set";

    internal static ApplicabilityPlan PlanSlice(
        KernelPlanningSession session,
        ExecutionProfile profile,
        IEnumerable<AcquisitionTarget> targets)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(profile);
        var rules = session.Rules.Where(rule =>
            rule.SubjectRoles.Contains(profile.SubjectRole) &&
            rule.Operations.Contains(profile.Operation) &&
            rule.SnapshotKinds.Contains(profile.SnapshotKind) &&
            Intersects(rule.Surfaces, profile.Surfaces)).ToArray();
        return Create(session, profile, rules, targets);
    }

    internal static ApplicabilityPlan PlanComplete(
        KernelPlanningSession session,
        NamedExecutionProfile profile,
        IEnumerable<AcquisitionTarget> targets)
    {
        ValidateCompleteProfile(session, profile);
        var plan = Create(
            session,
            profile.Axes,
            CompleteRules(session, profile),
            targets,
            subjectRepository: null);
        session.RegisterNamedProfile(plan, profile);
        return plan;
    }

    internal static ApplicabilityPlan PlanComplete(
        KernelPlanningSession session,
        NamedExecutionProfile profile,
        AcquisitionTarget subjectRepository,
        IEnumerable<AcquisitionTarget> targets)
    {
        ValidateCompleteProfile(session, profile);
        ArgumentNullException.ThrowIfNull(subjectRepository);
        var plan = Create(
            session,
            profile.Axes,
            CompleteRules(session, profile),
            targets,
            subjectRepository);
        session.RegisterNamedProfile(plan, profile);
        return plan;
    }

    private static void ValidateCompleteProfile(
        KernelPlanningSession session,
        NamedExecutionProfile profile)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(profile);
        if (!ReferenceEquals(session, profile.PlanningSession))
        {
            Invalid();
        }
    }

    private static RuleDeclaration[] CompleteRules(
        KernelPlanningSession session,
        NamedExecutionProfile profile)
    {
        var rules = profile.RuleIds.Select(ruleId =>
        {
            var matches = session.Rules
                .Where(rule => rule.RuleId.Equals(ruleId))
                .ToArray();
            return matches.Length == 1 ? matches[0] : Invalid<RuleDeclaration>();
        }).OrderBy(rule => rule.RuleId.Value, StringComparer.Ordinal).ToArray();
        if (rules.Length != profile.RuleIds.Count ||
            rules.Select(rule => rule.RuleId).Distinct().Count() != rules.Length)
        {
            Invalid();
        }

        return rules;
    }

    private static ApplicabilityPlan Create(
        KernelPlanningSession session,
        ExecutionProfile profile,
        IReadOnlyList<RuleDeclaration> rules,
        IEnumerable<AcquisitionTarget> targets,
        AcquisitionTarget? subjectRepository = null)
    {
        ArgumentNullException.ThrowIfNull(targets);
        if (rules.Count == 0)
        {
            Invalid();
        }

        var materializedTargets = targets.ToArray();
        if (materializedTargets.Any(target => target is null) ||
            materializedTargets.Distinct().Count() != materializedTargets.Length)
        {
            Invalid();
        }

        var repositoryTargets = materializedTargets.Where(static target =>
            target.Surface.Equals(SurfaceKind.Repository)).ToArray();
        if (repositoryTargets.Length > 1)
        {
            Invalid();
        }

        var retainedSubjectRepository = subjectRepository ??
            repositoryTargets.FirstOrDefault();
        if (retainedSubjectRepository is not null &&
            (!retainedSubjectRepository.Surface.Equals(SurfaceKind.Repository) ||
             !retainedSubjectRepository.SnapshotKind.Equals(profile.SnapshotKind) ||
             materializedTargets.Any(target =>
                 !string.Equals(
                     target.SubjectIdentity,
                     retainedSubjectRepository.SubjectIdentity,
                     StringComparison.Ordinal) ||
                 !target.SnapshotKind.Equals(retainedSubjectRepository.SnapshotKind) ||
                 !string.Equals(
                     target.TargetIdentity,
                     retainedSubjectRepository.TargetIdentity,
                     StringComparison.Ordinal)) ||
             materializedTargets.Any(target =>
                 target.Surface.Equals(SurfaceKind.Repository) &&
                 !target.Equals(retainedSubjectRepository))))
        {
            Invalid();
        }

        var activeSlots = rules
            .SelectMany(rule => rule.ApplicabilitySlots.Concat(rule.EvaluationSlots))
            .Where(slot => Intersects(slot.ProfileSurfaces, profile.Surfaces))
            .ToArray();
        var requiredSurfaces = activeSlots
            .Select(slot => SurfaceFor(slot.TargetSelectorKey))
            .Distinct()
            .ToArray();
        if (materializedTargets.Length != requiredSurfaces.Length ||
            requiredSurfaces.Any(surface =>
                materializedTargets.Count(target => target.Surface.Equals(surface)) != 1))
        {
            Invalid();
        }

        if (materializedTargets.Length != 0)
        {
            var first = materializedTargets[0];
            if (materializedTargets.Any(target =>
                    !string.Equals(
                        target.SubjectIdentity,
                        first.SubjectIdentity,
                        StringComparison.Ordinal) ||
                    !target.SnapshotKind.Equals(first.SnapshotKind) ||
                    !string.Equals(
                        target.TargetIdentity,
                        first.TargetIdentity,
                        StringComparison.Ordinal)) ||
                !first.SnapshotKind.Equals(profile.SnapshotKind))
            {
                Invalid();
            }
        }

        var orderedTargets = materializedTargets
            .OrderBy(target => SurfaceRank(target.Surface))
            .ThenBy(target => target.SourceIdentity, StringComparer.Ordinal)
            .ToArray();
        var applicabilitySlots = CanonicalApplicabilitySlots(rules, profile);
        var instructions = applicabilitySlots.Select(slot =>
        {
            var surface = SurfaceFor(slot.TargetSelectorKey);
            var target = orderedTargets.Single(item => item.Surface.Equals(surface));
            return AcquisitionInstruction.CreateApplicability(
                session.ManifestDigest,
                slot,
                target);
        }).ToArray();

        return new ApplicabilityPlan(
            session.AuthorityKind,
            profile,
            orderedTargets,
            rules.Select(rule => rule.RuleId),
            applicabilitySlots,
            instructions,
            session,
            retainedSubjectRepository);
    }

    private static IReadOnlyList<EvidenceSlotDeclaration>
        CanonicalApplicabilitySlots(
            IReadOnlyList<RuleDeclaration> rules,
            ExecutionProfile profile)
    {
        var slots = new Dictionary<string, EvidenceSlotDeclaration>(
            StringComparer.Ordinal);
        foreach (var slot in rules
                     .SelectMany(rule => rule.ApplicabilitySlots)
                     .Where(slot => Intersects(slot.ProfileSurfaces, profile.Surfaces)))
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

    private static bool Intersects(SurfaceSet left, SurfaceSet right) =>
        left.Values.Any(right.Values.Contains);

    private static SurfaceKind SurfaceFor(string selectorKey) => selectorKey switch
    {
        RepositorySnapshot or RepositoryGoverned or RepositoryTarget =>
            SurfaceKind.Repository,
        ProviderGoverned => SurfaceKind.Provider,
        _ => Invalid<SurfaceKind>(),
    };

    private static int SurfaceRank(SurfaceKind surface) => surface.Value switch
    {
        "repository" => 0,
        "provider" => 1,
        "workflow" => 2,
        "release" => 3,
        _ => Invalid<int>(),
    };

    private static void Invalid() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    private static T Invalid<T>()
    {
        Invalid();
        return default!;
    }
}
