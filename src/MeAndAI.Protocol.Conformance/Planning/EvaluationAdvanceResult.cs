using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public abstract class EvaluationAdvanceResult
{
    private protected EvaluationAdvanceResult(int completedRoundCount)
    {
        if (completedRoundCount < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(completedRoundCount));
        }

        CompletedRoundCount = completedRoundCount;
    }

    public int CompletedRoundCount { get; }
}

public sealed class EvaluationPlan : EvaluationAdvanceResult
{
    internal EvaluationPlan(
        int completedRoundCount,
        ApplicabilityClosure applicability,
        IEnumerable<EvidenceSlotDeclaration> slots,
        IEnumerable<AcquisitionInstruction> instructions,
        IPlanBoundEvidenceSession evidenceSession)
        : base(completedRoundCount)
    {
        Applicability = applicability;
        Slots = slots.ToArray();
        Instructions = instructions.ToArray();
        EvidenceSession = evidenceSession;
    }

    public ApplicabilityClosure Applicability { get; }

    public IReadOnlyList<EvidenceSlotDeclaration> Slots { get; }

    public IReadOnlyList<AcquisitionInstruction> Instructions { get; }

    internal IPlanBoundEvidenceSession EvidenceSession { get; }
}

public sealed class EvaluationClosure : EvaluationAdvanceResult
{
    private const string RepositoryTreeSlot = "protocol.slot.repository-tree";

    internal EvaluationClosure(
        int completedRoundCount,
        ApplicabilityClosure applicability,
        SealedEvaluationContext context,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> terminalEvaluations)
        : this(
            completedRoundCount,
            applicability,
            context,
            acquisitions,
            terminalEvaluations,
            protectedInput: null)
    {
    }

    internal EvaluationClosure(
        int completedRoundCount,
        ApplicabilityClosure applicability,
        SealedEvaluationContext context,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> terminalEvaluations,
        ProtectedEvaluationInput? protectedInput)
        : base(completedRoundCount)
    {
        Applicability = applicability;
        Context = context;
        Acquisitions = acquisitions.ToArray();
        TerminalEvaluations = terminalEvaluations.ToArray();
        ProtectedInput = protectedInput;
    }

    public ApplicabilityClosure Applicability { get; }

    public SealedEvaluationContext Context { get; }

    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }

    public IReadOnlyList<RuleEvaluation> TerminalEvaluations { get; }

    internal ProtectedEvaluationInput? ProtectedInput { get; }

    internal EvaluationClosure WithProtectedInput(IRepositoryTree repositoryTree)
    {
        ArgumentNullException.ThrowIfNull(repositoryTree);
        if (ProtectedInput is not null ||
            Applicability is null ||
            Applicability.Plan is null ||
            Context is null ||
            Applicability.Plan.EvidenceSession is not KernelPlanningSession session ||
            !Context.ManifestDigest.Equals(session.ManifestDigest) ||
            !Context.CatalogVersion.Equals(session.CatalogVersion))
        {
            throw InvalidPlan();
        }

        SealedAcquisitionOutcome? repositoryTreeOutcome = null;
        foreach (var acquisition in Acquisitions)
        {
            if (acquisition is null || acquisition.Slot is null)
            {
                throw InvalidPlan();
            }

            if (!string.Equals(
                    acquisition.Slot.SlotKey,
                    RepositoryTreeSlot,
                    StringComparison.Ordinal))
            {
                continue;
            }

            if (repositoryTreeOutcome is not null)
            {
                throw InvalidPlan();
            }

            repositoryTreeOutcome = acquisition;
        }

        if (repositoryTreeOutcome is null ||
            repositoryTreeOutcome.Status is null ||
            !repositoryTreeOutcome.Status.Equals(AcquisitionStatus.Complete) ||
            repositoryTreeOutcome.OutcomeDigest is null ||
            repositoryTreeOutcome.Scope is null ||
            repositoryTreeOutcome.ContextProof is not { } contextProof ||
            contextProof.Kind is null ||
            !contextProof.Kind.Equals(QualifiedEvidenceReferenceKind.ContextProof) ||
            contextProof.ManifestDigest is null ||
            !contextProof.ManifestDigest.Equals(Context.ManifestDigest) ||
            contextProof.CatalogVersion is null ||
            !contextProof.CatalogVersion.Equals(Context.CatalogVersion) ||
            !string.Equals(
                contextProof.SlotKey,
                repositoryTreeOutcome.Slot.SlotKey,
                StringComparison.Ordinal) ||
            !string.Equals(
                contextProof.RequirementKey,
                repositoryTreeOutcome.Slot.Requirement.Key,
                StringComparison.Ordinal) ||
            contextProof.Scope is null ||
            !contextProof.Scope.Equals(repositoryTreeOutcome.Scope) ||
            contextProof.QualificationProofDigest is null ||
            repositoryTreeOutcome.Attempts.Count != 1 ||
            !contextProof.QualificationProofDigest.Equals(
                repositoryTreeOutcome.Attempts[0].ReceiptDigest) ||
            Context.AdmittedSlotKeys.Count(slotKey => string.Equals(
                slotKey,
                RepositoryTreeSlot,
                StringComparison.Ordinal)) != 1 ||
            Context.Scopes.Any(scope => scope is null) ||
            Context.Scopes.Count(scope =>
                scope is not null && scope.Equals(contextProof.Scope)) != 1)
        {
            throw InvalidPlan();
        }

        return session.ReplaceIssuedEvaluationClosure(
            this,
            ProtectedEvaluationInput.Create(repositoryTree, contextProof));
    }

    private static CatalogIntegrityException InvalidPlan() =>
        new(CatalogIntegrityCode.PlanStateInvalid);
}

