using System.Reflection;
using System.Security.Cryptography;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBDecodeModelCacheTests
{
    private const string Marker = "TEST-0210-B-BEHAVIOR-RED-0007";
    private const string Release = "qualification-slice|manifest|1";
    private const string ForeignRelease = "qualification-slice|manifest-foreign|1";
    private const string Session = "session-01";
    private const string KeyABase64 =
        "cHJvdG9jb2wuY2FjaGUta2V5LmZyYW1lLnYxCgBxdWFsaWZpY2F0aW9uLXNsaWNlfG1hbmlmZXN0fDF8cmVwb3NpdG9yeS10cmVlfGluc3RydWN0aW9uLUE=";
    private const string KeyBBase64 =
        "cHJvdG9jb2wuY2FjaGUta2V5LmZyYW1lLnYxCgBxdWFsaWZpY2F0aW9uLXNsaWNlfG1hbmlmZXN0fDF8cmVwb3NpdG9yeS10cmVlfGluc3RydWN0aW9uLUI=";
    private const string KeyCBase64 =
        "cHJvdG9jb2wuY2FjaGUta2V5LmZyYW1lLnYxCgBxdWFsaWZpY2F0aW9uLXNsaWNlfG1hbmlmZXN0fDF8cmVwb3NpdG9yeS10cmVlfGluc3RydWN0aW9uLUM=";
    private const string KeyASha =
        "3966ED0A5CD736B311F695A3746090A405345C47E8584888C7201D13F7583959";
    private const string KeyBSha =
        "585852BDC1A3395DFC01611685BCDB7337C1AD6377142CAD63F946EADBF9A842";
    private const string KeyCSha =
        "AC7CB7EF1168A6590480B247EA91A1F75CC7F5CCE7B57F95F293B7410E7F94C4";

    [Fact]
    [Trait("ContractSlice", "B")]
    [Trait("Scenario", "TEST-0210")]
    public async Task Enforces_exact_codec_cache_single_flight_collision_and_eviction()
    {
        var aggregate = await ExecuteContractAsync();
        if (aggregate is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal(3, aggregate.FixtureKeys);
        Assert.Equal(3, aggregate.SingleFlightCallers);
        Assert.Equal(3, aggregate.CanonicalQueueStarts);
        Assert.True(aggregate.RetentionVectorsClosed);
        Assert.True(aggregate.FailureVectorsClosed);
    }

    private static async Task<CacheAggregateMirror?> ExecuteContractAsync()
    {
        var keys = AssertKeyContract();
        await AssertCollisionAndIsolationAsync(keys);
        await AssertSingleFlightAsync(keys.A);
        await AssertCanonicalQueueAsync(keys);
        await AssertFailureLifecycleAsync(keys);
        await AssertRetentionAsync(keys);
        AssertRetentionOverflow();

        return new CacheAggregateMirror(3, 3, 3, true, true);
    }

    private static CacheKeysMirror AssertKeyContract()
    {
        var aBytes = Convert.FromBase64String(KeyABase64);
        var bBytes = Convert.FromBase64String(KeyBBase64);
        var cBytes = Convert.FromBase64String(KeyCBase64);
        Assert.Equal(89, aBytes.Length);
        Assert.Equal(89, bBytes.Length);
        Assert.Equal(89, cBytes.Length);
        Assert.Equal(KeyASha, Convert.ToHexString(SHA256.HashData(aBytes)));
        Assert.Equal(KeyBSha, Convert.ToHexString(SHA256.HashData(bBytes)));
        Assert.Equal(KeyCSha, Convert.ToHexString(SHA256.HashData(cBytes)));

        var a = CodecModelCacheKeyMirror.Create(Release, aBytes);
        var b = CodecModelCacheKeyMirror.Create(Release, bBytes);
        var c = CodecModelCacheKeyMirror.Create(Release, cBytes);
        Assert.True(a.CompareTo(b) < 0);
        Assert.True(b.CompareTo(c) < 0);
        Assert.True(c.CompareTo(a) > 0);
        Assert.Equal(1, a.CompareTo(null));
        Assert.Equal(KeyASha, Convert.ToHexString(a.Digest.Span));
        Assert.Equal(KeyBSha, Convert.ToHexString(b.Digest.Span));
        Assert.Equal(KeyCSha, Convert.ToHexString(c.Digest.Span));

        aBytes[0] ^= 0xFF;
        Assert.Equal(KeyASha, Convert.ToHexString(a.Digest.Span));
        Assert.Equal(
            Convert.FromBase64String(KeyABase64),
            a.CanonicalBytes.ToArray());

        Assert.Throws<ArgumentException>(() =>
            CodecModelCacheKeyMirror.Create(string.Empty, bBytes));
        Assert.Throws<ArgumentException>(() =>
            CodecModelCacheKeyMirror.Create(Release, ReadOnlyMemory<byte>.Empty));
        var digestError = Assert.Throws<ArgumentException>(() =>
            CodecModelCacheKeyMirror.CreateCollisionProbe(
                Release,
                bBytes,
                new byte[31]));
        Assert.Equal("forcedDigest", digestError.ParamName);
        Assert.Throws<ArgumentException>(() =>
            DecodeModelValueMirror.Create("model", ReadOnlyMemory<byte>.Empty));
        Assert.Throws<ArgumentException>(() =>
            DeclaredDecodeFailureMirror.Create(
                "failure",
                ReadOnlyMemory<byte>.Empty));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            DecodeModelCacheMirror.Create(Release, Session, -1, 0, 1));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            DecodeModelCacheMirror.Create(Release, Session, 0, -1, 1));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            DecodeModelCacheMirror.Create(Release, Session, 0, 0, 0));

        return new CacheKeysMirror(a, b, c);
    }

    private static async Task AssertCollisionAndIsolationAsync(CacheKeysMirror keys)
    {
        var cache = DecodeModelCacheMirror.Create(Release, Session, 4, 64, 1);
        var attempt = Success("model-a", 4, 0xA1);
        var first = await cache.GetOrAddAsync(
            keys.A,
            _ => Task.FromResult(attempt),
            CancellationToken.None);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, first.Disposition);

        var collision = CodecModelCacheKeyMirror.CreateCollisionProbe(
            Release,
            keys.B.CanonicalBytes,
            keys.A.Digest);
        var collisionCalls = 0;
        var error = Assert.Throws<DecodeCacheIntegrityMirrorException>(() =>
        {
            _ = cache.GetOrAddAsync(
                collision,
                _ =>
                {
                    collisionCalls++;
                    return Task.FromResult(Success("collision", 1, 0xEE));
                },
                CancellationToken.None);
        });
        Assert.Equal("protocol.cache.key-collision", error.Code);
        Assert.Equal("Conflicting decode cache key bytes.", error.Message);
        Assert.Equal(0, collisionCalls);

        var foreignKey = CodecModelCacheKeyMirror.Create(
            ForeignRelease,
            keys.A.CanonicalBytes);
        var foreign = Assert.Throws<DecodeCacheIntegrityMirrorException>(() =>
        {
            _ = cache.GetOrAddAsync(
                foreignKey,
                _ => Task.FromResult(attempt),
                CancellationToken.None);
        });
        Assert.Equal("protocol.cache.release-identity-mismatch", foreign.Code);

        var secondSession = DecodeModelCacheMirror.Create(
            Release,
            "session-02",
            4,
            64,
            1);
        var sessionCalls = 0;
        var sessionResult = await secondSession.GetOrAddAsync(
            keys.A,
            _ =>
            {
                sessionCalls++;
                return Task.FromResult(attempt);
            },
            CancellationToken.None);
        Assert.Equal(1, sessionCalls);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, sessionResult.Disposition);
    }

    private static async Task AssertSingleFlightAsync(CodecModelCacheKeyMirror key)
    {
        var cache = DecodeModelCacheMirror.Create(Release, Session, 4, 64, 2);
        var started = Gate();
        var release = Gate();
        var attempt = Success("model-a", 4, 0xA2);
        var calls = 0;
        using var ownerTokenSource = new CancellationTokenSource();
        using var joinTokenSource = new CancellationTokenSource();
        CancellationToken observedToken = default;

        var owner = cache.GetOrAddAsync(
            key,
            async token =>
            {
                calls++;
                observedToken = token;
                started.TrySetResult();
                await release.Task.WaitAsync(token);
                return attempt;
            },
            ownerTokenSource.Token);
        await started.Task;
        var joined1 = cache.GetOrAddAsync(
            key,
            _ => throw new InvalidOperationException("join producer invoked"),
            joinTokenSource.Token);
        var joined2 = cache.GetOrAddAsync(
            key,
            _ => throw new InvalidOperationException("join producer invoked"),
            CancellationToken.None);
        release.TrySetResult();

        var results = await Task.WhenAll(owner, joined1, joined2);
        Assert.Equal(1, calls);
        Assert.Equal(ownerTokenSource.Token, observedToken);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, results[0].Disposition);
        Assert.Equal(DecodeCacheDispositionMirror.Joined, results[1].Disposition);
        Assert.Equal(DecodeCacheDispositionMirror.Joined, results[2].Disposition);
        Assert.All(results, item => Assert.Same(attempt, item.Attempt));

        var retained = await cache.GetOrAddAsync(
            key,
            _ => throw new InvalidOperationException("retained producer invoked"),
            CancellationToken.None);
        Assert.Equal(DecodeCacheDispositionMirror.Retained, retained.Disposition);
        Assert.Same(attempt, retained.Attempt);
    }

    private static async Task AssertCanonicalQueueAsync(CacheKeysMirror keys)
    {
        var cache = DecodeModelCacheMirror.Create(Release, Session, 8, 128, 1);
        var startedA = Gate();
        var releaseA = Gate();
        var starts = new List<string>();
        var gate = new object();

        void Record(string value)
        {
            lock (gate)
            {
                starts.Add(value);
            }
        }

        var a = cache.GetOrAddAsync(
            keys.A,
            async token =>
            {
                Record("A");
                startedA.TrySetResult();
                await releaseA.Task.WaitAsync(token);
                return Success("model-a", 4, 0xA3);
            },
            CancellationToken.None);
        await startedA.Task;
        var c = cache.GetOrAddAsync(
            keys.C,
            _ =>
            {
                Record("C");
                return Task.FromResult(Success("model-c", 4, 0xC3));
            },
            CancellationToken.None);
        var b = cache.GetOrAddAsync(
            keys.B,
            _ =>
            {
                Record("B");
                return Task.FromResult(Success("model-b", 4, 0xB3));
            },
            CancellationToken.None);
        Assert.Equal(["A"], starts);
        releaseA.TrySetResult();
        var results = await Task.WhenAll(a, b, c);
        Assert.Equal(["A", "B", "C"], starts);
        Assert.All(
            results,
            result => Assert.Equal(
                DecodeCacheDispositionMirror.Produced,
                result.Disposition));
    }

    private static async Task AssertFailureLifecycleAsync(CacheKeysMirror keys)
    {
        var declaredCache = DecodeModelCacheMirror.Create(
            Release,
            Session,
            4,
            64,
            1);
        var declared = DecodeAttemptMirror.DeclaredFailure(
            DeclaredDecodeFailureMirror.Create(
                "protocol.codec.invalid-repository-tree",
                Bytes(5, 0xD1)));
        var declaredCalls = 0;
        var firstDeclared = await declaredCache.GetOrAddAsync(
            keys.A,
            _ =>
            {
                declaredCalls++;
                return Task.FromResult(declared);
            },
            CancellationToken.None);
        var retainedDeclared = await declaredCache.GetOrAddAsync(
            keys.A,
            _ => throw new InvalidOperationException("declared producer invoked"),
            CancellationToken.None);
        Assert.Equal(1, declaredCalls);
        Assert.Same(firstDeclared.Attempt, retainedDeclared.Attempt);
        Assert.Equal(
            DecodeCacheDispositionMirror.Retained,
            retainedDeclared.Disposition);

        using var preCancelled = new CancellationTokenSource();
        preCancelled.Cancel();
        var foreign = CodecModelCacheKeyMirror.Create(
            ForeignRelease,
            keys.B.CanonicalBytes);
        var cancellationCache = DecodeModelCacheMirror.Create(
            Release,
            Session,
            4,
            64,
            1);
        Assert.Throws<OperationCanceledException>(() =>
        {
            _ = cancellationCache.GetOrAddAsync(
                foreign,
                _ => Task.FromResult(Success("unused", 1, 0x01)),
                preCancelled.Token);
        });

        using var owner = new CancellationTokenSource();
        var cancellationCalls = 0;
        var cancelledTask = cancellationCache.GetOrAddAsync(
            keys.B,
            token =>
            {
                cancellationCalls++;
                Assert.Equal(owner.Token, token);
                return Task.FromException<DecodeAttemptMirror>(
                    new OperationCanceledException(token));
            },
            owner.Token);
        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            async () => await cancelledTask);
        var afterCancellation = await cancellationCache.GetOrAddAsync(
            keys.B,
            _ =>
            {
                cancellationCalls++;
                return Task.FromResult(Success("model-b", 4, 0xB4));
            },
            CancellationToken.None);
        Assert.Equal(2, cancellationCalls);
        Assert.Equal(
            DecodeCacheDispositionMirror.Produced,
            afterCancellation.Disposition);

        await AssertExceptionIsNotRetainedAsync(
            keys.C,
            new TimeoutException("timeout"));
        await AssertExceptionIsNotRetainedAsync(
            keys.C,
            new ApplicationException("host"));

        var nullCache = DecodeModelCacheMirror.Create(Release, Session, 4, 64, 1);
        var nullTask = nullCache.GetOrAddAsync(
            keys.C,
            _ => Task.FromResult<DecodeAttemptMirror>(null!),
            CancellationToken.None);
        var nullError = await Assert.ThrowsAsync<InvalidOperationException>(
            async () => await nullTask);
        Assert.Equal("Decode attempt returned null.", nullError.Message);
        var afterNull = await nullCache.GetOrAddAsync(
            keys.C,
            _ => Task.FromResult(Success("model-c", 4, 0xC4)),
            CancellationToken.None);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, afterNull.Disposition);
    }

    private static async Task AssertExceptionIsNotRetainedAsync(
        CodecModelCacheKeyMirror key,
        Exception failure)
    {
        var cache = DecodeModelCacheMirror.Create(Release, Session, 4, 64, 1);
        var calls = 0;
        var failed = cache.GetOrAddAsync(
            key,
            _ =>
            {
                calls++;
                return Task.FromException<DecodeAttemptMirror>(failure);
            },
            CancellationToken.None);
        var observed = await Assert.ThrowsAsync(failure.GetType(), async () =>
            await failed);
        Assert.Same(failure, observed);
        var fresh = await cache.GetOrAddAsync(
            key,
            _ =>
            {
                calls++;
                return Task.FromResult(Success("fresh", 3, 0xF1));
            },
            CancellationToken.None);
        Assert.Equal(2, calls);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, fresh.Disposition);
    }

    private static async Task AssertRetentionAsync(CacheKeysMirror keys)
    {
        var equality = DecodeModelCacheMirror.Create(Release, Session, 2, 10, 1);
        var equalityCalls = new Dictionary<string, int>();
        await ProduceAsync(equality, keys.A, "A", 4, equalityCalls);
        await ProduceAsync(equality, keys.B, "B", 6, equalityCalls);
        var retainedA = await ProduceAsync(equality, keys.A, "A", 4, equalityCalls);
        var retainedB = await ProduceAsync(equality, keys.B, "B", 6, equalityCalls);
        await ProduceAsync(equality, keys.C, "C", 1, equalityCalls);
        await ProduceAsync(equality, keys.C, "C", 1, equalityCalls);
        Assert.Equal(DecodeCacheDispositionMirror.Retained, retainedA.Disposition);
        Assert.Equal(DecodeCacheDispositionMirror.Retained, retainedB.Disposition);
        Assert.Equal(1, equalityCalls["A"]);
        Assert.Equal(1, equalityCalls["B"]);
        Assert.Equal(2, equalityCalls["C"]);

        var eviction = DecodeModelCacheMirror.Create(Release, Session, 2, 10, 1);
        var evictionCalls = new Dictionary<string, int>();
        await ProduceAsync(eviction, keys.B, "B", 5, evictionCalls);
        await ProduceAsync(eviction, keys.C, "C", 5, evictionCalls);
        await ProduceAsync(eviction, keys.A, "A", 5, evictionCalls);
        var lowA = await ProduceAsync(eviction, keys.A, "A", 5, evictionCalls);
        var lowB = await ProduceAsync(eviction, keys.B, "B", 5, evictionCalls);
        var evictedC = await ProduceAsync(eviction, keys.C, "C", 5, evictionCalls);
        Assert.Equal(DecodeCacheDispositionMirror.Retained, lowA.Disposition);
        Assert.Equal(DecodeCacheDispositionMirror.Retained, lowB.Disposition);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, evictedC.Disposition);
        Assert.Equal(2, evictionCalls["C"]);

        var oversized = DecodeModelCacheMirror.Create(Release, Session, 2, 10, 1);
        var oversizedCalls = new Dictionary<string, int>();
        await ProduceAsync(oversized, keys.B, "B", 11, oversizedCalls);
        await ProduceAsync(oversized, keys.C, "C", 4, oversizedCalls);
        var repeatedB = await ProduceAsync(oversized, keys.B, "B", 11, oversizedCalls);
        var retainedC = await ProduceAsync(oversized, keys.C, "C", 4, oversizedCalls);
        Assert.Equal(DecodeCacheDispositionMirror.Produced, repeatedB.Disposition);
        Assert.Equal(DecodeCacheDispositionMirror.Retained, retainedC.Disposition);
        Assert.Equal(2, oversizedCalls["B"]);
        Assert.Equal(1, oversizedCalls["C"]);

        var countZero = DecodeModelCacheMirror.Create(Release, Session, 0, 10, 1);
        var countZeroCalls = new Dictionary<string, int>();
        await ProduceAsync(countZero, keys.A, "A", 1, countZeroCalls);
        await ProduceAsync(countZero, keys.A, "A", 1, countZeroCalls);
        Assert.Equal(2, countZeroCalls["A"]);
        var bytesZero = DecodeModelCacheMirror.Create(Release, Session, 2, 0, 1);
        var bytesZeroCalls = new Dictionary<string, int>();
        await ProduceAsync(bytesZero, keys.A, "A", 1, bytesZeroCalls);
        await ProduceAsync(bytesZero, keys.A, "A", 1, bytesZeroCalls);
        Assert.Equal(2, bytesZeroCalls["A"]);
    }

    private static void AssertRetentionOverflow()
    {
        var method = typeof(DecodeModelCacheMirror).GetMethod(
            "CheckedRetentionCost",
            BindingFlags.Static | BindingFlags.NonPublic);
        Assert.NotNull(method);
        var outer = Assert.Throws<TargetInvocationException>(() =>
        {
            _ = method.Invoke(null, [long.MaxValue, 1L]);
        });
        var error = Assert.IsType<DecodeCacheIntegrityMirrorException>(
            outer.InnerException);
        Assert.Equal("protocol.cache.retention-cost-overflow", error.Code);
    }

    private static async Task<DecodeCacheResultMirror> ProduceAsync(
        DecodeModelCacheMirror cache,
        CodecModelCacheKeyMirror key,
        string identity,
        int length,
        Dictionary<string, int> calls)
    {
        return await cache.GetOrAddAsync(
            key,
            _ =>
            {
                calls.TryGetValue(identity, out var count);
                calls[identity] = count + 1;
                return Task.FromResult(Success(
                    "model-" + identity.ToLowerInvariant(),
                    length,
                    identity[0]));
            },
            CancellationToken.None);
    }

    private static DecodeAttemptMirror Success(
        string identity,
        int length,
        int value) =>
        DecodeAttemptMirror.Succeeded(
            DecodeModelValueMirror.Create(identity, Bytes(length, value)));

    private static byte[] Bytes(int length, int value) =>
        Enumerable.Repeat((byte)value, length).ToArray();

    private static TaskCompletionSource Gate() =>
        new(TaskCreationOptions.RunContinuationsAsynchronously);

    private sealed record CacheKeysMirror(
        CodecModelCacheKeyMirror A,
        CodecModelCacheKeyMirror B,
        CodecModelCacheKeyMirror C);

    private sealed record CacheAggregateMirror(
        int FixtureKeys,
        int SingleFlightCallers,
        int CanonicalQueueStarts,
        bool RetentionVectorsClosed,
        bool FailureVectorsClosed);
}

