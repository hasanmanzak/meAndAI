using MeAndAI.Protocol.Domain;

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
            registry.DemandProjectors.Count != 0 ||
            registry.AdmissionProofContracts.Count != 0)
        {
            throw new ArgumentException("Payload schemas, slot requirements, or capabilities are not closed.", nameof(rules));
        }

        if (registry.Parsers.Count != 0)
        {
            ValidateParserRecordSlotClosure(registry, canonicalRules, slots);
            return;
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

    private static void ValidateParserRecordSlotClosure(ReleaseSchemaRegistry registry, IReadOnlyList<RuleDeclaration> rules, IReadOnlyList<EvidenceSlotDeclaration> slots)
    {
        var evaluationSlots = rules.SelectMany(rule => rule.EvaluationSlots).ToArray();
        if (registry.PayloadSchemas.Count != 2 || registry.Parsers.Count != 1 || registry.Indexes.Count != 2 ||
            slots.Count != 2 || evaluationSlots.Length != 2)
        {
            throw new ArgumentException("The parser and protocol-record graph is not exact.", nameof(rules));
        }
        var governedSchema = registry.PayloadSchemas[0];
        var treeSchema = registry.PayloadSchemas[1];
        var parser = registry.Parsers[0];
        var recordIndex = registry.Indexes[0];
        var treeIndex = registry.Indexes[1];
        var governedSlot = evaluationSlots[0];
        var treeSlot = evaluationSlots[1];
        var parserInput = parser.Inputs.Count == 1 ? parser.Inputs[0] : null;
        var recordInput = recordIndex.Inputs.Count == 1 ? recordIndex.Inputs[0] : null;
        var treeInput = treeIndex.Inputs.Count == 1 ? treeIndex.Inputs[0] : null;
        var governedModel = governedSchema.OutputModel;
        var markdownModel = parser.OutputModel;
        var treeModel = treeSchema.OutputModel;
        if (governedSchema.SchemaKey != "protocol.governed-text" || governedSchema.SchemaVersion != "1" ||
            !ComponentEquals(governedSchema.Codec, "protocol.codec.governed-text", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec") ||
            !ModelEquals(governedModel, "protocol.model.source-text", "protocol.type.model.source-text", "MeAndAI.Protocol.Policy.Models.SourceTextModel") ||
            governedSchema.MaxBindingsPerInstruction != 200_000 ||
            governedSchema.MaxRetainedCanonicalBytesPerInstruction != 67_108_864 ||
            !BudgetEquals(governedSchema.Budget, 4_194_304, 256, 500_000, 5_000_000) ||
            !CodesEqual(governedSchema.CodecFailureCodes, "protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-utf8",
                "protocol.codec.noncanonical-encoding", "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded") ||
            treeSchema.SchemaKey != "protocol.repository-tree" || treeSchema.SchemaVersion != "1" ||
            !ComponentEquals(treeSchema.Codec, "protocol.codec.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec") ||
            !ModelEquals(treeModel, "protocol.model.repository-tree", "protocol.type.model.repository-tree", "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel") ||
            treeSchema.MaxBindingsPerInstruction != 1 ||
            treeSchema.MaxRetainedCanonicalBytesPerInstruction != 16_777_216 ||
            !BudgetEquals(treeSchema.Budget, 16_777_216, 64, 200_000, 2_000_000) ||
            !CodesEqual(treeSchema.CodecFailureCodes, "protocol.codec.embedded-identity-mismatch", "protocol.codec.invalid-repository-tree",
                "protocol.codec.payload-location-mismatch", "protocol.codec.resource-limit-exceeded") ||
            parser.ParserKey != "protocol.parser.markdown" || parser.ParserVersion != "1" ||
            !ComponentEquals(parser.Parser, "protocol.parser.markdown", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser") ||
            !InputEquals(parserInput, governedModel, 1, 1) ||
            !ModelEquals(markdownModel, "protocol.model.markdown-document", "protocol.type.model.markdown-document", "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel") ||
            !BudgetEquals(parser.Budget, 4_194_304, 256, 500_000, 5_000_000) ||
            !CodesEqual(parser.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted", "protocol.model.invalid-markdown") ||
            recordIndex.IndexKey != "protocol.index.protocol-record" || recordIndex.IndexVersion != "1" ||
            !ComponentEquals(recordIndex.Indexer, "protocol.index.protocol-record", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex") ||
            !recordIndex.InvocationScope.Equals(IndexInvocationScope.PerContext) ||
            !InputEquals(recordInput, markdownModel, 0, null) ||
            !CapabilityEquals(recordIndex.OutputCapability, "protocol.capability.protocol-record-index", "protocol.type.capability.protocol-record-index", "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex") ||
            !BudgetEquals(recordIndex.Budget, 67_108_864, 256, 1_000_000, 10_000_000) ||
            !CodesEqual(recordIndex.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted", "protocol.index.record-unavailable") ||
            treeIndex.IndexKey != "protocol.index.repository-tree" || treeIndex.IndexVersion != "1" ||
            !ComponentEquals(treeIndex.Indexer, "protocol.index.repository-tree", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex") ||
            !treeIndex.InvocationScope.Equals(IndexInvocationScope.PerContext) ||
            !InputEquals(treeInput, treeModel, 1, 1) ||
            !CapabilityEquals(treeIndex.OutputCapability, "protocol.capability.repository-tree", "protocol.type.capability.repository-tree", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree") ||
            !BudgetEquals(treeIndex.Budget, 16_777_216, 64, 200_000, 2_000_000) ||
            !CodesEqual(treeIndex.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted", "protocol.index.repository-tree-unavailable") ||
            !SlotEquals(governedSlot, "protocol.slot.repository-governed-text", "protocol.requirement.repository-governed-text",
                "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", [SurfaceKind.Repository, SurfaceKind.Provider],
                "protocol.material.governed-text", "protocol.target.repository-governed-body-set", recordIndex.OutputCapability) ||
            !SlotEquals(treeSlot, "protocol.slot.repository-tree", "protocol.requirement.repository-tree", "protocol.evidence.repository-tree",
                "protocol.completeness.full-tree", "protocol.repository-tree", [SurfaceKind.Repository], "protocol.material.repository-tree", "protocol.target.repository-snapshot", treeIndex.OutputCapability) ||
            !BudgetEquals(registry.CacheBudget, 512, 67_108_864, 128, 2_000_000) ||
            registry.CacheBudget.MaxConcurrentDecodeAttempts != 8 || registry.CacheBudget.MaxConcurrentIndexAttempts != 4 ||
            !registry.CacheBudget.RetentionPolicy.Equals(CacheRetentionPolicy.RetainLowestCanonicalKeys))
        {
            throw new ArgumentException("The parser and protocol-record graph is not exact.", nameof(rules));
        }
    }
    private static bool ModelEquals(ModelContractIdentity model, string key, string componentKey, string type) =>
        model.ModelKey == key && model.ModelVersion == "1" && ComponentEquals(model.ImplementationType, componentKey, "MeAndAI.Protocol.Policy", type);
    private static bool CapabilityEquals(CapabilityContractIdentity capability, string key, string componentKey, string type) =>
        capability.CapabilityKey == key && capability.CapabilityVersion == "1" && ComponentEquals(capability.InterfaceType, componentKey, "MeAndAI.Protocol.Conformance.Abstractions", type);
    private static bool InputEquals(ComponentInputDeclaration? input, ModelContractIdentity model, int minimum, int? maximum) =>
        input?.Model?.Equals(model) == true && input.Capability is null && input.MinimumCount == minimum && input.MaximumCount == maximum;
    private static bool BudgetEquals(SemanticResourceBudget budget, long bytes, int depth, long nodes, long complexity) =>
        budget.MaxBytes == bytes && budget.MaxDepth == depth && budget.MaxNodes == nodes && budget.MaxComplexity == complexity;
    private static bool BudgetEquals(SessionCacheBudget budget, int decodeEntries, long decodeBytes, int indexEntries, long indexNodes) =>
        budget.MaxDecodeEntries == decodeEntries && budget.MaxDecodeCanonicalBytes == decodeBytes && budget.MaxIndexEntries == indexEntries && budget.MaxIndexNodes == indexNodes;
    private static bool CodesEqual(IEnumerable<string> actual, params string[] expected) => actual.SequenceEqual(expected, StringComparer.Ordinal);
    private static bool SlotEquals(EvidenceSlotDeclaration slot, string key, string requirement, string kind,
        string completeness, string schema, IReadOnlyList<SurfaceKind> surfaces, string material, string target, CapabilityContractIdentity capability) =>
        slot.SlotKey == key && slot.Requirement.Key == requirement && slot.Requirement.Surface.Equals(SurfaceKind.Repository) &&
        slot.Requirement.Kind == kind && slot.Requirement.CompletenessContract == completeness && slot.Requirement.PayloadSchemaKey == schema &&
        slot.Requirement.PayloadSchemaVersion == "1" && slot.Requirement.AcceptedConsistencyClasses.SequenceEqual(
            [EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.BoundedNonAtomicObservation]) &&
        slot.ProfileSurfaces.Values.SequenceEqual(surfaces) && slot.MaterialRole == material && slot.TargetSelectorKey == target &&
        slot.Capabilities.Count == 1 && slot.Capabilities[0].Equals(capability);

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