internal sealed class ProtectedEvaluationInput
{
    private const string RepositoryTreeSlot = "protocol.slot.repository-tree";

    private ProtectedEvaluationInput(
        IRuleInputAccess access,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            references)
    {
        Access = access;
        References = references;
    }

    internal IRuleInputAccess Access { get; }

    internal IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference> References
    { get; }

    internal static ProtectedEvaluationInput Create(
        IRepositoryTree repositoryTree,
        QualifiedEvidenceReference contextProof)
    {
        ArgumentNullException.ThrowIfNull(repositoryTree);
        ArgumentNullException.ThrowIfNull(contextProof);
        var handle = QualifiedEvidenceHandle.Create();
        var references = new Dictionary<QualifiedEvidenceHandle,
            QualifiedEvidenceReference>(ReferenceEqualityComparer.Instance)
        {
            [handle] = contextProof,
        };
        return new ProtectedEvaluationInput(
            new ProtectedRuleInputAccess(repositoryTree, handle),
            new System.Collections.ObjectModel.ReadOnlyDictionary<
                QualifiedEvidenceHandle,
                QualifiedEvidenceReference>(references));
    }

    private sealed class ProtectedRuleInputAccess : IRuleInputAccess
    {
        private readonly IRepositoryTree _repositoryTree;
        private readonly QualifiedEvidenceHandle _contextProof;

        internal ProtectedRuleInputAccess(
            IRepositoryTree repositoryTree,
            QualifiedEvidenceHandle contextProof)
        {
            _repositoryTree = repositoryTree;
            _contextProof = contextProof;
        }

        public TCapability GetCapability<TCapability>(string slotKey)
            where TCapability : class, IEvidenceCapability
        {
            if (typeof(TCapability) != typeof(IRepositoryTree) ||
                !string.Equals(
                    slotKey,
                    RepositoryTreeSlot,
                    StringComparison.Ordinal))
            {
                throw new InvalidOperationException(
                    "The requested capability is unavailable.");
            }

            return (TCapability)_repositoryTree;
        }

        public QualifiedEvidenceHandle GetContextProof(string slotKey) =>
            string.Equals(slotKey, RepositoryTreeSlot, StringComparison.Ordinal)
                ? _contextProof
                : throw new InvalidOperationException(
                    "The requested context proof is unavailable.");

        public QualifiedEvidenceHandle GetExpectedReference(
            string selectorKey,
            QualifiedEvidenceHandle parentHandle) =>
            throw new InvalidOperationException(
                "Protected evaluation input does not expose expected references.");
    }
}
