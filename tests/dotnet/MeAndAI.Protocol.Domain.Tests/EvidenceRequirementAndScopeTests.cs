using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class EvidenceRequirementAndScopeTests
{
    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ConsistencyClassHasTheExactClosedContract()
    {
        var expected = new[]
        {
            (EvidenceConsistencyClass.ExactSnapshot, "exact-snapshot"),
            (EvidenceConsistencyClass.ObjectVersionBound, "object-version-bound"),
            (EvidenceConsistencyClass.BoundedNonAtomicObservation,
                "bounded-non-atomic-observation"),
            (EvidenceConsistencyClass.InsufficientConsistency,
                "insufficient-consistency"),
        };

        foreach (var (value, token) in expected)
        {
            Assert.Equal(token, value.Value);
            Assert.Equal(token, value.ToString());
            Assert.Equal(value, EvidenceConsistencyClass.Parse(token));
            Assert.True(EvidenceConsistencyClass.TryParse(token, out var parsed));
            Assert.Equal(value, parsed);
            Assert.Equal(value.GetHashCode(), parsed.GetHashCode());
        }

        Assert.Throws<ArgumentNullException>(() =>
            EvidenceConsistencyClass.Parse(null!));
        foreach (var invalid in new string?[]
        {
            null,
            string.Empty,
            "Exact-Snapshot",
            " exact-snapshot",
            "exact-snapshot ",
            "unknown",
        })
        {
            Assert.False(EvidenceConsistencyClass.TryParse(invalid, out var parsed));
            Assert.Null(parsed);
            if (invalid is not null)
            {
                Assert.Throws<FormatException>(() =>
                    EvidenceConsistencyClass.Parse(invalid));
            }
        }

        for (var left = 0; left < expected.Length; left++)
        {
            for (var right = left + 1; right < expected.Length; right++)
            {
                Assert.NotEqual(expected[left].Item1, expected[right].Item1);
            }
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RequirementCanonicalizesAcceptedClassesAndOwnsItsInput()
    {
        var classes = new List<EvidenceConsistencyClass>
        {
            EvidenceConsistencyClass.BoundedNonAtomicObservation,
            EvidenceConsistencyClass.ExactSnapshot,
            EvidenceConsistencyClass.ObjectVersionBound,
        };
        var singleUse = new SingleUseEnumerable<EvidenceConsistencyClass>(classes);

        var requirement = EvidenceRequirement.Create(
            "protocol.requirement.repository-tree",
            SurfaceKind.Repository,
            "protocol.evidence.repository-tree",
            "protocol.completeness.exact",
            "protocol.schema.repository-tree",
            "1.0+release",
            singleUse);
        classes.Clear();

        Assert.Equal(1, singleUse.EnumerationCount);
        Assert.Equal(
            [
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceConsistencyClass.ObjectVersionBound,
                EvidenceConsistencyClass.BoundedNonAtomicObservation,
            ],
            requirement.AcceptedConsistencyClasses);
        Assert.Equal(requirement, EvidenceRequirement.Create(
            requirement.Key,
            requirement.Surface,
            requirement.Kind,
            requirement.CompletenessContract,
            requirement.PayloadSchemaKey,
            requirement.PayloadSchemaVersion,
            requirement.AcceptedConsistencyClasses.Reverse()));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RequirementRejectsInvalidOrInsufficientAcceptedClasses()
    {
        Assert.Throws<ArgumentException>(() =>
            EvidenceTestData.Requirement("not-namespaced"));
        Assert.Throws<ArgumentException>(() => EvidenceRequirement.Create(
            "protocol.requirement.valid",
            SurfaceKind.Repository,
            "protocol.kind.valid",
            "protocol.completeness.valid",
            "protocol.schema.valid",
            " bad",
            [EvidenceConsistencyClass.ExactSnapshot]));
        Assert.Throws<ArgumentException>(() => EvidenceRequirement.Create(
            "protocol.requirement.valid",
            SurfaceKind.Repository,
            "protocol.kind.valid",
            "protocol.completeness.valid",
            "protocol.schema.valid",
            "1",
            []));
        Assert.Throws<ArgumentException>(() => EvidenceRequirement.Create(
            "protocol.requirement.valid",
            SurfaceKind.Repository,
            "protocol.kind.valid",
            "protocol.completeness.valid",
            "protocol.schema.valid",
            "1",
            [
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceConsistencyClass.ExactSnapshot,
            ]));
        Assert.Throws<ArgumentException>(() => EvidenceRequirement.Create(
            "protocol.requirement.valid",
            SurfaceKind.Repository,
            "protocol.kind.valid",
            "protocol.completeness.valid",
            "protocol.schema.valid",
            "1",
            [EvidenceConsistencyClass.InsufficientConsistency]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void FoundationFactoriesUseTheExactNullErrorCategories()
    {
        var consistencyClasses = new[]
        {
            EvidenceConsistencyClass.ExactSnapshot,
        };
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var boundary = EvidenceTestData.Boundary();

        Action[] nullActions =
        [
            () => EvidenceRequirement.Create(
                null!, SurfaceKind.Repository, "protocol.kind.sample",
                "protocol.completeness.sample", "protocol.schema.sample", "1",
                consistencyClasses),
            () => EvidenceRequirement.Create(
                "protocol.requirement.sample", null!, "protocol.kind.sample",
                "protocol.completeness.sample", "protocol.schema.sample", "1",
                consistencyClasses),
            () => EvidenceRequirement.Create(
                "protocol.requirement.sample", SurfaceKind.Repository, null!,
                "protocol.completeness.sample", "protocol.schema.sample", "1",
                consistencyClasses),
            () => EvidenceRequirement.Create(
                "protocol.requirement.sample", SurfaceKind.Repository,
                "protocol.kind.sample", null!, "protocol.schema.sample", "1",
                consistencyClasses),
            () => EvidenceRequirement.Create(
                "protocol.requirement.sample", SurfaceKind.Repository,
                "protocol.kind.sample", "protocol.completeness.sample", null!,
                "1", consistencyClasses),
            () => EvidenceRequirement.Create(
                "protocol.requirement.sample", SurfaceKind.Repository,
                "protocol.kind.sample", "protocol.completeness.sample",
                "protocol.schema.sample", null!, consistencyClasses),
            () => EvidenceRequirement.Create(
                "protocol.requirement.sample", SurfaceKind.Repository,
                "protocol.kind.sample", "protocol.completeness.sample",
                "protocol.schema.sample", "1", null!),
            () => AcquisitionTarget.Create(
                null!, "source", SurfaceKind.Repository,
                SnapshotKind.ExactCommit, EvidenceTestData.GitObject40),
            () => AcquisitionTarget.Create(
                "subject", null!, SurfaceKind.Repository,
                SnapshotKind.ExactCommit, EvidenceTestData.GitObject40),
            () => AcquisitionTarget.Create(
                "subject", "source", null!, SnapshotKind.ExactCommit,
                EvidenceTestData.GitObject40),
            () => AcquisitionTarget.Create(
                "subject", "source", SurfaceKind.Repository, null!,
                EvidenceTestData.GitObject40),
            () => AcquisitionTarget.Create(
                "subject", "source", SurfaceKind.Repository,
                SnapshotKind.ExactCommit, null!),
            () => AcquisitionBoundary.Create(
                null!, EvidenceTestData.GitObject40,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc),
            () => AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit, null!,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc),
            () => EvidenceScope.Create(null!, boundary),
            () => EvidenceScope.Create(target, null!),
            () => AcquisitionRequest.Create(
                null!, "protocol.adapter.git", "1", "protocol.source.git", "1",
                [requirement]),
            () => AcquisitionRequest.Create(
                target, null!, "1", "protocol.source.git", "1", [requirement]),
            () => AcquisitionRequest.Create(
                target, "protocol.adapter.git", null!, "protocol.source.git", "1",
                [requirement]),
            () => AcquisitionRequest.Create(
                target, "protocol.adapter.git", "1", null!, "1", [requirement]),
            () => AcquisitionRequest.Create(
                target, "protocol.adapter.git", "1", "protocol.source.git", null!,
                [requirement]),
            () => AcquisitionRequest.Create(
                target, "protocol.adapter.git", "1", "protocol.source.git", "1",
                null!),
        ];

        Assert.All(
            nullActions,
            action => Assert.Throws<ArgumentNullException>(action));
        Assert.Throws<ArgumentException>(() => EvidenceRequirement.Create(
            "protocol.requirement.sample",
            SurfaceKind.Repository,
            "protocol.kind.sample",
            "protocol.completeness.sample",
            "protocol.schema.sample",
            "1",
            [null!]));
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git",
            "1",
            [null!]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void TokensVersionsAndOpaqueIdentitiesUseExactGrammarAndLengths()
    {
        var maximumToken = "a." + new string('b', 126);
        var overLengthToken = "a." + new string('b', 127);
        var maximumVersion = "V" + new string('1', 127);
        var overLengthVersion = "V" + new string('1', 128);
        var maximumIdentity = new string('i', 2048);
        var overLengthIdentity = new string('i', 2049);

        Assert.Equal(maximumToken, CreateRequirement(key: maximumToken).Key);
        Assert.Equal(
            maximumVersion,
            CreateRequirement(payloadSchemaVersion: maximumVersion)
                .PayloadSchemaVersion);
        Assert.Equal(
            maximumIdentity,
            AcquisitionTarget.Create(
                maximumIdentity,
                "source",
                SurfaceKind.Provider,
                SnapshotKind.ProviderEvent,
                maximumIdentity).SubjectIdentity);
        Assert.Equal(
            "V1.0+API_build",
            CreateRequirement(payloadSchemaVersion: "V1.0+API_build")
                .PayloadSchemaVersion);
        Assert.Equal(
            "subject/😀",
            AcquisitionTarget.Create(
                "subject/😀",
                "source",
                SurfaceKind.Repository,
                SnapshotKind.ExactCommit,
                EvidenceTestData.GitObject40).SubjectIdentity);

        foreach (var malformedToken in new[]
        {
            string.Empty,
            "ab",
            "A.b",
            "a.B",
            "a..b",
            "a.-b",
            "a.b-",
            "a.b--c",
            " a.b",
            "a.b ",
            "a_b.c",
            "a.é",
            "a.\0b",
        })
        {
            Assert.Throws<ArgumentException>(() =>
                CreateRequirement(key: malformedToken));
        }

        Assert.Throws<ArgumentException>(() =>
            CreateRequirement(kind: "Protocol.kind"));
        Assert.Throws<ArgumentException>(() =>
            CreateRequirement(completenessContract: " protocol.complete"));
        Assert.Throws<ArgumentException>(() =>
            CreateRequirement(payloadSchemaKey: "protocol.schema "));
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            EvidenceTestData.Target(),
            "Protocol.adapter",
            "1",
            "protocol.source.git",
            "1",
            [EvidenceTestData.Requirement()]));
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            EvidenceTestData.Target(),
            "protocol.adapter.git",
            "1",
            "protocol.source ",
            "1",
            [EvidenceTestData.Requirement()]));

        foreach (var malformedVersion in new[]
        {
            string.Empty,
            " version",
            "version ",
            "v1/preview",
            "v1:preview",
            "😀",
        })
        {
            Assert.Throws<ArgumentException>(() =>
                CreateRequirement(payloadSchemaVersion: malformedVersion));
        }

        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            EvidenceTestData.Target(),
            "protocol.adapter.git",
            "1/preview",
            "protocol.source.git",
            "1",
            [EvidenceTestData.Requirement()]));
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            EvidenceTestData.Target(),
            "protocol.adapter.git",
            "1",
            "protocol.source.git",
            "1/preview",
            [EvidenceTestData.Requirement()]));

        foreach (var malformedIdentity in new[]
        {
            " identity",
            "identity ",
            "identity\0value",
            "identity\u0001value",
            "\uD800",
        })
        {
            Assert.Throws<ArgumentException>(() => AcquisitionTarget.Create(
                malformedIdentity,
                "source",
                SurfaceKind.Provider,
                SnapshotKind.ProviderEvent,
                "delivery"));
        }

        Assert.Throws<ArgumentException>(() => AcquisitionTarget.Create(
            "subject",
            "source ",
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent,
            "delivery"));
        Assert.Throws<ArgumentException>(() => AcquisitionTarget.Create(
            "subject",
            "source",
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent,
            " delivery"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            CreateRequirement(key: overLengthToken));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            CreateRequirement(payloadSchemaVersion: overLengthVersion));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionTarget.Create(
                overLengthIdentity,
                "source",
                SurfaceKind.Provider,
                SnapshotKind.ProviderEvent,
                "delivery"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionTarget.Create(
                "subject",
                "source",
                SurfaceKind.Provider,
                SnapshotKind.ProviderEvent,
                overLengthIdentity));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void TargetAndBoundaryApplyEverySnapshotIdentityRule()
    {
        var cases = new[]
        {
            (SnapshotKind.ExactCommit,
                EvidenceTestData.GitObject40,
                EvidenceTestData.GitObject40),
            (SnapshotKind.Candidate,
                EvidenceTestData.Sha256C,
                EvidenceTestData.Sha256C),
            (SnapshotKind.ProviderEvent,
                "provider-delivery-1",
                EvidenceTestData.Sha256D),
            (SnapshotKind.ProviderFullInventory,
                "provider-plan-1",
                EvidenceTestData.Sha256D),
            (SnapshotKind.CapturedEvidence,
                EvidenceTestData.Sha256C,
                EvidenceTestData.Sha256C),
        };

        foreach (var (kind, targetIdentity, boundaryIdentity) in cases)
        {
            var target = EvidenceTestData.Target(
                snapshotKind: kind,
                subjectIdentity: "subject/repository",
                sourceIdentity: "source/repository",
                targetIdentity: targetIdentity);
            var boundary = EvidenceTestData.Boundary(
                kind,
                boundaryIdentity);
            var scope = EvidenceScope.Create(target, boundary);

            Assert.Equal(kind, scope.Target.SnapshotKind);
            Assert.Equal(kind, scope.Boundary.SnapshotKind);
            Assert.Equal("subject/repository", scope.Target.SubjectIdentity);
            Assert.Equal("source/repository", scope.Target.SourceIdentity);
        }

        var sameSubjectAndSource = AcquisitionTarget.Create(
            "same/repository",
            "same/repository",
            SurfaceKind.Repository,
            SnapshotKind.ExactCommit,
            EvidenceTestData.GitObject64);
        var exact64Scope = EvidenceScope.Create(
            sameSubjectAndSource,
            AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit,
                EvidenceTestData.GitObject64,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc));

        Assert.Equal(
            exact64Scope.Target.SubjectIdentity,
            exact64Scope.Target.SourceIdentity);
        Assert.Equal(
            EvidenceTestData.GitObject64,
            exact64Scope.Boundary.BoundaryIdentity);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void TargetBoundaryAndScopeRejectMismatchedOrUnsafeIdentity()
    {
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Target(
            snapshotKind: SnapshotKind.ExactCommit,
            targetIdentity: EvidenceTestData.Sha256C[..39]));
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Target(
            snapshotKind: SnapshotKind.Candidate,
            targetIdentity: EvidenceTestData.GitObject40));
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Target(
            snapshotKind: SnapshotKind.ProviderEvent,
            targetIdentity: " provider-delivery"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            AcquisitionBoundary.Create(
                SnapshotKind.ExactCommit,
                EvidenceTestData.GitObject40,
                EvidenceTestData.StartedAtUtc.ToOffset(TimeSpan.FromHours(1)),
                EvidenceTestData.CompletedAtUtc));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            EvidenceTestData.Boundary(
                completedAtUtc: EvidenceTestData.StartedAtUtc.AddTicks(-1)));

        var target = EvidenceTestData.Target();
        Assert.Throws<ArgumentException>(() => EvidenceScope.Create(
            target,
            EvidenceTestData.Boundary(
                SnapshotKind.ProviderEvent,
                EvidenceTestData.Sha256D)));
        Assert.Throws<ArgumentException>(() => EvidenceScope.Create(
            target,
            EvidenceTestData.Boundary(
                SnapshotKind.ExactCommit,
                EvidenceTestData.GitObject64)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RequestCanonicalizesRequirementsAndRejectsSurfaceOrKeyConflicts()
    {
        var target = EvidenceTestData.Target();
        var requirementB = EvidenceTestData.Requirement(
            "protocol.requirement.zeta");
        var requirementA = EvidenceTestData.Requirement(
            "protocol.requirement.alpha");
        var source = new List<EvidenceRequirement>
        {
            requirementB,
            requirementA,
        };
        var singleUse = new SingleUseEnumerable<EvidenceRequirement>(source);

        var request = AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1.0",
            "protocol.source.git-tree",
            "2026-01-01",
            singleUse);
        source.Clear();

        Assert.Equal(1, singleUse.EnumerationCount);
        Assert.Equal(
            [requirementA.Key, requirementB.Key],
            request.RequestedRequirements.Select(value => value.Key));
        Assert.Equal(request, AcquisitionRequest.Create(
            target,
            request.AdapterKey,
            request.AdapterContractVersion,
            request.SourceContractKey,
            request.SourceContractVersion,
            [requirementA, requirementB]));

        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            []));
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementA, requirementA]));
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [EvidenceTestData.Requirement(surface: SurfaceKind.Provider)]));

        var equalButDistinctRequirement = EvidenceRequirement.Create(
            requirementA.Key,
            requirementA.Surface,
            requirementA.Kind,
            requirementA.CompletenessContract,
            requirementA.PayloadSchemaKey,
            requirementA.PayloadSchemaVersion,
            requirementA.AcceptedConsistencyClasses);
        Assert.NotSame(requirementA, equalButDistinctRequirement);
        Assert.Equal(requirementA, equalButDistinctRequirement);
        Assert.Throws<ArgumentException>(() => AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementA, equalButDistinctRequirement]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void FoundationEqualityUsesEverySemanticField()
    {
        var requirement = CreateRequirement();
        AssertValueContract(
            requirement,
            CreateRequirement(),
            CreateRequirement(key: "protocol.requirement.other"),
            CreateRequirement(surface: SurfaceKind.Provider),
            CreateRequirement(kind: "protocol.kind.other"),
            CreateRequirement(
                completenessContract: "protocol.completeness.other"),
            CreateRequirement(payloadSchemaKey: "protocol.schema.other"),
            CreateRequirement(payloadSchemaVersion: "2"),
            CreateRequirement(
                acceptedConsistencyClasses:
                [EvidenceConsistencyClass.ObjectVersionBound]));

        var target = CreateTarget();
        AssertValueContract(
            target,
            CreateTarget(),
            CreateTarget(subjectIdentity: "subject/other"),
            CreateTarget(sourceIdentity: "source/other"),
            CreateTarget(surface: SurfaceKind.Provider),
            CreateTarget(
                snapshotKind: SnapshotKind.Candidate,
                targetIdentity: EvidenceTestData.Sha256C),
            CreateTarget(targetIdentity: EvidenceTestData.GitObject64));

        var boundary = CreateBoundary();
        AssertValueContract(
            boundary,
            CreateBoundary(),
            CreateBoundary(
                snapshotKind: SnapshotKind.Candidate,
                boundaryIdentity: EvidenceTestData.Sha256C),
            CreateBoundary(boundaryIdentity: EvidenceTestData.GitObject64),
            CreateBoundary(
                startedAtUtc: EvidenceTestData.StartedAtUtc.AddSeconds(1)),
            CreateBoundary(
                completedAtUtc: EvidenceTestData.CompletedAtUtc.AddSeconds(1)));

        var scope = EvidenceScope.Create(target, boundary);
        AssertValueContract(
            scope,
            EvidenceScope.Create(CreateTarget(), CreateBoundary()),
            EvidenceScope.Create(
                CreateTarget(subjectIdentity: "subject/other"),
                CreateBoundary()),
            EvidenceScope.Create(
                CreateTarget(),
                CreateBoundary(
                    completedAtUtc:
                    EvidenceTestData.CompletedAtUtc.AddSeconds(1))));

        var request = CreateRequest();
        AssertValueContract(
            request,
            CreateRequest(),
            CreateRequest(
                target: CreateTarget(subjectIdentity: "subject/other")),
            CreateRequest(adapterKey: "protocol.adapter.other"),
            CreateRequest(adapterContractVersion: "2"),
            CreateRequest(sourceContractKey: "protocol.source.other"),
            CreateRequest(sourceContractVersion: "2"),
            CreateRequest(
                requirements:
                [CreateRequirement(key: "protocol.requirement.other")]));
    }

    private static EvidenceRequirement CreateRequirement(
        string key = "protocol.requirement.sample",
        SurfaceKind? surface = null,
        string kind = "protocol.kind.sample",
        string completenessContract = "protocol.completeness.sample",
        string payloadSchemaKey = "protocol.schema.sample",
        string payloadSchemaVersion = "1",
        IEnumerable<EvidenceConsistencyClass>? acceptedConsistencyClasses = null) =>
        EvidenceRequirement.Create(
            key,
            surface ?? SurfaceKind.Repository,
            kind,
            completenessContract,
            payloadSchemaKey,
            payloadSchemaVersion,
            acceptedConsistencyClasses ??
                [EvidenceConsistencyClass.ExactSnapshot]);

    private static AcquisitionTarget CreateTarget(
        string subjectIdentity = "subject/repository",
        string sourceIdentity = "source/repository",
        SurfaceKind? surface = null,
        SnapshotKind? snapshotKind = null,
        string? targetIdentity = null)
    {
        var selectedSnapshotKind = snapshotKind ?? SnapshotKind.ExactCommit;
        return AcquisitionTarget.Create(
            subjectIdentity,
            sourceIdentity,
            surface ?? SurfaceKind.Repository,
            selectedSnapshotKind,
            targetIdentity ?? EvidenceTestData.GitObject40);
    }

    private static AcquisitionBoundary CreateBoundary(
        SnapshotKind? snapshotKind = null,
        string? boundaryIdentity = null,
        DateTimeOffset? startedAtUtc = null,
        DateTimeOffset? completedAtUtc = null) =>
        AcquisitionBoundary.Create(
            snapshotKind ?? SnapshotKind.ExactCommit,
            boundaryIdentity ?? EvidenceTestData.GitObject40,
            startedAtUtc ?? EvidenceTestData.StartedAtUtc,
            completedAtUtc ?? EvidenceTestData.CompletedAtUtc);

    private static AcquisitionRequest CreateRequest(
        AcquisitionTarget? target = null,
        string adapterKey = "protocol.adapter.git",
        string adapterContractVersion = "1",
        string sourceContractKey = "protocol.source.git",
        string sourceContractVersion = "1",
        IEnumerable<EvidenceRequirement>? requirements = null) =>
        AcquisitionRequest.Create(
            target ?? CreateTarget(),
            adapterKey,
            adapterContractVersion,
            sourceContractKey,
            sourceContractVersion,
            requirements ?? [CreateRequirement()]);

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
