namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ComponentArtifactBinding
{
    private ComponentArtifactBinding(
        ComponentTypeIdentity component,
        string artifactFileName)
    {
        Component = component;
        ArtifactFileName = artifactFileName;
    }

    public ComponentTypeIdentity Component { get; }

    public string ArtifactFileName { get; }

    public static ComponentArtifactBinding Create(
        ComponentTypeIdentity component,
        string artifactFileName)
    {
        ArgumentNullException.ThrowIfNull(component);
        var canonicalFileName = DeclarationValidation.Opaque(
            artifactFileName,
            nameof(artifactFileName));
        if (canonicalFileName.Contains('/') || canonicalFileName.Contains('\\'))
        {
            throw new ArgumentException(
                "An artifact file name must be a basename.",
                nameof(artifactFileName));
        }

        return new ComponentArtifactBinding(component, canonicalFileName);
    }
}
