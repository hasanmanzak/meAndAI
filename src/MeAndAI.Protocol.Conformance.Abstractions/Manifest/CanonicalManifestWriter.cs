using System.Buffers;
using System.Security.Cryptography;
using System.Text.Json;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class CanonicalManifestWriter
{
    private const string SchemaKey = "protocol.policy-manifest.v1";

    internal static byte[] Write(FinalizedPolicyManifest manifest)
    {
        ArgumentNullException.ThrowIfNull(manifest);

        return Write(new ParsedCanonicalManifest(
            manifest.AuthorityKind,
            manifest.SourceCommit,
            manifest.SchemaRegistry,
            manifest.ActivationProofContract,
            manifest.ArtifactFiles,
            manifest.Components,
            manifest.Slice,
            manifest.CompleteCatalog));
    }

    internal static byte[] Write(ParsedCanonicalManifest manifest)
    {
        ArgumentNullException.ThrowIfNull(manifest);

        var slice = manifest.Slice;
        var complete = manifest.CompleteCatalog;
        var validUnion =
            (manifest.AuthorityKind.Equals(CatalogAuthorityKind.QualificationSlice) &&
             slice is not null && complete is null) ||
            (manifest.AuthorityKind.Equals(CatalogAuthorityKind.CompleteProtocolSnapshot) &&
             slice is null && complete is not null);
        if (!validUnion ||
            (complete is not null && !HasCurrentAddedTransitions(complete)) ||
            manifest.ArtifactFiles.Count == 0 ||
            manifest.Components.Count == 0)
        {
            throw new InvalidOperationException(
                "This writer increment supports only the minimal qualification slice.");
        }

        CatalogSliceDeclaration.ValidateSchemaSlotClosure(
            manifest.SchemaRegistry,
            (slice?.Rules ?? complete!.Rules));

        var buffer = new ArrayBufferWriter<byte>();
        using (var writer = new Utf8JsonWriter(
                   buffer,
                   new JsonWriterOptions
                   {
                       Indented = false,
                       SkipValidation = false,
                   }))
        {
            WriteManifest(writer, manifest);
        }

        var result = GC.AllocateUninitializedArray<byte>(
            buffer.WrittenCount + 1);
        buffer.WrittenSpan.CopyTo(result);
        result[^1] = (byte)'\n';
        return result;
    }

    private static bool HasCurrentAddedTransitions(CompleteCatalogDeclaration catalog)
    {
        if (catalog.Transitions.Count != catalog.Rules.Count)
        {
            return false;
        }

        for (var index = 0; index < catalog.Rules.Count; index++)
        {
            var rule = catalog.Rules[index];
            var transition = catalog.Transitions[index];
            if (!transition.RuleId.Equals(rule.RuleId) ||
                !transition.Kind.Equals(RuleTransitionKind.Added) ||
                transition.PreviousRevision is not null ||
                !Equals(transition.CurrentRevision, rule.RuleRevision) ||
                transition.ReviewedAuthority is null)
            {
                return false;
            }
        }

        return true;
    }

    private static void WriteManifest(
        Utf8JsonWriter writer,
        ParsedCanonicalManifest manifest)
    {
        var slice = manifest.Slice;
        var complete = manifest.CompleteCatalog;
        writer.WriteStartObject();
        WriteCanonicalString(writer, "schema", SchemaKey);
        WriteCanonicalString(
            writer,
            "authorityKind",
            manifest.AuthorityKind.Value);
        WriteCanonicalString(writer, "sourceCommit", manifest.SourceCommit);
        WriteCanonicalString(
            writer,
            "protocolVersion",
            (slice?.ProtocolVersion ?? complete!.ProtocolVersion));
        writer.WriteNumber("catalogVersion", (slice?.CatalogVersion ?? complete!.CatalogVersion).Value);

        if (slice is not null)
        {
            writer.WritePropertyName("slice");
            writer.WriteStartObject();
            WriteCanonicalString(writer, "sliceKey", slice.SliceKey);
            WriteCanonicalString(writer, "sliceVersion", slice.SliceVersion);
            WriteRules(writer, slice.Rules);
            writer.WriteEndObject();
        }
        else
        {
            WriteCompleteCatalog(writer, complete!);
        }

        WriteSchemaRegistry(writer, manifest.SchemaRegistry);
        WriteActivationProof(writer, manifest.ActivationProofContract);
        WriteArtifactFiles(writer, manifest.ArtifactFiles);
        WriteComponents(writer, manifest.Components);
        writer.WriteEndObject();
    }

    private static void WriteCompleteCatalog(Utf8JsonWriter writer, CompleteCatalogDeclaration catalog)
    {
        writer.WritePropertyName("completeCatalog");
        writer.WriteStartObject();
        writer.WritePropertyName("predecessor");
        writer.WriteStartObject();
        WriteCanonicalString(writer, "kind", catalog.Predecessor.Kind.Value);
        if (catalog.Predecessor.Kind.Equals(CatalogPredecessorKind.Existing))
        {
            writer.WriteNumber("catalogVersion", catalog.Predecessor.CatalogVersion!.Value);
            WriteCanonicalString(writer, "manifestDigest", catalog.Predecessor.ManifestDigest!.Value);
            WriteCanonicalString(
                writer,
                "completeInventoryDigest",
                catalog.Predecessor.CompleteInventoryDigest!.Value);
        }
        writer.WriteEndObject();
        WriteCanonicalString(writer, "completeInventoryDigest", catalog.CompleteInventoryDigest.Value);
        WriteCanonicalString(writer, "baselineProfileName", catalog.BaselineProfileName);
        WriteRules(writer, catalog.Rules);
        writer.WritePropertyName("transitions");
        writer.WriteStartArray();
        foreach (var transition in catalog.Transitions)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "ruleId", transition.RuleId.Value);
            WriteCanonicalString(writer, "kind", transition.Kind.Value);
            writer.WriteNumber("currentRevision", transition.CurrentRevision!.Value);
            WriteCanonicalString(writer, "reviewedAuthority", transition.ReviewedAuthority!.Value);
            writer.WriteEndObject();
        }
        writer.WriteEndArray();
        writer.WritePropertyName("namedProfiles");
        writer.WriteStartArray();
        foreach (var profile in catalog.NamedProfiles)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "name", profile.Name);
            writer.WritePropertyName("axes");
            writer.WriteStartObject();
            WriteCanonicalString(writer, "subjectRole", profile.Axes.SubjectRole.Value);
            WriteCanonicalString(writer, "operation", profile.Axes.Operation.Value);
            WriteCanonicalString(writer, "snapshotKind", profile.Axes.SnapshotKind.Value);
            WriteCanonicalStringValues(writer, "surfaces", profile.Axes.Surfaces.Values.Select(item => item.Value));
            WriteCanonicalString(writer, "enforcementPhase", profile.Axes.EnforcementPhase.Value);
            writer.WriteEndObject();
            WriteCanonicalStringValues(writer, "ruleIds", profile.RuleIds.Select(item => item.Value));
            writer.WriteEndObject();
        }
        writer.WriteEndArray();
        writer.WriteEndObject();
    }

    private static void WriteSchemaRegistry(
        Utf8JsonWriter writer,
        ReleaseSchemaRegistry registry)
    {
        writer.WritePropertyName("schemaRegistry");
        writer.WriteStartObject();
        WritePayloadSchemas(writer, registry.PayloadSchemas);
        WriteParsers(writer, registry.Parsers);
        WriteIndexes(writer, registry.Indexes);
        WriteDemandProjectors(writer, registry.DemandProjectors);
        WriteAdmissionProofContracts(
            writer,
            registry.AdmissionProofContracts);

        var budget = registry.CacheBudget;
        writer.WritePropertyName("cacheBudget");
        writer.WriteStartObject();
        writer.WriteNumber("maxDecodeEntries", budget.MaxDecodeEntries);
        writer.WriteNumber(
            "maxDecodeCanonicalBytes",
            budget.MaxDecodeCanonicalBytes);
        writer.WriteNumber("maxIndexEntries", budget.MaxIndexEntries);
        writer.WriteNumber("maxIndexNodes", budget.MaxIndexNodes);
        writer.WriteNumber(
            "maxConcurrentDecodeAttempts",
            budget.MaxConcurrentDecodeAttempts);
        writer.WriteNumber(
            "maxConcurrentIndexAttempts",
            budget.MaxConcurrentIndexAttempts);
        WriteCanonicalString(
            writer,
            "retentionPolicy",
            budget.RetentionPolicy.Value);
        writer.WriteEndObject();
        writer.WriteEndObject();
    }

    private static void WriteDemandProjectors(Utf8JsonWriter writer,
        IReadOnlyList<AcquisitionDemandProjectorDeclaration> projectors)
    {
        writer.WriteStartArray("demandProjectors");
        foreach (var projector in projectors)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "projectorKey", projector.ProjectorKey);
            WriteCanonicalString(writer, "projectorVersion", projector.ProjectorVersion);
            WriteComponentReference(writer, "projector", projector.Projector);
            writer.WritePropertyName("inputCapability");
            WriteCapability(writer, projector.InputCapability);
            WriteCanonicalStringValues(writer, "inputSlotKeys", projector.InputSlotKeys);
            WriteCanonicalString(writer, "outputSlotKey", projector.OutputSlotKey);
            WriteCanonicalString(writer, "demandSchemaKey", projector.DemandSchemaKey);
            WriteCanonicalString(writer, "demandSchemaVersion", projector.DemandSchemaVersion);
            writer.WritePropertyName("budget");
            writer.WriteStartObject();
            writer.WriteNumber("maxBytes", projector.Budget.MaxBytes);
            writer.WriteNumber("maxDepth", projector.Budget.MaxDepth);
            writer.WriteNumber("maxNodes", projector.Budget.MaxNodes);
            writer.WriteNumber("maxComplexity", projector.Budget.MaxComplexity);
            writer.WriteEndObject();
            WriteCanonicalStringValues(writer, "failureCodes", projector.FailureCodes.Select(code => code.Value));
            writer.WriteEndObject();
        }
        writer.WriteEndArray();
    }

    private static void WriteAdmissionProofContracts(
        Utf8JsonWriter writer,
        IReadOnlyList<AdmissionProofContractDeclaration> contracts)
    {
        writer.WriteStartArray("admissionProofContracts");
        foreach (var contract in contracts)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "contractKey", contract.ContractKey);
            WriteCanonicalString(
                writer,
                "contractVersion",
                contract.ContractVersion);
            WriteCanonicalString(writer, "kind", contract.Kind.Value);
            WriteComponentReference(
                writer,
                "proofComponent",
                contract.ProofComponent);
            WriteCanonicalStringValues(
                writer,
                "surfaces",
                contract.Surfaces.Values.Select(surface => surface.Value));
            WriteCanonicalStringValues(
                writer,
                "materialRoles",
                contract.MaterialRoles);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteParsers(Utf8JsonWriter writer,
        IReadOnlyList<SemanticModelParserDeclaration> parsers)
    {
        writer.WriteStartArray("parsers");
        foreach (var parser in parsers)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "parserKey", parser.ParserKey);
            WriteCanonicalString(writer, "parserVersion", parser.ParserVersion);
            WriteComponentReference(writer, "parser", parser.Parser);
            writer.WriteStartArray("inputs");
            foreach (var input in parser.Inputs)
            {
                var model = input.Model!;
                writer.WriteStartObject();
                WriteCanonicalString(writer, "kind", "model");
                writer.WritePropertyName("model");
                writer.WriteStartObject();
                WriteCanonicalString(writer, "modelKey", model.ModelKey);
                WriteCanonicalString(writer, "modelVersion", model.ModelVersion);
                WriteComponentReference(writer, "implementationType", model.ImplementationType);
                writer.WriteEndObject();
                writer.WriteNumber("minimumCount", input.MinimumCount);
                if (input.MaximumCount is int maximumCount)
                {
                    writer.WriteNumber("maximumCount", maximumCount);
                }
                writer.WriteEndObject();
            }
            writer.WriteEndArray();
            writer.WritePropertyName("outputModel");
            writer.WriteStartObject();
            WriteCanonicalString(writer, "modelKey", parser.OutputModel.ModelKey);
            WriteCanonicalString(writer, "modelVersion", parser.OutputModel.ModelVersion);
            WriteComponentReference(writer, "implementationType", parser.OutputModel.ImplementationType);
            writer.WriteEndObject();
            writer.WritePropertyName("budget");
            writer.WriteStartObject();
            writer.WriteNumber("maxBytes", parser.Budget.MaxBytes);
            writer.WriteNumber("maxDepth", parser.Budget.MaxDepth);
            writer.WriteNumber("maxNodes", parser.Budget.MaxNodes);
            writer.WriteNumber("maxComplexity", parser.Budget.MaxComplexity);
            writer.WriteEndObject();
            WriteCanonicalStringValues(writer, "failureCodes",
                parser.FailureCodes.Select(code => code.Value));
            writer.WriteEndObject();
        }
        writer.WriteEndArray();
    }

    private static void WriteIndexes(Utf8JsonWriter writer,
        IReadOnlyList<ContextIndexDeclaration> indexes)
    {
        writer.WriteStartArray("indexes");
        foreach (var index in indexes)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "indexKey", index.IndexKey);
            WriteCanonicalString(writer, "indexVersion", index.IndexVersion);
            WriteComponentReference(writer, "indexer", index.Indexer);
            WriteCanonicalString(writer, "invocationScope", index.InvocationScope.Value);
            writer.WriteStartArray("inputs");
            foreach (var input in index.Inputs)
            {
                if (input.Capability is { } capability && input.Model is null)
                {
                    writer.WriteStartObject();
                    WriteCanonicalString(writer, "kind", "capability");
                    writer.WritePropertyName("capability");
                    WriteCapability(writer, capability);
                    writer.WriteNumber("minimumCount", input.MinimumCount);
                    if (input.MaximumCount is int capabilityMaximumCount)
                    {
                        writer.WriteNumber("maximumCount", capabilityMaximumCount);
                    }
                    writer.WriteEndObject();
                    continue;
                }

                if (input.Model is null || input.Capability is not null)
                {
                    throw new InvalidOperationException(
                        "An index input must declare exactly one model or capability.");
                }

                var model = input.Model!;
                writer.WriteStartObject();
                WriteCanonicalString(writer, "kind", "model");
                writer.WritePropertyName("model");
                writer.WriteStartObject();
                WriteCanonicalString(writer, "modelKey", model.ModelKey);
                WriteCanonicalString(writer, "modelVersion", model.ModelVersion);
                WriteComponentReference(
                    writer, "implementationType", model.ImplementationType);
                writer.WriteEndObject();
                writer.WriteNumber("minimumCount", input.MinimumCount);
                if (input.MaximumCount is int maximumCount)
                {
                    writer.WriteNumber("maximumCount", maximumCount);
                }
                writer.WriteEndObject();
            }
            writer.WriteEndArray();
            writer.WritePropertyName("outputCapability");
            WriteCapability(writer, index.OutputCapability);
            writer.WritePropertyName("budget");
            writer.WriteStartObject();
            writer.WriteNumber("maxBytes", index.Budget.MaxBytes);
            writer.WriteNumber("maxDepth", index.Budget.MaxDepth);
            writer.WriteNumber("maxNodes", index.Budget.MaxNodes);
            writer.WriteNumber("maxComplexity", index.Budget.MaxComplexity);
            writer.WriteEndObject();
            WriteCanonicalStringValues(writer, "failureCodes",
                index.FailureCodes.Select(code => code.Value));
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteCapability(Utf8JsonWriter writer,
        CapabilityContractIdentity capability)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "capabilityKey", capability.CapabilityKey);
        WriteCanonicalString(writer, "capabilityVersion", capability.CapabilityVersion);
        WriteComponentReference(writer, "interfaceType", capability.InterfaceType);
        writer.WriteEndObject();
    }

    private static void WritePayloadSchemas(Utf8JsonWriter writer, IReadOnlyList<PayloadSchemaDeclaration> schemas)
    {
        writer.WritePropertyName("payloadSchemas");
        writer.WriteStartArray();
        foreach (var schema in schemas)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "schemaKey", schema.SchemaKey);
            WriteCanonicalString(writer, "schemaVersion", schema.SchemaVersion);
            WriteComponentReference(writer, "codec", schema.Codec);

            writer.WritePropertyName("outputModel");
            writer.WriteStartObject();
            WriteCanonicalString(writer, "modelKey", schema.OutputModel.ModelKey);
            WriteCanonicalString(writer, "modelVersion", schema.OutputModel.ModelVersion);
            WriteComponentReference(writer, "implementationType", schema.OutputModel.ImplementationType);
            writer.WriteEndObject();

            writer.WriteNumber("maxBindingsPerInstruction", schema.MaxBindingsPerInstruction);
            writer.WriteNumber(
                "maxRetainedCanonicalBytesPerInstruction", schema.MaxRetainedCanonicalBytesPerInstruction);

            writer.WritePropertyName("budget");
            writer.WriteStartObject();
            writer.WriteNumber("maxBytes", schema.Budget.MaxBytes);
            writer.WriteNumber("maxDepth", schema.Budget.MaxDepth);
            writer.WriteNumber("maxNodes", schema.Budget.MaxNodes);
            writer.WriteNumber("maxComplexity", schema.Budget.MaxComplexity);
            writer.WriteEndObject();
            WriteCanonicalStringValues(writer, "codecFailureCodes", schema.CodecFailureCodes);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteRules(
        Utf8JsonWriter writer,
        IReadOnlyList<RuleDeclaration> rules)
    {
        writer.WritePropertyName("rules");
        writer.WriteStartArray();
        foreach (var rule in rules)
        {
            WriteRule(writer, rule);
        }

        writer.WriteEndArray();
    }

    private static void WriteRule(
        Utf8JsonWriter writer,
        RuleDeclaration rule)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "ruleId", rule.RuleId.Value);
        writer.WriteNumber("ruleRevision", rule.RuleRevision.Value);
        writer.WriteNumber("catalogVersion", rule.CatalogVersion.Value);
        WriteCanonicalString(writer, "normativeDigest", rule.NormativeDigest.Value);
        WriteNormativeFragments(writer, rule.NormativeFragments);
        WriteCanonicalStringValues(
            writer,
            "qualificationScenarios",
            rule.QualificationScenarios.Select(item => item.Value));
        WriteComponentReference(writer, "evaluator", rule.Evaluator);
        WriteSlots(writer, "applicabilitySlots", rule.ApplicabilitySlots);
        WriteSlots(writer, "evaluationSlots", rule.EvaluationSlots);
        WriteExpectedSelectors(writer, rule.ExpectedSelectors);
        WriteCanonicalStringValues(
            writer,
            "subjectRoles",
            rule.SubjectRoles.Select(item => item.Value));
        WriteCanonicalStringValues(
            writer,
            "surfaces",
            rule.Surfaces.Values.Select(item => item.Value));
        WriteCanonicalStringValues(
            writer,
            "snapshotKinds",
            rule.SnapshotKinds.Select(item => item.Value));
        WriteCanonicalStringValues(
            writer,
            "operations",
            rule.Operations.Select(item => item.Value));
        WriteFindings(writer, rule.Findings);
        WriteCanonicalStringValues(
            writer,
            "evaluationFailureCodes",
            rule.EvaluationFailureCodes.Select(item => item.Value));
        WriteCanonicalString(writer, "introducedIn", rule.IntroducedIn);
        if (rule.DeprecatedIn is not null)
        {
            WriteCanonicalString(writer, "deprecatedIn", rule.DeprecatedIn);
        }

        if (rule.RetiredIn is not null)
        {
            WriteCanonicalString(writer, "retiredIn", rule.RetiredIn);
        }

        WriteCanonicalStringValues(
            writer,
            "compatibilityAliases",
            rule.CompatibilityAliases);
        writer.WriteEndObject();
    }

    private static void WriteNormativeFragments(
        Utf8JsonWriter writer,
        IReadOnlyList<NormativeFragmentDeclaration> fragments)
    {
        writer.WritePropertyName("normativeFragments");
        writer.WriteStartArray();
        foreach (var fragment in fragments)
        {
            WriteNormativeFragment(writer, fragment);
        }

        writer.WriteEndArray();
    }

    private static void WriteNormativeFragment(
        Utf8JsonWriter writer,
        NormativeFragmentDeclaration fragment)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "path", fragment.Path);
        WriteCanonicalString(writer, "containingBlob", fragment.ContainingBlob);
        WriteCanonicalString(writer, "anchor", fragment.Anchor);
        writer.WriteNumber("startLine", fragment.StartLine);
        writer.WriteNumber("endLine", fragment.EndLine);
        WriteCanonicalString(
            writer,
            "canonicalizationSchema",
            fragment.CanonicalizationSchema);
        writer.WriteNumber("canonicalByteLength", fragment.CanonicalByteLength);
        WriteCanonicalString(writer, "fragmentDigest", fragment.FragmentDigest.Value);
        writer.WriteEndObject();
    }

    private static void WriteSlots(
        Utf8JsonWriter writer,
        string propertyName,
        IReadOnlyList<EvidenceSlotDeclaration> slots)
    {
        writer.WritePropertyName(propertyName);
        writer.WriteStartArray();
        foreach (var slot in slots)
        {
            WriteEvidenceSlot(writer, slot);
        }

        writer.WriteEndArray();
    }

    private static void WriteEvidenceSlot(
        Utf8JsonWriter writer,
        EvidenceSlotDeclaration slot)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "slotKey", slot.SlotKey);
        writer.WritePropertyName("requirement");
        WriteEvidenceRequirement(writer, slot.Requirement);
        WriteCanonicalStringValues(
            writer,
            "profileSurfaces",
            slot.ProfileSurfaces.Values.Select(item => item.Value));
        WriteCanonicalString(writer, "materialRole", slot.MaterialRole);
        WriteCanonicalString(writer, "targetSelectorKey", slot.TargetSelectorKey);
        writer.WritePropertyName("capabilities");
        writer.WriteStartArray();
        foreach (var capability in slot.Capabilities)
        {
            writer.WriteStartObject();
            WriteCanonicalString(
                writer,
                "capabilityKey",
                capability.CapabilityKey);
            WriteCanonicalString(
                writer,
                "capabilityVersion",
                capability.CapabilityVersion);
            WriteComponentReference(
                writer,
                "interfaceType",
                capability.InterfaceType);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
        writer.WriteEndObject();
    }

    private static void WriteEvidenceRequirement(
        Utf8JsonWriter writer,
        EvidenceRequirement requirement)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "key", requirement.Key);
        WriteCanonicalString(writer, "surface", requirement.Surface.Value);
        WriteCanonicalString(writer, "kind", requirement.Kind);
        WriteCanonicalString(
            writer,
            "completenessContract",
            requirement.CompletenessContract);
        WriteCanonicalString(
            writer,
            "payloadSchemaKey",
            requirement.PayloadSchemaKey);
        WriteCanonicalString(
            writer,
            "payloadSchemaVersion",
            requirement.PayloadSchemaVersion);
        WriteCanonicalStringValues(
            writer,
            "acceptedConsistencyClasses",
            requirement.AcceptedConsistencyClasses.Select(item => item.Value));
        writer.WriteEndObject();
    }

    private static void WriteExpectedSelectors(
        Utf8JsonWriter writer,
        IReadOnlyList<ExpectedSelectorDeclaration> selectors)
    {
        writer.WritePropertyName("expectedSelectors");
        writer.WriteStartArray();
        foreach (var selector in selectors)
        {
            WriteExpectedSelector(writer, selector);
        }

        writer.WriteEndArray();
    }

    private static void WriteExpectedSelector(
        Utf8JsonWriter writer,
        ExpectedSelectorDeclaration selector)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "selectorKey", selector.SelectorKey);
        WriteCanonicalString(writer, "slotKey", selector.SlotKey);
        WriteCanonicalString(
            writer,
            "selectorSchemaKey",
            selector.SelectorSchemaKey);
        WriteComponentReference(writer, "resolver", selector.Resolver);
        WriteCanonicalStringValues(
            writer,
            "allowedParentKinds",
            selector.AllowedParentKinds.Select(item => item.Value));
        WriteCanonicalStringValues(
            writer,
            "allowedFindingCodes",
            selector.AllowedFindingCodes.Select(item => item.Value));
        writer.WriteEndObject();
    }

    private static void WriteFindings(
        Utf8JsonWriter writer,
        IReadOnlyList<FindingDeclaration> findings)
    {
        writer.WritePropertyName("findings");
        writer.WriteStartArray();
        foreach (var finding in findings)
        {
            WriteFinding(writer, finding);
        }

        writer.WriteEndArray();
    }

    private static void WriteFinding(
        Utf8JsonWriter writer,
        FindingDeclaration finding)
    {
        writer.WriteStartObject();
        WriteCanonicalString(writer, "code", finding.Code.Value);
        WriteCanonicalString(writer, "severity", finding.Severity.Value);
        WriteCanonicalString(writer, "remediation", finding.Remediation.Value);
        WriteCanonicalStringValues(
            writer,
            "allowedPrimaryReferenceKinds",
            finding.AllowedPrimaryReferenceKinds.Select(item => item.Value));
        WriteCanonicalStringValues(
            writer,
            "allowedRelatedReferenceKinds",
            finding.AllowedRelatedReferenceKinds.Select(item => item.Value));
        writer.WriteEndObject();
    }

    private static void WriteComponentReference(
        Utf8JsonWriter writer,
        string propertyName,
        ComponentTypeIdentity component)
    {
        writer.WritePropertyName(propertyName);
        writer.WriteStartObject();
        WriteCanonicalString(writer, "componentKey", component.ComponentKey);
        WriteCanonicalString(
            writer,
            "componentVersion",
            component.ComponentVersion);
        writer.WriteEndObject();
    }

    private static void WriteCanonicalStringValues(
        Utf8JsonWriter writer,
        string propertyName,
        IEnumerable<string> values)
    {
        writer.WritePropertyName(propertyName);
        writer.WriteStartArray();
        foreach (var value in values)
        {
            WriteCanonicalStringValue(writer, value);
        }

        writer.WriteEndArray();
    }

    private static void WriteCanonicalStringValue(
        Utf8JsonWriter writer,
        string value)
    {
        var quotedUtf8 =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(value);
        try
        {
            writer.WriteRawValue(
                quotedUtf8,
                skipInputValidation: false);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(quotedUtf8);
        }
    }

    private static void WriteActivationProof(
        Utf8JsonWriter writer,
        ActivationProofContractDeclaration activationProof)
    {
        writer.WritePropertyName("activationProofContract");
        writer.WriteStartObject();
        WriteCanonicalString(
            writer,
            "contractKey",
            activationProof.ContractKey);
        WriteCanonicalString(
            writer,
            "contractVersion",
            activationProof.ContractVersion);
        writer.WritePropertyName("proofComponent");
        writer.WriteStartObject();
        WriteCanonicalString(
            writer,
            "componentKey",
            activationProof.ProofComponent.ComponentKey);
        WriteCanonicalString(
            writer,
            "componentVersion",
            activationProof.ProofComponent.ComponentVersion);
        writer.WriteEndObject();
        writer.WriteEndObject();
    }

    private static void WriteArtifactFiles(
        Utf8JsonWriter writer,
        IReadOnlyList<ArtifactFileBinding> artifactFiles)
    {
        writer.WriteStartArray("artifactFiles");
        foreach (var artifact in artifactFiles)
        {
            writer.WriteStartObject();
            WriteCanonicalString(writer, "fileName", artifact.FileName);
            writer.WriteNumber("byteLength", artifact.ByteLength);
            WriteCanonicalString(
                writer,
                "artifactDigest",
                artifact.ArtifactDigest.Value);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteComponents(
        Utf8JsonWriter writer,
        IReadOnlyList<ComponentArtifactBinding> components)
    {
        writer.WriteStartArray("components");
        foreach (var binding in components)
        {
            writer.WriteStartObject();
            writer.WritePropertyName("component");
            writer.WriteStartObject();
            WriteCanonicalString(
                writer,
                "componentKey",
                binding.Component.ComponentKey);
            WriteCanonicalString(
                writer,
                "componentVersion",
                binding.Component.ComponentVersion);
            WriteCanonicalString(
                writer,
                "assemblyName",
                binding.Component.AssemblyName);
            WriteCanonicalString(
                writer,
                "typeName",
                binding.Component.TypeName);
            writer.WriteEndObject();
            WriteCanonicalString(
                writer,
                "artifactFileName",
                binding.ArtifactFileName);
            writer.WriteEndObject();
        }

        writer.WriteEndArray();
    }

    private static void WriteCanonicalString(
        Utf8JsonWriter writer,
        string propertyName,
        string value)
    {
        writer.WritePropertyName(propertyName);
        var quotedUtf8 =
            CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(value);
        try
        {
            writer.WriteRawValue(
                quotedUtf8,
                skipInputValidation: false);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(quotedUtf8);
        }
    }

    private static void WriteEmptyArray(
        Utf8JsonWriter writer,
        string propertyName)
    {
        writer.WriteStartArray(propertyName);
        writer.WriteEndArray();
    }
}
