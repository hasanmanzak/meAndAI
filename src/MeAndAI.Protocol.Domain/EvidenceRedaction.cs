namespace MeAndAI.Protocol.Domain;

public sealed class EvidenceRedaction : IEquatable<EvidenceRedaction>
{
    private EvidenceRedaction(
        bool requiredValuesOmitted,
        bool nonRequiredValuesOmitted)
    {
        RequiredValuesOmitted = requiredValuesOmitted;
        NonRequiredValuesOmitted = nonRequiredValuesOmitted;
    }

    public static EvidenceRedaction None { get; } = new(false, false);

    public bool RequiredValuesOmitted { get; }

    public bool NonRequiredValuesOmitted { get; }

    public static EvidenceRedaction Create(
        bool requiredValuesOmitted,
        bool nonRequiredValuesOmitted) =>
        requiredValuesOmitted || nonRequiredValuesOmitted
            ? new EvidenceRedaction(
                requiredValuesOmitted,
                nonRequiredValuesOmitted)
            : None;

    public bool Equals(EvidenceRedaction? other) =>
        other is not null &&
        RequiredValuesOmitted == other.RequiredValuesOmitted &&
        NonRequiredValuesOmitted == other.NonRequiredValuesOmitted;

    public override bool Equals(object? obj) =>
        Equals(obj as EvidenceRedaction);

    public override int GetHashCode() => HashCode.Combine(
        RequiredValuesOmitted,
        NonRequiredValuesOmitted);
}
