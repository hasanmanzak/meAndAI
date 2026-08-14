using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Policy.Declarations;

internal static class InitialPolicyDeclarations
{
    private const string ProtocolBlob =
        "4698461c34196bc3639498d6b137f87e5a8bbe5d";
    private const string TemplateBlob =
        "a222f89700ea589dfbda683d69ad0ad50c48d72a";

    private static readonly (string Key, string Assembly, string Type)[]
        Components =
    [
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

    internal static InitialPolicyDeclarationSet Create()
    {
        var registry = ReleaseSchemaRegistry.Create(
            [GovernedSchema(), TargetSchema(), TreeSchema()],
            [MarkdownParser(), TargetParser()],
            [GovernedIndex(), RecordIndex(), TargetIndex(), TreeIndex()],
            [Projector()],
            Admissions(),
            SessionCacheBudget.Create(
                512,
                67_108_864,
                128,
                2_000_000,
                8,
                4,
                CacheRetentionPolicy.RetainLowestCanonicalKeys));
        var catalog = CatalogSliceDeclaration.Create(
            "protocol.catalog-slice.initial-common-rules",
            "1",
            "0.17.0",
            CatalogVersion.Create(1),
            [Rule0001(), Rule0002(), Rule0003(), Rule0004(), Rule0005()]);
        return new InitialPolicyDeclarationSet(catalog, registry);
    }

    private static AdmissionProofContractDeclaration[] Admissions() =>
    [
        Admission(AdmissionProofKind.Failed),
        Admission(AdmissionProofKind.NoInput),
        Admission(AdmissionProofKind.Observed),
    ];

    private static AdmissionProofContractDeclaration Admission(
        AdmissionProofKind kind) => AdmissionProofContractDeclaration.Create(
        "protocol.admission." + kind.Value,
        "1",
        kind,
        Resolve("protocol.admission-proof." + kind.Value),
        SurfaceSet.Create([SurfaceKind.Repository, SurfaceKind.Provider]),
        [
            "protocol.material.repository-tree",
            "protocol.material.governed-text",
            "protocol.material.repository-target-resolution",
        ]);

    private static PayloadSchemaDeclaration GovernedSchema() =>
        PayloadSchemaDeclaration.Create(
            "protocol.governed-text",
            "1",
            Resolve("protocol.codec.governed-text"),
            SourceModel(),
            200_000,
            67_108_864,
            Budget(4_194_304, 256, 500_000, 5_000_000),
            Codes(
                "protocol.codec.embedded-identity-mismatch",
                "protocol.codec.invalid-utf8",
                "protocol.codec.noncanonical-encoding",
                "protocol.codec.payload-location-mismatch",
                "protocol.codec.resource-limit-exceeded"));

    private static PayloadSchemaDeclaration TargetSchema() =>
        PayloadSchemaDeclaration.Create(
            "protocol.repository-target-resolution",
            "1",
            Resolve("protocol.codec.repository-target-resolution"),
            TargetResolutionModel(),
            1,
            33_554_432,
            Budget(33_554_432, 64, 500_000, 34_054_432),
            Codes(
                "protocol.codec.embedded-identity-mismatch",
                "protocol.codec.invalid-repository-target-resolution",
                "protocol.codec.payload-location-mismatch",
                "protocol.codec.resource-limit-exceeded"));

    private static PayloadSchemaDeclaration TreeSchema() =>
        PayloadSchemaDeclaration.Create(
            "protocol.repository-tree",
            "1",
            Resolve("protocol.codec.repository-tree"),
            TreeModel(),
            1,
            16_777_216,
            Budget(16_777_216, 64, 200_000, 2_000_000),
            Codes(
                "protocol.codec.embedded-identity-mismatch",
                "protocol.codec.invalid-repository-tree",
                "protocol.codec.payload-location-mismatch",
                "protocol.codec.resource-limit-exceeded"));

    private static SemanticModelParserDeclaration MarkdownParser() =>
        SemanticModelParserDeclaration.Create(
            "protocol.parser.markdown",
            "1",
            Resolve("protocol.parser.markdown"),
            [ComponentInputDeclaration.ForModel(SourceModel(), 1, 1)],
            MarkdownModel(),
            Budget(4_194_304, 256, 500_000, 5_000_000),
            Failures(
                "protocol.budget.exhausted",
                "protocol.model.invalid-markdown"));

    private static SemanticModelParserDeclaration TargetParser() =>
        SemanticModelParserDeclaration.Create(
            "protocol.parser.repository-target-markdown",
            "1",
            Resolve("protocol.parser.repository-target-markdown"),
            [ComponentInputDeclaration.ForModel(TargetResolutionModel(), 1, 1)],
            TargetMarkdownModel(),
            Budget(33_554_432, 256, 1_000_000, 34_554_432),
            Failures("protocol.budget.exhausted"));

    private static ContextIndexDeclaration GovernedIndex() =>
        ContextIndexDeclaration.Create(
            "protocol.index.governed-reference",
            "1",
            Resolve("protocol.index.governed-reference"),
            IndexInvocationScope.PerPlan,
            [
                ComponentInputDeclaration.ForCapability(RecordCapability(), 1, null),
                ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null),
            ],
            GovernedCapability(),
            Budget(67_108_864, 256, 1_000_000, 10_000_000),
            Failures(
                "protocol.budget.exhausted",
                "protocol.index.reference-unavailable"));

