# 2026-07-30 - [FEAT-0065](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md) [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) typed-handoff design

> Historical packet. For current ContractSlice A authority and the
> ParseCanonical-only A / first-activation-in-C correction, follow the
> [2026-07-31 topology-correction handoff](2026-07-31-feat-0065-subf-0143-contractslice-a-topology-correction.md).

## Authority and exact predecessor

- Current scope is the
  [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)/[TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584).
- It authorizes Gate 1/2 architecture design and expected-red planning only.
  C# source/test implementation, Gate 3, project/package/lock/solution,
  workflow, scenario-owner,
  [TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
  WIP extraction, consumer, release,
  publication, authority-transfer, and PowerShell-retirement mutation remain
  unauthorized.
- The accepted predecessor is
  [SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153),
  the
  [evidence-acquisition design](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0153-evidence-contract-design.md),
  merged through [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) at
  exact main
  [`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f),
  with bounded [closure evidence](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520).

## Canonical design

Follow the exact
[typed-evaluation-kernel design](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md)
and [TEST-0210 plan](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210).

Key decisions:

- [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  adds zero Domain exports. Abstractions owns declarations,
  provider-neutral capabilities, evaluator inputs/intents, and proof candidates;
  Conformance owns admission, sealed contexts/references, caches, applicability
  closure plus staged zero-to-N evaluation plans, kernel-minted
  findings/evaluations, and aggregation; Policy owns the compiled
  implementations.
- RULE-0001..0005 is a qualification-only catalog slice. The real Policy
  assembly exposes no complete-policy pack, named authoritative profile, or
  `ConformanceVerdict` authority.
- Binding is acyclic: compile logical artifacts, finalize a separate canonical
  manifest over their digests, then bind manifest and artifacts in the release
  envelope. No self-digest exists.
- [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  owns route selection/I/O and constructs one issued instruction's
  structural observed result. It calls that plan's internal Conformance
  qualification session rather than invoking Policy directly. Conformance
  resolves the manifest codec, invokes it once per exact binding/cache miss,
  owns qualification/decode single-flight and retention, and returns qualified
  model handles or declared rejection. Application copies successful handles
  into its proof candidate; admission validates them without rerunning the
  codec. Absent is synthesized only from an expected slot plus verified
  no-input/no-attempt proof; denial/failure never becomes Absent.
- Repository and provider bodies feed the same provider-neutral models and
  evaluators while retaining distinct qualified locations. Provider ObjectType,
  adapter keys, source-contract keys, permissions, and pagination do not enter
  common rule semantics.
- The mandatory state sequence is `PlanApplicability -> CloseApplicability ->
  PlanEvaluation -> zero-to-N AdvanceEvaluation -> EvaluationClosure ->
  Evaluate`. Only proven true activates evaluation-only evidence; false yields
  referenced NotApplicable; unresolved yields NotEvaluated. Evaluation plans
  are non-empty, predecessor/session-stamped, and single-use. Evaluate is
  proof-free and performs no acquisition, codec, parser, index, or projection.
- Evaluators return only code/reference intents. The kernel alone supplies
  RuleId/revision, severity, remediation, qualified references, findings,
  failures, status, ordering, and aggregate flags/verdict.
- Qualification/decode and context-index caches have exact release,
  instruction/demand, schema, binding bytes/length, component/artifact/budget,
  structural context/root, and producer identity; deterministic single-flight/
  eviction; exact collision checks; one session budget; and no timeout/
  cancellation memoization. Every producer returns exact non-negative byte,
  maximum-depth, node, and complexity usage checked against its declaration and
  copied into the instruction-bound receipt.
- Codec, parser, index, demand-projector, selector, and evaluator production is
  one closed acyclic graph with six exact internal registration lists,
  component/type-token bijection, resource budgets, failure codes, and
  activation coverage. The Policy registration/type-contract partition has
  exactly 27 rows and the full production component union has exactly 35.
  Catalog activation binds either genesis or an exact predecessor snapshot and
  proves the complete transition union.
- The three schema-1 payloads have exact protocol-owned persistent binary
  wires: one repository-tree snapshot, one governed-text body per binding, and
  one owner-sharded repository-target-resolution result set per instruction.
  The last wire has CommitObject, TagRoot, and CapturedSnapshotPath selectors
  plus a canonical deduplicated content table. They use
  strict UTF-8, big-endian framed fields, embedded scope/location equality, and
  no provider DTO/private-cache/report format. Target payload rows must biject
  with the issued DemandDigest and global ItemIds.
- CapturedSnapshotPath projection additionally retains the exact verified
  capture-manifest identity/path/expected-content tuple beside the private
  source-authority handle. The target index uses that tuple to distinguish
  Exact from WrongObject. Every resolution/object/anchor/line proof has an exact
  canonical node-identity frame, and external-owner evidence retains Snapshot
  custody rather than acquiring a false subject-repository location.
- Repository-target demand is projected only after the one per-plan
  `IGovernedReferenceIndex` is ready. Repository/provider input-slot aliases
  canonicalize to that single capability; Conformance retains the exact global
  ItemId-to-source-and-authority map and emits one instruction per owning repository.
  The instruction target remains the governed subject scope, while an external
  owner is object custody resolved to a route only by
  [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
  Empty demand
  emits no instruction, external call, payload, or target codec; the registered
  target index still runs once over zero target/target-Markdown models plus the
  qualified governed-reference capability and produces the empty index.
- Semantic resource ledgers select input payload rows separately from local
  producer rows, so payload bytes are not counted twice. The target-Markdown
  parser's byte/complexity boundary covers a 33,554,432-byte parent; declared
  parser failure creates no paired set model or target-index invocation. The
  plan-global target ceilings close through `projected-resource-failed`, which
  preserves valid shard attempts but emits no aggregate proof or partial
  parser/index product.
- Markdig 1.3.2 exact bytes, fresh pipeline order/options, iterative AST/source-
  span walk, protocol GFM heading IDs, renderer-active link/anchor truth table,
  and historical target-Markdown pairing are manifest-bound semantic authority.
- The staged public inventory is cumulative and exact: slice A has 48 exports,
  B has 72, C has 95, and D has 96, split finally as 72 Abstractions, 23
  Conformance, and one Policy export. A test-only friend authority may activate
  a synthetic complete fixture, but can never activate production or confer
  release/consumer authority.
- Slice B owns only codec mirror/writer/qualifier/admission, codec-local ledger,
  decode/model cache, and ContextProof/Root/codec-derived references. Slice C
  owns the Tests-only synthetic complete six-family graph, parsers/indexes/
  projector/selectors/evaluators, provider-neutral capabilities, index cache,
  and staged kernel. Slice D alone consumes and directly qualifies the real
  Policy export and repeats B/C vectors by freshly constructing from immutable
  fixture definitions/data, without consuming their runtime/test results.
- RULE-0001..0005 exact normative selectors, fragment digests, framed rule
  digests, finding/failure codes, capability requirements, and RULE-0003/0004/
  0005 specialized co-report behavior are fixed in the design.

## [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) and remaining gates

- [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  stays one canonical scenario with four internal traits: A catalog,
  B codec admission, C synthetic complete kernel, and D real first-rule
  qualification.
- Its exact expected-red matrix covers the `48/72/95/96` inventories, six
  registration lists, `27`/`35` component partitions, schema wire golden and
  malformed cases, plan-bound qualification/cache ownership, four-counter
  usage, zero-to-N staged transitions, demand/result/source-and-authority
  correlation, owner sharding/external owners, and the zero-demand target-index
  path.
- Each internal slice later receives its own expected red, review, bounded
  implementation, focused green, and fresh-diff review. No new stable test ID
  is allocated here.
- A valid red is transient/unpublished and follows byte-identical locked
  restore. `SurfaceRed` is compile-only and must produce exactly the reviewed
  single `CS0246` file/span/token/FQN tuple, with no discovery claim. Once that
  slice's structural surface is green, `BehaviorRed` must select, discover, and
  execute focused tests and fail only with the reviewed test-name/marker
  inventory. Infrastructure, restore, lock, predecessor, analyzer, environment,
  discovery, or unexpected diagnostics are invalid red.
- The first behavior-red predecessor for each slice is deterministic: only the
  design's exact warning-free `null!` activation/export sentinel may satisfy the
  compile-green structural checkpoint. D's first red proves only the real
  export graph. RULE-0001 invocation waits for the real D writer/codec/parser/
  index/projector/kernel vectors to be green and then builds a fresh
  Conformance-registered input in that D session from immutable fixture data;
  it is not the second red and consumes no C runtime/test result.
- After all focused/combined green only, one atomic change may activate
  [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  ownership, both workflow filters, and
  [TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146).
  Each existing job
  keeps one locked-restore and one solution test invocation; a deliberate new
  Conformance.Tests testhost must fit the unchanged 35-minute Windows timeout
  with exact per-project count reconciliation.
- Remaining gates are bounded red-team closure, maintainer acceptance, accepted
  design merge, bounded exact-main validation, and a separate implementation
  directive. Do not infer any of them from design publication or “continue.”

## Recurrence and WIP

- Active same-contract recurrence match: explicit `None`.
- The accepted
  [WIP extraction ledger](../../../docs/architecture/protocol-governance-and-execution/wip-extraction-ledger.md)
  remains canonical. RULE-0001/0002 and parse-once ideas are semantic seeds
  only; hard-coded catalog, repository-only context, caller-minted findings,
  report/CLI/exit/authority state, old project/lock/workflow, and passing WIP
  state are not carried forward.
