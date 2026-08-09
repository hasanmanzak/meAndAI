using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RuleTransitionKind : IEquatable<RuleTransitionKind>
{
    private RuleTransitionKind(string value)
    {
        Value = value;
    }

    public static RuleTransitionKind Unchanged { get; } = new("unchanged");

    public static RuleTransitionKind Added { get; } = new("added");

    public static RuleTransitionKind Revised { get; } = new("revised");

    public static RuleTransitionKind Retired { get; } = new("retired");

    public string Value { get; }

    public static RuleTransitionKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical rule transition kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out RuleTransitionKind? result)
    {
        result = value switch
        {
            "unchanged" => Unchanged,
            "added" => Added,
            "revised" => Revised,
            "retired" => Retired,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(RuleTransitionKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as RuleTransitionKind);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
