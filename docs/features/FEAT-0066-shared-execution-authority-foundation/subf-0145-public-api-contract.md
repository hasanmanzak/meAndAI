# [SUBF-0145](README.md#subf-0145) Exact Public API Contract

| Field | Value |
| --- | --- |
| Classification | Normative API appendix to the [selected design](subf-0145-authority-grant-activation-design.md) |
| Status | `DesignFreezeCandidate`; no implementation active |
| Parent | [FEAT-0066](README.md) |
| Test | [TEST-0212](test-cases.md#test-0212) |
| Values/errors | [Exact value and error contract](subf-0145-value-error-contract.md) |
| Baseline | Exact main [`14ad828bcdde5f843cdbf12677b25f19736e5691`](https://github.com/hasanmanzak/meAndAI/commit/14ad828bcdde5f843cdbf12677b25f19736e5691) |

This appendix is the sole normative public-signature authority for the first
[FEAT-0066](README.md) slice. The design owns semantics and security ordering;
the [value/error appendix](subf-0145-value-error-contract.md) owns validation
and exception behavior; the [micro plan](subf-0145-micro-delivery-plan.md) owns
package execution. A signature change reopens the complete design gate.

## Conventions

Domain types are in `MeAndAI.Operations.Domain.ExecutionAuthority`. Services
and ports are in `MeAndAI.Operations.Application.ExecutionAuthority`. No type
has a public constructor or setter. Every collection is defensively copied,
ordinally sorted, duplicate-free, and exposed as `IReadOnlyList<T>`.

Every class declaring `IEquatable<T>` exposes exactly
`bool Equals(T? other)`, `override bool Equals(object? obj)`, and
`override int GetHashCode()`. Every class declaring `IComparable<T>` also
exposes `int CompareTo(T? other)`. Closed records use generated value equality.
`TryParse` uses `[NotNullWhen(true)]` on its nullable result. No type exposes a
conversion, deconstruction, mutable collection, serializer attribute, public
comparison interface beyond the declaration below, arbitrary diagnostic text,
credential, exception, command, stdout, or stderr.

## Normative SliceInventory

~~~text
ActivationCasDecision
ApprovalAuthoritySetSnapshot
AuthorityApprovalPolicy
AuthorityActorId
AuthorityDigest
AuthorityGrantId
AuthorityOperationId
AuthorityRevision
AuthorityRole
AuthoritySetBinding
AuthoritySetId
AuthoritySetMember
ExecutionCapability
ExecutionGrant
ExecutionGrantAuthorizer
ExecutionGrantBinding
ExecutionGrantDecision
ExecutionGrantRejection
ExecutionSubject
ExecutionTarget
ExtensionActivationCommand
ExtensionActivationGrantBinding
ExtensionActivationMutationRequest
ExtensionActivationRecord
ExtensionActivationService
GrantApprovalEvidence
GrantConsumptionRequest
GrantGeneration
GrantValidationRequest
IExecutionAuthorityMutationPort
IExecutionAuthorityReadPort
IdempotencyKey
JournalStoreReference
LeaseFenceBinding
PlanGrantBinding
PublicationEnvelope
PublicationGrantBinding
ReadGrantBinding
RoleSeparationRequirement
SoloMaintainerException
~~~

The list is ordinal and count-free. Tests derive expected count and ownership
from it.

## Canonical absence oracles

Each expected-red first loads its named assembly, resolves the exact
assembly-qualified type with `Type.GetType(..., false)`, then resolves the exact
public member and parameter types. Only a null type/member fails, at the final
assertion, as `<marker> absent: <type>::<member>`.
Parameter entries below are ordered `<full type name>, <assembly simple name>`;
the oracle resolves each to a `Type` and requires one method with exact name,
visibility, static/instance kind, and parameter array. Return type is proven by
the later typed public-API test, not the absence predicate.

| Package / marker | Assembly-qualified type | Exact member |
| --- | --- | --- |
| `EA-AUTHORITY-SNAPSHOT-01` / [`TEST-0212-SNAPSHOT-RED-0001`](test-cases.md#test-0212) | `MeAndAI.Operations.Domain.ExecutionAuthority.AuthorityActorId, MeAndAI.Operations.Domain` | static `Parse(System.String, System.Private.CoreLib)` |
| `EA-EXECUTION-GRANT-01` / [`TEST-0212-GRANT-RED-0002`](test-cases.md#test-0212) | `MeAndAI.Operations.Application.ExecutionAuthority.ExecutionGrantAuthorizer, MeAndAI.Operations.Application` | instance `AuthorizeAndConsumeAsync(MeAndAI.Operations.Domain.ExecutionAuthority.GrantValidationRequest, MeAndAI.Operations.Domain; System.Threading.CancellationToken, System.Private.CoreLib)` |
| `EA-PUBLICATION-ENVELOPE-01` / [`TEST-0212-PUBLICATION-RED-0003`](test-cases.md#test-0212) | `MeAndAI.Operations.Domain.ExecutionAuthority.PublicationEnvelope, MeAndAI.Operations.Domain` | static `Create(MeAndAI.Operations.Domain.ExecutionAuthority.ExecutionGrant, MeAndAI.Operations.Domain; MeAndAI.Operations.Domain.ExecutionAuthority.AuthorityDigest, MeAndAI.Operations.Domain)` |
| `EA-EXTENSION-ACTIVATION-01` / [`TEST-0212-ACTIVATION-RED-0004`](test-cases.md#test-0212) | `MeAndAI.Operations.Application.ExecutionAuthority.ExtensionActivationService, MeAndAI.Operations.Application` | instance `ActivateAsync(MeAndAI.Operations.Domain.ExecutionAuthority.ExtensionActivationCommand, MeAndAI.Operations.Domain; MeAndAI.Operations.Domain.ExecutionAuthority.AuthorityActorId, MeAndAI.Operations.Domain; System.DateTimeOffset, System.Private.CoreLib; System.Threading.CancellationToken, System.Private.CoreLib)` |

## Exact scalar APIs

~~~csharp
public sealed class AuthorityActorId : IEquatable<AuthorityActorId>, IComparable<AuthorityActorId>
{
    public string Value { get; }
    public static AuthorityActorId Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out AuthorityActorId? result);
    public override string ToString();
}

public sealed class AuthoritySetId : IEquatable<AuthoritySetId>, IComparable<AuthoritySetId>
{
    public string Value { get; }
    public static AuthoritySetId Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out AuthoritySetId? result);
    public override string ToString();
}

public sealed class AuthorityGrantId : IEquatable<AuthorityGrantId>, IComparable<AuthorityGrantId>
{
    public string Value { get; }
    public static AuthorityGrantId Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out AuthorityGrantId? result);
    public override string ToString();
}

public sealed class AuthorityOperationId : IEquatable<AuthorityOperationId>, IComparable<AuthorityOperationId>
{
    public string Value { get; }
    public static AuthorityOperationId Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out AuthorityOperationId? result);
    public override string ToString();
}

public sealed class IdempotencyKey : IEquatable<IdempotencyKey>, IComparable<IdempotencyKey>
{
    public string Value { get; }
    public static IdempotencyKey Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out IdempotencyKey? result);
    public override string ToString();
}

public sealed class JournalStoreReference : IEquatable<JournalStoreReference>, IComparable<JournalStoreReference>
{
    public string Value { get; }
    public static JournalStoreReference Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out JournalStoreReference? result);
    public override string ToString();
}

