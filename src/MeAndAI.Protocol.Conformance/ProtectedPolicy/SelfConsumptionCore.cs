using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal sealed class SelfConsumptionCore
{
    private const int MaximumReviewedDifferences = 100_000;
    private const long MaximumCanonicalSetBytes = 67_108_864;

    private SelfConsumptionCore()
    {
    }

    internal static SelfConsumptionQualification Qualify(
        CompleteCatalogSnapshot catalog,
        PredecessorTrustPayload predecessorPayload,
        ProtectedAuthorityEnvelope predecessorProof,
        RuntimeQualificationBinding candidate,
        ActivatedExtensionPolicy activePolicy,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        CandidateIndependentQualificationInput candidateIndependentInput,
        IEnumerable<ReviewedOutcomeDifference> reviewedDifferences)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(predecessorPayload);
        ArgumentNullException.ThrowIfNull(predecessorProof);
        ArgumentNullException.ThrowIfNull(candidate);
        ArgumentNullException.ThrowIfNull(activePolicy);
        ArgumentNullException.ThrowIfNull(predecessorOverlap);
        ArgumentNullException.ThrowIfNull(candidateOverlap);
        ArgumentNullException.ThrowIfNull(candidateIndependentInput);
        ArgumentNullException.ThrowIfNull(reviewedDifferences);

        var anchor = CurrentAnchor(activePolicy);
        var predecessorProjection = ValidatePredecessor(
            catalog,
            predecessorPayload,
            predecessorProof,
            activePolicy,
            predecessorOverlap,
            anchor,
            out var predecessorTrust);
        var candidateProjection = ValidateCandidate(
            predecessorPayload,
            candidate,
            activePolicy,
            candidateOverlap,
            candidateIndependentInput,
            anchor,
            out var independentProjection);
        var reviewed = ValidateDifferences(
            predecessorPayload,
            predecessorProjection,
            candidateProjection,
            reviewedDifferences);
        var candidateIndependent = CandidateIndependentQualification.Create(
            candidateIndependentInput);
        var isQualified = independentProjection.Digest.Equals(
            predecessorPayload.IndependentExpectedOutcomeSetDigest);
        return new SelfConsumptionQualification(
            predecessorTrust,
            candidate,
            predecessorOverlap,
            candidateOverlap,
            candidateIndependent,
            reviewed,
            hasUnexplainedDifference: !isQualified,
            isQualified);
    }

    internal static ExactSha256Digest ComputeReviewedDifferenceSetDigest(
        IReadOnlyList<ReviewedOutcomeDifference> rows)
    {
        ArgumentNullException.ThrowIfNull(rows);
        ValidateReviewedBounds(rows);
        return ProtectedPolicyFrame.Hash(
            "protocol.reviewed-outcome-difference-set/1\n",
            stream =>
            {
                ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Count));
                foreach (var row in rows)
                {
                    ProtectedPolicyFrame.String(stream, row.Outcome.RowKey);
                    ProtectedPolicyFrame.Digest(
                        stream,
                        row.PredecessorOutcomeDigest);
                    ProtectedPolicyFrame.Digest(
                        stream,
                        row.CandidateOutcomeDigest);
                    ProtectedPolicyFrame.String(
                        stream,
                        row.ChangeAuthority.Value);
                    ProtectedPolicyFrame.Digest(
                        stream,
                        row.QualificationEvidenceDigest);
                }
            });
    }

    private static ProtectedOutcomeSetProjection ValidatePredecessor(
        CompleteCatalogSnapshot catalog,
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof,
        ActivatedExtensionPolicy active,
        ProtectedPolicyEvaluation evaluation,
        ExactSha256Digest anchor,
        out PredecessorTrustBinding trust)
    {
        if (!active.Policy.PredecessorVerifier.Verify(payload, proof))
        {
            throw PredecessorInvalid();
        }

        try
        {
            trust = PredecessorTrustBinding.Create(payload, proof);
        }
        catch (ArgumentException)
        {
            throw PredecessorInvalid();
        }

        if (!ReferenceEquals(evaluation.ActiveExtensions, active) ||
            !ReferenceEquals(evaluation.Baseline.Catalog, catalog) ||
            !ActiveInternallyValid(active) ||
            !payload.CurrentTrustAnchorDigest.Equals(anchor) ||
            !payload.ExpectedAuthorityRecordDigest.Equals(
                active.ActivationRecordDigest) ||
            payload.AuthorityEpoch != active.ActivationEpoch ||
            !RuntimeEquals(payload.Predecessor, evaluation.RuntimeBinding) ||
            !RuntimeMatchesEvaluation(evaluation, anchor) ||
            !payload.PredecessorOverlapEvidenceSetDigest.Equals(
                evaluation.EvidenceSetDigest) ||
            !payload.PredecessorOverlapOutcomeSetDigest.Equals(
                evaluation.OutcomeSetDigest))
        {
            throw PredecessorInvalid();
        }

        return Project(evaluation, ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);
    }

    private static ProtectedOutcomeSetProjection ValidateCandidate(
        PredecessorTrustPayload payload,
        RuntimeQualificationBinding candidate,
        ActivatedExtensionPolicy predecessorActive,
        ProtectedPolicyEvaluation overlap,
        CandidateIndependentQualificationInput independentInput,
        ExactSha256Digest anchor,
        out ProtectedOutcomeSetProjection independentProjection)
    {
        var independent = independentInput.Evaluation;
        if (!candidate.BindingDigest.Equals(payload.ExpectedCandidateBindingDigest) ||
            candidate.BindingDigest.Equals(payload.Predecessor.BindingDigest) ||
            !RuntimeEquals(candidate, overlap.RuntimeBinding) ||
            !RuntimeEquals(candidate, independent.RuntimeBinding) ||
            !ReferenceEquals(overlap.ActiveExtensions, independent.ActiveExtensions) ||
            !ActivePairMatches(overlap.ActiveExtensions, independent.ActiveExtensions) ||
            !SemanticAuthorityMatches(
                predecessorActive,
                overlap.ActiveExtensions) ||
            !ActiveInternallyValid(overlap.ActiveExtensions) ||
            !candidate.TrustAnchorDigest.Equals(anchor) ||
            !RuntimeMatchesEvaluation(overlap, anchor) ||
            !RuntimeMatchesEvaluation(independent, anchor) ||
            !payload.CandidateOverlapEvidenceSetDigest.Equals(
                overlap.EvidenceSetDigest) ||
            payload.CandidateOverlapEvidenceSetDigest.Equals(
                payload.PredecessorOverlapEvidenceSetDigest) ||
            !IndependentMatches(payload, independentInput) ||
            payload.IndependentEvidenceSetDigest.Equals(
                payload.CandidateOverlapEvidenceSetDigest))
        {
            throw CandidateInvalid();
        }

        var overlapProjection = Project(
            overlap,
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);
        independentProjection = Project(
            independent,
            ProtectedPolicyIntegrityCode.CandidateSelfCertification);
        return overlapProjection;
    }

    private static IReadOnlyList<ReviewedOutcomeDifference> ValidateDifferences(
        PredecessorTrustPayload payload,
        ProtectedOutcomeSetProjection predecessor,
        ProtectedOutcomeSetProjection candidate,
        IEnumerable<ReviewedOutcomeDifference> assertions)
    {
        if (predecessor.Entries.Count != candidate.Entries.Count)
        {
            throw DifferentialInvalid();
        }

        var actual = new List<KeyValuePair<string, DigestPair>>();
        for (var index = 0; index < predecessor.Entries.Count; index++)
        {
            var before = predecessor.Entries[index];
            var after = candidate.Entries[index];
            if (!string.Equals(before.Key, after.Key, StringComparison.Ordinal))
            {
                throw DifferentialInvalid();
            }
            if (!before.Value.Equals(after.Value))
            {
                if (actual.Count >= MaximumReviewedDifferences)
                {
                    throw ResourceLimit();
                }
                actual.Add(KeyValuePair.Create(
                    before.Key,
                    new DigestPair(before.Value, after.Value)));
            }
        }

        var asserted = new Dictionary<string, ReviewedOutcomeDifference>(
            StringComparer.Ordinal);
        var assertedBytes = ReviewedFrameHeaderBytes();
        foreach (var row in assertions)
        {
            if (row is null)
            {
                throw DifferentialInvalid();
            }
            if (asserted.Count >= MaximumReviewedDifferences)
            {
                throw ResourceLimit();
            }
            assertedBytes = AddReviewedRowBytes(assertedBytes, row);
            if (!asserted.TryAdd(row.Outcome.RowKey, row))
            {
                throw DifferentialInvalid();
            }
        }

        if (asserted.Count != actual.Count)
        {
            throw DifferentialInvalid();
        }

        var ordered = new List<ReviewedOutcomeDifference>(actual.Count);
        foreach (var entry in actual)
        {
            if (!asserted.TryGetValue(entry.Key, out var row) ||
                !row.PredecessorOutcomeDigest.Equals(entry.Value.Predecessor) ||
                !row.CandidateOutcomeDigest.Equals(entry.Value.Candidate))
            {
                throw DifferentialInvalid();
            }
            ordered.Add(row);
        }

        var frozen = Array.AsReadOnly(ordered.ToArray());
        if (!ComputeReviewedDifferenceSetDigest(frozen).Equals(
                payload.ReviewedDifferenceSetDigest))
        {
            throw DifferentialInvalid();
        }
        return frozen;
    }

    private static ProtectedOutcomeSetProjection Project(
        ProtectedPolicyEvaluation evaluation,
        ProtectedPolicyIntegrityCode failureCode)
    {
        try
        {
            var projection = DebtEnforcementCore.ProjectOutcomeSet(evaluation);
            if (!projection.Digest.Equals(evaluation.OutcomeSetDigest))
            {
                throw new ProtectedPolicyIntegrityException(failureCode);
            }
            return projection;
        }
        catch (ProtectedPolicyIntegrityException error)
            when (!error.Code.Equals(
                ProtectedPolicyIntegrityCode.ResourceLimitExceeded) &&
                  !error.Code.Equals(failureCode))
        {
            throw new ProtectedPolicyIntegrityException(failureCode);
        }
        catch (ArgumentException)
        {
            throw new ProtectedPolicyIntegrityException(failureCode);
        }
    }

    private static bool RuntimeMatchesEvaluation(
        ProtectedPolicyEvaluation evaluation,
        ExactSha256Digest anchor)
    {
        var active = evaluation.ActiveExtensions;
        var runtimeArtifact = active.PolicyPackBinding.Artifacts.SingleOrDefault(
            static row => string.Equals(
                row.ArtifactKey,
                "protocol.artifact.conformance-runtime",
                StringComparison.Ordinal));
        if (runtimeArtifact is null)
        {
            return false;
        }
        var catalog = evaluation.Baseline.Catalog;
        var expected = RuntimeQualificationBinding.Create(
            catalog.ProtocolVersion,
            active.ActivationPayload.ActivatedTargetCommit,
            catalog.ManifestDigest,
            catalog.CompleteInventoryDigest,
            active.PolicyPackBinding.BindingDigest,
            runtimeArtifact.FileDigest,
            anchor);
        return RuntimeEquals(expected, evaluation.RuntimeBinding) &&
               active.ActivationPayload.ManifestDigest.Equals(
                   catalog.ManifestDigest);
    }

    private static bool RuntimeEquals(
        RuntimeQualificationBinding left,
        RuntimeQualificationBinding right) =>
        string.Equals(
            left.ProtocolVersion,
            right.ProtocolVersion,
            StringComparison.Ordinal) &&
        string.Equals(left.SourceCommit, right.SourceCommit, StringComparison.Ordinal) &&
        left.ManifestDigest.Equals(right.ManifestDigest) &&
        left.CatalogDigest.Equals(right.CatalogDigest) &&
        left.PolicyPackBindingDigest.Equals(right.PolicyPackBindingDigest) &&
        left.RuntimeArtifactDigest.Equals(right.RuntimeArtifactDigest) &&
        left.TrustAnchorDigest.Equals(right.TrustAnchorDigest) &&
        left.BindingDigest.Equals(right.BindingDigest);

    private static bool ActiveInternallyValid(ActivatedExtensionPolicy active) =>
        active.ActivationPayload.ActiveSnapshotDigest.Equals(
            active.Snapshot.SnapshotDigest) &&
        active.ActivationPayload.AuthoritySetDigest.Equals(active.AuthoritySetDigest) &&
        active.ActivationPayload.ExpectedAuthorityRecordDigest.Equals(
            active.ActivationRecordDigest) &&
        active.ActivationPayload.ActivationEpoch == active.ActivationEpoch &&
        active.PolicyPackBinding.ManifestDigest.Equals(
            active.ActivationPayload.ManifestDigest) &&
        active.PolicyPackBinding.ExtensionExportDigest.Equals(
            active.Policy.ExportDigest);

    private static bool ActivePairMatches(
        ActivatedExtensionPolicy left,
        ActivatedExtensionPolicy right) =>
        left.ActivationRecordDigest.Equals(right.ActivationRecordDigest) &&
        left.ActivationEpoch == right.ActivationEpoch &&
        left.ActivationPayload.PayloadDigest.Equals(
            right.ActivationPayload.PayloadDigest) &&
        left.Snapshot.SnapshotDigest.Equals(right.Snapshot.SnapshotDigest) &&
        left.PolicyPackBinding.BindingDigest.Equals(
            right.PolicyPackBinding.BindingDigest);

    private static bool SemanticAuthorityMatches(
        ActivatedExtensionPolicy predecessor,
        ActivatedExtensionPolicy candidate) =>
        predecessor.Snapshot.SnapshotDigest.Equals(candidate.Snapshot.SnapshotDigest) &&
        predecessor.AuthoritySetDigest.Equals(candidate.AuthoritySetDigest) &&
        predecessor.Policy.ExportDigest.Equals(candidate.Policy.ExportDigest) &&
        predecessor.Policy.AuthorityPublicKeyDigest.Equals(
            candidate.Policy.AuthorityPublicKeyDigest);

    private static bool IndependentMatches(
        PredecessorTrustPayload payload,
        CandidateIndependentQualificationInput input) =>
        string.Equals(
            payload.IndependentFixtureSetKey,
            input.FixtureSetKey,
            StringComparison.Ordinal) &&
        string.Equals(
            payload.IndependentFixtureSetVersion,
            input.FixtureSetVersion,
            StringComparison.Ordinal) &&
        payload.IndependentFixtureSetDigest.Equals(input.FixtureSetDigest) &&
        payload.IndependentEvidenceSetDigest.Equals(
            input.Evaluation.EvidenceSetDigest) &&
        payload.IndependentExpectedOutcomeSetDigest.Equals(
            input.ExpectedOutcomeSetDigest);

    private static ExactSha256Digest CurrentAnchor(ActivatedExtensionPolicy active) =>
        ComputeCurrentAnchorDigest(
            active.Policy.AuthorityPublicKeyDigest,
            active.Policy.ExportDigest,
            active.Snapshot.SnapshotDigest,
            active.AuthoritySetDigest);

    private static ExactSha256Digest ComputeCurrentAnchorDigest(
        ExactSha256Digest authorityPublicKeyDigest,
        ExactSha256Digest exportDigest,
        ExactSha256Digest snapshotDigest,
        ExactSha256Digest authoritySetDigest) =>
        ProtectedPolicyFrame.Hash(
            "protocol.protected-current-trust-anchor/1\n",
            stream =>
            {
                ProtectedPolicyFrame.Digest(stream, authorityPublicKeyDigest);
                ProtectedPolicyFrame.Digest(stream, exportDigest);
                ProtectedPolicyFrame.Digest(stream, snapshotDigest);
                ProtectedPolicyFrame.Digest(stream, authoritySetDigest);
            });

    private static void ValidateReviewedBounds(
        IReadOnlyList<ReviewedOutcomeDifference> rows)
    {
        if (rows.Count > MaximumReviewedDifferences)
        {
            throw ResourceLimit();
        }

        var bytes = ReviewedFrameHeaderBytes();
        string? previous = null;
        foreach (var row in rows)
        {
            if (row is null)
            {
                throw DifferentialInvalid();
            }
            var key = row.Outcome.RowKey;
            if (previous is not null && CompareOutcomeKeys(previous, key) >= 0)
            {
                throw DifferentialInvalid();
            }
            bytes = AddReviewedRowBytes(bytes, row);
            previous = key;
        }
    }

    private static long ReviewedFrameHeaderBytes() =>
        "protocol.reviewed-outcome-difference-set/1\n"u8.Length + 4L;

    private static long AddReviewedRowBytes(
        long bytes,
        ReviewedOutcomeDifference row)
    {
        if (!ProtectedPolicyFrame.TryUtf8ByteCount(
                row.Outcome.RowKey,
                out var keyBytes) ||
            !ProtectedPolicyFrame.TryUtf8ByteCount(
                row.ChangeAuthority.Value,
                out var authorityBytes))
        {
            throw DifferentialInvalid();
        }
        try
        {
            var result = checked(
                bytes + 4L + keyBytes + 32L + 32L + 4L +
                authorityBytes + 32L);
            return result <= MaximumCanonicalSetBytes
                ? result
                : throw ResourceLimit();
        }
        catch (OverflowException)
        {
            throw ResourceLimit();
        }
    }

    private static int CompareOutcomeKeys(string left, string right)
    {
        var leftRule = left.StartsWith("rule:", StringComparison.Ordinal);
        var rightRule = right.StartsWith("rule:", StringComparison.Ordinal);
        if (leftRule || rightRule)
        {
            return leftRule == rightRule
                ? StringComparer.Ordinal.Compare(left, right)
                : leftRule ? -1 : 1;
        }
        return GlobalRank(left).CompareTo(GlobalRank(right));
    }

    private static int GlobalRank(string key) => key switch
    {
        "global:dispositions" => 0,
        "global:verdict" => 1,
        "global:enforcement" => 2,
        _ => throw DifferentialInvalid(),
    };

    private static ProtectedPolicyIntegrityException PredecessorInvalid() =>
        new(ProtectedPolicyIntegrityCode.PredecessorTrustInvalid);

    private static ProtectedPolicyIntegrityException CandidateInvalid() =>
        new(ProtectedPolicyIntegrityCode.CandidateSelfCertification);

    private static ProtectedPolicyIntegrityException DifferentialInvalid() =>
        new(ProtectedPolicyIntegrityCode.DifferentialUnexplained);

    private static ProtectedPolicyIntegrityException ResourceLimit() =>
        new(ProtectedPolicyIntegrityCode.ResourceLimitExceeded);

    private sealed record DigestPair(
        ExactSha256Digest Predecessor,
        ExactSha256Digest Candidate);
}
