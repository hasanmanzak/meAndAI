# [SUBF-0146](README.md#subf-0146) Exact Public API Contract

| Field | Value |
| --- | --- |
| Classification | Normative API appendix to the [journal/recovery design](subf-0146-journal-recovery-design.md) |
| Status | `DesignFreezeCandidate`; not implementation authority |
| Parent | [FEAT-0066](README.md) |
| Test | [TEST-0213](test-cases.md#test-0213) |
| Values/errors | [Exact value and error contract](subf-0146-value-error-contract.md) |
| Delivery | [Micro-delivery plan](subf-0146-micro-delivery-plan.md) |

This file is the sole normative public-signature authority for SUBF-0146.
Domain types are in `MeAndAI.Operations.Domain.ExecutionAuthority`; services
and ports are in `MeAndAI.Operations.Application.ExecutionAuthority`. The
accepted SUBF-0145 public surface is unchanged. A signature change reopens the
complete design gate.

No type has a public constructor or setter. Collections are defensively copied,
ordinally sorted, duplicate-free `IReadOnlyList<T>`. Scalar classes implement
the same exact `IEquatable<T>`, `IComparable<T>`, `Parse`, `TryParse`, and
`ToString` pattern as SUBF-0145 scalar identities. Closed values expose only
the listed static values, `Value`, `Parse`, and `ToString`.

## Normative SliceInventory

~~~text
ExternalEffectClassification
ExternalEffectMutationDecision
ExternalEffectMutationRejection
ExternalEffectMutationRequest
ExternalEffectObservation
DurableTransitionGrant
IExecutionRecoveryMutationPort
IExecutionRecoveryReadPort
JournalAppendDecision
JournalAppendRejection
JournalEntryKind
JournalEntrySequence
JournalReceiptOutcome
JournalIntentMutationRequest
JournalReceiptMutationRequest
LeaseAcquireCommand
LeaseAction
LeaseDecision
LeaseFenceRecord
LeaseGrant
LeaseLifecycleService
LeaseMutationRequest
LeaseRejection
LeaseReleaseCommand
LeaseRenewCommand
OperationEffectId
OperationEffectRequestEnvelope
OperationExecutionDecision
OperationExecutionRejection
OperationIntent
OperationIntentCommand
OperationJournalEntry
OperationJournalEntryDigest
OperationJournalHead
OperationJournalService
OperationPlanEffect
OperationPlanEnvelope
OperationReceipt
OperationReceiptCommand
OperationReconstructionRequest
OperationReconstructionResult
OperationReconstructionService
OperationRecoveryCommand
OperationRecoveryDecision
OperationRecoveryService
OperationState
ReconstructedEffect
RecoveryAction
RecoveryGrant
RecoveryIntentMutationRequest
RecoveryReceiptMutationRequest
RecoveryRejection
RetentionAction
RetentionAppendDecision
RetentionAppendRejection
RetentionArchiveRequest
RetentionCommand
RetentionDestroyRequest
RetentionEffectDecision
RetentionEffectRejection
RetentionGrant
RetentionIntent
RetentionIntentMutationRequest
RetentionLedgerEntry
RetentionLedgerEntryKind
RetentionLedgerHead
RetentionMutationDecision
RetentionReceipt
RetentionReceiptMutationRequest
~~~

Tests derive the exact count and ownership from this ordinal list.

## Canonical absence oracles

Each compile-safe expected red loads the named assembly, resolves the exact
type with `Type.GetType(..., false)`, then resolves the exact public member and
parameter array. Only the final absence assertion may fail.

| Package / marker | Assembly-qualified type | Exact public member |
| --- | --- | --- |
| `EA-LEASE-FENCE-01` / `TEST-0213-LEASE-RED-0001` | `MeAndAI.Operations.Application.ExecutionAuthority.LeaseLifecycleService, MeAndAI.Operations.Application` | instance `AcquireAsync(MeAndAI.Operations.Domain.ExecutionAuthority.LeaseAcquireCommand, MeAndAI.Operations.Domain; MeAndAI.Operations.Domain.ExecutionAuthority.AuthorityActorId, MeAndAI.Operations.Domain; System.DateTimeOffset, System.Private.CoreLib; System.Threading.CancellationToken, System.Private.CoreLib)` |
| `EA-JOURNAL-CHAIN-01` / `TEST-0213-JOURNAL-RED-0002` | `MeAndAI.Operations.Application.ExecutionAuthority.OperationJournalService, MeAndAI.Operations.Application` | instance `AppendIntentAsync(MeAndAI.Operations.Domain.ExecutionAuthority.OperationIntentCommand, MeAndAI.Operations.Domain; MeAndAI.Operations.Domain.ExecutionAuthority.AuthorityActorId, MeAndAI.Operations.Domain; System.DateTimeOffset, System.Private.CoreLib; System.Threading.CancellationToken, System.Private.CoreLib)` |
| `EA-RECONSTRUCTION-01` / `TEST-0213-RECONSTRUCTION-RED-0003` | `MeAndAI.Operations.Application.ExecutionAuthority.OperationReconstructionService, MeAndAI.Operations.Application` | instance `ReconstructAsync(MeAndAI.Operations.Domain.ExecutionAuthority.OperationReconstructionRequest, MeAndAI.Operations.Domain; System.Threading.CancellationToken, System.Private.CoreLib)` |
| `EA-RECOVERY-RETENTION-01` / `TEST-0213-RECOVERY-RED-0004` | `MeAndAI.Operations.Application.ExecutionAuthority.OperationRecoveryService, MeAndAI.Operations.Application` | instance `RecoverAsync(MeAndAI.Operations.Domain.ExecutionAuthority.OperationRecoveryCommand, MeAndAI.Operations.Domain; MeAndAI.Operations.Domain.ExecutionAuthority.AuthorityActorId, MeAndAI.Operations.Domain; System.DateTimeOffset, System.Private.CoreLib; System.Threading.CancellationToken, System.Private.CoreLib)` |

## Scalar and closed-value APIs

~~~csharp
public sealed class OperationEffectId : IEquatable<OperationEffectId>, IComparable<OperationEffectId>
{
    public string Value { get; }
    public static OperationEffectId Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out OperationEffectId? result);
    public override string ToString();
}

