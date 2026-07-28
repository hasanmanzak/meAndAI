namespace MeAndAI.Operations.Domain.Results;

public sealed record OperationOutcome
{
    public static OperationOutcome Succeeded { get; } = new("succeeded");

    public static OperationOutcome Rejected { get; } = new("rejected");

    public static OperationOutcome Failed { get; } = new("failed");

    public static OperationOutcome Canceled { get; } = new("canceled");

    private static readonly Dictionary<string, OperationOutcome> KnownValues = new(
        StringComparer.Ordinal)
    {
        [Succeeded.Value] = Succeeded,
        [Rejected.Value] = Rejected,
        [Failed.Value] = Failed,
        [Canceled.Value] = Canceled,
    };

    private OperationOutcome(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static OperationOutcome Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return KnownValues.TryGetValue(value, out var outcome)
            ? outcome
            : throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "Unknown operation outcome identity.");
    }

    public override string ToString() => Value;
}
