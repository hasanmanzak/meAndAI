# [FEAT-0060](README.md) Definition-of-Ready Analysis

> **Historical-input boundary (2026-07-29):** This analysis is retained as
> [FEAT-0060](README.md) planning and audit input. Under
> [DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md),
> full `candidate` snapshot support, remaining governance coverage, and
> equivalence qualification belong to
> [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md), not the
> bounded [FEAT-0060](README.md) release completion boundary.

Status: [SUBF-0138](README.md#subf-0138) bounded first clean-room
`CSharpShadow` vertical slice locally complete; exact-commit/hosted and
full-feature equivalence, authority, and retirement gates remain open.

This record freezes the current evidence boundary. The maintainer authorized
only the first specification-first slice on 2026-07-28. It is not implementation
evidence, a workflow change, authority transfer, consumer mutation, or
PowerShell retirement authorization.

## Specification-first sequencing amendment

[DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
defines the canonical protocol, decisions, feature contracts, and numbered
scenarios as the C# design authority. Project memory remains supporting context
and recurrence routing. PowerShell source is not translated or treated as a
design specification; only after independent C# implementation may its result
be observed as a legacy black-box oracle.

Therefore the exhaustive differential ledger and variant-level matrix are not
Definition-of-Ready prerequisites for a bounded read-only `CSharpShadow` slice
or an explicitly non-authoritative portable package. They remain mandatory
before an equivalence or stronger-evidence claim, required-check enforcement,
authority transfer, compatibility retirement, or PowerShell source retirement.

The authorized first slice is [SUBF-0138](README.md#subf-0138) and reuses canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
under the explicit `protocol-authority` profile. It reads feature directories,
requires `README.md` and `test-cases.md`, emits only a non-authoritative typed
result, and registers no provider or mutation port. Its C# test first failed to
compile before the domain/core types existed, then passed after the smallest
coherent implementation.

## Audited starting point

The immutable baseline is protocol `0.16.0` at
[`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
At that baseline:

- `tests/protocol.tests.ps1 -ExecutionProfile Full` discovers 23 executable
  PowerShell suite owners and 180 executable scenario identities.
- [tests/scenario-ownership.psd1](../../../tests/scenario-ownership.psd1)
  contains 206 identities: 180
  `ExecutableSuite`, three `DotNetTestProject`, four
  `GitHubActionsSemantic`, one `ExternalPostPublication`, 13
  `PlannedDocumentation`, and five `HistoricalSuperseded`.
- The 188 active, non-planning identities remain canonical. This feature does
  not renumber them merely because a second-language implementation is
  planned.
- The direct protocol-governance suite owns 37 identities, but the feature
  also intersects instruction-graph, repository-evidence, capability, marker,
  workflow, release, publication, and scenario-authority owners. The direct
  suite is therefore not the complete migration inventory.

Representative high-relevance owners are:

| Owner | Approximate size | Canonical identities | Relevance |
| --- | ---: | ---: | --- |
| [tests/capabilities/protocol-governance/protocol-governance.tests.ps1](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1) | 6,382 lines | 37 | Direct local protocol-governance rules |
| [tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1](../../../tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1) | 5,569 lines | 3 | Exact-tree graph discovery, bounds, and transport |
| [tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) | 2,445 lines | 7 | Local mock publication contracts |
| [tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1](../../../tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1) | 4,037 lines | 1 | One supplied release/issue/pull-request evidence set |

These counts are the exact historical scenario-level audit baseline, not a C#
design source or a completeness claim for concrete variants. The
[differential-ledger inventory](differential-ledger-analysis.md) accounts for
188/188 active identities and seven explicit declaration packets, proves at
least 116 TEST/case mappings separately from the base identities, and records
why the global inline/generative variant denominator is not encoded today.
Every material variant still needs a finite disposition before equivalence or
authority can move; that work does not block the authorized first slice. Larger mutation-heavy adoption and
update suites are intentionally not presented as size-ranked governance
owners; their pure-validation and operational variants still require explicit
ledger dispositions.

## Rule-family inventory

The complete scenario-level distribution and profile/evidence-source analysis
is in the [rule/profile matrix](rule-profile-matrix-analysis.md).

| Family | Current authority surface | Intended profile | Transfer boundary |
| --- | --- | --- | --- |
| Record grammar, indexes, IDs, and lifecycle | Direct governance, idea-incubation, and recurrence suites | Common grammar; exact meAndAI inventory only in `protocol-authority` | Port technology-neutral models and rules. Do not project meAndAI history into consumers. |
| Authority, protocol pin, and non-duplication | Direct governance and protocol integration evidence | Both profiles | Port read-only authority validation. Adoption/update mutation remains with [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md) and [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md). |
| Markdown links, stable IDs, and anchors | Direct local governance and publication fixtures | Both profiles | One pure reference engine; filesystem and provider data are separate adapters. |
| Scenario authority and test topology | Root runner, authority manifest, architecture and recurrence suites | Mainly `protocol-authority` | Port manifest uniqueness and evidence semantics. Retain PowerShell AST/runner mechanics as legacy infrastructure until [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md). |
| Instruction graph | Bootstrap, quick-adoption assessment, and instruction-graph suites | Both profiles | Port schema, discovery, bounds, digest, and path safety. Replace PowerShell child-process mechanics with an equivalent C# boundary; do not clone the mechanism. |
| Capability catalog and ledger | Capability catalog/review and consumer-migration owners | Consumer; authority publication surface where applicable | Port pure schema, prefix, digest, and byte-identity validation. Keep mutation/rollback variants in [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md). |
| Marker families and bound identity | Updater, bootstrap, quick-adoption, and capability-review actors | Consumer | Create one typed read-only marker registry. Keep cleanup, rewrite, repair, and publication mutation outside this CLI. |
| Workflow and hosted routing | Governance, Windows profile, workflow-efficiency, and finalization owners | Profile-dependent | Port event, permission, and route policy; keep `actionlint` bounded. Do not turn PS5.1/7 sharding or performance mechanics into consumer rules. |
| Release and publication | Local release/package contracts, publication fixtures, and external verifier | Repository phase is profile-dependent | Reuse the C# package contract and keep local immutable-content validation separate from live provider state. |

Known ownership debt must be handled explicitly rather than hidden by the
port:

- the direct suite hard-codes meAndAI required paths and historical releases;
- local and live Markdown parsing have separate implementations;
- marker parsing is distributed across updater, bootstrap, quick-adoption, and
  capability-review actors;
- current PowerShell findings are strings rather than a typed diagnostic
  schema; and
- several scenarios mix pure validation with mutation or recovery.

## Accepted v1 request and snapshot contract

The v1 request is repository-only and carries closed, versioned identities:

- `GovernanceProfileId`: exactly `protocol-authority` or `consumer`;
- `RepositorySnapshotMode`: `exact-commit` or `candidate`;
- `ProtocolPolicyIdentity`: exact release/tag, source commit, rule-catalog
  schema/digest, and instruction-graph schema/limits; and
- `EnginePolicyBundleIdentity`: exact engine source commit, policy source
  commit, catalog digest, and application artifact digest, plus immutable
  release identity when released; and
- `EvidenceScope`: exactly `repository` for this feature boundary.

The subject repository snapshot and engine/policy bundle are independent
identities. v1 supports only an exact application/policy pair and makes no
semantic-version-range compatibility claim. A clean unreleased exact-source
bundle may inspect a real consumer only through an explicit, read-only,
non-authoritative `CSharpShadow` run. It cannot become a managed integration or
required check, replace PowerShell authority, perform adoption/update, or
authorize mutation. Only an immutable release manifest may qualify a bundle as
`CSharpReleasedNonAuthoritative` or make it eligible for persistent managed
consumer use. Release alone does not grant blocking authority; required-check
enforcement and authority transfer remain owned by
[FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md). A
consumer pin must match the manifest's exact policy commit. A subject candidate
that changes released-policy-owning files is `incomplete` under that released
bundle and requires a separately bound candidate shadow bundle.

The caller selects a profile but cannot supply arbitrary rules, capabilities,
authority state, or a replacement catalog. The engine verifies the selection
from canonical repository evidence. `auto`, repository-name allowlists, and
named-consumer exceptions are forbidden.

| Profile | Required evidence | Fail-closed cases |
| --- | --- | --- |
| `protocol-authority` | Subject and exact policy source are the same canonical authority; one authority descriptor; no external protocol integration pin | Missing/duplicate authority, consumer pin, or conflicting self/consumer evidence |
| `consumer` | Subject is distinct; exactly one supported integration authority pins the exact protocol policy commit | Zero/multiple pins, unknown adapter, pin/policy mismatch, or protected-authority ambiguity |

Operational permissions and rule applicability are separate types. The first
repository-only composition may use `RepositoryRead`; it registers no mutation
port and no provider port. A caller cannot narrow or widen
`GovernanceRuleCapabilityId` applicability.

The repository snapshot extends the existing canonical
[TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171)
contract without creating a second behavioral identity:

| Candidate state | Canonical bytes |
| --- | --- |
| Clean tracked path | Exact `HEAD` blob |
| Staged-only path | Stage-zero index blob |
| Unstaged or untracked regular path | Exact worktree bytes |
| Staged plus unstaged, conflict, deletion, rename/copy, ignored ambiguity, link/reparse point, or non-regular entry | Fail closed; no snapshot |

Paths are canonical repository-relative `/` paths. Bytes are not newline- or
encoding-normalized and links are not dereferenced. Each item records mode,
type, Git object ID when applicable, byte length, and SHA-256. HEAD, index, and
worktree overlays are checked before and after capture; drift invalidates the
snapshot. Machine paths, user names, host names, and timestamps are excluded
from the public identity.

Instruction-graph evidence remains exact-commit evidence under
[DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md).
A graph-relevant candidate change may produce only an `incomplete` provisional
result and requires committed-HEAD validation before it can become authority
evidence.

## Accepted report and process contract

The public output is a dedicated, deterministic
`GovernanceReportEnvelopeV1`, not raw `OperationResult<T>` serialization. It
contains:

- schema, application, stage, profile, snapshot, and policy identities;
- `conforming`, `nonconforming`, or `incomplete` verdict;
- C# engine state and current authoritative engine;
- evaluated, missing, and unmapped rule counts;
- ordinally sorted findings; and
- a report digest over the canonical payload.

Each finding contains stable rule ID, canonical scenario identity and owner,
finding code, canonical severity, canonical enforcement, repository-relative location, safe
line/anchor, and content/object digest. It contains no file snippet, provider
body, exception, command line, stdout/stderr, environment value, absolute
path, or credential material. The accepted
[v1 decision packet](contract-decision-packet.md) fixes the severity and
enforcement vocabularies, caller non-downgrade rule, digest scope, and exit-code
map. Missing canonical severity or enforcement yields `incomplete`; advisory
observations do not make an otherwise conforming report nonconforming.

Process and report meanings stay distinct:

| Situation | Operation result | Report verdict |
| --- | --- | --- |
| Validation completed and no violation exists | Succeeded | `conforming` |
| Validation completed and blocking violations exist | Succeeded | `nonconforming` |
| Validation completed with advisory observations only | Succeeded | `conforming` |
| Required profile/policy/evidence is unavailable | Succeeded | `incomplete` |
| Malformed command or schema | Rejected / `input.malformed` | No report or fixed rejected envelope |
| Undeclared port requested | Rejected / `capability.denied` | No report or fixed rejected envelope |
| Git or filesystem dependency fails | Failed / `dependency.failed` | No authoritative verdict |
| Cancellation | Canceled / `operation.canceled` | No authoritative verdict |
| Unexpected programming exception | Fixed redacted internal-error result | No authoritative verdict |

JSON is one UTF-8-without-BOM object with explicit property order, ordinally
sorted collections, and one LF terminator. Culture, operating-system path
separator, elapsed duration, and timestamp cannot change its bytes.

## Live provider boundary

General enumeration and validation of all open/closed GitHub issues, pull
requests, and their comment content is intentionally not added here. The
maintainer reserved that governance feature for a separate discussion.

The existing external verifier remains authoritative for one supplied
release, issue, pull request, their relevant comments/reviews, and exact commit
evidence. A future provider phase, if separately authorized, must consume a
captured `ProviderEvidenceSnapshot`; missing required provider evidence yields
`incomplete`, never a local green result. Tokens, headers, and raw API payloads
cannot enter the public model.

## Differential authority ledger

[The inventory analysis](differential-ledger-analysis.md) accounts for all 188
active canonical identities, all seven explicit `ParameterizedVariant`
declaration packets, and 195 declaration-level units. It proves 107 named
source cases and 116 TEST/case mappings. The base identities and mappings are
separate facts; adding them would be valid only if the accepted schema retains
a base row beside expanded mappings. No central machine-readable source
currently assigns stable keys or cardinalities to every inline/generative
variant, so a complete row count or denominator cannot yet be claimed.

[TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196)
will own the finite authority-transfer
ledger after material-variant normalization. The ledger is populated
incrementally after specification-first rule slices; it does not gate bounded
implementation or an explicitly non-authoritative package. Each evidenced row
has exactly one disposition:

- `CSharpSameContract`;
- `ApprovedStrongerEvidence`;
- `PowerShellOperationalRetained`;
- `InfrastructureContract`; or
- reasoned `NotApplicable`.

Every row records canonical scenario and evidence owners, profile, snapshot
source, rule/finding identity, expected oracle, separate PowerShell/C#
observations, evidence link, and applicable operational-authority state.
`plannedRoute` is separate from `evidencedDisposition`; at the first-slice
authorization checkpoint the latter is empty. Only rows participating in governance
operational-capability migration receive `operationalAuthorityState`, and
applicable current rows retain `PowerShellAuthority`. Infrastructure, provider,
workflow-semantic, and existing-foundation rows preserve their canonical
evidence owners without a fabricated PowerShell authority state. Missing,
duplicate, divergent, or unproved stronger rows fail equivalence,
required-check, authority-transfer, and retirement gates closed. They do not
turn a bounded shadow slice into PowerShell translation work. A language port
does not create a new numbered scenario by itself.

Scenario-level planned routes are complete and mutually exclusive: 43 C#
candidates, 16 mixed boundaries, 94 retained PowerShell operations, 29
infrastructure contracts, three external-provider identities, and three
existing C# foundation identities. The 172 unambiguous routes are 91.5% of the
base universe; the 16 mixed routes are the remaining 8.5% and require accepted
variant keys.

Authority progression is bounded:

1. specification-first development slices emit `CSharpShadow` only and may
   proceed before exhaustive ledger completion;
2. a qualified immutable package may emit
   `CSharpReleasedNonAuthoritative`;
3. PowerShell remains the authoritative result engine throughout this feature;
4. only [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md)
   may authorize consumer cutover or PowerShell retirement.

This feature cannot emit `CSharpPrimaryWithRecovery` or `CSharpOnly`.

## Refined delivery slices

The original milestones are refined into eight independently reviewable
subfeatures. Existing canonical scenarios are reused where the behavioral
identity is unchanged.

| ID | Independently testable boundary | Evidence owner | Status |
| --- | --- | --- | --- |
| [SUBF-0122](README.md#subf-0122) | Versioned governance policy, profile, request, and authority-state identities | [TEST-0194](test-cases.md#test-0194) | In progress; bounded internal building blocks through [SUBF-0138](README.md#subf-0138), but [TEST-0194](test-cases.md#test-0194) remains `Planned` |
| [SUBF-0123](README.md#subf-0123) | Exact Git/index/worktree snapshot and repository-only profile-resolution CLI vertical slice | Existing [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) contract plus [TEST-0194](test-cases.md#test-0194) | In progress; candidate snapshot only through [SUBF-0138](README.md#subf-0138), while [TEST-0194](test-cases.md#test-0194) remains `Planned` |
| [SUBF-0124](README.md#subf-0124) | Versioned rule catalog, typed finding, deterministic report, and process/exit contract | [TEST-0195](test-cases.md#test-0195) | In progress; bounded internal building blocks through [SUBF-0138](README.md#subf-0138), but [TEST-0195](test-cases.md#test-0195) remains `Planned` |
| [SUBF-0134](README.md#subf-0134) | Common pure governance kernel and `protocol-authority` self-consumer profile | Canonical rule slices plus planned [TEST-0195](test-cases.md#test-0195) | In progress; first rule proven by [SUBF-0138](README.md#subf-0138), broader scenario not active |
| [SUBF-0135](README.md#subf-0135) | Project-neutral `consumer` profile and pinned-integration fixture | Canonical mapped scenarios plus [TEST-0194](test-cases.md#test-0194) / [TEST-0195](test-cases.md#test-0195) | Proposed; separate later gate |
| [SUBF-0136](../FEAT-0064-governance-coverage-equivalence/README.md#subf-0136) | Same-snapshot PowerShell/C# variant ledger and fail-closed differential harness | [TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196) | Mandatory before equivalence, authority transfer, or retirement |
| [SUBF-0137](README.md#subf-0137) | Immutable portable-package qualification at non-authoritative state | Existing [TEST-0193](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193) plus applicable focused C# tests | Proposed; separate later gate |
| [SUBF-0138](README.md#subf-0138) | Clean-room canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) vertical slice: `protocol-authority` candidate snapshot, feature-record pair rule, deterministic report/exit, thin CLI, and read-only adapter | Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) | Locally complete; exact-commit/hosted pending, PowerShell authority unchanged |

[SUBF-0138](README.md#subf-0138) uses a separate governance-core class
library, thin console, and repository-read-only filesystem adapter. Its focused
test first failed to compile in 7.9 seconds because the production governance
types were absent, then passed 12/12 in 6.1 seconds. Fresh-review boundary
corrections expanded the final focused suite to 28/28 in 5.5 seconds. The final
full-solution rerun passed governance 28/28, architecture 31/31, and packaging
17/17 in 6.4 seconds. Locked restore, format verification, and portable publish
also passed.
The published DLL validated the real repository in 0.5 seconds with exit `0`,
`conforming`, one evaluated rule, zero findings, `csharp-shadow`,
`powershell-authority`, deterministic digest, and no absolute path. This
reviewed result uses distinct `evidenceDigest` and `catalogMetadataDigest`
fields, declares `coverage=bounded-first-slice`, and centralizes
repository-relative finding-path validation. It
completes the canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
C# slice. [TEST-0194](test-cases.md#test-0194) and
[TEST-0195](test-cases.md#test-0195) remain `PlannedDocumentation` and are not
activated by this slice.

Each subfeature closes its own expected-red, focused green, self-review,
finding disposition, documentation, and exact committed-tree gate before the
next slice begins. No PowerShell path is disabled after an individual slice.

## Baseline and recurrence evidence

No new full baseline run is required while `main`, the mapping source, and the
snapshot contract remain unchanged:

- exact-head [run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744)
  passed 48/48 compiled tests and full Ubuntu/Windows governance at
  [`74055eb7357176c681b665783391a131186b5375`](https://github.com/hasanmanzak/meAndAI/commit/74055eb7357176c681b665783391a131186b5375);
- exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671)
  reused the exact tree and passed StructureOnly on Ubuntu and Windows; and
- post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375)
  verified immutable `v0.16.0` at the exact merge commit; and
- exact-head [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016)
  passed the final pre-slice branch head
  [`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186)
  on Ubuntu in 12 min 58 s and Windows in 32 min 12 s, including a
  30 min 46 s PowerShell 5.1 step, and closes [FIND-0365](README.md#find-0365)
  and [FIND-0366](README.md#find-0366).

Observed baseline durations are diagnostic only: Ubuntu governance was about
115 seconds plus 124 seconds for instruction graph; Windows PowerShell 5.1 was
about 200 seconds plus 211 seconds. They are not correctness thresholds.

Applicable recurrence barriers are:

- a planning packet is not self-consumer evidence until committed into exact
  HEAD and checked in both supported PowerShell runtimes;
- any helper/process/workflow ownership change must atomically preserve the
  canonical helper inventory;
- exact target graph/marker policy remains target-owned;
- structured Windows transport is UTF-8 without BOM and lossless JSON;
- restricted-sandbox Git signal-pipe failures use the documented bounded
  execution route rather than repeated broad retries; and
- all human-facing commit evidence uses full exact commit permalinks.

Sibling-intent boundaries under
[DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md):

- The first C# slice implements the existing behavioral identity
  [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004).
  Compiled C# evidence is a language implementation of that contract, not a
  new scenario or a validator of the PowerShell test.
- [TEST-0194](test-cases.md#test-0194) owns explicit compiled profile/request
  resolution, while graph discovery and repository byte-source precedence
  retain their canonical identities.
- [TEST-0195](test-cases.md#test-0195) owns only the typed
  finding/report/process envelope. It does not restate missing, duplicate,
  link, or semantic rule behavior.
- [TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196)
  owns cross-language scenario/variant
  authority disposition, while runtime-efficiency evidence remains with its
  existing owner.

## Remaining Definition-of-Ready gates

The bounded first clean-room slice has completed all ten readiness items:

- [x] Stable feature/slice identity, linked issue, dependency, and target
  `0.17.0`.
- [x] Problem, outcome, scope, non-goals, and measurable first-slice outcome.
- [x] Affected feature-packet concept, governance CLI entry point, existing C#
  foundation dependency, and meAndAI self-consumer.
- [x] Read-only capability, type, ownership, lifecycle, deterministic result,
  failure, and compatibility contracts.
- [x] Owned risks and accepted [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) /
  [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
  boundaries.
- [x] Independently reviewable subfeature and first vertical-slice
  decomposition.
- [x] Canonical [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
  positive and missing-file behavior with expected-red then focused-green
  implementation.
- [x] Active recurrence and same-contract sibling review, preserving the
  existing scenario identity.
- [x] Canonical specification ownership, memory-as-context boundary, and
  PowerShell-only-as-later-black-box-oracle route.
- [x] Explicit maintainer authorization on 2026-07-28 for only this bounded
  `protocol-authority` `CSharpShadow` slice.

First-slice readiness is 10/10 (100%). [SUBF-0138](README.md#subf-0138) is
locally complete, so feature implementation is one of eight subfeatures
(12.5%); exact-commit/hosted closure and the other seven subfeatures remain.
Later rule slices retain their own review gates and authorization.

The historical inventory remains 188/188 base identities (100%), 7/7 explicit
declaration packets (100%), 116 proven TEST/case mappings, and 172/188
unambiguous scenario routes (91.5%), with 16/188 mixed (8.5%). The complete
material-variant ledger and rule/profile/evidence-source matrix are explicitly
deferred from this slice's Definition of Ready, not waived. They must be
complete before equivalence or stronger-evidence claims, required-check
enforcement, authority transfer, compatibility retirement, or PowerShell
source retirement. A duration estimate for those later gates begins only when
fresh normalization timing exists; the earlier audit duration cannot be
reconstructed honestly.
