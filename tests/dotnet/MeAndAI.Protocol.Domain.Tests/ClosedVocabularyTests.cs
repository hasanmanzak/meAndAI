using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class ClosedVocabularyTests
{
    private static readonly string[] AllVocabularyTokens =
    [
        "protocol-authority-self-consumer",
        "consumer",
        "conformance",
        "adoption-assessment",
        "adoption-plan",
        "adoption-apply",
        "update-assessment",
        "update-plan",
        "update-apply",
        "publication",
        "finalization",
        "recovery",
        "exact-commit",
        "candidate",
        "provider-event",
        "provider-full-inventory",
        "captured-evidence",
        "repository",
        "provider",
        "workflow",
        "release",
        "audit",
        "prospective",
        "full-blocking",
        "complete",
        "incomplete",
        "failed",
        "satisfied",
        "violated",
        "not-applicable",
        "not-evaluated",
        "conforming",
        "non-conforming",
        "indeterminate",
        "allow",
        "block",
        "report-only",
    ];

    private static readonly string[] ExplicitRejectedAliases =
    [
        "protocol-authority",
        "self-consumer",
        "governance",
        "adoption",
        "update",
        "commit",
        "event",
        "full-inventory",
        "github",
        "fullblocking",
        "success",
        "partial",
        "failure",
        "pass",
        "fail",
        "skipped",
        "nonconforming",
        "reportonly",
    ];

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void SubjectRoleContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (
                    Token: "protocol-authority-self-consumer",
                    Named: SubjectRole.ProtocolAuthoritySelfConsumer),
                (Token: "consumer", Named: SubjectRole.Consumer),
            ],
            SubjectRole.Parse,
            SubjectRole.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ProtocolOperationContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "conformance", Named: ProtocolOperation.Conformance),
                (
                    Token: "adoption-assessment",
                    Named: ProtocolOperation.AdoptionAssessment),
                (Token: "adoption-plan", Named: ProtocolOperation.AdoptionPlan),
                (Token: "adoption-apply", Named: ProtocolOperation.AdoptionApply),
                (
                    Token: "update-assessment",
                    Named: ProtocolOperation.UpdateAssessment),
                (Token: "update-plan", Named: ProtocolOperation.UpdatePlan),
                (Token: "update-apply", Named: ProtocolOperation.UpdateApply),
                (Token: "publication", Named: ProtocolOperation.Publication),
                (Token: "finalization", Named: ProtocolOperation.Finalization),
                (Token: "recovery", Named: ProtocolOperation.Recovery),
            ],
            ProtocolOperation.Parse,
            ProtocolOperation.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void SnapshotKindContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "exact-commit", Named: SnapshotKind.ExactCommit),
                (Token: "candidate", Named: SnapshotKind.Candidate),
                (Token: "provider-event", Named: SnapshotKind.ProviderEvent),
                (
                    Token: "provider-full-inventory",
                    Named: SnapshotKind.ProviderFullInventory),
                (Token: "captured-evidence", Named: SnapshotKind.CapturedEvidence),
            ],
            SnapshotKind.Parse,
            SnapshotKind.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void SurfaceKindContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "repository", Named: SurfaceKind.Repository),
                (Token: "provider", Named: SurfaceKind.Provider),
                (Token: "workflow", Named: SurfaceKind.Workflow),
                (Token: "release", Named: SurfaceKind.Release),
            ],
            SurfaceKind.Parse,
            SurfaceKind.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void EnforcementPhaseContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "audit", Named: EnforcementPhase.Audit),
                (Token: "prospective", Named: EnforcementPhase.Prospective),
                (Token: "full-blocking", Named: EnforcementPhase.FullBlocking),
            ],
            EnforcementPhase.Parse,
            EnforcementPhase.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void AcquisitionStatusContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "complete", Named: AcquisitionStatus.Complete),
                (Token: "incomplete", Named: AcquisitionStatus.Incomplete),
                (Token: "failed", Named: AcquisitionStatus.Failed),
            ],
            AcquisitionStatus.Parse,
            AcquisitionStatus.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void RuleEvaluationStatusContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "satisfied", Named: RuleEvaluationStatus.Satisfied),
                (Token: "violated", Named: RuleEvaluationStatus.Violated),
                (
                    Token: "not-applicable",
                    Named: RuleEvaluationStatus.NotApplicable),
                (
                    Token: "not-evaluated",
                    Named: RuleEvaluationStatus.NotEvaluated),
            ],
            RuleEvaluationStatus.Parse,
            RuleEvaluationStatus.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ConformanceVerdictContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "conforming", Named: ConformanceVerdict.Conforming),
                (
                    Token: "non-conforming",
                    Named: ConformanceVerdict.NonConforming),
                (Token: "indeterminate", Named: ConformanceVerdict.Indeterminate),
            ],
            ConformanceVerdict.Parse,
            ConformanceVerdict.TryParse);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void EnforcementDecisionContractIsClosedAndExact()
    {
        AssertClosedVocabulary(
            [
                (Token: "allow", Named: EnforcementDecision.Allow),
                (Token: "block", Named: EnforcementDecision.Block),
                (Token: "report-only", Named: EnforcementDecision.ReportOnly),
            ],
            EnforcementDecision.Parse,
            EnforcementDecision.TryParse);
    }

    private static void AssertClosedVocabulary<T>(
        IReadOnlyList<(string Token, T Named)> declared,
        Func<string, T> parse,
        TryParseDelegate<T> tryParse)
        where T : class, IEquatable<T>
    {
        foreach (var (token, named) in declared)
        {
            var parsed = parse(token);

            Assert.Equal(token, parsed.ToString());
            Assert.Equal(token, ReadValue(parsed));
            Assert.Equal(named, parsed);
            Assert.True(named.Equals((object)parsed));
            Assert.Equal(named.GetHashCode(), parsed.GetHashCode());

            Assert.True(tryParse(token, out var tryParsed));
            Assert.NotNull(tryParsed);
            Assert.Equal(named, tryParsed);

            var invalidTokenVariants = new[]
            {
                token.ToUpperInvariant(),
                " " + token,
                token + " ",
                MutateFirstCharacterToNonAscii(token),
                token + "é",
                token.Replace('-', '_'),
                token.Replace("-", string.Empty, StringComparison.Ordinal),
            }
            .Where(value => !string.Equals(value, token, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal);

            foreach (var invalidTokenVariant in invalidTokenVariants)
            {
                AssertRejected(invalidTokenVariant, parse, tryParse);
            }
        }

        for (var left = 0; left < declared.Count; left++)
        {
            for (var right = left + 1; right < declared.Count; right++)
            {
                Assert.NotEqual(declared[left].Named, declared[right].Named);
            }
        }

        Assert.False(declared[0].Named.Equals(default));
        Assert.False(declared[0].Named.Equals((object)declared[0].Token));

        Assert.Throws<ArgumentNullException>(() => parse(null!));
        Assert.False(tryParse(null, out var nullResult));
        Assert.Null(nullResult);

        var declaredTokens = declared
            .Select(value => value.Token)
            .ToHashSet(StringComparer.Ordinal);
        var invalidValues = AllVocabularyTokens
            .Where(token => !declaredTokens.Contains(token))
            .Concat(ExplicitRejectedAliases)
            .Append(string.Empty)
            .Append("unknown-token")
            .Distinct(StringComparer.Ordinal);

        foreach (var value in invalidValues)
        {
            AssertRejected(value, parse, tryParse);
        }
    }

    private static void AssertRejected<T>(
        string value,
        Func<string, T> parse,
        TryParseDelegate<T> tryParse)
        where T : class
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => parse(value));
        Assert.False(tryParse(value, out var result));
        Assert.Null(result);
    }

    private static string MutateFirstCharacterToNonAscii(string value) =>
        "é" + value[1..];

    private static string ReadValue<T>(T value)
        where T : class
    {
        var property = typeof(T).GetProperty("Value")
            ?? throw new InvalidOperationException(
                $"{typeof(T).Name} has no public Value property.");

        return Assert.IsType<string>(property.GetValue(value));
    }

    private delegate bool TryParseDelegate<T>(string? value, out T? result)
        where T : class;
}
