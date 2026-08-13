using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;
using Markdig.Syntax;

namespace MeAndAI.Protocol.Policy.Indexes;

internal sealed class PolicyIndexInput : IComponentInput
{
    internal PolicyIndexInput(TypedInputReader reader) =>
        Reader = reader ?? throw new ArgumentNullException(nameof(reader));

    internal TypedInputReader Reader { get; }
}

internal sealed class RepositoryTreeIndex(
    ModelTypeToken<RepositoryTreeModel> inputModel) :
    IContextIndexer<PolicyIndexInput, IRepositoryTree>
{
    private readonly ModelTypeToken<RepositoryTreeModel> _inputModel =
        inputModel ?? throw new ArgumentNullException(nameof(inputModel));

    public CapabilityIntent<IRepositoryTree> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var model = input.Value.Reader.RequireModel(_inputModel);
        var entries = model.Value.Entries.Select(entry => RepositoryEntryView.Create(
            entry.RepositoryRelativePath,
            entry.Kind,
            input.Derivations.Derive(
                model.Evidence,
                "repository-entry",
                entry.RepositoryRelativePath,
                model.Value.Binding.Location))).ToArray();
        return CapabilityIntent<IRepositoryTree>.Produced(
            CapabilityProduct<IRepositoryTree>.Create(
                new RepositoryTreeCapability(entries),
                entries.Select(entry => entry.Evidence),
                Usage(entries.Length)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        IRepositoryTree value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value.Entries.Count);
    }

    private static SemanticResourceLocalUsage Usage(int nodes) =>
        SemanticResourceLocalUsage.Create(
            generatedBytes: 0,
            layerDepth: nodes == 0 ? 0 : 1,
            layerNodes: nodes,
            additionalComplexity: nodes);
}

