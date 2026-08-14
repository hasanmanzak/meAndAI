using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAProjectorDagManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private const string ProjectorKey = "protocol.projector.repository-target-resolution-demand";
    private const string GovernedIndexKey = "protocol.index.governed-reference";
    private const string GovernedTypeKey = "protocol.type.capability.governed-reference-index";
    private const string ExtraIndexKey = "protocol.index.governed-reference.extra";
    private const string ExtraProjectorKey = "protocol.projector.repository-target-resolution-demand.extra";
    private const string UnusedParserKey = "protocol.parser.markdown.unused";
    private const string UnusedModelKey = "protocol.model.markdown-document.unused";
    private const string UnusedModelTypeKey = "protocol.type.model.markdown-document.unused";
    private const string EnvelopeDiagnostic = "protocol.manifest.projector-array-envelope";
    private const string WireDiagnostic = "protocol.manifest.projector-row-wire";
    private const string ValueDiagnostic = "protocol.manifest.projector-value";
    private const string SlotDiagnostic = "protocol.manifest.projector-slot";
    private static readonly string[] Fields = ["projectorKey", "projectorVersion", "projector", "inputCapability", "inputSlotKeys", "outputSlotKey", "demandSchemaKey", "demandSchemaVersion", "budget", "failureCodes"];
    private static readonly string[] ProofKinds = ["observed", "failed", "no-input"], ProofKeys = ProofKinds.Select(kind => "protocol.admission-proof.test-" + kind).ToArray();
    private static readonly string[] MarkdownFailures = ["protocol.budget.exhausted", "protocol.model.invalid-markdown"], GovernedFailures = ["protocol.budget.exhausted", "protocol.index.reference-unavailable"];
    private static readonly string[] RecordFailures = ["protocol.budget.exhausted", "protocol.index.record-unavailable"], TargetIndexFailures = ["protocol.budget.exhausted", "protocol.index.repository-target-resolution-unavailable"], TreeIndexFailures = ["protocol.budget.exhausted", "protocol.index.repository-tree-unavailable"];
    private static readonly string[] GovernedCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-utf8", "protocol.codec.noncanonical-encoding", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"], TargetCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-target-resolution", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TreeCodecFailures = ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-tree", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly (string Key, string Assembly, string Type, string Artifact)[] Components =
    [
        ("protocol.activation-proof.test", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof", "ContractSliceA.Proof.dll"), (ProofKeys[1], "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestFailedAdmissionProof", "ContractSliceA.Proof.dll"),
        (ProofKeys[2], "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestNoInputAdmissionProof", "ContractSliceA.Proof.dll"), (ProofKeys[0], "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestObservedAdmissionProof", "ContractSliceA.Proof.dll"),
        ("protocol.codec.governed-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec", "MeAndAI.Protocol.Policy.dll"), ("protocol.codec.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.codec.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec", "MeAndAI.Protocol.Policy.dll"), ("protocol.evaluator.test-rule", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceAIndexSlotEvaluator", "ContractSliceA.Proof.dll"),
        (GovernedIndexKey, "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex", "MeAndAI.Protocol.Policy.dll"), ("protocol.index.protocol-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.index.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex", "MeAndAI.Protocol.Policy.dll"), ("protocol.index.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.parser.markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser", "MeAndAI.Protocol.Policy.dll"), ("protocol.parser.repository-target-markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser", "MeAndAI.Protocol.Policy.dll"),
        (ProjectorKey, "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector", "MeAndAI.Protocol.Policy.dll"), ("protocol.selector.test-alpha", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestAlphaSelectorResolver", "ContractSliceA.Proof.dll"),
        ("protocol.selector.test-zeta", "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestZetaSelectorResolver", "ContractSliceA.Proof.dll"), (GovernedTypeKey, "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.protocol-record-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"), ("protocol.type.capability.repository-target-resolution-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ("protocol.type.capability.repository-tree", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree", "MeAndAI.Protocol.Conformance.Abstractions.dll"), ("protocol.type.model.markdown-document", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-target-markdown-document-set", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel", "MeAndAI.Protocol.Policy.dll"), ("protocol.type.model.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel", "MeAndAI.Protocol.Policy.dll"),
        ("protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel", "MeAndAI.Protocol.Policy.dll"), ("protocol.type.model.source-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.SourceTextModel", "MeAndAI.Protocol.Policy.dll"),
    ];
    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_exact_projector_bindings_and_global_producer_graph()
    {
        var bytes = CanonicalManifestWriter.Write(CreateManifest(includeProjector: true));
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        var rule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        var projector = Assert.Single(manifest.SchemaRegistry.DemandProjectors);
        Assert.Equal((3, 2, 4, 1, 4, 2, 2, 3, 26, 3), (manifest.SchemaRegistry.PayloadSchemas.Count,
            manifest.SchemaRegistry.Parsers.Count, manifest.SchemaRegistry.Indexes.Count, manifest.SchemaRegistry.DemandProjectors.Count,
            rule.EvaluationSlots.Count, rule.ExpectedSelectors.Count, rule.Findings.Count,
            manifest.SchemaRegistry.AdmissionProofContracts.Count, manifest.Components.Count, manifest.ArtifactFiles.Count));
        Assert.Equal((ProjectorKey, "1", ProjectorKey, "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector"),
            (projector.ProjectorKey, projector.ProjectorVersion, projector.Projector.ComponentKey, projector.Projector.AssemblyName, projector.Projector.TypeName));
        Assert.Equal(("protocol.capability.governed-reference-index", "1", GovernedTypeKey),
            (projector.InputCapability.CapabilityKey, projector.InputCapability.CapabilityVersion, projector.InputCapability.InterfaceType.ComponentKey));
        Assert.Equal(["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text"], projector.InputSlotKeys);
        Assert.Equal(("protocol.slot.repository-target-resolution", "protocol.repository-target-resolution-demand", "1"),
            (projector.OutputSlotKey, projector.DemandSchemaKey, projector.DemandSchemaVersion));
        Assert.Equal((33_554_432L, 64, 100_000L, 5_000_000L),
            (projector.Budget.MaxBytes, projector.Budget.MaxDepth, projector.Budget.MaxNodes, projector.Budget.MaxComplexity));
        Assert.Equal(["protocol.budget.exhausted"], projector.FailureCodes.Select(code => code.Value));
        Assert.Equal("MeAndAI.Protocol.Policy.dll", manifest.Components.Single(item => item.Component.ComponentKey == ProjectorKey).ArtifactFileName);
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.Equal(["ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll"], manifest.ArtifactFiles.Select(item => item.FileName));
        Assert.True(CatalogSliceDeclaration.ValidateSchemaSlotClosure(manifest.SchemaRegistry, [rule]).ProducerRootIdentities.SetEquals(
            [new ProducerIdentity("Schema", "protocol.governed-text", "1"), new ProducerIdentity("Schema", "protocol.repository-tree", "1")]));
        using (var document = JsonDocument.Parse(bytes))
            Assert.Equal(Fields, ProjectorArray(document.RootElement)[0].EnumerateObject().Select(property => property.Name));

        var mutations = new HashSet<string>(StringComparer.Ordinal);
        foreach (var field in Enumerable.Range(0, Fields.Length))
            foreach (var mutation in Enum.GetValues<FieldMutation>().Skip(1))
                Reject(RewriteProjector(bytes, field, mutation), WireDiagnostic, mutations);
        Reject(RewriteProjector(bytes, extraField: true), WireDiagnostic, mutations);
        foreach (var swap in Enumerable.Range(0, Fields.Length - 1))
            Reject(RewriteProjector(bytes, adjacentSwap: swap), WireDiagnostic, mutations);
        Assert.Equal(50, mutations.Count);
        foreach (var mutation in Enum.GetValues<EnvelopeMutation>())
            Reject(RewriteEnvelope(bytes, mutation), EnvelopeDiagnostic, mutations);
        Assert.Equal(54, mutations.Count);
        foreach (var mutation in Enum.GetValues<ValueMutation>().Skip(1))
            Reject(RewriteValue(bytes, mutation), mutation is ValueMutation.RemoveProviderSlot or ValueMutation.RemoveRepositorySlot ? SlotDiagnostic : ValueDiagnostic, mutations);
        Assert.Equal(81, mutations.Count);
        foreach (var mutation in Enum.GetValues<TopologyMutation>().Skip(1))
            Reject(RewriteTopology(bytes, mutation), TopologyDiagnostic(mutation), mutations);
        Assert.Equal(103, mutations.Count);
        Assert.Equal([50, 4, 27, 22], new[] { 50, 54 - 50, 81 - 54, mutations.Count - 81 });

        var predecessor = RewriteComponents(RewriteProjectors(bytes, (_, _) => { }), removeKey: ProjectorKey);
        var predecessorManifest = FinalizedPolicyManifest.ParseCanonical(predecessor);
        Assert.Equal(predecessor, CanonicalManifestWriter.Write(predecessorManifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(predecessor)).ToLowerInvariant(), predecessorManifest.ManifestDigest.Value);
        Assert.Equal((25, 3, 0), (predecessorManifest.Components.Count, predecessorManifest.ArtifactFiles.Count, predecessorManifest.SchemaRegistry.DemandProjectors.Count));
        var predecessorRule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(predecessorManifest.Slice).Rules);
        Assert.True(CatalogSliceDeclaration.ValidateSchemaSlotClosure(predecessorManifest.SchemaRegistry, [predecessorRule]).ProducerRootIdentities.SetEquals(
            [new ProducerIdentity("Schema", "protocol.governed-text", "1"), new ProducerIdentity("Schema", "protocol.repository-target-resolution", "1"), new ProducerIdentity("Schema", "protocol.repository-tree", "1")]));
        Assert.Equal(CanonicalManifestWriter.Write(CreateManifest(includeProjector: false)), predecessor);
    }
    private static byte[] RewriteProjector(byte[] source, int field = -1, FieldMutation fieldMutation = FieldMutation.Normal,
        int adjacentSwap = -1, bool extraField = false) => RewriteProjectors(source, (writer, row) =>
            WriteProjector(writer, row, field, fieldMutation, adjacentSwap, extraField));
    private static byte[] RewriteEnvelope(byte[] source, EnvelopeMutation mutation) => RewriteRegistryArray(source, "demandProjectors", (writer, rows) =>
    {
        var row = rows[0];
        if (mutation == EnvelopeMutation.NullArray) { writer.WriteNullValue(); return; }
        if (mutation == EnvelopeMutation.Object) { writer.WriteStartObject(); writer.WriteEndObject(); return; }
        writer.WriteStartArray(); if (mutation == EnvelopeMutation.NullElement) writer.WriteNullValue();
        else { row.WriteTo(writer); row.WriteTo(writer); }
        writer.WriteEndArray();
    });
    private static byte[] RewriteValue(byte[] source, ValueMutation mutation)
    {
        var result = RewriteProjectors(source, (writer, row) => WriteProjector(writer, row, value: mutation));
        if (mutation == ValueMutation.AlternateComponent) result = RewriteComponents(result, ProjectorKey, [Binding.Test("protocol.projector.repository-target-resolution-demand.alt", "ContractSliceAAlternateProjector")]);
        else if (mutation == ValueMutation.ComponentVersion2) result = RewriteComponents(result, ProjectorKey, [Binding.Policy(ProjectorKey, "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector", "MeAndAI.Protocol.Policy.dll", "2")]);
        else if (mutation == ValueMutation.InterfaceVersion2) result = RewriteComponents(result, additions: [Binding.Test(GovernedTypeKey, "ContractSliceATestGovernedReferenceV2", "2")]);
        else if (mutation == ValueMutation.RemoveProviderSlot) result = RewriteRule(result, "protocol.slot.provider-governed-text");
        else if (mutation == ValueMutation.RemoveRepositorySlot) result = RewriteRule(result, "protocol.slot.repository-governed-text");
        return result;
    }
    private static byte[] RewriteTopology(byte[] source, TopologyMutation mutation)
    {
        if (mutation == TopologyMutation.RemoveProjectorComponent) return RewriteComponents(source, ProjectorKey);
        if (mutation == TopologyMutation.DuplicateProjectorComponent) return RewriteComponents(source, duplicateKey: ProjectorKey);
        if (mutation == TopologyMutation.DeclarationFreeComponent) return RewriteComponents(source, additions: [Binding.Test("protocol.projector.unexpected", "ContractSliceATestUnexpectedProjector")]);
        if (mutation == TopologyMutation.MissingArtifact) return RewriteComponents(source, replaceKey: ProjectorKey, replacement: Binding.Policy(ProjectorKey, "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector", "Missing.Projector.dll"));
        if (mutation == TopologyMutation.RemoveProjectorDeclaration) return RewriteProjectors(source, (_, _) => { });
        if (mutation is >= TopologyMutation.ReuseActivation and <= TopologyMutation.ReuseGovernedCapability || mutation is TopologyMutation.ReuseSelector or TopologyMutation.ReuseEvaluator)
            return RewriteComponents(RewriteProjectors(source, (writer, row) => WriteProjector(writer, row, componentKey: ReusedComponent(mutation))), ProjectorKey);
        if (mutation == TopologyMutation.RemoveProviderCapability) return RewriteRule(source, capabilitySlot: "protocol.slot.provider-governed-text");
        if (mutation == TopologyMutation.RemoveRepositoryCapability) return RewriteRule(source, capabilitySlot: "protocol.slot.repository-governed-text");
        if (mutation == TopologyMutation.RemoveGovernedProducer) return RewriteComponents(RewriteIndexes(source, mutation), GovernedIndexKey);
        if (mutation == TopologyMutation.SecondCapabilityProducer) return RewriteComponents(RewriteIndexes(source, mutation), additions: [Binding.Test(ExtraIndexKey, "ContractSliceATestSecondGovernedIndex")]);
        if (mutation == TopologyMutation.SecondSlotProducer) return RewriteComponents(RewriteProjectors(source, (writer, row) => { row.WriteTo(writer); WriteProjector(writer, row, componentKey: ExtraProjectorKey, projectorKey: ExtraProjectorKey); }), additions: [Binding.Test(ExtraProjectorKey, "ContractSliceATestSecondProjector")]);
        if (mutation == TopologyMutation.ApplicabilityOutput) return RewriteRule(source, moveTargetToApplicability: true);
        if (mutation == TopologyMutation.ProducerCycle) return RewriteIndexes(source, mutation);
        if (mutation == TopologyMutation.UnreachableParser) return RewriteComponents(RewriteParsers(source), additions: [Binding.Test(UnusedParserKey, "ContractSliceATestUnusedParser"), Binding.Test(UnusedModelTypeKey, "ContractSliceATestUnusedModel")]);
        throw new ArgumentOutOfRangeException(nameof(mutation));
    }
    private static string TopologyDiagnostic(TopologyMutation mutation) => mutation switch
    {
        TopologyMutation.RemoveProjectorComponent or TopologyMutation.DuplicateProjectorComponent or TopologyMutation.DeclarationFreeComponent or TopologyMutation.RemoveProjectorDeclaration => "protocol.manifest.component-closure",
        TopologyMutation.MissingArtifact => "protocol.manifest.artifact-owner",
        >= TopologyMutation.ReuseActivation and <= TopologyMutation.ReuseGovernedCapability or TopologyMutation.ReuseSelector or TopologyMutation.ReuseEvaluator => "protocol.manifest.functional-role-collision",
        TopologyMutation.RemoveProviderCapability or TopologyMutation.RemoveRepositoryCapability or TopologyMutation.ApplicabilityOutput => SlotDiagnostic,
        TopologyMutation.RemoveGovernedProducer or TopologyMutation.SecondCapabilityProducer or TopologyMutation.SecondSlotProducer => "protocol.manifest.producer-owner",
        TopologyMutation.ProducerCycle => "protocol.manifest.producer-cycle",
        TopologyMutation.UnreachableParser => "protocol.manifest.producer-unreachable",
        _ => throw new ArgumentOutOfRangeException(nameof(mutation)),
    };
    private static string ReusedComponent(TopologyMutation mutation) => mutation switch
    {
        TopologyMutation.ReuseActivation => "protocol.activation-proof.test",
        TopologyMutation.ReuseObservedProof => ProofKeys[0],
        TopologyMutation.ReuseGovernedCodec => "protocol.codec.governed-text",
        TopologyMutation.ReuseSourceModel => "protocol.type.model.source-text",
        TopologyMutation.ReuseMarkdownParser => "protocol.parser.markdown",
        TopologyMutation.ReuseGovernedIndex => GovernedIndexKey,
        TopologyMutation.ReuseGovernedCapability => GovernedTypeKey,
        TopologyMutation.ReuseSelector => "protocol.selector.test-alpha",
        TopologyMutation.ReuseEvaluator => "protocol.evaluator.test-rule",
        _ => throw new ArgumentOutOfRangeException(nameof(mutation)),
    };
    private static void WriteProjector(Utf8JsonWriter writer, JsonElement row, int field = -1,
        FieldMutation fieldMutation = FieldMutation.Normal, int adjacentSwap = -1, bool extraField = false,
        ValueMutation value = ValueMutation.Normal, string? componentKey = null, string? projectorKey = null)
    {
        var order = Enumerable.Range(0, Fields.Length).ToArray();
        if (adjacentSwap >= 0) (order[adjacentSwap], order[adjacentSwap + 1]) = (order[adjacentSwap + 1], order[adjacentSwap]);
        writer.WriteStartObject();
        foreach (var current in order)
        {
            if (current == field && fieldMutation == FieldMutation.Missing) continue;
            if (current == field && fieldMutation == FieldMutation.Null) writer.WriteNull(Fields[current]);
            else if (current == field && fieldMutation == FieldMutation.WrongType) { writer.WritePropertyName(Fields[current]); writer.WriteBooleanValue(false); }
            else WriteProjectorField(writer, row, current, value, componentKey, projectorKey);
            if (current == field && fieldMutation == FieldMutation.Duplicate) WriteProjectorField(writer, row, current, ValueMutation.Normal, null, null);
        }
        if (extraField) writer.WriteString("unexpectedProjectorProperty", "unexpected");
        writer.WriteEndObject();
    }
    private static void WriteProjectorField(Utf8JsonWriter writer, JsonElement row, int field, ValueMutation mutation, string? componentKey, string? projectorKey)
    {
        if (field == 0 && (mutation == ValueMutation.AlternateKey || projectorKey is not null)) { writer.WriteString(Fields[field], projectorKey ?? "protocol.projector.alternate"); return; }
        if (field == 1 && mutation == ValueMutation.Version2) { writer.WriteString(Fields[field], "2"); return; }
        if (field == 2 && (mutation is ValueMutation.AlternateComponent or ValueMutation.ComponentVersion2 || componentKey is not null))
        { WriteReference(writer, Fields[field], componentKey ?? (mutation == ValueMutation.AlternateComponent ? "protocol.projector.repository-target-resolution-demand.alt" : ProjectorKey), mutation == ValueMutation.ComponentVersion2 ? "2" : "1"); return; }
        if (field == 3 && mutation is >= ValueMutation.RecordCapabilityKey and <= ValueMutation.InterfaceVersion2) { WriteInputCapability(writer, mutation); return; }
        if (field == 4 && mutation is >= ValueMutation.EmptyInputs and <= ValueMutation.OutputAmongInputs) { WriteInputSlots(writer, mutation); return; }
        if (field == 5 && mutation == ValueMutation.TreeOutput) { writer.WriteString(Fields[field], "protocol.slot.repository-tree"); return; }
        if (field == 6 && mutation == ValueMutation.AlternateDemandSchema) { writer.WriteString(Fields[field], "protocol.repository-target-resolution-demand.alt"); return; }
        if (field == 7 && mutation == ValueMutation.DemandVersion2) { writer.WriteString(Fields[field], "2"); return; }
        if (field == 8 && mutation is >= ValueMutation.MaxBytesOne and <= ValueMutation.MaxComplexityOne) { WriteBudget(writer, mutation); return; }
        if (field == 9 && mutation is >= ValueMutation.EmptyFailures and <= ValueMutation.SupersetFailures) { WriteFailures(writer, mutation); return; }
        writer.WritePropertyName(Fields[field]); row.GetProperty(Fields[field]).WriteTo(writer);
    }
    private static void WriteInputCapability(Utf8JsonWriter writer, ValueMutation mutation)
    {
        writer.WriteStartObject("inputCapability");
        writer.WriteString("capabilityKey", mutation == ValueMutation.RecordCapabilityKey ? "protocol.capability.protocol-record-index" : "protocol.capability.governed-reference-index");
        writer.WriteString("capabilityVersion", mutation == ValueMutation.CapabilityVersion2 ? "2" : "1");
        WriteReference(writer, "interfaceType", mutation == ValueMutation.RecordInterface ? "protocol.type.capability.protocol-record-index" : GovernedTypeKey, mutation == ValueMutation.InterfaceVersion2 ? "2" : "1");
        writer.WriteEndObject();
    }
    private static void WriteInputSlots(Utf8JsonWriter writer, ValueMutation mutation)
    {
        writer.WriteStartArray("inputSlotKeys");
        string?[] values = mutation switch
        {
            ValueMutation.EmptyInputs => [],
            ValueMutation.NullInput => [null],
            ValueMutation.DuplicateProvider => ["protocol.slot.provider-governed-text", "protocol.slot.provider-governed-text"],
            ValueMutation.ReversedInputs => ["protocol.slot.repository-governed-text", "protocol.slot.provider-governed-text"],
            ValueMutation.UnknownInput => ["protocol.slot.provider-governed-text", "protocol.slot.unknown"],
            _ => ["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text", "protocol.slot.repository-target-resolution"]
        };
        foreach (var value in values) if (value is null) writer.WriteNullValue(); else writer.WriteStringValue(value); writer.WriteEndArray();
    }
    private static void WriteBudget(Utf8JsonWriter writer, ValueMutation mutation)
    {
        writer.WriteStartObject("budget"); writer.WriteNumber("maxBytes", mutation == ValueMutation.MaxBytesOne ? 1 : 33_554_432); writer.WriteNumber("maxDepth", mutation == ValueMutation.MaxDepthOne ? 1 : 64);
        writer.WriteNumber("maxNodes", mutation == ValueMutation.MaxNodesOne ? 1 : 100_000); writer.WriteNumber("maxComplexity", mutation == ValueMutation.MaxComplexityOne ? 1 : 5_000_000); writer.WriteEndObject();
    }
    private static void WriteFailures(Utf8JsonWriter writer, ValueMutation mutation)
    {
        writer.WriteStartArray("failureCodes"); if (mutation == ValueMutation.NullFailure) writer.WriteNullValue(); else if (mutation != ValueMutation.EmptyFailures) writer.WriteStringValue("protocol.budget.exhausted");
        if (mutation == ValueMutation.DuplicateFailure) writer.WriteStringValue("protocol.budget.exhausted");
        else if (mutation == ValueMutation.SupersetFailures) writer.WriteStringValue("protocol.projector.unexpected-failure"); writer.WriteEndArray();
    }
    private static byte[] RewriteProjectors(byte[] source, Action<Utf8JsonWriter, JsonElement> writeRows) => RewriteRegistryArray(source, "demandProjectors", (writer, rows) =>
    { writer.WriteStartArray(); if (rows.GetArrayLength() > 0) writeRows(writer, rows[0]); writer.WriteEndArray(); });
    private static byte[] RewriteIndexes(byte[] source, TopologyMutation mutation) => RewriteRegistryArray(source, "indexes", (writer, rows) =>
    {
        writer.WriteStartArray();
        foreach (var row in rows.EnumerateArray())
        {
            var key = row.GetProperty("indexKey").GetString();
            if (mutation == TopologyMutation.RemoveGovernedProducer && key == GovernedIndexKey) continue;
            row.WriteTo(writer);
            if (mutation == TopologyMutation.SecondCapabilityProducer && key == GovernedIndexKey) WriteRenamed(row, writer, GovernedIndexKey, ExtraIndexKey);
        }
        writer.WriteEndArray();
    }, mutation == TopologyMutation.ProducerCycle ? (writer, row) => WriteIndexCycle(writer, row) : null);
    private static byte[] RewriteParsers(byte[] source) => RewriteRegistryArray(source, "parsers", (writer, rows) =>
    {
        writer.WriteStartArray();
        foreach (var row in rows.EnumerateArray())
        {
            row.WriteTo(writer);
            if (row.GetProperty("parserKey").GetString() == "protocol.parser.markdown")
                WriteRenamed(row, writer, "protocol.parser.markdown", UnusedParserKey,
                    ("protocol.model.markdown-document", UnusedModelKey), ("protocol.type.model.markdown-document", UnusedModelTypeKey));
        }
        writer.WriteEndArray();
    });
    private static void WriteIndexCycle(Utf8JsonWriter writer, JsonElement row)
    {
        writer.WriteStartObject(); foreach (var property in row.EnumerateObject())
        {
            if (property.Name != "inputs") { property.WriteTo(writer); continue; }
            writer.WriteStartArray("inputs"); foreach (var input in property.Value.EnumerateArray()) input.WriteTo(writer);
            writer.WriteStartObject(); writer.WriteString("kind", "capability"); writer.WritePropertyName("capability"); WriteCapability(writer, "protocol.capability.repository-target-resolution-index", "protocol.type.capability.repository-target-resolution-index");
            writer.WriteNumber("minimumCount", 1); writer.WriteNumber("maximumCount", 1); writer.WriteEndObject(); writer.WriteEndArray();
        }
        writer.WriteEndObject();
    }
    private static byte[] RewriteRule(byte[] source, string? removeSlot = null, string? capabilitySlot = null, bool moveTargetToApplicability = false) => RewriteSliceRules(source, (writer, rule) =>
    {
        writer.WriteStartObject();
        foreach (var property in rule.EnumerateObject())
        {
            if (property.Name == "applicabilitySlots" && moveTargetToApplicability)
            { writer.WriteStartArray(property.Name); FindSlot(rule, "protocol.slot.repository-target-resolution").WriteTo(writer); writer.WriteEndArray(); }
            else if (property.Name == "evaluationSlots")
            {
                writer.WriteStartArray(property.Name);
                foreach (var slot in property.Value.EnumerateArray())
                {
                    var key = slot.GetProperty("slotKey").GetString();
                    if (key == removeSlot || moveTargetToApplicability && key == "protocol.slot.repository-target-resolution") continue;
                    if (key == capabilitySlot) WriteSlotWithoutGovernedCapability(writer, slot); else slot.WriteTo(writer);
                }
                writer.WriteEndArray();
            }
            else property.WriteTo(writer);
        }
        writer.WriteEndObject();
    });
    private static void WriteSlotWithoutGovernedCapability(Utf8JsonWriter writer, JsonElement slot)
    {
        writer.WriteStartObject();
        foreach (var property in slot.EnumerateObject())
        {
            if (property.Name != "capabilities") { property.WriteTo(writer); continue; }
            writer.WriteStartArray(property.Name);
            foreach (var capability in property.Value.EnumerateArray())
                if (capability.GetProperty("capabilityKey").GetString() != "protocol.capability.governed-reference-index") capability.WriteTo(writer);
            writer.WriteEndArray();
        }
        writer.WriteEndObject();
    }
    private static JsonElement FindSlot(JsonElement rule, string key) => rule.GetProperty("evaluationSlots").EnumerateArray().Single(slot => slot.GetProperty("slotKey").GetString() == key);
    private static byte[] RewriteComponents(byte[] source, string? removeKey = null, IReadOnlyList<Binding>? additions = null,
        string? duplicateKey = null, string? replaceKey = null, Binding? replacement = null) => RewriteRootArray(source, "components", (writer, rows) =>
    {
        var bindings = rows.EnumerateArray().Select(Binding.FromJson).Where(item => item.Key != removeKey).ToList();
        if (replaceKey is not null) { bindings.RemoveAll(item => item.Key == replaceKey); bindings.Add(replacement!); }
        if (duplicateKey is not null) bindings.Add(bindings.Single(item => item.Key == duplicateKey));
        if (additions is not null) bindings.AddRange(additions);
        writer.WriteStartArray();
        foreach (var binding in bindings.OrderBy(item => item.Key, StringComparer.Ordinal).ThenBy(item => item.Version, StringComparer.Ordinal)) WriteBinding(writer, binding);
        writer.WriteEndArray();
    });
    private static void WriteBinding(Utf8JsonWriter writer, Binding binding)
    { writer.WriteStartObject(); WriteReference(writer, "component", binding.Key, binding.Version, binding.Assembly, binding.Type); writer.WriteString("artifactFileName", binding.Artifact); writer.WriteEndObject(); }
    private static void WriteReference(Utf8JsonWriter writer, string property, string key, string version, string? assembly = null, string? type = null)
    { writer.WriteStartObject(property); writer.WriteString("componentKey", key); writer.WriteString("componentVersion", version); if (assembly is not null) { writer.WriteString("assemblyName", assembly); writer.WriteString("typeName", type); } writer.WriteEndObject(); }
    private static void WriteCapability(Utf8JsonWriter writer, string key, string typeKey)
    { writer.WriteStartObject(); writer.WriteString("capabilityKey", key); writer.WriteString("capabilityVersion", "1"); WriteReference(writer, "interfaceType", typeKey, "1"); writer.WriteEndObject(); }
    private static void WriteRenamed(JsonElement row, Utf8JsonWriter writer, string from, string to, params (string From, string To)[] other)
    {
        var json = row.GetRawText().Replace(from, to, StringComparison.Ordinal);
        foreach (var pair in other) json = json.Replace(pair.From, pair.To, StringComparison.Ordinal);
        using var document = JsonDocument.Parse(json); document.RootElement.WriteTo(writer);
    }
    private static byte[] RewriteRegistryArray(byte[] source, string name, Action<Utf8JsonWriter, JsonElement> write,
        Action<Utf8JsonWriter, JsonElement>? replaceRow = null) => RewriteSegment(source,
        root => root.GetProperty("schemaRegistry").GetProperty(name), (writer, rows) =>
        {
            if (replaceRow is null) { write(writer, rows); return; }
            writer.WriteStartArray(); foreach (var row in rows.EnumerateArray())
                if (row.TryGetProperty("indexKey", out var key) && key.GetString() == GovernedIndexKey) replaceRow(writer, row); else row.WriteTo(writer);
            writer.WriteEndArray();
        });
    private static byte[] RewriteRootArray(byte[] source, string name, Action<Utf8JsonWriter, JsonElement> write) => RewriteSegment(source, root => root.GetProperty(name), write);
    private static byte[] RewriteSliceRules(byte[] source, Action<Utf8JsonWriter, JsonElement> writeRule) => RewriteSegment(source, root => root.GetProperty("slice").GetProperty("rules"), (writer, rules) =>
    { writer.WriteStartArray(); writeRule(writer, rules[0]); writer.WriteEndArray(); });
    private static JsonElement ProjectorArray(JsonElement root) => root.GetProperty("schemaRegistry").GetProperty("demandProjectors");
    private static byte[] RewriteSegment(byte[] source, Func<JsonElement, JsonElement> locate, Action<Utf8JsonWriter, JsonElement> write)
    {
        using var document = JsonDocument.Parse(source); var segment = locate(document.RootElement);
        return Replace(source, Encoding.UTF8.GetBytes(segment.GetRawText()), writer => write(writer, segment));
    }
    private static byte[] Replace(byte[] source, byte[] needle, Action<Utf8JsonWriter> write)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping })) write(writer);
        var replacement = stream.ToArray(); var index = source.AsSpan().IndexOf(needle);
        if (index < 0 || source.AsSpan(index + needle.Length).IndexOf(needle) >= 0) throw new InvalidOperationException("The fixture segment must occur exactly once.");
        var result = new byte[source.Length - needle.Length + replacement.Length];
        source.AsSpan(0, index).CopyTo(result); replacement.CopyTo(result, index); source.AsSpan(index + needle.Length).CopyTo(result.AsSpan(index + replacement.Length));
        if (source[^1] != (byte)'\n' || result[^1] != (byte)'\n') throw new InvalidOperationException("Terminal LF was not preserved.");
        return result;
    }
    private static void Reject(byte[] mutated, string diagnostic, HashSet<string> mutations)
    {
        using var document = JsonDocument.Parse(mutated);
        Assert.True(mutations.Add(Convert.ToBase64String(mutated)));
        var exception = Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated));
        Assert.Equal(diagnostic, exception.Message);
    }
    private static AcquisitionDemandProjectorDeclaration Projector() => AcquisitionDemandProjectorDeclaration.Create(ProjectorKey, "1", Resolve(ProjectorKey), GovernedCapability(), ["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text"], "protocol.slot.repository-target-resolution", "protocol.repository-target-resolution-demand", "1", Budget(33_554_432, 64, 100_000, 5_000_000), [EvaluationFailureCode.Parse("protocol.budget.exhausted")]);
    private static AdmissionProofContractDeclaration Admission(AdmissionProofKind kind) => AdmissionProofContractDeclaration.Create("protocol.test.admission-proof", "1", kind, Resolve("protocol.admission-proof.test-" + kind.Value), SurfaceSet.Create([SurfaceKind.Provider, SurfaceKind.Repository]), ["protocol.material.repository-tree", "protocol.material.repository-target-resolution", "protocol.material.governed-text"]);
    private static ParsedCanonicalManifest CreateManifest(bool includeProjector) => new(CatalogAuthorityKind.QualificationSlice, Commit, ReleaseSchemaRegistry.Create([TreeSchema(), TargetSchema(), GovernedSchema()], [TargetParser(), MarkdownParser()], [TreeIndex(), TargetIndex(), RecordIndex(), GovernedIndex()], includeProjector ? [Projector()] : [], [Admission(AdmissionProofKind.NoInput), Admission(AdmissionProofKind.Failed), Admission(AdmissionProofKind.Observed)], SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys)), ActivationProofContractDeclaration.Create("protocol.activation-proof.test", "1.0.0", Resolve("protocol.activation-proof.test")), new[] { "ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll" }.Select(Artifact).ToArray(), Components.Where(item => includeProjector || item.Key != ProjectorKey).Select(item => ComponentArtifactBinding.Create(Resolve(item.Key), item.Artifact)).ToArray(), CatalogSliceDeclaration.Create("protocol.test.catalog-slice.selector", "1", "0.0.0", CatalogVersion.Create(1), [CreateRule()]));
    private static RuleDeclaration CreateRule() => RuleDeclaration.Create(RuleId.Parse("RULE-9999"), RuleRevision.Create(1), CatalogVersion.Create(1), ExactSha256Digest.Parse(Digest), [NormativeFragmentDeclaration.Create("docs/test-fixtures/selector-contract.md", Blob, "selector-contract", 1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))], [TestScenarioId.Parse("TEST-0001")], Resolve("protocol.evaluator.test-rule"), [], [TreeSlot(), TargetSlot(), RepositoryGovernedSlot(), ProviderGovernedSlot()], [Selector("zeta", "protocol.slot.repository-governed-text"), Selector("alpha", "protocol.slot.repository-tree")], [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]), [SnapshotKind.ExactCommit], [ProtocolOperation.Conformance], [Finding("protocol.test.finding.zeta"), Finding("protocol.test.finding.alpha")], [], "1.0.0", null, null, []);
    private static ExpectedSelectorDeclaration Selector(string suffix, string slot) => ExpectedSelectorDeclaration.Create("protocol.test.selector." + suffix, slot, "protocol.test.selector-schema." + suffix, Resolve("protocol.selector.test-" + suffix), suffix == "alpha" ? [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.ContextProof] : [QualifiedEvidenceReferenceKind.Derived], suffix == "alpha" ? [FindingCode.Parse("protocol.test.finding.zeta"), FindingCode.Parse("protocol.test.finding.alpha")] : [FindingCode.Parse("protocol.test.finding.zeta")]);
    private static FindingDeclaration Finding(string code) => FindingDeclaration.Create(FindingCode.Parse(code), FindingSeverity.Parse("protocol.test.severity." + (code.EndsWith("alpha", StringComparison.Ordinal) ? "alpha" : "zeta")), RemediationKey.Parse("protocol.test.remediation." + (code.EndsWith("alpha", StringComparison.Ordinal) ? "alpha" : "zeta")), code.EndsWith("alpha", StringComparison.Ordinal) ? [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.ContextProof] : [QualifiedEvidenceReferenceKind.Root], code.EndsWith("alpha", StringComparison.Ordinal) ? [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.ContextProof] : []);
    private static PayloadSchemaDeclaration GovernedSchema() => PayloadSchemaDeclaration.Create("protocol.governed-text", "1", Resolve("protocol.codec.governed-text"), SourceModel(), 200_000, 67_108_864, Budget(4_194_304, 256, 500_000, 5_000_000), GovernedCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TargetSchema() => PayloadSchemaDeclaration.Create("protocol.repository-target-resolution", "1", Resolve("protocol.codec.repository-target-resolution"), TargetResolutionModel(), 1, 33_554_432, Budget(33_554_432, 64, 500_000, 34_054_432), TargetCodecFailures.Reverse());
    private static PayloadSchemaDeclaration TreeSchema() => PayloadSchemaDeclaration.Create("protocol.repository-tree", "1", Resolve("protocol.codec.repository-tree"), TreeModel(), 1, 16_777_216, Budget(16_777_216, 64, 200_000, 2_000_000), TreeCodecFailures.Reverse());
    private static SemanticModelParserDeclaration MarkdownParser() => SemanticModelParserDeclaration.Create("protocol.parser.markdown", "1", Resolve("protocol.parser.markdown"), [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)], MarkdownModel(), Budget(4_194_304, 256, 500_000, 5_000_000), MarkdownFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static SemanticModelParserDeclaration TargetParser() => SemanticModelParserDeclaration.Create("protocol.parser.repository-target-markdown", "1", Resolve("protocol.parser.repository-target-markdown"), [ComponentInputDeclaration.ForModel(TargetResolutionModel(), 1, 1)], TargetMarkdownModel(), Budget(33_554_432, 256, 1_000_000, 34_554_432), [EvaluationFailureCode.Parse("protocol.budget.exhausted")]);
    private static ContextIndexDeclaration GovernedIndex() => ContextIndexDeclaration.Create(GovernedIndexKey, "1", Resolve(GovernedIndexKey), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(RecordCapability(), 1, null), ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], GovernedCapability(), Budget(67_108_864, 256, 1_000_000, 10_000_000), GovernedFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration RecordIndex() => ContextIndexDeclaration.Create("protocol.index.protocol-record", "1", Resolve("protocol.index.protocol-record"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], RecordCapability(), Budget(67_108_864, 256, 1_000_000, 10_000_000), RecordFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TargetIndex() => ContextIndexDeclaration.Create("protocol.index.repository-target-resolution", "1", Resolve("protocol.index.repository-target-resolution"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(GovernedCapability(), 1, 1), ComponentInputDeclaration.ForModel(TargetResolutionModel(), 0, null), ComponentInputDeclaration.ForModel(TargetMarkdownModel(), 0, null)], TargetCapability(), Budget(67_108_864, 256, 2_000_000, 20_000_000), TargetIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static ContextIndexDeclaration TreeIndex() => ContextIndexDeclaration.Create("protocol.index.repository-tree", "1", Resolve("protocol.index.repository-tree"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)], TreeCapability(), Budget(16_777_216, 64, 200_000, 2_000_000), TreeIndexFailures.Reverse().Select(EvaluationFailureCode.Parse));
    private static EvidenceSlotDeclaration ProviderGovernedSlot() => GovernedSlot("provider", SurfaceKind.Provider, [SurfaceKind.Provider]);
    private static EvidenceSlotDeclaration RepositoryGovernedSlot() => GovernedSlot("repository", SurfaceKind.Repository, [SurfaceKind.Provider, SurfaceKind.Repository]);
    private static EvidenceSlotDeclaration GovernedSlot(string scope, SurfaceKind surface, SurfaceKind[] profiles) => EvidenceSlotDeclaration.Create("protocol.slot." + scope + "-governed-text", EvidenceRequirement.Create("protocol.requirement." + scope + "-governed-text", surface, "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", "1", [EvidenceConsistencyClass.BoundedNonAtomicObservation, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create(profiles), "protocol.material.governed-text", "protocol.target." + scope + "-governed-body-set", [RecordCapability(), GovernedCapability()]);
    private static EvidenceSlotDeclaration TargetSlot() => EvidenceSlotDeclaration.Create("protocol.slot.repository-target-resolution", EvidenceRequirement.Create("protocol.requirement.repository-target-resolution", SurfaceKind.Repository, "protocol.evidence.repository-target-resolution-set", "protocol.completeness.all-projected-target-resolutions", "protocol.repository-target-resolution", "1", [EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create([SurfaceKind.Provider, SurfaceKind.Repository]), "protocol.material.repository-target-resolution", "protocol.target.repository-target-resolution-set", [TargetCapability()]);
    private static EvidenceSlotDeclaration TreeSlot() => EvidenceSlotDeclaration.Create("protocol.slot.repository-tree", EvidenceRequirement.Create("protocol.requirement.repository-tree", SurfaceKind.Repository, "protocol.evidence.repository-tree", "protocol.completeness.full-tree", "protocol.repository-tree", "1", [EvidenceConsistencyClass.BoundedNonAtomicObservation, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.ExactSnapshot]), SurfaceSet.Create([SurfaceKind.Repository]), "protocol.material.repository-tree", "protocol.target.repository-snapshot", [TreeCapability()]);
    private static ModelContractIdentity SourceModel() => Model("protocol.model.source-text", "protocol.type.model.source-text"); private static ModelContractIdentity MarkdownModel() => Model("protocol.model.markdown-document", "protocol.type.model.markdown-document"); private static ModelContractIdentity TargetMarkdownModel() => Model("protocol.model.repository-target-markdown-document-set", "protocol.type.model.repository-target-markdown-document-set"); private static ModelContractIdentity TargetResolutionModel() => Model("protocol.model.repository-target-resolution", "protocol.type.model.repository-target-resolution"); private static ModelContractIdentity TreeModel() => Model("protocol.model.repository-tree", "protocol.type.model.repository-tree"); private static ModelContractIdentity Model(string key, string component) => ModelContractIdentity.Create(key, "1", Resolve(component));
    private static CapabilityContractIdentity GovernedCapability() => Capability("protocol.capability.governed-reference-index", GovernedTypeKey); private static CapabilityContractIdentity RecordCapability() => Capability("protocol.capability.protocol-record-index", "protocol.type.capability.protocol-record-index"); private static CapabilityContractIdentity TargetCapability() => Capability("protocol.capability.repository-target-resolution-index", "protocol.type.capability.repository-target-resolution-index"); private static CapabilityContractIdentity TreeCapability() => Capability("protocol.capability.repository-tree", "protocol.type.capability.repository-tree"); private static CapabilityContractIdentity Capability(string key, string component) => CapabilityContractIdentity.Create(key, "1", Resolve(component));
    private static SemanticResourceBudget Budget(long bytes, int depth, long nodes, long complexity) => SemanticResourceBudget.Create(bytes, depth, nodes, complexity);
    private static ComponentTypeIdentity Resolve(string key) { var item = Components.Single(component => component.Key == key); return ComponentTypeIdentity.Create(key, "1", item.Assembly, item.Type); }
    private static ArtifactFileBinding Artifact(string name) => ArtifactFileBinding.Create(name, 1, ExactSha256Digest.Parse(Digest));
    private sealed record Binding(string Key, string Version, string Assembly, string Type, string Artifact)
    {
        internal static Binding FromJson(JsonElement row) { var component = row.GetProperty("component"); return new(component.GetProperty("componentKey").GetString()!, component.GetProperty("componentVersion").GetString()!, component.GetProperty("assemblyName").GetString()!, component.GetProperty("typeName").GetString()!, row.GetProperty("artifactFileName").GetString()!); }
        internal static Binding Test(string key, string type, string version = "1") => new(key, version, "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests." + type, "ContractSliceA.Proof.dll");
        internal static Binding Policy(string key, string type, string artifact, string version = "1") => new(key, version, "MeAndAI.Protocol.Policy", type, artifact);
    }
    private enum FieldMutation { Normal, Missing, Duplicate, Null, WrongType }
    private enum EnvelopeMutation { NullArray, Object, NullElement, DuplicateRows }
    private enum ValueMutation { Normal, AlternateKey, Version2, AlternateComponent, ComponentVersion2, RecordCapabilityKey, CapabilityVersion2, RecordInterface, InterfaceVersion2, TreeOutput, AlternateDemandSchema, DemandVersion2, EmptyInputs, NullInput, DuplicateProvider, ReversedInputs, UnknownInput, OutputAmongInputs, RemoveProviderSlot, RemoveRepositorySlot, EmptyFailures, NullFailure, DuplicateFailure, SupersetFailures, MaxBytesOne, MaxDepthOne, MaxNodesOne, MaxComplexityOne }
    private enum TopologyMutation { Normal, RemoveProjectorComponent, DuplicateProjectorComponent, DeclarationFreeComponent, MissingArtifact, RemoveProjectorDeclaration, ReuseActivation, ReuseObservedProof, ReuseGovernedCodec, ReuseSourceModel, ReuseMarkdownParser, ReuseGovernedIndex, ReuseGovernedCapability, RemoveProviderCapability, RemoveRepositoryCapability, RemoveGovernedProducer, SecondCapabilityProducer, SecondSlotProducer, ApplicabilityOutput, ProducerCycle, UnreachableParser, ReuseSelector, ReuseEvaluator }
}
