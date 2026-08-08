using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IPolicyActivationProof
{
    string ContractKey { get; }

    string ContractVersion { get; }

    ExactSha256Digest ManifestDigest { get; }

    IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts { get; }

    bool Proves(PolicyQualificationSliceExport policy);

    bool Proves(CompletePolicyPackExport policy);

    bool Proves(IAdmissionProofCandidate candidate);
}
