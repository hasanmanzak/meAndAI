using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;
using System.Text;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceDPolicyEvaluatorTests
{
    private const string Rule1Marker = "TEST-0210-D-BEHAVIOR-RED-0003";
    private const string Rule2Marker = "TEST-0210-D-BEHAVIOR-RED-0004";

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0001_against_fresh_qualified_fixture()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0001(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule1Marker);
        }

        Assert.Equal(8, evidence.ExercisedFindings);
        Assert.Equal(7, evidence.ExercisedFixtures);
        Assert.True(evidence.ExactReferences);
        Assert.True(evidence.CancellationClosed);
    }

    [Fact]
    [Trait("ContractSlice", "D")]
    public void Evaluates_rule_0002_against_fresh_qualified_fixture()
    {
        ContractSliceDPolicyEvaluatorEvidence? evidence =
            ContractSliceDPolicyEvaluatorFixture.EvaluateRule0002(
                InitialRuleQualificationPolicy.Export);
        if (evidence is null)
        {
            Assert.Fail(Rule2Marker);
        }

        Assert.Equal(11, evidence.ExercisedFindings);
        Assert.Equal(12, evidence.ExercisedFixtures);
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
    private const string TextSlot = "protocol.slot.repository-governed-text";
    private const string ReadmeSelector = "protocol.selector.feature-readme";
    private const string TestsSelector = "protocol.selector.feature-test-cases";
    private const string DecisionSelector = "protocol.selector.decision-record";
    private const string Rule1 = "RULE-0001";
    private const string Rule2 = "RULE-0002";
    private const string ObjectIdentity =
        "0123456789abcdef0123456789abcdef01234567";
    private const string ReferenceText = "# Feature record\n\nSee DEC-0001.\n";
    private const string ValidDecision = """
        # DEC-0001 - Exact decision

        1. Classification: Accepted
        2. Status: Active
        3. Date: 2026-08-13
        4. Decision owners: Protocol maintainers
        5. Related features: FEAT-0065
        6. Related decisions: None

        ## Context

        Exact context.

        ## Decision

        Exact decision.

        ## Consequences

        Exact consequences.

        ## Alternatives considered

        Exact alternatives.

        ## Review condition

        Exact review condition.
        """;
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

    internal static ContractSliceDPolicyEvaluatorEvidence? EvaluateRule0002(
        PolicyQualificationSliceExport export)
    {
        ArgumentNullException.ThrowIfNull(export);

        var missing = EvaluateDecision(export, ReferenceText);
        if (missing.Intent.Findings.Count == 0 && missing.Intent.Failures.Count == 0)
        {
            return null;
        }

        AssertDecisionFindings(missing,
            ("protocol.decision.record-missing", "DEC-0001"));

        var valid = EvaluateDecision(export, ReferenceText, ValidDecision);
        AssertDecisionFindings(valid);

        var missingMetadata = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace("3. Date: 2026-08-13\n", string.Empty,
                StringComparison.Ordinal));
        AssertDecisionFindings(missingMetadata,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var reorderedMetadata = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "2. Status: Active\n3. Date: 2026-08-13",
                "2. Date: 2026-08-13\n3. Status: Active",
                StringComparison.Ordinal));
        AssertDecisionFindings(reorderedMetadata,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var duplicateMetadata = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "3. Date: 2026-08-13",
                "3. Status: Active\n4. Date: 2026-08-13",
                StringComparison.Ordinal));
        AssertDecisionFindings(duplicateMetadata,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var missingSection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "## Consequences\n\nExact consequences.\n\n",
                string.Empty,
                StringComparison.Ordinal));
        AssertDecisionFindings(missingSection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var reorderedSection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "## Decision\n\nExact decision.\n\n## Consequences\n\nExact consequences.",
                "## Consequences\n\nExact consequences.\n\n## Decision\n\nExact decision.",
                StringComparison.Ordinal));
        AssertDecisionFindings(reorderedSection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var duplicateSection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "## Consequences\n\nExact consequences.",
                "## Decision\n\nDuplicate decision.\n\n## Consequences\n\nExact consequences.",
                StringComparison.Ordinal));
        AssertDecisionFindings(duplicateSection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var emptySection = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace("## Context\n\nExact context.", "## Context",
                StringComparison.Ordinal));
        AssertDecisionFindings(emptySection,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var malformedHeading = EvaluateDecision(export, ReferenceText,
            ValidDecision.Replace(
                "# DEC-0001 - Exact decision",
                "# DEC-0001 - ",
                StringComparison.Ordinal));
        AssertDecisionFindings(malformedHeading,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var duplicateDecision = EvaluateDecision(
            export, ReferenceText, ValidDecision, ValidDecision);
        AssertDecisionFindings(duplicateDecision,
            ("protocol.decision.structure-invalid", "DEC-0001"));

        var ordinal = EvaluateDecision(
            export,
            "# Feature record\n\nSee DEC-0002 then DEC-0001.\n",
            ValidDecision);
        AssertDecisionFindings(ordinal,
            ("protocol.decision.record-missing", "DEC-0002"));

        var cases = new[]
        {
            missing, valid, missingMetadata, reorderedMetadata,
            duplicateMetadata, missingSection, reorderedSection,
            duplicateSection, emptySection, malformedHeading,
            duplicateDecision, ordinal,
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
            item.Declaration.RuleId.Value == Rule1);
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

    private static DecisionCase EvaluateDecision(
        PolicyQualificationSliceExport export,
        params string[] documents)
    {
        var treeEntries = new List<RepositoryTreePayloadEntry>
        {
            Entry("docs", RepositoryEntryKind.Directory),
            Entry("docs/decisions", RepositoryEntryKind.Directory),
        };
        treeEntries.AddRange(documents.Select((_, index) =>
            Entry($"docs/decisions/document-{index:D2}.md", RepositoryEntryKind.File)));
        var treeModel = export.CodecRegistrations
            .Single(item => item.Declaration.SchemaKey == "protocol.repository-tree")
            .Accept(new TreeCodecVisitor(export, treeEntries));
        var tree = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey == "protocol.index.repository-tree")
            .Accept(new TreeIndexVisitor(treeModel));

        var parsed = documents.Select((text, index) =>
        {
            var source = export.CodecRegistrations
                .Single(item => item.Declaration.SchemaKey == "protocol.governed-text")
                .Accept(new TextCodecVisitor(
                    export,
                    $"docs/decisions/document-{index:D2}.md",
                    text));
            return export.ParserRegistrations
                .Single(item => item.Declaration.ParserKey == "protocol.parser.markdown")
                .Accept(new MarkdownParserVisitor(source));
        }).ToArray();
        var records = export.IndexRegistrations
            .Single(item => item.Declaration.IndexKey == "protocol.index.protocol-record")
            .Accept(new RecordIndexVisitor(parsed));
        var treeProof = QualifiedEvidenceHandle.Create();
        var textProof = QualifiedEvidenceHandle.Create();
        var lookup = new ExpectedReferences();
        var access = RuleInputAccess.Create(
            [
                SlotCapabilityBinding.Create(TreeSlot, tree.Handle),
                SlotCapabilityBinding.Create(TextSlot, records.Handle),
            ],
            new Dictionary<string, QualifiedEvidenceHandle>
            {
                [TreeSlot] = treeProof,
                [TextSlot] = textProof,
            },
            lookup);
        var registration = export.EvaluatorRegistrations.Single(item =>
            item.Declaration.RuleId.Value == Rule2);
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
        var intent = registration.Evaluator.Evaluate(input, CancellationToken.None);
        Assert.Throws<OperationCanceledException>(() =>
            registration.Evaluator.Evaluate(input, new CancellationToken(true)));
        return new(intent, records.Index, lookup, treeProof, textProof, true, true);
    }

    private static void AssertDecisionFindings(
        DecisionCase actual,
        params (string Code, string RecordId)[] expected)
    {
        Assert.Empty(actual.Intent.Failures);
        Assert.Equal(expected.Select(item => item.Code),
            actual.Intent.Findings.Select(item => item.Code.Value));
        for (var index = 0; index < expected.Length; index++)
        {
            var item = expected[index];
            var reference = actual.Index.Records.Single(record =>
                record.RecordKind == "protocol.record.decision-reference" &&
                record.RecordId == item.RecordId);
            var finding = actual.Intent.Findings[index];
            if (item.Code == "protocol.decision.record-missing")
            {
                Assert.Same(
                    actual.References.Require(DecisionSelector, reference.Evidence),
                    finding.PrimaryReference);
            }
            else
            {
                Assert.Same(
                    actual.Index.Records.First(record =>
                        record.RecordKind == "protocol.record.decision" &&
                        record.RecordId == item.RecordId).Evidence,
                    finding.PrimaryReference);
            }

            Assert.Collection(finding.RelatedReferences,
                related => Assert.Same(actual.TreeProof, related),
                related => Assert.Same(actual.TextProof, related),
                related => Assert.Same(reference.Evidence, related));
        }
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

    private sealed record DecisionCase(
        EvaluationIntent Intent,
        IProtocolRecordIndex Index,
        ExpectedReferences References,
        QualifiedEvidenceHandle TreeProof,
        QualifiedEvidenceHandle TextProof,
        bool ExactReferences,
        bool CancellationClosed);

    private sealed record IndexedTree(
        IRepositoryTree Tree,
        CapabilityHandle<IRepositoryTree> Handle);

    private sealed record IndexedRecords(
        IProtocolRecordIndex Index,
        CapabilityHandle<IProtocolRecordIndex> Handle);

    private sealed class TextCodecVisitor(
        PolicyQualificationSliceExport export,
        string path,
        string text) : ICodecRegistrationVisitor<ISealedModelHandle>
    {
        public ISealedModelHandle Visit<TModel>(
            CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            Assert.Equal("protocol.governed-text", registration.Declaration.SchemaKey);
            var scope = ContractSliceDProducerInfrastructureFixture.RepositoryScope();
            var location = RepositoryEvidenceLocation.Create(
                scope, path, ObjectIdentity, null, null, null);
            var source = CanonicalPayloadWriteSource.GovernedText(
                    scope,
                    location,
                    Digest,
                    Digest,
                    Encoding.UTF8.GetBytes(text))
                .Accept(SourceObserver.Instance);
            var slot = export.Catalog.Rules
                .Single(item => item.RuleId.Value == Rule2)
                .EvaluationSlots.Single(item => item.SlotKey == TextSlot);
            var write = CanonicalPayloadWriteInput.Create(
                slot,
                scope.Target,
                source,
                registration.Declaration.Budget,
                Digest,
                Digest,
                []);
            var payload = registration.Codec.Write(write, CancellationToken.None)
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

    private sealed class MarkdownParserVisitor(ISealedModelHandle source) :
        IParserRegistrationVisitor<ISealedModelHandle>
    {
        public ISealedModelHandle Visit<TInput, TOutput>(
            ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel
        {
            var bound = registration.Binder.Bind(TypedInputReader.Create(
                [source],
                [],
                new Dictionary<string, QualifiedEvidenceHandle>(),
                ExpectedReferences.Rejecting,
                [],
                []));
            var input = SemanticModelInput<TInput>.Create(
                bound,
                Allowance(registration.Declaration.Budget));
            var product = registration.Parser.Parse(input, CancellationToken.None)
                .Accept(ModelObserver<TOutput>.Instance);
            return SealedModelHandle<TOutput>.Create(
                registration.OutputModel,
                QualifiedEvidenceHandle.Create(),
                product.Value,
                SemanticResourceUsage.Create(0, 0, 0, 0),
                SemanticResourceLedger.Create([]));
        }
    }

    private sealed class RecordIndexVisitor(IReadOnlyList<ISealedModelHandle> models) :
        IIndexRegistrationVisitor<IndexedRecords>
    {
        public IndexedRecords Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            var bound = registration.Binder.Bind(TypedInputReader.Create(
                models,
                [],
                new Dictionary<string, QualifiedEvidenceHandle>(),
                ExpectedReferences.Rejecting,
                [],
                []));
            var input = ContextIndexInput<TInput>.Create(
                bound,
                Allowance(registration.Declaration.Budget),
                Derivations.Instance);
            var product = registration.Indexer.Build(input, CancellationToken.None)
                .Accept(CapabilityObserver<TCapability>.Instance);
            var index = Assert.IsAssignableFrom<IProtocolRecordIndex>(product.Value);
            return new IndexedRecords(
                index,
                CapabilityHandle<IProtocolRecordIndex>.Create(
                    CapabilityTypeToken<IProtocolRecordIndex>.Create(
                        registration.Declaration.OutputCapability),
                    index,
                    product.Evidence,
                    SemanticResourceUsage.Create(0, 0, 0, 0),
                    SemanticResourceLedger.Create([])));
        }
    }

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
                .Single(item => item.RuleId.Value == Rule1)
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

    private sealed class ModelObserver<TModel> :
        ISemanticModelIntentVisitor<TModel, SemanticModelProduct<TModel>>
        where TModel : class, IProtocolSemanticModel
    {
        internal static ModelObserver<TModel> Instance { get; } = new();

        public SemanticModelProduct<TModel> VisitProduced(
            SemanticModelProduct<TModel> product) => product;

        public SemanticModelProduct<TModel> VisitFailed(
            SemanticFailureIntent failure) =>
            throw new InvalidOperationException(failure.Code.Value);
    }
}
