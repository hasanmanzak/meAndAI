using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCRegistrationTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0002";

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Rejects_registration_mismatch_without_kernel_activation()
    {
        var fixture = CreateFixture();
        AssertValidDeclarationClosure(fixture);
        var valid = CatalogSliceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            new ContractSliceCQualificationProof(fixture.Manifest, fixture.Export));
        if (valid is null)
        {
            Assert.Fail(Marker);
        }

        Assert.NotNull(valid);
        AssertFamilyShape(fixture);

        AssertMissingAndDuplicate(fixture);
        AssertOrdering(fixture);
        AssertForeignDeclarations(fixture);
        AssertWrongRuntimeTypes(fixture);

        var mismatched = Export(
            fixture,
            codecs: fixture.Codecs.Skip(1).ToArray());
        AssertIntegrity(
            CatalogIntegrityCode.ActivationProofInvalid,
            fixture.Manifest,
            mismatched,
            new ContractSliceCQualificationProof(
                fixture.Manifest,
                mismatched,
                contractVersion: "2"));
    }

    private static QualificationFixture CreateFixture()
    {
        var surface = ContractSliceCActivationTests.CreateFixture();
        var complete = surface.Export.Catalog;
        var slice = CatalogSliceDeclaration.Create(
            "protocol.catalog-slice.synthetic-qualification",
            "1",
            complete.ProtocolVersion,
            complete.CatalogVersion,
            complete.Rules);
        var manifest = ContractSliceCActivationTests.CreateSyntheticManifest(
            CatalogAuthorityKind.QualificationSlice,
            surface.Manifest.SourceCommit,
            surface.Manifest.ManifestDigest,
            surface.Manifest.SchemaRegistry,
            surface.Manifest.ActivationProofContract,
            surface.Manifest.ArtifactFiles,
            surface.Manifest.Components,
            slice,
            null);
        var fixture = new QualificationFixture(
            manifest,
            surface.Codecs,
            surface.Parsers,
            surface.Indexes,
            surface.Projectors,
            surface.Selectors,
            surface.Evaluators);
        return fixture with { Export = Export(fixture) };
    }

    private static PolicyQualificationSliceExport Export(
        QualificationFixture fixture,
        IReadOnlyList<ICodecRegistration>? codecs = null,
        IReadOnlyList<IParserRegistration>? parsers = null,
        IReadOnlyList<IIndexRegistration>? indexes = null,
        IReadOnlyList<IDemandProjectorRegistration>? projectors = null,
        IReadOnlyList<ISelectorRegistration>? selectors = null,
        IReadOnlyList<RuleEvaluatorRegistration>? evaluators = null) =>
        PolicyQualificationSliceExport.Create(
            "protocol.policy-pack.synthetic-qualification",
            "1",
            fixture.Manifest.Slice!,
            fixture.Manifest.SchemaRegistry,
            codecs ?? fixture.Codecs,
            parsers ?? fixture.Parsers,
            indexes ?? fixture.Indexes,
            projectors ?? fixture.Projectors,
            selectors ?? fixture.Selectors,
            evaluators ?? fixture.Evaluators);

    private static void AssertFamilyShape(QualificationFixture fixture)
    {
        Assert.Equal(3, fixture.Codecs.Count);
        Assert.Equal(2, fixture.Parsers.Count);
        Assert.Equal(4, fixture.Indexes.Count);
        Assert.Single(fixture.Projectors);
        Assert.Equal(3, fixture.Selectors.Count);
        Assert.Equal(5, fixture.Evaluators.Count);
        Assert.Equal(18, fixture.Export.Components.Count);
    }

    private static void AssertValidDeclarationClosure(QualificationFixture fixture)
    {
        Assert.All(fixture.Codecs.Zip(fixture.Manifest.SchemaRegistry.PayloadSchemas),
            pair => Assert.Same(pair.Second, pair.First.Declaration));
        Assert.All(fixture.Parsers.Zip(fixture.Manifest.SchemaRegistry.Parsers),
            pair => Assert.Same(pair.Second, pair.First.Declaration));
        Assert.All(fixture.Indexes.Zip(fixture.Manifest.SchemaRegistry.Indexes),
            pair => Assert.Same(pair.Second, pair.First.Declaration));
        Assert.All(fixture.Projectors.Zip(fixture.Manifest.SchemaRegistry.DemandProjectors),
            pair => Assert.Same(pair.Second, pair.First.Declaration));

        var selectors = fixture.Manifest.Slice!.Rules
            .SelectMany(rule => rule.ExpectedSelectors)
            .DistinctBy(item => item.SelectorKey, StringComparer.Ordinal)
            .OrderBy(item => item.SelectorKey, StringComparer.Ordinal)
            .ToArray();
        Assert.All(fixture.Selectors.Zip(selectors), pair =>
            Assert.Same(pair.Second.Resolver, pair.First.Component));
        Assert.All(fixture.Evaluators.Zip(fixture.Manifest.Slice.Rules), pair =>
            Assert.Same(pair.Second, pair.First.Declaration));
        Assert.All(fixture.Export.Components, component =>
            Assert.Single(fixture.Manifest.Components, binding =>
                ComponentEquals(binding.Component, component)));
    }

    private static bool ComponentEquals(
        ComponentTypeIdentity left,
        ComponentTypeIdentity right) =>
        left.ComponentKey == right.ComponentKey &&
        left.ComponentVersion == right.ComponentVersion &&
        left.AssemblyName == right.AssemblyName &&
        left.TypeName == right.TypeName;

    private static void AssertMissingAndDuplicate(QualificationFixture fixture)
    {
        AssertMismatch(fixture, Export(fixture, codecs: Missing(fixture.Codecs)));
        AssertMismatch(fixture, Export(fixture, codecs: Duplicate(fixture.Codecs)));
        AssertMismatch(fixture, Export(fixture, parsers: Missing(fixture.Parsers)));
        AssertMismatch(fixture, Export(fixture, parsers: Duplicate(fixture.Parsers)));
        AssertMismatch(fixture, Export(fixture, indexes: Missing(fixture.Indexes)));
        AssertMismatch(fixture, Export(fixture, indexes: Duplicate(fixture.Indexes)));
        AssertMismatch(fixture, Export(fixture, projectors: Missing(fixture.Projectors)));
        AssertMismatch(fixture, Export(fixture, projectors: Duplicate(fixture.Projectors)));
        AssertMismatch(fixture, Export(fixture, selectors: Missing(fixture.Selectors)));
        AssertMismatch(fixture, Export(fixture, selectors: Duplicate(fixture.Selectors)));
        AssertMismatch(fixture, Export(fixture, evaluators: Missing(fixture.Evaluators)));
        AssertMismatch(fixture, Export(fixture, evaluators: Duplicate(fixture.Evaluators)));
    }

    private static void AssertOrdering(QualificationFixture fixture)
    {
        AssertOrderEdges(fixture, fixture.Codecs, values => Export(fixture, codecs: values));
        AssertOrderEdges(fixture, fixture.Parsers, values => Export(fixture, parsers: values));
        AssertOrderEdges(fixture, fixture.Indexes, values => Export(fixture, indexes: values));
        AssertOrderEdges(fixture, fixture.Selectors, values => Export(fixture, selectors: values));
        AssertOrderEdges(fixture, fixture.Evaluators, values => Export(fixture, evaluators: values));
    }

    private static void AssertForeignDeclarations(QualificationFixture fixture)
    {
        var foreign = CreateFixture();
        AssertMismatch(fixture, Export(fixture, codecs: ReplaceFirst(fixture.Codecs, foreign.Codecs[0])));
        AssertMismatch(fixture, Export(fixture, parsers: ReplaceFirst(fixture.Parsers, foreign.Parsers[0])));
        AssertMismatch(fixture, Export(fixture, indexes: ReplaceFirst(fixture.Indexes, foreign.Indexes[0])));
        AssertMismatch(fixture, Export(fixture, projectors: ReplaceFirst(fixture.Projectors, foreign.Projectors[0])));
        AssertMismatch(fixture, Export(fixture, selectors: ReplaceFirst(fixture.Selectors, foreign.Selectors[0])));
        AssertMismatch(fixture, Export(fixture, evaluators: ReplaceFirst(fixture.Evaluators, foreign.Evaluators[0])));
    }

    private static void AssertWrongRuntimeTypes(QualificationFixture fixture)
    {
        var codec = fixture.Codecs[0].Declaration;
        var wrongCodec = CodecRegistration<RepositoryTargetModelMirror>.Create(
            codec,
            ModelTypeToken<RepositoryTargetModelMirror>.Create(codec.OutputModel),
            new WrongGovernedCodecMirror());
        AssertMismatch(fixture, Export(fixture, codecs: ReplaceFirst(fixture.Codecs, wrongCodec)));

        var parser = fixture.Parsers[0].Declaration;
        var wrongParser = ParserRegistration<RepositoryTargetInputMirror,
            RepositoryTargetModelMirror>.Create(
                parser,
                new ComponentInputBinderMirror<RepositoryTargetInputMirror>(),
                ModelTypeToken<RepositoryTargetModelMirror>.Create(parser.OutputModel),
                new WrongParserMirror());
        AssertMismatch(fixture, Export(fixture, parsers: ReplaceFirst(fixture.Parsers, wrongParser)));

        var index = fixture.Indexes[0].Declaration;
        var wrongIndex = IndexRegistration<IndexInputMirror, IProtocolRecordIndex>.Create(
            index,
            new ComponentInputBinderMirror<IndexInputMirror>(),
            CapabilityTypeToken<IProtocolRecordIndex>.Create(index.OutputCapability),
            new WrongIndexMirror());
        AssertMismatch(fixture, Export(fixture, indexes: ReplaceFirst(fixture.Indexes, wrongIndex)));

        var projector = fixture.Projectors[0].Declaration;
        var wrongProjector = DemandProjectorRegistration<IRepositoryTree>.Create(
            projector,
            CapabilityTypeToken<IRepositoryTree>.Create(projector.InputCapability),
            new WrongProjectorMirror());
        AssertMismatch(fixture, Export(fixture, projectors: ReplaceFirst(fixture.Projectors, wrongProjector)));

        var selector = fixture.Selectors[0];
        var wrongSelector = SelectorRegistration<FeatureReadmeSelectorMirror>.Create(
            selector.Component,
            selector.SelectorSchemaKey,
            new FeatureReadmeSelectorMirror());
        AssertMismatch(fixture, Export(fixture, selectors: ReplaceFirst(fixture.Selectors, wrongSelector)));

        var wrongEvaluator = RuleEvaluatorRegistration.Create(
            fixture.Evaluators[0].Declaration,
            new Rule0002EvaluatorMirror());
        AssertMismatch(fixture, Export(fixture, evaluators: ReplaceFirst(fixture.Evaluators, wrongEvaluator)));
    }

    private static void AssertOrderEdges<T>(
        QualificationFixture fixture,
        IReadOnlyList<T> values,
        Func<IReadOnlyList<T>, PolicyQualificationSliceExport> create)
    {
        AssertMismatch(fixture, create(Swap(values, 0, 1)));
        if (values.Count > 2)
        {
            AssertMismatch(fixture, create(Swap(values, values.Count - 2, values.Count - 1)));
        }
    }

    private static void AssertMismatch(
        QualificationFixture fixture,
        PolicyQualificationSliceExport export) =>
        AssertIntegrity(
            CatalogIntegrityCode.RegistrationMismatch,
            fixture.Manifest,
            export,
            new ContractSliceCQualificationProof(fixture.Manifest, export));

    private static void AssertIntegrity(
        CatalogIntegrityCode expected,
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport export,
        IPolicyActivationProof proof)
    {
        CatalogSliceKernel? leaked = null;
        var exception = Assert.Throws<CatalogIntegrityException>(() =>
            leaked = CatalogSliceKernel.Activate(manifest, export, proof));
        Assert.Same(expected, exception.Code);
        Assert.Null(leaked);
    }

    private static IReadOnlyList<T> Missing<T>(IReadOnlyList<T> values) =>
        values.Skip(1).ToArray();

    private static IReadOnlyList<T> Duplicate<T>(IReadOnlyList<T> values) =>
        values.Append(values[0]).ToArray();

    private static IReadOnlyList<T> ReplaceFirst<T>(IReadOnlyList<T> values, T replacement) =>
        values.Select((value, index) => index == 0 ? replacement : value).ToArray();

    private static IReadOnlyList<T> Swap<T>(IReadOnlyList<T> values, int left, int right)
    {
        var result = values.ToArray();
        (result[left], result[right]) = (result[right], result[left]);
        return result;
    }

    private sealed record QualificationFixture(
        FinalizedPolicyManifest Manifest,
        IReadOnlyList<ICodecRegistration> Codecs,
        IReadOnlyList<IParserRegistration> Parsers,
        IReadOnlyList<IIndexRegistration> Indexes,
        IReadOnlyList<IDemandProjectorRegistration> Projectors,
        IReadOnlyList<ISelectorRegistration> Selectors,
        IReadOnlyList<RuleEvaluatorRegistration> Evaluators)
    {
        internal PolicyQualificationSliceExport Export { get; init; } = null!;
    }
}

