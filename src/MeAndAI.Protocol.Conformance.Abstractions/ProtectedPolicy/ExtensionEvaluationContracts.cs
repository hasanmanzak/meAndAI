using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ExtensionApplicabilityInput
{
    private readonly IRuleInputAccess _access;

    private ExtensionApplicabilityInput(
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile,
        IRuleInputAccess access)
    {
        Extension = extension;
        Profile = profile;
        _access = access;
    }

    public ExtensionRuleDeclaration Extension { get; }
    public ExecutionProfile Profile { get; }

    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability =>
        _access.GetCapability<TCapability>(slotKey);

    public QualifiedEvidenceHandle GetContextProof(string slotKey) =>
        _access.GetContextProof(slotKey);

    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle) =>
        _access.GetExpectedReference(selectorKey, parentHandle);

    internal static ExtensionApplicabilityInput Create(
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile,
        IRuleInputAccess access)
    {
        ArgumentNullException.ThrowIfNull(extension);
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(access);
        return new ExtensionApplicabilityInput(extension, profile, access);
    }
}

public sealed class ExtensionEvaluationInput
{
    private readonly IRuleInputAccess _access;

    private ExtensionEvaluationInput(
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile,
        IRuleInputAccess access)
    {
        Extension = extension;
        Profile = profile;
        _access = access;
    }

    public ExtensionRuleDeclaration Extension { get; }
    public ExecutionProfile Profile { get; }

    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability =>
        _access.GetCapability<TCapability>(slotKey);

    public QualifiedEvidenceHandle GetContextProof(string slotKey) =>
        _access.GetContextProof(slotKey);

    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle) =>
        _access.GetExpectedReference(selectorKey, parentHandle);

    internal static ExtensionEvaluationInput Create(
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile,
        IRuleInputAccess access)
    {
        ArgumentNullException.ThrowIfNull(extension);
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(access);
        return new ExtensionEvaluationInput(extension, profile, access);
    }
}

public sealed class ExtensionParameterDeclaration
{
    private ExtensionParameterDeclaration(
        string key,
        string valueGrammar,
        int maximumUtf8Bytes)
    {
        Key = key;
        ValueGrammar = valueGrammar;
        MaximumUtf8Bytes = maximumUtf8Bytes;
    }

    public string Key { get; }
    public string ValueGrammar { get; }
    public int MaximumUtf8Bytes { get; }

    public static ExtensionParameterDeclaration Create(
        string key,
        string valueGrammar,
        int maximumUtf8Bytes)
    {
        if (maximumUtf8Bytes is < 0 or > 4096)
        {
            throw new ArgumentOutOfRangeException(nameof(maximumUtf8Bytes));
        }

        return new ExtensionParameterDeclaration(
            ProtectedPolicyFrame.ParameterKey(key, nameof(key)),
            ProtectedPolicyFrame.Text(valueGrammar, nameof(valueGrammar), 256),
            maximumUtf8Bytes);
    }
}

public sealed class ExtensionEvaluatorKindDeclaration
{
    private ExtensionEvaluatorKindDeclaration(
        string evaluatorKind,
        string evaluatorVersion,
        ComponentTypeIdentity component,
        IReadOnlyList<ExtensionParameterDeclaration> parameters,
        IReadOnlyList<string> applicabilitySlotKeys,
        IReadOnlyList<string> evaluationSlotKeys,
        IReadOnlyList<FindingDeclaration> findings,
        IReadOnlyList<EvaluationFailureCode> failureCodes,
        bool waiverAllowed)
    {
        EvaluatorKind = evaluatorKind;
        EvaluatorVersion = evaluatorVersion;
        Component = component;
        Parameters = parameters;
        ApplicabilitySlotKeys = applicabilitySlotKeys;
        EvaluationSlotKeys = evaluationSlotKeys;
        Findings = findings;
        FailureCodes = failureCodes;
        WaiverAllowed = waiverAllowed;
    }

    public string EvaluatorKind { get; }
    public string EvaluatorVersion { get; }
    public ComponentTypeIdentity Component { get; }
    public IReadOnlyList<ExtensionParameterDeclaration> Parameters { get; }
    public IReadOnlyList<string> ApplicabilitySlotKeys { get; }
    public IReadOnlyList<string> EvaluationSlotKeys { get; }
    public IReadOnlyList<FindingDeclaration> Findings { get; }
    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }
    public bool WaiverAllowed { get; }

    internal static ExtensionEvaluatorKindDeclaration Create(
        string evaluatorKind,
        string evaluatorVersion,
        ComponentTypeIdentity component,
        IEnumerable<ExtensionParameterDeclaration> parameters,
        IEnumerable<string> applicabilitySlotKeys,
        IEnumerable<string> evaluationSlotKeys,
        IEnumerable<FindingDeclaration> findings,
        IEnumerable<EvaluationFailureCode> failureCodes,
        bool waiverAllowed)
    {
        var kind = ProtectedPolicyFrame.LowerAsciiToken(evaluatorKind, nameof(evaluatorKind), 128);
        var version = ProtectedPolicyFrame.Text(evaluatorVersion, nameof(evaluatorVersion), 32);
        ArgumentNullException.ThrowIfNull(component);
        var parameterRows = ProtectedPolicyFrame.SortedUnique(
            parameters, static row => row.Key, nameof(parameters), 64);
        var applicability = CanonicalStrings(applicabilitySlotKeys, nameof(applicabilitySlotKeys));
        var evaluation = CanonicalStrings(evaluationSlotKeys, nameof(evaluationSlotKeys));
        if (applicability.Intersect(evaluation, StringComparer.Ordinal).Any())
        {
            throw new ArgumentException("Applicability and evaluation slots must be disjoint.");
        }

        var findingRows = ProtectedPolicyFrame.SortedUnique(
            findings, static row => row.Code.Value, nameof(findings));
        var failureRows = ProtectedPolicyFrame.SortedUnique(
            failureCodes, static row => row.Value, nameof(failureCodes));
        return new ExtensionEvaluatorKindDeclaration(
            kind, version, component, parameterRows, applicability, evaluation,
            findingRows, failureRows, waiverAllowed);
    }

    private static IReadOnlyList<string> CanonicalStrings(
        IEnumerable<string> values,
        string paramName)
    {
        ArgumentNullException.ThrowIfNull(values, paramName);
        return ProtectedPolicyFrame.SortedUnique(
            values.Select(value => ProtectedPolicyFrame.LowerAsciiToken(
                value, paramName, 128)),
            static value => value, paramName, 4_096);
    }
}

