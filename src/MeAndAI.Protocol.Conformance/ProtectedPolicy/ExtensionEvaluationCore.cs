using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class ExtensionEvaluationCore
{
    private const string RepositoryTreeSlot = "protocol.slot.repository-tree";
    private const string RequiredPathEvaluator =
        "protocol.extension.repository-path-required";

    internal static IReadOnlyList<ExtensionEvaluation> Evaluate(
        ActivatedExtensionPolicy activePolicy,
        ExecutionProfile profile,
        IReadOnlyCollection<string> sealedSlotKeys,
        IRuleInputAccess access,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            references,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(activePolicy);
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(sealedSlotKeys);
        ArgumentNullException.ThrowIfNull(access);
        ArgumentNullException.ThrowIfNull(references);
        var sealedKeys = sealedSlotKeys.ToArray();
        if (sealedKeys.Any(static key => key is null) ||
            sealedKeys.Distinct(StringComparer.Ordinal).Count() != sealedKeys.Length)
        {
            throw InvalidDefinition();
        }

        var registrations = activePolicy.Policy.Registrations.ToDictionary(
            static row => row.Declaration.EvaluatorKind,
            StringComparer.Ordinal);
        var result = new List<ExtensionEvaluation>();
        foreach (var extension in activePolicy.Snapshot.Extensions)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!registrations.TryGetValue(extension.EvaluatorKind, out var registration) ||
                !string.Equals(
                    extension.EvaluatorVersion,
                    registration.Declaration.EvaluatorVersion,
                    StringComparison.Ordinal))
            {
                throw InvalidDefinition();
            }

            if (!MatchesProfile(extension, profile))
            {
                result.Add(Terminal(
                    extension,
                    RuleEvaluationStatus.NotApplicable,
                    applicabilityUnresolved: false,
                    [],
                    []));
                continue;
            }

            var applicabilityMissing = MissingSlots(
                registration.Declaration.ApplicabilitySlotKeys,
                sealedKeys);
            if (applicabilityMissing.Count != 0)
            {
                result.Add(Terminal(
                    extension,
                    RuleEvaluationStatus.NotEvaluated,
                    applicabilityUnresolved: true,
                    [],
                    applicabilityMissing));
                continue;
            }

            var applicability = InvokeApplicability(
                registration,
                extension,
                profile,
                access,
                cancellationToken);
            var applicabilityReferences = Resolve(
                applicability.References,
                references);
            if (applicability.Kind.Equals(ApplicabilityIntentKind.NotApplicable))
            {
                result.Add(Terminal(
                    extension,
                    RuleEvaluationStatus.NotApplicable,
                    applicabilityUnresolved: false,
                    applicabilityReferences,
                    []));
                continue;
            }

            if (applicability.Kind.Equals(ApplicabilityIntentKind.Unresolved))
            {
                result.Add(Terminal(
                    extension,
                    RuleEvaluationStatus.NotEvaluated,
                    applicabilityUnresolved: true,
                    applicabilityReferences,
                    []));
                continue;
            }

            if (!applicability.Kind.Equals(ApplicabilityIntentKind.Applicable))
            {
                throw InvalidDefinition();
            }

            var evaluationMissing = MissingSlots(
                registration.Declaration.EvaluationSlotKeys,
                sealedKeys);
            if (evaluationMissing.Count != 0)
            {
                result.Add(Terminal(
                    extension,
                    RuleEvaluationStatus.NotEvaluated,
                    applicabilityUnresolved: false,
                    applicabilityReferences,
                    evaluationMissing));
                continue;
            }

            var intent = InvokeEvaluation(
                registration,
                extension,
                profile,
                access,
                cancellationToken);
            result.Add(Mint(
                extension,
                registration.Declaration,
                intent,
                applicabilityReferences,
                access,
                references,
                cancellationToken));
        }

        cancellationToken.ThrowIfCancellationRequested();
        return Array.AsReadOnly(result
            .OrderBy(static row => row.ExtensionId.Value, StringComparer.Ordinal)
            .ThenBy(static row => row.RuleRevision.Value)
            .ToArray());
    }

    private static bool MatchesProfile(
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile) =>
        extension.SubjectRoles.Contains(profile.SubjectRole) &&
        extension.SnapshotKinds.Contains(profile.SnapshotKind) &&
        extension.Operations.Contains(profile.Operation) &&
        extension.Surfaces.Values.Any(profile.Surfaces.Values.Contains);

    private static IReadOnlyList<string> MissingSlots(
        IReadOnlyList<string> required,
        IReadOnlyCollection<string> sealedKeys) => Array.AsReadOnly(required
        .Where(key => !sealedKeys.Contains(key, StringComparer.Ordinal))
        .Order(StringComparer.Ordinal)
        .ToArray());

    private static ApplicabilityIntent InvokeApplicability(
        ExtensionEvaluatorRegistration registration,
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile,
        IRuleInputAccess access,
        CancellationToken cancellationToken)
    {
        try
        {
            return registration.Evaluator.EvaluateApplicability(
                ExtensionApplicabilityInput.Create(extension, profile, access),
                cancellationToken) ?? throw InvalidDefinition();
        }
        catch (ProtectedPolicyIntegrityException)
        {
            throw;
        }
        catch (Exception exception) when (
            exception is ArgumentException or InvalidOperationException)
        {
            throw InvalidDefinition();
        }
    }

    private static ExtensionEvaluationIntent InvokeEvaluation(
        ExtensionEvaluatorRegistration registration,
        ExtensionRuleDeclaration extension,
        ExecutionProfile profile,
        IRuleInputAccess access,
        CancellationToken cancellationToken)
    {
        try
        {
            return registration.Evaluator.Evaluate(
                ExtensionEvaluationInput.Create(extension, profile, access),
                cancellationToken) ?? throw InvalidDefinition();
        }
        catch (ProtectedPolicyIntegrityException)
        {
            throw;
        }
        catch (ArgumentOutOfRangeException)
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
        }
        catch (Exception exception) when (
            exception is ArgumentException or InvalidOperationException)
        {
            throw InvalidDefinition();
        }
    }

    private static ExtensionEvaluation Mint(
        ExtensionRuleDeclaration extension,
        ExtensionEvaluatorKindDeclaration evaluatorKind,
        ExtensionEvaluationIntent intent,
        IReadOnlyList<QualifiedEvidenceReference> applicabilityReferences,
        IRuleInputAccess access,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            references,
        CancellationToken cancellationToken)
    {
        var findings = intent.Findings.Select(finding =>
        {
            var declaration = evaluatorKind.Findings.SingleOrDefault(candidate =>
                candidate.Code.Equals(finding.Code)) ?? throw InvalidDefinition();
            var primary = Resolve(finding.PrimaryReference, references);
            var related = Resolve(finding.RelatedReferences, references);
            if (!declaration.AllowedPrimaryReferenceKinds.Contains(primary.Kind) ||
                related.Any(reference =>
                    !declaration.AllowedRelatedReferenceKinds.Contains(reference.Kind)) ||
                !HasExactRequiredPathState(
                    extension,
                    finding,
                    access,
                    cancellationToken))
            {
                throw InvalidDefinition();
            }

            return new ExtensionFinding(
                extension.ExtensionId,
                extension.Revision,
                declaration.Code,
                declaration.Severity,
                declaration.Remediation,
                primary,
                related.Order(ReferenceComparer.Instance),
                finding.StableStateToken,
                finding.StableStateValue);
        }).OrderBy(static finding => finding.Code.Value, StringComparer.Ordinal)
            .ThenBy(static finding => finding.PrimaryReference, ReferenceComparer.Instance)
            .ToArray();
        var failures = intent.Failures.Select(failure =>
        {
            if (!evaluatorKind.FailureCodes.Contains(failure.Code))
            {
                throw InvalidDefinition();
            }

            return new ExtensionEvaluationFailure(
                extension.ExtensionId,
                extension.Revision,
                failure.Code,
                Resolve(failure.PrimaryReference, references),
                Resolve(failure.RelatedReferences, references)
                    .Order(ReferenceComparer.Instance));
        }).OrderBy(static failure => failure.Code.Value, StringComparer.Ordinal)
            .ThenBy(static failure => failure.PrimaryReference, ReferenceComparer.Instance)
            .ToArray();
        var status = failures.Length != 0
            ? RuleEvaluationStatus.NotEvaluated
            : findings.Length != 0
                ? RuleEvaluationStatus.Violated
                : RuleEvaluationStatus.Satisfied;
        return new ExtensionEvaluation(
            extension.ExtensionId,
            extension.Revision,
            status,
            false,
            applicabilityReferences,
            [],
            findings,
            failures);
    }

    private static bool HasExactRequiredPathState(
        ExtensionRuleDeclaration extension,
        ExtensionFindingIntent finding,
        IRuleInputAccess access,
        CancellationToken cancellationToken)
    {
        if (!string.Equals(
                extension.EvaluatorKind,
                RequiredPathEvaluator,
                StringComparison.Ordinal) ||
            extension.Parameters.Count != 2 ||
            !string.Equals(extension.Parameters[0].Key, "kind", StringComparison.Ordinal) ||
            !string.Equals(extension.Parameters[1].Key, "path", StringComparison.Ordinal) ||
            !RepositoryEntryKind.TryParse(extension.Parameters[0].Value, out var expectedKind))
        {
            return false;
        }

        var tree = access.GetCapability<IRepositoryTree>(RepositoryTreeSlot);
        if (tree.Entries.Count > 200_000)
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.ResourceLimitExceeded);
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
                    extension.Parameters[1].Value,
                    StringComparison.Ordinal))
            {
                continue;
            }

            if (actualKind is not null)
            {
                return false;
            }

            actualKind = entry.Kind;
        }

        return actualKind is null
            ? string.Equals(finding.StableStateToken, "missing", StringComparison.Ordinal) &&
                finding.StableStateValue is null
            : !actualKind.Equals(expectedKind) &&
                string.Equals(
                    finding.StableStateToken,
                    "kind-mismatch",
                    StringComparison.Ordinal) &&
                string.Equals(
                    finding.StableStateValue,
                    actualKind.Value,
                    StringComparison.Ordinal);
    }

    private static ExtensionEvaluation Terminal(
        ExtensionRuleDeclaration extension,
        RuleEvaluationStatus status,
        bool applicabilityUnresolved,
        IEnumerable<QualifiedEvidenceReference> applicabilityReferences,
        IEnumerable<string> unresolvedSlotKeys) => new(
            extension.ExtensionId,
            extension.Revision,
            status,
            applicabilityUnresolved,
            applicabilityReferences,
            unresolvedSlotKeys,
            [],
            []);

    private static QualifiedEvidenceReference Resolve(
        QualifiedEvidenceHandle handle,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            references) => references.TryGetValue(handle, out var reference)
            ? reference
            : throw InvalidDefinition();

    private static IReadOnlyList<QualifiedEvidenceReference> Resolve(
        IEnumerable<QualifiedEvidenceHandle> handles,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            references) => Array.AsReadOnly(handles
        .Select(handle => Resolve(handle, references))
        .ToArray());

    private static ProtectedPolicyIntegrityException InvalidDefinition() =>
        new(ProtectedPolicyIntegrityCode.ExtensionDefinitionInvalid);

    private sealed class ReferenceComparer :
        IComparer<QualifiedEvidenceReference>
    {
        internal static ReferenceComparer Instance { get; } = new();

        public int Compare(
            QualifiedEvidenceReference? left,
            QualifiedEvidenceReference? right)
        {
            if (ReferenceEquals(left, right))
            {
                return 0;
            }

            if (left is null)
            {
                return -1;
            }

            if (right is null)
            {
                return 1;
            }

            var leftValues = Values(left);
            var rightValues = Values(right);
            for (var index = 0; index < leftValues.Length; index++)
            {
                var comparison = StringComparer.Ordinal.Compare(
                    leftValues[index],
                    rightValues[index]);
                if (comparison != 0)
                {
                    return comparison;
                }
            }

            return 0;
        }

        private static string[] Values(QualifiedEvidenceReference reference) =>
        [
            reference.Kind.Value,
            reference.SlotKey,
            reference.RequirementKey,
            reference.Scope.Target.SubjectIdentity,
            reference.Scope.Target.SourceIdentity,
            reference.Scope.Target.Surface.Value,
            reference.Scope.Target.SnapshotKind.Value,
            reference.Scope.Target.TargetIdentity,
            reference.QualificationProofDigest.Value,
        ];
    }
}
