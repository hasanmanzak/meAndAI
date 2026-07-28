using System.Text.Json;
using MeAndAI.Operations.Application.Authority;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Infrastructure.Hosting;

public static class OperationalApplicationHost
{
    public const int ContractSchemaVersion = 1;

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public static int Run(
        OperationalApplicationId application,
        IReadOnlyList<string> arguments,
        TextWriter standardOutput,
        TextWriter standardError)
    {
        ArgumentNullException.ThrowIfNull(application);
        ArgumentNullException.ThrowIfNull(arguments);
        ArgumentNullException.ThrowIfNull(standardOutput);
        ArgumentNullException.ThrowIfNull(standardError);

        _ = OperationalAuthorityCatalog.For(application);

        if (arguments.Count != 1 ||
            !string.Equals(
                arguments[0],
                "--describe-contract",
                StringComparison.Ordinal))
        {
            standardError.WriteLine(
                "This foundation shell accepts only --describe-contract.");
            return 64;
        }

        var descriptor = new OperationalApplicationContractDescriptor(
            application.Value,
            ContractSchemaVersion);
        standardOutput.WriteLine(
            JsonSerializer.Serialize(descriptor, SerializerOptions));
        return 0;
    }

    private sealed record OperationalApplicationContractDescriptor(
        string Application,
        int ContractSchemaVersion);
}
