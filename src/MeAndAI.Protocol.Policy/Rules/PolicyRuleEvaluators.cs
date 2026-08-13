using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Rules;

internal abstract class InitialRuleEvaluator : IRuleEvaluator
{
    public ApplicabilityIntent EvaluateApplicability(
        RuleApplicabilityInput input,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return ApplicabilityIntent.Applicable([]);
    }

    public virtual EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return EvaluationIntent.Create([], []);
    }
}

internal sealed class FeaturePacketRuleEvaluator : InitialRuleEvaluator
{
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string FeaturePrefix = "docs/features/FEAT-";

    public override EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var tree = input.GetCapability<IRepositoryTree>(TreeSlot);
        var findings = new List<FindingIntent>();

        foreach (var feature in tree.Entries
            .Where(entry =>
                entry.Kind.Equals(RepositoryEntryKind.Directory) &&
                IsFeatureRoot(entry.RepositoryRelativePath))
            .OrderBy(entry => entry.RepositoryRelativePath, StringComparer.Ordinal))
        {
            AddMissing(
                tree,
                feature,
                "README.md",
                "protocol.selector.feature-readme",
                "protocol.feature.readme-missing",
                input,
                findings);
            AddMissing(
                tree,
                feature,
                "test-cases.md",
                "protocol.selector.feature-test-cases",
                "protocol.feature.test-cases-missing",
                input,
                findings);
        }

        return EvaluationIntent.Create(findings, []);
    }

    private static void AddMissing(
        IRepositoryTree tree,
        RepositoryEntryView feature,
        string childName,
        string selectorKey,
        string findingCode,
        RuleEvaluationInput input,
        ICollection<FindingIntent> findings)
    {
        var childPath = $"{feature.RepositoryRelativePath}/{childName}";
        if (tree.Entries.Any(entry =>
                string.Equals(
                    entry.RepositoryRelativePath,
                    childPath,
                    StringComparison.Ordinal) &&
                entry.Kind.Equals(RepositoryEntryKind.File)))
        {
            return;
        }

        findings.Add(FindingIntent.Create(
            FindingCode.Parse(findingCode),
            input.GetExpectedReference(selectorKey, feature.Evidence),
            [feature.Evidence]));
    }

    private static bool IsFeatureRoot(string path)
    {
        if (!path.StartsWith(FeaturePrefix, StringComparison.Ordinal))
        {
            return false;
        }

        var suffix = path.AsSpan(FeaturePrefix.Length);
        return suffix.Length >= 6 &&
            suffix[..4].IndexOfAnyExceptInRange('0', '9') < 0 &&
            suffix[4] == '-' &&
            suffix[5..].IndexOf('/') < 0;
    }
}

internal sealed class DecisionRecordRuleEvaluator : InitialRuleEvaluator
{
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string TextSlot = "protocol.slot.repository-governed-text";
    private const string DecisionKind = "protocol.record.decision";
    private const string ReferenceKind = "protocol.record.decision-reference";
    private const string Selector = "protocol.selector.decision-record";
    private static readonly string[] RequiredMembers =
    [
        "heading",
        "metadata:Classification",
        "metadata:Status",
        "metadata:Date",
        "metadata:Decision owners",
        "metadata:Related features",
        "metadata:Related decisions",
        "section:Context",
        "section:Decision",
        "section:Consequences",
        "section:Alternatives considered",
        "section:Review condition",
    ];

    public override EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var index = input.GetCapability<IProtocolRecordIndex>(TextSlot);
        var contextProofs = new[]
        {
            input.GetContextProof(TreeSlot),
            input.GetContextProof(TextSlot),
        };
        var decisions = index.Records
            .Where(item => item.RecordKind == DecisionKind)
            .ToArray();
        var findings = new List<FindingIntent>();

        foreach (var reference in index.Records
            .Where(item => item.RecordKind == ReferenceKind)
            .OrderBy(item => item.Ordinal))
        {
            var matches = decisions
                .Where(item => item.RecordId == reference.RecordId)
                .OrderBy(item => item.Ordinal)
                .ToArray();
            if (matches.Length == 0)
            {
                findings.Add(FindingIntent.Create(
                    FindingCode.Parse("protocol.decision.record-missing"),
                    input.GetExpectedReference(Selector, reference.Evidence),
                    [.. contextProofs, reference.Evidence]));
                continue;
            }

            if (matches.Length != 1 ||
                !matches[0].Members
                    .OrderBy(item => item.Ordinal)
                    .Select(item => item.MemberKey)
                    .SequenceEqual(RequiredMembers, StringComparer.Ordinal))
            {
                findings.Add(FindingIntent.Create(
                    FindingCode.Parse("protocol.decision.structure-invalid"),
                    matches[0].Evidence,
                    [.. contextProofs, reference.Evidence]));
            }
        }

