using MeAndAI.Operations.Infrastructure.Hosting;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class OperationalApplicationHostExitCodeTests
{
    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void HostExitCodesHaveOneNamedAbiOwner()
    {
        Assert.Equal(
            [0, 64],
            Enum.GetValues<OperationalApplicationHostExitCode>()
                .Select(code => (int)code));
    }
}
