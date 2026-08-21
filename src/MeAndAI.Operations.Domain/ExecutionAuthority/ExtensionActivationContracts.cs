using System.Buffers.Binary;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace MeAndAI.Operations.Domain.ExecutionAuthority;

public sealed class ExtensionActivationRecord : IEquatable<ExtensionActivationRecord>
{
    private ExtensionActivationRecord(ExecutionTarget repository,
        AuthorityRevision epoch, AuthorityRevision version, string policy,
        AuthorityDigest policyDigest, AuthorityDigest snapshot, string commit,
        AuthorityDigest? previous, AuthorityDigest? bootstrap,
        IReadOnlyList<GrantApprovalEvidence> approvals, AuthorityDigest grant,
        AuthorityDigest transition, AuthorityDigest closure,
        AuthoritySetBinding authority)
    {
        (Repository, ActivationEpoch, CasVersion, ActivePolicyIdentity,
            ActivePolicyDigest, ActiveSnapshotDigest, ActivatingTargetCommit,
            PreviousRecordDigest, BootstrapEvidenceDigest, ActivationApprovals,
            ActivationGrantDigest, TransitionEvidenceDigest,
            ClosureEvidenceDigest, AuthoritySet) =
        (repository, epoch, version, policy, policyDigest, snapshot, commit,
            previous, bootstrap, approvals, grant, transition, closure, authority);
        RecordDigest = ExtensionActivationRecordFrame.Compute(this);
    }
    public ExecutionTarget Repository { get; }
    public AuthorityRevision ActivationEpoch { get; }
    public AuthorityRevision CasVersion { get; }
    public string ActivePolicyIdentity { get; }
    public AuthorityDigest ActivePolicyDigest { get; }
    public AuthorityDigest ActiveSnapshotDigest { get; }
    public string ActivatingTargetCommit { get; }
    public AuthorityDigest? PreviousRecordDigest { get; }
    public AuthorityDigest? BootstrapEvidenceDigest { get; }
    public IReadOnlyList<GrantApprovalEvidence> ActivationApprovals { get; }
    public AuthorityDigest ActivationGrantDigest { get; }
    public AuthorityDigest TransitionEvidenceDigest { get; }
    public AuthorityDigest ClosureEvidenceDigest { get; }
    public AuthoritySetBinding AuthoritySet { get; }
    public AuthorityDigest RecordDigest { get; }

    public static ExtensionActivationRecord CreateGenesis(
        ExecutionTarget repository, string activePolicyIdentity,
        AuthorityDigest activePolicyDigest, AuthorityDigest activeSnapshotDigest,
        string activatingTargetCommit, AuthorityDigest bootstrapEvidenceDigest,
        IEnumerable<GrantApprovalEvidence> activationApprovals,
        AuthorityDigest activationGrantDigest,
        AuthorityDigest transitionEvidenceDigest,
        AuthorityDigest closureEvidenceDigest, AuthoritySetBinding authoritySet) =>
        Create(repository, AuthorityRevision.Create(0), AuthorityRevision.Create(0),
            activePolicyIdentity, activePolicyDigest, activeSnapshotDigest,
            activatingTargetCommit, null, bootstrapEvidenceDigest,
            activationApprovals, activationGrantDigest, transitionEvidenceDigest,
            closureEvidenceDigest, authoritySet, genesis: true);

    public static ExtensionActivationRecord CreateSuccessor(
        ExecutionTarget repository, AuthorityRevision activationEpoch,
        AuthorityRevision casVersion, string activePolicyIdentity,
        AuthorityDigest activePolicyDigest, AuthorityDigest activeSnapshotDigest,
        string activatingTargetCommit, AuthorityDigest previousRecordDigest,
        IEnumerable<GrantApprovalEvidence> activationApprovals,
        AuthorityDigest activationGrantDigest,
        AuthorityDigest transitionEvidenceDigest,
        AuthorityDigest closureEvidenceDigest, AuthoritySetBinding authoritySet) =>
        Create(repository, activationEpoch, casVersion, activePolicyIdentity,
            activePolicyDigest, activeSnapshotDigest, activatingTargetCommit,
            previousRecordDigest, null, activationApprovals,
            activationGrantDigest, transitionEvidenceDigest,
            closureEvidenceDigest, authoritySet, genesis: false);

