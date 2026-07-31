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
        var artifacts = ReadArtifacts(ref reader);

        reader.ExpectProperty("components");
        var components = ReadComponents(ref reader);

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
            artifacts,
            components);
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

    private static IReadOnlyList<RawArtifact> ReadArtifacts(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var artifacts = new List<RawArtifact>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest artifactFiles array must contain objects.");
            }

            reader.ExpectProperty("fileName");
            var fileName = reader.ReadString();
            reader.ExpectProperty("byteLength");
            var byteLength = reader.ReadInt64();
            reader.ExpectProperty("artifactDigest");
            var artifactDigest = reader.ReadString();
            reader.Expect(JsonTokenType.EndObject);
            artifacts.Add(
                new RawArtifact(fileName, byteLength, artifactDigest));
        }

        if (artifacts.Count == 0)
        {
            throw new FormatException(
                "The manifest artifactFiles array cannot be empty.");
        }

        return artifacts;
    }

    private static IReadOnlyList<RawComponent> ReadComponents(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var components = new List<RawComponent>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest components array must contain objects.");
            }

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
            components.Add(
                new RawComponent(
                    componentKey,
                    componentVersion,
                    assemblyName,
                    typeName,
                    artifactFileName));
        }

        if (components.Count == 0)
        {
            throw new FormatException(
                "The manifest components array cannot be empty.");
        }

        return components;
    }

    private static ParsedCanonicalManifest CreateProjection(
        CatalogAuthorityKind authorityKind,
        string sourceCommit,
        string protocolVersion,
        int catalogVersion,
        RawSlice slice,
        RawCacheBudget cacheBudget,
        RawActivationProof activationProof,
        IReadOnlyList<RawArtifact> artifacts,
        IReadOnlyList<RawComponent> rawComponents)
    {
        try
        {
            RequirePositiveCacheBudget(cacheBudget);

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

            var artifactBindings = new List<ArtifactFileBinding>();
            var artifactFileNames = new HashSet<string>(StringComparer.Ordinal);
            foreach (var artifact in artifacts)
            {
                var binding = ArtifactFileBinding.Create(
                    artifact.FileName,
                    artifact.ByteLength,
                    ExactSha256Digest.Parse(artifact.ArtifactDigest));
                if (!artifactFileNames.Add(binding.FileName))
                {
                    throw new FormatException(
                        "The manifest artifactFiles array contains duplicate file names.");
                }

                artifactBindings.Add(binding);
            }

            var componentBindings = new List<ComponentArtifactBinding>();
            var componentKeys = new HashSet<string>(StringComparer.Ordinal);
            var usedArtifacts = new HashSet<string>(StringComparer.Ordinal);
            ComponentTypeIdentity? activationProofComponent = null;

            foreach (var component in rawComponents)
            {
                var componentIdentity = ComponentTypeIdentity.Create(
                    component.ComponentKey,
                    component.ComponentVersion,
                    component.AssemblyName,
                    component.TypeName);
                var componentKey = component.ComponentKey + "|" + component.ComponentVersion;
                if (!componentKeys.Add(componentKey))
                {
                    throw new FormatException(
                        "The manifest components array contains duplicate component identities.");
                }

                if (!artifactFileNames.Contains(component.ArtifactFileName))
                {
                    throw new FormatException(
                        "The manifest component mapping references an undeclared artifact.");
                }

                var componentBinding = ComponentArtifactBinding.Create(
                    componentIdentity,
                    component.ArtifactFileName);
                componentBindings.Add(componentBinding);
                usedArtifacts.Add(component.ArtifactFileName);

                if (IsActivationProof(componentIdentity, activationProof))
                {
                    activationProofComponent = componentIdentity;
                }
            }

            if (activationProofComponent is null)
            {
                throw new FormatException(
                    "The activation-proof component is not declared.");
            }

            foreach (var component in componentBindings.Select(item => item.Component))
            {
                if (!IsActivationProof(component, activationProof) &&
                    !IsRuntimeAnchor(component))
                {
                    throw new FormatException(
                        "The manifest component graph is not fully closed.");
                }
            }

            if (!artifactFileNames.SetEquals(usedArtifacts))
            {
                throw new FormatException(
                    "The manifest artifactFiles array must be fully bound.");
            }

            var typedActivationProof =
                ActivationProofContractDeclaration.Create(
                    activationProof.ContractKey,
                    activationProof.ContractVersion,
                    activationProofComponent);

            return new ParsedCanonicalManifest(
                authorityKind,
                sourceCommit,
                schemaRegistry,
                typedActivationProof,
                artifactBindings.AsReadOnly(),
                componentBindings.AsReadOnly(),
                typedSlice);
        }
        catch (ArgumentException exception)
        {
            throw new FormatException(
                "A policy manifest value is not canonical.",
                exception);
        }
    }

    private static bool IsActivationProof(
        ComponentTypeIdentity component,
        RawActivationProof activationProof) =>
        string.Equals(component.ComponentKey, activationProof.ComponentKey, StringComparison.Ordinal) &&
        string.Equals(component.ComponentVersion, activationProof.ComponentVersion, StringComparison.Ordinal);

    private static bool IsRuntimeAnchor(ComponentTypeIdentity component) =>
        component.ComponentVersion is "1" &&
        component switch
        {
            _ when component.ComponentKey == "protocol.runtime.domain" &&
                component.AssemblyName == "MeAndAI.Protocol.Domain" &&
                component.TypeName == "MeAndAI.Protocol.Domain.RuleId" => true,
            _ when component.ComponentKey == "protocol.runtime.conformance-abstractions" &&
                component.AssemblyName == "MeAndAI.Protocol.Conformance.Abstractions" &&
                component.TypeName == "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport" => true,
            _ when component.ComponentKey == "protocol.runtime.conformance" &&
                component.AssemblyName == "MeAndAI.Protocol.Conformance" &&
                component.TypeName == "MeAndAI.Protocol.Conformance.CatalogIntegrityException" => true,
            _ when component.ComponentKey == "protocol.runtime.markdig" &&
                component.AssemblyName == "Markdig" &&
                component.TypeName == "Markdig.Markdown" => true,
            _ => false,
        };

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

            var rawValue = ReadCanonicalIntegerToken();
            if (rawValue[0] == (byte)'-')
            {
                throw new FormatException(
                    "The policy manifest integer is outside Int32.");
            }

            long value;
            try
            {
                value = ParseCanonicalNonNegativeInteger(rawValue);
            }
            catch (Exception exception)
            {
                if (exception is not FormatException and not OverflowException)
                {
                    throw;
                }

                throw new FormatException(
                    "The policy manifest integer is outside Int32.",
                    exception);
            }

            if (value is < 0 or > int.MaxValue)
            {
                throw new FormatException(
                    "The policy manifest integer is outside Int32.");
            }

            return (int)value;
        }

        internal long ReadInt64()
        {
            Expect(JsonTokenType.Number);

            var rawValue = ReadCanonicalIntegerToken();
            if (rawValue[0] == (byte)'-')
            {
                throw new FormatException(
                    "The policy manifest integer is outside Int64.");
            }

            try
            {
                return ParseCanonicalNonNegativeInteger(rawValue);
            }
            catch (Exception exception)
            {
                if (exception is not FormatException and not OverflowException)
                {
                    throw;
                }

                throw new FormatException(
                    "The policy manifest integer is outside Int64.",
                    exception);
            }
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

        private ReadOnlySpan<byte> ReadCanonicalIntegerToken()
        {
            var tokenStart = checked((int)_reader.TokenStartIndex);
            var tokenLength = checked((int)(_reader.BytesConsumed - _reader.TokenStartIndex));
            return _input.Slice(tokenStart, tokenLength);
        }

        private static long ParseCanonicalNonNegativeInteger(
            ReadOnlySpan<byte> token)
        {
            if (token.Length == 0)
            {
                throw new FormatException(
                    "The policy manifest integer token is empty.");
            }

            if (token.Length > 1 && token[0] == (byte)'0')
            {
                throw new FormatException(
                    "The policy manifest integer has leading zero.");
            }

            long value = 0;
            foreach (var current in token)
            {
                if (current < (byte)'0' || current > (byte)'9')
                {
                    throw new FormatException(
                        "The policy manifest integer is not canonical.");
                }

                var digit = current - (byte)'0';
                checked
                {
                    value = (value * 10) + digit;
                }
            }

            return value;
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
