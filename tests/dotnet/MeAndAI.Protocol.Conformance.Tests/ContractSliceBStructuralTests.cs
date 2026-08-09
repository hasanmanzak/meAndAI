using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using System.Runtime.CompilerServices;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBPublicApiTests
{
    private const string AbstractionsScope = "A";
    private const string ConformanceScope = "C";
    private const BindingFlags DeclaredPublic =
        BindingFlags.Public |
        BindingFlags.Instance |
        BindingFlags.Static |
        BindingFlags.DeclaredOnly;

    private static readonly string[] AbstractionsA =
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

    private static readonly string[] AbstractionsB =
    [
        "GovernedReferenceKind",
        "GovernedReferenceResolution",
        "GovernedReferenceSyntax",
        "GovernedReferenceView",
        "IEvidenceCapability",
        "IFailedAttemptProof",
        "IGovernedReferenceIndex",
        "INoInputRoutingProof",
        "IObservedQualificationProof",
        "IProtocolRecordIndex",
        "IRepositoryTargetResolutionIndex",
        "IRepositoryTree",
        "ProtocolRecordMemberView",
        "ProtocolRecordView",
        "QualifiedEvidenceHandle",
        "RepositoryEntryKind",
        "RepositoryEntryView",
        "RepositoryTargetResolutionDemandItem",
        "RepositoryTargetResolutionView",
    ];

    private static readonly string[] ConformanceA =
    [
        "CatalogIntegrityException",
        "CompleteCatalogSnapshot",
        "NamedExecutionProfile",
    ];

    private static readonly string[] ConformanceB =
    [
        "AcquisitionProofSet",
        "QualifiedEvidenceDerivation",
        "QualifiedEvidenceReference",
        "QualifiedEvidenceSelector",
        "SealedEvaluationContext",
    ];

    [Fact]
    [Trait("ContractSlice", "B")]
    public void Matches_exact_cumulative_b_public_surface()
    {
        var abstractions = LoadAssembly(
            "MeAndAI.Protocol.Conformance.Abstractions");
        var conformance = LoadAssembly("MeAndAI.Protocol.Conformance");

        AssertExportedInventory(
            abstractions,
            "MeAndAI.Protocol.Conformance.Abstractions",
            AbstractionsA.Concat(AbstractionsB));
        AssertExportedInventory(
            conformance,
            "MeAndAI.Protocol.Conformance",
            ConformanceA.Concat(ConformanceB));
        Assert.Empty(LoadAssembly("MeAndAI.Protocol.Policy").GetExportedTypes());
        Assert.Equal(
            72,
            abstractions.GetExportedTypes().Length +
            conformance.GetExportedTypes().Length);

        var nullability = new NullabilityInfoContext();
        var actual = new List<string>();
        AppendActualSurface(
            actual,
            nullability,
            AbstractionsScope,
            abstractions,
            AbstractionsB);
        AppendActualSurface(
            actual,
            nullability,
            ConformanceScope,
            conformance,
            ConformanceB);

        Assert.Equal(
            BuildExpectedSurface().Order(StringComparer.Ordinal),
            actual.Order(StringComparer.Ordinal));

        foreach (var type in GetBTypes(abstractions, conformance))
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
            Assert.DoesNotContain(
                type.GetMethods(DeclaredPublic),
                method => method.Name == "Deconstruct" ||
                    method.Name.StartsWith("op_", StringComparison.Ordinal));
            Assert.DoesNotContain(type.CustomAttributes, IsSerializerAttribute);
        }
    }

    private static IReadOnlyList<string> BuildExpectedSurface()
    {
        var lines = new List<string>();

        AddToken(
            lines,
            "GovernedReferenceKind",
            ["Commit", "CrossRecord", "EmbeddedRecord"]);
        AddToken(
            lines,
            "GovernedReferenceResolution",
            [
                "Exact",
                "ExternalEvidenceRequired",
                "MissingFragment",
                "Unresolved",
                "WrongFragment",
                "WrongObject",
                "WrongRepository",
                "WrongTarget",
            ]);
        AddToken(
            lines,
            "GovernedReferenceSyntax",
            ["Clickable", "NonClickable", "UnsupportedAuthoringForm"]);
        AddToken(
            lines,
            "RepositoryEntryKind",
            ["Directory", "File", "GitLink", "SymbolicLink"]);

        AddInterface(lines, "IEvidenceCapability");
        AddInterface(lines, "IRepositoryTree", interfaces: ["IEvidenceCapability"]);
        AddProperty(
            lines,
            "IRepositoryTree",
            "IReadOnlyList<RepositoryEntryView>",
            "Entries");
        AddInterface(
            lines,
            "IProtocolRecordIndex",
            interfaces: ["IEvidenceCapability"]);
        AddProperty(
            lines,
            "IProtocolRecordIndex",
            "IReadOnlyList<ProtocolRecordView>",
            "Records");
        AddInterface(
            lines,
            "IGovernedReferenceIndex",
            interfaces: ["IEvidenceCapability"]);
        AddProperty(
            lines,
            "IGovernedReferenceIndex",
            "IReadOnlyList<GovernedReferenceView>",
            "References");
        AddInterface(
            lines,
            "IRepositoryTargetResolutionIndex",
            interfaces: ["IEvidenceCapability"]);
        AddProperty(
            lines,
            "IRepositoryTargetResolutionIndex",
            "IReadOnlyList<RepositoryTargetResolutionView>",
            "Targets");

        AddInterface(
            lines,
            "IObservedQualificationProof",
            interfaces: ["IAdmissionProofCandidate"]);
        AddProperties(
            lines,
            "IObservedQualificationProof",
            ("ObservedAcquisitionResult", "Result"),
            ("IReadOnlyList<ComponentArtifactBinding>", "QualifiedCodecs"));
        AddInterface(
            lines,
            "IFailedAttemptProof",
            interfaces: ["IAdmissionProofCandidate"]);
        AddProperty(
            lines,
            "IFailedAttemptProof",
            "FailedAcquisitionResult",
            "Result");
        AddInterface(
            lines,
            "INoInputRoutingProof",
            interfaces: ["IAdmissionProofCandidate"]);

        AddClass(lines, "QualifiedEvidenceHandle");
        AddClass(lines, "RepositoryEntryView");
        AddProperties(
            lines,
            "RepositoryEntryView",
            ("string", "RepositoryRelativePath"),
            ("RepositoryEntryKind", "Kind"),
            ("QualifiedEvidenceHandle", "Evidence"));
        AddClass(lines, "ProtocolRecordMemberView");
        AddProperties(
            lines,
            "ProtocolRecordMemberView",
            ("string", "MemberKey"),
            ("int", "Ordinal"),
            ("QualifiedEvidenceHandle", "Evidence"));
        AddClass(lines, "ProtocolRecordView");
        AddProperties(
            lines,
            "ProtocolRecordView",
            ("string", "RecordKind"),
            ("string", "RecordId"),
            ("int", "Ordinal"),
            ("QualifiedEvidenceHandle", "Evidence"),
            ("IReadOnlyList<ProtocolRecordMemberView>", "Members"));
        AddClass(lines, "GovernedReferenceView");
        AddProperties(
            lines,
            "GovernedReferenceView",
            ("GovernedReferenceKind", "Kind"),
            ("GovernedReferenceSyntax", "Syntax"),
            ("GovernedReferenceResolution", "Resolution"),
            ("string?", "OwningRepositoryIdentity"),
            ("string?", "CommitObjectId"),
            ("string?", "NormalizedTagName"),
            ("string?", "CapturedSnapshotIdentity"),
            ("string?", "NormalizedRepositoryRelativePath"),
            ("string?", "NormalizedFragment"),
            ("QualifiedEvidenceHandle", "Reference"),
            ("QualifiedEvidenceHandle?", "Target"));
        AddClass(lines, "RepositoryTargetResolutionDemandItem");
        AddProperties(
            lines,
            "RepositoryTargetResolutionDemandItem",
            ("int", "ItemId"),
            ("string", "OwningRepositoryIdentity"),
            ("string?", "CommitObjectId"),
            ("string?", "NormalizedTagName"),
            ("string?", "CapturedSnapshotIdentity"),
            ("string?", "NormalizedRepositoryRelativePath"),
            ("string?", "NormalizedFragment"));
        AddClass(lines, "RepositoryTargetResolutionView");
        AddProperties(
            lines,
            "RepositoryTargetResolutionView",
            ("QualifiedEvidenceHandle", "Reference"),
            ("GovernedReferenceResolution", "Resolution"),
            ("QualifiedEvidenceHandle", "ResolutionEvidence"),
            ("QualifiedEvidenceHandle?", "Commit"),
            ("QualifiedEvidenceHandle?", "Tag"),
            ("QualifiedEvidenceHandle?", "Target"));

        AddClass(lines, "AcquisitionProofSet", scope: ConformanceScope);
        AddProperties(
            lines,
            "AcquisitionProofSet",
            ConformanceScope,
            ("IReadOnlyList<IObservedQualificationProof>", "Observed"),
            ("IReadOnlyList<IFailedAttemptProof>", "Failed"),
            ("IReadOnlyList<INoInputRoutingProof>", "NoInput"));
        AddScopedStaticMethod(
            lines,
            "AcquisitionProofSet",
            "AcquisitionProofSet",
            "Create",
            ConformanceScope,
            Arg("observed", "IEnumerable<IObservedQualificationProof>"),
            Arg("failed", "IEnumerable<IFailedAttemptProof>"),
            Arg("noInput", "IEnumerable<INoInputRoutingProof>"));
        AddClass(lines, "SealedEvaluationContext", scope: ConformanceScope);
        AddProperties(
            lines,
            "SealedEvaluationContext",
            ConformanceScope,
            ("CatalogAuthorityKind", "AuthorityKind"),
            ("ExactSha256Digest", "ManifestDigest"),
            ("CatalogVersion", "CatalogVersion"),
            ("IReadOnlyList<string>", "AdmittedSlotKeys"),
            ("IReadOnlyList<EvidenceScope>", "Scopes"));
        AddClass(lines, "QualifiedEvidenceSelector", scope: ConformanceScope);
        AddProperties(
            lines,
            "QualifiedEvidenceSelector",
            ConformanceScope,
            ("string", "SelectorKey"),
            ("string", "SelectorSchemaKey"),
            ("string", "CanonicalValue"));
        AddClass(lines, "QualifiedEvidenceDerivation", scope: ConformanceScope);
        AddProperties(
            lines,
            "QualifiedEvidenceDerivation",
            ConformanceScope,
            ("ComponentTypeIdentity", "Component"),
            ("string", "ArtifactFileName"),
            ("ExactSha256Digest", "ArtifactDigest"),
            ("ModelContractIdentity?", "OutputModel"),
            ("CapabilityContractIdentity?", "OutputCapability"),
            ("string", "TypedNodeKind"),
            ("string", "TypedNodeIdentity"),
            ("EvidenceLocation", "Location"));
        AddClass(lines, "QualifiedEvidenceReference", scope: ConformanceScope);
        AddProperties(
            lines,
            "QualifiedEvidenceReference",
            ConformanceScope,
            ("QualifiedEvidenceReferenceKind", "Kind"),
            ("ExactSha256Digest", "ManifestDigest"),
            ("CatalogVersion", "CatalogVersion"),
            ("string", "SlotKey"),
            ("string", "RequirementKey"),
            ("EvidenceScope", "Scope"),
            ("ExactSha256Digest", "QualificationProofDigest"),
            ("RootEvidenceReference?", "Root"),
            ("EvidenceLocation?", "Location"),
            ("IReadOnlyList<QualifiedEvidenceDerivation>", "Derivations"),
            ("QualifiedEvidenceReferenceKind?", "ExpectedSelectorParentKind"),
            ("QualifiedEvidenceSelector?", "Selector"));

        return lines;
    }

    private static void AddToken(
        List<string> lines,
        string type,
        IReadOnlyList<string> namedProperties)
    {
        AddClass(lines, type, interfaces: [$"IEquatable<{type}>"]);
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
        AddInstanceMethod(lines, type, "bool", "Equals", Arg("other", $"{type}?"));
        AddOverrideMethod(lines, type, "bool", "Equals", Arg("obj", "object?"));
        AddOverrideMethod(lines, type, "int", "GetHashCode");
        AddOverrideMethod(lines, type, "string", "ToString");
    }

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
        AddProperties(lines, declaringType, AbstractionsScope, properties);

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
            AbstractionsScope,
            isStatic: true,
            isOverride: false,
            parameters);

    private static void AddScopedStaticMethod(
        List<string> lines,
        string declaringType,
        string returnType,
        string name,
        string scope,
        params string[] parameters) =>
        AddMethod(
            lines,
            declaringType,
            returnType,
            name,
            scope,
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
            AbstractionsScope,
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
            AbstractionsScope,
            isStatic: false,
            isOverride: true,
            parameters);

    private static void AddMethod(
        List<string> lines,
        string declaringType,
        string returnType,
        string name,
        string scope,
        bool isStatic,
        bool isOverride,
        params string[] parameters) =>
        lines.Add(
            $"M|{scope}|{declaringType}|{(isStatic ? "S" : "I")}|" +
            $"{(isOverride ? "override" : "plain")}|{returnType}|{name}|" +
            string.Join(',', parameters));

    private static string Arg(string name, string type) =>
        $"{name}:value:{type}:-";

    private static string Out(string name, string type, bool notNullWhenTrue) =>
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
            : parameter.ParameterType.IsByRef ? "ref" : "value";
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
            var arguments = type.GetGenericArguments();
            var annotatedArguments = nullability.GenericTypeArguments;
            formatted = $"{TypeAlias(type.GetGenericTypeDefinition())}<" +
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
        "System.Int32" => "int",
        "System.Object" => "object",
        "System.String" => "string",
        "System.Collections.Generic.IEnumerable`1" => "IEnumerable",
        "System.Collections.Generic.IReadOnlyList`1" => "IReadOnlyList",
        "System.IEquatable`1" => "IEquatable",
        _ => type.Name.Contains('`')
            ? type.Name[..type.Name.IndexOf('`')]
            : type.Name,
    };

    private static IEnumerable<Type> GetDeclaredInterfaces(Type type)
    {
        var inheritedInterfaces = type.BaseType?.GetInterfaces() ?? [];
        return type.GetInterfaces().Except(inheritedInterfaces);
    }

    private static IEnumerable<Type> GetBTypes(
        Assembly abstractions,
        Assembly conformance) =>
        AbstractionsB
            .Select(name => RequireType(abstractions, name))
            .Concat(ConformanceB.Select(name => RequireType(conformance, name)));

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

    private static Type RequireType(Assembly assembly, string name) =>
        assembly.GetType(
            $"{assembly.GetName().Name}.{name}",
            throwOnError: true,
            ignoreCase: false)!;

    private static Assembly LoadAssembly(string name) =>
        Assembly.Load(new AssemblyName(name));

    private static bool IsSerializerAttribute(CustomAttributeData attribute) =>
        attribute.AttributeType.FullName is
            "System.Runtime.Serialization.DataContractAttribute" or
            "System.Runtime.Serialization.DataMemberAttribute" or
            "System.Text.Json.Serialization.JsonConstructorAttribute" or
            "System.Text.Json.Serialization.JsonConverterAttribute" or
            "System.Text.Json.Serialization.JsonPropertyNameAttribute";
}

