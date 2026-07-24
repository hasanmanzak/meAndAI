# 2026-07-20 - v0.12.5 Created-Issue Convergence Handoff

## Status

- Feature: [FEAT-0036](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md)
- Delivery authority: [issue #89](https://github.com/hasanmanzak/meAndAI/issues/89)
- Candidate version: `0.12.5`
- State: focused implementation, self-review, and local convergence evidence
  are complete; PR, hosted checks, merge, immutable release, successful Derdini
  replay, and lifecycle cleanup remain pending.

## Live evidence

- Immutable v0.12.4 targets
  `edf443744e3a72bcc951008bf1b3ba4727104a27` and contains exactly the verified
  launcher and module-bundle assets.
- Its first Derdini replay repaired the exact quote-stripped [issue #7](https://github.com/hasanmanzak/Derdini/issues/7) and
  created canonical v0.12.4 [issue #8](https://github.com/hasanmanzak/Derdini/issues/8), but then stopped before branch or PR
  publication with `The canonical protocol-update issue did not converge after
  creation.`
- A fresh GitHub read proved [issue #8](https://github.com/hasanmanzak/Derdini/issues/8) had the exact title, marker, body, state,
  protocol commit, migration-plan digest, and repository identity. The failure
  was the immediate eventually consistent all-issues inventory, not malformed
  transport or failed creation.

## Candidate correction

- [BUG-0021](https://github.com/hasanmanzak/meAndAI/issues/89) / [FIND-0197](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md) captures the false convergence failure.
- A successful issue POST must return one positive issue number. The updater
  then performs a direct idempotent GET for that identity and verifies exact
  canonical marker, title, normalized body, open state, nonempty response
  author, and non-PR kind. It does not equate the updater PAT actor with the
  separate `ISSUE_TOKEN` actor used by hosted workflows.
- The all-issues inventory remains a visible duplicate/race detector. Zero
  immediate list matches may use the exact direct identity; more than one match
  or one different identity fails closed.
- The fixture can hide a created issue from list inventory until its direct
  identity is read, so the old implementation fails and the corrected path
  reaches draft-PR creation.

## Focused evidence

- Created-issue true zero-list lag plus different-identity race focus passed as
  [TEST-0150](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) in 12.0 seconds, including separate updater and issue-token actors.
- [TEST-0148](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) and [TEST-0149](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) passed in 23.5 seconds; [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) passed in
  20.0 seconds; publication evidence and capabilities-bootstrap `Contracts`
  each passed in 1.9 seconds.
- All 28 canonical consumer-updater behavior scenarios passed in 64.0 seconds
  outside the sandbox-only Git signal-pipe boundary; after the two new
  assertion labels were assigned to [TEST-0150](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md), exact registry binding passed
  separately in 0.7 seconds without rerunning unchanged behavior.
- [PR #92](https://github.com/hasanmanzak/meAndAI/pull/92) run `29756397638` exposed [FIND-0198](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md) on both hosts: the finalization
  fixture omitted the author object from its newly created issue. The fixture
  now distinguishes the historical issue owner, authenticated updater, and new
  `github-actions[bot]` issue-token author across separate updater and issue
  credentials. Its focused owner passed in 13.0 seconds, including an omitted
  `user` response that stopped on the exact controlled convergence error after
  one issue creation and before every later managed mutation. The final
  response-shape guard also passed focused [TEST-0150](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) again in 11.6 seconds,
  and structure-only validation remained green.
- [PR #92](https://github.com/hasanmanzak/meAndAI/pull/92) run `29757563950` then passed that finalization owner and all 28 updater
  scenarios on Ubuntu before exposing [FIND-0199](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md): the version bump had made
  both the current fixture and its first synthetic future release v0.12.5, so
  Git correctly rejected a second no-change commit. The future release is now
  v0.12.6; `ContractsPreflight` rebuilt the complete immutable fixture and
  passed in 17.1 seconds outside the sandbox-only Git signal-pipe boundary. The
  still-running Windows job was cancelled after the deterministic Ubuntu
  failure to avoid unnecessary runner use.

## Continue from here

Complete only the focused updater owners and structural gate, obtain fresh-diff
review, and publish one bounded v0.12.5 hotfix PR. After hosted validation,
merge and release exact source-bound assets, replay only the published launcher
against Derdini, then reconcile [PR #6](https://github.com/hasanmanzak/Derdini/pull/6) and stale issues [#7](https://github.com/hasanmanzak/Derdini/issues/7)/[#8](https://github.com/hasanmanzak/Derdini/issues/8) only after the new
replacement issue, branch, and draft PR are proven exact. Keep the consumer PR
open and draft for maintainer review.
