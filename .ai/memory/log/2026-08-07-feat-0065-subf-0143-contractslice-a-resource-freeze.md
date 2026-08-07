# ContractSlice A resource-boundary FrozenDesign handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-07 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Parent | ContractSlice A typed-kernel subfeature and its planned scenario |
| State | `A-RESOURCE-01` is `FrozenDesign` and inactive |
| Activation predecessor | `A-LIFECYCLE-01` records synchronization is the immutable exact hosted-green predecessor below |
| Identity | Exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceAResourceManifestTests.Enforces_exact_manifest_byte_reachable_depth_and_token_ceilings`; one Fact; only `ContractSlice=A`; no Scenario |
| Evidence route | D=`FrozenDesign`; P=`NotApplicable`; R ordinal `0016` with marker/TRX stem `TEST-0210-A-BEHAVIOR-RED-0016`; G is bounded test plus one production constant correction |
| Progress | Eighteen of twenty live packets are `ReviewedLocalGreen` (`90%`); cumulative A is `31/31`; the parent scenario remains `Planned` |

The records-head gate that permits this design freeze is exact-hosted-green:

```text
predecessorCommitSha=b7b31bada52b639e5bcdd4dc7a286821c7e0cc4a
predecessorTreeSha=92cc21e2d407fcf3d4d98b1cc2c8d628275cf335
workflowRunId=31196555916
workflowStatus=completed
workflowConclusion=success
ubuntuJobId=92926052870
ubuntuJobConclusion=success
ubuntuJobDuration=00:14:45
windowsJobId=92926052804
windowsJobConclusion=success
windowsJobDuration=00:48:03
publicationJobId=92926053924
publicationJobConclusion=skipped
```

## Frozen ceilings and carriers

- Schema 1 permits exactly `16,777,216` input bytes, reachable JSON container depth `9`, and `1,000,000` JSON tokens. Root object depth is `1`; only object/array starts increment depth. No declaration-count or collection-count ceiling is added.
- Byte equality/one-over uses a qualification `compatibilityAliases` carrier whose token count stays comfortably below the token ceiling. Its final one or two aliases tune canonical byte length without changing another resource boundary.
- Token equality/one-over uses sorted, unique, fixed-width qualification aliases and stays comfortably below the byte ceiling. Token counting uses `Utf8JsonReader` semantics and includes property names, scalars, and container tokens.
- Depth equality reuses the full manifest graph at exact reachable depth `9`. No grammar-valid schema-1 depth-`10` manifest exists. The one-over carrier replaces the deepest `componentKey` string scalar under `slice/rules/evaluationSlots/capabilities/interfaceType` with an object value, creating a tenth container while changing no byte/token-boundary claim.
- The three carriers are independent, sequential, deterministic, and in-memory. They use no disk fixture, `JsonDocument`, naive repeated concatenation, ambient machine value, or parallel million-token construction.

## Frozen red and green oracles

- R runs the exact FQN once. Exactly one test is selected, executed, and failed; the sole failed result owns the exact marker and every other BehaviorRed counter/diagnostic rule remains unchanged.
- Unchanged production must reach only the frozen legacy depth branch: outer `FormatException` message `Expected JSON token 'String'.` with no inner exception. Any other observation invalidates R and reopens D/RT.
- Green requires `FinalizedPolicyManifest.ParseCanonical` to reject the tenth container through outer exact `FormatException` message `The policy manifest is not canonical JSON.` with a `JsonException` inner exception. Byte equality must pass; byte one-over must throw exact `FormatException` message `The canonical policy manifest exceeds the byte ceiling.` with null inner exception. Token equality must pass; token one-over must throw exact `FormatException` message `The policy manifest exceeds the JSON token ceiling.` with null inner exception.
- The only production change is `CanonicalManifestReader.MaximumDepth = 64` to `9`. Public/friend surface, Writer, Catalog, fixture helpers, projects, packages, locks, workflows, and every other resource budget remain byte-identical.

## Caps, measurement, and holds

- Production delta is exactly one replacement (`+1/-1`). New retained test source and additions are capped at `650`; combined additions are capped at `651`. Crossing a cap or needing a second production location reopens D/RT.
- The test may declare a nonparallel xUnit collection in its own file. Large buffers/lists are pre-sized and released between carriers; token counting streams. A fresh parent sampler measures the exact focused `dotnet test` process tree every `100ms`, from root launch through root exit; inability to observe any descendant invalidates the measurement. Green custody requires focused duration at most `90s` and sampled aggregate working set at most `1,610,612,736` bytes (`1.5 GiB`). Crossing either cap reopens design instead of widening the existing `55`-minute Windows hosted ceiling or a resource limit automatically.
- No expected-red source is created until this records-only freeze itself passes local review, protocol gates, exact push, and exact-head hosted validation.
- `A-CONVERGE-02` remains Candidate/inactive. B/C/D, final Scenario/status/owner/workflow/efficiency activation, merge, release, publication, consumer mutation, and authority transfer remain held.
