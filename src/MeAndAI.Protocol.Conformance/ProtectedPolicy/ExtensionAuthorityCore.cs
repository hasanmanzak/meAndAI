using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class ExtensionAuthorityCore
{
    private static readonly IReadOnlyDictionary<string, string> ArtifactByAssembly =
        new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["MeAndAI.Protocol.Domain"] = "MeAndAI.Protocol.Domain.dll",
            ["MeAndAI.Protocol.Conformance.Abstractions"] =
                "MeAndAI.Protocol.Conformance.Abstractions.dll",
            ["MeAndAI.Protocol.Conformance"] = "MeAndAI.Protocol.Conformance.dll",
            ["MeAndAI.Protocol.Policy"] = "MeAndAI.Protocol.Policy.dll",
        };

    internal static ExtensionAuthorityValidation Validate(
        CompleteCatalogSnapshot catalog,
        FinalizedPolicyManifest manifest,
        ExtensionCatalogSnapshot activeSnapshot,
        ProtectedExtensionActivationPayload activationPayload,
        ProtectedAuthorityEnvelope activationProof,
        ProtectedPolicyPackBinding policyPackBinding,
        ProtectedAuthorityEnvelope policyPackProof,
        ExtensionPolicyPackExport policy)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(activeSnapshot);
        ArgumentNullException.ThrowIfNull(activationPayload);
        ArgumentNullException.ThrowIfNull(activationProof);
        ArgumentNullException.ThrowIfNull(policyPackBinding);
        ArgumentNullException.ThrowIfNull(policyPackProof);
        ArgumentNullException.ThrowIfNull(policy);

        ValidatePack(catalog, manifest, activationPayload, policyPackBinding,
            policyPackProof, policy);
        ValidateActivationIdentity(manifest, activationPayload, activationProof, policy);
        ValidateSnapshot(activeSnapshot, activationPayload);
        ValidateDefinitions(catalog, activeSnapshot, policy);

        return new ExtensionAuthorityValidation(
            activeSnapshot,
            activationPayload,
            policyPackBinding,
            policy,
            activationProof.AuthorityRecordDigest,
            activationProof.AuthorityEpoch);
    }

    private static void ValidatePack(
        CompleteCatalogSnapshot catalog,
        FinalizedPolicyManifest manifest,
        ProtectedExtensionActivationPayload activationPayload,
        ProtectedPolicyPackBinding binding,
        ProtectedAuthorityEnvelope proof,
        ExtensionPolicyPackExport policy)
    {
        if (!binding.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !binding.ExtensionExportDigest.Equals(policy.ExportDigest) ||
            !binding.BaselineWaiverPolicy.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !proof.AuthorityRecordDigest.Equals(
                activationPayload.ExpectedAuthorityRecordDigest) ||
            proof.AuthorityEpoch != activationPayload.ActivationEpoch ||
            !policy.PolicyPackVerifier.Verify(binding, proof) ||
            !HasExactBaselineWaiverRows(catalog, binding.BaselineWaiverPolicy) ||
            !HasExactArtifactRows(manifest, binding, policy))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.PolicyPackBindingInvalid);
        }
    }

    private static bool HasExactBaselineWaiverRows(
        CompleteCatalogSnapshot catalog,
        BaselineWaiverPolicySnapshot waiverPolicy) =>
        waiverPolicy.Rules.Count == catalog.Rules.Count &&
        waiverPolicy.Rules.Zip(catalog.Rules).All(pair =>
            pair.First.RuleId.Equals(pair.Second.RuleId) &&
            pair.First.RuleRevision.Equals(pair.Second.RuleRevision));

    private static bool HasExactArtifactRows(
        FinalizedPolicyManifest manifest,
        ProtectedPolicyPackBinding binding,
        ExtensionPolicyPackExport policy)
    {
        var manifestArtifacts = manifest.ArtifactFiles.ToDictionary(
            static row => row.FileName,
            StringComparer.Ordinal);
        var expectedComponents = ArtifactByAssembly.Values.ToDictionary(
            static fileName => fileName,
            static _ => new List<string>(),
            StringComparer.Ordinal);
        foreach (var component in policy.Components)
        {
            if (!ArtifactByAssembly.TryGetValue(component.AssemblyName, out var fileName))
            {
                return false;
            }

            expectedComponents[fileName].Add(component.ComponentKey);
        }

        foreach (var components in expectedComponents.Values)
        {
            components.Sort(StringComparer.Ordinal);
        }

        foreach (var row in binding.Artifacts)
        {
            if (!manifestArtifacts.TryGetValue(row.FileName, out var manifestRow) ||
                manifestRow.ByteLength != row.FileLength ||
                !manifestRow.ArtifactDigest.Equals(row.FileDigest) ||
                !expectedComponents.TryGetValue(row.FileName, out var componentKeys) ||
                !row.ComponentKeys.SequenceEqual(componentKeys, StringComparer.Ordinal))
            {
                return false;
            }
        }

        return binding.Artifacts.Count == ArtifactByAssembly.Count;
    }

    private static void ValidateActivationIdentity(
        FinalizedPolicyManifest manifest,
        ProtectedExtensionActivationPayload payload,
        ProtectedAuthorityEnvelope proof,
        ExtensionPolicyPackExport policy)
    {
        if (!payload.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !string.Equals(
                payload.ActivatedTargetCommit,
                manifest.SourceCommit,
                StringComparison.Ordinal) ||
            !proof.AuthorityRecordDigest.Equals(payload.ExpectedAuthorityRecordDigest) ||
            proof.AuthorityEpoch != payload.ActivationEpoch ||
            !policy.ActivationVerifier.Verify(payload, proof))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.ActivationProofInvalid);
        }
    }

    private static void ValidateSnapshot(
        ExtensionCatalogSnapshot snapshot,
        ProtectedExtensionActivationPayload payload)
    {
        if (!string.Equals(
                snapshot.RepositoryNamespace,
                payload.RepositoryNamespace,
                StringComparison.Ordinal) ||
            !snapshot.PolicyBlobDigest.Equals(payload.PolicyBlobDigest) ||
            !snapshot.SnapshotDigest.Equals(payload.ActiveSnapshotDigest))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.ActiveSnapshotMismatch);
        }
    }

    private static void ValidateDefinitions(
        CompleteCatalogSnapshot catalog,
        ExtensionCatalogSnapshot snapshot,
        ExtensionPolicyPackExport policy)
    {
        if (snapshot.Extensions.Count != 0 && string.Equals(
                policy.AuthorityIssuerKeyId,
                "protocol.authority.unprovisioned.extension-policy.v1",
                StringComparison.Ordinal))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.ActivationProofInvalid);
        }

        var registrations = policy.Registrations.ToDictionary(
            static row => row.Declaration.EvaluatorKind,
            StringComparer.Ordinal);
        foreach (var extension in snapshot.Extensions)
        {
            if (!registrations.TryGetValue(extension.EvaluatorKind, out var registration))
            {
                throw new ProtectedPolicyIntegrityException(
                    ProtectedPolicyIntegrityCode.ExtensionEvaluatorUnregistered);
            }
            if (!string.Equals(
                    extension.EvaluatorVersion,
                    registration.Declaration.EvaluatorVersion,
                    StringComparison.Ordinal))
            {
                throw new ProtectedPolicyIntegrityException(
                    ProtectedPolicyIntegrityCode.ExtensionDefinitionInvalid);
            }
        }

        var baselineFindingCodes = catalog.Rules
            .SelectMany(static rule => rule.Findings)
            .Select(static finding => finding.Code.Value)
            .ToHashSet(StringComparer.Ordinal);
        if (policy.EvaluatorKinds.SelectMany(static kind => kind.Findings)
            .Any(finding => baselineFindingCodes.Contains(finding.Code.Value)))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.ExtensionShadow);
        }
    }
}

internal sealed record ExtensionAuthorityValidation(
    ExtensionCatalogSnapshot Snapshot,
    ProtectedExtensionActivationPayload ActivationPayload,
    ProtectedPolicyPackBinding PolicyPackBinding,
    ExtensionPolicyPackExport Policy,
    ExactSha256Digest ActivationRecordDigest,
    long ActivationEpoch);
