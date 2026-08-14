using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCEvaluationPlanTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0006";
    private const string ProfileName =
        "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string RepositoryTreeSlot = "protocol.slot.repository-tree";
    private const string RepositoryGovernedSlot =
        "protocol.slot.repository-governed-text";
    private const string RepositoryTargetSlot =
        "protocol.slot.repository-target-resolution";

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Plans_exact_projected_evaluation_round()
    {
        var context = CreateContext(Candidates(permuted: true));
        var result = context.Kernel.PlanEvaluation(context.Closure);
        if (result is null)
        {
            Assert.Fail(Marker);
        }

        var plan = Assert.IsType<EvaluationPlan>(result);
        Assert.Equal(0, plan.CompletedRoundCount);
        Assert.Same(context.Closure, plan.Applicability);
        Assert.Equal(
            [RepositoryGovernedSlot, RepositoryTargetSlot, RepositoryTreeSlot],
            plan.Slots.Select(slot => slot.SlotKey));
        Assert.Equal(
            [RepositoryGovernedSlot, RepositoryTargetSlot, RepositoryTargetSlot],
            plan.Instructions.Select(item => item.Slot.SlotKey));
        Assert.All(plan.Instructions, item =>
        {
            Assert.Equal(0, item.RoundOrdinal);
            Assert.Same(context.Fixture.RepositoryTarget, item.Target);
        });

        var staticInstruction = plan.Instructions[0];
        Assert.Empty(staticInstruction.DemandItems);
        var alpha = plan.Instructions[1];
        Assert.Equal([0, 1], alpha.DemandItems.Select(item => item.ItemId));
        Assert.All(alpha.DemandItems, item =>
            Assert.Equal("alpha", item.OwningRepositoryIdentity));
        Assert.Equal(new string('1', 40), alpha.DemandItems[0].CommitObjectId);
        Assert.Equal("docs/a.md", alpha.DemandItems[0].NormalizedRepositoryRelativePath);
        Assert.Null(alpha.DemandItems[0].NormalizedFragment);
        Assert.Equal("v1.0.0", alpha.DemandItems[1].NormalizedTagName);
        var omega = plan.Instructions[2];
        var captured = Assert.Single(omega.DemandItems);
        Assert.Equal(2, captured.ItemId);
        Assert.Equal("omega", captured.OwningRepositoryIdentity);
        Assert.Equal("capture-1", captured.CapturedSnapshotIdentity);
        Assert.Equal("docs/b.md", captured.NormalizedRepositoryRelativePath);
        Assert.Equal("L1-L2", captured.NormalizedFragment);

        var canonical = CreateContext(Candidates(permuted: false));
        var canonicalPlan = Assert.IsType<EvaluationPlan>(
            canonical.Kernel.PlanEvaluation(canonical.Closure));
        Assert.Equal(
            plan.Instructions.Select(item => item.DemandDigest.Value),
            canonicalPlan.Instructions.Select(item => item.DemandDigest.Value));
        Assert.Equal(
            plan.Instructions.Select(item => item.InstructionDigest.Value),
            canonicalPlan.Instructions.Select(item => item.InstructionDigest.Value));

        var empty = CreateContext([]);
        var emptyPlan = Assert.IsType<EvaluationPlan>(
            empty.Kernel.PlanEvaluation(empty.Closure));
        var emptyInstruction = Assert.Single(emptyPlan.Instructions);
        Assert.Equal(RepositoryGovernedSlot, emptyInstruction.Slot.SlotKey);
        Assert.Empty(emptyInstruction.DemandItems);

        var terminal = CreateContext(
            Candidates(permuted: false),
            terminalizeEvaluationRule: true);
        var terminalClosure = Assert.IsType<EvaluationClosure>(
            terminal.Kernel.PlanEvaluation(terminal.Closure));
        Assert.Equal(0, terminalClosure.CompletedRoundCount);
        Assert.Same(terminal.Closure, terminalClosure.Applicability);
        Assert.Equal(3, terminalClosure.TerminalEvaluations.Count);

        AssertInvalid(() => context.Kernel.PlanEvaluation(context.Closure));
        var foreign = CreateContext(Candidates(permuted: false));
        AssertInvalid(() => foreign.Kernel.PlanEvaluation(canonical.Closure));
        var cancelled = CreateContext(Candidates(permuted: false));
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();
        Assert.Throws<OperationCanceledException>(() =>
            cancelled.Kernel.PlanEvaluation(cancelled.Closure, cancellation.Token));
    }

    internal static PlanningContext CreateContext(
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate> candidates,
        bool terminalizeEvaluationRule = false)
    {
        var fixture = ContractSliceCApplicabilityClosureTests.CreateFixture(
            terminalizeEvaluationRule,
            evaluationReady: true);
        var projector = Assert.Single(fixture.Export.DemandProjectorRegistrations)
            .Accept(ProjectorVisitor.Instance);
        projector.Configure(candidates);
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
        var applicability = kernel.PlanApplicability(
            profile,
            [fixture.ProviderTarget, fixture.RepositoryTarget]);
        var closure = kernel.CloseApplicability(applicability, fixture.Proofs);
        return new PlanningContext(fixture, proof, kernel, closure);
    }

    internal static IReadOnlyList<RepositoryTargetResolutionDemandCandidate>
        Candidates(bool permuted)
    {
        var commit = RepositoryTargetResolutionDemandCandidate.CommitObject(
            "alpha",
            new string('1', 40),
            "docs/a.md",
            null,
            QualifiedEvidenceHandle.Create(),
            QualifiedEvidenceHandle.Create());
        var tag = RepositoryTargetResolutionDemandCandidate.TagRoot(
            "alpha",
            "v1.0.0",
            QualifiedEvidenceHandle.Create(),
            QualifiedEvidenceHandle.Create());
        var captured =
            RepositoryTargetResolutionDemandCandidate.CapturedSnapshotPath(
                "omega",
                "capture-1",
                "docs/b.md",
                "L1-L2",
                new string('2', 64),
                QualifiedEvidenceHandle.Create(),
                QualifiedEvidenceHandle.Create());
        return permuted ? [captured, tag, commit] : [commit, tag, captured];
    }

    private static void AssertInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, error.Code);
    }

    internal sealed record PlanningContext(
        ContractSliceCApplicabilityClosureTests.ClosureFixture Fixture,
        ContractSliceCActivationProof Proof,
        ConformanceKernel Kernel,
        ApplicabilityClosure Closure);

    private sealed class ProjectorVisitor :
        IDemandProjectorRegistrationVisitor<RepositoryTargetProjectorMirror>
    {
        internal static ProjectorVisitor Instance { get; } = new();

        public RepositoryTargetProjectorMirror Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability =>
            Assert.IsType<RepositoryTargetProjectorMirror>(registration.Projector);
    }
}
