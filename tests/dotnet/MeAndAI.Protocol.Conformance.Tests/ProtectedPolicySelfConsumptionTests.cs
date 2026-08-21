using System.Security.Cryptography;
using System.Runtime.CompilerServices;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicySelfConsumptionTests
{
    [Fact]
    [Trait("Scenario", "TEST-0211")]
    public void Rejects_candidate_only_and_unreviewed_differential_authority()
    {
        var fixture = CreateFixture();
        var candidateFixture = CreateCandidateFixture(fixture);
        var predecessorActive = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var candidateActive = candidateFixture.Kernel.ActivateExtensions(
            candidateFixture.Snapshot,
            candidateFixture.ActivationPayload,
            candidateFixture.ActivationProof,
            candidateFixture.PackBinding,
            candidateFixture.PackProof,
            candidateFixture.Policy);
        var baseline = Baseline(fixture);
        var candidateBaseline = Baseline(candidateFixture);
        var anchor = CurrentAnchor(predecessorActive);
        var predecessor = Runtime(baseline, predecessorActive, anchor);
        var candidate = Runtime(candidateBaseline, candidateActive, anchor);
        Assert.NotEqual(predecessor.BindingDigest, candidate.BindingDigest);
        Assert.NotEqual(predecessor.SourceCommit, candidate.SourceCommit);
        Assert.NotEqual(predecessor.ManifestDigest, candidate.ManifestDigest);
        Assert.NotEqual(
            predecessor.PolicyPackBindingDigest,
            candidate.PolicyPackBindingDigest);
        Assert.NotEqual(
            predecessor.RuntimeArtifactDigest,
            candidate.RuntimeArtifactDigest);

        var predecessorOverlap = Evaluation(
            fixture,
            baseline,
            predecessorActive,
            predecessor,
            Digest("predecessor-overlap-evidence"));
        var candidateOverlap = Evaluation(
            candidateFixture,
            candidateBaseline,
            candidateActive,
            candidate,
            Digest("candidate-overlap-evidence"));
        var independent = Evaluation(
            candidateFixture,
            candidateBaseline,
            candidateActive,
            candidate,
            Digest("independent-evidence"));
        Assert.NotEqual(
            predecessorOverlap.OutcomeSetDigest,
            candidateOverlap.OutcomeSetDigest);
        Assert.Equal(candidateOverlap.OutcomeSetDigest, independent.OutcomeSetDigest);

        var reviewed = ReviewedDifferences(predecessorOverlap, candidateOverlap);
        Assert.NotEmpty(reviewed);
        var reviewedDifferenceSetDigest =
            SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(reviewed);
        var payload = Payload(
            predecessorActive,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            independent,
            anchor,
            reviewedDifferenceSetDigest,
            independent.OutcomeSetDigest);
        var proof = ProjectNeutralProtectedAuthorityFixture
            .CreatePredecessorProof(payload);
        var independentInput = IndependentInput(payload, independent);
        var qualification = fixture.Kernel.QualifyCandidate(
            payload,
            proof,
            candidate,
            predecessorActive,
            predecessorOverlap,
            candidateOverlap,
            independentInput,
            reviewed);

        Assert.True(qualification.IsQualified);
        Assert.False(qualification.HasUnexplainedDifference);
        Assert.Equal(reviewed, qualification.ReviewedDifferences);
        Assert.Equal(payload.PayloadDigest, qualification.Predecessor.Payload.PayloadDigest);
        Assert.Same(independentInput, qualification.CandidateIndependentQualification.Input);

        var semanticMismatchPayload = Payload(
            predecessorActive,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            independent,
            anchor,
            reviewedDifferenceSetDigest,
            Digest("trusted-independent-outcome"));
        var semanticMismatch = fixture.Kernel.QualifyCandidate(
            semanticMismatchPayload,
            ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                semanticMismatchPayload),
            candidate,
            predecessorActive,
            predecessorOverlap,
            candidateOverlap,
            IndependentInput(semanticMismatchPayload, independent),
            reviewed);
        Assert.False(semanticMismatch.IsQualified);
        Assert.True(semanticMismatch.HasUnexplainedDifference);

        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                predecessor,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                independentInput,
                reviewed),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);

        var wrongAnchorPayload = Payload(
            predecessorActive,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            independent,
            Digest("wrong-current-anchor"),
            reviewedDifferenceSetDigest,
            independent.OutcomeSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                wrongAnchorPayload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    wrongAnchorPayload),
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                independentInput,
                reviewed),
            ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);

        var unreviewedPayload = Payload(
            predecessorActive,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            independent,
            anchor,
            SelfConsumptionCore.ComputeReviewedDifferenceSetDigest([]),
            independent.OutcomeSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                unreviewedPayload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    unreviewedPayload),
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(unreviewedPayload, independent),
                []),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);

        var extra = ReviewedOutcomeDifference.Create(
            ProtectedOutcomeIdentity.Global(ProtectedOutcomeKind.Verdict),
            Digest("stale-predecessor-outcome"),
            Digest("stale-candidate-outcome"),
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('1', 40)}"),
            Digest("review-evidence"));
        var extraRows = reviewed.Append(extra).ToArray();
        var extraPayload = Payload(
            predecessorActive,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            independent,
            anchor,
            SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(extraRows),
            independent.OutcomeSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                extraPayload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    extraPayload),
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(extraPayload, independent),
                extraRows),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);

        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    semanticMismatchPayload),
                predecessor,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                independentInput,
                new ThrowingReviewedRows()),
            ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);

        var predecessorRuntimeMix = Evaluation(
            fixture,
            baseline,
            predecessorActive,
            candidate,
            predecessorOverlap.EvidenceSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                predecessorActive,
                predecessorRuntimeMix,
                candidateOverlap,
                independentInput,
                reviewed),
            ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                candidateActive,
                predecessorOverlap,
                candidateOverlap,
                independentInput,
                reviewed),
            ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);

        var wrongCandidateAnchor = RuntimeQualificationBinding.Create(
            candidate.ProtocolVersion,
            candidate.SourceCommit,
            candidate.ManifestDigest,
            candidate.CatalogDigest,
            candidate.PolicyPackBindingDigest,
            candidate.RuntimeArtifactDigest,
            Digest("candidate-anchor-mutation"));
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                wrongCandidateAnchor,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                independentInput,
                reviewed),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);
        var independentRuntimeMix = Evaluation(
            candidateFixture,
            candidateBaseline,
            candidateActive,
            predecessor,
            independent.EvidenceSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(payload, independentRuntimeMix),
                reviewed),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);
        var mixedActive = new ActivatedExtensionPolicy(
            candidateActive.Snapshot,
            candidateActive.ActivationPayload,
            candidateActive.PolicyPackBinding,
            candidateActive.Policy,
            candidateActive.AuthoritySetDigest,
            candidateActive.ActivationRecordDigest,
            candidateActive.ActivationEpoch + 1);
        var mixedOverlap = Evaluation(
            candidateFixture,
            candidateBaseline,
            mixedActive,
            candidate,
            candidateOverlap.EvidenceSetDigest);
        var mixedIndependent = Evaluation(
            candidateFixture,
            candidateBaseline,
            mixedActive,
            candidate,
            independent.EvidenceSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                predecessorActive,
                predecessorOverlap,
                mixedOverlap,
                IndependentInput(payload, mixedIndependent),
                reviewed),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);
        var wrongFixtureInput = CandidateIndependentQualificationInput.Create(
            "protocol.fixture.independent-other",
            payload.IndependentFixtureSetVersion,
            payload.IndependentFixtureSetDigest,
            payload.IndependentExpectedOutcomeSetDigest,
            independent);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                wrongFixtureInput,
                reviewed),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);

        var wrongReviewedPayload = Payload(
            predecessorActive,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            independent,
            anchor,
            Digest("wrong-reviewed-difference-set"),
            independent.OutcomeSetDigest);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                wrongReviewedPayload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    wrongReviewedPayload),
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(wrongReviewedPayload, independent),
                reviewed),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        var mutatedRows = reviewed.ToArray();
        mutatedRows[0] = ReviewedOutcomeDifference.Create(
            mutatedRows[0].Outcome,
            mutatedRows[0].PredecessorOutcomeDigest,
            mutatedRows[0].CandidateOutcomeDigest,
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('3', 40)}"),
            Digest("mutated-review-evidence"));
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                independentInput,
                mutatedRows),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        AssertCode(
            () => fixture.Kernel.QualifyCandidate(
                semanticMismatchPayload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    semanticMismatchPayload),
                candidate,
                predecessorActive,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(semanticMismatchPayload, independent),
                mutatedRows),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        AssertCode(
            () => SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(
                [reviewed[0], reviewed[0]]),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        Assert.Throws<ArgumentNullException>(() => fixture.Kernel.QualifyCandidate(
            null!, proof, candidate, predecessorActive, predecessorOverlap,
            candidateOverlap, independentInput, reviewed));
        Assert.Throws<ArgumentNullException>(() => fixture.Kernel.QualifyCandidate(
            payload, proof, candidate, predecessorActive, predecessorOverlap,
            candidateOverlap, independentInput, null!));
        AssertRemainingTrustMutations(
            fixture.Kernel,
            payload,
            proof,
            predecessor,
            candidate,
            predecessorActive,
            predecessorOverlap,
            candidateOverlap,
            independentInput,
            reviewed);
        AssertCanonicalSelfFrames(independent);
        AssertReviewedResourceBounds(payload);
    }

    private static void AssertRemainingTrustMutations(
        ConformanceKernel kernel,
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof,
        RuntimeQualificationBinding predecessor,
        RuntimeQualificationBinding candidate,
        ActivatedExtensionPolicy active,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        CandidateIndependentQualificationInput independentInput,
        IReadOnlyList<ReviewedOutcomeDifference> reviewed)
    {
        var independent = independentInput.Evaluation;
        foreach (var mutated in new[]
        {
            Payload(active, predecessor, candidate, predecessorOverlap,
                candidateOverlap, independent, payload.CurrentTrustAnchorDigest,
                payload.ReviewedDifferenceSetDigest,
                payload.IndependentExpectedOutcomeSetDigest,
                predecessorEvidence: Digest("mutated-predecessor-evidence")),
            Payload(active, predecessor, candidate, predecessorOverlap,
                candidateOverlap, independent, payload.CurrentTrustAnchorDigest,
                payload.ReviewedDifferenceSetDigest,
                payload.IndependentExpectedOutcomeSetDigest,
                predecessorOutcome: Digest("mutated-predecessor-outcome")),
        })
        {
            AssertCode(
                () => kernel.QualifyCandidate(
                    mutated,
                    ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                        mutated),
                    candidate,
                    active,
                    predecessorOverlap,
                    candidateOverlap,
                    IndependentInput(mutated, independent),
                    new ThrowingReviewedRows()),
                ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);
        }

        foreach (var mutated in new[]
        {
            Payload(active, predecessor, candidate, predecessorOverlap,
                candidateOverlap, independent, payload.CurrentTrustAnchorDigest,
                payload.ReviewedDifferenceSetDigest,
                payload.IndependentExpectedOutcomeSetDigest,
                candidateEvidence: Digest("mutated-candidate-evidence")),
            Payload(active, predecessor, candidate, predecessorOverlap,
                candidateOverlap, independent, payload.CurrentTrustAnchorDigest,
                payload.ReviewedDifferenceSetDigest,
                payload.IndependentExpectedOutcomeSetDigest,
                independentEvidence: Digest("mutated-independent-evidence")),
        })
        {
            AssertCode(
                () => kernel.QualifyCandidate(
                    mutated,
                    ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                        mutated),
                    candidate,
                    active,
                    predecessorOverlap,
                    candidateOverlap,
                    IndependentInput(mutated, independent),
                    new ThrowingReviewedRows()),
                ProtectedPolicyIntegrityCode.CandidateSelfCertification);
        }

        var wrongExpectedInput = CandidateIndependentQualificationInput.Create(
            payload.IndependentFixtureSetKey,
            payload.IndependentFixtureSetVersion,
            payload.IndependentFixtureSetDigest,
            Digest("caller-selected-independent-expected"),
            independent);
        AssertCode(
            () => kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                active,
                predecessorOverlap,
                candidateOverlap,
                wrongExpectedInput,
                new ThrowingReviewedRows()),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);

        var sharedEvidenceIndependent = WithEvidence(
            independent,
            candidateOverlap.EvidenceSetDigest);
        var sharedEvidencePayload = Payload(
            active,
            predecessor,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            sharedEvidenceIndependent,
            payload.CurrentTrustAnchorDigest,
            payload.ReviewedDifferenceSetDigest,
            payload.IndependentExpectedOutcomeSetDigest,
            candidateEvidence: candidateOverlap.EvidenceSetDigest,
            independentEvidence: candidateOverlap.EvidenceSetDigest);
        AssertCode(
            () => kernel.QualifyCandidate(
                sharedEvidencePayload,
                ProjectNeutralProtectedAuthorityFixture.CreatePredecessorProof(
                    sharedEvidencePayload),
                candidate,
                active,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(sharedEvidencePayload, sharedEvidenceIndependent),
                new ThrowingReviewedRows()),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);

        var clonedActive = new ActivatedExtensionPolicy(
            candidateOverlap.ActiveExtensions.Snapshot,
            candidateOverlap.ActiveExtensions.ActivationPayload,
            candidateOverlap.ActiveExtensions.PolicyPackBinding,
            candidateOverlap.ActiveExtensions.Policy,
            candidateOverlap.ActiveExtensions.AuthoritySetDigest,
            candidateOverlap.ActiveExtensions.ActivationRecordDigest,
            candidateOverlap.ActiveExtensions.ActivationEpoch);
        var clonedIndependent = WithActive(independent, clonedActive);
        AssertCode(
            () => kernel.QualifyCandidate(
                payload,
                proof,
                candidate,
                active,
                predecessorOverlap,
                candidateOverlap,
                IndependentInput(payload, clonedIndependent),
                new ThrowingReviewedRows()),
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);

        AssertReviewedMutation(
            kernel, payload, proof, candidate, active, predecessorOverlap,
            candidateOverlap, independentInput, reviewed,
            row => ReviewedOutcomeDifference.Create(
                row.Outcome,
                Digest("stale-predecessor-entry"),
                row.CandidateOutcomeDigest,
                row.ChangeAuthority,
                row.QualificationEvidenceDigest));
        AssertReviewedMutation(
            kernel, payload, proof, candidate, active, predecessorOverlap,
            candidateOverlap, independentInput, reviewed,
            row => ReviewedOutcomeDifference.Create(
                row.Outcome,
                row.PredecessorOutcomeDigest,
                Digest("stale-candidate-entry"),
                row.ChangeAuthority,
                row.QualificationEvidenceDigest));
        AssertReviewedMutation(
            kernel, payload, proof, candidate, active, predecessorOverlap,
            candidateOverlap, independentInput, reviewed,
            row => ReviewedOutcomeDifference.Create(
                row.Outcome,
                row.PredecessorOutcomeDigest,
                row.CandidateOutcomeDigest,
                ReviewedAuthorityPermalink.Create(
                    $"https://github.com/owner/repo/commit/{new string('4', 40)}"),
                row.QualificationEvidenceDigest));
        AssertReviewedMutation(
            kernel, payload, proof, candidate, active, predecessorOverlap,
            candidateOverlap, independentInput, reviewed,
            row => ReviewedOutcomeDifference.Create(
                row.Outcome,
                row.PredecessorOutcomeDigest,
                row.CandidateOutcomeDigest,
                row.ChangeAuthority,
                Digest("mutated-qualification-evidence")));
    }

    private static void AssertReviewedMutation(
        ConformanceKernel kernel,
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof,
        RuntimeQualificationBinding candidate,
        ActivatedExtensionPolicy active,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        CandidateIndependentQualificationInput independentInput,
        IReadOnlyList<ReviewedOutcomeDifference> reviewed,
        Func<ReviewedOutcomeDifference, ReviewedOutcomeDifference> mutate)
    {
        var rows = reviewed.ToArray();
        rows[0] = mutate(rows[0]);
        AssertCode(
            () => kernel.QualifyCandidate(
                payload, proof, candidate, active, predecessorOverlap,
                candidateOverlap, independentInput, rows),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
    }

    private static ProtectedPolicyEvaluation WithActive(
        ProtectedPolicyEvaluation source,
        ActivatedExtensionPolicy active) => new(
        source.RuntimeBinding,
        source.Baseline,
        active,
        source.DispositionAuthority,
        source.ProposedTransition,
        source.ExtensionEvaluations,
        source.Dispositions,
        source.EvidenceSetDigest,
        source.OutcomeSetDigest,
        source.Verdict,
        source.Enforcement);

    private static ProtectedPolicyEvaluation WithEvidence(
        ProtectedPolicyEvaluation source,
        ExactSha256Digest evidence) => new(
        source.RuntimeBinding,
        source.Baseline,
        source.ActiveExtensions,
        source.DispositionAuthority,
        source.ProposedTransition,
        source.ExtensionEvaluations,
        source.Dispositions,
        evidence,
        source.OutcomeSetDigest,
        source.Verdict,
        source.Enforcement);

    private static ProtectedPolicyEvaluation Evaluation(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        CompleteCatalogEvaluation baseline,
        ActivatedExtensionPolicy active,
        RuntimeQualificationBinding runtime,
        ExactSha256Digest evidence)
    {
        var authorityPayload = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            active.AuthoritySetDigest,
            active.PolicyPackBinding.BaselineWaiverPolicy.SnapshotDigest,
            Digest("debt-snapshot"),
            evidence,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            new DateTimeOffset(2026, 8, 21, 0, 0, 0, TimeSpan.Zero));
        var authorityProof = ProjectNeutralProtectedAuthorityFixture
            .CreateDispositionProof(authorityPayload);
        Assert.True(active.Policy.DispositionVerifier.Verify(
            authorityPayload,
            authorityProof));
        var authority = ProtectedDispositionAuthority.Create(
            authorityPayload,
            authorityProof);
        var draft = new ProtectedPolicyEvaluation(
            runtime,
            baseline,
            active,
            authority,
            null,
            [],
            [],
            evidence,
            Digest("outcome-placeholder"),
            baseline.Verdict,
            EnforcementDecision.Allow);
        return new ProtectedPolicyEvaluation(
            runtime,
            baseline,
            active,
            authority,
            null,
            [],
            [],
            evidence,
            DebtEnforcementCore.ProjectOutcomeSet(draft).Digest,
            baseline.Verdict,
            EnforcementDecision.Allow);
    }

    private static CompleteCatalogEvaluation Baseline(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture)
    {
        var profile = fixture.Kernel.ResolveNamedProfile(
            "protocol.profile.consumer-provider-exact-commit-conformance-audit");
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
        var closure = Assert.IsType<EvaluationClosure>(
            fixture.Kernel.AdvanceEvaluation(
                evaluationPlan,
                AcquisitionProofSet.Create(evaluationProofs, [], [])));
        return fixture.Kernel.Evaluate(closure);
    }

    private static RuntimeQualificationBinding Runtime(
        CompleteCatalogEvaluation baseline,
        ActivatedExtensionPolicy active,
        ExactSha256Digest anchor)
    {
        var runtimeArtifact = active.PolicyPackBinding.Artifacts.Single(row =>
            string.Equals(
                row.ArtifactKey,
                "protocol.artifact.conformance-runtime",
                StringComparison.Ordinal));
        return RuntimeQualificationBinding.Create(
            baseline.Catalog.ProtocolVersion,
            active.ActivationPayload.ActivatedTargetCommit,
            baseline.Catalog.ManifestDigest,
            baseline.Catalog.CompleteInventoryDigest,
            active.PolicyPackBinding.BindingDigest,
            runtimeArtifact.FileDigest,
            anchor);
    }

    private static ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture
        CreateFixture()
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
        var policy = ProjectNeutralProtectedAuthorityFixture.CreateTestPolicy([]);
        var policyBlobDigest = Digest("self-consumption-policy-blob");
        var snapshot = ExtensionCatalogSnapshot.Create(
            "repo",
            policyBlobDigest,
            ExtensionCatalogSnapshot.ComputeDigest(
                "repo",
                policyBlobDigest,
                []),
            []);
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
        var packBinding = PackBinding(
            manifest,
            policy,
            BaselineWaiverPolicy(
                kernel.Catalog,
                manifest.ManifestDigest,
                waiverFirst: false));
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

    private static ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture
        CreateCandidateFixture(
            ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture predecessor)
    {
        var source = ContractSliceCApplicabilityClosureTests.CreateFixture(
            evaluationReady: true,
            evaluationByRule: new Dictionary<string,
                Func<RuleEvaluationInput, EvaluationIntent>>(
                    StringComparer.Ordinal));
        var artifacts = source.Manifest.ArtifactFiles.Select(row =>
                string.Equals(
                    row.FileName,
                    "MeAndAI.Protocol.Conformance.dll",
                    StringComparison.Ordinal)
                    ? ArtifactFileBinding.Create(
                        row.FileName,
                        row.ByteLength,
                        Digest("candidate-runtime-artifact"))
                    : row)
            .Append(ArtifactFileBinding.Create(
                "MeAndAI.Protocol.Policy.dll",
                1,
                Digest("policy-artifact")))
            .OrderBy(static row => row.FileName, StringComparer.Ordinal)
            .ToArray();
        var sourceCommit = new string('c', 40);
        var manifest = ContractSliceCActivationTests.CreateSyntheticManifest(
            source.Manifest.AuthorityKind,
            sourceCommit,
            Digest("candidate-protected-authority-manifest"),
            source.Manifest.SchemaRegistry,
            source.Manifest.ActivationProofContract,
            artifacts,
            source.Manifest.Components,
            source.Manifest.Slice,
            source.Manifest.CompleteCatalog);
        var kernel = ConformanceKernel.Activate(
            manifest,
            source.Export,
            new ContractSliceCActivationProof(manifest, source.Export),
            predecessor: null);
        var activationPayload = ProtectedExtensionActivationPayload.Create(
            manifest.ManifestDigest,
            predecessor.Snapshot.RepositoryNamespace,
            predecessor.Snapshot.PolicyBlobDigest,
            predecessor.ActivationPayload.AuthoritySetDigest,
            predecessor.AuthorityRecordDigest,
            predecessor.ActivationPayload.PreviousActivationRecordDigest,
            predecessor.ActivationPayload.ClosureEvidenceDigest,
            predecessor.Snapshot.SnapshotDigest,
            sourceCommit,
            predecessor.ActivationPayload.ActivationEpoch);
        var pack = PackBinding(
            manifest,
            predecessor.Policy,
            BaselineWaiverPolicy(
                kernel.Catalog,
                manifest.ManifestDigest,
                waiverFirst: true));
        return new ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture(
            kernel,
            manifest,
            predecessor.Snapshot,
            activationPayload,
            ProjectNeutralProtectedAuthorityFixture.CreateActivationProof(
                activationPayload),
            pack,
            ProjectNeutralProtectedAuthorityFixture.CreatePackProof(
                pack,
                activationPayload),
            predecessor.Policy,
            predecessor.AuthorityRecordDigest);
    }

    private static FinalizedPolicyManifest AddPolicyArtifact(
        FinalizedPolicyManifest source)
    {
        var artifacts = source.ArtifactFiles.Append(ArtifactFileBinding.Create(
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
        bool waiverFirst)
    {
        var rows = catalog.Rules.Select((rule, index) =>
            BaselineRuleWaiverPolicy.Create(
                rule.RuleId,
                rule.RuleRevision,
                waiverAllowed: waiverFirst && index == 0)).ToArray();
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
        return BaselineWaiverPolicySnapshot.Create(manifestDigest, digest, rows);
    }

    private static ProtectedPolicyPackBinding PackBinding(
        FinalizedPolicyManifest manifest,
        ExtensionPolicyPackExport policy,
        BaselineWaiverPolicySnapshot waiverPolicy)
    {
        var keysByFile = policy.Components.GroupBy(
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

    private static PredecessorTrustPayload Payload(
        ActivatedExtensionPolicy active,
        RuntimeQualificationBinding predecessor,
        RuntimeQualificationBinding candidate,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        ProtectedPolicyEvaluation independent,
        ExactSha256Digest anchor,
        ExactSha256Digest reviewedDifferenceSetDigest,
        ExactSha256Digest independentExpectedOutcomeSetDigest,
        ExactSha256Digest? predecessorEvidence = null,
        ExactSha256Digest? predecessorOutcome = null,
        ExactSha256Digest? candidateEvidence = null,
        ExactSha256Digest? independentEvidence = null) =>
        PredecessorTrustPayload.Create(
            predecessor,
            anchor,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            "protocol.fixture.overlap",
            "1",
            Digest("overlap-fixture"),
            predecessorEvidence ?? predecessorOverlap.EvidenceSetDigest,
            candidateEvidence ?? candidateOverlap.EvidenceSetDigest,
            predecessorOutcome ?? predecessorOverlap.OutcomeSetDigest,
            candidate.BindingDigest,
            reviewedDifferenceSetDigest,
            "protocol.fixture.independent",
            "1",
            Digest("independent-fixture"),
            independentEvidence ?? independent.EvidenceSetDigest,
            independentExpectedOutcomeSetDigest);

    private static CandidateIndependentQualificationInput IndependentInput(
        PredecessorTrustPayload payload,
        ProtectedPolicyEvaluation evaluation) =>
        CandidateIndependentQualificationInput.Create(
            payload.IndependentFixtureSetKey,
            payload.IndependentFixtureSetVersion,
            payload.IndependentFixtureSetDigest,
            payload.IndependentExpectedOutcomeSetDigest,
            evaluation);

    private static ReviewedOutcomeDifference[] ReviewedDifferences(
        ProtectedPolicyEvaluation predecessor,
        ProtectedPolicyEvaluation candidate)
    {
        var before = DebtEnforcementCore.ProjectOutcomeSet(predecessor).Entries;
        var after = DebtEnforcementCore.ProjectOutcomeSet(candidate).Entries;
        Assert.Equal(
            before.Select(static row => row.Key),
            after.Select(static row => row.Key));
        return before.Zip(after)
            .Where(static pair => !pair.First.Value.Equals(pair.Second.Value))
            .Select(pair => ReviewedOutcomeDifference.Create(
                OutcomeIdentity(pair.First.Key, predecessor),
                pair.First.Value,
                pair.Second.Value,
                ReviewedAuthorityPermalink.Create(
                    $"https://github.com/owner/repo/commit/{new string('2', 40)}"),
                Digest($"review:{pair.First.Key}")))
            .ToArray();
    }

    private static ProtectedOutcomeIdentity OutcomeIdentity(
        string key,
        ProtectedPolicyEvaluation evaluation)
    {
        foreach (var row in evaluation.Baseline.Evaluations)
        {
            var identity = ProtectedOutcomeIdentity.ForRule(
                PolicyRuleIdentity.Baseline(row.RuleId, row.RuleRevision));
            if (string.Equals(identity.RowKey, key, StringComparison.Ordinal))
            {
                return identity;
            }
        }
        foreach (var row in evaluation.ExtensionEvaluations)
        {
            var identity = ProtectedOutcomeIdentity.ForRule(
                PolicyRuleIdentity.Extension(row.ExtensionId, row.RuleRevision));
            if (string.Equals(identity.RowKey, key, StringComparison.Ordinal))
            {
                return identity;
            }
        }
        return key switch
        {
            "global:dispositions" => ProtectedOutcomeIdentity.Global(
                ProtectedOutcomeKind.Dispositions),
            "global:verdict" => ProtectedOutcomeIdentity.Global(
                ProtectedOutcomeKind.Verdict),
            "global:enforcement" => ProtectedOutcomeIdentity.Global(
                ProtectedOutcomeKind.Enforcement),
            _ => throw new InvalidOperationException(
                $"Unknown protected outcome row '{key}'."),
        };
    }

    private static ExactSha256Digest CurrentAnchor(
        ActivatedExtensionPolicy active) => ProtectedPolicyFrame.Hash(
        "protocol.protected-current-trust-anchor/1\n",
        stream =>
        {
            ProtectedPolicyFrame.Digest(
                stream,
                active.Policy.AuthorityPublicKeyDigest);
            ProtectedPolicyFrame.Digest(stream, active.Policy.ExportDigest);
            ProtectedPolicyFrame.Digest(stream, active.Snapshot.SnapshotDigest);
            ProtectedPolicyFrame.Digest(stream, active.AuthoritySetDigest);
        });

    private static ContractSliceCActivationProof ActivationProof(
        IPlanBoundEvidenceSession evidenceSession) =>
        Assert.IsType<ContractSliceCActivationProof>(
            Assert.IsType<KernelPlanningSession>(evidenceSession)
                .ActivationProof);

    private static void AssertCode(
        Action action,
        ProtectedPolicyIntegrityCode expected)
    {
        var error = Assert.Throws<ProtectedPolicyIntegrityException>(action);
        Assert.Equal(expected, error.Code);
    }

    private static void AssertCanonicalSelfFrames(
        ProtectedPolicyEvaluation independent)
    {
        var components = new[]
        {
            RepeatedDigest('1'),
            RepeatedDigest('2'),
            RepeatedDigest('3'),
            RepeatedDigest('4'),
        };
        var anchor = ComputeCurrentAnchorDigest(
            null, components[0], components[1], components[2], components[3]);
        Assert.Equal(
            "fac1774e6142ef63408672f57a9b9fc449f134a1567459f3332f43bd7a6c4311",
            anchor.Value);
        for (var index = 0; index < components.Length; index++)
        {
            var mutated = components.ToArray();
            mutated[index] = Digest($"anchor-component-{index}");
            Assert.NotEqual(
                anchor,
                ComputeCurrentAnchorDigest(
                    null, mutated[0], mutated[1], mutated[2], mutated[3]));
        }

        var goldenEvaluation = new ProtectedPolicyEvaluation(
            independent.RuntimeBinding,
            independent.Baseline,
            independent.ActiveExtensions,
            independent.DispositionAuthority,
            independent.ProposedTransition,
            independent.ExtensionEvaluations,
            independent.Dispositions,
            RepeatedDigest('a'),
            RepeatedDigest('9'),
            independent.Verdict,
            independent.Enforcement);
        var input = CandidateIndependentQualificationInput.Create(
            "protocol.fixture.protected-policy",
            "1",
            RepeatedDigest('8'),
            RepeatedDigest('9'),
            goldenEvaluation);
        Assert.Equal(
            "a12d8f6d6bba746ad48da1bf115f39711d323482e900ad2f8c0784dd3f169671",
            input.InputDigest.Value);

        var reviewed = ReviewedOutcomeDifference.Create(
            ProtectedOutcomeIdentity.Global(ProtectedOutcomeKind.Verdict),
            RepeatedDigest('1'),
            RepeatedDigest('2'),
            ReviewedAuthorityPermalink.Create(
                $"https://github.com/owner/repo/commit/{new string('0', 40)}"),
            RepeatedDigest('3'));
        Assert.Equal(
            "6313748b75224c46dee244a02bd26aef0548b74ec631759f8170baecc24b230e",
            SelfConsumptionCore.ComputeReviewedDifferenceSetDigest([reviewed]).Value);
    }

    private static void AssertReviewedResourceBounds(
        PredecessorTrustPayload payload)
    {
        _ = SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(
            ReviewedRows(100_000));
        AssertCode(
            () => _ = SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(
                new CountOnlyReviewedRows(100_001)),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        _ = SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(
            ReviewedRowsForFrameBytes(67_108_864));
        AssertCode(
            () => _ = SelfConsumptionCore.ComputeReviewedDifferenceSetDigest(
                ReviewedRowsForFrameBytes(67_108_865)),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);

        var actualAtLimit = DifferenceProjection(100_000, after: false);
        var candidateAtLimit = DifferenceProjection(100_000, after: true);
        AssertCode(
            () => _ = ValidateDifferences(
                null, payload, actualAtLimit, candidateAtLimit, []),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        AssertCode(
            () => _ = ValidateDifferences(
                null,
                payload,
                DifferenceProjection(100_001, after: false),
                DifferenceProjection(100_001, after: true),
                []),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);

        var empty = new ProtectedOutcomeSetProjection([], Digest("empty-projection"));
        AssertCode(
            () => _ = ValidateDifferences(
                null, payload, empty, empty, ReviewedRows(100_000)),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        AssertCode(
            () => _ = ValidateDifferences(
                null, payload, empty, empty, ReviewedRows(100_001)),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        AssertCode(
            () => _ = ValidateDifferences(
                null,
                payload,
                empty,
                empty,
                ReviewedRowsForFrameBytes(67_108_864)),
            ProtectedPolicyIntegrityCode.DifferentialUnexplained);
        AssertCode(
            () => _ = ValidateDifferences(
                null,
                payload,
                empty,
                empty,
                ReviewedRowsForFrameBytes(67_108_865)),
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
    }

    private static ProtectedOutcomeSetProjection DifferenceProjection(
        int count,
        bool after) => new(
        Enumerable.Range(0, count).Select(index => KeyValuePair.Create(
            $"rule:extension:ext:self:r{index:D6}:1",
            Digest(after ? "resource-after" : "resource-before"))),
        Digest(after ? "candidate-projection" : "predecessor-projection"));

    private static ReviewedOutcomeDifference[] ReviewedRows(int count) =>
        Enumerable.Range(0, count)
            .Select(index => ReviewedRow(
                index,
                "https://example.com/review"))
            .ToArray();

    private static ReviewedOutcomeDifference[] ReviewedRowsForFrameBytes(
        long targetBytes)
    {
        const int maximumAuthorityBytes = 2_048;
        const string minimumAuthority = "https://example.com/a";
        var headerBytes =
            "protocol.reviewed-outcome-difference-set/1\n"u8.Length + 4L;
        var sample = ReviewedRow(0, minimumAuthority);
        var rowFixedBytes = 104L + Encoding.UTF8.GetByteCount(
            sample.Outcome.RowKey);
        var minimumAuthorityBytes = Encoding.UTF8.GetByteCount(minimumAuthority);
        var count = checked((int)Math.Ceiling(
            (targetBytes - headerBytes) /
            (double)(rowFixedBytes + maximumAuthorityBytes)));
        var authorityBytes = targetBytes - headerBytes - count * rowFixedBytes;
        Assert.InRange(
            authorityBytes,
            count * minimumAuthorityBytes,
            count * (long)maximumAuthorityBytes);
        var extra = authorityBytes - count * minimumAuthorityBytes;
        var rows = new ReviewedOutcomeDifference[count];
        for (var index = 0; index < rows.Length; index++)
        {
            var added = (int)Math.Min(
                maximumAuthorityBytes - minimumAuthorityBytes,
                extra);
            var length = minimumAuthorityBytes + added;
            extra -= added;
            rows[index] = ReviewedRow(
                index,
                "https://example.com/" +
                new string('a', length - "https://example.com/".Length));
        }
        Assert.Equal(0, extra);
        return rows;
    }

    private static ReviewedOutcomeDifference ReviewedRow(
        int index,
        string authority) => ReviewedOutcomeDifference.Create(
        ProtectedOutcomeIdentity.ForRule(PolicyRuleIdentity.Extension(
            ExtensionId.Parse($"ext:self:r{index:D6}"),
            RuleRevision.Create(1))),
        Digest("resource-before"),
        Digest("resource-after"),
        ReviewedAuthorityPermalink.Create(authority),
        Digest("resource-evidence"));

    private static ExactSha256Digest Digest(string value) =>
        ExactSha256Digest.FromHashBytes(
            SHA256.HashData(Encoding.UTF8.GetBytes(value)));

    private static ExactSha256Digest RepeatedDigest(char value) =>
        ExactSha256Digest.Parse(new string(value, 64));

    [UnsafeAccessor(UnsafeAccessorKind.StaticMethod, Name = "ValidateDifferences")]
    private static extern IReadOnlyList<ReviewedOutcomeDifference>
        ValidateDifferences(
            SelfConsumptionCore? owner,
            PredecessorTrustPayload payload,
            ProtectedOutcomeSetProjection predecessor,
            ProtectedOutcomeSetProjection candidate,
            IEnumerable<ReviewedOutcomeDifference> assertions);

    [UnsafeAccessor(
        UnsafeAccessorKind.StaticMethod,
        Name = "ComputeCurrentAnchorDigest")]
    private static extern ExactSha256Digest ComputeCurrentAnchorDigest(
        SelfConsumptionCore? owner,
        ExactSha256Digest authorityPublicKeyDigest,
        ExactSha256Digest exportDigest,
        ExactSha256Digest snapshotDigest,
        ExactSha256Digest authoritySetDigest);

    private sealed class CountOnlyReviewedRows(int count) :
        IReadOnlyList<ReviewedOutcomeDifference>
    {
        public int Count { get; } = count;
        public ReviewedOutcomeDifference this[int index] =>
            throw new InvalidOperationException();
        public IEnumerator<ReviewedOutcomeDifference> GetEnumerator() =>
            throw new InvalidOperationException();
        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() =>
            GetEnumerator();
    }

    private sealed class ThrowingReviewedRows :
        IEnumerable<ReviewedOutcomeDifference>
    {
        public IEnumerator<ReviewedOutcomeDifference> GetEnumerator() =>
            throw new InvalidOperationException(
                "A later-stage reviewed enumerable was consumed too early.");

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() =>
            GetEnumerator();
    }
}
