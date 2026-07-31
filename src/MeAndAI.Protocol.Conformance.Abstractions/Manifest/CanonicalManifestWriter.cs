using System.Buffers;
using System.Security.Cryptography;
using System.Text.Json;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class CanonicalManifestWriter
{
    private const string SchemaKey = "protocol.policy-manifest.v1";

    internal static byte[] Write(ParsedCanonicalManifest manifest)
    {
        ArgumentNullException.ThrowIfNull(manifest);

        var slice = manifest.Slice;
        if (!manifest.AuthorityKind.Equals(
                CatalogAuthorityKind.QualificationSlice) ||
            manifest.SchemaRegistry.PayloadSchemas.Count != 0 ||
            manifest.SchemaRegistry.Parsers.Count != 0 ||
            manifest.SchemaRegistry.Indexes.Count != 0 ||
            manifest.SchemaRegistry.DemandProjectors.Count != 0 ||
            manifest.SchemaRegistry.AdmissionProofContracts.Count != 0 ||
            manifest.ArtifactFiles.Count == 0 ||
            manifest.Components.Count == 0)
        {
            throw new InvalidOperationException(
                "This writer increment supports only the minimal qualification slice.");
        }

        var buffer = new ArrayBufferWriter<byte>();
        using (var writer = new Utf8JsonWriter(
                   buffer,
                   new JsonWriterOptions
                   {
                       Indented = false,
                       SkipValidation = false,
                   }))
        {
            WriteManifest(writer, manifest, slice);
        }

        var result = GC.AllocateUninitializedArray<byte>(
            buffer.WrittenCount + 1);
        buffer.WrittenSpan.CopyTo(result);
        result[^1] = (byte)'\n';
        return result;
    }

    private static void WriteManifest(
        Utf8JsonWriter writer,
        ParsedCanonicalManifest manifest,
        CatalogSliceDeclaration slice)
    {
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
            slice.ProtocolVersion);
        writer.WriteNumber("catalogVersion", slice.CatalogVersion.Value);

        writer.WritePropertyName("slice");
        writer.WriteStartObject();
        WriteCanonicalString(writer, "sliceKey", slice.SliceKey);
        WriteCanonicalString(writer, "sliceVersion", slice.SliceVersion);
        WriteRules(writer, slice.Rules);
        writer.WriteEndObject();

        WriteSchemaRegistry(writer, manifest.SchemaRegistry);
        WriteActivationProof(writer, manifest.ActivationProofContract);
        WriteArtifactFiles(writer, manifest.ArtifactFiles);
        WriteComponents(writer, manifest.Components);
        writer.WriteEndObject();
    }

    private static void WriteSchemaRegistry(
        Utf8JsonWriter writer,
        ReleaseSchemaRegistry registry)
    {
        writer.WritePropertyName("schemaRegistry");
        writer.WriteStartObject();
        WriteEmptyArray(writer, "payloadSchemas");
        WriteEmptyArray(writer, "parsers");
        WriteEmptyArray(writer, "indexes");
        WriteEmptyArray(writer, "demandProjectors");
        WriteEmptyArray(writer, "admissionProofContracts");

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