internal sealed class ProtocolRecordIndex(
    ModelTypeToken<MarkdownDocumentModel> inputModel) :
    IContextIndexer<PolicyIndexInput, IProtocolRecordIndex>
{
    private const string DecisionKind = "protocol.record.decision";
    private const string ReferenceKind = "protocol.record.decision-reference";
    private static readonly string[] MetadataKeys =
    [
        "Classification", "Status", "Date", "Decision owners",
        "Related features", "Related decisions",
    ];
    private static readonly string[] SectionKeys =
    [
        "Context", "Decision", "Consequences", "Alternatives considered",
        "Review condition",
    ];
    private readonly ModelTypeToken<MarkdownDocumentModel> _inputModel =
        inputModel ?? throw new ArgumentNullException(nameof(inputModel));

    public CapabilityIntent<IProtocolRecordIndex> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var candidates = new List<RecordCandidate>();
        foreach (var model in input.Value.Reader.RequireModels(_inputModel))
        {
            cancellationToken.ThrowIfCancellationRequested();
            AddCandidates(model, candidates);
        }

        var records = candidates
            .OrderBy(item => item.ModelOrdinal)
            .ThenBy(item => item.SourceOffset)
            .ThenBy(item => item.Kind, StringComparer.Ordinal)
            .Select((candidate, ordinal) => CreateRecord(
                input, candidate, ordinal))
            .ToArray();
        return CapabilityIntent<IProtocolRecordIndex>.Produced(
            CapabilityProduct<IProtocolRecordIndex>.Create(
                new ProtocolRecordCapability(records),
                records.Select(item => item.Evidence),
                Usage(records)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        IProtocolRecordIndex value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value.Records);
    }

    private static void AddCandidates(
        SealedModelHandle<MarkdownDocumentModel> model,
        ICollection<RecordCandidate> candidates)
    {
        var modelOrdinal = candidates.Count == 0
            ? 0
            : candidates.Max(item => item.ModelOrdinal) + 1;
        var source = model.Value.CanonicalText;
        var blocks = model.Value.Document.ToArray();
        var ownIds = new HashSet<int>();
        for (var index = 0; index < blocks.Length; index++)
        {
            if (blocks[index] is not HeadingBlock { Level: 1 } heading)
            {
                continue;
            }

            var headingText = InlineText(source, heading);
            if (!TryDecisionId(headingText, out var recordId))
            {
                continue;
            }

            var idOffset = heading.Inline?.Span.Start ?? heading.Span.Start;
            ownIds.Add(idOffset);
            var nextH1 = Array.FindIndex(
                blocks, index + 1,
                item => item is HeadingBlock { Level: 1 });
            if (nextH1 < 0)
            {
                nextH1 = blocks.Length;
            }

            candidates.Add(new RecordCandidate(
                modelOrdinal,
                heading.Span.Start,
                DecisionKind,
                recordId,
                model,
                Members(source, blocks, index, nextH1, headingText, recordId)));
        }

        for (var offset = 0; offset <= source.Length - 8; offset++)
        {
            if (ownIds.Contains(offset) || !TryDecisionId(source.AsSpan(offset), out var recordId))
            {
                continue;
            }

            candidates.Add(new RecordCandidate(
                modelOrdinal,
                offset,
                ReferenceKind,
                recordId,
                model,
                []));
            offset += 7;
        }
    }

    private static IReadOnlyList<string> Members(
        string source,
        IReadOnlyList<Block> blocks,
        int h1Index,
        int endIndex,
        string headingText,
        string recordId)
    {
        var members = new List<string>();
        if (headingText.StartsWith(recordId + " - ", StringComparison.Ordinal) &&
            !string.IsNullOrWhiteSpace(headingText[(recordId.Length + 3)..]))
        {
            members.Add("heading");
        }

        var firstH2 = endIndex;
        for (var index = h1Index + 1; index < endIndex; index++)
        {
            if (blocks[index] is HeadingBlock { Level: 2 })
            {
                firstH2 = index;
                break;
            }
        }

        var metadataLists = blocks
            .Skip(h1Index + 1)
            .Take(firstH2 - h1Index - 1)
            .OfType<ListBlock>()
            .ToArray();
        if (metadataLists.Length == 1 && metadataLists[0].IsOrdered)
        {
            foreach (var item in metadataLists[0].OfType<ListItemBlock>())
            {
                var text = ItemText(source, item);
                var separator = text.IndexOf(':');
                if (separator > 0 && !string.IsNullOrWhiteSpace(text[(separator + 1)..]))
                {
                    members.Add("metadata:" + text[..separator].Trim());
                }
            }
        }

        for (var index = firstH2; index < endIndex; index++)
        {
            if (blocks[index] is not HeadingBlock { Level: 2 } section)
            {
                continue;
            }

            var next = index + 1;
            while (next < endIndex && blocks[next] is not HeadingBlock { Level: 2 })
            {
                next++;
            }

            var bodyStart = section.Span.End + 1;
            var bodyEnd = next < endIndex ? blocks[next].Span.Start :
                blocks[endIndex - 1].Span.End + 1;
            if (bodyEnd > bodyStart &&
                !string.IsNullOrWhiteSpace(source[bodyStart..bodyEnd]))
            {
                members.Add("section:" + InlineText(source, section));
            }
        }

        return members;
    }

    private static ProtocolRecordView CreateRecord(
        ContextIndexInput<PolicyIndexInput> input,
        RecordCandidate candidate,
        int ordinal)
    {
        var evidence = input.Derivations.Derive(
            candidate.Model.Evidence,
            candidate.Kind == ReferenceKind
                ? "protocol.node.governed-record-reference"
                : "protocol.node.protocol-record",
            candidate.RecordId,
            candidate.Model.Value.Location);
        var members = candidate.MemberKeys.Select((key, memberOrdinal) =>
            ProtocolRecordMemberView.Create(
                key,
                memberOrdinal,
                input.Derivations.Derive(
                    evidence,
                    "protocol.node.protocol-record-member",
                    key,
                    candidate.Model.Value.Location)));
        return ProtocolRecordView.Create(
            candidate.Kind,
            candidate.RecordId,
            ordinal,
            evidence,
            members);
    }

    private static string ItemText(string source, ContainerBlock item)
    {
        foreach (var block in item)
        {
            if (block is ParagraphBlock paragraph)
            {
                return InlineText(source, paragraph);
            }

            if (block is ContainerBlock nested)
            {
                var result = ItemText(source, nested);
                if (result.Length != 0)
                {
                    return result;
                }
            }
        }

        return string.Empty;
    }

    private static string InlineText(string source, LeafBlock block)
    {
        var span = block.Inline?.Span ?? block.Span;
        return span.Start < 0 || span.End < span.Start
            ? string.Empty
            : source[span.Start..(span.End + 1)].Trim();
    }

    private static bool TryDecisionId(ReadOnlySpan<char> value, out string recordId)
    {
        if (value.Length >= 8 && value.StartsWith("DEC-") &&
            value.Slice(4, 4).IndexOfAnyExceptInRange('0', '9') < 0)
        {
            recordId = value[..8].ToString();
            return true;
        }

        recordId = string.Empty;
        return false;
    }

    private static SemanticResourceLocalUsage Usage(
        IReadOnlyList<ProtocolRecordView> records)
    {
        var nodes = records.Count + records.Sum(item => item.Members.Count);
        return SemanticResourceLocalUsage.Create(0, nodes == 0 ? 0 : 1, nodes, nodes);
    }

    private sealed record RecordCandidate(
        int ModelOrdinal,
        int SourceOffset,
        string Kind,
        string RecordId,
        SealedModelHandle<MarkdownDocumentModel> Model,
        IReadOnlyList<string> MemberKeys);
}

internal sealed class GovernedReferenceIndex :
    PolicyIndexer<IGovernedReferenceIndex>,
    IContextIndexer<PolicyIndexInput, IGovernedReferenceIndex>
{
    protected override IGovernedReferenceIndex CreateValue() =>
        new GovernedReferenceCapability([]);
}

internal sealed class RepositoryTargetResolutionIndex :
    PolicyIndexer<IRepositoryTargetResolutionIndex>,
    IContextIndexer<PolicyIndexInput, IRepositoryTargetResolutionIndex>
{
    protected override IRepositoryTargetResolutionIndex CreateValue() =>
        new RepositoryTargetResolutionCapability([]);
}

internal abstract class PolicyIndexer<TCapability>
    where TCapability : class, IEvidenceCapability
{
    protected abstract TCapability CreateValue();

    public CapabilityIntent<TCapability> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var value = CreateValue();
        return CapabilityIntent<TCapability>.Produced(
            CapabilityProduct<TCapability>.Create(
                value,
                [],
                Usage(value)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        TCapability value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value);
    }

    private static SemanticResourceLocalUsage Usage(TCapability value)
    {
        var nodes = value switch
        {
            IRepositoryTree tree => tree.Entries.Count,
            IProtocolRecordIndex records => records.Records.Count,
            IGovernedReferenceIndex references => references.References.Count,
            IRepositoryTargetResolutionIndex targets => targets.Targets.Count,
            _ => 0,
        };
        return SemanticResourceLocalUsage.Create(
            generatedBytes: 0,
            layerDepth: nodes == 0 ? 0 : 1,
            layerNodes: nodes,
            additionalComplexity: nodes);
    }
}
