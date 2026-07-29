using System.Text;
using MeAndAI.Operations.Governance.Core.Analysis;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ProtocolSubmoduleConfigurationTests
{
    [Fact]
    public void CanonicalProtocolMappingIsParsedOnceAlongsideUnrelatedMappings()
    {
        var content = Encoding.UTF8.GetBytes(
            "[submodule \"vendor/tool\"]\n" +
            "\tpath = vendor/tool\n" +
            "\turl = https://example.invalid/tool.git\n" +
            "[submodule \".ai/protocol\"]\n" +
            "\tpath = .ai/protocol\n" +
            "\turl = https://example.invalid/protocol.git\n");

        var analysis = ProtocolSubmoduleConfiguration.Analyze(content);

        Assert.True(analysis.IsReadable);
        Assert.True(analysis.HasReservedProtocolReference);
        Assert.True(analysis.HasCanonicalProtocolMapping);
    }

    [Theory]
    [InlineData(
        "[submodule \"alias\"]\n\tpath = .ai/protocol\n\turl = x\n")]
    [InlineData(
        "[submodule \".AI/Protocol\"]\n\tpath = .AI/Protocol\n\turl = x\n")]
    [InlineData(
        "[submodule \".ai/protocol\"]\n\tpath = vendor/protocol\n\turl = x\n")]
    [InlineData(
        "[submodule \".ai/protocol\"]\n\tpath = .ai/protocol\n")]
    [InlineData(
        "[submodule \".ai/protocol\"]\n\tpath = .ai/protocol\n\turl = x\n\tbranch = main\n")]
    [InlineData(
        "[submodule \".ai/protocol\"]\n\tpath = .ai/protocol\n\turl = x\n" +
        "[submodule \".ai/protocol\"]\n\tpath = .ai/protocol\n\turl = y\n")]
    public void ReservedButNoncanonicalMappingsFailClosed(string content)
    {
        var analysis = ProtocolSubmoduleConfiguration.Analyze(
            Encoding.UTF8.GetBytes(content));

        Assert.True(analysis.IsReadable);
        Assert.True(analysis.HasReservedProtocolReference);
        Assert.False(analysis.HasCanonicalProtocolMapping);
    }

    [Fact]
    public void UnrelatedMappingDoesNotInventProtocolEvidence()
    {
        var analysis = ProtocolSubmoduleConfiguration.Analyze(
            Encoding.UTF8.GetBytes(
                "[submodule \"vendor/tool\"]\n" +
                "\tpath = vendor/tool\n" +
                "\turl = x\n"));

        Assert.True(analysis.IsReadable);
        Assert.False(analysis.HasReservedProtocolReference);
        Assert.False(analysis.HasCanonicalProtocolMapping);
    }

    [Theory]
    [MemberData(nameof(MalformedConfigurations))]
    public void MalformedBytesAreNotTreatedAsCanonical(byte[] content)
    {
        var analysis = ProtocolSubmoduleConfiguration.Analyze(content);

        Assert.False(analysis.IsReadable);
        Assert.False(analysis.HasCanonicalProtocolMapping);
    }

    public static TheoryData<byte[]> MalformedConfigurations =>
        new()
        {
            Encoding.UTF8.GetBytes(
                "[submodule \".ai/protocol\"]\r\n" +
                "\tpath = .ai/protocol\r\n" +
                "\turl = x\r\n"),
            new byte[] { 0xef, 0xbb, 0xbf, 0x5b, 0x5d, 0x0a },
            new byte[] { 0xff, 0x0a },
            Encoding.UTF8.GetBytes(
                "[submodule \".ai/protocol\"]\n" +
                "\tpath = .ai/protocol\n" +
                "\turl = x"),
        };
}
