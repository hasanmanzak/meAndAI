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

- Local Windows PowerShell 5.1 validation passed [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0008) and [TEST-0009](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), PowerShell AST parsing, and a real local Git lease smoke test.
- Ubuntu and Windows PowerShell 7 CI, delivery pull request, merge, and release
  tag remain publication gates at the time of this handoff.
- Continue from the canonical feature test evidence rather than reconstructing
  intent from chat history.
