# FEAT-0040 - Batched Instruction-Graph Acquisition and Residual Runtime Reduction

| Field | Value |
| --- | --- |
| Classification | Backward-compatible test/runtime efficiency correction / `TASK-0002` |
| Status | Ready / Gate 1 complete |
| Target version | 0.13.1 |
| Issue and external evidence authority | [#98](https://github.com/hasanmanzak/meAndAI/issues/98) |
| Pull request | `Pending` |
| Decisions | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md), [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md), [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) |
| Tests | [TEST-0161 and TEST-0162](test-cases.md) |

## Problem

Immutable v0.13.0 makes equivalent expensive test setup reusable and blocks
unreviewed operation-count regressions, but it does not reduce every expensive
production-owned boundary. Exact instruction-graph acquisition still starts a
new `git cat-file blob <sha>` process for every parsed blob in both the quick-
adoption and hosted-bootstrap adapters.

The released tree's final pull-request run completed on Ubuntu in 5 minutes 33
seconds and on Windows in 20 minutes 33 seconds. Windows PowerShell 5.1 spent
723.326 seconds in quick adoption, 202.782 seconds in bootstrap, and 130.214
seconds in instruction-graph discovery. Deterministic fixture budgets passed,
so repeated immutable fixture construction no longer explains this residual.
The remaining per-blob process boundary is therefore FEAT-0040's first
candidate correction under `TASK-0002`. The immutable released-tree baseline
is now frozen at 175 blob processes and requests per actor acquisition, with a
candidate maximum of one process and the same 175 requests.

## Outcome

Each quick-adoption or hosted-bootstrap instruction-graph acquisition lazily
opens at most one actor-local, binary-safe `git cat-file --batch` session and
uses it only for exact blob OIDs requested by the unchanged pure graph builder.
Zero requested blobs start no batch process. Successful acquisition proves that
request and byte counts exactly equal the graph's parsed-blob evidence, while
malformed, drifted, over-budget, incomplete, or leaking sessions fail closed.

This is a transport correction, not a graph-policy or migration-authority
change. The graph schema, roots, grammar, roles, digest, limits, mutation
envelope, semantic capability catalog, and consumer ledger remain unchanged.

## Scope

- Bind the exact immutable-v0.13.0 per-blob process/request baseline for the
  production quick-adoption and hosted-bootstrap acquisition actors to a
  strictly lower process-start maximum before implementation, while using a
  separate stable small-fixture route for executable CI enforcement.
- Replace per-blob Git process starts with one lazy serial batch session per
  graph acquisition while retaining the existing `TreeEntries + ReadBlob`
  callback boundary in the pure capabilities module.
- Parse the batch protocol as bytes: one bounded ASCII header, the declared raw
  payload length, and one exact LF trailer. Do not use a text reader for the
  payload.
- Require canonical requested and returned blob OIDs, exact `blob` type,
  canonical decimal length, per-blob and aggregate budgets before allocation,
  payload SHA-1 identity, and request/byte parity with the resulting graph.
- Make the session acquisition-local, lazy, serial, non-reentrant, and closed
  before any later semantic or mutation boundary. Dispose or kill it on every
  success, validation failure, builder failure, malformed response, non-zero
  exit, or cleanup path.
- Apply one 120-second monotonic session deadline, a 128-byte response-header
  ceiling, a 65,536-byte standard-error ceiling, and a 5-second abort/reap
  grace. Request writes, stdout reads, concurrent stderr draining, completion,
  and process wait all consume the same remaining session deadline.
- Keep process I/O inside the two production Git actors. Actor implementations
  may duplicate only the minimum packaging-boundary transport and must have
  executable source/parity drift evidence.
- Extend the existing `test-runtime-efficiency` operation ratchet with the
  measured process-start/request identities without changing the immutable
  capability definition or catalog.
- Preserve Windows PowerShell 5.1, PowerShell 7 on Windows/Linux, the existing
  one-Windows/one-Ubuntu workflow, every active scenario authority, and the
  representative real-Git/security/recovery/native slices.
