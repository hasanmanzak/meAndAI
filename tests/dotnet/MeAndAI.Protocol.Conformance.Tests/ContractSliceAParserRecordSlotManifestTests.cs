using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAParserRecordSlotManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private static readonly string[] GovernedFailures = ["protocol.codec.embedded-identity-mismatch",
        "protocol.codec.invalid-utf8", "protocol.codec.noncanonical-encoding",
        "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TreeFailures = ["protocol.codec.embedded-identity-mismatch",
        "protocol.codec.invalid-repository-tree", "protocol.codec.payload-location-mismatch",
        "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] ParserFailures = ["protocol.budget.exhausted", "protocol.model.invalid-markdown"];
    private static readonly string[] RecordFailures = ["protocol.budget.exhausted", "protocol.index.record-unavailable"];
    private static readonly string[] TreeIndexFailures = ["protocol.budget.exhausted", "protocol.index.repository-tree-unavailable"];
    private static readonly (string Key, string Assembly, string Type, string Artifact)[] Components =
    [
        ("protocol.activation-proof.test", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof", "ContractSliceA.Proof.dll"),
        ("protocol.codec.governed-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.codec.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.evaluator.test-rule", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAIndexSlotEvaluator", "ContractSliceA.Proof.dll"),
        ("protocol.index.protocol-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.index.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.parser.markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.capability.protocol-record-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.repository-tree", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.model.markdown-document", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.source-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.SourceTextModel", "MeAndAI.Protocol.Policy.dll"),
    ];
    private static readonly string[] NewComponents = ["protocol.codec.governed-text",
        "protocol.index.protocol-record", "protocol.parser.markdown",
        "protocol.type.capability.protocol-record-index", "protocol.type.model.markdown-document",
        "protocol.type.model.source-text"];
    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_markdown_parser_protocol_record_index_and_slot_capability_closure()
    {
        var source = CreateManifest();
        var bytes = CanonicalManifestWriter.Write(source);
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        AssertGraph(manifest);
        Assert.ThrowsAny<ArgumentException>(() => ComponentInputDeclaration.ForModel(SourceModel(), 0, 0));
        Assert.ThrowsAny<ArgumentException>(() => ComponentInputDeclaration.ForCapability(RecordCapability(), 0, 0));
        AssertWire(bytes);
    }
    private static void AssertGraph(FinalizedPolicyManifest manifest)
    {
        var registry = manifest.SchemaRegistry;
        Assert.Equal(["protocol.governed-text", "protocol.repository-tree"], registry.PayloadSchemas.Select(item => item.SchemaKey));
        Assert.Equal(["protocol.parser.markdown"], registry.Parsers.Select(item => item.ParserKey));
        Assert.Equal(["protocol.index.protocol-record", "protocol.index.repository-tree"], registry.Indexes.Select(item => item.IndexKey));
        Assert.Empty(registry.DemandProjectors);
        Assert.Empty(registry.AdmissionProofContracts);
        AssertSchema(registry.PayloadSchemas[0], "protocol.governed-text", "protocol.codec.governed-text", SourceModel(), 200_000, 67_108_864, ParserBudget(), GovernedFailures);
        AssertSchema(registry.PayloadSchemas[1], "protocol.repository-tree", "protocol.codec.repository-tree", TreeModel(), 1, 16_777_216, TreeBudget(), TreeFailures);
        Assert.True(registry.TryGetPayloadSchema("protocol.governed-text", "1", out var schema));
        Assert.Same(registry.PayloadSchemas[0], schema);
        Assert.False(registry.TryGetPayloadSchema("protocol.missing", "1", out _));
        var parser = Assert.Single(registry.Parsers);
        Assert.Equal(("protocol.parser.markdown", "1"), (parser.ParserKey, parser.ParserVersion));
        AssertComponent(parser.Parser, "protocol.parser.markdown");
        AssertInput(Assert.Single(parser.Inputs), SourceModel(), 1, 1);
        AssertModel(parser.OutputModel, MarkdownModel());
        AssertBudget(parser.Budget, ParserBudget());
        Assert.Equal(ParserFailures, parser.FailureCodes.Select(item => item.Value));
        Assert.True(registry.TryGetParser("protocol.parser.markdown", "1", out var resolvedParser));
        Assert.Same(parser, resolvedParser);
        Assert.False(registry.TryGetParser("protocol.parser.missing", "1", out _));
        var record = registry.Indexes[0];
        AssertIndex(record, "protocol.index.protocol-record", MarkdownModel(), 0, null, RecordCapability(), RecordBudget(), RecordFailures);
        var tree = registry.Indexes[1];
        AssertIndex(tree, "protocol.index.repository-tree", TreeModel(), 1, 1, TreeCapability(), TreeBudget(), TreeIndexFailures);
        Assert.True(registry.TryGetIndex("protocol.index.protocol-record", "1", out var resolvedIndex));
        Assert.Same(record, resolvedIndex);
        Assert.False(registry.TryGetIndex("protocol.index.missing", "1", out _));
        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        Assert.Empty(rule.ApplicabilitySlots);
        Assert.Equal(["protocol.slot.repository-governed-text", "protocol.slot.repository-tree"], rule.EvaluationSlots.Select(item => item.SlotKey));
        AssertSlot(rule.EvaluationSlots[0], "protocol.slot.repository-governed-text", "protocol.requirement.repository-governed-text",
            "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text",
            [SurfaceKind.Repository, SurfaceKind.Provider], "protocol.material.governed-text", "protocol.target.repository-governed-body-set", RecordCapability());
        AssertSlot(rule.EvaluationSlots[1], "protocol.slot.repository-tree", "protocol.requirement.repository-tree",
            "protocol.evidence.repository-tree", "protocol.completeness.full-tree", "protocol.repository-tree",
            [SurfaceKind.Repository], "protocol.material.repository-tree", "protocol.target.repository-snapshot", TreeCapability());
        var cache = registry.CacheBudget;
        Assert.Equal((512, 67_108_864L, 128, 2_000_000L, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys),
            (cache.MaxDecodeEntries, cache.MaxDecodeCanonicalBytes, cache.MaxIndexEntries, cache.MaxIndexNodes,
                cache.MaxConcurrentDecodeAttempts, cache.MaxConcurrentIndexAttempts, cache.RetentionPolicy));
        Assert.Equal(["ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll"], manifest.ArtifactFiles.Select(item => item.FileName));
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.All(manifest.Components, binding =>
        {
            Assert.Equal(Spec(binding.Component.ComponentKey).Artifact, binding.ArtifactFileName);
            Assert.Contains(manifest.ArtifactFiles, artifact => artifact.FileName == binding.ArtifactFileName);
        });
    }
    private static void AssertWire(byte[] bytes)
    {
        using var document = JsonDocument.Parse(bytes);
        var root = document.RootElement;
        var registry = root.GetProperty("schemaRegistry");
        var schemas = registry.GetProperty("payloadSchemas").EnumerateArray().ToArray();
        var parser = registry.GetProperty("parsers").EnumerateArray().Single();
        var indexes = registry.GetProperty("indexes").EnumerateArray().ToArray();
        var record = indexes[0];
        var parserInput = parser.GetProperty("inputs").EnumerateArray().Single();
        var recordInput = record.GetProperty("inputs").EnumerateArray().Single();
        var slots = root.GetProperty("slice").GetProperty("rules").EnumerateArray().Single()
            .GetProperty("evaluationSlots").EnumerateArray().ToArray();
        var cache = registry.GetProperty("cacheBudget");
        AssertOrder(parser, "parserKey", "parserVersion", "parser", "inputs", "outputModel", "budget", "failureCodes");
        AssertOrder(parserInput, "kind", "model", "minimumCount", "maximumCount");
        AssertOrder(record, "indexKey", "indexVersion", "indexer", "invocationScope",
            "inputs", "outputCapability", "budget", "failureCodes");
        AssertOrder(recordInput, "kind", "model", "minimumCount");
        AssertOrder(slots[0], "slotKey", "requirement", "profileSurfaces", "materialRole",
            "targetSelectorKey", "capabilities");
        AssertOrder(cache, "maxDecodeEntries", "maxDecodeCanonicalBytes", "maxIndexEntries",
            "maxIndexNodes", "maxConcurrentDecodeAttempts", "maxConcurrentIndexAttempts", "retentionPolicy");
        var text = Encoding.UTF8.GetString(bytes);
        var governed = schemas[0].GetRawText();
        var treeSchema = schemas[1].GetRawText();
        var parserText = parser.GetRawText();
        var parserInputText = parserInput.GetRawText();
        var recordText = record.GetRawText();
        var recordInputText = recordInput.GetRawText();
        var governedSlot = slots[0].GetRawText();
        var treeSlot = slots[1].GetRawText();
        RejectInside(text, governed,
            ("\"componentKey\":\"protocol.codec.governed-text\"", "\"componentKey\":\"protocol.codec.missing\""),
            ("\"componentKey\":\"protocol.type.model.source-text\"", "\"componentKey\":\"protocol.type.model.missing\""),
            ("\"maxBindingsPerInstruction\":200000", "\"maxBindingsPerInstruction\":1"),
            ("\"maxBytes\":4194304", "\"maxBytes\":1"),
            ("\"protocol.codec.embedded-identity-mismatch\",\"protocol.codec.invalid-utf8\"",
                "\"protocol.codec.invalid-utf8\",\"protocol.codec.embedded-identity-mismatch\""));
        var schemaArray = "\"payloadSchemas\":[" + governed + "," + treeSchema + "]";
        RejectMany(text, schemaArray, "\"payloadSchemas\":[" + treeSchema + "," + governed + "]",
            "\"payloadSchemas\":[" + governed + "," + governed + "," + treeSchema + "]");
        RejectInside(text, parserText,
            ("\"parserVersion\":\"1\"", "\"parserVersion\":\"2\""),
            ("\"maxBytes\":4194304", "\"maxBytes\":1"),
            ("\"protocol.budget.exhausted\",\"protocol.model.invalid-markdown\"",
                "\"protocol.model.invalid-markdown\",\"protocol.budget.exhausted\""));
        RejectNested(text, parserText, parserInputText,
            ("\"kind\":\"model\"", "\"kind\":\"capability\""),
            ("\"minimumCount\":1", "\"minimumCount\":0"),
            (",\"maximumCount\":1", string.Empty),
            ("\"maximumCount\":1", "\"maximumCount\":null"),
            ("protocol.model.source-text", "protocol.model.source-text-missing"));
        var parserArray = "\"parsers\":[" + parserText + "]";
        RejectMany(text, parserArray, "\"parsers\":null", "\"parsers\":[]",
            "\"parsers\":[" + parserText + "," + parserText + "]",
            "\"parsers\":[" + ReplaceRequired(parserText,
                "\"parserKey\":\"protocol.parser.markdown\"",
                "\"parserKey\":\"protocol.parser.repository-target-markdown\"") + "]");
        RejectInside(text, recordText,
            ("\"invocationScope\":\"per-context\"", "\"invocationScope\":\"per-plan\""),
            ("\"maxBytes\":67108864", "\"maxBytes\":1"),
            ("\"protocol.budget.exhausted\",\"protocol.index.record-unavailable\"",
                "\"protocol.index.record-unavailable\",\"protocol.budget.exhausted\""));
        RejectNested(text, recordText, recordInputText,
            ("\"minimumCount\":0", "\"minimumCount\":1"),
            ("\"minimumCount\":0", "\"minimumCount\":0,\"maximumCount\":null"),
            ("\"minimumCount\":0", "\"minimumCount\":0,\"maximumCount\":1"),
            ("protocol.model.markdown-document", "protocol.model.markdown-document-missing"));
        foreach (var held in new[] { "protocol.index.governed-reference", "protocol.index.repository-target-resolution" })
        {
            RejectMany(text, "\"indexes\":[" + recordText + "," + indexes[1].GetRawText() + "]",
                "\"indexes\":[" + ReplaceRequired(recordText,
                    "\"indexKey\":\"protocol.index.protocol-record\"",
                    "\"indexKey\":\"" + held + "\"") + "," + indexes[1].GetRawText() + "]");
        }
        RejectInside(text, governedSlot,
            ("\"profileSurfaces\":[\"repository\",\"provider\"]", "\"profileSurfaces\":[\"repository\"]"),
            ("\"targetSelectorKey\":\"protocol.target.repository-governed-body-set\"",
                "\"targetSelectorKey\":\"protocol.target.repository-snapshot\""),
            ("protocol.capability.protocol-record-index", "protocol.capability.governed-reference-index"));
        var slotArray = "\"evaluationSlots\":[" + governedSlot + "," + treeSlot + "]";
        RejectMany(text, slotArray, "\"evaluationSlots\":[" + treeSlot + "," + governedSlot + "]",
            "\"evaluationSlots\":[" + governedSlot + "," + governedSlot + "," + treeSlot + "]",
            "\"evaluationSlots\":[" + ReplaceRequired(governedSlot,
                "protocol.slot.repository-governed-text", "protocol.slot.provider-governed-text") + "," + treeSlot + "]",
            "\"evaluationSlots\":[" + ReplaceRequired(governedSlot,
                "protocol.slot.repository-governed-text", "protocol.slot.repository-target-resolution") + "," + treeSlot + "]");
        RejectInside(text, cache.GetRawText(),
            ("\"maxDecodeEntries\":512", "\"maxDecodeEntries\":1"),
            ("\"maxDecodeCanonicalBytes\":67108864", "\"maxDecodeCanonicalBytes\":1"),
            ("\"maxIndexEntries\":128", "\"maxIndexEntries\":1"),
            ("\"maxIndexNodes\":2000000", "\"maxIndexNodes\":1"),
            ("\"maxConcurrentDecodeAttempts\":8", "\"maxConcurrentDecodeAttempts\":1"),
            ("\"maxConcurrentIndexAttempts\":4", "\"maxConcurrentIndexAttempts\":1"),
            ("\"retentionPolicy\":\"retain-lowest-canonical-keys\"", "\"retentionPolicy\":\"unknown\""));
        var bindings = root.GetProperty("components").EnumerateArray().ToArray();
        foreach (var key in NewComponents)
        {
            var binding = bindings.Single(item => ComponentKey(item) == key).GetRawText();
            RejectRemove(text, binding);
            RejectInside(text, binding,
                ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""),
                ("\"typeName\":\"" + Spec(key).Type + "\"", "\"typeName\":\"Wrong.Type\""),
                ("\"artifactFileName\":\"" + Spec(key).Artifact + "\"", "\"artifactFileName\":\"Missing.dll\""));
        }
        var artifacts = root.GetProperty("artifactFiles").EnumerateArray().Select(item => item.GetRawText()).ToArray();
        var artifactArray = "\"artifactFiles\":[" + string.Join(",", artifacts) + "]";
        var unused = ReplaceRequired(artifacts[^1], "MeAndAI.Protocol.Policy.dll", "Unused.dll");
        RejectMany(text, artifactArray, "\"artifactFiles\":[" + string.Join(",", artifacts) + "," + unused + "]");
    }
    private static ParsedCanonicalManifest CreateManifest() => new(CatalogAuthorityKind.QualificationSlice, Commit,
        CreateRegistry(), ActivationProofContractDeclaration.Create("protocol.activation-proof.test", "1.0.0", Resolve("protocol.activation-proof.test")),
        [Artifact("ContractSliceA.Proof.dll"), Artifact("MeAndAI.Protocol.Conformance.Abstractions.dll"), Artifact("MeAndAI.Protocol.Policy.dll")],
        Components.Select(item => ComponentArtifactBinding.Create(Resolve(item.Key), item.Artifact)).ToArray(),
        CatalogSliceDeclaration.Create("protocol.catalog-slice.index-slot", "1", "0.0.0", CatalogVersion.Create(1), [CreateRule()]));
    private static ReleaseSchemaRegistry CreateRegistry() => ReleaseSchemaRegistry.Create([TreeSchema(), GovernedSchema()],
        [MarkdownParser()], [TreeIndex(), RecordIndex()], Array.Empty<AcquisitionDemandProjectorDeclaration>(),
        Array.Empty<AdmissionProofContractDeclaration>(), SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static PayloadSchemaDeclaration GovernedSchema() => PayloadSchemaDeclaration.Create("protocol.governed-text", "1",
        Resolve("protocol.codec.governed-text"), SourceModel(), 200_000, 67_108_864, ParserBudget(), GovernedFailures.Reverse());
    private static PayloadSchemaDeclaration TreeSchema() => PayloadSchemaDeclaration.Create("protocol.repository-tree", "1",
        Resolve("protocol.codec.repository-tree"), TreeModel(), 1, 16_777_216, TreeBudget(), TreeFailures.Reverse());
    private static SemanticModelParserDeclaration MarkdownParser() => SemanticModelParserDeclaration.Create("protocol.parser.markdown", "1",
        Resolve("protocol.parser.markdown"), [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)], MarkdownModel(), ParserBudget(), ParserFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration RecordIndex() => ContextIndexDeclaration.Create("protocol.index.protocol-record", "1",
        Resolve("protocol.index.protocol-record"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], RecordCapability(), RecordBudget(), RecordFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TreeIndex() => ContextIndexDeclaration.Create("protocol.index.repository-tree", "1",
        Resolve("protocol.index.repository-tree"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)], TreeCapability(), TreeBudget(), TreeIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static RuleDeclaration CreateRule() => RuleDeclaration.Create(RuleId.Parse("RULE-0001"), RuleRevision.Create(1),
        CatalogVersion.Create(1), ExactSha256Digest.Parse(Digest), [NormativeFragmentDeclaration.Create("docs/rules/index-slot.md", Blob,
            "index-slot", 1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))],
        [TestScenarioId.Parse("TEST-0001")], Resolve("protocol.evaluator.test-rule"), Array.Empty<EvidenceSlotDeclaration>(),
        [TreeSlot(), GovernedSlot()], Array.Empty<ExpectedSelectorDeclaration>(), [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]),
        [SnapshotKind.ExactCommit], [ProtocolOperation.Conformance], Array.Empty<FindingDeclaration>(), Array.Empty<EvaluationFailureCode>(),
        "1.0.0", null, null, Array.Empty<string>());
    private static EvidenceSlotDeclaration GovernedSlot() => Slot("protocol.slot.repository-governed-text",
        "protocol.requirement.repository-governed-text", "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies",
        "protocol.governed-text", [SurfaceKind.Provider, SurfaceKind.Repository], "protocol.material.governed-text", "protocol.target.repository-governed-body-set", RecordCapability());
    private static EvidenceSlotDeclaration TreeSlot() => Slot("protocol.slot.repository-tree", "protocol.requirement.repository-tree",
        "protocol.evidence.repository-tree", "protocol.completeness.full-tree", "protocol.repository-tree", [SurfaceKind.Repository],
        "protocol.material.repository-tree", "protocol.target.repository-snapshot", TreeCapability());
    private static EvidenceSlotDeclaration Slot(string key, string requirement, string kind, string completeness, string schema,
        SurfaceKind[] surfaces, string material, string target, CapabilityContractIdentity capability) => EvidenceSlotDeclaration.Create(key,
        EvidenceRequirement.Create(requirement, SurfaceKind.Repository, kind, completeness, schema, "1", [EvidenceConsistencyClass.BoundedNonAtomicObservation,
            EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create(surfaces), material, target, [capability]);
    private static ModelContractIdentity SourceModel() => Model("protocol.model.source-text", "protocol.type.model.source-text");
    private static ModelContractIdentity MarkdownModel() => Model("protocol.model.markdown-document", "protocol.type.model.markdown-document");
    private static ModelContractIdentity TreeModel() => Model("protocol.model.repository-tree", "protocol.type.model.repository-tree");
    private static ModelContractIdentity Model(string key, string component) => ModelContractIdentity.Create(key, "1", Resolve(component));
    private static CapabilityContractIdentity RecordCapability() => Capability("protocol.capability.protocol-record-index", "protocol.type.capability.protocol-record-index");
    private static CapabilityContractIdentity TreeCapability() => Capability("protocol.capability.repository-tree", "protocol.type.capability.repository-tree");
    private static CapabilityContractIdentity Capability(string key, string component) => CapabilityContractIdentity.Create(key, "1", Resolve(component));
    private static SemanticResourceBudget ParserBudget() => Budget(4_194_304, 256, 500_000, 5_000_000);
    private static SemanticResourceBudget RecordBudget() => Budget(67_108_864, 256, 1_000_000, 10_000_000);
    private static SemanticResourceBudget TreeBudget() => Budget(16_777_216, 64, 200_000, 2_000_000);
    private static SemanticResourceBudget Budget(long bytes, int depth, long nodes, long complexity) => SemanticResourceBudget.Create(bytes, depth, nodes, complexity);
    private static ComponentTypeIdentity Resolve(string key) => ComponentTypeIdentity.Create(key, "1", Spec(key).Assembly, Spec(key).Type);
    private static (string Key, string Assembly, string Type, string Artifact) Spec(string key) => Components.Single(item => item.Key == key);
    private static ArtifactFileBinding Artifact(string name) => ArtifactFileBinding.Create(name, 1, ExactSha256Digest.Parse(Digest));
    private static void AssertSchema(PayloadSchemaDeclaration actual, string key, string codec,
        ModelContractIdentity model, int bindings, long retained, SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1"), (actual.SchemaKey, actual.SchemaVersion));
        AssertComponent(actual.Codec, codec);
        AssertModel(actual.OutputModel, model);
        Assert.Equal((bindings, retained), (actual.MaxBindingsPerInstruction, actual.MaxRetainedCanonicalBytesPerInstruction));
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.CodecFailureCodes);
    }
    private static void AssertIndex(ContextIndexDeclaration actual, string key, ModelContractIdentity model,
        int minimum, int? maximum, CapabilityContractIdentity capability, SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1"), (actual.IndexKey, actual.IndexVersion));
        AssertComponent(actual.Indexer, key);
        Assert.Equal(IndexInvocationScope.PerContext, actual.InvocationScope);
        AssertInput(Assert.Single(actual.Inputs), model, minimum, maximum);
        AssertCapability(actual.OutputCapability, capability);
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.FailureCodes.Select(item => item.Value));
    }
    private static void AssertSlot(EvidenceSlotDeclaration actual, string key, string requirement, string kind,
        string completeness, string schema, SurfaceKind[] surfaces, string material, string target, CapabilityContractIdentity capability)
    {
        Assert.Equal(key, actual.SlotKey);
        Assert.Equal((requirement, SurfaceKind.Repository, kind, completeness, schema, "1"),
            (actual.Requirement.Key, actual.Requirement.Surface, actual.Requirement.Kind, actual.Requirement.CompletenessContract,
                actual.Requirement.PayloadSchemaKey, actual.Requirement.PayloadSchemaVersion));
        Assert.Equal([EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound,
            EvidenceConsistencyClass.BoundedNonAtomicObservation], actual.Requirement.AcceptedConsistencyClasses);
        Assert.Equal(surfaces, actual.ProfileSurfaces.Values);
        Assert.Equal((material, target), (actual.MaterialRole, actual.TargetSelectorKey));
        AssertCapability(Assert.Single(actual.Capabilities), capability);
    }
    private static void AssertInput(ComponentInputDeclaration actual, ModelContractIdentity model, int minimum, int? maximum)
    {
        AssertModel(Assert.IsType<ModelContractIdentity>(actual.Model), model);
        Assert.Null(actual.Capability);
        Assert.Equal((minimum, maximum), (actual.MinimumCount, actual.MaximumCount));
    }
    private static void AssertModel(ModelContractIdentity actual, ModelContractIdentity expected)
    {
        Assert.Equal((expected.ModelKey, expected.ModelVersion), (actual.ModelKey, actual.ModelVersion));
        AssertComponent(actual.ImplementationType, expected.ImplementationType.ComponentKey);
    }
    private static void AssertCapability(CapabilityContractIdentity actual, CapabilityContractIdentity expected)
    {
        Assert.Equal((expected.CapabilityKey, expected.CapabilityVersion), (actual.CapabilityKey, actual.CapabilityVersion));
        AssertComponent(actual.InterfaceType, expected.InterfaceType.ComponentKey);
    }
    private static void AssertComponent(ComponentTypeIdentity actual, string key)
    {
        var expected = Spec(key);
        Assert.Equal((key, "1", expected.Assembly, expected.Type),
            (actual.ComponentKey, actual.ComponentVersion, actual.AssemblyName, actual.TypeName));
    }
    private static void AssertBudget(SemanticResourceBudget actual, SemanticResourceBudget expected) =>
        Assert.Equal((expected.MaxBytes, expected.MaxDepth, expected.MaxNodes, expected.MaxComplexity),
            (actual.MaxBytes, actual.MaxDepth, actual.MaxNodes, actual.MaxComplexity));
    private static void AssertOrder(JsonElement element, params string[] names) =>
        Assert.Equal(names, element.EnumerateObject().Select(property => property.Name));
    private static string ComponentKey(JsonElement binding) =>
        binding.GetProperty("component").GetProperty("componentKey").GetString()!;
    private static void RejectNested(string document, string outer, string inner, params (string Old, string New)[] mutations)
    {
        foreach (var mutation in mutations)
            Reject(document, outer, ReplaceRequired(outer, inner,
                ReplaceRequired(inner, mutation.Old, mutation.New)));
    }
    private static void RejectInside(string document, string container, params (string Old, string New)[] mutations)
    {
        foreach (var mutation in mutations)
            Reject(document, container, ReplaceRequired(container, mutation.Old, mutation.New));
    }
    private static void RejectMany(string document, string oldText, params string[] replacements)
    {
        foreach (var replacement in replacements)
            AssertPublicFormatException(ReplaceRequired(document, oldText, replacement));
    }
    private static void RejectRemove(string document, string item)
    {
        var marker = document.Contains(item + ",", StringComparison.Ordinal) ? item + "," : "," + item;
        AssertPublicFormatException(ReplaceRequired(document, marker, string.Empty));
    }
    private static void Reject(string document, string oldText, string newText) =>
        AssertPublicFormatException(ReplaceRequired(document, oldText, newText));
    private static string ReplaceRequired(string value, string oldText, string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (oldText.Length == 0 || index < 0 ||
            value.IndexOf(oldText, index + oldText.Length, StringComparison.Ordinal) >= 0 ||
            string.Equals(oldText, newText, StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Required mutation marker was invalid or absent: {oldText}");
        }
        return value.Remove(index, oldText.Length).Insert(index, newText);
    }
    private static void AssertPublicFormatException(string manifest) =>
        Assert.Throws<FormatException>(() =>
            FinalizedPolicyManifest.ParseCanonical(Encoding.UTF8.GetBytes(manifest)));
}
