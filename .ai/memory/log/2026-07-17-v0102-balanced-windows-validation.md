# 2026-07-17 - v0.10.2 Balanced Windows Validation

## Canonical records

- Feature: [FEAT-0025](../../../docs/features/FEAT-0025-v0102-balanced-windows-validation/README.md)
- Tests: [TEST-0117 and TEST-0118](../../../docs/features/FEAT-0025-v0102-balanced-windows-validation/test-cases.md)
- Tracking and post-publication authority: [issue #67](https://github.com/hasanmanzak/meAndAI/issues/67)

## Durable facts

- The stable `Validate on windows-latest` aggregate still requires Windows
  base validation and every compatibility matrix child.
- The former monolithic `IntegrityFailures` child is four semantic shards:
  completed graph, manifest/issue, Codex failure, and metadata/credential.
- Every partial integrity process creates its own completed-adoption baseline;
  `Shard=All` retains the existing canonical state sequence and is the only
  route allowed to emit canonical scenario evidence.
- Explicit `verify_post_publication=true` dispatch runs only the independent
  read-only verifier. Pull requests, pushes, schedules, and ordinary manual
  dispatches retain normal validation.
- Expected-red structure evidence failed only the intended new shard and event
  contracts. The corrected structure and all four focused PowerShell 5.1
  shards passed in 40.4, 81.2, 105.8, and 76.5 seconds.
- Durations are observations, not gates. Issue #67 owns hosted ordinary-CI,
  immutable-release, exact merge, branch deletion, and post-publication proof.

## Continuation

If delivery is still open, continue from issue #67 and the FEAT-0025 DoD. Do
not broaden this work into production-launcher refactoring, mutable fixture
sharing, a test scheduler, or reduced PowerShell 5.1 coverage.
