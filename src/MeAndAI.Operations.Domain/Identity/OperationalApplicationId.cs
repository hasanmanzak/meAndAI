namespace MeAndAI.Operations.Domain.Identity;

public sealed record OperationalApplicationId
{
    public static OperationalApplicationId Governance { get; } =
        new("governance");

    public static OperationalApplicationId Adoption { get; } =
        new("adoption");

    public static OperationalApplicationId ConsumerUpdate { get; } =
        new("consumer-update");

    private static readonly Dictionary<string, OperationalApplicationId>
        KnownValues = new(
            StringComparer.Ordinal)
        {
            [Governance.Value] = Governance,
            [Adoption.Value] = Adoption,
            [ConsumerUpdate.Value] = ConsumerUpdate,
        };

    private OperationalApplicationId(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static OperationalApplicationId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return KnownValues.TryGetValue(value, out var application)
            ? application
            : throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "Unknown operational application identity.");
    }

    public override string ToString() => Value;
}
