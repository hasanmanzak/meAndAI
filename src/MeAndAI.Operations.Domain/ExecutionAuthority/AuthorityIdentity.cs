using System.Collections.ObjectModel;
using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Operations.Domain.ExecutionAuthority;

internal static class ExecutionAuthorityValidation
{
    internal static string Token(string value, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);
        return IsToken(value)
            ? value
            : throw new ArgumentException(
                "The value is not a canonical execution-authority token.",
                parameterName);
    }
    internal static string ParseToken(string value, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(value, parameterName);
        return IsToken(value)
            ? value
            : throw new FormatException(
                "The value is not a canonical execution-authority token.");
    }
    internal static bool IsToken(string? value)
    {
        if (value is null || value.Length is < 1 or > 128 || value[^1] == '.')
        {
            return false;
        }
        foreach (ReadOnlyMemory<char> segment in Split(value))
        {
            ReadOnlySpan<char> span = segment.Span;
            if (span.IsEmpty || span[0] is < 'a' or > 'z')
            {
                return false;
            }

            bool hyphen = false;
            for (int index = 1; index < span.Length; index++)
            {
                char character = span[index];
                if (character == '-')
                {
                    if (hyphen || index == span.Length - 1)
                    {
                        return false;
                    }

                    hyphen = true;
                }
                else if ((character is < 'a' or > 'z') &&
                    (character is < '0' or > '9'))
                {
                    return false;
                }
                else
                {
                    hyphen = false;
                }
            }
        }
        return true;
    }
    internal static IReadOnlyList<T> SortedUnique<T>(
        IEnumerable<T> values,
        string parameterName,
        Comparison<T> comparison,
        bool allowEmpty = false)
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        List<T> result = [.. values];
        if ((!allowEmpty && result.Count == 0) ||
            result.Any(static value => value is null))
        {
            throw new ArgumentException(
                "The collection is empty or contains null.",
                parameterName);
        }

        result.Sort(comparison);
        if (result.Zip(
                result.Skip(1),
                (left, right) => comparison(left, right))
            .Any(static value => value == 0))
        {
            throw new ArgumentException(
                "The collection contains duplicate canonical values.",
                parameterName);
        }

        return new ReadOnlyCollection<T>(result);
    }
    private static IEnumerable<ReadOnlyMemory<char>> Split(string value)
    {
        int start = 0;
        for (int index = 0; index <= value.Length; index++)
        {
            if (index == value.Length || value[index] == '.')
            {
                yield return value.AsMemory(start, index - start);
                start = index + 1;
            }
        }
    }
}
public sealed class AuthorityActorId :
    IEquatable<AuthorityActorId>, IComparable<AuthorityActorId>
{
    private AuthorityActorId(string value) => Value = value;
    public string Value { get; }
    public static AuthorityActorId Parse(string value) =>
        new(ExecutionAuthorityValidation.ParseToken(value, nameof(value)));
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out AuthorityActorId? result)
    {
        result = ExecutionAuthorityValidation.IsToken(value)
            ? new AuthorityActorId(value!)
            : null;
        return result is not null;
    }
    public bool Equals(AuthorityActorId? other) =>
        other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) => Equals(obj as AuthorityActorId);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(AuthorityActorId? other) =>
        other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
}

public sealed class AuthoritySetId :
    IEquatable<AuthoritySetId>, IComparable<AuthoritySetId>
{
    private AuthoritySetId(string value) => Value = value;
    public string Value { get; }
    public static AuthoritySetId Parse(string value) =>
        new(ExecutionAuthorityValidation.ParseToken(value, nameof(value)));
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out AuthoritySetId? result)
    {
        result = ExecutionAuthorityValidation.IsToken(value)
            ? new AuthoritySetId(value!)
            : null;
        return result is not null;
    }
    public bool Equals(AuthoritySetId? other) =>
        other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) => Equals(obj as AuthoritySetId);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(AuthoritySetId? other) =>
        other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
}

public sealed class JournalStoreReference :
    IEquatable<JournalStoreReference>, IComparable<JournalStoreReference>
{
    private JournalStoreReference(string value) => Value = value;
    public string Value { get; }
    public static JournalStoreReference Parse(string value) =>
        new(ExecutionAuthorityValidation.ParseToken(value, nameof(value)));
    public static bool TryParse(
        string? value, [NotNullWhen(true)] out JournalStoreReference? result)
    {
        result = ExecutionAuthorityValidation.IsToken(value)
            ? new JournalStoreReference(value!)
            : null;
        return result is not null;
    }
    public bool Equals(JournalStoreReference? other) =>
        other is not null && StringComparer.Ordinal.Equals(Value, other.Value);
    public override bool Equals(object? obj) =>
        Equals(obj as JournalStoreReference);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public int CompareTo(JournalStoreReference? other) =>
        other is null ? 1 : StringComparer.Ordinal.Compare(Value, other.Value);
    public override string ToString() => Value;
}
