using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBActivationTests
{
    private const string TestArtifact = "MeAndAI.Protocol.Conformance.Tests.dll";
    private const string SentinelDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";

    [Fact]
    [Trait("ContractSlice", "B")]
    public void Activates_exact_codec_mirror()
    {
        var manifest = CreateManifest();
        var governed = RequireSchema(manifest, "protocol.governed-text");
        var target = RequireSchema(
            manifest,
            "protocol.repository-target-resolution");
        var tree = RequireSchema(manifest, "protocol.repository-tree");

        var governedCodec = new GovernedTextCodecMirror();
        var targetCodec = new RepositoryTargetCodecMirror();
        var treeCodec = new RepositoryTreeCodecMirror();
        var governedRegistration = CodecRegistration<GovernedTextModelMirror>.Create(
            governed,
            ModelTypeToken<GovernedTextModelMirror>.Create(governed.OutputModel),
            governedCodec);
        var targetRegistration =
            CodecRegistration<RepositoryTargetModelMirror>.Create(
                target,
                ModelTypeToken<RepositoryTargetModelMirror>.Create(
                    target.OutputModel),
                targetCodec);
        var treeRegistration = CodecRegistration<RepositoryTreeModelMirror>.Create(
            tree,
            ModelTypeToken<RepositoryTreeModelMirror>.Create(tree.OutputModel),
            treeCodec);
        var proof = new ContractSliceBActivationProof(
            manifest,
            governedRegistration,
            targetRegistration,
            treeRegistration,
            governedCodec,
            targetCodec,
            treeCodec);

        var harness = ContractSliceBAdmissionHarness.Activate(
            manifest,
            [treeRegistration, targetRegistration, governedRegistration],
            proof);

        Assert.NotNull(harness);
        Assert.Equal(1, proof.CodecMirrorProofCalls);
        Assert.Equal(
            [governedRegistration, targetRegistration, treeRegistration],
            proof.ObservedRegistrations);

        var wrongToken =
            ModelTypeToken<RepositoryTreeModelMirror>.Create(governed.OutputModel);
        Assert.Throws<ArgumentException>(() =>
            CodecRegistration<RepositoryTreeModelMirror>.Create(
                tree,
                wrongToken,
                treeCodec));

        AssertIntegrity(
            CatalogIntegrityCode.RegistrationMismatch,
            () => ContractSliceBAdmissionHarness.Activate(
                manifest,
                [governedRegistration, targetRegistration],
                proof));
        AssertIntegrity(
            CatalogIntegrityCode.RegistrationMismatch,
            () => ContractSliceBAdmissionHarness.Activate(
                manifest,
                [governedRegistration, targetRegistration, treeRegistration,
                    treeRegistration],
                proof));

        var rejectingProof = new ContractSliceBActivationProof(
            manifest,
            governedRegistration,
            targetRegistration,
            treeRegistration,
            governedCodec,
            targetCodec,
            treeCodec,
            provesMirror: false);
        AssertIntegrity(
            CatalogIntegrityCode.ActivationProofInvalid,
            () => ContractSliceBAdmissionHarness.Activate(
                manifest,
                [governedRegistration, targetRegistration, treeRegistration],
                rejectingProof));
        AssertIntegrity(
            CatalogIntegrityCode.ActivationProofInvalid,
            () => ContractSliceBAdmissionHarness.Activate(
                manifest,
                [governedRegistration, targetRegistration, treeRegistration],
                new ForeignActivationProof(manifest)));
    }

    internal static FinalizedPolicyManifest CreateManifest()
    {
        var source = ContractSliceAFullManifestGraphTests.CreateManifest();
        var proofType = typeof(ContractSliceBActivationProof);
        var proofComponent = ComponentTypeIdentity.Create(
            source.ActivationProofContract.ProofComponent.ComponentKey,
            source.ActivationProofContract.ProofComponent.ComponentVersion,
            proofType.Assembly.GetName().Name!,
            proofType.FullName!);
        var activationProofContract = ActivationProofContractDeclaration.Create(
            source.ActivationProofContract.ContractKey,
            source.ActivationProofContract.ContractVersion,
            proofComponent);
        var artifacts = source.ArtifactFiles
            .Append(ArtifactFileBinding.Create(
                TestArtifact,
                1,
                ExactSha256Digest.Parse(SentinelDigest)))
            .OrderBy(artifact => artifact.FileName, StringComparer.Ordinal)
            .ToArray();
        var components = source.Components
            .Where(binding => !string.Equals(
                binding.Component.ComponentKey,
                proofComponent.ComponentKey,
                StringComparison.Ordinal))
            .Append(ComponentArtifactBinding.Create(proofComponent, TestArtifact))
            .OrderBy(
                binding => binding.Component.ComponentKey,
                StringComparer.Ordinal)
            .ThenBy(
                binding => binding.Component.ComponentVersion,
                StringComparer.Ordinal)
            .ToArray();
        var bytes = CanonicalManifestWriter.Write(new ParsedCanonicalManifest(
            source.AuthorityKind,
            source.SourceCommit,
            source.SchemaRegistry,
            activationProofContract,
            artifacts,
            components,
            source.Slice,
            source.CompleteCatalog));

        return FinalizedPolicyManifest.ParseCanonical(bytes);
    }

    private static PayloadSchemaDeclaration RequireSchema(
        FinalizedPolicyManifest manifest,
        string key) => Assert.Single(
            manifest.SchemaRegistry.PayloadSchemas,
            schema => string.Equals(
                schema.SchemaKey,
                key,
                StringComparison.Ordinal));

    private static void AssertIntegrity(
        CatalogIntegrityCode expected,
        Action action)
    {
        var exception = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Same(expected, exception.Code);
    }
}

