using System.Collections.Frozen;
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

        _ = UniqueSlots(
            canonicalRules.SelectMany(rule =>
                rule.ApplicabilitySlots.Concat(rule.EvaluationSlots)),
            parameterName);

        return canonicalRules;
    }

    private static EvidenceSlotDeclaration[] UniqueSlots(
        IEnumerable<EvidenceSlotDeclaration> slots,
        string parameterName)
    {
        var unique = new Dictionary<string, EvidenceSlotDeclaration>(StringComparer.Ordinal);
        foreach (var slot in slots)
        {
            if (unique.TryGetValue(slot.SlotKey, out var existing) &&
                !RuleDeclaration.SlotsEqual(existing, slot))
            {
                throw new ArgumentException("A shared SlotKey must have one structural declaration.", parameterName);
            }

            unique[slot.SlotKey] = slot;
        }

        return unique.Values.OrderBy(slot => slot.SlotKey, StringComparer.Ordinal).ToArray();
    }

    internal static ProducerGraphValidationResult ValidateSchemaSlotClosure(ReleaseSchemaRegistry registry, IEnumerable<RuleDeclaration> rules)
    {
        var canonicalRules = rules.ToArray();
        var applicabilitySlots = UniqueSlots(canonicalRules.SelectMany(rule => rule.ApplicabilitySlots), nameof(rules));
        var evaluationSlots = UniqueSlots(canonicalRules.SelectMany(rule => rule.EvaluationSlots), nameof(rules));
        var slots = UniqueSlots(applicabilitySlots.Concat(evaluationSlots), nameof(rules));
        var schemas = registry.PayloadSchemas.Select(schema => (schema.SchemaKey, schema.SchemaVersion)).ToHashSet();
        if (!schemas.SetEquals(slots.Select(slot => (
                slot.Requirement.PayloadSchemaKey, slot.Requirement.PayloadSchemaVersion))))
        {
            throw new ArgumentException("Payload schemas, slot requirements, or capabilities are not closed.", nameof(rules));
        }

        var graph = ValidateProducerGraph(registry, slots);
        ValidateProjectorClosure(registry, applicabilitySlots, evaluationSlots);
        ValidateAdmissionProofClosure(registry, canonicalRules, slots);

        if (registry.Parsers.Count != 0)
        {
            ValidateParserRecordSlotClosure(registry, canonicalRules, slots);
            return graph;
        }

        var capabilitySlots = slots.Where(slot => slot.Capabilities.Count != 0).ToArray();
        if (registry.Indexes.Count == 0)
        {
            if (capabilitySlots.Length != 0)
            {
                throw new ArgumentException(
                    "Payload schemas, slot requirements, or capabilities are not closed.", nameof(rules));
            }

            return graph;
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

        return graph;
    }

    private static ProducerGraphValidationResult ValidateProducerGraph(
        ReleaseSchemaRegistry registry,
        IReadOnlyList<EvidenceSlotDeclaration> slots)
    {
        var nodes = new List<ProducerIdentity>();
        var sortKeys = new List<string>();
        var schemas = new Dictionary<(string, string), int>();
        var models = new Dictionary<(string, string), int>();
        var capabilities = new Dictionary<(string, string), int>();
        static void Own(Dictionary<(string, string), int> owners, (string, string) identity, int id)
        { if (!owners.TryAdd(identity, id)) throw new FormatException("protocol.manifest.producer-owner"); }
        static int Owner(Dictionary<(string, string), int> owners, (string, string) identity) =>
            owners.TryGetValue(identity, out var id) ? id : throw new FormatException("protocol.manifest.producer-owner");
        var id = 0;
        foreach (var schema in registry.PayloadSchemas)
        {
            nodes.Add(new ProducerIdentity("Schema", schema.SchemaKey, schema.SchemaVersion));
            sortKeys.Add($"{schema.Codec.ComponentKey}\0{schema.Codec.ComponentVersion}\0{schema.SchemaKey}\0{schema.SchemaVersion}\00");
            Own(schemas, (schema.SchemaKey, schema.SchemaVersion), id);
            Own(models, (schema.OutputModel.ModelKey, schema.OutputModel.ModelVersion), id++);
        }
        var parserStart = id;
        foreach (var parser in registry.Parsers)
        {
            nodes.Add(new ProducerIdentity("Parser", parser.ParserKey, parser.ParserVersion));
            sortKeys.Add($"{parser.Parser.ComponentKey}\0{parser.Parser.ComponentVersion}\0{parser.ParserKey}\0{parser.ParserVersion}\01");
            Own(models, (parser.OutputModel.ModelKey, parser.OutputModel.ModelVersion), id++);
        }
        var indexStart = id;
        foreach (var index in registry.Indexes)
        {
            nodes.Add(new ProducerIdentity("Index", index.IndexKey, index.IndexVersion));
            sortKeys.Add($"{index.Indexer.ComponentKey}\0{index.Indexer.ComponentVersion}\0{index.IndexKey}\0{index.IndexVersion}\02");
            Own(capabilities, (index.OutputCapability.CapabilityKey, index.OutputCapability.CapabilityVersion), id++);
        }
        var projectorStart = id;
        if (registry.DemandProjectors.Select(item => item.OutputSlotKey).Distinct(StringComparer.Ordinal).Count() !=
            registry.DemandProjectors.Count) throw new FormatException("protocol.manifest.producer-owner");
        foreach (var projector in registry.DemandProjectors)
        {
            nodes.Add(new ProducerIdentity("Projector", projector.ProjectorKey, projector.ProjectorVersion));
            sortKeys.Add($"{projector.Projector.ComponentKey}\0{projector.Projector.ComponentVersion}\0{projector.ProjectorKey}\0{projector.ProjectorVersion}\03");
        }
        var edges = Enumerable.Range(0, nodes.Count).Select(_ => new HashSet<int>()).ToArray();
        var reverse = Enumerable.Range(0, nodes.Count).Select(_ => new HashSet<int>()).ToArray();
        var indegrees = new int[nodes.Count];
        void Link(int source, int target)
        {
            if (edges[source].Add(target)) { reverse[target].Add(source); indegrees[target]++; }
        }
        void ConnectInputs(IEnumerable<ComponentInputDeclaration> inputs, int target)
        {
            foreach (var input in inputs)
            {
                if (input.Model is { } model)
                    Link(Owner(models, (model.ModelKey, model.ModelVersion)), target);
                else if (input.Capability is { } capability)
                    Link(Owner(capabilities, (capability.CapabilityKey, capability.CapabilityVersion)), target);
            }
        }
        for (var i = 0; i < registry.Parsers.Count; i++) ConnectInputs(registry.Parsers[i].Inputs, parserStart + i);
        for (var i = 0; i < registry.Indexes.Count; i++) ConnectInputs(registry.Indexes[i].Inputs, indexStart + i);
        for (var i = 0; i < registry.DemandProjectors.Count; i++)
        {
            var projector = registry.DemandProjectors[i];
            Link(Owner(capabilities, (projector.InputCapability.CapabilityKey, projector.InputCapability.CapabilityVersion)), projectorStart + i);
            var output = slots.FirstOrDefault(slot => slot.SlotKey == projector.OutputSlotKey)
                ?? throw new FormatException("protocol.manifest.projector-slot");
            Link(projectorStart + i, Owner(schemas, (output.Requirement.PayloadSchemaKey, output.Requirement.PayloadSchemaVersion)));
        }
        var seeds = new HashSet<int>();
        foreach (var slot in slots)
        {
            seeds.Add(Owner(schemas, (slot.Requirement.PayloadSchemaKey, slot.Requirement.PayloadSchemaVersion)));
            foreach (var capability in slot.Capabilities)
                seeds.Add(Owner(capabilities, (capability.CapabilityKey, capability.CapabilityVersion)));
        }
        var remaining = (int[])indegrees.Clone();
        var roots = Enumerable.Range(0, nodes.Count).Where(id => remaining[id] == 0).ToArray();
        var pending = new PriorityQueue<int, string>(StringComparer.Ordinal);
        foreach (var root in roots) pending.Enqueue(root, sortKeys[root]);
        var processed = 0;
        while (pending.TryDequeue(out var node, out _))
        {
            processed++;
            foreach (var successor in edges[node])
                if (--remaining[successor] == 0) pending.Enqueue(successor, sortKeys[successor]);
        }
        if (processed != nodes.Count) throw new FormatException("protocol.manifest.producer-cycle");
        var closure = new HashSet<int>(seeds);
        var frontier = new Stack<int>(seeds);
        while (frontier.TryPop(out var node))
        {
            foreach (var predecessor in reverse[node])
                if (closure.Add(predecessor)) frontier.Push(predecessor);
        }
        if (closure.Count != nodes.Count) throw new FormatException("protocol.manifest.producer-unreachable");
        return new ProducerGraphValidationResult(roots.Select(id => nodes[id]).ToFrozenSet());
    }

    private static void ValidateProjectorClosure(
        ReleaseSchemaRegistry registry,
        IReadOnlyList<EvidenceSlotDeclaration> applicability,
        IReadOnlyList<EvidenceSlotDeclaration> evaluation)
    {
        if (registry.DemandProjectors.Count == 0) return;
        var projector = registry.DemandProjectors.Count == 1 ? registry.DemandProjectors[0] : null;
        if (projector is null ||
            projector.ProjectorKey != "protocol.projector.repository-target-resolution-demand" ||
            projector.ProjectorVersion != "1" ||
            !ComponentEquals(projector.Projector, "protocol.projector.repository-target-resolution-demand",
                "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector") ||
            !CapabilityEquals(projector.InputCapability, "protocol.capability.governed-reference-index",
                "protocol.type.capability.governed-reference-index", "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex") ||
            !projector.InputSlotKeys.SequenceEqual(
                ["protocol.slot.provider-governed-text", "protocol.slot.repository-governed-text"], StringComparer.Ordinal) ||
            projector.OutputSlotKey != "protocol.slot.repository-target-resolution" ||
            projector.DemandSchemaKey != "protocol.repository-target-resolution-demand" ||
            projector.DemandSchemaVersion != "1" ||
            !BudgetEquals(projector.Budget, 33_554_432, 64, 100_000, 5_000_000) ||
            !CodesEqual(projector.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted"))
        {
            throw new FormatException("protocol.manifest.projector-value");
        }
        var output = evaluation.FirstOrDefault(slot => slot.SlotKey == projector.OutputSlotKey);
        if (output is null ||
            applicability.Any(slot => slot.SlotKey == projector.OutputSlotKey) ||
            output.Requirement.PayloadSchemaKey != "protocol.repository-target-resolution" ||
            output.Requirement.PayloadSchemaVersion != "1" ||
            projector.InputSlotKeys.Any(key => !evaluation.Any(slot =>
                slot.SlotKey == key && slot.Capabilities.Contains(projector.InputCapability))))
        {
            throw new FormatException("protocol.manifest.projector-slot");
        }
    }

    private static void ValidateAdmissionProofClosure(
        ReleaseSchemaRegistry registry,
        IReadOnlyList<RuleDeclaration> rules,
        IReadOnlyList<EvidenceSlotDeclaration> slots)
    {
        var contracts = registry.AdmissionProofContracts;
        if (contracts.Count == 0)
        {
            return;
        }

        var expectedSurfaces = SurfaceSet.Create(
            slots.SelectMany(slot => slot.ProfileSurfaces.Values).Distinct());
        var expectedMaterialRoles = slots
            .Select(slot => slot.MaterialRole)
            .Distinct(StringComparer.Ordinal)
            .OrderBy(role => role, StringComparer.Ordinal)
            .ToArray();
        var kinds = contracts.Select(contract => contract.Kind.Value)
            .ToHashSet(StringComparer.Ordinal);
        var proofComponents = contracts.Select(contract => (
                contract.ProofComponent.ComponentKey,
                contract.ProofComponent.ComponentVersion))
            .ToHashSet();
        var contractVersions = contracts.Select(contract => contract.ContractVersion).ToHashSet(StringComparer.Ordinal);
        if (contracts.Count != 3 ||
            !kinds.SetEquals(
                new[] { "observed", "failed", "no-input" }) ||
            proofComponents.Count != 3 ||
            contractVersions.Count != 1 ||
            contracts.Any(contract =>
                !contract.Surfaces.Equals(expectedSurfaces) ||
                !contract.MaterialRoles.SequenceEqual(
                    expectedMaterialRoles,
                    StringComparer.Ordinal)))
        {
            throw new ArgumentException(
                "Admission-proof contracts are not closed over kinds, surfaces, and material roles.",
                nameof(rules));
        }
    }

    private static void ValidateParserRecordSlotClosure(ReleaseSchemaRegistry registry, IReadOnlyList<RuleDeclaration> rules, IReadOnlyList<EvidenceSlotDeclaration> slots)
    {
        var evaluationSlots = UniqueSlots(
            rules.SelectMany(rule => rule.EvaluationSlots), nameof(rules));
        var predecessor = registry.PayloadSchemas.Count == 2 && registry.Parsers.Count == 1 &&
            registry.Indexes.Count == 2 && slots.Count == 2 && evaluationSlots.Length == 2;
        var governedReference = registry.PayloadSchemas.Count == 2 && registry.Parsers.Count == 1 &&
            registry.Indexes.Count == 3 && slots.Count == 3 && evaluationSlots.Length == 3;
        var repositoryTarget = registry.PayloadSchemas.Count == 3 && registry.Parsers.Count == 2 &&
            registry.Indexes.Count == 4 && slots.Count == 4 && evaluationSlots.Length == 4;
        if (!predecessor && !governedReference && !repositoryTarget)
        {
            throw new ArgumentException("The parser and protocol-record graph is not exact.", nameof(rules));
        }
        var hasGovernedReference = governedReference || repositoryTarget;
        var governedSchema = registry.PayloadSchemas[0];
        var targetSchema = repositoryTarget ? registry.PayloadSchemas[1] : null;
        var treeSchema = registry.PayloadSchemas[repositoryTarget ? 2 : 1];
        var parser = registry.Parsers[0];
        var targetParser = repositoryTarget ? registry.Parsers[1] : null;
        var governedOffset = hasGovernedReference ? 1 : 0;
        var targetOffset = repositoryTarget ? 1 : 0;
        var governedReferenceIndex = hasGovernedReference ? registry.Indexes[0] : null;
        var recordIndex = registry.Indexes[governedOffset];
        var targetIndex = repositoryTarget ? registry.Indexes[governedOffset + 1] : null;
        var treeIndex = registry.Indexes[governedOffset + targetOffset + 1];
        EvidenceSlotDeclaration RequiredSlot(string key) =>
            evaluationSlots.SingleOrDefault(slot => slot.SlotKey == key) ??
            throw new ArgumentException("The parser and protocol-record graph is not exact.", nameof(rules));
        var providerGovernedSlot = hasGovernedReference ? RequiredSlot("protocol.slot.provider-governed-text") : null;
        var repositoryGovernedSlot = RequiredSlot("protocol.slot.repository-governed-text");
        var targetSlot = repositoryTarget ? RequiredSlot("protocol.slot.repository-target-resolution") : null;
        var treeSlot = RequiredSlot("protocol.slot.repository-tree");
        var parserInput = parser.Inputs.Count == 1 ? parser.Inputs[0] : null;
        var targetParserInput = targetParser?.Inputs.Count == 1 ? targetParser.Inputs[0] : null;
        var governedModelInput = governedReferenceIndex?.Inputs.Count == 2 ? governedReferenceIndex.Inputs[0] : null;
        var governedCapabilityInput = governedReferenceIndex?.Inputs.Count == 2 ? governedReferenceIndex.Inputs[1] : null;
        var recordInput = recordIndex.Inputs.Count == 1 ? recordIndex.Inputs[0] : null;
        var targetMarkdownInput = targetIndex?.Inputs.Count == 3 ? targetIndex.Inputs[0] : null;
        var targetResolutionInput = targetIndex?.Inputs.Count == 3 ? targetIndex.Inputs[1] : null;
        var targetGovernedInput = targetIndex?.Inputs.Count == 3 ? targetIndex.Inputs[2] : null;
        var treeInput = treeIndex.Inputs.Count == 1 ? treeIndex.Inputs[0] : null;
        var governedModel = governedSchema.OutputModel;
        var markdownModel = parser.OutputModel;
        var targetResolutionModel = targetSchema?.OutputModel;
        var targetMarkdownModel = targetParser?.OutputModel;
        var treeModel = treeSchema.OutputModel;
        var governedTopologyExact = hasGovernedReference
            ? governedReferenceIndex is not null &&
              governedReferenceIndex.IndexKey == "protocol.index.governed-reference" && governedReferenceIndex.IndexVersion == "1" &&
              ComponentEquals(governedReferenceIndex.Indexer, "protocol.index.governed-reference", "MeAndAI.Protocol.Policy", "MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex") &&
              governedReferenceIndex.InvocationScope.Equals(IndexInvocationScope.PerPlan) &&
              InputEquals(governedModelInput, markdownModel, 0, null) &&
              InputEquals(governedCapabilityInput, recordIndex.OutputCapability, 1, null) &&
              CapabilityEquals(governedReferenceIndex.OutputCapability, "protocol.capability.governed-reference-index",
                  "protocol.type.capability.governed-reference-index", "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex") &&
              BudgetEquals(governedReferenceIndex.Budget, 67_108_864, 256, 1_000_000, 10_000_000) &&
              CodesEqual(governedReferenceIndex.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted", "protocol.index.reference-unavailable") &&
              SlotEquals(providerGovernedSlot!, "protocol.slot.provider-governed-text", "protocol.requirement.provider-governed-text",
                  "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", SurfaceKind.Provider,
                  [SurfaceKind.Provider], "protocol.material.governed-text", "protocol.target.provider-governed-body-set",
                  [governedReferenceIndex.OutputCapability, recordIndex.OutputCapability]) &&
              SlotEquals(repositoryGovernedSlot, "protocol.slot.repository-governed-text", "protocol.requirement.repository-governed-text",
                  "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", SurfaceKind.Repository,
                  [SurfaceKind.Repository, SurfaceKind.Provider], "protocol.material.governed-text", "protocol.target.repository-governed-body-set",
                  [governedReferenceIndex.OutputCapability, recordIndex.OutputCapability])
            : SlotEquals(repositoryGovernedSlot, "protocol.slot.repository-governed-text", "protocol.requirement.repository-governed-text",
                "protocol.evidence.governed-text-set", "protocol.completeness.all-governed-bodies", "protocol.governed-text", SurfaceKind.Repository,
                [SurfaceKind.Repository, SurfaceKind.Provider], "protocol.material.governed-text", "protocol.target.repository-governed-body-set",
                [recordIndex.OutputCapability]);
        var targetTopologyExact = !repositoryTarget ||
            targetSchema is not null && targetParser is not null && targetIndex is not null && targetSlot is not null &&
            targetResolutionModel is not null && targetMarkdownModel is not null && governedReferenceIndex is not null &&
            targetSchema.SchemaKey == "protocol.repository-target-resolution" && targetSchema.SchemaVersion == "1" &&
            ComponentEquals(targetSchema.Codec, "protocol.codec.repository-target-resolution", "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec") &&
            ModelEquals(targetResolutionModel, "protocol.model.repository-target-resolution",
                "protocol.type.model.repository-target-resolution", "MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel") &&
            targetSchema.MaxBindingsPerInstruction == 1 && targetSchema.MaxRetainedCanonicalBytesPerInstruction == 33_554_432 &&
            BudgetEquals(targetSchema.Budget, 33_554_432, 64, 500_000, 34_054_432) &&
            CodesEqual(targetSchema.CodecFailureCodes, "protocol.codec.embedded-identity-mismatch",
                "protocol.codec.invalid-repository-target-resolution", "protocol.codec.payload-location-mismatch",
                "protocol.codec.resource-limit-exceeded") &&
            targetParser.ParserKey == "protocol.parser.repository-target-markdown" && targetParser.ParserVersion == "1" &&
            ComponentEquals(targetParser.Parser, "protocol.parser.repository-target-markdown", "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser") &&
            InputEquals(targetParserInput, targetResolutionModel, 1, 1) &&
            ModelEquals(targetMarkdownModel, "protocol.model.repository-target-markdown-document-set",
                "protocol.type.model.repository-target-markdown-document-set", "MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel") &&
            BudgetEquals(targetParser.Budget, 33_554_432, 256, 1_000_000, 34_554_432) &&
            CodesEqual(targetParser.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted") &&
            targetIndex.IndexKey == "protocol.index.repository-target-resolution" && targetIndex.IndexVersion == "1" &&
            ComponentEquals(targetIndex.Indexer, "protocol.index.repository-target-resolution", "MeAndAI.Protocol.Policy",
                "MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex") &&
            targetIndex.InvocationScope.Equals(IndexInvocationScope.PerPlan) &&
            InputEquals(targetMarkdownInput, targetMarkdownModel, 0, null) &&
            InputEquals(targetResolutionInput, targetResolutionModel, 0, null) &&
            InputEquals(targetGovernedInput, governedReferenceIndex.OutputCapability, 1, 1) &&
            CapabilityEquals(targetIndex.OutputCapability, "protocol.capability.repository-target-resolution-index",
                "protocol.type.capability.repository-target-resolution-index", "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex") &&
            BudgetEquals(targetIndex.Budget, 67_108_864, 256, 2_000_000, 20_000_000) &&
            CodesEqual(targetIndex.FailureCodes.Select(code => code.Value), "protocol.budget.exhausted",
                "protocol.index.repository-target-resolution-unavailable") &&
            SlotEquals(targetSlot, "protocol.slot.repository-target-resolution", "protocol.requirement.repository-target-resolution",
                "protocol.evidence.repository-target-resolution-set", "protocol.completeness.all-projected-target-resolutions",
                "protocol.repository-target-resolution", SurfaceKind.Repository, [SurfaceKind.Repository, SurfaceKind.Provider],
                "protocol.material.repository-target-resolution", "protocol.target.repository-target-resolution-set",
                [targetIndex.OutputCapability], [EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound]);
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
            !SlotEquals(treeSlot, "protocol.slot.repository-tree", "protocol.requirement.repository-tree", "protocol.evidence.repository-tree",
                "protocol.completeness.full-tree", "protocol.repository-tree", SurfaceKind.Repository, [SurfaceKind.Repository],
                "protocol.material.repository-tree", "protocol.target.repository-snapshot", [treeIndex.OutputCapability]) ||
            !governedTopologyExact ||
            !targetTopologyExact ||
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
    private static bool InputEquals(ComponentInputDeclaration? input, CapabilityContractIdentity capability, int minimum, int? maximum) =>
        input?.Capability?.Equals(capability) == true && input.Model is null && input.MinimumCount == minimum && input.MaximumCount == maximum;
    private static bool BudgetEquals(SemanticResourceBudget budget, long bytes, int depth, long nodes, long complexity) =>
        budget.MaxBytes == bytes && budget.MaxDepth == depth && budget.MaxNodes == nodes && budget.MaxComplexity == complexity;
    private static bool BudgetEquals(SessionCacheBudget budget, int decodeEntries, long decodeBytes, int indexEntries, long indexNodes) =>
        budget.MaxDecodeEntries == decodeEntries && budget.MaxDecodeCanonicalBytes == decodeBytes && budget.MaxIndexEntries == indexEntries && budget.MaxIndexNodes == indexNodes;
    private static bool CodesEqual(IEnumerable<string> actual, params string[] expected) => actual.SequenceEqual(expected, StringComparer.Ordinal);
    private static bool SlotEquals(EvidenceSlotDeclaration slot, string key, string requirement, string kind,
        string completeness, string schema, SurfaceKind requirementSurface, IReadOnlyList<SurfaceKind> surfaces, string material, string target,
        IReadOnlyList<CapabilityContractIdentity> capabilities, IReadOnlyList<EvidenceConsistencyClass>? consistencyClasses = null)
    {
        consistencyClasses ??=
            [EvidenceConsistencyClass.ExactSnapshot, EvidenceConsistencyClass.ObjectVersionBound, EvidenceConsistencyClass.BoundedNonAtomicObservation];
        return slot.SlotKey == key && slot.Requirement.Key == requirement && slot.Requirement.Surface.Equals(requirementSurface) &&
            slot.Requirement.Kind == kind && slot.Requirement.CompletenessContract == completeness && slot.Requirement.PayloadSchemaKey == schema &&
            slot.Requirement.PayloadSchemaVersion == "1" && slot.Requirement.AcceptedConsistencyClasses.SequenceEqual(consistencyClasses) &&
            slot.ProfileSurfaces.Values.SequenceEqual(surfaces) && slot.MaterialRole == material && slot.TargetSelectorKey == target &&
            slot.Capabilities.SequenceEqual(capabilities);
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

internal readonly record struct ProducerIdentity(string Family, string Key, string Version);

internal sealed record ProducerGraphValidationResult(IReadOnlySet<ProducerIdentity> ProducerRootIdentities);
