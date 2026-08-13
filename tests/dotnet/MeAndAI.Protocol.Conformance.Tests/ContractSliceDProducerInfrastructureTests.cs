using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceDProducerInfrastructureTests
{
    private const string Marker = "TEST-0210-D-BEHAVIOR-RED-0002";

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Activates_exact_real_codec_parser_index_projector_selector_evaluator_graph()
    {
        ContractSliceDProducerInfrastructureEvidence? evidence =
            ContractSliceDProducerInfrastructureFixture.Activate(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal((3, 2, 4, 1, 3, 5),
            (evidence.Codecs, evidence.Parsers, evidence.Indexes,
             evidence.Projectors, evidence.Selectors, evidence.Evaluators));
        Assert.True(evidence.CancellationClosed);
        Assert.True(evidence.ResourceMetersClosed);
    }
}

internal sealed record ContractSliceDProducerInfrastructureEvidence(
    int Codecs, int Parsers, int Indexes, int Projectors, int Selectors,
    int Evaluators, bool CancellationClosed, bool ResourceMetersClosed);

internal static class ContractSliceDProducerInfrastructureFixture
{
    private const string Identity =
        "0123456789abcdef0123456789abcdef01234567";
    private static readonly ExactSha256Digest Digest =
        ExactSha256Digest.Parse(new string('0', 64));

    internal static ContractSliceDProducerInfrastructureEvidence? Activate(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);
        Assert.Equal(
            ["protocol.governed-text", "protocol.repository-target-resolution",
             "protocol.repository-tree"],
            export.CodecRegistrations.Select(item => item.Declaration.SchemaKey));
        Assert.Equal(
            ["protocol.parser.markdown", "protocol.parser.repository-target-markdown"],
            export.ParserRegistrations.Select(item => item.Declaration.ParserKey));
        Assert.Equal(
            ["protocol.index.governed-reference", "protocol.index.protocol-record",
             "protocol.index.repository-target-resolution", "protocol.index.repository-tree"],
            export.IndexRegistrations.Select(item => item.Declaration.IndexKey));

        var probe = new ProducerProbe(export);
        Assert.All(export.CodecRegistrations,
            item => Assert.True(item.Accept(probe)));
        Assert.All(export.ParserRegistrations,
            item => Assert.True(item.Accept(probe)));
        Assert.All(export.IndexRegistrations,
            item => Assert.True(item.Accept(probe)));
        Assert.All(export.DemandProjectorRegistrations,
            item => Assert.True(item.Accept(probe)));
        Assert.All(export.SelectorRegistrations,
            item => Assert.True(item.Accept(probe)));
        AssertEvaluators(export);

        return new(
            export.CodecRegistrations.Count, export.ParserRegistrations.Count,
            export.IndexRegistrations.Count,
            export.DemandProjectorRegistrations.Count,
            export.SelectorRegistrations.Count,
            export.EvaluatorRegistrations.Count,
            probe.CancellationClosed,
            probe.ResourceMetersClosed);
    }

    internal static EvidenceScope RepositoryScope()
    {
        var target = AcquisitionTarget.Create(
            "repo", "git", SurfaceKind.Repository,
            SnapshotKind.ExactCommit, Identity);
        return EvidenceScope.Create(target, AcquisitionBoundary.Create(
            SnapshotKind.ExactCommit, Identity,
            new DateTimeOffset(0, TimeSpan.Zero),
            new DateTimeOffset(1, TimeSpan.Zero)));
    }

    private static void AssertEvaluators(PolicyQualificationSliceExport export)
    {
        var access = RuleInputAccess.Create(
            [], new Dictionary<string, QualifiedEvidenceHandle>(),
            RejectingReferences.Instance);
        var profile = ExecutionProfile.Create(
            SubjectRole.Consumer, ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit, SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);
        foreach (var registration in export.EvaluatorRegistrations)
        {
            var applicability = RuleApplicabilityInput.Create(
                registration.Declaration.RuleId,
                registration.Declaration.RuleRevision, profile, access);
            var evaluation = RuleEvaluationInput.Create(
                registration.Declaration.RuleId,
                registration.Declaration.RuleRevision, profile, access);
            Assert.Equal(ApplicabilityIntentKind.Applicable,
                registration.Evaluator.EvaluateApplicability(
                    applicability, CancellationToken.None).Kind);
            if (registration.Declaration.RuleId.Value is "RULE-0001" or "RULE-0002")
            {
                Assert.Throws<OperationCanceledException>(() =>
                    registration.Evaluator.Evaluate(
                        evaluation, new CancellationToken(true)));
                continue;
            }

            var result = registration.Evaluator.Evaluate(
                evaluation, CancellationToken.None);
            Assert.Empty(result.Findings);
            Assert.Empty(result.Failures);
            Assert.Throws<OperationCanceledException>(() =>
                registration.Evaluator.Evaluate(
                    evaluation, new CancellationToken(true)));
        }
    }

    private sealed class ProducerProbe(PolicyQualificationSliceExport export) :
        ICodecRegistrationVisitor<bool>, IParserRegistrationVisitor<bool>,
        IIndexRegistrationVisitor<bool>,
        IDemandProjectorRegistrationVisitor<bool>,
        ISelectorRegistrationVisitor<bool>
    {
        private readonly List<ISealedModelHandle> _models = [];
        private readonly List<ICapabilityHandle> _capabilities = [];
        internal bool CancellationClosed { get; private set; } = true;
        internal bool ResourceMetersClosed { get; private set; } = true;

        public bool Visit<TModel>(CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            var fixture = Source(registration.Declaration.SchemaKey);
            var slot = Slot(registration.Declaration.SchemaKey);
            var input = CanonicalPayloadWriteInput.Create(
                slot, fixture.Scope.Target, fixture.Source,
                registration.Declaration.Budget, Digest, fixture.DemandDigest,
                fixture.DemandItems);
            Assert.Throws<OperationCanceledException>(() =>
                registration.Codec.Write(input, new CancellationToken(true)));
            var payload = registration.Codec.Write(input, CancellationToken.None)
                .Accept(WriteObserver.Instance);
            Assert.Equal(registration.Declaration.SchemaKey, payload.SchemaKey);
            if (fixture.ExpectedDigest is not null)
            {
                Assert.Equal(fixture.ExpectedDigest,
                    Convert.ToHexString(SHA256.HashData(payload.CanonicalBytes.ToArray())));
            }

            var binding = EvidenceBinding.Create(
                payload, fixture.Location, [slot.Requirement.Key],
                new DateTimeOffset(0, TimeSpan.Zero));
            var qualification = CodecQualificationInput.Create(
                binding, Allowance(registration.Declaration.Budget), Digest,
                fixture.DemandDigest, fixture.DemandItems);
            var handle = registration.Codec.Qualify(
                qualification, CancellationToken.None)
                .Accept(QualificationObserver<TModel>.Instance)
                ?? throw new InvalidOperationException("Qualification returned no model.");
            var measured = registration.Codec.MeasureLocal(
                qualification, handle.Value, CancellationToken.None);
            ResourceMetersClosed &= measured.GeneratedBytes > 0;
            Assert.Throws<OperationCanceledException>(() =>
                registration.Codec.Qualify(
                    qualification, new CancellationToken(true)));
            CancellationClosed &= true;
            _models.Add(SealedModelHandle<TModel>.Create(
                handle.ModelType, QualifiedEvidenceHandle.Create(), handle.Value,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([])));

            var malformed = payload.CanonicalBytes.ToArray();
            malformed[0] ^= 0x01;
            var rejected = CodecQualificationInput.Create(
                EvidenceBinding.Create(
                    CanonicalEvidencePayload.Create(payload.SchemaKey,
                        payload.SchemaVersion, malformed),
                    fixture.Location, [slot.Requirement.Key],
                    new DateTimeOffset(0, TimeSpan.Zero)),
                Allowance(registration.Declaration.Budget),
                Digest,
                fixture.DemandDigest,
                fixture.DemandItems);
            Assert.Null(registration.Codec.Qualify(rejected, CancellationToken.None)
                .Accept(QualificationObserver<TModel>.Rejected));
            return true;
        }

        public bool Visit<TInput, TOutput>(
            ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel
        {
            var value = registration.Binder.Bind(Reader());
            var input = SemanticModelInput<TInput>.Create(
                value, Allowance(registration.Declaration.Budget));
            Assert.Throws<OperationCanceledException>(() =>
                registration.Parser.Parse(input, new CancellationToken(true)));
            var product = registration.Parser.Parse(input, CancellationToken.None)
                .Accept(ModelObserver<TOutput>.Instance);
            ResourceMetersClosed &= registration.Parser.MeasureLocal(
                input, product.Value, CancellationToken.None).GeneratedBytes >= 0;
            _models.Add(SealedModelHandle<TOutput>.Create(
                registration.OutputModel, QualifiedEvidenceHandle.Create(),
                product.Value, SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([])));
            return true;
        }

        public bool Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            var value = registration.Binder.Bind(Reader());
            var input = ContextIndexInput<TInput>.Create(
                value, Allowance(registration.Declaration.Budget),
                Derivations.Instance);
            Assert.Throws<OperationCanceledException>(() =>
                registration.Indexer.Build(input, new CancellationToken(true)));
            var product = registration.Indexer.Build(input, CancellationToken.None)
                .Accept(CapabilityObserver<TCapability>.Instance);
            _capabilities.Add(CapabilityHandle<TCapability>.Create(
                registration.OutputCapability, product.Value, product.Evidence,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([])));
            ResourceMetersClosed &= registration.Indexer.MeasureLocal(
                input, product.Value, CancellationToken.None).GeneratedBytes >= 0;
            return true;
        }

        public bool Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability
        {
            var input = DemandProjectionInput<TCapability>.Create(
                Slot("protocol.repository-target-resolution"),
                RepositoryScope().Target, [], [], [], [],
                Allowance(registration.Declaration.Budget));
            Assert.Throws<OperationCanceledException>(() =>
                registration.Projector.Project(input, new CancellationToken(true)));
            var product = registration.Projector.Project(input, CancellationToken.None)
                .Accept(ProjectionObserver.Instance);
            Assert.Empty(product.Candidates);
            ResourceMetersClosed &= registration.Projector.MeasureLocal(
                input, product.Candidates, CancellationToken.None).GeneratedBytes == 0;
            return true;
        }

        public bool Visit<TResolver>(SelectorRegistration<TResolver> registration)
            where TResolver : class, IExpectedSelectorResolver
        {
            var declaration = export.Catalog.Rules
                .SelectMany(rule => rule.ExpectedSelectors)
                .Single(item => ReferenceEquals(item.Resolver, registration.Component));
            var parent = QualifiedEvidenceHandle.Create();
            var result = registration.Resolver.Resolve(ExpectedSelectorInput.Create(
                declaration, parent, "docs/features/FEAT-0001/README.md"))
                .Accept(SelectorObserver.Instance);
            Assert.Same(parent, result.Parent);
            return true;
        }

        private TypedInputReader Reader() => TypedInputReader.Create(
            _models, _capabilities,
            new Dictionary<string, QualifiedEvidenceHandle>(),
            RejectingReferences.Instance, [], []);

        private EvidenceSlotDeclaration Slot(string schema) =>
            export.Catalog.Rules.SelectMany(rule =>
                    rule.ApplicabilitySlots.Concat(rule.EvaluationSlots))
                .First(item => item.Requirement.PayloadSchemaKey == schema);
    }

    private static SourceFixture Source(string schema)
    {
        var scope = RepositoryScope();
        if (schema == "protocol.governed-text")
        {
            var location = RepositoryEvidenceLocation.Create(
                scope, "docs/body.text", Identity, null, null, null);
            return new(scope, location,
                Created(CanonicalPayloadWriteSource.GovernedText(
                    scope, location, Digest, Digest,
                    Encoding.UTF8.GetBytes("alpha\nβ\n"))), [],
                Digest,
                "93261D439E5D04624BC1F832077CEB9BBD2CA7B83B1CF7EEE0EA679553CECDAA");
        }
        var snapshot = SnapshotEvidenceLocation.Create(scope);
        if (schema == "protocol.repository-tree")
        {
            return new(scope, snapshot,
                Created(CanonicalPayloadWriteSource.RepositoryTree(
                    scope, snapshot, Digest, Digest,
                    [RepositoryTreePayloadEntry.Create("AGENTS.md", RepositoryEntryKind.File),
                     RepositoryTreePayloadEntry.Create("docs", RepositoryEntryKind.Directory),
                     RepositoryTreePayloadEntry.Create("links/latest", RepositoryEntryKind.SymbolicLink),
                     RepositoryTreePayloadEntry.Create("vendor/protocol", RepositoryEntryKind.GitLink)])),
                [], Digest,
                "C5A8CB268E42C8A8C532A42C86ECDB0200B4C75186364B6399AD1AE5A40AE97F");
        }
        const string owner = "https://github.com/owner/repo";
        const string capture =
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";
        var demands = new[]
        {
            RepositoryTargetResolutionDemandItem.Create(
                0, owner, Identity, null, null, "docs/README.md", "intro"),
            RepositoryTargetResolutionDemandItem.Create(
                1, owner, null, "v1", null, null, null),
            RepositoryTargetResolutionDemandItem.Create(
                2, owner, null, null, capture, "src/file.txt", "L1"),
        };
        var commitBytes = Encoding.UTF8.GetBytes("# Intro\n");
        var commitBlob = GitBlobIdentity(commitBytes);
        var capturedBytes = Encoding.UTF8.GetBytes("line\n");
        var capturedDigest = Convert.ToHexString(SHA256.HashData(capturedBytes))
            .ToLowerInvariant();
        var commitContent = RepositoryTargetResolutionContent.CommitObject(
            owner, Identity, "docs/README.md", commitBlob, commitBytes);
        var capturedContent =
            RepositoryTargetResolutionContent.CapturedSnapshotPath(
                owner,
                capture,
                "src/file.txt",
                capturedDigest,
                capturedBytes);
        var demandDigest = ExactSha256Digest.Parse(
            "9df61ac4d5f82c5fda121b05319b16399580fc0a8d28b4ac62d1879d24899cba");
        return new(scope, snapshot,
            Created(CanonicalPayloadWriteSource.RepositoryTargetResolution(
                scope, snapshot, Digest, demandDigest,
                [
                    RepositoryTargetResolutionPayloadRow.PresentCommitPath(
                        demands[0], owner, "commit", Identity,
                        "docs/README.md", "blob", commitBlob, commitContent),
                    RepositoryTargetResolutionPayloadRow.PresentTag(
                        demands[1], owner, "refs/tags/v1", "tag",
                        new string('1', 40), "commit", Identity),
                    RepositoryTargetResolutionPayloadRow.PresentCapturedPath(
                        demands[2], owner, capture, "src/file.txt", "file",
                        capturedDigest, capturedContent),
                ],
                [commitContent, capturedContent])),
            demands,
            demandDigest,
            "936D99ECDDC7332999B2641787BF160A1D126F27DAEB4F54BE1EBC8F426EE6F0");
    }

    private static string GitBlobIdentity(byte[] bytes)
    {
        var header = Encoding.ASCII.GetBytes($"blob {bytes.Length}\0");
        return Convert.ToHexString(SHA1.HashData([.. header, .. bytes]))
            .ToLowerInvariant();
    }

    private static CanonicalPayloadWriteSource Created(
        CanonicalPayloadWriteSourceIntent intent) =>
        intent.Accept(SourceObserver.Instance);

    private static SemanticResourceAllowance Allowance(
        SemanticResourceBudget budget) =>
        SemanticResourceAllowance.Create(
            budget, SemanticResourceUsage.Create(0, 0, 0, 0));

    private sealed record SourceFixture(
        EvidenceScope Scope, EvidenceLocation Location,
        CanonicalPayloadWriteSource Source,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems,
        ExactSha256Digest DemandDigest,
        string? ExpectedDigest);

    private sealed class SourceObserver :
        ICanonicalPayloadWriteSourceIntentVisitor<CanonicalPayloadWriteSource>
    {
        internal static SourceObserver Instance { get; } = new();
        public CanonicalPayloadWriteSource VisitCreated(CanonicalPayloadWriteSource source) => source;
        public CanonicalPayloadWriteSource VisitRejected(string schemaKey, string schemaVersion,
            EvidenceScope scope, EvidenceLocation location, ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest, string codecFailureCode) =>
            throw new InvalidOperationException(codecFailureCode);
    }

    private sealed class WriteObserver :
        ICanonicalPayloadWriteIntentVisitor<CanonicalEvidencePayload>
    {
        internal static WriteObserver Instance { get; } = new();
        public CanonicalEvidencePayload VisitWritten(CanonicalPayloadWriteProduct product) => product.Payload;
        public CanonicalEvidencePayload VisitRejected(IReadOnlyList<AcquisitionFailure> failures) =>
            throw new InvalidOperationException(string.Join(',', failures.Select(item => item.Code)));
    }

    private sealed class QualificationObserver<TModel> :
        ICodecQualificationIntentVisitor<TModel, CodecModelHandle<TModel>?>
        where TModel : class, IProtocolSemanticModel
    {
        internal static QualificationObserver<TModel> Instance { get; } = new(false);
        internal static QualificationObserver<TModel> Rejected { get; } = new(true);
        private QualificationObserver(bool rejected) => _rejected = rejected;
        private readonly bool _rejected;
        public CodecModelHandle<TModel>? VisitQualified(CodecModelHandle<TModel> model) =>
            _rejected ? throw new InvalidOperationException("Expected rejection.") : model;
        public CodecModelHandle<TModel>? VisitRejected(IReadOnlyList<AcquisitionFailure> failures) =>
            _rejected ? null : throw new InvalidOperationException(failures[0].Code);
    }

    private sealed class ModelObserver<TModel> :
        ISemanticModelIntentVisitor<TModel, SemanticModelProduct<TModel>>
        where TModel : class, IProtocolSemanticModel
    {
        internal static ModelObserver<TModel> Instance { get; } = new();
        public SemanticModelProduct<TModel> VisitProduced(SemanticModelProduct<TModel> product) => product;
        public SemanticModelProduct<TModel> VisitFailed(SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }

    private sealed class CapabilityObserver<TCapability> :
        ICapabilityIntentVisitor<TCapability, CapabilityProduct<TCapability>>
        where TCapability : class, IEvidenceCapability
    {
        internal static CapabilityObserver<TCapability> Instance { get; } = new();
        public CapabilityProduct<TCapability> VisitProduced(CapabilityProduct<TCapability> product) => product;
        public CapabilityProduct<TCapability> VisitFailed(SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }

    private sealed class ProjectionObserver :
        IDemandProjectionIntentVisitor<DemandProjectionProduct>
    {
        internal static ProjectionObserver Instance { get; } = new();
        public DemandProjectionProduct VisitProjected(DemandProjectionProduct product) => product;
        public DemandProjectionProduct VisitFailed(SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }

    private sealed class SelectorObserver : ISelectorIntentVisitor<SelectorProduct>
    {
        internal static SelectorObserver Instance { get; } = new();
        public SelectorProduct VisitResolved(SelectorProduct product) => product;
        public SelectorProduct VisitInvalid(CatalogIntegrityCode code) =>
            throw new InvalidOperationException(code.Value);
    }

    private sealed class RejectingReferences : IExpectedReferenceLookup
    {
        internal static RejectingReferences Instance { get; } = new();
        public QualifiedEvidenceHandle Require(string selectorKey, QualifiedEvidenceHandle parent) =>
            throw new InvalidOperationException("No expected reference is available.");
    }

    private sealed class Derivations : IQualifiedEvidenceDerivationFactory
    {
        internal static Derivations Instance { get; } = new();
        public QualifiedEvidenceHandle Derive(QualifiedEvidenceHandle parent,
            string typedNodeKind, string typedNodeIdentity, EvidenceLocation location) =>
            QualifiedEvidenceHandle.Create();
    }
}
