using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Conformance;
using System.Security.Cryptography;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCActivationTests
{
    private const string TestArtifact = "MeAndAI.Protocol.Conformance.Tests.dll";
    private const string SentinelDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";
    private const string ProfileName =
        "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private static readonly ReviewedAuthorityPermalink Authority =
        ReviewedAuthorityPermalink.Create(
            "https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228");

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Activates_exact_synthetic_registration_graph()
    {
        var fixture = CreateFixture();
        var proof = new ContractSliceCActivationProof(
            fixture.Manifest,
            fixture.Export);
        var manifestComponentValues = fixture.Manifest.Components
            .Select(item => item.Component)
            .ToArray();
        var missingComponents = fixture.Export.Components
            .Where(component => !manifestComponentValues.Contains(component))
            .Select(component =>
                $"{component.ComponentKey}|{component.AssemblyName}|{component.TypeName}")
            .ToArray();
        Assert.True(
            missingComponents.Length == 0,
            $"Synthetic export components missing from manifest: {string.Join(", ", missingComponents)}");

        var kernel = ConformanceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            proof,
            predecessor: null);

        Assert.Equal(1, proof.CompleteProofCalls);
        Assert.Equal(
            ["Markdig.dll", "MeAndAI.Protocol.Conformance.Abstractions.dll",
                TestArtifact, "MeAndAI.Protocol.Conformance.dll",
                "MeAndAI.Protocol.Domain.dll"],
            fixture.Manifest.ArtifactFiles.Select(item => item.FileName));
        Assert.DoesNotContain(
            fixture.Manifest.ArtifactFiles,
            item => item.FileName.Contains("Policy", StringComparison.Ordinal) ||
                item.FileName.Contains("Application", StringComparison.Ordinal));
        Assert.Equal(35, fixture.Manifest.Components.Count);
        Assert.Equal(27, fixture.Manifest.Components.Count(item =>
            string.Equals(
                item.Component.AssemblyName,
                "MeAndAI.Protocol.Conformance.Tests",
                StringComparison.Ordinal)));
        Assert.Equal(3, fixture.Export.CodecRegistrations.Count);
        Assert.Equal(2, fixture.Export.ParserRegistrations.Count);
        Assert.Equal(4, fixture.Export.IndexRegistrations.Count);
        Assert.Single(fixture.Export.DemandProjectorRegistrations);
        Assert.Equal(3, fixture.Export.SelectorRegistrations.Count);
        Assert.Equal(5, fixture.Export.EvaluatorRegistrations.Count);
        Assert.Equal(18, fixture.Export.Components.Count);

        Assert.Same(fixture.Codecs[0], fixture.Export.CodecRegistrations[0]);
        Assert.Same(fixture.Parsers[0], fixture.Export.ParserRegistrations[0]);
        Assert.Same(fixture.Indexes[0], fixture.Export.IndexRegistrations[0]);
        Assert.Same(
            fixture.Projectors[0],
            fixture.Export.DemandProjectorRegistrations[0]);
        Assert.Same(fixture.Selectors[0], fixture.Export.SelectorRegistrations[0]);
        Assert.Same(fixture.Evaluators[0], fixture.Export.EvaluatorRegistrations[0]);

        var complete = Assert.IsType<CompleteCatalogDeclaration>(
            fixture.Manifest.CompleteCatalog);
        Assert.Equal(complete.ProtocolVersion, kernel.Catalog.ProtocolVersion);
        Assert.Same(complete.CatalogVersion, kernel.Catalog.CatalogVersion);
        Assert.Same(complete.CompleteInventoryDigest, kernel.Catalog.CompleteInventoryDigest);
        Assert.Same(complete.Predecessor, kernel.Catalog.Predecessor);
        Assert.Equal(complete.BaselineProfileName, kernel.Catalog.BaselineProfileName);
        Assert.Equal(5, kernel.Catalog.Rules.Count);
        Assert.All(
            kernel.Catalog.Rules.Zip(complete.Rules),
            pair => Assert.Same(pair.Second, pair.First));
        Assert.Single(kernel.Catalog.NamedProfiles);

        var manifestComponents = fixture.Manifest.Components
            .Select(item => item.Component)
            .ToDictionary(item => item.ComponentKey, StringComparer.Ordinal);
        Assert.All(fixture.Export.Components, component =>
            Assert.Same(manifestComponents[component.ComponentKey], component));
    }

    internal static CFixture CreateFixture(
        IReadOnlyDictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>>? evaluationByRule = null)
    {
        var manifest = CreateManifest();
        var registry = manifest.SchemaRegistry;
        var complete = Assert.IsType<CompleteCatalogDeclaration>(manifest.CompleteCatalog);

        var codecs = CreateCodecs(registry);
        var parsers = CreateParsers(registry);
        var indexes = CreateIndexes(registry);
        var projectors = CreateProjectors(registry);
        var selectors = CreateSelectors(complete);
        var evaluators = CreateEvaluators(complete, evaluationByRule);
        var export = CompletePolicyPackExport.Create(
            "protocol.policy-pack.synthetic-complete",
            "1",
            complete,
            registry,
            codecs,
            parsers,
            indexes,
            projectors,
            selectors,
            evaluators);
        manifest = BindExportComponents(manifest, export);

        return new CFixture(
            manifest,
            export,
            codecs,
            parsers,
            indexes,
            projectors,
            selectors,
            evaluators);
    }

    internal static CSliceFixture CreateSliceFixture()
    {
        var fixture = CreateFixture();
        var slice = CatalogSliceDeclaration.Create(
            "protocol.catalog-slice.synthetic-applicability-plan",
            "1",
            fixture.Export.Catalog.ProtocolVersion,
            fixture.Export.Catalog.CatalogVersion,
            fixture.Export.Catalog.Rules);
        var manifest = CreateSyntheticManifest(
            CatalogAuthorityKind.QualificationSlice,
            fixture.Manifest.SourceCommit,
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.SchemaRegistry,
            fixture.Manifest.ActivationProofContract,
            fixture.Manifest.ArtifactFiles,
            fixture.Manifest.Components,
            slice,
            completeCatalog: null);
        var export = PolicyQualificationSliceExport.Create(
            "protocol.policy-pack.synthetic-applicability-plan",
            "1",
            slice,
            manifest.SchemaRegistry,
            fixture.Codecs,
            fixture.Parsers,
            fixture.Indexes,
            fixture.Projectors,
            fixture.Selectors,
            fixture.Evaluators);
        return new CSliceFixture(manifest, export);
    }

    internal static FinalizedPolicyManifest BindExportComponents(
        FinalizedPolicyManifest manifest,
        CompletePolicyPackExport export)
    {
        var exported = export.Components.ToDictionary(
            component => component.ComponentKey,
            StringComparer.Ordinal);
        var components = manifest.Components
            .Select(binding => exported.TryGetValue(
                    binding.Component.ComponentKey,
                    out var component)
                ? ComponentArtifactBinding.Create(
                    component,
                    binding.ArtifactFileName)
                : binding)
            .ToArray();
        return CreateSyntheticManifest(
            manifest.AuthorityKind,
            manifest.SourceCommit,
            manifest.ManifestDigest,
            manifest.SchemaRegistry,
            manifest.ActivationProofContract,
            manifest.ArtifactFiles,
            components,
            manifest.Slice,
            manifest.CompleteCatalog);
    }

    private static FinalizedPolicyManifest CreateManifest()
    {
        var source = ContractSliceAFullManifestGraphTests.CreateManifest();
        var registry = ReleaseSchemaRegistry.Create(
            source.SchemaRegistry.PayloadSchemas,
            source.SchemaRegistry.Parsers,
            source.SchemaRegistry.Indexes,
            source.SchemaRegistry.DemandProjectors,
            source.SchemaRegistry.AdmissionProofContracts.Select(contract =>
                AdmissionProofContractDeclaration.Create(
                    contract.ContractKey,
                    contract.ContractVersion,
                    contract.Kind,
                    ComponentTypeIdentity.Create(
                        contract.ProofComponent.ComponentKey,
                        contract.ProofComponent.ComponentVersion,
                        typeof(ContractSliceCActivationTests).Assembly
                            .GetName().Name!,
                        ReplacementType(contract.ProofComponent.ComponentKey)
                            .FullName!),
                    contract.Surfaces,
                    contract.MaterialRoles)),
            source.SchemaRegistry.CacheBudget);
        var rules = source.Slice!.Rules;
        var profile = NamedProfileDeclaration.Create(
            ProfileName,
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.Conformance,
                SnapshotKind.ExactCommit,
                SurfaceSet.Create([SurfaceKind.Provider]),
                EnforcementPhase.Audit),
            rules.Skip(2).Select(rule => rule.RuleId));
        var catalog = CompleteCatalogDeclaration.Create(
            source.Slice.ProtocolVersion,
            source.Slice.CatalogVersion,
            CatalogPredecessorBinding.Genesis(),
            ProfileName,
            rules,
            rules.Select(rule => RuleTransitionDeclaration.Added(
                rule.RuleId,
                rule.RuleRevision,
                Authority)),
            [profile]);
        var artifacts = source.ArtifactFiles
            .Where(item => item.FileName is not
                ("MeAndAI.Protocol.Application.dll" or
                 "MeAndAI.Protocol.Policy.dll"))
            .Append(ArtifactFileBinding.Create(
                TestArtifact,
                1,
                ExactSha256Digest.Parse(SentinelDigest)))
            .OrderBy(item => item.FileName, StringComparer.Ordinal)
            .ToArray();
        var testAssembly = typeof(ContractSliceCActivationTests)
            .Assembly.GetName().Name!;
        var proofComponents = registry.AdmissionProofContracts.ToDictionary(
            contract => contract.ProofComponent.ComponentKey,
            contract => contract.ProofComponent,
            StringComparer.Ordinal);
        var components = source.Components
            .Select(binding => ReplaceComponent(binding, testAssembly))
            .Select(binding => proofComponents.TryGetValue(
                    binding.Component.ComponentKey,
                    out var proofComponent)
                ? ComponentArtifactBinding.Create(
                    proofComponent,
                    binding.ArtifactFileName)
                : binding)
            .OrderBy(
                binding => binding.Component.ComponentKey,
                StringComparer.Ordinal)
            .ThenBy(
                binding => binding.Component.ComponentVersion,
                StringComparer.Ordinal)
            .ToArray();
        var digestBytes = SHA256.HashData(
            System.Text.Encoding.UTF8.GetBytes(
                string.Join('\n', components.Select(binding =>
                    $"{binding.Component.ComponentKey}|" +
                    $"{binding.Component.AssemblyName}|" +
                    binding.Component.TypeName))));
        return CreateSyntheticManifest(
            CatalogAuthorityKind.CompleteProtocolSnapshot,
            source.SourceCommit,
            ExactSha256Digest.FromHashBytes(digestBytes),
            registry,
            source.ActivationProofContract,
            artifacts,
            components,
            null,
            catalog);
    }

    internal static FinalizedPolicyManifest CreateSyntheticManifest(
        CatalogAuthorityKind authorityKind,
        string sourceCommit,
        ExactSha256Digest manifestDigest,
        ReleaseSchemaRegistry schemaRegistry,
        ActivationProofContractDeclaration activationProofContract,
        IReadOnlyList<ArtifactFileBinding> artifactFiles,
        IReadOnlyList<ComponentArtifactBinding> components,
        CatalogSliceDeclaration? slice,
        CompleteCatalogDeclaration? completeCatalog)
    {
        var constructor = Assert.Single(
            typeof(FinalizedPolicyManifest).GetConstructors(
                System.Reflection.BindingFlags.Instance |
                System.Reflection.BindingFlags.NonPublic));
        return Assert.IsType<FinalizedPolicyManifest>(constructor.Invoke(
        [
            authorityKind,
            sourceCommit,
            manifestDigest,
            schemaRegistry,
            activationProofContract,
            artifactFiles,
            components,
            slice,
            completeCatalog,
        ]));
    }

    private static ComponentArtifactBinding ReplaceComponent(
        ComponentArtifactBinding binding,
        string testAssembly)
    {
        if (binding.Component.AssemblyName is not
            ("MeAndAI.Protocol.Application" or "MeAndAI.Protocol.Policy"))
        {
            return binding;
        }

        var replacement = ReplacementType(binding.Component.ComponentKey);
        return ComponentArtifactBinding.Create(
            ComponentTypeIdentity.Create(
                binding.Component.ComponentKey,
                binding.Component.ComponentVersion,
                testAssembly,
                replacement.FullName!),
            TestArtifact);
    }

    private static Type ReplacementType(string key) => key switch
    {
        "protocol.activation-proof.release-envelope" =>
            typeof(ContractSliceCActivationProof),
        "protocol.admission-proof.failed" => typeof(CFailedAttemptProof),
        "protocol.admission-proof.no-input" => typeof(CNoInputRoutingProof),
        "protocol.admission-proof.observed" => typeof(CObservedQualificationProof),
        "protocol.codec.governed-text" => typeof(GovernedTextCodecMirror),
        "protocol.codec.repository-target-resolution" =>
            typeof(RepositoryTargetCodecMirror),
        "protocol.codec.repository-tree" => typeof(RepositoryTreeCodecMirror),
        "protocol.parser.markdown" => typeof(MarkdownParserMirror),
        "protocol.parser.repository-target-markdown" =>
            typeof(RepositoryTargetMarkdownParserMirror),
        "protocol.index.governed-reference" => typeof(GovernedReferenceIndexMirror),
        "protocol.index.protocol-record" => typeof(ProtocolRecordIndexMirror),
        "protocol.index.repository-target-resolution" =>
            typeof(RepositoryTargetIndexMirror),
        "protocol.index.repository-tree" => typeof(RepositoryTreeIndexMirror),
        "protocol.projector.repository-target-resolution-demand" =>
            typeof(RepositoryTargetProjectorMirror),
        "protocol.selector.decision-record" => typeof(DecisionRecordSelectorMirror),
        "protocol.selector.feature-readme" => typeof(FeatureReadmeSelectorMirror),
        "protocol.selector.feature-test-cases" =>
            typeof(FeatureTestCasesSelectorMirror),
        "protocol.evaluator.rule-0001" => typeof(Rule0001EvaluatorMirror),
        "protocol.evaluator.rule-0002" => typeof(Rule0002EvaluatorMirror),
        "protocol.evaluator.rule-0003" => typeof(Rule0003EvaluatorMirror),
        "protocol.evaluator.rule-0004" => typeof(Rule0004EvaluatorMirror),
        "protocol.evaluator.rule-0005" => typeof(Rule0005EvaluatorMirror),
        "protocol.type.model.source-text" => typeof(SourceTextModelMirror),
        "protocol.type.model.markdown-document" => typeof(MarkdownDocumentModelMirror),
        "protocol.type.model.repository-target-markdown-document-set" =>
            typeof(RepositoryTargetMarkdownDocumentSetModelMirror),
        "protocol.type.model.repository-target-resolution" =>
            typeof(RepositoryTargetModelMirror),
        "protocol.type.model.repository-tree" => typeof(RepositoryTreeModelMirror),
        _ => throw new InvalidOperationException(key),
    };

    private static ICodecRegistration[] CreateCodecs(ReleaseSchemaRegistry registry)
    {
        var governed = Schema(registry, "protocol.governed-text");
        var target = Schema(registry, "protocol.repository-target-resolution");
        var tree = Schema(registry, "protocol.repository-tree");
        return
        [
            CodecRegistration<SourceTextModelMirror>.Create(
                governed,
                ModelTypeToken<SourceTextModelMirror>.Create(governed.OutputModel),
                new GovernedTextCodecMirror()),
            CodecRegistration<RepositoryTargetModelMirror>.Create(
                target,
                ModelTypeToken<RepositoryTargetModelMirror>.Create(target.OutputModel),
                new RepositoryTargetCodecMirror()),
            CodecRegistration<RepositoryTreeModelMirror>.Create(
                tree,
                ModelTypeToken<RepositoryTreeModelMirror>.Create(tree.OutputModel),
                new RepositoryTreeCodecMirror()),
        ];
    }

    private static IParserRegistration[] CreateParsers(ReleaseSchemaRegistry registry)
    {
        var markdown = registry.Parsers.Single(item =>
            item.ParserKey == "protocol.parser.markdown");
        var target = registry.Parsers.Single(item =>
            item.ParserKey == "protocol.parser.repository-target-markdown");
        return
        [
            ParserRegistration<SourceTextInputMirror, MarkdownDocumentModelMirror>.Create(
                markdown,
                new ComponentInputBinderMirror<SourceTextInputMirror>(markdown.Inputs),
                ModelTypeToken<MarkdownDocumentModelMirror>.Create(markdown.OutputModel),
                new MarkdownParserMirror()),
            ParserRegistration<RepositoryTargetInputMirror,
                RepositoryTargetMarkdownDocumentSetModelMirror>.Create(
                    target,
                    new ComponentInputBinderMirror<RepositoryTargetInputMirror>(target.Inputs),
                    ModelTypeToken<RepositoryTargetMarkdownDocumentSetModelMirror>.Create(
                        target.OutputModel),
                    new RepositoryTargetMarkdownParserMirror()),
        ];
    }

    private static IIndexRegistration[] CreateIndexes(ReleaseSchemaRegistry registry) =>
    [
        CreateIndex<IGovernedReferenceIndex, GovernedReferenceIndexMirror>(
            registry,
            "protocol.index.governed-reference",
            new GovernedReferenceIndexMirror()),
        CreateIndex<IProtocolRecordIndex, ProtocolRecordIndexMirror>(
            registry,
            "protocol.index.protocol-record",
            new ProtocolRecordIndexMirror()),
        CreateIndex<IRepositoryTargetResolutionIndex, RepositoryTargetIndexMirror>(
            registry,
            "protocol.index.repository-target-resolution",
            new RepositoryTargetIndexMirror()),
        CreateIndex<IRepositoryTree, RepositoryTreeIndexMirror>(
            registry,
            "protocol.index.repository-tree",
            new RepositoryTreeIndexMirror()),
    ];

    private static IIndexRegistration CreateIndex<TCapability, TIndexer>(
        ReleaseSchemaRegistry registry,
        string key,
        TIndexer indexer)
        where TCapability : class, IEvidenceCapability
        where TIndexer : class, IContextIndexer<IndexInputMirror, TCapability>
    {
        var declaration = registry.Indexes.Single(item => item.IndexKey == key);
        return IndexRegistration<IndexInputMirror, TCapability>.Create(
            declaration,
            new ComponentInputBinderMirror<IndexInputMirror>(declaration.Inputs),
            CapabilityTypeToken<TCapability>.Create(declaration.OutputCapability),
            indexer);
    }

    private static IDemandProjectorRegistration[] CreateProjectors(
        ReleaseSchemaRegistry registry)
    {
        var declaration = Assert.Single(registry.DemandProjectors);
        return
        [
            DemandProjectorRegistration<IGovernedReferenceIndex>.Create(
                declaration,
                CapabilityTypeToken<IGovernedReferenceIndex>.Create(
                    declaration.InputCapability),
                new RepositoryTargetProjectorMirror()),
        ];
    }

    private static ISelectorRegistration[] CreateSelectors(
        CompleteCatalogDeclaration catalog)
    {
        var declarations = catalog.Rules.SelectMany(rule => rule.ExpectedSelectors)
            .DistinctBy(item => item.SelectorKey, StringComparer.Ordinal)
            .OrderBy(item => item.SelectorKey, StringComparer.Ordinal)
            .ToArray();
        return
        [
            Selector<DecisionRecordSelectorMirror>(
                declarations,
                "protocol.selector.decision-record",
                new DecisionRecordSelectorMirror()),
            Selector<FeatureReadmeSelectorMirror>(
                declarations,
                "protocol.selector.feature-readme",
                new FeatureReadmeSelectorMirror()),
            Selector<FeatureTestCasesSelectorMirror>(
                declarations,
                "protocol.selector.feature-test-cases",
                new FeatureTestCasesSelectorMirror()),
        ];
    }

    private static ISelectorRegistration Selector<TResolver>(
        IReadOnlyList<ExpectedSelectorDeclaration> declarations,
        string key,
        TResolver resolver)
        where TResolver : class, IExpectedSelectorResolver
    {
        var declaration = declarations.Single(item => item.SelectorKey == key);
        return SelectorRegistration<TResolver>.Create(
            declaration.Resolver,
            declaration.SelectorSchemaKey,
            resolver);
    }

    private static RuleEvaluatorRegistration[] CreateEvaluators(
        CompleteCatalogDeclaration catalog,
        IReadOnlyDictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>>? evaluationByRule)
    {
        if (evaluationByRule is not null &&
            (evaluationByRule.Any(item => item.Value is null) ||
             evaluationByRule.Keys.Except(
                 catalog.Rules.Select(rule => rule.RuleId.Value),
                 StringComparer.Ordinal).Any()))
        {
            throw new ArgumentException(
                "Evaluation callbacks must name exact catalog rules.",
                nameof(evaluationByRule));
        }

        return
        [
            RuleEvaluatorRegistration.Create(
                catalog.Rules[0],
                new Rule0001EvaluatorMirror(
                    evaluation: Evaluation(evaluationByRule, catalog.Rules[0]))),
            RuleEvaluatorRegistration.Create(
                catalog.Rules[1],
                new Rule0002EvaluatorMirror(
                    evaluation: Evaluation(evaluationByRule, catalog.Rules[1]))),
            RuleEvaluatorRegistration.Create(
                catalog.Rules[2],
                new Rule0003EvaluatorMirror(
                    evaluation: Evaluation(evaluationByRule, catalog.Rules[2]))),
            RuleEvaluatorRegistration.Create(
                catalog.Rules[3],
                new Rule0004EvaluatorMirror(
                    evaluation: Evaluation(evaluationByRule, catalog.Rules[3]))),
            RuleEvaluatorRegistration.Create(
                catalog.Rules[4],
                new Rule0005EvaluatorMirror(
                    evaluation: Evaluation(evaluationByRule, catalog.Rules[4]))),
        ];
    }

    private static Func<RuleEvaluationInput, EvaluationIntent>? Evaluation(
        IReadOnlyDictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>>? evaluationByRule,
        RuleDeclaration rule) =>
        evaluationByRule is not null &&
        evaluationByRule.TryGetValue(rule.RuleId.Value, out var callback)
            ? callback
            : null;

    private static PayloadSchemaDeclaration Schema(
        ReleaseSchemaRegistry registry,
        string key) => registry.PayloadSchemas.Single(item => item.SchemaKey == key);

    internal sealed record CFixture(
        FinalizedPolicyManifest Manifest,
        CompletePolicyPackExport Export,
        IReadOnlyList<ICodecRegistration> Codecs,
        IReadOnlyList<IParserRegistration> Parsers,
        IReadOnlyList<IIndexRegistration> Indexes,
        IReadOnlyList<IDemandProjectorRegistration> Projectors,
        IReadOnlyList<ISelectorRegistration> Selectors,
        IReadOnlyList<RuleEvaluatorRegistration> Evaluators);

    internal sealed record CSliceFixture(
        FinalizedPolicyManifest Manifest,
        PolicyQualificationSliceExport Export);
}

