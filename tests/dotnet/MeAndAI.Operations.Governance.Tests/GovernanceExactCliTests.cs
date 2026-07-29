using System.Text.Json;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceExactCliTests
{
    [Fact]
    public async Task AuthorityReadsTheRequestedCommitInsteadOfHeadOrWorktree()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        fixture.WritePolicyWorktreeVersion("dirty-worktree\n");

        var result = await InvokeExactAsync(
            fixture.PolicyRoot,
            "protocol-authority",
            fixture.PolicyCommit,
            fixture.PolicyCommit);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Conforming,
            result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var report = JsonDocument.Parse(result.StandardOutput);
        AssertExactIdentity(
            report.RootElement,
            "protocol-authority",
            fixture.PolicyCommit,
            fixture.PolicyCommit,
            "complete",
            "conforming");
    }

    [Fact]
    public async Task ConsumerUsesPinnedObjectsInsteadOfProviderCheckoutOrUrl()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        Assert.Equal(
            fixture.PolicyLaterCommit,
            fixture.GetIntegratedPolicyCheckoutCommit());

        var result = await InvokeExactAsync(
            fixture.ConsumerRoot,
            "consumer",
            fixture.ConsumerCommit,
            fixture.PolicyCommit);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Conforming,
            result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var report = JsonDocument.Parse(result.StandardOutput);
        AssertExactIdentity(
            report.RootElement,
            "consumer",
            fixture.ConsumerCommit,
            fixture.PolicyCommit,
            "complete",
            "conforming");
    }

    [Fact]
    public async Task MissingOrMismatchedProfileEvidenceProducesOneIncompleteReport()
    {
        using var fixture = GovernanceRealGitFixture.Create();

        var authorityMismatch = await InvokeExactAsync(
            fixture.PolicyRoot,
            "protocol-authority",
            fixture.PolicyLaterCommit,
            fixture.PolicyCommit);
        fixture.RemoveIntegratedPolicyWorktree();
        var missingProvider = await InvokeExactAsync(
            fixture.ConsumerRoot,
            "consumer",
            fixture.ConsumerCommit,
            fixture.PolicyCommit);

        foreach (var result in new[] { authorityMismatch, missingProvider })
        {
            Assert.Equal(
                (int)GovernanceProcessExitCode.Incomplete,
                result.ExitCode);
            Assert.Equal(string.Empty, result.StandardError);
            using var report = JsonDocument.Parse(result.StandardOutput);
            Assert.Equal(
                "incomplete",
                report.RootElement.GetProperty("verdict").GetString());
            Assert.Equal(
                "incomplete",
                report.RootElement
                    .GetProperty("policy")
                    .GetProperty("profileEvidence")
                    .GetString());
            Assert.Equal(
                2,
                report.RootElement
                    .GetProperty("counts")
                    .GetProperty("evaluatedRules")
                    .GetInt32());
            Assert.Equal(
                0,
                report.RootElement
                    .GetProperty("counts")
                    .GetProperty("missingRules")
                    .GetInt32());
        }
    }

    [Theory]
    [InlineData("automatic", "0123456789abcdef0123456789abcdef01234567")]
    [InlineData("consumer", "0123456789abcdef0123456789abcdef0123456Z")]
    public async Task MalformedCallerInputIsRejectedBeforePolicyBinding(
        string profile,
        string subjectCommit)
    {
        var resolverCalled = false;

        var result = await InvokeArgumentsAsync(
            [
                "validate",
                "--repository",
                "does-not-need-to-exist",
                "--profile",
                profile,
                "--subject-commit",
                subjectCommit,
            ],
            () =>
            {
                resolverCalled = true;
                return ExactGitCommitId.Parse(
                    "0123456789abcdef0123456789abcdef01234567");
            });

        Assert.False(resolverCalled);
        Assert.Equal(
            (int)GovernanceProcessExitCode.Rejected,
            result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Governance validation rejected.\n",
            NormalizeNewline(result.StandardError));
    }

    [Fact]
    public async Task UnboundDevelopmentBuildFailsExactValidationWithoutReport()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        using var output = new StringWriter();
        using var error = new StringWriter();

        var exitCode = await GovernanceCli.RunAsync(
            ExactArguments(
                fixture.PolicyRoot,
                "protocol-authority",
                fixture.PolicyCommit),
            output,
            error);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Failed,
            exitCode);
        Assert.Equal(string.Empty, output.ToString());
        Assert.Equal(
            "Governance validation failed.\n",
            NormalizeNewline(error.ToString()));
    }

    [Fact]
    public async Task PublicCliDoesNotExposeTheCandidateGrammar()
    {
        using var output = new StringWriter();
        using var error = new StringWriter();

        var exitCode = await GovernanceCli.RunAsync(
            [
                "validate",
                "--repository",
                "does-not-need-to-exist",
                "--profile",
                "protocol-authority",
            ],
            output,
            error);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Rejected,
            exitCode);
        Assert.Equal(string.Empty, output.ToString());
        Assert.Equal(
            "Governance validation rejected.\n",
            NormalizeNewline(error.ToString()));
    }

    [Fact]
    public async Task MissingSubjectObjectAndCancellationEmitNoReport()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var missing = await InvokeExactAsync(
            fixture.PolicyRoot,
            "protocol-authority",
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            fixture.PolicyCommit);
        using var cancellation = new CancellationTokenSource();
        await cancellation.CancelAsync();
        var canceled = await InvokeExactAsync(
            fixture.PolicyRoot,
            "protocol-authority",
            fixture.PolicyCommit,
            fixture.PolicyCommit,
            cancellation.Token);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Failed,
            missing.ExitCode);
        Assert.Equal(string.Empty, missing.StandardOutput);
        Assert.Equal(
            (int)GovernanceProcessExitCode.Canceled,
            canceled.ExitCode);
        Assert.Equal(string.Empty, canceled.StandardOutput);
    }

    [Theory]
    [InlineData("docs")]
    [InlineData("docs/decisions/DEC-0001-example.md")]
    public async Task LinkedGovernanceEvidenceFailsWithoutAReport(
        string relativePath)
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var linkedCommit = fixture.CommitPolicyGitLink(relativePath);

        var result = await InvokeExactAsync(
            fixture.PolicyRoot,
            "protocol-authority",
            linkedCommit,
            linkedCommit);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Failed,
            result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Governance validation failed.\n",
            NormalizeNewline(result.StandardError));
    }

    [Theory]
    [InlineData("docs/features/FEAT-0001-example/screenshot.bin")]
    [InlineData("docs/decisions/README.md")]
    public async Task UnrelatedOversizedBlobsDoNotConsumeTheCatalogBudget(
        string relativePath)
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var subjectCommit = fixture.CommitUnrelatedPolicyBlob(
            relativePath,
            600_000);

        var result = await InvokeExactAsync(
            fixture.PolicyRoot,
            "protocol-authority",
            subjectCommit,
            subjectCommit);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Conforming,
            result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
    }

    [Fact]
    public async Task ConsumerRootVersionDoesNotBecomePolicyEvidence()
    {
        using var fixture = GovernanceRealGitFixture.Create();
        var subjectCommit = fixture.CommitConsumerRootVersion(600_000);

        var result = await InvokeExactAsync(
            fixture.ConsumerRoot,
            "consumer",
            subjectCommit,
            fixture.PolicyCommit);

        Assert.Equal(
            (int)GovernanceProcessExitCode.Conforming,
            result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
    }

    private static async Task<CliResult> InvokeExactAsync(
        string repository,
        string profile,
        string subjectCommit,
        string policyCommit,
        CancellationToken cancellationToken = default) =>
        await InvokeArgumentsAsync(
            ExactArguments(repository, profile, subjectCommit),
            () => ExactGitCommitId.Parse(policyCommit),
            cancellationToken);

    private static async Task<CliResult> InvokeArgumentsAsync(
        IReadOnlyList<string> arguments,
        Func<ExactGitCommitId> policySourceResolver,
        CancellationToken cancellationToken = default)
    {
        using var output = new StringWriter();
        using var error = new StringWriter();
        var exitCode = await GovernanceCli.RunExactAsync(
            arguments,
            output,
            error,
            policySourceResolver,
            cancellationToken);
        return new CliResult(exitCode, output.ToString(), error.ToString());
    }

    private static string[] ExactArguments(
        string repository,
        string profile,
        string subjectCommit) =>
        [
            "validate",
            "--repository",
            repository,
            "--profile",
            profile,
            "--subject-commit",
            subjectCommit,
        ];

    private static void AssertExactIdentity(
        JsonElement root,
        string profile,
        string subjectCommit,
        string policyCommit,
        string profileEvidence,
        string verdict)
    {
        Assert.Equal(profile, root.GetProperty("profile").GetString());
        Assert.Equal(
            "exact-commit",
            root.GetProperty("snapshot").GetProperty("mode").GetString());
        Assert.Equal(
            subjectCommit,
            root.GetProperty("snapshot")
                .GetProperty("subjectCommit")
                .GetString());
        Assert.Equal(
            policyCommit,
            root.GetProperty("policy").GetProperty("sourceCommit").GetString());
        Assert.Equal(
            profileEvidence,
            root.GetProperty("policy")
                .GetProperty("profileEvidence")
                .GetString());
        Assert.Equal(verdict, root.GetProperty("verdict").GetString());
    }

    private static string NormalizeNewline(string value) =>
        value.Replace("\r\n", "\n", StringComparison.Ordinal);

    private sealed record CliResult(
        int ExitCode,
        string StandardOutput,
        string StandardError);
}
