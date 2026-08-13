using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Indexes;

internal sealed class PolicyIndexInput : IComponentInput;

internal sealed class RepositoryTreeIndex :
    IContextIndexer<PolicyIndexInput, IRepositoryTree>;

internal sealed class ProtocolRecordIndex :
    IContextIndexer<PolicyIndexInput, IProtocolRecordIndex>;

internal sealed class GovernedReferenceIndex :
    IContextIndexer<PolicyIndexInput, IGovernedReferenceIndex>;

internal sealed class RepositoryTargetResolutionIndex :
    IContextIndexer<PolicyIndexInput, IRepositoryTargetResolutionIndex>;
