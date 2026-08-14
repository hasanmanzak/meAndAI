using System.Security.Cryptography;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBSealedContextTests
{
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string TreeRequirement =
        "protocol.requirement.repository-tree";
    private const string Commit =
        "0123456789abcdef0123456789abcdef01234567";

    [Fact]
    [Trait("ContractSlice", "B")]
    [Trait("Scenario", "TEST-0210")]
    public void Seals_exact_context_proof_and_root_references()
    {
        var manifest =
            ContractSliceBAdmissionProofTests.CreateAdmissionManifest();
        var aggregate = Assert.IsType<AdmissionAggregateMirror>(
            ContractSliceBAdmissionProofTests.ExecuteContract());

        AssertNegativeMatrix(manifest, aggregate);

        var projection = Assert.IsType<SealedContextProjectionMirror>(
            ContractSliceBSealedContextCoordinatorMirror.Seal(
                manifest,
                aggregate));

        AssertProjection(manifest, aggregate, projection);
    }

    private static void AssertProjection(
        FinalizedPolicyManifest manifest,
        AdmissionAggregateMirror aggregate,
        SealedContextProjectionMirror projection)
    {
        var observed = Assert.IsType<ObservedAdmissionReceiptMirror>(
            aggregate.Receipts[2]);
        var context = observed.Result.Context;
        var root = Assert.Single(context.References);

        Assert.Equal(manifest.AuthorityKind, projection.Context.AuthorityKind);
        Assert.Equal(manifest.ManifestDigest, projection.Context.ManifestDigest);
        Assert.Equal(
            manifest.Slice!.CatalogVersion,
            projection.Context.CatalogVersion);
        Assert.Equal([TreeSlot], projection.Context.AdmittedSlotKeys);
        Assert.Equal([context.Scope], projection.Context.Scopes);

        AssertReference(
            projection.ContextProof,
            QualifiedEvidenceReferenceKind.ContextProof,
            manifest,
            observed,
            context.Scope);
        Assert.Null(projection.ContextProof.Root);
        Assert.Null(projection.ContextProof.Location);

        var rootReference = Assert.Single(projection.Roots);
        AssertReference(
            rootReference,
            QualifiedEvidenceReferenceKind.Root,
            manifest,
            observed,
            context.Scope);
        Assert.Same(root, rootReference.Root);
        Assert.Same(root.Location, rootReference.Location);

        Assert.Empty(projection.ContextProof.Derivations);
        Assert.Empty(rootReference.Derivations);
        Assert.Null(projection.ContextProof.ExpectedSelectorParentKind);
        Assert.Null(rootReference.ExpectedSelectorParentKind);
        Assert.Null(projection.ContextProof.Selector);
        Assert.Null(rootReference.Selector);
    }

    private static void AssertReference(
        QualifiedEvidenceReference reference,
        QualifiedEvidenceReferenceKind kind,
        FinalizedPolicyManifest manifest,
        ObservedAdmissionReceiptMirror observed,
        EvidenceScope scope)
    {
        Assert.Equal(kind, reference.Kind);
        Assert.Equal(manifest.ManifestDigest, reference.ManifestDigest);
        Assert.Equal(manifest.Slice!.CatalogVersion, reference.CatalogVersion);
        Assert.Equal(TreeSlot, reference.SlotKey);
        Assert.Equal(TreeRequirement, reference.RequirementKey);
        Assert.Same(scope, reference.Scope);
        Assert.Equal(
            observed.ReceiptDigest,
            reference.QualificationProofDigest);
    }

    private static void AssertNegativeMatrix(
        FinalizedPolicyManifest manifest,
        AdmissionAggregateMirror aggregate)
    {
        Assert.Equal(
            "manifest",
            Assert.Throws<ArgumentNullException>(() =>
                ContractSliceBSealedContextCoordinatorMirror.Seal(
                    null!, aggregate)).ParamName);
        Assert.Equal(
            "aggregate",
            Assert.Throws<ArgumentNullException>(() =>
                ContractSliceBSealedContextCoordinatorMirror.Seal(
                    manifest, null!)).ParamName);

        Reject(CatalogIntegrityCode.ManifestInvalid, () => Seal(
            manifest,
            aggregate with
            {
                AuthorityKind = CatalogAuthorityKind.CompleteProtocolSnapshot,
            }));
        Reject(CatalogIntegrityCode.ManifestInvalid, () => Seal(
            manifest,
            aggregate with
            {
                ManifestDigest = ZeroDigest(),
            }));
        Reject(CatalogIntegrityCode.ManifestInvalid, () => Seal(
            manifest,
            aggregate with
            {
                CatalogVersion = CatalogVersion.Create(2),
            }));

        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with { LifecycleClosed = false }));
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with { LeafCounts = (2, 0, 1) }));
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with
            {
                Receipts = aggregate.Receipts.Reverse().ToArray(),
            }));
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with
            {
                Receipts =
                [aggregate.Receipts[0], aggregate.Receipts[0],
                    aggregate.Receipts[2]],
            }));
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with
            {
                Receipts =
                [aggregate.Receipts[0], null!, aggregate.Receipts[2]],
            }));

        var observed = Assert.IsType<ObservedAdmissionReceiptMirror>(
            aggregate.Receipts[2]);
        var foreign = ObservedAdmissionReceiptMirror.Create(
            "protocol.slot.foreign",
            observed.ReceiptDigest,
            observed.CanonicalBytes,
            observed.Result,
            observed.State);
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with
            {
                Receipts =
                [aggregate.Receipts[0], aggregate.Receipts[1], foreign],
            }));

        var changedBytes = observed.CanonicalBytes.ToArray();
        changedBytes[^1] ^= 0x01;
        var rehashed = ObservedAdmissionReceiptMirror.Create(
            observed.SlotKey,
            Hash(changedBytes),
            changedBytes,
            observed.Result,
            observed.State);
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with
            {
                Receipts =
                [aggregate.Receipts[0], aggregate.Receipts[1], rehashed],
            }));

        var binding = observed.State.Binding;
        var equalButDetachedBinding = EvidenceBinding.Create(
            binding.Payload,
            binding.Location,
            binding.RequirementKeys,
            binding.CapturedAtUtc);
        var detachedState = ClosedQualificationStateMirror.Create(
            observed.State.InstructionDigest,
            observed.State.DemandDigest,
            observed.State.OutputModel,
            equalButDetachedBinding,
            observed.State.Codec,
            observed.State.ClaimedUsage,
            observed.State.MeasuredUsage,
            observed.State.CacheDisposition);
        var detached = ObservedAdmissionReceiptMirror.Create(
            observed.SlotKey,
            observed.ReceiptDigest,
            observed.CanonicalBytes,
            observed.Result,
            detachedState);
        Reject(CatalogIntegrityCode.AdmissionProofInvalid, () => Seal(
            manifest,
            aggregate with
            {
                Receipts =
                [aggregate.Receipts[0], aggregate.Receipts[1], detached],
            }));
    }

    private static void Seal(
        FinalizedPolicyManifest manifest,
        AdmissionAggregateMirror aggregate) =>
        _ = ContractSliceBSealedContextCoordinatorMirror.Seal(
            manifest,
            aggregate);

    private static void Reject(CatalogIntegrityCode code, Action action)
    {
        var exception = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Same(code, exception.Code);
    }

    private static ExactSha256Digest Hash(ReadOnlySpan<byte> bytes) =>
        ExactSha256Digest.FromHashBytes(SHA256.HashData(bytes));

    private static ExactSha256Digest ZeroDigest() =>
        ExactSha256Digest.Parse(new string('0', 64));
}

