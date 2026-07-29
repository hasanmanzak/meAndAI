namespace MeAndAI.Operations.Domain.Governance;

public sealed record EvidenceScope
{
    public static EvidenceScope Repository { get; } = new("repository");

    private EvidenceScope(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
