# FEAT-0032 Test Scenarios

Implementations: capability catalog and lifecycle suites under
`tests/capabilities/capability-adoption/`, test architecture suites under
`tests/capabilities/test-architecture/`, and the stable
[`tests/protocol.tests.ps1`](../../../tests/protocol.tests.ps1) runner.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0134` | `SUBF-0058` | Load valid and malformed ordered capability catalogs, typed immutable definitions, compatible predecessor catalogs, and consumer ledgers; vary slug, path, type, blob, order, prefix, duplicates, terminal state, and live-pin copies. | Only one canonical append-only catalog and exact consumer prefix are accepted; definition blobs and types are immutable; the ledger is not a protocol pin; every malformed or incompatible state fails closed. | Unit / contract / compatibility / negative | Automated | Capability catalog module fixture |
| `TEST-0135` | `SUBF-0058` | Assess applicable, inapplicable, conforming, nonconforming, and ambiguous repositories for each capability type and vary evidence and review identity. | The pure boundary returns exactly `Conforming`, `NotApplicable`, `AdoptionRequired`, or `ReviewRequired`; only reviewed `Conforming` and `NotApplicable` evidence may satisfy a ledger entry. | Unit / semantic contract / boundary | Automated | Capability assessment matrix |
| `TEST-0136` | `SUBF-0059` | Discover nested suites with mixed creation order and vary duplicate basenames, case collisions, unsafe relative paths, directory links/reparse points, support suffixes, parse failures, profile entries, and an empty capability root. | Canonical `*.tests.ps1` suites are returned once as normalized repository-relative paths in ordinal order; every ambiguous/unsafe state fails closed; support files are never canonical suites; partial profiles reference only discovered owners. | Unit / filesystem / cross-platform / negative | Automated | Test discovery module fixture |
| `TEST-0137` | `SUBF-0059` | Inspect the repository's nested suite owners, scenario authority, feature declarations, result records, and adapter/support relationships after capability moves. | Physical ownership is capability-based; every active `TEST-NNNN` has one feature declaration and one nested canonical owner/evidence kind; moved suites emit their exact owner and adapters are executed by one parent only. | Structural / traceability / regression | Automated | Test architecture and repository structure suite |
| `TEST-0138` | `SUBF-0059` | Run canonical suites independently and inspect infrastructure imports, process boundaries, capability-local fixtures, immutable shared fixtures, mutable reset state, and cleanup. | Common modules contain only shared runtime concerns; every suite uses a separate process; mocks and mutable fixtures cannot leak across capabilities or cases; the frozen legacy fixture remains byte-compatible. | Integration / isolation / regression | Automated | Focused suites plus topology assertions |
| `TEST-0139` | `SUBF-0060` | Complete fresh protocol adoption for a repository that is conforming, not applicable, requires test-architecture adoption, or is ambiguous; then run installed lifecycle discovery. | The initial content envelope remains unchanged. Terminal evidence creates no semantic proposal; open outcomes create one separately reviewed capability issue/manifest/draft bound to the immutable catalog; no semantic consumer path is automation-written. | Integration / adoption / ownership | Automated | Bootstrap, launcher, workflow, and capability-review fixtures |
| `TEST-0140` | `SUBF-0061` | Start from current, pre-framework, pending, completed, stale-definition, duplicate, drifted, and interrupted existing-consumer states; perform normal update discovery, semantic review completion, finalization, and exact reruns. | Old code first installs the framework through its ordinary update. The new lifecycle creates or reuses one canonical semantic issue and draft, blocks ambiguity, verifies terminal default-branch evidence before branch-first/issue-last closure, and becomes an exact no-op after completion. | Integration / update / recovery / idempotency | Automated | Protocol updater, capability-review adapter, and finalization fixtures |

## Required coverage

- Exact capability catalog, definition blob, type, order, and compatible
  append-only chain.
- Separate consumer capability ledger with terminal reviewed outcomes and no
  duplicated live protocol pin.
- All four assessment outcomes and invalid evidence/review variants.
- Recursive ordinal discovery, nested exact owners, unsafe/case/link failures,
  and explicit partial-profile mapping.
- Capability-first physical layout with feature-first canonical traceability.
- Separate suite processes, common-infrastructure dependency direction,
  capability-local fixtures, immutable sharing, mutable reset, and cleanup.
- Fresh-adoption post-completion assessment without broadening its semantic
  write envelope.
- Existing-consumer ordinary update handoff, one canonical issue/draft,
  reviewed completion, exact cleanup ordering, and rerun idempotency.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-19 | `37855c2` baseline | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 2.6 seconds before FEAT-0032 implementation; discovery is still root-only and the capability framework is absent |
| 2026-07-19 | working tree after scenario declaration | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Expected red: failed with exactly seven missing scenario-authority errors for `TEST-0134` through `TEST-0140`, proving that declared scenarios cannot pass before executable ownership is added |
| 2026-07-19 | reviewed working tree | Windows PowerShell 5.1 | Focused `capability-catalog.tests.ps1`, `capability-review.tests.ps1`, `test-discovery.tests.ps1`, and `test-architecture.tests.ps1` | Passed in 2.3, 3.0, 1.8, and 1.9 seconds; `TEST-0134` through `TEST-0140` emitted exact owner-bound evidence, including security-race negatives |
| 2026-07-19 | reviewed working tree | Windows PowerShell 5.1 / unrestricted local Git fixture | `quick-adoption.tests.ps1 -Shard ContractsPreflight` | Passed in 15.1 seconds after the restricted sandbox reproduced only the known Git-for-Windows `sh.exe` signal-pipe ACL error 5 |
| 2026-07-19 | reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 3.4 seconds after recursive discovery, exact authority, scenario-owner, fixture-mode, and documentation checks |
| 2026-07-19 | reviewed working tree | Windows PowerShell 5.1 / unrestricted local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -ValidationProfile WindowsNative` | Passed in 412.8 seconds after the restricted sandbox reproduced only the known Git-for-Windows `sh.exe` signal-pipe ACL error 5 |
| 2026-07-19 | first complete-suite review | Windows PowerShell 5.1 / unrestricted local Git fixture | `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Expected red after 1576.3 seconds: all earlier owners passed, then `TEST-0113`/`TEST-0130` found the stale already-current zero-dispatch fixture expectation recorded as `FIND-0169` |
| 2026-07-19 | corrected working tree | Windows PowerShell 5.1 / unrestricted local Git fixture | `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard AdoptionLifecycle` | Passed in 165.4 seconds; the exact same-target `Auto` capability dispatch and Git/secret/PR-lookup/Codex no-op boundaries were proven |
| 2026-07-19 | corrected working tree | Windows PowerShell 5.1 / unrestricted local Git fixture | `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 1652.5 seconds with exit code 0; every recursively discovered suite and scenario owner, including `TEST-0134` through `TEST-0140`, passed |
| 2026-07-19 | working tree after finding and evidence closure | Windows PowerShell 5.1 | `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 3.7 seconds; final documentation, finding, recursive authority, scenario-owner, and fixture-mode contracts passed |
| 2026-07-19 | working tree after finding and evidence closure | Windows PowerShell 5.1 | Parse every `.ps1`, `.psm1`, and `.psd1`; `git diff --check` | Passed; all PowerShell sources parsed and no whitespace error was reported |
| 2026-07-19 | draft PR #82 commit `e5c90b6` | Ubuntu / PowerShell 7 hosted expected red | [Protocol validation job 88145246394](https://github.com/hasanmanzak/meAndAI/actions/runs/29669260878/job/88145246394) | `FIND-0170` reproduced: workflow lint and YAML parsing passed, then the capability catalog suite rejected the otherwise canonical UTC-seconds review timestamp before emitting `TEST-0134`/`TEST-0135` evidence |
| 2026-07-19 | `f3737ec` | Ubuntu / PowerShell 7 hosted expected red | [Protocol validation job 88146035959](https://github.com/hasanmanzak/meAndAI/actions/runs/29669560953/job/88146035959) | The exact parser correction passed direct parsing but `TEST-0134` still failed during ledger import, narrowing `FIND-0170` to JSON round-trip materialization |
| 2026-07-19 | `FIND-0170` corrected working tree | Official PowerShell Linux container / PowerShell 7.4.2 | Focused `capability-catalog.tests.ps1` after reproducing the raw `System.DateTime` conversion | Passed in 3.0 seconds; canonical ledger round-trip retained exact UTC text and fractional-second, explicit-offset, and missing-zone variants all failed closed |
| 2026-07-19 | `FIND-0170` corrected working tree | Windows PowerShell 5.1 | Focused `capability-catalog.tests.ps1` | Passed in 1.7 seconds; canonical round-trip and the same timestamp-negative matrix preserve the Windows PowerShell contract; replacement Ubuntu evidence pending |
| 2026-07-19 | `FIND-0171` corrected working tree | Official PowerShell Linux container / PowerShell 7.4.2 | Focused `capability-review.tests.ps1` after reproducing scalar evidence and null binding wrapper changes | Passed in 6.2 seconds; `TEST-0139`/`TEST-0140` preserved reviewed evidence, fixture inventory, source-only handoff, and finalization boundaries |
| 2026-07-19 | `FIND-0171` corrected working tree | Windows PowerShell 5.1 | Focused `capability-review.tests.ps1` | Passed in 3.1 seconds with the same scalar, array, null, lifecycle, and production-runner contracts |
