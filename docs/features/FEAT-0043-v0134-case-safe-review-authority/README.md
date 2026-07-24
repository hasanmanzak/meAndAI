# FEAT-0043 - Case-Safe Repository Identity for Review Authority

| Field | Value |
| --- | --- |
| Classification | Backward-compatible capability-finalization correction / [BUG-0025](https://github.com/hasanmanzak/meAndAI/issues/106) |
| Status | Complete |
| Target version | 0.13.4 |
| Issue | [#106](https://github.com/hasanmanzak/meAndAI/issues/106) |
| Pull request | [#107](https://github.com/hasanmanzak/meAndAI/pull/107) |
| Decisions | [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md) and [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) |
| Tests | [TEST-0167](test-cases.md) and [TEST-0168](test-cases.md) |

## Problem

The v0.13.3 historical capability-review recovery correctly canonicalizes the
repository binding used by the owner-attestation contract to lowercase. A
consumer ledger can retain the same GitHub pull-request URL with the
repository's display casing. The finalizer compares those two equivalent
repository identities as case-sensitive text and rejects the already-proven
merged review before cleanup.

The failure is generic to any GitHub repository whose canonical evidence and
display URL differ only by owner or repository-name casing. It was reproduced
by [Derdini run 30004752646](https://github.com/hasanmanzak/Derdini/actions/runs/30004752646),
which reached the v0.13.3 historical recovery path after an exact-head owner
attestation and then rejected the equivalent mixed-case pull-request binding.

## Outcome

Treat GitHub owner and repository-name components as case-insensitive identity
when the historical finalizer compares canonical repository bindings. Keep the
GitHub host, pull-request path shape, pull-request number, exact reviewed head,
actor authority, immutable release provenance, ledger bytes, and every cleanup
gate unchanged and fail closed for any difference beyond permitted casing.

## Scope

- Parse the trusted GitHub pull-request URL as structured identity rather than
  comparing the complete URL to a synthesized lowercase string.
- Compare only GitHub owner and repository-name components
  case-insensitively; retain strict validation for host, path shape, and pull-
  request number.
- Apply the same repository-identity contract to current and historical
  review-authority evidence where those paths compare canonical repository
  bindings.
- Preserve [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md) owner-attestation and [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) historical recovery
  authority, provenance, mutation ordering, and idempotency.
- Add focused project-neutral regression coverage to the existing capability-
  review owner.

## Non-goals

- Lowercasing arbitrary URLs, ledger content, actor logins, branch names,
  commit IDs, issue markers, or consumer-owned files.
- Accepting another host, owner, repository, path, pull-request number, head,
  or ambiguous URL merely because some text compares equal after folding.
- Rewriting an existing consumer ledger or weakening its exact byte and prefix
  preservation contracts.
- Mutating Derdini or embedding consumer-specific production or fixture
  knowledge in meAndAI.
- Adding a workflow, hosted job, retry loop, or broader capability-review
  refactor.

## Readiness evidence

- Domain and contracts: GitHub repository identity is the case-insensitive
  owner/repository pair already canonicalized by
  [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md);
  [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md)
  continues to govern all historical proof and cleanup behavior.
- Consumers and dependencies: the source-only capability-review runner and its
  existing GitHub pull-request, issue, review, comment, permission, release,
  and Git-object reads; no token-scope or workflow expansion.
- Related behavior: [FEAT-0042](../FEAT-0042-v0133-historical-capability-review-recovery/README.md)
  remains the historical recovery authority; this feature corrects only its
  repository-identity comparison boundary.
- Risks: `RISK-0201` and `RISK-0202` below.
- Verification: focused capability-review tests first, structural and release-
  pin checks, one bounded fresh-diff review, and one final relevant protocol
  validation command.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0167](test-cases.md) and [TEST-0168](test-cases.md) |
| Test code | Implemented | [TEST-0167](test-cases.md) and [TEST-0168](test-cases.md) extend the existing capability-review production fixture without consumer-specific names and are registered in the capability evidence authority |
| Baseline run | Failed as intended | [Derdini run 30004752646](https://github.com/hasanmanzak/Derdini/actions/runs/30004752646) and the 10.3-second test-first run reproduce the v0.13.3 mixed-case false rejection |

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0201` | Identity and authorization | Broad case folding makes a different host, path, pull-request number, or malformed URL appear equivalent | Capability-review maintainer / parse the canonical GitHub PR URL, fold only owner and repository-name components, retain exact validation for all other binding fields, and prove negative variants in [TEST-0168](test-cases.md) |
| `RISK-0202` | Recovery safety and compatibility | Fixing the false rejection weakens historical proof, rewrites consumer state, or changes cleanup ordering | Consumer lifecycle maintainer / reuse the unchanged [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md)/[DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) authority and mutation path; [TEST-0167](test-cases.md) proves exact branch-first/issue-last recovery and idempotent rerun while [TEST-0168](test-cases.md) proves zero mutation on mismatch |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0082` | Structured case-safe GitHub repository identity comparison with unchanged historical authority and cleanup gates | [Issue #106](https://github.com/hasanmanzak/meAndAI/issues/106) | [TEST-0167](test-cases.md), [TEST-0168](test-cases.md); expected-red 10.3 seconds, corrected confirmation 14.5 seconds | One bounded review found three coverage gaps and one stale-record item; all corrected without production-scope expansion | Complete |

## Decisions and relationships

- Owner-attestation identity: [FEAT-0041](../FEAT-0041-v0132-exact-head-owner-attestation/README.md) / [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md)
- Historical recovery: [FEAT-0042](../FEAT-0042-v0133-historical-capability-review-recovery/README.md) / [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md)
- Semantic capability lifecycle: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- External incident evidence: [Derdini run 30004752646](https://github.com/hasanmanzak/Derdini/actions/runs/30004752646)

## Definition of Ready

- [x] [BUG-0025](https://github.com/hasanmanzak/meAndAI/issues/106), `FEAT-0043`, `SUBF-0082`, and linked [issue #106](https://github.com/hasanmanzak/meAndAI/issues/106) exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria and case-safe repository-identity contracts are
      defined.
- [x] Consumers, dependencies, compatibility, and token boundaries are known.
- [x] `RISK-0201`, `RISK-0202`, [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md), and [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) are recorded.
- [x] One independently reviewable slice has a gate ledger.
- [x] [TEST-0167](test-cases.md) and [TEST-0168](test-cases.md) and the bounded verification approach are defined.
- [x] Test-code and current-baseline states are recorded before implementation.

## Acceptance criteria

1. Canonical GitHub pull-request bindings that differ only in owner or
   repository-name casing resolve to the same repository identity.
2. Host, URL/path structure, pull-request number, exact reviewed head, actor
   authority, immutable release provenance, ledger, and cleanup evidence retain
   their existing strict behavior.
3. Another owner or repository, deceptive prefix/suffix, wrong host or path,
   wrong pull-request number, malformed or ambiguous URL, and any non-case
   mismatch fail before branch, comment, issue, ledger, or proposal mutation.
4. A proven merged strict-predecessor review with an exact personal-owner
   attestation and a mixed-case equivalent PR URL completes the existing
   expected-OID branch deletion, closure evidence, issue-last cleanup, and one
   fresh inventory.
5. A completed rerun is an exact no-op and the correction performs no consumer
   ledger rewrite or consumer-specific behavior.
6. No workflow, hosted job, credential permission, catalog rule, or release-
   provenance boundary changes.

## Verification approach

Register [TEST-0167](test-cases.md) and [TEST-0168](test-cases.md) in the existing capability-adoption owner and run them
against the unchanged v0.13.3 runner to capture the intended mixed-case
failure. Implement the smallest structured identity comparison, rerun the
focused owner, then run structural and release-pin checks. Perform one bounded
fresh-diff review and one final relevant protocol validation command; only a
proven Blocking finding reopens SUBF-0082.

## Self-review

One bounded fresh-diff review found no production defect and confirmed
PowerShell 5.1 compatibility. It found missing independent positive casing
variants, deceptive near-match negatives, an ineffective historical inventory
count assertion, and stale record states. [TEST-0167](test-cases.md) now covers owner-only,
repository-only, and combined casing plus rerun and exact inventory behavior;
[TEST-0168](test-cases.md) rejects eleven foreign or malformed variants; [TEST-0165](../FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md) now binds the
actual current/historical/fresh inventory sequence; records were refreshed.
No URL, authorization, provenance, ledger, or cleanup boundary was widened.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful focused results recorded.
- [x] Bounded self-review and applicable pre-publication validation complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current for
      the pre-publication tree.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #106](https://github.com/hasanmanzak/meAndAI/issues/106) |
| Pull request | [#107](https://github.com/hasanmanzak/meAndAI/pull/107) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