public sealed class AuthorityDigest : IEquatable<AuthorityDigest>, IComparable<AuthorityDigest>
{
    public string Value { get; }
    public static AuthorityDigest Parse(string value);
    public static bool TryParse(string? value, [NotNullWhen(true)] out AuthorityDigest? result);
    public static AuthorityDigest FromHashBytes(ReadOnlySpan<byte> hashBytes);
    public override string ToString();
}

public sealed record AuthorityRevision
{
    public long Value { get; }
    public static AuthorityRevision Create(long value);
    public override string ToString();
}

public sealed record GrantGeneration
{
    public long Value { get; }
    public static GrantGeneration Create(long value);
    public override string ToString();
}
~~~

The five opaque identities and store reference use 1..128 ASCII token grammar
`[a-z][a-z0-9]*(?:-[a-z0-9]+)*(?:\.[a-z][a-z0-9]*(?:-[a-z0-9]+)*)*`.
`AuthorityDigest` is exactly 64 lowercase hexadecimal characters and accepts
exactly 32 hash bytes. Revision is non-negative; generation is positive.

## Exact closed values

~~~csharp
public sealed record ExecutionCapability
{
    public static ExecutionCapability RepositoryRead { get; }
    public static ExecutionCapability ProviderRead { get; }
    public static ExecutionCapability ReportPublish { get; }
    public static ExecutionCapability RepositoryMutate { get; }
    public static ExecutionCapability ProviderMutate { get; }
    public static ExecutionCapability ExtensionActivate { get; }
    public static ExecutionCapability ReleasePublish { get; }
    public static ExecutionCapability AuthorityTransfer { get; }
    public string Value { get; }
    public static ExecutionCapability Parse(string value);
    public override string ToString();
}