internal sealed class ContractSliceCActivationProof : IPolicyActivationProof
{
    private readonly FinalizedPolicyManifest _manifest;
    private readonly CompletePolicyPackExport _policy;
    private readonly List<IAdmissionProofCandidate> _candidates;

    internal ContractSliceCActivationProof(
        FinalizedPolicyManifest manifest,
        CompletePolicyPackExport policy,
        IEnumerable<IAdmissionProofCandidate>? candidates = null)
    {
        _manifest = manifest;
        _policy = policy;
        var values = candidates?.ToArray() ?? [];
        if (values.Any(candidate => candidate is null) ||
            values.Distinct(ReferenceEqualityComparer.Instance).Count() !=
                values.Length)
        {
            throw new ArgumentException(
                "Admission candidates must be distinct non-null references.",
                nameof(candidates));
        }

        _candidates = [.. values];
    }

    public string ContractKey => _manifest.ActivationProofContract.ContractKey;

    public string ContractVersion => _manifest.ActivationProofContract.ContractVersion;

    public ExactSha256Digest ManifestDigest => _manifest.ManifestDigest;

    public IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts =>
        _manifest.ArtifactFiles;

    internal int CompleteProofCalls { get; private set; }

    public bool Proves(PolicyQualificationSliceExport policy) => false;

