# Common Development Protocol

Protocol version: **0.1.0**<br>
Status: **Release candidate for v0.1.0**

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

Every released version updates `VERSION`, relevant current-release metadata,
and `CHANGELOG.md`. Historical feature target versions remain unchanged.
Consumers SHOULD pin a tag or commit, never an unqualified moving branch. A
consuming project versions its own product independently and records the pinned
common-protocol version in its project memory.

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

Urgent work may compress sequencing but not evidence: record the exception,
risk, tests, and follow-up as linked work. No exception permits a knowingly
incorrect completion claim.
