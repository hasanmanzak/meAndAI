# FEAT-0060 - Any-Consumer Governance CLI

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | [SUBF-0138](#subf-0138), [SUBF-0134](#subf-0134), [SUBF-0122](#subf-0122), and [SUBF-0124](#subf-0124) fully complete with exact hosted evidence; four of seven bounded subfeatures closed (57.1%); PowerShell authority unchanged |
| Target version | 0.17.0 |
| Issue | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) |
| Pull request | [#160](https://github.com/hasanmanzak/meAndAI/pull/160) (draft; four bounded shadow slices complete with exact hosted evidence) |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md), and [DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md) |
| Tests | Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) and [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005) are implemented in the bounded C# catalog; bounded identity/request [TEST-0194](test-cases.md#test-0194) and report/process [TEST-0195](test-cases.md#test-0195) are exact hosted complete; exact profile-evidence [TEST-0208](test-cases.md#test-0208) remains `Planned` |
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

- One parse-once, immutable repository/document analysis context shared by the
  bounded rule catalog without duplicate grammar, index, finding, serializer,
  snapshot-reader, or fixture implementations.
- Explicit caller-selected and engine-verified `protocol-authority` and
  canonical `.ai/protocol` gitlink `consumer` profiles derived from canonical
  contracts rather than automatic detection or named-project allowlists.
