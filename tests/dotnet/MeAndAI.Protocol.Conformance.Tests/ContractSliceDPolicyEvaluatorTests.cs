using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceDPolicyEvaluatorTests
{
    private const string Marker = "TEST-0210-D-BEHAVIOR-RED-0003";

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0001_against_fresh_qualified_fixture()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0001(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal(8, evidence.ExercisedFindings);
        Assert.Equal(7, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }
}

internal sealed record ContractSliceDPolicyEvaluatorEvidence(
    int ExercisedFindings,
    int ExercisedFixtures,
    bool ExactReferences,
    bool CancellationClosed);

internal static class ContractSliceDPolicyEvaluatorFixture
{
    private const string FeatureRoot =
        "docs/features/FEAT-0065-shared-executable-conformance-runtime";
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string ReadmeSelector = "protocol.selector.feature-readme";
    private const string TestsSelector = "protocol.selector.feature-test-cases";
    private const string Rule = "RULE-0001";
    private static readonly ExactSha256Digest Digest =
        ExactSha256Digest.Parse(new string('0', 64));

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0001(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);

        var missingReadme = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.File));
        if (missingReadme.Intent.Findings.Count == 0 &&
            missingReadme.Intent.Failures.Count == 0)
        {
            return null;
        }

        AssertFindings(missingReadme,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot));

        var complete = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/README.md", RepositoryEntryKind.File),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.File));
        AssertFindings(complete);

        var missingTests = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/README.md", RepositoryEntryKind.File));
        AssertFindings(missingTests,
            ("protocol.feature.test-cases-missing", TestsSelector, FeatureRoot));

        var bothMissing = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory));
        AssertFindings(bothMissing,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot),
            ("protocol.feature.test-cases-missing", TestsSelector, FeatureRoot));

        var wrongKinds = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/README.md", RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.SymbolicLink));
        AssertFindings(wrongKinds,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot),
            ("protocol.feature.test-cases-missing", TestsSelector, FeatureRoot));

        var ignored = Evaluate(export,
            Entry("docs/features/FEAT-0065", RepositoryEntryKind.Directory),
            Entry("docs/features/feat-0065-lowercase", RepositoryEntryKind.Directory),
            Entry("docs/ideas/FEAT-0065-unrelated", RepositoryEntryKind.Directory));
        AssertFindings(ignored);

        const string otherRoot = "docs/features/FEAT-9999-other";
        var ordinal = Evaluate(export,
            Entry(FeatureRoot, RepositoryEntryKind.Directory),
            Entry($"{FeatureRoot}/test-cases.md", RepositoryEntryKind.File),
            Entry(otherRoot, RepositoryEntryKind.Directory),
            Entry($"{otherRoot}/README.md", RepositoryEntryKind.File));
        AssertFindings(ordinal,
            ("protocol.feature.readme-missing", ReadmeSelector, FeatureRoot),
            ("protocol.feature.test-cases-missing", TestsSelector, otherRoot));

        var cases = new[]
        {
            missingReadme, complete, missingTests, bothMissing,
            wrongKinds, ignored, ordinal,
        };
        return new(
            cases.Sum(item => item.Intent.Findings.Count),
            cases.Length,
            cases.All(item => item.ExactReferences),
            cases.All(item => item.CancellationClosed));
    }

    private static EvaluationCase Evaluate(
        PolicyQualificationSliceExport export,
        params RepositoryTreePayloadEntry[] entries)
    {
        var model = export.CodecRegistrations
            .Single(item => item.Declaration.SchemaKey == "protocol.repository-tree")
            .Accept(new TreeCodecVisitor(export, entries));
        var indexed = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey == "protocol.index.repository-tree")
            .Accept(new TreeIndexVisitor(model));
        var lookup = new ExpectedReferences();
        var access = RuleInputAccess.Create(
            [SlotCapabilityBinding.Create(TreeSlot, indexed.Handle)],
            new Dictionary<string, QualifiedEvidenceHandle>(),
            lookup);
        var registration = export.EvaluatorRegistrations.Single(item =>
            item.Declaration.RuleId.Value == Rule);
        var profile = ExecutionProfile.Create(
            SubjectRole.Consumer,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);
        var input = RuleEvaluationInput.Create(
            registration.Declaration.RuleId,
            registration.Declaration.RuleRevision,
            profile,
            access);
        var intent = registration.Evaluator.Evaluate(
            input, CancellationToken.None);
        Assert.Throws<OperationCanceledException>(() =>
            registration.Evaluator.Evaluate(
                input, new CancellationToken(canceled: true)));
        return new(intent, indexed.Tree, lookup, true, true);
    }

    private static void AssertFindings(
        EvaluationCase actual,
        params (string Code, string Selector, string ParentPath)[] expected)
    {
        Assert.Empty(actual.Intent.Failures);
        Assert.Equal(expected.Select(item => item.Code),
            actual.Intent.Findings.Select(item => item.Code.Value));
        for (var index = 0; index < expected.Length; index++)
        {
            var item = expected[index];
            var parent = actual.Tree.Entries.Single(entry =>
                entry.RepositoryRelativePath == item.ParentPath).Evidence;
            var primary = actual.References.Require(item.Selector, parent);
            Assert.Same(primary, actual.Intent.Findings[index].PrimaryReference);
            Assert.Collection(actual.Intent.Findings[index].RelatedReferences,
                related => Assert.Same(parent, related));
        }
    }

    private static RepositoryTreePayloadEntry Entry(
        string path,
        RepositoryEntryKind kind) =>
        RepositoryTreePayloadEntry.Create(path, kind);

    private static SemanticResourceAllowance Allowance(
        SemanticResourceBudget budget) =>
        SemanticResourceAllowance.Create(
            budget, SemanticResourceUsage.Create(0, 0, 0, 0));

    private sealed record EvaluationCase(
        EvaluationIntent Intent,
        IRepositoryTree Tree,
        ExpectedReferences References,
        bool ExactReferences,
        bool CancellationClosed);

    private sealed record IndexedTree(
        IRepositoryTree Tree,
        CapabilityHandle<IRepositoryTree> Handle);

    private sealed class TreeCodecVisitor(
        PolicyQualificationSliceExport export,
        IReadOnlyList<RepositoryTreePayloadEntry> entries) :
        ICodecRegistrationVisitor<ISealedModelHandle>
    {
        public ISealedModelHandle Visit<TModel>(
            CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            Assert.Equal("protocol.repository-tree",
                registration.Declaration.SchemaKey);
            var scope = ContractSliceDProducerInfrastructureFixture.RepositoryScope();
            var location = SnapshotEvidenceLocation.Create(scope);
            var callerEntries = entries.ToList();
            var source = CanonicalPayloadWriteSource.RepositoryTree(
                    scope, location, Digest, Digest, callerEntries)
                .Accept(SourceObserver.Instance);
            callerEntries.Clear();
            var slot = export.Catalog.Rules
                .Single(item => item.RuleId.Value == Rule)
                .EvaluationSlots.Single();
            var write = CanonicalPayloadWriteInput.Create(
                slot,
                scope.Target,
                source,
                registration.Declaration.Budget,
                Digest,
                Digest,
                []);
            var payload = registration.Codec.Write(
                    write, CancellationToken.None)
                .Accept(WriteObserver.Instance);
            var qualification = CodecQualificationInput.Create(
                EvidenceBinding.Create(
                    payload,
                    location,
                    [slot.Requirement.Key],
                    new DateTimeOffset(0, TimeSpan.Zero)),
                Allowance(registration.Declaration.Budget),
                Digest,
                Digest,
                []);
            var model = registration.Codec.Qualify(
                    qualification, CancellationToken.None)
                .Accept(QualificationObserver<TModel>.Instance);
            return SealedModelHandle<TModel>.Create(
                model.ModelType,
                QualifiedEvidenceHandle.Create(),
                model.Value,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([]));
        }
    }

    private sealed class TreeIndexVisitor(ISealedModelHandle model) :
        IIndexRegistrationVisitor<IndexedTree>
    {
        public IndexedTree Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            Assert.Equal("protocol.index.repository-tree",
                registration.Declaration.IndexKey);
            var input = ContextIndexInput<TInput>.Create(
                registration.Binder.Bind(TypedInputReader.Create(
                    [model],
                    [],
                    new Dictionary<string, QualifiedEvidenceHandle>(),
                    ExpectedReferences.Rejecting,
                    [],
                    [])),
                Allowance(registration.Declaration.Budget),
                Derivations.Instance);
            var product = registration.Indexer.Build(
                    input, CancellationToken.None)
                .Accept(CapabilityObserver<TCapability>.Instance);
            var tree = Assert.IsAssignableFrom<IRepositoryTree>(product.Value);
            return new IndexedTree(
                tree,
                CapabilityHandle<IRepositoryTree>.Create(
                    CapabilityTypeToken<IRepositoryTree>.Create(
                        registration.Declaration.OutputCapability),
                    tree,
                    product.Evidence,
                    SemanticResourceUsage.Create(0, 0, 0, 0),
                    SemanticResourceLedger.Create([])));
        }
    }

    private sealed class ExpectedReferences : IExpectedReferenceLookup
    {
        private readonly List<ReferenceEntry> _entries = [];
        internal static IExpectedReferenceLookup Rejecting { get; } =
            new RejectingReferences();

        public QualifiedEvidenceHandle Require(
            string selectorKey,
            QualifiedEvidenceHandle parent)
        {
            var existing = _entries.SingleOrDefault(item =>
                item.SelectorKey == selectorKey &&
                ReferenceEquals(item.Parent, parent));
            if (existing is not null)
            {
                return existing.Handle;
            }

            var created = new ReferenceEntry(
                selectorKey,
                parent,
                QualifiedEvidenceHandle.Create());
            _entries.Add(created);
            return created.Handle;
        }

        private sealed record ReferenceEntry(
            string SelectorKey,
            QualifiedEvidenceHandle Parent,
            QualifiedEvidenceHandle Handle);

        private sealed class RejectingReferences : IExpectedReferenceLookup
        {
            public QualifiedEvidenceHandle Require(
                string selectorKey,
                QualifiedEvidenceHandle parent) =>
                throw new InvalidOperationException(
                    "No expected reference is available during indexing.");
        }
    }

    private sealed class Derivations : IQualifiedEvidenceDerivationFactory
    {
        internal static Derivations Instance { get; } = new();

        public QualifiedEvidenceHandle Derive(
            QualifiedEvidenceHandle parent,
            string typedNodeKind,
            string typedNodeIdentity,
            EvidenceLocation location) =>
            QualifiedEvidenceHandle.Create();
    }

    private sealed class SourceObserver :
        ICanonicalPayloadWriteSourceIntentVisitor<CanonicalPayloadWriteSource>
    {
        internal static SourceObserver Instance { get; } = new();

        public CanonicalPayloadWriteSource VisitCreated(
            CanonicalPayloadWriteSource source) => source;

        public CanonicalPayloadWriteSource VisitRejected(
            string schemaKey,
            string schemaVersion,
            EvidenceScope scope,
            EvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            string codecFailureCode) =>
            throw new InvalidOperationException(codecFailureCode);
    }

    private sealed class WriteObserver :
        ICanonicalPayloadWriteIntentVisitor<CanonicalEvidencePayload>
    {
        internal static WriteObserver Instance { get; } = new();

        public CanonicalEvidencePayload VisitWritten(
            CanonicalPayloadWriteProduct product) => product.Payload;

        public CanonicalEvidencePayload VisitRejected(
            IReadOnlyList<AcquisitionFailure> failures) =>
            throw new InvalidOperationException(failures[0].Code);
    }

    private sealed class QualificationObserver<TModel> :
        ICodecQualificationIntentVisitor<TModel, CodecModelHandle<TModel>>
        where TModel : class, IProtocolSemanticModel
    {
        internal static QualificationObserver<TModel> Instance { get; } = new();

        public CodecModelHandle<TModel> VisitQualified(
            CodecModelHandle<TModel> model) => model;

        public CodecModelHandle<TModel> VisitRejected(
            IReadOnlyList<AcquisitionFailure> failures) =>
            throw new InvalidOperationException(failures[0].Code);
    }

    private sealed class CapabilityObserver<TCapability> :
        ICapabilityIntentVisitor<TCapability, CapabilityProduct<TCapability>>
        where TCapability : class, IEvidenceCapability
    {
        internal static CapabilityObserver<TCapability> Instance { get; } = new();

        public CapabilityProduct<TCapability> VisitProduced(
            CapabilityProduct<TCapability> product) => product;

        public CapabilityProduct<TCapability> VisitFailed(
            SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }
}
