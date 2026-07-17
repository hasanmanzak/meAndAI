# 2026-07-17 - v0.9.6 GitHub CLI Prerequisite Gate

## Scope

- [FEAT-0021](../../../docs/features/FEAT-0021-v096-github-cli-prerequisite/README.md),
  `BUG-0009`, and [issue #59](https://github.com/hasanmanzak/meAndAI/issues/59)
  own this bounded compatibility correction.
- Require GitHub CLI `2.82.1` or newer at the first quick-adoption prerequisite
  boundary and reject missing, malformed, ambiguous, leading-zero, or older
  version output before authentication or state mutation.
- Preserve the source-only launcher boundary, exact-release checks, credentials,
  lifecycle workflow, local Codex execution, and maintainer-owned merge.

## Current evidence

- [`TEST-0107`](../../../docs/features/FEAT-0021-v096-github-cli-prerequisite/test-cases.md)
  covers older, malformed, ambiguous, leading-zero, exact-floor, later, and
  multi-digit version cases plus side-effect ordering.
- The expected-red run produced the seven intended version-boundary failures.
  The focused green quick-adoption suite passed on Windows PowerShell 5.1 in
  362.5 seconds after an ACL-constrained sandbox retry was rerun outside that
  environment.
- The initial full-suite attempt exposed `FIND-0152`: three escaped v0.9.5 test
  fixture pins had not advanced with ordinary-text pins. The exact three-line
  correction and budgeted confirmation left no unresolved `Blocking` finding.
- The final complete repository suite passed in 535.1 seconds, including all
  discovered child suites, all 35 quick-adoption scenarios, `TEST-0107`, and
  streaming `TEST-0105`/`TEST-0106`.
- [Pull request #60](https://github.com/hasanmanzak/meAndAI/pull/60) owns the
  review branch and links the feature, tests, decision, issue, findings, and
  local evidence. Merge, immutable-release, and hosted-check evidence remain
  pending until those facts exist.

## Continuation

Wait for hosted checks and maintainer review on PR #60. Fix only new failed
evidence; do not repeat the unchanged local suite. The retained
[Derdini PR #1](https://github.com/hasanmanzak/Derdini/pull/1) continues to
target `v0.9.2`; it must not be retargeted while resuming with the newer
launcher.
