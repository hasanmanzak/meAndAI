using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBAdmissionProofTests
{
    private const string Marker = "TEST-0210-B-BEHAVIOR-RED-0011";
    private const string ApplicationArtifact =
        "MeAndAI.Protocol.Application.dll";
    private const string TestArtifact =
        "MeAndAI.Protocol.Conformance.Tests.dll";
    private const string Commit =
        "0123456789abcdef0123456789abcdef01234567";
    private static readonly DateTimeOffset Started =
        new(2026, 8, 10, 0, 0, 0, TimeSpan.Zero);
    private static readonly DateTimeOffset Completed = Started.AddMinutes(1);

    [Fact]
    [Trait("ContractSlice", "B")]
    public void Admits_exact_observed_failed_and_no_input_proofs()
    {
        var aggregate = ExecuteContract();
        if (aggregate is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal(3, aggregate.Receipts.Count);
        Assert.Equal(
            [
                "protocol.slot.provider-governed-text",
                "protocol.slot.repository-target-resolution",
                "protocol.slot.repository-tree",
            ],
            aggregate.Receipts.Select(receipt => receipt.SlotKey));
        Assert.Equal((1, 1, 1), aggregate.LeafCounts);
        Assert.True(aggregate.LifecycleClosed);
    }

    internal static AdmissionAggregateMirror? ExecuteContract()
    {
        var manifest = CreateAdmissionManifest();
        var instructions = CreateInstructions(manifest);
        var candidates = CreateCandidates(manifest, instructions);
        AssertCanonicalFrames(manifest, instructions, candidates);
        AssertDefensiveCopies(manifest, instructions, candidates);
        AssertLifecycle();

        var proof = CreateActivationProof(manifest, candidates.All);
        var coordinator = new ContractSliceBAdmissionCoordinatorMirror();
        var receipts = coordinator.Admit(
            manifest,
            proof,
            instructions.All.Reverse().ToArray(),
            AcquisitionProofSet.Create(
                SingleUse(candidates.Observed),
                SingleUse(candidates.Failed),
                SingleUse(candidates.NoInput)),
            CancellationToken.None);

        Assert.Equal(3, receipts.Count);
        Assert.IsType<FailedAdmissionReceiptMirror>(receipts[0]);
        Assert.IsType<NoInputAdmissionReceiptMirror>(receipts[1]);
        Assert.IsType<ObservedAdmissionReceiptMirror>(receipts[2]);
        Assert.True(proof.Proves(candidates.Observed));
        Assert.True(proof.Proves(candidates.Failed));
        Assert.True(proof.Proves(candidates.NoInput));

        AssertNegativeMatrix(manifest, instructions, candidates, proof);

        return new AdmissionAggregateMirror(
            manifest.AuthorityKind,
            manifest.ManifestDigest,
            manifest.Slice!.CatalogVersion,
            receipts,
            (1, 1, 1),
            true);
    }

    internal static FinalizedPolicyManifest CreateAdmissionManifest()
    {
        var source = ContractSliceBActivationTests.CreateManifest();
        var replacementTypes = new Dictionary<string, Type>(StringComparer.Ordinal)
        {
            [AdmissionProofKind.Observed.Value] =
                typeof(ObservedQualificationProofMirror),
            [AdmissionProofKind.Failed.Value] =
                typeof(FailedAttemptProofMirror),
            [AdmissionProofKind.NoInput.Value] =
                typeof(NoInputRoutingProofMirror),
        };
        var declarations = source.SchemaRegistry.AdmissionProofContracts
            .Select(contract =>
            {
                var type = replacementTypes[contract.Kind.Value];
                var component = ComponentTypeIdentity.Create(
                    contract.ProofComponent.ComponentKey,
                    contract.ProofComponent.ComponentVersion,
                    type.Assembly.GetName().Name!,
                    type.FullName!);
                return AdmissionProofContractDeclaration.Create(
                    contract.ContractKey,
                    contract.ContractVersion,
                    contract.Kind,
                    component,
                    contract.Surfaces,
                    contract.MaterialRoles);
            })
            .ToArray();
        var replacedKeys = declarations
            .Select(item => item.ProofComponent.ComponentKey)
            .ToHashSet(StringComparer.Ordinal);
        var registry = ReleaseSchemaRegistry.Create(
            source.SchemaRegistry.PayloadSchemas,
            source.SchemaRegistry.Parsers,
            source.SchemaRegistry.Indexes,
            source.SchemaRegistry.DemandProjectors,
            declarations,
            source.SchemaRegistry.CacheBudget);
        var components = source.Components
            .Where(binding =>
                !replacedKeys.Contains(binding.Component.ComponentKey))
            .Concat(declarations.Select(declaration =>
                ComponentArtifactBinding.Create(
                    declaration.ProofComponent,
                    TestArtifact)))
            .OrderBy(binding => binding.Component.ComponentKey, StringComparer.Ordinal)
            .ThenBy(binding => binding.Component.ComponentVersion, StringComparer.Ordinal)
            .ToArray();
        var artifacts = source.ArtifactFiles
            .Where(artifact => !string.Equals(
                artifact.FileName,
                ApplicationArtifact,
                StringComparison.Ordinal))
            .ToArray();
        Assert.Equal(source.ArtifactFiles.Count - 1, artifacts.Length);
        Assert.DoesNotContain(
            components,
            binding => string.Equals(
                binding.ArtifactFileName,
                ApplicationArtifact,
                StringComparison.Ordinal));
        var bytes = CanonicalManifestWriter.Write(new ParsedCanonicalManifest(
            source.AuthorityKind,
            source.SourceCommit,
            registry,
            source.ActivationProofContract,
            artifacts,
            components,
            source.Slice,
            source.CompleteCatalog));
        var manifest = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(manifest));
        Assert.Equal(3, manifest.SchemaRegistry.AdmissionProofContracts.Count);
        Assert.Equal(
            artifacts.Select(artifact => (
                artifact.FileName,
                artifact.ByteLength,
                artifact.ArtifactDigest.Value)),
            manifest.ArtifactFiles.Select(artifact => (
                artifact.FileName,
                artifact.ByteLength,
                artifact.ArtifactDigest.Value)));
        Assert.All(declarations, declaration => Assert.Contains(
            manifest.Components,
            binding =>
                string.Equals(
                    binding.Component.TypeName,
                    declaration.ProofComponent.TypeName,
                    StringComparison.Ordinal) &&
                string.Equals(
                    binding.ArtifactFileName,
                    TestArtifact,
                    StringComparison.Ordinal)));
        return manifest;
    }

    private static InstructionSet CreateInstructions(
        FinalizedPolicyManifest manifest)
    {
        var slice = Assert.IsType<CatalogSliceDeclaration>(manifest.Slice);
        var slots = new Dictionary<string, EvidenceSlotDeclaration>(
            StringComparer.Ordinal)
        {
            ["protocol.slot.provider-governed-text"] = RequireCanonicalSlot(
                slice,
                "protocol.slot.provider-governed-text",
                3),
            ["protocol.slot.repository-target-resolution"] =
                RequireCanonicalSlot(
                    slice,
                    "protocol.slot.repository-target-resolution",
                    3),
            ["protocol.slot.repository-tree"] = RequireCanonicalSlot(
                slice,
                "protocol.slot.repository-tree",
                2),
        };
        var repositoryTarget = AcquisitionTarget.Create(
            "protocol.test.subject",
            "protocol.test.repository",
            SurfaceKind.Repository,
            SnapshotKind.ExactCommit,
            Commit);
        var providerTarget = AcquisitionTarget.Create(
            "protocol.test.subject",
            "protocol.test.provider",
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent,
            "provider-event-0001");

        var failed = Instruction(
            manifest,
            slots["protocol.slot.provider-governed-text"],
            AdmissionProofKind.Failed,
            providerTarget);
        var noInput = Instruction(
            manifest,
            slots["protocol.slot.repository-target-resolution"],
            AdmissionProofKind.NoInput,
            repositoryTarget);
        var observed = Instruction(
            manifest,
            slots["protocol.slot.repository-tree"],
            AdmissionProofKind.Observed,
            repositoryTarget);
        return new([failed, noInput, observed], observed, failed, noInput);
    }

    private static EvidenceSlotDeclaration RequireCanonicalSlot(
        CatalogSliceDeclaration slice,
        string slotKey,
        int expectedOccurrences)
    {
        var matches = slice.Rules
            .SelectMany(rule => rule.EvaluationSlots)
            .Where(slot => string.Equals(
                slot.SlotKey,
                slotKey,
                StringComparison.Ordinal))
            .ToArray();
        Assert.Equal(expectedOccurrences, matches.Length);

        var canonical = matches[0];
        Assert.All(matches.Skip(1), candidate =>
        {
            Assert.Equal(canonical.Requirement, candidate.Requirement);
            Assert.Equal(canonical.ProfileSurfaces, candidate.ProfileSurfaces);
            Assert.Equal(canonical.MaterialRole, candidate.MaterialRole);
            Assert.Equal(canonical.TargetSelectorKey, candidate.TargetSelectorKey);
            Assert.Equal(canonical.Capabilities, candidate.Capabilities);
        });

        return canonical;
    }

    private static AdmissionInstructionMirror Instruction(
        FinalizedPolicyManifest manifest,
        EvidenceSlotDeclaration slot,
        AdmissionProofKind kind,
        AcquisitionTarget target) => AdmissionInstructionMirror.Create(
            manifest,
            slot.SlotKey,
            kind,
            slot.MaterialRole,
            AcquisitionRequest.Create(
                target,
                "protocol.adapter.test",
                "1",
                "protocol.source.test",
                "1",
                SingleUse(slot.Requirement)));

    private static CandidateSet CreateCandidates(
        FinalizedPolicyManifest manifest,
        InstructionSet instructions)
    {
        var failedResult = FailedAcquisitionResult.Create(
            instructions.Failed.Request,
            Started,
            Completed,
            [AcquisitionFailure.Create(
                instructions.Failed.Request.RequestedRequirements.Single().Key,
                "protocol.source.unavailable")]);
        var failed = FailedAttemptProofMirror.Create(
            manifest,
            instructions.Failed,
            failedResult);
        var noInput = NoInputRoutingProofMirror.Create(
            manifest,
            instructions.NoInput);

        var observedRequest = instructions.Observed.Request;
        var boundary = AcquisitionBoundary.Create(
            SnapshotKind.ExactCommit,
            Commit,
            Started,
            Completed);
        var scope = EvidenceScope.Create(observedRequest.Target, boundary);
        var requirement = observedRequest.RequestedRequirements.Single();
        var payload = CanonicalEvidencePayload.Create(
            requirement.PayloadSchemaKey,
            requirement.PayloadSchemaVersion,
            [0x01]);
        var binding = EvidenceBinding.Create(
            payload,
            SnapshotEvidenceLocation.Create(scope),
            [requirement.Key],
            Started.AddSeconds(30));
        var context = EvidenceContext.Create(
            observedRequest,
            scope,
            [RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [])],
            [binding],
            [],
            1);
        var result = ObservedAcquisitionResult.Create(context);
        var schema = manifest.SchemaRegistry.PayloadSchemas.Single(item =>
            string.Equals(
                item.SchemaKey,
                "protocol.repository-tree",
                StringComparison.Ordinal));
        var codec = manifest.Components.Single(item =>
            string.Equals(
                item.Component.ComponentKey,
                schema.Codec.ComponentKey,
                StringComparison.Ordinal));
        var usage = SemanticResourceLocalUsageMirror.Create(4, 1, 2, 3);
        var state = ClosedQualificationStateMirror.Create(
            instructions.Observed.InstructionDigest,
            Hash("protocol.test.demand/1"u8),
            schema.OutputModel,
            binding,
            codec,
            usage,
            usage,
            DecodeCacheDispositionMirror.Produced);
        var observed = ObservedQualificationProofMirror.Create(
            manifest,
            instructions.Observed,
            result,
            SingleUse(codec),
            state);
        return new(observed, failed, noInput);
    }

    private static ContractSliceBActivationProof CreateActivationProof(
        FinalizedPolicyManifest manifest,
        IEnumerable<IAdmissionProofCandidate> candidates)
    {
        var governed = RequireSchema(manifest, "protocol.governed-text");
        var target = RequireSchema(
            manifest,
            "protocol.repository-target-resolution");
        var tree = RequireSchema(manifest, "protocol.repository-tree");
        var governedCodec = new GovernedTextCodecMirror();
        var targetCodec = new RepositoryTargetCodecMirror();
        var treeCodec = new RepositoryTreeCodecMirror();
        var governedRegistration = CodecRegistration<GovernedTextModelMirror>
            .Create(
                governed,
                ModelTypeToken<GovernedTextModelMirror>.Create(
                    governed.OutputModel),
                governedCodec);
        var targetRegistration = CodecRegistration<RepositoryTargetModelMirror>
            .Create(
                target,
                ModelTypeToken<RepositoryTargetModelMirror>.Create(
                    target.OutputModel),
                targetCodec);
        var treeRegistration = CodecRegistration<RepositoryTreeModelMirror>
            .Create(
                tree,
                ModelTypeToken<RepositoryTreeModelMirror>.Create(
                    tree.OutputModel),
                treeCodec);
        return new ContractSliceBActivationProof(
            manifest,
            governedRegistration,
            targetRegistration,
            treeRegistration,
            governedCodec,
            targetCodec,
            treeCodec,
            admissionCandidates: candidates);
    }

    private static void AssertCanonicalFrames(
        FinalizedPolicyManifest manifest,
        InstructionSet instructions,
        CandidateSet candidates)
    {
        foreach (var instruction in instructions.All)
        {
            var expected = IndependentAdmissionFrame.WriteInstruction(
                manifest,
                instruction);
            Assert.Equal(expected, instruction.CanonicalBytes.ToArray());
            Assert.Equal(
                Convert.ToHexString(SHA256.HashData(expected)).ToLowerInvariant(),
                instruction.InstructionDigest.Value);
        }

        AssertCandidateFrame(manifest, instructions.Observed, candidates.Observed);
        AssertCandidateFrame(manifest, instructions.Failed, candidates.Failed);
        AssertCandidateFrame(manifest, instructions.NoInput, candidates.NoInput);
    }

    private static void AssertCandidateFrame(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        IAdmissionProofCandidate candidate)
    {
        var expected = IndependentAdmissionFrame.WriteReceipt(
            manifest,
            instruction,
            candidate);
        var actual = candidate switch
        {
            ObservedQualificationProofMirror observed =>
                observed.CanonicalReceiptBytes,
            FailedAttemptProofMirror failed => failed.CanonicalReceiptBytes,
            NoInputRoutingProofMirror noInput => noInput.CanonicalReceiptBytes,
            _ => throw new InvalidOperationException(),
        };
        Assert.Equal(expected, actual.ToArray());
        Assert.Equal(
            Convert.ToHexString(SHA256.HashData(expected)).ToLowerInvariant(),
            candidate.ReceiptDigest.Value);
    }

    private static void AssertDefensiveCopies(
        FinalizedPolicyManifest manifest,
        InstructionSet instructions,
        CandidateSet candidates)
    {
        var source = candidates.All.ToArray();
        var proof = CreateActivationProof(manifest, source);
        source[0] = candidates.Observed;
        Assert.True(proof.Proves(candidates.Failed));
        Assert.False(proof.Proves(FailedAttemptProofMirror.Create(
            manifest,
            instructions.Failed,
            candidates.Failed.Result)));
        Assert.Throws<ArgumentException>(() => CreateActivationProof(
            manifest,
            [candidates.Observed, candidates.Observed]));
        Assert.Throws<ArgumentException>(() => CreateActivationProof(
            manifest,
            [candidates.Observed, null!]));
    }

    private static void AssertLifecycle()
    {
        Assert.Equal((0, 0, 0, 0, "Failed"),
            Lifecycle(false, true, true, true, false));
        Assert.Equal((1, 0, 0, 0, "Failed"),
            Lifecycle(true, false, true, true, false));
        Assert.Equal((1, 1, 0, 0, "Failed"),
            Lifecycle(true, true, false, true, false));
        Assert.Equal((1, 1, 1, 1, "Observed"),
            Lifecycle(true, true, true, true, false));
        Assert.Equal((0, 0, 0, 0, "NoInput"),
            Lifecycle(true, true, true, true, true));
    }

    private static (int Writer, int Qualifier, int Meter, int Cache, string Leaf)
        Lifecycle(
            bool intent,
            bool write,
            bool qualify,
            bool cache,
            bool noInput)
    {
        var writer = 0;
        var qualifier = 0;
        var meter = 0;
        var cacheCalls = 0;
        if (noInput || !intent)
        {
            return (0, 0, 0, 0, noInput ? "NoInput" : "Failed");
        }

        writer++;
        if (!write)
        {
            return (writer, 0, 0, 0, "Failed");
        }

        qualifier++;
        if (!qualify)
        {
            return (writer, qualifier, 0, 0, "Failed");
        }

        meter++;
        if (!cache)
        {
            throw new InvalidOperationException("cache integrity failure");
        }

        cacheCalls++;
        return (writer, qualifier, meter, cacheCalls, "Observed");
    }

    private static void AssertNegativeMatrix(
        FinalizedPolicyManifest manifest,
        InstructionSet instructions,
        CandidateSet candidates,
        ContractSliceBActivationProof proof)
    {
        var coordinator = new ContractSliceBAdmissionCoordinatorMirror();
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () =>
            coordinator.Admit(
                manifest,
                proof,
                instructions.All,
                AcquisitionProofSet.Create([], [candidates.Failed],
                    [candidates.NoInput]),
                CancellationToken.None));

        var wrongDigest = FailedAttemptProofMirror.Create(
            manifest,
            instructions.Failed,
            candidates.Failed.Result,
            ExactSha256Digest.Parse(new string('0', 64)));
        var wrongProof = CreateActivationProof(
            manifest,
            [candidates.Observed, wrongDigest, candidates.NoInput]);
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () =>
            coordinator.Admit(
                manifest,
                wrongProof,
                instructions.All,
                AcquisitionProofSet.Create(
                    [candidates.Observed],
                    [wrongDigest],
                    [candidates.NoInput]),
                CancellationToken.None));

        var collisionDigest = ExactSha256Digest.Parse(new string('1', 64));
        var collisionFailed = FailedAttemptProofMirror.Create(
            manifest,
            instructions.Failed,
            candidates.Failed.Result,
            collisionDigest);
        var collisionNoInput = NoInputRoutingProofMirror.Create(
            manifest,
            instructions.NoInput,
            collisionDigest);
        var collisionProof = CreateActivationProof(
            manifest,
            [candidates.Observed, collisionFailed, collisionNoInput]);
        Reject(CatalogIntegrityCode.CacheIdentityCollision, () =>
            coordinator.Admit(
                manifest,
                collisionProof,
                instructions.All,
                AcquisitionProofSet.Create(
                    [candidates.Observed],
                    [collisionFailed],
                    [collisionNoInput]),
                CancellationToken.None));

        var joinedState = ClosedQualificationStateMirror.Create(
            candidates.Observed.State.InstructionDigest,
            candidates.Observed.State.DemandDigest,
            candidates.Observed.State.OutputModel,
            candidates.Observed.State.Binding,
            candidates.Observed.State.Codec,
            candidates.Observed.State.ClaimedUsage,
            candidates.Observed.State.MeasuredUsage,
            DecodeCacheDispositionMirror.Joined);
        var joined = ObservedQualificationProofMirror.Create(
            manifest,
            instructions.Observed,
            candidates.Observed.Result,
            candidates.Observed.QualifiedCodecs,
            joinedState);
        var joinedProof = CreateActivationProof(
            manifest,
            [joined, candidates.Failed, candidates.NoInput]);
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () =>
            coordinator.Admit(
                manifest,
                joinedProof,
                instructions.All,
                AcquisitionProofSet.Create(
                    [joined],
                    [candidates.Failed],
                    [candidates.NoInput]),
                CancellationToken.None));

        using var cancelled = new CancellationTokenSource();
        cancelled.Cancel();
        Assert.Throws<OperationCanceledException>(() => coordinator.Admit(
            manifest,
            proof,
            instructions.All,
            AcquisitionProofSet.Create(
                [candidates.Observed],
                [candidates.Failed],
                [candidates.NoInput]),
            cancelled.Token));
    }

    private static void Reject(CatalogIntegrityCode code, Action action)
    {
        var exception = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Same(code, exception.Code);
    }

    private static PayloadSchemaDeclaration RequireSchema(
        FinalizedPolicyManifest manifest,
        string key) => manifest.SchemaRegistry.PayloadSchemas.Single(schema =>
            string.Equals(schema.SchemaKey, key, StringComparison.Ordinal));

    private static ExactSha256Digest Hash(ReadOnlySpan<byte> bytes) =>
        ExactSha256Digest.FromHashBytes(SHA256.HashData(bytes));

    private static IEnumerable<T> SingleUse<T>(T value)
    {
        yield return value;
    }

    private sealed record InstructionSet(
        IReadOnlyList<AdmissionInstructionMirror> All,
        AdmissionInstructionMirror Observed,
        AdmissionInstructionMirror Failed,
        AdmissionInstructionMirror NoInput);

    private sealed record CandidateSet(
        ObservedQualificationProofMirror Observed,
        FailedAttemptProofMirror Failed,
        NoInputRoutingProofMirror NoInput)
    {
        internal IReadOnlyList<IAdmissionProofCandidate> All =>
            [Observed, Failed, NoInput];
    }
}

