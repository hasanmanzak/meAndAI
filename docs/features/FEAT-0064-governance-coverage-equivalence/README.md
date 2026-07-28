# FEAT-0064 - Governance Coverage Convergence and Equivalence

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed / records-only; development not authorized |
| Target version | 0.20.0 |
| Issue | [#161](https://github.com/hasanmanzak/meAndAI/issues/161) |
| Pull request | [#160](https://github.com/hasanmanzak/meAndAI/pull/160) introduces the records-only boundary; implementation pull request not created |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md), and [DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md) |
| Tests | [TEST-0196](test-cases.md#test-0196) plus reused canonical rule and snapshot scenarios |

## Problem

A bounded non-authoritative C# governance release can provide value before all
transferable rules and legacy variants have moved, but required-check
eligibility, authority transfer, and PowerShell retirement still require a
finite and complete equivalence boundary. Keeping both outcomes in
[FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md) would delay the
first release and encourage rule-specific parser, fixture, and metadata copies.

## Outcome

The remaining governance rule families converge on the shared C# repository
analysis model, and every supported material PowerShell/C# behavior receives a
same-snapshot evidenced disposition before any authority or retirement claim.

## Scope

- Remaining transferable governance rule families beyond the exact bounded
  FEAT-0060 catalog.
- Reuse of one canonical snapshot, document, record, ID, version, link, anchor,
  catalog, finding, serialization, and fixture foundation.
- Full HEAD/index/worktree `candidate` overlay with fail-closed ambiguity and
  drift behavior.
- Additional reviewed consumer integration adapters, including an explicit
  repository-reference contract if one becomes immutable and provider-neutral.
- Complete material-variant normalization, including the 16 currently mixed
  base identities.
- [TEST-0196](test-cases.md#test-0196) same-snapshot PowerShell/C# differential
  qualification and the exact dependency evidence required by
  [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md).

## Non-goals

- Reimplementing or translating PowerShell source.
- Duplicating a parser, grammar, model, snapshot reader, serializer, finding
  builder, fixture harness, or consumer-local validator.
- Required-check enforcement, consumer mutation, authority transfer, or
  PowerShell retirement; those remain
  [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md)
  gates.
- General live GitHub issue, pull-request, review, or comment content
  governance; that capability remains separately reserved.

## Reuse and ownership boundary

Each rule-family slice begins with a same-contract sibling inventory and a
compact reuse map. A repository file is acquired and parsed once per immutable
evaluation context; rule-specific evaluators consume shared indexes and add
only their distinct invariant. Common behavior is promoted to the narrowest
shared inward layer only when a concrete second consumer exists. Surface
similarity alone cannot create a universal framework or collapse distinct
policy into one rule.

## Readiness evidence

- Dependencies: the bounded released output of
  [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md), immutable
  [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md), and the
  specification/authority boundaries in the three linked decisions.
- Prior art: the FEAT-0060
  [differential inventory](../FEAT-0060-any-consumer-governance-cli/differential-ledger-analysis.md)
  and
  [rule/profile matrix](../FEAT-0060-any-consumer-governance-cli/rule-profile-matrix-analysis.md)
  account for 188 base identities, 43 C# candidates, 16 mixed boundaries, 94
  retained PowerShell operations, 29 infrastructure contracts, three provider
  identities, and three existing C# identities.
- Recurrence: the active
  [committed-HEAD graph route](../../../.ai/memory/project.md#untracked-governance-packet-is-absent-from-the-head-self-consumer-graph)
  applies to final governance packets; Git-heavy local validation also follows
  the active
  [restricted-sandbox route](../../../.ai/memory/project.md#restricted-sandbox-git-signal-pipe-failure).
- Development, a fresh variant denominator, executable baseline, and authority
  qualification remain unready and unauthorized.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0296` <a name="risk-0296"></a> | A bounded release is later treated as complete governance authority. | Governance owner / bind exact catalog inventory and digest in every report; keep missing and unmapped coverage visible and fail authority gates closed. |
| `RISK-0297` <a name="risk-0297"></a> | Rule growth creates duplicated parsers or an over-general universal framework. | Architecture owner / require the per-family reuse map, one canonical semantic owner, focused rule classes, and fresh-diff duplication review. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined but not implementation-ready | [TEST-0196](test-cases.md#test-0196) and existing canonical rule scenarios |
| Test code | Not started | Development is not authorized |
| Baseline run | Not run | FEAT-0060 bounded package and complete variant denominator do not yet exist |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0139` <a name="subf-0139"></a> | Remaining rule-family coverage over the shared analysis kernel | [#161](https://github.com/hasanmanzak/meAndAI/issues/161) | Existing canonical rule scenarios / not started | Pending | Proposed / not authorized |
| `SUBF-0140` <a name="subf-0140"></a> | Full candidate snapshot and reviewed consumer-adapter convergence | [#161](https://github.com/hasanmanzak/meAndAI/issues/161) | Existing [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) and applicable integration scenarios / not started | Pending | Proposed / not authorized |
| `SUBF-0136` <a name="subf-0136"></a> | Same-snapshot PowerShell/C# variant ledger and fail-closed differential harness | [#161](https://github.com/hasanmanzak/meAndAI/issues/161) | [TEST-0196](test-cases.md#test-0196) / not started | Pending | Proposed / mandatory before equivalence or retirement |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Predecessor: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md)
- Blocking predecessor of the retirement feature: [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md)
- Tracking issue: [#161](https://github.com/hasanmanzak/meAndAI/issues/161)

## Definition of Ready

- [x] Stable feature ID, linked issue, problem, outcome, high-level scope, and
  explicit non-goals.
- [x] Reuse ownership, predecessor, retirement consumer, risks, and existing
  inventory sources are identified.
- [ ] Finite rule-family catalog, complete material-variant denominator,
  exact adapter set, detailed contracts, executable red tests, baseline,
  verification budget, and explicit implementation authorization.

## Acceptance criteria

1. Every transferred rule family consumes canonical shared analysis primitives
   without a second same-contract parser, model, adapter, serializer, finding
   envelope, or fixture harness.
2. Candidate and exact-commit snapshots preserve the canonical byte-authority
   matrix and fail closed on ambiguous, unsafe, or drifting evidence.
3. Every supported material behavior has exactly one evidenced differential
   disposition; missing, duplicate, divergent, or unproved stronger evidence
   blocks equivalence.
4. Complete evidence is consumable by FEAT-0063 without granting mutation,
   required-check, or retirement authority in this feature.

## Definition of Done

All implementation, tests, review, CI, equivalence, documentation, and
authority-qualification evidence remains pending. Creating this records-only
feature does not authorize development.
