namespace MeAndAI.Protocol.Domain;

public sealed class AbsentAcquisitionResult : AcquisitionResult
{
    private AbsentAcquisitionResult(AcquisitionRequest request)
        : base(request, AcquisitionStatus.Incomplete)
    {
    }

    public static AbsentAcquisitionResult Create(AcquisitionRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        return new AbsentAcquisitionResult(request);
    }
}