internal sealed class AdmissionInstructionMirror
{
    private readonly byte[] _canonicalBytes;

    private AdmissionInstructionMirror(
        string slotKey,
        AdmissionProofKind kind,
        string contractKey,
        string contractVersion,
        string materialRole,
        AcquisitionRequest request,
        ExactSha256Digest manifestDigest,
        byte[] canonicalBytes)
    {
        SlotKey = slotKey;
        Kind = kind;
        ContractKey = contractKey;
        ContractVersion = contractVersion;
        MaterialRole = materialRole;
        Request = request;
        ManifestDigest = manifestDigest;
        _canonicalBytes = canonicalBytes.ToArray();
        InstructionDigest = ExactSha256Digest.FromHashBytes(
            SHA256.HashData(_canonicalBytes));
    }

    internal string SlotKey { get; }
    internal AdmissionProofKind Kind { get; }
    internal string ContractKey { get; }
    internal string ContractVersion { get; }
    internal string MaterialRole { get; }
    internal AcquisitionRequest Request { get; }
    internal ExactSha256Digest ManifestDigest { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes => _canonicalBytes;

    internal static AdmissionInstructionMirror Create(
        FinalizedPolicyManifest manifest,
        string slotKey,
        AdmissionProofKind kind,
        string materialRole,
        AcquisitionRequest request)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentException.ThrowIfNullOrEmpty(slotKey);
        ArgumentNullException.ThrowIfNull(kind);
        ArgumentException.ThrowIfNullOrEmpty(materialRole);
        ArgumentNullException.ThrowIfNull(request);
        var contract = manifest.SchemaRegistry.AdmissionProofContracts.Single(
            item => item.Kind.Equals(kind));
        var provisional = new AdmissionInstructionMirror(
            new string(slotKey.AsSpan()),
            kind,
            contract.ContractKey,
            contract.ContractVersion,
            new string(materialRole.AsSpan()),
            request,
            manifest.ManifestDigest,
            []);
        var bytes = AdmissionMirrorFrame.WriteInstruction(provisional);
        return new AdmissionInstructionMirror(
            provisional.SlotKey,
            kind,
            contract.ContractKey,
            contract.ContractVersion,
            provisional.MaterialRole,
            request,
            manifest.ManifestDigest,
            bytes);
    }
}

