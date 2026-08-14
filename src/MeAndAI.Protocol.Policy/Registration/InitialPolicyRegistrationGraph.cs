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
        var treeModel = ModelTypeToken<RepositoryTreeModel>.Create(
            Schema(registry, "protocol.repository-tree").OutputModel);
        var markdownModel = ModelTypeToken<MarkdownDocumentModel>.Create(
            Parser(registry, "protocol.parser.markdown").OutputModel);
        var targetModel = ModelTypeToken<RepositoryTargetResolutionModel>.Create(
            Schema(registry, "protocol.repository-target-resolution").OutputModel);
        var targetMarkdownModel =
            ModelTypeToken<RepositoryTargetMarkdownDocumentSetModel>.Create(
                Parser(registry, "protocol.parser.repository-target-markdown")
                    .OutputModel);

        return PolicyQualificationSliceExport.Create(
            "protocol.policy.initial-rule-qualification",
            "1",
            catalog,
            registry,
            CreateCodecs(registry, treeModel, targetModel),
            CreateParsers(registry, markdownModel, targetModel, targetMarkdownModel),
            CreateIndexes(
                registry,
                treeModel,
                markdownModel,
                targetModel,
                targetMarkdownModel),
            CreateProjectors(registry),
            CreateSelectors(catalog),
            CreateEvaluators(catalog));
    }

    private static ICodecRegistration[] CreateCodecs(
        ReleaseSchemaRegistry registry,
        ModelTypeToken<RepositoryTreeModel> treeModel,
        ModelTypeToken<RepositoryTargetResolutionModel> targetModel)
    {
        var governed = Schema(registry, "protocol.governed-text");
        var target = Schema(registry, "protocol.repository-target-resolution");
        var tree = Schema(registry, "protocol.repository-tree");
        var governedModel = ModelTypeToken<SourceTextModel>.Create(
            governed.OutputModel);
        return
        [
            CodecRegistration<SourceTextModel>.Create(
                governed,
                governedModel,
                new GovernedTextCodec(governed, governedModel)),
            CodecRegistration<RepositoryTargetResolutionModel>.Create(
                target,
                targetModel,
                new RepositoryTargetResolutionCodec(target, targetModel)),
            CodecRegistration<RepositoryTreeModel>.Create(
                tree,
                treeModel,
                new RepositoryTreeCodec(tree, treeModel)),
        ];
    }

    private static IParserRegistration[] CreateParsers(
        ReleaseSchemaRegistry registry,
        ModelTypeToken<MarkdownDocumentModel> markdownModel,
        ModelTypeToken<RepositoryTargetResolutionModel> targetInput,
        ModelTypeToken<RepositoryTargetMarkdownDocumentSetModel> targetOutput)
    {
        var markdown = Parser(registry, "protocol.parser.markdown");
        var target = Parser(
            registry,
            "protocol.parser.repository-target-markdown");
        var sourceInput = ModelTypeToken<SourceTextModel>.Create(
            Schema(registry, "protocol.governed-text").OutputModel);
        return
        [
            ParserRegistration<SourceTextInput, MarkdownDocumentModel>.Create(
                markdown,
                new PolicyInputBinder<SourceTextInput>(
                    markdown.Inputs,
                    reader => new SourceTextInput(
                        reader.RequireModel(sourceInput))),
                markdownModel,
                new MarkdownDocumentParser()),
            ParserRegistration<RepositoryTargetInput,
                RepositoryTargetMarkdownDocumentSetModel>.Create(
                    target,
                    new PolicyInputBinder<RepositoryTargetInput>(
                        target.Inputs,
                        reader => new RepositoryTargetInput(
                            reader.RequireModel(targetInput))),
                    targetOutput,
                    new RepositoryTargetMarkdownDocumentParser()),
        ];
    }

    private static IIndexRegistration[] CreateIndexes(
        ReleaseSchemaRegistry registry,
        ModelTypeToken<RepositoryTreeModel> treeModel,
        ModelTypeToken<MarkdownDocumentModel> markdownModel,
        ModelTypeToken<RepositoryTargetResolutionModel> targetModel,
        ModelTypeToken<RepositoryTargetMarkdownDocumentSetModel> targetMarkdownModel)
    {
        var governed = Index(registry, "protocol.index.governed-reference");
        var governedCapability = CapabilityTypeToken<IGovernedReferenceIndex>.Create(
            governed.OutputCapability);
        var targets = Index(registry, "protocol.index.repository-target-resolution");
        return
        [
            IndexRegistration<PolicyIndexInput, IGovernedReferenceIndex>.Create(
                governed,
                new PolicyInputBinder<PolicyIndexInput>(
                    governed.Inputs,
                    reader => new PolicyIndexInput(reader)),
                governedCapability,
                new GovernedReferenceIndex(markdownModel)),
            CreateProtocolRecordIndex(registry, markdownModel),
            IndexRegistration<PolicyIndexInput,
                IRepositoryTargetResolutionIndex>.Create(
                    targets,
                    new PolicyInputBinder<PolicyIndexInput>(
                        targets.Inputs,
                        reader => new PolicyIndexInput(reader)),
                    CapabilityTypeToken<IRepositoryTargetResolutionIndex>.Create(
                        targets.OutputCapability),
                    new RepositoryTargetResolutionIndex(
                        governedCapability,
                        targetModel,
                        targetMarkdownModel)),
            CreateRepositoryTreeIndex(registry, treeModel),
        ];
    }

    private static IIndexRegistration CreateProtocolRecordIndex(
        ReleaseSchemaRegistry registry,
        ModelTypeToken<MarkdownDocumentModel> inputModel)
    {
        var declaration = Index(registry, "protocol.index.protocol-record");
        return IndexRegistration<PolicyIndexInput, IProtocolRecordIndex>.Create(
            declaration,
            new PolicyInputBinder<PolicyIndexInput>(
                declaration.Inputs,
                reader => new PolicyIndexInput(reader)),
            CapabilityTypeToken<IProtocolRecordIndex>.Create(
                declaration.OutputCapability),
            new ProtocolRecordIndex(inputModel));
    }

    private static IIndexRegistration CreateRepositoryTreeIndex(
        ReleaseSchemaRegistry registry,
        ModelTypeToken<RepositoryTreeModel> inputModel)
    {
        var declaration = Index(registry, "protocol.index.repository-tree");
        return IndexRegistration<PolicyIndexInput, IRepositoryTree>.Create(
            declaration,
            new PolicyInputBinder<PolicyIndexInput>(
                declaration.Inputs,
                reader => new PolicyIndexInput(reader)),
            CapabilityTypeToken<IRepositoryTree>.Create(
                declaration.OutputCapability),
            new RepositoryTreeIndex(inputModel));
    }

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
            new PolicyInputBinder<PolicyIndexInput>(
                declaration.Inputs,
                reader => new PolicyIndexInput(reader)),
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
    private readonly Func<TypedInputReader, TInput> _bind;

    internal PolicyInputBinder(
        IEnumerable<ComponentInputDeclaration> inputs,
        Func<TypedInputReader, TInput> bind)
    {
        Inputs = Array.AsReadOnly(
            (inputs ?? throw new ArgumentNullException(nameof(inputs))).ToArray());
        _bind = bind ?? throw new ArgumentNullException(nameof(bind));
    }

    public IReadOnlyList<ComponentInputDeclaration> Inputs { get; }

    public TInput Bind(TypedInputReader reader)
    {
        ArgumentNullException.ThrowIfNull(reader);
        return _bind(reader);
    }
}
