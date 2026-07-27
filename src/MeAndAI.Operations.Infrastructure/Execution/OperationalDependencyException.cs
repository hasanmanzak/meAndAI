namespace MeAndAI.Operations.Infrastructure.Execution;

public sealed class OperationalDependencyException : Exception
{
    public OperationalDependencyException(string message)
        : base(message)
    {
    }

    public OperationalDependencyException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}
