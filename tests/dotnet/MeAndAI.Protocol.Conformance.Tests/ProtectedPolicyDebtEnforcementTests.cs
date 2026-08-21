using System.Security.Cryptography;
using System.Runtime.CompilerServices;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy.Models;
using MeAndAI.Protocol.Policy.ProtectedPolicy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicyDebtEnforcementTests
{
    [Fact]
    [Trait("Scenario", "TEST-0211")]
    public void Applies_exact_debt_and_enforcement_precedence()
    {
        var fixture = ProjectNeutralProtectedAuthorityFixture.CreateCanonicalEmpty();
        var declaration = fixture.Kernel.Catalog.Rules.First();
        var waiverPolicy = BaselineWaiverPolicy(
            fixture.Kernel.Catalog,
            fixture.Manifest.ManifestDigest,
            declaration);
        var pack = PackBinding(fixture.Manifest, fixture.Policy, waiverPolicy);
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            pack,
            ProjectNeutralProtectedAuthorityFixture.CreatePackProof(
                pack,
                fixture.ActivationPayload),
            fixture.Policy);
        var findingDeclaration = declaration.Findings.First();
        var finding = new RuleFinding(
            declaration.RuleId,
            declaration.RuleRevision,
            findingDeclaration.Code,
            findingDeclaration.Severity,
            findingDeclaration.Remediation,
            Reference(fixture, findingDeclaration.AllowedPrimaryReferenceKinds.First()),
            []);
        var protectedFinding = fixture.Kernel.ProtectFinding(finding, declaration);
        var evaluationUtc = new DateTimeOffset(2026, 8, 20, 13, 0, 0, TimeSpan.Zero);
        var debt = HistoricalDebtEntry.Create(
            protectedFinding.Identity,
            fixture.Kernel.Catalog.ProtocolVersion,
            "protocol-maintainer",
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('0', 40)}"),
            "Review when the protected evidence changes.",
            protectedFinding.Identity.EvidenceDigest,
            Digest("recurrence-record"),
            null,
            evaluationUtc.AddHours(1),
            fixture.Manifest.ManifestDigest);
        var historicalDebt = DebtSnapshot(debt);
        var waivers = WaiverSnapshotOf();
        var evidenceSetDigest = Digest("debt-evidence-set");
        ProtectedDispositionAuthorityPayload Payload(
            ExactSha256Digest waiverDigest,
            ExactSha256Digest debtDigest,
            ExactSha256Digest evidenceDigest) =>
            ProtectedDispositionAuthorityPayload.Create(
                fixture.Manifest.ManifestDigest,
                fixture.Manifest.ManifestDigest,
                active.AuthoritySetDigest,
                waiverDigest,
                debtDigest,
                evidenceDigest,
                active.ActivationRecordDigest,
                active.ActivationEpoch,
                evaluationUtc);
        void AssertAuthorityCode(
            ProtectedDispositionAuthorityPayload invalid,
            ProtectedPolicyIntegrityCode code) => AssertPolicyCode(
            () => fixture.Kernel.ApplyWaivers(
                active,
                waivers,
                historicalDebt,
                invalid,
                ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                    invalid),
                evidenceSetDigest,
                [protectedFinding]),
            code);
        var payload = Payload(
            waivers.SnapshotDigest,
            historicalDebt.SnapshotDigest,
            evidenceSetDigest);
        var waiverOutcome = fixture.Kernel.ApplyWaivers(
            active,
            waivers,
            historicalDebt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(payload),
            evidenceSetDigest,
            [protectedFinding]);
        Assert.Equal(
            FindingDisposition.ActiveViolation,
            Assert.Single(waiverOutcome.Results).Disposition);
        DebtEnforcementOutcome ApplyDebt(
            HistoricalDebtSnapshot snapshot,
            EnforcementPhase phase,
            DateTimeOffset? instant = null,
            string? protocolVersion = null) =>
            fixture.Kernel.ApplyDebtAndEnforcement(
                waiverOutcome,
                snapshot,
                protocolVersion ?? fixture.Kernel.Catalog.ProtocolVersion,
                instant ?? evaluationUtc,
                ConformanceVerdict.NonConforming,
                phase);
        void AssertDebtCase(
            HistoricalDebtSnapshot snapshot,
            FindingDisposition disposition,
            EnforcementDecision enforcement,
            EnforcementPhase phase,
            DateTimeOffset? instant = null,
            string? protocolVersion = null) => AssertEnforcement(
                ApplyDebt(snapshot, phase, instant, protocolVersion),
                disposition,
                enforcement);
        AssertAuthorityCode(
            Payload(
                waivers.SnapshotDigest,
                historicalDebt.SnapshotDigest,
                Digest("other-evidence-set")),
            ProtectedPolicyIntegrityCode.DispositionAuthorityInvalid);
        AssertAuthorityCode(
            Payload(
                Digest("other-waiver-snapshot"),
                historicalDebt.SnapshotDigest,
                evidenceSetDigest),
            ProtectedPolicyIntegrityCode.WaiverInvalid);
        AssertAuthorityCode(
            Payload(
                waivers.SnapshotDigest,
                Digest("other-debt-snapshot"),
                evidenceSetDigest),
            ProtectedPolicyIntegrityCode.DebtInvalid);

        var result = ApplyDebt(historicalDebt, EnforcementPhase.Prospective);
        Assert.Equal(
            FindingDisposition.HistoricalDebt,
            Assert.Single(result.Dispositions).Disposition);
        Assert.Equal(EnforcementDecision.Allow, result.Enforcement);
        var noDebt = DebtSnapshot();
        AssertDebtCase(
            noDebt,
            FindingDisposition.ActiveViolation,
            EnforcementDecision.ReportOnly,
            EnforcementPhase.Audit);
        AssertDebtCase(
            noDebt,
            FindingDisposition.ActiveViolation,
            EnforcementDecision.Block,
            EnforcementPhase.Prospective);
        var conforming = fixture.Kernel.ApplyDebtAndEnforcement(
            new WaiverDispositionOutcome(waiverOutcome.Authority, []),
            noDebt,
            fixture.Kernel.Catalog.ProtocolVersion,
            evaluationUtc,
            ConformanceVerdict.Conforming,
            EnforcementPhase.FullBlocking);
        Assert.Empty(conforming.Dispositions);
        Assert.Equal(EnforcementDecision.Allow, conforming.Enforcement);
        var closedDebt = HistoricalDebtEntry.Create(
            debt.Finding,
            debt.ProtocolVersion,
            debt.AccountableOwner,
            debt.Authority,
            debt.ReviewCondition,
            debt.StableEvidenceDigest,
            debt.RecurrenceRecordDigest,
            evaluationUtc.AddMinutes(-1),
            null,
            debt.TrustedBaseAuthorityDigest);
        AssertDebtCase(
            DebtSnapshot(closedDebt),
            FindingDisposition.ActiveViolation,
            EnforcementDecision.Block,
            EnforcementPhase.Prospective);
        AssertDebtCase(
            historicalDebt,
            FindingDisposition.HistoricalDebt,
            EnforcementDecision.Block,
            EnforcementPhase.FullBlocking);
        AssertDebtCase(
            historicalDebt,
            FindingDisposition.ActiveViolation,
            EnforcementDecision.Block,
            EnforcementPhase.Prospective,
            evaluationUtc.AddHours(2));
        AssertDebtCase(
            historicalDebt,
            FindingDisposition.ActiveViolation,
            EnforcementDecision.Block,
            EnforcementPhase.Prospective,
            protocolVersion: "different-protocol-version");
        var waiver = WaiverDeclaration.Create(
            protectedFinding.Identity,
            WaiverTargetSelector.Parse(
                $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}"),
            WaiverScope.Parse("finding"),
            "Project-neutral waiver precedence fixture.",
            "protocol-maintainer",
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('0', 40)}"),
            fixture.Manifest.ManifestDigest,
            evaluationUtc.AddMinutes(-1),
            evaluationUtc.AddMinutes(1),
            protectedFinding.Identity.EvidenceDigest);
        var waiverSnapshot = WaiverSnapshotOf(waiver);
        var waiverPayload = Payload(
            waiverSnapshot.SnapshotDigest,
            historicalDebt.SnapshotDigest,
            evidenceSetDigest);
        var waived = fixture.Kernel.ApplyWaivers(
            active,
            waiverSnapshot,
            historicalDebt,
            waiverPayload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                waiverPayload),
            evidenceSetDigest,
            [protectedFinding]);
        var waivedEnforcement = fixture.Kernel.ApplyDebtAndEnforcement(
                waived,
                historicalDebt,
                fixture.Kernel.Catalog.ProtocolVersion,
                evaluationUtc,
                ConformanceVerdict.NonConforming,
                EnforcementPhase.FullBlocking);
        AssertEnforcement(
            waivedEnforcement,
            FindingDisposition.Waived,
            EnforcementDecision.Allow);
        var waivedResult = Assert.Single(waivedEnforcement.Dispositions);
        Assert.Same(waiver, waivedResult.Waiver);
        Assert.Null(waivedResult.Debt);
        Assert.Equal(ConformanceVerdict.NonConforming, waivedEnforcement.Verdict);
        AssertPublicProtectedEvaluation();
        AssertNullCarrierRoute(
            EnforcementPhase.Audit,
            EnforcementDecision.ReportOnly);
        AssertNullCarrierRoute(
            EnforcementPhase.Prospective,
            EnforcementDecision.Block);
        AssertCanonicalFrames(fixture, declaration, findingDeclaration);
    }

    private static void AssertEnforcement(
        DebtEnforcementOutcome outcome,
        FindingDisposition disposition,
        EnforcementDecision enforcement)
    {
        Assert.Equal(disposition, Assert.Single(outcome.Dispositions).Disposition);
        Assert.Equal(enforcement, outcome.Enforcement);
    }

    private static void AssertPolicyCode(
        Action action,
        ProtectedPolicyIntegrityCode code)
    {
        var error = Assert.Throws<ProtectedPolicyIntegrityException>(action);
        Assert.Equal(code, error.Code);
    }

    private static (
        ExtensionEvaluatorRegistration Registration,
        ExtensionRuleDeclaration Declaration,
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture Fixture,
        ActivatedExtensionPolicy Active) ActivatedEvaluationFixture()
    {
        var registration = RepositoryPathRequiredExtensionEvaluator.CreateRegistration();
        var declaration = ExtensionDeclaration();
        var fixture = CreateEvaluationAuthorityFixture(registration, declaration);
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        return (registration, declaration, fixture, active);
    }

    private static void AssertPublicProtectedEvaluation()
    {
        var (registration, declaration, fixture, active) =
            ActivatedEvaluationFixture();
        var (profile, source) = IssueClosure(
            fixture,
            EnforcementPhase.Audit);

        AssertCarrierSource(source);
        var repositoryTree = new RepositoryTreeCapability([]);
        var replacements = new EvaluationClosure?[2];
        var replacementErrors = new Exception?[2];
        Parallel.For(0, 2, index =>
        {
            try
            {
                replacements[index] = source.WithProtectedInput(repositoryTree);
            }
            catch (Exception error)
            {
                replacementErrors[index] = error;
            }
        });
        var replacement = Assert.Single(
            replacements,
            static value => value is not null)!;
        var replacementError = Assert.IsType<CatalogIntegrityException>(
            Assert.Single(replacementErrors, static value => value is not null));
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, replacementError.Code);
        Assert.NotSame(source, replacement);
        Assert.Same(source.Applicability, replacement.Applicability);
        Assert.Same(source.Context, replacement.Context);
        Assert.Equal(source.CompletedRoundCount, replacement.CompletedRoundCount);
        Assert.Equal(source.Acquisitions, replacement.Acquisitions);
        Assert.Equal(source.TerminalEvaluations, replacement.TerminalEvaluations);
        AssertInvalid(() => fixture.Kernel.Evaluate(source));
        Assert.Throws<ArgumentNullException>(() =>
            replacement.WithProtectedInput(null!));
        AssertInvalid(() => replacement.WithProtectedInput(
            new RepositoryTreeCapability([])));

        Assert.Throws<OperationCanceledException>(() => fixture.Kernel.Evaluate(
            replacement,
            new CancellationToken(canceled: true)));
        var baseline = fixture.Kernel.Evaluate(replacement);
        Assert.Same(replacement, baseline.Closure);
        var reference = Assert.Single(
            replacement.ProtectedInput!.References.Values);
        var findingDeclaration = Assert.Single(
            registration.Declaration.Findings);
        var expectedFinding = new ExtensionFinding(
            declaration.ExtensionId,
            declaration.Revision,
            findingDeclaration.Code,
            findingDeclaration.Severity,
            findingDeclaration.Remediation,
            reference,
            [],
            "missing",
            null);
        var expectedEvaluation = new ExtensionEvaluation(
            declaration.ExtensionId,
            declaration.Revision,
            RuleEvaluationStatus.Violated,
            false,
            [],
            [],
            [expectedFinding],
            []);
        var expectedProtected = fixture.Kernel.ProtectFinding(
            expectedFinding,
            declaration,
            registration.Declaration);
        var evidenceSetDigest = DebtEnforcementCore.ComputeEvidenceSetDigest(
            baseline,
            replacement,
            active,
            [expectedEvaluation]);
        var evaluationUtc = new DateTimeOffset(2026, 8, 20, 14, 0, 0, TimeSpan.Zero);
        var debt = HistoricalDebtEntry.Create(
            expectedProtected.Identity,
            fixture.Kernel.Catalog.ProtocolVersion,
            "protocol-maintainer",
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('0', 40)}"),
            "Review when the protected evidence changes.",
            expectedProtected.Identity.EvidenceDigest,
            Digest("public-recurrence-record"),
            null,
            evaluationUtc.AddHours(1),
            fixture.Manifest.ManifestDigest);
        var historicalDebt = DebtSnapshot(debt);
        var waivers = WaiverSnapshotOf();
        var payload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            waivers.SnapshotDigest,
            historicalDebt.SnapshotDigest,
            evidenceSetDigest,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            evaluationUtc);
        var result = fixture.Kernel.EvaluateProtected(
            baseline,
            replacement,
            active,
            null,
            waivers,
            historicalDebt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                payload),
            baseline.Profile.Axes.EnforcementPhase);
        var extension = Assert.Single(result.ExtensionEvaluations);
        Assert.Equal(RuleEvaluationStatus.Violated, extension.Status);
        Assert.Equal("missing", Assert.Single(extension.Findings).StableStateToken);
        var disposition = Assert.Single(result.Dispositions);
        Assert.Equal(FindingDisposition.HistoricalDebt, disposition.Disposition);
        Assert.Same(debt, disposition.Debt);
        Assert.Equal(ConformanceVerdict.Indeterminate, result.Verdict);
        Assert.Equal(EnforcementDecision.ReportOnly, result.Enforcement);
        Assert.Equal(evidenceSetDigest, result.EvidenceSetDigest);
        Assert.Same(payload, result.DispositionAuthority.Payload);
        Assert.Equal(
            active.PolicyPackBinding.BindingDigest,
            result.RuntimeBinding.PolicyPackBindingDigest);
        var phaseError = Assert.Throws<ProtectedPolicyIntegrityException>(() =>
            fixture.Kernel.EvaluateProtected(
                baseline,
                replacement,
                active,
                null,
                waivers,
                historicalDebt,
                payload,
                ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                    payload),
                EnforcementPhase.Prospective));
        Assert.Equal(
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch,
            phaseError.Code);
        var foreignFixture = CreateEvaluationAuthorityFixture(
            registration,
            declaration);
        var (_, foreignClosure) = IssueClosure(
            foreignFixture,
            EnforcementPhase.Audit);
        AssertPolicyCode(
            () => fixture.Kernel.EvaluateProtected(
                baseline,
                foreignClosure,
                active,
                null,
                waivers,
                historicalDebt,
                payload,
                ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                    payload),
                EnforcementPhase.Audit),
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch);
        AssertInvalid(() => fixture.Kernel.Evaluate(replacement));
    }

    private static void AssertNullCarrierRoute(
        EnforcementPhase phase,
        EnforcementDecision expectedEnforcement)
    {
        var (_, declaration, fixture, active) = ActivatedEvaluationFixture();
        var (_, closure) = IssueClosure(fixture, phase);
        Assert.Null(closure.ProtectedInput);
        var baseline = fixture.Kernel.Evaluate(closure);
        var expectedExtension = new ExtensionEvaluation(
            declaration.ExtensionId,
            declaration.Revision,
            RuleEvaluationStatus.NotEvaluated,
            isApplicabilityUnresolved: false,
            [],
            ["protocol.slot.repository-tree"],
            [],
            []);
        var evidenceSetDigest = DebtEnforcementCore.ComputeEvidenceSetDigest(
            baseline,
            closure,
            active,
            [expectedExtension]);
        var waivers = WaiverSnapshotOf();
        var historicalDebt = DebtSnapshot();
        var payload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            waivers.SnapshotDigest,
            historicalDebt.SnapshotDigest,
            evidenceSetDigest,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            new DateTimeOffset(2026, 8, 20, 15, 0, 0, TimeSpan.Zero));
        var result = fixture.Kernel.EvaluateProtected(
            baseline,
            closure,
            active,
            null,
            waivers,
            historicalDebt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                payload),
            phase);
        var extension = Assert.Single(result.ExtensionEvaluations);
        Assert.Equal(RuleEvaluationStatus.NotEvaluated, extension.Status);
        Assert.False(extension.IsApplicabilityUnresolved);
        Assert.Equal(
            ["protocol.slot.repository-tree"],
            extension.UnresolvedSlotKeys);
        Assert.Empty(extension.Findings);
        Assert.Empty(result.Dispositions);
        Assert.Equal(ConformanceVerdict.Indeterminate, result.Verdict);
        Assert.Equal(expectedEnforcement, result.Enforcement);
    }

    private static void AssertCanonicalFrames(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        RuleDeclaration declaration,
        FindingDeclaration findingDeclaration)
    {
        var identity = new string('0', 40);
        var scope = EvidenceScope.Create(
            AcquisitionTarget.Create(
                "subject",
                "source",
                SurfaceKind.Repository,
                SnapshotKind.ExactCommit,
                identity),
            AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit,
                identity,
                new DateTimeOffset(0, TimeSpan.Zero),
                new DateTimeOffset(1, TimeSpan.Zero)));
        var reference = new QualifiedEvidenceReference(
            QualifiedEvidenceReferenceKind.ContextProof,
            ExactSha256Digest.Parse(new string('1', 64)),
            CatalogVersion.Create(1),
            "slot",
            "requirement",
            scope,
            ExactSha256Digest.Parse(new string('2', 64)),
            null,
            null,
            [],
            null,
            null);
        var scopeFrame = WaiverDispositionCore.ScopeFrame(scope);
        Assert.Equal(207, scopeFrame.Length);
        Assert.Equal(
            "FB1C8D577BD29102273DD0DF24C3065271DC540739FBB9F7FC05B9DC1C633167",
            Convert.ToHexString(SHA256.HashData(scopeFrame)));
        var referenceFrame = WaiverDispositionCore.ReferenceFrame(reference);
        Assert.Equal(327, referenceFrame.Length);
        Assert.Equal(
            "F58FF97C79B7EEE2E3F96AD55290B759E0805C76728032CA77E436ED806B2277",
            Convert.ToHexString(SHA256.HashData(referenceFrame)));
        var laterScope = EvidenceScope.Create(
            scope.Target,
            AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit,
                identity,
                new DateTimeOffset(0, TimeSpan.Zero),
                new DateTimeOffset(2, TimeSpan.Zero)));
        var later = new QualifiedEvidenceReference(
            reference.Kind,
            reference.ManifestDigest,
            reference.CatalogVersion,
            reference.SlotKey,
            reference.RequirementKey,
            laterScope,
            reference.QualificationProofDigest,
            null,
            null,
            [],
            null,
            null);
        Assert.NotEqual(
            WaiverDispositionCore.ReferenceDigest(reference),
            WaiverDispositionCore.ReferenceDigest(later));
        Assert.Equal(
            WaiverDispositionCore.StableScope(reference.Scope),
            WaiverDispositionCore.StableScope(later.Scope));
        Assert.Equal(
            "00884E9BEE5DC73A3399711573094D431CF1124234C169DB83A48E7880913586",
            EvidenceSetFrame(
                null,
                ExactSha256Digest.Parse(new string('1', 64)),
                ExactSha256Digest.Parse(new string('2', 64)),
                ExactSha256Digest.Parse(new string('3', 64)),
                0,
                "complete-protocol-snapshot",
                1,
                [],
                [],
                [],
                []).Value.ToUpperInvariant());
        var mixedOutcomes = new[]
        {
                KeyValuePair.Create(
                    "rule:baseline:protocol.rule.id:1",
                    ExactSha256Digest.Parse(new string('1', 64))),
                KeyValuePair.Create(
                    "global:dispositions",
                    ExactSha256Digest.Parse(new string('2', 64))),
                KeyValuePair.Create(
                    "global:verdict",
                    ExactSha256Digest.Parse(new string('3', 64))),
                KeyValuePair.Create(
                    "global:enforcement",
                    ExactSha256Digest.Parse(new string('4', 64))),
        };
        Assert.Equal(
            "594FBB75E2517B89ABA750F7376DDBADFFE6888FD6C94655723F87C19F5A93D0",
            OutcomeSetFrame(null, mixedOutcomes).Value.ToUpperInvariant());
        AssertPolicyCode(
            () => OutcomeSetFrame(null, mixedOutcomes.Reverse().ToArray()),
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch);
        AssertPolicyCode(
            () => OutcomeSetFrame(null, [mixedOutcomes[0], .. mixedOutcomes]),
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch);
        object Constant(string name) => typeof(DebtEnforcementCore)
            .GetField(name, System.Reflection.BindingFlags.NonPublic |
                System.Reflection.BindingFlags.Static)!.GetRawConstantValue()!;
        Assert.Equal(4_096, Constant("MaximumSlots"));
        Assert.Equal(65_536, Constant("MaximumScopes"));
        Assert.Equal(200_000, Constant("MaximumOutcomes"));
        Assert.Equal(1_000_000, Constant("MaximumReferences"));
        Assert.Equal(67_108_864L, Constant("MaximumCanonicalSetBytes"));
        var globals = new[] { "global:dispositions", "global:verdict", "global:enforcement" };
        IEnumerable<string> OutcomeKeys(int rules) => Enumerable.Range(0, rules)
            .Select(static value => $"rule:baseline:r{value:D6}:1").Concat(globals);
        ValidateOutcomeSetBounds(null, OutcomeKeys(199_997));
        AssertPolicyCode(
            () => ValidateOutcomeSetBounds(null, OutcomeKeys(199_998)),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        var boundaryKey = "rule:" + new string('a', 67_108_627);
        ValidateOutcomeSetBounds(null, [boundaryKey, .. globals]);
        AssertPolicyCode(
            () => ValidateOutcomeSetBounds(null, [boundaryKey + "a", .. globals]),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        Assert.Single(DebtEnforcementCore.OrderedUnique(
            ["a"], static value => value, 1));
        AssertPolicyCode(
            () => DebtEnforcementCore.OrderedUnique(
                ["a", "b"], static value => value, 1),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        AssertPolicyCode(
            () => DebtEnforcementCore.OrderedUnique(
                ["a", "a"], static value => value, 2),
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch);
        var collision = ExactSha256Digest.Parse(new string('5', 64));
        Assert.Single(DebtEnforcementCore.CanonicalFrames(
            ["a", "a"], _ => collision,
            static value => Encoding.UTF8.GetBytes(value), 2, true));
        AssertPolicyCode(
            () => DebtEnforcementCore.CanonicalFrames(
                ["a", "a"], _ => collision,
                static value => Encoding.UTF8.GetBytes(value), 2, false),
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch);
        AssertPolicyCode(
            () => DebtEnforcementCore.CanonicalFrames(
                ["a", "b"],
                _ => collision,
                static value => Encoding.UTF8.GetBytes(value),
                2,
                allowIdenticalDuplicates: true),
            ProtectedPolicyIntegrityCode.EvaluationContextMismatch);
        AssertPolicyCode(
            () => DebtEnforcementCore.CanonicalFrames(
                ["a", "b"],
                Digest,
                static value => Encoding.UTF8.GetBytes(value),
                1,
                allowIdenticalDuplicates: true),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        var kind = findingDeclaration.AllowedPrimaryReferenceKinds.First();
        var rich = RichReference(scope, new string('a', 40), kind);
        var laterRich = RichReference(laterScope, new string('a', 40), kind);
        var changedRich = RichReference(scope, new string('b', 40), kind);
        ExactSha256Digest Stable(QualifiedEvidenceReference candidate) =>
            fixture.Kernel.ProtectFinding(new RuleFinding(
                declaration.RuleId,
                declaration.RuleRevision,
                findingDeclaration.Code,
                findingDeclaration.Severity,
                findingDeclaration.Remediation,
                candidate,
                []), declaration).Identity.EvidenceDigest;
        Assert.NotEqual(
            WaiverDispositionCore.ReferenceDigest(rich),
            WaiverDispositionCore.ReferenceDigest(laterRich));
        Assert.Equal(
            Stable(rich),
            Stable(laterRich));
        Assert.NotEqual(
            Stable(rich),
            Stable(changedRich));
        var richFrame = WaiverDispositionCore.ReferenceFrame(rich);
        Assert.True(richFrame.Length == 927);
        Assert.Equal(
            "F920F4DD30E81425A502C23AD7E43775842C7A288DC3F7389ED19A0590A08E1B",
            Convert.ToHexString(SHA256.HashData(richFrame)));
    }

    private static QualifiedEvidenceReference RichReference(
        EvidenceScope scope,
        string blobIdentity,
        QualifiedEvidenceReferenceKind kind)
    {
        var location = RepositoryEvidenceLocation.Create(scope, "AGENTS.md", blobIdentity, 1, null, null);
        var derivation = new QualifiedEvidenceDerivation(ComponentTypeIdentity.Create("protocol.component.test", "1", "Assembly", "Type"), "artifact.dll", Digest("artifact"), null, null, "node", "identity", location);
        return new QualifiedEvidenceReference(kind, ExactSha256Digest.Parse(new string('1', 64)), CatalogVersion.Create(1), "slot", "requirement", scope, ExactSha256Digest.Parse(new string('2', 64)), null, location, [derivation], null, null);
    }

    private static (NamedExecutionProfile Profile, EvaluationClosure Closure)
        IssueClosure(
            ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
            EnforcementPhase phase)
    {
        var audit = fixture.Kernel.ResolveNamedProfile(
            "protocol.profile.consumer-provider-exact-commit-conformance-audit");
        var profile = phase.Equals(EnforcementPhase.Audit)
            ? audit
            : new NamedExecutionProfile(
                $"protocol.profile.protected-debt-{phase.Value}",
                ExecutionProfile.Create(
                    audit.Axes.SubjectRole,
                    audit.Axes.Operation,
                    audit.Axes.SnapshotKind,
                    audit.Axes.Surfaces,
                    phase),
                audit.RuleIds,
                audit.PlanningSession);
        Assert.Equal(
            fixture.Kernel.Catalog.Rules.Select(static rule => rule.RuleId),
            profile.RuleIds);
        var targets = new[]
        {
            SurfaceKind.Repository,
            SurfaceKind.Provider,
        }.Select(surface => AcquisitionTarget.Create(
            "repo",
            surface.Equals(SurfaceKind.Repository) ? "repo" : "github",
            surface,
            SnapshotKind.ExactCommit,
            fixture.Manifest.SourceCommit)).ToArray();
        var plan = fixture.Kernel.PlanApplicability(profile, targets);
        var applicabilityProofs = plan.Instructions.Select(instruction =>
            CObservedQualificationProof.Create(
                fixture.Manifest,
                instruction,
                complete: true)).ToArray();
        ActivationProof(plan.EvidenceSession).Authorize(applicabilityProofs);
        var applicability = fixture.Kernel.CloseApplicability(
            plan,
            AcquisitionProofSet.Create(applicabilityProofs, [], []));
        var evaluationPlan = Assert.IsType<EvaluationPlan>(
            fixture.Kernel.PlanEvaluation(applicability));
        var evaluationProofs = evaluationPlan.Instructions.Select(instruction =>
            CObservedQualificationProof.Create(
                fixture.Manifest,
                instruction,
                complete: true)).ToArray();
        ActivationProof(evaluationPlan.EvidenceSession).Authorize(evaluationProofs);
        return (
            profile,
            Assert.IsType<EvaluationClosure>(fixture.Kernel.AdvanceEvaluation(
                evaluationPlan,
                AcquisitionProofSet.Create(evaluationProofs, [], []))));
    }

    private static ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture
        CreateEvaluationAuthorityFixture(
            ExtensionEvaluatorRegistration registration,
            ExtensionRuleDeclaration declaration)
    {
        var source = ContractSliceCApplicabilityClosureTests.CreateFixture(
            evaluationReady: true,
            evaluationByRule: new Dictionary<string,
                Func<RuleEvaluationInput, EvaluationIntent>>(
                    StringComparer.Ordinal));
        var manifest = AddPolicyArtifact(source.Manifest);
        var kernel = ConformanceKernel.Activate(
            manifest,
            source.Export,
            new ContractSliceCActivationProof(manifest, source.Export),
            predecessor: null);
        var policy = ProjectNeutralProtectedAuthorityFixture.CreateTestPolicy(
            [registration]);
        var policyBlobDigest = Digest("registered-extension-policy-blob");
        var snapshot = ExtensionCatalogSnapshot.Create(
            "repo",
            policyBlobDigest,
            ExtensionCatalogSnapshot.ComputeDigest(
                "repo",
                policyBlobDigest,
                [declaration]),
            [declaration]);
        var authorityRecordDigest = Digest("authority-record");
        var activationPayload = ProtectedExtensionActivationPayload.Create(
            manifest.ManifestDigest,
            "repo",
            policyBlobDigest,
            Digest("authority-set"),
            authorityRecordDigest,
            Digest("previous-activation-record"),
            Digest("closure-evidence"),
            snapshot.SnapshotDigest,
            manifest.SourceCommit,
            activationEpoch: 1);
        var waiverPolicy = BaselineWaiverPolicy(kernel.Catalog, manifest.ManifestDigest);
        var packBinding = PackBinding(
            manifest,
            policy,
            waiverPolicy);
        return new ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture(
            kernel,
            manifest,
            snapshot,
            activationPayload,
            ProjectNeutralProtectedAuthorityFixture.CreateActivationProof(
                activationPayload),
            packBinding,
            ProjectNeutralProtectedAuthorityFixture.CreatePackProof(
                packBinding,
                activationPayload),
            policy,
            authorityRecordDigest);
    }

    private static FinalizedPolicyManifest AddPolicyArtifact(
        FinalizedPolicyManifest source)
    {
        var artifacts = source.ArtifactFiles
            .Append(ArtifactFileBinding.Create(
                "MeAndAI.Protocol.Policy.dll",
                1,
                Digest("policy-artifact")))
            .OrderBy(static row => row.FileName, StringComparer.Ordinal)
            .ToArray();
        return ContractSliceCActivationTests.CreateSyntheticManifest(
            source.AuthorityKind,
            source.SourceCommit,
            Digest("protected-authority-manifest"),
            source.SchemaRegistry,
            source.ActivationProofContract,
            artifacts,
            source.Components,
            source.Slice,
            source.CompleteCatalog);
    }

    private static BaselineWaiverPolicySnapshot BaselineWaiverPolicy(
        CompleteCatalogSnapshot catalog,
        ExactSha256Digest manifestDigest,
        RuleDeclaration? waiverEligible = null)
    {
        var rows = catalog.Rules.Select(rule =>
            BaselineRuleWaiverPolicy.Create(
                rule.RuleId,
                rule.RuleRevision,
                waiverEligible is not null &&
                rule.RuleId.Equals(waiverEligible.RuleId) &&
                rule.RuleRevision.Equals(waiverEligible.RuleRevision))).ToArray();
        var digest = ProtectedPolicyFrame.Hash(
            "protocol.baseline-waiver-policy/1\n",
            stream =>
            {
                ProtectedPolicyFrame.Digest(stream, manifestDigest);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Length));
                foreach (var row in rows)
                {
                    ProtectedPolicyFrame.String(stream, row.RuleId.Value);
                    ProtectedPolicyFrame.UInt32(
                        stream,
                        checked((uint)row.RuleRevision.Value));
                    ProtectedPolicyFrame.Bool(stream, row.WaiverAllowed);
                }
            });
        return BaselineWaiverPolicySnapshot.Create(
            manifestDigest,
            digest,
            rows);
    }

    private static ProtectedPolicyPackBinding PackBinding(
        FinalizedPolicyManifest manifest,
        ExtensionPolicyPackExport policy,
        BaselineWaiverPolicySnapshot waiverPolicy)
    {
        var keysByFile = policy.Components
            .GroupBy(
                component => $"{component.AssemblyName}.dll",
                StringComparer.Ordinal)
            .ToDictionary(
                static group => group.Key,
                static group => group.Select(component => component.ComponentKey)
                    .Order(StringComparer.Ordinal).ToArray(),
                StringComparer.Ordinal);
        var definitions = new[]
        {
            ("protocol.artifact.domain", "MeAndAI.Protocol.Domain.dll"),
            ("protocol.artifact.conformance-abstractions", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
            ("protocol.artifact.conformance-runtime", "MeAndAI.Protocol.Conformance.dll"),
            ("protocol.artifact.policy", "MeAndAI.Protocol.Policy.dll"),
        };
        var artifacts = definitions.Select(definition =>
        {
            var artifact = manifest.ArtifactFiles.Single(row => string.Equals(
                row.FileName,
                definition.Item2,
                StringComparison.Ordinal));
            return ProtectedPolicyArtifactBinding.Create(
                definition.Item1,
                definition.Item2,
                artifact.ByteLength,
                artifact.ArtifactDigest,
                keysByFile.GetValueOrDefault(definition.Item2) ?? []);
        }).ToArray();
        var digest = ProtectedPolicyPackBinding.ComputeDigest(
            manifest.ManifestDigest,
            policy.ExportDigest,
            waiverPolicy.SnapshotDigest,
            artifacts);
        return ProtectedPolicyPackBinding.Create(
            manifest.ManifestDigest,
            policy.ExportDigest,
            waiverPolicy,
            artifacts,
            digest);
    }

    private static void AssertCarrierSource(EvaluationClosure source)
    {
        var outcome = Assert.Single(source.Acquisitions, row =>
            string.Equals(
                row.Slot.SlotKey,
                "protocol.slot.repository-tree",
                StringComparison.Ordinal));
        Assert.Equal(AcquisitionStatus.Complete, outcome.Status);
        Assert.NotNull(outcome.Scope);
        var reference = Assert.IsType<QualifiedEvidenceReference>(
            outcome.ContextProof);
        Assert.Equal(QualifiedEvidenceReferenceKind.ContextProof, reference.Kind);
        Assert.Equal(source.Context.ManifestDigest, reference.ManifestDigest);
        Assert.Equal(source.Context.CatalogVersion, reference.CatalogVersion);
        Assert.Equal(outcome.Slot.SlotKey, reference.SlotKey);
        Assert.Equal(outcome.Slot.Requirement.Key, reference.RequirementKey);
        Assert.Equal(outcome.Scope, reference.Scope);
        Assert.Equal(
            Assert.Single(outcome.Attempts).ReceiptDigest,
            reference.QualificationProofDigest);
        Assert.Equal(
            1,
            source.Context.AdmittedSlotKeys.Count(slotKey => string.Equals(
                slotKey,
                outcome.Slot.SlotKey,
                StringComparison.Ordinal)));
        Assert.Equal(
            1,
            source.Context.Scopes.Count(scope => scope.Equals(reference.Scope)));
    }

    private static ContractSliceCActivationProof ActivationProof(
        IPlanBoundEvidenceSession evidenceSession) =>
        Assert.IsType<ContractSliceCActivationProof>(
            Assert.IsType<KernelPlanningSession>(evidenceSession)
                .ActivationProof);

    private static ExtensionRuleDeclaration ExtensionDeclaration()
    {
        var extensionId = ExtensionId.Parse("ext:repo:required-agents");
        var revision = RuleRevision.Create(1);
        var parameters = new[] { ExtensionParameter.Create("kind", "file"), ExtensionParameter.Create("path", "AGENTS.md") };
        var roles = new[] { SubjectRole.ProtocolAuthoritySelfConsumer, SubjectRole.Consumer }
            .OrderBy(static role => role.Value, StringComparer.Ordinal).ToArray();
        var surfaces = SurfaceSet.Create([SurfaceKind.Provider, SurfaceKind.Repository]);
        var snapshots = new[] { SnapshotKind.Candidate, SnapshotKind.CapturedEvidence, SnapshotKind.ExactCommit, SnapshotKind.ProviderEvent, SnapshotKind.ProviderFullInventory }
            .OrderBy(static kind => kind.Value, StringComparer.Ordinal).ToArray();
        var operations = new[] { ProtocolOperation.AdoptionApply, ProtocolOperation.AdoptionAssessment, ProtocolOperation.AdoptionPlan, ProtocolOperation.Conformance, ProtocolOperation.Finalization, ProtocolOperation.Publication, ProtocolOperation.Recovery, ProtocolOperation.UpdateApply, ProtocolOperation.UpdateAssessment, ProtocolOperation.UpdatePlan }
            .OrderBy(static operation => operation.Value, StringComparer.Ordinal).ToArray();
        const string evaluatorKind = "protocol.extension.repository-path-required";
        var digest = ExtensionRuleDeclaration.ComputeDefinition(extensionId, revision, evaluatorKind, "1", parameters, roles, surfaces, snapshots, operations);
        return ExtensionRuleDeclaration.Create(extensionId, revision, evaluatorKind, "1", parameters, roles, surfaces, snapshots, operations, digest);
    }

    private static void AssertInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, error.Code);
    }

    private static QualifiedEvidenceReference Reference(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        QualifiedEvidenceReferenceKind kind)
    {
        var identity = fixture.Manifest.SourceCommit;
        var scope = EvidenceScope.Create(AcquisitionTarget.Create("subject", "repository", SurfaceKind.Repository, SnapshotKind.ExactCommit, identity), AcquisitionBoundary.Create(SnapshotKind.ExactCommit, identity, new DateTimeOffset(0, TimeSpan.Zero), new DateTimeOffset(1, TimeSpan.Zero)));
        return new QualifiedEvidenceReference(kind, fixture.Manifest.ManifestDigest, fixture.Kernel.Catalog.CatalogVersion, "protocol.slot.debt-fixture", "protocol.requirement.debt-fixture", scope, Digest("qualification-proof"), null, null, [], null, null);
    }

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "EvidenceSetFrame")]
    private static extern ExactSha256Digest EvidenceSetFrame(
        DebtEnforcementCore? owner,
        ExactSha256Digest manifest,
        ExactSha256Digest inventory,
        ExactSha256Digest snapshot,
        int rounds,
        string authority,
        int catalogVersion,
        IReadOnlyList<string> slots,
        IReadOnlyList<ExactSha256Digest> scopes,
        IReadOnlyList<ExactSha256Digest> outcomes,
        IReadOnlyList<ExactSha256Digest> references);

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "OutcomeSetFrame")]
    private static extern ExactSha256Digest OutcomeSetFrame(
        DebtEnforcementCore? owner,
        IReadOnlyList<KeyValuePair<string, ExactSha256Digest>> entries);

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "ValidateOutcomeSetBounds")]
    private static extern void ValidateOutcomeSetBounds(
        DebtEnforcementCore? owner,
        IEnumerable<string> keys);

    private static HistoricalDebtSnapshot DebtSnapshot(
        params HistoricalDebtEntry[] rows) => HistoricalDebtSnapshot.Create(
            Snapshot(
                "protocol.historical-debt-snapshot/1\n",
                rows.Select(static row => row.EntryDigest).ToArray()),
            rows);

    private static WaiverSnapshot WaiverSnapshotOf(
        params WaiverDeclaration[] rows) => WaiverSnapshot.Create(
            Snapshot(
                "protocol.waiver-snapshot/1\n",
                rows.Select(static row => row.DeclarationDigest).ToArray()),
            rows);

    private static ExactSha256Digest Snapshot(
        string separator,
        IReadOnlyList<ExactSha256Digest> rows) =>
        ProtectedPolicyFrame.Hash(
            separator,
            stream =>
            {
                ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Count));
                foreach (var row in rows)
                {
                    ProtectedPolicyFrame.Digest(stream, row);
                }
            });

    private static ExactSha256Digest Digest(string value) =>
        ExactSha256Digest.FromHashBytes(
            SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}
