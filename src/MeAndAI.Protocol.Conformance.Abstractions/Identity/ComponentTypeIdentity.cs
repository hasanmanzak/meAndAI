namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ComponentTypeIdentity
{
    private ComponentTypeIdentity(
        string componentKey,
        string componentVersion,
        string assemblyName,
        string typeName)
    {
        ComponentKey = componentKey;
        ComponentVersion = componentVersion;
        AssemblyName = assemblyName;
        TypeName = typeName;
    }

    public string ComponentKey { get; }

    public string ComponentVersion { get; }

    public string AssemblyName { get; }

    public string TypeName { get; }

    public static ComponentTypeIdentity Create(
        string componentKey,
        string componentVersion,
        string assemblyName,
        string typeName) =>
        new(
            DeclarationValidation.Token(componentKey, nameof(componentKey)),
            DeclarationValidation.Version(
                componentVersion,
                nameof(componentVersion)),
            DeclarationValidation.Opaque(assemblyName, nameof(assemblyName)),
            DeclarationValidation.Opaque(typeName, nameof(typeName)));
}