        return EvaluationIntent.Create(findings, []);
    }
}

internal sealed class ClickableExactTargetRuleEvaluator : InitialRuleEvaluator
{
    private const string RepositorySlot =
        "protocol.slot.repository-governed-text";
    private const string ProviderSlot =
        "protocol.slot.provider-governed-text";
    private const string TargetSlot =
        "protocol.slot.repository-target-resolution";

    public override EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var governedSlot = input.Profile.Surfaces.Values.Contains(
            MeAndAI.Protocol.Domain.SurfaceKind.Repository)
            ? RepositorySlot
            : ProviderSlot;
        var references = input.GetCapability<IGovernedReferenceIndex>(
            governedSlot);
        var targets = input.GetCapability<IRepositoryTargetResolutionIndex>(
            TargetSlot);
        var context = input.GetContextProof(governedSlot);
        var findings = new List<FindingIntent>();
        var failures = new List<EvaluationFailureIntent>();

        foreach (var reference in references.References)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var overlays = targets.Targets.Where(item =>
                ReferenceEquals(item.Reference, reference.Reference)).ToArray();
            if (overlays.Length > 1)
            {
                failures.Add(EvaluationFailureIntent.Create(
                    EvaluationFailureCode.Parse(
                        "protocol.evaluator.reference-ambiguity"),
                    reference.Reference,
                    Related(reference, context, overlays)));
                continue;
            }

            var overlay = overlays.SingleOrDefault();
            var resolution = overlay?.Resolution ?? reference.Resolution;
            var code = Finding(reference, resolution, overlay is not null);
            if (code is not null)
            {
                findings.Add(FindingIntent.Create(
                    FindingCode.Parse(code),
                    reference.Reference,
                    Related(reference, context, overlays)));
            }
        }

        return EvaluationIntent.Create(findings, failures);
    }

    private static string? Finding(
        GovernedReferenceView reference,
        GovernedReferenceResolution resolution,
        bool hasOverlay)
    {
        if (reference.Syntax.Equals(
                GovernedReferenceSyntax.UnsupportedAuthoringForm))
        {
            return "protocol.reference.unsupported-authoring-form";
        }

        if (reference.Syntax.Equals(GovernedReferenceSyntax.NonClickable) ||
            reference.NormalizedRepositoryRelativePath is null &&
            !reference.Kind.Equals(GovernedReferenceKind.Commit))
        {
            return "protocol.reference.not-clickable";
        }

        if (resolution.Equals(
                GovernedReferenceResolution.ExternalEvidenceRequired) &&
            !hasOverlay)
        {
            return null;
        }

        if (resolution.Equals(GovernedReferenceResolution.Unresolved))
        {
            return "protocol.reference.unresolved-target";
        }

        if (resolution.Equals(GovernedReferenceResolution.WrongTarget) ||
            reference.Kind.Equals(GovernedReferenceKind.CrossRecord) &&
                (resolution.Equals(
                    GovernedReferenceResolution.MissingFragment) ||
                 resolution.Equals(
                    GovernedReferenceResolution.WrongFragment)) ||
            !reference.Kind.Equals(GovernedReferenceKind.Commit) &&
                (resolution.Equals(
                    GovernedReferenceResolution.WrongRepository) ||
                 resolution.Equals(GovernedReferenceResolution.WrongObject)))
        {
            return "protocol.reference.wrong-target";
        }

        return null;
    }

    private static IReadOnlyList<QualifiedEvidenceHandle> Related(
        GovernedReferenceView reference,
        QualifiedEvidenceHandle context,
        IEnumerable<RepositoryTargetResolutionView> overlays)
    {
        var values = new List<QualifiedEvidenceHandle> { context };
        if (reference.Target is not null)
        {
            values.Add(reference.Target);
        }

        foreach (var overlay in overlays)
        {
            values.Add(overlay.ResolutionEvidence);
            if (overlay.Target is not null)
            {
                values.Add(overlay.Target);
            }
        }

        var distinct = new List<QualifiedEvidenceHandle>();
        foreach (var value in values.Where(value =>
                     !ReferenceEquals(value, reference.Reference)))
        {
            if (!distinct.Any(existing => ReferenceEquals(existing, value)))
            {
                distinct.Add(value);
            }
        }

        return distinct;
    }
}

