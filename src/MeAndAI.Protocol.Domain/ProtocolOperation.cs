using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class ProtocolOperation : IEquatable<ProtocolOperation>
{
    private const string ConformanceToken = "conformance";
    private const string AdoptionAssessmentToken = "adoption-assessment";
    private const string AdoptionPlanToken = "adoption-plan";
    private const string AdoptionApplyToken = "adoption-apply";
    private const string UpdateAssessmentToken = "update-assessment";
    private const string UpdatePlanToken = "update-plan";
    private const string UpdateApplyToken = "update-apply";
    private const string PublicationToken = "publication";
    private const string FinalizationToken = "finalization";
    private const string RecoveryToken = "recovery";

    private ProtocolOperation(string value)
    {
        Value = value;
    }

    public static ProtocolOperation Conformance { get; } =
        new(ConformanceToken);

    public static ProtocolOperation AdoptionAssessment { get; } =
        new(AdoptionAssessmentToken);

    public static ProtocolOperation AdoptionPlan { get; } =
        new(AdoptionPlanToken);

    public static ProtocolOperation AdoptionApply { get; } =
        new(AdoptionApplyToken);

    public static ProtocolOperation UpdateAssessment { get; } =
        new(UpdateAssessmentToken);

    public static ProtocolOperation UpdatePlan { get; } =
        new(UpdatePlanToken);

    public static ProtocolOperation UpdateApply { get; } =
        new(UpdateApplyToken);

    public static ProtocolOperation Publication { get; } =
        new(PublicationToken);

    public static ProtocolOperation Finalization { get; } =
        new(FinalizationToken);

    public static ProtocolOperation Recovery { get; } = new(RecoveryToken);

    public string Value { get; }

    public static ProtocolOperation Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ProtocolOperation? result)
    {
        result = value switch
        {
            ConformanceToken => Conformance,
            AdoptionAssessmentToken => AdoptionAssessment,
            AdoptionPlanToken => AdoptionPlan,
            AdoptionApplyToken => AdoptionApply,
            UpdateAssessmentToken => UpdateAssessment,
            UpdatePlanToken => UpdatePlan,
            UpdateApplyToken => UpdateApply,
            PublicationToken => Publication,
            FinalizationToken => Finalization,
            RecoveryToken => Recovery,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(ProtocolOperation? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is ProtocolOperation other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
