using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class EvidenceAcquisitionStateTests
{
    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void FailureAndRedactionRetainOnlyScopedStructuralFacts()
    {
        var failure = AcquisitionFailure.Create(
            "protocol.requirement.repository-tree",
            "protocol.acquisition.payload-malformed");

        Assert.Equal(
            "protocol.requirement.repository-tree",
            failure.RequirementKey);
        Assert.Equal(
            "protocol.acquisition.payload-malformed",
            failure.Code);
        Assert.Equal(failure, AcquisitionFailure.Create(
            failure.RequirementKey,
            failure.Code));
        Assert.Throws<ArgumentException>(() =>
            AcquisitionFailure.Create("not-namespaced", failure.Code));
        Assert.Throws<ArgumentException>(() =>
            AcquisitionFailure.Create(failure.RequirementKey, "HTTP 500"));

        Assert.False(EvidenceRedaction.None.RequiredValuesOmitted);
        Assert.False(EvidenceRedaction.None.NonRequiredValuesOmitted);
        Assert.Equal(EvidenceRedaction.None, EvidenceRedaction.Create(
            requiredValuesOmitted: false,
            nonRequiredValuesOmitted: false));
        Assert.NotEqual(EvidenceRedaction.None, EvidenceRedaction.Create(
            requiredValuesOmitted: false,
            nonRequiredValuesOmitted: true));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void StateFactoriesUseExactNullLexicalAndLengthErrors()
    {
        var requirement = EvidenceTestData.Requirement();
        var failure = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.failed");

        Assert.Throws<ArgumentNullException>(() =>
            AcquisitionFailure.Create(null!, failure.Code));
        Assert.Throws<ArgumentNullException>(() =>
            AcquisitionFailure.Create(requirement.Key, null!));
        Assert.Throws<ArgumentNullException>(() =>
            RequirementAcquisition.Create(
                null!,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                []));
        Assert.Throws<ArgumentNullException>(() =>
            RequirementAcquisition.Create(
                requirement,
                null!,
                EvidenceRedaction.None,
                []));
        Assert.Throws<ArgumentNullException>(() =>
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                null!,
                []));
        Assert.Throws<ArgumentNullException>(() =>
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                null!));
        Assert.Throws<ArgumentException>(() =>
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [null!]));

        foreach (var malformed in new[]
        {
            "Protocol.acquisition.failed",
            "protocol.Acquisition.failed",
            " protocol.acquisition.failed",
            "protocol.acquisition.failed ",
            "protocol..failed",
            "protocol.acquisition--failed",
            "protocol.acquisition.é",
            "protocol.acquisition.\0failed",
        })
        {
            Assert.Throws<ArgumentException>(() =>
                AcquisitionFailure.Create(requirement.Key, malformed));
        }

        Assert.Throws<ArgumentException>(() => AcquisitionFailure.Create(
            " Protocol.requirement",
            "protocol.acquisition.failed"));

        var maximumToken = "a." + new string('b', 126);
        var overLengthToken = "a." + new string('b', 127);
        Assert.Equal(
            maximumToken,
            AcquisitionFailure.Create(maximumToken, maximumToken).Code);
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionFailure.Create(
                overLengthToken,
                "protocol.acquisition.failed"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionFailure.Create(requirement.Key, overLengthToken));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RequirementAcquisitionDerivesStatusWithoutCallerInput()
    {
        var requirement = EvidenceRequirement.Create(
            "protocol.requirement.sample",
            SurfaceKind.Repository,
            "protocol.kind.sample",
            "protocol.completeness.sample",
            "protocol.schema.sample",
            "1",
            [
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceConsistencyClass.ObjectVersionBound,
            ]);

        Assert.Equal(AcquisitionStatus.Complete,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                []).Status);
        Assert.Equal(AcquisitionStatus.Complete,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ObjectVersionBound,
                EvidenceRedaction.Create(false, true),
                []).Status);
        Assert.Equal(AcquisitionStatus.Incomplete,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.BoundedNonAtomicObservation,
                EvidenceRedaction.None,
                []).Status);
        Assert.Equal(AcquisitionStatus.Incomplete,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.InsufficientConsistency,
                EvidenceRedaction.None,
                []).Status);
        Assert.Equal(AcquisitionStatus.Incomplete,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.Create(true, false),
                []).Status);
        Assert.Equal(AcquisitionStatus.Incomplete,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [AcquisitionFailure.Create(
                    requirement.Key,
                    "protocol.acquisition.incomplete")]).Status);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RequirementAcquisitionRejectsForeignOrDuplicateFailures()
    {
        var requirement = EvidenceTestData.Requirement();
        var failure = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.incomplete");

        Assert.Throws<ArgumentException>(() =>
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [AcquisitionFailure.Create(
                    "protocol.requirement.foreign",
                    failure.Code)]));
        Assert.Throws<ArgumentException>(() =>
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [failure, failure]));

        var equalButDistinctFailure = AcquisitionFailure.Create(
            failure.RequirementKey,
            failure.Code);
        Assert.NotSame(failure, equalButDistinctFailure);
        Assert.Equal(failure, equalButDistinctFailure);
        Assert.Throws<ArgumentException>(() =>
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [failure, equalButDistinctFailure]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RequirementAcquisitionOwnsAndCanonicallyOrdersFailures()
    {
        var requirement = EvidenceTestData.Requirement();
        var failureZeta = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.zeta");
        var failureAlpha = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.alpha");
        var source = new List<AcquisitionFailure>
        {
            failureZeta,
            failureAlpha,
        };
        var singleUse = new SingleUseEnumerable<AcquisitionFailure>(source);

        var acquisition = RequirementAcquisition.Create(
            requirement,
            EvidenceConsistencyClass.ExactSnapshot,
            EvidenceRedaction.None,
            singleUse);
        source.Clear();

        Assert.Equal(1, singleUse.EnumerationCount);
        Assert.Equal(
            ["protocol.acquisition.alpha", "protocol.acquisition.zeta"],
            acquisition.Failures.Select(value => value.Code));
        Assert.Equal(AcquisitionStatus.Incomplete, acquisition.Status);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void AcquisitionPageRetainsOnlyDigestsAndCounts()
    {
        var requestCursor = ExactSha256Digest.Parse(EvidenceTestData.Sha256C);
        var nextCursor = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);
        var page = AcquisitionPage.Create(
            sequence: 2,
            requestCursor,
            nextCursor,
            sourceObjectCount: 12);

        Assert.Equal(2, page.Sequence);
        Assert.Equal(requestCursor, page.RequestCursorDigest);
        Assert.Equal(nextCursor, page.NextCursorDigest);
        Assert.Equal(12, page.SourceObjectCount);
        Assert.Equal(page, AcquisitionPage.Create(
            2,
            requestCursor,
            nextCursor,
            12));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionPage.Create(0, null, null, 0));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionPage.Create(1, null, null, -1));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void StateEqualityUsesEverySemanticField()
    {
        var requirement = EvidenceRequirement.Create(
            "protocol.requirement.sample",
            SurfaceKind.Repository,
            "protocol.kind.sample",
            "protocol.completeness.sample",
            "protocol.schema.sample",
            "1",
            [
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceConsistencyClass.ObjectVersionBound,
            ]);
        var failure = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.failed");
        AssertValueContract(
            failure,
            AcquisitionFailure.Create(failure.RequirementKey, failure.Code),
            AcquisitionFailure.Create(
                "protocol.requirement.other",
                failure.Code),
            AcquisitionFailure.Create(
                failure.RequirementKey,
                "protocol.acquisition.other"));

        AssertValueContract(
            EvidenceRedaction.None,
            EvidenceRedaction.Create(false, false),
            EvidenceRedaction.Create(false, true),
            EvidenceRedaction.Create(true, false),
            EvidenceRedaction.Create(true, true));

        var acquisition = RequirementAcquisition.Create(
            requirement,
            EvidenceConsistencyClass.ExactSnapshot,
            EvidenceRedaction.None,
            []);
        AssertValueContract(
            acquisition,
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                []),
            RequirementAcquisition.Create(
                EvidenceTestData.Requirement(
                    "protocol.requirement.other"),
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                []),
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ObjectVersionBound,
                EvidenceRedaction.None,
                []),
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.Create(false, true),
                []),
            RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [failure]));

        var requestCursor = ExactSha256Digest.Parse(EvidenceTestData.Sha256C);
        var nextCursor = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);
        var page = AcquisitionPage.Create(2, requestCursor, nextCursor, 12);
        AssertValueContract(
            page,
            AcquisitionPage.Create(2, requestCursor, nextCursor, 12),
            AcquisitionPage.Create(3, requestCursor, nextCursor, 12),
            AcquisitionPage.Create(2, null, nextCursor, 12),
            AcquisitionPage.Create(2, requestCursor, null, 12),
            AcquisitionPage.Create(2, requestCursor, nextCursor, 13));
    }

    private static void AssertValueContract<T>(
        T value,
        T equal,
        params T[] unequal)
        where T : class
    {
        Assert.Equal(value, equal);
        Assert.True(value.Equals(equal));
        Assert.True(equal.Equals(value));
        Assert.Equal(value.GetHashCode(), equal.GetHashCode());
        Assert.All(unequal, candidate =>
        {
            Assert.NotEqual(value, candidate);
            Assert.False(value.Equals(candidate));
            Assert.False(candidate.Equals(value));
        });
    }
}
