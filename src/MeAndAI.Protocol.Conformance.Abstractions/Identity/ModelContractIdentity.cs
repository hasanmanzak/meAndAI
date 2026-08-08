namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ModelContractIdentity : IEquatable<ModelContractIdentity>
{
    private ModelContractIdentity(
        string modelKey,
        string modelVersion,
        ComponentTypeIdentity implementationType)
    {
        ModelKey = modelKey;
        ModelVersion = modelVersion;
        ImplementationType = implementationType;
    }

    public string ModelKey { get; }

    public string ModelVersion { get; }

    public ComponentTypeIdentity ImplementationType { get; }

    public static ModelContractIdentity Create(
        string modelKey,
        string modelVersion,
        ComponentTypeIdentity implementationType)
    {
        var canonicalKey = DeclarationValidation.Token(
            modelKey,
            nameof(modelKey));
        var canonicalVersion = DeclarationValidation.Version(
            modelVersion,
            nameof(modelVersion));
        ArgumentNullException.ThrowIfNull(implementationType);

        return new ModelContractIdentity(
            canonicalKey,
            canonicalVersion,
            implementationType);
    }

    public bool Equals(ModelContractIdentity? other) =>
        other is not null &&
        string.Equals(ModelKey, other.ModelKey, StringComparison.Ordinal) &&
        string.Equals(ModelVersion, other.ModelVersion, StringComparison.Ordinal) &&
        ComponentEquals(ImplementationType, other.ImplementationType);

    public override bool Equals(object? obj) =>
        Equals(obj as ModelContractIdentity);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(ModelKey, StringComparer.Ordinal);
        hash.Add(ModelVersion, StringComparer.Ordinal);
        AddComponentHash(ref hash, ImplementationType);
        return hash.ToHashCode();
    }

    public override string ToString() =>
        $"{ModelKey}@{ModelVersion}|{ImplementationType.ComponentKey}@{ImplementationType.ComponentVersion}";

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

    private static void AddComponentHash(
        ref HashCode hash,
        ComponentTypeIdentity component)
    {
        hash.Add(component.ComponentKey, StringComparer.Ordinal);
        hash.Add(component.ComponentVersion, StringComparer.Ordinal);
        hash.Add(component.AssemblyName, StringComparer.Ordinal);
        hash.Add(component.TypeName, StringComparer.Ordinal);
    }
}
