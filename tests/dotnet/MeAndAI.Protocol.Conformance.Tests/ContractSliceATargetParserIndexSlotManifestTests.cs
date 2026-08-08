using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceATargetParserIndexSlotManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private static readonly string[] MarkdownParserFailures = ["protocol.budget.exhausted", "protocol.model.invalid-markdown"];
    private static readonly string[] TargetParserFailures = ["protocol.budget.exhausted"];
    private static readonly string[] GovernedIndexFailures = ["protocol.budget.exhausted", "protocol.index.reference-unavailable"];
    private static readonly string[] RecordFailures = ["protocol.budget.exhausted", "protocol.index.record-unavailable"];
    private static readonly string[] TargetIndexFailures = ["protocol.budget.exhausted", "protocol.index.repository-target-resolution-unavailable"];
    private static readonly string[] TreeIndexFailures = ["protocol.budget.exhausted", "protocol.index.repository-tree-unavailable"];
    private static readonly string[] GovernedCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-utf8", "protocol.codec.noncanonical-encoding", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TargetCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-target-resolution", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TreeCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-tree", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly (string Key, string Assembly, string Type, string Artifact)[] Components =
    [
        ("protocol.activation-proof.test", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof", "ContractSliceA.Proof.dll"),
        ("protocol.codec.governed-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.codec.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.codec.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.evaluator.test-rule", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAIndexSlotEvaluator", "ContractSliceA.Proof.dll"),
        ("protocol.index.governed-reference", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.index.protocol-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.index.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.index.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.parser.markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.parser.repository-target-markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.capability.governed-reference-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.protocol-record-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.repository-target-resolution-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.repository-tree", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.model.markdown-document", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-target-markdown-document-set", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.source-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.SourceTextModel", "MeAndAI.Protocol.Policy.dll"),
    ];

    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_repository_target_schema_parser_index_and_slot_capability_closure()
    {
        var registry = CreateRegistry();
        var rule = CreateRule();
        var proof = ActivationProofContractDeclaration.Create("protocol.activation-proof.test", "1.0.0", Resolve("protocol.activation-proof.test"));
        var artifacts = new[] { Artifact("ContractSliceA.Proof.dll"), Artifact("MeAndAI.Protocol.Conformance.Abstractions.dll"), Artifact("MeAndAI.Protocol.Policy.dll") };
        var components = Components.Select(item => ComponentArtifactBinding.Create(Resolve(item.Key), item.Artifact)).ToArray();
        var slice = CatalogSliceDeclaration.Create("protocol.catalog-slice.index-slot", "1", "0.0.0", CatalogVersion.Create(1), [rule]);
        var parsed = new ParsedCanonicalManifest(CatalogAuthorityKind.QualificationSlice, Commit, registry, proof, artifacts, components, slice);
        var bytes = CanonicalManifestWriter.Write(parsed);
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        AssertGraph(manifest);
        AssertWire(bytes);
    }

    private static void AssertGraph(FinalizedPolicyManifest manifest)
    {
        var registry = manifest.SchemaRegistry;
        Assert.Equal(["protocol.governed-text", "protocol.repository-target-resolution", "protocol.repository-tree"], registry.PayloadSchemas.Select(item => item.SchemaKey));
        Assert.Equal(["protocol.parser.markdown", "protocol.parser.repository-target-markdown"], registry.Parsers.Select(item => item.ParserKey));
        Assert.Equal(["protocol.index.governed-reference", "protocol.index.protocol-record", "protocol.index.repository-target-resolution", "protocol.index.repository-tree"], registry.Indexes.Select(item => item.IndexKey));
        Assert.Empty(registry.DemandProjectors);
        Assert.Empty(registry.AdmissionProofContracts);
        AssertSchema(registry.PayloadSchemas[0], "protocol.governed-text", SourceModel(), 200_000, 67_108_864, MarkdownBudget(), GovernedCodecFailures);
        AssertSchema(registry.PayloadSchemas[1], "protocol.repository-target-resolution", TargetResolutionModel(), 1, 33_554_432, TargetSchemaBudget(), TargetCodecFailures);
        AssertSchema(registry.PayloadSchemas[2], "protocol.repository-tree", TreeModel(), 1, 16_777_216, TreeBudget(), TreeCodecFailures);
        Assert.True(registry.TryGetPayloadSchema("protocol.repository-target-resolution", "1", out var targetSchema));
        Assert.Same(registry.PayloadSchemas[1], targetSchema);
        Assert.False(registry.TryGetPayloadSchema("protocol.repository-target-resolution-missing", "1", out _));

        var markdown = registry.Parsers[0];
        AssertParser(markdown, "protocol.parser.markdown", MarkdownModel(), MarkdownBudget(), MarkdownParserFailures);
        AssertModelInput(Assert.Single(markdown.Inputs), SourceModel(), 1, 1);
        var targetParser = registry.Parsers[1];
        AssertParser(targetParser, "protocol.parser.repository-target-markdown", TargetMarkdownModel(), TargetParserBudget(), TargetParserFailures);
        AssertModelInput(Assert.Single(targetParser.Inputs), TargetResolutionModel(), 1, 1);
        Assert.True(registry.TryGetParser("protocol.parser.repository-target-markdown", "1", out var resolvedParser));
        Assert.Same(targetParser, resolvedParser);
        Assert.False(registry.TryGetParser("protocol.parser.repository-target-markdown-missing", "1", out _));

        AssertIndex(registry.Indexes[0], "protocol.index.governed-reference", IndexInvocationScope.PerPlan, GovernedCapability(), GovernedBudget(), GovernedIndexFailures);
        AssertModelInput(registry.Indexes[0].Inputs[0], MarkdownModel(), 0, null);
        AssertCapabilityInput(registry.Indexes[0].Inputs[1], RecordCapability(), 1, null);
        AssertIndex(registry.Indexes[1], "protocol.index.protocol-record", IndexInvocationScope.PerContext, RecordCapability(), GovernedBudget(), RecordFailures);
        AssertModelInput(Assert.Single(registry.Indexes[1].Inputs), MarkdownModel(), 0, null);
        var targetIndex = registry.Indexes[2];
        AssertIndex(targetIndex, "protocol.index.repository-target-resolution", IndexInvocationScope.PerPlan, TargetCapability(), TargetIndexBudget(), TargetIndexFailures);
        Assert.Equal(3, targetIndex.Inputs.Count);
        AssertModelInput(targetIndex.Inputs[0], TargetMarkdownModel(), 0, null);
        AssertModelInput(targetIndex.Inputs[1], TargetResolutionModel(), 0, null);
        AssertCapabilityInput(targetIndex.Inputs[2], GovernedCapability(), 1, 1);
        AssertIndex(registry.Indexes[3], "protocol.index.repository-tree", IndexInvocationScope.PerContext, TreeCapability(), TreeBudget(), TreeIndexFailures);
        AssertModelInput(Assert.Single(registry.Indexes[3].Inputs), TreeModel(), 1, 1);
        Assert.True(registry.TryGetIndex("protocol.index.repository-target-resolution", "1", out var resolvedIndex));
        Assert.Same(targetIndex, resolvedIndex);
        Assert.False(registry.TryGetIndex("protocol.index.repository-target-resolution-missing", "1", out _));

        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        Assert.Empty(rule.ApplicabilitySlots);
        var slots = rule.EvaluationSlots;
        Assert.Equal(["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text", "protocol.slot.repository-target-resolution", "protocol.slot.repository-tree"], slots.Select(item => item.SlotKey));
        AssertGovernedSlot(slots[0], "provider", SurfaceKind.Provider, [SurfaceKind.Provider]);
        AssertGovernedSlot(slots[1], "repository", SurfaceKind.Repository, [SurfaceKind.Repository, SurfaceKind.Provider]);
        AssertTargetSlot(slots[2]);
        AssertTreeSlot(slots[3]);
        Assert.Equal((512, 67_108_864L, 128, 2_000_000L, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys), (registry.CacheBudget.MaxDecodeEntries,
            registry.CacheBudget.MaxDecodeCanonicalBytes, registry.CacheBudget.MaxIndexEntries, registry.CacheBudget.MaxIndexNodes,
            registry.CacheBudget.MaxConcurrentDecodeAttempts, registry.CacheBudget.MaxConcurrentIndexAttempts, registry.CacheBudget.RetentionPolicy));
        Assert.Equal(["ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll"], manifest.ArtifactFiles.Select(item => item.FileName));
        Assert.Equal(20, manifest.Components.Count);
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.All(manifest.Components, binding => Assert.Equal(Spec(binding.Component.ComponentKey).Artifact, binding.ArtifactFileName));
    }

    private static void AssertWire(byte[] bytes)
    {
        using var document = JsonDocument.Parse(bytes);
        var root = document.RootElement;
        var registry = root.GetProperty("schemaRegistry");
        var schemas = registry.GetProperty("payloadSchemas").EnumerateArray().ToArray();
        var parsers = registry.GetProperty("parsers").EnumerateArray().ToArray();
        var indexes = registry.GetProperty("indexes").EnumerateArray().ToArray();
        var slots = root.GetProperty("slice").GetProperty("rules").EnumerateArray().Single().GetProperty("evaluationSlots").EnumerateArray().ToArray();
        var targetSchema = schemas[1];
        var targetParser = parsers[1];
        var targetIndex = indexes[2];
        var targetSlot = slots[2];
        AssertOrder(targetSchema, "schemaKey", "schemaVersion", "codec", "outputModel", "maxBindingsPerInstruction", "maxRetainedCanonicalBytesPerInstruction", "budget", "codecFailureCodes");
        AssertOrder(targetParser, "parserKey", "parserVersion", "parser", "inputs", "outputModel", "budget", "failureCodes");
        AssertOrder(targetIndex, "indexKey", "indexVersion", "indexer", "invocationScope", "inputs", "outputCapability", "budget", "failureCodes");
        AssertOrder(targetSlot, "slotKey", "requirement", "profileSurfaces", "materialRole", "targetSelectorKey", "capabilities");
        AssertOrder(targetParser.GetProperty("inputs").EnumerateArray().Single(), "kind", "model", "minimumCount", "maximumCount");
        AssertOrder(targetIndex.GetProperty("inputs").EnumerateArray().ElementAt(0), "kind", "model", "minimumCount");
        AssertOrder(targetIndex.GetProperty("inputs").EnumerateArray().ElementAt(1), "kind", "model", "minimumCount");
        AssertOrder(targetIndex.GetProperty("inputs").EnumerateArray().ElementAt(2), "kind", "capability", "minimumCount", "maximumCount");
        AssertOrder(targetIndex.GetProperty("outputCapability"), "capabilityKey", "capabilityVersion", "interfaceType");
        AssertOrder(targetSlot.GetProperty("requirement"), "key", "surface", "kind", "completenessContract", "payloadSchemaKey", "payloadSchemaVersion", "acceptedConsistencyClasses");
        AssertOrder(targetSlot.GetProperty("capabilities").EnumerateArray().Single(), "capabilityKey", "capabilityVersion", "interfaceType");
        var text = Encoding.UTF8.GetString(bytes);
        var schemaText = targetSchema.GetRawText();
        var parserText = targetParser.GetRawText();
        var indexText = targetIndex.GetRawText();
        var slotText = targetSlot.GetRawText();
        var parserInput = targetParser.GetProperty("inputs").EnumerateArray().Single().GetRawText();
        var indexInputs = targetIndex.GetProperty("inputs").EnumerateArray().Select(item => item.GetRawText()).ToArray();
        var capability = targetIndex.GetProperty("outputCapability").GetRawText();
        var slotCapability = targetSlot.GetProperty("capabilities").EnumerateArray().Single().GetRawText();

        RejectInside(text, schemaText,
            ("\"schemaKey\":\"protocol.repository-target-resolution\"", "\"schemaKey\":\"protocol.repository-target-resolution-missing\""),
            ("\"schemaVersion\":\"1\"", "\"schemaVersion\":\"2\""),
            ("protocol.codec.repository-target-resolution", "protocol.codec.repository-target-resolution-missing"),
            ("\"codec\":{\"componentKey\":\"protocol.codec.repository-target-resolution\",\"componentVersion\":\"1\"}", "\"codec\":{\"componentKey\":\"protocol.codec.repository-target-resolution\",\"componentVersion\":\"2\"}"),
            ("\"outputModel\":{\"modelKey\":\"protocol.model.repository-target-resolution\",\"modelVersion\":\"1\"", "\"outputModel\":{\"modelKey\":\"protocol.model.repository-target-resolution\",\"modelVersion\":\"2\""),
            ("\"modelKey\":\"protocol.model.repository-target-resolution\"", "\"modelKey\":\"protocol.model.repository-target-resolution-missing\""),
            ("protocol.type.model.repository-target-resolution", "protocol.type.model.repository-target-resolution-missing"),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-target-resolution\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-target-resolution\",\"componentVersion\":\"2\"}"),
            ("\"maxBindingsPerInstruction\":1", "\"maxBindingsPerInstruction\":2"),
            ("\"maxRetainedCanonicalBytesPerInstruction\":33554432", "\"maxRetainedCanonicalBytesPerInstruction\":1"),
            ("\"maxBytes\":33554432", "\"maxBytes\":1"), ("\"maxDepth\":64", "\"maxDepth\":1"),
            ("\"maxNodes\":500000", "\"maxNodes\":1"), ("\"maxComplexity\":34054432", "\"maxComplexity\":1"),
            ("\"protocol.codec.embedded-identity-mismatch\",\"protocol.codec.invalid-repository-target-resolution\"", "\"protocol.codec.invalid-repository-target-resolution\",\"protocol.codec.embedded-identity-mismatch\""),
            ("\"codecFailureCodes\":[\"protocol.codec.embedded-identity-mismatch\",\"protocol.codec.invalid-repository-target-resolution\",\"protocol.codec.payload-location-mismatch\",\"protocol.codec.resource-limit-exceeded\"]", "\"codecFailureCodes\":[]"));
        RejectInside(text, schemaText, ("protocol.codec.invalid-repository-target-resolution", "protocol.codec.invalid-repository-tree"));
        RejectInside(text, parserText,
            ("\"parserKey\":\"protocol.parser.repository-target-markdown\"", "\"parserKey\":\"protocol.parser.repository-target-markdown-missing\""),
            ("\"parserVersion\":\"1\"", "\"parserVersion\":\"2\""),
            ("\"parser\":{\"componentKey\":\"protocol.parser.repository-target-markdown\",\"componentVersion\":\"1\"}", "\"parser\":{\"componentKey\":\"protocol.parser.repository-target-markdown-missing\",\"componentVersion\":\"1\"}"),
            ("\"parser\":{\"componentKey\":\"protocol.parser.repository-target-markdown\",\"componentVersion\":\"1\"}", "\"parser\":{\"componentKey\":\"protocol.parser.repository-target-markdown\",\"componentVersion\":\"2\"}"),
            ("\"outputModel\":{\"modelKey\":\"protocol.model.repository-target-markdown-document-set\",\"modelVersion\":\"1\"", "\"outputModel\":{\"modelKey\":\"protocol.model.repository-target-markdown-document-set\",\"modelVersion\":\"2\""),
            ("\"modelKey\":\"protocol.model.repository-target-markdown-document-set\"", "\"modelKey\":\"protocol.model.repository-target-markdown-document-set-missing\""),
            ("protocol.type.model.repository-target-markdown-document-set", "protocol.type.model.repository-target-markdown-document-set-missing"),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-target-markdown-document-set\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-target-markdown-document-set\",\"componentVersion\":\"2\"}"),
            ("\"maxBytes\":33554432", "\"maxBytes\":1"), ("\"maxDepth\":256", "\"maxDepth\":1"),
            ("\"maxNodes\":1000000", "\"maxNodes\":1"), ("\"maxComplexity\":34554432", "\"maxComplexity\":1"),
            ("\"failureCodes\":[\"protocol.budget.exhausted\"]", "\"failureCodes\":[]"));
        RejectInside(text, parserText, ("\"failureCodes\":[\"protocol.budget.exhausted\"]", "\"failureCodes\":[\"protocol.model.invalid-markdown\"]"));
        RejectNested(text, parserText, parserInput,
            ("\"kind\":\"model\"", "\"kind\":\"capability\""),
            ("protocol.model.repository-target-resolution", "protocol.model.repository-target-resolution-missing"),
            ("\"modelVersion\":\"1\"", "\"modelVersion\":\"2\""),
            ("\"componentKey\":\"protocol.type.model.repository-target-resolution\"", "\"componentKey\":\"protocol.type.model.repository-target-resolution-missing\""),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-target-resolution\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-target-resolution\",\"componentVersion\":\"2\"}"),
            ("\"minimumCount\":1", "\"minimumCount\":0"),
            ("\"minimumCount\":1,\"maximumCount\":1", "\"minimumCount\":1"));
        RejectInside(text, indexText,
            ("\"indexKey\":\"protocol.index.repository-target-resolution\"", "\"indexKey\":\"protocol.index.repository-target-resolution-missing\""),
            ("\"indexVersion\":\"1\"", "\"indexVersion\":\"2\""),
            ("\"indexer\":{\"componentKey\":\"protocol.index.repository-target-resolution\",\"componentVersion\":\"1\"}", "\"indexer\":{\"componentKey\":\"protocol.index.repository-target-resolution-missing\",\"componentVersion\":\"1\"}"),
            ("\"indexer\":{\"componentKey\":\"protocol.index.repository-target-resolution\",\"componentVersion\":\"1\"}", "\"indexer\":{\"componentKey\":\"protocol.index.repository-target-resolution\",\"componentVersion\":\"2\"}"),
            ("\"invocationScope\":\"per-plan\"", "\"invocationScope\":\"per-context\""),
            ("\"maxBytes\":67108864", "\"maxBytes\":1"), ("\"maxDepth\":256", "\"maxDepth\":1"),
            ("\"maxNodes\":2000000", "\"maxNodes\":1"), ("\"maxComplexity\":20000000", "\"maxComplexity\":1"),
            ("\"protocol.budget.exhausted\",\"protocol.index.repository-target-resolution-unavailable\"", "\"protocol.index.repository-target-resolution-unavailable\",\"protocol.budget.exhausted\""),
            ("\"failureCodes\":[\"protocol.budget.exhausted\",\"protocol.index.repository-target-resolution-unavailable\"]", "\"failureCodes\":[]"));
        RejectInside(text, indexText, ("protocol.index.repository-target-resolution-unavailable", "protocol.index.reference-unavailable"));
        RejectNested(text, indexText, indexInputs[0], ("\"kind\":\"model\"", "\"kind\":\"capability\""), ("protocol.model.repository-target-markdown-document-set", "protocol.model.repository-target-markdown-document-set-missing"), ("\"modelVersion\":\"1\"", "\"modelVersion\":\"2\""), ("\"componentKey\":\"protocol.type.model.repository-target-markdown-document-set\"", "\"componentKey\":\"protocol.type.model.repository-target-markdown-document-set-missing\""), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""), ("\"minimumCount\":0", "\"minimumCount\":1"), ("\"minimumCount\":0", "\"minimumCount\":0,\"maximumCount\":1"));
        RejectNested(text, indexText, indexInputs[1], ("\"kind\":\"model\"", "\"kind\":\"capability\""), ("protocol.model.repository-target-resolution", "protocol.model.repository-target-resolution-missing"), ("\"modelVersion\":\"1\"", "\"modelVersion\":\"2\""), ("\"componentKey\":\"protocol.type.model.repository-target-resolution\"", "\"componentKey\":\"protocol.type.model.repository-target-resolution-missing\""), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""), ("\"minimumCount\":0", "\"minimumCount\":1"), ("\"minimumCount\":0", "\"minimumCount\":0,\"maximumCount\":1"));
        RejectNested(text, indexText, indexInputs[2], ("\"kind\":\"capability\"", "\"kind\":\"model\""), ("protocol.capability.governed-reference-index", "protocol.capability.governed-reference-index-missing"), ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""), ("\"componentKey\":\"protocol.type.capability.governed-reference-index\"", "\"componentKey\":\"protocol.type.capability.governed-reference-index-missing\""), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""), ("\"minimumCount\":1", "\"minimumCount\":0"), ("\"minimumCount\":1,\"maximumCount\":1", "\"minimumCount\":1"));
        RejectNested(text, indexText, capability, ("protocol.capability.repository-target-resolution-index", "protocol.capability.repository-target-resolution-index-missing"), ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""), ("protocol.type.capability.repository-target-resolution-index", "protocol.type.capability.repository-target-resolution-index-missing"), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""));
        var inputArray = "\"inputs\":[" + string.Join(",", indexInputs) + "]";
        RejectMany(text, inputArray, "\"inputs\":[]", "\"inputs\":[" + indexInputs[1] + "," + indexInputs[0] + "," + indexInputs[2] + "]", "\"inputs\":[" + indexInputs[0] + "," + indexInputs[2] + "," + indexInputs[1] + "]", "\"inputs\":[" + indexInputs[0] + "," + indexInputs[1] + "]", "\"inputs\":[" + indexInputs[0] + "," + indexInputs[1] + "," + indexInputs[2] + "," + indexInputs[2] + "]");
        RejectInside(text, slotText,
            ("protocol.slot.repository-target-resolution", "protocol.slot.repository-target-resolution-missing"),
            ("protocol.requirement.repository-target-resolution", "protocol.requirement.repository-target-resolution-missing"),
            ("\"surface\":\"repository\"", "\"surface\":\"provider\""),
            ("protocol.evidence.repository-target-resolution-set", "protocol.evidence.repository-target-resolution-set-missing"),
            ("protocol.completeness.all-projected-target-resolutions", "protocol.completeness.all-projected-target-resolutions-missing"),
            ("\"payloadSchemaKey\":\"protocol.repository-target-resolution\"", "\"payloadSchemaKey\":\"protocol.repository-target-resolution-missing\""),
            ("\"payloadSchemaVersion\":\"1\"", "\"payloadSchemaVersion\":\"2\""),
            ("\"acceptedConsistencyClasses\":[\"exact-snapshot\",\"object-version-bound\"]", "\"acceptedConsistencyClasses\":[\"object-version-bound\",\"exact-snapshot\"]"),
            ("\"acceptedConsistencyClasses\":[\"exact-snapshot\",\"object-version-bound\"]", "\"acceptedConsistencyClasses\":[]"),
            ("\"profileSurfaces\":[\"repository\",\"provider\"]", "\"profileSurfaces\":[\"provider\",\"repository\"]"),
            ("\"profileSurfaces\":[\"repository\",\"provider\"]", "\"profileSurfaces\":[]"),
            ("protocol.material.repository-target-resolution", "protocol.material.repository-target-resolution-missing"),
            ("protocol.target.repository-target-resolution-set", "protocol.target.repository-target-resolution-set-missing"));
        RejectNested(text, slotText, slotCapability, ("protocol.capability.repository-target-resolution-index", "protocol.capability.repository-target-resolution-index-missing"), ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""), ("protocol.type.capability.repository-target-resolution-index", "protocol.type.capability.repository-target-resolution-index-missing"), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""));
        RejectMany(text, "\"capabilities\":[" + slotCapability + "]", "\"capabilities\":[]", "\"capabilities\":[" + slotCapability + "," + slotCapability + "]");

        RejectCollectionMutations(text, schemas, parsers, indexes, slots);
        AssertTargetTopologyMasks(text, targetSchema, targetParser, targetIndex, targetSlot, root.GetProperty("components").EnumerateArray().ToArray());
        var bindings = root.GetProperty("components").EnumerateArray().ToArray();
        foreach (var key in TargetComponentKeys())
        {
            var binding = bindings.Single(item => ComponentKey(item) == key).GetRawText();
            RejectRemove(text, binding);
            RejectInside(text, binding, ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""),
                ("\"assemblyName\":\"" + Spec(key).Assembly + "\"", "\"assemblyName\":\"Wrong.Assembly\""),
                ("\"typeName\":\"" + Spec(key).Type + "\"", "\"typeName\":\"Wrong.Type\""),
                ("\"artifactFileName\":\"" + Spec(key).Artifact + "\"", "\"artifactFileName\":\"Missing.dll\""));
        }
        var componentArray = "\"components\":[" + string.Join(",", bindings.Select(item => item.GetRawText())) + "]";
        var targetBinding = bindings.Single(item => ComponentKey(item) == "protocol.index.repository-target-resolution").GetRawText();
        RejectMany(text, componentArray,
            "\"components\":[" + string.Join(",", bindings.SelectMany(item => ComponentKey(item) == "protocol.index.repository-target-resolution" ? new[] { item.GetRawText(), item.GetRawText() } : new[] { item.GetRawText() })) + "]",
            "\"components\":[" + string.Join(",", bindings.SelectMany(item => ComponentKey(item) == "protocol.index.repository-target-resolution" ? new[] { item.GetRawText(), ReplaceRequired(targetBinding, "protocol.index.repository-target-resolution", "protocol.index.repository-target-resolution-unused") } : new[] { item.GetRawText() })) + "]");
        var artifacts = root.GetProperty("artifactFiles").EnumerateArray().Select(item => item.GetRawText()).ToArray();
        RejectMany(text, "\"artifactFiles\":[" + string.Join(",", artifacts) + "]", "\"artifactFiles\":[" + string.Join(",", artifacts) + "," + ReplaceRequired(artifacts[^1], "MeAndAI.Protocol.Policy.dll", "Unused.dll") + "]");
        AssertAccepted(ReplaceRequired(text, "\"applicabilitySlots\":[]", "\"applicabilitySlots\":[" + slotText + "]"));
        RejectMany(text, "\"demandProjectors\":[]", "\"demandProjectors\":[{}]");
        RejectMany(text, "\"admissionProofContracts\":[]", "\"admissionProofContracts\":[{}]");
    }

    private static void RejectCollectionMutations(string text, JsonElement[] schemas, JsonElement[] parsers, JsonElement[] indexes, JsonElement[] slots)
    {
        var schemaItems = schemas.Select(item => item.GetRawText()).ToArray();
        var parserItems = parsers.Select(item => item.GetRawText()).ToArray();
        var indexItems = indexes.Select(item => item.GetRawText()).ToArray();
        var slotItems = slots.Select(item => item.GetRawText()).ToArray();
        RejectMany(text, "\"payloadSchemas\":[" + string.Join(",", schemaItems) + "]", "\"payloadSchemas\":[" + string.Join(",", [schemaItems[0], schemaItems[2], schemaItems[1]]) + "]", "\"payloadSchemas\":[" + string.Join(",", [schemaItems[0], schemaItems[1], schemaItems[1], schemaItems[2]]) + "]");
        RejectMany(text, "\"parsers\":[" + string.Join(",", parserItems) + "]", "\"parsers\":[" + string.Join(",", parserItems.Reverse()) + "]", "\"parsers\":[" + string.Join(",", parserItems.Append(parserItems[1])) + "]");
        RejectMany(text, "\"indexes\":[" + string.Join(",", indexItems) + "]", "\"indexes\":[" + string.Join(",", [indexItems[0], indexItems[1], indexItems[3], indexItems[2]]) + "]", "\"indexes\":[" + string.Join(",", [indexItems[0], indexItems[1], indexItems[2], indexItems[2], indexItems[3]]) + "]");
        RejectMany(text, "\"evaluationSlots\":[" + string.Join(",", slotItems) + "]", "\"evaluationSlots\":[" + string.Join(",", [slotItems[0], slotItems[1], slotItems[3], slotItems[2]]) + "]", "\"evaluationSlots\":[" + string.Join(",", [slotItems[0], slotItems[1], slotItems[2], slotItems[2], slotItems[3]]) + "]");
    }

    private static void AssertTargetTopologyMasks(string text, JsonElement schema, JsonElement parser, JsonElement index, JsonElement slot, JsonElement[] bindings)
    {
        for (var mask = 0; mask < 15; mask++)
        {
            var candidate = text;
            if ((mask & 1) == 0) candidate = RemoveItem(candidate, schema.GetRawText());
            if ((mask & 2) == 0) candidate = RemoveItem(candidate, parser.GetRawText());
            if ((mask & 4) == 0) candidate = RemoveItem(candidate, index.GetRawText());
            if ((mask & 8) == 0) candidate = RemoveItem(candidate, slot.GetRawText());
            foreach (var key in TargetComponentKeys())
            {
                if (!TargetBindingNeeded(key, mask)) candidate = RemoveItem(candidate, bindings.Single(item => ComponentKey(item) == key).GetRawText());
            }
            if (mask == 0) AssertAccepted(candidate); else AssertPublicFormatException(candidate);
        }
    }

    private static bool TargetBindingNeeded(string key, int mask) => key switch
    {
        "protocol.codec.repository-target-resolution" => (mask & 1) != 0,
        "protocol.type.model.repository-target-resolution" => (mask & 7) != 0,
        "protocol.parser.repository-target-markdown" => (mask & 2) != 0,
        "protocol.type.model.repository-target-markdown-document-set" => (mask & 6) != 0,
        "protocol.index.repository-target-resolution" => (mask & 4) != 0,
        "protocol.type.capability.repository-target-resolution-index" => (mask & 12) != 0,
        _ => throw new InvalidOperationException(key),
    };

    private static string[] TargetComponentKeys() => ["protocol.codec.repository-target-resolution", "protocol.index.repository-target-resolution", "protocol.parser.repository-target-markdown", "protocol.type.capability.repository-target-resolution-index", "protocol.type.model.repository-target-markdown-document-set", "protocol.type.model.repository-target-resolution"];
    private static ReleaseSchemaRegistry CreateRegistry() => ReleaseSchemaRegistry.Create([TreeSchema(), TargetSchema(), GovernedSchema()], [TargetParser(), MarkdownParser()], [TreeIndex(), TargetIndex(), RecordIndex(), GovernedIndex()],
        Array.Empty<AcquisitionDemandProjectorDeclaration>(), Array.Empty<AdmissionProofContractDeclaration>(), SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static PayloadSchemaDeclaration GovernedSchema() => PayloadSchemaDeclaration.Create("protocol.governed-text", "1", Resolve("protocol.codec.governed-text"), SourceModel(), 200_000, 67_108_864, MarkdownBudget(), GovernedCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TargetSchema() => PayloadSchemaDeclaration.Create("protocol.repository-target-resolution", "1", Resolve("protocol.codec.repository-target-resolution"), TargetResolutionModel(), 1, 33_554_432, TargetSchemaBudget(), TargetCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TreeSchema() => PayloadSchemaDeclaration.Create("protocol.repository-tree", "1", Resolve("protocol.codec.repository-tree"), TreeModel(), 1, 16_777_216, TreeBudget(), TreeCodecFailures.Reverse());
    private static SemanticModelParserDeclaration MarkdownParser() => SemanticModelParserDeclaration.Create("protocol.parser.markdown", "1", Resolve("protocol.parser.markdown"), [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)], MarkdownModel(), MarkdownBudget(), MarkdownParserFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static SemanticModelParserDeclaration TargetParser() => SemanticModelParserDeclaration.Create("protocol.parser.repository-target-markdown", "1", Resolve("protocol.parser.repository-target-markdown"), [ComponentInputDeclaration.ForModel(TargetResolutionModel(), 1, 1)], TargetMarkdownModel(), TargetParserBudget(), TargetParserFailures.Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration GovernedIndex() => ContextIndexDeclaration.Create("protocol.index.governed-reference", "1", Resolve("protocol.index.governed-reference"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(RecordCapability(), 1, null), ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], GovernedCapability(), GovernedBudget(), GovernedIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration RecordIndex() => ContextIndexDeclaration.Create("protocol.index.protocol-record", "1", Resolve("protocol.index.protocol-record"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], RecordCapability(), GovernedBudget(), RecordFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TargetIndex() => ContextIndexDeclaration.Create("protocol.index.repository-target-resolution", "1", Resolve("protocol.index.repository-target-resolution"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(GovernedCapability(), 1, 1), ComponentInputDeclaration.ForModel(TargetResolutionModel(), 0, null), ComponentInputDeclaration.ForModel(TargetMarkdownModel(), 0, null)], TargetCapability(), TargetIndexBudget(), TargetIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TreeIndex() => ContextIndexDeclaration.Create("protocol.index.repository-tree", "1", Resolve("protocol.index.repository-tree"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)], TreeCapability(), TreeBudget(), TreeIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static RuleDeclaration CreateRule() => RuleDeclaration.Create(RuleId.Parse("RULE-0001"), RuleRevision.Create(1), CatalogVersion.Create(1), ExactSha256Digest.Parse(Digest), [NormativeFragmentDeclaration.Create("docs/rules/index-slot.md", Blob, "index-slot", 1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))], [TestScenarioId.Parse("TEST-0001")], Resolve("protocol.evaluator.test-rule"), Array.Empty<EvidenceSlotDeclaration>(), [TreeSlot(), TargetSlot(), RepositoryGovernedSlot(), ProviderGovernedSlot()], Array.Empty<ExpectedSelectorDeclaration>(), [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]), [SnapshotKind.ExactCommit], [ProtocolOperation.Conformance], Array.Empty<FindingDeclaration>(), Array.Empty<EvaluationFailureCode>(), "1.0.0", null, null, Array.Empty<string>());
    private static EvidenceSlotDeclaration ProviderGovernedSlot() => GovernedSlot("provider", SurfaceKind.Provider, [SurfaceKind.Provider]);
    private static EvidenceSlotDeclaration RepositoryGovernedSlot() => GovernedSlot("repository", SurfaceKind.Repository, [SurfaceKind.Provider, SurfaceKind.Repository]);
    private static EvidenceSlotDeclaration GovernedSlot(string scope, SurfaceKind surface, SurfaceKind[] profiles) => EvidenceSlotDeclaration.Create("protocol.slot." + scope + "-governed-text", EvidenceRequirement.Create("protocol.requirement." + scope + "-governed-text", surface, "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", "1", [EvidenceConsistencyClass.BoundedNonAtomicObservation, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create(profiles), "protocol.material.governed-text", "protocol.target." + scope + "-governed-body-set", [RecordCapability(), GovernedCapability()]);
    private static EvidenceSlotDeclaration TargetSlot() => EvidenceSlotDeclaration.Create("protocol.slot.repository-target-resolution", EvidenceRequirement.Create("protocol.requirement.repository-target-resolution", SurfaceKind.Repository, "protocol.evidence.repository-target-resolution-set", "protocol.completeness.all-projected-target-resolutions", "protocol.repository-target-resolution", "1", [EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create([SurfaceKind.Provider, SurfaceKind.Repository]), "protocol.material.repository-target-resolution", "protocol.target.repository-target-resolution-set", [TargetCapability()]);
    private static EvidenceSlotDeclaration TreeSlot() => EvidenceSlotDeclaration.Create("protocol.slot.repository-tree", EvidenceRequirement.Create("protocol.requirement.repository-tree", SurfaceKind.Repository, "protocol.evidence.repository-tree", "protocol.completeness.full-tree", "protocol.repository-tree", "1", [EvidenceConsistencyClass.BoundedNonAtomicObservation, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create([SurfaceKind.Repository]), "protocol.material.repository-tree", "protocol.target.repository-snapshot", [TreeCapability()]);
    private static ModelContractIdentity SourceModel() => Model("protocol.model.source-text", "protocol.type.model.source-text");
    private static ModelContractIdentity MarkdownModel() => Model("protocol.model.markdown-document", "protocol.type.model.markdown-document");
    private static ModelContractIdentity TargetMarkdownModel() => Model("protocol.model.repository-target-markdown-document-set", "protocol.type.model.repository-target-markdown-document-set");
    private static ModelContractIdentity TargetResolutionModel() => Model("protocol.model.repository-target-resolution", "protocol.type.model.repository-target-resolution");
    private static ModelContractIdentity TreeModel() => Model("protocol.model.repository-tree", "protocol.type.model.repository-tree");
    private static ModelContractIdentity Model(string key, string component) => ModelContractIdentity.Create(key, "1", Resolve(component));
    private static CapabilityContractIdentity GovernedCapability() => Capability("protocol.capability.governed-reference-index", "protocol.type.capability.governed-reference-index");
    private static CapabilityContractIdentity RecordCapability() => Capability("protocol.capability.protocol-record-index", "protocol.type.capability.protocol-record-index");
    private static CapabilityContractIdentity TargetCapability() => Capability("protocol.capability.repository-target-resolution-index", "protocol.type.capability.repository-target-resolution-index");
    private static CapabilityContractIdentity TreeCapability() => Capability("protocol.capability.repository-tree", "protocol.type.capability.repository-tree");
    private static CapabilityContractIdentity Capability(string key, string component) => CapabilityContractIdentity.Create(key, "1", Resolve(component));
    private static SemanticResourceBudget MarkdownBudget() => Budget(4_194_304, 256, 500_000, 5_000_000);
    private static SemanticResourceBudget GovernedBudget() => Budget(67_108_864, 256, 1_000_000, 10_000_000);
    private static SemanticResourceBudget TargetSchemaBudget() => Budget(33_554_432, 64, 500_000, 34_054_432);
    private static SemanticResourceBudget TargetParserBudget() => Budget(33_554_432, 256, 1_000_000, 34_554_432);
    private static SemanticResourceBudget TargetIndexBudget() => Budget(67_108_864, 256, 2_000_000, 20_000_000);
    private static SemanticResourceBudget TreeBudget() => Budget(16_777_216, 64, 200_000, 2_000_000);
    private static SemanticResourceBudget Budget(long bytes, int depth, long nodes, long complexity) => SemanticResourceBudget.Create(bytes, depth, nodes, complexity);
    private static ComponentTypeIdentity Resolve(string key) => ComponentTypeIdentity.Create(key, "1", Spec(key).Assembly, Spec(key).Type);
    private static (string Key, string Assembly, string Type, string Artifact) Spec(string key) => Components.Single(item => item.Key == key);
    private static ArtifactFileBinding Artifact(string name) => ArtifactFileBinding.Create(name, 1, ExactSha256Digest.Parse(Digest));

    private static void AssertSchema(PayloadSchemaDeclaration actual, string key, ModelContractIdentity model, int bindings, long retained, SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1", bindings, retained), (actual.SchemaKey, actual.SchemaVersion, actual.MaxBindingsPerInstruction, actual.MaxRetainedCanonicalBytesPerInstruction));
        AssertComponent(actual.Codec, key.Replace("protocol.", "protocol.codec.", StringComparison.Ordinal));
        AssertModel(actual.OutputModel, model);
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.CodecFailureCodes);
    }
    private static void AssertParser(SemanticModelParserDeclaration actual, string key, ModelContractIdentity output, SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1"), (actual.ParserKey, actual.ParserVersion));
        AssertComponent(actual.Parser, key);
        AssertModel(actual.OutputModel, output);
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.FailureCodes.Select(item => item.Value));
    }
    private static void AssertIndex(ContextIndexDeclaration actual, string key, IndexInvocationScope scope, CapabilityContractIdentity output, SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1", scope), (actual.IndexKey, actual.IndexVersion, actual.InvocationScope));
        AssertComponent(actual.Indexer, key);
        AssertCapability(actual.OutputCapability, output);
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.FailureCodes.Select(item => item.Value));
    }
    private static void AssertGovernedSlot(EvidenceSlotDeclaration slot, string scope, SurfaceKind surface, SurfaceKind[] profiles)
    {
        Assert.Equal(("protocol.slot." + scope + "-governed-text", "protocol.requirement." + scope + "-governed-text", surface), (slot.SlotKey, slot.Requirement.Key, slot.Requirement.Surface));
        Assert.Equal([EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.BoundedNonAtomicObservation], slot.Requirement.AcceptedConsistencyClasses);
        Assert.Equal(profiles, slot.ProfileSurfaces.Values);
        Assert.Equal([GovernedCapability(), RecordCapability()], slot.Capabilities);
    }
    private static void AssertTargetSlot(EvidenceSlotDeclaration slot)
    {
        Assert.Equal(("protocol.slot.repository-target-resolution", "protocol.requirement.repository-target-resolution", SurfaceKind.Repository), (slot.SlotKey, slot.Requirement.Key, slot.Requirement.Surface));
        Assert.Equal(("protocol.evidence.repository-target-resolution-set", "protocol.completeness.all-projected-target-resolutions", "protocol.repository-target-resolution", "1"), (slot.Requirement.Kind, slot.Requirement.CompletenessContract, slot.Requirement.PayloadSchemaKey, slot.Requirement.PayloadSchemaVersion));
        Assert.Equal([EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound], slot.Requirement.AcceptedConsistencyClasses);
        Assert.Equal([SurfaceKind.Repository, SurfaceKind.Provider], slot.ProfileSurfaces.Values);
        Assert.Equal(("protocol.material.repository-target-resolution", "protocol.target.repository-target-resolution-set"), (slot.MaterialRole, slot.TargetSelectorKey));
        Assert.Equal([TargetCapability()], slot.Capabilities);
    }
    private static void AssertTreeSlot(EvidenceSlotDeclaration slot)
    {
        Assert.Equal(("protocol.slot.repository-tree", "protocol.requirement.repository-tree", SurfaceKind.Repository), (slot.SlotKey, slot.Requirement.Key, slot.Requirement.Surface));
        Assert.Equal([TreeCapability()], slot.Capabilities);
    }
    private static void AssertModelInput(ComponentInputDeclaration actual, ModelContractIdentity model, int minimum, int? maximum) { AssertModel(Assert.IsType<ModelContractIdentity>(actual.Model), model); Assert.Null(actual.Capability); Assert.Equal((minimum, maximum), (actual.MinimumCount, actual.MaximumCount)); }
    private static void AssertCapabilityInput(ComponentInputDeclaration actual, CapabilityContractIdentity capability, int minimum, int? maximum) { Assert.Null(actual.Model); AssertCapability(Assert.IsType<CapabilityContractIdentity>(actual.Capability), capability); Assert.Equal((minimum, maximum), (actual.MinimumCount, actual.MaximumCount)); }
    private static void AssertModel(ModelContractIdentity actual, ModelContractIdentity expected) { Assert.Equal((expected.ModelKey, expected.ModelVersion), (actual.ModelKey, actual.ModelVersion)); AssertComponent(actual.ImplementationType, expected.ImplementationType.ComponentKey); }
    private static void AssertCapability(CapabilityContractIdentity actual, CapabilityContractIdentity expected) { Assert.Equal((expected.CapabilityKey, expected.CapabilityVersion), (actual.CapabilityKey, actual.CapabilityVersion)); AssertComponent(actual.InterfaceType, expected.InterfaceType.ComponentKey); }
    private static void AssertComponent(ComponentTypeIdentity actual, string key) { var expected = Spec(key); Assert.Equal((key, "1", expected.Assembly, expected.Type), (actual.ComponentKey, actual.ComponentVersion, actual.AssemblyName, actual.TypeName)); }
    private static void AssertBudget(SemanticResourceBudget actual, SemanticResourceBudget expected) => Assert.Equal((expected.MaxBytes, expected.MaxDepth, expected.MaxNodes, expected.MaxComplexity), (actual.MaxBytes, actual.MaxDepth, actual.MaxNodes, actual.MaxComplexity));
    private static void AssertOrder(JsonElement element, params string[] names) => Assert.Equal(names, element.EnumerateObject().Select(property => property.Name));
    private static string ComponentKey(JsonElement binding) => binding.GetProperty("component").GetProperty("componentKey").GetString()!;
    private static void RejectNested(string document, string outer, string inner, params (string Old, string New)[] mutations) => Array.ForEach(mutations, mutation => Reject(document, outer, ReplaceRequired(outer, inner, ReplaceRequired(inner, mutation.Old, mutation.New))));
    private static void RejectInside(string document, string container, params (string Old, string New)[] mutations) => Array.ForEach(mutations, mutation => Reject(document, container, ReplaceRequired(container, mutation.Old, mutation.New)));
    private static void RejectMany(string document, string oldText, params string[] replacements) => Array.ForEach(replacements, replacement => AssertPublicFormatException(ReplaceRequired(document, oldText, replacement)));
    private static void RejectRemove(string document, string item) => AssertPublicFormatException(RemoveItem(document, item));
    private static void Reject(string document, string oldText, string newText) => AssertPublicFormatException(ReplaceRequired(document, oldText, newText));
    private static string RemoveItem(string document, string item) { var marker = document.Contains(item + ",", StringComparison.Ordinal) ? item + "," : "," + item; return ReplaceRequired(document, marker, string.Empty); }
    private static string ReplaceRequired(string value, string oldText, string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (oldText.Length == 0 || index < 0 || value.IndexOf(oldText, index + oldText.Length, StringComparison.Ordinal) >= 0 || string.Equals(oldText, newText, StringComparison.Ordinal)) throw new InvalidOperationException($"Required mutation marker was invalid or absent: {oldText}");
        return value.Remove(index, oldText.Length).Insert(index, newText);
    }
    private static void AssertAccepted(string manifest) { var bytes = Encoding.UTF8.GetBytes(manifest); var parsed = FinalizedPolicyManifest.ParseCanonical(bytes); Assert.Equal(bytes, CanonicalManifestWriter.Write(parsed)); }
    private static void AssertPublicFormatException(string manifest) => Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(Encoding.UTF8.GetBytes(manifest)));
}
