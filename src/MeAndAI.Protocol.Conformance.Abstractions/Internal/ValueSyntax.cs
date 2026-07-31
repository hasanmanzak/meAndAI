namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class ValueSyntax
{
    internal static bool IsNamespacedToken(string? value)
    {
        if (value is null || value.Length is < 3 or > 128)
        {
            return false;
        }

        var hasNamespaceSeparator = false;
        var atSegmentStart = true;
        var previousWasHyphen = false;

        foreach (var character in value)
        {
            if (character == '.')
            {
                if (atSegmentStart || previousWasHyphen)
                {
                    return false;
                }

                hasNamespaceSeparator = true;
                atSegmentStart = true;
                previousWasHyphen = false;
                continue;
            }

            if (atSegmentStart)
            {
                var validStart = IsLowerAsciiLetter(character) ||
                    (hasNamespaceSeparator && IsAsciiDigit(character));

                if (!validStart)
                {
                    return false;
                }

                atSegmentStart = false;
                previousWasHyphen = false;
                continue;
            }

            if (IsLowerAsciiLetter(character) || IsAsciiDigit(character))
            {
                previousWasHyphen = false;
                continue;
            }

            if (character != '-' || previousWasHyphen)
            {
                return false;
            }

            previousWasHyphen = true;
        }

        return hasNamespaceSeparator && !atSegmentStart && !previousWasHyphen;
    }

    private static bool IsLowerAsciiLetter(char value) =>
        value is >= 'a' and <= 'z';

    private static bool IsAsciiDigit(char value) =>
        value is >= '0' and <= '9';
}
