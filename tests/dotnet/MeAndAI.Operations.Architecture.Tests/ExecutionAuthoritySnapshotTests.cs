using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ExecutionAuthoritySnapshotTests
{
    private static readonly AuthorityRole[] Roles = [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer, AuthorityRole.GrantIssuer, AuthorityRole.Executor];
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_snapshot_and_role_separation_are_exact()
    {
        List<AuthoritySetMember> members = DistinctMembers();
        List<RoleSeparationRequirement> separations = Separations();
        List<AuthorityApprovalPolicy> policies = Policies();
        List<JournalStoreReference> stores = [JournalStoreReference.Parse("store.zulu"), JournalStoreReference.Parse("store.alpha")];
        ApprovalAuthoritySetSnapshot snapshot = ApprovalAuthoritySetSnapshot.Create(
            AuthoritySetId.Parse("authority.primary"), "1", AuthorityRevision.Create(7),
            AuthorityRevision.Create(3), Digest('a'), members.AsEnumerable().Reverse(),
            separations.AsEnumerable().Reverse(), [], policies.AsEnumerable().Reverse(), stores);
        Assert.Equal("authority.primary", snapshot.Id.Value);
        Assert.Equal("1", snapshot.SchemaVersion);
        Assert.Equal(7, snapshot.Revision.Value);
        Assert.Equal(3, snapshot.RevocationEpoch.Value);
        Assert.Equal(new string('a', 64), snapshot.Digest.Value);
        Assert.Equal(["actor.envelope", "actor.executor", "actor.final", "actor.issuer", "actor.proposal"], snapshot.Members.Select(static member => member.Actor.Value));
        Assert.Equal(10, snapshot.SeparationRequirements.Count);
        Assert.Equal(["evidence.read", "extension.transition", "plan.sealed", "report.sealed"], snapshot.ApprovalPolicies.Select(static policy => policy.GrantKind));
        Assert.Equal(["store.alpha", "store.zulu"], snapshot.JournalStores.Select(static store => store.Value));
        members.Clear();
        separations.Clear();
        policies.Clear();
        stores.Clear();
        Assert.Equal(5, snapshot.Members.Count);
        Assert.Equal(10, snapshot.SeparationRequirements.Count);
        Assert.Equal(4, snapshot.ApprovalPolicies.Count);
        Assert.Equal(2, snapshot.JournalStores.Count);

        ApprovalAuthoritySetSnapshot equivalent = ApprovalAuthoritySetSnapshot.Create(
            AuthoritySetId.Parse("authority.primary"), "1", AuthorityRevision.Create(7),
            AuthorityRevision.Create(3), Digest('a'), DistinctMembers(), Separations(), [],
            Policies(), [JournalStoreReference.Parse("store.alpha"), JournalStoreReference.Parse("store.zulu")]);
        Assert.Equal(snapshot, equivalent);
        Assert.Equal(snapshot.GetHashCode(), equivalent.GetHashCode());

        AuthoritySetBinding binding = AuthoritySetBinding.From(snapshot);
        Assert.Equal(snapshot.Id, binding.Id);
        Assert.Equal(snapshot.Revision, binding.Revision);
        Assert.Equal(snapshot.RevocationEpoch, binding.RevocationEpoch);
        Assert.Equal(snapshot.Digest, binding.Digest);
        Assert.Equal(binding, AuthoritySetBinding.From(equivalent));
    }
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_scalar_values_are_canonical_and_closed()
    {
        AuthorityActorId actor = AuthorityActorId.Parse("actor.alpha-2");
        AuthoritySetId set = AuthoritySetId.Parse("authority.primary");
        JournalStoreReference store = JournalStoreReference.Parse("store.primary");

        Assert.Equal("actor.alpha-2", actor.Value);
        Assert.Equal("actor.alpha-2", actor.ToString());
        Assert.Equal("authority.primary", set.ToString());
        Assert.Equal("store.primary", store.ToString());
        Assert.True(AuthorityActorId.TryParse("actor.alpha-2", out AuthorityActorId? parsed));
        Assert.Equal(actor, parsed);
        Assert.False(AuthorityActorId.TryParse("Actor", out parsed));
        Assert.Null(parsed);
        Assert.False(AuthoritySetId.TryParse(null, out _));
        Assert.False(JournalStoreReference.TryParse("store..alpha", out _));

        Assert.Throws<ArgumentNullException>(
            "value", () => AuthorityActorId.Parse(null!));
        Assert.Throws<FormatException>(() => AuthorityActorId.Parse(" actor"));
        Assert.Throws<FormatException>(() => AuthoritySetId.Parse("actor--alpha"));
        Assert.Throws<FormatException>(() => JournalStoreReference.Parse("store.alpha-"));
        Assert.Throws<FormatException>(() => AuthorityActorId.Parse(new string('a', 129)));
        Assert.Throws<FormatException>(() => AuthorityActorId.Parse("actor.\u0131"));
        Assert.Throws<FormatException>(() => AuthorityActorId.Parse("actor.\0alpha"));

        AuthorityDigest digest = AuthorityDigest.Parse(new string('b', 64));
        Assert.Equal(new string('b', 64), digest.ToString());
        Assert.Equal(new string('0', 64), AuthorityDigest.FromHashBytes(new byte[32]).Value);
        Assert.True(AuthorityDigest.TryParse(new string('c', 64), out _));
        Assert.False(AuthorityDigest.TryParse(new string('A', 64), out _));
        Assert.Throws<ArgumentNullException>("value", () => AuthorityDigest.Parse(null!));
        Assert.Throws<FormatException>(() => AuthorityDigest.Parse(new string('a', 63)));
        Assert.Throws<ArgumentException>(
            "hashBytes", () => AuthorityDigest.FromHashBytes(new byte[31]));

        Assert.Equal("0", AuthorityRevision.Create(0).ToString());
        Assert.Throws<ArgumentOutOfRangeException>(
            "value", () => AuthorityRevision.Create(-1));

        Assert.Equal("proposal-actor", AuthorityRole.ProposalActor.Value);
        Assert.Equal("envelope-reviewer", AuthorityRole.EnvelopeReviewer.Value);
        Assert.Equal("final-plan-reviewer", AuthorityRole.FinalPlanReviewer.Value);
        Assert.Equal("grant-issuer", AuthorityRole.GrantIssuer.Value);
        Assert.Equal("executor", AuthorityRole.Executor.Value);
        Assert.Same(AuthorityRole.Executor, AuthorityRole.Parse("executor"));
        Assert.Throws<ArgumentNullException>("value", () => AuthorityRole.Parse(null!));
        Assert.Throws<FormatException>(() => AuthorityRole.Parse("reader"));
    }
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_snapshot_rejects_incomplete_or_ambiguous_authority()
    {
        ArgumentException missingRole = Assert.Throws<ArgumentException>(() =>
            Snapshot(
                members: DistinctMembers().Where(static member =>
                    member.Actor.Value != "actor.executor")));
        Assert.Equal("members", missingRole.ParamName);

        List<AuthoritySetMember> duplicateActor = DistinctMembers();
        duplicateActor.Add(AuthoritySetMember.Create(
            AuthorityActorId.Parse("actor.proposal"),
            [AuthorityRole.Executor]));
        Assert.Equal("members", Assert.Throws<ArgumentException>(() =>
            Snapshot(members: duplicateActor)).ParamName);

        Assert.Equal("separationRequirements", Assert.Throws<ArgumentException>(() =>
            Snapshot(separations: Separations().Skip(1))).ParamName);
        Assert.Equal("approvalPolicies", Assert.Throws<ArgumentException>(() =>
            Snapshot(policies: Policies().Skip(1))).ParamName);
        Assert.Equal("journalStores", Assert.Throws<ArgumentException>(() =>
            Snapshot(stores: [])).ParamName);
        Assert.Equal("schemaVersion", Assert.Throws<ArgumentException>(() =>
            Snapshot(schemaVersion: "01")).ParamName);

        Assert.Equal("second", Assert.Throws<ArgumentException>(() =>
            RoleSeparationRequirement.Create(
                AuthorityRole.Executor,
                AuthorityRole.Executor)).ParamName);
        Assert.Equal("requiredApprovalRoles", Assert.Throws<ArgumentException>(() =>
            AuthorityApprovalPolicy.Create(
                "plan.sealed",
                [AuthorityRole.ProposalActor])).ParamName);
        Assert.Equal("grantKind", Assert.Throws<ArgumentException>(() =>
            AuthorityApprovalPolicy.Create(
                "unknown.kind",
                [AuthorityRole.Executor])).ParamName);
    }
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_solo_maintainer_exception_is_exact_and_pair_scoped()
    {
        AuthorityActorId solo = AuthorityActorId.Parse("actor.solo");
        List<AuthoritySetMember> members =
        [
            AuthoritySetMember.Create(solo,
                [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.final"),
                [AuthorityRole.FinalPlanReviewer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.issuer"),
                [AuthorityRole.GrantIssuer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.executor"),
                [AuthorityRole.Executor])
        ];
        SoloMaintainerException exception = SoloMaintainerException.Create(
            solo,
            [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer],
            Digest('d'));

        ApprovalAuthoritySetSnapshot accepted =
            Snapshot(members: members, exceptions: [exception]);
        Assert.Single(accepted.SoloMaintainerExceptions);
        Assert.Equal(
            ["envelope-reviewer", "proposal-actor"],
            accepted.SoloMaintainerExceptions[0].AllowedRoles
                .Select(static role => role.Value));

        Assert.Equal("soloMaintainerExceptions", Assert.Throws<ArgumentException>(() =>
            Snapshot(members: members, exceptions: [])).ParamName);
        Assert.Equal("allowedRoles", Assert.Throws<ArgumentException>(() =>
            SoloMaintainerException.Create(
                solo, [AuthorityRole.ProposalActor], Digest('e'))).ParamName);
        Assert.Equal("soloMaintainerExceptions", Assert.Throws<ArgumentException>(() =>
            Snapshot(
                members: members,
                exceptions:
                [
                    exception,
                    SoloMaintainerException.Create(
                        solo,
                        [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer],
                        Digest('e'))
                ])).ParamName);
    }
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_approval_floors_and_solo_crossings_fail_closed()
    {
        (string Kind, AuthorityRole[] Floor)[] floors =
        [
            ("evidence.read", [AuthorityRole.EnvelopeReviewer]),
            ("plan.sealed", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer]),
            ("report.sealed", [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer]),
            ("extension.transition", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer])
        ];
        foreach ((string kind, AuthorityRole[] floor) in floors)
        {
            Assert.Equal("requiredApprovalRoles", Assert.Throws<ArgumentException>(() =>
                AuthorityApprovalPolicy.Create(kind, floor.Skip(1))).ParamName);
        }
        AuthorityApprovalPolicy additive = AuthorityApprovalPolicy.Create(
            "evidence.read",
            [AuthorityRole.EnvelopeReviewer, AuthorityRole.Executor]);
        List<AuthorityApprovalPolicy> additivePolicies = Policies();
        additivePolicies.RemoveAll(static policy =>
            policy.GrantKind == "evidence.read");
        additivePolicies.Add(additive);
        Assert.Contains(AuthorityRole.Executor,
            Snapshot(policies: additivePolicies).ApprovalPolicies
                .Single(static policy => policy.GrantKind == "evidence.read")
                .RequiredApprovalRoles);

        AuthorityActorId solo = AuthorityActorId.Parse("actor.solo");
        List<AuthoritySetMember> twoRoleMembers =
        [
            AuthoritySetMember.Create(solo, [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.final"), [AuthorityRole.FinalPlanReviewer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.issuer"), [AuthorityRole.GrantIssuer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.executor"), [AuthorityRole.Executor])
        ];
        Assert.Equal("soloMaintainerExceptions", Assert.Throws<ArgumentException>(() =>
            Snapshot(members: twoRoleMembers, exceptions:
            [
                SoloMaintainerException.Create(solo,
                    [AuthorityRole.ProposalActor, AuthorityRole.Executor],
                    Digest('b'))
            ])).ParamName);
        Assert.Equal("soloMaintainerExceptions", Assert.Throws<ArgumentException>(() =>
            Snapshot(members: twoRoleMembers, exceptions:
            [
                SoloMaintainerException.Create(
                    AuthorityActorId.Parse("actor.unknown"),
                    [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer],
                    Digest('b'))
            ])).ParamName);

        List<AuthoritySetMember> threeRoleMembers =
        [
            AuthoritySetMember.Create(solo, [AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.issuer"), [AuthorityRole.GrantIssuer]),
            AuthoritySetMember.Create(AuthorityActorId.Parse("actor.executor"), [AuthorityRole.Executor])
        ];
        SoloMaintainerException[] threeExactPairs =
        [
            Solo(solo, AuthorityRole.ProposalActor, AuthorityRole.EnvelopeReviewer, 'b'),
            Solo(solo, AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer, 'c'),
            Solo(solo, AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer, 'd')
        ];
        Assert.Equal("soloMaintainerExceptions", Assert.Throws<ArgumentException>(() =>
            Snapshot(members: threeRoleMembers,
                exceptions: threeExactPairs.Take(2))).ParamName);
        Assert.Equal(3,
            Snapshot(members: threeRoleMembers, exceptions: threeExactPairs)
                .SoloMaintainerExceptions.Count);

        Assert.Equal("journalStores", Assert.Throws<ArgumentException>(() =>
            Snapshot(stores:
            [
                JournalStoreReference.Parse("store.primary"),
                JournalStoreReference.Parse("store.primary")
            ])).ParamName);
        Assert.Equal("members", Assert.Throws<ArgumentException>(() =>
            Snapshot(members: DistinctMembers().Append(null!))).ParamName);
    }
    private static ApprovalAuthoritySetSnapshot Snapshot(
        string schemaVersion = "1",
        IEnumerable<AuthoritySetMember>? members = null,
        IEnumerable<RoleSeparationRequirement>? separations = null,
        IEnumerable<SoloMaintainerException>? exceptions = null,
        IEnumerable<AuthorityApprovalPolicy>? policies = null,
        IEnumerable<JournalStoreReference>? stores = null) =>
        ApprovalAuthoritySetSnapshot.Create(
            AuthoritySetId.Parse("authority.primary"),
            schemaVersion,
            AuthorityRevision.Create(1),
            AuthorityRevision.Create(0),
            Digest('a'),
            members ?? DistinctMembers(),
            separations ?? Separations(),
            exceptions ?? [],
            policies ?? Policies(),
            stores ?? [JournalStoreReference.Parse("store.primary")]);

    private static List<AuthoritySetMember> DistinctMembers() =>
    [
        AuthoritySetMember.Create(AuthorityActorId.Parse("actor.proposal"), [AuthorityRole.ProposalActor]),
        AuthoritySetMember.Create(AuthorityActorId.Parse("actor.envelope"), [AuthorityRole.EnvelopeReviewer]),
        AuthoritySetMember.Create(AuthorityActorId.Parse("actor.final"), [AuthorityRole.FinalPlanReviewer]),
        AuthoritySetMember.Create(AuthorityActorId.Parse("actor.issuer"), [AuthorityRole.GrantIssuer]),
        AuthoritySetMember.Create(AuthorityActorId.Parse("actor.executor"), [AuthorityRole.Executor])
    ];

    private static List<RoleSeparationRequirement> Separations() =>
    [
        .. (from left in Roles
            from right in Roles
            where StringComparer.Ordinal.Compare(left.Value, right.Value) < 0
            select RoleSeparationRequirement.Create(left, right))
    ];

    private static List<AuthorityApprovalPolicy> Policies() =>
    [
        AuthorityApprovalPolicy.Create("evidence.read", [AuthorityRole.EnvelopeReviewer]),
        AuthorityApprovalPolicy.Create("plan.sealed", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer]),
        AuthorityApprovalPolicy.Create("report.sealed", [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer]),
        AuthorityApprovalPolicy.Create("extension.transition", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer])
    ];

    private static AuthorityDigest Digest(char value) =>
        AuthorityDigest.Parse(new string(value, 64));

    private static SoloMaintainerException Solo(
        AuthorityActorId actor, AuthorityRole first, AuthorityRole second,
        char digest) => SoloMaintainerException.Create(
            actor, [first, second], Digest(digest));
}