- Inventory independent test-side exact-graph readers separately. The direct
  readers in quick-adoption, bootstrap graph-identity, and instruction-graph
  fixtures remain independent expected-evidence producers in this first slice;
  their process counts cannot be reported as production batch savings and must
  receive an explicit retained-or-follow-up disposition at closure.

## Non-goals

- A persistent Git service, daemon, cache, prefetcher, cross-acquisition
  session, cross-process state, mutable fixture sharing, hosted fan-out, or
  self-hosted runner.
- Moving process I/O into the pure graph-policy module or changing its callback,
  schema, traversal, digest, limits, projection, or closure semantics.
- Reducing evidence by deleting, renaming, weakening, or mocking an active
  `TEST-NNNN` scenario whose real boundary supplies material behavior.
- Batching unrelated bundle-builder, updater, release, or general Git calls.
- Treating elapsed time as a correctness gate or claiming a wall-clock gain
  from one noisy hosted run.
- Changing initial-adoption write/deletion authority, semantic FullMigration,
  product interpretation, capability-ledger state, or migration catalogs.

## Readiness evidence and contracts

### Released baseline

- Immutable baseline: [v0.13.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.0),
  merge commit `299b8982cd57961e2b3a6136b07af3bfb49a16d1`.
- Exact-tree candidate run:
  [29921546402](https://github.com/hasanmanzak/meAndAI/actions/runs/29921546402),
  head `88005e5b7b0b095044197d2c5513f2cd708faeec`. The merge tree is byte-identical
  to that tested head, and exact-main run
  [29923220827](https://github.com/hasanmanzak/meAndAI/actions/runs/29923220827)
  independently accepted the exact validated-tree reuse route.
- Ubuntu observations: total 5:33; validation 5:22; quick adoption 138.249
  seconds; bootstrap 46.956 seconds; graph 51.241 seconds.
- Windows observations: total 20:33; PowerShell 5.1 validation 20:04; quick
  adoption 723.326 seconds; bootstrap 202.782 seconds; graph 130.214 seconds.
- Every v0.13.0 fixture and operation maximum matched. Elapsed values are
  observations, not pass/fail thresholds.
- Exact released-tree observer
  `meandai.task-0002.instruction-graph-blob-process-observer` schema 1 has digest
  `sha256:1f0471fbe882ce959afe52f65713a4f3332c3ba0bc1616db0c5b256687fcf4a8`.
  It ran from an isolated exact v0.13.0 clone under Windows PowerShell
  5.1.19041.7548 and Git 2.55.0.windows.3; the clone and Trace2 files were
  removed after measurement.
- Quick `Get-QuickAdoptionInstructionGraph` took 52.440 seconds and bootstrap
  `Get-InstructionGraphForCommit` took 49.821 seconds. Each route started
  exactly 176 Git processes: one `ls-tree`, 175 `cat-file blob`, and no other
  Git process. Each produced 175 requests, 175 unique OIDs, 1,332,781 parsed
  bytes, 203 nodes, 1,198 edges, 2 candidates, and graph digest
  `685ad9b3797bc7406459986a4b5f28c771cea6acba8534dfdc891083857d3c99`.
- Both request sequences have digest
  `sha256:5447ffa5a375a0c4c39780668e0e8a069419bf74693b257ee3b9fb32aee2f27e`.
  Production source SHA-256 identities are quick
  `d13a5a45d96a4d0ee1820f0e60f71515dca1b8e521d862dc1d8277e1339da6ae`,
  bootstrap
  `27388f4de4180a4b997488f5d225e0791ccdf09e5490dc22d2a5cc3585e4b06d`,
  and pure policy
  `22faa7ec251e65428ac562dc5dbdf67bbfa4361bc59fd667ba4d52941097283c`.
- The frozen P1 closure target per positive acquisition is blob process starts
  `175 -> 1`, while requests remain exactly 175 and parsed bytes, request
  sequence, counts, and graph digest remain unchanged.

### Session and framing contract

- One session belongs to one repository plus one exact graph acquisition. It
  is not reused across repositories, commits, acquisitions, cases, or actors.
- Lifecycle is `NotStarted -> Running -> Completed`, with any protocol,
  builder, validation, or cleanup fault entering terminal `Faulted/Aborted`.
- The first valid blob request starts the process. A graph that parses zero
  blobs completes with zero process starts and zero requests.
- Requests are exact lowercase 40-hex OIDs followed by LF. Path/revision,
  filter, symlink-following, and all-object modes are forbidden. Git replace
  objects are disabled at the process boundary.
- Each response is `<oid> SP blob SP <size> LF`, exactly `<size>` raw bytes,
  then one LF. Header bytes and length are bounded independently of payload
  limits.
- Each request is encoded as exact 7-bit ASCII OID bytes plus one byte `0x0A`;
  a BOM, CRLF, host newline, locale encoding, or text-writer preamble is
  forbidden. Windows PowerShell 5.1 captures the raw stdin pipe under an
  explicit no-BOM encoding and then restores the ambient console encoding. A
  failure while capturing any redirected stream after process start must kill,
  reap, and dispose that child before surfacing the failure. Request write and
  flush are deadline-bound.
- Returned OID equals the request; size is canonical non-negative decimal;
  per-blob and remaining aggregate limits pass before allocation; the payload's
  Git blob SHA-1 equals the tree OID.
- Missing, ambiguous, wrong-type, wrong-OID, invalid-length, early-EOF,
  missing-trailer, extra-output, non-zero-exit, concurrent/reentrant read, or
  budget overflow permanently faults the session and returns no partial graph.
- Standard error is drained concurrently while stdout is awaited. At most
  65,536 stderr bytes are retained as diagnostic evidence; one additional byte
  may be read only as the bounded overflow sentinel. Overflow faults and aborts
  the session instead of buffering without bound. Process
  start failure, broken stdin, a child that stops producing bytes, and a child
  that does not exit within the common 120-second deadline all fail closed.
- Completion closes stdin, consumes exact stdout EOF, completes bounded stderr
  drain, and reaps the child before disposing streams. Abort calls the
  PowerShell-5-compatible parameterless `Kill()`, waits at most 5 seconds, and
  treats a survivor or unjoined I/O task as cleanup failure. Cleanup failure is
  reported without hiding the primary acquisition failure.
- On success, session request count equals `graph.counts.parsedBlobs` and
  response bytes equal `graph.counts.parsedBlobBytes` before graph acceptance.
- Each actor's private session factory alone may accept an
  `InternalTestHooks` record with exactly `TransportFactory` and
  `GetMonotonicMilliseconds` scriptblocks. No CLI, public actor, graph entry
  point, environment variable, repository content, or consumer configuration
  can supply that record. Production calls omit it and retain literal 120,000
  ms session, 5,000 ms abort, 128-byte header, and 65,536-byte stderr limits.
  Tests use callback transports plus a virtual non-decreasing clock to prove
  exact N/N+1, pending-I/O, start, write, kill, and reap behavior without sleep
  or reduced production limits. Unknown, partial, or non-scriptblock hooks fail
  closed, and the unhooked real-Git route remains mandatory.

### Ownership and compatibility

The pure policy owner remains
`MeAndAI.CapabilitiesBootstrap.psm1`. Quick-adoption
`RepositoryAssessment.ps1` and the hosted
`Invoke-MeAndAICapabilitiesBootstrap.ps1` adapter own their distinct process
and trust boundaries. DEC-0023's bundle packaging may require the same small
private transport in both actor artifacts; executable parity and real-Git graph
identity, rather than a new shared service, prevent drift.

The existing append-only `test-runtime-efficiency` definition and catalog blob
remain immutable. FEAT-0040 is meAndAI's next reviewed conformance correction
under that capability; it is not a third catalog entry and creates no consumer
capability reassessment or deterministic migration.

### Measurement provenance

The repository-local operation budget advances to schema 2 without rewriting
FEAT-0039 evidence. Its single schema-1 `Measurement` becomes the first entry
of an ordered `Measurements` collection. Every entry has exactly `Id`,
`BaseCommit`, and `ObserverDigest`; identities are ordinally ordered and unique.
The first entry is `feat-0039-v0127-fixtures`, whose base commit and observer
digest remain exact. FEAT-0040 appends
`feat-0040-v0130-graph-transport` with the immutable v0.13.0 base and observer digest
`sha256:1f0471fbe882ce959afe52f65713a4f3332c3ba0bc1616db0c5b256687fcf4a8`.
Every closure target requires one exact `MeasurementId`. Existing targets bind
the preserved v0.12.7 identity; new graph targets bind only the v0.13.0
identity. The generic importer rejects missing, unknown, duplicated, or
reordered measurement identity. The canonical test-runtime owner additionally
freezes every target-to-measurement mapping and rejects a valid-known identity
swapped across work. Active route maxima remain current enforcement and do not
silently change either historical baseline.

The exact new observation owner is
`tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1`,
route `default`, with no arguments and one required final observation. It has
exactly these ordinal counters and units:

| Counter | Baseline | Maximum | Unit and inclusion boundary |
| --- | ---: | ---: | --- |
| `instruction-graph.blob-process-start` | 4 | 2 | Aggregate blob-reader process starts for only the quick and hosted positive acquisitions in the existing small real-Git fixture; two parsed blobs per actor, exactly one candidate session per actor |
| `instruction-graph.blob-request` | 4 | 4 | Aggregate requests for the same two acquisitions; exactly two per actor and unchanged by batching |

Both closure targets are instrumented, owned by `SUBF-0078`, and bind
`feat-0040-v0130-graph-transport`. Per-actor assertions require exactly one
process and two requests so the aggregate cannot hide an omitted actor. Tree
acquisition, fixture-setup Git, direct blob smoke reads, the self/HEAD reader,
and every independent expected-evidence reader are excluded. The external
immutable self-repository measurement remains separately authoritative at
`175 -> 1` process and `175 -> 175` requests per actor; its different workload
is never substituted for the stable fixture counter.

### Independent evidence readers

The production correction applies to
`RepositoryAssessment.ps1` and
`Invoke-MeAndAICapabilitiesBootstrap.ps1`. Independent test readers in
`quick-adoption.tests.ps1`,
`capabilities-bootstrap-graph-identity.fixture.ps1`, and
`instruction-graph-discovery.tests.ps1` deliberately do not call the
production reader to calculate expected evidence. TEST-0161 inventories their
direct Git work separately and prevents it from being counted as production
process reduction. If their measured residual is material after SUBF-0078,
SUBF-0079 must either lower it through an independently faithful test boundary
or record a linked successor; it may not make the expected side depend on the
production batch implementation.

### Prior local timing dispositions

Issue #98's earlier local values are observational evidence, not interchangeable
baselines. They receive these explicit dispositions before implementation:

| Observation in issue #98 | Disposition |
| --- | --- |
| Quick `All` 776.2 seconds | Retained as historical FEAT-0039 local evidence. FEAT-0040 compares against the final immutable hosted values, 723.326 seconds on Windows and 138.249 seconds on Ubuntu, and preserves the full security/recovery/TOCTOU/native route. |
| `WindowsNative` 333.1 seconds | Superseded as an unproven transcription: final FEAT-0039 evidence is 341.0 seconds total, including 329.2 seconds in native quick adoption. The compatibility route remains mandatory and outside the operation observer; no elapsed-time claim is made without a same-command immutable rerun. |
| Bootstrap `All` 267.6 seconds | Retained as historical local evidence. The immutable hosted baseline is 202.782 seconds on Windows and 46.956 seconds on Ubuntu; FEAT-0040 changes only the production graph subprocess boundary and preserves init/clone/bundle/push/child evidence. |
| Graph owner 135.9 seconds | Retained as historical local evidence. The immutable hosted baseline is 130.214 seconds on Windows and 51.241 seconds on Ubuntu; independent readers are excluded from production savings and any material residual receives a SUBF-0079 retained-or-successor disposition. |

The issue's earlier exploratory `172` reads / 36.4 seconds and failed
intermediate hosted run `29919821489` are superseded by the exact immutable
observer and final tree-identical run above.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0161 and TEST-0162](test-cases.md) |
| Test code | Expected red complete | TEST-0161 reports exactly six missing batch-contract findings in 146.507 seconds with TEST-0151/0152 intact; TEST-0162 reports 25 schema-2/batch-ratchet findings in 8.3 seconds without parse/null failure; final `StructureOnly` accepts both canonical owners |
| Baseline run | Complete | Exact released hosted/tree timings plus per-actor observer identity, 175 process/request baseline, and process-start maximum 1 are frozen |

### Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0190` | Evidence integrity | Lower process count removes material real-Git, security, recovery, or exact-blob evidence | Test maintainer / preserve scenario authority and evidence-level inventory; retain representative real-Git adapter parity in `TEST-0161` and complete compatibility closure in `TEST-0162` |
| `RISK-0191` | Cross-runtime and process correctness | Batch framing misreads binary bytes, deadlocks, leaks, reorders, buffers stderr without bound, or diverges across PS5/PS7 | Git actor owners / byte framing, exact OID/type/size/hash checks, common deadline, concurrent bounded stderr drain, private virtual-clock/transport seam, fault cleanup, malformed/truncated/non-zero/hung-child variants, and cross-runtime execution |
| `RISK-0192` | Measurement and topology validity | Observer cost, host noise, hidden fan-out, or mixed baseline identity creates a false improvement | Workflow/test-runtime owner / exact release/tree/observer/route identities, deterministic counts as gates, unchanged topology, and elapsed time as observation only |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0078` | Actor-local lazy binary-safe batch transport, exact parity, and operation ratchet | [Issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) | `TEST-0161`; expected red is exactly six actor-contract findings | Framing, lifecycle, budgets, hashing, packaging duplication, and process cleanup review pending | Ready / Gate 1 complete |
| `SUBF-0079` | Cross-runtime, scenario-authority, version, hosted topology, and measured closure | [Issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) | `TEST-0162`; PS5/PS7/Linux/Windows and hosted evidence pending | Full diff and bounded convergence review pending | Proposed / depends on SUBF-0078 |

## Decisions and relationships

- Hosted runner evidence and exact-tree reuse:
  [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md).
- Existing immutable semantic capability:
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md).
- Quick-adoption packaging boundary:
  [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md).
- Exact graph policy/acquisition separation:
  [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md).
- Parent runtime guardrails:
  [FEAT-0039](../FEAT-0039-v0130-test-runtime-efficiency/README.md).
- Tracking and future publication authority:
  [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

No new decision is required for one bounded, per-acquisition transport that
leaves graph semantics and topology unchanged. Cross-process persistence,
shared cache/state, policy-module I/O, or topology change would exceed this
feature and require a new decision.

## Definition of Ready

- [x] Stable `FEAT-0040`, `TASK-0002`, `SUBF-0078`, `SUBF-0079`, and issue #98 identities.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Session, framing, identity, budget, error, cleanup, ownership, and compatibility contracts are explicit.
- [x] Consumers, dependencies, decisions, capability boundary, and risks are identified.
- [x] `RISK-0190` through `RISK-0192` have owners and required evidence.
- [x] Two dependency-ordered reviewable slices and gates are defined.
- [x] `TEST-0161` and `TEST-0162` plus the bounded verification approach are defined.
- [x] Exact v0.13.0 process/request baseline, observer identity, and strictly lower target are frozen.
- [x] Expected-red executable test authority exists and fails only for the missing batch/schema-2 contracts; structural ownership is green.

## Acceptance criteria

1. The exact immutable-v0.13.0 observer binds each selected actor route to 175
   blob process starts and requests; the reviewed candidate maximum is one
   process start with all 175 requests and graph evidence unchanged.
2. The pure graph module, graph schema, limits, serialization, digest, roles,
   projection, and closure semantics remain byte- and behavior-compatible.
3. Each production acquisition starts zero batch processes for zero parsed
   blobs and at most one for one or more parsed blobs; no per-blob production
   `cat-file` process remains on the selected actor paths.
4. Every successful read proves exact request/response OID, blob type,
   canonical size, raw payload length/trailer, Git blob hash, per-blob budget,
   aggregate budget, and graph request/byte parity.
5. Malformed framing, missing objects, wrong identity/type/size/hash,
   truncation, extra output, non-zero exit, reentrancy, builder/validator
   failure, or cleanup failure blocks before any mutation or success evidence
   and leaves no live child process or pipe.
6. Quick and hosted actors produce identical exact tree/graph identity for the
   same real repository while their minimum duplicated transport cannot drift
   silently.
7. Deterministic operation ratchets reject a restored per-blob process, an
   undeclared alternate Git path, a missing observation, or a budget increase
   before canonical success publication.
8. Every active `TEST-NNNN` authority, including `TEST-0151` through
   `TEST-0160`, and every representative security/recovery/TOCTOU/link/native
   evidence slice remains active.
9. Focused PS5 and PS7, Linux and Windows hosted jobs, `WindowsNative`, one Full
   suite, structural validation, and the unchanged one-Windows/one-Ubuntu
   topology pass. Elapsed time is recorded without becoming correctness
   authority.
10. At least one reviewed expensive process-start maximum is strictly lower
    than v0.13.0; any missed wall-clock goal has an explicit owned disposition.

## Verification approach

1. Freeze the released-tree process/request measurement and observer identity.
2. Register `TEST-0161`/`TEST-0162`, add focused batch-lifecycle and operation-
   ratchet tests, and record one expected-red run before production changes.
3. Implement and review `SUBF-0078`; run its focused owner once after the
   planned red and once after remediation.
4. Implement `SUBF-0079`; run focused PS5/PS7, adapter parity, version,
   `StructureOnly`, and `WindowsNative` gates.
5. Run one Windows PowerShell 5.1 Full suite, one fresh-diff review, the single
   bounded post-development convergence scan, and the existing hosted topology.
6. Validation budget: one baseline measurement, one planned-red focused run,
   one focused green per slice, one complete local suite, one convergence scan,
   and at most one confirmation after any blocking remediation.

## Self-review

Planning review confirms that the selected correction stays in the two Git
actors, retains DEC-0024's pure-policy separation, does not append or rewrite a
semantic capability, and does not introduce the cache/service/fan-out patterns
excluded by issue #98. The first `StructureOnly` run produced exactly the
planned `TEST-0161` and `TEST-0162` missing-authority findings and no unrelated
problem. Independent review required exact route/counter units, a bounded
deadline test seam, replace-object coverage, and explicit issue-timing
dispositions; the contracts above resolve those planning findings without
changing production authority. Focused expected-red runs now bind both new
canonical scenarios, and final `StructureOnly` is green. Implementation review
is pending.

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory test code and scenario mapping complete.
- [ ] Test commands and successful results recorded.
- [ ] Per-slice self-review and bounded convergence scan complete.
- [ ] No unresolved `Blocking` finding; residuals have explicit disposition.
- [ ] Documentation, version, links, changelog, and project memory current.
- [ ] Pull request, applicable hosted checks, and pre-merge review gates complete.

## Post-merge release evidence

[Issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) is the stable
external authority. Pull request, converged push, hosted checks, merge, owned-
branch cleanup, release identifier, immutable target commit, assets, and post-
publication verification remain `Pending` until those facts exist.
