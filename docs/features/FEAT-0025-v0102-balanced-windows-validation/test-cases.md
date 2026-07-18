# FEAT-0025 Test Scenarios

| ID | Owner | Scenario | Expected result | Type | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0117` | `SUBF-0044` | Inspect and execute the exact seven-name Windows matrix, four semantic integrity partial modes, independent partial baselines, `Shard=All`, compatibility result boundary, and aggregate dependencies; vary a legacy or unknown shard name. | Every prior integrity case has one partial route; partial modes are isolated and compatibility-only; legacy/unknown names fail closed; `Shard=All` remains canonical and ordered. | Structure / integration / isolation / negative | Superseded (`TEST-0123`, `TEST-0124`) | Historical v0.10.2 evidence remains in run 29576425693; the replacement scenarios are declared by [FEAT-0027](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md). |
| `TEST-0118` | `SUBF-0045` | Evaluate pull request, push, ordinary manual dispatch, and `verify_post_publication=true` routing for normal jobs, aggregate behavior, and the dedicated verifier. | Ordinary events retain recurring validation; the explicit release dispatch skips the normal matrix and aggregate and runs only the independent verifier. | Structure / event routing / negative | Passed | Exact workflow guard assertions passed; PR run 29576425693 ran ordinary jobs and skipped the release verifier as required; release-only publication proof remains in issue #67 |

## Baseline

| Date | Environment | Evidence | Result |
| --- | --- | --- | --- |
| 2026-07-17 | GitHub-hosted Ubuntu and Windows | [Run 29573099890](https://github.com/hasanmanzak/meAndAI/actions/runs/29573099890) | Linux full test 151 seconds; Windows base 137 seconds; Integrity test 308 seconds. |
| 2026-07-17 | GitHub-hosted Ubuntu and Windows | [Run 29573471361](https://github.com/hasanmanzak/meAndAI/actions/runs/29573471361) | Linux full test 132 seconds; Windows base 148 seconds; Integrity test 239 seconds. |
| 2026-07-17 | Release verification | [Run 29573909979](https://github.com/hasanmanzak/meAndAI/actions/runs/29573909979) | Verifier passed in 7 seconds, but the unnecessary ordinary matrix extended the workflow to about 275 seconds. |

## Planned evidence sequence

1. Expected red: exact seven-shard and release-only routing contracts fail on
   the v0.10.1 implementation.
2. Focused green: each of the four new partial integrity shards passes under
   Windows PowerShell 5.1 and structure validation passes.
3. Final local evidence: one complete Windows PowerShell 5.1 suite.
4. Hosted evidence: ordinary CI passes with the stable aggregate; a later
   release-only dispatch skips ordinary jobs and passes the verifier.

## Local evidence

- Expected red: the v0.10.1 implementation failed the four new shard-name
  assertions, retained the legacy monolith, and lacked the three normal-job and
  aggregate inverse guards.
- Focused green: structure validation and all four new Windows PowerShell 5.1
  compatibility shards passed. Their observed durations were 40.4, 81.2,
  105.8, and 76.5 seconds; timing is not a pass/fail gate.
- Complete local evidence: every executable test body passed. Final aggregation
  exposed a stale `TEST-0115` source anchor; the assertion was rebound to the
  superseding layout contract and the production evidence builder then returned
  the complete canonical root set.
- Hosted green: [run 29576425693](https://github.com/hasanmanzak/meAndAI/actions/runs/29576425693)
  passed in ordinary PR mode. Linux full took 153 seconds, Windows base 160,
  and the four integrity children 53, 96, 103, and 103 seconds. The Windows
  critical path fell from 326 to 160 seconds; timing remains observational.
