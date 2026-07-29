# Architecture Transition and Carry-Forward Register

| Field | Value |
| --- | --- |
| Owner | [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164) |
| Current default-branch baseline | [`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd) |
| Preserved WIP | [`1873c98638ba4960734aadb188eb8c8d70b4bc52`](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52) on [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) |
| Transition state | Architecture hold; no implementation extraction authorized |

This register changes prospective ownership without rewriting historical
evidence. A prior exact commit or workflow run proves only the code and
contract that it actually evaluated.

## 1. Record disposition

| Record | Current truth | Architecture disposition |
| --- | --- | --- |
| [EPIC-0001 / issue #153](https://github.com/hasanmanzak/meAndAI/issues/153) | Open CLI/PowerShell-migration epic | Freeze now. After architecture acceptance, close as prospectively superseded by [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163); do not rewrite its original outcome. |
| [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163) | Proposed protocol-platform authority | New active architecture authority. Implementation remains unauthorized. |
| [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164) | Architecture design | Owns this architecture, red-team review, and transition register only. |
| [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) | Accepted default-branch decision | Preserve C#, typed shared foundation, portable JIT, read-only governance, authority states, plan/apply separation, and single-engine mutation. On acceptance, [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) supersedes separate CLI/application products as the architectural center. |
| [DEC-0033](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/decisions/DEC-0033-specification-first-csharp-governance.md) on preserved WIP | Accepted on draft, never default-branch authority | Identifier remains reserved. Incorporate specification-first C# and legacy-black-box-oracle reasoning into [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md); do not present the draft record as merged history. |
| [DEC-0034](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/decisions/DEC-0034-bounded-reusable-governance-catalog.md) on preserved WIP | Accepted on draft, never default-branch authority | Identifier remains reserved. Incorporate parse-once/catalog/report reuse; reject the two-rule CLI/one-ZIP scope as target architecture. |
| [FEAT-0059](../../features/FEAT-0059-csharp-operational-foundation/README.md) / [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) | Complete in immutable `v0.16.0` | Retain as a completed technical prerequisite. Do not reopen or relabel its exact release evidence. |
| [SUBF-0141 / issue #162](https://github.com/hasanmanzak/meAndAI/issues/162) | Complete shared process extension on [PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) branch | Retain historical completion evidence. Any carried implementation is independently reviewed in successor work. |
| [FEAT-0060 / issue #155](https://github.com/hasanmanzak/meAndAI/issues/155) | Default branch says proposed; draft branch contains four of seven implemented/verified slices | Freeze. Preserve both truths explicitly: four slices have exact draft-branch evidence; the parent was not completed, merged, released, or granted authority, and three slices remain incomplete. After approved extraction, supersede prospectively. |
| [Draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) | Open draft at preserved exact head | Keep draft and stop implementation pushes. Extract only approved items into new main-based successor work. Close as superseded only after extraction is independently verified; do not delete its branch first. |
| [FEAT-0061 / issue #156](https://github.com/hasanmanzak/meAndAI/issues/156) | Proposed adoption CLI; no implementation authority | Freeze. After architecture acceptance, rescope to the adoption application and adapters without changing its historical test state. |
| [FEAT-0062 / issue #157](https://github.com/hasanmanzak/meAndAI/issues/157) | Proposed update CLI; no implementation authority | Freeze. After architecture acceptance, rescope to the update application and adapters. |
| [FEAT-0063 / issue #158](https://github.com/hasanmanzak/meAndAI/issues/158) | Proposed migration/retirement work | Park. PowerShell retirement is not a precondition for defining or initially delivering the new platform. Reactivate only after supported authority-transfer evidence exists. |
| [FEAT-0064 / issue #161](https://github.com/hasanmanzak/meAndAI/issues/161) | Draft-branch coverage/equivalence record | Freeze. Carry rule coverage into successor conformance work; keep PowerShell equivalence/retirement qualification as a later compatibility concern. |

## 2. Test and evidence disposition

| Evidence | Disposition |
| --- | --- |
| [TEST-0191](../../features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191), [TEST-0192](../../features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192), and [TEST-0193](../../features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193) | Retain as passing [FEAT-0059](../../features/FEAT-0059-csharp-operational-foundation/README.md) foundation evidence. |
| Canonical [TEST-0004](../../features/FEAT-0001-common-development-protocol/test-cases.md#test-0004) and [TEST-0005](../../features/FEAT-0001-common-development-protocol/test-cases.md#test-0005) | Retain unchanged as qualification scenarios mapped to future `RULE-NNNN` identities; they are not themselves rule identities or CLI-specific behavior. |
| Draft [TEST-0194](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194) and [TEST-0195](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195) | Retain their exact draft-commit passing evidence; do not use it as successor completion evidence. |
| Draft [TEST-0208](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0208) | Remains planned/unactivated; existing code on the preserved head is not accepted proof. Review under the new profile/evidence model. |
| [TEST-0196](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196) | Park with PowerShell compatibility/equivalence work. |
| [TEST-0197](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0197), [TEST-0198](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0198), [TEST-0200](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0200), [TEST-0201](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0201), [TEST-0202](../../features/FEAT-0062-consumer-protocol-update-cli/test-cases.md#test-0202), [TEST-0203](../../features/FEAT-0062-consumer-protocol-update-cli/test-cases.md#test-0203), [TEST-0204](../../features/FEAT-0062-consumer-protocol-update-cli/test-cases.md#test-0204), [TEST-0205](../../features/FEAT-0063-consumer-migration-powershell-retirement/test-cases.md#test-0205), [TEST-0206](../../features/FEAT-0063-consumer-migration-powershell-retirement/test-cases.md#test-0206), and [TEST-0207](../../features/FEAT-0063-consumer-migration-powershell-retirement/test-cases.md#test-0207) | Freeze as planned. Re-evaluate each contract after adoption/update application rescope; never mark them passing by inheritance. |
| Workflow runs on [PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) | Immutable historical evidence for their exact tested heads and merge refs only. |
| `[skip ci]` preservation commit | Preservation proof, not executable qualification. |

The required wording for future closure/rescope comments is:

> Four of seven bounded subfeatures were implemented and verified on exact
> draft-branch commits. The parent feature was not completed, merged, released,
> or granted production authority. Three remaining subfeatures were not
> completed. This record is superseded prospectively; its historical commit and
> run evidence is unchanged.

## 3. WIP code classification

| WIP asset or concept | Class | Target treatment |
| --- | --- | --- |
| [FEAT-0059](../../features/FEAT-0059-csharp-operational-foundation/README.md) typed domain/result/port contracts | Reusable | Map into the new domain/application boundary after independent review. |
| Binary-safe bounded process runner and process isolation | Reusable design; unaccepted WIP implementation | Carry only with fresh tests and review because the implementation is not on main. |
| Exact Git object reader/parser/process policy | Reusable design; unaccepted WIP implementation | Use in exact Git evidence adapter after fresh qualification. |
| Immutable snapshot identity, ordering, and SHA-256 evidence digest | Reusable | Generalize across repository and provider evidence. |
| Parse-once Markdown and protocol-record indexes | Refactor required | Extend the evidence model beyond feature/decision files without creating a universal parser. |
| Canonical [TEST-0004](../../features/FEAT-0001-common-development-protocol/test-cases.md#test-0004) / [TEST-0005](../../features/FEAT-0001-common-development-protocol/test-cases.md#test-0005) qualification scenarios and fixtures | Reusable | Map to future common baseline rule identities as qualification evidence; never treat TEST identity as RULE identity. |
| Hard-coded two-rule catalog | Historical slice only | Do not use as the target catalog boundary. |
| Authority/consumer role distinction | Reusable concept | Keep as one subject-role axis, not the whole profile. |
| Single-string authority/consumer profile resolver | Reject as target | Replace with independent role, operation, snapshot, surface, and enforcement axes; adapter/evidence capability and grants stay outside semantic applicability. |
| `.ai/protocol` gitlink and exact `VERSION` verification | Adapter-specific reuse | Keep as the canonical Git-reference resolver, not a universal rule. |
| Deterministic canonical JSON, report digest, and fail-closed rule inventory | Reusable | Generalize to typed locations, provider acquisition, and separated outcomes. |
| Repository-path-only findings | Refactor required | Replace with discriminated repository/provider/release locations. |
| `CSharpShadow`, `PowerShellAuthority`, and `bounded-catalog` as permanent report semantics | Transition-only | Keep only in compatibility/authority-transfer evidence where applicable. |
| Governance CLI grammar and exit-code ABI | Host-only historical input | It may inform a thin host; it cannot constrain the domain/application contract. |
| Assembly policy-source provenance | Reusable with refactor | Bind it in the release envelope rather than CLI packaging semantics. |
| Generic deterministic ZIP/manifest/verifier | Reusable | Adapt into the one protocol distribution builder/verifier. |
| Three independent CLI/ZIP products | Reject as product model | Publish one protocol release with shared runtime and five least-authority thin hosts: evaluator, report publisher, adoption, update, and protocol release finalizer. |

“Reusable” means architecturally compatible, not already accepted target code.
Every extracted implementation receives new exact-head tests and review.

## 4. Successor capability boundaries

Stable successor feature IDs are allocated only after
[DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
is accepted.
The required capability boundaries are nevertheless fixed:

1. shared conformance domain, abstractions, kernel, baseline catalog, typed
   evidence, canonical report, protected-base extension transitions,
   qualification fixtures, and self-consumption;
2. shared execution-authority foundation: authority-set snapshots and role
   separation, typed grants/capabilities, protected extension-activation
   records/CAS, publication envelopes, leases/fences, durable journal/retention
   stores, receipts, recovery grants, and fail-closed reconstruction. Boundaries
   3 through 6 must consume this one foundation and cannot reimplement or omit
   it;
3. repository/Git and GitHub acquisition, Trust Bootstrap, immutable
   distribution resolution, managed consumer hook, read-only event/full-
   inventory evaluation, and result publication through boundary 2;
4. adoption assessment, strategy, exact planning, separately authorized apply,
   interruption recovery, direct or provider exact-target closure, and
   finalization through boundary 2;
5. update installed-state validation, side-by-side target-runtime handoff,
   deterministic migration resolution, exact planning, separately authorized
   apply, proposal lifecycle, direct or provider exact-target closure,
   explicit legacy-handoff-pending reconciliation, finalization, and recovery
   through boundary 2;
6. protocol-authority release planning, predecessor-trusted executor/broker,
   least-authority publication, post-publication verification, distinct
   authority transfer, and interrupted publish/transfer recovery through
   boundary 2; and
7. compatibility qualification, consumer authority migration, and eventual
   PowerShell authority/compatibility/source retirement.

These are application/capability boundaries. They must not be named or scoped
as CLI products.

## 5. Temporary workflow posture

No workflow file, trigger, required check, ruleset, test filter, or timeout is
changed during the architecture phase.

- [PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) remains draft and
  receives no implementation push.
- Architecture commits use `[skip ci]` while the packet is under review.
- Existing runs remain immutable historical evidence.
- A successor implementation must run all tests required by its new exact
  contracts; old green runs are not reused.
- The normal governance stability claim may remain temporarily unavailable.

This pause avoids recurring full-suite runner cost without converting a
temporary architecture hold into permanent evidence weakening.

## 6. Exit conditions

The register may move from `Architecture hold` only after:

1. the maintainer accepts [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md);
2. the architecture red-team checklist is closed;
3. successor features and test matrices are allocated;
4. each selected WIP asset has an approved destination and required fresh
   evidence; and
5. a separate implementation directive is issued.
