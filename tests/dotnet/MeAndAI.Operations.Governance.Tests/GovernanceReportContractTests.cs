using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceReportContractTests
{
    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ReportUsesTheSharedGovernanceValidationIdentities()
    {
        var report = GovernanceReportTestData.ConformingReport();

        Assert.Same(OperationalApplicationId.Governance, report.Application);
        Assert.Same(OperationStageId.Validate, report.Stage);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void MissingRuleEvaluationProducesIncompleteReport()
    {
        var snapshot = GovernanceReportTestData.CompleteFeatureSnapshot();
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);

        var report = GovernanceReportTestData.Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            evaluations.Take(1));

        Assert.Same(GovernanceVerdict.Incomplete, report.Verdict);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(1, report.Counts.MissingRules);
        Assert.Equal(0, report.Counts.UnmappedRules);
        Assert.Empty(report.Findings);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ChangedCanonicalMetadataIsUnmappedAndCannotDowngradePolicy()
    {
        var snapshot = GovernanceReportTestData.CompleteFeatureSnapshot();
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);
        var changed = new GovernanceRuleEvaluation(
            evaluations[0].RuleIdentity with
            {
                Enforcement = GovernanceEnforcement.Advisory,
            },
            evaluations[0].Findings);

        var report = GovernanceReportTestData.Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [changed, evaluations[1]]);

        Assert.Same(GovernanceVerdict.Incomplete, report.Verdict);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(1, report.Counts.MissingRules);
        Assert.Equal(1, report.Counts.UnmappedRules);
        Assert.Empty(report.Findings);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void InvalidNullRuleIdentityIsUnmappedWithoutEscapingTheFactory()
    {
        var snapshot = GovernanceReportTestData.CompleteFeatureSnapshot();
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);
        var invalid = new GovernanceRuleEvaluation(
            evaluations[0].RuleIdentity with { RuleId = null! },
            evaluations[0].Findings);

        var report = GovernanceReportTestData.Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [invalid, evaluations[1]]);

        Assert.Same(GovernanceVerdict.Incomplete, report.Verdict);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(1, report.Counts.MissingRules);
        Assert.Equal(1, report.Counts.UnmappedRules);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void DuplicateCanonicalEvaluationIsUnmappedAndIncomplete()
    {
        var snapshot = GovernanceReportTestData.CompleteFeatureSnapshot();
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);

        var report = GovernanceReportTestData.Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [evaluations[0], evaluations[0], evaluations[1]]);

        Assert.Same(GovernanceVerdict.Incomplete, report.Verdict);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(1, report.Counts.MissingRules);
        Assert.Equal(2, report.Counts.UnmappedRules);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ConflictingDuplicateEvaluationsAreOrderIndependentAndExcluded()
    {
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-example"));
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);
        var conflicting = new GovernanceRuleEvaluation(
            evaluations[1].RuleIdentity,
            []);
        var factory = GovernanceReportTestData.Factory();

        var first = factory.Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [evaluations[0], evaluations[1], conflicting]);
        var second = factory.Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [evaluations[0], conflicting, evaluations[1]]);

        Assert.Same(GovernanceVerdict.Incomplete, first.Verdict);
        Assert.Equal(1, first.Counts.EvaluatedRules);
        Assert.Equal(1, first.Counts.MissingRules);
        Assert.Equal(2, first.Counts.UnmappedRules);
        Assert.Empty(first.Findings);
        Assert.Equal(
            GovernanceReportSerializer.Serialize(first),
            GovernanceReportSerializer.Serialize(second));
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void FindingOwnedByAnotherRuleInvalidatesItsEvaluation()
    {
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-example"));
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);
        var mismatched = new GovernanceRuleEvaluation(
            evaluations[0].RuleIdentity,
            evaluations[1].Findings);

        var report = GovernanceReportTestData.Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [mismatched, evaluations[1]]);

        Assert.Same(GovernanceVerdict.Incomplete, report.Verdict);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(1, report.Counts.MissingRules);
        Assert.Equal(1, report.Counts.UnmappedRules);
        Assert.Single(report.Findings);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void AdvisoryOnlyReadyEvaluationIsConforming()
    {
        var verdict = GovernanceReportFactory.DetermineVerdict(
            new GovernanceCounts(
                evaluatedRules: 2,
                missingRules: 0,
                unmappedRules: 0,
                blockingFindings: 0,
                advisoryFindings: 1));

        Assert.Same(GovernanceVerdict.Conforming, verdict);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void FindingMetadataAndEvidenceAreSingleOwnedAndTyped()
    {
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-example"));
        var rule = Assert.Single(
            GovernanceRuleCatalog.Current.Rules,
            candidate => string.Equals(
                candidate.RuleId,
                "protocol.feature-record.required-pair.v1",
                StringComparison.Ordinal));
        var context = GovernanceAnalysisContext.Create(snapshot);

        var finding = Assert.Single(rule.Evaluate(context));

        Assert.Same(rule.Identity, finding.RuleIdentity);
        Assert.Equal(
            "docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004",
            finding.CanonicalScenarioOwner);
        Assert.Equal(
            "docs/features/FEAT-0001-example",
            finding.Location.RelativePath);
        Assert.Null(finding.Location.Line);
        Assert.Null(finding.Location.Anchor);
        Assert.Same(
            GovernanceFindingEvidenceScope.Snapshot,
            finding.Evidence.Scope);
        Assert.Equal(snapshot.EvidenceDigest, finding.Evidence.Digest.Value);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ExistingDocumentFindingBindsTheExactContentDigest()
    {
        const string content = """
            # DEC-0001 - Example
            - Classification: Decision
            - Status:
            ## Context
            ## Decision
            ## Consequences
            """;
        var entry = GovernanceTestRepository.MarkdownFile(
            "docs/decisions/DEC-0001-example.md",
            content);
        var context = GovernanceAnalysisContext.Create(
            GovernanceTestRepository.Candidate(entry));
        var rule = Assert.Single(
            GovernanceRuleCatalog.Current.Rules,
            candidate => string.Equals(
                candidate.RuleId,
                "protocol.decision-record.required-structure.v1",
                StringComparison.Ordinal));

        var finding = Assert.Single(rule.Evaluate(context));
        var expectedDigest = Convert.ToHexString(
                SHA256.HashData(Encoding.UTF8.GetBytes(content)))
            .ToLowerInvariant();

        Assert.Same(
            GovernanceFindingEvidenceScope.ContentObject,
            finding.Evidence.Scope);
        Assert.Equal(expectedDigest, finding.Evidence.Digest.Value);
        Assert.Equal(
            "docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005",
            finding.CanonicalScenarioOwner);
    }

    [Theory]
    [InlineData(0, null)]
    [InlineData(null, "Unsafe Anchor")]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void UnsafeFindingLocationIsRejected(int? line, string? anchor)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            new GovernanceFindingLocation(
                RepositoryRelativePath.From("docs/example.md"),
                line,
                anchor));
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void SafeLineAndAnchorAreSerializedExactly()
    {
        var snapshot = GovernanceReportTestData.CompleteFeatureSnapshot();
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);
        var featureIdentity = evaluations[1].RuleIdentity;
        var finding = new GovernanceFinding(
            featureIdentity,
            new GovernanceFindingLocation(
                RepositoryRelativePath.From(
                    "docs/features/FEAT-0001-example/README.md"),
                line: 7,
                anchor: "safe-anchor"),
            GovernanceFindingEvidence.FromContentObject(
                ExactSha256Digest.FromHashBytes(SHA256.HashData([]))),
            [
                new GovernanceRequirement(
                    GovernanceRequirementKind.Section,
                    "Example"),
            ]);
        var report = GovernanceReportTestData.Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [
                evaluations[0],
                new GovernanceRuleEvaluation(featureIdentity, [finding]),
            ]);

        using var document = JsonDocument.Parse(
            GovernanceReportSerializer.Serialize(report));
        var serializedFinding = Assert.Single(
            document.RootElement.GetProperty("findings").EnumerateArray());

        Assert.Equal(7, serializedFinding.GetProperty("line").GetInt32());
        Assert.Equal(
            "safe-anchor",
            serializedFinding.GetProperty("anchor").GetString());
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ReportBytesAreStableAcrossInputOrderCultureAndPathSeparator()
    {
        var entries = new[]
        {
            GovernanceRepositoryEntry.Directory(
                @"docs\features\FEAT-0002-zeta"),
            GovernanceRepositoryEntry.File(
                "docs/features/FEAT-0002-zeta/README.md"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-alpha"),
        };
        var previousCulture = CultureInfo.CurrentCulture;
        var previousUiCulture = CultureInfo.CurrentUICulture;

        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR");
            CultureInfo.CurrentUICulture = CultureInfo.GetCultureInfo("tr-TR");
            var first = Serialize(entries);

            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("en-US");
            CultureInfo.CurrentUICulture = CultureInfo.GetCultureInfo("en-US");
            var second = Serialize(entries.Reverse().ToArray());

            Assert.Equal(first, second);
            Assert.EndsWith("\n", first, StringComparison.Ordinal);
            Assert.DoesNotContain("\\", first, StringComparison.Ordinal);
        }
        finally
        {
            CultureInfo.CurrentCulture = previousCulture;
            CultureInfo.CurrentUICulture = previousUiCulture;
        }
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void FindingBytesAreStableWhenCanonicalLocationKeysCollide()
    {
        var snapshot = GovernanceReportTestData.CompleteFeatureSnapshot();
        var evaluations = GovernanceReportTestData.Evaluate(snapshot);
        var identity = evaluations[1].RuleIdentity;
        var location = new GovernanceFindingLocation(
            RepositoryRelativePath.From(
                "docs/features/FEAT-0001-example/README.md"),
            line: 7,
            anchor: "same-anchor");
        var firstFinding = Finding("first", [1]);
        var secondFinding = Finding("second", [2]);
        var factory = GovernanceReportTestData.Factory();

        var first = factory.Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [
                evaluations[0],
                new GovernanceRuleEvaluation(
                    identity,
                    [firstFinding, secondFinding]),
            ]);
        var second = factory.Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            [
                evaluations[0],
                new GovernanceRuleEvaluation(
                    identity,
                    [secondFinding, firstFinding]),
            ]);

        Assert.Equal(
            GovernanceReportSerializer.Serialize(first),
            GovernanceReportSerializer.Serialize(second));

        GovernanceFinding Finding(string requirement, byte[] content) =>
            new(
                identity,
                location,
                GovernanceFindingEvidence.FromContentObject(
                    ExactSha256Digest.FromHashBytes(
                        SHA256.HashData(content))),
                [
                    new GovernanceRequirement(
                        GovernanceRequirementKind.Section,
                        requirement),
                ]);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ReportDigestBindsSemanticPayloadWithoutDigestFieldOrTransportLf()
    {
        var serialized = Serialize(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-example"),
            GovernanceRepositoryEntry.File(
                "docs/features/FEAT-0001-example/README.md",
                Encoding.UTF8.GetBytes("sensitive-fixture-body")));
        const string digestMarker = ",\"reportDigest\":\"";
        var markerIndex = serialized.LastIndexOf(
            digestMarker,
            StringComparison.Ordinal);

        Assert.True(markerIndex > 0);
        var digestStart = markerIndex + digestMarker.Length;
        var actualDigest = serialized.Substring(digestStart, 64);
        var semanticPayload = serialized[..markerIndex] + "}";
        var expectedDigest = Convert.ToHexString(
                SHA256.HashData(Encoding.UTF8.GetBytes(semanticPayload)))
            .ToLowerInvariant();

        Assert.Equal(expectedDigest, actualDigest);
        Assert.Equal('}', serialized[^2]);
        Assert.Equal('\n', serialized[^1]);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void SerializedFindingCarriesCanonicalOwnerLocationAndEvidenceWithoutContent()
    {
        var serialized = Serialize(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-example"));

        using var document = JsonDocument.Parse(serialized);
        var root = document.RootElement;
        var finding = Assert.Single(
            root.GetProperty("findings").EnumerateArray());

        Assert.Equal(0, root.GetProperty("counts").GetProperty("missingRules").GetInt32());
        Assert.Equal(0, root.GetProperty("counts").GetProperty("unmappedRules").GetInt32());
        Assert.Equal(
            "docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004",
            finding.GetProperty("canonicalScenarioOwner").GetString());
        Assert.Equal(
            "docs/features/FEAT-0001-example",
            finding.GetProperty("relativePath").GetString());
        Assert.Equal(JsonValueKind.Null, finding.GetProperty("line").ValueKind);
        Assert.Equal(JsonValueKind.Null, finding.GetProperty("anchor").ValueKind);
        var evidence = finding.GetProperty("evidence");
        Assert.Equal("snapshot", evidence.GetProperty("scope").GetString());
        Assert.Equal(64, evidence.GetProperty("digest").GetString()!.Length);
        Assert.DoesNotContain(
            "sensitive-fixture-body",
            serialized,
            StringComparison.Ordinal);
    }

    private static string Serialize(
        params GovernanceRepositoryEntry[] entries) =>
        GovernanceReportSerializer.Serialize(
            GovernanceEngine.CreateDefault().EvaluateCandidateShadow(
                GovernanceProfileId.ProtocolAuthority,
                GovernanceTestRepository.Candidate(entries)));
}
