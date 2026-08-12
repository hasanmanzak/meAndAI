using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IFailedAttemptProof : IAdmissionProofCandidate
{
    FailedAcquisitionResult Result { get; }
}
