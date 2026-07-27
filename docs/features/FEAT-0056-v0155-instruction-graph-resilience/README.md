# [FEAT-0056](README.md) - Instruction-Graph Preflight Resilience

| Field | Value |
| --- | --- |
| Classification | Instruction-graph preflight resilience and reviewed schema-2 compatibility / [BUG-0037](https://github.com/hasanmanzak/meAndAI/issues/140), [BUG-0038](https://github.com/hasanmanzak/meAndAI/issues/141), [BUG-0039](https://github.com/hasanmanzak/meAndAI/issues/142), [BUG-0040](https://github.com/hasanmanzak/meAndAI/issues/143), [BUG-0041](https://github.com/hasanmanzak/meAndAI/issues/144), [BUG-0042](https://github.com/hasanmanzak/meAndAI/issues/145), [BUG-0043](https://github.com/hasanmanzak/meAndAI/issues/146), and [BUG-0044](https://github.com/hasanmanzak/meAndAI/issues/147) |
| Status | Complete |
| Target version | 0.15.5 |
| Bugs | [BUG-0037 / issue #140](https://github.com/hasanmanzak/meAndAI/issues/140); [BUG-0038 / issue #141](https://github.com/hasanmanzak/meAndAI/issues/141); [BUG-0039 / issue #142](https://github.com/hasanmanzak/meAndAI/issues/142); [BUG-0040 / issue #143](https://github.com/hasanmanzak/meAndAI/issues/143); [BUG-0041 / issue #144](https://github.com/hasanmanzak/meAndAI/issues/144); [BUG-0042 / issue #145](https://github.com/hasanmanzak/meAndAI/issues/145); [BUG-0043 / issue #146](https://github.com/hasanmanzak/meAndAI/issues/146); [BUG-0044 / issue #147](https://github.com/hasanmanzak/meAndAI/issues/147) |
| Pull request | [PR #148](https://github.com/hasanmanzak/meAndAI/pull/148) |
| Decisions | [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md), [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md), [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md) |
| Tests | Existing [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153), and [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161); [feature evidence](test-cases.md) |

## Problem

Read-only adoption preflight against current, exact consumer trees exposed a
sequence of reusable defects in the immutable v0.15.4 instruction-graph
boundary.

First, repository-path code spans inherit URI fragment handling before they
are classified. A whitespace-bearing directive token beginning with `#`
reaches path resolution with an empty target. A conditional fixed-width
filename descriptor such as `docs/features/REC-####.md` is instead truncated
to `docs/features/REC-` and rejected as a missing concrete target.

Second, after such a primary graph-builder failure, the quick-adoption batch
abort path kills and reaps the child but checks pending pipe tasks immediately.
An ordinary task that completes during pipe shutdown is reported as though it
survived the complete abort budget, appending a false cleanup failure to the
real parser diagnostic.

Third, one exact required governance document is 269,236 bytes, 7,092 bytes
above the schema-1 per-blob ceiling. Its complete nine-blob graph consumes only
739,923 of the unchanged 4,194,304 aggregate bytes and remains below every
other declared limit. The published guard is correctly fail closed, but the
  real graph satisfies [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)'s
  capacity-review condition.

Fourth, an ordinary reference to an existing regular `.mqproj` file reaches the
unknown-format guard. The file is UTF-16 LE project metadata, not UTF-8 live
instruction text. Treating every unknown format as protected would hide
authority, while adding this reviewed format without a schema transition would
silently change schema-1 evidence.

The first corrected candidate simulation then exposed two narrower recurrence
boundaries. Closing raw stdin can let the Git wrapper exit between
`GetHasExited` and `Kill`, so the successful natural exit is reported as a kill
cleanup failure. Separately, the required-reading grammar treats a descriptive
phrase such as `load validation` as an imperative merely because bare `load`
appears anywhere on the line, promoting an ordinary protected source path to
live authority.

The next exact traversal reached an authoritative historical evidence line and
treated the test result `24/24` as a required extensionless repository path.
Slash-bearing all-numeric code spans are ambiguous with ratios and dates; an
untracked one is not concrete path evidence, while a matching exact tree entry
must remain addressable.

The following traversal exposed a protected-authority false negative. A line
declaring one protected source as the `single canonical` domain source was
classified as an ordinary reference because bounded qualifier words separated
`canonical` from `source`. The graph consequently reported a migration strategy
as resolved instead of requiring maintainer review.

The schema transition also exposed a release-selection fault. The runtime
imported only its own schema-2 policy even when a compatible graph-aware
v0.15.4 target workflow required schema-1 identity. Dispatching that mixed
identity would fail in the immutable target validator, while legacy workflows
without a source-graph input do not expose a target graph-policy contract.

Final bounded review exposed related edges that the first correction did not
cover. Encoded traversal/backslash and `file:` repeated-hash code spans were
suppressed before safety classification; encoded external schemes, tracked
literal-hash paths containing spaces, and literal-hash paths with URI fragments
were misclassified. Predicate-negated qualified authority such as `does not
remain` and `never serves as` was promoted to live authority, while applying
negation to a whole line could hide positive authority in a separate clause.
Finally, v0.12.6-v0.14.1 targets require their schema-7/8 marker family
throughout transition, and graph-unaware runtime-policy fallback must not accept
arbitrary old or future target tags.

The last independent parser review then exposed four residual order and grammar
faults. A fragment or query suffix containing dot segments could redirect a
tracked literal-hash path to another exact-tree entry. Encoded extensionless
`file:`, drive, and external targets could be discarded by the raw token-shape
prefilter before decoded safety classification. Mixed negative/positive
authority clauses separated by a semicolon, period, or `however` could lose the
positive declaration. Finally, treating every `and` as a clause boundary split
a qualifier conjunction inside a negated canonical-source predicate.

Three follow-up variants exposed the remaining nested-boundary and negation-
grammar gaps. A second literal or percent-decoded delimiter could be reconsidered
as a new path boundary, allowing `../` already inside an opaque suffix to be
normalized into a different exact-tree target. Direct and reverse authority
wording also omitted bounded modal, contraction, `no longer`, and `never`
negation forms, allowing negative canonical-source declarations to become live
authority. A broad 160-character negation mask could also begin at an
extensionless path's ordinary non-authority predicate and cross `when`,
`because`, `although`, `if`, `after`, `before`, or `where`, erasing a later
positive authority designation.

All observed parser, transport, and target-policy faults occur before consumer
or GitHub mutation in the read-only assessment path.

## Outcome

Hash-bearing repository code spans are strictly decoded before raw shape
filtering, external/file/drive classification, repository safety, exact-tree
membership, and placeholder suppression. For a local target containing literal
hash or query delimiters, the longest canonical exact-tree prefix wins before
literal membership is considered. Once that exact identity is established at
the first valid boundary, its suffix is opaque: a second literal or decoded
delimiter cannot reopen the suffix or feed its dot segments into repository-path
normalization. Fragment-only directive spans and untracked fixed-width numeric
placeholder descriptors are non-concrete references; tracked
repeated-hash code spans, inline Markdown links, and reference links, including
angle-delimited targets containing spaces, remain exact concrete paths even with
a trailing fragment or query. Concrete
path-plus-fragment spans keep resolving
to their concrete paths, and real files under known surface roots remain
bounded graph candidates. Concrete links, required paths, external schemes,
escapes, and unsafe targets retain their existing fail-closed behavior.

Batch abort uses one bounded cleanup deadline to terminate and reap the child,
join each distinct pending I/O task, and then dispose the transport. Ordinary
pipe completion no longer masks or decorates the primary graph error; a truly
unjoined or faulted task remains an explicit cleanup failure, and every faulted
task exception is observed before collection. A monotonic-clock integrity fault
is sticky across primary and abort scopes: cleanup performs no later timed wait
and cannot regain a fresh budget after the clock appears to recover.
An exit observed immediately after a failed kill is treated as the expected
race and still reaped; a kill failure while the child remains live is preserved
as cleanup evidence.

Required-reading classification distinguishes anchored imperative and explicit
`must read`, `must load`, and `must consult` forms from descriptive
`load`/`consult` text. Existing
required-reading headings, lists, negation, authority/index declarations, and
instruction-root behavior remain exact.

All-numeric slash code spans are classified against the exact tree: absent
tokens are ratios/date/result evidence and produce no path, while an exact
tracked numeric path retains ordinary significant-path behavior.

Qualified `single canonical ... source/authority` declarations use a bounded
word grammar and retain authority semantics. Predicate-negation masking covers
bounded direct and reverse forms, including modal `not`, contractions,
`no longer`, and `never`, without treating a qualifier conjunction such as
`product and domain` as a clause boundary. Each negative predicate must bind to
the same exact authority-designation complement accepted by the positive
grammar; an ordinary negated predicate cannot mask across a connective. A
separate positive declaration after `but`, a semicolon, a period, `however`, or
another reviewed mixed-line connector keeps the line authoritative. Because
path-to-clause ownership is not inferred, mixed negative/positive lines remain
conservatively fail closed; negative-only and ordinary references remain non-
authoritative.

The quick-adoption runtime retrieves the exact target workflow once before
assessment. A graph-aware workflow selects and probes its exact immutable
release profile; only graph-unaware v0.12.4-v0.12.5 workflows retain the bounded
runtime-policy fallback, and every other graph-unaware tag fails closed.
Target-semantic commands always come from the target
release, while the three linked-path ancillary helpers are composed atomically
from that release when present or from the runtime when absent. Proposal
identities use the probed policy schema, never a tag or blob-limit inference.
Schema-7/8 target markers remain schema 7/8 through proposed, publishing, and
completed transitions; schema-9/10 targets remain schema 9/10. Schema-1
evidence is not converted.

[DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md)
introduces graph schema 2, raises only the inclusive per-blob ceiling to
524,288 bytes, and retains the 4,194,304-byte aggregate ceiling. It adds only
`.mqproj` to terminal protected evidence: ordinary references are recorded but
never read or promoted, required/authority/index uses still fail closed, and
unknown extensions remain unsupported.

## Immutable baseline

- Release: [v0.15.4](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.4).
- Commit: [`1883a23`](https://github.com/hasanmanzak/meAndAI/commit/1883a2315529e7493343c07eebb4c74ed77a62b4).
- Parser failure variants: `#configuration version` and the conditional
  `docs/features/REC-####.md` descriptor.
- Abort failure: a primary graph exception followed by
  `Instruction-graph batch I/O task did not join after abort.`
- Canonical owners: `Get-MeAndAIInstructionGraphReferences`,
  `New-QuickAdoptionInstructionGraphBatchSession`,
  `Resolve-QuickAdoptionInitialPolicyTag`, [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151),
  [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152),
  [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153), and
  [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161).

## Ownership and prior-art review

The behavior is shared meAndAI production logic. Consumer-local workarounds,
fixtures, tests, or copied protocol assets are forbidden. [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
already owns exact committed-tree graph evidence, while [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
and [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md)
keep the regression in existing canonical owners.

The recurrence registry contains related Markdown/path false-positive and
batch-framing entries, but no exact match for URI semantics applied to code
spans or for an abort path that asserts task joining without waiting.
[DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md)
owns the required prospective graph-schema change. No new numbered test
identity is required.

## Scope

- Add project-neutral expected-red parser variants to existing
  [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)
  and [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152).
- Preserve concrete path-plus-fragment behavior while classifying
  fragment-only directives and fixed-width placeholder code spans only after
  strict decoding, external/file classification, exact-tree membership, and
  repository-safety resolution, before final URI normalization; retain tracked
  repeated-hash code-span and Markdown forms with fragments or spaces.
- Prefer the longest canonical exact-tree prefix for a local literal-hash/query
  target and treat the remaining URI suffix as opaque; once the first valid
  boundary establishes exact identity, never let a second literal or decoded
  delimiter feed suffix dot segments back into repository-path normalization.
- Decode before the raw token-shape prefilter so extensionless encoded file,
  drive, and external schemes reach the same fail-closed/external classification
  as their literal forms.
- Treat only explicit fixed-width numeric placeholder descriptors as
  non-concrete; do not introduce glob expansion or semantic inference.
- Add ordinary-completion, truly-unjoined, faulted-task, and primary-error
  variants to existing [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161).
- Join distinct pending tasks within one bounded abort deadline, make clock
  integrity failure sticky, and observe faulted task exceptions.
- Raise only the schema-2 per-blob ceiling to 524,288 bytes, retain the exact
  aggregate limit, and bind policy, both actors, identity, and release checks.
- Add `.mqproj` only to schema-2 terminal protected evidence while preserving
  protected-authority and unknown-format failures.
- Treat only an observed post-kill natural exit as a benign race; retain real
  kill/reap/pipe cleanup failures.
- Narrow bare `load`/`consult` matching to explicit imperative reading forms.
- Treat all-numeric slash code spans as concrete only when their exact resolved
  path exists in the committed tree.
- Recognize only bounded qualified `single canonical ... source/authority`
  declarations, mask bounded direct/reverse modal, contraction, `no longer`, and
  `never` negative predicates without splitting qualifier conjunctions, and
  require every negative predicate to consume the same exact authority-
  designation complement as the positive grammar. Preserve ordinary/table/
  negative-only forms. If another clause on the same line is positive, retain
  conservative authority and fail-closed behavior rather than infer path-to-
  clause ownership, including after `when`, `because`, `although`, `if`,
  `after`, `before`, or `where` following ordinary negated prose.
- Select and validate the exact historical target policy for graph-aware
  workflows, retain the runtime policy only for graph-unaware v0.12.4-v0.12.5
  workflows, compose the target/runtime ancillary helper family atomically,
  preserve the target marker family through every transition, and derive
  proposal schema from a valid empty-graph policy probe.
- Rerun exact consumer-tree preflight without writing any consumer repository.
- Publish the corrections as immutable `v0.15.5`.

## Non-goals

- No named-consumer knowledge in production code or regression fixtures.
- No general glob language, wildcard expansion, natural-language condition
  inference, alternate Git transport, schema-1 reinterpretation, or extension
  classification beyond the reviewed `.mqproj` addition.
- No strategy-selection, migration-plan, repository mutation, workflow-byte,
  issue-template, or managed-merge behavior change.
- No process-count optimization, new job, runner, cache, daemon, or unbounded
  wait.
- No consumer repository, branch, issue, pull request, or file mutation.

## Decomposition and review gate

| ID | Slice | Tracking | Test | Review state | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0107` <a name="subf-0107"></a> | Repository code-span and placeholder classification | [Issue #140](https://github.com/hasanmanzak/meAndAI/issues/140) | Existing [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) / [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) expected red; final PS5.1/7 green in 248.3/143.5 seconds | Decode-before-shape, file/drive/external scheme, longest exact prefix, nested literal/decoded delimiter opacity, literal hash, Markdown, missing, and candidate boundaries verified | Implemented |
| `SUBF-0108` <a name="subf-0108"></a> | Bounded batch-abort task joining and diagnostic preservation | [Issue #141](https://github.com/hasanmanzak/meAndAI/issues/141) | Existing [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) expected red, focused PS5.1/7 green | Deadline, sticky clock fault, distinct-task, exception observation, primary-error, and cleanup boundaries verified | Implemented |
| `SUBF-0109` <a name="subf-0109"></a> | Schema-2 bounded instruction-blob capacity | [Issue #142](https://github.com/hasanmanzak/meAndAI/issues/142) | Existing [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) / [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) 269,236-byte and exact N/N+1 variants | Per-blob, aggregate, unread-trailer, actor, and identity boundaries verified | Implemented |
| `SUBF-0110` <a name="subf-0110"></a> | Schema-2 `.mqproj` terminal protected classification | [Issue #143](https://github.com/hasanmanzak/meAndAI/issues/143) | Existing [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) / [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) terminal/authority/unknown-format variants | No-read, authority, surface, and schema boundaries verified | Implemented |
| `SUBF-0111` <a name="subf-0111"></a> | Imperative-versus-descriptive required-reading grammar | [Issue #144](https://github.com/hasanmanzak/meAndAI/issues/144) | Existing [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) / [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) descriptive/imperative variants | Anchored, heading, list, root, negation, and authority boundaries verified | Implemented |
| `SUBF-0112` <a name="subf-0112"></a> | Exact-tree numeric ratio/path disambiguation | [Issue #145](https://github.com/hasanmanzak/meAndAI/issues/145) | Existing [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) / [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) absent/present numeric-slash variants | Missing, tracked path, relative, and escape boundaries verified | Implemented |
| `SUBF-0113` <a name="subf-0113"></a> | Bounded qualified canonical-source authority grammar | [Issue #146](https://github.com/hasanmanzak/meAndAI/issues/146) | Existing [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) / [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) expected red; final PS5.1/7 green in 248.3/143.5 seconds | Word/character bounds, bounded direct/reverse modal/contraction/no-longer/never negation, exact designation complements, qualifier conjunction, mixed-clause conservative authority, table, and protected-authority boundaries verified | Implemented |
| `SUBF-0114` <a name="subf-0114"></a> | Release-owned graph policy selection and proposal identity | [Issue #147](https://github.com/hasanmanzak/meAndAI/issues/147) | Existing [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) immutable schema-1/schema-2 probe, graph-aware selection, graph-unaware fallback, and proposal-schema variants | Exact profiles, bounded fallback, target/runtime provenance, marker-family transition, reverse cleanup, and no-conversion boundaries verified | Implemented |

## Findings

| ID | Classification | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0310` <a name="find-0310"></a> | Parser correctness / P1 | URI fragment splitting runs on repository code spans before concrete-path classification, producing an empty target or a truncated placeholder target. | `Blocking` / Resolved in candidate by [SUBF-0107](#subf-0107) expected-red and PS5.1/7 [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)/[TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) green under [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140). |
| `FIND-0311` <a name="find-0311"></a> | Runtime cleanup / P1 | Batch abort checks pending pipe tasks without first joining them within its declared abort budget, so normal shutdown can produce false cleanup evidence. | `Blocking` / Resolved in candidate by [SUBF-0108](#subf-0108) expected-red and PS5.1/7 [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) green under [issue #141](https://github.com/hasanmanzak/meAndAI/issues/141). |
| `FIND-0312` <a name="find-0312"></a> | Integration boundary / P2 | The GitHub connector can read public meAndAI state but returned `403 Resource not accessible by integration` for issue creation. | `OptionalImprovement` / authenticated `gh issue create` created only owned [issues #140](https://github.com/hasanmanzak/meAndAI/issues/140), [#141](https://github.com/hasanmanzak/meAndAI/issues/141), [#142](https://github.com/hasanmanzak/meAndAI/issues/142), [#143](https://github.com/hasanmanzak/meAndAI/issues/143), [#144](https://github.com/hasanmanzak/meAndAI/issues/144), [#145](https://github.com/hasanmanzak/meAndAI/issues/145), [#146](https://github.com/hasanmanzak/meAndAI/issues/146), and [#147](https://github.com/hasanmanzak/meAndAI/issues/147); no MAAI or consumer behavior is affected, and review is required only if connector issue-write authority changes. |
| `FIND-0313` <a name="find-0313"></a> | Graph capacity / P1 | A valid nine-blob graph totals 739,923 bytes, but one 269,236-byte required governance document exceeds only the schema-1 per-blob ceiling by 7,092 bytes. | `Blocking` / Resolved in candidate by schema-2 exact N/N+1 evidence in [SUBF-0109](#subf-0109), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #142](https://github.com/hasanmanzak/meAndAI/issues/142). |
| `FIND-0314` <a name="find-0314"></a> | Format compatibility / P1 | An ordinary reference to a regular 57,502-byte UTF-16 LE BOM `.mqproj` file reaches the unknown-format guard because schema 1 omits the reviewed project-metadata extension. | `Blocking` / Resolved in candidate by schema-2 terminal/authority/unknown-format evidence in [SUBF-0110](#subf-0110), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #143](https://github.com/hasanmanzak/meAndAI/issues/143). |
| `FIND-0315` <a name="find-0315"></a> | Runtime cleanup / P1 | After stdin closes, the Git wrapper can exit between the abort path's first status check and kill; the resulting process-exited exception is recorded as cleanup failure even though the child is already gone. | `Blocking` / Resolved in candidate by PS5.1/7 lifecycle evidence in [SUBF-0108](#subf-0108) and [issue #141](https://github.com/hasanmanzak/meAndAI/issues/141). |
| `FIND-0316` <a name="find-0316"></a> | Parser correctness / P1 | The required-reading alternative treats bare `load` or `consult` anywhere on a traversed line as an imperative, so descriptive text such as `load validation` promotes a path to `RequiresRead`. | `Blocking` / Resolved in candidate by anchored and explicit reading grammar evidence in [SUBF-0111](#subf-0111) and [issue #144](https://github.com/hasanmanzak/meAndAI/issues/144). |
| `FIND-0317` <a name="find-0317"></a> | Parser correctness / P1 | A significant line's untracked `24/24` result token satisfies the generic slash-bearing extensionless-path production and is rejected as a missing required target. | `Blocking` / Resolved in candidate by absent and tracked exact-tree variants in [SUBF-0112](#subf-0112) and [issue #145](https://github.com/hasanmanzak/meAndAI/issues/145). |
| `FIND-0318` <a name="find-0318"></a> | Authority completeness / P1 | A protected path declared as the `single canonical` domain source remains an ordinary `References` edge, allowing a false resolved migration assessment. | `Blocking` / Resolved in candidate by the bounded qualified-authority matrix in [SUBF-0113](#subf-0113) and [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0319` <a name="find-0319"></a> | Release compatibility / P1 | A schema-2 runtime targeting graph-aware v0.15.4 imports the runtime policy and would dispatch schema-2 identity to the immutable schema-1 target validator. | `Blocking` / Resolved in candidate by exact target-policy probe and dispatch evidence in [SUBF-0114](#subf-0114), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #147](https://github.com/hasanmanzak/meAndAI/issues/147). |
| `FIND-0320` <a name="find-0320"></a> | Optional extraction debt / P3 | Untracked `*.log`, `MAJOR.MINOR`, and `vMAJOR.MINOR` tokens are extracted as non-required references and discarded before graph edges. | `OptionalImprovement` / no node, edge, digest, surface, or strategy effect; defer any exact-tree membership refinement beyond v0.15.5. |
| `FIND-0321` <a name="find-0321"></a> | Release compatibility / P1 | The target-policy importer accepts broad ranges instead of exact release-bound graph profiles; even immutable v0.15.4 with `MaximumNodes = 511` was accepted, while older reviewed schema-1 releases legitimately retain smaller exact node/edge/path profiles. | `Blocking` / Resolved in candidate by exact historical profiles and mutation rejection in [SUBF-0114](#subf-0114), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #147](https://github.com/hasanmanzak/meAndAI/issues/147). |
| `FIND-0322` <a name="find-0322"></a> | Runtime cleanup / P1 | Clock-integrity failure is not sticky: child-scope state lets abort trust a later recovered clock, and a primary monotonicity failure can likewise regain a full cleanup budget. | `Blocking` / Resolved in candidate by sticky primary/abort clock variants in [SUBF-0108](#subf-0108) and [issue #141](https://github.com/hasanmanzak/meAndAI/issues/141). |
| `FIND-0323` <a name="find-0323"></a> | Parser safety / P1 | Repeated-hash placeholder suppression runs before exact-tree membership and repository-boundary resolution, hiding both a tracked `docs/POLICY-##.md` path and unsafe `../REC-####.md`; the common final URI-fragment split also truncates an exact tracked repeated-hash Markdown link. | `Blocking` / Resolved in candidate by exact tracked, Markdown, untracked, and unsafe variants in [SUBF-0107](#subf-0107) and [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140). |
| `FIND-0324` <a name="find-0324"></a> | Parser correctness / P1 | The anchored grammar still classifies line-leading descriptive text such as `Load validation for ... is complete` as an imperative. | `Blocking` / Resolved in candidate by leading descriptive and explicit imperative variants in [SUBF-0111](#subf-0111) and [issue #144](https://github.com/hasanmanzak/meAndAI/issues/144). |
| `FIND-0325` <a name="find-0325"></a> | Test oracle / P2 | Schema-2 per-blob and aggregate N+1 tests accepted any exception and emitted no payload, so EOF could falsely satisfy the guard if preallocation rejection regressed. | `Blocking` / Resolved in candidate because [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) now requires exact size diagnostics and an unread trailer under [SUBF-0109](#subf-0109) and [issue #142](https://github.com/hasanmanzak/meAndAI/issues/142); no production defect was observed. |
| `FIND-0326` <a name="find-0326"></a> | Test boundary / P2 | Qualified-authority tests did not pin the declared six-word/seven-word, 32/33-character, and Markdown-table gates. | `Blocking` / Resolved in candidate by exact word, character, and table bounds in [SUBF-0113](#subf-0113) under [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0327` <a name="find-0327"></a> | Release compatibility / P1 | Exact graph-aware targets v0.12.6 through v0.14.1 export every target-semantic command but not the later three linked-path helpers, so the current all-or-nothing importer rejects valid schema-1 releases; target-generated schema-1 dispatch was also not exercised end to end. | `Blocking` / Resolved in candidate by target semantics plus atomic ancillary composition and policy-built schema-1 dispatch in [SUBF-0114](#subf-0114), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #147](https://github.com/hasanmanzak/meAndAI/issues/147). |
| `FIND-0328` <a name="find-0328"></a> | Maintainability / P3 | The public launcher fetches the exact workflow a second time after the earlier fetch and invariant, leaving unreachable duplicate transport work. | `Blocking` / Resolved in candidate by removing the duplicate fetch under [SUBF-0114](#subf-0114); no separate issue is needed because behavior was unreachable and owned by the same policy transition. |
| `FIND-0329` <a name="find-0329"></a> | Test oracle / P2 | The live-process cleanup test enabled both kill and dispose failures but accepted either diagnostic, so a lost kill failure could pass. | `Blocking` / Resolved in candidate because [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) requires both exact diagnostics under [SUBF-0108](#subf-0108) and [issue #141](https://github.com/hasanmanzak/meAndAI/issues/141). |
| `FIND-0330` <a name="find-0330"></a> | Runtime cleanup / P3 | Abort classifies a faulted pipe task without observing its `Exception`, permitting an unobserved task exception after collection. | `Blocking` / Resolved in candidate by explicit faulted-task exception observation in [SUBF-0108](#subf-0108) under [issue #141](https://github.com/hasanmanzak/meAndAI/issues/141). |
| `FIND-0331` <a name="find-0331"></a> | Parser safety / P1 | The first repeated-hash correction still suppressed percent-encoded traversal/backslash and relative `file:` targets before safety checks, dropped encoded external-scheme code spans, split literal-hash code/Markdown paths at a trailing fragment, and lost tracked angle-delimited targets containing spaces. | `Blocking` / Resolved in candidate by one decoded, external-aware, repository-safe common token path plus focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)/[TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) variants in [SUBF-0107](#subf-0107) and [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140). |
| `FIND-0332` <a name="find-0332"></a> | Authority correctness / P1 | Qualified-authority matching ignored predicate negation, so negative predicates produced required authority; a line-wide negation gate could then hide valid positive authority in another clause. | `Blocking` / Resolved in candidate by a bounded negative-predicate mask with conservative mixed-line authority and focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) variants in [SUBF-0113](#subf-0113) and [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0333` <a name="find-0333"></a> | Release compatibility / P1 | Runtime transition writers forced schema-9/10 markers onto v0.12.6-v0.14.1 targets whose immutable policy validates schema 7/8, breaking completed-marker revalidation. | `Blocking` / Resolved in candidate by preserving the incoming target marker family through a real v0.14.1 nonempty-surface Proposed-Publishing-Completed roundtrip under [SUBF-0114](#subf-0114), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #147](https://github.com/hasanmanzak/meAndAI/issues/147). |
| `FIND-0334` <a name="find-0334"></a> | Release compatibility / P1 | Graph-unaware workflow fallback accepted every target tag, allowing an unsupported future or too-old release to inherit the current runtime policy without a reviewed compatibility boundary. | `Blocking` / Resolved in candidate by allowing only exact v0.12.4-v0.12.5 graph-unaware targets and rejecting v0.12.3/v1.0.0 in [SUBF-0114](#subf-0114), [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md), and [issue #147](https://github.com/hasanmanzak/meAndAI/issues/147). |
| `FIND-0335` <a name="find-0335"></a> | Parser safety / P1 | A fragment or query suffix such as `#scope/../SECRET.md` was allowed to participate in dot-segment normalization, redirecting a tracked literal-hash policy reference to another exact-tree entry. | `Blocking` / Resolved in candidate by selecting the longest canonical exact-tree prefix first and keeping the remaining suffix opaque in [SUBF-0107](#subf-0107), focused [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140). |
| `FIND-0336` <a name="find-0336"></a> | Parser safety / P1 | The raw token-shape prefilter discarded encoded extensionless `file:`, drive, and external targets before decoding, bypassing required unsafe-scheme failure or external classification. | `Blocking` / Resolved in candidate by strict decoding and scheme classification before shape filtering in [SUBF-0107](#subf-0107), focused [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140). |
| `FIND-0337` <a name="find-0337"></a> | Authority correctness / P1 | Negation masking could consume a later positive authority declaration when mixed clauses were separated by a semicolon, period, or `however`, producing a false non-authoritative result. | `Blocking` / Resolved in candidate by bounded negative-predicate masking plus conservative positive mixed-line authority in [SUBF-0113](#subf-0113), focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), and [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0338` <a name="find-0338"></a> | Authority correctness / P1 | Treating every conjunction as a clause separator split `single canonical product and domain source` inside a negated predicate and exposed a false positive authority tail. | `Blocking` / Resolved in candidate by retaining qualifier conjunctions inside the bounded negation mask in [SUBF-0113](#subf-0113), focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), and [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0339` <a name="find-0339"></a> | Parser safety / P1 | Scanning backward from a second literal or percent-decoded delimiter let a candidate prefix include and re-normalize `../` from an already opaque suffix, redirecting the reference to another exact-tree path. | `Blocking` / Resolved in candidate by locking the exact-tree identity at the first valid boundary and treating every later decoded delimiter as opaque suffix in [SUBF-0107](#subf-0107), focused [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140). |
| `FIND-0340` <a name="find-0340"></a> | Authority correctness / P1 | Direct and reverse authority-negation grammar omitted bounded modal, contraction, `no longer`, and `never` forms, allowing negative canonical-source declarations to become authority. | `Blocking` / Resolved in candidate by the expanded bounded direct/reverse negation grammar in [SUBF-0113](#subf-0113), focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), and [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0341` <a name="find-0341"></a> | Authority correctness / P1 | A broad 160-character mask could start at an extensionless path's ordinary negated predicate and cross `when`, `because`, `although`, `if`, `after`, `before`, or `where` into a later positive authority declaration. | `Blocking` / Resolved in candidate by binding negation to the same exact authority-designation complement as the positive grammar in [SUBF-0113](#subf-0113), focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), and [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146). |
| `FIND-0342` <a name="find-0342"></a> | Test operation ownership / P1 | The first canonical full-suite attempt reached the runtime-efficiency owner after all preceding owners passed, then [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) exposed a stale reviewed AST call graph: four new script-scope `InitialPolicyContract` probes changed `$launcherPath|<script>` from 80 to 84, and `Copy-ImmutableProtocolPolicyFixture` added one function-owned recursive-cleanup identity. | `Blocking` / Resolved in candidate by reconciling only those exact identities; `tests/fixture-operation-budgets.psd1` and all declared runtime maxima remained byte-identical, and focused [TEST-0158](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158)/[TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)/[TEST-0162](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) passed on PowerShell 7 / Windows PowerShell 5.1 in 7.0 / 7.7 seconds. |
| `FIND-0343` <a name="find-0343"></a> | Committed-tree self-consumption / P1 | The pre-commit local full suite ran while the new feature packet was untracked, so the HEAD-based self-consumer graph omitted it. Once committed, two non-table occurrences of a slash-joined inline-code shorthand for `must read`, `must load`, and `must consult` produced the same hosted missing-required-target failure on both runtimes; a third textual occurrence was protected by the Markdown-table gate. | `Blocking` / Resolved in candidate by expanding all three occurrences into distinct code spans under [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) and [issue #144](https://github.com/hasanmanzak/meAndAI/issues/144). On [commit a0ed721](https://github.com/hasanmanzak/meAndAI/commit/a0ed7218175b7e1783c9db56174518eef4b344b0), the exact committed-tree owner passed on PowerShell 7 / Windows PowerShell 5.1 in 136.2 / 236.5 seconds with 2/2 process starts and 4/4 blob requests, and the full committed-tree suite passed in 1805.3 seconds. Hosted confirmation remains a delivery gate; no production parser change is indicated. |
| `FIND-0344` <a name="find-0344"></a> | Publication evidence / P1 | The evidence-sync commit introduced eight code-formatted short references to the implementation checkpoint; seven were renderer-active human-facing commit identities without exact full-SHA permalinks. Hosted Ubuntu passed instruction graph, governance, and every earlier owner before [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) rejected the seven references. | `Blocking` / Resolved in candidate by linking every checkpoint occurrence to its owning-repository exact full-SHA commit permalink. The publication-evidence owner passed [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) and every retained scenario on PowerShell 7 / Windows PowerShell 5.1 in 103.2 / 192.0 seconds; [run 30228883486](https://github.com/hasanmanzak/meAndAI/actions/runs/30228883486) remains the classified expected-red source. This is a candidate evidence correction; no production runtime change is indicated. |

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0250` <a name="risk-0250"></a> | Relaxing hash handling hides a concrete missing required path or changes Markdown-link fragment behavior. | Parser owner / distinguish token production, retain concrete missing/unsafe/link variants, and keep fixed-width placeholder recognition narrow. |
| `RISK-0251` <a name="risk-0251"></a> | Placeholder filtering loses actual feature packets. | Graph owner / all actual files under known `docs/features/` surfaces remain deterministic candidates; assert candidate retention separately from the non-concrete descriptor. |
| `RISK-0252` <a name="risk-0252"></a> | Abort waits indefinitely, double-waits one task, or disposes a live pipe. | Batch-session owner / one monotonic bounded deadline, distinct task identities, controlled completion/unjoined/fault variants, and existing hung-child limits. |
| `RISK-0253` <a name="risk-0253"></a> | Cleanup handling replaces the primary graph error or suppresses a real cleanup failure. | Diagnostic owner / preserve primary-first composition and assert exact ordinary and truly-failed cleanup outcomes. |
| `RISK-0254` <a name="risk-0254"></a> | Raising the single-blob ceiling increases peak allocation and parse work. | Graph/actor owner / exact 524,288 ceiling, unchanged 4 MiB aggregate, eight-blob aggregate N/N+1, and both-actor evidence. |
| `RISK-0255` <a name="risk-0255"></a> | Protected classification hides live authority or weakens the unknown-format guard. | Graph owner / only ordinary `.mqproj` references become unopened `ProtectedNonText`; required/authority/index use and every unrelated unknown extension still fail closed. |
| `RISK-0256` <a name="risk-0256"></a> | Existing schema-1 graph or proposal evidence is silently reinterpreted as schema 2. | Lifecycle owner / immutable target-release policy, schema-bound digest/identity, no conversion, and fail-closed recovery or reassessment. |
| `RISK-0257` <a name="risk-0257"></a> | Suppressing the natural-exit race hides a genuine kill failure while a child remains live. | Batch-session owner / recheck exact process status only after kill throws; suppress only a confirmed exit, retain recheck/kill/reap errors, and keep real kill-failure variants. |
| `RISK-0258` <a name="risk-0258"></a> | Narrowing `load`/`consult` loses a real imperative required-reading declaration. | Parser owner / retain anchored `Read`, `Load`, and `Consult` plus explicit `must read`, `must load`, and `must consult`, required headings/lists, roots, negation, and authority/index matrices. |
| `RISK-0259` <a name="risk-0259"></a> | Ratio filtering hides a legitimate numeric repository path or weakens significant missing-target safety. | Parser owner / consult exact resolved tree membership, retain matching numeric paths, and keep ordinary alphanumeric, link, relative, escape, and missing-path variants. |
| `RISK-0260` <a name="risk-0260"></a> | Qualified-authority matching promotes benign prose or negated evidence. | Parser owner / require `single canonical`, bound qualifier count and token width, exclude tables through the existing gate, and retain explicit ordinary and negative-predicate variants. |
| `RISK-0261` <a name="risk-0261"></a> | A target policy is selected by broad tag inference, mixed with runtime commands, assigned the wrong marker family, or granted runtime fallback outside the reviewed compatibility set. | Release/policy owner / select from exact workflow capability and immutable bytes, bind every graph-aware target to its exact profile and target semantics, compose all three ancillary helpers atomically, preserve schema 7/8 through v0.14.1 and schema 9/10 thereafter, allow graph-unaware runtime fallback only for exact v0.12.4-v0.12.5, and fail closed otherwise. |
| `RISK-0262` <a name="risk-0262"></a> | Placeholder suppression before decoding or scheme classification hides an unsafe/file target or external reference, while token truncation loses a tracked repeated-hash path containing spaces or a fragment. | Parser owner / use one strict decode-scheme-safety-exact-tree pipeline before suppression; retain encoded file/external, spaced code-span/inline/reference-link, and fragment variants in [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152). |
| `RISK-0263` <a name="risk-0263"></a> | A broad negation gate either promotes a negative predicate or suppresses positive authority in another clause on the same line. | Authority owner / mask bounded negative predicates, do not infer path-to-clause ownership, and retain negative-only plus conservative mixed negative/positive line variants in [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151). |
| `RISK-0264` <a name="risk-0264"></a> | URI fragment/query text containing dot segments redirects a literal-hash repository reference after an exact prefix has already been identified. | Parser owner / choose the longest canonical exact-tree prefix before literal membership and keep its suffix opaque to path normalization; retain both fragment and query redirect variants in [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152). |
| `RISK-0265` <a name="risk-0265"></a> | A raw shape filter discards an encoded extensionless target before decoded file/drive/external classification. | Parser owner / decode before any repository-token shape decision; fail closed for decoded file/drive targets and retain decoded external evidence under [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152). |
| `RISK-0266` <a name="risk-0266"></a> | Negative-predicate masking hides a positive authority clause separated by punctuation or a contrastive connector. | Authority owner / mask only bounded negative predicates and treat any retained positive mixed-line declaration conservatively as authority under [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151). |
| `RISK-0267` <a name="risk-0267"></a> | Clause-boundary recognition splits an allowed qualifier conjunction and turns the remaining text into false authority. | Authority owner / do not split the bounded negation mask at qualifier `and`; retain positive and negated qualifier-conjunction variants under [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151). |
| `RISK-0268` <a name="risk-0268"></a> | A second literal or decoded delimiter reopens an opaque URI suffix and lets its dot segments participate in repository normalization. | Parser owner / freeze the first valid exact-tree identity and keep every later decoded delimiter in the opaque suffix; retain literal and percent-encoded nested-delimiter variants in [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152). |
| `RISK-0269` <a name="risk-0269"></a> | A missing direct or reverse negative form promotes a negative canonical-source declaration to live authority. | Authority owner / keep the grammar bounded while covering reviewed modal, contraction, `no longer`, and `never` forms in both directions under [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151). |
| `RISK-0270` <a name="risk-0270"></a> | A generic-width negation mask crosses ordinary extensionless-path prose and hides a later positive authority declaration. | Authority owner / bind every negative predicate to the exact positive authority-designation complement and retain all reviewed connective variants under [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151). |
| `RISK-0271` <a name="risk-0271"></a> | A fixture/helper refactor leaves [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)'s reviewed AST ownership map stale while runtime counters stay green, causing a late full-suite failure or inviting a blind count increase. | Test-infrastructure owner / diff base-to-candidate AST identities by exact parent, reconcile only intended launcher/dynamic/recursive-cleanup additions in the same slice, preserve declared runtime maxima, and require focused [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) plus the final canonical suite; never suppress the inventory or copy observed totals without ownership review. |
| `RISK-0272` <a name="risk-0272"></a> | A new governance packet remains untracked during a worktree suite, so the HEAD-based exact self-consumer graph cannot inspect its committed bytes and a path-like documentation token survives until hosted CI. | Delivery owner / commit the complete graph-reachable packet, run exact-tree [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) against that exact commit on both supported runtimes, invalidate the evidence after any later graph-reachable Markdown change, retain the hosted check, and never treat a dirty-worktree full-suite pass as committed-tree graph evidence. |
| `RISK-0273` <a name="risk-0273"></a> | A late evidence-only commit introduces short or unlinked human-facing commit identities after the earlier full-suite publication-evidence slice passed. | Delivery owner / use exact full-SHA owning-repository permalinks from the first evidence write and rerun [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) after every final evidence synchronization before hosted confirmation. |

## Definition of Ready

- [x] Stable [FEAT-0056](README.md), [BUG-0037](https://github.com/hasanmanzak/meAndAI/issues/140),
  [BUG-0038](https://github.com/hasanmanzak/meAndAI/issues/141),
  [BUG-0039](https://github.com/hasanmanzak/meAndAI/issues/142),
  [BUG-0040](https://github.com/hasanmanzak/meAndAI/issues/143),
  [BUG-0041](https://github.com/hasanmanzak/meAndAI/issues/144),
  [BUG-0042](https://github.com/hasanmanzak/meAndAI/issues/145),
  [BUG-0043](https://github.com/hasanmanzak/meAndAI/issues/146),
  [BUG-0044](https://github.com/hasanmanzak/meAndAI/issues/147),
  [DEC-0031](../../decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md),
  [SUBF-0107](#subf-0107), [SUBF-0108](#subf-0108),
  [SUBF-0109](#subf-0109), [SUBF-0110](#subf-0110),
  [SUBF-0111](#subf-0111), [SUBF-0112](#subf-0112),
  [SUBF-0113](#subf-0113), [SUBF-0114](#subf-0114), findings, risks, and
  canonical GitHub issues are assigned.
- [x] Exact immutable baseline, primary and cleanup failures, production/test
  owners, scope, non-goals, compatibility, and failure behavior are recorded.
- [x] Scenario review classifies parser cases as parameterized
  [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)/[TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152)
  variants and cleanup cases as parameterized [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161)
  variants, not new numbered tests.
- [x] Test-first red, focused PS5.1/7, affected integration, final full suite,
  read-only resimulation, hosted validation, immutable release, and branch
  cleanup are defined.
- [x] The user's active directive authorizes upstream implementation and
  delivery while forbidding consumer repository writes.

## Acceptance criteria

1. Fragment-only whitespace code spans produce no local or external graph
   reference and never reach path resolution with an empty target.
2. A fixed-width numeric filename placeholder is non-concrete and is not
   truncated into a missing path; matching actual known-surface files remain
   graph candidates.
3. Markdown links/reference definitions, tracked repeated-hash paths containing
   spaces, concrete code-span path fragments, concrete required paths, unsafe
   and percent-encoded paths, file/drive/external schemes, and missing-target
   failures keep their exact behavior. Decoding and scheme classification happen
   before raw shape filtering; the longest canonical exact-tree prefix is chosen
   before literal membership; a retained fragment/query suffix stays opaque to
   dot-segment normalization, and a second literal or percent-decoded delimiter
   cannot reopen it as a new path prefix; only then may an untracked repeated-
   hash descriptor be skipped. Descriptive
   `load`/`consult` text is not required reading while explicit imperative,
   `must read`, `must load`, and `must consult` forms remain required. An absent
   all-numeric slash
   code span is non-concrete, while a matching exact tree path remains concrete.
4. Abort kills/reaps the child and joins every distinct pending I/O task within
   one bounded monotonic deadline before transport disposal; clock-integrity
   failure is sticky and every faulted task exception is observed.
5. Ordinary task completion preserves the primary graph error without a false
   cleanup suffix; true unjoined/faulted tasks still produce explicit cleanup
   evidence with primary-first composition. A kill exception is suppressed only
   when an immediate status recheck proves the process already exited.
6. Graph schema 2 accepts a 269,236-byte governance document and exact 524,288
   bytes, rejects 524,289 before payload allocation, and retains the exact
   4,194,304-byte aggregate N/N+1 boundary in both batch actors.
7. An ordinary `.mqproj` reference becomes unopened `ProtectedNonText`
   evidence outside candidates and protocol surfaces; required/authority/index
   use and unrelated unknown extensions still fail closed.
8. Qualified `single canonical ... source/authority` wording produces required
   authority evidence; a protected target blocks for maintainer review, while
   ordinary, table, and negative-only references remain non-authoritative.
   Bounded direct and reverse modal, contraction, `no longer`, and `never`
   negation forms remain ordinary, masking does not split qualifier
   conjunctions, and each mask consumes the same exact authority-designation
   complement as the positive grammar. A negated ordinary extensionless-path
   predicate cannot cross `when`, `because`, `although`, `if`, `after`,
   `before`, or `where` to hide a later positive declaration. If a semicolon,
   period, `but`, `however`, or one of those connective cases separates a
   positive declaration on the same line, authority remains conservatively
   fail closed rather than assigning individual paths to inferred clauses.
9. Schema-1 graph evidence is not reinterpreted as schema 2. A graph-aware
   compatible target uses its exact immutable policy and probed schema; target
   semantics stay target-owned and the ancillary helper trio is composed
   atomically. Schema-7/8 and schema-9/10 marker families remain unchanged
   through proposed, publishing, and completed transitions. Only graph-unaware
   v0.12.4-v0.12.5 targets use the runtime-policy fallback; all other
   graph-unaware targets fail closed.
10. Process/request counts, graph schema/digest determinism, exact-base
   acquisition, compatibility, packaging, and immutable-release behavior
   remain green.
11. Exact read-only simulations classify the three current consumer states
   without modifying their repositories; no GitHub simulation repository is
   created unless actual remote lifecycle behavior becomes necessary.
12. Documentation, memory, version surfaces, canonical issue/PR links, and the
   designated external post-publication authority are current before merge.

## Definition of Done

- [x] Expected-red evidence is recorded against v0.15.4 behavior and the
  unchanged schema-1/capacity/abort behavior in the partial candidate.
- [x] Final canonical parser variants pass on Windows PowerShell 5.1 and
  PowerShell 7 in 248.3/143.5 seconds, including retained batch-lifecycle
  evidence and exact 2/2 process-start and 4/4 blob-request maxima on both
  runtimes.
- [x] Affected initial-adoption integration and one final relevant owner pass.
- [x] One canonical full suite passes on the committed implementation
  candidate tree after the final production and parser correction.
- [x] Exact consumer-tree read-only simulations pass or yield classified,
  non-MAAI blocked outcomes with no consumer writes.
- [x] Bounded diff/self-review has no unresolved `Blocking` finding.
- [x] Protocol, version, changelog, feature, test, memory, and issue/PR links
  are current.
- [ ] Applicable PR review and hosted pre-merge gates pass.

## Post-merge release gate

- Publish immutable `v0.15.5` for the exact merged commit with the two
  [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
  assets, then verify their exact bytes and release identity.
- Add exact release/commit closure evidence to [issues #140](https://github.com/hasanmanzak/meAndAI/issues/140) and
  [#141](https://github.com/hasanmanzak/meAndAI/issues/141),
  [#142](https://github.com/hasanmanzak/meAndAI/issues/142),
  [#143](https://github.com/hasanmanzak/meAndAI/issues/143),
  [#144](https://github.com/hasanmanzak/meAndAI/issues/144),
  [#145](https://github.com/hasanmanzak/meAndAI/issues/145),
  [#146](https://github.com/hasanmanzak/meAndAI/issues/146), and
  [#147](https://github.com/hasanmanzak/meAndAI/issues/147); close only those
  eight owned issues and remove only the exact OID-bound owned branch.
- Dispatch the current-authority post-publication verifier only after issue
  closure and branch absence satisfy its inputs, retain the exact run evidence,
  and add the evidence to the already-closed owned issues when useful.

## Delivery evidence

| Field | Evidence |
| --- | --- |
| Initial expected-red | Windows PowerShell 5.1 canonical owner failed in 204.5 seconds with exactly the eight new [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)/[TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) variants; isolated placeholder output was `docs/features/REC-`. |
| Simulation-discovered expected-red | PowerShell 7 canonical owner failed in 115.7 seconds with exactly six new problems: quick/hosted input-close joining, ordinary and required `.mqproj`, schema/limit identity, and the 269,236-byte governance document. |
| First-candidate expected-red | PowerShell 7 canonical owner failed in 116.2 seconds with exactly three new problems: quick/hosted process-exit kill races and descriptive `load validation` promoted to required reading. |
| Second-candidate expected-red | PowerShell 7 canonical owner failed in 119.0 seconds with exactly one new problem: an untracked numeric `24/24` result became a required repository path. |
| Third-candidate expected-red | PowerShell 7 canonical owner failed in 117.0 seconds with exactly two [BUG-0043](https://github.com/hasanmanzak/meAndAI/issues/146) problems: qualified canonical-source wording remained ordinary and protected authority did not fail closed. |
| Target-policy expected-red | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) failed in 2.4 seconds with exactly two [BUG-0044](https://github.com/hasanmanzak/meAndAI/issues/147) problems: no workflow-aware policy selector and literal proposal schema 2. The immutable v0.15.4 schema-1 probe itself passed. |
| Target-policy focused green | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) passed in 4.0 seconds with exact schema-1/schema-2 policy probes, workflow-aware selection, graph-unaware fallback, JSON dispatch, UTF-8 stdin, compatibility, and callback evidence. |
| Prior focused PS5.1 / PS7 | The canonical instruction-graph owner passed [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) in 220.4 / 119.6 seconds with exact 2/2 process-start and 4/4 blob-request budgets, sticky clock-integrity cleanup, tracked repeated-hash code-span/Markdown forms, and strengthened N+1/authority/cleanup oracles. |
| Final-review expected-red | PowerShell 7 canonical instruction-graph owner failed in 121.1 seconds with exactly 12 problems: three spaced repeated-hash path variants, two encoded-file safety variants, two encoded-external classification variants, and five predicate-negation variants under [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)/[TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152). |
| Independent parser PS7 green | PowerShell 7 canonical instruction-graph owner passed [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and retained [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) in 126.5 seconds, including opaque fragment/query suffixes across nested literal/decoded delimiters, longest exact-prefix resolution, decoded extensionless file/drive/external classification, mixed punctuation/`however` authority, qualifier-conjunction masking, bounded direct/reverse modal/contraction/no-longer/never negation, and exact-complement containment across the reviewed ordinary-prose connectors. |
| Final canonical parser green | Windows PowerShell 5.1 / PowerShell 7 passed [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) in 248.3 / 143.5 seconds with exact 2/2 process starts and 4/4 blob requests on both runtimes. The parser-focused bounded independent audit found no new `Blocking` or `Important` finding on the latest bytes; policy review, both-runtime AST parses, and diff-check were also clean. |
| Final target-policy contracts | `ContractsPreflight` passed on PS5.1 / PS7 in 32.7 / 27.7 seconds; source-graph dispatch passed in 6.2 / 6.3 seconds. Exact v0.12.4 and v0.12.5 workflow blobs, v0.14.1 target semantics plus atomic runtime ancillary provenance, v0.15.4 mutation rejection, partial-family rejection, reverse module cleanup, policy-built schema-1 dispatch, and schema-7/8 and schema-9/10 reconstruction were verified under [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153). |
| Exact v0.12.4 workflow-blob compatibility | The focused [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) source-graph dispatch case passed on PowerShell 7 / Windows PowerShell 5.1 in 5.4 / 5.3 seconds using the exact immutable v0.12.4 workflow blob, retaining only the reviewed v0.12.4-v0.12.5 graph-unaware fallback and fail-closed unsupported tags. |
| Affected initial-adoption integration | PowerShell 7 canonical capabilities-bootstrap owner passed [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) and all 19 declared scenarios in 301.7 seconds with exact operation maxima: 3 graph acquisitions, 4 child processes, 2 bundle families, 2 clones, 3 initializations, and 36 pushes. The focused immutable-policy import and dispatch contracts also passed on PS5.1 and PS7. |
| Quick-adoption bundle / lifecycle shards | The bundle owner passed on PS5.1 / PS7 in 28.8 / 28.2 seconds; the PowerShell 7 `AdoptionLifecycle` shard passed in 184.9 seconds. |
| Latest-byte read-only consumer resimulation | Pre/post remote HEADs were exact and all clones remained clean. Derdini `e7b10ef` retained its classified existing older seed, which v0.15.5 does not recognize. TravelOS `6ee1191` returned assessment schema 3 for graph `0cd369f4...` with 9 nodes / 74 edges: `Auto` required explicit strategy, while hypothetical `FullMigration` was `Resolved`. HAnchor `0281b39` failed closed for maintainer review because protected `HAnchor.mq5` is declared live canonical authority. TravelOS assessment SHA-256 was `cf5f3609931cda8ba51cfb5b9f2325d777c82a7278ffd9ef36251ac509536c16`; latest summary SHA-256 was `b180143e125fdff13d24d3f717aeca4333fd0b6098be8c96cabb0a1ce2177d73`. No consumer was modified and no GitHub simulation repository was created. |
| First canonical full-suite attempt | `tests/protocol.tests.ps1` ran for 1751.8 seconds. Every preceding production, parser, capabilities-bootstrap, quick-adoption, governance, and publication-evidence owner passed; only [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) failed on the stale reviewed AST inventory: `$launcherPath|<script>` expected 80 instead of 84, and one helper-owned recursive-cleanup identity was absent. |
| Focused operation-inventory correction | The runtime-efficiency owner passed [TEST-0158](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158), [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159), and [TEST-0162](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) on PowerShell 7 / Windows PowerShell 5.1 in 7.0 / 7.7 seconds with `contract.self-check` at 1/1; only exact reviewed identities changed, `tests/fixture-operation-budgets.psd1` stayed byte-identical, and declared runtime maxima remained fixed. |
| Pre-commit local full suite | The worktree `tests/protocol.tests.ps1` run passed every discovered suite in 1745.3 seconds. Exact key owner times were 304.600 seconds for capabilities bootstrap, 861.817 seconds for quick adoption, 129.069 seconds for instruction graph, 118.857 seconds for protocol governance, 96.524 seconds for publication evidence, and 6.586 seconds for runtime efficiency; [TEST-0158](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158), [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159), and [TEST-0162](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) were green with `contract.self-check` 1/1. [FIND-0343](#find-0343) later proved that the untracked feature packet was absent from the HEAD-based self-consumer slice. |
| First hosted validation | [Run 30225563133](https://github.com/hasanmanzak/meAndAI/actions/runs/30225563133) failed on Ubuntu PowerShell 7 / Windows PowerShell 5.1 in 7m39s / 23m15s at the same [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) exact-tree diagnostic: the slash-joined inline-code shorthand for the three explicit required-reading commands was classified as a missing required path in this newly committed feature packet. All earlier hosted setup/actionlint/runtime-efficiency and quick-adoption steps passed. |
| Independent changed-document extractor audit | The production reference extractor scanned all 16 changed/new Markdown files against the HEAD path inventory after the candidate correction. No required local missing target remained; the audit confirmed two parser-active non-table occurrences and one table-gated occurrence in the original shorthand family, with no additional `Blocking` or `Important` Markdown-token finding. |
| Corrected committed-tree focus | On [commit a0ed721](https://github.com/hasanmanzak/meAndAI/commit/a0ed7218175b7e1783c9db56174518eef4b344b0), the canonical instruction-graph owner passed [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) on PowerShell 7 / Windows PowerShell 5.1 in 136.2 / 236.5 seconds with exact 2/2 process starts and 4/4 blob requests on both runtimes. |
| Final implementation-tree suite | On [commit a0ed721](https://github.com/hasanmanzak/meAndAI/commit/a0ed7218175b7e1783c9db56174518eef4b344b0), `tests/protocol.tests.ps1` passed every discovered protocol suite in 1805.3 seconds. Capabilities bootstrap passed in 304.173 seconds, quick adoption in 875.939 seconds, instruction graph in 138.206 seconds with exact 2/2 process starts and 4/4 blob requests, protocol governance in 127.574 seconds, publication evidence in 109.268 seconds, and runtime efficiency in 7.839 seconds with [TEST-0158](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158), [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159), [TEST-0162](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162), and `contract.self-check` 1/1. |
| Second hosted expected-red | On [head 7ee6c60](https://github.com/hasanmanzak/meAndAI/commit/7ee6c6058ae349ff52eb3f4c9a0cc16624760632), the Ubuntu slice of [run 30228883486](https://github.com/hasanmanzak/meAndAI/actions/runs/30228883486) passed quick adoption, instruction graph with exact counters, governance, and recurrence prevention before [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) correctly rejected seven unlinked human-facing checkpoint references. |
| Focused publication-evidence correction | The publication-evidence owner passed [TEST-0083](../FEAT-0013-v084-correction/test-cases.md#test-0083), [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178), [TEST-0180](../FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180), [TEST-0181](../FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181), [TEST-0182](../FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182), and [TEST-0189](../FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189) on PowerShell 7 / Windows PowerShell 5.1 in 103.2 / 192.0 seconds without claiming published-state evidence. |
| Pull request | Draft [PR #148](https://github.com/hasanmanzak/meAndAI/pull/148) opened from the exact owned branch; all eight owned issue bodies carry full-SHA feature/decision evidence and linked record identities. |
| Hosted validation | Pending |
| Release | Pending immutable `v0.15.5` |
| Branch cleanup | Pending |