    private static ContextIndexDeclaration RecordIndex() =>
        ContextIndexDeclaration.Create(
            "protocol.index.protocol-record",
            "1",
            Resolve("protocol.index.protocol-record"),
            IndexInvocationScope.PerContext,
            [ComponentInputDeclaration.ForModel(MarkdownModel(), 0, null)],
            RecordCapability(),
            Budget(67_108_864, 256, 1_000_000, 10_000_000),
            Failures(
                "protocol.budget.exhausted",
                "protocol.index.record-unavailable"));

    private static ContextIndexDeclaration TargetIndex() =>
        ContextIndexDeclaration.Create(
            "protocol.index.repository-target-resolution",
            "1",
            Resolve("protocol.index.repository-target-resolution"),
            IndexInvocationScope.PerPlan,
            [
                ComponentInputDeclaration.ForCapability(GovernedCapability(), 1, 1),
                ComponentInputDeclaration.ForModel(TargetResolutionModel(), 0, null),
                ComponentInputDeclaration.ForModel(TargetMarkdownModel(), 0, null),
            ],
            TargetCapability(),
            Budget(67_108_864, 256, 2_000_000, 20_000_000),
            Failures(
                "protocol.budget.exhausted",
                "protocol.index.repository-target-resolution-unavailable"));

    private static ContextIndexDeclaration TreeIndex() =>
        ContextIndexDeclaration.Create(
            "protocol.index.repository-tree",
            "1",
            Resolve("protocol.index.repository-tree"),
            IndexInvocationScope.PerContext,
            [ComponentInputDeclaration.ForModel(TreeModel(), 1, 1)],
            TreeCapability(),
            Budget(16_777_216, 64, 200_000, 2_000_000),
            Failures(
                "protocol.budget.exhausted",
                "protocol.index.repository-tree-unavailable"));

    private static AcquisitionDemandProjectorDeclaration Projector() =>
        AcquisitionDemandProjectorDeclaration.Create(
            "protocol.projector.repository-target-resolution-demand",
            "1",
            Resolve("protocol.projector.repository-target-resolution-demand"),
            GovernedCapability(),
            [
                "protocol.slot.provider-governed-text",
                "protocol.slot.repository-governed-text",
            ],
            "protocol.slot.repository-target-resolution",
            "protocol.repository-target-resolution-demand",
            "1",
            Budget(33_554_432, 64, 100_000, 5_000_000),
            Failures("protocol.budget.exhausted"));

    private static RuleDeclaration Rule0001() => Rule(
        "RULE-0001",
        "69fa9341b359ed5393ba6c92dd0682abecb5bc15e1745d8cddc07583744544fe",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.feature-packet", 520, 521, 84, "15d1991754f47a2ab096a32e5bbbcc4e8e20b8e95554364eac29da8c6114c3d7")],
        ["TEST-0004"],
        [TreeSlot()],
        [
            Selector("protocol.selector.feature-readme", "protocol.slot.repository-tree", "protocol.selector.relative-child.v1", "protocol.feature.readme-missing"),
            Selector("protocol.selector.feature-test-cases", "protocol.slot.repository-tree", "protocol.selector.relative-child.v1", "protocol.feature.test-cases-missing"),
        ],
        [SurfaceKind.Repository],
        RepositorySnapshots(),
        [
            Finding("protocol.feature.readme-missing", "protocol.remediation.feature-packet", [QualifiedEvidenceReferenceKind.ExpectedSelector], RelatedAll()),
            Finding("protocol.feature.test-cases-missing", "protocol.remediation.feature-packet", [QualifiedEvidenceReferenceKind.ExpectedSelector], RelatedAll()),
        ],
        []);

