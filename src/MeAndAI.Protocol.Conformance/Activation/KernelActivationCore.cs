using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

internal static class KernelActivationCore
{
    internal static void ValidateSlice(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        IPolicyActivationProof activationProof)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(activationProof);

        var catalog = manifest.Slice;
        if (!manifest.AuthorityKind.Equals(CatalogAuthorityKind.QualificationSlice) ||
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

        RequireSliceRegistrationClosure(manifest, policy, catalog);
    }

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

    private static void RequireSliceRegistrationClosure(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        CatalogSliceDeclaration catalog)
    {
        var selectors = catalog.Rules
            .SelectMany(rule => rule.ExpectedSelectors)
            .DistinctBy(item => item.SelectorKey, StringComparer.Ordinal)
            .OrderBy(item => item.SelectorKey, StringComparer.Ordinal)
            .ToArray();

        var codecsValid = Exact(
            manifest.SchemaRegistry.PayloadSchemas,
            policy.CodecRegistrations,
            (declaration, registration) =>
                ReferenceEquals(declaration, registration.Declaration) &&
                registration.Accept(new CodecShapeVisitor(manifest)));
        var parsersValid = Exact(
            manifest.SchemaRegistry.Parsers,
            policy.ParserRegistrations,
            (declaration, registration) =>
                ReferenceEquals(declaration, registration.Declaration) &&
                registration.Accept(new ParserShapeVisitor(manifest)));
        var indexesValid = Exact(
            manifest.SchemaRegistry.Indexes,
            policy.IndexRegistrations,
            (declaration, registration) =>
                ReferenceEquals(declaration, registration.Declaration) &&
                registration.Accept(new IndexShapeVisitor(manifest)));
        var projectorsValid = Exact(
            manifest.SchemaRegistry.DemandProjectors,
            policy.DemandProjectorRegistrations,
            (declaration, registration) =>
                ReferenceEquals(declaration, registration.Declaration) &&
                registration.Accept(new ProjectorShapeVisitor(manifest)));
        var selectorsValid = Exact(
            selectors,
            policy.SelectorRegistrations,
            (declaration, registration) =>
                ReferenceEquals(declaration.Resolver, registration.Component) &&
                string.Equals(
                    declaration.SelectorSchemaKey,
                    registration.SelectorSchemaKey,
                    StringComparison.Ordinal) &&
                registration.Accept(new SelectorShapeVisitor(manifest)));
        var evaluatorsValid = Exact(
            catalog.Rules,
            policy.EvaluatorRegistrations,
            (declaration, registration) =>
                ReferenceEquals(declaration, registration.Declaration) &&
                MappedTypeMatches(
                    manifest,
                    declaration.Evaluator,
                    registration.Evaluator.GetType()));
        var componentsValid = ExactComponents(manifest, policy.Components);

        if (!codecsValid || !parsersValid || !indexesValid || !projectorsValid ||
            !selectorsValid || !evaluatorsValid || !componentsValid)
        {
            throw new CatalogIntegrityException(
                CatalogIntegrityCode.RegistrationMismatch);
        }
    }

    private static bool Exact<TDeclaration, TRegistration>(
        IReadOnlyList<TDeclaration> declarations,
        IReadOnlyList<TRegistration> registrations,
        Func<TDeclaration, TRegistration, bool> matches)
    {
        if (declarations.Count != registrations.Count)
        {
            return false;
        }

        for (var index = 0; index < declarations.Count; index++)
        {
            if (!matches(declarations[index], registrations[index]))
            {
                return false;
            }
        }

        return true;
    }

    private static bool ExactComponents(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<ComponentTypeIdentity> components)
    {
        if (components.Count != 18)
        {
            return false;
        }

        for (var index = 0; index < components.Count; index++)
        {
            var component = components[index];
            if (manifest.Components.Count(binding =>
                    ComponentMatches(binding.Component, component)) != 1 ||
                (index != 0 && CompareComponents(components[index - 1], component) >= 0))
            {
                return false;
            }
        }

        return true;
    }

    private static int CompareComponents(
        ComponentTypeIdentity left,
        ComponentTypeIdentity right)
    {
        var key = string.CompareOrdinal(left.ComponentKey, right.ComponentKey);
        return key != 0
            ? key
            : string.CompareOrdinal(left.ComponentVersion, right.ComponentVersion);
    }