internal sealed class ClosedQualificationStateMirror
{
    private ClosedQualificationStateMirror(
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ModelContractIdentity outputModel,
        EvidenceBinding binding,
        ComponentArtifactBinding codec,
        SemanticResourceLocalUsageMirror claimedUsage,
        SemanticResourceLocalUsageMirror measuredUsage,
        DecodeCacheDispositionMirror cacheDisposition)
    {
        InstructionDigest = instructionDigest;
        DemandDigest = demandDigest;
        OutputModel = outputModel;
        Binding = binding;
        Codec = codec;
        ClaimedUsage = claimedUsage;
        MeasuredUsage = measuredUsage;
        CacheDisposition = cacheDisposition;
    }

    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal ModelContractIdentity OutputModel { get; }
    internal EvidenceBinding Binding { get; }
    internal ComponentArtifactBinding Codec { get; }
    internal SemanticResourceLocalUsageMirror ClaimedUsage { get; }
    internal SemanticResourceLocalUsageMirror MeasuredUsage { get; }
    internal DecodeCacheDispositionMirror CacheDisposition { get; }

    internal static ClosedQualificationStateMirror Create(
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ModelContractIdentity outputModel,
        EvidenceBinding binding,
        ComponentArtifactBinding codec,
        SemanticResourceLocalUsageMirror claimedUsage,
        SemanticResourceLocalUsageMirror measuredUsage,
        DecodeCacheDispositionMirror cacheDisposition) => new(
            instructionDigest ??
                throw new ArgumentNullException(nameof(instructionDigest)),
            demandDigest ?? throw new ArgumentNullException(nameof(demandDigest)),
            outputModel ?? throw new ArgumentNullException(nameof(outputModel)),
            binding ?? throw new ArgumentNullException(nameof(binding)),
            codec ?? throw new ArgumentNullException(nameof(codec)),
            claimedUsage ?? throw new ArgumentNullException(nameof(claimedUsage)),
            measuredUsage ??
                throw new ArgumentNullException(nameof(measuredUsage)),
            cacheDisposition);
}

