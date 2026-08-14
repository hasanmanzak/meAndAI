using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Selectors;

internal abstract class PolicySelectorResolver : IExpectedSelectorResolver
{
    public SelectorIntent Resolve(ExpectedSelectorInput input)
    {
        ArgumentNullException.ThrowIfNull(input);
        return SelectorIntent.Resolved(
            SelectorProduct.Create(input.Parent, input.ParentCanonicalValue));
    }
}

internal sealed class FeatureReadmeSelectorResolver : PolicySelectorResolver;

internal sealed class FeatureTestCasesSelectorResolver : PolicySelectorResolver;

internal sealed class DecisionRecordSelectorResolver : PolicySelectorResolver;
