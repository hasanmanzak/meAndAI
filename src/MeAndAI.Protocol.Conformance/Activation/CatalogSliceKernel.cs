using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CatalogSliceKernel
{
    private CatalogSliceKernel()
    {
    }

    public static CatalogSliceKernel Activate(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        IPolicyActivationProof activationProof) =>
        throw new CatalogIntegrityException(
            CatalogIntegrityCode.ActivationProofInvalid);

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
