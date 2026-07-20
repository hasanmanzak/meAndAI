# Common Development Protocol

Protocol version: **0.12.5**<br>
Status: **Active**

## 1. Purpose and authority

This protocol defines the minimum delivery discipline shared by repositories
that reference `meAndAI`. Its goal is to prevent fast but weak implementation:
unexamined code generation, semantic parameter mistakes, avoidable rework,
logic duplication, hidden architectural drift, and completion claims without
evidence.

The consuming repository remains authoritative for its domain and may add
stricter rules. A deviation from this protocol requires a numbered decision
record with rationale, impact, and an expiry or review condition where relevant.

Normative terms have their usual meanings: **MUST** is mandatory, **SHOULD** is
the default unless a decision documents an exception, and **MAY** is optional.

Repository artifacts governed by this protocol MUST be written in English.
Conversation language MAY follow the user. Evidence placed in issues, pull
requests, logs, test records, or memory MUST be minimized and redacted of
credentials, secrets, tokens, and unnecessary personal data.

## 2. Engineering defaults

- Domain-Driven Design, a Rich Entity Model, and Test-Driven Development are
  the defaults for domain-oriented software.
- Behavior and invariants SHOULD live with the domain objects that own them;
  anemic entities and service-heavy domain logic require justification.
- SOLID principles guide boundaries and dependencies. They are not a reason to
  introduce abstractions without a concrete responsibility or variation point.
- Duplication of business rules is prohibited. Superficial syntactic similarity
  is refactored only when the concepts and change reasons are truly shared.
- The simplest design that preserves domain meaning, testability, and future
  change safety is preferred.
- A different paradigm MAY be selected when the project's domain, runtime, or
  risk profile demands it; record that choice as a decision.

## 3. Traceable identifiers

Every material work item, conclusion, or durable incubating idea MUST have a
stable identifier. GitHub's issue number is a link, not a replacement for the
domain identifier.

| Identifier | Classification | Purpose |
| --- | --- | --- |
| `EPIC-NNNN` | Epic | Outcome spanning multiple features |
| `FEAT-NNNN` | Feature | Independently valuable capability |
| `SUBF-NNNN` | Subfeature | Independently reviewable feature slice |
| `TASK-NNNN` | Task | Bounded implementation or maintenance work |
| `BUG-NNNN` | Bug | Confirmed incorrect behavior |
| `FIND-NNNN` | Finding | Audit or review observation requiring triage |
| `IDEA-NNNN` | Idea | Durable possibility not yet authorized as work |
| `DEC-NNNN` | Decision | Architectural or process decision |
| `TEST-NNNN` | Test scenario | Verifiable behavior or quality condition |
| `MIG-NNNN` | Migration | Immutable declarative consumer-state transition |
| `RISK-NNNN` | Risk | Explicit uncertainty with impact and response |

Numbers are repository-local, four digits, monotonically allocated per class,
and never reused. Titles begin with the identifier. Records state status,
classification, relevant links, and the evidence supporting closure or outcome
where applicable.

A `TEST-NNNN` identifier belongs to exactly one canonical scenario record and
MUST NOT be reused for a different behavior. A superseded scenario remains as
historical evidence with status `Superseded` and links its active replacement.
Executable evidence MUST identify one owning suite and evidence kind whose
successful run covers the documented behavior. Declared variants require
focused fixture coverage recorded by that scenario; finding the identifier as
an unstructured source substring is not scenario-coverage evidence.

A `RISK-NNNN` record lives in the owning feature or decision. Create a linked
GitHub finding when a risk is independent, unresolved, or needs separate
ownership. Test records identify their feature or subfeature and current state.

### Idea incubation

Use `IDEA-NNNN` only for a possibility that is valuable enough to preserve
across machines and collaborators but has not been selected, scoped, or
authorized for delivery. An idea is not a work item, decision, backlog
commitment, or implementation instruction. It does not authorize implementation
and does not satisfy Definition of Ready.

An idea record lives under `docs/ideas`, uses exactly one of `Exploring`,
`Parked`, `Promoted`, or `Rejected`, and states its observation, possibility,
potential value, concerns, promotion condition, and outcome. It does not require
an issue, owner, test, target version, delivery date, or acceptance criteria.
Do not record low-value passing thoughts merely because the classification
exists.

Promotion creates and links the appropriate `EPIC-NNNN`, `FEAT-NNNN`,
`TASK-NNNN`, or `DEC-NNNN` record. That new record independently satisfies the
normal planning and delivery gates; the idea contributes history, not readiness
evidence. Promoted and rejected records remain indexed with their rationale and
bidirectional links instead of being deleted or silently rewritten. Use the
pinned `templates/idea.md` when creating a record.

## 4. Delivery lifecycle and review gates

### Gate 0 - Context and baseline

Before planning, inspect the repository instructions, project memory, related
features, decisions, issues, pull requests, tests, and relevant call sites. Do
not infer contracts from a single file when the repository can answer the
question. Confirm the Git boundary and preserve unrelated user changes.

### Gate 1 - Definition of Ready

Implementation MUST NOT start until the work item has:

- a stable ID and linked issue;
- problem statement, intended outcome, scope, and explicit non-goals;
- measurable acceptance criteria;
- affected domain concepts, entry points, dependencies, and known consumers;
- contracts covering type, domain meaning, units, range, nullability, ownership,
  lifecycle, errors, and compatibility where relevant;
- identified risks and decisions;
- a decomposition into reviewable slices when the work is not small;
- numbered test scenarios, including failure and boundary behavior; and
- an implementation and verification approach appropriate to the repository.

An automated dependency updater MAY create a deterministic, pointer-only draft
proposal before Gate 1 solely as a discovery artifact. The AI-capabilities
lifecycle MAY likewise create a deterministic adoption discovery draft that
contains only absent canonical adoption assets or a transient handoff manifest.
Either proposal MUST remain draft and MUST NOT be treated as implementation
authorization, marked ready, or merged until a stable work ID, linked issue,
impact review, test plan, and the remaining Definition of Ready are complete.
This narrow exception does not authorize product logic, domain behavior,
schema, generated-code, semantic collision resolution, or unrelated file
changes.

### Gate 2 - Design and contract review

Before code is written, trace data from its source through every changed
boundary to its consumers. Review each parameter and return value for both
language type and semantic type. Names such as `amount`, `rate`, `timestamp`,
or `id` are insufficient without domain, unit, precision, timezone, identity,
and validation semantics where applicable.

