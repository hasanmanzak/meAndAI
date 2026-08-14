using System.Diagnostics.CodeAnalysis;
using System.Globalization;

namespace MeAndAI.Operations.Domain.ExecutionAuthority;

public sealed class AuthorityDigest :
    IEquatable<AuthorityDigest>, IComparable<AuthorityDigest>
{
    private AuthorityDigest(string value) => Value = value;
    public string Value { get; }
    public static AuthorityDigest Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return IsDigest(value)
            ? new(value)
            : throw new FormatException(
                "The value is not a lowercase hexadecimal SHA-256 digest.");
    }
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out AuthorityDigest? result)
    {
        result = IsDigest(value) ? new AuthorityDigest(value!) : null;
        return result is not null;
    }
    public static AuthorityDigest FromHashBytes(ReadOnlySpan<byte> hashBytes)
    {
        if (hashBytes.Length != 32)
        {
            throw new ArgumentException(
                "A SHA-256 digest requires exactly 32 bytes.",
                nameof(hashBytes));
        }
        return new(Convert.ToHexString(hashBytes).ToLowerInvariant());
    }
    public bool Equals(AuthorityDigest? other) =>
        other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) => Equals(obj as AuthorityDigest);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(AuthorityDigest? other) =>
        other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
    private static bool IsDigest(string? value) =>
        value is { Length: 64 } &&
        value.All(static character =>
            character is >= '0' and <= '9' or >= 'a' and <= 'f');
}

public sealed record AuthorityRevision
{
    private AuthorityRevision(long value) => Value = value;
    public long Value { get; }
    public static AuthorityRevision Create(long value)
    {
        if (value < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(value), value, "Authority revisions cannot be negative.");
        }
        return new(value);
    }
    public override string ToString() =>
        Value.ToString(CultureInfo.InvariantCulture);
}
