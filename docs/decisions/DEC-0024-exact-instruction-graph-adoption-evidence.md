# DEC-0024 - Use Exact Instruction-Graph Discovery and Fail-Closed Completion Coverage

- Classification: Decision
- Status: Accepted
- Date: 2026-07-21
- Decision owners: meAndAI maintainers and adopting repository maintainers
- Related feature: [FEAT-0037](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/README.md)
- Tracking and post-publication authority: [Issue #93](https://github.com/hasanmanzak/meAndAI/issues/93)
- Disposition evidence: [accepted by the maintainer on 2026-07-21](https://github.com/hasanmanzak/meAndAI/issues/93#issuecomment-5033653638)
- Related decisions: [DEC-0013](DEC-0013-trusted-adoption-and-recoverable-evidence.md), [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md), [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md), and [DEC-0023](DEC-0023-verified-quick-adoption-module-bundle.md)
- Narrow supersession: supersedes [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md) only where its fixed known-surface inventory limits instruction-authority discovery; maintainer-owned strategy selection, semantic-mutation boundaries, and compatibility rules remain authoritative
- Current-schema evolution: [DEC-0031](DEC-0031-instruction-graph-schema-2-bounded-compatibility.md) narrowly supersedes this decision's schema-1 per-blob ceiling and protected-extension vocabulary for current releases; this record remains the immutable schema-1 rationale

## Context

[DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md) intentionally chose a small, inspectable path inventory instead of a
universal semantic parser. That inventory safely identifies known layouts but
cannot discover a consumer's custom memory or governance files merely because
`AGENTS.md` transitively requires them. The semantic prompt tells an agent to
report such authority, but the same missing path is not independently visible
to the completion validator. A model omission can therefore leave legacy live
authority while the bounded change-set contract reports success.

Consumer-specific filenames cannot be added indefinitely to the shared
protocol. A functioning consumer AI must instead enter through one or more
standard instruction roots, and those roots provide repository-relative
evidence from which a deterministic graph can be learned. Discovery evidence
still must not become semantic meaning or mutation authorization.

The existing capability framework already supplies the correct ownership
boundary: one immutable pure-policy module shared by launcher and workflow
adapters, with semantic changes remaining consumer-owned and reviewed. The
deterministic migration catalog deliberately cannot perform this semantic work.

## Decision

### One shared exact-base graph contract

Initial-adoption strategy assessment and completion closure use one versioned
instruction-graph contract owned by the immutable capabilities bootstrap policy
module. The quick launcher and workflow adapter acquire exact Git tree/blob
evidence at their respective trust boundaries and call that same contract.
They do not implement, mirror, or cross-validate another parser.

The graph input is one exact captured base commit. Worktree content, model
output, network responses, moving refs, and checkout-filtered text are not
committed-state authority. Each inspected repository node binds its exact path,
mode, type, blob SHA, scope, deterministic role, and sorted discovery reasons.
Roots, directed edges, known-surface compatibility candidates, derived protocol
surfaces, and release-owned limits are canonical ordinal collections.

The graph digest is lowercase SHA-256 over a schema-versioned, length-prefixed
UTF-8 representation of the base, limits, roots, nodes, edges, candidates, and
derived surface projection. The representation is independent of host culture,
PowerShell JSON behavior, newline convention, and worktree filters.

### Roots, references, and compatibility candidates

Instruction roots are every tracked `AGENTS.md` at every depth plus the
declared generic instruction roots: root `CLAUDE.md`, `GEMINI.md`,
`PROTOCOL.md`, `.cursorrules`,
`.windsurfrules`, `.github/copilot-instructions.md`, and supported entries below
`.github/instructions/`, `.cursor/rules/`, and `.windsurf/rules/`. Reserved
integration authority remains evidence without dereferencing a protocol
gitlink.

The graph schema also contains the complete current known-surface file/root
predicate as one explicit versioned compatibility seed. This includes
`CONTRIBUTING.md`, flat and `ai/` tracker files, `.ai/protocol/`, `.ai/memory/`,
and the current `docs/features/`, `docs/decisions/`, `docs/findings/`,
`docs/governance/`, `docs/ideas/`, and `docs/agent-prompts/` roots. This seed is
not an independent classifier: it is normalized into the same graph and makes
the graph-derived surface projection a non-regression superset of the current
classifier. A seeded path not reachable from an instruction root is an
unlinked compatibility candidate, not automatically live authority.

One deterministic, non-NLP grammar recognizes supported local Markdown inline
links; full, collapsed, and shortcut reference links; repository path tokens
outside CommonMark-compatible fenced examples; required-reading and authority
declarations; explicit index/catalog/tracker labels; and scoped instruction
relationships. Reference labels are trimmed, whitespace-collapsed, and
lowercased invariantly; conflicting normalized definitions are ambiguous.
Repository path tokens are accepted only in an instruction root or on an
explicit required-reading, authority, or index line. This prevents historical
prose, JSON values, API endpoints, and examples from silently becoming live
authority while retaining root bootstrap discovery.
Within a traversed JSON file that is not itself an instruction root, JSON
string scalars are opaque payload: Markdown syntax, authority wording, and path
tokens inside them produce no graph edge. A JSON file designated as an
instruction root retains the full instruction grammar. An unterminated string
or unescaped control character encountered by the scalar masker fails closed;
the instruction-graph parser does not otherwise validate JSON syntax.
An extensionless flat code-span token additionally requires an explicit
required-reading/order item, an imperative read/load/consult form, or a
colon-form authority/index declaration; ordinary command and finding-ID code
spans are not path evidence.

The following two lowercase extension vocabularies are exact schema-1 policy.
Extension comparison is invariant and case-insensitive; `(none)` means a
regular extensionless target. Adding, removing, or reclassifying an entry
requires a reviewed graph-schema change rather than an implementation-only
parser edit.

- Traversable instruction text: `(none)`, `.md`, `.markdown`, `.txt`, `.rst`,
  `.org`, `.adoc`, `.asciidoc`, `.json`, `.yaml`, `.yml`, `.toml`, `.ini`,
  `.cfg`, `.conf`, `.rules`, `.mdc`.
- Terminal protected source/binary evidence: `.pdf`, `.doc`, `.docx`, `.xls`,
  `.xlsx`, `.ppt`, `.pptx`, `.odt`, `.ods`, `.odp`, `.png`, `.jpg`, `.jpeg`,
  `.gif`, `.webp`, `.bmp`, `.tif`, `.tiff`, `.ico`, `.svg`, `.avif`, `.mp3`,
  `.wav`, `.flac`, `.ogg`, `.m4a`, `.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`,
  `.zip`, `.7z`, `.rar`, `.tar`, `.gz`, `.bz2`, `.xz`, `.zst`, `.exe`,
  `.dll`, `.so`, `.dylib`, `.bin`, `.dat`, `.db`, `.sqlite`, `.sqlite3`,
  `.wasm`, `.class`, `.jar`, `.pdb`, `.ps1`, `.psm1`, `.psd1`, `.sh`,
  `.bash`, `.zsh`, `.fish`, `.bat`, `.cmd`, `.cs`, `.fs`, `.fsx`, `.vb`,
  `.java`, `.kt`, `.kts`, `.c`, `.h`, `.cc`, `.cpp`, `.cxx`, `.hpp`, `.go`,
  `.rs`, `.py`, `.pyi`, `.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs`,
  `.vue`, `.svelte`, `.php`, `.rb`, `.swift`, `.m`, `.mm`, `.scala`, `.clj`,
  `.cljs`, `.ex`, `.exs`, `.erl`, `.hrl`, `.lua`, `.r`, `.dart`, `.sol`,
  `.asm`, `.s`, `.mq5`, `.mqh`, `.ipynb`, `.proto`, `.graphql`, `.gql`,
  `.html`, `.htm`, `.xml`, `.xsd`, `.css`, `.scss`, `.sass`, `.less`, `.tf`,
  `.tfvars`, `.hcl`, `.sln`, `.csproj`, `.fsproj`, `.vbproj`, `.props`,
  `.targets`, `.gradle`, `.csv`, `.tsv`, `.parquet`, `.feather`, `.lock`,
  `.log`.

Every reached regular target in the traversable vocabulary is parsed
transitively with cycle deduplication. An ordinary reference to a protected
format is recorded as terminal `ProtectedNonText` evidence and is never opened.
A protected target used as required reading, authority, or index requires
review. Any reached regular target outside both vocabularies fails closed,
including an ordinary reference, so an unknown custom text format cannot hide
downstream authority. External references are recorded but never fetched.

Missing significant targets, repository escape, invalid UTF-8 instruction
text, unsupported significant special entries, case-insensitive aliases,
NFC-equivalent Unicode aliases, and budget overflow fail closed. Regular modes
`100644` and `100755` may be parsed without losing mode identity. Links,
reparse destinations, gitlinks, trees, and other non-regular entries are not
dereferenced.

No other root-unreachable text is scanned for authority wording. A file that is
neither reachable nor matched by the versioned compatibility seed remains
protected unknown evidence: it is not live authority, does not block freshness,
and cannot be changed or deleted by this feature.

The latest immutable schema-1 policy has inclusive limits of 65,536 inspected tree entries,
4,194,304 UTF-8 bytes across their paths, 512 nodes, 4,096 edges, depth 32,
262,144 bytes for one parsed blob, 4,194,304 aggregate parsed bytes, and 32,768
UTF-8 bytes for the graph-node path inventory. One tree path is also bounded by
the graph-node path limit so a pre-terminator tree record cannot grow without
bound. Reaching a limit is valid; exceeding one blocks before external or
semantic mutation.

The accepted planning draft used a 1,024-edge ceiling. During [SUBF-0070](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/README.md#subf-0070), the
required all-reference traversal over meAndAI's own exact baseline produced
1,108 canonical edges from 318 tree entries and 185 nodes. Retaining 1,024
would therefore violate both transitive traversal and the decision that
meAndAI is an ordinary consumer. Before any schema was released, the first-
schema ceiling was corrected to 2,048 and bound with exact N/N+1 tests.

After `v0.14.2`, the ordinary meAndAI self-consumer graph used 2,039 of those
2,048 edges. The required `v0.14.3` feature, test, memory, and release-evidence
links produced 2,061 canonical edges without changing traversal semantics.
Deleting valid traceability would only postpone the same capacity failure, so
`v0.14.3` raises the release-declared inclusive edge ceiling to 4,096 and keeps
the same fail-closed exact N/N+1 boundary. Older immutable releases retain their
encoded 2,048-edge contract. A graph-aware lifecycle imports and validates the
policy owned by its exact target release; a historical graph-unaware workflow,
which accepts no graph identity, retains the bounded runtime-policy fallback.

The ordinary self-consumer graph later exceeded the original 256-node ceiling
while remaining within every independent surface, edge, depth, and byte bound.
`v0.15.0` therefore raised only the node ceiling to 512 and retained exact
N/N+1 evidence. The corresponding current-decision projection is corrected
here; older immutable releases keep their encoded node ceiling.

At the `v0.15.1` baseline, the ordinary self-consumer graph used 16,015 of the
16,384 path-inventory bytes. The four required `v0.15.2` feature, decision,
test, and memory records, together with their exact owner links, produced
16,883 bytes without changing traversal semantics. Deleting valid traceability
would only defer the same capacity failure, so `v0.15.2` raises only the
release-declared graph-node path inventory and per-path ceiling to 32,768 bytes
and preserves the same exact N/N+1 fail-closed boundary. Older immutable
releases retain their encoded 16,384-byte contract.

### Evidence is not mutation authority

The existing `protocolSurfaces` representation remains only as a graph-derived
compatibility projection for [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md) strategy resolution. It is the union of
reachable graph evidence and the versioned known-surface compatibility seeds,
and must reproduce every current known-surface result. Canonical target
collisions remain separate. Graph membership, reachability, candidate status,
or semantic-capability type does not authorize a write or deletion.

[FEAT-0037](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/README.md) leaves the current initial-adoption mutation envelope unchanged. A
discovered node outside that envelope is evidence-only and protected by its
base blob and mode. If FullMigration, HybridReconciliation, or CleanStart would
require changing or retiring it, the manifest is retained and completion
reports `MEANDAI_ADOPTION_BLOCKED` with exact unresolved paths. CleanStart gains
no new deletion authority merely because the graph found a file.

This decision does not add `semantic-full-migration` to the immutable capability
catalog. That capability may be proposed only when a separately approved
feature supplies its read-only planner and reviewed lifecycle. It also does not
change the capability ledger, deterministic migration catalog, or `MIG-NNNN`
contract.

### Lifecycle identity and completion

New local assessment snapshots and adoption manifests use schema 3. The
transient manifest contains the complete bounded graph. New proposed ownership
markers use schema 7 and publishing/recovery markers use schema 8; smaller
handoffs bind the exact base, graph digest, counts, limits, strategy, surface
projection, repository, target, protocol, actor, branch, and head needed by
their consumer.

Every actor independently recomputes the evidence available at its trust
boundary. Before mutation or proposal reuse, the launcher rebuilds the exact
bound source graph and requires source-digest equality. Before completion
publication it separately builds the candidate final graph and applies
authority closure and protected-tree validation. The hosted adapter repeats
the same committed-tree checks. Final equality with the source graph is not
required: authorized rewrites and retired edges inside the existing mutation
envelope are expected. Publication requires the final instruction roots to
reach canonical new live authority, no required legacy authority to remain,
and every out-of-envelope path to retain its protected blob and mode. Source
identity drift, an unresolved or newly introduced legacy authority, an
unapproved final edge, unsafe entry, protected-content mutation, or required
out-of-envelope retirement blocks without completion push or ready transition.

The full graph and manifest are transient and are removed only after valid
completion. No permanent graph ledger, path compatibility map, redirect, or
second common authority remains in the consumer tree.

The meAndAI repository is itself a consumer of this contract. Its own
[AGENTS.md](../../AGENTS.md), [PROTOCOL.md](../../PROTOCOL.md), project-local memory, and linked records are assessed
through the same roots, graph, limits, and closure rules; repository identity
does not grant an exception.

### Prospective compatibility

Manifest schema 2 and proposal/publishing marker schemas 5/6 retain only the
immutable recovery meaning they already encode. New code does not add graph
policy retroactively. If a graph-aware reassessment discovers authority outside
their exact path inventory, the old proposal requires close-and-reassessment.
Likewise, a current runtime targeting a compatible older protocol release
feature-detects that target workflow's declared inputs and omits the new graph
identity field when it is absent. The immutable older target keeps its own
graph-unaware schema and dispatch contract; runtime and target identity are not
conflated.
Completed consumers remain on the current/update/capability-review route and
are not returned to initial adoption.

## Consequences

- Custom instruction topologies become mechanically visible without adding
  consumer names or memory paths to production allowlists.
- A semantic actor can no longer be the sole detector of omitted authority;
  completion has independent graph and protected-tree evidence.
- The first release deliberately blocks custom semantic migrations that need
  authority beyond the existing envelope. Later planner/executor work may
  expand authority only through separate decisions and tests.
- The graph contract, schemas, cross-host digest, exact-base acquisition, and
  closure checks add implementation and fixture cost across launcher, workflow,
  recovery, and completion boundaries.
- The exact compatibility-candidate universe preserves existing conservative
  strategy behavior without opening arbitrary text or causing deletion or
  silent product reinterpretation.
- Earlier releases, proposals, capability definitions, and completed consumers
  retain their historical contract.

## Alternatives considered

- Add TravelOS, HAnchor, Photolity, or other consumer paths to the allowlist:
  rejected because it couples the shared protocol to consumer naming and still
  misses the next custom topology.
- Rely on the semantic prompt to discover additional authority: rejected
  because model omission remains outside mechanical closure.
- Scan and classify every repository document semantically: rejected because
  it creates a universal AI-memory validator, unpredictable authority, and an
  unbounded input surface.
- Treat every graph node as writable governance: rejected because reachability
  is evidence, not deletion or semantic-mutation authorization.
- Add the graph as a release-declared consumer capability: rejected because
  discovery is lifecycle safety infrastructure rather than a repository
  practice with terminal `Conforming` or `NotApplicable` evidence.
- Reuse `MIG-NNNN`: rejected because the graph does not declare one exact
  deterministic consumer-state transformation.
- Leave the full graph as a permanent consumer ledger: rejected because it
  duplicates live topology and becomes a compatibility mechanism after
  migration.

## Review condition

Review if project-neutral fixtures show that the deterministic grammar cannot
distinguish required instruction evidence without unacceptable false positives,
if real consumer graphs exceed the declared budgets, if Git changes repository
hash or path-normalization semantics, if a later reviewed semantic migration
feature requires a broader plan-bound mutation contract, or if completed-
consumer evidence shows that prospective schema handling is insufficient.
