using System.Security.Cryptography;
using System.Text.Json;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class CanonicalManifestReader
{
    internal const int MaximumByteLength = 16_777_216;

    private const int MaximumDepth = 64;
    private const int MaximumTokenCount = 1_000_000;
    private const string SchemaKey = "protocol.policy-manifest.v1";

    internal static ParsedCanonicalManifest Parse(ReadOnlySpan<byte> bytes)
    {
        ValidateEnvelope(bytes);

        var reader = new BoundedJsonReader(bytes[..^1]);
        reader.Expect(JsonTokenType.StartObject);

        reader.ExpectProperty("schema");
        if (!string.Equals(
                reader.ReadString(),
                SchemaKey,
                StringComparison.Ordinal))
        {
            throw new FormatException(
                "The policy manifest schema is not supported.");
        }

        reader.ExpectProperty("authorityKind");
        var authorityKind = CatalogAuthorityKind.Parse(reader.ReadString());
        if (!authorityKind.Equals(CatalogAuthorityKind.QualificationSlice))
        {
            throw new FormatException(
                "This parser increment requires qualification-slice authority.");
        }

        reader.ExpectProperty("sourceCommit");
        var sourceCommit = reader.ReadString();
        ValidateSourceCommit(sourceCommit);

        reader.ExpectProperty("protocolVersion");
        var protocolVersion = reader.ReadString();

        reader.ExpectProperty("catalogVersion");
        var catalogVersion = reader.ReadInt32();

        reader.ExpectProperty("slice");
        var slice = ReadSlice(ref reader);

        reader.ExpectProperty("schemaRegistry");
        var cacheBudget = ReadEmptySchemaRegistry(ref reader);

        reader.ExpectProperty("activationProofContract");
        var activationProof = ReadActivationProof(ref reader);

        reader.ExpectProperty("artifactFiles");
        var artifact = ReadSingleArtifact(ref reader);

        reader.ExpectProperty("components");
        var component = ReadSingleComponent(ref reader);

        reader.Expect(JsonTokenType.EndObject);
        reader.ExpectEndOfDocument();

        return CreateProjection(
            authorityKind,
            sourceCommit,
            protocolVersion,
            catalogVersion,
            slice,
            cacheBudget,
            activationProof,
            artifact,
            component);
    }

    private static RawSlice ReadSlice(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("sliceKey");
        var sliceKey = reader.ReadString();
        reader.ExpectProperty("sliceVersion");
        var sliceVersion = reader.ReadString();
        reader.ExpectProperty("rules");
        reader.ExpectEmptyArray();
        reader.Expect(JsonTokenType.EndObject);

        return new RawSlice(sliceKey, sliceVersion);
    }

    private static RawCacheBudget ReadEmptySchemaRegistry(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("payloadSchemas");
        reader.ExpectEmptyArray();
        reader.ExpectProperty("parsers");
        reader.ExpectEmptyArray();
        reader.ExpectProperty("indexes");
        reader.ExpectEmptyArray();
        reader.ExpectProperty("demandProjectors");
        reader.ExpectEmptyArray();
        reader.ExpectProperty("admissionProofContracts");
        reader.ExpectEmptyArray();
        reader.ExpectProperty("cacheBudget");

        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("maxDecodeEntries");
        var maxDecodeEntries = reader.ReadInt32();
        reader.ExpectProperty("maxDecodeCanonicalBytes");
        var maxDecodeCanonicalBytes = reader.ReadInt64();
        reader.ExpectProperty("maxIndexEntries");
        var maxIndexEntries = reader.ReadInt32();
        reader.ExpectProperty("maxIndexNodes");
        var maxIndexNodes = reader.ReadInt64();
        reader.ExpectProperty("maxConcurrentDecodeAttempts");
        var maxConcurrentDecodeAttempts = reader.ReadInt32();
        reader.ExpectProperty("maxConcurrentIndexAttempts");
        var maxConcurrentIndexAttempts = reader.ReadInt32();
        reader.ExpectProperty("retentionPolicy");
        var retentionPolicy = reader.ReadString();
        reader.Expect(JsonTokenType.EndObject);
        reader.Expect(JsonTokenType.EndObject);

        return new RawCacheBudget(
            maxDecodeEntries,
            maxDecodeCanonicalBytes,
            maxIndexEntries,
            maxIndexNodes,
            maxConcurrentDecodeAttempts,
            maxConcurrentIndexAttempts,
            retentionPolicy);
    }

    private static RawActivationProof ReadActivationProof(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("contractKey");
        var contractKey = reader.ReadString();
        reader.ExpectProperty("contractVersion");
        var contractVersion = reader.ReadString();
        reader.ExpectProperty("proofComponent");
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("componentKey");
        var componentKey = reader.ReadString();
        reader.ExpectProperty("componentVersion");
        var componentVersion = reader.ReadString();
        reader.Expect(JsonTokenType.EndObject);
        reader.Expect(JsonTokenType.EndObject);

        return new RawActivationProof(
            contractKey,
            contractVersion,
            componentKey,
            componentVersion);
    }

    private static RawArtifact ReadSingleArtifact(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("fileName");
        var fileName = reader.ReadString();
        reader.ExpectProperty("byteLength");
        var byteLength = reader.ReadInt64();
        reader.ExpectProperty("artifactDigest");
        var artifactDigest = reader.ReadString();
        reader.Expect(JsonTokenType.EndObject);
        reader.Expect(JsonTokenType.EndArray);

        return new RawArtifact(fileName, byteLength, artifactDigest);
    }

    private static RawComponent ReadSingleComponent(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("component");
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("componentKey");
        var componentKey = reader.ReadString();
        reader.ExpectProperty("componentVersion");
        var componentVersion = reader.ReadString();
        reader.ExpectProperty("assemblyName");
        var assemblyName = reader.ReadString();
        reader.ExpectProperty("typeName");
        var typeName = reader.ReadString();
        reader.Expect(JsonTokenType.EndObject);
        reader.ExpectProperty("artifactFileName");
        var artifactFileName = reader.ReadString();
        reader.Expect(JsonTokenType.EndObject);
        reader.Expect(JsonTokenType.EndArray);

        return new RawComponent(
            componentKey,
            componentVersion,
            assemblyName,
            typeName,
            artifactFileName);
    }

    private static ParsedCanonicalManifest CreateProjection(
        CatalogAuthorityKind authorityKind,
        string sourceCommit,
        string protocolVersion,
        int catalogVersion,
        RawSlice slice,
        RawCacheBudget cacheBudget,
        RawActivationProof activationProof,
        RawArtifact artifact,
        RawComponent component)
    {
        try
        {
            RequirePositiveCacheBudget(cacheBudget);

            var componentIdentity = ComponentTypeIdentity.Create(
                component.ComponentKey,
                component.ComponentVersion,
                component.AssemblyName,
                component.TypeName);
            if (!string.Equals(
                    activationProof.ComponentKey,
                    componentIdentity.ComponentKey,
                    StringComparison.Ordinal) ||
                !string.Equals(
                    activationProof.ComponentVersion,
                    componentIdentity.ComponentVersion,
                    StringComparison.Ordinal))
            {
                throw new FormatException(
                    "The activation-proof component is not declared.");
            }

            var artifactBinding = ArtifactFileBinding.Create(
                artifact.FileName,
                artifact.ByteLength,
                ExactSha256Digest.Parse(artifact.ArtifactDigest));
            if (!string.Equals(
                    component.ArtifactFileName,
                    artifactBinding.FileName,
                    StringComparison.Ordinal))
            {
                throw new FormatException(
                    "The component does not map to the declared artifact.");
            }

            var componentBinding = ComponentArtifactBinding.Create(
                componentIdentity,
                component.ArtifactFileName);
            var typedCacheBudget = SessionCacheBudget.Create(
                cacheBudget.MaxDecodeEntries,
                cacheBudget.MaxDecodeCanonicalBytes,
                cacheBudget.MaxIndexEntries,
                cacheBudget.MaxIndexNodes,
                cacheBudget.MaxConcurrentDecodeAttempts,
                cacheBudget.MaxConcurrentIndexAttempts,
                CacheRetentionPolicy.Parse(cacheBudget.RetentionPolicy));
            var schemaRegistry = ReleaseSchemaRegistry.Create(
                Array.Empty<PayloadSchemaDeclaration>(),
                Array.Empty<SemanticModelParserDeclaration>(),
                Array.Empty<ContextIndexDeclaration>(),
                Array.Empty<AcquisitionDemandProjectorDeclaration>(),
                Array.Empty<AdmissionProofContractDeclaration>(),
                typedCacheBudget);
            var typedCatalogVersion = CatalogVersion.Create(catalogVersion);
            var typedSlice = CatalogSliceDeclaration.Create(
                slice.SliceKey,
                slice.SliceVersion,
                protocolVersion,
                typedCatalogVersion,
                Array.Empty<RuleDeclaration>());
            var typedActivationProof =
                ActivationProofContractDeclaration.Create(
                    activationProof.ContractKey,
                    activationProof.ContractVersion,
                    componentIdentity);

            return new ParsedCanonicalManifest(
                authorityKind,
                sourceCommit,
                schemaRegistry,
                typedActivationProof,
                Array.AsReadOnly([artifactBinding]),
                Array.AsReadOnly([componentBinding]),
                typedSlice);
        }
        catch (ArgumentException exception)
        {
            throw new FormatException(
                "A policy manifest value is not canonical.",
                exception);
        }
    }

    private static void RequirePositiveCacheBudget(RawCacheBudget budget)
    {
        if (budget.MaxDecodeEntries <= 0 ||
            budget.MaxDecodeCanonicalBytes <= 0 ||
            budget.MaxIndexEntries <= 0 ||
            budget.MaxIndexNodes <= 0 ||
            budget.MaxConcurrentDecodeAttempts <= 0 ||
            budget.MaxConcurrentIndexAttempts <= 0)
        {
            throw new FormatException(
                "The minimal qualification cache budget must be positive.");
        }
    }

    private static void ValidateEnvelope(ReadOnlySpan<byte> bytes)
    {
        if (bytes[^1] != (byte)'\n')
        {
            throw new FormatException(
                "The policy manifest must end with exactly one LF.");
        }

        if (bytes.Length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF)
        {
            throw new FormatException(
                "The policy manifest must not contain a UTF-8 BOM.");
        }
    }

    private static void ValidateSourceCommit(string sourceCommit)
    {
        if (sourceCommit.Length != 40 ||
            sourceCommit.Any(character =>
                character is not (>= '0' and <= '9') and
                not (>= 'a' and <= 'f')))
        {
            throw new FormatException(
                "The source commit must be exact lowercase 40-hex.");
        }
    }

    private ref struct BoundedJsonReader
    {
        private Utf8JsonReader _reader;
        private readonly ReadOnlySpan<byte> _input;
        private readonly int _inputLength;
        private int _tokenCount;

        internal BoundedJsonReader(ReadOnlySpan<byte> bytes)
        {
            _input = bytes;
            _reader = new Utf8JsonReader(
                bytes,
                new JsonReaderOptions
                {
                    AllowTrailingCommas = false,
                    CommentHandling = JsonCommentHandling.Disallow,
                    MaxDepth = MaximumDepth,
                });
            _inputLength = bytes.Length;
            _tokenCount = 0;
        }

        internal void Expect(JsonTokenType expected)
        {
            if (!Read() || _reader.TokenType != expected)
            {
                throw new FormatException(
                    $"Expected JSON token '{expected}'.");
            }
        }

        internal void ExpectProperty(string expected)
        {
            Expect(JsonTokenType.PropertyName);
            if (!_reader.ValueTextEquals(expected))
            {
                throw new FormatException(
                    $"Expected policy manifest property '{expected}'.");
            }
        }

        internal void ExpectEmptyArray()
        {
            Expect(JsonTokenType.StartArray);
            Expect(JsonTokenType.EndArray);
        }

        internal string ReadString()
        {
            Expect(JsonTokenType.String);

            string value;
            try
            {
                value = _reader.GetString()!;
            }
            catch (InvalidOperationException exception)
            {
                throw new FormatException(
                    "The policy manifest string is not valid Unicode.",
                    exception);
            }

            byte[] canonicalToken;
            try
            {
                canonicalToken =
                    CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(value);
            }
            catch (ArgumentException exception)
            {
                throw new FormatException(
                    "The policy manifest string is not valid Unicode.",
                    exception);
            }

            try
            {
                var tokenStart = checked((int)_reader.TokenStartIndex);
                var tokenLength = checked((int)(
                    _reader.BytesConsumed - _reader.TokenStartIndex));
                if (!_input
                    .Slice(tokenStart, tokenLength)
                    .SequenceEqual(canonicalToken))
                {
                    throw new FormatException(
                        "The policy manifest string is not canonical.");
                }
            }
            finally
            {
                CryptographicOperations.ZeroMemory(canonicalToken);
            }

            return value;
        }

        internal int ReadInt32()
        {
            Expect(JsonTokenType.Number);
            if (!_reader.TryGetInt32(out var value))
            {
                throw new FormatException(
                    "The policy manifest integer is outside Int32.");
            }

            return value;
        }

        internal long ReadInt64()
        {
            Expect(JsonTokenType.Number);
            if (!_reader.TryGetInt64(out var value))
            {
                throw new FormatException(
                    "The policy manifest integer is outside Int64.");
            }

            return value;
        }

        internal void ExpectEndOfDocument()
        {
            if (Read() || _reader.BytesConsumed != _inputLength)
            {
                throw new FormatException(
                    "The policy manifest contains trailing JSON content.");
            }
        }

        private bool Read()
        {
            if (!_reader.Read())
            {
                return false;
            }

            _tokenCount++;
            if (_tokenCount > MaximumTokenCount)
            {
                throw new FormatException(
                    "The policy manifest exceeds the JSON token ceiling.");
            }

            return true;
        }
    }

    private sealed record RawSlice(string SliceKey, string SliceVersion);

    private sealed record RawCacheBudget(
        int MaxDecodeEntries,
        long MaxDecodeCanonicalBytes,
        int MaxIndexEntries,
        long MaxIndexNodes,
        int MaxConcurrentDecodeAttempts,
        int MaxConcurrentIndexAttempts,
        string RetentionPolicy);

    private sealed record RawActivationProof(
        string ContractKey,
        string ContractVersion,
        string ComponentKey,
        string ComponentVersion);

    private sealed record RawArtifact(
        string FileName,
        long ByteLength,
        string ArtifactDigest);

    private sealed record RawComponent(
        string ComponentKey,
        string ComponentVersion,
        string AssemblyName,
        string TypeName,
        string ArtifactFileName);
}

internal sealed record ParsedCanonicalManifest(
    CatalogAuthorityKind AuthorityKind,
    string SourceCommit,
    ReleaseSchemaRegistry SchemaRegistry,
    ActivationProofContractDeclaration ActivationProofContract,
    IReadOnlyList<ArtifactFileBinding> ArtifactFiles,
    IReadOnlyList<ComponentArtifactBinding> Components,
    CatalogSliceDeclaration Slice);
