namespace MeAndAI.Protocol.Domain;

public sealed class AcquisitionFailure : IEquatable<AcquisitionFailure>
{
    private AcquisitionFailure(string requirementKey, string code)
    {
        RequirementKey = requirementKey;
        Code = code;
    }

    public string RequirementKey { get; }

    public string Code { get; }

    public static AcquisitionFailure Create(
        string requirementKey,
        string code) =>
        new(
            EvidenceContractValidation.OpenToken(
                requirementKey,
                nameof(requirementKey)),
            EvidenceContractValidation.OpenToken(code, nameof(code)));

    public bool Equals(AcquisitionFailure? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(
            RequirementKey,
            other.RequirementKey) &&
        StringComparer.Ordinal.Equals(Code, other.Code);

    public override bool Equals(object? obj) =>
        Equals(obj as AcquisitionFailure);

    public override int GetHashCode() => HashCode.Combine(
        StringComparer.Ordinal.GetHashCode(RequirementKey),
        StringComparer.Ordinal.GetHashCode(Code));
}
