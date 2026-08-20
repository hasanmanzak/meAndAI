using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;
using MeAndAI.Protocol.Policy.Models;
using MeAndAI.Protocol.Policy.ProtectedPolicy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicyExtensionEvaluationTests
{
    private const string RepositoryTreeSlot = "protocol.slot.repository-tree";

    [Fact]
    public void Evaluates_only_protocol_owned_additive_extension_kinds()
    {
        var registration =
            RepositoryPathRequiredExtensionEvaluator.CreateRegistration();
        var declaration = CreateDeclaration();
        var policy = ProjectNeutralProtectedAuthorityFixture.CreateTestPolicy(
            [registration]);
        var fixture = ProjectNeutralProtectedAuthorityFixture
            .CreateCanonicalNonempty(policy, declaration);
        Assert.Same(declaration, Assert.Single(fixture.Snapshot.Extensions));
        Assert.Same(
            registration.Declaration,
            Assert.Single(fixture.Policy.EvaluatorKinds));

        var active = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        var evidence = CreateEvidence(fixture);
        var evaluations = fixture.Kernel.EvaluateExtensions(
            active,
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.Conformance,
                SnapshotKind.ExactCommit,
                SurfaceSet.Create([SurfaceKind.Repository]),
                EnforcementPhase.Audit),
            [RepositoryTreeSlot],
            evidence.Access,
            evidence.References,
            CancellationToken.None);
        var evaluation = Assert.Single(evaluations);
        Assert.Equal(declaration.ExtensionId, evaluation.ExtensionId);
        Assert.Equal(declaration.Revision, evaluation.RuleRevision);
        Assert.Equal(RuleEvaluationStatus.Violated, evaluation.Status);
        Assert.False(evaluation.IsApplicabilityUnresolved);
        Assert.Empty(evaluation.ApplicabilityReferences);
        Assert.Empty(evaluation.UnresolvedSlotKeys);
        Assert.Empty(evaluation.Failures);
        var finding = Assert.Single(evaluation.Findings);
        Assert.Equal(
            FindingCode.Parse("protocol.extension.required-path-missing"),
            finding.Code);
        Assert.Equal(FindingSeverity.Parse("protocol.finding.error"), finding.Severity);
        Assert.Equal(
            RemediationKey.Parse("protocol.remediation.restore-required-path"),
            finding.Remediation);
        Assert.Same(evidence.Reference, finding.PrimaryReference);
        Assert.Empty(finding.RelatedReferences);
        Assert.Equal("missing", finding.StableStateToken);
        Assert.Null(finding.StableStateValue);

        AssertRegistration(registration);
        AssertEvaluationMatrix(fixture, active, declaration);
        AssertDeclarationRejections(registration, evidence);
    }

    private static void AssertRegistration(ExtensionEvaluatorRegistration registration)
    {
        Assert.Equal(
            "protocol.extension.repository-path-required",
            registration.Declaration.EvaluatorKind);
        Assert.Equal("1", registration.Declaration.EvaluatorVersion);
        Assert.Equal(
            "protocol.evaluator.extension.repository-path-required",
            registration.Declaration.Component.ComponentKey);
        Assert.Equal("1", registration.Declaration.Component.ComponentVersion);
        Assert.Equal(
            "MeAndAI.Protocol.Policy",
            registration.Declaration.Component.AssemblyName);
        Assert.Equal(
            typeof(RepositoryPathRequiredExtensionEvaluator).FullName,
            registration.Declaration.Component.TypeName);
        Assert.Collection(
            registration.Declaration.Parameters,
            kind => Assert.Equal(
                ("kind", "directory|file|symbolic-link|git-link", 16),
                (kind.Key, kind.ValueGrammar, kind.MaximumUtf8Bytes)),
            path => Assert.Equal(
                ("path", "normalized-repository-relative-path", 4096),
                (path.Key, path.ValueGrammar, path.MaximumUtf8Bytes)));
        Assert.Empty(registration.Declaration.ApplicabilitySlotKeys);
        Assert.Equal(
            [RepositoryTreeSlot],
            registration.Declaration.EvaluationSlotKeys);
        var finding = Assert.Single(registration.Declaration.Findings);
        Assert.Equal(
            FindingCode.Parse("protocol.extension.required-path-missing"),
            finding.Code);
        Assert.Equal(
            [QualifiedEvidenceReferenceKind.ContextProof],
            finding.AllowedPrimaryReferenceKinds);
        Assert.Empty(finding.AllowedRelatedReferenceKinds);
        Assert.Empty(registration.Declaration.FailureCodes);
        Assert.False(registration.Declaration.WaiverAllowed);
        var productionKind = Assert.Single(
            ProtectedExtensionPolicy.Export.EvaluatorKinds);
        Assert.NotSame(registration.Declaration, productionKind);
        Assert.Equal(
            registration.Declaration.EvaluatorKind,
            productionKind.EvaluatorKind);
        Assert.Equal(
            registration.Declaration.EvaluatorVersion,
            productionKind.EvaluatorVersion);
        Assert.Equal(
            registration.Declaration.Component.TypeName,
            productionKind.Component.TypeName);
        Assert.IsType<RepositoryPathRequiredExtensionEvaluator>(
            Assert.Single(ProtectedExtensionPolicy.Export.Registrations).Evaluator);
    }

    private static void AssertEvaluationMatrix(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ActivatedExtensionPolicy active,
        ExtensionRuleDeclaration declaration)
    {
        var profile = Profile(SubjectRole.Consumer);
        var present = Evaluate(
            fixture,
            active,
            profile,
            [RepositoryTreeSlot],
            CreateEvidence(fixture, ("AGENTS.md", RepositoryEntryKind.File)));
        Assert.Equal(RuleEvaluationStatus.Satisfied, present.Status);
        Assert.Empty(present.Findings);

        var mismatchEvidence = CreateEvidence(
            fixture,
            ("AGENTS.md", RepositoryEntryKind.Directory));
        var mismatch = Evaluate(
            fixture,
            active,
            profile,
            [RepositoryTreeSlot],
            mismatchEvidence);
        var mismatchFinding = Assert.Single(mismatch.Findings);
        Assert.Equal("kind-mismatch", mismatchFinding.StableStateToken);
        Assert.Equal("directory", mismatchFinding.StableStateValue);

        var unresolved = Evaluate(
            fixture,
            active,
            profile,
            [],
            CreateEvidence(fixture));
        Assert.Equal(RuleEvaluationStatus.NotEvaluated, unresolved.Status);
        Assert.False(unresolved.IsApplicabilityUnresolved);
        Assert.Equal([RepositoryTreeSlot], unresolved.UnresolvedSlotKeys);

        var poison = new PoisonInputAccess();
        var notApplicable = Assert.Single(fixture.Kernel.EvaluateExtensions(
            active,
            Profile(SubjectRole.ProtocolAuthoritySelfConsumer),
            [],
            poison,
            new Dictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>(),
            CancellationToken.None));
        Assert.Equal(RuleEvaluationStatus.NotApplicable, notApplicable.Status);
        Assert.Equal(0, poison.AccessCount);

        Assert.Throws<OperationCanceledException>(() =>
            fixture.Kernel.EvaluateExtensions(
                active,
                profile,
                [RepositoryTreeSlot],
                mismatchEvidence.Access,
                mismatchEvidence.References,
                new CancellationToken(canceled: true)));

        var entryHandle = QualifiedEvidenceHandle.Create();
        var boundaryTree = new RepositoryTreeCapability(
            Enumerable.Repeat(
                RepositoryEntryView.Create(
                    "other",
                    RepositoryEntryKind.File,
                    entryHandle),
                200_000));
        var boundaryInput = ExtensionEvaluationInput.Create(
            declaration,
            profile,
            CreateAccess(fixture, boundaryTree, entryHandle).Access);
        var boundaryIntent = ProtectedExtensionPolicy.Export.Registrations.Single()
            .Evaluator.Evaluate(boundaryInput, CancellationToken.None);
        Assert.Single(boundaryIntent.Findings);

        var overTree = new RepositoryTreeCapability(
            Enumerable.Repeat(
                RepositoryEntryView.Create(
                    "other",
                    RepositoryEntryKind.File,
                    entryHandle),
                200_001));
        var overInput = ExtensionEvaluationInput.Create(
            declaration,
            profile,
            CreateAccess(fixture, overTree, entryHandle).Access);
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            ProtectedExtensionPolicy.Export.Registrations.Single()
                .Evaluator.Evaluate(overInput, CancellationToken.None));
        var overEvidence = CreateAccess(fixture, overTree, entryHandle);
        var overflow = Assert.Throws<ProtectedPolicyIntegrityException>(() =>
            fixture.Kernel.EvaluateExtensions(
                active,
                profile,
                [RepositoryTreeSlot],
                overEvidence.Access,
                overEvidence.References,
                CancellationToken.None));
        Assert.Equal(
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded,
            overflow.Code);
    }

    private static void AssertDeclarationRejections(
        ExtensionEvaluatorRegistration registration,
        EvaluationEvidence evidence)
    {
        foreach (var parameters in new[]
        {
            new[]
            {
                ExtensionParameter.Create("kind", "unknown"),
                ExtensionParameter.Create("path", "AGENTS.md"),
            },
            new[]
            {
                ExtensionParameter.Create("kind", "file"),
                ExtensionParameter.Create("path", "../AGENTS.md"),
            },
            new[]
            {
                ExtensionParameter.Create("path", "AGENTS.md"),
            },
        })
        {
            var declaration = CreateDeclaration(parameters);
            var input = ExtensionApplicabilityInput.Create(
                declaration,
                Profile(SubjectRole.Consumer),
                evidence.Access);
            Assert.Throws<ArgumentException>(() =>
                registration.Evaluator.EvaluateApplicability(
                    input,
                    CancellationToken.None));
        }
    }

    private static ExtensionRuleDeclaration CreateDeclaration()
    {
        var declaration = CreateDeclaration(
            [
            ExtensionParameter.Create("kind", "file"),
            ExtensionParameter.Create("path", "AGENTS.md"),
            ]);
        Assert.Equal(
            "1E9E438CC697900F6CFF8448BEB15F091FD91E6BF9D9EC31560BCBBC15A2C802",
            declaration.DefinitionDigest.Value.ToUpperInvariant());
        return declaration;
    }

    private static ExtensionRuleDeclaration CreateDeclaration(
        IReadOnlyList<ExtensionParameter> parameters)
    {
        var extensionId = ExtensionId.Parse("ext:repo:required-agents");
        var revision = RuleRevision.Create(1);
        const string evaluator = "protocol.extension.repository-path-required";
        SubjectRole[] roles = [SubjectRole.Consumer];
        var surfaces = SurfaceSet.Create([SurfaceKind.Repository]);
        SnapshotKind[] snapshots = [SnapshotKind.ExactCommit];
        ProtocolOperation[] operations = [ProtocolOperation.Conformance];
        var digest = ExtensionRuleDeclaration.ComputeDefinition(
            extensionId,
            revision,
            evaluator,
            "1",
            parameters,
            roles,
            surfaces,
            snapshots,
            operations);
        return ExtensionRuleDeclaration.Create(
            extensionId,
            revision,
            evaluator,
            "1",
            parameters,
            roles,
            surfaces,
            snapshots,
            operations,
            digest);
    }

    private static ExtensionEvaluation Evaluate(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        ActivatedExtensionPolicy active,
        ExecutionProfile profile,
        IReadOnlyCollection<string> sealedSlotKeys,
        EvaluationEvidence evidence) => Assert.Single(
            fixture.Kernel.EvaluateExtensions(
                active,
                profile,
                sealedSlotKeys,
                evidence.Access,
                evidence.References,
                CancellationToken.None));

    private static ExecutionProfile Profile(SubjectRole subjectRole) =>
        ExecutionProfile.Create(
            subjectRole,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);

    private static EvaluationEvidence CreateEvidence(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        params (string Path, RepositoryEntryKind Kind)[] entries)
    {
        var handle = QualifiedEvidenceHandle.Create();
        var tree = new RepositoryTreeCapability(entries.Select(entry =>
            RepositoryEntryView.Create(entry.Path, entry.Kind, handle)));
        return CreateAccess(fixture, tree, handle);
    }

    private static EvaluationEvidence CreateAccess(
        ProjectNeutralProtectedAuthorityFixture.EmptyAuthorityFixture fixture,
        IRepositoryTree tree,
        QualifiedEvidenceHandle handle)
    {
        var targetIdentity = fixture.Manifest.SourceCommit;
        var scope = EvidenceScope.Create(
            AcquisitionTarget.Create(
                "consumer",
                "repo",
                SurfaceKind.Repository,
                SnapshotKind.ExactCommit,
                targetIdentity),
            AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit,
                targetIdentity,
                new DateTimeOffset(0, TimeSpan.Zero),
                new DateTimeOffset(1, TimeSpan.Zero)));
        var reference = new QualifiedEvidenceReference(
            QualifiedEvidenceReferenceKind.ContextProof,
            fixture.Manifest.ManifestDigest,
            fixture.Kernel.Catalog.CatalogVersion,
            RepositoryTreeSlot,
            "protocol.requirement.repository-tree",
            scope,
            fixture.ActivationPayload.ClosureEvidenceDigest,
            null,
            null,
            [],
            null,
            null);
        var capability = CapabilityHandle<IRepositoryTree>.Create(
            CapabilityTypeToken<IRepositoryTree>.Create(
                CapabilityContractIdentity.Create(
                    "protocol.capability.repository-tree",
                    "1",
                    ComponentTypeIdentity.Create(
                        "protocol.type.capability.repository-tree",
                        "1",
                        "MeAndAI.Protocol.Conformance.Abstractions",
                        typeof(IRepositoryTree).FullName!))),
            tree,
            [handle],
            SemanticResourceUsage.Create(0, 0, 0, 0),
            SemanticResourceLedger.Create([]));
        var access = RuleInputAccess.Create(
            [SlotCapabilityBinding.Create(RepositoryTreeSlot, capability)],
            new Dictionary<string, QualifiedEvidenceHandle>(StringComparer.Ordinal)
            {
                [RepositoryTreeSlot] = handle,
            },
            RejectingExpectedReferences.Instance);
        return new EvaluationEvidence(
            access,
            new Dictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            {
                [handle] = reference,
            },
            reference);
    }

    private sealed record EvaluationEvidence(
        IRuleInputAccess Access,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            References,
        QualifiedEvidenceReference Reference);

    private sealed class RejectingExpectedReferences : IExpectedReferenceLookup
    {
        internal static RejectingExpectedReferences Instance { get; } = new();

        public QualifiedEvidenceHandle Require(
            string selectorKey,
            QualifiedEvidenceHandle parent) =>
            throw new InvalidOperationException(
                "The required-path evaluator does not own expected selectors.");
    }

    private sealed class PoisonInputAccess : IRuleInputAccess
    {
        internal int AccessCount { get; private set; }

        public TCapability GetCapability<TCapability>(string slotKey)
            where TCapability : class, IEvidenceCapability
        {
            AccessCount++;
            throw new InvalidOperationException("Static mismatch touched evidence.");
        }

        public QualifiedEvidenceHandle GetContextProof(string slotKey)
        {
            AccessCount++;
            throw new InvalidOperationException("Static mismatch touched evidence.");
        }

        public QualifiedEvidenceHandle GetExpectedReference(
            string selectorKey,
            QualifiedEvidenceHandle parentHandle)
        {
            AccessCount++;
            throw new InvalidOperationException("Static mismatch touched evidence.");
        }
    }
}