Review ownership and invariants, dependency direction, transaction and state
boundaries, concurrency, error behavior, compatibility, and existing extension
points. Search for related logic before introducing a new implementation.

### Gate 3 - Tests first

Create or update executable tests before production behavior whenever the stack
supports it. Demonstrate that the test fails for the intended reason, then make
the smallest coherent implementation that passes. If literal test-first work is
not feasible, document why and create the executable test in the same slice
before that slice can pass its review gate.

Mocks MUST express real contracts rather than make an implementation convenient.
Tests cover success, failure, boundaries, invariants, and regression risk at the
lowest useful level, with integration or end-to-end coverage where boundaries
make unit evidence insufficient.

A scenario description and its status MUST match the behavior actually
exercised. A pre-seeded state followed by a sequential rerun is recovery or
state-transition evidence, not concurrent-execution evidence. Variants named by
a scenario require distinct fixtures or an explicit parameterized case for each
variant.

### Gate 4 - Small-slice implementation

Large work is delivered as `EPIC -> FEAT -> SUBF -> TASK`. Each slice MUST be
coherent, independently testable, reviewable, and documented. The owning feature
maintains a compact ledger mapping every declared subfeature to its issue,
numbered tests, latest test run, self-review, findings, and status; separate
subfeature documents are optional. Do not implement future slices speculatively.
Avoid unrelated refactors unless they are required for correctness or separately
tracked.

### Gate 5 - Self-review

Every feature and subfeature receives a fresh-diff self-review after its tests
pass. The author MUST inspect the actual diff and relevant surrounding code for:

- type and semantic-contract correctness at every changed boundary;
- domain invariants and invalid-state prevention;
- logic duplication and missed reuse of existing behavior;
- SOLID, dependency direction, cohesion, and accidental coupling;
- error paths, state transitions, concurrency, resource ownership, and cleanup;
- compatibility, migrations, configuration, observability, and security when
  applicable;
- test quality, missing negative or boundary scenarios, and false-positive
  tests; and
- documentation, link, issue, decision, version, and memory consistency.

A defect found in newly written code is fixed in the current slice or becomes a
blocking issue. It MUST NOT be deferred merely so a later scan can say the new
code should have been written differently. Legacy findings may be scheduled
separately only when they do not invalidate the new work and are linked.

Every review or scan observation receives exactly one disposition:

- `Blocking`: actionable, in the current scope, and capable of invalidating an
  acceptance criterion, correctness, safety, compatibility, or required
  evidence. It reopens implementation and prevents completion.
- `AcceptedResidual`: not unresolved actionable work. It requires the explicit
  accepting authority, owner, rationale, evidence link, and review condition.
- `ExternalOrLegacyFollowUp`: actionable but outside the authorized current
  scope. It requires a durable owner and link and MUST NOT conceal a defect
  introduced or exposed by the current change.
- `OptionalImprovement`: non-required improvement whose absence does not
  invalidate the current work. It MAY be linked for later consideration.

These dispositions are mutually exclusive. `Actionable in-scope finding` means
`Blocking` throughout this protocol. Relabeling or wording alone cannot change
a disposition; reclassification requires new evidence, changed scope, or the
recorded accepting authority.


#### Bounded self-validation

Unless a known risk or project decision requires more, the default validation
budget is:

1. one fresh-diff self-review pass after the declared tests;
2. one final relevant verification command after fixes; and
3. one triage that assigns each observation one disposition defined above.

Only a `Blocking` finding reopens implementation scope. The other dispositions
MUST NOT trigger another review loop in the current delivery.

Stop validation when acceptance criteria and declared tests pass, no `Blocking`
finding remains, and the evidence and unreviewed scope are recorded. Repeating
an unchanged review without new diff, failed evidence, or an explicit user
request is prohibited.

