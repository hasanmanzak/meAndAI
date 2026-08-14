using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCEvaluationAdvanceTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0007";
    private const string RepositoryGovernedSlot =
        "protocol.slot.repository-governed-text";
    private const string RepositoryTargetSlot =
        "protocol.slot.repository-target-resolution";

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Advances_owner_sharded_evaluation_to_closure()
    {
        var context = ContractSliceCEvaluationPlanTests.CreateContext(
            ContractSliceCEvaluationPlanTests.Candidates(permuted: true));
        var plan = Assert.IsType<EvaluationPlan>(
            context.Kernel.PlanEvaluation(context.Closure));
        var proofs = CompleteProofs(context, plan);
        var index = TargetIndex(context);
        var result = context.Kernel.AdvanceEvaluation(plan, proofs);
        if (result is null)
        {
            Assert.Fail(Marker);
        }

        var closure = Assert.IsType<EvaluationClosure>(result);
        Assert.Equal(1, closure.CompletedRoundCount);
        Assert.Same(context.Closure, closure.Applicability);
        Assert.Equal(
            [
                RepositoryGovernedSlot,
                RepositoryTargetSlot,
                "protocol.slot.repository-tree",
            ],
            closure.Context.AdmittedSlotKeys);
        Assert.Equal(3, closure.Acquisitions.Count);
        var governed = closure.Acquisitions.Single(item =>
            item.Slot.SlotKey == RepositoryGovernedSlot);
        Assert.False(governed.IsProjected);
        Assert.Equal(AcquisitionStatus.Complete, governed.Status);
        Assert.Single(governed.Attempts);
        Assert.NotNull(governed.ContextProof);
        var projected = closure.Acquisitions.Single(item =>
            item.Slot.SlotKey == RepositoryTargetSlot);
        Assert.True(projected.IsProjected);
        Assert.Equal(AcquisitionStatus.Complete, projected.Status);
        Assert.Equal(2, projected.Attempts.Count);
        Assert.Equal(
            ["alpha", "omega"],
            projected.Attempts.Select(item =>
                item.Instruction.DemandItems[0].OwningRepositoryIdentity)
                .Distinct());
        Assert.NotNull(projected.ContextProof);
        Assert.Equal(1, index.BuildCalls);
        AssertInvalid(() => context.Kernel.AdvanceEvaluation(plan, proofs));

        var foreign = ContractSliceCEvaluationPlanTests.CreateContext(
            ContractSliceCEvaluationPlanTests.Candidates(permuted: false));
        var foreignPlan = Assert.IsType<EvaluationPlan>(
            foreign.Kernel.PlanEvaluation(foreign.Closure));
        AssertInvalid(() => context.Kernel.AdvanceEvaluation(
            foreignPlan,
            AcquisitionProofSet.Create([], [], [])));

        var cancelled = ContractSliceCEvaluationPlanTests.CreateContext(
            ContractSliceCEvaluationPlanTests.Candidates(permuted: false));
        var cancelledPlan = Assert.IsType<EvaluationPlan>(
            cancelled.Kernel.PlanEvaluation(cancelled.Closure));
        var cancelledProofs = CompleteProofs(cancelled, cancelledPlan);
        using (var source = new CancellationTokenSource())
        {
            source.Cancel();
            Assert.Throws<OperationCanceledException>(() =>
                cancelled.Kernel.AdvanceEvaluation(
                    cancelledPlan,
                    cancelledProofs,
                    source.Token));
        }
        Assert.IsType<EvaluationClosure>(cancelled.Kernel.AdvanceEvaluation(
            cancelledPlan,
            cancelledProofs));

        var retry = ContractSliceCEvaluationPlanTests.CreateContext(
            ContractSliceCEvaluationPlanTests.Candidates(permuted: false));
        var retryPlan = Assert.IsType<EvaluationPlan>(
            retry.Kernel.PlanEvaluation(retry.Closure));
        var retryProofs = CompleteProofs(retry, retryPlan);
        TargetIndex(retry).FailNext();
        Assert.Throws<InvalidOperationException>(() =>
            retry.Kernel.AdvanceEvaluation(retryPlan, retryProofs));
        Assert.IsType<EvaluationClosure>(retry.Kernel.AdvanceEvaluation(
            retryPlan,
            retryProofs));

        var empty = ContractSliceCEvaluationPlanTests.CreateContext([]);
        var emptyPlan = Assert.IsType<EvaluationPlan>(
            empty.Kernel.PlanEvaluation(empty.Closure));
        var emptyClosure = Assert.IsType<EvaluationClosure>(
            empty.Kernel.AdvanceEvaluation(
                emptyPlan,
                CompleteProofs(empty, emptyPlan)));
        var emptyProjected = emptyClosure.Acquisitions.Single(item =>
            item.Slot.SlotKey == RepositoryTargetSlot);
        Assert.True(emptyProjected.IsProjected);
        Assert.Equal(AcquisitionStatus.Complete, emptyProjected.Status);
        Assert.Empty(emptyProjected.Attempts);
        Assert.Equal(1, TargetIndex(empty).BuildCalls);
    }

    private static AcquisitionProofSet CompleteProofs(
        ContractSliceCEvaluationPlanTests.PlanningContext context,
        EvaluationPlan plan)
    {
        var observed = plan.Instructions.Select(instruction =>
                CObservedQualificationProof.Create(
                    context.Fixture.Manifest,
                    instruction,
                    complete: true))
            .ToArray();
        context.Proof.Authorize(observed);
        return AcquisitionProofSet.Create(observed, [], []);
    }

    private static RepositoryTargetIndexMirror TargetIndex(
        ContractSliceCEvaluationPlanTests.PlanningContext context) =>
        context.Fixture.Export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey ==
                "protocol.index.repository-target-resolution")
            .Accept(TargetIndexVisitor.Instance);

    private static void AssertInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, error.Code);
    }

    private sealed class TargetIndexVisitor :
        IIndexRegistrationVisitor<RepositoryTargetIndexMirror>
    {
        internal static TargetIndexVisitor Instance { get; } = new();

        public RepositoryTargetIndexMirror Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability =>
            Assert.IsType<RepositoryTargetIndexMirror>(registration.Indexer);
    }
}
