# 2026-07-17 - v0.10.0 Idempotent Consumer Lifecycle

## Current state

- [FEAT-0023](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md) and [BUG-0011](https://github.com/hasanmanzak/meAndAI/issues/63)
  and [DEC-0017](../../../docs/decisions/DEC-0017-idempotent-consumer-lifecycle.md)
  define the delivery.
- [Issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) owns the external
  pull-request, merge, release, and post-publication evidence.
- The scheduled/manual updater creates or reuses its exact issue and missing
  labels, writes reciprocal issue/PR links, and finalizes only after the exact
  owned branch converges.
- The current launcher is idempotent for an exact installation, dispatches the
  preserved installed updater for a complete older same-major installation,
  and fails before mutation for unsupported or ambiguous states.
- The consumer submodule gitlink and its checked-out `.ai/protocol/VERSION` are
  the sole live pin. Consumer-owned records resolve them dynamically.
- One bounded bridge repairs only an immutable-release-verified installing
  update from the legacy workflow; this is not a general migration framework.
- This release's prospective template rule did not prove every older consumer
  shape. [FEAT-0026](../../../docs/features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md)
  later defines release-declared, state-based migrations and the generic
  pre-engine capability handoff without changing [FEAT-0023](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md)'s historical scope.

## Verification authority

- [TEST-0111](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md#test-0111), [TEST-0112](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md#test-0112), [TEST-0113](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md#test-0113), and [TEST-0114](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md#test-0114)
  own automatic tracking, legacy finalization, repeat-launch routing, and
  version-neutral consumer evidence.
- The feature record owns local focused/full-suite and bounded-review evidence.
- This handoff does not predict a merge commit, tag target, release, or hosted
  check result. Those facts become authoritative only in [issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) and GitHub
  Releases after publication.

## Resume rule

If delivery is still open, continue from [issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) and the [FEAT-0023](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md) DoD. Do
not expand its legacy finalization bridge. If publication is complete, treat
the immutable v0.10.0 release plus [issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) as the external authority; generic
consumer-state transition work belongs to [FEAT-0026](../../../docs/features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md) and [DEC-0018](../../../docs/decisions/DEC-0018-release-declared-consumer-migrations.md).
