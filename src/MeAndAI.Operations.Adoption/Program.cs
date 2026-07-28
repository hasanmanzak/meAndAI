using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Infrastructure.Hosting;

return OperationalApplicationHost.Run(
    OperationalApplicationId.Adoption,
    args,
    Console.Out,
    Console.Error);