Do not create validator-for-validator chains, recursive bootstrap layers, or
universal semantic or AI-memory validators unless a concrete project risk and
numbered decision require them. Prefer existing compiler, test, linter, link,
and CI evidence. The post-development convergence scan in
[Full-project scans](#5-full-project-scans) is the single default completion
scan. Do not add another full-project scan to an ordinary feature or patch
unless the remaining triggers in that section require it.
### Gate 6 - Definition of Done

Work is done only when:

- all acceptance criteria are met;
- mandatory test code exists and all declared scenarios map to executable tests
  or an explicitly justified manual check;
- test commands, environment, and results are recorded;
- the self-review and required project scan have no unresolved `Blocking` finding;
- no known duplication, semantic misuse, invariant leak, or unjustified SOLID
  violation was introduced;
- feature and decision documents, cross-links, changelog/version when relevant,
  and project memory are current;
- the issue and pull request link each other and the canonical documents;
- required CI and review gates pass; and
- residual risks are owned, classified, and linked rather than hidden.

### Gate 7 - Pull request and merge

Push work to a dedicated branch and open a pull request. The pull request states
what changed, why, user/developer impact, test evidence, self-review evidence,
risks, linked work IDs, and version impact. Merge only after all pre-merge gates
pass. Successful merged branches MAY be deleted locally and remotely.

Feature Definition of Done is a pre-merge delivery gate. Publishing a version
is a separate post-merge release gate. For GitHub releases governed by this
protocol at `v0.8.0` or later, repository release immutability MUST be enabled
before publication; create the published GitHub Release and its tag for the
exact merged commit, then verify the release API reports the exact tag,
non-draft/non-prerelease state, `immutable: true`, and the expected commit.
Creating a movable tag before that release is not publication evidence.
Historical tags remain valid records of what was published at the time but are
not retroactively described as externally locked. A release identifier MUST
NOT be required by the feature's pre-merge Definition of Done.
Exact release-target evidence MUST be written to an external post-publication
record, such as the GitHub Release or linked issue/PR comment. A repository
document MAY link that record after publication but MUST NOT predict or attempt
to embed the hash of the commit that contains the document itself.
A pre-merge feature record MAY designate a stable external issue as its
post-publication evidence authority while all publication-dependent fields
remain `Pending`. After publication, the exact tag, commit, release state, and
check results are written to that authority and the GitHub Release. A second
documentation-only pull request is not required merely to copy those external
facts into the repository.

## 5. Full-project scans

When a project scan is requested, at project onboarding, before a major release,
or when architectural confidence is insufficient, scan the entire tracked
project at the highest practical detail. Sampling alone is not a project scan.
State any inaccessible, generated, binary, external, or otherwise unreviewed
scope explicitly.

### Stability and consistency mandate

This mandate applies recursively to this repository and prospectively to every
consumer that adopts the protocol version containing it. It is an
event-triggered delivery discipline, not a background agent, scheduler,
scanner service, or continuous autonomous loop.

#### Post-development convergence scan

After development is declared complete, enter this mandate when repository
content materially changed and perform the existing post-development
full-project scan under this section. Material development includes feature,
bug, refactor, review, test, documentation, governance, and consistency
changes. The scan covers every applicable concern listed below and records its
scope and exclusions. A repository in `Waiting` with no new material
development or new failed evidence does not start another cycle; an unchanged
tree is not a scan trigger.

Document every observation and assign exactly one Gate 5 disposition. The
local convergence condition is zero unresolved `Blocking`, not zero
observations. `AcceptedResidual`, `ExternalOrLegacyFollowUp`, and
`OptionalImprovement` records remain visible under their existing evidence
contracts but do not enter the active remediation queue.

Build that queue from explicit dependencies first. Dependencies determine the
ready set. Within the ready set, order `Blocking` findings from highest to lowest priority
using priority, severity, impact rank, and then stable identifier order.
Priority uses `p0`, `p1`, `p2`, or `p3`, where `p0` is highest; severity and
impact rank use `critical`, `high`, `medium`, `low`, or `info`. A
dependency cycle, missing required authority, or unavailable required
input stops the cycle as `Blocked`; it does not authorize an arbitrary order or
a success claim.

Resolve one `Blocking` finding at a time, except for the smallest explicitly
recorded dependency-coherent group that cannot be changed safely in isolation.
For each correction, provide the solution, focused evidence, and a fresh-diff
self-review before starting the next independent queue item. A `Blocking`
defect caused or exposed by the correction stays in the active queue: fix it in
the current correction when coherent, or record its dependencies and priority
before continuing. Debt introduced by the current change cannot be deferred as
legacy or optional work.

If the initial scan finds zero unresolved `Blocking`, that initial scan is the
convergence evidence; do not spend a confirmation pass on an unchanged tree. A
confirmation scan is required only after remediation changed the tree. When
the remediation queue becomes empty, run that one budgeted confirmation scan.
If it finds a new `Blocking` observation, add that observation to the queue and
continue only while the declared finite budget remains. The local convergence
condition is no unresolved `Blocking` finding. Local convergence is not full
normative cycle completion. A finding is not cleared or reclassified merely by
relabeling it.

When the declared tests pass and the applicable convergence scan proves local
convergence, perform the **converged final push** of the review branch. The
cycle completes and enters `Waiting` only after the authorized converged final
review-branch push exists. If exact push authority is unavailable, preserve
push-eligible evidence and stop as `Blocked` on missing final-push authority
without claiming completion or `Waiting`. This is an ordinary Git push and
does not create a tag or GitHub Release.
Hosted CI or review evidence discovered after that push reopens the same cycle;
after correction and renewed convergence, publish a corrected converged final
push. Correctable new failed evidence reopens the active cycle and receives the
same disposition, queue, correction, and review treatment. Failed evidence
produces `Blocked` only when its required correction cannot be completed within
the remaining authority and finite budget. Do not push a locally known
non-converged tree merely to mark progress.
Exact converged-push commit and ref evidence MUST be written to the issue or
pull request after the push exists. A repository document records local push
eligibility and MUST NOT predict the commit that contains itself.
The pull-request number, exact pushed SHA, hosted-check result, merge SHA,
release identity, and cleanup result are live external facts. Once the
candidate tree has converged, a maintainer MUST NOT create a repository commit
whose sole purpose is to copy external evidence into that candidate. Record
those facts in the linked issue or pull request as the stable external
authority. A failed hosted check that requires a product, test, or canonical
documentation correction still reopens the ordinary correction cycle.
Protocol-version tags and GitHub Releases are separate post-merge distribution
events governed by Gate 7 and Section 8.

Maintainers who deliberately invoke an AI agent MAY copy or reference the
[optional stability and consistency cycle prompt](docs/agent-prompts/stability-and-consistency-cycle.md).
That non-normative aid does not create or activate a goal, recurring task,
automation, schedule, background loop, or next invocation, and it cannot
override this protocol or repository-local instructions.

The cycle MUST remain bounded. Before the first pass, declare the scan scope,
exclusions, and a finite validation budget; the default is one initial scan and
one confirmation scan after remediation. Every additional pass requires changed
diff, failed evidence, or a new actionable finding within that budget. An
unchanged scan MUST NOT be repeated. If the budget is exhausted, progress
requires new authority or input, or the same blocker cannot be changed by
another pass, stop as blocked, preserve the evidence, and request direction.
Budget exhaustion is never a successful completion state.

The scan MUST cover:

1. repository inventory, build graph, entry points, generated boundaries, and
   runtime/deployment configuration;
2. architecture, domain boundaries, dependency direction, cohesion, coupling,
   SOLID, and consistency with recorded decisions;
3. correctness, call flows, semantic contracts, state transitions, error paths,
   concurrency, persistence, migrations, and external integrations;
4. duplication, dead code, obsolete paths, refactor opportunities, and naming;
5. tests, coverage of meaningful risks, flaky or misleading tests, and missing
   regression protection;
6. documentation, feature/decision drift, cross-links, versioning, and memory;
7. security, privacy, dependency, performance, observability, and operational
   risks to the extent relevant to the project; and
8. uncommitted changes and repository hygiene without overwriting user work.

Each finding is recorded as `FIND-NNNN` with classification, disposition,
severity (`critical`, `high`, `medium`, `low`, or `info`), confidence,
dependencies (`FIND-NNNN` identifiers or explicit `None`), priority (`p0`,
`p1`, `p2`, or `p3`, where `p0` is highest), impact rank (`critical`, `high`,
`medium`, `low`, or `info`), evidence, affected scope, impact rationale,
recommended action, status, and links to related issues, pull requests,
features, decisions, tests, and documentation. Separate verified defects from
risks and optional improvements.

A compact finding register MAY declare shared scope, confidence, impact, and
canonical evidence links once when they apply unambiguously to every listed
row. Each row still records its identifier, classification, disposition,
dependency, priority, severity, impact rank, specific evidence, action, and
status. Do not split one coherent observation into multiple records merely to
increase detail.

## 6. Documentation graph

- Every durable pre-work idea is indexed under `docs/ideas` and links any
  promoted work or decision.
- Every feature has `docs/features/FEAT-NNNN-slug/README.md` and
  `test-cases.md`.
- Every material architectural or process decision has
  `docs/decisions/DEC-NNNN-slug.md`.
- Feature records link their issue, decisions, dependencies, tests, and related
  documentation. They link the delivery pull request directly when its identity
  exists before the converged candidate push; otherwise they link the delivery
  issue as the stable indirection and that issue links the pull request after
  creation. The link graph MUST NOT require an evidence-only candidate commit.
- Decisions link affected features and superseded or related decisions.
- Before closure, an issue links its owning canonical feature and every
  applicable decision; the feature links back to the issue. A delivery issue
  also links the pull request and the stable external authority for any
  post-publication evidence. Pull requests link the same canonical records and
  related issues, pull requests, wiki pages, or external documentation.
- Links MUST be relative for repository files and absolute for GitHub or
  external resources. They MUST be clickable and validated before completion;
  record automated local-link results and manual or automated external-link
  evidence separately.
- An automated external-evidence query MUST exhaust the provider's pagination
  contract or fail at a declared finite page limit. A focused fixture MUST place
  qualifying evidence after the first page when closure depends on comments or
  another paginated collection.
- Documentation and implementation change in the same pull request.

## 7. GitHub tracking

GitHub Issues is the default tracking system. Use Agile hierarchy and labels:
type, priority, workflow status, and area when useful. Create missing labels
before assigning them, and apply status labels only when the stated transition
is reached. Avoid a second tracking file unless issue relationships cannot
express a real need.

Issue forms are structured prompts, not the authoritative DoR or DoD gate. The
canonical feature record and pull-request review verify completeness. This is
especially important for private repositories, where GitHub's current form
schema does not enforce `required` validation.

Branches use a short category and work description, for example
`feature/FEAT-0042-customer-credit-limit` or an automation-specific equivalent.
Commits are focused and describe intent. Pull requests close or reference their
primary issue and list all related records. Completed changes MUST be pushed.
If an authorized publication target has no repository, create a private GitHub
repository by default unless the user specifies visibility. Add a CI workflow
only when it enforces a recurring gate more reliably than recorded local checks.

Recurring GitHub Actions workflows MUST minimize total hosted runner
consumption and MUST NOT create redundant job, matrix, setup, checkout, or
fan-in load merely to reduce wall-clock latency. Every trigger, operating
system, matrix axis, job, dependency installation, retry, and aggregate runner
MUST map to declared risk or required evidence. Platform-specific runners
SHOULD execute only evidence that materially depends on that platform; a
complete or ambiguous sensitive change fails safe to the declared full
coverage. Efficiency changes MUST NOT weaken required checks, supported
runtimes, safety gates, or evidence authority. Automatic cancellation is
permitted only when the newer run wholly supersedes the same pull request's
older evidence; main, merge-queue, manual, and publication runs remain
independent. Workflow reviews compare job count and hosted runner consumption;
wall-clock latency alone is not runner-efficiency evidence.

An unprotected default branch retains its push validation. A short reuse route
is permitted only when read-only local Git and paginated provider evidence
jointly prove that the exact pushed commit tree already passed every declared
stable validation job. For a pull-request merge, this includes exact push
before/after identity, parent order, base and head repository/branch/commit
identity, merge-tree equality with the validated head tree, one merged pull
request, one successful current-workflow run for that exact head, and every
stable job completed successfully. An exact successful merge-queue commit may
provide the same authority. Direct, squash, rebase, forced, mismatched,
duplicated, missing, failed, canceled, malformed, unavailable, or API-error
evidence MUST run the full fail-safe route. Reuse keeps the stable job
identities present and performs a focused structural verification of the
already-validated tree; it is not permission to reuse a merely similar diff.

## 8. Versioning

Versions use `M.m.rev` and Git tags use `vM.m.rev`. Each component is an ASCII
decimal integer with no leading zero unless the component is exactly `0`.

- `M`: incompatible protocol, public contract, data, or adoption change.
- `m`: backward-compatible feature or meaningful capability addition.
- `rev`: backward-compatible correction, clarification, or maintenance change.

A new mandatory control MAY be introduced in `m` only when it applies
prospectively to consumers that choose to adopt or upgrade to that release and
does not invalidate a consumer correctly pinned to an earlier release. A forced
migration of already conforming consumers is incompatible and increments `M`.

Every released version updates `VERSION`, relevant current-release metadata,
and `CHANGELOG.md`. Historical feature target versions remain unchanged.
Consumers SHOULD pin the tag of a verified immutable release or an explicitly
reviewed commit, never an unqualified moving branch. A consuming project
versions its own product independently.

For a Git submodule consumer, the sole current protocol-pin authority is the
`.ai/protocol` `160000` gitlink in the consumer revision together with the
`VERSION` file inside that exact checkout: the gitlink supplies the commit and
`VERSION` supplies its canonical `M.m.rev` identity. Root instructions,
project memory, decisions, feature records, indexes, tests, and other
consumer-owned records MUST resolve the current identity from those sources;
they MUST NOT duplicate a literal tag or commit as a separately maintained
current-pin fact. A repository-reference consumer applies the same rule to its
provider's configured immutable-ref authority.

An exact tag or commit MAY remain in a dated adoption or update record, issue,
pull request, or test-run entry as historical event evidence. Such evidence
MUST identify the event and date and MUST NOT claim to be the consumer's live
pin authority. A routine compatible update therefore requires no separate
consumer-owned memory, decision, documentation, or test reconciliation merely
to restate the new tag or commit.

When a compatible release requires deterministic changes to consumer-owned
derived state, that transition MUST be declared by the immutable target release
through an ordered, append-only migration catalog. Each definition has a stable
`MIG-NNNN` identity, immutable Git-blob identity, exact path authority, and
deterministic legacy and satisfied states. Applicability is derived from actual
repository state, not from a hardcoded source tag. Arbitrary scripts, AI-driven
rewrites, unrestricted search-and-replace, and permanent updater ownership of
consumer files are prohibited.

The consumer records satisfied definitions in
`.ai/meandai-update-state.json`. That ledger is automation evidence, not a
second protocol pin. Its ordered IDs and definition blobs MUST be an exact
prefix of the target catalog. A fresh adoption records the complete target
catalog as its satisfied baseline. Missing, duplicate, reordered, changed,
partial, mixed, customized, linked, escaping, or otherwise ambiguous state
MUST fail closed before remote mutation.

Local migration planning MUST read every required input and the optional
ledger as binary-safe bytes from their validated regular-blob entries in the
exact captured consumer base commit. A checkout-filtered worktree is a write
destination, not committed-state evidence, and MUST NOT supply those planning
bytes. The worktree file's Git clean-filtered blob identity MUST still equal
the captured base blob so newline smudging is accepted without hiding genuine
content drift. Worktree containment, leaf type, staged-result,
committed-result, and live remote-head checks remain separate mandatory
fail-closed gates.

An updater that already implements this migration contract MUST include the
protocol gitlink, target-different updater assets, exact catalog-derived
consumer changes, and resulting ledger in one reviewed managed proposal. An
immutable updater installed before the contract cannot execute target-defined
migrations while creating its first proposal. It MUST first create only the
ordinary core update it can prove; after that merge, the newly installed
workflow MUST automatically discover the unsatisfied target catalog and open
one same-target reconciliation proposal. After that capability handoff merges,
later compatible transitions use the ordinary one-proposal path. This split is
capability-based and MUST NOT be implemented as a source-version-specific
switch.

### Release-declared capabilities

An immutable release MAY declare reusable repository practices through the
ordered catalog at `capabilities/index.json`. Each entry has one stable
lowercase slug, one declared type, one immutable definition path, and the
exact Git-blob identity of that definition. The supported types are
`Deterministic`, `DeclarativeMigration`, `Semantic`, and `Manual`.
Deterministic state remains subject to exact automation, declarative migration
state delegates to the migration catalog above, semantic state requires
repository-aware maintainer review, and manual state requires reviewed evidence
that automation cannot establish. A compatible catalog is append-only: an
existing slug/definition-path/type/blob tuple cannot be removed, reordered,
or rewritten.

Consumers record terminal capability assessments separately in
`.ai/meandai-capabilities-state.json`. This ledger is reviewed adoption
evidence, not another current protocol pin and not updater ownership of the
assessed files. It MUST be an exact ordered prefix of the target capability
catalog. The assessment boundary returns exactly `Conforming`,
`NotApplicable`, `AdoptionRequired`, or `ReviewRequired`; only reviewed
`Conforming` and `NotApplicable` evidence may enter the terminal ledger.
Missing, stale, partial, reordered, duplicated, unreviewed, or ambiguous
evidence remains open or fails closed.

Capability discovery runs after reviewed first adoption, for an already-current
consumer, and after ordinary compatible update discovery. It MUST NOT broaden
the initial-adoption content envelope. An updater installed before this
framework first performs only the ordinary update it can prove; the newly
installed same-target workflow then evaluates the immutable capability
catalog. That handoff MUST NOT switch source versions or pretend old immutable
code already possessed the new capability.

An unresolved immutable capability batch owns at most one canonical issue,
branch, transient `.ai/adoption/meandai-capability-review.json` manifest, and
draft semantic pull request. Automation MAY create or resume that review-only
handoff but MUST NOT edit, approve, mark ready, or merge semantic consumer
paths. Completion requires the reviewed pull request, a complete terminal
default-branch ledger, exact repository/catalog/branch/head evidence, removal
of the transient manifest, default-branch merge containment, branch deletion
with an exact-head lease, and issue-last closure evidence. Exact pending and
completed reruns are no-ops; duplicate or drifted ownership fails closed.

The `test-architecture` semantic capability establishes the shared test
baseline for adopting repositories: canonical suites are physically grouped by
capability while feature records retain canonical `TEST-NNNN` traceability;
suite discovery is recursive, normalized, link-safe, case-safe, and ordinal;
the stable repository runner executes each suite in a separate process; common
infrastructure contains only generic discovery, execution, result, evidence,
and cleanup mechanics; mutable fixtures are capability-local and reset per
case, while any shared immutable fixture has one explicit owner and byte
identity. A repository-native equivalent is acceptable only with reviewed
evidence satisfying the same outcomes.

### Consumer update proposals

#### AI-capabilities lifecycle

A GitHub submodule consumer adopting `v0.5.0` or later MAY begin with only the
canonical workflow at `.github/workflows/meandai-protocol-update.yml`. That
workflow is the seed for one AI-capabilities lifecycle covering first adoption,
bootstrap, and later updates. It MUST verify that the embedded protocol tag has
an exact published immutable release before checking out or executing bootstrap
code, then verify that checked-out source identity before proposing consumer
changes.

Before the workflow executes any consumer-local updater copy with repository
write credentials, trusted code from that exact checked-out release MUST verify
the local managed updater asset set, file modes, and blobs. A missing or
differing asset MUST block before the local copy receives either credential.

Deterministic adoption discovery classifies declared target paths, not the
presence of unrelated application code. When every target is absent except an
exact seed workflow, automation MAY open a draft containing the protocol
gitlink, canonical project adapter, memory skeleton, repository templates,
local updater scripts, the satisfied migration-ledger baseline, and the
transient handoff manifest at
`.ai/adoption/meandai-capabilities.json`. When any target collides, the draft
MUST contain only that manifest and MUST preserve every existing target. The
workflow MUST NOT imply that an AI agent is running; an explicitly invoked
agent or maintainer owns labels, project records, memory tailoring, semantic
merges, project tests, link validation, and manifest removal.

The deterministic adoption branch and its single draft are retained on later
runs. Missing proposal ownership, seed drift, an existing manifest, an orphan
branch, or any other ambiguous state MUST block without reset, deletion, or
overwrite. After verified local completion removes the manifest and marks the
proposal ready, that exact completed proposal MUST remain retained until
maintainer merge or explicit reviewed disposition; a later lifecycle run MUST
NOT misclassify it as a pending draft or create a duplicate. The manifest MUST
be removed before the draft becomes ready or merges. After reviewed adoption,
the local updater owns compatible update discovery and supersession under the
controls below. The source-only bootstrap resolver and adapter are not copied
into the consumer.

A transient adoption manifest MUST be validated before it enters an agent
prompt. Validation includes the exact canonical property inventory, repository
and release identity, proposed-path and collision sets, and required-task set;
accepting only a subset of identity fields is insufficient. Its tag and commit
are transition evidence, not permission to copy a separately maintained live
pin fact into consumer-owned records.

#### Local quick-adoption launcher

A consumer adopting `v0.6.0` or later MAY use the protocol's source-only local
launcher to establish the seed workflow. A modular quick-adoption release MUST
publish exactly two release assets: one small source-only
`Invoke-MeAndAIQuickAdoption.ps1` launcher and one
`MeAndAI.QuickAdoption.Bundle.zip`. The maintainer downloads and invokes only
the launcher; that launcher downloads the bundle as one asset and MUST NOT
assemble its runtime through per-module network requests. The bundle is
generated release output and MUST NOT be committed.

The launcher MUST bind its code to one canonical immutable
`RuntimeReleaseTag`. That runtime identity is independent of `-ProtocolTag`,
which remains the requested compatible protocol target for the consumer. The
bundle builder MUST accept one exact clean source commit, read its ordered
inventory and every payload as exact regular Git blobs from that commit, and
produce byte-identical archive output for repeated builds of the same identity.
Before module import, the launcher MUST verify the exact published immutable
runtime release, tag-resolved commit, unique bundle asset, API and downloaded
length/digest, bounded path-safe archive inventory, canonical manifest identity,
entry point, and every payload length/digest. Verification and extraction occur
in an owned temporary directory outside the consumer; invalid evidence MUST
block before module import or consumer mutation, and module and temporary-root
cleanup MUST run on every exit. Moving refs, unverified caches, downloaded-text
execution, and fallback to an older or local monolith are prohibited.

For `v0.8.0` or later, the download command and launcher MUST verify the exact
published immutable release before retrieving or accepting executable source.
The verified module MUST fetch the workflow from the exact requested protocol
tag, verify the returned Git blob, reject a differing existing seed, and stage
and publish only
`.github/workflows/meandai-protocol-update.yml`. Existing connected consumers
MUST be clean, on their synchronized GitHub default branch, and preserve all
consumer-owned content. A new directory MAY be initialized and connected to a
new private repository by default, but unrelated local files MUST remain
unpublished.

The launcher MUST require GitHub CLI `2.82.1` or newer immediately after
command discovery and before authentication, repository initialization,
credential inspection, or any remote action. It MUST accept exactly one
canonical ASCII `M.m.rev` version line, compare decimal components numerically
without a fixed integer ceiling, and fail closed with actionable official
upgrade guidance when the output is missing, malformed, ambiguous, or older
than the minimum.

Before the launcher acquires the secret-reconciliation lock or creates a
repository secret, any existing seed-workflow path MUST be a regular file whose
bytes exactly match the canonical release seed. Missing seed state may proceed
to canonical creation; differing or non-file state MUST block before secret
inventory or mutation.

When the explicit local inputs `FG_PAT.txt` and `MEANDAI_RO_FG_PAT.txt` are
used, their values MUST be stored only as `MEANDAI_UPDATER_TOKEN` and
`MEANDAI_PROTOCOL_TOKEN`, respectively. The values MUST travel through
standard input rather than command arguments and MUST NOT be printed, tracked,
committed, deleted, or written to project memory. Tracked or historically
committed credential files require rotation and MUST block the launcher.
Each present input MUST be the exact canonical root name and one regular
non-link, non-reparse file, and the launcher MUST revalidate that identity at
read time. While plaintext credential inputs may be accessible, every
launcher-owned Git process MUST use an invocation-scoped disabled hooks path;
the launcher MUST prove that Git honors the override and MUST restore the prior
process configuration on every exit. Detection after a consumer or global hook
ran is not credential containment.

For an existing repository, reconciliation MUST first list repository-level
Actions secret names without requesting their values. Each mapped local
credential file is required only when its canonical repository secret is
absent. An existing canonical name MUST be preserved without reading or
rewriting its value; only a missing name MAY be created from its mapped local
input. GitHub does not expose stored secret values, so name presence MUST NOT be
reported as value, scope, expiry, or usability validation.

The live secret-name inventory and every missing-secret write MUST share one
repository-scoped, remotely visible exclusivity boundary. That boundary is
acquired before the inventory, is owned by an unambiguous session identity, and
is released only by that owner. A stale, contended, changed, or unverifiable
lock MUST block before secret inventory or mutation; recovery is explicit
maintainer work after proving no active session owns it.

When `MEANDAI_PROTOCOL_TOKEN` exists and `MEANDAI_RO_FG_PAT.txt` is absent, the
launcher MAY use the authenticated local `gh` identity to retrieve the exact
tagged workflow and exact protocol commit. Git-blob and commit verification
remain mandatory, and inability to read the private protocol repository MUST
block. This authenticated source transport MUST NOT substitute for provisioning
a missing repository secret. Tracking and history checks still apply to both
credential paths when an optional source file is absent. Both canonical secret
names MUST be present, whether preserved or created, before the seed is pushed.
New repositories MUST still provide both mapped local credential files before
remote creation.

When `MEANDAI_RO_FG_PAT.txt` is present, the thin launcher MAY use its
revalidated value as invocation-scoped `GH_TOKEN` solely to verify and download
the exact immutable runtime release before module import. The value MUST NOT
enter argv, output, the bundle, or the consumer tree. The prior `GH_TOKEN` and
GitHub host environment MUST be restored, and the in-memory value cleared,
before downloaded module code runs. When the file is absent, runtime retrieval
uses the already authenticated local `gh` identity and fails closed if that
identity cannot read the runtime repository. This read transport does not
replace the file's separate `MEANDAI_PROTOCOL_TOKEN` provisioning role when
that repository Actions secret is missing.

After publication, the launcher MAY dispatch the lifecycle workflow and wait
for the exact published commit under a finite timeout. If that run creates one
deterministic adoption draft with a transient manifest, the launcher MAY invoke
an authenticated local Codex CLI synchronously in a temporary clone of the
draft's exact head. Secret provisioning MUST remain deterministic launcher
work: token values and source credential files MUST NOT enter the clone, agent
prompt, command arguments, output, or project memory. An installed CLI is
preferred; a temporary fallback MUST be version-pinned and MUST NOT perform a
global installation.

On native Windows, the launcher MUST perform a token-free workspace-write
probe through `codex sandbox` before any semantic model execution and MUST pass
only the verified Windows sandbox mode to the isolated `codex exec` run. It
MAY fall back from a failed `elevated` probe to `unelevated`, but it MUST report
that fallback and MUST block when no supported mode can create, verify, and
remove the probe file. It MUST NOT obtain write access by selecting a
full-access or sandbox-bypass mode. Progress reporting MUST reflect actual
launcher phases as normal, line-oriented console output; work with no
measurable completion fraction MUST NOT receive an invented percentage. The
display MAY be suppressed without changing behavior.

Semantic `codex exec` MAY expose its documented JSONL event stream as an
observational channel while the process is active. A launcher that presents
that stream MUST parse events incrementally, bound and deduplicate displayed
fields, and render only caller-facing messages and safe activity metadata. It
MUST NOT display raw reasoning, command arguments or output, credential
material, or an unfiltered event payload. Streamed text is never readiness
evidence: the final result artifact and repository validations remain the sole
authority for publication.

Before local semantic work, the launcher MUST idempotently reconcile the common
Agile labels and one canonically marked, project-owned adoption issue through
its authenticated GitHub boundary. Ownership requires exactly one parsed
canonical marker on the first body line; marker-like text in quotations,
examples, or unrelated prose is not ownership evidence, and duplicate or
malformed markers MUST block. The local agent MUST receive that issue reference,
run under a finite timeout with spawned-command network disabled,
resolve the transient manifest, complete the repository-local records and
tests, apply bounded review gates, and leave every GitHub mutation and Git
publication operation to the launcher. Those records and tests MUST resolve
the current protocol identity through the integration authority defined in
Section 8 rather than embedding the adoption tag or commit as a live fact.
Before publication, the launcher MUST verify the unchanged draft head,
unchanged canonical consumer base, manifest removal, credential-file absence,
a valid reviewable change set, and an unchanged live remote branch. It MAY then
create one completion commit and push it only with an exact expected-head
lease. Immediately before marking the pull request ready, it MUST revalidate
the canonical base. A draft whose manifest was already absent when
the launcher inspected it MUST NOT be promoted automatically because its
completion provenance is unknown. Missing or ambiguous workflow runs, drafts,
local CLI authentication, semantic results, or branch ownership MUST block or
leave a clear manual handoff. Neither launcher nor agent may approve or merge
the pull request.

The launcher MUST own every local agent child process and descendant for the
duration of semantic execution. Timeout, pipeline cancellation, and exceptional
exit MUST attempt process-tree termination before process disposal and owned
temporary-root cleanup. On Windows, semantic execution MUST establish
kill-on-close process containment before model work. Interruption before the
completion push MUST leave the live proposal head unchanged; interruption in
the later push/marker window follows the recoverable transition below. A hard
host termination may prevent temporary-directory cleanup, so residue MUST be
treated as an owned cleanup artifact, not as permission to publish or delete an
ambiguous directory automatically.

For a consumer with no application source or product documentation, unavailable
product purpose, runtime/stack, architecture, build command, and product test
command MUST be recorded as `Not yet established`. Their absence MUST NOT by
itself block protocol adoption, and the agent MUST use structural adoption
checks without inventing product facts or behavior.

Before initial-adoption mutation, a launcher MUST assess a declared, bounded
set of exact committed protocol/governance paths and canonical target
collisions. Protocol/governance surfaces determine migration-policy evidence;
a generic target collision MAY require semantic review without falsely
asserting another protocol. `Auto` MAY resolve only protocol-evidence-free
state to `FreshAdoption`.
Evidence-bearing state MUST receive the maintainer's explicit
`FullMigration`, `HybridReconciliation`, acknowledged `CleanStart`, or `Abort`
selection; non-interactive ambiguity MUST fail closed. `FullMigration` MUST
preserve still-valid repository semantics before retiring old live authority.
`HybridReconciliation` MUST end with a consumer decision that makes ownership
and precedence unambiguous. `CleanStart` MUST import no legacy governance
semantics and MAY delete only exact assessed governance-record paths; a shared
completion envelope MUST reject unauthorized application or product-content
addition, modification, type change, or deletion. `Abort` MUST exit
without adoption mutation. The selected strategy and exact sorted surface
inventory MUST remain identical through dispatch, transient manifest,
proposal marker, project adoption issue, semantic prompt, recovery, and
completion for every strategy-bound proposal. A legacy proposal MAY recover
only the policy-free meaning already encoded in its immutable schema; if a
collision now requires a maintainer strategy, it MUST block for close and
reassessment rather than receive a retroactive policy. The agent MUST NOT
select or change that policy. Discovery of an
additional authority or a required deletion outside the bound inventory MUST
retain the manifest and block for maintainer reassessment. Push and scheduled
events MUST NOT create an unselected initial migration proposal. Completed
consumers remain on their installed current/update route; this transient
initial strategy is not a persisted consumer setting or migration-ledger item.

When completion spans a remote head update and a later ownership-marker or
pull-request update, the launcher MUST persist exact pre-push intent that binds
the previous and planned heads. If the planned head is live, a rerun MUST
validate and finalize it without repeating semantic work. If the previous head
is still live, the launcher MUST restore the exact proposal state before any
retry. Any other head MUST block; push-first state that only the later marker
can explain is prohibited.

A GitHub submodule consumer adopting `v0.4.0` or later MUST install the
self-reconciling, consumer-owned update workflow supplied by the pinned
protocol, or record a decision that defines an equivalent reviewed update
control for its platform.

Re-running the current quick-adoption launcher against a connected non-empty
consumer MUST classify committed repository evidence before secret or
repository mutation. No adoption footprint follows initial adoption. A complete
installation requires the exact protocol gitlink, canonical submodule metadata,
no transient manifest, one immutable installed release matching the gitlink,
and workflow/module/adapter blobs equal to that release. An equal requested tag
is an idempotent no-op after missing-secret reconciliation. An older same-major
tag dispatches the verified installed updater without overwriting its seed or
running adoption/Codex work. Partial, drifted, newer, or cross-major state MUST
fail before mutation. A seed-only in-flight adoption MAY resume only through its
original exact seed.

The updater MUST:

- consider only canonical lowercase `vM.m.rev` tags with no leading zeros and
  compare their numeric parts;
- require the selected update target to have an exact published immutable
  release before target checkout, staging, or remote mutation;
- retry only operations explicitly declared as idempotent GitHub API GET reads,
  with at most three total attempts and short bounded delays for transport
  failures, HTTP 408/429, and 5xx responses; each paginated retry MUST discard
  the incomplete attempt, while authentication, authorization, not-found,
  validation, JSON, and contract failures and every mutation remain
  single-attempt;
- transport structured or multiline GitHub issue, comment, patch, and pull-
  request bodies as exact UTF-8 without a BOM through an owner-scoped temporary
  file or standard input, never as native command-line body text, and remove
  temporary material on success or failure;
- treat malformed ownership text as non-canonical and fail closed, except that
  the exact historical quote-stripped schema-2 update issue MAY be rewritten
  once only after proving its complete generated title/body, trusted actor,
  repository, target, protocol commit, migration plan, absence of canonical or
  malformed duplicates, absence of the paired branch and any all-state pull
  request, and absence of a managed backlink; the updater MUST refetch before
  mutation, replace the full body through the safe transport, refetch again,
  and validate canonical ownership, while every near match blocks before
  mutation;
- propose only same-major upgrades and leave major migrations for explicit
  maintainer review;
- open a draft pull request and never merge it automatically;
- maintain at most one unambiguous, automation-owned update pull request;
- create and verify a newer replacement before closing an older superseded pull
  request and deleting its branch, then close only its exact tracking issue as
  not planned after branch convergence;
- stop without cleanup when ownership, metadata, changed paths, branch content,
  authentication, or replacement verification is ambiguous;
- require exactly one canonical case-sensitive ownership marker and bind it to
  the consumer repository, target tag, expected protocol commit, and planned
  branch head;
- bind each managed proposal to its Git submodule mode, exact expected managed
  path set and target blobs, authenticated updater actor, same-repository head,
  consumer default branch, and draft state;
- compare the marker, API head, and live remote ref with the planned head
  immediately before each destructive cleanup sequence, then enforce the
  expected-head lease immediately before branch deletion;
- use expected-state Git leases for automation branch creation and deletion,
  and attempt to reopen an old PR when its paired branch cleanup fails;
- fail closed after interrupted creation and require lease-safe reviewed
  recovery for an orphan reserved branch;
- inventory the complete reserved automation-branch namespace before mutation;
  checking only the currently selected target branch is insufficient, and an
  ambiguous older orphan MUST block;
- verify that all current managed updater copies equal the pinned release before
  mutation, validate the target's immutable append-only migration catalog and
  the consumer's exact satisfied-prefix ledger, then update the deterministic
  protocol pointer, only the target-different canonical workflow and updater
  scripts, exact catalog-derived consumer paths, and resulting ledger;
- compute every migration output and its complete managed path set before the
  first write, bind the proposal marker and candidate validation to the exact
  catalog, definition blobs, output blobs, ledger, and plan digest, and reject
  unknown or partial state before branch, issue, or pull-request mutation;
- when the current gitlink already equals the target but a pre-engine consumer
  has no satisfied ledger, open one automatically tracked same-target
  reconciliation proposal; after its merge, repeated discovery MUST be a no-op;
- use a consumer-repository-scoped write credential with explicit Contents,
  Pull requests, and Workflows permissions while keeping any private-source read
  credential separate; scheduled proposal creation and updater self-update MUST
  NOT use `GITHUB_TOKEN` for contents, pull-request, or workflow writes;
- use the proposal job's repository-scoped `GITHUB_TOKEN` only for `issues:
  write`: create missing standard Agile labels without overwriting existing
  definitions, create or reuse exactly one canonical target/SHA/repository-owned
  update issue, place its real tracking line in the initial draft, and record an
  exact pull-request/head backlink;
- bind each managed adoption or update proposal to exactly one same-repository
  issue through one canonical, non-closing `Tracking issue: #N` body line before
  maintainer merge; native closing keywords are forbidden because issue closure
  must follow verified branch convergence;
- react to an exact merged, same-repository managed proposal through the
  consumer workflow, revalidate the live pull request, current default branch
  containment, canonical marker, changed paths, tracking issue, open-PR branch
  reuse, API head, and live ref, then delete only the unchanged deterministic
  branch with an expected-head lease before recording evidence, removing
  transient status labels, and closing the issue;
- scope the post-merge finalization job's `GITHUB_TOKEN` to `contents: write`,
  `pull-requests: write`, and `issues: write`; pull-request write authority is
  limited to repairing the missing or exact `#REQUIRED` tracking line of one
  otherwise fully qualified installing legacy update, and this exception MUST
  NOT grant contents/pull-request/workflow authority to the proposal job;
- provide an explicit pull-request-number recovery dispatch that is idempotent
  for an already absent exact branch and an issue already closed with the exact
  finalization marker; before update discovery, default-branch push, schedule,
  and ordinary dispatch MUST also recover retained exact merged branches through
  this route;
- repair an installing legacy update only after proving its same-repository
  merge, canonical marker/branch/head/base, current default containment, current
  gitlink, allowed path set, immutable target release and exact changed updater
  blobs; every foreign, partial, moved, malformed, or ambiguous near-match MUST
  fail before issue or pull-request mutation;
- never rewrite project memory, root instructions, domain records, feature or
  decision records, tests, or other consumer-owned files merely to restate the
  live protocol pin; the only exception is an exact path and deterministic
  transformation declared by the immutable migration catalog and validated
  against the consumer ledger and actual bytes;
  and
- keep credentials outside repository content, project memory, logs, and pull
  request bodies.

The supplied generic automation supports the recommended `.ai/protocol` Git
submodule. Updating an opaque repository reference requires a deterministic,
provider-specific adapter or a manual reviewed upgrade.
A consumer pinned to an earlier reviewed release remains governed by that pin.
Pre-`v0.4.0` copied updater code cannot acquire self-reconciliation
retroactively; one reviewed migration installs the `v0.4.0` assets and
credential contract. Earlier consumers are not invalidated by this prospective
requirement.

## 9. Project-local AI memory

Portable project memory lives in the consuming repository at `.ai/memory`,
outside the protocol submodule. It contains durable project facts, collaboration
constraints, active context, and concise dated handoffs needed to continue work
on another machine.

Memory MUST:

- be specific to the current project and exclude unrelated project details;
- distinguish verified facts, decisions, assumptions, and unresolved questions;
- link to canonical features, decisions, issues, pull requests, and evidence;
- include dates or versions for facts that can become stale;
- resolve the current common-protocol identity from the configured integration
  authority and never duplicate its live tag or commit as a memory fact;
- be updated with the feature that changes the remembered fact;
- record corrections instead of silently preserving contradicted guidance; and
- exclude secrets, credentials, personal data without a project need, raw chat
  transcripts, and disposable implementation chatter.

The protocol repository follows this rule recursively: its own memory is stored
in its root `.ai/memory`, while reusable rules remain in this file. A consuming
project MUST NOT edit its project memory inside `.ai/protocol`.

## 10. Minimalism and exceptions

This protocol is a quality control surface, not a requirement to build a large
framework. Add automation only when it enforces a real recurring rule more
reliably than a short documented check. Prefer small, inspectable scripts and
native project tooling over a universal bootstrapper.

Urgent work may compress elapsed time, but it does not change gate order or
authorize implementation before Gate 1. Evidence may be concise and gates may
run back-to-back, but the evidence for a gate MUST exist before that gate is
passed. Any deviation requires the numbered-decision process in Section 1,
including its owner, risk, tests, deferred evidence, linked follow-up, and review
or expiry condition. No exception permits a knowingly incorrect completion
claim.
