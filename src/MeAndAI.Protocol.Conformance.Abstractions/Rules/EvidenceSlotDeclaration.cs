using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class EvidenceSlotDeclaration
{
    private EvidenceSlotDeclaration(
        string slotKey,
        EvidenceRequirement requirement,
        SurfaceSet profileSurfaces,
        string materialRole,
        string targetSelectorKey,
        IReadOnlyList<CapabilityContractIdentity> capabilities)
    {
        SlotKey = slotKey;
        Requirement = requirement;
        ProfileSurfaces = profileSurfaces;
        MaterialRole = materialRole;
        TargetSelectorKey = targetSelectorKey;
        Capabilities = capabilities;
    }

    public string SlotKey { get; }

    public EvidenceRequirement Requirement { get; }

    public SurfaceSet ProfileSurfaces { get; }

    public string MaterialRole { get; }

    public string TargetSelectorKey { get; }

    public IReadOnlyList<CapabilityContractIdentity> Capabilities { get; }

    public static EvidenceSlotDeclaration Create(
        string slotKey,
        EvidenceRequirement requirement,
        SurfaceSet profileSurfaces,
        string materialRole,
        string targetSelectorKey,
        IEnumerable<CapabilityContractIdentity> capabilities)
    {
        ArgumentNullException.ThrowIfNull(requirement);
        ArgumentNullException.ThrowIfNull(profileSurfaces);

        return new EvidenceSlotDeclaration(
            DeclarationValidation.Token(slotKey, nameof(slotKey)),
            requirement,
            profileSurfaces,
            DeclarationValidation.Token(materialRole, nameof(materialRole)),
            DeclarationValidation.Token(
                targetSelectorKey,
                nameof(targetSelectorKey)),
            DeclarationValidation.Canonicalize(
                capabilities,
                nameof(capabilities),
                item => $"{item.CapabilityKey}\0{item.CapabilityVersion}",
                StringComparer.Ordinal));
    }
}
