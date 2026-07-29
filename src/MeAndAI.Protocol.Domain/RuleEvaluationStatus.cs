using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class RuleEvaluationStatus : IEquatable<RuleEvaluationStatus>
{
    private const string SatisfiedToken = "satisfied";
    private const string ViolatedToken = "violated";
    private const string NotApplicableToken = "not-applicable";
    private const string NotEvaluatedToken = "not-evaluated";

    private RuleEvaluationStatus(string value)
    {
        Value = value;
    }

    public static RuleEvaluationStatus Satisfied { get; } =
        new(SatisfiedToken);

    public static RuleEvaluationStatus Violated { get; } = new(ViolatedToken);

    public static RuleEvaluationStatus NotApplicable { get; } =
        new(NotApplicableToken);

    public static RuleEvaluationStatus NotEvaluated { get; } =
        new(NotEvaluatedToken);

    public string Value { get; }

    public static RuleEvaluationStatus Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out RuleEvaluationStatus? result)
    {
        result = value switch
        {
            SatisfiedToken => Satisfied,
            ViolatedToken => Violated,
            NotApplicableToken => NotApplicable,
            NotEvaluatedToken => NotEvaluated,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(RuleEvaluationStatus? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is RuleEvaluationStatus other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
