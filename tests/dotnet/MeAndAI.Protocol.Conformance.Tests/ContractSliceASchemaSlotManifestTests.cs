using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceASchemaSlotManifestTests
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

    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_schema_and_zero_capability_evidence_slot_closure()
    {
        var source = CreateManifest();
        var canonicalManifest = CanonicalManifestWriter.Write(source);

        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalManifest);
        Assert.Equal(canonicalManifest, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(
            Convert.ToHexString(SHA256.HashData(canonicalManifest)).ToLowerInvariant(),
            manifest.ManifestDigest.Value);

        var schema = Assert.Single(manifest.SchemaRegistry.PayloadSchemas);
        Assert.Equal("protocol.repository-tree", schema.SchemaKey);
        Assert.Equal("1", schema.SchemaVersion);
        Assert.Equal("protocol.codec.repository-tree", schema.Codec.ComponentKey);
        Assert.Equal("protocol.model.repository-tree", schema.OutputModel.ModelKey);
        Assert.Equal("protocol.type.model.repository-tree", schema.OutputModel.ImplementationType.ComponentKey);
        Assert.Equal(1, schema.MaxBindingsPerInstruction);
        Assert.Equal(16_777_216, schema.MaxRetainedCanonicalBytesPerInstruction);
        Assert.Equal(16_777_216, schema.Budget.MaxBytes);
        Assert.Equal(64, schema.Budget.MaxDepth);
        Assert.Equal(200_000, schema.Budget.MaxNodes);
        Assert.Equal(2_000_000, schema.Budget.MaxComplexity);
        Assert.Equal(CodecFailureCodes, schema.CodecFailureCodes);
        Assert.True(manifest.SchemaRegistry.TryGetPayloadSchema(
            "protocol.repository-tree",
            "1",
            out var resolvedSchema));
        Assert.Same(schema, resolvedSchema);
        Assert.False(manifest.SchemaRegistry.TryGetPayloadSchema(
            "protocol.repository-tree-missing",
            "1",
            out _));
        Assert.Empty(manifest.SchemaRegistry.Parsers);
        Assert.Empty(manifest.SchemaRegistry.Indexes);
        Assert.Empty(manifest.SchemaRegistry.DemandProjectors);
        Assert.Empty(manifest.SchemaRegistry.AdmissionProofContracts);

        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        Assert.Empty(rule.ApplicabilitySlots);
        var slot = Assert.Single(rule.EvaluationSlots);
        Assert.Equal("protocol.slot.repository-tree", slot.SlotKey);
        Assert.Equal("protocol.requirement.repository-tree", slot.Requirement.Key);
        Assert.Equal(SurfaceKind.Repository, slot.Requirement.Surface);
        Assert.Equal("protocol.evidence.repository-tree", slot.Requirement.Kind);
        Assert.Equal("protocol.completeness.full-tree", slot.Requirement.CompletenessContract);
        Assert.Equal("protocol.repository-tree", slot.Requirement.PayloadSchemaKey);
        Assert.Equal("1", slot.Requirement.PayloadSchemaVersion);
        Assert.Equal(
            [
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceConsistencyClass.ObjectVersionBound,
                EvidenceConsistencyClass.BoundedNonAtomicObservation,
            ],
            slot.Requirement.AcceptedConsistencyClasses);
        Assert.Equal([SurfaceKind.Repository], slot.ProfileSurfaces.Values);
        Assert.Equal("protocol.material.repository-tree", slot.MaterialRole);
        Assert.Equal("protocol.target.repository-snapshot", slot.TargetSelectorKey);
        Assert.Empty(slot.Capabilities);

        var equalReuseCanonical = CanonicalManifestWriter.Write(CreateManifest(
        [
            CreateRule("RULE-0001", CreateSlot()),
            CreateRule("RULE-0002", CreateSlot()),
        ]));
        var equalReuseManifest = FinalizedPolicyManifest.ParseCanonical(equalReuseCanonical);
        Assert.Equal(equalReuseCanonical, CanonicalManifestWriter.Write(equalReuseManifest));
        Assert.Equal(2, Assert.IsType<CatalogSliceDeclaration>(equalReuseManifest.Slice).Rules.Count);

        var independentSurfaceCanonical = CanonicalManifestWriter.Write(CreateManifest([
            CreateRule("RULE-0001", CreateSlot(profileSurface: SurfaceKind.Provider),
                [SurfaceKind.Repository, SurfaceKind.Provider]),
        ]));
        var independentSurfaceSlice = Assert.IsType<CatalogSliceDeclaration>(
            FinalizedPolicyManifest.ParseCanonical(independentSurfaceCanonical).Slice);
        var independentSurfaceSlot = Assert.Single(Assert.Single(independentSurfaceSlice.Rules).EvaluationSlots);
        Assert.Equal(SurfaceKind.Repository, independentSurfaceSlot.Requirement.Surface);
        Assert.Equal([SurfaceKind.Provider], independentSurfaceSlot.ProfileSurfaces.Values);

        using var document = JsonDocument.Parse(canonicalManifest);
        var root = document.RootElement;
        var canonicalSchema = root.GetProperty("schemaRegistry")
            .GetProperty("payloadSchemas")
            .EnumerateArray()
            .Single();
        var canonicalOutputModel = canonicalSchema.GetProperty("outputModel");
        var canonicalBudget = canonicalSchema.GetProperty("budget");
        Assert.Equal(
            [
                "schemaKey",
                "schemaVersion",
                "codec",
                "outputModel",
                "maxBindingsPerInstruction",
                "maxRetainedCanonicalBytesPerInstruction",
                "budget",
                "codecFailureCodes",
            ],
            canonicalSchema.EnumerateObject().Select(property => property.Name));
        Assert.Equal(
            ["componentKey", "componentVersion"],
            canonicalSchema.GetProperty("codec").EnumerateObject().Select(property => property.Name));
        Assert.Equal(
            ["modelKey", "modelVersion", "implementationType"],
            canonicalOutputModel.EnumerateObject().Select(property => property.Name));
        Assert.Equal(
            ["maxBytes", "maxDepth", "maxNodes", "maxComplexity"],
            canonicalBudget.EnumerateObject().Select(property => property.Name));

        var canonicalRule = root.GetProperty("slice").GetProperty("rules").EnumerateArray().Single();
        var canonicalSlot = canonicalRule.GetProperty("evaluationSlots").EnumerateArray().Single();
        var canonicalRequirement = canonicalSlot.GetProperty("requirement");
        Assert.Equal(
            ["slotKey", "requirement", "profileSurfaces", "materialRole", "targetSelectorKey", "capabilities"],
            canonicalSlot.EnumerateObject().Select(property => property.Name));
        Assert.Equal(
            ["key", "surface", "kind", "completenessContract", "payloadSchemaKey", "payloadSchemaVersion", "acceptedConsistencyClasses"],
            canonicalRequirement.EnumerateObject().Select(property => property.Name));

        var canonicalText = Encoding.UTF8.GetString(canonicalManifest);
        var schemaText = canonicalSchema.GetRawText();
        var outputModelText = canonicalOutputModel.GetRawText();
        var budgetText = canonicalBudget.GetRawText();
        var slotText = canonicalSlot.GetRawText();
        var requirementText = canonicalRequirement.GetRawText();
        var ruleText = canonicalRule.GetRawText();

        var invalidMutations = new (string OldText, string NewText)[]
        {
            ("\"schemaKey\":\"protocol.repository-tree\"", "\"unknownSchema\":0,\"schemaKey\":\"protocol.repository-tree\""),
            ("\"schemaKey\":\"protocol.repository-tree\",", string.Empty),
            ("\"schemaKey\":\"protocol.repository-tree\",\"schemaVersion\":\"1\"", "\"schemaVersion\":\"1\",\"schemaKey\":\"protocol.repository-tree\""),
            ("\"schemaKey\":\"protocol.repository-tree\"", "\"schemaKey\":null"),
            ("\"schemaKey\":\"protocol.repository-tree\"", "\"schemaKey\":\"Protocol.repository-tree\""),
            ("\"schemaVersion\":\"1\"", "\"schemaVersion\":\"!\""),
            ("\"codec\":{\"componentKey\":\"protocol.codec.repository-tree\",\"componentVersion\":\"1\"}", "\"codec\":null"),
            ("\"outputModel\":" + outputModelText, "\"outputModel\":null"),
            ("\"modelKey\":\"protocol.model.repository-tree\"", "\"unknownModel\":0,\"modelKey\":\"protocol.model.repository-tree\""),
            ("\"modelKey\":\"protocol.model.repository-tree\",", string.Empty),
            ("\"modelKey\":\"protocol.model.repository-tree\",\"modelVersion\":\"1\"", "\"modelVersion\":\"1\",\"modelKey\":\"protocol.model.repository-tree\""),
            ("\"modelVersion\":\"1\"", "\"modelVersion\":\"!\""),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}", "\"implementationType\":null"),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"unknownComponent\":0,\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}"),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"componentVersion\":\"1\",\"componentKey\":\"protocol.type.model.repository-tree\"}"),
            ("\"maxBindingsPerInstruction\":1", "\"maxBindingsPerInstruction\":0"),
            ("\"maxRetainedCanonicalBytesPerInstruction\":16777216", "\"maxRetainedCanonicalBytesPerInstruction\":0"),
            ("\"budget\":" + budgetText, "\"budget\":null"),
            ("\"maxBytes\":16777216", "\"unknownBudget\":0,\"maxBytes\":16777216"),
            ("\"maxBytes\":16777216,", string.Empty),
            ("\"maxBytes\":16777216", "\"maxBytes\":0"),
            ("\"maxDepth\":64", "\"maxDepth\":0"),
            ("\"maxNodes\":200000", "\"maxNodes\":0"),
            ("\"maxComplexity\":2000000", "\"maxComplexity\":0"),
            ("\"maxBytes\":16777216,\"maxDepth\":64", "\"maxDepth\":64,\"maxBytes\":16777216"),
            ("\"protocol.codec.embedded-identity-mismatch\",\"protocol.codec.invalid-repository-tree\"", "\"protocol.codec.invalid-repository-tree\",\"protocol.codec.embedded-identity-mismatch\""),
            ("\"protocol.codec.embedded-identity-mismatch\"", "\"protocol.codec.embedded-identity-mismatch\",\"protocol.codec.embedded-identity-mismatch\""),
            ("\"protocol.codec.resource-limit-exceeded\"", "\"Protocol.codec.resource-limit-exceeded\""),
            ("\"slotKey\":\"protocol.slot.repository-tree\"", "\"slotKey\":\"Protocol.slot.repository-tree\""),
            ("\"slotKey\":\"protocol.slot.repository-tree\"", "\"unknownSlot\":0,\"slotKey\":\"protocol.slot.repository-tree\""),
            ("\"slotKey\":\"protocol.slot.repository-tree\",\"requirement\":" + requirementText, "\"requirement\":" + requirementText + ",\"slotKey\":\"protocol.slot.repository-tree\""),
            ("\"requirement\":" + requirementText, "\"requirement\":null"),
            ("\"key\":\"protocol.requirement.repository-tree\"", "\"unknownRequirement\":0,\"key\":\"protocol.requirement.repository-tree\""),
            ("\"key\":\"protocol.requirement.repository-tree\",", string.Empty),
            ("\"key\":\"protocol.requirement.repository-tree\"", "\"key\":null"),
            ("\"key\":\"protocol.requirement.repository-tree\"", "\"key\":\"Protocol.requirement.repository-tree\""),
            ("\"key\":\"protocol.requirement.repository-tree\",\"surface\":\"repository\"", "\"surface\":\"repository\",\"key\":\"protocol.requirement.repository-tree\""),
            ("\"surface\":\"repository\"", "\"surface\":\"unknown\""),
            ("\"kind\":\"protocol.evidence.repository-tree\"", "\"kind\":\"Protocol.evidence.repository-tree\""),
            ("\"completenessContract\":\"protocol.completeness.full-tree\"", "\"completenessContract\":\"Protocol.completeness.full-tree\""),
            ("\"materialRole\":\"protocol.material.repository-tree\"", "\"materialRole\":null"),
            ("\"materialRole\":\"protocol.material.repository-tree\"", "\"materialRole\":\"Protocol.material.repository-tree\""),
            ("\"targetSelectorKey\":\"protocol.target.repository-snapshot\"", "\"targetSelectorKey\":\"Protocol.target.repository-snapshot\""),
            ("\"profileSurfaces\":[\"repository\"]", "\"profileSurfaces\":[]"),
            ("\"profileSurfaces\":[\"repository\"]", "\"profileSurfaces\":[\"unknown\"]"),
            ("\"profileSurfaces\":[\"repository\"]", "\"profileSurfaces\":[\"repository\",\"repository\"]"),
            ("\"acceptedConsistencyClasses\":[\"exact-snapshot\",\"object-version-bound\",\"bounded-non-atomic-observation\"]", "\"acceptedConsistencyClasses\":[\"object-version-bound\",\"exact-snapshot\",\"bounded-non-atomic-observation\"]"),
            ("\"acceptedConsistencyClasses\":[\"exact-snapshot\",\"object-version-bound\",\"bounded-non-atomic-observation\"]", "\"acceptedConsistencyClasses\":[]"),
            ("\"payloadSchemaKey\":\"protocol.repository-tree\"", "\"payloadSchemaKey\":\"protocol.repository-tree-missing\""),
            ("\"payloadSchemaVersion\":\"1\"", "\"payloadSchemaVersion\":\"2\""),
            ("\"codec\":{\"componentKey\":\"protocol.codec.repository-tree\",\"componentVersion\":\"1\"}", "\"codec\":{\"componentKey\":\"protocol.codec.repository-tree-missing\",\"componentVersion\":\"1\"}"),
            ("\"codec\":{\"componentKey\":\"protocol.codec.repository-tree\",\"componentVersion\":\"1\"}", "\"codec\":{\"componentKey\":\"protocol.codec.repository-tree\",\"componentVersion\":\"2\"}"),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree-missing\",\"componentVersion\":\"1\"}"),
            ("\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}", "\"implementationType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"2\"}"),
            ("\"capabilities\":[]", "\"capabilities\":[{\"capabilityKey\":\"protocol.capability.repository-tree\",\"capabilityVersion\":\"1\",\"interfaceType\":{\"componentKey\":\"protocol.type.model.repository-tree\",\"componentVersion\":\"1\"}}]"),
        };
        foreach (var mutation in invalidMutations)
        {
            AssertPublicFormatException(ReplaceRequired(canonicalText, mutation.OldText, mutation.NewText));
        }

        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"evaluationSlots\":[" + slotText + "]",
            "\"evaluationSlots\":[null]"));

        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"payloadSchemas\":[" + schemaText + "]",
            "\"payloadSchemas\":[" + schemaText + "," + schemaText + "]"));
        var unusedSchemaText = ReplaceRequired(
            schemaText,
            "\"schemaKey\":\"protocol.repository-tree\"",
            "\"schemaKey\":\"protocol.repository-tree-unused\"");
        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"payloadSchemas\":[" + schemaText + "]",
            "\"payloadSchemas\":[" + schemaText + "," + unusedSchemaText + "]"));
        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"evaluationSlots\":[" + slotText + "]",
            "\"evaluationSlots\":[]"));
        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"evaluationSlots\":[" + slotText + "]",
            "\"evaluationSlots\":[" + slotText + "," + slotText + "]"));

        var conflictingRuleText = ReplaceRequired(
            ReplaceRequired(ruleText, "\"ruleId\":\"RULE-0001\"", "\"ruleId\":\"RULE-0002\""),
            "\"materialRole\":\"protocol.material.repository-tree\"",
            "\"materialRole\":\"protocol.material.repository-tree-conflict\"");
        var conflictingSlotText = ReplaceRequired(
            slotText,
            "\"materialRole\":\"protocol.material.repository-tree\"",
            "\"materialRole\":\"protocol.material.repository-tree-conflict\"");
        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"applicabilitySlots\":[]",
            "\"applicabilitySlots\":[" + conflictingSlotText + "]"));
        AssertPublicFormatException(ReplaceRequired(
            canonicalText,
            "\"rules\":[" + ruleText + "]",
            "\"rules\":[" + ruleText + "," + conflictingRuleText + "]"));

        Assert.Throws<ArgumentException>(() => CatalogSliceDeclaration.Create(
            "protocol.catalog-slice.schema-slot-conflict",
            "1",
            "0.0.0",
            CatalogVersion.Create(1),
            [
                CreateRule("RULE-0001", CreateSlot()),
                CreateRule(
                    "RULE-0002",
                    CreateSlot("protocol.material.repository-tree-conflict")),
            ]));
    }

    private static ParsedCanonicalManifest CreateManifest(
        IReadOnlyList<RuleDeclaration>? rules = null) =>
        new(
            CatalogAuthorityKind.QualificationSlice,
            SourceCommit,
            CreateRegistry(),
            ActivationProofContractDeclaration.Create(
                "protocol.activation-proof.test",
                "1.0.0",
                ResolveComponentIdentity("protocol.activation-proof.test")),
            CreateArtifacts(),
            CreateComponents(),
            CatalogSliceDeclaration.Create(
                "protocol.catalog-slice.schema-slot",
                "1",
                "0.0.0",
                CatalogVersion.Create(1),
                rules ?? [CreateRule("RULE-0001", CreateSlot())]));

    private static ReleaseSchemaRegistry CreateRegistry() =>
        ReleaseSchemaRegistry.Create(
            [
                PayloadSchemaDeclaration.Create(
                    "protocol.repository-tree",
                    "1",
                    ResolveComponentIdentity("protocol.codec.repository-tree"),
                    ModelContractIdentity.Create(
                        "protocol.model.repository-tree",
                        "1",
                        ResolveComponentIdentity("protocol.type.model.repository-tree")),
                    1,
                    16_777_216,
                    SemanticResourceBudget.Create(16_777_216, 64, 200_000, 2_000_000),
                    CodecFailureCodes.Reverse()),
            ],
            Array.Empty<SemanticModelParserDeclaration>(),
            Array.Empty<ContextIndexDeclaration>(),
            Array.Empty<AcquisitionDemandProjectorDeclaration>(),
            Array.Empty<AdmissionProofContractDeclaration>(),
            SessionCacheBudget.Create(
                1,
                1,
                1,
                1,
                1,
                1,
                CacheRetentionPolicy.RetainLowestCanonicalKeys));

    private static RuleDeclaration CreateRule(
        string ruleId,
        EvidenceSlotDeclaration slot,
        IReadOnlyList<SurfaceKind>? surfaces = null) =>
        RuleDeclaration.Create(
            RuleId.Parse(ruleId),
            RuleRevision.Create(1),
            CatalogVersion.Create(1),
            ExactSha256Digest.Parse(ProbeDigest),
            [
                NormativeFragmentDeclaration.Create(
                    "docs/rules/schema-slot.md",
                    ProbeBlob,
                    "schema-slot",
                    1,
                    2,
                    "protocol.normative-fragment.utf8-lines.v1",
                    2,
                    ExactSha256Digest.Parse(ProbeDigest)),
            ],
            [TestScenarioId.Parse("TEST-0001")],
            ResolveComponentIdentity("protocol.evaluator.test-rule"),
            Array.Empty<EvidenceSlotDeclaration>(),
            [slot],
            Array.Empty<ExpectedSelectorDeclaration>(),
            [SubjectRole.Consumer],
            SurfaceSet.Create(surfaces ?? [SurfaceKind.Repository]),
            [SnapshotKind.ExactCommit],
            [ProtocolOperation.Conformance],
            Array.Empty<FindingDeclaration>(),
            Array.Empty<EvaluationFailureCode>(),
            "1.0.0",
            null,
            null,
            Array.Empty<string>());

    private static EvidenceSlotDeclaration CreateSlot(
        string materialRole = "protocol.material.repository-tree",
        SurfaceKind? profileSurface = null) =>
        EvidenceSlotDeclaration.Create(
            "protocol.slot.repository-tree",
            EvidenceRequirement.Create(
                "protocol.requirement.repository-tree",
                SurfaceKind.Repository,
                "protocol.evidence.repository-tree",
                "protocol.completeness.full-tree",
                "protocol.repository-tree",
                "1",
                [
                    EvidenceConsistencyClass.BoundedNonAtomicObservation,
                    EvidenceConsistencyClass.ObjectVersionBound,
                    EvidenceConsistencyClass.ExactSnapshot,
                ]),
            SurfaceSet.Create([profileSurface ?? SurfaceKind.Repository]),
            materialRole,
            "protocol.target.repository-snapshot",
            Array.Empty<CapabilityContractIdentity>());

    private static ComponentTypeIdentity ResolveComponentIdentity(string componentKey) =>
        componentKey switch
        {
            "protocol.activation-proof.test" => ComponentTypeIdentity.Create(
                componentKey,
                "1",
                "MeAndAI.Protocol.Conformance.Tests",
                "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"),
            "protocol.codec.repository-tree" => ComponentTypeIdentity.Create(
                componentKey,
                "1",
                "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec"),
            "protocol.evaluator.test-rule" => ComponentTypeIdentity.Create(
                componentKey,
                "1",
                "MeAndAI.Protocol.Conformance.Tests",
                "MeAndAI.Protocol.Conformance.Tests.ContractSliceASchemaSlotEvaluator"),
            "protocol.type.model.repository-tree" => ComponentTypeIdentity.Create(
                componentKey,
                "1",
                "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel"),
            _ => throw new ArgumentOutOfRangeException(nameof(componentKey)),
        };

    private static IReadOnlyList<ArtifactFileBinding> CreateArtifacts() =>
    [
        ArtifactFileBinding.Create("ContractSliceA.Proof.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
        ArtifactFileBinding.Create("MeAndAI.Protocol.Policy.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
    ];

    private static IReadOnlyList<ComponentArtifactBinding> CreateComponents() =>
    [
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.activation-proof.test"), "ContractSliceA.Proof.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.codec.repository-tree"), "MeAndAI.Protocol.Policy.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.evaluator.test-rule"), "ContractSliceA.Proof.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.type.model.repository-tree"), "MeAndAI.Protocol.Policy.dll"),
    ];

    private static string ReplaceRequired(
        string value,
        string oldText,
        string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (oldText.Length == 0 || index < 0 ||
            value.IndexOf(oldText, index + oldText.Length, StringComparison.Ordinal) >= 0 ||
            string.Equals(oldText, newText, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                $"Required mutation marker was invalid or absent: {oldText}");
        }

        return value.Remove(index, oldText.Length).Insert(index, newText);
    }

    private static void AssertPublicFormatException(string manifest) =>
        Assert.Throws<FormatException>(() =>
            FinalizedPolicyManifest.ParseCanonical(Encoding.UTF8.GetBytes(manifest)));
}
