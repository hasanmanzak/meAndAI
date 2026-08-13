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

internal sealed class DecisionRecordRuleEvaluator : InitialRuleEvaluator;

internal sealed class ClickableExactTargetRuleEvaluator : InitialRuleEvaluator;

internal sealed class StableFragmentRuleEvaluator : InitialRuleEvaluator;

internal sealed class CommitPermalinkRuleEvaluator : InitialRuleEvaluator;