    public bool Proves(CompletePolicyPackExport policy)
    {
        CompleteProofCalls++;
        return ReferenceEquals(policy, _policy);
    }

    public bool Proves(IAdmissionProofCandidate candidate) =>
        candidate is not null &&
        _candidates.Any(item => ReferenceEquals(item, candidate));

    internal void Authorize(IEnumerable<IAdmissionProofCandidate> candidates)
    {
        ArgumentNullException.ThrowIfNull(candidates);
        var values = candidates.ToArray();
        if (values.Any(candidate => candidate is null) ||
            values.Concat(_candidates)
                .Distinct(ReferenceEqualityComparer.Instance).Count() !=
                values.Length + _candidates.Count)
        {
            throw new ArgumentException(
                "Admission candidates must be new distinct non-null references.",
                nameof(candidates));
        }

        _candidates.AddRange(values);
    }
}

internal sealed partial class SourceTextModelMirror : IProtocolSemanticModel;
internal sealed partial class GovernedTextCodecMirror :
    ICanonicalPayloadCodec<SourceTextModelMirror>;
internal sealed partial class MarkdownDocumentModelMirror : IProtocolSemanticModel;
internal sealed partial class RepositoryTargetMarkdownDocumentSetModelMirror :
    IProtocolSemanticModel;

