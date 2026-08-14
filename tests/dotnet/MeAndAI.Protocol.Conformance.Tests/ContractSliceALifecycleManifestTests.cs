using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceALifecycleManifestTests
{
    private const string LifecycleMessage =
        "A complete catalog contains an invalid active-rule lifecycle.";
    private const string CompatibilityMessage =
        "A named profile must contain exactly its compatible rules.";
    private const string MembershipMessage =
        "A named profile references a rule outside the catalog.";

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_rule_lifecycle_against_transitions_and_active_profiles()
    {
        var manifest = ContractSliceATransitionManifestTests
            .CreateMixedTransitionManifest();
        var source = Assert.IsType<CompleteCatalogDeclaration>(
            manifest.CompleteCatalog);

        AssertOriginalCarrier(source);

        var introducedCurrent = WithRuleLifecycle(
            source,
            "RULE-0005",
            "0.18.0",
            null,
            null);
        Assert.Equal(
            "0.18.0",
            Rule(introducedCurrent, "RULE-0005").IntroducedIn);
        Assert.Equal(
            RuleTransitionKind.Added,
            Transition(introducedCurrent, "RULE-0005").Kind);

        var deprecatedEarlier = WithRuleLifecycle(
            source,
            "RULE-0003",
            Rule(source, "RULE-0003").IntroducedIn,
            "0.17.0",
            null);
        AssertDeprecatedActive(deprecatedEarlier, "0.17.0");

        var deprecatedCurrent = WithRuleLifecycle(
            source,
            "RULE-0003",
            Rule(source, "RULE-0003").IntroducedIn,
            "0.18.0",
            null);
        AssertDeprecatedActive(deprecatedCurrent, "0.18.0");

        AssertCatalogFailure(
            () => WithRuleLifecycle(
                source,
                "RULE-0005",
                "0.19.0",
                null,
                null),
            "rules",
            LifecycleMessage);
        var futureDeprecated = AssertCatalogFailure(
            () => WithRuleLifecycle(
                source,
                "RULE-0003",
                Rule(source, "RULE-0003").IntroducedIn,
                "0.19.0",
                null),
            "rules",
            LifecycleMessage);
        AssertCatalogFailure(
            () => WithRuleLifecycle(
                source,
                "RULE-0003",
                Rule(source, "RULE-0003").IntroducedIn,
                Rule(source, "RULE-0003").DeprecatedIn,
                "0.18.0"),
            "rules",
            LifecycleMessage);

        var profile = Assert.Single(deprecatedCurrent.NamedProfiles);
        var missingDeprecatedRule = NamedProfileDeclaration.Create(
            profile.Name,
            profile.Axes,
            profile.RuleIds.Where(ruleId => ruleId.Value != "RULE-0003"));
        AssertCatalogFailure(
            () => CreateCatalog(
                deprecatedCurrent,
                deprecatedCurrent.Rules,
                [missingDeprecatedRule]),
            "profiles",
            CompatibilityMessage);

        var containingRetiredRule = NamedProfileDeclaration.Create(
            profile.Name,
            profile.Axes,
            profile.RuleIds.Append(RuleId.Parse("RULE-0004")));
        AssertCatalogFailure(
            () => CreateCatalog(source, source.Rules, [containingRetiredRule]),
            "profiles",
            MembershipMessage);

        AssertReaderLifecycleFailure(
            manifest with { CompleteCatalog = deprecatedCurrent },
            futureDeprecated);
    }

    private static void AssertOriginalCarrier(CompleteCatalogDeclaration catalog)
    {
        Assert.Equal("0.18.0", catalog.ProtocolVersion);
        Assert.Equal("0.17.0", Rule(catalog, "RULE-0005").IntroducedIn);
        Assert.Equal(
            RuleTransitionKind.Added,
            Transition(catalog, "RULE-0005").Kind);
        Assert.DoesNotContain(
            catalog.Rules,
            rule => rule.RuleId.Value == "RULE-0004");
        Assert.Equal(
            RuleTransitionKind.Retired,
            Transition(catalog, "RULE-0004").Kind);
        Assert.DoesNotContain(
            Assert.Single(catalog.NamedProfiles).RuleIds,
            ruleId => ruleId.Value == "RULE-0004");
    }

    private static void AssertDeprecatedActive(
        CompleteCatalogDeclaration catalog,
        string deprecatedIn)
    {
        var rule = Rule(catalog, "RULE-0003");
        Assert.Equal(deprecatedIn, rule.DeprecatedIn);
        Assert.Null(rule.RetiredIn);
        Assert.Equal(
            RuleTransitionKind.Unchanged,
            Transition(catalog, "RULE-0003").Kind);
        Assert.Contains(
            Assert.Single(catalog.NamedProfiles).RuleIds,
            ruleId => ruleId.Value == "RULE-0003");
    }

    private static CompleteCatalogDeclaration WithRuleLifecycle(
        CompleteCatalogDeclaration source,
        string ruleId,
        string introducedIn,
        string? deprecatedIn,
        string? retiredIn)
    {
        var rules = source.Rules.Select(rule =>
            rule.RuleId.Value == ruleId
                ? CloneRule(
                    rule,
                    introducedIn,
                    deprecatedIn,
                    retiredIn)
                : rule);
        return CreateCatalog(source, rules, source.NamedProfiles);
    }

    private static CompleteCatalogDeclaration CreateCatalog(
        CompleteCatalogDeclaration source,
        IEnumerable<RuleDeclaration> rules,
        IEnumerable<NamedProfileDeclaration> profiles) =>
        CompleteCatalogDeclaration.Create(
            source.ProtocolVersion,
            source.CatalogVersion,
            source.Predecessor,
            source.BaselineProfileName,
            rules,
            source.Transitions,
            profiles);

    private static RuleDeclaration CloneRule(
        RuleDeclaration rule,
        string introducedIn,
        string? deprecatedIn,
        string? retiredIn) =>
        RuleDeclaration.Create(
            rule.RuleId,
            rule.RuleRevision,
            rule.CatalogVersion,
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
            introducedIn,
            deprecatedIn,
            retiredIn,
            rule.CompatibilityAliases);

    private static ArgumentException AssertCatalogFailure(
        Func<CompleteCatalogDeclaration> action,
        string parameterName,
        string message)
    {
        var exception = Assert.Throws<ArgumentException>(() => action());
        Assert.Equal(parameterName, exception.ParamName);
        Assert.Equal(
            new ArgumentException(message, parameterName).Message,
            exception.Message);
        return exception;
    }

    private static void AssertReaderLifecycleFailure(
        ParsedCanonicalManifest manifest,
        ArgumentException expectedInner)
    {
        var canonicalBytes = CanonicalManifestWriter.Write(manifest);
        var finalized = FinalizedPolicyManifest.ParseCanonical(canonicalBytes);
        Assert.Equal(canonicalBytes, CanonicalManifestWriter.Write(finalized));

        const string original = "\"deprecatedIn\":\"0.18.0\"";
        const string replacement = "\"deprecatedIn\":\"0.19.0\"";
        var text = Encoding.UTF8.GetString(canonicalBytes);
        Assert.Equal(1, CountOccurrences(text, original));
        var mutated = Encoding.UTF8.GetBytes(text.Replace(
            original,
            replacement,
            StringComparison.Ordinal));
        Assert.Equal((byte)'\n', mutated[^1]);

        var outer = Assert.Throws<FormatException>(() =>
            FinalizedPolicyManifest.ParseCanonical(mutated));
        Assert.Equal("A policy manifest value is not canonical.", outer.Message);
        var inner = Assert.IsType<ArgumentException>(outer.InnerException);
        Assert.Equal(expectedInner.ParamName, inner.ParamName);
        Assert.Equal(expectedInner.Message, inner.Message);
    }

    private static RuleDeclaration Rule(
        CompleteCatalogDeclaration catalog,
        string ruleId) =>
        catalog.Rules.Single(rule => rule.RuleId.Value == ruleId);

    private static RuleTransitionDeclaration Transition(
        CompleteCatalogDeclaration catalog,
        string ruleId) =>
        catalog.Transitions.Single(transition =>
            transition.RuleId.Value == ruleId);

    private static int CountOccurrences(string source, string value)
    {
        var count = 0;
        var offset = 0;
        while ((offset = source.IndexOf(
            value,
            offset,
            StringComparison.Ordinal)) >= 0)
        {
            count++;
            offset += value.Length;
        }
        return count;
    }
}
