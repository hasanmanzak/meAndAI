# FEAT-0020 - v0.9.5 Streamed Codex Activity and Safe Cancellation

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.9.5 |
| Issue | [#57](https://github.com/hasanmanzak/meAndAI/issues/57) |
| Pull request | Pending |
| Decisions | [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md), [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md) |
| Tests | [TEST-0105 and TEST-0106](test-cases.md) |

## Problem and intended outcome

The v0.9.4 launcher uses PowerShell's host-managed `Write-Progress` surface.
In Windows PowerShell that blue overlay occupies a separate console region and
can visually collide with normal launcher output and error text. Semantic
`codex exec` stdout is also read only after process completion, so the
maintainer sees elapsed time but none of Codex's observable activity.

The bounded-process timeout terminates the process tree, but its unconditional
finalizer currently disposes a still-running process without first terminating
it. A Ctrl+C or another exceptional pipeline stop can therefore leave a local
Codex process or an owned temporary-clone residue even though no validated
consumer change is published.

Keep the existing deterministic adoption and publication boundaries while
making progress line-oriented, consuming the documented `codex exec --json`
event stream as it arrives, and terminating the child process tree before
temporary-clone cleanup on every bounded-process exit.

## Scope and non-goals

- Replace the host-overlay progress surface with compact normal console lines
  for actual launcher phase boundaries.
- Add `--json` only to semantic `codex exec`, read JSONL stdout incrementally,
  and map allowlisted event metadata to concise `Codex | ...` activity lines.
- Display agent messages intended for the caller, generic reasoning/plan/tool
  activity, safe command identity, file-change paths, completion, and errors.
- Keep the final `--output-last-message` file as the sole readiness response;
  streamed presentation cannot authorize publication.
- Deduplicate activity and emit a bounded elapsed heartbeat when Codex emits no
  new event. `-NoProgress` suppresses phase and live activity presentation
  without changing execution.
- Reuse one process-tree termination helper for timeout and exceptional
  finalization, then remove only the launcher's owned temporary clone.
- Retain exact remote-head leases and the existing recoverable
  `Proposed -> Publishing -> Completed` transition.

No interactive TUI, Codex Cloud connection, raw chain-of-thought, command
output transcript, credential output, automatic merge, consumer reset,
protocol retargeting, new bootstrapper, or new validation framework is in
scope. The retained Derdini PR #1 remains a v0.9.2 adoption proposal.

## Contracts and risks

Semantic Codex execution uses JSONL only as an observational channel. The
launcher does not persist that stream and does not render reasoning content or
raw command output. Unknown or malformed presentation events are retained only
in the bounded process result for exit diagnostics and cannot make a blocked
or missing final-result file ready.

Cancellation safety is ordered: stop the active child tree, wait for bounded
termination, dispose the process wrapper, and only then let the outer adoption
boundary remove its unpredictable owned temporary root. Before the validated
completion push, the consumer checkout and remote proposal are not mutated by
Codex. If interruption occurs in the later push/marker window, DEC-0013's exact
persisted-intent recovery remains authoritative.

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0093` | Output confidentiality | A raw event field exposes command output, hidden reasoning, or credential material | Prevented / launcher maintainer | Render an allowlist of user-facing messages and safe activity metadata; never render raw reasoning or command output; `TEST-0105` |
| `RISK-0094` | Cancellation cleanup | Ctrl+C leaves Codex or its descendants running against a temporary clone | Mitigating / launcher maintainer | Invoke one child-tree stop helper from timeout and `finally`, then verify owned-root cleanup; `TEST-0106` |
| `RISK-0095` | Readiness authority | A streamed ready-looking message bypasses final-result or repository validation | Prevented / launcher maintainer | Preserve `--output-last-message`, manifest, head, change-set, credential, and lease checks as the only completion path; `TEST-0105` |
| `RISK-0096` | Console usability | Frequent events recreate noisy or overlapping output | Mitigating / launcher maintainer | Normal line output, event deduplication, bounded length, and throttled heartbeats; `TEST-0105` |

## Definition of Ready

- [x] Stable `FEAT-0020` and `BUG-0008` identifiers and linked issue #57 exist.
- [x] Problem, outcome, scope, non-goals, entry points, compatibility,
      presentation, cancellation, cleanup, remote-state, and error contracts are
      explicit.
- [x] DEC-0008 continues to own local Codex isolation and DEC-0013 continues to
      own push/marker recovery; no new architectural decision is required.
- [x] The change is one bounded launcher correction with no consumer reset or
      protocol retargeting.
- [x] `TEST-0105` and `TEST-0106` define streaming, false-readiness,
      presentation, timeout, cancellation-finalizer, process-tree, temporary
      cleanup, and remote-unchanged evidence before production changes.
- [x] Verification is bounded to one expected-red focused run, one focused
      green run, one fresh-diff review, one complete suite, and the protocol's
      single post-development scan.

## Acceptance criteria

1. Launcher progress appears as normal compact console lines and no active code
   invokes `Write-Progress` or creates the blue host overlay.
2. Semantic Codex receives `--json`; stdout is read while the child is active
   and recognized events produce concise, deduplicated live activity.
3. Agent messages are visible, while raw reasoning and command output are not;
   long or control-character-bearing values cannot corrupt the terminal.
4. `-NoProgress` suppresses phase, heartbeat, and Codex activity presentation
   without changing the adoption result.
5. The final result file and all existing repository validations remain the
   only readiness authority; streamed content cannot create a false success.
6. Timeout, Ctrl+C-equivalent pipeline cancellation, and other exceptional
   exits attempt child-tree termination before process disposal and owned-root
   cleanup.
7. Interruption before publication leaves the live proposal head unchanged;
   interruption in the push/marker window retains existing exact recovery.
8. Focused and complete repository suites pass, documentation and memory agree,
   and bounded review leaves no unresolved `Blocking` finding.

## Implementation and verification approach

Add `TEST-0105` and `TEST-0106` first. The red run must prove the current
launcher still uses the native overlay, lacks `--json` and incremental line
consumption, and does not stop an active process from its finalizer. Implement
only the existing launcher presentation and bounded-process seams, extend the
mock Codex event fixture, and preserve all downstream publication validators.

The implementation uses one line renderer, one JSONL event presenter, and the
existing bounded-process seam. Windows semantic execution is assigned to a
kill-on-close Job Object before model work; timeout and exceptional finalization
also use the shared process-tree stop path. No persistent event log, service,
or additional validation framework is introduced.

## Relationships

- Local Codex feature: [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md)
- Prior correction: [FEAT-0019](../FEAT-0019-v094-sandbox-progress-correction/README.md)
- Governing execution decision: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Governing interruption recovery: [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking and post-publication authority: [issue #57](https://github.com/hasanmanzak/meAndAI/issues/57)
- Consumer evidence: [Derdini PR #1](https://github.com/hasanmanzak/Derdini/pull/1)

## Self-review and completion

The fresh-diff review verified the presentation, event, process ownership,
cleanup, release-pin, test-evidence, documentation, and memory boundaries. The
event presenter exposes only bounded caller-facing messages and safe activity
metadata; final-result and repository checks remain authoritative. Windows
semantic execution fails closed unless kill-on-close containment is established,
and every exceptional bounded-process exit reaches tree termination before
process disposal and outer temporary-root cleanup.

Three blocking test-fixture defects were found and resolved in the current
slice before completion: escaped v0.9.4 mock endpoints were advanced to v0.9.5,
the timeout case now creates its proposal before reading the remote head, and
the proposal helper uses the existing native-Git wrapper so informational
stderr is not treated as a terminating PowerShell error. Parser, diff,
duplicate-function, stale-pin, focused streaming, all existing quick-adoption,
and scenario-ownership evidence then passed. The bounded project scan found no
remaining `Blocking` observation and was not repeated unchanged.

## Definition of Done

- [x] Acceptance criteria and `TEST-0105` / `TEST-0106` pass.
- [x] Existing quick-adoption scenarios and complete repository suite pass.
- [x] Fresh-diff review and bounded project scan leave no unresolved
      `Blocking` finding.
- [x] Version, changelog, guide, decisions, links, feature index, and project
      memory agree.
- [ ] Issue and pull request link canonical records and validation evidence.

## Post-merge publication gate

Issue #57 is the external authority for the exact merged commit, immutable
v0.9.5 release, launcher asset digest, hosted checks, branch cleanup, and
retained Derdini continuation evidence after those facts exist.
