# Successor Delivery and Qualification Plan

| Field | Value |
| --- | --- |
| Classification | Accepted architecture allocation |
| Parent epic | [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163) |
| Architecture task | [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164) |
| Decision | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) |
| Implementation authority | Scoped only to [SUBF-0152](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152) |

This plan allocates the accepted architecture to stable delivery records. It
did not itself authorize implementation. The later
[scoped directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932)
authorizes only [SUBF-0152](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
and [TEST-0220](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220),
including that scenario's route inside both existing stable jobs. WIP
extraction, other C# or test implementation, consumer mutation, release
publication, authority transfer, and PowerShell retirement remain unauthorized.
The [infrastructure clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847)
also permits only the corresponding assertion in existing
[TEST-0146](../../features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146).

## 1. Capability ownership

| Boundary | Stable owner | Outcome | Planning tests |
| --- | --- | --- | --- |
| 1. Shared conformance | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) / [issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) | Protocol-owned domain, rule catalog, evaluator kernel, typed evidence, canonical report, extension semantics, qualification, and self-consumption | Feature scenarios [TEST-0209](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0209), [TEST-0210](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210), and [TEST-0211](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0211); dependency-closed contracts [TEST-0220](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220), [TEST-0221](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221), and [TEST-0222](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0222) |
| 2. Shared execution authority | [FEAT-0066](../../features/FEAT-0066-shared-execution-authority-foundation/README.md) / [issue #166](https://github.com/hasanmanzak/meAndAI/issues/166) | Authority snapshots, grants, separation, activation CAS, publication envelopes, leases, fences, journal, receipts, reconstruction, and recovery | [TEST-0212](../../features/FEAT-0066-shared-execution-authority-foundation/test-cases.md#test-0212) and [TEST-0213](../../features/FEAT-0066-shared-execution-authority-foundation/test-cases.md#test-0213) |
| 3. Evidence and consumer integration | [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) / [issue #167](https://github.com/hasanmanzak/meAndAI/issues/167) | Exact Git/GitHub acquisition, Trust Bootstrap, immutable resolution, managed hook, evaluator host, and result publisher | [TEST-0214](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/test-cases.md#test-0214), [TEST-0215](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/test-cases.md#test-0215), and [TEST-0216](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/test-cases.md#test-0216) |
| 4. Adoption | [FEAT-0061](../../features/FEAT-0061-consumer-adoption-cli/README.md) / [issue #156](https://github.com/hasanmanzak/meAndAI/issues/156) | Adoption assessment, explicit strategy, sealed planning, authorized apply, closure, finalization, and recovery | Existing [TEST-0197](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0197), [TEST-0198](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0198), [TEST-0200](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0200), and [TEST-0201](../../features/FEAT-0061-consumer-adoption-cli/test-cases.md#test-0201) remain planned |
| 5. Update | [FEAT-0062](../../features/FEAT-0062-consumer-protocol-update-cli/README.md) / [issue #157](https://github.com/hasanmanzak/meAndAI/issues/157) | Installed-state validation, side-by-side handoff, migration resolution, sealed planning, authorized apply, proposal closure, finalization, and recovery | Existing [TEST-0202](../../features/FEAT-0062-consumer-protocol-update-cli/test-cases.md#test-0202), [TEST-0203](../../features/FEAT-0062-consumer-protocol-update-cli/test-cases.md#test-0203), and [TEST-0204](../../features/FEAT-0062-consumer-protocol-update-cli/test-cases.md#test-0204) remain planned |
| 6. Protocol release finalization | [FEAT-0068](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md) / [issue #168](https://github.com/hasanmanzak/meAndAI/issues/168) | Predecessor-trusted release planning, least-authority publication, fresh verification, distinct authority transfer, and recovery | [TEST-0217](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/test-cases.md#test-0217), [TEST-0218](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/test-cases.md#test-0218), and [TEST-0219](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/test-cases.md#test-0219) |
| 7. Compatibility and migration | [FEAT-0063](../../features/FEAT-0063-consumer-migration-powershell-retirement/README.md) / [issue #158](https://github.com/hasanmanzak/meAndAI/issues/158) | Differential qualification, supported-consumer authority migration, and eventual dependency-proven PowerShell retirement | Existing [TEST-0205](../../features/FEAT-0063-consumer-migration-powershell-retirement/test-cases.md#test-0205), [TEST-0206](../../features/FEAT-0063-consumer-migration-powershell-retirement/test-cases.md#test-0206), and [TEST-0207](../../features/FEAT-0063-consumer-migration-powershell-retirement/test-cases.md#test-0207) remain planned |

The historical path names of [FEAT-0061](../../features/FEAT-0061-consumer-adoption-cli/README.md)
and [FEAT-0062](../../features/FEAT-0062-consumer-protocol-update-cli/README.md)
are retained to avoid destructive record moves. Their product boundary is the
application lifecycle, not CLI syntax. [FEAT-0063](../../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
retains its original consumer-migration and retirement identity; compatibility
qualification is a prerequisite, not a generic residual-work bucket.

## 2. Dependency direction

1. [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md)
   and [FEAT-0066](../../features/FEAT-0066-shared-execution-authority-foundation/README.md)
   are independent shared foundations over completed
   [FEAT-0059](../../features/FEAT-0059-csharp-operational-foundation/README.md).
2. [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
   consumes both foundations and owns external evidence and host adapters.
3. [FEAT-0061](../../features/FEAT-0061-consumer-adoption-cli/README.md),
   [FEAT-0062](../../features/FEAT-0062-consumer-protocol-update-cli/README.md),
   and [FEAT-0068](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
   consume the shared authority foundation. They cannot recreate grants,
   journals, leases, receipts, or recovery.
4. [FEAT-0063](../../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
   remains parked until immutable successor releases and fresh supported-
   consumer evidence exist.

Five least-authority process hosts remain component adapters inside the owning
features. They are not five products and do not receive separate feature or
release identities merely because they have separate composition roots.

## 3. Release planning

The required structural target-version field is retained without turning
features into separately packaged CLI products:

- [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md),
  [FEAT-0066](../../features/FEAT-0066-shared-execution-authority-foundation/README.md),
  [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md),
  and [FEAT-0068](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
  are planned into the first coherent protocol-platform release, 0.17.0;
- [FEAT-0061](../../features/FEAT-0061-consumer-adoption-cli/README.md) retains
  0.18.0, [FEAT-0062](../../features/FEAT-0062-consumer-protocol-update-cli/README.md)
  retains 0.19.0, and [FEAT-0063](../../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
  retains 0.20.0; and
- these targets are planning order, not implementation authority or permission
  to publish one ZIP per feature. Every release remains one protocol
  distribution with an explicit component and compatibility manifest.

## 4. Governed surface coverage

The architecture is not a permalink validator and is not limited to Markdown.
Rule semantics and evidence acquisition are separated across all planned
surfaces:

| Surface family | Common rule ownership | Evidence ownership |
| --- | --- | --- |
| Repository tree, file structure, bytes, Git objects, candidate state | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| Protocol documents, records, IDs, anchors, links, instruction graphs, ledgers, and memory | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| Issues, pull requests, conversation comments, reviews, inline comments, commit comments, labels, checks, and rulesets | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| Workflows, event payloads, permissions, managed projections, and full inventories | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| Releases, assets, manifests, digests, runtime/policy binding, and authority anchors | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) and [FEAT-0068](../../features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md) |
| Adoption/update plans, grants, mutations, journals, receipts, closure, recovery, and finalization | Applicable conformance rules in [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | Application evidence from [FEAT-0061](../../features/FEAT-0061-consumer-adoption-cli/README.md), [FEAT-0062](../../features/FEAT-0062-consumer-protocol-update-cli/README.md), and the shared [FEAT-0066](../../features/FEAT-0066-shared-execution-authority-foundation/README.md) foundation |

## 5. First rule/specification/qualification/evidence matrix

This is the first rule/catalog implementation slice, not the first prerequisite
code slice and not the complete catalog. Authorized
[SUBF-0152](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
establishes scalar vocabulary only and grants no catalog or evaluator authority.
Later rule inventory work must cover every normative contract and may add stable
rule identities without changing these meanings. A rule is shared even when
its evidence comes from different repository or provider adapters.

For record-shape rules, the exact protocol-owned template is part of the
normative source: the documentation graph establishes the record class and
location, while the template establishes its required structural fields and
sections. An evaluator cannot infer structure beyond those exact sources.

| Rule | Normative contract and fragment | Existing qualification | Evaluator owner | Evidence modes |
| --- | --- | --- | --- | --- |
| `RULE-0001` <a name="rule-0001"></a> | Every feature packet contains both required documents under the [documentation graph](../../../PROTOCOL.md#6-documentation-graph) | [TEST-0004](../../features/FEAT-0001-common-development-protocol/test-cases.md#test-0004) | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | Exact Git tree and explicitly non-authoritative candidate snapshot through [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| `RULE-0002` <a name="rule-0002"></a> | Every numbered decision exists under the [documentation graph](../../../PROTOCOL.md#6-documentation-graph) and follows the exact required structure in the [canonical decision template](../../../templates/decision.md#dec-nnnn---decision-title) | [TEST-0005](../../features/FEAT-0001-common-development-protocol/test-cases.md#test-0005) | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | Exact Git tree and candidate snapshot through [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| `RULE-0003` <a name="rule-0003"></a> | A governed cross-record reference is a clickable link to the exact target under the [documentation graph](../../../PROTOCOL.md#6-documentation-graph) | Repository [TEST-0175](../../features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175) and provider-surface [TEST-0176](../../features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176) | One shared evaluator in [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | Repository documents, issues, pull requests, comments, reviews, and commit comments; pagination/completeness belongs to [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| `RULE-0004` <a name="rule-0004"></a> | A cross-document reference to an embedded record targets its unique stable fragment under the [documentation graph](../../../PROTOCOL.md#6-documentation-graph) | [TEST-0177](../../features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177) | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | Repository and provider Markdown with typed document/record locations through [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |
| `RULE-0005` <a name="rule-0005"></a> | A human-facing commit reference resolves to the exact full-SHA commit permalink in its owning repository under the [documentation graph](../../../PROTOCOL.md#6-documentation-graph) | [TEST-0178](../../features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) | [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md) | Repository/provider text plus Git-object/provider proof through [FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) |

[TEST-0176](../../features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176)
therefore does not become a GitHub-only rule. Its shared link semantics belong
to [FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md);
enumeration, pagination, freshness, and acquisition completeness belong to
[FEAT-0067](../../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).

## 6. Delivery gates

| Gate | State after this planning packet |
| --- | --- |
| Maintainer architecture acceptance | Satisfied; [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) is accepted |
| Independent architecture red-team | Satisfied at design level in the [review register](red-team-review.md) |
| Stable successor features and issue links | Satisfied by this plan |
| First rule/specification/qualification/evidence matrix | Satisfied at design level by [the first matrix](#5-first-rulespecificationqualificationevidence-matrix) |
| Exact WIP disposition and destination | Satisfied at design level by the [WIP extraction ledger](wip-extraction-ledger.md); no extraction is authorized |
| Selected-slice Gate 1 and expected-red design | Satisfied only for [SUBF-0152](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152) / [TEST-0220](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220) by the [design record](../../features/FEAT-0065-shared-executable-conformance-runtime/subf-0152-domain-vocabulary-design.md); executable Gate 3 red remains pending |
| Feature Gate 2 design review | Satisfied only for [SUBF-0152](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152) by the [design record](../../features/FEAT-0065-shared-executable-conformance-runtime/subf-0152-domain-vocabulary-design.md); every other slice remains unsatisfied |
| Exact accepted-head structural validation | Satisfied by merged [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169) and exact-main [run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367) |
| Separate maintainer implementation directive | Issued only for [SUBF-0152](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152) / [TEST-0220](../../features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220) in the [scoped directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932) |

The first eligible implementation directive should name exactly one
dependency-closed feature or subfeature. It must not authorize broad
cherry-picking, workflow changes, consumer mutation, release publication, or
authority transfer unless those actions are explicitly within that reviewed
slice.
