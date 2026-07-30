using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class RuleId : IEquatable<RuleId>, IComparable<RuleId>
{
    private RuleId(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static RuleId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not an exact rule identifier.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out RuleId? result)
    {
        if (value is null || !IsValid(value))
        {
            result = null;
            return false;
        }

        result = new RuleId(value);
        return true;
    }

    public int CompareTo(RuleId? other) =>
        other is null ? 1 : string.CompareOrdinal(Value, other.Value);

    public bool Equals(RuleId? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as RuleId);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;

    private static bool IsValid(string value)
    {
        if (value.Length != 9 ||
            value[0] != 'R' ||
            value[1] != 'U' ||
            value[2] != 'L' ||
            value[3] != 'E' ||
            value[4] != '-')
        {
            return false;
        }

        var numericValue = 0;
        for (var index = 5; index < value.Length; index++)
        {
            var character = value[index];
            if (character is < '0' or > '9')
            {
                return false;
            }

            numericValue = (numericValue * 10) + (character - '0');
        }

        return numericValue > 0;
    }
}
