using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCProducerPipelineTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0003";

    private static readonly string[] ExpectedOrder =
    [
        "Schema|protocol.governed-text|1",
        "Schema|protocol.repository-tree|1",
        "Index|protocol.index.repository-tree|1",
        "Parser|protocol.parser.markdown|1",
        "Index|protocol.index.protocol-record|1",
        "Index|protocol.index.governed-reference|1",
        "Projector|protocol.projector.repository-target-resolution-demand|1",
        "Schema|protocol.repository-target-resolution|1",
        "Parser|protocol.parser.repository-target-markdown|1",
        "Index|protocol.index.repository-target-resolution|1"
    ];

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Activates_and_orders_exact_six_family_producer_graph()
    {
        var fixture = ContractSliceCActivationTests.CreateFixture();
        var completeKernel = ConformanceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            new ContractSliceCActivationProof(fixture.Manifest, fixture.Export),
            predecessor: null);
        var slice = CatalogSliceDeclaration.Create(
            "protocol.catalog-slice.synthetic-producer-pipeline",
            "1",
            fixture.Export.Catalog.ProtocolVersion,
            fixture.Export.Catalog.CatalogVersion,
            fixture.Export.Catalog.Rules);
        var sliceManifest = ContractSliceCActivationTests.CreateSyntheticManifest(
            CatalogAuthorityKind.QualificationSlice,
            fixture.Manifest.SourceCommit,
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.SchemaRegistry,
            fixture.Manifest.ActivationProofContract,
            fixture.Manifest.ArtifactFiles,
            fixture.Manifest.Components,
            slice,
            completeCatalog: null);
        var sliceExport = PolicyQualificationSliceExport.Create(
            "protocol.policy-pack.synthetic-producer-pipeline",
            "1",
            slice,
            sliceManifest.SchemaRegistry,
            fixture.Codecs,
            fixture.Parsers,
            fixture.Indexes,
            fixture.Projectors,
            fixture.Selectors,
            fixture.Evaluators);
        var sliceKernel = CatalogSliceKernel.Activate(
            sliceManifest,
            sliceExport,
            new ContractSliceCQualificationProof(sliceManifest, sliceExport));

        CatalogSliceProducerGraph? completeGraph = completeKernel.ProducerGraph;
        if (completeGraph is null)
        {
            Assert.Fail(Marker);
        }

        AssertGraph(completeGraph);
        AssertGraph(sliceKernel.ProducerGraph);
        AssertSameRegistrations(fixture, completeGraph);
        AssertSameRegistrations(fixture, sliceKernel.ProducerGraph);
        AssertConcreteOperations(completeGraph);
    }

    private static void AssertGraph(CatalogSliceProducerGraph graph)
    {
        Assert.Equal(ExpectedOrder, graph.Nodes.Select(node => node.Identity));
        Assert.Equal(
            [
                "",
                "",
                ExpectedOrder[1],
                ExpectedOrder[0],
                ExpectedOrder[3],
                $"{ExpectedOrder[3]},{ExpectedOrder[4]}",
                ExpectedOrder[5],
                ExpectedOrder[6],
                ExpectedOrder[7],
                $"{ExpectedOrder[5]},{ExpectedOrder[7]},{ExpectedOrder[8]}"
            ],
            graph.Nodes.Select(node => string.Join(',', node.Dependencies)));
        Assert.Equal(2, graph.Nodes.Count(node => node.Dependencies.Count == 0));
        Assert.Equal(3, graph.CodecRegistrations.Count);
        Assert.Equal(2, graph.ParserRegistrations.Count);
        Assert.Equal(4, graph.IndexRegistrations.Count);
        Assert.Single(graph.DemandProjectorRegistrations);
        Assert.Equal(3, graph.SelectorRegistrations.Count);
        Assert.Equal(5, graph.EvaluatorRegistrations.Count);
    }

    private static void AssertSameRegistrations(
        ContractSliceCActivationTests.CFixture fixture,
        CatalogSliceProducerGraph graph)
    {
        Assert.All(fixture.Codecs.Zip(graph.CodecRegistrations), pair =>
            Assert.Same(pair.First, pair.Second));
        Assert.All(fixture.Parsers.Zip(graph.ParserRegistrations), pair =>
            Assert.Same(pair.First, pair.Second));
        Assert.All(fixture.Indexes.Zip(graph.IndexRegistrations), pair =>
            Assert.Same(pair.First, pair.Second));
        Assert.All(fixture.Projectors.Zip(graph.DemandProjectorRegistrations), pair =>
            Assert.Same(pair.First, pair.Second));
        Assert.All(fixture.Selectors.Zip(graph.SelectorRegistrations), pair =>
            Assert.Same(pair.First, pair.Second));
        Assert.All(fixture.Evaluators.Zip(graph.EvaluatorRegistrations), pair =>
            Assert.Same(pair.First, pair.Second));
    }

    private static void AssertConcreteOperations(CatalogSliceProducerGraph graph)
    {
        Assert.All(graph.CodecRegistrations, registration =>
            Assert.True(registration.Accept(OperationProbe.Codec)));
        Assert.All(graph.ParserRegistrations, registration =>
            Assert.True(registration.Accept(OperationProbe.Parser)));
        Assert.All(graph.IndexRegistrations, registration =>
            Assert.True(registration.Accept(OperationProbe.Index)));
        Assert.All(graph.DemandProjectorRegistrations, registration =>
            Assert.True(registration.Accept(OperationProbe.Projector)));
        Assert.All(graph.SelectorRegistrations, registration =>
            Assert.True(registration.Accept(OperationProbe.Selector)));
        Assert.All(graph.EvaluatorRegistrations, registration =>
        {
            Assert.NotNull(registration.Evaluator.EvaluateApplicability(null!, default));
            Assert.NotNull(registration.Evaluator.Evaluate(null!, default));
        });
    }

    private sealed class OperationProbe :
        ICodecRegistrationVisitor<bool>,
        IParserRegistrationVisitor<bool>,
        IIndexRegistrationVisitor<bool>,
        IDemandProjectorRegistrationVisitor<bool>,
        ISelectorRegistrationVisitor<bool>
    {
        internal static readonly OperationProbe Codec = new();
        internal static readonly OperationProbe Parser = new();
        internal static readonly OperationProbe Index = new();
        internal static readonly OperationProbe Projector = new();
        internal static readonly OperationProbe Selector = new();

        public bool Visit<TModel>(CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            Assert.Throws<ArgumentNullException>(() =>
                registration.Codec.Write(null!, default));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Codec.Qualify(null!, default));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Codec.MeasureLocal(null!, null!, default));
            return true;
        }

        public bool Visit<TInput, TOutput>(ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel
        {
            Assert.Throws<ArgumentNullException>(() => registration.Binder.Bind(null!));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Parser.Parse(null!, default));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Parser.MeasureLocal(null!, null!, default));
            return true;
        }

        public bool Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            Assert.Throws<ArgumentNullException>(() => registration.Binder.Bind(null!));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Indexer.Build(null!, default));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Indexer.MeasureLocal(null!, null!, default));
            return true;
        }

        public bool Visit<TCapability>(DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability
        {
            Assert.Throws<ArgumentNullException>(() =>
                registration.Projector.Project(null!, default));
            Assert.Throws<ArgumentNullException>(() =>
                registration.Projector.MeasureLocal(null!, null!, default));
            return true;
        }

        public bool Visit<TResolver>(SelectorRegistration<TResolver> registration)
            where TResolver : class, IExpectedSelectorResolver
        {
            Assert.Throws<ArgumentNullException>(() => registration.Resolver.Resolve(null!));
            return true;
        }
    }
}

