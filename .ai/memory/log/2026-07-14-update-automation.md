# 2026-07-14 - Semi-Automatic Consumer Updates

## Scope

- Feature:
  [FEAT-0002](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md)
- Decision:
  [DEC-0003](../../../docs/decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Tracking:
  [issue #3](https://github.com/hasanmanzak/meAndAI/issues/3)
- Target protocol release: `v0.2.0`

## Durable decisions

- Submodule consumers adopting `v0.2.0` or later install the pinned,
  consumer-owned scheduled/manual update workflow during collision-safe
  adoption.
- The workflow proposes only canonical same-major tags in a draft pull request.
  It never approves or merges consumer work.
- A newer compatible release replaces an older pending proposal only after the
  replacement is created and fully verified.
- Supersession is replacement-first and compensated, not atomic across GitHub
  pull-request state and Git refs.
- Exactly one canonical ownership marker binds the consumer, target, protocol
  commit, and planned head. The pure validator is shared by planning and live
  pre-mutation checks.
- Branch creation and deletion use expected-state leases. Ambiguity, changed
  ownership, case drift, missing refs, origin mismatch, or concurrent mutation
  fails closed and preserves work.
- A branch left between push and pull-request creation requires the reviewed
  [interrupted-run recovery procedure](../../../docs/adoption.md#interrupted-run-recovery).

## Adoption impact

- Existing immutable `v0.1.0` consumers need one manual move to `v0.2.0`
  and one collision-safe installation of the workflow and scripts.
- New `v0.2.0` submodule consumers receive those assets during initial
  adoption.
- Private consumers must configure a read-only `MEANDAI_PROTOCOL_TOKEN` and
  allow Actions to create pull requests. Credentials are never stored here.
- Repository-reference consumers require a reviewed provider-specific
  compare-and-swap adapter or remain manual.

## Evidence and handoff

- Local Windows PowerShell 5.1 validation passed `TEST-0001` through
  `TEST-0017`, PowerShell AST parsing, and a real local Git lease smoke test.
- Ubuntu and Windows PowerShell 7 CI, delivery pull request, merge, and release
  tag remain publication gates at the time of this handoff.
- Continue from the canonical feature test evidence rather than reconstructing
  intent from chat history.
