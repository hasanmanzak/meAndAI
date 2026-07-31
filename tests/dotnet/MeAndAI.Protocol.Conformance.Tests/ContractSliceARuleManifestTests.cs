using System.Linq;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceARuleManifestTests
{
    private const string ProbeDigest =
        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d";

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Parses_and_rehydrates_qualification_manifest_with_a_full_rule()
    {
        var source = CreateMinimalRuleManifest();
        var canonicalManifest = CanonicalManifestWriter.Write(source);
        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalManifest);
        var rehydrated = CanonicalManifestWriter.Write(manifest);

        Assert.Equal(canonicalManifest, rehydrated);
        Assert.Equal(CatalogAuthorityKind.QualificationSlice, manifest.AuthorityKind);
        Assert.Equal(
            "0000000000000000000000000000000000000001",
            manifest.SourceCommit);

        var slice = Assert.IsType<CatalogSliceDeclaration>(manifest.Slice);
        Assert.Equal("protocol.catalog-slice.test-rule", slice.SliceKey);
        Assert.Equal("1", slice.SliceVersion);
        Assert.Equal("0.0.0", slice.ProtocolVersion);
        Assert.Equal(1, slice.CatalogVersion.Value);
        Assert.Equal(5, manifest.ArtifactFiles.Count);
        Assert.Equal(5, manifest.Components.Count);
        var rule = Assert.Single(slice.Rules);
        Assert.Equal("RULE-00001", rule.RuleId.Value);
        Assert.Equal(1, rule.RuleRevision.Value);
        Assert.Equal(1, rule.CatalogVersion.Value);
        Assert.Equal(ProbeDigest, rule.NormativeDigest.Value);
        Assert.Equal(2, rule.NormativeFragments.Count);
        Assert.Equal(2, rule.QualificationScenarios.Count);
        Assert.Equal(
            [TestScenarioId.Parse("TEST-00001"), TestScenarioId.Parse("TEST-00002")],
            rule.QualificationScenarios);

        Assert.Equal("protocol.runtime.domain", rule.Evaluator.ComponentKey);
        Assert.Equal("protocol.slot-1", rule.ApplicabilitySlots.Single().SlotKey);
        Assert.Equal("protocol.slot-1", rule.EvaluationSlots.Single().SlotKey);
        Assert.Equal("protocol.selector-1", Assert.Single(rule.ExpectedSelectors).SelectorKey);
        Assert.Contains(SubjectRole.Consumer, rule.SubjectRoles);
        Assert.Contains(
            SubjectRole.ProtocolAuthoritySelfConsumer,
            rule.SubjectRoles);
        Assert.Contains(
            "protocol.compatibility.example",
            rule.CompatibilityAliases);
        Assert.Equal("1.0.0", rule.IntroducedIn);
        Assert.Equal("2.0.0", rule.DeprecatedIn);
        Assert.Equal("3.0.0", rule.RetiredIn);

        var finding = Assert.Single(rule.Findings);
        Assert.Equal("example.finding-rule", finding.Code.Value);
        Assert.Equal("example.high", finding.Severity.Value);
        Assert.Equal("protocol.remediation-example", finding.Remediation.Value);

        var expectedFiles = new[]
        {
            "ContractSliceA.Proof.dll",
            "MeAndAI.Protocol.Domain.dll",
            "MeAndAI.Protocol.Conformance.Abstractions.dll",
            "MeAndAI.Protocol.Conformance.dll",
            "Markdig.dll",
        };
        Assert.Equal(expectedFiles, manifest.ArtifactFiles.Select(file => file.FileName));

        var artifact = Assert.Single(manifest.ArtifactFiles, file =>
            file.FileName == "ContractSliceA.Proof.dll");
        Assert.Equal(1, artifact.ByteLength);
        Assert.Equal(ProbeDigest, artifact.ArtifactDigest.Value);

        var component = Assert.Single(
            manifest.Components,
            current => current.Component.ComponentKey == "protocol.activation-proof.test");
        Assert.Equal("1", component.Component.ComponentVersion);
        Assert.Equal(
            "MeAndAI.Protocol.Conformance.Tests",
            component.Component.AssemblyName);
        Assert.Equal(
            "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof",
            component.Component.TypeName);
    }

    [Fact]
    [Trait("Scenario", "TEST-0210")]
    [Trait("ContractSlice", "A")]
    public void Enforces_canonical_multi_fragment_rule_provenance()
    {
        var source = CreateMinimalRuleManifest();
        var canonicalManifest = CanonicalManifestWriter.Write(source);
        var manifest = FinalizedPolicyManifest.ParseCanonical(canonicalManifest);
        var rehydrated = CanonicalManifestWriter.Write(manifest);
        Assert.Equal(canonicalManifest, rehydrated);

        Assert.Throws<ArgumentException>(() => CreateRule(1));
        Assert.Throws<ArgumentException>(() => NormativeFragmentDeclaration.Create(
            "docs/rules/rule-1.md",
            "6e340b9cffb37a989ca544e6bb780a2c78901d3fb",
            "rule-fragment",
            1,
            2,
            "protocol.normative-fragment.legacy",
            2,
            ExactSha256Digest.Parse(ProbeDigest)));
    }

    private static ParsedCanonicalManifest CreateMinimalRuleManifest()
    {
        return new ParsedCanonicalManifest(
            CatalogAuthorityKind.QualificationSlice,
            "0000000000000000000000000000000000000001",
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
            CreateSlice());
    }

    private static CatalogSliceDeclaration CreateSlice()
    {
        return CatalogSliceDeclaration.Create(
            "protocol.catalog-slice.test-rule",
            "1",
            "0.0.0",
            CatalogVersion.Create(1),
            new[] { CreateRule() });
    }

    private static RuleDeclaration CreateRule(int normativeFragmentCount = 2)
    {
        return RuleDeclaration.Create(
            RuleId.Parse("RULE-00001"),
            RuleRevision.Create(1),
            CatalogVersion.Create(1),
            ExactSha256Digest.Parse(ProbeDigest),
            CreateNormativeFragments(normativeFragmentCount),
            new[]
            {
                TestScenarioId.Parse("TEST-00001"),
                TestScenarioId.Parse("TEST-00002"),
            },
            ResolveComponentIdentity("protocol.runtime.domain"),
            CreateEvidenceSlots(),
            CreateEvidenceSlots(),
            new[]
            {
                ExpectedSelectorDeclaration.Create(
                    "protocol.selector-1",
                    "protocol.slot-1",
                    "protocol.selector.schema",
                    ResolveComponentIdentity("protocol.runtime.conformance"),
                    new[]
                    {
                        QualifiedEvidenceReferenceKind.ContextProof,
                    },
                    new[]
                    {
                        FindingCode.Parse("example.finding-rule"),
                    }),
            },
            new[]
            {
                SubjectRole.ProtocolAuthoritySelfConsumer,
                SubjectRole.Consumer,
            },
            SurfaceSet.Create(
                new[] { SurfaceKind.Provider, SurfaceKind.Repository }),
            new[] { SnapshotKind.ExactCommit },
            new[] { ProtocolOperation.Conformance },
            new[]
            {
                FindingDeclaration.Create(
                    FindingCode.Parse("example.finding-rule"),
                    FindingSeverity.Parse("example.high"),
                    RemediationKey.Parse("protocol.remediation-example"),
                    new[] { QualifiedEvidenceReferenceKind.ContextProof },
                    new[] { QualifiedEvidenceReferenceKind.Root }),
            },
            new[] { EvaluationFailureCode.Parse("example.failure") },
            "1.0.0",
            "2.0.0",
            "3.0.0",
            new[] { "protocol.compatibility.example" });
    }

    private static IReadOnlyList<NormativeFragmentDeclaration> CreateNormativeFragments(
        int normativeFragmentCount)
    {
        var fragments = new List<NormativeFragmentDeclaration>(2)
        {
            NormativeFragmentDeclaration.Create(
                "docs/rules/rule-1.md",
                "6e340b9cffb37a989ca544e6bb780a2c78901d3fb",
                "rule-fragment",
                1,
                2,
                "protocol.normative-fragment.utf8-lines.v1",
                2,
                ExactSha256Digest.Parse(
                    "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d")),
        };

        if (normativeFragmentCount > 1)
        {
            fragments.Add(
                NormativeFragmentDeclaration.Create(
                    "docs/rules/rule-1-metadata.md",
                    "6e340b9cffb37a989ca544e6bb780a2c78901d3fb",
                    "rule-metadata",
                    10,
                    20,
                    "protocol.normative-fragment.utf8-lines.v1",
                    2,
                    ExactSha256Digest.Parse(
                        "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d")));
        }

        return fragments;
    }

    private static EvidenceSlotDeclaration[] CreateEvidenceSlots()
    {
        return
        [
            CreateEvidenceSlot(),
        ];
    }

    private static EvidenceSlotDeclaration CreateEvidenceSlot()
    {
        return EvidenceSlotDeclaration.Create(
            "protocol.slot-1",
            EvidenceRequirement.Create(
                "protocol.domain.example",
                SurfaceKind.Provider,
                "protocol.requirement-kind",
                "protocol.completeness-contract",
                "protocol.payload.schema",
                "1.0.0",
                new[] { EvidenceConsistencyClass.ExactSnapshot }),
            SurfaceSet.Create(new[] { SurfaceKind.Repository, SurfaceKind.Provider }),
            "protocol.slot-material-role",
            "protocol.selector-1",
            new[]
            {
                CapabilityContractIdentity.Create(
                    "protocol.example.capability",
                    "1.0.0",
                    ResolveComponentIdentity("protocol.runtime.conformance-abstractions")),
            });
    }

    private static ComponentTypeIdentity ResolveComponentIdentity(string componentKey) =>
        componentKey switch
        {
            "protocol.activation-proof.test" =>
                ComponentTypeIdentity.Create(
                    "protocol.activation-proof.test",
                    "1",
                    "MeAndAI.Protocol.Conformance.Tests",
                    "MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"),
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

    private static IReadOnlyList<ArtifactFileBinding> CreateArtifacts()
    {
        return new[]
        {
            ArtifactFileBinding.Create("ContractSliceA.Proof.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
            ArtifactFileBinding.Create(
                "MeAndAI.Protocol.Domain.dll",
                1,
                ExactSha256Digest.Parse(ProbeDigest)),
            ArtifactFileBinding.Create(
                "MeAndAI.Protocol.Conformance.Abstractions.dll",
                1,
                ExactSha256Digest.Parse(ProbeDigest)),
            ArtifactFileBinding.Create(
                "MeAndAI.Protocol.Conformance.dll",
                1,
                ExactSha256Digest.Parse(ProbeDigest)),
            ArtifactFileBinding.Create("Markdig.dll", 1, ExactSha256Digest.Parse(ProbeDigest)),
        };
    }

    private static IReadOnlyList<ComponentArtifactBinding> CreateComponents()
    {
        return new[]
        {
            ComponentArtifactBinding.Create(
                ResolveComponentIdentity("protocol.activation-proof.test"),
                "ContractSliceA.Proof.dll"),
            ComponentArtifactBinding.Create(
                ResolveComponentIdentity("protocol.runtime.domain"),
                "MeAndAI.Protocol.Domain.dll"),
            ComponentArtifactBinding.Create(
                ResolveComponentIdentity("protocol.runtime.conformance-abstractions"),
                "MeAndAI.Protocol.Conformance.Abstractions.dll"),
            ComponentArtifactBinding.Create(
                ResolveComponentIdentity("protocol.runtime.conformance"),
                "MeAndAI.Protocol.Conformance.dll"),
            ComponentArtifactBinding.Create(
                ResolveComponentIdentity("protocol.runtime.markdig"),
                "Markdig.dll"),
        };
    }
}
