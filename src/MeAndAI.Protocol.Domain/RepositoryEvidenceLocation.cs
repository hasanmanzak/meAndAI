namespace MeAndAI.Protocol.Domain;

public sealed class RepositoryEvidenceLocation : EvidenceLocation
{
    private RepositoryEvidenceLocation(
        EvidenceScope scope,
        string repositoryRelativePath,
        string? blobIdentity,
        int? line,
        string? anchor,
        string? property)
        : base(scope)
    {
        RepositoryRelativePath = repositoryRelativePath;
        BlobIdentity = blobIdentity;
        Line = line;
        Anchor = anchor;
        Property = property;
    }

    public string RepositoryRelativePath { get; }

    public string? BlobIdentity { get; }

    public int? Line { get; }

    public string? Anchor { get; }

    public string? Property { get; }

    public static RepositoryEvidenceLocation Create(
        EvidenceScope scope,
        string repositoryRelativePath,
        string? blobIdentity,
        int? line,
        string? anchor,
        string? property)
    {
        ArgumentNullException.ThrowIfNull(scope);

        if (!scope.Target.Surface.Equals(SurfaceKind.Repository))
        {
            throw new ArgumentException(
                "A repository location requires a repository evidence scope.",
                nameof(scope));
        }

        var validatedPath = EvidenceContractValidation.RepositoryRelativePath(
            repositoryRelativePath,
            nameof(repositoryRelativePath));
        var validatedBlobIdentity = blobIdentity is null
            ? null
            : EvidenceContractValidation.GitObjectIdentity(
                blobIdentity,
                nameof(blobIdentity));

        if (line is <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(line),
                line,
                "A repository line must be positive.");
        }

        var validatedAnchor = EvidenceContractValidation.OptionalOpaque(
            anchor,
            nameof(anchor));
        var validatedProperty = EvidenceContractValidation.OptionalOpaque(
            property,
            nameof(property));
        var refinementCount =
            (line.HasValue ? 1 : 0) +
            (validatedAnchor is null ? 0 : 1) +
            (validatedProperty is null ? 0 : 1);

        if (refinementCount > 1)
        {
            throw new ArgumentException(
                "A repository location can have at most one refinement.");
        }

        return new RepositoryEvidenceLocation(
            scope,
            validatedPath,
            validatedBlobIdentity,
            line,
            validatedAnchor,
            validatedProperty);
    }
}