    private static RuleDeclaration Rule0002() => Rule(
        "RULE-0002",
        "321aca48e204e7f3ddba9a327e57ad9184c9ec838160d1cd50b0afcf1c57121f",
        [
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.decision-record", 522, 523, 92, "a4588d88bea471839d750e4889d4deaabd422562053ab7caca5c11eede2ee243"),
            Fragment("templates/decision.md", TemplateBlob, "template.decision.required-structure", 1, 30, 677, "63a1ad23d40e8b228f9efc6e85fb76a91aee46e707a4fbd2536aab081c4c3aa5"),
        ],
        ["TEST-0005"],
        [TreeSlot(), RepositoryGovernedSlot()],
        [Selector("protocol.selector.decision-record", "protocol.slot.repository-governed-text", "protocol.selector.decision-record-by-id.v1", "protocol.decision.record-missing")],
        [SurfaceKind.Repository],
        RepositorySnapshots(),
        [
            Finding("protocol.decision.record-missing", "protocol.remediation.decision-structure", [QualifiedEvidenceReferenceKind.ExpectedSelector], RelatedAll()),
            Finding("protocol.decision.structure-invalid", "protocol.remediation.decision-structure", [QualifiedEvidenceReferenceKind.Root, QualifiedEvidenceReferenceKind.Derived], RelatedAll()),
        ],
        []);

    private static RuleDeclaration Rule0003() => Rule(
        "RULE-0003",
        "cac99d8884e9737f3db976b4ea10d175f87b8b526af38d9442d964443ef2639e",
        [
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.clickable-exact-target", 496, 508, 911, "a27cab5b79026b0b72839de0d88ade32fe37aeaa5a46a2076dea5f54cdfcf37f"),
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.repository-provider-reference-form", 535, 543, 680, "26d715022a371aa5154254bca291adb4e0f87bc6a43a913a6ff93727e9b54065"),
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.link-validation", 554, 555, 156, "fca31621542242a9243eb5ef4efc799e0614c7dcc7ceb502600b2fe5ce60d021"),
        ],
        ["TEST-0175", "TEST-0176", "TEST-0177"],
        LinkSlots(),
        [],
        BothSurfaces(),
        FullSnapshots(),
        Findings("protocol.remediation.exact-link", "protocol.reference.not-clickable", "protocol.reference.unsupported-authoring-form", "protocol.reference.wrong-target", "protocol.reference.unresolved-target"),
        ["protocol.evaluator.reference-ambiguity"]);

    private static RuleDeclaration Rule0004() => Rule(
        "RULE-0004",
        "951932712706a09ee94dbdb784533d48ae2895c962d94476dde98da92fbf8e69",
        [
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.addressable-target-fragment", 500, 504, 365, "527f9b4fa06345a74c50da8388fd5704608f808c4a0ffc2963789425f69220f0"),
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.embedded-stable-id-anchor", 509, 517, 620, "c992774d3b8a2a4ccd1e910991ef623b04ac925c176ba994c978380834a6f702"),
            Fragment("PROTOCOL.md", ProtocolBlob, "protocol.fragment-target-form", 535, 546, 887, "12fec7ac5a00e0ba137bc49f41ac7e54799e5e4b8278b5a785ef558ff7f8bd8f"),
        ],
        ["TEST-0177"],
        LinkSlots(),
        [],
        BothSurfaces(),
        FullSnapshots(),
        Findings("protocol.remediation.stable-fragment", "protocol.record.anchor-missing", "protocol.record.anchor-duplicate", "protocol.reference.fragment-missing", "protocol.reference.fragment-wrong"),
        ["protocol.evaluator.reference-ambiguity"]);

    private static RuleDeclaration Rule0005() => Rule(
        "RULE-0005",
        "e4512349b2fb23f6a367675f6a0b43bfe936c109d3109773d304affc5a1dd0b3",
        [Fragment("PROTOCOL.md", ProtocolBlob, "protocol.commit-permalink", 547, 553, 509, "203c70b6f2211f453b711c56d3a669a573cae728513b46d5706e1e8ec8d06231")],
        ["TEST-0178"],
        LinkSlots(),
        [],
        BothSurfaces(),
        FullSnapshots(),
        Findings("protocol.remediation.commit-permalink", "protocol.commit-reference.not-permalink", "protocol.commit-reference.wrong-repository", "protocol.commit-reference.wrong-object", "protocol.commit-reference.unresolved"),
        [
            "protocol.evaluator.reference-ambiguity",
            "protocol.evaluator.commit-intent-ambiguity",
        ]);

