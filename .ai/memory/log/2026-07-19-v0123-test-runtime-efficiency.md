# 2026-07-19 - v0.12.3 Test Runtime Efficiency Handoff

- Feature: [FEAT-0035](../../../docs/features/FEAT-0035-test-runtime-efficiency/README.md)
- Decisions: [DEC-0019](../../../docs/decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../../docs/decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Tracking and external publication authority: [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87)
- Delivery pull request: `Pending`; record through [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) after creation
- Target version: `0.12.3`

## Durable continuation

- [FEAT-0035](../../../docs/features/FEAT-0035-test-runtime-efficiency/README.md) is `Ready`; no production or executable-test implementation has
  started. [TEST-0144](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0144), [TEST-0145](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0145), and [TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) are the required test-first
  scenarios and must receive executable ownership before implementation.
- Preserve every active scenario ID and declared variant. Change the evidence
  level, not the behavior inventory: deterministic combinations belong in
  production-owned in-process contracts, injected boundaries must retain exact
  types/errors/ordering, and representative real Git/launcher slices remain
  mandatory for material integration, security, recovery, TOCTOU, credential,
  path/link, process, Codex, and native-Windows evidence.
- Keep one hosted Ubuntu job and one hosted Windows job. Do not restore a
  matrix, aggregate runner, reusable-workflow fan-out, or any other
  wall-clock-only optimization that increases total runner consumption.
- Hosted Linux 2 minutes and hosted Windows 3 minutes are soft optimization
  goals. They are observations, not timeout ceilings or pass/fail thresholds.
  Existing ordinary workflow execution and justified reruns continue normally.
- The stable runner should report exact suite duration without changing child
  scenario authority. Expensive-boundary observations must remain tied to an
  exact owner/case inventory and cannot become production behavior.
- Share only fingerprinted immutable fixture baselines. Every mutable scenario
  receives a fresh verified copy and remains capability-local.

## Environment and baseline handoff

- Repository `main` was synchronized to [`3f1072d`](https://github.com/hasanmanzak/meAndAI/commit/3f1072da05636ab428430954dbf5dc5f31f9cc6b) (`v0.12.2`) before planning.
- This machine verified Windows PowerShell 5.1.19041.7548, Windows PowerShell
  7.6.3, WSL2 Ubuntu 24.04.1, Linux PowerShell 7.6.3, Git 2.43.0, and repository
  access.
- The repository is temporarily public so ordinary GitHub-hosted standard
  validation can continue without private-minute consumption. Returning it to
  private is maintainer-owned operational work after the optimization.
- Existing authoritative baselines: hosted `v0.12.0` Ubuntu 6m57s and Windows
  31m26s; local `v0.12.2` Windows PowerShell 5.1 full validation 1609.5s.
- A WSL ext4 temporary-clone hotspot measurement exceeded its 15-minute outer
  diagnostic budget: capabilities-bootstrap completed and quick-adoption was
  still active at about 10m28s. The exact remaining process group and temp
  clone were removed. Do not use this machine for the iterative optimization
  loop; refresh a same-commit baseline on the stronger computer.

## Next action on the stronger computer

1. Fetch and switch to `codex/feat-0035-test-runtime-efficiency`.
2. Confirm [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) and this feature record still satisfy Gate 1.
3. Capture same-commit per-suite and expensive-boundary baselines without a
   short outer measurement timeout.
4. Add expected-red executable ownership for [TEST-0144](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0144) and implement
   [SUBF-0064](../../../docs/features/FEAT-0035-test-runtime-efficiency/README.md#subf-0064); run its focused tests and fresh-diff review before [SUBF-0065](../../../docs/features/FEAT-0035-test-runtime-efficiency/README.md#subf-0065).
5. Continue the dependency-ordered slices and record exact evidence in the
   feature ledger. Do not open a pull request until local convergence.