public sealed record AuthorityRole
{
    public static AuthorityRole ProposalActor { get; }
    public static AuthorityRole EnvelopeReviewer { get; }
    public static AuthorityRole FinalPlanReviewer { get; }
    public static AuthorityRole GrantIssuer { get; }
    public static AuthorityRole Executor { get; }
    public string Value { get; }
    public static AuthorityRole Parse(string value);
    public override string ToString();
}

public sealed record ExecutionGrantRejection
{
    public static ExecutionGrantRejection None { get; }
    public static ExecutionGrantRejection SnapshotUnavailable { get; }
    public static ExecutionGrantRejection SnapshotDrift { get; }
    public static ExecutionGrantRejection ActorMismatch { get; }
    public static ExecutionGrantRejection RoleConflict { get; }
    public static ExecutionGrantRejection ApprovalMismatch { get; }
    public static ExecutionGrantRejection SubjectMismatch { get; }
    public static ExecutionGrantRejection TargetMismatch { get; }
    public static ExecutionGrantRejection OperationMismatch { get; }
    public static ExecutionGrantRejection GenerationMismatch { get; }
    public static ExecutionGrantRejection LeaseFenceMismatch { get; }
    public static ExecutionGrantRejection CapabilityMismatch { get; }
    public static ExecutionGrantRejection BindingMismatch { get; }
    public static ExecutionGrantRejection NotYetValid { get; }
    public static ExecutionGrantRejection Expired { get; }
    public static ExecutionGrantRejection Replayed { get; }
    public static ExecutionGrantRejection GrantStoreDrift { get; }
    public static ExecutionGrantRejection ActivationRecordUnavailable { get; }
    public static ExecutionGrantRejection ActivationRecordDrift { get; }
    public static ExecutionGrantRejection CasConflict { get; }
    public string Value { get; }
    public static ExecutionGrantRejection Parse(string value);
    public override string ToString();
}
~~~

Capability values are the accepted eight dot tokens. Role values are property
names split at PascalCase boundaries and joined as lowercase kebab. Rejection
wire values are exact: `None=none`,
`SnapshotUnavailable=snapshot.unavailable`, `SnapshotDrift=snapshot.drift`,
`ActorMismatch=actor.mismatch`, `RoleConflict=role.conflict`,
`ApprovalMismatch=approval.mismatch`, `SubjectMismatch=subject.mismatch`,
`TargetMismatch=target.mismatch`, `OperationMismatch=operation.mismatch`,
`GenerationMismatch=generation.mismatch`,
`LeaseFenceMismatch=lease-fence.mismatch`,
`CapabilityMismatch=capability.mismatch`, `BindingMismatch=binding.mismatch`,
`NotYetValid=time.not-yet-valid`, `Expired=time.expired`,
`Replayed=grant.replayed`, `GrantStoreDrift=grant-store.drift`,
`ActivationRecordUnavailable=activation-record.unavailable`,
`ActivationRecordDrift=activation-record.drift`, and
`CasConflict=cas.conflict`. Unknown values fail closed.

## Snapshot APIs

~~~csharp
public sealed class AuthoritySetMember : IEquatable<AuthoritySetMember>
{
    public AuthorityActorId Actor { get; }
    public IReadOnlyList<AuthorityRole> Roles { get; }
    public static AuthoritySetMember Create(AuthorityActorId actor, IEnumerable<AuthorityRole> roles);
}

public sealed class RoleSeparationRequirement : IEquatable<RoleSeparationRequirement>
{
    public AuthorityRole First { get; }
    public AuthorityRole Second { get; }
    public static RoleSeparationRequirement Create(AuthorityRole first, AuthorityRole second);
}

public sealed class SoloMaintainerException : IEquatable<SoloMaintainerException>
{
    public AuthorityActorId Actor { get; }
    public IReadOnlyList<AuthorityRole> AllowedRoles { get; }
    public AuthorityDigest IndependentEvidenceDigest { get; }
    public static SoloMaintainerException Create(AuthorityActorId actor, IEnumerable<AuthorityRole> allowedRoles, AuthorityDigest independentEvidenceDigest);
}

public sealed class AuthorityApprovalPolicy : IEquatable<AuthorityApprovalPolicy>
{
    public string GrantKind { get; }
    public IReadOnlyList<AuthorityRole> RequiredApprovalRoles { get; }
    public static AuthorityApprovalPolicy Create(
        string grantKind,
        IEnumerable<AuthorityRole> requiredApprovalRoles);
}

