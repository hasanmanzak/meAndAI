using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Results;

namespace MeAndAI.Operations.Infrastructure.Execution;

public static class OperationBoundary
{
    public static async ValueTask<OperationResult<T>> ExecuteAsync<T>(
        OperationStageId stage,
        Func<CancellationToken, ValueTask<T>> operation,
        CancellationToken cancellationToken)
        where T : class
    {
        ArgumentNullException.ThrowIfNull(stage);
        ArgumentNullException.ThrowIfNull(operation);

        if (cancellationToken.IsCancellationRequested)
        {
            return OperationResult<T>.Canceled(stage);
        }

        try
        {
            var value = await operation(cancellationToken).ConfigureAwait(false);
            return OperationResult<T>.Succeeded(stage, value);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            return OperationResult<T>.Canceled(stage);
        }
        catch (OperationalDependencyException)
        {
            return OperationResult<T>.Failed(
                stage,
                OperationFailureCode.DependencyFailed);
        }
    }
}
