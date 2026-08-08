using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAIndexSlotManifestTests
{
    private const string ProbeDigest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string ProbeBlob = "1111111111111111111111111111111111111111";
    private const string SourceCommit = "0000000000000000000000000000000000000001";
    private static readonly string[] CodecFailureCodes =
    [
        "protocol.codec.embedded-identity-mismatch",
        "protocol.codec.invalid-repository-tree",
        "protocol.codec.payload-location-mismatch",
        "protocol.codec.resource-limit-exceeded",
    ];
    private static readonly string[] IndexFailureCodes =
    [
        "protocol.budget.exhausted",
        "protocol.index.repository-tree-unavailable",
    ];
    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_repository_tree_index_and_slot_capability_closure()
    {
        var source = CreateManifest(includeIndex: true);
        var canonicalManifest = CanonicalManifestWriter.Write(source);
        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalManifest);
        Assert.Equal(canonicalManifest, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(
            Convert.ToHexString(SHA256.HashData(canonicalManifest)).ToLowerInvariant(),
            manifest.ManifestDigest.Value);
        Assert.Empty(manifest.SchemaRegistry.Parsers);
        Assert.Empty(manifest.SchemaRegistry.DemandProjectors);
        Assert.Empty(manifest.SchemaRegistry.AdmissionProofContracts);
        var index = Assert.Single(manifest.SchemaRegistry.Indexes);
        Assert.Equal("protocol.index.repository-tree", index.IndexKey);
        Assert.Equal("1", index.IndexVersion);
        AssertComponent(index.Indexer, "protocol.index.repository-tree",
            "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex");
        Assert.Equal(IndexInvocationScope.PerContext, index.InvocationScope);
        var input = Assert.Single(index.Inputs);
        var model = Assert.IsType<ModelContractIdentity>(input.Model);
        Assert.Null(input.Capability);
        Assert.Equal("protocol.model.repository-tree", model.ModelKey);
        Assert.Equal("1", model.ModelVersion);
        AssertComponent(model.ImplementationType, "protocol.type.model.repository-tree",
            "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel");
        Assert.Equal(1, input.MinimumCount);
        Assert.Equal(1, input.MaximumCount);
        Assert.Equal("protocol.capability.repository-tree", index.OutputCapability.CapabilityKey);
        Assert.Equal("1", index.OutputCapability.CapabilityVersion);
        AssertComponent(index.OutputCapability.InterfaceType,
            "protocol.type.capability.repository-tree",
            "MeAndAI.Protocol.Conformance.Abstractions",
            "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree");
        AssertBudget(index.Budget);
        Assert.Equal(IndexFailureCodes, index.FailureCodes.Select(code => code.Value));
        Assert.True(manifest.SchemaRegistry.TryGetIndex(
            "protocol.index.repository-tree", "1", out var resolvedIndex));
        Assert.Same(index, resolvedIndex);
        Assert.False(manifest.SchemaRegistry.TryGetIndex(
            "protocol.index.repository-tree-missing", "1", out _));
        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        var slot = Assert.Single(rule.EvaluationSlots);
        Assert.Equal(index.OutputCapability, Assert.Single(slot.Capabilities));
        var directInput = ComponentInputDeclaration.ForModel(CreateModel(), 1, 1);
        Assert.Equal(1, directInput.MinimumCount);
        Assert.Equal(1, directInput.MaximumCount);
        Assert.ThrowsAny<ArgumentException>(() =>
            ComponentInputDeclaration.ForModel(CreateModel(), 0, 0));
        Assert.ThrowsAny<ArgumentException>(() =>
            ComponentInputDeclaration.ForCapability(CreateCapability(), 0, 0));
        var zeroBytes = CanonicalManifestWriter.Write(CreateManifest(includeIndex: false));
        var zeroManifest = FinalizedPolicyManifest.ParseCanonical(zeroBytes);
        Assert.Equal(zeroBytes, CanonicalManifestWriter.Write(zeroManifest));
        Assert.Empty(zeroManifest.SchemaRegistry.Indexes);
        var zeroRule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(zeroManifest.Slice).Rules);
        Assert.Empty(Assert.Single(zeroRule.EvaluationSlots).Capabilities);
        using var document = JsonDocument.Parse(canonicalManifest);
        var root = document.RootElement;
        var indexElement = root.GetProperty("schemaRegistry").GetProperty("indexes")
            .EnumerateArray().Single();
        var inputElement = indexElement.GetProperty("inputs").EnumerateArray().Single();
        var modelElement = inputElement.GetProperty("model");
        var outputElement = indexElement.GetProperty("outputCapability");
        var budgetElement = indexElement.GetProperty("budget");
        AssertOrder(indexElement, "indexKey", "indexVersion", "indexer", "invocationScope",
            "inputs", "outputCapability", "budget", "failureCodes");
        AssertOrder(indexElement.GetProperty("indexer"), "componentKey", "componentVersion");
        AssertOrder(inputElement, "kind", "model", "minimumCount", "maximumCount");
        AssertOrder(modelElement, "modelKey", "modelVersion", "implementationType");
        AssertOrder(outputElement, "capabilityKey", "capabilityVersion", "interfaceType");
        AssertOrder(budgetElement, "maxBytes", "maxDepth", "maxNodes", "maxComplexity");

        var text = Encoding.UTF8.GetString(canonicalManifest);
        var indexText = indexElement.GetRawText();
        var inputText = inputElement.GetRawText();
        var modelText = modelElement.GetRawText();
        var outputText = outputElement.GetRawText();
        var budgetText = budgetElement.GetRawText();
        var indexerText = indexElement.GetProperty("indexer").GetRawText();
        RejectInside(text, indexText,
            ("\"indexKey\":\"protocol.index.repository-tree\"", "\"unknownIndex\":0,\"indexKey\":\"protocol.index.repository-tree\""),
            ("\"indexKey\":\"protocol.index.repository-tree\"", "\"indexKey\":\"protocol.index.repository-tree\",\"indexKey\":\"protocol.index.repository-tree\""),
            ("\"indexKey\":\"protocol.index.repository-tree\",", string.Empty),
            ("\"indexKey\":\"protocol.index.repository-tree\"", "\"indexKey\":null"),
            ("\"indexVersion\":\"1\"", "\"indexVersion\":\"2\""),
            ("\"indexKey\":\"protocol.index.repository-tree\",\"indexVersion\":\"1\"", "\"indexVersion\":\"1\",\"indexKey\":\"protocol.index.repository-tree\""),
            ("\"indexer\":" + indexerText, "\"indexer\":null"),
            ("\"indexer\":" + indexerText, "\"indexer\":{\"componentVersion\":\"1\",\"componentKey\":\"protocol.index.repository-tree\"}"),
            ("\"invocationScope\":\"per-context\"", "\"invocationScope\":\"per-plan\""),
            ("\"invocationScope\":\"per-context\"", "\"invocationScope\":\"unknown\""),
            ("\"outputCapability\":" + outputText, "\"outputCapability\":null"));
        var inputsText = "\"inputs\":[" + inputText + "]";
        var capabilityInput = "{\"kind\":\"capability\",\"capability\":" + outputText +
            ",\"minimumCount\":1,\"maximumCount\":1}";
        RejectReplacements(text, indexText, inputsText,
            "\"inputs\":null", "\"inputs\":{}", "\"inputs\":[null]", "\"inputs\":[]",
            "\"inputs\":[" + inputText + "," + inputText + "]",
            "\"inputs\":[" + capabilityInput + "]",
            "\"inputs\":[" + ReplaceRequired(inputText, "\"minimumCount\":1",
                "\"capability\":" + outputText + ",\"minimumCount\":1") + "]",
            "\"inputs\":[{\"kind\":\"model\",\"minimumCount\":1,\"maximumCount\":1}]");
        RejectNested(text, indexText, inputText,
            ("\"kind\":\"model\"", "\"unknownInput\":0,\"kind\":\"model\""),
            ("\"kind\":\"model\"", "\"kind\":\"model\",\"kind\":\"model\""),
            ("\"kind\":\"model\",\"model\":" + modelText, "\"model\":" + modelText + ",\"kind\":\"model\""),
            ("\"kind\":\"model\"", "\"kind\":null"),
            ("\"kind\":\"model\"", "\"kind\":\"capability\""),
            ("\"model\":" + modelText, "\"model\":null"),
            ("\"minimumCount\":1", "\"minimumCount\":0"),
            ("\"minimumCount\":1,\"maximumCount\":1", "\"minimumCount\":0,\"maximumCount\":0"),
            ("\"minimumCount\":1,\"maximumCount\":1", "\"minimumCount\":2,\"maximumCount\":2"),
            ("\"maximumCount\":1", "\"maximumCount\":0"),
            ("\"maximumCount\":1", "\"maximumCount\":2"),
            (",\"maximumCount\":1", string.Empty),
            ("\"maximumCount\":1", "\"maximumCount\":null"));
        RejectNested(text, indexText, modelText,
            ("\"modelKey\":\"protocol.model.repository-tree\"", "\"modelKey\":\"protocol.model.repository-tree-missing\""),
            ("\"modelVersion\":\"1\"", "\"modelVersion\":\"2\""),
            ("protocol.type.model.repository-tree", "protocol.type.model.repository-tree-missing"),
            ("\"modelKey\":\"protocol.model.repository-tree\",\"modelVersion\":\"1\"", "\"modelVersion\":\"1\",\"modelKey\":\"protocol.model.repository-tree\""));
        RejectNested(text, indexText, outputText,
            ("protocol.capability.repository-tree", "protocol.capability.repository-tree-missing"),
            ("\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"2\""),
            ("protocol.type.capability.repository-tree", "protocol.type.capability.repository-tree-missing"),
            ("\"capabilityKey\":\"protocol.capability.repository-tree\",\"capabilityVersion\":\"1\"", "\"capabilityVersion\":\"1\",\"capabilityKey\":\"protocol.capability.repository-tree\""),
            ("\"interfaceType\":{\"componentKey\":\"protocol.type.capability.repository-tree\",\"componentVersion\":\"1\"}", "\"interfaceType\":null"));
        RejectNested(text, indexText, budgetText,
            ("\"maxBytes\":16777216", "\"maxBytes\":1"),
            ("\"maxDepth\":64", "\"maxDepth\":1"),
            ("\"maxNodes\":200000", "\"maxNodes\":1"),
            ("\"maxComplexity\":2000000", "\"maxComplexity\":1"),
            ("\"maxBytes\":16777216,\"maxDepth\":64", "\"maxDepth\":64,\"maxBytes\":16777216"));
        RejectInside(text, indexText, ("\"budget\":" + budgetText, "\"budget\":null"));
        var failures = "\"failureCodes\":[\"protocol.budget.exhausted\",\"protocol.index.repository-tree-unavailable\"]";
        RejectReplacements(text, indexText, failures,
            "\"failureCodes\":null", "\"failureCodes\":[]",
            "\"failureCodes\":[\"protocol.budget.exhausted\"]",
            "\"failureCodes\":[\"protocol.budget.exhausted\",\"protocol.index.unknown\"]",
            "\"failureCodes\":[\"protocol.budget.exhausted\",\"protocol.index.repository-tree-unavailable\",\"protocol.index.unknown\"]",
            "\"failureCodes\":[\"protocol.budget.exhausted\",\"protocol.budget.exhausted\",\"protocol.index.repository-tree-unavailable\"]",
            "\"failureCodes\":[\"protocol.index.repository-tree-unavailable\",\"protocol.budget.exhausted\"]");
        var indexesText = "\"indexes\":[" + indexText + "]";
        RejectDocumentReplacements(text, indexesText,
            "\"indexes\":null", "\"indexes\":{}", "\"indexes\":[null]",
            "\"indexes\":[]", "\"indexes\":[" + indexText + "," + indexText + "]");
        foreach (var otherKey in new[]
        {
            "protocol.index.protocol-record",
            "protocol.index.governed-reference",
            "protocol.index.repository-target-resolution",
        })
        {
            var other = ReplaceRequired(indexText,
                "\"indexKey\":\"protocol.index.repository-tree\"",
                "\"indexKey\":\"" + otherKey + "\"");
            RejectDocumentReplacements(text, indexesText,
                "\"indexes\":[" + other + "]",
                "\"indexes\":[" + indexText + "," + other + "]");
        }
        var parser = "{\"parserKey\":\"protocol.parser.held\",\"parserVersion\":\"1\",\"parser\":" + indexerText +
            ",\"inputs\":[" + inputText + "],\"outputModel\":" + modelText + ",\"budget\":" + budgetText +
            ",\"failureCodes\":[\"protocol.budget.exhausted\"]}";
        RejectDocumentReplacements(text, "\"parsers\":[]", "\"parsers\":[" + parser + "]");
        var slotElement = root.GetProperty("slice").GetProperty("rules").EnumerateArray()
            .Single().GetProperty("evaluationSlots").EnumerateArray().Single();
        var slotText = slotElement.GetRawText();
        var capabilityText = slotElement.GetProperty("capabilities").EnumerateArray().Single().GetRawText();
        RejectInside(text, slotText,
            ("\"capabilities\":[" + capabilityText + "]", "\"capabilities\":[]"),
            ("\"capabilities\":[" + capabilityText + "]", "\"capabilities\":[" + capabilityText + "," + capabilityText + "]"));
        var bindings = root.GetProperty("components").EnumerateArray().ToArray();
        var indexerBinding = bindings.Single(item => ComponentKey(item) == "protocol.index.repository-tree").GetRawText();
        var interfaceBinding = bindings.Single(item => ComponentKey(item) == "protocol.type.capability.repository-tree").GetRawText();
        RejectDocumentReplacements(text, indexerBinding + ",", string.Empty);
        RejectDocumentReplacements(text, interfaceBinding + ",", string.Empty);
        RejectInside(text, indexerBinding,
            ("\"assemblyName\":\"MeAndAI.Protocol.Policy\"", "\"assemblyName\":\"Wrong.Assembly\""),
            ("\"typeName\":\"MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex\"", "\"typeName\":\"Wrong.Type\""),
            ("\"artifactFileName\":\"MeAndAI.Protocol.Policy.dll\"", "\"artifactFileName\":\"Missing.dll\""));
        RejectInside(text, interfaceBinding,
            ("\"assemblyName\":\"MeAndAI.Protocol.Conformance.Abstractions\"", "\"assemblyName\":\"Wrong.Assembly\""),
            ("\"typeName\":\"MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree\"", "\"typeName\":\"Wrong.Type\""),
            ("\"artifactFileName\":\"MeAndAI.Protocol.Conformance.Abstractions.dll\"", "\"artifactFileName\":\"Missing.dll\""));
        var interfaceArtifact = root.GetProperty("artifactFiles").EnumerateArray()
            .Single(item => item.GetProperty("fileName").GetString() ==
                "MeAndAI.Protocol.Conformance.Abstractions.dll").GetRawText();
        RejectDocumentReplacements(text, interfaceArtifact + ",", string.Empty);
    }

    private static ParsedCanonicalManifest CreateManifest(bool includeIndex) => new(
        CatalogAuthorityKind.QualificationSlice,
        SourceCommit,
        CreateRegistry(includeIndex),
        ActivationProofContractDeclaration.Create("protocol.activation-proof.test", "1.0.0",
            ResolveComponent("protocol.activation-proof.test")),
        CreateArtifacts(includeIndex),
        CreateComponents(includeIndex),
        CatalogSliceDeclaration.Create("protocol.catalog-slice.index-slot", "1", "0.0.0",
            CatalogVersion.Create(1), [CreateRule(CreateSlot(includeIndex))]));
    private static ReleaseSchemaRegistry CreateRegistry(bool includeIndex) => ReleaseSchemaRegistry.Create(
        [PayloadSchemaDeclaration.Create("protocol.repository-tree", "1",
            ResolveComponent("protocol.codec.repository-tree"), CreateModel(), 1, 16_777_216,
            CreateBudget(), CodecFailureCodes.Reverse())],
        Array.Empty<SemanticModelParserDeclaration>(),
        includeIndex ? [CreateIndex()] : Array.Empty<ContextIndexDeclaration>(),
        Array.Empty<AcquisitionDemandProjectorDeclaration>(),
        Array.Empty<AdmissionProofContractDeclaration>(),
        SessionCacheBudget.Create(1, 1, 1, 1, 1, 1, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static ContextIndexDeclaration CreateIndex() => ContextIndexDeclaration.Create(
        "protocol.index.repository-tree", "1", ResolveComponent("protocol.index.repository-tree"),
        IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(CreateModel(), 1, 1)],
        CreateCapability(), CreateBudget(), IndexFailureCodes.Reverse().Select(EvaluationFailureCode.Parse));
    private static ModelContractIdentity CreateModel() => ModelContractIdentity.Create(
        "protocol.model.repository-tree", "1", ResolveComponent("protocol.type.model.repository-tree"));
    private static CapabilityContractIdentity CreateCapability() => CapabilityContractIdentity.Create(
        "protocol.capability.repository-tree", "1",
        ResolveComponent("protocol.type.capability.repository-tree"));
    private static SemanticResourceBudget CreateBudget() =>
        SemanticResourceBudget.Create(16_777_216, 64, 200_000, 2_000_000);
    private static RuleDeclaration CreateRule(EvidenceSlotDeclaration slot) => RuleDeclaration.Create(
        RuleId.Parse("RULE-0001"), RuleRevision.Create(1), CatalogVersion.Create(1),
        ExactSha256Digest.Parse(ProbeDigest),
        [NormativeFragmentDeclaration.Create("docs/rules/index-slot.md", ProbeBlob, "index-slot",
            1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(ProbeDigest))],
        [TestScenarioId.Parse("TEST-0001")], ResolveComponent("protocol.evaluator.test-rule"),
        Array.Empty<EvidenceSlotDeclaration>(), [slot], Array.Empty<ExpectedSelectorDeclaration>(),
        [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]), [SnapshotKind.ExactCommit],
        [ProtocolOperation.Conformance], Array.Empty<FindingDeclaration>(),
        Array.Empty<EvaluationFailureCode>(), "1.0.0", null, null, Array.Empty<string>());
    private static EvidenceSlotDeclaration CreateSlot(bool includeCapability) => EvidenceSlotDeclaration.Create(
        "protocol.slot.repository-tree",
        EvidenceRequirement.Create("protocol.requirement.repository-tree", SurfaceKind.Repository,
            "protocol.evidence.repository-tree", "protocol.completeness.full-tree",
            "protocol.repository-tree", "1",
            [EvidenceConsistencyClass.BoundedNonAtomicObservation,
                EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]),
        SurfaceSet.Create([SurfaceKind.Repository]), "protocol.material.repository-tree",
        "protocol.target.repository-snapshot",
        includeCapability ? [CreateCapability()] : Array.Empty<CapabilityContractIdentity>());
    private static ComponentTypeIdentity ResolveComponent(string key) => key switch
    {
        "protocol.activation-proof.test" => ComponentTypeIdentity.Create(key, "1",
            "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"),
        "protocol.codec.repository-tree" => ComponentTypeIdentity.Create(key, "1",
            "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec"),
        "protocol.evaluator.test-rule" => ComponentTypeIdentity.Create(key, "1",
            "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAIndexSlotEvaluator"),
        "protocol.index.repository-tree" => ComponentTypeIdentity.Create(key, "1",
            "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex"),
        "protocol.type.capability.repository-tree" => ComponentTypeIdentity.Create(key, "1",
            "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree"),
        "protocol.type.model.repository-tree" => ComponentTypeIdentity.Create(key, "1",
            "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel"),
        _ => throw new ArgumentOutOfRangeException(nameof(key)),
    };

    private static IReadOnlyList<ArtifactFileBinding> CreateArtifacts(bool includeIndex) => includeIndex
        ? [Artifact("ContractSliceA.Proof.dll"), Artifact("MeAndAI.Protocol.Conformance.Abstractions.dll"),
            Artifact("MeAndAI.Protocol.Policy.dll")]
        : [Artifact("ContractSliceA.Proof.dll"), Artifact("MeAndAI.Protocol.Policy.dll")];
    private static ArtifactFileBinding Artifact(string name) =>
        ArtifactFileBinding.Create(name, 1, ExactSha256Digest.Parse(ProbeDigest));
    private static IReadOnlyList<ComponentArtifactBinding> CreateComponents(bool includeIndex)
    {
        var bindings = new List<ComponentArtifactBinding>
        {
            Bind("protocol.activation-proof.test", "ContractSliceA.Proof.dll"),
            Bind("protocol.codec.repository-tree", "MeAndAI.Protocol.Policy.dll"),
            Bind("protocol.evaluator.test-rule", "ContractSliceA.Proof.dll"),
            Bind("protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy.dll"),
        };
        if (includeIndex)
        {
            bindings.Add(Bind("protocol.index.repository-tree", "MeAndAI.Protocol.Policy.dll"));
            bindings.Add(Bind("protocol.type.capability.repository-tree",
                "MeAndAI.Protocol.Conformance.Abstractions.dll"));
        }

        return bindings.OrderBy(item => item.Component.ComponentKey, StringComparer.Ordinal).ToArray();
    }
    private static ComponentArtifactBinding Bind(string key, string artifact) =>
        ComponentArtifactBinding.Create(ResolveComponent(key), artifact);
    private static void AssertComponent(
        ComponentTypeIdentity actual, string key, string assembly, string type)
    {
        Assert.Equal(key, actual.ComponentKey);
        Assert.Equal("1", actual.ComponentVersion);
        Assert.Equal(assembly, actual.AssemblyName);
        Assert.Equal(type, actual.TypeName);
    }
    private static void AssertBudget(SemanticResourceBudget budget) =>
        Assert.Equal((16_777_216L, 64, 200_000L, 2_000_000L),
            (budget.MaxBytes, budget.MaxDepth, budget.MaxNodes, budget.MaxComplexity));

    private static void AssertOrder(JsonElement element, params string[] names) =>
        Assert.Equal(names, element.EnumerateObject().Select(property => property.Name));
    private static string ComponentKey(JsonElement binding) =>
        binding.GetProperty("component").GetProperty("componentKey").GetString()!;
    private static void RejectNested(
        string document, string outer, string inner, params (string Old, string New)[] mutations)
    {
        foreach (var mutation in mutations)
        {
            RejectDocument(document, outer, ReplaceRequired(
                outer, inner, ReplaceRequired(inner, mutation.Old, mutation.New)));
        }
    }
    private static void RejectInside(
        string document, string container, params (string Old, string New)[] mutations)
    {
        foreach (var mutation in mutations)
        {
            RejectDocument(document, container,
                ReplaceRequired(container, mutation.Old, mutation.New));
        }
    }
    private static void RejectReplacements(
        string document, string outer, string inner, params string[] replacements)
    {
        foreach (var replacement in replacements)
        {
            RejectDocument(document, outer, ReplaceRequired(outer, inner, replacement));
        }
    }
    private static void RejectDocumentReplacements(
        string document, string oldText, params string[] replacements)
    {
        foreach (var replacement in replacements)
        {
            AssertPublicFormatException(ReplaceRequired(document, oldText, replacement));
        }
    }
    private static void RejectDocument(string document, string oldText, string newText) =>
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
