using System.Text;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceACanonicalNumberTests
{
    private static readonly UTF8Encoding StrictUtf8 = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_integer_grammar_and_range()
    {
        var baseline = StrictUtf8.GetBytes(
            ContractSliceAManifestTests.MinimalCanonicalManifest);
        _ = FinalizedPolicyManifest.ParseCanonical(baseline);

        AssertPublicFormatException(
            ReplaceFirst(
                ContractSliceAManifestTests.MinimalCanonicalManifest,
                "\"catalogVersion\":1",
                "\"catalogVersion\":-1"));
        AssertPublicFormatException(
            ReplaceFirst(
                ContractSliceAManifestTests.MinimalCanonicalManifest,
                "\"catalogVersion\":1",
                "\"catalogVersion\":01"));
        AssertPublicFormatException(
            ReplaceFirst(
                ContractSliceAManifestTests.MinimalCanonicalManifest,
                "\"catalogVersion\":1",
                "\"catalogVersion\":2147483648"));
        AssertPublicFormatException(
            ReplaceFirst(
                ContractSliceAManifestTests.MinimalCanonicalManifest,
                "\"maxDecodeCanonicalBytes\":1",
                "\"maxDecodeCanonicalBytes\":18446744073709551616"));
        AssertPublicFormatException(
            ReplaceFirst(
                ContractSliceAManifestTests.MinimalCanonicalManifest,
                "\"maxDecodeEntries\":1",
                "\"maxDecodeEntries\":1.0"));
    }

    private static string ReplaceFirst(
        string value,
        string oldText,
        string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0)
        {
            return value;
        }

        return value.Remove(index, oldText.Length)
            .Insert(index, newText);
    }

    private static void AssertPublicFormatException(string manifest) =>
        Assert.Throws<FormatException>(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(
                StrictUtf8.GetBytes(manifest));
        });
}