- An `exact-commit` release snapshot, versioned policy identity, canonical
  [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
  feature packet validation, canonical
  [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
  decision-record validation, deterministic typed findings, and a byte-stable
  bounded-coverage report envelope.
- One portable framework-dependent `maai-governance.zip`, eligible only for
  `CSharpReleasedNonAuthoritative` use.

## Specification-first implementation boundary

[DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
makes the canonical protocol, accepted decisions, owning feature contracts,
and numbered scenarios the C# design authority. Project-local memory supplies
dated context and safe continuation routes only. PowerShell source is neither a
normative specification nor a line-by-line migration source; after a rule is
independently implemented, PowerShell may serve as a legacy black-box oracle.

The first clean-room slice was [SUBF-0138](#subf-0138) and reuses canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
for the explicit `protocol-authority` profile. It reads repository state, checks
that every `FEAT-NNNN-*` directory contains `README.md` and `test-cases.md`,
emits a non-authoritative typed result, registers no provider or mutation port,
and follows expected-red then focused-green test-first delivery. No new
numbered scenario is allocated for the C# language implementation. The
maintainer subsequently authorized the complete bounded MVP defined by
[DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md);
that authorization does not extend to
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md)
equivalence work, migration,
authority transfer, or PowerShell retirement.

[SUBF-0134](#subf-0134) now implements the second bounded rule from canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
through one shared parse-once repository/document analysis context. The rule
remains distinct from canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004),
while both rules reuse the same document metadata, heading, path, and snapshot
analysis primitives. Exact committed-tree verification and exact-head hosted
[run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192)
are green on Ubuntu and Windows. The PowerShell authority state is unchanged.

## Non-goals

- Automatic repair, adoption, update, GitHub publication, or mutation.
- Consumer-specific duplicated validators.
- General enumeration and content governance for all open/closed GitHub
  issues, pull requests, and comments; that provider feature requires the
  maintainer's separately reserved discussion and authorization.
- Full HEAD/index/worktree candidate overlay, repository-reference consumer
  integration, remaining governance rule families, and exhaustive
  PowerShell/C# equivalence; these are owned by
  [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md).
- Retirement of PowerShell governance before equivalence and migration proof.

## Authority transition

- [SUBF-0122](#subf-0122), [SUBF-0123](#subf-0123),
  [SUBF-0124](#subf-0124), [SUBF-0134](#subf-0134),
  [SUBF-0135](#subf-0135), and [SUBF-0138](#subf-0138) run C# only as a
  read-only `CSharpShadow` against one
  captured repository input. Their output cannot replace the PowerShell result
  or authorize mutation.
- [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md)
  incrementally maps every applicable PowerShell-owned scenario and declared
  variant to equivalent, retained, not-applicable, infrastructure, or
  explicitly approved stronger C# evidence. Any missing or divergent mapping
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
- On 2026-07-29 the maintainer accepted
  [DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md):
  this feature now closes the exact bounded catalog and portable
  non-authoritative package, while
  [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md) owns full
  candidate, remaining-coverage, and equivalence qualification.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0288` <a name="risk-0288"></a> | A bounded C# validator result is mistaken for complete governance coverage. | Governance owner / bind the exact two-rule inventory and catalog digest into every report, label coverage bounded, and leave equivalence and authority gates fail-closed under [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md). |
| `RISK-0289` <a name="risk-0289"></a> | Profiles become named-consumer policy forks. | Governance owner / capability-derived profiles and project-neutral fixtures. |

## Delivery findings

| ID | Boundary | Evidence | Status / response |
| --- | --- | --- | --- |
| `FIND-0365` <a name="find-0365"></a> | Canonical [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) process-tree fixture readiness / P1 | The records-only exact head [`9fa453b58a39817839beaff98927f7654419f950`](https://github.com/hasanmanzak/meAndAI/commit/9fa453b58a39817839beaff98927f7654419f950) passed the [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30358996927/job/90273817948), but its [Windows PowerShell 5.1 job](https://github.com/hasanmanzak/meAndAI/actions/runs/30358996927/job/90273818054) failed only at the canonical [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) startup boundary with `mock process tree did not start before cancellation.` The test, fixture, and production bounded-process blobs were unchanged from a prior passing head. A delayed-child variant then reproduced the exact failure locally: the child owned `child.pid`, the fixture parent imposed a separate five-second wait, and the outer harness neither observed early async completion nor surfaced `EndInvoke` errors. | Resolved. The fixture parent atomically publishes the exact `Start-Process -PassThru` child ID without a cross-process readiness handshake; the harness independently parses each identity, requires both processes active before cancellation, observes early completion, stops and drains a timed-out pipeline, and preserves bounded diagnostics and cleanup. Exact checkpoint [`7cfcdcb4bf320aec950147097086bba1978863d9`](https://github.com/hasanmanzak/meAndAI/commit/7cfcdcb4bf320aec950147097086bba1978863d9) passes PowerShell 7 / Windows PowerShell 5.1 StructureOnly in 184.3 / 292.4 seconds, the exact Windows streaming shard in 12.9 seconds, and its unchanged quick-adoption sibling in 482.4 seconds. Exact final head [`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186) passed [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016): [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016/job/90346608851) in 12 min 58 s and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016/job/90346609315) in 32 min 12 s, including a 30 min 46 s PowerShell 5.1 step. Production, retry, C# implementation, consumer, and authority behavior remained unchanged. |
| `FIND-0366` <a name="find-0366"></a> | Windows serial `Full` whole-job ceiling under [TEST-0124](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124) / test-infrastructure budget defect / `p1`, high severity, high impact, high confidence / dependency [FIND-0365](#find-0365) | Exact head [`39d6a0790e967293249dff2e32f5197a149added`](https://github.com/hasanmanzak/meAndAI/commit/39d6a0790e967293249dff2e32f5197a149added) selected `Full`; [run `30366875189`](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189) passed [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266387), skipped the [release verifier](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300267382) as expected, and canceled only the [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266379) at its exact 35-minute ceiling. The check annotation was `The job has exceeded the maximum execution time of 35m0s`; the displayed quick-adoption Git failures were emitted while cancellation was active and do not independently establish three defects, so they remain secondary unless reproduced by an uncancelled run. The nearest successful `Full` Windows evidence used 30 min 17 s for the PowerShell 5.1 step and 31 min 48 s for the job, leaving about three minutes of effective headroom. This repeats historical [FIND-0160](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0160). | Resolved. [TEST-0124](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124) first failed alone in 201 s while requiring 60 minutes against the unchanged 35-minute workflow, then passed in 176.9 s after only the Windows job ceiling changed to 60. Selector [TEST-0123](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0123), checksummed actionlint, the unchanged [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) owner on both runtimes, and candidate PowerShell 7 / Windows PowerShell 5.1 StructureOnly are green. Exact final head [`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186) passed [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016): Ubuntu in 12 min 58 s and Windows in 32 min 12 s, including a 30 min 46 s PowerShell 5.1 step. Linux remains 20 minutes, post-publication remains 5, and no retry, operation timeout, runner, matrix, profile, coverage route, production code, consumer, C#, PowerShell authority, or release behavior changed. |
| `FIND-0367` <a name="find-0367"></a> | Bounded-scope record relocation / structural governance | Exact committed records checkpoint [`97c8c63`](https://github.com/hasanmanzak/meAndAI/commit/97c8c633f7268cd74d189191df48a6bfbc6ebddf) first failed only [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) because planned [TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196) still named the old owner in `tests/scenario-ownership.psd1`. After moving that authority, the same gate exposed 110 then 23 [TEST-0003](../FEAT-0001-common-development-protocol/test-cases.md#test-0003) / [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175) defects in moved targets, new scope banners, and repeated visible IDs. | Resolved. [TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196) has one canonical [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md) declaration/authority; former local targets link to it and visible stable IDs use exact canonical links. Exact checkpoint [`a4231a2`](https://github.com/hasanmanzak/meAndAI/commit/a4231a2d4d6ff1068092c0f7b4c8304aaef5ceb4) passed PowerShell 7 / Windows PowerShell 5.1 `StructureOnly` in 178.0 / 253.4 seconds, with protocol-governance elapsed 175.753 / 250.869 seconds and zero remaining problems. |
| `FIND-0368` <a name="find-0368"></a> | [SUBF-0134](#subf-0134) shared analysis and bounded-report fresh review | Fresh review of the first combined [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) / [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005) green result found fenced metadata, incomplete evaluated-rule inventory, and decision-link fail-closed gaps. Independent re-review then found over-broad eager parsing of unrelated Markdown, unhandled invalid UTF-8 for a numbered decision, HTML-comment structure that could falsely satisfy the rule, and fence-info/comment state leakage that could hide later real structure. | Resolved. One protocol-record index owns path grammar; the shared document index parses only its numbered decision entries, excludes fenced and HTML-comment content from structure, and isolates fence/comment state. Unrelated invalid UTF-8 is outside the bounded catalog, targeted invalid UTF-8 produces a controlled operational failure with no verdict, reports bind exact `evaluatedRuleIds` with `coverage=bounded-catalog`, and decision symlink/dangling cases fail closed. Exact checkpoint [`a4231a2`](https://github.com/hasanmanzak/meAndAI/commit/a4231a2d4d6ff1068092c0f7b4c8304aaef5ceb4) passed full solution governance 62/62, architecture 31/31, packaging 17/17, repository-only [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) in 64.6 seconds, both `StructureOnly` runtimes, published-DLL self-consumption, locked restore, format verification, and framework-dependent publish without apphost. Exact final head [`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110) passed hosted [run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192) on Ubuntu and Windows. |
| `FIND-0369` <a name="find-0369"></a> | Exact-head publication evidence / P1 | On exact head [`990b634`](https://github.com/hasanmanzak/meAndAI/commit/990b6346c7a1f7455872c2164a54dc7d7fe4223a), [run `30406017573`](https://github.com/hasanmanzak/meAndAI/actions/runs/30406017573) passed every C# build, test, package, and Linux package-reuse step. Both long PowerShell `Full` routes then failed only at [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178): tracked Markdown contained two human-facing commit-reference problems because [FIND-0367](#find-0367) used a short commit target. | Resolved by replacing the short target with the exact full-SHA permalink. Exact checkpoint [`a4231a2`](https://github.com/hasanmanzak/meAndAI/commit/a4231a2d4d6ff1068092c0f7b4c8304aaef5ceb4) passed the focused repository-only [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) owner in 64.6 seconds and both `StructureOnly` runtimes; exact final head [`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110) passed hosted [run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192) on Ubuntu and Windows. No C#, PowerShell, workflow, consumer, or authority behavior changed for this evidence correction. |
| `FIND-0370` <a name="find-0370"></a> | [TEST-0194](test-cases.md#test-0194) hosted execution route / P1 | Exact implementation head [`c2236b1`](https://github.com/hasanmanzak/meAndAI/commit/c2236b10328f78c0285d966c4b14ea70b9216d6e) passed 69/69 focused tests and compiled the new governance code in both hosted jobs, but inspection found that both C# workflow filters still selected only the three operational-foundation scenarios and omitted [TEST-0194](test-cases.md#test-0194). A green C# step therefore could not prove execution of the bounded contract. | Resolved. A same-owner C# route regression first failed `Expected: 2`, `Actual: 0`; both existing Ubuntu and Windows filters now include [TEST-0194](test-cases.md#test-0194), and the focused suite passes 70/70. Exact committed-tree [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) then rejected the first assertion because its literal full-filter match repeated three sibling scenario identities; the assertion now verifies only its owned identity across both existing filters. Exact head [`603823e`](https://github.com/hasanmanzak/meAndAI/commit/603823e5e6521e009d6b50e77d602b812ea1da6d) passed hosted [run `30419091904`](https://github.com/hasanmanzak/meAndAI/actions/runs/30419091904) on Ubuntu and Windows, and both logs prove that the existing C# step selected the owned scenario. No job, matrix, runner, package, PowerShell route, consumer behavior, or authority changed. |
| `FIND-0371` <a name="find-0371"></a> | [SUBF-0124](#subf-0124) closure-record Markdown / P1 | Closure-record head [`8cb4fa4`](https://github.com/hasanmanzak/meAndAI/commit/8cb4fa4549ef8ccd3f3eb59ded531012e79e89fa) passed its C# and package gates in hosted [run `30427450155`](https://github.com/hasanmanzak/meAndAI/actions/runs/30427450155), but Ubuntu failed only [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178): six visible copies of one Git tree-object SHA-1 were shaped like human-facing commit references even though the object was not a commit. | Corrected; exact-head confirmation required. The non-commit object identifier is removed from human-facing prose while the linked PR-head and tested-merge commit permalinks continue to state and prove exact tree equality. The focused repository-only [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) owner is the correction gate. No C#, package, workflow, PowerShell, consumer, or authority behavior changes. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Bounded MVP ready; its two canonical rules are locally implemented; full coverage/equivalence is outside this feature | Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), canonical [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0194](test-cases.md#test-0194), [TEST-0195](test-cases.md#test-0195), and [TEST-0208](test-cases.md#test-0208) |
| Test code | Four slices exact hosted green | [TEST-0194](test-cases.md#test-0194) is closed on [`603823e`](https://github.com/hasanmanzak/meAndAI/commit/603823e5e6521e009d6b50e77d602b812ea1da6d) / hosted [run `30419091904`](https://github.com/hasanmanzak/meAndAI/actions/runs/30419091904). [TEST-0195](test-cases.md#test-0195) expected-red failed in 11.2 seconds with `CS0246`; after fresh-review corrections the exact implementation head [`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99) passes focused 25/25, full solution governance 155/155, architecture 31/31, packaging 17/17, and both exact-tree structural runtimes; hosted [run `30424139722`](https://github.com/hasanmanzak/meAndAI/actions/runs/30424139722) supplies tree-equivalent merge evidence. |
| Baseline run | Latest hosted exact-tree-equivalent baseline accepted for continuation | [Run `30424139722`](https://github.com/hasanmanzak/meAndAI/actions/runs/30424139722), associated with PR head [`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99), and tested merge commit [`9582a4a`](https://github.com/hasanmanzak/meAndAI/commit/9582a4aabb67dfcf9adf291a7eb2b781cf8c4a04); both commits resolve to the same exact Git tree. Ubuntu passed in 8 min 37 s and Windows in 33 min 52 s, including explicit [TEST-0195](test-cases.md#test-0195) selection and the supported PowerShell validation routes. |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0122` <a name="subf-0122"></a> | Versioned bounded catalog, profile, request, application-policy-pair, and authority-state identities | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0194](test-cases.md#test-0194) expected-red `CS0234` / `CS0246`; focused 70/70 green after review and [FIND-0370](#find-0370) route corrections; catalog metadata, bounded version/tag, hex grammar, and candidate eligibility each have one production owner; distinct Git/profile evidence remains in [TEST-0208](test-cases.md#test-0208); exact head [`603823e`](https://github.com/hasanmanzak/meAndAI/commit/603823e5e6521e009d6b50e77d602b812ea1da6d) passed hosted [run `30419091904`](https://github.com/hasanmanzak/meAndAI/actions/runs/30419091904) | Complete; no open Blocking finding | Complete; PowerShell authority unchanged |
| `SUBF-0123` <a name="subf-0123"></a> | Exact-commit snapshot and explicit profile-resolution CLI vertical slice | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Existing [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) plus [TEST-0208](test-cases.md#test-0208), which remains `Planned`; full candidate overlay is excluded | Pending | In progress / not complete |
| `SUBF-0124` <a name="subf-0124"></a> | Versioned rule catalog, typed finding, deterministic report, and process contract | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0195](test-cases.md#test-0195) expected-red `CS0246`; focused 25/25 and full solution governance 155/155, architecture 31/31, packaging 17/17 after independent review; exact implementation head [`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99) passed exact-tree gates and has tree-equivalent hosted merge evidence in [run `30424139722`](https://github.com/hasanmanzak/meAndAI/actions/runs/30424139722) | Fresh review complete; no open recorded finding | Complete; PowerShell authority unchanged |
| `SUBF-0134` <a name="subf-0134"></a> | Parse-once repository/document kernel and the exact [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) / [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005) `protocol-authority` rules | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Expected-red `CS0234` / `CS0246`; first combined green 53/53; [FIND-0368](#find-0368) resolved after independent re-review; exact local [`a4231a2`](https://github.com/hasanmanzak/meAndAI/commit/a4231a2d4d6ff1068092c0f7b4c8304aaef5ceb4) gates and exact final [`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110) hosted [run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192) green | Complete | Complete; PowerShell authority unchanged |
| `SUBF-0135` <a name="subf-0135"></a> | Project-neutral canonical `.ai/protocol` gitlink `consumer` profile and pinned-integration fixture | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Canonical mapped scenarios plus [TEST-0208](test-cases.md#test-0208) / [TEST-0195](test-cases.md#test-0195) / not started | Pending | Proposed / separate later gate |
| `SUBF-0137` <a name="subf-0137"></a> | Immutable portable-package qualification at non-authoritative state | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Existing [TEST-0193](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193) plus applicable focused C# tests / not started | Pending | Proposed / separate later gate |
| `SUBF-0138` <a name="subf-0138"></a> | Clean-room canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) vertical slice: `protocol-authority` candidate snapshot, required feature-record pair rule, deterministic report/exit, thin CLI, and repository-read-only adapter | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | Local test-first, locked restore, format, publish, real self-run, both StructureOnly runtimes, and exact-head hosted [run `30394623671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30394623671) green | Complete | Complete; PowerShell authority unchanged |

The former local [SUBF-0136](../FEAT-0064-governance-coverage-equivalence/README.md#subf-0136)
differential slice moved to its single canonical record in
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md).
This sentence is navigation only and does not declare a second subfeature
identity.

## Implemented-slice evidence

### [SUBF-0138](#subf-0138) exact-head closure

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
- Exact head
  [`393aaa561d0133aba7522083617564e1dca76fe2`](https://github.com/hasanmanzak/meAndAI/commit/393aaa561d0133aba7522083617564e1dca76fe2)
  passed hosted [run `30394623671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30394623671):
  Ubuntu completed in 13 min 57 s and Windows in 33 min 26 s, including the
  PowerShell Full compatibility gates. The release verifier skipped as
  expected for the pull request.

These results complete canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
for this C# slice.

### [SUBF-0134](#subf-0134) shared-kernel exact-head closure

[SUBF-0134](#subf-0134) replaces per-rule repository/document parsing with
one immutable analysis context and adds the canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
decision-record rule without reading or translating the PowerShell
implementation.

- The focused governance test command first exited `1` with `CS0234` and
  `CS0246` because the `Analysis` namespace and `GovernanceAnalysisContext`
  did not exist. The first combined implementation passed 53/53.
- Fresh review and independent re-review produced and resolved
  [FIND-0368](#find-0368): fenced and HTML-comment structure is excluded,
  fence/comment state is isolated, only indexed numbered decisions are parsed,
  invalid UTF-8 has bounded fail-closed behavior, reports contain exact
  `evaluatedRuleIds` with `coverage=bounded-catalog`, and decision
  symlink/dangling paths fail closed. The final focused suite passed 62/62.
- The final full-solution run passed governance 62/62, architecture 31/31,
  and packaging 17/17. Locked restore and format verification are also green.
- Framework-dependent publish succeeded without an apphost. Running the
  published DLL against the real repository returned `conforming` with two
  evaluated rules, zero findings, and `bounded-catalog` coverage.
- Exact final head
  [`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110)
  passed hosted [run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192)
  on Ubuntu and Windows.

This evidence implements canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
and preserves the already implemented canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
behavior through the shared kernel. Exact committed-tree and exact-head hosted
closure are green. Neither result activates
[TEST-0194](test-cases.md#test-0194), [TEST-0195](test-cases.md#test-0195), or
[TEST-0208](test-cases.md#test-0208) at that historical checkpoint. At the later
[SUBF-0122](#subf-0122) checkpoint, only [TEST-0194](test-cases.md#test-0194)
was active; [TEST-0195](test-cases.md#test-0195) and
[TEST-0208](test-cases.md#test-0208) remained literal `Planned` documentation
scenarios. The subsequent [SUBF-0124](#subf-0124) section records activation and
closure of [TEST-0195](test-cases.md#test-0195).

### [SUBF-0122](#subf-0122) exact-head identity-contract closure

[SUBF-0122](#subf-0122) now implements only the repository-independent
[TEST-0194](test-cases.md#test-0194) contract. It does not claim exact Git
object evidence, consumer repository evidence, package qualification,
publication, equivalence, authority transfer, or PowerShell retirement.

- The focused expected-red failed in 9.6 seconds with `CS0234` / `CS0246`
  because the typed request, identity, policy, and bundle contracts did not
  exist. The final focused local run passes 70/70, including the hosted-route
  contract from [FIND-0370](#find-0370).
- The final local full-solution run passes governance 132/132, architecture
  31/31, and packaging 17/17.
- Locked restore and format verification pass. The first PowerShell 7
  `StructureOnly` run found only an unlinked subfeature identity in the newly
  appended memory heading; after linking it to this canonical record,
  PowerShell 7 and Windows PowerShell 5.1 pass in 189.1 and 274.3 seconds.
- Framework-dependent publish produces no apphost. The published DLL validates
  the real repository as `conforming` with the exact catalog digest, two rules,
  zero findings, `csharp-shadow`, and `powershell-authority`.
- One Domain-owned lowercase-ASCII-hex matcher serves exact commit and SHA-256
  digest identities, and packaging references those same types. Each rule owns
  its canonical metadata once; the bounded contract owns the protocol version
  and derived tag once; the catalog alone serializes its ordered metadata and
  derives its digest.
- The public request accepts only profile plus exact commit and fixes
  `exact-commit` / `repository` evidence. Candidate snapshot construction and
  evaluation remain internal. Both profiles map to the same rule instances,
  while the current candidate CLI and evaluator reject `consumer` before
  repository access because [TEST-0208](test-cases.md#test-0208) is still
  planned.
- A matching immutable-release binding remains a hypothetical identity proof;
  no released engine or qualified `maai-governance.zip` is asserted.
- Exact committed-tree reruns on
  [`603823e`](https://github.com/hasanmanzak/meAndAI/commit/603823e5e6521e009d6b50e77d602b812ea1da6d)
  passed the focused 70/70 identity suite, the full 132/132 governance,
  31/31 architecture, and 17/17 packaging suites, locked restore, format,
  PowerShell 7 / Windows PowerShell 5.1 `StructureOnly` in 186.6 / 272.4
  seconds, and the repository-only publication-evidence owner.
- The same exact head passed hosted
  [run `30419091904`](https://github.com/hasanmanzak/meAndAI/actions/runs/30419091904):
  Ubuntu completed in 13 min 33 s and Windows in 25 min 54 s. Both C# logs
  explicitly selected [TEST-0194](test-cases.md#test-0194) and passed 70/70
  governance, 31/31 architecture, and 17/17 packaging tests. The supported
  PowerShell routes also passed and the release verifier skipped as expected.

At this [SUBF-0122](#subf-0122) checkpoint, the third of seven bounded
subfeatures closed (42.9%) and four remained open. The subsequent
[SUBF-0124](#subf-0124) checkpoint advances the current numerator; PowerShell
remains authoritative throughout.

### [SUBF-0124](#subf-0124) exact hosted report/process closure

[SUBF-0124](#subf-0124) activates [TEST-0195](test-cases.md#test-0195) without
adding a second engine, serializer, report envelope, exit map, or fixture
family.

- The focused expected-red failed in 11.2 seconds with `CS0246` because the
  report factory and rule-evaluation types did not exist.
- `GovernanceEngine` now only executes the two catalog rules. One report
  factory validates exact catalog-identity references, rejects missing,
  changed, duplicate, or mismatched evaluations as `incomplete`, orders safe
  findings, computes counts/verdict, and alone constructs the existing report.
- Each finding forwards rule, canonical scenario/owner, code, severity, and
  enforcement from its one catalog identity. A shared rule helper binds a
  typed repository-relative location to a `content-object` or `snapshot`
  evidence scope plus exact SHA-256, with no snippets or machine paths.
- The existing serializer remains the only canonical byte writer. Reports add
  missing/unmapped counts, normative scenario owner, nullable line/anchor, and
  typed evidence scope/digest while preserving explicit property order, one
  LF, and digest-over-payload semantics.
- One exit mapper and one governance process boundary distinguish successful
  `conforming` / `nonconforming` / `incomplete` reports at exits `0` / `1` /
  `2` from fixed redacted no-report exits `64` / `70` / `130`. Unexpected
  programming failures are redacted only at this outer governance boundary;
  pre-cancellation exits `130` without invoking the operation, and the shared
  operation boundary is unchanged.
- The schema-`1` catalog now single-owns normative scenario record addresses;
  its unreleased metadata digest is
  `000caecc4c5cd941da8b0ab06386cc1a88c294117f69f685245b6bc29af9fc6f`.
  [TEST-0194](test-cases.md#test-0194) exact metadata/digest assertions changed
  in the same slice.
- Focused development checkpoints passed 8/8, 14/14, and 16/16 before atomic
  route activation. Independent fresh review closed duplicate-order,
  application/stage identity, evidence-scope, location, and cancellation gaps;
  invalid identity, total-order, and late-cancellation edges; the final focused
  suite passed 25/25 and the full solution passed governance 155/155,
  architecture 31/31, and packaging 17/17.
- Locked restore and format verification passed. The exact committed tree at
  [`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99)
  passed PowerShell 7 and Windows PowerShell 5.1 `StructureOnly` in 203.6 and
  284.7 seconds, with protocol-governance observations of 201.5 and 282.3
  seconds. Earlier candidate observations were 183.2 and 275.4 seconds and are
  not substituted for the committed-tree evidence.
- Framework-dependent publish produced only DLL/JSON/PDB artifacts and no
  apphost. The published governance DLL validated the real repository with
  exit `0`, `conforming`, the exact catalog digest, two evaluated rules, zero
  findings, `bounded-catalog`, `csharp-shadow`, and
  `powershell-authority`.
- Ownership activation moves only [TEST-0195](test-cases.md#test-0195) into the
  existing governance .NET project and both existing hosted C# filters.
  [TEST-0208](test-cases.md#test-0208) remains planned. No job, runner,
  PowerShell route, consumer behavior, package-qualification/provenance state,
  or authority state changes.

Hosted [run `30424139722`](https://github.com/hasanmanzak/meAndAI/actions/runs/30424139722),
associated with exact PR head
[`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99),
tested merge commit
[`9582a4a`](https://github.com/hasanmanzak/meAndAI/commit/9582a4aabb67dfcf9adf291a7eb2b781cf8c4a04)
over the same exact Git tree
and passed Ubuntu in 8 min 37 s and Windows in 33 min 52 s. Both hosted filters
explicitly selected [TEST-0195](test-cases.md#test-0195); exact-head trait
inventory plus the filtered logs reconcile 25 selected, executed, and passed
cases with zero failed or skipped. The hosted C# steps passed governance 95/95,
architecture 31/31, and packaging 17/17 on both platforms. Windows PowerShell
5.1 validation consumed 32 min 28 s of the Windows job. Elapsed values are
observations, not thresholds.

Fresh review, exact committed-tree gates, and implementation hosted closure are
green. This closes the fourth of seven bounded subfeatures (57.1%); three remain
open. [FIND-0371](#find-0371) records the later closure-record Markdown defect
and its bounded correction. No later implementation slice may begin until the
commit containing that correction passes the existing hosted Ubuntu and Windows
gates.

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Specification-first sequencing: [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
- Bounded catalog and reuse boundary: [DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md)
- Deferred coverage/equivalence owner: [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md)
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
- [x] [RISK-0288](#risk-0288) and [RISK-0289](#risk-0289) remain owned; the first slice introduces no
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

The first-slice Definition of Ready remains complete, 10/10 (100%). The
2026-07-29 bounded-MVP addendum is also ready: the exact two-rule catalog,
parse-once reuse ownership, exact-commit-only snapshot, canonical gitlink
consumer boundary, typed bounded-coverage report, portable artifact, deferred
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md) scope,
risks, and maintainer implementation authorization are all explicit in
[DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md)
and this record.

[SUBF-0138](#subf-0138), [SUBF-0134](#subf-0134), [SUBF-0122](#subf-0122), and
[SUBF-0124](#subf-0124) are fully closed, so bounded feature closure is four
of seven subfeatures (57.1%). Three subfeatures remain independently open. The
historical 188-identity inventory and its
mixed/variant gaps are inputs to
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md)
equivalence, not this feature's completion criteria. See the historical
[sequencing analysis](readiness-analysis.md#remaining-definition-of-ready-gates)
with the
[DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md)
scope banner.

## Acceptance criteria

1. The governance application has no repository or GitHub mutation capability.
2. The same engine validates meAndAI and project-neutral consumers through
   caller-selected, engine-verified capability profiles.
3. One parse-once immutable analysis context serves the distinct
   [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
   and
   [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
   rules; no second same-contract parser, index, finding envelope,
   serializer, adapter, or fixture builder exists.
4. Reports are deterministic, typed, redacted, bind the exact evaluated
   two-rule catalog/digest, and describe coverage as bounded.
5. The released CLI accepts only an explicit exact-commit snapshot and fails
   closed on an unknown, ambiguous, unsafe, mismatched, or drifting commit.
6. The consumer profile supports only the canonical `.ai/protocol` gitlink;
   repository-reference and full candidate overlays remain outside the package.
7. One framework-dependent `maai-governance.zip` is qualified as
   `CSharpReleasedNonAuthoritative`; it grants no required-check or authority
   claim.
8. General live GitHub issue/PR/comment governance remains outside this feature
   unless separately discussed and authorized.

## Definition of Done

[SUBF-0138](#subf-0138), [SUBF-0134](#subf-0134), [SUBF-0122](#subf-0122), and
[SUBF-0124](#subf-0124) are implemented, fresh-review green, and exact hosted
verified. Three bounded subfeature implementations, full-feature review/CI,
exact-commit package qualification, draft-PR completion, merge, and immutable
release remain incomplete.
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md)
equivalence,
[FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md)
migration, authority transfer, and PowerShell retirement are explicit successor
work rather than this feature's Definition of Done.
