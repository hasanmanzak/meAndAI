using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ProtectedAuthorityEnvelope
{
    private readonly byte[] _signature;

    private ProtectedAuthorityEnvelope(
        string issuerKeyId,
        string algorithm,
        string contractKey,
        string contractVersion,
        ExactSha256Digest payloadDigest,
        ExactSha256Digest authorityRecordDigest,
        long authorityEpoch,
        byte[] signature,
        ExactSha256Digest envelopeDigest)
    {
        IssuerKeyId = issuerKeyId;
        Algorithm = algorithm;
        ContractKey = contractKey;
        ContractVersion = contractVersion;
        PayloadDigest = payloadDigest;
        AuthorityRecordDigest = authorityRecordDigest;
        AuthorityEpoch = authorityEpoch;
        _signature = signature;
        EnvelopeDigest = envelopeDigest;
    }

    public string IssuerKeyId { get; }
    public string Algorithm { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest PayloadDigest { get; }
    public ExactSha256Digest AuthorityRecordDigest { get; }
    public long AuthorityEpoch { get; }
    public ExactSha256Digest EnvelopeDigest { get; }

    public byte[] GetSignatureCopy() => (byte[])_signature.Clone();

    public static ProtectedAuthorityEnvelope Create(
        string issuerKeyId,
        string algorithm,
        string contractKey,
        string contractVersion,
        ExactSha256Digest payloadDigest,
        ExactSha256Digest authorityRecordDigest,
        long authorityEpoch,
        IEnumerable<byte> signature)
    {
        var issuer = ProtectedPolicyFrame.LowerAsciiToken(issuerKeyId, nameof(issuerKeyId), 128);
        var algorithmValue = ProtectedPolicyFrame.LowerAsciiToken(algorithm, nameof(algorithm), 32);
        var contract = ProtectedPolicyFrame.LowerAsciiToken(contractKey, nameof(contractKey), 128);
        var version = ProtectedPolicyFrame.Text(contractVersion, nameof(contractVersion), 32);
        ProtectedPolicyFrame.RequireDigest(payloadDigest, nameof(payloadDigest));
        ProtectedPolicyFrame.RequireDigest(authorityRecordDigest, nameof(authorityRecordDigest));
        if (authorityEpoch <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(authorityEpoch));
        }

        var signatureBytes = ProtectedPolicyFrame.ExactBytes(
            signature,
            64,
            nameof(signature));

        var digest = ProtectedPolicyFrame.Hash("protocol.protected-authority-envelope/1\n", stream =>
        {
            ProtectedPolicyFrame.String(stream, issuer);
            ProtectedPolicyFrame.String(stream, algorithmValue);
            ProtectedPolicyFrame.String(stream, contract);
            ProtectedPolicyFrame.String(stream, version);
            ProtectedPolicyFrame.Digest(stream, payloadDigest);
            ProtectedPolicyFrame.Digest(stream, authorityRecordDigest);
            ProtectedPolicyFrame.Int64(stream, authorityEpoch);
            stream.Write(signatureBytes);
        });
        return new ProtectedAuthorityEnvelope(
            issuer, algorithmValue, contract, version, payloadDigest,
            authorityRecordDigest, authorityEpoch, (byte[])signatureBytes.Clone(), digest);
    }
}

public sealed class ProtectedExtensionActivationPayload
{
    private ProtectedExtensionActivationPayload(
        ExactSha256Digest manifestDigest,
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        ExactSha256Digest previousActivationRecordDigest,
        ExactSha256Digest closureEvidenceDigest,
        ExactSha256Digest activeSnapshotDigest,
        string activatedTargetCommit,
        long activationEpoch,
        ExactSha256Digest payloadDigest)
    {
        ManifestDigest = manifestDigest;
        RepositoryNamespace = repositoryNamespace;
        PolicyBlobDigest = policyBlobDigest;
        AuthoritySetDigest = authoritySetDigest;
        ExpectedAuthorityRecordDigest = expectedAuthorityRecordDigest;
        PreviousActivationRecordDigest = previousActivationRecordDigest;
        ClosureEvidenceDigest = closureEvidenceDigest;
        ActiveSnapshotDigest = activeSnapshotDigest;
        ActivatedTargetCommit = activatedTargetCommit;
        ActivationEpoch = activationEpoch;
        PayloadDigest = payloadDigest;
    }

