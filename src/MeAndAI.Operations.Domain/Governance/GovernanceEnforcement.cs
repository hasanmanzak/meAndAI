namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceEnforcement
{
    public static GovernanceEnforcement Blocking { get; } = new("blocking");

    public static GovernanceEnforcement Advisory { get; } = new("advisory");

    private GovernanceEnforcement(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
