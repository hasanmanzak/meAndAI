using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAPredecessorManifestTests
{
    private const string ProtocolVersion = "0.17.0";
    private const string ProfileName = "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string ManifestSeed = "meandai.test-0210.a.predecessor-manifest.v1\n";
    private const string ManifestDigest = "6fb963fcdf35683f2172ea62e383401f36f5c41660c59e0c594852ccb64108df";
    private const string PredecessorInventoryDigest = "52cf1f9c6ecc7e8b652d047f595bb4c66fac53735f9637cb3edbd0c54c8e8554";
    private const string CurrentInventoryDigest = "c013e4b9937f225163f58e41b893600b87d88faf6340678a79242041443f8af3";
    private static readonly ReviewedAuthorityPermalink Authority = ReviewedAuthorityPermalink.Create(
        "https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228");

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_existing_predecessor_version_and_exact_digests()
    {
        var basis = ContractSliceAFullManifestGraphTests.CreateManifest();
        var basisSlice = Assert.IsType<CatalogSliceDeclaration>(basis.Slice);
        AssertInventoryOrder(basisSlice.Rules, 1);
        var existingTwo = CreateExistingManifest(basis, 2);
        AssertFrame(Encoding.UTF8.GetBytes(ManifestSeed), 44, ManifestDigest);
        AssertFrame(InventoryFrame(basisSlice.Rules.Take(4)), 91, PredecessorInventoryDigest);
        AssertFrame(InventoryFrame(existingTwo.CompleteCatalog!.Rules), 104, CurrentInventoryDigest);

        var canonicalBytes = CanonicalManifestWriter.Write(existingTwo);

        AssertPositive(canonicalBytes, 2);
        var predecessorJson = PredecessorJson();

        var existingThree = CreateExistingManifest(basis, 3);
        AssertPositive(CanonicalManifestWriter.Write(existingThree), 3);

        AssertPredecessorWireCases(canonicalBytes, predecessorJson);
        AssertVersionBoundaries(existingTwo, canonicalBytes, predecessorJson);
    }

    private static ParsedCanonicalManifest CreateExistingManifest(
        ParsedCanonicalManifest basis,
        int currentVersionValue)
    {
        var currentVersion = CatalogVersion.Create(currentVersionValue);
        var sourceRules = Assert.IsType<CatalogSliceDeclaration>(basis.Slice).Rules;
        var rules = sourceRules.Select(rule => CloneRule(rule, currentVersion)).ToArray();
        var catalog = CreateExistingCatalog(
            currentVersion,
            CatalogVersion.Create(1),
            rules,
            Added(rules));
        return basis with
        {
            AuthorityKind = CatalogAuthorityKind.CompleteProtocolSnapshot,
            Slice = null,
            CompleteCatalog = catalog,
        };
    }

    private static CompleteCatalogDeclaration CreateExistingCatalog(
        CatalogVersion currentVersion,
        CatalogVersion predecessorVersion,
        IReadOnlyList<RuleDeclaration> rules,
        IEnumerable<RuleTransitionDeclaration> transitions) =>
        CompleteCatalogDeclaration.Create(
            ProtocolVersion,
            currentVersion,
            CatalogPredecessorBinding.Existing(
                predecessorVersion,
                ExactSha256Digest.Parse(ManifestDigest),
                ExactSha256Digest.Parse(PredecessorInventoryDigest)),
            ProfileName,
            rules,
            transitions,
            [Profile(rules)]);

    private static NamedProfileDeclaration Profile(IEnumerable<RuleDeclaration> rules) =>
        NamedProfileDeclaration.Create(
            ProfileName,
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.Conformance,
                SnapshotKind.ExactCommit,
                SurfaceSet.Create([SurfaceKind.Provider]),
                EnforcementPhase.Audit),
            rules.Skip(2).Select(rule => rule.RuleId));

    private static RuleTransitionDeclaration[] Added(IReadOnlyList<RuleDeclaration> rules) =>
        rules.Select(rule => RuleTransitionDeclaration.Added(
            rule.RuleId,
            rule.RuleRevision,
            Authority)).ToArray();

    private static RuleDeclaration CloneRule(
        RuleDeclaration rule,
        CatalogVersion currentCatalogVersion) =>
        RuleDeclaration.Create(
            rule.RuleId,
            rule.RuleRevision,
            currentCatalogVersion,
            rule.NormativeDigest,
            rule.NormativeFragments,
            rule.QualificationScenarios,
            rule.Evaluator,
            rule.ApplicabilitySlots,
            rule.EvaluationSlots,
            rule.ExpectedSelectors,
            rule.SubjectRoles,
            rule.Surfaces,
            rule.SnapshotKinds,
            rule.Operations,
            rule.Findings,
            rule.EvaluationFailureCodes,
            rule.IntroducedIn,
            rule.DeprecatedIn,
            rule.RetiredIn,
            rule.CompatibilityAliases);

    private static void AssertPositive(byte[] canonicalBytes, int currentVersion)
    {
        var finalized = FinalizedPolicyManifest.ParseCanonical(canonicalBytes);
        Assert.Equal(canonicalBytes, CanonicalManifestWriter.Write(finalized));
        Assert.Equal(Digest(canonicalBytes), finalized.ManifestDigest.Value);
        Assert.Equal(CatalogAuthorityKind.CompleteProtocolSnapshot, finalized.AuthorityKind);
        Assert.Null(finalized.Slice);
        var catalog = Assert.IsType<CompleteCatalogDeclaration>(finalized.CompleteCatalog);
        Assert.Equal(currentVersion, catalog.CatalogVersion.Value);
        Assert.Equal(CatalogPredecessorKind.Existing, catalog.Predecessor.Kind);
        Assert.Equal(1, catalog.Predecessor.CatalogVersion!.Value);
        Assert.Equal(ManifestDigest, catalog.Predecessor.ManifestDigest!.Value);
        Assert.Equal(PredecessorInventoryDigest, catalog.Predecessor.CompleteInventoryDigest!.Value);
        Assert.Equal(CurrentInventoryDigest, catalog.CompleteInventoryDigest.Value);
        Assert.NotEqual(catalog.Predecessor.ManifestDigest, catalog.Predecessor.CompleteInventoryDigest);
        Assert.NotEqual(catalog.Predecessor.CompleteInventoryDigest, catalog.CompleteInventoryDigest);
        AssertInventoryOrder(catalog.Rules, currentVersion);
        Assert.Equal(5, catalog.Transitions.Count);
        Assert.All(catalog.Transitions, transition =>
        {
            Assert.Equal(RuleTransitionKind.Added, transition.Kind);
            Assert.Null(transition.PreviousRevision);
            Assert.NotNull(transition.CurrentRevision);
            Assert.NotNull(transition.ReviewedAuthority);
        });
    }

    private static void AssertInventoryOrder(
        IReadOnlyList<RuleDeclaration> rules,
        int catalogVersion)
    {
        Assert.Equal(5, rules.Count);
        for (var index = 0; index < rules.Count; index++)
        {
            Assert.Equal($"RULE-{index + 1:0000}", rules[index].RuleId.Value);
            Assert.Equal(1, rules[index].RuleRevision.Value);
            Assert.Equal(catalogVersion, rules[index].CatalogVersion.Value);
        }
    }

    private static void AssertPredecessorWireCases(byte[] canonicalBytes, string canonicalPredecessor)
    {
        var cases = PredecessorWireCases();
        Assert.Equal(24, cases.Count);
        foreach (var (predecessorJson, projectionDigest) in cases)
        {
            var exception = Assert.Throws<FormatException>(() =>
                FinalizedPolicyManifest.ParseCanonical(
                    ReplaceExact(canonicalBytes, canonicalPredecessor, predecessorJson)));
            if (projectionDigest)
            {
                Assert.Equal("The value is not an exact SHA-256 digest.", exception.Message);
            }
        }
    }

    private static IReadOnlyList<(string Json, bool ProjectionDigest)> PredecessorWireCases()
    {
        var fields = ExistingFields();
        var names = new[] { "kind", "catalogVersion", "manifestDigest", "completeInventoryDigest" };
        var wrongTypes = new[]
        {
            "\"kind\":1", "\"catalogVersion\":\"1\"", "\"manifestDigest\":1", "\"completeInventoryDigest\":1",
        };
        var cases = new List<(string, bool)>();
        for (var index = 0; index < fields.Length; index++)
        {
            cases.Add((Object(fields.Where((_, current) => current != index)), false));
            cases.Add((Object(fields.Take(index + 1).Append(fields[index]).Concat(fields.Skip(index + 1))), false));
            cases.Add((Object(With(fields, index, $"\"{names[index]}\":null")), false));
            cases.Add((Object(With(fields, index, wrongTypes[index])), false));
        }

        cases.Add((Object(With(fields, 0, "\"kind\":\"unknown\"")), false));
        cases.Add((Object(fields.Append("\"extra\":true")), false));
        cases.Add((Object(Swap(fields, 0)), false));
        cases.Add((Object(Swap(fields, 1)), false));
        cases.Add((Object(Swap(fields, 2)), false));
        cases.Add((Object(With(fields, 0, "\"kind\":\"genesis\"")), false));
        cases.Add((Object(With(fields, 2, "\"manifestDigest\":\"not-an-exact-digest\"")), true));
        cases.Add((Object(With(fields, 3, "\"completeInventoryDigest\":\"not-an-exact-digest\"")), true));
        return cases;
    }

    private static void AssertVersionBoundaries(
        ParsedCanonicalManifest validManifest,
        byte[] canonicalBytes,
        string canonicalPredecessor)
    {
        var catalog = validManifest.CompleteCatalog!;
        var rejected = new[]
        {
            AssertVersionRejected(catalog, 2),
            AssertVersionRejected(catalog, 3),
        };
        Assert.Equal(2, rejected.Length);
        var equal = rejected[0];

        var readerException = Assert.Throws<FormatException>(() =>
            FinalizedPolicyManifest.ParseCanonical(
                ReplaceExact(canonicalBytes, canonicalPredecessor, PredecessorJson(2))));
        Assert.Equal("A policy manifest value is not canonical.", readerException.Message);
        var inner = Assert.IsType<ArgumentException>(readerException.InnerException);
        Assert.Equal(equal.GetType(), inner.GetType());
        Assert.Equal(equal.ParamName, inner.ParamName);
        Assert.Equal(equal.Message, inner.Message);
    }

    private static ArgumentException AssertVersionRejected(
        CompleteCatalogDeclaration catalog,
        int predecessorVersion)
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            CreateExistingCatalog(
                CatalogVersion.Create(2),
                CatalogVersion.Create(predecessorVersion),
                catalog.Rules,
                Added(catalog.Rules)));
        Assert.Equal("predecessor", exception.ParamName);
        return exception;
    }




    private static byte[] InventoryFrame(IEnumerable<RuleDeclaration> rules)
    {
        var snapshot = rules.ToArray();
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("meandai.complete-rule-inventory.v1\n"));
        Span<byte> number = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(number, checked((uint)snapshot.Length));
        stream.Write(number);
        foreach (var rule in snapshot)
        {
            stream.Write(Encoding.ASCII.GetBytes(rule.RuleId.Value));
            BinaryPrimitives.WriteUInt32BigEndian(number, checked((uint)rule.RuleRevision.Value));
            stream.Write(number);
        }
        return stream.ToArray();
    }

    private static void AssertFrame(byte[] frame, int expectedLength, string expectedDigest)
    {
        Assert.Equal(expectedLength, frame.Length);
        Assert.Equal(expectedDigest, Digest(frame));
    }

    private static string Digest(byte[] bytes) =>
        Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();

    private static string[] ExistingFields(
        int catalogVersion = 1,
        string manifestDigest = ManifestDigest,
        string inventoryDigest = PredecessorInventoryDigest) =>
    [
        "\"kind\":\"existing\"",
        $"\"catalogVersion\":{catalogVersion}",
        $"\"manifestDigest\":\"{manifestDigest}\"",
        $"\"completeInventoryDigest\":\"{inventoryDigest}\"",
    ];

    private static string PredecessorJson(int catalogVersion = 1) =>
        Object(ExistingFields(catalogVersion));

    private static string Object(IEnumerable<string> fields) =>
        "{" + string.Join(",", fields) + "}";

    private static string[] With(string[] fields, int index, string replacement)
    {
        var result = fields.ToArray();
        result[index] = replacement;
        return result;
    }

    private static string[] Swap(string[] fields, int leftIndex)
    {
        var result = fields.ToArray();
        (result[leftIndex], result[leftIndex + 1]) = (result[leftIndex + 1], result[leftIndex]);
        return result;
    }



    private static byte[] ReplaceExact(byte[] source, string original, string replacement)
    {
        AssertCanonicalLineFrame(source);
        var originalBytes = Encoding.UTF8.GetBytes(original);
        var replacementBytes = Encoding.UTF8.GetBytes(replacement);
        var first = source.AsSpan().IndexOf(originalBytes);
        Assert.True(first >= 0);
        Assert.Equal(-1, source.AsSpan(first + originalBytes.Length).IndexOf(originalBytes));

        var mutated = new byte[source.Length - originalBytes.Length + replacementBytes.Length];
        source.AsSpan(0, first).CopyTo(mutated);
        replacementBytes.AsSpan().CopyTo(mutated.AsSpan(first));
        source.AsSpan(first + originalBytes.Length).CopyTo(
            mutated.AsSpan(first + replacementBytes.Length));
        Assert.Equal(-1, mutated.AsSpan().IndexOf(originalBytes));
        var replacementOffset = mutated.AsSpan().IndexOf(replacementBytes);
        Assert.True(replacementOffset >= 0);
        Assert.Equal(
            -1,
            mutated.AsSpan(replacementOffset + replacementBytes.Length).IndexOf(replacementBytes));
        AssertCanonicalLineFrame(mutated);
        return mutated;
    }

    private static void AssertCanonicalLineFrame(byte[] bytes)
    {
        Assert.DoesNotContain((byte)'\r', bytes);
        Assert.Equal((byte)'\n', bytes[^1]);
        Assert.Single(bytes, value => value == (byte)'\n');
    }
}
