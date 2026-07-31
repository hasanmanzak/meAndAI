using System.Reflection;
using System.Security.Cryptography;
using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class EvidenceLocationAndPayloadTests
{
    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void LocationUnionAcceptsEachExactLeaf()
    {
        var repositoryScope = EvidenceTestData.Scope();
        EvidenceLocation repository = RepositoryEvidenceLocation.Create(
            repositoryScope,
            "docs/features/README.md",
            EvidenceTestData.GitObject40,
            line: 12,
            anchor: null,
            property: null);

        var providerScope = EvidenceTestData.Scope(
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent);
        EvidenceLocation provider = ProviderEvidenceLocation.Create(
            providerScope,
            "github/installations/1",
            "provider.issue",
            "issue-42",
            "version-7",
            "body",
            line: 3,
            fragment: null);

        var releaseScope = EvidenceTestData.Scope(
            SurfaceKind.Release,
            SnapshotKind.CapturedEvidence);
        EvidenceLocation release = ReleaseAssetEvidenceLocation.Create(
            releaseScope,
            "release-1",
            "v1.0.0",
            "protocol.zip",
            ExactSha256Digest.Parse(EvidenceTestData.Sha256D));
        EvidenceLocation snapshot =
            SnapshotEvidenceLocation.Create(repositoryScope);

        Assert.IsType<RepositoryEvidenceLocation>(repository);
        Assert.IsType<ProviderEvidenceLocation>(provider);
        Assert.IsType<ReleaseAssetEvidenceLocation>(release);
        Assert.IsType<SnapshotEvidenceLocation>(snapshot);
        Assert.NotEqual(repository, snapshot);
        Assert.Equal(repository, RepositoryEvidenceLocation.Create(
            repositoryScope,
            "docs/features/README.md",
            EvidenceTestData.GitObject40,
            12,
            null,
            null));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RepositoryLocationRejectsInvalidSurfacePathAndRefinement()
    {
        var scope = EvidenceTestData.Scope();
        foreach (var path in new[]
        {
            string.Empty,
            "/absolute",
            "trailing/",
            "a//b",
            "a/./b",
            "a/../b",
            "a\\b",
            "C:/drive",
        })
        {
            Assert.Throws<ArgumentException>(() =>
                RepositoryEvidenceLocation.Create(
                    scope,
                    path,
                    null,
                    null,
                    null,
                    null));
        }

        Assert.Throws<ArgumentException>(() =>
            RepositoryEvidenceLocation.Create(
                EvidenceTestData.Scope(SurfaceKind.Provider,
                    SnapshotKind.ProviderEvent),
                "README.md",
                null,
                null,
                null,
                null));
        Assert.Throws<ArgumentException>(() =>
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                "not-a-git-id",
                null,
                null,
                null));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                null,
                0,
                null,
                null));
        Assert.Throws<ArgumentException>(() =>
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                null,
                1,
                "fragment",
                null));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ProviderAndReleaseLocationsEnforceTheirSurfaceAndRefinement()
    {
        var providerScope = EvidenceTestData.Scope(
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent);

        Assert.Throws<ArgumentException>(() =>
            ProviderEvidenceLocation.Create(
                EvidenceTestData.Scope(),
                "github/installations/1",
                "provider.issue",
                "issue-42",
                "version-7",
                null,
                null,
                null));
        Assert.Throws<ArgumentException>(() =>
            ProviderEvidenceLocation.Create(
                providerScope,
                "github/installations/1",
                "provider.issue",
                "issue-42",
                "version-7",
                null,
                1,
                null));
        Assert.Throws<ArgumentException>(() =>
            ProviderEvidenceLocation.Create(
                providerScope,
                "github/installations/1",
                "provider.issue",
                "issue-42",
                "version-7",
                "body",
                1,
                "fragment"));
        Assert.Throws<ArgumentException>(() =>
            ReleaseAssetEvidenceLocation.Create(
                providerScope,
                "release-1",
                "v1",
                "protocol.zip",
                ExactSha256Digest.Parse(EvidenceTestData.Sha256D)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void LocationPayloadAndBindingFactoriesUseExactValidationCategories()
    {
        var repositoryScope = EvidenceTestData.Scope();
        var providerScope = EvidenceTestData.Scope(
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent);
        var releaseScope = EvidenceTestData.Scope(
            SurfaceKind.Release,
            SnapshotKind.CapturedEvidence);
        var payload = EvidenceTestData.Payload();
        var location = SnapshotEvidenceLocation.Create(repositoryScope);
        var digest = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);

        Action[] requiredNullActions =
        [
            () => RepositoryEvidenceLocation.Create(
                null!, "README.md", null, null, null, null),
            () => RepositoryEvidenceLocation.Create(
                repositoryScope, null!, null, null, null, null),
            () => ProviderEvidenceLocation.Create(
                null!, "github", "provider.issue", "issue-1", "v1",
                null, null, null),
            () => ProviderEvidenceLocation.Create(
                providerScope, null!, "provider.issue", "issue-1", "v1",
                null, null, null),
            () => ProviderEvidenceLocation.Create(
                providerScope, "github", null!, "issue-1", "v1",
                null, null, null),
            () => ProviderEvidenceLocation.Create(
                providerScope, "github", "provider.issue", null!, "v1",
                null, null, null),
            () => ProviderEvidenceLocation.Create(
                providerScope, "github", "provider.issue", "issue-1", null!,
                null, null, null),
            () => ReleaseAssetEvidenceLocation.Create(
                null!, "release-1", "v1", "protocol.zip", digest),
            () => ReleaseAssetEvidenceLocation.Create(
                releaseScope, null!, "v1", "protocol.zip", digest),
            () => ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-1", null!, "protocol.zip", digest),
            () => ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-1", "v1", null!, digest),
            () => ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-1", "v1", "protocol.zip", null!),
            () => SnapshotEvidenceLocation.Create(null!),
            () => CanonicalEvidencePayload.Create(
                null!, "1", [1]),
            () => CanonicalEvidencePayload.Create(
                "protocol.schema.sample", null!, [1]),
            () => CanonicalEvidencePayload.Create(
                "protocol.schema.sample", "1", null!),
            () => EvidenceBinding.Create(
                null!, location, ["protocol.requirement.sample"],
                EvidenceTestData.StartedAtUtc),
            () => EvidenceBinding.Create(
                payload, null!, ["protocol.requirement.sample"],
                EvidenceTestData.StartedAtUtc),
            () => EvidenceBinding.Create(
                payload, location, null!, EvidenceTestData.StartedAtUtc),
        ];

        Assert.All(
            requiredNullActions,
            action => Assert.Throws<ArgumentNullException>(action));
        Assert.Throws<ArgumentException>(() => EvidenceBinding.Create(
            payload,
            location,
            [null!],
            EvidenceTestData.StartedAtUtc));

        Assert.Throws<ArgumentException>(() =>
            CanonicalEvidencePayload.Create(
                "Protocol.schema.sample",
                "1",
                [1]));
        Assert.Throws<ArgumentException>(() =>
            CanonicalEvidencePayload.Create(
                "protocol.schema.sample",
                "1/preview",
                [1]));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            CanonicalEvidencePayload.Create(
                "a." + new string('b', 127),
                "1",
                [1]));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            CanonicalEvidencePayload.Create(
                "protocol.schema.sample",
                "V" + new string('1', 128),
                [1]));
        var exactPayload = CanonicalEvidencePayload.Create(
            "protocol.schema.forward-compatible",
            "V1.0+API_build",
            [1]);
        Assert.Equal(
            "protocol.schema.forward-compatible",
            exactPayload.SchemaKey);
        Assert.Equal("V1.0+API_build", exactPayload.SchemaVersion);

        var maximumPath = new string('p', 4096);
        var overLengthPath = new string('p', 4097);
        var maximumRefinement = new string('r', 2048);
        var overLengthRefinement = new string('r', 2049);
        Assert.Equal(
            maximumPath,
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                maximumPath,
                null,
                null,
                null,
                null).RepositoryRelativePath);
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                overLengthPath,
                null,
                null,
                null,
                null));
        Assert.Equal(
            maximumRefinement,
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                "README.md",
                null,
                null,
                maximumRefinement,
                null).Anchor);
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                "README.md",
                null,
                null,
                overLengthRefinement,
                null));
        Assert.Equal(
            maximumRefinement,
            ProviderEvidenceLocation.Create(
                providerScope,
                "github",
                "provider.issue",
                "issue-1",
                "v1",
                "body",
                null,
                maximumRefinement).Fragment);
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            ProviderEvidenceLocation.Create(
                providerScope,
                "github",
                "provider.issue",
                "issue-1",
                "v1",
                "body",
                null,
                overLengthRefinement));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void CanonicalPayloadDerivesDigestAndDefensivelyOwnsBytes()
    {
        var bytes = new byte[] { 3, 1, 4, 1, 5 };
        var expectedDigest = ExactSha256Digest.FromHashBytes(
            SHA256.HashData(bytes));

        var singleUse = new SingleUseEnumerable<byte>(bytes);
        var payload = CanonicalEvidencePayload.Create(
            "protocol.schema.sample",
            "1.0",
            singleUse);
        var hashBeforeMutation = payload.GetHashCode();
        bytes[0] = 9;

        Assert.Equal(expectedDigest, payload.ContentDigest);
        Assert.Equal(1, singleUse.EnumerationCount);
        Assert.Equal([3, 1, 4, 1, 5], payload.CanonicalBytes);
        Assert.Equal(hashBeforeMutation, payload.GetHashCode());
        Assert.Equal(payload, CanonicalEvidencePayload.Create(
            payload.SchemaKey,
            payload.SchemaVersion,
            [3, 1, 4, 1, 5]));
        Assert.Empty(CanonicalEvidencePayload.Create(
            "protocol.schema.empty",
            "1",
            []).CanonicalBytes);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void BindingCanonicalizesKeysAndEnforcesScopeInterval()
    {
        var keys = new List<string>
        {
            "protocol.requirement.zeta",
            "protocol.requirement.alpha",
        };
        var singleUse = new SingleUseEnumerable<string>(keys);
        var binding = EvidenceBinding.Create(
            EvidenceTestData.Payload(),
            SnapshotEvidenceLocation.Create(EvidenceTestData.Scope()),
            singleUse,
            EvidenceTestData.StartedAtUtc);
        keys.Clear();

        Assert.Equal(1, singleUse.EnumerationCount);
        Assert.Equal(
            [
                "protocol.requirement.alpha",
                "protocol.requirement.zeta",
            ],
            binding.RequirementKeys);
        Assert.Throws<ArgumentException>(() => EvidenceBinding.Create(
            binding.Payload,
            binding.Location,
            [],
            binding.CapturedAtUtc));
        Assert.Throws<ArgumentException>(() => EvidenceBinding.Create(
            binding.Payload,
            binding.Location,
            [binding.RequirementKeys[0], binding.RequirementKeys[0]],
            binding.CapturedAtUtc));
        Assert.Throws<ArgumentOutOfRangeException>(() => EvidenceBinding.Create(
            binding.Payload,
            binding.Location,
            binding.RequirementKeys,
            EvidenceTestData.CompletedAtUtc.AddTicks(1)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void RootReferenceCanOnlyBeMintedByContext()
    {
        Assert.Empty(typeof(RootEvidenceReference).GetConstructors(
            BindingFlags.Public | BindingFlags.Instance));
        Assert.Empty(typeof(RootEvidenceReference).GetMethods(
            BindingFlags.Public |
            BindingFlags.Static |
            BindingFlags.DeclaredOnly));

        var context = EvidenceTestData.Context();
        var reference = Assert.Single(context.References);
        var binding = Assert.Single(context.Bindings);

        Assert.Equal(binding.Location.Scope, reference.Scope);
        Assert.Equal(binding.Payload.SchemaKey, reference.SchemaKey);
        Assert.Equal(binding.Payload.SchemaVersion, reference.SchemaVersion);
        Assert.Equal(binding.Payload.ContentDigest, reference.ContentDigest);
        Assert.Equal(binding.Location, reference.Location);
        Assert.Equal(binding.RequirementKeys, reference.RequirementKeys);
        Assert.Equal(binding.CapturedAtUtc, reference.CapturedAtUtc);
        Assert.DoesNotContain(
            typeof(RootEvidenceReference).GetProperties(),
            property => property.Name.Contains(
                "Byte",
                StringComparison.Ordinal));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void LocationsRejectUnsafeRefinementsAndPreserveExactAlternatives()
    {
        var repositoryScope = EvidenceTestData.Scope();
        var anchorLocation = RepositoryEvidenceLocation.Create(
            repositoryScope,
            "README.md",
            null,
            null,
            "section-one",
            null);
        var propertyLocation = RepositoryEvidenceLocation.Create(
            repositoryScope,
            "README.md",
            null,
            null,
            null,
            "title");

        Assert.Equal("section-one", anchorLocation.Anchor);
        Assert.Equal("title", propertyLocation.Property);
        Assert.NotEqual(anchorLocation, propertyLocation);

        Assert.Throws<ArgumentException>(() =>
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                "README.md",
                null,
                null,
                "section-one",
                "title"));
        Assert.Throws<ArgumentException>(() =>
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                "bad\uD800path",
                null,
                null,
                null,
                null));
        Assert.Throws<ArgumentException>(() =>
            RepositoryEvidenceLocation.Create(
                repositoryScope,
                "README.md",
                null,
                null,
                "bad\uD800anchor",
                null));

        var workflowScope = EvidenceTestData.Scope(
            SurfaceKind.Workflow,
            SnapshotKind.ProviderEvent);
        var fragmentLocation = ProviderEvidenceLocation.Create(
            workflowScope,
            "github/installations/1",
            "provider.workflow-run",
            "run-42",
            "version-7",
            "body",
            null,
            "job-1");

        Assert.Equal("job-1", fragmentLocation.Fragment);
        Assert.Throws<ArgumentException>(() =>
            ProviderEvidenceLocation.Create(
                workflowScope,
                "github/installations/1",
                "provider.workflow-run",
                "run-42",
                "version-7",
                null,
                null,
                "job-1"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            ProviderEvidenceLocation.Create(
                workflowScope,
                "github/installations/1",
                "provider.workflow-run",
                "run-42",
                "version-7",
                "body",
                0,
                null));
        Assert.Throws<ArgumentException>(() =>
            ProviderEvidenceLocation.Create(
                workflowScope,
                "github/installations/1",
                "provider.workflow-run",
                "run-42",
                "version-7",
                "bad\uD800field",
                null,
                null));

        Assert.Throws<ArgumentException>(() =>
            ReleaseAssetEvidenceLocation.Create(
                EvidenceTestData.Scope(
                    SurfaceKind.Release,
                    SnapshotKind.CapturedEvidence),
                "release-1",
                "v1",
                " protocol.zip",
                ExactSha256Digest.Parse(EvidenceTestData.Sha256D)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void LocationPayloadAndBindingEqualityTrackSemanticFields()
    {
        var scope = EvidenceTestData.Scope();
        var otherTarget = EvidenceTestData.Target(
            sourceIdentity: "example/other-source");
        var otherScope = EvidenceScope.Create(
            otherTarget,
            EvidenceTestData.Boundary());
        var location = RepositoryEvidenceLocation.Create(
            scope,
            "README.md",
            null,
            null,
            null,
            null);
        var equalLocation = RepositoryEvidenceLocation.Create(
            EvidenceTestData.Scope(),
            "README.md",
            null,
            null,
            null,
            null);

        AssertEqualValuesHaveEqualHashes<EvidenceLocation>(
            location,
            equalLocation);

        EvidenceLocation[] locationMutations =
        [
            RepositoryEvidenceLocation.Create(
                otherScope,
                "README.md",
                null,
                null,
                null,
                null),
            RepositoryEvidenceLocation.Create(
                scope,
                "PROTOCOL.md",
                null,
                null,
                null,
                null),
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                EvidenceTestData.GitObject40,
                null,
                null,
                null),
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                null,
                1,
                null,
                null),
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                null,
                null,
                "anchor",
                null),
            RepositoryEvidenceLocation.Create(
                scope,
                "README.md",
                null,
                null,
                null,
                "property"),
            SnapshotEvidenceLocation.Create(scope),
        ];

        Assert.All(locationMutations, mutation =>
            Assert.NotEqual<EvidenceLocation>(location, mutation));

        var payload = CanonicalEvidencePayload.Create(
            "protocol.schema.sample",
            "1",
            [1, 2, 3]);
        var equalPayload = CanonicalEvidencePayload.Create(
            "protocol.schema.sample",
            "1",
            [1, 2, 3]);
        AssertEqualValuesHaveEqualHashes(payload, equalPayload);
        Assert.NotEqual(payload, CanonicalEvidencePayload.Create(
            "protocol.schema.other",
            "1",
            [1, 2, 3]));
        Assert.NotEqual(payload, CanonicalEvidencePayload.Create(
            "protocol.schema.sample",
            "2",
            [1, 2, 3]));
        Assert.NotEqual(payload, CanonicalEvidencePayload.Create(
            "protocol.schema.sample",
            "1",
            [1, 2, 4]));

        var binding = EvidenceBinding.Create(
            payload,
            SnapshotEvidenceLocation.Create(scope),
            [
                "protocol.requirement.zeta",
                "protocol.requirement.alpha",
            ],
            EvidenceTestData.StartedAtUtc);
        var equalBinding = EvidenceBinding.Create(
            equalPayload,
            SnapshotEvidenceLocation.Create(EvidenceTestData.Scope()),
            [
                "protocol.requirement.alpha",
                "protocol.requirement.zeta",
            ],
            EvidenceTestData.StartedAtUtc);
        AssertEqualValuesHaveEqualHashes(binding, equalBinding);

        Assert.NotEqual(binding, EvidenceBinding.Create(
            CanonicalEvidencePayload.Create(
                payload.SchemaKey,
                payload.SchemaVersion,
                [9]),
            binding.Location,
            binding.RequirementKeys,
            binding.CapturedAtUtc));
        Assert.NotEqual(binding, EvidenceBinding.Create(
            payload,
            location,
            binding.RequirementKeys,
            binding.CapturedAtUtc));
        Assert.NotEqual(binding, EvidenceBinding.Create(
            payload,
            binding.Location,
            ["protocol.requirement.alpha"],
            binding.CapturedAtUtc));
        Assert.NotEqual(binding, EvidenceBinding.Create(
            payload,
            binding.Location,
            binding.RequirementKeys,
            binding.CapturedAtUtc.AddTicks(1)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ProviderReleaseSnapshotAndRootEqualityTrackSemanticFields()
    {
        var providerScope = EvidenceTestData.Scope(
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent);
        var providerTargetWithOtherSource = EvidenceTestData.Target(
            SurfaceKind.Provider,
            SnapshotKind.ProviderEvent,
            sourceIdentity: "example/other-source");
        var otherProviderScope = EvidenceScope.Create(
            providerTargetWithOtherSource,
            EvidenceTestData.Boundary(SnapshotKind.ProviderEvent));
        var provider = ProviderEvidenceLocation.Create(
            providerScope,
            "github/installations/1",
            "provider.issue",
            "issue-42",
            "version-7",
            "body",
            null,
            null);
        AssertEqualValuesHaveEqualHashes<EvidenceLocation>(
            provider,
            ProviderEvidenceLocation.Create(
                EvidenceTestData.Scope(
                    SurfaceKind.Provider,
                    SnapshotKind.ProviderEvent),
                "github/installations/1",
                "provider.issue",
                "issue-42",
                "version-7",
                "body",
                null,
                null));
        EvidenceLocation[] providerMutations =
        [
            ProviderEvidenceLocation.Create(
                otherProviderScope, "github/installations/1",
                "provider.issue", "issue-42", "version-7", "body",
                null, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/2", "provider.issue",
                "issue-42", "version-7", "body", null, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/1",
                "provider.pull-request", "issue-42", "version-7", "body",
                null, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/1", "provider.issue",
                "issue-43", "version-7", "body", null, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/1", "provider.issue",
                "issue-42", "version-8", "body", null, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/1", "provider.issue",
                "issue-42", "version-7", "title", null, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/1", "provider.issue",
                "issue-42", "version-7", "body", 1, null),
            ProviderEvidenceLocation.Create(
                providerScope, "github/installations/1", "provider.issue",
                "issue-42", "version-7", "body", null, "fragment"),
        ];
        Assert.All(providerMutations, mutation =>
            Assert.NotEqual<EvidenceLocation>(provider, mutation));

        var releaseScope = EvidenceTestData.Scope(
            SurfaceKind.Release,
            SnapshotKind.CapturedEvidence);
        var releaseTargetWithOtherSource = EvidenceTestData.Target(
            SurfaceKind.Release,
            SnapshotKind.CapturedEvidence,
            sourceIdentity: "example/other-source");
        var otherReleaseScope = EvidenceScope.Create(
            releaseTargetWithOtherSource,
            EvidenceTestData.Boundary(SnapshotKind.CapturedEvidence));
        var digest = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);
        var release = ReleaseAssetEvidenceLocation.Create(
            releaseScope,
            "release-1",
            "v1",
            "protocol.zip",
            digest);
        AssertEqualValuesHaveEqualHashes<EvidenceLocation>(
            release,
            ReleaseAssetEvidenceLocation.Create(
                EvidenceTestData.Scope(
                    SurfaceKind.Release,
                    SnapshotKind.CapturedEvidence),
                "release-1",
                "v1",
                "protocol.zip",
                digest));
        EvidenceLocation[] releaseMutations =
        [
            ReleaseAssetEvidenceLocation.Create(
                otherReleaseScope, "release-1", "v1", "protocol.zip",
                digest),
            ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-2", "v1", "protocol.zip", digest),
            ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-1", "v2", "protocol.zip", digest),
            ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-1", "v1", "protocol.tar", digest),
            ReleaseAssetEvidenceLocation.Create(
                releaseScope, "release-1", "v1", "protocol.zip",
                ExactSha256Digest.Parse(EvidenceTestData.Sha256C)),
        ];
        Assert.All(releaseMutations, mutation =>
            Assert.NotEqual<EvidenceLocation>(release, mutation));

        EvidenceLocation snapshot = SnapshotEvidenceLocation.Create(
            EvidenceTestData.Scope());
        AssertEqualValuesHaveEqualHashes(
            snapshot,
            SnapshotEvidenceLocation.Create(EvidenceTestData.Scope()));
        Assert.NotEqual<EvidenceLocation>(
            snapshot,
            SnapshotEvidenceLocation.Create(EvidenceScope.Create(
                EvidenceTestData.Target(
                    sourceIdentity: "example/other-source"),
                EvidenceTestData.Boundary())));

        var root = CreateRootReference();
        AssertEqualValuesHaveEqualHashes(root, CreateRootReference());
        Assert.Equal(root.Scope, root.Location.Scope);
        var rootMutations = new[]
        {
            CreateRootReference(sourceIdentity: "example/other-source"),
            CreateRootReference(schemaKey: "protocol.schema.other"),
            CreateRootReference(schemaVersion: "2"),
            CreateRootReference(canonicalBytes: [9, 8, 7]),
            CreateRootReference(repositoryRelativePath: "README.md"),
            CreateRootReference(
                requirementKey: "protocol.requirement.other"),
            CreateRootReference(
                capturedAtUtc: EvidenceTestData.StartedAtUtc.AddTicks(1)),
        };
        Assert.All(rootMutations, mutation => Assert.NotEqual(root, mutation));
    }

    private static RootEvidenceReference CreateRootReference(
        string sourceIdentity = "example/source",
        string schemaKey = "protocol.schema.repository-tree",
        string schemaVersion = "1.0",
        IEnumerable<byte>? canonicalBytes = null,
        string? repositoryRelativePath = null,
        string requirementKey = "protocol.requirement.repository-tree",
        DateTimeOffset? capturedAtUtc = null)
    {
        var requirement = EvidenceTestData.Requirement(
            requirementKey,
            schemaKey: schemaKey,
            schemaVersion: schemaVersion);
        var target = EvidenceTestData.Target(sourceIdentity: sourceIdentity);
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        EvidenceLocation location = repositoryRelativePath is null
            ? SnapshotEvidenceLocation.Create(scope)
            : RepositoryEvidenceLocation.Create(
                scope,
                repositoryRelativePath,
                null,
                null,
                null,
                null);
        var payload = CanonicalEvidencePayload.Create(
            schemaKey,
            schemaVersion,
            canonicalBytes ?? [1, 2, 3]);
        var binding = EvidenceBinding.Create(
            payload,
            location,
            [requirement.Key],
            capturedAtUtc ?? EvidenceTestData.StartedAtUtc);
        var context = EvidenceContext.Create(
            request,
            scope,
            [EvidenceTestData.RequirementAcquisition(requirement)],
            [binding],
            [],
            0);

        return Assert.Single(context.References);
    }

    private static void AssertEqualValuesHaveEqualHashes<T>(T left, T right)
        where T : notnull
    {
        Assert.Equal(left, right);
        Assert.Equal(left.GetHashCode(), right.GetHashCode());
    }
}
