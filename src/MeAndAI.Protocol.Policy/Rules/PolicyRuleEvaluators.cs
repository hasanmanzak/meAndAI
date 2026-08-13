using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Rules;

internal abstract class InitialRuleEvaluator : IRuleEvaluator
{
    public ApplicabilityIntent EvaluateApplicability(
        RuleApplicabilityInput input,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return ApplicabilityIntent.Applicable([]);
    }

    public EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return EvaluationIntent.Create([], []);
    }
}

internal sealed class FeaturePacketRuleEvaluator : InitialRuleEvaluator;

internal sealed class DecisionRecordRuleEvaluator : InitialRuleEvaluator;

internal sealed class ClickableExactTargetRuleEvaluator : InitialRuleEvaluator;

internal sealed class StableFragmentRuleEvaluator : InitialRuleEvaluator;

internal sealed class CommitPermalinkRuleEvaluator : InitialRuleEvaluator;
