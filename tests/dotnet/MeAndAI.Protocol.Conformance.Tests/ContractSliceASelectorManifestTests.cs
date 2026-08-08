using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceASelectorManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private const string AlphaCode = "protocol.test.finding.alpha";
    private const string ZetaCode = "protocol.test.finding.zeta";
    private const string AlphaResolver = "protocol.selector.test-alpha";
    private const string ZetaResolver = "protocol.selector.test-zeta";
    private const string FrozenMessage = "Expected selector parent kinds must be ContextProof, Root, or Derived.";
    private static readonly string[] FieldNames =
        ["selectorKey", "slotKey", "selectorSchemaKey", "resolver", "allowedParentKinds", "allowedFindingCodes"];
    private static readonly string[] ParentKinds = ["context-proof", "root", "derived"];
    private static readonly string[] FindingCodes = [AlphaCode, ZetaCode];
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
        (AlphaResolver, "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestAlphaSelectorResolver", "ContractSliceA.Proof.dll"),
        (ZetaResolver, "MeAndAI.Protocol.Conformance.Tests", "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestZetaSelectorResolver", "ContractSliceA.Proof.dll"),
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
    public void Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure()
    {
        var allowedParentKinds = new[] { QualifiedEvidenceReferenceKind.ExpectedSelector };
        var expectedParentException = new ArgumentException(FrozenMessage, nameof(allowedParentKinds));
        var actualParentException = Assert.Throws<ArgumentException>(() =>
            ExpectedSelectorDeclaration.Create(
                "protocol.test.selector.alpha",
                "protocol.slot.repository-tree",
                "protocol.test.selector-schema.alpha",
                Resolve("protocol.selector.test-alpha"),
                allowedParentKinds,
                [FindingCode.Parse("protocol.test.finding.alpha")]));
        Assert.Equal(expectedParentException.ParamName, actualParentException.ParamName);
        Assert.Equal(expectedParentException.Message, actualParentException.Message);

        var parentInput = ParentKinds.Reverse().Select(QualifiedEvidenceReferenceKind.Parse).ToList();
        var findingInput = FindingCodes.Reverse().Select(FindingCode.Parse).ToList();
        var alpha = Selector("alpha", "protocol.slot.repository-tree", parentInput, findingInput);
        var zeta = Selector("zeta", "protocol.slot.repository-governed-text", [QualifiedEvidenceReferenceKind.Derived], [FindingCode.Parse(ZetaCode)]);
        var selectorInput = new List<ExpectedSelectorDeclaration> { zeta, alpha };
        var rule = CreateRule(selectorInput);
        parentInput.Clear();
        parentInput.Add(QualifiedEvidenceReferenceKind.ExpectedSelector);
        findingInput.Clear();
        findingInput.Add(FindingCode.Parse("protocol.test.finding.changed"));
        selectorInput.Clear();
        var bytes = CanonicalManifestWriter.Write(CreateManifest(rule));
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        var parsedRule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        Assert.Equal((3, 2, 4, 4, 22, 3), (manifest.SchemaRegistry.PayloadSchemas.Count, manifest.SchemaRegistry.Parsers.Count,
            manifest.SchemaRegistry.Indexes.Count, parsedRule.EvaluationSlots.Count, manifest.Components.Count, manifest.ArtifactFiles.Count));
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.Equal(["protocol.test.selector.alpha", "protocol.test.selector.zeta"], parsedRule.ExpectedSelectors.Select(item => item.SelectorKey));
        var parsedAlpha = parsedRule.ExpectedSelectors[0];
        Assert.Equal(("protocol.slot.repository-tree", "protocol.test.selector-schema.alpha", AlphaResolver),
            (parsedAlpha.SlotKey, parsedAlpha.SelectorSchemaKey, parsedAlpha.Resolver.ComponentKey));
        Assert.Equal(ParentKinds, parsedAlpha.AllowedParentKinds.Select(item => item.Value));
        Assert.Equal(FindingCodes, parsedAlpha.AllowedFindingCodes.Select(item => item.Value));
        var parsedZeta = parsedRule.ExpectedSelectors[1];
        Assert.Equal(("protocol.slot.repository-governed-text", "protocol.test.selector-schema.zeta", ZetaResolver),
            (parsedZeta.SlotKey, parsedZeta.SelectorSchemaKey, parsedZeta.Resolver.ComponentKey));
        Assert.Equal(["derived"], parsedZeta.AllowedParentKinds.Select(item => item.Value));
        Assert.Equal([ZetaCode], parsedZeta.AllowedFindingCodes.Select(item => item.Value));
        using var document = JsonDocument.Parse(bytes);
        var wireSelectors = document.RootElement.GetProperty("slice").GetProperty("rules").EnumerateArray().Single()
            .GetProperty("expectedSelectors").EnumerateArray().ToArray();
        Assert.Equal(["protocol.test.selector.alpha", "protocol.test.selector.zeta"], wireSelectors.Select(item => item.GetProperty("selectorKey").GetString()));
        Assert.All(wireSelectors, item => Assert.Equal(FieldNames, item.EnumerateObject().Select(property => property.Name)));
        Assert.All(wireSelectors, item => Assert.Equal(["componentKey", "componentVersion"],
            item.GetProperty("resolver").EnumerateObject().Select(property => property.Name)));
        AssertFactoryAndRuleBoundaries(alpha);
        Assert.Equal(bytes, RewriteSelectors(bytes, writer => WriteSelectors(writer)));
        var mutations = new HashSet<string>(StringComparer.Ordinal);
        foreach (var field in Enumerable.Range(0, FieldNames.Length))
        {
            foreach (var mutation in Enum.GetValues<FieldMutation>().Skip(1))
            {
                Reject(bytes, mutations, writer => WriteSelectors(writer, field: field, fieldMutation: mutation));
            }
        }
        Reject(bytes, mutations, writer => WriteSelectors(writer, extraField: true));
        foreach (var swap in Enumerable.Range(0, FieldNames.Length - 1))
        {
            Reject(bytes, mutations, writer => WriteSelectors(writer, adjacentSwap: swap));
        }
        foreach (var mutation in new[] { CollectionMutation.Unknown, CollectionMutation.Duplicate, CollectionMutation.Reversed, CollectionMutation.Empty, CollectionMutation.ForbiddenParent })
        {
            Reject(bytes, mutations, writer => WriteSelectors(writer, collectionField: 4, collectionMutation: mutation));
        }
        foreach (var mutation in new[] { CollectionMutation.Unknown, CollectionMutation.Duplicate, CollectionMutation.Reversed, CollectionMutation.Empty })
        {
            Reject(bytes, mutations, writer => WriteSelectors(writer, collectionField: 5, collectionMutation: mutation));
        }
        foreach (var mutation in Enum.GetValues<ArrayMutation>().Skip(1))
        {
            Reject(bytes, mutations, writer => WriteSelectors(writer, arrayMutation: mutation));
        }
        Assert.Equal(42, mutations.Count);
        var selectorless = RewriteSelectors(bytes, writer => { writer.WriteStartArray(); writer.WriteEndArray(); });
        RejectGraph(selectorless);
        RejectGraph(WithoutResolvers(bytes, AlphaResolver));
        RejectGraph(WithoutResolvers(bytes, ZetaResolver));
        RejectGraph(WithoutResolvers(selectorless, AlphaResolver));
        RejectGraph(WithoutResolvers(selectorless, ZetaResolver));
        var predecessor = WithoutResolvers(selectorless, AlphaResolver, ZetaResolver);
        var predecessorManifest = FinalizedPolicyManifest.ParseCanonical(predecessor);
        Assert.Equal(predecessor, CanonicalManifestWriter.Write(predecessorManifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(predecessor)).ToLowerInvariant(), predecessorManifest.ManifestDigest.Value);
        Assert.Empty(Assert.Single(Assert.IsType<CatalogSliceDeclaration>(predecessorManifest.Slice).Rules).ExpectedSelectors);
        Assert.Equal(20, predecessorManifest.Components.Count);
    }

    private static void AssertFactoryAndRuleBoundaries(ExpectedSelectorDeclaration alpha)
    {
        var finding = FindingCode.Parse(AlphaCode);
        foreach (var kind in new[] { QualifiedEvidenceReferenceKind.ContextProof, QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Derived })
        {
            Assert.Equal(kind, Assert.Single(Selector("alpha", "protocol.slot.repository-tree", [kind], [finding]).AllowedParentKinds));
        }
        AssertForbidden([QualifiedEvidenceReferenceKind.ExpectedSelector]);
        AssertForbidden([QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.ExpectedSelector]);
        Assert.Throws<ArgumentNullException>(() => Selector("alpha", "protocol.slot.repository-tree", null!, [finding]));
        Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", [], [finding]));
        Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", [null!], [finding]));
        Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", [QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Root], [finding]));
        Assert.Throws<ArgumentNullException>(() => Selector("alpha", "protocol.slot.repository-tree", [QualifiedEvidenceReferenceKind.Root], null!));
        Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", [QualifiedEvidenceReferenceKind.Root], []));
        Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", [QualifiedEvidenceReferenceKind.Root], [null!]));
        Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", [QualifiedEvidenceReferenceKind.Root], [finding, finding]));
        Assert.Throws<ArgumentNullException>(() => ExpectedSelectorDeclaration.Create("protocol.test.selector.alpha", "protocol.slot.repository-tree",
            "protocol.test.selector-schema.alpha", null!, [QualifiedEvidenceReferenceKind.Root], [finding]));
        Assert.Throws<ArgumentException>(() => CreateRule([alpha, alpha]));
        Assert.Throws<ArgumentException>(() => CreateRule([Selector("alpha", "protocol.slot.unknown", [QualifiedEvidenceReferenceKind.Root], [finding])]));
        Assert.Throws<ArgumentException>(() => CreateRule([Selector("alpha", "protocol.slot.repository-tree", [QualifiedEvidenceReferenceKind.Root], [FindingCode.Parse("protocol.test.finding.unknown")])]));
    }

    private static void AssertForbidden(IEnumerable<QualifiedEvidenceReferenceKind> kinds)
    {
        var expected = new ArgumentException(FrozenMessage, "allowedParentKinds");
        var actual = Assert.Throws<ArgumentException>(() => Selector("alpha", "protocol.slot.repository-tree", kinds, [FindingCode.Parse(AlphaCode)]));
        Assert.Equal(expected.ParamName, actual.ParamName);
        Assert.Equal(expected.Message, actual.Message);
    }

    private static ExpectedSelectorDeclaration Selector(string suffix, string slot,
        IEnumerable<QualifiedEvidenceReferenceKind> parents, IEnumerable<FindingCode> findings) =>
        ExpectedSelectorDeclaration.Create("protocol.test.selector." + suffix, slot, "protocol.test.selector-schema." + suffix,
            Resolve("protocol.selector.test-" + suffix), parents, findings);

    private static void WriteSelectors(Utf8JsonWriter writer, int field = -1,
        FieldMutation fieldMutation = FieldMutation.Normal, int adjacentSwap = -1, int collectionField = -1,
        CollectionMutation collectionMutation = CollectionMutation.Normal, bool extraField = false,
        ArrayMutation arrayMutation = ArrayMutation.Normal)
    {
        writer.WriteStartArray();
        if (arrayMutation == ArrayMutation.NullEntry) writer.WriteNullValue();
        else if (arrayMutation == ArrayMutation.Reversed) { WriteSelector(writer, false); WriteSelector(writer, true); }
        else if (arrayMutation == ArrayMutation.Duplicate) { WriteSelector(writer, true); WriteSelector(writer, true); }
        else { WriteSelector(writer, true, field, fieldMutation, adjacentSwap, collectionField, collectionMutation, extraField); WriteSelector(writer, false); }
        writer.WriteEndArray();
    }

    private static void WriteSelector(Utf8JsonWriter writer, bool alpha, int field = -1,
        FieldMutation fieldMutation = FieldMutation.Normal, int adjacentSwap = -1, int collectionField = -1,
        CollectionMutation collectionMutation = CollectionMutation.Normal, bool extraField = false)
    {
        var order = Enumerable.Range(0, FieldNames.Length).ToArray();
        if (adjacentSwap >= 0) (order[adjacentSwap], order[adjacentSwap + 1]) = (order[adjacentSwap + 1], order[adjacentSwap]);
        writer.WriteStartObject();
        foreach (var current in order)
        {
            if (current == field && fieldMutation == FieldMutation.Missing) continue;
            if (current == field && fieldMutation == FieldMutation.Null) { writer.WriteNull(FieldNames[current]); continue; }
            if (current == field && fieldMutation == FieldMutation.WrongType)
            {
                writer.WritePropertyName(FieldNames[current]); writer.WriteBooleanValue(false); continue;
            }
            WriteField(writer, current, alpha, current == collectionField ? collectionMutation : CollectionMutation.Normal);
            if (current == field && fieldMutation == FieldMutation.Duplicate) WriteField(writer, current, alpha, CollectionMutation.Normal);
            if (extraField && current == FieldNames.Length - 1) writer.WriteString("unexpectedSelectorProperty", "unexpected");
        }
        writer.WriteEndObject();
    }

    private static void WriteField(Utf8JsonWriter writer, int field, bool alpha, CollectionMutation mutation)
    {
        var suffix = alpha ? "alpha" : "zeta";
        switch (field)
        {
            case 0: writer.WriteString(FieldNames[field], "protocol.test.selector." + suffix); break;
            case 1: writer.WriteString(FieldNames[field], alpha ? "protocol.slot.repository-tree" : "protocol.slot.repository-governed-text"); break;
            case 2: writer.WriteString(FieldNames[field], "protocol.test.selector-schema." + suffix); break;
            case 3:
                writer.WritePropertyName(FieldNames[field]); writer.WriteStartObject();
                writer.WriteString("componentKey", alpha ? AlphaResolver : ZetaResolver);
                writer.WriteString("componentVersion", "1"); writer.WriteEndObject(); break;
            case 4: WriteValues(writer, FieldNames[field], alpha ? ParentKinds : ["derived"], mutation, parentKinds: true); break;
            case 5: WriteValues(writer, FieldNames[field], alpha ? FindingCodes : [ZetaCode], mutation, parentKinds: false); break;
            default: throw new ArgumentOutOfRangeException(nameof(field));
        }
    }

    private static void WriteValues(Utf8JsonWriter writer, string property, IReadOnlyList<string> canonical,
        CollectionMutation mutation, bool parentKinds)
    {
        IEnumerable<string> values = mutation switch
        {
            CollectionMutation.Unknown => [parentKinds ? "unknown-reference" : "protocol.test.finding.unknown"],
            CollectionMutation.Duplicate => canonical.Prepend(canonical[0]),
            CollectionMutation.Reversed => canonical.Reverse(),
            CollectionMutation.Empty => [],
            CollectionMutation.ForbiddenParent => ["expected-selector"],
            _ => canonical,
        };
        writer.WriteStartArray(property);
        foreach (var value in values) writer.WriteStringValue(value);
        writer.WriteEndArray();
    }

    private static byte[] RewriteSelectors(byte[] canonical, Action<Utf8JsonWriter> write)
    {
        using var document = JsonDocument.Parse(canonical);
        var selectors = document.RootElement.GetProperty("slice").GetProperty("rules").EnumerateArray().Single().GetProperty("expectedSelectors");
        return Rewrite(canonical, Encoding.UTF8.GetBytes(selectors.GetRawText()), write);
    }

    private static byte[] WithoutResolvers(byte[] canonical, params string[] resolverKeys)
    {
        using var document = JsonDocument.Parse(canonical);
        var components = document.RootElement.GetProperty("components");
        var removed = resolverKeys.ToHashSet(StringComparer.Ordinal);
        return Rewrite(canonical, Encoding.UTF8.GetBytes(components.GetRawText()), writer =>
        {
            writer.WriteStartArray();
            foreach (var item in components.EnumerateArray())
            {
                var key = item.GetProperty("component").GetProperty("componentKey").GetString()!;
                if (!removed.Contains(key)) item.WriteTo(writer);
            }
            writer.WriteEndArray();
        });
    }

    private static byte[] Rewrite(byte[] source, byte[] needle, Action<Utf8JsonWriter> write)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping })) write(writer);
        var replacement = stream.ToArray();
        var index = source.AsSpan().IndexOf(needle);
        if (index < 0 || source.AsSpan(index + needle.Length).IndexOf(needle) >= 0) throw new InvalidOperationException("The fixture segment must occur exactly once.");
        var result = new byte[source.Length - needle.Length + replacement.Length];
        source.AsSpan(0, index).CopyTo(result); replacement.CopyTo(result, index);
        source.AsSpan(index + needle.Length).CopyTo(result.AsSpan(index + replacement.Length));
        if (source[^1] != (byte)'\n' || result[^1] != (byte)'\n') throw new InvalidOperationException("Terminal LF was not preserved.");
        return result;
    }

    private static void Reject(byte[] canonical, HashSet<string> mutations, Action<Utf8JsonWriter> write)
    {
        var mutated = RewriteSelectors(canonical, write);
        Assert.False(canonical.AsSpan().SequenceEqual(mutated));
        using var document = JsonDocument.Parse(mutated);
        Assert.True(mutations.Add(Convert.ToBase64String(mutated)));
        Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated));
    }

    private static void RejectGraph(byte[] mutated)
    {
        using var document = JsonDocument.Parse(mutated);
        Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated));
    }

    private static ParsedCanonicalManifest CreateManifest(RuleDeclaration rule) => new(
        CatalogAuthorityKind.QualificationSlice, Commit, CreateRegistry(),
        ActivationProofContractDeclaration.Create("protocol.activation-proof.test", "1.0.0", Resolve("protocol.activation-proof.test")),
        new[] { "ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll" }.Select(Artifact).ToArray(),
        Components.Select(item => ComponentArtifactBinding.Create(Resolve(item.Key), item.Artifact)).ToArray(),
        CatalogSliceDeclaration.Create("protocol.test.catalog-slice.selector", "1", "0.0.0", CatalogVersion.Create(1), [rule]));
    private static ReleaseSchemaRegistry CreateRegistry() => ReleaseSchemaRegistry.Create([TreeSchema(), TargetSchema(), GovernedSchema()], [TargetParser(), MarkdownParser()], [TreeIndex(), TargetIndex(), RecordIndex(), GovernedIndex()], [], [], SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static RuleDeclaration CreateRule(IEnumerable<ExpectedSelectorDeclaration> selectors) => RuleDeclaration.Create(
        RuleId.Parse("RULE-9999"), RuleRevision.Create(1), CatalogVersion.Create(1), ExactSha256Digest.Parse(Digest),
        [NormativeFragmentDeclaration.Create("docs/test-fixtures/selector-contract.md", Blob, "selector-contract", 1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))],
        [TestScenarioId.Parse("TEST-0001")], Resolve("protocol.evaluator.test-rule"), [],
        [TreeSlot(), TargetSlot(), RepositoryGovernedSlot(), ProviderGovernedSlot()], selectors, [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]),
        [SnapshotKind.ExactCommit], [ProtocolOperation.Conformance], [Finding(ZetaCode, [QualifiedEvidenceReferenceKind.Root], []), Finding(AlphaCode, ParentKinds.Select(QualifiedEvidenceReferenceKind.Parse), [QualifiedEvidenceReferenceKind.ContextProof, QualifiedEvidenceReferenceKind.Derived])], [], "1.0.0", null, null, []);
    private static FindingDeclaration Finding(string code, IEnumerable<QualifiedEvidenceReferenceKind> primary, IEnumerable<QualifiedEvidenceReferenceKind> related) => FindingDeclaration.Create(
        FindingCode.Parse(code), FindingSeverity.Parse("protocol.test.severity." + (code == AlphaCode ? "alpha" : "zeta")),
        RemediationKey.Parse("protocol.test.remediation." + (code == AlphaCode ? "alpha" : "zeta")), primary, related);
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
    private enum CollectionMutation { Normal, Unknown, Duplicate, Reversed, Empty, ForbiddenParent }
    private enum ArrayMutation { Normal, NullEntry, Reversed, Duplicate }
}
