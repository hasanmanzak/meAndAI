using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CatalogSliceKernel
{
    private readonly CatalogSliceProducerGraph _producerGraph;
    private readonly KernelPlanningSession _planningSession;

    private CatalogSliceKernel(
        CatalogSliceProducerGraph producerGraph,
        KernelPlanningSession planningSession)
    {
        _producerGraph = producerGraph;
        _planningSession = planningSession;
    }

    public static CatalogSliceKernel Activate(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        IPolicyActivationProof activationProof)
    {
        KernelActivationCore.ValidateSlice(manifest, policy, activationProof);
        var graph = CatalogSliceProducerGraph.Create(policy);
        return new CatalogSliceKernel(
            graph,
            new KernelPlanningSession(
                manifest,
                activationProof,
                CatalogAuthorityKind.QualificationSlice,
                manifest.ManifestDigest,
                policy.Catalog.CatalogVersion,
                policy.Catalog.Rules,
                graph));
    }

    internal CatalogSliceProducerGraph ProducerGraph => _producerGraph;

    public ApplicabilityPlan PlanApplicability(
        ExecutionProfile diagnosticProfile,
        IEnumerable<AcquisitionTarget> targets) =>
        ApplicabilityPlanningCore.PlanSlice(
            _planningSession,
            diagnosticProfile,
            targets);

    public ApplicabilityClosure CloseApplicability(
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        ApplicabilityClosureCore.Close(
            _planningSession,
            plan,
            proofs,
            cancellationToken);

    public EvaluationAdvanceResult PlanEvaluation(
        ApplicabilityClosure closure,
        CancellationToken cancellationToken = default) =>
        EvaluationPlanningCore.Plan(
            _planningSession,
            closure,
            cancellationToken);

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
