using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAFindingManifestTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string Blob = "1111111111111111111111111111111111111111";
    private const string Commit = "0000000000000000000000000000000000000001";
    private const string AlphaCode = "protocol.test.finding.alpha";
    private const string ZetaCode = "protocol.test.finding.zeta";
    private const string AlphaSeverity = "protocol.test.severity.alpha";
    private const string ZetaSeverity = "protocol.test.severity.zeta";
    private const string AlphaRemediation = "protocol.test.remediation.alpha";
    private const string ZetaRemediation = "protocol.test.remediation.zeta";
    private static readonly string[] FieldNames =
    [
        "code", "severity", "remediation",
        "allowedPrimaryReferenceKinds", "allowedRelatedReferenceKinds",
    ];
    private static readonly string[] PrimaryKinds =
        ["context-proof", "root", "derived", "expected-selector"];
    private static readonly string[] RelatedKinds = ["context-proof", "derived"];
    private static readonly string[] MarkdownParserFailures =
        ["protocol.budget.exhausted", "protocol.model.invalid-markdown"];
    private static readonly string[] TargetParserFailures = ["protocol.budget.exhausted"];
    private static readonly string[] GovernedIndexFailures =
        ["protocol.budget.exhausted", "protocol.index.reference-unavailable"];
    private static readonly string[] RecordFailures =
        ["protocol.budget.exhausted", "protocol.index.record-unavailable"];
    private static readonly string[] TargetIndexFailures =
        ["protocol.budget.exhausted", "protocol.index.repository-target-resolution-unavailable"];
    private static readonly string[] TreeIndexFailures =
        ["protocol.budget.exhausted", "protocol.index.repository-tree-unavailable"];
    private static readonly string[] GovernedCodecFailures =
        ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-utf8", "protocol.codec.noncanonical-encoding", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TargetCodecFailures =
        ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-target-resolution", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
    private static readonly string[] TreeCodecFailures =
        ["protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-tree", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"];
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
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_finding_declarations_with_exact_reference_roles()
    {
        var primaryInput = PrimaryKinds.Reverse().Select(QualifiedEvidenceReferenceKind.Parse).ToList();
        var relatedInput = RelatedKinds.Reverse().Select(QualifiedEvidenceReferenceKind.Parse).ToList();
        var zetaRelatedInput = new List<QualifiedEvidenceReferenceKind>();
        var alpha = CreateFinding(AlphaCode, primaryInput, relatedInput);
        var zeta = CreateFinding(ZetaCode, [QualifiedEvidenceReferenceKind.Root], zetaRelatedInput);
        var findingsInput = new List<FindingDeclaration> { zeta, alpha };
        var rule = CreateRule(findingsInput);
        primaryInput.Clear();
        primaryInput.Add(QualifiedEvidenceReferenceKind.Root);
        relatedInput.Clear();
        relatedInput.Add(QualifiedEvidenceReferenceKind.Root);
        zetaRelatedInput.Add(QualifiedEvidenceReferenceKind.ExpectedSelector);
        findingsInput.Clear();
        findingsInput.Add(alpha);
        var bytes = CanonicalManifestWriter.Write(CreateManifest(rule));
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        var parsedRule = Assert.Single(Assert.IsType<CatalogSliceDeclaration>(manifest.Slice).Rules);
        Assert.Equal(
            (3, 2, 4, 4, 20, 3),
            (manifest.SchemaRegistry.PayloadSchemas.Count, manifest.SchemaRegistry.Parsers.Count,
                manifest.SchemaRegistry.Indexes.Count, parsedRule.EvaluationSlots.Count,
                manifest.Components.Count, manifest.ArtifactFiles.Count));
        Assert.Equal(Components.Select(item => item.Key), manifest.Components.Select(item => item.Component.ComponentKey));
        Assert.Equal([AlphaCode, ZetaCode], parsedRule.Findings.Select(item => item.Code.Value));
        var parsedAlpha = parsedRule.Findings[0];
        Assert.Equal(AlphaSeverity, parsedAlpha.Severity.Value);
        Assert.Equal(AlphaRemediation, parsedAlpha.Remediation.Value);
        Assert.Equal(PrimaryKinds, parsedAlpha.AllowedPrimaryReferenceKinds.Select(item => item.Value));
        Assert.Equal(RelatedKinds, parsedAlpha.AllowedRelatedReferenceKinds.Select(item => item.Value));
        var parsedZeta = parsedRule.Findings[1];
        Assert.Equal(ZetaSeverity, parsedZeta.Severity.Value);
        Assert.Equal(ZetaRemediation, parsedZeta.Remediation.Value);
        Assert.Equal(["root"], parsedZeta.AllowedPrimaryReferenceKinds.Select(item => item.Value));
        Assert.Empty(parsedZeta.AllowedRelatedReferenceKinds);
        using var document = JsonDocument.Parse(bytes);
        var wireFindings = document.RootElement.GetProperty("slice")
            .GetProperty("rules").EnumerateArray().Single()
            .GetProperty("findings").EnumerateArray().ToArray();
        Assert.Equal([AlphaCode, ZetaCode], wireFindings.Select(item => item.GetProperty("code").GetString()));
        Assert.All(wireFindings, item => Assert.Equal(FieldNames, item.EnumerateObject().Select(property => property.Name)));
        Assert.Equal(PrimaryKinds, Strings(wireFindings[0], FieldNames[3]));
        Assert.Equal(RelatedKinds, Strings(wireFindings[0], FieldNames[4]));
        Assert.Empty(Strings(wireFindings[1], FieldNames[4]));
        AssertFactoryBoundaries(alpha);
        Assert.Equal(bytes, RewriteFindings(bytes, writer => WriteFindings(writer)));
        var mutations = new HashSet<string>(StringComparer.Ordinal);
        foreach (var field in Enumerable.Range(0, FieldNames.Length))
        {
            foreach (var mutation in Enum.GetValues<FieldMutation>().Skip(1))
            {
                Reject(bytes, mutations, writer => WriteFindings(writer, field: field, fieldMutation: mutation));
            }
        }
        Reject(bytes, mutations, writer => WriteFindings(writer, extraField: true));
        foreach (var adjacentSwap in Enumerable.Range(0, FieldNames.Length - 1))
        {
            Reject(bytes, mutations, writer => WriteFindings(writer, adjacentSwap: adjacentSwap));
        }
        foreach (var field in new[] { 3, 4 })
        {
            foreach (var mutation in new[] { CollectionMutation.Unknown, CollectionMutation.Duplicate, CollectionMutation.Reversed })
            {
                Reject(bytes, mutations, writer => WriteFindings(writer, collectionField: field, collectionMutation: mutation));
            }
        }
        Reject(bytes, mutations, writer => WriteFindings(writer, collectionField: 3, collectionMutation: CollectionMutation.Empty));
        foreach (var mutation in Enum.GetValues<ArrayMutation>().Skip(1))
        {
            Reject(bytes, mutations, writer => WriteFindings(writer, arrayMutation: mutation));
        }
        Assert.Equal(35, mutations.Count);
    }
    private static void AssertFactoryBoundaries(FindingDeclaration alpha)
    {
        var code = FindingCode.Parse(AlphaCode);
        var severity = FindingSeverity.Parse(AlphaSeverity);
        var remediation = RemediationKey.Parse(AlphaRemediation);
        var primary = new[] { QualifiedEvidenceReferenceKind.Root };
        Assert.Throws<ArgumentNullException>(() => FindingDeclaration.Create(null!, severity, remediation, primary, []));
        Assert.Throws<ArgumentNullException>(() => FindingDeclaration.Create(code, null!, remediation, primary, []));
        Assert.Throws<ArgumentNullException>(() => FindingDeclaration.Create(code, severity, null!, primary, []));
        Assert.Throws<ArgumentNullException>(() => FindingDeclaration.Create(code, severity, remediation, null!, []));
        Assert.Throws<ArgumentNullException>(() => FindingDeclaration.Create(code, severity, remediation, primary, null!));
        Assert.Throws<ArgumentException>(() => FindingDeclaration.Create(code, severity, remediation, [], []));
        Assert.Throws<ArgumentException>(() => FindingDeclaration.Create(code, severity, remediation, [QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Root], []));
        Assert.Throws<ArgumentException>(() => FindingDeclaration.Create(code, severity, remediation, primary, [QualifiedEvidenceReferenceKind.Derived, QualifiedEvidenceReferenceKind.Derived]));
        Assert.Throws<ArgumentException>(() => CreateRule([alpha, alpha]));
    }
    private static FindingDeclaration CreateFinding(
        string code,
        IEnumerable<QualifiedEvidenceReferenceKind> primary,
        IEnumerable<QualifiedEvidenceReferenceKind> related)
    {
        var alpha = string.Equals(code, AlphaCode, StringComparison.Ordinal);
        return FindingDeclaration.Create(
            FindingCode.Parse(code),
            FindingSeverity.Parse(alpha ? AlphaSeverity : ZetaSeverity),
            RemediationKey.Parse(alpha ? AlphaRemediation : ZetaRemediation),
            primary,
            related);
    }
    private static void WriteFindings(
        Utf8JsonWriter writer,
        int field = -1,
        FieldMutation fieldMutation = FieldMutation.Normal,
        int adjacentSwap = -1,
        int collectionField = -1,
        CollectionMutation collectionMutation = CollectionMutation.Normal,
        bool extraField = false,
        ArrayMutation arrayMutation = ArrayMutation.Normal)
    {
        writer.WriteStartArray();
        if (arrayMutation == ArrayMutation.NullEntry)
        {
            writer.WriteNullValue();
        }
        else if (arrayMutation == ArrayMutation.Reversed)
        {
            WriteFinding(writer, alpha: false);
            WriteFinding(writer, alpha: true);
        }
        else if (arrayMutation == ArrayMutation.Duplicate)
        {
            WriteFinding(writer, alpha: true);
            WriteFinding(writer, alpha: true);
        }
        else
        {
            WriteFinding(
                writer, alpha: true, field, fieldMutation, adjacentSwap,
                collectionField, collectionMutation, extraField);
            WriteFinding(writer, alpha: false);
        }
        writer.WriteEndArray();
    }
    private static void WriteFinding(
        Utf8JsonWriter writer,
        bool alpha,
        int field = -1,
        FieldMutation fieldMutation = FieldMutation.Normal,
        int adjacentSwap = -1,
        int collectionField = -1,
        CollectionMutation collectionMutation = CollectionMutation.Normal,
        bool extraField = false)
    {
        var order = new[] { 0, 1, 2, 3, 4 };
        if (adjacentSwap >= 0)
        {
            (order[adjacentSwap], order[adjacentSwap + 1]) =
                (order[adjacentSwap + 1], order[adjacentSwap]);
        }
        writer.WriteStartObject();
        foreach (var current in order)
        {
            if (current == field && fieldMutation == FieldMutation.Missing)
            {
                continue;
            }
            if (current == field && fieldMutation == FieldMutation.Null)
            {
                writer.WriteNull(FieldNames[current]);
                continue;
            }
            if (current == field && fieldMutation == FieldMutation.WrongType)
            {
                writer.WritePropertyName(FieldNames[current]);
                writer.WriteBooleanValue(false);
                continue;
            }
            WriteField(
                writer,
                current,
                alpha,
                current == collectionField
                    ? collectionMutation
                    : CollectionMutation.Normal);
            if (current == field && fieldMutation == FieldMutation.Duplicate)
            {
                WriteField(writer, current, alpha, CollectionMutation.Normal);
            }
            if (extraField && current == FieldNames.Length - 1)
            {
                writer.WriteString("unexpectedFindingProperty", "unexpected");
            }
        }
        writer.WriteEndObject();
    }
    private static void WriteField(
        Utf8JsonWriter writer,
        int field,
        bool alpha,
        CollectionMutation collectionMutation)
    {
        switch (field)
        {
            case 0:
                writer.WriteString(FieldNames[field], alpha ? AlphaCode : ZetaCode);
                break;
            case 1:
                writer.WriteString(FieldNames[field], alpha ? AlphaSeverity : ZetaSeverity);
                break;
            case 2:
                writer.WriteString(FieldNames[field], alpha ? AlphaRemediation : ZetaRemediation);
                break;
            case 3:
                WriteKinds(writer, FieldNames[field],
                    alpha ? PrimaryKinds : ["root"], collectionMutation);
                break;
            case 4:
                WriteKinds(writer, FieldNames[field],
                    alpha ? RelatedKinds : [], collectionMutation);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(field));
        }
    }
    private static void WriteKinds(
        Utf8JsonWriter writer,
        string property,
        IReadOnlyList<string> canonical,
        CollectionMutation mutation)
    {
        IEnumerable<string> values = mutation switch
        {
            CollectionMutation.Unknown => ["unknown-reference"],
            CollectionMutation.Duplicate => canonical.Prepend(canonical[0]),
            CollectionMutation.Reversed => canonical.Reverse(),
            CollectionMutation.Empty => [],
            _ => canonical,
        };
        writer.WriteStartArray(property);
        foreach (var value in values)
        {
            writer.WriteStringValue(value);
        }
        writer.WriteEndArray();
    }
    private static byte[] RewriteFindings(
        byte[] canonical,
        Action<Utf8JsonWriter> findingsWriter)
    {
        using var document = JsonDocument.Parse(canonical);
        var findings = document.RootElement.GetProperty("slice")
            .GetProperty("rules").EnumerateArray().Single()
            .GetProperty("findings");
        var needle = Encoding.UTF8.GetBytes(findings.GetRawText());
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(
                   stream,
                   new JsonWriterOptions
                   {
                       Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
                   }))
        {
            findingsWriter(writer);
        }
        return ReplaceUnique(canonical, needle, stream.ToArray());
    }
    private static byte[] ReplaceUnique(
        byte[] source,
        byte[] needle,
        byte[] replacement)
    {
        var index = source.AsSpan().IndexOf(needle);
        if (index < 0 ||
            source.AsSpan(index + needle.Length).IndexOf(needle) >= 0)
        {
            throw new InvalidOperationException(
                "The findings fixture must occur exactly once.");
        }
        var result = new byte[source.Length - needle.Length + replacement.Length];
        source.AsSpan(0, index).CopyTo(result);
        replacement.CopyTo(result, index);
        source.AsSpan(index + needle.Length)
            .CopyTo(result.AsSpan(index + replacement.Length));
        if (source[^1] != (byte)'\n' || result[^1] != (byte)'\n')
        {
            throw new InvalidOperationException("Terminal LF was not preserved.");
        }
        return result;
    }
    private static ParsedCanonicalManifest CreateManifest(RuleDeclaration rule) =>
        new(
            CatalogAuthorityKind.QualificationSlice,
            Commit,
            CreateRegistry(),
            ActivationProofContractDeclaration.Create(
                "protocol.activation-proof.test", "1.0.0",
                Resolve("protocol.activation-proof.test")),
            new[] { "ContractSliceA.Proof.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Policy.dll" }.Select(Artifact).ToArray(),
            Components.Select(item => ComponentArtifactBinding.Create(
                Resolve(item.Key), item.Artifact)).ToArray(),
            CatalogSliceDeclaration.Create(
                "protocol.test.catalog-slice.finding", "1", "0.0.0",
                CatalogVersion.Create(1), [rule]));
    private static ReleaseSchemaRegistry CreateRegistry() => ReleaseSchemaRegistry.Create([TreeSchema(), TargetSchema(), GovernedSchema()], [TargetParser(), MarkdownParser()], [TreeIndex(), TargetIndex(), RecordIndex(), GovernedIndex()], [], [], SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));
    private static RuleDeclaration CreateRule(IEnumerable<FindingDeclaration> findings) => RuleDeclaration.Create(RuleId.Parse("RULE-9999"), RuleRevision.Create(1), CatalogVersion.Create(1), ExactSha256Digest.Parse(Digest), [NormativeFragmentDeclaration.Create("docs/test-fixtures/finding-contract.md", Blob, "finding-contract", 1, 2, "protocol.normative-fragment.utf8-lines.v1", 2, ExactSha256Digest.Parse(Digest))], [TestScenarioId.Parse("TEST-0001")], Resolve("protocol.evaluator.test-rule"), [], [TreeSlot(), TargetSlot(), RepositoryGovernedSlot(), ProviderGovernedSlot()], [], [SubjectRole.Consumer], SurfaceSet.Create([SurfaceKind.Repository]), [SnapshotKind.ExactCommit], [ProtocolOperation.Conformance], findings, [], "1.0.0", null, null, []);
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
    private static string[] Strings(JsonElement element, string property) => element.GetProperty(property).EnumerateArray().Select(item => item.GetString()!).ToArray();
    private static void Reject(byte[] canonical, HashSet<string> mutations, Action<Utf8JsonWriter> write)
    {
        var mutated = RewriteFindings(canonical, write);
        Assert.False(canonical.AsSpan().SequenceEqual(mutated));
        using var document = JsonDocument.Parse(mutated);
        Assert.True(mutations.Add(Convert.ToBase64String(mutated)));
        Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated));
    }

    private enum FieldMutation { Normal, Missing, Duplicate, Null, WrongType }
    private enum CollectionMutation { Normal, Unknown, Duplicate, Reversed, Empty }
    private enum ArrayMutation { Normal, NullEntry, Reversed, Duplicate }
}
