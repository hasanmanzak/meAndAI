using System.Reflection;
using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class ExecutionProfileTests
{
    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void AllStructuralAxisCombinationsAreConstructibleAndRetained()
    {
        var subjectRoles = new[]
        {
            SubjectRole.ProtocolAuthoritySelfConsumer,
            SubjectRole.Consumer,
        };
        var operations = new[]
        {
            ProtocolOperation.Conformance,
            ProtocolOperation.AdoptionAssessment,
            ProtocolOperation.AdoptionPlan,
            ProtocolOperation.AdoptionApply,
            ProtocolOperation.UpdateAssessment,
            ProtocolOperation.UpdatePlan,
            ProtocolOperation.UpdateApply,
            ProtocolOperation.Publication,
            ProtocolOperation.Finalization,
            ProtocolOperation.Recovery,
        };
        var snapshotKinds = new[]
        {
            SnapshotKind.ExactCommit,
            SnapshotKind.Candidate,
            SnapshotKind.ProviderEvent,
            SnapshotKind.ProviderFullInventory,
            SnapshotKind.CapturedEvidence,
        };
        var surfaceSets = CreateEveryNonEmptySurfaceSubset();
        var enforcementPhases = new[]
        {
            EnforcementPhase.Audit,
            EnforcementPhase.Prospective,
            EnforcementPhase.FullBlocking,
        };
        var constructed = 0;

        foreach (var subjectRole in subjectRoles)
        {
            foreach (var operation in operations)
            {
                foreach (var snapshotKind in snapshotKinds)
                {
                    foreach (var surfaces in surfaceSets)
                    {
                        foreach (var enforcementPhase in enforcementPhases)
                        {
                            var profile = ExecutionProfile.Create(
                                subjectRole,
                                operation,
                                snapshotKind,
                                surfaces,
                                enforcementPhase);

                            Assert.Equal(subjectRole, profile.SubjectRole);
                            Assert.Equal(operation, profile.Operation);
                            Assert.Equal(snapshotKind, profile.SnapshotKind);
                            Assert.Equal(surfaces, profile.Surfaces);
                            Assert.Equal(
                                enforcementPhase,
                                profile.EnforcementPhase);
                            constructed++;
                        }
                    }
                }
            }
        }

        Assert.Equal(4500, constructed);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void CreateRejectsNullForEachAxis()
    {
        var subjectRole = SubjectRole.Consumer;
        var operation = ProtocolOperation.Conformance;
        var snapshotKind = SnapshotKind.ExactCommit;
        var surfaces = SurfaceSet.Create(new[] { SurfaceKind.Repository });
        var enforcementPhase = EnforcementPhase.Audit;

        Assert.Throws<ArgumentNullException>(() => ExecutionProfile.Create(
            null!,
            operation,
            snapshotKind,
            surfaces,
            enforcementPhase));
        Assert.Throws<ArgumentNullException>(() => ExecutionProfile.Create(
            subjectRole,
            null!,
            snapshotKind,
            surfaces,
            enforcementPhase));
        Assert.Throws<ArgumentNullException>(() => ExecutionProfile.Create(
            subjectRole,
            operation,
            null!,
            surfaces,
            enforcementPhase));
        Assert.Throws<ArgumentNullException>(() => ExecutionProfile.Create(
            subjectRole,
            operation,
            snapshotKind,
            null!,
            enforcementPhase));
        Assert.Throws<ArgumentNullException>(() => ExecutionProfile.Create(
            subjectRole,
            operation,
            snapshotKind,
            surfaces,
            null!));
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ProfilesUseStructuralEqualityIncludingOrderIndependentSurfaceSets()
    {
        var left = ExecutionProfile.Create(
            SubjectRole.ProtocolAuthoritySelfConsumer,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create(
                new[] { SurfaceKind.Release, SurfaceKind.Repository }),
            EnforcementPhase.Audit);
        var equal = ExecutionProfile.Create(
            SubjectRole.Parse("protocol-authority-self-consumer"),
            ProtocolOperation.Parse("conformance"),
            SnapshotKind.Parse("exact-commit"),
            SurfaceSet.Create(
                new[] { SurfaceKind.Repository, SurfaceKind.Release }),
            EnforcementPhase.Parse("audit"));

        Assert.Equal(left, equal);
        Assert.True(left.Equals((object)equal));
        Assert.Equal(left.GetHashCode(), equal.GetHashCode());
        Assert.False(left.Equals(null));
        Assert.False(left.Equals((object)"execution-profile"));

        var oneAxisChanges = new[]
        {
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                left.Operation,
                left.SnapshotKind,
                left.Surfaces,
                left.EnforcementPhase),
            ExecutionProfile.Create(
                left.SubjectRole,
                ProtocolOperation.Publication,
                left.SnapshotKind,
                left.Surfaces,
                left.EnforcementPhase),
            ExecutionProfile.Create(
                left.SubjectRole,
                left.Operation,
                SnapshotKind.Candidate,
                left.Surfaces,
                left.EnforcementPhase),
            ExecutionProfile.Create(
                left.SubjectRole,
                left.Operation,
                left.SnapshotKind,
                SurfaceSet.Create(new[] { SurfaceKind.Provider }),
                left.EnforcementPhase),
            ExecutionProfile.Create(
                left.SubjectRole,
                left.Operation,
                left.SnapshotKind,
                left.Surfaces,
                EnforcementPhase.Prospective),
        };

        Assert.All(oneAxisChanges, profile => Assert.NotEqual(left, profile));
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ReadablePublicInstancePropertiesAreExactlyTheFiveAxes()
    {
        var properties = typeof(ExecutionProfile)
            .GetProperties(BindingFlags.Instance | BindingFlags.Public)
            .Where(property =>
                property.CanRead && property.GetIndexParameters().Length == 0)
            .OrderBy(property => property.Name, StringComparer.Ordinal)
            .ToArray();

        Assert.Collection(
            properties,
            property => AssertProperty(
                property,
                "EnforcementPhase",
                typeof(EnforcementPhase)),
            property => AssertProperty(
                property,
                "Operation",
                typeof(ProtocolOperation)),
            property => AssertProperty(
                property,
                "SnapshotKind",
                typeof(SnapshotKind)),
            property => AssertProperty(
                property,
                "SubjectRole",
                typeof(SubjectRole)),
            property => AssertProperty(
                property,
                "Surfaces",
                typeof(SurfaceSet)));
    }

    private static IReadOnlyList<SurfaceSet> CreateEveryNonEmptySurfaceSubset()
    {
        var kinds = new[]
        {
            SurfaceKind.Repository,
            SurfaceKind.Provider,
            SurfaceKind.Workflow,
            SurfaceKind.Release,
        };
        var results = new List<SurfaceSet>();

        for (var mask = 1; mask < 1 << kinds.Length; mask++)
        {
            var selected = kinds
                .Where((_, index) => (mask & (1 << index)) != 0)
                .Reverse()
                .ToArray();
            results.Add(SurfaceSet.Create(selected));
        }

        return results;
    }

    private static void AssertProperty(
        PropertyInfo property,
        string expectedName,
        Type expectedType)
    {
        Assert.Equal(expectedName, property.Name);
        Assert.Equal(expectedType, property.PropertyType);
    }
}
