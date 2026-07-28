# FEAT-0060 - Any-Consumer Governance CLI

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | [SUBF-0138](#subf-0138) first clean-room `CSharpShadow` vertical slice locally complete; exact-commit/hosted closure pending; full feature incomplete and PowerShell authority unchanged |
| Target version | 0.17.0 |
| Issue | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) |
| Pull request | [#160](https://github.com/hasanmanzak/meAndAI/pull/160) (draft; first clean-room shadow slice locally complete) |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) and [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md) |
| Tests | Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004); [TEST-0194](test-cases.md#test-0194), [TEST-0195](test-cases.md#test-0195), and [TEST-0196](test-cases.md#test-0196) remain `Planned` |
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

## Specification-first implementation boundary

[DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
makes the canonical protocol, accepted decisions, owning feature contracts,
and numbered scenarios the C# design authority. Project-local memory supplies
dated context and safe continuation routes only. PowerShell source is neither a
normative specification nor a line-by-line migration source; after a rule is
independently implemented, PowerShell may serve as a legacy black-box oracle.

The first authorized clean-room slice is [SUBF-0138](#subf-0138) and reuses canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
for the explicit `protocol-authority` profile. It reads repository state, checks
that every `FEAT-NNNN-*` directory contains `README.md` and `test-cases.md`,
emits a non-authoritative typed result, registers no provider or mutation port,
and follows expected-red then focused-green test-first delivery. No new
numbered scenario is allocated for the C# language implementation.

## Non-goals

- Automatic repair, adoption, update, GitHub publication, or mutation.
- Consumer-specific duplicated validators.
- General enumeration and content governance for all open/closed GitHub
  issues, pull requests, and comments; that provider feature requires the
  maintainer's separately reserved discussion and authorization.
- Retirement of PowerShell governance before equivalence and migration proof.

## Authority transition

- [SUBF-0122](#subf-0122), [SUBF-0123](#subf-0123),
  [SUBF-0124](#subf-0124), [SUBF-0134](#subf-0134),
  [SUBF-0135](#subf-0135), and [SUBF-0138](#subf-0138) run C# only as a
  read-only `CSharpShadow` against one
  captured repository input. Their output cannot replace the PowerShell result
  or authorize mutation.
- [SUBF-0136](#subf-0136) incrementally maps every applicable
  PowerShell-owned scenario and declared variant to equivalent, retained,
  not-applicable, infrastructure, or explicitly approved stronger C# evidence.
  It is not a prerequisite for bounded clean-room implementation or an
  explicitly non-authoritative package. Any missing or divergent mapping
  blocks equivalence and keeps `PowerShellAuthority`.
- [SUBF-0137](#subf-0137) may qualify an immutable C# release only as
  `CSharpReleasedNonAuthoritative`, without implying complete rule coverage or
  equivalence. Consumer authority changes only through
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
  severity/enforcement. [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
  then moved exhaustive variant normalization to the equivalence, authority,
  and retirement gates and authorized the bounded first clean-room slice.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0288` <a name="risk-0288"></a> | A C# validator reports green while omitting PowerShell-owned semantics. | Governance owner / complete scenario inventory, differential fixtures, and fail-closed unmapped contract handling. |
| `RISK-0289` <a name="risk-0289"></a> | Profiles become named-consumer policy forks. | Governance owner / capability-derived profiles and project-neutral fixtures. |

## Delivery findings

| ID | Boundary | Evidence | Status / response |
| --- | --- | --- | --- |
| `FIND-0365` <a name="find-0365"></a> | Canonical [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) process-tree fixture readiness / P1 | The records-only exact head [`9fa453b58a39817839beaff98927f7654419f950`](https://github.com/hasanmanzak/meAndAI/commit/9fa453b58a39817839beaff98927f7654419f950) passed the [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30358996927/job/90273817948), but its [Windows PowerShell 5.1 job](https://github.com/hasanmanzak/meAndAI/actions/runs/30358996927/job/90273818054) failed only at the canonical [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) startup boundary with `mock process tree did not start before cancellation.` The test, fixture, and production bounded-process blobs were unchanged from a prior passing head. A delayed-child variant then reproduced the exact failure locally: the child owned `child.pid`, the fixture parent imposed a separate five-second wait, and the outer harness neither observed early async completion nor surfaced `EndInvoke` errors. | Resolved. The fixture parent atomically publishes the exact `Start-Process -PassThru` child ID without a cross-process readiness handshake; the harness independently parses each identity, requires both processes active before cancellation, observes early completion, stops and drains a timed-out pipeline, and preserves bounded diagnostics and cleanup. Exact checkpoint [`7cfcdcb4bf320aec950147097086bba1978863d9`](https://github.com/hasanmanzak/meAndAI/commit/7cfcdcb4bf320aec950147097086bba1978863d9) passes PowerShell 7 / Windows PowerShell 5.1 StructureOnly in 184.3 / 292.4 seconds, the exact Windows streaming shard in 12.9 seconds, and its unchanged quick-adoption sibling in 482.4 seconds. Exact final head [`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186) passed [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016): [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016/job/90346608851) in 12 min 58 s and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016/job/90346609315) in 32 min 12 s, including a 30 min 46 s PowerShell 5.1 step. Production, retry, C# implementation, consumer, and authority behavior remained unchanged. |
| `FIND-0366` <a name="find-0366"></a> | Windows serial `Full` whole-job ceiling under [TEST-0124](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124) / test-infrastructure budget defect / `p1`, high severity, high impact, high confidence / dependency [FIND-0365](#find-0365) | Exact head [`39d6a0790e967293249dff2e32f5197a149added`](https://github.com/hasanmanzak/meAndAI/commit/39d6a0790e967293249dff2e32f5197a149added) selected `Full`; [run `30366875189`](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189) passed [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266387), skipped the [release verifier](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300267382) as expected, and canceled only the [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266379) at its exact 35-minute ceiling. The check annotation was `The job has exceeded the maximum execution time of 35m0s`; the displayed quick-adoption Git failures were emitted while cancellation was active and do not independently establish three defects, so they remain secondary unless reproduced by an uncancelled run. The nearest successful `Full` Windows evidence used 30 min 17 s for the PowerShell 5.1 step and 31 min 48 s for the job, leaving about three minutes of effective headroom. This repeats historical [FIND-0160](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0160). | Resolved. [TEST-0124](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124) first failed alone in 201 s while requiring 60 minutes against the unchanged 35-minute workflow, then passed in 176.9 s after only the Windows job ceiling changed to 60. Selector [TEST-0123](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0123), checksummed actionlint, the unchanged [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) owner on both runtimes, and candidate PowerShell 7 / Windows PowerShell 5.1 StructureOnly are green. Exact final head [`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186) passed [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016): Ubuntu in 12 min 58 s and Windows in 32 min 12 s, including a 30 min 46 s PowerShell 5.1 step. Linux remains 20 minutes, post-publication remains 5, and no retry, operation timeout, runner, matrix, profile, coverage route, production code, consumer, C#, PowerShell authority, or release behavior changed. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | First clean-room slice locally green; complete equivalence variants pending | Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [test scenarios](test-cases.md), and [readiness analysis](readiness-analysis.md) |
| Test code | First slice implemented | Expected compile-red in 7.9 s; final solution green in 6.4 s: governance 28/28, architecture 31/31, packaging 17/17 |
| Baseline run | Existing immutable baseline accepted | Exact-head [run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744), exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671), and post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0122` <a name="subf-0122"></a> | Versioned policy, profile, request, and authority-state identities | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0194](test-cases.md#test-0194) remains `Planned`; [SUBF-0138](#subf-0138) supplies only bounded internal building blocks | Pending | In progress / not complete |
| `SUBF-0123` <a name="subf-0123"></a> | Exact Git/index/worktree snapshot and repository-only profile-resolution CLI vertical slice | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Existing [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) plus [TEST-0194](test-cases.md#test-0194), which remains `Planned`; [SUBF-0138](#subf-0138) implements candidate snapshot only | Pending | In progress / not complete |
| `SUBF-0124` <a name="subf-0124"></a> | Versioned rule catalog, typed finding, deterministic report, and process contract | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0195](test-cases.md#test-0195) remains `Planned`; [SUBF-0138](#subf-0138) supplies only bounded internal building blocks | Pending | In progress / not complete |
| `SUBF-0134` <a name="subf-0134"></a> | Common pure governance kernel and `protocol-authority` self-consumer profile | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | First canonical rule proven by [SUBF-0138](#subf-0138); [TEST-0195](test-cases.md#test-0195) and remaining rule family stay `Planned` | Pending | In progress / not complete |
| `SUBF-0135` <a name="subf-0135"></a> | Project-neutral `consumer` profile and pinned-integration fixture | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Canonical mapped scenarios plus [TEST-0194](test-cases.md#test-0194) / [TEST-0195](test-cases.md#test-0195) / not started | Pending | Proposed / separate later gate |
| `SUBF-0136` <a name="subf-0136"></a> | Same-snapshot PowerShell/C# variant ledger and fail-closed differential harness | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0196](test-cases.md#test-0196) / not started | Pending | Mandatory before equivalence, authority transfer, or retirement |
| `SUBF-0137` <a name="subf-0137"></a> | Immutable portable-package qualification at non-authoritative state | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Existing [TEST-0193](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193) plus applicable focused C# tests / not started | Pending | Proposed / separate later gate |
| `SUBF-0138` <a name="subf-0138"></a> | Clean-room canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) vertical slice: `protocol-authority` candidate snapshot, required feature-record pair rule, deterministic report/exit, thin CLI, and repository-read-only adapter | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004); expected compile-red 7.9 s; final solution governance 28/28, architecture 31/31, packaging 17/17 in 6.4 s; locked restore, format, publish, and published-DLL self-run green | Pending exact-commit/hosted evidence | Locally complete; PowerShell authority unchanged |

## First-slice local implementation evidence

[SUBF-0138](#subf-0138) adds a separate
[`MeAndAI.Operations.Governance.Core`](../../../src/MeAndAI.Operations.Governance.Core/MeAndAI.Operations.Governance.Core.csproj)
class library, keeps the
[`MeAndAI.Operations.Governance`](../../../src/MeAndAI.Operations.Governance/MeAndAI.Operations.Governance.csproj)
console thin, and places the filesystem implementation behind a repository-read
port. The first production behavior is the canonical required feature-record
pair rule; it does not inspect or call PowerShell.

- The focused governance test command first failed to compile in 7.9 seconds
  because the new governance domain/core types did not exist.
- The same focused command first passed 12/12 in 6.1 seconds. After boundary
  expansion and fresh-review corrections, the final focused suite passed
  28/28 in 5.5 seconds. The final full-solution rerun passed governance 28/28,
  architecture 31/31, and packaging 17/17 in 6.4 seconds.
- Fresh review added wrong-case filename behavior plus fail-closed root,
  feature-directory, required-file, dangling/non-directory link cases at exact
  `docs` and `docs/features`, and drive-relative `C:outside` rejection. It separated
  `evidenceDigest` from `catalogMetadataDigest`, declared
  `coverage=bounded-first-slice`, and centralized repository-relative finding
  path validation.
- Locked restore passed in 2.5 seconds, format verification in 14.1 seconds,
  and portable publish in 2.5 seconds without an apphost.
- The first PowerShell 7 `StructureOnly` pass exposed 15 canonical
  [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  link defects only in the new records. After correcting those links, final
  PowerShell 7 and Windows PowerShell 5.1 `StructureOnly` passed in 159.3 and
  236.9 seconds.
- The published DLL validated the real repository in 0.5 seconds with exit
  `0`, `conforming`, one evaluated rule, zero findings,
  `csharp-shadow`, `powershell-authority`, deterministic digest, and no
  absolute path in the public report.

These results complete canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
for this C# slice. They do not activate [TEST-0194](test-cases.md#test-0194)
or [TEST-0195](test-cases.md#test-0195); both remain literal `Planned`
documentation scenarios with no active C# source ownership.

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Specification-first sequencing: [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
- Readiness detail: [Definition-of-Ready analysis](readiness-analysis.md)

## Definition of Ready

- [x] Stable feature/slice identity and linked issue.
- [x] Problem, outcome, scope, non-goals, and measurable first-slice outcome.
- [x] Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
  behavior, positive/missing-file boundaries, and test-first route.
- [x] `protocol-authority`, repository-read-only, provider-free,
  non-authoritative capability boundary.
- [x] Affected feature-packet domain concept, governance CLI entry point,
  existing C# foundation dependency, and meAndAI self-consumer are identified;
  type, ownership, lifecycle, deterministic finding/report, failure, and
  compatibility contracts are bounded for the slice.
- [x] `RISK-0288` and `RISK-0289` remain owned; the first slice introduces no
  consumer-specific policy or authority claim.
- [x] Canonical specification ownership under
  [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md),
  with memory as context and PowerShell only as a later black-box oracle.
- [x] Recurrence and same-contract sibling review preserve canonical
  [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
  rather than allocating a duplicate identity.
- [x] The first rule is an independently reviewable vertical slice with a
  bounded implementation and verification approach.
- [x] Explicit maintainer authorization on 2026-07-28 for only the first
  clean-room `CSharpShadow` vertical slice.

The bounded first-slice Definition of Ready is complete, 10/10 (100%).
[SUBF-0138](#subf-0138) is locally complete, so implementation is one of eight
subfeatures (12.5%); exact-commit/hosted closure and the other seven subfeatures
remain. Historical inventory remains 188/188 base identities and 7/7
declaration packets, with 172/188 scenario routes unambiguous and 16/188 mixed.
Those ledger and matrix gaps are mandatory before equivalence, authority
transfer, or retirement, not before this slice. See the
[sequencing and remaining gates](readiness-analysis.md#remaining-definition-of-ready-gates).

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

[SUBF-0138](#subf-0138) is locally implemented and verified; its exact-commit
and hosted gates remain pending. The other seven subfeatures, full-feature
review/CI, equivalence ledger, release, migration, authority, and retirement
gates remain incomplete.
