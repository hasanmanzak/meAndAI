using System.Diagnostics;
using System.Text;

namespace MeAndAI.Operations.Governance.Tests;

internal sealed class GovernanceRealGitFixture : IDisposable
{
    private readonly string container;

    private GovernanceRealGitFixture(
        string container,
        string policyRoot,
        string consumerRoot,
        string policyCommit,
        string policyLaterCommit,
        string consumerCommit)
    {
        this.container = container;
        PolicyRoot = policyRoot;
        ConsumerRoot = consumerRoot;
        PolicyCommit = policyCommit;
        PolicyLaterCommit = policyLaterCommit;
        ConsumerCommit = consumerCommit;
    }

    internal string PolicyRoot { get; }

    internal string ConsumerRoot { get; }

    internal string PolicyCommit { get; }

    internal string PolicyLaterCommit { get; }

    internal string ConsumerCommit { get; }

    internal static GovernanceRealGitFixture Create()
    {
        var container = Path.Combine(
            Path.GetTempPath(),
            $"meandai-governance-git-{Guid.NewGuid():N}");
        var policyRoot = Path.Combine(container, "policy");
        var consumerRoot = Path.Combine(container, "consumer");
        Directory.CreateDirectory(policyRoot);
        Directory.CreateDirectory(consumerRoot);

        InitializeRepository(policyRoot);
        WriteGovernanceRecords(policyRoot);
        WriteUtf8(Path.Combine(policyRoot, "VERSION"), "0.17.0\n");
        RunGit(policyRoot, "add", "--", ".");
        RunGit(policyRoot, "commit", "-m", "policy fixture");
        var policyCommit = RunGit(policyRoot, "rev-parse", "HEAD").Trim();

        WriteUtf8(Path.Combine(policyRoot, "VERSION"), "9.9.9\n");
        RunGit(policyRoot, "add", "--", "VERSION");
        RunGit(policyRoot, "commit", "-m", "later policy fixture");
        var policyLaterCommit = RunGit(
            policyRoot,
            "rev-parse",
            "HEAD").Trim();

        InitializeRepository(consumerRoot);
        WriteGovernanceRecords(consumerRoot);
        RunGit(
            consumerRoot,
            "-c",
            "protocol.file.allow=always",
            "submodule",
            "add",
            policyRoot,
            ".ai/protocol");
        RunGit(
            Path.Combine(consumerRoot, ".ai", "protocol"),
            "checkout",
            "--detach",
            policyCommit);
        WriteUtf8(
            Path.Combine(consumerRoot, ".gitmodules"),
            "[submodule \".ai/protocol\"]\n" +
            "\tpath = .ai/protocol\n" +
            "\turl = https://example.invalid/protocol.git\n");
        RunGit(consumerRoot, "add", "--", ".");
        RunGit(consumerRoot, "commit", "-m", "consumer fixture");
        var consumerCommit = RunGit(
            consumerRoot,
            "rev-parse",
            "HEAD").Trim();
        RunGit(
            Path.Combine(consumerRoot, ".ai", "protocol"),
            "checkout",
            "--detach",
            policyLaterCommit);

        return new GovernanceRealGitFixture(
            container,
            policyRoot,
            consumerRoot,
            policyCommit,
            policyLaterCommit,
            consumerCommit);
    }

    internal void WritePolicyWorktreeVersion(string version) =>
        WriteUtf8(Path.Combine(PolicyRoot, "VERSION"), version);

    internal string GetIntegratedPolicyCheckoutCommit() =>
        RunGit(
            Path.Combine(ConsumerRoot, ".ai", "protocol"),
            "rev-parse",
            "HEAD").Trim();

    internal string GetPolicyTreeObjectId() =>
        RunGit(PolicyRoot, "rev-parse", $"{PolicyCommit}^{{tree}}").Trim();

    internal string CommitPolicyGitLink(string relativePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        RunGit(PolicyRoot, "checkout", "--detach", PolicyCommit);
        RunGit(
            PolicyRoot,
            "rm",
            "-r",
            "--cached",
            "--",
            relativePath);
        RunGit(
            PolicyRoot,
            "update-index",
            "--add",
            "--cacheinfo",
            "160000",
            PolicyCommit,
            relativePath);
        RunGit(PolicyRoot, "commit", "-m", "linked governance fixture");
        return RunGit(PolicyRoot, "rev-parse", "HEAD").Trim();
    }

