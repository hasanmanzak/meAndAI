using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Infrastructure.Hosting;

return OperationalApplicationHost.Run(
    OperationalApplicationId.ConsumerUpdate,
    args,
    Console.Out,
    Console.Error);
