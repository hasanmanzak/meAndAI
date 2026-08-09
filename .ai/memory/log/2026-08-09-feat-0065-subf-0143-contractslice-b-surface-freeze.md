# ContractSlice B surface packet freeze

| Field | Value |
| --- | --- |
| Packet | `B-SURFACE-01` |
| State | `ReviewedLocalGreen`; exact-head hosted pending |
| Parent | [ContractSlice B micro-delivery plan](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-contractslice-b-micro-delivery-plan.md) |
| Scenario | [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210), retained `Planned` |
| Exact predecessor | Merge commit [`793bb75074ddaa62e62fcb0ee33574b3efda001a`](https://github.com/hasanmanzak/meAndAI/commit/793bb75074ddaa62e62fcb0ee33574b3efda001a); exact-main [run 31310208767](https://github.com/hasanmanzak/meAndAI/actions/runs/31310208767) passed Ubuntu `5m39s`, Windows `11m28s`, publication skipped |
| Implementation language | C# only |

## Frozen executable allowlist

The packet may add exactly these nineteen Abstractions public carriers:

```text
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/GovernedReferenceView.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/IEvidenceCapability.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/IGovernedReferenceIndex.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/IProtocolRecordIndex.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/IRepositoryTargetResolutionIndex.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/IRepositoryTree.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/ProtocolRecordMemberView.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/ProtocolRecordView.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/QualifiedEvidenceHandle.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/RepositoryEntryView.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/RepositoryTargetResolutionDemandItem.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Capabilities/RepositoryTargetResolutionView.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Proofs/IFailedAttemptProof.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Proofs/INoInputRoutingProof.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Proofs/IObservedQualificationProof.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Tokens/GovernedReferenceKind.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Tokens/GovernedReferenceResolution.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Tokens/GovernedReferenceSyntax.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Tokens/RepositoryEntryKind.cs
```

It may add exactly these five Conformance public carriers:

```text
src/MeAndAI.Protocol.Conformance/Evidence/AcquisitionProofSet.cs
src/MeAndAI.Protocol.Conformance/Evidence/QualifiedEvidenceDerivation.cs
src/MeAndAI.Protocol.Conformance/Evidence/QualifiedEvidenceReference.cs
src/MeAndAI.Protocol.Conformance/Evidence/QualifiedEvidenceSelector.cs
src/MeAndAI.Protocol.Conformance/Evidence/SealedEvaluationContext.cs
```

The exact test-project allowlist is:

```text
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceB.SurfaceRed.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBStructuralTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceAPublicApiTests.cs
```

The second file owns exactly the retained direct Facts
`ContractSliceBPublicApiTests.Matches_exact_cumulative_b_public_surface` and
`ContractSliceBOwnershipTests.Enforces_exact_friend_factory_and_negative_surface`.
Each has only `ContractSlice=B` and no `Scenario`.
The retained A PublicApi file may change only inside the existing
`ExportedTypesEqualTheContractSliceAInventories` Fact/helper: its FQN, direct
Fact, trait, A-owned inventory/member/friend/negative-surface ownership remain
exact, while whole-assembly-total equality becomes exact containment. The B
PublicApi Fact becomes the sole current cumulative-total owner at `72`.

## Red and green oracle

The permanent ten-line SurfaceRed has sole unresolved token
`IObservedQualificationProof`. The one canonical command is:

```text
dotnet build tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --nologo --verbosity minimal
```

The only accepted diagnostic is `CS0246` at
`ContractSliceB.SurfaceRed.cs` `5:38-5:65`, token
`IObservedQualificationProof`, semantic FQN
`MeAndAI.Protocol.Conformance.Abstractions.IObservedQualificationProof`, with
zero warnings and no second compiler, analyzer, restore, project, or
environment diagnostic. It is invoked once and never rerun.

The canonical invocation completed once with exit `1`, zero warnings, and the
sole exact `CS0246` diagnostic above. The permanent SurfaceRed source remains
in the test project and is never rerun as red. After the 24 public carriers and
two B Facts were added, the first A+B diagnostic run selected `34`, passed
`33`, and failed only the retained A PublicApi Fact because its historical
whole-assembly-total assertion rejected legitimate B exports. That result is a
topology diagnostic, not green evidence; it triggered the reviewed ownership
transfer above without changing production scope or rerunning SurfaceRed.

Green requires a warning-free Release build, focused structural `2/2`, exact
`ContractSlice=B` `2/2`, exact `ContractSlice=A|ContractSlice=B` `34/34`, full
Conformance `34/34`, and Domain `98/98`. The two structural Facts prove the
exact cumulative export count `72`, all 24 type/member/nullability/factory
surfaces, unchanged friend/project/lock boundary, zero Domain export delta, and
absence of codec activation or later-slice runtime types.

## Green and review evidence

- Release build: `0` warnings / `0` errors.
- Focused PublicApi + Ownership: `2/2`; `ContractSlice=B`: `2/2`.
- Cumulative A+B: `34/34`; full Conformance: `34/34`; Domain: `98/98`.
- Format verification at severity `info`: clean; diff check: clean.
- StructureOnly: green with `elapsedMs=445953`; accepted schema-2 graph limits
  were not exceeded.
- Publication-evidence verifier: `7/7`, including the fresh commit-reference
  recurrence, with no publication claim.
- Source/test additions: `1,744/2,500`; exactly 24 public carrier files, two
  new B test files, and the one named retained-A assertion transition.
- Project/package/lock/workflow/Domain/Policy deltas: zero.
- Product/test review: `0 Blocking / 0 Important / 0 Minor`.
- Evidence/scope review: `0 Blocking / 0 Important / 0 Minor`.

The canonical red is not reused as green evidence. The first A+B topology
diagnostic remains diagnostic only; all retained green counts above are fresh
after the reviewed assertion-ownership correction.

## Negative scope and budgets

No Domain, project, package, lock, workflow, other A source/test, Policy,
consumer, Scenario/status/owner/filter, runtime-efficiency, codec activation,
wire, resource, cache, admission, C/D, release, or publication mutation is
allowed. The packet adds at most 24 carrier files and two B test-project files,
may make only the named A PublicApi assertion transition, and adds at most
2,500 normalized source/test lines. Record synchronization occurs only after green.
The prospective graph profile remains the accepted schema-2 `8,192` edge /
`8,388,608` parsed-byte profile; final StructureOnly must emit an in-limit exact
tree.

## Pre-red reviews

- Architecture/semantic-boundary review: `0 Blocking / 0 Important / 0 Minor`.
  The complete public surface closes atomically, exposes no runtime activation,
  and retains B/C/D ownership boundaries.
- Evidence/scope review: `0 Blocking / 0 Important / 0 Minor`. The exact
  predecessor, two-new-file test cap plus one named predecessor-test
  transition, one-diagnostic oracle, cardinalities, immutable surfaces,
  exclusions, and line/graph budgets are finite and fail-closed.
- Post-diagnostic topology review: `0 Blocking / 0 Important / 0 Minor`. The
  retained slice owns containment; the active slice owns cumulative-total
  equality; no FQN, trait, member snapshot, runtime, or downstream authority
  changes.

The accepted canonical SurfaceRed is immutable and must not be invoked again.
A successful structural green does not activate `B-CODEC-ACTIVATION-01`.
