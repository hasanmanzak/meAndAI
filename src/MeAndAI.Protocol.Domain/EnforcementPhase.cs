using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class EnforcementPhase : IEquatable<EnforcementPhase>
{
    private const string AuditToken = "audit";
    private const string ProspectiveToken = "prospective";
    private const string FullBlockingToken = "full-blocking";

    private EnforcementPhase(string value)
    {
        Value = value;
    }

    public static EnforcementPhase Audit { get; } = new(AuditToken);

    public static EnforcementPhase Prospective { get; } =
        new(ProspectiveToken);

    public static EnforcementPhase FullBlocking { get; } =
        new(FullBlockingToken);

    public string Value { get; }

    public static EnforcementPhase Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out EnforcementPhase? result)
    {
        result = value switch
        {
            AuditToken => Audit,
            ProspectiveToken => Prospective,
            FullBlockingToken => FullBlocking,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(EnforcementPhase? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is EnforcementPhase other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
