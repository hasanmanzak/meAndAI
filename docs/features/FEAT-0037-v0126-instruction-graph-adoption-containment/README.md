# FEAT-0037 - Exact Instruction-Graph Discovery and Fail-Closed Containment

| Field | Value |
| --- | --- |
| Classification | Feature / adoption-safety and deterministic discovery infrastructure |
| Status | Complete |
| Target version | 0.12.6 |
| Issue and post-publication authority | [#93](https://github.com/hasanmanzak/meAndAI/issues/93) |
| Maintainer disposition | [Accepted on 2026-07-21](https://github.com/hasanmanzak/meAndAI/issues/93#issuecomment-5033653638) |
| Pull request | [#94](https://github.com/hasanmanzak/meAndAI/pull/94) (Merged) |
| Decision | [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) (Accepted) |
| Tests | [TEST-0151](test-cases.md#test-0151), [TEST-0152](test-cases.md#test-0152), [TEST-0153](test-cases.md#test-0153), and [TEST-0154](test-cases.md#test-0154) |

## Problem

Initial adoption currently classifies a bounded list of known repository paths.
It does not follow the repository-relative instruction graph rooted in tracked
instruction files. A consumer can therefore expose only `AGENTS.md` to the
classifier while that file transitively requires custom memory, development
protocol, tracker, test-catalog, or other governance authorities.

The semantic completion prompt asks the agent to report additional authority,
but the completion validator checks only the original path-first surface set.
If the semantic actor overlooks a referenced authority, `FullMigration` can be
accepted while legacy live authority remains. This is a discovery and closure
coverage defect, not authorization to expand semantic mutation.

## Outcome

Initial adoption and its capability bootstrap derive strategy evidence from one
exact-base, deterministic instruction graph. The graph identity remains bound
through assessment, dispatch, transient manifest, proposal ownership, issue,
prompt, recovery, and completion. Completion independently rebuilds the base
graph and evaluates the final instruction graph before publication.

Any discovered authority or required reference outside the existing mutation
envelope remains exact protected evidence. If the selected strategy would need
that path changed or retired, adoption fails closed instead of publishing a
partial migration. FEAT-0037 does not perform the semantic migration that a
later feature may authorize.

## Scope

- Define a canonical graph contract over one exact captured consumer base
  commit, including roots, nodes, directed edges, known-surface compatibility
  candidates, finite limits, canonical serialization, and a lowercase SHA-256
  digest.
- Discover every tracked root or nested `AGENTS.md` plus the declared generic
  instruction roots without consumer-specific memory or governance paths, and
  retain the complete current known-surface predicate as an explicit versioned
  compatibility seed rather than a second classifier.
- Extract supported local Markdown links, reference-style links, explicit
  repository path tokens, required-reading relationships, and scoped nested
  instruction relationships using one versioned deterministic grammar with
  bounded CommonMark-compatible fence handling.
- Traverse local regular text blobs transitively, deduplicate cycles, preserve
  exact Git path spelling, and record external references without fetching
  them.
- Read tree entries and blob bytes only from the exact committed base; keep the
  worktree a destination and drift check, never committed-state evidence.
- Derive the existing sorted `protocolSurfaces` strategy projection from the
  graph union, including compatibility seeds, instead of treating a second
  path classifier as an independent authority. Keep canonical target
  collisions separate.
- Bind graph base, digest, counts, limits, and required projections through the
  quick launcher, workflow adapter, manifest, proposal marker, issue, semantic
  prompt, recovery intent, and completion evidence.
- Independently rebuild the source graph and final graph at completion, reject
  uncovered or newly introduced live authority, and preserve the existing
  product/application mutation envelope.
- Preserve completed-consumer routes and the immutable recovery meaning of
  legacy proposal schemas.
- Add project-neutral fixtures covering chained custom governance, nested
  scopes, cycles, an unlinked known-surface compatibility candidate, drift,
  safety boundaries, and a semantic actor that omits linked authority.

## Non-goals

- A semantic migration planner, plan-bound executor, parity reviewer, product
  catalog converter, or `PROD-NNNN` contract.
- A new entry in `capabilities/index.json` or a new terminal capability-ledger
  state. Instruction-graph discovery is shared lifecycle infrastructure, not a
  consumer practice to assess.
- Expanding `MIG-NNNN`, the deterministic updater managed set, or the current
  initial-adoption write/deletion envelope.
- Inferring product meaning, authority precedence, semantic equivalence, or
  conflict resolution from arbitrary prose.
- Parsing application source, following external URLs, dereferencing links or
  gitlinks, or building a universal repository/AI-memory scanner.
- Scanning arbitrary root-unreachable text for authority wording. A file that
  is neither reachable from an instruction root nor matched by the versioned
  compatibility seed remains protected unknown evidence: it is not live
  authority, not a freshness blocker, and not deletable by this feature.
- Automatically editing, deleting, marking ready, approving, merging, or
  leaving a permanent graph ledger or compatibility mapping in a consumer.
- Retrofitting graph authority into a legacy proposal or returning a completed
  consumer to initial adoption.

## Readiness evidence and contracts

### Ownership and capability integration

- The immutable capabilities bootstrap contract remains the single pure-policy
  authority. It owns graph canonicalization, discovery grammar, role and edge
  vocabulary, projections, limits, and digest semantics.
- The quick launcher and workflow adapter own only their distinct Git/GitHub,
  exact-tree/blob acquisition, containment, TOCTOU, and mutation boundaries.
  They call the same graph contract and do not embed or cross-check a second
  parser or classifier.
- [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md) continues to own strategy selection and the current mutation
  envelope. [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) continues to prohibit capability types from granting path
  authority. `capabilities/index.json`, the capability ledger, and the
  deterministic migration catalog remain byte-unchanged in this feature.
- A future semantic FullMigration capability is not declared until its
  read-only planner and reviewed lifecycle exist in a separately approved
  feature.

### Graph semantic types

- `BaseHead` is the exact canonical 40-character lowercase commit SHA captured
  before assessment. Every repository node resolves from that commit's Git
  tree entry and, where inspected, its exact regular blob.
- Seed kinds are `ScopedAgents`, `GenericInstructionRoot`,
  `KnownSurfaceCompatibility`, and `ReservedIntegrationAuthority`.
- Repository-node roles are `InstructionRoot`, `ReferencedText`,
  `ProtectedNonText`, and `UnlinkedKnownSurfaceCandidate`. Graph membership is
  evidence only; it is never write or deletion authorization.
- Edge kinds are `Scopes`, `RequiresRead`, `DeclaresAuthority`, `Indexes`, and
  `References`. Discovery records the source path, target path or external URI,
  exact source anchor, and extraction reason.
- Each repository node records exact `path`, `mode`, `type`, `blobSha`, `scope`,
  `role`, and an ordinally sorted unique discovery-reason set. Fragments do not
  change file identity.
- Nodes, roots, edges, candidates, and reasons are unique and sorted with
  ordinal comparison. Case-insensitive aliases and NFC-equivalent Unicode
  aliases are ambiguous and fail closed while the original Git spelling
  remains authoritative.
- The graph digest is lowercase SHA-256 over a versioned, length-prefixed UTF-8
  representation containing schema, base, declared limits, roots, nodes,
  edges, candidates, and the derived surface projection. It does not depend on
  PowerShell JSON property ordering, culture, newline convention, or worktree
  filtering.

### Deterministic roots and traversal grammar

- Instruction roots include every tracked `AGENTS.md` at every depth; root
  `CLAUDE.md`, `GEMINI.md`, `PROTOCOL.md`, `.cursorrules`, `.windsurfrules`, and
  `.github/copilot-instructions.md`; and supported regular text entries under
  `.github/instructions/`, `.cursor/rules/`, and `.windsurf/rules/`.
  Intermediate trees and unsupported binary descendants are not opened; paths
  retained by the compatibility seed remain evidence-only candidates.
- The schema also carries the complete v0.12.5 known-surface file/root
  predicate, including `CONTRIBUTING.md`, flat and `ai/` tracker files,
  `.ai/protocol/`, `.ai/memory/`, and `docs/features/`, `docs/decisions/`,
  `docs/findings/`, `docs/governance/`, `docs/ideas/`, and
  `docs/agent-prompts/`. A matched path not reachable from an instruction root
  is an `UnlinkedKnownSurfaceCandidate`; it preserves existing strategy
  behavior but does not become live authority or mutation authorization.
- Markdown inline and reference links resolve relative to their source file.
  Explicit `./` and `../` path tokens resolve lexically relative to the source;
  canonical unprefixed repository tokens resolve from the repository root.
- Schema-1 traversable text extensions are exactly `(none)`, `.md`,
  `.markdown`, `.txt`, `.rst`, `.org`, `.adoc`, `.asciidoc`, `.json`, `.yaml`,
  `.yml`, `.toml`, `.ini`, `.cfg`, `.conf`, `.rules`, and `.mdc`; [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
  owns the exact protected source/binary vocabulary and the narrower explicit-
  directive rule for flat extensionless code spans.
- Fenced examples do not create edges. External URLs are recorded but never
  fetched. A missing required local target, repository escape, ambiguous path,
  invalid UTF-8 instruction blob, or unsupported special entry blocks rather
  than producing a partial graph.
- Regular modes `100644` and `100755` may be inspected with their original mode
  retained. Mode `120000`, mode `160000`, trees, reparse destinations, and
  other non-regular targets are never dereferenced and require review when a
  required edge reaches them.
- No other root-unreachable text is opened to search for authority wording.
  Such a file remains protected unknown evidence and cannot be changed or
  deleted by FEAT-0037. New generic seed conventions require a later reviewed
  schema change rather than heuristic expansion.

### Finite limits

The first graph schema declares the following inclusive limits. Reaching a
limit is valid; exceeding one blocks before repository, secret, branch, issue,
pull-request, or semantic-model mutation.

| Dimension | Inclusive limit |
| --- | ---: |
| Tracked tree entries inspected | 65,536 |
| Aggregate tracked-tree path inventory | 4,194,304 UTF-8 bytes |
| Graph nodes | 256 |
| Directed edges | 2,048 |
| Traversal depth | 32 |
| One parsed blob | 262,144 bytes |
| Aggregate parsed blobs | 4,194,304 bytes |
| Graph path inventory | 16,384 UTF-8 bytes |

The planning draft's 1,024-edge value was corrected before release after the
required full-transitive self-consumer fixture produced 1,108 canonical edges.
The 2,048 ceiling and the new aggregate tree-path acquisition bound both have
exact N/N+1 evidence; no published graph schema is being revised.

### Lifecycle, schemas, and compatibility

- New local assessment snapshots use schema 3 and new adoption manifests use
  schema 3. The manifest holds the complete bounded graph; issue and prompt
  render only the bounded review projection needed by their consumer.
- New proposed ownership markers use schema 7 and publishing/recovery markers
  use schema 8. They bind `graphBase`, `graphDigest`, graph counts, strategy,
  derived surfaces, repository, target, protocol, branch, actor, and head.
- Existing manifest schema 2 and proposal/publishing marker schemas 5/6 retain
  only their immutable encoded meaning. A new graph-aware release may recover
  them only when no newly discovered authority changes the old assessment;
  otherwise it requires close-and-reassessment and never edits old policy in
  place.
- When the current runtime targets a compatible older release whose immutable
  workflow does not declare `source_graph_identity`, dispatch omits that field
  and preserves the older target contract. Graph identity is never sent as an
  unexpected input, and target identity remains independent from runtime
  identity under [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md).
- The full graph is transient. Successful completion removes the manifest and
  leaves no graph ledger, compatibility router, or duplicate protocol
  authority in the final consumer tree.
- Completed consumers remain on their current/update/capability-review routes
  and are not retroactively assessed as initial adopters.

### Containment and closure

- `protocolSurfaces` remains a compatibility-shaped projection derived from
  reachable graph evidence plus the versioned known-surface compatibility
  seeds and is not an independent parser input. This union must reproduce all
  current known-surface detections before adding newly reachable custom paths.
- A node outside the current legacy-governance mutation predicate is
  evidence-only and must retain its exact base blob and mode. If FullMigration,
  HybridReconciliation, or CleanStart would require changing or retiring it,
  completion reports `MEANDAI_ADOPTION_BLOCKED` with exact unresolved paths.
- Before mutation or proposal reuse, the launcher and hosted adapter
  independently rebuild the bound source graph and require exact source digest
  equality. Before publication they rebuild the candidate final graph and
  apply closure; final equality with the source graph is neither required nor
  expected. An authorized rewrite or retired edge inside the existing mutation
  envelope is valid only when the final roots reach the canonical new live
  authority and no required legacy authority remains. Unplanned source drift,
  an unresolved or newly introduced legacy authority, an unapproved final
  edge, an unsafe entry, protected-content change, or out-of-envelope required
  retirement blocks without completion push or ready transition.
- Existing application source, product documentation, product tests, binaries,
  assets, and runtime configuration remain outside this feature's mutation
  authority and retain exact base blob/mode unless a separately approved future
  feature changes that contract.

### Consumers and dependencies

- Entry points: the pure capabilities bootstrap module, workflow adapter,
  quick-adoption repository assessment, proposal ownership, semantic prompt,
  completion/publication, and recovery paths.
- Known consumers: the meAndAI repository itself under its recursive protocol,
  protocol-free repositories, repositories with custom instruction/governance
  topology, nested scoped instructions, completed meAndAI consumers, and
  legacy in-flight adoption proposals.
- Dependencies: [FEAT-0029](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md),
  [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md),
  [FEAT-0033](../FEAT-0033-canonical-base-blob-migration-planning/README.md),
  [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md),
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md),
  and [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md).
- Error model: missing, malformed, ambiguous, linked, escaping, over-budget,
  drifted, unsupported, incomplete, or legacy-incompatible evidence blocks at
  the next mutation boundary and never returns a partial graph as complete.

## Risks

| ID | Classification | Risk | Owner / response and evidence |
| --- | --- | --- | --- |
| `RISK-0171` <a name="risk-0171"></a> | Discovery completeness | Linked authority omission causes false freshness or partial FullMigration closure | Protocol maintainer / recursive graph plus independent final closure in [TEST-0151](test-cases.md#test-0151) and [TEST-0154](test-cases.md#test-0154) |
| `RISK-0172` <a name="risk-0172"></a> | Authority classification | Ordinary product or architecture documentation is overclassified, or graph membership becomes mutation authority | Protocol maintainer / exact reachable-or-versioned-seed candidate universe, benign controls, evidence-only default, and [TEST-0151](test-cases.md#test-0151) / [TEST-0154](test-cases.md#test-0154) |
| `RISK-0173` <a name="risk-0173"></a> | Committed-state integrity | Worktree bytes or a moved base produce a graph different from the maintainer-authorized tree | Launcher/workflow maintainers / exact base tree/blob reads and graph rebinding in [TEST-0152](test-cases.md#test-0152) / [TEST-0153](test-cases.md#test-0153) |
| `RISK-0174` <a name="risk-0174"></a> | Path containment | Symlink, gitlink, reparse, path escape, case alias, or Unicode alias crosses the repository boundary | Protocol maintainer / no dereference, lexical resolution, alias rejection, and [TEST-0152](test-cases.md#test-0152) |
| `RISK-0175` <a name="risk-0175"></a> | Resource exhaustion | Cycles, depth, node, edge, or byte volume consume unbounded resources | Protocol maintainer / visited set, inclusive release limits, N/N+1 fixtures, and [TEST-0151](test-cases.md#test-0151) / [TEST-0152](test-cases.md#test-0152) |
| `RISK-0176` <a name="risk-0176"></a> | Policy duplication | Launcher, workflow, and completion acquire divergent graph classifiers | Protocol maintainer / one pure contract authority, I/O-only adapters, structural duplicate-policy checks, and [TEST-0153](test-cases.md#test-0153) |
| `RISK-0177` <a name="risk-0177"></a> | Compatibility and recovery | Graph schema/digest changes strand existing proposals or alter completed-consumer behavior | Lifecycle maintainer / prospective schemas, immutable legacy recovery, close-and-reassess, and [TEST-0153](test-cases.md#test-0153) |
| `RISK-0178` <a name="risk-0178"></a> | Closure integrity | A bound base graph passes while unresolved/new final authority or protected-content mutation is published | Completion maintainer / independent final graph rebuild, closure predicate, exact protected-tree diff, and [TEST-0154](test-cases.md#test-0154) |

## Test readiness

| Test readiness | Current state | Evidence |
| --- | --- | --- |
| Scenarios | Defined and registered | [TEST-0151](test-cases.md#test-0151), [TEST-0152](test-cases.md#test-0152), [TEST-0153](test-cases.md#test-0153), and [TEST-0154](test-cases.md#test-0154) have canonical capability-owned executable owners |
| Test code | Locally complete | Graph, exact-Git acquisition, lifecycle identity, local and hosted-adapter closure, and test-architecture fixtures are present on `codex/feat-0037-instruction-graph-containment` |
| Local evidence | Complete for the corrected parser and prior candidate | The corrected graph owner passed in 168.6 seconds on Windows PowerShell 5.1 and 167.1 seconds on containerized PowerShell 7.4.2; the local Windows execution of the complete hosted-adapter fixture passed in 316.2 seconds. Prior focused closure, capability-bootstrap `All`, quick-adoption `All`, `StructureOnly`, `WindowsNative`, and complete-suite evidence remains recorded in the test ledger |
| Hosted evidence | Complete | Replacement checks passed before [PR #94](https://github.com/hasanmanzak/meAndAI/pull/94) merged at commit [`6de31e0c318666bfa1fb884f2f5a791ecaf0fd3e`](https://github.com/hasanmanzak/meAndAI/commit/6de31e0c318666bfa1fb884f2f5a791ecaf0fd3e) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0070` <a name="subf-0070"></a> | Canonical instruction-graph contract and deterministic discovery | [Issue #93](https://github.com/hasanmanzak/meAndAI/issues/93) | [TEST-0151](test-cases.md#test-0151), [TEST-0152](test-cases.md#test-0152); corrected focused owner passed in 168.6 seconds on Windows PowerShell 5.1 and 167.1 seconds on containerized PowerShell 7.4.2 | Parser, lexical-path, culture, budget, cycle, reason, role, exact-validator, and cross-runtime physical-line findings were corrected and rerun | Locally complete |
| `SUBF-0071` <a name="subf-0071"></a> | Exact-base graph acquisition and lifecycle identity binding | [Issue #93](https://github.com/hasanmanzak/meAndAI/issues/93) | [TEST-0153](test-cases.md#test-0153); the local Windows execution of the corrected complete hosted-adapter fixture passed in 316.2 seconds; prior capability-bootstrap `All` and complete-suite evidence remains recorded | Trust-boundary, schema, drift, target dispatch, dynamic-module, and completed-proposal fixture findings were corrected and rerun | Complete |
| `SUBF-0072` <a name="subf-0072"></a> | Independent completion containment and authority closure | [Issue #93](https://github.com/hasanmanzak/meAndAI/issues/93) | [TEST-0154](test-cases.md#test-0154); final focused closure passed in 40.202 seconds, quick-adoption `All` passed in 948.236 seconds, and the complete suite reran it in 928.828 seconds | Fail-closed omission, canonical-retirement, protected-terminal, and out-of-envelope cases were corrected and rerun | Locally complete |

## Decisions and relationships

- Governing decision: [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
- Initial-adoption strategy: [FEAT-0029](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md) / [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md)
- Capability framework: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Exact-base byte authority: [FEAT-0033](../FEAT-0033-canonical-base-blob-migration-planning/README.md)
- Tracking and post-publication authority: [Issue #93](https://github.com/hasanmanzak/meAndAI/issues/93)
- Future semantic planning, product records, execution, and parity work are not
  authorized by this feature and require separately disposed feature records.

## Definition of Ready

- [x] Stable feature, subfeature, risk, test, decision, and issue identities exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Roots, nodes, edges, roles, canonicalization, digest, limits, identity,
      lifecycle, error, mutation, and compatibility contracts are explicit.
- [x] Consumers, entry points, dependencies, and existing capability ownership
      boundaries are identified.
- [x] `RISK-0171` through `RISK-0178` have owners and required evidence.
- [x] Three independently reviewable slices have a dependency-ordered gate ledger.
- [x] Numbered success, negative, boundary, drift, recovery, omission, and
      protected-content scenarios and their planned owners are defined.
- [x] Test-first implementation, baseline state, finite validation budget, and
      verification approach are recorded.
- [x] Maintainer disposition accepted FEAT-0037 and [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) on 2026-07-21.
      The maintainer subsequently gave the separate explicit development
      directive that authorized this local implementation.

## Acceptance criteria

1. Every tracked `AGENTS.md` and declared generic instruction root is assessed
   from the exact base commit without a consumer-specific governance path.
2. The project-neutral five-node instruction chain is discovered transitively
   and exactly once, while nested scope and cycles terminate deterministically.
3. The same exact base produces byte-identical graph serialization and digest
   under Windows PowerShell 5.1 and supported PowerShell 7 hosts.
4. Required missing targets, root escapes, invalid UTF-8, unsupported modes,
   links/reparse points, gitlinks, case/Unicode aliases, and every N+1 budget
   variant fail before external or semantic mutation.
5. `Auto` and explicit strategy resolution use only the graph-derived surface
   projection; an unrelated canonical target collision alone does not become
   fictional migration evidence.
6. Graph base and digest remain exact through preflight, dispatch, independently
   rebuilt workflow evidence, manifest, marker, issue, prompt, recovery, and
   completion.
7. Any source path, blob, mode, role, candidate, or edge drift blocks mutation
   or proposal reuse without silently retargeting the maintainer's strategy.
   Deliberate final-graph changes are accepted only through the existing
   mutation envelope and the declared final closure predicate.
8. Graph membership never expands mutation/deletion authority. Required changes
   outside the current envelope retain the manifest and return
   `MEANDAI_ADOPTION_BLOCKED` with exact unresolved paths.
9. Completion independently rebuilds the source and final graphs and cannot
   publish while a bound legacy authority remains live, a new noncanonical
   authority is unassessed, the final roots do not reach canonical new live
   authority, or protected content differs from the base.
10. A semantic actor that reconciles only `AGENTS.md` while leaving its four
    required custom authorities live is mechanically rejected before completion
    push or ready transition.
11. Legacy graph-unaware proposals retain only their immutable recovery meaning;
    newly discovered authority requires close-and-reassessment. Completed
    consumers remain on their current/update/capability-review routes.
12. The capability catalog, capability ledger schema, migration catalog,
    product/application mutation envelope, and no-auto-ready/approve/merge
    boundaries remain unchanged.
13. Running discovery against the meAndAI repository's own exact fixture proves
    that meAndAI is governed as a consumer of the same graph contract; no
    repository-name exception or privileged topology is introduced.

## Verification approach

1. Add the capability-owned graph and lifecycle fixtures before production
   behavior and record the expected-red current path-only inventory and partial
   completion acceptance.
2. Implement `SUBF-0070`, run [TEST-0151](test-cases.md#test-0151)/[TEST-0152](test-cases.md#test-0152), and perform one fresh-diff
   contract/security review.
3. Implement `SUBF-0071`, run [TEST-0153](test-cases.md#test-0153) plus affected initial-adoption and
   quick-launcher compatibility owners, and review schema/identity drift.
4. Implement `SUBF-0072`, run [TEST-0154](test-cases.md#test-0154), affected recovery/completion owners,
   PowerShell 5.1/7 fixtures, and protected-tree checks.
5. Run `tests/protocol.tests.ps1 -StructureOnly`, affected focused suites, the
   declared native compatibility profile, one complete suite, one fresh-diff
   review per slice, and the single bounded post-development convergence scan.
6. Validation budget: one expected-red run per new scenario owner, one focused
   final command per slice after fixes, one complete suite after all slices,
   one initial convergence scan, and at most one confirmation after remediation.

## Self-review

The accepted planning review remains historical evidence. Three bounded
implementation reviews and the final convergence pass drove concrete production
corrections: inclusive traversal budgets, shortest-path cycle/back-edge depth,
exact derived discovery reasons, culture-invariant authority parsing, lexical
Git-path handling independent of the host file-system API, BOM and line-ending
normalization, URI/command/fenced-example rejection, Unicode and spaced-path
support, significant reading-list propagation, protected-terminal rejection,
and exact source/final graph identity validation.

Lifecycle review additionally corrected dynamic policy callback scope, regular
legacy `.ai/protocol/**` traversal versus canonical protocol-gitlink handling,
immutable older-target graph-input feature detection, and Hybrid retention for
a pre-existing generic instruction root. Empty-array, helper-closure,
dynamic-module restoration, and exact fixture-inventory corrections were test
harness changes only; they did not relax the production validator. The final
focused owners, `StructureOnly`, `WindowsNative`, and the complete 1,582.88-second
protocol suite all pass. Hosted CI and supported PowerShell 7 evidence remain
delivery gates and are not projected by this local review.

The first hosted Ubuntu run then exposed a blocking cross-runtime defect in the
new parser: PowerShell 7 interprets a negative `-split` limit differently from
Windows PowerShell 5.1 and merged the complete instruction document into one
logical line. The correction uses explicit .NET regex splitting without
discarding empty physical lines, and a focused regression binds conditional
manifest and required protocol references to distinct kinds, anchors, and
required states. The corrected graph owner passes on both tested runtimes and
the local Windows execution of the complete hosted-adapter fixture passes;
replacement hosted checks remain the external gate.

The budgeted 2026-07-22 confirmation convergence scan covered the tracked
candidate documentation/evidence surface plus all 16 tracked production files
and the focused regression owner. It found one parser definition, one
production invocation, no stale or embedded parser copy, and zero unresolved
local Blocking observations after remediation. Hosted PowerShell 7 remains a
delivery gate rather than an unresolved local code finding.

## Definition of Done

- [x] All acceptance criteria and cross-host delivery gates completed.
- [x] Mandatory test code and scenario ownership complete.
- [x] Local focused, structural, native-compatibility, and complete-suite test
      commands and successful results recorded.
- [x] Every subfeature fresh-diff review and the bounded convergence scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory are current.

## Delivery gates

- [x] [Pull request #94](https://github.com/hasanmanzak/meAndAI/pull/94)
      and [issue #93](https://github.com/hasanmanzak/meAndAI/issues/93) cross-link the canonical records.
- [x] Applicable hosted PowerShell 7, Windows, and Ubuntu checks passed before
      merge.

## Post-merge release evidence

[Issue #93](https://github.com/hasanmanzak/meAndAI/issues/93) is the stable
external evidence authority. [Pull request #94](https://github.com/hasanmanzak/meAndAI/pull/94) merged as
[`6de31e0c318666bfa1fb884f2f5a791ecaf0fd3e`](https://github.com/hasanmanzak/meAndAI/commit/6de31e0c318666bfa1fb884f2f5a791ecaf0fd3e) on 2026-07-22. Immutable release
[v0.12.6](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.12.6) targets
that exact commit, and the owned work branch is absent.
