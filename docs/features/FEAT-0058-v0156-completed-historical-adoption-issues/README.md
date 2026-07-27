# FEAT-0058 - Completed Historical Adoption-Issue Compatibility

| Field | Value |
| --- | --- |
| Classification | Backward-compatible quick-adoption defect correction / [BUG-0045](https://github.com/hasanmanzak/meAndAI/issues/149) |
| Status | Complete |
| Target version | 0.15.6 |
| Bug | [BUG-0045 / issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) |
| Pull request | [PR #152](https://github.com/hasanmanzak/meAndAI/pull/152) |
| Decisions | [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md), [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md), [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md), [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md), [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md) |
| Tests | Existing [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) and related [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176); [feature evidence](test-cases.md) |

## Problem

The v0.15.5 quick-adoption issue reader inventories both open and closed
issues, but classifies ownership only against the current opaque marker or the
current target/current pull-request legacy marker. A valid marker written by
an older immutable meAndAI release therefore reaches the malformed-marker
fallback during a later clean adoption. The launcher blocks even when the
historical issue is closed as completed, its exact same-repository pull request
is merged, and its reserved proposal branch is absent.

## Outcome

The shared launcher classifies issue inventory as `CurrentCanonical`,
`CurrentLegacy`, `CompletedHistorical`, `Competing`, `Malformed`, or
`Unmarked`. A non-current marker is excluded from current cardinality only
after bounded, immutable, same-repository proof establishes its complete
historical identity and absence of live authority. The historical issue is
never migrated or edited. Every partial, unsupported, ambiguous, or live state
still fails before issue mutation and local Codex execution.

## Immutable baseline

- Release: [v0.15.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.5).
- Commit: [exact baseline commit](https://github.com/hasanmanzak/meAndAI/commit/11c56aac369767202835c4e9d6cc83aa321f4070).
- Reproducer owner: [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069), extended with an anonymous historical-release variant before production changes.
- Failure: `A project-owned adoption issue contains a malformed ownership marker; manual review is required.`

## Domain and compatibility contract

- A reserved issue marker is trusted only when it is the exact case-sensitive
  first line and occurs exactly once.
- Current opaque and current-target legacy identities retain their existing
  exact title/body, uniqueness, drift, and convergence rules.
- A historical candidate must use canonical `vM.m.rev` syntax, be strictly
  older than the requested target within the same major version, and belong to
  a marker/body family inventoried from an immutable meAndAI release. This
  correction admits only the reviewed `v0.8.0` through `v0.10.4` legacy
  profile-A issue body paired with a schema-3 `Completed` pull-request marker.
- Historical proof binds the issue number, exact title and generated body,
  target tag, immutable protocol commit, pull-request URL and number,
  same-repository merged pull request, exact terminal adoption marker, actor,
  historical head, completed issue disposition, and absent exact reserved
  branch.
- Provider reads begin only after strict local grammar and candidate-count
  filtering. At most eight historical candidates are permitted; a full
  1,000-item issue result is treated as ambiguous pagination and fails before
  candidate reads. Each candidate permits one exact pull-request read, one
  two-item open-branch pull-request query, cached immutable release/commit
  resolution, and one exact remote-ref read, with no retry.
- Releases `v0.6.1` through `v0.7.1` have no canonical pull-request marker;
  `v0.7.2` through `v0.7.3` have only schema-2 `Proposed` evidence;
  `v0.11.0` through `v0.12.5` add schema-5 strategy/surface identity;
  `v0.12.6` through `v0.14.1` add schema-7 graph identity; and `v0.14.2`
  onward uses an opaque issue identity with schema-9/11 terminal evidence.
  Those families are inventoried but intentionally unsupported by this narrow
  compatibility correction. They, cross-major targets, provider failures,
  bound exhaustion, and any ambiguity are
  `Malformed` or `Competing` and fail closed.
- Classification completes once before mutation. Later issue-inventory reads
  in the same reconciliation must match the frozen historical metadata
  fingerprint byte-for-byte; any drift blocks the next mutation without
  repeating provider proof or introducing eventual-consistency retries.

## Scope

- Inventory every adoption-issue marker family emitted by immutable releases
  and record its reconstructability boundary.
- Add one bounded classification path to the canonical quick-adoption
  ownership reader.
- Reuse the canonical pull-request marker parser, version comparison, immutable
  release verifier, exact generated-body contracts, and remote-branch reader.
- Extend [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069)
  with positive, idempotent, and fail-closed historical variants.
- Pass the already-cloned target repository into issue reconciliation for exact
  remote branch proof.
- Publish the common correction as immutable `v0.15.6` and record
  post-publication evidence in [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149).

## Non-goals

- No named-consumer branch, constant, fixture, path, issue, pull request, test,
  documentation fact, or workaround.
- No mutation or migration of a completed historical issue.
- No acceptance based only on `CLOSED`, a marker-shaped string, or an old tag.
- No second lifecycle engine, generic history framework, or duplicate scenario
  identity.
- No consumer recovery; any later consumer operation is separately authorized
  and linked after the common immutable release exists.
- No change to proposal creation, merge authority, secret handling,
  instruction-graph semantics, or managed update behavior.

## Readiness evidence

- Domain and contracts: the six classes, immutable identity inputs, terminal
  lifecycle state, strict version compatibility, read bounds, mutation order,
  and error behavior are fixed above.
- Consumers and dependencies: `Ensure-AdoptionIssue` is the sole mutation
  path; its three completion/recovery callers already hold the target clone.
  GitHub issue/PR metadata, the immutable meAndAI release, and the exact remote
  branch namespace are external evidence boundaries.
- Prior art: [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
  owns convergence; [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md)
  owns target-bound recovery; [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md)
  requires a project-neutral upstream correction. No new architectural
  decision is required.
- Recurrence: no active entry matches the exact signature; result `None`.
  The implemented correction must add one linked active entry and keep
  [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) as the
  executable barrier.
- Scenario intent: nearest same-contract sibling is existing
  [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069).
  Relationship disposition is `ParameterizedVariant`: the ownership contract,
  risk family, integration level, and exercised launcher boundary are the same;
  only authoritative lifecycle state and immutable marker family vary.
- Verification: deterministic expected red against exact v0.15.5; focused
  `IntegrityManifestIssue` on PowerShell 7 and Windows PowerShell 5.1; bundle,
  role-boundary, structure, and final canonical suites; hosted Ubuntu/Windows;
  immutable-release and current-authority post-publication verification.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0278` <a name="risk-0278"></a> | A merely closed or marker-shaped issue suppresses a competing live adoption record. | [SUBF-0118](#subf-0118) / require complete exact issue, release, merged-PR, terminal-marker, actor, and absent-branch proof; otherwise fail before mutation. |
| `RISK-0279` <a name="risk-0279"></a> | Historical compatibility becomes an unbounded remote scan or retry loop. | [SUBF-0118](#subf-0118) / strict local grammar first, explicit candidate/read ceilings, existing finite issue inventory, no automatic retry. |
| `RISK-0280` <a name="risk-0280"></a> | Reconstructing old output copies or forks the canonical lifecycle parser. | Quick-adoption owner / share marker parsing and existing release/version/body helpers; retain only reviewed immutable family profiles and reject unreconstructable families. |
| `RISK-0281` <a name="risk-0281"></a> | Evidence changes after classification while current issue convergence performs additional inventory reads. | Issue owner / freeze the historical metadata fingerprint before the first mutation, require every later inventory to match it byte-for-byte, and never repeat historical provider proof as an eventual-consistency retry. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | Existing [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) parameterized variant in [feature evidence](test-cases.md) |
| Test code | Expected red | Anonymous historical legacy issue and merged pull-request fixture in existing [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) owner |
| Baseline run | Failing as intended | Exact v0.15.5 focused `IntegrityManifestIssue` failed only on the completed-historical expectation in 175.6 seconds |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0118` <a name="subf-0118"></a> | Bounded completed-historical issue classification and immutable v0.15.6 delivery | [Issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) | Existing [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) expected red, focused PS7/PS5.1 green, final suite, hosted and release verification | Exact family inventory, mutation order, provider bounds, project-neutrality, and final diff review | Complete |

## Decisions and relationships

- Decisions: existing [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md), [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md), [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md), [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md), [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md), and [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md); no new decision because the correction preserves those boundaries and extends the unchanged reviewed schema-2 profile through v0.15.6.
- Parent epic: N/A; this is one bounded P1 common-runtime correction.
- Dependencies: immutable v0.15.5 baseline and current [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) owner.
- Related: [historical capability-review recovery](https://github.com/hasanmanzak/meAndAI/issues/104) is analogous for a different artifact; [BUG-0036 / issue #139](https://github.com/hasanmanzak/meAndAI/issues/139) is sequenced after this overlapping ownership change.

## Definition of Ready

- [x] Stable feature, bug, subfeature, target release, and linked issue assigned.
- [x] Problem, outcome, scope, non-goals, and acceptance boundary recorded.
- [x] Domain, compatibility, consumer, dependency, bound, and error contracts recorded.
- [x] Numbered risks and existing governing decisions recorded.
- [x] One independently reviewable subfeature and gate ledger recorded.
- [x] Existing numbered scenario and verification approach recorded.
- [x] Same-contract review records `ParameterizedVariant`; no new TEST ID.
- [x] Executable expected-red evidence recorded against exact v0.15.5.
- [x] Prior-art and recurrence result `None` recorded with planned barrier.
- [x] Explicit implementation and end-to-end delivery authorization received from the maintainer on 2026-07-27.

## Acceptance criteria

1. Exact v0.15.5 deterministically rejects the valid completed-historical fixture.
2. A fully proven historical record becomes `CompletedHistorical`; its issue bytes and metadata are unchanged.
3. Exactly one current adoption issue is reconciled and repeated runs add no duplicate.
4. `CurrentCanonical`, `CurrentLegacy`, uniqueness, drift, and current issue lifecycle behavior remain unchanged.
5. Open/uncompleted issue, open/unmerged/foreign/mismatched pull request, live historical branch, wrong target/repository/actor/title/body, malformed or displaced marker, provider failure, unsupported family, ambiguous inventory, and bound exhaustion all fail before issue, branch, pull-request, consumer-head, or Codex mutation.
6. Provider reads are locally prefiltered and remain within the declared ceilings.
7. Common source, fixtures, and normative records contain no named-consumer fact.
8. Both supported PowerShell runtimes, applicable hosted gates, immutable release verification, and external post-publication evidence pass before closure.

## Self-review

The bounded base-to-candidate review is complete. It covered the exact
historical family registry, provider-read ceilings and arguments, proof and
mutation ordering, frozen-evidence revalidation, private-protocol authority,
same-contract test ownership, project-neutrality, version/profile boundaries,
bundle identity, and graph-reachable records. Two independent final reviews
found the late-proof, test-oracle, and credential-authority gaps below. The
canonical quick-adoption run then exposed detached-helper, row-shape, race-
fixture, partial-reset, version-oracle, and JSON-root gaps. Every `Blocking`
finding is resolved in the candidate. The canonical committed-tree full-
project scan, hosted checks, and publication remain delivery gates.

| ID | Area / priority | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0345` <a name="find-0345"></a> | Mutation ordering / P1 | The first correction proved historical ownership only when the current issue was reconciled, after unrelated launcher mutations could already occur. | `Blocking` / Resolved in candidate by one public-launcher snapshot after route and live-boundary checks but before Git configuration, secret, seed, push, dispatch, issue, pull-request, or Codex mutation; every later relevant transition revalidates the frozen issue fingerprint. |
| `FIND-0346` <a name="find-0346"></a> | Classification identity / P1 | Initial classification relied on ambient target identity, accepted incomplete issue response shapes, let one malformed record contaminate later rows, and compared repository identity case-sensitively. | `Blocking` / Resolved in candidate by explicit target tag and remote parameters, array/row shape validation with the 1,000-item ambiguity guard, issue-local classification state, and ordinal-ignore-case GitHub repository identity checks. |
| `FIND-0347` <a name="find-0347"></a> | Test oracle / P1 | The first matrix did not prove the full provider call prefix and exact arguments, and representative launcher negatives did not snapshot every mutable issue, pull-request, label, ref, worktree, workflow, and Codex surface. | `Blocking` / Resolved in candidate by ordered one-call ceilings, exact release/`pr view`/`pr list` contracts, and four full-launcher byte-identical zero-mutation snapshots across local malformed, provider failure, live branch, and frozen-drift boundaries. |
| `FIND-0348` <a name="find-0348"></a> | Test oracle / P1 | The injected frozen-drift fixture changed the backing issue object, so a stronger before/after oracle correctly reported mutation caused by the test itself. | `Blocking` / Resolved in candidate by generating drift only in the serialized read projection while keeping provider backing state byte-identical. |
| `FIND-0349` <a name="find-0349"></a> | Credential authority / P1 | Historical immutable-release proof dropped the already-loaded protocol read token, so private protocol access could pass current preflight and then fail only on an otherwise valid old issue. | `Blocking` / Resolved in candidate by exact token forwarding from launcher through snapshot, classifier, validator, and immutable-release verifier without persisting the token in evidence; contract and full-launcher tests prove the private read boundary. |
| `FIND-0350` <a name="find-0350"></a> | Evidence wording / P2 | The first test record claimed exact negative error-text assertions although the matrix contract requires expected acceptance or rejection plus exact bounded calls. | `Blocking` / Resolved in candidate by narrowing the record to the implemented semantic rejection contract while retaining exact call order, arguments, ceilings, and zero-unexpected-call evidence. |
| `FIND-0351` <a name="find-0351"></a> | Detached test dependency / P1 | The culture fixture extracted `Get-ValidatedAdoptionMarker` after its parser became a canonical sibling helper, so the isolated module no longer contained its complete production dependency graph. | `Blocking` / Resolved in candidate by extracting both the parser and validation boundary; both culture variants now execute the actual dependency pair. |
| `FIND-0352` <a name="find-0352"></a> | Version oracle / P1 | One current-release URL assertion still expected immutable prior `v0.15.5`, so the canonical full run rejected the correctly advanced `v0.15.6` source. | `Blocking` / Resolved in candidate by retaining v0.15.5 only in explicit immutable-prior fixtures and asserting v0.15.6 on the current runtime route. |
| `FIND-0353` <a name="find-0353"></a> | Classification row safety / P1 | Current-issue lookup dereferenced `state` on every classification row even though `Unmarked` rows intentionally do not project a top-level state. | `Blocking` / Resolved in candidate by testing classification before accessing the current-only state field. |
| `FIND-0354` <a name="find-0354"></a> | Race oracle / P1 | The already-ready base-race injection used a shared cumulative PR-read count and the pre-BUG-0045 call offset, so it could hit the mock ceiling before the intended final revalidation. | `Blocking` / Resolved in candidate by making the scenario own a zero-based counter and injecting on the third read: frozen issue snapshot, retained proposal read, then final ready-state revalidation. |
| `FIND-0355` <a name="find-0355"></a> | Fixture authority / P1 | Several independent negative fixtures deleted the mock PR/branch but retained the completed proposal's marked issue, creating an impossible orphan authority; one invalid-manifest slice could therefore pass for the wrong preflight reason. | `Blocking` / Resolved in candidate by clearing issue/label authority only for explicitly fresh attempts, preserving it for true recovery scenarios, and asserting the representative manifest's exact boundary error. |
| `FIND-0356` <a name="find-0356"></a> | Manifest root shape / P1 | `ConvertFrom-Json` enumerated a root array before typed property access, leaking a raw `System.Object[]` to `Int64` conversion error instead of the canonical manifest-contract rejection. | `Blocking` / Resolved in candidate by validating the raw JSON object root and exact `PSCustomObject` result before any property cast on both supported runtimes. |

## Delivery evidence

| Field | Evidence |
| --- | --- |
| Expected red | Exact v0.15.5 plus the [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) fixture only failed in 175.6 seconds with `A project-owned adoption issue contains a malformed ownership marker; manual review is required.` No production source had changed. |
| Focused PowerShell 7 / Windows PowerShell 5.1 | The final frozen implementation bytes passed `IntegrityManifestIssue` on PowerShell 7 / Windows PowerShell 5.1 in 156.1 / 162.6 seconds. The runs include exact protocol-read token forwarding through the full launcher, all six classifications, 20 supported immutable identities, exact candidate/inventory ceilings, provider-call contracts, frozen drift, full-state zero-mutation negatives, exact manifest-root rejection, and idempotent convergence. |
| Retained lifecycle PowerShell 7 / Windows PowerShell 5.1 | The final candidate passed `AdoptionLifecycle` in 194.9 / 202.4 seconds, including current canonical/legacy behavior, unmarked-row classification, exact drift diagnostics, idempotent recovery, and final ready-state base-race handling. |
| Final relevant auxiliary gates | PowerShell 7 / Windows PowerShell 5.1 passed bundle verification in 27.3 / 28.9 seconds, runtime-efficiency in 7.7 / 8.9 seconds, and source-graph dispatch in 4.9 / 5.7 seconds. PowerShell 7 role-boundary passed in 19.6 seconds, test architecture in 2.9 seconds, recurrence prevention in 1.1 seconds, and protocol governance in 124.0 seconds. Publication evidence passed without claiming published state on PowerShell 7 / Windows PowerShell 5.1 in 106.6 / 194.1 seconds. |
| Canonical quick-adoption owner | PowerShell 7 `Shard=All` passed in 847.1 seconds after exercising every declared quick-adoption scenario in one process, including the completed-historical matrix, exact manifest-root rejection, fresh-attempt authority isolation, FullMigration, Codex-failure, and managed-consumer routes. |
| Final local suite | Exact candidate commit [`7856697dc8733449bf907dfb47af77486dd8dee6`](https://github.com/hasanmanzak/meAndAI/commit/7856697dc8733449bf907dfb47af77486dd8dee6) passed `pwsh -NoProfile -File tests/protocol.tests.ps1` in 1732.8 seconds. Exact owner times included quick adoption 844.371 seconds, instruction graph 129.840 seconds with 2/2 process starts and 4/4 blob requests, governance 121.801 seconds, publication evidence 100.484 seconds, and runtime efficiency 7.038 seconds; every discovered suite emitted valid scenario evidence. |
| Pull request / hosted validation | Draft [PR #152](https://github.com/hasanmanzak/meAndAI/pull/152); hosted required checks and final review pending |
| Immutable release / post-publication verification | Pending `v0.15.6` |

## Definition of Done

- [ ] Acceptance criteria met.
- [x] Existing [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) variant and scenario mapping complete.
- [x] Focused PowerShell 7 and Windows PowerShell 5.1 evidence recorded.
- [x] Bundle, governance, structure, and canonical full-suite evidence recorded.
- [x] Bounded self-review and post-development scan have no unresolved `Blocking` finding.
- [ ] Documentation, links, version, changelog, active recurrence entry, and project memory current.
- [x] Issue and pull request cross-linked.
- [ ] Applicable hosted pre-merge gates pass.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [BUG-0045 / issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) |
| Release authority | `Pending`; immutable GitHub Release `v0.15.6` after merge |
| Release identifier | `Pending`; exact release link will be written to [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) |
| Target commit | `Pending`; exact full-SHA commit permalink will be written to [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) |
| Verification evidence | `Pending`; API/ref/check/current-authority result and date will be written to [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) |
