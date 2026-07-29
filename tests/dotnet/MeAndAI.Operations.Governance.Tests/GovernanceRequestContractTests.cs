using System.Reflection;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceRequestContractTests
{
    private static readonly ExactGitCommitId SubjectCommit =
        ExactGitCommitId.Parse(
            "0123456789abcdef0123456789abcdef01234567");

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData("protocol-authority")]
    [InlineData("consumer")]
    public void PublicRequestFixesExactCommitRepositoryEvidence(string profileValue)
    {
        var profile = GovernanceProfileId.Parse(profileValue);

        var request = GovernanceRequest.Create(profile, SubjectCommit);

        Assert.Same(profile, request.Profile);
        Assert.Same(SubjectCommit, request.SubjectCommit);
        Assert.Same(RepositorySnapshotMode.ExactCommit, request.SnapshotMode);
        Assert.Same(EvidenceScope.Repository, request.EvidenceScope);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void PublicRequestSurfaceAcceptsOnlyProfileAndSubjectCommit()
    {
        Assert.Empty(typeof(GovernanceRequest).GetConstructors());

        var publicFactories = typeof(GovernanceRequest)
            .GetMethods(
                BindingFlags.Public |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly)
            .Where(method => !method.IsSpecialName)
            .ToArray();
        var factory = Assert.Single(publicFactories);

        Assert.Equal("Create", factory.Name);
        Assert.Equal(
            [typeof(GovernanceProfileId), typeof(ExactGitCommitId)],
            factory.GetParameters().Select(parameter => parameter.ParameterType));
        Assert.Equal(typeof(GovernanceRequest), factory.ReturnType);

        Assert.Equal(
            ["EvidenceScope", "Profile", "SnapshotMode", "SubjectCommit"],
            typeof(GovernanceRequest)
                .GetProperties(BindingFlags.Public | BindingFlags.Instance)
                .Select(property => property.Name)
                .Order(StringComparer.Ordinal));
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void PublicRequestRejectsNullCallerSelections()
    {
        Assert.Throws<ArgumentNullException>(() =>
            GovernanceRequest.Create(null!, SubjectCommit));
        Assert.Throws<ArgumentNullException>(() =>
            GovernanceRequest.Create(
                GovernanceProfileId.ProtocolAuthority,
                null!));
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void CandidateSnapshotModeIsNotPubliclySelectable()
    {
        Assert.Equal(
            ["ExactCommit"],
            typeof(RepositorySnapshotMode)
                .GetProperties(
                    BindingFlags.Public |
                    BindingFlags.Static |
                    BindingFlags.DeclaredOnly)
                .Select(property => property.Name)
                .Order(StringComparer.Ordinal));
        Assert.DoesNotContain(
            typeof(GovernanceEngine)
                .GetMethods(
                    BindingFlags.Public |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly),
            method => method.Name.Contains(
                "Candidate",
                StringComparison.Ordinal));
        Assert.DoesNotContain(
            typeof(GovernanceRepositorySnapshot)
                .GetMethods(
                    BindingFlags.Public |
                    BindingFlags.Static |
                    BindingFlags.DeclaredOnly),
            method => method.Name.Contains(
                "Candidate",
                StringComparison.Ordinal));
        Assert.False(typeof(IGovernanceRepositorySnapshotPort).IsPublic);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void InternalCandidateEvaluatorRejectsConsumerBeforeAnalysis()
    {
        var snapshot = GovernanceRepositorySnapshot.CreateCandidate([]);

        Assert.Throws<ArgumentOutOfRangeException>(() =>
            GovernanceEngine.CreateDefault().EvaluateCandidateShadow(
                GovernanceProfileId.Consumer,
                snapshot));
    }
}
