using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Infrastructure.Hosting;

return OperationalApplicationHost.Run(
    OperationalApplicationId.Governance,
    args,
    Console.Out,
    Console.Error);