internal static class ProducerOperationStub
{
    internal static void Require(object? value) =>
        ArgumentNullException.ThrowIfNull(value, "input");

    internal static CanonicalPayloadWriteIntent RejectedWrite(object? input)
    {
        Require(input);
        return CanonicalPayloadWriteIntent.Rejected([]);
    }

    internal static CodecQualificationIntent<TModel> RejectedCodec<TModel>(object? input)
        where TModel : class, IProtocolSemanticModel
    {
        Require(input);
        return CodecQualificationIntent<TModel>.Rejected([]);
    }

    internal static SemanticModelIntent<TModel> FailedModel<TModel>(object? input)
        where TModel : class, IProtocolSemanticModel
    {
        Require(input);
        return SemanticModelIntent<TModel>.Failed(Failure());
    }

    internal static CapabilityIntent<TCapability> FailedCapability<TCapability>(object? input)
        where TCapability : class, IEvidenceCapability
    {
        Require(input);
        return CapabilityIntent<TCapability>.Failed(Failure());
    }

    internal static DemandProjectionIntent EmptyProjection(object? input)
    {
        Require(input);
        return DemandProjectionIntent.Projected(
            DemandProjectionProduct.Create([], Zero()));
    }

    internal static SelectorIntent InvalidSelector(object? input)
    {
        Require(input);
        return SelectorIntent.Invalid(CatalogIntegrityCode.IntentInvalid);
    }

