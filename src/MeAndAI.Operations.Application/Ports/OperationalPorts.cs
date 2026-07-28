namespace MeAndAI.Operations.Application.Ports;

public interface IOperationalPort;

public interface IRepositoryReadPort : IOperationalPort;

public interface IRepositoryMutationPort : IOperationalPort;

public interface IProviderReadPort : IOperationalPort;

public interface IProviderMutationPort : IOperationalPort;
