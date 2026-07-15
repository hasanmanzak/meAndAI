# Common Development Protocol

Protocol version: **0.5.0**<br>
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

Every material work item or conclusion MUST have a stable identifier. GitHub's
issue number is a link, not a replacement for the domain identifier.

| Identifier | Classification | Purpose |
| --- | --- | --- |
| `EPIC-NNNN` | Epic | Outcome spanning multiple features |
| `FEAT-NNNN` | Feature | Independently valuable capability |
| `SUBF-NNNN` | Subfeature | Independently reviewable feature slice |
| `TASK-NNNN` | Task | Bounded implementation or maintenance work |
| `BUG-NNNN` | Bug | Confirmed incorrect behavior |
| `FIND-NNNN` | Finding | Audit or review observation requiring triage |
| `DEC-NNNN` | Decision | Architectural or process decision |
| `TEST-NNNN` | Test scenario | Verifiable behavior or quality condition |
| `RISK-NNNN` | Risk | Explicit uncertainty with impact and response |

Numbers are repository-local, four digits, monotonically allocated per class,
and never reused. Titles begin with the identifier. Records state status,
classification, relevant links, and the evidence supporting closure.

A `RISK-NNNN` record lives in the owning feature or decision. Create a linked
GitHub finding when a risk is independent, unresolved, or needs separate
ownership. Test records identify their feature or subfeature and current state.

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


#### Bounded self-validation

Unless a known risk or project decision requires more, the default validation
budget is:

1. one fresh-diff self-review pass after the declared tests;
2. one final relevant verification command after fixes; and
3. one triage that classifies each observation as blocking or follow-up.

Only a blocking finding that invalidates acceptance, correctness, safety,
compatibility, or required evidence reopens implementation scope. A
non-blocking improvement is linked for later work and MUST NOT trigger another
review loop in the current delivery.

Stop validation when acceptance criteria and declared tests pass, no blocking
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
- the self-review and required project scan have no unresolved blocking finding;
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
tag is a separate post-merge release gate: update the default branch, tag the
merged release commit, push the tag, and verify the remote reference. A version
tag MUST NOT be required by the feature's pre-merge Definition of Done.

## 5. Full-project scans

When a project scan is requested, at project onboarding, before a major release,
or when architectural confidence is insufficient, scan the entire tracked
project at the highest practical detail. Sampling alone is not a project scan.
State any inaccessible, generated, binary, external, or otherwise unreviewed
scope explicitly.

### Post-development convergence scan

After development is declared complete, perform a full-project scan under this
section. Document every observation, classify it, and order actionable findings
from highest to lowest priority before remediation, using severity, impact, and
dependency order as inputs. Resolve the highest-priority actionable in-scope
findings first.

After remediation, repeat the full-project scan. The completion condition is a
convergence pass with no unresolved actionable in-scope finding. A finding is
not cleared merely by relabeling it: an accepted residual risk requires an
owner, rationale, and link, while an external or legacy follow-up may be
separated only under the rules in Gate 5.

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

Each finding is recorded as `FIND-NNNN` with classification, severity
(`critical`, `high`, `medium`, `low`, or `info`), confidence, evidence,
affected scope, impact, recommended action, status, and links to related issues,
pull requests, features, decisions, tests, and documentation. Separate verified
defects from risks and optional improvements.

A compact finding register MAY declare shared scope, confidence, impact, and
canonical evidence links once when they apply unambiguously to every listed
row. Each row still records its identifier, classification, severity, specific
evidence, action, and status. Do not split one coherent observation into
multiple records merely to increase detail.

## 6. Documentation graph

- Every feature has `docs/features/FEAT-NNNN-slug/README.md` and
  `test-cases.md`.
- Every material architectural or process decision has
  `docs/decisions/DEC-NNNN-slug.md`.
- Feature records link their issue, pull request, decisions, dependencies,
  tests, and related documentation.
- Decisions link affected features and superseded or related decisions.
- Issues and pull requests link canonical repository documents and related
  issues, pull requests, wiki pages, or external documentation.
- Links MUST be relative for repository files and absolute for GitHub or
  external resources. They MUST be clickable and validated before completion;
  record automated local-link results and manual or automated external-link
  evidence separately.
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

Versions use `M.m.rev` and Git tags use `vM.m.rev`.

- `M`: incompatible protocol, public contract, data, or adoption change.
- `m`: backward-compatible feature or meaningful capability addition.
- `rev`: backward-compatible correction, clarification, or maintenance change.

A new mandatory control MAY be introduced in `m` only when it applies
prospectively to consumers that choose to adopt or upgrade to that release and
does not invalidate a consumer correctly pinned to an earlier release. A forced
migration of already conforming consumers is incompatible and increments `M`.

Every released version updates `VERSION`, relevant current-release metadata,
and `CHANGELOG.md`. Historical feature target versions remain unchanged.
Consumers SHOULD pin a tag or commit, never an unqualified moving branch. A
consuming project versions its own product independently and records the pinned
common-protocol version in its project memory.

### Consumer update proposals

#### AI-capabilities lifecycle

A GitHub submodule consumer adopting `v0.5.0` or later MAY begin with only the
canonical workflow at `.github/workflows/meandai-protocol-update.yml`. That
workflow is the seed for one AI-capabilities lifecycle covering first adoption,
bootstrap, and later updates. It MUST execute bootstrap code only from the
immutable protocol tag embedded in the seed and verify that source identity
before proposing consumer changes.

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
overwrite. The manifest MUST be removed before the draft becomes ready or
merges. After reviewed adoption, the local updater owns compatible update
discovery and supersession under the controls below. The source-only bootstrap
resolver and adapter are not copied into the consumer.

A GitHub submodule consumer adopting `v0.4.0` or later MUST install the
self-reconciling, consumer-owned update workflow supplied by the pinned
protocol, or record a decision that defines an equivalent reviewed update
control for its platform.
The updater MUST:

- consider only canonical lowercase `vM.m.rev` tags with no leading zeros and
  compare their numeric parts;
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
A consumer pinned to an earlier immutable release remains governed by that pin.
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
