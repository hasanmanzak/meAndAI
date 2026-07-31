using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceACanonicalJsonGrammarTests
{
    private const string BaselineManifest =
        ContractSliceAManifestTests.MinimalCanonicalManifest;

    private const string ZeroCommit =
        "0000000000000000000000000000000000000001";

    private const string SchemaAuthorityBoundary =
        "\"schema\":\"protocol.policy-manifest.v1\",\"authorityKind\"";

    private const string MinimalSliceObject =
        "{\"sliceKey\":\"protocol.catalog-slice.test-empty\"," +
        "\"sliceVersion\":\"1\",\"rules\":[]}";

    private const string MinimalSliceMember =
        "\"slice\":" + MinimalSliceObject;

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

        Assert.Null(manifest.CompleteCatalog);

        var invalidVectors = CreateInvalidVectors(baselineBytes);
        Assert.Equal(
            invalidVectors.Count,
            invalidVectors
                .Select(vector => vector.Name)
                .Distinct(StringComparer.Ordinal)
                .Count());

        foreach (var vector in invalidVectors)
        {
            Assert.False(
                baselineBytes.AsSpan().SequenceEqual(vector.Bytes),
                $"Vector '{vector.Name}' did not mutate the baseline manifest.");
            AssertExactPublicFormatException(vector.Name, vector.Bytes);
        }
    }

    private static IReadOnlyList<(string Name, byte[] Bytes)> CreateInvalidVectors(
        byte[] baselineBytes)
    {
        var vectors = new List<(string Name, byte[] Bytes)>
        {
            ("empty", Array.Empty<byte>()),
            ("utf8-bom", Prepend(Utf8Bom, baselineBytes)),
            ("missing-final-lf", AsBytes(BaselineManifest[..^1])),
            ("extra-final-lf", AsBytes(BaselineManifest + "\n")),
            ("final-crlf", AsBytes(BaselineManifest[..^1] + "\r\n")),
            ("final-lone-cr", AsBytes(BaselineManifest[..^1] + "\r")),
            (
                "malformed-json-missing-comma",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        SchemaAuthorityBoundary,
                        "\"schema\":\"protocol.policy-manifest.v1\"" +
                        "\"authorityKind\""))),
            (
                "malformed-json-unterminated-root-with-valid-lf",
                AsBytes(BaselineManifest[..^2] + "\n")),
            ("json-root-array", AsBytes("[]\n")),
            (
                "root-property-alternate-spelling",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"authorityKind\":\"qualification-slice\"",
                        "\"authoritykind\":\"qualification-slice\""))),
            (
                "slice-property-alternate-spelling",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"sliceVersion\":\"1\"",
                        "\"sliceversion\":\"1\""))),
            (
                "unknown-root-property",
                AsBytes(
                    InsertBeforeRequired(
                        BaselineManifest,
                        "\"sourceCommit\"",
                        "\"unknownRoot\":0,"))),
            (
                "unknown-slice-property",
                AsBytes(
                    InsertBeforeRequired(
                        BaselineManifest,
                        "\"sliceVersion\"",
                        "\"unknownSlice\":0,"))),
            (
                "unknown-authority-kind",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"authorityKind\":\"qualification-slice\"",
                        "\"authorityKind\":\"qualification_slice\""))),
            (
                "null-authority-kind",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"authorityKind\":\"qualification-slice\"",
                        "\"authorityKind\":null"))),
            (
                "null-source-commit",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"sourceCommit\":\"" + ZeroCommit + "\"",
                        "\"sourceCommit\":null"))),
            (
                "null-slice",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        MinimalSliceMember,
                        "\"slice\":null"))),
            (
                "null-slice-member",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"sliceKey\":\"protocol.catalog-slice.test-empty\"",
                        "\"sliceKey\":null"))),
            (
                "duplicate-root-property",
                AsBytes(
                    InsertBeforeRequired(
                        BaselineManifest,
                        "\"sourceCommit\"",
                        "\"sourceCommit\":\"" + ZeroCommit + "\","))),
            (
                "duplicate-slice-property",
                AsBytes(
                    InsertBeforeRequired(
                        BaselineManifest,
                        "\"sliceVersion\"",
                        "\"sliceKey\":\"protocol.catalog-slice.test-empty\","))),
            (
                "missing-root-property",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"sourceCommit\":\"" + ZeroCommit + "\",",
                        string.Empty))),
            (
                "missing-slice-member",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"sliceVersion\":\"1\",",
                        string.Empty))),
            (
                "missing-slice-variant",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        MinimalSliceMember + ",",
                        string.Empty))),
            (
                "complete-authority-with-slice-is-held",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        "\"authorityKind\":\"qualification-slice\"",
                        "\"authorityKind\":\"complete-protocol-snapshot\""))),
            (
                "unexpected-complete-member-on-qualification-slice",
                AsBytes(
                    InsertBeforeRequired(
                        BaselineManifest,
                        "\"schemaRegistry\"",
                        "\"completeCatalog\":{},"))),
            (
                "actual-block-comment",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        SchemaAuthorityBoundary,
                        "\"schema\":\"protocol.policy-manifest.v1\"" +
                        "/*comment*/,\"authorityKind\""))),
            (
                "actual-line-comment",
                AsBytes(
                    ReplaceRequired(
                        BaselineManifest,
                        SchemaAuthorityBoundary,
                        "\"schema\":\"protocol.policy-manifest.v1\"" +
                        "//comment\n,\"authorityKind\""))),
            (
                "trailing-json-value",
                AsBytes(BaselineManifest[..^1] + "{}\n")),
            (
                "trailing-comma",
                AsBytes(BaselineManifest[..^2] + ",}\n")),
        };

        AddMalformedUtf8Vectors(vectors, baselineBytes);
        AddPropertyOrderVectors(vectors);
        AddWhitespaceVectors(vectors);
        return vectors;
    }

    private static void AddMalformedUtf8Vectors(
        ICollection<(string Name, byte[] Bytes)> vectors,
        byte[] baselineBytes)
    {
        (string Name, byte[] Bytes)[] malformedValues =
        [
            ("isolated-continuation", [0x80]),
            ("overlong-form", [0xC0, 0xAF]),
            ("utf8-surrogate", [0xED, 0xA0, 0x80]),
            ("truncated-sequence", [0xF0, 0xA0, 0xAE]),
            ("above-unicode-maximum", [0xF4, 0x90, 0x80, 0x80]),
        ];
        var marker = StrictUtf8.GetBytes("Conformance.Tests");

        foreach (var malformedValue in malformedValues)
        {
            vectors.Add(
                (
                    "malformed-utf8-" + malformedValue.Name,
                    InsertBytesBeforeRequired(
                        baselineBytes,
                        marker,
                        malformedValue.Bytes)));
        }
    }

    private static void AddPropertyOrderVectors(
        ICollection<(string Name, byte[] Bytes)> vectors)
    {
        string[] rootPropertyOrder =
        [
            "schema",
            "authorityKind",
            "sourceCommit",
            "protocolVersion",
            "catalogVersion",
            "slice",
            "schemaRegistry",
            "activationProofContract",
            "artifactFiles",
            "components",
        ];
        string[] slicePropertyOrder =
        [
            "sliceKey",
            "sliceVersion",
            "rules",
        ];

        AddAdjacentSwapVectors(vectors, null, rootPropertyOrder);
        AddAdjacentSwapVectors(vectors, "slice", slicePropertyOrder);
    }

    private static void AddAdjacentSwapVectors(
        ICollection<(string Name, byte[] Bytes)> vectors,
        string? nestedObjectProperty,
        IReadOnlyList<string> propertyOrder)
    {
        var scopeName = nestedObjectProperty ?? "root";
        for (var index = 0; index < propertyOrder.Count - 1; index++)
        {
            var first = propertyOrder[index];
            var second = propertyOrder[index + 1];
            vectors.Add(
                (
                    $"{scopeName}-order-swapped-{first}-{second}",
                    SwapAdjacentProperties(
                        nestedObjectProperty,
                        first,
                        second)));
        }
    }

    private static void AddWhitespaceVectors(
        ICollection<(string Name, byte[] Bytes)> vectors)
    {
        (string Name, string Value)[] whitespaceValues =
        [
            ("space", " "),
            ("tab", "\t"),
            ("cr", "\r"),
            ("lf", "\n"),
        ];

        foreach (var whitespace in whitespaceValues)
        {
            vectors.Add(
                (
                    "whitespace-leading-" + whitespace.Name,
                    AsBytes(whitespace.Value + BaselineManifest)));
            vectors.Add(
                (
                    "whitespace-interior-" + whitespace.Name,
                    AsBytes(
                        ReplaceRequired(
                            BaselineManifest,
                            SchemaAuthorityBoundary,
                            "\"schema\":\"protocol.policy-manifest.v1\"" +
                            whitespace.Value +
                            ",\"authorityKind\""))));
            vectors.Add(
                (
                    "whitespace-trailing-" + whitespace.Name,
                    AsBytes(
                        BaselineManifest[..^1] +
                        whitespace.Value +
                        "\n")));
        }
    }

    private static byte[] AsBytes(string value) =>
        StrictUtf8.GetBytes(value);

    private static byte[] Prepend(byte[] prefix, byte[] value)
    {
        var output = new byte[prefix.Length + value.Length];
        prefix.AsSpan().CopyTo(output);
        value.AsSpan().CopyTo(output.AsSpan(prefix.Length));
        return output;
    }

    private static string ReplaceRequired(
        string value,
        string oldText,
        string newText)
    {
        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0)
        {
            throw new InvalidOperationException(
                $"Required fixture text was not found: {oldText}");
        }

        return value.Remove(index, oldText.Length)
            .Insert(index, newText);
    }

    private static string InsertBeforeRequired(
        string value,
        string marker,
        string insertion)
    {
        var index = value.IndexOf(marker, StringComparison.Ordinal);
        if (index < 0)
        {
            throw new InvalidOperationException(
                $"Required fixture marker was not found: {marker}");
        }

        return value.Insert(index, insertion);
    }

    private static byte[] InsertBytesBeforeRequired(
        byte[] value,
        byte[] marker,
        byte[] insertion)
    {
        var index = value.AsSpan().IndexOf(marker);
        if (index < 0)
        {
            throw new InvalidOperationException(
                "Required byte fixture marker was not found.");
        }

        var output = new byte[value.Length + insertion.Length];
        value.AsSpan(0, index).CopyTo(output);
        insertion.CopyTo(output, index);
        value.AsSpan(index).CopyTo(output.AsSpan(index + insertion.Length));
        return output;
    }

    private static byte[] SwapAdjacentProperties(
        string? nestedObjectProperty,
        string firstProperty,
        string secondProperty)
    {
        using var document = JsonDocument.Parse(BaselineManifest);
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(
                   stream,
                   new JsonWriterOptions
                   {
                       Indented = false,
                       SkipValidation = false,
                   }))
        {
            if (nestedObjectProperty is null)
            {
                WriteObjectWithAdjacentSwap(
                    writer,
                    document.RootElement,
                    firstProperty,
                    secondProperty);
            }
            else
            {
                WriteRootWithNestedAdjacentSwap(
                    writer,
                    document.RootElement,
                    nestedObjectProperty,
                    firstProperty,
                    secondProperty);
            }
        }

        var jsonBytes = stream.ToArray();
        var output = new byte[jsonBytes.Length + 1];
        jsonBytes.CopyTo(output, 0);
        output[^1] = (byte)'\n';
        return output;
    }

    private static void WriteRootWithNestedAdjacentSwap(
        Utf8JsonWriter writer,
        JsonElement root,
        string nestedObjectProperty,
        string firstProperty,
        string secondProperty)
    {
        if (!root.TryGetProperty(nestedObjectProperty, out _))
        {
            throw new InvalidOperationException(
                $"Nested fixture object was not found: {nestedObjectProperty}");
        }

        writer.WriteStartObject();
        foreach (var property in root.EnumerateObject())
        {
            writer.WritePropertyName(property.Name);
            if (property.NameEquals(nestedObjectProperty))
            {
                WriteObjectWithAdjacentSwap(
                    writer,
                    property.Value,
                    firstProperty,
                    secondProperty);
            }
            else
            {
                property.Value.WriteTo(writer);
            }
        }

        writer.WriteEndObject();
    }

    private static void WriteObjectWithAdjacentSwap(
        Utf8JsonWriter writer,
        JsonElement value,
        string firstProperty,
        string secondProperty)
    {
        var properties = value.EnumerateObject().ToArray();
        var firstIndex = Array.FindIndex(
            properties,
            property => property.NameEquals(firstProperty));
        if (firstIndex < 0 ||
            firstIndex + 1 >= properties.Length ||
            !properties[firstIndex + 1].NameEquals(secondProperty))
        {
            throw new InvalidOperationException(
                $"Fixture properties are not adjacent: " +
                $"{firstProperty}, {secondProperty}");
        }

        (properties[firstIndex], properties[firstIndex + 1]) =
            (properties[firstIndex + 1], properties[firstIndex]);

        writer.WriteStartObject();
        foreach (var property in properties)
        {
            property.WriteTo(writer);
        }

        writer.WriteEndObject();
    }

    private static void AssertExactPublicFormatException(
        string vectorName,
        byte[] bytes)
    {
        var exception = Record.Exception(() =>
        {
            _ = FinalizedPolicyManifest.ParseCanonical(bytes);
        });

        Assert.True(
            exception?.GetType() == typeof(FormatException),
            $"Vector '{vectorName}' must produce exact FormatException; " +
            $"actual: {exception?.GetType().FullName ?? "<none>"}.");
    }
}
