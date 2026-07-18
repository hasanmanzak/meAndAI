# FEAT-0030 Test Scenarios

Test implementation: [repository structural suite](../../../tests/protocol.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0131` | `SUBF-0055` | Inspect the canonical prompt for pinned authority, material-change entry, disposition and dependency rules, per-finding evidence/review, finite confirmation, blocked/waiting outcomes, and publication mode. | The prompt faithfully invokes DEC-0015, defaults to report-only, distinguishes local convergence from full completion, remains blocked without final-push authority, permits only an explicitly authorized review-branch push to enter Waiting, and never permits a tag or GitHub Release. | Structural / semantic fidelity / authority | Passed | `tests/protocol.tests.ps1` |
| `TEST-0132` | `SUBF-0055` | Inspect documentation links and both consumer integration models; search managed paths, templates, workflows, migrations, and prompt text for automatic installation or scheduling. | Maintainers can resolve one immutable canonical prompt; no consumer-owned copy, goal, task, schedule, workflow, updater path, migration, or self-activation is created. | Structural / reachability / negative | Passed | `tests/protocol.tests.ps1` |

## Required coverage

- Normative authority and direct DEC-0015 fidelity.
- Event trigger, waiting, blocked, finite budget, and unchanged-scan stop.
- Dispositions, dependency ordering, sequential remediation, tests, and review.
- Report-only default and separately authorized review-branch push.
- No tag, release, goal, scheduler, automation, or consumer-owned copy.
- Submodule and repository-reference immutable reachability.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-18 | `e226293` baseline | Windows / repository baseline | Existing TEST-0096 through TEST-0099 | Normative cycle green; TEST-0131 and TEST-0132 not yet implemented |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\protocol.tests.ps1 -StructureOnly` | Passed, exit 0 in 2.5 s after the final local-convergence / publication-authority clarification; TEST-0131 and TEST-0132 green |
| 2026-07-18 | Pre-clarification working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\protocol.tests.ps1` | Passed, exit 0 in 1576 s; all discovered suites and canonical TEST-0131 / TEST-0132 ownership green; only the later documentation-and-assertion clarification differs |
