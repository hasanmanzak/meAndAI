using System.Globalization;
using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class RuleIdentityTests
{
    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void RuleIdAcceptsBoundariesAndSyntacticallyValidUncataloguedIds()
    {
        var minimum = RuleId.Parse("RULE-0001");
        var sameMinimum = RuleId.Parse("RULE-0001");
        var uncatalogued = RuleId.Parse("RULE-4321");
        var maximum = RuleId.Parse("RULE-9999");

        Assert.Equal("RULE-0001", minimum.Value);
        Assert.Equal("RULE-0001", minimum.ToString());
        Assert.Equal("RULE-4321", uncatalogued.Value);
        Assert.Equal(minimum, sameMinimum);
        Assert.True(minimum.Equals((object)sameMinimum));
        Assert.Equal(minimum.GetHashCode(), sameMinimum.GetHashCode());
        Assert.NotEqual(minimum, maximum);
        Assert.False(minimum.Equals(maximum));
        Assert.False(minimum.Equals((object)maximum));
        Assert.False(minimum.Equals(null));
        Assert.False(minimum.Equals((object)"RULE-0001"));
        Assert.Equal(0, minimum.CompareTo(sameMinimum));
        Assert.True(minimum.CompareTo(uncatalogued) < 0);
        Assert.True(maximum.CompareTo(uncatalogued) > 0);
        Assert.Equal(1, minimum.CompareTo(null));

        Assert.True(RuleId.TryParse("RULE-9999", out var parsedMaximum));
        Assert.Equal(maximum, parsedMaximum);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void RuleIdRejectsNullSeparatelyFromMalformedInput()
    {
        Assert.Throws<ArgumentNullException>(() => RuleId.Parse(null!));

        Assert.False(RuleId.TryParse(null, out var result));
        Assert.Null(result);
    }

    [Theory]
    [InlineData("")]
    [InlineData("RULE-0000")]
    [InlineData("RULE-10000")]
    [InlineData("RULE-001")]
    [InlineData("RULE-00001")]
    [InlineData("RULE_0001")]
    [InlineData("rule-0001")]
    [InlineData(" RULE-0001")]
    [InlineData("RULE-0001 ")]
    [InlineData("RULE-٠٠٠١")]
    [InlineData("RULÉ-0001")]
    [Trait("Scenario", "TEST-0220")]
    public void RuleIdRejectsMalformedRangeCaseUnicodeAndPadding(string value)
    {
        Assert.Throws<FormatException>(() => RuleId.Parse(value));

        Assert.False(RuleId.TryParse(value, out var result));
        Assert.Null(result);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void RuleRevisionAcceptsPositiveBoundariesAndOrdersNumerically()
    {
        var minimum = RuleRevision.Create(1);
        var sameMinimum = RuleRevision.Create(1);
        var two = RuleRevision.Create(2);
        var ten = RuleRevision.Create(10);
        var maximum = RuleRevision.Create(int.MaxValue);

        Assert.Equal(1, minimum.Value);
        Assert.Equal("1", minimum.ToString());
        Assert.Equal(int.MaxValue, maximum.Value);
        Assert.Equal("2147483647", maximum.ToString());
        Assert.Equal(minimum, sameMinimum);
        Assert.True(minimum.Equals((object)sameMinimum));
        Assert.Equal(minimum.GetHashCode(), sameMinimum.GetHashCode());
        Assert.NotEqual(minimum, maximum);
        Assert.False(minimum.Equals(maximum));
        Assert.False(minimum.Equals((object)maximum));
        Assert.False(minimum.Equals(null));
        Assert.False(minimum.Equals((object)1));
        Assert.Equal(0, minimum.CompareTo(sameMinimum));
        Assert.True(two.CompareTo(ten) < 0);
        Assert.True(maximum.CompareTo(ten) > 0);
        Assert.Equal(1, minimum.CompareTo(null));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(int.MinValue)]
    [Trait("Scenario", "TEST-0220")]
    public void RuleRevisionRejectsNonPositiveValues(int value)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => RuleRevision.Create(value));
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void RuleRevisionFormatsInvariantAsciiDecimal()
    {
        var originalCulture = CultureInfo.CurrentCulture;

        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR");

            var revision = RuleRevision.Create(12345);

            Assert.Equal("12345", revision.ToString());
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
        }
    }
}
