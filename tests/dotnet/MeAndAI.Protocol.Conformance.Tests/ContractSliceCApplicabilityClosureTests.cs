using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCApplicabilityClosureTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0005";
    private const string ProfileName =
        "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string Commit =
        "0123456789abcdef0123456789abcdef01234567";

    [Fact]
    [Trait("ContractSlice", "C")]
    public void Closes_applicability_with_exact_terminal_shapes()
    {
        var fixture = CreateFixture();
        var proof = new ContractSliceCActivationProof(
            fixture.Manifest,
            fixture.Export,
            fixture.Candidates);
        var kernel = ConformanceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            proof,
            predecessor: null);
        var profile = kernel.ResolveNamedProfile(ProfileName);
        var plan = kernel.PlanApplicability(
            profile,
            [fixture.ProviderTarget, fixture.RepositoryTarget]);

        Assert.Equal(
            [
                "protocol.slot.provider-governed-text",
                "protocol.slot.repository-governed-text",
                "protocol.slot.repository-target-resolution",
                "protocol.slot.repository-tree",
            ],
            plan.Slots.Select(slot => slot.SlotKey));
        Assert.Equal(plan.Slots, plan.Instructions.Select(item => item.Slot));
        Assert.All(plan.Instructions, item => Assert.Equal(0, item.RoundOrdinal));

        var foreign = ConformanceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            new ContractSliceCActivationProof(
                fixture.Manifest,
                fixture.Export,
                fixture.Candidates),
            predecessor: null);
        AssertInvalid(() => foreign.CloseApplicability(
            plan,
            fixture.Proofs));

        using (var cancelled = new CancellationTokenSource())
        {
            cancelled.Cancel();
            Assert.Throws<OperationCanceledException>(() =>
                kernel.CloseApplicability(plan, fixture.Proofs, cancelled.Token));
        }

        ApplicabilityClosure? closure = kernel.CloseApplicability(
            plan,
            fixture.Proofs);
        if (closure is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Same(plan, closure.Plan);
        Assert.Equal(CatalogAuthorityKind.CompleteProtocolSnapshot,
            closure.Context.AuthorityKind);
        Assert.Equal(fixture.Manifest.ManifestDigest,
            closure.Context.ManifestDigest);
        Assert.Equal(fixture.Export.Catalog.CatalogVersion,
            closure.Context.CatalogVersion);
        Assert.Equal(["protocol.slot.repository-tree"],
            closure.Context.AdmittedSlotKeys);
        Assert.Single(closure.Context.Scopes);
        Assert.Equal(fixture.RepositoryTarget,
            closure.Context.Scopes[0].Target);

        Assert.Equal(4, closure.Acquisitions.Count);
        Assert.Equal(
            [
                AcquisitionStatus.Failed,
                AcquisitionStatus.Incomplete,
                AcquisitionStatus.Incomplete,
                AcquisitionStatus.Complete,
            ],
            closure.Acquisitions.Select(item => item.Status));
        Assert.Equal([false, false, false, false],
            closure.Acquisitions.Select(item => item.IsProjected));
        Assert.All(closure.Acquisitions, item => Assert.Single(item.Attempts));
        Assert.Null(closure.Acquisitions[0].ContextProof);
        Assert.Null(closure.Acquisitions[1].ContextProof);
        Assert.Null(closure.Acquisitions[2].ContextProof);
        var contextProof = Assert.IsType<QualifiedEvidenceReference>(
            closure.Acquisitions[3].ContextProof);
        Assert.Equal(QualifiedEvidenceReferenceKind.ContextProof,
            contextProof.Kind);
        Assert.Equal(fixture.Candidates[0].ReceiptDigest,
            contextProof.QualificationProofDigest);
        Assert.Null(contextProof.Root);
        Assert.Null(contextProof.Location);
        Assert.Empty(contextProof.Derivations);

        Assert.Equal(["RULE-0003", "RULE-0004", "RULE-0005"],
            closure.TerminalEvaluations.Select(item => item.RuleId.Value));
        Assert.Equal(
            [
                RuleEvaluationStatus.NotApplicable,
                RuleEvaluationStatus.NotEvaluated,
                RuleEvaluationStatus.NotEvaluated,
            ],
            closure.TerminalEvaluations.Select(item => item.Status));
        Assert.Equal([false, true, false],
            closure.TerminalEvaluations.Select(item =>
                item.IsApplicabilityUnresolved));
        Assert.Equal([1, 1, 0],
            closure.TerminalEvaluations.Select(item =>
                item.ApplicabilityReferences.Count));
        Assert.Empty(closure.TerminalEvaluations[0].UnresolvedSlotKeys);
        Assert.Empty(closure.TerminalEvaluations[1].UnresolvedSlotKeys);
        Assert.Equal(
            [
                "protocol.slot.provider-governed-text",
                "protocol.slot.repository-governed-text",
                "protocol.slot.repository-target-resolution",
            ],
            closure.TerminalEvaluations[2].UnresolvedSlotKeys);
        Assert.All(closure.TerminalEvaluations, item =>
        {
            Assert.Empty(item.Findings);
            Assert.Empty(item.Failures);
        });
        AssertInvalid(() => kernel.CloseApplicability(plan, fixture.Proofs));
    }

    private static ClosureFixture CreateFixture()
    {
        var source = ContractSliceCActivationTests.CreateFixture();
        var sourceTree = source.Export.Catalog.Rules[0].EvaluationSlots.Single();
        var tree = EvidenceSlotDeclaration.Create(
            sourceTree.SlotKey,
            sourceTree.Requirement,
            SurfaceSet.Create([SurfaceKind.Repository, SurfaceKind.Provider]),
            sourceTree.MaterialRole,
            sourceTree.TargetSelectorKey,
            sourceTree.Capabilities);
        var rules = source.Export.Catalog.Rules
            .Select(rule => CloneRule(
                rule,
                evaluation: rule.EvaluationSlots.Select(slot =>
                    slot.SlotKey == sourceTree.SlotKey ? tree : slot)))
            .ToArray();
        rules[2] = CloneRule(rules[2], [tree]);
        rules[3] = CloneRule(rules[3], [tree]);
        rules[4] = CloneRule(rules[4], rules[4].EvaluationSlots);
        var catalog = CompleteCatalogDeclaration.Create(
            source.Export.Catalog.ProtocolVersion,
            source.Export.Catalog.CatalogVersion,
            source.Export.Catalog.Predecessor,
            source.Export.Catalog.BaselineProfileName,
            rules,
            source.Export.Catalog.Transitions,
            source.Export.Catalog.NamedProfiles);
        var evaluators = new RuleEvaluatorRegistration[]
        {
            RuleEvaluatorRegistration.Create(rules[0], new Rule0001EvaluatorMirror()),
            RuleEvaluatorRegistration.Create(rules[1], new Rule0002EvaluatorMirror()),
            RuleEvaluatorRegistration.Create(rules[2], new Rule0003EvaluatorMirror(
                input => ApplicabilityIntent.NotApplicable(
                    [input.GetContextProof(tree.SlotKey)]))),
            RuleEvaluatorRegistration.Create(rules[3], new Rule0004EvaluatorMirror(
                input => ApplicabilityIntent.Unresolved(
                    [input.GetContextProof(tree.SlotKey)]))),
            RuleEvaluatorRegistration.Create(rules[4], new Rule0005EvaluatorMirror()),
        };
        var export = CompletePolicyPackExport.Create(
            source.Export.ExportKey,
            source.Export.ExportVersion,
            catalog,
            source.Manifest.SchemaRegistry,
            source.Codecs,
            source.Parsers,
            source.Indexes,
            source.Projectors,
            source.Selectors,
            evaluators);
        var manifest = ContractSliceCActivationTests.CreateSyntheticManifest(
            CatalogAuthorityKind.CompleteProtocolSnapshot,
            source.Manifest.SourceCommit,
            source.Manifest.ManifestDigest,
            source.Manifest.SchemaRegistry,
            source.Manifest.ActivationProofContract,
            source.Manifest.ArtifactFiles,
            source.Manifest.Components,
            slice: null,
            completeCatalog: catalog);
        manifest = ContractSliceCActivationTests.BindExportComponents(manifest, export);
        var repository = Target("repo", SurfaceKind.Repository);
        var provider = Target("github", SurfaceKind.Provider);
        var slots = rules.Skip(2).SelectMany(rule => rule.ApplicabilitySlots)
            .DistinctBy(slot => slot.SlotKey)
            .OrderBy(slot => slot.SlotKey, StringComparer.Ordinal)
            .ToArray();
        var instructions = slots.Select(slot =>
            AcquisitionInstruction.CreateApplicability(
                manifest.ManifestDigest,
                slot,
                slot.Requirement.Surface.Equals(SurfaceKind.Provider)
                    ? provider
                    : repository)).ToArray();
        var observedComplete = CObservedQualificationProof.Create(
            manifest,
            instructions.Single(item => item.Slot.SlotKey ==
                "protocol.slot.repository-tree"),
            complete: true);
        var observedIncomplete = CObservedQualificationProof.Create(
            manifest,
            instructions.Single(item => item.Slot.SlotKey ==
                "protocol.slot.repository-governed-text"),
            complete: false);
        var failed = CFailedAttemptProof.Create(
            manifest,
            instructions.Single(item => item.Slot.SlotKey ==
                "protocol.slot.provider-governed-text"));
        var noInput = CNoInputRoutingProof.Create(
            manifest,
            instructions.Single(item => item.Slot.SlotKey ==
                "protocol.slot.repository-target-resolution"));
        var candidates = new IAdmissionProofCandidate[]
        {
            observedComplete,
            observedIncomplete,
            failed,
            noInput,
        };
        return new ClosureFixture(
            manifest,
            export,
            repository,
            provider,
            candidates,
            AcquisitionProofSet.Create(
                [observedIncomplete, observedComplete],
                [failed],
                [noInput]));
    }

    private static RuleDeclaration CloneRule(
        RuleDeclaration rule,
        IEnumerable<EvidenceSlotDeclaration>? applicability = null,
        IEnumerable<EvidenceSlotDeclaration>? evaluation = null) =>
        RuleDeclaration.Create(
            rule.RuleId,
            rule.RuleRevision,
            rule.CatalogVersion,
            rule.NormativeDigest,
            rule.NormativeFragments,
            rule.QualificationScenarios,
            rule.Evaluator,
            applicability ?? rule.ApplicabilitySlots,
            evaluation ?? rule.EvaluationSlots,
            rule.ExpectedSelectors,
            rule.SubjectRoles,
            rule.Surfaces,
            rule.SnapshotKinds,
            rule.Operations,
            rule.Findings,
            rule.EvaluationFailureCodes,
            rule.IntroducedIn,
            rule.DeprecatedIn,
            rule.RetiredIn,
            rule.CompatibilityAliases);

    private static AcquisitionTarget Target(
        string source,
        SurfaceKind surface) => AcquisitionTarget.Create(
            "repo",
            source,
            surface,
            SnapshotKind.ExactCommit,
            Commit);

    private static void AssertInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, error.Code);
    }

    private sealed record ClosureFixture(
        FinalizedPolicyManifest Manifest,
        CompletePolicyPackExport Export,
        AcquisitionTarget RepositoryTarget,
        AcquisitionTarget ProviderTarget,
        IReadOnlyList<IAdmissionProofCandidate> Candidates,
        AcquisitionProofSet Proofs);
}

