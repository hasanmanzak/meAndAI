using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Rules;

internal abstract class InitialRuleEvaluator : IRuleEvaluator
{
    public ApplicabilityIntent EvaluateApplicability(
        RuleApplicabilityInput input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException(
            "Rule evaluation is not active in the Policy surface packet.");

    public EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException(
            "Rule evaluation is not active in the Policy surface packet.");
}

internal sealed class FeaturePacketRuleEvaluator : InitialRuleEvaluator;

internal sealed class DecisionRecordRuleEvaluator : InitialRuleEvaluator;

internal sealed class ClickableExactTargetRuleEvaluator : InitialRuleEvaluator;

internal sealed class StableFragmentRuleEvaluator : InitialRuleEvaluator;

internal sealed class CommitPermalinkRuleEvaluator : InitialRuleEvaluator;
