# FEAT-0053 - Distinct Test Intent and Meta-Test Boundaries

| Field | Value |
| --- | --- |
| Classification | Backward-compatible protocol clarification and test-portfolio correction |
| Status | Complete |
| Target version | 0.15.2 |
| Issue | [Issue #133](https://github.com/hasanmanzak/meAndAI/issues/133) |
| Pull request | [PR #134](https://github.com/hasanmanzak/meAndAI/pull/134) |
| Decisions | [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md), [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The existing architecture gives every numbered scenario one technical owner and
prevents duplicated generic helpers, inferred runtime completion, and role
overlap. It does not explicitly prevent two different numbered scenarios from
owning the same behavioral contract, risk, evidence level, and exercised
boundary.

The same gap makes a legitimate direct test of test infrastructure look similar
to a redundant test whose only oracle is another test's source or green result.
Without a reviewed semantic boundary, later work can either duplicate behavior
or remove material infrastructure evidence by mistake.

## Outcome

Every new or changed numbered scenario records a distinct reviewed intent or an
explicit parameterized/supersession relationship to its nearest same-contract
sibling. Direct infrastructure-contract tests remain valid, but another test's
source, assertion wording, pass marker, or successful result cannot serve as
the behavioral oracle. The current portfolio is reviewed once through its
existing executable-owner inventory and only proven collisions are corrected.

## Scope

- Add the prospective scenario-intent rule to the protocol, feature template,
  test-scenario template, and feature issue form.
- Define the reviewed tuple as contract, risk, evidence level, and exercised
  boundary.
- Use exactly `Distinct`, `ParameterizedVariant`, `InfrastructureContract`, or
  `SupersededDuplicate` as the relationship disposition.
- Record one finite owner-level review of all 23 canonical executable owners
  and 181 active identities from the existing scenario authority.
- Consolidate [TEST-0081](../FEAT-0013-v084-correction/test-cases.md#test-0081)
  into [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069).
- Consolidate [TEST-0082](../FEAT-0013-v084-correction/test-cases.md#test-0082)
  into [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070) and
  remove its per-test documentation-row oracle.
- Add [TEST-0190](test-cases.md#test-0190) to the existing role-boundary owner,
  using inert declarative examples and the canonical scenario registry.
- Record any runtime effect as observational input to
  [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

## Non-goals

- No universal semantic clone detector, source-similarity matcher, or validator
  for every test.
- No second scenario registry, test framework, workflow, job, matrix, runner,
  or capability catalog entry.
- No mutation of the released `test-harness-modularity` capability definition
  or earlier consumer capability assessments.
- No removal of distinct security, recovery, integration, supported-runtime,
  state-transition, or external-authority evidence.
- No elapsed-time optimization or closure of
  [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

## Readiness evidence

- Domain and contracts: `ScenarioIntent` is the reviewed tuple `contract`,
  `risk`, `evidence level`, and `exercised boundary`. `Relationship` is exactly
  one of the four declared dispositions. `NearestSibling` names the closest
  known same-contract scenario or records explicit `None` when no sibling
  exists. Semantic equivalence remains a maintainer review, not an automated
  inference.
- Consumers and dependencies: [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md),
  the canonical scenario authority, the existing role inspector, feature/test
  templates, and the feature issue form are the complete changed surfaces.
  The immutable capability definition remains byte-identical under
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md).
- Prior art and recurrence: no active project-memory entry describes semantic
  scenario duplication, so the contract match is explicit `None`.
  [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  is the canonical technical-ownership sibling. The finite review below is the
  same-contract sibling inventory. There is no failed implementation route.
  [TEST-0190](test-cases.md#test-0190) is the planned executable barrier.
- Tooling recurrence: restricted Git commands use the one authorized
  unrestricted route after the known signal-pipe signature; displayed
  full-file output is never rewrite authority; failed patches require
  per-target inspection; PowerShell diagnostics avoid ambiguous variable-colon
  interpolation; multiline GitHub bodies use file/stdin transport.
- Verification approach: add the focused structural/negative scenario first,
  record its intended red state, implement the protocol/template/owner changes,
  run the retained quick-adoption owner and focused role-boundary owner, perform
  one fresh-diff review, then one final canonical suite and ordinary hosted PR
  validation.
- Compatibility: this is a prospective `rev` clarification. A repository
  correctly pinned to an earlier release remains conforming; a repository that
  adopts `0.15.2` applies the review when it next adds or changes a numbered
  scenario.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0238` <a name="risk-0238"></a> | A semantic detector creates false positives or a second validation framework. | [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md) keeps equivalence as a finite reviewed disposition; [TEST-0190](test-cases.md#test-0190) validates only the explicit contract and deterministic boundaries. |
| `RISK-0239` <a name="risk-0239"></a> | Broad consolidation removes material evidence that merely looks similar. | The owner-level ledger requires the complete intent tuple; only [FIND-0289](#find-0289) and [FIND-0290](#find-0290) satisfy it. |
| `RISK-0240` <a name="risk-0240"></a> | Legitimate discovery, authority, role, or exact-evidence tests are mislabeled as prohibited tests-of-tests. | `InfrastructureContract` remains an explicit valid disposition with one direct owner and inert inputs under [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md). |
| `RISK-0241` <a name="risk-0241"></a> | A prospective clarification mutates an immutable capability blob and forces dishonest ledger reassessment. | Do not edit the released capability definition or catalog; version `0.15.2` changes only protocol/review surfaces and this repository's proven duplicate identities. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0190](test-cases.md#test-0190) with retained [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) and [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070) |
| Test code | Implemented / focused green | Existing role-boundary owner and its inert fixture family; no new suite or framework |
| Baseline run | Test-first harness findings resolved; focused green | Commands and results in [test evidence](test-cases.md#evidence) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0100` <a name="subf-0100"></a> | Protocol decision, intent contract, and finite active-portfolio review | [Issue #133](https://github.com/hasanmanzak/meAndAI/issues/133) | [TEST-0190](test-cases.md#test-0190) focused pass | [FIND-0289](#find-0289) and [FIND-0290](#find-0290) resolved | Implemented |
| `SUBF-0101` <a name="subf-0101"></a> | Existing-owner structural barrier and two proven supersessions | [Issue #133](https://github.com/hasanmanzak/meAndAI/issues/133) | [TEST-0190](test-cases.md#test-0190), retained canonical quick-adoption scenarios passed | [FIND-0291](#find-0291) through [FIND-0298](#find-0298) resolved; bounded fresh-diff review found no remaining blocker | Implemented |

## Finite active-portfolio review

The existing `tests/scenario-ownership.psd1` executable authority is the sole
inventory. The review baseline contained 23 owners and 181 active identities;
this table records those pre-remediation counts as delivery evidence, not as a
second runtime registry. The final authority still has 23 owners and has 180
active identities: Quick Adoption changes from 41 to 39, Role Boundaries
changes from 2 to 3 with [TEST-0190](test-cases.md#test-0190), and every other
owner count remains unchanged.

| Canonical executable owner | Baseline active count | Nearest same-contract owner | Disposition |
| --- | ---: | --- | --- |
| [Protocol governance](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1) | 37 | [Recurrence prevention](../../../tests/capabilities/protocol-governance/recurrence-prevention.tests.ps1), [test architecture](../../../tests/capabilities/test-architecture/test-architecture.tests.ps1) | `Distinct`; general governance differs from recurrence routing and test infrastructure. |
| [Protocol update](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1) | 29 | [Update reliability](../../../tests/capabilities/consumer-update/protocol-update-reliability.tests.ps1), [migrations](../../../tests/capabilities/consumer-update/consumer-migrations.tests.ps1), [merge finalization](../../../tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1) | `Distinct`; planning/orchestration differs from native transport, pure migration, and cleanup. |
| [Protocol-update reliability](../../../tests/capabilities/consumer-update/protocol-update-reliability.tests.ps1) | 2 | [Protocol update](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1) | `Distinct`; retry, JSON, and native-process transport is an independent boundary. |
| [Instruction-graph discovery](../../../tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1) | 3 | [Runtime efficiency](../../../tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1) | `Distinct`; graph behavior differs from operation-budget enforcement. |
| [Capabilities bootstrap](../../../tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1) | 19 | [Quick adoption](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1) | `Distinct`; empty/populated consumer cases are valid `ParameterizedVariant` repository states. |
| [Quick adoption](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1) | 41 | [Capabilities bootstrap](../../../tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1), [streaming](../../../tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1), [bundle](../../../tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1) | Two `SupersededDuplicate` pairs are proven by [FIND-0289](#find-0289) and [FIND-0290](#find-0290); remaining families are distinct. |
| [Quick-adoption streaming](../../../tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1) | 2 | [Quick adoption](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1) | `Distinct`; rendering and process-tree cancellation are separate runtime boundaries. |
| [Quick-adoption bundle](../../../tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1) | 1 | [Quick adoption](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1), [publication evidence](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) | `Distinct`; deterministic archive construction differs from launcher and external verification. |
| [Consumer migrations](../../../tests/capabilities/consumer-update/consumer-migrations.tests.ps1) | 2 | [Protocol update](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1) | `Distinct`; pure migration/atomic adapter behavior differs from GitHub orchestration. |
| [Windows validation profile](../../../tests/capabilities/windows-validation/windows-validation-profile.tests.ps1) | 1 | [Main validation route](../../../tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1) | `Distinct`; diff classification differs from exact-green-tree reuse. |
| [Publication evidence](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) | 7 | [Protocol governance](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1), [bundle](../../../tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1) | `Distinct`; external GitHub authority and transport are separate. |
| [Managed merge finalization](../../../tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1) | 7 | [Protocol update](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1), [capability review](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1) | `Distinct`; branch-first/issue-last convergence is separate. |
| [Main validation route](../../../tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1) | 2 | [Windows validation profile](../../../tests/capabilities/windows-validation/windows-validation-profile.tests.ps1), [runtime efficiency](../../../tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1) | `Distinct`; hosted routing differs from profile selection and fixture budgets. |
| [Idea incubation](../../../tests/capabilities/idea-incubation/idea-incubation.tests.ps1) | 1 | [Protocol governance](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1) | `Distinct`; non-authorizing idea lifecycle is its own domain. |
| [Capability catalog](../../../tests/capabilities/capability-adoption/capability-catalog.tests.ps1) | 5 | [Capability review](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1) | Append/prefix cases are `ParameterizedVariant`; catalog and ledger-review contracts remain distinct. |
| [Test discovery](../../../tests/capabilities/test-architecture/test-discovery.tests.ps1) | 1 | [Test architecture](../../../tests/capabilities/test-architecture/test-architecture.tests.ps1) | `InfrastructureContract`; synthetic paths directly test discovery. |
| [Test architecture](../../../tests/capabilities/test-architecture/test-architecture.tests.ps1) | 3 | [Test discovery](../../../tests/capabilities/test-architecture/test-discovery.tests.ps1), [runtime identity](../../../tests/capabilities/test-architecture/runtime-scenario-identity.tests.ps1), [role boundaries](../../../tests/capabilities/test-architecture/role-boundaries.tests.ps1) | `InfrastructureContract`; topology, process isolation, and observations are direct contracts. |
| [Canonical utility ownership](../../../tests/capabilities/test-architecture/canonical-utility-ownership.tests.ps1) | 1 | [Role boundaries](../../../tests/capabilities/test-architecture/role-boundaries.tests.ps1) | `InfrastructureContract`; inert unauthorized definitions test helper ownership. |
| [Runtime scenario identity](../../../tests/capabilities/test-architecture/runtime-scenario-identity.tests.ps1) | 1 | [Test architecture](../../../tests/capabilities/test-architecture/test-architecture.tests.ps1) | `InfrastructureContract`; synthetic results directly test exact-once evidence. |
| [Role boundaries](../../../tests/capabilities/test-architecture/role-boundaries.tests.ps1) | 2 | [Test architecture](../../../tests/capabilities/test-architecture/test-architecture.tests.ps1), [utility ownership](../../../tests/capabilities/test-architecture/canonical-utility-ownership.tests.ps1) | `InfrastructureContract`; inert fixtures directly test roles and transition closure. |
| [Test runtime efficiency](../../../tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1) | 3 | Quick adoption, bootstrap, instruction graph, and workflow owners above | `InfrastructureContract`; fixture ownership and operation budgets do not reuse child-suite green results as product proof. |
| [Recurrence prevention](../../../tests/capabilities/protocol-governance/recurrence-prevention.tests.ps1) | 1 | [Protocol governance](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1) | `Distinct`; direct recurrence-routing contract, not product-oracle re-execution. |
| [Capability review](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1) | 10 | [Capability catalog](../../../tests/capabilities/capability-adoption/capability-catalog.tests.ps1), [merge finalization](../../../tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1) | `Distinct`; semantic review/recovery differs from catalog parsing and ordinary finalization. |

No cross-owner semantic duplicate was proven. The two owner-local collisions
below are the complete remediation set.

## Decisions and relationships

- Decisions: [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  and [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md).
- Parent epic: N/A - bounded protocol clarification.
- Dependencies: [FEAT-0051](../FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md)
  and immutable [v0.15.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.1).
- Separate residual: [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
  begins its refreshed baseline only after this feature closes.

## Definition of Ready

- [x] Stable [FEAT-0053](README.md) ID and [linked issue](https://github.com/hasanmanzak/meAndAI/issues/133).
- [x] Problem, outcome, scope, and non-goals.
- [x] Acceptance criteria.
- [x] Domain/boundary contracts, consumers, and dependencies.
- [x] Numbered risks and [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md).
- [x] Reviewable decomposition with a gate ledger.
- [x] [TEST-0190](test-cases.md#test-0190) and retained canonical scenario intent.
- [x] Test-code and baseline-run states recorded.
- [x] Prior-art, active recurrence routes, and finite same-contract inventory recorded.

The maintainer's standing directive to continue the ordered backlog authorizes
implementation after this Gate 1 record.

## Acceptance criteria

1. The protocol and feature/test templates require nearest-sibling and distinct
   intent review for every new or changed numbered scenario.
2. The finite review covers all 23 current executable owners without creating a
   second registry.
3. Every reviewed relationship uses one declared disposition and the complete
   intent tuple.
4. [TEST-0081](../FEAT-0013-v084-correction/test-cases.md#test-0081) and
   [TEST-0082](../FEAT-0013-v084-correction/test-cases.md#test-0082) remain as
   historical superseded evidence while their material behavior is retained by
   [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) and
   [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070).
5. Direct infrastructure-contract tests retain one owner and do not reassert
   another scenario's product oracle.
6. Canonical suites cannot dispatch other canonical suites; only the root
   runner owns dispatch and aggregation.
7. Existing helper, runtime-evidence, role, fixture, workflow, and immutable
   capability authorities are not recreated or mutated.
8. Any runtime observation is linked to
   [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
   without satisfying its acceptance criteria.

## Self-review

Review scope is limited to the prospective protocol/templates, one new
decision, the canonical scenario authority, the existing role-boundary owner,
the two superseded documentation records, their existing quick-adoption owner,
version/memory surfaces, release evidence, and the one self-consumer graph
capacity blocker exposed by the final suite. The budget is one focused review
per slice, one fresh-diff review, and one final canonical suite after proven
blocker correction.

| ID | Severity | Disposition | Finding | Resolution |
| --- | --- | --- | --- | --- |
| `FIND-0289` <a name="find-0289"></a> | High | `Blocking` / Resolved | [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) and [TEST-0081](../FEAT-0013-v084-correction/test-cases.md#test-0081) shared the same ownership-marker contract, ambiguity risk, launcher-integration evidence, and exercised variants; the executable owner confirmed both from the same oracle. | The complete marker fixture family remains under [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069), [TEST-0081](../FEAT-0013-v084-correction/test-cases.md#test-0081) is historical superseded authority, and [TEST-0190](test-cases.md#test-0190) protects the general boundary. |
| `FIND-0290` <a name="find-0290"></a> | High | `Blocking` / Resolved | [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070) and [TEST-0082](../FEAT-0013-v084-correction/test-cases.md#test-0082) shared the same secret-lock state-transition tuple; the latter additionally read the former's Markdown row as its only extra oracle. | Contention, ownership-change, and rerun behavior remain under [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070); the source-row oracle is removed and [TEST-0082](../FEAT-0013-v084-correction/test-cases.md#test-0082) is historical superseded authority. |
| `FIND-0291` <a name="find-0291"></a> | High | `Blocking` / Resolved | Test-first execution exposed a StrictMode defect in the shared role inspector: a dynamic member AST was read through `.Value` as though every member were a string constant. | The canonical role helper now inspects `.Value` only for `StringConstantExpressionAst`; the focused [TEST-0190](test-cases.md#test-0190) owner passes across all 23 canonical suites. |
| `FIND-0292` <a name="find-0292"></a> | Medium | `Blocking` / Resolved | The first cross-suite guard treated legitimate infrastructure fixtures that launch synthetic child suites as forbidden canonical-suite dependencies. | The rejected role-wide design was removed. The final guard detects only direct/static dispatch to another canonical owner and preserves synthetic infrastructure-contract execution. |
| `FIND-0293` <a name="find-0293"></a> | Medium | `Blocking` / Resolved | The first StructureOnly run found [TEST-0190](test-cases.md#test-0190) registered as both planned and executable, while [TEST-0081](../FEAT-0013-v084-correction/test-cases.md#test-0081) and [TEST-0082](../FEAT-0013-v084-correction/test-cases.md#test-0082) used explanatory status text instead of the canonical exact `Superseded` value. | Removed the obsolete planned authority and kept replacement links in each historical row while restoring the exact status contract. |
| `FIND-0294` <a name="find-0294"></a> | High | `Blocking` / Resolved | Fresh-diff review found that the first guard detected static command arguments but could miss direct `& $suitePath` or `powershell -File $suitePath` dispatch after a simple static assignment. | The existing [TEST-0190](test-cases.md#test-0190) owner now resolves bounded same-file static assignments used by direct invocation forms; inert direct, variable, joined-variable, and synthetic-child cases prove detection without broad semantic inference. |
| `FIND-0295` <a name="find-0295"></a> | Medium | `Blocking` / Resolved | The finite review table retained its 181-identity baseline counts after the two supersessions and [TEST-0190](test-cases.md#test-0190) addition, which made the baseline look like the final authority state. | The record now labels baseline counts explicitly and records the exact post-change result: 23 owners, 180 active identities, Quick Adoption 39, and Role Boundaries 3. |
| `FIND-0296` <a name="find-0296"></a> | High | `Blocking` / Resolved | Fresh-diff review found [TEST-0190](test-cases.md#test-0190) hard-coding the 23-owner baseline and requiring every future canonical owner path to remain copied into the completed [FEAT-0053](README.md) record. That turned one-time audit evidence into a second live registry. | Removed the cardinality and historical-document parity assertions. The bounded dispatch guard now consumes whatever executable owners the canonical scenario authority declares, while the 23-owner audit remains immutable delivery evidence only. |
| `FIND-0297` <a name="find-0297"></a> | High | `Blocking` / Resolved | Fresh-diff review found the first variable-aware dispatch guard pooling same-named assignments across the whole file without scope or execution order, allowing unrelated canonical-path data to falsely block a synthetic child invocation. | Candidate resolution is now limited to the command's nearest scriptblock, assignments before the command, and the nearest prior assignment. Separate-scope and later-assignment inert cases protect the negative boundary. |
| `FIND-0298` <a name="find-0298"></a> | High | `Blocking` / Resolved | The first scope-aware implementation rescanned a complete scriptblock for every command variable and timed out after 124 seconds; it also compared PowerShell variable names and Windows dispatch paths case-sensitively. | Assignments are indexed once by scope and case-insensitive variable name, nearest-prior selection is linear within that small bucket, and Windows path matching uses ordinal-ignore-case. A mixed-case fixture protects both semantic boundaries. |
| `FIND-0299` <a name="find-0299"></a> | High | `Blocking` / Resolved | The first final suite stopped at [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152): immutable `v0.15.1` already used 16,015 of 16,384 graph path-inventory bytes, while the four required `v0.15.2` records and exact owner links produced 16,883. Review also found the current 512-node production ceiling still projected as 256 in [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) and the historical feature. | The current path-inventory and per-path ceiling alone increases to 32,768 bytes; exact N/N+1 rejection, node/edge/depth/blob/tree limits, committed-base integrity, and older immutable limits remain unchanged. The deterministic graph digest and compact-serialization golden values are re-bound to the new release-declared limit. [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) and [FEAT-0037](../FEAT-0037-v0126-instruction-graph-adoption-containment/README.md) now project both the already-released 512-node correction and this measured capacity correction. |

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Bounded self-review and required convergence scan complete.
- [x] No unresolved `Blocking` finding; every other disposition has evidence.
- [x] Documentation, links, version, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #133](https://github.com/hasanmanzak/meAndAI/issues/133) |
| Release authority | Pending immutable `v0.15.2` publication |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
