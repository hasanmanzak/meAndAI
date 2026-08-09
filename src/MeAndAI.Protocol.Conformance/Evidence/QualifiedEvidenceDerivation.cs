using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class QualifiedEvidenceDerivation
{
    internal QualifiedEvidenceDerivation(
        ComponentTypeIdentity component,
        string artifactFileName,
        ExactSha256Digest artifactDigest,
        ModelContractIdentity? outputModel,
        CapabilityContractIdentity? outputCapability,
        string typedNodeKind,
        string typedNodeIdentity,
        EvidenceLocation location)
    {
        ArgumentNullException.ThrowIfNull(component);
        ArgumentNullException.ThrowIfNull(artifactFileName);
        ArgumentNullException.ThrowIfNull(artifactDigest);
        ArgumentNullException.ThrowIfNull(typedNodeKind);
        ArgumentNullException.ThrowIfNull(typedNodeIdentity);
        ArgumentNullException.ThrowIfNull(location);

        Component = component;
        ArtifactFileName = artifactFileName;
        ArtifactDigest = artifactDigest;
        OutputModel = outputModel;
        OutputCapability = outputCapability;
        TypedNodeKind = typedNodeKind;
        TypedNodeIdentity = typedNodeIdentity;
        Location = location;
    }

    public ComponentTypeIdentity Component { get; }

    public string ArtifactFileName { get; }

    public ExactSha256Digest ArtifactDigest { get; }

    public ModelContractIdentity? OutputModel { get; }

    public CapabilityContractIdentity? OutputCapability { get; }

    public string TypedNodeKind { get; }

    public string TypedNodeIdentity { get; }

    public EvidenceLocation Location { get; }
}
