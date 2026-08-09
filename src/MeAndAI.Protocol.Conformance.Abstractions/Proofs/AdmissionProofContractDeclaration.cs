using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class AdmissionProofContractDeclaration
{
    private AdmissionProofContractDeclaration(
        string contractKey,
        string contractVersion,
        AdmissionProofKind kind,
        ComponentTypeIdentity proofComponent,
        SurfaceSet surfaces,
        IReadOnlyList<string> materialRoles)
    {
        ContractKey = contractKey;
        ContractVersion = contractVersion;
        Kind = kind;
        ProofComponent = proofComponent;
        Surfaces = surfaces;
        MaterialRoles = materialRoles;
    }

    public string ContractKey { get; }

    public string ContractVersion { get; }

    public AdmissionProofKind Kind { get; }

    public ComponentTypeIdentity ProofComponent { get; }

    public SurfaceSet Surfaces { get; }

    public IReadOnlyList<string> MaterialRoles { get; }

    public static AdmissionProofContractDeclaration Create(
        string contractKey,
        string contractVersion,
        AdmissionProofKind kind,
        ComponentTypeIdentity proofComponent,
        SurfaceSet surfaces,
        IEnumerable<string> materialRoles)
    {
        var canonicalKey = DeclarationValidation.Token(
            contractKey,
            nameof(contractKey));
        var canonicalVersion = DeclarationValidation.Version(
            contractVersion,
            nameof(contractVersion));
        ArgumentNullException.ThrowIfNull(kind);
        ArgumentNullException.ThrowIfNull(proofComponent);
        ArgumentNullException.ThrowIfNull(surfaces);

        return new AdmissionProofContractDeclaration(
            canonicalKey,
            canonicalVersion,
            kind,
            proofComponent,
            surfaces,
            DeclarationValidation.CanonicalTokens(
                materialRoles,
                nameof(materialRoles)));
    }
}
