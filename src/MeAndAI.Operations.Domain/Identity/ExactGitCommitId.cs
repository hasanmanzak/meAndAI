using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Operations.Domain.Identity;

public sealed record ExactGitCommitId
{
    private const int RequiredLength = 40;

    private ExactGitCommitId(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static ExactGitCommitId Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return ExactLowercaseAsciiHex.IsMatch(value, RequiredLength)
            ? new ExactGitCommitId(value)
            : throw new ArgumentException(
                "An exact Git commit identity must contain exactly 40 lowercase ASCII hexadecimal characters.",
                nameof(value));
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ExactGitCommitId? result)
    {
        if (!ExactLowercaseAsciiHex.IsMatch(value, RequiredLength))
        {
            result = null;
            return false;
        }

        result = new ExactGitCommitId(value);
        return true;
    }

    public override string ToString() => Value;
}
