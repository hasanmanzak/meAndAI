using MeAndAI.Operations.Application.ExecutionAuthority;
using MeAndAI.Operations.Domain.ExecutionAuthority;

#pragma warning disable CA1822 // Fixture helpers intentionally model instance-scoped state.

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ExecutionGrantContractTests
{
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public async Task TEST_0212_grant_is_fresh_exact_non_transitive_and_single_use()
    {
        Fixture fixture = new();
        GrantValidationRequest request = fixture.Request();
        ExecutionGrantAuthorizer authorizer = fixture.Authorizer();

        ExecutionGrantDecision first = await authorizer.AuthorizeAndConsumeAsync(
            request, CancellationToken.None);
        ExecutionGrantDecision replay = await authorizer.AuthorizeAndConsumeAsync(
            request, CancellationToken.None);

        Assert.True(first.IsAuthorized);
        Assert.Equal(ExecutionGrantRejection.None, first.Rejection);
        Assert.False(replay.IsAuthorized);
        Assert.Equal(ExecutionGrantRejection.Replayed, replay.Rejection);
        Assert.Equal(2, fixture.Port.MutationCalls);
        Assert.Equal(2, fixture.Port.AuthorityReads);
        Assert.Equal(2, fixture.Port.HeadReads);
        Assert.Equal(AuthoritySetBinding.From(fixture.Snapshot),
            fixture.Port.LastConsumption!.ExpectedCurrentAuthoritySet);
        Assert.Equal(fixture.StoreHead,
            fixture.Port.LastConsumption.ExpectedStoreHead);
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public async Task TEST_0212_first_failure_order_and_pre_mutation_store_checks_are_exact()
    {
        Fixture missing = new() { ReturnSnapshot = false };
        await AssertRejected(missing, missing.Request(),
            ExecutionGrantRejection.SnapshotUnavailable);

        Fixture drift = new();
        await AssertRejected(drift, drift.Request(authoritySet: drift.Binding('f')),
            ExecutionGrantRejection.SnapshotDrift);
        Fixture actor = new();
        await AssertRejected(actor,
            actor.Request(executingActor: AuthorityActorId.Parse("actor.other")),
            ExecutionGrantRejection.ActorMismatch);
        Fixture conflict = new();
        await AssertRejected(conflict, conflict.Request(approvals:
        [
            GrantApprovalEvidence.Create(conflict.Issuer,
                AuthorityRole.ProposalActor, Digest('1')),
            GrantApprovalEvidence.Create(conflict.FinalReviewer,
                AuthorityRole.FinalPlanReviewer, Digest('2'))
        ]), ExecutionGrantRejection.RoleConflict);
        Fixture approval = new();
        await AssertRejected(approval, approval.Request(approvals:
        [
            GrantApprovalEvidence.Create(approval.ProposalActor,
                AuthorityRole.ProposalActor, Digest('1'))
        ]), ExecutionGrantRejection.ApprovalMismatch);

        Fixture fields = new();
        await AssertRejected(fields, fields.Request(expectedSubject:
            ExecutionSubject.Create("worker", "actor.other")),
            ExecutionGrantRejection.SubjectMismatch);
        await AssertRejected(new(), new Fixture().Request(expectedTarget:
            ExecutionTarget.Create("repository", "repo.other", "generation.one")),
            ExecutionGrantRejection.TargetMismatch);
        Fixture operation = new();
        await AssertRejected(operation, operation.Request(expectedOperation:
            AuthorityOperationId.Parse("operation.other")),
            ExecutionGrantRejection.OperationMismatch);
        Fixture generation = new();
        await AssertRejected(generation, generation.Request(expectedGeneration:
            GrantGeneration.Create(8)), ExecutionGrantRejection.GenerationMismatch);
        Fixture lease = new();
        await AssertRejected(lease, lease.Request(expectedLease:
            LeaseFenceBinding.Create(lease.Generation, "worker.other", "fence.one")),
            ExecutionGrantRejection.LeaseFenceMismatch);
        Fixture capability = new();
        await AssertRejected(capability, capability.Request(required:
            ExecutionCapability.ProviderMutate), ExecutionGrantRejection.CapabilityMismatch);
        Fixture binding = new();
        await AssertRejected(binding, binding.Request(expectedBinding:
            binding.PlanBinding(effect: "effect.other")),
            ExecutionGrantRejection.BindingMismatch);
        Fixture early = new();
        await AssertRejected(early, early.Request(observedAt: early.Now.AddMinutes(-2)),
            ExecutionGrantRejection.NotYetValid);
        Fixture expired = new();
        await AssertRejected(expired, expired.Request(observedAt: expired.Now.AddMinutes(10)),
            ExecutionGrantRejection.Expired);

        Fixture unapproved = new();
        await AssertRejected(unapproved, unapproved.Request(
            store: JournalStoreReference.Parse("store.other")),
            ExecutionGrantRejection.GrantStoreDrift);
        Assert.Equal(0, unapproved.Port.HeadReads);
        Fixture missingHead = new() { ReturnHead = false };
        await AssertRejected(missingHead, missingHead.Request(),
            ExecutionGrantRejection.GrantStoreDrift);
        Assert.Equal(1, missingHead.Port.HeadReads);
        Assert.Equal(0, missingHead.Port.MutationCalls);
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public async Task TEST_0212_approval_separation_drift_and_validity_edges_fail_closed()
    {
        Fixture empty = new();
        Assert.Equal("approvals", Assert.Throws<ArgumentException>(() =>
            empty.Request(approvals: [])).ParamName);
        foreach (IEnumerable<GrantApprovalEvidence> approvals in new Fixture().InvalidApprovals())
        {
            Fixture fixture = new();
            await AssertRejected(fixture, fixture.Request(approvals: approvals),
                ExecutionGrantRejection.ApprovalMismatch);
        }
        Fixture proposalFinal = new();
        await AssertRejected(proposalFinal, proposalFinal.Request(approvals:
            proposalFinal.PlanApprovals(proposalFinal.ProposalActor)), ExecutionGrantRejection.RoleConflict);
        Fixture issuer = new();
        await AssertRejected(issuer, issuer.Request(approvals:
            [.. issuer.PlanApprovals().Select(value => value.Role == AuthorityRole.ProposalActor
                ? GrantApprovalEvidence.Create(issuer.Issuer, value.Role, value.EvidenceDigest) : value)]),
            ExecutionGrantRejection.RoleConflict);
        Fixture executor = new();
        await AssertRejected(executor, executor.Request(approvals:
            [.. executor.PlanApprovals().Select(value => value.Role == AuthorityRole.FinalPlanReviewer
                ? GrantApprovalEvidence.Create(executor.Executor, value.Role, value.EvidenceDigest) : value)]),
            ExecutionGrantRejection.RoleConflict);
        Fixture envelope = new();
        ReadGrantBinding read = envelope.ReadBinding(paths: ["docs/a.md"]);
        await AssertRejected(envelope, envelope.Request(required: ExecutionCapability.RepositoryRead,
            grantCapability: ExecutionCapability.RepositoryRead, grantBinding: read, expectedBinding: read,
            approvals: [GrantApprovalEvidence.Create(envelope.Issuer, AuthorityRole.EnvelopeReviewer, Digest('1'))]),
            ExecutionGrantRejection.RoleConflict);
        Fixture solo = new(soloProposalFinal: true);
        Assert.True((await solo.Authorizer().AuthorizeAndConsumeAsync(solo.Request(
            approvals: solo.PlanApprovals(solo.ProposalActor)), CancellationToken.None)).IsAuthorized);

        foreach (AuthoritySetBinding drift in new[] { new Fixture().Binding('f'), new Fixture().Binding(revision: 8), new Fixture().Binding(epoch: 4) })
        {
            Fixture fixture = new();
            await AssertRejected(fixture, fixture.Request(authoritySet: drift), ExecutionGrantRejection.SnapshotDrift);
        }
        Fixture grantGeneration = new();
        await AssertRejected(grantGeneration, grantGeneration.Request(grantGeneration: GrantGeneration.Create(8)), ExecutionGrantRejection.GenerationMismatch);
        Fixture grantLease = new();
        await AssertRejected(grantLease, grantLease.Request(grantLease: LeaseFenceBinding.Create(GrantGeneration.Create(8), "worker.one", "fence.one")), ExecutionGrantRejection.GenerationMismatch);
        Fixture expectedGeneration = new();
        await AssertRejected(expectedGeneration, expectedGeneration.Request(expectedGeneration: GrantGeneration.Create(8)), ExecutionGrantRejection.GenerationMismatch);
        Fixture expectedLeaseGeneration = new();
        await AssertRejected(expectedLeaseGeneration, expectedLeaseGeneration.Request(expectedLease: LeaseFenceBinding.Create(GrantGeneration.Create(8), "worker.one", "fence.one")), ExecutionGrantRejection.GenerationMismatch);
        Fixture fence = new();
        await AssertRejected(fence, fence.Request(expectedLease: LeaseFenceBinding.Create(fence.Generation, "worker.one", "fence.other")), ExecutionGrantRejection.LeaseFenceMismatch);

        Fixture notBefore = new();
        Assert.True((await notBefore.Authorizer().AuthorizeAndConsumeAsync(notBefore.Request(notBefore: notBefore.Now, observedAt: notBefore.Now), CancellationToken.None)).IsAuthorized);
        Fixture beforeExpiry = new();
        Assert.True((await beforeExpiry.Authorizer().AuthorizeAndConsumeAsync(beforeExpiry.Request(expires: beforeExpiry.Now.AddTicks(1), observedAt: beforeExpiry.Now), CancellationToken.None)).IsAuthorized);
        Fixture expiry = new();
        await AssertRejected(expiry, expiry.Request(expires: expiry.Now, observedAt: expiry.Now), ExecutionGrantRejection.Expired);
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public async Task TEST_0212_all_capability_binding_pairs_are_non_transitive()
    {
        ExecutionCapability[] capabilities = [ExecutionCapability.RepositoryRead, ExecutionCapability.ProviderRead,
            ExecutionCapability.RepositoryMutate, ExecutionCapability.ProviderMutate, ExecutionCapability.ReportPublish,
            ExecutionCapability.ExtensionActivate, ExecutionCapability.ReleasePublish, ExecutionCapability.AuthorityTransfer];
        foreach (ExecutionCapability capability in capabilities)
        {
            for (int bindingCase = 0; bindingCase < 6; bindingCase++)
            {
                Fixture fixture = new();
                ExecutionGrantBinding binding = fixture.BindingCase(bindingCase);
                bool expected = capability == fixture.CapabilityCase(bindingCase);
                ExecutionGrantDecision decision = await fixture.Authorizer().AuthorizeAndConsumeAsync(fixture.Request(
                    required: capability, grantCapability: capability, grantBinding: binding,
                    expectedBinding: binding, approvals: fixture.ApprovalsFor(binding)), CancellationToken.None);
                Assert.Equal(expected, decision.IsAuthorized);
                Assert.Equal(expected ? ExecutionGrantRejection.None : ExecutionGrantRejection.CapabilityMismatch, decision.Rejection);
            }
        }
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public async Task TEST_0212_atomic_mutation_rechecks_replay_authority_and_store_head()
    {
        Fixture idempotency = new();
        Assert.True((await idempotency.Authorizer().AuthorizeAndConsumeAsync(idempotency.Request(), CancellationToken.None)).IsAuthorized);
        await AssertRejected(idempotency, idempotency.Request(grantId: AuthorityGrantId.Parse("grant.other")), ExecutionGrantRejection.Replayed);
        await AssertRejected(idempotency, idempotency.Request(idempotencyKey: IdempotencyKey.Parse("attempt.other")), ExecutionGrantRejection.Replayed);

        Fixture authority = new();
        authority.Port.CurrentAuthoritySet = authority.Binding('f');
        await AssertRejected(authority, authority.Request(), ExecutionGrantRejection.SnapshotDrift);
        Fixture head = new();
        head.Port.CurrentHead = Digest('d');
        await AssertRejected(head, head.Request(), ExecutionGrantRejection.GrantStoreDrift);
        head.Port.CurrentHead = head.StoreHead;
        Assert.True((await head.Authorizer().AuthorizeAndConsumeAsync(head.Request(), CancellationToken.None)).IsAuthorized);
        head.Port.CurrentHead = Digest('d');
        await AssertRejected(head, head.Request(), ExecutionGrantRejection.Replayed);
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_grant_values_are_canonical_defensive_and_closed()
    {
        Assert.Equal("repository.read", ExecutionCapability.RepositoryRead.Value);
        Assert.Same(ExecutionCapability.AuthorityTransfer,
            ExecutionCapability.Parse("authority.transfer"));
        Assert.Throws<FormatException>(() => ExecutionCapability.Parse("other"));
        Assert.Equal("grant-store.drift",
            ExecutionGrantRejection.GrantStoreDrift.Value);
        Assert.Same(ExecutionGrantRejection.CasConflict,
            ExecutionGrantRejection.Parse("cas.conflict"));
        Assert.Throws<FormatException>(() => ExecutionGrantRejection.Parse("unknown"));
        Assert.Equal("5", GrantGeneration.Create(5).ToString());
        Assert.Throws<ArgumentOutOfRangeException>("value",
            () => GrantGeneration.Create(0));
        Assert.Equal("grant.primary", AuthorityGrantId.Parse("grant.primary").Value);
        Assert.True(IdempotencyKey.TryParse("attempt.one", out _));
        Assert.False(AuthorityOperationId.TryParse("Bad", out _));

        Assert.Equal("kind.value", ExecutionSubject.Create(
            "kind.value", "subject:One").Kind);
        Assert.Throws<ArgumentException>("kind",
            () => ExecutionSubject.Create("Bad", "subject.one"));
        Assert.Throws<ArgumentException>("kind",
            () => ExecutionSubject.Create("kind-value", "subject.one"));
        Assert.Equal("kind.part-value", ExecutionSubject.Create(
            "kind.part-value", "subject.one").Kind);
        Assert.Throws<ArgumentException>("identity",
            () => ExecutionTarget.Create("repository", " repo", "generation.one"));
        Assert.Throws<ArgumentException>("ownerIdentity",
            () => LeaseFenceBinding.Create(
                GrantGeneration.Create(1), " owner", "fence.one"));

        Fixture fixture = new();
        List<string> paths = ["src/z.cs", "src/a.cs"];
        PlanGrantBinding plan = fixture.PlanBinding(paths: paths);
        paths.Clear();
        Assert.Equal(["src/a.cs", "src/z.cs"], plan.AllowedRepositoryPaths);
        Assert.Throws<ArgumentException>("allowedRepositoryPaths", () =>
            fixture.PlanBinding(paths: [], providers: []));
        Assert.Throws<ArgumentException>("allowedRepositoryPaths", () =>
            fixture.PlanBinding(paths: ["src/a.cs"], providers: ["object.one"]));
        Assert.Throws<ArgumentException>("requiredApprovalRoles", () =>
            PlanGrantBinding.Create(Digest('1'), Ref('a'), Ref('b'), Ref('c'),
                ["src/a.cs"], [], "stage.apply", "effect.apply",
                [AuthorityRole.ProposalActor], Digest('2')));

        ExecutionGrantDecision authorized = ExecutionGrantDecision.Authorized();
        Assert.True(authorized.IsAuthorized);
        Assert.Equal(ExecutionGrantRejection.None, authorized.Rejection);
        Assert.Throws<ArgumentException>("rejection", () =>
            ExecutionGrantDecision.Rejected(ExecutionGrantRejection.None));
        Assert.Equal("observedAtUtc", Assert.Throws<ArgumentException>(() =>
            fixture.Request(observedAt: new DateTimeOffset(
                fixture.Now.DateTime, TimeSpan.FromHours(1)))).ParamName);
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public async Task TEST_0212_pre_cancellation_performs_no_port_call()
    {
        Fixture fixture = new();
        using CancellationTokenSource source = new();
        source.Cancel();
        OperationCanceledException exception = await Assert.ThrowsAsync<OperationCanceledException>(
            async () => await fixture.Authorizer().AuthorizeAndConsumeAsync(
                fixture.Request(), source.Token));
        Assert.Equal(source.Token, exception.CancellationToken);
        Assert.Equal(0, fixture.Port.AuthorityReads);
        Assert.Equal(0, fixture.Port.HeadReads);
        Assert.Equal(0, fixture.Port.MutationCalls);
    }

    private static async Task AssertRejected(
        Fixture fixture, GrantValidationRequest request,
        ExecutionGrantRejection rejection)
    {
        ExecutionGrantDecision result = await fixture.Authorizer()
            .AuthorizeAndConsumeAsync(request, CancellationToken.None);
        Assert.False(result.IsAuthorized);
        Assert.Equal(rejection, result.Rejection);
    }
    private static AuthorityDigest Digest(char value) =>
        AuthorityDigest.Parse(new string(value, 64));
    private static string Ref(char value) => new(value, 40);

    private sealed class Fixture
    {
        internal readonly AuthorityActorId ProposalActor = AuthorityActorId.Parse("actor.proposal");
        internal readonly AuthorityActorId EnvelopeActor = AuthorityActorId.Parse("actor.envelope");
        internal readonly AuthorityActorId FinalReviewer = AuthorityActorId.Parse("actor.final");
        internal readonly AuthorityActorId Issuer = AuthorityActorId.Parse("actor.issuer");
        internal readonly AuthorityActorId Executor = AuthorityActorId.Parse("actor.executor");
        internal readonly GrantGeneration Generation = GrantGeneration.Create(7);
        internal readonly DateTimeOffset Now = new(2026, 8, 14, 12, 0, 0, TimeSpan.Zero);
        internal readonly AuthorityDigest StoreHead = Digest('e');
        internal readonly FakePort Port;
        internal readonly ApprovalAuthoritySetSnapshot Snapshot;
        internal bool ReturnSnapshot { set => Port.ReturnSnapshot = value; }
        internal bool ReturnHead { set => Port.ReturnHead = value; }
        internal Fixture(bool soloProposalFinal = false)
        {
            Snapshot = CreateSnapshot(soloProposalFinal: soloProposalFinal);
            Port = new(Snapshot, StoreHead);
        }
        internal ExecutionGrantAuthorizer Authorizer() =>
            ExecutionGrantAuthorizer.Create(Port, Port);
        internal AuthoritySetBinding Binding(char digest = 'a', long revision = 7, long epoch = 3) =>
            AuthoritySetBinding.From(CreateSnapshot(Digest(digest), revision, epoch));
        internal PlanGrantBinding PlanBinding(
            string effect = "effect.apply", IEnumerable<string>? paths = null,
            IEnumerable<string>? providers = null) => PlanGrantBinding.Create(
                Digest('4'), Ref('a'), Ref('b'), Ref('c'), paths ?? ["src/a.cs"],
                providers ?? [], "stage.apply", effect,
                [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer], Digest('5'));
        internal ReadGrantBinding ReadBinding(
            IEnumerable<string>? paths = null,
            IEnumerable<string>? providers = null) => ReadGrantBinding.Create(
                Digest('6'), Ref('a'), Ref('b'), paths ?? [], providers ?? [],
                "effect.read", [AuthorityRole.EnvelopeReviewer], Digest('7'));
        internal PublicationGrantBinding PublicationBinding() => PublicationGrantBinding.Create(
            Digest('8'), Target(), "gate 1", "result 1", "effect.publish", IdempotencyKey.Parse("attempt.one"),
            [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer], Digest('9'));
        internal ExtensionActivationGrantBinding ActivationBinding() => ExtensionActivationGrantBinding.Create(
            Digest('1'), Digest('2'), "ext:owner:name", Digest('3'), Ref('d'), Digest('4'), Digest('5'), Target(),
            AuthorityRevision.Create(7), "effect.activate", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer], Digest('6'));
        internal GrantApprovalEvidence[] PlanApprovals(AuthorityActorId? both = null) =>
            [Approval(both ?? ProposalActor, AuthorityRole.ProposalActor), Approval(both ?? FinalReviewer, AuthorityRole.FinalPlanReviewer)];
        internal GrantApprovalEvidence[] ApprovalsFor(ExecutionGrantBinding binding) =>
            [.. binding.RequiredApprovalRoles.Select(role => Approval(RoleActor(role), role))];
        internal IEnumerable<GrantApprovalEvidence>[] InvalidApprovals() =>
        [
            [Approval(ProposalActor, AuthorityRole.ProposalActor)],
            [.. PlanApprovals(), Approval(EnvelopeActor, AuthorityRole.EnvelopeReviewer)],
            [.. PlanApprovals(), Approval(EnvelopeActor, AuthorityRole.ProposalActor)],
            [Approval(AuthorityActorId.Parse("actor.other"), AuthorityRole.ProposalActor), Approval(FinalReviewer, AuthorityRole.FinalPlanReviewer)],
            [Approval(ProposalActor, AuthorityRole.EnvelopeReviewer), Approval(FinalReviewer, AuthorityRole.FinalPlanReviewer)]
        ];
        internal ExecutionGrantBinding BindingCase(int value) => value switch
        {
            0 => ReadBinding(paths: ["docs/a.md"]),
            1 => ReadBinding(providers: ["object.one"]),
            2 => PlanBinding(),
            3 => PlanBinding(paths: [], providers: ["object.one"]),
            4 => PublicationBinding(),
            _ => ActivationBinding()
        };
        internal ExecutionCapability CapabilityCase(int value) => value switch
        {
            0 => ExecutionCapability.RepositoryRead,
            1 => ExecutionCapability.ProviderRead,
            2 => ExecutionCapability.RepositoryMutate,
            3 => ExecutionCapability.ProviderMutate,
            4 => ExecutionCapability.ReportPublish,
            _ => ExecutionCapability.ExtensionActivate
        };
        internal GrantValidationRequest Request(
            ExecutionCapability? required = null,
            ExecutionCapability? grantCapability = null,
            ExecutionSubject? expectedSubject = null,
            ExecutionTarget? expectedTarget = null,
            AuthorityOperationId? expectedOperation = null,
            GrantGeneration? expectedGeneration = null,
            LeaseFenceBinding? expectedLease = null,
            ExecutionGrantBinding? grantBinding = null,
            ExecutionGrantBinding? expectedBinding = null,
            AuthorityActorId? executingActor = null,
            DateTimeOffset? observedAt = null,
            AuthoritySetBinding? authoritySet = null,
            IEnumerable<GrantApprovalEvidence>? approvals = null,
            JournalStoreReference? store = null, AuthorityGrantId? grantId = null,
            IdempotencyKey? idempotencyKey = null, GrantGeneration? grantGeneration = null,
            LeaseFenceBinding? grantLease = null, DateTimeOffset? notBefore = null,
            DateTimeOffset? expires = null)
        {
            ExecutionSubject subject = ExecutionSubject.Create("worker", "subject.one");
            ExecutionTarget target = Target();
            AuthorityOperationId operation = AuthorityOperationId.Parse("operation.apply");
            LeaseFenceBinding lease = LeaseFenceBinding.Create(
                Generation, "worker.one", "fence.one");
            ExecutionGrantBinding binding = grantBinding ?? PlanBinding();
            ExecutionGrant grant = ExecutionGrant.Create(
                grantId ?? AuthorityGrantId.Parse("grant.primary"),
                authoritySet ?? AuthoritySetBinding.From(Snapshot),
                grantCapability ?? ExecutionCapability.RepositoryMutate,
                subject, target, operation, grantGeneration ?? Generation,
                idempotencyKey ?? IdempotencyKey.Parse("attempt.one"), Issuer, Executor,
                approvals ?? PlanApprovals(), binding,
                store ?? JournalStoreReference.Parse("store.primary"), grantLease ?? lease,
                Now.AddMinutes(-5), notBefore ?? Now.AddMinutes(-1), expires ?? Now.AddMinutes(5), Digest('9'));
            return GrantValidationRequest.Create(
                grant, required ?? ExecutionCapability.RepositoryMutate,
                expectedSubject ?? subject, expectedTarget ?? target,
                expectedOperation ?? operation, expectedGeneration ?? Generation,
                expectedLease ?? lease, expectedBinding ?? binding,
                executingActor ?? Executor, observedAt ?? Now);
        }
        private ApprovalAuthoritySetSnapshot CreateSnapshot(
            AuthorityDigest? digest = null, long revision = 7, long epoch = 3,
            bool soloProposalFinal = false)
        {
            AuthorityRole[] roles = [AuthorityRole.ProposalActor,
                AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer,
                AuthorityRole.GrantIssuer, AuthorityRole.Executor];
            List<RoleSeparationRequirement> separations = [];
            for (int left = 0; left < roles.Length; left++)
                for (int right = left + 1; right < roles.Length; right++)
                    separations.Add(RoleSeparationRequirement.Create(
                        roles[left], roles[right]));
            return ApprovalAuthoritySetSnapshot.Create(
                AuthoritySetId.Parse("authority.primary"), "1",
                AuthorityRevision.Create(revision), AuthorityRevision.Create(epoch),
                digest ?? Digest('a'),
                [
                    AuthoritySetMember.Create(ProposalActor, soloProposalFinal
                        ? [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer] : [AuthorityRole.ProposalActor]),
                    AuthoritySetMember.Create(EnvelopeActor, [AuthorityRole.EnvelopeReviewer]),
                    AuthoritySetMember.Create(FinalReviewer, [AuthorityRole.FinalPlanReviewer]),
                    AuthoritySetMember.Create(Issuer, [AuthorityRole.GrantIssuer]),
                    AuthoritySetMember.Create(Executor, [AuthorityRole.Executor])
                ], separations, soloProposalFinal
                    ? [SoloMaintainerException.Create(ProposalActor,
                        [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer], Digest('b'))] : [],
                [
                    AuthorityApprovalPolicy.Create("evidence.read", [AuthorityRole.EnvelopeReviewer]),
                    AuthorityApprovalPolicy.Create("plan.sealed", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer]),
                    AuthorityApprovalPolicy.Create("report.sealed", [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer]),
                    AuthorityApprovalPolicy.Create("extension.transition", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer])
                ], [JournalStoreReference.Parse("store.primary")]);
        }
        private ExecutionTarget Target() => ExecutionTarget.Create("repository", "repo.primary", "generation.one");
        private AuthorityActorId RoleActor(AuthorityRole role) => role == AuthorityRole.ProposalActor ? ProposalActor :
            role == AuthorityRole.EnvelopeReviewer ? EnvelopeActor : role == AuthorityRole.FinalPlanReviewer ? FinalReviewer :
            role == AuthorityRole.GrantIssuer ? Issuer : Executor;
        private static GrantApprovalEvidence Approval(AuthorityActorId actor, AuthorityRole role) =>
            GrantApprovalEvidence.Create(actor, role, Digest('1'));
    }

    private sealed class FakePort :
        IExecutionAuthorityReadPort, IExecutionAuthorityMutationPort
    {
        private readonly HashSet<AuthorityGrantId> consumedIds = [];
        private readonly HashSet<IdempotencyKey> consumedKeys = [];
        private readonly ApprovalAuthoritySetSnapshot snapshot;
        private readonly AuthorityDigest readHead;
        internal FakePort(ApprovalAuthoritySetSnapshot snapshot, AuthorityDigest head)
        {
            this.snapshot = snapshot; readHead = head; CurrentHead = head;
            CurrentAuthoritySet = AuthoritySetBinding.From(snapshot);
        }
        internal bool ReturnSnapshot { get; set; } = true;
        internal bool ReturnHead { get; set; } = true;
        internal int AuthorityReads { get; private set; }
        internal int HeadReads { get; private set; }
        internal int MutationCalls { get; private set; }
        internal GrantConsumptionRequest? LastConsumption { get; private set; }
        internal AuthoritySetBinding CurrentAuthoritySet { get; set; }
        internal AuthorityDigest CurrentHead { get; set; }
        public ValueTask<ApprovalAuthoritySetSnapshot?> ReadAuthoritySetAsync(
            AuthoritySetId id, CancellationToken cancellationToken)
        {
            AuthorityReads++;
            return ValueTask.FromResult<ApprovalAuthoritySetSnapshot?>(
                ReturnSnapshot ? snapshot : null);
        }
        public ValueTask<AuthorityDigest?> ReadGrantStoreHeadAsync(
            JournalStoreReference store, CancellationToken cancellationToken)
        {
            HeadReads++;
            return ValueTask.FromResult<AuthorityDigest?>(ReturnHead ? readHead : null);
        }
        public ValueTask<ExtensionActivationRecord?> ReadExtensionActivationAsync(
            ExecutionTarget repository, CancellationToken cancellationToken) =>
            ValueTask.FromResult<ExtensionActivationRecord?>(null);
        public ValueTask<ExecutionGrantDecision> TryConsumeGrantAsync(
            GrantConsumptionRequest request, CancellationToken cancellationToken)
        {
            MutationCalls++;
            LastConsumption = request;
            ExecutionGrant grant = request.Validation.Grant;
            ExecutionGrantDecision decision = consumedIds.Contains(grant.Id) || consumedKeys.Contains(grant.IdempotencyKey)
                ? ExecutionGrantDecision.Rejected(ExecutionGrantRejection.Replayed)
                : !request.ExpectedCurrentAuthoritySet.Equals(CurrentAuthoritySet)
                    ? ExecutionGrantDecision.Rejected(ExecutionGrantRejection.SnapshotDrift)
                    : !request.ExpectedStoreHead.Equals(CurrentHead)
                        ? ExecutionGrantDecision.Rejected(ExecutionGrantRejection.GrantStoreDrift)
                        : ExecutionGrantDecision.Authorized();
            if (decision.IsAuthorized) { consumedIds.Add(grant.Id); consumedKeys.Add(grant.IdempotencyKey); }
            return ValueTask.FromResult(decision);
        }
        public ValueTask<ActivationCasDecision> TryActivateExtensionAsync(
            ExtensionActivationMutationRequest request,
            CancellationToken cancellationToken) =>
            ValueTask.FromResult(ActivationCasDecision.Rejected(
                ExecutionGrantRejection.CasConflict));
    }
}
