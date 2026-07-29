using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class ExactSha256Digest :
    IEquatable<ExactSha256Digest>,
    IComparable<ExactSha256Digest>
{
    private ExactSha256Digest(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static ExactSha256Digest Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not an exact SHA-256 digest.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExactSha256Digest? result)
    {
        if (value is null || !IsValid(value))
        {
            result = null;
            return false;
        }

        result = new ExactSha256Digest(value);
        return true;
    }

    public static ExactSha256Digest FromHashBytes(
        ReadOnlySpan<byte> hashBytes)
    {
        if (hashBytes.Length != 32)
        {
            throw new ArgumentException(
                "An exact SHA-256 digest requires exactly 32 hash bytes.",
                nameof(hashBytes));
        }

        return new ExactSha256Digest(
            Convert.ToHexString(hashBytes).ToLowerInvariant());
    }

    public int CompareTo(ExactSha256Digest? other) =>
        other is null ? 1 : string.CompareOrdinal(Value, other.Value);

    public bool Equals(ExactSha256Digest? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as ExactSha256Digest);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;

    private static bool IsValid(string value)
    {
        if (value.Length != 64)
        {
            return false;
        }

        foreach (var character in value)
        {
            if (character is not (>= '0' and <= '9') and
                not (>= 'a' and <= 'f'))
            {
                return false;
            }
        }

        return true;
    }
}
