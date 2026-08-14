using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceARuleDeclarationTests
{
    private const string ProbeDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";

    private const string ProbeBlob =
        "1111111111111111111111111111111111111111";

    private const string SourceCommit =
        "0000000000000000000000000000000000000001";

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_canonical_multi_fragment_rule_provenance()
    {
        var source = CreateManifest(CreateRule(CreateNormativeFragments()));
        var canonicalManifest = CanonicalManifestWriter.Write(source);
        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalManifest);
        var rehydrated = CanonicalManifestWriter.Write(manifest);

        Assert.Equal(canonicalManifest, rehydrated);
        Assert.Equal(
            Convert.ToHexString(SHA256.HashData(canonicalManifest)).ToLowerInvariant(),
            manifest.ManifestDigest.Value);
        Assert.Equal(CatalogAuthorityKind.QualificationSlice, manifest.AuthorityKind);
        Assert.Equal(SourceCommit, manifest.SourceCommit);

        using var canonicalDocument = JsonDocument.Parse(canonicalManifest);
        var canonicalRule = canonicalDocument.RootElement
            .GetProperty("slice")
            .GetProperty("rules")
            .EnumerateArray()
            .Single();
        Assert.Equal(
            [
                "ruleId",
                "ruleRevision",
                "catalogVersion",
                "normativeDigest",
                "normativeFragments",
                "qualificationScenarios",
                "evaluator",
                "applicabilitySlots",
                "evaluationSlots",
                "expectedSelectors",
                "subjectRoles",
                "surfaces",
                "snapshotKinds",
                "operations",
                "findings",
                "evaluationFailureCodes",
                "introducedIn",
                "deprecatedIn",
                "retiredIn",
                "compatibilityAliases",
            ],
            canonicalRule.EnumerateObject().Select(property => property.Name));
        Assert.All(
            canonicalRule.GetProperty("normativeFragments").EnumerateArray(),
            fragment => Assert.Equal(
                [
                    "path",
                    "containingBlob",
                    "anchor",
                    "startLine",
                    "endLine",
                    "canonicalizationSchema",
                    "canonicalByteLength",
                    "fragmentDigest",
                ],
                fragment.EnumerateObject().Select(property => property.Name)));

        var slice = Assert.IsType<CatalogSliceDeclaration>(manifest.Slice);
        var rule = Assert.Single(slice.Rules);
        Assert.Equal("RULE-0001", rule.RuleId.Value);
        Assert.Equal(1, rule.RuleRevision.Value);
        Assert.Equal(1, rule.CatalogVersion.Value);
        Assert.Equal(ProbeDigest, rule.NormativeDigest.Value);
        Assert.Equal(
            ["docs/rules/z-rule.md", "docs/rules/a-rule-metadata.md"],
            rule.NormativeFragments.Select(fragment => fragment.Path));
        Assert.Equal(
            ["rule-body", "rule-metadata"],
            rule.NormativeFragments.Select(fragment => fragment.Anchor));
        Assert.All(
            rule.NormativeFragments,
            fragment =>
            {
                Assert.Equal(ProbeBlob, fragment.ContainingBlob);
                Assert.Equal(
                    "protocol.normative-fragment.utf8-lines.v1",
                    fragment.CanonicalizationSchema);
                Assert.Equal(2, fragment.CanonicalByteLength);
                Assert.Equal(ProbeDigest, fragment.FragmentDigest.Value);
            });
        Assert.Equal(
            [TestScenarioId.Parse("TEST-0001"), TestScenarioId.Parse("TEST-0002")],
            rule.QualificationScenarios);
        Assert.Equal("protocol.evaluator.test-rule", rule.Evaluator.ComponentKey);
        Assert.Empty(rule.ApplicabilitySlots);
        Assert.Empty(rule.EvaluationSlots);
        Assert.Empty(rule.ExpectedSelectors);
        Assert.Empty(rule.Findings);
        Assert.Empty(rule.EvaluationFailureCodes);
        Assert.Equal("1.0.0", rule.IntroducedIn);
        Assert.Equal("2.0.0", rule.DeprecatedIn);
        Assert.Equal("3.0.0", rule.RetiredIn);
        Assert.Equal(
            ["protocol.compatibility.alpha", "protocol.compatibility.zeta"],
            rule.CompatibilityAliases);

        var singleFragmentRule = CreateRule([CreateNormativeFragments()[0]]);
        Assert.Single(singleFragmentRule.NormativeFragments);
        AssertRoundTrip(singleFragmentRule);

        var lifecycleShapes = new (string? DeprecatedIn, string? RetiredIn)[]
        {
            (null, null),
            ("2.0.0", null),
            (null, "3.0.0"),
            ("2.0.0", "3.0.0"),
        };
        foreach (var shape in lifecycleShapes)
        {
            var parsed = AssertRoundTrip(
                CreateRule(
                    CreateNormativeFragments(),
                    shape.DeprecatedIn,
                    shape.RetiredIn));
            var parsedRule = Assert.Single(
                Assert.IsType<CatalogSliceDeclaration>(parsed.Slice).Rules);
            Assert.Equal(shape.DeprecatedIn, parsedRule.DeprecatedIn);
            Assert.Equal(shape.RetiredIn, parsedRule.RetiredIn);
        }

        Assert.ThrowsAny<ArgumentException>(() =>
            CreateRule(Array.Empty<NormativeFragmentDeclaration>()));
        Assert.ThrowsAny<ArgumentException>(() =>
            CreateRule(
            [
                CreateFragment("docs/rules/duplicate.md", "stable-address", 1, 2),
                CreateFragment("docs/rules/duplicate.md", "stable-address", 10, 20),
            ]));

        AssertFragmentRejected(path: "../docs/rule.md");
        AssertFragmentRejected(path: "/docs/rule.md");
        AssertFragmentRejected(path: "C:/docs/rule.md");
        AssertFragmentRejected(path: "docs\\rules\\rule.md");
        AssertFragmentRejected(blob: "111");
        AssertFragmentRejected(blob: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        AssertFragmentRejected(anchor: "#rule-body");
        AssertFragmentRejected(startLine: 0);
        AssertFragmentRejected(startLine: 2, endLine: 1);
        AssertFragmentRejected(canonicalizationSchema: "protocol.normative-fragment.legacy");
        AssertFragmentRejected(canonicalByteLength: 0);

        Assert.ThrowsAny<ArgumentException>(() =>
            CreateRule(CreateNormativeFragments(), "4.0.0", "3.0.0"));
        Assert.ThrowsAny<ArgumentException>(() =>
            CreateRule(CreateNormativeFragments(), null, "0.9.0"));

        var canonicalText = Encoding.UTF8.GetString(canonicalManifest);
        var invalidShapeMutations = new (string OldText, string NewText)[]
        {
            ("\"ruleRevision\":1,", string.Empty),
            ("\"compatibilityAliases\"", "\"unknownRule\":0,\"compatibilityAliases\""),
            ("\"ruleId\":\"RULE-0001\"", "\"ruleId\":null"),
            ("\"ruleRevision\":1", "\"ruleRevision\":1,\"ruleRevision\":1"),
            ("\"qualificationScenarios\":[\"TEST-0001\",\"TEST-0002\"]", "\"qualificationScenarios\":[0]"),
            ("\"containingBlob\":\"" + ProbeBlob + "\",", string.Empty),
            ("\"path\":\"docs/rules/z-rule.md\"", "\"unknownFragment\":0,\"path\":\"docs/rules/z-rule.md\""),
            ("\"path\":\"docs/rules/z-rule.md\"", "\"path\":null"),
            ("\"path\":\"docs/rules/z-rule.md\"", "\"path\":\"docs/rules/z-rule.md\",\"path\":\"docs/rules/z-rule.md\""),
        };
        foreach (var mutation in invalidShapeMutations)
        {
            AssertPublicFormatException(
                ReplaceRequired(canonicalText, mutation.OldText, mutation.NewText));
        }

        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"evaluator\":{\"componentKey\":\"protocol.evaluator.test-rule\",\"componentVersion\":\"1\"}",
                "\"evaluator\":{\"componentKey\":\"protocol.runtime.domain\",\"componentVersion\":\"1\"}"));
        var duplicateAddress = ReplaceRequired(
            ReplaceRequired(
                canonicalText,
                "\"path\":\"docs/rules/a-rule-metadata.md\"",
                "\"path\":\"docs/rules/z-rule.md\""),
            "\"anchor\":\"rule-metadata\"",
            "\"anchor\":\"rule-body\"");
        AssertPublicFormatException(duplicateAddress);

        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"path\":\"docs/rules/z-rule.md\",\"containingBlob\":\"" + ProbeBlob + "\"",
                "\"containingBlob\":\"" + ProbeBlob + "\",\"path\":\"docs/rules/z-rule.md\""));
        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"deprecatedIn\":\"2.0.0\"",
                "\"deprecatedIn\":null"));
        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"deprecatedIn\":\"2.0.0\"",
                "\"deprecatedIn\":\"2.0.0\",\"deprecatedIn\":\"2.0.0\""));
        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"deprecatedIn\":\"2.0.0\",\"retiredIn\":\"3.0.0\"",
                "\"retiredIn\":\"3.0.0\",\"deprecatedIn\":\"2.0.0\""));
        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"compatibilityAliases\"",
                "\"unknownLifecycleField\":\"x\",\"compatibilityAliases\""));

        foreach (var invalidCommit in new[]
                 {
                     "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                     "000000000000000000000000000000000000001",
                     "000000000000000000000000000000000000000g",
                 })
        {
            AssertPublicFormatException(
                ReplaceRequired(canonicalText, SourceCommit, invalidCommit));
        }

        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"normativeDigest\":\"" + ProbeDigest + "\"",
                "\"normativeDigest\":\"" + ProbeDigest.ToUpperInvariant() + "\""));
        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"fragmentDigest\":\"" + ProbeDigest + "\"",
                "\"fragmentDigest\":\"" + ProbeDigest[..^1] + "\""));
        AssertPublicFormatException(
            ReplaceRequired(
                canonicalText,
                "\"fragmentDigest\":\"" + ProbeDigest + "\"",
                "\"fragmentDigest\":\"" + ProbeDigest.ToUpperInvariant() + "\""));

        var invalidProvenanceMutations = new (string OldText, string NewText)[]
        {
            ("\"path\":\"docs/rules/z-rule.md\"", "\"path\":\"../docs/rule.md\""),
            ("\"containingBlob\":\"" + ProbeBlob + "\"", "\"containingBlob\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\""),
            ("\"anchor\":\"rule-body\"", "\"anchor\":\"#rule-body\""),
            ("\"startLine\":1", "\"startLine\":0"),
            ("\"startLine\":1,\"endLine\":2", "\"startLine\":2,\"endLine\":1"),
            ("\"canonicalizationSchema\":\"protocol.normative-fragment.utf8-lines.v1\"", "\"canonicalizationSchema\":\"protocol.normative-fragment.legacy\""),
            ("\"canonicalByteLength\":2", "\"canonicalByteLength\":0"),
        };
        foreach (var mutation in invalidProvenanceMutations)
        {
            AssertPublicFormatException(
                ReplaceRequired(canonicalText, mutation.OldText, mutation.NewText));
        }
    }

    private static FinalizedPolicyManifest AssertRoundTrip(RuleDeclaration rule)
    {
        var canonical = CanonicalManifestWriter.Write(CreateManifest(rule));
        var parsed = FinalizedPolicyManifest.ParseCanonical(canonical);
        Assert.Equal(canonical, CanonicalManifestWriter.Write(parsed));
        return parsed;
    }

    private static void AssertFragmentRejected(
        string path = "docs/rules/rule.md",
        string blob = ProbeBlob,
        string anchor = "rule-body",
        int startLine = 1,
        int endLine = 2,
        string canonicalizationSchema = "protocol.normative-fragment.utf8-lines.v1",
        long canonicalByteLength = 2) =>
        Assert.ThrowsAny<ArgumentException>(() =>
            NormativeFragmentDeclaration.Create(
                path,
                blob,
                anchor,
                startLine,
                endLine,
                canonicalizationSchema,
                canonicalByteLength,
                ExactSha256Digest.Parse(ProbeDigest)));

    private static ParsedCanonicalManifest CreateManifest(RuleDeclaration rule) =>
        new(
            CatalogAuthorityKind.QualificationSlice,
            SourceCommit,
            ReleaseSchemaRegistry.Create(
                Array.Empty<PayloadSchemaDeclaration>(),
                Array.Empty<SemanticModelParserDeclaration>(),
                Array.Empty<ContextIndexDeclaration>(),
                Array.Empty<AcquisitionDemandProjectorDeclaration>(),
                Array.Empty<AdmissionProofContractDeclaration>(),
                SessionCacheBudget.Create(
                    1,
                    1,
                    1,
                    1,
                    1,
                    1,
                    CacheRetentionPolicy.RetainLowestCanonicalKeys)),
            ActivationProofContractDeclaration.Create(
                "protocol.activation-proof.test",
                "1.0.0",
                ResolveComponentIdentity("protocol.activation-proof.test")),
            CreateArtifacts(),
            CreateComponents(),
            CatalogSliceDeclaration.Create(
                "protocol.catalog-slice.test-rule",
                "1",
                "0.0.0",
                CatalogVersion.Create(1),
                [rule]));

    private static RuleDeclaration CreateRule(
        IReadOnlyList<NormativeFragmentDeclaration> fragments,
        string? deprecatedIn = "2.0.0",
        string? retiredIn = "3.0.0") =>
        RuleDeclaration.Create(
            RuleId.Parse("RULE-0001"),
            RuleRevision.Create(1),
            CatalogVersion.Create(1),
            ExactSha256Digest.Parse(ProbeDigest),
            fragments,
            new[]
            {
                TestScenarioId.Parse("TEST-0002"),
                TestScenarioId.Parse("TEST-0001"),
            },
            ResolveComponentIdentity("protocol.evaluator.test-rule"),
            Array.Empty<EvidenceSlotDeclaration>(),
            Array.Empty<EvidenceSlotDeclaration>(),
            Array.Empty<ExpectedSelectorDeclaration>(),
            new[]
            {
                SubjectRole.ProtocolAuthoritySelfConsumer,
                SubjectRole.Consumer,
            },
            SurfaceSet.Create(new[] { SurfaceKind.Provider, SurfaceKind.Repository }),
            new[] { SnapshotKind.ExactCommit },
            new[] { ProtocolOperation.Conformance },
            Array.Empty<FindingDeclaration>(),
            Array.Empty<EvaluationFailureCode>(),
            "1.0.0",
            deprecatedIn,
            retiredIn,
            new[]
            {
                "protocol.compatibility.zeta",
                "protocol.compatibility.alpha",
            });

    private static IReadOnlyList<NormativeFragmentDeclaration> CreateNormativeFragments() =>
    [
        CreateFragment("docs/rules/z-rule.md", "rule-body", 1, 2),
        CreateFragment("docs/rules/a-rule-metadata.md", "rule-metadata", 10, 20),
    ];

    private static NormativeFragmentDeclaration CreateFragment(
        string path,
        string anchor,
        int startLine,
        int endLine) =>
        NormativeFragmentDeclaration.Create(
            path,
            ProbeBlob,
            anchor,
            startLine,
            endLine,
            "protocol.normative-fragment.utf8-lines.v1",
            2,
            ExactSha256Digest.Parse(ProbeDigest));

    private static ComponentTypeIdentity ResolveComponentIdentity(string componentKey) =>
        componentKey switch
        {
            "protocol.activation-proof.test" =>
                ComponentTypeIdentity.Create(
                    "protocol.activation-proof.test",
                    "1",
                    "MeAndAI.Protocol.Conformance.Tests",
                    "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"),
            "protocol.evaluator.test-rule" =>
                ComponentTypeIdentity.Create(
                    "protocol.evaluator.test-rule",
                    "1",
                    "MeAndAI.Protocol.Conformance.Tests",
                    "MeAndAI.Protocol.Conformance.Tests.ContractSliceATestRuleEvaluator"),
            "protocol.runtime.domain" =>
                ComponentTypeIdentity.Create(
                    "protocol.runtime.domain",
                    "1",
                    "MeAndAI.Protocol.Domain",
                    "MeAndAI.Protocol.Domain.RuleId"),
            "protocol.runtime.conformance-abstractions" =>
                ComponentTypeIdentity.Create(
                    "protocol.runtime.conformance-abstractions",
                    "1",
                    "MeAndAI.Protocol.Conformance.Abstractions",
                    "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport"),
            "protocol.runtime.conformance" =>
                ComponentTypeIdentity.Create(
                    "protocol.runtime.conformance",
                    "1",
                    "MeAndAI.Protocol.Conformance",
                    "MeAndAI.Protocol.Conformance.CatalogIntegrityException"),
            "protocol.runtime.markdig" =>
                ComponentTypeIdentity.Create(
                    "protocol.runtime.markdig",
                    "1",
                    "Markdig",
                    "Markdig.Markdown"),
            _ => throw new ArgumentOutOfRangeException(nameof(componentKey)),
        };

    private static IReadOnlyList<ArtifactFileBinding> CreateArtifacts() =>
    [
        ArtifactFileBinding.Create("ContractSliceA.Proof.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
        ArtifactFileBinding.Create("Markdig.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
        ArtifactFileBinding.Create("MeAndAI.Protocol.Conformance.Abstractions.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
        ArtifactFileBinding.Create("MeAndAI.Protocol.Conformance.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
        ArtifactFileBinding.Create("MeAndAI.Protocol.Domain.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
    ];

    private static IReadOnlyList<ComponentArtifactBinding> CreateComponents() =>
    [
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.activation-proof.test"), "ContractSliceA.Proof.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.evaluator.test-rule"), "ContractSliceA.Proof.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.runtime.conformance"), "MeAndAI.Protocol.Conformance.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.runtime.conformance-abstractions"), "MeAndAI.Protocol.Conformance.Abstractions.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.runtime.domain"), "MeAndAI.Protocol.Domain.dll"),
        ComponentArtifactBinding.Create(ResolveComponentIdentity("protocol.runtime.markdig"), "Markdig.dll"),
    ];

    private static string ReplaceRequired(
        string value,
        string oldText,
        string newText)
    {
        if (oldText.Length == 0 ||
            string.Equals(oldText, newText, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "A required rule mutation must make a non-empty change.");
        }

        var index = value.IndexOf(oldText, StringComparison.Ordinal);
        if (index < 0)
        {
            throw new InvalidOperationException(
                $"Required mutation marker was absent: {oldText}");
        }

        var result = value.Remove(index, oldText.Length).Insert(index, newText);
        if (string.Equals(result, value, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "A required rule mutation was a no-op.");
        }

        return result;
    }

    private static void AssertPublicFormatException(string manifest) =>
        Assert.Throws<FormatException>(() =>
            FinalizedPolicyManifest.ParseCanonical(Encoding.UTF8.GetBytes(manifest)));
}
