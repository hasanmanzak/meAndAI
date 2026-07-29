using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed record GovernanceCounts
{
    public GovernanceCounts(
        int evaluatedRules,
        int missingRules,
        int unmappedRules,
        int blockingFindings,
        int advisoryFindings)
    {
        if (evaluatedRules < 0 ||
            missingRules < 0 ||
            unmappedRules < 0 ||
            blockingFindings < 0 ||
            advisoryFindings < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(evaluatedRules),
                "Governance counts cannot be negative.");
        }

        EvaluatedRules = evaluatedRules;
        MissingRules = missingRules;
        UnmappedRules = unmappedRules;
        BlockingFindings = blockingFindings;
        AdvisoryFindings = advisoryFindings;
    }

    public int EvaluatedRules { get; }

    public int MissingRules { get; }

    public int UnmappedRules { get; }

    public int BlockingFindings { get; }

    public int AdvisoryFindings { get; }
}

public sealed class GovernanceReport
{
    internal GovernanceReport(
        GovernanceProfileId profile,
        string snapshotMode,
        string snapshotEvidenceDigest,
        ExactGitCommitId? snapshotSubjectCommit,
        ProtocolVersion? policyVersion,
        ExactGitCommitId? policySourceCommit,
        GovernanceProfileEvidenceState? profileEvidenceState,
        string policyCatalogVersion,
        string policyCatalogMetadataDigest,
        string[] evaluatedRuleIds,
        GovernanceVerdict verdict,
        GovernanceEngineState engineState,
        GovernanceAuthorityState authorityState,
        GovernanceCounts counts,
        GovernanceFinding[] findings)
    {
        Profile = profile;
        SnapshotMode = snapshotMode;
        SnapshotEvidenceDigest = snapshotEvidenceDigest;
        SnapshotSubjectCommit = snapshotSubjectCommit;
        PolicyVersion = policyVersion;
        PolicySourceCommit = policySourceCommit;
        ProfileEvidenceState = profileEvidenceState;
        PolicyCatalogVersion = policyCatalogVersion;
        PolicyCatalogMetadataDigest = policyCatalogMetadataDigest;
        EvaluatedRuleIds = new ReadOnlyCollection<string>(evaluatedRuleIds);
        Verdict = verdict;
        EngineState = engineState;
        AuthorityState = authorityState;
        Counts = counts;
        Findings = new ReadOnlyCollection<GovernanceFinding>(findings);
    }

    public int Schema => 1;

    public OperationalApplicationId Application =>
        OperationalApplicationId.Governance;

    public OperationStageId Stage => OperationStageId.Validate;

    public GovernanceProfileId Profile { get; }

    public string SnapshotMode { get; }

    public string SnapshotEvidenceDigest { get; }

    public ExactGitCommitId? SnapshotSubjectCommit { get; }

    public ProtocolVersion? PolicyVersion { get; }

    public ExactGitCommitId? PolicySourceCommit { get; }

    public GovernanceProfileEvidenceState? ProfileEvidenceState { get; }

    public string PolicyCatalogVersion { get; }

    public string PolicyCatalogMetadataDigest { get; }

    public IReadOnlyList<string> EvaluatedRuleIds { get; }

    public string Coverage => "bounded-catalog";

    public GovernanceVerdict Verdict { get; }

    public GovernanceEngineState EngineState { get; }

    public GovernanceAuthorityState AuthorityState { get; }

    public GovernanceCounts Counts { get; }

    public IReadOnlyList<GovernanceFinding> Findings { get; }
}