internal sealed class ObservedQualificationProofMirror :
    IObservedQualificationProof
{
    private readonly byte[] _canonicalReceiptBytes;

    private ObservedQualificationProofMirror(
        AdmissionInstructionMirror instruction,
        ObservedAcquisitionResult result,
        ComponentArtifactBinding[] qualifiedCodecs,
        ClosedQualificationStateMirror state,
        byte[] canonicalReceiptBytes,
        ExactSha256Digest receiptDigest)
    {
        SlotKeys = Array.AsReadOnly([instruction.SlotKey]);
        ContractKey = instruction.ContractKey;
        ContractVersion = instruction.ContractVersion;
        ManifestDigest = instruction.ManifestDigest;
        InstructionDigest = instruction.InstructionDigest;
        Request = instruction.Request;
        Result = result;
        QualifiedCodecs = Array.AsReadOnly(qualifiedCodecs.ToArray());
        State = state;
        _canonicalReceiptBytes = canonicalReceiptBytes.ToArray();
        ReceiptDigest = receiptDigest;
    }

    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
    public ObservedAcquisitionResult Result { get; }
    public IReadOnlyList<ComponentArtifactBinding> QualifiedCodecs { get; }
    internal ClosedQualificationStateMirror State { get; }
    internal ReadOnlyMemory<byte> CanonicalReceiptBytes =>
        _canonicalReceiptBytes;

    internal static ObservedQualificationProofMirror Create(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        ObservedAcquisitionResult result,
        IEnumerable<ComponentArtifactBinding> qualifiedCodecs,
        ClosedQualificationStateMirror state,
        ExactSha256Digest? forcedReceiptDigest = null)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(instruction);
        ArgumentNullException.ThrowIfNull(result);
        ArgumentNullException.ThrowIfNull(qualifiedCodecs);
        ArgumentNullException.ThrowIfNull(state);
        var codecs = qualifiedCodecs.ToArray();
        if (codecs.Length == 0 || codecs.Any(item => item is null))
        {
            throw new ArgumentException(
                "Qualified codecs must be non-empty and non-null.",
                nameof(qualifiedCodecs));
        }

        Array.Sort(codecs, static (left, right) => StringComparer.Ordinal.Compare(
            left.Component.ComponentKey,
            right.Component.ComponentKey));
        if (codecs.Select(item => item.Component.ComponentKey)
            .Distinct(StringComparer.Ordinal).Count() != codecs.Length)
        {
            throw new ArgumentException(
                "Qualified codecs must be unique.",
                nameof(qualifiedCodecs));
        }

        var provisional = new ObservedQualificationProofMirror(
            instruction,
            result,
            codecs,
            state,
            [],
            forcedReceiptDigest ?? ExactSha256Digest.Parse(new string('0', 64)));
        var bytes = AdmissionMirrorFrame.WriteReceipt(
            manifest,
            instruction,
            provisional);
        var digest = forcedReceiptDigest ?? ExactSha256Digest.FromHashBytes(
            SHA256.HashData(bytes));
        return new ObservedQualificationProofMirror(
            instruction,
            result,
            codecs,
            state,
            bytes,
            digest);
    }
}

