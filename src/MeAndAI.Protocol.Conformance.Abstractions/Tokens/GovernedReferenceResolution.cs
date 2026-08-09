using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class GovernedReferenceResolution :
    IEquatable<GovernedReferenceResolution>
{
    private GovernedReferenceResolution(string value)
    {
        Value = value;
    }

    public static GovernedReferenceResolution Exact { get; } = new("exact");

    public static GovernedReferenceResolution WrongTarget { get; } =
        new("wrong-target");

    public static GovernedReferenceResolution Unresolved { get; } =
        new("unresolved");

    public static GovernedReferenceResolution MissingFragment { get; } =
        new("missing-fragment");

    public static GovernedReferenceResolution WrongFragment { get; } =
        new("wrong-fragment");

    public static GovernedReferenceResolution WrongRepository { get; } =
        new("wrong-repository");

    public static GovernedReferenceResolution WrongObject { get; } =
        new("wrong-object");

    public static GovernedReferenceResolution ExternalEvidenceRequired { get; } =
        new("external-evidence-required");

    public string Value { get; }

    public static GovernedReferenceResolution Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException(
                "The value is not a canonical governed reference resolution.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out GovernedReferenceResolution? result)
    {
        result = value switch
        {
            "exact" => Exact,
            "wrong-target" => WrongTarget,
            "unresolved" => Unresolved,
            "missing-fragment" => MissingFragment,
            "wrong-fragment" => WrongFragment,
            "wrong-repository" => WrongRepository,
            "wrong-object" => WrongObject,
            "external-evidence-required" => ExternalEvidenceRequired,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(GovernedReferenceResolution? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as GovernedReferenceResolution);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
