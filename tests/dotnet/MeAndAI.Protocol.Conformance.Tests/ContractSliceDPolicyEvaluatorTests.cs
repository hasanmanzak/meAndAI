using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;
using MeAndAI.Protocol.Policy.Models;
using System.Text;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceDPolicyEvaluatorTests
{
    private const string Rule1Marker = "TEST-0210-D-BEHAVIOR-RED-0003";
    private const string Rule2Marker = "TEST-0210-D-BEHAVIOR-RED-0004";
    private const string Rule3Marker = "TEST-0210-D-BEHAVIOR-RED-0005";
    private const string Rule4Marker = "TEST-0210-D-BEHAVIOR-RED-0006";
    private const string Rule5Marker = "TEST-0210-D-BEHAVIOR-RED-0007";

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0001_against_fresh_qualified_fixture()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0001(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule1Marker);
        }

        Assert.Equal(8, evidence.ExercisedFindings);
        Assert.Equal(7, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0002_against_fresh_qualified_fixture()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0002(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule2Marker);
        }

        Assert.Equal(11, evidence.ExercisedFindings);
        Assert.Equal(12, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0003_with_exact_target_specialization_and_co_report()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0003(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule3Marker);
        }

        Assert.Equal(7, evidence.ExercisedFindings);
        Assert.Equal(12, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0004_with_exact_fragment_specialization_and_co_report()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0004(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule4Marker);
        }

        Assert.Equal(5, evidence.ExercisedFindings);
        Assert.Equal(12, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0005_with_exact_commit_specialization_and_co_report()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0005(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule5Marker);
        }

        Assert.Equal(5, evidence.ExercisedFindings);
        Assert.Equal(11, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }
}

internal sealed record ContractSliceDPolicyEvaluatorEvidence(
    int ExercisedFindings,
    int ExercisedFixtures,
    bool ExactReferences,
    bool CancellationClosed);

internal static class ContractSliceDPolicyEvaluatorFixture
{
    private const string FeatureRoot =
        "docs/features/FEAT-0065-shared-executable-conformance-runtime";
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string TextSlot = "protocol.slot.repository-governed-text";
    private const string ReadmeSelector = "protocol.selector.feature-readme";
    private const string TestsSelector = "protocol.selector.feature-test-cases";
    private const string DecisionSelector = "protocol.selector.decision-record";
    private const string Rule1 = "RULE-0001";
    private const string Rule2 = "RULE-0002";
    private const string Rule3 = "RULE-0003";
    private const string Rule4 = "RULE-0004";
    private const string Rule5 = "RULE-0005";
    private const string RepositoryGovernedSlot =
        "protocol.slot.repository-governed-text";
    private const string ProviderGovernedSlot =
        "protocol.slot.provider-governed-text";
    private const string TargetSlot =
        "protocol.slot.repository-target-resolution";
    private const string Owner = "https://github.com/owner/repo";
    private const string ObjectIdentity =
        "0123456789abcdef0123456789abcdef01234567";
    private const string ReferenceText = "# Feature record\n\nSee DEC-0001.\n";
    private const string ValidDecision = """
        # DEC-0001 - Exact decision

        1. Classification: Accepted
        2. Status: Active
        3. Date: 2026-08-13
        4. Decision owners: Protocol maintainers
        5. Related features: FEAT-0065
        6. Related decisions: None

        ## Context

        Exact context.

        ## Decision

        Exact decision.

        ## Consequences

        Exact consequences.

        ## Alternatives considered

        Exact alternatives.

        ## Review condition

        Exact review condition.
        """;
    private static readonly ExactSha256Digest Digest =
        ExactSha256Digest.Parse(new string('0', 64));

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0001(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);

