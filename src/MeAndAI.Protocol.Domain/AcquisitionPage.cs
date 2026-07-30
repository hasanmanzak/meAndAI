namespace MeAndAI.Protocol.Domain;

public sealed class AcquisitionPage : IEquatable<AcquisitionPage>
{
    private AcquisitionPage(
        int sequence,
        ExactSha256Digest? requestCursorDigest,
        ExactSha256Digest? nextCursorDigest,
        long sourceObjectCount)
    {
        Sequence = sequence;
        RequestCursorDigest = requestCursorDigest;
        NextCursorDigest = nextCursorDigest;
        SourceObjectCount = sourceObjectCount;
    }

    public int Sequence { get; }

    public ExactSha256Digest? RequestCursorDigest { get; }

    public ExactSha256Digest? NextCursorDigest { get; }

    public long SourceObjectCount { get; }

    public static AcquisitionPage Create(
        int sequence,
        ExactSha256Digest? requestCursorDigest,
        ExactSha256Digest? nextCursorDigest,
        long sourceObjectCount)
    {
        if (sequence <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(sequence),
                sequence,
                "A page sequence must be positive.");
        }

        if (sourceObjectCount < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(sourceObjectCount),
                sourceObjectCount,
                "A page source-object count cannot be negative.");
        }

        return new AcquisitionPage(
            sequence,
            requestCursorDigest,
            nextCursorDigest,
            sourceObjectCount);
    }

    public bool Equals(AcquisitionPage? other) =>
        other is not null &&
        Sequence == other.Sequence &&
        Equals(RequestCursorDigest, other.RequestCursorDigest) &&
        Equals(NextCursorDigest, other.NextCursorDigest) &&
        SourceObjectCount == other.SourceObjectCount;

    public override bool Equals(object? obj) =>
        Equals(obj as AcquisitionPage);

    public override int GetHashCode() => HashCode.Combine(
        Sequence,
        RequestCursorDigest,
        NextCursorDigest,
        SourceObjectCount);
}
