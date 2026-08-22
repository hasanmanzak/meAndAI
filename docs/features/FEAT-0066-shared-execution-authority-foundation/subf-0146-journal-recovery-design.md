# [SUBF-0146](README.md#subf-0146) Journal and Recovery Design

| Field | Value |
| --- | --- |
| Classification | Gate 1/2 selected-slice design |
| Status | `DesignFreezeCandidate`; records-only review, exact-head hosted validation, and maintainer acceptance remain required before implementation authority |
| Parent | [FEAT-0066](README.md) |
| Scenario | [TEST-0213](test-cases.md#test-0213) |
| Public signatures | [Exact public API contract](subf-0146-public-api-contract.md) |
| Values/errors | [Exact value and error contract](subf-0146-value-error-contract.md) |
| Delivery controls | [Micro-delivery plan](subf-0146-micro-delivery-plan.md) |
| Baseline | Exact main [`1d39a8bcfb18f4970c1642214a9415182ed82745`](https://github.com/hasanmanzak/meAndAI/commit/1d39a8bcfb18f4970c1642214a9415182ed82745) |

This packet freezes design only. It grants no production, test, workflow,
release, publication, adapter, consumer, or external-effect authority. The
four implementation packages remain conditional on the complete
[`AcceptedFrozenDesign`](subf-0146-micro-delivery-plan.md#acceptedfrozendesign-gate)
transition and a later explicit maintainer implementation directive.

## Dependency and ownership boundary

This slice extends the accepted [SUBF-0145](README.md#subf-0145) authority-set,
grant, exact binding, approved journal-store, lease/fence, idempotency, and
protected-CAS contracts. It must not weaken or privately replace them. It owns
only the protocol-neutral lease lifecycle, append-only operation journal,
deterministic reconstruction, recovery grant, and separately authorized
retention semantics. Git, GitHub, filesystem, provider, workflow, release, and
consumer adapters remain out of scope.

One operation has one protected immutable `OperationPlanEnvelope`, one
`AuthorityOperationId`, one approved `JournalStoreReference`, and one current
fenced owner. The envelope owns the complete ordered effect inventory; callers
cannot narrow it during reconstruction.
Every adapter effect is represented by a stable `OperationEffectId`; an
application cannot substitute its own lease, journal, receipt, or recovery
state. Live-effect observation is a read port and mutation is an independently
authorized write port.

Parallel work may own disjoint paths only. The selected package owns the exact
paths in its package allowlist. The feature README, test ledger, package
evidence, workflow files, shared architecture, and `.ai/memory` are
single-writer surfaces. A package may propose facts for those surfaces but may
not edit them unless the active grant names the path. No concurrent package
may change an earlier package's contract, marker, FQN, source digest, TRX
digest, or reviewed commit.

## Invariants

1. A protected single-use grant, current protected authority snapshot, exact
   protected plan, approved grant/journal stores and heads, and current
   lease/fence are all necessary; none implies another. Lease lifecycle uses a
   separate `LeaseGrant`; ordinary intent uses [SUBF-0145](README.md#subf-0145)
   `ExecutionGrant`; recovery and retention use their own grant types.
2. Lease acquisition and renewal are protected compare-and-swap operations.
   Only the record carrying the greatest accepted fencing token is current.
   Expiry never revives an older owner or token.
3. An authenticated, hash-chained intent is durably appended before its named
   external effect. Intent append failure forbids the effect.
4. A successful or deterministically rejected external effect is followed by
   an authenticated receipt. Receipt append failure is not success: it yields
   `RecoveryRequired` because the effect may already exist.
5. Every append binds operation, plan, authority set, grant ID and digest,
   qualified target/result identity, store, previous
   head, sequence, effect, lease generation/owner/token, entry kind, payload
   digest, and observed UTC time. Atomic append compares both prior head and
   fence.
6. Duplicate delivery is idempotent only when the complete canonical intent or
   receipt is byte-identical at its identity. Same identity with different
   content is divergence and fails closed.
7. Reconstruction is read-only. It re-resolves the protected plan and validates
   every plan effect plus the complete retained chain
   before trusting any state and joins journal evidence with exact live-effect
   observations. Missing, corrupt, truncated, reordered, forked, unauthenticated,
   or unverifiable evidence returns `UnrecoverableJournal`, never `Complete`.
8. Recovery is not ordinary continuation. It requires a protected, current-
   issuer, exact-executor, approved, single-use `RecoveryGrant` bound to the
   same operation, protected plan, authority snapshot, predecessor grant ID/
   digest, grant store/head, journal store/head, reconstruction digest, one
   permitted action, and a strictly newer current fence.
9. Retention is not recovery. Archive or destruction requires a separate
   `RetentionGrant` and a separate protected retention ledger. The operation
   journal cannot authorize or erase itself.
10. Cancellation before a port call has no effect. Once an atomic append or
    compare-and-swap begins, it reaches and reports one terminal decision.

## Lease lifecycle

`AcquireAsync` accepts only a separately issued and protected `LeaseGrant`
whose action is `Acquire` and whose predecessor is the exact absent, expired,
or released protected lease. It atomically consumes that grant while allocating
the store's next monotonically increasing fencing token. Genesis uses null
`ExpectedCurrent`, null predecessor digest, and sentinel
`(ExpectedGeneration, "unowned", "0")`; a successor lease grant binds the exact
predecessor digest, generation, owner, and token. Only after acquisition may an
ordinary effect grant be issued against the acquired fence. `RenewAsync` requires
exact operation, owner, generation, token, prior lease digest, unexpired
record, and protected authority equality. Renewal preserves the token and may
only extend expiry. `ReleaseAsync` requires the same exact coordinates and
records a terminal release; each action consumes its own exact `LeaseGrant` and
does not decrement or recycle the token.

Every journal and recovery mutation independently re-resolves the current
lease. A stale owner, generation, token, digest, expired lease, or simultaneous
CAS loss rejects before the named effect. A competing engine may acquire only
after expiry/release and receives a strictly greater fencing token. The newer
token makes all delayed writes from the predecessor reject.

## Intent, effect, and receipt protocol

For each effect `OperationJournalService`, not an adapter or caller, performs
this state machine:

~~~text
Planned
  -> append exact intent
IntentRecorded
  -> invoke named external-effect port exactly once
EffectObserved
  -> append exact receipt
Recorded
~~~

The intent append atomically consumes exactly one ordinary `ExecutionGrant`
already bound to the acquired fence and exact plan effect. A receipt is derived
from that consumed grant and needs no second grant. An intent owns the exact
request digest and idempotency key. A receipt owns the intent digest, outcome
(`Applied` or `Rejected`), qualified provider/repository result object and
version, result digest, and observation digest. It cannot widen the intent. An adapter exception or lost
response does not prove absence; reconstruction must observe the named live
effect before any retry. No automatic engine, adapter, PowerShell/C#, local/
provider, or mutation-actor fallback exists.

The service calls separate protected intent-CAS, exact effect-invocation, and
receipt-CAS ports. The append ports return `Appended`, `AlreadyPresent`, or one
closed rejection. Replay lookup by entry identity/digest occurs before current-
head comparison; `AlreadyPresent` is success only when the stored entry retains
the command's exact original prior-head transition and complete digest. It never
masks a fork, stale fence, or conflicting payload.

`ExecuteAsync` may invoke the effect only when its own intent mutation returns
fresh `Appended`. `AlreadyPresent` never carries execution authority: the
service immediately reconstructs. It returns the existing exact `Recorded`
evidence when already complete, or a typed `RecoveryRequired`, `Diverged`, or
`UnrecoverableJournal` decision without invoking the effect. Only the recovery
path may resume an intent recorded by an earlier attempt.

## Reconstruction classifications

Each expected effect is classified exactly once:

| State | Journal/live evidence | Permitted next step |
| --- | --- | --- |
| `NotStarted` | No receipt, the exact intent is absent or already recorded identically, and exact live observation is absent | Fresh recovery grant may append/confirm the exact intent and apply effect |
| `AppliedUnrecorded` | Exact intent exists, receipt does not, and live observation exactly matches intended effect | Fresh recovery grant may append the missing receipt only |
| `Recorded` | Exact intent and receipt form a valid chain and live observation matches the receipt | No mutation; continue reconstruction |
| `Diverged` | Journal and named live observation disagree, conflicting identity/content exists, or an effect absent from the protected plan appears in the journal | No automatic mutation; require a new ordinary plan/grant |

The foundation makes no completeness claim about effects that an adapter cannot
enumerate. It detects every unplanned journal effect and every mismatch among
the protected plan's named live effects; a consumer needing complete external
inventory must supply a separately designed completeness-proof adapter.
| `Complete` | Every effect in the re-resolved protected plan is `Recorded`, and plan/chain/head/fence/authority all validate | No recovery action |

`RecoveryRequired` is the aggregate state when at least one effect is
`NotStarted` or `AppliedUnrecorded` and none is divergent or unrecoverable.
`Diverged` dominates recoverable states. `UnrecoverableJournal` dominates all
other states. An empty valid genesis journal may classify an expected effect
as `NotStarted`; absent or unverifiable protected store state cannot.

The reconstruction result retains the validated protected plan. Its digest
commits to the validated journal head, authority, complete plan, ordered effects
and their classifications, ordered live observations, and aggregate state. A
recovery command carries the original reconstruction request; the service
re-resolves the protected plan, journal, and live observations and recomputes
that result before accepting a grant. A recovery grant cannot be reused
after any of those values changes.

## Recovery and retention

`RetryNotStarted` atomically consumes its recovery grant while appending or
confirming the exact frozen intent, then invokes the exact effect and appends
its receipt through separate service-owned phases. `RecordAppliedUnrecorded`
atomically consumes its grant with the missing exact receipt and never invokes
the effect. It
must not invoke the effect. Any other classification, action, effect, head,
authority, plan, predecessor grant, observation, or fence mismatch is rejected.
The recovery grant is single-use and non-transitive. It grants no ordinary
mutation, publication, authority transfer, or retention capability.

Retention operates only after a freshly recomputed `Complete` operation state.
The service atomically consumes a retention grant while appending a retention-
ledger intent, calls an exact archive/destroy port, then appends the matching
retention receipt. `Archive` copies the exact retained segment and records its
segment and archive-receipt digests before any source deletion.
`DestroyArchivedSegment` requires the
matching archive receipt, current store/head, policy identity, minimum-retained
boundary, fresh separate retention grant, and newer/current fence. Genesis,
the current head, unarchived entries, active recovery evidence, and the
retention ledger are never destroyable by this slice.

## Failure semantics

- Invalid public values throw only the frozen argument/format exceptions.
- Expected protected-state, authority, lease, journal, observation, recovery,
  retention, replay, and CAS failures return closed rejection values.
- Port infrastructure exceptions propagate unchanged and confer no authority.
- An unknown external-effect result is represented as recovery-required input,
  not success or safe-to-retry proof.
- `UnrecoverableJournal` and `Diverged` are terminal for this recovery grant;
  an operator must produce a separately reviewed ordinary plan and grant.
- No log text, process exit code, engine-state label, branch name, or mutable
  workflow state is authority or durable completion evidence.

## Review questions

Gate review must independently prove: intent-before-effect ordering; receipt
failure ambiguity; monotonic fences; chain authentication and fork detection;
classification precedence; exact recovery binding and newer fence; retry versus
receipt-only separation; independent retention authority/ledger; cancellation
atomicity; no adapter/consumer leakage; and package/path independence. Any
semantic, signature, value, error, marker, FQN, allowlist, cap, or transition
change reopens the complete design gate.
