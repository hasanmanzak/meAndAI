using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CacheRetentionPolicy : IEquatable<CacheRetentionPolicy>
{
    private CacheRetentionPolicy(string value)
    {
        Value = value;
    }

    public static CacheRetentionPolicy RetainLowestCanonicalKeys { get; } =
        new("retain-lowest-canonical-keys");

    public string Value { get; }

    public static CacheRetentionPolicy Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical cache retention policy.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out CacheRetentionPolicy? result)
    {
        result = value switch
        {
            "retain-lowest-canonical-keys" => RetainLowestCanonicalKeys,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(CacheRetentionPolicy? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as CacheRetentionPolicy);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