    private static bool ComponentMatches(
        ComponentTypeIdentity expected,
        ComponentTypeIdentity actual) =>
        string.Equals(expected.ComponentKey, actual.ComponentKey, StringComparison.Ordinal) &&
        string.Equals(expected.ComponentVersion, actual.ComponentVersion, StringComparison.Ordinal) &&
        string.Equals(expected.AssemblyName, actual.AssemblyName, StringComparison.Ordinal) &&
        string.Equals(expected.TypeName, actual.TypeName, StringComparison.Ordinal);

    private static bool TypeMatches(ComponentTypeIdentity expected, Type actual) =>
        string.Equals(
            expected.AssemblyName,
            actual.Assembly.GetName().Name,
            StringComparison.Ordinal) &&
        string.Equals(expected.TypeName, actual.FullName, StringComparison.Ordinal);

    private static bool MappedTypeMatches(
        FinalizedPolicyManifest manifest,
        ComponentTypeIdentity declaration,
        Type actual)
    {
        var bindings = manifest.Components.Where(binding =>
            string.Equals(
                binding.Component.ComponentKey,
                declaration.ComponentKey,
                StringComparison.Ordinal) &&
            string.Equals(
                binding.Component.ComponentVersion,
                declaration.ComponentVersion,
                StringComparison.Ordinal)).ToArray();
        return bindings.Length == 1 && TypeMatches(bindings[0].Component, actual);
    }

    private sealed class CodecShapeVisitor : ICodecRegistrationVisitor<bool>
    {
        private readonly FinalizedPolicyManifest _manifest;

        internal CodecShapeVisitor(FinalizedPolicyManifest manifest) =>
            _manifest = manifest;

        public bool Visit<TModel>(CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel =>
            MappedTypeMatches(
                _manifest,
                registration.Declaration.OutputModel.ImplementationType,
                typeof(TModel)) &&
            MappedTypeMatches(
                _manifest,
                registration.Declaration.Codec,
                registration.Codec.GetType());
    }

    private sealed class ParserShapeVisitor : IParserRegistrationVisitor<bool>
    {
        private readonly FinalizedPolicyManifest _manifest;

        internal ParserShapeVisitor(FinalizedPolicyManifest manifest) =>
            _manifest = manifest;

        public bool Visit<TInput, TOutput>(ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel =>
            MappedTypeMatches(
                _manifest,
                registration.Declaration.OutputModel.ImplementationType,
                typeof(TOutput)) &&
            MappedTypeMatches(
                _manifest,
                registration.Declaration.Parser,
                registration.Parser.GetType());
    }

    private sealed class IndexShapeVisitor : IIndexRegistrationVisitor<bool>
    {
        private readonly FinalizedPolicyManifest _manifest;

        internal IndexShapeVisitor(FinalizedPolicyManifest manifest) =>
            _manifest = manifest;

        public bool Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability =>
            MappedTypeMatches(
                _manifest,
                registration.Declaration.OutputCapability.InterfaceType,
                typeof(TCapability)) &&
            MappedTypeMatches(
                _manifest,
                registration.Declaration.Indexer,
                registration.Indexer.GetType());
    }

    private sealed class ProjectorShapeVisitor :
        IDemandProjectorRegistrationVisitor<bool>
    {
        private readonly FinalizedPolicyManifest _manifest;

        internal ProjectorShapeVisitor(FinalizedPolicyManifest manifest) =>
            _manifest = manifest;

        public bool Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability =>
            MappedTypeMatches(
                _manifest,
                registration.Declaration.InputCapability.InterfaceType,
                typeof(TCapability)) &&
            MappedTypeMatches(
                _manifest,
                registration.Declaration.Projector,
                registration.Projector.GetType());
    }

    private sealed class SelectorShapeVisitor : ISelectorRegistrationVisitor<bool>
    {
        private readonly FinalizedPolicyManifest _manifest;

        internal SelectorShapeVisitor(FinalizedPolicyManifest manifest) =>
            _manifest = manifest;

        public bool Visit<TResolver>(SelectorRegistration<TResolver> registration)
            where TResolver : class, IExpectedSelectorResolver =>
            MappedTypeMatches(_manifest, registration.Component, typeof(TResolver)) &&
            registration.Resolver.GetType() == typeof(TResolver);
    }

    private static bool ArtifactsEqual(
        IReadOnlyList<ArtifactFileBinding> left,
        IReadOnlyList<ArtifactFileBinding> right) =>
        left.Count == right.Count &&
        left.Zip(right).All(pair => pair.First.Equals(pair.Second));
}
