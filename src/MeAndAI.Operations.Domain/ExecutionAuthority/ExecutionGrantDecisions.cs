using System.Diagnostics.CodeAnalysis;
using System.Globalization;

namespace MeAndAI.Operations.Domain.ExecutionAuthority;

public sealed class AuthorityGrantId :
    IEquatable<AuthorityGrantId>, IComparable<AuthorityGrantId>
{
    private AuthorityGrantId(string value) => Value = value;
    public string Value { get; }
    public static AuthorityGrantId Parse(string value) => new(ExecutionAuthorityValidation.ParseToken(value, nameof(value)));
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out AuthorityGrantId? result)
    {
        result = ExecutionAuthorityValidation.IsToken(value)
            ? new AuthorityGrantId(value!) : null;
        return result is not null;
    }
    public bool Equals(AuthorityGrantId? other) => other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) => Equals(obj as AuthorityGrantId);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(AuthorityGrantId? other) => other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
}
public sealed class AuthorityOperationId :
    IEquatable<AuthorityOperationId>, IComparable<AuthorityOperationId>
{
    private AuthorityOperationId(string value) => Value = value;
    public string Value { get; }
    public static AuthorityOperationId Parse(string value) => new(ExecutionAuthorityValidation.ParseToken(value, nameof(value)));
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out AuthorityOperationId? result)
    {
        result = ExecutionAuthorityValidation.IsToken(value)
            ? new AuthorityOperationId(value!) : null;
        return result is not null;
    }
    public bool Equals(AuthorityOperationId? other) => other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) => Equals(obj as AuthorityOperationId);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(AuthorityOperationId? other) => other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
}
public sealed class IdempotencyKey :
    IEquatable<IdempotencyKey>, IComparable<IdempotencyKey>
{
    private IdempotencyKey(string value) => Value = value;
    public string Value { get; }
    public static IdempotencyKey Parse(string value) => new(ExecutionAuthorityValidation.ParseToken(value, nameof(value)));
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out IdempotencyKey? result)
    {
        result = ExecutionAuthorityValidation.IsToken(value)
            ? new IdempotencyKey(value!) : null;
        return result is not null;
    }
    public bool Equals(IdempotencyKey? other) => other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) => Equals(obj as IdempotencyKey);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(IdempotencyKey? other) => other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
}
public sealed record GrantGeneration
{
    private GrantGeneration(long value) => Value = value;
    public long Value { get; }
    public static GrantGeneration Create(long value)
    {
        if (value <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(value), value, "Grant generations must be positive.");
        }
        return new(value);
    }
    public override string ToString() =>
        Value.ToString(CultureInfo.InvariantCulture);
}
public sealed record ExecutionCapability
{
    private static readonly Dictionary<string, ExecutionCapability> Values =
        new(StringComparer.Ordinal)
        {
            ["repository.read"] = new("repository.read"),
            ["provider.read"] = new("provider.read"),
            ["report.publish"] = new("report.publish"),
            ["repository.mutate"] = new("repository.mutate"),
            ["provider.mutate"] = new("provider.mutate"),
            ["extension.activate"] = new("extension.activate"),
            ["release.publish"] = new("release.publish"),
            ["authority.transfer"] = new("authority.transfer")
        };
    private ExecutionCapability(string value) => Value = value;
    public static ExecutionCapability RepositoryRead => Values["repository.read"]; public static ExecutionCapability ProviderRead => Values["provider.read"];
    public static ExecutionCapability ReportPublish => Values["report.publish"]; public static ExecutionCapability RepositoryMutate => Values["repository.mutate"];
    public static ExecutionCapability ProviderMutate => Values["provider.mutate"]; public static ExecutionCapability ExtensionActivate => Values["extension.activate"];
    public static ExecutionCapability ReleasePublish => Values["release.publish"]; public static ExecutionCapability AuthorityTransfer => Values["authority.transfer"];
    public string Value { get; }
    public static ExecutionCapability Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value); return Values.TryGetValue(value, out ExecutionCapability? capability)
            ? capability : throw new FormatException("The execution capability is not recognized.");
    }
    public override string ToString() => Value;
}
public sealed record ExecutionGrantRejection
{
    private static readonly Dictionary<string, ExecutionGrantRejection> Values =
        new(StringComparer.Ordinal)
        {
            ["none"] = new("none"),
            ["snapshot.unavailable"] = new("snapshot.unavailable"),
            ["snapshot.drift"] = new("snapshot.drift"),
            ["actor.mismatch"] = new("actor.mismatch"),
            ["role.conflict"] = new("role.conflict"),
            ["approval.mismatch"] = new("approval.mismatch"),
            ["subject.mismatch"] = new("subject.mismatch"),
            ["target.mismatch"] = new("target.mismatch"),
            ["operation.mismatch"] = new("operation.mismatch"),
            ["generation.mismatch"] = new("generation.mismatch"),
            ["lease-fence.mismatch"] = new("lease-fence.mismatch"),
            ["capability.mismatch"] = new("capability.mismatch"),
            ["binding.mismatch"] = new("binding.mismatch"),
            ["time.not-yet-valid"] = new("time.not-yet-valid"),
            ["time.expired"] = new("time.expired"),
            ["grant.replayed"] = new("grant.replayed"),
            ["grant-store.drift"] = new("grant-store.drift"),
            ["activation-record.unavailable"] = new("activation-record.unavailable"),
            ["activation-record.drift"] = new("activation-record.drift"),
            ["cas.conflict"] = new("cas.conflict")
        };
    private ExecutionGrantRejection(string value) => Value = value;
    public static ExecutionGrantRejection None => Values["none"]; public static ExecutionGrantRejection SnapshotUnavailable => Values["snapshot.unavailable"];
    public static ExecutionGrantRejection SnapshotDrift => Values["snapshot.drift"]; public static ExecutionGrantRejection ActorMismatch => Values["actor.mismatch"];
    public static ExecutionGrantRejection RoleConflict => Values["role.conflict"]; public static ExecutionGrantRejection ApprovalMismatch => Values["approval.mismatch"];
    public static ExecutionGrantRejection SubjectMismatch => Values["subject.mismatch"]; public static ExecutionGrantRejection TargetMismatch => Values["target.mismatch"];
    public static ExecutionGrantRejection OperationMismatch => Values["operation.mismatch"]; public static ExecutionGrantRejection GenerationMismatch => Values["generation.mismatch"];
    public static ExecutionGrantRejection LeaseFenceMismatch => Values["lease-fence.mismatch"]; public static ExecutionGrantRejection CapabilityMismatch => Values["capability.mismatch"];
    public static ExecutionGrantRejection BindingMismatch => Values["binding.mismatch"]; public static ExecutionGrantRejection NotYetValid => Values["time.not-yet-valid"];
    public static ExecutionGrantRejection Expired => Values["time.expired"]; public static ExecutionGrantRejection Replayed => Values["grant.replayed"];
    public static ExecutionGrantRejection GrantStoreDrift => Values["grant-store.drift"]; public static ExecutionGrantRejection ActivationRecordUnavailable => Values["activation-record.unavailable"];
    public static ExecutionGrantRejection ActivationRecordDrift => Values["activation-record.drift"]; public static ExecutionGrantRejection CasConflict => Values["cas.conflict"];
    public string Value { get; }
    public static ExecutionGrantRejection Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value); return Values.TryGetValue(value, out ExecutionGrantRejection? rejection)
            ? rejection : throw new FormatException("The grant rejection is not recognized.");
    }
    public override string ToString() => Value;
}
public sealed class ExecutionGrantDecision : IEquatable<ExecutionGrantDecision>
{
    private ExecutionGrantDecision(bool authorized, ExecutionGrantRejection rejection) =>
        (IsAuthorized, Rejection) = (authorized, rejection);
    public bool IsAuthorized { get; }
    public ExecutionGrantRejection Rejection { get; }
    public static ExecutionGrantDecision Authorized() =>
        new(true, ExecutionGrantRejection.None);
    public static ExecutionGrantDecision Rejected(ExecutionGrantRejection rejection)
    {
        ArgumentNullException.ThrowIfNull(rejection);
        return rejection == ExecutionGrantRejection.None
            ? throw new ArgumentException(
                "An unauthorized decision requires a rejection.", nameof(rejection))
            : new(false, rejection);
    }
    public bool Equals(ExecutionGrantDecision? other) =>
        other is not null && IsAuthorized == other.IsAuthorized &&
        Rejection == other.Rejection;
    public override bool Equals(object? obj) => Equals(obj as ExecutionGrantDecision);
    public override int GetHashCode() => HashCode.Combine(IsAuthorized, Rejection);
}
