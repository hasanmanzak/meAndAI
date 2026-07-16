# FEAT-0016 - v0.9.1 Quick-Adoption Existing-Repository Correction

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.9.1 |
| Issue | [#49](https://github.com/hasanmanzak/meAndAI/issues/49) |
| Pull request | Pending |
| Decision | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md) |
| Tests | [TEST-0100](test-cases.md) |

## Problem and outcome

[BUG-0002](../FEAT-0007-local-codex-adoption/README.md#bug-0002-correction-for-v071)
made local credential files optional for an existing connected repository, but
the launcher still classified every no-`origin` target as a new repository
before resolving the derived GitHub identity. An accessible, empty GitHub
repository could therefore already own both mapped repository Actions secrets
while the launcher emitted a misleading missing-file error.

The launcher now resolves the exact derived GitHub repository read-only. If it
exists and has no branch history, canonical source is verified before the
launcher connects it to the safe no-head bootstrap path. Repository secret-name
inventory then determines whether either local credential file is required. A
genuinely absent repository retains the existing requirement for both files
before creation.

## Scope and non-goals

- Discover only the exact owner/name already derived by the launcher and
  connect it only when it is empty.
- Preserve present `MEANDAI_UPDATER_TOKEN` and `MEANDAI_PROTOCOL_TOKEN` names
  without reading their mapped local files or attempting `gh secret set`.
- Require a mapped file when its repository secret is absent and fail before
  any secret write.
- Keep credential tracked/history validation ahead of identity classification.
- Reject no-remote repositories with local commits and derived repositories
  with remote history instead of attempting general synchronization.
- Preserve release/source verification, secret locking, stdin-only writes, and
  the existing new-repository flow.

General repository synchronization, secret-value inspection, organization or
environment secret import, token rotation, and additional bootstrap layers are
out of scope. The accepted repository and credential boundary remains
[DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md), while
[DEC-0008](../../decisions/DEC-0008-local-codex-execution.md) continues to own
the later local Codex step; no new architectural decision is required.

## Risks and readiness

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0085` | Repository identity | A derived repository exists with history that cannot be reconciled safely with a no-head local target | Mitigated / launcher maintainer | Read-only head inspection and fail before adding the remote; `TEST-0100` |

- [x] Stable `FEAT-0016`, `BUG-0005`, and linked issue #49 exist.
- [x] Problem, outcome, scope, non-goals, identity, credential ownership,
      ordering, errors, and compatibility are explicit.
- [x] Existing DEC-0007 and DEC-0008 boundaries remain sufficient and linked.
- [x] One bounded implementation slice is sufficient; no subfeature or new
      runtime layer is needed.
- [x] `TEST-0100` covers existing-empty success, missing-secret/missing-file,
      existing-non-empty rejection, and unchanged absent-repository behavior.
- [x] Validation is bounded to focused red/green evidence, one fresh-diff
      review, one full repository gate, and confirmation only after remediation.

## Acceptance criteria

1. A no-head target without the selected remote resolves the exact derived
   GitHub owner/repository before deciding that it is new.
2. If that repository is accessible and empty, canonical source is verified,
   the remote is connected, and present mapped repository secrets make their
   local files optional without any overwrite attempt.
3. A missing repository secret still requires its mapped local file and fails
   before secret mutation when that file is absent.
4. A genuinely absent repository still requires both local files before
   creation; a repository with remote history or a no-remote local commit is
   not reconciled automatically.
5. Credential history, exact source, secret locking, stdin transfer, existing
   connected-repository behavior, and new-repository behavior remain intact.

## Verification and self-review

The executable regression first reproduced the incorrect early
`FG_PAT.txt` requirement. The quick-adoption suite then passed all declared
scenarios, including `TEST-0100`, in 351.3 seconds outside the restricted Git
signal-pipe sandbox. The success fixture proves zero `gh secret set` calls with
both files absent and both mapped names present. Negative fixtures prove the
missing updater mapping and non-empty derived repository stop before secret or
local-remote mutation.

| ID | Classification / priority | Finding and resolution | Status |
| --- | --- | --- | --- |
| `FIND-0140` | Test fixture contract / P1 | Early fixture revisions did not model every GitHub transition and used one unsupported helper parameter. The fixture now models repository creation, first-push default-branch assignment, and explicit derived identity with supported helpers. | `Blocking` / Resolved before final green evidence |
| `FIND-0141` | Security gate ordering / P1 | The first implementation moved no-remote/local-commit rejection ahead of credential reflog validation, and `TEST-0055` failed. Tracked/history validation is again unconditional and file presence is evaluated after identity. | `Blocking` / Resolved by the green suite |
| `FIND-0142` | Scenario evidence ownership / P1 | The new fixture executed before the machine-readable authority owned `TEST-0100`. The scenario is now source-bound and listed in `tests/scenario-ownership.psd1`. | `Blocking` / Resolved by focused ownership verification |
| `FIND-0143` | Decision traceability / P1 | The first feature draft named only DEC-0008 even though no-remote repository resolution is governed by DEC-0007. Both decision relationships and DEC-0007's refined empty-existing-repository rule are now explicit. | `Blocking` / Resolved during fresh-diff review |
| `FIND-0144` | Test contract / P1 | The first success assertion proved zero secret writes but did not independently require repository secret-name inventory, so an implementation that skipped reconciliation entirely could look green. `TEST-0100` now requires exactly one `gh secret list` call before accepting the file-free success path. | `Blocking` / Resolved during fresh-diff review |
| `FIND-0145` | Semantic cross-link / P2 | After TEST-0100 moved into FEAT-0016, the changelog still linked the historical FEAT-0007 scenario file. The link now resolves to the canonical FEAT-0016 scenario record. | `Blocking` / Resolved during fresh-diff review |
| `FIND-0146` | Escaped active pin / P1 | The first full suite found three regex-escaped v0.9.0 quick-adoption mock matchers that plain active-pin replacement did not change, causing real API fallback. The exact escaped matchers now target v0.9.1, and both plain and escaped stale-pin searches are part of the final confirmation. | `Blocking` / Resolved after failed full-suite evidence |

The fresh diff contains no secret value, broad repository synchronizer,
duplicate owner/name validation, new workflow, or AI bootstrap layer. The full
repository gate passed all discovered suites in 473.8 seconds and reported
`TEST-0100` in the quick-adoption suite's machine-readable scenario result.

## Relationships

- Corrects: [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md)
- Repository and credential decision: [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md)
- Local Codex decision: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Guide: [Quick adoption](../../quick-adoption.md)
- Tracking and publication authority: [issue #49](https://github.com/hasanmanzak/meAndAI/issues/49)

## Definition of Done

- [x] Acceptance criteria and `TEST-0100` pass.
- [x] Existing quick-adoption scenarios pass in the same executable suite.
- [x] The complete repository suite passes with exact scenario ownership.
- [x] Fresh-diff findings are resolved with no open `Blocking` item.
- [x] Active version pins, guide, changelog, feature graph, and project memory
      describe v0.9.1 consistently.
- [x] Issue, decision, predecessor, test, and guide links are present.
- [x] No external fact that does not yet exist is predicted in this record.

## Post-merge publication gate

Issue #49 is the external authority for the exact merged commit, immutable
`v0.9.1` GitHub Release, hosted checks, and post-publication verification after
those facts exist.
