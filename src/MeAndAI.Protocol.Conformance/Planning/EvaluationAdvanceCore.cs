using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class EvaluationAdvanceCore
{
    private const string RepositoryTargetSlot =
        "protocol.slot.repository-target-resolution";
    private const string RepositoryTargetIndex =
        "protocol.index.repository-target-resolution";

    internal static EvaluationAdvanceResult Advance(
        KernelPlanningSession session,
        EvaluationPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(plan);
        ArgumentNullException.ThrowIfNull(proofs);
        cancellationToken.ThrowIfCancellationRequested();
        if (!ReferenceEquals(plan.EvidenceSession, session) ||
            !ReferenceEquals(plan.Applicability.Plan.EvidenceSession, session) ||
            !plan.Applicability.Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !plan.Applicability.Context.CatalogVersion.Equals(session.CatalogVersion))
        {
            InvalidPlan();
        }

        session.BeginEvaluationAdvance(plan);
        try
        {
            var candidates = proofs.Observed.Cast<IAdmissionProofCandidate>()
                .Concat(proofs.Failed)
                .Concat(proofs.NoInput)
                .ToArray();
            if (candidates.Any(candidate => candidate is null) ||
                candidates.Length != plan.Instructions.Count ||
                candidates.Distinct(ReferenceEqualityComparer.Instance).Count() !=
                    candidates.Length)
            {
                InvalidProof();
            }

            var unused = candidates.ToList();
            var attempts = new List<SealedAcquisitionAttempt>();
            foreach (var instruction in plan.Instructions)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var matches = unused.Where(candidate =>
                    candidate.InstructionDigest.Equals(
                        instruction.InstructionDigest)).ToArray();
                if (matches.Length != 1)
                {
                    InvalidProof();
                }

                var candidate = matches[0];
                unused.Remove(candidate);
                var leaf = ApplicabilityClosureCore.ValidateCandidate(
                    session,
                    instruction,
                    candidate);
                attempts.Add(new SealedAcquisitionAttempt(
                    instruction,
                    leaf.Kind,
                    leaf.Status,
                    candidate.ReceiptDigest,
                    leaf.Scope,
                    leaf.Acquisition,
                    leaf.Failures));
            }

            if (unused.Count != 0)
            {
                InvalidProof();
            }

            var outcomes = new List<SealedAcquisitionOutcome>();
            foreach (var slot in plan.Slots.Where(slot =>
                         !plan.Applicability.Context.AdmittedSlotKeys.Contains(
                             slot.SlotKey,
                             StringComparer.Ordinal)))
            {
                cancellationToken.ThrowIfCancellationRequested();
                var slotAttempts = attempts.Where(attempt => string.Equals(
                        attempt.Instruction.Slot.SlotKey,
                        slot.SlotKey,
                        StringComparison.Ordinal))
                    .ToArray();
                var target = ResolveTarget(plan, slot);
                outcomes.Add(string.Equals(
                        slot.SlotKey,
                        RepositoryTargetSlot,
                        StringComparison.Ordinal)
                    ? ProjectedOutcome(session, plan, slot, target, slotAttempts)
                    : StaticOutcome(session, slotAttempts));
            }

            var targetOutcome = outcomes.SingleOrDefault(outcome => string.Equals(
                outcome.Slot.SlotKey,
                RepositoryTargetSlot,
                StringComparison.Ordinal));
            if (targetOutcome is not null &&
                targetOutcome.Status.Equals(AcquisitionStatus.Complete))
            {
                InvokeTargetIndex(session, cancellationToken);
            }

            var allOutcomes = plan.Applicability.Acquisitions
                .Concat(outcomes)
                .OrderBy(outcome => outcome.Slot.SlotKey, StringComparer.Ordinal)
                .ToArray();
            var context = new SealedEvaluationContext(
                session.AuthorityKind,
                session.ManifestDigest,
                session.CatalogVersion,
                allOutcomes
                    .Where(outcome => outcome.Status.Equals(AcquisitionStatus.Complete))
                    .Select(outcome => outcome.Slot.SlotKey)
                    .Distinct(StringComparer.Ordinal)
                    .OrderBy(value => value, StringComparer.Ordinal),
                allOutcomes
                    .Where(outcome => outcome.ContextProof is not null)
                    .Select(outcome => outcome.ContextProof!.Scope)
                    .Distinct()
                    .OrderBy(scope => scope.Target.SubjectIdentity, StringComparer.Ordinal)
                    .ThenBy(scope => scope.Target.SourceIdentity, StringComparer.Ordinal)
                    .ThenBy(scope => scope.Target.Surface.Value, StringComparer.Ordinal));
            EvaluationAdvanceResult? result = new EvaluationClosure(
                checked(plan.CompletedRoundCount + 1),
                plan.Applicability,
                context,
                allOutcomes,
                plan.Applicability.TerminalEvaluations);
            if (result is null)
            {
                session.AbandonEvaluationAdvance(plan);
                return null!;
            }

            session.CompleteEvaluationAdvance(plan);
            return result;
        }
        catch
        {
            session.AbandonEvaluationAdvance(plan);
            throw;
        }
    }

    private static SealedAcquisitionOutcome StaticOutcome(
        KernelPlanningSession session,
        IReadOnlyList<SealedAcquisitionAttempt> attempts)
    {
        if (attempts.Count != 1)
        {
            InvalidProof();
        }

        var attempt = attempts[0];
        var contextProof = attempt.Status.Equals(AcquisitionStatus.Complete)
            ? ContextProof(
                session,
                attempt.Instruction.Slot,
                attempt.Scope!,
                attempt.ReceiptDigest)
            : null;
        return new SealedAcquisitionOutcome(
            attempt.Instruction.Slot,
            attempt.Instruction.Target,
            attempt.Status,
            false,
            ApplicabilityClosureCore.OutcomeDigest(
                session,
                attempt.Instruction,
                attempt),
            attempt.Scope,
            attempt.RequirementAcquisition,
            contextProof,
            [attempt],
            attempt.Failures);
    }

    private static SealedAcquisitionOutcome ProjectedOutcome(
        KernelPlanningSession session,
        EvaluationPlan plan,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        IReadOnlyList<SealedAcquisitionAttempt> attempts)
    {
        EvidenceScope? scope;
        RequirementAcquisition? acquisition;
        AcquisitionStatus status;
        if (attempts.Count == 0)
        {
            var boundary = plan.Applicability.Context.Scopes
                .Select(item => item.Boundary)
                .FirstOrDefault(item => item.SnapshotKind.Equals(target.SnapshotKind)) ??
                throw Error();
            scope = EvidenceScope.Create(target, boundary);
            acquisition = RequirementAcquisition.Create(
                slot.Requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                []);
            status = AcquisitionStatus.Complete;
        }
        else
        {
            status = attempts.Any(attempt =>
                    attempt.Status.Equals(AcquisitionStatus.Failed))
                ? AcquisitionStatus.Failed
                : attempts.All(attempt =>
                    attempt.Status.Equals(AcquisitionStatus.Complete))
                    ? AcquisitionStatus.Complete
                    : AcquisitionStatus.Incomplete;
            scope = status.Equals(AcquisitionStatus.Complete) &&
                    attempts.Select(attempt => attempt.Scope).Distinct().Count() == 1
                ? attempts[0].Scope
                : null;
            acquisition = status.Equals(AcquisitionStatus.Complete) &&
                    attempts.Select(attempt => attempt.RequirementAcquisition)
                        .Distinct().Count() == 1
                ? attempts[0].RequirementAcquisition
                : null;
            if (status.Equals(AcquisitionStatus.Complete) &&
                (scope is null || acquisition is null))
            {
                InvalidProof();
            }
        }

        var digest = AggregateDigest(session, slot, target, status, attempts);
        return new SealedAcquisitionOutcome(
            slot,
            target,
            status,
            true,
            digest,
            scope,
            acquisition,
            status.Equals(AcquisitionStatus.Complete)
                ? ContextProof(session, slot, scope!, digest)
                : null,
            attempts,
            attempts.SelectMany(attempt => attempt.Failures)
                .Distinct()
                .ToArray());
    }

    private static QualifiedEvidenceReference ContextProof(
        KernelPlanningSession session,
        EvidenceSlotDeclaration slot,
        EvidenceScope scope,
        ExactSha256Digest proofDigest) => new(
        QualifiedEvidenceReferenceKind.ContextProof,
        session.ManifestDigest,
        session.CatalogVersion,
        slot.SlotKey,
        slot.Requirement.Key,
        scope,
        proofDigest,
        null,
        null,
        [],
        null,
        null);

    private static ExactSha256Digest AggregateDigest(
        KernelPlanningSession session,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        AcquisitionStatus status,
        IEnumerable<SealedAcquisitionAttempt> attempts)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes(
            "protocol.projected-acquisition-outcome/1\n"));
        WriteText(stream, session.AuthorityKind.Value);
        stream.Write(Convert.FromHexString(session.ManifestDigest.Value));
        WriteText(stream, session.CatalogVersion.Value.ToString(
            System.Globalization.CultureInfo.InvariantCulture));
        WriteText(stream, slot.SlotKey);
        WriteText(stream, target.SubjectIdentity);
        WriteText(stream, target.SourceIdentity);
        WriteText(stream, target.Surface.Value);
        WriteText(stream, target.SnapshotKind.Value);
        WriteText(stream, target.TargetIdentity);
        WriteText(stream, status.Value);
        foreach (var attempt in attempts)
        {
            stream.Write(Convert.FromHexString(
                attempt.Instruction.InstructionDigest.Value));
            stream.Write(Convert.FromHexString(attempt.ReceiptDigest.Value));
        }

        return ExactSha256Digest.FromHashBytes(SHA256.HashData(stream.ToArray()));
    }

    private static AcquisitionTarget ResolveTarget(
        EvaluationPlan plan,
        EvidenceSlotDeclaration slot)
    {
        var matches = plan.Instructions
            .Where(item => ReferenceEquals(item.Slot, slot) ||
                string.Equals(item.Slot.SlotKey, slot.SlotKey,
                    StringComparison.Ordinal))
            .Select(item => item.Target)
            .Distinct()
            .ToArray();
        if (matches.Length == 1)
        {
            return matches[0];
        }

        var surface = slot.TargetSelectorKey switch
        {
            "protocol.target.repository-snapshot" or
            "protocol.target.repository-governed-body-set" or
            "protocol.target.repository-target-resolution-set" =>
                SurfaceKind.Repository,
            "protocol.target.provider-governed-body-set" => SurfaceKind.Provider,
            _ => throw Error(),
        };
        var targets = plan.Applicability.Plan.Targets
            .Where(target => target.Surface.Equals(surface))
            .ToArray();
        return targets.Length == 1 ? targets[0] : throw Error();
    }

    private static void InvokeTargetIndex(
        KernelPlanningSession session,
        CancellationToken cancellationToken)
    {
        var registrations = session.ProducerGraph.IndexRegistrations
            .Where(item => string.Equals(
                item.Declaration.IndexKey,
                RepositoryTargetIndex,
                StringComparison.Ordinal))
            .ToArray();
        if (registrations.Length != 1)
        {
            InvalidPlan();
        }

        registrations[0].Accept(new IndexVisitor(cancellationToken));
    }

    private sealed class IndexVisitor(CancellationToken cancellationToken) :
        IIndexRegistrationVisitor<bool>
    {
        public bool Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability
        {
            var allowance = SemanticResourceAllowance.Create(
                registration.Declaration.Budget,
                SemanticResourceUsage.Create(0, 0, 0, 0));
            var reader = TypedInputReader.Create(
                [],
                [],
                new Dictionary<string, QualifiedEvidenceHandle>(
                    StringComparer.Ordinal),
                RejectingReferences.Instance,
                [],
                []);
            var input = ContextIndexInput<TInput>.Create(
                registration.Binder.Bind(reader),
                allowance,
                RejectingDerivations.Instance);
            var intent = registration.Indexer.Build(input, cancellationToken) ??
                throw Error();
            var product = intent.Accept(CapabilityVisitor<TCapability>.Instance);
            var measured = registration.Indexer.MeasureLocal(
                input,
                product.Value,
                cancellationToken) ?? throw Error();
            if (!SameUsage(product.ClaimedLocalUsage, measured) ||
                !allowance.FitsLocal(measured))
            {
                throw Error();
            }

            return true;
        }
    }

    private sealed class CapabilityVisitor<TCapability> :
        ICapabilityIntentVisitor<TCapability, CapabilityProduct<TCapability>>
        where TCapability : class, IEvidenceCapability
    {
        internal static CapabilityVisitor<TCapability> Instance { get; } = new();

        public CapabilityProduct<TCapability> VisitProduced(
            CapabilityProduct<TCapability> product) => product;

        public CapabilityProduct<TCapability> VisitFailed(
            SemanticFailureIntent failure) => throw Error();
    }

    private sealed class RejectingReferences : IExpectedReferenceLookup
    {
        internal static RejectingReferences Instance { get; } = new();

        public QualifiedEvidenceHandle Require(
            string selectorKey,
            QualifiedEvidenceHandle parent) => throw Error();
    }

    private sealed class RejectingDerivations : IQualifiedEvidenceDerivationFactory
    {
        internal static RejectingDerivations Instance { get; } = new();

        public QualifiedEvidenceHandle Derive(
            QualifiedEvidenceHandle parent,
            string typedNodeKind,
            string typedNodeIdentity,
            EvidenceLocation location) => throw Error();
    }

    private static bool SameUsage(
        SemanticResourceLocalUsage left,
        SemanticResourceLocalUsage right) =>
        left.GeneratedBytes == right.GeneratedBytes &&
        left.LayerDepth == right.LayerDepth &&
        left.LayerNodes == right.LayerNodes &&
        left.AdditionalComplexity == right.AdditionalComplexity;

    private static void WriteText(Stream stream, string value)
    {
        var bytes = new UTF8Encoding(false, true).GetBytes(value);
        Span<byte> length = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(length, checked((uint)bytes.Length));
        stream.Write(length);
        stream.Write(bytes);
    }

    private static void InvalidPlan() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    private static void InvalidProof() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.AdmissionProofInvalid);

    private static CatalogIntegrityException Error() =>
        new(CatalogIntegrityCode.PlanStateInvalid);
}
