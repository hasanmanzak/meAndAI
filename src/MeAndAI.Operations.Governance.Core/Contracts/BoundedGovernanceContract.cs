using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Protocol;
using System.Text;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal static class BoundedGovernanceContract
{
    internal static ProtocolVersion Version { get; } =
        ProtocolVersion.Parse("0.17.0");

    internal static ProtocolReleaseTag ReleaseTag { get; } =
        ProtocolReleaseTag.Parse($"v{Version.Value}");

    internal static InstructionGraphPolicyIdentity InstructionGraph { get; } =
        InstructionGraphPolicyIdentity.Create(
            schema: 2,
            maximumTreeEntries: 65536,
            maximumAggregateTreePathUtf8Bytes: 4194304,
            maximumNodes: 512,
            maximumEdges: 4096,
            maximumDepth: 32,
            maximumParsedBlobBytes: 524288,
            maximumAggregateParsedBytes: 4194304,
            maximumGraphPathUtf8Bytes: 32768);

    internal static ReadOnlyMemory<byte> VersionFileBytes { get; } =
        Encoding.UTF8.GetBytes($"{Version.Value}\n");
}
