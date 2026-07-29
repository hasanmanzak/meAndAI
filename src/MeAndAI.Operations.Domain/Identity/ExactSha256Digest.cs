using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Operations.Domain.Identity;

public sealed record ExactSha256Digest
{
    private const int RequiredCharacterLength = 64;
    private const int RequiredByteLength = 32;

    private ExactSha256Digest(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static ExactSha256Digest Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return ExactLowercaseAsciiHex.IsMatch(
            value,
            RequiredCharacterLength)
            ? new ExactSha256Digest(value)
            : throw new ArgumentException(
                "An exact SHA-256 digest must contain exactly 64 lowercase ASCII hexadecimal characters.",
                nameof(value));
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExactSha256Digest? result)
    {
        if (!ExactLowercaseAsciiHex.IsMatch(
                value,
                RequiredCharacterLength))
        {
            result = null;
            return false;
        }

        result = new ExactSha256Digest(value);
        return true;
    }

    public static ExactSha256Digest FromHashBytes(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length != RequiredByteLength)
        {
            throw new ArgumentException(
                "A SHA-256 hash must contain exactly 32 bytes.",
                nameof(bytes));
        }

        return new ExactSha256Digest(Convert.ToHexStringLower(bytes));
    }

    public override string ToString() => Value;
}
