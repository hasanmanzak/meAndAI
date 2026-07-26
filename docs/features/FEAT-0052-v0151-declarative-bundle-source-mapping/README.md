# FEAT-0052 - Declarative Bundle Source Mapping

| Field | Value |
| --- | --- |
| Classification | Backward-compatible bundle verification correction / [BUG-0034](https://github.com/hasanmanzak/meAndAI/issues/131) |
| Status | Complete |
| Target version | 0.15.1 |
| Issue | [Issue #131](https://github.com/hasanmanzak/meAndAI/issues/131) |
| Pull request | [PR #132](https://github.com/hasanmanzak/meAndAI/pull/132) |
| Decisions | [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md), [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The immutable `v0.15.0` bundle correctly places the shared content-identity
module at its runtime archive path while reading it from a different repository
source path. The builder and its bundle test encoded that relocation as separate
special cases. The post-publication verifier retained the old assumption that
every runtime archive path maps below `scripts/quick-adoption/`, so
[run 30176928208](https://github.com/hasanmanzak/meAndAI/actions/runs/30176928208)
requested a nonexistent GitHub Contents path and could not verify the valid
release.

## Outcome

One ordered release-owned inventory declares both the runtime bundle path and
the exact tracked repository source path. The builder, verifier, and test owners
consume that data instead of recreating mapping logic. Current authority can
still verify the bounded historical schema-1 releases without mutating them.

## Scope

- Upgrade the bundle source inventory to explicit schema-2 mapping records.
- Validate bundle and repository paths independently, including order,
  uniqueness, containment, regular-file, and exact Git-blob identity.
- Make the builder and publication verifier consume the same declared mapping.
- Retain a version-bounded schema-1 adapter only for releases `v0.12.4` through
  `v0.15.0`.
- Cover the correction through [TEST-0189](test-cases.md#test-0189) and retain
  the existing [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147)
  bundle contract.
- Publish the backward-compatible correction as `v0.15.1` with the established
  two release assets.

## Non-goals

- No consumer-local correction or recovery change.
- No new workflow, job, matrix, runner fan-out, release asset, or package
  manager.
- No quick-adoption runtime behavior or public parameter change.
- No mutation or replacement of immutable `v0.15.0`.
- No broad test-framework, verifier, or bundle rewrite.

## Readiness evidence

- Domain and contracts: `bundlePath` is the ordered ZIP/manifest identity;
  `repositoryPath` is the ordered tracked regular Git-blob identity. Neither is
  inferred from the other. Both use case-sensitive safe relative paths, have
  ordinal-ignore-case uniqueness within their own domains, and fail closed on
  missing, extra, duplicate, unsafe, or mismatched values.
- Consumers and dependencies: the canonical builder, publication verifier,
  [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147),
  and publication-evidence fixture are the complete same-contract sibling set.
  Consumers receive only the already established verified ZIP layout.
- Prior art and recurrence: [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
  owns deterministic bundle construction; [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  prohibits repeated active mapping logic. The failed hosted run and reproduced
  local `404` are the changed evidence. Repeating publication verification
  without changing the mapping authority is unsafe. [TEST-0189](test-cases.md#test-0189)
  is the executable recurrence barrier.
- Verification approach: test first in the existing publication-evidence
  owner, update the existing bundle owner, run both focused suites, validate
  historical `v0.15.0` live evidence, then run one final canonical suite before
  publication.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0235` <a name="risk-0235"></a> | Historical compatibility becomes an open-ended second mapping implementation. | [TEST-0189](test-cases.md#test-0189) requires the adapter to accept only schema 1 and release range `v0.12.4` through `v0.15.0`; schema 2 is mandatory afterward. |
| `RISK-0236` <a name="risk-0236"></a> | Explicit repository paths allow traversal, aliasing, or duplicate source identities. | Builder and verifier validate safe relative syntax, exact properties, bounds, and ordinal-ignore-case uniqueness before reading bytes. |
| `RISK-0237` <a name="risk-0237"></a> | Schema migration changes archive order or deterministic payload bytes. | [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) compares exact ordered entries and tracked Git-blob digests; runtime manifest schema and bundle paths remain unchanged. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0189](test-cases.md#test-0189) |
| Test code | Implemented / focused passing | Existing publication-evidence and bundle suites own the change; no new suite or fixture family |
| Baseline run | Failing for intended reason; focused correction passing | [Hosted run 30176928208](https://github.com/hasanmanzak/meAndAI/actions/runs/30176928208) and the local verifier both request the nonexistent inferred source path; the focused correction results are recorded below |
| Implementation run | Passing | [TEST-0189](test-cases.md#test-0189) passed in 171.4 seconds; retained [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) passed in 28.6 seconds |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0099` <a name="subf-0099"></a> | Declarative mapping, bounded legacy adapter, and release closure | [Issue #131](https://github.com/hasanmanzak/meAndAI/issues/131) | [TEST-0189](test-cases.md#test-0189), [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) | [FIND-0287](#find-0287) and [FIND-0288](#find-0288) resolved; focused owners and final canonical suite pass; hosted and publication evidence remain external gates | Implementation complete |

## Decisions and relationships

- Decisions: [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
  and [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md).
- Parent epic: N/A - bounded release correction.
- Dependencies: [FEAT-0036](../FEAT-0036-modular-quick-adoption-reliability/README.md)
  and [FEAT-0051](../FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md).
- Separate residual: [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
  remains outside this correction.

## Definition of Ready

- [x] [BUG-0034](https://github.com/hasanmanzak/meAndAI/issues/131),
  [FEAT-0052](README.md), [SUBF-0099](#subf-0099),
  [TEST-0189](test-cases.md#test-0189), and numbered risks are assigned.
- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Acceptance criteria.
- [x] Domain/boundary contracts, consumers, and dependencies.
- [x] Numbered risks and decisions.
- [x] Reviewable decomposition with a gate ledger.
- [x] Numbered test scenario and verification approach.
- [x] Test-code and baseline-run states recorded.
- [x] Prior-art and recurrence evidence recorded.

The maintainer's standing directive to complete the release chain authorizes
this proven post-publication blocker after Gate 1.

## Acceptance criteria

1. Schema 2 declares every ordered bundle/repository path pair without active
   path-specific logic in builder, verifier, or bundle test.
2. Exact source bytes come from the declared tracked Git blob and appear under
   the declared bundle path without changing manifest/archive identity.
3. Unsafe, missing, duplicate, reordered, or mismatched records fail closed.
4. Current authority verifies immutable `v0.15.0` through one bounded legacy
   adapter and requires schema 2 for `v0.15.1` and later.
5. `v0.15.1` retains the established two assets and unchanged workflow
   topology.

## Self-review

Review scope is limited to the inventory schema, its two production consumers,
the two existing owning suites, version/documentation/memory surfaces, and
release evidence. One fresh-diff review and one final canonical suite are the
completion budget.

| ID | Severity | Disposition | Finding | Resolution |
| --- | --- | --- | --- | --- |
| `FIND-0287` <a name="find-0287"></a> | High | `Resolved` | The builder and bundle test repeated one relocated-source exception while the verifier independently inferred repository paths, so a valid immutable payload produced a live post-publication `404`. Fresh-diff review also found three derivatives of that same authority leak: coercible top-level inventory types, a repeated mapping oracle in the bundle test, and a [TEST-0189](test-cases.md#test-0189) success path coupled to retained [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) state. | Schema 2 now owns every ordered `bundlePath` / `repositoryPath` pair; builder and verifier require the exact top-level shape and an actual source array; [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) derives its independent blob/archive assertions from the inventory instead of a second mapping table; [TEST-0189](test-cases.md#test-0189) owns its positive checkpoint; active path-specific inference is absent; the adapter is limited to immutable `v0.12.4` through `v0.15.0`; and both owning suites pass. |
| `FIND-0288` <a name="find-0288"></a> | Low | `Resolved` | Final documentation review found the feature index marked `Complete` while the canonical feature record was temporarily marked `In review`, which violated the current-release publication contract. | The canonical record is aligned to `Complete`; pending PR, CI, and release fields remain explicit external gates, and the protocol-governance `StructureOnly` assertions pass. |

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Bounded self-review and required convergence scan complete.
- [x] No unresolved `Blocking` finding; all other dispositions have evidence.
- [x] Documentation, links, version, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #131](https://github.com/hasanmanzak/meAndAI/issues/131) |
| Release authority | Pending immutable `v0.15.1` publication |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
