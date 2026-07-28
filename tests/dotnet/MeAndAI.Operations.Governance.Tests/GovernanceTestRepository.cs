using System.Text;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

internal static class GovernanceTestRepository
{
    public static GovernanceRepositoryEntry MarkdownFile(
        string relativePath,
        string content) =>
        GovernanceRepositoryEntry.File(
            relativePath,
            Encoding.UTF8.GetBytes(content));

    public static GovernanceRepositorySnapshot Candidate(
        params GovernanceRepositoryEntry[] entries) =>
        GovernanceRepositorySnapshot.CreateCandidate(entries);

    public static GovernanceAnalysisContext Analyze(
        params GovernanceRepositoryEntry[] entries) =>
        GovernanceAnalysisContext.Create(Candidate(entries));
}
