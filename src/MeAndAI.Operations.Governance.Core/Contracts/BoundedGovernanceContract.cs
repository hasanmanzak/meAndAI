using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal static class BoundedGovernanceContract
{
    internal static ProtocolVersion Version { get; } =
        ProtocolVersion.Parse("0.17.0");

    internal static ProtocolReleaseTag ReleaseTag { get; } =
        ProtocolReleaseTag.Parse($"v{Version.Value}");
}
