# [SUBF-0146](README.md#subf-0146) Exact Value and Error Contract

| Field | Value |
| --- | --- |
| Classification | Normative value/error appendix to the [journal/recovery design](subf-0146-journal-recovery-design.md) |
| Status | `DesignFreezeCandidate`; not implementation authority |
| Public signatures | [Exact public API contract](subf-0146-public-api-contract.md) |
| Test | [TEST-0213](test-cases.md#test-0213) |

All public text is ordinal ASCII and already canonical. Null, empty,
leading/trailing whitespace, NUL, C0/DEL control, non-ASCII, unpaired
surrogate, or normalization-changing input is invalid. No public value silently
normalizes, truncates, defaults, unions, or applies first/last-wins behavior.

## Exact grammar and ranges

| Value | Exact rule |
| --- | --- |
| `OperationEffectId` | SUBF-0145 scalar token grammar; 1..128 bytes |
| `OperationJournalEntryDigest` | exactly 64 lowercase hexadecimal characters; `FromHashBytes` accepts exactly 32 bytes |
| `JournalEntrySequence` | non-negative; genesis is `0`; every append is prior + 1 |
| fencing token | positive signed 64-bit integer; first accepted token is at least `1`; every later acquisition is strictly greater than every token previously accepted for that operation |
| all supplied `AuthorityDigest` values | exact SUBF-0145 SHA-256 shape |
| UTC timestamps | `Offset == TimeSpan.Zero`; no normalization from another offset |

Closed wire values are exact:

| Type | Static value -> wire token |
| --- | --- |
| `JournalEntryKind` | `Intent -> journal.intent`; `Receipt -> journal.receipt` |
| `JournalReceiptOutcome` | `Applied -> receipt.applied`; `Rejected -> receipt.rejected` |
| `ExternalEffectClassification` | `NotStarted -> effect.not-started`; `AppliedUnrecorded -> effect.applied-unrecorded`; `Recorded -> effect.recorded`; `Diverged -> effect.diverged` |
| `OperationState` | `RecoveryRequired -> operation.recovery-required`; `Diverged -> operation.diverged`; `UnrecoverableJournal -> operation.unrecoverable-journal`; `Complete -> operation.complete` |
| `RecoveryAction` | `RetryNotStarted -> recovery.retry-not-started`; `RecordAppliedUnrecorded -> recovery.record-applied-unrecorded` |
| `RetentionAction` | `Archive -> retention.archive`; `DestroyArchivedSegment -> retention.destroy-archived-segment` |
| `LeaseAction` | `Acquire -> lease.acquire`; `Renew -> lease.renew`; `Release -> lease.release` |
| `RetentionLedgerEntryKind` | `Intent -> retention.intent`; `Receipt -> retention.receipt` |

For every rejection type, each listed static name maps mechanically and only to
`<prefix>.<kebab-name>` where each ASCII uppercase boundary starts a lowercase
hyphenated word: `None -> <prefix>.none`, `CasConflict ->
<prefix>.cas-conflict`. Prefixes are `lease`, `journal`, `recovery`,
`effect-mutation`, `operation-execution`, `retention-append`, and
`retention-effect` for their correspondingly named rejection types. `Parse`
accepts only the exact listed tokens; there are no aliases.

Every public reference parameter passed as null throws
`ArgumentNullException` with its declared parameter name. `Parse(null)` does
the same; invalid non-null input throws `FormatException`; `TryParse` returns
`false`, assigns null, and never throws for shape. Negative sequence or
nonpositive fencing token throws `ArgumentOutOfRangeException` with the
numeric parameter name. Invalid collection, duplicate, intrinsic field shape,
timestamp order, genesis/successor form, nullable-discriminator shape, or
digest shape throws `ArgumentException` with the first offending declared
parameter name. No factory returns a partial value.

Collections reject null elements and duplicate canonical values and sort
ordinally by exposed identity. Expected effects and observations sort by
`EffectId.Value`; journal entries sort by `Sequence.Value`; reconstructed
effects sort by `EffectId.Value`. A journal rejects duplicate sequence,
entry digest, or effect/kind identity even when other fields differ.

## Intrinsic construction rules

`LeaseFenceRecord.Create` requires positive generation and fencing token,
`AcquiredAtUtc < ExpiresAtUtc`, and UTC timestamps. `IsReleased=false` requires
null `ReleasedAtUtc`; `IsReleased=true` requires non-null UTC
`AcquiredAtUtc <= ReleasedAtUtc <= ExpiresAtUtc`. A released record cannot be
renewed. Factories validate
intrinsic shape only and do not claim the record is protected/current.

`OperationJournalHead.CreateGenesis` fixes sequence `0`, `IsGenesis=true`, and
`OperationJournalEntryDigest.FromHashBytes(SHA256(UTF8("meandai.execution-authority.operation-journal-genesis-entry/v1")))`;
it has no entry. The retention-ledger genesis uses the same rule with exact
ASCII label `meandai.execution-authority.retention-ledger-genesis-entry/v1`.
`CreateSuccessor` requires positive sequence, `IsGenesis=false`, and a
non-genesis entry digest. `OperationJournalEntry.CreateIntent` requires non-null
intent/null receipt and kind `Intent`; `CreateReceipt` requires null intent/
non-null receipt and kind `Receipt`. Genesis has no public entry. Every entry
has a non-null previous head and its sequence is exactly previous sequence + 1.

An intent contains the effect, request digest, and idempotency key. A receipt
must name the same effect as its referenced intent. `Applied` requires an exact
non-null qualified `ExecutionTarget` result object/version plus result and
observation digests. `Rejected` requires null result object but still requires
deterministic result and observation digests; an exception or unknown result is not a
receipt. Receipt factory shape does not prove that the intent exists; the
service and atomic port own that protected-state check.

`OperationPlanEnvelope.Create` requires a nonempty, duplicate-free effect list,
sorts it by `EffectId.Value`, and computes `PlanDigest` over operation,
authority, approved protected plan store, approved journal store, and every effect's subject, target, request
digest, and idempotency key. Construction is not authority. Every service
re-resolves the protected plan by digest and requires complete equality; only
that protected inventory defines completeness. A caller cannot omit or add an
effect.

`OperationEffectRequestEnvelope.SchemaId` uses the exact dot-token grammar.
`CanonicalPayload` is `1..65536` bytes, is defensively copied on input/output,
contains only the schema-defined mutation request (never credentials), and is
hashed with effect ID and schema ID. Before intent construction or effect
invocation the service resolves it from the protected plan store by digest,
requires complete byte equality and `EffectId` equality, and passes that exact
envelope to the adapter. Adapters obtain credentials only from their protected
environment and must reject an unsupported schema before mutation.

`ExternalEffectObservation.Absent` requires `Exists=false`, the plan's exact
`RequestedTarget`, null `ResultObject`, and null applied-request/result digests.
`Present` requires `Exists=true`, that same requested target, a non-null
qualified result object/version, and both digests. `OperationReceipt.Applied`
copies that exact result object and digest; it never invents either. Every
observation has a non-null observation digest. A request/result mismatch
is constructible input so reconstruction can return `Diverged`.

`OperationReconstructionResult.Create` requires one distinct reconstructed row
per protected `ValidatedPlan.Effects` item. `Complete` requires a non-null
validated plan/head and every protected effect `Recorded`; `RecoveryRequired`
requires at least one `NotStarted` or `AppliedUnrecorded` and no `Diverged`;
`Diverged` requires at least one `Diverged`; `UnrecoverableJournal` has no
trusted effect rows and may have no validated plan/head. These are intrinsic consistency
rules, not proof that the digest is trusted.

`DurableTransitionGrant` values require a current issuer with `GrantIssuer`, an
exact executor with `Executor`, the active authority policy's required
approvals, issuer/executor separation unless an exact independently evidenced
solo exception applies, a protected approved grant store/head, and a nonempty
validity interval. Factories preserve constructible negative authority inputs;
services re-resolve the protected concrete grant by store/ID, require full
equality and recomputed digest, and atomically consume its ID/idempotency.
Every subtype requires UTC `IssuedAtUtc <= NotBeforeUtc < ExpiresAtUtc` and is
fresh exactly when `NotBeforeUtc <= observedAtUtc < ExpiresAtUtc`.

Every `LeaseGrant`, `RecoveryGrant`, and `RetentionGrant` maps by closed runtime
type to the existing protected policy kind `plan.sealed`; there is no caller-
selectable kind. Its mandatory floor is exactly `ProposalActor` plus
`FinalPlanReviewer`, and the protected snapshot may add but not remove roles.
Each required role has exactly one approval; extra, missing, duplicated,
nonmember, or wrong-role evidence rejects as the subtype's closed
`GrantRejected`/`GrantDrift` path. Existing SUBF-0145 policy kinds and source
remain unchanged.

`RecoveryGrant.Create` requires exactly one action/effect and a nonempty
interval `NotBeforeUtc < ExpiresAtUtc`. `RetentionGrant.Create` requires one
action, nonempty interval, and non-negative boundary. Neither factory issues
authority. A retention destroy grant additionally requires a non-null exact
archive-receipt digest; archive requires it null. Both grants bind the complete
protected plan and reconstruction, not a caller-selected effect inventory.

`LeaseAcquireCommand.ExpectedCurrent` is null only for genesis acquisition.
Its separately issued `LeaseGrant` predecessor fence must then equal
`(ExpectedGeneration, "unowned", "0")` and predecessor digest must be null. A
successor acquisition requires the exact expired or released predecessor and
the lease grant must equal that record's digest, generation, owner `Value`, and
invariant-decimal fencing token.
Renewal and release use the same exact current-record equality. Factories
preserve mismatch inputs; the service returns the closed rejection.

For every lease grant, subject is exactly
`ExecutionSubject.Create("operation.lease", OperationId.Value)` and target is
exactly `ExecutionTarget.Create("operation.lease-record", OperationId.Value,
ProposedGeneration.Value.ToString(InvariantCulture))`; inequality is
`GrantRejected`. Action must equal the invoked service method. Genesis acquire
uses the command's positive `ExpectedGeneration` as `ProposedGeneration`.
Successor acquire requires `ProposedGeneration == ExpectedCurrent.Generation +
1`; overflow is `CasConflict`. Renew and release preserve the exact current
generation. Acquire/renew command expiry must equal `ProposedExpiresAtUtc`;
renew additionally requires it strictly greater than current expiry. Release
requires `ProposedExpiresAtUtc == ExpectedCurrent.ExpiresAtUtc` and changes
only release time/state. Action or expiry mismatch is `GrantRejected`;
generation mismatch is `GenerationMismatch`. No action reuses another lease
grant ID or idempotency key.

The bridge from numeric `LeaseFenceRecord.FencingToken` to SUBF-0145
`LeaseFenceBinding.FencingToken` is its invariant ASCII decimal form with no
sign and no leading zero. Numeric zero is permitted only in the exact genesis
`unowned` sentinel and never in a protected lease record.

`OperationRecoveryCommand.Create` preserves negative cross-field inputs for
service tests. `RetryNotStarted` requires an intent and null receipt at service
authorization time. `RecordAppliedUnrecorded` requires matching intent and
receipt and must not invoke the external effect. Retention is never carried by
`OperationRecoveryCommand`.

## Canonical digests

Every digest preimage uses four-byte unsigned big-endian UTF-8 byte length plus
exact UTF-8 bytes for a scalar. Null is length `0xFFFFFFFF`. A collection is a
four-byte unsigned big-endian count followed by its canonical ordered elements.
Signed integers use invariant decimal ASCII. Booleans are lowercase `true` or
`false`; UTC timestamps use exact `yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'`.

Each preimage begins with exactly one version label:

| Digest | Version label and ordered content |
| --- | --- |
| protected plan | `meandai.execution-authority.operation-plan-envelope/v1`; operation, authority binding, protected plan store, journal store, ordered effects as effect ID, subject, target, request digest, idempotency |
| effect request | `meandai.execution-authority.operation-effect-request/v1`; effect ID, schema ID, canonical payload bytes |
| durable transition grant common | subtype version label; grant ID, authority, issuer, executor, subject, target, operation, grant store/head, ordered approvals, issued/not-before/expires, idempotency, then subtype fields |
| lease grant | `meandai.execution-authority.lease-grant/v1`; common fields, action, predecessor fence/digest, proposed generation/expiry |
| lease record | `meandai.execution-authority.lease-record/v1`; operation, owner, generation, fencing token, acquired/expiry, nullable released-at, released, authority-set binding |
| journal entry | `meandai.execution-authority.operation-journal-entry/v1`; store, operation, plan, authority binding, grant ID/digest, prior head, sequence, lease generation/owner/token, kind, effect, kind-specific request/result object/version/digests, observed UTC |
| journal head | `meandai.execution-authority.operation-journal-head/v1`; store, operation, sequence, entry digest |
| reconstruction | `meandai.execution-authority.operation-reconstruction/v1`; validated protected plan, store/head, ordered observations, ordered classifications, aggregate state |
| recovery grant | `meandai.execution-authority.recovery-grant/v1`; common fields, predecessor grant ID/digest, complete protected plan, journal head, reconstruction, effect, action, lease generation/owner/token |
| retention grant | `meandai.execution-authority.retention-grant/v1`; common fields, complete protected plan, journal and retention-ledger heads, reconstruction, action, boundary, policy, archive segment/receipt bindings, lease generation/owner/token |
| retention entry | `meandai.execution-authority.retention-ledger-entry/v1`; ledger and operation from prior head, prior head digest/sequence, successor sequence, authority, grant ID/digest, fence, kind, kind-specific archive/destroy payload, observed UTC |
| retention head | `meandai.execution-authority.retention-ledger-head/v1`; ledger, operation, sequence, entry digest |

The exposed digest is lowercase SHA-256 of the preimage. Supplied digests are
content identities only; authority comes from protected-store resolution and
exact equality. Digest graphs are acyclic: a value never includes its own
digest.

## Closed rejections

`LeaseRejection` exposes exactly: `None`, `SnapshotUnavailable`,
`SnapshotDrift`, `GrantRejected`, `ActorMismatch`, `LeaseUnavailable`,
`LeaseStillActive`, `LeaseExpired`, `LeaseReleased`, `GenerationMismatch`,
`LeaseFenceMismatch`, `Replay`, and `CasConflict`.

`JournalAppendRejection` exposes exactly: `None`, `SnapshotUnavailable`,
`SnapshotDrift`, `GrantRejected`, `ActorMismatch`, `JournalStoreDrift`,
`JournalUnavailable`, `JournalCorrupt`, `HeadMismatch`, `SequenceMismatch`,
`LeaseUnavailable`, `LeaseExpired`, `LeaseFenceMismatch`, `IntentMissing`,
`EntryConflict`, `Replay`, and `CasConflict`.

`RecoveryRejection` exposes exactly: `None`, `SnapshotUnavailable`,
`SnapshotDrift`, `GrantUnavailable`, `GrantDrift`, `GrantNotYetValid`,
`GrantExpired`, `ActorMismatch`, `PredecessorMismatch`, `OperationMismatch`,
`PlanMismatch`, `JournalStoreDrift`, `JournalUnavailable`, `JournalCorrupt`,
`HeadMismatch`, `ReconstructionMismatch`, `ClassificationMismatch`,
`ActionMismatch`, `EffectMismatch`, `LeaseUnavailable`, `LeaseExpired`,
`LeaseFenceMismatch`, `FenceNotNewer`, `RetentionPolicyMismatch`, `Replay`,
and `CasConflict`.

`ExternalEffectMutationRejection`, `OperationExecutionRejection`,
`RetentionAppendRejection`, and `RetentionEffectRejection` expose exactly the
static values in the [public API](subf-0146-public-api-contract.md); their wire
tokens follow the frozen mapping above.

`LeaseDecision`, `JournalAppendDecision`, `OperationRecoveryDecision`, and
`RetentionAppendDecision` accepted/already-present factories require their
non-null success head/record and `None`; their rejected factories require a
non-`None` rejection and expose no success value.

`ExternalEffectMutationDecision.Applied` is terminal with `None`, `Applied`, a
present observation and its result digest. Its deterministic `Rejected`
factory is also terminal with `None`, outcome `Rejected`, an exact observation,
and a deterministic result digest; this is an effect outcome, not a port
failure. `Failed` requires a non-`None` rejection and exposes no outcome,
observation, or result.

`OperationExecutionDecision.Recorded` is `IsRecorded=true`,
`RequiresRecovery=false`, `None`, and exact head/observation.
`RecoveryRequired` is false/true with rejection `RecoveryRequired`, the intent
head, and null observation. `Rejected` is false/false with one non-`None`
non-recovery rejection and may carry only the exact phase head/observation
already durably obtained. `RetentionMutationDecision.Completed` and
`RetentionEffectDecision.Recorded` require `None` plus their exact receipt/head;
their rejected factories require non-`None` and may expose only immutable
phase evidence explicitly accepted by their nullable parameters. No such
evidence is authority or a success value. No arbitrary diagnostic text crosses
the public boundary.

## Fixed service rejection order

After the pre-canceled-token and UTC rules, services apply the first applicable
rejection in this order; rejected paths invoke no mutation port.

### Lease

1. protected authority unavailable/drift;
2. protected concrete `LeaseGrant` unavailable/drift, grant-store-head drift,
   issuer/executor/approval/time/action mismatch, or replay;
3. protected lease unavailable/shape mismatch where required;
4. active/expired/released/generation/fence mismatch;
5. atomic replay, protected-state recheck, or CAS conflict.

Acquire treats an absent lease as available. An existing unexpired/unreleased
lease returns `LeaseStillActive`. Renewal/release require an existing exact
record. Acquisition after expiry/release allocates a strictly greater token;
overflow returns `CasConflict` without mutation.

### Journal append

1. protected authority and complete protected plan equality;
2. for intent, ordinary SUBF-0145 grant and approved grant-store head; for
   receipt, exact prior consumed grant ID/digest from the protected intent;
3. approved journal store/head availability/integrity and current unexpired
   exact lease/fence;
4. lookup exact entry identity: identical digest plus identical original
   prior-head transition -> `AlreadyPresent`; conflicting identity ->
   `EntryConflict`;
5. for a new entry only, head then sequence equality and receipt's referenced
   intent existence/equality;
6. atomic authority/plan/grant/fence/head recheck and CAS; intent atomically
   consumes its ordinary grant, receipt never consumes it again.

Intent append failure returns without invoking an external-effect port.
`OperationJournalService.ExecuteAsync` invokes the effect only after a fresh
`Appended` result from its own intent mutation. `AlreadyPresent` triggers
reconstruction and returns existing `Recorded` evidence or typed
`RecoveryRequired`/`Diverged`/`UnrecoverableJournal` without effect invocation.
Receipt failure after an observed effect returns rejection and the caller must
enter reconstruction; it cannot report ordinary success.

### Reconstruction

1. protected authority and protected plan unavailable or drift;
2. protected store/head unavailable or drift;
3. structural sequence, previous-head, digest, entry-kind, duplicate, fork,
   and truncation validation;
4. one exact live observation per protected-plan effect and rejection of every
   unplanned journal effect; this slice does not claim an adapter-wide live
   inventory completeness proof;
5. per-effect classification in protected ordinal effect order;
6. aggregate precedence `UnrecoverableJournal > Diverged > RecoveryRequired > Complete`;
7. canonical reconstruction digest retaining the validated plan.

Structural/integrity failure returns `UnrecoverableJournal` rather than an
exception or partial trusted row. Port infrastructure exceptions still
propagate unchanged.

### Recovery and retention

Recovery applies:

1. protected authority, concrete recovery grant, approved grant store/head,
   recomputed grant digest, issuer/executor/approval/time, and single-use state;
2. predecessor grant ID/digest, operation, complete protected plan, exact
   subject/target effect, journal store/head, and exact actor;
3. rerun the supplied reconstruction request through protected plan/journal/
   live reads and require complete result/digest equality;
4. permitted classification/action and exact effect/intent/receipt equality;
5. current unexpired lease with a token strictly newer than the predecessor
   effect's fence;
6. `RetryNotStarted`: atomically consume grant plus append/confirm intent,
   invoke the exact effect, then append receipt; `RecordAppliedUnrecorded`:
   atomically consume grant plus append the observed exact receipt and never
   invoke the effect;
7. each atomic phase rechecks authority, plan, grant, journal head, and fence.

Retention applies:

1. the same protected authority/concrete-grant/store/head/issuer/executor/
approval/time/single-use checks with a retention grant;
2. require the grant subject/target to identify the protected journal segment,
   rerun reconstruction, and require exact `Complete` for the full protected
   plan, exact journal head, and current fence;
3. validate the protected retention ledger/head, policy, boundary, segment
   digest, and action; destroy also resolves and matches the protected archive
   receipt named by the grant;
4. atomically consume the grant with the exact retention intent, invoke only
   the named archive or destroy port, then append its exact retention receipt;
5. identical retention-entry replay is checked before new-head comparison;
   every phase rechecks protected heads and fence.

`RetryNotStarted` invokes the named effect once only after its intent append is
durable. `RecordAppliedUnrecorded` never invokes it. `Diverged`, `Complete`, or
`UnrecoverableJournal` cannot be recovered with this grant. Retention cannot
delete genesis, current head, unarchived/current-recovery evidence, or the
retention ledger.

## Cancellation and port failures

A pre-canceled token throws `OperationCanceledException` carrying that token
before validation or any port call. A port may honor cancellation only before
its atomic mutation begins. Once lease CAS, append, recovery, or retention CAS
begins, it defers cancellation and returns a terminal decision. Read/mutation
port exceptions propagate unchanged; they never create a grant, receipt,
completion, or safe-to-retry fact.

Any grammar, range, collection, digest, nullability, rejection, ordering,
cancellation, or exception change reopens the complete design gate.
