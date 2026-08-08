using System.Buffers;
using System.Text;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class CanonicalManifestQuotedUtf8Codec
{
    internal static byte[] EncodeQuotedUtf8(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        var result = GC.AllocateUninitializedArray<byte>(
            GetEncodedByteLength(value));
        var offset = 0;
        result[offset++] = (byte)'"';

        var remaining = value.AsSpan();
        while (!remaining.IsEmpty)
        {
            var rune = DecodeNext(
                remaining,
                out var charsConsumed,
                nameof(value));
            var shortEscape = GetShortEscape(rune.Value);
            if (shortEscape != 0)
            {
                result[offset++] = (byte)'\\';
                result[offset++] = shortEscape;
            }
            else if (RequiresUnicodeEscape(rune.Value))
            {
                result[offset++] = (byte)'\\';
                result[offset++] = (byte)'u';
                result[offset++] = (byte)'0';
                result[offset++] = (byte)'0';
                result[offset++] = LowerHexDigit(rune.Value >> 4);
                result[offset++] = LowerHexDigit(rune.Value);
            }
            else
            {
                offset += rune.EncodeToUtf8(
                    result.AsSpan(offset, rune.Utf8SequenceLength));
            }

            remaining = remaining[charsConsumed..];
        }

        result[offset] = (byte)'"';
        return result;
    }

    private static int GetEncodedByteLength(string value)
    {
        var byteLength = 2;
        var remaining = value.AsSpan();
        while (!remaining.IsEmpty)
        {
            var rune = DecodeNext(
                remaining,
                out var charsConsumed,
                nameof(value));
            var encodedLength = GetShortEscape(rune.Value) != 0
                ? 2
                : RequiresUnicodeEscape(rune.Value)
                    ? 6
                    : rune.Utf8SequenceLength;
            byteLength = checked(byteLength + encodedLength);
            remaining = remaining[charsConsumed..];
        }

        return byteLength;
    }

    private static Rune DecodeNext(
        ReadOnlySpan<char> source,
        out int charsConsumed,
        string parameterName)
    {
        if (Rune.DecodeFromUtf16(
                source,
                out var rune,
                out charsConsumed) != OperationStatus.Done)
        {
            throw new ArgumentException(
                "The value contains invalid UTF-16.",
                parameterName);
        }

        return rune;
    }

    private static byte GetShortEscape(int value) => value switch
    {
        '"' => (byte)'"',
        '\\' => (byte)'\\',
        '\b' => (byte)'b',
        '\f' => (byte)'f',
        '\n' => (byte)'n',
        '\r' => (byte)'r',
        '\t' => (byte)'t',
        _ => 0,
    };

    private static bool RequiresUnicodeEscape(int value) =>
        value <= 0x1F || value is >= 0x7F and <= 0x9F;

    private static byte LowerHexDigit(int value)
    {
        var digit = value & 0x0F;
        return (byte)(digit < 10
            ? '0' + digit
            : 'a' + digit - 10);
    }
}
