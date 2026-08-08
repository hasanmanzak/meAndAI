using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CatalogIntegrityCode : IEquatable<CatalogIntegrityCode>
{
    private CatalogIntegrityCode(string value)
    {
        Value = value;
    }

    public static CatalogIntegrityCode ManifestInvalid { get; } =
        new("protocol.integrity.manifest-invalid");

    public static CatalogIntegrityCode ArtifactMismatch { get; } =
        new("protocol.integrity.artifact-mismatch");

    public static CatalogIntegrityCode ActivationProofInvalid { get; } =
        new("protocol.integrity.activation-proof-invalid");

    public static CatalogIntegrityCode CatalogIncomplete { get; } =
        new("protocol.integrity.catalog-incomplete");

    public static CatalogIntegrityCode RegistrationMismatch { get; } =
        new("protocol.integrity.registration-mismatch");

    public static CatalogIntegrityCode PlanStateInvalid { get; } =
        new("protocol.integrity.plan-state-invalid");

    public static CatalogIntegrityCode AdmissionProofInvalid { get; } =
        new("protocol.integrity.admission-proof-invalid");

    public static CatalogIntegrityCode ReferenceInvalid { get; } =
        new("protocol.integrity.reference-invalid");

    public static CatalogIntegrityCode IntentInvalid { get; } =
        new("protocol.integrity.intent-invalid");

    public static CatalogIntegrityCode CacheIdentityCollision { get; } =
        new("protocol.integrity.cache-identity-collision");

    public string Value { get; }

    public static CatalogIntegrityCode Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical catalog integrity code.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out CatalogIntegrityCode? result)
    {
        result = value switch
        {
            "protocol.integrity.manifest-invalid" => ManifestInvalid,
            "protocol.integrity.artifact-mismatch" => ArtifactMismatch,
            "protocol.integrity.activation-proof-invalid" => ActivationProofInvalid,
            "protocol.integrity.catalog-incomplete" => CatalogIncomplete,
            "protocol.integrity.registration-mismatch" => RegistrationMismatch,
            "protocol.integrity.plan-state-invalid" => PlanStateInvalid,
            "protocol.integrity.admission-proof-invalid" => AdmissionProofInvalid,
            "protocol.integrity.reference-invalid" => ReferenceInvalid,
            "protocol.integrity.intent-invalid" => IntentInvalid,
            "protocol.integrity.cache-identity-collision" => CacheIdentityCollision,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(CatalogIntegrityCode? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as CatalogIntegrityCode);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
