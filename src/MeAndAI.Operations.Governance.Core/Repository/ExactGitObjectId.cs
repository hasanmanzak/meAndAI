using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Repository;

internal sealed record ExactGitObjectId
{
    private ExactGitObjectId(string value)
    {
        Value = value;
    }

    internal string Value { get; }

    internal static ExactGitObjectId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return ExactGitCommitId.TryParse(value, out _)
            ? new ExactGitObjectId(value)
            : throw new ArgumentException(
                "An exact Git object identity must contain exactly 40 lowercase ASCII hexadecimal characters.",
                nameof(value));
    }

    public override string ToString() => Value;
}
