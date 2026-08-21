using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    public ProtectedPolicyEvaluation EvaluateProtected(
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        ActivatedExtensionPolicy activeExtensions,
        ProposedExtensionTransition? proposedTransition,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ProtectedDispositionAuthorityPayload dispositionPayload,
        ProtectedAuthorityEnvelope dispositionProof,
        EnforcementPhase enforcementPhase,
        CancellationToken cancellationToken = default) =>
        DebtEnforcementCore.Evaluate(
            Catalog,
            _planningSession,
            baseline,
            closure,
            activeExtensions,
            proposedTransition,
            waivers,
            historicalDebt,
            dispositionPayload,
            dispositionProof,
            enforcementPhase,
            cancellationToken);

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

    internal DebtEnforcementOutcome ApplyDebtAndEnforcement(
        WaiverDispositionOutcome waiverOutcome,
        HistoricalDebtSnapshot historicalDebt,
        string protocolVersion,
        DateTimeOffset evaluationUtc,
        ConformanceVerdict verdict,
        EnforcementPhase enforcementPhase) =>
        DebtEnforcementCore.Apply(
            waiverOutcome,
            historicalDebt,
            protocolVersion,
            evaluationUtc,
            verdict,
            enforcementPhase);
}