public sealed class ApprovalAuthoritySetSnapshot : IEquatable<ApprovalAuthoritySetSnapshot>
{
    public AuthoritySetId Id { get; }
    public string SchemaVersion { get; }
    public AuthorityRevision Revision { get; }
    public AuthorityRevision RevocationEpoch { get; }
    public AuthorityDigest Digest { get; }
    public IReadOnlyList<AuthoritySetMember> Members { get; }
    public IReadOnlyList<RoleSeparationRequirement> SeparationRequirements { get; }
    public IReadOnlyList<SoloMaintainerException> SoloMaintainerExceptions { get; }
    public IReadOnlyList<AuthorityApprovalPolicy> ApprovalPolicies { get; }
    public IReadOnlyList<JournalStoreReference> JournalStores { get; }
    public static ApprovalAuthoritySetSnapshot Create(
        AuthoritySetId id, string schemaVersion, AuthorityRevision revision,
        AuthorityRevision revocationEpoch, AuthorityDigest digest,
        IEnumerable<AuthoritySetMember> members,
        IEnumerable<RoleSeparationRequirement> separationRequirements,
        IEnumerable<SoloMaintainerException> soloMaintainerExceptions,
        IEnumerable<AuthorityApprovalPolicy> approvalPolicies,
        IEnumerable<JournalStoreReference> journalStores);
}

public sealed class AuthoritySetBinding : IEquatable<AuthoritySetBinding>
{
    public AuthoritySetId Id { get; }
    public AuthorityRevision Revision { get; }
    public AuthorityRevision RevocationEpoch { get; }
    public AuthorityDigest Digest { get; }
    public static AuthoritySetBinding From(ApprovalAuthoritySetSnapshot snapshot);
}
~~~

Schema version is `[1-9][0-9]{0,8}`. Snapshot membership includes at least one
identity for each of the five accepted roles; journal stores are nonempty. Separation pairs are distinct
and ordered. The five accepted roles have all ten pairwise separation
requirements. A solo exception has exactly two distinct sorted roles, both
held by its actor; that pair equals one separation requirement and carries
independent evidence. An actor/pair occurs at most once.
Approval policy kinds are exactly `evidence.read`, `plan.sealed`,
`report.sealed`, and `extension.transition`; each occurs once and cannot omit
the mandatory role floor frozen below.

## Grant APIs

~~~csharp
public sealed class ExecutionSubject : IEquatable<ExecutionSubject>
{
    public string Kind { get; }
    public string Identity { get; }
    public static ExecutionSubject Create(string kind, string identity);
}

public sealed class ExecutionTarget : IEquatable<ExecutionTarget>
{
    public string Kind { get; }
    public string Identity { get; }
    public string GenerationIdentity { get; }
    public static ExecutionTarget Create(string kind, string identity, string generationIdentity);
}

public sealed class LeaseFenceBinding : IEquatable<LeaseFenceBinding>
{
    public GrantGeneration Generation { get; }
    public string OwnerIdentity { get; }
    public string FencingToken { get; }
    public static LeaseFenceBinding Create(GrantGeneration generation, string ownerIdentity, string fencingToken);
}

public sealed class GrantApprovalEvidence : IEquatable<GrantApprovalEvidence>
{
    public AuthorityActorId Approver { get; }
    public AuthorityRole Role { get; }
    public AuthorityDigest EvidenceDigest { get; }
    public static GrantApprovalEvidence Create(AuthorityActorId approver, AuthorityRole role, AuthorityDigest evidenceDigest);
}