internal sealed class StableFragmentRuleEvaluator : InitialRuleEvaluator
{
    private const string RepositorySlot =
        "protocol.slot.repository-governed-text";
    private const string ProviderSlot =
        "protocol.slot.provider-governed-text";
    private const string TargetSlot =
        "protocol.slot.repository-target-resolution";

    public override EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var governedSlot = input.Profile.Surfaces.Values.Contains(
            MeAndAI.Protocol.Domain.SurfaceKind.Repository)
            ? RepositorySlot
            : ProviderSlot;
        var references = input.GetCapability<IGovernedReferenceIndex>(
            governedSlot);
        var targets = input.GetCapability<IRepositoryTargetResolutionIndex>(
            TargetSlot);
        var context = input.GetContextProof(governedSlot);
        var findings = new List<FindingIntent>();
        var failures = new List<EvaluationFailureIntent>();

        foreach (var reference in references.References)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!reference.Kind.Equals(GovernedReferenceKind.EmbeddedRecord))
            {
                continue;
            }

            var overlays = targets.Targets.Where(item =>
                ReferenceEquals(item.Reference, reference.Reference)).ToArray();
            if (overlays.Length > 1)
            {
                failures.Add(EvaluationFailureIntent.Create(
                    EvaluationFailureCode.Parse(
                        "protocol.evaluator.reference-ambiguity"),
                    reference.Reference,
                    Related(reference, context, overlays)));
                continue;
            }

            var overlay = overlays.SingleOrDefault();
            var resolution = overlay?.Resolution ?? reference.Resolution;
            var code = Finding(reference, resolution, overlay is not null);
            if (code is not null)
            {
                findings.Add(FindingIntent.Create(
                    FindingCode.Parse(code),
                    reference.Reference,
                    Related(reference, context, overlays)));
            }
        }

        return EvaluationIntent.Create(findings, failures);
    }

    private static string? Finding(
        GovernedReferenceView reference,
        GovernedReferenceResolution resolution,
        bool hasOverlay)
    {
        if (resolution.Equals(
                GovernedReferenceResolution.ExternalEvidenceRequired) &&
            !hasOverlay)
        {
            return null;
        }

        if (reference.NormalizedRepositoryRelativePath is null)
        {
            return resolution.Equals(GovernedReferenceResolution.MissingFragment)
                ? "protocol.record.anchor-missing"
                : resolution.Equals(GovernedReferenceResolution.WrongFragment)
                    ? "protocol.record.anchor-duplicate"
                    : null;
        }

        if (resolution.Equals(GovernedReferenceResolution.MissingFragment))
        {
            return "protocol.reference.fragment-missing";
        }

        if (resolution.Equals(GovernedReferenceResolution.WrongFragment))
        {
            return "protocol.reference.fragment-wrong";
        }

        return null;
    }

    private static IReadOnlyList<QualifiedEvidenceHandle> Related(
        GovernedReferenceView reference,
        QualifiedEvidenceHandle context,
        IEnumerable<RepositoryTargetResolutionView> overlays)
    {
        var values = new List<QualifiedEvidenceHandle> { context };
        if (reference.Target is not null)
        {
            values.Add(reference.Target);
        }

        foreach (var overlay in overlays)
        {
            values.Add(overlay.ResolutionEvidence);
            if (overlay.Target is not null)
            {
                values.Add(overlay.Target);
            }
        }

        var distinct = new List<QualifiedEvidenceHandle>();
        foreach (var value in values.Where(value =>
                     !ReferenceEquals(value, reference.Reference)))
        {
            if (!distinct.Any(existing => ReferenceEquals(existing, value)))
            {
                distinct.Add(value);
            }
        }

        return distinct;
    }
}

internal sealed class CommitPermalinkRuleEvaluator : InitialRuleEvaluator
{
    private const string RepositorySlot =
        "protocol.slot.repository-governed-text";
    private const string ProviderSlot =
        "protocol.slot.provider-governed-text";
    private const string TargetSlot =
        "protocol.slot.repository-target-resolution";