internal sealed class FailedAttemptProofMirror : IFailedAttemptProof
{
    private readonly byte[] _canonicalReceiptBytes;

    private FailedAttemptProofMirror(
        AdmissionInstructionMirror instruction,
        FailedAcquisitionResult result,
        byte[] canonicalReceiptBytes,
        ExactSha256Digest receiptDigest)
    {
        SlotKeys = Array.AsReadOnly([instruction.SlotKey]);
        ContractKey = instruction.ContractKey;
        ContractVersion = instruction.ContractVersion;
        ManifestDigest = instruction.ManifestDigest;
        InstructionDigest = instruction.InstructionDigest;
        Request = instruction.Request;
        Result = result;
        _canonicalReceiptBytes = canonicalReceiptBytes.ToArray();
        ReceiptDigest = receiptDigest;
    }

    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
    public FailedAcquisitionResult Result { get; }
    internal ReadOnlyMemory<byte> CanonicalReceiptBytes =>
        _canonicalReceiptBytes;

    internal static FailedAttemptProofMirror Create(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        FailedAcquisitionResult result,
        ExactSha256Digest? forcedReceiptDigest = null)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(instruction);
        ArgumentNullException.ThrowIfNull(result);
        var provisional = new FailedAttemptProofMirror(
            instruction,
            result,
            [],
            forcedReceiptDigest ?? ExactSha256Digest.Parse(new string('0', 64)));
        var bytes = AdmissionMirrorFrame.WriteReceipt(
            manifest,
            instruction,
            provisional);
        return new FailedAttemptProofMirror(
            instruction,
            result,
            bytes,
            forcedReceiptDigest ?? ExactSha256Digest.FromHashBytes(
                SHA256.HashData(bytes)));
    }
}

internal sealed class NoInputRoutingProofMirror : INoInputRoutingProof
{
    private readonly byte[] _canonicalReceiptBytes;

    private NoInputRoutingProofMirror(
        AdmissionInstructionMirror instruction,
        byte[] canonicalReceiptBytes,
        ExactSha256Digest receiptDigest)
    {
        SlotKeys = Array.AsReadOnly([instruction.SlotKey]);
        ContractKey = instruction.ContractKey;
        ContractVersion = instruction.ContractVersion;
        ManifestDigest = instruction.ManifestDigest;
        InstructionDigest = instruction.InstructionDigest;
        Request = instruction.Request;
        _canonicalReceiptBytes = canonicalReceiptBytes.ToArray();
        ReceiptDigest = receiptDigest;
    }

    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
    internal ReadOnlyMemory<byte> CanonicalReceiptBytes =>
        _canonicalReceiptBytes;

    internal static NoInputRoutingProofMirror Create(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        ExactSha256Digest? forcedReceiptDigest = null)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(instruction);
        var provisional = new NoInputRoutingProofMirror(
            instruction,
            [],
            forcedReceiptDigest ?? ExactSha256Digest.Parse(new string('0', 64)));
        var bytes = AdmissionMirrorFrame.WriteReceipt(
            manifest,
            instruction,
            provisional);
        return new NoInputRoutingProofMirror(
            instruction,
            bytes,
            forcedReceiptDigest ?? ExactSha256Digest.FromHashBytes(
                SHA256.HashData(bytes)));
    }
}

internal abstract class AdmissionReceiptMirror
{
    private readonly byte[] _canonicalBytes;

    private protected AdmissionReceiptMirror(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        SlotKey = new string(slotKey.AsSpan());
        ReceiptDigest = receiptDigest;
        _canonicalBytes = canonicalBytes.ToArray();
    }

    internal string SlotKey { get; }
    internal ExactSha256Digest ReceiptDigest { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes => _canonicalBytes;
    internal abstract TResult Accept<TResult>(
        IAdmissionReceiptMirrorVisitor<TResult> visitor);
}

internal sealed class ObservedAdmissionReceiptMirror : AdmissionReceiptMirror
{
    private ObservedAdmissionReceiptMirror(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        ObservedAcquisitionResult result,
        ClosedQualificationStateMirror state)
        : base(slotKey, receiptDigest, canonicalBytes)
    {
        Result = result;
        State = state;
    }

    internal ObservedAcquisitionResult Result { get; }
    internal ClosedQualificationStateMirror State { get; }
    internal override TResult Accept<TResult>(
        IAdmissionReceiptMirrorVisitor<TResult> visitor) =>
        visitor.VisitObserved(Result, State);

    internal static ObservedAdmissionReceiptMirror Create(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        ObservedAcquisitionResult result,
        ClosedQualificationStateMirror state) => new(
            slotKey,
            receiptDigest,
            canonicalBytes,
            result,
            state);
}

internal sealed class FailedAdmissionReceiptMirror : AdmissionReceiptMirror
{
    private FailedAdmissionReceiptMirror(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        FailedAcquisitionResult result)
        : base(slotKey, receiptDigest, canonicalBytes)
    {
        Result = result;
    }

    internal FailedAcquisitionResult Result { get; }
    internal override TResult Accept<TResult>(
        IAdmissionReceiptMirrorVisitor<TResult> visitor) =>
        visitor.VisitFailed(Result);

    internal static FailedAdmissionReceiptMirror Create(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        FailedAcquisitionResult result) =>
        new(slotKey, receiptDigest, canonicalBytes, result);
}

internal sealed class NoInputAdmissionReceiptMirror : AdmissionReceiptMirror
{
    private NoInputAdmissionReceiptMirror(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        AcquisitionRequest request)
        : base(slotKey, receiptDigest, canonicalBytes)
    {
        Request = request;
    }

    internal AcquisitionRequest Request { get; }
    internal override TResult Accept<TResult>(
        IAdmissionReceiptMirrorVisitor<TResult> visitor) =>
        visitor.VisitNoInput(Request);

