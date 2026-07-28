namespace MeAndAI.Operations.Domain.Authority;

public sealed record OperationalCapability
{
    public static OperationalCapability RepositoryRead { get; } =
        new("repository.read", 0);

    public static OperationalCapability RepositoryMutation { get; } =
        new("repository.mutate", 1);

    public static OperationalCapability ProviderRead { get; } =
        new("provider.read", 2);

    public static OperationalCapability ProviderMutation { get; } =
        new("provider.mutate", 3);

    private static readonly Dictionary<string, OperationalCapability>
        KnownValues = new(
            StringComparer.Ordinal)
        {
            [RepositoryRead.Value] = RepositoryRead,
            [RepositoryMutation.Value] = RepositoryMutation,
            [ProviderRead.Value] = ProviderRead,
            [ProviderMutation.Value] = ProviderMutation,
        };

    private OperationalCapability(string value, int sortOrder)
    {
        Value = value;
        SortOrder = sortOrder;
    }

    public string Value { get; }

    internal int SortOrder { get; }

    public static OperationalCapability Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return KnownValues.TryGetValue(value, out var capability)
            ? capability
            : throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "Unknown operational capability identity.");
    }

    public override string ToString() => Value;
}
