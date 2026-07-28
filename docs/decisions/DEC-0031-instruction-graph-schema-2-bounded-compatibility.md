# DEC-0031 - Evolve the Instruction Graph to Schema 2 for Bounded Compatibility

- Classification: Decision
- Status: Accepted
- Date: 2026-07-26
- Decision owners: meAndAI maintainer and initial-adoption maintainers
- Related feature: [FEAT-0056](../features/FEAT-0056-v0155-instruction-graph-resilience/README.md)
- Tracking: [BUG-0037 / issue #140](https://github.com/hasanmanzak/meAndAI/issues/140), [BUG-0039 / issue #142](https://github.com/hasanmanzak/meAndAI/issues/142), [BUG-0040 / issue #143](https://github.com/hasanmanzak/meAndAI/issues/143), [BUG-0043 / issue #146](https://github.com/hasanmanzak/meAndAI/issues/146), and [BUG-0044 / issue #147](https://github.com/hasanmanzak/meAndAI/issues/147)
- Supersedes: [DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md) only for the current graph schema, current per-blob ceiling, and current protected-extension vocabulary; clarifies schema-2 reference/authority invariants without reinterpreting immutable schema-1 evidence

## Context

[DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md) makes the
instruction graph release-owned, bounded, exact-base evidence. It also requires
a reviewed graph-schema change before an extension is added, removed, or
reclassified, and calls for review when a real consumer graph exceeds a
declared budget.

Read-only exact-tree simulations exercised both review conditions. One valid
required governance document is 269,236 bytes, only 7,092 bytes above the
schema-1 per-blob ceiling; its complete nine-blob reachable graph is 739,923
bytes and remains well below the 4,194,304-byte aggregate ceiling and every
other graph limit. Separately, a regular `.mqproj` target is reviewed project
metadata encoded as UTF-16 LE. It must be retained as terminal evidence rather
than parsed as UTF-8 instruction text, while the general unknown-format guard
must remain fail closed.

Changing only implementation constants would silently alter schema-1 graph
identity. Relaxing the unknown-format guard would allow an unreviewed custom
format to hide live authority. The compatibility correction therefore needs a
prospective, explicit schema boundary.

The runtime can target an older immutable release. If that target workflow is
graph aware, importing only the runtime policy would apply schema-2 identity to
a schema-1 validator. Compatibility therefore also requires policy selection
from the exact target workflow capability, without converting either schema.
The target policy also owns its transition-marker family and every semantic
graph command. Three later linked-path helpers are graph-agnostic and may be
absent from otherwise complete older target policies, but mixing only part of
that helper family would create unreviewed hybrid semantics.

Conversely, graph-unaware workflows expose no target graph contract. Runtime-
policy fallback is therefore a compatibility exception for the two exact
bundled-runtime releases that predate graph identity, not a general inference
for arbitrary older or future tags.

Schema-2 review also exposed ordering requirements inside the exact-reference
parser. URI fragment/query text is navigation metadata, not another repository
path to normalize; a second literal or percent-decoded delimiter must not reopen
an already opaque suffix as a new path candidate. Encoded extensionless targets
must not disappear in a raw shape prefilter before their decoded file, drive, or
external semantics are known. Authority negation is similarly bounded evidence:
the grammar must cover reviewed direct/reverse modal, contraction, `no longer`,
and `never` forms without splitting an allowed qualifier conjunction. It also
must bind to the exact positive authority-designation complement instead of a
generic character-width window that can cross ordinary prose and erase a later
positive declaration. Because one semantic line does not prove exact path-to-
clause ownership, a mixed negative/positive line must remain conservatively fail
closed.

## Decision

1. The current instruction-graph contract is schema 2. Schema remains part of
   the canonical digest and every compact graph identity.
2. Schema 2 raises only the inclusive per-blob parsing ceiling from 262,144 to
   524,288 bytes. The aggregate parsed-blob ceiling remains 4,194,304 bytes;
   the tree, node, edge, depth, tree-path, and graph-path limits are unchanged.
3. Schema 2 adds only `.mqproj` to the terminal protected source/binary
   vocabulary. An ordinary reference produces an unopened `ProtectedNonText`
   node and edge. The target is neither a compatibility candidate nor a
   protocol surface.
4. A protected `.mqproj` target used as `RequiresRead`, `DeclaresAuthority`, or
   `Indexes` remains a maintainer-review failure. Every other regular extension
   outside the traversable and protected vocabularies remains unsupported and
   fails closed.
5. Pure policy, quick and hosted batch actors, release validation, graph
   serialization, proposal/completion identities, and dispatch evidence use
   the same release-owned schema and limits. Exact 524,288 is accepted;
   524,289 is rejected before payload allocation; the unchanged aggregate
   boundary retains exact N/N+1 evidence.
6. Immutable schema-1 releases keep their 262,144-byte ceiling and exact
   extension vocabulary. Schema-1 graph evidence is never converted or
   reinterpreted as schema 2. A graph-aware lifecycle uses the policy owned by
   its exact supported target release. Runtime-policy fallback is allowed only
   when the exact target workflow is graph unaware and its tag is `v0.12.4` or
   `v0.12.5`. Every other graph-unaware tag, every graph-aware tag without a
   reviewed profile, and every schema mismatch fails closed and requires
   recovery under a supported immutable target or close-and-reassessment.
7. Target-policy validation binds every supported graph-aware tag to its exact
   reviewed graph profile rather than accepting a broad upper bound. Tags not
   covered by a row are unsupported. The common tree-entry, tree-path, depth,
   and aggregate ceilings remain 65,536, 4,194,304, 32, and 4,194,304
   respectively:

   | Exact target interval | Schema / blob | Nodes / edges / path bytes | Transition marker family |
   | --- | --- | --- | --- |
   | `v0.12.6` through `v0.14.1` | `1` / `262144` | `256` / `2048` / `16384` | `7` Proposed/Completed; `8` Publishing |
   | `v0.14.2` | `1` / `262144` | `256` / `2048` / `16384` | `9` Proposed/Completed; `10` Publishing |
   | `v0.14.3` through `v0.14.5` | `1` / `262144` | `256` / `4096` / `16384` | `9` Proposed/Completed; `10` Publishing |
   | `v0.15.0` through `v0.15.1` | `1` / `262144` | `512` / `4096` / `16384` | `9` Proposed/Completed; `10` Publishing |
   | `v0.15.2` through `v0.15.4` | `1` / `262144` | `512` / `4096` / `32768` | `9` Proposed/Completed; `10` Publishing |
   | `v0.15.5` through `v0.16.0` | `2` / `524288` | `512` / `4096` / `32768` | `9` Proposed/Completed; `10` Publishing |

8. All assessment, graph, strategy, closure, and marker semantics come from
   the exact selected target policy. A schema-7/8 marker remains in that family
   through Proposed, Publishing, and Completed transitions; it is not rebuilt
   as schema 9/10 merely because a newer runtime executes the transition. The
   three linked-path rendering and validation helpers are one atomic graph-
   agnostic family. A target exports all three itself, or an older target
   exporting none composes exactly those three from the runtime policy. Partial
   families and every missing target-semantic command fail closed. Both exact
   module instances are tracked and removed in reverse import order.
9. Schema-2 reference resolution strictly decodes a token before any raw
   repository-shape filter. Decoded `file:` and drive targets fail closed;
   decoded external schemes remain external even when extensionless. For a
   local target containing literal `#` or `?`, the resolver selects the longest
   canonical exact-tree prefix before considering literal membership. Once the
   first valid boundary establishes that exact identity, the remaining
   fragment/query suffix is opaque and never participates in repository dot-
   segment normalization. A later literal or percent-decoded delimiter cannot
   reopen the preceding suffix as another normalized prefix. Placeholder
   suppression occurs only after those classifications.
10. Schema-2 qualified-authority parsing masks bounded direct and reverse modal,
   contraction, `no longer`, and `never` negative predicates without treating
   qualifier conjunctions as clause boundaries. Every negation consumes the
   same exact authority-designation complement accepted by the positive grammar;
   a generic character-width mask across ordinary prose is not allowed. A
   negative-only declaration remains ordinary. If a separate positive
   declaration remains after `but`, a semicolon, a period, `however`, or another
   reviewed connector, the semantic line remains authoritative. Exact path-to-
   clause ownership is not inferred; mixed negative/positive evidence therefore
   fails closed conservatively for protected targets.

## Consequences

- A bounded real governance document can participate in exact graph discovery
  without increasing the total graph memory envelope.
- Reviewed MetaEditor project metadata is visible as protected terminal
  evidence without exposing its UTF-16 bytes to the instruction parser.
- Every graph digest changes prospectively because schema and the per-blob
  limit are digest inputs. Current fixtures, identities, and handoffs must move
  together; outer manifest and proposal/publishing marker schemas do not
  change.
- Eight maximum-size schema-2 blobs can consume the unchanged aggregate budget.
  Larger individual or aggregate inputs still block before semantic or remote
  mutation.
- In-flight schema-1 evidence cannot be silently reused by schema-2 code.
- Older graph-aware releases retain their exact smaller limits, graph
  semantics, and schema-7/8 or schema-9/10 transition evidence while remaining
  operable with the current linked-path proposal surface; runtime helpers never
  replace target graph commands and the helper family is never split.
- Graph-unaware runtime fallback has a finite compatibility set: v0.12.4 and
  v0.12.5. Too-old, unknown, and future graph-unaware tags fail closed instead
  of inheriting current runtime semantics.
- A drifted historical profile, missing target-semantic export, or partial
  ancillary family is rejected before assessment or consumer mutation.
- Fragment/query suffix text cannot redirect a literal-hash reference through
  path normalization; exact-tree identity is selected from the longest
  canonical prefix and the suffix stays opaque across every later literal or
  decoded delimiter.
- Encoded extensionless file/drive targets fail closed and encoded external
  schemes remain visible instead of being discarded by raw token shape.
- Reviewed direct/reverse negative forms remain wholly masked only when they
  consume the exact positive authority-designation complement; qualifier
  conjunctions remain intact, ordinary negated prose cannot absorb later
  authority through a generic-width window, and any retained positive mixed-line
  authority keeps protected evidence on the conservative maintainer-review path.

## Verification

The final canonical instruction-graph owner passed
[TEST-0151](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151),
[TEST-0152](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152),
and [TEST-0161](../features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161)
on Windows PowerShell 5.1 / PowerShell 7 in 248.3 / 143.5 seconds with exact 2/2
process starts and 4/4 blob requests on both runtimes. The parser-focused bounded
independent audit found no new `Blocking` or `Important` finding on the latest
bytes; both runtime AST parses and diff-check were clean. The overall bounded
diff/self-review, full-suite, and hosted gates remain pending under
[FEAT-0056](../features/FEAT-0056-v0155-instruction-graph-resilience/README.md).

Latest-byte read-only consumer resimulation also retained exact pre/post remote
HEADs and clean clones. TravelOS produced assessment schema 3 over the same
9-node / 74-edge exact graph and separated explicit `Auto` strategy from a
resolved hypothetical `FullMigration`; HAnchor retained the protected live-
authority maintainer-review failure. Derdini retained its independently
classified older-seed boundary. No consumer was modified and no GitHub
simulation repository was created.

## Alternatives considered

- Increase only the implementation actor limit: rejected because policy,
  identity, digest, release validation, and both actors would diverge.
- Increase the aggregate budget as well: rejected because the observed graph
  does not require it and a larger total memory envelope has no evidence.
- Parse `.mqproj` as text or JSON: rejected because the reviewed format is
  UTF-16 project metadata, not live UTF-8 instruction authority.
- Treat every unknown extension as protected: rejected because an unknown
  custom text format could then hide transitive authority.
- Add consumer filenames or paths: rejected because shared policy must remain
  project-neutral.
- Always use the runtime policy: rejected because a graph-aware immutable
  target owns its accepted graph schema, limits, semantics, and marker family;
  overriding them would reinterpret exact release evidence.
- Always use the target policy: rejected because exact graph-unaware v0.12.4
  and v0.12.5 workflows accept no source-graph identity and require the bounded
  runtime fallback.
- Require every older target to export the current helper surface: rejected
  because `v0.12.6` through `v0.14.1` own complete graph semantics but predate
  the graph-agnostic linked-path helper family.

## Review condition

Review this decision if another real exact graph exceeds the retained limits,
if `.mqproj` becomes a live instruction format, if another extension needs
classification, if eight full-size blobs create unacceptable supported-host
resource pressure, if another exact graph-unaware target needs fallback, if a
supported target changes its profile, exports, or marker family, or if
immutable target-policy recovery cannot distinguish schema-1 and schema-2
evidence without conversion. Also review if URI suffix semantics, decoded
scheme handling, reference token-shape rules, nested delimiter handling,
authority-designation complements, direct/reverse negation vocabulary,
qualifier conjunctions, or semantic-line authority ownership change.
