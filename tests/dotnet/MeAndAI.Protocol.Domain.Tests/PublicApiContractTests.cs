using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class PublicApiContractTests
{
    private static readonly Type[] CategoricalTypes =
    [
        typeof(SubjectRole),
        typeof(ProtocolOperation),
        typeof(SnapshotKind),
        typeof(SurfaceKind),
        typeof(EnforcementPhase),
        typeof(AcquisitionStatus),
        typeof(RuleEvaluationStatus),
        typeof(ConformanceVerdict),
        typeof(EnforcementDecision),
    ];

    private static readonly Dictionary<Type, string[]>
        CategoricalPropertyNames = new()
        {
            [typeof(SubjectRole)] =
            [
                "Consumer",
                "ProtocolAuthoritySelfConsumer",
            ],
            [typeof(ProtocolOperation)] =
            [
                "AdoptionApply",
                "AdoptionAssessment",
                "AdoptionPlan",
                "Conformance",
                "Finalization",
                "Publication",
                "Recovery",
                "UpdateApply",
                "UpdateAssessment",
                "UpdatePlan",
            ],
            [typeof(SnapshotKind)] =
            [
                "Candidate",
                "CapturedEvidence",
                "ExactCommit",
                "ProviderEvent",
                "ProviderFullInventory",
            ],
            [typeof(SurfaceKind)] =
            [
                "Provider",
                "Release",
                "Repository",
                "Workflow",
            ],
            [typeof(EnforcementPhase)] =
            [
                "Audit",
                "FullBlocking",
                "Prospective",
            ],
            [typeof(AcquisitionStatus)] =
            [
                "Complete",
                "Failed",
                "Incomplete",
            ],
            [typeof(RuleEvaluationStatus)] =
            [
                "NotApplicable",
                "NotEvaluated",
                "Satisfied",
                "Violated",
            ],
            [typeof(ConformanceVerdict)] =
            [
                "Conforming",
                "Indeterminate",
                "NonConforming",
            ],
            [typeof(EnforcementDecision)] =
            [
                "Allow",
                "Block",
                "ReportOnly",
            ],
        };

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void TypesHaveExactReferenceShapeInterfacesAndNoPublicConstructors()
    {
        var expectedExportedTypes = new[]
        {
            typeof(AcquisitionStatus),
            typeof(ConformanceVerdict),
            typeof(EnforcementDecision),
            typeof(EnforcementPhase),
            typeof(ExactSha256Digest),
            typeof(ExecutionProfile),
            typeof(ProtocolOperation),
            typeof(RuleEvaluationStatus),
            typeof(RuleId),
            typeof(RuleRevision),
            typeof(SnapshotKind),
            typeof(SubjectRole),
            typeof(SurfaceKind),
            typeof(SurfaceSet),
        };
        var exportedTypes = typeof(RuleId).Assembly
            .GetExportedTypes()
            .OrderBy(type => type.FullName, StringComparer.Ordinal)
            .ToArray();

        Assert.All(
            expectedExportedTypes,
            expectedType => Assert.Contains(expectedType, exportedTypes));
        AssertTypeShape(
            typeof(RuleId),
            typeof(IComparable<RuleId>),
            typeof(IEquatable<RuleId>));
        AssertTypeShape(
            typeof(RuleRevision),
            typeof(IComparable<RuleRevision>),
            typeof(IEquatable<RuleRevision>));
        AssertTypeShape(
            typeof(ExactSha256Digest),
            typeof(IComparable<ExactSha256Digest>),
            typeof(IEquatable<ExactSha256Digest>));
        AssertTypeShape(typeof(SurfaceSet), typeof(IEquatable<SurfaceSet>));
        AssertTypeShape(
            typeof(ExecutionProfile),
            typeof(IEquatable<ExecutionProfile>));

        foreach (var type in CategoricalTypes)
        {
            AssertTypeShape(type, typeof(IEquatable<>).MakeGenericType(type));
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DeclaredPropertiesAreExactAndReadOnly()
    {
        AssertProperties(
            typeof(RuleId),
            new PropertyExpectation("Value", typeof(string), IsStatic: false));
        AssertProperties(
            typeof(RuleRevision),
            new PropertyExpectation("Value", typeof(int), IsStatic: false));
        AssertProperties(
            typeof(ExactSha256Digest),
            new PropertyExpectation("Value", typeof(string), IsStatic: false));
        AssertProperties(
            typeof(SurfaceSet),
            new PropertyExpectation(
                "Values",
                typeof(IReadOnlyList<SurfaceKind>),
                IsStatic: false));
        AssertProperties(
            typeof(ExecutionProfile),
            new PropertyExpectation(
                "EnforcementPhase",
                typeof(EnforcementPhase),
                IsStatic: false),
            new PropertyExpectation(
                "Operation",
                typeof(ProtocolOperation),
                IsStatic: false),
            new PropertyExpectation(
                "SnapshotKind",
                typeof(SnapshotKind),
                IsStatic: false),
            new PropertyExpectation(
                "SubjectRole",
                typeof(SubjectRole),
                IsStatic: false),
            new PropertyExpectation(
                "Surfaces",
                typeof(SurfaceSet),
                IsStatic: false));

        foreach (var type in CategoricalTypes)
        {
            var expected = CategoricalPropertyNames[type]
                .Select(name => new PropertyExpectation(
                    name,
                    type,
                    IsStatic: true))
                .Append(new PropertyExpectation(
                    "Value",
                    typeof(string),
                    IsStatic: false))
                .ToArray();

            AssertProperties(type, expected);
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DeclaredMethodsAndSourceParameterNamesAreExact()
    {
        AssertMethods(
            typeof(RuleId),
            ParseMethod(typeof(RuleId)),
            TryParseMethod(typeof(RuleId)),
            ComparableMethod(typeof(RuleId)),
            TypedEqualsMethod(typeof(RuleId)),
            ObjectEqualsMethod(),
            GetHashCodeMethod(),
            ToStringMethod());
        AssertMethods(
            typeof(RuleRevision),
            new MethodExpectation(
                "Create",
                IsStatic: true,
                typeof(RuleRevision),
                new ParameterExpectation("value", typeof(int))),
            ComparableMethod(typeof(RuleRevision)),
            TypedEqualsMethod(typeof(RuleRevision)),
            ObjectEqualsMethod(),
            GetHashCodeMethod(),
            ToStringMethod());
        AssertMethods(
            typeof(ExactSha256Digest),
            ParseMethod(typeof(ExactSha256Digest)),
            TryParseMethod(typeof(ExactSha256Digest)),
            new MethodExpectation(
                "FromHashBytes",
                IsStatic: true,
                typeof(ExactSha256Digest),
                new ParameterExpectation(
                    "hashBytes",
                    typeof(ReadOnlySpan<byte>))),
            ComparableMethod(typeof(ExactSha256Digest)),
            TypedEqualsMethod(typeof(ExactSha256Digest)),
            ObjectEqualsMethod(),
            GetHashCodeMethod(),
            ToStringMethod());
        AssertMethods(
            typeof(SurfaceSet),
            new MethodExpectation(
                "Create",
                IsStatic: true,
                typeof(SurfaceSet),
                new ParameterExpectation(
                    "surfaces",
                    typeof(IEnumerable<SurfaceKind>))),
            TypedEqualsMethod(typeof(SurfaceSet)),
            ObjectEqualsMethod(),
            GetHashCodeMethod(),
            ToStringMethod());
        AssertMethods(
            typeof(ExecutionProfile),
            new MethodExpectation(
                "Create",
                IsStatic: true,
                typeof(ExecutionProfile),
                new ParameterExpectation("subjectRole", typeof(SubjectRole)),
                new ParameterExpectation(
                    "operation",
                    typeof(ProtocolOperation)),
                new ParameterExpectation(
                    "snapshotKind",
                    typeof(SnapshotKind)),
                new ParameterExpectation("surfaces", typeof(SurfaceSet)),
                new ParameterExpectation(
                    "enforcementPhase",
                    typeof(EnforcementPhase))),
            TypedEqualsMethod(typeof(ExecutionProfile)),
            ObjectEqualsMethod(),
            GetHashCodeMethod());

        foreach (var type in CategoricalTypes)
        {
            AssertMethods(
                type,
                ParseMethod(type),
                TryParseMethod(type),
                TypedEqualsMethod(type),
                ObjectEqualsMethod(),
                GetHashCodeMethod(),
                ToStringMethod());
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void TryParseOutResultsDeclareNotNullWhenTrue()
    {
        var tryParseTypes = new[]
        {
            typeof(RuleId),
            typeof(ExactSha256Digest),
        }
        .Concat(CategoricalTypes);

        foreach (var type in tryParseTypes)
        {
            var method = Assert.Single(
                type.GetMethods(BindingFlags.Public | BindingFlags.Static),
                candidate => candidate.Name == "TryParse");
            var parameters = method.GetParameters();

            var attribute = Assert.Single(
                parameters[1].GetCustomAttributes<NotNullWhenAttribute>());
            Assert.True(attribute.ReturnValue);
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void NullableAnnotationsMatchTheExactSourceContract()
    {
        var context = new NullabilityInfoContext();
        var parseTypes = new[]
        {
            typeof(RuleId),
            typeof(ExactSha256Digest),
        }
        .Concat(CategoricalTypes);

        foreach (var type in parseTypes)
        {
            AssertParameterNullability(
                context,
                type,
                "Parse",
                "value",
                NullabilityState.NotNull);
            AssertParameterNullability(
                context,
                type,
                "TryParse",
                "value",
                NullabilityState.Nullable);
            AssertParameterNullability(
                context,
                type,
                "TryParse",
                "result",
                NullabilityState.Nullable,
                useWriteState: true);
        }

        foreach (var type in new[]
        {
            typeof(RuleId),
            typeof(RuleRevision),
            typeof(ExactSha256Digest),
        })
        {
            AssertParameterNullability(
                context,
                type,
                "CompareTo",
                "other",
                NullabilityState.Nullable);
        }

        foreach (var type in parseTypes
            .Append(typeof(RuleRevision))
            .Append(typeof(SurfaceSet))
            .Append(typeof(ExecutionProfile)))
        {
            AssertParameterNullability(
                context,
                type,
                "Equals",
                "other",
                NullabilityState.Nullable);
            AssertParameterNullability(
                context,
                type,
                "Equals",
                "obj",
                NullabilityState.Nullable);
        }

        AssertParameterNullability(
            context,
            typeof(SurfaceSet),
            "Create",
            "surfaces",
            NullabilityState.NotNull);
        foreach (var parameterName in new[]
        {
            "subjectRole",
            "operation",
            "snapshotKind",
            "surfaces",
            "enforcementPhase",
        })
        {
            AssertParameterNullability(
                context,
                typeof(ExecutionProfile),
                "Create",
                parameterName,
                NullabilityState.NotNull);
        }

        var referenceProperties = new[]
        {
            typeof(RuleId),
            typeof(ExactSha256Digest),
            typeof(SurfaceSet),
            typeof(ExecutionProfile),
        }
        .Concat(CategoricalTypes)
        .SelectMany(type => type.GetProperties(
            BindingFlags.Public |
            BindingFlags.Instance |
            BindingFlags.Static |
            BindingFlags.DeclaredOnly))
        .Where(property => !property.PropertyType.IsValueType);

        Assert.All(
            referenceProperties,
            property => Assert.Equal(
                NullabilityState.NotNull,
                context.Create(property).ReadState));

        var surfaceValuesNullability = context.Create(
            typeof(SurfaceSet).GetProperty(nameof(SurfaceSet.Values))
                ?? throw new InvalidOperationException(
                    "SurfaceSet.Values is missing."));
        Assert.Equal(
            NullabilityState.NotNull,
            Assert.Single(surfaceValuesNullability.GenericTypeArguments).ReadState);

        var surfacesParameter = Assert.Single(typeof(SurfaceSet)
            .GetMethod(nameof(SurfaceSet.Create))!
            .GetParameters());
        var surfacesNullability = context.Create(surfacesParameter);
        Assert.Equal(
            NullabilityState.NotNull,
            Assert.Single(surfacesNullability.GenericTypeArguments).ReadState);

        var referenceReturns = new[]
        {
            typeof(RuleId),
            typeof(RuleRevision),
            typeof(ExactSha256Digest),
            typeof(SurfaceSet),
            typeof(ExecutionProfile),
        }
        .Concat(CategoricalTypes)
        .SelectMany(type => type.GetMethods(
            BindingFlags.Public |
            BindingFlags.Instance |
            BindingFlags.Static |
            BindingFlags.DeclaredOnly))
        .Where(method =>
            !method.IsSpecialName && !method.ReturnType.IsValueType);

        Assert.All(
            referenceReturns,
            method => Assert.Equal(
                NullabilityState.NotNull,
                context.Create(method.ReturnParameter).ReadState));
    }

    private static void AssertTypeShape(Type type, params Type[] interfaces)
    {
        Assert.True(type.IsClass);
        Assert.True(type.IsSealed);
        Assert.False(type.IsAbstract);
        Assert.False(type.IsEnum);
        Assert.True(type.IsPublic);
        Assert.Equal("MeAndAI.Protocol.Domain", type.Namespace);
        Assert.Equal(typeof(object), type.BaseType);
        Assert.Empty(type.GetConstructors(
            BindingFlags.Public | BindingFlags.Instance));
        Assert.Equal(
            interfaces.OrderBy(InterfaceName, StringComparer.Ordinal),
            type.GetInterfaces().OrderBy(InterfaceName, StringComparer.Ordinal));
        Assert.Empty(type.GetFields(
            BindingFlags.Public |
            BindingFlags.Instance |
            BindingFlags.Static |
            BindingFlags.DeclaredOnly));
        Assert.Empty(type.GetEvents(
            BindingFlags.Public |
            BindingFlags.Instance |
            BindingFlags.Static |
            BindingFlags.DeclaredOnly));
        Assert.Empty(type.GetNestedTypes(
            BindingFlags.Public | BindingFlags.DeclaredOnly));
    }

    private static void AssertProperties(
        Type type,
        params PropertyExpectation[] expected)
    {
        var properties = type
            .GetProperties(
                BindingFlags.Public |
                BindingFlags.Instance |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly)
            .OrderBy(property => property.Name, StringComparer.Ordinal)
            .ToArray();
        var orderedExpected = expected
            .OrderBy(property => property.Name, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(orderedExpected.Length, properties.Length);
        for (var index = 0; index < orderedExpected.Length; index++)
        {
            var expectation = orderedExpected[index];
            var property = properties[index];

            Assert.Equal(expectation.Name, property.Name);
            Assert.Equal(expectation.Type, property.PropertyType);
            Assert.Equal(
                expectation.IsStatic,
                property.GetMethod?.IsStatic ?? false);
            Assert.True(property.CanRead);
            Assert.NotNull(property.GetMethod);
            Assert.True(property.GetMethod!.IsPublic);
            Assert.Null(property.GetSetMethod(nonPublic: false));
            Assert.Empty(property.GetIndexParameters());
        }

        var propertyAccessors = properties
            .SelectMany(property => property.GetAccessors(nonPublic: false))
            .ToHashSet();
        var declaredSpecialMethods = type
            .GetMethods(
                BindingFlags.Public |
                BindingFlags.Instance |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly)
            .Where(method => method.IsSpecialName);

        Assert.All(
            declaredSpecialMethods,
            method => Assert.Contains(method, propertyAccessors));
    }

    private static void AssertMethods(
        Type type,
        params MethodExpectation[] expected)
    {
        var methods = type
            .GetMethods(
                BindingFlags.Public |
                BindingFlags.Instance |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly)
            .Where(method => !method.IsSpecialName)
            .OrderBy(MethodKey, StringComparer.Ordinal)
            .ToArray();
        var orderedExpected = expected
            .OrderBy(MethodKey, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(orderedExpected.Length, methods.Length);
        for (var index = 0; index < orderedExpected.Length; index++)
        {
            var expectation = orderedExpected[index];
            var method = methods[index];
            var parameters = method.GetParameters();

            Assert.Equal(expectation.Name, method.Name);
            Assert.Equal(expectation.IsStatic, method.IsStatic);
            Assert.Equal(expectation.ReturnType, method.ReturnType);
            Assert.False(method.IsGenericMethod);
            Assert.Equal(expectation.Parameters.Length, parameters.Length);

            for (var parameterIndex = 0;
                parameterIndex < expectation.Parameters.Length;
                parameterIndex++)
            {
                var parameterExpectation =
                    expectation.Parameters[parameterIndex];
                var parameter = parameters[parameterIndex];

                Assert.Equal(parameterExpectation.Name, parameter.Name);
                Assert.Equal(parameterExpectation.Type, parameter.ParameterType);
                Assert.Equal(parameterExpectation.IsOut, parameter.IsOut);
                Assert.False(parameter.IsOptional);
                Assert.False(parameter.HasDefaultValue);
                Assert.Empty(parameter.GetCustomAttributes<ParamArrayAttribute>());
            }
        }

        foreach (var methodName in new[] { "Equals", "GetHashCode", "ToString" })
        {
            foreach (var method in methods.Where(method =>
                method.Name == methodName &&
                (methodName != "Equals" ||
                    method.GetParameters().Single().ParameterType ==
                    typeof(object))))
            {
                Assert.Equal(typeof(object), method.GetBaseDefinition().DeclaringType);
            }
        }
    }

    private static MethodExpectation ParseMethod(Type type) => new(
        "Parse",
        IsStatic: true,
        type,
        new ParameterExpectation("value", typeof(string)));

    private static MethodExpectation TryParseMethod(Type type) => new(
        "TryParse",
        IsStatic: true,
        typeof(bool),
        new ParameterExpectation("value", typeof(string)),
        new ParameterExpectation(
            "result",
            type.MakeByRefType(),
            IsOut: true));

    private static MethodExpectation ComparableMethod(Type type) => new(
        "CompareTo",
        IsStatic: false,
        typeof(int),
        new ParameterExpectation("other", type));

    private static MethodExpectation TypedEqualsMethod(Type type) => new(
        "Equals",
        IsStatic: false,
        typeof(bool),
        new ParameterExpectation("other", type));

    private static MethodExpectation ObjectEqualsMethod() => new(
        "Equals",
        IsStatic: false,
        typeof(bool),
        new ParameterExpectation("obj", typeof(object)));

    private static MethodExpectation GetHashCodeMethod() => new(
        "GetHashCode",
        IsStatic: false,
        typeof(int));

    private static MethodExpectation ToStringMethod() => new(
        "ToString",
        IsStatic: false,
        typeof(string));

    private static string InterfaceName(Type type) =>
        type.FullName ?? type.Name;

    private static string MethodKey(MethodInfo method) =>
        $"{method.Name}|{method.IsStatic}|" +
        string.Join(",", method.GetParameters().Select(parameter =>
            parameter.ParameterType.ToString()));

    private static string MethodKey(MethodExpectation method) =>
        $"{method.Name}|{method.IsStatic}|" +
        string.Join(",", method.Parameters.Select(parameter =>
            parameter.Type.ToString()));

    private static void AssertParameterNullability(
        NullabilityInfoContext context,
        Type type,
        string methodName,
        string parameterName,
        NullabilityState expected,
        bool useWriteState = false)
    {
        var parameters = type
            .GetMethods(
                BindingFlags.Public |
                BindingFlags.Instance |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly)
            .Where(method => method.Name == methodName)
            .SelectMany(method => method.GetParameters());
        var parameter = Assert.Single(
            parameters,
            candidate => candidate.Name == parameterName);
        var nullability = context.Create(parameter);

        Assert.Equal(
            expected,
            useWriteState ? nullability.WriteState : nullability.ReadState);
    }

    private sealed record PropertyExpectation(
        string Name,
        Type Type,
        bool IsStatic);

    private sealed record MethodExpectation(
        string Name,
        bool IsStatic,
        Type ReturnType,
        params ParameterExpectation[] Parameters);

    private sealed record ParameterExpectation(
        string Name,
        Type Type,
        bool IsOut = false);
}
