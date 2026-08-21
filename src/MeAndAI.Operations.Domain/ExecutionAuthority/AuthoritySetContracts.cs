namespace MeAndAI.Operations.Domain.ExecutionAuthority;

public sealed record AuthorityRole
{
    private static readonly Dictionary<string, AuthorityRole> Values =
        new(StringComparer.Ordinal)
        {
            ["proposal-actor"] = new("proposal-actor"),
            ["envelope-reviewer"] = new("envelope-reviewer"),
            ["final-plan-reviewer"] = new("final-plan-reviewer"),
            ["grant-issuer"] = new("grant-issuer"),
            ["executor"] = new("executor")
        };
    private AuthorityRole(string value) => Value = value;
    public static AuthorityRole ProposalActor => Values["proposal-actor"];
    public static AuthorityRole EnvelopeReviewer => Values["envelope-reviewer"];
    public static AuthorityRole FinalPlanReviewer => Values["final-plan-reviewer"];
    public static AuthorityRole GrantIssuer => Values["grant-issuer"];
    public static AuthorityRole Executor => Values["executor"];
    public string Value { get; }
    public static AuthorityRole Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return Values.TryGetValue(value, out AuthorityRole? role)
            ? role
            : throw new FormatException("The authority role is not recognized.");
    }
    public override string ToString() => Value;
}

public sealed class AuthoritySetMember : IEquatable<AuthoritySetMember>
{
    private AuthoritySetMember(
        AuthorityActorId actor, IReadOnlyList<AuthorityRole> roles) =>
        (Actor, Roles) = (actor, roles);
    public AuthorityActorId Actor { get; }
    public IReadOnlyList<AuthorityRole> Roles { get; }
    public static AuthoritySetMember Create(
        AuthorityActorId actor, IEnumerable<AuthorityRole> roles)
    {
        ArgumentNullException.ThrowIfNull(actor);
        return new(actor, AuthoritySetRules.SortRoles(roles, nameof(roles)));
    }
    public bool Equals(AuthoritySetMember? other) =>
        other is not null && Actor.Equals(other.Actor) &&
        Roles.SequenceEqual(other.Roles);
    public override bool Equals(object? obj) => Equals(obj as AuthoritySetMember);
    public override int GetHashCode() =>
        HashCode.Combine(Actor, AuthoritySetRules.Hash(Roles));
}

public sealed class RoleSeparationRequirement :
    IEquatable<RoleSeparationRequirement>
{
    private RoleSeparationRequirement(AuthorityRole first, AuthorityRole second) =>
        (First, Second) = (first, second);
    public AuthorityRole First { get; }
    public AuthorityRole Second { get; }
    public static RoleSeparationRequirement Create(
        AuthorityRole first, AuthorityRole second)
    {
        ArgumentNullException.ThrowIfNull(first);
        ArgumentNullException.ThrowIfNull(second);
        if (first == second)
        {
            throw new ArgumentException(
                "Separated roles must be distinct.", nameof(second));
        }
        return StringComparer.Ordinal.Compare(first.Value, second.Value) < 0
            ? new(first, second)
            : new(second, first);
    }
    public bool Equals(RoleSeparationRequirement? other) =>
        other is not null && First == other.First && Second == other.Second;
    public override bool Equals(object? obj) =>
        Equals(obj as RoleSeparationRequirement);
    public override int GetHashCode() => HashCode.Combine(First, Second);
}

public sealed class SoloMaintainerException :
    IEquatable<SoloMaintainerException>
{
    private SoloMaintainerException(
        AuthorityActorId actor,
        IReadOnlyList<AuthorityRole> roles,
        AuthorityDigest evidence) =>
        (Actor, AllowedRoles, IndependentEvidenceDigest) =
            (actor, roles, evidence);
    public AuthorityActorId Actor { get; }
    public IReadOnlyList<AuthorityRole> AllowedRoles { get; }
    public AuthorityDigest IndependentEvidenceDigest { get; }
    public static SoloMaintainerException Create(
        AuthorityActorId actor,
        IEnumerable<AuthorityRole> allowedRoles,
        AuthorityDigest independentEvidenceDigest)
    {
        ArgumentNullException.ThrowIfNull(actor);
        IReadOnlyList<AuthorityRole> roles =
            AuthoritySetRules.SortRoles(allowedRoles, nameof(allowedRoles));
        ArgumentNullException.ThrowIfNull(independentEvidenceDigest);
        if (roles.Count != 2)
        {
            throw new ArgumentException(
                "A solo exception covers exactly two roles.",
                nameof(allowedRoles));
        }
        return new(actor, roles, independentEvidenceDigest);
    }
    public bool Equals(SoloMaintainerException? other) =>
        other is not null && Actor.Equals(other.Actor) &&
        AllowedRoles.SequenceEqual(other.AllowedRoles) &&
        IndependentEvidenceDigest.Equals(other.IndependentEvidenceDigest);
    public override bool Equals(object? obj) =>
        Equals(obj as SoloMaintainerException);
    public override int GetHashCode() =>
        HashCode.Combine(Actor, AllowedRoles[0], AllowedRoles[1],
            IndependentEvidenceDigest);
}

