using MeAndAI.Operations.Governance.Core.Analysis;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class MarkdownDocumentIndexTests
{
    [Fact]
    public void FencedHeadingsAreNotSectionsAndAtxStructureIsDeterministic()
    {
        const string path = "docs/decisions/DEC-0042-parser-contract.md";
        const string markdown = """
            # DEC-0042 - Parser Contract
            - Classification: Decision
            - Status: Accepted
            ```markdown
            ## Context
            ```
            ~~~markdown
            ## Decision
            ~~~
            ## Context
            Context body.
            ## Decision ##
            Decision body.
            ## Consequences
            Consequences body.
            """;
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, markdown));

        var document = GovernanceAnalysisContext.Create(snapshot)
            .MarkdownDocuments
            .GetRequired(path);

        Assert.Equal("DEC-0042 - Parser Contract", document.H1);
        Assert.Equal(
            [
                "- Classification: Decision",
                "- Status: Accepted",
                "```markdown",
                "## Context",
                "```",
                "~~~markdown",
                "## Decision",
                "~~~",
            ],
            document.PreambleLines);
        Assert.Equal(
            [
                new MarkdownMetadataField("Classification", "Decision"),
                new MarkdownMetadataField("Status", "Accepted"),
            ],
            document.PreambleMetadata);
        Assert.Equal(
            ["Context", "Decision", "Consequences"],
            document.H2Sections.Select(section => section.Heading));
        Assert.Equal(
            ["Context body."],
            document.H2Sections[0].BodyLines);
        Assert.Equal(
            ["Decision body."],
            document.H2Sections[1].BodyLines);
        Assert.Equal(
            ["Consequences body."],
            document.H2Sections[2].BodyLines);
    }

    [Fact]
    public void FencedPreambleMetadataIsNotIndexed()
    {
        const string path = "docs/decisions/DEC-0042-parser-contract.md";
        const string markdown = """
            # DEC-0042 - Parser Contract
            ```yaml
            - Classification: Decision
            - Status: Accepted
            ```
            - Status: Proposed
            ## Context
            """;
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, markdown));

        var document = GovernanceAnalysisContext.Create(snapshot)
            .MarkdownDocuments
            .GetRequired(path);

        Assert.Equal(
            [new MarkdownMetadataField("Status", "Proposed")],
            document.PreambleMetadata);
    }

    [Fact]
    public void HtmlCommentStructureIsNotIndexed()
    {
        const string path = "docs/decisions/DEC-0042-parser-contract.md";
        const string markdown = """
            <!--
            # DEC-0042 - Commented Out
            - Classification: Decision
            - Status: Accepted
            ## Context
            ## Decision
            ## Consequences
            -->
            """;
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, markdown));

        var document = GovernanceAnalysisContext.Create(snapshot)
            .MarkdownDocuments
            .GetRequired(path);

        Assert.Null(document.H1);
        Assert.Empty(document.PreambleMetadata);
        Assert.Empty(document.H2Sections);
    }

    [Fact]
    public void FenceInfoCommentMarkerDoesNotLeakIntoFollowingStructure()
    {
        const string path = "docs/decisions/DEC-0042-parser-contract.md";
        const string markdown = """
            ```html <!--
            ignored fenced content
            ```
            # DEC-0042 - Parser Contract
            - Classification: Decision
            - Status: Accepted
            ## Context
            ## Decision
            ## Consequences
            """;
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, markdown));

        var document = GovernanceAnalysisContext.Create(snapshot)
            .MarkdownDocuments
            .GetRequired(path);

        Assert.Equal("DEC-0042 - Parser Contract", document.H1);
        Assert.Equal(2, document.PreambleMetadata.Count);
        Assert.Equal(
            ["Context", "Decision", "Consequences"],
            document.H2Sections.Select(section => section.Heading));
    }

    [Fact]
    public void RepeatedIndexConstructionProducesTheSameDocumentModel()
    {
        const string path = "docs/decisions/DEC-0042-parser-contract.md";
        const string markdown = """
            # DEC-0042 - Parser Contract
            - Classification: Decision
            - Status: Accepted
            ## Context
            Context.
            ## Decision
            Decision.
            ## Consequences
            Consequences.
            """;
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, markdown));

        var first = GovernanceAnalysisContext.Create(snapshot)
            .MarkdownDocuments
            .GetRequired(path);
        var second = GovernanceAnalysisContext.Create(snapshot)
            .MarkdownDocuments
            .GetRequired(path);

        Assert.Equal(first.H1, second.H1);
        Assert.Equal(first.PreambleLines, second.PreambleLines);
        Assert.Equal(
            first.H2Sections.Select(section => section.Heading),
            second.H2Sections.Select(section => section.Heading));
        Assert.Equal(first.H2Sections.Count, second.H2Sections.Count);
        for (var index = 0; index < first.H2Sections.Count; index++)
        {
            Assert.Equal(
                first.H2Sections[index].BodyLines,
                second.H2Sections[index].BodyLines);
        }
    }
}
