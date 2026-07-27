using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.Authority;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Infrastructure.Ports;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class OperationalPortScopeTests
{
    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void ReadOnlyScopeResolvesOnlyItsExactRegisteredReadPort()
    {
        var reader = new RepositorySnapshotPort();
        var scope = OperationalPortScope.Create(
            ReadOnlyGrant(),
            OperationalPortRegistration.Create<IRepositorySnapshotPort>(reader));

        Assert.Same(reader, scope.Require<IRepositorySnapshotPort>());
        Assert.Throws<UnauthorizedAccessException>(
            () => scope.Require<IRepositoryWriterPort>());
        Assert.Throws<UnauthorizedAccessException>(
            () => scope.Require<IProviderWriterPort>());
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void ReadOnlyScopeRejectsMutationRegistrationBeforeResolution()
    {
        var registration =
            OperationalPortRegistration.Create<IRepositoryWriterPort>(
                new RepositoryWriterPort());

        Assert.Throws<UnauthorizedAccessException>(
            () => OperationalPortScope.Create(ReadOnlyGrant(), registration));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void PortContractsMustDeclareExactlyOneCapability()
    {
        Assert.Throws<ArgumentException>(
            () => OperationalPortRegistration.Create<IAmbiguousReadPort>(
                new AmbiguousReadPort()));
        Assert.Throws<ArgumentException>(
            () => OperationalPortRegistration.Create<IRepositoryReadPort>(
                new RepositorySnapshotPort()));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void PortImplementationsCannotExposeAnAdditionalCapability()
    {
        Assert.Throws<ArgumentException>(
            () => OperationalPortRegistration.Create<IRepositorySnapshotPort>(
                new CapabilityWideningSnapshotPort()));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void DuplicateExactPortContractsAreRejected()
    {
        var first = OperationalPortRegistration.Create<IRepositorySnapshotPort>(
            new RepositorySnapshotPort());
        var second = OperationalPortRegistration.Create<IRepositorySnapshotPort>(
            new RepositorySnapshotPort());

        Assert.Throws<ArgumentException>(
            () => OperationalPortScope.Create(ReadOnlyGrant(), first, second));
    }

    private static OperationalAuthorityGrant ReadOnlyGrant() =>
        OperationalAuthorityGrant.Create(
            OperationStageId.Validate,
            OperationalCapability.RepositoryRead,
            OperationalCapability.ProviderRead);

    private interface IRepositorySnapshotPort : IRepositoryReadPort;

    private interface IRepositoryWriterPort : IRepositoryMutationPort;

    private interface IProviderWriterPort : IProviderMutationPort;

    private interface IAmbiguousReadPort : IRepositoryReadPort, IProviderReadPort;

    private sealed class RepositorySnapshotPort : IRepositorySnapshotPort;

    private sealed class RepositoryWriterPort : IRepositoryWriterPort;

    private sealed class CapabilityWideningSnapshotPort :
        IRepositorySnapshotPort,
        IProviderMutationPort;

    private sealed class AmbiguousReadPort : IAmbiguousReadPort;
}
