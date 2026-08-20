using System.Security.Cryptography;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IPolicyOwnedProtectedPolicyComponent
{
    ComponentTypeIdentity VerifyRuntimeComponentIdentity(
        ComponentTypeIdentity expectedIdentity);
}

public sealed class ExtensionPolicyPackExport
{
    private readonly byte[] _authorityPublicKey;
    private readonly IProtectedExtensionActivationVerifier _activationVerifier;
    private readonly IProtectedPolicyPackVerifier _policyPackVerifier;
    private readonly IProtectedDispositionAuthorityVerifier _dispositionVerifier;
    private readonly IPredecessorTrustVerifier _predecessorVerifier;
    private readonly IReadOnlyList<ExtensionEvaluatorRegistration> _registrations;

    private ExtensionPolicyPackExport(
        string exportKey,
        string exportVersion,
        ExactSha256Digest exportDigest,
        string authorityIssuerKeyId,
        string authorityAlgorithm,
        ExactSha256Digest authorityPublicKeyDigest,
        byte[] authorityPublicKey,
        ComponentTypeIdentity activationVerifierComponent,
        ComponentTypeIdentity policyPackVerifierComponent,
        ComponentTypeIdentity dispositionVerifierComponent,
        ComponentTypeIdentity predecessorVerifierComponent,
        IReadOnlyList<ExtensionEvaluatorRegistration> registrations,
        IReadOnlyList<ExtensionEvaluatorKindDeclaration> evaluatorKinds,
        IReadOnlyList<ComponentTypeIdentity> components,
        IProtectedExtensionActivationVerifier activationVerifier,
        IProtectedPolicyPackVerifier policyPackVerifier,
        IProtectedDispositionAuthorityVerifier dispositionVerifier,
        IPredecessorTrustVerifier predecessorVerifier)
    {
        ExportKey = exportKey;
        ExportVersion = exportVersion;
        ExportDigest = exportDigest;
        AuthorityIssuerKeyId = authorityIssuerKeyId;
        AuthorityAlgorithm = authorityAlgorithm;
        AuthorityPublicKeyDigest = authorityPublicKeyDigest;
        _authorityPublicKey = authorityPublicKey;
        ActivationVerifierComponent = activationVerifierComponent;
        PolicyPackVerifierComponent = policyPackVerifierComponent;
        DispositionVerifierComponent = dispositionVerifierComponent;
        PredecessorVerifierComponent = predecessorVerifierComponent;
        _registrations = registrations;
        EvaluatorKinds = evaluatorKinds;
        Components = components;
        _activationVerifier = activationVerifier;
        _policyPackVerifier = policyPackVerifier;
        _dispositionVerifier = dispositionVerifier;
        _predecessorVerifier = predecessorVerifier;
    }

    public string ExportKey { get; }
    public string ExportVersion { get; }
    public ExactSha256Digest ExportDigest { get; }
    public string AuthorityIssuerKeyId { get; }
    public string AuthorityAlgorithm { get; }
    public ExactSha256Digest AuthorityPublicKeyDigest { get; }
    public ComponentTypeIdentity ActivationVerifierComponent { get; }
    public ComponentTypeIdentity PolicyPackVerifierComponent { get; }
    public ComponentTypeIdentity DispositionVerifierComponent { get; }
    public ComponentTypeIdentity PredecessorVerifierComponent { get; }
    public IReadOnlyList<ExtensionEvaluatorKindDeclaration> EvaluatorKinds { get; }
    public IReadOnlyList<ComponentTypeIdentity> Components { get; }

    internal byte[] GetAuthorityPublicKeyCopy() => (byte[])_authorityPublicKey.Clone();
    internal IProtectedExtensionActivationVerifier ActivationVerifier => _activationVerifier;
    internal IProtectedPolicyPackVerifier PolicyPackVerifier => _policyPackVerifier;
    internal IProtectedDispositionAuthorityVerifier DispositionVerifier => _dispositionVerifier;
    internal IPredecessorTrustVerifier PredecessorVerifier => _predecessorVerifier;
    internal IReadOnlyList<ExtensionEvaluatorRegistration> Registrations => _registrations;