    private static RuleDeclaration Rule(
        string id,
        string digest,
        IReadOnlyList<NormativeFragmentDeclaration> fragments,
        IEnumerable<string> scenarios,
        IReadOnlyList<EvidenceSlotDeclaration> slots,
        IReadOnlyList<ExpectedSelectorDeclaration> selectors,
        SurfaceKind[] surfaces,
        SnapshotKind[] snapshots,
        IReadOnlyList<FindingDeclaration> findings,
        IEnumerable<string> failures) => RuleDeclaration.Create(
        RuleId.Parse(id),
        RuleRevision.Create(1),
        CatalogVersion.Create(1),
        ExactSha256Digest.Parse(digest),
        fragments,
        scenarios.Select(TestScenarioId.Parse),
        Resolve("protocol.evaluator." + id.ToLowerInvariant()),
        [],
        slots,
        selectors,
        [SubjectRole.ProtocolAuthoritySelfConsumer, SubjectRole.Consumer],
        SurfaceSet.Create(surfaces),
        snapshots,
        [ProtocolOperation.Conformance],
        findings,
        failures.Select(EvaluationFailureCode.Parse),
        "0.17.0",
        null,
        null,
        []);

    private static NormativeFragmentDeclaration Fragment(
        string path,
        string blob,
        string anchor,
        int start,
        int end,
        long length,
        string digest) => NormativeFragmentDeclaration.Create(
        path,
        blob,
        anchor,
        start,
        end,
        "protocol.normative-fragment.utf8-lines.v1",
        length,
        ExactSha256Digest.Parse(digest));

    private static ExpectedSelectorDeclaration Selector(
        string key,
        string slot,
        string schema,
        string finding) => ExpectedSelectorDeclaration.Create(
        key,
        slot,
        schema,
        Resolve(key),
        [QualifiedEvidenceReferenceKind.Derived],
        [FindingCode.Parse(finding)]);

    private static FindingDeclaration Finding(
        string code,
        string remediation,
        IReadOnlyList<QualifiedEvidenceReferenceKind> primary,
        IReadOnlyList<QualifiedEvidenceReferenceKind> related) =>
        FindingDeclaration.Create(
            FindingCode.Parse(code),
            FindingSeverity.Parse("protocol.finding.error"),
            RemediationKey.Parse(remediation),
            primary,
            related);

    private static IReadOnlyList<FindingDeclaration> Findings(
        string remediation,
        params string[] codes) => codes.Select(code => Finding(
            code,
            remediation,
            [QualifiedEvidenceReferenceKind.Derived],
            [QualifiedEvidenceReferenceKind.Root,
                QualifiedEvidenceReferenceKind.Derived])).ToArray();

    private static QualifiedEvidenceReferenceKind[] RelatedAll() =>
    [
        QualifiedEvidenceReferenceKind.ContextProof,
        QualifiedEvidenceReferenceKind.Root,
        QualifiedEvidenceReferenceKind.Derived,
    ];

    private static EvidenceSlotDeclaration[] LinkSlots() =>
    [RepositoryGovernedSlot(), ProviderGovernedSlot(), TargetSlot()];

    private static SurfaceKind[] BothSurfaces() =>
        [SurfaceKind.Repository, SurfaceKind.Provider];

    private static SurfaceKind[] RepositoryProfiles() =>
        [SurfaceKind.Repository];

    private static SnapshotKind[] RepositorySnapshots() =>
    [
        SnapshotKind.ExactCommit,
        SnapshotKind.Candidate,
        SnapshotKind.ProviderFullInventory,
        SnapshotKind.CapturedEvidence,
    ];

    private static SnapshotKind[] FullSnapshots() =>
    [
        SnapshotKind.ExactCommit,
        SnapshotKind.Candidate,
        SnapshotKind.ProviderEvent,
        SnapshotKind.ProviderFullInventory,
        SnapshotKind.CapturedEvidence,
    ];

    private static EvidenceSlotDeclaration RepositoryGovernedSlot() =>
        GovernedSlot(
            "repository",
            SurfaceKind.Repository,
            [SurfaceKind.Repository, SurfaceKind.Provider]);

    private static EvidenceSlotDeclaration ProviderGovernedSlot() =>
        GovernedSlot("provider", SurfaceKind.Provider, [SurfaceKind.Provider]);

