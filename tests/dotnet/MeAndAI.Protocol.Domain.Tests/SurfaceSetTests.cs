using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class SurfaceSetTests
{
    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void CreateRejectsNullEmptyRuntimeNullAndSemanticDuplicate()
    {
        Assert.Throws<ArgumentNullException>(() => SurfaceSet.Create(null!));
        Assert.Throws<ArgumentException>(() =>
            SurfaceSet.Create(Array.Empty<SurfaceKind>()));
        Assert.Throws<ArgumentException>(() =>
            SurfaceSet.Create(
                new SurfaceKind[] { SurfaceKind.Repository, null! }));
        Assert.Throws<ArgumentException>(() =>
            SurfaceSet.Create(
                new[]
                {
                    SurfaceKind.Repository,
                    SurfaceKind.Parse("repository"),
                }));
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void AllTwentyFourFullSetPermutationsCanonicalizeIdentically()
    {
        var canonical = new[]
        {
            SurfaceKind.Repository,
            SurfaceKind.Provider,
            SurfaceKind.Workflow,
            SurfaceKind.Release,
        };
        var baseline = SurfaceSet.Create(canonical);
        var permutations = CreatePermutations(canonical);

        Assert.Equal(24, permutations.Count);

        foreach (var permutation in permutations)
        {
            var set = SurfaceSet.Create(permutation);

            Assert.Equal(canonical, set.Values);
            Assert.Equal("repository,provider,workflow,release", set.ToString());
            Assert.Equal(baseline, set);
            Assert.Equal(baseline.GetHashCode(), set.GetHashCode());
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void SubsetsUseSchemaOrderRatherThanInputOrder()
    {
        var set = SurfaceSet.Create(
            new[] { SurfaceKind.Release, SurfaceKind.Repository });
        var different = SurfaceSet.Create(new[] { SurfaceKind.Provider });

        Assert.Equal(
            new[] { SurfaceKind.Repository, SurfaceKind.Release },
            set.Values);
        Assert.Equal("repository,release", set.ToString());
        Assert.NotEqual(set, different);
        Assert.False(set.Equals(different));
        Assert.False(set.Equals((object)different));
        Assert.False(set.Equals(null));
        Assert.False(set.Equals((object)"repository,release"));
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void CreateDefensivelyCopiesCallerInput()
    {
        var input = new List<SurfaceKind>
        {
            SurfaceKind.Release,
            SurfaceKind.Repository,
        };
        var set = SurfaceSet.Create(input);
        var equivalent = SurfaceSet.Create(
            new[] { SurfaceKind.Repository, SurfaceKind.Release });
        var hashBeforeCallerMutation = set.GetHashCode();

        input[0] = SurfaceKind.Provider;
        input.Clear();

        Assert.Equal(
            new[] { SurfaceKind.Repository, SurfaceKind.Release },
            set.Values);
        Assert.Equal(equivalent, set);
        Assert.Equal(hashBeforeCallerMutation, set.GetHashCode());
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ValuesCannotBeMutatedThroughAnyExposedCollectionInterface()
    {
        var set = SurfaceSet.Create(
            new[] { SurfaceKind.Repository, SurfaceKind.Release });
        var values = set.Values;

        Assert.IsAssignableFrom<IReadOnlyList<SurfaceKind>>(values);
        Assert.False(values is SurfaceKind[]);

        if (values is IList<SurfaceKind> list)
        {
            Assert.True(list.IsReadOnly);
            Assert.Throws<NotSupportedException>(() =>
                list[0] = SurfaceKind.Provider);
        }

        if (values is ICollection<SurfaceKind> collection)
        {
            Assert.True(collection.IsReadOnly);
            Assert.Throws<NotSupportedException>(() =>
                collection.Add(SurfaceKind.Provider));
        }

        Assert.Equal(
            new[] { SurfaceKind.Repository, SurfaceKind.Release },
            set.Values);
    }

    private static IReadOnlyList<SurfaceKind[]> CreatePermutations(
        IReadOnlyList<SurfaceKind> values)
    {
        var working = values.ToArray();
        var results = new List<SurfaceKind[]>();
        AddPermutations(working, index: 0, results);
        return results;
    }

    private static void AddPermutations(
        SurfaceKind[] values,
        int index,
        ICollection<SurfaceKind[]> results)
    {
        if (index == values.Length)
        {
            results.Add((SurfaceKind[])values.Clone());
            return;
        }

        for (var candidate = index; candidate < values.Length; candidate++)
        {
            (values[index], values[candidate]) = (values[candidate], values[index]);
            AddPermutations(values, index + 1, results);
            (values[index], values[candidate]) = (values[candidate], values[index]);
        }
    }
}
