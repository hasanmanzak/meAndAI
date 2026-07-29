using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal sealed class GovernanceReportFactory
{
    private readonly GovernanceRuleCatalog catalog;

    internal GovernanceReportFactory(GovernanceRuleCatalog catalog)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        this.catalog = catalog;
    }

    internal GovernanceReport Create(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot,
        IEnumerable<GovernanceRuleEvaluation> evaluations)
    {
        ArgumentNullException.ThrowIfNull(snapshot);
        if (!snapshot.IsCandidate)
        {
            throw new ArgumentException(
                "Candidate governance reports require a candidate snapshot.",
                nameof(snapshot));
        }

        return CreateCore(
            profile,
            snapshot,
            exactPolicy: null,
            profileEvidenceState: null,
            evaluations);
    }

    internal GovernanceReport CreateExact(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot,
        ProtocolPolicyIdentity policy,
        GovernanceProfileEvidenceState profileEvidenceState,
        IEnumerable<GovernanceRuleEvaluation> evaluations)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(snapshot);
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(profileEvidenceState);
        ArgumentNullException.ThrowIfNull(evaluations);

        if (!snapshot.IsExactCommit)
        {
            throw new ArgumentException(
                "Exact governance reports require an exact-commit snapshot.",
                nameof(snapshot));
        }

        if (profileEvidenceState != GovernanceProfileEvidenceState.Complete &&
            profileEvidenceState != GovernanceProfileEvidenceState.Incomplete)
        {
            throw new ArgumentOutOfRangeException(
                nameof(profileEvidenceState),
                profileEvidenceState,
                "Unknown governance profile-evidence state.");
        }

        return CreateCore(
            profile,
            snapshot,
            policy,
            profileEvidenceState,
            evaluations);
    }

    private GovernanceReport CreateCore(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot,
        ProtocolPolicyIdentity? exactPolicy,
        GovernanceProfileEvidenceState? profileEvidenceState,
        IEnumerable<GovernanceRuleEvaluation> evaluations)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(snapshot);
        ArgumentNullException.ThrowIfNull(evaluations);

        var expectedRules = catalog.GetApplicableRules(profile)
            .Select(rule => rule.Identity)
            .ToArray();
        var expectedByRuleId = expectedRules.ToDictionary(
            identity => identity.RuleId,
            StringComparer.Ordinal);
        var candidatesByRuleId = new Dictionary<
            string,
            List<GovernanceRuleEvaluation>>(StringComparer.Ordinal);
        var unmappedRules = 0;

        foreach (var evaluation in evaluations)
        {
            if (evaluation is null ||
                string.IsNullOrEmpty(evaluation.RuleIdentity.RuleId) ||
                !expectedByRuleId.TryGetValue(
                    evaluation.RuleIdentity.RuleId,
                    out var expectedIdentity) ||
                !ReferenceEquals(
                    evaluation.RuleIdentity,
                    expectedIdentity) ||
                evaluation.Findings.Any(finding =>
                    !ReferenceEquals(
                        finding.RuleIdentity,
                        expectedIdentity)))
            {
                unmappedRules++;
                continue;
            }

            if (!candidatesByRuleId.TryGetValue(
                    expectedIdentity.RuleId,
                    out var candidates))
            {
                candidates = [];
                candidatesByRuleId.Add(expectedIdentity.RuleId, candidates);
            }

            candidates.Add(evaluation);
        }

        var mappedByRuleId = new Dictionary<
            string,
            GovernanceRuleEvaluation>(StringComparer.Ordinal);
        foreach (var pair in candidatesByRuleId)
        {
            if (pair.Value.Count == 1)
            {
                mappedByRuleId.Add(pair.Key, pair.Value[0]);
                continue;
            }

            unmappedRules += pair.Value.Count;
        }

        var evaluatedRuleIds = expectedRules
            .Where(identity => mappedByRuleId.ContainsKey(identity.RuleId))
            .Select(identity => identity.RuleId)
            .OrderBy(ruleId => ruleId, StringComparer.Ordinal)
            .ToArray();
        var findings = evaluatedRuleIds
            .SelectMany(ruleId => mappedByRuleId[ruleId].Findings)
            .OrderBy(finding => finding, FindingComparer.Instance)
            .ToArray();
        var blockingFindings = findings.Count(finding =>
            finding.Enforcement == GovernanceEnforcement.Blocking);
        var counts = new GovernanceCounts(
            evaluatedRuleIds.Length,
            expectedRules.Length - evaluatedRuleIds.Length,
            unmappedRules,
            blockingFindings,
            findings.Length - blockingFindings);
        return new GovernanceReport(
            profile,
            snapshot.Mode,
            snapshot.EvidenceDigest,
            snapshot.SubjectCommit,
            exactPolicy?.Version,
            exactPolicy?.SourceCommit,
            profileEvidenceState,
            catalog.Version.Value,
            catalog.Identity.MetadataDigest.Value,
            evaluatedRuleIds,
            DetermineVerdict(counts, profileEvidenceState),
            GovernanceEngineState.CSharpShadow,
            GovernanceAuthorityState.PowerShellAuthority,
            counts,
            findings);
    }

    internal static GovernanceVerdict DetermineVerdict(
        GovernanceCounts counts)
        => DetermineVerdict(counts, profileEvidenceState: null);

    private static GovernanceVerdict DetermineVerdict(
        GovernanceCounts counts,
        GovernanceProfileEvidenceState? profileEvidenceState)
    {
        ArgumentNullException.ThrowIfNull(counts);

        if (profileEvidenceState == GovernanceProfileEvidenceState.Incomplete)
        {
            return GovernanceVerdict.Incomplete;
        }

        if (counts.MissingRules > 0 || counts.UnmappedRules > 0)
        {
            return GovernanceVerdict.Incomplete;
        }

        return counts.BlockingFindings > 0
            ? GovernanceVerdict.Nonconforming
            : GovernanceVerdict.Conforming;
    }

    private sealed class FindingComparer : IComparer<GovernanceFinding>
    {
        internal static FindingComparer Instance { get; } = new();

        public int Compare(GovernanceFinding? left, GovernanceFinding? right)
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

            var comparison = StringComparer.Ordinal.Compare(
                left.RelativePath,
                right.RelativePath);
            comparison = comparison != 0
                ? comparison
                : Nullable.Compare(left.Location.Line, right.Location.Line);
            comparison = comparison != 0
                ? comparison
                : StringComparer.Ordinal.Compare(
                    left.Location.Anchor,
                    right.Location.Anchor);
            comparison = comparison != 0
                ? comparison
                : StringComparer.Ordinal.Compare(left.Code, right.Code);
            comparison = comparison != 0
                ? comparison
                : StringComparer.Ordinal.Compare(left.RuleId, right.RuleId);
            comparison = comparison != 0
                ? comparison
                : StringComparer.Ordinal.Compare(
                    left.Evidence.Scope.Value,
                    right.Evidence.Scope.Value);
            comparison = comparison != 0
                ? comparison
                : StringComparer.Ordinal.Compare(
                    left.Evidence.Digest.Value,
                    right.Evidence.Digest.Value);
            return comparison != 0
                ? comparison
                : CompareRequirements(
                    left.UnsatisfiedRequirements,
                    right.UnsatisfiedRequirements);
        }

        private static int CompareRequirements(
            IReadOnlyList<GovernanceRequirement> left,
            IReadOnlyList<GovernanceRequirement> right)
        {
            for (var index = 0;
                 index < Math.Min(left.Count, right.Count);
                 index++)
            {
                var comparison = StringComparer.Ordinal.Compare(
                    left[index].Kind.Value,
                    right[index].Kind.Value);
                comparison = comparison != 0
                    ? comparison
                    : StringComparer.Ordinal.Compare(
                        left[index].Name,
                        right[index].Name);
                if (comparison != 0)
                {
                    return comparison;
                }
            }

            return left.Count.CompareTo(right.Count);
        }
    }
}
