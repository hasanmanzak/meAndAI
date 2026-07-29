using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceCatalogIdentityTests
{
    private const string ExpectedMetadata =
        "protocol.decision-record.required-structure.v1\0" +
        "TEST-0005\0" +
        "governance.decision.record-structure-incomplete\0" +
        "high\0blocking\n" +
        "protocol.feature-record.required-pair.v1\0" +
        "TEST-0004\0" +
        "governance.feature.record-set-incomplete\0" +
        "high\0blocking\n";

    private const string ExpectedDigest =
        "ff99d63fb1fed8cff276edb5833e0d65ca554367ead998ec2bc365ecc65ce047";

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void CurrentCatalogHasExactSchemaInventoryMetadataAndDigest()
    {
        var catalog = GovernanceRuleCatalog.Current;
        var identity = catalog.Identity;

        Assert.Equal("0.17.0", catalog.Version.Value);
        Assert.Equal(1, identity.Schema);
        Assert.Equal(
            [
                (
                    "protocol.decision-record.required-structure.v1",
                    "TEST-0005",
                    "governance.decision.record-structure-incomplete",
                    "high",
                    "blocking"),
                (
                    "protocol.feature-record.required-pair.v1",
                    "TEST-0004",
                    "governance.feature.record-set-incomplete",
                    "high",
                    "blocking"),
            ],
            identity.Rules.Select(rule =>
                (
                    rule.RuleId,
                    rule.CanonicalScenarioId,
                    rule.FindingCode,
                    rule.Severity.Value,
                    rule.Enforcement.Value)));
        Assert.Equal(
            Encoding.UTF8.GetBytes(ExpectedMetadata),
            identity.GetCanonicalMetadataBytes());
        Assert.Equal(ExpectedDigest, identity.MetadataDigest.Value);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void CatalogRejectsReorderedChangedOrIncompleteMetadata()
    {
        var exact = ExactRules();
        var invalidCatalogs = new[]
        {
            exact.Reverse().ToArray(),
            [exact[0]],
            [exact[0], exact[0]],
            [
                exact[0],
                exact[1] with { RuleId = "protocol.changed.v1" },
            ],
            [
                exact[0],
                exact[1] with { CanonicalScenarioId = "TEST-9999" },
            ],
            [
                exact[0],
                exact[1] with { FindingCode = "governance.changed" },
            ],
            [
                exact[0],
                exact[1] with { Severity = GovernanceSeverity.Medium },
            ],
            [
                exact[0],
                exact[1] with { Enforcement = GovernanceEnforcement.Advisory },
            ],
        };

        foreach (var invalid in invalidCatalogs)
        {
            Assert.Throws<ArgumentException>(() =>
                GovernanceRuleCatalog.CreateBoundedIdentity(invalid));
        }

        Assert.Empty(typeof(GovernanceCatalogIdentity).GetConstructors());
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void CatalogRejectsAnUnrelatedButLexicallyValidDigest()
    {
        var unrelated = ExactSha256Digest.Parse(
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");

        Assert.Throws<ArgumentException>(() =>
            GovernanceRuleCatalog.Current.Identity.RequireMatchingDigest(
                unrelated));
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void BothProfilesReuseTheSameCatalogRuleInstances()
    {
        var catalog = GovernanceRuleCatalog.Current;
        var authorityRules = catalog.GetApplicableRules(
            GovernanceProfileId.ProtocolAuthority);
        var consumerRules = catalog.GetApplicableRules(
            GovernanceProfileId.Consumer);

        Assert.Equal(2, authorityRules.Length);
        Assert.Equal(2, consumerRules.Length);
        Assert.Same(authorityRules[0], consumerRules[0]);
        Assert.Same(authorityRules[1], consumerRules[1]);
    }

    private static GovernanceCatalogRuleIdentity[] ExactRules() =>
    [
        new(
            "protocol.decision-record.required-structure.v1",
            "TEST-0005",
            "governance.decision.record-structure-incomplete",
            GovernanceSeverity.High,
            GovernanceEnforcement.Blocking),
        new(
            "protocol.feature-record.required-pair.v1",
            "TEST-0004",
            "governance.feature.record-set-incomplete",
            GovernanceSeverity.High,
            GovernanceEnforcement.Blocking),
    ];
}
