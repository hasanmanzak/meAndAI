namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceSeverity
{
    public static GovernanceSeverity Critical { get; } = new("critical");

    public static GovernanceSeverity High { get; } = new("high");

    public static GovernanceSeverity Medium { get; } = new("medium");

    public static GovernanceSeverity Low { get; } = new("low");

    public static GovernanceSeverity Info { get; } = new("info");

    private GovernanceSeverity(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