internal sealed partial class GovernedTextModelMirror : IProtocolSemanticModel;

internal sealed partial class RepositoryTargetModelMirror : IProtocolSemanticModel;

internal sealed partial class RepositoryTreeModelMirror : IProtocolSemanticModel;

internal sealed partial class GovernedTextCodecMirror :
    ICanonicalPayloadCodec<GovernedTextModelMirror>;

internal sealed partial class RepositoryTargetCodecMirror :
    ICanonicalPayloadCodec<RepositoryTargetModelMirror>;

internal sealed partial class RepositoryTreeCodecMirror :
    ICanonicalPayloadCodec<RepositoryTreeModelMirror>;

internal sealed class ContractSliceBActivationProof :
    IPolicyActivationProof,
    IContractSliceBActivationProofState
{
    private readonly FinalizedPolicyManifest _manifest;
    private readonly CodecRegistration<GovernedTextModelMirror> _governed;
    private readonly CodecRegistration<RepositoryTargetModelMirror> _target;
    private readonly CodecRegistration<RepositoryTreeModelMirror> _tree;
    private readonly GovernedTextCodecMirror _governedCodec;
    private readonly RepositoryTargetCodecMirror _targetCodec;
    private readonly RepositoryTreeCodecMirror _treeCodec;
    private readonly bool _provesMirror;
    private readonly IReadOnlyList<IAdmissionProofCandidate>
        _admissionCandidates;

    internal ContractSliceBActivationProof(
        FinalizedPolicyManifest manifest,
        CodecRegistration<GovernedTextModelMirror> governed,
        CodecRegistration<RepositoryTargetModelMirror> target,
        CodecRegistration<RepositoryTreeModelMirror> tree,
        GovernedTextCodecMirror governedCodec,
        RepositoryTargetCodecMirror targetCodec,
        RepositoryTreeCodecMirror treeCodec,
        bool provesMirror = true,
        IEnumerable<IAdmissionProofCandidate>? admissionCandidates = null)
    {
        _manifest = manifest;
        _governed = governed;
        _target = target;
        _tree = tree;
        _governedCodec = governedCodec;
        _targetCodec = targetCodec;
        _treeCodec = treeCodec;
        _provesMirror = provesMirror;
        var candidates = admissionCandidates?.ToArray() ?? [];
        if (candidates.Any(candidate => candidate is null) ||
            candidates.Distinct(ReferenceEqualityComparer.Instance).Count() !=
                candidates.Length)
        {
            throw new ArgumentException(
                "Admission candidates must be non-null distinct references.",
                nameof(admissionCandidates));
        }

        _admissionCandidates = Array.AsReadOnly(candidates);
    }

    public string ContractKey => _manifest.ActivationProofContract.ContractKey;

    public string ContractVersion =>
        _manifest.ActivationProofContract.ContractVersion;

    public ExactSha256Digest ManifestDigest => _manifest.ManifestDigest;

    public IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts =>
        _manifest.ArtifactFiles;

    internal int CodecMirrorProofCalls { get; private set; }

    internal IReadOnlyList<ICodecRegistration> ObservedRegistrations
    { get; private set; } = [];

    public bool Proves(PolicyQualificationSliceExport policy) => false;

    public bool Proves(CompletePolicyPackExport policy) => false;

    public bool Proves(IAdmissionProofCandidate candidate) =>
        candidate is not null &&
        _admissionCandidates.Any(item => ReferenceEquals(item, candidate));

    public bool ProvesCodecMirror(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<ICodecRegistration> codecRegistrations)
    {
        CodecMirrorProofCalls++;
        ObservedRegistrations = codecRegistrations.ToArray();
        if (!_provesMirror ||
            !ReferenceEquals(manifest, _manifest) ||
            codecRegistrations.Count != 3)
        {
            return false;
        }

        var visitor = new CodecMirrorVisitor(
            _governed,
            _target,
            _tree,
            _governedCodec,
            _targetCodec,
            _treeCodec);
        return codecRegistrations.All(registration => registration.Accept(visitor));
    }

    private sealed class CodecMirrorVisitor : ICodecRegistrationVisitor<bool>
    {
        private readonly CodecRegistration<GovernedTextModelMirror> _governed;
        private readonly CodecRegistration<RepositoryTargetModelMirror> _target;
        private readonly CodecRegistration<RepositoryTreeModelMirror> _tree;
        private readonly GovernedTextCodecMirror _governedCodec;
        private readonly RepositoryTargetCodecMirror _targetCodec;
        private readonly RepositoryTreeCodecMirror _treeCodec;

        internal CodecMirrorVisitor(
            CodecRegistration<GovernedTextModelMirror> governed,
            CodecRegistration<RepositoryTargetModelMirror> target,
            CodecRegistration<RepositoryTreeModelMirror> tree,
            GovernedTextCodecMirror governedCodec,
            RepositoryTargetCodecMirror targetCodec,
            RepositoryTreeCodecMirror treeCodec)
        {
            _governed = governed;
            _target = target;
            _tree = tree;
            _governedCodec = governedCodec;
            _targetCodec = targetCodec;
            _treeCodec = treeCodec;
        }

        public bool Visit<TModel>(CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel
        {
            var exactRegistration = registration.Declaration.SchemaKey switch
            {
                "protocol.governed-text" =>
                    typeof(TModel) == typeof(GovernedTextModelMirror) &&
                    ReferenceEquals(registration, _governed) &&
                    ReferenceEquals(registration.Codec, _governedCodec),
                "protocol.repository-target-resolution" =>
                    typeof(TModel) == typeof(RepositoryTargetModelMirror) &&
                    ReferenceEquals(registration, _target) &&
                    ReferenceEquals(registration.Codec, _targetCodec),
                "protocol.repository-tree" =>
                    typeof(TModel) == typeof(RepositoryTreeModelMirror) &&
                    ReferenceEquals(registration, _tree) &&
                    ReferenceEquals(registration.Codec, _treeCodec),
                _ => false,
            };
            return exactRegistration && ReferenceEquals(
                registration.OutputModel.Contract,
                registration.Declaration.OutputModel);
        }
    }
}

internal sealed class ForeignActivationProof : IPolicyActivationProof
{
    private readonly FinalizedPolicyManifest _manifest;

    internal ForeignActivationProof(FinalizedPolicyManifest manifest)
    {
        _manifest = manifest;
    }

    public string ContractKey => _manifest.ActivationProofContract.ContractKey;

    public string ContractVersion =>
        _manifest.ActivationProofContract.ContractVersion;

    public ExactSha256Digest ManifestDigest => _manifest.ManifestDigest;

    public IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts =>
        _manifest.ArtifactFiles;

    public bool Proves(PolicyQualificationSliceExport policy) => false;

    public bool Proves(CompletePolicyPackExport policy) => false;

    public bool Proves(IAdmissionProofCandidate candidate) => false;
}
