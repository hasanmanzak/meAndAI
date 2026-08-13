using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class ApplicabilityClosureCore
{
    internal static ApplicabilityClosure Close(
        KernelPlanningSession session,
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(plan);
        ArgumentNullException.ThrowIfNull(proofs);
        cancellationToken.ThrowIfCancellationRequested();
        if (!ReferenceEquals(plan.EvidenceSession, session) ||
            !ReferenceEquals(plan.AuthorityKind, session.AuthorityKind))
        {
            InvalidPlan();
        }

        session.BeginClose(plan);
        try
        {
            var admitted = Admit(session, plan, proofs, cancellationToken);
            var context = new SealedEvaluationContext(
                session.AuthorityKind,
                session.ManifestDigest,
                session.CatalogVersion,
                admitted.Outcomes
                    .Where(outcome => outcome.Status.Equals(AcquisitionStatus.Complete))
                    .Select(outcome => outcome.Slot.SlotKey),
                admitted.Outcomes
                    .Where(outcome => outcome.ContextProof is not null)
                    .Select(outcome => outcome.ContextProof!.Scope)
                    .Distinct()
                    .OrderBy(scope => scope.Target.SubjectIdentity, StringComparer.Ordinal)
                    .ThenBy(scope => scope.Target.SourceIdentity, StringComparer.Ordinal)
                    .ThenBy(scope => scope.Target.Surface.Value, StringComparer.Ordinal));
            var terminal = EvaluateApplicability(
                session,
                plan,
                admitted,
                cancellationToken);
            ApplicabilityClosure? result = new(
                plan,
                context,
                admitted.Outcomes,
                terminal);
            if (result is null)
            {
                session.AbandonClose(plan);
                return null!;
            }

            session.CompleteClose(plan);
            return result;
        }
        catch
        {
            session.AbandonClose(plan);
            throw;
        }
    }

    private static AdmissionState Admit(
        KernelPlanningSession session,
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken)
    {
        if (plan.Slots.Count != plan.Instructions.Count ||
            !plan.Slots.Select(slot => slot.SlotKey).SequenceEqual(
                plan.Instructions.Select(item => item.Slot.SlotKey),
                StringComparer.Ordinal))
        {
            InvalidPlan();
        }

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

        var bySlot = new Dictionary<string, IAdmissionProofCandidate>(
            StringComparer.Ordinal);
        foreach (var candidate in candidates)
        {
            if (candidate.SlotKeys.Count != 1 ||
                !bySlot.TryAdd(candidate.SlotKeys[0], candidate))
            {
                InvalidProof();
            }
        }

        var outcomes = new List<SealedAcquisitionOutcome>();
        var handles = new Dictionary<string, QualifiedEvidenceHandle>(
            StringComparer.Ordinal);
        var references = new Dictionary<QualifiedEvidenceHandle,
            QualifiedEvidenceReference>(ReferenceEqualityComparer.Instance);
        foreach (var instruction in plan.Instructions)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!bySlot.TryGetValue(instruction.Slot.SlotKey, out var candidate))
            {
                InvalidProof();
            }

            var leaf = ValidateCandidate(session, instruction, candidate!);
            var attempt = new SealedAcquisitionAttempt(
                instruction,
                leaf.Kind,
                leaf.Status,
                candidate!.ReceiptDigest,
                leaf.Scope,
                leaf.Acquisition,
                leaf.Failures);
            QualifiedEvidenceReference? contextProof = null;
            if (leaf.Status.Equals(AcquisitionStatus.Complete))
            {
                contextProof = new QualifiedEvidenceReference(
                    QualifiedEvidenceReferenceKind.ContextProof,
                    session.ManifestDigest,
                    session.CatalogVersion,
                    instruction.Slot.SlotKey,
                    instruction.Slot.Requirement.Key,
                    leaf.Scope!,
                    candidate!.ReceiptDigest,
                    null,
                    null,
                    [],
                    null,
                    null);
                var handle = QualifiedEvidenceHandle.Create();
                handles.Add(instruction.Slot.SlotKey, handle);
                references.Add(handle, contextProof);
            }

            outcomes.Add(new SealedAcquisitionOutcome(
                instruction.Slot,
                instruction.Target,
                leaf.Status,
                false,
                OutcomeDigest(session, instruction, attempt),
                leaf.Scope,
                leaf.Acquisition,
                contextProof,
                [attempt],
                leaf.Failures));
        }

        return new AdmissionState(
            Array.AsReadOnly(outcomes.ToArray()),
            handles,
            references);
    }

    internal static AdmissionLeaf ValidateCandidate(
        KernelPlanningSession session,
        AcquisitionInstruction instruction,
        IAdmissionProofCandidate candidate)
    {
        var kind = candidate switch
        {
            IObservedQualificationProof => AdmissionProofKind.Observed,
            IFailedAttemptProof => AdmissionProofKind.Failed,
            INoInputRoutingProof => AdmissionProofKind.NoInput,
            _ => throw ProofError(),
        };
        var contracts = session.Manifest.SchemaRegistry.AdmissionProofContracts;
        var contract = contracts.SingleOrDefault(item => item.Kind.Equals(kind));
        if (contract is null ||
            !string.Equals(candidate.ContractKey, contract.ContractKey,
                StringComparison.Ordinal) ||
            !string.Equals(candidate.ContractVersion, contract.ContractVersion,
                StringComparison.Ordinal) ||
            !candidate.ManifestDigest.Equals(session.ManifestDigest) ||
            !candidate.InstructionDigest.Equals(instruction.InstructionDigest) ||
            !candidate.Request.Target.Equals(instruction.Target) ||
            candidate.Request.RequestedRequirements.Count != 1 ||
            !candidate.Request.RequestedRequirements[0].Equals(
                instruction.Slot.Requirement) ||
            !string.Equals(candidate.GetType().Assembly.GetName().Name,
                contract.ProofComponent.AssemblyName, StringComparison.Ordinal) ||
            !string.Equals(candidate.GetType().FullName,
                contract.ProofComponent.TypeName, StringComparison.Ordinal) ||
            !contract.Surfaces.Values.Contains(instruction.Target.Surface) ||
            !contract.MaterialRoles.Contains(
                instruction.Slot.MaterialRole,
                StringComparer.Ordinal) ||
            !session.Manifest.Components.Any(binding =>
                binding.Component.Equals(contract.ProofComponent)) ||
            !session.ActivationProof.Proves(candidate))
        {
            InvalidProof();
        }

        return candidate switch
        {
            IObservedQualificationProof observed => Observed(observed),
            IFailedAttemptProof failed => Failed(failed),
            INoInputRoutingProof => new AdmissionLeaf(
                kind,
                AcquisitionStatus.Incomplete,
                null,
                null,
                []),
            _ => throw ProofError(),
        };
    }

    private static AdmissionLeaf Observed(IObservedQualificationProof proof)
    {
        var context = proof.Result.Context;
        if (!proof.Result.Request.Equals(proof.Request) ||
            !context.Scope.Target.Equals(proof.Request.Target) ||
            context.RequirementAcquisitions.Count != 1 ||
            !context.RequirementAcquisitions[0].Requirement.Equals(
                proof.Request.RequestedRequirements[0]) ||
            !context.Status.Equals(context.RequirementAcquisitions[0].Status))
        {
            InvalidProof();
        }

        return new AdmissionLeaf(
            AdmissionProofKind.Observed,
            context.Status,
            context.Scope,
            context.RequirementAcquisitions[0],
            context.RequirementAcquisitions[0].Failures);
    }

    private static AdmissionLeaf Failed(IFailedAttemptProof proof)
    {
        if (!proof.Result.Request.Equals(proof.Request) ||
            proof.Result.Failures.Count == 0)
        {
            InvalidProof();
        }

        return new AdmissionLeaf(
            AdmissionProofKind.Failed,
            AcquisitionStatus.Failed,
            null,
            null,
            proof.Result.Failures);
    }

    private static IReadOnlyList<RuleEvaluation> EvaluateApplicability(
        KernelPlanningSession session,
        ApplicabilityPlan plan,
        AdmissionState admitted,
        CancellationToken cancellationToken)
    {
        var outcomes = admitted.Outcomes.ToDictionary(
            outcome => outcome.Slot.SlotKey,
            StringComparer.Ordinal);
        var terminals = new List<RuleEvaluation>();
        foreach (var ruleId in plan.RuleIds)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var rule = session.Rules.Single(item => item.RuleId.Equals(ruleId));
            var activeSlots = rule.ApplicabilitySlots
                .Where(slot => plan.Slots.Any(item =>
                    string.Equals(item.SlotKey, slot.SlotKey,
                        StringComparison.Ordinal)))
                .OrderBy(slot => slot.SlotKey, StringComparer.Ordinal)
                .ToArray();
            var unresolved = activeSlots
                .Where(slot => !outcomes[slot.SlotKey].Status.Equals(
                    AcquisitionStatus.Complete))
                .Select(slot => slot.SlotKey)
                .ToArray();
            if (unresolved.Length != 0)
            {
                terminals.Add(Terminal(
                    rule,
                    RuleEvaluationStatus.NotEvaluated,
                    false,
                    [],
                    unresolved));
                continue;
            }

            var access = RuleInputAccess.Create(
                [],
                activeSlots.ToDictionary(
                    slot => slot.SlotKey,
                    slot => admitted.Handles[slot.SlotKey],
                    StringComparer.Ordinal),
                RejectingReferenceLookup.Instance);
            var evaluator = session.ProducerGraph.EvaluatorRegistrations
                .Single(item => ReferenceEquals(item.Declaration, rule))
                .Evaluator;
            var intent = evaluator.EvaluateApplicability(
                RuleApplicabilityInput.Create(
                    rule.RuleId,
                    rule.RuleRevision,
                    plan.Profile,
                    access),
                cancellationToken) ?? throw ProofError();
            var references = new List<QualifiedEvidenceReference>();
            foreach (var reference in intent.References)
            {
                if (!admitted.References.TryGetValue(reference, out var value) ||
                    !activeSlots.Any(slot => string.Equals(
                        slot.SlotKey,
                        value.SlotKey,
                        StringComparison.Ordinal)))
                {
                    InvalidProof();
                }

                references.Add(value!);
            }

            var uniqueReferences = references.Distinct().ToArray();
            if (uniqueReferences.Length != intent.References.Count)
            {
                InvalidProof();
            }

            if (intent.Kind.Equals(ApplicabilityIntentKind.Applicable))
            {
                continue;
            }

            if (intent.Kind.Equals(ApplicabilityIntentKind.NotApplicable))
            {
                terminals.Add(Terminal(
                    rule,
                    RuleEvaluationStatus.NotApplicable,
                    false,
                    uniqueReferences,
                    []));
                continue;
            }

            if (intent.Kind.Equals(ApplicabilityIntentKind.Unresolved))
            {
                terminals.Add(Terminal(
                    rule,
                    RuleEvaluationStatus.NotEvaluated,
                    true,
                    uniqueReferences,
                    []));
                continue;
            }

            InvalidProof();
        }

        return Array.AsReadOnly(terminals
            .OrderBy(item => item.RuleId.Value, StringComparer.Ordinal)
            .ThenBy(item => item.RuleRevision.Value)
            .ToArray());
    }

    private static RuleEvaluation Terminal(
        RuleDeclaration rule,
        RuleEvaluationStatus status,
        bool unresolved,
        IEnumerable<QualifiedEvidenceReference> references,
        IEnumerable<string> unresolvedSlots) => new(
            rule.RuleId,
            rule.RuleRevision,
            status,
            unresolved,
            references,
            unresolvedSlots,
            [],
            []);

    internal static ExactSha256Digest OutcomeDigest(
        KernelPlanningSession session,
        AcquisitionInstruction instruction,
        SealedAcquisitionAttempt attempt)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-outcome/1\n"));
        WriteText(stream, session.AuthorityKind.Value);
        stream.Write(Convert.FromHexString(session.ManifestDigest.Value));
        WriteText(stream, session.CatalogVersion.Value.ToString(
            System.Globalization.CultureInfo.InvariantCulture));
        WriteText(stream, instruction.Slot.SlotKey);
        WriteText(stream, instruction.Target.SubjectIdentity);
        WriteText(stream, instruction.Target.SourceIdentity);
        WriteText(stream, instruction.Target.Surface.Value);
        WriteText(stream, instruction.Target.SnapshotKind.Value);
        WriteText(stream, instruction.Target.TargetIdentity);
        stream.WriteByte(0);
        WriteText(stream, attempt.Status.Value);
        stream.Write(Convert.FromHexString(attempt.ReceiptDigest.Value));
        return ExactSha256Digest.FromHashBytes(SHA256.HashData(stream.ToArray()));
    }

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

    private static void InvalidProof() => throw ProofError();

    private static CatalogIntegrityException ProofError() =>
        new(CatalogIntegrityCode.AdmissionProofInvalid);

    private sealed record AdmissionState(
        IReadOnlyList<SealedAcquisitionOutcome> Outcomes,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> Handles,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            References);

    internal sealed record AdmissionLeaf(
        AdmissionProofKind Kind,
        AcquisitionStatus Status,
        EvidenceScope? Scope,
        RequirementAcquisition? Acquisition,
        IReadOnlyList<AcquisitionFailure> Failures);

    private sealed class RejectingReferenceLookup : IExpectedReferenceLookup
    {
        internal static RejectingReferenceLookup Instance { get; } = new();

        public QualifiedEvidenceHandle Require(
            string selectorKey,
            QualifiedEvidenceHandle parent) =>
            throw new InvalidOperationException(
                "Expected references are unavailable during applicability.");
    }
}
