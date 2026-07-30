using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class SubjectRole : IEquatable<SubjectRole>
{
    private const string ProtocolAuthoritySelfConsumerToken =
        "protocol-authority-self-consumer";
    private const string ConsumerToken = "consumer";

    private SubjectRole(string value)
    {
        Value = value;
    }

    public static SubjectRole ProtocolAuthoritySelfConsumer { get; } =
        new(ProtocolAuthoritySelfConsumerToken);

    public static SubjectRole Consumer { get; } = new(ConsumerToken);

    public string Value { get; }

    public static SubjectRole Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out SubjectRole? result)
    {
        result = value switch
        {
            ProtocolAuthoritySelfConsumerToken =>
                ProtocolAuthoritySelfConsumer,
            ConsumerToken => Consumer,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(SubjectRole? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is SubjectRole other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