internal abstract class CAdmissionProof : IAdmissionProofCandidate
{
    protected CAdmissionProof(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction,
        AdmissionProofKind kind)
    {
        var contract = manifest.SchemaRegistry.AdmissionProofContracts.Single(
            item => item.Kind.Equals(kind));
        SlotKeys = Array.AsReadOnly([instruction.Slot.SlotKey]);
        ContractKey = contract.ContractKey;
        ContractVersion = contract.ContractVersion;
        ManifestDigest = manifest.ManifestDigest;
        InstructionDigest = instruction.InstructionDigest;
        Request = AcquisitionRequest.Create(
            instruction.Target,
            "protocol.adapter.synthetic",
            "1",
            "protocol.source.synthetic",
            "1",
            [instruction.Slot.Requirement]);
        ReceiptDigest = ExactSha256Digest.FromHashBytes(SHA256.HashData(
            Encoding.UTF8.GetBytes(
                $"{kind.Value}|{instruction.InstructionDigest.Value}")));
    }

    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
}

internal sealed class CObservedQualificationProof : CAdmissionProof,
    IObservedQualificationProof
{
    private CObservedQualificationProof(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction,
        bool complete)
        : base(manifest, instruction, AdmissionProofKind.Observed)
    {
        var requirement = Request.RequestedRequirements.Single();
        var acquisition = RequirementAcquisition.Create(
            requirement,
            complete
                ? EvidenceConsistencyClass.ExactSnapshot
                : EvidenceConsistencyClass.InsufficientConsistency,
            EvidenceRedaction.None,
            []);
        var now = new DateTimeOffset(2026, 8, 12, 0, 0, 0, TimeSpan.Zero);
        var scope = EvidenceScope.Create(
            Request.Target,
            AcquisitionBoundary.Create(
                Request.Target.SnapshotKind,
                Request.Target.TargetIdentity,
                now,
                now.AddSeconds(1)));
        Result = ObservedAcquisitionResult.Create(EvidenceContext.Create(
            Request,
            scope,
            [acquisition],
            [],
            [],
            0));
        QualifiedCodecs = Array.Empty<ComponentArtifactBinding>();
    }

    public ObservedAcquisitionResult Result { get; }
    public IReadOnlyList<ComponentArtifactBinding> QualifiedCodecs { get; }

    internal static CObservedQualificationProof Create(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction,
        bool complete) => new(manifest, instruction, complete);
}

internal sealed class CFailedAttemptProof : CAdmissionProof,
    IFailedAttemptProof
{
    private CFailedAttemptProof(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction)
        : base(manifest, instruction, AdmissionProofKind.Failed)
    {
        var now = new DateTimeOffset(2026, 8, 12, 0, 0, 0, TimeSpan.Zero);
        Result = FailedAcquisitionResult.Create(
            Request,
            now,
            now.AddSeconds(1),
            Request.RequestedRequirements.Select(requirement =>
                AcquisitionFailure.Create(
                    requirement.Key,
                    "protocol.test.synthetic-failure")));
    }

    public FailedAcquisitionResult Result { get; }

    internal static CFailedAttemptProof Create(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction) => new(manifest, instruction);
}

internal sealed class CNoInputRoutingProof : CAdmissionProof,
    INoInputRoutingProof
{
    private CNoInputRoutingProof(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction)
        : base(manifest, instruction, AdmissionProofKind.NoInput) { }

    internal static CNoInputRoutingProof Create(
        FinalizedPolicyManifest manifest,
        AcquisitionInstruction instruction) => new(manifest, instruction);
}
