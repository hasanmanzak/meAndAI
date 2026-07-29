using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Protocol;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ExactGitOutputParserTests
{
    private const string ObjectIdValue =
        "0123456789abcdef0123456789abcdef01234567";

    [Fact]
    public void NulTreeRecordsPreserveExactUtf8Paths()
    {
        var output = TreeRecord(
            "100644",
            "blob",
            Encoding.UTF8.GetBytes(
                "docs/features/FEAT-0001-example/README.md"));

        var entry = Assert.Single(
            ExactGitOutputParser.ParseTree(output, Limits()));

        Assert.Equal(
            "docs/features/FEAT-0001-example/README.md",
            entry.Path.Value);
        Assert.Equal(ExactGitTreeEntryMode.RegularFile, entry.Mode);
        Assert.Equal(ObjectIdValue, entry.ObjectId.Value);
    }

    [Fact]
    public void GitPathsCannotNormalizeBackslashAliases()
    {
        var output = TreeRecord(
            "100644",
            "blob",
            Encoding.UTF8.GetBytes(
                "docs\\features\\FEAT-0001-example\\README.md"));

        Assert.Throws<InvalidDataException>(() =>
            ExactGitOutputParser.ParseTree(output, Limits()));
    }

    [Fact]
    public void GitPathsRequireStrictUtf8()
    {
        var output = TreeRecord("100644", "blob", [0xff]);

        Assert.Throws<InvalidDataException>(() =>
            ExactGitOutputParser.ParseTree(output, Limits()));
    }

    [Fact]
    public void TreeEntryLimitIsAppliedBeforeProjection()
    {
        var first = TreeRecord(
            "100644",
            "blob",
            "first.md"u8.ToArray());
        var second = TreeRecord(
            "100644",
            "blob",
            "second.md"u8.ToArray());

        Assert.Throws<InvalidDataException>(() =>
            ExactGitOutputParser.ParseTree(
                [.. first, .. second],
                Limits(maximumTreeEntries: 1)));
    }

    [Fact]
    public void UnrelatedLinksDoNotEnterTheGovernanceProjection()
    {
        var output = new[]
            {
                TreeRecord("040000", "tree", "docs"u8.ToArray()),
                TreeRecord(
                    "040000",
                    "tree",
                    "docs/features"u8.ToArray()),
                TreeRecord(
                    "040000",
                    "tree",
                    "docs/features/example"u8.ToArray()),
                TreeRecord(
                    "040000",
                    "tree",
                    "docs/decisions"u8.ToArray()),
                TreeRecord(
                    "120000",
                    "blob",
                    "unrelated/root/example/link"u8.ToArray()),
                TreeRecord(
                    "120000",
                    "blob",
                    "unrelated/root/link"u8.ToArray()),
            }
            .SelectMany(record => record)
            .ToArray();
        var tree = ExactGitOutputParser.ParseTree(output, Limits());

        var selected =
            BoundedGovernanceRepositoryProjection.SelectBlobEntries(
                tree,
                GovernanceProfileId.ProtocolAuthority);

        Assert.Empty(selected);
    }

    [Fact]
    public void BatchContentFramingIsBinarySafe()
    {
        byte[] content = [0x00, 0x0a, 0xff, 0x01];
        var header = Encoding.ASCII.GetBytes(
            $"{ObjectIdValue} blob {content.Length}\n");
        var output = new byte[header.Length + content.Length + 1];
        header.CopyTo(output, 0);
        content.CopyTo(output, header.Length);
        output[^1] = (byte)'\n';

        var result = Assert.Single(
            ExactGitOutputParser.ParseBatchContents(
                output,
                [ExactGitObjectId.Parse(ObjectIdValue)],
                Limits()));

        Assert.False(result.IsMissing);
        Assert.Equal(content, result.Content.ToArray());
    }

    [Fact]
    public void BatchContentRejectsTruncatedPayloads()
    {
        var output = Encoding.ASCII.GetBytes(
            $"{ObjectIdValue} blob 4\nabc\n");

        Assert.Throws<InvalidDataException>(() =>
            ExactGitOutputParser.ParseBatchContents(
                output,
                [ExactGitObjectId.Parse(ObjectIdValue)],
                Limits()));
    }

    [Fact]
    public void BatchCheckDistinguishesCleanlyMissingObjects()
    {
        var output = Encoding.ASCII.GetBytes(
            $"{ObjectIdValue} missing\n");

        var result = ExactGitOutputParser.ParseBatchCheck(
            output,
            ExactGitObjectId.Parse(ObjectIdValue));

        Assert.True(result.IsMissing);
        Assert.Null(result.ObjectType);
    }

    [Fact]
    public void BatchCheckRejectsTrailingRecords()
    {
        var output = Encoding.ASCII.GetBytes(
            $"{ObjectIdValue} commit 12\n{ObjectIdValue} commit 12\n");

        Assert.Throws<InvalidDataException>(() =>
            ExactGitOutputParser.ParseBatchCheck(
                output,
                ExactGitObjectId.Parse(ObjectIdValue)));
    }

    private static ExactRepositoryAcquisitionLimits Limits(
        int maximumTreeEntries = 8) =>
        ExactRepositoryAcquisitionLimits.From(
            InstructionGraphPolicyIdentity.Create(
                schema: 2,
                maximumTreeEntries,
                maximumAggregateTreePathUtf8Bytes: 4096,
                maximumNodes: 8,
                maximumEdges: 8,
                maximumDepth: 4,
                maximumParsedBlobBytes: 1024,
                maximumAggregateParsedBytes: 4096,
                maximumGraphPathUtf8Bytes: 512));

    private static byte[] TreeRecord(
        string mode,
        string type,
        byte[] path)
    {
        var header = Encoding.ASCII.GetBytes(
            $"{mode} {type} {ObjectIdValue}\t");
        return [.. header, .. path, 0x00];
    }
}
