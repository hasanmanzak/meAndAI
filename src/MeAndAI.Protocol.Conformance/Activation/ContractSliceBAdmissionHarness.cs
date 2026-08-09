using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

internal interface IContractSliceBActivationProofState
{
    bool ProvesCodecMirror(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<ICodecRegistration> codecRegistrations);
}

internal sealed class ContractSliceBAdmissionHarness
{
    private readonly FinalizedPolicyManifest _manifest;
    private readonly IReadOnlyList<ICodecRegistration> _codecRegistrations;
    private readonly IPolicyActivationProof _activationProof;

    private ContractSliceBAdmissionHarness(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<ICodecRegistration> codecRegistrations,
        IPolicyActivationProof activationProof)
    {
        _manifest = manifest;
        _codecRegistrations = codecRegistrations;
        _activationProof = activationProof;
    }

    internal static ContractSliceBAdmissionHarness Activate(
        FinalizedPolicyManifest manifest,
        IEnumerable<ICodecRegistration> codecRegistrations,
        IPolicyActivationProof activationProof)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(codecRegistrations);
        ArgumentNullException.ThrowIfNull(activationProof);

        var registrations = codecRegistrations.ToArray();
        if (registrations.Any(registration => registration is null))
        {
            throw Integrity(CatalogIntegrityCode.RegistrationMismatch);
        }

        Array.Sort(registrations, CompareRegistrations);
        var declarations = manifest.SchemaRegistry.PayloadSchemas;
        if (registrations.Length != declarations.Count)
        {
            throw Integrity(CatalogIntegrityCode.RegistrationMismatch);
        }

        for (var index = 0; index < declarations.Count; index++)
        {
            if (!ReferenceEquals(
                    registrations[index].Declaration,
                    declarations[index]) ||
                !registrations[index].Accept(RegistrationShapeVisitor.Instance))
            {
                throw Integrity(CatalogIntegrityCode.RegistrationMismatch);
            }
        }

        ValidateActivationProof(manifest, activationProof);
        if (activationProof is not IContractSliceBActivationProofState state ||
            !state.ProvesCodecMirror(manifest, registrations))
        {
            throw Integrity(CatalogIntegrityCode.ActivationProofInvalid);
        }

        return new ContractSliceBAdmissionHarness(
            manifest,
            registrations,
            activationProof);
    }

    private static int CompareRegistrations(
        ICodecRegistration left,
        ICodecRegistration right)
    {
        var key = string.Compare(
            left.Declaration.SchemaKey,
            right.Declaration.SchemaKey,
            StringComparison.Ordinal);
        return key != 0
            ? key
            : string.Compare(
                left.Declaration.SchemaVersion,
                right.Declaration.SchemaVersion,
                StringComparison.Ordinal);
    }

    private static void ValidateActivationProof(
        FinalizedPolicyManifest manifest,
        IPolicyActivationProof activationProof)
    {
        var contract = manifest.ActivationProofContract;
        var component = contract.ProofComponent;
        var proofType = activationProof.GetType();
        var typeMatches = string.Equals(
                proofType.Assembly.GetName().Name,
                component.AssemblyName,
                StringComparison.Ordinal) &&
            string.Equals(
                proofType.FullName,
                component.TypeName,
                StringComparison.Ordinal);
        var componentMatches = manifest.Components.Count(binding =>
            ComponentEquals(binding.Component, component)) == 1;
        var binding = manifest.Components.SingleOrDefault(candidate =>
            ComponentEquals(candidate.Component, component));
        var artifactMatches = binding is not null &&
            manifest.ArtifactFiles.Any(artifact => string.Equals(
                artifact.FileName,
                binding.ArtifactFileName,
                StringComparison.Ordinal));
        var metadataMatches = string.Equals(
                activationProof.ContractKey,
                contract.ContractKey,
                StringComparison.Ordinal) &&
            string.Equals(
                activationProof.ContractVersion,
                contract.ContractVersion,
                StringComparison.Ordinal) &&
            Equals(activationProof.ManifestDigest, manifest.ManifestDigest) &&
            ArtifactsEqual(
                activationProof.VerifiedArtifacts,
                manifest.ArtifactFiles);

        if (!typeMatches ||
            !componentMatches ||
            !artifactMatches ||
            !metadataMatches)
        {
            throw Integrity(CatalogIntegrityCode.ActivationProofInvalid);
        }
    }

    private static bool ComponentEquals(
        ComponentTypeIdentity left,
        ComponentTypeIdentity right) =>
        string.Equals(
            left.ComponentKey,
            right.ComponentKey,
            StringComparison.Ordinal) &&
        string.Equals(
            left.ComponentVersion,
            right.ComponentVersion,
            StringComparison.Ordinal) &&
        string.Equals(
            left.AssemblyName,
            right.AssemblyName,
            StringComparison.Ordinal) &&
        string.Equals(
            left.TypeName,
            right.TypeName,
            StringComparison.Ordinal);

    private static bool ArtifactsEqual(
        IReadOnlyList<ArtifactFileBinding>? left,
        IReadOnlyList<ArtifactFileBinding> right)
    {
        if (left is null || left.Count != right.Count)
        {
            return false;
        }

        for (var index = 0; index < right.Count; index++)
        {
            if (!string.Equals(
                    left[index].FileName,
                    right[index].FileName,
                    StringComparison.Ordinal) ||
                left[index].ByteLength != right[index].ByteLength ||
                !Equals(
                    left[index].ArtifactDigest,
                    right[index].ArtifactDigest))
            {
                return false;
            }
        }

        return true;
    }

    private static CatalogIntegrityException Integrity(
        CatalogIntegrityCode code) => new(code);

    private sealed class RegistrationShapeVisitor :
        ICodecRegistrationVisitor<bool>
    {
        internal static RegistrationShapeVisitor Instance { get; } = new();

        private RegistrationShapeVisitor()
        {
        }

        public bool Visit<TModel>(CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel =>
            ReferenceEquals(
                registration.Declaration.OutputModel,
                registration.OutputModel.Contract) &&
            registration.Codec is not null;
    }
}
