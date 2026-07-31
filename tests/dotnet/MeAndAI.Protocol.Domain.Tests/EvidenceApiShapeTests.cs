using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class EvidenceApiShapeTests
{
    private const BindingFlags DeclaredPublic =
        BindingFlags.Public |
        BindingFlags.Instance |
        BindingFlags.Static |
        BindingFlags.DeclaredOnly;

    private static readonly TypeExpectation[] Expectations =
    [
        Equatable<EvidenceConsistencyClass>(
            [
                Property("ExactSnapshot", typeof(EvidenceConsistencyClass),
                    isStatic: true),
                Property("ObjectVersionBound", typeof(EvidenceConsistencyClass),
                    isStatic: true),
                Property(
                    "BoundedNonAtomicObservation",
                    typeof(EvidenceConsistencyClass),
                    isStatic: true),
                Property(
                    "InsufficientConsistency",
                    typeof(EvidenceConsistencyClass),
                    isStatic: true),
                Property("Value", typeof(string)),
            ],
            Method(
                "Parse",
                isStatic: true,
                typeof(EvidenceConsistencyClass),
                Parameter("value", typeof(string))),
            Method(
                "TryParse",
                isStatic: true,
                typeof(bool),
                Parameter("value", typeof(string), isNullable: true),
                Parameter(
                    "result",
                    typeof(EvidenceConsistencyClass).MakeByRefType(),
                    isOut: true,
                    isNullable: true)),
            ToStringMethod()),
        Equatable<EvidenceRequirement>(
            [
                Property("Key", typeof(string)),
                Property("Surface", typeof(SurfaceKind)),
                Property("Kind", typeof(string)),
                Property("CompletenessContract", typeof(string)),
                Property("PayloadSchemaKey", typeof(string)),
                Property("PayloadSchemaVersion", typeof(string)),
                Property(
                    "AcceptedConsistencyClasses",
                    typeof(IReadOnlyList<EvidenceConsistencyClass>)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(EvidenceRequirement),
                Parameter("key", typeof(string)),
                Parameter("surface", typeof(SurfaceKind)),
                Parameter("kind", typeof(string)),
                Parameter("completenessContract", typeof(string)),
                Parameter("payloadSchemaKey", typeof(string)),
                Parameter("payloadSchemaVersion", typeof(string)),
                Parameter(
                    "acceptedConsistencyClasses",
                    typeof(IEnumerable<EvidenceConsistencyClass>)))),
        Equatable<AcquisitionTarget>(
            [
                Property("SubjectIdentity", typeof(string)),
                Property("SourceIdentity", typeof(string)),
                Property("Surface", typeof(SurfaceKind)),
                Property("SnapshotKind", typeof(SnapshotKind)),
                Property("TargetIdentity", typeof(string)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(AcquisitionTarget),
                Parameter("subjectIdentity", typeof(string)),
                Parameter("sourceIdentity", typeof(string)),
                Parameter("surface", typeof(SurfaceKind)),
                Parameter("snapshotKind", typeof(SnapshotKind)),
                Parameter("targetIdentity", typeof(string)))),
        Equatable<AcquisitionBoundary>(
            [
                Property("SnapshotKind", typeof(SnapshotKind)),
                Property("BoundaryIdentity", typeof(string)),
                Property("StartedAtUtc", typeof(DateTimeOffset)),
                Property("CompletedAtUtc", typeof(DateTimeOffset)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(AcquisitionBoundary),
                Parameter("snapshotKind", typeof(SnapshotKind)),
                Parameter("boundaryIdentity", typeof(string)),
                Parameter("startedAtUtc", typeof(DateTimeOffset)),
                Parameter("completedAtUtc", typeof(DateTimeOffset)))),
        Equatable<EvidenceScope>(
            [
                Property("Target", typeof(AcquisitionTarget)),
                Property("Boundary", typeof(AcquisitionBoundary)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(EvidenceScope),
                Parameter("target", typeof(AcquisitionTarget)),
                Parameter("boundary", typeof(AcquisitionBoundary)))),
        Equatable<AcquisitionRequest>(
            [
                Property("Target", typeof(AcquisitionTarget)),
                Property("AdapterKey", typeof(string)),
                Property("AdapterContractVersion", typeof(string)),
                Property("SourceContractKey", typeof(string)),
                Property("SourceContractVersion", typeof(string)),
                Property(
                    "RequestedRequirements",
                    typeof(IReadOnlyList<EvidenceRequirement>)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(AcquisitionRequest),
                Parameter("target", typeof(AcquisitionTarget)),
                Parameter("adapterKey", typeof(string)),
                Parameter("adapterContractVersion", typeof(string)),
                Parameter("sourceContractKey", typeof(string)),
                Parameter("sourceContractVersion", typeof(string)),
                Parameter(
                    "requestedRequirements",
                    typeof(IEnumerable<EvidenceRequirement>)))),
        AbstractUnion<EvidenceLocation>(
            [Property("Scope", typeof(EvidenceScope))]),
        UnionLeaf<RepositoryEvidenceLocation, EvidenceLocation>(
            [
                Property("RepositoryRelativePath", typeof(string)),
                Property("BlobIdentity", typeof(string), isNullable: true),
                Property("Line", typeof(int?)),
                Property("Anchor", typeof(string), isNullable: true),
                Property("Property", typeof(string), isNullable: true),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(RepositoryEvidenceLocation),
                Parameter("scope", typeof(EvidenceScope)),
                Parameter("repositoryRelativePath", typeof(string)),
                Parameter("blobIdentity", typeof(string), isNullable: true),
                Parameter("line", typeof(int?)),
                Parameter("anchor", typeof(string), isNullable: true),
                Parameter("property", typeof(string), isNullable: true))),
        UnionLeaf<ProviderEvidenceLocation, EvidenceLocation>(
            [
                Property("ProviderServiceIdentity", typeof(string)),
                Property("ObjectType", typeof(string)),
                Property("StableObjectIdentity", typeof(string)),
                Property("VersionIdentity", typeof(string)),
                Property("Field", typeof(string), isNullable: true),
                Property("Line", typeof(int?)),
                Property("Fragment", typeof(string), isNullable: true),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(ProviderEvidenceLocation),
                Parameter("scope", typeof(EvidenceScope)),
                Parameter("providerServiceIdentity", typeof(string)),
                Parameter("objectType", typeof(string)),
                Parameter("stableObjectIdentity", typeof(string)),
                Parameter("versionIdentity", typeof(string)),
                Parameter("field", typeof(string), isNullable: true),
                Parameter("line", typeof(int?)),
                Parameter("fragment", typeof(string), isNullable: true))),
        UnionLeaf<ReleaseAssetEvidenceLocation, EvidenceLocation>(
            [
                Property("ReleaseObjectIdentity", typeof(string)),
                Property("Tag", typeof(string)),
                Property("AssetName", typeof(string)),
                Property("AssetDigest", typeof(ExactSha256Digest)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(ReleaseAssetEvidenceLocation),
                Parameter("scope", typeof(EvidenceScope)),
                Parameter("releaseObjectIdentity", typeof(string)),
                Parameter("tag", typeof(string)),
                Parameter("assetName", typeof(string)),
                Parameter("assetDigest", typeof(ExactSha256Digest)))),
        UnionLeaf<SnapshotEvidenceLocation, EvidenceLocation>(
            [],
            Method(
                "Create",
                isStatic: true,
                typeof(SnapshotEvidenceLocation),
                Parameter("scope", typeof(EvidenceScope)))),
        Equatable<CanonicalEvidencePayload>(
            [
                Property("SchemaKey", typeof(string)),
                Property("SchemaVersion", typeof(string)),
                Property("ContentDigest", typeof(ExactSha256Digest)),
                Property("CanonicalBytes", typeof(IReadOnlyList<byte>)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(CanonicalEvidencePayload),
                Parameter("schemaKey", typeof(string)),
                Parameter("schemaVersion", typeof(string)),
                Parameter("canonicalBytes", typeof(IEnumerable<byte>)))),
        Equatable<EvidenceBinding>(
            [
                Property("Payload", typeof(CanonicalEvidencePayload)),
                Property("Location", typeof(EvidenceLocation)),
                Property(
                    "RequirementKeys",
                    typeof(IReadOnlyList<string>)),
                Property("CapturedAtUtc", typeof(DateTimeOffset)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(EvidenceBinding),
                Parameter("payload", typeof(CanonicalEvidencePayload)),
                Parameter("location", typeof(EvidenceLocation)),
                Parameter("requirementKeys", typeof(IEnumerable<string>)),
                Parameter("capturedAtUtc", typeof(DateTimeOffset)))),
        Equatable<RootEvidenceReference>(
            [
                Property("Scope", typeof(EvidenceScope)),
                Property("SchemaKey", typeof(string)),
                Property("SchemaVersion", typeof(string)),
                Property("ContentDigest", typeof(ExactSha256Digest)),
                Property("Location", typeof(EvidenceLocation)),
                Property(
                    "RequirementKeys",
                    typeof(IReadOnlyList<string>)),
                Property("CapturedAtUtc", typeof(DateTimeOffset)),
            ]),
        Equatable<AcquisitionFailure>(
            [
                Property("RequirementKey", typeof(string)),
                Property("Code", typeof(string)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(AcquisitionFailure),
                Parameter("requirementKey", typeof(string)),
                Parameter("code", typeof(string)))),
        Equatable<EvidenceRedaction>(
            [
                Property("None", typeof(EvidenceRedaction), isStatic: true),
                Property("RequiredValuesOmitted", typeof(bool)),
                Property("NonRequiredValuesOmitted", typeof(bool)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(EvidenceRedaction),
                Parameter("requiredValuesOmitted", typeof(bool)),
                Parameter("nonRequiredValuesOmitted", typeof(bool)))),
        Equatable<RequirementAcquisition>(
            [
                Property("Requirement", typeof(EvidenceRequirement)),
                Property(
                    "ConsistencyClass",
                    typeof(EvidenceConsistencyClass)),
                Property("Redaction", typeof(EvidenceRedaction)),
                Property(
                    "Failures",
                    typeof(IReadOnlyList<AcquisitionFailure>)),
                Property("Status", typeof(AcquisitionStatus)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(RequirementAcquisition),
                Parameter("requirement", typeof(EvidenceRequirement)),
                Parameter(
                    "consistencyClass",
                    typeof(EvidenceConsistencyClass)),
                Parameter("redaction", typeof(EvidenceRedaction)),
                Parameter(
                    "failures",
                    typeof(IEnumerable<AcquisitionFailure>)))),
        Equatable<AcquisitionPage>(
            [
                Property("Sequence", typeof(int)),
                Property(
                    "RequestCursorDigest",
                    typeof(ExactSha256Digest),
                    isNullable: true),
                Property(
                    "NextCursorDigest",
                    typeof(ExactSha256Digest),
                    isNullable: true),
                Property("SourceObjectCount", typeof(long)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(AcquisitionPage),
                Parameter("sequence", typeof(int)),
                Parameter(
                    "requestCursorDigest",
                    typeof(ExactSha256Digest),
                    isNullable: true),
                Parameter(
                    "nextCursorDigest",
                    typeof(ExactSha256Digest),
                    isNullable: true),
                Parameter("sourceObjectCount", typeof(long)))),
        Equatable<EvidenceContext>(
            [
                Property("Request", typeof(AcquisitionRequest)),
                Property("Scope", typeof(EvidenceScope)),
                Property(
                    "RequirementAcquisitions",
                    typeof(IReadOnlyList<RequirementAcquisition>)),
                Property(
                    "Bindings",
                    typeof(IReadOnlyList<EvidenceBinding>)),
                Property("Pages", typeof(IReadOnlyList<AcquisitionPage>)),
                Property("SourceObjectCount", typeof(long)),
                Property("Status", typeof(AcquisitionStatus)),
                Property(
                    "References",
                    typeof(IReadOnlyList<RootEvidenceReference>)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(EvidenceContext),
                Parameter("request", typeof(AcquisitionRequest)),
                Parameter("scope", typeof(EvidenceScope)),
                Parameter(
                    "requirementAcquisitions",
                    typeof(IEnumerable<RequirementAcquisition>)),
                Parameter(
                    "bindings",
                    typeof(IEnumerable<EvidenceBinding>)),
                Parameter("pages", typeof(IEnumerable<AcquisitionPage>)),
                Parameter("sourceObjectCount", typeof(long)))),
        AbstractUnion<AcquisitionResult>(
            [
                Property("Request", typeof(AcquisitionRequest)),
                Property("Status", typeof(AcquisitionStatus)),
            ]),
        UnionLeaf<ObservedAcquisitionResult, AcquisitionResult>(
            [Property("Context", typeof(EvidenceContext))],
            Method(
                "Create",
                isStatic: true,
                typeof(ObservedAcquisitionResult),
                Parameter("context", typeof(EvidenceContext)))),
        UnionLeaf<AbsentAcquisitionResult, AcquisitionResult>(
            [],
            Method(
                "Create",
                isStatic: true,
                typeof(AbsentAcquisitionResult),
                Parameter("request", typeof(AcquisitionRequest)))),
        UnionLeaf<FailedAcquisitionResult, AcquisitionResult>(
            [
                Property("StartedAtUtc", typeof(DateTimeOffset)),
                Property("FailedAtUtc", typeof(DateTimeOffset)),
                Property(
                    "Failures",
                    typeof(IReadOnlyList<AcquisitionFailure>)),
            ],
            Method(
                "Create",
                isStatic: true,
                typeof(FailedAcquisitionResult),
                Parameter("request", typeof(AcquisitionRequest)),
                Parameter("startedAtUtc", typeof(DateTimeOffset)),
                Parameter("failedAtUtc", typeof(DateTimeOffset)),
                Parameter(
                    "failures",
                    typeof(IEnumerable<AcquisitionFailure>)))),
    ];

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void SliceTypesExposeOnlyTheExactDeclaredPublicApi()
    {
        Assert.Equal(23, Expectations.Length);
        Assert.Equal(
            Expectations.Length,
            Expectations.Select(value => value.Type).Distinct().Count());

        foreach (var expectation in Expectations)
        {
            AssertType(expectation);
            AssertProperties(expectation);
            AssertMethods(expectation);
        }

        Assert.Empty(typeof(RootEvidenceReference).GetMethods(
            BindingFlags.Public |
            BindingFlags.Static |
            BindingFlags.DeclaredOnly));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void SliceTypesCarryTheExactReferenceNullability()
    {
        var context = new NullabilityInfoContext();

        foreach (var expectation in Expectations)
        {
            foreach (var propertyExpectation in expectation.Properties)
            {
                var property = expectation.Type.GetProperty(
                    propertyExpectation.Name,
                    DeclaredPublic);
                Assert.NotNull(property);
                if (!property!.PropertyType.IsValueType)
                {
                    AssertNullability(
                        context.Create(property),
                        propertyExpectation.IsNullable,
                        useWriteState: false);
                }
            }

            foreach (var methodExpectation in expectation.Methods)
            {
                var method = FindMethod(expectation.Type, methodExpectation);
                if (!method.ReturnType.IsValueType)
                {
                    AssertNullability(
                        context.Create(method.ReturnParameter),
                        methodExpectation.IsReturnNullable,
                        useWriteState: false);
                }

                var parameters = method.GetParameters();
                for (var index = 0;
                    index < methodExpectation.Parameters.Length;
                    index++)
                {
                    var parameterExpectation =
                        methodExpectation.Parameters[index];
                    var parameter = parameters[index];
                    var effectiveType = parameter.ParameterType.IsByRef
                        ? parameter.ParameterType.GetElementType()!
                        : parameter.ParameterType;

                    if (!effectiveType.IsValueType)
                    {
                        AssertNullability(
                            context.Create(parameter),
                            parameterExpectation.IsNullable,
                            useWriteState: parameter.IsOut);
                    }
                }
            }
        }

        var tryParse = FindMethod(
            typeof(EvidenceConsistencyClass),
            Method(
                "TryParse",
                isStatic: true,
                typeof(bool),
                Parameter("value", typeof(string), isNullable: true),
                Parameter(
                    "result",
                    typeof(EvidenceConsistencyClass).MakeByRefType(),
                    isOut: true,
                    isNullable: true)));
        var resultParameter = Assert.Single(
            tryParse.GetParameters(),
            parameter => parameter.Name == "result");
        var attribute = Assert.Single(
            resultParameter.GetCustomAttributes<NotNullWhenAttribute>());
        Assert.True(attribute.ReturnValue);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void UnionBasesAndLeavesAreExactlyClosed()
    {
        AssertClosedUnion(
            typeof(EvidenceLocation),
            [typeof(EvidenceScope)],
            typeof(RepositoryEvidenceLocation),
            typeof(ProviderEvidenceLocation),
            typeof(ReleaseAssetEvidenceLocation),
            typeof(SnapshotEvidenceLocation));
        AssertClosedUnion(
            typeof(AcquisitionResult),
            [typeof(AcquisitionRequest), typeof(AcquisitionStatus)],
            typeof(ObservedAcquisitionResult),
            typeof(AbsentAcquisitionResult),
            typeof(FailedAcquisitionResult));
    }

    private static TypeExpectation Equatable<T>(
        PropertyExpectation[] properties,
        params MethodExpectation[] additionalMethods)
    {
        var type = typeof(T);
        return new TypeExpectation(
            type,
            typeof(object),
            IsAbstract: false,
            [typeof(IEquatable<T>)],
            properties,
            [.. additionalMethods
, .. StandardEquality(type)]);
    }

    private static TypeExpectation AbstractUnion<T>(
        PropertyExpectation[] properties)
    {
        var type = typeof(T);
        return new TypeExpectation(
            type,
            typeof(object),
            IsAbstract: true,
            [typeof(IEquatable<T>)],
            properties,
            StandardEquality(type));
    }

    private static TypeExpectation UnionLeaf<TLeaf, TBase>(
        PropertyExpectation[] properties,
        params MethodExpectation[] methods) =>
        new(
            typeof(TLeaf),
            typeof(TBase),
            IsAbstract: false,
            [typeof(IEquatable<TBase>)],
            properties,
            methods);

    private static MethodExpectation[] StandardEquality(Type type) =>
    [
        Method(
            "Equals",
            isStatic: false,
            typeof(bool),
            Parameter("other", type, isNullable: true)),
        Method(
            "Equals",
            isStatic: false,
            typeof(bool),
            Parameter("obj", typeof(object), isNullable: true)),
        Method("GetHashCode", isStatic: false, typeof(int)),
    ];

    private static MethodExpectation ToStringMethod() =>
        Method("ToString", isStatic: false, typeof(string));

    private static PropertyExpectation Property(
        string name,
        Type type,
        bool isStatic = false,
        bool isNullable = false) =>
        new(name, type, isStatic, isNullable);

    private static MethodExpectation Method(
        string name,
        bool isStatic,
        Type returnType,
        params ParameterExpectation[] parameters) =>
        new(
            name,
            isStatic,
            returnType,
            IsReturnNullable: false,
            parameters);

    private static ParameterExpectation Parameter(
        string name,
        Type type,
        bool isOut = false,
        bool isNullable = false) =>
        new(name, type, isOut, isNullable);

    private static void AssertType(TypeExpectation expectation)
    {
        var type = expectation.Type;
        Assert.True(type.IsClass);
        Assert.True(type.IsPublic);
        Assert.False(type.IsEnum);
        Assert.Equal("MeAndAI.Protocol.Domain", type.Namespace);
        Assert.Equal(expectation.BaseType, type.BaseType);
        Assert.Equal(expectation.IsAbstract, type.IsAbstract);
        Assert.Equal(!expectation.IsAbstract, type.IsSealed);
        Assert.Equal(
            expectation.Interfaces
                .OrderBy(InterfaceName, StringComparer.Ordinal),
            type.GetInterfaces()
                .OrderBy(InterfaceName, StringComparer.Ordinal));
        Assert.Empty(type.GetConstructors(
            BindingFlags.Public | BindingFlags.Instance));
        Assert.Empty(type.GetFields(DeclaredPublic));
        Assert.Empty(type.GetEvents(DeclaredPublic));
        Assert.Empty(type.GetNestedTypes(
            BindingFlags.Public | BindingFlags.DeclaredOnly));
        Assert.DoesNotContain(
            type.GetMethods(DeclaredPublic),
            method => method.Name is "op_Implicit" or "op_Explicit");
    }

    private static void AssertProperties(TypeExpectation expectation)
    {
        var properties = expectation.Type
            .GetProperties(DeclaredPublic)
            .OrderBy(property => property.Name, StringComparer.Ordinal)
            .ToArray();
        var expected = expectation.Properties
            .OrderBy(property => property.Name, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expected.Length, properties.Length);
        for (var index = 0; index < expected.Length; index++)
        {
            Assert.Equal(expected[index].Name, properties[index].Name);
            Assert.Equal(expected[index].Type, properties[index].PropertyType);
            Assert.True(properties[index].CanRead);
            Assert.NotNull(properties[index].GetMethod);
            Assert.True(properties[index].GetMethod!.IsPublic);
            Assert.Equal(
                expected[index].IsStatic,
                properties[index].GetMethod!.IsStatic);
            Assert.Null(properties[index].SetMethod);
            Assert.Empty(properties[index].GetIndexParameters());
        }

        var accessors = properties
            .SelectMany(property => property.GetAccessors(nonPublic: false))
            .ToHashSet();
        var declaredSpecialMethods = expectation.Type
            .GetMethods(DeclaredPublic)
            .Where(method => method.IsSpecialName)
            .ToArray();
        Assert.All(
            declaredSpecialMethods,
            method => Assert.Contains(method, accessors));
    }

    private static void AssertMethods(TypeExpectation expectation)
    {
        var methods = expectation.Type
            .GetMethods(DeclaredPublic)
            .Where(method => !method.IsSpecialName)
            .OrderBy(MethodKey, StringComparer.Ordinal)
            .ToArray();
        var expected = expectation.Methods
            .OrderBy(MethodKey, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expected.Length, methods.Length);
        for (var index = 0; index < expected.Length; index++)
        {
            var method = methods[index];
            var methodExpectation = expected[index];
            var parameters = method.GetParameters();

            Assert.Equal(methodExpectation.Name, method.Name);
            Assert.Equal(methodExpectation.IsStatic, method.IsStatic);
            Assert.Equal(methodExpectation.ReturnType, method.ReturnType);
            Assert.False(method.IsGenericMethod);
            Assert.Equal(methodExpectation.Parameters.Length, parameters.Length);

            for (var parameterIndex = 0;
                parameterIndex < methodExpectation.Parameters.Length;
                parameterIndex++)
            {
                var parameter = parameters[parameterIndex];
                var parameterExpectation =
                    methodExpectation.Parameters[parameterIndex];

                Assert.Equal(parameterExpectation.Name, parameter.Name);
                Assert.Equal(
                    parameterExpectation.Type,
                    parameter.ParameterType);
                Assert.Equal(parameterExpectation.IsOut, parameter.IsOut);
                Assert.False(parameter.IsOptional);
                Assert.False(parameter.HasDefaultValue);
                Assert.Empty(
                    parameter.GetCustomAttributes<ParamArrayAttribute>());
            }

            if (method.Name is "GetHashCode" or "ToString" ||
                (method.Name == "Equals" &&
                 method.GetParameters().Single().ParameterType ==
                 typeof(object)))
            {
                Assert.Equal(
                    typeof(object),
                    method.GetBaseDefinition().DeclaringType);
            }
        }
    }

    private static MethodInfo FindMethod(
        Type type,
        MethodExpectation expectation) =>
        Assert.Single(
            type.GetMethods(DeclaredPublic)
                .Where(method => !method.IsSpecialName),
            method => MethodKey(method) == MethodKey(expectation));

    private static void AssertNullability(
        NullabilityInfo info,
        bool isNullable,
        bool useWriteState)
    {
        Assert.Equal(
            isNullable ? NullabilityState.Nullable : NullabilityState.NotNull,
            useWriteState ? info.WriteState : info.ReadState);

        foreach (var argument in info.GenericTypeArguments)
        {
            if (!argument.Type.IsValueType)
            {
                Assert.Equal(NullabilityState.NotNull, argument.ReadState);
            }

            AssertGenericArgumentsAreNotNullable(argument);
        }
    }

    private static void AssertGenericArgumentsAreNotNullable(
        NullabilityInfo info)
    {
        foreach (var argument in info.GenericTypeArguments)
        {
            if (!argument.Type.IsValueType)
            {
                Assert.Equal(NullabilityState.NotNull, argument.ReadState);
            }

            AssertGenericArgumentsAreNotNullable(argument);
        }
    }

    private static void AssertClosedUnion(
        Type baseType,
        Type[] constructorParameters,
        params Type[] leaves)
    {
        var constructor = Assert.Single(baseType.GetConstructors(
            BindingFlags.Instance | BindingFlags.NonPublic));
        Assert.True(constructor.IsFamilyAndAssembly);
        Assert.Equal(
            constructorParameters,
            constructor.GetParameters().Select(parameter => parameter.ParameterType));

        var actualLeaves = baseType.Assembly
            .GetTypes()
            .Where(type => type.BaseType == baseType)
            .OrderBy(type => type.FullName, StringComparer.Ordinal)
            .ToArray();
        Assert.Equal(
            leaves.OrderBy(type => type.FullName, StringComparer.Ordinal),
            actualLeaves);
        Assert.All(actualLeaves, type => Assert.True(type.IsSealed));

        foreach (var methodName in new[] { "Equals", "GetHashCode" })
        {
            var method = Assert.Single(baseType.GetMethods(DeclaredPublic), value =>
                value.Name == methodName &&
                (methodName != "Equals" ||
                 value.GetParameters().Single().ParameterType == typeof(object)));
            Assert.False(method.IsAbstract);
            Assert.True(method.IsFinal);
            Assert.Equal(typeof(object), method.GetBaseDefinition().DeclaringType);
        }
    }

    private static string InterfaceName(Type type) =>
        type.FullName ?? type.Name;

    private static string MethodKey(MethodInfo method) =>
        $"{method.Name}|{method.IsStatic}|" +
        string.Join(
            ",",
            method.GetParameters().Select(parameter =>
                parameter.ParameterType.ToString()));

    private static string MethodKey(MethodExpectation method) =>
        $"{method.Name}|{method.IsStatic}|" +
        string.Join(
            ",",
            method.Parameters.Select(parameter => parameter.Type.ToString()));

    private sealed record TypeExpectation(
        Type Type,
        Type BaseType,
        bool IsAbstract,
        Type[] Interfaces,
        PropertyExpectation[] Properties,
        MethodExpectation[] Methods);

    private sealed record PropertyExpectation(
        string Name,
        Type Type,
        bool IsStatic,
        bool IsNullable);

    private sealed record MethodExpectation(
        string Name,
        bool IsStatic,
        Type ReturnType,
        bool IsReturnNullable,
        ParameterExpectation[] Parameters);

    private sealed record ParameterExpectation(
        string Name,
        Type Type,
        bool IsOut,
        bool IsNullable);
}
