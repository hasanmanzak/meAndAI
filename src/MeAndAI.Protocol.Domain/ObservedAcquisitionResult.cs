namespace MeAndAI.Protocol.Domain;

public sealed class ObservedAcquisitionResult : AcquisitionResult
{
    private ObservedAcquisitionResult(EvidenceContext context)
        : base(context.Request, context.Status)
    {
        Context = context;
    }

    public EvidenceContext Context { get; }

    public static ObservedAcquisitionResult Create(EvidenceContext context)
    {
        ArgumentNullException.ThrowIfNull(context);
        return new ObservedAcquisitionResult(context);
    }
}
