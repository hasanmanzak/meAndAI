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
        if (bytes.Length >= 3 &&
            bytes[0] == 0xef &&
            bytes[1] == 0xbb &&
            bytes[2] == 0xbf)
        {
            throw new InvalidDataException($"{surface} must not contain a UTF-8 BOM.");
        }

        try
        {
            using var document = JsonDocument.Parse(
                bytes,
                new JsonDocumentOptions
                {
                    AllowTrailingCommas = false,
                    CommentHandling = JsonCommentHandling.Disallow,
                    MaxDepth = 32,
                });
            AssertUniqueProperties(document.RootElement, surface);
            return JsonSerializer.Deserialize<T>(bytes, SerializerOptions)
                ?? throw new InvalidDataException($"{surface} is empty.");
        }
        catch (JsonException exception)
        {
            throw new InvalidDataException(
                $"{surface} is not strict UTF-8 JSON.",
                exception);
        }
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
