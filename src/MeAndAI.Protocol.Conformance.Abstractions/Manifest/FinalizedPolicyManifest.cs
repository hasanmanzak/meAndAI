using System.Security.Cryptography;
using System.Text.Json;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class FinalizedPolicyManifest
{
    private FinalizedPolicyManifest(
        CatalogAuthorityKind authorityKind,
        string sourceCommit,
        ExactSha256Digest manifestDigest,
        ReleaseSchemaRegistry schemaRegistry,
        ActivationProofContractDeclaration activationProofContract,
        IReadOnlyList<ArtifactFileBinding> artifactFiles,
        IReadOnlyList<ComponentArtifactBinding> components,
        CatalogSliceDeclaration? slice,
        CompleteCatalogDeclaration? completeCatalog)
    {
        AuthorityKind = authorityKind;
        SourceCommit = sourceCommit;
        ManifestDigest = manifestDigest;
        SchemaRegistry = schemaRegistry;
        ActivationProofContract = activationProofContract;
        ArtifactFiles = artifactFiles;
        Components = components;
        Slice = slice;
        CompleteCatalog = completeCatalog;
    }

    public CatalogAuthorityKind AuthorityKind { get; }

    public string SourceCommit { get; }

    public ExactSha256Digest ManifestDigest { get; }

    public ReleaseSchemaRegistry SchemaRegistry { get; }

    public ActivationProofContractDeclaration ActivationProofContract { get; }

    public IReadOnlyList<ArtifactFileBinding> ArtifactFiles { get; }

    public IReadOnlyList<ComponentArtifactBinding> Components { get; }

    public CatalogSliceDeclaration? Slice { get; }

    public CompleteCatalogDeclaration? CompleteCatalog { get; }

    internal static FinalizedPolicyManifest ParseCanonical(
        ReadOnlyMemory<byte> canonicalBytes)
    {
        if (canonicalBytes.Length > CanonicalManifestReader.MaximumByteLength)
        {
            throw new FormatException(
                "The canonical policy manifest exceeds the byte ceiling.");
        }

        if (canonicalBytes.IsEmpty)
        {
            throw new FormatException(
                "The canonical policy manifest must not be empty.");
        }

        var privateBytes = canonicalBytes.ToArray();
        try
        {
            ParsedCanonicalManifest parsed;
            try
            {
                parsed = CanonicalManifestReader.Parse(privateBytes);
            }
            catch (JsonException exception)
            {
                throw new FormatException(
                    "The policy manifest is not canonical JSON.",
                    exception);
            }

            var reserializedBytes = CanonicalManifestWriter.Write(parsed);
            try
            {
                if (!privateBytes.AsSpan().SequenceEqual(reserializedBytes))
                {
                    throw new FormatException(
                        "The policy manifest bytes are not canonical.");
                }
            }
            finally
            {
                CryptographicOperations.ZeroMemory(reserializedBytes);
            }

            var manifestDigest = ExactSha256Digest.FromHashBytes(
                SHA256.HashData(privateBytes));
            return new FinalizedPolicyManifest(
                parsed.AuthorityKind,
                parsed.SourceCommit,
                manifestDigest,
                parsed.SchemaRegistry,
                parsed.ActivationProofContract,
                parsed.ArtifactFiles,
                parsed.Components,
                parsed.Slice,
                completeCatalog: null);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(privateBytes);
        }
    }
}
