using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Governance;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed record GovernanceCounts(
    int EvaluatedRules,
    int BlockingFindings,
    int AdvisoryFindings);

public sealed class GovernanceReport
{
    internal GovernanceReport(
        GovernanceProfileId profile,
        string snapshotMode,
        string snapshotEvidenceDigest,
        string policyCatalogVersion,
        string policyCatalogMetadataDigest,
        GovernanceVerdict verdict,
        GovernanceCounts counts,
        GovernanceFinding[] findings)
    {
        Profile = profile;
        SnapshotMode = snapshotMode;
        SnapshotEvidenceDigest = snapshotEvidenceDigest;
        PolicyCatalogVersion = policyCatalogVersion;
        PolicyCatalogMetadataDigest = policyCatalogMetadataDigest;
        Verdict = verdict;
        Counts = counts;
        Findings = new ReadOnlyCollection<GovernanceFinding>(findings);
    }

    public int Schema => 1;

    public string Application => "governance";

    public string Stage => "validate";

    public GovernanceProfileId Profile { get; }

    public string SnapshotMode { get; }

    public string SnapshotEvidenceDigest { get; }

    public string PolicyCatalogVersion { get; }

    public string PolicyCatalogMetadataDigest { get; }

    public string Coverage => "bounded-first-slice";

    public GovernanceVerdict Verdict { get; }

    public string EngineState => "csharp-shadow";

    public string AuthorityState => "powershell-authority";

    public GovernanceCounts Counts { get; }

    public IReadOnlyList<GovernanceFinding> Findings { get; }
}