    private static ExtensionActivationRecord Create(ExecutionTarget repository,
        AuthorityRevision activationEpoch, AuthorityRevision casVersion,
        string activePolicyIdentity, AuthorityDigest activePolicyDigest,
        AuthorityDigest activeSnapshotDigest, string activatingTargetCommit,
        AuthorityDigest? previousRecordDigest,
        AuthorityDigest? bootstrapEvidenceDigest,
        IEnumerable<GrantApprovalEvidence> activationApprovals,
        AuthorityDigest activationGrantDigest,
        AuthorityDigest transitionEvidenceDigest,
        AuthorityDigest closureEvidenceDigest, AuthoritySetBinding authoritySet,
        bool genesis)
    {
        ArgumentNullException.ThrowIfNull(repository);
        ArgumentNullException.ThrowIfNull(activationEpoch);
        ArgumentNullException.ThrowIfNull(casVersion);
        ArgumentNullException.ThrowIfNull(activePolicyDigest);
        ArgumentNullException.ThrowIfNull(activeSnapshotDigest);
        ArgumentNullException.ThrowIfNull(activationGrantDigest);
        ArgumentNullException.ThrowIfNull(transitionEvidenceDigest);
        ArgumentNullException.ThrowIfNull(closureEvidenceDigest);
        ArgumentNullException.ThrowIfNull(authoritySet);
        if (genesis)
            ArgumentNullException.ThrowIfNull(bootstrapEvidenceDigest);
        else
            ArgumentNullException.ThrowIfNull(previousRecordDigest);
        if (genesis && (activationEpoch.Value != 0 || casVersion.Value != 0))
            throw new ArgumentException("The genesis counter shape is invalid.",
                nameof(activationEpoch));
        if (!genesis && activationEpoch.Value <= 0)
            throw new ArgumentException("The successor epoch must be positive.",
                nameof(activationEpoch));
        if (!genesis && casVersion.Value <= 0)
            throw new ArgumentException("The successor CAS version must be positive.",
                nameof(casVersion));
        return new(repository, activationEpoch, casVersion,
            GrantContractValidation.Extension(activePolicyIdentity,
                nameof(activePolicyIdentity)), activePolicyDigest,
            activeSnapshotDigest, GrantContractValidation.Commit(
                activatingTargetCommit, nameof(activatingTargetCommit)),
            previousRecordDigest, bootstrapEvidenceDigest,
            GrantContractValidation.Approvals(activationApprovals,
                nameof(activationApprovals)), activationGrantDigest,
            transitionEvidenceDigest, closureEvidenceDigest, authoritySet);
    }
    public bool Equals(ExtensionActivationRecord? other) => other is not null &&
        Repository.Equals(other.Repository) && ActivationEpoch == other.ActivationEpoch &&
        CasVersion == other.CasVersion && ActivePolicyIdentity == other.ActivePolicyIdentity &&
        ActivePolicyDigest.Equals(other.ActivePolicyDigest) &&
        ActiveSnapshotDigest.Equals(other.ActiveSnapshotDigest) &&
        ActivatingTargetCommit == other.ActivatingTargetCommit &&
        Equals(PreviousRecordDigest, other.PreviousRecordDigest) &&
        Equals(BootstrapEvidenceDigest, other.BootstrapEvidenceDigest) &&
        ActivationApprovals.SequenceEqual(other.ActivationApprovals) &&
        ActivationGrantDigest.Equals(other.ActivationGrantDigest) &&
        TransitionEvidenceDigest.Equals(other.TransitionEvidenceDigest) &&
        ClosureEvidenceDigest.Equals(other.ClosureEvidenceDigest) &&
        AuthoritySet.Equals(other.AuthoritySet) && RecordDigest.Equals(other.RecordDigest);
    public override bool Equals(object? obj) => Equals(obj as ExtensionActivationRecord);
    public override int GetHashCode() => HashCode.Combine(Repository, ActivationEpoch,
        CasVersion, ActivePolicyIdentity, ActivePolicyDigest, ActiveSnapshotDigest,
        ActivatingTargetCommit, HashCode.Combine(PreviousRecordDigest,
            BootstrapEvidenceDigest, GrantContractValidation.Hash(ActivationApprovals),
            ActivationGrantDigest, TransitionEvidenceDigest, ClosureEvidenceDigest,
            AuthoritySet, RecordDigest));
}

