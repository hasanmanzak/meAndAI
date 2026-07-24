# 2026-07-19 - v0.12.0 Capability Framework and Test Architecture

- Feature: [FEAT-0032](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md)
- Decision: [DEC-0022](../../../docs/decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Tracking: [issue #81](https://github.com/hasanmanzak/meAndAI/issues/81)
- Pull request: [#82](https://github.com/hasanmanzak/meAndAI/pull/82)
- Target version: `0.12.0`

## Durable continuation

- The ordered immutable release catalog in `capabilities/index.json` declares
  reusable repository practices separately from deterministic consumer
  migrations. Consumer terminal evidence lives in the separate
  `.ai/meandai-capabilities-state.json` ledger and is not another protocol pin.
- `test-architecture` is the first semantic capability. Tests are physically
  capability-owned, scenarios remain feature-owned, full discovery is
  recursive and ordinal, shared code is limited to generic infrastructure,
  suites execute in separate processes, and mutable fixtures stay local to
  their owning capability.
- Fresh-adoption completion, already-current discovery, and normal
  existing-consumer protocol-update completion converge on the same target
  catalog. Pre-framework code first installs the ordinary updater; no
  source-version switch grants old code the new semantic authority.
- Open semantic outcomes reuse one exact issue, branch, transient manifest,
  and draft pull request. Maintainer authorization, exact PR-tree ledger
  provenance, default-branch containment, and manifest removal gate
  branch-first, issue-last finalization.
- The initial-adoption managed content envelope and deterministic updater
  managed paths remain unchanged; automation never reorganizes consumer tests
  or other semantic paths.

## Current evidence

- [TEST-0134](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0135](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0136](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0137](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0138](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0139](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), and [TEST-0140](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) have executable capability-owned suites and
  focused catalog, discovery, topology, lifecycle, and workflow evidence.
- The unrestricted Windows-native profile passed in 412.8 seconds. The first
  complete suite then found the stale already-current zero-dispatch fixture
  expectation after 1576.3 seconds; its exact `Auto` dispatch correction passed
  the focused adoption-lifecycle shard in 165.4 seconds and the complete suite
  passed in 1652.5 seconds with every recursively discovered owner green.
- Draft [PR #82](https://github.com/hasanmanzak/meAndAI/pull/82)'s first two Ubuntu jobs found and narrowed [FIND-0170](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md). The
  exact UTC parser was not the final failing boundary: PowerShell 7.4.2
  `ConvertFrom-Json` materialized canonical `reviewedAt` JSON as
  `System.DateTime`, then a direct string cast applied culture formatting.
  Ledger import now restores runtime date values to invariant UTC seconds and
  still requires exact source-to-canonical byte equality. Canonical round-trip
  and fraction/offset/zone negatives pass on Windows PowerShell 5.1 and the
  matching Linux PowerShell 7.4.2 container.
- The corrected Linux catalog slice then exposed [FIND-0171](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md): both shared
  property accessors used `Write-Output -NoEnumerate`, which represented scalar
  evidence and a null fixture binding as `List<object>` values on PowerShell
  7.4. They now return through unary comma, preserving scalar, null, empty,
  singleton, and multi-value shapes on Windows PowerShell 5.1 and PowerShell
  7.4.2. Focused [TEST-0139](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md)/[TEST-0140](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) pass on both hosts.
- Hosted Ubuntu then reached [TEST-0136](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) and exposed [FIND-0172](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md): Linux
  PowerShell returned from `New-Item -ItemType Junction` without creating a
  path, while the fixture treated call completion as link creation and skipped
  its `SymbolicLink` fallback. The fixture now requires the link path to exist
  before accepting an item type. Focused discovery passes with an actual link
  on Windows PowerShell 5.1 and Linux PowerShell 7.4.2.
- Replacement hosted run 29670698209 passed on exact candidate commit
  `773a415`: Ubuntu completed in 6 minutes 57 seconds and Windows completed in
  31 minutes 26 seconds. [FIND-0170](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md), [FIND-0171](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md), and [FIND-0172](../../../docs/features/FEAT-0032-general-capability-test-architecture/README.md) are resolved.
- Windows Git-heavy focused tests may require an unrestricted rerun when the
  sandbox reproduces the known `sh.exe` signal-pipe ACL error; this is a harness
  boundary, not product evidence.
- Draft [pull request #82](https://github.com/hasanmanzak/meAndAI/pull/82) exists and its hosted candidate checks passed. Merge,
  immutable release, and post-publication evidence remain pending until those
  facts exist.
