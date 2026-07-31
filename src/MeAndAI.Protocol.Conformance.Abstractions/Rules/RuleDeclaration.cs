using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RuleDeclaration
{
    private RuleDeclaration(
        RuleId ruleId,
        RuleRevision ruleRevision,
        CatalogVersion catalogVersion,
        ExactSha256Digest normativeDigest,
        IReadOnlyList<NormativeFragmentDeclaration> normativeFragments,
        IReadOnlyList<TestScenarioId> qualificationScenarios,
        ComponentTypeIdentity evaluator,
        IReadOnlyList<EvidenceSlotDeclaration> applicabilitySlots,
        IReadOnlyList<EvidenceSlotDeclaration> evaluationSlots,
        IReadOnlyList<ExpectedSelectorDeclaration> expectedSelectors,
        IReadOnlyList<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IReadOnlyList<SnapshotKind> snapshotKinds,
        IReadOnlyList<ProtocolOperation> operations,
        IReadOnlyList<FindingDeclaration> findings,
        IReadOnlyList<EvaluationFailureCode> evaluationFailureCodes,
        string introducedIn,
        string? deprecatedIn,
        string? retiredIn,
        IReadOnlyList<string> compatibilityAliases)
    {
        RuleId = ruleId;
        RuleRevision = ruleRevision;
        CatalogVersion = catalogVersion;
        NormativeDigest = normativeDigest;
        NormativeFragments = normativeFragments;
        QualificationScenarios = qualificationScenarios;
        Evaluator = evaluator;
        ApplicabilitySlots = applicabilitySlots;
        EvaluationSlots = evaluationSlots;
        ExpectedSelectors = expectedSelectors;
        SubjectRoles = subjectRoles;
        Surfaces = surfaces;
        SnapshotKinds = snapshotKinds;
        Operations = operations;
        Findings = findings;
        EvaluationFailureCodes = evaluationFailureCodes;
        IntroducedIn = introducedIn;
        DeprecatedIn = deprecatedIn;
        RetiredIn = retiredIn;
        CompatibilityAliases = compatibilityAliases;
    }

    public RuleId RuleId { get; }

    public RuleRevision RuleRevision { get; }

    public CatalogVersion CatalogVersion { get; }

    public ExactSha256Digest NormativeDigest { get; }

    public IReadOnlyList<NormativeFragmentDeclaration> NormativeFragments { get; }

    public IReadOnlyList<TestScenarioId> QualificationScenarios { get; }

    public ComponentTypeIdentity Evaluator { get; }

    public IReadOnlyList<EvidenceSlotDeclaration> ApplicabilitySlots { get; }

    public IReadOnlyList<EvidenceSlotDeclaration> EvaluationSlots { get; }

    public IReadOnlyList<ExpectedSelectorDeclaration> ExpectedSelectors { get; }

    public IReadOnlyList<SubjectRole> SubjectRoles { get; }

    public SurfaceSet Surfaces { get; }

    public IReadOnlyList<SnapshotKind> SnapshotKinds { get; }

    public IReadOnlyList<ProtocolOperation> Operations { get; }

    public IReadOnlyList<FindingDeclaration> Findings { get; }

    public IReadOnlyList<EvaluationFailureCode> EvaluationFailureCodes { get; }

    public string IntroducedIn { get; }

    public string? DeprecatedIn { get; }

    public string? RetiredIn { get; }

    public IReadOnlyList<string> CompatibilityAliases { get; }

    public static RuleDeclaration Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        CatalogVersion catalogVersion,
        ExactSha256Digest normativeDigest,
        IEnumerable<NormativeFragmentDeclaration> normativeFragments,
        IEnumerable<TestScenarioId> qualificationScenarios,
        ComponentTypeIdentity evaluator,
        IEnumerable<EvidenceSlotDeclaration> applicabilitySlots,
        IEnumerable<EvidenceSlotDeclaration> evaluationSlots,
        IEnumerable<ExpectedSelectorDeclaration> expectedSelectors,
        IEnumerable<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IEnumerable<SnapshotKind> snapshotKinds,
        IEnumerable<ProtocolOperation> operations,
        IEnumerable<FindingDeclaration> findings,
        IEnumerable<EvaluationFailureCode> evaluationFailureCodes,
        string introducedIn,
        string? deprecatedIn,
        string? retiredIn,
        IEnumerable<string> compatibilityAliases)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(ruleRevision);
        ArgumentNullException.ThrowIfNull(catalogVersion);
        ArgumentNullException.ThrowIfNull(normativeDigest);
        ArgumentNullException.ThrowIfNull(evaluator);
        ArgumentNullException.ThrowIfNull(surfaces);

        var canonicalFragments = DeclarationValidation.Snapshot(
            normativeFragments,
            nameof(normativeFragments),
            requireNonEmpty: true);
        ValidateDistinctFragments(canonicalFragments);

        var canonicalScenarios = DeclarationValidation.Canonicalize(
            qualificationScenarios,
            nameof(qualificationScenarios),
            item => item.Value,
            StringComparer.Ordinal,
            requireNonEmpty: true);
        var canonicalApplicability = CanonicalSlots(
            applicabilitySlots,
            nameof(applicabilitySlots));
        var canonicalEvaluation = CanonicalSlots(
            evaluationSlots,
            nameof(evaluationSlots));
        ValidateSharedSlots(canonicalApplicability, canonicalEvaluation);

        var canonicalFindings = DeclarationValidation.Canonicalize(
            findings,
            nameof(findings),
            item => item.Code.Value,
            StringComparer.Ordinal);
        var canonicalSelectors = DeclarationValidation.Canonicalize(
            expectedSelectors,
            nameof(expectedSelectors),
            item => item.SelectorKey,
            StringComparer.Ordinal);
        ValidateSelectors(
            canonicalSelectors,
            canonicalApplicability,
            canonicalEvaluation,
            canonicalFindings);

        var canonicalIntroduced = DeclarationValidation.ProtocolVersion(
            introducedIn,
            nameof(introducedIn));
        var canonicalDeprecated = deprecatedIn is null
            ? null
            : DeclarationValidation.ProtocolVersion(
                deprecatedIn,
                nameof(deprecatedIn));
        var canonicalRetired = retiredIn is null
            ? null
            : DeclarationValidation.ProtocolVersion(
                retiredIn,
                nameof(retiredIn));
        ValidateLifecycle(
            canonicalIntroduced,
            canonicalDeprecated,
            canonicalRetired);

        return new RuleDeclaration(
            ruleId,
            ruleRevision,
            catalogVersion,
            normativeDigest,
            canonicalFragments,
            canonicalScenarios,
            evaluator,
            canonicalApplicability,
            canonicalEvaluation,
            canonicalSelectors,
            CanonicalCategories(subjectRoles, nameof(subjectRoles), item => item.Value),
            surfaces,
            CanonicalCategories(snapshotKinds, nameof(snapshotKinds), item => item.Value),
            CanonicalCategories(operations, nameof(operations), item => item.Value),
            canonicalFindings,
            SemanticModelParserDeclaration.CanonicalFailureCodes(
                evaluationFailureCodes,
                nameof(evaluationFailureCodes)),
            canonicalIntroduced,
            canonicalDeprecated,
            canonicalRetired,
            DeclarationValidation.CanonicalTokens(
                compatibilityAliases,
                nameof(compatibilityAliases)));
    }

    private static IReadOnlyList<EvidenceSlotDeclaration> CanonicalSlots(
        IEnumerable<EvidenceSlotDeclaration>? slots,
        string parameterName) =>
        DeclarationValidation.Canonicalize(
            slots,
            parameterName,
            item => item.SlotKey,
            StringComparer.Ordinal);

    private static IReadOnlyList<T> CanonicalCategories<T>(
        IEnumerable<T>? values,
        string parameterName,
        Func<T, string> keySelector) where T : class =>
        DeclarationValidation.Canonicalize(
            values,
            parameterName,
            keySelector,
            StringComparer.Ordinal,
            requireNonEmpty: true);

    private static void ValidateDistinctFragments(
        IReadOnlyList<NormativeFragmentDeclaration> fragments)
    {
        var identities = new HashSet<(string Path, string Anchor)>();

        foreach (var fragment in fragments)
        {
            if (!identities.Add((fragment.Path, fragment.Anchor)))
            {
                throw new ArgumentException(
                    "Normative fragments must be distinct.",
                    nameof(fragments));
            }
        }
    }

    private static void ValidateSharedSlots(
        IReadOnlyList<EvidenceSlotDeclaration> applicability,
        IReadOnlyList<EvidenceSlotDeclaration> evaluation)
    {
        foreach (var left in applicability)
        {
            var right = evaluation.SingleOrDefault(item =>
                string.Equals(item.SlotKey, left.SlotKey, StringComparison.Ordinal));
            if (right is not null && !SlotsEqual(left, right))
            {
                throw new ArgumentException(
                    "A shared slot must be structurally identical in both phases.");
            }
        }
    }

    private static bool SlotsEqual(
        EvidenceSlotDeclaration left,
        EvidenceSlotDeclaration right) =>
        left.Requirement.Equals(right.Requirement) &&
        left.ProfileSurfaces.Equals(right.ProfileSurfaces) &&
        string.Equals(left.MaterialRole, right.MaterialRole, StringComparison.Ordinal) &&
        string.Equals(
            left.TargetSelectorKey,
            right.TargetSelectorKey,
            StringComparison.Ordinal) &&
        left.Capabilities.SequenceEqual(right.Capabilities);

    private static void ValidateSelectors(
        IReadOnlyList<ExpectedSelectorDeclaration> selectors,
        IReadOnlyList<EvidenceSlotDeclaration> applicability,
        IReadOnlyList<EvidenceSlotDeclaration> evaluation,
        IReadOnlyList<FindingDeclaration> findings)
    {
        var slotKeys = applicability
            .Concat(evaluation)
            .Select(item => item.SlotKey)
            .ToHashSet(StringComparer.Ordinal);
        var findingCodes = findings
            .Select(item => item.Code.Value)
            .ToHashSet(StringComparer.Ordinal);

        foreach (var selector in selectors)
        {
            if (!slotKeys.Contains(selector.SlotKey) ||
                selector.AllowedFindingCodes.Any(code =>
                    !findingCodes.Contains(code.Value)))
            {
                throw new ArgumentException(
                    "An expected selector references an undeclared slot or finding.");
            }
        }
    }

    private static void ValidateLifecycle(
        string introduced,
        string? deprecated,
        string? retired)
    {
        if (deprecated is not null &&
            DeclarationValidation.CompareProtocolVersions(
                introduced,
                deprecated) > 0)
        {
            throw new ArgumentException(
                "IntroducedIn must not follow DeprecatedIn.");
        }

        if (retired is not null &&
            DeclarationValidation.CompareProtocolVersions(
                deprecated ?? introduced,
                retired) > 0)
        {
            throw new ArgumentException(
                "DeprecatedIn must not follow RetiredIn.");
        }
    }
}
