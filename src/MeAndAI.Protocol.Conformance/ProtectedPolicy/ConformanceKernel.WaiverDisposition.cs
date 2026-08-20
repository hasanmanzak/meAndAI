using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    internal ProtectedFinding ProtectFinding(
        RuleFinding finding,
        RuleDeclaration declaration) =>
        WaiverDispositionCore.Protect(finding, declaration);

    internal ProtectedFinding ProtectFinding(
        ExtensionFinding finding,
        ExtensionRuleDeclaration declaration,
        ExtensionEvaluatorKindDeclaration evaluatorKind) =>
        WaiverDispositionCore.Protect(finding, declaration, evaluatorKind);

    internal WaiverDispositionOutcome ApplyWaivers(
        ActivatedExtensionPolicy activePolicy,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof,
        ExactSha256Digest evidenceSetDigest,
        IEnumerable<ProtectedFinding> findings) =>
        WaiverDispositionCore.Apply(
            activePolicy,
            waivers,
            historicalDebt,
            payload,
            proof,
            evidenceSetDigest,
            findings);
}
