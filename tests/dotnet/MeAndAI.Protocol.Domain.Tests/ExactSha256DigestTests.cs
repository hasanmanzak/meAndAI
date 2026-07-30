using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class ExactSha256DigestTests
{
    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DigestAcceptsExactLowercaseHexBoundariesAndUsesOrdinalValueSemantics()
    {
        var zerosText = new string('0', 64);
        var nextText = new string('0', 63) + "1";
        var maximumText = new string('f', 64);
        var zeros = ExactSha256Digest.Parse(zerosText);
        var sameZeros = ExactSha256Digest.Parse(zerosText);
        var next = ExactSha256Digest.Parse(nextText);
        var maximum = ExactSha256Digest.Parse(maximumText);

        Assert.Equal(zerosText, zeros.Value);
        Assert.Equal(zerosText, zeros.ToString());
        Assert.Equal(zeros, sameZeros);
        Assert.True(zeros.Equals((object)sameZeros));
        Assert.Equal(zeros.GetHashCode(), sameZeros.GetHashCode());
        Assert.NotEqual(zeros, maximum);
        Assert.False(zeros.Equals(maximum));
        Assert.False(zeros.Equals((object)maximum));
        Assert.False(zeros.Equals(null));
        Assert.False(zeros.Equals((object)zerosText));
        Assert.Equal(0, zeros.CompareTo(sameZeros));
        Assert.True(zeros.CompareTo(next) < 0);
        Assert.True(maximum.CompareTo(next) > 0);
        Assert.Equal(1, zeros.CompareTo(null));

        Assert.True(ExactSha256Digest.TryParse(maximumText, out var parsedMaximum));
        Assert.Equal(maximum, parsedMaximum);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DigestRejectsNullSeparatelyFromMalformedText()
    {
        Assert.Throws<ArgumentNullException>(() => ExactSha256Digest.Parse(null!));

        Assert.False(ExactSha256Digest.TryParse(null, out var result));
        Assert.Null(result);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DigestRejectsLengthCaseUnicodeHexAndPaddingErrors()
    {
        var invalidValues = new[]
        {
            string.Empty,
            new string('0', 63),
            new string('0', 65),
            new string('A', 64),
            new string('g', 64),
            " " + new string('0', 64),
            new string('0', 64) + " ",
            new string('0', 63) + "é",
        };

        foreach (var value in invalidValues)
        {
            Assert.Throws<FormatException>(() => ExactSha256Digest.Parse(value));
            Assert.False(ExactSha256Digest.TryParse(value, out var result));
            Assert.Null(result);
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void FromHashBytesEncodesExactlyThirtyTwoAlreadyComputedBytes()
    {
        var hashBytes = Enumerable.Range(0, 32).Select(value => (byte)value).ToArray();
        const string expected =
            "000102030405060708090a0b0c0d0e0f" +
            "101112131415161718191a1b1c1d1e1f";

        var digest = ExactSha256Digest.FromHashBytes(hashBytes);
        hashBytes[0] = byte.MaxValue;

        Assert.Equal(expected, digest.Value);
        Assert.Equal(expected, digest.ToString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void FromHashBytesRejectsEveryNonThirtyTwoBoundarySample()
    {
        foreach (var length in new[] { 0, 31, 33 })
        {
            var hashBytes = new byte[length];

            Assert.Throws<ArgumentException>(() =>
                ExactSha256Digest.FromHashBytes(hashBytes));
        }
    }
}
