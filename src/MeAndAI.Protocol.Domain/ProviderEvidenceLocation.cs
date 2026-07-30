namespace MeAndAI.Protocol.Domain;

public sealed class ProviderEvidenceLocation : EvidenceLocation
{
    private ProviderEvidenceLocation(
        EvidenceScope scope,
        string providerServiceIdentity,
        string objectType,
        string stableObjectIdentity,
        string versionIdentity,
        string? field,
        int? line,
        string? fragment)
        : base(scope)
    {
        ProviderServiceIdentity = providerServiceIdentity;
        ObjectType = objectType;
        StableObjectIdentity = stableObjectIdentity;
        VersionIdentity = versionIdentity;
        Field = field;
        Line = line;
        Fragment = fragment;
    }

    public string ProviderServiceIdentity { get; }

    public string ObjectType { get; }

    public string StableObjectIdentity { get; }

    public string VersionIdentity { get; }

    public string? Field { get; }

    public int? Line { get; }

    public string? Fragment { get; }

    public static ProviderEvidenceLocation Create(
        EvidenceScope scope,
        string providerServiceIdentity,
        string objectType,
        string stableObjectIdentity,
        string versionIdentity,
        string? field,
        int? line,
        string? fragment)
    {
        ArgumentNullException.ThrowIfNull(scope);

        if (!scope.Target.Surface.Equals(SurfaceKind.Provider) &&
            !scope.Target.Surface.Equals(SurfaceKind.Workflow))
        {
            throw new ArgumentException(
                "A provider location requires a provider or workflow evidence scope.",
                nameof(scope));
        }

        var validatedProviderServiceIdentity =
            EvidenceContractValidation.OpaqueIdentity(
                providerServiceIdentity,
                nameof(providerServiceIdentity));
        var validatedObjectType = EvidenceContractValidation.OpenToken(
            objectType,
            nameof(objectType));
        var validatedStableObjectIdentity =
            EvidenceContractValidation.OpaqueIdentity(
                stableObjectIdentity,
                nameof(stableObjectIdentity));
        var validatedVersionIdentity = EvidenceContractValidation.OpaqueIdentity(
            versionIdentity,
            nameof(versionIdentity));
        var validatedField = EvidenceContractValidation.OptionalOpaque(
            field,
            nameof(field));

        if (line is <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(line),
                line,
                "A provider line must be positive.");
        }

        var validatedFragment = EvidenceContractValidation.OptionalOpaque(
            fragment,
            nameof(fragment));

        if ((line.HasValue || validatedFragment is not null) &&
            validatedField is null)
        {
            throw new ArgumentException(
                "A provider line or fragment requires a field.",
                nameof(field));
        }

        if (line.HasValue && validatedFragment is not null)
        {
            throw new ArgumentException(
                "A provider location cannot have both a line and a fragment.");
        }

        return new ProviderEvidenceLocation(
            scope,
            validatedProviderServiceIdentity,
            validatedObjectType,
            validatedStableObjectIdentity,
            validatedVersionIdentity,
            validatedField,
            line,
            validatedFragment);
    }
}
