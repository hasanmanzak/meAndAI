using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCAggregationTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0009";
    private const string TreeSlot = "protocol.slot.repository-tree";

    [Fact]
    [Trait("ContractSlice", "C")]
    public void Aggregates_exact_catalog_evaluation_and_verdict()
    {
        var indeterminate = CompleteContext(
            violation: true,
            terminalApplicability: true);
        CompleteCatalogEvaluation? result = indeterminate.Kernel.Evaluate(
            indeterminate.Closure);
        if (result is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Same(indeterminate.Kernel.Catalog, result.Catalog);
        Assert.Same(indeterminate.Profile, result.Profile);
        Assert.True(result.HasKnownViolation);
        Assert.True(result.HasUnresolvedRequiredEvaluation);
        Assert.Equal(ConformanceVerdict.Indeterminate, result.Verdict);
        Assert.Equal(
            result.Acquisitions.Select(item => item.Slot.SlotKey)
                .Order(StringComparer.Ordinal),
            result.Acquisitions.Select(item => item.Slot.SlotKey));
        Assert.Equal(
            ["RULE-0001", "RULE-0002", "RULE-0003", "RULE-0004", "RULE-0005"],
            result.Evaluations.Select(item => item.RuleId.Value));
        Assert.Equal(
            [
                RuleEvaluationStatus.Satisfied,
                RuleEvaluationStatus.Violated,
                RuleEvaluationStatus.NotApplicable,
                RuleEvaluationStatus.NotEvaluated,
                RuleEvaluationStatus.Satisfied,
            ],
            result.Evaluations.Select(item => item.Status));
        Assert.Throws<NotSupportedException>(() =>
            ((IList<RuleEvaluation>)result.Evaluations).Clear());
        Assert.Throws<NotSupportedException>(() =>
            ((IList<SealedAcquisitionOutcome>)result.Acquisitions).Clear());

        var nonConforming = CompleteContext(
            violation: true,
            terminalApplicability: false);
        var nonConformingResult = nonConforming.Kernel.Evaluate(
            nonConforming.Closure);
        Assert.True(nonConformingResult.HasKnownViolation);
        Assert.False(nonConformingResult.HasUnresolvedRequiredEvaluation);
        Assert.Equal(
            ConformanceVerdict.NonConforming,
            nonConformingResult.Verdict);

        var conforming = CompleteContext(
            violation: false,
            terminalApplicability: false);
        var conformingResult = conforming.Kernel.Evaluate(conforming.Closure);
        Assert.False(conformingResult.HasKnownViolation);
        Assert.False(conformingResult.HasUnresolvedRequiredEvaluation);
        Assert.Equal(ConformanceVerdict.Conforming, conformingResult.Verdict);

        AssertPlanInvalid(() => indeterminate.Kernel.Evaluate(
            indeterminate.Closure));
        AssertPlanInvalid(() => conforming.Kernel.Evaluate(
            nonConforming.Closure));

        var cancellation = CompleteContext(false, false);
        using (var source = new CancellationTokenSource())
        {
            source.Cancel();
            Assert.Throws<OperationCanceledException>(() =>
                cancellation.Kernel.Evaluate(
                    cancellation.Closure,
                    source.Token));
        }
        Assert.Equal(
            ConformanceVerdict.Conforming,
            cancellation.Kernel.Evaluate(cancellation.Closure).Verdict);

        var calls = 0;
        var retry = CreateContext(
            new Dictionary<string, Func<RuleEvaluationInput, EvaluationIntent>>(
                StringComparer.Ordinal)
            {
                ["RULE-0001"] = _ => ++calls == 1
                    ? throw new InvalidOperationException("host-failure")
                    : EvaluationIntent.Create([], []),
            },
            AllApplicable());
        var hostFailure = Assert.Throws<InvalidOperationException>(() =>
            retry.Kernel.Evaluate(retry.Closure));
        Assert.Equal("host-failure", hostFailure.Message);
        Assert.Equal(
            ConformanceVerdict.Conforming,
            retry.Kernel.Evaluate(retry.Closure).Verdict);
        Assert.Equal(2, calls);

        var slice = EvaluateSlice();
        Assert.Same(slice.Fixture.Export.Catalog, slice.Result.Catalog);
        Assert.Equal(
            slice.Fixture.Manifest.ManifestDigest,
            slice.Result.ManifestDigest);
        Assert.Same(slice.Profile, slice.Result.Profile);
        Assert.False(slice.Result.HasKnownViolation);
        Assert.False(slice.Result.HasUnresolvedRequiredEvaluation);
        Assert.Null(typeof(CatalogSliceEvaluation).GetProperty("Verdict"));
        Assert.Null(typeof(CatalogSliceEvaluation).GetProperty("Report"));
        Assert.Null(typeof(CompleteCatalogEvaluation).GetProperty("Enforcement"));
    }

    private static ContractSliceCIntentTests.MintingContext CompleteContext(
        bool violation,
        bool terminalApplicability) => CreateContext(
            violation ? Violation() : EmptyCallbacks(),
            terminalApplicability ? null : AllApplicable());

    private static ContractSliceCIntentTests.MintingContext CreateContext(
        IReadOnlyDictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>> callbacks,
        IReadOnlyDictionary<string,
            Func<RuleApplicabilityInput, ApplicabilityIntent>>?
            applicability) =>
        ContractSliceCIntentTests.CreateContext(
            callbacks,
            applicabilityByRule: applicability);

    private static IReadOnlyDictionary<string,
        Func<RuleEvaluationInput, EvaluationIntent>> EmptyCallbacks() =>
        new Dictionary<string, Func<RuleEvaluationInput, EvaluationIntent>>(
            StringComparer.Ordinal);

    private static IReadOnlyDictionary<string,
        Func<RuleEvaluationInput, EvaluationIntent>> Violation() =>
        new Dictionary<string, Func<RuleEvaluationInput, EvaluationIntent>>(
            StringComparer.Ordinal)
        {
            ["RULE-0002"] = input => EvaluationIntent.Create(
                [FindingIntent.Create(
                    FindingCode.Parse("protocol.decision.record-missing"),
                    input.GetContextProof(TreeSlot),
                    [])],
                []),
        };

    private static IReadOnlyDictionary<string,
        Func<RuleApplicabilityInput, ApplicabilityIntent>> AllApplicable() =>
        new Dictionary<string, Func<RuleApplicabilityInput, ApplicabilityIntent>>(
            StringComparer.Ordinal)
        {
            ["RULE-0003"] = _ => ApplicabilityIntent.Applicable([]),
            ["RULE-0004"] = _ => ApplicabilityIntent.Applicable([]),
        };

    private static SliceResult EvaluateSlice()
    {
        var fixture = ContractSliceCActivationTests.CreateSliceFixture();
        var proof = new SliceActivationProof(fixture.Manifest, fixture.Export);
        var kernel = CatalogSliceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            proof);
        Assert.Single(fixture.Export.DemandProjectorRegistrations)
            .Accept(ProjectorVisitor.Instance)
            .Configure(ContractSliceCEvaluationPlanTests.Candidates(
                permuted: false));
        var profile = ExecutionProfile.Create(
            SubjectRole.Consumer,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);
        var target = AcquisitionTarget.Create(
            "repo",
            "repo",
            SurfaceKind.Repository,
            SnapshotKind.ExactCommit,
            "0123456789abcdef0123456789abcdef01234567");
        var plan = kernel.PlanApplicability(profile, [target]);
        var applicability = kernel.CloseApplicability(
            plan,
            AcquisitionProofSet.Create([], [], []));
        var advance = kernel.PlanEvaluation(applicability);
        while (advance is EvaluationPlan evaluationPlan)
        {
            var observed = evaluationPlan.Instructions.Select(instruction =>
                CObservedQualificationProof.Create(
                    fixture.Manifest,
                    instruction,
                    complete: true)).ToArray();
            proof.Authorize(observed);
            advance = kernel.AdvanceEvaluation(
                evaluationPlan,
                AcquisitionProofSet.Create(observed, [], []));
        }

        var closure = Assert.IsType<EvaluationClosure>(advance);
        return new SliceResult(
            fixture,
            profile,
            kernel.Evaluate(closure));
    }

    private static void AssertPlanInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, error.Code);
    }

    private sealed record SliceResult(
        ContractSliceCActivationTests.CSliceFixture Fixture,
        ExecutionProfile Profile,
        CatalogSliceEvaluation Result);

    private sealed class ProjectorVisitor :
        IDemandProjectorRegistrationVisitor<RepositoryTargetProjectorMirror>
    {
        internal static ProjectorVisitor Instance { get; } = new();

        public RepositoryTargetProjectorMirror Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability =>
            Assert.IsType<RepositoryTargetProjectorMirror>(registration.Projector);
    }

    private sealed class SliceActivationProof : IPolicyActivationProof
    {
        private readonly FinalizedPolicyManifest _manifest;
        private readonly PolicyQualificationSliceExport _policy;
        private readonly HashSet<IAdmissionProofCandidate> _candidates =
            new(ReferenceEqualityComparer.Instance);

        internal SliceActivationProof(
            FinalizedPolicyManifest manifest,
            PolicyQualificationSliceExport policy)
        {
            _manifest = manifest;
            _policy = policy;
        }

        public string ContractKey => _manifest.ActivationProofContract.ContractKey;
        public string ContractVersion =>
            _manifest.ActivationProofContract.ContractVersion;
        public ExactSha256Digest ManifestDigest => _manifest.ManifestDigest;
        public IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts =>
            _manifest.ArtifactFiles;
        public bool Proves(PolicyQualificationSliceExport policy) =>
            ReferenceEquals(policy, _policy);
        public bool Proves(CompletePolicyPackExport policy) => false;
        public bool Proves(IAdmissionProofCandidate candidate) =>
            _candidates.Contains(candidate);

        internal void Authorize(IEnumerable<IAdmissionProofCandidate> candidates)
        {
            foreach (var candidate in candidates)
            {
                Assert.True(_candidates.Add(candidate));
            }
        }
    }
}
