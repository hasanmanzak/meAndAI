# 2026-07-18 - v0.11.1 Project-Neutral Legacy-Consumer Fixture

- Feature: [FEAT-0031](../../../docs/features/FEAT-0031-v0111-project-neutral-legacy-fixture/README.md)
- Tracking: [issue #79](https://github.com/hasanmanzak/meAndAI/issues/79)
- Pull request: [#80](https://github.com/hasanmanzak/meAndAI/pull/80)
- Target version: `0.11.1`

## Durable continuation

- Replace the named pre-engine regression fixture with the synthetic
  `tests/fixtures/legacy-pre-engine-consumer` fixture.
- Preserve the legacy protocol SHA and the exact [MIG-0001](../../../migrations/MIG-0001.json) recognition
  fragment; do not edit migration catalog bytes.
- [TEST-0125](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) must retain core-only unique [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md) failure, exact 13-path
  atomic success, and now directly prove a satisfied, unchanged second plan.
- [TEST-0133](../../../docs/features/FEAT-0031-v0111-project-neutral-legacy-fixture/test-cases.md) stays inside the existing adapter suite; no new validator or
  bootstrap framework is authorized.
- Protocol-owned issues retain historical traceability without embedding a
  consumer repository identity in canonical meAndAI content.

## Current evidence

- The test-first adapter run failed at the missing neutral fixture as expected;
  the sandboxed run also reproduced the known Windows Git signal-pipe ACL
  limitation.
- After fixture replacement, the unrestricted focused adapter suite passed,
  including [TEST-0125](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) and [TEST-0133](../../../docs/features/FEAT-0031-v0111-project-neutral-legacy-fixture/test-cases.md).
- The unrestricted complete protocol suite passed in 1593.1 seconds on Windows
  PowerShell 5.1; all discovered suites passed, including [TEST-0125](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) and
  [TEST-0133](../../../docs/features/FEAT-0031-v0111-project-neutral-legacy-fixture/test-cases.md).
- Bounded review is complete. Pull-request, hosted-check, merge, release, and
  branch-cleanup evidence remain pending.
