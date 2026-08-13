namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IRuleEvaluator
{
    ApplicabilityIntent EvaluateApplicability(
        RuleApplicabilityInput input,
        CancellationToken cancellationToken);

    EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken);
}
