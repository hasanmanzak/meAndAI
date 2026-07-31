using System.Collections.ObjectModel;
using System.Globalization;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class DeclarationValidation
{
    internal static string Token(string? value, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > 128)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }

        if (!IsToken(value))
        {
            throw new ArgumentException(
                "The value is not a canonical namespaced token.",
                parameterName);
        }

        return value;
    }

    internal static string Version(string? value, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > 128)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }

        if (value.Length == 0 ||
            !IsAsciiLetterOrDigit(value[0]) ||
            value.Any(character =>
                !IsAsciiLetterOrDigit(character) &&
                character is not ('.' or '_' or '+' or '-')))
        {
            throw new ArgumentException(
                "The value is not a canonical version.",
                parameterName);
        }

        return value;
    }

    internal static string ProtocolVersion(
        string? value,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > 32)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }

        var parts = value.Split('.');
        if (parts.Length != 3 || parts.Any(part => !IsDecimalComponent(part)))
        {
            throw new ArgumentException(
                "The value is not a canonical protocol version.",
                parameterName);
        }

        return value;
    }

    internal static int CompareProtocolVersions(string left, string right)
    {
        var leftParts = left.Split('.');
        var rightParts = right.Split('.');

        for (var index = 0; index < 3; index++)
        {
            var comparison = uint.Parse(
                    leftParts[index],
                    NumberStyles.None,
                    CultureInfo.InvariantCulture)
                .CompareTo(uint.Parse(
                    rightParts[index],
                    NumberStyles.None,
                    CultureInfo.InvariantCulture));
            if (comparison != 0)
            {
                return comparison;
            }
        }

        return 0;
    }

    internal static string Opaque(
        string? value,
        string parameterName,
        int maximumLength = 2048)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);

        if (value.Length > maximumLength)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }

        if (value.Length == 0 ||
            char.IsWhiteSpace(value[0]) ||
            char.IsWhiteSpace(value[^1]) ||
            value.Any(character => character == '\0' || char.IsControl(character)) ||
            !IsWellFormedUtf16(value))
        {
            throw new ArgumentException(
                "The value is not a canonical opaque identity.",
                parameterName);
        }

        return value;
    }

    internal static IReadOnlyList<T> Snapshot<T>(
        IEnumerable<T>? source,
        string parameterName,
        bool requireNonEmpty = false)
    {
        ArgumentNullException.ThrowIfNull(source, parameterName);

        var items = new List<T>();
        foreach (var item in source)
        {
            if (item is null)
            {
                throw new ArgumentException(
                    "The collection contains a null element.",
                    parameterName);
            }

            items.Add(item);
        }

        if (requireNonEmpty && items.Count == 0)
        {
            throw new ArgumentException(
                "The collection must not be empty.",
                parameterName);
        }

        return new ReadOnlyCollection<T>(items);
    }

    internal static IReadOnlyList<T> Canonicalize<T, TKey>(
        IEnumerable<T>? source,
        string parameterName,
        Func<T, TKey> keySelector,
        IComparer<TKey> comparer,
        bool requireNonEmpty = false)
        where TKey : notnull
    {
        var snapshot = Snapshot(source, parameterName, requireNonEmpty);
        var items = snapshot.ToList();
        items.Sort((left, right) => comparer.Compare(
            keySelector(left),
            keySelector(right)));

        for (var index = 1; index < items.Count; index++)
        {
            if (comparer.Compare(
                    keySelector(items[index - 1]),
                    keySelector(items[index])) == 0)
            {
                throw new ArgumentException(
                    "The collection contains a duplicate semantic key.",
                    parameterName);
            }
        }

        return new ReadOnlyCollection<T>(items);
    }

    internal static IReadOnlyList<string> CanonicalTokens(
        IEnumerable<string>? source,
        string parameterName,
        bool requireNonEmpty = false)
    {
        var snapshot = Snapshot(source, parameterName, requireNonEmpty);
        var values = snapshot
            .Select(value => Token(value, parameterName))
            .Order(StringComparer.Ordinal)
            .ToArray();

        if (values.Distinct(StringComparer.Ordinal).Count() != values.Length)
        {
            throw new ArgumentException(
                "The collection contains a duplicate token.",
                parameterName);
        }

        return Array.AsReadOnly(values);
    }

    internal static void NonNegative(int value, string parameterName)
    {
        if (value < 0)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }
    }

    internal static void Positive(long value, string parameterName)
    {
        if (value <= 0)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }
    }

    private static bool IsToken(string value)
    {
        var segments = value.Split('.');
        if (segments.Length < 2 || !IsFirstSegment(segments[0]))
        {
            return false;
        }

        return segments.Skip(1).All(IsLaterSegment);
    }

    private static bool IsFirstSegment(string segment) =>
        segment.Length > 0 &&
        IsAsciiLower(segment[0]) &&
        IsHyphenatedSegment(segment, firstMustBeLetter: true);

    private static bool IsLaterSegment(string segment) =>
        segment.Length > 0 &&
        IsHyphenatedSegment(segment, firstMustBeLetter: false);

    private static bool IsHyphenatedSegment(
        string segment,
        bool firstMustBeLetter)
    {
        if (segment[0] == '-' || segment[^1] == '-')
        {
            return false;
        }

        var previousHyphen = false;
        for (var index = 0; index < segment.Length; index++)
        {
            var character = segment[index];
            if (character == '-')
            {
                if (previousHyphen)
                {
                    return false;
                }

                previousHyphen = true;
                continue;
            }

            if (!IsAsciiLower(character) && !IsAsciiDigit(character))
            {
                return false;
            }

            if (index == 0 && firstMustBeLetter && !IsAsciiLower(character))
            {
                return false;
            }

            previousHyphen = false;
        }

        return true;
    }

    private static bool IsDecimalComponent(string value) =>
        value.Length > 0 &&
        (value.Length == 1 || value[0] != '0') &&
        value.All(IsAsciiDigit) &&
        uint.TryParse(
            value,
            NumberStyles.None,
            CultureInfo.InvariantCulture,
            out _);

    private static bool IsWellFormedUtf16(string value)
    {
        for (var index = 0; index < value.Length; index++)
        {
            var character = value[index];
            if (char.IsHighSurrogate(character))
            {
                if (index + 1 >= value.Length ||
                    !char.IsLowSurrogate(value[++index]))
                {
                    return false;
                }
            }
            else if (char.IsLowSurrogate(character))
            {
                return false;
            }
        }

        return true;
    }

    private static bool IsAsciiLower(char value) => value is >= 'a' and <= 'z';

    private static bool IsAsciiDigit(char value) => value is >= '0' and <= '9';

    private static bool IsAsciiLetterOrDigit(char value) =>
        value is >= 'a' and <= 'z' or >= 'A' and <= 'Z' or >= '0' and <= '9';
}
