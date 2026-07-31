using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceACanonicalStringTests
{
    private const string CanonicalProbeHex =
        "22515C225C5C5C625C665C6E5C725C745C75303031665C75303037665C75303038355C7530303966E38080F0A0AE9F22";

    private const string ExpectedPositiveManifestDigest =
        "5195e1a4b36b8b57a96fbd774fb78c5d46878948f91ee597e66ef6f44821a928";

    private const string OriginalAssemblyNameProperty =
        "\"assemblyName\":\"MeAndAI.Protocol.Conformance.Tests\"";

    private const string PositiveAssemblyName =
        "MeAndAI.Protocol.\u3000Unicode.\U00020B9F.Tests";

    private const string SupplementaryScalar = "\U00020B9F";

    private static readonly UTF8Encoding StrictUtf8 = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_canonical_manifest_string_encoding()
    {
        var actualProbe =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(
                CreateExactProbe());

        AssertBytes(
            Convert.FromHexString(CanonicalProbeHex),
            actualProbe);

        AssertExactQuotedCodecMatrix();
        AssertExactControlMatrix();
        AssertNoNormalization();
        AssertPositiveUnicodeManifest();
        AssertPrintableEscapeAlternativesFail();
        AssertMalformedRawUtf8Fails();
        AssertMalformedEscapedUnicodeFails();
        AssertInternalMalformedUtf16Fails();
    }

    private static string CreateExactProbe() =>
        "Q\"\\\b\f\n\r\t\u001f\u007f\u0085\u009f\u3000\U00020B9F";

    private static void AssertExactQuotedCodecMatrix()
    {
        AssertQuotedHex("\"", "225C2222");
        AssertQuotedHex("\\", "225C5C22");
        AssertQuotedHex("/", "222F22");

        var decoded =
            "MeAndAI.Protocol.Quote\"Backslash\\Slash/Tests";
        var encoded =
            "MeAndAI.Protocol.Quote\\\"Backslash\\\\Slash/Tests";

        AssertAssemblyNameRoundTrip(encoded, decoded);

        AssertRejectedBeforeFactory(
            "MeAndAI.Protocol.Quote\\\"Backslash\\\\Slash\\/Tests");
    }

    private static void AssertExactControlMatrix()
    {
        var namedControls = new (int Scalar, string Escape)[]
        {
            (0x08, "\\b"),
            (0x0C, "\\f"),
            (0x0A, "\\n"),
            (0x0D, "\\r"),
            (0x09, "\\t"),
        };

        foreach (var (scalar, escape) in namedControls)
        {
            AssertQuotedEncoding(scalar, escape);
            AssertFactoryRejected(escape);

            var longLower = CanonicalUnicodeEscape(scalar);
            AssertRejectedBeforeFactory(longLower);

            var longUpper =
                "\\u" + scalar.ToString(
                    "X4",
                    CultureInfo.InvariantCulture);
            if (!string.Equals(
                    longLower,
                    longUpper,
                    StringComparison.Ordinal))
            {
                AssertRejectedBeforeFactory(longUpper);
            }
        }

        for (var scalar = 0x00; scalar <= 0x1F; scalar++)
        {
            if (IsNamedControl(scalar))
            {
                continue;
            }

            var canonicalEscape = CanonicalUnicodeEscape(scalar);

            AssertQuotedEncoding(scalar, canonicalEscape);
            AssertFactoryRejected(canonicalEscape);
            AssertUppercaseAlternativeRejected(
                scalar,
                canonicalEscape);
        }

        for (var scalar = 0x7F; scalar <= 0x9F; scalar++)
        {
            var canonicalEscape = CanonicalUnicodeEscape(scalar);

            AssertQuotedEncoding(scalar, canonicalEscape);
            AssertFactoryRejected(canonicalEscape);
            AssertUppercaseAlternativeRejected(
                scalar,
                canonicalEscape);

            var rawControl = char.ConvertFromUtf32(scalar);
            AssertRejectedBeforeFactory(rawControl);
        }
    }

    private static void AssertUppercaseAlternativeRejected(
        int scalar,
        string canonicalEscape)
    {
        var uppercaseEscape =
            "\\u" + scalar.ToString(
                "X4",
                CultureInfo.InvariantCulture);

        if (!string.Equals(
                canonicalEscape,
                uppercaseEscape,
                StringComparison.Ordinal))
        {
            AssertRejectedBeforeFactory(uppercaseEscape);
        }
    }

    private static bool IsNamedControl(int scalar) =>
        scalar is 0x08 or 0x09 or 0x0A or 0x0C or 0x0D;

    private static string CanonicalUnicodeEscape(int scalar) =>
        "\\u" + scalar.ToString(
            "x4",
            CultureInfo.InvariantCulture);

    private static void AssertQuotedEncoding(
        int scalar,
        string expectedEncodedContent)
    {
        var value = char.ConvertFromUtf32(scalar);
        var expected = StrictUtf8.GetBytes(
            "\"" + expectedEncodedContent + "\"");
        var actual =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(value);

        AssertBytes(expected, actual);
    }

    private static void AssertQuotedHex(
        string value,
        string expectedHex)
    {
        var actual =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(value);

        AssertBytes(Convert.FromHexString(expectedHex), actual);
    }

    private static void AssertNoNormalization()
    {
        var nfc =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(
                "\u00e9");
        var nfd =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(
                "e\u0301");

        AssertBytes(Convert.FromHexString("22C3A922"), nfc);
        AssertBytes(Convert.FromHexString("2265CC8122"), nfd);
        Assert.False(nfc.AsSpan().SequenceEqual(nfd));
    }

    private static void AssertAssemblyNameRoundTrip(
        string encodedAssemblyName,
        string expectedAssemblyName)
    {
        var bytes =
            CreateManifestWithEncodedAssemblyName(encodedAssemblyName);
        var manifest =
            FinalizedPolicyManifest.ParseCanonical(bytes);
        var component = Assert.Single(manifest.Components);

        Assert.Equal(
            expectedAssemblyName,
            component.Component.AssemblyName);
    }

    private static void AssertPositiveUnicodeManifest()
    {
        var canonicalBytes =
            CreateManifestWithEncodedAssemblyName(
                PositiveAssemblyName);

        Assert.Equal(1_226, canonicalBytes.Length);
        Assert.Equal(
            ExpectedPositiveManifestDigest,
            Convert.ToHexString(
                    SHA256.HashData(canonicalBytes))
                .ToLowerInvariant());

        Assert.Equal(
            1,
            CountOccurrences(
                canonicalBytes,
                Convert.FromHexString("E38080")));
        Assert.Equal(
            1,
            CountOccurrences(
                canonicalBytes,
                Convert.FromHexString("F0A0AE9F")));

        Assert.Equal(
            0,
            CountOccurrences(
                canonicalBytes,
                StrictUtf8.GetBytes("\\u3000")));
        Assert.Equal(
            0,
            CountOccurrences(
                canonicalBytes,
                StrictUtf8.GetBytes("\\ud842")));
        Assert.Equal(
            0,
            CountOccurrences(
                canonicalBytes,
                StrictUtf8.GetBytes("\\uD842")));
        Assert.Equal(
            0,
            CountOccurrences(
                canonicalBytes,
                StrictUtf8.GetBytes("\\udf9f")));
        Assert.Equal(
            0,
            CountOccurrences(
                canonicalBytes,
                StrictUtf8.GetBytes("\\uDF9F")));

        var manifest =
            FinalizedPolicyManifest.ParseCanonical(canonicalBytes);

        Array.Fill(canonicalBytes, byte.MaxValue);

        Assert.Equal(
            ExpectedPositiveManifestDigest,
            manifest.ManifestDigest.Value);

        var component = Assert.Single(manifest.Components);
        var artifact = Assert.Single(manifest.ArtifactFiles);

        Assert.Equal(
            PositiveAssemblyName,
            component.Component.AssemblyName);
        Assert.Equal(
            PositiveAssemblyName,
            manifest
                .ActivationProofContract
                .ProofComponent
                .AssemblyName);
        Assert.Equal(
            artifact.FileName,
            component.ArtifactFileName);
        Assert.Equal(
            "ContractSliceA.Proof.dll",
            component.ArtifactFileName);
    }

    private static void AssertPrintableEscapeAlternativesFail()
    {
        var escapedIdeographicSpace =
            PositiveAssemblyName.Replace(
                "\u3000",
                "\\u3000",
                StringComparison.Ordinal);
        var escapedLowerSurrogatePair =
            PositiveAssemblyName.Replace(
                SupplementaryScalar,
                "\\ud842\\udf9f",
                StringComparison.Ordinal);
        var escapedUpperSurrogatePair =
            PositiveAssemblyName.Replace(
                SupplementaryScalar,
                "\\uD842\\uDF9F",
                StringComparison.Ordinal);

        AssertPublicFormatException(
            CreateManifestWithEncodedAssemblyName(
                escapedIdeographicSpace));
        AssertPublicFormatException(
            CreateManifestWithEncodedAssemblyName(
                escapedLowerSurrogatePair));
        AssertPublicFormatException(
            CreateManifestWithEncodedAssemblyName(
                escapedUpperSurrogatePair));
    }

    private static void AssertFactoryRejected(
        string encodedControl)
    {
        var encodedAssemblyName =
            BuildEncodedControlCarrier(encodedControl);
        var exception = AssertPublicFormatException(
            CreateManifestWithEncodedAssemblyName(
                encodedAssemblyName));

        Assert.NotNull(exception.InnerException);
        Assert.IsType<ArgumentException>(
            exception.InnerException!);
    }

    private static void AssertRejectedBeforeFactory(
        string encodedValueOrFragment)
    {
        var encodedAssemblyName =
            encodedValueOrFragment.StartsWith(
                "MeAndAI.Protocol.",
                StringComparison.Ordinal)
                ? encodedValueOrFragment
                : BuildEncodedControlCarrier(
                    encodedValueOrFragment);

        var exception = AssertPublicFormatException(
            CreateManifestWithEncodedAssemblyName(
                encodedAssemblyName));

        Assert.False(
            exception.InnerException is ArgumentException);
    }

    private static string BuildEncodedControlCarrier(
        string encodedControl) =>
        "MeAndAI.Protocol.X" +
        encodedControl +
        "Y.Tests";

    private static void AssertMalformedRawUtf8Fails()
    {
        var malformedValues = new byte[][]
        {
            new byte[] { 0x80 },
            new byte[] { 0xC0, 0xAF },
            new byte[] { 0xED, 0xA0, 0x80 },
            new byte[] { 0xF0, 0xA0, 0xAE },
            new byte[] { 0xF4, 0x90, 0x80, 0x80 },
        };

        foreach (var malformedValue in malformedValues)
        {
            var encodedAssemblyName = ConcatBytes(
                StrictUtf8.GetBytes("MeAndAI.Protocol.X"),
                malformedValue,
                StrictUtf8.GetBytes("Y.Tests"));

            AssertPublicFormatException(
                CreateManifestWithEncodedAssemblyName(
                    encodedAssemblyName));
        }
    }

    private static void AssertMalformedEscapedUnicodeFails()
    {
        var malformedEscapes = new[]
        {
            "\\ud842",
            "\\udf9f",
            "\\udf9f\\ud842",
            "\\ud842Z",
        };

        foreach (var malformedEscape in malformedEscapes)
        {
            AssertPublicFormatException(
                CreateManifestWithEncodedAssemblyName(
                    BuildEncodedControlCarrier(
                        malformedEscape)));
        }
    }

    private static void AssertInternalMalformedUtf16Fails()
    {
        var malformedValues = new[]
        {
            new string((char)0xD842, 1),
            new string((char)0xDF9F, 1),
            new string(
                new[]
                {
                    (char)0xDF9F,
                    (char)0xD842,
                }),
        };

        foreach (var malformedValue in malformedValues)
        {
            Assert.Throws<ArgumentException>(() =>
            {
                _ =
                    CanonicalManifestQuotedUtf8Codec
                        .EncodeQuotedUtf8(malformedValue);
            });
        }
    }

    private static FormatException AssertPublicFormatException(
        byte[] canonicalBytes) =>
        Assert.Throws<FormatException>(() =>
        {
            _ =
                FinalizedPolicyManifest.ParseCanonical(
                    canonicalBytes);
        });

    private static byte[] CreateManifestWithEncodedAssemblyName(
        string encodedAssemblyName) =>
        CreateManifestWithEncodedAssemblyName(
            StrictUtf8.GetBytes(encodedAssemblyName));

    private static byte[] CreateManifestWithEncodedAssemblyName(
        byte[] encodedAssemblyName)
    {
        var source =
            StrictUtf8.GetBytes(
                ContractSliceAManifestTests.MinimalCanonicalManifest);
        var originalProperty =
            StrictUtf8.GetBytes(OriginalAssemblyNameProperty);
        var replacementProperty = ConcatBytes(
            StrictUtf8.GetBytes("\"assemblyName\":\""),
            encodedAssemblyName,
            new[] { (byte)'"' });

        return ReplaceExactlyOnce(
            source,
            originalProperty,
            replacementProperty);
    }

    private static byte[] ReplaceExactlyOnce(
        byte[] source,
        byte[] oldValue,
        byte[] newValue)
    {
        var index = source.AsSpan().IndexOf(oldValue);
        if (index < 0)
        {
            throw new InvalidOperationException(
                "The assembly-name fixture target is absent.");
        }

        var trailingStart = index + oldValue.Length;
        if (source
            .AsSpan(trailingStart)
            .IndexOf(oldValue) >= 0)
        {
            throw new InvalidOperationException(
                "The assembly-name fixture target is duplicated.");
        }

        var result = new byte[
            source.Length - oldValue.Length + newValue.Length];

        source
            .AsSpan(0, index)
            .CopyTo(result);
        newValue
            .AsSpan()
            .CopyTo(result.AsSpan(index));
        source
            .AsSpan(trailingStart)
            .CopyTo(result.AsSpan(index + newValue.Length));

        return result;
    }

    private static byte[] ConcatBytes(params byte[][] values)
    {
        var length = 0;
        foreach (var value in values)
        {
            length = checked(length + value.Length);
        }

        var result = new byte[length];
        var offset = 0;

        foreach (var value in values)
        {
            value
                .AsSpan()
                .CopyTo(result.AsSpan(offset));
            offset += value.Length;
        }

        return result;
    }

    private static int CountOccurrences(
        byte[] source,
        byte[] value)
    {
        if (value.Length == 0)
        {
            throw new ArgumentException(
                "The searched byte sequence must not be empty.",
                nameof(value));
        }

        var count = 0;
        var offset = 0;

        while (offset <= source.Length - value.Length)
        {
            var relativeIndex =
                source.AsSpan(offset).IndexOf(value);
            if (relativeIndex < 0)
            {
                break;
            }

            count++;
            offset += relativeIndex + value.Length;
        }

        return count;
    }

    private static void AssertBytes(
        byte[] expected,
        byte[]? actual)
    {
        Assert.NotNull(actual);
        Assert.Equal(
            Convert.ToHexString(expected),
            Convert.ToHexString(actual!));
    }
}