internal sealed partial class SourceTextInputMirror : IComponentInput;
internal sealed partial class RepositoryTargetInputMirror : IComponentInput;
internal sealed partial class IndexInputMirror : IComponentInput;
internal sealed partial class ComponentInputBinderMirror<TInput> :
    IComponentInputBinder<TInput>
    where TInput : class, IComponentInput
{
    private readonly IReadOnlyList<ComponentInputDeclaration> _inputs;

    internal ComponentInputBinderMirror()
        : this(Array.Empty<ComponentInputDeclaration>())
    {
    }

    internal ComponentInputBinderMirror(IEnumerable<ComponentInputDeclaration> inputs)
    {
        ArgumentNullException.ThrowIfNull(inputs);
        _inputs = Array.AsReadOnly(inputs.ToArray());
    }

    public IReadOnlyList<ComponentInputDeclaration> Inputs => _inputs;

    public TInput Bind(TypedInputReader reader)
    {
        ArgumentNullException.ThrowIfNull(reader);
        return Activator.CreateInstance<TInput>();
    }
}

internal sealed partial class MarkdownParserMirror :
    ISemanticModelParser<SourceTextInputMirror, MarkdownDocumentModelMirror>;
internal sealed partial class RepositoryTargetMarkdownParserMirror :
    ISemanticModelParser<RepositoryTargetInputMirror,
        RepositoryTargetMarkdownDocumentSetModelMirror>;