    internal static NoInputAdmissionReceiptMirror Create(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        AcquisitionRequest request) =>
        new(slotKey, receiptDigest, canonicalBytes, request);
}

internal interface IAdmissionReceiptMirrorVisitor<TResult>
{
    TResult VisitObserved(
        ObservedAcquisitionResult result,
        ClosedQualificationStateMirror state);
    TResult VisitFailed(FailedAcquisitionResult result);
    TResult VisitNoInput(AcquisitionRequest request);
}

internal sealed class ContractSliceBAdmissionCoordinatorMirror
{
    internal IReadOnlyList<AdmissionReceiptMirror> Admit(
        FinalizedPolicyManifest manifest,
        IPolicyActivationProof activationProof,
        IReadOnlyList<AdmissionInstructionMirror> instructions,
        AcquisitionProofSet candidates,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(activationProof);
        ArgumentNullException.ThrowIfNull(instructions);
        ArgumentNullException.ThrowIfNull(candidates);
        cancellationToken.ThrowIfCancellationRequested();

        var orderedInstructions = instructions.ToArray();
        if (orderedInstructions.Length == 0 ||
            orderedInstructions.Any(item => item is null))
        {
            throw Invalid();
        }

        Array.Sort(orderedInstructions, static (left, right) =>
            StringComparer.Ordinal.Compare(left.SlotKey, right.SlotKey));
        if (orderedInstructions.Select(item => item.SlotKey)
            .Distinct(StringComparer.Ordinal).Count() !=
            orderedInstructions.Length)
        {
            throw Invalid();
        }

        var flattened = candidates.Observed
            .Cast<IAdmissionProofCandidate>()
            .Concat(candidates.Failed)
            .Concat(candidates.NoInput)
            .ToArray();
        if (flattened.Length != orderedInstructions.Length ||
            flattened.Any(item => item is null) ||
            flattened.Distinct(ReferenceEqualityComparer.Instance).Count() !=
                flattened.Length ||
            flattened.Any(item => item.SlotKeys.Count != 1))
        {
            throw Invalid();
        }

        var candidateBySlot = new Dictionary<string, IAdmissionProofCandidate>(
            StringComparer.Ordinal);
        foreach (var candidate in flattened)
        {
            if (!candidateBySlot.TryAdd(candidate.SlotKeys[0], candidate))
            {
                throw Invalid();
            }
        }

        var validated = new List<(AdmissionInstructionMirror Instruction,
            IAdmissionProofCandidate Candidate, byte[] Bytes)>();
        foreach (var instruction in orderedInstructions)
        {
            if (!candidateBySlot.TryGetValue(
                    instruction.SlotKey,
                    out var candidate))
            {
                throw Invalid();
            }

            ValidateCommon(manifest, activationProof, instruction, candidate);
            ValidateLeaf(manifest, instruction, candidate);
            var bytes = AdmissionMirrorFrame.WriteReceipt(
                manifest,
                instruction,
                candidate);
            validated.Add((instruction, candidate, bytes));
        }

        for (var left = 0; left < validated.Count; left++)
        {
            for (var right = left + 1; right < validated.Count; right++)
            {
                if (validated[left].Candidate.ReceiptDigest.Equals(
                        validated[right].Candidate.ReceiptDigest) &&
                    !validated[left].Bytes.AsSpan().SequenceEqual(
                        validated[right].Bytes))
                {
                    throw new CatalogIntegrityException(
                        CatalogIntegrityCode.CacheIdentityCollision);
                }
            }
        }

        foreach (var item in validated)
        {
            var digest = ExactSha256Digest.FromHashBytes(
                SHA256.HashData(item.Bytes));
            if (!digest.Equals(item.Candidate.ReceiptDigest))
            {
                throw Invalid();
            }
        }

        return Array.AsReadOnly(validated.Select(item => item.Candidate switch
        {
            ObservedQualificationProofMirror observed =>
                (AdmissionReceiptMirror)ObservedAdmissionReceiptMirror.Create(
                    item.Instruction.SlotKey,
                    observed.ReceiptDigest,
                    item.Bytes,
                    observed.Result,
                    observed.State),
            FailedAttemptProofMirror failed =>
                FailedAdmissionReceiptMirror.Create(
                    item.Instruction.SlotKey,
                    failed.ReceiptDigest,
                    item.Bytes,
                    failed.Result),
            NoInputRoutingProofMirror noInput =>
                NoInputAdmissionReceiptMirror.Create(
                    item.Instruction.SlotKey,
                    noInput.ReceiptDigest,
                    item.Bytes,
                    noInput.Request),
            _ => throw Invalid(),
        }).ToArray());
    }

    private static void ValidateCommon(
        FinalizedPolicyManifest manifest,
        IPolicyActivationProof activationProof,
        AdmissionInstructionMirror instruction,
        IAdmissionProofCandidate candidate)
    {
        var contract = manifest.SchemaRegistry.AdmissionProofContracts.SingleOrDefault(
            item =>
                item.Kind.Equals(instruction.Kind) &&
                string.Equals(
                    item.ContractKey,
                    instruction.ContractKey,
                    StringComparison.Ordinal) &&
                string.Equals(
                    item.ContractVersion,
                    instruction.ContractVersion,
                    StringComparison.Ordinal));
        if (contract is null ||
            !instruction.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !candidate.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !candidate.InstructionDigest.Equals(instruction.InstructionDigest) ||
            !candidate.Request.Equals(instruction.Request) ||
            !string.Equals(candidate.ContractKey, instruction.ContractKey,
                StringComparison.Ordinal) ||
            !string.Equals(candidate.ContractVersion,
                instruction.ContractVersion, StringComparison.Ordinal) ||
            !string.Equals(candidate.GetType().FullName,
                contract.ProofComponent.TypeName, StringComparison.Ordinal) ||
            !string.Equals(candidate.GetType().Assembly.GetName().Name,
                contract.ProofComponent.AssemblyName, StringComparison.Ordinal) ||
            !contract.Surfaces.Values.Contains(instruction.Request.Target.Surface) ||
            !contract.MaterialRoles.Contains(
                instruction.MaterialRole,
                StringComparer.Ordinal) ||
            !manifest.Components.Any(binding =>
                string.Equals(binding.Component.ComponentKey,
                    contract.ProofComponent.ComponentKey,
                    StringComparison.Ordinal) &&
                string.Equals(binding.ArtifactFileName,
                    "MeAndAI.Protocol.Conformance.Tests.dll",
                    StringComparison.Ordinal)) ||
            !string.Equals(activationProof.ContractKey,
                manifest.ActivationProofContract.ContractKey,
                StringComparison.Ordinal) ||
            !string.Equals(activationProof.ContractVersion,
                manifest.ActivationProofContract.ContractVersion,
                StringComparison.Ordinal) ||
            !activationProof.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !activationProof.VerifiedArtifacts.SequenceEqual(
                manifest.ArtifactFiles) ||
            !activationProof.Proves(candidate) ||
            !AdmissionMirrorFrame.WriteInstruction(instruction).AsSpan()
                .SequenceEqual(instruction.CanonicalBytes.Span))
        {
            throw Invalid();
        }
    }

