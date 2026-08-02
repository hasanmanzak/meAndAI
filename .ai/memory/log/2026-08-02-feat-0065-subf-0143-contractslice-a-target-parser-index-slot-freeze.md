# ContractSlice A target parser/index/slot frozen design

| Field | Value |
| --- | --- |
| Date | 2026-08-02 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-GOVERNED-REFERENCE-SLOTS-01` is remote-equal exact-head hosted green; `A-TARGET-PARSER-INDEX-SLOT-01` is a `FrozenDesign` with no implementation, expected-red invocation, or green claim |
| Predecessor | Exact [`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602), git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`; remote branch and draft PR head are equal; [run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121) passed Ubuntu and Windows; publication verification was correctly skipped |
| Progress | Eight of twenty packets are `ReviewedLocalGreen` (`40%`); cumulative A is `21/21`; target green would become `22/22` and nine of twenty (`45%`); [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen identity and activation gate

- Operational label remains `A-TARGET-PARSER-INDEX-SLOT-01`; its indivisible
  vertical explicitly includes the repository-target schema/model row because
  the parser, index, and slot cannot close without it.
- Reserved FQN:
  `MeAndAI.Protocol.Conformance.Tests.ContractSliceATargetParserIndexSlotManifestTests.Enforces_exact_repository_target_schema_parser_index_and_slot_capability_closure`.
- Marker/TRX stem: `TEST-0210-A-BEHAVIOR-RED-0007`; one Fact; only
  `ContractSlice=A`; no `Scenario`.
- Before canonical R, locked restore and six lock hashes must match, then the
  unchanged predecessor Fact must pass `1/1` and cumulative A must pass `21/21`.
  This freeze must be reviewed, committed, pushed, and exact-head hosted green
  before the expected-red invocation is authorized.

## Exact cumulative topology

- Green topology is exact `3 schema / 2 parser / 4 index / 4 evaluation slot`,
  `0` applicability slot, `0` demand projector, `0` admission proof, `20`
  components, `3` artifacts, and unchanged cache
  `(512,67108864,128,2000000,8,4,retain-lowest-canonical-keys)`.
- Canonical declaration order is exact: schemas governed-text,
  repository-target-resolution, repository-tree; parsers markdown,
  repository-target-markdown; indexes governed-reference, protocol-record,
  repository-target-resolution, repository-tree; evaluation slots
  provider-governed-text, repository-governed-text,
  repository-target-resolution, repository-tree.
- The target schema is `protocol.repository-target-resolution/1`; codec
  component `protocol.codec.repository-target-resolution/1` /
  `MeAndAI.Protocol.Policy` /
  `MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec`; output model
  `protocol.model.repository-target-resolution/1` through component
  `protocol.type.model.repository-target-resolution/1` /
  `MeAndAI.Protocol.Policy` /
  `MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel`; retention
  `(1,33554432)`; budget `(33554432,64,500000,34054432)`; ordered failures
  `protocol.codec.embedded-identity-mismatch`,
  `protocol.codec.invalid-repository-target-resolution`,
  `protocol.codec.payload-location-mismatch`,
  `protocol.codec.resource-limit-exceeded`.
- The target parser is `protocol.parser.repository-target-markdown/1` /
  `MeAndAI.Protocol.Policy` /
  `MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser`, with
  exact-one target-resolution model input and output model
  `protocol.model.repository-target-markdown-document-set/1` through component
  `protocol.type.model.repository-target-markdown-document-set/1` /
  `MeAndAI.Protocol.Policy` /
  `MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel`;
  budget `(33554432,256,1000000,34554432)`; sole failure
  `protocol.budget.exhausted`.
- The target index component is
  `protocol.index.repository-target-resolution/1` /
  `MeAndAI.Protocol.Policy` /
  `MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex`, `PerPlan`,
  with canonical wire inputs target-Markdown-set model `(0,null)`,
  target-resolution model `(0,null)`, then governed-reference capability
  `(1,1)`; output `protocol.capability.repository-target-resolution-index/1`
  through component `protocol.type.capability.repository-target-resolution-index/1`
  / `MeAndAI.Protocol.Conformance.Abstractions` /
  `MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex`;
  budget
  `(67108864,256,2000000,20000000)`; failures `protocol.budget.exhausted` then
  `protocol.index.repository-target-resolution-unavailable`.
- The target slot is `protocol.slot.repository-target-resolution`; requirement
  `protocol.requirement.repository-target-resolution` on Repository surface;
  kind `protocol.evidence.repository-target-resolution-set`; completeness
  `protocol.completeness.all-projected-target-resolutions`; target schema;
  exactly `ExactSnapshot` then `ObjectVersionBound`; Repository then Provider
  profiles; material `protocol.material.repository-target-resolution`; selector
  `protocol.target.repository-target-resolution-set`; and only the target-index
  capability.
- Existing exact `2/1/2/2` and `2/1/3/3` predecessors remain valid; only exact
  `3/2/4/4` is added. Every hybrid count or partial target vertical fails closed.

## Expected red, allowlist, budgets, and holds

- Transient setup and the runtime-created expected exception are outside the
  catch. `CanonicalManifestWriter.Write(parsed)` is the first and only guarded
  cross-graph/serialization observation. Only exact runtime `ArgumentException`,
  `ParamName == "rules"`, and the runtime-created message for
  `The parser and protocol-record graph is not exact.` emit marker 0007; every
  setup, filter mismatch, Catalog call, or other exception stays marker-free.
- Anticipated production owner is only `CatalogSliceDeclaration.cs`; Reader and
  Writer are regression-only. One new retained test file is allowed. A required
  Reader/Writer/public-API/project/solution/package/lock/workflow change returns
  the packet to D/RT.
- Hard caps are gross changed-line counts against the exact predecessor:
  Catalog/production `180`, retained test `500`, combined `680`. Exceeding any
  cap requires redraw; no source packing or assertion loss.
- Positive proof owns byte-identical write/parse/rewrite, digest/projection,
  the exact four collection orders/lookups, full target identities, budgets,
  failures, component/artifact/cache closure, and predecessor preservation.
  One-at-a-time negatives own schema key/version, codec/output bindings,
  retention, budget, and ordered failures; parser component/input/output,
  budget, and sole failure; index component/scope, all three ordered input
  union arms, cardinalities/omitted maxima, output, budget, and ordered
  failures; slot key, requirement key/surface, kind, completeness,
  schema/version, consistency/profile orders, material, selector, and sole
  capability; missing/wrong/unused component-artifact closure; producer
  binding; collection order; every individually or jointly partial target
  topology; and held-array rejection. Removing the entire schema/model,
  parser, index, and slot vertical reconstructs valid `2/1/3/3` and is the sole
  non-negative target removal.
- Projector/DAG, finding, selector, admission, profile/predecessor/transition,
  lifecycle/resource, final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
  B/C/D, merge, release, publication, and consumer mutation remain held.
- Preliminary read-only preparation reported `2 Blocking / 3 Important / 0
  Minor`. Disposition is exact: predecessor hosted proof is closed by
  `6b49de76d7420c33a3707c3aeeab78b4362fb602` / run `30753246121`; the missing
  schema blocker is closed by the indivisible `3/2/4/4` vertical; index input
  order is frozen to the canonical wire order; Catalog-only Writer-first
  feasibility is frozen; and the exact mutation matrix plus `180/500/680` caps
  close the remaining scope and implementability findings. After the final two
  full failure-code literals were corrected, three independent current-tree
  D/RT pass-3 reviews each closed `0 Blocking / 0 Important / 0 Minor`.
- The first StructureOnly invocation reached its external 604-second command
  bound without producing a result and is diagnostic only. The fresh wider-bound
  invocation passed all discovered contracts in `608.2` seconds; protocol-
  governance assertions reported `elapsedMs=606124`.
