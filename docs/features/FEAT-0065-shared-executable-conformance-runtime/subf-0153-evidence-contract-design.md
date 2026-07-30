# [SUBF-0153](README.md#subf-0153) - Evidence Acquisition Contract Design

| Field | Value |
| --- | --- |
| Classification | Subfeature / second dependency-closed [FEAT-0065](README.md) design slice |
| Status | Gate 2 design candidate; bounded red-team clean; maintainer acceptance, merge, exact-main validation, typed-handoff Gate 2 closure, and a separate implementation directive are pending |
| Parent | [FEAT-0065](README.md) |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Decision | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) |
| Test | [TEST-0221](test-cases.md#test-0221) |
| Exact-main baseline | [c31819487e77fc878fc40fae6445bfef582719da](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da) |
| Design authority | [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253) |

## Directive and hard boundary

The maintainer authorized Gate 1 and Gate 2 architecture design and
expected-red planning for [SUBF-0153](README.md#subf-0153) and
[TEST-0221](test-cases.md#test-0221) only. This packet defines the acquisition
and evidence substrate, its exact public contract, construction invariants,
project and test ownership, prior-art dispositions, and future verification
route.

It does **not** authorize C# source or executable-test implementation, project
or package changes, lock-file changes, workflow changes, scenario-ownership
changes, expected-red execution, WIP extraction, provider or consumer
mutation, release work, publication, authority transfer, or PowerShell
retirement.

The continuation chain is normative:

1. review and accept this exact design;
2. merge the complete design packet;
3. validate the merged exact-main commit;
4. review/accept, merge, and exact-main validate the separately authorized
   [SUBF-0143](README.md#subf-0143) typed-handoff Gate 2 packet;
5. receive a separate, explicitly scoped implementation directive; and only
6. enter Gate 3 expected red.

No earlier step implies a later one. A draft pull request, design validation,
or the word “continue” is not implementation authority.

[SUBF-0152](README.md#subf-0152) is the completed predecessor. Its existing
RuleId, RuleRevision, ExactSha256Digest, SurfaceKind, SnapshotKind,
AcquisitionStatus, and RuleEvaluationStatus values remain unchanged.

Every future executable contract described here is implemented in C#.
Markdown is the reviewed specification, not a second rule engine.

## Gate 2 outcome

This slice creates one BCL-only protocol-domain substrate for:

- rule-declared evidence requirements and their schema contracts;
- an exact post-routing acquisition request;
- requested target versus observed boundary identity;
- subject/source-safe repository, provider, release, and snapshot locations;
- schema-identified bytes asserted canonical by an untrusted carrier and
  structurally sealed bindings;
- requirement-scoped completeness, consistency, redaction, and failures;
- paged and non-paged acquisition contexts; and
- a closed Complete/Incomplete/Failed acquisition-result union.

This revision deliberately removes RuleFinding and RuleEvaluation from
[SUBF-0153](README.md#subf-0153). A metadata-only Domain factory cannot prove catalog membership,
applicability, typed-model membership, or evaluation closure. Those records
belong to [SUBF-0143](README.md#subf-0143) and
[TEST-0210](test-cases.md#test-0210), together with the immutable catalog,
release-bound decoders, sealed typed-model context, evaluator kernel, and
evaluation-failure semantics.

The values are identical for meAndAI self-consumption and consumer execution.
Only the acquired evidence and selected applicable rules differ. Rules never
call an adapter, and consumers never copy these contracts or validators.

## Project and dependency allocation

Every type in SliceInventory belongs to the existing
MeAndAI.Protocol.Domain assembly. The slice adds no project, solution entry,
package, lock file, friend assembly, or dependency.

The downstream ownership graph is:

1. [SUBF-0143](README.md#subf-0143) release-bound catalog declaration
2. EvidenceRequirement values
3. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) post-routing acquisition and normalization
4. AcquisitionResult closed union + EvidenceContext
5. [SUBF-0143](README.md#subf-0143) SealedEvaluationContext
   (release/artifact-bound decode cache; separate context/location index cache)
6. [SUBF-0143](README.md#subf-0143) common C# evaluator
7. [SUBF-0143](README.md#subf-0143) RuleFinding / RuleEvaluation
8. [SUBF-0154](README.md#subf-0154) canonical report closure and serialization

Domain owns immutable transport semantics and local invalid-state prevention.
[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
owns Git, filesystem, provider, release, paging, convergence, adapter, source
API, and evidence-schema qualification. [SUBF-0143](README.md#subf-0143) owns semantic catalog
membership, typed decoders/models, applicability, evaluation, and aggregation.
[SUBF-0154](README.md#subf-0154) owns report bytes and report digests.

The apparent [SUBF-0153](README.md#subf-0153)/[SUBF-0143](README.md#subf-0143) dependency is resolved at gate level:

1. accepted, merged, and exact-main-validated [SUBF-0153](README.md#subf-0153) Gate 2 acquisition
   design feeds [SUBF-0143](README.md#subf-0143) typed-handoff Gate 2;
2. accepted, merged, and exact-main-validated [SUBF-0143](README.md#subf-0143) typed-handoff Gate 2 is
   required before [SUBF-0153](README.md#subf-0153) Gate 3;
3. completed [SUBF-0153](README.md#subf-0153) implementation is then required before [SUBF-0143](README.md#subf-0143) Gate 3.

No implementation dependency cycle exists, and neither slice may skip its
design prerequisite.

## Scope

- Open, namespaced requirement, completeness, adapter, source-contract,
  payload-schema, and failure-code tokens with explicit semantic owners.
- A requested AcquisitionTarget and observed AcquisitionBoundary joined by an
  exact EvidenceScope.
- One request per routed target/surface and exact adapter/source-contract
  endpoint identity. SourceContractKey/Version identifies one endpoint and one
  cursor grammar; multiple endpoints use distinct source-contract identities
  and separate requests/results.
- Schema-identified payload bytes asserted canonical by an untrusted carrier,
  derived SHA-256 content identity, typed locations, structurally sealed
  bindings, and context-minted root references.
- Exact per-requirement acquisition state and caller-independent context/result
  status.
- Paged, interrupted-paged, and non-paged observation without cursor leakage.
- Closed result variants for observed, absent, and failed acquisition.
- Exact [TEST-0221](test-cases.md#test-0221) expected-red, inventory transition, and future hosted route.

## Non-goals

- RuleFinding, RuleEvaluation, evaluation-failure, applicability, evaluator,
  catalog, parser, typed-model, aggregation, verdict, enforcement, waiver,
  debt, or report implementation.
- Provider DTOs, arbitrary objects, raw JSON contracts, response bodies, raw
  cursors, raw ETags, credentials, exceptions, or HTTP status enums.
- Filesystem, Git, HTTP, SDK, provider, retry, rate-limit, clock, parser,
  normalization, or convergence implementation.
- Consumer-provided executable plugins, reflection/DI discovery of consumer
  evaluators, or consumer-owned payload decoders.
- Report construction, canonical report JSON/bytes, report stable keys,
  publication digests, messages, localization, or remediation links.
- CLI grammar, process exits, workflow dispatch, adoption, update, release,
  publication, mutation, or authority transfer.

## Inventory-derived ownership terms

- PredecessorInventory is the exact public Domain-type inventory owned by
  [TEST-0220](test-cases.md#test-0220) at the accepted predecessor commit.
- SliceInventory is the exact public-type list declared by this document at
  the accepted Gate 2 head.
- CumulativeInventory is the ordinal set union of PredecessorInventory and
  SliceInventory.

The enumerated lists are normative; separately handwritten type counts are
not. [TEST-0221](test-cases.md#test-0221) derives the expected cumulative count from the lists. Any
SliceInventory change before Gate 2 acceptance must update the public API,
expected-red matrix, ownership transition, WIP disposition, feature record,
test record, and memory handoff together.

## Open vocabulary and semantic owners

The following ASCII token grammar is shared by requirement keys/kinds,
completeness contracts, adapter keys, source-contract keys, payload-schema
keys, and acquisition-failure codes:

~~~text
segment0  = [a-z][a-z0-9]*(?:-[a-z0-9]+)*
segmentN  = [a-z0-9]+(?:-[a-z0-9]+)*
token     = segment0 "." segmentN ("." segmentN)*
length    = 3..128 UTF-16 code units
~~~

At least one dot is required. Inputs are never trimmed, case-folded,
Unicode-normalized, or accepted through aliases. Syntactically valid unknown
tokens remain constructible; construction grants no semantic authority.

Semantic ownership is exact:

| Token | Owner |
| --- | --- |
| EvidenceRequirement.Key, Kind, CompletenessContract | [SUBF-0143](README.md#subf-0143) immutable rule catalog |
| EvidenceRequirement.PayloadSchemaKey/Version | one [SUBF-0143](README.md#subf-0143) immutable release schema registry; [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) consumes it to qualify adapter output |
| AcquisitionRequest.AdapterKey/ContractVersion | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) adapter registry and qualification |
| AcquisitionRequest.SourceContractKey/Version | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) source API/schema registry and qualification |
| AcquisitionFailure.Code | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) adapter/evidence-schema contract, never the rule catalog |
| ProviderEvidenceLocation.ObjectType | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) provider-surface/schema registry; Domain owns syntax/immutability only |
| Future finding/evaluation-failure codes | [SUBF-0143](README.md#subf-0143) rule/evaluator catalog |

Version text accepts SemVer and provider API forms:

~~~text
version = [A-Za-z0-9][A-Za-z0-9._+-]{0,127}
~~~

It is preserved exactly and semantically interpreted only by its owner.

Every opaque identity is 1 through 2048 UTF-16 code units, is well-formed
UTF-16, and rejects leading/trailing whitespace, controls, NUL, and unpaired
surrogates. Paths and refinements have their narrower rules below.

## Exact public API conventions

All types are in MeAndAI.Protocol.Domain. The C# blocks use signature notation:
a semicolon denotes a concrete method body unless the abstract keyword is
present. Public parameter names and nullability are source API.

Every sealed non-union composite implements IEquatable<T> and, in addition to
the members shown below, declares exactly:

~~~csharp
public bool Equals(T? other);
public override bool Equals(object? obj);
public override int GetHashCode();
~~~

Every collection is enumerated exactly once into a defensive immutable
snapshot and exposed as IReadOnlyList<T>. No composite has a public constructor
or setter. No type exposes mutable collections, ToString other than closed
categorical values, conversions, deconstruction, serializer attributes, or a
public comparison interface.

Exception type and invalid-input category are observable. Message text,
ParamName, exact hash integers, private layout, factory implementation, and
singleton reference identity are not compatibility or [TEST-0221](test-cases.md#test-0221) oracles.

## Exact SliceInventory

The following list is normative and ordered ordinally for the assembly-export
oracle:

~~~text
AbsentAcquisitionResult
AcquisitionBoundary
AcquisitionFailure
AcquisitionPage
AcquisitionRequest
AcquisitionResult
AcquisitionTarget
CanonicalEvidencePayload
EvidenceBinding
EvidenceConsistencyClass
EvidenceContext
EvidenceLocation
EvidenceRedaction
EvidenceRequirement
EvidenceScope
FailedAcquisitionResult
ObservedAcquisitionResult
ProviderEvidenceLocation
ReleaseAssetEvidenceLocation
RepositoryEvidenceLocation
RequirementAcquisition
RootEvidenceReference
SnapshotEvidenceLocation
~~~

RuleFinding, FindingSeverity, RuleEvaluationInput, RuleEvaluationFailure, and
RuleEvaluation are explicitly **not** in SliceInventory. Their exact API and
implementation are a [SUBF-0143](README.md#subf-0143)/[TEST-0210](test-cases.md#test-0210) Gate 2 obligation.

## Requirement, target, boundary, and request

~~~csharp
public sealed class EvidenceRequirement : IEquatable<EvidenceRequirement>
{
    public string Key { get; }
    public SurfaceKind Surface { get; }
    public string Kind { get; }
    public string CompletenessContract { get; }
    public string PayloadSchemaKey { get; }
    public string PayloadSchemaVersion { get; }
    public IReadOnlyList<EvidenceConsistencyClass> AcceptedConsistencyClasses { get; }

    public static EvidenceRequirement Create(
        string key,
        SurfaceKind surface,
        string kind,
        string completenessContract,
        string payloadSchemaKey,
        string payloadSchemaVersion,
        IEnumerable<EvidenceConsistencyClass> acceptedConsistencyClasses);
}

public sealed class EvidenceConsistencyClass :
    IEquatable<EvidenceConsistencyClass>
{
    public static EvidenceConsistencyClass ExactSnapshot { get; }
    public static EvidenceConsistencyClass ObjectVersionBound { get; }
    public static EvidenceConsistencyClass BoundedNonAtomicObservation { get; }
    public static EvidenceConsistencyClass InsufficientConsistency { get; }
    public string Value { get; }

    public static EvidenceConsistencyClass Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out EvidenceConsistencyClass? result);
    public override string ToString();
}

public sealed class AcquisitionTarget : IEquatable<AcquisitionTarget>
{
    public string SubjectIdentity { get; }
    public string SourceIdentity { get; }
    public SurfaceKind Surface { get; }
    public SnapshotKind SnapshotKind { get; }
    public string TargetIdentity { get; }

    public static AcquisitionTarget Create(
        string subjectIdentity,
        string sourceIdentity,
        SurfaceKind surface,
        SnapshotKind snapshotKind,
        string targetIdentity);
}

public sealed class AcquisitionBoundary : IEquatable<AcquisitionBoundary>
{
    public SnapshotKind SnapshotKind { get; }
    public string BoundaryIdentity { get; }
    public DateTimeOffset StartedAtUtc { get; }
    public DateTimeOffset CompletedAtUtc { get; }

    public static AcquisitionBoundary Create(
        SnapshotKind snapshotKind,
        string boundaryIdentity,
        DateTimeOffset startedAtUtc,
        DateTimeOffset completedAtUtc);
}

public sealed class EvidenceScope : IEquatable<EvidenceScope>
{
    public AcquisitionTarget Target { get; }
    public AcquisitionBoundary Boundary { get; }

    public static EvidenceScope Create(
        AcquisitionTarget target,
        AcquisitionBoundary boundary);
}

public sealed class AcquisitionRequest : IEquatable<AcquisitionRequest>
{
    public AcquisitionTarget Target { get; }
    public string AdapterKey { get; }
    public string AdapterContractVersion { get; }
    public string SourceContractKey { get; }
    public string SourceContractVersion { get; }
    public IReadOnlyList<EvidenceRequirement> RequestedRequirements { get; }

    public static AcquisitionRequest Create(
        AcquisitionTarget target,
        string adapterKey,
        string adapterContractVersion,
        string sourceContractKey,
        string sourceContractVersion,
        IEnumerable<EvidenceRequirement> requestedRequirements);
}
~~~

EvidenceConsistencyClass has these exact wire values:

| Property | Value |
| --- | --- |
| ExactSnapshot | exact-snapshot |
| ObjectVersionBound | object-version-bound |
| BoundedNonAtomicObservation | bounded-non-atomic-observation |
| InsufficientConsistency | insufficient-consistency |

An EvidenceRequirement has at least one accepted consistency class. Nulls,
duplicates, and InsufficientConsistency are rejected. Values are ordered
ExactSnapshot, ObjectVersionBound, then BoundedNonAtomicObservation.

Every request has at least one requirement. Requirement keys are unique and
every requirement surface equals Target.Surface. Requirements are ordered by
key and then their remaining exact fields. Adapter/source contract metadata is
post-routing description, not capability.

Target and boundary identity rules are shared by every later location:

| SnapshotKind | TargetIdentity | BoundaryIdentity | Scope relation |
| --- | --- | --- | --- |
| ExactCommit | lowercase 40- or 64-hex Git object ID | same grammar | exact ordinal equality |
| Candidate | lowercase 64-hex SHA-256 capture identity | same grammar | exact ordinal equality |
| ProviderEvent | opaque provider delivery identity | lowercase 64-hex SHA-256 observed-event boundary | Domain enforces same kind; [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification proves the boundary frame contains this exact delivery target/source |
| ProviderFullInventory | opaque acquisition-plan identity | lowercase 64-hex SHA-256 convergence identity | Domain enforces same kind; [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification proves the convergence frame belongs to this exact plan target/source |
| CapturedEvidence | lowercase 64-hex SHA-256 capture identity | same grammar | exact ordinal equality |

The same kind-specific validation applies through AcquisitionTarget,
AcquisitionBoundary, EvidenceScope, and SnapshotEvidenceLocation. ExactCommit
can never carry an opaque non-Git identity. Both boundary timestamps have zero
offset and CompletedAtUtc is not earlier than StartedAtUtc.

For ProviderEvent and ProviderFullInventory, a public Domain factory cannot
cryptographically prove that opaque target A produced digest B. EvidenceScope
is an immutable untrusted assertion until [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) verifies the exact
release-bound adapter receipt/boundary frame, including request, target,
subject/source, adapter/source contract, delivery or plan identity, observed
object/convergence identities, and boundary digest. [SUBF-0143](README.md#subf-0143) accepts only that
qualified result. Structural construction alone grants no evidence authority.

SubjectIdentity names the repository/process being governed. SourceIdentity
names the repository/provider source from which evidence was acquired. They
may differ for an upstream protocol release, but the mapping is explicit in
the target and cannot change inside its scope.

Candidate is a two-stage [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) route: first freeze/capture HEAD, index,
worktree, and untracked inventory into an immutable capture manifest; then use
that manifest’s SHA-256 as AcquisitionTarget.TargetIdentity for the routed
request. The request never predicts a future candidate digest.

## Typed location family

~~~csharp
public abstract class EvidenceLocation : IEquatable<EvidenceLocation>
{
    private protected EvidenceLocation(EvidenceScope scope);
    public EvidenceScope Scope { get; }
    public bool Equals(EvidenceLocation? other);
    public sealed override bool Equals(object? obj);
    public sealed override int GetHashCode();
}

public sealed class RepositoryEvidenceLocation : EvidenceLocation
{
    public string RepositoryRelativePath { get; }
    public string? BlobIdentity { get; }
    public int? Line { get; }
    public string? Anchor { get; }
    public string? Property { get; }

    public static RepositoryEvidenceLocation Create(
        EvidenceScope scope,
        string repositoryRelativePath,
        string? blobIdentity,
        int? line,
        string? anchor,
        string? property);
}

public sealed class ProviderEvidenceLocation : EvidenceLocation
{
    public string ProviderServiceIdentity { get; }
    public string ObjectType { get; }
    public string StableObjectIdentity { get; }
    public string VersionIdentity { get; }
    public string? Field { get; }
    public int? Line { get; }
    public string? Fragment { get; }

    public static ProviderEvidenceLocation Create(
        EvidenceScope scope,
        string providerServiceIdentity,
        string objectType,
        string stableObjectIdentity,
        string versionIdentity,
        string? field,
        int? line,
        string? fragment);
}

public sealed class ReleaseAssetEvidenceLocation : EvidenceLocation
{
    public string ReleaseObjectIdentity { get; }
    public string Tag { get; }
    public string AssetName { get; }
    public ExactSha256Digest AssetDigest { get; }

    public static ReleaseAssetEvidenceLocation Create(
        EvidenceScope scope,
        string releaseObjectIdentity,
        string tag,
        string assetName,
        ExactSha256Digest assetDigest);
}

public sealed class SnapshotEvidenceLocation : EvidenceLocation
{
    public static SnapshotEvidenceLocation Create(EvidenceScope scope);
}
~~~

The private-protected base constructor and sealed leaves close the union. Base
equality is concrete, non-virtual structural dispatch across the four leaves;
leaves declare no Equals/GetHashCode overrides and cannot disagree between
leaf-typed and base-typed calls.

| Variant | Surface invariant | Refinement invariant |
| --- | --- | --- |
| Repository | scope target is Repository | path required; at most one of line/anchor/property; optional blob is lowercase 40/64-hex Git object ID |
| Provider | scope target is Provider or Workflow | field is required before line/fragment; line and fragment are exclusive |
| Release asset | scope target is Release | release, tag, asset, and exact SHA-256 digest are all required |
| Snapshot | any surface | identifies the exact whole scope when no narrower location exists |

Scope.Target.SourceIdentity is the governed source repository/resource.
ProviderServiceIdentity names the provider service/installation namespace and
ReleaseObjectIdentity names one release object; neither duplicates or replaces
SourceIdentity. “Foreign source” means a foreign EvidenceScope. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
qualifies the provider/release object-to-source mapping before authoritative
use.

Repository-relative paths use / only, contain 1 through 4096 code units, do
not start/end with /, and reject empty, dot, dot-dot, backslash, drive-prefix,
control, NUL, ill-formed UTF-16, and unpaired-surrogate segments. A line is
positive. Optional textual refinements use the opaque-value safety rules and
are preserved exactly. ObjectType uses the open-token grammar.

Because every leaf owns an EvidenceScope, Repository A cannot satisfy a
request for Repository B. A valid subject/source difference remains possible
only through the explicit target mapping.

## Canonical payload, binding, and reference

~~~csharp
public sealed class CanonicalEvidencePayload :
    IEquatable<CanonicalEvidencePayload>
{
    public string SchemaKey { get; }
    public string SchemaVersion { get; }
    public ExactSha256Digest ContentDigest { get; }
    public IReadOnlyList<byte> CanonicalBytes { get; }

    public static CanonicalEvidencePayload Create(
        string schemaKey,
        string schemaVersion,
        IEnumerable<byte> canonicalBytes);
}

public sealed class EvidenceBinding : IEquatable<EvidenceBinding>
{
    public CanonicalEvidencePayload Payload { get; }
    public EvidenceLocation Location { get; }
    public IReadOnlyList<string> RequirementKeys { get; }
    public DateTimeOffset CapturedAtUtc { get; }

    public static EvidenceBinding Create(
        CanonicalEvidencePayload payload,
        EvidenceLocation location,
        IEnumerable<string> requirementKeys,
        DateTimeOffset capturedAtUtc);
}

public sealed class RootEvidenceReference :
    IEquatable<RootEvidenceReference>
{
    public EvidenceScope Scope { get; }
    public string SchemaKey { get; }
    public string SchemaVersion { get; }
    public ExactSha256Digest ContentDigest { get; }
    public EvidenceLocation Location { get; }
    public IReadOnlyList<string> RequirementKeys { get; }
    public DateTimeOffset CapturedAtUtc { get; }
}
~~~

CanonicalEvidencePayload is a schema-identified byte sequence whose carrier
asserts canonicality, not a provider DTO or evaluator-facing arbitrary object.
Its factory copies the bytes once and derives ContentDigest from those exact
bytes; the caller cannot supply or override the digest. Construction alone
does not verify schema membership or canonical encoding. Empty bytes are
structurally valid; authoritative use requires the qualified release schema to
permit them.

The schema key/version is meaningful only when the immutable release binds it
to one qualified decoder/model. Unknown syntax-valid schemas may be transported
for forward compatibility but cannot enter authoritative evaluation.

An EvidenceBinding has at least one unique requirement key, derives its scope
from Location, requires a zero-offset CapturedAtUtc inside the inclusive
boundary interval, and sorts keys ordinally. RequirementKeys are a membership
projection, not part of physical evidence identity. Before context construction,
the acquisition route must place every contributing requirement key into the
single binding it creates for that physical evidence.

Domain construction seals the exact asserted tuple; it does not prove that
payload bytes truthfully describe the asserted source object. Publicly created
Domain values are untrusted carriers. Authoritative evaluation accepts only a
result from the exact release-bound [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) acquisition route after the
qualified schema codec has verified canonical encoding, embedded object/version
identity, resource limits, and semantic coherence with Location. A digest
cannot turn an unqualified adapter assertion into evidence authority.

RootEvidenceReference has no public constructor or factory. EvidenceContext mints
one root reference for each exact member binding. A root reference copies only
the binding’s safe structural identity fields and content digest; it does not
retain CanonicalBytes.

Parser-discovered line, anchor, fragment, property, node, or related-object
references are intentionally not minted by the acquisition adapter. The
future [SUBF-0143](README.md#subf-0143) SealedEvaluationContext must mint a separate
DerivedEvidenceReference from one
root reference, a qualified decoder/parser artifact, typed node/span identity,
and a same-or-narrower validated Location. That future reference contract is a
mandatory Gate 2 prerequisite, not part of SliceInventory.

Canonical payload bytes never enter reports. [SUBF-0154](README.md#subf-0154) serializes references,
schema identities, content digests, locations, and enclosing acquisition
context facts only.

## Requirement acquisition, redaction, failures, and pages

~~~csharp
public sealed class AcquisitionFailure : IEquatable<AcquisitionFailure>
{
    public string RequirementKey { get; }
    public string Code { get; }

    public static AcquisitionFailure Create(
        string requirementKey,
        string code);
}

public sealed class EvidenceRedaction : IEquatable<EvidenceRedaction>
{
    public static EvidenceRedaction None { get; }
    public bool RequiredValuesOmitted { get; }
    public bool NonRequiredValuesOmitted { get; }

    public static EvidenceRedaction Create(
        bool requiredValuesOmitted,
        bool nonRequiredValuesOmitted);
}

public sealed class RequirementAcquisition :
    IEquatable<RequirementAcquisition>
{
    public EvidenceRequirement Requirement { get; }
    public EvidenceConsistencyClass ConsistencyClass { get; }
    public EvidenceRedaction Redaction { get; }
    public IReadOnlyList<AcquisitionFailure> Failures { get; }
    public AcquisitionStatus Status { get; }

    public static RequirementAcquisition Create(
        EvidenceRequirement requirement,
        EvidenceConsistencyClass consistencyClass,
        EvidenceRedaction redaction,
        IEnumerable<AcquisitionFailure> failures);
}

public sealed class AcquisitionPage : IEquatable<AcquisitionPage>
{
    public int Sequence { get; }
    public ExactSha256Digest? RequestCursorDigest { get; }
    public ExactSha256Digest? NextCursorDigest { get; }
    public long SourceObjectCount { get; }

    public static AcquisitionPage Create(
        int sequence,
        ExactSha256Digest? requestCursorDigest,
        ExactSha256Digest? nextCursorDigest,
        long sourceObjectCount);
}
~~~

AcquisitionFailure is always requirement-scoped. Its code is owned by the
qualified adapter/evidence schema. The same (RequirementKey, Code) pair cannot
repeat. No message, exception, response body, credential, or transport enum is
part of the value.

EvidenceRedaction is attached to one RequirementAcquisition, so required-value
omission can never be global and unscoped. RequiredValuesOmitted makes that
requirement Incomplete. NonRequiredValuesOmitted is report-visible but does
not change status. Credentials are prohibited input, not “redacted evidence.”

RequirementAcquisition derives Complete only when:

- ConsistencyClass is one of Requirement.AcceptedConsistencyClasses;
- ConsistencyClass is not InsufficientConsistency;
- RequiredValuesOmitted is false; and
- Failures is empty.

Otherwise it derives Incomplete. It never derives Failed because a valid
EvidenceContext exists. Every failure key must equal the owning requirement
key. Zero bindings may derive a structurally Complete context; it becomes an
authoritative negative-inventory proof only after the exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) route
qualifies the completeness, page, and convergence contract for the empty set.

Pages count source objects, not bindings. One source object can produce
multiple schema projections and bindings. SourceObjectCount is non-negative
and uses long; checked summation overflow throws OverflowException.

For a non-empty page list:

- sequence values are exactly 1 through n;
- page 1 request cursor is null;
- for every i less than n, page i NextCursorDigest is non-null and equals page
  i+1 RequestCursorDigest;
- request cursor digests on pages 2 through n are unique;
- non-null next cursor digests on pages 1 through n are unique;
- the required adjacent next/request equality is one transition identity, not
  a forbidden duplicate;
- the last next cursor may be null (exhausted) or non-null (interrupted);
- no cursor may appear outside its one mandated adjacent pair, except that the
  final non-null interrupted cursor appears once and has no following request
  pair; and
- the checked page SourceObjectCount sum equals context SourceObjectCount.

An empty page list means non-paginated acquisition and imposes no page-count
sum equality. It may contain any non-negative SourceObjectCount.

An interrupted final cursor makes every requested requirement Incomplete and
requires at least one scoped failure for each. A Complete context always has
an empty page list or a null final next cursor.

This global interrupted-page rule is intentionally fail-closed. Independent
provider endpoints or surface families are separate routed
AcquisitionRequest/AcquisitionResult values with distinct
SourceContractKey/Version identities; one AcquisitionPage chain never mixes
multiple endpoint cursor grammars. A source-contract identity cannot alias two
endpoint or cursor grammars.

## Evidence context and closed acquisition result

~~~csharp
public sealed class EvidenceContext : IEquatable<EvidenceContext>
{
    public AcquisitionRequest Request { get; }
    public EvidenceScope Scope { get; }
    public IReadOnlyList<RequirementAcquisition> RequirementAcquisitions { get; }
    public IReadOnlyList<EvidenceBinding> Bindings { get; }
    public IReadOnlyList<AcquisitionPage> Pages { get; }
    public long SourceObjectCount { get; }
    public AcquisitionStatus Status { get; }
    public IReadOnlyList<RootEvidenceReference> References { get; }

    public static EvidenceContext Create(
        AcquisitionRequest request,
        EvidenceScope scope,
        IEnumerable<RequirementAcquisition> requirementAcquisitions,
        IEnumerable<EvidenceBinding> bindings,
        IEnumerable<AcquisitionPage> pages,
        long sourceObjectCount);
}

public abstract class AcquisitionResult : IEquatable<AcquisitionResult>
{
    private protected AcquisitionResult(
        AcquisitionRequest request,
        AcquisitionStatus status);
    public AcquisitionRequest Request { get; }
    public AcquisitionStatus Status { get; }
    public bool Equals(AcquisitionResult? other);
    public sealed override bool Equals(object? obj);
    public sealed override int GetHashCode();
}

public sealed class ObservedAcquisitionResult : AcquisitionResult
{
    public EvidenceContext Context { get; }
    public static ObservedAcquisitionResult Create(EvidenceContext context);
}

public sealed class AbsentAcquisitionResult : AcquisitionResult
{
    public static AbsentAcquisitionResult Create(AcquisitionRequest request);
}

public sealed class FailedAcquisitionResult : AcquisitionResult
{
    public DateTimeOffset StartedAtUtc { get; }
    public DateTimeOffset FailedAtUtc { get; }
    public IReadOnlyList<AcquisitionFailure> Failures { get; }

    public static FailedAcquisitionResult Create(
        AcquisitionRequest request,
        DateTimeOffset startedAtUtc,
        DateTimeOffset failedAtUtc,
        IEnumerable<AcquisitionFailure> failures);
}
~~~

EvidenceContext closes one request:

- Scope.Target equals Request.Target structurally.
- There is exactly one RequirementAcquisition for every requested requirement,
  no extra requirement, and the full requirement value matches.
- Every binding scope equals Context.Scope.
- Every binding requirement key is requested.
- A binding payload schema key/version equals every requirement to which the
  binding contributes.
- Every binding contributes to at least one requirement. The physical
  observation key is Location plus payload SchemaKey and SchemaVersion;
  exactly one binding per physical observation key is allowed, and its
  RequirementKeys must already be the complete union. EvidenceContext never
  merges inputs. A second physical observation key is rejected regardless of
  ContentDigest, CanonicalBytes, requirement partition, or CapturedAtUtc.
- Within one context, payloads with the same SchemaKey, SchemaVersion, and
  ContentDigest must have byte-identical CanonicalBytes. A same-identity,
  different-bytes collision fails construction before ordering or reference
  projection.
- References contains exactly one root reference per binding and no
  parser-derived reference.
- Requirement acquisitions, bindings, pages, and references are canonically
  ordered by requirement key, the structural binding key below, sequence, and
  matching root binding order.
- Page and source-object rules above hold.

Context Status is Complete exactly when every RequirementAcquisition is
Complete and pagination is exhausted/non-paged. Otherwise it is Incomplete.
An EvidenceContext can never be Failed.
For a zero-binding complete acquisition, EvidenceContext carries the exact
structural empty-inventory assertion. Only the separately qualified [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
route can promote it to authoritative proof. [SUBF-0154](README.md#subf-0154) later seals its
canonical report representation; [SUBF-0153](README.md#subf-0153) does not invent an early manifest
digest.

The result family is closed by private-protected construction and sealed
leaves. Base equality is concrete structural union dispatch; leaves declare no
equality overrides.

| Variant | Context | Failures | Derived status |
| --- | --- | --- | --- |
| ObservedAcquisitionResult | exactly one valid context | context-scoped only | context Complete or Incomplete |
| AbsentAcquisitionResult | none; no attempt was supplied | none | Incomplete |
| FailedAcquisitionResult | none; a required source could not produce a valid context; exact attempt interval retained | at least one per requested requirement | Failed |

Failed is therefore a structurally valid acquisition-result value with no
valid EvidenceContext. There is no “valid failure envelope.” This matches the
accepted architecture. Failure keys must cover every requested requirement,
and all keys must be requested. Failed-result timestamps have zero offset and
FailedAtUtc is not earlier than StartedAtUtc. Raw partial objects/pages,
transport messages, and provider payloads remain [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) diagnostics and do
not become evidence when no valid context exists.

## Content identity and later report identity

[SUBF-0153](README.md#subf-0153) derives one digest only: ContentDigest is SHA-256 over
CanonicalBytes exactly. EvidenceBinding and EvidenceContext are immutable
structural values; this slice does not create a second private canonical
serializer or a premature binding/context/manifest digest.

RootEvidenceReference copies the exact safe identity fields of a member binding.
The future evaluation input proves membership against the enclosing structural
EvidenceContext. [SUBF-0154](README.md#subf-0154) later defines one canonical report byte contract and
all report/reference stable keys. It must not hash canonical payload bytes into
the report or reinterpret ContentDigest.

## Sealed typed-evaluation boundary

CanonicalEvidencePayload is the safe immutable structural carrier boundary.
Evaluators do **not** receive it directly.

Before either [SUBF-0153](README.md#subf-0153) or [SUBF-0143](README.md#subf-0143) implementation, a separately reviewed
[SUBF-0143](README.md#subf-0143) typed-handoff Gate 2 design must close all requirements below. This
is an explicit prerequisite for the [SUBF-0153](README.md#subf-0153) implementation directive.

1. One [SUBF-0143](README.md#subf-0143) immutable release schema registry owns canonical schema
   membership. Each schema key/version binds one provider-neutral canonical
   codec, immutable model/capability key, model/parser-schema version, assembly
   and type identity, implementation artifact digest, canonicality rules, and
   deterministic byte/depth/count/complexity resource limits. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
   consumes this registry and owns adapter-output qualification; it is not a
   second schema owner.
2. Result admission is variant-specific. Observed requires an exact
   release-bound [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification receipt after source-contract,
   freshness, completeness, canonical codec, payload/location coherence, and
   deterministic resource checks. Failed requires an exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
   attempt/failure receipt binding the request, interval, failure codes, and
   absence of any valid partial context. Absent is never adapter-qualified or
   accepted as a caller-authored fact: the protocol-owned application/kernel
   synthesizes it only from a catalog-declared expected request slot plus a
   routing receipt proving no input was supplied and no attempt occurred.
   Publicly constructed Domain result values remain untrusted carriers.
3. The protocol-owned kernel alone constructs SealedEvaluationContext from
   variant-qualified or kernel-synthesized result inputs. Retrieval is
   generic/model-typed; no public object, dynamic, provider DTO, raw JSON node,
   service-provider lookup, reflection scan, lazy I/O model, or consumer
   executable registration exists.
4. Decode/parse attempts are memoized thread-safely, including typed failures,
   by exact release identity, schema key/version, content digest,
   model/parser-schema version, and decoder/parser artifact digest.
5. Context-sensitive index attempts are separately memoized, including typed
   failures, by exact release identity, exact structural EvidenceContext and
   ordered parent root references, index key/version, and indexer artifact
   digest. A same-byte document at another path cannot reuse a relative-link
   index merely because ContentDigest matches.
6. Decoder/parser evidence failures become typed RuleEvaluationFailure values
   and force NotEvaluated even when acquisition is Complete. Catalog,
   decoder-artifact, or release-envelope integrity mismatch is a runtime
   integrity failure, not an evidence parse failure. Raw exception text is
   never exposed. Deterministic resource-budget exhaustion may be a memoized
   semantic failure; host wall-clock timeout/cancellation is an operational
   runtime failure and never a cached semantic evidence result.
7. SealedEvaluationContext mints a qualified context-proof reference for the
   whole qualified EvidenceContext, including a zero-binding complete context.
   It binds the exact request/context, release and qualification receipt,
   requirement key, and completeness/convergence proof without inventing a
   member location. This is the only admissible absence/coverage provenance.
8. SealedEvaluationContext alone mints each parser-derived evidence reference.
   It binds one RootEvidenceReference, exact decoder/parser artifact identity
   and digest, typed node/span identity, and a validated same-or-narrower
   repository/provider refinement. Acquisition adapters do not pre-parse every
   link or line merely to create findings.
9. RuleEvaluationInput uses a catalog-declared two-phase requirement closure.
   It first closes qualified applicability requirements. Proven false yields
   NotApplicable without acquiring or requiring evaluation-only evidence;
   proven true activates and closes evaluation requirements; unresolved
   applicability yields NotEvaluated. Shared requirements may serve both
   phases but are acquired once per exact request.
10. Evaluation readiness is derived from variant admission, adapter/source
    qualification, completeness/freshness, canonicality, payload/location
    coherence, required typed model/index availability, and the applicable
    requirement phase. Context.Status == Complete alone is never enough for
    Satisfied.
11. Applicability/context-proof/root/derived/evaluated references must belong
    to the sealed input. Missing applicability evidence produces NotEvaluated,
    never NotApplicable. NotApplicable has zero findings and zero evaluation
    failures and retains the qualified applicability/context-proof references
    that prove the false result.
12. RuleFinding derives RuleId/RuleRevision from the input and accepts only a
    sealed context-proof reference or a sealed root/derived member reference.
    Raw Domain RootEvidenceReference is not independently admissible. Whether
    a finding has ordered related references is an exact [SUBF-0143](README.md#subf-0143) API
    decision; no independent location/digest pair is allowed.
13. The evaluator returns semantic assessment only. The kernel mints final
    Satisfied, Violated, NotApplicable, or NotEvaluated through distinct
    factories. Satisfied requires evaluation-ready input, zero evaluation
    failures, and zero findings. NotEvaluated requires unresolved evidence,
    undetermined applicability, unavailable model/index, or evaluation failure
    and may retain already proven partial findings.
14. Activation resolves evaluator/decoder/index implementations only from the
    exact immutable release catalog. Implementing an interface grants no
    consumer/provider execution authority; there is no assembly/DI discovery.

The [SUBF-0143](README.md#subf-0143) typed-handoff packet and [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification boundary are
joint authority for the exact observed/failure/absence receipt contracts above;
neither record may define a competing admission path.

The [SUBF-0143](README.md#subf-0143) Gate 2 packet must prove feasibility for RULE-0001 through
RULE-0005 with provider-neutral capabilities for repository/file-tree
inventory, source text/body plus deterministic line/span mapping, provider
object/conversation provenance, Markdown/link/record models, context-sensitive
link/record indexes, and Git object/permalink resolution. Repository documents
and issue/PR/comment bodies must be able to feed the same common evaluator
through the same typed capability while retaining distinct root/derived
locations.

[SUBF-0153](README.md#subf-0153) must not add placeholder evaluation records. [SUBF-0143](README.md#subf-0143) must not
weaken these gates.

## Error contract

| Invalid input | Exception category |
| --- | --- |
| Null required reference or enumerable | ArgumentNullException |
| Null enumerable element, malformed token/version/identity/path/refinement, duplicate, foreign requirement/scope/binding, content-identity collision, schema mismatch, union mismatch, or other cross-field conflict | ArgumentException |
| Null passed to EvidenceConsistencyClass.Parse | ArgumentNullException |
| Malformed, unknown, wrong-case, or otherwise non-canonical EvidenceConsistencyClass.Parse value | FormatException |
| Non-positive sequence/line, negative count, non-zero UTC offset, reversed timestamps, or over-length value | ArgumentOutOfRangeException |
| Checked page-count overflow | OverflowException |

TryParse never throws for caller input and returns false/null for null,
malformed, unknown, wrong-case, whitespace-padded, or non-canonical values.
Factories never trim or normalize.

## Equality, ordering, and defensive ownership

Equality includes every public semantic property and uses ordinal string and
byte comparison. Hashing uses the same fields. Union equality requires the
same runtime leaf. Call-order and static input type cannot change location or
result equality.

The structural comparer used for public context ordering is exact:

- strings compare ordinally; closed vocabulary values compare their exact
  ToString tokens ordinally; digests compare Value ordinally; timestamps compare
  chronological UTC instants; integers compare numerically;
- null sorts before non-null; sequences compare item-by-item and the shorter
  equal prefix sorts first;
- EvidenceScope compares Target then Boundary. Target compares
  SubjectIdentity, SourceIdentity, Surface, SnapshotKind, TargetIdentity.
  Boundary compares SnapshotKind, BoundaryIdentity, StartedAtUtc,
  CompletedAtUtc;
- location leaf rank is Repository, Provider, ReleaseAsset, Snapshot. After
  Scope, Repository compares RepositoryRelativePath, BlobIdentity, Line,
  Anchor, Property; Provider compares ProviderServiceIdentity, ObjectType,
  StableObjectIdentity, VersionIdentity, Field, Line, Fragment; ReleaseAsset
  compares ReleaseObjectIdentity, Tag, AssetName, AssetDigest; Snapshot has no
  remaining field.

Canonical order is:

- requirements and requirement acquisitions by exact requirement key then
  remaining semantic fields;
- accepted consistency classes in architecture order;
- failure pairs by requirement key then code;
- binding requirement keys ordinally;
- bindings by location leaf discriminator and exact location fields, then
  payload schema key/version, ContentDigest Value, CapturedAtUtc, and
  requirement keys; same schema/version/digest with unequal bytes is rejected
  before sorting;
- pages by Sequence; and
- root references in their matching binding order.

All input collections and canonical payload bytes are defensively copied.
Mutating caller-owned arrays/lists after Create has no effect. Enumerables are
consumed once.

## Prior art and WIP disposition

The preserved WIP remains frozen at exact commit
[1873c98638ba4960734aadb188eb8c8d70b4bc52](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52)
and draft [PR #160](https://github.com/hasanmanzak/meAndAI/pull/160). No source,
namespace, project, test result, passing state, or serializer is copied.

| WIP candidate | Disposition |
| --- | --- |
| [GovernanceRequirementKind and GovernanceRequirement](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Contracts/GovernanceFinding.cs#L9-L49) | Refactor for [SUBF-0153](README.md#subf-0153): retain distinct requirement intent; replace closed repository/document-only kinds with catalog-owned key/kind/completeness/payload-schema plus surface and consistency. |
| [GovernanceFindingEvidenceScope and GovernanceFindingEvidence](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Contracts/GovernanceFinding.cs#L51-L97) | Refactor for [SUBF-0153](README.md#subf-0153): explicit target/boundary/scope, canonical payload, binding, context, and result union. |
| [GovernanceFindingLocation](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Contracts/GovernanceFinding.cs#L99-L139) | Refactor for [SUBF-0153](README.md#subf-0153): path/line/anchor is only a seed; use the closed scope-bound location union. |
| [GovernanceFinding](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Contracts/GovernanceFinding.cs#L141-L209) | Defer/rebuild under [SUBF-0143](README.md#subf-0143) with context-minted references and release-bound catalog/evaluator ownership. |
| [GovernanceRuleEvaluation](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Contracts/GovernanceRuleEvaluation.cs#L6-L29) | Defer/rebuild under [SUBF-0143](README.md#subf-0143); do not carry status/list factories into [SUBF-0153](README.md#subf-0153). |
| [GovernanceRepositorySnapshot](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Repository/GovernanceRepositorySnapshot.cs#L9-L163) | Split/refactor: defensive copy, framed digest, order, and duplicate ideas inform Domain; Git/filesystem acquisition and raw entries remain [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md). |
| [MarkdownDocumentIndex](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Analysis/MarkdownDocumentIndex.cs#L7-L455) and [ProtocolRecordIndex](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/src/MeAndAI.Operations.Governance.Core/Analysis/ProtocolRecordIndex.cs#L6-L102) | Preserve-only for [SUBF-0143](README.md#subf-0143) typed decoder/model design; hard-coded paths and decision-only parsing do not enter this slice. |
| WIP report/factory/serializer/counts/report-byte tests | Preserve-only for [SUBF-0154](README.md#subf-0154). |
| WIP profile-evidence state, verdict, engine/authority state, exit code, and CLI contracts | Reject here; they collapse dimensions or belong to hosts. |
| [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) OperationResult<T>, operational failure vocabulary, and ports | Reject as Domain dependency. |
| Preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195) and WIP parser/snapshot tests | Preserve-only oracle; rewrite selected invalid-state ideas as fresh successor cases. Historical counts and passes are not evidence. |

SliceInventory is fresh successor authority. WIP was never merged or released,
so no shim, alias, conversion, or compatibility layer belongs in Domain.

## Distinct test intent and sibling inventory

[TEST-0221](test-cases.md#test-0221) owns this acquisition/evidence substrate directly. It never invokes
another test, reads another test’s source/result, or treats a child pass as its
oracle.

| Scenario | Relationship |
| --- | --- |
| [TEST-0220](test-cases.md#test-0220) | Distinct predecessor with cumulative public-surface overlap; retains predecessor API and project/restore graph. |
| [TEST-0209](test-cases.md#test-0209) | Distinct composed umbrella; future report/cross-boundary qualification, not a child-test aggregator. |
| [TEST-0210](test-cases.md#test-0210) | Distinct downstream owner of catalog, typed context, findings, evaluation, and aggregation. |
| Preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195) | Distinct legacy oracle; repository-only collapsed WIP model. |
| [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192) | Distinct operational ports/capability security. |
| [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) | InfrastructureContract; hosted discovery and exact command topology only. |
| [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176) | Distinct provider/rule qualification rather than generic Domain structure. |

## [TEST-0221](test-cases.md#test-0221) expected-red contract

[TEST-0221](test-cases.md#test-0221) is project-neutral and table-driven. Its Gate 3 red is valid only
after the later implementation directive.

| Area | Required cases |
| --- | --- |
| Public API | CumulativeInventory equality; exact SliceInventory names, namespace, base/leaf closure, members, parameter names, nullability, no public constructors/setters/conversions, and existing Domain assembly ownership. |
| Vocabulary/owners | valid/invalid open tokens and version text; all four exact EvidenceConsistencyClass static values/tokens in architecture order, ToString/equality/hash behavior, Parse null-to-ArgumentNullException and invalid-to-FormatException, TryParse false/null for null/unknown/wrong-case/malformed input, and accepted-class canonical ordering; unknown syntax-valid open values construct but confer no authority; AcquisitionFailure code is not catalog-owned. |
| Target/boundary/scope | subject=source and subject≠source; kind-specific positive/negative identities; ExactCommit rejection on repository/snapshot paths; local kind/equality/foreign-scope mismatch fails; provider target-to-boundary semantic substitution remains an explicit [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification case. |
| Locations | every leaf positive; invalid surface, path, Git ID, line/anchor/property, provider field/line/fragment, release asset, ill-formed UTF-16, and cross-leaf equality cases fail. |
| Payload/binding | asserted-canonical bytes copied once and ContentDigest derived; schema/version syntax validation without qualification; structural equality changes with byte/schema/location/requirement/time; foreign scope/schema/requirement binding fails; callers must pre-union requirement keys; repeated location+schema observations with the same or different payload/time are rejected rather than merged; public values remain untrusted until [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification. |
| Requirement state | accepted/unaccepted consistency, scoped required/optional redaction, scoped failures, duplicate/conflicting failure pairs, zero-binding negative inventory, and caller-independent status. |
| Pagination | non-paged non-zero object count; positive two-plus-page chain; interrupted last cursor; duplicate/cycle/reused transition; sequence/count/overflow errors; binding count independent of source-object count. |
| Context | exact request coverage; zero-object structurally Complete context that remains unqualified; foreign/orphan/duplicate physical observation and same-content-identity/different-bytes rejection; pre-unioned requirement membership; schema match; complete/incomplete derivation; exact root-reference projection; no caller reference factory. |
| Result union | observed Complete/Incomplete only; absent always Incomplete; failed has no context and covers every requirement; impossible “failure envelope”; base/leaf equality. |
| Defensive ownership | single enumeration; caller mutation resistance; ordinal ordering; culture independence; no provider DTO/object/dynamic/credential/message/exception/HTTP enum surface. |

The focused red must fail solely because a SliceInventory contract/member is
absent. A compile, restore, environment, workflow-discovery, or predecessor
failure is invalid red.

## Cumulative public-API ownership transition

[TEST-0220](test-cases.md#test-0220) retains canonical ownership of:

- the exact API/behavior of every type in PredecessorInventory; and
- the existing solution, project, package, lock, and effective-restore graph.

Its assembly-export assertion changes only from total-inventory equality to
exact presence and shape of PredecessorInventory. Those types may not drift.

[TEST-0221](test-cases.md#test-0221) directly owns:

- exact equality between assembly exports and CumulativeInventory;
- exact SliceInventory API, nullability, errors, equality, ordering, and
  behavior; and
- proof that every SliceInventory type is in the existing Domain assembly.

[TEST-0221](test-cases.md#test-0221) does not reassert predecessor member contracts or duplicate
[TEST-0220](test-cases.md#test-0220) project/package/lock/restore tests. The combined process runs both.
Neither scenario invokes the other or consumes the other’s result. A later
Domain export needs another explicit cumulative-owner transition.

## Future canonical execution route

This route is planning, not current authority. It may start only after
maintainer acceptance/merge/exact-main validation of this design, the
maintainer-accepted/merged/exact-main-validated [SUBF-0143](README.md#subf-0143) typed-handoff design,
and a separate implementation directive.

1. Start from the accepted exact-main predecessor with clean scoped project
   and lock files.
2. Capture hashes of both existing lock files, run the exact locked restore,
   and prove byte-identical locks.
3. Add fresh [TEST-0221](test-cases.md#test-0221) sources and only the bounded [TEST-0220](test-cases.md#test-0220) export-inventory
   transition. No SliceInventory production member exists yet.
4. Run only the focused [TEST-0221](test-cases.md#test-0221) command. It must fail solely for absent
   SliceInventory contracts.
5. Do not run StructureOnly, the root protocol suite, or hosted validation on
   this transient red tree. [TEST-0221](test-cases.md#test-0221) remains Planned and
   PlannedDocumentation, so active source is intentionally not a valid final
   authority graph. Do not publish the red tree as active PR head.
6. Implement exactly SliceInventory/invariants without project, package,
   dependency, lock, adapter, parser, evaluator, finding, report, host, or
   authority behavior.
7. Run focused [TEST-0221](test-cases.md#test-0221) green, then combined [TEST-0220](test-cases.md#test-0220)/[TEST-0221](test-cases.md#test-0221) in one test
   process, explicit Release build, and format verification.
8. After green only, atomically set [TEST-0221](test-cases.md#test-0221) to Passing, set Automation to the
   existing Domain test project, retain project-owned Scenario traits, move
   authority from PlannedDocumentation to that DotNetTestProject owner, update
   both existing stable jobs to the one combined filter, and update [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146).
9. Commit the complete graph-reachable implementation/test/docs/owner/workflow
   packet. Dirty/untracked validation is diagnostic only.
10. Run StructureOnly on that exact commit under PowerShell 7 and Windows
    PowerShell 5.1.
11. Publish only after both pass; require one hosted Ubuntu/Windows exact-head
    run. Merge and exact-main evidence remain later closure gates.

Focused red/green command:

~~~powershell
$scenarioId = 'TEST-' + '0221'
dotnet test tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj --configuration Release --no-restore --nologo --verbosity minimal --filter "Scenario=$scenarioId"
~~~

The combined local and hosted filter for [TEST-0220](test-cases.md#test-0220)
and [TEST-0221](test-cases.md#test-0221) is supplied through
`$protocolFilter`:

~~~text
--filter "$protocolFilter"
~~~

### Locked-restore oracle

Exact restore:

~~~powershell
dotnet restore MeAndAI.Protocol.slnx --configfile NuGet.Config --locked-mode
~~~

Scoped lock set:

~~~text
src/MeAndAI.Protocol.Domain/packages.lock.json
tests/dotnet/MeAndAI.Protocol.Domain.Tests/packages.lock.json
~~~

Before/after restore, both tracked and staged diffs for this set are empty.
Capture each SHA-256 before restore and require exact equality afterward. A
zero exit without byte-identical locks is not valid evidence. No solution,
project, central-package, NuGet configuration, or lock file may change.

### [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) exact-count and source-identity contract

[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) inspects every normalized run command in each existing stable Full
job. Per job it requires:

- exactly one MeAndAI.Protocol.slnx restore, exactly the locked command above;
- exactly one Domain test invocation, exactly Release/no-restore/minimal with
  the combined filter for [TEST-0220](test-cases.md#test-0220) and
  [TEST-0221](test-cases.md#test-0221);
- exactly one Full condition on each and no continue-on-error true; and
- no wrapper, alternate form, second restore, or second Domain test command.

Positive matching is insufficient; all restore/test invocations are counted
first, so a differently parameterized extra command fails.

The [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) PowerShell source contains no literal
[TEST-0220](test-cases.md#test-0220) or [TEST-0221](test-cases.md#test-0221),
including comments/messages, because [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) scans source identities. It
constructs them from split fragments while asserting the exact literal
workflow command:

~~~powershell
$protocolScenarioIds = @(
    ('TEST-' + '0220'),
    ('TEST-' + '0221')
)
$protocolFilter = @(
    $protocolScenarioIds | ForEach-Object { "Scenario=$_" }
) -join '|'
~~~

Only workflow YAML contains the exact literal combined filter.

## Recurrence review and verification budget

- Full-file display is not rewrite authority; bounded reads and filesystem
  bytes remain authoritative.
- Multiline GitHub content uses stdin/body-file, not direct multiline --body.
- Human-facing commits use clickable full 40-SHA links.
- Untracked governance packets are never HEAD evidence.
- CreateProcessAsUserW failed: 5 causes narrow retries only, not broad repeated
  commands.

No new job, trigger, path filter, restore process, test process, timeout
increase, or workflow registry is allowed. The accepted PR-head
[Windows job 90708165290](https://github.com/hasanmanzak/meAndAI/actions/runs/30490879521/job/90708165290)
used approximately 33 minutes 25 seconds of the 35-minute timeout, leaving
approximately 1 minute 35 seconds. [SUBF-0153](README.md#subf-0153) extends the existing process only.
If the combined route cannot fit, implementation stops for design review.

## Gate 2 findings incorporated

| Finding | Resolution |
| --- | --- |
| [FIND-0374](README.md#find-0374) | Open syntax has separate catalog, adapter/source, payload-schema, and failure-code owners. |
| [FIND-0375](README.md#find-0375) | Closed result union separates absent, observed, and failed; Failed has no valid context. |
| [FIND-0376](README.md#find-0376) | Every typed location owns exact EvidenceScope; shared boundary validation covers snapshot leaves. |
| [FIND-0377](README.md#find-0377) | RequirementAcquisition + EvidenceContext close consistency, redaction, failures, pagination, and status. |
| [FIND-0378](README.md#find-0378) | Premature evaluation records moved to [SUBF-0143](README.md#subf-0143); future evaluation closure is mandatory above. |
| [FIND-0379](README.md#find-0379) | Inventory-derived cumulative ownership removes handwritten counts. |
| [FIND-0380](README.md#find-0380) | WIP records are dispositioned by exact successor owner; no code/status carry-forward. |
| [FIND-0381](README.md#find-0381) | [SUBF-0152](README.md#subf-0152) exact-main baseline remains explicit. |
| [FIND-0382](README.md#find-0382) | One-process hosted route, exact job evidence, and fail-closed budget remain. |
| [FIND-0383](README.md#find-0383) | [TEST-0220](test-cases.md#test-0220) stays Passing and [TEST-0221](test-cases.md#test-0221) stays Planned until atomic activation. |
| [FIND-0384](README.md#find-0384) | Schema-identified content plus mandatory qualification and a release-bound typed context replace metadata-only evidence. |
| [FIND-0385](README.md#find-0385) | Target/boundary/scope and location membership close subject/source/snapshot authority. |
| [FIND-0386](README.md#find-0386) | Context-minted root references seal the asserted tuple; [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification verifies payload/location coherence and [SUBF-0143](README.md#subf-0143) owns parser-derived references. |
| [FIND-0387](README.md#find-0387) | Requirement-scoped redaction/failures and a real result union remove ambiguous failure envelopes. |
| [FIND-0388](README.md#find-0388) | Concrete base equality, version grammar, UTF-16 safety, long counts, and non-paged semantics close API edge contradictions. |
| [FIND-0389](README.md#find-0389) | Review, merge, exact-main validation, and separate directive are explicit continuation gates. |
| [FIND-0390](README.md#find-0390) | Transient-red prohibition, split scenario IDs, exact-count [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), and lock-hash oracle close execution-route ambiguity. |
| [FIND-0392](README.md#find-0392) | Schema and provider/source semantic owners are singular and explicit. |
| [FIND-0393](README.md#find-0393) | The gate-level dependency DAG forbids [SUBF-0153](README.md#subf-0153) implementation before the accepted typed seam. |
| [FIND-0394](README.md#find-0394) | Two-tier caches, qualified context-proof/derived references, and kernel-derived readiness prevent cross-context closure. |
| [FIND-0395](README.md#find-0395) | [SUBF-0153](README.md#subf-0153) derives only ContentDigest; report/reference identity remains [SUBF-0154](README.md#subf-0154)-owned. |
| [FIND-0396](README.md#find-0396) | Public Domain values are untrusted schema-identified assertions until [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification. |
| [FIND-0397](README.md#find-0397) | Pre-unioned physical-observation uniqueness and content-identity collision rejection close deterministic ordering. |
| [FIND-0398](README.md#find-0398) | Variant-specific observed/failure receipts and kernel-synthesized absence close result admission. |
| [FIND-0399](README.md#find-0399) | Applicability-first closure makes evaluation-only evidence conditional and preserves NotEvaluated. |
| [FIND-0400](README.md#find-0400) | Deterministic semantic budgets stay separate from operational wall-clock cancellation. |

[FIND-0391](README.md#find-0391) is deliberately not incorporated here. It is
an external [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)/[TEST-0214](../FEAT-0067-evidence-acquisition-managed-consumer-integration/test-cases.md#test-0214) terminology and consumer-contract follow-up
outside the current design-only mutation authority.

## Approval gate

Gate 2 is not accepted merely because this revision exists. Before Gate 3:

- bounded red-team must find no unresolved Blocking issue;
- the maintainer must accept or revise this exact design;
- the accepted design must merge and pass exact-main validation; and
- a separately reviewed and maintainer-accepted [SUBF-0143](README.md#subf-0143) typed-handoff Gate 2
  design must close every
  [sealed evaluation boundary](#sealed-typed-evaluation-boundary) requirement,
  merge, and pass bounded exact-main validation; and
- a new directive must explicitly authorize [TEST-0221](test-cases.md#test-0221) source, expected red,
  SliceInventory implementation, [TEST-0220](test-cases.md#test-0220) inventory transition, scenario
  activation, combined workflow filter, and narrow [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) change.

Until then C# implementation, test execution, project/lock/workflow mutation,
WIP extraction, consumer mutation, release, publication, and authority
transfer remain prohibited.
