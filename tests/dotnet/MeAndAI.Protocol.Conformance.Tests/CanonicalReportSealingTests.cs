using System.Globalization;
using System.Runtime.CompilerServices;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy.Models;
using MeAndAI.Protocol.Policy.ProtectedPolicy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class CanonicalReportSealingTests
{
    private const string ReviewedLiteral =
        "cHJvdG9jb2wuY29uZm9ybWFuY2UtcmVwb3J0LzEKAAAABnJlcG9ydAAAABtwcm90b2NvbC5jb25mb3JtYW5jZS1yZXBvcnQAAAABMQAAAAdydW50aW1lAAAABTEuMC4wAAAAKDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYAAAAGdGFyZ2V0AAAADHJlcG86Zml4dHVyZQAAAAxyZXBvOmZpeHR1cmUAAAAKcmVwb3NpdG9yeQAAAAxleGFjdC1jb21taXQAAAAoMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMQAAAAdwcm9maWxlAAAAAQICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAB2ZpeHR1cmUAAAAIY29uc3VtZXIAAAATYWRvcHRpb24tYXNzZXNzbWVudAAAAAxleGFjdC1jb21taXQAAAABAAAACnJlcG9zaXRvcnkAAAAFYXVkaXQAAAANYWN0aXZlLXBvbGljeQcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQAAAAAAAAABCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMAAAAAAAAAAAAAAAACGNvbXBsZXRlAAAAAAAAAAAAAAAAAAAAAAAADQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODgAAAApjb25mb3JtaW5nAAAABWFsbG93";
    [Fact]
    public void Seals_exact_typed_report_bytes_digest_redaction_and_dimensions()
    {
        AssertReviewedLiteralAndWriter();
        var fixture = CreateEvaluationFixture();
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var evaluation = CreateEvaluation(
            fixture,
            active,
            out var repository,
            out var profile);
        var report = AssertRealReport(fixture, evaluation, repository);
        var reorderedEvaluation = CreateEvaluation(
            fixture,
            active,
            out _,
            out _,
            reverseTargets: true);
        Assert.Equal(
            report.CanonicalBytes,
            fixture.Kernel.SealReport(reorderedEvaluation).CanonicalBytes);
        var transition = Transition(active, fixture.Manifest.SourceCommit);
        var transitionEvaluation = CreateEvaluation(
            fixture,
            active,
            out _,
            out _,
            transition: transition);
        var transitionReport = fixture.Kernel.SealReport(transitionEvaluation);
        Assert.Equal(
            transition.ProposedSnapshot.SnapshotDigest,
            transitionReport.ProposedExtensionSnapshotDigest);
        Assert.Equal(transition.TargetCommit, transitionReport.ProposedTargetCommit);
        Assert.Equal(transition.TransitionDigest, transitionReport.ProposedTransitionDigest);
        Assert.NotEqual(report.CanonicalBytes, transitionReport.CanonicalBytes);
        AssertNoInputCarrier(EnforcementPhase.Prospective);
        AssertNoInputCarrier(EnforcementPhase.FullBlocking);
        AssertIssuedDimensionReports();
        var compatibilityTargets = new[]
        {
            Target(fixture, SurfaceKind.Provider, "github"),
            repository,
        };
        var compatibility = fixture.Kernel.PlanApplicability(
            profile,
            compatibilityTargets);
        Assert.Same(repository, compatibility.SubjectRepository);
        var anchorNull = Assert.Throws<ArgumentNullException>(() =>
            fixture.Kernel.PlanApplicability(
                profile,
                null!,
                compatibilityTargets));
        Assert.Equal("subjectRepository", anchorNull.ParamName);
        var invalidAnchor = Assert.Throws<CatalogIntegrityException>(() =>
            fixture.Kernel.PlanApplicability(
                profile,
                compatibilityTargets[0],
                compatibilityTargets));
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, invalidAnchor.Code);

        var nullError = Assert.Throws<ArgumentNullException>(
            () => fixture.Kernel.SealReport(null!));
        Assert.Equal("evaluation", nullError.ParamName);
        var canceled = new CancellationToken(canceled: true);
        var canceledError = Assert.Throws<OperationCanceledException>(
            () => fixture.Kernel.SealReport(evaluation, canceled));
        Assert.Equal(canceled, canceledError.CancellationToken);
        AssertIntegrityRoutes(fixture, evaluation);
        AssertResourceBounds();
        AssertProtectedRedactionAndPrecedence();
    }

    private static void AssertReviewedLiteralAndWriter()
    {
        var expected = Convert.FromBase64String(ReviewedLiteral);
        Assert.Equal(927, expected.Length);
        const string digest =
            "960F98690439111A04A9DB1BE3CC31CB790FFD5C10056E3BF088EB20DE92C2BE";
        Assert.Equal(digest, Convert.ToHexString(SHA256.HashData(expected)));
        var frame = new CanonicalReportFrame(
            "protocol.conformance-report",
            "1",
            new CanonicalRuntimeFrame(
                "1.0.0",
                new string('0', 39) + "1",
                Repeated(1),
                Repeated(2),
                Repeated(3),
                Repeated(4),
                Repeated(5),
                Repeated(6)),
            AcquisitionTarget.Create(
                "repo:fixture",
                "repo:fixture",
                SurfaceKind.Repository,
                SnapshotKind.ExactCommit,
                new string('0', 39) + "1"),
            CatalogVersion.Create(1),
            Repeated(2),
            "fixture",
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.AdoptionAssessment,
                SnapshotKind.ExactCommit,
                SurfaceSet.Create([SurfaceKind.Repository]),
                EnforcementPhase.Audit),
            new CanonicalActivePolicyFrame(
                Repeated(7),
                Repeated(8),
                Repeated(9),
                1,
                Repeated(10),
                Repeated(11),
                Repeated(12),
                default),
            null,
            AcquisitionStatus.Complete,
            [],
            [],
            [],
            [],
            false,
            false,
            Repeated(13),
            Repeated(14),
            ConformanceVerdict.Conforming,
            EnforcementDecision.Allow);
        var originalCulture = CultureInfo.CurrentCulture;
        byte[] actual;
        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR");
            actual = CanonicalReportCore.Write(frame, CancellationToken.None);
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
        }

        Assert.Equal(expected, actual);
        AssertRootFieldGroups(frame, actual);
        Assert.Throws<OverflowException>(() => CanonicalReportCore.Write(
            CloneRoot(frame, catalogVersion: CreateCatalogVersion(-1)),
            CancellationToken.None));
        var english = CultureInfo.GetCultureInfo("en-US");
        try
        {
            CultureInfo.CurrentCulture = english;
            Assert.Equal(
                actual,
                CanonicalReportCore.Write(frame, CancellationToken.None));
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
        }

        Assert.NotEqual(
            CanonicalReportCore.Write(
                CopyFrame(frame, "fixture\nline"),
                CancellationToken.None),
            CanonicalReportCore.Write(
                CopyFrame(frame, "fixture\r\nline"),
                CancellationToken.None));
        AssertLocationUnions(frame);
        AssertDispositionUnions(frame);
        CanonicalReportCore.ValidateDigest(
            actual,
            ExactSha256Digest.Parse(digest.ToLowerInvariant()));
        var changed = actual.ToArray();
        changed[^1] ^= 1;
        AssertReportCode(
            () => CanonicalReportCore.ValidateDigest(
                changed,
                ExactSha256Digest.Parse(digest.ToLowerInvariant())),
            CanonicalReportIntegrityCode.DigestMismatch);
    }

    private static void AssertRootFieldGroups(
        CanonicalReportFrame source,
        IReadOnlyList<byte> expected)
    {
        var runtime = source.Runtime;
        var active = source.ActivePolicy;
        CanonicalReportFrame[] mutations =
        [
            CloneRoot(source, schemaKey: "protocol.conformance-report.changed"),
            CloneRoot(source, runtime: new CanonicalRuntimeFrame(
                "1.0.1",
                runtime.SourceCommit,
                runtime.ManifestDigest,
                runtime.CatalogDigest,
                runtime.PolicyPackBindingDigest,
                runtime.RuntimeArtifactDigest,
                runtime.TrustAnchorDigest,
                runtime.BindingDigest)),
            CloneRoot(source, subjectRepository: AcquisitionTarget.Create(
                source.SubjectRepository.SubjectIdentity,
                "repo:changed",
                source.SubjectRepository.Surface,
                source.SubjectRepository.SnapshotKind,
                source.SubjectRepository.TargetIdentity)),
            CloneRoot(source, profileName: "fixture-changed"),
            CloneRoot(source, activePolicy: new CanonicalActivePolicyFrame(
                active.SnapshotDigest,
                active.AuthoritySetDigest,
                active.ActivationRecordDigest,
                active.ActivationEpoch + 1,
                active.DispositionAuthorityBindingDigest,
                active.WaiverSnapshotDigest,
                active.DebtSnapshotDigest,
                active.EvaluationUtc)),
            CloneRoot(source, acquisitionStatus: AcquisitionStatus.Incomplete),
            CloneRoot(source, hasKnownViolation: true),
            CloneRoot(source, hasUnresolvedRequiredEvaluation: true),
            CloneRoot(source, evidenceSetDigest: Repeated(61)),
            CloneRoot(source, outcomeSetDigest: Repeated(62)),
            CloneRoot(source, verdict: ConformanceVerdict.NonConforming),
            CloneRoot(source, enforcement: EnforcementDecision.Block),
        ];
        Assert.All(mutations, mutation => Assert.NotEqual(
            expected,
            CanonicalReportCore.Write(mutation, CancellationToken.None)));
    }

    private static CanonicalReportFrame CloneRoot(
        CanonicalReportFrame source,
        string? schemaKey = null,
        CanonicalRuntimeFrame? runtime = null,
        AcquisitionTarget? subjectRepository = null,
        CatalogVersion? catalogVersion = null,
        string? profileName = null,
        CanonicalActivePolicyFrame? activePolicy = null,
        AcquisitionStatus? acquisitionStatus = null,
        bool? hasKnownViolation = null,
        bool? hasUnresolvedRequiredEvaluation = null,
        ExactSha256Digest? evidenceSetDigest = null,
        ExactSha256Digest? outcomeSetDigest = null,
        ConformanceVerdict? verdict = null,
        EnforcementDecision? enforcement = null) => new(
        schemaKey ?? source.SchemaKey,
        source.SchemaVersion,
        runtime ?? source.Runtime,
        subjectRepository ?? source.SubjectRepository,
        catalogVersion ?? source.CatalogVersion,
        source.CatalogDigest,
        profileName ?? source.ProfileName,
        source.Profile,
        activePolicy ?? source.ActivePolicy,
        source.Transition,
        acquisitionStatus ?? source.AcquisitionStatus,
        source.Acquisitions,
        source.BaselineEvaluations,
        source.ExtensionEvaluations,
        source.Dispositions,
        hasKnownViolation ?? source.HasKnownViolation,
        hasUnresolvedRequiredEvaluation ?? source.HasUnresolvedRequiredEvaluation,
        evidenceSetDigest ?? source.EvidenceSetDigest,
        outcomeSetDigest ?? source.OutcomeSetDigest,
        verdict ?? source.Verdict,
        enforcement ?? source.Enforcement,
        source.BaselineFindingIdentities,
        source.ExtensionFindingIdentities);

    private static CanonicalReportFrame CopyFrame(
        CanonicalReportFrame source,
        string profileName,
        IReadOnlyList<CanonicalFindingDisposition>? dispositions = null,
        IReadOnlyList<RuleEvaluation>? baselineEvaluations = null) => new(
        source.SchemaKey,
        source.SchemaVersion,
        source.Runtime,
        source.SubjectRepository,
        source.CatalogVersion,
        source.CatalogDigest,
        profileName,
        source.Profile,
        source.ActivePolicy,
        source.Transition,
        source.AcquisitionStatus,
        source.Acquisitions,
        baselineEvaluations ?? source.BaselineEvaluations,
        source.ExtensionEvaluations,
        dispositions ?? source.Dispositions,
        source.HasKnownViolation,
        source.HasUnresolvedRequiredEvaluation,
        source.EvidenceSetDigest,
        source.OutcomeSetDigest,
        source.Verdict,
        source.Enforcement,
        source.BaselineFindingIdentities,
        source.ExtensionFindingIdentities);

    private static void AssertLocationUnions(CanonicalReportFrame source)
    {
        var started = new DateTimeOffset(2026, 8, 22, 0, 0, 0, TimeSpan.Zero);
        var repositoryScope = Scope(
            SurfaceKind.Repository,
            SnapshotKind.ExactCommit,
            new string('a', 40),
            new string('a', 40));
        var providerScope = Scope(
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent,
            "provider-delivery-1",
            new string('d', 64));
        var releaseScope = Scope(
            SurfaceKind.Release,
            SnapshotKind.CapturedEvidence,
            new string('c', 64),
            new string('c', 64));
        EvidenceLocation[] locations =
        [
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                "AGENTS.md",
                new string('a', 40),
                1,
                null,
                null),
            ProviderEvidenceLocation.Create(
                providerScope,
                "github/installations/1",
                "provider.issue",
                "issue-42",
                "version-7",
                "body",
                3,
                null),
            ReleaseAssetEvidenceLocation.Create(
                releaseScope,
                "release-1",
                "v1.0.0",
                "protocol.zip",
                Repeated(41)),
            SnapshotEvidenceLocation.Create(repositoryScope),
        ];
        var references = locations.Select((location, index) =>
            new QualifiedEvidenceReference(
                QualifiedEvidenceReferenceKind.ContextProof,
                Repeated(checked((byte)(42 + index))),
                CatalogVersion.Create(1),
                $"protocol.slot.location-{index}",
                $"protocol.requirement.location-{index}",
                location.Scope,
                Repeated(checked((byte)(46 + index))),
                null,
                location,
                [],
                null,
                null)).ToArray();
        var evaluation = new RuleEvaluation(
            RuleId.Parse("RULE-0001"),
            RuleRevision.Create(1),
            RuleEvaluationStatus.Satisfied,
            false,
            references,
            [],
            [],
            []);
        var frame = CopyFrame(
            source,
            source.ProfileName,
            baselineEvaluations: [evaluation]);
        var expected = CanonicalReportCore.Write(frame, CancellationToken.None);
        Array.Reverse(references);
        var repeated = CanonicalReportCore.Write(frame, CancellationToken.None);
        Assert.Equal(expected, repeated);
        Assert.All(
            new[]
            {
                "repository-location",
                "provider-location",
                "release-asset-location",
                "snapshot-location",
            },
            tag => Assert.True(expected.AsSpan().IndexOf(
                Encoding.UTF8.GetBytes(tag)) >= 0));
        AssertNestedUnionTamper(
            expected,
            "repository-location",
            "provider-location",
            "release-asset-location",
            "snapshot-location");

        EvidenceScope Scope(
            SurfaceKind surface,
            SnapshotKind snapshot,
            string targetIdentity,
            string boundaryIdentity)
        {
            var target = AcquisitionTarget.Create(
                "repo:fixture",
                surface.Equals(SurfaceKind.Provider) ? "github" : "repo:fixture",
                surface,
                snapshot,
                targetIdentity);
            return EvidenceScope.Create(
                target,
                AcquisitionBoundary.Create(
                    snapshot,
                    boundaryIdentity,
                    started,
                    started.AddMinutes(1)));
        }
    }

    private static void AssertDispositionUnions(CanonicalReportFrame source)
    {
        var authority = ReviewedAuthorityPermalink.Create(
            $"https://github.com/owner/repo/commit/{new string('0', 40)}");
        var expires = new DateTimeOffset(2026, 9, 1, 0, 0, 0, TimeSpan.Zero);
        var rows = new[]
        {
            new CanonicalFindingDisposition(
                Finding("protocol.finding.report-active", 20),
                FindingDisposition.ActiveViolation,
                null,
                null,
                null,
                null,
                null,
                null),
            new CanonicalFindingDisposition(
                Finding("protocol.finding.report-waived", 24),
                FindingDisposition.Waived,
                Repeated(28),
                authority,
                expires,
                null,
                null,
                null),
            new CanonicalFindingDisposition(
                Finding("protocol.finding.report-debt", 32),
                FindingDisposition.HistoricalDebt,
                null,
                null,
                null,
                Repeated(36),
                authority,
                expires),
        };
        var bytes = CanonicalReportCore.Write(
            CopyFrame(source, source.ProfileName, rows),
            CancellationToken.None);
        Assert.True(bytes.AsSpan().IndexOf("active"u8) >= 0);
        Assert.True(bytes.AsSpan().IndexOf("waived"u8) >= 0);
        Assert.True(bytes.AsSpan().IndexOf("debt"u8) >= 0);
        Assert.True(bytes.AsSpan().IndexOf("waiver free text"u8) < 0);
        Assert.True(bytes.AsSpan().IndexOf("debt review text"u8) < 0);
        AssertNestedUnionTamper(bytes, "active", "waived", "debt");
        AssertWriterMidWalkCancellation(source, rows[0]);
    }

    private static void AssertWriterMidWalkCancellation(
        CanonicalReportFrame source,
        CanonicalFindingDisposition row)
    {
        var frame = CopyFrame(source, source.ProfileName, [row]);
        using var cancellation = new CancellationTokenSource();
        Dispositions(frame) = new CancelingList<CanonicalFindingDisposition>(
            row, 100_000, cancellation, 2_048);
        var error = Assert.Throws<OperationCanceledException>(() =>
            CanonicalReportCore.Write(frame, cancellation.Token));
        Assert.Equal(cancellation.Token, error.CancellationToken);
    }

    private static void AssertNestedUnionTamper(
        IReadOnlyList<byte> source,
        params string[] tags)
    {
        var retained = source.ToArray();
        var digest = ExactSha256Digest.FromHashBytes(SHA256.HashData(retained));
        var offsets = new HashSet<int>();
        foreach (var tag in tags)
        {
            var encoded = Encoding.UTF8.GetBytes(tag);
            var framed = new byte[] { 0, 0, 0, checked((byte)encoded.Length) }
                .Concat(encoded).ToArray();
            var offset = retained.AsSpan().IndexOf(framed);
            Assert.True(offset >= 0);
            Assert.True(offsets.Add(offset));
            var changed = retained.ToArray();
            changed[offset + framed.Length] ^= 1;
            AssertReportCode(
                () => CanonicalReportCore.ValidateDigest(changed, digest),
                CanonicalReportIntegrityCode.DigestMismatch);
        }
    }

    private static ProtectedFindingIdentity Finding(string code, byte seed)
    {
        var rule = PolicyRuleIdentity.Baseline(
            RuleId.Parse("RULE-0001"),
            RuleRevision.Create(1));
        var findingCode = FindingCode.Parse(code);
        var location = Repeated(seed);
        var evidence = Repeated(checked((byte)(seed + 1)));
        var expected = Repeated(checked((byte)(seed + 2)));
        var stable = StableFindingKey.Create(
            rule,
            findingCode,
            location,
            evidence,
            expected);
        return ProtectedFindingIdentity.Create(
            rule,
            findingCode,
            location,
            evidence,
            expected,
            stable);
    }

    private static ProtectedPolicyEvaluation CreateEvaluation(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ActivatedExtensionPolicy active,
        out AcquisitionTarget repository,
        out NamedExecutionProfile profile,
        bool reverseTargets = false,
        ProposedExtensionTransition? transition = null,
        bool attachProtectedInput = false,
        EnforcementPhase? phase = null,
        AcquisitionStatus? acquisitionStatus = null)
    {
        var resolved = fixture.Kernel.ResolveNamedProfile(
            "protocol.profile.consumer-provider-exact-commit-conformance-audit");
        profile = phase is null
            ? resolved
            : new NamedExecutionProfile(
                $"protocol.profile.report-{phase.Value}",
                ExecutionProfile.Create(
                    resolved.Axes.SubjectRole,
                    resolved.Axes.Operation,
                    resolved.Axes.SnapshotKind,
                    resolved.Axes.Surfaces,
                    phase),
                resolved.RuleIds,
                resolved.PlanningSession);
        repository = Target(fixture, SurfaceKind.Repository, "repo");
        var targets = new[]
        {
            Target(fixture, SurfaceKind.Provider, "github"),
            repository,
        };
        if (reverseTargets)
        {
            Array.Reverse(targets);
        }
        var plan = fixture.Kernel.PlanApplicability(profile, repository, targets);
        Assert.Same(repository, plan.SubjectRepository);
        Assert.Equal(
            [SurfaceKind.Repository, SurfaceKind.Provider],
            plan.Targets.Select(static row => row.Surface));
        var closure = IssueClosure(
            fixture,
            plan,
            acquisitionStatus ?? AcquisitionStatus.Complete);
        if (attachProtectedInput)
        {
            closure = closure.WithProtectedInput(new RepositoryTreeCapability([]));
        }
        var baseline = fixture.Kernel.Evaluate(closure);
        var extensionEvaluations = active.Snapshot.Extensions.Count == 0
            ? []
            : closure.ProtectedInput is null
                ? [new ExtensionEvaluation(
                    active.Snapshot.Extensions.Single().ExtensionId,
                    active.Snapshot.Extensions.Single().Revision,
                    RuleEvaluationStatus.NotEvaluated,
                    isApplicabilityUnresolved: false,
                    [],
                    ["protocol.slot.repository-tree"],
                    [],
                    [])]
            : ExtensionEvaluationCore.Evaluate(
                active,
                profile.Axes,
                closure.Context.AdmittedSlotKeys,
                closure.ProtectedInput!.Access,
                closure.ProtectedInput.References,
                CancellationToken.None);
        var evidence = DebtEnforcementCore.ComputeEvidenceSetDigest(
            baseline,
            closure,
            active,
            extensionEvaluations);
        var waivers = WaiverSnapshot.Create(
            Snapshot("protocol.waiver-snapshot/1\n", []),
            []);
        var debt = HistoricalDebtSnapshot.Create(
            Snapshot("protocol.historical-debt-snapshot/1\n", []),
            []);
        var payload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            waivers.SnapshotDigest,
            debt.SnapshotDigest,
            evidence,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            new DateTimeOffset(2026, 8, 22, 8, 0, 0, TimeSpan.Zero));
        return fixture.Kernel.EvaluateProtected(
            baseline,
            closure,
            active,
            transition,
            waivers,
            debt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(payload),
            profile.Axes.EnforcementPhase);
    }

    private static ProposedExtensionTransition Transition(
        ActivatedExtensionPolicy active,
        string targetCommit)
    {
        var declaration = ExtensionDeclaration();
        var extensionId = declaration.ExtensionId;
        var blob = Digest("report-proposed-policy-blob");
        var proposed = ExtensionCatalogSnapshot.Create(
            active.Snapshot.RepositoryNamespace,
            blob,
            ExtensionCatalogSnapshot.ComputeDigest(
                active.Snapshot.RepositoryNamespace,
                blob,
                [declaration]),
            [declaration]);
        var change = ProposedExtensionChange.Create(
            extensionId,
            ExtensionTransitionKind.Added,
            null,
            declaration.DefinitionDigest);
        return ProposedExtensionTransition.Create(
            active.Snapshot,
            proposed,
            targetCommit,
            Digest("report-transition-rationale"),
            [change]);
    }

    private static ExtensionRuleDeclaration ExtensionDeclaration()
    {
        var extensionId = ExtensionId.Parse("ext:repo:report-transition");
        var revision = RuleRevision.Create(1);
        var parameters = new[]
        {
            ExtensionParameter.Create("kind", "file"),
            ExtensionParameter.Create("path", "AGENTS.md"),
        };
        var roles = new[] { SubjectRole.Consumer };
        var surfaces = SurfaceSet.Create([SurfaceKind.Repository]);
        var snapshots = new[] { SnapshotKind.ExactCommit };
        var operations = new[] { ProtocolOperation.Conformance };
        const string evaluator = "protocol.extension.repository-path-required";
        var definition = ExtensionRuleDeclaration.ComputeDefinition(
            extensionId,
            revision,
            evaluator,
            "1",
            parameters,
            roles,
            surfaces,
            snapshots,
            operations);
        return ExtensionRuleDeclaration.Create(
            extensionId,
            revision,
            evaluator,
            "1",
            parameters,
            roles,
            surfaces,
            snapshots,
            operations,
            definition);
    }

    private static CanonicalConformanceReport AssertRealReport(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ProtectedPolicyEvaluation evaluation,
        AcquisitionTarget repository)
    {
        var report = fixture.Kernel.SealReport(evaluation);
        Assert.Equal("protocol.conformance-report", report.SchemaKey);
        Assert.Equal("1", report.SchemaVersion);
        Assert.Same(repository, report.SubjectRepository);
        Assert.Equal(evaluation.Baseline.Acquisitions.Count, report.Acquisitions.Count);
        Assert.Equal(
            evaluation.Baseline.Evaluations.Count +
                evaluation.ExtensionEvaluations.Count,
            report.RuleEvaluations.Count);
        Assert.Equal(evaluation.Dispositions.Count, report.Dispositions.Count);
        Assert.Equal(
            evaluation.Baseline.Acquisitions.Any(static row =>
                row.Status.Equals(AcquisitionStatus.Failed))
                ? AcquisitionStatus.Failed
                : evaluation.Baseline.Acquisitions.Any(static row =>
                    row.Status.Equals(AcquisitionStatus.Incomplete))
                    ? AcquisitionStatus.Incomplete
                    : AcquisitionStatus.Complete,
            report.AcquisitionStatus);
        Assert.Equal(evaluation.Baseline.HasKnownViolation ||
            evaluation.ExtensionEvaluations.Any(static row =>
                row.Status.Equals(RuleEvaluationStatus.Violated)),
            report.HasKnownViolation);
        Assert.Equal(evaluation.Baseline.HasUnresolvedRequiredEvaluation ||
            evaluation.ExtensionEvaluations.Any(static row =>
                row.IsApplicabilityUnresolved ||
                row.Status.Equals(RuleEvaluationStatus.NotEvaluated)),
            report.HasUnresolvedRequiredEvaluation);
        Assert.Equal(evaluation.EvidenceSetDigest, report.EvidenceSetDigest);
        Assert.Equal(evaluation.OutcomeSetDigest, report.OutcomeSetDigest);
        Assert.Equal(evaluation.Verdict, report.Verdict);
        Assert.Equal(evaluation.Enforcement, report.Enforcement);
        Assert.Equal(
            report.ReportDigest,
            ExactSha256Digest.FromHashBytes(SHA256.HashData(
                report.CanonicalBytes.ToArray())));
        var changed = report.CanonicalBytes.ToArray();
        changed[0] ^= 1;
        Assert.NotEqual(changed, report.CanonicalBytes);
        Assert.DoesNotContain(
            "authorization: bearer test-secret",
            Encoding.UTF8.GetString(report.CanonicalBytes.ToArray()),
            StringComparison.OrdinalIgnoreCase);
        return report;
    }

    private static void AssertIntegrityRoutes(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ProtectedPolicyEvaluation evaluation)
    {
        var kernel = fixture.Kernel;
        var runtime = evaluation.RuntimeBinding;
        var foreignRuntime = RuntimeQualificationBinding.Create(
            runtime.ProtocolVersion,
            new string('0', 40),
            runtime.ManifestDigest,
            runtime.CatalogDigest,
            runtime.PolicyPackBindingDigest,
            runtime.RuntimeArtifactDigest,
            runtime.TrustAnchorDigest);
        var contradictoryVerdict = evaluation.Verdict.Equals(
            ConformanceVerdict.Conforming)
            ? ConformanceVerdict.NonConforming
            : ConformanceVerdict.Conforming;
        var otherFixture = CreateEvaluationFixture();
        var otherActive = otherFixture.Kernel.ActivateExtensions(
            otherFixture.Snapshot,
            otherFixture.ActivationPayload,
            otherFixture.ActivationProof,
            otherFixture.PackBinding,
            otherFixture.PackProof,
            otherFixture.Policy);
        var other = CreateEvaluation(otherFixture, otherActive, out _, out _);
        var foreignCatalog = CloneBaseline(
            evaluation.Baseline,
            catalog: other.Baseline.Catalog);
        var foreignSession = CloneBaseline(
            evaluation.Baseline,
            profile: other.Baseline.Profile);
        var foreignClosure = CloneBaseline(
            evaluation.Baseline,
            closure: other.Baseline.Closure);
        var payload = evaluation.DispositionAuthority.Payload;
        var foreignPayload = ProtectedDispositionAuthorityPayload.Create(
            payload.ManifestDigest,
            payload.TrustedBaseAuthorityDigest,
            payload.AuthoritySetDigest,
            payload.WaiverSnapshotDigest,
            payload.DebtSnapshotDigest,
            payload.EvidenceSetDigest,
            Digest("foreign-report-authority"),
            payload.AuthorityEpoch,
            payload.EvaluationUtc);
        var foreignAuthority = ProtectedDispositionAuthority.Create(
            foreignPayload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(foreignPayload));
        var stalePayload = ProtectedDispositionAuthorityPayload.Create(
            payload.ManifestDigest,
            payload.TrustedBaseAuthorityDigest,
            payload.AuthoritySetDigest,
            payload.WaiverSnapshotDigest,
            payload.DebtSnapshotDigest,
            Digest("stale-report-evidence"),
            payload.ExpectedAuthorityRecordDigest,
            payload.AuthorityEpoch,
            payload.EvaluationUtc);
        var staleAuthority = ProtectedDispositionAuthority.Create(
            stalePayload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(stalePayload));
        (Action Call, CanonicalReportIntegrityCode Code)[] cases =
        [
            (() => otherFixture.Kernel.SealReport(evaluation),
                CanonicalReportIntegrityCode.EvaluationContextMismatch),
            (() => kernel.SealReport(Clone(evaluation,
                runtime: foreignRuntime,
                verdict: contradictoryVerdict)),
                CanonicalReportIntegrityCode.EvaluationContextMismatch),
            (() => kernel.SealReport(Clone(evaluation, baseline: foreignCatalog)),
                CanonicalReportIntegrityCode.EvaluationContextMismatch),
            (() => kernel.SealReport(Clone(evaluation, baseline: foreignSession)),
                CanonicalReportIntegrityCode.EvaluationContextMismatch),
            (() => kernel.SealReport(Clone(evaluation, baseline: foreignClosure)),
                CanonicalReportIntegrityCode.EvaluationContextMismatch),
            (() => kernel.SealReport(Clone(evaluation,
                authority: foreignAuthority)),
                CanonicalReportIntegrityCode.EvaluationContextMismatch),
            (() => kernel.SealReport(Clone(evaluation,
                verdict: contradictoryVerdict)),
                CanonicalReportIntegrityCode.DimensionInconsistent),
            (() => kernel.SealReport(Clone(evaluation,
                authority: staleAuthority,
                evidence: stalePayload.EvidenceSetDigest)),
                CanonicalReportIntegrityCode.DimensionInconsistent),
            (() => kernel.SealReport(Clone(evaluation,
                outcome: Digest("stale-report-outcome"))),
                CanonicalReportIntegrityCode.DimensionInconsistent),
            (() => kernel.SealReport(Clone(evaluation,
                enforcement: EnforcementDecision.Block)),
                CanonicalReportIntegrityCode.DimensionInconsistent),
        ];
        Assert.All(cases, item => AssertReportCode(item.Call, item.Code));
        var acquisition = evaluation.Baseline.Acquisitions[0];
        Assert.Equal(AcquisitionStatus.Incomplete, ProjectAcquisitionStatus(
            null, [WithStatus(acquisition, AcquisitionStatus.Incomplete)]));
        Assert.Equal(AcquisitionStatus.Failed, ProjectAcquisitionStatus(null,
            [WithStatus(acquisition, AcquisitionStatus.Incomplete),
             WithStatus(acquisition, AcquisitionStatus.Failed)]));
        Assert.Same(
            CanonicalReportIntegrityCode.DigestMismatch,
            CanonicalReportIntegrityCode.Parse(
                "protocol.report.digest-mismatch"));
        Assert.False(CanonicalReportIntegrityCode.TryParse(
            "protocol.report.unknown",
            out _));
    }

    private static ProtectedPolicyEvaluation Clone(
        ProtectedPolicyEvaluation source,
        RuntimeQualificationBinding? runtime = null,
        CompleteCatalogEvaluation? baseline = null,
        ProtectedDispositionAuthority? authority = null,
        IEnumerable<ExtensionEvaluation>? extensions = null,
        IEnumerable<FindingDispositionResult>? dispositions = null,
        ExactSha256Digest? evidence = null,
        ExactSha256Digest? outcome = null,
        ConformanceVerdict? verdict = null,
        EnforcementDecision? enforcement = null) => new(
        runtime ?? source.RuntimeBinding,
        baseline ?? source.Baseline,
        source.ActiveExtensions,
        authority ?? source.DispositionAuthority,
        source.ProposedTransition,
        extensions ?? source.ExtensionEvaluations,
        dispositions ?? source.Dispositions,
        evidence ?? source.EvidenceSetDigest,
        outcome ?? source.OutcomeSetDigest,
        verdict ?? source.Verdict,
        enforcement ?? source.Enforcement);

    private static CompleteCatalogEvaluation CloneBaseline(
        CompleteCatalogEvaluation source,
        CompleteCatalogSnapshot? catalog = null,
        NamedExecutionProfile? profile = null,
        EvaluationClosure? closure = null) => new(
        catalog ?? source.Catalog,
        profile ?? source.Profile,
        closure ?? source.Closure,
        source.Acquisitions,
        source.Evaluations,
        source.HasKnownViolation,
        source.HasUnresolvedRequiredEvaluation,
        source.Verdict);

    private static SealedAcquisitionOutcome WithStatus(
        SealedAcquisitionOutcome source,
        AcquisitionStatus status) => new(
        source.Slot,
        source.Target,
        status,
        source.IsProjected,
        source.OutcomeDigest,
        source.Scope,
        source.RequirementAcquisition,
        source.ContextProof,
        source.Attempts,
        source.Failures);

    private static void AssertResourceBounds()
    {
        CanonicalReportCore.ValidatePreflightCounts(
            4_096,
            200_000,
            100_000,
            1_000_000);
        ValidateByteCount(null, 67_108_864);
        AssertReportCode(
            () => CanonicalReportCore.ValidatePreflightCounts(4_097, 0, 0, 0),
            CanonicalReportIntegrityCode.ResourceLimitExceeded);
        AssertReportCode(
            () => ValidateResourceCounts(null, 0, 200_001, 0, 0),
            CanonicalReportIntegrityCode.ResourceLimitExceeded);
        AssertReportCode(
            () => ValidateResourceCounts(null, 0, 0, 100_001, 0),
            CanonicalReportIntegrityCode.ResourceLimitExceeded);
        AssertReportCode(
            () => ValidateResourceCounts(null, 0, 0, 0, 1_000_001),
            CanonicalReportIntegrityCode.ResourceLimitExceeded);
        AssertReportCode(
            () => ValidateByteCount(null, 67_108_865),
            CanonicalReportIntegrityCode.ResourceLimitExceeded);
        AssertReportCode(
            () => CheckedAdd(null, long.MaxValue, 1),
            CanonicalReportIntegrityCode.ResourceLimitExceeded);
    }

    private static void AssertProtectedRedactionAndPrecedence()
    {
        var declaration = ExtensionDeclaration();
        var registration = WaiverEnabledRegistration();
        var fixture = CreateEvaluationFixture(registration, declaration);
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var unresolved = CreateEvaluation(fixture, active, out _, out _);
        var unresolvedReport = fixture.Kernel.SealReport(unresolved);
        Assert.Equal(RuleEvaluationStatus.NotEvaluated,
            Assert.Single(unresolved.ExtensionEvaluations).Status);
        Assert.True(unresolvedReport.HasUnresolvedRequiredEvaluation);
        Assert.Equal(ConformanceVerdict.Indeterminate, unresolvedReport.Verdict);
        var activeViolation = CreateEvaluation(
            fixture,
            active,
            out _,
            out _,
            attachProtectedInput: true);
        var extension = Assert.Single(activeViolation.ExtensionEvaluations);
        Assert.Equal(RuleEvaluationStatus.Violated, extension.Status);
        Assert.Single(extension.Findings);
        var activeRow = Assert.Single(activeViolation.Dispositions);
        Assert.Equal(FindingDisposition.ActiveViolation, activeRow.Disposition);
        Assert.Throws<ArgumentException>(() => new FindingDispositionResult(
            activeRow.Finding, FindingDisposition.Waived, null, null));
        Assert.All(
            new[]
            {
                Clone(activeViolation, dispositions: []),
                Clone(activeViolation, dispositions: [activeRow, activeRow]),
                Clone(activeViolation, extensions: [], dispositions: [activeRow]),
                Clone(activeViolation,
                    dispositions: Enumerable.Repeat(activeRow, 100_001),
                    outcome: Digest("stale-overlimit-outcome")),
            },
            invalid => AssertReportCode(
                () => fixture.Kernel.SealReport(invalid),
                CanonicalReportIntegrityCode.DimensionInconsistent));
        var finding = activeRow.Finding.Identity;
        var evaluationUtc = activeViolation.DispositionAuthority.Payload.EvaluationUtc;
        var authority = ReviewedAuthorityPermalink.Create(
            $"https://github.com/owner/repo/commit/{new string('0', 40)}");
        var waiver = WaiverDeclaration.Create(
            finding,
            WaiverTargetSelector.Parse($"evidence:{finding.EvidenceDigest.Value}"),
            WaiverScope.Parse("finding"),
            "authorization: bearer test-secret",
            "waiver-secret-owner",
            authority,
            fixture.Manifest.ManifestDigest,
            evaluationUtc.AddHours(-1),
            evaluationUtc.AddHours(1),
            finding.EvidenceDigest);
        var waived = Reevaluate(
            fixture,
            activeViolation,
            WaiverSnapshot.Create(
                Snapshot(
                    "protocol.waiver-snapshot/1\n",
                    [waiver.DeclarationDigest]),
                [waiver]),
            HistoricalDebtSnapshot.Create(
                Snapshot("protocol.historical-debt-snapshot/1\n", []),
                []));
        Assert.Equal(
            FindingDisposition.Waived,
            Assert.Single(waived.Dispositions).Disposition);
        var debt = HistoricalDebtEntry.Create(
            finding,
            fixture.Kernel.Catalog.ProtocolVersion,
            "debt-secret-owner",
            authority,
            "debt review text",
            finding.EvidenceDigest,
            Digest("report-debt-recurrence"),
            null,
            evaluationUtc.AddHours(1),
            fixture.Manifest.ManifestDigest);
        var historical = Reevaluate(
            fixture,
            activeViolation,
            WaiverSnapshot.Create(
                Snapshot("protocol.waiver-snapshot/1\n", []),
                []),
            HistoricalDebtSnapshot.Create(
                Snapshot(
                    "protocol.historical-debt-snapshot/1\n",
                    [debt.EntryDigest]),
                [debt]));
        Assert.Equal(
            FindingDisposition.HistoricalDebt,
            Assert.Single(historical.Dispositions).Disposition);

        var activeReport = fixture.Kernel.SealReport(activeViolation);
        var waiverReport = fixture.Kernel.SealReport(waived);
        var debtReport = fixture.Kernel.SealReport(historical);
        Assert.All(
            new[] { activeReport, waiverReport, debtReport },
            report =>
            {
                Assert.Equal(activeViolation.Verdict, report.Verdict);
                Assert.Equal(EnforcementDecision.ReportOnly, report.Enforcement);
                Assert.Equal(AcquisitionStatus.Complete, report.AcquisitionStatus);
                Assert.Contains(report.RuleEvaluations, row =>
                    row.Rule.ExtensionId?.Equals(declaration.ExtensionId) == true &&
                    row.Status.Equals(RuleEvaluationStatus.Violated));
            });
        var safeWaiver = Assert.Single(waiverReport.Dispositions);
        Assert.Equal(waiver.DeclarationDigest, safeWaiver.WaiverDeclarationDigest);
        Assert.Equal(waiver.DecisionAuthority, safeWaiver.WaiverDecisionAuthority);
        var safeDebt = Assert.Single(debtReport.Dispositions);
        Assert.Equal(debt.EntryDigest, safeDebt.DebtEntryDigest);
        Assert.Equal(debt.Authority, safeDebt.DebtAuthority);
        Assert.Equal(EnforcementDecision.Allow, ExpectedEnforcement(null,
            ConformanceVerdict.Conforming, EnforcementPhase.Prospective, []));
        Assert.Equal(EnforcementDecision.Block, ExpectedEnforcement(null,
            ConformanceVerdict.Indeterminate, EnforcementPhase.Prospective, []));
        Assert.Equal(EnforcementDecision.Block, ExpectedEnforcement(null,
            ConformanceVerdict.NonConforming, EnforcementPhase.Prospective,
            [activeRow]));
        Assert.Equal(EnforcementDecision.Allow, ExpectedEnforcement(null,
            ConformanceVerdict.NonConforming, EnforcementPhase.Prospective,
            [Assert.Single(waived.Dispositions)]));
        Assert.Equal(EnforcementDecision.Block, ExpectedEnforcement(null,
            ConformanceVerdict.NonConforming, EnforcementPhase.FullBlocking,
            [Assert.Single(historical.Dispositions)]));
        AssertExcluded(
            waiverReport.CanonicalBytes,
            "authorization: bearer test-secret",
            "waiver-secret-owner");
        AssertExcluded(
            debtReport.CanonicalBytes,
            "debt-secret-owner",
            "debt review text");
    }

    private static ExtensionEvaluatorRegistration WaiverEnabledRegistration()
    {
        var source = RepositoryPathRequiredExtensionEvaluator.CreateRegistration();
        var declaration = source.Declaration;
        return ExtensionEvaluatorRegistration.Create(
            ExtensionEvaluatorKindDeclaration.Create(
                declaration.EvaluatorKind,
                declaration.EvaluatorVersion,
                declaration.Component,
                declaration.Parameters,
                declaration.ApplicabilitySlotKeys,
                declaration.EvaluationSlotKeys,
                declaration.Findings,
                declaration.FailureCodes,
                waiverAllowed: true),
            source.Evaluator);
    }

    private static ProtectedPolicyEvaluation Reevaluate(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ProtectedPolicyEvaluation source,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot debt)
    {
        var payload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            source.ActiveExtensions.AuthoritySetDigest,
            waivers.SnapshotDigest,
            debt.SnapshotDigest,
            source.EvidenceSetDigest,
            source.ActiveExtensions.ActivationRecordDigest,
            source.ActiveExtensions.ActivationEpoch,
            source.DispositionAuthority.Payload.EvaluationUtc);
        return fixture.Kernel.EvaluateProtected(
            source.Baseline,
            source.Baseline.Closure,
            source.ActiveExtensions,
            source.ProposedTransition,
            waivers,
            debt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(payload),
            source.Baseline.Profile.Axes.EnforcementPhase);
    }

    private static void AssertExcluded(
        IReadOnlyList<byte> bytes,
        params string[] prohibited)
    {
        var retained = bytes.ToArray();
        Assert.All(prohibited, value => Assert.True(
            retained.AsSpan().IndexOf(Encoding.UTF8.GetBytes(value)) < 0));
    }

    [UnsafeAccessor(
        UnsafeAccessorKind.StaticMethod,
        Name = "ValidateResourceCounts")]
    private static extern void ValidateResourceCounts(
        CanonicalReportCore? owner,
        long acquisitions,
        long evaluations,
        long dispositions,
        long references);

    [UnsafeAccessor(
        UnsafeAccessorKind.StaticMethod,
        Name = "ValidateByteCount")]
    private static extern void ValidateByteCount(
        CanonicalReportCore? owner,
        long count);

    [UnsafeAccessor(UnsafeAccessorKind.Constructor)]
    private static extern CatalogVersion CreateCatalogVersion(int value);

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "CheckedAdd")]
    private static extern long CheckedAdd(
        ConformanceKernel? owner,
        long left,
        long right);

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "ExpectedEnforcement")]
    private static extern EnforcementDecision ExpectedEnforcement(
        ConformanceKernel? owner,
        ConformanceVerdict verdict,
        EnforcementPhase phase,
        IReadOnlyList<FindingDispositionResult> dispositions);

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "ProjectAcquisitionStatus")]
    private static extern AcquisitionStatus ProjectAcquisitionStatus(
        ConformanceKernel? owner,
        IReadOnlyList<SealedAcquisitionOutcome> rows);

    [UnsafeAccessor(UnsafeAccessorKind.Field, Name = "<Dispositions>k__BackingField")]
    private static extern ref IReadOnlyList<CanonicalFindingDisposition> Dispositions(
        CanonicalReportFrame owner);

    private sealed class CancelingList<T> : IReadOnlyList<T>
    {
        private readonly T _value;
        private readonly int _count;
        private readonly CancellationTokenSource _source;
        private readonly int _cancelAt;

        internal CancelingList(
            T value,
            int count,
            CancellationTokenSource source,
            int cancelAt) =>
            (_value, _count, _source, _cancelAt) =
            (value, count, source, cancelAt);

        public int Count => _count;
        public T this[int index] => index >= 0 && index < _count
            ? _value
            : throw new ArgumentOutOfRangeException(nameof(index));

        public IEnumerator<T> GetEnumerator()
        {
            for (var index = 0; index < _count; index++)
            {
                if (index == _cancelAt)
                {
                    _source.Cancel();
                }
                yield return _value;
            }
        }

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() =>
            GetEnumerator();
    }

    private static void AssertNoInputCarrier(EnforcementPhase phase)
    {
        var fixture = CreateEvaluationFixture(allNotApplicable: true);
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var source = fixture.Kernel.ResolveNamedProfile(
            "protocol.profile.consumer-provider-exact-commit-conformance-audit");
        var repository = Target(fixture, SurfaceKind.Repository, "repo");
        var profile = new NamedExecutionProfile(
            "protocol.profile.report-zero-input",
            ExecutionProfile.Create(
                source.Axes.SubjectRole,
                source.Axes.Operation,
                source.Axes.SnapshotKind,
                SurfaceSet.Create([SurfaceKind.Release]),
                phase),
            source.RuleIds,
            source.PlanningSession);
        var plan = fixture.Kernel.PlanApplicability(profile, repository, []);
        Assert.Empty(plan.Targets);
        Assert.Empty(plan.Instructions);
        Assert.Same(repository, plan.SubjectRepository);
        var closure = IssueClosure(fixture, plan);
        var baseline = fixture.Kernel.Evaluate(closure);
        var evidence = DebtEnforcementCore.ComputeEvidenceSetDigest(
            baseline,
            closure,
            active,
            []);
        var waivers = WaiverSnapshot.Create(
            Snapshot("protocol.waiver-snapshot/1\n", []),
            []);
        var debt = HistoricalDebtSnapshot.Create(
            Snapshot("protocol.historical-debt-snapshot/1\n", []),
            []);
        var payload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            waivers.SnapshotDigest,
            debt.SnapshotDigest,
            evidence,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            new DateTimeOffset(2026, 8, 22, 8, 0, 0, TimeSpan.Zero));
        var evaluation = fixture.Kernel.EvaluateProtected(
            baseline,
            closure,
            active,
            null,
            waivers,
            debt,
            payload,
            ProjectNeutralProtectedAuthorityFixture.CreateDispositionProof(payload),
            phase);
        var report = fixture.Kernel.SealReport(evaluation);
        Assert.Same(repository, report.SubjectRepository);
        Assert.Empty(report.Acquisitions);
        Assert.Equal(AcquisitionStatus.Complete, report.AcquisitionStatus);
        Assert.All(report.RuleEvaluations, row => Assert.Equal(
            RuleEvaluationStatus.Satisfied, row.Status));
        Assert.Equal(ConformanceVerdict.Conforming, report.Verdict);
        Assert.Equal(EnforcementDecision.Allow, report.Enforcement);
    }

    private static void AssertIssuedDimensionReports()
    {
        var fixture = CreateEvaluationFixture();
        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var cases = new[]
        {
            (AcquisitionStatus.Incomplete, EnforcementPhase.Prospective),
            (AcquisitionStatus.Failed, EnforcementPhase.FullBlocking),
        };
        foreach (var item in cases)
        {
            var evaluation = CreateEvaluation(
                fixture,
                active,
                out _,
                out _,
                phase: item.Item2, acquisitionStatus: item.Item1);
            var report = fixture.Kernel.SealReport(evaluation);
            Assert.Equal(item.Item1, report.AcquisitionStatus);
            Assert.Contains(report.RuleEvaluations, row =>
                row.Status.Equals(RuleEvaluationStatus.NotEvaluated));
            Assert.Equal(ConformanceVerdict.Indeterminate, report.Verdict);
            Assert.Equal(EnforcementDecision.Block, report.Enforcement);
        }
    }

    private static EvaluationClosure IssueClosure(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ApplicabilityPlan plan,
        AcquisitionStatus acquisitionStatus = null!)
    {
        acquisitionStatus ??= AcquisitionStatus.Complete;
        var applicabilityProofs = Proofs(
            fixture.Manifest,
            plan.Instructions,
            AcquisitionStatus.Complete);
        ActivationProof(plan.EvidenceSession).Authorize(
            applicabilityProofs.Observed.Cast<IAdmissionProofCandidate>()
                .Concat(applicabilityProofs.Failed));
        var applicability = fixture.Kernel.CloseApplicability(
            plan,
            AcquisitionProofSet.Create(
                applicabilityProofs.Observed,
                applicabilityProofs.Failed,
                []));
        var next = fixture.Kernel.PlanEvaluation(applicability);
        if (next is EvaluationClosure terminal)
        {
            return terminal;
        }

        var evaluationPlan = Assert.IsType<EvaluationPlan>(next);
        var evaluationProofs = Proofs(
            fixture.Manifest,
            evaluationPlan.Instructions,
            acquisitionStatus);
        ActivationProof(evaluationPlan.EvidenceSession).Authorize(
            evaluationProofs.Observed.Cast<IAdmissionProofCandidate>()
                .Concat(evaluationProofs.Failed));
        return Assert.IsType<EvaluationClosure>(fixture.Kernel.AdvanceEvaluation(
            evaluationPlan,
            AcquisitionProofSet.Create(
                evaluationProofs.Observed,
                evaluationProofs.Failed,
                [])));
    }

    private static (
        CObservedQualificationProof[] Observed,
        CFailedAttemptProof[] Failed) Proofs(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<AcquisitionInstruction> instructions,
        AcquisitionStatus status) => status.Equals(AcquisitionStatus.Failed)
        ? ([], instructions.Select(instruction => CFailedAttemptProof.Create(
            manifest, instruction)).ToArray())
        : (instructions.Select(instruction => CObservedQualificationProof.Create(
            manifest,
            instruction,
            complete: status.Equals(AcquisitionStatus.Complete))).ToArray(), []);

    private static ContractSliceCActivationProof ActivationProof(
        IPlanBoundEvidenceSession evidenceSession) =>
        Assert.IsType<ContractSliceCActivationProof>(
            Assert.IsType<KernelPlanningSession>(evidenceSession).ActivationProof);

    private static AcquisitionTarget Target(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        SurfaceKind surface,
        string source) => AcquisitionTarget.Create(
        "repo",
        source,
        surface,
        SnapshotKind.ExactCommit,
        fixture.Manifest.SourceCommit);

    private static ExactSha256Digest Snapshot(
        string prefix,
        IReadOnlyList<ExactSha256Digest> rows) =>
        ProtectedPolicyFrame.Hash(prefix, stream =>
        {
            ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Count));
            foreach (var row in rows)
            {
                ProtectedPolicyFrame.Digest(stream, row);
            }
        });

    private static ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture
        CreateEvaluationFixture(
            ExtensionEvaluatorRegistration? registration = null,
            ExtensionRuleDeclaration? declaration = null,
            bool allNotApplicable = false)
    {
        if ((registration is null) != (declaration is null))
        {
            throw new ArgumentException("Registration and declaration must pair.");
        }

        var applicabilityByRule = allNotApplicable
            ? new[] { 3, 4 }.ToDictionary(
                static index => $"RULE-{index:0000}",
                static _ => new Func<RuleApplicabilityInput, ApplicabilityIntent>(
                    static _ => ApplicabilityIntent.Applicable([])),
                StringComparer.Ordinal)
            : null;
        var source = ContractSliceCApplicabilityClosureTests.CreateFixture(
            evaluationReady: true,
            evaluationByRule: new Dictionary<string,
                Func<RuleEvaluationInput, EvaluationIntent>>(
                    StringComparer.Ordinal),
            applicabilityByRule: applicabilityByRule);
        var manifest = AddPolicyArtifact(source.Manifest);
        var kernel = ConformanceKernel.Activate(
            manifest,
            source.Export,
            new ContractSliceCActivationProof(manifest, source.Export),
            predecessor: null);
        var registrations = registration is null
            ? Array.Empty<ExtensionEvaluatorRegistration>()
            : [registration];
        var declarations = declaration is null
            ? Array.Empty<ExtensionRuleDeclaration>()
            : [declaration];
        var policy = ProjectNeutralProtectedAuthorityFixture.CreateTestPolicy(
            registrations);
        var policyBlobDigest = Digest("report-extension-policy-blob");
        var snapshot = ExtensionCatalogSnapshot.Create(
            "repo",
            policyBlobDigest,
            ExtensionCatalogSnapshot.ComputeDigest(
                "repo",
                policyBlobDigest,
                declarations),
            declarations);
        var authorityRecord = Digest("report-authority-record");
        var activation = ProtectedExtensionActivationPayload.Create(
            manifest.ManifestDigest,
            "repo",
            policyBlobDigest,
            Digest("report-authority-set"),
            authorityRecord,
            Digest("report-previous-activation"),
            Digest("report-closure-evidence"),
            snapshot.SnapshotDigest,
            manifest.SourceCommit,
            1);
        var waiverPolicy = BaselineWaiverPolicy(
            kernel.Catalog,
            manifest.ManifestDigest);
        var pack = PackBinding(manifest, policy, waiverPolicy);
        return new ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture(
            kernel,
            manifest,
            snapshot,
            activation,
            ProjectNeutralProtectedAuthorityFixture.CreateActivationProof(activation),
            pack,
            ProjectNeutralProtectedAuthorityFixture.CreatePackProof(pack, activation),
            policy,
            authorityRecord);
    }

    private static FinalizedPolicyManifest AddPolicyArtifact(
        FinalizedPolicyManifest source) =>
        ContractSliceCActivationTests.CreateSyntheticManifest(
            source.AuthorityKind,
            source.SourceCommit,
            Digest("report-authority-manifest"),
            source.SchemaRegistry,
            source.ActivationProofContract,
            source.ArtifactFiles.Append(ArtifactFileBinding.Create(
                    "MeAndAI.Protocol.Policy.dll",
                    1,
                    Digest("report-policy-artifact")))
                .OrderBy(static row => row.FileName, StringComparer.Ordinal)
                .ToArray(),
            source.Components,
            source.Slice,
            source.CompleteCatalog);

    private static BaselineWaiverPolicySnapshot BaselineWaiverPolicy(
        CompleteCatalogSnapshot catalog,
        ExactSha256Digest manifestDigest)
    {
        var rows = catalog.Rules.Select(rule =>
            BaselineRuleWaiverPolicy.Create(
                rule.RuleId,
                rule.RuleRevision,
                waiverAllowed: false)).ToArray();
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
        var keysByFile = policy.Components.GroupBy(
                static component => $"{component.AssemblyName}.dll",
                StringComparer.Ordinal)
            .ToDictionary(
                static group => group.Key,
                static group => group.Select(static row => row.ComponentKey)
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

    private static ExactSha256Digest Digest(string value) =>
        ExactSha256Digest.FromHashBytes(
            SHA256.HashData(Encoding.UTF8.GetBytes(value)));

    private static ExactSha256Digest Repeated(byte value) =>
        ExactSha256Digest.Parse(Convert.ToHexString(
            Enumerable.Repeat(value, 32).ToArray()).ToLowerInvariant());

    private static void AssertReportCode(
        Action action,
        CanonicalReportIntegrityCode expected)
    {
        var error = Assert.Throws<CanonicalReportIntegrityException>(action);
        Assert.Equal(expected, error.Code);
        Assert.Equal(expected.Value, error.Message);
    }
}
