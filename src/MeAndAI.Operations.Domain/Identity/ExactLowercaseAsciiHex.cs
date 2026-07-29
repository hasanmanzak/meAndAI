using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Operations.Domain.Identity;

internal static class ExactLowercaseAsciiHex
{
    internal static bool IsMatch(
        [NotNullWhen(true)] string? value,
        int requiredLength)
    {
        if (value is null || value.Length != requiredLength)
        {
            return false;
        }

        foreach (var character in value)
        {
            if (character is not (>= '0' and <= '9' or >= 'a' and <= 'f'))
            {
                return false;
            }
        }

        return true;
    }
}