    internal static ExtensionPolicyPackExport Create(
        string exportKey,
        string exportVersion,
        ExactSha256Digest exportDigest,
        string authorityIssuerKeyId,
        string authorityAlgorithm,
        IEnumerable<byte> authorityPublicKeyBytes,
        IProtectedExtensionActivationVerifier activationVerifier,
        IProtectedPolicyPackVerifier policyPackVerifier,
        IProtectedDispositionAuthorityVerifier dispositionVerifier,
        IPredecessorTrustVerifier predecessorVerifier,
        IEnumerable<ExtensionEvaluatorRegistration> registrations)
    {
        var key = ProtectedPolicyFrame.LowerAsciiToken(exportKey, nameof(exportKey), 128);
        var version = ProtectedPolicyFrame.Text(exportVersion, nameof(exportVersion), 32);
        ProtectedPolicyFrame.RequireDigest(exportDigest, nameof(exportDigest));
        var issuer = ProtectedPolicyFrame.LowerAsciiToken(
            authorityIssuerKeyId, nameof(authorityIssuerKeyId), 128);
        if (!string.Equals(authorityAlgorithm, "ed25519", StringComparison.Ordinal))
        {
            throw new ArgumentException("The authority algorithm must be ed25519.", nameof(authorityAlgorithm));
        }

        var publicKey = ProtectedPolicyFrame.ExactBytes(
            authorityPublicKeyBytes,
            32,
            nameof(authorityPublicKeyBytes));

        ArgumentNullException.ThrowIfNull(activationVerifier);
        ArgumentNullException.ThrowIfNull(policyPackVerifier);
        ArgumentNullException.ThrowIfNull(dispositionVerifier);
        ArgumentNullException.ThrowIfNull(predecessorVerifier);
        var activationComponent = VerifierComponent(
            "protocol.verifier.extension-activation", activationVerifier,
            "ExtensionActivationEnvelopeVerifier");
        var packComponent = VerifierComponent(
            "protocol.verifier.protected-policy-pack", policyPackVerifier,
            "ProtectedPolicyPackEnvelopeVerifier");
        var dispositionComponent = VerifierComponent(
            "protocol.verifier.protected-disposition", dispositionVerifier,
            "ProtectedDispositionEnvelopeVerifier");
        var predecessorComponent = VerifierComponent(
            "protocol.verifier.predecessor-trust", predecessorVerifier,
            "PredecessorTrustEnvelopeVerifier");
        var registrationRows = ProtectedPolicyFrame.SortedUnique(
            registrations, static row => row.Declaration.EvaluatorKind,
            nameof(registrations), 10_000);
        var evaluatorKinds = registrationRows.Select(static row => row.Declaration).ToArray();
        var components = new[]
            {
                activationComponent,
                packComponent,
                dispositionComponent,
                predecessorComponent,
            }
            .Concat(evaluatorKinds.Select(static row => row.Component))
            .OrderBy(static row => row.ComponentKey, StringComparer.Ordinal)
            .ToArray();
        if (components.Select(static row => row.ComponentKey)
                .Distinct(StringComparer.Ordinal).Count() != components.Length)
        {
            throw new ArgumentException("Export component keys must be globally unique.", nameof(registrations));
        }

        var publicKeyDigest = ExactSha256Digest.FromHashBytes(SHA256.HashData(publicKey));
        var computed = ComputeDigest(
            key, version, issuer, authorityAlgorithm, publicKeyDigest,
            activationComponent, packComponent, dispositionComponent,
            predecessorComponent, evaluatorKinds);
        if (!computed.Equals(exportDigest))
        {
            throw new ArgumentException("The export digest does not match the typed export.", nameof(exportDigest));
        }

        return new ExtensionPolicyPackExport(
            key, version, computed, issuer, authorityAlgorithm, publicKeyDigest,
            (byte[])publicKey.Clone(), activationComponent, packComponent,
            dispositionComponent, predecessorComponent, registrationRows,
            Array.AsReadOnly(evaluatorKinds), Array.AsReadOnly(components),
            activationVerifier, policyPackVerifier, dispositionVerifier,
            predecessorVerifier);
    }