internal sealed class CodecModelCacheKeyMirror : IComparable<CodecModelCacheKeyMirror>
{
    private readonly byte[] _canonicalBytes;
    private readonly byte[] _digest;

    private CodecModelCacheKeyMirror(
        string releaseIdentity,
        ReadOnlyMemory<byte> canonicalBytes,
        ReadOnlyMemory<byte> digest)
    {
        ReleaseIdentity = new string(releaseIdentity.AsSpan());
        _canonicalBytes = canonicalBytes.ToArray();
        _digest = digest.ToArray();
    }

    internal string ReleaseIdentity { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes => _canonicalBytes;
    internal ReadOnlyMemory<byte> Digest => _digest;

    internal static CodecModelCacheKeyMirror Create(
        string releaseIdentity,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        Validate(releaseIdentity, canonicalBytes);
        return new CodecModelCacheKeyMirror(
            releaseIdentity,
            canonicalBytes,
            SHA256.HashData(canonicalBytes.Span));
    }

    internal static CodecModelCacheKeyMirror CreateCollisionProbe(
        string releaseIdentity,
        ReadOnlyMemory<byte> canonicalBytes,
        ReadOnlyMemory<byte> forcedDigest)
    {
        Validate(releaseIdentity, canonicalBytes);
        if (forcedDigest.Length != 32)
        {
            throw new ArgumentException(
                "Digest must contain exactly 32 bytes.",
                nameof(forcedDigest));
        }
        return new CodecModelCacheKeyMirror(
            releaseIdentity,
            canonicalBytes,
            forcedDigest);
    }

    public int CompareTo(CodecModelCacheKeyMirror? other)
    {
        if (other is null)
        {
            return 1;
        }
        return CompareBytes(_canonicalBytes, other._canonicalBytes);
    }

    internal static int CompareBytes(
        ReadOnlySpan<byte> left,
        ReadOnlySpan<byte> right)
    {
        var shared = Math.Min(left.Length, right.Length);
        for (var index = 0; index < shared; index++)
        {
            var comparison = left[index].CompareTo(right[index]);
            if (comparison != 0)
            {
                return comparison;
            }
        }
        return left.Length.CompareTo(right.Length);
    }

    private static void Validate(
        string releaseIdentity,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        ArgumentException.ThrowIfNullOrEmpty(releaseIdentity);
        if (canonicalBytes.IsEmpty)
        {
            throw new ArgumentException(
                "Canonical bytes cannot be empty.",
                nameof(canonicalBytes));
        }
    }
}

internal sealed class DecodeModelValueMirror
{
    private readonly byte[] _canonicalBytes;

