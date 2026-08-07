using System.Text;
using System.Text.Json;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceATransitionManifestTests
{
    private const string ProfileName = "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string ManifestDigest = "6fb963fcdf35683f2172ea62e383401f36f5c41660c59e0c594852ccb64108df";
    private const string PredecessorInventoryDigest = "52cf1f9c6ecc7e8b652d047f595bb4c66fac53735f9637cb3edbd0c54c8e8554";
    private static readonly ReviewedAuthorityPermalink Authority = ReviewedAuthorityPermalink.Create(
        "https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228");

    private sealed record Field(string Name, string Value);
    private sealed record Mutation(string Original, string Replacement);

    [Fact]
    [Trait("ContractSlice", "A")]
    public void Enforces_exact_unchanged_added_revised_and_retired_transition_shapes()
    {
        var parsedExisting = CreateMixedTransitionManifest();
        AssertCarrier(
            parsedExisting.AuthorityKind,
            parsedExisting.Slice,
            parsedExisting.CompleteCatalog,
            parsedExisting.Components);

        var canonicalBytes = CanonicalManifestWriter.Write(parsedExisting);

        var finalized = FinalizedPolicyManifest.ParseCanonical(canonicalBytes);
        Assert.Equal(canonicalBytes, CanonicalManifestWriter.Write(finalized));
        AssertCarrier(
            finalized.AuthorityKind,
            finalized.Slice,
            finalized.CompleteCatalog,
            finalized.Components);
        AssertReaderVectors(canonicalBytes, finalized.CompleteCatalog!);
        AssertCatalogVectors(parsedExisting.CompleteCatalog!);
    }

    internal static ParsedCanonicalManifest CreateMixedTransitionManifest()
    {
        var basis = ContractSliceAFullManifestGraphTests.CreateManifest();
        var sourceRules = Assert.IsType<CatalogSliceDeclaration>(basis.Slice).Rules;
        var currentVersion = CatalogVersion.Create(2);
        var rules = sourceRules
            .Where(rule => rule.RuleId.Value != "RULE-0004")
            .Select(rule => CloneRule(
                rule,
                RuleRevision.Create(rule.RuleId.Value == "RULE-0002" ? 2 : 1),
                currentVersion))
            .ToArray();
        var byId = rules.ToDictionary(rule => rule.RuleId.Value, StringComparer.Ordinal);
        var transitions = new[]
        {
            RuleTransitionDeclaration.Unchanged(byId["RULE-0001"].RuleId, RuleRevision.Create(1), null),
            RuleTransitionDeclaration.Revised(byId["RULE-0002"].RuleId, RuleRevision.Create(1), RuleRevision.Create(2), Authority),
            RuleTransitionDeclaration.Unchanged(byId["RULE-0003"].RuleId, RuleRevision.Create(1), Authority),
            RuleTransitionDeclaration.Retired(RuleId.Parse("RULE-0004"), RuleRevision.Create(1), Authority),
            RuleTransitionDeclaration.Added(byId["RULE-0005"].RuleId, RuleRevision.Create(1), Authority),
        };
        var catalog = CompleteCatalogDeclaration.Create(
            "0.18.0",
            currentVersion,
            CatalogPredecessorBinding.Existing(
                CatalogVersion.Create(1),
                ExactSha256Digest.Parse(ManifestDigest),
                ExactSha256Digest.Parse(PredecessorInventoryDigest)),
            ProfileName,
            rules,
            transitions,
            [CreateProfile(rules)]);

        return basis with
        {
            AuthorityKind = CatalogAuthorityKind.CompleteProtocolSnapshot,
            Slice = null,
            CompleteCatalog = catalog,
            Components = basis.Components.Where(binding =>
                binding.Component.ComponentKey != "protocol.evaluator.rule-0004").ToArray(),
        };
    }

    private static RuleDeclaration CloneRule(
        RuleDeclaration rule,
        RuleRevision currentRevision,
        CatalogVersion currentCatalogVersion) =>
        RuleDeclaration.Create(
            rule.RuleId,
            currentRevision,
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

    private static NamedProfileDeclaration CreateProfile(IEnumerable<RuleDeclaration> rules) =>
        NamedProfileDeclaration.Create(
            ProfileName,
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.Conformance,
                SnapshotKind.ExactCommit,
                SurfaceSet.Create([SurfaceKind.Provider]),
                EnforcementPhase.Audit),
            rules.Where(rule => rule.RuleId.Value is "RULE-0003" or "RULE-0005")
                .Select(rule => rule.RuleId));

    private static void AssertCarrier(
        CatalogAuthorityKind authorityKind,
        CatalogSliceDeclaration? slice,
        CompleteCatalogDeclaration? completeCatalog,
        IReadOnlyList<ComponentArtifactBinding> components)
    {
        Assert.Equal(CatalogAuthorityKind.CompleteProtocolSnapshot, authorityKind);
        Assert.Null(slice);
        Assert.DoesNotContain(
            components,
            binding => binding.Component.ComponentKey == "protocol.evaluator.rule-0004");
        var catalog = Assert.IsType<CompleteCatalogDeclaration>(completeCatalog);
        Assert.Equal("0.18.0", catalog.ProtocolVersion);
        Assert.Equal(2, catalog.CatalogVersion.Value);
        Assert.Equal(CatalogPredecessorKind.Existing, catalog.Predecessor.Kind);
        Assert.Equal(1, catalog.Predecessor.CatalogVersion!.Value);
        Assert.Equal(ManifestDigest, catalog.Predecessor.ManifestDigest!.Value);
        Assert.Equal(PredecessorInventoryDigest, catalog.Predecessor.CompleteInventoryDigest!.Value);
        Assert.Equal(
            [("RULE-0001", 1), ("RULE-0002", 2), ("RULE-0003", 1), ("RULE-0005", 1)],
            catalog.Rules.Select(rule => (rule.RuleId.Value, rule.RuleRevision.Value)));
        var expected = new (string, string, int?, int?, string?)[]
        {
            ("RULE-0001", "unchanged", 1, 1, null),
            ("RULE-0002", "revised", 1, 2, Authority.Value),
            ("RULE-0003", "unchanged", 1, 1, Authority.Value),
            ("RULE-0004", "retired", 1, null, Authority.Value),
            ("RULE-0005", "added", null, 1, Authority.Value),
        };
        Assert.Equal(expected, catalog.Transitions.Select(transition => (
            transition.RuleId.Value,
            transition.Kind.Value,
            transition.PreviousRevision?.Value,
            transition.CurrentRevision?.Value,
            transition.ReviewedAuthority?.Value)));
        var profile = Assert.Single(catalog.NamedProfiles);
        Assert.Equal(ProfileName, profile.Name);
        Assert.Equal(EnforcementPhase.Audit, profile.Axes.EnforcementPhase);
        Assert.Equal([SurfaceKind.Provider], profile.Axes.Surfaces.Values);
        Assert.Equal(["RULE-0003", "RULE-0005"], profile.RuleIds.Select(rule => rule.Value));
    }

    private static void AssertReaderVectors(
        byte[] canonicalBytes,
        CompleteCatalogDeclaration catalog)
    {
        var mutations = ReaderMutations(catalog.Transitions);
        Assert.Equal(91, mutations.Count);
        Assert.Equal(91, mutations.Distinct().Count());
        foreach (var mutation in mutations)
        {
            var mutated = ReplaceUniqueAndPreflight(canonicalBytes, mutation);
            Assert.Throws<FormatException>(() => FinalizedPolicyManifest.ParseCanonical(mutated));
        }
    }

    private static IReadOnlyList<Mutation> ReaderMutations(
        IReadOnlyList<RuleTransitionDeclaration> transitions)
    {
        var unchanged = Fields(Transition(transitions, "RULE-0003"));
        var added = Fields(Transition(transitions, "RULE-0005"));
        var revised = Fields(Transition(transitions, "RULE-0002"));
        var retired = Fields(Transition(transitions, "RULE-0004"));
        var mutations = new List<Mutation>();
        AddRequiredFieldMutations(mutations, unchanged, 4);
        mutations.Add(Change(unchanged, Insert(unchanged, 5, unchanged[4])));
        mutations.Add(Change(unchanged, Replace(unchanged, 4, new Field("reviewedAuthority", "null"))));
        mutations.Add(Change(unchanged, Replace(unchanged, 4, new Field("reviewedAuthority", "1"))));
        AddRequiredFieldMutations(mutations, added, 4);
        AddRequiredFieldMutations(mutations, revised, 5);
        AddRequiredFieldMutations(mutations, retired, 4);
        mutations.Add(Change(added, Replace(added, 1, new Field("kind", Quote("unknown")))));
        mutations.Add(Change(added, Insert(added, 2, new Field("previousRevision", "1"))));
        mutations.Add(Change(retired, Insert(retired, 3, new Field("currentRevision", "1"))));
        mutations.Add(Change(unchanged, Replace(unchanged, 3, new Field("currentRevision", "2"))));
        mutations.Add(Change(revised, Replace(revised, 3, new Field("currentRevision", "1"))));
        AddAdjacentSwaps(mutations, unchanged);
        AddAdjacentSwaps(mutations, added);
        AddAdjacentSwaps(mutations, revised);
        AddAdjacentSwaps(mutations, retired);
        mutations.Add(Change(revised, [.. revised, new Field("unexpected", "true")]));
        return mutations;
    }

    private static void AddRequiredFieldMutations(
        ICollection<Mutation> mutations,
        Field[] fields,
        int requiredCount)
    {
        for (var index = 0; index < requiredCount; index++)
        {
            var field = fields[index];
            var wrongType = field.Value[0] == '"' ? "1" : Quote("wrong");
            mutations.Add(Change(fields, Remove(fields, index)));
            mutations.Add(Change(fields, Insert(fields, index + 1, field)));
            mutations.Add(Change(fields, Replace(fields, index, new Field(field.Name, "null"))));
            mutations.Add(Change(fields, Replace(fields, index, new Field(field.Name, wrongType))));
        }
    }

    private static void AddAdjacentSwaps(ICollection<Mutation> mutations, Field[] fields)
    {
        for (var index = 0; index < fields.Length - 1; index++)
        {
            var swapped = fields.ToArray();
            (swapped[index], swapped[index + 1]) = (swapped[index + 1], swapped[index]);
            mutations.Add(Change(fields, swapped));
        }
    }

    private static void AssertCatalogVectors(CompleteCatalogDeclaration catalog)
    {
        var transitions = catalog.Transitions.ToArray();
        var rule1 = Rule(catalog, "RULE-0001");
        var rule2 = Rule(catalog, "RULE-0002");
        var rule3 = Rule(catalog, "RULE-0003");
        var rule5 = Rule(catalog, "RULE-0005");
        var cases = new[]
        {
            transitions.Where(transition => transition.RuleId.Value != "RULE-0005").ToArray(),
            [.. transitions, RuleTransitionDeclaration.Unchanged(rule3.RuleId, rule3.RuleRevision, Authority)],
            ReplaceByRuleId(transitions, "RULE-0004", RuleTransitionDeclaration.Added(
                RuleId.Parse("RULE-9998"), RuleRevision.Create(1), Authority)),
            ReplaceByRuleId(transitions, "RULE-0003", RuleTransitionDeclaration.Retired(
                rule3.RuleId, rule3.RuleRevision, Authority)),
            ReplaceByRuleId(transitions, "RULE-0001", RuleTransitionDeclaration.Unchanged(
                rule1.RuleId, RuleRevision.Create(2), null)),
            ReplaceByRuleId(transitions, "RULE-0005", RuleTransitionDeclaration.Added(
                rule5.RuleId, RuleRevision.Create(2), Authority)),
            ReplaceByRuleId(transitions, "RULE-0002", RuleTransitionDeclaration.Revised(
                rule2.RuleId, RuleRevision.Create(1), RuleRevision.Create(3), Authority)),
        };
        Assert.Equal(7, cases.Length);
        foreach (var transitionCase in cases)
        {
            var exception = Assert.Throws<ArgumentException>(() =>
                CreateCatalog(catalog, transitionCase));
            Assert.Equal("transitions", exception.ParamName);
        }
    }

    private static CompleteCatalogDeclaration CreateCatalog(
        CompleteCatalogDeclaration source,
        IEnumerable<RuleTransitionDeclaration> transitions) =>
        CompleteCatalogDeclaration.Create(
            source.ProtocolVersion,
            source.CatalogVersion,
            source.Predecessor,
            source.BaselineProfileName,
            source.Rules,
            transitions,
            source.NamedProfiles);

    private static RuleTransitionDeclaration[] ReplaceByRuleId(
        IEnumerable<RuleTransitionDeclaration> transitions,
        string ruleId,
        RuleTransitionDeclaration replacement) =>
        transitions.Select(transition =>
            transition.RuleId.Value == ruleId ? replacement : transition).ToArray();

    private static RuleDeclaration Rule(CompleteCatalogDeclaration catalog, string ruleId) =>
        catalog.Rules.Single(rule => rule.RuleId.Value == ruleId);

    private static RuleTransitionDeclaration Transition(
        IReadOnlyList<RuleTransitionDeclaration> transitions,
        string ruleId) =>
        transitions.Single(transition => transition.RuleId.Value == ruleId);

    private static Field[] Fields(RuleTransitionDeclaration transition)
    {
        var fields = new List<Field>
        {
            new("ruleId", Quote(transition.RuleId.Value)),
            new("kind", Quote(transition.Kind.Value)),
        };
        if (transition.PreviousRevision is not null)
            fields.Add(new Field("previousRevision", transition.PreviousRevision.Value.ToString()));
        if (transition.CurrentRevision is not null)
            fields.Add(new Field("currentRevision", transition.CurrentRevision.Value.ToString()));
        if (transition.ReviewedAuthority is not null)
            fields.Add(new Field("reviewedAuthority", Quote(transition.ReviewedAuthority.Value)));
        return [.. fields];
    }

    private static Mutation Change(Field[] original, Field[] replacement) =>
        new(Object(original), Object(replacement));

    private static Field[] Remove(Field[] fields, int index) =>
        [.. fields[..index], .. fields[(index + 1)..]];

    private static Field[] Insert(Field[] fields, int index, Field field) =>
        [.. fields[..index], field, .. fields[index..]];

    private static Field[] Replace(Field[] fields, int index, Field field) =>
        [.. fields[..index], field, .. fields[(index + 1)..]];

    private static string Object(IEnumerable<Field> fields) =>
        "{" + string.Join(",", fields.Select(field => Quote(field.Name) + ":" + field.Value)) + "}";

    private static string Quote(string value) => "\"" + value + "\"";

    private static byte[] ReplaceUniqueAndPreflight(byte[] source, Mutation mutation)
    {
        Assert.NotEqual(mutation.Original, mutation.Replacement);
        var text = Encoding.UTF8.GetString(source);
        Assert.Equal(1, CountOccurrences(text, mutation.Original));
        var mutated = Encoding.UTF8.GetBytes(text.Replace(
            mutation.Original,
            mutation.Replacement,
            StringComparison.Ordinal));
        Assert.Equal((byte)'\n', mutated[^1]);
        using var document = JsonDocument.Parse(mutated);
        Assert.Equal(JsonValueKind.Object, document.RootElement.ValueKind);
        return mutated;
    }

    private static int CountOccurrences(string source, string value)
    {
        var count = 0;
        var offset = 0;
        while ((offset = source.IndexOf(value, offset, StringComparison.Ordinal)) >= 0)
        {
            count++;
            offset += value.Length;
        }
        return count;
    }
}
