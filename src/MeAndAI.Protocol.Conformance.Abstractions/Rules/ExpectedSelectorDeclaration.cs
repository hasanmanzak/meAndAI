namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ExpectedSelectorDeclaration
{
    private ExpectedSelectorDeclaration(
        string selectorKey,
        string slotKey,
        string selectorSchemaKey,
        ComponentTypeIdentity resolver,
        IReadOnlyList<QualifiedEvidenceReferenceKind> allowedParentKinds,
        IReadOnlyList<FindingCode> allowedFindingCodes)
    {
        SelectorKey = selectorKey;
        SlotKey = slotKey;
        SelectorSchemaKey = selectorSchemaKey;
        Resolver = resolver;
        AllowedParentKinds = allowedParentKinds;
        AllowedFindingCodes = allowedFindingCodes;
    }

    public string SelectorKey { get; }

    public string SlotKey { get; }

    public string SelectorSchemaKey { get; }

    public ComponentTypeIdentity Resolver { get; }

    public IReadOnlyList<QualifiedEvidenceReferenceKind> AllowedParentKinds { get; }

    public IReadOnlyList<FindingCode> AllowedFindingCodes { get; }

    public static ExpectedSelectorDeclaration Create(
        string selectorKey,
        string slotKey,
        string selectorSchemaKey,
        ComponentTypeIdentity resolver,
        IEnumerable<QualifiedEvidenceReferenceKind> allowedParentKinds,
        IEnumerable<FindingCode> allowedFindingCodes)
    {
        ArgumentNullException.ThrowIfNull(resolver);

        return new ExpectedSelectorDeclaration(
            DeclarationValidation.Token(selectorKey, nameof(selectorKey)),
            DeclarationValidation.Token(slotKey, nameof(slotKey)),
            DeclarationValidation.Token(
                selectorSchemaKey,
                nameof(selectorSchemaKey)),
            resolver,
            CanonicalReferenceKinds(
                allowedParentKinds,
                nameof(allowedParentKinds),
                requireNonEmpty: true),
            DeclarationValidation.Canonicalize(
                allowedFindingCodes,
                nameof(allowedFindingCodes),
                item => item.Value,
                StringComparer.Ordinal,
                requireNonEmpty: true));
    }

    internal static IReadOnlyList<QualifiedEvidenceReferenceKind>
        CanonicalReferenceKinds(
            IEnumerable<QualifiedEvidenceReferenceKind>? kinds,
            string parameterName,
            bool requireNonEmpty = false)
    {
        var snapshot = DeclarationValidation.Snapshot(
            kinds,
            parameterName,
            requireNonEmpty);
        var ordered = snapshot.OrderBy(ReferenceKindRank).ToArray();
        if (ordered.Select(item => item.Value)
            .Distinct(StringComparer.Ordinal)
            .Count() != ordered.Length)
        {
            throw new ArgumentException(
                "The collection contains a duplicate reference kind.",
                parameterName);
        }

        return Array.AsReadOnly(ordered);
    }

    private static int ReferenceKindRank(QualifiedEvidenceReferenceKind kind)
    {
        if (kind.Equals(QualifiedEvidenceReferenceKind.ContextProof))
        {
            return 0;
        }

        if (kind.Equals(QualifiedEvidenceReferenceKind.Root))
        {
            return 1;
        }

        if (kind.Equals(QualifiedEvidenceReferenceKind.Derived))
        {
            return 2;
        }

        return 3;
    }
}
