using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Policy.Models;

internal sealed class SourceTextModel : IProtocolSemanticModel
{
    internal SourceTextModel(EvidenceBinding binding, ReadOnlyMemory<byte> body)
    {
        Binding = binding ?? throw new ArgumentNullException(nameof(binding));
        Body = body.ToArray();
    }

    internal EvidenceBinding Binding { get; }
    internal ReadOnlyMemory<byte> Body { get; }
}

internal sealed class RepositoryTreeModel : IProtocolSemanticModel
{
    internal RepositoryTreeModel(
        EvidenceBinding binding,
        IEnumerable<RepositoryTreePayloadEntry> entries)
    {
        Binding = binding ?? throw new ArgumentNullException(nameof(binding));
        ArgumentNullException.ThrowIfNull(entries);
        var snapshot = entries.ToArray();
        if (snapshot.Any(entry => entry is null))
        {
            throw new ArgumentException(
                "Repository-tree entries cannot contain null.",
                nameof(entries));
        }

        Entries = Array.AsReadOnly(snapshot);
    }

    internal EvidenceBinding Binding { get; }
    internal IReadOnlyList<RepositoryTreePayloadEntry> Entries { get; }
}

internal sealed class RepositoryTargetResolutionModel : IProtocolSemanticModel
{
    internal RepositoryTargetResolutionModel(
        EvidenceBinding binding,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        IEnumerable<RepositoryTargetResolutionPayloadRow> rows,
        IEnumerable<RepositoryTargetResolutionContent> contents)
    {
        Binding = binding ?? throw new ArgumentNullException(nameof(binding));
        DemandDigest = demandDigest ?? throw new ArgumentNullException(nameof(demandDigest));
        ArgumentNullException.ThrowIfNull(demandItems);
        ArgumentNullException.ThrowIfNull(rows);
        ArgumentNullException.ThrowIfNull(contents);
        var demandSnapshot = demandItems.ToArray();
        var rowSnapshot = rows.ToArray();
        var contentSnapshot = contents.ToArray();
        if (demandSnapshot.Any(item => item is null) ||
            rowSnapshot.Any(item => item is null) ||
            contentSnapshot.Any(item => item is null))
        {
            throw new ArgumentException(
                "Repository-target model collections cannot contain null.",
                nameof(demandItems));
        }

        DemandItems = Array.AsReadOnly(demandSnapshot);
        Rows = Array.AsReadOnly(rowSnapshot);
        Contents = Array.AsReadOnly(contentSnapshot);
    }

    internal EvidenceBinding Binding { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal IReadOnlyList<RepositoryTargetResolutionPayloadRow> Rows { get; }
    internal IReadOnlyList<RepositoryTargetResolutionContent> Contents { get; }
}

internal sealed class MarkdownDocumentModel : IProtocolSemanticModel
{
    internal MarkdownDocumentModel(
        QualifiedEvidenceHandle parent,
        string canonicalText)
    {
        Parent = parent ?? throw new ArgumentNullException(nameof(parent));
        CanonicalText = canonicalText ?? throw new ArgumentNullException(nameof(canonicalText));
    }

    internal QualifiedEvidenceHandle Parent { get; }
    internal string CanonicalText { get; }
}

internal sealed class RepositoryTargetMarkdownDocumentSetModel :
    IProtocolSemanticModel
{
    internal RepositoryTargetMarkdownDocumentSetModel(
        QualifiedEvidenceHandle parent,
        IEnumerable<string> canonicalDocuments)
    {
        Parent = parent ?? throw new ArgumentNullException(nameof(parent));
        ArgumentNullException.ThrowIfNull(canonicalDocuments);
        var snapshot = canonicalDocuments.ToArray();
        if (snapshot.Any(item => item is null))
        {
            throw new ArgumentException(
                "Repository-target documents cannot contain null.",
                nameof(canonicalDocuments));
        }

        CanonicalDocuments = Array.AsReadOnly(snapshot);
    }

    internal QualifiedEvidenceHandle Parent { get; }
    internal IReadOnlyList<string> CanonicalDocuments { get; }
}

internal sealed class RepositoryTreeCapability(
    IEnumerable<RepositoryEntryView> entries) : IRepositoryTree
{
    public IReadOnlyList<RepositoryEntryView> Entries { get; } =
        Snapshot(entries, nameof(entries));

    private static IReadOnlyList<RepositoryEntryView> Snapshot(
        IEnumerable<RepositoryEntryView> values,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        var snapshot = values.ToArray();
        if (snapshot.Any(value => value is null))
        {
            throw new ArgumentException("The collection contains null.", parameterName);
        }

        return Array.AsReadOnly(snapshot);
    }
}

internal sealed class ProtocolRecordCapability(
    IEnumerable<ProtocolRecordView> records) : IProtocolRecordIndex
{
    public IReadOnlyList<ProtocolRecordView> Records { get; } =
        Array.AsReadOnly((records ?? throw new ArgumentNullException(nameof(records))).ToArray());
}

internal sealed class GovernedReferenceCapability(
    IEnumerable<GovernedReferenceView> references) : IGovernedReferenceIndex
{
    public IReadOnlyList<GovernedReferenceView> References { get; } =
        Array.AsReadOnly((references ?? throw new ArgumentNullException(nameof(references))).ToArray());
}

internal sealed class RepositoryTargetResolutionCapability(
    IEnumerable<RepositoryTargetResolutionView> targets) :
    IRepositoryTargetResolutionIndex
{
    public IReadOnlyList<RepositoryTargetResolutionView> Targets { get; } =
        Array.AsReadOnly((targets ?? throw new ArgumentNullException(nameof(targets))).ToArray());
}
