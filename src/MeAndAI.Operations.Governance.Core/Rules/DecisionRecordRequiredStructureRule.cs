using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed class DecisionRecordRequiredStructureRule :
    GovernanceRule
{
    internal static GovernanceCatalogRuleIdentity CanonicalIdentity { get; } =
        new(
            "protocol.decision-record.required-structure.v1",
            "TEST-0005",
            "governance.decision.record-structure-incomplete",
            GovernanceSeverity.High,
            GovernanceEnforcement.Blocking);

    private static readonly string[] RequiredSections =
        ["Context", "Decision", "Consequences"];

    public override GovernanceCatalogRuleIdentity Identity =>
        CanonicalIdentity;

    public override IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceAnalysisContext context)
    {
        return
        [
            .. context.ProtocolRecords.DecisionRecords
                .OrderBy(record => record.RelativePath, StringComparer.Ordinal)
                .Select(record => CreateFindingIfIncomplete(
                    record,
                    context.MarkdownDocuments.GetRequired(
                        record.RelativePath)))
                .Where(finding => finding is not null)
                .Select(finding => finding!),
        ];
    }

    private GovernanceFinding? CreateFindingIfIncomplete(
        DecisionRecord record,
        MarkdownDocument document)
    {
        var requirements = new List<GovernanceRequirement>();

        if (!HasExactDocumentIdentity(document.H1, record.Id))
        {
            requirements.Add(new GovernanceRequirement(
                GovernanceRequirementKind.DocumentIdentity,
                record.Id));
        }

        if (!document.PreambleMetadata.Any(field =>
                string.Equals(
                    field.Name,
                    "Classification",
                    StringComparison.Ordinal) &&
                string.Equals(
                    field.Value,
                    "Decision",
                    StringComparison.Ordinal)))
        {
            requirements.Add(new GovernanceRequirement(
                GovernanceRequirementKind.MetadataField,
                "Classification"));
        }

        if (!document.PreambleMetadata.Any(field =>
                string.Equals(
                    field.Name,
                    "Status",
                    StringComparison.Ordinal) &&
                !string.IsNullOrWhiteSpace(field.Value)))
        {
            requirements.Add(new GovernanceRequirement(
                GovernanceRequirementKind.MetadataField,
                "Status"));
        }

        var sectionHeadings = document.H2Sections
            .Select(section => section.Heading)
            .ToHashSet(StringComparer.Ordinal);
        requirements.AddRange(
            RequiredSections
                .Where(section => !sectionHeadings.Contains(section))
                .Select(section => new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    section)));

        return requirements.Count == 0
            ? null
            : new GovernanceFinding(
                RuleId,
                CanonicalScenarioId,
                FindingCode,
                Severity,
                Enforcement,
                record.Path,
                requirements);
    }

    private static bool HasExactDocumentIdentity(
        string? heading,
        string decisionId) =>
        string.Equals(heading, decisionId, StringComparison.Ordinal) ||
        heading?.StartsWith(
            decisionId + " ",
            StringComparison.Ordinal) == true;

}