    private static void ValidateLeaf(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        IAdmissionProofCandidate candidate)
    {
        if (candidate is ObservedQualificationProofMirror observed)
        {
            var schema = manifest.SchemaRegistry.PayloadSchemas.Single(item =>
                string.Equals(item.SchemaKey,
                    observed.State.Binding.Payload.SchemaKey,
                    StringComparison.Ordinal));
            var exactUsage = SameUsage(
                observed.State.ClaimedUsage,
                observed.State.MeasuredUsage);
            if (!instruction.Kind.Equals(AdmissionProofKind.Observed) ||
                !observed.Result.Request.Equals(instruction.Request) ||
                !observed.Result.Context.Status.Equals(
                    AcquisitionStatus.Complete) ||
                !observed.Result.Context.Scope.Target.Equals(
                    instruction.Request.Target) ||
                observed.Result.Context.Bindings.Count != 1 ||
                !ReferenceEquals(observed.Result.Context.Bindings[0],
                    observed.State.Binding) ||
                observed.QualifiedCodecs.Count != 1 ||
                !ReferenceEquals(observed.QualifiedCodecs[0],
                    observed.State.Codec) ||
                !observed.State.InstructionDigest.Equals(
                    instruction.InstructionDigest) ||
                !ReferenceEquals(observed.State.OutputModel, schema.OutputModel) ||
                !string.Equals(observed.State.Codec.Component.ComponentKey,
                    schema.Codec.ComponentKey, StringComparison.Ordinal) ||
                !exactUsage ||
                observed.State.CacheDisposition is not
                    (DecodeCacheDispositionMirror.Produced or
                     DecodeCacheDispositionMirror.Retained))
            {
                throw Invalid();
            }
        }
        else if (candidate is FailedAttemptProofMirror failed)
        {
            if (!instruction.Kind.Equals(AdmissionProofKind.Failed) ||
                !failed.Result.Request.Equals(instruction.Request) ||
                failed.Result.Failures.Count == 0 ||
                failed.Result.Failures.Select(item => item.RequirementKey)
                    .Distinct(StringComparer.Ordinal).Count() !=
                    instruction.Request.RequestedRequirements.Count)
            {
                throw Invalid();
            }
        }
        else if (candidate is NoInputRoutingProofMirror)
        {
            if (!instruction.Kind.Equals(AdmissionProofKind.NoInput))
            {
                throw Invalid();
            }
        }
        else
        {
            throw Invalid();
        }
    }

    private static bool SameUsage(
        SemanticResourceLocalUsageMirror left,
        SemanticResourceLocalUsageMirror right) =>
        left.GeneratedBytes == right.GeneratedBytes &&
        left.LayerDepth == right.LayerDepth &&
        left.LayerNodes == right.LayerNodes &&
        left.AdditionalComplexity == right.AdditionalComplexity;

    private static CatalogIntegrityException Invalid() =>
        new(CatalogIntegrityCode.AdmissionProofInvalid);
}

internal sealed record AdmissionAggregateMirror(
    CatalogAuthorityKind AuthorityKind,
    ExactSha256Digest ManifestDigest,
    CatalogVersion CatalogVersion,
    IReadOnlyList<AdmissionReceiptMirror> Receipts,
    (int Observed, int Failed, int NoInput) LeafCounts,
    bool LifecycleClosed);

internal static class AdmissionMirrorFrame
{
    private static readonly UTF8Encoding Utf8 = new(false, true);

    internal static byte[] WriteInstruction(
        AdmissionInstructionMirror instruction)
    {
        using var stream = new MemoryStream();
        WriteRaw(stream, "protocol.test.admission-instruction/1\n"u8);
        WriteText(stream, instruction.SlotKey);
        WriteText(stream, instruction.ManifestDigest.Value);
        stream.WriteByte(LeafRank(instruction.Kind));
        WriteText(stream, instruction.ContractKey);
        WriteText(stream, instruction.ContractVersion);
        WriteText(stream, instruction.MaterialRole);
        WriteRequest(stream, instruction.Request);
        return stream.ToArray();
    }

    internal static byte[] WriteReceipt(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        IAdmissionProofCandidate candidate)
    {
        using var stream = new MemoryStream();
        WriteRaw(stream, "protocol.test.admission-receipt/1\n"u8);
        WriteBytes(stream, instruction.CanonicalBytes.Span);
        WriteText(stream, instruction.SlotKey);
        var contract = manifest.SchemaRegistry.AdmissionProofContracts.Single(
            item => item.Kind.Equals(instruction.Kind));
        WriteComponent(stream, contract.ProofComponent);
        var component = manifest.Components.Single(item =>
            string.Equals(item.Component.ComponentKey,
                contract.ProofComponent.ComponentKey,
                StringComparison.Ordinal));
        var artifact = manifest.ArtifactFiles.Single(item =>
            string.Equals(item.FileName,
                component.ArtifactFileName,
                StringComparison.Ordinal));
        WriteText(stream, artifact.FileName);
        WriteInt64(stream, artifact.ByteLength);
        WriteText(stream, artifact.ArtifactDigest.Value);

        switch (candidate)
        {
            case ObservedQualificationProofMirror observed:
                WriteObserved(stream, observed);
                break;
            case FailedAttemptProofMirror failed:
                WriteFailed(stream, failed.Result);
                break;
            case NoInputRoutingProofMirror:
                break;
            default:
                throw new InvalidOperationException();
        }

        return stream.ToArray();
    }

    internal static void WriteRequest(Stream stream, AcquisitionRequest request)
    {
        WriteText(stream, request.Target.SubjectIdentity);
        WriteText(stream, request.Target.SourceIdentity);
        stream.WriteByte(SurfaceRank(request.Target.Surface));
        stream.WriteByte(SnapshotRank(request.Target.SnapshotKind));
        WriteText(stream, request.Target.TargetIdentity);
        WriteText(stream, request.AdapterKey);
        WriteText(stream, request.AdapterContractVersion);
        WriteText(stream, request.SourceContractKey);
        WriteText(stream, request.SourceContractVersion);
        WriteUInt32(stream, checked((uint)request.RequestedRequirements.Count));
        foreach (var requirement in request.RequestedRequirements)
        {
            WriteText(stream, requirement.Key);
            stream.WriteByte(SurfaceRank(requirement.Surface));
            WriteText(stream, requirement.Kind);
            WriteText(stream, requirement.CompletenessContract);
            WriteText(stream, requirement.PayloadSchemaKey);
            WriteText(stream, requirement.PayloadSchemaVersion);
            WriteUInt32(stream,
                checked((uint)requirement.AcceptedConsistencyClasses.Count));
            foreach (var consistency in requirement.AcceptedConsistencyClasses)
            {
                WriteText(stream, consistency.Value);
            }
        }
    }

    private static void WriteObserved(
        Stream stream,
        ObservedQualificationProofMirror proof)
    {
        var context = proof.Result.Context;
        stream.WriteByte(StatusRank(context.Status));
        WriteScope(stream, context.Scope);
        WriteUInt32(stream,
            checked((uint)context.RequirementAcquisitions.Count));
        foreach (var acquisition in context.RequirementAcquisitions)
        {
            WriteText(stream, acquisition.Requirement.Key);
            stream.WriteByte(StatusRank(acquisition.Status));
            WriteUInt32(stream, checked((uint)acquisition.Failures.Count));
            foreach (var failure in acquisition.Failures)
            {
                WriteText(stream, failure.RequirementKey);
                WriteText(stream, failure.Code);
            }
        }

        WriteUInt32(stream, checked((uint)context.Bindings.Count));
        foreach (var binding in context.Bindings)
        {
            WriteScope(stream, binding.Location.Scope);
            WriteText(stream, binding.Payload.SchemaKey);
            WriteText(stream, binding.Payload.SchemaVersion);
            WriteText(stream, binding.Payload.ContentDigest.Value);
            WriteUInt32(stream, checked((uint)binding.RequirementKeys.Count));
            foreach (var key in binding.RequirementKeys)
            {
                WriteText(stream, key);
            }
        }

        WriteUInt32(stream, checked((uint)context.Pages.Count));
        foreach (var page in context.Pages)
        {
            WriteUInt32(stream, checked((uint)page.Sequence));
            WriteNullableDigest(stream, page.RequestCursorDigest);
            WriteNullableDigest(stream, page.NextCursorDigest);
            WriteInt64(stream, page.SourceObjectCount);
        }
        WriteInt64(stream, context.SourceObjectCount);
        WriteUInt32(stream, checked((uint)proof.QualifiedCodecs.Count));
        foreach (var codec in proof.QualifiedCodecs)
        {
            WriteComponent(stream, codec.Component);
            WriteText(stream, codec.ArtifactFileName);
        }

        var state = proof.State;
        WriteText(stream, state.InstructionDigest.Value);
        WriteText(stream, state.DemandDigest.Value);
        WriteText(stream, state.OutputModel.ModelKey);
        WriteText(stream, state.OutputModel.ModelVersion);
        WriteComponent(stream, state.OutputModel.ImplementationType);
        WriteText(stream, state.Binding.Payload.ContentDigest.Value);
        WriteComponent(stream, state.Codec.Component);
        WriteText(stream, state.Codec.ArtifactFileName);
        stream.WriteByte(state.CacheDisposition switch
        {
            DecodeCacheDispositionMirror.Produced => 0,
            DecodeCacheDispositionMirror.Retained => 1,
            DecodeCacheDispositionMirror.Joined => 2,
            _ => throw new InvalidOperationException(),
        });
        WriteUsage(stream, state.ClaimedUsage);
        WriteUsage(stream, state.MeasuredUsage);
    }

