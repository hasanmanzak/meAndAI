namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceProfileEvidenceState
{
    public static GovernanceProfileEvidenceState Complete { get; } =
        new("complete");

    public static GovernanceProfileEvidenceState Incomplete { get; } =
        new("incomplete");

    private GovernanceProfileEvidenceState(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
