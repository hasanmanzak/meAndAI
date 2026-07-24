# FEAT-0015 Test Scenarios

Test implementation: [repository structural suite](../../../tests/protocol.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0096` <a name="test-0096"></a> | [SUBF-0037](README.md#subf-0037) | Inspect the normative cycle for its material-development trigger, required scan concerns, Gate 5 dispositions, zero-`Blocking` convergence, `Waiting` state, and material-change or failed-evidence re-entry. | The initial scan is sufficient when it has zero unresolved `Blocking`; confirmation runs only after remediation changed the tree; correctable failed evidence reopens the cycle while an uncorrectable failure stops at its authority/budget boundary; non-blocking dispositions remain visible and an unchanged waiting tree does not run autonomously. | Lifecycle / structural | Passed locally on 2026-07-16 | Repository structural suite |
| `TEST-0097` <a name="test-0097"></a> | [SUBF-0037](README.md#subf-0037) | Inspect the canonical finding schema, queue readiness, deterministic ordering, dependency cycles, missing authority, and the inseparable dependency-group exception. | Findings record explicit dependencies, priority, severity, and impact rank; dependencies determine the ready set; the remaining fields and stable ID order that set; cycles or missing authority stop `Blocked`; only the smallest recorded dependency-coherent group may be atomic. | Ordering / structural | Passed locally on 2026-07-16 | Repository structural suite |
| `TEST-0098` <a name="test-0098"></a> | [SUBF-0037](README.md#subf-0037) | Inspect each remediation unit for a solution, focused evidence, fresh-diff self-review, and treatment of a `Blocking` defect caused or exposed by the correction. | The next independent item cannot start before the current review gate; new blockers are fixed coherently or enter the active queue and cannot be deferred as legacy or optional debt. | Review containment / structural | Passed locally on 2026-07-16 | Repository structural suite |
| `TEST-0099` <a name="test-0099"></a> | [SUBF-0037](README.md#subf-0037) | Inspect the terminal publication boundary, hosted-evidence reopening, unchanged-scan prohibition, consumer pin reachability, updater ownership, and separate protocol-version distribution gate. | Only a converged tree receives the final push; that push is not a tag or GitHub Release; hosted blockers require a corrected converged push; each consumer adapter resolves the exact pin independently; updater ownership stays exact; v0.9.0 distribution still uses the mandatory immutable release. | Publication and compatibility / structural | Passed locally on 2026-07-16 | Repository structural suite |

## Required coverage

- Material development trigger and the applicable stability/consistency scan
  concerns.
- Existing observation dispositions and zero unresolved `Blocking` as the
  success condition.
- Dependency-first ready-set construction and deterministic priority ordering.
- Per-finding focused evidence, fresh-diff self-review, and containment of
  change-caused or change-exposed defects.
- Finite confirmation, blocked outcome, waiting state, and no unchanged loop.
- Converged final push versus separate protocol tag/GitHub Release publication.
- Prospective consumer exact-pin adoption and preservation of consumer-owned
  instructions, memory, records, and tests.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | Immutable v0.8.6 commit [`a3d58a9cee00b9914c40adcd8e93dff53bed235a`](https://github.com/hasanmanzak/meAndAI/commit/a3d58a9cee00b9914c40adcd8e93dff53bed235a) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Baseline passed in 561.6 seconds; TEST-0096 through TEST-0099 did not yet exist |
| 2026-07-16 | FEAT-0015 test-first tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Expected red: 14 missing mandate, template, and consumer contract assertions |
| 2026-07-16 | FEAT-0015 correction queue | Windows PowerShell 5.1 | Repeated focused `tests/protocol.tests.ps1 -StructureOnly` runs | [FIND-0133](README.md#find-0133), [FIND-0135](README.md#find-0135), [FIND-0134](README.md#find-0134), and [FIND-0136](README.md#find-0136) each demonstrated the intended red state; corrected runs returned only the intentional current-feature status gate; [FIND-0137](README.md#find-0137) strengthened false-positive boundaries from review evidence |
| 2026-07-16 | FEAT-0015 review tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Passed in 372.3 seconds with all declared launcher scenarios |
| 2026-07-16 | FEAT-0015 review tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 3.7 seconds after the feature completion projection |
| 2026-07-16 | FEAT-0015 review tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 560.1 seconds; every executable owner and exact source-bound scenario result passed |
| 2026-07-16 | FEAT-0015 confirmation tree | Windows PowerShell 5.1 | Structure/link/ID suite, PowerShell parse, `git diff --check`, active-pin audit, and exact finding-register review | Passed; no unresolved `Blocking` finding; two diagnostic false positives were historical evidence, not repository drift |
| 2026-07-16 | FEAT-0015 evidence tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 3.7 seconds after [FIND-0139](README.md#find-0139) separated local eligibility from external push evidence |
