namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceAuthorityState
{
    public static GovernanceAuthorityState PowerShellAuthority { get; } =
        new("powershell-authority");

    private GovernanceAuthorityState(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
