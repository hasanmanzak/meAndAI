using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class ConformanceKernel
{
    private readonly CatalogSliceProducerGraph _producerGraph;

    private ConformanceKernel(
        CompleteCatalogSnapshot catalog,
        CatalogSliceProducerGraph producerGraph)
    {
        Catalog = catalog;
        _producerGraph = producerGraph;
    }

    public static ConformanceKernel Activate(
        FinalizedPolicyManifest manifest,
        CompletePolicyPackExport policy,
        IPolicyActivationProof activationProof,
        CompleteCatalogSnapshot? predecessor) =>
        new(
            KernelActivationCore.ActivateComplete(
                manifest,
                policy,
                activationProof,
                predecessor),
            CatalogSliceProducerGraph.Create(policy));

    public CompleteCatalogSnapshot Catalog { get; }

    internal CatalogSliceProducerGraph ProducerGraph => _producerGraph;

    public NamedExecutionProfile ResolveNamedProfile(string name)
    {
        ArgumentNullException.ThrowIfNull(name);
        var profile = Catalog.NamedProfiles.SingleOrDefault(item =>
            string.Equals(item.Name, name, StringComparison.Ordinal));
        if (profile is null)
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);
        }

        return new NamedExecutionProfile(profile.Name, profile.Axes, profile.RuleIds);
    }

    public ApplicabilityPlan PlanApplicability(
        NamedExecutionProfile profile,
        IEnumerable<AcquisitionTarget> targets) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public ApplicabilityClosure CloseApplicability(
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public EvaluationAdvanceResult PlanEvaluation(
        ApplicabilityClosure closure,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public EvaluationAdvanceResult AdvanceEvaluation(
        EvaluationPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    public CompleteCatalogEvaluation Evaluate(
        EvaluationClosure closure,
        CancellationToken cancellationToken = default) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);
}