    public ExactSha256Digest ManifestDigest { get; }
    public string RepositoryNamespace { get; }
    public ExactSha256Digest PolicyBlobDigest { get; }
    public ExactSha256Digest AuthoritySetDigest { get; }
    public ExactSha256Digest ExpectedAuthorityRecordDigest { get; }
    public ExactSha256Digest PreviousActivationRecordDigest { get; }
    public ExactSha256Digest ClosureEvidenceDigest { get; }
    public ExactSha256Digest ActiveSnapshotDigest { get; }
    public string ActivatedTargetCommit { get; }
    public long ActivationEpoch { get; }
    public ExactSha256Digest PayloadDigest { get; }

    public static ProtectedExtensionActivationPayload Create(
        ExactSha256Digest manifestDigest,
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        ExactSha256Digest previousActivationRecordDigest,
        ExactSha256Digest closureEvidenceDigest,
        ExactSha256Digest activeSnapshotDigest,
        string activatedTargetCommit,
        long activationEpoch)
    {
        ProtectedPolicyFrame.RequireDigest(manifestDigest, nameof(manifestDigest));
        var repository = ProtectedPolicyFrame.LowerAsciiToken(repositoryNamespace, nameof(repositoryNamespace), 96);
        ProtectedPolicyFrame.RequireDigest(policyBlobDigest, nameof(policyBlobDigest));
        ProtectedPolicyFrame.RequireDigest(authoritySetDigest, nameof(authoritySetDigest));
        ProtectedPolicyFrame.RequireDigest(expectedAuthorityRecordDigest, nameof(expectedAuthorityRecordDigest));
        ProtectedPolicyFrame.RequireDigest(previousActivationRecordDigest, nameof(previousActivationRecordDigest));
        ProtectedPolicyFrame.RequireDigest(closureEvidenceDigest, nameof(closureEvidenceDigest));
        ProtectedPolicyFrame.RequireDigest(activeSnapshotDigest, nameof(activeSnapshotDigest));
        var target = ProtectedPolicyFrame.GitObjectId(activatedTargetCommit, nameof(activatedTargetCommit));
        if (activationEpoch <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(activationEpoch));
        }

        var digest = ProtectedPolicyFrame.Hash("protocol.extension-activation-payload/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, manifestDigest);
            ProtectedPolicyFrame.String(stream, repository);
            ProtectedPolicyFrame.Digest(stream, policyBlobDigest);
            ProtectedPolicyFrame.Digest(stream, authoritySetDigest);
            ProtectedPolicyFrame.Digest(stream, expectedAuthorityRecordDigest);
            ProtectedPolicyFrame.Digest(stream, previousActivationRecordDigest);
            ProtectedPolicyFrame.Digest(stream, closureEvidenceDigest);
            ProtectedPolicyFrame.Digest(stream, activeSnapshotDigest);
            ProtectedPolicyFrame.String(stream, target);
            ProtectedPolicyFrame.Int64(stream, activationEpoch);
        });
        return new ProtectedExtensionActivationPayload(
            manifestDigest, repository, policyBlobDigest, authoritySetDigest,
            expectedAuthorityRecordDigest, previousActivationRecordDigest,
            closureEvidenceDigest, activeSnapshotDigest, target, activationEpoch, digest);
    }
}

public interface IProtectedExtensionActivationVerifier
{
    bool Verify(
        ProtectedExtensionActivationPayload payload,
        ProtectedAuthorityEnvelope activationProof);
}

public sealed class ProtectedPolicyArtifactBinding
{
    private ProtectedPolicyArtifactBinding(
        string artifactKey,
        string fileName,
        long fileLength,
        ExactSha256Digest fileDigest,
        IReadOnlyList<string> componentKeys)
    {
        ArtifactKey = artifactKey;
        FileName = fileName;
        FileLength = fileLength;
        FileDigest = fileDigest;
        ComponentKeys = componentKeys;
    }

    public string ArtifactKey { get; }
    public string FileName { get; }
    public long FileLength { get; }
    public ExactSha256Digest FileDigest { get; }
    public IReadOnlyList<string> ComponentKeys { get; }

    public static ProtectedPolicyArtifactBinding Create(
        string artifactKey,
        string fileName,
        long fileLength,
        ExactSha256Digest fileDigest,
        IEnumerable<string> componentKeys)
    {
        var key = ProtectedPolicyFrame.LowerAsciiToken(artifactKey, nameof(artifactKey), 128);
        var file = ProtectedPolicyFrame.Text(fileName, nameof(fileName), 256);
        if (fileLength <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(fileLength));
        }

        ProtectedPolicyFrame.RequireDigest(fileDigest, nameof(fileDigest));
        ArgumentNullException.ThrowIfNull(componentKeys);
        var components = ProtectedPolicyFrame.SortedUnique(
            componentKeys.Select(value => ProtectedPolicyFrame.LowerAsciiToken(
                value, nameof(componentKeys), 128)),
            static value => value, nameof(componentKeys), 10_004,
            requireInputOrder: true);

