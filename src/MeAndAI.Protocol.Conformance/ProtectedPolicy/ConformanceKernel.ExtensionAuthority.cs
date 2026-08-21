using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    public ActivatedExtensionPolicy ActivateExtensions(
        ExtensionCatalogSnapshot activeSnapshot,
        ProtectedExtensionActivationPayload activationPayload,
        ProtectedAuthorityEnvelope activationProof,
        ProtectedPolicyPackBinding policyPackBinding,
        ProtectedAuthorityEnvelope policyPackProof,
        ExtensionPolicyPackExport policy)
    {
        var validation = ExtensionAuthorityCore.Validate(
            Catalog,
            _planningSession.Manifest,
            activeSnapshot,
            activationPayload,
            activationProof,
            policyPackBinding,
            policyPackProof,
            policy);
        return new ActivatedExtensionPolicy(
            validation.Snapshot,
            validation.ActivationPayload,
            validation.PolicyPackBinding,
            validation.Policy,
            validation.ActivationPayload.AuthoritySetDigest,
            validation.ActivationRecordDigest,
            validation.ActivationEpoch);
    }
}
