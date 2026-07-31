using System.Text;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceACanonicalJsonGrammarTests
{
    private const string BaselineManifest =
        ContractSliceAManifestTests.MinimalCanonicalManifest;

    private const string ZeroCommit =
        "0000000000000000000000000000000000000001";

    private static readonly byte[] Utf8Bom =
    [
        0xEF,
        0xBB,
        0xBF
    ];

    private static readonly UTF8Encoding StrictUtf8 = new(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_document_and_slice_structural_grammar()
    {
        var baselineBytes = StrictUtf8.GetBytes(BaselineManifest);
        var manifest = FinalizedPolicyManifest.ParseCanonical(baselineBytes);

        Assert.Equal(CatalogAuthorityKind.QualificationSlice, manifest.AuthorityKind);
        Assert.Equal("protocol.catalog-slice.test-empty", manifest.Slice?.SliceKey);

        AssertPublicFormatException(Array.Empty<byte>());
        AssertPublicFormatException(Prepend(Utf8Bom, baselineBytes));
        AssertPublicFormatException(
            AsBytes(BaselineManifest[..^1]));
        AssertPublicFormatException(
            AsBytes(BaselineManifest + "\n"));
        AssertPublicFormatException(
            AsBytes(BaselineManifest[..^2]));

        AssertPublicFormatException(
            ReplaceFirst(
                BaselineManifest,
                "\"authorityKind\":\"qualification-slice\"",
                "\"authoritykind\":\"qualification-slice\""));
        AssertPublicFormatException(
            ReplaceFirst(
                BaselineManifest,
                "\"sourceCommit\":\"" + ZeroCommit + "\"",
                "\"sourceCommit\":null"));
        AssertPublicFormatException(
            ReplaceFirst(
                BaselineManifest,
                "\"catalogVersion\":1",
                "\"catalogVersion\":01"));
        AssertPublicFormatException(
            ReplaceFirst(
                BaselineManifest,
                "\"maxDecodeEntries\":1",
                "\"maxDecodeEntries\":01"));
        AssertPublicFormatException(
            AsBytes(
                BaselineManifest.Insert(
                BaselineManifest.IndexOf("\",\"authorityKind", StringComparison.Ordinal),
                "/*comment*/")));
        AssertPublicFormatException(
            InsertDuplicateSourceCommit(BaselineManifest));
        AssertPublicFormatException(
            ReplaceFirst(
                BaselineManifest,
                "\"sourceCommit\":\"" + ZeroCommit + "\",\"protocolVersion\":\"0.0.0\"",
                "\"protocolVersion\":\"0.0.0\",\"sourceCommit\":\"" + ZeroCommit + "\""));
        AssertPublicFormatException(
            ReplaceFirst(
                BaselineManifest,
                "\"authorityKind\":\"qualification-slice\"",
                "\"authorityKind\":\"complete-protocol-snapshot\""));
        AssertPublicFormatException(
            AddCompleteCatalogBeforeSchemaRegistry(BaselineManifest));
        AssertPublicFormatException(
            RemoveSliceProperty(BaselineManifest));
    }

    private static void AssertPublicFormatException(string manifest) =>
        AssertPublicFormatException(AsBytes(manifest));

    private static byte[] AsBytes(string value) =>
        StrictUtf8.GetBytes(value);

    private static byte[] Prepend(byte[] prefix, byte[] value)
    {
        var output = new byte[prefix.Length + value.Length];
        prefix.AsSpan().CopyTo(output);
        value.AsSpan().CopyTo(output.AsSpan(prefix.Length));
        return output;
    }

    private static string ReplaceFirst(string value, string oldText, string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0)
        {
            return value;
        }

        return value.Remove(index, oldText.Length)
            .Insert(index, newText);
    }

    private static string InsertDuplicateSourceCommit(string manifest)
    {
        var index = manifest.IndexOf(
            "\"sourceCommit\"",
            StringComparison.Ordinal);
        return manifest.Insert(
            index,
            "\"sourceCommit\":\"" + ZeroCommit + "\",");
    }

    private static string AddCompleteCatalogBeforeSchemaRegistry(string manifest)
    {
        const string marker = "\"schemaRegistry\"";
        var schemaIndex = manifest.IndexOf(
            marker,
            StringComparison.Ordinal);
        if (schemaIndex < 0)
        {
            return manifest;
        }

        return manifest.Insert(
            schemaIndex,
            "\"completeCatalog\":{\"predecessor\":{\"kind\":\"root\"}},");
    }

    private static string RemoveSliceProperty(string manifest)
    {
        const string marker = "\"slice\":";
        var sliceIndex = manifest.IndexOf(marker, StringComparison.Ordinal);
        if (sliceIndex < 0)
        {
            return manifest;
        }

        var openIndex = manifest.IndexOf('{', sliceIndex);
        if (openIndex < 0)
        {
            return manifest;
        }

        var depth = 0;
        var cursor = openIndex;
        while (cursor < manifest.Length)
        {
            if (manifest[cursor] == '{')
            {
                depth++;
            }
            else if (manifest[cursor] == '}')
            {
                depth--;
            }

            cursor++;
            if (depth == 0)
            {
                break;
            }
        }

        if (depth != 0)
        {
            return manifest;
        }

        var start = sliceIndex;
        if (start < 0)
        {
            return manifest;
        }

        if (cursor < manifest.Length && manifest[cursor] == ',')
        {
            cursor++;
        }

        return manifest[..start] + manifest[cursor..];
    }

    private static void AssertPublicFormatException(byte[] bytes) =>
        Assert.Throws<FormatException>(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(bytes);
        });
}
