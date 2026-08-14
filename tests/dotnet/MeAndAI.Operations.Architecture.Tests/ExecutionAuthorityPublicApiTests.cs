using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ExecutionAuthorityPublicApiTests
{
    private const BindingFlags DeclaredPublic = BindingFlags.Public |
        BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly;
    private static readonly Type[] SnapshotTypes =
    [
        typeof(ApprovalAuthoritySetSnapshot),
        typeof(AuthorityApprovalPolicy),
        typeof(AuthorityActorId),
        typeof(AuthorityDigest),
        typeof(AuthorityRevision),
        typeof(AuthorityRole),
        typeof(AuthoritySetBinding),
        typeof(AuthoritySetId),
        typeof(AuthoritySetMember),
        typeof(JournalStoreReference),
        typeof(RoleSeparationRequirement),
        typeof(SoloMaintainerException)
    ];
    private static readonly Dictionary<Type, PropertySpec[]> Properties = new()
    {
        [typeof(AuthorityActorId)] = [new("Value", typeof(string))],
        [typeof(AuthoritySetId)] = [new("Value", typeof(string))],
        [typeof(JournalStoreReference)] = [new("Value", typeof(string))],
        [typeof(AuthorityDigest)] = [new("Value", typeof(string))],
        [typeof(AuthorityRevision)] = [new("Value", typeof(long))],
        [typeof(AuthorityRole)] = [new("EnvelopeReviewer", typeof(AuthorityRole), true), new("Executor", typeof(AuthorityRole), true), new("FinalPlanReviewer", typeof(AuthorityRole), true), new("GrantIssuer", typeof(AuthorityRole), true), new("ProposalActor", typeof(AuthorityRole), true), new("Value", typeof(string))],
        [typeof(AuthoritySetMember)] = [new("Actor", typeof(AuthorityActorId)), new("Roles", typeof(IReadOnlyList<AuthorityRole>))],
        [typeof(RoleSeparationRequirement)] = [new("First", typeof(AuthorityRole)), new("Second", typeof(AuthorityRole))],
        [typeof(SoloMaintainerException)] = [new("Actor", typeof(AuthorityActorId)), new("AllowedRoles", typeof(IReadOnlyList<AuthorityRole>)), new("IndependentEvidenceDigest", typeof(AuthorityDigest))],
        [typeof(AuthorityApprovalPolicy)] = [new("GrantKind", typeof(string)), new("RequiredApprovalRoles", typeof(IReadOnlyList<AuthorityRole>))],
        [typeof(ApprovalAuthoritySetSnapshot)] =
        [
            new("ApprovalPolicies", typeof(IReadOnlyList<AuthorityApprovalPolicy>)), new("Digest", typeof(AuthorityDigest)), new("Id", typeof(AuthoritySetId)), new("JournalStores", typeof(IReadOnlyList<JournalStoreReference>)), new("Members", typeof(IReadOnlyList<AuthoritySetMember>)),
            new("Revision", typeof(AuthorityRevision)), new("RevocationEpoch", typeof(AuthorityRevision)), new("SchemaVersion", typeof(string)), new("SeparationRequirements", typeof(IReadOnlyList<RoleSeparationRequirement>)),
            new("SoloMaintainerExceptions", typeof(IReadOnlyList<SoloMaintainerException>))
        ],
        [typeof(AuthoritySetBinding)] = [new("Digest", typeof(AuthorityDigest)), new("Id", typeof(AuthoritySetId)), new("Revision", typeof(AuthorityRevision)), new("RevocationEpoch", typeof(AuthorityRevision))]
    };
    private static readonly Dictionary<string, string[]> FactoryParameterNames = new()
    {
        ["AuthorityDigest.FromHashBytes"] = ["hashBytes"],
        ["AuthorityRevision.Create"] = ["value"],
        ["AuthoritySetMember.Create"] = ["actor", "roles"],
        ["RoleSeparationRequirement.Create"] = ["first", "second"],
        ["SoloMaintainerException.Create"] = ["actor", "allowedRoles", "independentEvidenceDigest"],
        ["AuthorityApprovalPolicy.Create"] = ["grantKind", "requiredApprovalRoles"],
        ["ApprovalAuthoritySetSnapshot.Create"] = ["id", "schemaVersion", "revision", "revocationEpoch", "digest", "members", "separationRequirements", "soloMaintainerExceptions", "approvalPolicies", "journalStores"],
        ["AuthoritySetBinding.From"] = ["snapshot"]
    };
    [Fact]
    [Trait("Scenario", "TEST-0212")]
    public void TEST_0212_snapshot_public_api_matches_the_frozen_contract()
    {
        Assert.All(SnapshotTypes, AssertExactTypeSurface);
        AssertIdentityApi<AuthorityActorId>();
        AssertIdentityApi<AuthoritySetId>();
        AssertIdentityApi<JournalStoreReference>();
        AssertIdentityApi<AuthorityDigest>();
        AssertMethod<AuthorityDigest>("FromHashBytes", true, typeof(AuthorityDigest), typeof(ReadOnlySpan<byte>));
        AssertMethod<AuthorityRevision>("Create", true, typeof(AuthorityRevision), typeof(long));
        AssertMethod<AuthorityRole>("Parse", true, typeof(AuthorityRole), typeof(string));
        AssertMethod<AuthoritySetMember>("Create", true, typeof(AuthoritySetMember), typeof(AuthorityActorId), typeof(IEnumerable<AuthorityRole>));
        AssertMethod<RoleSeparationRequirement>("Create", true, typeof(RoleSeparationRequirement), typeof(AuthorityRole), typeof(AuthorityRole));
        AssertMethod<SoloMaintainerException>("Create", true, typeof(SoloMaintainerException), typeof(AuthorityActorId), typeof(IEnumerable<AuthorityRole>), typeof(AuthorityDigest));
        AssertMethod<AuthorityApprovalPolicy>("Create", true, typeof(AuthorityApprovalPolicy), typeof(string), typeof(IEnumerable<AuthorityRole>));
        AssertMethod<ApprovalAuthoritySetSnapshot>("Create", true, typeof(ApprovalAuthoritySetSnapshot), typeof(AuthoritySetId), typeof(string), typeof(AuthorityRevision), typeof(AuthorityRevision), typeof(AuthorityDigest), typeof(IEnumerable<AuthoritySetMember>), typeof(IEnumerable<RoleSeparationRequirement>), typeof(IEnumerable<SoloMaintainerException>), typeof(IEnumerable<AuthorityApprovalPolicy>), typeof(IEnumerable<JournalStoreReference>));
        AssertMethod<AuthoritySetBinding>("From", true, typeof(AuthoritySetBinding), typeof(ApprovalAuthoritySetSnapshot));
        Assert.Equal(
            ["envelope-reviewer", "executor", "final-plan-reviewer", "grant-issuer", "proposal-actor"],
            typeof(AuthorityRole)
                .GetProperties(BindingFlags.Public | BindingFlags.Static)
                .Where(static property => property.PropertyType == typeof(AuthorityRole))
                .Select(static property => ((AuthorityRole)property.GetValue(null)!).Value)
                .Order(StringComparer.Ordinal));
    }
    private static void AssertExactTypeSurface(Type type)
    {
        Assert.True(type.IsClass, type.FullName);
        Assert.True(type.IsSealed, type.FullName);
        Assert.False(type.IsAbstract, type.FullName);
        Assert.Equal(typeof(object), type.BaseType);
        Assert.Equal("MeAndAI.Operations.Domain.ExecutionAuthority", type.Namespace);
        Assert.Empty(type.GetConstructors(BindingFlags.Public | BindingFlags.Instance));
        Assert.Empty(type.GetFields(DeclaredPublic));
        Assert.Empty(type.GetEvents(DeclaredPublic));
        Assert.Empty(type.GetNestedTypes(BindingFlags.Public));
        PropertyInfo[] actualProperties =
        [
            .. type.GetProperties(DeclaredPublic)
                .OrderBy(static property => property.Name, StringComparer.Ordinal)
        ];
        PropertySpec[] expectedProperties =
        [
            .. Properties[type]
                .OrderBy(static property => property.Name, StringComparer.Ordinal)
        ];
        Assert.Equal(expectedProperties.Length, actualProperties.Length);
        for (int index = 0; index < expectedProperties.Length; index++)
        {
            PropertySpec expected = expectedProperties[index];
            PropertyInfo actual = actualProperties[index];
            Assert.Equal(expected.Name, actual.Name);
            Assert.Equal(expected.Type, actual.PropertyType);
            Assert.Equal(expected.IsStatic, actual.GetMethod!.IsStatic);
            Assert.Null(actual.SetMethod);
            if (!actual.PropertyType.IsValueType)
            {
                Assert.Equal(NullabilityState.NotNull,
                    new NullabilityInfoContext().Create(actual).ReadState);
            }
        }
        bool isRecord = type == typeof(AuthorityRevision) ||
            type == typeof(AuthorityRole);
        bool isComparable = type == typeof(AuthorityActorId) ||
            type == typeof(AuthoritySetId) ||
            type == typeof(JournalStoreReference) ||
            type == typeof(AuthorityDigest);
        Type[] expectedInterfaces = isComparable
            ? [typeof(IComparable<>).MakeGenericType(type),
                typeof(IEquatable<>).MakeGenericType(type)]
            : [typeof(IEquatable<>).MakeGenericType(type)];
        Assert.Equal(expectedInterfaces.OrderBy(static value => value.Name),
            type.GetInterfaces().OrderBy(static value => value.Name));
        AssertMethod(type, "Equals", false, typeof(bool), type);
        AssertMethod(type, "Equals", false, typeof(bool), typeof(object));
        AssertMethod(type, "GetHashCode", false, typeof(int));
        if (isComparable)
        {
            AssertMethod(type, "CompareTo", false, typeof(int), type);
        }
        if (isComparable || isRecord)
        {
            AssertMethod(type, "ToString", false, typeof(string));
        }
        MethodInfo[] methods = type.GetMethods(DeclaredPublic);
        string[] special =
        [
            .. methods.Where(static method => method.IsSpecialName &&
                    !method.Name.StartsWith("get_", StringComparison.Ordinal))
                .Select(static method => method.Name).Order(StringComparer.Ordinal)
        ];
        Assert.Equal(isRecord ? ["op_Equality", "op_Inequality"] : [], special);
        Assert.Equal(isRecord, methods.Any(static method => method.Name == "<Clone>$"));
        string[] expectedOperations = type == typeof(AuthorityDigest)
            ? ["FromHashBytes", "Parse", "TryParse"]
            : type == typeof(AuthorityActorId) || type == typeof(AuthoritySetId) ||
                type == typeof(JournalStoreReference)
                ? ["Parse", "TryParse"]
                : type == typeof(AuthoritySetBinding) ? ["From"]
                : [type == typeof(AuthorityRole) ? "Parse" : "Create"];
        List<string> expectedNames =
            [.. expectedOperations, "Equals", "Equals", "GetHashCode"];
        if (isComparable)
        {
            expectedNames.Add("CompareTo");
        }
        if (isComparable || isRecord)
        {
            expectedNames.Add("ToString");
        }
        Assert.Equal(expectedNames.Order(StringComparer.Ordinal), methods
            .Where(static method => !method.IsSpecialName &&
                method.Name != "<Clone>$")
            .Select(static method => method.Name).Order(StringComparer.Ordinal));
    }
    private static void AssertIdentityApi<T>()
    {
        MethodInfo parse = AssertMethod<T>("Parse", true, typeof(T), typeof(string));
        Assert.Equal(NullabilityState.NotNull,
            new NullabilityInfoContext().Create(parse.GetParameters()[0]).ReadState);
        MethodInfo tryParse = AssertMethod<T>("TryParse", true, typeof(bool),
            typeof(string), typeof(T).MakeByRefType());
        ParameterInfo[] parameters = tryParse.GetParameters();
        Assert.Equal(NullabilityState.Nullable,
            new NullabilityInfoContext().Create(parameters[0]).ReadState);
        Assert.True(Assert.Single(
            parameters[1].GetCustomAttributes<NotNullWhenAttribute>()).ReturnValue);
    }
    private static MethodInfo AssertMethod<T>(
        string name, bool isStatic, Type returnType, params Type[] parameterTypes) =>
        AssertMethod(typeof(T), name, isStatic, returnType, parameterTypes);
    private static MethodInfo AssertMethod(
        Type type, string name, bool isStatic, Type returnType,
        params Type[] parameterTypes)
    {
        MethodInfo method = Assert.Single(type.GetMethods(DeclaredPublic), candidate =>
            candidate.Name == name && candidate.GetParameters()
                .Select(static parameter => parameter.ParameterType)
                .SequenceEqual(parameterTypes));
        Assert.Equal(isStatic, method.IsStatic);
        Assert.Equal(returnType, method.ReturnType);
        string[] expectedNames = name switch
        {
            "Parse" => ["value"],
            "TryParse" => ["value", "result"],
            "Equals" => [parameterTypes[0] == typeof(object) ? "obj" : "other"],
            "CompareTo" => ["other"],
            "GetHashCode" or "ToString" => [],
            _ => FactoryParameterNames[$"{type.Name}.{name}"]
        };
        ParameterInfo[] parameters = method.GetParameters();
        Assert.Equal(expectedNames, parameters.Select(static value => value.Name));
        if (!returnType.IsValueType)
        {
            Assert.Equal(NullabilityState.NotNull,
                new NullabilityInfoContext().Create(method.ReturnParameter).ReadState);
        }
        foreach (ParameterInfo parameter in parameters)
        {
            Type valueType = parameter.ParameterType.IsByRef
                ? parameter.ParameterType.GetElementType()! : parameter.ParameterType;
            if (!valueType.IsValueType)
            {
                bool nullable = name is "TryParse" or "Equals" or "CompareTo";
                NullabilityInfo info = new NullabilityInfoContext().Create(parameter);
                Assert.Equal(nullable ? NullabilityState.Nullable : NullabilityState.NotNull,
                    parameter.IsOut ? info.WriteState : info.ReadState);
            }
        }
        return method;
    }
    private sealed record PropertySpec(string Name, Type Type, bool IsStatic = false);
}
