using MeAndAI.Operations.Governance;

using var cancellation = new CancellationTokenSource();
ConsoleCancelEventHandler cancelHandler = (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    cancellation.Cancel();
};
Console.CancelKeyPress += cancelHandler;

try
{
    return await GovernanceCli.RunAsync(
        args,
        Console.Out,
        Console.Error,
        cancellation.Token);
}
finally
{
    Console.CancelKeyPress -= cancelHandler;
}