public sealed class ExtensionActivationCommand : IEquatable<ExtensionActivationCommand>
{
    private ExtensionActivationCommand(ExtensionActivationRecord current,
        AuthorityDigest transition, ExecutionGrant grant, LeaseFenceBinding lease,
        ExtensionActivationRecord proposed) =>
        (ExpectedCurrent, TransitionEvidenceDigest, Grant, ExpectedLeaseFence, Proposed) =
        (current, transition, grant, lease, proposed);
    public ExtensionActivationRecord ExpectedCurrent { get; }
    public AuthorityDigest TransitionEvidenceDigest { get; }
    public ExecutionGrant Grant { get; }
    public LeaseFenceBinding ExpectedLeaseFence { get; }
    public ExtensionActivationRecord Proposed { get; }
    public static ExtensionActivationCommand Create(ExtensionActivationRecord expectedCurrent,
        AuthorityDigest transitionEvidenceDigest, ExecutionGrant grant,
        LeaseFenceBinding expectedLeaseFence, ExtensionActivationRecord proposed)
    {
        ArgumentNullException.ThrowIfNull(expectedCurrent);
        ArgumentNullException.ThrowIfNull(transitionEvidenceDigest);
        ArgumentNullException.ThrowIfNull(grant);
        ArgumentNullException.ThrowIfNull(expectedLeaseFence);
        ArgumentNullException.ThrowIfNull(proposed);
        return new(expectedCurrent, transitionEvidenceDigest, grant,
            expectedLeaseFence, proposed);
    }
    public bool Equals(ExtensionActivationCommand? other) => other is not null &&
        ExpectedCurrent.Equals(other.ExpectedCurrent) &&
        TransitionEvidenceDigest.Equals(other.TransitionEvidenceDigest) &&
        Grant.Equals(other.Grant) && ExpectedLeaseFence.Equals(other.ExpectedLeaseFence) &&
        Proposed.Equals(other.Proposed);
    public override bool Equals(object? obj) => Equals(obj as ExtensionActivationCommand);
    public override int GetHashCode() => HashCode.Combine(ExpectedCurrent,
        TransitionEvidenceDigest, Grant, ExpectedLeaseFence, Proposed);
}

public sealed class ExtensionActivationMutationRequest : IEquatable<ExtensionActivationMutationRequest>
{
    private ExtensionActivationMutationRequest(ExtensionActivationCommand command,
        AuthoritySetBinding authority, AuthorityDigest head, AuthorityActorId actor,
        DateTimeOffset observed) =>
        (Command, ExpectedCurrentAuthoritySet, ExpectedGrantStoreHead,
            ExecutingActor, ObservedAtUtc) = (command, authority, head, actor, observed);
    public ExtensionActivationCommand Command { get; }
    public AuthoritySetBinding ExpectedCurrentAuthoritySet { get; }
    public AuthorityDigest ExpectedGrantStoreHead { get; }
    public AuthorityActorId ExecutingActor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static ExtensionActivationMutationRequest Create(
        ExtensionActivationCommand command, AuthoritySetBinding expectedCurrentAuthoritySet,
        AuthorityDigest expectedGrantStoreHead, AuthorityActorId executingActor,
        DateTimeOffset observedAtUtc)
    {
        ArgumentNullException.ThrowIfNull(command);
        ArgumentNullException.ThrowIfNull(expectedCurrentAuthoritySet);
        ArgumentNullException.ThrowIfNull(expectedGrantStoreHead);
        ArgumentNullException.ThrowIfNull(executingActor);
        GrantContractValidation.Utc(observedAtUtc, nameof(observedAtUtc));
        return new(command, expectedCurrentAuthoritySet, expectedGrantStoreHead,
            executingActor, observedAtUtc);
    }
    public bool Equals(ExtensionActivationMutationRequest? other) => other is not null &&
        Command.Equals(other.Command) &&
        ExpectedCurrentAuthoritySet.Equals(other.ExpectedCurrentAuthoritySet) &&
        ExpectedGrantStoreHead.Equals(other.ExpectedGrantStoreHead) &&
        ExecutingActor.Equals(other.ExecutingActor) && ObservedAtUtc == other.ObservedAtUtc;
    public override bool Equals(object? obj) => Equals(obj as ExtensionActivationMutationRequest);
    public override int GetHashCode() => HashCode.Combine(Command,
        ExpectedCurrentAuthoritySet, ExpectedGrantStoreHead, ExecutingActor, ObservedAtUtc);
}

