using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Domain.Results;

public sealed record OperationResult<T>
    where T : class
{
    private OperationResult(
        OperationStageId stage,
        OperationOutcome outcome,
        T? value,
        OperationFailureCode? failureCode)
    {
        Stage = stage;
        Outcome = outcome;
        Value = value;
        FailureCode = failureCode;
    }

    public OperationStageId Stage { get; }

    public OperationOutcome Outcome { get; }

    public T? Value { get; }

    public OperationFailureCode? FailureCode { get; }

    public static OperationResult<T> Succeeded(
        OperationStageId stage,
        T value)
    {
        ArgumentNullException.ThrowIfNull(stage);
        ArgumentNullException.ThrowIfNull(value);

        return new OperationResult<T>(
            stage,
            OperationOutcome.Succeeded,
            value,
            null);
    }

    public static OperationResult<T> Rejected(
        OperationStageId stage,
        OperationFailureCode failureCode)
    {
        ArgumentNullException.ThrowIfNull(stage);
        ArgumentNullException.ThrowIfNull(failureCode);

        if (failureCode != OperationFailureCode.MalformedInput &&
            failureCode != OperationFailureCode.CapabilityDenied)
        {
            throw new ArgumentOutOfRangeException(
                nameof(failureCode),
                failureCode,
                "Rejected results require a rejection failure code.");
        }

        return new OperationResult<T>(
            stage,
            OperationOutcome.Rejected,
            default,
            failureCode);
    }

    public static OperationResult<T> Failed(
        OperationStageId stage,
        OperationFailureCode failureCode)
    {
        ArgumentNullException.ThrowIfNull(stage);
        ArgumentNullException.ThrowIfNull(failureCode);

        if (failureCode != OperationFailureCode.DependencyFailed)
        {
            throw new ArgumentOutOfRangeException(
                nameof(failureCode),
                failureCode,
                "Failed results require a dependency failure code.");
        }

        return new OperationResult<T>(
            stage,
            OperationOutcome.Failed,
            default,
            failureCode);
    }

    public static OperationResult<T> Canceled(OperationStageId stage)
    {
        ArgumentNullException.ThrowIfNull(stage);

        return new OperationResult<T>(
            stage,
            OperationOutcome.Canceled,
            default,
            OperationFailureCode.OperationCanceled);
    }

    public override string ToString() => FailureCode is null
        ? $"{Stage}:{Outcome}"
        : $"{Stage}:{Outcome}:{FailureCode}";
}
