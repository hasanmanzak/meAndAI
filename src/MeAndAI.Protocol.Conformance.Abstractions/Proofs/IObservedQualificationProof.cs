using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IObservedQualificationProof : IAdmissionProofCandidate
{
    ObservedAcquisitionResult Result { get; }

    IReadOnlyList<ComponentArtifactBinding> QualifiedCodecs { get; }
}
