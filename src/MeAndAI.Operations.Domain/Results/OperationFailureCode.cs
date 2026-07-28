namespace MeAndAI.Operations.Domain.Results;

public sealed record OperationFailureCode
{
    public static OperationFailureCode MalformedInput { get; } =
        new("input.malformed");

    public static OperationFailureCode CapabilityDenied { get; } =
        new("capability.denied");

    public static OperationFailureCode DependencyFailed { get; } =
        new("dependency.failed");

    public static OperationFailureCode OperationCanceled { get; } =
        new("operation.canceled");

    private static readonly Dictionary<string, OperationFailureCode> KnownValues = new(
        StringComparer.Ordinal)
    {
        [MalformedInput.Value] = MalformedInput,
        [CapabilityDenied.Value] = CapabilityDenied,
        [DependencyFailed.Value] = DependencyFailed,
        [OperationCanceled.Value] = OperationCanceled,
    };

    private OperationFailureCode(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static OperationFailureCode Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return KnownValues.TryGetValue(value, out var code)
            ? code
            : throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "Unknown operation failure identity.");
    }

    public override string ToString() => Value;
}
