using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class IndexInvocationScope : IEquatable<IndexInvocationScope>
{
    private IndexInvocationScope(string value)
    {
        Value = value;
    }

    public static IndexInvocationScope PerContext { get; } = new("per-context");

    public static IndexInvocationScope PerPlan { get; } = new("per-plan");

    public string Value { get; }

    public static IndexInvocationScope Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical index invocation scope.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out IndexInvocationScope? result)
    {
        result = value switch
        {
            "per-context" => PerContext,
            "per-plan" => PerPlan,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(IndexInvocationScope? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as IndexInvocationScope);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
