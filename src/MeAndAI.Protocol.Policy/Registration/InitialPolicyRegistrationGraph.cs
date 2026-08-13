using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Codecs;
using MeAndAI.Protocol.Policy.Declarations;
using MeAndAI.Protocol.Policy.Demands;
using MeAndAI.Protocol.Policy.Indexes;
using MeAndAI.Protocol.Policy.Models;
using MeAndAI.Protocol.Policy.Parsers;
using MeAndAI.Protocol.Policy.Rules;
using MeAndAI.Protocol.Policy.Selectors;

namespace MeAndAI.Protocol.Policy.Registration;

internal static class InitialPolicyRegistrationGraph
{
    internal static PolicyQualificationSliceExport Create(
        InitialPolicyDeclarationSet declarations)
    {
        ArgumentNullException.ThrowIfNull(declarations);
        var registry = declarations.SchemaRegistry;
        var catalog = declarations.Catalog;

        return PolicyQualificationSliceExport.Create(
            "protocol.policy.initial-rule-qualification",
            "1",
            catalog,
            registry,
            CreateCodecs(registry),
            CreateParsers(registry),
            CreateIndexes(registry),
            CreateProjectors(registry),
            CreateSelectors(catalog),
            CreateEvaluators(catalog));
    }

    private static ICodecRegistration[] CreateCodecs(
        ReleaseSchemaRegistry registry)
    {
        var governed = Schema(registry, "protocol.governed-text");
        var target = Schema(registry, "protocol.repository-target-resolution");
        var tree = Schema(registry, "protocol.repository-tree");
        return
        [
            CodecRegistration<SourceTextModel>.Create(
                governed,
                ModelTypeToken<SourceTextModel>.Create(governed.OutputModel),
                new GovernedTextCodec()),
            CodecRegistration<RepositoryTargetResolutionModel>.Create(
                target,
                ModelTypeToken<RepositoryTargetResolutionModel>.Create(
                    target.OutputModel),
                new RepositoryTargetResolutionCodec()),
            CodecRegistration<RepositoryTreeModel>.Create(
                tree,
                ModelTypeToken<RepositoryTreeModel>.Create(tree.OutputModel),
                new RepositoryTreeCodec()),
        ];
    }

    private static IParserRegistration[] CreateParsers(
        ReleaseSchemaRegistry registry)
    {
        var markdown = Parser(registry, "protocol.parser.markdown");
        var target = Parser(
            registry,
            "protocol.parser.repository-target-markdown");
        return
        [
            ParserRegistration<SourceTextInput, MarkdownDocumentModel>.Create(
                markdown,
                new PolicyInputBinder<SourceTextInput>(markdown.Inputs),
                ModelTypeToken<MarkdownDocumentModel>.Create(
                    markdown.OutputModel),
                new MarkdownDocumentParser()),
            ParserRegistration<RepositoryTargetInput,
                RepositoryTargetMarkdownDocumentSetModel>.Create(
                    target,
                    new PolicyInputBinder<RepositoryTargetInput>(target.Inputs),
                    ModelTypeToken<RepositoryTargetMarkdownDocumentSetModel>
                        .Create(target.OutputModel),
                    new RepositoryTargetMarkdownDocumentParser()),
        ];
    }

    private static IIndexRegistration[] CreateIndexes(
        ReleaseSchemaRegistry registry) =>
    [
        CreateIndex<IGovernedReferenceIndex, GovernedReferenceIndex>(
            registry,
            "protocol.index.governed-reference",
            new GovernedReferenceIndex()),
        CreateIndex<IProtocolRecordIndex, ProtocolRecordIndex>(
            registry,
            "protocol.index.protocol-record",
            new ProtocolRecordIndex()),
        CreateIndex<IRepositoryTargetResolutionIndex,
            RepositoryTargetResolutionIndex>(
                registry,
                "protocol.index.repository-target-resolution",
                new RepositoryTargetResolutionIndex()),
        CreateIndex<IRepositoryTree, RepositoryTreeIndex>(
            registry,
            "protocol.index.repository-tree",
            new RepositoryTreeIndex()),
    ];

