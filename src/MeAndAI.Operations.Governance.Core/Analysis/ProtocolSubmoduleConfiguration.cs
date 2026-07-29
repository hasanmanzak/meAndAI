using System.Text;

namespace MeAndAI.Operations.Governance.Core.Analysis;

internal sealed record ProtocolSubmoduleConfigurationAnalysis(
    bool IsReadable,
    bool HasReservedProtocolReference,
    bool HasCanonicalProtocolMapping);

internal static class ProtocolSubmoduleConfiguration
{
    private static readonly Encoding StrictUtf8 = new UTF8Encoding(
        encoderShouldEmitUTF8Identifier: false,
        throwOnInvalidBytes: true);

    internal static ProtocolSubmoduleConfigurationAnalysis Analyze(
        ReadOnlyMemory<byte> content)
    {
        if (content.Span.StartsWith(Encoding.UTF8.Preamble) ||
            content.Span.Contains((byte)'\r') ||
            content.Span.Contains((byte)'\0') ||
            (content.Length > 0 && content.Span[^1] != (byte)'\n'))
        {
            return Unreadable();
        }

        string configuration;
        try
        {
            configuration = StrictUtf8.GetString(content.Span);
        }
        catch (DecoderFallbackException)
        {
            return Unreadable();
        }

        var sections = new List<SubmoduleSection>();
        SubmoduleSection? current = null;
        foreach (var line in configuration.Split('\n')[..^1])
        {
            var trimmed = line.Trim(' ', '\t');
            if (trimmed.Length == 0 ||
                trimmed.StartsWith('#') ||
                trimmed.StartsWith(';'))
            {
                continue;
            }

            if (trimmed.StartsWith('['))
            {
                if (!TryParseSection(trimmed, out var name))
                {
                    return Unreadable();
                }

                current = new SubmoduleSection(name);
                sections.Add(current);
                continue;
            }

            if (current is null ||
                !TryParseProperty(trimmed, out var key, out var value))
            {
                return Unreadable();
            }

            current.Properties.Add(new KeyValuePair<string, string>(key, value));
        }

        var reserved = sections
            .Where(section =>
                ProtocolIntegrationPath.CollidesWithReservedPath(
                    section.Name) ||
                section.Properties.Any(property =>
                    string.Equals(
                        property.Key,
                        "path",
                        StringComparison.OrdinalIgnoreCase) &&
                    ProtocolIntegrationPath.CollidesWithReservedPath(
                        property.Value)))
            .ToArray();
        var canonical = reserved
            .Where(IsCanonicalProtocolSection)
            .ToArray();

        return new ProtocolSubmoduleConfigurationAnalysis(
            IsReadable: true,
            HasReservedProtocolReference: reserved.Length > 0,
            HasCanonicalProtocolMapping:
                reserved.Length == 1 && canonical.Length == 1);
    }

    private static bool TryParseSection(string line, out string name)
    {
        const string prefix = "[submodule \"";
        const string suffix = "\"]";
        name = string.Empty;
        if (!line.StartsWith(prefix, StringComparison.Ordinal) ||
            !line.EndsWith(suffix, StringComparison.Ordinal) ||
            line.Length <= prefix.Length + suffix.Length)
        {
            return false;
        }

        name = line[prefix.Length..^suffix.Length];
        return !name.Any(character =>
            char.IsControl(character) || character is '"' or '\\');
    }

    private static bool TryParseProperty(
        string line,
        out string key,
        out string value)
    {
        key = string.Empty;
        value = string.Empty;
        var separator = line.IndexOf('=');
        if (separator <= 0 || separator == line.Length - 1)
        {
            return false;
        }

        key = line[..separator].Trim(' ', '\t');
        value = line[(separator + 1)..].Trim(' ', '\t');
        return key.Length > 0 &&
            value.Length > 0 &&
            !key.Any(char.IsControl) &&
            !value.Any(char.IsControl);
    }

    private static bool IsCanonicalProtocolSection(SubmoduleSection section)
    {
        if (!string.Equals(
                section.Name,
                ProtocolIntegrationPath.Canonical,
                StringComparison.Ordinal) ||
            section.Properties.Count != 2)
        {
            return false;
        }

        var path = section.Properties
            .Where(property => string.Equals(
                property.Key,
                "path",
                StringComparison.Ordinal))
            .Select(property => property.Value)
            .ToArray();
        var urls = section.Properties
            .Where(property => string.Equals(
                property.Key,
                "url",
                StringComparison.Ordinal))
            .Select(property => property.Value)
            .ToArray();
        return path.Length == 1 &&
            string.Equals(
                path[0],
                ProtocolIntegrationPath.Canonical,
                StringComparison.Ordinal) &&
            urls.Length == 1 &&
            urls[0].Length > 0;
    }

    private static ProtocolSubmoduleConfigurationAnalysis Unreadable() =>
        new(
            IsReadable: false,
            HasReservedProtocolReference: false,
            HasCanonicalProtocolMapping: false);

    private sealed class SubmoduleSection(string name)
    {
        internal string Name { get; } = name;

        internal List<KeyValuePair<string, string>> Properties { get; } = [];
    }
}
