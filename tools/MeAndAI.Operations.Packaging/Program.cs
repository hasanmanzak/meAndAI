using MeAndAI.Operations.Packaging;

using var cancellation = new CancellationTokenSource();
ConsoleCancelEventHandler cancelHandler = (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    cancellation.Cancel();
};
Console.CancelKeyPress += cancelHandler;

try
{
    return await PackagingCli.RunAsync(args, cancellation.Token)
        .ConfigureAwait(false);
}
finally
{
    Console.CancelKeyPress -= cancelHandler;
}