public sealed class ContractSliceBOwnershipTests
{
    private const BindingFlags DeclaredNonPublicStatic =
        BindingFlags.NonPublic |
        BindingFlags.Static |
        BindingFlags.DeclaredOnly;

    [Fact]
    [Trait("ContractSlice", "B")]
    public void Enforces_exact_friend_factory_and_negative_surface()
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

        var abstractions = LoadAssembly(
            "MeAndAI.Protocol.Conformance.Abstractions");
        var conformance = LoadAssembly("MeAndAI.Protocol.Conformance");
        var domain = LoadAssembly("MeAndAI.Protocol.Domain");

        Assert.Equal(37, domain.GetExportedTypes().Length);
        AssertFactory(abstractions, "QualifiedEvidenceHandle", []);
        AssertFactory(
            abstractions,
            "RepositoryEntryView",
            ["String", "RepositoryEntryKind", "QualifiedEvidenceHandle"]);
        AssertFactory(
            abstractions,
            "ProtocolRecordMemberView",
            ["String", "Int32", "QualifiedEvidenceHandle"]);
        AssertFactory(
            abstractions,
            "ProtocolRecordView",
            [
                "String",
                "String",
                "Int32",
                "QualifiedEvidenceHandle",
                "IEnumerable`1",
            ]);
        AssertFactory(
            abstractions,
            "GovernedReferenceView",
            [
                "GovernedReferenceKind",
                "GovernedReferenceSyntax",
                "GovernedReferenceResolution",
                "String",
                "String",
                "String",
                "String",
                "String",
                "String",
                "QualifiedEvidenceHandle",
                "QualifiedEvidenceHandle",
            ]);
        AssertFactory(
            abstractions,
            "RepositoryTargetResolutionDemandItem",
            ["Int32", "String", "String", "String", "String", "String", "String"]);
        AssertFactory(
            abstractions,
            "RepositoryTargetResolutionView",
            [
                "QualifiedEvidenceHandle",
                "GovernedReferenceResolution",
                "QualifiedEvidenceHandle",
                "QualifiedEvidenceHandle",
                "QualifiedEvidenceHandle",
                "QualifiedEvidenceHandle",
            ]);