public sealed class ExtensionFindingIntent
{
    private ExtensionFindingIntent(
        FindingCode code,
        QualifiedEvidenceHandle primaryReference,
        IReadOnlyList<QualifiedEvidenceHandle> relatedReferences,
        string stableStateToken,
        string? stableStateValue)
    {
        Code = code;
        PrimaryReference = primaryReference;
        RelatedReferences = relatedReferences;
        StableStateToken = stableStateToken;
        StableStateValue = stableStateValue;
    }

    public FindingCode Code { get; }
    public QualifiedEvidenceHandle PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }
    public string StableStateToken { get; }
    public string? StableStateValue { get; }

    internal static ExtensionFindingIntent Create(
        FindingCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences,
        string stableStateToken,
        string? stableStateValue)
    {
        ArgumentNullException.ThrowIfNull(code);
        ArgumentNullException.ThrowIfNull(primaryReference);
        ArgumentNullException.ThrowIfNull(relatedReferences);
        var related = relatedReferences.ToArray();
        if (related.Any(static row => row is null) ||
            related.Distinct(ReferenceEqualityComparer.Instance).Count() != related.Length)
        {
            throw new ArgumentException("Related references must be unique and non-null.", nameof(relatedReferences));
        }

        var token = ProtectedPolicyFrame.LowerAsciiToken(stableStateToken, nameof(stableStateToken), 64);
        if (string.Equals(token, "missing", StringComparison.Ordinal))
        {
            if (stableStateValue is not null)
            {
                throw new ArgumentException("Missing state has no value.", nameof(stableStateValue));
            }
        }
        else if (string.Equals(token, "kind-mismatch", StringComparison.Ordinal))
        {
            if (stableStateValue is null || !RepositoryEntryKind.TryParse(stableStateValue, out _))
            {
                throw new ArgumentException("Kind mismatch requires an exact repository entry kind.", nameof(stableStateValue));
            }
        }
        else
        {
            throw new ArgumentException("The stable-state token is not protocol-owned.", nameof(stableStateToken));
        }

        return new ExtensionFindingIntent(
            code, primaryReference, Array.AsReadOnly(related), token, stableStateValue);
    }
}

public sealed class ExtensionEvaluationIntent
{
    private ExtensionEvaluationIntent(
        IReadOnlyList<ExtensionFindingIntent> findings,
        IReadOnlyList<EvaluationFailureIntent> failures)
    {
        Findings = findings;
        Failures = failures;
    }

    public IReadOnlyList<ExtensionFindingIntent> Findings { get; }
    public IReadOnlyList<EvaluationFailureIntent> Failures { get; }

    internal static ExtensionEvaluationIntent Create(
        IEnumerable<ExtensionFindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures)
    {
        var findingRows = ProtectedPolicyFrame.SortedUnique(
            findings, static row => row.Code.Value, nameof(findings));
        var failureRows = ProtectedPolicyFrame.SortedUnique(
            failures, static row => row.Code.Value, nameof(failures));
        return new ExtensionEvaluationIntent(findingRows, failureRows);
    }
}

public interface IExtensionEvaluator
{
    ApplicabilityIntent EvaluateApplicability(
        ExtensionApplicabilityInput input,
        CancellationToken cancellationToken);

    ExtensionEvaluationIntent Evaluate(
        ExtensionEvaluationInput input,
        CancellationToken cancellationToken);
}

internal sealed class ExtensionEvaluatorRegistration
{
    private ExtensionEvaluatorRegistration(
        ExtensionEvaluatorKindDeclaration declaration,
        IExtensionEvaluator evaluator)
    {
        Declaration = declaration;
        Evaluator = evaluator;
    }

    public ExtensionEvaluatorKindDeclaration Declaration { get; }
    public IExtensionEvaluator Evaluator { get; }

    internal static ExtensionEvaluatorRegistration Create(
        ExtensionEvaluatorKindDeclaration declaration,
        IExtensionEvaluator evaluator)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(evaluator);
        if (evaluator is not IPolicyOwnedProtectedPolicyComponent owned ||
            !SameComponent(
                declaration.Component,
                owned.VerifyRuntimeComponentIdentity(declaration.Component)))
        {
            throw new ArgumentException(
                "The evaluator does not carry the exact Policy-owned component identity.",
                nameof(evaluator));
        }

        return new ExtensionEvaluatorRegistration(declaration, evaluator);
    }

    private static bool SameComponent(
        ComponentTypeIdentity left,
        ComponentTypeIdentity right) =>
        string.Equals(left.ComponentKey, right.ComponentKey, StringComparison.Ordinal) &&
        string.Equals(left.ComponentVersion, right.ComponentVersion, StringComparison.Ordinal) &&
        string.Equals(left.AssemblyName, right.AssemblyName, StringComparison.Ordinal) &&
        string.Equals(left.TypeName, right.TypeName, StringComparison.Ordinal);
}