internal sealed record SealedContextProjectionMirror(
    SealedEvaluationContext Context,
    QualifiedEvidenceReference ContextProof,
    IReadOnlyList<QualifiedEvidenceReference> Roots);

internal static class ContractSliceBSealedContextCoordinatorMirror
{
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string TreeRequirement =
        "protocol.requirement.repository-tree";
    private const string Commit =
        "0123456789abcdef0123456789abcdef01234567";

    internal static SealedContextProjectionMirror? Seal(
        FinalizedPolicyManifest manifest,
        AdmissionAggregateMirror aggregate)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(aggregate);

        if (!manifest.AuthorityKind.Equals(
                CatalogAuthorityKind.QualificationSlice) ||
            manifest.Slice is not CatalogSliceDeclaration slice ||
            manifest.CompleteCatalog is not null ||
            !aggregate.AuthorityKind.Equals(manifest.AuthorityKind) ||
            !aggregate.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !aggregate.CatalogVersion.Equals(slice.CatalogVersion))
        {
            throw ManifestInvalid();
        }

        var receipts = aggregate.Receipts?.ToArray();
        if (!aggregate.LifecycleClosed ||
            aggregate.LeafCounts != (1, 1, 1) ||
            receipts is null ||
            receipts.Length != 3 ||
            receipts.Any(receipt => receipt is null) ||
            receipts[0] is not FailedAdmissionReceiptMirror ||
            receipts[1] is not NoInputAdmissionReceiptMirror ||
            receipts[2] is not ObservedAdmissionReceiptMirror ||
            !receipts.Select(receipt => receipt.SlotKey).SequenceEqual(
                [
                    "protocol.slot.provider-governed-text",
                    "protocol.slot.repository-target-resolution",
                    TreeSlot,
                ],
                StringComparer.Ordinal))
        {
            throw AdmissionInvalid();
        }

