using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IAdmissionProofCandidate
{
    IReadOnlyList<string> SlotKeys { get; }

    string ContractKey { get; }

    string ContractVersion { get; }

    ExactSha256Digest ManifestDigest { get; }

    ExactSha256Digest InstructionDigest { get; }

    ExactSha256Digest ReceiptDigest { get; }

    AcquisitionRequest Request { get; }
}
