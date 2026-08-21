using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.ProtectedPolicy;

internal sealed class RepositoryPathRequiredExtensionEvaluator :
    IExtensionEvaluator,
    IPolicyOwnedProtectedPolicyComponent
{
    internal const string EvaluatorKind =
        "protocol.extension.repository-path-required";
    internal const string EvaluatorVersion = "1";
    private const string ComponentKey =
        "protocol.evaluator.extension.repository-path-required";
    private const string RepositoryTreeSlot = "protocol.slot.repository-tree";
    private const string Finding = "protocol.extension.required-path-missing";

    internal static ExtensionEvaluatorRegistration CreateRegistration()
    {
        var evaluator = new RepositoryPathRequiredExtensionEvaluator();
        var component = ComponentTypeIdentity.Create(
            ComponentKey,
            "1",
            "MeAndAI.Protocol.Policy",
            typeof(RepositoryPathRequiredExtensionEvaluator).FullName!);
        var declaration = ExtensionEvaluatorKindDeclaration.Create(
            EvaluatorKind,
            EvaluatorVersion,
            component,
            [
                ExtensionParameterDeclaration.Create(
                    "kind",
                    "directory|file|symbolic-link|git-link",
                    16),
                ExtensionParameterDeclaration.Create(
                    "path",
                    "normalized-repository-relative-path",
                    4096),
            ],
            [],
            [RepositoryTreeSlot],
            [
                FindingDeclaration.Create(
                    FindingCode.Parse(Finding),
                    FindingSeverity.Parse("protocol.finding.error"),
                    RemediationKey.Parse(
                        "protocol.remediation.restore-required-path"),
                    [QualifiedEvidenceReferenceKind.ContextProof],
                    []),
            ],
            [],
            waiverAllowed: false);
        return ExtensionEvaluatorRegistration.Create(declaration, evaluator);
    }

    public ApplicabilityIntent EvaluateApplicability(
        ExtensionApplicabilityInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        ValidateDeclaration(input.Extension);
        return ApplicabilityIntent.Applicable([]);
    }

    public ExtensionEvaluationIntent Evaluate(
        ExtensionEvaluationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var (path, expectedKind) = ValidateDeclaration(input.Extension);
        var tree = input.GetCapability<IRepositoryTree>(RepositoryTreeSlot);
        var contextProof = input.GetContextProof(RepositoryTreeSlot);
        if (tree.Entries.Count > 200_000)
        {
            throw new ArgumentOutOfRangeException(
                nameof(input),
                "The sealed repository tree exceeds the evaluator bound.");
        }

        RepositoryEntryKind? actualKind = null;
        for (var index = 0; index < tree.Entries.Count; index++)
        {
            if ((index & 1023) == 0)
            {
                cancellationToken.ThrowIfCancellationRequested();
            }

            var entry = tree.Entries[index];
            if (!string.Equals(
                    entry.RepositoryRelativePath,
                    path,
                    StringComparison.Ordinal))
            {
                continue;
            }

            if (actualKind is not null)
            {
                throw new ArgumentException(
                    "The sealed repository tree contains a duplicate path.",
                    nameof(input));
            }

            actualKind = entry.Kind;
        }

        cancellationToken.ThrowIfCancellationRequested();
        if (actualKind is not null && actualKind.Equals(expectedKind))
        {
            return ExtensionEvaluationIntent.Create([], []);
        }

        var state = actualKind is null ? "missing" : "kind-mismatch";
        return ExtensionEvaluationIntent.Create(
            [
                ExtensionFindingIntent.Create(
                    FindingCode.Parse(Finding),
                    contextProof,
                    [],
                    state,
                    actualKind?.Value),
            ],
            []);
    }

    ComponentTypeIdentity IPolicyOwnedProtectedPolicyComponent
        .VerifyRuntimeComponentIdentity(ComponentTypeIdentity expectedIdentity)
    {
        ArgumentNullException.ThrowIfNull(expectedIdentity);
        var runtimeType = GetType();
        return ComponentTypeIdentity.Create(
            expectedIdentity.ComponentKey,
            expectedIdentity.ComponentVersion,
            runtimeType.Assembly.GetName().Name!,
            runtimeType.FullName!);
    }

    private static (string Path, RepositoryEntryKind Kind) ValidateDeclaration(
        ExtensionRuleDeclaration declaration)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        if (!string.Equals(
                declaration.EvaluatorKind,
                EvaluatorKind,
                StringComparison.Ordinal) ||
            !string.Equals(
                declaration.EvaluatorVersion,
                EvaluatorVersion,
                StringComparison.Ordinal) ||
            declaration.Parameters.Count != 2 ||
            !string.Equals(
                declaration.Parameters[0].Key,
                "kind",
                StringComparison.Ordinal) ||
            !string.Equals(
                declaration.Parameters[1].Key,
                "path",
                StringComparison.Ordinal) ||
            !RepositoryEntryKind.TryParse(
                declaration.Parameters[0].Value,
                out var kind) ||
            !IsNormalizedRepositoryPath(declaration.Parameters[1].Value))
        {
            throw new ArgumentException(
                "The extension declaration does not match the required-path schema.",
                nameof(declaration));
        }

        return (declaration.Parameters[1].Value, kind);
    }

    private static bool IsNormalizedRepositoryPath(string value)
    {
        if (!ProtectedPolicyFrame.TryUtf8ByteCount(value, out var byteCount) ||
            byteCount is < 1 or > 4096 ||
            !value.IsNormalized(NormalizationForm.FormC) ||
            value[0] == '/' ||
            value[^1] == '/' ||
            value.Contains('\\', StringComparison.Ordinal) ||
            value.Contains("//", StringComparison.Ordinal) ||
            value.Any(static character => character is < ' ' or '\u007f') ||
            value.Length >= 3 && char.IsAsciiLetter(value[0]) &&
            value[1] == ':' && value[2] == '/')
        {
            return false;
        }

        return value.Split('/').All(static segment =>
            segment.Length != 0 &&
            !string.Equals(segment, ".", StringComparison.Ordinal) &&
            !string.Equals(segment, "..", StringComparison.Ordinal));
    }
}
