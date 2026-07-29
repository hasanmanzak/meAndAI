namespace MeAndAI.Protocol.Domain;

public sealed class SurfaceSet : IEquatable<SurfaceSet>
{
    private static readonly SurfaceKind[] SchemaOrder =
    [
        SurfaceKind.Repository,
        SurfaceKind.Provider,
        SurfaceKind.Workflow,
        SurfaceKind.Release,
    ];

    private readonly IReadOnlyList<SurfaceKind> _values;

    private SurfaceSet(IReadOnlyList<SurfaceKind> values)
    {
        _values = values;
    }

    public IReadOnlyList<SurfaceKind> Values => _values;

    public static SurfaceSet Create(IEnumerable<SurfaceKind> surfaces)
    {
        ArgumentNullException.ThrowIfNull(surfaces);

        var materialized = surfaces.ToArray();
        if (materialized.Length == 0)
        {
            throw new ArgumentException(
                "At least one surface is required.",
                nameof(surfaces));
        }

        var unique = new HashSet<SurfaceKind>();
        foreach (var surface in materialized)
        {
            if (surface is null)
            {
                throw new ArgumentException(
                    "A surface cannot be null.",
                    nameof(surfaces));
            }

            if (!unique.Add(surface))
            {
                throw new ArgumentException(
                    "Duplicate surfaces are not allowed.",
                    nameof(surfaces));
            }
        }

        var ordered = SchemaOrder
            .Where(unique.Contains)
            .ToArray();
        if (ordered.Length != materialized.Length)
        {
            throw new ArgumentException(
                "Every surface must be a declared schema value.",
                nameof(surfaces));
        }

        return new SurfaceSet(Array.AsReadOnly(ordered));
    }

    public bool Equals(SurfaceSet? other) =>
        other is not null &&
        (ReferenceEquals(this, other) || _values.SequenceEqual(other._values));

    public override bool Equals(object? obj) =>
        obj is SurfaceSet other && Equals(other);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        foreach (var surface in _values)
        {
            hash.Add(surface);
        }

        return hash.ToHashCode();
    }

    public override string ToString() => string.Join(",", _values);
}
