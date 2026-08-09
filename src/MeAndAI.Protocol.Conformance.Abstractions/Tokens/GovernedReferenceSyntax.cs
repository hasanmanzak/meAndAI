using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class GovernedReferenceSyntax : IEquatable<GovernedReferenceSyntax>
{
    private GovernedReferenceSyntax(string value)
    {
        Value = value;
    }

    public static GovernedReferenceSyntax Clickable { get; } = new("clickable");

    public static GovernedReferenceSyntax NonClickable { get; } =
        new("non-clickable");

    public static GovernedReferenceSyntax UnsupportedAuthoringForm { get; } =
        new("unsupported-authoring-form");

    public string Value { get; }

    public static GovernedReferenceSyntax Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException(
                "The value is not a canonical governed reference syntax.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out GovernedReferenceSyntax? result)
    {
        result = value switch
        {
            "clickable" => Clickable,
            "non-clickable" => NonClickable,
            "unsupported-authoring-form" => UnsupportedAuthoringForm,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(GovernedReferenceSyntax? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as GovernedReferenceSyntax);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
