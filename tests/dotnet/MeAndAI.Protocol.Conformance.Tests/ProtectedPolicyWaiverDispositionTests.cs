using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy.ProtectedPolicy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicyWaiverDispositionTests
{
    [Fact]
    [Trait("Scenario", "TEST-0211")]
    public void Applies_exact_waiver_identity_expiry_and_nonwaivable_rules()
    {
        var fixture = ProjectNeutralProtectedAuthorityFixture.CreateCanonicalEmpty();
        var declaration = fixture.Kernel.Catalog.Rules.First();
        var pack = CreateWaiverEnabledPack(fixture, declaration);
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
        var reference = CreateReference(
            fixture,
            findingDeclaration.AllowedPrimaryReferenceKinds.First());
        var finding = new RuleFinding(
            declaration.RuleId,
            declaration.RuleRevision,
            findingDeclaration.Code,
            findingDeclaration.Severity,
            findingDeclaration.Remediation,
            reference,
            []);
        var protectedFinding = fixture.Kernel.ProtectFinding(finding, declaration);
        var evaluationUtc = new DateTimeOffset(
            2026,
            8,
            20,
            12,
            0,
            0,
            TimeSpan.Zero);
        var waiver = WaiverDeclaration.Create(
            protectedFinding.Identity,
            WaiverTargetSelector.Parse(
                $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}"),
            WaiverScope.Parse("finding"),
            "Project-neutral waiver fixture.",
            "protocol-maintainer",
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('0', 40)}"),
            fixture.Manifest.ManifestDigest,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            protectedFinding.Identity.EvidenceDigest);
        var waivers = WaiverSnapshot.Create(
            Snapshot(
                "protocol.waiver-snapshot/1\n",
                [waiver.DeclarationDigest]),
            [waiver]);
        var historicalDebt = HistoricalDebtSnapshot.Create(
            Snapshot("protocol.historical-debt-snapshot/1\n", []),
            []);
        var evidenceSetDigest = Digest("waiver-evidence-set");
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
        var outcome = fixture.Kernel.ApplyWaivers(
            active,
            waivers,
            historicalDebt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(payload),
            evidenceSetDigest,
            [protectedFinding]);
        var result = Assert.Single(outcome.Results);
        Assert.Equal(payload.PayloadDigest, outcome.Authority.Payload.PayloadDigest);
        Assert.Equal(FindingDisposition.Waived, result.Disposition);
        Assert.Same(waiver, result.Waiver);
        Assert.Null(result.Debt);
        AssertExpiryEligibilityAndScopes(
            fixture,
            active,
            declaration,
            finding,
            protectedFinding,
            evaluationUtc);
        AssertAuthorityFailures(
            fixture,
            active,
            protectedFinding,
            waiver,
            waivers,
            historicalDebt,
            evidenceSetDigest,
            evaluationUtc);
        AssertStableProjection(fixture, declaration, findingDeclaration);
        AssertNonWaivableExtension(evaluationUtc);
    }

    private static void AssertExpiryEligibilityAndScopes(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ActivatedExtensionPolicy active,
        RuleDeclaration declaration,
        RuleFinding finding,
        ProtectedFinding protectedFinding,
        DateTimeOffset evaluationUtc)
    {
        var expired = CreateWaiver(
            fixture,
            protectedFinding,
            evaluationUtc.AddHours(-2),
            evaluationUtc,
            protectedFinding.Identity.EvidenceDigest,
            WaiverScope.Parse("finding"),
            $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}");
        Assert.Equal(
            FindingDisposition.ActiveViolation,
            Apply(fixture, active, protectedFinding, expired, evaluationUtc)
                .Disposition);
        var future = CreateWaiver(
            fixture,
            protectedFinding,
            evaluationUtc.AddHours(1),
            evaluationUtc.AddHours(2),
            protectedFinding.Identity.EvidenceDigest,
            WaiverScope.Parse("finding"),
            $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}");
        Assert.Equal(
            FindingDisposition.ActiveViolation,
            Apply(fixture, active, protectedFinding, future, evaluationUtc)
                .Disposition);
        var wrongEvidence = CreateWaiver(
            fixture,
            protectedFinding,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            Digest("wrong-evidence"),
            WaiverScope.Parse("finding"),
            $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}");
        Assert.Equal(
            FindingDisposition.ActiveViolation,
            Apply(
                fixture,
                active,
                protectedFinding,
                wrongEvidence,
                evaluationUtc).Disposition);

        var ineligible = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var eligible = CreateWaiver(
            fixture,
            protectedFinding,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            protectedFinding.Identity.EvidenceDigest,
            WaiverScope.Parse("finding"),
            $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}");
        Assert.Equal(
            FindingDisposition.ActiveViolation,
            Apply(fixture, ineligible, protectedFinding, eligible, evaluationUtc)
                .Disposition);

        var pathReference = CreateReference(
            fixture,
            finding.PrimaryReference.Kind,
            repositoryPath: "AGENTS.md");
        var pathFinding = new RuleFinding(
            finding.RuleId,
            finding.RuleRevision,
            finding.Code,
            finding.Severity,
            finding.Remediation,
            pathReference,
            []);
        var protectedPath = fixture.Kernel.ProtectFinding(pathFinding, declaration);
        var pathWaiver = CreateWaiver(
            fixture,
            protectedPath,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            protectedPath.Identity.EvidenceDigest,
            WaiverScope.Parse("path"),
            "repository:AGENTS.md");
        Assert.Equal(
            FindingDisposition.Waived,
            Apply(fixture, active, protectedPath, pathWaiver, evaluationUtc)
                .Disposition);

        var repositoryWaiver = CreateWaiver(
            fixture,
            protectedPath,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            protectedPath.Identity.EvidenceDigest,
            WaiverScope.Parse("repository"),
            $"evidence:{WaiverDispositionCore.StableScope(pathReference.Scope).Value}");
        Assert.Equal(
            FindingDisposition.Waived,
            Apply(
                fixture,
                active,
                protectedPath,
                repositoryWaiver,
                evaluationUtc).Disposition);
    }

    private static void AssertAuthorityFailures(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ActivatedExtensionPolicy active,
        ProtectedFinding finding,
        WaiverDeclaration waiver,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ExactSha256Digest evidenceSetDigest,
        DateTimeOffset evaluationUtc)
    {
        var wrongSnapshotPayload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            Digest("wrong-waiver-snapshot"),
            historicalDebt.SnapshotDigest,
            evidenceSetDigest,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            evaluationUtc);
        AssertCode(
            ProtectedPolicyIntegrityCode.WaiverInvalid,
            () => fixture.Kernel.ApplyWaivers(
                active,
                waivers,
                historicalDebt,
                wrongSnapshotPayload,
                ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                    wrongSnapshotPayload),
                evidenceSetDigest,
                [finding]));

        var wrongManifest = Digest("wrong-manifest");
        var wrongAuthorityPayload = ProtectedDispositionAuthorityPayload.Create(
            wrongManifest,
            wrongManifest,
            active.AuthoritySetDigest,
            waivers.SnapshotDigest,
            historicalDebt.SnapshotDigest,
            evidenceSetDigest,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            evaluationUtc);
        AssertCode(
            ProtectedPolicyIntegrityCode.DispositionAuthorityInvalid,
            () => fixture.Kernel.ApplyWaivers(
                active,
                waivers,
                historicalDebt,
                wrongAuthorityPayload,
                ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                    wrongAuthorityPayload),
                evidenceSetDigest,
                [finding]));

        var wrongBaseWaiver = WaiverDeclaration.Create(
            waiver.Finding,
            waiver.TargetSelector,
            waiver.Scope,
            waiver.Rationale,
            waiver.Owner,
            waiver.DecisionAuthority,
            Digest("wrong-trusted-base"),
            waiver.CreatedUtc,
            waiver.ExpiresUtc,
            waiver.EvidenceDigest);
        var wrongBaseSnapshot = WaiverSnapshot.Create(
            Snapshot(
                "protocol.waiver-snapshot/1\n",
                [wrongBaseWaiver.DeclarationDigest]),
            [wrongBaseWaiver]);
        var wrongBasePayload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            wrongBaseSnapshot.SnapshotDigest,
            historicalDebt.SnapshotDigest,
            evidenceSetDigest,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            evaluationUtc);
        AssertCode(
            ProtectedPolicyIntegrityCode.WaiverInvalid,
            () => fixture.Kernel.ApplyWaivers(
                active,
                wrongBaseSnapshot,
                historicalDebt,
                wrongBasePayload,
                ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(
                    wrongBasePayload),
                evidenceSetDigest,
                [finding]));
    }

    private static void AssertStableProjection(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        RuleDeclaration declaration,
        FindingDeclaration findingDeclaration)
    {
        var first = Protect(
            fixture,
            declaration,
            findingDeclaration,
            CreateReference(
                fixture,
                findingDeclaration.AllowedPrimaryReferenceKinds.First()));
        var later = Protect(
            fixture,
            declaration,
            findingDeclaration,
            CreateReference(
                fixture,
                findingDeclaration.AllowedPrimaryReferenceKinds.First(),
                targetIdentity: new string('1', 40),
                startedTicks: 10,
                proofSeed: "later-proof"));
        Assert.Equal(first.Identity.StableKey.Value, later.Identity.StableKey.Value);
        var differentSource = Protect(
            fixture,
            declaration,
            findingDeclaration,
            CreateReference(
                fixture,
                findingDeclaration.AllowedPrimaryReferenceKinds.First(),
                sourceIdentity: "other-repository"));
        Assert.NotEqual(
            first.Identity.StableKey.Value,
            differentSource.Identity.StableKey.Value);
        var differentManifest = Protect(
            fixture,
            declaration,
            findingDeclaration,
            CreateReference(
                fixture,
                findingDeclaration.AllowedPrimaryReferenceKinds.First(),
                manifestDigest: Digest("different-content")));
        Assert.NotEqual(
            first.Identity.StableKey.Value,
            differentManifest.Identity.StableKey.Value);
    }

    private static void AssertNonWaivableExtension(DateTimeOffset evaluationUtc)
    {
        var registration =
            RepositoryPathRequiredExtensionEvaluator.CreateRegistration();
        var declaration = CreateRequiredPathDeclaration();
        var policy = ProjectNeutralProtectedAuthorityFixture.CreateTestPolicy(
            [registration]);
        var fixture = ProjectNeutralProtectedAuthorityFixture
            .CreateCanonicalNonempty(policy, declaration);
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var findingDeclaration = Assert.Single(registration.Declaration.Findings);
        var finding = new ExtensionFinding(
            declaration.ExtensionId,
            declaration.Revision,
            findingDeclaration.Code,
            findingDeclaration.Severity,
            findingDeclaration.Remediation,
            CreateReference(
                fixture,
                findingDeclaration.AllowedPrimaryReferenceKinds.First()),
            [],
            "missing",
            null);
        var protectedFinding = fixture.Kernel.ProtectFinding(
            finding,
            declaration,
            registration.Declaration);
        var waiver = CreateWaiver(
            fixture,
            protectedFinding,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            protectedFinding.Identity.EvidenceDigest,
            WaiverScope.Parse("finding"),
            $"evidence:{protectedFinding.Identity.EvidenceDigest.Value}");
        Assert.Equal(
            FindingDisposition.ActiveViolation,
            Apply(fixture, active, protectedFinding, waiver, evaluationUtc)
                .Disposition);
    }

    private static ExtensionRuleDeclaration CreateRequiredPathDeclaration()
    {
        var extensionId = ExtensionId.Parse("ext:repo:required-agents");
        var revision = RuleRevision.Create(1);
        ExtensionParameter[] parameters =
        [
            ExtensionParameter.Create("kind", "file"),
            ExtensionParameter.Create("path", "AGENTS.md"),
        ];
        SubjectRole[] roles = [SubjectRole.Consumer];
        var surfaces = SurfaceSet.Create([SurfaceKind.Repository]);
        SnapshotKind[] snapshots = [SnapshotKind.ExactCommit];
        ProtocolOperation[] operations = [ProtocolOperation.Conformance];
        var digest = ExtensionRuleDeclaration.ComputeDefinition(
            extensionId,
            revision,
            "protocol.extension.repository-path-required",
            "1",
            parameters,
            roles,
            surfaces,
            snapshots,
            operations);
        return ExtensionRuleDeclaration.Create(
            extensionId,
            revision,
            "protocol.extension.repository-path-required",
            "1",
            parameters,
            roles,
            surfaces,
            snapshots,
            operations,
            digest);
    }

    private static ProtectedFinding Protect(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        RuleDeclaration declaration,
        FindingDeclaration findingDeclaration,
        QualifiedEvidenceReference reference) => fixture.Kernel.ProtectFinding(
        new RuleFinding(
            declaration.RuleId,
            declaration.RuleRevision,
            findingDeclaration.Code,
            findingDeclaration.Severity,
            findingDeclaration.Remediation,
            reference,
            []),
        declaration);

    private static WaiverDeclaration CreateWaiver(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ProtectedFinding finding,
        DateTimeOffset createdUtc,
        DateTimeOffset expiresUtc,
        ExactSha256Digest evidenceDigest,
        WaiverScope scope,
        string selector) => WaiverDeclaration.Create(
        finding.Identity,
        WaiverTargetSelector.Parse(selector),
        scope,
        "Project-neutral waiver fixture.",
        "protocol-maintainer",
        ReviewedAuthorityPermalink.Create(
            $"https://github.com/owner/repo/commit/{new string('0', 40)}"),
        fixture.Manifest.ManifestDigest,
        createdUtc,
        expiresUtc,
        evidenceDigest);

    private static FindingDispositionResult Apply(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ActivatedExtensionPolicy active,
        ProtectedFinding finding,
        WaiverDeclaration waiver,
        DateTimeOffset evaluationUtc)
    {
        var waivers = WaiverSnapshot.Create(
            Snapshot(
                "protocol.waiver-snapshot/1\n",
                [waiver.DeclarationDigest]),
            [waiver]);
        var debt = HistoricalDebtSnapshot.Create(
            Snapshot("protocol.historical-debt-snapshot/1\n", []),
            []);
        var evidence = Digest("waiver-evidence-set");
        var payload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            waivers.SnapshotDigest,
            debt.SnapshotDigest,
            evidence,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            evaluationUtc);
        return Assert.Single(fixture.Kernel.ApplyWaivers(
            active,
            waivers,
            debt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(payload),
            evidence,
            [finding]).Results);
    }

    private static void AssertCode(
        ProtectedPolicyIntegrityCode expected,
        Action action)
    {
        var failure = Assert.Throws<ProtectedPolicyIntegrityException>(action);
        Assert.Equal(expected, failure.Code);
    }

    private static ProtectedPolicyPackBinding CreateWaiverEnabledPack(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        RuleDeclaration target)
    {
        var rows = fixture.Kernel.Catalog.Rules.Select(rule =>
            BaselineRuleWaiverPolicy.Create(
                rule.RuleId,
                rule.RuleRevision,
                rule.RuleId.Equals(target.RuleId) &&
                rule.RuleRevision.Equals(target.RuleRevision)))
            .ToArray();
        var waiverPolicyDigest = ProtectedPolicyFrame.Hash(
            "protocol.baseline-waiver-policy/1\n",
            stream =>
            {
                ProtectedPolicyFrame.Digest(
                    stream,
                    fixture.Manifest.ManifestDigest);
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
        var waiverPolicy = BaselineWaiverPolicySnapshot.Create(
            fixture.Manifest.ManifestDigest,
            waiverPolicyDigest,
            rows);
        var bindingDigest = ProtectedPolicyPackBinding.ComputeDigest(
            fixture.Manifest.ManifestDigest,
            fixture.Policy.ExportDigest,
            waiverPolicy.SnapshotDigest,
            fixture.PackBinding.Artifacts);
        return ProtectedPolicyPackBinding.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Policy.ExportDigest,
            waiverPolicy,
            fixture.PackBinding.Artifacts,
            bindingDigest);
    }

    private static QualifiedEvidenceReference CreateReference(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        QualifiedEvidenceReferenceKind kind,
        string sourceIdentity = "repository",
        string? targetIdentity = null,
        long startedTicks = 0,
        string proofSeed = "qualification-proof",
        ExactSha256Digest? manifestDigest = null,
        string? repositoryPath = null)
    {
        var identity = targetIdentity ?? fixture.Manifest.SourceCommit;
        var scope = EvidenceScope.Create(
            AcquisitionTarget.Create(
                "subject",
                sourceIdentity,
                SurfaceKind.Repository,
                SnapshotKind.ExactCommit,
                identity),
            AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit,
                identity,
                new DateTimeOffset(startedTicks, TimeSpan.Zero),
                new DateTimeOffset(startedTicks + 1, TimeSpan.Zero)));
        var location = repositoryPath is null
            ? null
            : RepositoryEvidenceLocation.Create(
                scope,
                repositoryPath,
                null,
                null,
                null,
                null);
        return new QualifiedEvidenceReference(
            kind,
            manifestDigest ?? fixture.Manifest.ManifestDigest,
            fixture.Kernel.Catalog.CatalogVersion,
            "protocol.slot.waiver-fixture",
            "protocol.requirement.waiver-fixture",
            scope,
            Digest(proofSeed),
            null,
            location,
            [],
            null,
            null);
    }

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
