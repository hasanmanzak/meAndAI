using System.Collections.ObjectModel;

#pragma warning disable CA1067 // Exact frozen API omits derived object equality overrides.

namespace MeAndAI.Operations.Domain.ExecutionAuthority;

internal static class GrantContractValidation
{
    internal static string Dot(string value, string parameterName) =>
        Check(value, parameterName, 128, static text =>
        {
            string[] parts = text.Split('.');
            return parts[0].Length > 0 && parts[0][0] is >= 'a' and <= 'z' &&
                parts[0].Skip(1).All(static value => value is >= 'a' and <= 'z' or >= '0' and <= '9') &&
                parts.Skip(1).All(static part => part.Length > 0 && part[0] is >= 'a' and <= 'z' &&
                    part.Skip(1).All(static value => value is >= 'a' and <= 'z' or >= '0' and <= '9' or '-'));
        });
    internal static string Stable(string value, string parameterName) =>
        Check(value, parameterName, 256, static text =>
            text[0] is >= 'a' and <= 'z' or >= '0' and <= '9' &&
            text.Skip(1).All(static character =>
                character is >= 'A' and <= 'Z' or >= 'a' and <= 'z' or
                    >= '0' and <= '9' or '.' or '_' or ':' or '/' or '-'));
    internal static string Display(string value, string parameterName) =>
        Check(value, parameterName, 128, static text =>
            text[0] is >= '!' and <= '~' && text[^1] is >= '!' and <= '~' &&
            text.Skip(1).SkipLast(1).All(static character =>
                character is >= ' ' and <= '~'));
    internal static string Reference(string value, string parameterName) =>
        Check(value, parameterName, 255, static text => IsCommit(text) ||
            text.StartsWith("refs/", StringComparison.Ordinal) &&
            text.Length <= 255 && !text.Contains("..", StringComparison.Ordinal) &&
            !text.Contains("//", StringComparison.Ordinal) &&
            !text.Contains("@{", StringComparison.Ordinal) &&
            !text.EndsWith('/') && !text.EndsWith('.') && !text.Contains('\\') &&
            text[5..].Split('/').All(static part => part.Length > 0 &&
                !StringComparer.Ordinal.Equals(part, ".lock") &&
                part.All(static character => character is >= 'A' and <= 'Z' or
                    >= 'a' and <= 'z' or >= '0' and <= '9' or '.' or '_' or '-' or '/')));
    internal static string Commit(string value, string parameterName) =>
        Check(value, parameterName, 40, IsCommit);
    internal static string Extension(string value, string parameterName) =>
        Check(value, parameterName, 256, static text =>
        {
            string[] parts = text.Split(':');
            return parts is ["ext", var owner, var name] && owner.Length > 0 &&
                owner[0] is >= 'a' and <= 'z' or >= '0' and <= '9' &&
                owner.Skip(1).All(static value => value is >= 'a' and <= 'z' or
                    >= '0' and <= '9' or '.' or '-') && name.Length > 0 &&
                name[0] is >= 'a' and <= 'z' && name.Skip(1).All(static value =>
                    value is >= 'a' and <= 'z' or >= '0' and <= '9' or '-');
        }, minimum: 7);
    internal static string Path(string value, string parameterName) =>
        Check(value, parameterName, 512, static text =>
            !text.StartsWith('/') && !text.EndsWith('/') && !text.Contains(':') &&
            !text.Contains('\\') && text.Split('/').All(static part =>
                part.Length is >= 1 and <= 128 && part is not "." and not ".." &&
                part.All(static value => value is >= 'A' and <= 'Z' or
                    >= 'a' and <= 'z' or >= '0' and <= '9' or '.' or '_' or '-')));
    internal static IReadOnlyList<string> Strings(
        IEnumerable<string> values, string parameterName,
        Func<string, string, string> validator)
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        List<string> result = [];
        foreach (string? value in values)
        {
            if (value is null)
                throw new ArgumentException("The collection contains null.", parameterName);
            result.Add(validator(value, parameterName));
        }
        result.Sort(StringComparer.Ordinal);
        if (result.Zip(result.Skip(1), StringComparer.Ordinal.Equals).Any(static same => same))
            throw new ArgumentException("The collection contains duplicates.", parameterName);
        return new ReadOnlyCollection<string>(result);
    }
    internal static IReadOnlyList<AuthorityRole> Roles(
        IEnumerable<AuthorityRole> values, string parameterName,
        params AuthorityRole[] floor)
    {
        IReadOnlyList<AuthorityRole> roles = AuthoritySetRules.SortRoles(values, parameterName);
        if (floor.Any(role => !roles.Contains(role)))
            throw new ArgumentException("A mandatory approval role is missing.", parameterName);
        return roles;
    }
    internal static IReadOnlyList<GrantApprovalEvidence> Approvals(
        IEnumerable<GrantApprovalEvidence> values, string parameterName) =>
        ExecutionAuthorityValidation.SortedUnique(values, parameterName,
            static (left, right) => Compare(
                [left.Approver.Value, left.Role.Value, left.EvidenceDigest.Value],
                [right.Approver.Value, right.Role.Value, right.EvidenceDigest.Value]));
    internal static void Utc(DateTimeOffset value, string parameterName)
    {
        if (value.Offset != TimeSpan.Zero)
            throw new ArgumentException("The timestamp must have UTC offset zero.", parameterName);
    }
    internal static int Hash<T>(IEnumerable<T> values) => AuthoritySetRules.Hash(values);
    private static int Compare(string[] left, string[] right)
    {
        for (int index = 0; index < left.Length; index++)
        {
            int result = StringComparer.Ordinal.Compare(left[index], right[index]);
            if (result != 0) return result;
        }
        return 0;
    }
    private static string Check(
        string value, string parameterName, int maximum,
        Func<string, bool> predicate, int minimum = 1)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);
        return value.Length >= minimum && value.Length <= maximum && predicate(value)
            ? value : throw new ArgumentException("The value is not canonical.", parameterName);
    }
    private static bool IsCommit(string value) => value.Length == 40 &&
        value.All(static character => character is >= '0' and <= '9' or >= 'a' and <= 'f');
}
public sealed class ExecutionSubject : IEquatable<ExecutionSubject>
{
    private ExecutionSubject(string kind, string identity) => (Kind, Identity) = (kind, identity);
    public string Kind { get; }
    public string Identity { get; }
    public static ExecutionSubject Create(string kind, string identity) =>
        new(GrantContractValidation.Dot(kind, nameof(kind)),
            GrantContractValidation.Stable(identity, nameof(identity)));
    public bool Equals(ExecutionSubject? other) => other is not null &&
        StringComparer.Ordinal.Equals(Kind, other.Kind) && StringComparer.Ordinal.Equals(Identity, other.Identity);
    public override bool Equals(object? obj) => Equals(obj as ExecutionSubject);
    public override int GetHashCode() => HashCode.Combine(
        StringComparer.Ordinal.GetHashCode(Kind), StringComparer.Ordinal.GetHashCode(Identity));
}
public sealed class ExecutionTarget : IEquatable<ExecutionTarget>
{
    private ExecutionTarget(string kind, string identity, string generation) =>
        (Kind, Identity, GenerationIdentity) = (kind, identity, generation);
    public string Kind { get; }
    public string Identity { get; }
    public string GenerationIdentity { get; }
    public static ExecutionTarget Create(string kind, string identity, string generationIdentity) =>
        new(GrantContractValidation.Dot(kind, nameof(kind)),
            GrantContractValidation.Stable(identity, nameof(identity)),
            GrantContractValidation.Stable(generationIdentity, nameof(generationIdentity)));
    public bool Equals(ExecutionTarget? other) => other is not null &&
        StringComparer.Ordinal.Equals(Kind, other.Kind) &&
        StringComparer.Ordinal.Equals(Identity, other.Identity) &&
        StringComparer.Ordinal.Equals(GenerationIdentity, other.GenerationIdentity);
    public override bool Equals(object? obj) => Equals(obj as ExecutionTarget);
    public override int GetHashCode() => HashCode.Combine(Kind, Identity, GenerationIdentity);
}
public sealed class LeaseFenceBinding : IEquatable<LeaseFenceBinding>
{
    private LeaseFenceBinding(GrantGeneration generation, string owner, string token) =>
        (Generation, OwnerIdentity, FencingToken) = (generation, owner, token);
    public GrantGeneration Generation { get; }
    public string OwnerIdentity { get; }
    public string FencingToken { get; }
    public static LeaseFenceBinding Create(GrantGeneration generation, string ownerIdentity, string fencingToken)
    {
        ArgumentNullException.ThrowIfNull(generation);
        return new(generation, GrantContractValidation.Stable(ownerIdentity, nameof(ownerIdentity)),
            GrantContractValidation.Stable(fencingToken, nameof(fencingToken)));
    }
    public bool Equals(LeaseFenceBinding? other) => other is not null && Generation == other.Generation &&
        StringComparer.Ordinal.Equals(OwnerIdentity, other.OwnerIdentity) &&
        StringComparer.Ordinal.Equals(FencingToken, other.FencingToken);
    public override bool Equals(object? obj) => Equals(obj as LeaseFenceBinding);
    public override int GetHashCode() => HashCode.Combine(Generation, OwnerIdentity, FencingToken);
}
public sealed class GrantApprovalEvidence : IEquatable<GrantApprovalEvidence>
{
    private GrantApprovalEvidence(AuthorityActorId approver, AuthorityRole role, AuthorityDigest digest) =>
        (Approver, Role, EvidenceDigest) = (approver, role, digest);
    public AuthorityActorId Approver { get; }
    public AuthorityRole Role { get; }
    public AuthorityDigest EvidenceDigest { get; }
    public static GrantApprovalEvidence Create(AuthorityActorId approver, AuthorityRole role, AuthorityDigest evidenceDigest)
    {
        ArgumentNullException.ThrowIfNull(approver); ArgumentNullException.ThrowIfNull(role);
        ArgumentNullException.ThrowIfNull(evidenceDigest); return new(approver, role, evidenceDigest);
    }
    public bool Equals(GrantApprovalEvidence? other) => other is not null && Approver.Equals(other.Approver) &&
        Role == other.Role && EvidenceDigest.Equals(other.EvidenceDigest);
    public override bool Equals(object? obj) => Equals(obj as GrantApprovalEvidence);
    public override int GetHashCode() => HashCode.Combine(Approver, Role, EvidenceDigest);
}
public abstract class ExecutionGrantBinding : IEquatable<ExecutionGrantBinding>
{
    internal ExecutionGrantBinding() { }
    private protected string BindingKind = null!;
    private protected AuthorityDigest BindingDigest = null!;
    private protected IReadOnlyList<AuthorityRole> BindingRoles = null!;
    public string Kind => BindingKind;
    public AuthorityDigest Digest => BindingDigest;
    public IReadOnlyList<AuthorityRole> RequiredApprovalRoles => BindingRoles;
    public bool Equals(ExecutionGrantBinding? other) => (this, other) switch
    {
        (PlanGrantBinding left, PlanGrantBinding right) => left.Equals(right),
        (ReadGrantBinding left, ReadGrantBinding right) => left.Equals(right),
        (PublicationGrantBinding left, PublicationGrantBinding right) => left.Equals(right),
        (ExtensionActivationGrantBinding left, ExtensionActivationGrantBinding right) => left.Equals(right),
        _ => false
    };
    public override bool Equals(object? obj) => Equals(obj as ExecutionGrantBinding);
    public override int GetHashCode() => this switch
    {
        PlanGrantBinding value => value.GetTypedHashCode(),
        ReadGrantBinding value => value.GetTypedHashCode(),
        PublicationGrantBinding value => value.GetTypedHashCode(),
        ExtensionActivationGrantBinding value => value.GetTypedHashCode(),
        _ => 0
    };
    private protected bool BaseEquals(ExecutionGrantBinding other) =>
        StringComparer.Ordinal.Equals(Kind, other.Kind) && Digest.Equals(other.Digest) &&
        RequiredApprovalRoles.SequenceEqual(other.RequiredApprovalRoles);
    private protected int BaseHash() => HashCode.Combine(Kind, Digest,
        GrantContractValidation.Hash(RequiredApprovalRoles));
}
public sealed class PlanGrantBinding : ExecutionGrantBinding, IEquatable<PlanGrantBinding>
{
    private PlanGrantBinding(AuthorityDigest plan, string baseRef, string headRef,
        string targetRef, IReadOnlyList<string> paths, IReadOnlyList<string> providers,
        string stage, string effect, IReadOnlyList<AuthorityRole> roles, AuthorityDigest digest)
    {
        (FinalPlanDigest, BaseReference, HeadReference, TargetReference, AllowedRepositoryPaths,
            AllowedProviderObjectIdentities, OperationStage, AllowedEffectIdentity) = (plan, baseRef, headRef, targetRef, paths, providers, stage, effect);
        BindingKind = "plan.sealed"; BindingDigest = digest; BindingRoles = roles;
    }
    public AuthorityDigest FinalPlanDigest { get; }
    public string BaseReference { get; }
    public string HeadReference { get; }
    public string TargetReference { get; }
    public string OperationStage { get; }
    public IReadOnlyList<string> AllowedRepositoryPaths { get; }
    public IReadOnlyList<string> AllowedProviderObjectIdentities { get; }
    public string AllowedEffectIdentity { get; }
    public static PlanGrantBinding Create(AuthorityDigest finalPlanDigest, string baseReference, string headReference,
        string targetReference, IEnumerable<string> allowedRepositoryPaths,
        IEnumerable<string> allowedProviderObjectIdentities, string operationStage, string allowedEffectIdentity,
        IEnumerable<AuthorityRole> requiredApprovalRoles, AuthorityDigest digest)
    {
        ArgumentNullException.ThrowIfNull(finalPlanDigest); ArgumentNullException.ThrowIfNull(digest);
        IReadOnlyList<string> paths = GrantContractValidation.Strings(allowedRepositoryPaths, nameof(allowedRepositoryPaths), GrantContractValidation.Path);
        IReadOnlyList<string> providers = GrantContractValidation.Strings(allowedProviderObjectIdentities, nameof(allowedProviderObjectIdentities), GrantContractValidation.Stable);
        if ((paths.Count == 0) == (providers.Count == 0)) throw new ArgumentException("Exactly one scope is required.", nameof(allowedRepositoryPaths));
        return new(finalPlanDigest,
            GrantContractValidation.Reference(baseReference, nameof(baseReference)),
            GrantContractValidation.Reference(headReference, nameof(headReference)),
            GrantContractValidation.Reference(targetReference, nameof(targetReference)), paths, providers,
            GrantContractValidation.Dot(operationStage, nameof(operationStage)),
            GrantContractValidation.Dot(allowedEffectIdentity, nameof(allowedEffectIdentity)),
            GrantContractValidation.Roles(requiredApprovalRoles, nameof(requiredApprovalRoles), AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer), digest);
    }
    public bool Equals(PlanGrantBinding? other) => other is not null && BaseEquals(other) && FinalPlanDigest.Equals(other.FinalPlanDigest) &&
        BaseReference == other.BaseReference && HeadReference == other.HeadReference && TargetReference == other.TargetReference && AllowedRepositoryPaths.SequenceEqual(other.AllowedRepositoryPaths) &&
        AllowedProviderObjectIdentities.SequenceEqual(other.AllowedProviderObjectIdentities) && OperationStage == other.OperationStage && AllowedEffectIdentity == other.AllowedEffectIdentity;
    internal int GetTypedHashCode() => HashCode.Combine(BaseHash(), FinalPlanDigest, BaseReference, HeadReference,
        HashCode.Combine(TargetReference, GrantContractValidation.Hash(AllowedRepositoryPaths), GrantContractValidation.Hash(AllowedProviderObjectIdentities), OperationStage, AllowedEffectIdentity));
}
public sealed class ReadGrantBinding : ExecutionGrantBinding, IEquatable<ReadGrantBinding>
{
    private ReadGrantBinding(AuthorityDigest plan, string baseRef, string headRef,
        IReadOnlyList<string> paths, IReadOnlyList<string> providers, string effect,
        IReadOnlyList<AuthorityRole> roles, AuthorityDigest digest)
    {
        (EvidencePlanDigest, BaseReference, HeadReference, AllowedRepositoryPaths,
            AllowedProviderObjectIdentities, AllowedEffectIdentity) = (plan, baseRef, headRef, paths, providers, effect);
        BindingKind = "evidence.read"; BindingDigest = digest; BindingRoles = roles;
    }
    public AuthorityDigest EvidencePlanDigest { get; }
    public string BaseReference { get; }
    public string HeadReference { get; }
    public IReadOnlyList<string> AllowedRepositoryPaths { get; }
    public IReadOnlyList<string> AllowedProviderObjectIdentities { get; }
    public string AllowedEffectIdentity { get; }
    public static ReadGrantBinding Create(AuthorityDigest evidencePlanDigest, string baseReference, string headReference,
        IEnumerable<string> allowedRepositoryPaths, IEnumerable<string> allowedProviderObjectIdentities,
        string allowedEffectIdentity, IEnumerable<AuthorityRole> requiredApprovalRoles, AuthorityDigest digest)
    {
        ArgumentNullException.ThrowIfNull(evidencePlanDigest); ArgumentNullException.ThrowIfNull(digest);
        IReadOnlyList<string> paths = GrantContractValidation.Strings(allowedRepositoryPaths, nameof(allowedRepositoryPaths), GrantContractValidation.Path);
        IReadOnlyList<string> providers = GrantContractValidation.Strings(allowedProviderObjectIdentities, nameof(allowedProviderObjectIdentities), GrantContractValidation.Stable);
        if ((paths.Count == 0) == (providers.Count == 0)) throw new ArgumentException("Exactly one scope is required.", nameof(allowedRepositoryPaths));
        return new(evidencePlanDigest,
            GrantContractValidation.Reference(baseReference, nameof(baseReference)),
            GrantContractValidation.Reference(headReference, nameof(headReference)), paths, providers,
            GrantContractValidation.Dot(allowedEffectIdentity, nameof(allowedEffectIdentity)),
            GrantContractValidation.Roles(requiredApprovalRoles, nameof(requiredApprovalRoles), AuthorityRole.EnvelopeReviewer), digest);
    }
    public bool Equals(ReadGrantBinding? other) => other is not null && BaseEquals(other) && EvidencePlanDigest.Equals(other.EvidencePlanDigest) &&
        BaseReference == other.BaseReference && HeadReference == other.HeadReference && AllowedRepositoryPaths.SequenceEqual(other.AllowedRepositoryPaths) &&
        AllowedProviderObjectIdentities.SequenceEqual(other.AllowedProviderObjectIdentities) && AllowedEffectIdentity == other.AllowedEffectIdentity;
    internal int GetTypedHashCode() => HashCode.Combine(BaseHash(), EvidencePlanDigest, BaseReference, HeadReference,
        GrantContractValidation.Hash(AllowedRepositoryPaths), GrantContractValidation.Hash(AllowedProviderObjectIdentities), AllowedEffectIdentity);
}
public sealed class PublicationGrantBinding : ExecutionGrantBinding, IEquatable<PublicationGrantBinding>
{
    private PublicationGrantBinding(AuthorityDigest report, ExecutionTarget target,
        string gate, string name, string effect, IdempotencyKey key,
        IReadOnlyList<AuthorityRole> roles, AuthorityDigest digest)
    {
        (SealedReportDigest, ProviderTarget, GateSnapshotIdentity, ResultName,
            AllowedEffectIdentity, IdempotencyKey) = (report, target, gate, name, effect, key);
        BindingKind = "report.sealed"; BindingDigest = digest; BindingRoles = roles;
    }
    public AuthorityDigest SealedReportDigest { get; }
    public ExecutionTarget ProviderTarget { get; }
    public string GateSnapshotIdentity { get; }
    public string ResultName { get; }
    public string AllowedEffectIdentity { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public static PublicationGrantBinding Create(AuthorityDigest sealedReportDigest, ExecutionTarget providerTarget,
        string gateSnapshotIdentity, string resultName, string allowedEffectIdentity, IdempotencyKey idempotencyKey,
        IEnumerable<AuthorityRole> requiredApprovalRoles, AuthorityDigest digest)
    {
        ArgumentNullException.ThrowIfNull(sealedReportDigest); ArgumentNullException.ThrowIfNull(providerTarget);
        ArgumentNullException.ThrowIfNull(idempotencyKey); ArgumentNullException.ThrowIfNull(digest);
        return new(sealedReportDigest, providerTarget,
            GrantContractValidation.Display(gateSnapshotIdentity, nameof(gateSnapshotIdentity)),
            GrantContractValidation.Display(resultName, nameof(resultName)),
            GrantContractValidation.Dot(allowedEffectIdentity, nameof(allowedEffectIdentity)), idempotencyKey,
            GrantContractValidation.Roles(requiredApprovalRoles, nameof(requiredApprovalRoles), AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer), digest);
    }
    public bool Equals(PublicationGrantBinding? other) => other is not null && BaseEquals(other) && SealedReportDigest.Equals(other.SealedReportDigest) &&
        ProviderTarget.Equals(other.ProviderTarget) && GateSnapshotIdentity == other.GateSnapshotIdentity && ResultName == other.ResultName && AllowedEffectIdentity == other.AllowedEffectIdentity && IdempotencyKey.Equals(other.IdempotencyKey);
    internal int GetTypedHashCode() => HashCode.Combine(BaseHash(), SealedReportDigest, ProviderTarget, GateSnapshotIdentity, ResultName, AllowedEffectIdentity, IdempotencyKey);
}
public sealed class ExtensionActivationGrantBinding : ExecutionGrantBinding, IEquatable<ExtensionActivationGrantBinding>
{
    private ExtensionActivationGrantBinding(AuthorityDigest current, AuthorityDigest proposed,
        string policy, AuthorityDigest policyDigest, string commit, AuthorityDigest transition,
        AuthorityDigest closure, ExecutionTarget target, AuthorityRevision version, string effect,
        IReadOnlyList<AuthorityRole> roles, AuthorityDigest digest)
    {
        (CurrentActivationRecordDigest, ProposedExtensionSnapshotDigest, ActivePolicyIdentity, ActivePolicyDigest, ActivatingTargetCommit,
            TransitionEvidenceDigest, ClosureReportDigest, Target, ExpectedCasVersion, AllowedEffectIdentity) = (current, proposed, policy, policyDigest, commit, transition, closure, target, version, effect);
        BindingKind = "extension.transition"; BindingDigest = digest; BindingRoles = roles;
    }
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
    public static ExtensionActivationGrantBinding Create(AuthorityDigest currentActivationRecordDigest,
        AuthorityDigest proposedExtensionSnapshotDigest, string activePolicyIdentity, AuthorityDigest activePolicyDigest,
        string activatingTargetCommit, AuthorityDigest transitionEvidenceDigest, AuthorityDigest closureReportDigest,
        ExecutionTarget target, AuthorityRevision expectedCasVersion, string allowedEffectIdentity,
        IEnumerable<AuthorityRole> requiredApprovalRoles, AuthorityDigest digest)
    {
        ArgumentNullException.ThrowIfNull(currentActivationRecordDigest); ArgumentNullException.ThrowIfNull(proposedExtensionSnapshotDigest);
        ArgumentNullException.ThrowIfNull(activePolicyDigest); ArgumentNullException.ThrowIfNull(transitionEvidenceDigest);
        ArgumentNullException.ThrowIfNull(closureReportDigest); ArgumentNullException.ThrowIfNull(target);
        ArgumentNullException.ThrowIfNull(expectedCasVersion); ArgumentNullException.ThrowIfNull(digest);
        return new(currentActivationRecordDigest, proposedExtensionSnapshotDigest,
            GrantContractValidation.Extension(activePolicyIdentity, nameof(activePolicyIdentity)), activePolicyDigest,
            GrantContractValidation.Commit(activatingTargetCommit, nameof(activatingTargetCommit)), transitionEvidenceDigest,
            closureReportDigest, target, expectedCasVersion,
            GrantContractValidation.Dot(allowedEffectIdentity, nameof(allowedEffectIdentity)),
            GrantContractValidation.Roles(requiredApprovalRoles, nameof(requiredApprovalRoles), AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer), digest);
    }
    public bool Equals(ExtensionActivationGrantBinding? other) => other is not null && BaseEquals(other) && CurrentActivationRecordDigest.Equals(other.CurrentActivationRecordDigest) &&
        ProposedExtensionSnapshotDigest.Equals(other.ProposedExtensionSnapshotDigest) && ActivePolicyIdentity == other.ActivePolicyIdentity && ActivePolicyDigest.Equals(other.ActivePolicyDigest) &&
        ActivatingTargetCommit == other.ActivatingTargetCommit && TransitionEvidenceDigest.Equals(other.TransitionEvidenceDigest) && ClosureReportDigest.Equals(other.ClosureReportDigest) &&
        Target.Equals(other.Target) && ExpectedCasVersion == other.ExpectedCasVersion && AllowedEffectIdentity == other.AllowedEffectIdentity;
    internal int GetTypedHashCode() => HashCode.Combine(BaseHash(), CurrentActivationRecordDigest, ProposedExtensionSnapshotDigest, ActivePolicyIdentity,
        HashCode.Combine(ActivePolicyDigest, ActivatingTargetCommit, TransitionEvidenceDigest, ClosureReportDigest, Target, ExpectedCasVersion, AllowedEffectIdentity));
}
public sealed class ExecutionGrant : IEquatable<ExecutionGrant>
{
    private ExecutionGrant(AuthorityGrantId id, AuthoritySetBinding set,
        ExecutionCapability capability, ExecutionSubject subject, ExecutionTarget target,
        AuthorityOperationId operation, GrantGeneration generation, IdempotencyKey key,
        AuthorityActorId issuer, AuthorityActorId executor,
        IReadOnlyList<GrantApprovalEvidence> approvals, ExecutionGrantBinding binding,
        JournalStoreReference store, LeaseFenceBinding lease, DateTimeOffset issued,
        DateTimeOffset notBefore, DateTimeOffset expires, AuthorityDigest digest) =>
        (Id, AuthoritySet, Capability, Subject, Target, Operation, Generation, IdempotencyKey, Issuer, Executor,
            Approvals, Binding, JournalStore, LeaseFence, IssuedAtUtc, NotBeforeUtc, ExpiresAtUtc, Digest) =
        (id, set, capability, subject, target, operation, generation, key, issuer, executor, approvals, binding, store, lease, issued, notBefore, expires, digest);
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
    public static ExecutionGrant Create(AuthorityGrantId id, AuthoritySetBinding authoritySet,
        ExecutionCapability capability, ExecutionSubject subject, ExecutionTarget target, AuthorityOperationId operation,
        GrantGeneration generation, IdempotencyKey idempotencyKey, AuthorityActorId issuer, AuthorityActorId executor,
        IEnumerable<GrantApprovalEvidence> approvals, ExecutionGrantBinding binding, JournalStoreReference journalStore,
        LeaseFenceBinding leaseFence, DateTimeOffset issuedAtUtc, DateTimeOffset notBeforeUtc,
        DateTimeOffset expiresAtUtc, AuthorityDigest digest)
    {
        ArgumentNullException.ThrowIfNull(id); ArgumentNullException.ThrowIfNull(authoritySet); ArgumentNullException.ThrowIfNull(capability);
        ArgumentNullException.ThrowIfNull(subject); ArgumentNullException.ThrowIfNull(target); ArgumentNullException.ThrowIfNull(operation);
        ArgumentNullException.ThrowIfNull(generation); ArgumentNullException.ThrowIfNull(idempotencyKey); ArgumentNullException.ThrowIfNull(issuer);
        ArgumentNullException.ThrowIfNull(executor); ArgumentNullException.ThrowIfNull(binding); ArgumentNullException.ThrowIfNull(journalStore);
        ArgumentNullException.ThrowIfNull(leaseFence); ArgumentNullException.ThrowIfNull(digest);
        GrantContractValidation.Utc(issuedAtUtc, nameof(issuedAtUtc)); GrantContractValidation.Utc(notBeforeUtc, nameof(notBeforeUtc));
        GrantContractValidation.Utc(expiresAtUtc, nameof(expiresAtUtc));
        if (issuedAtUtc > notBeforeUtc) throw new ArgumentException("Not-before precedes issue time.", nameof(notBeforeUtc));
        if (notBeforeUtc >= expiresAtUtc) throw new ArgumentException("Expiry must follow not-before.", nameof(expiresAtUtc));
        return new(id, authoritySet, capability, subject, target, operation,
            generation, idempotencyKey, issuer, executor,
            GrantContractValidation.Approvals(approvals, nameof(approvals)),
            binding, journalStore, leaseFence, issuedAtUtc, notBeforeUtc,
            expiresAtUtc, digest);
    }
    public bool Equals(ExecutionGrant? other) => other is not null && Id.Equals(other.Id) && AuthoritySet.Equals(other.AuthoritySet) && Capability == other.Capability &&
        Subject.Equals(other.Subject) && Target.Equals(other.Target) && Operation.Equals(other.Operation) && Generation == other.Generation && IdempotencyKey.Equals(other.IdempotencyKey) &&
        Issuer.Equals(other.Issuer) && Executor.Equals(other.Executor) && Approvals.SequenceEqual(other.Approvals) && Binding.Equals(other.Binding) && JournalStore.Equals(other.JournalStore) &&
        LeaseFence.Equals(other.LeaseFence) && IssuedAtUtc == other.IssuedAtUtc && NotBeforeUtc == other.NotBeforeUtc && ExpiresAtUtc == other.ExpiresAtUtc && Digest.Equals(other.Digest);
    public override bool Equals(object? obj) => Equals(obj as ExecutionGrant);
    public override int GetHashCode() => HashCode.Combine(Id, AuthoritySet, Capability, Subject,
        HashCode.Combine(Target, Operation, Generation, IdempotencyKey, Issuer, Executor, GrantContractValidation.Hash(Approvals), Binding),
        HashCode.Combine(JournalStore, LeaseFence, IssuedAtUtc, NotBeforeUtc, ExpiresAtUtc, Digest));
}
public sealed class GrantValidationRequest : IEquatable<GrantValidationRequest>
{
    private GrantValidationRequest(ExecutionGrant grant, ExecutionCapability capability,
        ExecutionSubject subject, ExecutionTarget target, AuthorityOperationId operation,
        GrantGeneration generation, LeaseFenceBinding lease, ExecutionGrantBinding binding,
        AuthorityActorId actor, DateTimeOffset observed) =>
        (Grant, RequiredCapability, ExpectedSubject, ExpectedTarget, ExpectedOperation, ExpectedGeneration,
            ExpectedLeaseFence, ExpectedBinding, ExecutingActor, ObservedAtUtc) =
        (grant, capability, subject, target, operation, generation, lease, binding, actor, observed);
    public ExecutionGrant Grant { get; }
    public ExecutionCapability RequiredCapability { get; }
    public ExecutionSubject ExpectedSubject { get; }
    public ExecutionTarget ExpectedTarget { get; }
    public AuthorityOperationId ExpectedOperation { get; }
    public GrantGeneration ExpectedGeneration { get; }
    public LeaseFenceBinding ExpectedLeaseFence { get; }
    public ExecutionGrantBinding ExpectedBinding { get; }
    public AuthorityActorId ExecutingActor { get; }
    public DateTimeOffset ObservedAtUtc { get; }
    public static GrantValidationRequest Create(ExecutionGrant grant, ExecutionCapability requiredCapability,
        ExecutionSubject expectedSubject, ExecutionTarget expectedTarget, AuthorityOperationId expectedOperation,
        GrantGeneration expectedGeneration, LeaseFenceBinding expectedLeaseFence, ExecutionGrantBinding expectedBinding,
        AuthorityActorId executingActor, DateTimeOffset observedAtUtc)
    {
        ArgumentNullException.ThrowIfNull(grant); ArgumentNullException.ThrowIfNull(requiredCapability);
        ArgumentNullException.ThrowIfNull(expectedSubject); ArgumentNullException.ThrowIfNull(expectedTarget);
        ArgumentNullException.ThrowIfNull(expectedOperation); ArgumentNullException.ThrowIfNull(expectedGeneration);
        ArgumentNullException.ThrowIfNull(expectedLeaseFence); ArgumentNullException.ThrowIfNull(expectedBinding);
        ArgumentNullException.ThrowIfNull(executingActor); GrantContractValidation.Utc(observedAtUtc, nameof(observedAtUtc));
        return new(grant, requiredCapability, expectedSubject, expectedTarget,
            expectedOperation, expectedGeneration, expectedLeaseFence,
            expectedBinding, executingActor, observedAtUtc);
    }
    public bool Equals(GrantValidationRequest? other) => other is not null && Grant.Equals(other.Grant) && RequiredCapability == other.RequiredCapability &&
        ExpectedSubject.Equals(other.ExpectedSubject) && ExpectedTarget.Equals(other.ExpectedTarget) && ExpectedOperation.Equals(other.ExpectedOperation) &&
        ExpectedGeneration == other.ExpectedGeneration && ExpectedLeaseFence.Equals(other.ExpectedLeaseFence) && ExpectedBinding.Equals(other.ExpectedBinding) &&
        ExecutingActor.Equals(other.ExecutingActor) && ObservedAtUtc == other.ObservedAtUtc;
    public override bool Equals(object? obj) => Equals(obj as GrantValidationRequest);
    public override int GetHashCode() => HashCode.Combine(
        HashCode.Combine(Grant, RequiredCapability, ExpectedSubject, ExpectedTarget,
            ExpectedOperation, ExpectedGeneration, ExpectedLeaseFence, ExpectedBinding),
        ExecutingActor, ObservedAtUtc);
}
public sealed class GrantConsumptionRequest : IEquatable<GrantConsumptionRequest>
{
    private GrantConsumptionRequest(GrantValidationRequest validation, AuthoritySetBinding set, AuthorityDigest head) =>
        (Validation, ExpectedCurrentAuthoritySet, ExpectedStoreHead) = (validation, set, head);
    public GrantValidationRequest Validation { get; }
    public AuthoritySetBinding ExpectedCurrentAuthoritySet { get; }
    public AuthorityDigest ExpectedStoreHead { get; }
    public static GrantConsumptionRequest Create(GrantValidationRequest validation,
        AuthoritySetBinding expectedCurrentAuthoritySet, AuthorityDigest expectedStoreHead)
    {
        ArgumentNullException.ThrowIfNull(validation); ArgumentNullException.ThrowIfNull(expectedCurrentAuthoritySet);
        ArgumentNullException.ThrowIfNull(expectedStoreHead); return new(validation, expectedCurrentAuthoritySet, expectedStoreHead);
    }
    public bool Equals(GrantConsumptionRequest? other) => other is not null && Validation.Equals(other.Validation) &&
        ExpectedCurrentAuthoritySet.Equals(other.ExpectedCurrentAuthoritySet) && ExpectedStoreHead.Equals(other.ExpectedStoreHead);
    public override bool Equals(object? obj) => Equals(obj as GrantConsumptionRequest);
    public override int GetHashCode() => HashCode.Combine(Validation, ExpectedCurrentAuthoritySet, ExpectedStoreHead);
}
