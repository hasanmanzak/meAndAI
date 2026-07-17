# 2026-07-17 - v0.10.3 v0.9.2 Live-Pin Migration

## Scope

- [FEAT-0026 / BUG-0012](../../../docs/features/FEAT-0026-v0103-v092-live-pin-migration/README.md)
- [DEC-0018](../../../docs/decisions/DEC-0018-bounded-v092-live-pin-migration.md)
- [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69)

## Durable decisions

- The first proposal created by immutable v0.9.2 updater code cannot execute a
  migration introduced by its target release. Do not claim same-PR retroactive
  repair.
- The compatibility bridge is an explicit local launcher mode, not recurring
  updater authority. It verifies the exact v0.9.2 installation and recognizes
  only eight known current-authority fragments.
- All eight outputs are planned before writing. Unknown, partial, duplicated,
  mixed, linked, or non-UTF-8 state fails closed; an immediate all-neutral
  rerun is a no-op.
- Dated adoption and update facts remain historical evidence. Active
  instructions, memory, decisions, indexes, and tests derive current identity
  from the consumer gitlink and its checked-out `VERSION`.

## Evidence

- [TEST-0119 and TEST-0120](../../../docs/features/FEAT-0026-v0103-v092-live-pin-migration/test-cases.md)
  own the historical positive, idempotent, preservation, and zero-write
  negative evidence.
- The focused Windows PowerShell 5.1 black-box test passed on the working tree
  in 55.8 seconds after the bounded review corrections. The negative matrix
  covers the exact unsupported identities and content states declared by
  TEST-0120, and the positive route uses an independent byte oracle.
- The complete Windows PowerShell 5.1 repository suite passed every discovered
  contract and scenario in 561.4 seconds.

## Continuation

Complete hosted checks, merge, exact branch cleanup, immutable v0.10.3 release,
launcher-asset verification, and post-publication evidence. Record only facts
after they exist.
