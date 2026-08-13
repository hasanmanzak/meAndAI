namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IDemandProjectorRegistration
{
    AcquisitionDemandProjectorDeclaration Declaration { get; }

    TResult Accept<TResult>(
        IDemandProjectorRegistrationVisitor<TResult> visitor);
}

internal interface IDemandProjectorRegistrationVisitor<TResult>
{
    TResult Visit<TCapability>(
        DemandProjectorRegistration<TCapability> registration)
        where TCapability : class, IEvidenceCapability;
}

internal sealed class DemandProjectorRegistration<TCapability> :
    IDemandProjectorRegistration
    where TCapability : class, IEvidenceCapability
{
    private DemandProjectorRegistration(
        AcquisitionDemandProjectorDeclaration declaration,
        CapabilityTypeToken<TCapability> inputCapability,
        IAcquisitionDemandProjector<TCapability> projector)
    {
        Declaration = declaration;
        InputCapability = inputCapability;
        Projector = projector;
    }

    public AcquisitionDemandProjectorDeclaration Declaration { get; }

    internal CapabilityTypeToken<TCapability> InputCapability { get; }

    internal IAcquisitionDemandProjector<TCapability> Projector { get; }

    internal static DemandProjectorRegistration<TCapability> Create(
        AcquisitionDemandProjectorDeclaration declaration,
        CapabilityTypeToken<TCapability> inputCapability,
        IAcquisitionDemandProjector<TCapability> projector)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(inputCapability);
        ArgumentNullException.ThrowIfNull(projector);
        if (!ReferenceEquals(
                declaration.InputCapability,
                inputCapability.Contract))
        {
            throw new ArgumentException(
                "The capability token must retain the projector input capability.",
                nameof(inputCapability));
        }

        return new DemandProjectorRegistration<TCapability>(
            declaration,
            inputCapability,
            projector);
    }

    public TResult Accept<TResult>(
        IDemandProjectorRegistrationVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return visitor.Visit(this);
    }
}
