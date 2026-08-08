namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ReviewedAuthorityPermalink :
    IEquatable<ReviewedAuthorityPermalink>
{
    private static readonly string[] StableFragmentPrefixes =
    [
        "issuecomment-",
        "pullrequestreview-",
        "discussion_r",
        "commitcomment-",
    ];

    private ReviewedAuthorityPermalink(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static ReviewedAuthorityPermalink Create(string value)
    {
        var canonical = DeclarationValidation.Opaque(value, nameof(value));
        if (!canonical.StartsWith("https://", StringComparison.Ordinal) ||
            canonical.Contains('?') ||
            !Uri.IsWellFormedUriString(canonical, UriKind.Absolute) ||
            !Uri.TryCreate(canonical, UriKind.Absolute, out var uri) ||
            !string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.Ordinal) ||
            uri.Host.Length == 0 ||
            uri.AbsolutePath.Length <= 1 ||
            uri.UserInfo.Length != 0 ||
            !HasValidFragment(canonical, uri))
        {
            throw new ArgumentException(
                "The value is not an immutable HTTPS authority permalink.",
                nameof(value));
        }

        return new ReviewedAuthorityPermalink(canonical);
    }

    public bool Equals(ReviewedAuthorityPermalink? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as ReviewedAuthorityPermalink);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;

    private static bool HasValidFragment(string value, Uri uri)
    {
        var fragmentMarker = value.IndexOf('#');
        if (fragmentMarker < 0)
        {
            return true;
        }

        if (uri.Fragment.Length <= 1 || fragmentMarker != value.LastIndexOf('#'))
        {
            return false;
        }

        var fragment = uri.Fragment[1..];
        foreach (var prefix in StableFragmentPrefixes)
        {
            if (fragment.StartsWith(prefix, StringComparison.Ordinal) &&
                fragment.Length > prefix.Length &&
                fragment[prefix.Length..].All(character =>
                    character is >= '0' and <= '9'))
            {
                return true;
            }
        }

        return false;
    }
}
