using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAGovernedReferenceSlotsManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private static readonly string[] ParserFailures = ["protocol.budget.exhausted", "protocol.model.invalid-markdown"];
    private static readonly string[] GovernedIndexFailures = ["protocol.budget.exhausted", "protocol.index.reference-unavailable"];
    private static readonly string[] RecordFailures = ["protocol.budget.exhausted", "protocol.index.record-unavailable"];
    private static readonly string[] TreeIndexFailures = ["protocol.budget.exhausted", "protocol.index.repository-tree-unavailable"];
    private static readonly string[] GovernedCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-utf8", "protocol.codec.noncanonical-encoding", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TreeCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-tree", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly (string Key, string Assembly, string Type, string Artifact)[] Components =
    [
        ("protocol.activation-proof.test", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof", "ContractSliceA.Proof.dll"), ("protocol.codec.governed-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.codec.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec", "MeAndAI.Protocol.Policy.dll"), ("protocol.evaluator.test-rule", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAIndexSlotEvaluator", "ContractSliceA.Proof.dll"),
        ("protocol.index.governed-reference", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex", "MeAndAI.Protocol.Policy.dll"), ("protocol.index.protocol-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.index.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex", "MeAndAI.Protocol.Policy.dll"), ("protocol.parser.markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.capability.governed-reference-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"), ("protocol.type.capability.protocol-record-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.repository-tree", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree", "MeAndAI.Protocol.Conformance.Abstractions.dll"), ("protocol.type.model.markdown-document", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel", "MeAndAI.Protocol.Policy.dll"), ("protocol.type.model.source-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.SourceTextModel", "MeAndAI.Protocol.Policy.dll"),
    ];
    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_governed_reference_index_and_dual_governed_text_slot_capability_closure()
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
        Assert.ThrowsAny<ArgumentException>(() => ComponentInputDeclaration.ForModel(MarkdownModel(), 0, 0));
        Assert.ThrowsAny<ArgumentException>(() => ComponentInputDeclaration.ForCapability(RecordCapability(), 0, 0));
        AssertWire(bytes);
    }
    private static void AssertGraph(FinalizedPolicyManifest manifest)
    {
        var registry = manifest.SchemaRegistry;
        Assert.Equal(["protocol.governed-text", "protocol.repository-tree"], registry.PayloadSchemas.Select(item => item.SchemaKey));
        Assert.Equal(["protocol.parser.markdown"], registry.Parsers.Select(item => item.ParserKey));
        Assert.Equal(["protocol.index.governed-reference", "protocol.index.protocol-record", "protocol.index.repository-tree"], registry.Indexes.Select(item => item.IndexKey));
        Assert.Empty(registry.DemandProjectors);
        Assert.Empty(registry.AdmissionProofContracts);
        AssertSchema(registry.PayloadSchemas[0], "protocol.governed-text", SourceModel(), 200_000, 67_108_864, ParserBudget(), GovernedCodecFailures);
        AssertSchema(registry.PayloadSchemas[1], "protocol.repository-tree", TreeModel(), 1, 16_777_216, TreeBudget(), TreeCodecFailures);
        var parser = Assert.Single(registry.Parsers);
        Assert.Equal(("protocol.parser.markdown", "1"), (parser.ParserKey, parser.ParserVersion));
        AssertComponent(parser.Parser, "protocol.parser.markdown");
        AssertModelInput(Assert.Single(parser.Inputs), SourceModel(), 1, 1);
        AssertModel(parser.OutputModel, MarkdownModel());
        AssertBudget(parser.Budget, ParserBudget());
        Assert.Equal(ParserFailures, parser.FailureCodes.Select(item => item.Value));
        var governed = registry.Indexes[0];
        AssertIndex(governed, "protocol.index.governed-reference", IndexInvocationScope.PerPlan, GovernedCapability(), GovernedBudget(), GovernedIndexFailures);
        Assert.Equal(2, governed.Inputs.Count);
        AssertModelInput(governed.Inputs[0], MarkdownModel(), 0, null);
        AssertCapabilityInput(governed.Inputs[1], RecordCapability(), 1, null);
        AssertIndex(registry.Indexes[1], "protocol.index.protocol-record", IndexInvocationScope.PerContext, RecordCapability(), RecordBudget(), RecordFailures);
        AssertModelInput(Assert.Single(registry.Indexes[1].Inputs), MarkdownModel(), 0, null);
        AssertIndex(registry.Indexes[2], "protocol.index.repository-tree", IndexInvocationScope.PerContext, TreeCapability(), TreeBudget(), TreeIndexFailures);
        AssertModelInput(Assert.Single(registry.Indexes[2].Inputs), TreeModel(), 1, 1);
        Assert.True(registry.TryGetIndex("protocol.index.governed-reference", "1", out var resolved));
        Assert.Same(governed, resolved);
        Assert.False(registry.TryGetIndex("protocol.index.missing", "1", out _));
        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        Assert.Empty(rule.ApplicabilitySlots);
        var slots = rule.EvaluationSlots;
        Assert.Equal(["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text", "protocol.slot.repository-tree"], slots.Select(item => item.SlotKey));
        AssertSlot(slots[0], "protocol.slot.provider-governed-text", "protocol.requirement.provider-governed-text", SurfaceKind.Provider,
            [SurfaceKind.Provider], "protocol.target.provider-governed-body-set", [GovernedCapability(), RecordCapability()]);
        AssertSlot(slots[1], "protocol.slot.repository-governed-text", "protocol.requirement.repository-governed-text", SurfaceKind.Repository,
            [SurfaceKind.Repository, SurfaceKind.Provider], "protocol.target.repository-governed-body-set", [GovernedCapability(), RecordCapability()]);
        AssertSlot(slots[2], "protocol.slot.repository-tree", "protocol.requirement.repository-tree", SurfaceKind.Repository,
            [SurfaceKind.Repository], "protocol.target.repository-snapshot", [TreeCapability()], tree: true);
        Assert.Equal((512, 67_108_864L, 128, 2_000_000L, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys), (registry.CacheBudget.MaxDecodeEntries,
            registry.CacheBudget.MaxDecodeCanonicalBytes, registry.CacheBudget.MaxIndexEntries, registry.CacheBudget.MaxIndexNodes,
            registry.CacheBudget.MaxConcurrentDecodeAttempts, registry.CacheBudget.MaxConcurrentIndexAttempts, registry.CacheBudget.RetentionPolicy));
        Assert.Equal(["ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll"], manifest.ArtifactFiles.Select(item => item.FileName));
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.All(manifest.Components, binding => Assert.Equal(Spec(binding.Component.ComponentKey).Artifact, binding.ArtifactFileName));
    }
    private static void AssertWire(byte[] bytes)
    {
        using var document = JsonDocument.Parse(bytes);
        var root = document.RootElement;
        var registry = root.GetProperty("schemaRegistry");
        var parser = registry.GetProperty("parsers").EnumerateArray().Single();
        var indexes = registry.GetProperty("indexes").EnumerateArray().ToArray();
        var governed = indexes[0];
        var inputs = governed.GetProperty("inputs").EnumerateArray().ToArray();
        var output = governed.GetProperty("outputCapability");
        var budget = governed.GetProperty("budget");
        var slots = root.GetProperty("slice").GetProperty("rules").EnumerateArray().Single().GetProperty("evaluationSlots").EnumerateArray().ToArray();
        AssertOrder(governed, "indexKey", "indexVersion", "indexer", "invocationScope", "inputs", "outputCapability", "budget", "failureCodes");
        AssertOrder(inputs[0], "kind", "model", "minimumCount");
        AssertOrder(inputs[1], "kind", "capability", "minimumCount");
        AssertOrder(output, "capabilityKey", "capabilityVersion", "interfaceType");
        AssertOrder(slots[0], "slotKey", "requirement", "profileSurfaces", "materialRole", "targetSelectorKey", "capabilities");
        var text = Encoding.UTF8.GetString(bytes);
        var governedText = governed.GetRawText();
        var modelInput = inputs[0].GetRawText();
        var capabilityInput = inputs[1].GetRawText();
        var outputText = output.GetRawText();
        var budgetText = budget.GetRawText();
        RejectInside(text, governedText,
            ("\"indexKey\":\"protocol.index.governed-reference\"", "\"indexKey\":\"protocol.index.governed-reference-missing\""),
            ("\"indexVersion\":\"1\"", "\"indexVersion\":\"2\""),
            ("\"componentKey\":\"protocol.index.governed-reference\"", "\"componentKey\":\"protocol.index.governed-reference-missing\""),
            ("\"indexer\":{\"componentKey\":\"protocol.index.governed-reference\",\"componentVersion\":\"1\"}", "\"indexer\":{\"componentKey\":\"protocol.index.governed-reference\",\"componentVersion\":\"2\"}"),
            ("\"invocationScope\":\"per-plan\"", "\"invocationScope\":\"per-context\""),
            ("\"outputCapability\":" + outputText, "\"outputCapability\":null"));
        var inputArray = "\"inputs\":[" + modelInput + "," + capabilityInput + "]";
        RejectMany(text, inputArray, "\"inputs\":null", "\"inputs\":[]", "\"inputs\":[" + modelInput + "]",
            "\"inputs\":[" + capabilityInput + "]", "\"inputs\":[" + capabilityInput + "," + modelInput + "]",
            "\"inputs\":[" + modelInput + "," + modelInput + "," + capabilityInput + "]");
        RejectNested(text, governedText, modelInput,
            ("\"kind\":\"model\"", "\"kind\":\"capability\""),
            ("\"model\":" + inputs[0].GetProperty("model").GetRawText() + ",", string.Empty),
            ("protocol.model.markdown-document", "protocol.model.markdown-document-missing"),
            ("\"modelVersion\":\"1\"", "\"modelVersion\":\"2\""), ("protocol.type.model.markdown-document", "protocol.type.model.markdown-document-missing"),
            ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""),
            ("\"minimumCount\":0", "\"minimumCount\":1"),
            ("\"minimumCount\":0", "\"minimumCount\":0,\"maximumCount\":null"),
            ("\"minimumCount\":0", "\"minimumCount\":0,\"maximumCount\":1"),
            ("\"minimumCount\":0", "\"extra\":0,\"minimumCount\":0"));
        RejectNested(text, governedText, capabilityInput,
            ("\"kind\":\"capability\"", "\"kind\":\"model\""),
            ("\"capability\":" + inputs[1].GetProperty("capability").GetRawText() + ",", string.Empty),
            ("protocol.capability.protocol-record-index", "protocol.capability.protocol-record-index-missing"),
            ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""), ("protocol.type.capability.protocol-record-index", "protocol.type.capability.protocol-record-index-missing"),
            ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""),
            ("\"minimumCount\":1", "\"minimumCount\":0"),
            ("\"minimumCount\":1", "\"minimumCount\":1,\"maximumCount\":null"),
            ("\"minimumCount\":1", "\"minimumCount\":1,\"maximumCount\":1"));
        RejectNested(text, governedText, outputText,
            ("protocol.capability.governed-reference-index", "protocol.capability.governed-reference-index-missing"),
            ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""),
            ("protocol.type.capability.governed-reference-index", "protocol.type.capability.governed-reference-index-missing"), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""));
        RejectNested(text, governedText, budgetText,
            ("\"maxBytes\":67108864", "\"maxBytes\":1"), ("\"maxDepth\":256", "\"maxDepth\":1"),
            ("\"maxNodes\":1000000", "\"maxNodes\":1"), ("\"maxComplexity\":10000000", "\"maxComplexity\":1"));
        RejectInside(text, governedText,
            ("\"protocol.budget.exhausted\",\"protocol.index.reference-unavailable\"", "\"protocol.index.reference-unavailable\",\"protocol.budget.exhausted\""));
        var indexArray = "\"indexes\":[" + string.Join(",", indexes.Select(item => item.GetRawText())) + "]";
        RejectMany(text, indexArray,
            "\"indexes\":[" + string.Join(",", indexes.Skip(1).Select(item => item.GetRawText())) + "]",
            "\"indexes\":[" + governedText + "," + governedText + "," + string.Join(",", indexes.Skip(1).Select(item => item.GetRawText())) + "]");
        RejectInside(text, parser.GetRawText(), ("\"parserKey\":\"protocol.parser.markdown\"", "\"parserKey\":\"protocol.parser.repository-target-markdown\""));
        RejectInside(text, governedText,
            ("\"indexKey\":\"protocol.index.governed-reference\"", "\"indexKey\":\"protocol.index.repository-target-resolution\""));
        RejectGovernedSlot(text, slots[0], provider: true);
        RejectGovernedSlot(text, slots[1], provider: false);
        var slotArray = "\"evaluationSlots\":[" + string.Join(",", slots.Select(item => item.GetRawText())) + "]";
        RejectMany(text, slotArray,
            "\"evaluationSlots\":[" + string.Join(",", slots.Skip(1).Select(item => item.GetRawText())) + "]",
            "\"evaluationSlots\":[" + slots[0].GetRawText() + "," + string.Join(",", slots.Select(item => item.GetRawText())) + "]");
        RejectInside(text, slots[0].GetRawText(),
            ("protocol.slot.provider-governed-text", "protocol.slot.repository-target-resolution"));
        RejectMany(text, "\"applicabilitySlots\":[]", "\"applicabilitySlots\":[" + slots[0].GetRawText() + "]");
        RejectMany(text, "\"demandProjectors\":[]", "\"demandProjectors\":[{}]");
        RejectMany(text, "\"admissionProofContracts\":[]", "\"admissionProofContracts\":[{}]");
        var bindings = root.GetProperty("components").EnumerateArray().ToArray();
        foreach (var key in new[] { "protocol.index.governed-reference", "protocol.type.capability.governed-reference-index", "protocol.type.capability.protocol-record-index", "protocol.type.model.markdown-document" })
        {
            var binding = bindings.Single(item => ComponentKey(item) == key).GetRawText();
            RejectRemove(text, binding);
            RejectInside(text, binding, ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""),
                ("\"assemblyName\":\"" + Spec(key).Assembly + "\"", "\"assemblyName\":\"Wrong.Assembly\""),
                ("\"typeName\":\"" + Spec(key).Type + "\"", "\"typeName\":\"Wrong.Type\""),
                ("\"artifactFileName\":\"" + Spec(key).Artifact + "\"", "\"artifactFileName\":\"Missing.dll\""));
        }
        var artifacts = root.GetProperty("artifactFiles").EnumerateArray().Select(item => item.GetRawText()).ToArray();
        RejectMany(text, "\"artifactFiles\":[" + string.Join(",", artifacts) + "]",
            "\"artifactFiles\":[" + string.Join(",", artifacts) + "," + ReplaceRequired(artifacts[^1], "MeAndAI.Protocol.Policy.dll", "Unused.dll") + "]");
        RejectInside(text, registry.GetProperty("cacheBudget").GetRawText(),
            ("\"maxDecodeEntries\":512", "\"maxDecodeEntries\":1"), ("\"maxIndexEntries\":128", "\"maxIndexEntries\":1"),
            ("\"retentionPolicy\":\"retain-lowest-canonical-keys\"", "\"retentionPolicy\":\"unknown\""));
    }
    private static void RejectGovernedSlot(string document, JsonElement element, bool provider)
    {
        var slot = element.GetRawText();
        var capabilities = element.GetProperty("capabilities").EnumerateArray().Select(item => item.GetRawText()).ToArray();
        var key = provider ? "provider" : "repository";
        RejectInside(document, slot,
            ("protocol.slot." + key + "-governed-text", "protocol.slot." + key + "-governed-text-missing"),
            ("protocol.requirement." + key + "-governed-text", "protocol.requirement." + key + "-governed-text-missing"),
            ("\"surface\":\"" + key + "\"", "\"surface\":\"workflow\""),
            ("protocol.evidence.governed-text-set", "protocol.evidence.governed-text-set-missing"),
            ("protocol.completeness.all-governed-bodies", "protocol.completeness.all-governed-bodies-missing"),
            ("\"payloadSchemaKey\":\"protocol.governed-text\"", "\"payloadSchemaKey\":\"protocol.repository-tree\""),
            ("\"payloadSchemaVersion\":\"1\"", "\"payloadSchemaVersion\":\"2\""),
            ("\"acceptedConsistencyClasses\":[\"exact-snapshot\",\"object-version-bound\",\"bounded-non-atomic-observation\"]",
                "\"acceptedConsistencyClasses\":[\"object-version-bound\",\"exact-snapshot\",\"bounded-non-atomic-observation\"]"),
            ("\"bounded-non-atomic-observation\"", "\"exact-snapshot\""),
            (provider ? "\"profileSurfaces\":[\"provider\"]" : "\"profileSurfaces\":[\"repository\",\"provider\"]",
                provider ? "\"profileSurfaces\":[\"repository\"]" : "\"profileSurfaces\":[\"provider\",\"repository\"]"),
            ("protocol.material.governed-text", "protocol.material.governed-text-missing"),
            ("protocol.target." + key + "-governed-body-set", "protocol.target." + key + "-governed-body-set-missing"),
            ("protocol.capability.governed-reference-index", "protocol.capability.governed-reference-index-missing"),
            ("protocol.type.capability.governed-reference-index", "protocol.type.capability.governed-reference-index-missing"),
            ("protocol.capability.protocol-record-index", "protocol.capability.protocol-record-index-missing"));
        RejectCapabilityIdentity(document, slot, capabilities[0], "protocol.type.capability.governed-reference-index");
        RejectCapabilityIdentity(document, slot, capabilities[1], "protocol.type.capability.protocol-record-index");
        var capabilityArray = "\"capabilities\":[" + string.Join(",", capabilities) + "]";
        RejectInside(document, slot, (capabilityArray, "\"capabilities\":[]"),
            (capabilityArray, "\"capabilities\":[" + capabilities[0] + "]"),
            (capabilityArray, "\"capabilities\":[" + capabilities[1] + "]"),
            (capabilityArray, "\"capabilities\":[" + capabilities[1] + "," + capabilities[0] + "]"),
            (capabilityArray, "\"capabilities\":[" + capabilities[0] + "," + capabilities[0] + "," + capabilities[1] + "]"));
        var profile = provider ? "\"profileSurfaces\":[\"provider\"]" : "\"profileSurfaces\":[\"repository\",\"provider\"]";
        RejectInside(document, slot, (profile, "\"profileSurfaces\":[]"),
            (profile, provider ? "\"profileSurfaces\":[\"provider\",\"provider\"]" : "\"profileSurfaces\":[\"repository\"]"));
    }
    private static ReleaseSchemaRegistry CreateRegistry() => ReleaseSchemaRegistry.Create([TreeSchema(), GovernedSchema()], [MarkdownParser()], [TreeIndex(), RecordIndex(), GovernedIndex()],
        Array.Empty<AcquisitionDemandProjectorDeclaration>(), Array.Empty<AdmissionProofContractDeclaration>(),
        SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static PayloadSchemaDeclaration GovernedSchema() => PayloadSchemaDeclaration.Create("protocol.governed-text", "1", Resolve("protocol.codec.governed-text"), SourceModel(), 200_000, 67_108_864, ParserBudget(), GovernedCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TreeSchema() => PayloadSchemaDeclaration.Create("protocol.repository-tree", "1", Resolve("protocol.codec.repository-tree"), TreeModel(), 1, 16_777_216, TreeBudget(), TreeCodecFailures.Reverse());
    private static SemanticModelParserDeclaration MarkdownParser() => SemanticModelParserDeclaration.Create("protocol.parser.markdown", "1", Resolve("protocol.parser.markdown"), [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)], MarkdownModel(), ParserBudget(), ParserFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration GovernedIndex() => ContextIndexDeclaration.Create("protocol.index.governed-reference", "1",
        Resolve("protocol.index.governed-reference"), IndexInvocationScope.PerPlan,
        [ComponentInputDeclaration.ForCapability(RecordCapability(), 1, null), ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)],
        GovernedCapability(), GovernedBudget(), GovernedIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration RecordIndex() => ContextIndexDeclaration.Create("protocol.index.protocol-record", "1", Resolve("protocol.index.protocol-record"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], RecordCapability(), RecordBudget(), RecordFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TreeIndex() => ContextIndexDeclaration.Create("protocol.index.repository-tree", "1", Resolve("protocol.index.repository-tree"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)], TreeCapability(), TreeBudget(), TreeIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static RuleDeclaration CreateRule() => RuleDeclaration.Create(RuleId.Parse("RULE-0001"), RuleRevision.Create(1), CatalogVersion.Create(1),
        ExactSha256Digest.Parse(Digest), [NormativeFragmentDeclaration.Create("docs/rules/index-slot.md", Blob, "index-slot", 1, 2,
            "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))], [TestScenarioId.Parse("TEST-0001")],
        Resolve("protocol.evaluator.test-rule"), Array.Empty<EvidenceSlotDeclaration>(), [TreeSlot(), RepositoryGovernedSlot(), ProviderGovernedSlot()],
        Array.Empty<ExpectedSelectorDeclaration>(), [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]), [SnapshotKind.ExactCommit],
        [ProtocolOperation.Conformance], Array.Empty<FindingDeclaration>(), Array.Empty<EvaluationFailureCode>(), "1.0.0", null, null, Array.Empty<string>());
    private static EvidenceSlotDeclaration ProviderGovernedSlot() => GovernedSlot("provider", SurfaceKind.Provider, [SurfaceKind.Provider]);
    private static EvidenceSlotDeclaration RepositoryGovernedSlot() => GovernedSlot("repository", SurfaceKind.Repository, [SurfaceKind.Provider, SurfaceKind.Repository]);
    private static EvidenceSlotDeclaration GovernedSlot(string scope, SurfaceKind surface, SurfaceKind[] profiles) => EvidenceSlotDeclaration.Create(
        "protocol.slot." + scope + "-governed-text", EvidenceRequirement.Create("protocol.requirement." + scope + "-governed-text", surface,
            "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", "1",
            [EvidenceConsistencyClass.BoundedNonAtomicObservation, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]),
        SurfaceSet.Create(profiles), "protocol.material.governed-text", "protocol.target." + scope + "-governed-body-set", [RecordCapability(), GovernedCapability()]);
    private static EvidenceSlotDeclaration TreeSlot() => EvidenceSlotDeclaration.Create("protocol.slot.repository-tree",
        EvidenceRequirement.Create("protocol.requirement.repository-tree", SurfaceKind.Repository, "protocol.evidence.repository-tree", "protocol.completeness.full-tree",
            "protocol.repository-tree", "1", [EvidenceConsistencyClass.BoundedNonAtomicObservation, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]),
        SurfaceSet.Create([SurfaceKind.Repository]), "protocol.material.repository-tree", "protocol.target.repository-snapshot", [TreeCapability()]);
    private static ModelContractIdentity SourceModel() => Model("protocol.model.source-text", "protocol.type.model.source-text");
    private static ModelContractIdentity MarkdownModel() => Model("protocol.model.markdown-document", "protocol.type.model.markdown-document");
    private static ModelContractIdentity TreeModel() => Model("protocol.model.repository-tree", "protocol.type.model.repository-tree");
    private static ModelContractIdentity Model(string key, string component) => ModelContractIdentity.Create(key, "1", Resolve(component));
    private static CapabilityContractIdentity GovernedCapability() => Capability("protocol.capability.governed-reference-index", "protocol.type.capability.governed-reference-index");
    private static CapabilityContractIdentity RecordCapability() => Capability("protocol.capability.protocol-record-index", "protocol.type.capability.protocol-record-index");
    private static CapabilityContractIdentity TreeCapability() => Capability("protocol.capability.repository-tree", "protocol.type.capability.repository-tree");
    private static CapabilityContractIdentity Capability(string key, string component) => CapabilityContractIdentity.Create(key, "1", Resolve(component));
    private static SemanticResourceBudget ParserBudget() => Budget(4_194_304, 256, 500_000, 5_000_000);
    private static SemanticResourceBudget GovernedBudget() => Budget(67_108_864, 256, 1_000_000, 10_000_000);
    private static SemanticResourceBudget RecordBudget() => GovernedBudget();
    private static SemanticResourceBudget TreeBudget() => Budget(16_777_216, 64, 200_000, 2_000_000);
    private static SemanticResourceBudget Budget(long bytes, int depth, long nodes, long complexity) => SemanticResourceBudget.Create(bytes, depth, nodes, complexity);
    private static ComponentTypeIdentity Resolve(string key) => ComponentTypeIdentity.Create(key, "1", Spec(key).Assembly, Spec(key).Type);
    private static (string Key, string Assembly, string Type, string Artifact) Spec(string key) => Components.Single(item => item.Key == key);
    private static ArtifactFileBinding Artifact(string name) => ArtifactFileBinding.Create(name, 1, ExactSha256Digest.Parse(Digest));
    private static void AssertSchema(PayloadSchemaDeclaration actual, string key, ModelContractIdentity model, int bindings, long retained,
        SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1", bindings, retained), (actual.SchemaKey, actual.SchemaVersion, actual.MaxBindingsPerInstruction, actual.MaxRetainedCanonicalBytesPerInstruction));
        AssertComponent(actual.Codec, key.Replace("protocol.", "protocol.codec.", StringComparison.Ordinal));
        AssertModel(actual.OutputModel, model);
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.CodecFailureCodes);
    }
    private static void AssertIndex(ContextIndexDeclaration actual, string key, IndexInvocationScope scope, CapabilityContractIdentity output,
        SemanticResourceBudget budget, string[] failures)
    {
        Assert.Equal((key, "1", scope), (actual.IndexKey, actual.IndexVersion, actual.InvocationScope));
        AssertComponent(actual.Indexer, key);
        AssertCapability(actual.OutputCapability, output);
        AssertBudget(actual.Budget, budget);
        Assert.Equal(failures, actual.FailureCodes.Select(item => item.Value));
    }
    private static void AssertSlot(EvidenceSlotDeclaration actual, string key, string requirement, SurfaceKind surface, SurfaceKind[] profiles,
        string target, CapabilityContractIdentity[] capabilities, bool tree = false)
    {
        Assert.Equal((key, requirement, surface), (actual.SlotKey, actual.Requirement.Key, actual.Requirement.Surface));
        Assert.Equal(tree ? "protocol.evidence.repository-tree" : "protocol.evidence.governed-text-set", actual.Requirement.Kind);
        Assert.Equal(tree ? "protocol.completeness.full-tree" : "protocol.completeness.all-governed-bodies", actual.Requirement.CompletenessContract);
        Assert.Equal((tree ? "protocol.repository-tree" : "protocol.governed-text", "1"), (actual.Requirement.PayloadSchemaKey, actual.Requirement.PayloadSchemaVersion));
        Assert.Equal([EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.BoundedNonAtomicObservation], actual.Requirement.AcceptedConsistencyClasses);
        Assert.Equal(profiles, actual.ProfileSurfaces.Values);
        Assert.Equal((tree ? "protocol.material.repository-tree" : "protocol.material.governed-text", target), (actual.MaterialRole, actual.TargetSelectorKey));
        Assert.Equal(capabilities, actual.Capabilities);
    }
    private static void AssertModelInput(ComponentInputDeclaration actual, ModelContractIdentity model, int minimum, int? maximum)
    {
        AssertModel(Assert.IsType<ModelContractIdentity>(actual.Model), model);
        Assert.Null(actual.Capability);
        Assert.Equal((minimum, maximum), (actual.MinimumCount, actual.MaximumCount));
    }
    private static void AssertCapabilityInput(ComponentInputDeclaration actual, CapabilityContractIdentity capability, int minimum, int? maximum)
    {
        Assert.Null(actual.Model);
        AssertCapability(Assert.IsType<CapabilityContractIdentity>(actual.Capability), capability);
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
        Assert.Equal((key, "1", expected.Assembly, expected.Type), (actual.ComponentKey, actual.ComponentVersion, actual.AssemblyName, actual.TypeName));
    }
    private static void AssertBudget(SemanticResourceBudget actual, SemanticResourceBudget expected) =>
        Assert.Equal((expected.MaxBytes, expected.MaxDepth, expected.MaxNodes, expected.MaxComplexity), (actual.MaxBytes, actual.MaxDepth, actual.MaxNodes, actual.MaxComplexity));
    private static void AssertOrder(JsonElement element, params string[] names) => Assert.Equal(names, element.EnumerateObject().Select(property => property.Name));
    private static string ComponentKey(JsonElement binding) => binding.GetProperty("component").GetProperty("componentKey").GetString()!;
    private static void RejectNested(string document, string outer, string inner, params (string Old, string New)[] mutations) =>
        Array.ForEach(mutations, mutation => Reject(document, outer, ReplaceRequired(outer, inner, ReplaceRequired(inner, mutation.Old, mutation.New))));
    private static void RejectCapabilityIdentity(string document, string slot, string capability, string component) =>
        RejectNested(document, slot, capability, ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""),
            (component, component + "-missing"), ("\"componentVersion\":\"1\"", "\"componentVersion\":\"2\""));
    private static void RejectInside(string document, string container, params (string Old, string New)[] mutations) =>
        Array.ForEach(mutations, mutation => Reject(document, container, ReplaceRequired(container, mutation.Old, mutation.New)));
    private static void RejectMany(string document, string oldText, params string[] replacements) =>
        Array.ForEach(replacements, replacement => AssertPublicFormatException(ReplaceRequired(document, oldText, replacement)));
    private static void RejectRemove(string document, string item)
    {
        var marker = document.Contains(item + ",", StringComparison.Ordinal) ? item + "," : "," + item;
        AssertPublicFormatException(ReplaceRequired(document, marker, string.Empty));
    }
    private static void Reject(string document, string oldText, string newText) => AssertPublicFormatException(ReplaceRequired(document, oldText, newText));
    private static string ReplaceRequired(string value, string oldText, string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (oldText.Length == 0 || index < 0 || value.IndexOf(oldText, index + oldText.Length, StringComparison.Ordinal) >= 0 ||
            string.Equals(oldText, newText, StringComparison.Ordinal)) throw new InvalidOperationException($"Required mutation marker was invalid or absent: {oldText}");
        return value.Remove(index, oldText.Length).Insert(index, newText);
    }
    private static void AssertPublicFormatException(string manifest) =>
        Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(Encoding.UTF8.GetBytes(manifest)));
}
