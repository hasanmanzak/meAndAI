# FEAT-0028 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0125` | `SUBF-0052` | Start from a catalogless, ledgerless Derdini-shaped pre-engine consumer. Compare a core-only target tree with the production current-launcher proposal containing the target gitlink, target-different updater assets, `MIG-0001` outputs, and ledger; run the real pre-migration consumer validator and rerun the planner. | Core-only tree fails; the one atomic schema-2 proposal has the exact staged path/blob set and passes the real validator; rerun is an exact no-op. No source version or consumer name controls planning. | Integration / regression / compatibility / idempotency | Passing locally | Focused atomic-recovery fixture plus `tests/protocol-update-adapter.tests.ps1` |
| `TEST-0126` | `SUBF-0051`, `SUBF-0052` | Vary target release inventory, isolated consumer/protocol clone identity, captured/default-head movement, interruption cleanup, catalog/ledger capability boundaries, local authentication, and legacy schema-1 draft ownership/tracking/path/blob/head/branch state. | Requested target stays fixed; only the captured base is planned; maintainer checkout, default branch, credential files, and stored Actions secret values are untouched; catalog/ledger ambiguity blocks; an exact unbound draft is cleanup-only and is retired only after a validated replacement, while every ambiguous variant remains unchanged. | Contract / integration / negative / race / recovery | Passing locally | `tests/quick-adoption.tests.ps1`, `tests/protocol-update.tests.ps1`, `tests/protocol-update-adapter.tests.ps1`, and `tests/managed-merge-finalization.tests.ps1` |

## Required coverage

- Target release and source checkout exact identity.
- Catalogless-before-first-catalog and catalog-removal/ledger negative cases.
- One atomic proposal and real consumer validator evidence.
- Existing engine-era update and finalizer regressions.
- Isolated clone exact target/base identity, interruption cleanup, and remote
  default-head drift rejection.
- No default-branch/worktree mutation and no stored secret-value reads.
- Legacy unbound exact qualification, ambiguity rejection, and
  replacement-first cleanup without a synthetic historical issue.

## Evidence

| Date | Environment | Command / scope | Result |
| --- | --- | --- | --- |
| 2026-07-18 | Windows PowerShell 5.1, unrestricted local Git fixture | `tests/protocol-update-adapter.tests.ps1` | Passed; frozen Derdini validator blob `b4e5067ac409bb2ffc153b5b8ba867ce3ae46aab`, core-only unique `TEST-0001` failure, atomic exact 13-path proposal green |
| 2026-07-18 | Windows PowerShell 5.1 | `tests/quick-adoption.tests.ps1 -Shard CurrentLauncherRecovery` | Passed; exact clone identities, target adapter handoff, environment/worktree preservation, and cleanup variants |
| 2026-07-18 | Windows PowerShell 5.1 | `tests/managed-merge-finalization.tests.ps1` | Passed; schema-2 `-recovery` branch finalizes and cleans its exact issue/branch |
| 2026-07-18 | Windows PowerShell 5.1, unrestricted local Git fixture | `tests/protocol.tests.ps1` | Complete discovered suite passed in 589.1 seconds; canonical output includes `TEST-0125` and `TEST-0126` |
| 2026-07-18 | Bounded fresh-diff review | Initial review plus exact correction re-review | Final result: no unresolved Blocking/High finding |
