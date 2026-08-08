using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class QualifiedEvidenceReferenceKind :
    IEquatable<QualifiedEvidenceReferenceKind>
{
    private QualifiedEvidenceReferenceKind(string value)
    {
        Value = value;
    }

    public static QualifiedEvidenceReferenceKind ContextProof { get; } =
        new("context-proof");

    public static QualifiedEvidenceReferenceKind Root { get; } = new("root");

    public static QualifiedEvidenceReferenceKind Derived { get; } = new("derived");

    public static QualifiedEvidenceReferenceKind ExpectedSelector { get; } =
        new("expected-selector");

    public string Value { get; }

    public static QualifiedEvidenceReferenceKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException(
                "The value is not a canonical qualified evidence reference kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out QualifiedEvidenceReferenceKind? result)
    {
        result = value switch
        {
            "context-proof" => ContextProof,
            "root" => Root,
            "derived" => Derived,
            "expected-selector" => ExpectedSelector,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(QualifiedEvidenceReferenceKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as QualifiedEvidenceReferenceKind);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
