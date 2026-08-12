using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class NamedExecutionProfile
{
    internal NamedExecutionProfile(
        string name,
        ExecutionProfile axes,
        IEnumerable<RuleId> ruleIds,
        KernelPlanningSession planningSession)
    {
        Name = DeclarationValidation.Token(name, nameof(name));
        ArgumentNullException.ThrowIfNull(axes);

        Axes = axes;
        RuleIds = DeclarationValidation.Snapshot(ruleIds, nameof(ruleIds));
        PlanningSession = planningSession ??
            throw new ArgumentNullException(nameof(planningSession));
    }

    public string Name { get; }

    public ExecutionProfile Axes { get; }

    public IReadOnlyList<RuleId> RuleIds { get; }

    internal KernelPlanningSession PlanningSession { get; }
}
