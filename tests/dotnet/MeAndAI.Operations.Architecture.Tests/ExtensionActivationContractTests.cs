using MeAndAI.Operations.Application.ExecutionAuthority;
using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ExtensionActivationContractTests
{
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    [Trait("Scenario", "TEST-0212")]
    public async Task TEST_0212_only_fresh_winning_cas_activates_extension()
    {
        Fixture fixture = new();
        FakePort port = new(fixture.Snapshot, fixture.Head, fixture.Current)
        { CoordinateTwoContenders = true };
        ExtensionActivationService service = ExtensionActivationService.Create(port, port);
        Task<ActivationCasDecision> first = service.ActivateAsync(fixture.Command,
            fixture.Executor, fixture.Observed, CancellationToken.None).AsTask();
        Task<ActivationCasDecision> second = service.ActivateAsync(fixture.Command,
            fixture.Executor, fixture.Observed, CancellationToken.None).AsTask();
        ActivationCasDecision[] decisions = await Task.WhenAll(first, second);
        ActivationCasDecision activated = Assert.Single(decisions, static value => value.IsActivated);
        ActivationCasDecision conflict = Assert.Single(decisions, static value => !value.IsActivated);
        Assert.Equal(fixture.Proposed, activated.Record);
        Assert.Equal(ExecutionGrantRejection.CasConflict, conflict.Rejection);
        Assert.Equal(fixture.Proposed, port.Current);
        Assert.Equal(2, port.MutationCalls);

        await AssertRejected(fixture, static value => value.ReturnSnapshot = false,
            ExecutionGrantRejection.SnapshotUnavailable);
        await AssertRejected(fixture, static value => value.ReturnRecord = false,
            ExecutionGrantRejection.ActivationRecordUnavailable);
        await AssertRejected(fixture, static value => value.Current = value.Fixture.Proposed,
            ExecutionGrantRejection.ActivationRecordDrift);
        await AssertRejected(fixture, static value => value.ReturnHead = false,
            ExecutionGrantRejection.GrantStoreDrift);
        FakePort unapprovedStore = new(fixture.CreateSnapshot('6', "store.other"),
            fixture.Head, fixture.Current);
        await AssertRejected(fixture, unapprovedStore, fixture.Command,
            ExecutionGrantRejection.GrantStoreDrift);
        ExtensionActivationCommand wrongFence = ExtensionActivationCommand.Create(
            fixture.Current, fixture.Transition, fixture.Grant,
            LeaseFenceBinding.Create(fixture.Grant.Generation, "owner.other", "fence.one"),
            fixture.Proposed);
        await AssertRejected(fixture, wrongFence, ExecutionGrantRejection.LeaseFenceMismatch);
        ExtensionActivationCommand wrongTransition = ExtensionActivationCommand.Create(
            fixture.Current, Digest('f'), fixture.Grant, fixture.ExpectedFence,
            fixture.Proposed);
        await AssertRejected(fixture, wrongTransition, ExecutionGrantRejection.BindingMismatch);
        await AssertAtomicRejected(fixture, static value => value.IsConsumed = true,
            ExecutionGrantRejection.Replayed);
        await AssertAtomicRejected(fixture, static value => value.CurrentHead = Digest('e'),
            ExecutionGrantRejection.GrantStoreDrift);
        await AssertAtomicRejected(fixture, value => value.CurrentAuthority =
            AuthoritySetBinding.From(fixture.CreateSnapshot('e')),
            ExecutionGrantRejection.SnapshotDrift);

        FakePort canceledPort = new(fixture.Snapshot, fixture.Head, fixture.Current);
        using CancellationTokenSource source = new(); source.Cancel();
        OperationCanceledException canceled = await Assert.ThrowsAsync<OperationCanceledException>(
            () => ExtensionActivationService.Create(canceledPort, canceledPort).ActivateAsync(
                fixture.Command, fixture.Executor, fixture.Observed, source.Token).AsTask());
        Assert.Equal(source.Token, canceled.CancellationToken);
        Assert.Equal(0, canceledPort.Reads + canceledPort.MutationCalls);
        Assert.Equal(ExtensionActivationRecord.CreateSuccessor(fixture.Repository,
            AuthorityRevision.Create(1), AuthorityRevision.Create(1), "ext:repo:test",
            Digest('1'), Digest('2'), Commit, fixture.Current.RecordDigest,
            fixture.Approvals, fixture.Grant.Digest, fixture.Transition,
            fixture.Closure, fixture.Authority).RecordDigest, fixture.Proposed.RecordDigest);
        Assert.NotEqual(fixture.Current.RecordDigest, fixture.Proposed.RecordDigest);
    }

    private static async Task AssertRejected(Fixture fixture,
        Action<FakePort> arrange, ExecutionGrantRejection rejection)
    {
        FakePort port = new(fixture.Snapshot, fixture.Head, fixture.Current)
        { Fixture = fixture };
        arrange(port);
        await AssertRejected(fixture, port, fixture.Command, rejection);
    }
    private static async Task AssertRejected(Fixture fixture,
        ExtensionActivationCommand command, ExecutionGrantRejection rejection)
    {
        FakePort port = new(fixture.Snapshot, fixture.Head, fixture.Current);
        await AssertRejected(fixture, port, command, rejection);
    }
    private static async Task AssertRejected(Fixture fixture, FakePort port,
        ExtensionActivationCommand command, ExecutionGrantRejection rejection)
    {
        ActivationCasDecision result = await ExtensionActivationService.Create(port, port)
            .ActivateAsync(command, fixture.Executor, fixture.Observed, CancellationToken.None);
        Assert.False(result.IsActivated); Assert.Equal(rejection, result.Rejection);
        Assert.Null(result.Record); Assert.Equal(0, port.MutationCalls);
    }
    private static async Task AssertAtomicRejected(Fixture fixture,
        Action<FakePort> arrange, ExecutionGrantRejection rejection)
    {
        FakePort port = new(fixture.Snapshot, fixture.Head, fixture.Current);
        arrange(port);
        ActivationCasDecision result = await ExtensionActivationService.Create(port, port)
            .ActivateAsync(fixture.Command, fixture.Executor, fixture.Observed,
                CancellationToken.None);
        Assert.False(result.IsActivated); Assert.Equal(rejection, result.Rejection);
        Assert.Null(result.Record); Assert.Equal(1, port.MutationCalls);
        Assert.Equal(fixture.Current, port.Current);
    }

    private sealed class Fixture
    {
        internal Fixture()
        {
            Snapshot = CreateSnapshot(); Authority = AuthoritySetBinding.From(Snapshot);
            Current = ExtensionActivationRecord.CreateGenesis(Repository, "ext:repo:test",
                Digest('0'), Digest('0'), Commit, Digest('0'), Approvals,
                Digest('0'), Digest('0'), Digest('0'), Authority);
            ExtensionActivationGrantBinding binding = ExtensionActivationGrantBinding.Create(
                Current.RecordDigest, Digest('2'), "ext:repo:test", Digest('1'),
                Commit, Transition, Closure, Repository, Current.CasVersion,
                "effect.activate", [AuthorityRole.ProposalActor,
                    AuthorityRole.FinalPlanReviewer], Digest('a'));
            Grant = ExecutionGrant.Create(AuthorityGrantId.Parse("grant.activation"),
                Authority, ExecutionCapability.ExtensionActivate,
                ExecutionSubject.Create("extension", "ext:repo:test"), Repository,
                AuthorityOperationId.Parse("operation.activation"), GrantGeneration.Create(7),
                IdempotencyKey.Parse("activation.once"), Issuer, Executor, Approvals,
                binding, JournalStoreReference.Parse("store.primary"), ExpectedFence,
                Observed.AddMinutes(-2), Observed.AddMinutes(-1),
                Observed.AddMinutes(1), Digest('b'));
            Proposed = ExtensionActivationRecord.CreateSuccessor(Repository,
                AuthorityRevision.Create(1), AuthorityRevision.Create(1), "ext:repo:test",
                Digest('1'), Digest('2'), Commit, Current.RecordDigest, Approvals,
                Grant.Digest, Transition, Closure, Authority);
            Command = ExtensionActivationCommand.Create(Current, Transition, Grant,
                ExpectedFence, Proposed);
        }
        internal readonly DateTimeOffset Observed = new(2026, 8, 20, 0, 0, 0, TimeSpan.Zero);
        internal readonly ExecutionTarget Repository =
            ExecutionTarget.Create("repository", "repo.primary", "generation.one");
        internal readonly LeaseFenceBinding ExpectedFence =
            LeaseFenceBinding.Create(GrantGeneration.Create(7), "owner.one", "fence.one");
        internal readonly AuthorityActorId Proposal = AuthorityActorId.Parse("actor.proposal");
        internal readonly AuthorityActorId Reviewer = AuthorityActorId.Parse("actor.reviewer");
        internal readonly AuthorityActorId Issuer = AuthorityActorId.Parse("actor.issuer");
        internal readonly AuthorityActorId Executor = AuthorityActorId.Parse("actor.executor");
        internal IReadOnlyList<GrantApprovalEvidence> Approvals =>
        [
            GrantApprovalEvidence.Create(Proposal, AuthorityRole.ProposalActor, Digest('8')),
            GrantApprovalEvidence.Create(Reviewer, AuthorityRole.FinalPlanReviewer, Digest('9'))
        ];
        internal readonly AuthorityDigest Head = Digest('7');
        internal readonly AuthorityDigest Transition = Digest('3');
        internal readonly AuthorityDigest Closure = Digest('4');
        internal ApprovalAuthoritySetSnapshot Snapshot { get; }
        internal AuthoritySetBinding Authority { get; }
        internal ExtensionActivationRecord Current { get; }
        internal ExtensionActivationRecord Proposed { get; }
        internal ExecutionGrant Grant { get; }
        internal ExtensionActivationCommand Command { get; }
        internal ApprovalAuthoritySetSnapshot CreateSnapshot(
            char digest = '6', string store = "store.primary")
        {
            AuthorityActorId envelope = AuthorityActorId.Parse("actor.envelope");
            AuthorityRole[] roles = [AuthorityRole.ProposalActor,
                AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer,
                AuthorityRole.GrantIssuer, AuthorityRole.Executor];
            RoleSeparationRequirement[] separations =
            [.. from left in roles from right in roles
                where StringComparer.Ordinal.Compare(left.Value, right.Value) < 0
                select RoleSeparationRequirement.Create(left, right)];
            return ApprovalAuthoritySetSnapshot.Create(AuthoritySetId.Parse("authority.primary"),
                "1", AuthorityRevision.Create(1), AuthorityRevision.Create(0), Digest(digest),
                [AuthoritySetMember.Create(Proposal, [AuthorityRole.ProposalActor]),
                    AuthoritySetMember.Create(envelope, [AuthorityRole.EnvelopeReviewer]),
                    AuthoritySetMember.Create(Reviewer, [AuthorityRole.FinalPlanReviewer]),
                    AuthoritySetMember.Create(Issuer, [AuthorityRole.GrantIssuer]),
                    AuthoritySetMember.Create(Executor, [AuthorityRole.Executor])],
                separations, [],
                [AuthorityApprovalPolicy.Create("evidence.read", [AuthorityRole.EnvelopeReviewer]),
                    AuthorityApprovalPolicy.Create("plan.sealed", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer]),
                    AuthorityApprovalPolicy.Create("report.sealed", [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer]),
                    AuthorityApprovalPolicy.Create("extension.transition", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer])],
                [JournalStoreReference.Parse(store)]);
        }
    }

    private sealed class FakePort : IExecutionAuthorityReadPort, IExecutionAuthorityMutationPort
    {
        private readonly Lock gate = new();
        private readonly ApprovalAuthoritySetSnapshot snapshot;
        private readonly AuthorityDigest head;
        private readonly TaskCompletionSource<bool> contenders =
            new(TaskCreationOptions.RunContinuationsAsynchronously);
        private readonly HashSet<AuthorityGrantId> consumedIds = [];
        private readonly HashSet<IdempotencyKey> consumedKeys = [];
        private int contenderCount;
        private int mutationCalls;
        internal FakePort(ApprovalAuthoritySetSnapshot snapshot,
            AuthorityDigest head, ExtensionActivationRecord current)
        {
            this.snapshot = snapshot; this.head = head; Current = current;
            CurrentAuthority = AuthoritySetBinding.From(snapshot); CurrentHead = head;
        }
        internal Fixture Fixture { get; set; } = null!;
        internal bool ReturnSnapshot { get; set; } = true;
        internal bool ReturnHead { get; set; } = true;
        internal bool ReturnRecord { get; set; } = true;
        internal bool CoordinateTwoContenders { get; set; }
        internal bool IsConsumed { get; set; }
        internal int Reads { get; private set; }
        internal int MutationCalls => mutationCalls;
        internal ExtensionActivationRecord Current { get; set; }
        internal AuthoritySetBinding CurrentAuthority { get; set; }
        internal AuthorityDigest CurrentHead { get; set; }
        public ValueTask<ApprovalAuthoritySetSnapshot?> ReadAuthoritySetAsync(
            AuthoritySetId id, CancellationToken cancellationToken)
        { Reads++; return ValueTask.FromResult<ApprovalAuthoritySetSnapshot?>(ReturnSnapshot ? snapshot : null); }
        public ValueTask<AuthorityDigest?> ReadGrantStoreHeadAsync(
            JournalStoreReference store, CancellationToken cancellationToken)
        { Reads++; return ValueTask.FromResult<AuthorityDigest?>(ReturnHead ? head : null); }
        public ValueTask<ExtensionActivationRecord?> ReadExtensionActivationAsync(
            ExecutionTarget repository, CancellationToken cancellationToken)
        { Reads++; return ValueTask.FromResult<ExtensionActivationRecord?>(ReturnRecord ? Current : null); }
        public ValueTask<ExecutionGrantDecision> TryConsumeGrantAsync(
            GrantConsumptionRequest request, CancellationToken cancellationToken) =>
            ValueTask.FromResult(ExecutionGrantDecision.Rejected(
                ExecutionGrantRejection.CapabilityMismatch));
        public async ValueTask<ActivationCasDecision> TryActivateExtensionAsync(
            ExtensionActivationMutationRequest request, CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref mutationCalls);
            bool replay; bool authorityDrift; bool headDrift;
            lock (gate)
            {
                replay = IsConsumed || consumedIds.Contains(request.Command.Grant.Id) ||
                    consumedKeys.Contains(request.Command.Grant.IdempotencyKey);
                authorityDrift = !request.ExpectedCurrentAuthoritySet.Equals(
                    CurrentAuthority);
                headDrift = !request.ExpectedGrantStoreHead.Equals(CurrentHead);
            }
            if (replay) return ActivationCasDecision.Rejected(ExecutionGrantRejection.Replayed);
            if (authorityDrift) return ActivationCasDecision.Rejected(ExecutionGrantRejection.SnapshotDrift);
            if (headDrift) return ActivationCasDecision.Rejected(ExecutionGrantRejection.GrantStoreDrift);
            if (CoordinateTwoContenders)
            {
                if (Interlocked.Increment(ref contenderCount) == 2) contenders.TrySetResult(true);
                await contenders.Task.ConfigureAwait(false);
            }
            lock (gate)
            {
                if (!Current.Equals(request.Command.ExpectedCurrent))
                    return ActivationCasDecision.Rejected(ExecutionGrantRejection.CasConflict);
                consumedIds.Add(request.Command.Grant.Id);
                consumedKeys.Add(request.Command.Grant.IdempotencyKey);
                Current = request.Command.Proposed;
                return ActivationCasDecision.Activated(Current);
            }
        }
    }

    private const string Commit = "0123456789abcdef0123456789abcdef01234567";
    private static AuthorityDigest Digest(char value) => AuthorityDigest.Parse(
        new string(value, 64));
}
