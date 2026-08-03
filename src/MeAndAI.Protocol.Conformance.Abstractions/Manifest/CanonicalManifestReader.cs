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
        if (!authorityKind.Equals(CatalogAuthorityKind.QualificationSlice) &&
            !authorityKind.Equals(CatalogAuthorityKind.CompleteProtocolSnapshot))
        {
            throw new FormatException(
                "This parser increment requires a supported catalog authority.");
        }

        reader.ExpectProperty("sourceCommit");
        var sourceCommit = reader.ReadString();
        ValidateSourceCommit(sourceCommit);

        reader.ExpectProperty("protocolVersion");
        var protocolVersion = reader.ReadString();

        reader.ExpectProperty("catalogVersion");
        var catalogVersion = reader.ReadInt32();

        RawSlice? slice = null;
        RawCompleteCatalog? completeCatalog = null;
        if (authorityKind.Equals(CatalogAuthorityKind.QualificationSlice))
        {
            reader.ExpectProperty("slice");
            slice = ReadSlice(ref reader);
        }
        else
        {
            reader.ExpectProperty("completeCatalog");
            completeCatalog = ReadCompleteCatalog(ref reader);
        }

        reader.ExpectProperty("schemaRegistry");
        var schemaRegistry = ReadSchemaRegistry(ref reader);

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
            completeCatalog,
            schemaRegistry,
            activationProof,
            artifacts,
            components);
    }

    private static RawCompleteCatalog ReadCompleteCatalog(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("predecessor");
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("kind");
        var predecessorKind = reader.ReadString();
        if (!string.Equals(predecessorKind, CatalogPredecessorKind.Genesis.Value, StringComparison.Ordinal))
            throw new FormatException("This parser increment supports only a genesis predecessor.");
        reader.Expect(JsonTokenType.EndObject);
        reader.ExpectProperty("completeInventoryDigest");
        var digest = reader.ReadString();
        reader.ExpectProperty("baselineProfileName");
        var baseline = reader.ReadString();
        reader.ExpectProperty("rules");
        var rules = ReadRules(ref reader);
        reader.ExpectProperty("transitions");
        var transitions = ReadTransitions(ref reader);
        reader.ExpectProperty("namedProfiles");
        var profiles = ReadNamedProfiles(ref reader);
        reader.Expect(JsonTokenType.EndObject);
        return new RawCompleteCatalog(digest, baseline, rules, transitions, profiles);
    }

    private static IReadOnlyList<RawTransition> ReadTransitions(ref BoundedJsonReader reader)
    {
        var items = new List<RawTransition>();
        reader.Expect(JsonTokenType.StartArray);
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            reader.ExpectProperty("ruleId"); var ruleId = reader.ReadString();
            reader.ExpectProperty("kind"); var kind = reader.ReadString();
            if (!string.Equals(kind, RuleTransitionKind.Added.Value, StringComparison.Ordinal))
                throw new FormatException("This parser increment supports only Added transitions.");
            reader.ExpectProperty("currentRevision"); var revision = reader.ReadInt32();
            reader.ExpectProperty("reviewedAuthority"); var authority = reader.ReadString();
            reader.Expect(JsonTokenType.EndObject);
            items.Add(new RawTransition(ruleId, revision, authority));
        }
        return items;
    }

    private static IReadOnlyList<RawNamedProfile> ReadNamedProfiles(ref BoundedJsonReader reader)
    {
        var items = new List<RawNamedProfile>();
        reader.Expect(JsonTokenType.StartArray);
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            reader.ExpectProperty("name"); var name = reader.ReadString();
            reader.ExpectProperty("axes");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("subjectRole"); var role = reader.ReadString();
            reader.ExpectProperty("operation"); var operation = reader.ReadString();
            reader.ExpectProperty("snapshotKind"); var snapshot = reader.ReadString();
            reader.ExpectProperty("surfaces"); var surfaces = ReadStringArray(ref reader);
            reader.ExpectProperty("enforcementPhase"); var phase = reader.ReadString();
            reader.Expect(JsonTokenType.EndObject);
            reader.ExpectProperty("ruleIds"); var ruleIds = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            items.Add(new RawNamedProfile(name, role, operation, snapshot, surfaces, phase, ruleIds));
        }
        return items;
    }

    private static RawSlice ReadSlice(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("sliceKey");
        var sliceKey = reader.ReadString();
        reader.ExpectProperty("sliceVersion");
        var sliceVersion = reader.ReadString();
        reader.ExpectProperty("rules");
        var rules = ReadRules(ref reader);
        reader.Expect(JsonTokenType.EndObject);

        return new RawSlice(sliceKey, sliceVersion, rules);
    }

    private static RawSchemaRegistry ReadSchemaRegistry(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("payloadSchemas");
        var payloadSchemas = ReadPayloadSchemas(ref reader);
        reader.ExpectProperty("parsers");
        var parsers = ReadParsers(ref reader);
        reader.ExpectProperty("indexes");
        var indexes = ReadIndexes(ref reader);
        reader.ExpectProperty("demandProjectors");
        var demandProjectors = ReadDemandProjectors(ref reader);
        reader.ExpectProperty("admissionProofContracts");
        var admissionProofContracts = ReadAdmissionProofContracts(ref reader);
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

        return new RawSchemaRegistry(
            payloadSchemas,
            parsers,
            indexes,
            demandProjectors,
            admissionProofContracts,
            new RawCacheBudget(
                maxDecodeEntries,
                maxDecodeCanonicalBytes,
                maxIndexEntries,
                maxIndexNodes,
                maxConcurrentDecodeAttempts,
                maxConcurrentIndexAttempts,
                retentionPolicy));
    }

    private static IReadOnlyList<RawDemandProjector> ReadDemandProjectors(ref BoundedJsonReader reader)
    {
        try { reader.Expect(JsonTokenType.StartArray); }
        catch (FormatException exception) { throw new FormatException("protocol.manifest.projector-array-envelope", exception); }
        var projectors = new List<RawDemandProjector>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new FormatException("protocol.manifest.projector-array-envelope");
            try
            {
                reader.ExpectProperty("projectorKey"); var key = reader.ReadString();
                reader.ExpectProperty("projectorVersion"); var version = reader.ReadString();
                reader.ExpectProperty("projector"); var projector = ReadComponentReference(ref reader);
                reader.ExpectProperty("inputCapability"); reader.Expect(JsonTokenType.StartObject);
                reader.ExpectProperty("capabilityKey"); var capabilityKey = reader.ReadString();
                reader.ExpectProperty("capabilityVersion"); var capabilityVersion = reader.ReadString();
                reader.ExpectProperty("interfaceType"); var interfaceType = ReadComponentReference(ref reader);
                reader.Expect(JsonTokenType.EndObject);
                reader.ExpectProperty("inputSlotKeys"); var inputs = ReadNullableStringArray(ref reader);
                reader.ExpectProperty("outputSlotKey"); var output = reader.ReadString();
                reader.ExpectProperty("demandSchemaKey"); var schemaKey = reader.ReadString();
                reader.ExpectProperty("demandSchemaVersion"); var schemaVersion = reader.ReadString();
                reader.ExpectProperty("budget"); reader.Expect(JsonTokenType.StartObject);
                reader.ExpectProperty("maxBytes"); var maxBytes = reader.ReadInt64();
                reader.ExpectProperty("maxDepth"); var maxDepth = reader.ReadInt32();
                reader.ExpectProperty("maxNodes"); var maxNodes = reader.ReadInt64();
                reader.ExpectProperty("maxComplexity"); var maxComplexity = reader.ReadInt64();
                reader.Expect(JsonTokenType.EndObject);
                reader.ExpectProperty("failureCodes"); var failures = ReadNullableStringArray(ref reader);
                reader.Expect(JsonTokenType.EndObject);
                var row = new RawDemandProjector(key, version, projector,
                    new RawCapabilityContract(capabilityKey, capabilityVersion, interfaceType), inputs,
                    output, schemaKey, schemaVersion, maxBytes, maxDepth, maxNodes, maxComplexity, failures);
                if (projectors.Any(item => item.HasSameValues(row)))
                    throw new FormatException("protocol.manifest.projector-array-envelope");
                projectors.Add(row);
            }
            catch (FormatException exception) when (exception.Message != "protocol.manifest.projector-array-envelope")
            { throw new FormatException("protocol.manifest.projector-row-wire", exception); }
        }
        return projectors;
    }

    private static IReadOnlyList<RawAdmissionProofContract>
        ReadAdmissionProofContracts(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var contracts = new List<RawAdmissionProofContract>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest admissionProofContracts array must contain objects.");
            }

            reader.ExpectProperty("contractKey");
            var contractKey = reader.ReadString();
            reader.ExpectProperty("contractVersion");
            var contractVersion = reader.ReadString();
            reader.ExpectProperty("kind");
            var kind = reader.ReadString();
            reader.ExpectProperty("proofComponent");
            var proofComponent = ReadComponentReference(ref reader);
            reader.ExpectProperty("surfaces");
            var surfaces = ReadStringArray(ref reader);
            reader.ExpectProperty("materialRoles");
            var materialRoles = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);

            contracts.Add(new RawAdmissionProofContract(
                contractKey,
                contractVersion,
                kind,
                proofComponent,
                surfaces,
                materialRoles));
        }

        return contracts;
    }

    private static IReadOnlyList<RawPayloadSchema> ReadPayloadSchemas(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var schemas = new List<RawPayloadSchema>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest payloadSchemas array must contain objects.");
            }

            reader.ExpectProperty("schemaKey");
            var schemaKey = reader.ReadString();
            reader.ExpectProperty("schemaVersion");
            var schemaVersion = reader.ReadString();
            reader.ExpectProperty("codec");
            var codec = ReadComponentReference(ref reader);

            reader.ExpectProperty("outputModel");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("modelKey");
            var modelKey = reader.ReadString();
            reader.ExpectProperty("modelVersion");
            var modelVersion = reader.ReadString();
            reader.ExpectProperty("implementationType");
            var implementationType = ReadComponentReference(ref reader);
            reader.Expect(JsonTokenType.EndObject);

            reader.ExpectProperty("maxBindingsPerInstruction");
            var maxBindings = reader.ReadInt32();
            reader.ExpectProperty("maxRetainedCanonicalBytesPerInstruction");
            var maxRetainedBytes = reader.ReadInt64();

            reader.ExpectProperty("budget");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("maxBytes");
            var maxBytes = reader.ReadInt64();
            reader.ExpectProperty("maxDepth");
            var maxDepth = reader.ReadInt32();
            reader.ExpectProperty("maxNodes");
            var maxNodes = reader.ReadInt64();
            reader.ExpectProperty("maxComplexity");
            var maxComplexity = reader.ReadInt64();
            reader.Expect(JsonTokenType.EndObject);

            reader.ExpectProperty("codecFailureCodes");
            var codecFailureCodes = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            schemas.Add(new RawPayloadSchema(
                schemaKey,
                schemaVersion,
                codec,
                modelKey,
                modelVersion,
                implementationType,
                maxBindings,
                maxRetainedBytes,
                maxBytes,
                maxDepth,
                maxNodes,
                maxComplexity,
                codecFailureCodes));
        }

        return schemas;
    }

    private static IReadOnlyList<RawSemanticParser> ReadParsers(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var parsers = new List<RawSemanticParser>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException("The manifest parsers array must contain objects.");
            }
            reader.ExpectProperty("parserKey"); var parserKey = reader.ReadString();
            reader.ExpectProperty("parserVersion"); var parserVersion = reader.ReadString();
            reader.ExpectProperty("parser"); var parser = ReadComponentReference(ref reader);
            reader.ExpectProperty("inputs"); var input = ReadSingleModelInput(ref reader);
            reader.ExpectProperty("outputModel");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("modelKey"); var modelKey = reader.ReadString();
            reader.ExpectProperty("modelVersion"); var modelVersion = reader.ReadString();
            reader.ExpectProperty("implementationType"); var implementationType = ReadComponentReference(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            reader.ExpectProperty("budget");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("maxBytes"); var maxBytes = reader.ReadInt64();
            reader.ExpectProperty("maxDepth"); var maxDepth = reader.ReadInt32();
            reader.ExpectProperty("maxNodes"); var maxNodes = reader.ReadInt64();
            reader.ExpectProperty("maxComplexity"); var maxComplexity = reader.ReadInt64();
            reader.Expect(JsonTokenType.EndObject);
            reader.ExpectProperty("failureCodes"); var failureCodes = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            parsers.Add(new RawSemanticParser(parserKey, parserVersion, parser, input,
                modelKey, modelVersion, implementationType,
                maxBytes, maxDepth, maxNodes, maxComplexity, failureCodes));
        }
        return parsers;
    }

    private static IReadOnlyList<RawContextIndex> ReadIndexes(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var indexes = new List<RawContextIndex>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException("The manifest indexes array must contain objects.");
            }

            reader.ExpectProperty("indexKey");
            var indexKey = reader.ReadString();
            reader.ExpectProperty("indexVersion");
            var indexVersion = reader.ReadString();
            reader.ExpectProperty("indexer");
            var indexer = ReadComponentReference(ref reader);
            reader.ExpectProperty("invocationScope");
            var invocationScope = reader.ReadString();
            reader.ExpectProperty("inputs");
            var inputs = ReadIndexInputs(ref reader);
            reader.ExpectProperty("outputCapability");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("capabilityKey");
            var capabilityKey = reader.ReadString();
            reader.ExpectProperty("capabilityVersion");
            var capabilityVersion = reader.ReadString();
            reader.ExpectProperty("interfaceType");
            var interfaceType = ReadComponentReference(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            reader.ExpectProperty("budget");
            reader.Expect(JsonTokenType.StartObject);
            reader.ExpectProperty("maxBytes");
            var maxBytes = reader.ReadInt64();
            reader.ExpectProperty("maxDepth");
            var maxDepth = reader.ReadInt32();
            reader.ExpectProperty("maxNodes");
            var maxNodes = reader.ReadInt64();
            reader.ExpectProperty("maxComplexity");
            var maxComplexity = reader.ReadInt64();
            reader.Expect(JsonTokenType.EndObject);
            reader.ExpectProperty("failureCodes");
            var failureCodes = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            indexes.Add(new RawContextIndex(
                indexKey, indexVersion, indexer, invocationScope,
                inputs,
                new RawCapabilityContract(capabilityKey, capabilityVersion, interfaceType),
                maxBytes, maxDepth, maxNodes, maxComplexity, failureCodes));
        }

        return indexes;
    }

    private static RawModelInput ReadSingleModelInput(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("kind");
        if (reader.ReadString() != "model")
        {
            throw new FormatException("This parser increment requires a model component input.");
        }
        reader.ExpectProperty("model");
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("modelKey"); var modelKey = reader.ReadString();
        reader.ExpectProperty("modelVersion"); var modelVersion = reader.ReadString();
        reader.ExpectProperty("implementationType"); var implementationType = ReadComponentReference(ref reader);
        reader.Expect(JsonTokenType.EndObject);
        reader.ExpectProperty("minimumCount"); var minimumCount = reader.ReadInt32();
        int? maximumCount = null;
        if (!reader.Read())
        {
            throw new FormatException("The component input is incomplete.");
        }
        if (reader.TokenType == JsonTokenType.PropertyName)
        {
            reader.RequireProperty("maximumCount");
            maximumCount = reader.ReadInt32();
            reader.Expect(JsonTokenType.EndObject);
        }
        else if (reader.TokenType != JsonTokenType.EndObject)
        {
            throw new FormatException("Expected component input maximumCount or end of object.");
        }
        reader.Expect(JsonTokenType.EndArray);
        return new RawModelInput(modelKey, modelVersion, implementationType, minimumCount, maximumCount);
    }

    private static IReadOnlyList<RawIndexInput> ReadIndexInputs(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var inputs = new List<RawIndexInput>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest index inputs array must contain objects.");
            }

            reader.ExpectProperty("kind");
            var kind = reader.ReadString();
            RawModelContract? model = null;
            RawCapabilityContract? capability = null;
            if (kind == "model")
            {
                reader.ExpectProperty("model");
                reader.Expect(JsonTokenType.StartObject);
                reader.ExpectProperty("modelKey");
                var modelKey = reader.ReadString();
                reader.ExpectProperty("modelVersion");
                var modelVersion = reader.ReadString();
                reader.ExpectProperty("implementationType");
                var implementationType = ReadComponentReference(ref reader);
                reader.Expect(JsonTokenType.EndObject);
                model = new RawModelContract(
                    modelKey, modelVersion, implementationType);
            }
            else if (kind == "capability")
            {
                reader.ExpectProperty("capability");
                reader.Expect(JsonTokenType.StartObject);
                reader.ExpectProperty("capabilityKey");
                var capabilityKey = reader.ReadString();
                reader.ExpectProperty("capabilityVersion");
                var capabilityVersion = reader.ReadString();
                reader.ExpectProperty("interfaceType");
                var interfaceType = ReadComponentReference(ref reader);
                reader.Expect(JsonTokenType.EndObject);
                capability = new RawCapabilityContract(
                    capabilityKey, capabilityVersion, interfaceType);
            }
            else
            {
                throw new FormatException(
                    "The manifest index input kind is not supported.");
            }

            reader.ExpectProperty("minimumCount");
            var minimumCount = reader.ReadInt32();
            int? maximumCount = null;
            if (!reader.Read())
            {
                throw new FormatException("The index input is incomplete.");
            }
            if (reader.TokenType == JsonTokenType.PropertyName)
            {
                reader.RequireProperty("maximumCount");
                maximumCount = reader.ReadInt32();
                reader.Expect(JsonTokenType.EndObject);
            }
            else if (reader.TokenType != JsonTokenType.EndObject)
            {
                throw new FormatException(
                    "Expected index input maximumCount or end of object.");
            }

            inputs.Add(new RawIndexInput(
                model, capability, minimumCount, maximumCount));
        }

        return inputs;
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

    private static IReadOnlyList<RawRuleDeclaration> ReadRules(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var rules = new List<RawRuleDeclaration>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest rules array must contain objects.");
            }

            reader.ExpectProperty("ruleId");
            var ruleId = reader.ReadString();
            reader.ExpectProperty("ruleRevision");
            var ruleRevision = reader.ReadInt32();
            reader.ExpectProperty("catalogVersion");
            var catalogVersion = reader.ReadInt32();
            reader.ExpectProperty("normativeDigest");
            var normativeDigest = reader.ReadString();
            reader.ExpectProperty("normativeFragments");
            var normativeFragments = ReadNormativeFragments(ref reader);
            reader.ExpectProperty("qualificationScenarios");
            var qualificationScenarios = ReadStringArray(ref reader);
            reader.ExpectProperty("evaluator");
            var evaluator = ReadComponentReference(ref reader);
            reader.ExpectProperty("applicabilitySlots");
            var applicabilitySlots = ReadEvidenceSlots(ref reader);
            reader.ExpectProperty("evaluationSlots");
            var evaluationSlots = ReadEvidenceSlots(ref reader);
            reader.ExpectProperty("expectedSelectors");
            var expectedSelectors = ReadExpectedSelectors(ref reader);
            reader.ExpectProperty("subjectRoles");
            var subjectRoles = ReadStringArray(ref reader);
            reader.ExpectProperty("surfaces");
            var surfaces = ReadStringArray(ref reader);
            reader.ExpectProperty("snapshotKinds");
            var snapshotKinds = ReadStringArray(ref reader);
            reader.ExpectProperty("operations");
            var operations = ReadStringArray(ref reader);
            reader.ExpectProperty("findings");
            var findings = ReadFindings(ref reader);
            reader.ExpectProperty("evaluationFailureCodes");
            var evaluationFailureCodes = ReadStringArray(ref reader);
            reader.ExpectProperty("introducedIn");
            var introducedIn = reader.ReadString();
            string? deprecatedIn = null;
            string? retiredIn = null;

            if (!reader.Read())
            {
                throw new FormatException(
                    "The rule declaration ended before compatibilityAliases.");
            }

            if (reader.IsPropertyName("deprecatedIn"))
            {
                deprecatedIn = reader.ReadString();
                if (!reader.Read())
                {
                    throw new FormatException(
                        "The rule declaration ended before compatibilityAliases.");
                }
            }

            if (reader.IsPropertyName("retiredIn"))
            {
                retiredIn = reader.ReadString();
                if (!reader.Read())
                {
                    throw new FormatException(
                        "The rule declaration ended before compatibilityAliases.");
                }
            }

            reader.RequireProperty("compatibilityAliases");
            var compatibilityAliases = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);

            rules.Add(
                new RawRuleDeclaration(
                    ruleId,
                    ruleRevision,
                    catalogVersion,
                    normativeDigest,
                    normativeFragments,
                    qualificationScenarios,
                    evaluator,
                    applicabilitySlots,
                    evaluationSlots,
                    expectedSelectors,
                    subjectRoles,
                    surfaces,
                    snapshotKinds,
                    operations,
                    findings,
                    evaluationFailureCodes,
                    introducedIn,
                    deprecatedIn,
                    retiredIn,
                    compatibilityAliases));
        }

        return rules;
    }

    private static IReadOnlyList<RawNormativeFragment> ReadNormativeFragments(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var fragments = new List<RawNormativeFragment>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest normative fragment array must contain objects.");
            }

            reader.ExpectProperty("path");
            var path = reader.ReadString();
            reader.ExpectProperty("containingBlob");
            var containingBlob = reader.ReadString();
            reader.ExpectProperty("anchor");
            var anchor = reader.ReadString();
            reader.ExpectProperty("startLine");
            var startLine = reader.ReadInt32();
            reader.ExpectProperty("endLine");
            var endLine = reader.ReadInt32();
            reader.ExpectProperty("canonicalizationSchema");
            var canonicalizationSchema = reader.ReadString();
            reader.ExpectProperty("canonicalByteLength");
            var canonicalByteLength = reader.ReadInt64();
            reader.ExpectProperty("fragmentDigest");
            var fragmentDigest = reader.ReadString();
            reader.Expect(JsonTokenType.EndObject);
            fragments.Add(
                new RawNormativeFragment(
                    path,
                    containingBlob,
                    anchor,
                    startLine,
                    endLine,
                    canonicalizationSchema,
                    canonicalByteLength,
                    fragmentDigest));
        }

        return fragments;
    }

    private static IReadOnlyList<string> ReadStringArray(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var values = new List<string>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            values.Add(reader.ReadCurrentString());
        }

        return values;
    }

    private static IReadOnlyList<string?> ReadNullableStringArray(ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var values = new List<string?>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
            values.Add(reader.TokenType == JsonTokenType.Null
                ? null
                : reader.ReadCurrentString());
        return values;
    }

    private static IReadOnlyList<RawEvidenceSlot> ReadEvidenceSlots(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var slots = new List<RawEvidenceSlot>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest slot array must contain objects.");
            }

            reader.ExpectProperty("slotKey");
            var slotKey = reader.ReadString();
            reader.ExpectProperty("requirement");
            var requirement = ReadEvidenceRequirement(ref reader);
            reader.ExpectProperty("profileSurfaces");
            var profileSurfaces = ReadStringArray(ref reader);
            reader.ExpectProperty("materialRole");
            var materialRole = reader.ReadString();
            reader.ExpectProperty("targetSelectorKey");
            var targetSelectorKey = reader.ReadString();
            reader.ExpectProperty("capabilities");
            var capabilities = ReadCapabilities(ref reader);
            reader.Expect(JsonTokenType.EndObject);

            slots.Add(
                new RawEvidenceSlot(
                    slotKey,
                    requirement,
                    profileSurfaces,
                    materialRole,
                    targetSelectorKey,
                    capabilities));
        }

        return slots;
    }

    private static RawEvidenceRequirement ReadEvidenceRequirement(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("key");
        var key = reader.ReadString();
        reader.ExpectProperty("surface");
        var surface = reader.ReadString();
        reader.ExpectProperty("kind");
        var kind = reader.ReadString();
        reader.ExpectProperty("completenessContract");
        var completenessContract = reader.ReadString();
        reader.ExpectProperty("payloadSchemaKey");
        var payloadSchemaKey = reader.ReadString();
        reader.ExpectProperty("payloadSchemaVersion");
        var payloadSchemaVersion = reader.ReadString();
        reader.ExpectProperty("acceptedConsistencyClasses");
        var acceptedConsistencyClasses = ReadStringArray(ref reader);
        reader.Expect(JsonTokenType.EndObject);

        return new RawEvidenceRequirement(
            key,
            surface,
            kind,
            completenessContract,
            payloadSchemaKey,
            payloadSchemaVersion,
            acceptedConsistencyClasses);
    }

    private static IReadOnlyList<RawCapabilityContract> ReadCapabilities(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var capabilities = new List<RawCapabilityContract>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest capability array must contain objects.");
            }

            reader.ExpectProperty("capabilityKey");
            var capabilityKey = reader.ReadString();
            reader.ExpectProperty("capabilityVersion");
            var capabilityVersion = reader.ReadString();
            reader.ExpectProperty("interfaceType");
            var interfaceType = ReadComponentReference(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            capabilities.Add(
                new RawCapabilityContract(
                    capabilityKey,
                    capabilityVersion,
                    interfaceType));
        }

        return capabilities;
    }

    private static IReadOnlyList<RawExpectedSelector> ReadExpectedSelectors(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var selectors = new List<RawExpectedSelector>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest expected selector array must contain objects.");
            }

            reader.ExpectProperty("selectorKey");
            var selectorKey = reader.ReadString();
            reader.ExpectProperty("slotKey");
            var slotKey = reader.ReadString();
            reader.ExpectProperty("selectorSchemaKey");
            var selectorSchemaKey = reader.ReadString();
            reader.ExpectProperty("resolver");
            var resolver = ReadComponentReference(ref reader);
            reader.ExpectProperty("allowedParentKinds");
            var allowedParentKinds = ReadStringArray(ref reader);
            reader.ExpectProperty("allowedFindingCodes");
            var allowedFindingCodes = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);

            selectors.Add(
                new RawExpectedSelector(
                    selectorKey,
                    slotKey,
                    selectorSchemaKey,
                    resolver,
                    allowedParentKinds,
                    allowedFindingCodes));
        }

        return selectors;
    }

    private static IReadOnlyList<RawFindingDeclaration> ReadFindings(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartArray);
        var findings = new List<RawFindingDeclaration>();
        while (reader.Read() && reader.TokenType != JsonTokenType.EndArray)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                throw new FormatException(
                    "The manifest finding array must contain objects.");
            }

            reader.ExpectProperty("code");
            var code = reader.ReadString();
            reader.ExpectProperty("severity");
            var severity = reader.ReadString();
            reader.ExpectProperty("remediation");
            var remediation = reader.ReadString();
            reader.ExpectProperty("allowedPrimaryReferenceKinds");
            var allowedPrimaryReferenceKinds = ReadStringArray(ref reader);
            reader.ExpectProperty("allowedRelatedReferenceKinds");
            var allowedRelatedReferenceKinds = ReadStringArray(ref reader);
            reader.Expect(JsonTokenType.EndObject);
            findings.Add(
                new RawFindingDeclaration(
                    code,
                    severity,
                    remediation,
                    allowedPrimaryReferenceKinds,
                    allowedRelatedReferenceKinds));
        }

        return findings;
    }

    private static RawComponentReference ReadComponentReference(
        ref BoundedJsonReader reader)
    {
        reader.Expect(JsonTokenType.StartObject);
        reader.ExpectProperty("componentKey");
        var componentKey = reader.ReadString();
        reader.ExpectProperty("componentVersion");
        var componentVersion = reader.ReadString();
        reader.Expect(JsonTokenType.EndObject);

        return new RawComponentReference(componentKey, componentVersion);
    }

    private static ParsedCanonicalManifest CreateProjection(
        CatalogAuthorityKind authorityKind,
        string sourceCommit,
        string protocolVersion,
        int catalogVersion,
        RawSlice? slice,
        RawCompleteCatalog? completeCatalog,
        RawSchemaRegistry rawSchemaRegistry,
        RawActivationProof activationProof,
        IReadOnlyList<RawArtifact> artifacts,
        IReadOnlyList<RawComponent> rawComponents)
    {
        try
        {
            var rawRules = slice?.Rules ?? completeCatalog?.Rules ??
                throw new FormatException("The manifest catalog union is empty.");
            var cacheBudget = rawSchemaRegistry.CacheBudget;
            RequirePositiveCacheBudget(cacheBudget);
            ValidateCanonicalArtifactOrder(artifacts);
            ValidateCanonicalComponentOrder(rawComponents);

            var declarationComponentReferences =
                CollectDeclarationComponentReferences(
                    rawRules,
                    rawSchemaRegistry.PayloadSchemas,
                    rawSchemaRegistry.Parsers,
                    rawSchemaRegistry.Indexes,
                    rawSchemaRegistry.DemandProjectors);
            var admissionProofComponentReferences =
                rawSchemaRegistry.AdmissionProofContracts
                    .Select(contract => (
                        contract.ProofComponent.ComponentKey,
                        contract.ProofComponent.ComponentVersion))
                    .ToHashSet();
            declarationComponentReferences.UnionWith(
                admissionProofComponentReferences);

            var typedCacheBudget = SessionCacheBudget.Create(
                cacheBudget.MaxDecodeEntries,
                cacheBudget.MaxDecodeCanonicalBytes,
                cacheBudget.MaxIndexEntries,
                cacheBudget.MaxIndexNodes,
                cacheBudget.MaxConcurrentDecodeAttempts,
                cacheBudget.MaxConcurrentIndexAttempts,
                CacheRetentionPolicy.Parse(cacheBudget.RetentionPolicy));
            var typedCatalogVersion = CatalogVersion.Create(catalogVersion);

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
            var componentKeys =
                new HashSet<(string ComponentKey, string ComponentVersion)>();
            var physicalComponentIdentities =
                new HashSet<(string AssemblyName, string TypeName)>();
            var usedArtifacts = new HashSet<string>(StringComparer.Ordinal);
            ComponentTypeIdentity? activationProofComponent = null;
            var componentLookup = new Dictionary<(string, string), ComponentTypeIdentity>();

            foreach (var component in rawComponents)
            {
                var componentIdentity = ComponentTypeIdentity.Create(
                    component.ComponentKey,
                    component.ComponentVersion,
                    component.AssemblyName,
                    component.TypeName);
                if (!componentKeys.Add(
                        (componentIdentity.ComponentKey,
                         componentIdentity.ComponentVersion)))
                {
                    throw new FormatException(
                        "The manifest components array contains duplicate component identities.");
                }

                if (!physicalComponentIdentities.Add(
                        (componentIdentity.AssemblyName,
                         componentIdentity.TypeName)))
                {
                    throw new FormatException(
                        "The manifest components array contains a duplicate physical type identity.");
                }

                if (!artifactFileNames.Contains(component.ArtifactFileName))
                {
                    throw new FormatException(component.ComponentKey.StartsWith("protocol.projector.", StringComparison.Ordinal)
                        ? "protocol.manifest.artifact-owner" : "The manifest component mapping references an undeclared artifact.");
                }

                var componentBinding = ComponentArtifactBinding.Create(
                    componentIdentity,
                    component.ArtifactFileName);
                componentBindings.Add(componentBinding);
                usedArtifacts.Add(component.ArtifactFileName);
                componentLookup[(componentIdentity.ComponentKey, componentIdentity.ComponentVersion)] =
                    componentIdentity;

                if (IsActivationProof(componentIdentity, activationProof))
                {
                    activationProofComponent = componentIdentity;
                }
            }

            if (!declarationComponentReferences.IsSubsetOf(componentKeys))
                throw new FormatException("protocol.manifest.component-closure");
            ValidateFunctionalRoleCollisions(rawRules, rawSchemaRegistry, activationProof);

            if (activationProofComponent is null)
            {
                throw new FormatException(
                    "The activation-proof component is not declared.");
            }

            foreach (var binding in componentBindings)
            {
                var component = binding.Component;
                var componentReference =
                    (component.ComponentKey, component.ComponentVersion);
                var isActivationProof =
                    IsActivationProof(component, activationProof);
                var isRuntimeAnchor = IsRuntimeAnchor(binding);
                var hasRuntimeAnchorPhysicalIdentity =
                    IsRuntimeAnchorPhysicalIdentity(component);
                var isDeclarationReference =
                    declarationComponentReferences.Contains(componentReference);

                if ((IsRuntimeAnchorKey(component.ComponentKey) ||
                     hasRuntimeAnchorPhysicalIdentity) &&
                    !isRuntimeAnchor)
                {
                    throw new FormatException(
                        "A runtime anchor does not have its exact schema-1 identity and artifact mapping.");
                }

                if (isRuntimeAnchor &&
                    (isActivationProof || isDeclarationReference))
                {
                    throw new FormatException(
                        "A runtime anchor cannot satisfy a functional declaration reference.");
                }

                if (!isActivationProof &&
                    !isRuntimeAnchor &&
                    !isDeclarationReference)
                {
                    throw new FormatException("protocol.manifest.component-closure");
                }
            }

            if (!artifactFileNames.SetEquals(usedArtifacts))
            {
                throw new FormatException(
                    "The manifest artifactFiles array must be fully bound.");
            }

            ValidateProjectorValuesAndSlots(rawSchemaRegistry.DemandProjectors, rawRules);

            var schemaRegistry = ReleaseSchemaRegistry.Create(
                CreatePayloadSchemas(
                    rawSchemaRegistry.PayloadSchemas,
                    componentLookup),
                CreateParsers(rawSchemaRegistry.Parsers, componentLookup),
                CreateIndexes(rawSchemaRegistry.Indexes, componentLookup),
                CreateDemandProjectors(rawSchemaRegistry.DemandProjectors, componentLookup),
                CreateAdmissionProofContracts(
                    rawSchemaRegistry.AdmissionProofContracts,
                    componentLookup),
                typedCacheBudget);

            var typedRules = CreateRules(rawRules, componentLookup);
            var typedSlice = slice is null ? null : CatalogSliceDeclaration.Create(
                slice.SliceKey,
                slice.SliceVersion,
                protocolVersion,
                typedCatalogVersion,
                typedRules);
            CatalogSliceDeclaration.ValidateSchemaSlotClosure(
                schemaRegistry,
                typedRules);

            CompleteCatalogDeclaration? typedComplete = null;
            if (completeCatalog is not null)
            {
                var transitions = completeCatalog.Transitions.Select(item =>
                    RuleTransitionDeclaration.Added(
                        RuleId.Parse(item.RuleId),
                        RuleRevision.Create(item.CurrentRevision),
                        ReviewedAuthorityPermalink.Create(item.ReviewedAuthority)));
                var profiles = completeCatalog.NamedProfiles.Select(item =>
                    NamedProfileDeclaration.Create(
                        item.Name,
                        ExecutionProfile.Create(
                            SubjectRole.Parse(item.SubjectRole),
                            ProtocolOperation.Parse(item.Operation),
                            SnapshotKind.Parse(item.SnapshotKind),
                            SurfaceSet.Create(item.Surfaces.Select(SurfaceKind.Parse)),
                            EnforcementPhase.Parse(item.EnforcementPhase)),
                        item.RuleIds.Select(RuleId.Parse)));
                typedComplete = CompleteCatalogDeclaration.Create(
                    protocolVersion,
                    typedCatalogVersion,
                    CatalogPredecessorBinding.Genesis(),
                    completeCatalog.BaselineProfileName,
                    typedRules,
                    transitions,
                    profiles);
                if (!typedComplete.CompleteInventoryDigest.Equals(
                        ExactSha256Digest.Parse(completeCatalog.CompleteInventoryDigest)))
                    throw new FormatException("The complete inventory digest does not match the catalog rules.");
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
                typedSlice,
                typedComplete);
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

    private static HashSet<(string ComponentKey, string ComponentVersion)>
        CollectDeclarationComponentReferences(
            IReadOnlyList<RawRuleDeclaration> rules,
            IReadOnlyList<RawPayloadSchema> schemas,
            IReadOnlyList<RawSemanticParser> parsers,
            IReadOnlyList<RawContextIndex> indexes,
            IReadOnlyList<RawDemandProjector> projectors)
    {
        var references = new HashSet<(string, string)>();
        foreach (var schema in schemas)
        {
            references.Add((schema.Codec.ComponentKey, schema.Codec.ComponentVersion));
            references.Add((schema.ImplementationType.ComponentKey, schema.ImplementationType.ComponentVersion));
        }

        foreach (var parser in parsers)
        {
            references.Add((parser.Parser.ComponentKey, parser.Parser.ComponentVersion));
            references.Add((parser.Input.ImplementationType.ComponentKey,
                parser.Input.ImplementationType.ComponentVersion));
            references.Add((parser.OutputImplementationType.ComponentKey,
                parser.OutputImplementationType.ComponentVersion));
        }

        foreach (var index in indexes)
        {
            references.Add((index.Indexer.ComponentKey, index.Indexer.ComponentVersion));
            foreach (var input in index.Inputs)
            {
                var inputType = input.Model?.ImplementationType ??
                    input.Capability!.InterfaceType;
                references.Add((inputType.ComponentKey, inputType.ComponentVersion));
            }
            references.Add((index.OutputCapability.InterfaceType.ComponentKey, index.OutputCapability.InterfaceType.ComponentVersion));
        }

        foreach (var projector in projectors) { references.Add((projector.Projector.ComponentKey, projector.Projector.ComponentVersion)); references.Add((projector.InputCapability.InterfaceType.ComponentKey, projector.InputCapability.InterfaceType.ComponentVersion)); }

        foreach (var rule in rules)
        {
            references.Add(
                (rule.Evaluator.ComponentKey, rule.Evaluator.ComponentVersion));
            foreach (var slot in rule.ApplicabilitySlots.Concat(rule.EvaluationSlots))
            {
                foreach (var capability in slot.Capabilities)
                {
                    references.Add((
                        capability.InterfaceType.ComponentKey,
                        capability.InterfaceType.ComponentVersion));
                }
            }

            foreach (var selector in rule.ExpectedSelectors)
            {
                references.Add((
                    selector.Resolver.ComponentKey,
                    selector.Resolver.ComponentVersion));
            }
        }

        return references;
    }

    private static void ValidateFunctionalRoleCollisions(IReadOnlyList<RawRuleDeclaration> rules, RawSchemaRegistry registry, RawActivationProof activation)
    {
        var roles = new Dictionary<(string, string), string>();
        void Add(string role, RawComponentReference component)
        {
            var key = (component.ComponentKey, component.ComponentVersion);
            if (roles.TryGetValue(key, out var existing) && existing != role)
                throw new FormatException("protocol.manifest.functional-role-collision");
            roles[key] = role;
        }
        Add("activation", new RawComponentReference(activation.ComponentKey, activation.ComponentVersion));
        foreach (var item in registry.AdmissionProofContracts) Add("admission", item.ProofComponent);
        foreach (var item in registry.PayloadSchemas) { Add("codec", item.Codec); Add("model", item.ImplementationType); }
        foreach (var item in registry.Parsers) { Add("parser", item.Parser); Add("model", item.Input.ImplementationType); Add("model", item.OutputImplementationType); }
        foreach (var item in registry.Indexes)
        {
            Add("index", item.Indexer); Add("capability", item.OutputCapability.InterfaceType);
            foreach (var input in item.Inputs)
                Add(input.Model is null ? "capability" : "model",
                    input.Model?.ImplementationType ?? input.Capability!.InterfaceType);
        }
        foreach (var item in registry.DemandProjectors) { Add("projector", item.Projector); Add("capability", item.InputCapability.InterfaceType); }
        foreach (var rule in rules)
        {
            Add("evaluator", rule.Evaluator);
            foreach (var slot in rule.ApplicabilitySlots.Concat(rule.EvaluationSlots))
                foreach (var capability in slot.Capabilities) Add("capability", capability.InterfaceType);
            foreach (var selector in rule.ExpectedSelectors) Add("selector", selector.Resolver);
        }
    }

    private static void ValidateProjectorValuesAndSlots(IReadOnlyList<RawDemandProjector> projectors, IReadOnlyList<RawRuleDeclaration> rules)
    {
        if (projectors.Count == 0) return;
        var projector = projectors.SingleOrDefault(item => item.ProjectorKey == "protocol.projector.repository-target-resolution-demand" &&
            item.ProjectorVersion == "1");
        if (projector is null && projectors.Count == 1)
            throw new FormatException("protocol.manifest.projector-value");
        if (projector is null) return;
        if (projector.Projector != new RawComponentReference("protocol.projector.repository-target-resolution-demand", "1") ||
            projector.InputCapability != new RawCapabilityContract("protocol.capability.governed-reference-index", "1", new RawComponentReference("protocol.type.capability.governed-reference-index", "1")) ||
            !projector.InputSlotKeys.SequenceEqual(["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text"], StringComparer.Ordinal) ||
            projector.OutputSlotKey != "protocol.slot.repository-target-resolution" ||
            projector.DemandSchemaKey != "protocol.repository-target-resolution-demand" || projector.DemandSchemaVersion != "1" ||
            (projector.MaxBytes, projector.MaxDepth, projector.MaxNodes, projector.MaxComplexity) != (33_554_432, 64, 100_000, 5_000_000) ||
            !projector.FailureCodes.SequenceEqual(["protocol.budget.exhausted"], StringComparer.Ordinal))
            throw new FormatException("protocol.manifest.projector-value");

        var applicability = rules.SelectMany(item => item.ApplicabilitySlots).ToArray();
        var evaluation = rules.SelectMany(item => item.EvaluationSlots).ToArray();
        var inputSlotsValid = projector.InputSlotKeys.All(key => evaluation.Any(slot =>
            slot.SlotKey == key && slot.Capabilities.Any(capability =>
                capability.CapabilityKey == projector.InputCapability.CapabilityKey &&
                capability.CapabilityVersion == projector.InputCapability.CapabilityVersion)));
        if (!inputSlotsValid || applicability.Any(slot => slot.SlotKey == projector.OutputSlotKey) ||
            !evaluation.Any(slot => slot.SlotKey == projector.OutputSlotKey))
            throw new FormatException("protocol.manifest.projector-slot");
    }

    private static IReadOnlyList<AcquisitionDemandProjectorDeclaration> CreateDemandProjectors(IReadOnlyList<RawDemandProjector> projectors, IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components) =>
        projectors.Select(item => AcquisitionDemandProjectorDeclaration.Create(
            item.ProjectorKey, item.ProjectorVersion,
            ResolveComponentReference(item.Projector, components),
            CapabilityContractIdentity.Create(item.InputCapability.CapabilityKey,
                item.InputCapability.CapabilityVersion,
                ResolveComponentReference(item.InputCapability.InterfaceType, components)),
            item.InputSlotKeys.Select(value => value!), item.OutputSlotKey,
            item.DemandSchemaKey, item.DemandSchemaVersion,
            SemanticResourceBudget.Create(item.MaxBytes, item.MaxDepth, item.MaxNodes, item.MaxComplexity),
            item.FailureCodes.Select(value => EvaluationFailureCode.Parse(value!)))).ToArray();

    private static IReadOnlyList<PayloadSchemaDeclaration> CreatePayloadSchemas(
        IReadOnlyList<RawPayloadSchema> schemas,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components)
    {
        var declarations = new List<PayloadSchemaDeclaration>(schemas.Count);
        foreach (var schema in schemas)
        {
            declarations.Add(PayloadSchemaDeclaration.Create(
                schema.SchemaKey,
                schema.SchemaVersion,
                ResolveComponentReference(schema.Codec, components),
                ModelContractIdentity.Create(
                    schema.ModelKey,
                    schema.ModelVersion,
                    ResolveComponentReference(
                        schema.ImplementationType,
                        components)),
                schema.MaxBindingsPerInstruction,
                schema.MaxRetainedCanonicalBytesPerInstruction,
                SemanticResourceBudget.Create(
                    schema.MaxBytes,
                    schema.MaxDepth,
                    schema.MaxNodes,
                    schema.MaxComplexity),
                schema.CodecFailureCodes));
        }

        return declarations;
    }

    private static IReadOnlyList<SemanticModelParserDeclaration> CreateParsers(
        IReadOnlyList<RawSemanticParser> parsers,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components) =>
        parsers.Select(parser => SemanticModelParserDeclaration.Create(
            parser.ParserKey, parser.ParserVersion,
            ResolveComponentReference(parser.Parser, components),
            [ComponentInputDeclaration.ForModel(
                ModelContractIdentity.Create(parser.Input.ModelKey, parser.Input.ModelVersion,
                    ResolveComponentReference(parser.Input.ImplementationType, components)),
                parser.Input.MinimumCount, parser.Input.MaximumCount)],
            ModelContractIdentity.Create(parser.OutputModelKey, parser.OutputModelVersion,
                ResolveComponentReference(parser.OutputImplementationType, components)),
            SemanticResourceBudget.Create(parser.MaxBytes, parser.MaxDepth, parser.MaxNodes, parser.MaxComplexity),
            parser.FailureCodes.Select(EvaluationFailureCode.Parse)))
        .ToArray();

    private static IReadOnlyList<ContextIndexDeclaration> CreateIndexes(
        IReadOnlyList<RawContextIndex> indexes,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components) =>
        indexes.Select(index => ContextIndexDeclaration.Create(
            index.IndexKey,
            index.IndexVersion,
            ResolveComponentReference(index.Indexer, components),
            IndexInvocationScope.Parse(index.InvocationScope),
            index.Inputs.Select(input => CreateIndexInput(input, components)),
            CapabilityContractIdentity.Create(
                index.OutputCapability.CapabilityKey,
                index.OutputCapability.CapabilityVersion,
                ResolveComponentReference(index.OutputCapability.InterfaceType, components)),
            SemanticResourceBudget.Create(index.MaxBytes, index.MaxDepth, index.MaxNodes, index.MaxComplexity),
            index.FailureCodes.Select(EvaluationFailureCode.Parse)))
        .ToArray();

    private static IReadOnlyList<AdmissionProofContractDeclaration>
        CreateAdmissionProofContracts(
            IReadOnlyList<RawAdmissionProofContract> contracts,
            IReadOnlyDictionary<(string, string), ComponentTypeIdentity>
                components) =>
        contracts.Select(contract => AdmissionProofContractDeclaration.Create(
                contract.ContractKey,
                contract.ContractVersion,
                AdmissionProofKind.Parse(contract.Kind),
                ResolveComponentReference(contract.ProofComponent, components),
                SurfaceSet.Create(contract.Surfaces.Select(SurfaceKind.Parse)),
                contract.MaterialRoles))
            .ToArray();

    private static ComponentInputDeclaration CreateIndexInput(
        RawIndexInput input,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components)
    {
        if (input.Model is { } model)
        {
            return ComponentInputDeclaration.ForModel(
                ModelContractIdentity.Create(
                    model.ModelKey,
                    model.ModelVersion,
                    ResolveComponentReference(
                        model.ImplementationType,
                        components)),
                input.MinimumCount,
                input.MaximumCount);
        }

        if (input.Capability is { } capability)
        {
            return ComponentInputDeclaration.ForCapability(
                CapabilityContractIdentity.Create(
                    capability.CapabilityKey,
                    capability.CapabilityVersion,
                    ResolveComponentReference(
                        capability.InterfaceType,
                        components)),
                input.MinimumCount,
                input.MaximumCount);
        }

        throw new FormatException(
            "The manifest index input must declare one contract identity.");
    }

    private static void ValidateCanonicalArtifactOrder(
        IReadOnlyList<RawArtifact> artifacts)
    {
        for (var index = 1; index < artifacts.Count; index++)
        {
            if (StringComparer.Ordinal.Compare(
                    artifacts[index - 1].FileName,
                    artifacts[index].FileName) >= 0)
            {
                throw new FormatException(
                    "The manifest artifactFiles array is not in canonical FileName order.");
            }
        }
    }

    private static void ValidateCanonicalComponentOrder(
        IReadOnlyList<RawComponent> components)
    {
        for (var index = 1; index < components.Count; index++)
        {
            var previous = components[index - 1];
            var current = components[index];
            var keyComparison = StringComparer.Ordinal.Compare(
                previous.ComponentKey,
                current.ComponentKey);
            if (keyComparison > 0 ||
                (keyComparison == 0 &&
                 StringComparer.Ordinal.Compare(
                     previous.ComponentVersion,
                     current.ComponentVersion) >= 0))
            {
                if (previous.ComponentKey == current.ComponentKey &&
                    previous.ComponentVersion == current.ComponentVersion &&
                    previous.ComponentKey.StartsWith("protocol.projector.", StringComparison.Ordinal))
                    throw new FormatException("protocol.manifest.component-closure");
                throw new FormatException(
                    "The manifest components array is not in canonical key/version order.");
            }
        }
    }

    private static IReadOnlyList<RuleDeclaration> CreateRules(
        IReadOnlyList<RawRuleDeclaration> rules,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components)
    {
        var declarations = new List<RuleDeclaration>(rules.Count);
        foreach (var rule in rules)
        {
            declarations.Add(
                RuleDeclaration.Create(
                    RuleId.Parse(rule.RuleId),
                    RuleRevision.Create(rule.RuleRevision),
                    CatalogVersion.Create(rule.CatalogVersion),
                    ExactSha256Digest.Parse(rule.NormativeDigest),
                    CreateNormativeFragments(rule.NormativeFragments),
                    rule.QualificationScenarios.Select(TestScenarioId.Parse).ToList(),
                    ResolveComponentReference(rule.Evaluator, components),
                    CreateEvidenceSlots(rule.ApplicabilitySlots, components),
                    CreateEvidenceSlots(rule.EvaluationSlots, components),
                    CreateExpectedSelectors(rule.ExpectedSelectors, components),
                    rule.SubjectRoles.Select(SubjectRole.Parse).ToList(),
                    SurfaceSet.Create(rule.Surfaces.Select(SurfaceKind.Parse)),
                    rule.SnapshotKinds.Select(SnapshotKind.Parse).ToList(),
                    rule.Operations.Select(ProtocolOperation.Parse).ToList(),
                    CreateFindings(rule.Findings),
                    rule.EvaluationFailureCodes.Select(EvaluationFailureCode.Parse).ToList(),
                    rule.IntroducedIn,
                    rule.DeprecatedIn is not null
                        ? rule.DeprecatedIn
                        : null,
                    rule.RetiredIn is not null
                        ? rule.RetiredIn
                        : null,
                    rule.CompatibilityAliases));
        }

        return declarations;
    }

    private static IReadOnlyList<NormativeFragmentDeclaration> CreateNormativeFragments(
        IReadOnlyList<RawNormativeFragment> fragments)
    {
        var declarations = new List<NormativeFragmentDeclaration>(fragments.Count);
        foreach (var fragment in fragments)
        {
            declarations.Add(
                NormativeFragmentDeclaration.Create(
                    fragment.Path,
                    fragment.ContainingBlob,
                    fragment.Anchor,
                    fragment.StartLine,
                    fragment.EndLine,
                    fragment.CanonicalizationSchema,
                    fragment.CanonicalByteLength,
                    ExactSha256Digest.Parse(fragment.FragmentDigest)));
        }

        return declarations;
    }

    private static IReadOnlyList<EvidenceSlotDeclaration> CreateEvidenceSlots(
        IReadOnlyList<RawEvidenceSlot> slots,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components)
    {
        var declarations = new List<EvidenceSlotDeclaration>(slots.Count);
        foreach (var slot in slots)
        {
            declarations.Add(
                EvidenceSlotDeclaration.Create(
                    slot.SlotKey,
                    EvidenceRequirement.Create(
                        slot.Requirement.Key,
                        SurfaceKind.Parse(slot.Requirement.Surface),
                        slot.Requirement.Kind,
                        slot.Requirement.CompletenessContract,
                        slot.Requirement.PayloadSchemaKey,
                        slot.Requirement.PayloadSchemaVersion,
                        slot.Requirement.AcceptedConsistencyClasses.Select(
                            EvidenceConsistencyClass.Parse)),
                    SurfaceSet.Create(slot.ProfileSurfaces.Select(SurfaceKind.Parse)),
                    slot.MaterialRole,
                    slot.TargetSelectorKey,
                    slot.Capabilities.Select(
                            capability => CapabilityContractIdentity.Create(
                                capability.CapabilityKey,
                                capability.CapabilityVersion,
                                ResolveComponentReference(
                                    capability.InterfaceType,
                                    components)))
                        .ToList()));
        }

        return declarations;
    }

    private static IReadOnlyList<ExpectedSelectorDeclaration> CreateExpectedSelectors(
        IReadOnlyList<RawExpectedSelector> selectors,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components)
    {
        var declarations = new List<ExpectedSelectorDeclaration>(selectors.Count);
        foreach (var selector in selectors)
        {
            declarations.Add(
                ExpectedSelectorDeclaration.Create(
                    selector.SelectorKey,
                    selector.SlotKey,
                    selector.SelectorSchemaKey,
                    ResolveComponentReference(selector.Resolver, components),
                    selector.AllowedParentKinds.Select(
                        QualifiedEvidenceReferenceKind.Parse),
                    selector.AllowedFindingCodes.Select(FindingCode.Parse)));
        }

        return declarations;
    }

    private static IReadOnlyList<FindingDeclaration> CreateFindings(
        IReadOnlyList<RawFindingDeclaration> findings)
    {
        var declarations = new List<FindingDeclaration>(findings.Count);
        foreach (var finding in findings)
        {
            declarations.Add(
                FindingDeclaration.Create(
                    FindingCode.Parse(finding.Code),
                    FindingSeverity.Parse(finding.Severity),
                    RemediationKey.Parse(finding.Remediation),
                    finding.AllowedPrimaryReferenceKinds.Select(
                        QualifiedEvidenceReferenceKind.Parse),
                    finding.AllowedRelatedReferenceKinds.Select(
                        QualifiedEvidenceReferenceKind.Parse)));
        }

        return declarations;
    }

    private static ComponentTypeIdentity ResolveComponentReference(
        RawComponentReference componentReference,
        IReadOnlyDictionary<(string, string), ComponentTypeIdentity> components)
    {
        if (!components.TryGetValue(
            (componentReference.ComponentKey, componentReference.ComponentVersion),
            out var component))
        {
            throw new FormatException(
                "The manifest rule references a component that is not declared.");
        }

        return component;
    }

    private static bool IsRuntimeAnchor(ComponentArtifactBinding binding)
    {
        var component = binding.Component;
        return component.ComponentVersion is "1" &&
            component switch
            {
                _ when component.ComponentKey == "protocol.runtime.domain" &&
                    component.AssemblyName == "MeAndAI.Protocol.Domain" &&
                    component.TypeName == "MeAndAI.Protocol.Domain.RuleId" &&
                    binding.ArtifactFileName == "MeAndAI.Protocol.Domain.dll" => true,
                _ when component.ComponentKey == "protocol.runtime.conformance-abstractions" &&
                    component.AssemblyName == "MeAndAI.Protocol.Conformance.Abstractions" &&
                    component.TypeName == "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport" &&
                    binding.ArtifactFileName == "MeAndAI.Protocol.Conformance.Abstractions.dll" => true,
                _ when component.ComponentKey == "protocol.runtime.conformance" &&
                    component.AssemblyName == "MeAndAI.Protocol.Conformance" &&
                    component.TypeName == "MeAndAI.Protocol.Conformance.CatalogIntegrityException" &&
                    binding.ArtifactFileName == "MeAndAI.Protocol.Conformance.dll" => true,
                _ when component.ComponentKey == "protocol.runtime.markdig" &&
                    component.AssemblyName == "Markdig" &&
                    component.TypeName == "Markdig.Markdown" &&
                    binding.ArtifactFileName == "Markdig.dll" => true,
                _ => false,
            };
    }

    private static bool IsRuntimeAnchorKey(string componentKey) =>
        componentKey is
            "protocol.runtime.domain" or
            "protocol.runtime.conformance-abstractions" or
            "protocol.runtime.conformance" or
            "protocol.runtime.markdig";

    private static bool IsRuntimeAnchorPhysicalIdentity(
        ComponentTypeIdentity component) =>
        component switch
        {
            _ when component.AssemblyName == "MeAndAI.Protocol.Domain" &&
                component.TypeName == "MeAndAI.Protocol.Domain.RuleId" => true,
            _ when component.AssemblyName == "MeAndAI.Protocol.Conformance.Abstractions" &&
                component.TypeName == "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport" => true,
            _ when component.AssemblyName == "MeAndAI.Protocol.Conformance" &&
                component.TypeName == "MeAndAI.Protocol.Conformance.CatalogIntegrityException" => true,
            _ when component.AssemblyName == "Markdig" &&
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
            RequireProperty(expected);
        }

        internal void RequireProperty(string expected)
        {
            if (_reader.TokenType != JsonTokenType.PropertyName)
            {
                throw new FormatException(
                    $"Expected policy manifest property '{expected}'.");
            }

            if (!_reader.ValueTextEquals(expected))
            {
                throw new FormatException(
                    $"Expected policy manifest property '{expected}'.");
            }
        }

        internal JsonTokenType TokenType => _reader.TokenType;

        internal bool IsPropertyName(string expected) =>
            _reader.TokenType == JsonTokenType.PropertyName &&
            _reader.ValueTextEquals(expected);

        internal void ExpectEmptyArray()
        {
            Expect(JsonTokenType.StartArray);
            Expect(JsonTokenType.EndArray);
        }

        internal string ReadString()
        {
            Expect(JsonTokenType.String);
            return ReadCurrentString();
        }

        internal string ReadCurrentString()
        {
            if (_reader.TokenType != JsonTokenType.String)
            {
                throw new FormatException(
                    "Expected JSON token 'String'.");
            }

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

        internal bool Read()
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

    private sealed record RawSlice(
        string SliceKey,
        string SliceVersion,
        IReadOnlyList<RawRuleDeclaration> Rules);

    private sealed record RawCompleteCatalog(
        string CompleteInventoryDigest,
        string BaselineProfileName,
        IReadOnlyList<RawRuleDeclaration> Rules,
        IReadOnlyList<RawTransition> Transitions,
        IReadOnlyList<RawNamedProfile> NamedProfiles);

    private sealed record RawTransition(
        string RuleId,
        int CurrentRevision,
        string ReviewedAuthority);

    private sealed record RawNamedProfile(
        string Name,
        string SubjectRole,
        string Operation,
        string SnapshotKind,
        IReadOnlyList<string> Surfaces,
        string EnforcementPhase,
        IReadOnlyList<string> RuleIds);

    private sealed record RawRuleDeclaration(
        string RuleId,
        int RuleRevision,
        int CatalogVersion,
        string NormativeDigest,
        IReadOnlyList<RawNormativeFragment> NormativeFragments,
        IReadOnlyList<string> QualificationScenarios,
        RawComponentReference Evaluator,
        IReadOnlyList<RawEvidenceSlot> ApplicabilitySlots,
        IReadOnlyList<RawEvidenceSlot> EvaluationSlots,
        IReadOnlyList<RawExpectedSelector> ExpectedSelectors,
        IReadOnlyList<string> SubjectRoles,
        IReadOnlyList<string> Surfaces,
        IReadOnlyList<string> SnapshotKinds,
        IReadOnlyList<string> Operations,
        IReadOnlyList<RawFindingDeclaration> Findings,
        IReadOnlyList<string> EvaluationFailureCodes,
        string IntroducedIn,
        string? DeprecatedIn,
        string? RetiredIn,
        IReadOnlyList<string> CompatibilityAliases);

    private sealed record RawNormativeFragment(
        string Path,
        string ContainingBlob,
        string Anchor,
        int StartLine,
        int EndLine,
        string CanonicalizationSchema,
        long CanonicalByteLength,
        string FragmentDigest);

    private sealed record RawEvidenceSlot(
        string SlotKey,
        RawEvidenceRequirement Requirement,
        IReadOnlyList<string> ProfileSurfaces,
        string MaterialRole,
        string TargetSelectorKey,
        IReadOnlyList<RawCapabilityContract> Capabilities);

    private sealed record RawEvidenceRequirement(
        string Key,
        string Surface,
        string Kind,
        string CompletenessContract,
        string PayloadSchemaKey,
        string PayloadSchemaVersion,
        IReadOnlyList<string> AcceptedConsistencyClasses);

    private sealed record RawCapabilityContract(
        string CapabilityKey,
        string CapabilityVersion,
        RawComponentReference InterfaceType);

    private sealed record RawExpectedSelector(
        string SelectorKey,
        string SlotKey,
        string SelectorSchemaKey,
        RawComponentReference Resolver,
        IReadOnlyList<string> AllowedParentKinds,
        IReadOnlyList<string> AllowedFindingCodes);

    private sealed record RawFindingDeclaration(
        string Code,
        string Severity,
        string Remediation,
        IReadOnlyList<string> AllowedPrimaryReferenceKinds,
        IReadOnlyList<string> AllowedRelatedReferenceKinds);

    private sealed record RawComponentReference(string ComponentKey, string ComponentVersion);

    private sealed record RawSchemaRegistry(
        IReadOnlyList<RawPayloadSchema> PayloadSchemas,
        IReadOnlyList<RawSemanticParser> Parsers,
        IReadOnlyList<RawContextIndex> Indexes,
        IReadOnlyList<RawDemandProjector> DemandProjectors,
        IReadOnlyList<RawAdmissionProofContract> AdmissionProofContracts,
        RawCacheBudget CacheBudget);

    private sealed record RawDemandProjector(
        string ProjectorKey, string ProjectorVersion, RawComponentReference Projector, RawCapabilityContract InputCapability,
        IReadOnlyList<string?> InputSlotKeys, string OutputSlotKey, string DemandSchemaKey, string DemandSchemaVersion, long MaxBytes,
        int MaxDepth, long MaxNodes, long MaxComplexity, IReadOnlyList<string?> FailureCodes)
    {
        internal bool HasSameValues(RawDemandProjector other) => this with { InputSlotKeys = other.InputSlotKeys, FailureCodes = other.FailureCodes } == other && InputSlotKeys.SequenceEqual(other.InputSlotKeys, StringComparer.Ordinal) && FailureCodes.SequenceEqual(other.FailureCodes, StringComparer.Ordinal);
    }

    private sealed record RawAdmissionProofContract(
        string ContractKey,
        string ContractVersion,
        string Kind,
        RawComponentReference ProofComponent,
        IReadOnlyList<string> Surfaces,
        IReadOnlyList<string> MaterialRoles);

    private sealed record RawSemanticParser(
        string ParserKey, string ParserVersion, RawComponentReference Parser,
        RawModelInput Input, string OutputModelKey, string OutputModelVersion,
        RawComponentReference OutputImplementationType,
        long MaxBytes, int MaxDepth, long MaxNodes, long MaxComplexity,
        IReadOnlyList<string> FailureCodes);

    private sealed record RawContextIndex(
        string IndexKey, string IndexVersion, RawComponentReference Indexer,
        string InvocationScope, IReadOnlyList<RawIndexInput> Inputs,
        RawCapabilityContract OutputCapability, long MaxBytes, int MaxDepth,
        long MaxNodes, long MaxComplexity, IReadOnlyList<string> FailureCodes);

    private sealed record RawIndexInput(RawModelContract? Model, RawCapabilityContract? Capability,
        int MinimumCount, int? MaximumCount);

    private sealed record RawModelContract(string ModelKey, string ModelVersion,
        RawComponentReference ImplementationType);

    private sealed record RawModelInput(
        string ModelKey, string ModelVersion,
        RawComponentReference ImplementationType,
        int MinimumCount, int? MaximumCount);

    private sealed record RawPayloadSchema(
        string SchemaKey,
        string SchemaVersion,
        RawComponentReference Codec,
        string ModelKey,
        string ModelVersion,
        RawComponentReference ImplementationType,
        int MaxBindingsPerInstruction,
        long MaxRetainedCanonicalBytesPerInstruction,
        long MaxBytes,
        int MaxDepth,
        long MaxNodes,
        long MaxComplexity,
        IReadOnlyList<string> CodecFailureCodes);

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
    CatalogSliceDeclaration? Slice,
    CompleteCatalogDeclaration? CompleteCatalog = null);