    private static IIndexRegistration CreateIndex<TCapability, TIndexer>(
        ReleaseSchemaRegistry registry,
        string key,
        TIndexer indexer)
        where TCapability : class, IEvidenceCapability
        where TIndexer : class, IContextIndexer<PolicyIndexInput, TCapability>
    {
        var declaration = Index(registry, key);
        return IndexRegistration<PolicyIndexInput, TCapability>.Create(
            declaration,
            new PolicyInputBinder<PolicyIndexInput>(declaration.Inputs),
            CapabilityTypeToken<TCapability>.Create(
                declaration.OutputCapability),
            indexer);
    }

    private static IDemandProjectorRegistration[] CreateProjectors(
        ReleaseSchemaRegistry registry)
    {
        var declaration = registry.DemandProjectors.Single();
        return
        [
            DemandProjectorRegistration<IGovernedReferenceIndex>.Create(
                declaration,
                CapabilityTypeToken<IGovernedReferenceIndex>.Create(
                    declaration.InputCapability),
                new RepositoryTargetResolutionDemandProjector()),
        ];
    }

    private static ISelectorRegistration[] CreateSelectors(
        CatalogSliceDeclaration catalog)
    {
        var declarations = catalog.Rules
            .SelectMany(rule => rule.ExpectedSelectors)
            .DistinctBy(item => item.SelectorKey, StringComparer.Ordinal)
            .OrderBy(item => item.SelectorKey, StringComparer.Ordinal)
            .ToArray();
        return
        [
            Selector<DecisionRecordSelectorResolver>(
                declarations,
                "protocol.selector.decision-record",
                new DecisionRecordSelectorResolver()),
            Selector<FeatureReadmeSelectorResolver>(
                declarations,
                "protocol.selector.feature-readme",
                new FeatureReadmeSelectorResolver()),
            Selector<FeatureTestCasesSelectorResolver>(
                declarations,
                "protocol.selector.feature-test-cases",
                new FeatureTestCasesSelectorResolver()),
        ];
    }

    private static ISelectorRegistration Selector<TResolver>(
        IReadOnlyList<ExpectedSelectorDeclaration> declarations,
        string key,
        TResolver resolver)
        where TResolver : class, IExpectedSelectorResolver
    {
        var declaration = declarations.Single(item =>
            item.SelectorKey == key);
        return SelectorRegistration<TResolver>.Create(
            declaration.Resolver,
            declaration.SelectorSchemaKey,
            resolver);
    }

    private static RuleEvaluatorRegistration[] CreateEvaluators(
        CatalogSliceDeclaration catalog) =>
    [
        RuleEvaluatorRegistration.Create(
            catalog.Rules[0],
            new FeaturePacketRuleEvaluator()),
        RuleEvaluatorRegistration.Create(
            catalog.Rules[1],
            new DecisionRecordRuleEvaluator()),
        RuleEvaluatorRegistration.Create(
            catalog.Rules[2],
            new ClickableExactTargetRuleEvaluator()),
        RuleEvaluatorRegistration.Create(
            catalog.Rules[3],
            new StableFragmentRuleEvaluator()),
        RuleEvaluatorRegistration.Create(
            catalog.Rules[4],
            new CommitPermalinkRuleEvaluator()),
    ];

    private static PayloadSchemaDeclaration Schema(
        ReleaseSchemaRegistry registry,
        string key) => registry.PayloadSchemas.Single(item =>
        item.SchemaKey == key);

    private static SemanticModelParserDeclaration Parser(
        ReleaseSchemaRegistry registry,
        string key) => registry.Parsers.Single(item => item.ParserKey == key);

    private static ContextIndexDeclaration Index(
        ReleaseSchemaRegistry registry,
        string key) => registry.Indexes.Single(item => item.IndexKey == key);
}

internal sealed class PolicyInputBinder<TInput> : IComponentInputBinder<TInput>
    where TInput : class, IComponentInput
{
    internal PolicyInputBinder(IEnumerable<ComponentInputDeclaration> inputs) =>
        Inputs = Array.AsReadOnly(
            (inputs ?? throw new ArgumentNullException(nameof(inputs))).ToArray());

    public IReadOnlyList<ComponentInputDeclaration> Inputs { get; }
}
