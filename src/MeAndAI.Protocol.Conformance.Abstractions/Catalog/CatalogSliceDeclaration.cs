namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CatalogSliceDeclaration
{
    private CatalogSliceDeclaration(
        string sliceKey,
        string sliceVersion,
        string protocolVersion,
        CatalogVersion catalogVersion,
        IReadOnlyList<RuleDeclaration> rules)
    {
        SliceKey = sliceKey;
        SliceVersion = sliceVersion;
        ProtocolVersion = protocolVersion;
        CatalogVersion = catalogVersion;
        Rules = rules;
    }

    public string SliceKey { get; }

    public string SliceVersion { get; }

    public string ProtocolVersion { get; }

    public CatalogVersion CatalogVersion { get; }

    public IReadOnlyList<RuleDeclaration> Rules { get; }

    public static CatalogSliceDeclaration Create(
        string sliceKey,
        string sliceVersion,
        string protocolVersion,
        CatalogVersion catalogVersion,
        IEnumerable<RuleDeclaration> rules)
    {
        ArgumentNullException.ThrowIfNull(catalogVersion);
        var canonicalRules = CanonicalRules(rules, nameof(rules));
        ValidateRuleVersions(catalogVersion, canonicalRules);

        return new CatalogSliceDeclaration(
            DeclarationValidation.Token(sliceKey, nameof(sliceKey)),
            DeclarationValidation.Version(sliceVersion, nameof(sliceVersion)),
            DeclarationValidation.ProtocolVersion(
                protocolVersion,
                nameof(protocolVersion)),
            catalogVersion,
            canonicalRules);
    }

    internal static IReadOnlyList<RuleDeclaration> CanonicalRules(
        IEnumerable<RuleDeclaration>? rules,
        string parameterName) =>
        DeclarationValidation.Canonicalize(
            rules,
            parameterName,
            item => item.RuleId.Value,
            StringComparer.Ordinal);

    internal static void ValidateRuleVersions(
        CatalogVersion catalogVersion,
        IEnumerable<RuleDeclaration> rules)
    {
        if (rules.Any(rule => !rule.CatalogVersion.Equals(catalogVersion)))
        {
            throw new ArgumentException(
                "Every rule must belong to the enclosing catalog version.",
                nameof(rules));
        }
    }
}
