# SUBF-0143 Micro-Delivery Control Plan

| Field | Value |
| --- | --- |
| Classification | Delivery control for [SUBF-0143](README.md#subf-0143); operational labels below are not new protocol IDs |
| Status | Prepared for maintainer review; no later ContractSlice A increment is active |
| Parent scenario | [TEST-0210](test-cases.md#test-0210), always `ContractSlice=A` until A closes |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Canonical design | [Typed evaluation kernel design](subf-0143-typed-evaluation-kernel-design.md) |
| Accepted A origin | Exact main [`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd) |
| Next-packet predecessor | `Pending`: the reviewed local `13/13` tree is not content-addressed and is not exact main |
| Git authority | None granted by this plan; stage, commit, and push each require an explicit maintainer directive |

## Purpose

This plan changes delivery granularity, not architecture. A future Codex turn
must receive one bounded packet rather than an instruction such as “continue
SUBF-0143”. The standing ContractSlice A directive remains the authority
ceiling. It does not activate any item below by itself and grants no B/C/D,
workflow, publication, or release authority.

The first limited `ParseCanonical` and canonical-string increments are green,
and cumulative A last passed `13/13`. Those files are not yet an exact committed
green baseline because the new source and test trees remain untracked. No new
C# mutation may begin until the baseline checkpoint below is complete.

## Spark startup capsule

Every activated micro task targets a self-contained brief of at most 120 lines
and approximately 4,000 tokens. It names one label/state, accepted A origin,
exact current predecessor, applicable recurrence entries, design anchors,
allowlist, commands, oracle, held scope, and stop conditions. Inherited chat is
not evidence. A small-context agent does not reread the 6,800-line design or an
unbounded historical handoff by default; it may open additional bounded exact
ranges and must never infer omitted semantics.

The aggregate startup ingress targets 500 lines/about 16,000 tokens and stops
at 750 lines/about 24,000 tokens: brief at most 120/4,000; all governance,
memory, decision, feature, test-matrix, design, and handoff excerpts together at
most 180/6,000; exact source/test/call-site ranges together at most 450/14,000.
If a mandatory read or semantic closure exceeds the hard budget, split the
micro task or keep it with the high-context D/RT coordinator; never truncate a
required contract or delegate it to Spark with missing evidence. These budgets
are context-control targets, never completeness waivers.

The brief requires only these targeted reads before work:

1. `AGENTS.md`; only the brief-named `PROTOCOL.md` Gate 0-6, review, and Git
   anchors/ranges.
2. Only the brief-named `.ai/memory/README.md` ranges and
   [active recurrence knowledge](../../../.ai/memory/project.md#active-recurrence-knowledge),
   after verifying each recurrence is still `Active` and not superseded; the
   embedded packet-row/invariant extract from this plan; and at most 80 lines of
   the current handoff. Do not open this whole plan or older handoffs.
3. Only the exact brief-named anchors/ranges from DEC-0035, retained DEC-0032
   and DEC-0030, then the exact architecture authority/hold rows.
4. The FEAT-0065 DoR/DoD and TEST-0210 matrix plus only the exact canonical
   design subsection and requirement rows named by the packet.
5. Current branch, HEAD, status, locks, packet allowlist, and the exact source,
   test, and call-site files affected by the packet.

The brief always carries these active recurrence facts: do not repeat an
unchanged restricted-sandbox Git failure; treat displayed full-file output as
lossy and verify exact ranges after patch errors; use quoted PowerShell
patterns/`rg --glob` and never the reserved `$Error`; an untracked governance
graph cannot prove its own exact commit, so checkpoint it before successor
claims.

The brief requires a concise progress update after preflight and every
D/RT/LR/P/R/G/V transition, before a long-running command or outbound wait, and at
least once every 60 seconds while work continues.

Stop and report `Blocked` on ambiguous authority or packet scope, unknown
writer overlap, an invalid expected-red cause, unexpected lock/project/public-
API delta, failed green/build/format/diff check, an unresolved in-scope
Blocking/Important/Minor or undispositioned Gate 5 observation, scope expansion,
a permission missing from the requested boundary, a repeated unchanged failure,
weekly quota exhaustion, or any user stop instruction. If Git authority is not
needed by the requested boundary, finish as `ReviewedLocalGreen`; do not call it
DoD, Waiting, hosted, or published. Do not infer a next contract, marker, count,
or permission.

## Micro-mode invariants

- One active closed semantic increment, one exact evidence filter, and one
  failure cause. Mutually dependent declarations stay in the same semantic
  packet even when its implementation is split into smaller internal tasks.
- Semantic behavior/regression packets freeze one retained test FQN. Audit and
  convergence packets add no `[Fact]` and instead freeze an exact existing
  FQN/filter set.
- One semantic packet adds at most one retained `[Fact]`; it reuses
  `TEST-0210` and creates no new `TEST-NNNN`.
- Operational labels in this file are routing labels only. A transient evidence
  marker is allocated monotonically and frozen only when its exact packet is
  reviewed and activated.
- Target code plus test change is at most 450 lines. At 700 changed lines the D
  packet must be redrawn; semantic closure may use several smaller internal
  implementation tasks but never an invalid accepted intermediate state.
- A packet may touch at most five production, three test, and four current
  delivery-record files. D/RT may approve a different finite bounded allowlist
  or cap with a dependency rationale; the 700-line redraw rule remains hard and
  semantic closure is never split into an invalid accepted intermediate state.
  Cohort synchronization is separate from the semantic record cap.
- No placeholder public type or member is introduced. A public-surface change
  must close exact inventory, behavior, and negative leakage in the same packet.
- The main oracle is the reviewed public/friend contract boundary, normally
  `FinalizedPolicyManifest.ParseCanonical`. Private helper shape and exception
  text are not behavioral oracles unless the packet explicitly freezes an
  internal ownership/resource invariant, as the accepted canonical codec did.
- Unsupported later valid shapes continue to fail closed. Invalid documents
  are never accepted temporarily.
- `TEST-0210` remains `Planned` through every A package. A checkpoint may be
  described as cumulative A green, never as full `TEST-0210` green.
- `MeAndAI.Protocol.v3.ncrunchsolution.user`, repository-local `.dotnet-cli`,
  TRX/temp output, `bin`, and `obj` are never staged as delivery content.

## Packet state machine

```text
Candidate
  -> Frozen design packet
  -> Red-team accepted
  -> Maintainer activated
  -> Locked restore and lock bytes verified
  -> Exact red accepted, when real behavior is absent
  -> Smallest bounded green
  -> Fresh-diff review accepted
  -> Marker-free reviewed local green
  -> Git-authorized exact green checkpoint
```

Only one packet may be in a mutating state. Read-only design, sibling inventory,
fixture design/calculation, and red-team for the next packet may be pipelined
while a current test or outbound review is pending. Preparation for a successor
must not write source, tests, records, generated files, caches, or fixtures.
Two agents must not concurrently edit the shared reader, writer, fixture, plan,
or handoff files.

## One semantic packet as seven small tasks

1. **D — Freeze design:** exact requirement rows, candidate marker/TRX name,
   FQN, positive/negative/boundary matrix, natural absent predicate, allowlist,
   commands, estimated line budget, count, and held scope. No source mutation.
2. **RT — Red-team:** dependency, same-contract sibling, false-positive,
   expected-red, package-size, and authority review. Mutation stays held until
   every in-scope finding is resolved and the verdict is
   `0 Blocking / 0 Important / 0 Minor`; record the separate Protocol Gate 5
   disposition of every observation, including explicit zero-finding evidence.
   The candidate marker freezes only after RT and activation.
3. **LR — Locked restore:** exactly one locked restore, with lock-byte
   fingerprints verified before and after. Every later test/build uses
   `--no-restore`; LR still runs when P is `NotApplicable`.
4. **P — Prepare source:** when needed, one behavior-preserving seam and proof
   that the previous exact FQN and cumulative A remain green. Otherwise record
   `NotApplicable` and run those `--no-restore` checks against unchanged source.
5. **R — Observe exact red:** one filtered `--no-restore` invocation using the
   exact contract below; never restore again. A generic
   `catch (FormatException) => Assert.Fail(marker)` is invalid.
6. **G — Implement green:** smallest C# delta, original-oracle checkpoint when
   applicable, marker/legacy branch removal, final exact FQN, and cumulative A.
7. **V — Verify and finalize:** run marker-free green tests, unchanged-lock
   checks, zero-warning/error six-project Release build, and standard format,
   all `--no-restore`; synchronize every packet record/memory entry; rerun final
   `git diff --check`; then perform final fresh-diff production/test/docs/memory
   review. Any correction needs its own authority, returns to the applicable
   step, and reruns affected evidence plus V. No edit follows final review; the
   result is `ReviewedLocalGreen`. Stage/commit/push remain separately
   authorized Git operations.

If existing production behavior already satisfies a regression packet, R is
`NotApplicable` and G is `TestOnlyGreen`: do not manufacture a red, add the
direct retained test with no production delta, review the source, and finalize
the already-green contract. Audit/convergence packets may mark both R and G
`NotApplicable` and add no `[Fact]`. If a regression test exposes a defect,
stop and create a separately frozen semantic packet.

D may bind only requirements already present in the canonical design. If exact
semantics or ownership are absent, ambiguous, or contradictory, stop and route
a separate architecture correction through review and maintainer acceptance in
`subf-0143-typed-evaluation-kernel-design.md` before packet activation. That
design may be the fourth packet record when needed; an operational label in
this plan never becomes architecture authority.

### Exact BehaviorRed acceptance contract

The activated brief freezes `TEST-0210-A-BEHAVIOR-RED-NNNN` as both marker and
TRX stem, the exact full FQN/filter, red source hash, baseline commit/tree,
invocation, and every name/value in the 16-counter inventory. The external
fresh directory basename is exactly
`meandai-test-0210-a-<32-lower-hex-guid>`; that path did not exist before
creation and is empty immediately before the single invocation. The command
exits nonzero and writes exactly one TRX at the frozen path, with no stale,
extra, or outside TRX. Discovery and retry are forbidden.

There is one logger and one selected/executed/failed result. Its
`UnitTestResult@testId` maps through the sole `UnitTest/TestMethod` to the exact
FQN, and `ResultSummary/@outcome` is `Failed`. The sole failed result has exactly
one `Output/ErrorInfo/Message` whose normalized text equals the marker byte-for-
byte and no sibling `ErrorInfo` content. The TRX contains the marker nowhere else
except at most one byte-identical `StdOut` or `StdErr` adapter echo.

`ResultSummary/RunInfos` is absent or contains exactly one marker-free
same-FQN `[FAIL]` `RunInfo outcome="Error"` with only `computerName`, `outcome`,
and `timestamp` attributes, exactly one `Text` child, and no other content. Its
raw text matches
`^\[xUnit\.net [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{2}\][ ]+<FQN>[ ]\[FAIL\]$`.
The activated capsule substitutes and regex-escapes the frozen full FQN. The
RunInfo maps to the same Failed result and summary. All 16 counters are exact,
including `total=1`, `executed=1`, `failed=1`, and `error=0`; no other result,
diagnostic, or attachment is allowed.

Reviewed red source contains exactly one direct `Assert.Fail(marker)`, reachable
only from the frozen absent/legacy predicate; the locked xUnit package proves
its exception type. Any clause mismatch invalidates red and forbids G.

NU/MSB/compiler/analyzer/project/reference/lock/predecessor/environment
failure, an extra result/diagnostic/attachment, unexpected exception relabel,
console-only inference, or any mismatch above is an invalid red. An invalid red
is never implemented green; return to D/RT or report `Blocked`.

## Baseline checkpoint before the next increment

| Label | Bounded task | Exit condition |
| --- | --- | --- |
| `BASE-SCOPE` | Record branch/HEAD, tracked and untracked allowlist, excluded NCrunch/temp files, prior red/green evidence, and content/lock hashes. No mutation. | Exact scope manifest; no unknown writer overlap. |
| `BASE-VERIFY` | Run exact cumulative A, locked restore/hash check, Release build, standard format, marker/sentinel search, and `git diff --check`. | Existing `13/13` state is freshly reproducible or a specific blocker is recorded. |
| `BASE-RECORDS` | After explicit record-edit authority, synchronize this plan, the current bounded handoff, and exact verification evidence before final review. | Complete candidate tree is stable; no later content edit is permitted without returning here. |
| `BASE-REVIEW` | After `BASE-RECORDS`, rerun `git diff --check`, then conduct parallel read-only reviews of the complete production/test/docs/memory tree; report every finding and disposition every Gate 5 observation without editing. A finding stops and routes to an explicitly authorized correction, followed by `BASE-VERIFY` as applicable, `BASE-RECORDS`, and a fresh `BASE-REVIEW`. | Final diff check clean, zero in-scope findings, verdict `0/0/0`, every observation dispositioned, and held scopes unchanged. |
| `BASE-STAGE` | After an explicit stage directive, stage only the reviewed allowlist; make no file edit; review the staged diff and tree identity. | Staged tree byte-equals the reviewed tree; NCrunch, temp output, and unrelated work are absent. |
| `BASE-CHECKPOINT` | Commit only after an explicit commit directive; push only after a separately explicit push directive. Do not claim hosted or DoD evidence. | Local exact commit is the immutable predecessor; no push means no hosted/Gate-7/DoD claim. |

`[skip ci]` is not inherited posture. It may be used only as a separately
explicit maintainer exception for an exact push; it cannot satisfy DoD, Gate 7,
or hosted evidence. Hosted validation remains a separately activated gate.

### Exact Git checkpoint contract

Any active Git directive freezes the repository, branch/ref, and reviewed tree
ID. A push directive additionally freezes the remote, expected remote old head,
normal non-force route, and explicit `[skip ci]` choice. `BASE-STAGE` records the
staged tree ID. After commit, record the commit SHA and prove `HEAD^{tree}`
equals that staged/reviewed tree. Immediately before push, recheck the expected
remote head; any drift is `Blocked`. After push, record the exact remote ref and
SHA. A local commit without push remains an immutable local predecessor, not
hosted evidence.

## Ordered remaining ContractSlice A queue

The FQNs below are design candidates. Each becomes exact only in its D/RT
packet. If a preceding regression reveals a defect or a packet exceeds the hard
cap, later evidence ordinals and cumulative counts move; they are not predicted
here.

| Label | Smallest closed contract and mandatory owner | Candidate test suffix after `MeAndAI.Protocol.Conformance.Tests.` |
| --- | --- | --- |
| `A-GRAMMAR-STRUCT-01` | Empty-input, UTF-8/BOM, malformed-JSON, and missing/extra final-LF boundaries; exact root and slice field order; `authorityKind`/variant coherence; unknown spelling, duplicate, null, comment, whitespace, and trailing-content rejection; slice-positive plus both/neither `slice`/`completeCatalog` negatives, but no premature complete-positive claim | `ContractSliceACanonicalJsonGrammarTests.Enforces_exact_document_and_slice_structural_grammar` |
| `A-GRAMMAR-NUMBER-01` | Canonical integer lexical form and range | `ContractSliceACanonicalNumberTests.Enforces_exact_integer_grammar_and_range` |
| `A-GRAPH-01` | A closed fixture with one activation-proof-rooted component plus four exact role-exempt runtime anchors, one local binding per component, every artifact used by a mapping, and activation-proof root closure; it does not yet claim the production six-artifact set | `ContractSliceAArtifactComponentGraphTests.Enforces_exact_binding_runtime_anchor_and_reachability_graph` |
| `A-RULE-01` | Minimal non-empty rule; lowercase 40-hex `sourceCommit`; at least two ordered normative fragments; fragment framing, provenance, and rule-digest integrity | `ContractSliceARuleDeclarationTests.Enforces_canonical_multi_fragment_rule_provenance` |
| `A-SCHEMA-SLOT-01` | Payload schema codec/model/budget/failure closure together with mutually reachable evidence-slot requirement/material-role/surface grammar and an exact zero-capability positive closure | `ContractSliceASchemaSlotManifestTests.Enforces_exact_schema_and_zero_capability_evidence_slot_closure` |
| `A-PARSER-INDEX-01` | Closed parser-to-index-to-slot-capability vertical that first resolves nonempty produced capabilities, including inputs, output model/capability, invocation scope, failure codes, and session-cache budget positivity/order/boundaries | `ContractSliceAParserIndexManifestTests.Enforces_exact_parser_index_and_slot_capability_closure` |
| `A-FINDING-01` | Finding declaration and primary/related reference roles | `ContractSliceAFindingManifestTests.Enforces_finding_declarations_with_exact_reference_roles` |
| `A-SELECTOR-01` | Selector-to-slot/schema/resolver/finding closure | `ContractSliceASelectorManifestTests.Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure` |
| `A-ADMISSION-01` | Admission-proof kind/component/artifact/surface/material-role declarations | `ContractSliceAAdmissionProofManifestTests.Enforces_admission_proof_declarations_with_exact_kind_component_and_artifact_closure` |
| `A-PROJECTOR-DAG-01` | Projector slot/schema/component bindings plus the mutually required acyclic, reachable, single-owner global producer graph | `ContractSliceAProjectorDagManifestTests.Enforces_exact_projector_bindings_and_global_producer_graph` |
| `A-CONVERGE-01` | Test-only production six-artifact-set/bijection; exact five-rule/normative inventory; exact three schema, two parser, four index, and one projector declarations/values, four slots, selectors/findings, proof contracts, caches/budgets/failure codes, and ordinal/reference relationships; and the disjoint ordinal union of `27` Policy + `4` runtime-anchor + `1` activation-proof + `3` admission rows into the exact `35` component snapshot | `ContractSliceAFullManifestGraphTests.Full_declaration_graph_equals_the_exact_six_artifact_27_35_snapshot` |
| `A-COMPLETE-PROFILE-01` | Complete-positive branch and final exact-one union closure; genesis complete catalog, current `CompleteInventoryDigest` framing/equality, one minimal baseline/named profile with compatible-rule closure, and one mandatory Added transition per current rule | `ContractSliceACompleteCatalogProfileTests.Enforces_exact_genesis_catalog_inventory_digest_profile_and_added_transitions` |
| `A-PREDECESSOR-01` | Existing predecessor `catalogVersion` strictly lower than current, predecessor `manifestDigest`, predecessor `completeInventoryDigest`, and current derived inventory digest as separate exact fields | `ContractSliceAPredecessorManifestTests.Enforces_existing_predecessor_version_and_exact_digests` |
| `A-TRANSITION-01` | Expand and retest exact Unchanged/Added/Revised/Retired shapes from the already-valid genesis Added baseline | `ContractSliceATransitionManifestTests.Enforces_exact_unchanged_added_revised_and_retired_transition_shapes` |
| `A-LIFECYCLE-01` | Rule lifecycle against transitions and active profiles | `ContractSliceALifecycleManifestTests.Enforces_rule_lifecycle_against_transitions_and_active_profiles` |
| `A-RESOURCE-01` | Only after full collection grammar: input-byte and reachable-depth ceilings plus token-ceiling equality/one-over through a collection-heavy fixture; no independent collection/declaration-count ceiling | FQN freezes in D only after the reachable-depth contract is resolved |
| `A-CONVERGE-02` | Full A coverage, API/friend/hold audit, and completion recommendation | No new behavior or forced red; cumulative evidence only |

### Packet evidence ledger

Each packet is discoverable here without loading a handoff. D records the frozen
ordinal/FQN; V records the final cumulative count, review verdict, and clickable
current handoff. `None` is exact while the packet remains a candidate.

| Label | State | Frozen ordinal/FQN | Final cumulative | Review | Current handoff |
| --- | --- | --- | --- | --- | --- |
| `A-GRAMMAR-STRUCT-01` | Candidate | None | None | N/A | None |
| `A-GRAMMAR-NUMBER-01` | Candidate | None | None | N/A | None |
| `A-GRAPH-01` | Candidate | None | None | N/A | None |
| `A-RULE-01` | Candidate | None | None | N/A | None |
| `A-SCHEMA-SLOT-01` | Candidate | None | None | N/A | None |
| `A-PARSER-INDEX-01` | Candidate | None | None | N/A | None |
| `A-FINDING-01` | Candidate | None | None | N/A | None |
| `A-SELECTOR-01` | Candidate | None | None | N/A | None |
| `A-ADMISSION-01` | Candidate | None | None | N/A | None |
| `A-PROJECTOR-DAG-01` | Candidate | None | None | N/A | None |
| `A-CONVERGE-01` | Candidate | None | None | N/A | None |
| `A-COMPLETE-PROFILE-01` | Candidate | None | None | N/A | None |
| `A-PREDECESSOR-01` | Candidate | None | None | N/A | None |
| `A-TRANSITION-01` | Candidate | None | None | N/A | None |
| `A-LIFECYCLE-01` | Candidate | None | None | N/A | None |
| `A-RESOURCE-01` | Candidate | None | None | N/A | None |
| `A-CONVERGE-02` | Candidate | None | None | N/A | None |

Every family packet owns positive byte-identical reader/writer round-trip,
exact manifest digest and typed projection, canonical collection order and
duplicate negatives, every newly reachable nested property's spelling/order,
unknown/null/cardinality/optional/variant negatives, and document-caused
factory `ArgumentException` mapping to public `FormatException`. Loaded
artifact/predecessor conflicts stay outside the A parser. Rule `sourceCommit`,
blob existence, and content trust also remain external qualification evidence;
A owns only their grammar and digest closure and performs no repository lookup.
The D packet names any family-specific exception to this oracle.

`A-RULE-01` must prove in D/RT that a rule with both slot lists empty is valid
in the then-current schema; otherwise it moves behind and joins
`A-SCHEMA-SLOT-01`. `A-SCHEMA-SLOT-01` must likewise prove and retain a valid
zero-capability positive slot until `A-PARSER-INDEX-01` introduces its producer;
otherwise those packets reorder or join before activation. `A-PREDECESSOR-01`, `A-TRANSITION-01`, and
`A-LIFECYCLE-01` each freeze the exact temporarily accepted subset and reject
all successor shapes; if no such fail-closed boundary exists, the dependent
packets combine before activation. No line cap overrides this semantic rule.

`A-GRAMMAR-STRUCT-01` and `A-GRAMMAR-NUMBER-01` are first reviewed as likely
already-green regressions; they do not force expected-red. `A-RESOURCE-01`
waits until the full grammar can produce the equality fixtures. It must
reconcile the declared depth-64 ceiling with actual reachable nesting and must
not invent a structurally invalid depth-64 success fixture. `A-CONVERGE-01`
owns no production fix: a missing invariant returns to its owner or receives a
new frozen packet. Neither convergence checkpoint manufactures red evidence.

The queue has 17 routing packages. Each semantic package expands into the seven
D/RT/LR/P/R/G/V micro tasks above, named `<packet>-D` through `<packet>-V`;
R is `NotApplicable` and G is `TestOnlyGreen` for an already-green regression;
both are `NotApplicable` for audit packages. No package becomes active merely
because its predecessor finished.

## Cohorts and record synchronization

Use cohorts of at most three semantic packages. Each package updates this
register, the TEST-0210 evidence section, and a packet handoff capped at 80
lines; close it before the next package and link older history rather than
loading or appending it indefinitely. Historical handoffs are never rewritten.

After up to three packages, run a separate code-free `COHORT-SYNC-NN` packet.
It synchronizes feature status, architecture README, successor plan, transition
register, and top-level project memory only when authority/status changed or
the cohort closed. This checkpoint has its own reviewed record allowlist and is
outside the per-semantic-package four-record cap.

## Held future work

ContractSlice B, C, and D remain ordered future cohorts, not active work. B
will be decomposed around codec-mirror activation, the three persistent wire
families, admission variants, decode/model cache, resource ledger, and sealed
roots. C will be decomposed around synthetic activation, registration mismatch,
capability/index/projector families, staged plans, outcomes, references,
intents, and aggregation. D will be decomposed around the real Policy export,
real codec/parser/index/projector registrations, RULE-0001 through RULE-0005,
and repository/provider equivalence. Each receives its own reviewed micro plan
only after its predecessor is green and the maintainer separately authorizes
that boundary.

Workflow/scenario-owner/TEST-0146 activation, combined/root/hosted validation,
WIP extraction, consumer/provider mutation, release/publication, authority
transfer, and PowerShell retirement remain hard-held throughout this plan.
