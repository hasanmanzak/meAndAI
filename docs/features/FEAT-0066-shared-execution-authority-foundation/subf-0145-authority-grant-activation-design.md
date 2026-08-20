# [SUBF-0145](README.md#subf-0145) - Authority, Grant, Publication, and Activation Design

| Field | Value |
| --- | --- |
| Classification | Selected Gate 2 design for the first [FEAT-0066](README.md) slice |
| Status | `AcceptedFrozenDesign`; four implementation packages are `ReviewedLocalGreen`, and `EA-CONVERGE-01` exact-head hosted validation is pending |
| Correction | Closed: independent expected lease/fence coordinates and protected grant-store failure mapping were added without changing type inventory, rejection set/order, FQNs, package identities/order/budgets, or ownership |
| Public API | [Exact public API contract](subf-0145-public-api-contract.md) |
| Values/errors | [Exact value and error contract](subf-0145-value-error-contract.md) |
| Delivery | [Micro-delivery plan](subf-0145-micro-delivery-plan.md) |
| Test | [TEST-0212](test-cases.md#test-0212) |
| Baseline | Exact main [`14ad828bcdde5f843cdbf12677b25f19736e5691`](https://github.com/hasanmanzak/meAndAI/commit/14ad828bcdde5f843cdbf12677b25f19736e5691) |

## Authority and activation condition

This packet was design-only. Its initial checkpoint and narrow corrections were
committed, pushed, independently reviewed with
`0 Blocking / 0 Important / 0 Minor`, and validated by exact-head Ubuntu plus
Windows stable CI before implementation resumed. Only the four
dependency-ordered packages in the
[micro plan](subf-0145-micro-delivery-plan.md#package-matrix) were authorized;
all four are now `ReviewedLocalGreen`. `EA-CONVERGE-01` final-sync validation is
pending. Merge, release, publication, consumer mutation, credentials, real
authority effects, authority transfer, [SUBF-0146](README.md#subf-0146), and
any later successor remain held.

## Gate 2 outcome

The slice supplies one additive C# authority boundary that:

- represents a protected approval-authority snapshot, stable identities,
  explicit separated roles, exact solo exceptions, and approved journal-store
  references;
- issues structurally typed, bounded, fresh, expiring, non-transitive execution
  grants with exact subject, target, operation, generation, idempotency,
  lease/fence, approval, and artifact/effect bindings;
- re-resolves protected authority immediately before an effect and atomically
  consumes a grant against the unchanged authority and grant-store head;
- breaks the sealed-report/publication-grant digest cycle with a publication
  envelope that retains the grant's report, provider, gate, result-name,
  effect, and idempotency binding; and
- activates an extension through one atomic protected-store operation that
  rechecks authority freshness, grant replay, the current activation record,
  and CAS version before consuming the grant and advancing the record.

The sole normative public signatures are in the
[API appendix](subf-0145-public-api-contract.md); exact grammars, factory
invariants, exceptions, and cancellation are in the
[value/error appendix](subf-0145-value-error-contract.md). This document is the
normative semantic/security authority. The micro plan is the normative delivery
and evidence authority. A conflict reopens the design gate.

## Ownership and dependencies

The slice owns:

- `MeAndAI.Operations.Domain.ExecutionAuthority` immutable value contracts;
- `MeAndAI.Operations.Application.ExecutionAuthority` protected read/mutation
  ports plus the public grant-authorizer and activation-service use cases;
- authority freshness, approval sufficiency, separation, replay, expiry,
  typed-binding, and activation-CAS rejection semantics; and
- the publication envelope and protected extension-activation record.

It depends on completed [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
for coarse provider/repository ports only. Existing `AuthorityGrant` and
`OperationalCapability` remain unchanged compatibility surfaces and are not
execution authority. The new ports refine the
[FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) read/mutation ports;
neither enum labels nor constructible domain values confer real authority.

[SUBF-0144](../FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0144)
owns proposed-extension semantics: exact additions, removals, revisions,
rationale, old/new digests, and deterministic transition/closure evidence.
This slice consumes only sealed transition, proposed-snapshot, and closure
digests, then owns the protected activation decision and CAS. It neither
redefines nor evaluates the transition.

Later features own real provider/local adapters, authenticated identities,
durable journal/recovery behavior, specialized release/direct-seal/
finalization/authority-transfer grants, and effect execution. The current slice
provides only ports and deterministic in-memory contract behavior.

The lease/fence boundary is deliberately narrow: this slice owns only the
immutable generation/owner/fencing coordinates carried by a grant and their
exact equality rejection during authorization. [SUBF-0146](README.md#subf-0146)
owns lease issue, acquisition, renewal, expiry, fencing lifecycle, durable
journal/receipt behavior, reconstruction, and recovery.
`GrantValidationRequest` and `ExtensionActivationCommand` each carry an
independent expected `LeaseFenceBinding`; neither service may compare the grant
to itself or derive owner/fence equality from an unfrozen field.

## Scope and non-goals

In scope:

- exact public values, factories, services, ports, errors, nullability, and
  collection behavior listed in the API appendix;
- typed read, plan, publication, and extension-activation grant bindings;
- compile-safe expected-red, pure focused tests, fake protected stores, and a
  deterministic two-contender activation fixture; and
- bounded records and graph-safe evidence.

Out of scope:

- Git, GitHub, filesystem, network, credential, workflow, or release adapters;
- journal/receipt/retention/reconstruction/recovery implementation from
  [SUBF-0146](README.md#subf-0146);
- consumer, scenario/status/owner/workflow final activation, merge, release, or
  publication;
- changes to shared architecture, protocol rules, feature indexes, common
  memory/logs, locks, packages, project files, or workflows; and
- granting `release.publish` or `authority.transfer` through a generic or
  caller-matched binding.

Every intermediate fact uses only the exact `Trait("Subfeature", value)` shape
with value [SUBF-0145](README.md#subf-0145) for cohort selection. It must not
assert [Scenario=TEST-0212](test-cases.md#test-0212) while the canonical
scenario authority remains `PlannedDocumentation`. Exact FQNs, markers, and
documentation links retain [TEST-0212](test-cases.md#test-0212) traceability;
scenario trait/status/owner activation is a separately authorized final atom.

## Protected authority semantics

`ApprovalAuthoritySetSnapshot` is obtained from the protected authority store,
not candidate or release content. Its identity, schema, monotonic revision,
revocation epoch, digest, members, mandatory role separation, exact solo
exceptions, approval policies, and nonempty approved journal-store list are
immutable.

The default five roles are proposal actor, envelope reviewer, final-plan
reviewer, grant issuer, and executor. The snapshot contains all ten pairwise
separation requirements. A single identity may cross one of those pairs only
when the same protected snapshot names that actor, exact role pair, and
independent evidence digest. Repository ownership, a serialized object, or an
empty/partial approval set never creates an exception.

The protected snapshot owns the required-approval policy for each constructible
binding kind. Mandatory floors are:

| Binding kind | Mandatory approval roles |
| --- | --- |
| `evidence.read` | `EnvelopeReviewer` |
| `plan.sealed` | `ProposalActor`, `FinalPlanReviewer` |
| `report.sealed` | `EnvelopeReviewer`, `FinalPlanReviewer` |
| `extension.transition` | `ProposalActor`, `FinalPlanReviewer` |

Policy may add roles but cannot remove a floor. The binding role set must equal
the current protected policy. Every required role has exactly one matching
member approval. Extra, missing, duplicate, nonmember, or wrong-role evidence
fails before mutation. Issuer/executor memberships and executing-actor identity
are independently checked.

## Typed grant and freshness semantics

Every grant binds the current authority-set identity/revision/revocation
epoch/digest; issuer, executor, approvals, exact capability, subject, target,
operation, generation, idempotency, lease/fence, UTC validity interval,
structurally typed artifact/effect binding, and its own digest.

The constructible bindings are closed:

- `ReadGrantBinding` binds the evidence-plan digest, base/head references,
  allowed repository paths, allowed provider object identities, and effect.
- `PlanGrantBinding` binds final-plan digest, base/head/target references,
  allowed repository paths, allowed provider object identities, operation
  stage, and effect.
- `PublicationGrantBinding` binds the already-sealed report, provider target,
  exact gate snapshot, result name, publication effect, and idempotency key.
- `ExtensionActivationGrantBinding` binds the current activation-record
  digest, proposed extension-snapshot digest, transition evidence, exact
  closure report, target, CAS version, and activation effect.

No string-keyed open bag or externally derived binding is accepted.
`repository.read`/`provider.read` accept only the read binding;
`repository.mutate`/`provider.mutate` accept only the plan binding;
`report.publish` accepts only the publication binding; and
`extension.activate` accepts only the activation binding. Capability/binding
mismatch is rejected before field comparison, preserving non-transitivity.
`release.publish` and `authority.transfer` always fail
`CapabilityMismatch` in this slice. Their later specialized contracts cannot
be approximated by equality against a caller-created binding.

Validity is exactly `NotBeforeUtc <= ObservedAtUtc < ExpiresAtUtc`, with grant
construction requiring `IssuedAtUtc <= NotBeforeUtc < ExpiresAtUtc`. A
replay, expiry-edge observation, drift, or mismatch is closed evidence and does
not permit fallback or partial mutation.

`ExecutionGrantAuthorizer.AuthorizeAndConsumeAsync` receives no caller-supplied
current snapshot. It resolves the protected snapshot, validates in the frozen
first-failure order, compares grant/lease/request/expected-fence generation,
then exact lease owner/fencing token, and rejects an unapproved journal store
or null resolved head as `GrantStoreDrift` without mutation. For an approved
store with a non-null head, the mutation compares the exact authority binding,
expected grant-store head, grant ID, and idempotency before atomically consuming.
A post-read authority/store drift fails closed.

## Publication envelope

An evaluation report contains no future publication grant. A publication grant
therefore binds the existing sealed-report digest and all publication fields,
but never the future envelope. `PublicationEnvelope.Create` accepts only the
grant and the proposed envelope digest; it copies every public field from the
grant and its typed binding. This eliminates a caller-controlled duplicate and
the report/grant/envelope digest cycle.

The envelope is data, not effect authority. A later publisher must still use
the public authorizer, current protected authority, authenticated actor, and
atomic one-time consumption before publishing.

## Extension activation and atomic CAS

The protected `ExtensionActivationRecord` binds repository, epoch/version,
active policy identity/digest, active snapshot digest, activating target
commit, predecessor or bootstrap evidence, exact approvals, activation-grant
digest, transition evidence, closure evidence, authority-set binding, and
record digest. Its factories compute the canonical record digest from all
preceding fields; callers cannot supply it, and the grant-to-record graph stays
cycle-free as frozen in the value/error appendix.

Genesis is explicit: epoch/version zero, null predecessor, and non-null
protected bootstrap evidence. A successor has null bootstrap evidence, a
non-null predecessor, and positive counters. The successor factory owns that
intrinsic shape; the activation service requires predecessor equality and
advances both counters by exactly one. Constructing a record cannot install it;
candidate content cannot create protected genesis.

`ExtensionActivationService.ActivateAsync`:

1. re-resolves the protected authority snapshot and activation record;
2. rejects a missing record or any mismatch with the command's expected
   current record;
3. validates the grant against the command's independent expected lease/fence,
   typed activation binding, actor, time, proposed record,
   transition/closure evidence, and successor invariants; and
4. makes one `TryActivateExtensionAsync` mutation call.

That port operation atomically re-compares the current authority binding,
grant-store head, unused grant/idempotency, activation-record digest/version,
then consumes the grant and exchanges the record. There is no separate
consume-then-CAS route. With two equal contenders, exactly one can return
`Activated`; the other returns `CasConflict` and no partial effect.

The authorizer's exact first-failure order is frozen in the
[API appendix](subf-0145-public-api-contract.md#cross-field-and-rejection-contract);
the activation service's distinct protected-record/CAS order is frozen in the
[value/error appendix](subf-0145-value-error-contract.md#exact-activation-equality-and-rejection-ownership).
No result contains arbitrary diagnostics or secrets.

## [TEST-0212](test-cases.md#test-0212) qualification freeze

The implementation sequence owns four and only four canonical expected-red
identities:

| Package | Marker | Exact FQN |
| --- | --- | --- |
| `EA-AUTHORITY-SNAPSHOT-01` | [`TEST-0212-SNAPSHOT-RED-0001`](test-cases.md#test-0212) | `MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_snapshot_and_role_separation_are_exact` |
| `EA-EXECUTION-GRANT-01` | [`TEST-0212-GRANT-RED-0002`](test-cases.md#test-0212) | `MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_grant_is_fresh_exact_non_transitive_and_single_use` |
| `EA-PUBLICATION-ENVELOPE-01` | [`TEST-0212-PUBLICATION-RED-0003`](test-cases.md#test-0212) | `MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_binds_sealed_report_and_publication_grant` |
| `EA-EXTENSION-ACTIVATION-01` | [`TEST-0212-ACTIVATION-RED-0004`](test-cases.md#test-0212) | `MeAndAI.Operations.Architecture.Tests.ExtensionActivationContractTests.TEST_0212_only_fresh_winning_cas_activates_extension` |

Each corrected-freeze red file is compile-safe before the public surface
exists. It has one `[Fact]`, one [Subfeature=SUBF-0145](README.md#subf-0145)
trait, one marker, and an ordinal
reflection absence oracle using assembly-qualified type/member names frozen in
the API appendix. The oracle first proves the owning assembly loads, then fails
only because the package's first required type/member is absent. Build failure,
zero discovery, a sibling failure, skip, infrastructure abort, or any other
message is not accepted red.

The source and accepted TRX SHA-256 are frozen before product work. The R
command has one pre-green attempt and no unchanged retry. For a future package,
after changed product evidence exists, the frozen original-oracle source is run
exactly once and must pass unchanged; typed final behavior tests then replace
the working copy and pass the same FQN. No sleep, network, or real
provider/store is allowed.
The already accepted snapshot and grant red artifacts retain their frozen
pre-correction source digests even though those historical bytes carry
[Scenario=TEST-0212](test-cases.md#test-0212). The active grant source remains byte-identical through
design-correction reconciliation; green transformation then replaces the
working trait, and the committed snapshot facts' traits, with
[Subfeature=SUBF-0145](README.md#subf-0145). The grant source hash is reverified, but its original
oracle is not invoked again; neither accepted R is rerun.

Focused negatives cover empty/partial/extra approval roles, all five separated
identities and exact solo exception, stale revision/epoch/digest, executing
actor, subject/target/operation/generation/lease/fence/capability/binding,
validity edges, replay, store-head drift, publication-field mismatch,
activation-record drift, missing protected record, and losing CAS.

## Prior art and recurrence disposition

- [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  is `Distinct`: it proves one workflow lease, not shared protected authority.
- [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125)
  is `Distinct`: it informs later recovery, not this grant/activation slice.
- [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191),
  [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192),
  and [TEST-0193](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193)
  are coexistence gates, not replacement evidence.
- The active project-memory record-link recurrence applies: every changed
  record link/stable ID is validated through [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175).
- The ContractSlice A VSTest suppression recurrence is `NotApplicable`;
  none of its FQNs or project routes are reused.
- An untracked governance packet is not final graph evidence. StructureOnly
  evidence is taken from the committed candidate checkpoint.

## AcceptedFrozenDesign gate

The design can advance from `DesignFreezeCandidate` only when:

1. this semantic design, the API appendix, value/error appendix, micro plan,
   [FEAT-0066](README.md),
   and [TEST-0212](test-cases.md#test-0212) are synchronized;
2. architecture/security, implementation-feasibility, and
   evidence/traceability fresh-diff reviews each report
   `0 Blocking / 0 Important / 0 Minor`;
3. exact local design checks in the micro plan are green;
4. one focused design-only commit is pushed to the dedicated PR branch; and
5. that exact head passes Ubuntu and Windows stable CI.

Any signature choice, scope widening, expected-red change, package reorder,
allowlist/budget increase, graph-limit increase, held capability enablement, or
new unresolved finding reopens this gate.

## Prospective graph-capacity contract

The candidate uses schema 2 only:

| Dimension | Limit |
| --- | ---: |
| Nodes | `512` |
| Edges | `8192` |
| Depth | `32` |
| Tree entries | `65536` |
| Tree-path bytes | `4194304` |
| Graph-path bytes | `32768` |
| Per-blob bytes | `1048576` |
| Aggregate parsed bytes | `8388608` |

Profiles through `v0.16.0` remain immutable. The selected design, API appendix,
value/error appendix, and micro plan are separate bounded blobs; each is `<=800` lines and
`<1048576` bytes. These limits are safety contracts, not permission to append
to older ContractSlice artifacts or to raise limits during implementation.

## Frozen design statement

This packet freezes a dependency-closed Gate 2 candidate, not an implementation
or completion claim. The implementation gate remains conditional until the
fresh-diff reviews, committed-tree structural evidence, and exact-head hosted
checks above are all closed.
