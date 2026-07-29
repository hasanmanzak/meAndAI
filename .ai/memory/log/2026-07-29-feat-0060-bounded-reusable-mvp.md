# 2026-07-29 - [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md) Bounded Reusable Governance MVP

## Current authority and evidence

Development continues on `codex/feat-0060-dor-analysis` under
[issue #155](https://github.com/hasanmanzak/meAndAI/issues/155) and
[draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160).
[SUBF-0138](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0138)
has exact-head hosted evidence: [run `30394623671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30394623671)
passed both Ubuntu and Windows validation. The slice remains a read-only,
provider-free, non-authoritative `CSharpShadow` implementation of canonical
[TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004).
PowerShell remains production and compatibility authority; no workflow route,
consumer repository, required check, or retirement boundary changed.

## Accepted bounded allocation

[DEC-0034](../../../docs/decisions/DEC-0034-bounded-reusable-governance-catalog.md)
allocates the independently releasable `v0.17.0` MVP to
[FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md).
The bounded feature targets exact-commit evaluation, the two recorded
profiles, canonical
[TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004)
and
[TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005),
a deterministic typed catalog and report, and one framework-dependent
`maai-governance.zip`. Candidate-worktree evaluation, the remaining governance
families, exhaustive coverage, and equivalence are outside this release.

Repository and document analysis must be reusable by construction. One
immutable evaluation context reads and parses a repository artifact once;
rules consume its typed indexes instead of owning duplicate scanners, regular
expressions, parsers, snapshots, or catalog projections. Distinct rule classes
remain appropriate only for genuinely distinct invariants and change reasons.

## Follow-up ownership

[FEAT-0064](../../../docs/features/FEAT-0064-governance-coverage-equivalence/README.md)
/ [issue #161](https://github.com/hasanmanzak/meAndAI/issues/161) owns
candidate-worktree support, remaining rule families, complete catalog
qualification, and differential equivalence. Those gates remain fail-closed
for required-check enforcement, authority transfer, compatibility retirement,
or PowerShell source retirement.

## Historical progress checkpoint

At the scope-record correction checkpoint, two of seven
[FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
subfeatures were fully closed, approximately 28.6%.
[SUBF-0134](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0134)
has exact committed-tree evidence at
[`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110):
full solution tests are green, repository-only
[TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
passed in 64.6 seconds, PowerShell 7 / Windows PowerShell 5.1 `StructureOnly`
passed in 178.0 / 253.4 seconds, and hosted
[run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192)
passed Ubuntu and Windows on the exact head. Continuation at that checkpoint
was
[SUBF-0122](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0122)
under repository-independent [TEST-0194](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194).
Exact repository/profile evidence follows later under
[TEST-0208](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0208).
The [SUBF-0122](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0122)
DoR now freezes a public `profile + exact commit` request, shared Domain-owned
commit/digest parsers, an exact `maai-governance.zip` byte digest, and one
all-or-nothing release binding; candidate remains internal/deferred and
PowerShell authority is unchanged.

Keep the typed catalog, engine defaults, and report metadata single-sourced as
the rule set grows. Do not implement
[FEAT-0064](../../../docs/features/FEAT-0064-governance-coverage-equivalence/README.md),
widen authority, mutate a consumer, disable PowerShell, or claim equivalence
as part of this continuation.

## Shared-kernel exact-head checkpoint

[SUBF-0134](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0134)
now implements canonical
[TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005)
through the same parse-once repository/document kernel used by canonical
[TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004).
The expected-red checkpoint failed with compiler diagnostics `CS0234` and
`CS0246`; the first green checkpoint passed 53/53 focused tests.

Fresh self-review and independent re-review under
[FIND-0368](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0368)
covered fenced/HTML-comment structure, fence-state isolation, indexed-only
document parsing, bounded invalid-UTF-8 failure, exact evaluated-rule inventory,
bounded-catalog identity, and decision-document symlink behavior. Final local
evidence is:

- focused governance tests: 62/62;
- full governance tests: 62/62;
- architecture tests: 31/31;
- packaging tests: 17/17;
- locked restore, format verification, and publish: passed; and
- published-DLL execution against the real repository: conforming, two
  evaluated rules, zero findings.

PowerShell remains production and compatibility authority. No workflow route,
consumer repository, required check, or retirement boundary changed.

Hosted [run `30406017573`](https://github.com/hasanmanzak/meAndAI/actions/runs/30406017573)
evaluates exact commit
[`990b634`](https://github.com/hasanmanzak/meAndAI/commit/990b6346c7a1f7455872c2164a54dc7d7fe4223a).
Every C# build/test/package step passed. Both PowerShell `Full` routes failed
only at
[TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
because tracked Markdown contained a short commit target. The correction is
recorded under
[FIND-0369](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0369),
and the focused repository-only owner passes on exact
[`a4231a2`](https://github.com/hasanmanzak/meAndAI/commit/a4231a2d4d6ff1068092c0f7b4c8304aaef5ceb4)
in 64.6 seconds. The final exact-head correction at
[`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110)
passed hosted [run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192)
on Ubuntu and Windows.

## Structural record correction

The first committed scope packet exposed
[FIND-0367](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0367):
the planned-scenario authority still named its former owner, then exact-link
governance found moved and newly repeated identifiers. The owner and links were
corrected without restoring duplicate declarations; PowerShell 7
`StructureOnly` then passed in 184.6 seconds. The correction was committed and
dual-runtime exact-head evidence is counted only from the later successful run.

## [SUBF-0122](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0122) local continuation

The historical handoff above has now advanced through repository-independent
[TEST-0194](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194).
Its focused expected-red failed in 9.6 seconds with `CS0234` / `CS0246`; the
post-review focused suite passes 69/69. The public request accepts only an
explicit profile plus exact 40-lowercase-hex commit and fixes exact-commit /
repository evidence. One Domain matcher owns lowercase-ASCII-hex grammar for
commit and digest identities, packaging reuses those identities, each rule
descriptor owns its metadata once, and one typed bounded contract owns version
`0.17.0` plus the derived release tag.

The catalog maps both typed profiles to the same rule objects, while a distinct
single candidate-eligibility policy rejects `consumer` in both the candidate-
only CLI preflight and the internal candidate evaluator before repository
access. This is not consumer Git evidence: commit existence/object type,
consumer pin/profile verification, exact-commit CLI acquisition, ZIP
qualification/publication, and an actual released engine remain unproved.
At this historical checkpoint PowerShell remained authority, two of seven
subfeatures were fully closed, three were implementation-active, and exact
committed-tree/hosted closure was still pending for
[SUBF-0122](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0122).

The final local full solution passes governance 131/131, architecture 31/31,
and packaging 17/17; locked restore and format verification also pass. The
first PowerShell 7 `StructureOnly` run found only the newly appended heading's
unlinked subfeature identity. After linking the whole identity to its canonical
record, PowerShell 7 and Windows PowerShell 5.1 passed in 189.1 and 274.3
seconds. Framework-dependent publish produced no apphost, and the published
DLL validated the real repository as `conforming` with the exact catalog
digest, two evaluated rules, zero findings, `csharp-shadow`, and
`powershell-authority`. The preceding records-only identity-contract checkpoint
[`7a935a5`](https://github.com/hasanmanzak/meAndAI/commit/7a935a5d8a62b3e49348475962215849f3c4a18b)
passed hosted [run `30414044175`](https://github.com/hasanmanzak/meAndAI/actions/runs/30414044175)
on Ubuntu and Windows; that historical result does not close this later
implementation tree.

## [TEST-0194](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194) and [TEST-0195](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195) closure checkpoint

[SUBF-0122](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0122)
closed on exact implementation head
[`603823e`](https://github.com/hasanmanzak/meAndAI/commit/603823e5e6521e009d6b50e77d602b812ea1da6d)
and hosted [run `30419091904`](https://github.com/hasanmanzak/meAndAI/actions/runs/30419091904).
[SUBF-0124](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0124)
then closed the single typed report/process path without adding another engine,
serializer, report envelope, exit map, parser, or fixture family. Its exact
implementation head
[`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99)
passes 25/25 focused tests and the full solution passes governance 155/155,
architecture 31/31, and packaging 17/17 after fresh review. Locked restore,
format, both exact-tree structural runtimes, framework-dependent publish, and
published-DLL real-repository validation are green.

Hosted [run `30424139722`](https://github.com/hasanmanzak/meAndAI/actions/runs/30424139722)
was associated with that PR head and tested merge commit
[`9582a4a`](https://github.com/hasanmanzak/meAndAI/commit/9582a4aabb67dfcf9adf291a7eb2b781cf8c4a04).
Both objects resolve to the same exact Git tree.
Ubuntu passed in 8 min 37 s and Windows in 33 min 52 s; the Windows PowerShell
5.1 step consumed 32 min 28 s. Both hosted filters explicitly selected
[TEST-0195](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195).
The exact trait inventory plus aggregate hosted results reconcile 25 selected,
executed, and passed cases with zero failed or skipped.

Four of seven bounded subfeatures are now closed, approximately 57.1%. The
commit containing this closure checkpoint must pass the existing Ubuntu and
Windows gates before any later implementation begins. The next implementation
gate is one shared Infrastructure-owned, streaming, binary-safe bounded child-
process/acquisition foundation reused by packaging and later exact Git work.
[TEST-0208](../../../docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0208)
remains `Planned`; its exact profile semantics must be frozen before atomic
activation. PowerShell remains authority.

The first closure-record head
[`8cb4fa4`](https://github.com/hasanmanzak/meAndAI/commit/8cb4fa4549ef8ccd3f3eb59ded531012e79e89fa)
passed its C# and portable-package gates in hosted
[run `30427450155`](https://github.com/hasanmanzak/meAndAI/actions/runs/30427450155),
but Ubuntu failed only the tracked-Markdown commit-reference owner. Six visible
copies of the shared Git tree-object SHA-1 were shaped like commit identities
although the object was not a commit. [FIND-0371](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0371)
removes that non-commit object identifier from human-facing prose while
preserving the exact linked PR-head and tested-merge commits and their proven
tree equality. No executable or authority behavior changes.

Exact correction head
[`2a70b64a7b34abfc440f4af65e2067cdee6adcc3`](https://github.com/hasanmanzak/meAndAI/commit/2a70b64a7b34abfc440f4af65e2067cdee6adcc3)
passed candidate/exact-tree repository-only
[TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
in 65.3 / 66.3 seconds, then passed hosted
[run `30429072869`](https://github.com/hasanmanzak/meAndAI/actions/runs/30429072869):
Ubuntu in 13 min 05 s and Windows in 33 min 19 s, including the 31 min
47 s Windows PowerShell 5.1 full route and exact same-byte package handoff.
The closure-record barrier is complete.

## [SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141) records-only readiness checkpoint

The original immutable `v0.16.0`
[FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
closure remains three of three. Declaring this later support extension makes
current [FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
progress three of four (75%).
[FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
remains four of seven (57.1%) because this is an external prerequisite rather
than an eighth governance subfeature.

The extension, tracked by
[issue #162](https://github.com/hasanmanzak/meAndAI/issues/162), moves the sole
C# child-process owner into Infrastructure, requires direct Packaging adoption,
and leaves later Git/profile interpretation with
[SUBF-0123](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0123).
Existing [TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191),
[TEST-0192](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192),
and [TEST-0193](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193)
identities are extended; no new TEST identity, PowerShell change, consumer
mutation, release publication, or authority transfer is introduced.

## [SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141) tests-first checkpoint

The existing Architecture.Tests assembly now owns the explicit inert child
fixture and the
[TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191) /
[TEST-0192](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
extensions; no project, package, solution node, workflow filter, or new test
identity was added. The focused Release compile for
[TEST-0192](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
with `--no-restore` failed in 11.1 seconds only
with `CS0246` for the absent `BoundedProcessRequest`. No entrypoint collision,
restore/lock problem, warning, or unrelated compiler failure occurred.

[SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141)
is therefore two of five delivery gates complete (40%). The next gate
implements only the Infrastructure kernel: behavioral
[TEST-0192](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
must turn green while the new
[TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191)
single-owner and Packaging dependency assertions remain intentionally red
until direct Packaging adoption removes the prior runner.

## [SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141) kernel-only checkpoint

The internal Infrastructure request, result, and async runner now compile.
All 11 new
[TEST-0192](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
process cases passed in 4 seconds. The complete scenario filter passed 26 of 27
and failed only the deliberately premature Packaging dependency expectation.
The
[TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191)
filter passed 16 of 18 and failed only that dependency plus the exact two-owner
inventory containing the new Infrastructure file and the old Packaging file.

This controlled red is the planned migration barrier. No wrapper, public
process API, package, project, solution node, workflow change, PowerShell
change, or authority transfer was introduced. Overall delivery remains two of
five gates complete (40%) while gate three is in progress; direct async
Packaging adoption and removal of the old owner are next.

## [SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141) local-green checkpoint

Exact local implementation commit
[`389ebf70699ccf55788838772811af14f6cab2f6`](https://github.com/hasanmanzak/meAndAI/commit/389ebf70699ccf55788838772811af14f6cab2f6)
completes direct asynchronous Packaging adoption. The old Packaging runner is
deleted, Infrastructure is the sole production process owner, and the internal
request/result/runner family has no Packaging forwarding wrapper. Executable
source-owner tests fix the direct-consumer inventory at four CLI calls plus one
executor call and keep Packaging JSON parsing and direct UTF-8 decoding
single-owned by `StrictJson` and `StrictUtf8`.

The shared runner now covers exact binary stdin/stdout/stderr, inclusive byte
limits, discrete arguments, environment set/remove isolation, nonzero result,
pre- and in-flight cancellation, huge timeouts, active descendant cleanup,
inherited-pipe EOF, prompt broken-pipe transport failure, fixed redaction, and
bounded cleanup observation. Packaging preserves strict descriptor/runtime
JSON, whitespace-compatible strict UTF-8, exit interpretation, Ctrl+C mapping,
and fail-closed temporary-workspace cleanup with bounded deletion retry.

The final targeted union passed 46 Architecture and 33 Packaging cases
(79/79). The exact clean commit passed the complete solution with 46
Architecture, 33 Packaging, and 155 Governance cases (234/234), locked restore,
and a zero-warning/zero-error Release build in 2.61 seconds. Changed-file
analyzer/format verification passed. Three independent process, Packaging, and
duplication reviews found two recurrence-barrier P1s and four lifecycle/cleanup
P2s; all were corrected, and their bounded re-reviews report no remaining
P0/P1/P2. Candidate-tree StructureOnly then passed all discovered contracts in
186.5 seconds; its protocol-governance owner reported 184,511 ms. The support
extension is four of five gates complete (80%); exact committed-tree protocol
and package evidence plus one consolidated hosted Ubuntu/Windows closure
remain. PowerShell, workflows, consumers, release assets, and operational
authority are unchanged.

## [SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141) exact-local checkpoint

Exact local evidence checkpoint
[`537776966c3f3ac31c4271378456b1073c2dd193`](https://github.com/hasanmanzak/meAndAI/commit/537776966c3f3ac31c4271378456b1073c2dd193)
passed committed-tree StructureOnly in 192.6 seconds. The canonical workflow
CLI built the manifest-bound framework-dependent JIT package set in 15.9
seconds and `--execute` verification validated and ran all three applications
on Windows in 2.7 seconds.

The exact local assets were `maai-adoption.zip` at 95,385 bytes with SHA-256
`645faf79967d9352aa57b3debc1b076c4b93488d0602491d7f95c894b1c444de`,
`maai-consumer-update.zip` at 95,951 bytes with SHA-256
`91a05dbb792e72b830288670c87cd4da4eb7a732bdff0a06ef90aa081bd08561`,
and `maai-governance.zip` at 185,733 bytes with SHA-256
`319fb4431be7bbee52036d1d5cc8875d408accb33344b3077723cd44e88c6609`.
These are local Windows outputs, not a cross-host same-byte claim. Only the
hosted same-byte Ubuntu/Windows handoff, remote evidence, and final hosted
confirmation remain for gate five; the support extension therefore stays at
four of five gates (80%).

## [SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141) hosted closure

Implementation run-time PR head
[`bf62e7969977819438cfd873a7a20a41243a5561`](https://github.com/hasanmanzak/meAndAI/commit/bf62e7969977819438cfd873a7a20a41243a5561)
passed hosted [run `30439984248`](https://github.com/hasanmanzak/meAndAI/actions/runs/30439984248).
The PR head and tested merge commit
[`ae6cc95475f4514fb9e66b42f480acf7170b8083`](https://github.com/hasanmanzak/meAndAI/commit/ae6cc95475f4514fb9e66b42f480acf7170b8083)
resolve to the same exact Git tree; the package manifest was bound to the
tested merge commit.

The [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30439984248/job/90536710360)
passed Governance 95/95, Packaging 33/33, and Architecture 46/46, built and
executed the manifest-bound package set, and uploaded artifact `8719031242` at
382,242 bytes with digest
`96b1cd931dcbfc4fac23eada6b5fbc177ee95ecc3b4f38318a5d023f81fbb387`.
The [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30439984248/job/90536710423)
passed the same C# totals, downloaded that artifact with the identical expected
and observed digest, and verified and executed adoption, consumer update, and
governance from those same bytes. Ubuntu completed in 14 min 17 s and Windows
in 30 min 53 s, including 29 min 31 s in the retained Windows PowerShell 5.1
route. These times are observations, not thresholds.

[SUBF-0141](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0141)
is therefore five of five gates complete (100%), and current
[FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
is four of four subfeatures complete (100%) while its immutable `v0.16.0`
three-of-three release evidence remains unchanged. The external prerequisite
does not change [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md),
which remains four of seven (57.1%). PowerShell, workflows, consumers,
released assets, and operational authority are unchanged.