    internal static SemanticResourceLocalUsage Meter(object? input, object? value)
    {
        Require(input);
        ArgumentNullException.ThrowIfNull(value);
        return Zero();
    }

    private static SemanticFailureIntent Failure() =>
        SemanticFailureIntent.Create(
            EvaluationFailureCode.Parse("protocol.failure.producer-not-active"),
            QualifiedEvidenceHandle.Create(),
            []);

    private static SemanticResourceLocalUsage Zero() =>
        SemanticResourceLocalUsage.Create(0, 0, 0, 0);
}

internal sealed partial class GovernedTextCodecMirror
{
    public CanonicalPayloadWriteIntent Write(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken) => ProducerOperationStub.RejectedWrite(input);

    CodecQualificationIntent<GovernedTextModelMirror>
        ICanonicalPayloadCodec<GovernedTextModelMirror>.Qualify(
            CodecQualificationInput input,
            CancellationToken cancellationToken) =>
            ProducerOperationStub.RejectedCodec<GovernedTextModelMirror>(input);

    CodecQualificationIntent<SourceTextModelMirror>
        ICanonicalPayloadCodec<SourceTextModelMirror>.Qualify(
            CodecQualificationInput input,
            CancellationToken cancellationToken) =>
            ProducerOperationStub.RejectedCodec<SourceTextModelMirror>(input);

    public SemanticResourceLocalUsage MeasureLocal(
        CodecQualificationInput input,
        GovernedTextModelMirror value,
        CancellationToken cancellationToken) => ProducerOperationStub.Meter(input, value);

    public SemanticResourceLocalUsage MeasureLocal(
        CodecQualificationInput input,
        SourceTextModelMirror value,
        CancellationToken cancellationToken) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class RepositoryTargetCodecMirror
{
    public CanonicalPayloadWriteIntent Write(CanonicalPayloadWriteInput input, CancellationToken token) =>
        ProducerOperationStub.RejectedWrite(input);
    public CodecQualificationIntent<RepositoryTargetModelMirror> Qualify(
        CodecQualificationInput input, CancellationToken token) =>
        ProducerOperationStub.RejectedCodec<RepositoryTargetModelMirror>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        CodecQualificationInput input, RepositoryTargetModelMirror value, CancellationToken token) =>
        ProducerOperationStub.Meter(input, value);
}

internal sealed partial class RepositoryTreeCodecMirror
{
    public CanonicalPayloadWriteIntent Write(CanonicalPayloadWriteInput input, CancellationToken token) =>
        ProducerOperationStub.RejectedWrite(input);
    public CodecQualificationIntent<RepositoryTreeModelMirror> Qualify(
        CodecQualificationInput input, CancellationToken token) =>
        ProducerOperationStub.RejectedCodec<RepositoryTreeModelMirror>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        CodecQualificationInput input, RepositoryTreeModelMirror value, CancellationToken token) =>
        ProducerOperationStub.Meter(input, value);
}

