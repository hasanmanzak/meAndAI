using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal interface IPlanBoundEvidenceSession;

public sealed class ApplicabilityPlan
{
    internal ApplicabilityPlan(
        CatalogAuthorityKind authorityKind,
        ExecutionProfile profile,
        IEnumerable<AcquisitionTarget> targets,
        IEnumerable<RuleId> ruleIds,
        IEnumerable<EvidenceSlotDeclaration> slots,
        IEnumerable<AcquisitionInstruction> instructions,
        IPlanBoundEvidenceSession evidenceSession,
        AcquisitionTarget? subjectRepository = null)
    {
        AuthorityKind = authorityKind;
        Profile = profile;
        Targets = Array.AsReadOnly(targets.ToArray());
        RuleIds = Array.AsReadOnly(ruleIds.ToArray());
        Slots = Array.AsReadOnly(slots.ToArray());
        Instructions = Array.AsReadOnly(instructions.ToArray());
        EvidenceSession = evidenceSession;
        SubjectRepository = subjectRepository;
    }

    public CatalogAuthorityKind AuthorityKind { get; }

    public ExecutionProfile Profile { get; }

    public IReadOnlyList<AcquisitionTarget> Targets { get; }

    public IReadOnlyList<RuleId> RuleIds { get; }

    public IReadOnlyList<EvidenceSlotDeclaration> Slots { get; }

    public IReadOnlyList<AcquisitionInstruction> Instructions { get; }

    internal IPlanBoundEvidenceSession EvidenceSession { get; }

    internal AcquisitionTarget? SubjectRepository { get; }
}
