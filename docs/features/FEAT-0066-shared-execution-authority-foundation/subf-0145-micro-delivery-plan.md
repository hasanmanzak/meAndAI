# [SUBF-0145](README.md#subf-0145) Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Dependency-ordered delivery control for [TEST-0212](test-cases.md#test-0212) |
| Status | `AcceptedFrozenDesign`; all four implementation packages are `ReviewedLocalGreen`, and `EA-CONVERGE-01` exact-head hosted validation is pending |
| Design | [Authority, grant, publication, and activation design](subf-0145-authority-grant-activation-design.md) |
| Public API | [Exact public API contract](subf-0145-public-api-contract.md) |
| Values/errors | [Exact value and error contract](subf-0145-value-error-contract.md) |
| Baseline | Exact main [`14ad828bcdde5f843cdbf12677b25f19736e5691`](https://github.com/hasanmanzak/meAndAI/commit/14ad828bcdde5f843cdbf12677b25f19736e5691) |
| Tracking | [Issue #166](https://github.com/hasanmanzak/meAndAI/issues/166) |

## Delivery state machine

The only valid package states are `Inactive`, `DesignFrozen`,
`ExpectedRedAccepted`, `ReviewedLocalGreen`, and `ExactHeadHostedGreen`.
Exactly one implementation package may be active. A successor starts only when
its predecessor is `ReviewedLocalGreen` in a separate focused local commit.

~~~text
AcceptedFrozenDesign
  -> EA-AUTHORITY-SNAPSHOT-01
  -> EA-EXECUTION-GRANT-01
  -> EA-PUBLICATION-ENVELOPE-01
  -> EA-EXTENSION-ACTIVATION-01
  -> EA-CONVERGE-01
~~~

Each implementation package runs canonical expected red, the exact focused
test, slice-cumulative [Subfeature=SUBF-0145](README.md#subf-0145), the cumulative operational
foundation filter, the relevant Release build, format/diff/locks and structural
checks, a fresh package-local independent review, record synchronization, and a
separate focused local commit. Intermediate commits are not pushed and no
hosted-green claim is made for them.

The completed local commit sequence is pushed once at `EA-CONVERGE-01`. Exact
head then waits for Ubuntu and Windows stable jobs. A hosted failure reopens
only this cohort; separate commits identify the owning package. The correction
repeats local cohort validation and produces one new exact-head push. No work
continues through a failed hosted head.

## AcceptedFrozenDesign gate

Before `EA-AUTHORITY-SNAPSHOT-01` may start:

1. the design, [public API contract](subf-0145-public-api-contract.md),
   [value/error contract](subf-0145-value-error-contract.md), this plan,
   [FEAT-0066](README.md), and
   [TEST-0212](test-cases.md#test-0212) form one synchronized design-only diff;
2. the exact public inventory/signatures, errors, semantic owners, four
   expected-red FQNs/markers, package order, allowlists, and budgets are frozen;
3. architecture/security, evidence/traceability, and implementation-feasibility
   reviews each report `0 Blocking / 0 Important / 0 Minor` on the fresh diff;
4. local design validation in [Design verification](#design-verification) is
   green;
5. the design checkpoint is one focused commit and one push to the dedicated
   [FEAT-0066](README.md) PR branch; and
6. the exact pushed head passes Ubuntu and Windows stable CI.

When all six are recorded, status becomes `AcceptedFrozenDesign` and the
maintainer's conditional directive automatically authorizes the four
[SUBF-0145](README.md#subf-0145) implementation packages. No additional user
confirmation is requested. Merge, release, publication, consumer mutation,
credentials, real authority effects, [SUBF-0146](README.md#subf-0146), and
authority transfer remain unauthorized.

The grant canonical red exposed an implementability defect after the initial
gate: no independent expected lease/fence existed, and unapproved/null
grant-store states lacked exact mapping. The synchronized six-record correction
adds those coordinates to `GrantValidationRequest` and
`ExtensionActivationCommand`, maps the store states to `GrantStoreDrift`, and
repeats all six gate steps. It also freezes removal of the governance-invalid
intermediate [Scenario=TEST-0212](test-cases.md#test-0212) traits in favor of
[Subfeature=SUBF-0145](README.md#subf-0145); exact FQNs and documentation traceability remain. It
changes no type inventory, rejection set/order, expected-red identity/FQN,
package sequence/budget, or scenario owner/status. The one exact package-2
allowlist carveout below permits only this trait correction in the committed
snapshot test. The
accepted grant red remains immutable and was not invoked again; implementation
resumed only after the correction exact head passed Ubuntu and Windows.

The activation canonical red later exposed one package-local allowlist defect:
the two existing exact port-test doubles must implement the activation members
added to the frozen ports. The repeated design gate therefore permits only the
two package-4 test carveouts below. The accepted activation red source and TRX
remain immutable, are hash-reverified after reconciliation, and are never
invoked again before bounded green. This correction changes no product API,
behavior, rejection, expected-red identity, package order, or budget.

## Package matrix

| Package | Canonical expected red | Smallest green | Cumulative gate | Local handoff |
| --- | --- | --- | --- | --- |
| `EA-AUTHORITY-SNAPSHOT-01` | [`TEST-0212-SNAPSHOT-RED-0001`](test-cases.md#test-0212) / `MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_snapshot_and_role_separation_are_exact` | Frozen identity, role, member, separation, exception, digest, revision, journal-store, and snapshot contracts | exact FQN; [Subfeature=SUBF-0145](README.md#subf-0145); operational cumulative filter | `ReviewedLocalGreen` commit 1 |
| `EA-EXECUTION-GRANT-01` | [`TEST-0212-GRANT-RED-0002`](test-cases.md#test-0212) / `MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_grant_is_fresh_exact_non_transitive_and_single_use` | Exact subject/target/binding/grant validation plus one-time fake-store consumption and least-authority ports | exact FQN; [Subfeature=SUBF-0145](README.md#subf-0145); operational cumulative filter | `ReviewedLocalGreen` commit 2 |
| `EA-PUBLICATION-ENVELOPE-01` | [`TEST-0212-PUBLICATION-RED-0003`](test-cases.md#test-0212) / `MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_binds_sealed_report_and_publication_grant` | Cycle-free sealed-report/publication-grant envelope with mismatch negatives | exact FQN; [Subfeature=SUBF-0145](README.md#subf-0145); operational cumulative filter | `ReviewedLocalGreen` commit 3 |
| `EA-EXTENSION-ACTIVATION-01` | [`TEST-0212-ACTIVATION-RED-0004`](test-cases.md#test-0212) / `MeAndAI.Operations.Architecture.Tests.ExtensionActivationContractTests.TEST_0212_only_fresh_winning_cas_activates_extension` | Protected record/transition/command plus two-contender single-winning CAS | exact FQN; [Subfeature=SUBF-0145](README.md#subf-0145); operational cumulative filter | `ReviewedLocalGreen` commit 4 |
| `EA-CONVERGE-01` | `R=NotApplicable`; no new behavior or marker | Records, exact API inventory, full local cohort gates, independent cohort diff review | all gates below | records-only local commit 5, one cohort push, exact-head hosted gate |

Each corrected-freeze red source has one `[Fact]`, only the cohort trait
[Subfeature=SUBF-0145](README.md#subf-0145), and no sleep/retry/network/real-store dependency. The accepted TRX and
source SHA-256 are recorded before green. Infrastructure abort, zero discovery,
unexpected sibling failure, skip, or same-FQN pass is not red. An accepted red
is immutable; its R command has one pre-green attempt and no unchanged retry.
The already accepted snapshot and grant source digests remain immutable
historical evidence of their pre-correction [Scenario=TEST-0212](test-cases.md#test-0212) bytes. Only
their working typed facts are transformed to [Subfeature=SUBF-0145](README.md#subf-0145); neither R
is rerun.

The first red in each package is compile-safe: it resolves the owning assembly,
uses ordinal reflection against the package's first frozen assembly-qualified
type/member name from the API appendix, and fails only on that absence with the
exact package marker. It contains no compile-time reference to the absent API.
For the publication and activation packages, after changed product evidence
exists, an immutable source copy of that absence oracle is run exactly once and
passes unchanged; the working test is then replaced by typed behavior coverage
under the same FQN. The completed snapshot package has already consumed this
step. The grant source is hash-reverified after reconciliation but is never
invoked again before its working green transformation. Build failure is never
the expected failure.

## Exact package allowlists and budgets

Files outside the listed roots are forbidden. Existing files may change only
when explicitly listed; generated `obj`, `bin`, result, coverage, and temporary
files are never staged.

Each of the first four packages may also create/update only its matching
heading in
`docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-package-evidence.md`.
That package-local record allowance is `<=80` normalized changed lines per
package and may contain only command result/count/duration, R/TRX/source digest,
review B/I/M disposition, and local commit evidence. The frozen design, API and
value/error appendices, plan, README, and test-cases are immutable during implementation; a
needed change to them reopens `AcceptedFrozenDesign`. Shared project memory and
common logs remain under their single owner and are allowed only at converge.

### `EA-AUTHORITY-SNAPSHOT-01`

Allowed production:

- `src/MeAndAI.Operations.Domain/ExecutionAuthority/AuthorityIdentity.cs`
- `src/MeAndAI.Operations.Domain/ExecutionAuthority/AuthorityDigest.cs`
- `src/MeAndAI.Operations.Domain/ExecutionAuthority/AuthoritySetContracts.cs`

Allowed tests:

- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthoritySnapshotTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs`

Budget: production `<=650`, tests `<=650`, combined normalized changed lines
`<=1200`; every single file `<=500` lines.

### `EA-EXECUTION-GRANT-01`

Allowed production:

- `src/MeAndAI.Operations.Domain/ExecutionAuthority/ExecutionGrantContracts.cs`
- `src/MeAndAI.Operations.Domain/ExecutionAuthority/ExecutionGrantDecisions.cs`
- `src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionAuthorityPorts.cs`
- `src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionGrantAuthorizer.cs`

Allowed tests:

- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionGrantContractTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPortTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthoritySnapshotTests.cs`,
  only to replace each [Scenario=TEST-0212](test-cases.md#test-0212) attribute with
  [Subfeature=SUBF-0145](README.md#subf-0145); no test body or public-API assertion may change

Budget: production `<=850`, tests `<=850`, combined normalized changed lines
`<=1600`; every single file `<=550` lines. The wider package budget is required
for the security matrix; it does not permit a monolithic file.

### `EA-PUBLICATION-ENVELOPE-01`

Allowed production:

- `src/MeAndAI.Operations.Domain/ExecutionAuthority/PublicationEnvelope.cs`

Allowed tests:

- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/PublicationEnvelopeContractTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs`

Budget: production `<=350`, tests `<=450`, combined normalized changed lines
`<=750`; every single file `<=500` lines.

### `EA-EXTENSION-ACTIVATION-01`

Allowed production:

- `src/MeAndAI.Operations.Domain/ExecutionAuthority/ExtensionActivationContracts.cs`
- `src/MeAndAI.Operations.Application/ExecutionAuthority/ExtensionActivationService.cs`
- `src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionAuthorityPorts.cs`

Allowed tests:

- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExtensionActivationContractTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs`
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPortTests.cs`,
  only to add the frozen activation read/mutation members to the exact method
  inventory, parameter-name routing, and fail-closed stub
- `tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionGrantContractTests.cs`,
  only to add compile-safe fail-closed stubs for the same two activation port
  members; no existing grant test body or fake-store behavior may change

Budget: production `<=700`, tests `<=700`, combined normalized changed lines
`<=1300`; every single file `<=550` lines.

### `EA-CONVERGE-01`

Allowed records:

- `docs/features/FEAT-0066-shared-execution-authority-foundation/README.md`
- `docs/features/FEAT-0066-shared-execution-authority-foundation/test-cases.md`
- `docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-authority-grant-activation-design.md`
- `docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-public-api-contract.md`
- `docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-value-error-contract.md`
- `docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-micro-delivery-plan.md`
- `docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-package-evidence.md`
- the canonical project-memory handoff and log index, only when the shared-record owner has granted that exact file cohort

Budget: records-only normalized changed lines `<=300`; each new Markdown blob
`<=800` lines and `<1048576` bytes. Any required file outside an allowlist or
any exceeded budget reopens design; it is not silently added or raised during
implementation.

No package may change project files, solution files, central build/package
configuration, packages, lock files, workflows, scenario ownership,
`PROTOCOL.md`, architecture, [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md),
consumer repositories, or preserved WIP.

## Per-package procedure

The snapshot package has already completed this procedure under the initial
freeze. For the resumed grant package, steps 2-4 are replaced by an ordinal
verification of the frozen source and TRX SHA-256 values after correction
reconciliation; neither the R command nor the original oracle is invoked.
Grant step 6 therefore begins with the transformed final-source exact FQN, then
runs the cumulative gates. The activation R was accepted before its allowlist
correction; activation therefore also replaces steps 2-4 with ordinal
verification of its frozen source and TRX SHA-256 after reconciliation and
invokes neither R nor the original oracle at that point. It then performs step
5, and step 6 begins with the not-yet-consumed source-identical original-oracle
pass exactly once before the typed final-source FQN. Publication alone uses the
full procedure:

1. verify predecessor local commit and the exact allowlist;
2. write only the canonical expected-red source;
3. build the owning test project and run one exact-FQN invocation to capture R;
4. validate exact marker/FQN/result/counter/source-digest/TRX-digest shape;
5. freeze R and implement the smallest dependency-closed green;
6. run original-oracle exact FQN, final-source exact FQN, slice-cumulative,
   operational cumulative, and Release build;
7. run format, diff, marker, API, project-boundary, lock, and relevant
   structural checks;
8. perform fresh code/security, regression, and evidence/traceability reviews;
9. synchronize package-local records and record elapsed local time plus B/I/M;
10. make one focused local commit, mark `ReviewedLocalGreen`, and activate only
    its direct successor.

No package pushes, changes a PR, or claims hosted evidence. A failed check
reopens the owning package. No unchanged failing command is retried; continue
only after changed evidence or a materially different authorized route.

## Design verification

The uncommitted candidate runs the following from repository root on an
unchanged source snapshot:

~~~powershell
git diff --check
$packet = @(
  '.\docs\features\FEAT-0066-shared-execution-authority-foundation\subf-0145-authority-grant-activation-design.md',
  '.\docs\features\FEAT-0066-shared-execution-authority-foundation\subf-0145-public-api-contract.md',
  '.\docs\features\FEAT-0066-shared-execution-authority-foundation\subf-0145-value-error-contract.md',
  '.\docs\features\FEAT-0066-shared-execution-authority-foundation\subf-0145-micro-delivery-plan.md'
)
foreach ($path in $packet) {
  $lines = (Get-Content -LiteralPath $path).Count
  $bytes = (Get-Item -LiteralPath $path).Length
  if ($lines -gt 800 -or $bytes -ge 1048576) { throw "Packet budget exceeded: $path" }
}
$changed = @(git diff --name-only; git ls-files --others --exclude-standard)
$allowed = @(
  'docs/features/FEAT-0066-shared-execution-authority-foundation/README.md',
  'docs/features/FEAT-0066-shared-execution-authority-foundation/test-cases.md',
  'docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-authority-grant-activation-design.md',
  'docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-public-api-contract.md',
  'docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-value-error-contract.md',
  'docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0145-micro-delivery-plan.md'
)
$forbidden = @($changed | Where-Object { $_ -notin $allowed })
if ($forbidden.Count -ne 0) { throw "Forbidden design path: $($forbidden -join ', ')" }
$api = Get-Content -LiteralPath $packet[1] -Raw
$inventory = [regex]::Match(
  $api,
  '(?ms)^## Normative SliceInventory\r?\n\r?\n~~~text\r?\n(?<body>.*?)\r?\n~~~'
).Groups['body'].Value -split '\r?\n'
$expectedInventory = @(
  'ActivationCasDecision','ApprovalAuthoritySetSnapshot','AuthorityApprovalPolicy',
  'AuthorityActorId','AuthorityDigest','AuthorityGrantId','AuthorityOperationId',
  'AuthorityRevision','AuthorityRole','AuthoritySetBinding','AuthoritySetId',
  'AuthoritySetMember','ExecutionCapability','ExecutionGrant',
  'ExecutionGrantAuthorizer','ExecutionGrantBinding','ExecutionGrantDecision',
  'ExecutionGrantRejection','ExecutionSubject','ExecutionTarget',
  'ExtensionActivationCommand','ExtensionActivationGrantBinding',
  'ExtensionActivationMutationRequest','ExtensionActivationRecord',
  'ExtensionActivationService','GrantApprovalEvidence','GrantConsumptionRequest',
  'GrantGeneration','GrantValidationRequest','IExecutionAuthorityMutationPort',
  'IExecutionAuthorityReadPort','IdempotencyKey','JournalStoreReference',
  'LeaseFenceBinding','PlanGrantBinding','PublicationEnvelope',
  'PublicationGrantBinding','ReadGrantBinding','RoleSeparationRequirement',
  'SoloMaintainerException'
)
if (($inventory -join '|') -cne ($expectedInventory -join '|')) {
  throw 'Normative SliceInventory drifted.'
}
$frozenTokens = @(
  ('TEST-' + '0212-SNAPSHOT-RED-0001'),
  ('TEST-' + '0212-GRANT-RED-0002'),
  ('TEST-' + '0212-PUBLICATION-RED-0003'),
  ('TEST-' + '0212-ACTIVATION-RED-0004'),
  'MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_snapshot_and_role_separation_are_exact',
  'MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_grant_is_fresh_exact_non_transitive_and_single_use',
  'MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_binds_sealed_report_and_publication_grant',
  'MeAndAI.Operations.Architecture.Tests.ExtensionActivationContractTests.TEST_0212_only_fresh_winning_cas_activates_extension'
)
foreach ($token in $frozenTokens) {
  $hits = @(Select-String -LiteralPath $packet[0],$packet[3] -SimpleMatch $token)
  $expectedHits = if ($token.StartsWith('TEST-')) { 2 } else { 4 }
  if ($hits.Count -ne $expectedHits) {
    throw "Frozen token occurrence drift: $token"
  }
}
& .\tests\capabilities\protocol-governance\protocol-governance.tests.ps1
& .\tests\capabilities\publication-evidence\post-publication-evidence.tests.ps1
~~~

Expected result is exit 0, no diff whitespace error, four bounded blobs, no
path outside the six-file design allowlist, all canonical governance
assertions green including [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175),
and the complete publication-evidence suite green. The frozen API inventory is
checked ordinally against the appendix; every marker, FQN, package name, stable
ID, and relative Markdown link must occur at its owning record and resolve
without ambiguity. No project/solution/build/package/lock/workflow/source/test
file may appear in the diff.

After the focused local design commit, and before push, the committed candidate
runs:

~~~powershell
git status --short
& .\tests\protocol.tests.ps1 -StructureOnly
git diff HEAD^ --check
~~~

`git status --short` must be empty, StructureOnly must exit 0 within the
official 20-minute PowerShell 7 or 35-minute Windows PowerShell 5.1 bound, and
the committed diff check must be clean. It is not retried unchanged. The
design-only commit is then pushed once and its exact SHA must pass the stable
Ubuntu and Windows jobs before status becomes `AcceptedFrozenDesign`.

## Canonical verification commands

From repository root, with exact test paths and no package restore drift:

~~~powershell
$subfeature0145 = 'SUBF-' + '0145'
$scenario0191 = 'TEST-' + '0191'
$scenario0192 = 'TEST-' + '0192'
$scenario0193 = 'TEST-' + '0193'
dotnet restore .\MeAndAI.Operations.slnx --locked-mode
dotnet test .\tests\dotnet\MeAndAI.Operations.Architecture.Tests\MeAndAI.Operations.Architecture.Tests.csproj --no-restore --configuration Release --filter "FullyQualifiedName=MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_snapshot_and_role_separation_are_exact"
dotnet test .\tests\dotnet\MeAndAI.Operations.Architecture.Tests\MeAndAI.Operations.Architecture.Tests.csproj --no-restore --configuration Release --filter "FullyQualifiedName=MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_grant_is_fresh_exact_non_transitive_and_single_use"
dotnet test .\tests\dotnet\MeAndAI.Operations.Architecture.Tests\MeAndAI.Operations.Architecture.Tests.csproj --no-restore --configuration Release --filter "FullyQualifiedName=MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_binds_sealed_report_and_publication_grant"
dotnet test .\tests\dotnet\MeAndAI.Operations.Architecture.Tests\MeAndAI.Operations.Architecture.Tests.csproj --no-restore --configuration Release --filter "FullyQualifiedName=MeAndAI.Operations.Architecture.Tests.ExtensionActivationContractTests.TEST_0212_only_fresh_winning_cas_activates_extension"
dotnet test .\tests\dotnet\MeAndAI.Operations.Architecture.Tests\MeAndAI.Operations.Architecture.Tests.csproj --no-restore --configuration Release --filter "Subfeature=$subfeature0145"
dotnet test .\tests\dotnet\MeAndAI.Operations.Architecture.Tests\MeAndAI.Operations.Architecture.Tests.csproj --no-restore --configuration Release --filter "Scenario=$scenario0191|Scenario=$scenario0192|Subfeature=$subfeature0145"
dotnet test .\tests\dotnet\MeAndAI.Operations.Packaging.Tests\MeAndAI.Operations.Packaging.Tests.csproj --no-restore --configuration Release --filter "Scenario=$scenario0193"
dotnet build .\MeAndAI.Operations.slnx --no-restore --configuration Release
dotnet format .\MeAndAI.Operations.slnx --no-restore --verify-no-changes --severity info
git diff --check
~~~

Only the exact FQN belonging to the active package is run at its expected-red
step. Lock fingerprints are captured before the first package and compared
after each package. `dotnet test` or build failure is not retried unchanged.
The expected-red process receives no loop or automatic retry.

## Cohort convergence verification

After commit 5 and before the single push:

- rerun all four exact FQNs and
  [Subfeature=SUBF-0145](README.md#subf-0145); the canonical [TEST-0212](test-cases.md#test-0212)
  scenario remains `Planned` and is not asserted;
- rerun the complete Operations architecture test project and
  the complete `MeAndAI.Operations.Packaging.Tests` project, including
  [TEST-0193](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193),
  plus the `MeAndAI.Operations.slnx` Release build;
- run `dotnet format`, `git diff --check`, lock fingerprints, exact public API
  inventory, namespace/project ownership, forbidden-path scan, and line budgets;
- run the full Conformance and Domain test projects to prove foundation
  coexistence;
- run `./tests/protocol.tests.ps1 -StructureOnly` at its official bound;
- run [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  and the relevant publication-evidence checks; and
- perform one fresh complete cohort-diff review with no unresolved B/I/M.

The prospective graph authority is schema 2 with `8192` edges, `1048576`
per-blob bytes, and `8388608` aggregate parsed bytes; unchanged limits are
nodes `512`, depth `32`, tree entries `65536`, tree-path bytes `4194304`, and
graph-path bytes `32768`. Profiles through `v0.16.0` remain immutable. The
committed candidate is required because an untracked governance packet cannot
be final HEAD-graph evidence.

## Evidence ledger

For each package and the final cohort record:

- local implementation and validation elapsed time;
- canonical R source/TRX SHA-256 and exact FQN;
- focused, slice-cumulative, operational-cumulative, build, format, structural,
  API, lock, and review result;
- B/I/M and exact disposition of every observation;
- local commit SHA;
- hosted CI duration and errors, owning-package identification time, correction
  and revalidation cost after the cohort push; and
- estimated savings versus four package-level hosted pushes, plus any observed
  consistency or traceability loss.

The final [SUBF-0145](README.md#subf-0145) cohort completion claim requires the
`EA-CONVERGE-01` audit, final record synchronization, remote-equal exact-head
Ubuntu/Windows green, and no unresolved B/I/M. It does not claim
[TEST-0212](test-cases.md#test-0212) completion while that scenario remains
`Planned`; nor does it imply feature merge, release, publication, consumer
activation, or [SUBF-0146](README.md#subf-0146) implementation.
