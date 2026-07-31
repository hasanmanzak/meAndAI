using System.Buffers;
using System.Security.Cryptography;
using System.Text.Json;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class CanonicalManifestWriter
{
    private const string SchemaKey = "protocol.policy-manifest.v1";

    internal static byte[] Write(ParsedCanonicalManifest manifest)
    {
        ArgumentNullException.ThrowIfNull(manifest);

        var slice = manifest.Slice;
        if (!manifest.AuthorityKind.Equals(
                CatalogAuthorityKind.QualificationSlice) ||
            slice.Rules.Count != 0 ||
            manifest.SchemaRegistry.PayloadSchemas.Count != 0 ||
            manifest.SchemaRegistry.Parsers.Count != 0 ||
            manifest.SchemaRegistry.Indexes.Count != 0 ||
            manifest.SchemaRegistry.DemandProjectors.Count != 0 ||
            manifest.SchemaRegistry.AdmissionProofContracts.Count != 0 ||
            manifest.ArtifactFiles.Count != 1 ||
            manifest.Components.Count != 1)
        {
            throw new InvalidOperationException(
                "This writer increment supports only the minimal qualification slice.");
        }

        var buffer = new ArrayBufferWriter<byte>();
        using (var writer = new Utf8JsonWriter(
                   buffer,
                   new JsonWriterOptions
                   {
                       Indented = false,
                       SkipValidation = false,
                   }))
        {
            WriteManifest(writer, manifest, slice);
        }

        var result = GC.AllocateUninitializedArray<byte>(
            buffer.WrittenCount + 1);
        buffer.WrittenSpan.CopyTo(result);
        result[^1] = (byte)'\n';
        return result;
    }

    private static void WriteManifest(
        Utf8JsonWriter writer,
        ParsedCanonicalManifest manifest,
        CatalogSliceDeclaration slice)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "schema", SchemaKey);
        WriteCanonicalString(
            writer,
            "authorityKind",
            manifest.AuthorityKind.Value);
        WriteCanonicalString(writer, "sourceCommit", manifest.SourceCommit);
        WriteCanonicalString(
            writer,
            "protocolVersion",
            slice.ProtocolVersion);
        writer.WriteNumber("catalogVersion", slice.CatalogVersion.Value);

        writer.WritePropertyName("slice");
        writer.WriteStartObject();
        WriteCanonicalString(writer, "sliceKey", slice.SliceKey);
        WriteCanonicalString(writer, "sliceVersion", slice.SliceVersion);
        writer.WriteStartArray("rules");
        writer.WriteEndArray();
        writer.WriteEndObject();

        WriteSchemaRegistry(writer, manifest.SchemaRegistry);
        WriteActivationProof(writer, manifest.ActivationProofContract);
        WriteArtifactFiles(writer, manifest.ArtifactFiles);
        WriteComponents(writer, manifest.Components);
        writer.WriteEndObject();
    }

    private static void WriteSchemaRegistry(
        Utf8JsonWriter writer,
        ReleaseSchemaRegistry registry)
    {
        writer.WritePropertyName("schemaRegistry");
        writer.WriteStartObject();
        WriteEmptyArray(writer, "payloadSchemas");
        WriteEmptyArray(writer, "parsers");
        WriteEmptyArray(writer, "indexes");
        WriteEmptyArray(writer, "demandProjectors");
        WriteEmptyArray(writer, "admissionProofContracts");

        var budget = registry.CacheBudget;
        writer.WritePropertyName("cacheBudget");
        writer.WriteStartObject();
        writer.WriteNumber("maxDecodeEntries", budget.MaxDecodeEntries);
        writer.WriteNumber(
            "maxDecodeCanonicalBytes",
            budget.MaxDecodeCanonicalBytes);
        writer.WriteNumber("maxIndexEntries", budget.MaxIndexEntries);
        writer.WriteNumber("maxIndexNodes", budget.MaxIndexNodes);
        writer.WriteNumber(
            "maxConcurrentDecodeAttempts",
            budget.MaxConcurrentDecodeAttempts);
        writer.WriteNumber(
            "maxConcurrentIndexAttempts",
            budget.MaxConcurrentIndexAttempts);
        WriteCanonicalString(
            writer,
            "retentionPolicy",
            budget.RetentionPolicy.Value);
        writer.WriteEndObject();
        writer.WriteEndObject();
    }

    private static void WriteActivationProof(
        Utf8JsonWriter writer,
        ActivationProofContractDeclaration activationProof)
    {
        writer.WritePropertyName("activationProofContract");
        writer.WriteStartObject();
        WriteCanonicalString(
            writer,
            "contractKey",
            activationProof.ContractKey);
        WriteCanonicalString(
            writer,
            "contractVersion",
            activationProof.ContractVersion);
        writer.WritePropertyName("proofComponent");
        writer.WriteStartObject();
        WriteCanonicalString(
            writer,
            "componentKey",
            activationProof.ProofComponent.ComponentKey);
        WriteCanonicalString(
            writer,
            "componentVersion",
            activationProof.ProofComponent.ComponentVersion);
        writer.WriteEndObject();
        writer.WriteEndObject();
    }

    private static void WriteArtifactFiles(
        Utf8JsonWriter writer,
        IReadOnlyList<ArtifactFileBinding> artifactFiles)
    {
        writer.WriteStartArray("artifactFiles");
        foreach (var artifact in artifactFiles)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "fileName", artifact.FileName);
            writer.WriteNumber("byteLength", artifact.ByteLength);
            WriteCanonicalString(
                writer,
                "artifactDigest",
                artifact.ArtifactDigest.Value);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteComponents(
        Utf8JsonWriter writer,
        IReadOnlyList<ComponentArtifactBinding> components)
    {
        writer.WriteStartArray("components");
        foreach (var binding in components)
        {
            writer.WriteStartObject();
            writer.WritePropertyName("component");
            writer.WriteStartObject();
            WriteCanonicalString(
                writer,
                "componentKey",
                binding.Component.ComponentKey);
            WriteCanonicalString(
                writer,
                "componentVersion",
                binding.Component.ComponentVersion);
            WriteCanonicalString(
                writer,
                "assemblyName",
                binding.Component.AssemblyName);
            WriteCanonicalString(
                writer,
                "typeName",
                binding.Component.TypeName);
            writer.WriteEndObject();
            WriteCanonicalString(
                writer,
                "artifactFileName",
                binding.ArtifactFileName);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteCanonicalString(
        Utf8JsonWriter writer,
        string propertyName,
        string value)
    {
        writer.WritePropertyName(propertyName);
        var quotedUtf8 =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(value);
        try
        {
            writer.WriteRawValue(
                quotedUtf8,
                skipInputValidation: false);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(quotedUtf8);
        }
    }

    private static void WriteEmptyArray(
        Utf8JsonWriter writer,
        string propertyName)
    {
        writer.WriteStartArray(propertyName);
        writer.WriteEndArray();
    }
}
