namespace MeAndAI.Protocol.Conformance;

public sealed class QualifiedEvidenceSelector
{
    internal QualifiedEvidenceSelector(
        string selectorKey,
        string selectorSchemaKey,
        string canonicalValue)
    {
        ArgumentNullException.ThrowIfNull(selectorKey);
        ArgumentNullException.ThrowIfNull(selectorSchemaKey);
        ArgumentNullException.ThrowIfNull(canonicalValue);

        SelectorKey = selectorKey;
        SelectorSchemaKey = selectorSchemaKey;
        CanonicalValue = canonicalValue;
    }

    public string SelectorKey { get; }

    public string SelectorSchemaKey { get; }

    public string CanonicalValue { get; }
}
