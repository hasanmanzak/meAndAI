# 2026-07-18 - v0.10.4 Hosted Runner-Minute Efficiency

## Scope

- [FEAT-0027](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/README.md)
- [DEC-0019](../../../docs/decisions/DEC-0019-hosted-runner-efficiency.md)
- [Issue #72](https://github.com/hasanmanzak/meAndAI/issues/72)

## Durable decisions

- GitHub Actions efficiency means preserving declared evidence with the least
  total hosted runner consumption; lower wall-clock latency alone is not proof.
- Linux remains the canonical full-suite authority on every ordinary event.
- Exactly one actual Windows job retains the stable
  `Validate on windows-latest` identity. It runs `WindowsNative` for complete,
  platform-neutral diffs and `Full` for sensitive or ambiguous evidence.
- The repository-owned selector reads exact checked-out Git commits, disables
  rename detection, caps observable paths at 300, and fails empty, unavailable,
  malformed, manual, merge-queue, PowerShell, command-wrapper, workflow, and
  migration cases to `Full`.
- `WindowsNative` covers the existing PowerShell 5.1 launcher, `.cmd`, native
  sandbox, linked/reparse containment, streaming, and process-tree cleanup
  contracts. It emits compatibility-only evidence and cannot claim canonical
  scenario completion.
- Seven focused quick-adoption shards remain local diagnostic entry points;
  they no longer create seven hosted Windows runners and an aggregate runner.
- Only a newer run for the same pull request may cancel older evidence. Main,
  manual, merge-queue, and publication runs use independent concurrency keys.

## Evidence state

- [TEST-0123](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md) selector fixtures and [TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md) structure validation pass.
- The PowerShell 5.1 `WindowsNative` profile passed in 187.1 seconds outside
  the restricted local Git signal-pipe sandbox.
- The complete PowerShell 5.1 suite passed in 577.7 seconds outside the
  restricted local Git signal-pipe sandbox. The bounded fresh-diff review
  found no unresolved blocking finding.
- The checksummed actionlint 1.7.12 Windows binary accepted both workflow
  definitions before publication.
- Hosted checks, merge, branch cleanup, immutable release, and
  post-publication evidence remain external completion gates.

## Continuation

Publish the converged branch once. [Issue #72](https://github.com/hasanmanzak/meAndAI/issues/72) owns external delivery facts
after they exist.