internal sealed partial class MarkdownParserMirror
{
    public SemanticModelIntent<MarkdownDocumentModelMirror> Parse(
        SemanticModelInput<SourceTextInputMirror> input, CancellationToken token) =>
        ProducerOperationStub.FailedModel<MarkdownDocumentModelMirror>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        SemanticModelInput<SourceTextInputMirror> input,
        MarkdownDocumentModelMirror value,
        CancellationToken token) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class RepositoryTargetMarkdownParserMirror
{
    public SemanticModelIntent<RepositoryTargetMarkdownDocumentSetModelMirror> Parse(
        SemanticModelInput<RepositoryTargetInputMirror> input, CancellationToken token) =>
        ProducerOperationStub.FailedModel<RepositoryTargetMarkdownDocumentSetModelMirror>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        SemanticModelInput<RepositoryTargetInputMirror> input,
        RepositoryTargetMarkdownDocumentSetModelMirror value,
        CancellationToken token) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class GovernedReferenceIndexMirror
{
    public CapabilityIntent<IGovernedReferenceIndex> Build(
        ContextIndexInput<IndexInputMirror> input, CancellationToken token) =>
        ProducerOperationStub.FailedCapability<IGovernedReferenceIndex>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<IndexInputMirror> input,
        IGovernedReferenceIndex value,
        CancellationToken token) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class ProtocolRecordIndexMirror
{
    public CapabilityIntent<IProtocolRecordIndex> Build(
        ContextIndexInput<IndexInputMirror> input, CancellationToken token) =>
        ProducerOperationStub.FailedCapability<IProtocolRecordIndex>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<IndexInputMirror> input,
        IProtocolRecordIndex value,
        CancellationToken token) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class RepositoryTargetIndexMirror
{
    private bool _failNext;

    internal int BuildCalls { get; private set; }

    internal void FailNext() => _failNext = true;

    public CapabilityIntent<IRepositoryTargetResolutionIndex> Build(
        ContextIndexInput<IndexInputMirror> input, CancellationToken token)
    {
        ArgumentNullException.ThrowIfNull(input);
        token.ThrowIfCancellationRequested();
        BuildCalls++;
        if (_failNext)
        {
            _failNext = false;
            throw new InvalidOperationException("Synthetic repository-target index failure.");
        }

        return CapabilityIntent<IRepositoryTargetResolutionIndex>.Produced(
            CapabilityProduct<IRepositoryTargetResolutionIndex>.Create(
                new RepositoryTargetResolutionIndexMirror(),
                [],
                SemanticResourceLocalUsage.Create(0, 0, 0, 0)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<IndexInputMirror> input,
        IRepositoryTargetResolutionIndex value,
        CancellationToken token)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        token.ThrowIfCancellationRequested();
        return SemanticResourceLocalUsage.Create(0, 0, 0, 0);
    }
}

internal sealed class RepositoryTargetResolutionIndexMirror :
    IRepositoryTargetResolutionIndex
{
    public IReadOnlyList<RepositoryTargetResolutionView> Targets { get; } =
        Array.Empty<RepositoryTargetResolutionView>();
}

internal sealed partial class RepositoryTreeIndexMirror
{
    public CapabilityIntent<IRepositoryTree> Build(
        ContextIndexInput<IndexInputMirror> input, CancellationToken token) =>
        ProducerOperationStub.FailedCapability<IRepositoryTree>(input);
    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<IndexInputMirror> input,
        IRepositoryTree value,
        CancellationToken token) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class RepositoryTargetProjectorMirror
{
    private IReadOnlyList<RepositoryTargetResolutionDemandCandidate> _candidates =
        Array.Empty<RepositoryTargetResolutionDemandCandidate>();

    internal void Configure(
        IEnumerable<RepositoryTargetResolutionDemandCandidate> candidates)
    {
        ArgumentNullException.ThrowIfNull(candidates);
        _candidates = Array.AsReadOnly(candidates.ToArray());
    }

    public DemandProjectionIntent Project(
        DemandProjectionInput<IGovernedReferenceIndex> input, CancellationToken token)
    {
        ArgumentNullException.ThrowIfNull(input);
        token.ThrowIfCancellationRequested();
        return DemandProjectionIntent.Projected(
            DemandProjectionProduct.Create(
                _candidates,
                SemanticResourceLocalUsage.Create(0, 0, 0, 0)));
    }
    public SemanticResourceLocalUsage MeasureLocal(
        DemandProjectionInput<IGovernedReferenceIndex> input,
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate> value,
        CancellationToken token) => ProducerOperationStub.Meter(input, value);
}

internal sealed partial class DecisionRecordSelectorMirror
{
    public SelectorIntent Resolve(ExpectedSelectorInput input) =>
        ProducerOperationStub.InvalidSelector(input);
}

internal sealed partial class FeatureReadmeSelectorMirror
{
    public SelectorIntent Resolve(ExpectedSelectorInput input) =>
        ProducerOperationStub.InvalidSelector(input);
}

internal sealed partial class FeatureTestCasesSelectorMirror
{
    public SelectorIntent Resolve(ExpectedSelectorInput input) =>
        ProducerOperationStub.InvalidSelector(input);
}
