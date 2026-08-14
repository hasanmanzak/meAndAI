using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using MeAndAI.Operations.Application.ExecutionAuthority;
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
    [Trait("Subfeature", "SUBF-0145")]
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
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_grant_public_api_matches_the_frozen_contract()
    {
        AssertProperties<AuthorityGrantId>(new PropertySpec("Value", typeof(string)));
        AssertProperties<AuthorityOperationId>(new PropertySpec("Value", typeof(string)));
        AssertProperties<IdempotencyKey>(new PropertySpec("Value", typeof(string)));
        AssertProperties<GrantGeneration>(new PropertySpec("Value", typeof(long)));
        AssertProperties<ExecutionCapability>(
            new("AuthorityTransfer", typeof(ExecutionCapability), true),
            new("ExtensionActivate", typeof(ExecutionCapability), true),
            new("ProviderMutate", typeof(ExecutionCapability), true),
            new("ProviderRead", typeof(ExecutionCapability), true),
            new("ReleasePublish", typeof(ExecutionCapability), true),
            new("ReportPublish", typeof(ExecutionCapability), true),
            new("RepositoryMutate", typeof(ExecutionCapability), true),
            new("RepositoryRead", typeof(ExecutionCapability), true),
            new("Value", typeof(string)));
        AssertClosedProperties<ExecutionGrantRejection>(
        [
            "ActivationRecordDrift", "ActivationRecordUnavailable", "ActorMismatch",
            "ApprovalMismatch", "BindingMismatch", "CapabilityMismatch", "CasConflict",
            "Expired", "GenerationMismatch", "GrantStoreDrift", "LeaseFenceMismatch",
            "None", "NotYetValid", "OperationMismatch", "Replayed", "RoleConflict",
            "SnapshotDrift", "SnapshotUnavailable", "SubjectMismatch", "TargetMismatch"
        ]);
        AssertProperties<ExecutionSubject>(new("Identity", typeof(string)), new("Kind", typeof(string)));
        AssertProperties<ExecutionTarget>(new("GenerationIdentity", typeof(string)), new("Identity", typeof(string)), new("Kind", typeof(string)));
        AssertProperties<LeaseFenceBinding>(new("FencingToken", typeof(string)), new("Generation", typeof(GrantGeneration)), new("OwnerIdentity", typeof(string)));
        AssertProperties<GrantApprovalEvidence>(new("Approver", typeof(AuthorityActorId)), new("EvidenceDigest", typeof(AuthorityDigest)), new("Role", typeof(AuthorityRole)));
        AssertPropertiesCore<ExecutionGrantBinding>([new("Digest", typeof(AuthorityDigest)), new("Kind", typeof(string)), new("RequiredApprovalRoles", typeof(IReadOnlyList<AuthorityRole>))], isAbstract: true);
        AssertProperties<PlanGrantBinding>(new("AllowedEffectIdentity", typeof(string)), new("AllowedProviderObjectIdentities", typeof(IReadOnlyList<string>)), new("AllowedRepositoryPaths", typeof(IReadOnlyList<string>)), new("BaseReference", typeof(string)), new("FinalPlanDigest", typeof(AuthorityDigest)), new("HeadReference", typeof(string)), new("OperationStage", typeof(string)), new("TargetReference", typeof(string)));
        AssertProperties<ReadGrantBinding>(new("AllowedEffectIdentity", typeof(string)), new("AllowedProviderObjectIdentities", typeof(IReadOnlyList<string>)), new("AllowedRepositoryPaths", typeof(IReadOnlyList<string>)), new("BaseReference", typeof(string)), new("EvidencePlanDigest", typeof(AuthorityDigest)), new("HeadReference", typeof(string)));
        AssertProperties<PublicationGrantBinding>(new("AllowedEffectIdentity", typeof(string)), new("GateSnapshotIdentity", typeof(string)), new("IdempotencyKey", typeof(IdempotencyKey)), new("ProviderTarget", typeof(ExecutionTarget)), new("ResultName", typeof(string)), new("SealedReportDigest", typeof(AuthorityDigest)));
        AssertProperties<ExtensionActivationGrantBinding>(new("ActivatingTargetCommit", typeof(string)), new("ActivePolicyDigest", typeof(AuthorityDigest)), new("ActivePolicyIdentity", typeof(string)), new("AllowedEffectIdentity", typeof(string)), new("ClosureReportDigest", typeof(AuthorityDigest)), new("CurrentActivationRecordDigest", typeof(AuthorityDigest)), new("ExpectedCasVersion", typeof(AuthorityRevision)), new("ProposedExtensionSnapshotDigest", typeof(AuthorityDigest)), new("Target", typeof(ExecutionTarget)), new("TransitionEvidenceDigest", typeof(AuthorityDigest)));
        AssertProperties<ExecutionGrant>(new("Approvals", typeof(IReadOnlyList<GrantApprovalEvidence>)), new("AuthoritySet", typeof(AuthoritySetBinding)), new("Binding", typeof(ExecutionGrantBinding)), new("Capability", typeof(ExecutionCapability)), new("Digest", typeof(AuthorityDigest)), new("Executor", typeof(AuthorityActorId)), new("ExpiresAtUtc", typeof(DateTimeOffset)), new("Generation", typeof(GrantGeneration)), new("Id", typeof(AuthorityGrantId)), new("IdempotencyKey", typeof(IdempotencyKey)), new("IssuedAtUtc", typeof(DateTimeOffset)), new("Issuer", typeof(AuthorityActorId)), new("JournalStore", typeof(JournalStoreReference)), new("LeaseFence", typeof(LeaseFenceBinding)), new("NotBeforeUtc", typeof(DateTimeOffset)), new("Operation", typeof(AuthorityOperationId)), new("Subject", typeof(ExecutionSubject)), new("Target", typeof(ExecutionTarget)));
        AssertProperties<GrantValidationRequest>(new("ExecutingActor", typeof(AuthorityActorId)), new("ExpectedBinding", typeof(ExecutionGrantBinding)), new("ExpectedGeneration", typeof(GrantGeneration)), new("ExpectedLeaseFence", typeof(LeaseFenceBinding)), new("ExpectedOperation", typeof(AuthorityOperationId)), new("ExpectedSubject", typeof(ExecutionSubject)), new("ExpectedTarget", typeof(ExecutionTarget)), new("Grant", typeof(ExecutionGrant)), new("ObservedAtUtc", typeof(DateTimeOffset)), new("RequiredCapability", typeof(ExecutionCapability)));
        AssertProperties<GrantConsumptionRequest>(new("ExpectedCurrentAuthoritySet", typeof(AuthoritySetBinding)), new("ExpectedStoreHead", typeof(AuthorityDigest)), new("Validation", typeof(GrantValidationRequest)));
        AssertProperties<ExecutionGrantDecision>(new("IsAuthorized", typeof(bool)), new("Rejection", typeof(ExecutionGrantRejection)));
        AssertProperties<ExecutionGrantAuthorizer>();

        AssertIdentityApi<AuthorityGrantId>(); AssertIdentityApi<AuthorityOperationId>(); AssertIdentityApi<IdempotencyKey>();
        AssertFactory<GrantGeneration>("Create", typeof(GrantGeneration), [typeof(long)], ["value"]);
        AssertFactory<ExecutionCapability>("Parse", typeof(ExecutionCapability), [typeof(string)], ["value"]);
        AssertFactory<ExecutionGrantRejection>("Parse", typeof(ExecutionGrantRejection), [typeof(string)], ["value"]);
        AssertFactory<ExecutionSubject>("Create", typeof(ExecutionSubject), [typeof(string), typeof(string)], ["kind", "identity"]);
        AssertFactory<ExecutionTarget>("Create", typeof(ExecutionTarget), [typeof(string), typeof(string), typeof(string)], ["kind", "identity", "generationIdentity"]);
        AssertFactory<LeaseFenceBinding>("Create", typeof(LeaseFenceBinding), [typeof(GrantGeneration), typeof(string), typeof(string)], ["generation", "ownerIdentity", "fencingToken"]);
        AssertFactory<GrantApprovalEvidence>("Create", typeof(GrantApprovalEvidence), [typeof(AuthorityActorId), typeof(AuthorityRole), typeof(AuthorityDigest)], ["approver", "role", "evidenceDigest"]);
        AssertFactory<PlanGrantBinding>("Create", typeof(PlanGrantBinding), [typeof(AuthorityDigest), typeof(string), typeof(string), typeof(string), typeof(IEnumerable<string>), typeof(IEnumerable<string>), typeof(string), typeof(string), typeof(IEnumerable<AuthorityRole>), typeof(AuthorityDigest)], ["finalPlanDigest", "baseReference", "headReference", "targetReference", "allowedRepositoryPaths", "allowedProviderObjectIdentities", "operationStage", "allowedEffectIdentity", "requiredApprovalRoles", "digest"]);
        AssertFactory<ReadGrantBinding>("Create", typeof(ReadGrantBinding), [typeof(AuthorityDigest), typeof(string), typeof(string), typeof(IEnumerable<string>), typeof(IEnumerable<string>), typeof(string), typeof(IEnumerable<AuthorityRole>), typeof(AuthorityDigest)], ["evidencePlanDigest", "baseReference", "headReference", "allowedRepositoryPaths", "allowedProviderObjectIdentities", "allowedEffectIdentity", "requiredApprovalRoles", "digest"]);
        AssertFactory<PublicationGrantBinding>("Create", typeof(PublicationGrantBinding), [typeof(AuthorityDigest), typeof(ExecutionTarget), typeof(string), typeof(string), typeof(string), typeof(IdempotencyKey), typeof(IEnumerable<AuthorityRole>), typeof(AuthorityDigest)], ["sealedReportDigest", "providerTarget", "gateSnapshotIdentity", "resultName", "allowedEffectIdentity", "idempotencyKey", "requiredApprovalRoles", "digest"]);
        AssertFactory<ExtensionActivationGrantBinding>("Create", typeof(ExtensionActivationGrantBinding), [typeof(AuthorityDigest), typeof(AuthorityDigest), typeof(string), typeof(AuthorityDigest), typeof(string), typeof(AuthorityDigest), typeof(AuthorityDigest), typeof(ExecutionTarget), typeof(AuthorityRevision), typeof(string), typeof(IEnumerable<AuthorityRole>), typeof(AuthorityDigest)], ["currentActivationRecordDigest", "proposedExtensionSnapshotDigest", "activePolicyIdentity", "activePolicyDigest", "activatingTargetCommit", "transitionEvidenceDigest", "closureReportDigest", "target", "expectedCasVersion", "allowedEffectIdentity", "requiredApprovalRoles", "digest"]);
        AssertFactory<ExecutionGrant>("Create", typeof(ExecutionGrant), [typeof(AuthorityGrantId), typeof(AuthoritySetBinding), typeof(ExecutionCapability), typeof(ExecutionSubject), typeof(ExecutionTarget), typeof(AuthorityOperationId), typeof(GrantGeneration), typeof(IdempotencyKey), typeof(AuthorityActorId), typeof(AuthorityActorId), typeof(IEnumerable<GrantApprovalEvidence>), typeof(ExecutionGrantBinding), typeof(JournalStoreReference), typeof(LeaseFenceBinding), typeof(DateTimeOffset), typeof(DateTimeOffset), typeof(DateTimeOffset), typeof(AuthorityDigest)], ["id", "authoritySet", "capability", "subject", "target", "operation", "generation", "idempotencyKey", "issuer", "executor", "approvals", "binding", "journalStore", "leaseFence", "issuedAtUtc", "notBeforeUtc", "expiresAtUtc", "digest"]);
        AssertFactory<GrantValidationRequest>("Create", typeof(GrantValidationRequest), [typeof(ExecutionGrant), typeof(ExecutionCapability), typeof(ExecutionSubject), typeof(ExecutionTarget), typeof(AuthorityOperationId), typeof(GrantGeneration), typeof(LeaseFenceBinding), typeof(ExecutionGrantBinding), typeof(AuthorityActorId), typeof(DateTimeOffset)], ["grant", "requiredCapability", "expectedSubject", "expectedTarget", "expectedOperation", "expectedGeneration", "expectedLeaseFence", "expectedBinding", "executingActor", "observedAtUtc"]);
        AssertFactory<GrantConsumptionRequest>("Create", typeof(GrantConsumptionRequest), [typeof(GrantValidationRequest), typeof(AuthoritySetBinding), typeof(AuthorityDigest)], ["validation", "expectedCurrentAuthoritySet", "expectedStoreHead"]);
        AssertFactory<ExecutionGrantDecision>("Authorized", typeof(ExecutionGrantDecision), [], []);
        AssertFactory<ExecutionGrantDecision>("Rejected", typeof(ExecutionGrantDecision), [typeof(ExecutionGrantRejection)], ["rejection"]);
        AssertFactory<ExecutionGrantAuthorizer>("Create", typeof(ExecutionGrantAuthorizer), [typeof(IExecutionAuthorityReadPort), typeof(IExecutionAuthorityMutationPort)], ["readPort", "mutationPort"]);
        AssertFactory<ExecutionGrantAuthorizer>("AuthorizeAndConsumeAsync", typeof(ValueTask<ExecutionGrantDecision>), [typeof(GrantValidationRequest), typeof(CancellationToken)], ["request", "cancellationToken"], isStatic: false);

        AssertGrantIdentitySurface<AuthorityGrantId>(); AssertGrantIdentitySurface<AuthorityOperationId>(); AssertGrantIdentitySurface<IdempotencyKey>();
        AssertGrantSurface<GrantGeneration>(typeof(object), [typeof(IEquatable<GrantGeneration>)], true, "Create", "Equals", "Equals", "GetHashCode", "ToString");
        AssertGrantSurface<ExecutionCapability>(typeof(object), [typeof(IEquatable<ExecutionCapability>)], true, "Equals", "Equals", "GetHashCode", "Parse", "ToString");
        AssertGrantSurface<ExecutionGrantRejection>(typeof(object), [typeof(IEquatable<ExecutionGrantRejection>)], true, "Equals", "Equals", "GetHashCode", "Parse", "ToString");
        AssertGrantValueSurface<ExecutionSubject>(); AssertGrantValueSurface<ExecutionTarget>();
        AssertGrantValueSurface<LeaseFenceBinding>(); AssertGrantValueSurface<GrantApprovalEvidence>();
        AssertGrantSurface<ExecutionGrantBinding>(typeof(object), [typeof(IEquatable<ExecutionGrantBinding>)], false, "Equals", "Equals", "GetHashCode");
        AssertGrantBindingSurface<PlanGrantBinding>(); AssertGrantBindingSurface<ReadGrantBinding>();
        AssertGrantBindingSurface<PublicationGrantBinding>(); AssertGrantBindingSurface<ExtensionActivationGrantBinding>();
        AssertGrantValueSurface<ExecutionGrant>(); AssertGrantValueSurface<GrantValidationRequest>(); AssertGrantValueSurface<GrantConsumptionRequest>();
        AssertGrantSurface<ExecutionGrantDecision>(typeof(object), [typeof(IEquatable<ExecutionGrantDecision>)], false, "Authorized", "Equals", "Equals", "GetHashCode", "Rejected");
        AssertGrantSurface<ExecutionGrantAuthorizer>(typeof(object), [], false, "AuthorizeAndConsumeAsync", "Create");
    }
    private static void AssertProperties<T>(params PropertySpec[] properties) =>
        AssertPropertiesCore<T>(properties, isAbstract: false);
    private static void AssertClosedProperties<T>(string[] names) =>
        AssertProperties<T>([.. names.Select(static name =>
            new PropertySpec(name, typeof(T), true)), new("Value", typeof(string))]);
    private static void AssertPropertiesCore<T>(PropertySpec[] properties, bool isAbstract)
    {
        Type type = typeof(T);
        Assert.Equal(isAbstract, type.IsAbstract);
        Assert.Equal(!isAbstract, type.IsSealed);
        Assert.Empty(type.GetConstructors(BindingFlags.Public | BindingFlags.Instance));
        PropertyInfo[] actual = [.. type.GetProperties(DeclaredPublic).OrderBy(static value => value.Name, StringComparer.Ordinal)];
        PropertySpec[] expected = [.. properties.OrderBy(static value => value.Name, StringComparer.Ordinal)];
        Assert.Equal(expected.Length, actual.Length);
        for (int index = 0; index < expected.Length; index++)
        {
            Assert.Equal(expected[index].Name, actual[index].Name);
            Assert.Equal(expected[index].Type, actual[index].PropertyType);
            Assert.Equal(expected[index].IsStatic, actual[index].GetMethod!.IsStatic);
            Assert.Null(actual[index].GetSetMethod(nonPublic: true));
            if (!actual[index].PropertyType.IsValueType)
                Assert.Equal(NullabilityState.NotNull,
                    new NullabilityInfoContext().Create(actual[index]).ReadState);
        }
    }
    private static void AssertFactory<T>(string name, Type returnType,
        Type[] parameterTypes, string[] parameterNames, bool isStatic = true)
    {
        MethodInfo method = Assert.Single(typeof(T).GetMethods(DeclaredPublic), value =>
            value.Name == name && value.GetParameters().Select(static item => item.ParameterType).SequenceEqual(parameterTypes));
        Assert.Equal(isStatic, method.IsStatic);
        Assert.Equal(returnType, method.ReturnType);
        Assert.Equal(parameterNames, method.GetParameters().Select(static value => value.Name));
        NullabilityInfoContext nullability = new();
        if (!returnType.IsValueType)
            Assert.Equal(NullabilityState.NotNull, nullability.Create(method.ReturnParameter).ReadState);
        foreach (ParameterInfo parameter in method.GetParameters().Where(static value =>
            !value.ParameterType.IsValueType))
            Assert.Equal(NullabilityState.NotNull, nullability.Create(parameter).ReadState);
    }
    private static void AssertGrantIdentitySurface<T>() => AssertGrantSurface<T>(typeof(object),
        [typeof(IComparable<T>), typeof(IEquatable<T>)], false,
        "CompareTo", "Equals", "Equals", "GetHashCode", "Parse", "ToString", "TryParse");
    private static void AssertGrantValueSurface<T>() => AssertGrantSurface<T>(typeof(object),
        [typeof(IEquatable<T>)], false, "Create", "Equals", "Equals", "GetHashCode");
    private static void AssertGrantBindingSurface<T>() => AssertGrantSurface<T>(typeof(ExecutionGrantBinding),
        [typeof(IEquatable<ExecutionGrantBinding>), typeof(IEquatable<T>)], false, "Create", "Equals");
    private static void AssertGrantSurface<T>(Type baseType, Type[] interfaces,
        bool isRecord, params string[] expectedMethods)
    {
        Type type = typeof(T);
        Assert.True(type.IsClass, type.FullName);
        Assert.Equal(type == typeof(ExecutionGrantBinding), type.IsAbstract);
        Assert.Equal(type != typeof(ExecutionGrantBinding), type.IsSealed);
        Assert.Equal(baseType, type.BaseType);
        Assert.Equal(type == typeof(ExecutionGrantAuthorizer)
            ? "MeAndAI.Operations.Application.ExecutionAuthority"
            : "MeAndAI.Operations.Domain.ExecutionAuthority", type.Namespace);
        Assert.Equal(interfaces.OrderBy(static value => value.FullName, StringComparer.Ordinal),
            type.GetInterfaces().OrderBy(static value => value.FullName, StringComparer.Ordinal));
        Assert.Empty(type.GetConstructors(BindingFlags.Public | BindingFlags.Instance));
        Assert.Empty(type.GetFields(DeclaredPublic)); Assert.Empty(type.GetEvents(DeclaredPublic));
        Assert.Empty(type.GetNestedTypes(BindingFlags.Public));
        MethodInfo[] methods = type.GetMethods(DeclaredPublic);
        Assert.Equal(expectedMethods.Order(StringComparer.Ordinal), methods.Where(static method =>
            !method.IsSpecialName && method.Name != "<Clone>$").Select(static method => method.Name).Order(StringComparer.Ordinal));
        Assert.Equal(isRecord ? ["op_Equality", "op_Inequality"] : [], methods.Where(static method =>
            method.IsSpecialName && !method.Name.StartsWith("get_", StringComparison.Ordinal)).Select(static method => method.Name).Order(StringComparer.Ordinal));
        Assert.Equal(isRecord, methods.Any(static method => method.Name == "<Clone>$"));
        foreach (MethodInfo equals in methods.Where(static method => method.Name == "Equals" && method.GetParameters().Length == 1))
            Assert.Equal(NullabilityState.Nullable,
                new NullabilityInfoContext().Create(equals.GetParameters()[0]).ReadState);
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
