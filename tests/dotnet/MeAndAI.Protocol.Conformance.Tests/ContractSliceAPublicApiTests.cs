using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using System.Runtime.CompilerServices;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAPublicApiTests
{
    private const string AbstractionsScope = "A";
    private const string ConformanceScope = "C";
    private const BindingFlags DeclaredPublic =
        BindingFlags.Public |
        BindingFlags.Instance |
        BindingFlags.Static |
        BindingFlags.DeclaredOnly;
    private const BindingFlags DeclaredNonPublic =
        BindingFlags.NonPublic |
        BindingFlags.Instance |
        BindingFlags.Static |
        BindingFlags.DeclaredOnly;

    private static readonly string[] AbstractionsInventory =
    [
        "AcquisitionDemandProjectorDeclaration",
        "ActivationProofContractDeclaration",
        "AdmissionProofContractDeclaration",
        "AdmissionProofKind",
        "ArtifactFileBinding",
        "CacheRetentionPolicy",
        "CapabilityContractIdentity",
        "CatalogAuthorityKind",
        "CatalogIntegrityCode",
        "CatalogPredecessorBinding",
        "CatalogPredecessorKind",
        "CatalogSliceDeclaration",
        "CatalogVersion",
        "CompleteCatalogDeclaration",
        "CompletePolicyPackExport",
        "ComponentArtifactBinding",
        "ComponentInputDeclaration",
        "ComponentTypeIdentity",
        "ContextIndexDeclaration",
        "EvaluationFailureCode",
        "EvidenceSlotDeclaration",
        "ExpectedSelectorDeclaration",
        "FinalizedPolicyManifest",
        "FindingCode",
        "FindingDeclaration",
        "FindingSeverity",
        "IAdmissionProofCandidate",
        "IPolicyActivationProof",
        "IndexInvocationScope",
        "ModelContractIdentity",
        "NamedProfileDeclaration",
        "NormativeFragmentDeclaration",
        "PayloadSchemaDeclaration",
        "PolicyQualificationSliceExport",
        "QualifiedEvidenceReferenceKind",
        "ReleaseSchemaRegistry",
        "RemediationKey",
        "ReviewedAuthorityPermalink",
        "RuleDeclaration",
        "RuleTransitionDeclaration",
        "RuleTransitionKind",
        "SemanticModelParserDeclaration",
        "SemanticResourceBudget",
        "SessionCacheBudget",
        "TestScenarioId",
    ];

    private static readonly string[] ConformanceInventory =
    [
        "CatalogIntegrityException",
        "CompleteCatalogSnapshot",
        "NamedExecutionProfile",
    ];

    [Fact]
    [Trait("ContractSlice", "A")]
    public void ExportedTypesEqualTheContractSliceAInventories()
    {
        AssertExportedInventory(
            LoadAssembly("MeAndAI.Protocol.Conformance.Abstractions"),
            "MeAndAI.Protocol.Conformance.Abstractions",
            AbstractionsInventory);
        AssertExportedInventory(
            LoadAssembly("MeAndAI.Protocol.Conformance"),
            "MeAndAI.Protocol.Conformance",
            ConformanceInventory);
        Assert.Empty(
            LoadAssembly("MeAndAI.Protocol.Policy").GetExportedTypes());
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    public void DeclaredPublicSurfaceEqualsTheContractSliceASnapshot()
    {
        var nullability = new NullabilityInfoContext();
        var actual = new List<string>();

        AppendActualSurface(
            actual,
            nullability,
            AbstractionsScope,
            LoadAssembly("MeAndAI.Protocol.Conformance.Abstractions"),
            AbstractionsInventory);
        AppendActualSurface(
            actual,
            nullability,
            ConformanceScope,
            LoadAssembly("MeAndAI.Protocol.Conformance"),
            ConformanceInventory);

        Assert.Equal(
            BuildExpectedSurface().Order(StringComparer.Ordinal),
            actual.Order(StringComparer.Ordinal));
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    public void PublicTypesHaveNoConstructionOrSerializationLeak()
    {
        foreach (var type in GetContractSliceATypes())
        {
            Assert.Empty(type.GetConstructors(
                BindingFlags.Public |
                BindingFlags.Instance |
                BindingFlags.DeclaredOnly));

            if (!type.IsInterface)
            {
                Assert.NotEmpty(type.GetConstructors(
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly));
            }

            Assert.Empty(type.GetFields(DeclaredPublic));
            Assert.Empty(type.GetEvents(DeclaredPublic));
            Assert.All(
                type.GetProperties(DeclaredPublic),
                property => Assert.Null(property.SetMethod));
            Assert.DoesNotContain(type.GetMethods(DeclaredPublic), method =>
                method.Name == "Deconstruct" ||
                method.Name.StartsWith("op_", StringComparison.Ordinal));
            Assert.DoesNotContain(
                type.CustomAttributes,
                IsSerializerAttribute);
            Assert.All(
                type.GetProperties(DeclaredPublic),
                property => Assert.DoesNotContain(
                    property.CustomAttributes,
                    IsSerializerAttribute));
        }
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    public void FriendAssembliesEqualTheCurrentContractSliceAAllowlist()
    {
        AssertFriendAssemblies("MeAndAI.Protocol.Domain", []);
        AssertFriendAssemblies(
            "MeAndAI.Protocol.Conformance.Abstractions",
            [
                "MeAndAI.Protocol.Conformance",
                "MeAndAI.Protocol.Conformance.Tests",
                "MeAndAI.Protocol.Policy",
            ]);
        AssertFriendAssemblies(
            "MeAndAI.Protocol.Conformance",
            ["MeAndAI.Protocol.Conformance.Tests"]);
        AssertFriendAssemblies("MeAndAI.Protocol.Policy", []);
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    public void StagedExportsExposeOnlyTheContractSliceASeam()
    {
        var abstractions = LoadAssembly(
            "MeAndAI.Protocol.Conformance.Abstractions");
        var conformance = LoadAssembly("MeAndAI.Protocol.Conformance");
        var policy = LoadAssembly("MeAndAI.Protocol.Policy");
        var manifest = RequireType(abstractions, "FinalizedPolicyManifest");
        var parseCanonical = Assert.Single(
            manifest.GetMethods(DeclaredNonPublic),
            method => method.Name == "ParseCanonical");

        Assert.True(parseCanonical.IsAssembly);
        Assert.True(parseCanonical.IsStatic);
        Assert.Equal(manifest, parseCanonical.ReturnType);
        var canonicalBytes = Assert.Single(parseCanonical.GetParameters());
        Assert.Equal("canonicalBytes", canonicalBytes.Name);
        Assert.Equal(typeof(ReadOnlyMemory<byte>), canonicalBytes.ParameterType);

        var forbiddenRegistrationMembers = new[]
        {
            "CodecRegistrations",
            "DemandProjectorRegistrations",
            "EvaluatorRegistrations",
            "IndexRegistrations",
            "ParserRegistrations",
            "SelectorRegistrations",
        };
        foreach (var exportName in new[]
                 {
                     "CompletePolicyPackExport",
                     "PolicyQualificationSliceExport",
                 })
        {
            var export = RequireType(abstractions, exportName);
            Assert.DoesNotContain(
                export.GetProperties(DeclaredNonPublic),
                property => forbiddenRegistrationMembers.Contains(
                    property.Name,
                    StringComparer.Ordinal));
            Assert.DoesNotContain(
                export.GetMethods(DeclaredNonPublic),
                method => method.IsStatic && method.Name == "Create");
        }

        foreach (var forbiddenType in new[]
                 {
                     "ICodecRegistration",
                     "IDemandProjectorRegistration",
                     "IIndexRegistration",
                     "IParserRegistration",
                     "ISelectorRegistration",
                     "RuleEvaluatorRegistration",
                 })
        {
            Assert.Null(abstractions.GetType(
                $"MeAndAI.Protocol.Conformance.Abstractions.{forbiddenType}",
                throwOnError: false,
                ignoreCase: false));
        }

        Assert.Null(conformance.GetType(
            "MeAndAI.Protocol.Conformance.CatalogSliceKernel",
            throwOnError: false,
            ignoreCase: false));
        Assert.Null(conformance.GetType(
            "MeAndAI.Protocol.Conformance.ConformanceKernel",
            throwOnError: false,
            ignoreCase: false));
        Assert.Null(policy.GetType(
            "MeAndAI.Protocol.Policy.InitialRuleQualificationPolicy",
            throwOnError: false,
            ignoreCase: false));
        Assert.Empty(policy.GetExportedTypes());
    }

    private static IReadOnlyList<string> BuildExpectedSurface()
    {
        var lines = new List<string>();

        AddToken(lines, "AdmissionProofKind", ["Failed", "NoInput", "Observed"]);
        AddToken(lines, "CacheRetentionPolicy", ["RetainLowestCanonicalKeys"]);
        AddToken(
            lines,
            "CatalogAuthorityKind",
            ["CompleteProtocolSnapshot", "QualificationSlice"]);
        AddToken(
            lines,
            "CatalogIntegrityCode",
            [
                "ActivationProofInvalid",
                "AdmissionProofInvalid",
                "ArtifactMismatch",
                "CacheIdentityCollision",
                "CatalogIncomplete",
                "IntentInvalid",
                "ManifestInvalid",
                "PlanStateInvalid",
                "ReferenceInvalid",
                "RegistrationMismatch",
            ]);
        AddToken(lines, "CatalogPredecessorKind", ["Existing", "Genesis"]);
        AddToken(lines, "EvaluationFailureCode", []);
        AddToken(lines, "FindingCode", []);
        AddToken(lines, "FindingSeverity", []);
        AddToken(lines, "IndexInvocationScope", ["PerContext", "PerPlan"]);
        AddToken(
            lines,
            "QualifiedEvidenceReferenceKind",
            ["ContextProof", "Derived", "ExpectedSelector", "Root"]);
        AddToken(lines, "RemediationKey", []);
        AddToken(
            lines,
            "RuleTransitionKind",
            ["Added", "Retired", "Revised", "Unchanged"]);
        AddToken(lines, "TestScenarioId", [], comparable: true);
        AddCatalogVersion(lines);

        AddClass(lines, "SemanticResourceBudget");
        AddProperties(
            lines,
            "SemanticResourceBudget",
            ("long", "MaxBytes"),
            ("int", "MaxDepth"),
            ("long", "MaxNodes"),
            ("long", "MaxComplexity"));
        AddStaticMethod(
            lines,
            "SemanticResourceBudget",
            "SemanticResourceBudget",
            "Create",
            Arg("maxBytes", "long"),
            Arg("maxDepth", "int"),
            Arg("maxNodes", "long"),
            Arg("maxComplexity", "long"));

        AddClass(lines, "SessionCacheBudget");
        AddProperties(
            lines,
            "SessionCacheBudget",
            ("int", "MaxDecodeEntries"),
            ("long", "MaxDecodeCanonicalBytes"),
            ("int", "MaxIndexEntries"),
            ("long", "MaxIndexNodes"),
            ("int", "MaxConcurrentDecodeAttempts"),
            ("int", "MaxConcurrentIndexAttempts"),
            ("CacheRetentionPolicy", "RetentionPolicy"));
        AddStaticMethod(
            lines,
            "SessionCacheBudget",
            "SessionCacheBudget",
            "Create",
            Arg("maxDecodeEntries", "int"),
            Arg("maxDecodeCanonicalBytes", "long"),
            Arg("maxIndexEntries", "int"),
            Arg("maxIndexNodes", "long"),
            Arg("maxConcurrentDecodeAttempts", "int"),
            Arg("maxConcurrentIndexAttempts", "int"),
            Arg("retentionPolicy", "CacheRetentionPolicy"));

        AddEquatableClass(lines, "ModelContractIdentity");
        AddProperties(
            lines,
            "ModelContractIdentity",
            ("string", "ModelKey"),
            ("string", "ModelVersion"),
            ("ComponentTypeIdentity", "ImplementationType"));
        AddStaticMethod(
            lines,
            "ModelContractIdentity",
            "ModelContractIdentity",
            "Create",
            Arg("modelKey", "string"),
            Arg("modelVersion", "string"),
            Arg("implementationType", "ComponentTypeIdentity"));

        AddEquatableClass(lines, "CapabilityContractIdentity");
        AddProperties(
            lines,
            "CapabilityContractIdentity",
            ("string", "CapabilityKey"),
            ("string", "CapabilityVersion"),
            ("ComponentTypeIdentity", "InterfaceType"));
        AddStaticMethod(
            lines,
            "CapabilityContractIdentity",
            "CapabilityContractIdentity",
            "Create",
            Arg("capabilityKey", "string"),
            Arg("capabilityVersion", "string"),
            Arg("interfaceType", "ComponentTypeIdentity"));

        AddClass(lines, "ComponentTypeIdentity");
        AddProperties(
            lines,
            "ComponentTypeIdentity",
            ("string", "ComponentKey"),
            ("string", "ComponentVersion"),
            ("string", "AssemblyName"),
            ("string", "TypeName"));
        AddStaticMethod(
            lines,
            "ComponentTypeIdentity",
            "ComponentTypeIdentity",
            "Create",
            Arg("componentKey", "string"),
            Arg("componentVersion", "string"),
            Arg("assemblyName", "string"),
            Arg("typeName", "string"));

        AddClass(lines, "ArtifactFileBinding");
        AddProperties(
            lines,
            "ArtifactFileBinding",
            ("string", "FileName"),
            ("long", "ByteLength"),
            ("ExactSha256Digest", "ArtifactDigest"));
        AddStaticMethod(
            lines,
            "ArtifactFileBinding",
            "ArtifactFileBinding",
            "Create",
            Arg("fileName", "string"),
            Arg("byteLength", "long"),
            Arg("artifactDigest", "ExactSha256Digest"));

        AddClass(lines, "ComponentArtifactBinding");
        AddProperties(
            lines,
            "ComponentArtifactBinding",
            ("ComponentTypeIdentity", "Component"),
            ("string", "ArtifactFileName"));
        AddStaticMethod(
            lines,
            "ComponentArtifactBinding",
            "ComponentArtifactBinding",
            "Create",
            Arg("component", "ComponentTypeIdentity"),
            Arg("artifactFileName", "string"));

        AddClass(lines, "ComponentInputDeclaration");
        AddProperties(
            lines,
            "ComponentInputDeclaration",
            ("ModelContractIdentity?", "Model"),
            ("CapabilityContractIdentity?", "Capability"),
            ("int", "MinimumCount"),
            ("int?", "MaximumCount"));
        AddStaticMethod(
            lines,
            "ComponentInputDeclaration",
            "ComponentInputDeclaration",
            "ForModel",
            Arg("model", "ModelContractIdentity"),
            Arg("minimumCount", "int"),
            Arg("maximumCount", "int?"));
        AddStaticMethod(
            lines,
            "ComponentInputDeclaration",
            "ComponentInputDeclaration",
            "ForCapability",
            Arg("capability", "CapabilityContractIdentity"),
            Arg("minimumCount", "int"),
            Arg("maximumCount", "int?"));

        AddClass(lines, "ActivationProofContractDeclaration");
        AddProperties(
            lines,
            "ActivationProofContractDeclaration",
            ("string", "ContractKey"),
            ("string", "ContractVersion"),
            ("ComponentTypeIdentity", "ProofComponent"));
        AddStaticMethod(
            lines,
            "ActivationProofContractDeclaration",
            "ActivationProofContractDeclaration",
            "Create",
            Arg("contractKey", "string"),
            Arg("contractVersion", "string"),
            Arg("proofComponent", "ComponentTypeIdentity"));

        AddClass(lines, "AdmissionProofContractDeclaration");
        AddProperties(
            lines,
            "AdmissionProofContractDeclaration",
            ("string", "ContractKey"),
            ("string", "ContractVersion"),
            ("AdmissionProofKind", "Kind"),
            ("ComponentTypeIdentity", "ProofComponent"),
            ("SurfaceSet", "Surfaces"),
            ("IReadOnlyList<string>", "MaterialRoles"));
        AddStaticMethod(
            lines,
            "AdmissionProofContractDeclaration",
            "AdmissionProofContractDeclaration",
            "Create",
            Arg("contractKey", "string"),
            Arg("contractVersion", "string"),
            Arg("kind", "AdmissionProofKind"),
            Arg("proofComponent", "ComponentTypeIdentity"),
            Arg("surfaces", "SurfaceSet"),
            Arg("materialRoles", "IEnumerable<string>"));

        AddInterface(lines, "IPolicyActivationProof");
        AddProperties(
            lines,
            "IPolicyActivationProof",
            ("string", "ContractKey"),
            ("string", "ContractVersion"),
            ("ExactSha256Digest", "ManifestDigest"),
            ("IReadOnlyList<ArtifactFileBinding>", "VerifiedArtifacts"));
        AddInstanceMethod(
            lines,
            "IPolicyActivationProof",
            "bool",
            "Proves",
            Arg("policy", "PolicyQualificationSliceExport"));
        AddInstanceMethod(
            lines,
            "IPolicyActivationProof",
            "bool",
            "Proves",
            Arg("policy", "CompletePolicyPackExport"));
        AddInstanceMethod(
            lines,
            "IPolicyActivationProof",
            "bool",
            "Proves",
            Arg("candidate", "IAdmissionProofCandidate"));

        AddClass(lines, "NormativeFragmentDeclaration");
        AddProperties(
            lines,
            "NormativeFragmentDeclaration",
            ("string", "Path"),
            ("string", "ContainingBlob"),
            ("string", "Anchor"),
            ("int", "StartLine"),
            ("int", "EndLine"),
            ("string", "CanonicalizationSchema"),
            ("long", "CanonicalByteLength"),
            ("ExactSha256Digest", "FragmentDigest"));
        AddStaticMethod(
            lines,
            "NormativeFragmentDeclaration",
            "NormativeFragmentDeclaration",
            "Create",
            Arg("path", "string"),
            Arg("containingBlob", "string"),
            Arg("anchor", "string"),
            Arg("startLine", "int"),
            Arg("endLine", "int"),
            Arg("canonicalizationSchema", "string"),
            Arg("canonicalByteLength", "long"),
            Arg("fragmentDigest", "ExactSha256Digest"));

        AddClass(lines, "EvidenceSlotDeclaration");
        AddProperties(
            lines,
            "EvidenceSlotDeclaration",
            ("string", "SlotKey"),
            ("EvidenceRequirement", "Requirement"),
            ("SurfaceSet", "ProfileSurfaces"),
            ("string", "MaterialRole"),
            ("string", "TargetSelectorKey"),
            ("IReadOnlyList<CapabilityContractIdentity>", "Capabilities"));
        AddStaticMethod(
            lines,
            "EvidenceSlotDeclaration",
            "EvidenceSlotDeclaration",
            "Create",
            Arg("slotKey", "string"),
            Arg("requirement", "EvidenceRequirement"),
            Arg("profileSurfaces", "SurfaceSet"),
            Arg("materialRole", "string"),
            Arg("targetSelectorKey", "string"),
            Arg("capabilities", "IEnumerable<CapabilityContractIdentity>"));

        AddClass(lines, "ExpectedSelectorDeclaration");
        AddProperties(
            lines,
            "ExpectedSelectorDeclaration",
            ("string", "SelectorKey"),
            ("string", "SlotKey"),
            ("string", "SelectorSchemaKey"),
            ("ComponentTypeIdentity", "Resolver"),
            ("IReadOnlyList<QualifiedEvidenceReferenceKind>", "AllowedParentKinds"),
            ("IReadOnlyList<FindingCode>", "AllowedFindingCodes"));
        AddStaticMethod(
            lines,
            "ExpectedSelectorDeclaration",
            "ExpectedSelectorDeclaration",
            "Create",
            Arg("selectorKey", "string"),
            Arg("slotKey", "string"),
            Arg("selectorSchemaKey", "string"),
            Arg("resolver", "ComponentTypeIdentity"),
            Arg("allowedParentKinds", "IEnumerable<QualifiedEvidenceReferenceKind>"),
            Arg("allowedFindingCodes", "IEnumerable<FindingCode>"));

        AddClass(lines, "FindingDeclaration");
        AddProperties(
            lines,
            "FindingDeclaration",
            ("FindingCode", "Code"),
            ("FindingSeverity", "Severity"),
            ("RemediationKey", "Remediation"),
            ("IReadOnlyList<QualifiedEvidenceReferenceKind>", "AllowedPrimaryReferenceKinds"),
            ("IReadOnlyList<QualifiedEvidenceReferenceKind>", "AllowedRelatedReferenceKinds"));
        AddStaticMethod(
            lines,
            "FindingDeclaration",
            "FindingDeclaration",
            "Create",
            Arg("code", "FindingCode"),
            Arg("severity", "FindingSeverity"),
            Arg("remediation", "RemediationKey"),
            Arg("allowedPrimaryReferenceKinds", "IEnumerable<QualifiedEvidenceReferenceKind>"),
            Arg("allowedRelatedReferenceKinds", "IEnumerable<QualifiedEvidenceReferenceKind>"));

        AddPayloadAndProducerSurfaces(lines);
        AddRuleAndCatalogSurfaces(lines);
        AddManifestAndConformanceSurfaces(lines);

        return lines;
    }

    private static void AddPayloadAndProducerSurfaces(List<string> lines)
    {
        AddClass(lines, "PayloadSchemaDeclaration");
        AddProperties(
            lines,
            "PayloadSchemaDeclaration",
            ("string", "SchemaKey"),
            ("string", "SchemaVersion"),
            ("ComponentTypeIdentity", "Codec"),
            ("ModelContractIdentity", "OutputModel"),
            ("int", "MaxBindingsPerInstruction"),
            ("long", "MaxRetainedCanonicalBytesPerInstruction"),
            ("SemanticResourceBudget", "Budget"),
            ("IReadOnlyList<string>", "CodecFailureCodes"));
        AddStaticMethod(
            lines,
            "PayloadSchemaDeclaration",
            "PayloadSchemaDeclaration",
            "Create",
            Arg("schemaKey", "string"),
            Arg("schemaVersion", "string"),
            Arg("codec", "ComponentTypeIdentity"),
            Arg("outputModel", "ModelContractIdentity"),
            Arg("maxBindingsPerInstruction", "int"),
            Arg("maxRetainedCanonicalBytesPerInstruction", "long"),
            Arg("budget", "SemanticResourceBudget"),
            Arg("codecFailureCodes", "IEnumerable<string>"));

        AddClass(lines, "SemanticModelParserDeclaration");
        AddProperties(
            lines,
            "SemanticModelParserDeclaration",
            ("string", "ParserKey"),
            ("string", "ParserVersion"),
            ("ComponentTypeIdentity", "Parser"),
            ("IReadOnlyList<ComponentInputDeclaration>", "Inputs"),
            ("ModelContractIdentity", "OutputModel"),
            ("SemanticResourceBudget", "Budget"),
            ("IReadOnlyList<EvaluationFailureCode>", "FailureCodes"));
        AddStaticMethod(
            lines,
            "SemanticModelParserDeclaration",
            "SemanticModelParserDeclaration",
            "Create",
            Arg("parserKey", "string"),
            Arg("parserVersion", "string"),
            Arg("parser", "ComponentTypeIdentity"),
            Arg("inputs", "IEnumerable<ComponentInputDeclaration>"),
            Arg("outputModel", "ModelContractIdentity"),
            Arg("budget", "SemanticResourceBudget"),
            Arg("failureCodes", "IEnumerable<EvaluationFailureCode>"));

        AddClass(lines, "ContextIndexDeclaration");
        AddProperties(
            lines,
            "ContextIndexDeclaration",
            ("string", "IndexKey"),
            ("string", "IndexVersion"),
            ("ComponentTypeIdentity", "Indexer"),
            ("IndexInvocationScope", "InvocationScope"),
            ("IReadOnlyList<ComponentInputDeclaration>", "Inputs"),
            ("CapabilityContractIdentity", "OutputCapability"),
            ("SemanticResourceBudget", "Budget"),
            ("IReadOnlyList<EvaluationFailureCode>", "FailureCodes"));
        AddStaticMethod(
            lines,
            "ContextIndexDeclaration",
            "ContextIndexDeclaration",
            "Create",
            Arg("indexKey", "string"),
            Arg("indexVersion", "string"),
            Arg("indexer", "ComponentTypeIdentity"),
            Arg("invocationScope", "IndexInvocationScope"),
            Arg("inputs", "IEnumerable<ComponentInputDeclaration>"),
            Arg("outputCapability", "CapabilityContractIdentity"),
            Arg("budget", "SemanticResourceBudget"),
            Arg("failureCodes", "IEnumerable<EvaluationFailureCode>"));

        AddClass(lines, "AcquisitionDemandProjectorDeclaration");
        AddProperties(
            lines,
            "AcquisitionDemandProjectorDeclaration",
            ("string", "ProjectorKey"),
            ("string", "ProjectorVersion"),
            ("ComponentTypeIdentity", "Projector"),
            ("CapabilityContractIdentity", "InputCapability"),
            ("IReadOnlyList<string>", "InputSlotKeys"),
            ("string", "OutputSlotKey"),
            ("string", "DemandSchemaKey"),
            ("string", "DemandSchemaVersion"),
            ("SemanticResourceBudget", "Budget"),
            ("IReadOnlyList<EvaluationFailureCode>", "FailureCodes"));
        AddStaticMethod(
            lines,
            "AcquisitionDemandProjectorDeclaration",
            "AcquisitionDemandProjectorDeclaration",
            "Create",
            Arg("projectorKey", "string"),
            Arg("projectorVersion", "string"),
            Arg("projector", "ComponentTypeIdentity"),
            Arg("inputCapability", "CapabilityContractIdentity"),
            Arg("inputSlotKeys", "IEnumerable<string>"),
            Arg("outputSlotKey", "string"),
            Arg("demandSchemaKey", "string"),
            Arg("demandSchemaVersion", "string"),
            Arg("budget", "SemanticResourceBudget"),
            Arg("failureCodes", "IEnumerable<EvaluationFailureCode>"));

        AddClass(lines, "ReleaseSchemaRegistry");
        AddProperties(
            lines,
            "ReleaseSchemaRegistry",
            ("IReadOnlyList<PayloadSchemaDeclaration>", "PayloadSchemas"),
            ("IReadOnlyList<SemanticModelParserDeclaration>", "Parsers"),
            ("IReadOnlyList<ContextIndexDeclaration>", "Indexes"),
            ("IReadOnlyList<AcquisitionDemandProjectorDeclaration>", "DemandProjectors"),
            ("IReadOnlyList<AdmissionProofContractDeclaration>", "AdmissionProofContracts"),
            ("SessionCacheBudget", "CacheBudget"));
        AddStaticMethod(
            lines,
            "ReleaseSchemaRegistry",
            "ReleaseSchemaRegistry",
            "Create",
            Arg("payloadSchemas", "IEnumerable<PayloadSchemaDeclaration>"),
            Arg("parsers", "IEnumerable<SemanticModelParserDeclaration>"),
            Arg("indexes", "IEnumerable<ContextIndexDeclaration>"),
            Arg("demandProjectors", "IEnumerable<AcquisitionDemandProjectorDeclaration>"),
            Arg("admissionProofContracts", "IEnumerable<AdmissionProofContractDeclaration>"),
            Arg("cacheBudget", "SessionCacheBudget"));
        AddTryGet(
            lines,
            "TryGetPayloadSchema",
            "schemaKey",
            "schemaVersion",
            "PayloadSchemaDeclaration");
        AddTryGet(
            lines,
            "TryGetParser",
            "parserKey",
            "parserVersion",
            "SemanticModelParserDeclaration");
        AddTryGet(
            lines,
            "TryGetIndex",
            "indexKey",
            "indexVersion",
            "ContextIndexDeclaration");
        AddTryGet(
            lines,
            "TryGetDemandProjector",
            "projectorKey",
            "projectorVersion",
            "AcquisitionDemandProjectorDeclaration");
        AddInstanceMethod(
            lines,
            "ReleaseSchemaRegistry",
            "bool",
            "TryGetAdmissionProofContract",
            Arg("contractKey", "string"),
            Arg("contractVersion", "string"),
            Arg("kind", "AdmissionProofKind"),
            Out("declaration", "AdmissionProofContractDeclaration?", true));
    }

    private static void AddRuleAndCatalogSurfaces(List<string> lines)
    {
        AddClass(lines, "RuleDeclaration");
        AddProperties(
            lines,
            "RuleDeclaration",
            ("RuleId", "RuleId"),
            ("RuleRevision", "RuleRevision"),
            ("CatalogVersion", "CatalogVersion"),
            ("ExactSha256Digest", "NormativeDigest"),
            ("IReadOnlyList<NormativeFragmentDeclaration>", "NormativeFragments"),
            ("IReadOnlyList<TestScenarioId>", "QualificationScenarios"),
            ("ComponentTypeIdentity", "Evaluator"),
            ("IReadOnlyList<EvidenceSlotDeclaration>", "ApplicabilitySlots"),
            ("IReadOnlyList<EvidenceSlotDeclaration>", "EvaluationSlots"),
            ("IReadOnlyList<ExpectedSelectorDeclaration>", "ExpectedSelectors"),
            ("IReadOnlyList<SubjectRole>", "SubjectRoles"),
            ("SurfaceSet", "Surfaces"),
            ("IReadOnlyList<SnapshotKind>", "SnapshotKinds"),
            ("IReadOnlyList<ProtocolOperation>", "Operations"),
            ("IReadOnlyList<FindingDeclaration>", "Findings"),
            ("IReadOnlyList<EvaluationFailureCode>", "EvaluationFailureCodes"),
            ("string", "IntroducedIn"),
            ("string?", "DeprecatedIn"),
            ("string?", "RetiredIn"),
            ("IReadOnlyList<string>", "CompatibilityAliases"));
        AddStaticMethod(
            lines,
            "RuleDeclaration",
            "RuleDeclaration",
            "Create",
            Arg("ruleId", "RuleId"),
            Arg("ruleRevision", "RuleRevision"),
            Arg("catalogVersion", "CatalogVersion"),
            Arg("normativeDigest", "ExactSha256Digest"),
            Arg("normativeFragments", "IEnumerable<NormativeFragmentDeclaration>"),
            Arg("qualificationScenarios", "IEnumerable<TestScenarioId>"),
            Arg("evaluator", "ComponentTypeIdentity"),
            Arg("applicabilitySlots", "IEnumerable<EvidenceSlotDeclaration>"),
            Arg("evaluationSlots", "IEnumerable<EvidenceSlotDeclaration>"),
            Arg("expectedSelectors", "IEnumerable<ExpectedSelectorDeclaration>"),
            Arg("subjectRoles", "IEnumerable<SubjectRole>"),
            Arg("surfaces", "SurfaceSet"),
            Arg("snapshotKinds", "IEnumerable<SnapshotKind>"),
            Arg("operations", "IEnumerable<ProtocolOperation>"),
            Arg("findings", "IEnumerable<FindingDeclaration>"),
            Arg("evaluationFailureCodes", "IEnumerable<EvaluationFailureCode>"),
            Arg("introducedIn", "string"),
            Arg("deprecatedIn", "string?"),
            Arg("retiredIn", "string?"),
            Arg("compatibilityAliases", "IEnumerable<string>"));

        AddClass(lines, "NamedProfileDeclaration");
        AddProperties(
            lines,
            "NamedProfileDeclaration",
            ("string", "Name"),
            ("ExecutionProfile", "Axes"),
            ("IReadOnlyList<RuleId>", "RuleIds"));
        AddStaticMethod(
            lines,
            "NamedProfileDeclaration",
            "NamedProfileDeclaration",
            "Create",
            Arg("name", "string"),
            Arg("axes", "ExecutionProfile"),
            Arg("ruleIds", "IEnumerable<RuleId>"));

        AddEquatableClass(lines, "ReviewedAuthorityPermalink");
        AddProperty(lines, "ReviewedAuthorityPermalink", "string", "Value");
        AddStaticMethod(
            lines,
            "ReviewedAuthorityPermalink",
            "ReviewedAuthorityPermalink",
            "Create",
            Arg("value", "string"));

        AddEquatableClass(lines, "CatalogPredecessorBinding");
        AddProperties(
            lines,
            "CatalogPredecessorBinding",
            ("CatalogPredecessorKind", "Kind"),
            ("CatalogVersion?", "CatalogVersion"),
            ("ExactSha256Digest?", "ManifestDigest"),
            ("ExactSha256Digest?", "CompleteInventoryDigest"));
        AddStaticMethod(
            lines,
            "CatalogPredecessorBinding",
            "CatalogPredecessorBinding",
            "Genesis");
        AddStaticMethod(
            lines,
            "CatalogPredecessorBinding",
            "CatalogPredecessorBinding",
            "Existing",
            Arg("catalogVersion", "CatalogVersion"),
            Arg("manifestDigest", "ExactSha256Digest"),
            Arg("completeInventoryDigest", "ExactSha256Digest"));

        AddClass(lines, "RuleTransitionDeclaration");
        AddProperties(
            lines,
            "RuleTransitionDeclaration",
            ("RuleId", "RuleId"),
            ("RuleTransitionKind", "Kind"),
            ("RuleRevision?", "PreviousRevision"),
            ("RuleRevision?", "CurrentRevision"),
            ("ReviewedAuthorityPermalink?", "ReviewedAuthority"));
        AddStaticMethod(
            lines,
            "RuleTransitionDeclaration",
            "RuleTransitionDeclaration",
            "Unchanged",
            Arg("ruleId", "RuleId"),
            Arg("revision", "RuleRevision"),
            Arg("reviewedAuthority", "ReviewedAuthorityPermalink?"));
        AddStaticMethod(
            lines,
            "RuleTransitionDeclaration",
            "RuleTransitionDeclaration",
            "Added",
            Arg("ruleId", "RuleId"),
            Arg("currentRevision", "RuleRevision"),
            Arg("reviewedAuthority", "ReviewedAuthorityPermalink"));
        AddStaticMethod(
            lines,
            "RuleTransitionDeclaration",
            "RuleTransitionDeclaration",
            "Revised",
            Arg("ruleId", "RuleId"),
            Arg("previousRevision", "RuleRevision"),
            Arg("currentRevision", "RuleRevision"),
            Arg("reviewedAuthority", "ReviewedAuthorityPermalink"));
        AddStaticMethod(
            lines,
            "RuleTransitionDeclaration",
            "RuleTransitionDeclaration",
            "Retired",
            Arg("ruleId", "RuleId"),
            Arg("previousRevision", "RuleRevision"),
            Arg("reviewedAuthority", "ReviewedAuthorityPermalink"));

        AddClass(lines, "CatalogSliceDeclaration");
        AddProperties(
            lines,
            "CatalogSliceDeclaration",
            ("string", "SliceKey"),
            ("string", "SliceVersion"),
            ("string", "ProtocolVersion"),
            ("CatalogVersion", "CatalogVersion"),
            ("IReadOnlyList<RuleDeclaration>", "Rules"));
        AddStaticMethod(
            lines,
            "CatalogSliceDeclaration",
            "CatalogSliceDeclaration",
            "Create",
            Arg("sliceKey", "string"),
            Arg("sliceVersion", "string"),
            Arg("protocolVersion", "string"),
            Arg("catalogVersion", "CatalogVersion"),
            Arg("rules", "IEnumerable<RuleDeclaration>"));

        AddClass(lines, "CompleteCatalogDeclaration");
        AddProperties(
            lines,
            "CompleteCatalogDeclaration",
            ("string", "ProtocolVersion"),
            ("CatalogVersion", "CatalogVersion"),
            ("CatalogPredecessorBinding", "Predecessor"),
            ("ExactSha256Digest", "CompleteInventoryDigest"),
            ("string", "BaselineProfileName"),
            ("IReadOnlyList<RuleDeclaration>", "Rules"),
            ("IReadOnlyList<RuleTransitionDeclaration>", "Transitions"),
            ("IReadOnlyList<NamedProfileDeclaration>", "NamedProfiles"));
        AddStaticMethod(
            lines,
            "CompleteCatalogDeclaration",
            "CompleteCatalogDeclaration",
            "Create",
            Arg("protocolVersion", "string"),
            Arg("catalogVersion", "CatalogVersion"),
            Arg("predecessor", "CatalogPredecessorBinding"),
            Arg("baselineProfileName", "string"),
            Arg("rules", "IEnumerable<RuleDeclaration>"),
            Arg("transitions", "IEnumerable<RuleTransitionDeclaration>"),
            Arg("namedProfiles", "IEnumerable<NamedProfileDeclaration>"));
    }

    private static void AddManifestAndConformanceSurfaces(List<string> lines)
    {
        AddClass(lines, "FinalizedPolicyManifest");
        AddProperties(
            lines,
            "FinalizedPolicyManifest",
            ("CatalogAuthorityKind", "AuthorityKind"),
            ("string", "SourceCommit"),
            ("ExactSha256Digest", "ManifestDigest"),
            ("ReleaseSchemaRegistry", "SchemaRegistry"),
            ("ActivationProofContractDeclaration", "ActivationProofContract"),
            ("IReadOnlyList<ArtifactFileBinding>", "ArtifactFiles"),
            ("IReadOnlyList<ComponentArtifactBinding>", "Components"),
            ("CatalogSliceDeclaration?", "Slice"),
            ("CompleteCatalogDeclaration?", "CompleteCatalog"));

        AddClass(lines, "PolicyQualificationSliceExport");
        AddProperties(
            lines,
            "PolicyQualificationSliceExport",
            ("string", "ExportKey"),
            ("string", "ExportVersion"),
            ("CatalogSliceDeclaration", "Catalog"),
            ("ReleaseSchemaRegistry", "SchemaRegistry"),
            ("IReadOnlyList<ComponentTypeIdentity>", "Components"));

        AddClass(lines, "CompletePolicyPackExport");
        AddProperties(
            lines,
            "CompletePolicyPackExport",
            ("string", "ExportKey"),
            ("string", "ExportVersion"),
            ("CompleteCatalogDeclaration", "Catalog"),
            ("ReleaseSchemaRegistry", "SchemaRegistry"),
            ("IReadOnlyList<ComponentTypeIdentity>", "Components"));

        AddInterface(lines, "IAdmissionProofCandidate");
        AddProperties(
            lines,
            "IAdmissionProofCandidate",
            ("IReadOnlyList<string>", "SlotKeys"),
            ("string", "ContractKey"),
            ("string", "ContractVersion"),
            ("ExactSha256Digest", "ManifestDigest"),
            ("ExactSha256Digest", "InstructionDigest"),
            ("ExactSha256Digest", "ReceiptDigest"),
            ("AcquisitionRequest", "Request"));

        AddClass(
            lines,
            "CatalogIntegrityException",
            ConformanceScope,
            "InvalidOperationException");
        AddProperty(
            lines,
            "CatalogIntegrityException",
            "CatalogIntegrityCode",
            "Code",
            scope: ConformanceScope);

        AddClass(
            lines,
            "CompleteCatalogSnapshot",
            ConformanceScope);
        AddProperties(
            lines,
            "CompleteCatalogSnapshot",
            ConformanceScope,
            ("string", "ProtocolVersion"),
            ("CatalogVersion", "CatalogVersion"),
            ("ExactSha256Digest", "ManifestDigest"),
            ("ExactSha256Digest", "CompleteInventoryDigest"),
            ("CatalogPredecessorBinding", "Predecessor"),
            ("string", "BaselineProfileName"),
            ("IReadOnlyList<RuleDeclaration>", "Rules"),
            ("IReadOnlyList<NamedProfileDeclaration>", "NamedProfiles"));

        AddClass(
            lines,
            "NamedExecutionProfile",
            ConformanceScope);
        AddProperties(
            lines,
            "NamedExecutionProfile",
            ConformanceScope,
            ("string", "Name"),
            ("ExecutionProfile", "Axes"),
            ("IReadOnlyList<RuleId>", "RuleIds"));
    }

    private static void AddToken(
        List<string> lines,
        string type,
        IReadOnlyList<string> namedProperties,
        bool comparable = false)
    {
        AddClass(
            lines,
            type,
            interfaces: comparable
                ? [$"IComparable<{type}>", $"IEquatable<{type}>"]
                : [$"IEquatable<{type}>"]);
        AddProperty(lines, type, "string", "Value");
        foreach (var property in namedProperties)
        {
            AddProperty(lines, type, type, property, isStatic: true);
        }

        AddStaticMethod(lines, type, type, "Parse", Arg("value", "string"));
        AddStaticMethod(
            lines,
            type,
            "bool",
            "TryParse",
            Arg("value", "string?"),
            Out("result", $"{type}?", true));
        AddEqualityMethods(lines, type);
        if (comparable)
        {
            AddInstanceMethod(
                lines,
                type,
                "int",
                "CompareTo",
                Arg("other", $"{type}?"));
        }
    }

    private static void AddCatalogVersion(List<string> lines)
    {
        const string type = "CatalogVersion";
        AddClass(
            lines,
            type,
            interfaces:
            [
                "IComparable<CatalogVersion>",
                "IEquatable<CatalogVersion>",
            ]);
        AddProperty(lines, type, "int", "Value");
        AddStaticMethod(lines, type, type, "Create", Arg("value", "int"));
        AddEqualityMethods(lines, type);
        AddInstanceMethod(
            lines,
            type,
            "int",
            "CompareTo",
            Arg("other", "CatalogVersion?"));
    }

    private static void AddEquatableClass(List<string> lines, string type)
    {
        AddClass(lines, type, interfaces: [$"IEquatable<{type}>"]);
        AddEqualityMethods(lines, type);
    }

    private static void AddEqualityMethods(List<string> lines, string type)
    {
        AddInstanceMethod(
            lines,
            type,
            "bool",
            "Equals",
            Arg("other", $"{type}?"));
        AddOverrideMethod(
            lines,
            type,
            "bool",
            "Equals",
            Arg("obj", "object?"));
        AddOverrideMethod(lines, type, "int", "GetHashCode");
        AddOverrideMethod(lines, type, "string", "ToString");
    }

    private static void AddTryGet(
        List<string> lines,
        string method,
        string keyName,
        string versionName,
        string declarationType) =>
        AddInstanceMethod(
            lines,
            "ReleaseSchemaRegistry",
            "bool",
            method,
            Arg(keyName, "string"),
            Arg(versionName, "string"),
            Out("declaration", $"{declarationType}?", true));

    private static void AddClass(
        List<string> lines,
        string type,
        string scope = AbstractionsScope,
        string baseType = "object",
        params string[] interfaces) =>
        lines.Add(
            $"T|{scope}|{type}|class|sealed|{baseType}|" +
            string.Join(',', interfaces.Order(StringComparer.Ordinal)));

    private static void AddInterface(
        List<string> lines,
        string type,
        string scope = AbstractionsScope,
        params string[] interfaces) =>
        lines.Add(
            $"T|{scope}|{type}|interface|-|-|" +
            string.Join(',', interfaces.Order(StringComparer.Ordinal)));

    private static void AddProperties(
        List<string> lines,
        string declaringType,
        params (string Type, string Name)[] properties) =>
        AddProperties(
            lines,
            declaringType,
            AbstractionsScope,
            properties);

    private static void AddProperties(
        List<string> lines,
        string declaringType,
        string scope,
        params (string Type, string Name)[] properties)
    {
        foreach (var property in properties)
        {
            AddProperty(
                lines,
                declaringType,
                property.Type,
                property.Name,
                scope: scope);
        }
    }

    private static void AddProperty(
        List<string> lines,
        string declaringType,
        string propertyType,
        string name,
        bool isStatic = false,
        string scope = AbstractionsScope) =>
        lines.Add(
            $"P|{scope}|{declaringType}|{(isStatic ? "S" : "I")}|" +
            $"{propertyType}|{name}");

    private static void AddStaticMethod(
        List<string> lines,
        string declaringType,
        string returnType,
        string name,
        params string[] parameters) =>
        AddMethod(
            lines,
            declaringType,
            returnType,
            name,
            isStatic: true,
            isOverride: false,
            parameters);

    private static void AddInstanceMethod(
        List<string> lines,
        string declaringType,
        string returnType,
        string name,
        params string[] parameters) =>
        AddMethod(
            lines,
            declaringType,
            returnType,
            name,
            isStatic: false,
            isOverride: false,
            parameters);

    private static void AddOverrideMethod(
        List<string> lines,
        string declaringType,
        string returnType,
        string name,
        params string[] parameters) =>
        AddMethod(
            lines,
            declaringType,
            returnType,
            name,
            isStatic: false,
            isOverride: true,
            parameters);

    private static void AddMethod(
        List<string> lines,
        string declaringType,
        string returnType,
        string name,
        bool isStatic,
        bool isOverride,
        params string[] parameters) =>
        lines.Add(
            $"M|{AbstractionsScope}|{declaringType}|" +
            $"{(isStatic ? "S" : "I")}|" +
            $"{(isOverride ? "override" : "plain")}|" +
            $"{returnType}|{name}|{string.Join(',', parameters)}");

    private static string Arg(string name, string type) =>
        $"{name}:value:{type}:-";

    private static string Out(
        string name,
        string type,
        bool notNullWhenTrue) =>
        $"{name}:out:{type}:{(notNullWhenTrue ? "true" : "-")}";

    private static void AppendActualSurface(
        List<string> lines,
        NullabilityInfoContext nullability,
        string scope,
        Assembly assembly,
        IEnumerable<string> inventory)
    {
        foreach (var typeName in inventory)
        {
            var type = RequireType(assembly, typeName);
            var interfaces = GetDeclaredInterfaces(type)
                .Select(FormatType)
                .Order(StringComparer.Ordinal);
            lines.Add(
                $"T|{scope}|{type.Name}|" +
                $"{(type.IsInterface ? "interface" : "class")}|" +
                $"{(type.IsInterface ? "-" : type.IsSealed ? "sealed" : "open")}|" +
                $"{(type.IsInterface ? "-" : FormatType(type.BaseType!))}|" +
                string.Join(',', interfaces));

            foreach (var property in type.GetProperties(DeclaredPublic))
            {
                lines.Add(
                    $"P|{scope}|{type.Name}|" +
                    $"{(property.GetMethod?.IsStatic == true ? "S" : "I")}|" +
                    $"{FormatAnnotatedType(property.PropertyType, nullability.Create(property))}|" +
                    property.Name);
            }

            foreach (var method in type
                         .GetMethods(DeclaredPublic)
                         .Where(method => !method.IsSpecialName))
            {
                var parameters = method
                    .GetParameters()
                    .Select(parameter => FormatParameter(parameter, nullability));
                lines.Add(
                    $"M|{scope}|{type.Name}|" +
                    $"{(method.IsStatic ? "S" : "I")}|" +
                    $"{(method.GetBaseDefinition() == method ? "plain" : "override")}|" +
                    $"{FormatAnnotatedType(method.ReturnType, nullability.Create(method.ReturnParameter))}|" +
                    $"{method.Name}|{string.Join(',', parameters)}");
            }
        }
    }

    private static string FormatParameter(
        ParameterInfo parameter,
        NullabilityInfoContext nullability)
    {
        var direction = parameter.IsOut
            ? "out"
            : parameter.ParameterType.IsByRef
                ? "ref"
                : "value";
        var notNullWhen = parameter
            .GetCustomAttribute<NotNullWhenAttribute>()?
            .ReturnValue == true
            ? "true"
            : "-";

        return $"{parameter.Name}:{direction}:" +
            $"{FormatAnnotatedType(parameter.ParameterType, nullability.Create(parameter))}:" +
            notNullWhen;
    }

    private static string FormatAnnotatedType(
        Type type,
        NullabilityInfo nullability)
    {
        if (type.IsByRef)
        {
            type = type.GetElementType()
                ?? throw new InvalidDataException("A by-ref type has no element type.");
        }

        var nullableValue = Nullable.GetUnderlyingType(type);
        if (nullableValue is not null)
        {
            return $"{FormatType(nullableValue)}?";
        }

        string formatted;
        if (type.IsGenericType)
        {
            var definitionName = TypeAlias(type.GetGenericTypeDefinition());
            var arguments = type.GetGenericArguments();
            var annotatedArguments = nullability.GenericTypeArguments;
            formatted = $"{definitionName}<" +
                string.Join(
                    ',',
                    arguments.Select((argument, index) =>
                        index < annotatedArguments.Length
                            ? FormatAnnotatedType(argument, annotatedArguments[index])
                            : FormatType(argument))) +
                ">";
        }
        else
        {
            formatted = TypeAlias(type);
        }

        return !type.IsValueType &&
            nullability.ReadState == NullabilityState.Nullable
            ? $"{formatted}?"
            : formatted;
    }

    private static string FormatType(Type type)
    {
        var nullableValue = Nullable.GetUnderlyingType(type);
        if (nullableValue is not null)
        {
            return $"{FormatType(nullableValue)}?";
        }

        if (!type.IsGenericType)
        {
            return TypeAlias(type);
        }

        return $"{TypeAlias(type.GetGenericTypeDefinition())}<" +
            string.Join(',', type.GetGenericArguments().Select(FormatType)) +
            ">";
    }

    private static string TypeAlias(Type type) => type.FullName switch
    {
        "System.Boolean" => "bool",
        "System.Byte" => "byte",
        "System.Int32" => "int",
        "System.Int64" => "long",
        "System.Object" => "object",
        "System.String" => "string",
        "System.Void" => "void",
        "System.Collections.Generic.IEnumerable`1" => "IEnumerable",
        "System.Collections.Generic.IReadOnlyList`1" => "IReadOnlyList",
        "System.IComparable`1" => "IComparable",
        "System.IEquatable`1" => "IEquatable",
        "System.ReadOnlyMemory`1" => "ReadOnlyMemory",
        _ => type.Name.Contains('`')
            ? type.Name[..type.Name.IndexOf('`')]
            : type.Name,
    };

    private static IEnumerable<Type> GetDeclaredInterfaces(Type type)
    {
        var inheritedInterfaces = type.BaseType?.GetInterfaces() ?? [];

        return type.GetInterfaces().Except(inheritedInterfaces);
    }

    private static IEnumerable<Type> GetContractSliceATypes()
    {
        var abstractions = LoadAssembly(
            "MeAndAI.Protocol.Conformance.Abstractions");
        var conformance = LoadAssembly("MeAndAI.Protocol.Conformance");

        return AbstractionsInventory
            .Select(name => RequireType(abstractions, name))
            .Concat(ConformanceInventory.Select(
                name => RequireType(conformance, name)));
    }

    private static void AssertExportedInventory(
        Assembly assembly,
        string expectedNamespace,
        IEnumerable<string> expectedNames)
    {
        var expected = expectedNames
            .Select(name => $"{expectedNamespace}.{name}")
            .Order(StringComparer.Ordinal)
            .ToArray();
        var actual = assembly
            .GetExportedTypes()
            .Select(type => type.FullName)
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expected, actual);
    }

    private static void AssertFriendAssemblies(
        string assemblyName,
        IEnumerable<string> expectedFriends)
    {
        var actual = LoadAssembly(assemblyName)
            .GetCustomAttributes<InternalsVisibleToAttribute>()
            .Select(attribute => new AssemblyName(
                attribute.AssemblyName).Name
                ?? throw new InvalidDataException(
                    "InternalsVisibleTo has no simple assembly name."))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expectedFriends.Order(StringComparer.Ordinal), actual);
    }

    private static bool IsSerializerAttribute(CustomAttributeData attribute) =>
        attribute.AttributeType.FullName is
            "System.Runtime.Serialization.DataContractAttribute" or
            "System.Runtime.Serialization.DataMemberAttribute" or
            "System.Text.Json.Serialization.JsonConstructorAttribute" or
            "System.Text.Json.Serialization.JsonConverterAttribute" or
            "System.Text.Json.Serialization.JsonPropertyNameAttribute";

    private static Assembly LoadAssembly(string name) =>
        Assembly.Load(new AssemblyName(name));

    private static Type RequireType(Assembly assembly, string name) =>
        assembly.GetType(
            $"{assembly.GetName().Name}.{name}",
            throwOnError: true,
            ignoreCase: false)
        ?? throw new TypeLoadException(
            $"Assembly '{assembly.GetName().Name}' has no type '{name}'.");
}
