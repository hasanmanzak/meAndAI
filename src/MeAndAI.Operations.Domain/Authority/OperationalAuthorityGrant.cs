using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Domain.Authority;

public sealed class OperationalAuthorityGrant
{
    private readonly AuthorityGrant authority;

    private OperationalAuthorityGrant(
        OperationStageId stage,
        AuthorityGrant authority)
    {
        Stage = stage;
        this.authority = authority;
    }

    public OperationStageId Stage { get; }

    public IReadOnlyList<OperationalCapability> Capabilities =>
        authority.Capabilities;

    public static OperationalAuthorityGrant Create(
        OperationStageId stage,
        params OperationalCapability[] capabilities)
    {
        ArgumentNullException.ThrowIfNull(stage);

        return new OperationalAuthorityGrant(
            stage,
            AuthorityGrant.Create(capabilities));
    }

    public bool Allows(OperationalCapability capability) =>
        authority.Allows(capability);
}
