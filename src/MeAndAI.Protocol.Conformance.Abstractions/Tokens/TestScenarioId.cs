using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class TestScenarioId :
    IEquatable<TestScenarioId>,
    IComparable<TestScenarioId>
{
    private TestScenarioId(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static TestScenarioId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical test scenario identifier.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out TestScenarioId? result)
    {
        if (!IsValid(value))
        {
            result = null;
            return false;
        }

        result = new TestScenarioId(value!);
        return true;
    }

    public int CompareTo(TestScenarioId? other) =>
        other is null ? 1 : string.CompareOrdinal(Value, other.Value);

    public bool Equals(TestScenarioId? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as TestScenarioId);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;

    private static bool IsValid(string? value)
    {
        if (value is null || value.Length != 9 ||
            !value.StartsWith("TEST-", StringComparison.Ordinal))
        {
            return false;
        }

        for (var index = 5; index < value.Length; index++)
        {
            if (value[index] is < '0' or > '9')
            {
                return false;
            }
        }

        return true;
    }
}
