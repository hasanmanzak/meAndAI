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
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(profile);
        if (!ReferenceEquals(session, profile.PlanningSession))
        {
            Invalid();
        }

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

        return Create(session, profile.Axes, rules, targets);
    }

    private static ApplicabilityPlan Create(
        KernelPlanningSession session,
        ExecutionProfile profile,
        IReadOnlyList<RuleDeclaration> rules,
        IEnumerable<AcquisitionTarget> targets)
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
            session);
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
