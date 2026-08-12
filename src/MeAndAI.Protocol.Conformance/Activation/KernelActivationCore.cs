using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

internal static class KernelActivationCore
{
    internal static CompleteCatalogSnapshot ActivateComplete(
        FinalizedPolicyManifest manifest,
        CompletePolicyPackExport policy,
        IPolicyActivationProof activationProof,
        CompleteCatalogSnapshot? predecessor)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(activationProof);

        var catalog = manifest.CompleteCatalog;
        if (!manifest.AuthorityKind.Equals(
                CatalogAuthorityKind.CompleteProtocolSnapshot) ||
            catalog is null ||
            !ReferenceEquals(policy.Catalog, catalog) ||
            !ReferenceEquals(policy.SchemaRegistry, manifest.SchemaRegistry))
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.ManifestInvalid);
        }

        if (!string.Equals(
                activationProof.ContractKey,
                manifest.ActivationProofContract.ContractKey,
                StringComparison.Ordinal) ||
            !string.Equals(
                activationProof.ContractVersion,
                manifest.ActivationProofContract.ContractVersion,
                StringComparison.Ordinal) ||
            !activationProof.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !ArtifactsEqual(activationProof.VerifiedArtifacts, manifest.ArtifactFiles) ||
            !activationProof.Proves(policy))
        {
            throw new CatalogIntegrityException(
                CatalogIntegrityCode.ActivationProofInvalid);
        }

        if ((catalog.Predecessor.Kind.Equals(CatalogPredecessorKind.Genesis) &&
                predecessor is not null) ||
            (catalog.Predecessor.Kind.Equals(CatalogPredecessorKind.Existing) &&
                predecessor is null))
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.ManifestInvalid);
        }

        RequireRegistrationCardinality(policy);
        RequireManifestComponentClosure(manifest, policy.Components);

        return new CompleteCatalogSnapshot(
            catalog.ProtocolVersion,
            catalog.CatalogVersion,
            manifest.ManifestDigest,
            catalog.CompleteInventoryDigest,
            catalog.Predecessor,
            catalog.BaselineProfileName,
            catalog.Rules,
            catalog.NamedProfiles);
    }

    private static void RequireRegistrationCardinality(CompletePolicyPackExport policy)
    {
        if (policy.CodecRegistrations.Count != 3 ||
            policy.ParserRegistrations.Count != 2 ||
            policy.IndexRegistrations.Count != 4 ||
            policy.DemandProjectorRegistrations.Count != 1 ||
            policy.SelectorRegistrations.Count != 3 ||
            policy.EvaluatorRegistrations.Count != 5 ||
            policy.Components.Count != 18)
        {
            throw new CatalogIntegrityException(
                CatalogIntegrityCode.RegistrationMismatch);
        }
    }

    private static void RequireManifestComponentClosure(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<ComponentTypeIdentity> components)
    {
        var mapped = manifest.Components.Select(item => item.Component).ToArray();
        if (components.Any(component => !mapped.Contains(component)))
        {
            throw new CatalogIntegrityException(
                CatalogIntegrityCode.RegistrationMismatch);
        }
    }

    private static bool ArtifactsEqual(
        IReadOnlyList<ArtifactFileBinding> left,
        IReadOnlyList<ArtifactFileBinding> right) =>
        left.Count == right.Count &&
        left.Zip(right).All(pair => pair.First.Equals(pair.Second));
}