    internal string CommitUnrelatedPolicyBlob(
        string relativePath,
        int byteCount) =>
        CommitBlob(
            PolicyRoot,
            PolicyCommit,
            relativePath,
            byteCount,
            "unrelated policy blob fixture");

    internal string CommitConsumerRootVersion(int byteCount) =>
        CommitBlob(
            ConsumerRoot,
            ConsumerCommit,
            "VERSION",
            byteCount,
            "consumer root version fixture");

    internal void RemoveIntegratedPolicyWorktree()
    {
        var path = Path.Combine(ConsumerRoot, ".ai", "protocol");
        Directory.Delete(path, recursive: true);
    }

    public void Dispose()
    {
        if (Directory.Exists(container))
        {
            foreach (var file in Directory.EnumerateFiles(
                         container,
                         "*",
                         SearchOption.AllDirectories))
            {
                File.SetAttributes(file, FileAttributes.Normal);
            }

            foreach (var directory in Directory.EnumerateDirectories(
                         container,
                         "*",
                         SearchOption.AllDirectories))
            {
                var info = new DirectoryInfo(directory);
                info.Attributes &= ~FileAttributes.ReadOnly;
            }

            Directory.Delete(container, recursive: true);
        }
    }

    private static void InitializeRepository(string root)
    {
        RunGit(root, "init", "-b", "main");
        RunGit(root, "config", "user.name", "Governance Fixture");
        RunGit(root, "config", "user.email", "fixture@example.invalid");
        RunGit(root, "config", "commit.gpgsign", "false");
    }

    private static void WriteGovernanceRecords(string root)
    {
        var feature = Path.Combine(
            root,
            "docs",
            "features",
            "FEAT-0001-example");
        var decisions = Path.Combine(root, "docs", "decisions");
        Directory.CreateDirectory(feature);
        Directory.CreateDirectory(decisions);
        WriteUtf8(Path.Combine(feature, "README.md"), "# Feature\n");
        WriteUtf8(Path.Combine(feature, "test-cases.md"), "# Tests\n");
        WriteUtf8(
            Path.Combine(decisions, "DEC-0001-example.md"),
            """
            # DEC-0001 - Example
            - Classification: Decision
            - Status: Accepted
            ## Context
            ## Decision
            ## Consequences
            """);
    }

    private static void WriteUtf8(string path, string value) =>
        File.WriteAllBytes(path, new UTF8Encoding(false).GetBytes(value));

    private static string CommitBlob(
        string root,
        string baseCommit,
        string relativePath,
        int byteCount,
        string message)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(byteCount);
        RunGit(root, "checkout", "--detach", baseCommit);
        var path = Path.Combine(
            root,
            relativePath.Replace('/', Path.DirectorySeparatorChar));
        var parent = Path.GetDirectoryName(path)
            ?? throw new InvalidOperationException(
                "The fixture blob requires one parent directory.");
        Directory.CreateDirectory(parent);
        File.WriteAllBytes(path, Enumerable.Repeat((byte)0xff, byteCount).ToArray());
        RunGit(root, "add", "--", relativePath);
        RunGit(root, "commit", "-m", message);
        return RunGit(root, "rev-parse", "HEAD").Trim();
    }

    private static string RunGit(string root, params string[] arguments)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = "git",
            WorkingDirectory = root,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
        };
        startInfo.ArgumentList.Add("-C");
        startInfo.ArgumentList.Add(root);
        foreach (var argument in arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        startInfo.Environment["GIT_TERMINAL_PROMPT"] = "0";
        using var process = Process.Start(startInfo)
            ?? throw new InvalidOperationException(
                "The Git fixture process could not start.");
        var standardOutput = process.StandardOutput.ReadToEnd();
        var standardError = process.StandardError.ReadToEnd();
        process.WaitForExit();
        if (process.ExitCode != 0)
        {
            throw new InvalidOperationException(
                $"The Git fixture command failed: {standardError}");
        }

        return standardOutput;
    }
}
