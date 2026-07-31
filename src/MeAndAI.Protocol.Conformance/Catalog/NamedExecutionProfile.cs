using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class NamedExecutionProfile
{
    internal NamedExecutionProfile(
        string name,
        ExecutionProfile axes,
        IEnumerable<RuleId> ruleIds)
    {
        Name = DeclarationValidation.Token(name, nameof(name));
        ArgumentNullException.ThrowIfNull(axes);

        Axes = axes;
        RuleIds = DeclarationValidation.Snapshot(ruleIds, nameof(ruleIds));
    }

    public string Name { get; }

    public ExecutionProfile Axes { get; }

    public IReadOnlyList<RuleId> RuleIds { get; }
}
