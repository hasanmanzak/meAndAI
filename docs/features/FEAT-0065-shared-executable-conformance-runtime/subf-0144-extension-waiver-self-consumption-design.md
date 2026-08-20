# [SUBF-0144](README.md#subf-0144) - Protected Policy and Self-Consumption Design

| Field | Value |
| --- | --- |
| Classification | Subfeature / dependency-closed [FEAT-0065](README.md) design slice |
| Status | `AcceptedFrozenDesign`; exact design head is hosted green; `POLICY-SURFACE-FRAMING-01`, `EXTENSION-AUTHORITY-01`, `EXTENSION-EVALUATION-01`, and `WAIVER-DISPOSITION-01` are packet-local `ReviewedLocalGreen`; `DEBT-ENFORCEMENT-01` is next and inactive in this commit |
| Parent | [FEAT-0065](README.md) |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Decision | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) |
| Scenario | [TEST-0211](test-cases.md#test-0211) |
| Exact design baseline | [`14ad828bcdde5f843cdbf12677b25f19736e5691`](https://github.com/hasanmanzak/meAndAI/commit/14ad828bcdde5f843cdbf12677b25f19736e5691) |
| Predecessor | [SUBF-0143](README.md#subf-0143) and [TEST-0210](test-cases.md#test-0210) are immutable merged/exact-main-hosted-green history |
| Delivery control | [Micro-delivery plan](subf-0144-micro-delivery-plan.md) |

## Directive and activation boundary

The maintainer's 2026-08-14 successor directive authorizes this design packet
and conditionally authorizes its implementation without another confirmation
only after the exact design cohort is `AcceptedFrozenDesign`: Definition of
Ready complete, exact API and ownership freeze complete, canonical expected-red
identity frozen, implementation allowlist frozen, fresh design/evidence/
traceability reviews at `0 Blocking / 0 Important / 0 Minor`, local structural
and graph validation green, one focused design commit pushed, and that exact
head green on Ubuntu and Windows with publication verification skipped.

Before that exact-head hosted gate, no C# source, executable test, project,
package, lock, workflow, scenario-owner, consumer, release, publication,
authority-transfer, or PowerShell-retirement change is authorized. After that
gate, the packets in the [micro-delivery plan](subf-0144-micro-delivery-plan.md)
may proceed in order without another user confirmation. Pull-request merge,
real release/publication, credentials, consumer mutation, authority transfer,
and destructive retirement still require their own exact directives.

## Outcome

The completed conformance kernel evaluates one protected baseline plus an
independently authenticated active extension snapshot, reports any candidate
extension transition separately, applies exact waiver and historical-debt
dispositions without rewriting conformance, derives the accepted enforcement
decision, and qualifies a candidate runtime only through predecessor-trusted
same-evidence differential and independent fixtures.

The slice does not serialize a canonical report. It produces immutable typed
results consumed later by [SUBF-0154](README.md#subf-0154).

## Ownership and dependency allocation

| Assembly | Owned additions | Forbidden pull-forward |
| --- | --- | --- |
| `MeAndAI.Protocol.Domain` | Closed extension identity and finding-disposition value types only | Catalog/evaluator objects, grants, CAS, stores, reports, adapters |
| `MeAndAI.Protocol.Conformance.Abstractions` | Declarative extension inputs, activation-proof contract, waiver/debt inputs, evaluator registration/input/intent, trusted runtime binding | Provider DTOs, durable authority records, journals, report bytes |
| `MeAndAI.Protocol.Conformance` | Activation validation, extension evaluation, finding disposition, enforcement derivation, predecessor-trusted differential qualification | I/O, credential use, protected-store mutation, publication, serialization |
| `MeAndAI.Protocol.Policy` | Protocol-owned extension evaluator-kind registrations used by project-neutral qualification fixtures | Consumer policy parsing, arbitrary code loading, activation or grant logic |
| `MeAndAI.Protocol.Conformance.Tests` | [TEST-0211](test-cases.md#test-0211) expected-red, behavior, security, differential, public API, ownership, and convergence evidence | Reopening or consuming [TEST-0210](test-cases.md#test-0210) as a child suite |

[FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md)
owns durable authority-set snapshots, grants, activation CAS, publication
envelopes, journals, and recovery. This slice owns only the semantic contract
that a verified activation proof must satisfy before an active extension
snapshot can affect evaluation. This subfeature solely owns proposed-extension
addition/removal/revision semantics, rationale and exact active-to-proposed diff
recomputation; [SUBF-0145](../FEAT-0066-shared-execution-authority-foundation/README.md#subf-0145)
may consume only the sealed transition evidence and
proposed-snapshot digest when it owns protected activation CAS. Neither workstream
duplicates or revises the other's owner. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
later owns protected-store and file/provider acquisition adapters.

## Exact public surface

All collections are defensive ordinal snapshots, all strings use ordinal
comparison, every digest is `ExactSha256Digest`, and every timestamp is UTC
`DateTimeOffset` with zero offset. Public constructors are absent unless shown;
factories validate all arguments before retaining them.

### Domain values

```csharp
public sealed class ExtensionId : IEquatable<ExtensionId>, IComparable<ExtensionId>
{
    public string Value { get; }
    public static ExtensionId Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExtensionId? result);
    public int CompareTo(ExtensionId? other);
    public bool Equals(ExtensionId? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class FindingDisposition : IEquatable<FindingDisposition>
{
    public static FindingDisposition ActiveViolation { get; }
    public static FindingDisposition HistoricalDebt { get; }
    public static FindingDisposition Waived { get; }
    public string Value { get; }
    public static FindingDisposition Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out FindingDisposition? result);
    public bool Equals(FindingDisposition? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class ExtensionTransitionKind : IEquatable<ExtensionTransitionKind>
{
    public static ExtensionTransitionKind Added { get; }
    public static ExtensionTransitionKind Revised { get; }
    public static ExtensionTransitionKind Removed { get; }
    public string Value { get; }
    public static ExtensionTransitionKind Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExtensionTransitionKind? result);
    public bool Equals(ExtensionTransitionKind? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}
```

`ExtensionId` is exact lowercase ASCII
`ext:<repository-namespace>:<stable-name>`. Each of the two suffix components
is `1..96` characters, starts and ends in `[a-z0-9]`, and otherwise contains
only `[a-z0-9.-]`; empty segments, consecutive dots, leading/trailing dot or
hyphen, `RULE-` aliases, uppercase, whitespace, slash, backslash, colon, and a
total length above `197` fail parsing.
`FindingDisposition` values are exactly `active-violation`,
`historical-debt`, and `waived`; `ExtensionTransitionKind` values are exactly
`added`, `revised`, and `removed`. Their closed Parse/TryParse/equality members
use ordinal text and reject aliases or case drift.

`ExtensionParameter.Key` is lowercase ASCII `1..64`, starts/ends in
`[a-z0-9]`, and otherwise uses `[a-z0-9.-]`; `Value` is strict UTF-8,
`0..4,096` bytes, contains no NUL/CR and is interpreted only by the registered
kind's exact grammar. Declarations require ordinal key order and reject
duplicates rather than sorting caller input.

### Extension declarations and activation

```csharp
public sealed class ExtensionParameter
{
    public string Key { get; }
    public string Value { get; }
    public static ExtensionParameter Create(string key, string value);
}

public sealed class ExtensionRuleDeclaration
{
    public ExtensionId ExtensionId { get; }
    public RuleRevision Revision { get; }
    public string EvaluatorKind { get; }
    public string EvaluatorVersion { get; }
    public IReadOnlyList<ExtensionParameter> Parameters { get; }
    public IReadOnlyList<SubjectRole> SubjectRoles { get; }
    public SurfaceSet Surfaces { get; }
    public IReadOnlyList<SnapshotKind> SnapshotKinds { get; }
    public IReadOnlyList<ProtocolOperation> Operations { get; }
    public ExactSha256Digest DefinitionDigest { get; }
    public static ExtensionRuleDeclaration Create(
        ExtensionId extensionId,
        RuleRevision revision,
        string evaluatorKind,
        string evaluatorVersion,
        IEnumerable<ExtensionParameter> parameters,
        IEnumerable<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IEnumerable<SnapshotKind> snapshotKinds,
        IEnumerable<ProtocolOperation> operations,
        ExactSha256Digest definitionDigest);
}

public sealed class ExtensionCatalogSnapshot
{
    public string RepositoryNamespace { get; }
    public ExactSha256Digest PolicyBlobDigest { get; }
    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<ExtensionRuleDeclaration> Extensions { get; }
    public static ExtensionCatalogSnapshot Create(
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        ExactSha256Digest snapshotDigest,
        IEnumerable<ExtensionRuleDeclaration> extensions);
}

public sealed class ProposedExtensionChange
{
    public ExtensionId ExtensionId { get; }
    public ExtensionTransitionKind Kind { get; }
    public ExactSha256Digest? PreviousDefinitionDigest { get; }
    public ExactSha256Digest? ProposedDefinitionDigest { get; }
    public static ProposedExtensionChange Create(
        ExtensionId extensionId,
        ExtensionTransitionKind kind,
        ExactSha256Digest? previousDefinitionDigest,
        ExactSha256Digest? proposedDefinitionDigest);
}

public sealed class ProposedExtensionTransition
{
    public ExtensionCatalogSnapshot ActiveSnapshot { get; }
    public ExtensionCatalogSnapshot ProposedSnapshot { get; }
    public string TargetCommit { get; }
    public ExactSha256Digest RationaleDigest { get; }
    public IReadOnlyList<ProposedExtensionChange> Changes { get; }
    public ExactSha256Digest TransitionDigest { get; }
    public static ProposedExtensionTransition Create(
        ExtensionCatalogSnapshot activeSnapshot,
        ExtensionCatalogSnapshot proposedSnapshot,
        string targetCommit,
        ExactSha256Digest rationaleDigest,
        IEnumerable<ProposedExtensionChange> changes);
}

public sealed class ProtectedAuthorityEnvelope
{
    public string IssuerKeyId { get; }
    public string Algorithm { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest PayloadDigest { get; }
    public ExactSha256Digest AuthorityRecordDigest { get; }
    public long AuthorityEpoch { get; }
    public ExactSha256Digest EnvelopeDigest { get; }
    public byte[] GetSignatureCopy();
    public static ProtectedAuthorityEnvelope Create(
        string issuerKeyId,
        string algorithm,
        string contractKey,
        string contractVersion,
        ExactSha256Digest payloadDigest,
        ExactSha256Digest authorityRecordDigest,
        long authorityEpoch,
        IEnumerable<byte> signature);
}

public sealed class ProtectedExtensionActivationPayload
{
    public ExactSha256Digest ManifestDigest { get; }
    public string RepositoryNamespace { get; }
    public ExactSha256Digest PolicyBlobDigest { get; }
    public ExactSha256Digest AuthoritySetDigest { get; }
    public ExactSha256Digest ExpectedAuthorityRecordDigest { get; }
    public ExactSha256Digest PreviousActivationRecordDigest { get; }
    public ExactSha256Digest ClosureEvidenceDigest { get; }
    public ExactSha256Digest ActiveSnapshotDigest { get; }
    public string ActivatedTargetCommit { get; }
    public long ActivationEpoch { get; }
    public ExactSha256Digest PayloadDigest { get; }
    public static ProtectedExtensionActivationPayload Create(
        ExactSha256Digest manifestDigest,
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        ExactSha256Digest previousActivationRecordDigest,
        ExactSha256Digest closureEvidenceDigest,
        ExactSha256Digest activeSnapshotDigest,
        string activatedTargetCommit,
        long activationEpoch);
}

public interface IProtectedExtensionActivationVerifier
{
    bool Verify(
        ProtectedExtensionActivationPayload payload,
        ProtectedAuthorityEnvelope activationProof);
}

public sealed class ProtectedPolicyArtifactBinding
{
    public string ArtifactKey { get; }
    public string FileName { get; }
    public long FileLength { get; }
    public ExactSha256Digest FileDigest { get; }
    public IReadOnlyList<string> ComponentKeys { get; }
    public static ProtectedPolicyArtifactBinding Create(
        string artifactKey,
        string fileName,
        long fileLength,
        ExactSha256Digest fileDigest,
        IEnumerable<string> componentKeys);
}

public sealed class ProtectedPolicyPackBinding
{
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest ExtensionExportDigest { get; }
    public BaselineWaiverPolicySnapshot BaselineWaiverPolicy { get; }
    public IReadOnlyList<ProtectedPolicyArtifactBinding> Artifacts { get; }
    public ExactSha256Digest BindingDigest { get; }
    public static ProtectedPolicyPackBinding Create(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest extensionExportDigest,
        BaselineWaiverPolicySnapshot baselineWaiverPolicy,
        IEnumerable<ProtectedPolicyArtifactBinding> artifacts,
        ExactSha256Digest bindingDigest);
}

public interface IProtectedPolicyPackVerifier
{
    bool Verify(
        ProtectedPolicyPackBinding protectedBinding,
        ProtectedAuthorityEnvelope packProof);
}
```

An empty extension snapshot is canonical and valid. Declarations are sorted by
`ExtensionId`; parameters by key; category lists by their existing token value.
Duplicate identities/keys, unknown evaluator kinds, namespace mismatch,
baseline `RuleId`/finding-code shadowing, lower severity/enforcement/evidence,
digest mismatch, invalid activation proof, non-positive epoch, or an active
snapshot derived from candidate-only content fail closed. The proposed
transition is separately validated and never changes the active snapshot used
for the candidate gate.

The proof contract key/version are exactly
`protocol.extension-activation-proof` / `1`. The public payload is untrusted:
its factory recomputes `PayloadDigest`, but that digest authenticates nothing.
`ActivateExtensions` compares the payload with the active kernel manifest and
snapshot, then the release-owned retained verifier authenticates the proof's
independently protected authority record and envelope, requires exact
Ed25519 signature verification with the immutable Policy public key, and
requires the envelope `PayloadDigest` to equal the recomputed payload digest.
Only then does
Conformance internally mint the trusted activation binding and copy the
authenticated authority-record digest; callers cannot mint that binding. All
digests must be nonzero, the target commit uses the exact Git grammar, and the
epoch is positive. A consumer- or candidate-implemented `Proves(...)` callback
is deliberately absent. A caller implementation of any of the four public
verifier interfaces confers no authority; only the retained Policy verifier
authenticating the external envelope can mint the trusted binding.

`ProtectedAuthorityEnvelope.Create` copies exactly 64 signature bytes into a
private array and
recomputes `EnvelopeDigest`; it does not authenticate them. The signed bytes are
`protocol.protected-authority-envelope-signing/1\n`, issuer key ID, algorithm,
contract key/version, raw payload digest, raw authority-record digest and
positive signed 64-bit authority epoch. `EnvelopeDigest` frames the same fields
under `protocol.protected-authority-envelope/1\n` followed by the signature.
The retained verifier requires issuer/key algorithm equality with the immutable
Policy export, verifies the signature over the signing frame, requires the
contract-specific key/version and exact payload digest, and rejects zero record
identities and non-positive epochs. The envelope record/epoch must equal the
payload's expected record/epoch; this proves cryptographic authenticity and
internal consistency, not store currentness. This design has no I/O, lease,
challenge or latest-record oracle and therefore makes no replay/freshness claim.
Exact Policy-owned verifier code, the trusted Policy artifact bytes and the
retained key bytes anchor verification; a digest-only envelope is never
accepted.
`GetSignatureCopy()` returns a fresh clone on every call. The verifier snapshots
that clone once before digest/signature checks. The retained public key is also
an internal private copy and is never returned. Tests mutate source arrays,
returned copies and a concurrent caller-owned buffer; envelope/public-key bytes
and digests remain unchanged.

The internal project-neutral fixture export is exactly key
`protocol.policy.extension-protected.test-fixture`, version `1`, issuer
`protocol.authority.test`, and RFC8032 public key
`D75A980182B10AB7D54BFED3C964073A0EE172F3DAA62325AF021A68F707511A`
(SHA-256 `21FE31DFA154A261626BF854046FD2271B7BED4B6ABE45AA58877EF47F9721B9`).
The authority packet adds exactly one Policy friend declaration,
`[assembly: InternalsVisibleTo("MeAndAI.Protocol.Conformance.Tests")]`, in
`MeAndAI.Protocol.Policy/Properties/AssemblyInfo.cs`; the ownership oracle
requires that sole literal and no other Policy friend. Conformance.Tests uses
that boundary to construct the test export with the same four internal Policy
verifier types; exact call-site tests require zero production callers.
Its precomputed known-answer corpus uses payload bytes `11` x32, authority
record `22` x32 and epoch `1`:

| Proof contract | Signing bytes / SHA-256 | Envelope bytes / SHA-256 / Base64 |
| --- | --- | --- |
| `protocol.extension-activation-proof` / `1` | `202` / `E261D35024A39F8A8D02514D786AF986482C773A4407E182A0276B54D3ED497C` | `258` / `574D2F7BC3EDDB6652197DA9A6B548477FA09A7FA9004E1EFD5F2DB2F95046E6` / `cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAI3Byb3RvY29sLmV4dGVuc2lvbi1hY3RpdmF0aW9uLXByb29mAAAAATERERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAAAAAAAAEETz6gphZl04yB9XScsKKG+RLcSMqHhh0bFdC/ssxacOFbLmpgdlE9y8Dfc2wSjz6DALqC7zAh4LlWseEcjqAE` |
| `protocol.protected-policy-pack-proof` / `1` | `203` / `3C3027F9540732A7D10AB906FCA4FBFC33D7B0F2A54019EFB523F3DD93B9C673` | `259` / `15589E6295D4B61D75686CFC2B5A1F995398BA926895AB1745ABCA5E9F834AD5` / `cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAJHByb3RvY29sLnByb3RlY3RlZC1wb2xpY3ktcGFjay1wcm9vZgAAAAExEREREREREREREREREREREREREREREREREREREREREREiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIgAAAAAAAAABPso6mNr9DGW1Z8Sz5+6VkfXjo7IzUGzmovEeVvIASgaUzo2OKOXhS2s4JkbFsJQPVQfQGwXc89r06bBA8KVPDA==` |
| `protocol.protected-disposition-authority-proof` / `1` | `213` / `91808B04E4D7C27E2115D0EDFECED28EE9EB1CB3531BDE753598F9698A8B600E` | `269` / `7B037B204681A581B63FA16EC3C0148E3CF640C61159BFAE7E57AD18684118C0` / `cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAALnByb3RvY29sLnByb3RlY3RlZC1kaXNwb3NpdGlvbi1hdXRob3JpdHktcHJvb2YAAAABMRERERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIAAAAAAAAAAXkLkGomjGxp/alANRgwgHd62PyrWeVMZujW+S5z/Mid0LGZgtsKIaOnHPlR0webx5KYNm+bhlk0d3y9mO0DygE=` |
| `protocol.predecessor-trust-proof` / `1` | `199` / `FEA89ABBF9A34EA939B77DAAC3C7BA3D9B4406876E4C41D928027719E43E3DCA` | `255` / `4670533144F7467A51D9A94356077C4B71073673F9571BC0ACEEDC8B4098390D` / `cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAIHByb3RvY29sLnByZWRlY2Vzc29yLXRydXN0LXByb29mAAAAATERERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAAAAAAAAEA/fXwwvArk4VXYXXdxku0mcEf6a0JtPrwa23M5M2CXe65veSgzWM99zYDW7u/Yy0kTz/EJWUdenFvBFhg+QsO` |

Every contract, field, public-key byte and signature byte has a mutation
rejection oracle. This corpus proves only the Ed25519 envelope implementation;
its dummy payload digest never authenticates or transfers authority to a
semantic payload.

`ProjectNeutralProtectedAuthorityFixture` lives only in the authority test
file. It owns the public RFC8032 test seed
`9D61B19DEFFD5A60BA844AF492EC2CC44449C5697B326919703BAC031CAE7F60`
and exposes exact contract-specific methods: activation accepts one
`ProtectedExtensionActivationPayload`; pack accepts one
`ProtectedPolicyPackBinding` plus that exact activation payload and derives the
record/epoch only from the activation; disposition accepts one
`ProtectedDispositionAuthorityPayload`; predecessor accepts one
`PredecessorTrustPayload`. Each method recomputes its exact payload/binding
digest, signs that digest and the typed record/epoch tuple with the test key,
constructs the envelope, and verifies it through the same Policy-owned
implementation before returning the friend-only binding. Cross-record/epoch
pack mutations are rejected. It accepts no raw digest, caller key, signer,
verifier callback or
arbitrary bytes. Later test files consume this unchanged helper; no production
source references it. The known public test seed and signing operation exist
only in Conformance.Tests and never enter a product artifact or production
authority claim.

[FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md)
later supplies only the sealed protected payload and proof obtained from its
store and owns the monotonic CAS/latest-state decision; it does not supply or
replace any verifier. Policy owns the immutable release verifier, and
[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
later freezes a non-forgeable current-authority composition ingress. Until that
separate accepted design exists, this public method accepts only the canonical
empty snapshot and rejects every nonempty production activation as
`protocol.policy.activation-proof-invalid`, even with a valid historical
signature. Project-neutral [TEST-0211](test-cases.md#test-0211) tests use an internal friend-only current-
authority fixture to exercise nonempty semantic projection; that fixture and
its method are absent from the public API and cannot enter production evidence.

`ProtectedPolicyPackBinding` is the successor manifest overlay supplied through
the already trusted release-loader/kernel boundary. Its artifact rows are
exactly `protocol.artifact.domain`, `protocol.artifact.conformance-abstractions`,
`protocol.artifact.conformance-runtime`, and `protocol.artifact.policy`, with
file names respectively `MeAndAI.Protocol.Domain.dll`,
`MeAndAI.Protocol.Conformance.Abstractions.dll`,
`MeAndAI.Protocol.Conformance.dll`, and `MeAndAI.Protocol.Policy.dll`. Each row
binds positive exact file length, SHA-256 bytes and an ordinal
component-key list; every export component key occurs in exactly one row and
its assembly name must match that row's file name. Every row's file name,
positive length, and digest must also equal exactly one same-name
`ArtifactFileBinding` in the already activated complete manifest; component-key
membership is derived from the immutable export and compared with the row, not
trusted from caller input. Missing, extra, duplicate, or non-ordinal rows fail.
Those rows bind the exact Domain, Abstractions, Conformance, and Policy bytes,
including the four Policy-owned verifier implementations and Policy evaluator,
to the exact
release-owned export digest. `BindingDigest` is recomputed from every field and
artifact row. The kernel accepts it only through the exact release-owned
`IProtectedPolicyPackVerifier` component declared by the immutable Policy
export, requires a valid `protocol.protected-policy-pack-proof` / `1` signed
envelope whose payload digest equals `BindingDigest`, and requires its manifest
to equal the already activated complete manifest. The signed binding therefore
authenticates the exact complete `BaselineWaiverPolicySnapshot`; the
qualification-only initial Policy export owns no substitute overlay. Component
identity, assembly identity, MVID, self-computed digest, or
caller equality does not confer authority. The existing
[TEST-0210](test-cases.md#test-0210) manifest and
five-rule `InitialRuleQualificationPolicy.Export` remain byte- and behavior-
identical qualification-only predecessors; a negative qualification test proves
that neither can mint a complete baseline, protected binding, or protected
verdict.

### Protocol-owned evaluator contract

```csharp
public sealed class ExtensionApplicabilityInput
{
    public ExtensionRuleDeclaration Extension { get; }
    public ExecutionProfile Profile { get; }
    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability;
    public QualifiedEvidenceHandle GetContextProof(string slotKey);
    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
}

public sealed class ExtensionEvaluationInput
{
    public ExtensionRuleDeclaration Extension { get; }
    public ExecutionProfile Profile { get; }
    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability;
    public QualifiedEvidenceHandle GetContextProof(string slotKey);
    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
}

public sealed class ExtensionParameterDeclaration
{
    public string Key { get; }
    public string ValueGrammar { get; }
    public int MaximumUtf8Bytes { get; }
    public static ExtensionParameterDeclaration Create(
        string key,
        string valueGrammar,
        int maximumUtf8Bytes);
}

public sealed class ExtensionEvaluatorKindDeclaration
{
    public string EvaluatorKind { get; }
    public string EvaluatorVersion { get; }
    public ComponentTypeIdentity Component { get; }
    public IReadOnlyList<ExtensionParameterDeclaration> Parameters { get; }
    public IReadOnlyList<string> ApplicabilitySlotKeys { get; }
    public IReadOnlyList<string> EvaluationSlotKeys { get; }
    public IReadOnlyList<FindingDeclaration> Findings { get; }
    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }
    public bool WaiverAllowed { get; }
    internal static ExtensionEvaluatorKindDeclaration Create(
        string evaluatorKind,
        string evaluatorVersion,
        ComponentTypeIdentity component,
        IEnumerable<ExtensionParameterDeclaration> parameters,
        IEnumerable<string> applicabilitySlotKeys,
        IEnumerable<string> evaluationSlotKeys,
        IEnumerable<FindingDeclaration> findings,
        IEnumerable<EvaluationFailureCode> failureCodes,
        bool waiverAllowed);
}

public sealed class ExtensionFindingIntent
{
    public FindingCode Code { get; }
    public QualifiedEvidenceHandle PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }
    public string StableStateToken { get; }
    public string? StableStateValue { get; }
    internal static ExtensionFindingIntent Create(
        FindingCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences,
        string stableStateToken,
        string? stableStateValue);
}

public sealed class ExtensionEvaluationIntent
{
    public IReadOnlyList<ExtensionFindingIntent> Findings { get; }
    public IReadOnlyList<EvaluationFailureIntent> Failures { get; }
    internal static ExtensionEvaluationIntent Create(
        IEnumerable<ExtensionFindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures);
}

public interface IExtensionEvaluator
{
    ApplicabilityIntent EvaluateApplicability(
        ExtensionApplicabilityInput input,
        CancellationToken cancellationToken);

    ExtensionEvaluationIntent Evaluate(
        ExtensionEvaluationInput input,
        CancellationToken cancellationToken);
}

internal sealed class ExtensionEvaluatorRegistration
{
    public ExtensionEvaluatorKindDeclaration Declaration { get; }
    public IExtensionEvaluator Evaluator { get; }
    internal static ExtensionEvaluatorRegistration Create(
        ExtensionEvaluatorKindDeclaration declaration,
        IExtensionEvaluator evaluator);
}

public sealed class ExtensionPolicyPackExport
{
    public string ExportKey { get; }
    public string ExportVersion { get; }
    public ExactSha256Digest ExportDigest { get; }
    public string AuthorityIssuerKeyId { get; }
    public string AuthorityAlgorithm { get; }
    public ExactSha256Digest AuthorityPublicKeyDigest { get; }
    public ComponentTypeIdentity ActivationVerifierComponent { get; }
    public ComponentTypeIdentity PolicyPackVerifierComponent { get; }
    public ComponentTypeIdentity DispositionVerifierComponent { get; }
    public ComponentTypeIdentity PredecessorVerifierComponent { get; }
    public IReadOnlyList<ExtensionEvaluatorKindDeclaration> EvaluatorKinds { get; }
    public IReadOnlyList<ComponentTypeIdentity> Components { get; }
}
```

`ExtensionPolicyPackExport` has a private constructor and an internal
`Create(exportKey, exportVersion, exportDigest, authorityIssuerKeyId,
authorityAlgorithm, authorityPublicKeyBytes, activationVerifier,
policyPackVerifier, dispositionVerifier, predecessorVerifier, registrations)`
factory. It copies exactly 32 public-key bytes into immutable storage, derives
their digest and each verifier component identity from the release-owned
runtime instances, and rejects advertised digest/type drift. The four
release-owned verifier role constants are exactly
`protocol.verifier.extension-activation` / `1`,
`protocol.verifier.protected-policy-pack` / `1`,
`protocol.verifier.protected-disposition` / `1`, and
`protocol.verifier.predecessor-trust` / `1`. The internal factory combines
those role-known key/version pairs with the actual runtime assembly/type and
requires assembly `MeAndAI.Protocol.Policy` plus, respectively, internal types
`ExtensionActivationEnvelopeVerifier`, `ProtectedPolicyPackEnvelopeVerifier`,
`ProtectedDispositionEnvelopeVerifier`, and `PredecessorTrustEnvelopeVerifier`
in namespace `MeAndAI.Protocol.Policy.ProtectedPolicy`; caller metadata can
never supply or replace an identity. The immutable production singleton is
exactly export key `protocol.policy.extension-protected`, version `1`, issuer
`protocol.authority.unprovisioned.extension-policy.v1`, algorithm `ed25519`,
and public-key bytes
`4C4B29AD97DBDEFA3087835D1AEAB0221EE8AE4DF5D692D84360D74F607D7365`
(SHA-256 `FBF4A343910D98B0C13F1FC3D9DE513C5D53E0B7FFDB31346648FDF2912E6EA4`).
Those deterministic bytes are an unprovisioned fail-closed sentinel, not an
RFC private seed and not a minting authority; a future provisioned key requires
a versioned accepted design/release.
`AuthorityAlgorithm` is exactly `ed25519`; no production private key or signing
operation enters any product artifact.
Its internal registration snapshot is created only by
the friend Policy assembly; `MeAndAI.Protocol.Policy.ProtectedExtensionPolicy`
exposes the sole public immutable `Export` singleton. Components are the exact
ordinal runtime assembly/type projection of registrations and all four verifier
components, and `ExportDigest` is recomputed from that typed projection. It is
qualification-only and contains no complete-baseline waiver authority. Callers
cannot register an `IExtensionEvaluator` or build an export.

`ExtensionFindingIntent` and `ExtensionEvaluationIntent` live in
Conformance.Abstractions, but their factories are internal; the sole production
call site is the friend Policy implementation, while the existing Conformance
test friend may construct project-neutral fixtures. They snapshot collections and reject
null or duplicate semantic tuples. For
`protocol.extension.repository-path-required`, the only legal stable-state
tuples are `missing` plus null, or `kind-mismatch` plus one exact
`RepositoryEntryKind.Value`; every other token/value pair is a policy-integrity
failure. Conformance copies that tuple into the resulting finding, and the
release-owned projector independently validates it against the declaration
before computing stable identity.
`ExtensionEvaluatorKindDeclaration.Create` is the sole construction seam; it
copies and ordinally orders parameters, slots, findings and failure codes and
rejects nulls, duplicate keys/codes, cross-list slot duplication, unknown
tokens and bounds before the Policy export retains the declaration.

The same internal snapshot retains the exact release-owned activation, pack,
disposition, and predecessor verifier instances; these instances are visible
only to the friend Conformance runtime. Public kernel methods never accept a
verifier callback or registration from the caller. A caller-created interface
implementation is therefore inert even if it copies a component name.

Registrations are release-owned and unique by `EvaluatorKind`. An extension
may parameterize only one registered kind. It cannot supply code, assembly/type
names, raw JSON, delegates, expressions, scripts, or reflection instructions.
`ExtensionEvaluationInput` mirrors the capability-only access of
`RuleEvaluationInput`; its constructor and `IRuleInputAccess` carrier remain
internal to the runtime. It therefore does not expose or reference the
Conformance-owned `SealedEvaluationContext` across the Abstractions boundary.

The initial evaluator-kind inventory is exactly one row:
`protocol.extension.repository-path-required` / version `1`, implemented by
component key `protocol.evaluator.extension.repository-path-required`, version
`1`, assembly `MeAndAI.Protocol.Policy`, type
`MeAndAI.Protocol.Policy.ProtectedPolicy.RepositoryPathRequiredExtensionEvaluator`.
The factory combines this role-known identity with the evaluator instance's
actual `GetType()` and rejects drift; callers do not supply component metadata.
Every export component key is globally unique and maps to exactly one artifact
row.
It requires exactly two ordinal parameters and rejects missing, extra, or
duplicate keys: `path` is strict UTF-8, `1..4,096` bytes, and follows the
existing normalized repository-relative-path grammar; `kind` is exactly one of
`directory`, `file`, `symbolic-link`, or `git-link`. Its applicability-slot
inventory is empty and its evaluation-slot inventory is exactly
`protocol.slot.repository-tree`. The kernel first applies the declaration's
static subject/surface/snapshot/operation categories: a category mismatch is
NotApplicable without calling the evaluator; a match invokes
`EvaluateApplicability`, which returns Applicable with no references and does
not inspect evidence. Evaluation emits no finding when the exact path/kind row
exists and exactly one
`protocol.extension.required-path-missing` / `protocol.finding.error` /
`protocol.remediation.restore-required-path` finding against the repository-
tree context proof when absent or kind-mismatched. It declares no evaluator
failure codes, is non-waivable, performs no acquisition or I/O, enumerates at
most `200,000` already-sealed entries, and checks cancellation every `1,024`
rows. An unsealed/missing slot is unresolved and blocks; it never triggers
hidden acquisition. Consumer declarations cannot replace these slots,
findings, severity, remediation, failure codes, bounds, or waiver policy.

### Waiver and historical-debt inputs

```csharp
public sealed class PolicyRuleIdentity
{
    public RuleId? BaselineRuleId { get; }
    public ExtensionId? ExtensionId { get; }
    public RuleRevision Revision { get; }
    public static PolicyRuleIdentity Baseline(
        RuleId ruleId,
        RuleRevision revision);
    public static PolicyRuleIdentity Extension(
        ExtensionId extensionId,
        RuleRevision revision);
}

public sealed class StableFindingKey
{
    public ExactSha256Digest Value { get; }
    public static StableFindingKey Create(
        PolicyRuleIdentity rule,
        FindingCode findingCode,
        ExactSha256Digest locationDigest,
        ExactSha256Digest evidenceDigest,
        ExactSha256Digest expectedValueDigest);
}

public sealed class WaiverTargetSelector
{
    public string Value { get; }
    public static WaiverTargetSelector Parse(string value);
}

public sealed class WaiverScope
{
    public string Value { get; }
    public static WaiverScope Parse(string value);
}

public sealed class ProtectedFindingIdentity
{
    public PolicyRuleIdentity Rule { get; }
    public FindingCode FindingCode { get; }
    public ExactSha256Digest LocationDigest { get; }
    public ExactSha256Digest EvidenceDigest { get; }
    public ExactSha256Digest ExpectedValueDigest { get; }
    public StableFindingKey StableKey { get; }
    public static ProtectedFindingIdentity Create(
        PolicyRuleIdentity rule,
        FindingCode findingCode,
        ExactSha256Digest locationDigest,
        ExactSha256Digest evidenceDigest,
        ExactSha256Digest expectedValueDigest,
        StableFindingKey stableKey);
}

public sealed class WaiverDeclaration
{
    public ProtectedFindingIdentity Finding { get; }
    public WaiverTargetSelector TargetSelector { get; }
    public WaiverScope Scope { get; }
    public string Rationale { get; }
    public string Owner { get; }
    public ReviewedAuthorityPermalink DecisionAuthority { get; }
    public ExactSha256Digest TrustedBaseAuthorityDigest { get; }
    public DateTimeOffset CreatedUtc { get; }
    public DateTimeOffset ExpiresUtc { get; }
    public ExactSha256Digest EvidenceDigest { get; }
    public ExactSha256Digest DeclarationDigest { get; }
    public static WaiverDeclaration Create(
        ProtectedFindingIdentity finding,
        WaiverTargetSelector targetSelector,
        WaiverScope scope,
        string rationale,
        string owner,
        ReviewedAuthorityPermalink decisionAuthority,
        ExactSha256Digest trustedBaseAuthorityDigest,
        DateTimeOffset createdUtc,
        DateTimeOffset expiresUtc,
        ExactSha256Digest evidenceDigest);
}

public sealed class BaselineRuleWaiverPolicy
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public bool WaiverAllowed { get; }
    public static BaselineRuleWaiverPolicy Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        bool waiverAllowed);
}

public sealed class BaselineWaiverPolicySnapshot
{
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<BaselineRuleWaiverPolicy> Rules { get; }
    public static BaselineWaiverPolicySnapshot Create(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest snapshotDigest,
        IEnumerable<BaselineRuleWaiverPolicy> rules);
}

public sealed class HistoricalDebtEntry
{
    public ProtectedFindingIdentity Finding { get; }
    public string ProtocolVersion { get; }
    public string AccountableOwner { get; }
    public ReviewedAuthorityPermalink Authority { get; }
    public string ReviewCondition { get; }
    public ExactSha256Digest StableEvidenceDigest { get; }
    public ExactSha256Digest RecurrenceRecordDigest { get; }
    public DateTimeOffset? ClosedUtc { get; }
    public DateTimeOffset? ExpiresUtc { get; }
    public ExactSha256Digest TrustedBaseAuthorityDigest { get; }
    public ExactSha256Digest EntryDigest { get; }
    public static HistoricalDebtEntry Create(
        ProtectedFindingIdentity finding,
        string protocolVersion,
        string accountableOwner,
        ReviewedAuthorityPermalink authority,
        string reviewCondition,
        ExactSha256Digest stableEvidenceDigest,
        ExactSha256Digest recurrenceRecordDigest,
        DateTimeOffset? closedUtc,
        DateTimeOffset? expiresUtc,
        ExactSha256Digest trustedBaseAuthorityDigest);
}

public sealed class WaiverSnapshot
{
    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<WaiverDeclaration> Waivers { get; }
    public static WaiverSnapshot Create(
        ExactSha256Digest snapshotDigest,
        IEnumerable<WaiverDeclaration> waivers);
}

public sealed class HistoricalDebtSnapshot
{
    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<HistoricalDebtEntry> Entries { get; }
    public static HistoricalDebtSnapshot Create(
        ExactSha256Digest snapshotDigest,
        IEnumerable<HistoricalDebtEntry> entries);
}

public sealed class ProtectedDispositionAuthorityPayload
{
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest TrustedBaseAuthorityDigest { get; }
    public ExactSha256Digest AuthoritySetDigest { get; }
    public ExactSha256Digest WaiverSnapshotDigest { get; }
    public ExactSha256Digest DebtSnapshotDigest { get; }
    public ExactSha256Digest EvidenceSetDigest { get; }
    public ExactSha256Digest ExpectedAuthorityRecordDigest { get; }
    public long AuthorityEpoch { get; }
    public DateTimeOffset EvaluationUtc { get; }
    public ExactSha256Digest PayloadDigest { get; }
    public static ProtectedDispositionAuthorityPayload Create(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest trustedBaseAuthorityDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest waiverSnapshotDigest,
        ExactSha256Digest debtSnapshotDigest,
        ExactSha256Digest evidenceSetDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        long authorityEpoch,
        DateTimeOffset evaluationUtc);
}

public sealed class ProtectedDispositionAuthority
{
    public ProtectedDispositionAuthorityPayload Payload { get; }
    public ExactSha256Digest AuthorityRecordDigest { get; }
    public ExactSha256Digest AuthorityEnvelopeDigest { get; }
    public ExactSha256Digest BindingDigest { get; }
    internal static ProtectedDispositionAuthority Create(
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof);
}

public interface IProtectedDispositionAuthorityVerifier
{
    bool Verify(
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof);
}
```

`ProtectedDispositionAuthorityPayload.Create` recomputes only its own payload
digest; it does not authenticate authority. `EvaluateProtected` accepts that
public payload plus a signed `ProtectedAuthorityEnvelope`. The retained release
verifier requires contract key/version
`protocol.protected-disposition-authority-proof` / `1`, exact payload digest,
an independently authenticated authority record, and a valid signature under
the Policy export's release-owned issuer key. Conformance calls the internal
`ProtectedDispositionAuthority.Create` only after this verification, copying
the independently authenticated record and envelope digests rather than
recomputing authority from caller fields. Tests use an internal project-neutral
envelope fixture. [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md)
may persist and return payload/proof but exposes no
minting API or verifier replacement.

Waiver and debt snapshots are assertions until the exact release-owned
`IProtectedDispositionAuthorityVerifier` accepts their protected authority.
The verifier runtime type must equal the Policy export component, the authority
manifest/trusted-base/authority-set/evidence-set must equal the already active
kernel projection, and the kernel recomputes both complete snapshot digests.
`TrustedBaseAuthorityDigest` is exactly the raw active complete
`ManifestDigest`; it is not a caller-selected or separately derived authority.
Every waiver/debt row and the disposition payload must carry that same raw
digest or verification fails before matching.
The sole evaluation instant is
`ProtectedDispositionAuthority.Payload.EvaluationUtc`;
there is no caller clock parameter and no backdating path.
Each current waiver/debt snapshot contains at most one row per
`StableFindingKey`; duplicates fail before digesting or evaluation. A closed
debt row is that key's sole current history pointer and recurrence remains the
authenticated opaque digest. `FindingDispositionResult` is a closed union:
`ActiveViolation` retains neither row, `Waived` retains exactly its Waiver and
null Debt even if a debt matched, and `HistoricalDebt` retains exactly its Debt
and null Waiver. The canonical dispositions outcome entry asserts the same
branch.

`PolicyRuleIdentity` is a closed exactly-one-of union. `StableFindingKey` is
SHA-256 over `protocol.stable-finding-key/1\n`, the rule union tag and exact
identity/revision, finding-code token, raw location/evidence/expected-value
digests in that order. The tag is `00` for baseline then RuleId, `01` for
extension then ExtensionId; revision is big-endian unsigned 32-bit. Its factory
computes the value; `ProtectedFindingIdentity.Create` independently recomputes
and rejects a supplied stable-key mismatch.
`WaiverTargetSelector` is `repository:<normalized-relative-path>` or
`evidence:<64-lowercase-hex>`; `WaiverScope` is exactly `finding`, `path`, or
`repository`. This makes finding matching stable across runtimes and excludes
untyped free-form identity.

Scope never widens the exact protected finding identity. The legal matrix is:
`finding` + `evidence:<Finding.EvidenceDigest>`; `path` + `repository:<path>`
where the primary reference's direct/root canonical location is that exact
repository path; or `repository` + `evidence:<ScopeDigest>` where `ScopeDigest`
is SHA-256 of `protocol.stable-evidence-scope/1\n`, subject identity, source
identity, surface token and snapshot-kind token in that order. Repository
identity is not a fifth field: for repository surfaces it is exactly
`Target.SourceIdentity`; `Target.SubjectIdentity` and `Target.SourceIdentity`
remain two independent, nonempty opaque identities and are never required to
be equal. This shared stable-scope projection excludes target/boundary commit
identities, timestamps and qualification proof, and is also consumed by stable
location and stable evidence identity. Related references never satisfy a
selector. Any other pair, selector mismatch, provider location under path
scope, or attempt to waive another stable key is invalid. Later-time,
unrelated-commit and proof mutations preserve `ScopeDigest`; changing either
independently bounded identity changes it, while a valid subject/source-unequal
fixture remains accepted. The repository vector `repo`/`repo`/`repository`/
`exact-commit` is exactly `79` bytes, SHA-256
`26FB461A9FA65B2E829AB5446C43B3732AD9668B203F165D7EC30DD32E6FD7D6`,
Base64
`cHJvdG9jb2wuc3RhYmxlLWV2aWRlbmNlLXNjb3BlLzEKAAAABHJlcG8AAAAEcmVwbwAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdA==`;
later-time and unrelated-target mutations remain equal, while either identity,
surface or snapshot-kind one-byte mutation differs; a separate positive vector
uses distinct subject and source identities and recomputes the digest.

The runtime owns one internal canonical qualified-reference identity. Its frame
is `protocol.qualified-evidence-reference/1\n`, then kind token, raw manifest
digest, unsigned catalog version, slot key, requirement key, the exact scope,
raw qualification-proof digest, optional root tag/value, optional direct
location tag/value, derivation count/rows, optional expected-selector-parent
kind, and optional selector. The scope is subject identity, source identity,
surface token, snapshot token, target identity, boundary snapshot token,
boundary identity, signed started/completed UTC ticks. Location tags are `00`
snapshot, `01` repository, `02` provider, `03` release asset, followed by the
same scope and then respectively no fields; path plus optional blob/line/anchor/
property tags; provider service/object/stable/version/field plus optional line/
fragment; or release object/tag/asset/raw asset digest. A root frames its scope,
schema key/version, raw content digest, location, ordinal requirement keys and
captured UTC ticks. Each derivation frames component key/version/assembly/type,
artifact file/raw digest, optional model key/version/component, optional
capability key/version/component, typed-node kind/identity and location. A
selector frames key/schema/canonical value. All nullable members use `00`
absent or `01` plus value; derivation order is retained only after exact ordinal
validation by its complete tuple.

The full reference digest is SHA-256 of that frame and is used by outcome/audit
rows. Stable finding identity deliberately uses two different projections.
`protocol.stable-evidence-location/1\n` frames subject/source/surface/snapshot-
kind but excludes enclosing target/boundary commit identities and timestamps,
then typed coordinates: repository path, provider service/object/stable-object/
field, release tag/asset, or snapshot selector. `protocol.stable-evidence-identity/1\n` frames
kind, manifest, catalog, slot, requirement, that stable scope, optional root
schema/version/content/stable-location/requirement keys, optional direct stable
location, the same derivation semantic fields and artifact digests, optional
expected-parent and selector; it excludes qualification-proof and every
acquisition/capture timestamp and unrelated enclosing commit identity. Repository
blob/content, provider version/content, release object/asset digest and selector
state enter this evidence projection rather than location. The finding
`LocationDigest` and `EvidenceDigest`
are SHA-256 of these stable projections. The primary direct location wins,
otherwise root location, otherwise the canonical snapshot location. Therefore
the same path/object/content observed at a later unrelated commit has the same
stable key while its full reference digest changes; content/version or typed-
coordinate mutation changes the stable key. Exact later-time/unrelated-commit/
proof equality and content/version inequality vectors are mandatory.

Each release-owned baseline finding declaration and extension evaluator kind
owns one exact stable projector; an unknown projector fails closed. For
`protocol.extension.required-path-missing`, location is the declaration's
normalized repository `path` selector (not the repository-tree context-proof
commit), expected value is its exact `kind`, and stable evidence is
`protocol.extension.required-path-state/1\n`, path, expected kind, state token
`missing` or `kind-mismatch`, then optional actual kind. Thus an unrelated tree
change preserves the key, while appearance or kind change alters the finding
state/key. The full context proof remains in the outcome/audit reference.

The expected-value digest frames
`protocol.finding-expected-value/1\n`: baseline tag `00`, rule ID/revision and
the matched immutable `FindingDeclaration` code/severity/remediation plus
primary/related reference-kind lists; extension tag `01`, raw extension
definition digest, evaluator kind/version and the matched immutable evaluator-
kind finding projection with the same fields. Thus a baseline finding with no
separate expected-value member has one explicit declaration-derived digest,
never an invented empty value.

The simple qualified-reference vector is kind `context-proof`, manifest byte
`11` repeated, catalog `1`, slot `slot`, requirement `requirement`, repository/
exact-commit scope for subject/source and forty-zero target/boundary identities,
ticks `0..1`, proof byte `22` repeated, and all four optional/list tails empty.
It is exactly `327` bytes, SHA-256
`F58FF97C79B7EEE2E3F96AD55290B759E0805C76728032CA77E436ED806B2277`,
Base64 `cHJvdG9jb2wucXVhbGlmaWVkLWV2aWRlbmNlLXJlZmVyZW5jZS8xCgAAAA1jb250ZXh0LXByb29mEREREREREREREREREREREREREREREREREREREREREREAAAABAAAABHNsb3QAAAALcmVxdWlyZW1lbnQAAAAHc3ViamVjdAAAAAZzb3VyY2UAAAAKcmVwb3NpdG9yeQAAAAxleGFjdC1jb21taXQAAAAoMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMAAAAAxleGFjdC1jb21taXQAAAAoMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMAAAAAAAAAAAAAAAAAAAAAEiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIgAAAAAAAAAA`.
Every field and optional tag has a one-byte mutation rejection oracle.

`ExtensionFinding` is minted only by Conformance from the internal-factory
`ExtensionFindingIntent`; it preserves the exact stable-state token/value
beside the qualified references. `ProtectedFinding.Baseline` and `.Extension`
are internal kernel factories.
They require exactly one finding branch, exact rule/extension ID, revision and
finding-code agreement, recompute the location/reference/expected digests from
the underlying primary reference plus the active immutable declaration, and
recompute `StableFindingKey`; any supplied identity mismatch is
`protocol.policy.disposition-authority-invalid`. Related references still enter
the outcome frame, but cannot substitute for the primary stable identity.
Across one protected evaluation, the baseline/extension union must contain one
globally unique `StableFindingKey` per finding. A repeated key is rejected
before disposition; a hash collision between byte-distinct canonical identity
frames is an integrity failure, never a lookup tie or last-writer win.

A waiver is valid only for one exact current finding identity, selector/scope,
trusted base, and authority time; baseline eligibility comes from the complete
trusted overlay, while an extension can be waived only when its protocol-owned
evaluator-kind declaration permits it. The initial required-path kind is
non-waivable. Acquisition, integrity, execution, trust-anchor, activation-
proof, and self-consumption failures are always non-waivable. Debt is valid
only in `Prospective` against exact unchanged finding identity, rule revision,
stable primary-evidence identity, baseline protocol version, and protected
recurrence chain. The entry's `ProtocolVersion` must ordinally equal
`baseline.Catalog.ProtocolVersion` and the internally minted
`RuntimeQualificationBinding.ProtocolVersion`; the entry's
`StableEvidenceDigest` must equal the finding evidence digest;
`RecurrenceRecordDigest` links the prior authenticated debt snapshot/history.
`ClosedUtc` marks an authenticated closure but retains the row for resurrection
detection. Changed, missing, expired, resurrected, or already-closed evidence
never yields `HistoricalDebt`; its corresponding finding is
`ActiveViolation`. Candidate content cannot approve either snapshot.
Waiver construction requires `CreatedUtc < ExpiresUtc`; applicability is the
half-open interval `CreatedUtc <= EvaluationUtc < ExpiresUtc`, so future-created
and expiry-equality waivers are invalid. A debt row with no expiry is active;
with an expiry it is expired exactly when `EvaluationUtc >= ExpiresUtc`.
Golden/equality tests own creation equality, just-before-expiry, expiry equality
and just-after-expiry without consulting a process clock. Exact protocol-version
equality passes; a one-byte version mutation remains a structurally valid but
mismatched debt and yields `ActiveViolation`, not `DebtInvalid`.

### Conformance outputs and enforcement

```csharp
public sealed class ExtensionFinding
{
    public ExtensionId ExtensionId { get; }
    public RuleRevision RuleRevision { get; }
    public FindingCode Code { get; }
    public FindingSeverity Severity { get; }
    public RemediationKey Remediation { get; }
    public QualifiedEvidenceReference PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
    public string StableStateToken { get; }
    public string? StableStateValue { get; }
}

public sealed class ExtensionEvaluationFailure
{
    public ExtensionId ExtensionId { get; }
    public RuleRevision RuleRevision { get; }
    public EvaluationFailureCode Code { get; }
    public QualifiedEvidenceReference PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
}

public sealed class ExtensionEvaluation
{
    public ExtensionId ExtensionId { get; }
    public RuleRevision RuleRevision { get; }
    public RuleEvaluationStatus Status { get; }
    public bool IsApplicabilityUnresolved { get; }
    public IReadOnlyList<QualifiedEvidenceReference> ApplicabilityReferences { get; }
    public IReadOnlyList<string> UnresolvedSlotKeys { get; }
    public IReadOnlyList<ExtensionFinding> Findings { get; }
    public IReadOnlyList<ExtensionEvaluationFailure> Failures { get; }
}

public sealed class ProtectedFinding
{
    public ProtectedFindingIdentity Identity { get; }
    public RuleFinding? BaselineFinding { get; }
    public ExtensionFinding? ExtensionFinding { get; }
    internal static ProtectedFinding Baseline(
        ProtectedFindingIdentity identity,
        RuleFinding finding,
        RuleDeclaration declaration);
    internal static ProtectedFinding Extension(
        ProtectedFindingIdentity identity,
        ExtensionFinding finding,
        ExtensionRuleDeclaration declaration,
        ExtensionEvaluatorKindDeclaration evaluatorKind);
}

public sealed class FindingDispositionResult
{
    public ProtectedFinding Finding { get; }
    public FindingDisposition Disposition { get; }
    public WaiverDeclaration? Waiver { get; }
    public HistoricalDebtEntry? Debt { get; }
}

public sealed class ActivatedExtensionPolicy
{
    public ExtensionCatalogSnapshot Snapshot { get; }
    public ProtectedExtensionActivationPayload ActivationPayload { get; }
    public ProtectedPolicyPackBinding PolicyPackBinding { get; }
    public ExtensionPolicyPackExport Policy { get; }
    public ExactSha256Digest AuthoritySetDigest { get; }
    public ExactSha256Digest ActivationRecordDigest { get; }
    public long ActivationEpoch { get; }
}

public sealed class ProtectedPolicyEvaluation
{
    public RuntimeQualificationBinding RuntimeBinding { get; }
    public CompleteCatalogEvaluation Baseline { get; }
    public ActivatedExtensionPolicy ActiveExtensions { get; }
    public ProtectedDispositionAuthority DispositionAuthority { get; }
    public ProposedExtensionTransition? ProposedTransition { get; }
    public IReadOnlyList<ExtensionEvaluation> ExtensionEvaluations { get; }
    public IReadOnlyList<FindingDispositionResult> Dispositions { get; }
    public ExactSha256Digest EvidenceSetDigest { get; }
    public ExactSha256Digest OutcomeSetDigest { get; }
    public ConformanceVerdict Verdict { get; }
    public EnforcementDecision Enforcement { get; }
}

public sealed partial class ConformanceKernel
{
    public ActivatedExtensionPolicy ActivateExtensions(
        ExtensionCatalogSnapshot activeSnapshot,
        ProtectedExtensionActivationPayload activationPayload,
        ProtectedAuthorityEnvelope activationProof,
        ProtectedPolicyPackBinding policyPackBinding,
        ProtectedAuthorityEnvelope policyPackProof,
        ExtensionPolicyPackExport policy);

    public ProtectedPolicyEvaluation EvaluateProtected(
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        ActivatedExtensionPolicy activeExtensions,
        ProposedExtensionTransition? proposedTransition,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ProtectedDispositionAuthorityPayload dispositionPayload,
        ProtectedAuthorityEnvelope dispositionProof,
        EnforcementPhase enforcementPhase,
        CancellationToken cancellationToken = default);
}
```

`ConformanceKernel.ActivateExtensions` accepts the active snapshot, untrusted
payload, exact proof, trusted pack binding with its signed
`protocol.protected-policy-pack-proof` / `1` envelope, and release-owned registrations;
retained verifiers are never caller parameters. It returns
`ActivatedExtensionPolicy` only when every authenticated projection agrees.
The activation envelope record/epoch must equal
`activationPayload.ExpectedAuthorityRecordDigest` / `ActivationEpoch`; the
pack envelope must use that exact same record and epoch. Disposition and
predecessor payloads and envelopes must each equal the resulting active
policy's `ActivationRecordDigest` / `ActivationEpoch`. Cross-record or
cross-epoch mixing fails before semantic evaluation even when every individual
signature is valid; exact negative mutations cover all four envelopes.
`ConformanceKernel.EvaluateProtected` accepts an already completed baseline
evaluation, its exact `EvaluationClosure`, the activated policy, optional
separately reported proposed transition, exact release-owned baseline waiver
policy snapshot from the trusted pack binding, complete waiver/debt snapshots,
the protected disposition payload/proof, and enforcement phase. The retained
verifier mints the internal authority only after authentication. The
policy snapshot's manifest digest must equal the kernel manifest and its
rules must be an exact one-to-one ordinal `(RuleId, RuleRevision)` projection
of the protected baseline: no missing, extra, duplicate, retired, or revision-
drifted row is accepted. Its digest is recomputed with the typed framing below.
`CompleteCatalogEvaluation` retains an internal, non-public reference to the
exact `EvaluationClosure` consumed by `EvaluationAggregationCore`; the core
passes it at construction without exposing a new public member.
`EvaluateProtected` requires `ReferenceEquals(baseline.Closure, closure)`, the
same kernel planning session, catalog/profile identity, and exact ordinal
acquisition/terminal-evaluation projections. Any mismatch is
`protocol.policy.evaluation-context-mismatch`. This requires bounded changes
only to `CompleteCatalogEvaluation.cs` and `EvaluationAggregationCore.cs` in
the packet that first implements `EvaluateProtected`;
[TEST-0210](test-cases.md#test-0210) public surface
and evaluation behavior remain byte-for-byte compatible. No method performs
I/O or changes activation state. `BaselineRuleWaiverPolicy` is a complete successor
overlay; this slice does not mutate the immutable ContractSlice-A manifest
grammar or its [TEST-0210](test-cases.md#test-0210) public surface.
The returned evaluation retains the exact internally minted
`DispositionAuthority`, including signed snapshot identities, authority record/
envelope and `EvaluationUtc`, as typed provenance for
[SUBF-0154](README.md#subf-0154). Its binding/
time is deliberately excluded from `OutcomeSetDigest`; dispositions and
enforcement remain the semantic projection, while qualification separately
checks the authenticated authority coupling.

`EvaluateProtected` internally mints `RuntimeBinding`; no caller binding is
accepted. Protocol/source/manifest/catalog identities come from the active
baseline and activation payload, `PolicyPackBindingDigest` is the exact
authenticated `activeExtensions.PolicyPackBinding.BindingDigest`,
`RuntimeArtifactDigest` is the exact kernel-verified
`protocol.artifact.conformance-runtime` file digest in that pack, and
`TrustAnchorDigest` is the independently recomputed current anchor below. This
is trusted-loader-established artifact identity, not a claim
of cross-process executing-byte attestation; transport attestation remains
[SUBF-0154](README.md#subf-0154)/
[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)-owned.
Exactly, `ProtocolVersion = baseline.Catalog.ProtocolVersion`, `SourceCommit =
activatedManifest.SourceCommit = ActivationPayload.ActivatedTargetCommit`,
`ManifestDigest = baseline.Catalog.ManifestDigest = ActivationPayload.ManifestDigest`,
and `CatalogDigest = baseline.Catalog.CompleteInventoryDigest`; the active
snapshot is bound by the current-anchor frame, while the remaining activation-
payload fields are bound separately by the active policy and qualification
equality gates below. Any mismatch fails before the runtime binding is minted.

`EvidenceSetDigest` is never caller-selected. Conformance recomputes
`protocol.protected-evidence-set/1\n` followed by raw baseline manifest digest,
raw complete-inventory digest, raw active-extension snapshot digest, unsigned
big-endian closure completed-round count, length-prefixed closure authority
kind, unsigned catalog version, then four unsigned-count sets: ordinal admitted
slot keys; ordinal SHA-256 digests of the exact closure scope subframes; ordinal
unique sealed-acquisition `OutcomeDigest` values; and ordinal unique full
qualified-reference digests. Acquisition membership includes every sealed
closure outcome, including unused-but-sealed evidence. Reference membership is
the union of non-null acquisition context proofs and all baseline/extension
applicability, finding and failure primary/related references. Rows are sorted
by raw digest (slot keys by ordinal text); input order and object identity do
not enter. Reuse of one byte-identical full reference across applicability,
finding or failure sites is set-deduplicated once; byte-distinct frames with one
digest are a collision/integrity failure. Duplicate acquisition outcome digests
for distinct rows remain invalid. Baseline acquisitions must be the closure's
exact outcomes, the context manifest/catalog must match the baseline, and any
other duplicate semantic row or mismatch fails before hashing. The four sets are bounded at
`4,096` slots, `65,536` scopes, `200,000` outcomes and `1,000,000` references;
equality passes, first-one-over and checked overflow fail before retention.
The empty-set fixture uses digest bytes `11`/`22`/`33`, round `0`, authority
`complete-protocol-snapshot`, catalog `1` and four empty sets: `184` bytes,
SHA-256 `00884E9BEE5DC73A3399711573094D431CF1124234C169DB83A48E7880913586`,
Base64 `cHJvdG9jb2wucHJvdGVjdGVkLWV2aWRlbmNlLXNldC8xChERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMwAAAAAAAAAaY29tcGxldGUtcHJvdG9jb2wtc25hcHNob3QAAAABAAAAAAAAAAAAAAAAAAAAAA==`.
Each identity/count/row has one-byte mutation, duplicate, order and N/N+1
oracles. Disposition, overlap and independent-fixture contracts consume only
this raw recomputed digest.

Precedence is exact: invalid/missing activation, pack, signature, authority or
other integrity input throws the exact `ProtectedPolicyIntegrityException`
code and produces no `ProtectedPolicyEvaluation`. After a valid active policy
is minted, unresolved sealed baseline or active-extension evaluator evidence is
`Indeterminate`; otherwise any baseline or extension violation is
`NonConforming`; otherwise `Conforming`. `Audit` always yields `ReportOnly`.
`FullBlocking` blocks each violation not covered by an exact valid waiver.
`Prospective` blocks each new/worsened/resurrected violation, and permits only
unchanged exact debt or exact valid waivers. A disposition never changes a
`Violated` status or `NonConforming` verdict.

`RecurrenceRecordDigest` is an opaque nonzero pointer authenticated as part of
the signed current debt snapshot; the pure kernel does not claim to traverse an
external history. `ClosedUtc`, when present, must be `<= EvaluationUtc`; a
future closure invalidates the authority snapshot. A closed row never yields
`HistoricalDebt`; recurrence of its finding is `ActiveViolation`. An unclosed
row is expired at `EvaluationUtc >= ExpiresUtc` and then also yields
`ActiveViolation`. Closure takes precedence over expiry only for diagnostic
classification; neither permits prospective execution.

The canonical disposition/enforcement matrix is:

| Evaluation row | Disposition | `Audit` | `Prospective` | `FullBlocking` |
| --- | --- | --- | --- | --- |
| unresolved sealed evidence after valid activation | no trusted disposition; verdict `Indeterminate` | `ReportOnly` | `Block` | `Block` |
| conforming/no finding | none; verdict `Conforming` | `ReportOnly` | `Allow` | `Allow` |
| exact valid waiver, even when an exact debt row also exists | `Waived`; verdict remains `NonConforming` | `ReportOnly` | `Allow` | `Allow` |
| exact unchanged, unclosed, unexpired debt and no valid waiver | `HistoricalDebt`; verdict remains `NonConforming` | `ReportOnly` | `Allow` | `Block` |
| new/worsened/resurrected, missing, closed, expired, protocol-version-mismatched or otherwise mismatched debt; absent/invalid waiver | `ActiveViolation`; verdict remains `NonConforming` | `ReportOnly` | `Block` | `Block` |

Aggregate enforcement is `Block` if any row blocks in that phase; otherwise it
is the row's common `Allow`, while Audit is always `ReportOnly`. Invalid signed
authority or integrity input throws before the row matrix, creates no
evaluation, and cannot be downgraded by Audit.

### Predecessor-trusted self-consumption

```csharp
public sealed class RuntimeQualificationBinding
{
    public string ProtocolVersion { get; }
    public string SourceCommit { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest CatalogDigest { get; }
    public ExactSha256Digest PolicyPackBindingDigest { get; }
    public ExactSha256Digest RuntimeArtifactDigest { get; }
    public ExactSha256Digest TrustAnchorDigest { get; }
    public ExactSha256Digest BindingDigest { get; }
    public static RuntimeQualificationBinding Create(
        string protocolVersion,
        string sourceCommit,
        ExactSha256Digest manifestDigest,
        ExactSha256Digest catalogDigest,
        ExactSha256Digest policyPackBindingDigest,
        ExactSha256Digest runtimeArtifactDigest,
        ExactSha256Digest trustAnchorDigest);
}

public sealed class PredecessorTrustPayload
{
    public RuntimeQualificationBinding Predecessor { get; }
    public ExactSha256Digest CurrentTrustAnchorDigest { get; }
    public ExactSha256Digest ExpectedAuthorityRecordDigest { get; }
    public long AuthorityEpoch { get; }
    public string OverlapFixtureSetKey { get; }
    public string OverlapFixtureSetVersion { get; }
    public ExactSha256Digest OverlapFixtureSetDigest { get; }
    public ExactSha256Digest PredecessorOverlapEvidenceSetDigest { get; }
    public ExactSha256Digest CandidateOverlapEvidenceSetDigest { get; }
    public ExactSha256Digest PredecessorOverlapOutcomeSetDigest { get; }
    public ExactSha256Digest ExpectedCandidateBindingDigest { get; }
    public ExactSha256Digest ReviewedDifferenceSetDigest { get; }
    public string IndependentFixtureSetKey { get; }
    public string IndependentFixtureSetVersion { get; }
    public ExactSha256Digest IndependentFixtureSetDigest { get; }
    public ExactSha256Digest IndependentEvidenceSetDigest { get; }
    public ExactSha256Digest IndependentExpectedOutcomeSetDigest { get; }
    public ExactSha256Digest PayloadDigest { get; }
    public static PredecessorTrustPayload Create(
        RuntimeQualificationBinding predecessor,
        ExactSha256Digest currentTrustAnchorDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        long authorityEpoch,
        string overlapFixtureSetKey,
        string overlapFixtureSetVersion,
        ExactSha256Digest overlapFixtureSetDigest,
        ExactSha256Digest predecessorOverlapEvidenceSetDigest,
        ExactSha256Digest candidateOverlapEvidenceSetDigest,
        ExactSha256Digest predecessorOverlapOutcomeSetDigest,
        ExactSha256Digest expectedCandidateBindingDigest,
        ExactSha256Digest reviewedDifferenceSetDigest,
        string independentFixtureSetKey,
        string independentFixtureSetVersion,
        ExactSha256Digest independentFixtureSetDigest,
        ExactSha256Digest independentEvidenceSetDigest,
        ExactSha256Digest independentExpectedOutcomeSetDigest);
}

public sealed class PredecessorTrustBinding
{
    public PredecessorTrustPayload Payload { get; }
    public ExactSha256Digest AuthorityRecordDigest { get; }
    public ExactSha256Digest AuthorityEnvelopeDigest { get; }
    public ExactSha256Digest BindingDigest { get; }
    internal static PredecessorTrustBinding Create(
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof);
}

public interface IPredecessorTrustVerifier
{
    bool Verify(
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof);
}

public sealed class CandidateIndependentQualificationInput
{
    public string FixtureSetKey { get; }
    public string FixtureSetVersion { get; }
    public ExactSha256Digest FixtureSetDigest { get; }
    public ExactSha256Digest ExpectedOutcomeSetDigest { get; }
    public ProtectedPolicyEvaluation Evaluation { get; }
    public ExactSha256Digest InputDigest { get; }
    public static CandidateIndependentQualificationInput Create(
        string fixtureSetKey,
        string fixtureSetVersion,
        ExactSha256Digest fixtureSetDigest,
        ExactSha256Digest expectedOutcomeSetDigest,
        ProtectedPolicyEvaluation evaluation);
}

public sealed class CandidateIndependentQualification
{
    public CandidateIndependentQualificationInput Input { get; }
    internal static CandidateIndependentQualification Create(
        CandidateIndependentQualificationInput input);
}

public sealed class ProtectedOutcomeKind : IEquatable<ProtectedOutcomeKind>
{
    public static ProtectedOutcomeKind Rule { get; }
    public static ProtectedOutcomeKind Dispositions { get; }
    public static ProtectedOutcomeKind Verdict { get; }
    public static ProtectedOutcomeKind Enforcement { get; }
    public string Value { get; }
    public static ProtectedOutcomeKind Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ProtectedOutcomeKind? result);
    public bool Equals(ProtectedOutcomeKind? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class ProtectedOutcomeIdentity
{
    public ProtectedOutcomeKind Kind { get; }
    public PolicyRuleIdentity? Rule { get; }
    public static ProtectedOutcomeIdentity ForRule(PolicyRuleIdentity rule);
    public static ProtectedOutcomeIdentity Global(ProtectedOutcomeKind kind);
}

public sealed class ReviewedOutcomeDifference
{
    public ProtectedOutcomeIdentity Outcome { get; }
    public ExactSha256Digest PredecessorOutcomeDigest { get; }
    public ExactSha256Digest CandidateOutcomeDigest { get; }
    public ReviewedAuthorityPermalink ChangeAuthority { get; }
    public ExactSha256Digest QualificationEvidenceDigest { get; }
    public static ReviewedOutcomeDifference Create(
        ProtectedOutcomeIdentity outcome,
        ExactSha256Digest predecessorOutcomeDigest,
        ExactSha256Digest candidateOutcomeDigest,
        ReviewedAuthorityPermalink changeAuthority,
        ExactSha256Digest qualificationEvidenceDigest);
}

public sealed class SelfConsumptionQualification
{
    public PredecessorTrustBinding Predecessor { get; }
    public RuntimeQualificationBinding Candidate { get; }
    public ProtectedPolicyEvaluation PredecessorOverlap { get; }
    public ProtectedPolicyEvaluation CandidateOverlap { get; }
    public CandidateIndependentQualification CandidateIndependentQualification { get; }
    public IReadOnlyList<ReviewedOutcomeDifference> ReviewedDifferences { get; }
    public bool HasUnexplainedDifference { get; }
    public bool IsQualified { get; }
}

public sealed partial class ConformanceKernel
{
    public SelfConsumptionQualification QualifyCandidate(
        PredecessorTrustPayload predecessorPayload,
        ProtectedAuthorityEnvelope predecessorProof,
        RuntimeQualificationBinding candidate,
        ActivatedExtensionPolicy activePolicy,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        CandidateIndependentQualificationInput candidateIndependentInput,
        IEnumerable<ReviewedOutcomeDifference> reviewedDifferences);
}
```

`ProtectedOutcomeKind` tokens are exactly `rule`, `dispositions`, `verdict`,
and `enforcement`. `ProtectedOutcomeIdentity.ForRule` requires the rule kind;
`Global` rejects `rule` and accepts only the three global kinds. Exactly one
outcome identity exists for every evaluated rule and each global kind.

`ConformanceKernel.QualifyCandidate` accepts the public predecessor payload and
proof, then the release-owned verifier retained by `activePolicy.Policy`
authenticates contract key/version `protocol.predecessor-trust-proof` / `1`,
payload digest, external authority record and the Ed25519-signed envelope.
Only then does Conformance internally mint `PredecessorTrustBinding`; a
caller-created payload, proof implementation or self-digest grants no trust.
The authenticated record must bind the exact kernel-held current trust anchor,
predecessor release/runtime/manifest/catalog/pack, expected candidate runtime-
binding digest, one release-neutral overlap fixture-set identity with separate
predecessor/candidate evidence-set digests, predecessor overlap outcome-set
digest, signed reviewed-difference-set digest, and independent fixture-set
identity plus its independent evidence-set and trusted expected-outcome-set
digests. The predecessor overlap evaluation must equal both authenticated
overlap digests and its `RuntimeBinding.BindingDigest` must equal the signed
predecessor binding. Candidate overlap and independent evaluation runtime
bindings must both equal the supplied candidate binding and signed expected-
candidate digest; candidate overlap must equal the signed
`CandidateOverlapEvidenceSetDigest`. A
candidate cannot provide or select the predecessor result identity.
`CandidateIndependentQualificationInput` is public data, while the trusted
qualification result is internally minted only after its fixture/evaluation
identity and evidence projection agrees with that predecessor proof; its
actual outcome is compared only after those integrity gates. The predecessor overlap
evaluation must expose `PredecessorOverlapEvidenceSetDigest`; candidate overlap
must expose the distinct signed `CandidateOverlapEvidenceSetDigest`. The signed
overlap fixture key/version/digest declares their shared release-neutral input
semantics without weakening either protected evidence-set frame;
the independent evaluation must expose the exact signed project-neutral
`IndependentEvidenceSetDigest`, which differs from
`CandidateOverlapEvidenceSetDigest`; no predecessor-versus-independent
inequality is required because their release-specific manifest projections are
already distinct and independently signed. Its actual `OutcomeSetDigest` is
compared with, but is not required to equal, the signed trusted expected digest
until the semantic qualification result is determined. Both predecessor and
candidate `TrustAnchorDigest` must equal `CurrentTrustAnchorDigest`, and
candidate `BindingDigest` must equal `ExpectedCandidateBindingDigest`; this
slice permits no trust-anchor transfer. The kernel-held value is recomputed
from `protocol.protected-current-trust-anchor/1\n`, raw active Policy authority-
public-key digest, raw Policy `ExportDigest`, raw active-snapshot digest and raw
authority-set digest, in that order. It deliberately excludes protected-pack
and runtime-artifact identity so a separately signed candidate release can be
distinct while remaining under the same semantic authority. The signed
predecessor payload and both runtime bindings must equal that independently
recomputed value; a caller-declared anchor never substitutes for it. One-byte
mutations of every anchor component fail closed.
The signed `ReviewedDifferenceSetDigest` frames
`protocol.reviewed-outcome-difference-set/1\n`, ordinal row count, then each
outcome identity, raw predecessor/candidate entry digests, authority permalink
value and raw qualification-evidence digest. Public difference rows remain
assertions until their exact one-to-one set digest equals that signed value; an
arbitrary permalink cannot close drift.
Reviewed-difference rows cap at `100,000`; protected outcome rows cap at
`200,000`; each canonical set frame caps at `67,108,864` bytes. Equality
passes; first-one-over, duplicate identity, byte overflow or partial retention
fails before allocation/hash and cannot truncate a reviewed difference.
Each evaluation's outcome projection contains one ordinal entry for
every baseline/extension rule's full applicability, status, unresolved slots,
references, findings and failures, plus global disposition-set, verdict, and
enforcement entries. Every predecessor/candidate entry digest difference must
have one exact `ReviewedOutcomeDifference`; status-only comparison is
insufficient. The ordered entry projection produces `OutcomeSetDigest`, so a
finding, failure, disposition, verdict, or enforcement drift cannot hide behind
an unchanged status. Reviewed identities must equal the exact set of actually
differing outcome identities; each row's predecessor/candidate digests equal
the corresponding actual entry digests and must differ. Missing, extra, equal,
or stale rows throw `DifferentialUnexplained` before qualification. No such
integrity defect is converted into a false result. After all authenticated
identity, binding, evidence, fixture, and differential-closure gates pass, the
sole semantic false route is an independent evaluation whose actual
`OutcomeSetDigest` differs from the signed `IndependentExpectedOutcomeSetDigest`;
the input's `ExpectedOutcomeSetDigest` must itself equal that signed value or
the candidate binding is rejected before qualification. That result has
`IsQualified=false` and `HasUnexplainedDifference=true`. Exact
expected-outcome equality yields `IsQualified=true` and
`HasUnexplainedDifference=false`. No output grants publication, release
execution, or authority transfer.
Before outcome comparison, predecessor-overlap must have the exact
`ActiveExtensions` record, epoch, activation-payload, snapshot and pack binding
of the predecessor `activePolicy`; its record/epoch also equals the signed
predecessor payload's `ExpectedAuthorityRecordDigest` / `AuthorityEpoch`.
Candidate-overlap and independent evaluations must have identical candidate
record, epoch, activation-payload, snapshot and pack binding to one another.
Their active snapshot, authority set, Policy export and recomputed current
anchor equal the predecessor semantic authority, but their manifest, source
commit, pack binding and runtime artifact may differ and must produce the exact
signed `ExpectedCandidateBindingDigest`. The candidate runtime binding must be
different from the predecessor binding. Cross-record/epoch/payload mixing
inside either predecessor or candidate pair fails even when the current anchor
matches. A positive oracle uses distinct source commit, manifest, pack and
runtime artifact identities under the same snapshot/authority anchor and must
qualify; this proves the contract is inhabitable rather than contradictory.
Proof, payload, envelope, predecessor active-policy tuple, predecessor runtime/
pack/evidence/outcome binding, or independently recomputed current-anchor
corruption throws `PredecessorTrustInvalid`. Candidate binding reuse of the
predecessor, or substitution/mixing between the candidate-overlap and
independent runtime, pack, activation payload, snapshot, record, epoch, anchor,
or signed evidence/fixture identities throws `CandidateSelfCertification`. A
reviewed-difference digest mismatch, or an actual-difference closure with a
missing, extra, equal, or stale row, throws `DifferentialUnexplained`. Only the
fully authenticated independent actual-versus-expected outcome mismatch named
above returns `IsQualified=false`; it does not throw. Mutation oracles prove
the disjoint first-error order and the sole false route.

The predecessor-trusted kernel/verifier is the authority for predecessor
digests; candidate execution supplies only candidate overlap and independent-
fixture result data. [TEST-0211](test-cases.md#test-0211) proves this typed qualification contract and its
authenticated projections in a process-neutral fixture. Cross-process or
cross-version transport/report serialization remains
[SUBF-0154](README.md#subf-0154)-owned and no
runtime-transfer authority claim is made here.

## Error and validation order

The slice adds `ProtectedPolicyIntegrityException` with one closed
`ProtectedPolicyIntegrityCode`. Codes are:

1. `protocol.policy.activation-proof-invalid`;
2. `protocol.policy.active-snapshot-mismatch`;
3. `protocol.policy.extension-shadow`;
4. `protocol.policy.extension-evaluator-unregistered`;
5. `protocol.policy.extension-definition-invalid`;
6. `protocol.policy.proposed-transition-invalid`;
7. `protocol.policy.waiver-invalid`;
8. `protocol.policy.debt-invalid`;
9. `protocol.policy.evaluation-context-mismatch`;
10. `protocol.policy.predecessor-trust-invalid`;
11. `protocol.policy.differential-unexplained`;
12. `protocol.policy.candidate-self-certification`;
13. `protocol.policy.policy-pack-binding-invalid`;
14. `protocol.policy.disposition-authority-invalid`;
15. `protocol.policy.resource-limit-exceeded`.

The omitted singleton/error declarations are exactly:

```csharp
namespace MeAndAI.Protocol.Policy;

public static class ProtectedExtensionPolicy
{
    public static ExtensionPolicyPackExport Export { get; }
}

```

```csharp

namespace MeAndAI.Protocol.Conformance;

public sealed class ProtectedPolicyIntegrityException : InvalidOperationException
{
    public ProtectedPolicyIntegrityCode Code { get; }
    internal ProtectedPolicyIntegrityException(ProtectedPolicyIntegrityCode code);
}

public sealed class ProtectedPolicyIntegrityCode :
    IEquatable<ProtectedPolicyIntegrityCode>
{
    public static ProtectedPolicyIntegrityCode ActivationProofInvalid { get; }
    public static ProtectedPolicyIntegrityCode ActiveSnapshotMismatch { get; }
    public static ProtectedPolicyIntegrityCode ExtensionShadow { get; }
    public static ProtectedPolicyIntegrityCode ExtensionEvaluatorUnregistered { get; }
    public static ProtectedPolicyIntegrityCode ExtensionDefinitionInvalid { get; }
    public static ProtectedPolicyIntegrityCode ProposedTransitionInvalid { get; }
    public static ProtectedPolicyIntegrityCode WaiverInvalid { get; }
    public static ProtectedPolicyIntegrityCode DebtInvalid { get; }
    public static ProtectedPolicyIntegrityCode EvaluationContextMismatch { get; }
    public static ProtectedPolicyIntegrityCode PredecessorTrustInvalid { get; }
    public static ProtectedPolicyIntegrityCode DifferentialUnexplained { get; }
    public static ProtectedPolicyIntegrityCode CandidateSelfCertification { get; }
    public static ProtectedPolicyIntegrityCode PolicyPackBindingInvalid { get; }
    public static ProtectedPolicyIntegrityCode DispositionAuthorityInvalid { get; }
    public static ProtectedPolicyIntegrityCode ResourceLimitExceeded { get; }
    public string Value { get; }
    public static ProtectedPolicyIntegrityCode Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ProtectedPolicyIntegrityCode? result);
    public bool Equals(ProtectedPolicyIntegrityCode? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}
```

The code constructor is private; its fifteen singleton values are exactly the
ordinal token list above. `Parse`/`TryParse`, equality, hash and `ToString`
follow the closed ordinal predecessor-token pattern; unknown/case-drifted text
is rejected. The exception's internal constructor rejects null and sets the
base message to `Code.Value`. `ProtectedExtensionPolicy` has no public
constructor, method, field or setter and exposes exactly its one static Export.
The final successor public totals are exactly Domain `40`,
Conformance.Abstractions `112`, Conformance `35`, and Policy `2` (non-Domain
aggregate `149`). The surface-stage oracle runs before the Policy singleton and
kernel methods exist, so it requires Domain `40`, Conformance.Abstractions
`112`, Conformance `35`, Policy `1`, non-Domain `148`, and the exact staged
signature inventory. Authority then adds only `ProtectedExtensionPolicy` and
the implemented `ActivateExtensions`; debt adds only the implemented
`EvaluateProtected`; self-consumption adds only the implemented
`QualifyCandidate`. The convergence oracle enumerates every final exported full
type name and declared public constructor/property/method signature from this
design, sorts by ordinal canonical signature, and requires exact equality;
unexpected exports or members fail even when totals remain unchanged.

Argument null/grammar/range errors occur at the public factory boundary.
Domain/Conformance.Abstractions factories cannot reference Conformance errors:
null uses the named `ArgumentNullException`; scalar/count/checked-overflow and
first-one-over use `ArgumentOutOfRangeException` for the owning parameter;
duplicates, aggregate-byte or cross-field inconsistency use `ArgumentException`
for the owning enumerable/input parameter, all before retention. Only
kernel-derived evidence-set, reviewed/outcome-set, protected-pack or semantic
validation overflow throws `ProtectedPolicyIntegrityException` with
`ResourceLimitExceeded`. Exact equality/first-one-over oracles cover both
layers. Kernel
validation order is trusted pack binding, proof/context identity, active
snapshot/digest, baseline shadow, registration/definition, proposed-transition
isolation, evaluation, disposition authority/time, waiver row integrity,
waiver eligibility/expiry, debt row integrity, debt exactness, enforcement,
predecessor trust, candidate self-certification, differential closure, and the
non-throwing independent expected-outcome comparison. After the signed disposition authority
is valid, a recomputed waiver-snapshot digest unequal to the payload's
`WaiverSnapshotDigest`, or any waiver row whose `TrustedBaseAuthorityDigest`
differs from the payload's value, throws `WaiverInvalid`; the equivalent
debt-snapshot or debt-row defect throws `DebtInvalid`. Eligibility, expiry, or
finding/evidence mismatch in a structurally valid row is not an integrity
exception: it remains the exact `ActiveViolation` result in the matrix. A
payload manifest, trusted-base, authority-set, evidence-set, record, epoch, or
envelope mismatch still fails earlier as `DispositionAuthorityInvalid`.
First-error mutation oracles cover each disjoint branch; later defects never
mask an earlier category.

## Equality, ordering, and resource bounds

- Extension declarations, registrations, changes, evaluations, and findings
  are ordinal by stable identity; input order cannot affect outputs.
- Every cross-runtime digest uses strict UTF-8 without BOM, an ASCII separator
  including one terminal LF, big-endian unsigned 32-bit byte lengths/counts,
  big-endian unsigned 32-bit revisions, raw 32-byte digests, and one-byte
  booleans (`00`/`01`). Every signed 64-bit length, epoch, and UTC tick is
  big-endian two's-complement; each valid domain remains nonnegative or positive
  exactly where specified. Every bounded nonnegative or positive 32-bit
  semantic scalar, including optional repository/provider `Line` and
  `ExtensionParameterDeclaration.MaximumUtf8Bytes`, is big-endian unsigned
  32-bit after bounds validation. Strings are length-prefixed; null is forbidden unless a
  field is explicitly optional; lists are copied, validated, and ordinally
  sorted before framing. No delimiter, JSON, platform newline, culture, enum
  ordinal, assembly MVID, or hash-text spelling enters a frame.
- `ExtensionRuleDeclaration.DefinitionDigest` frames exactly
  `protocol.extension-declaration/1\n`, extension ID, revision, evaluator kind,
  evaluator version, parameter count and each key/value, subject-role count/tokens, surface count
  and `SurfaceSet.Values` tokens, snapshot-kind count/tokens, then operation
  count/tokens. It excludes `DefinitionDigest` itself. The declaration carries
  no slots, selectors, findings, failure codes, severity, remediation, or waiver
  flag; those are solely the immutable evaluator-kind catalog's authority.
- `ExtensionCatalogSnapshot.SnapshotDigest` frames exactly
  `protocol.extension-snapshot/1\n`, repository namespace, raw policy blob
  digest, extension count, then each extension ID, revision, and raw definition
  digest. Factories recompute both identities and reject any mismatch. The
  single-definition vector uses `ext:repo:required-agents`, revision `1`, the
  required-path kind/version `1`, `kind=file`, `path=AGENTS.md`, subject `consumer`, surface
  `repository`, snapshot `exact-commit`, and operation `conformance`; it is
  exactly `231` bytes, SHA-256
  `1E9E438CC697900F6CFF8448BEB15F091FD91E6BF9D9EC31560BCBBC15A2C802`,
  Base64 `cHJvdG9jb2wuZXh0ZW5zaW9uLWRlY2xhcmF0aW9uLzEKAAAAGGV4dDpyZXBvOnJlcXVpcmVkLWFnZW50cwAAAAEAAAArcHJvdG9jb2wuZXh0ZW5zaW9uLnJlcG9zaXRvcnktcGF0aC1yZXF1aXJlZAAAAAExAAAAAgAAAARraW5kAAAABGZpbGUAAAAEcGF0aAAAAAlBR0VOVFMubWQAAAABAAAACGNvbnN1bWVyAAAAAQAAAApyZXBvc2l0b3J5AAAAAQAAAAxleGFjdC1jb21taXQAAAABAAAAC2NvbmZvcm1hbmNl`.
  The empty snapshot vector uses namespace `repo`, raw policy digest byte `11`
  repeated 32 times, and zero declarations; it is exactly `74` bytes, SHA-256
  `C1E573C918A7FE198E6168EA0773D0814F83800EC75D2BA2FDB31071D8132E40`,
  Base64 `cHJvdG9jb2wuZXh0ZW5zaW9uLXNuYXBzaG90LzEKAAAABHJlcG8REREREREREREREREREREREREREREREREREREREREREQAAAAA=`.
  Every field has one one-byte mutation oracle; any later byte change redraws
  the framing packet. This typed frame is not final report serialization.
- `ProposedExtensionTransition` requires both complete active and proposed
  snapshots. Its active snapshot fields and digest must exactly equal
  `activePolicy.Snapshot`; the proposed snapshot keeps the same repository
  namespace, while its `PolicyBlobDigest` may differ and is bound by its own
  `SnapshotDigest` and target commit. The factory recomputes a nonempty ordinal
  add/remove/revise set from their declarations and requires exact equality
  with `Changes`. Added has no prior declaration; Removed has no proposed
  declaration; Revised requires checked exact `proposed.Revision =
  active.Revision + 1`. Equal, decrement, skipped increment and unsigned
  overflow are invalid. A digest-only proposed snapshot, active-snapshot mismatch,
  namespace drift, empty or caller-supplied incomplete diff is invalid before evaluation. The proposed snapshot and target are reported
  separately and cannot affect the active evaluation.
- `BaselineWaiverPolicySnapshot.SnapshotDigest` uses the ASCII separator
  `protocol.baseline-waiver-policy/1\n`, raw manifest digest, unsigned 32-bit
  rule count, then ordinal rule ID, revision, and one-byte waiver flag. Exact
  equality with the kernel's protected baseline is required before disposition
  evaluation; omission cannot silently make a rule waivable or non-waivable.
- `ExtensionPolicyPackExport.ExportDigest` uses
  `protocol.extension-policy-pack/1\n`, export key/version, authority issuer key
  ID, exact `ed25519` algorithm token, raw public-key digest, the four verifier
  component identities, evaluator-kind count, and each kind in this
  exact order: key/version/component, parameter count with key/grammar/max bytes,
  applicability slots, evaluation slots, finding count with code/severity/
  remediation/primary-reference-kind list/related-reference-kind list, failure-
  code list, and waiver flag. A component identity frames ComponentKey,
  ComponentVersion, AssemblyName, then TypeName in that exact order. The
  internal factory recomputes it and callers cannot build a registration/export.
  The internal raw public key must hash to the advertised digest; issuer,
  algorithm and each public-key byte have independent mutation oracles.
- `ProtectedPolicyPackBinding.BindingDigest` uses
  `protocol.protected-policy-pack-binding/1\n`, raw manifest, export and baseline-
  waiver snapshot digests, then ordinal artifact rows of key, file name,
  big-endian signed 64-bit positive length, raw file digest, component-key count
  and component keys.
  `StableFindingKey`, waiver/debt snapshots, disposition authority, predecessor
  trust, and qualification fixture identities each have distinct version-1
  separators and frame every public identity member in displayed property
  order as follows:
  - `protocol.waiver-declaration/1\n`: protected finding identity subframe
    (`00` baseline / `01` extension, length-prefixed ID, unsigned revision,
    finding code, raw location/evidence/expected/stable-key digests),
    target selector, scope, rationale, owner, decision-authority `.Value`, raw
    trusted-base digest, created UTC ticks, expiry UTC ticks, raw waiver-evidence
    digest; `DeclarationDigest` is excluded and recomputed;
  - `protocol.historical-debt-entry/1\n`: protected finding, protocol version,
    owner, authority `.Value`, review condition, raw stable-evidence and
    recurrence-record digests, optional closed-UTC tag/ticks, optional-expiry
    tag/ticks, raw trusted-base digest; `EntryDigest` is excluded;
  - waiver and debt snapshot separators, unsigned count, then ordinal raw row
    digests; empty snapshots are valid;
  - `protocol.extension-activation-payload/1\n`: raw manifest, repository
    namespace, raw policy/authority-set/expected-authority-record/previous-
    record/closure/snapshot digests, activated target commit and signed epoch;
    `PayloadDigest` is excluded and recomputed. A verified activation record is
    exactly the signed envelope's `AuthorityRecordDigest`, never a second hash;
  - `protocol.proposed-extension-transition/1\n`: raw active/proposed snapshot
    digests, target commit, raw rationale digest, unsigned change count, then
    ordinal extension ID, transition-kind token and optional previous/proposed
    raw definition digests. `TransitionDigest` is excluded and recomputed;
  - `protocol.protected-disposition-authority-payload/1\n`: raw manifest,
    trusted-base, authority-set, waiver, debt, evidence-set and expected-
    authority-record digests, signed authority epoch and signed UTC ticks;
    `PayloadDigest` is excluded and recomputed;
  - `protocol.protected-disposition-authority-binding/1\n`: raw payload,
    verified-envelope and authenticated-authority-record digests; `BindingDigest`
    is excluded and recomputed only after signature verification;
  - `protocol.runtime-qualification-binding/1\n`: protocol version, source
    commit, raw manifest/catalog/policy-pack-binding/runtime/trust-anchor
    digests; binding digest is excluded;
  - `protocol.predecessor-trust-payload/1\n`: raw predecessor binding/current-
    anchor/expected-authority-record, signed authority epoch, overlap fixture
    key/version and raw fixture/predecessor-evidence/candidate-evidence digests,
    raw predecessor-outcome/expected-candidate-binding/reviewed-difference-set
    digests, independent fixture key/version, raw fixture/independent-evidence/
    trusted-expected-outcome digests; `PayloadDigest`
    is excluded;
  - `protocol.predecessor-trust-binding/1\n`: raw payload, verified-envelope and
    authenticated-authority-record digests; `BindingDigest` is excluded and is
    recomputed only after signature verification; and
  - `protocol.qualification-fixture-input/1\n`: fixture key/version, raw
    fixture digest, raw trusted expected-outcome-set digest, raw evaluation
    evidence-set digest and raw actual outcome-set digest; input digest is
    excluded. Times are UTC `DateTimeOffset.Ticks`; optional values use tag
    `00` absent or `01` followed by value. All factories recompute identities.
  - Reviewed outcome identity is the same length-prefixed canonical row key as
    OutcomeSet: `global:<dispositions|verdict|enforcement>` or
    `rule:<baseline|extension>:<id>:<revision>`. Revision is invariant ASCII
    unsigned base-10 with no sign, whitespace, or leading zero: for example
    `rule:baseline:protocol.rule.id:1` and `rule:extension:ext:repo:test:2`.
    One shared comparator is used by both ReviewedDifferenceSet and OutcomeSet:
    all rule rows first, ordinal by their complete row key, followed by exactly
    `global:dispositions`, `global:verdict`, `global:enforcement`. This is not
    whole-key lexical order. Globals forbid a Rule and duplicate identities fail
    before hashing.
  - Each `protocol.protected-outcome-entry/1\n` row begins with outcome-kind
    token. A rule row then frames the baseline/extension rule union, revision,
    applicability-kind and status tokens; applicability is `unresolved` iff
    its flag is true, else `not-applicable` iff status is NotApplicable, else
    `applicable`; contradictory flag/status combinations fail integrity. Then
    follow ordinal raw applicability-reference
    digests; ordinal unresolved slot keys; ordinal findings with stable-key,
    severity, remediation, primary and related reference digests; and ordinal
    failures with code plus primary/related reference digests. The dispositions
    row frames each stable key, disposition token and optional waiver/debt row
    digest; verdict and enforcement rows frame only their exact tokens.
    `OutcomeSetDigest` frames `protocol.protected-outcome-set/1\n`, unsigned row
    count, then rows ordinal by `rule:<baseline|extension>:<id>:<revision>`,
    `global:dispositions`, `global:verdict`, `global:enforcement`, each followed
    by its raw entry digest. No display text, exception, object identity, input
    order, or elapsed time enters either outcome frame.

  Golden vectors use literal raw digest-byte repetitions and no omitted fields:

  | Frame fixture | Bytes | SHA-256 | Base64 |
  | --- | ---: | --- | --- |
  | Pack binding, raw manifest/export/waiver `11`/`22`/`33`, four exact artifact rows length `1..4`, digests `44..77`, representative component keys | `716` | `13822FD15F4931A6592CF0EC9FBA2D68CB2D8D59D90D661B29961CA98546E534` | `cHJvdG9jb2wucHJvdGVjdGVkLXBvbGljeS1wYWNrLWJpbmRpbmcvMQoRERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMAAAAEAAAAGHByb3RvY29sLmFydGlmYWN0LmRvbWFpbgAAABtNZUFuZEFJLlByb3RvY29sLkRvbWFpbi5kbGwAAAAAAAAAAUREREREREREREREREREREREREREREREREREREREREREAAAAAAAAACpwcm90b2NvbC5hcnRpZmFjdC5jb25mb3JtYW5jZS1hYnN0cmFjdGlvbnMAAAAtTWVBbmRBSS5Qcm90b2NvbC5Db25mb3JtYW5jZS5BYnN0cmFjdGlvbnMuZGxsAAAAAAAAAAJVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVQAAAAEAAAAkcHJvdG9jb2wuY29tcG9uZW50LnRlc3QuYWJzdHJhY3Rpb25zAAAAJXByb3RvY29sLmFydGlmYWN0LmNvbmZvcm1hbmNlLXJ1bnRpbWUAAAAgTWVBbmRBSS5Qcm90b2NvbC5Db25mb3JtYW5jZS5kbGwAAAAAAAAAA2ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmAAAAAQAAAB9wcm90b2NvbC5jb21wb25lbnQudGVzdC5ydW50aW1lAAAAGHByb3RvY29sLmFydGlmYWN0LnBvbGljeQAAABtNZUFuZEFJLlByb3RvY29sLlBvbGljeS5kbGwAAAAAAAAABHd3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3AAAAAQAAAB5wcm90b2NvbC5jb21wb25lbnQudGVzdC5wb2xpY3k=` |
  | Stable baseline `RULE-0001`/rev1/`protocol.test.finding`, location `11`, evidence `22`, expected `33` | `169` | `A298841EC8CCFEB02C4192F8684B2432F99F2E9E69A8DC3000EAA8E5505E3791` | `cHJvdG9jb2wuc3RhYmxlLWZpbmRpbmcta2V5LzEKAAAAAAlSVUxFLTAwMDEAAAABAAAAFXByb3RvY29sLnRlc3QuZmluZGluZxERERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMw==` |
  | Empty baseline-waiver policy, manifest `11` | `70` | `FD3E642248F405BB948395B1C543275CD554810A2A479F7B65F216E2C881834A` | `cHJvdG9jb2wuYmFzZWxpbmUtd2FpdmVyLXBvbGljeS8xChERERERERERERERERERERERERERERERERERERERERERAAAAAA==` |
  | Empty waiver snapshot | `31` | `B76E40F37E33A0392341301BB0D0C56FE3B0E2C911B48CD6427B5BF79C8FD02A` | `cHJvdG9jb2wud2FpdmVyLXNuYXBzaG90LzEKAAAAAA==` |
  | One-row waiver snapshot, raw declaration digest `11` | `63` | `DDCBCE4C150065FD7F5E905D787E765159145904C7B7D8F780C85DFE6F23CBE6` | `cHJvdG9jb2wud2FpdmVyLXNuYXBzaG90LzEKAAAAARERERERERERERERERERERERERERERERERERERERERER` |
  | Waiver row, baseline stable fixture above, `evidence:22..`, finding/test/owner, exact commit permalink, base `44`, ticks `0..1`, evidence `55` | `467` | `D8A0F34B6820A19FF3584C09EFB134472542EEDDF4F575BBFE0312F0F04E7BE1` | `cHJvdG9jb2wud2FpdmVyLWRlY2xhcmF0aW9uLzEKAAAAAAlSVUxFLTAwMDEAAAABAAAAFXByb3RvY29sLnRlc3QuZmluZGluZxERERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzM6KYhB7IzP6wLEGS+GhLJDL5ny6eaajcMADqqOVQXjeRAAAASWV2aWRlbmNlOjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIAAAAHZmluZGluZwAAAAR0ZXN0AAAABW93bmVyAAAATWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvL2NvbW1pdC8wMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwREREREREREREREREREREREREREREREREREREREREREQAAAAAAAAAAAAAAAAAAAABVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=` |
  | Empty debt snapshot | `40` | `20B8BFD02EBD0621C0E533851D943D8C98F552ACC014ECF6BE663123E3283A46` | `cHJvdG9jb2wuaGlzdG9yaWNhbC1kZWJ0LXNuYXBzaG90LzEKAAAAAA==` |
  | One-row debt snapshot, raw entry digest `22` | `72` | `27C490C65567AB92B16F591CAD2D100671B65A1C97E68978E5448CF2BF93D20D` | `cHJvdG9jb2wuaGlzdG9yaWNhbC1kZWJ0LXNuYXBzaG90LzEKAAAAASIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIi` |
  | Debt row, same stable fixture, version1/owner/permalink/review, stable `22`, recurrence `66`, closed absent, expiry tick1, base `44` | `415` | `08616F2CA31F056D8421C73B56688C2D415E3551083C5D808A2BB58EB26BBF5D` | `cHJvdG9jb2wuaGlzdG9yaWNhbC1kZWJ0LWVudHJ5LzEKAAAAAAlSVUxFLTAwMDEAAAABAAAAFXByb3RvY29sLnRlc3QuZmluZGluZxERERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzM6KYhB7IzP6wLEGS+GhLJDL5ny6eaajcMADqqOVQXjeRAAAAATEAAAAFb3duZXIAAABNaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8vY29tbWl0LzAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAAAAAGcmV2aWV3IiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiJmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZgABAAAAAAAAAAFERERERERERERERERERERERERERERERERERERERERERA==` |
  | Activation payload manifest `11`, namespace `repo`, remaining digests `22`..`77`, forty-zero target, epoch1 | `324` | `6C0996CE7AD2D0B6193ED30186D3A5A8D2CFCB4E914673EA6C326429C8BD9FF3` | `cHJvdG9jb2wuZXh0ZW5zaW9uLWFjdGl2YXRpb24tcGF5bG9hZC8xChERERERERERERERERERERERERERERERERERERERERERAAAABHJlcG8iIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIjMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzRERERERERERERERERERERERERERERERERERERERERERVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVWZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmd3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3cAAAAoMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMAAAAAAAAAAB` |
  | Disposition payload manifest/trusted-base `11`/`11`, remaining digests `33`..`77`, epoch1, UTC ticks zero | `291` | `CABD6EC11544BECFCB99EBD980B6725414847C31C1E019F2F446C7909753C7AB` | `cHJvdG9jb2wucHJvdGVjdGVkLWRpc3Bvc2l0aW9uLWF1dGhvcml0eS1wYXlsb2FkLzEKERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERETMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzRERERERERERERERERERERERERERERERERERERERERERVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVWZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmd3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3cAAAAAAAAAAQAAAAAAAAAA` |
  | Disposition binding payload/envelope/record `11`/`22`/`33` | `147` | `4961D0B9753E23AF2744C4B387F10B4D2508235E81776A1FEA4001E68B6EEC80` | `cHJvdG9jb2wucHJvdGVjdGVkLWRpc3Bvc2l0aW9uLWF1dGhvcml0eS1iaW5kaW5nLzEKEREREREREREREREREREREREREREREREREREREREREREiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIjMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz` |
  | Runtime version1/source forty zeroes/manifest/catalog/pack/runtime/anchor `11`..`55` | `250` | `E30958B738278EDA4107CA6989FE35ED65A3183814E83DD1EC4234C66830DEA5` | `cHJvdG9jb2wucnVudGltZS1xdWFsaWZpY2F0aW9uLWJpbmRpbmcvMQoAAAABMQAAACgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwEREREREREREREREREREREREREREREREREREREREREREiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIjMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzRERERERERERERERERERERERERERERERERERERERERERVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVQ==` |
  | Predecessor payload using prior runtime digest, anchor/record `55`/`66`, epoch1, overlap fixture `protocol.fixture.protected-policy-overlap`/1/`77`, predecessor/candidate evidence `88`/`99`, outcome/candidate/reviewed `AA`/`BB`/`CC`, independent fixture `protocol.fixture.protected-policy`/1/`DD`, evidence `EE`, expected `FF` | `521` | `35A596903394E0AD16FDC96ADDADEF9135BBE9E1F7E11BEABD9CA9E24DDBC3D9` | `cHJvdG9jb2wucHJlZGVjZXNzb3ItdHJ1c3QtcGF5bG9hZC8xCuMJWLc4J47aQQfKaYn+Ne1loxg4FOg90exCNMZoMN6lVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZgAAAAAAAAABAAAAKXByb3RvY29sLmZpeHR1cmUucHJvdGVjdGVkLXBvbGljeS1vdmVybGFwAAAAATF3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d4iIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiImZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqru7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7zMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMwAAAAhcHJvdG9jb2wuZml4dHVyZS5wcm90ZWN0ZWQtcG9saWN5AAAAATHd3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3e7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u//////////////////////////////////////////8=` |
  | Predecessor binding payload/envelope/record `11`/`22`/`33` | `133` | `9207A49B9BEC1537A1D71661E40381DEC72FB1941907090B0055BCB8162B403D` | `cHJvdG9jb2wucHJlZGVjZXNzb3ItdHJ1c3QtYmluZGluZy8xChERERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMw==` |
  | Candidate input prior key/version, fixture `88`, expected `99`, evidence `AA`, actual outcome `99` | `209` | `A12D8F6D6BBA746AD48DA1BF115F39711D323482E900AD2F8C0784DD3F169671` | `cHJvdG9jb2wucXVhbGlmaWNhdGlvbi1maXh0dXJlLWlucHV0LzEKAAAAIXByb3RvY29sLmZpeHR1cmUucHJvdGVjdGVkLXBvbGljeQAAAAExiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmaqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZk=` |
  | Added transition active/proposed `11`/`22`, target zero, rationale `33`, `ext:repo:test`, proposed `44` | `245` | `A589422AA3010E335A3730F280F19226DFB72E866D97B0ADAC99AA084D689D0C` | `cHJvdG9jb2wucHJvcG9zZWQtZXh0ZW5zaW9uLXRyYW5zaXRpb24vMQoRERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAAKDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMwAAAAEAAAANZXh0OnJlcG86dGVzdAAAAAVhZGRlZAABREREREREREREREREREREREREREREREREREREREREREQ=` |
  | Current trust anchor key/export/snapshot/authority-set `11`/`22`/`33`/`44` | `170` | `FAC1774E6142EF63408672F57A9B9FC449F134A1567459F3332F43BD7A6C4311` | `cHJvdG9jb2wucHJvdGVjdGVkLWN1cnJlbnQtdHJ1c3QtYW5jaG9yLzEKEREREREREREREREREREREREREREREREREREREREREREiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIjMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzREREREREREREREREREREREREREREREREREREREREREQ=` |
  | One reviewed difference, `global:verdict`, predecessor/candidate `11`/`22`, exact commit permalink, evidence `33` | `242` | `6313748B75224C46DEE244A02BD26AEF0548B74EC631759F8170BAECC24B230E` | `cHJvdG9jb2wucmV2aWV3ZWQtb3V0Y29tZS1kaWZmZXJlbmNlLXNldC8xCgAAAAEAAAAOZ2xvYmFsOnZlcmRpY3QRERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAATWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvL2NvbW1pdC8wMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzM=` |
  | One protected outcome, `global:verdict`, entry digest `11` | `87` | `99BEE53CEEC141FA45BAF5B1495E218FCEDC089A0CE6460828690019699184B0` | `cHJvdG9jb2wucHJvdGVjdGVkLW91dGNvbWUtc2V0LzEKAAAAAQAAAA5nbG9iYWw6dmVyZGljdBERERERERERERERERERERERERERERERERERERERERER` |
  | Mixed comparator: baseline rule `protocol.rule.id:1`, then dispositions/verdict/enforcement with digests `11`/`22`/`33`/`44` | `264` | `594FBB75E2517B89ABA750F7376DDBADFFE6888FD6C94655723F87C19F5A93D0` | `cHJvdG9jb2wucHJvdGVjdGVkLW91dGNvbWUtc2V0LzEKAAAABAAAACBydWxlOmJhc2VsaW5lOnByb3RvY29sLnJ1bGUuaWQ6MRERERERERERERERERERERERERERERERERERERERERERAAAAE2dsb2JhbDpkaXNwb3NpdGlvbnMiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIgAAAA5nbG9iYWw6dmVyZGljdDMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzAAAAEmdsb2JhbDplbmZvcmNlbWVudERERERERERERERERERERERERERERERERERERERERERE` |
- `TargetCommit`, `ActivatedTargetCommit`, and `SourceCommit` are exact forty
  lowercase hexadecimal Git object identities, consistent with the existing
  manifest source-commit grammar; they are not mislabeled SHA-256 digests.
- Factories copy every enumerable before validation and never retain mutable
  arrays, dictionaries, or caller objects not already immutable contracts.
- Maximum active extensions: `10,000`; parameters per extension: `64`;
  UTF-8 parameter key: `64` bytes (the ASCII grammar makes characters and
  bytes identical); value: `4,096` bytes; aggregate parameter key plus value
  bytes: `8,388,608`. Waivers and debt entries each cap at `100,000`.
- Repository namespace and authority issuer key ID are lowercase ASCII tokens
  capped at `96` and `128` bytes respectively; authority algorithm and contract
  key/version are closed exact constants. Waiver rationale and debt review
  condition are strict UTF-8 at most `4,096` bytes; accountable/waiver owner at
  most `256`; debt protocol version at most `64`; both overlap and independent
  fixture keys are strict UTF-8 at most `128` bytes and their versions at most
  `32`; no string admits NUL or CR. Equality succeeds and each first byte over
  is rejected before retention/framing. Repository selector
  paths retain their existing `4,096`-byte normalized-path bound.
- Each complete waiver-snapshot and debt-snapshot canonical frame is at most
  `67,108,864` bytes including row framing. Count equality is accepted only
  when the byte ceiling also passes; when algebraically dominated, the byte
  failure is the exact first failure. The first byte/count over and checked
  addition overflow fail before copying or digesting the over-limit member.
- Exact equality at each bound passes; first-one-over fails before retention.
  Kernel-derived checked overflow is `resource-limit-exceeded`; lower-layer
  public factory overflow is `ArgumentOutOfRangeException` under the split
  above. Neither path truncates.
- These semantic bounds do not broaden [DEC-0036](../../decisions/DEC-0036-prospective-instruction-graph-capacity.md):
  prospective schema-2 remains `8,192` edges, `1,048,576` bytes per parsed
  blob, and `8,388,608` aggregate parsed bytes; older target profiles remain
  immutable.

## Negative surface

No arbitrary executable plugin, reflection/type name, `object`, `dynamic`, raw
JSON/report bytes, provider DTO, file/network/Git/GitHub I/O, clock lookup,
credential, authority-store mutation, grant/CAS/journal/recovery behavior,
report serialization, host/CLI, consumer mutation, release, publication, or
authority-transfer API may enter this slice. Existing [TEST-0210](test-cases.md#test-0210)
FQNs, traits, outputs, registration graph, Policy pack, manifests, and evidence
remain immutable predecessor behavior.
The only reflection carve-out is Policy-internal `GetType()` inspection of the
four already-created retained verifier instances plus the one retained
evaluator instance, each only against the exact role, assembly, and type
constants above; no caller type name, discovery, loading, or activation is
accepted.

## Verification and acceptance

This security/authority design is bounded at `2,400` normalized lines and its
micro plan at `500`; equality passes and first-one-over requires a reviewed
appendix split or explicit redesign. These local readability brakes do not
alter the schema-2 per-blob or aggregate limits and may not be met by deleting
normative framing, trust, negative-surface, or oracle content.
The subfeature-specific increase from `1,500` to `2,400` preserves the newly
required signed-envelope, persistent-finding and authenticated-differential
contracts plus the exact production/test trust-root split with bounded repair
reserve; it is not a
general limit rise.

The exact package order, expected-red identities, mutation allowlists, line
budgets, local commands, review gates, record synchronization, commit/push and
hosted requirements are normative in the
[micro-delivery plan](subf-0144-micro-delivery-plan.md). This design becomes
`AcceptedFrozenDesign` only after fresh design, evidence, traceability,
security/authority, graph/capacity and implementation-topology reviews all
close `0/0/0`; diff/format/link checks and StructureOnly are green; the exact
design cohort is committed and pushed; and that exact head is Ubuntu/Windows
hosted green with publication verification skipped.
