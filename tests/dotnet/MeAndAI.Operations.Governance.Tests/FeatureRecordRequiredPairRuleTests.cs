using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class FeatureRecordRequiredPairRuleTests
{
    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public void CompleteFeatureRecordProducesNoFinding()
    {
        var snapshot = CandidateSnapshot(
            directories: ["docs/features/FEAT-0001-example"],
            files:
            [
                "docs/features/FEAT-0001-example/README.md",
                "docs/features/FEAT-0001-example/test-cases.md",
            ]);

        var findings = new FeatureRecordRequiredPairRule().Evaluate(
            GovernanceAnalysisContext.Create(snapshot));

        Assert.Empty(findings);
    }

    [Theory]
    [Trait("Scenario", "TEST-0004")]
    [InlineData("README.md")]
    [InlineData("test-cases.md")]
    public void MissingRequiredFileProducesOneBlockingFinding(
        string missingFile)
    {
        var presentFile = string.Equals(
            missingFile,
            "README.md",
            StringComparison.Ordinal)
            ? "test-cases.md"
            : "README.md";
        var featurePath = "docs/features/FEAT-0042-example";
        var snapshot = CandidateSnapshot(
            directories: [featurePath],
            files: [$"{featurePath}/{presentFile}"]);

        var finding = Assert.Single(
            new FeatureRecordRequiredPairRule().Evaluate(
                GovernanceAnalysisContext.Create(snapshot)));

        Assert.Equal(
            "protocol.feature-record.required-pair.v1",
            finding.RuleId);
        Assert.Equal("TEST-0004", finding.CanonicalScenarioId);
        Assert.Equal(
            "governance.feature.record-set-incomplete",
            finding.Code);
        Assert.Same(GovernanceSeverity.High, finding.Severity);
        Assert.Same(GovernanceEnforcement.Blocking, finding.Enforcement);
        Assert.Equal(featurePath, finding.RelativePath);
        Assert.Equal(
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.RepositoryFile,
                    missingFile),
            ],
            finding.UnsatisfiedRequirements);
    }

    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public void FindingsAndMissingRolesHaveOrdinalOrder()
    {
        var snapshot = CandidateSnapshot(
            directories:
            [
                "docs/features/FEAT-0002-zeta",
                "docs/features/FEAT-0001-alpha",
                "docs/features/not-a-feature",
            ],
            files: []);

        var findings = new FeatureRecordRequiredPairRule().Evaluate(
            GovernanceAnalysisContext.Create(snapshot));

        Assert.Equal(
            [
                "docs/features/FEAT-0001-alpha",
                "docs/features/FEAT-0002-zeta",
            ],
            findings.Select(finding => finding.RelativePath));
        Assert.All(
            findings,
            finding => Assert.Equal(
                [
                    new GovernanceRequirement(
                        GovernanceRequirementKind.RepositoryFile,
                        "README.md"),
                    new GovernanceRequirement(
                        GovernanceRequirementKind.RepositoryFile,
                        "test-cases.md"),
                ],
                finding.UnsatisfiedRequirements));
    }

    private static GovernanceRepositorySnapshot CandidateSnapshot(
        IReadOnlyList<string> directories,
        IReadOnlyList<string> files) =>
        GovernanceRepositorySnapshot.CreateCandidate(
            [
                .. directories.Select(GovernanceRepositoryEntry.Directory),
                .. files.Select(GovernanceRepositoryEntry.File),
            ]);
}
