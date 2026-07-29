namespace MeAndAI.Operations.Domain.Identity;

public sealed record ProtocolReleaseTag
{
    private ProtocolReleaseTag(string value, ProtocolVersion version)
    {
        Value = value;
        Version = version;
    }

    public string Value { get; }

    public ProtocolVersion Version { get; }

    public static ProtocolReleaseTag Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (value.Length < 2 || value[0] != 'v')
        {
            throw new ArgumentException(
                "A protocol release tag must use a lowercase v followed by a canonical protocol version.",
                nameof(value));
        }

        var version = ProtocolVersion.Parse(value[1..]);
        return new ProtocolReleaseTag(value, version);
    }

    public override string ToString() => Value;
}
