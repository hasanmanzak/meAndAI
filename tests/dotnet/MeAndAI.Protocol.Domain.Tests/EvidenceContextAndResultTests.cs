using System.Globalization;
using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class EvidenceContextAndResultTests
{
    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextClosesRequestAndMintsOneRootPerBinding()
    {
        var requirementA = EvidenceTestData.Requirement(
            "protocol.requirement.alpha");
        var requirementB = EvidenceTestData.Requirement(
            "protocol.requirement.zeta");
        var target = EvidenceTestData.Target();
        var request = AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementB, requirementA]);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var binding = EvidenceTestData.Binding(
            scope,
            requirementKeys: [requirementB.Key, requirementA.Key]);

        var context = EvidenceContext.Create(
            request,
            scope,
            [
                EvidenceTestData.RequirementAcquisition(requirementB),
                EvidenceTestData.RequirementAcquisition(requirementA),
            ],
            [binding],
            [],
            sourceObjectCount: 1);

        Assert.Equal(AcquisitionStatus.Complete, context.Status);
        Assert.Equal(
            [requirementA.Key, requirementB.Key],
            context.RequirementAcquisitions.Select(value =>
                value.Requirement.Key));
        var reference = Assert.Single(context.References);
        Assert.Equal(binding.Location.Scope, reference.Scope);
        Assert.Equal(binding.Payload.ContentDigest, reference.ContentDigest);
        Assert.Equal(binding.RequirementKeys, reference.RequirementKeys);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ZeroBindingContextCanBeStructurallyComplete()
    {
        var context = EvidenceTestData.Context(
            includeBinding: false,
            sourceObjectCount: 0);

        Assert.Equal(AcquisitionStatus.Complete, context.Status);
        Assert.Empty(context.Bindings);
        Assert.Empty(context.References);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextConsumesEachCollectionOnceAndOwnsCanonicalSnapshots()
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var acquisitionValues = new List<RequirementAcquisition>
        {
            EvidenceTestData.RequirementAcquisition(requirement),
        };
        var bindingValues = new List<EvidenceBinding>
        {
            EvidenceTestData.Binding(scope),
        };
        var pageValues = new List<AcquisitionPage>();
        var acquisitions = new SingleUseEnumerable<RequirementAcquisition>(
            acquisitionValues);
        var bindings = new SingleUseEnumerable<EvidenceBinding>(bindingValues);
        var pages = new SingleUseEnumerable<AcquisitionPage>(pageValues);

        var context = EvidenceContext.Create(
            request,
            scope,
            acquisitions,
            bindings,
            pages,
            sourceObjectCount: 0);
        acquisitionValues.Clear();
        bindingValues.Clear();

        Assert.Equal(1, acquisitions.EnumerationCount);
        Assert.Equal(1, bindings.EnumerationCount);
        Assert.Equal(1, pages.EnumerationCount);
        Assert.Single(context.RequirementAcquisitions);
        Assert.Single(context.Bindings);
        Assert.Single(context.References);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextAndResultFactoriesUseExactNullErrorCategories()
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var acquisition =
            EvidenceTestData.RequirementAcquisition(requirement);
        var binding = EvidenceTestData.Binding(scope);
        var failure = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.failed");

        Action[] requiredNullActions =
        [
            () => EvidenceContext.Create(
                null!, scope, [acquisition], [binding], [], 0),
            () => EvidenceContext.Create(
                request, null!, [acquisition], [binding], [], 0),
            () => EvidenceContext.Create(
                request, scope, null!, [binding], [], 0),
            () => EvidenceContext.Create(
                request, scope, [acquisition], null!, [], 0),
            () => EvidenceContext.Create(
                request, scope, [acquisition], [binding], null!, 0),
            () => ObservedAcquisitionResult.Create(null!),
            () => AbsentAcquisitionResult.Create(null!),
            () => FailedAcquisitionResult.Create(
                null!,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc,
                [failure]),
            () => FailedAcquisitionResult.Create(
                request,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc,
                null!),
        ];
        Assert.All(
            requiredNullActions,
            action => Assert.Throws<ArgumentNullException>(action));

        Action[] nullElementActions =
        [
            () => EvidenceContext.Create(
                request, scope, [null!], [binding], [], 0),
            () => EvidenceContext.Create(
                request, scope, [acquisition], [null!], [], 0),
            () => EvidenceContext.Create(
                request, scope, [acquisition], [binding], [null!], 0),
            () => FailedAcquisitionResult.Create(
                request,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc,
                [null!]),
        ];
        Assert.All(
            nullElementActions,
            action => Assert.Throws<ArgumentException>(action));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextRejectsCoverageScopeSchemaAndObservationConflicts()
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var acquisition = EvidenceTestData.RequirementAcquisition(requirement);
        var binding = EvidenceTestData.Binding(scope);

        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [],
            [binding],
            [],
            0));
        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [acquisition, acquisition],
            [binding],
            [],
            0));
        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [acquisition],
            [EvidenceTestData.Binding(
                EvidenceTestData.Scope(
                    SurfaceKind.Repository,
                    SnapshotKind.Candidate))],
            [],
            0));
        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [acquisition],
            [EvidenceTestData.Binding(
                scope,
                EvidenceTestData.Payload("protocol.schema.other"))],
            [],
            0));
        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [acquisition],
            [binding, binding],
            [],
            0));
        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [acquisition],
            [EvidenceTestData.Binding(
                scope,
                requirementKeys: ["protocol.requirement.foreign"])],
            [],
            0));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextValidatesCompleteAndInterruptedPageChains()
    {
        var cursorA = ExactSha256Digest.Parse(EvidenceTestData.Sha256C);
        var cursorB = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);
        var completePages = new[]
        {
            AcquisitionPage.Create(1, null, cursorA, 2),
            AcquisitionPage.Create(2, cursorA, null, 3),
        };
        var complete = EvidenceTestData.Context(
            pages: completePages,
            sourceObjectCount: 5);

        Assert.Equal(AcquisitionStatus.Complete, complete.Status);

        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var failure = AcquisitionFailure.Create(
            requirement.Key,
            "protocol.acquisition.interrupted");
        var incomplete = EvidenceContext.Create(
            request,
            scope,
            [RequirementAcquisition.Create(
                requirement,
                EvidenceConsistencyClass.ExactSnapshot,
                EvidenceRedaction.None,
                [failure])],
            [EvidenceTestData.Binding(scope)],
            [AcquisitionPage.Create(1, null, cursorB, 1)],
            1);

        Assert.Equal(AcquisitionStatus.Incomplete, incomplete.Status);
        Assert.Equal(cursorB, incomplete.Pages[0].NextCursorDigest);
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextRejectsMalformedPageChainsAndOverflow()
    {
        var cursorA = ExactSha256Digest.Parse(EvidenceTestData.Sha256C);
        var cursorB = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);

        Assert.Throws<ArgumentException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(1, cursorA, null, 1),
            ],
            sourceObjectCount: 1));
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(1, null, cursorA, 1),
                AcquisitionPage.Create(2, cursorB, null, 1),
            ],
            sourceObjectCount: 2));
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(1, null, null, 1),
            ],
            sourceObjectCount: 2));
        Assert.Throws<OverflowException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(1, null, cursorA, long.MaxValue),
                AcquisitionPage.Create(2, cursorA, null, 1),
            ],
            sourceObjectCount: long.MaxValue));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ResultUnionDerivesExactStatusAndLeafEquality()
    {
        var context = EvidenceTestData.Context();
        AcquisitionResult observed = ObservedAcquisitionResult.Create(context);
        AcquisitionResult absent =
            AbsentAcquisitionResult.Create(context.Request);
        var failure = AcquisitionFailure.Create(
            context.Request.RequestedRequirements[0].Key,
            "protocol.acquisition.source-failed");
        AcquisitionResult failed = FailedAcquisitionResult.Create(
            context.Request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc,
            [failure]);

        Assert.Equal(AcquisitionStatus.Complete, observed.Status);
        Assert.Equal(AcquisitionStatus.Incomplete, absent.Status);
        Assert.Equal(AcquisitionStatus.Failed, failed.Status);
        Assert.Equal(context, Assert.IsType<ObservedAcquisitionResult>(
            observed).Context);
        Assert.NotEqual(observed, absent);
        Assert.NotEqual(absent, failed);
        Assert.Equal(absent, AbsentAcquisitionResult.Create(context.Request));
        Assert.Equal(failed, FailedAcquisitionResult.Create(
            context.Request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc,
            [failure]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void FailedResultRequiresEveryAndOnlyRequestedRequirement()
    {
        var requirementA = EvidenceTestData.Requirement(
            "protocol.requirement.alpha");
        var requirementB = EvidenceTestData.Requirement(
            "protocol.requirement.zeta");
        var request = AcquisitionRequest.Create(
            EvidenceTestData.Target(),
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementA, requirementB]);
        var failureA = AcquisitionFailure.Create(
            requirementA.Key,
            "protocol.acquisition.failed");

        Assert.Throws<ArgumentException>(() =>
            FailedAcquisitionResult.Create(
                request,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc,
                [failureA]));
        Assert.Throws<ArgumentException>(() =>
            FailedAcquisitionResult.Create(
                request,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc,
                [
                    failureA,
                    AcquisitionFailure.Create(
                        "protocol.requirement.foreign",
                        "protocol.acquisition.failed"),
                ]));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            FailedAcquisitionResult.Create(
                request,
                EvidenceTestData.CompletedAtUtc,
                EvidenceTestData.StartedAtUtc,
                [
                    failureA,
                    AcquisitionFailure.Create(
                        requirementB.Key,
                        "protocol.acquisition.failed"),
                ]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void FailedResultOwnsCanonicalFailuresAndRejectsEqualDuplicates()
    {
        var requirementA = EvidenceTestData.Requirement(
            "protocol.requirement.alpha");
        var requirementB = EvidenceTestData.Requirement(
            "protocol.requirement.zeta");
        var request = AcquisitionRequest.Create(
            EvidenceTestData.Target(),
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementB, requirementA]);
        var failureAAlpha = AcquisitionFailure.Create(
            requirementA.Key,
            "protocol.acquisition.alpha");
        var failureAZeta = AcquisitionFailure.Create(
            requirementA.Key,
            "protocol.acquisition.zeta");
        var failureBBeta = AcquisitionFailure.Create(
            requirementB.Key,
            "protocol.acquisition.beta");
        var source = new List<AcquisitionFailure>
        {
            failureBBeta,
            failureAZeta,
            failureAAlpha,
        };
        var singleUse = new SingleUseEnumerable<AcquisitionFailure>(source);

        var result = FailedAcquisitionResult.Create(
            request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc,
            singleUse);
        source.Clear();

        Assert.Equal(1, singleUse.EnumerationCount);
        Assert.Equal(
            [
                "protocol.requirement.alpha|protocol.acquisition.alpha",
                "protocol.requirement.alpha|protocol.acquisition.zeta",
                "protocol.requirement.zeta|protocol.acquisition.beta",
            ],
            result.Failures.Select(failure =>
                $"{failure.RequirementKey}|{failure.Code}"));

        var equalButDistinctFailure = AcquisitionFailure.Create(
            failureAAlpha.RequirementKey,
            failureAAlpha.Code);
        Assert.NotSame(failureAAlpha, equalButDistinctFailure);
        Assert.Equal(failureAAlpha, equalButDistinctFailure);
        Assert.Throws<ArgumentException>(() =>
            FailedAcquisitionResult.Create(
                request,
                EvidenceTestData.StartedAtUtc,
                EvidenceTestData.CompletedAtUtc,
                [failureAAlpha, equalButDistinctFailure, failureBBeta]));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextRejectsDistinctEqualObservationsAndPreservesContentIdentity()
    {
        var requirementA = EvidenceTestData.Requirement(
            "protocol.requirement.alpha");
        var requirementB = EvidenceTestData.Requirement(
            "protocol.requirement.zeta");
        var target = EvidenceTestData.Target();
        var request = AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementA, requirementB]);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var firstLocation = SnapshotEvidenceLocation.Create(scope);
        var equalLocation = SnapshotEvidenceLocation.Create(scope);

        Assert.NotSame(firstLocation, equalLocation);
        Assert.Equal(firstLocation, equalLocation);

        var firstBinding = EvidenceBinding.Create(
            EvidenceTestData.Payload(bytes: [1]),
            firstLocation,
            [requirementA.Key],
            EvidenceTestData.StartedAtUtc);
        var conflictingBinding = EvidenceBinding.Create(
            EvidenceTestData.Payload(bytes: [2]),
            equalLocation,
            [requirementB.Key],
            EvidenceTestData.CompletedAtUtc);
        var acquisitions = new[]
        {
            EvidenceTestData.RequirementAcquisition(requirementA),
            EvidenceTestData.RequirementAcquisition(requirementB),
        };

        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            acquisitions,
            [firstBinding, conflictingBinding],
            [],
            1));

        var canonicalPayload = EvidenceTestData.Payload(bytes: [1, 2, 3]);
        var differentPayload = EvidenceTestData.Payload(bytes: [9, 8, 7]);
        Assert.NotEqual(
            canonicalPayload.ContentDigest,
            differentPayload.ContentDigest);
        Assert.NotEqual(canonicalPayload, differentPayload);

        var contentBindingA = EvidenceBinding.Create(
            canonicalPayload,
            RepositoryEvidenceLocation.Create(
                scope,
                "a.md",
                null,
                null,
                null,
                null),
            [requirementA.Key, requirementB.Key],
            EvidenceTestData.StartedAtUtc);
        var contentBindingB = EvidenceBinding.Create(
            differentPayload,
            RepositoryEvidenceLocation.Create(
                scope,
                "b.md",
                null,
                null,
                null,
                null),
            [requirementA.Key, requirementB.Key],
            EvidenceTestData.StartedAtUtc);

        var contentContext = EvidenceContext.Create(
            request,
            scope,
            acquisitions,
            [contentBindingA, contentBindingB],
            [],
            2);
        Assert.Equal(2, contentContext.Bindings.Count);
        Assert.Contains(
            contentContext.Bindings,
            binding => binding.Payload.ContentDigest.Equals(
                canonicalPayload.ContentDigest));
        Assert.Contains(
            contentContext.Bindings,
            binding => binding.Payload.ContentDigest.Equals(
                differentPayload.ContentDigest));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextCanonicalizesMultipleBindingsAndMatchingRootReferences()
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var payload = EvidenceTestData.Payload();
        var snapshotBinding = EvidenceBinding.Create(
            payload,
            SnapshotEvidenceLocation.Create(scope),
            [requirement.Key],
            EvidenceTestData.StartedAtUtc);
        var repositoryZ = EvidenceBinding.Create(
            payload,
            RepositoryEvidenceLocation.Create(
                scope,
                "z.md",
                null,
                null,
                null,
                null),
            [requirement.Key],
            EvidenceTestData.StartedAtUtc);
        var repositoryA = EvidenceBinding.Create(
            payload,
            RepositoryEvidenceLocation.Create(
                scope,
                "A.md",
                null,
                null,
                null,
                null),
            [requirement.Key],
            EvidenceTestData.StartedAtUtc);

        var context = EvidenceContext.Create(
            request,
            scope,
            [EvidenceTestData.RequirementAcquisition(requirement)],
            [snapshotBinding, repositoryZ, repositoryA],
            [],
            3);

        Assert.Equal(
            ["repository:A.md", "repository:z.md", "snapshot"],
            context.Bindings.Select(binding =>
                DescribeLocation(binding.Location)));
        Assert.Equal(
            context.Bindings.Select(binding => binding.Location),
            context.References.Select(reference => reference.Location));
        Assert.Equal(
            context.Bindings.Select(binding => binding.Payload.ContentDigest),
            context.References.Select(reference => reference.ContentDigest));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void PageInputsCanonicalizeAndRejectGapsReuseAndCycles()
    {
        var cursorA = ExactSha256Digest.Parse(EvidenceTestData.Sha256C);
        var cursorB = ExactSha256Digest.Parse(EvidenceTestData.Sha256D);
        var firstPage = AcquisitionPage.Create(1, null, cursorA, 1);
        var secondPage = AcquisitionPage.Create(2, cursorA, null, 1);

        var reversed = EvidenceTestData.Context(
            pages: [secondPage, firstPage],
            sourceObjectCount: 2);

        Assert.Equal([1, 2], reversed.Pages.Select(page => page.Sequence));
        Assert.Equal(AcquisitionStatus.Complete, reversed.Status);

        Assert.Throws<ArgumentException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(3, cursorA, null, 1),
                AcquisitionPage.Create(1, null, cursorA, 1),
            ],
            sourceObjectCount: 2));
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(1, null, cursorA, 0),
                AcquisitionPage.Create(2, cursorA, cursorA, 0),
                AcquisitionPage.Create(3, cursorA, null, 0),
            ],
            sourceObjectCount: 0));
        Assert.Throws<ArgumentException>(() => EvidenceTestData.Context(
            pages:
            [
                AcquisitionPage.Create(1, null, cursorA, 0),
                AcquisitionPage.Create(2, cursorA, cursorB, 0),
                AcquisitionPage.Create(3, cursorB, cursorA, 0),
                AcquisitionPage.Create(4, cursorA, null, 0),
            ],
            sourceObjectCount: 0));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void InterruptedMultiRequirementContextRequiresScopedFailures()
    {
        var requirementA = EvidenceTestData.Requirement(
            "protocol.requirement.alpha");
        var requirementB = EvidenceTestData.Requirement(
            "protocol.requirement.zeta");
        var target = EvidenceTestData.Target();
        var request = AcquisitionRequest.Create(
            target,
            "protocol.adapter.git",
            "1",
            "protocol.source.git-tree",
            "1",
            [requirementA, requirementB]);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var failureA = AcquisitionFailure.Create(
            requirementA.Key,
            "protocol.acquisition.interrupted");
        var failureB = AcquisitionFailure.Create(
            requirementB.Key,
            "protocol.acquisition.interrupted");
        var interruptedPage = AcquisitionPage.Create(
            1,
            null,
            ExactSha256Digest.Parse(EvidenceTestData.Sha256C),
            0);
        var acquisitionA = RequirementAcquisition.Create(
            requirementA,
            EvidenceConsistencyClass.ExactSnapshot,
            EvidenceRedaction.None,
            [failureA]);
        var acquisitionB = RequirementAcquisition.Create(
            requirementB,
            EvidenceConsistencyClass.ExactSnapshot,
            EvidenceRedaction.None,
            [failureB]);

        var context = EvidenceContext.Create(
            request,
            scope,
            [acquisitionB, acquisitionA],
            [],
            [interruptedPage],
            0);
        AcquisitionResult observed = ObservedAcquisitionResult.Create(context);
        AcquisitionResult equalObserved =
            ObservedAcquisitionResult.Create(context);

        Assert.Equal(AcquisitionStatus.Incomplete, context.Status);
        Assert.Equal(AcquisitionStatus.Incomplete, observed.Status);
        Assert.Equal(
            context,
            Assert.IsType<ObservedAcquisitionResult>(observed).Context);
        AssertEqualValuesHaveEqualHashes(observed, equalObserved);
        Assert.NotEqual(
            observed,
            AbsentAcquisitionResult.Create(request));

        var missingFailure = RequirementAcquisition.Create(
            requirementB,
            EvidenceConsistencyClass.InsufficientConsistency,
            EvidenceRedaction.None,
            []);
        Assert.Throws<ArgumentException>(() => EvidenceContext.Create(
            request,
            scope,
            [acquisitionA, missingFailure],
            [],
            [interruptedPage],
            0));
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void CanonicalOrderingIsCultureIndependent()
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var payload = EvidenceTestData.Payload();
        var bindingZ = EvidenceBinding.Create(
            payload,
            RepositoryEvidenceLocation.Create(
                scope,
                "Z.md",
                null,
                null,
                null,
                null),
            [requirement.Key],
            EvidenceTestData.StartedAtUtc);
        var bindingA = EvidenceBinding.Create(
            payload,
            RepositoryEvidenceLocation.Create(
                scope,
                "a.md",
                null,
                null,
                null,
                null),
            [requirement.Key],
            EvidenceTestData.StartedAtUtc);
        var acquisition = EvidenceTestData.RequirementAcquisition(requirement);
        var originalCulture = CultureInfo.CurrentCulture;
        var originalUiCulture = CultureInfo.CurrentUICulture;

        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR");
            CultureInfo.CurrentUICulture = CultureInfo.GetCultureInfo("tr-TR");
            var turkishContext = EvidenceContext.Create(
                request,
                scope,
                [acquisition],
                [bindingA, bindingZ],
                [],
                2);

            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("en-US");
            CultureInfo.CurrentUICulture = CultureInfo.GetCultureInfo("en-US");
            var englishContext = EvidenceContext.Create(
                request,
                scope,
                [acquisition],
                [bindingZ, bindingA],
                [],
                2);

            Assert.Equal(
                ["Z.md", "a.md"],
                turkishContext.Bindings.Select(binding =>
                    Assert.IsType<RepositoryEvidenceLocation>(
                        binding.Location).RepositoryRelativePath));
            AssertEqualValuesHaveEqualHashes(
                turkishContext,
                englishContext);
        }
        finally
        {
            CultureInfo.CurrentCulture = originalCulture;
            CultureInfo.CurrentUICulture = originalUiCulture;
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void ContextAndResultEqualityTrackSemanticFields()
    {
        var context = EvidenceTestData.Context();
        var equalContext = EvidenceTestData.Context();
        AssertEqualValuesHaveEqualHashes(context, equalContext);

        var contextMutations = new[]
        {
            EvidenceTestData.Context(includeBinding: false),
            EvidenceTestData.Context(sourceObjectCount: 1),
            EvidenceTestData.Context(
                pages: [AcquisitionPage.Create(1, null, null, 0)],
                sourceObjectCount: 0),
            CreateIncompleteContext(),
            CreateContextForSubject("other/subject"),
        };
        Assert.All(contextMutations, mutation =>
            Assert.NotEqual(context, mutation));

        AcquisitionResult observed = ObservedAcquisitionResult.Create(context);
        AcquisitionResult equalObserved =
            ObservedAcquisitionResult.Create(equalContext);
        AssertEqualValuesHaveEqualHashes(observed, equalObserved);
        Assert.NotEqual(
            observed,
            ObservedAcquisitionResult.Create(contextMutations[1]));

        AcquisitionResult absent =
            AbsentAcquisitionResult.Create(context.Request);
        AcquisitionResult equalAbsent =
            AbsentAcquisitionResult.Create(equalContext.Request);
        AssertEqualValuesHaveEqualHashes(absent, equalAbsent);
        Assert.NotEqual(
            absent,
            AbsentAcquisitionResult.Create(contextMutations[^1].Request));

        var failure = AcquisitionFailure.Create(
            context.Request.RequestedRequirements[0].Key,
            "protocol.acquisition.failed");
        AcquisitionResult failed = FailedAcquisitionResult.Create(
            context.Request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc,
            [failure]);
        AcquisitionResult equalFailed = FailedAcquisitionResult.Create(
            equalContext.Request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc,
            [failure]);
        AssertEqualValuesHaveEqualHashes(failed, equalFailed);
        Assert.NotEqual(failed, FailedAcquisitionResult.Create(
            context.Request,
            EvidenceTestData.StartedAtUtc.AddTicks(1),
            EvidenceTestData.CompletedAtUtc,
            [failure]));
        Assert.NotEqual(failed, FailedAcquisitionResult.Create(
            context.Request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc.AddTicks(1),
            [failure]));
        Assert.NotEqual(failed, FailedAcquisitionResult.Create(
            context.Request,
            EvidenceTestData.StartedAtUtc,
            EvidenceTestData.CompletedAtUtc,
            [AcquisitionFailure.Create(
                failure.RequirementKey,
                "protocol.acquisition.other-failure")]));
        Assert.NotEqual(observed, absent);
        Assert.NotEqual(absent, failed);
    }

    private static string DescribeLocation(EvidenceLocation location) =>
        location switch
        {
            RepositoryEvidenceLocation repository =>
                $"repository:{repository.RepositoryRelativePath}",
            SnapshotEvidenceLocation => "snapshot",
            _ => throw new InvalidOperationException(
                "The fixture uses only repository and snapshot locations."),
        };

    private static EvidenceContext CreateIncompleteContext()
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target();
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());
        var acquisition = RequirementAcquisition.Create(
            requirement,
            EvidenceConsistencyClass.InsufficientConsistency,
            EvidenceRedaction.None,
            []);

        return EvidenceContext.Create(
            request,
            scope,
            [acquisition],
            [],
            [],
            0);
    }

    private static EvidenceContext CreateContextForSubject(
        string subjectIdentity)
    {
        var requirement = EvidenceTestData.Requirement();
        var target = EvidenceTestData.Target(
            subjectIdentity: subjectIdentity);
        var request = EvidenceTestData.Request(requirement, target);
        var scope = EvidenceScope.Create(target, EvidenceTestData.Boundary());

        return EvidenceContext.Create(
            request,
            scope,
            [EvidenceTestData.RequirementAcquisition(requirement)],
            [EvidenceTestData.Binding(scope)],
            [],
            0);
    }

    private static void AssertEqualValuesHaveEqualHashes<T>(T left, T right)
        where T : notnull
    {
        Assert.Equal(left, right);
        Assert.Equal(left.GetHashCode(), right.GetHashCode());
    }
}
