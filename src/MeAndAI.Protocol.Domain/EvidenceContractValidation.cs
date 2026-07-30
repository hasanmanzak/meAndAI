namespace MeAndAI.Protocol.Domain;

internal static class EvidenceContractValidation
{
    internal static string OpenToken(string value, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > 128)
        {
            throw new ArgumentOutOfRangeException(
                parameterName,
                value,
                "The namespaced token exceeds its maximum length.");
        }

        if (value.Length < 3 || !HasValidOpenTokenGrammar(value))
        {
            throw new ArgumentException(
                "The value is not a valid namespaced token.",
                parameterName);
        }

        return value;
    }

    internal static string Version(string value, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > 128)
        {
            throw new ArgumentOutOfRangeException(
                parameterName,
                value,
                "The contract version exceeds its maximum length.");
        }

        if (value.Length < 1 ||
            !IsAsciiLetterOrDigit(value[0]) ||
            value.Skip(1).Any(character =>
                !IsAsciiLetterOrDigit(character) &&
                character is not ('.' or '_' or '+' or '-')))
        {
            throw new ArgumentException(
                "The value is not a valid contract version.",
                parameterName);
        }

        return value;
    }

    internal static string OpaqueIdentity(
        string value,
        string parameterName,
        int maximumLength = 2048)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > maximumLength)
        {
            throw new ArgumentOutOfRangeException(
                parameterName,
                value,
                "The opaque identity exceeds its maximum length.");
        }

        if (value.Length < 1 ||
            char.IsWhiteSpace(value[0]) ||
            char.IsWhiteSpace(value[^1]) ||
            !HasWellFormedSafeUtf16(value))
        {
            throw new ArgumentException(
                "The value is not a valid opaque identity.",
                parameterName);
        }

        return value;
    }

    internal static string RepositoryRelativePath(
        string value,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > 4096)
        {
            throw new ArgumentOutOfRangeException(
                parameterName,
                value,
                "The repository-relative path exceeds its maximum length.");
        }

        if (value.Length < 1 ||
            value[0] == '/' ||
            value[^1] == '/' ||
            value.Contains('\\') ||
            !HasWellFormedSafeUtf16(value))
        {
            throw new ArgumentException(
                "The value is not a valid repository-relative path.",
                parameterName);
        }

        var segments = value.Split('/');
        if (segments.Any(segment =>
                segment.Length == 0 ||
                segment is "." or "..") ||
            (segments[0].Length >= 2 &&
             IsAsciiLetter(segments[0][0]) &&
             segments[0][1] == ':'))
        {
            throw new ArgumentException(
                "The value is not a valid repository-relative path.",
                parameterName);
        }

        return value;
    }

    internal static string? OptionalOpaque(
        string? value,
        string parameterName,
        int maximumLength = 2048) =>
        value is null
            ? null
            : OpaqueIdentity(value, parameterName, maximumLength);

    internal static void Utc(DateTimeOffset value, string parameterName)
    {
        if (value.Offset != TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(
                parameterName,
                value,
                "The timestamp must have a zero UTC offset.");
        }
    }

    internal static void OrderedInterval(
        DateTimeOffset startedAtUtc,
        string startedParameterName,
        DateTimeOffset completedAtUtc,
        string completedParameterName)
    {
        Utc(startedAtUtc, startedParameterName);
        Utc(completedAtUtc, completedParameterName);

        if (completedAtUtc < startedAtUtc)
        {
            throw new ArgumentOutOfRangeException(
                completedParameterName,
                completedAtUtc,
                "The completed timestamp cannot precede the start.");
        }
    }

    internal static string TargetIdentity(
        SnapshotKind snapshotKind,
        string value,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(snapshotKind);
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (snapshotKind.Equals(SnapshotKind.ExactCommit))
        {
            return GitObjectIdentity(value, parameterName);
        }

        if (snapshotKind.Equals(SnapshotKind.Candidate) ||
            snapshotKind.Equals(SnapshotKind.CapturedEvidence))
        {
            return Sha256Identity(value, parameterName);
        }

        if (snapshotKind.Equals(SnapshotKind.ProviderEvent) ||
            snapshotKind.Equals(SnapshotKind.ProviderFullInventory))
        {
            return OpaqueIdentity(value, parameterName);
        }

        throw new ArgumentException(
            "The snapshot kind is not declared.",
            nameof(snapshotKind));
    }

    internal static string BoundaryIdentity(
        SnapshotKind snapshotKind,
        string value,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(snapshotKind);

        if (snapshotKind.Equals(SnapshotKind.ExactCommit))
        {
            return GitObjectIdentity(value, parameterName);
        }

        if (snapshotKind.Equals(SnapshotKind.Candidate) ||
            snapshotKind.Equals(SnapshotKind.CapturedEvidence) ||
            snapshotKind.Equals(SnapshotKind.ProviderEvent) ||
            snapshotKind.Equals(SnapshotKind.ProviderFullInventory))
        {
            return Sha256Identity(value, parameterName);
        }

        throw new ArgumentException(
            "The snapshot kind is not declared.",
            nameof(snapshotKind));
    }

    internal static string GitObjectIdentity(
        string value,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length is not (40 or 64) || !IsLowerHex(value))
        {
            throw new ArgumentException(
                "The value is not an exact Git object identity.",
                parameterName);
        }

        return value;
    }

    internal static string Sha256Identity(
        string value,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length != 64 || !IsLowerHex(value))
        {
            throw new ArgumentException(
                "The value is not an exact SHA-256 identity.",
                parameterName);
        }

        return value;
    }

    internal static T[] Materialize<T>(
        IEnumerable<T> values,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        return [.. values];
    }

    internal static void NoNullElements<T>(
        IEnumerable<T?> values,
        string parameterName)
        where T : class
    {
        if (values.Any(value => value is null))
        {
            throw new ArgumentException(
                "The collection cannot contain null values.",
                parameterName);
        }
    }

    internal static IReadOnlyList<T> ReadOnly<T>(T[] values) =>
        Array.AsReadOnly(values);

    private static bool HasValidOpenTokenGrammar(string value)
    {
        var segments = value.Split('.');
        if (segments.Length < 2 ||
            segments.Any(segment => segment.Length == 0))
        {
            return false;
        }

        if (!IsAsciiLower(segments[0][0]) ||
            !HasValidTokenSegment(segments[0], allowLeadingDigit: false))
        {
            return false;
        }

        return segments
            .Skip(1)
            .All(segment => HasValidTokenSegment(
                segment,
                allowLeadingDigit: true));
    }

    private static bool HasValidTokenSegment(
        string segment,
        bool allowLeadingDigit)
    {
        if ((!allowLeadingDigit && !IsAsciiLower(segment[0])) ||
            (allowLeadingDigit &&
             !IsAsciiLower(segment[0]) &&
             !IsAsciiDigit(segment[0])) ||
            segment[^1] == '-')
        {
            return false;
        }

        var previousWasHyphen = false;
        foreach (var character in segment)
        {
            if (character == '-')
            {
                if (previousWasHyphen)
                {
                    return false;
                }

                previousWasHyphen = true;
                continue;
            }

            if (!IsAsciiLower(character) && !IsAsciiDigit(character))
            {
                return false;
            }

            previousWasHyphen = false;
        }

        return true;
    }

    private static bool HasWellFormedSafeUtf16(string value)
    {
        for (var index = 0; index < value.Length; index++)
        {
            var character = value[index];
            if (character == '\0' || char.IsControl(character))
            {
                return false;
            }

            if (char.IsHighSurrogate(character))
            {
                if (index + 1 >= value.Length ||
                    !char.IsLowSurrogate(value[index + 1]))
                {
                    return false;
                }

                index++;
            }
            else if (char.IsLowSurrogate(character))
            {
                return false;
            }
        }

        return true;
    }

    private static bool IsLowerHex(string value) =>
        value.All(character =>
            IsAsciiDigit(character) || character is >= 'a' and <= 'f');

    private static bool IsAsciiLetterOrDigit(char value) =>
        IsAsciiLetter(value) || IsAsciiDigit(value);

    private static bool IsAsciiLetter(char value) =>
        value is >= 'a' and <= 'z' or >= 'A' and <= 'Z';

    private static bool IsAsciiLower(char value) =>
        value is >= 'a' and <= 'z';

    private static bool IsAsciiDigit(char value) =>
        value is >= '0' and <= '9';
}
