# 2026-07-17 - v0.10.0 Idempotent Consumer Lifecycle

## Current state

- [FEAT-0023 / BUG-0011](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md)
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

## Verification authority

- [TEST-0111 through TEST-0114](../../../docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md)
  own automatic tracking, legacy finalization, repeat-launch routing, and
  version-neutral consumer evidence.
- The feature record owns local focused/full-suite and bounded-review evidence.
- This handoff does not predict a merge commit, tag target, release, or hosted
  check result. Those facts become authoritative only in issue #63 and GitHub
  Releases after publication.

## Resume rule

If delivery is still open, continue from issue #63 and the FEAT-0023 DoD. Do
not add a second consumer reconciliation step or expand the legacy bridge. If
publication is complete, treat the immutable v0.10.0 release plus issue #63 as
the external authority and begin new work under a new tracked feature.