        foreach (var forbidden in new[]
                 {
                     "IPayloadCodec",
                 })
        {
            Assert.Null(abstractions.GetType(
                $"MeAndAI.Protocol.Conformance.Abstractions.{forbidden}",
                throwOnError: false,
                ignoreCase: false));
        }

        foreach (var forbidden in new[]
                 {
                     "CatalogSliceKernel",
                     "ConformanceKernel",
                     "DecodeModelCache",
                 })
        {
            Assert.Null(conformance.GetType(
                $"MeAndAI.Protocol.Conformance.{forbidden}",
                throwOnError: false,
                ignoreCase: false));
        }

        Assert.Empty(LoadAssembly("MeAndAI.Protocol.Policy").GetExportedTypes());
    }

    private static void AssertFactory(
        Assembly assembly,
        string typeName,
        IReadOnlyList<string> parameterTypeNames)
    {
        var type = assembly.GetType(
            $"{assembly.GetName().Name}.{typeName}",
            throwOnError: true,
            ignoreCase: false)!;
        var create = Assert.Single(
            type.GetMethods(DeclaredNonPublicStatic),
            method => method.Name == "Create");

        Assert.True(create.IsAssembly);
        Assert.True(create.IsStatic);
        Assert.Equal(type, create.ReturnType);
        Assert.Equal(
            parameterTypeNames,
            create.GetParameters().Select(parameter => parameter.ParameterType.Name));
    }

    private static void AssertFriendAssemblies(
        string assemblyName,
        IEnumerable<string> expectedFriends)
    {
        var actual = LoadAssembly(assemblyName)
            .GetCustomAttributes<InternalsVisibleToAttribute>()
            .Select(attribute => new AssemblyName(attribute.AssemblyName).Name
                ?? throw new InvalidDataException(
                    "InternalsVisibleTo has no simple assembly name."))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expectedFriends.Order(StringComparer.Ordinal), actual);
    }

    private static Assembly LoadAssembly(string name) =>
        Assembly.Load(new AssemblyName(name));
}
