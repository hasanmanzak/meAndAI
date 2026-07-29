using System.Collections.ObjectModel;
using System.Globalization;
using System.Text;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance;

internal sealed class ExactGitObjectMetadata
{
    private ExactGitObjectMetadata(
        ExactGitObjectId requestedObjectId,
        ExactGitObjectId? returnedObjectId,
        ExactGitObjectType? objectType,
        long size)
    {
        RequestedObjectId = requestedObjectId;
        ReturnedObjectId = returnedObjectId;
        ObjectType = objectType;
        Size = size;
    }

    internal ExactGitObjectId RequestedObjectId { get; }

    internal ExactGitObjectId? ReturnedObjectId { get; }

    internal ExactGitObjectType? ObjectType { get; }

    internal long Size { get; }

    internal bool IsMissing => ReturnedObjectId is null;

    internal static ExactGitObjectMetadata Missing(
        ExactGitObjectId requestedObjectId) =>
        new(
            requestedObjectId,
            returnedObjectId: null,
            objectType: null,
            size: 0);

    internal static ExactGitObjectMetadata Present(
        ExactGitObjectId requestedObjectId,
        ExactGitObjectId returnedObjectId,
        ExactGitObjectType objectType,
        long size) =>
        new(
            requestedObjectId,
            returnedObjectId,
            objectType,
            size);
}

internal sealed class ExactGitObjectContent
{
    private readonly byte[] content;

    internal ExactGitObjectContent(
        ExactGitObjectMetadata metadata,
        ReadOnlySpan<byte> content)
    {
        ArgumentNullException.ThrowIfNull(metadata);
        Metadata = metadata;
        this.content = content.ToArray();
    }

    internal ExactGitObjectMetadata Metadata { get; }

    internal bool IsMissing => Metadata.IsMissing;

    internal ReadOnlyMemory<byte> Content => content.ToArray();
}

