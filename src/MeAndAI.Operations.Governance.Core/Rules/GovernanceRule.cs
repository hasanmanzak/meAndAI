using System.Security.Cryptography;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Rules;

public abstract class GovernanceRule : IGovernanceRule
{
    public abstract GovernanceCatalogRuleIdentity Identity { get; }

    public string RuleId => Identity.RuleId;

    public string CanonicalScenarioId => Identity.CanonicalScenarioId;

    public string FindingCode => Identity.FindingCode;

    public GovernanceSeverity Severity => Identity.Severity;

    public GovernanceEnforcement Enforcement => Identity.Enforcement;

    public abstract IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceAnalysisContext context);

    protected GovernanceFinding CreateFinding(
        GovernanceAnalysisContext context,
        RepositoryRelativePath path,
        IEnumerable<GovernanceRequirement> unsatisfiedRequirements,
        int? line = null,
        string? anchor = null)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(path);
        ArgumentNullException.ThrowIfNull(unsatisfiedRequirements);

        var evidence =
            context.TryGetEntry(path.Value, out var entry) &&
            entry!.Kind == GovernanceRepositoryEntryKind.File
                ? GovernanceFindingEvidence.FromContentObject(
                    ExactSha256Digest.FromHashBytes(
                        SHA256.HashData(entry.CapturedContent)))
                : GovernanceFindingEvidence.FromSnapshot(
                    context.Snapshot.EvidenceDigest);

        return new GovernanceFinding(
            Identity,
            new GovernanceFindingLocation(path, line, anchor),
            evidence,
            unsatisfiedRequirements);
    }
}
