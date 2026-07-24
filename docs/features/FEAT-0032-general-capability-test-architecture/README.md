# FEAT-0032 - General Capability Framework and Test Architecture

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.12.0 |
| Issue | [#81](https://github.com/hasanmanzak/meAndAI/issues/81) |
| Pull request | [#82](https://github.com/hasanmanzak/meAndAI/pull/82) |
| Decision | [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) |
| Tests | [TEST-0134](test-cases.md), [TEST-0135](test-cases.md), [TEST-0136](test-cases.md), [TEST-0137](test-cases.md), [TEST-0138](test-cases.md), [TEST-0139](test-cases.md), and [TEST-0140](test-cases.md) |

## Problem

The protocol has deterministic adoption, immutable consumer migrations, and a
reviewed update lifecycle, but it has no small general contract for practices
that require repository-aware semantic adoption. Test and validation suites
also accumulate as large root-level scripts. Their physical layout is neither
capability-oriented nor recursively discoverable, shared runner logic is mixed
with protocol assertions, and fixtures do not consistently express one owning
capability.

Without a semantic capability lifecycle, a new protocol practice can be
documented but cannot be assessed consistently during fresh adoption or normal
existing-consumer update discovery. Without a test-architecture capability,
every consumer can recreate the same growing-script problem independently.

## Outcome

An immutable protocol release can declare typed capabilities. A consumer
records reviewed assessment evidence in a separate capability ledger without
creating another protocol pin or granting the updater semantic write authority.
Freshly adopted and already adopted consumers discover the same pending
semantic capability lifecycle. The first definition, `test-architecture`,
organizes tests physically by capability while preserving feature-based
`TEST-NNNN` traceability, deterministic recursive discovery, common test
infrastructure, process isolation, and capability-local fixtures.

## Scope

- Add a validated, ordered, append-only capability catalog and immutable
  definition blobs with the types `Deterministic`, `DeclarativeMigration`,
  `Semantic`, and `Manual`.
- Add a separate consumer-owned capability assessment ledger and pure resolver
  for `Conforming`, `NotApplicable`, `AdoptionRequired`, and `ReviewRequired`.
- Add review-only semantic capability discovery after fresh adoption, for an
  already-current consumer, and after an ordinary compatible protocol update.
- Bind unresolved semantic work to one canonical issue, one deterministic
  draft pull request, one transient manifest, exact catalog identity, and
  evidence-based completion with idempotent re-evaluation.
- Add `test-architecture` as the first semantic definition.
- Reorganize this repository's tests under `tests/capabilities/<capability>`,
  retain `tests/protocol.tests.ps1` as the stable entry point, and move generic
  discovery/result/evidence logic into `tests/infrastructure`.
- Discover canonical suites recursively in normalized repository-relative
  ordinal order and retain a small explicit profile map only for partial native
  compatibility execution.
- Move fixtures to their owning capability and preserve a fresh mutable state
  boundary for every scenario while retaining separate suite processes.

## Non-goals

- Automatically approving, semantically editing, marking ready, or merging a
  consumer capability pull request.
- Treating semantic capability work as a `MIG-NNNN` transition or adding its
  paths to the deterministic updater's permanent managed set.
- Rewriting arbitrary consumer tests, product code, project memory, or domain
  records from GitHub Actions.
- A universal repository parser, semantic validator, hosted AI service,
  capability daemon, background loop, or validator-for-validator chain.
- Invalidating an earlier consumer that remains correctly pinned to an
  immutable release.
- Replacing feature records or `TEST-NNNN` scenario ownership with physical
  directory names.

## Readiness evidence and contracts

### Capability model

- A capability has one stable lowercase slug, one immutable JSON definition,
  one declared type, and one Git-blob identity in the ordered release catalog.
- Compatible catalogs are append-only. A changed meaning uses a new appended
  definition; an existing slug or definition blob cannot be rewritten,
  reordered, or removed.
- `Deterministic` capabilities may be satisfied only by exact automation;
  `DeclarativeMigration` delegates exact state changes to the existing
  migration catalog; `Semantic` requires repository-aware review; `Manual`
  records evidence that automation cannot establish.
- The consumer ledger is automation evidence, not a live protocol pin. It
  binds the exact capability definition blob, terminal outcome, reviewed
  evidence, and review identity.
- `Conforming` and `NotApplicable` are terminal only with reviewed evidence.
  `AdoptionRequired` and `ReviewRequired` remain open handoff states and cannot
  be written as satisfied ledger entries.

### Lifecycle and ownership

- Initial protocol adoption remains bounded by its existing content envelope.
  After that reviewed adoption, the installed workflow evaluates the current
  capability catalog and creates a separate semantic handoff when required.
- An updater whose immutable code predates this framework first installs the
  normal target updater. The newly installed workflow then performs same-target
  capability discovery; no source-version switch is allowed.
- An unchanged terminal definition/ledger pair is an exact no-op. Missing,
  reordered, duplicated, changed, partial, malformed, or ambiguous evidence
  fails closed or remains review-required.
- Semantic changes remain consumer-owned. Automation may create only the
  transient discovery manifest, canonical issue, and draft proposal; the
  consumer's DoR/DoD and maintainer review authorize the actual adoption.

### Test architecture

- Canonical executable suites live below `tests/capabilities/<capability>`.
  Feature records remain the canonical history and own each `TEST-NNNN` once.
- Full discovery is recursive, repository-relative, case-safe, link-safe, and
  sorted with ordinal comparison. Duplicate normalized owners, unsafe paths,
  adapter/support files masquerading as suites, and zero discovered suites fail
  closed.
- The stable root runner executes every canonical suite in a separate process.
  Partial profiles list only discovered owner paths plus explicit arguments.
- Shared infrastructure contains only truly common discovery, evidence,
  result, and runtime contracts. Domain-specific builders and mocks remain
  capability-local.
- Fixtures are capability-local by default. A shared fixture requires one
  identical contract and immutable/read-only use; every mutable repository,
  remote, environment, collection, and temporary root is case-local.

### Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0143` | Consumer ownership | Capability discovery becomes permission to rewrite semantic consumer files | Protocol maintainer / manifest-only automation, separate reviewed PR, and exact managed-path exclusion in [TEST-0139](test-cases.md) and [TEST-0140](test-cases.md) |
| `RISK-0144` | Contract confusion | Semantic capabilities are treated as deterministic migrations | Protocol maintainer / separate catalog, ledger, resolver, and explicit type delegation in [TEST-0134](test-cases.md) |
| `RISK-0145` | Evidence integrity | An unsupported or unreviewed result is recorded as terminal | Consumer maintainer / terminal-only ledger schema, review identity, and outcome matrix in [TEST-0135](test-cases.md) |
| `RISK-0146` | Lifecycle duplication | Repeated discovery creates multiple issues, branches, or pull requests | Workflow maintainer / exact repository/catalog marker, canonical inventory, and idempotency in [TEST-0140](test-cases.md) |
| `RISK-0147` | Discovery integrity | Recursive discovery is nondeterministic, escapes the test root, or loses nested owner identity | Test maintainer / ordinal normalized owners, link/case checks, and [TEST-0136](test-cases.md) |
| `RISK-0148` | Traceability | Moving suites breaks canonical feature-to-scenario evidence | Test maintainer / unchanged scenario declarations, nested owner validation, and [TEST-0137](test-cases.md) |
| `RISK-0149` | Fixture isolation | Shared mutable Git, mock, environment, or module state makes results order-dependent | Test maintainer / capability-local fixtures, per-suite processes, and [TEST-0138](test-cases.md) |
| `RISK-0150` | Immutable handoff | Documentation claims old updater code can perform the new semantic lifecycle | Protocol maintainer / capability-based post-update handoff and explicit two-stage evidence in [TEST-0140](test-cases.md) |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0134](test-cases.md), [TEST-0135](test-cases.md), [TEST-0136](test-cases.md), [TEST-0137](test-cases.md), [TEST-0138](test-cases.md), [TEST-0139](test-cases.md), and [TEST-0140](test-cases.md) |
| Test code | Implemented and automated | Capability catalog/review, recursive discovery, topology/isolation, workflow, and compatibility fixtures own [TEST-0134](test-cases.md), [TEST-0135](test-cases.md), [TEST-0136](test-cases.md), [TEST-0137](test-cases.md), [TEST-0138](test-cases.md), [TEST-0139](test-cases.md), and [TEST-0140](test-cases.md) |
| Baseline run | Green | Exact `main` commit `37855c2`; `tests/protocol.tests.ps1 -StructureOnly` passed in 2.6 seconds and [FEAT-0031](../FEAT-0031-v0111-project-neutral-legacy-fixture/README.md) records the complete 0.11.1 suite pass |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0058` | Immutable catalog, typed definitions, consumer ledger, and pure assessment resolver | [Issue #81](https://github.com/hasanmanzak/meAndAI/issues/81) | [TEST-0134](test-cases.md), [TEST-0135](test-cases.md); passed locally, in a PowerShell 7.4.2 Linux container, and hosted Ubuntu/Windows | `FIND-0165` and `FIND-0170` resolved | Complete |
| `SUBF-0059` | Capability-based repository test topology, recursive discovery, common infrastructure, and fixture isolation | [Issue #81](https://github.com/hasanmanzak/meAndAI/issues/81) | [TEST-0136](test-cases.md), [TEST-0137](test-cases.md), and [TEST-0138](test-cases.md); passed locally, with real links on both local hosts, and hosted Ubuntu/Windows | `FIND-0166` and `FIND-0172` resolved | Complete |
| `SUBF-0060` | Fresh-adoption semantic capability handoff | [Issue #81](https://github.com/hasanmanzak/meAndAI/issues/81) | [TEST-0139](test-cases.md); passed locally, in a PowerShell 7.4.2 Linux container, and hosted Ubuntu/Windows | `FIND-0167` and `FIND-0171` resolved | Complete |
| `SUBF-0061` | Existing-consumer update discovery, canonical proposal lifecycle, closure, and idempotency | [Issue #81](https://github.com/hasanmanzak/meAndAI/issues/81) | [TEST-0140](test-cases.md); passed locally, in a PowerShell 7.4.2 Linux container, and hosted Ubuntu/Windows | `FIND-0168`, `FIND-0169`, and `FIND-0171` resolved | Complete |

## Decisions and relationships

- Governing decision: [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Initial adoption lifecycle: [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md) / [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Consumer lifecycle: [FEAT-0023](../FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md) / [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
- Deterministic transition boundary: [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md) / [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
- Initial migration policy: [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md)
- Test-fixture baseline: [FEAT-0024](../FEAT-0024-v0101-parallel-windows-validation/README.md)
- Tracking and external publication authority: [issue #81](https://github.com/hasanmanzak/meAndAI/issues/81)

## Definition of Ready

- [x] Stable IDs and linked issue exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria are measurable.
- [x] Capability, catalog, definition, assessment, ledger, discovery, fixture,
      ownership, lifecycle, compatibility, and error contracts are explicit.
- [x] Consumers, entry points, dependencies, and immutable handoff are identified.
- [x] Numbered risks and [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) are recorded.
- [x] Four independently reviewable slices have a gate ledger.
- [x] Numbered success, negative, boundary, recovery, and idempotency scenarios
      and the verification approach are defined.
- [x] Test-code and baseline states are recorded before implementation.

## Acceptance criteria

1. The immutable release exposes one validated ordered capability catalog whose
   existing slug/blob entries cannot change within the compatible major line.
2. The framework supports the four declared capability types without treating
   semantic work as a deterministic migration or permanent updater-owned path.
3. The pure assessment boundary returns exactly `Conforming`,
   `NotApplicable`, `AdoptionRequired`, or `ReviewRequired`; only the first two
   can become terminal reviewed ledger evidence.
4. A fresh protocol adoption and an already adopted current consumer both
   discover the first pending semantic capability without broadening the
   initial-adoption content envelope.
5. A pre-framework consumer first receives its ordinary immutable update and
   then enters the same same-target capability discovery path without a
   source-version switch.
6. One unresolved immutable capability batch owns at most one canonical issue,
   branch, and draft semantic pull request. Exact reruns reuse it; ambiguous
   ownership fails closed.
7. Completion requires a reviewed semantic pull request, terminal default-
   branch ledger evidence, exact issue/PR/catalog links, branch-first cleanup,
   and issue-last evidence closure; rerunning completed state is a no-op.
8. `test-architecture` defines capability-based physical ownership,
   feature-based traceability, deterministic recursive discovery, shared
   infrastructure boundaries, per-suite processes, and fixture isolation.
9. This repository's canonical suites and fixtures conform to that definition
   while `tests/protocol.tests.ps1` remains the stable CI/CLI entry point.
10. [TEST-0134](test-cases.md), [TEST-0135](test-cases.md), [TEST-0136](test-cases.md), [TEST-0137](test-cases.md), [TEST-0138](test-cases.md), [TEST-0139](test-cases.md), and [TEST-0140](test-cases.md), focused suites, full validation, native
    compatibility, link checks, and bounded review pass with no unresolved
    `Blocking` finding.

## Verification approach

Add the pure catalog/ledger and discovery tests first and record the intended
red state. Implement `SUBF-0058`, then move one test capability at a time under
the recursive runner for `SUBF-0059`, preserving per-suite processes and exact
scenario evidence after every move. Implement fresh and existing-consumer
handoff only after the pure contracts pass. Run focused capability suites,
`tests/protocol.tests.ps1 -StructureOnly`, the `WindowsNative` profile, one
complete suite, one fresh-diff self-review per slice, and the single bounded
post-development project scan.

## Self-review

The four slice gates and one bounded post-development scan completed.

- `SUBF-0058`: catalog/type/order/blob, compatible-prefix, terminal ledger,
  four-outcome, and no-live-pin boundaries passed focused contract tests. The
  documentation audit found one incomplete immutable tuple description; the
  normative text now binds slug, definition path, type, and blob.
- `SUBF-0059`: recursive discovery and topology review found root/partial
  authority ordering, executable fixture mode, and stale active-path pointer
  gaps. The root runner now validates the exact authority shape, IDs, and owner
  set before every child; the shell fixture is pinned as `100755` with its
  original blob; active pointers use nested owners. Shared runtime duplication
  and suite-masquerading support names were also removed during the slice.
- `SUBF-0060` and `SUBF-0061`: two independent security reviews challenged
  reviewer trust, issue/comment and PR actor identity, fork heads, canonical
  issue/PR/manifest bytes, terminal-inventory ordering, checkout identity,
  exact base/handoff/review/merge/default-tree provenance, split tokens,
  closure evidence, reviewer ID reuse, and default-head races. Every finding
  was corrected and covered by negative [TEST-0139](test-cases.md)/[TEST-0140](test-cases.md) evidence; the
  final bounded review reported no blocker.
- The final documentation scan confirmed both fresh adoption and ordinary
  existing-consumer protocol-update discovery, immutable release/catalog/
  ledger boundaries, consumer ownership, and no premature merge or release
  claim. Deterministic and semantic post-merge credential authorities are now
  documented separately.
- The first complete suite exposed `FIND-0169`: the already-current consumer
  intentionally sent one same-target `Auto` capability discovery, while its
  legacy fixture still allowed only initial-adoption strategies and expected no
  workflow dispatch. The corrected fixture now proves one exact repository,
  ref, head, base, strategy, loss-acknowledgement, and correlation-bound
  dispatch while Git, secrets, adoption-PR lookup, and Codex remain unchanged.
  The focused shard passed in 165.4 seconds and the complete suite passed in
  1652.5 seconds.
- Draft [PR #82](https://github.com/hasanmanzak/meAndAI/pull/82)'s first two Ubuntu jobs exposed `FIND-0170`. The first parser
  correction isolated exact UTC parsing, but a matching PowerShell 7.4.2 Linux
  container proved the remaining cause: `ConvertFrom-Json` materializes the
  canonical JSON timestamp as `System.DateTime`, and the later direct string
  cast was culture-formatted. Import now converts runtime date values back to
  invariant UTC seconds before validation while retaining the final exact-byte
  equality gate. Canonical round-trip and noncanonical fraction, offset, and
  zone-negative cases pass on Windows PowerShell 5.1 and Linux PowerShell
  7.4.2.
- The corrected Linux catalog slice then exposed `FIND-0171` in the semantic
  lifecycle: `Write-Output -NoEnumerate` wrapped a scalar evidence string and
  a null fixture binding in `List<object>` values on PowerShell 7.4. Both
  property accessors now return the property value through a unary-comma
  boundary, which preserves scalar, empty-array, singleton-array, multi-array,
  and null shapes on both PowerShell hosts. Focused [TEST-0139](test-cases.md)/[TEST-0140](test-cases.md)
  pass on Windows PowerShell 5.1 and Linux PowerShell 7.4.2.
- Hosted Ubuntu then reached the later discovery slice and exposed
  `FIND-0172`: Linux PowerShell accepted `New-Item -ItemType Junction` without
  creating a path, but the test marked the fixture created and never attempted
  its real `SymbolicLink` fallback. The fixture now accepts an item type only
  after the link path exists. [TEST-0136](test-cases.md) passes with an actual junction on
  Windows and an actual symbolic link in Linux PowerShell 7.4.2.
- Replacement [run 29670698209](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209)
  passed on the exact `773a415` tree: hosted Ubuntu completed in 6 minutes 57
  seconds and hosted Windows completed in 31 minutes 26 seconds. This closes
  `FIND-0170` through `FIND-0172` without weakening their fail-closed guards.

### Finding register

Shared scope: FEAT-0032 implementation and its consumer lifecycle. Shared
owner: meAndAI protocol maintainers. Shared confidence: high. Tracking:
[issue #81](https://github.com/hasanmanzak/meAndAI/issues/81). Governing
decision: [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md).

| ID / title | Classification / disposition | Dependency | Priority / severity / impact rank | Evidence and impact rationale | Action / status | Links |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0165` - Capability identity tuple was under-specified | Documentation and immutable-contract defect / `Blocking` | None | `p1` / medium / high | The first normative wording did not bind the definition path even though catalog identity depended on it. Relocation could therefore be misread as compatible state. | Bind slug, definition path, type, and Git blob as the exact append-only tuple; the documentation and catalog contract now agree. / Resolved | `SUBF-0058`; [`TEST-0134`](test-cases.md); [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) |
| `FIND-0166` - Test authority and fixture provenance were incomplete | Test-topology and evidence-integrity defect / `Blocking` | None | `p1` / high / high | Review found that executable authority shape, scenario IDs, and discovered owners were not all established before every child path; relocated shell-fixture mode, active pointers, and support naming also lacked exact guards. Evidence could execute before its canonical authority was proven. | Validate authority shape, IDs, duplicate IDs, and exact owner inventory before every child; pin the shell fixture as `100755` with blob `7a1d8a42cc0492ff1511a31da6f44c389a3bf279`; use nested active owners; remove duplicated runtime and suite-like support names. / Resolved | `SUBF-0059`; [TEST-0136](test-cases.md), [TEST-0137](test-cases.md), and [TEST-0138](test-cases.md) |
| `FIND-0167` - Semantic handoff trust boundaries admitted ambiguous authority | Authorization and proposal-identity defect / `Blocking` | None | `p1` / high / high | Initial review did not prove every issue, comment, proposal, reviewer, permission, and head-repository identity through exact actor ID/login and canonical payload evidence. Token roles could be conflated and an untrusted actor could enter the handoff. | Split updater proposal authority from issue authority; require exact actor and reviewer identity, write-or-higher permission, same-repository head, and canonical issue, PR, and manifest bytes. Negative lifecycle cases fail closed. / Resolved | `SUBF-0060`; [`TEST-0139`](test-cases.md); `RISK-0143`; `RISK-0145` |
| `FIND-0168` - Completion provenance and cleanup were raceable | Lifecycle provenance, state-machine, and TOCTOU defect / `Blocking` | `FIND-0167` | `p1` / high / high | Finalization initially lacked one complete base-to-handoff-to-reviewed-head-to-merge-to-default-tree proof and sufficiently late live-head/tree rechecks. A raced state could otherwise authorize terminal inventory, branch deletion, or issue closure. | Require canonical inventory and closure evidence, reviewed ledger/manifest provenance, current default-tree containment, managed checkout identity, exact-head deletion, and fresh checks immediately before branch deletion and issue-last closure. / Resolved | `SUBF-0061`; [`TEST-0140`](test-cases.md); `RISK-0146`; `RISK-0150` |
| `FIND-0169` - Already-current capability dispatch regressed the legacy fixture | Compatibility and regression-fixture defect / `Blocking` | None | `p1` / medium / high | The first 1576.3-second complete suite reached [TEST-0113](../FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md)/[TEST-0130](../FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md) and rejected the intentional already-current `Auto` dispatch because the mock excluded `Auto` and required zero dispatches. This blocked acceptance criterion 10 and conflated protocol currency with capability conformance. | Accept `Auto` in the exact workflow mock and require one repository/ref/head/base-bound capability dispatch while preserving Git heads, secrets, adoption-PR lookup, and Codex no-op boundaries. The focused shard passed in 165.4 seconds and the complete suite passed in 1652.5 seconds. / Resolved | `SUBF-0061`; [TEST-0113](../FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md); [TEST-0130](../FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md); [`TEST-0140`](test-cases.md) |
| `FIND-0170` - UTC review timestamp parsing differed on PowerShell 7 | Cross-platform compatibility defect / `Blocking` | None | `p1` / medium / high | Draft [PR #82](https://github.com/hasanmanzak/meAndAI/pull/82)'s first [Ubuntu validation job](https://github.com/hasanmanzak/meAndAI/actions/runs/29669260878/job/88145246394) rejected the canonical timestamp. The first exact-parser correction still failed in [job 88146035959](https://github.com/hasanmanzak/meAndAI/actions/runs/29669560953/job/88146035959). A matching PowerShell 7.4.2 Linux container then proved that `ConvertFrom-Json` had materialized `reviewedAt` as `System.DateTime`; its direct string cast produced `07/19/2026 10:20:30`. Windows PowerShell 5.1 left the JSON value as a string, hiding the compatibility defect. | Keep the exact invariant parser and normalize runtime `DateTime`/`DateTimeOffset` values to canonical UTC seconds only at ledger import. Preserve final source-to-canonical byte equality so fractional seconds, offsets, and missing zones remain invalid. Focused positive/negative tests and replacement hosted [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209/job/88149004892)/[Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209/job/88149004887) validation passed. / Resolved | `SUBF-0058`; [TEST-0134](test-cases.md) and [TEST-0135](test-cases.md); [PowerShell 7.4 JSON conversion contract](https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/convertfrom-json?view=powershell-7.4); [PR #82](https://github.com/hasanmanzak/meAndAI/pull/82) |
| `FIND-0171` - Property accessors changed scalar and null shapes on PowerShell 7 | Cross-platform compatibility defect / `Blocking` | `FIND-0170` | `p1` / medium / high | After the catalog slice passed in the matching Linux container, the semantic lifecycle rejected reviewed scalar evidence as a `List<object>` and later treated a null fixture binding as a non-null collection. Both values came from `Write-Output -NoEnumerate` property accessors whose PowerShell 7.4 representation differed from Windows PowerShell 5.1. | Return property values through unary comma in both the lifecycle module and production runner. This preserves scalar, null, empty-array, singleton-array, and multi-array shapes without weakening evidence or binding validation. Focused lifecycle tests and replacement hosted [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209/job/88149004892)/[Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209/job/88149004887) validation passed. / Resolved | `SUBF-0060`, `SUBF-0061`; [TEST-0139](test-cases.md) and [TEST-0140](test-cases.md); [PR #82](https://github.com/hasanmanzak/meAndAI/pull/82) |
| `FIND-0172` - Linux junction fixture reported success without creating a link | Cross-platform test-fixture defect / `Blocking` | `FIND-0170`, `FIND-0171` | `p1` / medium / high | After the earlier Linux slices passed, [Ubuntu job 88147932798](https://github.com/hasanmanzak/meAndAI/actions/runs/29670294956/job/88147932798) reached [TEST-0136](test-cases.md) and reported that a linked capability path was accepted. Reproduction showed that Linux PowerShell returned from `New-Item -ItemType Junction` without an error or path; the fixture set `linkCreated` from call completion and therefore never created the supported symbolic-link fallback. Discovery had not received a linked path. | Set `linkCreated` only after `Test-Path` proves that the requested link exists, otherwise continue to `SymbolicLink`. Focused discovery and replacement hosted [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209/job/88149004892)/[Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209/job/88149004887) validation passed with real link fixtures. / Resolved | `SUBF-0059`; [`TEST-0136`](test-cases.md); [PR #82](https://github.com/hasanmanzak/meAndAI/pull/82) |

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Every subfeature review and the bounded post-development scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Issue, pull request, decision, tests, and related work cross-linked.
- [x] Applicable CI and review gates pass.

## Post-merge release evidence

[Issue #81](https://github.com/hasanmanzak/meAndAI/issues/81) and draft
[pull request #82](https://github.com/hasanmanzak/meAndAI/pull/82) are the
stable pre-merge authorities. Hosted PR validation passed on exact candidate
commit `773a415`. Exact merge commit, immutable `v0.12.0` release, branch
cleanup, and post-publication verification remain `Pending` until those facts
exist.