        var missingReadme = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.File));
        if (missingReadme.Intent.Findings.Count == 0 &&
            missingReadme.Intent.Failures.Count == 0)
        {
            return null;
        }

        AssertFindings(missingReadme,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot));

        var complete = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/README.md", RepositoryEntryKind.File),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.File));
        AssertFindings(complete);

        var missingTests = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/README.md", RepositoryEntryKind.File));
        AssertFindings(missingTests,
            ("protocol.feature.test-cases-missing", TestsSelector, FeatureRoot));

        var bothMissing = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory));
        AssertFindings(bothMissing,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot),
            ("protocol.feature.test-cases-missing", TestsSelector, FeatureRoot));

        var wrongKinds = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/README.md", RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.SymbolicLink));
        AssertFindings(wrongKinds,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot),
            ("protocol.feature.test-cases-missing", TestsSelector, FeatureRoot));

        var ignored = Evaluate(export,
            Entry("docs/features/FEAT-0065", RepositoryEntryKind.Directory),
            Entry("docs/features/feat-0065-lowercase", RepositoryEntryKind.Directory),
            Entry("docs/ideas/FEAT-0065-unrelated", RepositoryEntryKind.Directory));
        AssertFindings(ignored);

        const string otherRoot = "docs/features/FEAT-9999-other";
        var ordinal = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.File),
            Entry(otherRoot, RepositoryEntryKind.Directory),
            Entry($"{otherRoot}/README.md", RepositoryEntryKind.File));
        AssertFindings(ordinal,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot),
            ("protocol.feature.test-cases-missing", TestsSelector, otherRoot));

        var cases = new[]
        {
            missingReadme, complete, missingTests, bothMissing,
            wrongKinds, ignored, ordinal,
        };
        return new(
            cases.Sum(item => item.Intent.Findings.Count),
            cases.Length,
            cases.All(item => item.ExactReferences),
            cases.All(item => item.CancellationClosed));
    }

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0002(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);

        var missing = EvaluateDecision(export, ReferenceText);
        if (missing.Intent.Findings.Count == 0 && missing.Intent.Failures.Count == 0)
        {
            return null;
        }

        AssertDecisionFindings(missing,
            ("protocol.decision.record-missing", "DEC-0001"));

        var valid = EvaluateDecision(export, ReferenceText, ValidDecision);
        AssertDecisionFindings(valid);

        var missingMetadata = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace("3. Date: 2026-08-13\n", string.Empty,
                StringComparison.Ordinal));
        AssertDecisionFindings(missingMetadata,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var reorderedMetadata = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "2. Status: Active\n3. Date: 2026-08-13",
                "2. Date: 2026-08-13\n3. Status: Active",
                StringComparison.Ordinal));
        AssertDecisionFindings(reorderedMetadata,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var duplicateMetadata = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "3. Date: 2026-08-13",
                "3. Status: Active\n4. Date: 2026-08-13",
                StringComparison.Ordinal));
        AssertDecisionFindings(duplicateMetadata,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var missingSection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "## Consequences\n\nExact consequences.\n\n",
                string.Empty,
                StringComparison.Ordinal));
        AssertDecisionFindings(missingSection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var reorderedSection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "## Decision\n\nExact decision.\n\n## Consequences\n\nExact consequences.",
                "## Consequences\n\nExact consequences.\n\n## Decision\n\nExact decision.",
                StringComparison.Ordinal));
        AssertDecisionFindings(reorderedSection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var duplicateSection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "## Consequences\n\nExact consequences.",
                "## Decision\n\nDuplicate decision.\n\n## Consequences\n\nExact consequences.",
                StringComparison.Ordinal));
        AssertDecisionFindings(duplicateSection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var emptySection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace("## Context\n\nExact context.", "## Context",
                StringComparison.Ordinal));
        AssertDecisionFindings(emptySection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var malformedHeading = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "# DEC-0001 - Exact decision",
                "# DEC-0001 - ",
                StringComparison.Ordinal));
        AssertDecisionFindings(malformedHeading,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var duplicateDecision = EvaluateDecision(
            export, ReferenceText, ValidDecision, ValidDecision);
        AssertDecisionFindings(duplicateDecision,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var ordinal = EvaluateDecision(
            export,
            "# Feature record\n\nSee DEC-0002 then DEC-0001.\n",
            ValidDecision);
        AssertDecisionFindings(ordinal,
            ("protocol.decision.record-missing", "DEC-0002"));

        var cases = new[]
        {
            missing, valid, missingMetadata, reorderedMetadata,
            duplicateMetadata, missingSection, reorderedSection,
            duplicateSection, emptySection, malformedHeading,
            duplicateDecision, ordinal,
        };
        return new(
            cases.Sum(item => item.Intent.Findings.Count),
            cases.Length,
            cases.All(item => item.ExactReferences),
            cases.All(item => item.CancellationClosed));
    }

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0003(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);

        var unsupported = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.UnsupportedAuthoringForm,
            GovernedReferenceResolution.Exact));
        if (unsupported.Intent.Findings.Count == 0 &&
            unsupported.Intent.Failures.Count == 0)
        {
            return null;
        }

        AssertReferenceFinding(
            unsupported, "protocol.reference.unsupported-authoring-form");
        var nonClickable = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.NonClickable,
            GovernedReferenceResolution.Unresolved));
        AssertReferenceFinding(nonClickable, "protocol.reference.not-clickable");
        var unresolved = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Unresolved));
        AssertReferenceFinding(unresolved, "protocol.reference.unresolved-target");
        var wrongTarget = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongTarget));
        AssertReferenceFinding(wrongTarget, "protocol.reference.wrong-target");
        var missingFragment = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.MissingFragment));
        AssertReferenceFinding(missingFragment, "protocol.reference.wrong-target");
        var exact = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Exact));
        AssertReferenceFinding(exact);
        var externalUnqualified = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired));
        AssertReferenceFinding(externalUnqualified);
        var externalExact = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired),
            GovernedReferenceResolution.Exact);
        AssertReferenceFinding(externalExact);
        var embeddedFragment = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongFragment));
        AssertReferenceFinding(embeddedFragment);
        var commitOwner = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongRepository));
        AssertReferenceFinding(commitOwner);
        var embeddedContainingTarget = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongTarget));
        AssertReferenceFinding(
            embeddedContainingTarget, "protocol.reference.wrong-target");
        var commitContainingTarget = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongTarget),
            GovernedReferenceResolution.WrongTarget,
            provider: true);
        AssertReferenceFinding(
            commitContainingTarget, "protocol.reference.wrong-target");

        AssertRealReferencePipeline(export);
        var cases = new[]
        {
            unsupported, nonClickable, unresolved, wrongTarget, missingFragment,
            exact, externalUnqualified, externalExact, embeddedFragment,
            commitOwner, embeddedContainingTarget, commitContainingTarget,
        };
        return new(
            cases.Sum(item => item.Intent.Findings.Count),
            cases.Length,
            cases.All(item => item.ExactReferences),
            cases.All(item => item.CancellationClosed));
    }

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0004(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);
        var declarationMissing = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.MissingFragment,
            path: null), rule: Rule4);
        if (declarationMissing.Intent.Findings.Count == 0)
        {
            return null;
        }

        AssertReferenceFinding(
            declarationMissing, "protocol.record.anchor-missing");
        var declarationDuplicate = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongFragment,
            path: null), rule: Rule4);
        AssertReferenceFinding(
            declarationDuplicate, "protocol.record.anchor-duplicate");
        var declarationExact = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Exact,
            path: null), rule: Rule4);
        AssertReferenceFinding(declarationExact);
        var fragmentMissing = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.MissingFragment), rule: Rule4);
        AssertReferenceFinding(
            fragmentMissing, "protocol.reference.fragment-missing");
        var fragmentWrong = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongFragment), rule: Rule4);
        AssertReferenceFinding(
            fragmentWrong, "protocol.reference.fragment-wrong");
        var fragmentExact = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Exact), rule: Rule4);
        AssertReferenceFinding(fragmentExact);
        var coReport = Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.UnsupportedAuthoringForm,
            GovernedReferenceResolution.MissingFragment);
        var common = EvaluateReference(export, coReport);
        AssertReferenceFinding(
            common, "protocol.reference.unsupported-authoring-form");
        var specialized = EvaluateReference(export, coReport, rule: Rule4);
        AssertReferenceFinding(
            specialized, "protocol.reference.fragment-missing");
        var wrongTarget = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongTarget), rule: Rule4);
        AssertReferenceFinding(wrongTarget);
        var unresolved = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Unresolved), rule: Rule4);
        AssertReferenceFinding(unresolved);
        var external = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired), rule: Rule4);
        AssertReferenceFinding(external);
        var crossRecord = EvaluateReference(export, Reference(
            GovernedReferenceKind.CrossRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongFragment), rule: Rule4);
        AssertReferenceFinding(crossRecord);
        var ambiguity = EvaluateReference(export, Reference(
            GovernedReferenceKind.EmbeddedRecord,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired),
            GovernedReferenceResolution.Exact,
            rule: Rule4,
            secondOverlay: GovernedReferenceResolution.Exact);
        Assert.Empty(ambiguity.Intent.Findings);
        Assert.Equal(
            "protocol.evaluator.reference-ambiguity",
            Assert.Single(ambiguity.Intent.Failures).Code.Value);

        var cases = new[]
        {
            declarationMissing, declarationDuplicate, declarationExact,
            fragmentMissing, fragmentWrong, fragmentExact, specialized,
            wrongTarget, unresolved, external, crossRecord, ambiguity,
        };
        return new(
            cases.Sum(item => item.Intent.Findings.Count),
            cases.Length,
            cases.All(item => item.ExactReferences),
            cases.All(item => item.CancellationClosed));
    }

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0005(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);
        var nonClickableReference = Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.NonClickable,
            GovernedReferenceResolution.Exact);
        var nonClickable = EvaluateReference(
            export, nonClickableReference, rule: Rule5);
        if (nonClickable.Intent.Findings.Count == 0)
        {
            return null;
        }

        AssertReferenceFinding(
            nonClickable, "protocol.commit-reference.not-permalink");
        var common = EvaluateReference(export, nonClickableReference);
        AssertReferenceFinding(common, "protocol.reference.not-clickable");
        var missingForm = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Exact,
            omitCommit: true), rule: Rule5);
        AssertReferenceFinding(
            missingForm, "protocol.commit-reference.not-permalink");
        var wrongRepository = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongRepository), rule: Rule5);
        AssertReferenceFinding(
            wrongRepository, "protocol.commit-reference.wrong-repository");
        var unresolved = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Unresolved), rule: Rule5);
        AssertReferenceFinding(
            unresolved, "protocol.commit-reference.unresolved");
        var wrongObject = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongObject), rule: Rule5);
        AssertReferenceFinding(
            wrongObject, "protocol.commit-reference.wrong-object");
        var exact = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.Exact), rule: Rule5);
        AssertReferenceFinding(exact);
        var external = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired), rule: Rule5);
        AssertReferenceFinding(external);
        var qualified = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired),
            GovernedReferenceResolution.Exact,
            provider: true,
            rule: Rule5);
        AssertReferenceFinding(qualified);
        var wrongTarget = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongTarget), rule: Rule5);
        AssertReferenceFinding(wrongTarget);
        var referenceAmbiguity = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.ExternalEvidenceRequired),
            GovernedReferenceResolution.Exact,
            rule: Rule5,
            secondOverlay: GovernedReferenceResolution.Exact);
        Assert.Empty(referenceAmbiguity.Intent.Findings);
        Assert.Equal(
            "protocol.evaluator.reference-ambiguity",
            Assert.Single(referenceAmbiguity.Intent.Failures).Code.Value);
        var intentAmbiguity = EvaluateReference(export, Reference(
            GovernedReferenceKind.Commit,
            GovernedReferenceSyntax.Clickable,
            GovernedReferenceResolution.WrongRepository),
            GovernedReferenceResolution.Exact,
            rule: Rule5);
        Assert.Empty(intentAmbiguity.Intent.Findings);
        Assert.Equal(
            "protocol.evaluator.commit-intent-ambiguity",
            Assert.Single(intentAmbiguity.Intent.Failures).Code.Value);

        var cases = new[]
        {
            nonClickable, missingForm, wrongRepository, unresolved, wrongObject,
            exact, external, qualified, wrongTarget, referenceAmbiguity,
            intentAmbiguity,
        };
        return new(
            cases.Sum(item => item.Intent.Findings.Count),
            cases.Length,
            cases.All(item => item.ExactReferences),
            cases.All(item => item.CancellationClosed));
    }

    private static ReferenceCase EvaluateReference(
        PolicyQualificationSliceExport export,
        GovernedReferenceView reference,
        GovernedReferenceResolution? overlay = null,
        bool provider = false,
        string rule = Rule3,
        GovernedReferenceResolution? secondOverlay = null)
    {
        var referenceIndex = new ReferenceIndexFixture([reference]);
        var targetEvidence = QualifiedEvidenceHandle.Create();
        var targets = new List<RepositoryTargetResolutionView>();
        if (overlay is not null)
        {
            targets.Add(RepositoryTargetResolutionView.Create(
                reference.Reference,
                overlay,
                targetEvidence,
                null,
                null,
                reference.Target));
        }

        if (secondOverlay is not null)
        {
            targets.Add(RepositoryTargetResolutionView.Create(
                reference.Reference,
                secondOverlay,
                QualifiedEvidenceHandle.Create(),
                null,
                null,
                reference.Target));
        }
        var targetIndex = new TargetIndexFixture(targets);
        var referenceHandle = CapabilityHandle<IGovernedReferenceIndex>.Create(
            CapabilityTypeToken<IGovernedReferenceIndex>.Create(
                export.SchemaRegistry.Indexes.Single(item =>
                    item.IndexKey == "protocol.index.governed-reference")
                    .OutputCapability),
            referenceIndex,
            [reference.Reference],
            SemanticResourceUsage.Create(0, 0, 0, 0),
            SemanticResourceLedger.Create([]));
        var targetHandle = CapabilityHandle<IRepositoryTargetResolutionIndex>.Create(
            CapabilityTypeToken<IRepositoryTargetResolutionIndex>.Create(
                export.SchemaRegistry.Indexes.Single(item =>
                    item.IndexKey == "protocol.index.repository-target-resolution")
                    .OutputCapability),
            targetIndex,
            targets.Select(item => item.ResolutionEvidence),
            SemanticResourceUsage.Create(0, 0, 0, 0),
            SemanticResourceLedger.Create([]));
        var governedSlot = provider ? ProviderGovernedSlot : RepositoryGovernedSlot;
        var context = QualifiedEvidenceHandle.Create();
        var access = RuleInputAccess.Create(
            [
                SlotCapabilityBinding.Create(governedSlot, referenceHandle),
                SlotCapabilityBinding.Create(TargetSlot, targetHandle),
            ],
            new Dictionary<string, QualifiedEvidenceHandle>
            {
                [governedSlot] = context,
                [TargetSlot] = targetEvidence,
            },
            ExpectedReferences.Rejecting);
        var registration = export.EvaluatorRegistrations.Single(item =>
            item.Declaration.RuleId.Value == rule);
        var input = RuleEvaluationInput.Create(
            registration.Declaration.RuleId,
            registration.Declaration.RuleRevision,
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.Conformance,
                SnapshotKind.ExactCommit,
                SurfaceSet.Create([
                    provider ? SurfaceKind.Provider : SurfaceKind.Repository,
                ]),
                EnforcementPhase.Audit),
            access);
        var intent = registration.Evaluator.Evaluate(input, CancellationToken.None);
        Assert.Throws<OperationCanceledException>(() =>
            registration.Evaluator.Evaluate(input, new CancellationToken(true)));
        return new(intent, reference, context, overlay is null ? null : targetEvidence,
            true, true);
    }

    private static GovernedReferenceView Reference(
        GovernedReferenceKind kind,
        GovernedReferenceSyntax syntax,
        GovernedReferenceResolution resolution,
        string? path = "docs/decisions/DEC-0001.md",
        string? owner = Owner,
        bool omitCommit = false)
    {
        var reference = QualifiedEvidenceHandle.Create();
        var target = QualifiedEvidenceHandle.Create();
        return GovernedReferenceView.Create(
            kind,
            syntax,
            resolution,
            owner,
            kind.Equals(GovernedReferenceKind.Commit) && !omitCommit
                ? ObjectIdentity
                : null,
            null,
            null,
            path,
            "dec-0001",
            reference,
            target);
    }

    private static void AssertReferenceFinding(
        ReferenceCase actual,
        params string[] codes)
    {
        Assert.Empty(actual.Intent.Failures);
        Assert.Equal(codes, actual.Intent.Findings.Select(item => item.Code.Value));
        foreach (var finding in actual.Intent.Findings)
        {
            Assert.Same(actual.Reference.Reference, finding.PrimaryReference);
            Assert.Contains(actual.Context, finding.RelatedReferences);
            Assert.Contains(actual.Reference.Target!, finding.RelatedReferences);
            if (actual.TargetEvidence is not null)
            {
                Assert.Contains(actual.TargetEvidence, finding.RelatedReferences);
            }
        }
    }

    private static void AssertRealReferencePipeline(
        PolicyQualificationSliceExport export)
    {
        var text = $"- [commit](https://github.com/owner/repo/commit/{ObjectIdentity})";
        var source = export.CodecRegistrations
            .Single(item => item.Declaration.SchemaKey == "protocol.governed-text")
            .Accept(new TextCodecVisitor(export, "docs/reference.md", text));
        var model = export.ParserRegistrations
            .Single(item => item.Declaration.ParserKey == "protocol.parser.markdown")
            .Accept(new MarkdownParserVisitor(source));
        var indexed = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey ==
                "protocol.index.governed-reference")
            .Accept(new GovernedIndexVisitor([model]));
        var reference = Assert.Single(indexed.Index.References);
        Assert.Equal(GovernedReferenceKind.Commit, reference.Kind);
        Assert.Equal(GovernedReferenceSyntax.Clickable, reference.Syntax);
        var projected = export.DemandProjectorRegistrations.Single()
            .Accept(new ReferenceProjectionVisitor(export, indexed.Index));
        var candidate = Assert.Single(projected);
        Assert.Equal(Owner, candidate.OwningRepositoryIdentity);
        Assert.Equal(ObjectIdentity, candidate.CommitObjectId);
        Assert.Same(reference.Reference, candidate.SourceReference);
    }

    private static EvaluationCase Evaluate(
        PolicyQualificationSliceExport export,
        params RepositoryTreePayloadEntry[] entries)
    {
        var model = export.CodecRegistrations
            .Single(item => item.Declaration.SchemaKey == "protocol.repository-tree")
            .Accept(new TreeCodecVisitor(export, entries));
        var indexed = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey == "protocol.index.repository-tree")
            .Accept(new TreeIndexVisitor(model));
        var lookup = new ExpectedReferences();
        var access = RuleInputAccess.Create(
            [SlotCapabilityBinding.Create(TreeSlot, indexed.Handle)],
            new Dictionary<string, QualifiedEvidenceHandle>(),
            lookup);
        var registration = export.EvaluatorRegistrations.Single(item =>
            item.Declaration.RuleId.Value == Rule1);
        var profile = ExecutionProfile.Create(
            SubjectRole.Consumer,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);
        var input = RuleEvaluationInput.Create(
            registration.Declaration.RuleId,
            registration.Declaration.RuleRevision,
            profile,
            access);
        var intent = registration.Evaluator.Evaluate(
            input, CancellationToken.None);
        Assert.Throws<OperationCanceledException>(() =>
            registration.Evaluator.Evaluate(
                input, new CancellationToken(canceled: true)));
        return new(intent, indexed.Tree, lookup, true, true);
    }

    private static DecisionCase EvaluateDecision(
        PolicyQualificationSliceExport export,
        params string[] documents)
    {
        var treeEntries = new List<RepositoryTreePayloadEntry>
        {
            Entry("docs", RepositoryEntryKind.Directory),
            Entry("docs/decisions", RepositoryEntryKind.Directory),
        };
        treeEntries.AddRange(documents.Select((_, index) =>
            Entry($"docs/decisions/document-{index:D2}.md", RepositoryEntryKind.File)));
        var treeModel = export.CodecRegistrations
            .Single(item => item.Declaration.SchemaKey == "protocol.repository-tree")
            .Accept(new TreeCodecVisitor(export, treeEntries));
        var tree = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey == "protocol.index.repository-tree")
            .Accept(new TreeIndexVisitor(treeModel));

        var parsed = documents.Select((text, index) =>
        {
            var source = export.CodecRegistrations
                .Single(item => item.Declaration.SchemaKey == "protocol.governed-text")
                .Accept(new TextCodecVisitor(
                    export,
                    $"docs/decisions/document-{index:D2}.md",
                    text));
            return export.ParserRegistrations
                .Single(item => item.Declaration.ParserKey == "protocol.parser.markdown")
                .Accept(new MarkdownParserVisitor(source));
        }).ToArray();
        var records = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey == "protocol.index.protocol-record")
            .Accept(new RecordIndexVisitor(parsed));
        var treeProof = QualifiedEvidenceHandle.Create();
        var textProof = QualifiedEvidenceHandle.Create();
        var lookup = new ExpectedReferences();
        var access = RuleInputAccess.Create(
            [
                SlotCapabilityBinding.Create(TreeSlot, tree.Handle),
                SlotCapabilityBinding.Create(TextSlot, records.Handle),
            ],
            new Dictionary<string, QualifiedEvidenceHandle>
            {
                [TreeSlot] = treeProof,
                [TextSlot] = textProof,
            },
            lookup);
        var registration = export.EvaluatorRegistrations.Single(item =>
            item.Declaration.RuleId.Value == Rule2);
        var profile = ExecutionProfile.Create(
            SubjectRole.Consumer,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);
        var input = RuleEvaluationInput.Create(
            registration.Declaration.RuleId,
            registration.Declaration.RuleRevision,
            profile,
            access);
        var intent = registration.Evaluator.Evaluate(input, CancellationToken.None);
        Assert.Throws<OperationCanceledException>(() =>
            registration.Evaluator.Evaluate(input, new CancellationToken(true)));
        return new(intent, records.Index, lookup, treeProof, textProof, true, true);
    }

    private static void AssertDecisionFindings(
        DecisionCase actual,
        params (string Code, string RecordId)[] expected)
    {
        Assert.Empty(actual.Intent.Failures);
        Assert.Equal(expected.Select(item => item.Code),
            actual.Intent.Findings.Select(item => item.Code.Value));
        for (var index = 0; index < expected.Length; index++)
        {
            var item = expected[index];
            var reference = actual.Index.Records.Single(record =>
                record.RecordKind == "protocol.record.decision-reference" &&
                record.RecordId == item.RecordId);
            var finding = actual.Intent.Findings[index];
            if (item.Code == "protocol.decision.record-missing")
            {
                Assert.Same(
                    actual.References.Require(DecisionSelector, reference.Evidence),
                    finding.PrimaryReference);
            }
            else
            {
                Assert.Same(
                    actual.Index.Records.First(record =>
                        record.RecordKind == "protocol.record.decision" &&
                        record.RecordId == item.RecordId).Evidence,
                    finding.PrimaryReference);
            }

            Assert.Collection(finding.RelatedReferences,
                related => Assert.Same(actual.TreeProof, related),
                related => Assert.Same(actual.TextProof, related),
                related => Assert.Same(reference.Evidence, related));
        }
    }

    private static void AssertFindings(
        EvaluationCase actual,
        params (string Code, string Selector, string ParentPath)[] expected)
    {
        Assert.Empty(actual.Intent.Failures);
        Assert.Equal(expected.Select(item => item.Code),
            actual.Intent.Findings.Select(item => item.Code.Value));
        for (var index = 0; index < expected.Length; index++)
        {
            var item = expected[index];
            var parent = actual.Tree.Entries.Single(entry =>
                entry.RepositoryRelativePath == item.ParentPath).Evidence;
            var primary = actual.References.Require(item.Selector, parent);
            Assert.Same(primary, actual.Intent.Findings[index].PrimaryReference);
            Assert.Collection(actual.Intent.Findings[index].RelatedReferences,
                related => Assert.Same(parent, related));
        }
    }

    private static RepositoryTreePayloadEntry Entry(
        string path,
        RepositoryEntryKind kind) =>
        RepositoryTreePayloadEntry.Create(path, kind);

    private static SemanticResourceAllowance Allowance(
        SemanticResourceBudget budget) =>
        SemanticResourceAllowance.Create(
            budget, SemanticResourceUsage.Create(0, 0, 0, 0));

    private sealed record EvaluationCase(
        EvaluationIntent Intent,
        IRepositoryTree Tree,
        ExpectedReferences References,
        bool ExactReferences,
        bool CancellationClosed);

    private sealed record DecisionCase(
        EvaluationIntent Intent,
        IProtocolRecordIndex Index,
        ExpectedReferences References,
        QualifiedEvidenceHandle TreeProof,
        QualifiedEvidenceHandle TextProof,
        bool ExactReferences,
        bool CancellationClosed);

    private sealed record ReferenceCase(
        EvaluationIntent Intent,
        GovernedReferenceView Reference,
        QualifiedEvidenceHandle Context,
        QualifiedEvidenceHandle? TargetEvidence,
        bool ExactReferences,
        bool CancellationClosed);

    private sealed record IndexedTree(
        IRepositoryTree Tree,
        CapabilityHandle<IRepositoryTree> Handle);

    private sealed record IndexedRecords(
        IProtocolRecordIndex Index,
        CapabilityHandle<IProtocolRecordIndex> Handle);

    private sealed record IndexedReferences(
        IGovernedReferenceIndex Index,
        CapabilityHandle<IGovernedReferenceIndex> Handle);

    private sealed class ReferenceIndexFixture(
        IEnumerable<GovernedReferenceView> references) : IGovernedReferenceIndex
    {
        public IReadOnlyList<GovernedReferenceView> References { get; } =
            Array.AsReadOnly(references.ToArray());
    }

    private sealed class TargetIndexFixture(
        IEnumerable<RepositoryTargetResolutionView> targets) :
        IRepositoryTargetResolutionIndex
    {
        public IReadOnlyList<RepositoryTargetResolutionView> Targets { get; } =
            Array.AsReadOnly(targets.ToArray());
    }

    private sealed class GovernedIndexVisitor(
        IReadOnlyList<ISealedModelHandle> models) :
        IIndexRegistrationVisitor<IndexedReferences>
    {
        public IndexedReferences Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            var input = ContextIndexInput<TInput>.Create(
                registration.Binder.Bind(TypedInputReader.Create(
                    models, [],
                    new Dictionary<string, QualifiedEvidenceHandle>(),
                    ExpectedReferences.Rejecting, [], [])),
                Allowance(registration.Declaration.Budget),
                Derivations.Instance);
            var product = registration.Indexer.Build(input, CancellationToken.None)
                .Accept(CapabilityObserver<TCapability>.Instance);
            var index = Assert.IsAssignableFrom<IGovernedReferenceIndex>(
                product.Value);
            return new IndexedReferences(
                index,
                CapabilityHandle<IGovernedReferenceIndex>.Create(
                    CapabilityTypeToken<IGovernedReferenceIndex>.Create(
                        registration.Declaration.OutputCapability),
                    index,
                    product.Evidence,
                    SemanticResourceUsage.Create(0, 0, 0, 0),
                    SemanticResourceLedger.Create([])));
        }
    }

    private sealed class ReferenceProjectionVisitor(
        PolicyQualificationSliceExport export,
        IGovernedReferenceIndex index) :
        IDemandProjectorRegistrationVisitor<
            IReadOnlyList<RepositoryTargetResolutionDemandCandidate>>
    {
        public IReadOnlyList<RepositoryTargetResolutionDemandCandidate>
            Visit<TCapability>(DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability
        {
            var typed = Assert.IsAssignableFrom<TCapability>(index);
            var authority = SourceReferenceResolutionAuthority.Create(
                index.References[0].Reference,
                QualifiedEvidenceHandle.Create(),
                Owner,
                ObjectIdentity,
                null,
                null,
                null,
                null);
            var slot = export.Catalog.Rules.Single(item =>
                    item.RuleId.Value == Rule3).EvaluationSlots.Single(item =>
                    item.SlotKey == TargetSlot);
            var input = DemandProjectionInput<TCapability>.Create(
                slot,
                ContractSliceDProducerInfrastructureFixture.RepositoryScope().Target,
                [typed],
                [0],
                [authority],
                [0],
                Allowance(registration.Declaration.Budget));
            return registration.Projector.Project(input, CancellationToken.None)
                .Accept(ProjectionObserver.Instance).Candidates;
        }
    }

    private sealed class ProjectionObserver :
        IDemandProjectionIntentVisitor<DemandProjectionProduct>
    {
        internal static ProjectionObserver Instance { get; } = new();

        public DemandProjectionProduct VisitProjected(
            DemandProjectionProduct product) => product;

        public DemandProjectionProduct VisitFailed(
            SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }

    private sealed class TextCodecVisitor(
        PolicyQualificationSliceExport export,
        string path,
        string text) : ICodecRegistrationVisitor<ISealedModelHandle>
    {
        public ISealedModelHandle Visit<TModel>(
            CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            Assert.Equal("protocol.governed-text", registration.Declaration.SchemaKey);
            var scope = ContractSliceDProducerInfrastructureFixture.RepositoryScope();
            var location = RepositoryEvidenceLocation.Create(
                scope, path, ObjectIdentity, null, null, null);
            var source = CanonicalPayloadWriteSource.GovernedText(
                    scope,
                    location,
                    Digest,
                    Digest,
                    Encoding.UTF8.GetBytes(text))
                .Accept(SourceObserver.Instance);
            var slot = export.Catalog.Rules
                .Single(item => item.RuleId.Value == Rule2)
                .EvaluationSlots.Single(item => item.SlotKey == TextSlot);
            var write = CanonicalPayloadWriteInput.Create(
                slot,
                scope.Target,
                source,
                registration.Declaration.Budget,
                Digest,
                Digest,
                []);
            var payload = registration.Codec.Write(write, CancellationToken.None)
                .Accept(WriteObserver.Instance);
            var qualification = CodecQualificationInput.Create(
                EvidenceBinding.Create(
                    payload,
                    location,
                    [slot.Requirement.Key],
                    new DateTimeOffset(0, TimeSpan.Zero)),
                Allowance(registration.Declaration.Budget),
                Digest,
                Digest,
                []);
            var model = registration.Codec.Qualify(
                    qualification, CancellationToken.None)
                .Accept(QualificationObserver<TModel>.Instance);
            return SealedModelHandle<TModel>.Create(
                model.ModelType,
                QualifiedEvidenceHandle.Create(),
                model.Value,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([]));
        }
    }

    private sealed class MarkdownParserVisitor(ISealedModelHandle source) :
        IParserRegistrationVisitor<ISealedModelHandle>
    {
        public ISealedModelHandle Visit<TInput, TOutput>(
            ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel
        {
            var bound = registration.Binder.Bind(TypedInputReader.Create(
                [source],
                [],
                new Dictionary<string, QualifiedEvidenceHandle>(),
                ExpectedReferences.Rejecting,
                [],
                []));
            var input = SemanticModelInput<TInput>.Create(
                bound,
                Allowance(registration.Declaration.Budget));
            var product = registration.Parser.Parse(input, CancellationToken.None)
                .Accept(ModelObserver<TOutput>.Instance);
            return SealedModelHandle<TOutput>.Create(
                registration.OutputModel,
                QualifiedEvidenceHandle.Create(),
                product.Value,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([]));
        }
    }

    private sealed class RecordIndexVisitor(IReadOnlyList<ISealedModelHandle> models) :
        IIndexRegistrationVisitor<IndexedRecords>
    {
        public IndexedRecords Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            var bound = registration.Binder.Bind(TypedInputReader.Create(
                models,
                [],
                new Dictionary<string, QualifiedEvidenceHandle>(),
                ExpectedReferences.Rejecting,
                [],
                []));
            var input = ContextIndexInput<TInput>.Create(
                bound,
                Allowance(registration.Declaration.Budget),
                Derivations.Instance);
            var product = registration.Indexer.Build(input, CancellationToken.None)
                .Accept(CapabilityObserver<TCapability>.Instance);
            var index = Assert.IsAssignableFrom<IProtocolRecordIndex>(product.Value);
            return new IndexedRecords(
                index,
                CapabilityHandle<IProtocolRecordIndex>.Create(
                    CapabilityTypeToken<IProtocolRecordIndex>.Create(
                        registration.Declaration.OutputCapability),
                    index,
                    product.Evidence,
                    SemanticResourceUsage.Create(0, 0, 0, 0),
                    SemanticResourceLedger.Create([])));
        }
    }

    private sealed class TreeCodecVisitor(
        PolicyQualificationSliceExport export,
        IReadOnlyList<RepositoryTreePayloadEntry> entries) :
        ICodecRegistrationVisitor<ISealedModelHandle>
    {
        public ISealedModelHandle Visit<TModel>(
            CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            Assert.Equal("protocol.repository-tree",
                registration.Declaration.SchemaKey);
            var scope = ContractSliceDProducerInfrastructureFixture.RepositoryScope();
            var location = SnapshotEvidenceLocation.Create(scope);
            var callerEntries = entries.ToList();
            var source = CanonicalPayloadWriteSource.RepositoryTree(
                    scope, location, Digest, Digest, callerEntries)
                .Accept(SourceObserver.Instance);
            callerEntries.Clear();
            var slot = export.Catalog.Rules
                .Single(item => item.RuleId.Value == Rule1)
                .EvaluationSlots.Single();
            var write = CanonicalPayloadWriteInput.Create(
                slot,
                scope.Target,
                source,
                registration.Declaration.Budget,
                Digest,
                Digest,
                []);
            var payload = registration.Codec.Write(
                    write, CancellationToken.None)
                .Accept(WriteObserver.Instance);
            var qualification = CodecQualificationInput.Create(
                EvidenceBinding.Create(
                    payload,
                    location,
                    [slot.Requirement.Key],
                    new DateTimeOffset(0, TimeSpan.Zero)),
                Allowance(registration.Declaration.Budget),
                Digest,
                Digest,
                []);
            var model = registration.Codec.Qualify(
                    qualification, CancellationToken.None)
                .Accept(QualificationObserver<TModel>.Instance);
            return SealedModelHandle<TModel>.Create(
                model.ModelType,
                QualifiedEvidenceHandle.Create(),
                model.Value,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([]));
        }
    }

    private sealed class TreeIndexVisitor(ISealedModelHandle model) :
        IIndexRegistrationVisitor<IndexedTree>
    {
        public IndexedTree Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            Assert.Equal("protocol.index.repository-tree",
                registration.Declaration.IndexKey);
            var input = ContextIndexInput<TInput>.Create(
                registration.Binder.Bind(TypedInputReader.Create(
                    [model],
                    [],
                    new Dictionary<string, QualifiedEvidenceHandle>(),
                    ExpectedReferences.Rejecting,
                    [],
                    [])),
                Allowance(registration.Declaration.Budget),
                Derivations.Instance);
            var product = registration.Indexer.Build(
                    input, CancellationToken.None)
                .Accept(CapabilityObserver<TCapability>.Instance);
            var tree = Assert.IsAssignableFrom<IRepositoryTree>(product.Value);
            return new IndexedTree(
                tree,
                CapabilityHandle<IRepositoryTree>.Create(
                    CapabilityTypeToken<IRepositoryTree>.Create(
                        registration.Declaration.OutputCapability),
                    tree,
                    product.Evidence,
                    SemanticResourceUsage.Create(0, 0, 0, 0),
                    SemanticResourceLedger.Create([])));
        }
    }

    private sealed class ExpectedReferences : IExpectedReferenceLookup
    {
        private readonly List<ReferenceEntry> _entries = [];
        internal static IExpectedReferenceLookup Rejecting { get; } =
            new RejectingReferences();

        public QualifiedEvidenceHandle Require(
            string selectorKey,
            QualifiedEvidenceHandle parent)
        {
            var existing = _entries.SingleOrDefault(item =>
                item.SelectorKey == selectorKey &&
                ReferenceEquals(item.Parent, parent));
            if (existing is not null)
            {
                return existing.Handle;
            }

            var created = new ReferenceEntry(
                selectorKey,
                parent,
                QualifiedEvidenceHandle.Create());
            _entries.Add(created);
            return created.Handle;
        }

        private sealed record ReferenceEntry(
            string SelectorKey,
            QualifiedEvidenceHandle Parent,
            QualifiedEvidenceHandle Handle);

        private sealed class RejectingReferences : IExpectedReferenceLookup
        {
            public QualifiedEvidenceHandle Require(
                string selectorKey,
                QualifiedEvidenceHandle parent) =>
                throw new InvalidOperationException(
                    "No expected reference is available during indexing.");
        }
    }

    private sealed class Derivations : IQualifiedEvidenceDerivationFactory
    {
        internal static Derivations Instance { get; } = new();

        public QualifiedEvidenceHandle Derive(
            QualifiedEvidenceHandle parent,
            string typedNodeKind,
            string typedNodeIdentity,
            EvidenceLocation location) =>
            QualifiedEvidenceHandle.Create();
    }

    private sealed class SourceObserver :
        ICanonicalPayloadWriteSourceIntentVisitor<CanonicalPayloadWriteSource>
    {
        internal static SourceObserver Instance { get; } = new();

        public CanonicalPayloadWriteSource VisitCreated(
            CanonicalPayloadWriteSource source) => source;

        public CanonicalPayloadWriteSource VisitRejected(
            string schemaKey,
            string schemaVersion,
            EvidenceScope scope,
            EvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            string codecFailureCode) =>
            throw new InvalidOperationException(codecFailureCode);
    }

    private sealed class WriteObserver :
        ICanonicalPayloadWriteIntentVisitor<CanonicalEvidencePayload>
    {
        internal static WriteObserver Instance { get; } = new();

        public CanonicalEvidencePayload VisitWritten(
            CanonicalPayloadWriteProduct product) => product.Payload;

        public CanonicalEvidencePayload VisitRejected(
            IReadOnlyList<AcquisitionFailure> failures) =>
            throw new InvalidOperationException(failures[0].Code);
    }

    private sealed class QualificationObserver<TModel> :
        ICodecQualificationIntentVisitor<TModel, CodecModelHandle<TModel>>
        where TModel : class, IProtocolSemanticModel
    {
        internal static QualificationObserver<TModel> Instance { get; } = new();

        public CodecModelHandle<TModel> VisitQualified(
            CodecModelHandle<TModel> model) => model;

        public CodecModelHandle<TModel> VisitRejected(
            IReadOnlyList<AcquisitionFailure> failures) =>
            throw new InvalidOperationException(failures[0].Code);
    }

    private sealed class CapabilityObserver<TCapability> :
        ICapabilityIntentVisitor<TCapability, CapabilityProduct<TCapability>>
        where TCapability : class, IEvidenceCapability
    {
        internal static CapabilityObserver<TCapability> Instance { get; } = new();

        public CapabilityProduct<TCapability> VisitProduced(
            CapabilityProduct<TCapability> product) => product;

        public CapabilityProduct<TCapability> VisitFailed(
            SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }

    private sealed class ModelObserver<TModel> :
        ISemanticModelIntentVisitor<TModel, SemanticModelProduct<TModel>>
        where TModel : class, IProtocolSemanticModel
    {
        internal static ModelObserver<TModel> Instance { get; } = new();

        public SemanticModelProduct<TModel> VisitProduced(
            SemanticModelProduct<TModel> product) => product;

        public SemanticModelProduct<TModel> VisitFailed(
            SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }
}
