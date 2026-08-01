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
        string parameterName)
    {
        var canonicalRules = DeclarationValidation.Canonicalize(
            rules,
            parameterName,
            item => item.RuleId.Value,
            StringComparer.Ordinal);

        var slots = new Dictionary<string, EvidenceSlotDeclaration>(StringComparer.Ordinal);
        foreach (var slot in canonicalRules.SelectMany(rule => rule.ApplicabilitySlots.Concat(rule.EvaluationSlots)))
        {
            if (slots.TryGetValue(slot.SlotKey, out var existing) &&
                !RuleDeclaration.SlotsEqual(existing, slot))
            {
                throw new ArgumentException("A shared SlotKey must have one structural declaration.", parameterName);
            }

            slots[slot.SlotKey] = slot;
        }

        return canonicalRules;
    }

    internal static void ValidateSchemaSlotClosure(ReleaseSchemaRegistry registry, IEnumerable<RuleDeclaration> rules)
    {
        var slots = rules.SelectMany(rule => rule.ApplicabilitySlots.Concat(rule.EvaluationSlots)).ToArray();
        var schemas = registry.PayloadSchemas.Select(schema => (schema.SchemaKey, schema.SchemaVersion)).ToHashSet();
        if (slots.Any(slot => slot.Capabilities.Count != 0) ||
            !schemas.SetEquals(slots.Select(slot => (
                slot.Requirement.PayloadSchemaKey, slot.Requirement.PayloadSchemaVersion))))
        {
            throw new ArgumentException("Payload schemas, slot requirements, or capabilities are not closed.", nameof(rules));
        }
    }

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
