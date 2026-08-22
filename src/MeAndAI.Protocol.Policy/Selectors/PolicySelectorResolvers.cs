using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Selectors;

internal abstract class PolicySelectorResolver(string canonicalSuffix) :
    IExpectedSelectorResolver
{
    public SelectorIntent Resolve(ExpectedSelectorInput input)
    {
        ArgumentNullException.ThrowIfNull(input);
        return SelectorIntent.Resolved(
            SelectorProduct.Create(
                input.Parent,
                string.Concat(input.ParentCanonicalValue, canonicalSuffix)));
    }
}

internal sealed class FeatureReadmeSelectorResolver() :
    PolicySelectorResolver("/README.md");

internal sealed class FeatureTestCasesSelectorResolver() :
    PolicySelectorResolver("/test-cases.md");

internal sealed class DecisionRecordSelectorResolver() :
    PolicySelectorResolver("");
