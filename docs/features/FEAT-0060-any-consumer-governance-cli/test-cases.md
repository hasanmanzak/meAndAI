# FEAT-0060 Test Scenarios

Test implementation: [SUBF-0138](README.md#subf-0138),
[SUBF-0134](README.md#subf-0134), [SUBF-0122](README.md#subf-0122), and
[SUBF-0124](README.md#subf-0124) are fully complete with exact hosted evidence.
Fully closed progress is therefore four of seven (57.1%); three bounded slices
remain open.

## Authorized bounded clean-room catalog

The first compiled C# vertical slice is [SUBF-0138](README.md#subf-0138) and
reuses canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
rather than allocating another numbered scenario. For the explicit
`protocol-authority` profile, a conforming fixture contains `README.md` and
`test-cases.md` in every `FEAT-NNNN-*` directory; a fixture missing either file
produces the deterministic nonconforming result for that canonical rule.

The slice is repository-read-only, provider-free, `CSharpShadow`, and
non-authoritative. Its test first failed to compile because the governance
domain/core types did not exist, then passed the conforming and each
missing-file boundary after the smallest coherent implementation. PowerShell
source was not inspected or translated to design the rule; later differential
work may compare the independently produced results as black-box observations.

The second bounded rule reuses canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005).
It validates the decision-record identity, classification, status, and exact
required sections through the same repository/document indexes as
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004);
it does not allocate a language-specific test identity or a second parser.
The rule is implemented, green after fresh review, exact committed-tree
verified, and exact-head hosted on Ubuntu and Windows.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0194` <a name="test-0194"></a> | [SUBF-0122](README.md#subf-0122) | Construct the closed, versioned governance profile, exact-commit request, policy/catalog, application-policy-pair, evidence-scope, engine-state, and authority-state identities without reading a repository. | Every lexical identity and cross-identity invariant is exact and fail closed; the caller selects one declared profile and exact commit but cannot inject rules, catalog metadata, enforcement, engine state, or authority. Invalid casing, length, schema, digest, release state, commit, or mismatched application/policy identity is rejected before repository access. | Unit / contract / identity / security | `Distinct`; see the exact sibling tuple below. [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) closed application/stage/capability identities remain owned by [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191). | Passing | `tests/dotnet/MeAndAI.Operations.Governance.Tests/MeAndAI.Operations.Governance.Tests.csproj` |
| `TEST-0195` <a name="test-0195"></a> | [SUBF-0124](README.md#subf-0124) and [SUBF-0135](README.md#subf-0135) | Serialize conforming, nonconforming, incomplete, rejected, failed, canceled, redacted, reordered, and cross-platform governance outcomes. | One typed report/process contract preserves canonical rule ownership, independent severity/enforcement, deterministic bytes, redaction, and the distinction between execution outcome and governance verdict. Current canonical violations remain blocking, advisory observations do not fail the verdict, caller downgrade is rejected, and missing canonical metadata yields `incomplete`. | Unit / contract / security | `Distinct`; see the exact sibling tuple below. Existing rule semantics retain their canonical `TEST-*` identities. | Passing | `tests/dotnet/MeAndAI.Operations.Governance.Tests/MeAndAI.Operations.Governance.Tests.csproj` |
| `TEST-0208` <a name="test-0208"></a> | [SUBF-0123](README.md#subf-0123) and [SUBF-0135](README.md#subf-0135) | In fresh anonymous real Git repositories, resolve one closed [TEST-0194](#test-0194) request against an exact commit and packaging-owned compiled policy binding, then verify explicit `protocol-authority` plus canonical `.ai/protocol` gitlink `consumer` profile evidence. | Both variants use one bounded binary-safe Git reader, resolver, parse-once snapshot, and project-neutral fixture family. Exact subject/policy equality or gitlink pin, canonical `.gitmodules`, and exact `VERSION` blob bytes are independently verified. Missing or mismatched observed profile evidence yields a canonical `incomplete` report and exit `2`; malformed caller input is rejected with `64`; acquisition/process/security failure emits no report and exits `70`; cancellation exits `130`. No named repository, automatic profile, public policy-commit input, network/ref acquisition, candidate overlay, mutation, or authority inference exists. | Git / integration / profile / security | `Distinct`; see the exact sibling tuple below. Canonical byte-source precedence remains owned by [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171), while [TEST-0194](#test-0194) owns the repository-independent typed request. | Planned | Future .NET integration tests; authority and consumer variants activate atomically |

[SUBF-0138](README.md#subf-0138) and
[SUBF-0134](README.md#subf-0134) contribute bounded implementation experience
to the request/report design. [SUBF-0122](README.md#subf-0122) now activates
and passes repository-independent [TEST-0194](#test-0194) in the governance
.NET test project. [TEST-0195](#test-0195) now also has executable ownership in
that one project; [TEST-0208](#test-0208) remains the only local canonical
`PlannedDocumentation` scenario.

### [TEST-0194](#test-0194) exact identity matrix

The executable slice covers the contract before any repository adapter is
called:

- both exact profile values and ordinal rejection of unknown or differently
  cased values;
- exact 40-character lowercase commit and 64-character lowercase digest
  acceptance, with null, empty, whitespace-padded, short, long, uppercase, and
  non-ASCII/non-hex rejection;
- one shared ASCII `M.m.rev` parser reused by exact lowercase `vM.m.rev` tags;
  bounded engine version exactly `0.17.0`; catalog schema exactly `1`; and the
  exact instruction-graph profile, including rejection of another lexically
  valid version with the current limits or `0.17.0` with any changed limit;
- the exact two-rule catalog metadata byte serialization and derived digest,
  including rejection of reordered/changed inventory or metadata and an
  unrelated but lexically valid 64-hex digest;
- a public request surface that accepts only profile plus subject commit and
  fixes `exact-commit` plus `repository` without caller-injected policy,
  catalog, rules, enforcement, state, or authority;
- an unreleased bundle with no partial release fields, derived
  `csharp-shadow`, and derived `powershell-authority`; and
- a hypothetical fully matching immutable release binding with `vM.m.rev`,
  engine commit, policy commit, catalog digest, and exact
  `maai-governance.zip` digest,
  deriving `csharp-released-non-authoritative` while every null/partial/mismatch
  combination fails before repository access.

Commit existence, Git object type, authority/consumer evidence, and pin
verification remain exclusively owned by [TEST-0208](#test-0208).

### [TEST-0208](#test-0208) approved implementation and activation contract

The public request continues to contain only the caller-selected profile and
exact subject commit. Packaging passes its already validated clean exact HEAD
to the governance publish only, and the governance assembly records that value
as compile-time metadata. Runtime composition requires exactly one valid
metadata value and parses it through the existing `ExactGitCommitId` owner.
There is no `--policy-commit`, environment fallback, runtime descriptor, cwd
file, ref, range, tag lookup, or network fetch. An ordinary unbound development
build may still execute `--describe-contract`; a syntactically valid exact
validation request against that build fails with no report and exit `70`.

The `protocol-authority` variant requires the exact subject commit to equal the
compiled policy commit, reads root `VERSION` only through that exact commit's
regular Git blob, compares its canonical bytes with the bounded typed version,
and rejects conflicting `.ai/protocol` pin evidence as profile-incomplete. The
`consumer` variant requires a distinct subject, exactly one `160000` canonical
`.ai/protocol` gitlink equal to the compiled policy commit, and one canonical
`.gitmodules` mapping. Because the superproject object database does not
normally contain the submodule commit, the resolver may use only the already
initialized local Git repository at the fixed `.ai/protocol` integration path
as an object provider. It does not require or trust checkout HEAD and reads
`VERSION` from the exact policy commit object, never from worktree bytes.

After a bounded exact subject snapshot exists, absent/uninitialized local
submodule objects, cleanly missing policy objects, wrong equality/pin/mode,
noncanonical `.gitmodules`, or missing/noncanonical/mismatched `VERSION` are
profile evidence gaps and therefore produce the one canonical report with
`incomplete` and exit `2`. A missing or wrong-type subject commit, malformed Git
framing, unsafe repository/admin boundary, process failure, timeout, or byte
limit failure prevents safe acquisition and exits `70` without a report. A
within-limit but invalid `VERSION` is incomplete; a blob that exceeds the
acquisition limit is failed.

Formal activation is indivisible. While this row is `Planned`, committed C#
source contains no `TEST-0208` literal. Only after both profile variants are
green may one commit change this row to `Passing`, move the scenario from
`PlannedDocumentation` to the existing governance `DotNetTestProject` owner,
add the single scenario constant/traits and hosted-route assertion, and extend
both existing workflow filters. No profile receives an earlier formal TEST
identity.

The stable exit ABI is owned by one internal `GovernanceProcessExitCode : int`
enum with semantic members for conforming, nonconforming, incomplete, rejected,
failed, and canceled. The existing mapper and process boundary return the typed
value, and the public CLI casts it once to the operating-system `int` boundary.
Generic domain/result types remain exit-code agnostic. The independent
`--describe-contract` Infrastructure host uses its own success/usage enum and
converts it to `int` only at that process boundary; it does not reuse governance
verdict semantics.
The exact enum-value set is covered by existing [TEST-0195](#test-0195); `32`
is an instruction-graph depth limit, not a governance exit code.

### [TEST-0194](#test-0194) local implementation evidence

Test-first evidence on 2026-07-29:

- The focused `dotnet test` command filtered to `Scenario=TEST-0194` first
  failed to compile in 9.6 seconds with `CS0234` / `CS0246` because the exact
  identity, policy, request, and bundle types did not exist.
- After implementation and independent review corrections, the same focused
  command passed 69/69 in 7.5 seconds. The corrections prevent public candidate
  selection, reject `consumer` on both the current candidate-only CLI
  preflight and the internal candidate evaluator before repository access, and
  keep the two profiles mapped to the same catalog rule objects without
  activating consumer repository evidence.
- Hosted-route regression [FIND-0370](README.md#find-0370) then failed with
  `Expected: 2`, `Actual: 0` because the Ubuntu and Windows C# workflow filters
  did not select this scenario. After extending only those two existing
  filters, the focused command passed 70/70. Exact committed-tree
  [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) then caught
  sibling scenario literals in the first regression assertion; it was narrowed
  to verify only its owned identity across the same two filter lines.
- The final local full-solution run passed governance 132/132, architecture
  31/31, and packaging 17/17 after moving canonical catalog metadata
  serialization and digest derivation behind the catalog owner.
- Locked restore and format verification passed. The first PowerShell 7
  `StructureOnly` run found only the new memory-log heading's unlinked
  subfeature identity; after linking the whole identity to its canonical
  record, PowerShell 7 and Windows PowerShell 5.1 passed in 189.1 and 274.3
  seconds.
- Framework-dependent publish produced DLL/JSON/PDB output without an apphost.
  Running that published DLL on the real repository exited `0` with
  `conforming`, the exact catalog digest, two evaluated rules, zero findings,
  `csharp-shadow`, and `powershell-authority`.
- One Domain-owned lowercase-ASCII-hex matcher serves both exact commit and
  digest identities. Packaging references Domain and reuses those identities;
  rule descriptors own catalog metadata once, while one typed bounded contract
  owns version `0.17.0` and derives its exact release tag.
- Exact committed-tree reruns on
  [`603823e`](https://github.com/hasanmanzak/meAndAI/commit/603823e5e6521e009d6b50e77d602b812ea1da6d)
  passed the focused 70/70 identity suite, the full 132/132 governance,
  31/31 architecture, and 17/17 packaging suites, locked restore, format,
  both supported `StructureOnly` runtimes, and the repository-only
  publication-evidence owner.
- The same exact head passed hosted
  [run `30419091904`](https://github.com/hasanmanzak/meAndAI/actions/runs/30419091904):
  Ubuntu completed in 13 min 33 s and Windows in 25 min 54 s. Both existing
  C# routes explicitly selected [TEST-0194](#test-0194) and passed 70/70
  governance, 31/31 architecture, and 17/17 packaging tests; the supported
  PowerShell routes also passed.

This proves only repository-independent typed construction and fail-closed
cross-identity validation. It does not prove commit existence or Git object
type, consumer pin/profile evidence, exact-commit CLI acquisition, ZIP
qualification/publication, or an actual released engine. The matching release
test constructs a hypothetical all-or-nothing binding; PowerShell remains the
authority. Exact committed-tree and hosted closure are complete for this
repository-independent contract. Exact Git/profile evidence and package
qualification remain separate later gates.

### [TEST-0195](#test-0195) exact hosted closure evidence

[SUBF-0124](README.md#subf-0124) preserves one engine-to-report path:

- one typed report factory and one exit-code mapper serve conforming,
  nonconforming, and incomplete results;
- `incomplete` is a successful operation result carrying a report, not a
  dependency failure;
- exits `0`, `1`, and `2` emit only the canonical deterministic JSON report on
  stdout;
- rejected, dependency/internal failure, and cancellation exits `64`, `70`,
  and `130` emit only fixed redacted stderr and no JSON report;
- findings retain canonical rule/scenario ownership, severity, enforcement,
  safe repository-relative location/line/anchor, and a typed `content-object`
  or `snapshot` evidence scope plus digest without snippets, host data,
  commands, or secrets; and
- engine/authority state remains typed `csharp-shadow` /
  `powershell-authority`; production manifest/ZIP provenance, bundle
  resolution, and any released-engine claim remain owned by
  [SUBF-0137](README.md#subf-0137).

Canonical scenario owner is the normative repository-relative
`test-cases.md#anchor` address, not a PowerShell suite or C# class path. The
single catalog rule identity owns that value and includes it in canonical
metadata/digest bytes. Since `0.17.0` is not released, this slice may finalize
the schema-`1` catalog identity only by atomically updating and rerunning the
exact [TEST-0194](#test-0194) assertions; a second owner lookup is forbidden.

Test-first and local verification evidence on 2026-07-29:

- The focused command first failed to compile in 11.2 seconds with `CS0246`
  because `GovernanceReportFactory` and `GovernanceRuleEvaluation` did not
  exist.
- One factory now owns canonical evaluation matching, finding ordering,
  evaluated/missing/unmapped counts, verdict selection, typed engine/authority
  state, and construction of the existing report model. The engine only runs
  rules; the existing serializer remains the sole byte writer.
- Findings hold the exact catalog identity rather than copied rule/scenario/
  severity/enforcement scalars. A shared rule helper produces typed safe
  locations and exact typed `content-object` / `snapshot` evidence digests.
  Canonical owner is
  part of the schema-`1` metadata bytes, changing the unreleased catalog digest
  to `000caecc4c5cd941da8b0ab06386cc1a88c294117f69f685245b6bc29af9fc6f`;
  the exact [TEST-0194](#test-0194) assertions changed atomically.
- Changed metadata, missing evaluation, and a finding attached to another rule
  all yield `incomplete` with explicit missing/unmapped counts; their untrusted
  findings cannot enter the report. Every member of a duplicate/contradictory
  evaluation group is also excluded, so input order cannot change findings or
  report digest. Blocking remains nonconforming and advisory-only ready
  evaluation remains conforming.
- One exit mapper owns `0` / `1` / `2` / `64` / `70` / `130`. The governance
  process boundary emits one canonical JSON report only for succeeded
  conforming/nonconforming/incomplete results, emits only fixed redacted stderr
  for every other outcome, and converts an unexpected programming failure to
  fixed exit `70` without changing the shared operation boundary. A
  pre-canceled token exits `130` without invoking the operation.
- The later maintainer-approved typed-ABI refinement first failed only with
  `CS0103` / `CS0246` for the absent `GovernanceProcessExitCode`. The mapper and
  process boundary now return semantic enum members, the public CLI performs
  the single `int` conversion, and one ABI assertion fixes the exact six-value
  set. Focused [TEST-0195](#test-0195) passed 26/26; the distinct host-enum
  expected-red failed only with `CS0246` and then passed 1/1. The complete
  solution passed Governance 156/156, Packaging 33/33, and Architecture 47/47; format
  verification passed. No workflow, scenario owner, generic descriptor result,
  PowerShell route, consumer, package, or authority state changed.
- Focused development checkpoints passed 8/8, 14/14, and 16/16 before atomic
  route activation. Independent fresh review then closed typed identity,
  duplicate-order, evidence-scope, positive location, and cancellation gaps;
  invalid identity, total-order, and late-cancellation edges; the final focused
  suite passed 25/25. The full solution passed governance 155/155,
  architecture 31/31, and packaging 17/17.
- Locked restore and format verification passed. Exact committed-tree
  PowerShell 7 / Windows PowerShell 5.1 `StructureOnly` passed in 203.6 /
  284.7 seconds, with protocol-governance elapsed times of 201.5 / 282.3
  seconds. Earlier candidate observations of 183.2 / 275.4 seconds remain
  historical development evidence only.
- Framework-dependent publish produced no apphost. The published governance
  DLL validated the real repository at exit `0` with `conforming`, two
  evaluated rules, zero findings, `bounded-catalog`, `csharp-shadow`, and
  `powershell-authority`.
- The same-owner hosted-route regression extends only the two existing C#
  filters and matches its own exact pipe-delimited token. No job, matrix,
  PowerShell route, package route, consumer behavior, or authority changes.

Exact implementation head
[`885ab84`](https://github.com/hasanmanzak/meAndAI/commit/885ab84faa965d052167a48dd2f52facbcaf8d99)
has tree-equivalent hosted evidence from
[run `30424139722`](https://github.com/hasanmanzak/meAndAI/actions/runs/30424139722),
which tested merge commit
[`9582a4a`](https://github.com/hasanmanzak/meAndAI/commit/9582a4aabb67dfcf9adf291a7eb2b781cf8c4a04).
The PR head and tested merge commit resolve to the same exact Git tree, so this
is exact-tree-equivalent
hosted implementation evidence rather than a claim that checkout executed the
head commit object directly. Ubuntu completed in 8 min 37 s and Windows in 33
min 52 s. Both hosted C#
filters explicitly selected [TEST-0195](#test-0195); exact-head trait inventory
and filtered log results reconcile 25 selected, executed, and passed cases with
zero failed or skipped. Each platform passed governance 95/95, architecture
31/31, and packaging 17/17. The Windows PowerShell 5.1 step took 32 min 28 s;
all elapsed values are observations, not thresholds. Exact Git acquisition and
both repository profiles remain owned by [TEST-0208](#test-0208), which follows
this closed report/process gate.

Closure-record head
[`8cb4fa4`](https://github.com/hasanmanzak/meAndAI/commit/8cb4fa4549ef8ccd3f3eb59ded531012e79e89fa)
then passed the C# and package gates in hosted
[run `30427450155`](https://github.com/hasanmanzak/meAndAI/actions/runs/30427450155)
but failed Ubuntu only at [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178).
[FIND-0371](README.md#find-0371) removes six human-facing repetitions of the
non-commit Git tree-object identity while preserving the two exact commit
permalinks and their proven tree equality. The focused repository-only
[TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
owner is the bounded correction gate; no executable behavior changed.
Exact correction head
[`2a70b64a7b34abfc440f4af65e2067cdee6adcc3`](https://github.com/hasanmanzak/meAndAI/commit/2a70b64a7b34abfc440f4af65e2067cdee6adcc3)
passed candidate/exact-tree repository-only [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
in 65.3 / 66.3 seconds and hosted
[run `30429072869`](https://github.com/hasanmanzak/meAndAI/actions/runs/30429072869)
on Ubuntu in 13 min 05 s and Windows in 33 min 19 s. The correction gate is
complete.

## Distinct-intent review

| Scenario | Nearest same-contract sibling | Contract difference | Risk difference | Evidence-level difference | Exercised-boundary difference |
| --- | --- | --- | --- | --- | --- |
| Request/identity scenario | [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191) and [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192) | Owns the governance-specific exact profile, request, policy/catalog, application-policy-pair, evidence, engine, and authority identities; the foundation scenarios retain generic application/stage/capability identities and operation-result boundaries. | Prevents caller-injected policy, catalog, enforcement, or authority and invalid cross-identity combinations before any repository access. | Pure compiled unit/contract evidence without Git or filesystem state. | Construction and rejection of the closed governance request vocabulary. |
| Exact profile-evidence scenario | [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) and [TEST-0194](#test-0194) | Owns engine verification of an already typed request against exact repository/profile evidence; byte-source precedence and typed request construction remain with their existing owners. | Prevents named-repository, automatic-profile, drifting-commit, unsupported-adapter, or pin/policy authority inference. | Real anonymous Git integration over project-neutral authority and canonical-gitlink consumer fixtures. | Exact-commit acquisition and profile resolution around, not inside, the canonical byte resolver or request types. |
| Report-envelope scenario | [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192) | Owns the governance finding/report/process envelope; the foundation scenario owns closed operation results and port failures. | Prevents a false green, nondeterministic/redaction-unsafe report, or collapsed verdict/outcome state. | Byte-deterministic compiled serialization and security evidence. | Public governance report boundary after canonical rule evaluation. |

The relationship for all three rows is `Distinct` under
[DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md).
Porting an existing rule or snapshot behavior to C# does not allocate another
numbered scenario; the existing identity is cited by the differential ledger.

Canonical [TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196)
and its distinct-intent review moved to
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md). This link
is navigation only; this feature no longer declares that scenario.

## Evidence

### [SUBF-0134](README.md#subf-0134) shared-kernel exact-head closure

[SUBF-0134](README.md#subf-0134) test-first evidence on 2026-07-29:

- The focused governance test command first exited `1` with `CS0234` and
  `CS0246` because the `Analysis` namespace and `GovernanceAnalysisContext`
  were absent. The first combined
  [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
  / [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
  implementation passed 53/53.
- Fresh review and independent re-review produced and resolved
  [FIND-0368](README.md#find-0368): fenced and HTML-comment structure is
  excluded, fence/comment state is isolated, only indexed numbered decisions
  are parsed, invalid UTF-8 has bounded fail-closed behavior, reports bind exact
  `evaluatedRuleIds` with `coverage=bounded-catalog`, and decision
  symlink/dangling cases fail closed. The final focused suite passed 62/62.
- The full solution passed governance 62/62, architecture 31/31, and packaging
  17/17. Locked restore and format verification are green.
- Framework-dependent publish succeeded without an apphost. The published DLL
  validated the real repository as `conforming` with two evaluated rules, zero
  findings, and `bounded-catalog` coverage.
- Exact final head
  [`492ca9f`](https://github.com/hasanmanzak/meAndAI/commit/492ca9fa8ac5c43b1a3497b871ddc9061a5dc110)
  passed hosted [run `30410251192`](https://github.com/hasanmanzak/meAndAI/actions/runs/30410251192)
  on Ubuntu and Windows, including the C# build/test/package/reuse gates and
  the supported PowerShell validation routes.

This is executable evidence for canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
and regression evidence for canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
through the shared analysis context. Exact committed-tree and hosted closure
are green for that historical shared-kernel checkpoint. At that checkpoint,
the later [SUBF-0122](README.md#subf-0122) slice was to activate
[TEST-0194](#test-0194), while [TEST-0195](#test-0195) and
[TEST-0208](#test-0208) still remained `Planned`.

### [SUBF-0138](README.md#subf-0138) exact-head closure

[SUBF-0138](README.md#subf-0138) local test-first evidence, from the repository
root on 2026-07-28:

- `dotnet test tests/dotnet/MeAndAI.Operations.Governance.Tests/MeAndAI.Operations.Governance.Tests.csproj --no-restore --configuration Release`
  first failed to compile in 7.9 seconds because the new domain/core types were
  absent. The same command first passed 12/12 in 6.1 seconds after production
  implementation. Fresh review then added wrong-case filename and fail-closed
  root, feature-directory, required-file, exact `docs` / `docs/features`
  dangling/non-directory link, and drive-relative `C:outside` cases; the final
  focused command passed 28/28 in 5.5 seconds.
- `dotnet test tests/dotnet/MeAndAI.Operations.Architecture.Tests/MeAndAI.Operations.Architecture.Tests.csproj --configuration Release --no-restore`
  passed 31/31 in 4.7 seconds after correcting one expected dependency-order
  assertion to the canonical solution order.
- `dotnet restore MeAndAI.Operations.slnx --locked-mode` passed in 2.5 seconds.
- `dotnet test MeAndAI.Operations.slnx --configuration Release --no-restore`
  finally passed governance 28/28, architecture 31/31, and packaging 17/17 in
  6.4 seconds. Report contracts distinguish
  `evidenceDigest` from `catalogMetadataDigest`, declare
  `coverage=bounded-first-slice`, and centralize repository-relative finding
  paths.
- `dotnet format MeAndAI.Operations.slnx --verify-no-changes --no-restore`
  passed in 14.1 seconds.
- The first PowerShell 7 `tests/protocol.tests.ps1 -StructureOnly` run exposed
  15 canonical
  [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  link defects only in the new records. After canonical-target corrections,
  final PowerShell 7 and Windows PowerShell 5.1 `StructureOnly` passed in
  159.3 and 236.9 seconds.
- `dotnet publish src/MeAndAI.Operations.Governance/MeAndAI.Operations.Governance.csproj --configuration Release --no-restore --output .codex-tmp/feat0060-first-slice/publish`
  passed in 2.5 seconds and produced the portable framework-dependent output
  without an apphost.
- `dotnet .codex-tmp/feat0060-first-slice/publish/MeAndAI.Operations.Governance.dll validate --repository . --profile protocol-authority`
  completed in 0.5 seconds with exit `0`, `conforming`, one evaluated rule,
  zero findings, `csharp-shadow`, `powershell-authority`, deterministic digest,
  and no absolute path in the report.

This evidence completes the canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
C# vertical slice with exact-head hosted proof. The shared-kernel checkpoint
above adds canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
evidence but did not itself close exact-commit request/profile verification. At
that checkpoint [TEST-0194](#test-0194), [TEST-0195](#test-0195), and
[TEST-0208](#test-0208) remained `Planned`; the later
[SUBF-0122](README.md#subf-0122) slice activates only [TEST-0194](#test-0194).
Exact head
[`393aaa561d0133aba7522083617564e1dca76fe2`](https://github.com/hasanmanzak/meAndAI/commit/393aaa561d0133aba7522083617564e1dca76fe2)
passed hosted [run `30394623671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30394623671)
on Ubuntu and Windows. Exact-commit package behavior remains pending. The historical
[differential-ledger inventory](differential-ledger-analysis.md),
[rule/profile matrix](rule-profile-matrix-analysis.md), and
[accepted v1 decision packet](contract-decision-packet.md) refine later
equivalence boundaries without claiming executable completion. The accepted pre-change baseline is exact-head
[run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744),
exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671),
and post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375).
The final pre-slice exact head
[`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186)
passed [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016)
on Ubuntu and Windows.
