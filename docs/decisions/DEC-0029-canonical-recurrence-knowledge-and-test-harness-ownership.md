# DEC-0029 - Keep Recurrence Knowledge and Test Harness Roles under Canonical Owners

- Classification: Decision
- Status: Proposed
- Date: 2026-07-25
- Decision owners: meAndAI maintainer and protocol contributors
- Related features: [FEAT-0051](../features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md)
- Related decisions: [DEC-0002](DEC-0002-project-local-memory.md), [DEC-0015](DEC-0015-event-triggered-stability-cycles.md), [DEC-0019](DEC-0019-hosted-runner-efficiency.md), [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md), and [DEC-0028](DEC-0028-upstream-owned-reusable-corrections.md)

## Context

Prior solutions and safe tooling routes can be forgotten when their evidence is
buried in dated records, while repeated test mechanics can acquire multiple
local owners. Memory, regression evidence, canonical production logic, shared
test mechanics, capability semantics, executable scenarios, and fixture state
have different authority and lifecycle requirements. Treating any of them as
interchangeable creates recurrence, duplication, and false completion risks.

The repository already defines project-local memory, bounded stability cycles,
hosted-runner efficiency, append-only semantic capabilities, and upstream
ownership. [FEAT-0051](../features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md)
needs one explicit boundary decision that composes these
authorities without creating a new memory system or a universal test framework.

## Decision

1. Confirmed recurring failures are represented by concise, curated signature
   entries. Reusable protocol rules live in the common protocol; project,
   environment, and tool facts live in that project's `.ai/memory` under
   [DEC-0002](DEC-0002-project-local-memory.md). Tool-local memory may cache a
   pointer but is not portable authority.
2. A signature entry routes later work to canonical evidence and a safe
   response. It records applicability, cause, canonical feature/decision/test,
   fixed release, unsafe retry boundary, freshness, supersession, and review
   condition. It never substitutes for an executable regression.
3. A correction or new helper requires same-contract sibling inventory and
   canonical-owner classification. Similar names alone are insufficient.
4. Focused shared modules own only generic test mechanics. Capability-specific
   builders, adapters, assertions, and semantic evidence remain with the owning
   capability. Reusable production behavior is called through its production
   owner rather than copied into test infrastructure.
5. The root runner owns discovery, profile selection, dispatch, and aggregation.
   The harness owns explicit context, assertions, result collection, runtime
   TEST identity, and cleanup. Executable cases own TEST input/action/expected
   outcome. Capability support owns local builders/adapters. Fixtures remain
   inert state or dependency doubles; mocks may simulate output and exit codes
   but cannot assert or complete tests.
6. Runtime execution evidence must identify the exact case that ran and passed
   exactly once. Source-string, TEST-constant, or assertion-name inference is
   not execution evidence.
7. Implementation appends one `test-harness-modularity` capability under
   [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md) and migrates
   only the finite
   [FEAT-0051](../features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md)
   hotspot ledger. Existing
   capability definitions, active TEST identities, isolation, supported
   runtimes, and workflow topology remain compatible.

## Consequences

- Later agents gain a portable, reviewable route around already-known failures
  without turning raw operational history into authority.
- Recurring defects require both durable routing knowledge and executable
  prevention, so neither can silently replace the other.
- Generic helpers become easier to maintain, while semantic differences remain
  local and explicit.
- The role boundary makes runtime evidence stronger but requires staged
  migration and equivalence proof for large existing suites.
- A bounded owner-list guard is permitted; a name-only clone detector, memory
  daemon, or full test-framework rewrite is not.
- Consumers receive the semantic capability declaration but do not copy common
  test assets. A consumer with no applicable automated surface may record a
  reviewed NotApplicable result.

## Alternatives considered

- Rely only on chat or tool-local memory: rejected because it is not portable,
  reviewable, or reliable across machines and agents.
- Treat memory as proof that a defect is prevented: rejected because only
  executable evidence can close the regression contract.
- Merge every same-named helper automatically: rejected because names do not
  establish semantic equivalence.
- Build one universal harness or clone detector: rejected because it increases
  coupling, false positives, validation cost, and bootstrap complexity.
- Leave all helpers local: rejected because confirmed generic families would
  retain multiple authorities and continue to drift.

## Review condition

Review this decision if a declared generic helper cannot be shared without
capability semantics, if exact runtime identity cannot be preserved during the
three migrations, if the capability cannot be appended compatibly, or if the
bounded guard requires workflow expansion or broad source-clone detection.
