namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class SessionCacheBudget
{
    private SessionCacheBudget(
        int maxDecodeEntries,
        long maxDecodeCanonicalBytes,
        int maxIndexEntries,
        long maxIndexNodes,
        int maxConcurrentDecodeAttempts,
        int maxConcurrentIndexAttempts,
        CacheRetentionPolicy retentionPolicy)
    {
        MaxDecodeEntries = maxDecodeEntries;
        MaxDecodeCanonicalBytes = maxDecodeCanonicalBytes;
        MaxIndexEntries = maxIndexEntries;
        MaxIndexNodes = maxIndexNodes;
        MaxConcurrentDecodeAttempts = maxConcurrentDecodeAttempts;
        MaxConcurrentIndexAttempts = maxConcurrentIndexAttempts;
        RetentionPolicy = retentionPolicy;
    }

    public int MaxDecodeEntries { get; }

    public long MaxDecodeCanonicalBytes { get; }

    public int MaxIndexEntries { get; }

    public long MaxIndexNodes { get; }

    public int MaxConcurrentDecodeAttempts { get; }

    public int MaxConcurrentIndexAttempts { get; }

    public CacheRetentionPolicy RetentionPolicy { get; }

    public static SessionCacheBudget Create(
        int maxDecodeEntries,
        long maxDecodeCanonicalBytes,
        int maxIndexEntries,
        long maxIndexNodes,
        int maxConcurrentDecodeAttempts,
        int maxConcurrentIndexAttempts,
        CacheRetentionPolicy retentionPolicy)
    {
        DeclarationValidation.NonNegative(
            maxDecodeEntries,
            nameof(maxDecodeEntries));
        NonNegative(maxDecodeCanonicalBytes, nameof(maxDecodeCanonicalBytes));
        DeclarationValidation.NonNegative(
            maxIndexEntries,
            nameof(maxIndexEntries));
        NonNegative(maxIndexNodes, nameof(maxIndexNodes));
        DeclarationValidation.Positive(
            maxConcurrentDecodeAttempts,
            nameof(maxConcurrentDecodeAttempts));
        DeclarationValidation.Positive(
            maxConcurrentIndexAttempts,
            nameof(maxConcurrentIndexAttempts));
        ArgumentNullException.ThrowIfNull(retentionPolicy);

        return new SessionCacheBudget(
            maxDecodeEntries,
            maxDecodeCanonicalBytes,
            maxIndexEntries,
            maxIndexNodes,
            maxConcurrentDecodeAttempts,
            maxConcurrentIndexAttempts,
            retentionPolicy);
    }

    private static void NonNegative(long value, string parameterName)
    {
        if (value < 0)
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }
    }
}
