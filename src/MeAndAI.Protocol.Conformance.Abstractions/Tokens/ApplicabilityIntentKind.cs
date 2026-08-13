using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ApplicabilityIntentKind : IEquatable<ApplicabilityIntentKind>
{
    private ApplicabilityIntentKind(string value) => Value = value;

    public static ApplicabilityIntentKind Applicable { get; } = new("applicable");

    public static ApplicabilityIntentKind NotApplicable { get; } =
        new("not-applicable");

    public static ApplicabilityIntentKind Unresolved { get; } = new("unresolved");

    public string Value { get; }

    public static ApplicabilityIntentKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException(
                "The value is not a canonical applicability intent kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ApplicabilityIntentKind? result)
    {
        result = value switch
        {
            "applicable" => Applicable,
            "not-applicable" => NotApplicable,
            "unresolved" => Unresolved,
            _ => null,
        };
        return result is not null;
    }

    public bool Equals(ApplicabilityIntentKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as ApplicabilityIntentKind);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
