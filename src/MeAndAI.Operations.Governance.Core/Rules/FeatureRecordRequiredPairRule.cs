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
            "docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004",
            "governance.feature.record-set-incomplete",
            GovernanceSeverity.High,
            GovernanceEnforcement.Blocking);

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
        var requirements = ProtocolRecordPath.RequiredFeatureFileNames
            .Where(requiredFile => !IsRepositoryFile(
                context,
                $"{featureRecord.RelativePath}/{requiredFile}"))
            .Select(requiredFile => new GovernanceRequirement(
                GovernanceRequirementKind.RepositoryFile,
                requiredFile))
            .ToArray();

        return requirements.Length == 0
            ? null
            : CreateFinding(
                context,
                featureRecord.Path,
                requirements);
    }

    private static bool IsRepositoryFile(
        GovernanceAnalysisContext context,
        string relativePath) =>
        context.TryGetEntry(relativePath, out var entry) &&
        entry!.Kind == GovernanceRepositoryEntryKind.File;
}