internal sealed partial class GovernedReferenceIndexMirror :
    IContextIndexer<IndexInputMirror, IGovernedReferenceIndex>;
internal sealed partial class ProtocolRecordIndexMirror :
    IContextIndexer<IndexInputMirror, IProtocolRecordIndex>;
internal sealed partial class RepositoryTargetIndexMirror :
    IContextIndexer<IndexInputMirror, IRepositoryTargetResolutionIndex>;
internal sealed partial class RepositoryTreeIndexMirror :
    IContextIndexer<IndexInputMirror, IRepositoryTree>;

internal sealed partial class RepositoryTargetProjectorMirror :
    IAcquisitionDemandProjector<IGovernedReferenceIndex>;

internal sealed partial class DecisionRecordSelectorMirror : IExpectedSelectorResolver;
internal sealed partial class FeatureReadmeSelectorMirror : IExpectedSelectorResolver;
internal sealed partial class FeatureTestCasesSelectorMirror : IExpectedSelectorResolver;

internal abstract class RuleEvaluatorMirror : IRuleEvaluator
{
    private readonly Func<RuleApplicabilityInput, ApplicabilityIntent> _applicability;
    private readonly Func<RuleEvaluationInput, EvaluationIntent> _evaluation;

    protected RuleEvaluatorMirror(
        Func<RuleApplicabilityInput, ApplicabilityIntent>? applicability = null,
        Func<RuleEvaluationInput, EvaluationIntent>? evaluation = null)
    {
        _applicability = applicability ??
            (_ => ApplicabilityIntent.Applicable([]));
        _evaluation = evaluation ?? (_ => EvaluationIntent.Create([], []));
    }

