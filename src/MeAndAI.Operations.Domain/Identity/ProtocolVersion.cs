namespace MeAndAI.Operations.Domain.Identity;

public sealed record ProtocolVersion
{
    private ProtocolVersion(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static ProtocolVersion Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return IsCanonical(value)
            ? new ProtocolVersion(value)
            : throw new ArgumentException(
                "A protocol version must use the exact ASCII M.m.rev grammar without leading zeros.",
                nameof(value));
    }

    public override string ToString() => Value;

    private static bool IsCanonical(string value)
    {
        var componentStart = 0;
        var componentCount = 0;

        for (var index = 0; index <= value.Length; index++)
        {
            if (index < value.Length && value[index] != '.')
            {
                if (value[index] is < '0' or > '9')
                {
                    return false;
                }

                continue;
            }

            var componentLength = index - componentStart;
            if (componentLength == 0 ||
                (componentLength > 1 && value[componentStart] == '0'))
            {
                return false;
            }

            componentCount++;
            componentStart = index + 1;
        }

        return componentCount == 3;
    }
}
