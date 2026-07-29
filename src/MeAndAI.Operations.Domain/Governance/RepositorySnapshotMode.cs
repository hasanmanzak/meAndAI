namespace MeAndAI.Operations.Domain.Governance;

public sealed record RepositorySnapshotMode
{
    public static RepositorySnapshotMode ExactCommit { get; } =
        new("exact-commit");

    private RepositorySnapshotMode(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}