internal sealed class ContractSliceCQualificationProof : IPolicyActivationProof
{
    private readonly FinalizedPolicyManifest _manifest;
    private readonly PolicyQualificationSliceExport _policy;
    private readonly string _contractVersion;

    internal ContractSliceCQualificationProof(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        string? contractVersion = null)
    {
        _manifest = manifest;
        _policy = policy;
        _contractVersion = contractVersion ?? manifest.ActivationProofContract.ContractVersion;
    }

    public string ContractKey => _manifest.ActivationProofContract.ContractKey;
    public string ContractVersion => _contractVersion;
    public ExactSha256Digest ManifestDigest => _manifest.ManifestDigest;
    public IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts => _manifest.ArtifactFiles;
    public bool Proves(PolicyQualificationSliceExport policy) => ReferenceEquals(policy, _policy);
    public bool Proves(CompletePolicyPackExport policy) => false;
    public bool Proves(IAdmissionProofCandidate candidate) => false;
}

internal sealed class WrongGovernedCodecMirror :
    ICanonicalPayloadCodec<RepositoryTargetModelMirror>;

internal sealed class WrongParserMirror :
    ISemanticModelParser<RepositoryTargetInputMirror, RepositoryTargetModelMirror>;

internal sealed class WrongIndexMirror :
    IContextIndexer<IndexInputMirror, IProtocolRecordIndex>;

internal sealed class WrongProjectorMirror :
    IAcquisitionDemandProjector<IRepositoryTree>;
