# Common Development Protocol

Protocol version: **0.9.1**<br>
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
continue only while the declared finite budget remains. The completion
condition is no unresolved `Blocking` finding. A finding is not cleared or
reclassified merely by relabeling it.

When the declared tests pass and the confirmation scan proves convergence,
perform the **converged final push** of the review branch and enter `Waiting`.
This is an ordinary Git push and does not create a tag or GitHub Release.
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
Protocol-version tags and GitHub Releases are separate post-merge distribution
events governed by Gate 7 and Section 8.

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
- Feature records link their issue, pull request, decisions, dependencies,
  tests, and related documentation.
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
versions its own product independently and records the pinned common-protocol
version in its project memory.

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
local updater scripts, and the transient handoff manifest at
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
accepting only a subset of identity fields is insufficient.

#### Local quick-adoption launcher

A consumer adopting `v0.6.0` or later MAY use the protocol's source-only local
launcher to establish the seed workflow. For `v0.8.0` or later, the download
command and launcher MUST verify the exact published immutable release before
retrieving or accepting executable source. The launcher MUST fetch the workflow
from that exact tag, verify the returned Git blob, reject a differing existing
seed, and stage and publish only
`.github/workflows/meandai-protocol-update.yml`. Existing connected consumers
MUST be clean, on their synchronized GitHub default branch, and preserve all
consumer-owned content. A new directory MAY be initialized and connected to a
new private repository by default, but unrelated local files MUST remain
unpublished.

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

After publication, the launcher MAY dispatch the lifecycle workflow and wait
for the exact published commit under a finite timeout. If that run creates one
deterministic adoption draft with a transient manifest, the launcher MAY invoke
an authenticated local Codex CLI synchronously in a temporary clone of the
draft's exact head. Secret provisioning MUST remain deterministic launcher
work: token values and source credential files MUST NOT enter the clone, agent
prompt, command arguments, output, or project memory. An installed CLI is
preferred; a temporary fallback MUST be version-pinned and MUST NOT perform a
global installation.

Before local semantic work, the launcher MUST idempotently reconcile the common
Agile labels and one canonically marked, project-owned adoption issue through
its authenticated GitHub boundary. Ownership requires exactly one parsed
canonical marker on the first body line; marker-like text in quotations,
examples, or unrelated prose is not ownership evidence, and duplicate or
malformed markers MUST block. The local agent MUST receive that issue reference,
run under a finite timeout with spawned-command network disabled,
resolve the transient manifest, complete the repository-local records and
tests, apply bounded review gates, and leave every GitHub mutation and Git
publication operation to the launcher. Before publication, the launcher MUST
verify the unchanged draft head, manifest removal, credential-file absence, a
valid reviewable change set, and an unchanged live remote branch. It MAY then
create one completion commit, push it only with an exact expected-head lease,
and mark the pull request ready. A draft whose manifest was already absent when
the launcher inspected it MUST NOT be promoted automatically because its
completion provenance is unknown. Missing or ambiguous workflow runs, drafts,
local CLI authentication, semantic results, or branch ownership MUST block or
leave a clear manual handoff. Neither launcher nor agent may approve or merge
the pull request.

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
The updater MUST:

- consider only canonical lowercase `vM.m.rev` tags with no leading zeros and
  compare their numeric parts;
- require the selected update target to have an exact published immutable
  release before target checkout, staging, or remote mutation;
- propose only same-major upgrades and leave major migrations for explicit
  maintainer review;
- open a draft pull request and never merge it automatically;
- maintain at most one unambiguous, automation-owned update pull request;
- create and verify a newer replacement before closing an older superseded pull
  request and deleting its branch;
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
  mutation, then update the deterministic protocol pointer plus only the
  target-different canonical workflow and updater scripts;
- use a consumer-repository-scoped write credential with explicit Contents,
  Pull requests, and Workflows permissions while keeping any private-source read
  credential separate and the workflow `GITHUB_TOKEN` read-only;
- never rewrite project memory, root instructions, domain records, feature or
  decision records, tests, or other consumer-owned files; and
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
