using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class NamedProfileDeclaration
{
    private NamedProfileDeclaration(
        string name,
        ExecutionProfile axes,
        IReadOnlyList<RuleId> ruleIds)
    {
        Name = name;
        Axes = axes;
        RuleIds = ruleIds;
    }

    public string Name { get; }

    public ExecutionProfile Axes { get; }

    public IReadOnlyList<RuleId> RuleIds { get; }

    public static NamedProfileDeclaration Create(
        string name,
        ExecutionProfile axes,
        IEnumerable<RuleId> ruleIds)
    {
        ArgumentNullException.ThrowIfNull(axes);

        return new NamedProfileDeclaration(
            DeclarationValidation.Token(name, nameof(name)),
            axes,
            DeclarationValidation.Canonicalize(
                ruleIds,
                nameof(ruleIds),
                item => item.Value,
                StringComparer.Ordinal));
    }
}
