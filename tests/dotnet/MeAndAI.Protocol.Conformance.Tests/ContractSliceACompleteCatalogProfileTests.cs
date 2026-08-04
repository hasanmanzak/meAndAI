using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceACompleteCatalogProfileTests
{
    private const string ProfileName =
        "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string InventoryDigest =
        "c013e4b9937f225163f58e41b893600b87d88faf6340678a79242041443f8af3";
    private static readonly ReviewedAuthorityPermalink Authority =
        ReviewedAuthorityPermalink.Create(
            "https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228");

    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_provider_profile_genesis_catalog_inventory_digest_and_added_transitions()
    {
        var predecessor = ContractSliceAFullManifestGraphTests.CreateManifest();
        var rules = predecessor.Slice!.Rules;
        var profile = Profile(EnforcementPhase.Audit, rules.Skip(2));
        var catalog = Catalog(rules, Added(rules), [profile]);
        var parsed = predecessor with
        {
            AuthorityKind = CatalogAuthorityKind.CompleteProtocolSnapshot,
            Slice = null,
            CompleteCatalog = catalog,
        };

        var bytes = CanonicalManifestWriter.Write(parsed);
        var finalized = FinalizedPolicyManifest.ParseCanonical(bytes);
        Assert.Equal(bytes, CanonicalManifestWriter.Write(finalized));
        Assert.Equal(Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant(),
            finalized.ManifestDigest.Value);
        Assert.Equal(CatalogAuthorityKind.CompleteProtocolSnapshot, finalized.AuthorityKind);
        Assert.Null(finalized.Slice);
        var complete = Assert.IsType<CompleteCatalogDeclaration>(finalized.CompleteCatalog);
        Assert.Equal("0.17.0", complete.ProtocolVersion);
        Assert.Equal(1, complete.CatalogVersion.Value);
        Assert.Equal(CatalogPredecessorKind.Genesis, complete.Predecessor.Kind);
        Assert.Equal(InventoryDigest, complete.CompleteInventoryDigest.Value);
        Assert.Equal(InventoryDigest, IndependentInventoryDigest(rules));
        Assert.Equal(ProfileName, complete.BaselineProfileName);
        Assert.Equal(["RULE-0001", "RULE-0002", "RULE-0003", "RULE-0004", "RULE-0005"],
            complete.Rules.Select(rule => rule.RuleId.Value));
        Assert.All(complete.Rules, rule => Assert.Equal(1, rule.RuleRevision.Value));
        Assert.Equal(5, complete.Transitions.Count);
        Assert.All(complete.Transitions, transition =>
        {
            Assert.Equal(RuleTransitionKind.Added, transition.Kind);
            Assert.Null(transition.PreviousRevision);
            Assert.Equal(Authority, transition.ReviewedAuthority);
        });
        var projectedProfile = Assert.Single(complete.NamedProfiles);
        Assert.Equal(ProfileName, projectedProfile.Name);
        Assert.Equal(SubjectRole.Consumer, projectedProfile.Axes.SubjectRole);
        Assert.Equal(ProtocolOperation.Conformance, projectedProfile.Axes.Operation);
        Assert.Equal(SnapshotKind.ExactCommit, projectedProfile.Axes.SnapshotKind);
        Assert.Equal([SurfaceKind.Provider], projectedProfile.Axes.Surfaces.Values);
        Assert.Equal(EnforcementPhase.Audit, projectedProfile.Axes.EnforcementPhase);
        Assert.Equal(["RULE-0003", "RULE-0004", "RULE-0005"],
            projectedProfile.RuleIds.Select(ruleId => ruleId.Value));
        AssertCanonicalOrder(Encoding.UTF8.GetString(bytes));

        RejectWrite(predecessor with
        {
            AuthorityKind = CatalogAuthorityKind.CompleteProtocolSnapshot,
            CompleteCatalog = catalog,
        });
        RejectWrite(predecessor with
        {
            AuthorityKind = CatalogAuthorityKind.CompleteProtocolSnapshot,
            Slice = null,
        });
        var mutatedDigest = Encoding.UTF8.GetString(bytes).Replace(
            InventoryDigest,
            $"{InventoryDigest[..^1]}4",
            StringComparison.Ordinal);
        Assert.Throws<FormatException>(() =>
            FinalizedPolicyManifest.ParseCanonical(Encoding.UTF8.GetBytes(mutatedDigest)));

        RejectCatalog(rules, Added(rules), [Profile(EnforcementPhase.Audit, rules.Skip(3))]);
        RejectCatalog(rules, Added(rules), [Profile(EnforcementPhase.Audit, rules.Skip(1))]);
        RejectCatalog(rules, Added(rules).Skip(1), [profile]);
        RejectCatalog(rules, Added(rules).Append(RuleTransitionDeclaration.Added(
            RuleId.Parse("RULE-9999"), RuleRevision.Create(1), Authority)), [profile]);
        RejectCatalog(rules,
            [RuleTransitionDeclaration.Unchanged(rules[0].RuleId, rules[0].RuleRevision, Authority),
             .. Added(rules).Skip(1)], [profile]);
        _ = Catalog(rules, Added(rules), [Profile(EnforcementPhase.FullBlocking, rules.Skip(2))]);
    }

    private static CompleteCatalogDeclaration Catalog(
        IReadOnlyList<RuleDeclaration> rules,
        IEnumerable<RuleTransitionDeclaration> transitions,
        IEnumerable<NamedProfileDeclaration> profiles) =>
        CompleteCatalogDeclaration.Create("0.17.0", CatalogVersion.Create(1),
            CatalogPredecessorBinding.Genesis(), ProfileName, rules, transitions, profiles);

    private static NamedProfileDeclaration Profile(
        EnforcementPhase phase,
        IEnumerable<RuleDeclaration> rules) =>
        NamedProfileDeclaration.Create(ProfileName,
            ExecutionProfile.Create(SubjectRole.Consumer, ProtocolOperation.Conformance,
                SnapshotKind.ExactCommit, SurfaceSet.Create([SurfaceKind.Provider]), phase),
            rules.Select(rule => rule.RuleId));

    private static RuleTransitionDeclaration[] Added(IReadOnlyList<RuleDeclaration> rules) =>
        rules.Select(rule => RuleTransitionDeclaration.Added(
            rule.RuleId, rule.RuleRevision, Authority)).ToArray();

    private static void RejectCatalog(
        IReadOnlyList<RuleDeclaration> rules,
        IEnumerable<RuleTransitionDeclaration> transitions,
        IEnumerable<NamedProfileDeclaration> profiles) =>
        Assert.ThrowsAny<ArgumentException>(() => Catalog(rules, transitions, profiles));

    private static void RejectWrite(ParsedCanonicalManifest manifest) =>
        Assert.Throws<InvalidOperationException>(() => CanonicalManifestWriter.Write(manifest));

    private static string IndependentInventoryDigest(IReadOnlyList<RuleDeclaration> rules)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("meandai.complete-rule-inventory.v1\n"));
        Span<byte> number = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(number, (uint)rules.Count);
        stream.Write(number);
        foreach (var rule in rules)
        {
            stream.Write(Encoding.ASCII.GetBytes(rule.RuleId.Value));
            BinaryPrimitives.WriteUInt32BigEndian(number, (uint)rule.RuleRevision.Value);
            stream.Write(number);
        }
        Assert.Equal(104, stream.Length);
        return Convert.ToHexString(SHA256.HashData(stream.ToArray())).ToLowerInvariant();
    }

    private static void AssertCanonicalOrder(string json)
    {
        var root = new[] { "\"schema\"", "\"authorityKind\"", "\"sourceCommit\"",
            "\"protocolVersion\"", "\"catalogVersion\"", "\"completeCatalog\"",
            "\"schemaRegistry\"", "\"activationProofContract\"", "\"artifactFiles\"", "\"components\"" };
        Assert.True(root.Select(token => json.IndexOf(token, StringComparison.Ordinal))
            .SequenceEqual(root.Select(token => json.IndexOf(token, StringComparison.Ordinal)).Order()));
        var catalogStart = json.IndexOf("\"completeCatalog\"", StringComparison.Ordinal);
        var fields = new[] { "\"predecessor\"", "\"completeInventoryDigest\"",
            "\"baselineProfileName\"", "\"rules\"", "\"transitions\"", "\"namedProfiles\"" };
        Assert.True(fields.Select(token => json.IndexOf(token, catalogStart, StringComparison.Ordinal))
            .SequenceEqual(fields.Select(token => json.IndexOf(token, catalogStart, StringComparison.Ordinal)).Order()));
    }
}
