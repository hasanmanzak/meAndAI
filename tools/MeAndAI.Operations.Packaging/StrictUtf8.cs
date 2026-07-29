using System.Text;

namespace MeAndAI.Operations.Packaging;

internal static class StrictUtf8
{
    private static readonly UTF8Encoding Decoder = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    internal static string Decode(ReadOnlyMemory<byte> bytes)
    {
        try
        {
            return Decoder.GetString(bytes.Span);
        }
        catch (DecoderFallbackException)
        {
            throw new InvalidDataException(
                "Process dependency returned invalid UTF-8 text.");
        }
    }

    internal static bool IsNullOrWhiteSpace(ReadOnlyMemory<byte> bytes) =>
        string.IsNullOrWhiteSpace(Decode(bytes));
}