    public override EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var governedSlot = input.Profile.Surfaces.Values.Contains(
            MeAndAI.Protocol.Domain.SurfaceKind.Repository)
            ? RepositorySlot
            : ProviderSlot;
        var references = input.GetCapability<IGovernedReferenceIndex>(
            governedSlot);
        var targets = input.GetCapability<IRepositoryTargetResolutionIndex>(
            TargetSlot);
        var context = input.GetContextProof(governedSlot);
        var findings = new List<FindingIntent>();
        var failures = new List<EvaluationFailureIntent>();

        foreach (var reference in references.References)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!reference.Kind.Equals(GovernedReferenceKind.Commit))
            {
                continue;
            }

            var overlays = targets.Targets.Where(item =>
                ReferenceEquals(item.Reference, reference.Reference)).ToArray();
            if (overlays.Length > 1)
            {
                failures.Add(Failure(
                    "protocol.evaluator.reference-ambiguity",
                    reference,
                    context,
                    overlays));
                continue;
            }

            var overlay = overlays.SingleOrDefault();
            if (overlay is not null &&
                !reference.Resolution.Equals(
                    GovernedReferenceResolution.ExternalEvidenceRequired) &&
                !reference.Resolution.Equals(overlay.Resolution))
            {
                failures.Add(Failure(
                    "protocol.evaluator.commit-intent-ambiguity",
                    reference,
                    context,
                    overlays));
                continue;
            }

            var resolution = overlay?.Resolution ?? reference.Resolution;
            var code = Finding(reference, resolution, overlay is not null);
            if (code is not null)
            {
                findings.Add(FindingIntent.Create(
                    FindingCode.Parse(code),
                    reference.Reference,
                    Related(reference, context, overlays)));
            }
        }

        return EvaluationIntent.Create(findings, failures);
    }

    private static EvaluationFailureIntent Failure(
        string code,
        GovernedReferenceView reference,
        QualifiedEvidenceHandle context,
        IEnumerable<RepositoryTargetResolutionView> overlays) =>
        EvaluationFailureIntent.Create(
            EvaluationFailureCode.Parse(code),
            reference.Reference,
            Related(reference, context, overlays));

    private static string? Finding(
        GovernedReferenceView reference,
        GovernedReferenceResolution resolution,
        bool hasOverlay)
    {
        if (!reference.Syntax.Equals(GovernedReferenceSyntax.Clickable) ||
            reference.OwningRepositoryIdentity is null ||
            !IsObjectId(reference.CommitObjectId))
        {
            return "protocol.commit-reference.not-permalink";
        }

        if (resolution.Equals(
                GovernedReferenceResolution.ExternalEvidenceRequired) &&
            !hasOverlay)
        {
            return null;
        }

        if (resolution.Equals(GovernedReferenceResolution.WrongRepository))
        {
            return "protocol.commit-reference.wrong-repository";
        }

        if (resolution.Equals(GovernedReferenceResolution.Unresolved))
        {
            return "protocol.commit-reference.unresolved";
        }

        if (resolution.Equals(GovernedReferenceResolution.WrongObject))
        {
            return "protocol.commit-reference.wrong-object";
        }

        return null;
    }

    private static bool IsObjectId(string? value) =>
        value is { Length: 40 } && value.All(character =>
            character is >= '0' and <= '9' or >= 'a' and <= 'f');

    private static IReadOnlyList<QualifiedEvidenceHandle> Related(
        GovernedReferenceView reference,
        QualifiedEvidenceHandle context,
        IEnumerable<RepositoryTargetResolutionView> overlays)
    {
        var values = new List<QualifiedEvidenceHandle> { context };
        if (reference.Target is not null)
        {
            values.Add(reference.Target);
        }

        foreach (var overlay in overlays)
        {
            values.Add(overlay.ResolutionEvidence);
            if (overlay.Commit is not null)
            {
                values.Add(overlay.Commit);
            }

            if (overlay.Target is not null)
            {
                values.Add(overlay.Target);
            }
        }

        var distinct = new List<QualifiedEvidenceHandle>();
        foreach (var value in values.Where(value =>
                     !ReferenceEquals(value, reference.Reference)))
        {
            if (!distinct.Any(existing => ReferenceEquals(existing, value)))
            {
                distinct.Add(value);
            }
        }

        return distinct;
    }
}
