namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CapabilityContractIdentity :
    IEquatable<CapabilityContractIdentity>
{
    private CapabilityContractIdentity(
        string capabilityKey,
        string capabilityVersion,
        ComponentTypeIdentity interfaceType)
    {
        CapabilityKey = capabilityKey;
        CapabilityVersion = capabilityVersion;
        InterfaceType = interfaceType;
    }

    public string CapabilityKey { get; }

    public string CapabilityVersion { get; }

    public ComponentTypeIdentity InterfaceType { get; }

    public static CapabilityContractIdentity Create(
        string capabilityKey,
        string capabilityVersion,
        ComponentTypeIdentity interfaceType)
    {
        var canonicalKey = DeclarationValidation.Token(
            capabilityKey,
            nameof(capabilityKey));
        var canonicalVersion = DeclarationValidation.Version(
            capabilityVersion,
            nameof(capabilityVersion));
        ArgumentNullException.ThrowIfNull(interfaceType);

        return new CapabilityContractIdentity(
            canonicalKey,
            canonicalVersion,
            interfaceType);
    }

    public bool Equals(CapabilityContractIdentity? other) =>
        other is not null &&
        string.Equals(
            CapabilityKey,
            other.CapabilityKey,
            StringComparison.Ordinal) &&
        string.Equals(
            CapabilityVersion,
            other.CapabilityVersion,
            StringComparison.Ordinal) &&
        ComponentEquals(InterfaceType, other.InterfaceType);

    public override bool Equals(object? obj) =>
        Equals(obj as CapabilityContractIdentity);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(CapabilityKey, StringComparer.Ordinal);
        hash.Add(CapabilityVersion, StringComparer.Ordinal);
        hash.Add(InterfaceType.ComponentKey, StringComparer.Ordinal);
        hash.Add(InterfaceType.ComponentVersion, StringComparer.Ordinal);
        hash.Add(InterfaceType.AssemblyName, StringComparer.Ordinal);
        hash.Add(InterfaceType.TypeName, StringComparer.Ordinal);
        return hash.ToHashCode();
    }

    public override string ToString() =>
        $"{CapabilityKey}@{CapabilityVersion}|{InterfaceType.ComponentKey}@{InterfaceType.ComponentVersion}";

    private static bool ComponentEquals(
        ComponentTypeIdentity left,
        ComponentTypeIdentity right) =>
        string.Equals(
            left.ComponentKey,
            right.ComponentKey,
            StringComparison.Ordinal) &&
        string.Equals(
            left.ComponentVersion,
            right.ComponentVersion,
            StringComparison.Ordinal) &&
        string.Equals(
            left.AssemblyName,
            right.AssemblyName,
            StringComparison.Ordinal) &&
        string.Equals(left.TypeName, right.TypeName, StringComparison.Ordinal);
}
