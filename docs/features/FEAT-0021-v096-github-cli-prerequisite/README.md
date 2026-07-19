# FEAT-0021 - v0.9.6 GitHub CLI Prerequisite Gate

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.9.6 |
| Issue | [#59](https://github.com/hasanmanzak/meAndAI/issues/59) |
| Pull request | [#60](https://github.com/hasanmanzak/meAndAI/pull/60) |
| Decision | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md) |
| Tests | [TEST-0107](test-cases.md) |

## Problem and intended outcome

The source-only quick-adoption launcher checks that `gh` exists but does not
check whether the installed GitHub CLI is compatible with GitHub's current API
boundary. A client older than `2.82.1` can complete deterministic setup and
semantic work before `gh pr edit --body-file` fails because that client still
requests the retired Projects (classic) `projectCards` field.

Reject an incompatible or unparseable GitHub CLI version at the first
prerequisite boundary, before authentication, repository initialization,
credential inspection, remote mutation, workflow dispatch, or Codex execution.

## Scope and non-goals

- Invoke the documented `gh --version` command once after command discovery.
- Parse exactly one canonical ASCII `M.m.rev` version line without integer-size
  assumptions or lexical comparison.
- Require version `2.82.1` or newer and provide actionable upgrade guidance.
- Prove exact-floor, older, malformed, later, and multi-digit component
  behavior plus pre-mutation ordering in `TEST-0107`.
- Update the prerequisite guide, protocol contract, version records, and
  project memory for `0.9.6`.

GitHub Projects adoption, token-scope changes, credential repair, automatic CLI
installation, PR-body transport replacement, consumer reset, a second launcher,
or another validation framework are not in scope.

## Contracts and risks

The prerequisite is the installed GitHub CLI application version, not a GitHub
API version or repository protocol version. Components are non-negative ASCII
decimal strings with no leading zeros except the single value `0`. Comparison
is numeric by component and must accept future component lengths such as
`2.100.0` without fixed-width integer conversion.

No local or remote state may change when the version is older, missing,
malformed, or ambiguous. The error identifies the minimum version and the
official upgrade location without echoing uncontrolled command output.

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0097` | Compatibility parsing | Lexical, permissive, locale-sensitive, or bounded-integer comparison accepts an unsafe client or rejects a valid future version | Mitigating / launcher maintainer | Strict ASCII components, length-aware ordinal comparison, and `TEST-0107` boundary fixtures |

## Definition of Ready

- [x] Stable `FEAT-0021` and `BUG-0009` identifiers and linked issue #59 exist.
- [x] Problem, outcome, scope, non-goals, entry point, version grammar,
      comparison, ordering, error, and compatibility contracts are explicit.
- [x] DEC-0007 continues to own the source-only local launcher boundary; no new
      architectural decision is required.
- [x] The work is one independently reviewable prerequisite correction; no
      subfeature decomposition is required.
- [x] `TEST-0107` defines success, failure, malformed, boundary, future-version,
      and side-effect-ordering evidence before production changes.
- [x] Verification is bounded to one expected-red focused run, one focused
      green run, one complete suite, one fresh-diff review, and the protocol's
      single post-development scan.

## Acceptance criteria

1. The launcher rejects `2.82.0` and all earlier versions before any
   authentication, Git initialization, credential inspection, or remote action.
2. Missing, malformed, leading-zero, or ambiguous version output fails closed
   with the `2.82.1` minimum and official upgrade guidance.
3. Exact `2.82.1`, later versions, and multi-digit components such as `2.100.0`
   pass the version gate and continue to the next ordinary prerequisite.
4. The check is locale-independent, does not expose raw uncontrolled output,
   and introduces no fixed integer ceiling.
5. `TEST-0107`, existing quick-adoption scenarios, and the complete repository
   suite pass; canonical docs and project memory agree on version `0.9.6`.

## Implementation and verification approach

Add the focused mock version cases first and record the expected-red result.
Implement one assertion beside the existing external-command boundary and call
it immediately after `git`/`gh` discovery. Reuse the existing launcher and test
suite; do not add a wrapper, dependency, installer, or generalized validator.

| Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- |
| `FEAT-0021` | [Issue #59](https://github.com/hasanmanzak/meAndAI/issues/59) | `TEST-0107`; seven-case expected red, focused green, and complete suite passed in 535.1 seconds | `FIND-0152` resolved; confirmation found no Blocking observation | Complete |

## Relationships

- Original launcher capability: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Governing decision: [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking and post-publication authority: [issue #59](https://github.com/hasanmanzak/meAndAI/issues/59)
- GitHub compatibility notice: [Projects (classic) sunset](https://github.blog/changelog/2024-05-23-sunset-notice-projects-classic/)

## Self-review and completion

The fresh diff and relevant launcher call flow were reviewed for strict type
and semantic boundaries, numeric comparison, failure ordering, error-output
control, duplication, cohesion, compatibility, test false positives, and
documentation/version/memory consistency. The implementation reuses the
existing external-command boundary, adds one cohesive prerequisite assertion,
and creates no installer, alternate launcher, or validation framework. No
unresolved `Blocking` observation remains.

### Bounded project scan

- Scope: all 140 tracked repository files, PowerShell entry points, workflow
  and consumer templates, scenario ownership, version pins, documentation and
  memory links, credential patterns, and working-tree hygiene.
- Exclusions: `.git` internals and external hosted-CI, merge, tag, and immutable
  release facts that do not exist before publication.
- Budget: one initial scan and one confirmation only if remediation changes the
  tree.
- Initial result: all 18 tracked PowerShell files parsed, no duplicate launcher
  function or credential pattern was found, the four ordinary-text `v0.9.5`
  matches were historical, and `git diff --check` was clean. The subsequent
  complete suite exposed one escaped-regex pin missed by that search, reopening
  the bounded cycle as `FIND-0152`.

| ID | Classification / disposition | Dependencies | Priority / severity / impact | Confidence | Evidence and affected scope | Impact rationale and action | Status / links |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `FIND-0152` | Defect / `Blocking` | None | `p1` / medium / medium | High | The complete suite failed after 208.2 seconds because three `v0\.9\.5` regex fixtures in [`tests/quick-adoption.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1) no longer matched the active `v0.9.6` release endpoint; `TEST-0056`, `TEST-0078`, `TEST-0086`, and `TEST-0089` entered the generic API-error path. | The incomplete mechanical pin update invalidated existing regression evidence. Update only the three escaped fixture pins, search both ordinary and escaped forms, review the correction, then run the budgeted confirmation and final suite. | Resolved; the confirmation found no stale active fixture or new `Blocking` observation / [issue #59](https://github.com/hasanmanzak/meAndAI/issues/59) |

The budgeted confirmation parsed all tracked PowerShell, searched ordinary and
escaped old-version forms, rechecked credential patterns, active version pins,
the correction diff, conflicts, and whitespace. Only historical `v0.9.5`
records and the finding evidence itself remained; no unresolved `Blocking`
finding remained. The three-line fixture correction introduced no production
behavior change or duplicated test path.

## Definition of Done

- [x] Acceptance criteria and `TEST-0107` pass.
- [x] Existing quick-adoption scenarios and complete repository suite pass.
- [x] Fresh-diff review and bounded project scan leave no unresolved
      `Blocking` finding.
- [x] Version, changelog, guide, decision links, feature index, and project
      memory agree.
- [x] Issue and pull request link canonical records and validation evidence.

## Post-merge publication gate

Issue #59 is the external authority for the exact merged commit, immutable
v0.9.6 release, launcher asset digest, hosted checks, and branch cleanup after
those facts exist.
