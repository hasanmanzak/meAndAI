using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    public SelfConsumptionQualification QualifyCandidate(
        PredecessorTrustPayload predecessorPayload,
        ProtectedAuthorityEnvelope predecessorProof,
        RuntimeQualificationBinding candidate,
        ActivatedExtensionPolicy activePolicy,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        CandidateIndependentQualificationInput candidateIndependentInput,
        IEnumerable<ReviewedOutcomeDifference> reviewedDifferences) =>
        SelfConsumptionCore.Qualify(
            Catalog,
            predecessorPayload,
            predecessorProof,
            candidate,
            activePolicy,
            predecessorOverlap,
            candidateOverlap,
            candidateIndependentInput,
            reviewedDifferences);
}
