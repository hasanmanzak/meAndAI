using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ArtifactFileBinding
{
    private ArtifactFileBinding(
        string fileName,
        long byteLength,
        ExactSha256Digest artifactDigest)
    {
        FileName = fileName;
        ByteLength = byteLength;
        ArtifactDigest = artifactDigest;
    }

    public string FileName { get; }

    public long ByteLength { get; }

    public ExactSha256Digest ArtifactDigest { get; }

    public static ArtifactFileBinding Create(
        string fileName,
        long byteLength,
        ExactSha256Digest artifactDigest)
    {
        var canonicalFileName = ValidateFileName(fileName, nameof(fileName));
        DeclarationValidation.Positive(byteLength, nameof(byteLength));
        ArgumentNullException.ThrowIfNull(artifactDigest);

        return new ArtifactFileBinding(
            canonicalFileName,
            byteLength,
            artifactDigest);
    }

    private static string ValidateFileName(
        string value,
        string parameterName)
    {
        var canonical = DeclarationValidation.Opaque(value, parameterName);
        if (canonical.Contains('/') || canonical.Contains('\\'))
        {
            throw new ArgumentException(
                "An artifact file name must be a basename.",
                parameterName);
        }

        return canonical;
    }
}
