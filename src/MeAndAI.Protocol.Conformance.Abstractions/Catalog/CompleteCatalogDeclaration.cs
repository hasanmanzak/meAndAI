using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CompleteCatalogDeclaration
{
    private CompleteCatalogDeclaration(
        string protocolVersion,
        CatalogVersion catalogVersion,
        CatalogPredecessorBinding predecessor,
        ExactSha256Digest completeInventoryDigest,
        string baselineProfileName,
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<RuleTransitionDeclaration> transitions,
        IReadOnlyList<NamedProfileDeclaration> namedProfiles)
    {
        ProtocolVersion = protocolVersion;
        CatalogVersion = catalogVersion;
        Predecessor = predecessor;
        CompleteInventoryDigest = completeInventoryDigest;
        BaselineProfileName = baselineProfileName;
        Rules = rules;
        Transitions = transitions;
        NamedProfiles = namedProfiles;
    }

    public string ProtocolVersion { get; }

    public CatalogVersion CatalogVersion { get; }

    public CatalogPredecessorBinding Predecessor { get; }

    public ExactSha256Digest CompleteInventoryDigest { get; }

    public string BaselineProfileName { get; }

    public IReadOnlyList<RuleDeclaration> Rules { get; }

    public IReadOnlyList<RuleTransitionDeclaration> Transitions { get; }

    public IReadOnlyList<NamedProfileDeclaration> NamedProfiles { get; }

    public static CompleteCatalogDeclaration Create(
        string protocolVersion,
        CatalogVersion catalogVersion,
        CatalogPredecessorBinding predecessor,
        string baselineProfileName,
        IEnumerable<RuleDeclaration> rules,
        IEnumerable<RuleTransitionDeclaration> transitions,
        IEnumerable<NamedProfileDeclaration> namedProfiles)
    {
        var canonicalProtocolVersion = DeclarationValidation.ProtocolVersion(
            protocolVersion,
            nameof(protocolVersion));
        ArgumentNullException.ThrowIfNull(catalogVersion);
        ArgumentNullException.ThrowIfNull(predecessor);
        ValidatePredecessorVersion(catalogVersion, predecessor);
        var canonicalBaseline = DeclarationValidation.Token(
            baselineProfileName,
            nameof(baselineProfileName));
        var canonicalRules = CatalogSliceDeclaration.CanonicalRules(
            rules,
            nameof(rules));
        CatalogSliceDeclaration.ValidateRuleVersions(
            catalogVersion,
            canonicalRules);
        ValidateRuleLifecycle(canonicalProtocolVersion, canonicalRules);

        var canonicalTransitions = DeclarationValidation.Canonicalize(
            transitions,
            nameof(transitions),
            item => item.RuleId.Value,
            StringComparer.Ordinal);
        var canonicalProfiles = DeclarationValidation.Canonicalize(
            namedProfiles,
            nameof(namedProfiles),
            item => item.Name,
            StringComparer.Ordinal,
            requireNonEmpty: true);
        if (!canonicalProfiles.Any(profile =>
            string.Equals(
                profile.Name,
                canonicalBaseline,
                StringComparison.Ordinal)))
        {
            throw new ArgumentException(
                "The baseline profile must name a declared profile.",
                nameof(baselineProfileName));
        }

        ValidateProfileMembership(canonicalRules, canonicalProfiles);
        ValidateTransitions(predecessor, canonicalRules, canonicalTransitions);
        ValidateProfileCompatibility(canonicalRules, canonicalProfiles);

        return new CompleteCatalogDeclaration(
            canonicalProtocolVersion,
            catalogVersion,
            predecessor,
            ComputeInventoryDigest(canonicalRules),
            canonicalBaseline,
            canonicalRules,
            canonicalTransitions,
            canonicalProfiles);
    }

    private static void ValidatePredecessorVersion(
        CatalogVersion catalogVersion,
        CatalogPredecessorBinding predecessor)
    {
        if (predecessor.Kind.Equals(CatalogPredecessorKind.Existing) &&
            predecessor.CatalogVersion!.CompareTo(catalogVersion) >= 0)
        {
            throw new ArgumentException(
                "An existing predecessor catalog version must be lower than the current catalog version.",
                nameof(predecessor));
        }
    }

    private static ExactSha256Digest ComputeInventoryDigest(
        IReadOnlyList<RuleDeclaration> rules)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes(
            "meandai.complete-rule-inventory.v1\n"));
        Span<byte> buffer = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(buffer, checked((uint)rules.Count));
        stream.Write(buffer);

        foreach (var rule in rules)
        {
            stream.Write(Encoding.ASCII.GetBytes(rule.RuleId.Value));
            BinaryPrimitives.WriteUInt32BigEndian(
                buffer,
                checked((uint)rule.RuleRevision.Value));
            stream.Write(buffer);
        }

        return ExactSha256Digest.FromHashBytes(
            SHA256.HashData(stream.ToArray()));
    }

    private static void ValidateRuleLifecycle(
        string protocolVersion,
        IEnumerable<RuleDeclaration> rules)
    {
        if (rules.Any(rule =>
            rule.RetiredIn is not null ||
            DeclarationValidation.CompareProtocolVersions(
                rule.IntroducedIn,
                protocolVersion) > 0 ||
            (rule.DeprecatedIn is not null &&
                DeclarationValidation.CompareProtocolVersions(
                    rule.DeprecatedIn,
                    protocolVersion) > 0)))
        {
            throw new ArgumentException(
                "A complete catalog contains an invalid active-rule lifecycle.",
                nameof(rules));
        }
    }

    private static void ValidateProfileMembership(
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<NamedProfileDeclaration> profiles)
    {
        var ruleMap = rules.ToDictionary(
            rule => rule.RuleId.Value,
            StringComparer.Ordinal);
        foreach (var profile in profiles)
        {
            if (profile.RuleIds.Any(ruleId => !ruleMap.ContainsKey(ruleId.Value)))
            {
                throw new ArgumentException(
                    "A named profile references a rule outside the catalog.",
                    nameof(profiles));
            }
        }
    }

    private static void ValidateTransitions(
        CatalogPredecessorBinding predecessor,
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<RuleTransitionDeclaration> transitions)
    {
        if (predecessor.Kind.Equals(CatalogPredecessorKind.Genesis))
        {
            ValidateGenesisTransitions(predecessor, rules, transitions);
            return;
        }

        ValidateExistingTransitions(rules, transitions);
    }

    private static void ValidateExistingTransitions(
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<RuleTransitionDeclaration> transitions)
    {
        var currentRules = rules.ToDictionary(
            rule => rule.RuleId.Value,
            StringComparer.Ordinal);
        var representedCurrentRules = new HashSet<string>(StringComparer.Ordinal);
        foreach (var transition in transitions)
        {
            if (transition.Kind.Equals(RuleTransitionKind.Retired))
            {
                if (currentRules.ContainsKey(transition.RuleId.Value))
                {
                    throw InvalidExistingTransitions(nameof(transitions));
                }

                continue;
            }

            if (!currentRules.TryGetValue(transition.RuleId.Value, out var currentRule) ||
                !representedCurrentRules.Add(transition.RuleId.Value) ||
                transition.CurrentRevision is null ||
                !transition.CurrentRevision.Equals(currentRule.RuleRevision))
            {
                throw InvalidExistingTransitions(nameof(transitions));
            }
        }

        if (representedCurrentRules.Count != currentRules.Count)
        {
            throw InvalidExistingTransitions(nameof(transitions));
        }
    }

    private static ArgumentException InvalidExistingTransitions(string parameterName) =>
        new(
            "An existing catalog requires exactly one current transition per current rule and Retired transitions only for absent rules.",
            parameterName);

    private static void ValidateGenesisTransitions(
        CatalogPredecessorBinding predecessor,
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<RuleTransitionDeclaration> transitions)
    {
        if (!predecessor.Kind.Equals(CatalogPredecessorKind.Genesis))
        {
            return;
        }

        if (predecessor.CatalogVersion is not null ||
            predecessor.ManifestDigest is not null ||
            predecessor.CompleteInventoryDigest is not null ||
            transitions.Count != rules.Count)
        {
            throw new ArgumentException("This increment supports only complete genesis transitions.", nameof(transitions));
        }

        for (var index = 0; index < rules.Count; index++)
        {
            var rule = rules[index];
            var transition = transitions[index];
            if (!transition.RuleId.Equals(rule.RuleId) ||
                !transition.Kind.Equals(RuleTransitionKind.Added) ||
                transition.PreviousRevision is not null ||
                !Equals(transition.CurrentRevision, rule.RuleRevision) ||
                transition.ReviewedAuthority is null)
            {
                throw new ArgumentException(
                    "A complete genesis catalog requires one Added transition per current rule.",
                    nameof(transitions));
            }
        }
    }

    private static void ValidateProfileCompatibility(
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<NamedProfileDeclaration> profiles)
    {
        foreach (var profile in profiles)
        {
            var compatible = rules.Where(rule =>
                rule.SubjectRoles.Contains(profile.Axes.SubjectRole) &&
                rule.Operations.Contains(profile.Axes.Operation) &&
                rule.SnapshotKinds.Contains(profile.Axes.SnapshotKind) &&
                rule.Surfaces.Values.Intersect(profile.Axes.Surfaces.Values).Any())
                .Select(rule => rule.RuleId);
            if (!profile.RuleIds.SequenceEqual(compatible))
            {
                throw new ArgumentException(
                    "A named profile must contain exactly its compatible rules.",
                    nameof(profiles));
            }
        }
    }
}
