using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RemediationKey : IEquatable<RemediationKey>
{
    private RemediationKey(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static RemediationKey Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical remediation key.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out RemediationKey? result)
    {
        if (!ValueSyntax.IsNamespacedToken(value))
        {
            result = null;
            return false;
        }

        result = new RemediationKey(value!);
        return true;
    }

    public bool Equals(RemediationKey? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as RemediationKey);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
