# [SUBF-0145](README.md#subf-0145) Exact Value and Error Contract

| Field | Value |
| --- | --- |
| Classification | Normative value/error appendix to the [selected design](subf-0145-authority-grant-activation-design.md) |
| Status | `AcceptedFrozenDesign`; four implementation packages are `ReviewedLocalGreen`, and `EA-CONVERGE-01` exact-head hosted validation is pending |
| Correction | Closed: independent lease/fence negative states are preserved and unapproved/missing protected grant-store state is mapped exactly |
| Public signatures | [Exact public API contract](subf-0145-public-api-contract.md) |
| Test | [TEST-0212](test-cases.md#test-0212) |

All text is ordinal, ASCII, and already canonical; null, empty, leading/trailing
whitespace, NUL, C0/DEL control, non-ASCII, unpaired surrogate, or
normalization-changing input is invalid. The closed grammars are:

| Name | Exact grammar / bound |
| --- | --- |
| dot token | `[a-z][a-z0-9]*(?:\.[a-z][a-z0-9-]*)*`, 1..128 bytes |
| stable identity | `[a-z0-9][A-Za-z0-9._:/-]*`, 1..256 bytes |
| display token | first/last `[!-~]`, interior `[ -~]`, 1..128 bytes |
| exact commit | `[0-9a-f]{40}` |
| exact ref | exact commit or `refs/` plus 1..250 `[A-Za-z0-9._/-]`; no `..`, `//`, `@{`, trailing `/` or `.`, `.lock` segment, or backslash |
| repository path | 1..512 bytes, slash-relative; segments 1..128 `[A-Za-z0-9._-]`; no empty, `.`, `..`, leading/trailing slash, colon, or backslash |
| extension identity | `ext:[a-z0-9][a-z0-9.-]*:[a-z][a-z0-9-]*`, 7..256 bytes |

`ExecutionSubject.Kind`, `ExecutionTarget.Kind`, binding kind,
`OperationStage`, and every allowed-effect identity use dot token.
Subject/target/generation identities, lease owner/fence, and provider-object
identities use stable identity. Gate-snapshot identity and result name use
display token. Base/head/target reference fields use exact ref. Activating
target commit uses exact commit. Active policy identity uses extension
identity. Allowed paths use repository path. Scalar identity/store values keep
the stricter token grammar frozen in the API appendix.

`ReadGrantBinding` and `PlanGrantBinding` require exactly one nonempty scope:
allowed paths or provider-object identities. The authorizer, not either
factory, matches that scope to repository/provider capability. Every other
collection is nonempty except solo exceptions, which may be empty. Collections
reject null elements and duplicate canonical values; factories sort accepted
values ordinally. A separation pair cannot repeat or contain the same role.
Each solo exception contains exactly two distinct, sorted roles, both held by
its actor, and that pair equals one declared separation requirement. Duplicate
actor/pair exceptions are invalid; an actor crossing several pairs needs one
independently evidenced exception per pair. An exception authorizes only its
two roles and does not widen to any other role held by the actor.
`ApprovalAuthoritySetSnapshot.Create` requires exactly one member per
`AuthorityActorId`; a repeated actor, even with a different role list, throws
`ArgumentException` with parameter name `members`. No union/first-wins rule exists.

Complex collection order uses ordinal tuple comparison in this exact key
order: member `(Actor.Value)`; separation `(First.Value, Second.Value)`; solo
exception `(Actor.Value, AllowedRoles[0].Value, AllowedRoles[1].Value,
IndependentEvidenceDigest.Value)`; approval policy `(GrantKind)`; and grant
approval `(Approver.Value, Role.Value, EvidenceDigest.Value)`. Scalar role,
store, path, provider-object, and other string collections use their exposed
ordinal value. Tuple comparison advances to the next key only when the prior
key is ordinally equal.

Every public reference parameter passed as null throws
`ArgumentNullException` with its declared parameter name. `Parse(null)`
does the same; non-null invalid parse input throws `FormatException`;
`TryParse` returns `false`, assigns null, and never throws for input shape.
Negative revision or nonpositive generation throws
`ArgumentOutOfRangeException` with the numeric parameter name. Invalid
string, collection, duplicate, membership, role floor, timestamp order,
intrinsic genesis/successor shape, or digest-shape input throws
`ArgumentException` with the first offending declared parameter name. No
factory returns a partial value.

Every `DateTimeOffset` input has `Offset == TimeSpan.Zero`; values are neither
normalized nor preserved at a nonzero offset. A factory rejects the first
nonzero-offset timestamp with `ArgumentException` and that declared parameter
name. A service rejects nonzero `observedAtUtc` with
`ArgumentException(nameof(observedAtUtc))` before any port read. After the
pre-canceled-token rule, this validation precedes protected-state resolution.

`ExecutionGrant.Create` accepts any one of the four closed binding runtime
types with any one of the eight closed capabilities when every individual
value is structurally valid. It does not evaluate capability/binding
compatibility, held capabilities, protected state, or authority. Those states
remain constructible security inputs; only the authorizer returns
`CapabilityMismatch`. Binding factories validate only their own kind, scope,
role-floor, grammar, and intrinsic field shape.

`GrantValidationRequest.Create` and `ExtensionActivationCommand.Create`
require a non-null independent `expectedLeaseFence` but do not compare it with
the grant. They preserve generation, owner, and fencing-token mismatch inputs
for the services. Any inequality among grant generation, grant lease
generation, expected generation, and expected lease generation maps to
`GenerationMismatch`; the first owner/token inequality then maps to
`LeaseFenceMismatch`.

If the grant journal store is absent from the protected snapshot's approved
stores, or `ReadGrantStoreHeadAsync` returns null, the service returns
`GrantStoreDrift` without invoking a mutation port. An approved non-null head
is copied into the mutation request. Atomic mutation orders a consumed grant
ID/idempotency as `Replayed` before a post-read head mismatch as
`GrantStoreDrift`.

Supplied digests are immutable external content identities; a factory validates
their exact SHA-256 shape but does not claim the referenced bytes exist or are
trusted. Real authority comes only from protected-store re-resolution and exact
digest equality in the public use cases.

`ExecutionGrantDecision.Authorized()` is exactly
`IsAuthorized=true/Rejection=None`. `Rejected` rejects `None` with
`ArgumentException` and returns `false` plus the supplied non-None value.
`ActivationCasDecision.Activated` requires a non-null record and returns
`true/None/record`; `Rejected` rejects `None` and returns
`false/rejection/null`.

Service `Create` rejects a null port by declared parameter name. A
pre-canceled token throws `OperationCanceledException` carrying that token
before any read or mutation call. A port may honor cancellation only before
its atomic mutation begins. Once consumption or activation compare-exchange
begins, it must defer cancellation and return the terminal decision; it cannot
throw cancellation after consuming a grant. Activation consumes the grant and
installs the record in the same atomic call, so cancellation can never expose
one without the other. Other port exceptions propagate unchanged before any
success decision and confer no authority.

## Exact activation equality and rejection ownership

`CreateGenesis` enforces only zero epoch/version, null predecessor, and
non-null bootstrap evidence. `CreateSuccessor` enforces only positive
epoch/version, non-null predecessor, and null bootstrap evidence. Neither has a
protected prior record and therefore neither claims a +1 transition.
`RecordDigest` is computed by both factories and has no public input.
`ExtensionActivationCommand.Create` validates only non-null, individually
well-formed values; it preserves negative cross-field states for service tests.

The record digest is SHA-256 over this canonical preimage. The first scalar is
`meandai.execution-authority.extension-activation-record/v1`; it and every
following scalar are encoded as four-byte unsigned big-endian UTF-8 byte length
plus exact UTF-8 bytes. Encode a null scalar as length `0xFFFFFFFF`; encode a
collection as four-byte unsigned big-endian count followed by its elements:

1. repository kind, identity, generation identity; epoch and CAS invariant
   decimal strings; active policy identity/digest; active snapshot digest;
   activating commit; nullable previous-record and bootstrap digests;
2. approval count, then approvals sorted by the exact grant-approval tuple
   above, each encoded as approver value, role value, and evidence digest;
3. activation-grant, transition, and closure digests; and
4. authority-set ID, revision and revocation-epoch invariant decimal strings,
   and authority-set digest.

`RecordDigest` is lowercase hexadecimal SHA-256 of those bytes. It includes
the activation-grant digest, while that grant binds installed policy, snapshot,
transition, closure, target, commit, predecessor, and CAS but not
`RecordDigest`; therefore the graph is exact and cycle-free.

The service applies this fixed order:

1. missing protected authority -> `SnapshotUnavailable`; grant/current-record
   authority identity, revision, epoch, or digest drift -> `SnapshotDrift`;
2. missing protected record -> `ActivationRecordUnavailable`;
3. protected record unequal to `ExpectedCurrent` -> `ActivationRecordDrift`;
4. ordinary grant validation runs in the API's frozen first-mismatch order,
   using required `extension.activate`, the command's independent expected
   lease/fence, and a service-derived expected binding;
5. binding current digest/CAS unequal to expected current, binding target
   unequal to grant target/current repository/proposed repository, binding
   policy identity/digest/activating commit/proposed snapshot/transition/closure
   unequal to the corresponding proposed record/command values ->
   `BindingMismatch`;
6. proposed predecessor unequal to current record digest, epoch or CAS not
   current+1, proposed authority unequal to current protected authority,
   proposed approvals unequal to grant approvals, activation-grant digest
   unequal to grant digest, proposed transition/closure unequal to the typed
   binding, or recomputed record digest unequal to `Proposed.RecordDigest` ->
   `BindingMismatch`;
7. the atomic port rechecks authority, grant-store head/replay, and current
   activation digest/version using the corresponding frozen rejection; and
8. a simultaneous compare-exchange loss after every equality passed ->
   `CasConflict`.

Only step 3 owns pre-port `ActivationRecordDrift`; command/proposed/binding
inconsistency is `BindingMismatch`. Overflow when evaluating current+1 also
returns `BindingMismatch`. No rejected path consumes the grant or installs a
record.

This appendix and the public API are one freeze unit. Any grammar, range,
nullability, exception, collection, decision, digest, or cancellation change
reopens the complete `AcceptedFrozenDesign` gate.
