using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class SurfaceKind : IEquatable<SurfaceKind>
{
    private const string RepositoryToken = "repository";
    private const string ProviderToken = "provider";
    private const string WorkflowToken = "workflow";
    private const string ReleaseToken = "release";

    private SurfaceKind(string value)
    {
        Value = value;
    }

    public static SurfaceKind Repository { get; } = new(RepositoryToken);

    public static SurfaceKind Provider { get; } = new(ProviderToken);

    public static SurfaceKind Workflow { get; } = new(WorkflowToken);

    public static SurfaceKind Release { get; } = new(ReleaseToken);

    public string Value { get; }

    public static SurfaceKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out SurfaceKind? result)
    {
        result = value switch
        {
            RepositoryToken => Repository,
            ProviderToken => Provider,
            WorkflowToken => Workflow,
            ReleaseToken => Release,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(SurfaceKind? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is SurfaceKind other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
