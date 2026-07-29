using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Protocol;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ExactGitRepositoryReaderTests
{
    [Fact]
    public async Task AuthorityCaptureUsesOnlyTheExactCommitTree()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        fixture.WritePolicyWorktreeVersion("9.9.9\n");
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.PolicyRoot,
            Limits());

        var capture = await port.CaptureSubjectAsync(
            Request(fixture.PolicyCommit),
            CancellationToken.None);

        Assert.Equal("exact-commit", capture.Snapshot.Mode);
        Assert.Equal(fixture.PolicyCommit, capture.SubjectCommit.Value);
        Assert.Equal(
            fixture.PolicyCommit,
            capture.Snapshot.SubjectCommit!.Value);
        Assert.Contains(
            capture.Snapshot.Entries,
            entry => entry.RelativePath ==
                "docs/features/FEAT-0001-example/README.md");
        Assert.True(capture.TryGetSelectedBlob("VERSION", out var version));
        Assert.Equal("0.17.0\n", Encoding.UTF8.GetString(version.Span));
    }

    [Fact]
    public async Task ExactSnapshotDigestBindsTheSubjectCommit()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.PolicyRoot,
            Limits());

        var first = await port.CaptureSubjectAsync(
            Request(fixture.PolicyCommit),
            CancellationToken.None);
        var second = await port.CaptureSubjectAsync(
            Request(fixture.PolicyLaterCommit),
            CancellationToken.None);

        Assert.NotEqual(
            first.Snapshot.EvidenceDigest,
            second.Snapshot.EvidenceDigest);
    }

    [Fact]
    public async Task ConsumerProviderReadsPinnedCommitInsteadOfCheckoutHead()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.ConsumerRoot,
            Limits());

        var version = await port.CaptureIntegratedPolicyVersionAsync(
            ExactGitCommitId.Parse(fixture.PolicyCommit),
            CancellationToken.None);

        Assert.True(version.IsAvailable);
        Assert.Equal(fixture.PolicyCommit, version.PolicyCommit.Value);
        Assert.Equal(
            "0.17.0\n",
            Encoding.UTF8.GetString(version.Content.Span));
        Assert.Equal(
            fixture.PolicyLaterCommit,
            fixture.GetIntegratedPolicyCheckoutCommit());
    }

    [Fact]
    public async Task PolicyVersionLookupDoesNotEnumerateThePolicyTree()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.ConsumerRoot,
            Limits(maximumTreeEntries: 1));

        var version = await port.CaptureIntegratedPolicyVersionAsync(
            ExactGitCommitId.Parse(fixture.PolicyCommit),
            CancellationToken.None);

        Assert.True(version.IsAvailable);
        Assert.Equal(
            "0.17.0\n",
            Encoding.UTF8.GetString(version.Content.Span));
    }

    [Fact]
    public async Task MissingIntegratedProviderIsCleanlyUnavailable()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        fixture.RemoveIntegratedPolicyWorktree();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.ConsumerRoot,
            Limits());

        var version = await port.CaptureIntegratedPolicyVersionAsync(
            ExactGitCommitId.Parse(fixture.PolicyCommit),
            CancellationToken.None);

        Assert.False(version.IsAvailable);
        Assert.True(version.Content.IsEmpty);
    }

    [Fact]
    public async Task MissingSubjectCommitIsAnAcquisitionFailure()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.PolicyRoot,
            Limits());

        await Assert.ThrowsAsync<OperationalDependencyException>(async () =>
            await port.CaptureSubjectAsync(
                Request(new string('0', 40)),
                CancellationToken.None));
    }

    [Fact]
    public async Task WrongTypeSubjectObjectIsAnAcquisitionFailure()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.PolicyRoot,
            Limits());

        await Assert.ThrowsAsync<OperationalDependencyException>(async () =>
            await port.CaptureSubjectAsync(
                Request(fixture.GetPolicyTreeObjectId()),
                CancellationToken.None));
    }

    [Fact]
    public async Task WrongTypeIntegratedPolicyObjectIsCleanlyUnavailable()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.ConsumerRoot,
            Limits());

        var version = await port.CaptureIntegratedPolicyVersionAsync(
            ExactGitCommitId.Parse(fixture.GetPolicyTreeObjectId()),
            CancellationToken.None);

        Assert.False(version.IsAvailable);
        Assert.True(version.Content.IsEmpty);
    }

    [Fact]
    public async Task CaptureHonorsPreCanceledTokens()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var port = new ExactGitGovernanceRepositorySnapshotPort(
            fixture.PolicyRoot,
            Limits());
        using var cancellation = new CancellationTokenSource();
        await cancellation.CancelAsync();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(async () =>
            await port.CaptureSubjectAsync(
                Request(fixture.PolicyCommit),
                cancellation.Token));
    }

    private static GovernanceRequest Request(
        string commit,
        GovernanceProfileId? profile = null) =>
        GovernanceRequest.Create(
            profile ?? GovernanceProfileId.ProtocolAuthority,
            ExactGitCommitId.Parse(commit));

    private static ExactRepositoryAcquisitionLimits Limits(
        int? maximumTreeEntries = null)
    {
        var current = BoundedGovernanceContract.InstructionGraph;
        if (maximumTreeEntries is null)
        {
            return ExactRepositoryAcquisitionLimits.From(current);
        }

        return ExactRepositoryAcquisitionLimits.From(
            InstructionGraphPolicyIdentity.Create(
                current.Schema,
                maximumTreeEntries.Value,
                current.MaximumAggregateTreePathUtf8Bytes,
                current.MaximumNodes,
                current.MaximumEdges,
                current.MaximumDepth,
                current.MaximumParsedBlobBytes,
                current.MaximumAggregateParsedBytes,
                current.MaximumGraphPathUtf8Bytes));
    }
}
