namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceVerdict
{
    public static GovernanceVerdict Conforming { get; } = new("conforming");

    public static GovernanceVerdict Nonconforming { get; } =
        new("nonconforming");

    public static GovernanceVerdict Incomplete { get; } = new("incomplete");

    private GovernanceVerdict(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
