using System.Collections.ObjectModel;
using System.Text;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Analysis;

public sealed class MarkdownDocumentIndex
{
    private static readonly Encoding StrictUtf8 = new UTF8Encoding(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    private readonly IReadOnlyDictionary<string, MarkdownDocument> _documents;

    private MarkdownDocumentIndex(
        IReadOnlyDictionary<string, MarkdownDocument> documents)
    {
        _documents = documents;
        Documents = new ReadOnlyCollection<MarkdownDocument>(
            documents.Values
                .OrderBy(
                    document => document.RelativePath,
                    StringComparer.Ordinal)
                .ToArray());
    }

    public IReadOnlyList<MarkdownDocument> Documents { get; }

    internal static MarkdownDocumentIndex Create(
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        ArgumentNullException.ThrowIfNull(entries);

        var documents = new Dictionary<string, MarkdownDocument>(
            StringComparer.Ordinal);
        foreach (var entry in entries.Where(IsMarkdownFile))
        {
            string markdown;
            try
            {
                markdown = StrictUtf8.GetString(entry.CapturedContent);
            }
            catch (DecoderFallbackException exception)
            {
                throw new InvalidDataException(
                    $"Markdown document '{entry.RelativePath}' is not valid UTF-8.",
                    exception);
            }

            if (markdown.StartsWith('\uFEFF'))
            {
                markdown = markdown[1..];
            }

            documents.Add(
                entry.RelativePath,
                MarkdownDocument.Parse(entry.Path, markdown));
        }

        return new MarkdownDocumentIndex(documents);
    }

    public MarkdownDocument GetRequired(string relativePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);

        return _documents.TryGetValue(relativePath, out var document)
            ? document
            : throw new KeyNotFoundException(
                $"Markdown document '{relativePath}' does not exist in the repository snapshot.");
    }

    public MarkdownDocument GetRequired(RepositoryRelativePath path)
    {
        ArgumentNullException.ThrowIfNull(path);
        return GetRequired(path.Value);
    }

    public bool TryGet(
        string relativePath,
        out MarkdownDocument? document)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        return _documents.TryGetValue(relativePath, out document);
    }

    private static bool IsMarkdownFile(GovernanceRepositoryEntry entry) =>
        entry.Kind == GovernanceRepositoryEntryKind.File &&
        entry.RelativePath.EndsWith(".md", StringComparison.Ordinal);
}

public sealed class MarkdownDocument
{
    private MarkdownDocument(
        RepositoryRelativePath path,
        string? h1,
        string[] preambleLines,
        MarkdownMetadataField[] preambleMetadata,
        MarkdownSection[] h2Sections)
    {
        Path = path;
        H1 = h1;
        PreambleLines = new ReadOnlyCollection<string>(preambleLines);
        PreambleMetadata = new ReadOnlyCollection<MarkdownMetadataField>(
            preambleMetadata);
        H2Sections = new ReadOnlyCollection<MarkdownSection>(h2Sections);
    }

    public RepositoryRelativePath Path { get; }

    public string RelativePath => Path.Value;

    public string? H1 { get; }

    public IReadOnlyList<string> PreambleLines { get; }

    public IReadOnlyList<MarkdownMetadataField> PreambleMetadata { get; }

    public IReadOnlyList<MarkdownSection> H2Sections { get; }

    internal static MarkdownDocument Parse(
        RepositoryRelativePath path,
        string markdown)
    {
        var preamble = new List<string>();
        var preambleMetadata = new List<MarkdownMetadataField>();
        var sections = new List<MutableMarkdownSection>();
        string? h1 = null;
        MutableMarkdownSection? currentSection = null;
        char fenceMarker = default;
        var fenceLength = 0;
        var insideHtmlComment = false;

        foreach (var line in SplitLines(markdown))
        {
            if (fenceLength > 0)
            {
                AddContentLine(preamble, currentSection, line);
                if (IsClosingFence(line, fenceMarker, fenceLength))
                {
                    fenceMarker = default;
                    fenceLength = 0;
                }

                continue;
            }

            if (!insideHtmlComment &&
                TryGetOpeningFence(
                    line,
                    out fenceMarker,
                    out fenceLength))
            {
                AddContentLine(preamble, currentSection, line);
                continue;
            }

            var structuralLine = MaskHtmlComments(
                line,
                ref insideHtmlComment);

            if (h1 is null &&
                TryGetAtxHeading(structuralLine, 1, out var heading))
            {
                h1 = heading;
                continue;
            }

            if (TryGetAtxHeading(structuralLine, 2, out heading))
            {
                currentSection = new MutableMarkdownSection(heading);
                sections.Add(currentSection);
                continue;
            }

            if (currentSection is null &&
                TryGetMetadataField(
                    structuralLine,
                    out var metadataField))
            {
                preambleMetadata.Add(metadataField);
            }

            AddContentLine(preamble, currentSection, line);
        }

        return new MarkdownDocument(
            path,
            h1,
            preamble.ToArray(),
            preambleMetadata.ToArray(),
            sections
                .Select(section => section.ToImmutable())
                .ToArray());
    }

    private static IEnumerable<string> SplitLines(string markdown)
    {
        if (markdown.Length == 0)
        {
            return [];
        }

        var lines = markdown
            .Replace("\r\n", "\n", StringComparison.Ordinal)
            .Replace('\r', '\n')
            .Split('\n');
        return lines[^1].Length == 0 ? lines[..^1] : lines;
    }