    private static EvidenceSlotDeclaration GovernedSlot(
        string scope,
        SurfaceKind surface,
        SurfaceKind[] profiles) => EvidenceSlotDeclaration.Create(
        "protocol.slot." + scope + "-governed-text",
        EvidenceRequirement.Create(
            "protocol.requirement." + scope + "-governed-text",
            surface,
            "protocol.evidence.governed-text-set",
            "protocol.completeness.all-governed-bodies",
            "protocol.governed-text",
            "1",
            [
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceConsistencyClass.ObjectVersionBound,
                EvidenceConsistencyClass.BoundedNonAtomicObservation,
            ]),
        SurfaceSet.Create(profiles),
        "protocol.material.governed-text",
        "protocol.target." + scope + "-governed-body-set",
        [RecordCapability(), GovernedCapability()]);

    private static EvidenceSlotDeclaration TargetSlot() =>
        EvidenceSlotDeclaration.Create(
            "protocol.slot.repository-target-resolution",
            EvidenceRequirement.Create(
                "protocol.requirement.repository-target-resolution",
                SurfaceKind.Repository,
                "protocol.evidence.repository-target-resolution-set",
                "protocol.completeness.all-projected-target-resolutions",
                "protocol.repository-target-resolution",
                "1",
                [
                    EvidenceConsistencyClass.ExactSnapshot,
                    EvidenceConsistencyClass.ObjectVersionBound,
                ]),
            SurfaceSet.Create([SurfaceKind.Repository, SurfaceKind.Provider]),
            "protocol.material.repository-target-resolution",
            "protocol.target.repository-target-resolution-set",
            [TargetCapability()]);

    private static EvidenceSlotDeclaration TreeSlot() =>
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
                    EvidenceConsistencyClass.ExactSnapshot,
                    EvidenceConsistencyClass.ObjectVersionBound,
                    EvidenceConsistencyClass.BoundedNonAtomicObservation,
                ]),
            SurfaceSet.Create(RepositoryProfiles()),
            "protocol.material.repository-tree",
            "protocol.target.repository-snapshot",
            [TreeCapability()]);

    private static ModelContractIdentity SourceModel() =>
        Model("protocol.model.source-text", "protocol.type.model.source-text");

    private static ModelContractIdentity MarkdownModel() =>
        Model(
            "protocol.model.markdown-document",
            "protocol.type.model.markdown-document");

    private static ModelContractIdentity TargetMarkdownModel() =>
        Model(
            "protocol.model.repository-target-markdown-document-set",
            "protocol.type.model.repository-target-markdown-document-set");

    private static ModelContractIdentity TargetResolutionModel() =>
        Model(
            "protocol.model.repository-target-resolution",
            "protocol.type.model.repository-target-resolution");

    private static ModelContractIdentity TreeModel() =>
        Model("protocol.model.repository-tree", "protocol.type.model.repository-tree");

    private static ModelContractIdentity Model(string key, string type) =>
        ModelContractIdentity.Create(key, "1", Resolve(type));

    private static CapabilityContractIdentity GovernedCapability() =>
        Capability(
            "protocol.capability.governed-reference-index",
            "protocol.type.capability.governed-reference-index");

    private static CapabilityContractIdentity RecordCapability() =>
        Capability(
            "protocol.capability.protocol-record-index",
            "protocol.type.capability.protocol-record-index");

    private static CapabilityContractIdentity TargetCapability() =>
        Capability(
            "protocol.capability.repository-target-resolution-index",
            "protocol.type.capability.repository-target-resolution-index");

    private static CapabilityContractIdentity TreeCapability() =>
        Capability(
            "protocol.capability.repository-tree",
            "protocol.type.capability.repository-tree");

    private static CapabilityContractIdentity Capability(
        string key,
        string type) => CapabilityContractIdentity.Create(
        key,
        "1",
        Resolve(type));

    private static SemanticResourceBudget Budget(
        long bytes,
        int depth,
        long nodes,
        long complexity) => SemanticResourceBudget.Create(
        bytes,
        depth,
        nodes,
        complexity);

    private static IEnumerable<string> Codes(params string[] codes) => codes;

    private static IEnumerable<EvaluationFailureCode> Failures(
        params string[] codes) => codes.Select(EvaluationFailureCode.Parse);

    private static ComponentTypeIdentity Resolve(string key)
    {
        var component = Components.Single(candidate => candidate.Key == key);
        return ComponentTypeIdentity.Create(
            key,
            "1",
            component.Assembly,
            component.Type);
    }
}

internal sealed record InitialPolicyDeclarationSet(
    CatalogSliceDeclaration Catalog,
    ReleaseSchemaRegistry SchemaRegistry);