        foreach (var receipt in receipts)
        {
            ValidateCanonicalReceipt(manifest, slice, receipt);
        }

        var observed = (ObservedAdmissionReceiptMirror)receipts[2];
        var treeSlot = FindSlot(slice, TreeSlot, expectedOccurrences: 2);
        if (!string.Equals(
                treeSlot.Requirement.Key,
                TreeRequirement,
                StringComparison.Ordinal))
        {
            throw AdmissionInvalid();
        }

        ValidateObserved(manifest, treeSlot, observed);

        var context = observed.Result.Context;
        var root = context.References[0];
        var contextProof = new QualifiedEvidenceReference(
            QualifiedEvidenceReferenceKind.ContextProof,
            manifest.ManifestDigest,
            slice.CatalogVersion,
            TreeSlot,
            TreeRequirement,
            context.Scope,
            observed.ReceiptDigest,
            null,
            null,
            [],
            null,
            null);
        var rootReference = new QualifiedEvidenceReference(
            QualifiedEvidenceReferenceKind.Root,
            manifest.ManifestDigest,
            slice.CatalogVersion,
            TreeSlot,
            TreeRequirement,
            context.Scope,
            observed.ReceiptDigest,
            root,
            root.Location,
            [],
            null,
            null);
        var sealedContext = new SealedEvaluationContext(
            manifest.AuthorityKind,
            manifest.ManifestDigest,
            slice.CatalogVersion,
            [TreeSlot],
            [context.Scope]);
        var projection = new SealedContextProjectionMirror(
            sealedContext,
            contextProof,
            Array.AsReadOnly([rootReference]));