    private DecodeModelValueMirror(
        string identity,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        Identity = new string(identity.AsSpan());
        _canonicalBytes = canonicalBytes.ToArray();
    }

    internal string Identity { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes => _canonicalBytes;

    internal static DecodeModelValueMirror Create(
        string identity,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        ArgumentException.ThrowIfNullOrEmpty(identity);
        if (canonicalBytes.IsEmpty)
        {
            throw new ArgumentException(
                "Canonical bytes cannot be empty.",
                nameof(canonicalBytes));
        }
        return new DecodeModelValueMirror(identity, canonicalBytes);
    }
}

internal sealed class DeclaredDecodeFailureMirror
{
    private readonly byte[] _canonicalBytes;

    private DeclaredDecodeFailureMirror(
        string code,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        Code = new string(code.AsSpan());
        _canonicalBytes = canonicalBytes.ToArray();
    }

    internal string Code { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes => _canonicalBytes;

    internal static DeclaredDecodeFailureMirror Create(
        string code,
        ReadOnlyMemory<byte> canonicalBytes)
    {
        ArgumentException.ThrowIfNullOrEmpty(code);
        if (canonicalBytes.IsEmpty)
        {
            throw new ArgumentException(
                "Canonical bytes cannot be empty.",
                nameof(canonicalBytes));
        }
        return new DeclaredDecodeFailureMirror(code, canonicalBytes);
    }
}

internal abstract class DecodeAttemptMirror
{
    private DecodeAttemptMirror()
    {
    }

