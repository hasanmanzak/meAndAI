using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAManifestTests
{
    private const string ExpectedManifestDigest =
        "59ef47142c3c0d1e39825bd0e2e11d8f28093bed1ad93c12e251bb95cf5a4d64";
    private const string ExpectedArtifactDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    internal const string MinimalCanonicalManifest = """{"schema":"protocol.policy-manifest.v1","authorityKind":"qualification-slice","sourceCommit":"0000000000000000000000000000000000000001","protocolVersion":"0.0.0","catalogVersion":1,"slice":{"sliceKey":"protocol.catalog-slice.test-empty","sliceVersion":"1","rules":[]},"schemaRegistry":{"payloadSchemas":[],"parsers":[],"indexes":[],"demandProjectors":[],"admissionProofContracts":[],"cacheBudget":{"maxDecodeEntries":1,"maxDecodeCanonicalBytes":1,"maxIndexEntries":1,"maxIndexNodes":1,"maxConcurrentDecodeAttempts":1,"maxConcurrentIndexAttempts":1,"retentionPolicy":"retain-lowest-canonical-keys"}},"activationProofContract":{"contractKey":"protocol.activation-proof.test","contractVersion":"1","proofComponent":{"componentKey":"protocol.activation-proof.test","componentVersion":"1"}},"artifactFiles":[{"fileName":"ContractSliceA.Proof.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}],"components":[{"component":{"componentKey":"protocol.activation-proof.test","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"},"artifactFileName":"ContractSliceA.Proof.dll"}]}""" + "\n";

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void Parses_minimal_canonical_qualification_manifest()
    {
        var canonicalBytes = new UTF8Encoding(
            encoderShouldEmitUTF8Identifier: false,
            throwOnInvalidBytes: true)
            .GetBytes(MinimalCanonicalManifest);

        Assert.Equal(1_222, canonicalBytes.Length);
        Assert.Equal(
            ExpectedManifestDigest,
            Convert.ToHexString(SHA256.HashData(canonicalBytes))
                .ToLowerInvariant());

        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalBytes);

        Array.Fill(canonicalBytes, byte.MaxValue);

        Assert.Equal(CatalogAuthorityKind.QualificationSlice, manifest.AuthorityKind);
        Assert.Equal(
            "0000000000000000000000000000000000000001",
            manifest.SourceCommit);
        Assert.Equal(ExpectedManifestDigest, manifest.ManifestDigest.Value);
        Assert.Null(manifest.CompleteCatalog);

        var slice = Assert.IsType<CatalogSliceDeclaration>(manifest.Slice);
        Assert.Equal("protocol.catalog-slice.test-empty", slice.SliceKey);
        Assert.Equal("1", slice.SliceVersion);
        Assert.Equal("0.0.0", slice.ProtocolVersion);
        Assert.Equal(1, slice.CatalogVersion.Value);
        Assert.Empty(slice.Rules);

        var registry = manifest.SchemaRegistry;
        Assert.Empty(registry.PayloadSchemas);
        Assert.Empty(registry.Parsers);
        Assert.Empty(registry.Indexes);
        Assert.Empty(registry.DemandProjectors);
        Assert.Empty(registry.AdmissionProofContracts);
        Assert.Equal(1, registry.CacheBudget.MaxDecodeEntries);
        Assert.Equal(1, registry.CacheBudget.MaxDecodeCanonicalBytes);
        Assert.Equal(1, registry.CacheBudget.MaxIndexEntries);
        Assert.Equal(1, registry.CacheBudget.MaxIndexNodes);
        Assert.Equal(1, registry.CacheBudget.MaxConcurrentDecodeAttempts);
        Assert.Equal(1, registry.CacheBudget.MaxConcurrentIndexAttempts);
        Assert.Equal(
            CacheRetentionPolicy.RetainLowestCanonicalKeys,
            registry.CacheBudget.RetentionPolicy);

        var activationProof = manifest.ActivationProofContract;
        Assert.Equal("protocol.activation-proof.test", activationProof.ContractKey);
        Assert.Equal("1", activationProof.ContractVersion);
        AssertComponentIdentity(activationProof.ProofComponent);

        var artifact = Assert.Single(manifest.ArtifactFiles);
        Assert.Equal("ContractSliceA.Proof.dll", artifact.FileName);
        Assert.Equal(1, artifact.ByteLength);
        Assert.Equal(ExpectedArtifactDigest, artifact.ArtifactDigest.Value);

        var component = Assert.Single(manifest.Components);
        AssertComponentIdentity(component.Component);
        Assert.Equal("ContractSliceA.Proof.dll", component.ArtifactFileName);
        Assert.Equal(
            manifest.ArtifactFiles.Select(binding => binding.FileName),
            manifest.Components.Select(binding => binding.ArtifactFileName));

        Assert.Equal(ExpectedManifestDigest, manifest.ManifestDigest.Value);
        Assert.Equal("protocol.catalog-slice.test-empty", manifest.Slice?.SliceKey);
        Assert.Equal("protocol.activation-proof.test", manifest
            .ActivationProofContract
            .ProofComponent
            .ComponentKey);
        Assert.Equal("ContractSliceA.Proof.dll", Assert
            .Single(manifest.ArtifactFiles)
            .FileName);
        Assert.Equal("ContractSliceA.Proof.dll", Assert
            .Single(manifest.Components)
            .ArtifactFileName);
    }

    private static void AssertComponentIdentity(ComponentTypeIdentity component)
    {
        Assert.Equal("protocol.activation-proof.test", component.ComponentKey);
        Assert.Equal("1", component.ComponentVersion);
        Assert.Equal(
            "MeAndAI.Protocol.Conformance.Tests",
            component.AssemblyName);
        Assert.Equal(
            "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof",
            component.TypeName);
    }
}
