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
}
