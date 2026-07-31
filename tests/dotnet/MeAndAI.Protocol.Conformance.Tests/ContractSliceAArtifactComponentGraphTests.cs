using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAArtifactComponentGraphTests
{
    private const int ExpectedClosedGraphByteLength = 2_743;
    private const string ExpectedClosedGraphManifestDigest =
        "e55e9fa0e2fc5930675409dda911af80fe22616b177402f464d6b4fd9428af40";
    private const string CanonicalProbeDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";

    private const string ManifestPrefix =
        """{"schema":"protocol.policy-manifest.v1","authorityKind":"qualification-slice","sourceCommit":"0000000000000000000000000000000000000001","protocolVersion":"0.0.0","catalogVersion":1,"slice":{"sliceKey":"protocol.catalog-slice.test-empty","sliceVersion":"1","rules":[]},"schemaRegistry":{"payloadSchemas":[],"parsers":[],"indexes":[],"demandProjectors":[],"admissionProofContracts":[],"cacheBudget":{"maxDecodeEntries":1,"maxDecodeCanonicalBytes":1,"maxIndexEntries":1,"maxIndexNodes":1,"maxConcurrentDecodeAttempts":1,"maxConcurrentIndexAttempts":1,"retentionPolicy":"retain-lowest-canonical-keys"}}""";

    private const string ActivationProofReference =
        """{"componentKey":"protocol.activation-proof.test","componentVersion":"1"}""";

    private const string ActivationProofContract =
        """{"contractKey":"protocol.activation-proof.test","contractVersion":"1","proofComponent":""" +
        ActivationProofReference +
        "}";

    private const string ProofArtifactRow =
        """{"fileName":"ContractSliceA.Proof.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""";
    private const string MarkdigArtifactRow =
        """{"fileName":"Markdig.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""";
    private const string ConformanceAbstractionsArtifactRow =
        """{"fileName":"MeAndAI.Protocol.Conformance.Abstractions.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""";
    private const string ConformanceArtifactRow =
        """{"fileName":"MeAndAI.Protocol.Conformance.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""";
    private const string DomainArtifactRow =
        """{"fileName":"MeAndAI.Protocol.Domain.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""";

    private const string CanonicalArtifactRows =
        ProofArtifactRow + "," +
        MarkdigArtifactRow + "," +
        ConformanceAbstractionsArtifactRow + "," +
        ConformanceArtifactRow + "," +
        DomainArtifactRow;

    private const string ProofComponentIdentity =
        """{"componentKey":"protocol.activation-proof.test","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"}""";
    private const string RuntimeConformanceComponentIdentity =
        """{"componentKey":"protocol.runtime.conformance","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance","typeName":"MeAndAI.Protocol.Conformance.CatalogIntegrityException"}""";
    private const string RuntimeConformanceAbstractionsComponentIdentity =
        """{"componentKey":"protocol.runtime.conformance-abstractions","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Abstractions","typeName":"MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport"}""";
    private const string RuntimeDomainComponentIdentity =
        """{"componentKey":"protocol.runtime.domain","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Domain","typeName":"MeAndAI.Protocol.Domain.RuleId"}""";
    private const string RuntimeMarkdigComponentIdentity =
        """{"componentKey":"protocol.runtime.markdig","componentVersion":"1","assemblyName":"Markdig","typeName":"Markdig.Markdown"}""";

    private const string ProofComponentRow =
        """{"component":""" + ProofComponentIdentity +
        ""","artifactFileName":"ContractSliceA.Proof.dll"}""";
    private const string RuntimeConformanceComponentRow =
        """{"component":""" + RuntimeConformanceComponentIdentity +
        ""","artifactFileName":"MeAndAI.Protocol.Conformance.dll"}""";
    private const string RuntimeConformanceAbstractionsComponentRow =
        """{"component":""" + RuntimeConformanceAbstractionsComponentIdentity +
        ""","artifactFileName":"MeAndAI.Protocol.Conformance.Abstractions.dll"}""";
    private const string RuntimeDomainComponentRow =
        """{"component":""" + RuntimeDomainComponentIdentity +
        ""","artifactFileName":"MeAndAI.Protocol.Domain.dll"}""";
    private const string AliasedDomainComponentRow =
        """{"component":{"componentKey":"protocol.activation-proof.alias","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Domain","typeName":"MeAndAI.Protocol.Domain.RuleId"},"artifactFileName":"MeAndAI.Protocol.Domain.dll"}""";
    private const string RuntimeMarkdigComponentRow =
        """{"component":""" + RuntimeMarkdigComponentIdentity +
        ""","artifactFileName":"Markdig.dll"}""";

    private const string CanonicalComponentRows =
        ProofComponentRow + "," +
        RuntimeConformanceComponentRow + "," +
        RuntimeConformanceAbstractionsComponentRow + "," +
        RuntimeDomainComponentRow + "," +
        RuntimeMarkdigComponentRow;

    private const string ClosedGraphManifest =
        ManifestPrefix +
        ",\"activationProofContract\":" + ActivationProofContract +
        ",\"artifactFiles\":[" + CanonicalArtifactRows + "]" +
        ",\"components\":[" + CanonicalComponentRows + "]}" +
        "\n";

    private const string UnreferencedComponentRow =
        """{"component":{"componentKey":"protocol.runtime.unreferenced","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.UnreferencedComponent"},"artifactFileName":"ContractSliceA.Proof.dll"}""";

    private static readonly UTF8Encoding StrictUtf8 = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_binding_runtime_anchor_and_reachability_graph()
    {
        var canonicalBytes = AsBytes(ClosedGraphManifest);
        Assert.Equal(ExpectedClosedGraphByteLength, canonicalBytes.Length);
        Assert.Equal(
            ExpectedClosedGraphManifestDigest,
            Convert.ToHexString(SHA256.HashData(canonicalBytes))
                .ToLowerInvariant());

        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalBytes);
        Assert.Equal(
            ExpectedClosedGraphManifestDigest,
            manifest.ManifestDigest.Value);
        Assert.Equal(
            canonicalBytes,
            CanonicalManifestWriter.Write(manifest));

        Assert.Equal(
            CatalogAuthorityKind.QualificationSlice,
            manifest.AuthorityKind);
        Assert.Equal(
            "protocol.activation-proof.test",
            manifest.ActivationProofContract.ContractKey);
        Assert.Equal("1", manifest.ActivationProofContract.ContractVersion);
        Assert.Equal(
            (
                "protocol.activation-proof.test",
                "1",
                "MeAndAI.Protocol.Conformance.Tests",
                "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"),
            ToTuple(manifest.ActivationProofContract.ProofComponent));

        Assert.Equal(
            [
                ("ContractSliceA.Proof.dll", 1L, CanonicalProbeDigest),
                ("Markdig.dll", 1L, CanonicalProbeDigest),
                ("MeAndAI.Protocol.Conformance.Abstractions.dll", 1L, CanonicalProbeDigest),
                ("MeAndAI.Protocol.Conformance.dll", 1L, CanonicalProbeDigest),
                ("MeAndAI.Protocol.Domain.dll", 1L, CanonicalProbeDigest),
            ],
            manifest.ArtifactFiles.Select(artifact => (
                artifact.FileName,
                artifact.ByteLength,
                artifact.ArtifactDigest.Value)));

        Assert.Equal(
            [
                ("protocol.activation-proof.test", "1", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof", "ContractSliceA.Proof.dll"),
                ("protocol.runtime.conformance", "1", "MeAndAI.Protocol.Conformance", "MeAndAI.Protocol.Conformance.CatalogIntegrityException", "MeAndAI.Protocol.Conformance.dll"),
                ("protocol.runtime.conformance-abstractions", "1", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
                ("protocol.runtime.domain", "1", "MeAndAI.Protocol.Domain", "MeAndAI.Protocol.Domain.RuleId", "MeAndAI.Protocol.Domain.dll"),
                ("protocol.runtime.markdig", "1", "Markdig", "Markdig.Markdown", "Markdig.dll"),
            ],
            manifest.Components.Select(binding => (
                binding.Component.ComponentKey,
                binding.Component.ComponentVersion,
                binding.Component.AssemblyName,
                binding.Component.TypeName,
                binding.ArtifactFileName)));

        var invalidManifests = new (string Name, string Manifest)[]
        {
            (
                "artifact-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofArtifactRow + "," + MarkdigArtifactRow,
                    MarkdigArtifactRow + "," + ProofArtifactRow)),
            (
                "component-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofComponentRow + "," + RuntimeConformanceComponentRow,
                    RuntimeConformanceComponentRow + "," + ProofComponentRow)),
            (
                "duplicate-artifact-file-name",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"fileName\":\"Markdig.dll\"",
                    "\"fileName\":\"ContractSliceA.Proof.dll\"")),
            (
                "duplicate-component-key-version",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"componentKey\":\"protocol.runtime.conformance-abstractions\"",
                    "\"componentKey\":\"protocol.runtime.conformance\"")),
            (
                "duplicate-physical-component-type",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"assemblyName\":\"MeAndAI.Protocol.Conformance.Tests\",\"typeName\":\"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof\"",
                    "\"assemblyName\":\"MeAndAI.Protocol.Conformance\",\"typeName\":\"MeAndAI.Protocol.Conformance.CatalogIntegrityException\"")),
            (
                "runtime-anchor-artifact-swap",
                SwapRequired(
                    ClosedGraphManifest,
                    "\"artifactFileName\":\"Markdig.dll\"",
                    "\"artifactFileName\":\"MeAndAI.Protocol.Domain.dll\"")),
            (
                "component-maps-undeclared-artifact",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"artifactFileName\":\"Markdig.dll\"",
                    "\"artifactFileName\":\"Missing.dll\"")),
            (
                "artifact-unused-by-components",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"artifactFileName\":\"Markdig.dll\"",
                    "\"artifactFileName\":\"MeAndAI.Protocol.Domain.dll\"")),
            (
                "activation-proof-component-undeclared",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ActivationProofReference,
                    """{"componentKey":"protocol.activation-proof.missing","componentVersion":"1"}""")),
            (
                "runtime-anchor-used-as-activation-proof",
                BuildRuntimeAnchorProofManifest()),
            (
                "runtime-physical-type-aliased-as-activation-proof",
                BuildAliasedRuntimePhysicalProofManifest()),
            (
                "unreferenced-component",
                ReplaceRequired(
                    ClosedGraphManifest,
                    RuntimeMarkdigComponentRow + "]}\n",
                    RuntimeMarkdigComponentRow + "," + UnreferencedComponentRow + "]}\n")),
            (
                "alternate-runtime-anchor-identity",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"assemblyName\":\"MeAndAI.Protocol.Conformance\",\"typeName\":\"MeAndAI.Protocol.Conformance.CatalogIntegrityException\"",
                    "\"assemblyName\":\"MeAndAI.Protocol.Conformance\",\"typeName\":\"MeAndAI.Protocol.Conformance.AlternateIntegrityException\"")),
            (
                "empty-artifact-array",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"artifactFiles\":[" + CanonicalArtifactRows + "]",
                    "\"artifactFiles\":[]")),
            (
                "empty-component-array",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"components\":[" + CanonicalComponentRows + "]",
                    "\"components\":[]")),
            (
                "component-missing-artifact-binding",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofComponentRow,
                    """{"component":""" + ProofComponentIdentity + "}")),
            (
                "activation-proof-contract-missing",
                RemoveRequired(
                    ClosedGraphManifest,
                    ",\"activationProofContract\":" + ActivationProofContract)),
            (
                "activation-proof-contract-null",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"activationProofContract\":" + ActivationProofContract,
                    "\"activationProofContract\":null")),
            (
                "activation-proof-contract-property-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"contractKey\":\"protocol.activation-proof.test\",\"contractVersion\":\"1\"",
                    "\"contractVersion\":\"1\",\"contractKey\":\"protocol.activation-proof.test\"")),
            (
                "activation-proof-contract-unknown-property",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"contractKey\":\"protocol.activation-proof.test\"",
                    "\"unknown\":0,\"contractKey\":\"protocol.activation-proof.test\"")),
            (
                "activation-proof-component-missing",
                RemoveRequired(
                    ClosedGraphManifest,
                    ",\"proofComponent\":" + ActivationProofReference)),
            (
                "activation-proof-component-null",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"proofComponent\":" + ActivationProofReference,
                    "\"proofComponent\":null")),
            (
                "activation-proof-reference-property-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ActivationProofReference,
                    """{"componentVersion":"1","componentKey":"protocol.activation-proof.test"}""")),
            (
                "activation-proof-reference-unknown-property",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ActivationProofReference,
                    """{"componentKey":"protocol.activation-proof.test","componentVersion":"1","unknown":0}""")),
            (
                "activation-proof-reference-null",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ActivationProofReference,
                    """{"componentKey":null,"componentVersion":"1"}""")),
            (
                "artifact-property-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofArtifactRow,
                    """{"byteLength":1,"fileName":"ContractSliceA.Proof.dll","artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""")),
            (
                "artifact-unknown-property",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofArtifactRow,
                    """{"fileName":"ContractSliceA.Proof.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d","unknown":0}""")),
            (
                "artifact-null-file-name",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofArtifactRow,
                    """{"fileName":null,"byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""")),
            (
                "artifact-invalid-basename",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"fileName\":\"ContractSliceA.Proof.dll\"",
                    "\"fileName\":\"nested/ContractSliceA.Proof.dll\"")),
            (
                "artifact-zero-byte-length",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofArtifactRow,
                    """{"fileName":"ContractSliceA.Proof.dll","byteLength":0,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}""")),
            (
                "artifact-invalid-digest",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofArtifactRow,
                    """{"fileName":"ContractSliceA.Proof.dll","byteLength":1,"artifactDigest":"6E340B9CFC37A989CA544E6BB780A2C78901D3FB33738768511A30617AFA01D"}""")),
            (
                "component-binding-property-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofComponentRow,
                    """{"artifactFileName":"ContractSliceA.Proof.dll","component":""" + ProofComponentIdentity + "}")),
            (
                "component-identity-property-order",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofComponentIdentity,
                    """{"componentVersion":"1","componentKey":"protocol.activation-proof.test","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"}""")),
            (
                "component-identity-unknown-property",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofComponentIdentity,
                    """{"componentKey":"protocol.activation-proof.test","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof","unknown":0}""")),
            (
                "component-identity-null",
                ReplaceRequired(
                    ClosedGraphManifest,
                    ProofComponentIdentity,
                    """{"componentKey":"protocol.activation-proof.test","componentVersion":"1","assemblyName":null,"typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"}""")),
            (
                "component-artifact-file-name-null",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"artifactFileName\":\"ContractSliceA.Proof.dll\"",
                    "\"artifactFileName\":null")),
            (
                "component-artifact-invalid-basename",
                ReplaceRequired(
                    ClosedGraphManifest,
                    "\"artifactFileName\":\"ContractSliceA.Proof.dll\"",
                    "\"artifactFileName\":\"nested/ContractSliceA.Proof.dll\"")),
        };

        foreach (var vector in invalidManifests)
        {
            AssertPublicFormatException(vector.Name, vector.Manifest);
        }
    }

    private static (
        string ComponentKey,
        string ComponentVersion,
        string AssemblyName,
        string TypeName) ToTuple(ComponentTypeIdentity component) =>
        (
            component.ComponentKey,
            component.ComponentVersion,
            component.AssemblyName,
            component.TypeName);

    private static byte[] AsBytes(string value) =>
        StrictUtf8.GetBytes(value);

    private static string BuildRuntimeAnchorProofManifest()
    {
        var manifest = ReplaceRequired(
            ClosedGraphManifest,
            ActivationProofReference,
            """{"componentKey":"protocol.runtime.domain","componentVersion":"1"}""");
        manifest = RemoveRequired(manifest, ProofArtifactRow + ",");
        return RemoveRequired(manifest, ProofComponentRow + ",");
    }

    private static string BuildAliasedRuntimePhysicalProofManifest()
    {
        var manifest = ReplaceRequired(
            ClosedGraphManifest,
            ActivationProofReference,
            """{"componentKey":"protocol.activation-proof.alias","componentVersion":"1"}""");
        manifest = RemoveRequired(manifest, ProofArtifactRow + ",");
        manifest = RemoveRequired(manifest, ProofComponentRow + ",");
        return ReplaceRequired(
            manifest,
            RuntimeConformanceComponentRow + "," +
            RuntimeConformanceAbstractionsComponentRow + "," +
            RuntimeDomainComponentRow + "," +
            RuntimeMarkdigComponentRow,
            AliasedDomainComponentRow + "," +
            RuntimeConformanceComponentRow + "," +
            RuntimeConformanceAbstractionsComponentRow + "," +
            RuntimeMarkdigComponentRow);
    }

    private static string RemoveRequired(string value, string text) =>
        ReplaceRequired(value, text, string.Empty);

    private static string ReplaceRequired(
        string value,
        string oldText,
        string newText)
    {
        if (oldText.Length == 0 ||
            string.Equals(oldText, newText, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "A required manifest mutation must make a non-empty change.");
        }

        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0 ||
            value.IndexOf(
                oldText,
                index + oldText.Length,
                StringComparison.Ordinal) >= 0)
        {
            throw new InvalidOperationException(
                $"A required mutation marker was absent or ambiguous: {oldText}");
        }

        var result = value.Remove(index, oldText.Length)
            .Insert(index, newText);
        if (string.Equals(result, value, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "A required manifest mutation was a no-op.");
        }

        return result;
    }

    private static string SwapRequired(
        string value,
        string left,
        string right)
    {
        const string Sentinel = "__contract_slice_a_graph_swap__";
        if (value.Contains(Sentinel, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "The manifest already contains the swap sentinel.");
        }

        var result = ReplaceRequired(value, left, Sentinel);
        result = ReplaceRequired(result, right, left);
        return ReplaceRequired(result, Sentinel, right);
    }

    private static void AssertPublicFormatException(
        string vectorName,
        string manifest)
    {
        if (string.Equals(manifest, ClosedGraphManifest, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                $"The '{vectorName}' mutation was a no-op.");
        }

        var exception = Record.Exception(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(AsBytes(manifest));
        });

        Assert.True(
            exception?.GetType() == typeof(FormatException),
            $"Vector '{vectorName}' must produce exact FormatException; " +
            $"actual: {exception?.GetType().FullName ?? "<none>"}.");
    }
}
