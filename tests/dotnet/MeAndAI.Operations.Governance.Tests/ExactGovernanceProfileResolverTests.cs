using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ExactGovernanceProfileResolverTests
{
    private static readonly ExactGitCommitId PolicyCommit =
        ExactGitCommitId.Parse(
            "0123456789abcdef0123456789abcdef01234567");

    private static readonly ExactGitCommitId ConsumerCommit =
        ExactGitCommitId.Parse(
            "89abcdef0123456789abcdef0123456789abcdef");

    [Fact]
    public void AuthorityRequiresMatchingCommitVersionAndNoConsumerPin()
    {
        var request = GovernanceRequest.Create(
            GovernanceProfileId.ProtocolAuthority,
            PolicyCommit);
        var complete = Capture(
            PolicyCommit,
            VersionEntry(),
            Blob("VERSION", BoundedGovernanceContract.VersionFileBytes));

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Complete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                complete,
                Policy()));

        var mismatchedCommit = GovernanceRequest.Create(
            GovernanceProfileId.ProtocolAuthority,
            ConsumerCommit);
        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                mismatchedCommit,
                Capture(
                    ConsumerCommit,
                    VersionEntry(),
                    Blob("VERSION", BoundedGovernanceContract.VersionFileBytes)),
                Policy()));

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(PolicyCommit),
                Policy()));

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(
                    PolicyCommit,
                    VersionEntry(),
                    Blob("VERSION", Encoding.UTF8.GetBytes("0.17.0"))),
                Policy()));

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(
                    PolicyCommit,
                    VersionEntry(),
                    ProtocolGitLink(),
                    Blob("VERSION", BoundedGovernanceContract.VersionFileBytes)),
                Policy()));

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(
                    PolicyCommit,
                    VersionEntry(),
                    TreeEntry(
                        ".ai",
                        "160000",
                        "commit",
                        PolicyCommit.Value),
                    Blob("VERSION", BoundedGovernanceContract.VersionFileBytes)),
                Policy()));
    }

    [Fact]
    public void AuthorityUsesTheSharedGitModulesParserForConflictingEvidence()
    {
        var request = GovernanceRequest.Create(
            GovernanceProfileId.ProtocolAuthority,
            PolicyCommit);
        var unrelated = GitModules(
            "[submodule \"vendor/tool\"]\n" +
            "\tpath = vendor/tool\n" +
            "\turl = x\n");
        var reserved = GitModules(CanonicalGitModules());
        var unreadable = GitModules("invalid-without-final-lf");

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Complete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(
                    PolicyCommit,
                    VersionEntry(),
                    unrelated.Entry,
                    Blob("VERSION", BoundedGovernanceContract.VersionFileBytes),
                    unrelated.Blob),
                Policy()));
        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(
                    PolicyCommit,
                    VersionEntry(),
                    reserved.Entry,
                    Blob("VERSION", BoundedGovernanceContract.VersionFileBytes),
                    reserved.Blob),
                Policy()));
        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                Capture(
                    PolicyCommit,
                    VersionEntry(),
                    unreadable.Entry,
                    Blob("VERSION", BoundedGovernanceContract.VersionFileBytes),
                    unreadable.Blob),
                Policy()));
    }

    [Fact]
    public void ConsumerRequiresCanonicalPinBeforeProviderAcquisition()
    {
        var request = GovernanceRequest.Create(
            GovernanceProfileId.Consumer,
            ConsumerCommit);
        var gitModules = GitModules(CanonicalGitModules());
        var completeSubject = Capture(
            ConsumerCommit,
            ProtocolGitLink(),
            gitModules.Entry,
            gitModules.Blob);

        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.RequiresIntegratedPolicyVersion,
            ExactGovernanceProfileResolver.ResolveSubject(
                request,
                completeSubject,
                Policy()));

        var invalidCaptures = new[]
        {
            Capture(ConsumerCommit, gitModules.Entry, gitModules.Blob),
            Capture(
                ConsumerCommit,
                TreeEntry(
                    ".ai/protocol",
                    "040000",
                    "tree",
                    PolicyCommit.Value),
                gitModules.Entry,
                gitModules.Blob),
            Capture(
                ConsumerCommit,
                TreeEntry(
                    ".ai/protocol",
                    "160000",
                    "commit",
                    ConsumerCommit.Value),
                gitModules.Entry,
                gitModules.Blob),
            Capture(ConsumerCommit, ProtocolGitLink()),
            Capture(
                ConsumerCommit,
                TreeEntry(
                    ".AI/Protocol",
                    "160000",
                    "commit",
                    PolicyCommit.Value),
                gitModules.Entry,
                gitModules.Blob),
            Capture(
                ConsumerCommit,
                ProtocolGitLink(),
                GitModules("invalid-without-final-lf").Entry,
                GitModules("invalid-without-final-lf").Blob),
        };

        foreach (var invalid in invalidCaptures)
        {
            Assert.Equal(
                ExactGovernanceProfileSubjectResolution.Incomplete,
                ExactGovernanceProfileResolver.ResolveSubject(
                    request,
                    invalid,
                Policy()));
        }

        var sameSubjectRequest = GovernanceRequest.Create(
            GovernanceProfileId.Consumer,
            PolicyCommit);
        Assert.Equal(
            ExactGovernanceProfileSubjectResolution.Incomplete,
            ExactGovernanceProfileResolver.ResolveSubject(
                sameSubjectRequest,
                Capture(
                    PolicyCommit,
                    ProtocolGitLink(),
                    gitModules.Entry,
                    gitModules.Blob),
                Policy()));
    }

    [Fact]
    public void ConsumerProviderVersionCompletesOrLeavesEvidenceIncomplete()
    {
        var pending =
            ExactGovernanceProfileSubjectResolution
                .RequiresIntegratedPolicyVersion;
        var versionEntry = VersionEntry();

        Assert.Same(
            GovernanceProfileEvidenceState.Complete,
            ExactGovernanceProfileResolver.ResolveIntegratedPolicy(
                pending,
                Policy(),
                ExactIntegratedPolicyVersionCapture.Available(
                    PolicyCommit,
                    versionEntry,
                    BoundedGovernanceContract.VersionFileBytes)));
        Assert.Same(
            GovernanceProfileEvidenceState.Incomplete,
            ExactGovernanceProfileResolver.ResolveIntegratedPolicy(
                pending,
                Policy(),
                ExactIntegratedPolicyVersionCapture.Unavailable(
                    PolicyCommit)));
        Assert.Same(
            GovernanceProfileEvidenceState.Incomplete,
            ExactGovernanceProfileResolver.ResolveIntegratedPolicy(
                pending,
                Policy(),
                ExactIntegratedPolicyVersionCapture.Available(
                    PolicyCommit,
                    versionEntry,
                    Encoding.UTF8.GetBytes("0.17.0"))));
        Assert.Same(
            GovernanceProfileEvidenceState.Incomplete,
            ExactGovernanceProfileResolver.ResolveIntegratedPolicy(
                pending,
                Policy(),
                ExactIntegratedPolicyVersionCapture.Available(
                    ConsumerCommit,
                    versionEntry,
                    BoundedGovernanceContract.VersionFileBytes)));
    }

    private static ProtocolPolicyIdentity Policy() =>
        ProtocolPolicyIdentity.CreateCurrent(PolicyCommit);

    private static ExactGitTreeEntry VersionEntry() =>
        TreeEntry(
            "VERSION",
            "100644",
            "blob",
            "1111111111111111111111111111111111111111");

    private static ExactGitTreeEntry ProtocolGitLink() =>
        TreeEntry(
            ".ai/protocol",
            "160000",
            "commit",
            PolicyCommit.Value);

    private static (
        ExactGitTreeEntry Entry,
        KeyValuePair<string, ReadOnlyMemory<byte>> Blob) GitModules(
            string content) =>
        (
            TreeEntry(
                ".gitmodules",
                "100644",
                "blob",
                "2222222222222222222222222222222222222222"),
            new KeyValuePair<string, ReadOnlyMemory<byte>>(
                ".gitmodules",
                Encoding.UTF8.GetBytes(content)));

    private static ExactGitTreeEntry TreeEntry(
        string path,
        string mode,
        string type,
        string objectId) =>
        ExactGitTreeEntry.Create(
            RepositoryRelativePath.FromExactGit(path),
            mode,
            type,
            ExactGitObjectId.Parse(objectId));

    private static KeyValuePair<string, ReadOnlyMemory<byte>> Blob(
        string path,
        ReadOnlyMemory<byte> content) =>
        new(path, content);

    private static ExactGovernanceRepositoryCapture Capture(
        ExactGitCommitId commit,
        params object[] evidence)
    {
        var entries = evidence.OfType<ExactGitTreeEntry>().ToArray();
        var blobs = evidence
            .OfType<KeyValuePair<string, ReadOnlyMemory<byte>>>()
            .ToArray();
        return ExactGovernanceRepositoryCapture.Create(
            commit,
            GovernanceRepositorySnapshot.CreateExact(commit, []),
            entries,
            blobs);
    }

    private static string CanonicalGitModules() =>
        "[submodule \".ai/protocol\"]\n" +
        "\tpath = .ai/protocol\n" +
        "\turl = https://example.invalid/protocol.git\n";
}
