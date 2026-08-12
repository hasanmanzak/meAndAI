namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IRepositoryTree : IEvidenceCapability
{
    IReadOnlyList<RepositoryEntryView> Entries { get; }
}
