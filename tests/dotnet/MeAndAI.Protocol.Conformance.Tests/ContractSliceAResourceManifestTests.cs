using System.Runtime.CompilerServices;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

internal static class ContractSliceATestCollections
{
    internal const string ResourceManifest = "ContractSliceA.ResourceManifest";
}

[CollectionDefinition(
    ContractSliceATestCollections.ResourceManifest,
    DisableParallelization = true)]
public sealed class ContractSliceAResourceManifestCollection
{
}

[Collection(ContractSliceATestCollections.ResourceManifest)]
public sealed class ContractSliceAResourceManifestTests
{
    private const int MaximumBytes = 16_777_216;
    private const int MaximumTokens = 1_000_000;
    private const int MaximumDepth = 9;
    private const int MaximumAliasLength = 128;
    private const int AliasPrefixLength = 8;
    private const string GreenDepthMessage = "The policy manifest is not canonical JSON.";
    private const string ByteMessage = "The canonical policy manifest exceeds the byte ceiling.";
    private const string TokenMessage = "The policy manifest exceeds the JSON token ceiling.";

    private static ReadOnlySpan<byte> Rule0001 => "\"ruleId\":\"RULE-0001\""u8;

    private static ReadOnlySpan<byte> EmptyAliases => "\"compatibilityAliases\":[]"u8;

    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_manifest_byte_reachable_depth_and_token_ceilings()
    {
        var basis = CanonicalManifestWriter.Write(
            ContractSliceAFullManifestGraphTests.CreateManifest());

        Assert.Equal(MaximumBytes, CanonicalManifestReader.MaximumByteLength);
        Assert.Equal((byte)'\n', basis[^1]);
        Assert.Equal(MaximumDepth, MaximumContainerDepth(basis));

        AssertByteEquality(basis);
        AssertByteOneOver(basis);
        AssertTokenEquality(basis);
        AssertTokenOneOver(basis);
        AssertDepthOneOver(basis);
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    private static void AssertByteEquality(byte[] basis)
    {
        var carrier = CreateSizedByteCarrier(basis, MaximumBytes);
        Assert.Equal(MaximumBytes, carrier.Length);
        Assert.True(CountTokens(carrier) < MaximumTokens);
        _ = FinalizedPolicyManifest.ParseCanonical(carrier);
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    private static void AssertByteOneOver(byte[] basis)
    {
        var carrier = CreateSizedByteCarrier(basis, MaximumBytes + 1);
        Assert.True(CountTokens(carrier) < MaximumTokens);

        var exception = CaptureFormatException(carrier);
        Assert.Equal(ByteMessage, exception.Message);
        Assert.Null(exception.InnerException);
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    private static void AssertTokenEquality(byte[] basis)
    {
        var carrier = CreateTokenCarrier(basis, MaximumTokens);
        Assert.True(carrier.Length < MaximumBytes);
        Assert.Equal(MaximumTokens, CountTokens(carrier));
        _ = FinalizedPolicyManifest.ParseCanonical(carrier);
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    private static void AssertTokenOneOver(byte[] basis)
    {
        var carrier = CreateTokenCarrier(basis, MaximumTokens + 1);
        Assert.True(carrier.Length < MaximumBytes);
        Assert.Equal(MaximumTokens + 1, CountTokens(carrier));

        var exception = CaptureFormatException(carrier);
        Assert.Equal(TokenMessage, exception.Message);
        Assert.Null(exception.InnerException);
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    private static void AssertDepthOneOver(byte[] basis)
    {
        _ = FinalizedPolicyManifest.ParseCanonical(basis);
        var carrier = CreateDepthOneOverCarrier(basis);
        Assert.Equal(MaximumDepth + 1, MaximumContainerDepth(carrier));
        Assert.True(carrier.Length < MaximumBytes);
        Assert.True(CountTokens(carrier) < MaximumTokens);

        var exception = CaptureFormatException(carrier);
        Assert.Equal(GreenDepthMessage, exception.Message);
        Assert.IsAssignableFrom<JsonException>(exception.InnerException);
    }

    private static byte[] CreateSizedByteCarrier(
        ReadOnlySpan<byte> basis,
        int targetLength)
    {
        var arrayOffset = FindRule0001AliasArray(basis);
        var arrayLength = checked(targetLength - (basis.Length - 2));
        var aliasCount = checked((arrayLength - 1 + 130) / 131);
        var deficit = checked(1 + (131 * aliasCount) - arrayLength);
        Assert.True(aliasCount >= 2);
        Assert.InRange(deficit, 0, 130);

        var result = GC.AllocateUninitializedArray<byte>(targetLength);
        basis[..arrayOffset].CopyTo(result);
        WriteSizedAliasArray(
            result.AsSpan(arrayOffset, arrayLength),
            aliasCount,
            deficit);
        basis[(arrayOffset + 2)..].CopyTo(
            result.AsSpan(arrayOffset + arrayLength));
        Assert.Equal((byte)'\n', result[^1]);
        return result;
    }

    private static byte[] CreateTokenCarrier(
        ReadOnlySpan<byte> basis,
        int targetTokenCount)
    {
        var aliasCount = checked(targetTokenCount - CountTokens(basis));
        Assert.InRange(aliasCount, 1, 1_000_000);
        var arrayLength = checked(1 + (11 * aliasCount));
        var arrayOffset = FindRule0001AliasArray(basis);
        var result = GC.AllocateUninitializedArray<byte>(
            checked(basis.Length - 2 + arrayLength));

        basis[..arrayOffset].CopyTo(result);
        WriteFixedAliasArray(
            result.AsSpan(arrayOffset, arrayLength),
            aliasCount);
        basis[(arrayOffset + 2)..].CopyTo(
            result.AsSpan(arrayOffset + arrayLength));
        Assert.Equal((byte)'\n', result[^1]);
        return result;
    }

    private static byte[] CreateDepthOneOverCarrier(ReadOnlySpan<byte> basis)
    {
        var scalar = FindDeepestComponentKeyScalar(basis);
        ReadOnlySpan<byte> prefix = "{\"componentKey\":"u8;
        ReadOnlySpan<byte> suffix = ",\"componentVersion\":\"1\"}"u8;
        var result = GC.AllocateUninitializedArray<byte>(
            checked(basis.Length + prefix.Length + suffix.Length));
        var cursor = 0;

        basis[..scalar.Offset].CopyTo(result);
        cursor += scalar.Offset;
        prefix.CopyTo(result.AsSpan(cursor));
        cursor += prefix.Length;
        basis.Slice(scalar.Offset, scalar.Length).CopyTo(result.AsSpan(cursor));
        cursor += scalar.Length;
        suffix.CopyTo(result.AsSpan(cursor));
        cursor += suffix.Length;
        basis[(scalar.Offset + scalar.Length)..].CopyTo(result.AsSpan(cursor));
        Assert.Equal((byte)'\n', result[^1]);
        return result;
    }

    private static int FindRule0001AliasArray(ReadOnlySpan<byte> basis)
    {
        Assert.Equal(1, CountOccurrences(basis, Rule0001));
        var ruleOffset = basis.IndexOf(Rule0001);
        Assert.True(ruleOffset >= 0);
        var propertyOffset = basis[ruleOffset..].IndexOf(EmptyAliases);
        Assert.True(propertyOffset >= 0);
        var arrayOffset = checked(
            ruleOffset + propertyOffset + EmptyAliases.Length - 2);
        Assert.Equal((byte)'[', basis[arrayOffset]);
        Assert.Equal((byte)']', basis[arrayOffset + 1]);
        return arrayOffset;
    }

    private static void WriteSizedAliasArray(
        Span<byte> target,
        int aliasCount,
        int deficit)
    {
        var cursor = 0;
        target[cursor++] = (byte)'[';
        for (var ordinal = 0; ordinal < aliasCount; ordinal++)
        {
            if (ordinal > 0)
            {
                target[cursor++] = (byte)',';
            }

            var reduction = ordinal == aliasCount - 1
                ? Math.Min(deficit, MaximumAliasLength - AliasPrefixLength)
                : ordinal == aliasCount - 2
                    ? Math.Max(
                        deficit - (MaximumAliasLength - AliasPrefixLength),
                        0)
                    : 0;
            var aliasLength = MaximumAliasLength - reduction;
            target[cursor++] = (byte)'\"';
            WriteAlias(target.Slice(cursor, aliasLength), ordinal);
            cursor += aliasLength;
            target[cursor++] = (byte)'\"';
        }

        target[cursor++] = (byte)']';
        Assert.Equal(target.Length, cursor);
    }

    private static void WriteFixedAliasArray(
        Span<byte> target,
        int aliasCount)
    {
        var cursor = 0;
        target[cursor++] = (byte)'[';
        for (var ordinal = 0; ordinal < aliasCount; ordinal++)
        {
            if (ordinal > 0)
            {
                target[cursor++] = (byte)',';
            }

            target[cursor++] = (byte)'\"';
            WriteAlias(target.Slice(cursor, AliasPrefixLength), ordinal);
            cursor += AliasPrefixLength;
            target[cursor++] = (byte)'\"';
        }

        target[cursor++] = (byte)']';
        Assert.Equal(target.Length, cursor);
    }

    private static void WriteAlias(Span<byte> target, int ordinal)
    {
        Assert.InRange(target.Length, AliasPrefixLength, MaximumAliasLength);
        target[0] = (byte)'a';
        target[1] = (byte)'.';
        var remaining = ordinal;
        for (var index = AliasPrefixLength - 1; index >= 2; index--)
        {
            target[index] = (byte)('0' + (remaining % 10));
            remaining /= 10;
        }

        Assert.Equal(0, remaining);
        target[AliasPrefixLength..].Fill((byte)'a');
    }

    private static int CountTokens(ReadOnlySpan<byte> canonicalBytes)
    {
        Assert.Equal((byte)'\n', canonicalBytes[^1]);
        var reader = new Utf8JsonReader(
            canonicalBytes[..^1],
            new JsonReaderOptions
            {
                AllowTrailingCommas = false,
                CommentHandling = JsonCommentHandling.Disallow,
                MaxDepth = 64,
            });
        var count = 0;
        while (reader.Read())
        {
            count = checked(count + 1);
        }

        return count;
    }

    private static int MaximumContainerDepth(ReadOnlySpan<byte> canonicalBytes)
    {
        Assert.Equal((byte)'\n', canonicalBytes[^1]);
        var reader = new Utf8JsonReader(
            canonicalBytes[..^1],
            new JsonReaderOptions
            {
                AllowTrailingCommas = false,
                CommentHandling = JsonCommentHandling.Disallow,
                MaxDepth = 64,
            });
        var depth = 0;
        var maximum = 0;
        while (reader.Read())
        {
            if (reader.TokenType is JsonTokenType.StartObject or JsonTokenType.StartArray)
            {
                depth = checked(depth + 1);
                maximum = Math.Max(maximum, depth);
            }
            else if (reader.TokenType is JsonTokenType.EndObject or JsonTokenType.EndArray)
            {
                depth--;
            }
        }

        Assert.Equal(0, depth);
        return maximum;
    }

    private static ScalarRange FindDeepestComponentKeyScalar(
        ReadOnlySpan<byte> canonicalBytes)
    {
        Assert.Equal((byte)'\n', canonicalBytes[^1]);
        var reader = new Utf8JsonReader(
            canonicalBytes[..^1],
            new JsonReaderOptions
            {
                AllowTrailingCommas = false,
                CommentHandling = JsonCommentHandling.Disallow,
                MaxDepth = 64,
            });
        var depth = 0;
        var candidate = default(ScalarRange);
        string? candidateValue = null;
        while (reader.Read())
        {
            if (reader.TokenType is JsonTokenType.StartObject or JsonTokenType.StartArray)
            {
                depth = checked(depth + 1);
                continue;
            }

            if (reader.TokenType is JsonTokenType.EndObject or JsonTokenType.EndArray)
            {
                depth--;
                continue;
            }

            if (reader.TokenType != JsonTokenType.PropertyName ||
                !reader.ValueTextEquals("componentKey") ||
                depth <= candidate.Depth)
            {
                continue;
            }

            Assert.True(reader.Read());
            Assert.Equal(JsonTokenType.String, reader.TokenType);
            Assert.False(reader.HasValueSequence);
            candidate = new ScalarRange(
                checked((int)reader.TokenStartIndex),
                checked((int)(reader.BytesConsumed - reader.TokenStartIndex)),
                depth);
            candidateValue = reader.GetString();
        }

        Assert.Equal(0, depth);
        Assert.Equal(MaximumDepth, candidate.Depth);
        Assert.StartsWith(
            "protocol.type.capability.",
            Assert.IsType<string>(candidateValue),
            StringComparison.Ordinal);
        return candidate;
    }

    private static FormatException CaptureFormatException(byte[] carrier) =>
        Assert.Throws<FormatException>(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(carrier);
        });

    private static int CountOccurrences(
        ReadOnlySpan<byte> source,
        ReadOnlySpan<byte> value)
    {
        var count = 0;
        while (true)
        {
            var index = source.IndexOf(value);
            if (index < 0)
            {
                return count;
            }

            count = checked(count + 1);
            source = source[(index + value.Length)..];
        }
    }

    private readonly record struct ScalarRange(
        int Offset,
        int Length,
        int Depth);
}