    public ApplicabilityIntent EvaluateApplicability(
        RuleApplicabilityInput input,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return _applicability(input);
    }

    public EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return _evaluation(input);
    }
}

internal sealed class Rule0001EvaluatorMirror : RuleEvaluatorMirror
{
    internal Rule0001EvaluatorMirror(
        Func<RuleApplicabilityInput, ApplicabilityIntent>? applicability = null,
        Func<RuleEvaluationInput, EvaluationIntent>? evaluation = null)
        : base(applicability, evaluation) { }
}

internal sealed class Rule0002EvaluatorMirror : RuleEvaluatorMirror
{
    internal Rule0002EvaluatorMirror(
        Func<RuleApplicabilityInput, ApplicabilityIntent>? applicability = null,
        Func<RuleEvaluationInput, EvaluationIntent>? evaluation = null)
        : base(applicability, evaluation) { }
}

internal sealed class Rule0003EvaluatorMirror : RuleEvaluatorMirror
{
    internal Rule0003EvaluatorMirror(
        Func<RuleApplicabilityInput, ApplicabilityIntent>? applicability = null,
        Func<RuleEvaluationInput, EvaluationIntent>? evaluation = null)
        : base(applicability, evaluation) { }
}

internal sealed class Rule0004EvaluatorMirror : RuleEvaluatorMirror
{
    internal Rule0004EvaluatorMirror(
        Func<RuleApplicabilityInput, ApplicabilityIntent>? applicability = null,
        Func<RuleEvaluationInput, EvaluationIntent>? evaluation = null)
        : base(applicability, evaluation) { }
}

internal sealed class Rule0005EvaluatorMirror : RuleEvaluatorMirror
{
    internal Rule0005EvaluatorMirror(
        Func<RuleApplicabilityInput, ApplicabilityIntent>? applicability = null,
        Func<RuleEvaluationInput, EvaluationIntent>? evaluation = null)
        : base(applicability, evaluation) { }
}
