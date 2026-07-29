using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

internal static class GovernanceReportTestData
{
    internal static GovernanceReport ConformingReport() =>
        ReportWithMissingEvaluationCount(0);

    internal static GovernanceReport IncompleteReport() =>
        ReportWithMissingEvaluationCount(1);

    internal static GovernanceReport NonconformingReport() =>
        GovernanceEngine.CreateDefault().EvaluateCandidateShadow(
            GovernanceProfileId.ProtocolAuthority,
            GovernanceTestRepository.Candidate(
                GovernanceRepositoryEntry.Directory(
                    "docs/features/FEAT-0001-example")));

    internal static GovernanceReportFactory Factory() =>
        new(GovernanceRuleCatalog.Current);

    internal static GovernanceRuleEvaluation[] Evaluate(
        GovernanceRepositorySnapshot snapshot)
    {
        var context = GovernanceAnalysisContext.Create(snapshot);
        return GovernanceRuleCatalog.Current
            .GetApplicableRules(GovernanceProfileId.ProtocolAuthority)
            .Select(rule => new GovernanceRuleEvaluation(
                rule.Identity,
                rule.Evaluate(context)))
            .ToArray();
    }

    internal static GovernanceRepositorySnapshot CompleteFeatureSnapshot() =>
        GovernanceTestRepository.Candidate(
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-example"),
            GovernanceRepositoryEntry.File(
                "docs/features/FEAT-0001-example/README.md"),
            GovernanceRepositoryEntry.File(
                "docs/features/FEAT-0001-example/test-cases.md"));

    private static GovernanceReport ReportWithMissingEvaluationCount(
        int missingEvaluationCount)
    {
        var snapshot = CompleteFeatureSnapshot();
        var evaluations = Evaluate(snapshot)
            .SkipLast(missingEvaluationCount)
            .ToArray();

        return Factory().Create(
            GovernanceProfileId.ProtocolAuthority,
            snapshot,
            evaluations);
    }
}
