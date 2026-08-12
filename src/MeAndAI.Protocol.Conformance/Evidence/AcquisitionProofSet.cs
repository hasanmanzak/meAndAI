using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

public sealed class AcquisitionProofSet
{
    private AcquisitionProofSet(
        IReadOnlyList<IObservedQualificationProof> observed,
        IReadOnlyList<IFailedAttemptProof> failed,
        IReadOnlyList<INoInputRoutingProof> noInput)
    {
        Observed = observed;
        Failed = failed;
        NoInput = noInput;
    }

    public IReadOnlyList<IObservedQualificationProof> Observed { get; }

    public IReadOnlyList<IFailedAttemptProof> Failed { get; }

    public IReadOnlyList<INoInputRoutingProof> NoInput { get; }

    public static AcquisitionProofSet Create(
        IEnumerable<IObservedQualificationProof> observed,
        IEnumerable<IFailedAttemptProof> failed,
        IEnumerable<INoInputRoutingProof> noInput)
    {
        ArgumentNullException.ThrowIfNull(observed);
        ArgumentNullException.ThrowIfNull(failed);
        ArgumentNullException.ThrowIfNull(noInput);

        return new AcquisitionProofSet(
            observed.ToArray(),
            failed.ToArray(),
            noInput.ToArray());
    }
}
