using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class EnforcementDecision : IEquatable<EnforcementDecision>
{
    private const string AllowToken = "allow";
    private const string BlockToken = "block";
    private const string ReportOnlyToken = "report-only";

    private EnforcementDecision(string value)
    {
        Value = value;
    }

    public static EnforcementDecision Allow { get; } = new(AllowToken);

    public static EnforcementDecision Block { get; } = new(BlockToken);

    public static EnforcementDecision ReportOnly { get; } =
        new(ReportOnlyToken);

    public string Value { get; }

    public static EnforcementDecision Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out EnforcementDecision? result)
    {
        result = value switch
        {
            AllowToken => Allow,
            BlockToken => Block,
            ReportOnlyToken => ReportOnly,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(EnforcementDecision? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is EnforcementDecision other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
