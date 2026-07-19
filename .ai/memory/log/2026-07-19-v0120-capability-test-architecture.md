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

- `TEST-0134` through `TEST-0140` have executable capability-owned suites and
  focused catalog, discovery, topology, lifecycle, and workflow evidence.
- The unrestricted Windows-native profile passed in 412.8 seconds. The first
  complete suite then found the stale already-current zero-dispatch fixture
  expectation after 1576.3 seconds; its exact `Auto` dispatch correction passed
  the focused adoption-lifecycle shard in 165.4 seconds and the complete suite
  passed in 1652.5 seconds with every recursively discovered owner green.
- Draft PR #82's first Ubuntu job found `FIND-0170`: the UTC review timestamp
  exact format was accepted by Windows PowerShell 5.1 but rejected by
  PowerShell 7 before capability-catalog evidence. The parser now uses quoted
  UTC literals, a strongly typed `DateTimeOffset` result, and universal
  adjustment; focused local evidence is green and replacement hosted
  confirmation is pending.
- Windows Git-heavy focused tests may require an unrestricted rerun when the
  sandbox reproduces the known `sh.exe` signal-pipe ACL error; this is a harness
  boundary, not product evidence.
- Draft pull request #82 exists. Hosted-check, merge, immutable release, and
  post-publication evidence remain pending until those facts exist.
