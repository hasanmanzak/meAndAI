# FEAT-0031 - v0.11.1 Project-Neutral Legacy-Consumer Fixture

| Field | Value |
| --- | --- |
| Classification | Maintenance feature / evidence correction |
| Status | Complete |
| Target version | 0.11.1 |
| Issue | [#79](https://github.com/hasanmanzak/meAndAI/issues/79) |
| Pull request | Pending |
| Decisions | [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md), [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md) |
| Tests | [TEST-0125 and TEST-0133](test-cases.md) |

## Problem

The common protocol's frozen pre-engine compatibility fixture, its regression
test, and canonical records retain the identity and live URLs of one consumer
repository. That coupling is unnecessary: the updater contract depends on a
legacy repository state, not on a product identity.

The `TEST-0125` record also claims an exact no-op rerun, while the executable
scenario stops after validating the first atomic proposal. The compatibility
claim therefore needs one direct second-plan assertion.

## Outcome

Canonical meAndAI content uses a minimal synthetic legacy-consumer fixture with
reserved example links. The existing migration and updater behavior remains
unchanged, `TEST-0125` proves the documented no-op rerun, and one bounded
structural assertion prevents the fixture/test surface from regaining a named
consumer dependency.

## Scope

- Rename and neutralize the frozen pre-engine consumer fixture and test symbols.
- Preserve the exact legacy fragment recognized by immutable `MIG-0001`.
- Execute a second migration plan over the applied atomic tree and assert exact
  satisfied/no-change semantics.
- Replace named-consumer references in canonical documentation and project
  memory with state-based wording and protocol-owned evidence links.
- Add `TEST-0133` inside the existing adapter suite.
- Publish the backward-compatible correction as `0.11.1`.

## Non-goals

- Changing updater, workflow, or migration-engine production behavior.
- Modifying `migrations/MIG-0001.json`, its catalog entry, or historical
  release state.
- Changing any consumer repository.
- Adding a bootstrapper, recursive validator, service, or new test framework.

## Readiness evidence

- Domain and contracts: applicability remains repository-state based; the
  legacy protocol SHA and migration-recognition fragment are preserved; only
  fixture identity and evidence wording change.
- Consumers and dependencies: `TEST-0125` calls the production planner and
  proposal stager; `MIG-0001` and `migrations/index.json` remain immutable.
- Compatibility: this is a test/documentation maintenance correction with no
  consumer-managed asset or runtime behavior change.
- Verification: focused adapter and migration suites, one complete protocol
  suite, one fresh-diff review, and one bounded post-development scan.

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0139` | Compatibility | Neutralization changes the exact fragment recognized by `MIG-0001` | Protocol maintainer / keep the fragment byte-identical and run migration plus adapter regressions |
| `RISK-0140` | Traceability | Removing consumer identity erases historical evidence | Protocol maintainer / retain dates and failure modes through protocol-owned issues and records |
| `RISK-0141` | Immutability | Historical migration data drifts during cleanup | Protocol maintainer / do not edit migration files and verify existing integrity gates |
| `RISK-0142` | Complexity | The correction grows another validator chain | Protocol maintainer / keep `TEST-0133` in the existing suite and prohibit a new framework |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0125 and TEST-0133](test-cases.md) |
| Test code | Implemented and focused green | Existing `TEST-0125` strengthened; `TEST-0133` added to the same adapter suite |
| Baseline run | Green release with evidence gap | `v0.11.0`; named fixture exists and direct no-op rerun is absent |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0056` | Synthetic fixture and exact no-op rerun proof | [Issue #79](https://github.com/hasanmanzak/meAndAI/issues/79) | `TEST-0125`; focused pass in 33.7 seconds | `FIND-0161` resolved; fixture and immutable migration blobs reviewed | Complete |
| `SUBF-0057` | Canonical documentation/memory neutralization and regression guard | [Issue #79](https://github.com/hasanmanzak/meAndAI/issues/79) | `TEST-0133`; focused pass in 33.7 seconds | `FIND-0162` through `FIND-0164` resolved in bounded review | Complete |

## Decisions and relationships

- [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
  owns immutable, state-based consumer migrations.
- [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md)
  owns atomic current-launcher recovery.
- [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md)
  introduced the generic migration engine.
- [FEAT-0028](../FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md)
  owns `TEST-0125`.

## Definition of Ready

- [x] Stable IDs and linked [issue #79](https://github.com/hasanmanzak/meAndAI/issues/79).
- [x] Problem, outcome, scope, and non-goals are bounded.
- [x] Acceptance criteria and compatibility contracts are explicit.
- [x] Risks and immutable dependencies are identified.
- [x] Work is split into two independently reviewable subfeatures.
- [x] Numbered scenarios and verification commands are defined.
- [x] Test-code and baseline states are recorded before implementation.

## Acceptance criteria

1. The canonical regression, its supporting records, and current project
   memory contain no real consumer-project identity or live consumer URL.
2. The project-neutral frozen fixture uses reserved synthetic URLs and keeps the
   migration-recognition fragment and legacy protocol SHA unchanged.
3. The core-only tree still fails only `TEST-0001`, while the atomic exact
   13-path proposal passes the frozen validator.
4. Replanning the applied atomic result returns `Satisfied`, zero changed paths,
   and an unchanged ledger.
5. `TEST-0133`, migration tests, adapter tests, and the complete protocol suite
   pass without a production updater change.
6. Version, changelog, feature index, links, and project memory agree on
   maintenance release `0.11.1`.

## Self-review

The 2026-07-18 fresh-diff review covered the fixture byte delta, migration
recognition fragment, legacy SHA, adapter symbols/messages/paths, second-plan
semantics, version pins, historical evidence links, project memory, and
immutable migration/catalog blobs. The fixture differs from its predecessor
only by the two reserved URL substitutions. Its Git blob is
`1dffab9c6b6d6f22aedb83c313b95d7b0f275183`; `MIG-0001` remains
`1b46c79f76703631688f85a5a2dfcee5128d9548` and the catalog index remains
`8fa228fc5fa66ff5017e4bc9560c19ac75a3839e`.

| ID | Classification / disposition | Priority | Finding and resolution | Status |
| --- | --- | --- | --- | --- |
| `FIND-0161` | Evidence defect / `Blocking` | p1 | `TEST-0125` documented an exact no-op rerun but did not execute it. The scenario now replans the applied ledger and requires `Satisfied`, no pending migration/path/change, and an unchanged ledger blob. | Resolved |
| `FIND-0162` | Change-caused pin consistency / `Blocking` | p1 | The initial `0.11.1` mechanical alignment left one escaped `v0\.11\.0` matcher and reused the new current tag as a future-tag fixture. The matcher now targets `v0.11.1`; the future fixture uses `v0.11.2`. | Resolved before the final suite |
| `FIND-0163` | Regression-scope defect / `Blocking` | p1 | The first `TEST-0133` draft inspected only fixture URLs. It now bounds the exact adapter surface with unique markers and requires the neutral path, function, variable, messages, commit text, reserved URLs, and absence of a live consumer GitHub URL. | Resolved; focused adapter suite passed |
| `FIND-0164` | Canonical coupling / `Blocking` | p2 | A bounded broad-name scan found two unrelated product examples in DEC-0021 after the original regression references were removed. They were replaced with state-based migration outcomes; the confirmation scan found no known project identity or external owner-repository URL. | Resolved |

The post-development project scan covered every tracked and intended file,
PowerShell parseability, current and escaped release pins, canonical Markdown
links, named-project and external owner-repository references, immutable
migration/catalog blobs, test scenario ownership, whitespace, and Git hygiene.
It excluded `.git` internals and publication facts that cannot exist before
merge. The finite budget was one initial scan plus this confirmation after the
four blocking corrections. No unresolved `Blocking` finding remains; no
recursive hardening or additional validator was introduced.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Focused and complete-suite successful test evidence recorded.
- [x] Bounded self-review and post-development scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed.

## Post-merge release evidence

[Issue #79](https://github.com/hasanmanzak/meAndAI/issues/79) is the stable
external authority. Exact merge commit, immutable `v0.11.1` release, hosted
checks, and branch cleanup remain pending until those facts exist.
