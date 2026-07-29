# [SUBF-0152](README.md#subf-0152) - Protocol Domain Vocabulary Design

| Field | Value |
| --- | --- |
| Classification | Subfeature / first dependency-closed [FEAT-0065](README.md) implementation slice |
| Status | Gate 2 complete; Gate 3 expected-red pending |
| Parent | [FEAT-0065](README.md) |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Decision | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) |
| Test | [TEST-0220](test-cases.md#test-0220) |

## Directive and boundary

The maintainer's 2026-07-29 directive authorizes only this bounded, test-first
slice. The accepted architecture is merged and its exact tree passed the
[main validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).
The durable authority is recorded in the
[scoped directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932)
and its narrow [infrastructure-contract clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847).

This subfeature establishes the vocabulary that later protocol-owned rule,
evidence, evaluator, and report contracts consume unchanged in meAndAI and in
consumers. It does not evaluate a rule or acquire, serialize, publish, or
mutate anything.

## Scope

- A new BCL-only `MeAndAI.Protocol.Domain` assembly and a side-by-side
  `MeAndAI.Protocol.slnx` build root.
- Exact `RuleId`, positive `RuleRevision`, and exact SHA-256 value types.
- Closed values for every independent execution-profile axis.
- Immutable `SurfaceSet` and `ExecutionProfile` values.
- Four distinct acquisition, rule-evaluation, conformance, and enforcement
  vocabularies.
- One canonical .NET test owner and explicit Ubuntu/Windows workflow route for
  [TEST-0220](test-cases.md#test-0220).

## Non-goals

- Rule descriptors, catalogs, evaluators, parsers, applicability, aggregation,
  or qualification of RULE-0001 through RULE-0005.
- Evidence requirements, acquisition envelopes, typed locations, findings, or
  rule-evaluation records.
- Canonical report construction, JSON, encoding, ordering, redaction, or
  digest computation.
- Debt, waiver, extension, activation, self-consumption, grants, or authority.
- Git, filesystem, GitHub, process, native, host, CLI, package, publication,
  release, mutation, or governance-workflow behavior. Registering
  [TEST-0220](test-cases.md#test-0220) in the two existing stable validation
  jobs is test ownership, not product
  workflow authority.
- Compatibility aliases or implicit conversions from `MeAndAI.Operations.*`
  or the preserved WIP branch.

## Dependency and consumer flow

```text
validated literal or numeric input
    -> exact domain constructor / Parse / TryParse
    -> immutable protocol-domain value
    -> future evidence, rule, evaluator, and report contracts
```

There is no adapter or I/O boundary in this task. `MeAndAI.Protocol.Domain`
has no project or package references. The test project has only the Domain
project reference and the centrally versioned xUnit test packages.

```text
MeAndAI.Protocol.slnx
|- src/MeAndAI.Protocol.Domain/MeAndAI.Protocol.Domain.csproj
`- tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj
```

`MeAndAI.Operations.slnx` remains unchanged. Empty placeholder projects for
Conformance, Policy, Application, Infrastructure, or hosts are prohibited.

## Exact public API and semantic contract

Every type below is in `MeAndAI.Protocol.Domain`. All text comparison and hash
input interpretation are ordinal and ASCII-exact. Input is never trimmed,
case-folded, Unicode-normalized, or accepted through an alias. Public parameter
names in the signatures below are source API. Exception type and invalid-input
category are behavioral contracts; exception message text, `ParamName`, private
member layout, constructor implementation, and compiler-generated shape are
not compatibility or [TEST-0220](test-cases.md#test-0220) oracles.

`RuleId`, `RuleRevision`, and `ExactSha256Digest` are public sealed reference
value types with no public constructor and these exact members:

```csharp
public sealed class RuleId : IEquatable<RuleId>, IComparable<RuleId>
{
    public string Value { get; }
    public static RuleId Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out RuleId? result);
    public int CompareTo(RuleId? other);
    public bool Equals(RuleId? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class RuleRevision : IEquatable<RuleRevision>, IComparable<RuleRevision>
{
    public int Value { get; }
    public static RuleRevision Create(int value);
    public int CompareTo(RuleRevision? other);
    public bool Equals(RuleRevision? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class ExactSha256Digest : IEquatable<ExactSha256Digest>,
    IComparable<ExactSha256Digest>
{
    public string Value { get; }
    public static ExactSha256Digest Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExactSha256Digest? result);
    public static ExactSha256Digest FromHashBytes(ReadOnlySpan<byte> hashBytes);
    public int CompareTo(ExactSha256Digest? other);
    public bool Equals(ExactSha256Digest? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}
```

`NotNullWhenAttribute` is the BCL
`System.Diagnostics.CodeAnalysis.NotNullWhenAttribute`. `CompareTo(null)`
returns `1`. Equality and hash behavior use the declared semantic value;
no exact integer hash code is stable across processes. Identity and digest
`ToString()` return exact `Value`; `RuleRevision.ToString()` returns invariant
ASCII base-10 `Value` with no sign or leading zero.

| Type | Valid semantic domain | Error and ordering behavior |
| --- | --- | --- |
| `RuleId` | Exact ASCII `RULE-0001` through `RULE-9999` | `Parse(null)` throws `ArgumentNullException`; malformed, non-ASCII, wrong-case, padded, or `RULE-0000` input throws `FormatException`; `TryParse` returns `false` and null; fixed-width ordinal order. Parsing validates syntax/range only and does not allocate a rule or prove catalog membership. |
| `RuleRevision` | Positive `int`, including `1` through `Int32.MaxValue` | `Create(0)` and negative values throw `ArgumentOutOfRangeException`; numeric order; no implicit conversion or `Next`. |
| `ExactSha256Digest` | Exactly 64 lowercase ASCII hexadecimal characters, or exactly 32 already-computed hash bytes | `Parse(null)` throws `ArgumentNullException`; malformed text throws `FormatException`; `TryParse` returns `false` and null; a span with length other than 32 throws `ArgumentException`; ordinal order. `FromHashBytes` only encodes bytes and performs no hashing or I/O; `ReadOnlySpan<byte>` has no null state. |

Each closed categorical value below is a public sealed reference value type
with no public constructor, implements `IEquatable<T>`, and exposes exactly
`string Value`, the named static properties below, `Parse(string value)`,
`TryParse(string? value, [NotNullWhen(true)] out T? result)`, value equality,
`GetHashCode`, and `ToString`. It does not implement comparison or define
implicit/explicit numeric or string conversions. `Parse(null)` throws
`ArgumentNullException`; an unknown token throws `ArgumentOutOfRangeException`;
`TryParse` returns `false` and null. Parsing a declared token returns the
corresponding named value; `ToString()` returns exact `Value`; singleton
reference identity is not a contract.

| Type | Named static property = exact token |
| --- | --- |
| `SubjectRole` | `ProtocolAuthoritySelfConsumer` = `protocol-authority-self-consumer`; `Consumer` = `consumer` |
| `ProtocolOperation` | `Conformance` = `conformance`; `AdoptionAssessment` = `adoption-assessment`; `AdoptionPlan` = `adoption-plan`; `AdoptionApply` = `adoption-apply`; `UpdateAssessment` = `update-assessment`; `UpdatePlan` = `update-plan`; `UpdateApply` = `update-apply`; `Publication` = `publication`; `Finalization` = `finalization`; `Recovery` = `recovery` |
| `SnapshotKind` | `ExactCommit` = `exact-commit`; `Candidate` = `candidate`; `ProviderEvent` = `provider-event`; `ProviderFullInventory` = `provider-full-inventory`; `CapturedEvidence` = `captured-evidence` |
| `SurfaceKind` | `Repository` = `repository`; `Provider` = `provider`; `Workflow` = `workflow`; `Release` = `release` |
| `EnforcementPhase` | `Audit` = `audit`; `Prospective` = `prospective`; `FullBlocking` = `full-blocking` |
| `AcquisitionStatus` | `Complete` = `complete`; `Incomplete` = `incomplete`; `Failed` = `failed` |
| `RuleEvaluationStatus` | `Satisfied` = `satisfied`; `Violated` = `violated`; `NotApplicable` = `not-applicable`; `NotEvaluated` = `not-evaluated` |
| `ConformanceVerdict` | `Conforming` = `conforming`; `NonConforming` = `non-conforming`; `Indeterminate` = `indeterminate`; preserved-WIP `nonconforming` is invalid |
| `EnforcementDecision` | `Allow` = `allow`; `Block` = `block`; `ReportOnly` = `report-only` |

The categorical families are deliberately not C# enums: undefined numeric
casts, invalid default numeric values, accidental numeric precedence, and
serializer-dependent numeric wire values must not become domain states. Tests
prove the public token/factory/equality/no-conversion behavior; they do not
assert private constructors or record/compiler-generated implementation.

### SurfaceSet

`SurfaceSet` is a public sealed reference value type implementing
`IEquatable<SurfaceSet>`. It has no public constructor and exposes exactly
`IReadOnlyList<SurfaceKind> Values`,
`Create(IEnumerable<SurfaceKind> surfaces)`, value equality, `GetHashCode`, and
`ToString`. `Create` enumerates and materializes a defensive copy. A null
`surfaces` reference throws `ArgumentNullException`; empty input, a runtime null
member, or a duplicate semantic value throws `ArgumentException`. Values are
exposed through a read-only view in explicit schema-1 order `repository`,
`provider`, `workflow`, `release`; neither input enumeration order nor later
caller mutation affects the instance, equality, or hash behavior. No default
or all-surfaces instance exists. `ToString` joins canonical tokens with `,` and
no whitespace.

### ExecutionProfile

`ExecutionProfile` is a public sealed reference value type implementing
`IEquatable<ExecutionProfile>`, with no public constructor and this exact API:

```csharp
public SubjectRole SubjectRole { get; }
public ProtocolOperation Operation { get; }
public SnapshotKind SnapshotKind { get; }
public SurfaceSet Surfaces { get; }
public EnforcementPhase EnforcementPhase { get; }
public static ExecutionProfile Create(
    SubjectRole subjectRole,
    ProtocolOperation operation,
    SnapshotKind snapshotKind,
    SurfaceSet surfaces,
    EnforcementPhase enforcementPhase);
public bool Equals(ExecutionProfile? other);
public override bool Equals(object? obj);
public override int GetHashCode();
```

Each null argument throws `ArgumentNullException`; all structural combinations
are otherwise constructible. The five values are retained as independent
read-only axes. Named-profile authority, applicability, adapter capability,
evidence state, outcome, and grants are not profile fields and cannot be
inferred during construction. `ExecutionProfile` deliberately has no canonical
text or serialization method in this slice.

## Compatibility

This is an additive new assembly. Existing `OperationStageId`,
`OperationalAuthorityGrant`, WIP `GovernanceProfileId`, WIP verdicts, and CLI
tokens are different contracts and receive no conversion, alias, or fallback.
Changing a public token, value set, numeric range, or equality rule after the
first immutable protocol release is schema and release compatibility work.

## Prior art and WIP disposition

Same-contract inventory:

- [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191)
  and [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
  own the existing Operations foundation graph and
  typed-operation boundaries; they do not own protocol conformance vocabulary.
- Preserved [TEST-0194](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194)
  is a host scenario and is not a scalar-domain sibling.
- Preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195)
  is a bounded repository-model oracle; its repository-only
  profile and collapsed report types are rejected.
- Preserved `ExactGitCommitId`, `ExactSha256Digest`, and `ProtocolVersion`
  implementations are behavior-discovery input only. No source, project,
  namespace, lock file, friend-assembly rule, or passing WIP evidence is
  carried forward.

The selected implementation starts from fresh tests and a fresh target
assembly. Normative RULE inventory and normative-fragment digests are
`NotApplicable` to [SUBF-0152](README.md#subf-0152) and remain owned by
[SUBF-0143](README.md#subf-0143).

## Distinct test intent

[TEST-0220](test-cases.md#test-0220) is `Distinct` from
[TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191),
[TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192),
[TEST-0194](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194),
[TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195),
and the full [FEAT-0065](README.md) [TEST-0209](test-cases.md#test-0209)
scenario. Its tuple is scalar invalid-state and
axis-separation risk, Domain-only scope, unit/architecture evidence, and the
new protocol build root. [TEST-0209](test-cases.md#test-0209) remains a planned composed production
qualification scenario; it cannot use child-test pass results as its oracle.

[TEST-0220](test-cases.md#test-0220) covers:

- exact positive, negative, null, wrong-case, non-ASCII, padding, and boundary
  cases for every scalar;
- RuleId `0001`/`9999`, RuleRevision `1`/`Int32.MaxValue`, and SHA-256 64-char
  and 32-byte boundaries;
- categorical exact-token/factory/equality behavior, absence of numeric or
  cross-dimension conversions, and rejection of other dimensions' tokens;
- SurfaceSet empty/null/duplicate rejection, all 24 input permutations,
  canonical order, equality, and defensive copying;
- ExecutionProfile axis independence, null rejection, structural equality, and
  an executable public-surface assertion that its readable instance properties
  are exactly the five declared axes with no authority, applicability,
  capability, evidence, outcome, or grant member; and
- a project-graph assertion proving the Domain project is BCL-only and the
  test project references only Domain plus test infrastructure.

It does not assert singleton reference identity, exact hash-code integers,
private-member shape, exception messages, aggregation, serialization, or
future report bytes.

## Recurrence review

- Same-contract active recurrence: explicit `None` for this pure domain
  vocabulary.
- Human-facing commit evidence must use an exact full-SHA GitHub permalink.
- Exact closure requires the complete graph-reachable governance packet to be
  committed before exact-HEAD validation on PowerShell 7 and Windows
  PowerShell 5.1.
- Dynamic, native, AST, and process-helper recurrence routes are
  `NotApplicable`; this task moves no such helper.

Memory is routing evidence only. [TEST-0220](test-cases.md#test-0220) is the executable recurrence
barrier.

## Canonical execution route

The implementation change must atomically:

1. create fresh Domain and Domain.Tests projects plus lock files;
2. add `MeAndAI.Protocol.slnx` without changing Operations solution contents;
3. add locked protocol restore and [TEST-0220](test-cases.md#test-0220) steps inside both existing stable
   workflow jobs without adding a job, path filter, or trigger change; and
4. move only [TEST-0220](test-cases.md#test-0220) from planned documentation to the Domain.Tests owner
   after its focused green result. Existing planned scenarios remain planned;
   and
5. extend the existing [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
   workflow-topology owner to assert that both stable jobs retain the exact
   protocol locked-restore command, Domain.Tests invocation, and
   [TEST-0220](test-cases.md#test-0220)
   filter under the existing `Full` route.

[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) is the
`InfrastructureContract` for [TEST-0220](test-cases.md#test-0220) discovery and
hosted invocation. It directly inspects workflow structure and does not invoke
[TEST-0220](test-cases.md#test-0220), read its
source/assertion text, or use its result as product-behavior evidence. No new
numbered scenario or second workflow registry is introduced.
Its mutation authority is limited by the
[infrastructure clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847).

Expected-red and focused-green use the same command after a fresh restore:

```powershell
$scenarioId = 'TEST-' + '0220'
dotnet test tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj `
  --configuration Release `
  --no-restore `
  --nologo `
  --verbosity minimal `
  --filter "Scenario=$scenarioId"
```

The first project graph generates fresh locks, then every proof uses locked
restore. Because the repository now has two root solutions, every build and
format command names the protocol solution explicitly:

```powershell
dotnet restore MeAndAI.Protocol.slnx --configfile NuGet.Config --force-evaluate
dotnet restore MeAndAI.Protocol.slnx --configfile NuGet.Config --locked-mode
dotnet build MeAndAI.Protocol.slnx --configuration Release --no-restore --nologo
dotnet format MeAndAI.Protocol.slnx --verify-no-changes --severity info --no-restore
```

The first run must fail only because the declared protocol-domain contracts
are absent. Production types are then implemented in the smallest coherent
files. Focused green, locked restore, zero-warning Release build, format,
fresh-diff review, repository structural validation, and the two hosted stable
jobs are required; no result is inferred before it exists.

## Gate 2 findings

| ID | Observation | Disposition |
| --- | --- | --- |
| [FIND-0365](README.md#find-0365) | [SUBF-0142](README.md#subf-0142) and [TEST-0209](test-cases.md#test-0209) mixed scalar, evidence, report, serialization, and debt/waiver contracts. | `Blocking`, resolved in design by [SUBF-0152](README.md#subf-0152)/[TEST-0220](test-cases.md#test-0220) and later dependency-closed owners while preserving [TEST-0209](test-cases.md#test-0209) as a true feature-level composed scenario. |
| [FIND-0366](README.md#find-0366) | The stable workflow runs only the Operations solution, so a new protocol test could compile locally yet never execute in hosted validation. | `Blocking`, resolved in design by the exact two-job execution route above plus the direct [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) infrastructure contract; executable closure is part of [SUBF-0152](README.md#subf-0152). |
| [FIND-0367](README.md#find-0367) | The accepted architecture said no RULE IDs were allocated while its accepted successor matrix allocated [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001), [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002), [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003), [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004), and [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005). | `Blocking`, resolved by the planning correction in the same Gate 2 packet; it grants no evaluator or digest authority. |
| [FIND-0368](README.md#find-0368) | [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001), [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002), [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003), [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004), and [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005) links resolve, but rule-specific fragment selectors, canonical bytes, and exact digests are not ready; [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002) has conflicting required-structure authorities. | `ExternalOrLegacyFollowUp`, owned by [SUBF-0143](README.md#subf-0143) and [issue #165](https://github.com/hasanmanzak/meAndAI/issues/165); blocking before the first catalog/evaluator slice, not [SUBF-0152](README.md#subf-0152). |
| [FIND-0369](README.md#find-0369) | The original directive and active instruction graph still named the mixed predecessor boundary and withheld all workflow changes. | `Blocking`, resolved by the corrected scoped directive and synchronized transition/successor/memory surfaces. |
| [FIND-0370](README.md#find-0370) | Public signatures, nullability, collection exposure, and error categories were incomplete while private implementation details leaked into the proposed oracle. | `Blocking`, resolved by the [exact public API](#exact-public-api-and-semantic-contract) and observable [TEST-0220](test-cases.md#test-0220) boundary. |
| [FIND-0371](README.md#find-0371) | Mixed-slice successor ownership, future dependency edges, and [TEST-0221](test-cases.md#test-0221) sibling review were incomplete. | `Blocking`, resolved in the feature ledger and test matrix; later slices remain unauthorized. |
| [FIND-0372](README.md#find-0372) | [TEST-0209](test-cases.md#test-0209) collapsed incomplete acquisition and non-conforming verdict into one outcome phrase. | `Blocking`, resolved by restoring the four independent dimensions and accepted precedence in [TEST-0209](test-cases.md#test-0209). |
| [FIND-0373](README.md#find-0373) | Future [TEST-0221](test-cases.md#test-0221) wording could imply a fourth acquisition status for absence. | `ExternalOrLegacyFollowUp`; clarified as an input fact that rolls up to `Incomplete`, with full envelope semantics still owned by [SUBF-0153](README.md#subf-0153). |

Gate 2 result: [SUBF-0152](README.md#subf-0152) is dependency-closed and ready
for Gate 3. [SUBF-0153](README.md#subf-0153),
[SUBF-0143](README.md#subf-0143), [SUBF-0144](README.md#subf-0144),
[SUBF-0154](README.md#subf-0154), and all other [FEAT-0065](README.md)
implementation remain unauthorized.
