# FEAT-0014 Test Scenarios

Implemented automation:

- [Quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1)
- [Bootstrap adapter fixtures](../../../tests/capabilities-bootstrap-adapter.tests.ps1)
- [Updater resolver and adapter fixtures](../../../tests/protocol-update.tests.ps1)
- [Repository and scenario-ownership validator](../../../tests/protocol.tests.ps1)
- [Post-publication evidence fixtures](../../../tests/post-publication-evidence.tests.ps1)

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0086` | `SUBF-0033` | Run the launcher with its seed workflow under an ordinary `.github` directory and under a representative existing linked `.github` ancestor. | The ordinary contained destination proceeds; the linked ancestor blocks before secret inventory or mutation and leaves the external target unchanged. | Launcher containment / security integration | Passed locally on 2026-07-16 | Launcher real-filesystem fixture |
| `TEST-0087` | `SUBF-0033` | Retain exact launcher `Completed` state and exercise wrong completion parent, rewritten proposal tree, checked-change-set, protected workflow/credential, protocol, updater-blob, and manifest variants. | Only the exact launcher completion transition reaches readiness reconciliation; each drift blocks without Codex, readiness, or remote mutation. | Launcher lifecycle / state-transition integration | Passed locally on 2026-07-16 | Launcher real-Git fixture |
| `TEST-0088` | `SUBF-0033`, `SUBF-0035` | Parse and compare canonical ASCII/no-leading-zero version components, leading-zero and Unicode-digit forms, and components beyond platform integer limits. | Every affected runtime boundary and TEST-0002 use the same unbounded canonical grammar and numeric ordering. | Version contract / boundary | Passed locally on 2026-07-16 | Launcher, updater resolver, and repository validator fixtures |
| `TEST-0089` | `SUBF-0034` | Exercise launcher manifest identity/schema/type variants, post-ready/pre-issue interruption, and missing immutable release state. | Each malformed, interrupted, or missing launcher state fails or recovers at its owning boundary without prohibited mutation. | Launcher evidence integrity / integration | Passed locally on 2026-07-16 | Parameterized launcher fixtures |
| `TEST-0090` | `SUBF-0034` | Dispatch the lifecycle with exact and wrong workflow, repository, ref, correlation, and independently expected commit/run identities. | Only the exact dispatch is recorded and only its independently derived run can satisfy the wait; caller-supplied query data cannot fabricate success. | External-boundary mock / integration | Passed locally on 2026-07-16 | Quick-adoption GitHub CLI fixture |
| `TEST-0091` | `SUBF-0034` | Remove a scenario assertion while leaving a hard-coded success result, and suppress one mapped result while its owning suite otherwise succeeds. | Source-bound evidence ignores the stale hard-coded result, and ownership validation rejects every missing or unobserved scenario. | Evidence authority / structural | Passed locally on 2026-07-16 | Compact source/result contract and repository validator |
| `TEST-0092` | `SUBF-0035` | Inspect v0.8.4 finding counts, TEST-0002 wording, issue #41/PR #42 canonical links and workflow status, and the active `FIND-0120` external follow-up. | Counts and grammar match canonical records; GitHub projections use stable FEAT/DEC links, closed delivery is not labeled in progress, and branch protection remains an openly tracked external risk rather than a false resolution. | Governance / external integration | Passed locally and externally reviewed on 2026-07-16 | Repository validator plus read-only GitHub projection review |
| `TEST-0093` | `SUBF-0033` | Run bootstrap with its representative `.ai` managed ancestor as an ordinary directory and as an existing symbolic-link, junction, or reparse boundary. | The ordinary contained write set proceeds; the linked ancestor blocks before branch switch or managed filesystem mutation and leaves the external target unchanged. | Bootstrap containment / security integration | Passed locally on 2026-07-16 | Bootstrap real-filesystem fixture |
| `TEST-0094` | `SUBF-0033` | Retain exact bootstrap `Completed` state and exercise wrong completion parent, rewritten proposal tree, checked-change-set, protected workflow/credential, protocol, updater-blob, and manifest variants. | Only the exact bootstrap completion transition is retained; each drift blocks without proposal replacement or remote mutation. | Bootstrap lifecycle / state-transition integration | Passed locally on 2026-07-16 | Bootstrap real-Git fixture |
| `TEST-0095` | `SUBF-0034` | Execute exact, missing, and drifted state for both bootstrap updater assets and a case-variant managed-path collision. | Every updater-asset variant is checked independently, and the case collision remains a manifest-only handoff without overwrite. | Bootstrap evidence integrity / integration | Passed locally on 2026-07-16 | Parameterized bootstrap fixtures |

## Required coverage

- Lexical and physical containment before credential or filesystem side effects.
- Exact completed-publication trust shared across bootstrap, launcher, and
  publishing recovery.
- One unbounded ASCII/no-leading-zero version contract.
- Every declared variant from `FIND-0126`, including negative mutation checks.
- Independently derived workflow dispatch and run identity.
- Observable per-scenario execution rather than suite-exit inference.
- Exact historical counts, canonical wording, stable links, and open external
  risk ownership.

## Baseline evidence

| Date | Commit | Environment | Command or review | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | Immutable v0.8.4 commit `0d4a05e0ce09e5c5586d69a7868128e061f35295` | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Existing suite passed in 543.6 seconds but did not prove TEST-0086 through TEST-0092; all nine findings remained open |
| 2026-07-16 | Immutable v0.8.4 commit `0d4a05e0ce09e5c5586d69a7868128e061f35295` | Repository scan | Parse all 15 tracked PowerShell files; inspect diff hygiene and local links | Parse, diff, and links were clean; the read-only runtime, test, and governance scans produced the frozen nine-finding register |

## Completion evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | FEAT-0014 review tree (pre-commit) | Windows PowerShell 5.1 | Parse all 16 PowerShell files; `tests/protocol.tests.ps1 -StructureOnly`; `git diff --check` | Passed; every script parsed, the structural contract passed, and diff hygiene was clean |
| 2026-07-16 | FEAT-0014 review tree (pre-commit) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Passed in 368.8 seconds after the exact fixture inventory and label-operation mock were reconciled |
| 2026-07-16 | FEAT-0014 review tree (pre-commit) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 611.7 seconds; all six executable owners emitted exact source-bound scenario results |
| 2026-07-16 | Issues #41, #43, #44 and PR #42 | Read-only GitHub projection review | Verify canonical links, closure labels, and open external follow-up ownership | Passed; #41/#42 are reconciled, #43 owns this delivery, and #44 remains the open `FIND-0120` authority |
| Pending | Merged v0.8.5 commit | GitHub Actions and post-publication authority | Hosted CI and exact publication verifier | Pending; exact facts belong to issue #43 and the GitHub Release |
