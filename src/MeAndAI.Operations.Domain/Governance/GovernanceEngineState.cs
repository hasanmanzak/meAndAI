namespace MeAndAI.Operations.Domain.Governance;

public sealed record GovernanceEngineState
{
    public static GovernanceEngineState CSharpShadow { get; } =
        new("csharp-shadow");

    public static GovernanceEngineState CSharpReleasedNonAuthoritative { get; } =
        new("csharp-released-non-authoritative");

    private GovernanceEngineState(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
