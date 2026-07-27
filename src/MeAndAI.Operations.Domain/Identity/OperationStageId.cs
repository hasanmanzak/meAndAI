namespace MeAndAI.Operations.Domain.Identity;

public sealed record OperationStageId
{
    public static OperationStageId Validate { get; } = new("validate");

    public static OperationStageId Discover { get; } = new("discover");

    public static OperationStageId Assess { get; } = new("assess");

    public static OperationStageId Plan { get; } = new("plan");

    public static OperationStageId Apply { get; } = new("apply");

    public static OperationStageId Publish { get; } = new("publish");

    public static OperationStageId Finalize { get; } = new("finalize");

    private static readonly Dictionary<string, OperationStageId>
        KnownValues = new(
            StringComparer.Ordinal)
        {
            [Validate.Value] = Validate,
            [Discover.Value] = Discover,
            [Assess.Value] = Assess,
            [Plan.Value] = Plan,
            [Apply.Value] = Apply,
            [Publish.Value] = Publish,
            [Finalize.Value] = Finalize,
        };

    private OperationStageId(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static OperationStageId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return KnownValues.TryGetValue(value, out var stage)
            ? stage
            : throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "Unknown operational stage identity.");
    }

    public override string ToString() => Value;
}