internal static class ExactGitOutputParser
{
    private static readonly Encoding StrictUtf8 = new UTF8Encoding(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    internal static IReadOnlyList<ExactGitTreeEntry> ParseTree(
        ReadOnlySpan<byte> output,
        ExactRepositoryAcquisitionLimits limits)
    {
        ArgumentNullException.ThrowIfNull(limits);
        var entries = new List<ExactGitTreeEntry>();
        var paths = new HashSet<string>(StringComparer.Ordinal);
        long aggregatePathBytes = 0;
        var cursor = 0;

        while (cursor < output.Length)
        {
            var terminatorOffset = output[cursor..].IndexOf((byte)0);
            if (terminatorOffset < 0)
            {
                throw FramingFailure();
            }

            var record = output.Slice(cursor, terminatorOffset);
            cursor += terminatorOffset + 1;
            if (record.IsEmpty || entries.Count >= limits.MaximumTreeEntries)
            {
                throw LimitOrFramingFailure();
            }

            var tab = record.IndexOf((byte)'\t');
            if (tab <= 0 || tab == record.Length - 1)
            {
                throw FramingFailure();
            }

            var header = record[..tab];
            var pathBytes = record[(tab + 1)..];
            if (pathBytes.Length > limits.MaximumPathUtf8Bytes)
            {
                throw LimitOrFramingFailure();
            }

            aggregatePathBytes = checked(aggregatePathBytes + pathBytes.Length);
            if (aggregatePathBytes >
                limits.MaximumAggregateTreePathUtf8Bytes)
            {
                throw LimitOrFramingFailure();
            }

            var firstSpace = header.IndexOf((byte)' ');
            var secondSpace = firstSpace < 0
                ? -1
                : header[(firstSpace + 1)..].IndexOf((byte)' ');
            if (firstSpace <= 0 || secondSpace <= 0)
            {
                throw FramingFailure();
            }

            secondSpace += firstSpace + 1;
            if (secondSpace >= header.Length - 1 ||
                header[(secondSpace + 1)..].Contains((byte)' '))
            {
                throw FramingFailure();
            }

            try
            {
                var mode = DecodeAscii(header[..firstSpace]);
                var objectType = DecodeAscii(
                    header[(firstSpace + 1)..secondSpace]);
                var objectId = ExactGitObjectId.Parse(
                    DecodeAscii(header[(secondSpace + 1)..]));
                var pathValue = StrictUtf8.GetString(pathBytes);
                if (pathValue.StartsWith('\uFEFF') || !paths.Add(pathValue))
                {
                    throw FramingFailure();
                }

                var path = RepositoryRelativePath.FromExactGit(pathValue);
                entries.Add(ExactGitTreeEntry.Create(
                    path,
                    mode,
                    objectType,
                    objectId));
            }
            catch (Exception exception) when (
                exception is ArgumentException or DecoderFallbackException)
            {
                throw new InvalidDataException(
                    "Git tree output contains an invalid canonical entry.",
                    exception);
            }
        }

        return new ReadOnlyCollection<ExactGitTreeEntry>(entries);
    }

    internal static ExactGitObjectMetadata ParseBatchCheck(
        ReadOnlySpan<byte> output,
        ExactGitObjectId requestedObjectId)
    {
        ArgumentNullException.ThrowIfNull(requestedObjectId);
        var line = GetSingleLine(output);
        return ParseMetadataLine(line, requestedObjectId);
    }

    internal static IReadOnlyList<ExactGitObjectContent> ParseBatchContents(
        ReadOnlySpan<byte> output,
        IReadOnlyList<ExactGitObjectId> requestedObjectIds,
        ExactRepositoryAcquisitionLimits limits)
    {
        ArgumentNullException.ThrowIfNull(requestedObjectIds);
        ArgumentNullException.ThrowIfNull(limits);
        var results = new List<ExactGitObjectContent>(
            requestedObjectIds.Count);
        long aggregateBlobBytes = 0;
        var cursor = 0;

        foreach (var requestedObjectId in requestedObjectIds)
        {
            ArgumentNullException.ThrowIfNull(requestedObjectId);
            var lineOffset = output[cursor..].IndexOf((byte)'\n');
            if (lineOffset < 0)
            {
                throw FramingFailure();
            }

            var line = output.Slice(cursor, lineOffset);
            cursor += lineOffset + 1;
            var metadata = ParseMetadataLine(line, requestedObjectId);
            if (metadata.IsMissing)
            {
                results.Add(new ExactGitObjectContent(
                    metadata,
                    ReadOnlySpan<byte>.Empty));
                continue;
            }

            if (metadata.Size > limits.MaximumSelectedBlobBytes ||
                metadata.Size > int.MaxValue)
            {
                throw LimitOrFramingFailure();
            }

            aggregateBlobBytes = checked(aggregateBlobBytes + metadata.Size);
            if (aggregateBlobBytes >
                limits.MaximumAggregateSelectedBlobBytes)
            {
                throw LimitOrFramingFailure();
            }

            var size = (int)metadata.Size;
            if (size > output.Length - cursor - 1 ||
                output[cursor + size] != (byte)'\n')
            {
                throw FramingFailure();
            }

            results.Add(new ExactGitObjectContent(
                metadata,
                output.Slice(cursor, size)));
            cursor += size + 1;
        }

        if (cursor != output.Length)
        {
            throw FramingFailure();
        }

        return new ReadOnlyCollection<ExactGitObjectContent>(results);
    }

    private static ExactGitObjectMetadata ParseMetadataLine(
        ReadOnlySpan<byte> line,
        ExactGitObjectId requestedObjectId)
    {
        var text = DecodeAscii(line);
        if (string.Equals(
                text,
                $"{requestedObjectId.Value} missing",
                StringComparison.Ordinal))
        {
            return ExactGitObjectMetadata.Missing(requestedObjectId);
        }

        var parts = text.Split(' ');
        if (parts.Length != 3 ||
            !string.Equals(
                parts[0],
                requestedObjectId.Value,
                StringComparison.Ordinal))
        {
            throw FramingFailure();
        }

        ExactGitObjectId returnedObjectId;
        try
        {
            returnedObjectId = ExactGitObjectId.Parse(parts[0]);
        }
        catch (ArgumentException exception)
        {
            throw new InvalidDataException(
                "Git object output contains an invalid object identity.",
                exception);
        }

        var objectType = parts[1] switch
        {
            "blob" => ExactGitObjectType.Blob,
            "tree" => ExactGitObjectType.Tree,
            "commit" => ExactGitObjectType.Commit,
            "tag" => ExactGitObjectType.Tag,
            _ => throw FramingFailure(),
        };
        if (!IsCanonicalDecimal(parts[2]) ||
            !long.TryParse(
                parts[2],
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out var size))
        {
            throw FramingFailure();
        }

        return ExactGitObjectMetadata.Present(
            requestedObjectId,
            returnedObjectId,
            objectType,
            size);
    }

    private static ReadOnlySpan<byte> GetSingleLine(ReadOnlySpan<byte> output)
    {
        if (output.Length < 2 || output[^1] != (byte)'\n')
        {
            throw FramingFailure();
        }

        var line = output[..^1];
        if (line.IsEmpty || line.Contains((byte)'\n'))
        {
            throw FramingFailure();
        }

        return line;
    }

    private static string DecodeAscii(ReadOnlySpan<byte> value)
    {
        if (value.IsEmpty || value.ContainsAnyExceptInRange((byte)0x20, (byte)0x7e))
        {
            throw FramingFailure();
        }

        return Encoding.ASCII.GetString(value);
    }

    private static bool IsCanonicalDecimal(string value) =>
        value.Length > 0 &&
        (value.Length == 1 || value[0] != '0') &&
        value.All(character => character is >= '0' and <= '9');

    private static InvalidDataException FramingFailure() =>
        new("Git object output does not use the required binary-safe framing.");

    private static InvalidDataException LimitOrFramingFailure() =>
        new("Git object output exceeds the bounded acquisition contract.");
}
