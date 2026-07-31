using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class AdmissionProofKind : IEquatable<AdmissionProofKind>
{
    private AdmissionProofKind(string value)
    {
        Value = value;
    }

    public static AdmissionProofKind Observed { get; } = new("observed");

    public static AdmissionProofKind Failed { get; } = new("failed");

    public static AdmissionProofKind NoInput { get; } = new("no-input");

    public string Value { get; }

    public static AdmissionProofKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical admission proof kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out AdmissionProofKind? result)
    {
        result = value switch
        {
            "observed" => Observed,
            "failed" => Failed,
            "no-input" => NoInput,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(AdmissionProofKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as AdmissionProofKind);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
