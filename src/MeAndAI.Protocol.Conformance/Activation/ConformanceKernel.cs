using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    private readonly CatalogSliceProducerGraph _producerGraph;
    private readonly KernelPlanningSession _planningSession;

    private ConformanceKernel(
        CompleteCatalogSnapshot catalog,
        CatalogSliceProducerGraph producerGraph,
        KernelPlanningSession planningSession)
    {
        Catalog = catalog;
        _producerGraph = producerGraph;
        _planningSession = planningSession;
    }

    public static ConformanceKernel Activate(
        FinalizedPolicyManifest manifest,
        CompletePolicyPackExport policy,
        IPolicyActivationProof activationProof,
        CompleteCatalogSnapshot? predecessor)
    {
        var catalog = KernelActivationCore.ActivateComplete(
            manifest,
            policy,
            activationProof,
            predecessor);
        var graph = CatalogSliceProducerGraph.Create(policy);
        return new ConformanceKernel(
            catalog,
            graph,
            new KernelPlanningSession(
                manifest,
                activationProof,
                CatalogAuthorityKind.CompleteProtocolSnapshot,
                manifest.ManifestDigest,
                catalog.CatalogVersion,
                catalog.Rules,
                graph));
    }

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

        return new NamedExecutionProfile(
            profile.Name,
            profile.Axes,
            profile.RuleIds,
            _planningSession);
    }

    public ApplicabilityPlan PlanApplicability(
        NamedExecutionProfile profile,
        IEnumerable<AcquisitionTarget> targets) =>
        ApplicabilityPlanningCore.PlanComplete(
            _planningSession,
            profile,
            targets);

    public ApplicabilityClosure CloseApplicability(
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        ApplicabilityClosureCore.Close(
            _planningSession,
            plan,
            proofs,
            cancellationToken);

    public EvaluationAdvanceResult PlanEvaluation(
        ApplicabilityClosure closure,
        CancellationToken cancellationToken = default) =>
        EvaluationPlanningCore.Plan(
            _planningSession,
            closure,
            cancellationToken);

    public EvaluationAdvanceResult AdvanceEvaluation(
        EvaluationPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default) =>
        EvaluationAdvanceCore.Advance(
            _planningSession,
            plan,
            proofs,
            cancellationToken);

    public CompleteCatalogEvaluation Evaluate(
        EvaluationClosure closure,
        CancellationToken cancellationToken = default)
    {
        return EvaluationAggregationCore.EvaluateComplete(
            _planningSession,
            Catalog,
            closure,
            cancellationToken);
    }
}
