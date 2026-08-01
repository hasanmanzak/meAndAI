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
        var canonicalRules = rules.ToArray();
        var slots = canonicalRules.SelectMany(
            rule => rule.ApplicabilitySlots.Concat(rule.EvaluationSlots)).ToArray();
        var schemas = registry.PayloadSchemas.Select(schema => (schema.SchemaKey, schema.SchemaVersion)).ToHashSet();
        if (!schemas.SetEquals(slots.Select(slot => (
                slot.Requirement.PayloadSchemaKey, slot.Requirement.PayloadSchemaVersion))) ||
            registry.Parsers.Count != 0 ||
            registry.DemandProjectors.Count != 0 ||
            registry.AdmissionProofContracts.Count != 0)
        {
            throw new ArgumentException("Payload schemas, slot requirements, or capabilities are not closed.", nameof(rules));
        }

        var capabilitySlots = slots.Where(slot => slot.Capabilities.Count != 0).ToArray();
        if (registry.Indexes.Count == 0)
        {
            if (capabilitySlots.Length != 0)
            {
                throw new ArgumentException(
                    "Payload schemas, slot requirements, or capabilities are not closed.", nameof(rules));
            }

            return;
        }

        var index = registry.Indexes.Count == 1 ? registry.Indexes[0] : null;
        var input = index?.Inputs.Count == 1 ? index.Inputs[0] : null;
        var model = input?.Model;
        var capabilitySlot = capabilitySlots.Length == 1 ? capabilitySlots[0] : null;
        var budget = index?.Budget;
        if (index is null ||
            capabilitySlot is null ||
            !canonicalRules.SelectMany(rule => rule.EvaluationSlots).Contains(capabilitySlot) ||
            capabilitySlot.SlotKey != "protocol.slot.repository-tree" ||
            capabilitySlot.Capabilities.Count != 1 ||
            index.IndexKey != "protocol.index.repository-tree" ||
            index.IndexVersion != "1" ||
            !ComponentEquals(index.Indexer, "protocol.index.repository-tree", "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex") ||
            !index.InvocationScope.Equals(IndexInvocationScope.PerContext) ||
            model is null ||
            input!.Capability is not null ||
            input.MinimumCount != 1 ||
            input.MaximumCount != 1 ||
            model.ModelKey != "protocol.model.repository-tree" ||
            model.ModelVersion != "1" ||
            !ComponentEquals(model.ImplementationType, "protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel") ||
            index.OutputCapability.CapabilityKey != "protocol.capability.repository-tree" ||
            index.OutputCapability.CapabilityVersion != "1" ||
            !ComponentEquals(index.OutputCapability.InterfaceType, "protocol.type.capability.repository-tree",
                "MeAndAI.Protocol.Conformance.Abstractions",
                "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree") ||
            !index.OutputCapability.Equals(capabilitySlot.Capabilities[0]) ||
            budget is null || budget.MaxBytes != 16_777_216 || budget.MaxDepth != 64 ||
            budget.MaxNodes != 200_000 || budget.MaxComplexity != 2_000_000 ||
            index.FailureCodes.Count != 2 ||
            index.FailureCodes[0].Value != "protocol.budget.exhausted" ||
            index.FailureCodes[1].Value != "protocol.index.repository-tree-unavailable" ||
            !registry.TryGetPayloadSchema("protocol.repository-tree", "1", out var schema) ||
            !schema.OutputModel.Equals(model))
        {
            throw new ArgumentException("The repository-tree index and slot capability graph is not exact.", nameof(rules));
        }
    }

    private static bool ComponentEquals(
        ComponentTypeIdentity component, string key, string assembly, string type) =>
        component.ComponentKey == key &&
        component.ComponentVersion == "1" &&
        component.AssemblyName == assembly &&
        component.TypeName == type;

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
