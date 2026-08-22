# [SUBF-0146](README.md#subf-0146) Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Conditional implementation-control record |
| Status | `DesignFreezeCandidate`; no implementation or expected-red authority exists |
| Parent | [FEAT-0066](README.md) |
| Design | [Journal and recovery design](subf-0146-journal-recovery-design.md) |
| Public API | [Exact public API contract](subf-0146-public-api-contract.md) |
| Values/errors | [Exact value and error contract](subf-0146-value-error-contract.md) |
| Scenario | [TEST-0213](test-cases.md#test-0213) |

The current records-only packet may edit only the six paths named under
[current authority](#current-records-only-authority). Everything below is a
frozen conditional plan, not permission to create a red, production code,
tests, workflows, releases, publications, adapters, or consumer changes.

## AcceptedFrozenDesign gate

Implementation authority remains inactive through two records-only cohorts:

1. the six-path records-only packet committed from exact base
   [`1d39a8bcfb18f4970c1642214a9415182ed82745`](https://github.com/hasanmanzak/meAndAI/commit/1d39a8bcfb18f4970c1642214a9415182ed82745);
2. scope/authority, semantic/security, public-API/value/error, test-intent, and
   delivery/parallelism reviews, each with `0` unresolved findings;
3. record-link, normalized-diff, allowlist, cap, formatting, and
   `StructureOnly` validation green on the committed candidate;
4. one push and exact-head Ubuntu/Windows hosted validation green;
5. explicit maintainer semantic acceptance authorizing a second records-only
   cohort that changes all four normative design-file statuses to
   `AcceptedFrozenDesign` and only the necessary README/test status links;
6. that exact acceptance-status cohort is independently reviewed, committed,
   pushed once, and exact-head Ubuntu/Windows hosted green; and
7. the maintainer issues a separate implementation directive against that
   exact hosted-green acceptance head.

Failure or correction restarts the affected review and exact-head gate. No
`Ready`, red, package, or implementation state may be inferred from this
records-only commit.

## Current records-only authority

Exact current allowlist:

~~~text
docs/features/FEAT-0066-shared-execution-authority-foundation/README.md
docs/features/FEAT-0066-shared-execution-authority-foundation/test-cases.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-journal-recovery-design.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-public-api-contract.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-value-error-contract.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-micro-delivery-plan.md
~~~

No production, test, workflow, solution, project, architecture, decision,
release, consumer, `.ai/memory`, or package-evidence path is currently owned.
The records packet caps are: at most `6` changed paths, at most `4` new paths,
each new file at most `1000` physical lines, and at most `3000` normalized
added lines across the packet. A cap increase reopens Gate 2.

## Package matrix

Packages execute strictly one at a time. Each begins only after its predecessor
is `ReviewedLocalGreen` on a focused commit and the next package receives an
explicit directive. Parallel agents may review or inspect disjoint read-only
surfaces; they may not implement multiple packages concurrently.

| Package | Dependency-closed outcome | Canonical red marker / exact FQN | Status |
| --- | --- | --- | --- |
| `EA-LEASE-FENCE-01` | protected lease acquire/renew/release and monotonic fencing | `TEST-0213-LEASE-RED-0001` / `MeAndAI.Operations.Architecture.Tests.LeaseFenceLifecycleContractTests.TEST_0213_only_current_fenced_owner_holds_the_lease` | `HeldForAcceptedFrozenDesign` |
| `EA-JOURNAL-CHAIN-01` | authenticated intent/receipt chain, head CAS, idempotent identical replay | `TEST-0213-JOURNAL-RED-0002` / `MeAndAI.Operations.Architecture.Tests.OperationJournalContractTests.TEST_0213_intent_precedes_effect_and_receipt_closes_the_chain` | `HeldForPredecessor` |
| `EA-RECONSTRUCTION-01` | chain validation, live observation, deterministic fail-closed classification | `TEST-0213-RECONSTRUCTION-RED-0003` / `MeAndAI.Operations.Architecture.Tests.OperationReconstructionContractTests.TEST_0213_reconstruction_classifies_live_effects_and_corruption_fail_closed` | `HeldForPredecessor` |
| `EA-RECOVERY-RETENTION-01` | exact newer-fenced recovery and separately authorized retention | `TEST-0213-RECOVERY-RED-0004` / `MeAndAI.Operations.Architecture.Tests.OperationRecoveryContractTests.TEST_0213_only_fresh_newer_fenced_recovery_or_retention_grant_mutates` | `HeldForPredecessor` |
| `EA-RECOVERY-CONVERGE-01` | records/reviews/evidence reconciliation only | no red and no production/test change | `HeldForPackages` |

Every future implementation Fact carries exactly the trait
[Subfeature=SUBF-0146](README.md#subf-0146). It must not carry
[Scenario=TEST-0213](test-cases.md#test-0213) until a later, separately frozen final-activation atom
adds the Scenario trait, owner mapping, stable workflow filter, and status in
one change. Partial package evidence never makes
[TEST-0213](test-cases.md#test-0213) active.

Exact public-type ownership is frozen as follows. `EA-LEASE-FENCE-01` owns
`DurableTransitionGrant`, `LeaseAction`, `LeaseGrant`, every `Lease*` type, and
introduces both `IExecutionRecovery*Port` interfaces. `EA-JOURNAL-CHAIN-01`
owns every `Journal*`, `OperationPlan*`, `OperationIntent*`,
`OperationReceipt*`, `OperationJournal*`, `OperationEffectId`,
`ExternalEffectObservation`, `ExternalEffectMutation*`, and
`OperationExecution*` type and extends only journal/effect port members.
`EA-RECONSTRUCTION-01` owns `ExternalEffectClassification`, `OperationState`,
`ReconstructedEffect`, and every `OperationReconstruction*` type and extends
only protected plan/journal/live-observation reads. `EA-RECOVERY-RETENTION-01`
owns every `Recovery*` and `Retention*` type and extends only the corresponding
protected grant/ledger and phased mutation members. No type may move packages
without reopening Gate 2.

## Package allowlists and caps

All paths are repository-relative. A package may change only its exact list.
The shared `ExecutionRecoveryPorts.cs` is successively owned by one active
package, never concurrently. Existing [SUBF-0145](README.md#subf-0145) source is read-only.

### EA-LEASE-FENCE-01

~~~text
src/MeAndAI.Operations.Domain/ExecutionAuthority/LeaseLifecycleContracts.cs
src/MeAndAI.Operations.Domain/ExecutionAuthority/DurableTransitionGrantContracts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionRecoveryPorts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/LeaseLifecycleService.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/LeaseFenceLifecycleContractTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPortTests.cs
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-package-evidence.md
~~~

Caps: production `1200`, tests `700`, package combined `1800`, any file `650`
normalized changed lines; at most `8` paths. The inventory may contain only the
exact types assigned to this package by the public-API grouping. The evidence
file is records-only and does not count toward production/test caps.

### EA-JOURNAL-CHAIN-01

~~~text
src/MeAndAI.Operations.Domain/ExecutionAuthority/OperationJournalContracts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionRecoveryPorts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/OperationJournalService.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/OperationJournalContractTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPortTests.cs
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-package-evidence.md
~~~

Caps: production `1100`, tests `850`, combined `1850`, any file `650`; at most
`7` paths. Only this package may extend the previously created recovery ports.

### EA-RECONSTRUCTION-01

~~~text
src/MeAndAI.Operations.Domain/ExecutionAuthority/OperationReconstructionContracts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionRecoveryPorts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/OperationReconstructionService.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/OperationReconstructionContractTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPortTests.cs
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-package-evidence.md
~~~

Caps: production `900`, tests `850`, combined `1600`, any file `600`; at most
`7` paths. No mutation adapter or consumer fixture is allowed.

### EA-RECOVERY-RETENTION-01

~~~text
src/MeAndAI.Operations.Domain/ExecutionAuthority/OperationRecoveryContracts.cs
src/MeAndAI.Operations.Domain/ExecutionAuthority/JournalRetentionContracts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/ExecutionRecoveryPorts.cs
src/MeAndAI.Operations.Application/ExecutionAuthority/OperationRecoveryService.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/OperationRecoveryContractTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPublicApiTests.cs
tests/dotnet/MeAndAI.Operations.Architecture.Tests/ExecutionAuthorityPortTests.cs
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-package-evidence.md
~~~

Caps: production `1800`, tests `1000`, combined `2700`, any file `850`; at most
`8` paths. Recovery and retention remain one dependency-closed package, while
their domain declarations are split across two bounded files. Their grant and
ledger semantics are inseparable from the recovery boundary; adapters remain
excluded.

### EA-RECOVERY-CONVERGE-01

~~~text
docs/features/FEAT-0066-shared-execution-authority-foundation/README.md
docs/features/FEAT-0066-shared-execution-authority-foundation/test-cases.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-journal-recovery-design.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-public-api-contract.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-value-error-contract.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-micro-delivery-plan.md
docs/features/FEAT-0066-shared-execution-authority-foundation/subf-0146-package-evidence.md
~~~

Caps: at most `7` records paths, `0` production/test/workflow changes, and at
most `700` normalized record lines. `.ai/memory` remains a separately granted
shared-writer operation after committed evidence exists.

## Canonical-red custody

For each package, the accepted red is one compile-safe reflection Fact at the
exact FQN/marker in the matrix. Before implementation it must:

1. contain only [Subfeature=SUBF-0146](README.md#subf-0146), fail only on the exact absent
   type/member, and keep all other assertions green;
2. run once through the original trusted project/filter route with no retry;
3. record exact command, SDK/tool versions, exit code, TRX path, failing test,
   duration, source SHA-256, TRX SHA-256, and clean pre/post status;
4. receive test-intent and red-integrity reviews with `0` unresolved findings;
5. be committed as an immutable expected-red checkpoint before production
   implementation begins.

The accepted source/TRX digests and marker may never be rewritten or rerun.
Implementation must make that exact test green. A failed green attempt uses a
new ordinary run; it never creates a second canonical red.

## Per-package transition

~~~text
HeldForAcceptedFrozenDesign
  -> AuthorizedRed
  -> ReviewedImmutableRed
  -> AuthorizedImplementation
  -> LocalGreenCandidate
  -> ReviewedLocalGreen
~~~

Every transition requires exact allowed paths, cap proof, clean pre/post status,
and its phase-specific evidence. `HeldForAcceptedFrozenDesign -> AuthorizedRed`
requires only the hosted-green accepted-design head plus explicit package/red
authority; no source/TRX exists yet. `AuthorizedRed -> ReviewedImmutableRed`
requires the one-time red invocation, source/TRX hashes, red-integrity reviews,
and immutable red commit. `ReviewedImmutableRed -> AuthorizedImplementation`
requires a separate implementation directive and unchanged red custody.
`AuthorizedImplementation -> LocalGreenCandidate -> ReviewedLocalGreen`
requires focused/full bounded build/test evidence, exact hashes, two independent
implementation/evidence reviews, and a focused green commit. Any unallowlisted path, cap breach, changed
accepted-red identity, missing link, retry, inherited dirty state, or unresolved
finding returns the package to its prior authorized state.

## Package tests and final held boundary

Package greens run the exact canonical FQN, then the Operations Domain,
Application, Architecture, Packaging, and StructureOnly suites required by the
changed dependency closure. The ledger records exact discovered/passed counts;
this plan does not predict counts. No full Windows CI retry or timeout change
is authorized by this plan.

After all four packages are `ReviewedLocalGreen`, convergence reconciles only
records and evidence, commits once, pushes one cohort, and requires exact-head
Ubuntu/Windows green. [TEST-0213](test-cases.md#test-0213) still remains `Planned` until its separate
activation atom is frozen, authorized, reviewed, committed, pushed, and hosted
green. Release, publication, adapters, consumer integration, authority transfer,
remote branch cleanup, and worktree cleanup are independently authorized
operations and are not implied by package completion.
