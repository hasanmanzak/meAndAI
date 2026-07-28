# [FEAT-0060](README.md) Rule, Profile, and Evidence-Source Matrix Analysis

Status: scenario-level analysis complete; variant-level matrix blocked on the
[contract decision packet](contract-decision-packet.md). Development is not
authorized.

This record separates governance rule applicability from operational runtime,
test infrastructure, and provider evidence. It does not infer consumer policy
from the current PowerShell owner name.

## Family distribution

| Family | Total | C# candidate | Mixed | PowerShell operational | Infrastructure | Provider | Existing C# |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Direct protocol governance | 37 | 29 | 6 | 1 | 1 | 0 | 0 |
| Adoption | 61 | 0 | 2 | 54 | 5 | 0 | 0 |
| Update, migration, and finalization | 40 | 2 | 4 | 30 | 4 | 0 | 0 |
| Instruction graph | 3 | 2 | 0 | 0 | 1 | 0 | 0 |
| Capability | 15 | 5 | 1 | 9 | 0 | 0 | 0 |
| Publication | 8 | 1 | 3 | 0 | 1 | 3 | 0 |
| Windows, workflow, and runtime | 10 | 0 | 0 | 0 | 10 | 0 | 0 |
| Test architecture and recurrence | 10 | 3 | 0 | 0 | 7 | 0 | 0 |
| Idea lifecycle | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| C# foundation | 3 | 0 | 0 | 0 | 0 | 0 | 3 |
| **Total** | **188** | **43** | **16** | **94** | **29** | **3** | **3** |

The category membership is enumerated in the
[differential-ledger inventory](differential-ledger-analysis.md#scenario-level-planned-route-inventory).

## Candidate profile applicability

Only the 43 `CSharpCandidate` identities have a conclusive scenario-level
profile proposal. No candidate is consumer-only at scenario level.

| Applicability | Count | TEST identities |
| --- | ---: | --- |
| `protocol-authority` only | 10 | Exact membership in the [scenario-route analysis](scenario-route-analysis.csv) |
| Both `protocol-authority` and `consumer` | 33 | Exact membership in the [scenario-route analysis](scenario-route-analysis.csv) |
| `consumer` only | 0 | None at scenario level; mixed variants may yield consumer-only rows after accepted expansion |

Profile applicability must be assigned per material variant. It cannot be
derived automatically from repository name, feature family, or script owner.
The caller selects one of the two closed profiles and the engine independently
verifies that choice from canonical evidence.

## Snapshot mode and evidence source

`RepositorySnapshotMode` describes the evaluated subject repository. It is
separate from both evidence source and the exact engine/policy bundle identity:

- `exact-commit` reads the immutable commit tree and is eligible for
  authoritative comparison;
- `candidate` applies the accepted HEAD/index/worktree precedence and can emit
  provisional `CSharpShadow` evidence only;
- `RepositorySnapshot` identifies repository bytes;
- `SyntheticFixture` identifies project-neutral constructed inputs;
- `WorkflowDefinitionAtCommit` identifies a workflow blob at an exact commit;
- `ImmutableRelease` identifies released package/content evidence;
- `CapturedProviderEvidence` identifies a bounded immutable provider capture;
  and
- `ProcessRuntime` identifies execution/transport behavior that is not a pure
  repository rule.

An unreleased engine/policy bundle is bound by exact source commits, catalog
digest, and application artifact digest and remains shadow-only. An immutable
release manifest binds the consumer-eligible bundle. Selecting a candidate
subject snapshot never permits an implicit candidate policy.

| Planned route | Profile treatment | Typical source | v1 authority treatment |
| --- | --- | --- | --- |
| `CSharpCandidate` | Explicit variant-level `protocol-authority`, `consumer`, or both | `RepositorySnapshot`, `SyntheticFixture`, and when required `WorkflowDefinitionAtCommit` or `ImmutableRelease` | Later differential evidence required; applicable production governance authority remains PowerShell |
| `MixedBoundary` | Undetermined until variant split | More than one source kind | Fail closed as unmapped |
| `PowerShellOperationalRetained` | Not a [FEAT-0060](README.md) rule transfer | `ProcessRuntime`, provider operation, or mutation fixture | Retain PowerShell operational owner |
| `InfrastructureContract` | Not a governance profile rule | `ProcessRuntime`, workflow definition, runner, AST, or fixture topology | Retain infrastructure owner |
| `ExternalProvider` | Wholly outside repository-only v1 | `CapturedProviderEvidence` or live provider | Reasoned `NotApplicable` to v1 while existing verifier remains authoritative |
| `ExistingCSharpFoundation` | Shared application foundation, not a governance profile rule | Compiled test and `ImmutableRelease` | Reasoned `NotApplicable` / `AlreadyOwnedByCSharpFoundation`; reuse canonical evidence and do not duplicate it in [TEST-0196](test-cases.md#test-0196) |

Canonical evidence ownership and operational migration authority are different
fields. A PowerShell suite, GitHub Actions semantic contract, external verifier,
or .NET test project keeps its exact canonical evidence owner. Only a row that
participates in governance operational-capability migration receives an
`operationalAuthorityState`; applicable current rows remain
`PowerShellAuthority`.

Instruction-graph results preserve the immutable exact-commit rule from
[DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md).
A graph-relevant candidate result is incomplete and provisional; it cannot
become authority evidence.

## Mixed boundaries requiring variant keys

The 16 rows classified as `MixedBoundary` in the
[scenario-route analysis](scenario-route-analysis.csv) cannot safely receive
one rule/profile/source row.

Typical splits include pure validation versus mutation/rollback, local
repository grammar versus provider collection, and semantic contract versus
PowerShell process mechanics. The accepted material-variant rule must be
applied before any of these receives a final profile or disposition.

## Finding and severity gap

The 43 candidate scenarios currently assert pass/fail behavior through strings
and assertions. They do not provide a complete canonical mapping to both a
stable finding code and severity. Neither severity nor enforcement may be
inferred from prose, test names, or current failure messages.

The recommended v1 contract is recorded in the
[decision packet](contract-decision-packet.md): severity uses
`critical`, `high`, `medium`, `low`, or `info`; enforcement remains a separate
concept; every v1 violation is blocking; and a missing rule severity yields an
`incomplete` report.

## Completion boundary

This analysis supplies a complete scenario-level family and route matrix but
does not satisfy the variant-level Definition-of-Ready item. Completion
requires accepted variant granularity, stable variant keys for the 16 mixed
identities and every other material inline/generative branch, and canonical
finding/severity assignments. No C# equivalence or stronger-evidence claim is
made here.