        return new ProtectedPolicyArtifactBinding(
            key, file, fileLength, fileDigest, components);
    }
}

public sealed class ProtectedPolicyPackBinding
{
    private ProtectedPolicyPackBinding(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest extensionExportDigest,
        BaselineWaiverPolicySnapshot baselineWaiverPolicy,
        IReadOnlyList<ProtectedPolicyArtifactBinding> artifacts,
        ExactSha256Digest bindingDigest)
    {
        ManifestDigest = manifestDigest;
        ExtensionExportDigest = extensionExportDigest;
        BaselineWaiverPolicy = baselineWaiverPolicy;
        Artifacts = artifacts;
        BindingDigest = bindingDigest;
    }

    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest ExtensionExportDigest { get; }
    public BaselineWaiverPolicySnapshot BaselineWaiverPolicy { get; }
    public IReadOnlyList<ProtectedPolicyArtifactBinding> Artifacts { get; }
    public ExactSha256Digest BindingDigest { get; }

    public static ProtectedPolicyPackBinding Create(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest extensionExportDigest,
        BaselineWaiverPolicySnapshot baselineWaiverPolicy,
        IEnumerable<ProtectedPolicyArtifactBinding> artifacts,
        ExactSha256Digest bindingDigest)
    {
        ProtectedPolicyFrame.RequireDigest(manifestDigest, nameof(manifestDigest));
        ProtectedPolicyFrame.RequireDigest(extensionExportDigest, nameof(extensionExportDigest));
        ArgumentNullException.ThrowIfNull(baselineWaiverPolicy);
        ProtectedPolicyFrame.RequireDigest(bindingDigest, nameof(bindingDigest));
        var expectedKeys = new[]
        {
            "protocol.artifact.domain",
            "protocol.artifact.conformance-abstractions",
            "protocol.artifact.conformance-runtime",
            "protocol.artifact.policy",
        };
        ArgumentNullException.ThrowIfNull(artifacts);
        var materialized = new List<ProtectedPolicyArtifactBinding>(expectedKeys.Length);
        foreach (var artifact in artifacts)
        {
            if (artifact is null)
            {
                throw new ArgumentException(
                    "Null artifact rows are not allowed.",
                    nameof(artifacts));
            }
            if (materialized.Count == expectedKeys.Length)
            {
                throw new ArgumentOutOfRangeException(nameof(artifacts));
            }

            materialized.Add(artifact);
        }

        var rows = Array.AsReadOnly(materialized.ToArray());
        if (!rows.Select(static row => row.ArtifactKey).SequenceEqual(expectedKeys, StringComparer.Ordinal))
        {
            throw new ArgumentException("The protected pack requires the exact four artifact rows.", nameof(artifacts));
        }

        var computed = ComputeDigest(
            manifestDigest,
            extensionExportDigest,
            baselineWaiverPolicy.SnapshotDigest,
            rows);
        if (!computed.Equals(bindingDigest))
        {
            throw new ArgumentException("The binding digest does not match the protected pack.", nameof(bindingDigest));
        }

        return new ProtectedPolicyPackBinding(
            manifestDigest, extensionExportDigest, baselineWaiverPolicy, rows, computed);
    }

    internal static ExactSha256Digest ComputeDigest(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest extensionExportDigest,
        ExactSha256Digest baselineWaiverSnapshotDigest,
        IReadOnlyList<ProtectedPolicyArtifactBinding> artifacts) =>
        ProtectedPolicyFrame.Hash("protocol.protected-policy-pack-binding/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, manifestDigest);
            ProtectedPolicyFrame.Digest(stream, extensionExportDigest);
            ProtectedPolicyFrame.Digest(stream, baselineWaiverSnapshotDigest);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)artifacts.Count));
            foreach (var row in artifacts)
            {
                ProtectedPolicyFrame.String(stream, row.ArtifactKey);
                ProtectedPolicyFrame.String(stream, row.FileName);
                ProtectedPolicyFrame.Int64(stream, row.FileLength);
                ProtectedPolicyFrame.Digest(stream, row.FileDigest);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)row.ComponentKeys.Count));
                foreach (var component in row.ComponentKeys)
                {
                    ProtectedPolicyFrame.String(stream, component);
                }
            }
        });
}

public interface IProtectedPolicyPackVerifier
{
    bool Verify(
        ProtectedPolicyPackBinding protectedBinding,
        ProtectedAuthorityEnvelope packProof);
}
