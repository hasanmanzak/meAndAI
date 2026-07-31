using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class NormativeFragmentDeclaration
{
    private NormativeFragmentDeclaration(
        string path,
        string containingBlob,
        string anchor,
        int startLine,
        int endLine,
        string canonicalizationSchema,
        long canonicalByteLength,
        ExactSha256Digest fragmentDigest)
    {
        Path = path;
        ContainingBlob = containingBlob;
        Anchor = anchor;
        StartLine = startLine;
        EndLine = endLine;
        CanonicalizationSchema = canonicalizationSchema;
        CanonicalByteLength = canonicalByteLength;
        FragmentDigest = fragmentDigest;
    }

    public string Path { get; }

    public string ContainingBlob { get; }

    public string Anchor { get; }

    public int StartLine { get; }

    public int EndLine { get; }

    public string CanonicalizationSchema { get; }

    public long CanonicalByteLength { get; }

    public ExactSha256Digest FragmentDigest { get; }

    public static NormativeFragmentDeclaration Create(
        string path,
        string containingBlob,
        string anchor,
        int startLine,
        int endLine,
        string canonicalizationSchema,
        long canonicalByteLength,
        ExactSha256Digest fragmentDigest)
    {
        var canonicalPath = ValidatePath(path);
        var canonicalBlob = ValidateBlob(containingBlob);
        var canonicalAnchor = DeclarationValidation.Opaque(
            anchor,
            nameof(anchor),
            maximumLength: 256);
        if (canonicalAnchor.Contains('#'))
        {
            throw new ArgumentException(
                "The anchor must not include a fragment prefix.",
                nameof(anchor));
        }

        if (startLine <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(startLine));
        }

        if (endLine < startLine)
        {
            throw new ArgumentOutOfRangeException(nameof(endLine));
        }

        DeclarationValidation.Positive(
            canonicalByteLength,
            nameof(canonicalByteLength));
        ArgumentNullException.ThrowIfNull(fragmentDigest);

        return new NormativeFragmentDeclaration(
            canonicalPath,
            canonicalBlob,
            canonicalAnchor,
            startLine,
            endLine,
            DeclarationValidation.Token(
                canonicalizationSchema,
                nameof(canonicalizationSchema)),
            canonicalByteLength,
            fragmentDigest);
    }

    private static string ValidatePath(string? path)
    {
        var value = DeclarationValidation.Opaque(
            path,
            nameof(path),
            maximumLength: 1024);
        if (System.IO.Path.IsPathRooted(value) ||
            value.Contains('\\') ||
            value.Split('/').Any(segment =>
                segment.Length == 0 || segment is "." or ".."))
        {
            throw new ArgumentException(
                "The path must be a canonical repository-relative path.",
                nameof(path));
        }

        return value;
    }

    private static string ValidateBlob(string? containingBlob)
    {
        ArgumentNullException.ThrowIfNull(containingBlob);
        if (containingBlob.Length != 40 || containingBlob.Any(character =>
                character is not (>= '0' and <= '9') and
                    not (>= 'a' and <= 'f')))
        {
            throw new ArgumentException(
                "The containing blob must be lowercase SHA-1 text.",
                nameof(containingBlob));
        }

        return containingBlob;
    }
}