    internal static DecodeAttemptMirror Succeeded(DecodeModelValueMirror value) =>
        new SucceededAttempt(
            value ?? throw new ArgumentNullException(nameof(value)));

    internal static DecodeAttemptMirror DeclaredFailure(
        DeclaredDecodeFailureMirror failure) =>
        new DeclaredFailureAttempt(
            failure ?? throw new ArgumentNullException(nameof(failure)));

    internal abstract TResult Accept<TResult>(
        IDecodeAttemptMirrorVisitor<TResult> visitor);

    private sealed class SucceededAttempt : DecodeAttemptMirror
    {
        private readonly DecodeModelValueMirror _value;

        internal SucceededAttempt(DecodeModelValueMirror value)
        {
            _value = value;
        }

        internal override TResult Accept<TResult>(
            IDecodeAttemptMirrorVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitSucceeded(_value);
    }

    private sealed class DeclaredFailureAttempt : DecodeAttemptMirror
    {
        private readonly DeclaredDecodeFailureMirror _failure;

        internal DeclaredFailureAttempt(DeclaredDecodeFailureMirror failure)
        {
            _failure = failure;
        }

        internal override TResult Accept<TResult>(
            IDecodeAttemptMirrorVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitDeclaredFailure(_failure);
    }
}

internal interface IDecodeAttemptMirrorVisitor<TResult>
{
    TResult VisitSucceeded(DecodeModelValueMirror value);
    TResult VisitDeclaredFailure(DeclaredDecodeFailureMirror failure);
}

internal enum DecodeCacheDispositionMirror
{
    Produced,
    Joined,
    Retained,
}

internal sealed class DecodeCacheResultMirror
{
    private DecodeCacheResultMirror(
        DecodeAttemptMirror attempt,
        DecodeCacheDispositionMirror disposition)
    {
        Attempt = attempt;
        Disposition = disposition;
    }