    private static ComponentTypeIdentity VerifierComponent(
        string componentKey,
        object instance,
        string expectedTypeName)
    {
        if (instance is not IPolicyOwnedProtectedPolicyComponent owned)
        {
            throw new ArgumentException("A retained verifier has the wrong release-owned runtime identity.", nameof(instance));
        }

        var expectedType = $"MeAndAI.Protocol.Policy.ProtectedPolicy.{expectedTypeName}";
        var expected = ComponentTypeIdentity.Create(
            componentKey,
            "1",
            "MeAndAI.Protocol.Policy",
            expectedType);
        var component = owned.VerifyRuntimeComponentIdentity(expected);
        if (!SameComponent(component, expected))
        {
            throw new ArgumentException(
                "A retained verifier has the wrong release-owned component identity.",
                nameof(instance));
        }

        return component;
    }

    private static bool SameComponent(
        ComponentTypeIdentity? left,
        ComponentTypeIdentity right) =>
        left is not null &&
        string.Equals(left.ComponentKey, right.ComponentKey, StringComparison.Ordinal) &&
        string.Equals(left.ComponentVersion, right.ComponentVersion, StringComparison.Ordinal) &&
        string.Equals(left.AssemblyName, right.AssemblyName, StringComparison.Ordinal) &&
        string.Equals(left.TypeName, right.TypeName, StringComparison.Ordinal);

    private static ExactSha256Digest ComputeDigest(
        string exportKey,
        string exportVersion,
        string authorityIssuerKeyId,
        string authorityAlgorithm,
        ExactSha256Digest authorityPublicKeyDigest,
        ComponentTypeIdentity activation,
        ComponentTypeIdentity pack,
        ComponentTypeIdentity disposition,
        ComponentTypeIdentity predecessor,
        IReadOnlyList<ExtensionEvaluatorKindDeclaration> evaluatorKinds) =>
        ProtectedPolicyFrame.Hash("protocol.extension-policy-pack/1\n", stream =>
        {
            ProtectedPolicyFrame.String(stream, exportKey);
            ProtectedPolicyFrame.String(stream, exportVersion);
            ProtectedPolicyFrame.String(stream, authorityIssuerKeyId);
            ProtectedPolicyFrame.String(stream, authorityAlgorithm);
            ProtectedPolicyFrame.Digest(stream, authorityPublicKeyDigest);
            WriteComponent(stream, activation);
            WriteComponent(stream, pack);
            WriteComponent(stream, disposition);
            WriteComponent(stream, predecessor);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)evaluatorKinds.Count));
            foreach (var kind in evaluatorKinds)
            {
                ProtectedPolicyFrame.String(stream, kind.EvaluatorKind);
                ProtectedPolicyFrame.String(stream, kind.EvaluatorVersion);
                WriteComponent(stream, kind.Component);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)kind.Parameters.Count));
                foreach (var parameter in kind.Parameters)
                {
                    ProtectedPolicyFrame.String(stream, parameter.Key);
                    ProtectedPolicyFrame.String(stream, parameter.ValueGrammar);
                    ProtectedPolicyFrame.UInt32(stream, checked((uint)parameter.MaximumUtf8Bytes));
                }

                WriteStrings(stream, kind.ApplicabilitySlotKeys);
                WriteStrings(stream, kind.EvaluationSlotKeys);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)kind.Findings.Count));
                foreach (var finding in kind.Findings)
                {
                    ProtectedPolicyFrame.String(stream, finding.Code.Value);
                    ProtectedPolicyFrame.String(stream, finding.Severity.Value);
                    ProtectedPolicyFrame.String(stream, finding.Remediation.Value);
                    WriteStrings(stream, finding.AllowedPrimaryReferenceKinds.Select(static row => row.Value).ToArray());
                    WriteStrings(stream, finding.AllowedRelatedReferenceKinds.Select(static row => row.Value).ToArray());
                }

                WriteStrings(stream, kind.FailureCodes.Select(static row => row.Value).ToArray());
                ProtectedPolicyFrame.Bool(stream, kind.WaiverAllowed);
            }
        });

    private static void WriteComponent(MemoryStream stream, ComponentTypeIdentity component)
    {
        ProtectedPolicyFrame.String(stream, component.ComponentKey);
        ProtectedPolicyFrame.String(stream, component.ComponentVersion);
        ProtectedPolicyFrame.String(stream, component.AssemblyName);
        ProtectedPolicyFrame.String(stream, component.TypeName);
    }

    private static void WriteStrings(MemoryStream stream, IReadOnlyList<string> values)
    {
        ProtectedPolicyFrame.UInt32(stream, checked((uint)values.Count));
        foreach (var value in values)
        {
            ProtectedPolicyFrame.String(stream, value);
        }
    }
}
