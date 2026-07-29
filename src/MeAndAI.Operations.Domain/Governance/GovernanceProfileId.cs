namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceProfileId
{
    public static GovernanceProfileId ProtocolAuthority { get; } =
        new("protocol-authority");

    public static GovernanceProfileId Consumer { get; } =
        new("consumer");

    private static readonly Dictionary<string, GovernanceProfileId> KnownValues =
        new(StringComparer.Ordinal)
        {
            [ProtocolAuthority.Value] = ProtocolAuthority,
            [Consumer.Value] = Consumer,
        };

    private GovernanceProfileId(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static GovernanceProfileId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return KnownValues.TryGetValue(value, out var profile)
            ? profile
            : throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "Unknown governance profile identity.");
    }

    public override string ToString() => Value;
}