    internal DecodeAttemptMirror Attempt { get; }
    internal DecodeCacheDispositionMirror Disposition { get; }

    internal static DecodeCacheResultMirror Create(
        DecodeAttemptMirror attempt,
        DecodeCacheDispositionMirror disposition) =>
        new(
            attempt ?? throw new ArgumentNullException(nameof(attempt)),
            disposition);
}

internal sealed class DecodeModelCacheMirror
{
    private readonly object _gate = new();
    private readonly string _releaseIdentity;
    private readonly string _sessionIdentity;
    private readonly int _maximumEntries;
    private readonly long _maximumCanonicalBytes;
    private readonly int _maximumConcurrentAttempts;
    private readonly List<WorkItem> _active = [];
    private readonly List<WorkItem> _pending = [];
    private List<RetainedEntry> _retained = [];
    private int _running;

    private DecodeModelCacheMirror(
        string releaseIdentity,
        string sessionIdentity,
        int maximumEntries,
        long maximumCanonicalBytes,
        int maximumConcurrentAttempts)
    {
        _releaseIdentity = new string(releaseIdentity.AsSpan());
        _sessionIdentity = new string(sessionIdentity.AsSpan());
        _maximumEntries = maximumEntries;
        _maximumCanonicalBytes = maximumCanonicalBytes;
        _maximumConcurrentAttempts = maximumConcurrentAttempts;
    }

