using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CatalogSliceKernel
{
    private readonly CatalogSliceProducerGraph _producerGraph;

    private CatalogSliceKernel(CatalogSliceProducerGraph producerGraph)
    {
        _producerGraph = producerGraph;
    }

    public static CatalogSliceKernel Activate(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        IPolicyActivationProof activationProof)
    {
        KernelActivationCore.ValidateSlice(manifest, policy, activationProof);
        return new CatalogSliceKernel(CatalogSliceProducerGraph.Create(policy));
    }

    internal CatalogSliceProducerGraph ProducerGraph => _producerGraph;

    public ApplicabilityPlan PlanApplicability(
        ExecutionProfile diagnosticProfile,
        IEnumerable<AcquisitionTarget> targets) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public ApplicabilityClosure CloseApplicability(
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public EvaluationAdvanceResult PlanEvaluation(
        ApplicabilityClosure closure,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public EvaluationAdvanceResult AdvanceEvaluation(
        EvaluationPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public CatalogSliceEvaluation Evaluate(
        EvaluationClosure closure,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);
}