    private static void WriteFailed(
        Stream stream,
        FailedAcquisitionResult result)
    {
        WriteInt64(stream, result.StartedAtUtc.UtcTicks);
        WriteInt64(stream, result.FailedAtUtc.UtcTicks);
        WriteUInt32(stream, checked((uint)result.Failures.Count));
        foreach (var failure in result.Failures)
        {
            WriteText(stream, failure.RequirementKey);
            WriteText(stream, failure.Code);
        }
    }

    private static void WriteScope(Stream stream, EvidenceScope scope)
    {
        WriteText(stream, scope.Target.SubjectIdentity);
        WriteText(stream, scope.Target.SourceIdentity);
        stream.WriteByte(SurfaceRank(scope.Target.Surface));
        stream.WriteByte(SnapshotRank(scope.Target.SnapshotKind));
        WriteText(stream, scope.Target.TargetIdentity);
        stream.WriteByte(SnapshotRank(scope.Boundary.SnapshotKind));
        WriteText(stream, scope.Boundary.BoundaryIdentity);
        WriteInt64(stream, scope.Boundary.StartedAtUtc.UtcTicks);
        WriteInt64(stream, scope.Boundary.CompletedAtUtc.UtcTicks);
    }

    private static void WriteUsage(
        Stream stream,
        SemanticResourceLocalUsageMirror usage)
    {
        WriteInt64(stream, usage.GeneratedBytes);
        WriteUInt32(stream, checked((uint)usage.LayerDepth));
        WriteInt64(stream, usage.LayerNodes);
        WriteInt64(stream, usage.AdditionalComplexity);
    }

    private static void WriteComponent(
        Stream stream,
        ComponentTypeIdentity component)
    {
        WriteText(stream, component.ComponentKey);
        WriteText(stream, component.ComponentVersion);
        WriteText(stream, component.AssemblyName);
        WriteText(stream, component.TypeName);
    }

    private static void WriteNullableDigest(
        Stream stream,
        ExactSha256Digest? digest)
    {
        stream.WriteByte(digest is null ? (byte)0 : (byte)1);
        if (digest is not null)
        {
            WriteText(stream, digest.Value);
        }
    }

    private static byte LeafRank(AdmissionProofKind kind) =>
        kind.Equals(AdmissionProofKind.Observed) ? (byte)0 :
        kind.Equals(AdmissionProofKind.Failed) ? (byte)1 :
        kind.Equals(AdmissionProofKind.NoInput) ? (byte)2 :
        throw new InvalidOperationException();

    private static byte SurfaceRank(SurfaceKind surface) =>
        surface.Equals(SurfaceKind.Repository) ? (byte)0 :
        surface.Equals(SurfaceKind.Provider) ? (byte)1 :
        surface.Equals(SurfaceKind.Workflow) ? (byte)2 :
        surface.Equals(SurfaceKind.Release) ? (byte)3 :
        throw new InvalidOperationException();

    private static byte SnapshotRank(SnapshotKind snapshot) =>
        snapshot.Equals(SnapshotKind.ExactCommit) ? (byte)0 :
        snapshot.Equals(SnapshotKind.Candidate) ? (byte)1 :
        snapshot.Equals(SnapshotKind.ProviderEvent) ? (byte)2 :
        snapshot.Equals(SnapshotKind.ProviderFullInventory) ? (byte)3 :
        snapshot.Equals(SnapshotKind.CapturedEvidence) ? (byte)4 :
        throw new InvalidOperationException();

    private static byte StatusRank(AcquisitionStatus status) =>
        status.Equals(AcquisitionStatus.Complete) ? (byte)0 :
        status.Equals(AcquisitionStatus.Incomplete) ? (byte)1 :
        status.Equals(AcquisitionStatus.Failed) ? (byte)2 :
        throw new InvalidOperationException();

    internal static void WriteText(Stream stream, string value)
    {
        var bytes = Utf8.GetBytes(value);
        WriteBytes(stream, bytes);
    }

    internal static void WriteBytes(Stream stream, ReadOnlySpan<byte> bytes)
    {
        WriteUInt32(stream, checked((uint)bytes.Length));
        WriteRaw(stream, bytes);
    }

    internal static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> buffer = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(buffer, value);
        WriteRaw(stream, buffer);
    }

    internal static void WriteInt64(Stream stream, long value)
    {
        Span<byte> buffer = stackalloc byte[8];
        BinaryPrimitives.WriteInt64BigEndian(buffer, value);
        WriteRaw(stream, buffer);
    }

    internal static void WriteRaw(Stream stream, ReadOnlySpan<byte> bytes) =>
        stream.Write(bytes);
}

internal static class IndependentAdmissionFrame
{
    internal static byte[] WriteInstruction(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction)
    {
        Assert.Equal(manifest.ManifestDigest, instruction.ManifestDigest);
        using var stream = new MemoryStream();
        stream.Write("protocol.test.admission-instruction/1\n"u8);
        AdmissionMirrorFrame.WriteText(stream, instruction.SlotKey);
        AdmissionMirrorFrame.WriteText(stream, manifest.ManifestDigest.Value);
        stream.WriteByte(instruction.Kind.Equals(AdmissionProofKind.Observed)
            ? (byte)0
            : instruction.Kind.Equals(AdmissionProofKind.Failed)
                ? (byte)1
                : (byte)2);
        AdmissionMirrorFrame.WriteText(stream, instruction.ContractKey);
        AdmissionMirrorFrame.WriteText(stream, instruction.ContractVersion);
        AdmissionMirrorFrame.WriteText(stream, instruction.MaterialRole);
        AdmissionMirrorFrame.WriteRequest(stream, instruction.Request);
        return stream.ToArray();
    }

    internal static byte[] WriteReceipt(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        IAdmissionProofCandidate candidate) =>
        AdmissionMirrorFrame.WriteReceipt(manifest, instruction, candidate);
}
