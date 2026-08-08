using System.Security.Cryptography;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAFullManifestGraphTests
{
    private const string Digest = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string ProtocolBlob = "4698461c34196bc3639498d6b137f87e5a8bbe5d";
    private const string TemplateBlob = "a222f89700ea589dfbda683d69ad0ad50c48d72a";
    private const string Commit = "0000000000000000000000000000000000000001";
    private static readonly (string Key, string Assembly, string Type)[] Components =
    [
        ("protocol.activation-proof.release-envelope", "MeAndAI.Protocol.Application", "MeAndAI.Protocol.Application.PolicyActivationProof"),
        ("protocol.admission-proof.failed", "MeAndAI.Protocol.Application", "MeAndAI.Protocol.Application.Qualification.FailedAttemptProof"),
        ("protocol.admission-proof.no-input", "MeAndAI.Protocol.Application", "MeAndAI.Protocol.Application.Qualification.NoInputRoutingProof"),
        ("protocol.admission-proof.observed", "MeAndAI.Protocol.Application", "MeAndAI.Protocol.Application.Qualification.ObservedQualificationProof"),
        ("protocol.codec.governed-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec"),
        ("protocol.codec.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec"),
        ("protocol.codec.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec"),
        ("protocol.evaluator.rule-0001", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Rules.FeaturePacketRuleEvaluator"),
        ("protocol.evaluator.rule-0002", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Rules.DecisionRecordRuleEvaluator"),
        ("protocol.evaluator.rule-0003", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Rules.ClickableExactTargetRuleEvaluator"),
        ("protocol.evaluator.rule-0004", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Rules.StableFragmentRuleEvaluator"),
        ("protocol.evaluator.rule-0005", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Rules.CommitPermalinkRuleEvaluator"),
        ("protocol.index.governed-reference", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex"),
        ("protocol.index.protocol-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex"),
        ("protocol.index.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex"),
        ("protocol.index.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex"),
        ("protocol.parser.markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser"),
        ("protocol.parser.repository-target-markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser"),
        ("protocol.projector.repository-target-resolution-demand", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector"),
        ("protocol.runtime.conformance", "MeAndAI.Protocol.Conformance", "MeAndAI.Protocol.Conformance.CatalogIntegrityException"),
        ("protocol.runtime.conformance-abstractions", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport"),
        ("protocol.runtime.domain", "MeAndAI.Protocol.Domain", "MeAndAI.Protocol.Domain.RuleId"),
        ("protocol.runtime.markdig", "Markdig", "Markdig.Markdown"),
        ("protocol.selector.decision-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Selectors.DecisionRecordSelectorResolver"),
        ("protocol.selector.feature-readme", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Selectors.FeatureReadmeSelectorResolver"),
        ("protocol.selector.feature-test-cases", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Selectors.FeatureTestCasesSelectorResolver"),
        ("protocol.type.capability.governed-reference-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex"),
        ("protocol.type.capability.protocol-record-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex"),
        ("protocol.type.capability.repository-target-resolution-index", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex"),
        ("protocol.type.capability.repository-tree", "MeAndAI.Protocol.Conformance.Abstractions", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree"),
        ("protocol.type.model.markdown-document", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel"),
        ("protocol.type.model.repository-target-markdown-document-set", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel"),
        ("protocol.type.model.repository-target-resolution", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel"),
        ("protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel"),
        ("protocol.type.model.source-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Models.SourceTextModel"),
    ];

    [Fact]
    [Trait("ContractSlice", "A")]
    public void Full_declaration_graph_equals_the_exact_five_rule_six_artifact_thirty_five_component_snapshot()
    {
        var bytes = CanonicalManifestWriter.Write(CreateManifest());
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(), manifest.ManifestDigest.Value);
        AssertExactSnapshot(manifest);

        var sharedBytes = CanonicalManifestWriter.Write(CreateManifest(
            admissions: Admissions(sharedKey: "protocol.admission.shared")));
        var sharedManifest = FinalizedPolicyManifest.ParseCanonical(sharedBytes);
        Assert.Equal(sharedBytes, CanonicalManifestWriter.Write(sharedManifest));
        Assert.Equal(["protocol.admission.shared"], sharedManifest.SchemaRegistry.AdmissionProofContracts
            .Select(contract => contract.ContractKey).Distinct(StringComparer.Ordinal));

        Reject(() => CreateManifest(
                rules: [Rule0001(), Rule0002(TreeSlot("protocol.target.repository-snapshot.divergent")), Rule0003(), Rule0004(), Rule0005()]),
            "A shared SlotKey must have one structural declaration.");
        Reject(() => CreateManifest(admissions: Admissions().Where(contract => !contract.Kind.Equals(AdmissionProofKind.NoInput)).ToArray()),
            "Admission-proof contracts are not closed over kinds, surfaces, and material roles.");
        Reject(() => CreateManifest(admissions: Admissions(observedProofKey: "protocol.admission-proof.failed")),
            "Admission-proof contracts are not closed over kinds, surfaces, and material roles.");
        Reject(() => CreateManifest(admissions: Admissions(observedSurfaces: SurfaceSet.Create([SurfaceKind.Repository]))),
            "Admission-proof contracts are not closed over kinds, surfaces, and material roles.");
        Reject(() => CreateManifest(admissions: Admissions(observedRoles: ["protocol.material.governed-text", "protocol.material.repository-tree"])),
            "Admission-proof contracts are not closed over kinds, surfaces, and material roles.");
    }

    private static void AssertExactSnapshot(FinalizedPolicyManifest manifest)
    {
        Assert.Equal(CatalogAuthorityKind.QualificationSlice, manifest.AuthorityKind);
        Assert.Equal(Commit, manifest.SourceCommit);
        Assert.Null(manifest.CompleteCatalog);
        var slice = Assert.IsType<CatalogSliceDeclaration>(manifest.Slice);
        Assert.Equal(("protocol.catalog-slice.initial-common-rules", "1", "0.17.0", 1),
            (slice.SliceKey, slice.SliceVersion, slice.ProtocolVersion, slice.CatalogVersion.Value));
        var rules = slice.Rules;
        Assert.Equal(["RULE-0001", "RULE-0002", "RULE-0003", "RULE-0004", "RULE-0005"], rules.Select(rule => rule.RuleId.Value));
        Assert.All(rules, rule =>
        {
            Assert.Equal(1, rule.RuleRevision.Value);
            Assert.Equal(1, rule.CatalogVersion.Value);
            Assert.Equal("0.17.0", rule.IntroducedIn);
            Assert.Null(rule.DeprecatedIn);
            Assert.Null(rule.RetiredIn);
            Assert.Empty(rule.CompatibilityAliases);
            Assert.Empty(rule.ApplicabilitySlots);
            Assert.Equal([SubjectRole.Consumer, SubjectRole.ProtocolAuthoritySelfConsumer], rule.SubjectRoles);
            Assert.Equal([ProtocolOperation.Conformance], rule.Operations);
        });
        Assert.Equal([1, 2, 3, 3, 1], rules.Select(rule => rule.NormativeFragments.Count));
        Assert.Equal([1, 1, 3, 1, 1], rules.Select(rule => rule.QualificationScenarios.Count));
        Assert.Equal([1, 2, 3, 3, 3], rules.Select(rule => rule.EvaluationSlots.Count));
        Assert.Equal([2, 1, 0, 0, 0], rules.Select(rule => rule.ExpectedSelectors.Count));
        Assert.Equal([2, 2, 4, 4, 4], rules.Select(rule => rule.Findings.Count));
        Assert.Equal([0, 0, 1, 1, 2], rules.Select(rule => rule.EvaluationFailureCodes.Count));
        Assert.Equal(["protocol.evaluator.rule-0001", "protocol.evaluator.rule-0002", "protocol.evaluator.rule-0003", "protocol.evaluator.rule-0004", "protocol.evaluator.rule-0005"],
            rules.Select(rule => rule.Evaluator.ComponentKey));
        Assert.Equal([
            "protocol.feature.readme-missing,protocol.feature.test-cases-missing",
            "protocol.decision.record-missing,protocol.decision.structure-invalid",
            "protocol.reference.not-clickable,protocol.reference.unresolved-target,protocol.reference.unsupported-authoring-form,protocol.reference.wrong-target",
            "protocol.record.anchor-duplicate,protocol.record.anchor-missing,protocol.reference.fragment-missing,protocol.reference.fragment-wrong",
            "protocol.commit-reference.not-permalink,protocol.commit-reference.unresolved,protocol.commit-reference.wrong-object,protocol.commit-reference.wrong-repository"],
            rules.Select(rule => string.Join(',', rule.Findings.Select(finding => finding.Code.Value))));
        Assert.Equal(["", "", "protocol.evaluator.reference-ambiguity", "protocol.evaluator.reference-ambiguity", "protocol.evaluator.commit-intent-ambiguity,protocol.evaluator.reference-ambiguity"],
            rules.Select(rule => string.Join(',', rule.EvaluationFailureCodes.Select(code => code.Value))));
        Assert.Equal([
            "RULE-0001|protocol.feature-packet", "RULE-0002|protocol.decision-record", "RULE-0002|template.decision.required-structure",
            "RULE-0003|protocol.clickable-exact-target", "RULE-0003|protocol.repository-provider-reference-form", "RULE-0003|protocol.link-validation",
            "RULE-0004|protocol.addressable-target-fragment", "RULE-0004|protocol.embedded-stable-id-anchor", "RULE-0004|protocol.fragment-target-form",
            "RULE-0005|protocol.commit-permalink"],
            rules.SelectMany(rule => rule.NormativeFragments.Select(fragment => $"{rule.RuleId.Value}|{fragment.Anchor}")));
        Assert.Equal([
            "69fa9341b359ed5393ba6c92dd0682abecb5bc15e1745d8cddc07583744544fe",
            "321aca48e204e7f3ddba9a327e57ad9184c9ec838160d1cd50b0afcf1c57121f",
            "cac99d8884e9737f3db976b4ea10d175f87b8b526af38d9442d964443ef2639e",
            "951932712706a09ee94dbdb784533d48ae2895c962d94476dde98da92fbf8e69",
            "e4512349b2fb23f6a367675f6a0b43bfe936c109d3109773d304affc5a1dd0b3"], rules.Select(rule => rule.NormativeDigest.Value));
        Assert.Equal([
            "RULE-0001|TEST-0004", "RULE-0002|TEST-0005", "RULE-0003|TEST-0175,TEST-0176,TEST-0177",
            "RULE-0004|TEST-0177", "RULE-0005|TEST-0178"],
            rules.Select(rule => $"{rule.RuleId.Value}|{string.Join(',', rule.QualificationScenarios.Select(scenario => scenario.Value))}"));

        var slotCounts = rules.SelectMany(rule => rule.EvaluationSlots).GroupBy(slot => slot.SlotKey, StringComparer.Ordinal)
            .ToDictionary(group => group.Key, group => group.Count(), StringComparer.Ordinal);
        Assert.Equal(4, slotCounts.Count);
        Assert.Equal(2, slotCounts["protocol.slot.repository-tree"]);
        Assert.Equal(4, slotCounts["protocol.slot.repository-governed-text"]);
        Assert.Equal(3, slotCounts["protocol.slot.provider-governed-text"]);
        Assert.Equal(3, slotCounts["protocol.slot.repository-target-resolution"]);
        Assert.Equal(["protocol.selector.feature-readme", "protocol.selector.feature-test-cases", "protocol.selector.decision-record"],
            rules.SelectMany(rule => rule.ExpectedSelectors).Select(selector => selector.SelectorKey));

        var registry = manifest.SchemaRegistry;
        Assert.Equal((3, 2, 4, 1, 3), (registry.PayloadSchemas.Count, registry.Parsers.Count, registry.Indexes.Count,
            registry.DemandProjectors.Count, registry.AdmissionProofContracts.Count));
        Assert.Equal(["protocol.governed-text", "protocol.repository-target-resolution", "protocol.repository-tree"], registry.PayloadSchemas.Select(schema => schema.SchemaKey));
        Assert.Equal(["protocol.parser.markdown", "protocol.parser.repository-target-markdown"], registry.Parsers.Select(parser => parser.ParserKey));
        Assert.Equal(["protocol.index.governed-reference", "protocol.index.protocol-record", "protocol.index.repository-target-resolution", "protocol.index.repository-tree"], registry.Indexes.Select(index => index.IndexKey));
        Assert.Equal(["protocol.projector.repository-target-resolution-demand"], registry.DemandProjectors.Select(projector => projector.ProjectorKey));
        Assert.Equal(["protocol.admission.failed", "protocol.admission.no-input", "protocol.admission.observed"], registry.AdmissionProofContracts.Select(contract => contract.ContractKey));
        Assert.Equal([
            "protocol.admission.failed|failed|protocol.admission-proof.failed",
            "protocol.admission.no-input|no-input|protocol.admission-proof.no-input",
            "protocol.admission.observed|observed|protocol.admission-proof.observed"],
            registry.AdmissionProofContracts.Select(contract => $"{contract.ContractKey}|{contract.Kind.Value}|{contract.ProofComponent.ComponentKey}"));
        Assert.Equal((512, 67_108_864L, 128, 2_000_000L, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys),
            (registry.CacheBudget.MaxDecodeEntries, registry.CacheBudget.MaxDecodeCanonicalBytes, registry.CacheBudget.MaxIndexEntries,
             registry.CacheBudget.MaxIndexNodes, registry.CacheBudget.MaxConcurrentDecodeAttempts, registry.CacheBudget.MaxConcurrentIndexAttempts,
             registry.CacheBudget.RetentionPolicy));
        Assert.Equal([
            "protocol.governed-text|200000/67108864|4194304/256/500000/5000000|protocol.codec.embedded-identity-mismatch,protocol.codec.invalid-utf8,protocol.codec.noncanonical-encoding,protocol.codec.payload-location-mismatch,protocol.codec.resource-limit-exceeded",
            "protocol.repository-target-resolution|1/33554432|33554432/64/500000/34054432|protocol.codec.embedded-identity-mismatch,protocol.codec.invalid-repository-target-resolution,protocol.codec.payload-location-mismatch,protocol.codec.resource-limit-exceeded",
            "protocol.repository-tree|1/16777216|16777216/64/200000/2000000|protocol.codec.embedded-identity-mismatch,protocol.codec.invalid-repository-tree,protocol.codec.payload-location-mismatch,protocol.codec.resource-limit-exceeded"],
            registry.PayloadSchemas.Select(schema => $"{schema.SchemaKey}|{schema.MaxBindingsPerInstruction}/{schema.MaxRetainedCanonicalBytesPerInstruction}|{BudgetText(schema.Budget)}|{string.Join(',', schema.CodecFailureCodes)}"));
        Assert.Equal([
            "protocol.parser.markdown|4194304/256/500000/5000000|protocol.budget.exhausted,protocol.model.invalid-markdown",
            "protocol.parser.repository-target-markdown|33554432/256/1000000/34554432|protocol.budget.exhausted"],
            registry.Parsers.Select(parser => $"{parser.ParserKey}|{BudgetText(parser.Budget)}|{string.Join(',', parser.FailureCodes.Select(code => code.Value))}"));
        Assert.Equal([
            "protocol.index.governed-reference|67108864/256/1000000/10000000|protocol.budget.exhausted,protocol.index.reference-unavailable",
            "protocol.index.protocol-record|67108864/256/1000000/10000000|protocol.budget.exhausted,protocol.index.record-unavailable",
            "protocol.index.repository-target-resolution|67108864/256/2000000/20000000|protocol.budget.exhausted,protocol.index.repository-target-resolution-unavailable",
            "protocol.index.repository-tree|16777216/64/200000/2000000|protocol.budget.exhausted,protocol.index.repository-tree-unavailable"],
            registry.Indexes.Select(index => $"{index.IndexKey}|{BudgetText(index.Budget)}|{string.Join(',', index.FailureCodes.Select(code => code.Value))}"));
        var projector = Assert.Single(registry.DemandProjectors);
        Assert.Equal((33_554_432L, 64, 100_000L, 5_000_000L),
            (projector.Budget.MaxBytes, projector.Budget.MaxDepth, projector.Budget.MaxNodes, projector.Budget.MaxComplexity));
        Assert.Equal(["protocol.budget.exhausted"], projector.FailureCodes.Select(code => code.Value));
        Assert.All(registry.AdmissionProofContracts, contract =>
        {
            Assert.Equal("1", contract.ContractVersion);
            Assert.Equal(SurfaceSet.Create([SurfaceKind.Repository, SurfaceKind.Provider]), contract.Surfaces);
            Assert.Equal(["protocol.material.governed-text", "protocol.material.repository-target-resolution", "protocol.material.repository-tree"], contract.MaterialRoles);
        });

        Assert.Equal(("protocol.activation.release-envelope", "1", "protocol.activation-proof.release-envelope", "1"),
            (manifest.ActivationProofContract.ContractKey, manifest.ActivationProofContract.ContractVersion,
             manifest.ActivationProofContract.ProofComponent.ComponentKey, manifest.ActivationProofContract.ProofComponent.ComponentVersion));

        Assert.Equal(["Markdig.dll", "MeAndAI.Protocol.Application.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Conformance.dll", "MeAndAI.Protocol.Domain.dll", "MeAndAI.Protocol.Policy.dll"],
            manifest.ArtifactFiles.Select(artifact => artifact.FileName));
        Assert.All(manifest.ArtifactFiles, artifact =>
        {
            Assert.Equal(1L, artifact.ByteLength);
            Assert.Equal(Digest, artifact.ArtifactDigest.Value);
        });
        Assert.Equal(Components.Select(component => $"{component.Key}|1|{component.Assembly}|{component.Type}|{ArtifactName(component.Assembly)}"),
            manifest.Components.Select(binding => $"{binding.Component.ComponentKey}|{binding.Component.ComponentVersion}|{binding.Component.AssemblyName}|{binding.Component.TypeName}|{binding.ArtifactFileName}"));
        Assert.True(manifest.ArtifactFiles.Select(artifact => artifact.FileName).ToHashSet(StringComparer.Ordinal)
            .SetEquals(manifest.Components.Select(binding => binding.ArtifactFileName)));
        Assert.Equal([
            "Markdig=1", "MeAndAI.Protocol.Application=4", "MeAndAI.Protocol.Conformance=1",
            "MeAndAI.Protocol.Conformance.Abstractions=5", "MeAndAI.Protocol.Domain=1", "MeAndAI.Protocol.Policy=23"],
            manifest.Components.GroupBy(binding => binding.Component.AssemblyName, StringComparer.Ordinal)
                .OrderBy(group => group.Key, StringComparer.Ordinal).Select(group => $"{group.Key}={group.Count()}"));

        var allKeys = manifest.Components.Select(binding => binding.Component.ComponentKey).ToHashSet(StringComparer.Ordinal);
        var runtime = allKeys.Where(key => key.StartsWith("protocol.runtime.", StringComparison.Ordinal)).ToHashSet(StringComparer.Ordinal);
        var activation = allKeys.Where(key => key == "protocol.activation-proof.release-envelope").ToHashSet(StringComparer.Ordinal);
        var admission = allKeys.Where(key => key.StartsWith("protocol.admission-proof.", StringComparison.Ordinal)).ToHashSet(StringComparer.Ordinal);
        var logicalPolicy = allKeys.Except(runtime).Except(activation).Except(admission).ToHashSet(StringComparer.Ordinal);
        Assert.Equal((27, 4, 1, 3, 35), (logicalPolicy.Count, runtime.Count, activation.Count, admission.Count,
            logicalPolicy.Concat(runtime).Concat(activation).Concat(admission).Distinct(StringComparer.Ordinal).Count()));
        Assert.True(allKeys.SetEquals(logicalPolicy.Concat(runtime).Concat(activation).Concat(admission)));
        Assert.True(CatalogSliceDeclaration.ValidateSchemaSlotClosure(registry, rules).ProducerRootIdentities.SetEquals(
            [new ProducerIdentity("Schema", "protocol.governed-text", "1"), new ProducerIdentity("Schema", "protocol.repository-tree", "1")]));
    }

    internal static ParsedCanonicalManifest CreateManifest(
        IReadOnlyList<RuleDeclaration>? rules = null,
        IReadOnlyList<AdmissionProofContractDeclaration>? admissions = null)
    {
        rules ??= Rules();
        var artifacts = new[] { "Markdig.dll", "MeAndAI.Protocol.Application.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll", "MeAndAI.Protocol.Conformance.dll", "MeAndAI.Protocol.Domain.dll", "MeAndAI.Protocol.Policy.dll" }.Select(Artifact).ToArray();
        var components = Components.Select(component => ComponentArtifactBinding.Create(Resolve(component.Key), ArtifactName(component.Assembly))).ToArray();
        var slice = CatalogSliceDeclaration.Create("protocol.catalog-slice.initial-common-rules", "1", "0.17.0", CatalogVersion.Create(1), rules);
        return new ParsedCanonicalManifest(CatalogAuthorityKind.QualificationSlice, Commit, Registry(admissions),
            ActivationProofContractDeclaration.Create("protocol.activation.release-envelope", "1", Resolve("protocol.activation-proof.release-envelope")), artifacts, components, slice);
    }

    private static RuleDeclaration[] Rules() => [Rule0001(), Rule0002(), Rule0003(), Rule0004(), Rule0005()];
    private static AdmissionProofContractDeclaration[] Admissions(
        string? sharedKey = null,
        string? observedProofKey = null,
        SurfaceSet? observedSurfaces = null,
        IReadOnlyList<string>? observedRoles = null) =>
    [
        Admission(sharedKey ?? "protocol.admission.failed", AdmissionProofKind.Failed),
        Admission(sharedKey ?? "protocol.admission.no-input", AdmissionProofKind.NoInput),
        Admission(sharedKey ?? "protocol.admission.observed", AdmissionProofKind.Observed, observedProofKey, observedSurfaces, observedRoles),
    ];

    private static void Reject(Func<ParsedCanonicalManifest> create, string message)
    {
        var exception = Assert.Throws<ArgumentException>(() => CanonicalManifestWriter.Write(create()));
        Assert.Equal("rules", exception.ParamName);
        Assert.Equal(new ArgumentException(message, "rules").Message, exception.Message);
    }

    private static string BudgetText(SemanticResourceBudget budget) =>
        $"{budget.MaxBytes}/{budget.MaxDepth}/{budget.MaxNodes}/{budget.MaxComplexity}";

    private static ReleaseSchemaRegistry Registry(IReadOnlyList<AdmissionProofContractDeclaration>? admissions = null) => ReleaseSchemaRegistry.Create(
        [GovernedSchema(), TargetSchema(), TreeSchema()],
        [MarkdownParser(), TargetParser()],
        [GovernedIndex(), RecordIndex(), TargetIndex(), TreeIndex()],
        [Projector()],
        admissions ?? Admissions(),
        SessionCacheBudget.Create(512, 67_108_864, 128, 2_000_000, 8, 4, CacheRetentionPolicy.RetainLowestCanonicalKeys));

    private static PayloadSchemaDeclaration GovernedSchema() => PayloadSchemaDeclaration.Create("protocol.governed-text", "1", Resolve("protocol.codec.governed-text"), SourceModel(), 200_000, 67_108_864, Budget(4_194_304, 256, 500_000, 5_000_000), Codes("protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-utf8", "protocol.codec.noncanonical-encoding", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"));
    private static PayloadSchemaDeclaration TargetSchema() => PayloadSchemaDeclaration.Create("protocol.repository-target-resolution", "1", Resolve("protocol.codec.repository-target-resolution"), TargetResolutionModel(), 1, 33_554_432, Budget(33_554_432, 64, 500_000, 34_054_432), Codes("protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-target-resolution", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"));
    private static PayloadSchemaDeclaration TreeSchema() => PayloadSchemaDeclaration.Create("protocol.repository-tree", "1", Resolve("protocol.codec.repository-tree"), TreeModel(), 1, 16_777_216, Budget(16_777_216, 64, 200_000, 2_000_000), Codes("protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-tree", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded"));
    private static SemanticModelParserDeclaration MarkdownParser() => SemanticModelParserDeclaration.Create("protocol.parser.markdown", "1", Resolve("protocol.parser.markdown"), [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)], MarkdownModel(), Budget(4_194_304, 256, 500_000, 5_000_000), Failures("protocol.budget.exhausted", "protocol.model.invalid-markdown"));
    private static SemanticModelParserDeclaration TargetParser() => SemanticModelParserDeclaration.Create("protocol.parser.repository-target-markdown", "1", Resolve("protocol.parser.repository-target-markdown"), [ComponentInputDeclaration.ForModel(TargetResolutionModel(), 1, 1)], TargetMarkdownModel(), Budget(33_554_432, 256, 1_000_000, 34_554_432), Failures("protocol.budget.exhausted"));
    private static ContextIndexDeclaration GovernedIndex() => ContextIndexDeclaration.Create("protocol.index.governed-reference", "1", Resolve("protocol.index.governed-reference"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(RecordCapability(), 1, null), ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], GovernedCapability(), Budget(67_108_864, 256, 1_000_000, 10_000_000), Failures("protocol.budget.exhausted", "protocol.index.reference-unavailable"));
    private static ContextIndexDeclaration RecordIndex() => ContextIndexDeclaration.Create("protocol.index.protocol-record", "1", Resolve("protocol.index.protocol-record"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)], RecordCapability(), Budget(67_108_864, 256, 1_000_000, 10_000_000), Failures("protocol.budget.exhausted", "protocol.index.record-unavailable"));
    private static ContextIndexDeclaration TargetIndex() => ContextIndexDeclaration.Create("protocol.index.repository-target-resolution", "1", Resolve("protocol.index.repository-target-resolution"), IndexInvocationScope.PerPlan, [ComponentInputDeclaration.ForCapability(GovernedCapability(), 1, 1), ComponentInputDeclaration.ForModel(TargetResolutionModel(), 0, null), ComponentInputDeclaration.ForModel(TargetMarkdownModel(), 0, null)], TargetCapability(), Budget(67_108_864, 256, 2_000_000, 20_000_000), Failures("protocol.budget.exhausted", "protocol.index.repository-target-resolution-unavailable"));
    private static ContextIndexDeclaration TreeIndex() => ContextIndexDeclaration.Create("protocol.index.repository-tree", "1", Resolve("protocol.index.repository-tree"), IndexInvocationScope.PerContext, [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)], TreeCapability(), Budget(16_777_216, 64, 200_000, 2_000_000), Failures("protocol.budget.exhausted", "protocol.index.repository-tree-unavailable"));
    private static AcquisitionDemandProjectorDeclaration Projector() => AcquisitionDemandProjectorDeclaration.Create("protocol.projector.repository-target-resolution-demand", "1", Resolve("protocol.projector.repository-target-resolution-demand"), GovernedCapability(), ["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text"], "protocol.slot.repository-target-resolution", "protocol.repository-target-resolution-demand", "1", Budget(33_554_432, 64, 100_000, 5_000_000), Failures("protocol.budget.exhausted"));
    private static AdmissionProofContractDeclaration Admission(
        string key,
        AdmissionProofKind kind,
        string? proofKey = null,
        SurfaceSet? surfaces = null,
        IReadOnlyList<string>? roles = null) => AdmissionProofContractDeclaration.Create(
            key, "1", kind, Resolve(proofKey ?? "protocol.admission-proof." + kind.Value),
            surfaces ?? SurfaceSet.Create([SurfaceKind.Repository, SurfaceKind.Provider]),
            roles ?? ["protocol.material.repository-tree", "protocol.material.governed-text", "protocol.material.repository-target-resolution"]);

    private static RuleDeclaration Rule0001() => Rule(
        "RULE-0001", "69fa9341b359ed5393ba6c92dd0682abecb5bc15e1745d8cddc07583744544fe",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.feature-packet", 520, 521, 84, "15d1991754f47a2ab096a32e5bbbcc4e8e20b8e95554364eac29da8c6114c3d7")],
        ["TEST-0004"], [TreeSlot()], [Selector("protocol.selector.feature-readme", "protocol.slot.repository-tree", "protocol.selector.relative-child.v1", "protocol.feature.readme-missing"), Selector("protocol.selector.feature-test-cases", "protocol.slot.repository-tree", "protocol.selector.relative-child.v1", "protocol.feature.test-cases-missing")],
        [SurfaceKind.Repository], [SnapshotKind.ExactCommit, SnapshotKind.Candidate, SnapshotKind.ProviderFullInventory, SnapshotKind.CapturedEvidence],
        [Finding("protocol.feature.readme-missing", "protocol.remediation.feature-packet", [QualifiedEvidenceReferenceKind.ExpectedSelector], RelatedAll()), Finding("protocol.feature.test-cases-missing", "protocol.remediation.feature-packet", [QualifiedEvidenceReferenceKind.ExpectedSelector], RelatedAll())], []);

    private static RuleDeclaration Rule0002(EvidenceSlotDeclaration? treeSlot = null) => Rule(
        "RULE-0002", "321aca48e204e7f3ddba9a327e57ad9184c9ec838160d1cd50b0afcf1c57121f",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.decision-record", 522, 523, 92, "a4588d88bea471839d750e4889d4deaabd422562053ab7caca5c11eede2ee243"), Fragment("templates/decision.md", TemplateBlob, "template.decision.required-structure", 1, 30, 677, "63a1ad23d40e8b228f9efc6e85fb76a91aee46e707a4fbd2536aab081c4c3aa5")],
        ["TEST-0005"], [treeSlot ?? TreeSlot(), RepositoryGovernedSlot()], [Selector("protocol.selector.decision-record", "protocol.slot.repository-governed-text", "protocol.selector.decision-record-by-id.v1", "protocol.decision.record-missing")],
        [SurfaceKind.Repository], [SnapshotKind.ExactCommit, SnapshotKind.Candidate, SnapshotKind.ProviderFullInventory, SnapshotKind.CapturedEvidence],
        [Finding("protocol.decision.record-missing", "protocol.remediation.decision-structure", [QualifiedEvidenceReferenceKind.ExpectedSelector], RelatedAll()), Finding("protocol.decision.structure-invalid", "protocol.remediation.decision-structure", [QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Derived], RelatedAll())], []);

    private static RuleDeclaration Rule0003() => Rule(
        "RULE-0003", "cac99d8884e9737f3db976b4ea10d175f87b8b526af38d9442d964443ef2639e",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.clickable-exact-target", 496, 508, 911, "a27cab5b79026b0b72839de0d88ade32fe37aeaa5a46a2076dea5f54cdfcf37f"), Fragment("PROTOCOL.md", ProtocolBlob, "protocol.repository-provider-reference-form", 535, 543, 680, "26d715022a371aa5154254bca291adb4e0f87bc6a43a913a6ff93727e9b54065"), Fragment("PROTOCOL.md", ProtocolBlob, "protocol.link-validation", 554, 555, 156, "fca31621542242a9243eb5ef4efc799e0614c7dcc7ceb502600b2fe5ce60d021")],
        ["TEST-0175", "TEST-0176", "TEST-0177"], LinkSlots(), [], BothSurfaces(), FullSnapshots(),
        Findings("protocol.remediation.exact-link", "protocol.reference.not-clickable", "protocol.reference.unsupported-authoring-form", "protocol.reference.wrong-target", "protocol.reference.unresolved-target"), ["protocol.evaluator.reference-ambiguity"]);

    private static RuleDeclaration Rule0004() => Rule(
        "RULE-0004", "951932712706a09ee94dbdb784533d48ae2895c962d94476dde98da92fbf8e69",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.addressable-target-fragment", 500, 504, 365, "527f9b4fa06345a74c50da8388fd5704608f808c4a0ffc2963789425f69220f0"), Fragment("PROTOCOL.md", ProtocolBlob, "protocol.embedded-stable-id-anchor", 509, 517, 620, "c992774d3b8a2a4ccd1e910991ef623b04ac925c176ba994c978380834a6f702"), Fragment("PROTOCOL.md", ProtocolBlob, "protocol.fragment-target-form", 535, 546, 887, "12fec7ac5a00e0ba137bc49f41ac7e54799e5e4b8278b5a785ef558ff7f8bd8f")],
        ["TEST-0177"], LinkSlots(), [], BothSurfaces(), FullSnapshots(),
        Findings("protocol.remediation.stable-fragment", "protocol.record.anchor-missing", "protocol.record.anchor-duplicate", "protocol.reference.fragment-missing", "protocol.reference.fragment-wrong"), ["protocol.evaluator.reference-ambiguity"]);

    private static RuleDeclaration Rule0005() => Rule(
        "RULE-0005", "e4512349b2fb23f6a367675f6a0b43bfe936c109d3109773d304affc5a1dd0b3",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.commit-permalink", 547, 553, 509, "203c70b6f2211f453b711c56d3a669a573cae728513b46d5706e1e8ec8d06231")],
        ["TEST-0178"], LinkSlots(), [], BothSurfaces(), FullSnapshots(),
        Findings("protocol.remediation.commit-permalink", "protocol.commit-reference.not-permalink", "protocol.commit-reference.wrong-repository", "protocol.commit-reference.wrong-object", "protocol.commit-reference.unresolved"), ["protocol.evaluator.reference-ambiguity", "protocol.evaluator.commit-intent-ambiguity"]);

    private static RuleDeclaration Rule(string id, string digest, IReadOnlyList<NormativeFragmentDeclaration> fragments, IEnumerable<string> scenarios, IReadOnlyList<EvidenceSlotDeclaration> slots, IReadOnlyList<ExpectedSelectorDeclaration> selectors, SurfaceKind[] surfaces, SnapshotKind[] snapshots, IReadOnlyList<FindingDeclaration> findings, IEnumerable<string> failures) => RuleDeclaration.Create(
        RuleId.Parse(id), RuleRevision.Create(1), CatalogVersion.Create(1), ExactSha256Digest.Parse(digest), fragments, scenarios.Select(TestScenarioId.Parse), Resolve("protocol.evaluator." + id.ToLowerInvariant()), [], slots, selectors,
        [SubjectRole.ProtocolAuthoritySelfConsumer, SubjectRole.Consumer], SurfaceSet.Create(surfaces), snapshots, [ProtocolOperation.Conformance], findings, failures.Select(EvaluationFailureCode.Parse), "0.17.0", null, null, []);
    private static NormativeFragmentDeclaration Fragment(string path, string blob, string anchor, int start, int end, long length, string digest) => NormativeFragmentDeclaration.Create(path, blob, anchor, start, end, "protocol.normative-fragment.utf8-lines.v1", length, ExactSha256Digest.Parse(digest));
    private static ExpectedSelectorDeclaration Selector(string key, string slot, string schema, string finding) => ExpectedSelectorDeclaration.Create(key, slot, schema, Resolve(key), [QualifiedEvidenceReferenceKind.Derived], [FindingCode.Parse(finding)]);
    private static FindingDeclaration Finding(string code, string remediation, IReadOnlyList<QualifiedEvidenceReferenceKind> primary, IReadOnlyList<QualifiedEvidenceReferenceKind> related) => FindingDeclaration.Create(FindingCode.Parse(code), FindingSeverity.Parse("protocol.finding.error"), RemediationKey.Parse(remediation), primary, related);
    private static IReadOnlyList<FindingDeclaration> Findings(string remediation, params string[] codes) => codes.Select(code => Finding(code, remediation, [QualifiedEvidenceReferenceKind.Derived], [QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Derived])).ToArray();
    private static QualifiedEvidenceReferenceKind[] RelatedAll() => [QualifiedEvidenceReferenceKind.ContextProof, QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Derived];
    private static EvidenceSlotDeclaration[] LinkSlots() => [RepositoryGovernedSlot(), ProviderGovernedSlot(), TargetSlot()];
    private static SurfaceKind[] BothSurfaces() => [SurfaceKind.Repository, SurfaceKind.Provider];
    private static SnapshotKind[] FullSnapshots() => [SnapshotKind.ExactCommit, SnapshotKind.Candidate, SnapshotKind.ProviderEvent, SnapshotKind.ProviderFullInventory, SnapshotKind.CapturedEvidence];

    private static EvidenceSlotDeclaration RepositoryGovernedSlot() => GovernedSlot("repository", SurfaceKind.Repository, [SurfaceKind.Repository, SurfaceKind.Provider]);
    private static EvidenceSlotDeclaration ProviderGovernedSlot() => GovernedSlot("provider", SurfaceKind.Provider, [SurfaceKind.Provider]);
    private static EvidenceSlotDeclaration GovernedSlot(string scope, SurfaceKind surface, SurfaceKind[] profiles) => EvidenceSlotDeclaration.Create("protocol.slot." + scope + "-governed-text", EvidenceRequirement.Create("protocol.requirement." + scope + "-governed-text", surface, "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", "1", [EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.BoundedNonAtomicObservation]), SurfaceSet.Create(profiles), "protocol.material.governed-text", "protocol.target." + scope + "-governed-body-set", [RecordCapability(), GovernedCapability()]);
    private static EvidenceSlotDeclaration TargetSlot() => EvidenceSlotDeclaration.Create("protocol.slot.repository-target-resolution", EvidenceRequirement.Create("protocol.requirement.repository-target-resolution", SurfaceKind.Repository, "protocol.evidence.repository-target-resolution-set", "protocol.completeness.all-projected-target-resolutions", "protocol.repository-target-resolution", "1", [EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound]), SurfaceSet.Create([SurfaceKind.Repository, SurfaceKind.Provider]), "protocol.material.repository-target-resolution", "protocol.target.repository-target-resolution-set", [TargetCapability()]);
    private static EvidenceSlotDeclaration TreeSlot(string target = "protocol.target.repository-snapshot") => EvidenceSlotDeclaration.Create("protocol.slot.repository-tree", EvidenceRequirement.Create("protocol.requirement.repository-tree", SurfaceKind.Repository, "protocol.evidence.repository-tree", "protocol.completeness.full-tree", "protocol.repository-tree", "1", [EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.BoundedNonAtomicObservation]), SurfaceSet.Create([SurfaceKind.Repository]), "protocol.material.repository-tree", target, [TreeCapability()]);

    private static ModelContractIdentity SourceModel() => Model("protocol.model.source-text", "protocol.type.model.source-text");
    private static ModelContractIdentity MarkdownModel() => Model("protocol.model.markdown-document", "protocol.type.model.markdown-document");
    private static ModelContractIdentity TargetMarkdownModel() => Model("protocol.model.repository-target-markdown-document-set", "protocol.type.model.repository-target-markdown-document-set");
    private static ModelContractIdentity TargetResolutionModel() => Model("protocol.model.repository-target-resolution", "protocol.type.model.repository-target-resolution");
    private static ModelContractIdentity TreeModel() => Model("protocol.model.repository-tree", "protocol.type.model.repository-tree");
    private static ModelContractIdentity Model(string key, string type) => ModelContractIdentity.Create(key, "1", Resolve(type));
    private static CapabilityContractIdentity GovernedCapability() => Capability("protocol.capability.governed-reference-index", "protocol.type.capability.governed-reference-index");
    private static CapabilityContractIdentity RecordCapability() => Capability("protocol.capability.protocol-record-index", "protocol.type.capability.protocol-record-index");
    private static CapabilityContractIdentity TargetCapability() => Capability("protocol.capability.repository-target-resolution-index", "protocol.type.capability.repository-target-resolution-index");
    private static CapabilityContractIdentity TreeCapability() => Capability("protocol.capability.repository-tree", "protocol.type.capability.repository-tree");
    private static CapabilityContractIdentity Capability(string key, string type) => CapabilityContractIdentity.Create(key, "1", Resolve(type));
    private static SemanticResourceBudget Budget(long bytes, int depth, long nodes, long complexity) => SemanticResourceBudget.Create(bytes, depth, nodes, complexity);
    private static IEnumerable<string> Codes(params string[] codes) => codes;
    private static IEnumerable<EvaluationFailureCode> Failures(params string[] codes) => codes.Select(EvaluationFailureCode.Parse);
    private static ComponentTypeIdentity Resolve(string key) { var component = Components.Single(candidate => candidate.Key == key); return ComponentTypeIdentity.Create(key, "1", component.Assembly, component.Type); }
    private static ArtifactFileBinding Artifact(string name) => ArtifactFileBinding.Create(name, 1, ExactSha256Digest.Parse(Digest));
    private static string ArtifactName(string assembly) => assembly + ".dll";
}
