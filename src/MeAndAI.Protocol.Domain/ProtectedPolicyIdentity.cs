using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class ExtensionId : IEquatable<ExtensionId>, IComparable<ExtensionId>
{
    private const string Prefix = "ext:";

    private ExtensionId(string value) => Value = value;

    public string Value { get; }

    public static ExtensionId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not an extension identifier.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExtensionId? result)
    {
        if (value is null || value.Length > 197 ||
            !value.StartsWith(Prefix, StringComparison.Ordinal))
        {
            result = null;
            return false;
        }

        var components = value[Prefix.Length..].Split(':');
        if (components.Length != 2 ||
            !IsComponent(components[0]) ||
            !IsComponent(components[1]))
        {
            result = null;
            return false;
        }

        result = new ExtensionId(value);
        return true;
    }

    public int CompareTo(ExtensionId? other) =>
        other is null ? 1 : string.CompareOrdinal(Value, other.Value);

    public bool Equals(ExtensionId? other) =>
        other is not null && string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as ExtensionId);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;

    private static bool IsComponent(string value)
    {
        if (value.Length is < 1 or > 96 || !IsAlphaNumeric(value[0]) ||
            !IsAlphaNumeric(value[^1]) || value.Contains("..", StringComparison.Ordinal))
        {
            return false;
        }

        foreach (var character in value)
        {
            if (!IsAlphaNumeric(character) && character is not ('.' or '-'))
            {
                return false;
            }
        }

        return true;
    }

    private static bool IsAlphaNumeric(char character) =>
        character is >= 'a' and <= 'z' or >= '0' and <= '9';
}

public sealed class FindingDisposition : IEquatable<FindingDisposition>
{
    public static FindingDisposition ActiveViolation { get; } = new("active-violation");
    public static FindingDisposition HistoricalDebt { get; } = new("historical-debt");
    public static FindingDisposition Waived { get; } = new("waived");

    private FindingDisposition(string value) => Value = value;

    public string Value { get; }

    public static FindingDisposition Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a finding disposition.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out FindingDisposition? result)
    {
        result = value switch
        {
            "active-violation" => ActiveViolation,
            "historical-debt" => HistoricalDebt,
            "waived" => Waived,
            _ => null,
        };
        return result is not null;
    }

    public bool Equals(FindingDisposition? other) =>
        other is not null && string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as FindingDisposition);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}

public sealed class ExtensionTransitionKind : IEquatable<ExtensionTransitionKind>
{
    public static ExtensionTransitionKind Added { get; } = new("added");
    public static ExtensionTransitionKind Revised { get; } = new("revised");
    public static ExtensionTransitionKind Removed { get; } = new("removed");

    private ExtensionTransitionKind(string value) => Value = value;

    public string Value { get; }

    public static ExtensionTransitionKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not an extension transition kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExtensionTransitionKind? result)
    {
        result = value switch
        {
            "added" => Added,
            "revised" => Revised,
            "removed" => Removed,
            _ => null,
        };
        return result is not null;
    }

    public bool Equals(ExtensionTransitionKind? other) =>
        other is not null && string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as ExtensionTransitionKind);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