        return projection;
    }

    private static void ValidateCanonicalReceipt(
        FinalizedPolicyManifest manifest,
        CatalogSliceDeclaration slice,
        AdmissionReceiptMirror receipt)
    {
        var kind = receipt switch
        {
            ObservedAdmissionReceiptMirror => AdmissionProofKind.Observed,
            FailedAdmissionReceiptMirror => AdmissionProofKind.Failed,
            NoInputAdmissionReceiptMirror => AdmissionProofKind.NoInput,
            _ => throw AdmissionInvalid(),
        };
        var request = receipt switch
        {
            ObservedAdmissionReceiptMirror observed => observed.Result.Request,
            FailedAdmissionReceiptMirror failed => failed.Result.Request,
            NoInputAdmissionReceiptMirror noInput => noInput.Request,
            _ => throw AdmissionInvalid(),
        };
        var slot = FindSlot(slice, receipt.SlotKey, expectedOccurrences: null);
        var instruction = AdmissionInstructionMirror.Create(
            manifest,
            slot.SlotKey,
            kind,
            slot.MaterialRole,
            request);
        var expected = receipt switch
        {
            ObservedAdmissionReceiptMirror observed =>
                ObservedQualificationProofMirror.Create(
                    manifest,
                    instruction,
                    observed.Result,
                    [observed.State.Codec],
                    observed.State).CanonicalReceiptBytes,
            FailedAdmissionReceiptMirror failed =>
                FailedAttemptProofMirror.Create(
                    manifest,
                    instruction,
                    failed.Result).CanonicalReceiptBytes,
            NoInputAdmissionReceiptMirror =>
                NoInputRoutingProofMirror.Create(
                    manifest,
                    instruction).CanonicalReceiptBytes,
            _ => throw AdmissionInvalid(),
        };
        var digest = ExactSha256Digest.FromHashBytes(
            SHA256.HashData(receipt.CanonicalBytes.Span));
        if (!receipt.CanonicalBytes.Span.SequenceEqual(expected.Span) ||
            !receipt.ReceiptDigest.Equals(digest))
        {
            throw AdmissionInvalid();
        }
    }

    private static EvidenceSlotDeclaration FindSlot(
        CatalogSliceDeclaration slice,
        string slotKey,
        int? expectedOccurrences)
    {
        var slots = slice.Rules
            .SelectMany(rule =>
                rule.ApplicabilitySlots.Concat(rule.EvaluationSlots))
            .Where(slot => string.Equals(
                slot.SlotKey,
                slotKey,
                StringComparison.Ordinal))
            .ToArray();
        if (slots.Length == 0 ||
            (expectedOccurrences.HasValue &&
             slots.Length != expectedOccurrences.Value) ||
            slots.Skip(1).Any(slot => !SlotsEqual(slots[0], slot)))
        {
            throw AdmissionInvalid();
        }

        return slots[0];
    }

    private static bool SlotsEqual(
        EvidenceSlotDeclaration left,
        EvidenceSlotDeclaration right) =>
        string.Equals(left.SlotKey, right.SlotKey, StringComparison.Ordinal) &&
        left.Requirement.Equals(right.Requirement) &&
        left.ProfileSurfaces.Equals(right.ProfileSurfaces) &&
        string.Equals(
            left.MaterialRole,
            right.MaterialRole,
            StringComparison.Ordinal) &&
        string.Equals(
            left.TargetSelectorKey,
            right.TargetSelectorKey,
            StringComparison.Ordinal) &&
        left.Capabilities.SequenceEqual(right.Capabilities);

    private static void ValidateObserved(
        FinalizedPolicyManifest manifest,
        EvidenceSlotDeclaration slot,
        ObservedAdmissionReceiptMirror observed)
    {
        var result = observed.Result;
        var context = result.Context;
        if (!result.Request.Equals(context.Request) ||
            !context.Status.Equals(AcquisitionStatus.Complete) ||
            context.Request.RequestedRequirements.Count != 1 ||
            !context.Request.RequestedRequirements[0].Equals(slot.Requirement) ||
            !context.Scope.Target.Equals(context.Request.Target) ||
            !context.Scope.Target.Surface.Equals(SurfaceKind.Repository) ||
            !context.Scope.Target.SnapshotKind.Equals(SnapshotKind.ExactCommit) ||
            !string.Equals(
                context.Scope.Target.TargetIdentity,
                Commit,
                StringComparison.Ordinal) ||
            !context.Scope.Boundary.SnapshotKind.Equals(
                SnapshotKind.ExactCommit) ||
            !string.Equals(
                context.Scope.Boundary.BoundaryIdentity,
                Commit,
                StringComparison.Ordinal) ||
            context.RequirementAcquisitions.Count != 1 ||
            !context.RequirementAcquisitions[0].Status.Equals(
                AcquisitionStatus.Complete) ||
            context.Bindings.Count != 1 ||
            context.Pages.Count != 0 ||
            context.SourceObjectCount != 1 ||
            context.References.Count != 1)
        {
            throw AdmissionInvalid();
        }

        var binding = context.Bindings[0];
        var root = context.References[0];
        var schema = manifest.SchemaRegistry.PayloadSchemas.SingleOrDefault(
            candidate => string.Equals(
                    candidate.SchemaKey,
                    slot.Requirement.PayloadSchemaKey,
                    StringComparison.Ordinal) &&
                string.Equals(
                    candidate.SchemaVersion,
                    slot.Requirement.PayloadSchemaVersion,
                    StringComparison.Ordinal));
        if (schema is null ||
            !ReferenceEquals(binding, observed.State.Binding) ||
            binding.Location is not SnapshotEvidenceLocation ||
            !binding.Location.Scope.Equals(context.Scope) ||
            !binding.RequirementKeys.SequenceEqual(
                [TreeRequirement],
                StringComparer.Ordinal) ||
            !string.Equals(
                binding.Payload.SchemaKey,
                slot.Requirement.PayloadSchemaKey,
                StringComparison.Ordinal) ||
            !string.Equals(
                binding.Payload.SchemaVersion,
                slot.Requirement.PayloadSchemaVersion,
                StringComparison.Ordinal) ||
            !observed.State.OutputModel.Equals(schema.OutputModel) ||
            !root.Scope.Equals(context.Scope) ||
            !string.Equals(
                root.SchemaKey,
                binding.Payload.SchemaKey,
                StringComparison.Ordinal) ||
            !string.Equals(
                root.SchemaVersion,
                binding.Payload.SchemaVersion,
                StringComparison.Ordinal) ||
            !root.ContentDigest.Equals(binding.Payload.ContentDigest) ||
            !root.RequirementKeys.SequenceEqual(
                binding.RequirementKeys,
                StringComparer.Ordinal) ||
            !root.CapturedAtUtc.Equals(binding.CapturedAtUtc) ||
            !ReferenceEquals(root.Location, binding.Location))
        {
            throw AdmissionInvalid();
        }
    }

    private static CatalogIntegrityException ManifestInvalid() =>
        new(CatalogIntegrityCode.ManifestInvalid);

    private static CatalogIntegrityException AdmissionInvalid() =>
        new(CatalogIntegrityCode.AdmissionProofInvalid);
}
