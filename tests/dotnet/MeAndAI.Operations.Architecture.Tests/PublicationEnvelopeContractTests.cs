using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class PublicationEnvelopeContractTests
{
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_envelope_binds_sealed_report_and_publication_grant()
    {
        Fixture fixture = new();
        PublicationGrantBinding binding = Fixture.PublicationBinding();
        ExecutionGrant grant = fixture.Grant(binding: binding);
        AuthorityDigest envelopeDigest = Digest('8');

        PublicationEnvelope envelope = PublicationEnvelope.Create(
            grant, envelopeDigest);

        Assert.Equal(binding.SealedReportDigest, envelope.SealedReportDigest);
        Assert.Equal(grant.Digest, envelope.PublicationGrantDigest);
        Assert.Equal(grant.AuthoritySet, envelope.AuthoritySet);
        Assert.Equal(binding.ProviderTarget, envelope.ProviderTarget);
        Assert.Equal(binding.IdempotencyKey, envelope.IdempotencyKey);
        Assert.Equal(binding.GateSnapshotIdentity, envelope.GateSnapshotIdentity);
        Assert.Equal(binding.ResultName, envelope.ResultName);
        Assert.Equal(binding.AllowedEffectIdentity, envelope.AllowedEffectIdentity);
        Assert.Equal(envelopeDigest, envelope.Digest);
        Assert.DoesNotContain(typeof(PublicationEnvelope),
            typeof(ExecutionGrant).GetProperties().Select(static value => value.PropertyType));
        Assert.DoesNotContain(typeof(PublicationEnvelope),
            typeof(PublicationGrantBinding).GetProperties().Select(static value => value.PropertyType));
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_envelope_rejects_nonpublication_or_disagreeing_grants()
    {
        Fixture fixture = new();
        PublicationGrantBinding binding = Fixture.PublicationBinding();
        AssertPublicationMismatch(fixture.Grant(
            capability: ExecutionCapability.RepositoryRead, binding: binding));
        AssertPublicationMismatch(fixture.Grant(binding: Fixture.PlanBinding()));

        PublicationGrantBinding wrongTarget = Fixture.PublicationBinding(
            target: ExecutionTarget.Create(
                "provider", "provider.other", "generation.one"));
        AssertPublicationMismatch(fixture.Grant(binding: wrongTarget));
        PublicationGrantBinding wrongKey = Fixture.PublicationBinding(
            key: IdempotencyKey.Parse("attempt.other"));
        AssertPublicationMismatch(fixture.Grant(binding: wrongKey));

        Assert.Equal("publicationGrant", Assert.Throws<ArgumentNullException>(() =>
            PublicationEnvelope.Create(null!, Digest('8'))).ParamName);
        Assert.Equal("digest", Assert.Throws<ArgumentNullException>(() =>
            PublicationEnvelope.Create(fixture.Grant(binding: binding), null!)).ParamName);
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_envelope_has_exact_value_equality()
    {
        Fixture fixture = new();
        PublicationEnvelope first = fixture.Envelope();
        PublicationEnvelope equivalent = fixture.Envelope();
        PublicationEnvelope[] different =
        [
            fixture.Envelope(reportDigest: 'a'),
            fixture.Envelope(grantDigest: 'a'),
            fixture.Envelope(authorityDigest: 'a'),
            fixture.Envelope(targetIdentity: "provider.other"),
            fixture.Envelope(keyValue: "attempt.other"),
            fixture.Envelope(gate: "gate snapshot 2"),
            fixture.Envelope(result: "result 2"),
            fixture.Envelope(effect: "effect.archive"),
            fixture.Envelope(envelopeDigest: 'a')
        ];

        Assert.Equal(first, equivalent);
        Assert.Equal(first.GetHashCode(), equivalent.GetHashCode());
        Assert.All(different, value => Assert.NotEqual(first, value));
        Assert.True(first.Equals((object)equivalent));
        Assert.False(first.Equals(new object()));
        Assert.False(first.Equals(null));
    }

    private static void AssertPublicationMismatch(ExecutionGrant grant) =>
        Assert.Equal("publicationGrant", Assert.Throws<ArgumentException>(() =>
            PublicationEnvelope.Create(grant, Digest('8'))).ParamName);

    private static AuthorityDigest Digest(char value) =>
        AuthorityDigest.Parse(new string(value, 64));

    private sealed class Fixture
    {
        private readonly AuthorityActorId proposal =
            AuthorityActorId.Parse("actor.proposal");
        private readonly AuthorityActorId envelope =
            AuthorityActorId.Parse("actor.envelope");
        private readonly AuthorityActorId final =
            AuthorityActorId.Parse("actor.final");
        private readonly AuthorityActorId issuer =
            AuthorityActorId.Parse("actor.issuer");
        private readonly AuthorityActorId executor =
            AuthorityActorId.Parse("actor.executor");
        private readonly GrantGeneration generation = GrantGeneration.Create(7);
        private readonly AuthoritySetBinding authoritySet;

        internal Fixture() => authoritySet = AuthoritySetBinding.From(Snapshot());

        internal static PublicationGrantBinding PublicationBinding(
            ExecutionTarget? target = null, IdempotencyKey? key = null,
            AuthorityDigest? reportDigest = null, string gate = "gate snapshot 1",
            string result = "result 1", string effect = "effect.publish") =>
            PublicationGrantBinding.Create(reportDigest ?? Digest('2'),
                target ?? ProviderTarget(), gate, result, effect,
                key ?? IdempotencyKey.Parse("attempt.one"),
                [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer],
                Digest('3'));

        internal static PlanGrantBinding PlanBinding() => PlanGrantBinding.Create(
            Digest('2'), new string('a', 40), new string('b', 40),
            new string('c', 40), ["src/a.cs"], [], "stage.apply",
            "effect.apply",
            [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer],
            Digest('3'));

        internal ExecutionGrant Grant(ExecutionCapability? capability = null,
            ExecutionGrantBinding? binding = null, ExecutionTarget? target = null,
            IdempotencyKey? key = null, AuthoritySetBinding? authority = null,
            AuthorityDigest? digest = null)
        {
            target ??= ProviderTarget();
            key ??= IdempotencyKey.Parse("attempt.one");
            return ExecutionGrant.Create(AuthorityGrantId.Parse("grant.publish"),
                authority ?? authoritySet,
                capability ?? ExecutionCapability.ReportPublish,
                ExecutionSubject.Create("worker", "subject.one"), target,
                AuthorityOperationId.Parse("operation.publish"), generation, key,
                issuer, executor,
                [
                    GrantApprovalEvidence.Create(envelope,
                        AuthorityRole.EnvelopeReviewer, Digest('4')),
                    GrantApprovalEvidence.Create(final,
                        AuthorityRole.FinalPlanReviewer, Digest('5'))
                ], binding ?? PublicationBinding(),
                JournalStoreReference.Parse("store.primary"),
                LeaseFenceBinding.Create(generation, "worker.one", "fence.one"),
                new DateTimeOffset(2026, 8, 14, 12, 0, 0, TimeSpan.Zero),
                new DateTimeOffset(2026, 8, 14, 12, 1, 0, TimeSpan.Zero),
                new DateTimeOffset(2026, 8, 14, 12, 5, 0, TimeSpan.Zero),
                digest ?? Digest('9'));
        }

        internal PublicationEnvelope Envelope(char reportDigest = '2',
            char grantDigest = '9', char authorityDigest = '1',
            string targetIdentity = "provider.primary",
            string keyValue = "attempt.one", string gate = "gate snapshot 1",
            string result = "result 1", string effect = "effect.publish",
            char envelopeDigest = '8')
        {
            ExecutionTarget target = ExecutionTarget.Create(
                "provider", targetIdentity, "generation.one");
            IdempotencyKey key = IdempotencyKey.Parse(keyValue);
            PublicationGrantBinding binding = PublicationBinding(target, key,
                Digest(reportDigest), gate, result, effect);
            ExecutionGrant grant = Grant(binding: binding, target: target,
                key: key, authority: AuthoritySetBinding.From(
                    Snapshot(authorityDigest)), digest: Digest(grantDigest));
            return PublicationEnvelope.Create(grant, Digest(envelopeDigest));
        }

        private ApprovalAuthoritySetSnapshot Snapshot(char digest = '1')
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
                AuthorityRevision.Create(7), AuthorityRevision.Create(3),
                Digest(digest),
                [
                    AuthoritySetMember.Create(proposal, [AuthorityRole.ProposalActor]),
                    AuthoritySetMember.Create(envelope, [AuthorityRole.EnvelopeReviewer]),
                    AuthoritySetMember.Create(final, [AuthorityRole.FinalPlanReviewer]),
                    AuthoritySetMember.Create(issuer, [AuthorityRole.GrantIssuer]),
                    AuthoritySetMember.Create(executor, [AuthorityRole.Executor])
                ], separations, [],
                [
                    AuthorityApprovalPolicy.Create("evidence.read", [AuthorityRole.EnvelopeReviewer]),
                    AuthorityApprovalPolicy.Create("plan.sealed", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer]),
                    AuthorityApprovalPolicy.Create("report.sealed", [AuthorityRole.EnvelopeReviewer, AuthorityRole.FinalPlanReviewer]),
                    AuthorityApprovalPolicy.Create("extension.transition", [AuthorityRole.ProposalActor, AuthorityRole.FinalPlanReviewer])
                ], [JournalStoreReference.Parse("store.primary")]);
        }

        private static ExecutionTarget ProviderTarget() => ExecutionTarget.Create(
            "provider", "provider.primary", "generation.one");
    }
}
