using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;
using Markdig.Syntax;
using Markdig.Syntax.Inlines;
using System.Text.RegularExpressions;

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

internal sealed class GovernedReferenceIndex(
    ModelTypeToken<MarkdownDocumentModel> inputModel) :
    IContextIndexer<PolicyIndexInput, IGovernedReferenceIndex>
{
    private static readonly Regex StableId = new(
        @"\b(?:DEC|TEST|SUBF|FIND|RISK)-[0-9]{4}\b",
        RegexOptions.CultureInvariant);
    private static readonly Regex RawHref = new(
        @"<a\s+[^>]*href\s*=",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
    private readonly ModelTypeToken<MarkdownDocumentModel> _inputModel =
        inputModel ?? throw new ArgumentNullException(nameof(inputModel));

    public CapabilityIntent<IGovernedReferenceIndex> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        var rows = new List<GovernedReferenceView>();
        foreach (var model in input.Value.Reader.RequireModels(_inputModel))
        {
            cancellationToken.ThrowIfCancellationRequested();
            AddMarkdownLinks(input, model, rows);
            AddRawForms(input, model, rows);
        }

        var value = new GovernedReferenceCapability(rows);
        return CapabilityIntent<IGovernedReferenceIndex>.Produced(
            CapabilityProduct<IGovernedReferenceIndex>.Create(
                value,
                rows.SelectMany(row => row.Target is null
                    ? [row.Reference]
                    : new[] { row.Reference, row.Target }),
                Usage(rows.Count)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        IGovernedReferenceIndex value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value.References.Count);
    }

    private static void AddMarkdownLinks(
        ContextIndexInput<PolicyIndexInput> input,
        SealedModelHandle<MarkdownDocumentModel> model,
        ICollection<GovernedReferenceView> rows)
    {
        foreach (var block in model.Value.Document)
        {
            AddBlock(input, model, block, rows);
        }
    }

    private static void AddBlock(
        ContextIndexInput<PolicyIndexInput> input,
        SealedModelHandle<MarkdownDocumentModel> model,
        Block block,
        ICollection<GovernedReferenceView> rows)
    {
        if (block is LeafBlock leaf)
        {
            for (var inline = leaf.Inline?.FirstChild;
                 inline is not null;
                 inline = inline.NextSibling)
            {
                AddInline(input, model, inline, rows);
            }
        }

        if (block is ContainerBlock container)
        {
            foreach (var child in container)
            {
                AddBlock(input, model, child, rows);
            }
        }
    }

    private static void AddInline(
        ContextIndexInput<PolicyIndexInput> input,
        SealedModelHandle<MarkdownDocumentModel> model,
        Inline inline,
        ICollection<GovernedReferenceView> rows)
    {
        if (inline is LinkInline { IsImage: false, Url: not null } link)
        {
            rows.Add(Create(input, model, link.Url, GovernedReferenceSyntax.Clickable));
            return;
        }

        if (inline is ContainerInline container)
        {
            for (var child = container.FirstChild;
                 child is not null;
                 child = child.NextSibling)
            {
                AddInline(input, model, child, rows);
            }
        }
    }

    private static void AddRawForms(
        ContextIndexInput<PolicyIndexInput> input,
        SealedModelHandle<MarkdownDocumentModel> model,
        ICollection<GovernedReferenceView> rows)
    {
        var source = model.Value.CanonicalText;
        foreach (Match match in RawHref.Matches(source))
        {
            rows.Add(Create(
                input,
                model,
                $"raw-html:{match.Index}",
                GovernedReferenceSyntax.UnsupportedAuthoringForm));
        }

        foreach (var line in source.Split('\n'))
        {
            if (line.Contains("](", StringComparison.Ordinal) ||
                RawHref.IsMatch(line))
            {
                continue;
            }

            foreach (Match match in StableId.Matches(line))
            {
                rows.Add(Create(
                    input,
                    model,
                    match.Value,
                    GovernedReferenceSyntax.NonClickable));
            }
        }
    }

    private static GovernedReferenceView Create(
        ContextIndexInput<PolicyIndexInput> input,
        SealedModelHandle<MarkdownDocumentModel> model,
        string targetText,
        GovernedReferenceSyntax syntax)
    {
        var shape = TargetShape.Parse(targetText, syntax);
        var reference = input.Derivations.Derive(
            model.Evidence,
            "protocol.node.governed-reference",
            targetText,
            model.Value.Location);
        var target = shape.Resolution.Equals(GovernedReferenceResolution.Exact)
            ? input.Derivations.Derive(
                reference,
                "protocol.node.governed-reference-target",
                shape.Path ?? shape.Fragment ?? targetText,
                model.Value.Location)
            : null;
        return GovernedReferenceView.Create(
            shape.Kind,
            syntax,
            shape.Resolution,
            shape.Owner,
            shape.Commit,
            shape.Tag,
            shape.Capture,
            shape.Path,
            shape.Fragment,
            reference,
            target);
    }

    private static SemanticResourceLocalUsage Usage(int count) =>
        SemanticResourceLocalUsage.Create(0, count == 0 ? 0 : 1, count, count);

    private sealed record TargetShape(
        GovernedReferenceKind Kind,
        GovernedReferenceResolution Resolution,
        string? Owner,
        string? Commit,
        string? Tag,
        string? Capture,
        string? Path,
        string? Fragment)
    {
        internal static TargetShape Parse(
            string value,
            GovernedReferenceSyntax syntax)
        {
            if (!syntax.Equals(GovernedReferenceSyntax.Clickable))
            {
                return new(
                    GovernedReferenceKind.EmbeddedRecord,
                    GovernedReferenceResolution.Unresolved,
                    null, null, null, null, null,
                    StableId.Match(value).Success
                        ? value.ToLowerInvariant()
                        : null);
            }

            const string github = "https://github.com/";
            var fragmentAt = value.IndexOf('#');
            var fragment = fragmentAt < 0 ? null : value[(fragmentAt + 1)..];
            var withoutFragment = fragmentAt < 0 ? value : value[..fragmentAt];
            if (withoutFragment.StartsWith(github, StringComparison.Ordinal))
            {
                var parts = withoutFragment[github.Length..].Split('/');
                if (parts.Length == 4 && parts[2] == "commit" &&
                    IsObjectId(parts[3]))
                {
                    return new(
                        GovernedReferenceKind.Commit,
                        GovernedReferenceResolution.ExternalEvidenceRequired,
                        github + parts[0] + "/" + parts[1],
                        parts[3], null, null, null, fragment);
                }

                if (parts.Length >= 5 && parts[2] == "blob")
                {
                    var path = string.Join('/', parts.Skip(4));
                    return new(
                        IsStableFragment(fragment)
                            ? GovernedReferenceKind.EmbeddedRecord
                            : GovernedReferenceKind.CrossRecord,
                        GovernedReferenceResolution.ExternalEvidenceRequired,
                        github + parts[0] + "/" + parts[1],
                        IsObjectId(parts[3]) ? parts[3] : null,
                        IsObjectId(parts[3]) ? null : parts[3],
                        null, path, fragment);
                }

                return new(
                    GovernedReferenceKind.CrossRecord,
                    GovernedReferenceResolution.Unresolved,
                    null, null, null, null, null, fragment);
            }

            if (Uri.TryCreate(withoutFragment, UriKind.Absolute, out _))
            {
                return new(
                    GovernedReferenceKind.CrossRecord,
                    GovernedReferenceResolution.ExternalEvidenceRequired,
                    null, null, null, null, withoutFragment, fragment);
            }

            var resolution = string.IsNullOrWhiteSpace(withoutFragment)
                ? GovernedReferenceResolution.WrongTarget
                : string.IsNullOrWhiteSpace(fragment)
                    ? GovernedReferenceResolution.MissingFragment
                    : GovernedReferenceResolution.Exact;
            return new(
                IsStableFragment(fragment)
                    ? GovernedReferenceKind.EmbeddedRecord
                    : GovernedReferenceKind.CrossRecord,
                resolution,
                null, null, null, null,
                string.IsNullOrWhiteSpace(withoutFragment)
                    ? null
                    : withoutFragment.Replace('\\', '/'),
                fragment);
        }

        private static bool IsObjectId(string value) =>
            value.Length == 40 && value.All(character =>
                character is >= '0' and <= '9' or >= 'a' and <= 'f');

        private static bool IsStableFragment(string? value) =>
            value is not null && StableId.IsMatch(value.ToUpperInvariant());
    }
}

internal sealed class RepositoryTargetResolutionIndex(
    CapabilityTypeToken<IGovernedReferenceIndex> governedCapability,
    ModelTypeToken<RepositoryTargetResolutionModel> targetModel,
    ModelTypeToken<RepositoryTargetMarkdownDocumentSetModel> targetMarkdownModel) :
    IContextIndexer<PolicyIndexInput, IRepositoryTargetResolutionIndex>
{
    private readonly CapabilityTypeToken<IGovernedReferenceIndex> _governedCapability =
        governedCapability ?? throw new ArgumentNullException(nameof(governedCapability));
    private readonly ModelTypeToken<RepositoryTargetResolutionModel> _targetModel =
        targetModel ?? throw new ArgumentNullException(nameof(targetModel));
    private readonly ModelTypeToken<RepositoryTargetMarkdownDocumentSetModel>
        _targetMarkdownModel = targetMarkdownModel ??
            throw new ArgumentNullException(nameof(targetMarkdownModel));

    public CapabilityIntent<IRepositoryTargetResolutionIndex> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var governed = input.Value.Reader.RequireCapability(_governedCapability).Value;
        _ = input.Value.Reader.RequireModels(_targetMarkdownModel);
        var targets = new List<RepositoryTargetResolutionView>();
        if (governed.References.Count == 0)
        {
            var empty = new RepositoryTargetResolutionCapability(targets);
            return CapabilityIntent<IRepositoryTargetResolutionIndex>.Produced(
                CapabilityProduct<IRepositoryTargetResolutionIndex>.Create(
                    empty, [], Usage(0)));
        }

        foreach (var model in input.Value.Reader.RequireModels(_targetModel))
        {
            foreach (var row in model.Value.Rows)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var binding = input.Value.Reader.RequireDemandBinding(
                    row.DemandItem.ItemId);
                if (!governed.References.Any(reference =>
                        ReferenceEquals(reference.Reference, binding.SourceReference)))
                {
                    throw new InvalidOperationException(
                        "The target row does not bind a governed reference.");
                }

                var evidence = input.Derivations.Derive(
                    model.Evidence,
                    "protocol.node.repository-target-resolution",
                    row.DemandItem.ItemId.ToString(
                        System.Globalization.CultureInfo.InvariantCulture),
                    model.Value.Binding.Location);
                var shape = row.Accept(new TargetRowVisitor());
                var target = shape.HasTarget
                    ? input.Derivations.Derive(
                        evidence,
                        "protocol.node.repository-target",
                        row.DemandItem.NormalizedRepositoryRelativePath ??
                            row.DemandItem.OwningRepositoryIdentity,
                        model.Value.Binding.Location)
                    : null;
                targets.Add(RepositoryTargetResolutionView.Create(
                    binding.SourceReference,
                    shape.Resolution,
                    evidence,
                    shape.HasCommit ? evidence : null,
                    shape.HasTag ? evidence : null,
                    target));
            }
        }

        var value = new RepositoryTargetResolutionCapability(targets);
        return CapabilityIntent<IRepositoryTargetResolutionIndex>.Produced(
            CapabilityProduct<IRepositoryTargetResolutionIndex>.Create(
                value,
                targets.Select(item => item.ResolutionEvidence),
                Usage(targets.Count)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        IRepositoryTargetResolutionIndex value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value.Targets.Count);
    }

    private static SemanticResourceLocalUsage Usage(int count) =>
        SemanticResourceLocalUsage.Create(0, count == 0 ? 0 : 1, count, count);

    private sealed record RowShape(
        GovernedReferenceResolution Resolution,
        bool HasCommit,
        bool HasTag,
        bool HasTarget);

    private sealed class TargetRowVisitor :
        IRepositoryTargetResolutionPayloadRowVisitor<RowShape>
    {
        public RowShape VisitMissingCommit(
            RepositoryTargetResolutionDemandItem demandItem) =>
            new(GovernedReferenceResolution.Unresolved, false, false, false);

        public RowShape VisitPresentCommit(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedType,
            string observedIdentity) =>
            Commit(demandItem, observedOwner, observedType, observedIdentity, null);

        public RowShape VisitPresentCommitMissingPath(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedType,
            string observedIdentity) =>
            Commit(demandItem, observedOwner, observedType, observedIdentity, false);

        public RowShape VisitPresentCommitPath(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedType,
            string observedIdentity,
            string observedPath,
            string observedPathType,
            string observedPathIdentity,
            RepositoryTargetResolutionContent? content)
        {
            var commit = Commit(
                demandItem, observedOwner, observedType, observedIdentity, true);
            if (!commit.Resolution.Equals(GovernedReferenceResolution.Exact))
            {
                return commit;
            }

            return string.Equals(
                    demandItem.NormalizedRepositoryRelativePath,
                    observedPath,
                    StringComparison.Ordinal)
                ? commit
                : new(GovernedReferenceResolution.WrongTarget, true, false, true);
        }

        public RowShape VisitMissingTag(
            RepositoryTargetResolutionDemandItem demandItem) =>
            new(GovernedReferenceResolution.Unresolved, false, false, false);

        public RowShape VisitPresentTag(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedRefName,
            string observedRefType,
            string observedRefIdentity,
            string observedPeeledType,
            string observedPeeledIdentity)
        {
            var expected = "refs/tags/" + demandItem.NormalizedTagName;
            var exact = string.Equals(
                    demandItem.OwningRepositoryIdentity,
                    observedOwner,
                    StringComparison.Ordinal) &&
                string.Equals(expected, observedRefName, StringComparison.Ordinal) &&
                observedPeeledType == "commit";
            return new(
                exact ? GovernedReferenceResolution.Exact :
                    GovernedReferenceResolution.WrongTarget,
                false, true, exact);
        }

        public RowShape VisitMissingCapturedPath(
            RepositoryTargetResolutionDemandItem demandItem) =>
            new(GovernedReferenceResolution.Unresolved, false, false, false);

        public RowShape VisitPresentCapturedPath(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedCapture,
            string observedPath,
            string observedEntryKind,
            string observedContentIdentity,
            RepositoryTargetResolutionContent content)
        {
            var exact = string.Equals(
                    demandItem.OwningRepositoryIdentity,
                    observedOwner,
                    StringComparison.Ordinal) &&
                string.Equals(
                    demandItem.CapturedSnapshotIdentity,
                    observedCapture,
                    StringComparison.Ordinal) &&
                string.Equals(
                    demandItem.NormalizedRepositoryRelativePath,
                    observedPath,
                    StringComparison.Ordinal) &&
                observedEntryKind == "file";
            return new(
                exact ? GovernedReferenceResolution.Exact :
                    GovernedReferenceResolution.WrongTarget,
                false, false, exact);
        }

        private static RowShape Commit(
            RepositoryTargetResolutionDemandItem demandItem,
            string owner,
            string type,
            string identity,
            bool? pathPresent)
        {
            if (!string.Equals(
                    demandItem.OwningRepositoryIdentity,
                    owner,
                    StringComparison.Ordinal))
            {
                return new(
                    GovernedReferenceResolution.WrongRepository,
                    true, false, pathPresent == true);
            }

            if (type != "commit" || !string.Equals(
                    demandItem.CommitObjectId,
                    identity,
                    StringComparison.Ordinal))
            {
                return new(
                    GovernedReferenceResolution.WrongObject,
                    true, false, pathPresent == true);
            }

            if (demandItem.NormalizedRepositoryRelativePath is not null &&
                pathPresent != true)
            {
                return new(
                    GovernedReferenceResolution.Unresolved,
                    true, false, false);
            }

            return new(
                GovernedReferenceResolution.Exact,
                true, false, pathPresent == true ||
                    demandItem.NormalizedRepositoryRelativePath is null);
        }
    }
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
