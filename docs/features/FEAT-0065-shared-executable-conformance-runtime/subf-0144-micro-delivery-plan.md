# [SUBF-0144](README.md#subf-0144) Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Ordered implementation control plan |
| Status | `FrozenDesignCorrection`; immutable issued-closure carrier custody and staged public-signature-oracle allowlists are corrected without changing public API, packet order, FQNs, markers, or ownership; debt green remains held pending the latest correction head's exact Ubuntu/Windows hosted green |
| Parent design | [Protected policy and self-consumption design](subf-0144-extension-waiver-self-consumption-design.md) |
| Scenario | [TEST-0211](test-cases.md#test-0211) |
| Exact baseline | [`14ad828bcdde5f843cdbf12677b25f19736e5691`](https://github.com/hasanmanzak/meAndAI/commit/14ad828bcdde5f843cdbf12677b25f19736e5691) |

## Invariants

1. [TEST-0210](test-cases.md#test-0210) and ContractSlice A-D are immutable
   predecessor evidence and are never reopened or used as child-test results.
2. One packet owns one canonical expected red, one smallest dependency-closed
   implementation delta, focused green, cumulative [TEST-0211](test-cases.md#test-0211),
   full Conformance and Domain validation, review, records, and a focused local
   commit before its successor starts.
3. A packet may start only after its predecessor is `ReviewedLocalGreen` in a
   separate local commit. No failed or unresolved packet is bypassed.
4. The feature branch is pushed only at a reviewed checkpoint. Pull-request
   merge is never inferred from implementation authority.
5. Every canonical expected-red process uses one exact full-FQN filter, one
   fresh result directory, one TRX logger, the default VSTest connection
   behavior, a `420`-second outer bound, and no discovery, fallback, retry, or
   evidence reuse. A connection-timeout override requires fresh infrastructure
   evidence and a newly reviewed identity. Once the test child starts, that red
   identity is consumed whether accepted or diagnostic.
6. Standard xUnit TRX bookkeeping follows the retained one-result contract:
   exact marker Message, optional one nonempty marker-free StackTrace, optional
   one byte-identical summary echo, optional one exact marker-free same-FQN
   `[FAIL]` RunInfo, exact sixteen counters, and no attachment or independent
   diagnostic.
7. Before convergence, every new test is one direct Fact with no Scenario,
   ContractSlice, alternate trait, Theory, skip, overload, or class trait. The
   convergence packet atomically adds the Scenario trait for
   [TEST-0211](test-cases.md#test-0211) to the
   exact seven-FQN inventory and activates the existing stable workflow route.

## Ordered packet queue

| Packet | Owner and outcome | Canonical expected-red identity | Hard redraw threshold |
| --- | --- | --- | --- |
| `POLICY-SURFACE-FRAMING-01` | Exact public types/factories, versioned frames/golden vectors, API/ownership and negative surface | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicySurfaceTests.Exposes_exact_extension_waiver_debt_and_self_consumption_surface`; compile SurfaceRed solely on missing `ExtensionId` | `6,500` normalized code+test changed lines |
| `EXTENSION-AUTHORITY-01` | Trusted pack/proof binding, immutable Policy export, active/proposed separation | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyExtensionAuthorityTests.Keeps_active_extension_authority_separate_from_candidate_proposal`; marker `PROTECTED-POLICY-AUTHORITY-RED-0001` | `2,500` lines |
| `EXTENSION-EVALUATION-01` | Protocol-owned required-path kind, capability-only applicability/evaluation and findings | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyExtensionEvaluationTests.Evaluates_only_protocol_owned_additive_extension_kinds`; marker `PROTECTED-POLICY-EVALUATION-RED-0002` | `2,500` lines |
| `WAIVER-DISPOSITION-01` | Stable finding identity, authenticated waiver policy/snapshot, expiry and non-waivable behavior | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyWaiverDispositionTests.Applies_exact_waiver_identity_expiry_and_nonwaivable_rules`; marker `PROTECTED-POLICY-WAIVER-RED-0003` | `2,500` lines |
| `DEBT-ENFORCEMENT-01` | Authenticated debt snapshot and exact Audit/Prospective/FullBlocking truth table | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyDebtEnforcementTests.Applies_exact_debt_and_enforcement_precedence`; marker `PROTECTED-POLICY-DEBT-RED-0004` | `2,500` lines |
| `SELF-CONSUMPTION-01` | Predecessor trust, release-neutral overlap fixture with separate predecessor/candidate evidence-set digests, independent fixture and reviewed differential | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicySelfConsumptionTests.Rejects_candidate_only_and_unreviewed_differential_authority`; marker `PROTECTED-POLICY-SELF-CONSUMPTION-RED-0005` | `2,500` lines |
| `PROTECTED-POLICY-CONVERGE-01` | End-to-end matrix plus atomic scenario owner/workflow/API convergence | `MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyConvergenceTests.Evaluates_protected_baseline_extensions_dispositions_and_self_consumption`; marker `PROTECTED-POLICY-CONVERGE-RED-0006` | `2,000` lines |

The aggregate subfeature redraw threshold is `22,000` normalized production plus
test changed lines. Equality passes; first-one-over stops for design review.
The larger surface allowance is subfeature-specific: its dependency-closed
first packet owns `55` distinct public class/interface declarations plus
factories, canonical writers, goldens, API/ownership tests and four bounded
predecessor-presence edits. It does not expand semantic scope or any graph cap;
it prevents an implementation-time redraw caused only by an unrealistically
small serialization/test budget.
These are complexity brakes, not targets, and do not authorize unrelated files.

The final ordinal FQN inventory is exactly the seven names below. Canonical
UTF-8 with LF separators and one terminal LF has SHA-256
`ACD4354E28B3640B3B10E8C8FFD336D95C282EAB1965611038C59D7403B6D024`:

```text
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyConvergenceTests.Evaluates_protected_baseline_extensions_dispositions_and_self_consumption
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyDebtEnforcementTests.Applies_exact_debt_and_enforcement_precedence
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyExtensionAuthorityTests.Keeps_active_extension_authority_separate_from_candidate_proposal
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyExtensionEvaluationTests.Evaluates_only_protocol_owned_additive_extension_kinds
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicySelfConsumptionTests.Rejects_candidate_only_and_unreviewed_differential_authority
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicySurfaceTests.Exposes_exact_extension_waiver_debt_and_self_consumption_surface
MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyWaiverDispositionTests.Applies_exact_waiver_identity_expiry_and_nonwaivable_rules
```

## Packet mutation allowlists

### `POLICY-SURFACE-FRAMING-01`

- add `src/MeAndAI.Protocol.Domain/ProtectedPolicyIdentity.cs`;
- add `src/MeAndAI.Protocol.Conformance.Abstractions/ProtectedPolicy/ExtensionDeclarations.cs`,
  `ExtensionAuthorityContracts.cs`, `ExtensionPolicyPackExport.cs`,
  `ExtensionEvaluationContracts.cs`, `DispositionContracts.cs`, and
  `SelfConsumptionContracts.cs`;
- add `src/MeAndAI.Protocol.Conformance/ProtectedPolicy/ProtectedPolicyContracts.cs`
  and `ProtectedPolicyIntegrityException.cs`;
- add `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicySurfaceTests.cs`
  and modify `ContractSliceAOwnershipTests.cs`,
  `ContractSliceBStructuralTests.cs`, `ContractSliceCStructuralTests.cs`, and
  `ContractSliceDPolicyExportTests.cs` only to replace A's full Domain export
  equality, Domain exact-total `37`, C total `95`, and D totals
  `72/23/37/Policy=1/total=96` with exact
  predecessor-inventory presence assertions; their FQNs, traits, and
  predecessor behavior remain unchanged;
- no Policy implementation or existing source/test mutation.

This packet creates the dependency-closed public data/contract graph, but does
not create the Policy singleton or declare unimplemented public kernel methods.
At its `ReviewedLocalGreen` commit the exact exported totals are Domain `40`,
Conformance.Abstractions `112`, Conformance `35`, Policy `1`, and non-Domain
aggregate `148`. Its packet-local oracle compares the complete ordinal
type/member signature inventory present at that stage, so equal totals cannot
hide an accidental replacement. The only later public additions are already
frozen here: `EXTENSION-AUTHORITY-01` adds `ProtectedExtensionPolicy` and the
implemented `ActivateExtensions` member, reaching Policy `2` / non-Domain
`149`; `DEBT-ENFORCEMENT-01` adds the implemented `EvaluateProtected` member;
`SELF-CONSUMPTION-01` adds the implemented `QualifyCandidate` member.
`PROTECTED-POLICY-CONVERGE-01` reasserts the final Domain `40`,
Conformance.Abstractions `112`, Conformance `35`, Policy `2`, non-Domain `149`
totals and the full design signature inventory. No packet may invent a public
protected-policy type/member outside that exact staged list.

`SelfConsumptionContracts.cs` is limited to runtime/predecessor bindings,
verifier contract, protected outcome identity, and reviewed-difference inputs;
it cannot reference Conformance. `CandidateIndependentQualificationInput`,
`CandidateIndependentQualification`, and `SelfConsumptionQualification`, which
contain `ProtectedPolicyEvaluation`, are owned by Conformance's
`ProtectedPolicyContracts.cs`.

### `EXTENSION-AUTHORITY-01`

- change `src/MeAndAI.Protocol.Conformance/Activation/ConformanceKernel.cs` only
  from `sealed` to `sealed partial`;
- add `src/MeAndAI.Protocol.Conformance/ProtectedPolicy/ExtensionAuthorityCore.cs`
  and `ConformanceKernel.ExtensionAuthority.cs`;
- add `src/MeAndAI.Protocol.Policy/ProtectedPolicy/ProtectedExtensionPolicy.cs`;
- add `src/MeAndAI.Protocol.Policy/Properties/AssemblyInfo.cs` containing only
  the exact `InternalsVisibleTo("MeAndAI.Protocol.Conformance.Tests")` friend;
- add only `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicyExtensionAuthorityTests.cs`;
  modify `ContractSliceAOwnershipTests.cs`, `ContractSliceAPublicApiTests.cs`,
  `ContractSliceBStructuralTests.cs`, `ContractSliceCOwnershipTests.cs`, and
  `ContractSliceDPolicyExportTests.cs` solely to replace their immutable empty-
  Policy-friend expectation with the exact one-row
  `MeAndAI.Protocol.Conformance.Tests` expectation. All five FQNs, traits and
  every other predecessor assertion remain unchanged; no additional friend is
  accepted;
  the predecessor presence guards from the surface packet already permit only
  additive successor exports and still prove the qualification-only predecessor.
  The authority canonical red/green owns all four retained signed-envelope
  verifier algorithms (activation, protected pack, disposition, predecessor),
  immutable public-key custody, forgery/mutation rejection and exact component/
  artifact binding. It also proves the public nonempty activation path remains
  fail-closed without the linked execution-authority and managed-integration
  current-state composition while the
  friend-only project-neutral fixture mints only the trusted canonical-empty
  activation at this stage. The empty snapshot has zero declarations and
  therefore requires no evaluator registration; it proves the complete
  activation/pack trust chain without pulling evaluator behavior forward.
  The same authority test file owns the immutable internal
  `ProjectNeutralProtectedAuthorityFixture`: it validates the four precomputed
  RFC8032 known-answer envelopes, whose dummy digest never authorizes semantic
  payloads, and owns the exact test-only RFC seed. Its activation, disposition
  and predecessor methods accept only their frozen typed payload; its pack
  method accepts the typed pack binding plus the exact activation payload from
  which record/epoch are derived. Each recomputes and signs its exact digest,
  verifies the envelope, and exposes the friend-only binding to later tests.
  It accepts no raw digest, caller key, signer or verifier callback,
  is never modified by later packets, and has no production call site.
  Later waiver/self packets consume the helper and verifier implementations
  unchanged and may not carry an untested placeholder across commits.
  All four concrete verifier implementations and immutable production key
  custody are private/internal Policy-owned types in
  `ProtectedExtensionPolicy.cs`; the singleton constructs and retains them.
  The Policy project retains its current references and never references
  Conformance; the exact new test friend is the sole permitted friend change
  and the ownership oracle rejects any additional Policy friend.
  Conformance's `ExtensionAuthorityCore` only orchestrates the verifier
  contracts supplied through the existing friend boundary. A Conformance- or
  Abstractions-owned concrete verifier, any project/reference mutation, or any
  friend mutation beyond the exact Policy-to-Conformance.Tests row redraws this
  packet.
  Its API oracle requires the exact frozen Policy singleton and implemented
  `ConformanceKernel.ActivateExtensions` signature, Policy total `2`, and
  non-Domain aggregate `149`; a shell or throwing placeholder is forbidden.

### `EXTENSION-EVALUATION-01`

- add `src/MeAndAI.Protocol.Conformance/ProtectedPolicy/ExtensionEvaluationCore.cs`
  and `ConformanceKernel.ExtensionEvaluation.cs`;
- add `src/MeAndAI.Protocol.Policy/ProtectedPolicy/RepositoryPathRequiredExtensionEvaluator.cs`;
- modify only the predecessor Policy export file above to add the frozen
  required-path registration;
- add only `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicyExtensionEvaluationTests.cs`.

This packet first proves the friend-only signed nonempty activation against the
real required-path registration and exact Policy evaluator component identity;
only after that trust chain is green may its canonical red reach the missing
applicability/evaluation outcome. The authority packet's canonical-empty proof
is not promoted into nonempty registration evidence.

### `WAIVER-DISPOSITION-01`

- add `src/MeAndAI.Protocol.Conformance/ProtectedPolicy/WaiverDispositionCore.cs`
  and `ConformanceKernel.WaiverDisposition.cs`;
- add only `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicyWaiverDispositionTests.cs`.

### `DEBT-ENFORCEMENT-01`

- add `src/MeAndAI.Protocol.Conformance/ProtectedPolicy/DebtEnforcementCore.cs`;
  it owns the single deterministic internal `ComputeEvidenceSetDigest`
  production writer. The friend fixture supplies an exact typed expected
  extension evaluation to mint the signed payload; the public wrapper invokes
  the real evaluator once and recomputes with the same writer. Test-side frame
  duplication or a second evaluator invocation is forbidden;
- modify `ProtectedPolicy/WaiverDispositionCore.cs` only to split its existing
  authority validation into exact common authority, waiver, then debt checks:
  common payload/envelope mismatch stays `DispositionAuthorityInvalid`, waiver
  snapshot/row integrity is `WaiverInvalid`, and debt snapshot/trusted-base or
  future-closed-row integrity is `DebtInvalid`. Valid prior waiver behavior and
  its public surface/FQN remain unchanged;
- modify only `ConformanceKernel.WaiverDisposition.cs` for the frozen debt and
  enforcement call path and add the exact implemented `EvaluateProtected`
  public member; neither the earlier waiver packet nor this packet may carry a
  shell or throwing placeholder;
- modify only `Planning/EvaluationAdvanceResult.cs` to add the internal
  `ProtectedEvaluationInput` and the sole internal
  `EvaluationClosure.WithProtectedInput(IRepositoryTree)` replacement seam.
  This packet permits exactly one call site in the project-neutral friend
  fixture and no production call site. The seam binds the exact completed
  repository-tree outcome context proof and returns only the immutable
  replacement issued by the exact planning session;
- modify only the `KernelPlanningSession` state portion of
  `Planning/ApplicabilityPlanningCore.cs` to add
  `ReplaceIssuedEvaluationClosure(source, protectedInput)`. Under the existing
  state lock it requires an issued, carrier-free, neither evaluating nor
  evaluated source; creates a replacement with the same applicability/context
  references, completed-round count, and ordinal acquisition/evaluation
  element references in fresh defensive collections; and atomically swaps it
  into the issued set. Source reuse, a second/concurrent replacement, or a
  second evaluation is `PlanStateInvalid`. No other code in that file may
  change. Ordinary advance results keep a null carrier.
  `WithProtectedInput(null)` is `ArgumentNullException(repositoryTree)`;
  missing/duplicate/non-Complete tree outcomes, null/wrong context proof,
  wrong session and every other custody/state defect are
  `CatalogIntegrityException(PlanStateInvalid)` before replacement;
  `Planning/EvaluationAdvanceCore.cs` is immutable: its existing
  repository-target-resolution index product is not a repository tree, and no
  cast, second parser/index invocation, payload reconstruction, public member,
  or [TEST-0210](test-cases.md#test-0210) behavior change is allowed;
- modify `Evaluation/CompleteCatalogEvaluation.cs` and
  `Evaluation/EvaluationAggregationCore.cs` only to retain/pass the internal
  exact consumed immutable replacement `EvaluationClosure` reference at
  baseline construction; no public member or
  [TEST-0210](test-cases.md#test-0210) behavior changes, and
  `EvaluateProtected` rejects any non-identical closure or
  carrier substitution;
- add only `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicyDebtEnforcementTests.cs`;
  that test owns the friend-only repository-tree/carrier fixture, produces the
  baseline from the exact replacement closure, and proves the ordinary null-
  carrier Audit route is `Indeterminate/ReportOnly` without evaluator
  invocation; a separate test-only Prospective or FullBlocking profile owns
  `Indeterminate/Block`. It also
  proves source/replacement distinction, exact projection identities/order,
  source invalidation, second/concurrent replacement rejection, retry
  stability, one-shot replacement evaluation and evaluated-closure rejection.
  It also proves `enforcementPhase` exactly equals the baseline profile phase.
  The fixture is not
  production activation or acquisition evidence;
- modify `ProtectedPolicySurfaceTests.cs` only to advance the already-frozen
  complete ordinal public-signature digest by the exact implemented
  `ConformanceKernel.EvaluateProtected` member. Every prior type/member row,
  total, boundary oracle, FQN and trait remains unchanged.

### `SELF-CONSUMPTION-01`

- add `src/MeAndAI.Protocol.Conformance/ProtectedPolicy/SelfConsumptionCore.cs`
  and `ConformanceKernel.SelfConsumption.cs`;
- add the exact implemented `QualifyCandidate` public member; a shell or
  throwing placeholder is forbidden;
- add only `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicySelfConsumptionTests.cs`;
- modify `ProtectedPolicySurfaceTests.cs` only to advance that same complete
  ordinal public-signature digest by the exact implemented
  `ConformanceKernel.QualifyCandidate` member. Every earlier staged row remains
  exact and the convergence reasserts the final frozen inventory.

### `PROTECTED-POLICY-CONVERGE-01`

- add `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicyConvergenceTests.cs`;
- modify the six prior protected-policy test files only to add the exact
  Scenario trait;
- modify `tests/scenario-ownership.psd1`, `.github/workflows/protocol-tests.yml`,
  and `tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1`;
- The [TEST-0211](test-cases.md#test-0211) surface/convergence tests own the exact successor API and ownership
  totals; predecessor FQNs/traits/product behavior remain unchanged;
- production changes are forbidden; a missing owner reopens its prior packet.

Every packet may additionally synchronize only this existing twelve-path
record cohort; these paths are cross-cutting evidence ownership, not production
allowlist expansion:

1. `.ai/memory/README.md`;
2. `.ai/memory/project.md`;
3. `.ai/memory/log/README.md`;
4. `.ai/memory/log/2026-08-14-feat-0065-subf-0144-design-freeze.md`;
5. `docs/architecture/protocol-governance-and-execution/README.md`;
6. `docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md`;
7. `docs/architecture/protocol-governance-and-execution/transition-register.md`;
8. `docs/features/README.md`;
9. the [feature record](README.md);
10. the owning `test-cases.md`;
11. this micro plan; and
12. the protected-policy design.

Record sync is wording/table substitution only: no new Markdown node, no new
this subfeature's design/implementation delivery commit/run link outside the owning
ledger, and no additional unique relation. Existing baseline/predecessor links
remain in their current canonical owner surfaces.
Each packet's final diff must be exactly its code/test allowlist plus these
records; an unrelated path redraws the packet before commit.

No packet may add or mutate a project, solution entry, package, lock, consumer
file, new workflow job/invocation, or graph-limit override. No friend assembly
change is allowed except the exact `EXTENSION-AUTHORITY-01`
Policy-to-Conformance.Tests declaration frozen above.
The convergence atomically removes [TEST-0211](test-cases.md#test-0211) from the existing
`PlannedDocumentation` [FEAT-0065](README.md) owner row while leaving
[TEST-0209](test-cases.md#test-0209) and [TEST-0222](test-cases.md#test-0222)
there, and changes the existing Conformance `DotNetTestProject` owner row from
the one-entry completed-scenario list to the exact ordinal two-entry list of
[TEST-0210](test-cases.md#test-0210) then [TEST-0211](test-cases.md#test-0211);
no intermediate or final duplicate owner is allowed. It appends the Scenario
predicate for [TEST-0211](test-cases.md#test-0211) once to each of the two existing
stable solution-test filters and updates the existing main-validation oracle
to require that exact two-filter shape. It creates no job, step, invocation,
owner row or runtime-efficiency mutation. StructureOnly, the main-validation
test and the exact scenario evidence inventory prove the new count/route. Any
other path redraws the owning packet first.

## Exact expected-red route

SurfaceRed uses one warning-as-error Release build of Conformance.Tests after
the source file is present and must fail only on the frozen missing type token;
it makes no test-discovery claim. Every behavior red uses:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj
  --configuration Release --no-restore --no-build --nologo --verbosity minimal
  --results-directory <fresh-external-directory>
  --logger trx;LogFileName=<packet-marker>.trx
  --filter FullyQualifiedName=<exact-fqn>
```

The exact behavior-red seam is packet-owned and cannot be substituted:

| Packet | Fully valid setup and sole missing behavior |
| --- | --- |
| `EXTENSION-AUTHORITY-01` | The friend-only signed canonical-empty activation fixture passes every identity and retained-verifier gate without requiring a registration; the marker is reached only because the trusted empty `ActivatedExtensionPolicy` is not minted. Public nonempty activation remains fail-closed. |
| `EXTENSION-EVALUATION-01` | The friend-only signed nonempty activation first passes against the real required-path registration; then the active declaration and sealed repository-tree row prove the path missing and reach that evaluator, and the marker is reached only because the exact extension finding/evaluation is absent. |
| `WAIVER-DISPOSITION-01` | The exact eligible, signed, unexpired waiver still returns `ActiveViolation`; the marker owns the missing `Waived` disposition only. |
| `DEBT-ENFORCEMENT-01` | The exact unchanged, unclosed, unexpired Prospective debt still returns `ActiveViolation` / `Block`; the marker owns the missing `HistoricalDebt` disposition and implemented public wrapper. |
| `SELF-CONSUMPTION-01` | Fully authenticated matching overlap and independent-fixture evaluations pass binding gates but remain `IsQualified=false`; the marker owns only the missing qualified result. |
| `PROTECTED-POLICY-CONVERGE-01` | The full semantic matrix is green first; the marker owns only the absent atomic seven Scenario traits, one owner move, and two filter additions. |

The pre-red compile scaffold is intentional, fail-closed, and uncommitted. A
throwing or untested production placeholder is forbidden. The accepted red
source remains byte-identical through review; green removes only its marker/
missing-seam assertion while implementing the owning behavior under the frozen
allowlist.

The immutable `DEBT-ENFORCEMENT-01` R=0004 source, FQN, marker, source hash and
TRX remain canonical and are never rerun. Because the internal carrier defect
was discovered only after that invocation, once this exact correction reaches
hosted green its green transformation may additionally add only the frozen
issued-replacement carrier positive, source/second/evaluated rejection,
ordinary phase-specific null-carrier unresolved assertions and their friend fixture to the same
test file. This does not rewrite the red observation or authorize a replacement
red identity.

Before the sole child invocation, the runner freezes exact HEAD/upstream/status,
source/runner/DLL/PDB/lock hashes, exact command, fresh-path absence, and one
warning-free Release `--no-restore` build. The exact semantic marker is emitted
only by the frozen missing behavior after all valid setup and identity checks.
Preflight/build failures consume no red but require correction review; any
failure after invocation commitment consumes that identity and is immutable.

## Local verification pipeline

One exact locked
`dotnet restore MeAndAI.Protocol.slnx --locked-mode --configfile NuGet.Config`
succeeds before any packet command using `--no-restore`; subsequent packets reverify the
six immutable lock hashes and perform no restore unless dependency state
changes, which reopens the cohort.

The six locks are exactly
`src/MeAndAI.Protocol.Domain/packages.lock.json`,
`src/MeAndAI.Protocol.Conformance.Abstractions/packages.lock.json`,
`src/MeAndAI.Protocol.Conformance/packages.lock.json`,
`src/MeAndAI.Protocol.Policy/packages.lock.json`,
`tests/dotnet/MeAndAI.Protocol.Domain.Tests/packages.lock.json`, and
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/packages.lock.json`; all must
remain regular/non-reparse and byte-identical to the accepted design head.

Each packet first performs one warning-free Release `--no-restore` build of
`MeAndAI.Protocol.slnx`, freezes the resulting Conformance.Tests DLL/PDB
identities, and only then runs every `--no-build` test against those exact
bytes. It then runs, in order:

1. exact focused FQN;
2. the exact ordinal protected-policy FQN inventory accumulated so far; before
   convergence this is an explicit OR filter plus expected FQN-set digest, and
   after convergence it must equal the Scenario filter for
   [TEST-0211](test-cases.md#test-0211);
3. full Conformance.Tests;
4. full Domain.Tests;
5. a second Release `--no-restore` build of `MeAndAI.Protocol.slnx`, zero
   warnings/errors, whose outputs must remain byte-identical to the frozen
   pre-test DLL/PDB identities;
6. `dotnet format MeAndAI.Protocol.slnx --verify-no-changes --no-restore`;
7. six relevant lock hashes and exact project/reference/API/ownership checks;
8. `pwsh -NoProfile -File tests/protocol.tests.ps1 -StructureOnly`; on Windows,
   run the same StructureOnly route under both PowerShell 7 and Windows
   PowerShell 5.1 where the repository route supports both;
9. `pwsh -NoProfile -File tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1`, including the exact [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175) cross-record barrier and with no publication claim;
10. `git diff --check`, marker removal/trait/allowlist/line-budget checks and
    exact graph/schema-2 validation;
11. independent code/test, evidence/scope, security/authority, and fresh-diff
    reviews at `0/0/0`;
12. record synchronization and one focused local commit.

The prospective graph profile is schema `2`, at most `512` nodes, `8,192`
unique relations, `1,048,576` bytes per parsed blob, `8,388,608` aggregate
parsed bytes, depth `32`, tree entries `65,536`, tree path bytes `4,194,304`,
and graph path bytes `32,768`. Exact `N` passes and `N+1` fails; released older
profiles remain byte-identical.

## Design cohort and automatic implementation gate

The design cohort is exactly these twelve Markdown paths:

1. `.ai/memory/README.md`;
2. `.ai/memory/project.md`;
3. `.ai/memory/log/README.md`;
4. the owning [SUBF-0144](README.md#subf-0144) design-freeze memory ledger;
5. `docs/architecture/protocol-governance-and-execution/README.md`;
6. `docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md`;
7. `docs/architecture/protocol-governance-and-execution/transition-register.md`;
8. `docs/features/README.md`;
9. [FEAT-0065](README.md);
10. [feature test cases](test-cases.md);
11. this micro plan; and
12. the [protected-policy design](subf-0144-extension-waiver-self-consumption-design.md).

The original cohort added no code/test/project/workflow/package/lock node and
introduced exactly the design, micro plan, and owning ledger. This correction
modifies those same twelve records, adds no node, and permits no fourth
handoff/appendix. New protected-policy design/implementation
delivery commit/run links remain only in the owning ledger; existing baseline/
predecessor links keep their current owners, while other live summaries use
existing links or generic wording. The
canonical schema-2 builder must record the exact node/relation/blob/byte tuple
and digest before commit; no static relation-neutral claim substitutes for that
executable validation.

The original cohort reached `AcceptedFrozenDesign` and activated the ordered
pipeline. The first input-custody correction is immutable intermediate
evidence, but fresh source projection found that its assumed target-resolution
product is not a repository tree. This latest follow-up owns only the immutable
issued-closure carrier topology and staged signature-oracle allowlists. Fresh
design/evidence/traceability/security/
graph reviews must again close `0/0/0`; StructureOnly and publication-evidence
must be green; the exact correction cohort must be committed and pushed; and
Ubuntu/Windows hosted validation must succeed for that exact head with
publication skipped. Success restores `AcceptedFrozenDesign` and automatically
resumes `DEBT-ENFORCEMENT-01` after its preserved canonical red. No extra
confirmation, completed-packet replay, or red rerun is required. Any correction
or hosted failure reopens only this design cohort and keeps debt green held.

## Held future work

[SUBF-0154](README.md#subf-0154), [TEST-0222](test-cases.md#test-0222),
[TEST-0209](test-cases.md#test-0209), [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md)
durable stores/grants/CAS, [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
adapters, consumer/Scenario-owner/workflow mutation, real publication,
release, authority transfer, and PowerShell retirement remain held.

The sole exception is the convergence packet's exact
[TEST-0211](test-cases.md#test-0211) verification
owner/filter/count activation within the existing workflow invocations. It is
not consumer behavior, a new workflow, release, publication, or authority
transfer.
