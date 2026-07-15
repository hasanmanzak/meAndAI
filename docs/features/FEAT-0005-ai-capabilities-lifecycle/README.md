# FEAT-0005 - Unified AI Capabilities Lifecycle

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | In review |
| Target version | 0.5.0 |
| Issue | [#17](https://github.com/hasanmanzak/meAndAI/issues/17) |
| Pull request | Pending |
| Decision | [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The v0.4 updater maintains an already adopted protocol submodule and its local
updater assets, but it cannot establish that adoption. Copying only the
workflow into an unadopted repository fails because the workflow invokes local
scripts and the updater requires an existing `.gitmodules` entry and protocol
gitlink. A populated repository also needs semantic agent review when
consumer-owned targets already exist; deterministic automation must not guess
how to merge those files.

## Outcome

A consumer can seed one canonical workflow and run one AI-capabilities
lifecycle operation. The operation executes bootstrap code from the exact
pinned protocol release when the local updater is absent, opens a review-only
adoption proposal appropriate to the observed collisions, and delegates to the
existing local updater after adoption. It never claims to run an AI agent;
instead, a transient manifest is the durable handoff for an explicitly invoked
agent or maintainer.

## Scope

- Route the existing consumer workflow between source-pinned bootstrap and the
  reviewed local updater.
- Define lifecycle states `BootstrapReady`, `AdoptionReviewRequired`,
  `PendingAdoption`, `Update`, and `BlockedManualReview`.
- Treat target-path collisions, not arbitrary repository content, as the
  distinction between deterministic bootstrap and semantic adoption review.
- For collision-free consumers, propose the protocol gitlink, root adapter,
  local memory skeleton, tracking templates, updater scripts, and transient
  handoff manifest in one draft pull request.
- For colliding consumers, propose only the transient handoff manifest and
  preserve every existing consumer-owned target unchanged.
- Use a deterministic adoption branch, an expected-absent creation lease, and
  no overwrite of an existing branch or proposal.
- Keep label creation, project-specific feature/decision records, memory
  tailoring, tests, and semantic merges as agent/maintainer completion tasks.
- Preserve v0.4 update behavior and credential boundaries.

## Non-goals

- Starting, hosting, scheduling, or impersonating Codex or another AI agent
  from GitHub Actions.
- A universal repository bootstrapper, merge engine, or semantic memory
  validator.
- Automatic approval, readiness transition, merge, or incompatible-major
  migration.
- Guessing how to merge existing `AGENTS.md`, memory, `.gitmodules`, issue
  templates, pull-request templates, or updater assets.
- Creating labels or issues from the updater token, or adding `Issues` write
  permission to that token.
- Supporting opaque repository references with the submodule bootstrap.
- Replacing the existing update resolver or supersession controls.

## Lifecycle and managed contracts

The seed is the canonical consumer workflow at
`.github/workflows/meandai-protocol-update.yml`. It checks out the protocol
source at the workflow's immutable bootstrap tag. If both local updater scripts
exist, it executes the local updater. Otherwise it executes the source-only
bootstrap adapter from that checkout.

The collision-free bootstrap targets are:

1. `.gitmodules` and `.ai/protocol`;
2. `AGENTS.md`;
3. the three `.ai/memory` skeleton files;
4. six issue forms and `.github/PULL_REQUEST_TEMPLATE.md`; and
5. the two local updater scripts.

The already present seed workflow is allowed only when its committed blob
equals the pinned template. Every other existing target is a collision. The
transient handoff path is
`.ai/adoption/meandai-capabilities.json`; an existing file at that path is an
ambiguous ownership condition and blocks mutation.

Both collision-free and collision proposals remain draft. The manifest records
the state, target tag, repository, collision paths, proposed paths, and required
agent/maintainer tasks. It MUST be removed before the proposal can become ready
or merge. Arbitrary application files outside the target set are never read as
evidence of collision and are never changed.

## Readiness evidence

- Domain and boundaries: lifecycle state, seed workflow, protocol pin,
  adoption targets, collision paths, manifest ownership, draft proposal,
  local updater, source bootstrap code, and agent handoff are distinct
  concepts. GitHub Actions performs deterministic repository operations only;
  an AI agent remains a separately invoked actor.
- Consumers and compatibility: new or unadopted submodule consumers can seed
  the v0.5.0 workflow. Existing v0.4.0 consumers receive the changed workflow
  through their ordinary updater and remain in `Update`. Earlier pins remain
  immutable and require their existing reviewed migration path.
- Error behavior: workflow drift, partial adoption, path collision, existing
  manifest, ambiguous branch/PR ownership, invalid tag/origin, or failed lease
  produces review handoff or a mutation-free block; no collision is
  overwritten.
- Verification: pure lifecycle tests, adapter fixtures, structural/version
  assertions, current updater regression, PowerShell AST parsing, and Ubuntu /
  Windows CI.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0022` | Supply chain | Workflow-only bootstrap executes code not yet stored in the consumer | Mitigated; protocol maintainers | Execute only from the workflow's immutable protocol tag and verify tag/checkout identity |
| `RISK-0023` | Integrity | A populated repository is misclassified as safe and consumer content is overwritten | Mitigated; bootstrap adapter | Exact target collision inventory, copy-only-when-absent behavior, staged-path validation, and negative fixtures |
| `RISK-0024` | Semantics | “AI capabilities” is mistaken for an automatically running AI agent | Mitigated; maintainers | Explicit manifest handoff and non-goal; workflow never calls an AI service |
| `RISK-0025` | Interruption | Branch creation succeeds before PR creation and leaves an orphan | Managed; consumer maintainer | Expected-absent lease, deterministic branch, no overwrite on later runs, and documented recovery |
| `RISK-0026` | Compatibility | Existing v0.4 consumers stop updating after lifecycle routing changes | Mitigated; protocol maintainers | Complete local-updater presence delegates unchanged behavior; full updater regression suite |
| `RISK-0027` | Authorization | Bootstrap expands the updater token into issue/label administration | Avoided; consumer admin | Labels remain agent/maintainer work; token permissions do not change |
| `RISK-0028` | Handoff | A draft adoption proposal is merged before semantic completion | Mitigated; consumer maintainer | Transient manifest, draft-only proposal, explicit readiness tasks, and protocol gate |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0027 through TEST-0032](test-cases.md) |
| Test code | Green | PowerShell planner, structural, and real-Git adapter fixtures pass for `TEST-0027` through `TEST-0032` |
| Baseline run | Passed | Windows PowerShell 5.1 repository suite on 2026-07-15 before FEAT-0005 changes |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0009` | Seed routing and collision-free deterministic bootstrap | [Issue #17](https://github.com/hasanmanzak/meAndAI/issues/17) | `TEST-0027` through `TEST-0029`; passed | Fresh-diff review complete; no slice finding | Reviewed |
| `SUBF-0010` | Collision handoff, idempotency, and updater transition | [Issue #17](https://github.com/hasanmanzak/meAndAI/issues/17) | `TEST-0030` through `TEST-0032`; passed | Fresh-diff review complete; no slice finding | Reviewed |

## Decisions and relationships

- Decision: [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Predecessor: [FEAT-0004](../FEAT-0004-self-updating-consumer-updater/README.md)
- Update controls: [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Credential boundary: [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md)
- Adoption guide: [Consumer adoption](../../adoption.md)
- Tracking: [issue #17](https://github.com/hasanmanzak/meAndAI/issues/17)

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable lifecycle acceptance criteria.
- [x] State, path, ownership, credential, compatibility, and handoff contracts identified.
- [x] Numbered risks and DEC-0006.
- [x] Two reviewable slices with a gate ledger.
- [x] Numbered test scenarios and verification approach.
- [x] Planned red test state and successful pre-change baseline recorded.

## Acceptance criteria

1. A consumer containing only the exact canonical seed workflow can execute
   bootstrap code from the workflow's immutable protocol tag without local
   scripts.
2. If no adoption target collides, one deterministic draft proposal contains
   the exact protocol gitlink, core adoption assets, and handoff manifest while
   preserving every unrelated repository path.
3. If any adoption target collides, one draft proposal contains only the
   manifest; the collision list is exact and no existing target is changed.
4. A complete existing adoption delegates to the local updater; a partial
   updater installation is never executed as a valid update installation.
5. Existing or ambiguous adoption branches and proposals are never reset,
   duplicated, deleted, or silently adopted; orphan state blocks with recovery
   evidence.
6. The manifest explicitly assigns labels, project docs, tailored memory,
   semantic merge, tests, and its own removal to an invoked agent/maintainer.
7. The workflow remains draft-only, source-pinned, read-only under
   `GITHUB_TOKEN`, and uses the existing separate write/read secrets without an
   Issues permission.
8. Existing updater behavior and the complete repository test suite continue
   to pass.

## Self-review

Completed on 2026-07-15. Each slice received one fresh-diff review covering
state transitions, target ownership, collision preservation, Git leases,
credential scope, and source-only boundaries. The one full tracked-project
convergence run covered diff hygiene, current-version references,
documentation links, PowerShell AST parsing, lifecycle fixtures, and the
existing updater regression suite. One blocking documentation finding was
fixed and the complete suite was then used as the single confirmation run; no
unchanged review loop or extra bootstrap layer was added.

| ID | Classification / severity / confidence | Evidence and action | Status |
| --- | --- | --- | --- |
| `FIND-0052` | Version consistency / High / High | The full suite found `templates/project/AGENTS.repository-reference.md` still pinned to `v0.4.0`; updated the current reference to `v0.5.0` and confirmed the complete suite. | Resolved |

No unresolved actionable in-scope finding remains. Explicitly owned residual
risks remain `RISK-0022` through `RISK-0028`.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Slice reviews and bounded convergence scan complete.
- [x] No unresolved blocking finding; residual risks are explicit and owned.
- [x] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates pass.

## Post-merge release gate

After the delivery pull request merges, tag the merged `main` commit as
`v0.5.0`, push the tag, and verify the remote reference.