public sealed class AuthorityApprovalPolicy :
    IEquatable<AuthorityApprovalPolicy>
{
    private static readonly Dictionary<string, AuthorityRole[]> Floors =
        new(StringComparer.Ordinal)
        {
            ["evidence.read"] = [AuthorityRole.EnvelopeReviewer],
            ["plan.sealed"] =
                [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer],
            ["report.sealed"] =
                [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer],
            ["extension.transition"] =
                [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer]
        };
    private AuthorityApprovalPolicy(
        string kind, IReadOnlyList<AuthorityRole> roles) =>
        (GrantKind, RequiredApprovalRoles) = (kind, roles);
    public string GrantKind { get; }
    public IReadOnlyList<AuthorityRole> RequiredApprovalRoles { get; }
    public static AuthorityApprovalPolicy Create(
        string grantKind, IEnumerable<AuthorityRole> requiredApprovalRoles)
    {
        string kind = ExecutionAuthorityValidation.Token(
            grantKind, nameof(grantKind));
        if (!Floors.TryGetValue(kind, out AuthorityRole[]? floor))
        {
            throw new ArgumentException(
                "The approval-policy kind is not recognized.", nameof(grantKind));
        }
        IReadOnlyList<AuthorityRole> roles = AuthoritySetRules.SortRoles(
            requiredApprovalRoles, nameof(requiredApprovalRoles));
        if (floor.Any(role => !roles.Contains(role)))
        {
            throw new ArgumentException(
                "The policy removes a mandatory approval role.",
                nameof(requiredApprovalRoles));
        }
        return new(kind, roles);
    }
    public bool Equals(AuthorityApprovalPolicy? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(GrantKind, other.GrantKind) &&
        RequiredApprovalRoles.SequenceEqual(other.RequiredApprovalRoles);
    public override bool Equals(object? obj) =>
        Equals(obj as AuthorityApprovalPolicy);
    public override int GetHashCode() =>
        HashCode.Combine(StringComparer.Ordinal.GetHashCode(GrantKind),
            AuthoritySetRules.Hash(RequiredApprovalRoles));
}

public sealed class ApprovalAuthoritySetSnapshot :
    IEquatable<ApprovalAuthoritySetSnapshot>
{
    private ApprovalAuthoritySetSnapshot(
        AuthoritySetId id, string schemaVersion, AuthorityRevision revision,
        AuthorityRevision revocationEpoch, AuthorityDigest digest,
        IReadOnlyList<AuthoritySetMember> members,
        IReadOnlyList<RoleSeparationRequirement> separations,
        IReadOnlyList<SoloMaintainerException> exceptions,
        IReadOnlyList<AuthorityApprovalPolicy> policies,
        IReadOnlyList<JournalStoreReference> stores) =>
        (Id, SchemaVersion, Revision, RevocationEpoch, Digest, Members,
            SeparationRequirements, SoloMaintainerExceptions, ApprovalPolicies,
            JournalStores) =
        (id, schemaVersion, revision, revocationEpoch, digest, members,
            separations, exceptions, policies, stores);
    public AuthoritySetId Id { get; }
    public string SchemaVersion { get; }
    public AuthorityRevision Revision { get; }
    public AuthorityRevision RevocationEpoch { get; }
    public AuthorityDigest Digest { get; }
    public IReadOnlyList<AuthoritySetMember> Members { get; }
    public IReadOnlyList<RoleSeparationRequirement> SeparationRequirements { get; }
    public IReadOnlyList<SoloMaintainerException> SoloMaintainerExceptions { get; }
    public IReadOnlyList<AuthorityApprovalPolicy> ApprovalPolicies { get; }
    public IReadOnlyList<JournalStoreReference> JournalStores { get; }
    public static ApprovalAuthoritySetSnapshot Create(
        AuthoritySetId id, string schemaVersion, AuthorityRevision revision,
        AuthorityRevision revocationEpoch, AuthorityDigest digest,
        IEnumerable<AuthoritySetMember> members,
        IEnumerable<RoleSeparationRequirement> separationRequirements,
        IEnumerable<SoloMaintainerException> soloMaintainerExceptions,
        IEnumerable<AuthorityApprovalPolicy> approvalPolicies,
        IEnumerable<JournalStoreReference> journalStores)
    {
        ArgumentNullException.ThrowIfNull(id);
        AuthoritySetRules.ValidateVersion(schemaVersion);
        ArgumentNullException.ThrowIfNull(revision);
        ArgumentNullException.ThrowIfNull(revocationEpoch);
        ArgumentNullException.ThrowIfNull(digest);
        IReadOnlyList<AuthoritySetMember> memberList =
            AuthoritySetRules.SortMembers(members);
        IReadOnlyList<RoleSeparationRequirement> separationList =
            AuthoritySetRules.SortSeparations(separationRequirements);
        IReadOnlyList<SoloMaintainerException> exceptionList =
            AuthoritySetRules.SortExceptions(soloMaintainerExceptions);
        IReadOnlyList<AuthorityApprovalPolicy> policyList =
            AuthoritySetRules.SortPolicies(approvalPolicies);
        IReadOnlyList<JournalStoreReference> storeList =
            ExecutionAuthorityValidation.SortedUnique(
                journalStores, nameof(journalStores),
                static (left, right) => left.CompareTo(right));
        AuthoritySetRules.Validate(
            memberList, separationList, exceptionList, policyList);
        return new(id, schemaVersion, revision, revocationEpoch, digest,
            memberList, separationList, exceptionList, policyList, storeList);
    }
    public bool Equals(ApprovalAuthoritySetSnapshot? other) =>
        other is not null && Id.Equals(other.Id) &&
        StringComparer.Ordinal.Equals(SchemaVersion, other.SchemaVersion) &&
        Revision == other.Revision && RevocationEpoch == other.RevocationEpoch &&
        Digest.Equals(other.Digest) && Members.SequenceEqual(other.Members) &&
        SeparationRequirements.SequenceEqual(other.SeparationRequirements) &&
        SoloMaintainerExceptions.SequenceEqual(other.SoloMaintainerExceptions) &&
        ApprovalPolicies.SequenceEqual(other.ApprovalPolicies) &&
        JournalStores.SequenceEqual(other.JournalStores);
    public override bool Equals(object? obj) =>
        Equals(obj as ApprovalAuthoritySetSnapshot);
    public override int GetHashCode() => HashCode.Combine(
        Id, SchemaVersion, Revision, RevocationEpoch, Digest,
        AuthoritySetRules.Hash(Members),
        AuthoritySetRules.Hash(SeparationRequirements),
        HashCode.Combine(AuthoritySetRules.Hash(SoloMaintainerExceptions),
            AuthoritySetRules.Hash(ApprovalPolicies),
            AuthoritySetRules.Hash(JournalStores)));
}

public sealed class AuthoritySetBinding : IEquatable<AuthoritySetBinding>
{
    private AuthoritySetBinding(
        AuthoritySetId id, AuthorityRevision revision,
        AuthorityRevision revocationEpoch, AuthorityDigest digest) =>
        (Id, Revision, RevocationEpoch, Digest) =
            (id, revision, revocationEpoch, digest);
    public AuthoritySetId Id { get; }
    public AuthorityRevision Revision { get; }
    public AuthorityRevision RevocationEpoch { get; }
    public AuthorityDigest Digest { get; }
    public static AuthoritySetBinding From(ApprovalAuthoritySetSnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(snapshot);
        return new(snapshot.Id, snapshot.Revision,
            snapshot.RevocationEpoch, snapshot.Digest);
    }
    public bool Equals(AuthoritySetBinding? other) =>
        other is not null && Id.Equals(other.Id) &&
        Revision == other.Revision && RevocationEpoch == other.RevocationEpoch &&
        Digest.Equals(other.Digest);
    public override bool Equals(object? obj) => Equals(obj as AuthoritySetBinding);
    public override int GetHashCode() =>
        HashCode.Combine(Id, Revision, RevocationEpoch, Digest);
}

internal static class AuthoritySetRules
{
    private static readonly AuthorityRole[] Roles =
    [
        AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer,
        AuthorityRole.FinalPlanReviewer, AuthorityRole.GrantIssuer,
        AuthorityRole.Executor
    ];
    internal static IReadOnlyList<AuthorityRole> SortRoles(
        IEnumerable<AuthorityRole> values, string parameterName) =>
        ExecutionAuthorityValidation.SortedUnique(
            values, parameterName,
            static (left, right) =>
                StringComparer.Ordinal.Compare(left.Value, right.Value));
    internal static IReadOnlyList<AuthoritySetMember> SortMembers(
        IEnumerable<AuthoritySetMember> members) =>
        ExecutionAuthorityValidation.SortedUnique(
            members, nameof(members),
            static (left, right) => left.Actor.CompareTo(right.Actor));
    internal static IReadOnlyList<RoleSeparationRequirement> SortSeparations(
        IEnumerable<RoleSeparationRequirement> separationRequirements) =>
        ExecutionAuthorityValidation.SortedUnique(
            separationRequirements, nameof(separationRequirements),
            static (left, right) =>
                StringComparer.Ordinal.Compare(Pair(left), Pair(right)));
    internal static IReadOnlyList<SoloMaintainerException> SortExceptions(
        IEnumerable<SoloMaintainerException> soloMaintainerExceptions)
    {
        IReadOnlyList<SoloMaintainerException> result =
            ExecutionAuthorityValidation.SortedUnique(
                soloMaintainerExceptions, nameof(soloMaintainerExceptions),
                static (left, right) =>
                    StringComparer.Ordinal.Compare(ExceptionKey(left),
                        ExceptionKey(right)),
                allowEmpty: true);
        if (result.GroupBy(static value => ExceptionPair(value),
                StringComparer.Ordinal).Any(static group => group.Count() > 1))
        {
            throw new ArgumentException(
                "A solo actor/role pair occurs more than once.",
                nameof(soloMaintainerExceptions));
        }
        return result;
    }
    internal static IReadOnlyList<AuthorityApprovalPolicy> SortPolicies(
        IEnumerable<AuthorityApprovalPolicy> approvalPolicies) =>
        ExecutionAuthorityValidation.SortedUnique(
            approvalPolicies, nameof(approvalPolicies),
            static (left, right) =>
                StringComparer.Ordinal.Compare(left.GrantKind, right.GrantKind));
    internal static void ValidateVersion(string schemaVersion)
    {
        ArgumentNullException.ThrowIfNull(schemaVersion);
        if (schemaVersion.Length is < 1 or > 9 ||
            schemaVersion[0] is < '1' or > '9' ||
            schemaVersion.Any(static character => character is < '0' or > '9'))
        {
            throw new ArgumentException(
                "The schema version is not canonical.", nameof(schemaVersion));
        }
    }
    internal static void Validate(
        IReadOnlyList<AuthoritySetMember> members,
        IReadOnlyList<RoleSeparationRequirement> separationRequirements,
        IReadOnlyList<SoloMaintainerException> soloMaintainerExceptions,
        IReadOnlyList<AuthorityApprovalPolicy> approvalPolicies)
    {
        if (Roles.Any(role => members.All(member => !member.Roles.Contains(role))))
        {
            throw new ArgumentException(
                "Every role requires a member.", nameof(members));
        }
        IEnumerable<string> expectedPairs =
            (from left in Roles
             from right in Roles
             where StringComparer.Ordinal.Compare(left.Value, right.Value) < 0
             select Pair(RoleSeparationRequirement.Create(left, right)))
            .Order(StringComparer.Ordinal);
        if (!separationRequirements.Select(Pair).SequenceEqual(expectedPairs))
        {
            throw new ArgumentException(
                "All ten separation pairs are required.",
                nameof(separationRequirements));
        }
        foreach (SoloMaintainerException exception in soloMaintainerExceptions)
        {
            AuthoritySetMember? member =
                members.SingleOrDefault(value => value.Actor.Equals(exception.Actor));
            if (member is null ||
                exception.AllowedRoles.Any(role => !member.Roles.Contains(role)))
            {
                throw new ArgumentException(
                    "Solo evidence must name held roles.",
                    nameof(soloMaintainerExceptions));
            }
        }
        foreach (AuthoritySetMember member in members)
        {
            for (int left = 0; left < member.Roles.Count; left++)
                for (int right = left + 1; right < member.Roles.Count; right++)
                {
                    string expected = $"{member.Actor.Value}\0" +
                        $"{member.Roles[left].Value}\0{member.Roles[right].Value}";
                    if (!soloMaintainerExceptions.Any(value =>
                        StringComparer.Ordinal.Equals(ExceptionPair(value), expected)))
                    {
                        throw new ArgumentException(
                            "A role crossing requires exact solo evidence.",
                            nameof(soloMaintainerExceptions));
                    }
                }
        }
        string[] kinds =
            ["evidence.read", "extension.transition", "plan.sealed", "report.sealed"];
        if (!approvalPolicies.Select(value => value.GrantKind).SequenceEqual(kinds))
        {
            throw new ArgumentException(
                "All four approval policies are required.", nameof(approvalPolicies));
        }
    }
    internal static int Hash<T>(IEnumerable<T> values)
    {
        HashCode hash = new();
        foreach (T value in values)
        {
            hash.Add(value);
        }
        return hash.ToHashCode();
    }
    private static string Pair(RoleSeparationRequirement value) =>
        $"{value.First.Value}\0{value.Second.Value}";
    private static string ExceptionPair(SoloMaintainerException value) =>
        $"{value.Actor.Value}\0{value.AllowedRoles[0].Value}\0" +
        value.AllowedRoles[1].Value;
    private static string ExceptionKey(SoloMaintainerException value) =>
        $"{ExceptionPair(value)}\0{value.IndependentEvidenceDigest.Value}";
}
