using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class DecisionRecordRequiredStructureRuleTests
{
    private const string DecisionPath =
        "docs/decisions/DEC-0042-example.md";

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void MinimalCanonicalDecisionRecordProducesNoFinding()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile(
                DecisionPath,
                """
                # DEC-0042 - Example
                - Classification: Decision
                - Status: Accepted
                ## Context
                ## Decision
                ## Consequences
                """));

        var findings = new DecisionRecordRequiredStructureRule().Evaluate(
            GovernanceProfileId.ProtocolAuthority,
            context);

        Assert.Empty(findings);
    }

    [Theory]
    [Trait("Scenario", "TEST-0005")]
    [InlineData("# DEC-0043 - Wrong ID")]
    [InlineData("# dec-0042 - Wrong case")]
    [InlineData("# Example without decision ID")]
    public void H1MustContainTheExactFilenameDecisionId(string h1)
    {
        var context = GovernanceTestRepository.Analyze(
            DecisionEntry(
                h1: h1,
                classification: "- Classification: Decision",
                status: "- Status: Accepted",
                sections: ["Context", "Decision", "Consequences"]));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.DocumentIdentity,
                    "DEC-0042"),
            ],
            finding.UnsatisfiedRequirements);
    }

    [Theory]
    [Trait("Scenario", "TEST-0005")]
    [InlineData("", "- Status: Accepted", "Classification")]
    [InlineData(
        "- Classification: Architecture",
        "- Status: Accepted",
        "Classification")]
    [InlineData(
        "- Classification: decision",
        "- Status: Accepted",
        "Classification")]
    [InlineData("- Classification: Decision", "", "Status")]
    [InlineData("- Classification: Decision", "- Status:", "Status")]
    [InlineData("- Classification: Decision", "- Status:   ", "Status")]
    public void RequiredMetadataMustHaveTheCanonicalValueContract(
        string classification,
        string status,
        string expectedField)
    {
        var context = GovernanceTestRepository.Analyze(
            DecisionEntry(
                h1: "# DEC-0042 - Example",
                classification: classification,
                status: status,
                sections: ["Context", "Decision", "Consequences"]));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.MetadataField,
                    expectedField),
            ],
            finding.UnsatisfiedRequirements);
    }

    [Theory]
    [Trait("Scenario", "TEST-0005")]
    [InlineData("Context")]
    [InlineData("Decision")]
    [InlineData("Consequences")]
    public void EachExactAtxH2SectionIsRequired(string missingSection)
    {
        var sections = new[] { "Context", "Decision", "Consequences" }
            .Where(section => !string.Equals(
                section,
                missingSection,
                StringComparison.Ordinal))
            .ToArray();
        var context = GovernanceTestRepository.Analyze(
            DecisionEntry(
                h1: "# DEC-0042 - Example",
                classification: "- Classification: Decision",
                status: "- Status: Accepted",
                sections: sections));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    missingSection),
            ],
            finding.UnsatisfiedRequirements);
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void FencedHeadingsDoNotSatisfyRequiredSections()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile(
                DecisionPath,
                """
                # DEC-0042 - Example
                - Classification: Decision
                - Status: Accepted
                ```markdown
                ## Context
                ## Decision
                ## Consequences
                ```
                """));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Consequences"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Context"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Decision"),
            ],
            finding.UnsatisfiedRequirements);
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void FencedMetadataDoesNotSatisfyRequiredFields()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile(
                DecisionPath,
                """
                # DEC-0042 - Example
                ```yaml
                - Classification: Decision
                - Status: Accepted
                ```
                ## Context
                ## Decision
                ## Consequences
                """));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.MetadataField,
                    "Classification"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.MetadataField,
                    "Status"),
            ],
            finding.UnsatisfiedRequirements);
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void CommentedStructureDoesNotSatisfyTheDecisionContract()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile(
                DecisionPath,
                """
                <!--
                # DEC-0042 - Commented Out
                - Classification: Decision
                - Status: Accepted
                ## Context
                ## Decision
                ## Consequences
                -->
                """));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(6, finding.UnsatisfiedRequirements.Count);
        Assert.Contains(
            new GovernanceRequirement(
                GovernanceRequirementKind.DocumentIdentity,
                "DEC-0042"),
            finding.UnsatisfiedRequirements);
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void MultipleFindingsAndRequirementsHaveOrdinalOrder()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-0002-zeta.md",
                """
                # DEC-9999 - Wrong ID
                - Classification: Decision
                - Status: Accepted
                ## Context
                """),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-0001-alpha.md",
                """
                # Wrong H1
                - Classification: Note
                - Status:
                """));

        var findings = new DecisionRecordRequiredStructureRule().Evaluate(
            GovernanceProfileId.ProtocolAuthority,
            context);

        Assert.Equal(
            [
                "docs/decisions/DEC-0001-alpha.md",
                "docs/decisions/DEC-0002-zeta.md",
            ],
            findings.Select(finding => finding.RelativePath));
        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.DocumentIdentity,
                    "DEC-0001"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.MetadataField,
                    "Classification"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.MetadataField,
                    "Status"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Consequences"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Context"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Decision"),
            ],
            findings[0].UnsatisfiedRequirements);
        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.DocumentIdentity,
                    "DEC-0002"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Consequences"),
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Decision"),
            ],
            findings[1].UnsatisfiedRequirements);
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void FindingUsesTheCanonicalRuleEnvelope()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile(
                DecisionPath,
                "# DEC-0042 - Example\n"));

        var finding = Assert.Single(
            new DecisionRecordRequiredStructureRule().Evaluate(
                GovernanceProfileId.ProtocolAuthority,
                context));

        Assert.Equal(
            "protocol.decision-record.required-structure.v1",
            finding.RuleId);
        Assert.Equal("TEST-0005", finding.CanonicalScenarioId);
        Assert.Equal(
            "governance.decision.record-structure-incomplete",
            finding.Code);
        Assert.Same(GovernanceSeverity.High, finding.Severity);
        Assert.Same(GovernanceEnforcement.Blocking, finding.Enforcement);
        Assert.Equal(DecisionPath, finding.RelativePath);
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public void UnrelatedMarkdownDocumentsAreIgnored()
    {
        var context = GovernanceTestRepository.Analyze(
            GovernanceTestRepository.MarkdownFile("README.md", "not a decision"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/README.md",
                "not a numbered decision"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/dec-0042-wrong-case.md",
                "not an exact decision path"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/archive/DEC-0042-nested.md",
                "not a direct decision path"));

        var findings = new DecisionRecordRequiredStructureRule().Evaluate(
            GovernanceProfileId.ProtocolAuthority,
            context);

        Assert.Empty(findings);
    }

    private static GovernanceRepositoryEntry DecisionEntry(
        string h1,
        string classification,
        string status,
        IReadOnlyList<string> sections)
    {
        var lines = new List<string> { h1 };
        if (classification.Length > 0)
        {
            lines.Add(classification);
        }

        if (status.Length > 0)
        {
            lines.Add(status);
        }

        lines.AddRange(sections.Select(section => $"## {section}"));
        return GovernanceTestRepository.MarkdownFile(
            DecisionPath,
            string.Join('\n', lines) + "\n");
    }
}
