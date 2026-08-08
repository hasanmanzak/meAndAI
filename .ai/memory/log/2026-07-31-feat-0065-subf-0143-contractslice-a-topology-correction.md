# 2026-07-31 - [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) ContractSlice A topology correction

## Status

The accepted [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
Gate 2 packet remains the architecture baseline. Its first ContractSlice A
behavior oracle was found non-executable because A prohibited executable export
construction and C-owned six-list registrations while requiring
`CatalogSliceKernel.Activate` to reach a missing-registration path.

The maintainer approved the corrected topology and the durable
[Gate 3 directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228):

- A owns canonical manifest parse/digest/typed projection, public 48-type shape,
  declaration/artifact/component and manifest `27/35` closure, predecessor/
  transition/schema-DAG behavior, factory/value semantics, and the exact friend
  and negative public surface;
- A constructs no executable export, calls no activation-proof overload,
  declares no `CatalogSliceKernel`, and validates no typed registration list;
- first executable export activation and all six-list registration/type-token/
  public-projection mismatch oracles belong to C; and
- B, C, D, workflow/scenario-owner/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) activation, hosted publication,
  consumer mutation, release, authority transfer, and PowerShell retirement
  remain held.

The append-only
[BehaviorRed evidence clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
keeps the same test, marker, filter, counters, and implementation authority. The
sole failed result must contain exactly one byte-exact marker message. The
marker may occur nowhere else except at most one byte-identical
`ResultSummary/Output/StdOut` or `StdErr` adapter echo. Reviewed source plus the
immutable xUnit `2.9.3` lock proves the direct `Assert.Fail` exception type; TRX
does not serialize it. The run observed before this clarification is diagnostic
only and must not authorize green.

The later append-only
[RunInfo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
permits zero or one `ResultSummary/RunInfos/RunInfo`. If present, it is the exact
marker-free, same-FQN locked-xUnit `[FAIL]` bookkeeping shape with
`outcome="Error"`, exact attributes/child grammar, the sole Failed result,
Failed summary, all 16 counters including `error=0`, and no other diagnostic or
attachment. [FIND-0440](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0440)
records this correction. The run that exposed the missing classification is
also diagnostic and cannot authorize green.

## Exact first A behavior

After the reviewed project/reference/lock scaffold, predecessor total-equality
ownership transition, exact `CatalogVersion` SurfaceRed, and complete structural
A compile green, the first behavior test is:

```text
MeAndAI.Protocol.Conformance.Tests.ContractSliceAManifestTests.Parses_minimal_canonical_qualification_manifest
```

Its exact marker/TRX filename is
`TEST-0210-A-BEHAVIOR-RED-0001`. The only temporary production body is
`FinalizedPolicyManifest.ParseCanonical(...) => null!`; only a returned null
manifest emits the marker. Exceptions propagate, and wrong non-null projection
or digest assertions are marker-free. The fixture bytes and green projection
are normative in the corrected typed-evaluation-kernel design.

`ParseCanonical` is Abstractions-owned and rejects malformed/noncanonical bytes
with `FormatException`. It cannot throw downstream Conformance's
`CatalogIntegrityException`; it copies at entry, seals digest/projections, and
discards raw bytes. `ManifestInvalid` is reserved for a later sealed-manifest/
envelope identity conflict, while valid parsed metadata versus actual loaded
artifacts is `ArtifactMismatch`. An empty qualification slice and empty registry arrays are valid
only when the declaration graph is closed and the required proof component,
artifact mapping, and positive cache budget remain present.

Schema 1 admits at most `16,777,216` bytes, JSON depth `64`, and `1,000,000`
tokens; the length ceiling is checked before the copy and the other ceilings are
checked while parsing. All document-local rule/slot/profile/transition/schema/
producer/projector/component/artifact closure defects are `FormatException`.
This is the explicit
[FIND-0439](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0439)
resolution.
Only predecessor-trusted snapshot or loaded executable/export knowledge may
later produce `CatalogIncomplete`. Every component must be reachable from a
declared role except the four exact runtime anchors; arbitrary unused components
and unmapped/unused artifacts fail parsing. `sourceCommit` and fragment metadata
are grammatically sealed by the parser, while real commit/blob/content proof
belongs to the trusted qualification/release envelope.

## Canonical first A BehaviorRed

After authoritative packet synchronization, the exact one-invocation A command
used a newly created, initially empty external directory and one TRX logger. It
exited nonzero and produced exactly one TRX at
`D:\Temp\meandai-test-0210-a-canonical-54b33df16d7446be918f0a3cb75d3c28\TEST-0210-A-BEHAVIOR-RED-0001.trx`.
The sole mapped result is Failed for
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAManifestTests.Parses_minimal_canonical_qualification_manifest`.
Its one normalized `ErrorInfo/Message` equals
`TEST-0210-A-BEHAVIOR-RED-0001`; one byte-identical `StdOut` echo is present.
The one marker-free `RunInfo` has only the allowed
`computerName`/`outcome`/`timestamp` attributes, `outcome="Error"`, and one
same-FQN `[FAIL]` Text child. `ResultSummary` is Failed, and the counters are
exactly `total=1`, `executed=1`, `passed=0`, `failed=1`, `error=0`,
`timeout=0`, `aborted=0`, `inconclusive=0`, `passedButRunAborted=0`,
`notRunnable=0`, `notExecuted=0`, `disconnected=0`, `warning=0`, `completed=0`,
`inProgress=0`, and `pending=0`. The standard failed-result assertion stack is
marker-free, and there is no independent diagnostic or attachment. IDs,
machine, timestamps, durations, indentation, absolute paths, and stack line
numbers are recorded non-oracles.

This post-synchronization run is the canonical first A BehaviorRed. Every run
observed before its applicable clarification remains diagnostic and cannot
satisfy a successor increment. [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remained `Planned`; at this red checkpoint `ParseCanonical` still had only the
reviewed `null!` sentinel.

## First limited ParseCanonical green

The sentinel was replaced by the first limited ParseCanonical implementation.
The Release `--no-restore` production build completed with zero warnings and
zero errors. With the original red oracle unchanged, the exact same FQN passed
`1/1` at
`D:\Temp\meandai-test-0210-a-green-91b9a19a6db741c6af2e5bac3a1a22b0\TEST-0210-A-GREEN-0001.trx`.
The transient marker constant and null-only `Assert.Fail` branch were then
removed, and canonical equality was moved before digest/object construction.
Format verification and the final six-project Release build passed with zero
warnings and zero errors. The final-source exact FQN passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-62a34655387e4306b0bc26c9203fb97d\TEST-0210-A-GREEN-FINAL-0001.trx`,
and cumulative `ContractSlice=A` passed `12/12`.

The accepted first increment validates the exact 1,222-byte fixture, full typed
projection and ordering, manifest/artifact digests, null `CompleteCatalog`, and
caller-buffer mutation independence. Source review confirms that the 16 MiB
length check precedes the private `ToArray` copy; parsing and hashing use only
private bytes; typed canonical reserialization must equal the private input;
and the manifest retains no raw byte field. The private input copy and writer-
returned reserialization byte array are zeroed in `finally`; the
`ArrayBufferWriter` internal buffer becomes unreachable and is not retained by
the manifest but is not explicitly zeroed. The proven contract is copy-at-entry
and no retained raw bytes, not universal buffer zeroization.
The stable source contains neither the `null!` sentinel nor the transient
marker/null branch.

Final support review closed with `0 Blocking`, one unnumbered remaining-A
coverage `Important`, and no unresolved `Minor`. The current
`CanonicalManifestWriter` uses `UnsafeRelaxedJsonEscaping`, which is exact for
the reviewed ASCII 1,222-byte fixture but is not proof of raw printable-Unicode
preservation, lowercase control escaping, or malformed-Unicode boundaries.
Those cases require a separately reviewed exact FQN, marker, fixture matrix, and
absent-behavior predicate before their next red-to-green sequence and before A
completion. This is a known next-red constraint, not a defect or numbered
finding in the accepted first increment. The ordering Minor is closed by the
equality-before-digest/object refactor, and the zeroization wording is corrected
above.

This is only the first limited ContractSlice A behavior increment.
[TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`, every remaining A increment requires its own reviewed
red-to-green sequence, and no held scope is activated.

## Exact predecessor and continuation

[SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
completed through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173) at
exact main
[`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd).
[Run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256)
passed both stable jobs. The implementation branch is
`codex/subf-0143-contract-slice-a-implementation` from that exact baseline.

Bounded correction red-team completed with `0 Blocking`, `0 Important`, and
`0 Minor`; canonical StructureOnly passed in `251.7` seconds. Scaffold and
locked restore, predecessor ownership transfer, exact SurfaceRed, cumulative-A
structural green, and focused ownership/public-API `11/11` are now local
checkpoints. BehaviorRed observations made before their applicable
clarifications are diagnostic. Topology/parser and RunInfo reviews passed with
`0 Blocking`, `0 Important`, and `0 Minor`.
Authoritative packet synchronization, the fresh filtered canonical
BehaviorRed/TRX, and the first limited ParseCanonical green are now complete.
Proceed next with remaining reviewed A increments, focused validation, and
fresh-diff review. Root, StructureOnly, combined, hosted, and owner/workflow
activation remain outside this limited-green checkpoint. B/C/D, WIP extraction,
consumer mutation, release, publication, authority transfer, and PowerShell
retirement remain held. Preserve the user-owned untracked
`MeAndAI.Protocol.v3.ncrunchsolution.user` file unchanged.
