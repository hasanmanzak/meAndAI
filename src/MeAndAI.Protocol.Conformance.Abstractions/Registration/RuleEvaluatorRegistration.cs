namespace MeAndAI.Protocol.Conformance.Abstractions;

internal sealed class RuleEvaluatorRegistration
{
    private RuleEvaluatorRegistration(
        RuleDeclaration declaration,
        IRuleEvaluator evaluator)
    {
        Declaration = declaration;
        Evaluator = evaluator;
    }

    internal RuleDeclaration Declaration { get; }

    internal IRuleEvaluator Evaluator { get; }

    internal static RuleEvaluatorRegistration Create(
        RuleDeclaration declaration,
        IRuleEvaluator evaluator)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(evaluator);
        return new RuleEvaluatorRegistration(declaration, evaluator);
    }
}
