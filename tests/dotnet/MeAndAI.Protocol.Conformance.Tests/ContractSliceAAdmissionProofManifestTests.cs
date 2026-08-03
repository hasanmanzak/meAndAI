using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAAdmissionProofManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private const string ContractKey = "protocol.test.admission-proof";
    private static readonly string[] Fields = ["contractKey", "contractVersion", "kind", "proofComponent", "surfaces", "materialRoles"];
    private static readonly string[] Kinds = ["observed", "failed", "no-input"];
    private static readonly string[] Surfaces = ["repository", "provider"];
    private static readonly string[] Roles = ["protocol.material.governed-text", "protocol.material.repository-target-resolution", "protocol.material.repository-tree"];
    private static readonly string[] ProofKeys = Kinds.Select(kind => "protocol.admission-proof.test-" + kind).ToArray();
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
        (ProofKeys[1], "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestFailedAdmissionProof", "ContractSliceA.Proof.dll"),
        (ProofKeys[2], "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestNoInputAdmissionProof", "ContractSliceA.Proof.dll"),
        (ProofKeys[0], "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestObservedAdmissionProof", "ContractSliceA.Proof.dll"),
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
        ("protocol.selector.test-alpha", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestAlphaSelectorResolver", "ContractSliceA.Proof.dll"),
        ("protocol.selector.test-zeta", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestZetaSelectorResolver", "ContractSliceA.Proof.dll"),
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
    public void Enforces_admission_proof_declarations_with_exact_kind_component_and_artifact_closure()
    {
        var surfaceInput = new List<SurfaceKind> { SurfaceKind.Provider, SurfaceKind.Repository };
        var roleInput = Roles.Reverse().ToList();
        var surfaceSet = SurfaceSet.Create(surfaceInput);
        var admissionInput = new List<AdmissionProofContractDeclaration>
        {
            Admission(AdmissionProofKind.NoInput, surfaceSet, roleInput),
            Admission(AdmissionProofKind.Failed, surfaceSet, roleInput),
            Admission(AdmissionProofKind.Observed, surfaceSet, roleInput),
        };
        var parsed = CreateManifest(admissionInput, includeAdmissionComponents: true);
        var bytes = CanonicalManifestWriter.Write(parsed);
        surfaceInput.Clear(); roleInput.Clear(); admissionInput.Clear();
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        var registry = manifest.SchemaRegistry;
        Assert.Equal((3, 2, 4, 0, 4, 2, 2, 3, 25, 3), (registry.PayloadSchemas.Count, registry.Parsers.Count,
            registry.Indexes.Count, registry.DemandProjectors.Count, rule.EvaluationSlots.Count, rule.ExpectedSelectors.Count,
            rule.Findings.Count, registry.AdmissionProofContracts.Count, manifest.Components.Count, manifest.ArtifactFiles.Count));
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.Equal(Kinds, registry.AdmissionProofContracts.Select(item => item.Kind.Value));
        Assert.All(registry.AdmissionProofContracts, item =>
        {
            var expected = Spec("protocol.admission-proof.test-" + item.Kind.Value);
            Assert.Equal((ContractKey, "1", expected.Key, expected.Assembly, expected.Type),
                (item.ContractKey, item.ContractVersion, item.ProofComponent.ComponentKey, item.ProofComponent.AssemblyName, item.ProofComponent.TypeName));
            Assert.Equal(Surfaces, item.Surfaces.Values.Select(value => value.Value));
            Assert.Equal(Roles, item.MaterialRoles);
            Assert.Equal("ContractSliceA.Proof.dll", manifest.Components.Single(binding => binding.Component.ComponentKey == expected.Key).ArtifactFileName);
            Assert.True(registry.TryGetAdmissionProofContract(ContractKey, "1", item.Kind, out var found));
            Assert.Same(item, found);
        });
        Assert.False(registry.TryGetAdmissionProofContract("protocol.test.admission-proof.unknown", "1", AdmissionProofKind.Observed, out _));
        Assert.False(registry.TryGetAdmissionProofContract(ContractKey, "2", AdmissionProofKind.Observed, out _));
        using var document = JsonDocument.Parse(bytes);
        var wire = document.RootElement.GetProperty("schemaRegistry").GetProperty("admissionProofContracts");
        Assert.Equal(Kinds, wire.EnumerateArray().Select(item => item.GetProperty("kind").GetString()));
        Assert.All(wire.EnumerateArray(), item =>
        {
            Assert.Equal(Fields, item.EnumerateObject().Select(property => property.Name));
            Assert.Equal(["componentKey", "componentVersion"], item.GetProperty("proofComponent").EnumerateObject().Select(property => property.Name));
        });
        Assert.Equal(bytes, RewriteAdmissions(bytes, writer => WriteAdmissions(writer)));
        var mutations = new HashSet<string>(StringComparer.Ordinal);
        foreach (var field in Enumerable.Range(0, Fields.Length))
            foreach (var mutation in Enum.GetValues<FieldMutation>().Skip(1))
                Reject(bytes, mutations, writer => WriteAdmissions(writer, field, mutation));
        Reject(bytes, mutations, writer => WriteAdmissions(writer, extraField: true));
        foreach (var swap in Enumerable.Range(0, Fields.Length - 1))
            Reject(bytes, mutations, writer => WriteAdmissions(writer, adjacentSwap: swap));
        Reject(bytes, mutations, writer => WriteAdmissions(writer, unknownKind: true));
        foreach (var mutation in Enum.GetValues<CollectionMutation>().Skip(1))
            Reject(bytes, mutations, writer => WriteAdmissions(writer, collectionField: 4, collectionMutation: mutation));
        foreach (var mutation in Enum.GetValues<CollectionMutation>().Skip(1))
            Reject(bytes, mutations, writer => WriteAdmissions(writer, collectionField: 5, collectionMutation: mutation));
        foreach (var mutation in Enum.GetValues<ArrayMutation>().Skip(1))
            Reject(bytes, mutations, writer => WriteAdmissions(writer, arrayMutation: mutation));
        Assert.Equal(42, mutations.Count);
        RejectGraph(RewriteAdmissions(bytes, writer => WriteAdmissions(writer, kinds: [])));
        foreach (var key in ProofKeys) RejectGraph(RewriteComponents(bytes, [key]));
        var partial = RewriteAdmissions(bytes, writer => WriteAdmissions(writer, kinds: ["observed"]));
        RejectGraph(RewriteComponents(partial, [ProofKeys[1], ProofKeys[2]]));
        var shared = RewriteAdmissions(bytes, writer => WriteAdmissions(writer, failedProof: ProofKeys[0]));
        RejectGraph(RewriteComponents(shared, [ProofKeys[1]]));
        var activation = RewriteAdmissions(bytes, writer => WriteAdmissions(writer, failedProof: "protocol.activation-proof.test"));
        RejectGraph(RewriteComponents(activation, [ProofKeys[1]]));
        var functionalOverlap = RewriteAdmissions(bytes, writer => WriteAdmissions(writer,
            failedProof: "protocol.evaluator.test-rule"));
        RejectGraph(RewriteComponents(functionalOverlap, [ProofKeys[1]]));
        var distinctContractKey = RewriteAdmissions(bytes, writer => WriteAdmissions(writer,
            observedContractKey: "protocol.test.admission-proo"));
        var distinctContractKeyManifest = FinalizedPolicyManifest.ParseCanonical(distinctContractKey);
        Assert.Equal(distinctContractKey, CanonicalManifestWriter.Write(distinctContractKeyManifest));
        RejectGraph(RewriteAdmissions(bytes, writer => WriteAdmissions(writer,
            observedContractVersion: "0")));
        RejectGraph(RewriteComponents(bytes, [], badArtifact: true));
        RejectGraph(RewriteComponents(bytes, [], extraProof: true));
        var predecessor = RewriteComponents(RewriteAdmissions(bytes, writer => WriteAdmissions(writer, kinds: [])), ProofKeys);
        var predecessorManifest = FinalizedPolicyManifest.ParseCanonical(predecessor);
        Assert.Equal(predecessor, CanonicalManifestWriter.Write(predecessorManifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(predecessor)).ToLowerInvariant(), predecessorManifest.ManifestDigest.Value);
        Assert.Empty(predecessorManifest.SchemaRegistry.AdmissionProofContracts);
        Assert.Equal((22, 3), (predecessorManifest.Components.Count, predecessorManifest.ArtifactFiles.Count));
        Assert.Equal(CanonicalManifestWriter.Write(CreateManifest([], includeAdmissionComponents: false)), predecessor);
    }

    private static void WriteAdmissions(Utf8JsonWriter writer, int field = -1, FieldMutation fieldMutation = FieldMutation.Normal,
        int adjacentSwap = -1, int collectionField = -1, CollectionMutation collectionMutation = CollectionMutation.Normal,
        bool extraField = false, bool unknownKind = false, ArrayMutation arrayMutation = ArrayMutation.Normal,
        IReadOnlyList<string>? kinds = null, string? failedProof = null,
        string? observedContractKey = null, string? observedContractVersion = null)
    {
        kinds ??= Kinds; writer.WriteStartArray();
        if (arrayMutation == ArrayMutation.NullEntry) writer.WriteNullValue();
        else if (arrayMutation == ArrayMutation.Reversed) foreach (var kind in kinds.Reverse()) WriteAdmission(writer, kind);
        else if (arrayMutation == ArrayMutation.Duplicate) { WriteAdmission(writer, Kinds[0]); WriteAdmission(writer, Kinds[0]); }
        else foreach (var kind in kinds) WriteAdmission(writer, kind, kind == Kinds[0] ? field : -1, fieldMutation,
            kind == Kinds[0] ? adjacentSwap : -1, kind == Kinds[0] ? collectionField : -1, collectionMutation,
            kind == Kinds[0] && extraField, kind == Kinds[0] && unknownKind, failedProof,
            kind == Kinds[0] ? observedContractKey : null,
            kind == Kinds[0] ? observedContractVersion : null);
        writer.WriteEndArray();
    }

    private static void WriteAdmission(Utf8JsonWriter writer, string kind, int field = -1,
        FieldMutation mutation = FieldMutation.Normal, int adjacentSwap = -1, int collectionField = -1,
        CollectionMutation collectionMutation = CollectionMutation.Normal, bool extraField = false,
        bool unknownKind = false, string? failedProof = null,
        string? contractKey = null, string? contractVersion = null)
    {
        var order = Enumerable.Range(0, Fields.Length).ToArray();
        if (adjacentSwap >= 0) (order[adjacentSwap], order[adjacentSwap + 1]) = (order[adjacentSwap + 1], order[adjacentSwap]);
        writer.WriteStartObject();
        foreach (var current in order)
        {
            if (current == field && mutation == FieldMutation.Missing) continue;
            if (current == field && mutation == FieldMutation.Null) { writer.WriteNull(Fields[current]); continue; }
            if (current == field && mutation == FieldMutation.WrongType)
            { writer.WritePropertyName(Fields[current]); writer.WriteBooleanValue(false); continue; }
            WriteField(writer, current, unknownKind ? "unknown" : kind,
                current == collectionField ? collectionMutation : CollectionMutation.Normal,
                failedProof, contractKey, contractVersion);
            if (current == field && mutation == FieldMutation.Duplicate)
                WriteField(writer, current, kind, CollectionMutation.Normal,
                    failedProof, contractKey, contractVersion);
            if (extraField && current == Fields.Length - 1) writer.WriteString("unexpectedAdmissionProperty", "unexpected");
        }
        writer.WriteEndObject();
    }

    private static void WriteField(Utf8JsonWriter writer, int field, string kind,
        CollectionMutation mutation, string? failedProof, string? contractKey,
        string? contractVersion)
    {
        switch (field)
        {
            case 0: writer.WriteString(Fields[field], contractKey ?? ContractKey); break;
            case 1: writer.WriteString(Fields[field], contractVersion ?? "1"); break;
            case 2: writer.WriteString(Fields[field], kind); break;
            case 3:
                writer.WritePropertyName(Fields[field]); writer.WriteStartObject();
                writer.WriteString("componentKey", kind == "failed" && failedProof is not null ? failedProof : "protocol.admission-proof.test-" + kind);
                writer.WriteString("componentVersion", "1"); writer.WriteEndObject(); break;
            case 4: WriteValues(writer, Fields[field], Surfaces, mutation, "unknown-surface"); break;
            case 5: WriteValues(writer, Fields[field], Roles, mutation, "protocol.material.undeclared"); break;
            default: throw new ArgumentOutOfRangeException(nameof(field));
        }
    }

    private static void WriteValues(Utf8JsonWriter writer, string property, IReadOnlyList<string> canonical,
        CollectionMutation mutation, string unknown)
    {
        IEnumerable<string> values = mutation switch
        {
            CollectionMutation.Unknown => [unknown],
            CollectionMutation.Duplicate => canonical.Prepend(canonical[0]),
            CollectionMutation.Reversed => canonical.Reverse(),
            CollectionMutation.Empty => [],
            _ => canonical,
        };
        writer.WriteStartArray(property); foreach (var value in values) writer.WriteStringValue(value); writer.WriteEndArray();
    }

    private static byte[] RewriteAdmissions(byte[] canonical, Action<Utf8JsonWriter> write)
    {
        using var document = JsonDocument.Parse(canonical);
        var admissions = document.RootElement.GetProperty("schemaRegistry").GetProperty("admissionProofContracts");
        return Rewrite(canonical, Encoding.UTF8.GetBytes(admissions.GetRawText()), write);
    }

    private static byte[] RewriteComponents(byte[] canonical, IEnumerable<string> removedKeys, bool badArtifact = false, bool extraProof = false)
    {
        using var document = JsonDocument.Parse(canonical);
        var components = document.RootElement.GetProperty("components");
        var removed = removedKeys.ToHashSet(StringComparer.Ordinal);
        return Rewrite(canonical, Encoding.UTF8.GetBytes(components.GetRawText()), writer =>
        {
            writer.WriteStartArray();
            foreach (var item in components.EnumerateArray())
            {
                var component = item.GetProperty("component"); var key = component.GetProperty("componentKey").GetString()!;
                if (extraProof && key == ProofKeys[1]) WriteComponent(writer, "protocol.admission-proof.test-extra",
                    "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestExtraAdmissionProof", "ContractSliceA.Proof.dll");
                if (removed.Contains(key)) continue;
                if (badArtifact && key == ProofKeys[0]) WriteComponent(writer, key, component.GetProperty("assemblyName").GetString()!,
                    component.GetProperty("typeName").GetString()!, "Undeclared.dll");
                else item.WriteTo(writer);
            }
            writer.WriteEndArray();
        });
    }

    private static void WriteComponent(Utf8JsonWriter writer, string key, string assembly, string type, string artifact)
    {
        writer.WriteStartObject(); writer.WritePropertyName("component"); writer.WriteStartObject();
        writer.WriteString("componentKey", key); writer.WriteString("componentVersion", "1");
        writer.WriteString("assemblyName", assembly); writer.WriteString("typeName", type); writer.WriteEndObject();
        writer.WriteString("artifactFileName", artifact); writer.WriteEndObject();
    }

    private static byte[] Rewrite(byte[] source, byte[] needle, Action<Utf8JsonWriter> write)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping })) write(writer);
        var replacement = stream.ToArray(); var index = source.AsSpan().IndexOf(needle);
        if (index < 0 || source.AsSpan(index + needle.Length).IndexOf(needle) >= 0) throw new InvalidOperationException("The fixture segment must occur exactly once.");
        var result = new byte[source.Length - needle.Length + replacement.Length];
        source.AsSpan(0, index).CopyTo(result); replacement.CopyTo(result, index);
        source.AsSpan(index + needle.Length).CopyTo(result.AsSpan(index + replacement.Length));
        if (source[^1] != (byte)'\n' || result[^1] != (byte)'\n') throw new InvalidOperationException("Terminal LF was not preserved.");
        return result;
    }

    private static void Reject(byte[] canonical, HashSet<string> mutations, Action<Utf8JsonWriter> write)
    {
        var mutated = RewriteAdmissions(canonical, write); Assert.False(canonical.AsSpan().SequenceEqual(mutated));
        using var document = JsonDocument.Parse(mutated); Assert.True(mutations.Add(Convert.ToBase64String(mutated)));
        Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated));
    }

    private static void RejectGraph(byte[] mutated)
    { using var document = JsonDocument.Parse(mutated); Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated)); }

    private static AdmissionProofContractDeclaration Admission(AdmissionProofKind kind, SurfaceSet surfaces, IEnumerable<string> roles) =>
        AdmissionProofContractDeclaration.Create(ContractKey, "1", kind, Resolve("protocol.admission-proof.test-" + kind.Value), surfaces, roles);
    private static ParsedCanonicalManifest CreateManifest(IEnumerable<AdmissionProofContractDeclaration> admissions, bool includeAdmissionComponents) => new(
        CatalogAuthorityKind.QualificationSlice, Commit, CreateRegistry(admissions),
        ActivationProofContractDeclaration.Create("protocol.activation-proof.test", "1.0.0", Resolve("protocol.activation-proof.test")),
        new[] { "ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll" }.Select(Artifact).ToArray(),
        Components.Where(item => includeAdmissionComponents || !ProofKeys.Contains(item.Key, StringComparer.Ordinal)).Select(item => ComponentArtifactBinding.Create(Resolve(item.Key), item.Artifact)).ToArray(),
        CatalogSliceDeclaration.Create("protocol.test.catalog-slice.selector", "1", "0.0.0", CatalogVersion.Create(1), [CreateRule()]));
    private static ReleaseSchemaRegistry CreateRegistry(IEnumerable<AdmissionProofContractDeclaration> admissions) => ReleaseSchemaRegistry.Create([TreeSchema(), TargetSchema(), GovernedSchema()], [TargetParser(), MarkdownParser()], [TreeIndex(), TargetIndex(), RecordIndex(), GovernedIndex()], [], admissions, SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static RuleDeclaration CreateRule() => RuleDeclaration.Create(RuleId.Parse("RULE-9999"), RuleRevision.Create(1), CatalogVersion.Create(1), ExactSha256Digest.Parse(Digest),
        [NormativeFragmentDeclaration.Create("docs/test-fixtures/selector-contract.md", Blob, "selector-contract", 1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))], [TestScenarioId.Parse("TEST-0001")], Resolve("protocol.evaluator.test-rule"), [],
        [TreeSlot(), TargetSlot(), RepositoryGovernedSlot(), ProviderGovernedSlot()], [Selector("zeta", "protocol.slot.repository-governed-text"), Selector("alpha", "protocol.slot.repository-tree")], [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]), [SnapshotKind.ExactCommit], [ProtocolOperation.Conformance],
        [Finding("protocol.test.finding.zeta"), Finding("protocol.test.finding.alpha")], [], "1.0.0", null, null, []);
    private static ExpectedSelectorDeclaration Selector(string suffix, string slot) => ExpectedSelectorDeclaration.Create("protocol.test.selector." + suffix, slot, "protocol.test.selector-schema." + suffix, Resolve("protocol.selector.test-" + suffix), suffix == "alpha" ? [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.ContextProof] : [QualifiedEvidenceReferenceKind.Derived], suffix == "alpha" ? [FindingCode.Parse("protocol.test.finding.zeta"), FindingCode.Parse("protocol.test.finding.alpha")] : [FindingCode.Parse("protocol.test.finding.zeta")]);
    private static FindingDeclaration Finding(string code) => FindingDeclaration.Create(FindingCode.Parse(code), FindingSeverity.Parse("protocol.test.severity." + (code.EndsWith("alpha", StringComparison.Ordinal) ? "alpha" : "zeta")), RemediationKey.Parse("protocol.test.remediation." + (code.EndsWith("alpha", StringComparison.Ordinal) ? "alpha" : "zeta")), code.EndsWith("alpha", StringComparison.Ordinal) ? [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.ContextProof] : [QualifiedEvidenceReferenceKind.Root], code.EndsWith("alpha", StringComparison.Ordinal) ? [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.ContextProof] : []);
    private static PayloadSchemaDeclaration GovernedSchema() => PayloadSchemaDeclaration.Create("protocol.governed-text", "1", Resolve("protocol.codec.governed-text"), SourceModel(), 200_000, 67_108_864, MarkdownBudget(), GovernedCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TargetSchema() => PayloadSchemaDeclaration.Create("protocol.repository-target-resolution", "1", Resolve("protocol.codec.repository-target-resolution"), TargetResolutionModel(), 1, 33_554_432, TargetSchemaBudget(), TargetCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TreeSchema() => PayloadSchemaDeclaration.Create("protocol.repository-tree", "1", Resolve("protocol.codec.repository-tree"), TreeModel(), 1, 16_777_216, TreeBudget(), TreeCodecFailures.Reverse());
    private static SemanticModelParserDeclaration MarkdownParser() => SemanticModelParserDeclaration.Create("protocol.parser.markdown", "1", Resolve("protocol.parser.markdown"), [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)], MarkdownModel(), MarkdownBudget(), MarkdownParserFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static SemanticModelParserDeclaration TargetParser() => SemanticModelParserDeclaration.Create("protocol.parser.repository-target-markdown", "1", Resolve("protocol.parser.repository-target-markdown"), [ComponentInputDeclaration.ForModel(TargetResolutionModel(), 1, 1)], TargetMarkdownModel(), TargetParserBudget(), TargetParserFailures.Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration GovernedIndex() => ContextIndexDeclaration.Create("protocol.index.governed-reference", "1", Resolve("protocol.index.governed-reference"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(RecordCapability(), 1, null), ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], GovernedCapability(), GovernedBudget(), GovernedIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration RecordIndex() => ContextIndexDeclaration.Create("protocol.index.protocol-record", "1", Resolve("protocol.index.protocol-record"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], RecordCapability(), GovernedBudget(), RecordFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TargetIndex() => ContextIndexDeclaration.Create("protocol.index.repository-target-resolution", "1", Resolve("protocol.index.repository-target-resolution"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(GovernedCapability(), 1, 1), ComponentInputDeclaration.ForModel(TargetResolutionModel(), 0, null), ComponentInputDeclaration.ForModel(TargetMarkdownModel(), 0, null)], TargetCapability(), TargetIndexBudget(), TargetIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TreeIndex() => ContextIndexDeclaration.Create("protocol.index.repository-tree", "1", Resolve("protocol.index.repository-tree"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)], TreeCapability(), TreeBudget(), TreeIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
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

    private enum FieldMutation { Normal, Missing, Duplicate, Null, WrongType }
    private enum CollectionMutation { Normal, Unknown, Duplicate, Reversed, Empty }
    private enum ArrayMutation { Normal, NullEntry, Reversed, Duplicate }
}
