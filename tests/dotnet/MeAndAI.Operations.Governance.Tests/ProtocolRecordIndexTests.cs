using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ProtocolRecordIndexTests
{
    [Fact]
    public void ExactFeatureAndDecisionPathsAreIndexedWithOrdinalCase()
    {
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0002-zeta"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-alpha"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-0002-zeta.md",
                "# DEC-0002 - Zeta\n"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-0001-alpha.md",
                "# DEC-0001 - Alpha\n"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/feat-0003-wrong-case"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-003-too-short"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0004"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0005-nested/child"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/dec-0003-wrong-case.md",
                "# DEC-0003 - Wrong case\n"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-003-too-short.md",
                "# DEC-0003 - Too short\n"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-0004.md",
                "# DEC-0004\n"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/DEC-0005-wrong-extension.MD",
                "# DEC-0005 - Wrong extension\n"),
            GovernanceTestRepository.MarkdownFile(
                "docs/decisions/archive/DEC-0006-nested.md",
                "# DEC-0006 - Nested\n"));

        var index = ProtocolRecordIndex.Create(snapshot);

        Assert.Equal(
            [
                "docs/features/FEAT-0001-alpha",
                "docs/features/FEAT-0002-zeta",
            ],
            index.FeatureRecords.Select(record => record.RelativePath));
        Assert.Equal(
            [
                "docs/decisions/DEC-0001-alpha.md",
                "docs/decisions/DEC-0002-zeta.md",
            ],
            index.DecisionRecords.Select(record => record.RelativePath));
    }
}
