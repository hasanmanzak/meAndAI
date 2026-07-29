using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed class FeatureRecordRequiredPairRule :
    GovernanceRule
{
    internal static GovernanceCatalogRuleIdentity CanonicalIdentity { get; } =
        new(
            "protocol.feature-record.required-pair.v1",
            "TEST-0004",
            "governance.feature.record-set-incomplete",
            GovernanceSeverity.High,
            GovernanceEnforcement.Blocking);

    private static readonly string[] RequiredFiles =
        ["README.md", "test-cases.md"];

    public override GovernanceCatalogRuleIdentity Identity =>
        CanonicalIdentity;

    public override IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceAnalysisContext context)
    {
        return
        [
            .. context.ProtocolRecords.FeatureRecords
                .Select(record => CreateFindingIfIncomplete(
                    record,
                    context))
                .Where(finding => finding is not null)
                .Select(finding => finding!),
        ];
    }

    private GovernanceFinding? CreateFindingIfIncomplete(
        FeatureRecord featureRecord,
        GovernanceAnalysisContext context)
    {
        var requirements = RequiredFiles
            .Where(requiredFile => !IsRepositoryFile(
                context,
                $"{featureRecord.RelativePath}/{requiredFile}"))
            .Select(requiredFile => new GovernanceRequirement(
                GovernanceRequirementKind.RepositoryFile,
                requiredFile))
            .ToArray();

        return requirements.Length == 0
            ? null
            : new GovernanceFinding(
                RuleId,
                CanonicalScenarioId,
                FindingCode,
                Severity,
                Enforcement,
                featureRecord.Path,
                requirements);
    }

    private static bool IsRepositoryFile(
        GovernanceAnalysisContext context,
        string relativePath) =>
        context.TryGetEntry(relativePath, out var entry) &&
        entry!.Kind == GovernanceRepositoryEntryKind.File;
}
