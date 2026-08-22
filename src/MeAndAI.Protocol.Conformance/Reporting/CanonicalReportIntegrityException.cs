using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance;

public sealed class CanonicalReportIntegrityException : InvalidOperationException
{
    internal CanonicalReportIntegrityException(CanonicalReportIntegrityCode code)
        : base(BuildMessage(code))
    {
        Code = code;
    }

    public CanonicalReportIntegrityCode Code { get; }

    private static string BuildMessage(CanonicalReportIntegrityCode code)
    {
        ArgumentNullException.ThrowIfNull(code);
        return code.Value;
    }
}

public sealed class CanonicalReportIntegrityCode :
    IEquatable<CanonicalReportIntegrityCode>
{
    public static CanonicalReportIntegrityCode EvaluationContextMismatch { get; } =
        new("protocol.report.evaluation-context-mismatch");
    public static CanonicalReportIntegrityCode DimensionInconsistent { get; } =
        new("protocol.report.dimension-inconsistent");
    public static CanonicalReportIntegrityCode DigestMismatch { get; } =
        new("protocol.report.digest-mismatch");
    public static CanonicalReportIntegrityCode ResourceLimitExceeded { get; } =
        new("protocol.report.resource-limit-exceeded");

    private CanonicalReportIntegrityCode(string value) => Value = value;

    public string Value { get; }

    public static CanonicalReportIntegrityCode Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return TryParse(value, out var result)
            ? result
            : throw new FormatException(
                "The value is not a canonical-report integrity code.");
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out CanonicalReportIntegrityCode? result)
    {
        result = All.FirstOrDefault(code => string.Equals(
            code.Value,
            value,
            StringComparison.Ordinal));
        return result is not null;
    }

    public bool Equals(CanonicalReportIntegrityCode? other) =>
        other is not null && string.Equals(
            Value,
            other.Value,
            StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as CanonicalReportIntegrityCode);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;

    private static IReadOnlyList<CanonicalReportIntegrityCode> All =>
    [
        EvaluationContextMismatch,
        DimensionInconsistent,
        DigestMismatch,
        ResourceLimitExceeded,
    ];
}