public sealed class OperationJournalEntryDigest : IEquatable<OperationJournalEntryDigest>, IComparable<OperationJournalEntryDigest>
{
    public string Value { get; }
    public static OperationJournalEntryDigest Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out OperationJournalEntryDigest? result);
    public static OperationJournalEntryDigest FromHashBytes(ReadOnlySpan<byte> hashBytes);
    public override string ToString();
}

public sealed record JournalEntrySequence
{
    public long Value { get; }
    public static JournalEntrySequence Create(long value);
    public override string ToString();
}

public sealed record JournalEntryKind
{
    public static JournalEntryKind Intent { get; }
    public static JournalEntryKind Receipt { get; }
    public string Value { get; }
    public static JournalEntryKind Parse(string value);
    public override string ToString();
}

public sealed record JournalReceiptOutcome
{
    public static JournalReceiptOutcome Applied { get; }
    public static JournalReceiptOutcome Rejected { get; }
    public string Value { get; }
    public static JournalReceiptOutcome Parse(string value);
    public override string ToString();
}

public sealed record ExternalEffectClassification
{
    public static ExternalEffectClassification NotStarted { get; }
    public static ExternalEffectClassification AppliedUnrecorded { get; }
    public static ExternalEffectClassification Recorded { get; }
    public static ExternalEffectClassification Diverged { get; }
    public string Value { get; }
    public static ExternalEffectClassification Parse(string value);
    public override string ToString();
}

public sealed record OperationState
{
    public static OperationState RecoveryRequired { get; }
    public static OperationState Diverged { get; }
    public static OperationState UnrecoverableJournal { get; }
    public static OperationState Complete { get; }
    public string Value { get; }
    public static OperationState Parse(string value);
    public override string ToString();
}

public sealed record RecoveryAction
{
    public static RecoveryAction RetryNotStarted { get; }
    public static RecoveryAction RecordAppliedUnrecorded { get; }
    public string Value { get; }
    public static RecoveryAction Parse(string value);
    public override string ToString();
}

public sealed record RetentionAction
{
    public static RetentionAction Archive { get; }
    public static RetentionAction DestroyArchivedSegment { get; }
    public string Value { get; }
    public static RetentionAction Parse(string value);
    public override string ToString();
}

public sealed record LeaseAction
{
    public static LeaseAction Acquire { get; }
    public static LeaseAction Renew { get; }
    public static LeaseAction Release { get; }
    public string Value { get; }
    public static LeaseAction Parse(string value);
    public override string ToString();
}
~~~

