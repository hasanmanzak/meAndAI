# FEAT-0001 Test Scenarios

Test implementation:
[tests/protocol.tests.ps1](../../../tests/protocol.tests.ps1)

Run from the repository root with the installed Windows PowerShell 5.1:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1
```

PowerShell 7 environments may use `pwsh -NoProfile -File tests/protocol.tests.ps1`.

| ID | Related slice | Scenario | Expected result | Status | Automation |
| --- | --- | --- | --- | --- | --- |
| `TEST-0001` | All | Required protocol, adoption, memory, feature, decision, and GitHub template files exist. | Every required path resolves to the expected file type. | Passed | Structural test |
| `TEST-0002` | `SUBF-0001` | `VERSION` is evaluated against `M.m.rev`. | Exactly three ASCII decimal components are accepted, with no leading zero unless the component is exactly `0`. | Passed | Structural test |
| `TEST-0003` | All | Inline local Markdown links are resolved relative to their document and remain inside the repository. | No missing, escaped, or invalid-anchor target is reported. | Passed | Structural test |
| `TEST-0004` | `SUBF-0003` | Every `FEAT-NNNN-*` directory is inspected. | `README.md` and `test-cases.md` both exist. | Passed | Structural test |
| `TEST-0005` | `SUBF-0003` | Every numbered decision document is inspected. | Required classification, ID, status, context, decision, and consequences sections exist. | Passed | Structural test |
| `TEST-0006` | `SUBF-0001` | Current release metadata is compared with `VERSION`; historical feature targets are checked only for format. | Current metadata reports the value in `VERSION` without rewriting historical feature targets. | Passed | Structural test |
| `TEST-0007` | `SUBF-0003` | Issue forms and the PR template receive targeted identifier, label, and evidence-prompt checks. | Expected tracking semantics are present; full YAML schema is manually reviewed. | Passed | Structural plus manual schema review |
| `TEST-0008` | `SUBF-0002` | Submodule and repository-reference adapters are distinguished and memory remains outside the protocol path. | Each adoption mode loads its real entry point without cross-project memory coupling. | Passed | Structural test |
| `TEST-0018` | `SUBF-0001` | Inspect the bounded self-validation contract and feature template. | One normal review pass and final verification command are the default; only blockers reopen scope; recursive validator chains require a concrete risk and decision. | Passed | Structural test |
| `TEST-0020` | `SUBF-0001` | Inspect the urgent-work exception contract for [FIND-0047](https://github.com/hasanmanzak/meAndAI/issues/9). | Urgency compresses elapsed time, not gate order; Gate 1 remains pre-implementation and deviations preserve tests and linked follow-up through the numbered-decision process. | Passed | Structural test |

## Evidence

Evidence is recorded after each run:

| Date | Environment | Result | Notes |
| --- | --- | --- | --- |
| 2026-07-14 | Baseline `a6e3064` plus current test harness; Windows PowerShell 5.1.19041.7417 | Expected failure | `TEST-0001` reported the protocol files absent before implementation. |
| 2026-07-14 | Windows PowerShell 5.1.19041.7417 | Pass | `TEST-0001` through `TEST-0008`; `git diff --cached --check` clean. |
| 2026-07-14 | Windows PowerShell 5.1 | Pass | Initial `TEST-0001` through `TEST-0020`; FIND-0047 fresh-diff review then preserved tests and linked follow-up. |
| 2026-07-14 | Windows PowerShell 5.1 | Expected blocker | Confirmation exposed `FIND-0048`: TEST-0020 exact-string matching crossed a Markdown line wrap. |
| 2026-07-14 | Windows PowerShell 5.1 | Pass | Whitespace-normalized `TEST-0020`; full suite passed through `TEST-0020`. |

## Manual evidence

- GitHub issue forms were reviewed against the official
  [issue-form syntax](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
  and [form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema).
- The private repository and [issue #1](https://github.com/hasanmanzak/meAndAI/issues/1)
  resolve. The `v0.1.0` adapter links are release-gated and verified after merge.
