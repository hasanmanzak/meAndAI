# DEC-0035 - Make the Executable Protocol the Governance and Execution Authority

- Classification: Decision
- Status: Accepted; implementation authority withheld
- Date: 2026-07-29
- Accepted: 2026-07-29 by maintainer directive; [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164) owns durable integration and validation evidence
- Decision owners: Maintainer and meAndAI architecture owner
- Owning epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Owning task: [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164)
- Full architecture: [Protocol Governance and Execution Architecture](../architecture/protocol-governance-and-execution/README.md)
- Transition register: [Architecture Transition and Carry-Forward Register](../architecture/protocol-governance-and-execution/transition-register.md)
- Successor allocation: [Successor Delivery and Qualification Plan](../architecture/protocol-governance-and-execution/successor-delivery-plan.md)
- Preserved WIP disposition: [Exact Extraction Ledger](../architecture/protocol-governance-and-execution/wip-extraction-ledger.md)
- Red-team review: [Closed at design level](../architecture/protocol-governance-and-execution/red-team-review.md)
- Related decisions: [DEC-0001](DEC-0001-portable-protocol-reference.md), [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0018](DEC-0018-release-declared-consumer-migrations.md), [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md), [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md), [DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md), [DEC-0028](DEC-0028-upstream-owned-reusable-corrections.md), [DEC-0030](DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md), and [DEC-0032](DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
- Supersedes: [DEC-0032](DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) only where separate CLI/application artifacts or the PowerShell-migration feature sequence define the product architecture; preserves its C#, typed-foundation, portable-JIT, least-authority, plan/apply, single-engine-mutation, and explicit-authority-state decisions
- Reserved draft decisions: the [specification-first C# governance draft](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/decisions/DEC-0033-specification-first-csharp-governance.md) and [bounded reusable governance catalog draft](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/decisions/DEC-0034-bounded-reusable-governance-catalog.md) exist only on preserved exact draft commit [`1873c98638ba4960734aadb188eb8c8d70b4bc52`](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52); their identifier positions are not reused and their compatible rationale is incorporated here without claiming default-branch authority

## Context

The first C# migration architecture organized governance, adoption, and update
as separate operational CLI applications. That direction produced useful typed
foundations and a bounded governance implementation, but it placed process
entry points above the actual product boundary.

The protocol itself is the reusable product. Its consumers need the same
executable rules for files, documents, links, issues, pull requests, comments,
reviews, workflows, releases, and related evidence. A consumer must execute
those rules against its own state without copying their code, fixtures, tests,
or workflows. Adoption and update are likewise application lifecycles, not
command syntaxes.

The preserved [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
branch proves that specification-first C#, parse-once
analysis, typed identities, deterministic reports, exact Git evidence, and
portable packaging are viable. It also proves that a two-profile, repository-
only CLI package is too narrow to define the full governance architecture.

## Decision

Adopt the complete [Protocol Governance and Execution Architecture](../architecture/protocol-governance-and-execution/README.md).

### 1. Product authority

meAndAI publishes one immutable protocol release envelope containing normative
specifications, a machine-readable rule catalog, compiled C# evaluators,
schemas, shared runtime libraries, adoption/update transition contracts,
managed projections, and thin hosts.

CLI, workflow, action, agent, and future service entry points are adapters.
They cannot own rule semantics, applicability, transition behavior, evidence
completeness, report meaning, or release authority.

### 2. Implementation language

All new executable protocol domain, conformance, acquisition, planning,
mutation, recovery, reporting, package/reference, and provider orchestration
behavior is implemented in C#.

Markdown, JSON, YAML, workflow files, and minimal bootstrap scripts may declare
or compose exact behavior but cannot implement business rules or transitions.
The sole pre-C# `Trust Bootstrap` exception uses a provider/native trust
primitive to verify an exact issuer/repository/workflow/source/subject-bound
attestation, asset SHA-256, and declared .NET runtime before starting the host.
It owns no repository semantics; C# independently re-verifies the complete
chain immediately after launch. It never installs a runtime or executes a setup
action; exact runtime provisioning is an external platform precondition.
Portable framework-dependent JIT remains the default distribution strategy.

### 3. Common conformance ownership

Separate normative requirements, executable rules, upstream qualification
scenarios/fixtures, and consumer domain tests. The first three are versioned by
meAndAI. Consumers execute the released common rules unchanged against their
own evidence and do not own duplicate validator tests.

Introduce stable `RULE-NNNN` identities after this decision is accepted.
`RULE-NNNN` is distinct from its exact specification links, `TEST-NNNN`
qualification scenarios, finding codes, and execution profiles. Existing test
identities are mapped and remain immutable.

Every release contains a full immutable catalog snapshot. Rule revisions bind
a canonical per-rule normative-fragment digest, semantic contract, and
qualification-observable expected outcomes. A behavior-changing defect fix is
therefore `Revised` even when normative prose is unchanged; a proven behavior-
preserving refactor changes only evaluator-artifact identity. The containing
Git blob/anchor remains provenance and an unrelated document edit does not
revise the rule. Catalog transitions are unchanged, added, revised, or retired.
Every non-unchanged transition links a reviewed rule-change authority: either a
normative change or a defect record with exact qualification/differential
evidence for changed expected outcomes.
Catalog metadata and evaluator code cannot replace or silently override
normative protocol text.

### 4. Layering and I/O

Use inward dependencies from thin hosts and infrastructure adapters through
application use cases to conformance/transition components and typed domain
contracts. Rules consume sealed evidence and perform no I/O. Git, filesystem,
GitHub, release, cache, clock, process, and reporting behavior remains in
outward adapters.

Acquire and parse each same-contract evidence source once per sealed context.
Distinct rule invariants may share indexes and parsers without becoming one
universal rule.

### 5. Evidence and verdicts

Represent repository, Git, document, provider, workflow, release, and captured
evidence through typed kinds and locations. Provider acquisition records exact
object/version identities, cursor/page coverage, digests, and bounded
convergence.

Keep acquisition, rule evaluation, conformance verdict, and enforcement
decision separate. Missing or failed required evidence is indeterminate and
cannot become conforming. Historical debt and waivers never rewrite a rule
violation as satisfaction.

Aggregation has fixed precedence: unresolved required acquisition/evaluation
makes the verdict `Indeterminate` while preserving a separate known-violation
flag; otherwise any violation is `NonConforming`, otherwise the result is
`Conforming`. Audit/detective routes are `ReportOnly`. On authoritative routes
`Indeterminate` always blocks; full blocking blocks every unwaived violation;
prospective blocking blocks only new, worsened, or resurrected unwaived
findings against the protected exact debt baseline. A valid waiver or unchanged
debt may affect enforcement but never rewrites conformance.

Live-provider evidence also declares whether it is an exact snapshot,
object-version-bound evidence, or a bounded non-atomic observation. A rule that
requires unavailable cross-object atomicity remains unevaluated.

### 6. Profiles and enforcement

Define profiles through independent subject-role, operation, snapshot, surface,
and enforcement axes. Catalog applicability selects rules only from semantic
subject facts. Adapter/evidence capability and authority are separate
acquisition/I/O contracts; their absence makes an applicable rule not evaluated
and the verdict indeterminate, never not-applicable. A caller cannot lower the
immutable baseline, narrow an authoritative profile, reduce evidence
completeness, or disable a rule.

Use pre-mutation validation for protocol-owned writers and merge gates only for
supported same-repository, exact-commit-bound PR evidence. Mutable PR/provider
surfaces and manually written issues/comments receive detective event/full-
inventory results in the initial GitHub adapter because their evidence can
change without a candidate SHA change.

### 7. Governance, adoption, and update

Governance evaluation is strictly read-only and returns a sealed report through
stdout/local artifact output. Exact check/status publication is a separate
least-authority application and host with its own digest/head/name-bound grant;
it cannot reevaluate rules or edit governed content. The report contains only
evaluation/acquisition authority provenance. A separately digested publication
envelope binds the already sealed report and later publication grant, avoiding
a report/grant digest cycle.

Adoption and update are explicit state machines with read-only discovery,
assessment, strategy, and planning stages; separately granted apply,
proposal publication, exact-target closure, finalization, and recovery stages;
exact plan digests; pre-write TOCTOU revalidation; and a single mutating engine.
Direct execution finalizes only after an exact durable target is sealed and
re-acquired; provider execution finalizes only after the exact proposal merge is
observed and re-acquired. Proposal publication alone is never closure. For
direct execution, sealing the commit/ref requires its own grant; both routes
require a final closure-report/journal-bound grant before terminal cleanup and
`Finalized`. For semantic adoption, a
first review authorizes only a path/action/invariant envelope. Candidate output
is produced in isolated proposal storage, C# reacquires it and seals exact
output hashes, and a second review plus grant binds that final plan before
target mutation. Failure cannot trigger an automatic PowerShell/C# fallback.

Updates preserve the [DEC-0018](DEC-0018-release-declared-consumer-migrations.md)
boundary: `MIG-NNNN` is declarative and
deterministic. The exact target runtime is staged side-by-side under a sealed
handoff while the current durable pin remains unchanged; the target pin is an
effect of the reviewed final plan. [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md)
semantic/manual capabilities use a
separate capability catalog and ledger. When both are needed, deterministic
update reaches exact-target closure first and then starts a separately linked
adoption/capability operation; a MIG never invokes a semantic actor.

An immutable predecessor that cannot perform side-by-side handoff retains the
[DEC-0018](DEC-0018-release-declared-consumer-migrations.md) two-proposal truth
as an explicit `LegacyHandoffPending` authority
state. Exact predecessor/merge/target evidence and a protected immutable marker
permit only one same-target deterministic ledger reconciliation under the new
runtime, normal grant, and journal. It is never treated as ordinary installed or
finalized state; any mismatch fails closed.

Semantic reconciliation by a maintainer/AI actor is allowed only inside that
reviewed C#-owned mutation envelope and cannot write or authorize the target.
Accepted grant issuers and stable reviewer/executor identities come from a
protected immutable `ApprovalAuthoritySetSnapshot` rooted in the current trust
anchor/base authority, never the target release or candidate. It binds revision,
revocation epoch, digest, separation-of-duty predicates, explicit solo-
maintainer exceptions, and journal stores. Mutation grants bind the final plan;
publication grants bind the sealed report plus target/name/gate snapshot and are
then bound by a separate publication envelope; release grants bind the sealed
release plan. `authority.transfer` is a distinct non-transitive capability and
grant bound to the verified publication report, exact old/new trust anchors,
and predecessor-trusted executor; `release.publish` never implies it. All grants bind the exact authority snapshot, issuer, approval evidence,
actor, idempotency key, lease generation/fence, and expiry; authority drift
invalidates them before an effect.

Every publication, mutation, or finalization writes a hash-chained intent to a
durable `IOperationJournal` outside candidate control before the external
effect, then records an exact object/version/digest receipt afterward. Its
authenticated CAS append is the non-recursive trusted control-plane primitive;
intent failure forbids the effect, receipt failure enters recovery, and missing/
corrupt history forbids automatic replay. Fenced leases and CAS protect one
writer. Recovery queries live state and classifies effects before action. An
expired grant/lease is replaced only by a current `RecoveryGrant` bound to the
same operation, plan/envelope, journal head, predecessor grant, authority-set
digest, and a newer fencing generation; divergence requires a new normal plan.

### 8. Consumer reference and managed projection

A consumer retains its immutable protocol gitlink/equivalent reference,
consumer-owned configuration and domain evidence, and only the exact resident
managed hook required by the execution platform. That hook resolves and
verifies the pinned distribution and invokes it; it contains no common rule,
parser, fixture, transition, or verdict logic.

The baseline distribution is one release bundle with five thin least-authority
C# process hosts: read-only governance evaluator, exact report publisher,
adoption, update, and protocol release finalizer. The last host alone composes
exact release/tag/asset/attestation publication, verification, and explicit
authority transfer for the protocol-authority role. Their physical separation
limits privileges but does not create five products.

Gitlink and immutable repository-reference inputs resolve to the same typed
commit/version/release identity. First adoption begins only from an exact
`AdoptionBootstrapReference`; it can neither mean a moving version nor confer
mutation authority.

The initial resident GitHub adapter supports authoritative PR result
publication only for commit-bound gate rules, when a base-owned trusted
workflow treats same-repository candidate objects strictly as data and the
publisher creates/updates the release-declared Check Run on the exact candidate
or base-owned merge SHA. The publisher revalidates the report's candidate and
provider version vector before publication; mutable provider rules remain
report-only because they can race afterward without a new SHA. It never uses
the base-SHA workflow conclusion as the candidate gate. It returns
`UnsupportedForkExecution` for fork PRs because
`pull_request_target` runs in base context and cannot by itself prove or attach
a required result to the exact fork candidate. A future separately designed
GitHub App/service may add that capability only with an independently proven
exact-candidate/merge and privilege boundary.

### 9. Trust and self-consumption

Bind source commit, protocol version, rule/provider-surface/capability/migration
catalogs, evaluator pack, runtime, all hosts, projections, and the canonical
schemas/digests for bootstrap/reference, authority-set, grant, report,
publication-envelope, plan, journal, recovery, waiver, and debt contracts in
addition to handoff context, legacy-handoff marker, published-artifact
verification, authority-transfer plan/record, migration/capability ledger, and
active/proposed extension-transition/activation-record contracts in one immutable release
envelope. Per-consumer instances remain outside the
release but their digests bind to the owning report/plan/grant/journal. The
envelope also binds an attestation predicate naming the accepted issuer,
repository, workflow/builder, source ref/commit, predicate schema, subject name,
and subject digest. No moving reference or implicit compatibility fallback is
valid.

meAndAI is a self-consumer of the same baseline rules. The last trusted
immutable runtime validates the candidate baseline; the candidate performs
same-evidence differential evaluation and independent fixture qualification;
the trusted release process attests exact artifacts; the Release Finalizer
publishes and re-verifies an exact reviewed release plan under separate grants
and journal; and a separate explicit record transfers authority. The privileged
executor is the predecessor-trusted finalizer or an immutable external broker
already named by the current trust anchor for the exact plan schema/transition.
Candidate finalizer code may shadow-verify but receives no release credential or
grant-execution authority before transfer. The first legacy-to-C# transition
uses only previously accepted manual/provider-native authority under an explicit
decision. A candidate cannot authorize itself or define its own executor
compatibility.

### 10. Extensions, waivers, and debt

Privileged runtime extensions are declarative parameters over protocol-owned
evaluator kinds. Arbitrary consumer code runs only in a separate unprivileged
domain-test lane. Extensions cannot shadow or weaken baseline rules. Evaluation
uses an authority-store `ExtensionActivationRecord`, not whichever policy file
is in candidate/base content. Candidate policy changes are separately reported
proposed transitions. Merge/seal cannot activate them: after exact-target
closure, a distinct non-transitive `extension.activate` grant CAS-advances the
protected record under the shared journal. Until then the old snapshot remains
active and the new file is pending, never part of the gate judging itself.

Waivers are typed, exact, decision-linked, scoped, expiring, and unavailable
for acquisition, integrity, execution, or trust-anchor failures. A scan may
only propose historical debt. The authoritative baseline comes from protected
base authority, never the candidate; it changes only through a separately
reviewed/granted/journaled adoption or update plan. Debt remains bound to exact
unchanged evidence and progresses from audit to prospective/full blocking only
through a release-declared reviewed transition.

## Consequences

- The common protocol becomes executable once and reusable by reference.
- meAndAI and consumers cannot silently diverge in shared governance semantics.
- Provider acquisition, rule evaluation, and delivery orchestration become
  independently testable rather than one large workflow/CLI behavior.
- CLI hosts remain useful for local and CI invocation but lose architectural
  ownership.
- Five least-authority hosts remain possible without five release products.
- Consumer integration stays small and exact; shared logic remains upstream.
- Adoption/update retain explicit review and mutation controls.
- The previous trusted release creates a deliberate bootstrap cost for runtime
  changes, accepted to prevent circular self-certification.
- Existing PowerShell remains compatibility authority until separately proven
  and migrated; this decision does not authorize retirement.
- Existing [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
  work is classified and selectively carried forward, not
  discarded or merged wholesale.

## Alternatives considered

- **Continue with three CLI products:** rejected because process entry points
  would keep defining shared rule and lifecycle boundaries.
- **Copy tests/validators into consumers:** rejected because common behavior
  would fork and consumers would retest an upstream implementation rather than
  execute one protocol.
- **Use a fully data-driven rule language:** rejected because it creates a new
  interpreter and an unsafe extension surface; inspectable metadata plus
  compiled C# evaluators is sufficient.
- **Load arbitrary consumer plugins:** rejected in privileged execution because
  untrusted repository code would cross the provider trust boundary.
- **Let the candidate runtime validate itself:** rejected as circular authority.
- **Edit or disable durable workflow definitions during design:** not selected;
  `[skip ci]` architecture commits and a frozen draft stop recurring runner cost
  while leaving the later enforcement contract available for redesign.

## Implementation boundary

This accepted decision contains no implementation authority. Every successor
still requires the separate implementation-entry gate in the full
architecture. No code, test, workflow, consumer, release, authority, or
retirement change may begin without a later explicit maintainer directive.

## Review condition

Review before changing the implementation language, permitting executable
consumer plugins, combining read-only and mutation-capable composition roots,
changing the immutable trust anchor, allowing partial provider evidence to
authorize conformance, or replacing the pinned protocol reference model.