    internal static DecodeModelCacheMirror Create(
        string releaseIdentity,
        string sessionIdentity,
        int maximumEntries,
        long maximumCanonicalBytes,
        int maximumConcurrentAttempts)
    {
        ArgumentException.ThrowIfNullOrEmpty(releaseIdentity);
        ArgumentException.ThrowIfNullOrEmpty(sessionIdentity);
        if (maximumEntries < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maximumEntries));
        }
        if (maximumCanonicalBytes < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maximumCanonicalBytes));
        }
        if (maximumConcurrentAttempts <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maximumConcurrentAttempts));
        }
        return new DecodeModelCacheMirror(
            releaseIdentity,
            sessionIdentity,
            maximumEntries,
            maximumCanonicalBytes,
            maximumConcurrentAttempts);
    }

    internal Task<DecodeCacheResultMirror> GetOrAddAsync(
        CodecModelCacheKeyMirror key,
        Func<CancellationToken, Task<DecodeAttemptMirror>> attempt,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(key);
        ArgumentNullException.ThrowIfNull(attempt);
        cancellationToken.ThrowIfCancellationRequested();
        if (!string.Equals(
                key.ReleaseIdentity,
                _releaseIdentity,
                StringComparison.Ordinal))
        {
            throw new DecodeCacheIntegrityMirrorException(
                "protocol.cache.release-identity-mismatch");
        }

        List<WorkItem> starts;
        Task<DecodeCacheResultMirror> result;
        lock (_gate)
        {
            _ = _sessionIdentity.Length;
            RejectDigestCollision(key);
            var retained = _retained.Find(item => EqualKey(item.Key, key));
            if (retained is not null)
            {
                return Task.FromResult(DecodeCacheResultMirror.Create(
                    retained.Attempt,
                    DecodeCacheDispositionMirror.Retained));
            }
            var active = _active.Find(item => EqualKey(item.Key, key));
            if (active is not null)
            {
                return ObserveAsync(
                    active.Completion.Task,
                    DecodeCacheDispositionMirror.Joined);
            }

            var work = new WorkItem(key, attempt, cancellationToken);
            _active.Add(work);
            _pending.Add(work);
            starts = TakeStarts();
            result = ObserveAsync(
                work.Completion.Task,
                DecodeCacheDispositionMirror.Produced);
        }
        Start(starts);
        return result;
    }

    private void RejectDigestCollision(CodecModelCacheKeyMirror key)
    {
        foreach (var candidate in _retained.Select(item => item.Key)
                     .Concat(_active.Select(item => item.Key)))
        {
            if (candidate.Digest.Span.SequenceEqual(key.Digest.Span) &&
                !candidate.CanonicalBytes.Span.SequenceEqual(
                    key.CanonicalBytes.Span))
            {
                throw new DecodeCacheIntegrityMirrorException(
                    "protocol.cache.key-collision");
            }
        }
    }

    private static async Task<DecodeCacheResultMirror> ObserveAsync(
        Task<DecodeAttemptMirror> completion,
        DecodeCacheDispositionMirror disposition)
    {
        var result = await completion.ConfigureAwait(false);
        return DecodeCacheResultMirror.Create(result, disposition);
    }

    private List<WorkItem> TakeStarts()
    {
        var starts = new List<WorkItem>();
        while (_running < _maximumConcurrentAttempts && _pending.Count > 0)
        {
            _pending.Sort((left, right) => left.Key.CompareTo(right.Key));
            var next = _pending[0];
            _pending.RemoveAt(0);
            _running++;
            starts.Add(next);
        }
        return starts;
    }

    private void Start(IEnumerable<WorkItem> starts)
    {
        foreach (var item in starts)
        {
            _ = ExecuteAsync(item);
        }
    }

    private async Task ExecuteAsync(WorkItem item)
    {
        try
        {
            var attempt = await item.Producer(item.Token).ConfigureAwait(false);
            if (attempt is null)
            {
                throw new InvalidOperationException("Decode attempt returned null.");
            }
            Complete(item, attempt);
        }
        catch (Exception error)
        {
            Fail(item, error);
        }
    }

    private void Complete(WorkItem item, DecodeAttemptMirror attempt)
    {
        List<WorkItem> starts;
        lock (_gate)
        {
            var retained = BuildRetainedSnapshot(item.Key, attempt);
            if (!_active.Remove(item))
            {
                throw new DecodeCacheIntegrityMirrorException(
                    "protocol.cache.active-entry-mismatch");
            }
            _running--;
            _retained = retained;
            item.Completion.TrySetResult(attempt);
            starts = TakeStarts();
        }
        Start(starts);
    }

    private void Fail(WorkItem item, Exception error)
    {
        List<WorkItem> starts;
        lock (_gate)
        {
            if (_active.Remove(item))
            {
                _running--;
            }
            item.Completion.TrySetException(error);
            starts = TakeStarts();
        }
        Start(starts);
    }

    private List<RetainedEntry> BuildRetainedSnapshot(
        CodecModelCacheKeyMirror key,
        DecodeAttemptMirror attempt)
    {
        var candidates = new List<RetainedEntry>(_retained)
        {
            new(key, attempt, attempt.Accept(RetentionCostVisitor.Instance)),
        };
        candidates.Sort((left, right) => left.Key.CompareTo(right.Key));
        var next = new List<RetainedEntry>();
        if (_maximumEntries == 0 || _maximumCanonicalBytes == 0)
        {
            return next;
        }
        long total = 0;
        foreach (var candidate in candidates)
        {
            if (next.Count >= _maximumEntries ||
                candidate.CanonicalBytes > _maximumCanonicalBytes)
            {
                continue;
            }
            var proposed = CheckedRetentionCost(total, candidate.CanonicalBytes);
            if (proposed <= _maximumCanonicalBytes)
            {
                next.Add(candidate);
                total = proposed;
            }
        }
        return next;
    }

    private static long CheckedRetentionCost(long current, long addition)
    {
        try
        {
            return checked(current + addition);
        }
        catch (OverflowException)
        {
            throw new DecodeCacheIntegrityMirrorException(
                "protocol.cache.retention-cost-overflow");
        }
    }

    private static bool EqualKey(
        CodecModelCacheKeyMirror left,
        CodecModelCacheKeyMirror right) =>
        left.Digest.Span.SequenceEqual(right.Digest.Span) &&
        left.CanonicalBytes.Span.SequenceEqual(right.CanonicalBytes.Span);

    private sealed class WorkItem
    {
        internal WorkItem(
            CodecModelCacheKeyMirror key,
            Func<CancellationToken, Task<DecodeAttemptMirror>> producer,
            CancellationToken token)
        {
            Key = key;
            Producer = producer;
            Token = token;
            Completion = new TaskCompletionSource<DecodeAttemptMirror>(
                TaskCreationOptions.RunContinuationsAsynchronously);
        }

        internal CodecModelCacheKeyMirror Key { get; }
        internal Func<CancellationToken, Task<DecodeAttemptMirror>> Producer { get; }
        internal CancellationToken Token { get; }
        internal TaskCompletionSource<DecodeAttemptMirror> Completion { get; }
    }

    private sealed record RetainedEntry(
        CodecModelCacheKeyMirror Key,
        DecodeAttemptMirror Attempt,
        long CanonicalBytes);

    private sealed class RetentionCostVisitor : IDecodeAttemptMirrorVisitor<long>
    {
        internal static RetentionCostVisitor Instance { get; } = new();

        private RetentionCostVisitor()
        {
        }

        public long VisitSucceeded(DecodeModelValueMirror value) =>
            value.CanonicalBytes.Length;

        public long VisitDeclaredFailure(DeclaredDecodeFailureMirror failure) =>
            failure.CanonicalBytes.Length;
    }
}

internal sealed class DecodeCacheIntegrityMirrorException : Exception
{
    internal DecodeCacheIntegrityMirrorException(string code)
        : base(ResolveMessage(code))
    {
        ArgumentException.ThrowIfNullOrEmpty(code);
        Code = new string(code.AsSpan());
    }

    internal string Code { get; }

    private static string ResolveMessage(string code) => code switch
    {
        "protocol.cache.key-collision" =>
            "Conflicting decode cache key bytes.",
        "protocol.cache.release-identity-mismatch" =>
            "Decode cache release identity mismatch.",
        "protocol.cache.retention-cost-overflow" =>
            "Decode cache retention cost overflow.",
        "protocol.cache.active-entry-mismatch" =>
            "Decode cache active entry mismatch.",
        _ => "Decode cache integrity failure.",
    };
}