public sealed class ActivationCasDecision : IEquatable<ActivationCasDecision>
{
    private ActivationCasDecision(bool activated, ExecutionGrantRejection rejection,
        ExtensionActivationRecord? record) =>
        (IsActivated, Rejection, Record) = (activated, rejection, record);
    public bool IsActivated { get; }
    public ExecutionGrantRejection Rejection { get; }
    public ExtensionActivationRecord? Record { get; }
    public static ActivationCasDecision Activated(ExtensionActivationRecord record)
    {
        ArgumentNullException.ThrowIfNull(record);
        return new(true, ExecutionGrantRejection.None, record);
    }
    public static ActivationCasDecision Rejected(ExecutionGrantRejection rejection)
    {
        ArgumentNullException.ThrowIfNull(rejection);
        return rejection == ExecutionGrantRejection.None
            ? throw new ArgumentException("A rejected activation requires a rejection.",
                nameof(rejection))
            : new(false, rejection, null);
    }
    public bool Equals(ActivationCasDecision? other) => other is not null &&
        IsActivated == other.IsActivated && Rejection == other.Rejection &&
        Equals(Record, other.Record);
    public override bool Equals(object? obj) => Equals(obj as ActivationCasDecision);
    public override int GetHashCode() => HashCode.Combine(IsActivated, Rejection, Record);
}

internal static class ExtensionActivationRecordFrame
{
    internal static AuthorityDigest Compute(ExtensionActivationRecord record)
    {
        using MemoryStream stream = new();
        Write(stream, "meandai.execution-authority.extension-activation-record/v1");
        Write(stream, record.Repository.Kind); Write(stream, record.Repository.Identity);
        Write(stream, record.Repository.GenerationIdentity);
        Write(stream, Invariant(record.ActivationEpoch)); Write(stream, Invariant(record.CasVersion));
        Write(stream, record.ActivePolicyIdentity); Write(stream, record.ActivePolicyDigest.Value);
        Write(stream, record.ActiveSnapshotDigest.Value); Write(stream, record.ActivatingTargetCommit);
        Write(stream, record.PreviousRecordDigest?.Value); Write(stream, record.BootstrapEvidenceDigest?.Value);
        WriteUInt32(stream, checked((uint)record.ActivationApprovals.Count));
        foreach (GrantApprovalEvidence approval in record.ActivationApprovals)
        { Write(stream, approval.Approver.Value); Write(stream, approval.Role.Value); Write(stream, approval.EvidenceDigest.Value); }
        Write(stream, record.ActivationGrantDigest.Value); Write(stream, record.TransitionEvidenceDigest.Value);
        Write(stream, record.ClosureEvidenceDigest.Value); Write(stream, record.AuthoritySet.Id.Value);
        Write(stream, Invariant(record.AuthoritySet.Revision)); Write(stream, Invariant(record.AuthoritySet.RevocationEpoch));
        Write(stream, record.AuthoritySet.Digest.Value);
        return AuthorityDigest.FromHashBytes(SHA256.HashData(stream.ToArray()));
    }
    private static string Invariant(AuthorityRevision value) =>
        value.Value.ToString(CultureInfo.InvariantCulture);
    private static void Write(Stream stream, string? value)
    {
        if (value is null) { WriteUInt32(stream, uint.MaxValue); return; }
        byte[] bytes = Encoding.UTF8.GetBytes(value);
        WriteUInt32(stream, checked((uint)bytes.Length)); stream.Write(bytes);
    }
    private static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> bytes = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(bytes, value); stream.Write(bytes);
    }
}
