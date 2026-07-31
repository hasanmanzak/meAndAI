namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ActivationProofContractDeclaration
{
    private ActivationProofContractDeclaration(
        string contractKey,
        string contractVersion,
        ComponentTypeIdentity proofComponent)
    {
        ContractKey = contractKey;
        ContractVersion = contractVersion;
        ProofComponent = proofComponent;
    }

    public string ContractKey { get; }

    public string ContractVersion { get; }

    public ComponentTypeIdentity ProofComponent { get; }

    public static ActivationProofContractDeclaration Create(
        string contractKey,
        string contractVersion,
        ComponentTypeIdentity proofComponent)
    {
        var canonicalKey = DeclarationValidation.Token(
            contractKey,
            nameof(contractKey));
        var canonicalVersion = DeclarationValidation.Version(
            contractVersion,
            nameof(contractVersion));
        ArgumentNullException.ThrowIfNull(proofComponent);

        return new ActivationProofContractDeclaration(
            canonicalKey,
            canonicalVersion,
            proofComponent);
    }
}