The rejection types use the same closed-value API shape. Their exact
static values are frozen in the [value/error appendix](subf-0146-value-error-contract.md#closed-rejections):

~~~csharp
public sealed record LeaseRejection
{
    public static LeaseRejection None { get; }
    public static LeaseRejection SnapshotUnavailable { get; }
    public static LeaseRejection SnapshotDrift { get; }
    public static LeaseRejection GrantRejected { get; }
    public static LeaseRejection ActorMismatch { get; }
    public static LeaseRejection LeaseUnavailable { get; }
    public static LeaseRejection LeaseStillActive { get; }
    public static LeaseRejection LeaseExpired { get; }
    public static LeaseRejection LeaseReleased { get; }
    public static LeaseRejection GenerationMismatch { get; }
    public static LeaseRejection LeaseFenceMismatch { get; }
    public static LeaseRejection Replay { get; }
    public static LeaseRejection CasConflict { get; }
    public string Value { get; }
    public static LeaseRejection Parse(string value);
    public override string ToString();
}

public sealed record JournalAppendRejection
{
    public static JournalAppendRejection None { get; }
    public static JournalAppendRejection SnapshotUnavailable { get; }
    public static JournalAppendRejection SnapshotDrift { get; }
    public static JournalAppendRejection GrantRejected { get; }
    public static JournalAppendRejection ActorMismatch { get; }
    public static JournalAppendRejection JournalStoreDrift { get; }
    public static JournalAppendRejection JournalUnavailable { get; }
    public static JournalAppendRejection JournalCorrupt { get; }
    public static JournalAppendRejection HeadMismatch { get; }
    public static JournalAppendRejection SequenceMismatch { get; }
    public static JournalAppendRejection LeaseUnavailable { get; }
    public static JournalAppendRejection LeaseExpired { get; }
    public static JournalAppendRejection LeaseFenceMismatch { get; }
    public static JournalAppendRejection IntentMissing { get; }
    public static JournalAppendRejection EntryConflict { get; }
    public static JournalAppendRejection Replay { get; }
    public static JournalAppendRejection CasConflict { get; }
    public string Value { get; }
    public static JournalAppendRejection Parse(string value);
    public override string ToString();
}

public sealed record RecoveryRejection
{
    public static RecoveryRejection None { get; }
    public static RecoveryRejection SnapshotUnavailable { get; }
    public static RecoveryRejection SnapshotDrift { get; }
    public static RecoveryRejection GrantUnavailable { get; }
    public static RecoveryRejection GrantDrift { get; }
    public static RecoveryRejection GrantNotYetValid { get; }
    public static RecoveryRejection GrantExpired { get; }
    public static RecoveryRejection ActorMismatch { get; }
    public static RecoveryRejection PredecessorMismatch { get; }
    public static RecoveryRejection OperationMismatch { get; }
    public static RecoveryRejection PlanMismatch { get; }
    public static RecoveryRejection JournalStoreDrift { get; }
    public static RecoveryRejection JournalUnavailable { get; }
    public static RecoveryRejection JournalCorrupt { get; }
    public static RecoveryRejection HeadMismatch { get; }
    public static RecoveryRejection ReconstructionMismatch { get; }
    public static RecoveryRejection ClassificationMismatch { get; }
    public static RecoveryRejection ActionMismatch { get; }
    public static RecoveryRejection EffectMismatch { get; }
    public static RecoveryRejection LeaseUnavailable { get; }
    public static RecoveryRejection LeaseExpired { get; }
    public static RecoveryRejection LeaseFenceMismatch { get; }
    public static RecoveryRejection FenceNotNewer { get; }
    public static RecoveryRejection RetentionPolicyMismatch { get; }
    public static RecoveryRejection Replay { get; }
    public static RecoveryRejection CasConflict { get; }
    public string Value { get; }
    public static RecoveryRejection Parse(string value);
    public override string ToString();
}

public sealed record ExternalEffectMutationRejection
{
    public static ExternalEffectMutationRejection None { get; }
    public static ExternalEffectMutationRejection PlanDrift { get; }
    public static ExternalEffectMutationRejection IntentUnavailable { get; }
    public static ExternalEffectMutationRejection LeaseUnavailable { get; }
    public static ExternalEffectMutationRejection LeaseExpired { get; }
    public static ExternalEffectMutationRejection LeaseFenceMismatch { get; }
    public static ExternalEffectMutationRejection BindingMismatch { get; }
    public static ExternalEffectMutationRejection Replay { get; }
    public static ExternalEffectMutationRejection CasConflict { get; }
    public string Value { get; }
    public static ExternalEffectMutationRejection Parse(string value);
    public override string ToString();
}

public sealed record OperationExecutionRejection
{
    public static OperationExecutionRejection None { get; }
    public static OperationExecutionRejection RecoveryRequired { get; }
    public static OperationExecutionRejection Diverged { get; }
    public static OperationExecutionRejection UnrecoverableJournal { get; }
    public static OperationExecutionRejection IntentAppendRejected { get; }
    public static OperationExecutionRejection EffectInvocationRejected { get; }
    public static OperationExecutionRejection ReceiptAppendRejected { get; }
    public string Value { get; }
    public static OperationExecutionRejection Parse(string value);
    public override string ToString();
}

public sealed record RetentionAppendRejection
{
    public static RetentionAppendRejection None { get; }
    public static RetentionAppendRejection GrantRejected { get; }
    public static RetentionAppendRejection LedgerUnavailable { get; }
    public static RetentionAppendRejection LedgerCorrupt { get; }
    public static RetentionAppendRejection HeadMismatch { get; }
    public static RetentionAppendRejection LeaseFenceMismatch { get; }
    public static RetentionAppendRejection EntryConflict { get; }
    public static RetentionAppendRejection Replay { get; }
    public static RetentionAppendRejection CasConflict { get; }
    public string Value { get; }
    public static RetentionAppendRejection Parse(string value);
    public override string ToString();
}

public sealed record RetentionEffectRejection
{
    public static RetentionEffectRejection None { get; }
    public static RetentionEffectRejection ReconstructionMismatch { get; }
    public static RetentionEffectRejection IntentRejected { get; }
    public static RetentionEffectRejection ArchiveRejected { get; }
    public static RetentionEffectRejection DestroyRejected { get; }
    public static RetentionEffectRejection ArchiveReceiptMismatch { get; }
    public static RetentionEffectRejection ReceiptRejected { get; }
    public string Value { get; }
    public static RetentionEffectRejection Parse(string value);
    public override string ToString();
}
~~~

## Lease contracts

~~~csharp
public abstract class DurableTransitionGrant : IEquatable<DurableTransitionGrant>
{
    internal DurableTransitionGrant();
    public AuthorityGrantId GrantId { get; }
    public AuthoritySetBinding Authority { get; }
    public AuthorityActorId Issuer { get; }
    public AuthorityActorId Executor { get; }
    public ExecutionSubject Subject { get; }
    public ExecutionTarget Target { get; }
    public AuthorityOperationId OperationId { get; }
    public JournalStoreReference GrantStore { get; }
    public AuthorityDigest ExpectedGrantStoreHead { get; }
    public IReadOnlyList<GrantApprovalEvidence> Approvals { get; }
    public DateTimeOffset IssuedAtUtc { get; }
    public DateTimeOffset NotBeforeUtc { get; }
    public DateTimeOffset ExpiresAtUtc { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public AuthorityDigest GrantDigest { get; }
    public bool Equals(DurableTransitionGrant? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
}

public sealed class LeaseGrant : DurableTransitionGrant, IEquatable<LeaseGrant>
{
    public LeaseAction Action { get; }
    public LeaseFenceBinding ExpectedPredecessorFence { get; }
    public AuthorityDigest? ExpectedPredecessorLeaseDigest { get; }
    public GrantGeneration ProposedGeneration { get; }
    public DateTimeOffset ProposedExpiresAtUtc { get; }
    public static LeaseGrant Create(AuthorityGrantId grantId, AuthoritySetBinding authority, AuthorityActorId issuer, AuthorityActorId executor, ExecutionSubject subject, ExecutionTarget target, AuthorityOperationId operationId, JournalStoreReference grantStore, AuthorityDigest expectedGrantStoreHead, IReadOnlyList<GrantApprovalEvidence> approvals, DateTimeOffset issuedAtUtc, DateTimeOffset notBeforeUtc, DateTimeOffset expiresAtUtc, IdempotencyKey idempotencyKey, LeaseAction action, LeaseFenceBinding expectedPredecessorFence, AuthorityDigest? expectedPredecessorLeaseDigest, GrantGeneration proposedGeneration, DateTimeOffset proposedExpiresAtUtc);
    public bool Equals(LeaseGrant? other);
}

public sealed record LeaseFenceRecord
{
    public AuthorityOperationId OperationId { get; }
    public AuthorityActorId Owner { get; }
    public AuthoritySetBinding Authority { get; }
    public GrantGeneration Generation { get; }
    public long FencingToken { get; }
    public DateTimeOffset AcquiredAtUtc { get; }
    public DateTimeOffset ExpiresAtUtc { get; }
    public DateTimeOffset? ReleasedAtUtc { get; }
    public bool IsReleased { get; }
    public AuthorityDigest RecordDigest { get; }
    public static LeaseFenceRecord Create(AuthorityOperationId operationId, AuthorityActorId owner, GrantGeneration generation, long fencingToken, DateTimeOffset acquiredAtUtc, DateTimeOffset expiresAtUtc, DateTimeOffset? releasedAtUtc, AuthoritySetBinding authority);
}

public sealed record LeaseAcquireCommand
{
    public AuthorityOperationId OperationId { get; }
    public AuthoritySetBinding Authority { get; }
    public LeaseGrant Grant { get; }
    public LeaseFenceRecord? ExpectedCurrent { get; }
    public GrantGeneration ExpectedGeneration { get; }
    public DateTimeOffset ExpiresAtUtc { get; }
    public static LeaseAcquireCommand Create(AuthorityOperationId operationId, AuthoritySetBinding authority, LeaseGrant grant, LeaseFenceRecord? expectedCurrent, GrantGeneration expectedGeneration, DateTimeOffset expiresAtUtc);
}

public sealed record LeaseRenewCommand
{
    public LeaseFenceRecord ExpectedCurrent { get; }
    public AuthoritySetBinding Authority { get; }
    public LeaseGrant Grant { get; }
    public DateTimeOffset ExpiresAtUtc { get; }
    public static LeaseRenewCommand Create(LeaseFenceRecord expectedCurrent, AuthoritySetBinding authority, LeaseGrant grant, DateTimeOffset expiresAtUtc);
}

public sealed record LeaseReleaseCommand
{
    public LeaseFenceRecord ExpectedCurrent { get; }
    public AuthoritySetBinding Authority { get; }
    public LeaseGrant Grant { get; }
    public static LeaseReleaseCommand Create(LeaseFenceRecord expectedCurrent, AuthoritySetBinding authority, LeaseGrant grant);
}

public sealed record LeaseDecision
{
    public bool IsAccepted { get; }
    public LeaseRejection Rejection { get; }
    public LeaseFenceRecord? Record { get; }
    public static LeaseDecision Accepted(LeaseFenceRecord record);
    public static LeaseDecision Rejected(LeaseRejection rejection);
}

public sealed class LeaseLifecycleService
{
    public static LeaseLifecycleService Create(IExecutionRecoveryReadPort readPort, IExecutionRecoveryMutationPort mutationPort);
    public ValueTask<LeaseDecision> AcquireAsync(LeaseAcquireCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
    public ValueTask<LeaseDecision> RenewAsync(LeaseRenewCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
    public ValueTask<LeaseDecision> ReleaseAsync(LeaseReleaseCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
}
~~~

## Journal contracts

~~~csharp
public sealed record OperationPlanEffect
{
    public OperationEffectId EffectId { get; }
    public ExecutionSubject Subject { get; }
    public ExecutionTarget Target { get; }
    public AuthorityDigest RequestDigest { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public static OperationPlanEffect Create(OperationEffectId effectId, ExecutionSubject subject, ExecutionTarget target, AuthorityDigest requestDigest, IdempotencyKey idempotencyKey);
}

public sealed record OperationEffectRequestEnvelope
{
    public OperationEffectId EffectId { get; }
    public string SchemaId { get; }
    public ReadOnlyMemory<byte> CanonicalPayload { get; }
    public AuthorityDigest RequestDigest { get; }
    public static OperationEffectRequestEnvelope Create(OperationEffectId effectId, string schemaId, ReadOnlyMemory<byte> canonicalPayload);
}

public sealed record OperationPlanEnvelope
{
    public AuthorityOperationId OperationId { get; }
    public AuthoritySetBinding Authority { get; }
    public JournalStoreReference PlanStore { get; }
    public JournalStoreReference JournalStore { get; }
    public IReadOnlyList<OperationPlanEffect> Effects { get; }
    public AuthorityDigest PlanDigest { get; }
    public static OperationPlanEnvelope Create(AuthorityOperationId operationId, AuthoritySetBinding authority, JournalStoreReference planStore, JournalStoreReference journalStore, IReadOnlyList<OperationPlanEffect> effects);
}

public sealed record OperationJournalHead
{
    public JournalStoreReference Store { get; }
    public AuthorityOperationId OperationId { get; }
    public JournalEntrySequence Sequence { get; }
    public OperationJournalEntryDigest EntryDigest { get; }
    public AuthorityDigest HeadDigest { get; }
    public bool IsGenesis { get; }
    public static OperationJournalHead CreateGenesis(JournalStoreReference store, AuthorityOperationId operationId);
    public static OperationJournalHead CreateSuccessor(JournalStoreReference store, AuthorityOperationId operationId, JournalEntrySequence sequence, OperationJournalEntryDigest entryDigest);
}

public sealed record OperationIntent
{
    public OperationEffectId EffectId { get; }
    public AuthorityDigest RequestDigest { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public static OperationIntent Create(OperationEffectId effectId, AuthorityDigest requestDigest, IdempotencyKey idempotencyKey);
}

public sealed record OperationReceipt
{
    public OperationEffectId EffectId { get; }
    public OperationJournalEntryDigest IntentDigest { get; }
    public JournalReceiptOutcome Outcome { get; }
    public ExecutionTarget? ResultObject { get; }
    public AuthorityDigest ResultDigest { get; }
    public AuthorityDigest ObservationDigest { get; }
    public static OperationReceipt Create(OperationEffectId effectId, OperationJournalEntryDigest intentDigest, JournalReceiptOutcome outcome, ExecutionTarget? resultObject, AuthorityDigest resultDigest, AuthorityDigest observationDigest);
}

public sealed record OperationJournalEntry
{
    public OperationJournalHead PreviousHead { get; }
    public JournalEntrySequence Sequence { get; }
    public JournalEntryKind Kind { get; }
    public AuthorityOperationId OperationId { get; }
    public AuthorityDigest PlanDigest { get; }
    public AuthoritySetBinding Authority { get; }
    public AuthorityGrantId GrantId { get; }
    public AuthorityDigest GrantDigest { get; }
    public JournalStoreReference Store { get; }
    public LeaseFenceBinding LeaseFence { get; }
    public OperationIntent? Intent { get; }
    public OperationReceipt? Receipt { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public OperationJournalEntryDigest EntryDigest { get; }
    public static OperationJournalEntry CreateIntent(OperationJournalHead previousHead, AuthorityOperationId operationId, AuthorityDigest planDigest, AuthoritySetBinding authority, AuthorityGrantId grantId, AuthorityDigest grantDigest, JournalStoreReference store, LeaseFenceBinding leaseFence, OperationIntent intent, DateTimeOffset observedAtUtc);
    public static OperationJournalEntry CreateReceipt(OperationJournalHead previousHead, AuthorityOperationId operationId, AuthorityDigest planDigest, AuthoritySetBinding authority, AuthorityGrantId grantId, AuthorityDigest grantDigest, JournalStoreReference store, LeaseFenceBinding leaseFence, OperationReceipt receipt, DateTimeOffset observedAtUtc);
}

public sealed record OperationIntentCommand
{
    public ExecutionGrant Grant { get; }
    public OperationPlanEnvelope ExpectedPlan { get; }
    public OperationJournalHead ExpectedHead { get; }
    public LeaseFenceRecord ExpectedLease { get; }
    public OperationIntent Intent { get; }
    public static OperationIntentCommand Create(ExecutionGrant grant, OperationPlanEnvelope expectedPlan, OperationJournalHead expectedHead, LeaseFenceRecord expectedLease, OperationIntent intent);
}

public sealed record OperationReceiptCommand
{
    public AuthorityGrantId GrantId { get; }
    public AuthorityDigest GrantDigest { get; }
    public OperationPlanEnvelope ExpectedPlan { get; }
    public OperationJournalHead ExpectedHead { get; }
    public LeaseFenceRecord ExpectedLease { get; }
    public OperationReceipt Receipt { get; }
    public static OperationReceiptCommand Create(AuthorityGrantId grantId, AuthorityDigest grantDigest, OperationPlanEnvelope expectedPlan, OperationJournalHead expectedHead, LeaseFenceRecord expectedLease, OperationReceipt receipt);
}

public sealed record JournalAppendDecision
{
    public bool IsAppended { get; }
    public bool IsAlreadyPresent { get; }
    public JournalAppendRejection Rejection { get; }
    public OperationJournalHead? Head { get; }
    public static JournalAppendDecision Appended(OperationJournalHead head);
    public static JournalAppendDecision AlreadyPresent(OperationJournalHead head);
    public static JournalAppendDecision Rejected(JournalAppendRejection rejection);
}

public sealed record ExternalEffectMutationRequest
{
    public OperationPlanEnvelope ExpectedPlan { get; }
    public OperationPlanEffect Effect { get; }
    public OperationEffectRequestEnvelope Request { get; }
    public OperationJournalHead IntentHead { get; }
    public AuthorityGrantId GrantId { get; }
    public AuthorityDigest GrantDigest { get; }
    public LeaseFenceRecord ExpectedLease { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static ExternalEffectMutationRequest Create(OperationPlanEnvelope expectedPlan, OperationPlanEffect effect, OperationEffectRequestEnvelope request, OperationJournalHead intentHead, AuthorityGrantId grantId, AuthorityDigest grantDigest, LeaseFenceRecord expectedLease, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record ExternalEffectMutationDecision
{
    public bool IsTerminal { get; }
    public ExternalEffectMutationRejection Rejection { get; }
    public JournalReceiptOutcome? Outcome { get; }
    public ExternalEffectObservation? Observation { get; }
    public AuthorityDigest? ResultDigest { get; }
    public static ExternalEffectMutationDecision Applied(ExternalEffectObservation observation);
    public static ExternalEffectMutationDecision Rejected(ExternalEffectObservation observation, AuthorityDigest resultDigest);
    public static ExternalEffectMutationDecision Failed(ExternalEffectMutationRejection rejection);
}

public sealed record OperationExecutionDecision
{
    public bool IsRecorded { get; }
    public bool RequiresRecovery { get; }
    public OperationExecutionRejection Rejection { get; }
    public OperationJournalHead? Head { get; }
    public ExternalEffectObservation? Observation { get; }
    public static OperationExecutionDecision Recorded(OperationJournalHead head, ExternalEffectObservation observation);
    public static OperationExecutionDecision RecoveryRequired(OperationJournalHead head);
    public static OperationExecutionDecision Rejected(OperationExecutionRejection rejection, OperationJournalHead? head, ExternalEffectObservation? observation);
}

public sealed record JournalIntentMutationRequest
{
    public OperationIntentCommand Command { get; }
    public OperationJournalEntry Entry { get; }
    public GrantConsumptionRequest GrantConsumption { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static JournalIntentMutationRequest Create(OperationIntentCommand command, OperationJournalEntry entry, GrantConsumptionRequest grantConsumption, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record JournalReceiptMutationRequest
{
    public OperationReceiptCommand Command { get; }
    public OperationJournalEntry Entry { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static JournalReceiptMutationRequest Create(OperationReceiptCommand command, OperationJournalEntry entry, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed class OperationJournalService
{
    public static OperationJournalService Create(IExecutionRecoveryReadPort readPort, IExecutionRecoveryMutationPort mutationPort);
    public ValueTask<JournalAppendDecision> AppendIntentAsync(OperationIntentCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
    public ValueTask<JournalAppendDecision> AppendReceiptAsync(OperationReceiptCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
    public ValueTask<OperationExecutionDecision> ExecuteAsync(OperationIntentCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
}
~~~

## Reconstruction and recovery contracts

~~~csharp
public sealed record ExternalEffectObservation
{
    public OperationEffectId EffectId { get; }
    public ExecutionTarget RequestedTarget { get; }
    public ExecutionTarget? ResultObject { get; }
    public bool Exists { get; }
    public AuthorityDigest ObservationDigest { get; }
    public AuthorityDigest? AppliedRequestDigest { get; }
    public AuthorityDigest? ResultDigest { get; }
    public static ExternalEffectObservation Absent(OperationEffectId effectId, ExecutionTarget requestedTarget, AuthorityDigest observationDigest);
    public static ExternalEffectObservation Present(OperationEffectId effectId, ExecutionTarget requestedTarget, ExecutionTarget resultObject, AuthorityDigest observationDigest, AuthorityDigest appliedRequestDigest, AuthorityDigest resultDigest);
}

public sealed record ReconstructedEffect
{
    public OperationEffectId EffectId { get; }
    public ExternalEffectClassification Classification { get; }
    public OperationJournalEntryDigest? IntentDigest { get; }
    public OperationJournalEntryDigest? ReceiptDigest { get; }
    public AuthorityDigest ObservationDigest { get; }
    public static ReconstructedEffect Create(OperationEffectId effectId, ExternalEffectClassification classification, OperationJournalEntryDigest? intentDigest, OperationJournalEntryDigest? receiptDigest, AuthorityDigest observationDigest);
}

public sealed record OperationReconstructionRequest
{
    public OperationPlanEnvelope ExpectedPlan { get; }
    public OperationJournalHead ExpectedHead { get; }
    public static OperationReconstructionRequest Create(OperationPlanEnvelope expectedPlan, OperationJournalHead expectedHead);
}

public sealed record OperationReconstructionResult
{
    public OperationState State { get; }
    public OperationPlanEnvelope? ValidatedPlan { get; }
    public IReadOnlyList<ReconstructedEffect> Effects { get; }
    public OperationJournalHead? ValidatedHead { get; }
    public AuthorityDigest ReconstructionDigest { get; }
    public static OperationReconstructionResult Create(OperationState state, OperationPlanEnvelope? validatedPlan, IReadOnlyList<ReconstructedEffect> effects, OperationJournalHead? validatedHead, AuthorityDigest reconstructionDigest);
}

public sealed class OperationReconstructionService
{
    public static OperationReconstructionService Create(IExecutionRecoveryReadPort readPort);
    public ValueTask<OperationReconstructionResult> ReconstructAsync(OperationReconstructionRequest request, CancellationToken cancellationToken);
}

public sealed class RecoveryGrant : DurableTransitionGrant, IEquatable<RecoveryGrant>
{
    public AuthorityGrantId PredecessorGrantId { get; }
    public AuthorityDigest PredecessorGrantDigest { get; }
    public OperationPlanEnvelope ExpectedPlan { get; }
    public OperationJournalHead ExpectedHead { get; }
    public AuthorityDigest ReconstructionDigest { get; }
    public OperationEffectId EffectId { get; }
    public RecoveryAction Action { get; }
    public LeaseFenceBinding ExpectedLeaseFence { get; }
    public static RecoveryGrant Create(AuthorityGrantId grantId, AuthoritySetBinding authority, AuthorityActorId issuer, AuthorityActorId executor, ExecutionSubject subject, ExecutionTarget target, AuthorityOperationId operationId, JournalStoreReference grantStore, AuthorityDigest expectedGrantStoreHead, IReadOnlyList<GrantApprovalEvidence> approvals, DateTimeOffset issuedAtUtc, DateTimeOffset notBeforeUtc, DateTimeOffset expiresAtUtc, IdempotencyKey idempotencyKey, AuthorityGrantId predecessorGrantId, AuthorityDigest predecessorGrantDigest, OperationPlanEnvelope expectedPlan, OperationJournalHead expectedHead, AuthorityDigest reconstructionDigest, OperationEffectId effectId, RecoveryAction action, LeaseFenceBinding expectedLeaseFence);
    public bool Equals(RecoveryGrant? other);
}

public sealed class RetentionGrant : DurableTransitionGrant, IEquatable<RetentionGrant>
{
    public OperationPlanEnvelope ExpectedPlan { get; }
    public JournalStoreReference RetentionLedger { get; }
    public AuthorityDigest ExpectedRetentionLedgerHeadDigest { get; }
    public OperationJournalHead ExpectedHead { get; }
    public AuthorityDigest ReconstructionDigest { get; }
    public RetentionAction Action { get; }
    public JournalEntrySequence ThroughSequence { get; }
    public AuthorityDigest PolicyDigest { get; }
    public AuthorityDigest ArchiveSegmentDigest { get; }
    public AuthorityDigest? ExpectedArchiveReceiptDigest { get; }
    public LeaseFenceBinding ExpectedLeaseFence { get; }
    public static RetentionGrant Create(AuthorityGrantId grantId, AuthoritySetBinding authority, AuthorityActorId issuer, AuthorityActorId executor, ExecutionSubject subject, ExecutionTarget target, AuthorityOperationId operationId, JournalStoreReference grantStore, AuthorityDigest expectedGrantStoreHead, IReadOnlyList<GrantApprovalEvidence> approvals, DateTimeOffset issuedAtUtc, DateTimeOffset notBeforeUtc, DateTimeOffset expiresAtUtc, IdempotencyKey idempotencyKey, OperationPlanEnvelope expectedPlan, JournalStoreReference retentionLedger, AuthorityDigest expectedRetentionLedgerHeadDigest, OperationJournalHead expectedHead, AuthorityDigest reconstructionDigest, RetentionAction action, JournalEntrySequence throughSequence, AuthorityDigest policyDigest, AuthorityDigest archiveSegmentDigest, AuthorityDigest? expectedArchiveReceiptDigest, LeaseFenceBinding expectedLeaseFence);
    public bool Equals(RetentionGrant? other);
}

public sealed record OperationRecoveryCommand
{
    public RecoveryGrant Grant { get; }
    public OperationReconstructionRequest ReconstructionRequest { get; }
    public OperationReconstructionResult ExpectedReconstruction { get; }
    public OperationIntent Intent { get; }
    public OperationReceipt? Receipt { get; }
    public LeaseFenceRecord ExpectedLease { get; }
    public static OperationRecoveryCommand Create(RecoveryGrant grant, OperationReconstructionRequest reconstructionRequest, OperationReconstructionResult expectedReconstruction, OperationIntent intent, OperationReceipt? receipt, LeaseFenceRecord expectedLease);
}

public sealed record RecoveryIntentMutationRequest
{
    public OperationRecoveryCommand Command { get; }
    public OperationJournalEntry Entry { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static RecoveryIntentMutationRequest Create(OperationRecoveryCommand command, OperationJournalEntry entry, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record RecoveryReceiptMutationRequest
{
    public OperationRecoveryCommand Command { get; }
    public OperationJournalEntry Entry { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static RecoveryReceiptMutationRequest Create(OperationRecoveryCommand command, OperationJournalEntry entry, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record RetentionCommand
{
    public RetentionGrant Grant { get; }
    public OperationReconstructionRequest ReconstructionRequest { get; }
    public OperationReconstructionResult ExpectedReconstruction { get; }
    public LeaseFenceRecord ExpectedLease { get; }
    public static RetentionCommand Create(RetentionGrant grant, OperationReconstructionRequest reconstructionRequest, OperationReconstructionResult expectedReconstruction, LeaseFenceRecord expectedLease);
}

public sealed record RetentionLedgerEntryKind
{
    public static RetentionLedgerEntryKind Intent { get; }
    public static RetentionLedgerEntryKind Receipt { get; }
    public string Value { get; }
    public static RetentionLedgerEntryKind Parse(string value);
    public override string ToString();
}

public sealed record RetentionLedgerHead
{
    public JournalStoreReference Ledger { get; }
    public AuthorityOperationId OperationId { get; }
    public JournalEntrySequence Sequence { get; }
    public OperationJournalEntryDigest EntryDigest { get; }
    public AuthorityDigest HeadDigest { get; }
    public bool IsGenesis { get; }
    public static RetentionLedgerHead CreateGenesis(JournalStoreReference ledger, AuthorityOperationId operationId);
    public static RetentionLedgerHead CreateSuccessor(JournalStoreReference ledger, AuthorityOperationId operationId, JournalEntrySequence sequence, OperationJournalEntryDigest entryDigest);
}

public sealed record RetentionIntent
{
    public RetentionAction Action { get; }
    public JournalStoreReference SourceStore { get; }
    public OperationJournalHead SourceHead { get; }
    public JournalEntrySequence ThroughSequence { get; }
    public AuthorityDigest PolicyDigest { get; }
    public AuthorityDigest ArchiveSegmentDigest { get; }
    public AuthorityDigest? ExpectedArchiveReceiptDigest { get; }
    public static RetentionIntent Create(RetentionAction action, JournalStoreReference sourceStore, OperationJournalHead sourceHead, JournalEntrySequence throughSequence, AuthorityDigest policyDigest, AuthorityDigest archiveSegmentDigest, AuthorityDigest? expectedArchiveReceiptDigest);
}

public sealed record RetentionReceipt
{
    public OperationJournalEntryDigest IntentDigest { get; }
    public RetentionAction Action { get; }
    public AuthorityDigest ArchiveReceiptDigest { get; }
    public AuthorityDigest ResultDigest { get; }
    public static RetentionReceipt Create(OperationJournalEntryDigest intentDigest, RetentionAction action, AuthorityDigest archiveReceiptDigest, AuthorityDigest resultDigest);
}

public sealed record RetentionLedgerEntry
{
    public RetentionLedgerHead PreviousHead { get; }
    public RetentionLedgerEntryKind Kind { get; }
    public AuthoritySetBinding Authority { get; }
    public AuthorityGrantId GrantId { get; }
    public AuthorityDigest GrantDigest { get; }
    public LeaseFenceBinding LeaseFence { get; }
    public RetentionIntent? Intent { get; }
    public RetentionReceipt? Receipt { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public OperationJournalEntryDigest EntryDigest { get; }
    public static RetentionLedgerEntry CreateIntent(RetentionLedgerHead previousHead, AuthoritySetBinding authority, AuthorityGrantId grantId, AuthorityDigest grantDigest, LeaseFenceBinding leaseFence, RetentionIntent intent, DateTimeOffset observedAtUtc);
    public static RetentionLedgerEntry CreateReceipt(RetentionLedgerHead previousHead, AuthoritySetBinding authority, AuthorityGrantId grantId, AuthorityDigest grantDigest, LeaseFenceBinding leaseFence, RetentionReceipt receipt, DateTimeOffset observedAtUtc);
}

public sealed record RetentionAppendDecision
{
    public bool IsAppended { get; }
    public bool IsAlreadyPresent { get; }
    public RetentionAppendRejection Rejection { get; }
    public RetentionLedgerHead? Head { get; }
    public static RetentionAppendDecision Appended(RetentionLedgerHead head);
    public static RetentionAppendDecision AlreadyPresent(RetentionLedgerHead head);
    public static RetentionAppendDecision Rejected(RetentionAppendRejection rejection);
}

public sealed record RetentionArchiveRequest
{
    public RetentionCommand Command { get; }
    public RetentionLedgerHead IntentHead { get; }
    public RetentionIntent Intent { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static RetentionArchiveRequest Create(RetentionCommand command, RetentionLedgerHead intentHead, RetentionIntent intent, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record RetentionDestroyRequest
{
    public RetentionCommand Command { get; }
    public RetentionLedgerHead IntentHead { get; }
    public RetentionIntent Intent { get; }
    public RetentionReceipt ProtectedArchiveReceipt { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static RetentionDestroyRequest Create(RetentionCommand command, RetentionLedgerHead intentHead, RetentionIntent intent, RetentionReceipt protectedArchiveReceipt, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record RetentionEffectDecision
{
    public bool IsRecorded { get; }
    public RetentionEffectRejection Rejection { get; }
    public RetentionLedgerHead? Head { get; }
    public RetentionReceipt? Receipt { get; }
    public static RetentionEffectDecision Recorded(RetentionLedgerHead head, RetentionReceipt receipt);
    public static RetentionEffectDecision Rejected(RetentionEffectRejection rejection, RetentionLedgerHead? head, RetentionReceipt? receipt);
}

public sealed record RetentionMutationDecision
{
    public bool IsTerminal { get; }
    public RetentionEffectRejection Rejection { get; }
    public RetentionReceipt? Receipt { get; }
    public static RetentionMutationDecision Completed(RetentionReceipt receipt);
    public static RetentionMutationDecision Rejected(RetentionEffectRejection rejection);
}

public sealed record RetentionIntentMutationRequest
{
    public RetentionCommand Command { get; }
    public RetentionLedgerEntry Entry { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static RetentionIntentMutationRequest Create(RetentionCommand command, RetentionLedgerEntry entry, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record RetentionReceiptMutationRequest
{
    public RetentionCommand Command { get; }
    public RetentionLedgerEntry Entry { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static RetentionReceiptMutationRequest Create(RetentionCommand command, RetentionLedgerEntry entry, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

public sealed record OperationRecoveryDecision
{
    public bool IsAccepted { get; }
    public RecoveryRejection Rejection { get; }
    public OperationJournalHead? Head { get; }
    public static OperationRecoveryDecision Accepted(OperationJournalHead head);
    public static OperationRecoveryDecision Rejected(RecoveryRejection rejection);
}

public sealed class OperationRecoveryService
{
    public static OperationRecoveryService Create(IExecutionRecoveryReadPort readPort, IExecutionRecoveryMutationPort mutationPort);
    public ValueTask<OperationRecoveryDecision> RecoverAsync(OperationRecoveryCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
    public ValueTask<RetentionEffectDecision> RetainAsync(RetentionCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc, CancellationToken cancellationToken);
}
~~~

## Exact ports

~~~csharp
public interface IExecutionRecoveryReadPort : IExecutionAuthorityReadPort
{
    ValueTask<LeaseGrant?> ReadLeaseGrantAsync(JournalStoreReference grantStore, AuthorityGrantId grantId, CancellationToken cancellationToken);
    ValueTask<RecoveryGrant?> ReadRecoveryGrantAsync(JournalStoreReference grantStore, AuthorityGrantId grantId, CancellationToken cancellationToken);
    ValueTask<RetentionGrant?> ReadRetentionGrantAsync(JournalStoreReference grantStore, AuthorityGrantId grantId, CancellationToken cancellationToken);
    ValueTask<OperationPlanEnvelope?> ReadOperationPlanAsync(JournalStoreReference planStore, AuthorityDigest planDigest, CancellationToken cancellationToken);
    ValueTask<OperationEffectRequestEnvelope?> ReadEffectRequestAsync(JournalStoreReference planStore, AuthorityDigest requestDigest, CancellationToken cancellationToken);
    ValueTask<LeaseFenceRecord?> ReadLeaseAsync(AuthorityOperationId operationId, CancellationToken cancellationToken);
    ValueTask<OperationJournalHead?> ReadJournalHeadAsync(JournalStoreReference store, AuthorityOperationId operationId, CancellationToken cancellationToken);
    ValueTask<IReadOnlyList<OperationJournalEntry>> ReadJournalAsync(JournalStoreReference store, AuthorityOperationId operationId, CancellationToken cancellationToken);
    ValueTask<IReadOnlyList<ExternalEffectObservation>> ObserveEffectsAsync(AuthorityOperationId operationId, IReadOnlyList<OperationEffectId> effectIds, CancellationToken cancellationToken);
    ValueTask<RetentionLedgerHead?> ReadRetentionLedgerHeadAsync(JournalStoreReference retentionLedger, AuthorityOperationId operationId, CancellationToken cancellationToken);
    ValueTask<IReadOnlyList<RetentionLedgerEntry>> ReadRetentionLedgerAsync(JournalStoreReference retentionLedger, AuthorityOperationId operationId, CancellationToken cancellationToken);
}

public interface IExecutionRecoveryMutationPort : IExecutionAuthorityMutationPort
{
    ValueTask<LeaseDecision> CompareExchangeLeaseAsync(LeaseMutationRequest request, CancellationToken cancellationToken);
    ValueTask<JournalAppendDecision> AppendIntentAsync(JournalIntentMutationRequest request, CancellationToken cancellationToken);
    ValueTask<ExternalEffectMutationDecision> InvokeEffectAsync(ExternalEffectMutationRequest request, CancellationToken cancellationToken);
    ValueTask<JournalAppendDecision> AppendReceiptAsync(JournalReceiptMutationRequest request, CancellationToken cancellationToken);
    ValueTask<JournalAppendDecision> AppendRecoveryIntentAsync(RecoveryIntentMutationRequest request, CancellationToken cancellationToken);
    ValueTask<JournalAppendDecision> AppendRecoveryReceiptAsync(RecoveryReceiptMutationRequest request, CancellationToken cancellationToken);
    ValueTask<RetentionAppendDecision> AppendRetentionIntentAsync(RetentionIntentMutationRequest request, CancellationToken cancellationToken);
    ValueTask<RetentionMutationDecision> ArchiveJournalSegmentAsync(RetentionArchiveRequest request, CancellationToken cancellationToken);
    ValueTask<RetentionMutationDecision> DestroyArchivedJournalSegmentAsync(RetentionDestroyRequest request, CancellationToken cancellationToken);
    ValueTask<RetentionAppendDecision> AppendRetentionReceiptAsync(RetentionReceiptMutationRequest request, CancellationToken cancellationToken);
}
~~~

The exact immutable port DTOs are:

~~~csharp
public sealed record LeaseMutationRequest
{
    public LeaseAcquireCommand? Acquire { get; }
    public LeaseRenewCommand? Renew { get; }
    public LeaseReleaseCommand? Release { get; }
    public AuthorityActorId Actor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static LeaseMutationRequest ForAcquire(LeaseAcquireCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc);
    public static LeaseMutationRequest ForRenew(LeaseRenewCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc);
    public static LeaseMutationRequest ForRelease(LeaseReleaseCommand command, AuthorityActorId actor, DateTimeOffset observedAtUtc);
}

~~~

Exactly one `LeaseMutationRequest` command property is non-null. No adapter
type, credential, exception, command line, stdout, stderr, or mutable collection
is part of this API.
