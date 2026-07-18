# DEC-0019 - Minimize Hosted Runner Consumption Without Weakening Evidence

- Classification: Decision
- Status: Accepted
- Date: 2026-07-18
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0027](../features/FEAT-0027-v0104-runner-minute-efficiency/README.md)
- Related decisions: [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), and [DEC-0015](DEC-0015-event-triggered-stability-cycles.md)
- Supersedes: the hosted seven-child Windows matrix and aggregate topology of
  [FEAT-0025](../features/FEAT-0025-v0102-balanced-windows-validation/README.md),
  without superseding its historical evidence

## Context

The Linux full suite is the canonical executable-scenario authority. Windows
exists to prove PowerShell 5.1 and native launcher behavior. The current
workflow nevertheless starts separate Windows jobs for a base profile and
seven quick-adoption groups, then starts Ubuntu solely to aggregate their
result. This optimizes elapsed critical path but repeats runner setup and
platform-neutral integration work on every change.

Workflow-level path filters are not a safe basis for a stable required check:
a filtered workflow may have no check result for the pull request. A separate
conditional workflow also cannot contribute reliably to one always-required
cross-workflow aggregate. The efficient boundary must therefore live inside
one always-present Windows job.

## Decision

Ordinary repository validation uses exactly one Windows runner job named
`Validate on windows-latest`. After checkout with sufficient Git history, a
pure repository script selects one of two profiles:

1. `WindowsNative` for a complete, unambiguous diff containing no declared
   Windows/PowerShell-sensitive path; or
2. `Full` for sensitive, manual, merge-queue, missing, malformed, empty,
   oversized, or otherwise ambiguous evidence.

Sensitive paths include PowerShell script/module/data files, Windows command
wrappers, workflow YAML, and migration JSON. Diff classification disables
rename detection so both sides of a move are evaluated. The selector has no
network, GitHub mutation, or workflow authority and returns only the semantic
profile name.

`WindowsNative` reuses existing quick-adoption contracts that exercise
`.cmd`/`ComSpec`, native Codex sandbox fallback and rejection, process-tree
cancellation, and linked/reparse containment. It emits compatibility-only
evidence. `Full` executes every canonical suite once under Windows PowerShell
5.1. Linux continues to execute the canonical full suite on every ordinary
event. The explicit post-publication dispatch skips both ordinary jobs and
runs only its verifier.

Concurrency groups include the workflow and pull-request identity. Automatic
cancellation applies only to superseded runs for the same pull request. Main,
manual, merge-queue, and publication runs use unique identities and cannot
cancel each other.

## Consequences

- Ordinary validation starts one Windows runner instead of a base job, seven
  matrix children, and an aggregate runner.
- Documentation/governance changes retain native compatibility evidence
  without paying for complete duplicated Windows execution.
- Sensitive and ambiguous changes trade matrix wall-clock speed for lower
  total runner/setup consumption by executing the full suite serially once.
- The stable Windows check name remains available without a conditional
  workflow or duplicate check identity.
- Focused shard entry points remain useful locally for diagnosis but no longer
  define hosted orchestration.
- Workflow changes must report coverage mapping and total job/runner
  observations; shorter elapsed time alone is not efficiency evidence.

## Alternatives considered

- Keep the seven-job matrix: rejected because it optimizes wall time while
  repeating hosted setup and portable work.
- Add a path-filtered second workflow: rejected because conditional check
  presence and cross-workflow aggregation are unsafe for a stable required
  gate and may duplicate native plus full execution.
- Remove Windows entirely: rejected because Linux cannot prove PowerShell 5.1,
  `.cmd`, native sandbox, Job Object/process cleanup, or junction semantics.
- Always run the serial full Windows suite: rejected because platform-neutral
  changes do not justify complete duplicate coverage.
- Add a scheduler or self-hosted coordinator: rejected as unnecessary
  infrastructure for an event-triggered protocol repository.

## Review condition

Review if Windows PowerShell 5.1 support is removed, GitHub provides a reliable
conditional required-check result or cross-workflow aggregate, the native
profile no longer covers every Windows-only production branch, or measured
full-suite runner consumption becomes materially worse than a proven
single-runner alternative.