    private static string MaskHtmlComments(
        string line,
        ref bool insideComment)
    {
        char[]? masked = null;
        var cursor = 0;
        while (cursor < line.Length)
        {
            if (insideComment)
            {
                var closing = line.IndexOf(
                    "-->",
                    cursor,
                    StringComparison.Ordinal);
                if (closing < 0)
                {
                    Mask(cursor, line.Length - cursor);
                    break;
                }

                Mask(cursor, closing + 3 - cursor);
                insideComment = false;
                cursor = closing + 3;
                continue;
            }

            var opening = line.IndexOf(
                "<!--",
                cursor,
                StringComparison.Ordinal);
            if (opening < 0)
            {
                break;
            }

            var closingOnLine = line.IndexOf(
                "-->",
                opening + 4,
                StringComparison.Ordinal);
            if (closingOnLine < 0)
            {
                Mask(opening, line.Length - opening);
                insideComment = true;
                break;
            }

            Mask(opening, closingOnLine + 3 - opening);
            cursor = closingOnLine + 3;
        }

        return masked is null ? line : new string(masked);

        void Mask(int start, int length)
        {
            masked ??= line.ToCharArray();
            Array.Fill(masked, ' ', start, length);
        }
    }

    private static void AddContentLine(
        ICollection<string> preamble,
        MutableMarkdownSection? currentSection,
        string line)
    {
        if (currentSection is null)
        {
            preamble.Add(line);
        }
        else
        {
            currentSection.BodyLines.Add(line);
        }
    }

    private static bool TryGetAtxHeading(
        string line,
        int level,
        out string heading)
    {
        heading = string.Empty;
        if (line.Length < level ||
            !line.AsSpan(0, level).SequenceEqual(
                new string('#', level).AsSpan()) ||
            (line.Length > level &&
             line[level] is not (' ' or '\t')))
        {
            return false;
        }

        var content = TrimHorizontalWhitespace(line.AsSpan(level));
        var closingHashStart = content.Length;
        while (closingHashStart > 0 &&
               content[closingHashStart - 1] == '#')
        {
            closingHashStart--;
        }

        if (closingHashStart < content.Length &&
            closingHashStart > 0 &&
            content[closingHashStart - 1] is ' ' or '\t')
        {
            content = TrimHorizontalWhitespaceEnd(
                content[..closingHashStart]);
        }

        heading = content.ToString();
        return true;
    }

    private static bool TryGetOpeningFence(
        string line,
        out char marker,
        out int length)
    {
        marker = default;
        length = 0;
        var content = RemoveFenceIndent(line.AsSpan());
        if (content.Length < 3 || content[0] is not ('`' or '~'))
        {
            return false;
        }

        marker = content[0];
        while (length < content.Length && content[length] == marker)
        {
            length++;
        }

        if (length < 3 ||
            (marker == '`' && content[length..].Contains('`')))
        {
            marker = default;
            length = 0;
            return false;
        }

        return true;
    }

    private static bool TryGetMetadataField(
        string line,
        out MarkdownMetadataField field)
    {
        field = default!;
        if (!line.StartsWith("- ", StringComparison.Ordinal))
        {
            return false;
        }

        var separator = line.IndexOf(':', 2);
        if (separator <= 2)
        {
            return false;
        }

        var name = line[2..separator];
        if (string.IsNullOrWhiteSpace(name))
        {
            return false;
        }

        field = new MarkdownMetadataField(
            name,
            line[(separator + 1)..].Trim(' ', '\t'));
        return true;
    }

    private static bool IsClosingFence(
        string line,
        char marker,
        int openingLength)
    {
        var content = RemoveFenceIndent(line.AsSpan());
        var length = 0;
        while (length < content.Length && content[length] == marker)
        {
            length++;
        }

        return length >= openingLength &&
               TrimHorizontalWhitespace(content[length..]).Length == 0;
    }

    private static ReadOnlySpan<char> RemoveFenceIndent(
        ReadOnlySpan<char> line)
    {
        var indentation = 0;
        while (indentation < line.Length &&
               indentation < 3 &&
               line[indentation] == ' ')
        {
            indentation++;
        }

        return line[indentation..];
    }

    private static ReadOnlySpan<char> TrimHorizontalWhitespace(
        ReadOnlySpan<char> value)
    {
        var start = 0;
        while (start < value.Length && value[start] is ' ' or '\t')
        {
            start++;
        }

        return TrimHorizontalWhitespaceEnd(value[start..]);
    }

    private static ReadOnlySpan<char> TrimHorizontalWhitespaceEnd(
        ReadOnlySpan<char> value)
    {
        var end = value.Length;
        while (end > 0 && value[end - 1] is ' ' or '\t')
        {
            end--;
        }

        return value[..end];
    }

    private sealed class MutableMarkdownSection(string heading)
    {
        public string Heading { get; } = heading;

        public List<string> BodyLines { get; } = [];

        public MarkdownSection ToImmutable() =>
            new(Heading, BodyLines.ToArray());
    }
}

public sealed record MarkdownMetadataField(string Name, string Value);

public sealed class MarkdownSection
{
    internal MarkdownSection(string heading, string[] bodyLines)
    {
        Heading = heading;
        BodyLines = new ReadOnlyCollection<string>(bodyLines);
    }

    public string Heading { get; }

    public IReadOnlyList<string> BodyLines { get; }
}
