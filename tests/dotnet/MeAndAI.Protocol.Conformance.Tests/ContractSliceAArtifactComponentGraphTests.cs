using System.Text;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAArtifactComponentGraphTests
{
    private const string CanonicalProbeDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";

    private const string ClosedGraphManifest =
        """{"schema":"protocol.policy-manifest.v1","authorityKind":"qualification-slice","sourceCommit":"0000000000000000000000000000000000000001","protocolVersion":"0.0.0","catalogVersion":1,"slice":{"sliceKey":"protocol.catalog-slice.test-empty","sliceVersion":"1","rules":[]},"schemaRegistry":{"payloadSchemas":[],"parsers":[],"indexes":[],"demandProjectors":[],"admissionProofContracts":[],"cacheBudget":{"maxDecodeEntries":1,"maxDecodeCanonicalBytes":1,"maxIndexEntries":1,"maxIndexNodes":1,"maxConcurrentDecodeAttempts":1,"maxConcurrentIndexAttempts":1,"retentionPolicy":"retain-lowest-canonical-keys"}},"activationProofContract":{"contractKey":"protocol.activation-proof.test","contractVersion":"1","proofComponent":{"componentKey":"protocol.activation-proof.test","componentVersion":"1"}},"artifactFiles":[{"fileName":"ContractSliceA.Proof.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"},{"fileName":"MeAndAI.Protocol.Domain.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"},{"fileName":"MeAndAI.Protocol.Conformance.Abstractions.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"},{"fileName":"MeAndAI.Protocol.Conformance.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"},{"fileName":"Markdig.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}],"components":[{"component":{"componentKey":"protocol.activation-proof.test","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"},"artifactFileName":"ContractSliceA.Proof.dll"},{"component":{"componentKey":"protocol.runtime.domain","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Domain","typeName":"MeAndAI.Protocol.Domain.RuleId"},"artifactFileName":"MeAndAI.Protocol.Domain.dll"},{"component":{"componentKey":"protocol.runtime.conformance-abstractions","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Abstractions","typeName":"MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport"},"artifactFileName":"MeAndAI.Protocol.Conformance.Abstractions.dll"},{"component":{"componentKey":"protocol.runtime.conformance","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance","typeName":"MeAndAI.Protocol.Conformance.CatalogIntegrityException"},"artifactFileName":"MeAndAI.Protocol.Conformance.dll"},{"component":{"componentKey":"protocol.runtime.markdig","componentVersion":"1","assemblyName":"Markdig","typeName":"Markdig.Markdown"},"artifactFileName":"Markdig.dll"}]}""" + "\n";

    private static readonly UTF8Encoding StrictUtf8 = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_binding_runtime_anchor_and_reachability_graph()
    {
        var manifest =
            FinalizedPolicyManifest.ParseCanonical(AsBytes(ClosedGraphManifest));

        Assert.Equal(5, manifest.ArtifactFiles.Count);
        Assert.Equal(5, manifest.Components.Count);
        Assert.Equal(
            [
                "ContractSliceA.Proof.dll",
                "MeAndAI.Protocol.Domain.dll",
                "MeAndAI.Protocol.Conformance.Abstractions.dll",
                "MeAndAI.Protocol.Conformance.dll",
                "Markdig.dll",
            ],
            manifest.ArtifactFiles.Select(artifact => artifact.FileName));

        var components = manifest.Components
            .Select(item => item.Component)
            .ToArray();
        Assert.Equal(
            [
                ("protocol.activation-proof.test", "1", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"),
                ("protocol.runtime.domain", "1", "MeAndAI.Protocol.Domain", "MeAndAI.Protocol.Domain.RuleId"),
                ("protocol.runtime.conformance-abstractions", "1", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport"),
                ("protocol.runtime.conformance", "1", "MeAndAI.Protocol.Conformance", "MeAndAI.Protocol.Conformance.CatalogIntegrityException"),
                ("protocol.runtime.markdig", "1", "Markdig", "Markdig.Markdown"),
            ],
            components.Select(component => (
                component.ComponentKey,
                component.ComponentVersion,
                component.AssemblyName,
                component.TypeName)));

        Assert.All(
            manifest.Components,
            component =>
            {
                var artifact = Assert.Single(
                    manifest.ArtifactFiles.Where(file => file.FileName == component.ArtifactFileName));
                Assert.Equal(1L, artifact.ByteLength);
                Assert.Equal(CanonicalProbeDigest, artifact.ArtifactDigest.Value);
            });

        AssertPublicFormatException(
            ReplaceFirst(
                ClosedGraphManifest,
                "\"proofComponent\":{\"componentKey\":\"protocol.activation-proof.test\",\"componentVersion\":\"1\"}",
                "\"proofComponent\":{\"componentKey\":\"protocol.activation-proof.missing\",\"componentVersion\":\"1\"}"));
        AssertPublicFormatException(
            ReplaceFirst(
                ClosedGraphManifest,
                "\"componentKey\":\"protocol.runtime.conformance\"",
                "\"componentKey\":\"protocol.runtime.unreferenced\""));
        AssertPublicFormatException(
            ReplaceFirst(
                ClosedGraphManifest,
                "\"artifactFileName\":\"Markdig.dll\"",
                "\"artifactFileName\":\"MeAndAI.Protocol.Domain.dll\"");
        AssertPublicFormatException(
            ReplaceFirst(
                ClosedGraphManifest,
                "\"componentKey\":\"protocol.runtime.domain\"",
                "\"componentKey\":\"protocol.activation-proof.test\""));
    }

    private static byte[] AsBytes(string value) =>
        StrictUtf8.GetBytes(value);

    private static string ReplaceFirst(
        string value,
        string oldText,
        string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0)
        {
            return value;
        }

        return value.Remove(index, oldText.Length)
            .Insert(index, newText);
    }

    private static void AssertPublicFormatException(string manifest) =>
        Assert.Throws<FormatException>(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(AsBytes(manifest));
        });
}