public abstract class ExecutionGrantBinding : IEquatable<ExecutionGrantBinding>
{
    internal ExecutionGrantBinding();
    public string Kind { get; }
    public AuthorityDigest Digest { get; }
    public IReadOnlyList<AuthorityRole> RequiredApprovalRoles { get; }
    public bool Equals(ExecutionGrantBinding? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
}

public sealed class PlanGrantBinding : ExecutionGrantBinding, IEquatable<PlanGrantBinding>
{
    public AuthorityDigest FinalPlanDigest { get; }
    public string BaseReference { get; }
    public string HeadReference { get; }
    public string TargetReference { get; }
    public IReadOnlyList<string> AllowedRepositoryPaths { get; }
    public IReadOnlyList<string> AllowedProviderObjectIdentities { get; }
    public string OperationStage { get; }
    public string AllowedEffectIdentity { get; }
    public static PlanGrantBinding Create(
        AuthorityDigest finalPlanDigest,
        string baseReference,
        string headReference,
        string targetReference,
        IEnumerable<string> allowedRepositoryPaths,
        IEnumerable<string> allowedProviderObjectIdentities,
        string operationStage,
        string allowedEffectIdentity,
        IEnumerable<AuthorityRole> requiredApprovalRoles,
        AuthorityDigest digest);
    public bool Equals(PlanGrantBinding? other);
}

public sealed class ReadGrantBinding : ExecutionGrantBinding, IEquatable<ReadGrantBinding>
{
    public AuthorityDigest EvidencePlanDigest { get; }
    public string BaseReference { get; }
    public string HeadReference { get; }
    public IReadOnlyList<string> AllowedRepositoryPaths { get; }
    public IReadOnlyList<string> AllowedProviderObjectIdentities { get; }
    public string AllowedEffectIdentity { get; }
    public static ReadGrantBinding Create(
        AuthorityDigest evidencePlanDigest,
        string baseReference,
        string headReference,
        IEnumerable<string> allowedRepositoryPaths,
        IEnumerable<string> allowedProviderObjectIdentities,
        string allowedEffectIdentity,
        IEnumerable<AuthorityRole> requiredApprovalRoles,
        AuthorityDigest digest);
    public bool Equals(ReadGrantBinding? other);
}

public sealed class PublicationGrantBinding : ExecutionGrantBinding, IEquatable<PublicationGrantBinding>
{
    public AuthorityDigest SealedReportDigest { get; }
    public ExecutionTarget ProviderTarget { get; }
    public string GateSnapshotIdentity { get; }
    public string ResultName { get; }
    public string AllowedEffectIdentity { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public static PublicationGrantBinding Create(
        AuthorityDigest sealedReportDigest,
        ExecutionTarget providerTarget,
        string gateSnapshotIdentity,
        string resultName,
        string allowedEffectIdentity,
        IdempotencyKey idempotencyKey,
        IEnumerable<AuthorityRole> requiredApprovalRoles,
        AuthorityDigest digest);
    public bool Equals(PublicationGrantBinding? other);
}

public sealed class ExtensionActivationGrantBinding : ExecutionGrantBinding, IEquatable<ExtensionActivationGrantBinding>
{
    public AuthorityDigest CurrentActivationRecordDigest { get; }
    public AuthorityDigest ProposedExtensionSnapshotDigest { get; }
    public string ActivePolicyIdentity { get; }
    public AuthorityDigest ActivePolicyDigest { get; }
    public string ActivatingTargetCommit { get; }
    public AuthorityDigest TransitionEvidenceDigest { get; }
    public AuthorityDigest ClosureReportDigest { get; }
    public ExecutionTarget Target { get; }
    public AuthorityRevision ExpectedCasVersion { get; }
    public string AllowedEffectIdentity { get; }
    public static ExtensionActivationGrantBinding Create(
        AuthorityDigest currentActivationRecordDigest,
        AuthorityDigest proposedExtensionSnapshotDigest,
        string activePolicyIdentity,
        AuthorityDigest activePolicyDigest,
        string activatingTargetCommit,
        AuthorityDigest transitionEvidenceDigest,
        AuthorityDigest closureReportDigest,
        ExecutionTarget target,
        AuthorityRevision expectedCasVersion,
        string allowedEffectIdentity,
        IEnumerable<AuthorityRole> requiredApprovalRoles,
        AuthorityDigest digest);
    public bool Equals(ExtensionActivationGrantBinding? other);
}

public sealed class ExecutionGrant : IEquatable<ExecutionGrant>
{
    public AuthorityGrantId Id { get; }
    public AuthoritySetBinding AuthoritySet { get; }
    public ExecutionCapability Capability { get; }
    public ExecutionSubject Subject { get; }
    public ExecutionTarget Target { get; }
    public AuthorityOperationId Operation { get; }
    public GrantGeneration Generation { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public AuthorityActorId Issuer { get; }
    public AuthorityActorId Executor { get; }
    public IReadOnlyList<GrantApprovalEvidence> Approvals { get; }
    public ExecutionGrantBinding Binding { get; }
    public JournalStoreReference JournalStore { get; }
    public LeaseFenceBinding LeaseFence { get; }
    public DateTimeOffset IssuedAtUtc { get; }
    public DateTimeOffset NotBeforeUtc { get; }
    public DateTimeOffset ExpiresAtUtc { get; }
    public AuthorityDigest Digest { get; }
    public static ExecutionGrant Create(
        AuthorityGrantId id, AuthoritySetBinding authoritySet,
        ExecutionCapability capability, ExecutionSubject subject,
        ExecutionTarget target, AuthorityOperationId operation,
        GrantGeneration generation, IdempotencyKey idempotencyKey,
        AuthorityActorId issuer, AuthorityActorId executor,
        IEnumerable<GrantApprovalEvidence> approvals,
        ExecutionGrantBinding binding, JournalStoreReference journalStore,
        LeaseFenceBinding leaseFence,
        DateTimeOffset issuedAtUtc, DateTimeOffset notBeforeUtc,
        DateTimeOffset expiresAtUtc, AuthorityDigest digest);
}

public sealed class GrantValidationRequest : IEquatable<GrantValidationRequest>
{
    public ExecutionGrant Grant { get; }
    public ExecutionCapability RequiredCapability { get; }
    public ExecutionSubject ExpectedSubject { get; }
    public ExecutionTarget ExpectedTarget { get; }
    public AuthorityOperationId ExpectedOperation { get; }
    public GrantGeneration ExpectedGeneration { get; }
    public ExecutionGrantBinding ExpectedBinding { get; }
    public AuthorityActorId ExecutingActor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static GrantValidationRequest Create(
        ExecutionGrant grant, ExecutionCapability requiredCapability,
        ExecutionSubject expectedSubject, ExecutionTarget expectedTarget,
        AuthorityOperationId expectedOperation, GrantGeneration expectedGeneration,
        ExecutionGrantBinding expectedBinding, AuthorityActorId executingActor,
        DateTimeOffset observedAtUtc);
}

public sealed class GrantConsumptionRequest : IEquatable<GrantConsumptionRequest>
{
    public GrantValidationRequest Validation { get; }
    public AuthoritySetBinding ExpectedCurrentAuthoritySet { get; }
    public AuthorityDigest ExpectedStoreHead { get; }
    public static GrantConsumptionRequest Create(
        GrantValidationRequest validation,
        AuthoritySetBinding expectedCurrentAuthoritySet,
        AuthorityDigest expectedStoreHead);
}

public sealed class ExecutionGrantDecision : IEquatable<ExecutionGrantDecision>
{
    public bool IsAuthorized { get; }
    public ExecutionGrantRejection Rejection { get; }
    public static ExecutionGrantDecision Authorized();
    public static ExecutionGrantDecision Rejected(ExecutionGrantRejection rejection);
}
~~~

## Publication API

~~~csharp
public sealed class PublicationEnvelope : IEquatable<PublicationEnvelope>
{
    public AuthorityDigest SealedReportDigest { get; }
    public AuthorityDigest PublicationGrantDigest { get; }
    public AuthoritySetBinding AuthoritySet { get; }
    public ExecutionTarget ProviderTarget { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public string GateSnapshotIdentity { get; }
    public string ResultName { get; }
    public string AllowedEffectIdentity { get; }
    public AuthorityDigest Digest { get; }
    public static PublicationEnvelope Create(
        ExecutionGrant publicationGrant,
        AuthorityDigest digest);
}
~~~

The factory accepts only a `report.publish` grant with a
`PublicationGrantBinding`. Every envelope field is copied from that immutable
grant/binding; no caller-supplied duplicate may disagree. The envelope binds
the grant digest, while the grant binding binds the pre-existing sealed report
and never the not-yet-created envelope, so there is no digest cycle.

## Activation APIs

~~~csharp
public sealed class ExtensionActivationRecord : IEquatable<ExtensionActivationRecord>
{
    public ExecutionTarget Repository { get; }
    public AuthorityRevision ActivationEpoch { get; }
    public AuthorityRevision CasVersion { get; }
    public string ActivePolicyIdentity { get; }
    public AuthorityDigest ActivePolicyDigest { get; }
    public AuthorityDigest ActiveSnapshotDigest { get; }
    public string ActivatingTargetCommit { get; }
    public AuthorityDigest? PreviousRecordDigest { get; }
    public AuthorityDigest? BootstrapEvidenceDigest { get; }
    public IReadOnlyList<GrantApprovalEvidence> ActivationApprovals { get; }
    public AuthorityDigest ActivationGrantDigest { get; }
    public AuthorityDigest TransitionEvidenceDigest { get; }
    public AuthorityDigest ClosureEvidenceDigest { get; }
    public AuthoritySetBinding AuthoritySet { get; }
    public AuthorityDigest RecordDigest { get; }
    public static ExtensionActivationRecord CreateGenesis(
        ExecutionTarget repository, string activePolicyIdentity,
        AuthorityDigest activePolicyDigest, AuthorityDigest activeSnapshotDigest,
        string activatingTargetCommit,
        AuthorityDigest bootstrapEvidenceDigest,
        IEnumerable<GrantApprovalEvidence> activationApprovals,
        AuthorityDigest activationGrantDigest,
        AuthorityDigest transitionEvidenceDigest,
        AuthorityDigest closureEvidenceDigest,
        AuthoritySetBinding authoritySet);
    public static ExtensionActivationRecord CreateSuccessor(
        ExecutionTarget repository, AuthorityRevision activationEpoch,
        AuthorityRevision casVersion, string activePolicyIdentity,
        AuthorityDigest activePolicyDigest, AuthorityDigest activeSnapshotDigest,
        string activatingTargetCommit, AuthorityDigest previousRecordDigest,
        IEnumerable<GrantApprovalEvidence> activationApprovals,
        AuthorityDigest activationGrantDigest,
        AuthorityDigest transitionEvidenceDigest,
        AuthorityDigest closureEvidenceDigest,
        AuthoritySetBinding authoritySet);
}

public sealed class ExtensionActivationCommand : IEquatable<ExtensionActivationCommand>
{
    public ExtensionActivationRecord ExpectedCurrent { get; }
    public AuthorityDigest TransitionEvidenceDigest { get; }
    public ExecutionGrant Grant { get; }
    public ExtensionActivationRecord Proposed { get; }
    public static ExtensionActivationCommand Create(
        ExtensionActivationRecord expectedCurrent,
        AuthorityDigest transitionEvidenceDigest,
        ExecutionGrant grant,
        ExtensionActivationRecord proposed);
}

public sealed class ExtensionActivationMutationRequest : IEquatable<ExtensionActivationMutationRequest>
{
    public ExtensionActivationCommand Command { get; }
    public AuthoritySetBinding ExpectedCurrentAuthoritySet { get; }
    public AuthorityDigest ExpectedGrantStoreHead { get; }
    public AuthorityActorId ExecutingActor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static ExtensionActivationMutationRequest Create(
        ExtensionActivationCommand command,
        AuthoritySetBinding expectedCurrentAuthoritySet,
        AuthorityDigest expectedGrantStoreHead,
        AuthorityActorId executingActor,
        DateTimeOffset observedAtUtc);
}

public sealed class ActivationCasDecision : IEquatable<ActivationCasDecision>
{
    public bool IsActivated { get; }
    public ExecutionGrantRejection Rejection { get; }
    public ExtensionActivationRecord? Record { get; }
    public static ActivationCasDecision Activated(ExtensionActivationRecord record);
    public static ActivationCasDecision Rejected(ExecutionGrantRejection rejection);
}
~~~

## Exact services and ports

~~~csharp
public sealed class ExecutionGrantAuthorizer
{
    public static ExecutionGrantAuthorizer Create(
        IExecutionAuthorityReadPort readPort,
        IExecutionAuthorityMutationPort mutationPort);
    public ValueTask<ExecutionGrantDecision> AuthorizeAndConsumeAsync(
        GrantValidationRequest request,
        CancellationToken cancellationToken);
}

public sealed class ExtensionActivationService
{
    public static ExtensionActivationService Create(
        IExecutionAuthorityReadPort readPort,
        IExecutionAuthorityMutationPort mutationPort);
    public ValueTask<ActivationCasDecision> ActivateAsync(
        ExtensionActivationCommand command,
        AuthorityActorId executingActor,
        DateTimeOffset observedAtUtc,
        CancellationToken cancellationToken);
}

public interface IExecutionAuthorityReadPort : IProviderReadPort
{
    ValueTask<ApprovalAuthoritySetSnapshot?> ReadAuthoritySetAsync(
        AuthoritySetId id, CancellationToken cancellationToken);
    ValueTask<AuthorityDigest?> ReadGrantStoreHeadAsync(
        JournalStoreReference store, CancellationToken cancellationToken);
    ValueTask<ExtensionActivationRecord?> ReadExtensionActivationAsync(
        ExecutionTarget repository, CancellationToken cancellationToken);
}

public interface IExecutionAuthorityMutationPort : IProviderMutationPort
{
    ValueTask<ExecutionGrantDecision> TryConsumeGrantAsync(
        GrantConsumptionRequest request, CancellationToken cancellationToken);
    ValueTask<ActivationCasDecision> TryActivateExtensionAsync(
        ExtensionActivationMutationRequest request,
        CancellationToken cancellationToken);
}
~~~

## Cross-field and rejection contract

- The grant journal store occurs exactly once in the protected authority
  snapshot's approved nonempty store list. The public use cases resolve its
  current head through the read port; callers cannot supply that head. Grant
  and lease generations are equal. UTC timestamps satisfy
  `IssuedAtUtc <= NotBeforeUtc < ExpiresAtUtc`; authorization is valid exactly
  when `NotBeforeUtc <= ObservedAtUtc < ExpiresAtUtc`.
- Mandatory approval-role floors are: `evidence.read` -> `EnvelopeReviewer`;
  `plan.sealed` -> `ProposalActor` plus `FinalPlanReviewer`;
  `report.sealed` -> `EnvelopeReviewer` plus
  `FinalPlanReviewer`; `extension.transition` -> `ProposalActor` plus
  `FinalPlanReviewer`. The protected snapshot policy may add but cannot remove
  roles. A binding's required-role set must equal the protected policy. Each
  required role has exactly one matching approval; an extra, missing,
  duplicated, nonmember, or wrong-role approval is `ApprovalMismatch`. Issuer
  and executor must hold `GrantIssuer` and `Executor`; wrong executing actor is
  `ActorMismatch`. The snapshot's mandatory ten-pair separation is enforced
  across proposal, envelope, final-plan, issuer, and executor identities unless
  that exact actor/role pair has the snapshot's independent solo evidence.
- `ReadGrantBinding`, `PlanGrantBinding`, `PublicationGrantBinding`, and
  `ExtensionActivationGrantBinding` are the only constructible binding types.
  Their fixed kinds are respectively `evidence.read`, `plan.sealed`,
  `report.sealed`, and `extension.transition`.
  Publication structurally binds report, target, gate snapshot, result name,
  allowed effect, and idempotency. Activation structurally binds current
  record, proposed snapshot, policy identity/digest, activating commit,
  transition evidence, closure report, target, CAS version, and allowed effect.
  Unknown runtime subclasses and mismatched binding kinds fail closed.
- Capability/binding compatibility is exact and checked before any binding
  field: `repository.read` and `provider.read` require `ReadGrantBinding`;
  `repository.mutate` and `provider.mutate` require `PlanGrantBinding`;
  `report.publish` requires `PublicationGrantBinding`; and
  `extension.activate` requires `ExtensionActivationGrantBinding`. Every other
  pair returns `CapabilityMismatch` even when all caller-supplied values equal.
- `release.publish` and `authority.transfer` always return
  `CapabilityMismatch` in this slice. Their specialized grant contracts remain
  held for the owning later feature; caller-matched open bindings cannot enable
  them.
- `ExecutionGrantAuthorizer` first mismatch order and mapping is: missing authority snapshot ->
  `SnapshotUnavailable`; authority identity/revision/epoch/digest drift ->
  `SnapshotDrift`; executing actor, issuer role, executor role, or grant executor
  mismatch -> `ActorMismatch`; separation -> `RoleConflict`; approval policy or
  evidence -> `ApprovalMismatch`; subject -> `SubjectMismatch`; target ->
  `TargetMismatch`; operation -> `OperationMismatch`; grant/lease generation ->
  `GenerationMismatch`; owner/fence -> `LeaseFenceMismatch`; capability ->
  `CapabilityMismatch`; typed binding or any binding field ->
  `BindingMismatch`; early observation -> `NotYetValid`; expiry edge or later ->
  `Expired`; consumed grant ID or idempotency -> `Replayed`; grant-store head ->
  `GrantStoreDrift`. The distinct `ExtensionActivationService` order and its
  activation-only rejections are frozen in the
  [value/error appendix](subf-0145-value-error-contract.md#exact-activation-equality-and-rejection-ownership).
- The authorizer always resolves the protected snapshot itself, validates, and
  asks the mutation port to atomically compare that exact authority binding,
  the grant-store head, grant ID, and idempotency key while consuming. The
  activation service separately re-reads the protected authority snapshot and
  activation record, rejects any caller-current mismatch, validates the typed
  activation binding, and makes exactly one `TryActivateExtensionAsync` call.
  That mutation atomically re-compares the authority binding, grant-store head,
  unused grant/idempotency, protected activation record digest/version, then
  consumes the grant and exchanges the activation record. A split consume/CAS
  sequence is forbidden.
- A genesis activation record has epoch/version zero and a null previous
  digest, non-null bootstrap evidence, and is created only through
  `CreateGenesis` from protected bootstrap authority. A successor has null
  bootstrap evidence, positive epoch/version, non-null previous digest, and is
  created only through `CreateSuccessor`. The factory owns that intrinsic
  shape; the activation service owns predecessor equality and exact +1 counter
  advancement as frozen in the value/error appendix. Both retain exact
  approval, grant, transition, and closure evidence. Candidate content cannot
  create a protected genesis or winning successor merely by constructing a
  value.
