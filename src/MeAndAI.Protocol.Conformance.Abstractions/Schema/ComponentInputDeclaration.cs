namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ComponentInputDeclaration
{
    private ComponentInputDeclaration(
        ModelContractIdentity? model,
        CapabilityContractIdentity? capability,
        int minimumCount,
        int? maximumCount)
    {
        Model = model;
        Capability = capability;
        MinimumCount = minimumCount;
        MaximumCount = maximumCount;
    }

    public ModelContractIdentity? Model { get; }

    public CapabilityContractIdentity? Capability { get; }

    public int MinimumCount { get; }

    public int? MaximumCount { get; }

    public static ComponentInputDeclaration ForModel(
        ModelContractIdentity model,
        int minimumCount,
        int? maximumCount)
    {
        ArgumentNullException.ThrowIfNull(model);
        ValidateCounts(minimumCount, maximumCount);
        return new ComponentInputDeclaration(
            model,
            capability: null,
            minimumCount,
            maximumCount);
    }

    public static ComponentInputDeclaration ForCapability(
        CapabilityContractIdentity capability,
        int minimumCount,
        int? maximumCount)
    {
        ArgumentNullException.ThrowIfNull(capability);
        ValidateCounts(minimumCount, maximumCount);
        return new ComponentInputDeclaration(
            model: null,
            capability,
            minimumCount,
            maximumCount);
    }

    private static void ValidateCounts(int minimumCount, int? maximumCount)
    {
        DeclarationValidation.NonNegative(minimumCount, nameof(minimumCount));
        if ((minimumCount == 0 && maximumCount == 0) ||
            maximumCount is < 0 ||
            maximumCount < minimumCount)
        {
            throw new ArgumentOutOfRangeException(nameof(maximumCount));
        }
    }
}
