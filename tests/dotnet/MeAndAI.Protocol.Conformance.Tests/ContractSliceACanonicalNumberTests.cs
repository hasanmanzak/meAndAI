using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceACanonicalNumberTests
{
    private const string BaselineManifest =
        ContractSliceAManifestTests.MinimalCanonicalManifest;

    private static readonly UTF8Encoding StrictUtf8 = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_integer_grammar_and_range()
    {
        var minimumBytes = AsBytes(BaselineManifest);
        var minimum = FinalizedPolicyManifest.ParseCanonical(minimumBytes);
        Assert.Equal(1, minimum.Slice?.CatalogVersion.Value);
        Assert.Equal(1, minimum.SchemaRegistry.CacheBudget.MaxDecodeEntries);
        Assert.Equal(1, minimum.SchemaRegistry.CacheBudget.MaxDecodeCanonicalBytes);
        Assert.Equal(1, minimum.SchemaRegistry.CacheBudget.MaxIndexEntries);
        Assert.Equal(1, minimum.SchemaRegistry.CacheBudget.MaxIndexNodes);
        Assert.Equal(1, minimum.SchemaRegistry.CacheBudget.MaxConcurrentDecodeAttempts);
        Assert.Equal(1, minimum.SchemaRegistry.CacheBudget.MaxConcurrentIndexAttempts);
        Assert.Equal(1, Assert.Single(minimum.ArtifactFiles).ByteLength);

        var boundaryText = ReplaceRequired(
            ReplaceRequired(
                BaselineManifest,
                "\"catalogVersion\":1",
                "\"catalogVersion\":2147483647"),
            "\"maxDecodeCanonicalBytes\":1",
            "\"maxDecodeCanonicalBytes\":9223372036854775807");
        var boundaryBytes = AsBytes(boundaryText);
        var boundary = FinalizedPolicyManifest.ParseCanonical(boundaryBytes);
        Assert.Equal(int.MaxValue, boundary.Slice?.CatalogVersion.Value);
        Assert.Equal(
            long.MaxValue,
            boundary.SchemaRegistry.CacheBudget.MaxDecodeCanonicalBytes);
        Assert.Equal(boundaryBytes, CanonicalManifestWriter.Write(boundary));
        Assert.Equal(
            Convert.ToHexString(SHA256.HashData(boundaryBytes)).ToLowerInvariant(),
            boundary.ManifestDigest.Value);

        var invalidVectors = new (string Name, string OldText, string NewText)[]
        {
            ("int-zero", "\"catalogVersion\":1", "\"catalogVersion\":0"),
            ("int-negative", "\"catalogVersion\":1", "\"catalogVersion\":-1"),
            ("int-negative-zero", "\"catalogVersion\":1", "\"catalogVersion\":-0"),
            ("int-leading-zero", "\"catalogVersion\":1", "\"catalogVersion\":01"),
            ("int-plus-sign", "\"catalogVersion\":1", "\"catalogVersion\":+1"),
            ("int-fraction", "\"catalogVersion\":1", "\"catalogVersion\":1.0"),
            ("int-lower-exponent", "\"catalogVersion\":1", "\"catalogVersion\":1e0"),
            ("int-upper-exponent", "\"catalogVersion\":1", "\"catalogVersion\":1E+0"),
            ("int-one-over", "\"catalogVersion\":1", "\"catalogVersion\":2147483648"),
            ("long-negative", "\"maxDecodeCanonicalBytes\":1", "\"maxDecodeCanonicalBytes\":-1"),
            ("long-negative-zero", "\"maxDecodeCanonicalBytes\":1", "\"maxDecodeCanonicalBytes\":-0"),
            ("long-fraction", "\"maxDecodeCanonicalBytes\":1", "\"maxDecodeCanonicalBytes\":1.0"),
            ("long-exponent", "\"maxDecodeCanonicalBytes\":1", "\"maxDecodeCanonicalBytes\":1e0"),
            ("long-one-over", "\"maxDecodeCanonicalBytes\":1", "\"maxDecodeCanonicalBytes\":9223372036854775808"),
            ("zero-max-decode-entries", "\"maxDecodeEntries\":1", "\"maxDecodeEntries\":0"),
            ("zero-max-decode-bytes", "\"maxDecodeCanonicalBytes\":1", "\"maxDecodeCanonicalBytes\":0"),
            ("zero-max-index-entries", "\"maxIndexEntries\":1", "\"maxIndexEntries\":0"),
            ("zero-max-index-nodes", "\"maxIndexNodes\":1", "\"maxIndexNodes\":0"),
            ("zero-max-decode-attempts", "\"maxConcurrentDecodeAttempts\":1", "\"maxConcurrentDecodeAttempts\":0"),
            ("zero-max-index-attempts", "\"maxConcurrentIndexAttempts\":1", "\"maxConcurrentIndexAttempts\":0"),
            ("zero-artifact-byte-length", "\"byteLength\":1", "\"byteLength\":0"),
        };

        Assert.Equal(
            invalidVectors.Length,
            invalidVectors.Select(vector => vector.Name).Distinct(StringComparer.Ordinal).Count());
        foreach (var vector in invalidVectors)
        {
            var mutated = ReplaceRequired(
                BaselineManifest,
                vector.OldText,
                vector.NewText);
            Assert.NotEqual(BaselineManifest, mutated);
            AssertExactPublicFormatException(vector.Name, mutated);
        }
    }

    private static byte[] AsBytes(string value) =>
        StrictUtf8.GetBytes(value);

    private static string ReplaceRequired(
        string value,
        string oldText,
        string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0)
        {
            throw new InvalidOperationException(
                $"Required numeric fixture marker was not found: {oldText}");
        }

        return value.Remove(index, oldText.Length).Insert(index, newText);
    }

    private static void AssertExactPublicFormatException(
        string vectorName,
        string manifest)
    {
        var exception = Record.Exception(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(AsBytes(manifest));
        });

        Assert.True(
            exception?.GetType() == typeof(FormatException),
            $"Vector '{vectorName}' must produce exact FormatException; " +
            $"actual: {exception?.GetType().FullName ?? "<none>"}.");
    }
}
