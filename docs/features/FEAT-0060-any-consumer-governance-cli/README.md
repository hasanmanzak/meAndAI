# FEAT-0060 - Any-Consumer Governance CLI

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Definition-of-Ready analysis in progress / development not authorized |
| Target version | 0.17.0 |
| Issue | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) |
| Pull request | [#160](https://github.com/hasanmanzak/meAndAI/pull/160) (draft, records only) |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) |
| Tests | [TEST-0194](test-cases.md#test-0194), [TEST-0195](test-cases.md#test-0195), and [TEST-0196](test-cases.md#test-0196) |
| Readiness analysis | [Definition-of-Ready analysis](readiness-analysis.md), [differential-ledger inventory](differential-ledger-analysis.md), [rule/profile matrix](rule-profile-matrix-analysis.md), and [v1 decision packet](contract-decision-packet.md) |

## Problem

Governance validation is difficult for the maintainer to review and is coupled
to PowerShell runtime behavior even when the governed evidence is technology
neutral.

## Outcome

A read-only C# application validates meAndAI itself and arbitrary consumers
through explicit profiles, structured results, and one canonical governance
engine without repository or GitHub mutation authority.

## Scope

- Repository discovery, governance profile selection, structural and semantic
  validation, instruction graph inspection, scenario ownership, links, ledgers,
  markers, release contracts, and machine-readable reports.
- Explicit caller-selected and engine-verified `protocol-authority` and
  `consumer` profiles derived from canonical contracts rather than automatic
  detection or named-project allowlists.
- Versioned policy identity, canonical repository snapshot, deterministic
  typed findings, and a byte-stable report envelope.
- Differential evidence against applicable PowerShell governance authority.

## Non-goals

- Automatic repair, adoption, update, GitHub publication, or mutation.
- Consumer-specific duplicated validators.
- General enumeration and content governance for all open/closed GitHub
  issues, pull requests, and comments; that provider feature requires the
  maintainer's separately reserved discussion and authorization.
- Retirement of PowerShell governance before equivalence and migration proof.

## Authority transition

- [SUBF-0122](#subf-0122), [SUBF-0123](#subf-0123),
  [SUBF-0124](#subf-0124), [SUBF-0134](#subf-0134), and
  [SUBF-0135](#subf-0135) run C# only as a read-only `CSharpShadow` against one
  captured repository input. Their output cannot replace the PowerShell result
  or authorize mutation.
- [SUBF-0136](#subf-0136) maps every applicable PowerShell-owned scenario and
  declared variant to equivalent, retained, not-applicable, infrastructure, or
  explicitly approved stronger C# evidence. Any missing or divergent mapping
  keeps `PowerShellAuthority`.
- [SUBF-0137](#subf-0137) may qualify an immutable C# release only as
  `CSharpReleasedNonAuthoritative`. Consumer authority changes only through
  the explicit migration owned by
  [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md).
- Read-only dual execution is allowed; governance never gains a repair or
  mutation fallback. PowerShell validation contracts remain live for the
  supported scope until that migration and dependency proof complete.

## Readiness evidence

- Dependency: immutable
  [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) / `v0.16.0`
  at
  [`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
- The [readiness analysis](readiness-analysis.md) inventories current owners,
  rule families, snapshot/profile/report contracts, immutable baseline,
  recurrence barriers, and the bounded authority progression.
- The [differential-ledger inventory](differential-ledger-analysis.md) accounts
  for all 188 active base identities, all seven explicit declaration packets,
  195 declaration-level units, and a separate proven lower bound of 116
  TEST/case mappings. It identifies the absence of a global
  inline/generative variant denominator rather than claiming a ledger size or
  false completeness before the row-shape decision.
- The [rule/profile matrix](rule-profile-matrix-analysis.md) classifies all 188
  base identities: 43 C# candidates, 16 mixed boundaries, 94 retained
  PowerShell operations, 29 infrastructure contracts, three provider-owned
  identities, and three existing C# foundation identities.
- The maintainer accepted the [v1 decision packet](contract-decision-packet.md)
  on 2026-07-28, including exact-pair shadow/release eligibility and separate
  severity/enforcement. The remaining material variants can now be normalized.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0288` <a name="risk-0288"></a> | A C# validator reports green while omitting PowerShell-owned semantics. | Governance owner / complete scenario inventory, differential fixtures, and fail-closed unmapped contract handling. |
| `RISK-0289` <a name="risk-0289"></a> | Profiles become named-consumer policy forks. | Governance owner / capability-derived profiles and project-neutral fixtures. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Refined; exact variant ledger pending | [Test scenarios](test-cases.md) and [readiness analysis](readiness-analysis.md) |
| Test code | Not started | Development not authorized |
| Baseline run | Existing immutable baseline accepted | Exact-head [run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744), exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671), and post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0122` <a name="subf-0122"></a> | Versioned policy, profile, request, and authority-state identities | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0194](test-cases.md#test-0194) / not started | Pending | Proposed / development not authorized |
| `SUBF-0123` <a name="subf-0123"></a> | Exact repository snapshot and repository-only profile-resolution CLI vertical slice | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Existing [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) plus [TEST-0194](test-cases.md#test-0194) / not started | Pending | Proposed / development not authorized |
| `SUBF-0124` <a name="subf-0124"></a> | Versioned rule catalog, typed finding, deterministic report, and process contract | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0195](test-cases.md#test-0195) / not started | Pending | Proposed / development not authorized |
| `SUBF-0134` <a name="subf-0134"></a> | Common pure governance kernel and `protocol-authority` self-consumer profile | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Canonical mapped scenarios plus [TEST-0195](test-cases.md#test-0195) / not started | Pending | Proposed / development not authorized |
| `SUBF-0135` <a name="subf-0135"></a> | Project-neutral `consumer` profile and pinned-integration fixture | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Canonical mapped scenarios plus [TEST-0194](test-cases.md#test-0194) / [TEST-0195](test-cases.md#test-0195) / not started | Pending | Proposed / development not authorized |
| `SUBF-0136` <a name="subf-0136"></a> | Same-snapshot PowerShell/C# variant ledger and fail-closed differential harness | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0196](test-cases.md#test-0196) / not started | Pending | Proposed / development not authorized |
| `SUBF-0137` <a name="subf-0137"></a> | Immutable portable-package qualification at non-authoritative state | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Existing [TEST-0193](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193) plus [TEST-0196](test-cases.md#test-0196) / not started | Pending | Proposed / development not authorized |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Readiness detail: [Definition-of-Ready analysis](readiness-analysis.md)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, non-goals, initial scenarios, and risks.
- [x] Target `0.17.0`, immutable baseline, owner/rule-family inventory,
  recurrence review, sibling-intent review, and independently reviewable
  decomposition.
- [ ] Complete material-variant ledger and rule-by-rule
  profile/applicability/evidence-source matrix; scenario-level inventory is
  complete, but inline/generative expansion and 16 mixed boundaries still
  require normalization under the accepted granularity contract.
- [x] Maintainer acceptance of the v1 request, snapshot, profile, report,
  exact-pair policy/runtime, severity/enforcement, digest, and exit-code
  contract.
- [ ] Separate executable development authorization.

Readiness is nine of twelve items, or 75%; implementation is zero of seven
subfeatures, or 0%. Base identity and explicit declaration-packet inventory is
100%; scenario-level route classification is 91.5% unambiguous and 8.5% mixed.
See the [remaining gates and estimation boundary](readiness-analysis.md#remaining-definition-of-ready-gates).

## Acceptance criteria

1. The governance application has no repository or GitHub mutation capability.
2. The same engine validates meAndAI and project-neutral consumers through
   caller-selected, engine-verified capability profiles.
3. Every transferred canonical scenario has equivalent or stronger executable evidence and unmapped authority blocks transfer.
4. Reports are deterministic, typed, redacted, and useful to local and hosted callers.
5. Repository bytes follow the existing HEAD/index/worktree precedence and
   ambiguous or drifting state fails closed.
6. General live GitHub issue/PR/comment governance remains outside this feature
   unless separately discussed and authorized.

## Definition of Done

All implementation, review, CI, migration, documentation, and release gates remain pending.
