using System.Text.Json;
using System.Text.Json.Serialization;

namespace MeAndAI.Operations.Packaging;

internal static class StrictJson
{
    private const int MaximumJsonBytes = 64 * 1024;

    internal static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = false,
        ReadCommentHandling = JsonCommentHandling.Disallow,
        AllowTrailingCommas = false,
        UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        WriteIndented = true,
    };

    internal static T Read<T>(string path, string surface)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        ArgumentException.ThrowIfNullOrWhiteSpace(surface);

        var file = new FileInfo(path);
        if (!file.Exists ||
            (file.Attributes & FileAttributes.ReparsePoint) != 0 ||
            file.Length is <= 0 or > MaximumJsonBytes)
        {
            throw new InvalidDataException(
                $"{surface} must be one bounded regular non-empty file.");
        }

        var bytes = File.ReadAllBytes(file.FullName);
        try
        {
            using var document = Parse(bytes, surface);
            return document.RootElement.Deserialize<T>(SerializerOptions)
                ?? throw new InvalidDataException($"{surface} is empty.");
        }
        catch (JsonException exception)
        {
            throw new InvalidDataException(
                $"{surface} is not strict UTF-8 JSON.",
                exception);
        }
    }

    internal static JsonDocument Parse(
        ReadOnlyMemory<byte> bytes,
        string surface)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(surface);
        if (bytes.IsEmpty || bytes.Length > MaximumJsonBytes)
        {
            throw new InvalidDataException(
                $"{surface} must be bounded and non-empty.");
        }

        var span = bytes.Span;
        if (span.Length >= 3 &&
            span[0] == 0xef &&
            span[1] == 0xbb &&
            span[2] == 0xbf)
        {
            throw new InvalidDataException($"{surface} must not contain a UTF-8 BOM.");
        }

        try
        {
            var document = JsonDocument.Parse(
                bytes,
                new JsonDocumentOptions
                {
                    AllowTrailingCommas = false,
                    CommentHandling = JsonCommentHandling.Disallow,
                    MaxDepth = 32,
                });
            try
            {
                AssertUniqueProperties(document.RootElement, surface);
                return document;
            }
            catch (InvalidDataException)
            {
                document.Dispose();
                throw;
            }
        }
        catch (JsonException exception)
        {
            throw new InvalidDataException(
                $"{surface} is not strict UTF-8 JSON.",
                exception);
        }
    }

    internal static JsonDocument Parse(Stream stream, string surface)
    {
        ArgumentNullException.ThrowIfNull(stream);
        ArgumentException.ThrowIfNullOrWhiteSpace(surface);
        using var buffered = new MemoryStream();
        var buffer = new byte[8192];
        while (true)
        {
            var read = stream.Read(buffer, 0, buffer.Length);
            if (read == 0)
            {
                break;
            }

            if (buffered.Length + read > MaximumJsonBytes)
            {
                throw new InvalidDataException(
                    $"{surface} must be bounded and non-empty.");
            }

            buffered.Write(buffer, 0, read);
        }

        return Parse(buffered.ToArray(), surface);
    }

    internal static byte[] Write<T>(T value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return [.. JsonSerializer.SerializeToUtf8Bytes(value, SerializerOptions), (byte)'\n'];
    }

    private static void AssertUniqueProperties(JsonElement element, string surface)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Object:
                {
                    var names = new HashSet<string>(StringComparer.Ordinal);
                    foreach (var property in element.EnumerateObject())
                    {
                        if (!names.Add(property.Name))
                        {
                            throw new InvalidDataException(
                                $"{surface} contains duplicate property '{property.Name}'.");
                        }

                        AssertUniqueProperties(property.Value, surface);
                    }

                    break;
                }

            case JsonValueKind.Array:
                foreach (var item in element.EnumerateArray())
                {
                    AssertUniqueProperties(item, surface);
                }

                break;
        }
    }
}
