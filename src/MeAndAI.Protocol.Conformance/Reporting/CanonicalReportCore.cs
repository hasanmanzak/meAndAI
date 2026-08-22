using System.Buffers.Binary;
using System.Runtime.ExceptionServices;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal sealed class CanonicalRuntimeFrame
{
    internal CanonicalRuntimeFrame(RuntimeQualificationBinding binding)
        : this(
            binding.ProtocolVersion,
            binding.SourceCommit,
            binding.ManifestDigest,
            binding.CatalogDigest,
            binding.PolicyPackBindingDigest,
            binding.RuntimeArtifactDigest,
            binding.TrustAnchorDigest,
            binding.BindingDigest)
    {
    }

    internal CanonicalRuntimeFrame(
        string protocolVersion,
        string sourceCommit,
        ExactSha256Digest manifestDigest,
        ExactSha256Digest catalogDigest,
        ExactSha256Digest policyPackBindingDigest,
        ExactSha256Digest runtimeArtifactDigest,
        ExactSha256Digest trustAnchorDigest,
        ExactSha256Digest bindingDigest)
    {
        ProtocolVersion = protocolVersion;
        SourceCommit = sourceCommit;
        ManifestDigest = manifestDigest;
        CatalogDigest = catalogDigest;
        PolicyPackBindingDigest = policyPackBindingDigest;
        RuntimeArtifactDigest = runtimeArtifactDigest;
        TrustAnchorDigest = trustAnchorDigest;
        BindingDigest = bindingDigest;
    }

    internal string ProtocolVersion { get; }
    internal string SourceCommit { get; }
    internal ExactSha256Digest ManifestDigest { get; }
    internal ExactSha256Digest CatalogDigest { get; }
    internal ExactSha256Digest PolicyPackBindingDigest { get; }
    internal ExactSha256Digest RuntimeArtifactDigest { get; }
    internal ExactSha256Digest TrustAnchorDigest { get; }
    internal ExactSha256Digest BindingDigest { get; }
}

internal sealed class CanonicalActivePolicyFrame
{
    internal CanonicalActivePolicyFrame(
        ExactSha256Digest snapshotDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest activationRecordDigest,
        long activationEpoch,
        ExactSha256Digest dispositionAuthorityBindingDigest,
        ExactSha256Digest waiverSnapshotDigest,
        ExactSha256Digest debtSnapshotDigest,
        DateTimeOffset evaluationUtc)
    {
        SnapshotDigest = snapshotDigest;
        AuthoritySetDigest = authoritySetDigest;
        ActivationRecordDigest = activationRecordDigest;
        ActivationEpoch = activationEpoch;
        DispositionAuthorityBindingDigest = dispositionAuthorityBindingDigest;
        WaiverSnapshotDigest = waiverSnapshotDigest;
        DebtSnapshotDigest = debtSnapshotDigest;
        EvaluationUtc = evaluationUtc;
    }

    internal ExactSha256Digest SnapshotDigest { get; }
    internal ExactSha256Digest AuthoritySetDigest { get; }
    internal ExactSha256Digest ActivationRecordDigest { get; }
    internal long ActivationEpoch { get; }
    internal ExactSha256Digest DispositionAuthorityBindingDigest { get; }
    internal ExactSha256Digest WaiverSnapshotDigest { get; }
    internal ExactSha256Digest DebtSnapshotDigest { get; }
    internal DateTimeOffset EvaluationUtc { get; }
}

internal sealed class CanonicalTransitionFrame
{
    internal CanonicalTransitionFrame(ProposedExtensionTransition transition)
    {
        ActiveSnapshotDigest = transition.ActiveSnapshot.SnapshotDigest;
        ProposedSnapshotDigest = transition.ProposedSnapshot.SnapshotDigest;
        TargetCommit = transition.TargetCommit;
        RationaleDigest = transition.RationaleDigest;
        TransitionDigest = transition.TransitionDigest;
        Changes = Array.AsReadOnly(transition.Changes.ToArray());
    }

    internal ExactSha256Digest ActiveSnapshotDigest { get; }
    internal ExactSha256Digest ProposedSnapshotDigest { get; }
    internal string TargetCommit { get; }
    internal ExactSha256Digest RationaleDigest { get; }
    internal ExactSha256Digest TransitionDigest { get; }
    internal IReadOnlyList<ProposedExtensionChange> Changes { get; }
}

internal sealed class CanonicalReportFrame
{
    internal CanonicalReportFrame(
        string schemaKey,
        string schemaVersion,
        CanonicalRuntimeFrame runtime,
        AcquisitionTarget subjectRepository,
        CatalogVersion catalogVersion,
        ExactSha256Digest catalogDigest,
        string profileName,
        ExecutionProfile profile,
        CanonicalActivePolicyFrame activePolicy,
        CanonicalTransitionFrame? transition,
        AcquisitionStatus acquisitionStatus,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> baselineEvaluations,
        IEnumerable<ExtensionEvaluation> extensionEvaluations,
        IEnumerable<CanonicalFindingDisposition> dispositions,
        bool hasKnownViolation,
        bool hasUnresolvedRequiredEvaluation,
        ExactSha256Digest evidenceSetDigest,
        ExactSha256Digest outcomeSetDigest,
        ConformanceVerdict verdict,
        EnforcementDecision enforcement,
        IReadOnlyDictionary<RuleFinding, ProtectedFindingIdentity>?
            baselineFindingIdentities = null,
        IReadOnlyDictionary<ExtensionFinding, ProtectedFindingIdentity>?
            extensionFindingIdentities = null)
    {
        SchemaKey = schemaKey;
        SchemaVersion = schemaVersion;
        Runtime = runtime;
        SubjectRepository = subjectRepository;
        CatalogVersion = catalogVersion;
        CatalogDigest = catalogDigest;
        ProfileName = profileName;
        Profile = profile;
        ActivePolicy = activePolicy;
        Transition = transition;
        AcquisitionStatus = acquisitionStatus;
        Acquisitions = Array.AsReadOnly(acquisitions.ToArray());
        BaselineEvaluations = Array.AsReadOnly(baselineEvaluations.ToArray());
        ExtensionEvaluations = Array.AsReadOnly(extensionEvaluations.ToArray());
        Dispositions = Array.AsReadOnly(dispositions.ToArray());
        HasKnownViolation = hasKnownViolation;
        HasUnresolvedRequiredEvaluation = hasUnresolvedRequiredEvaluation;
        EvidenceSetDigest = evidenceSetDigest;
        OutcomeSetDigest = outcomeSetDigest;
        Verdict = verdict;
        Enforcement = enforcement;
        BaselineFindingIdentities = SnapshotIdentities(baselineFindingIdentities);
        ExtensionFindingIdentities = SnapshotIdentities(extensionFindingIdentities);
    }

    internal string SchemaKey { get; }
    internal string SchemaVersion { get; }
    internal CanonicalRuntimeFrame Runtime { get; }
    internal AcquisitionTarget SubjectRepository { get; }
    internal CatalogVersion CatalogVersion { get; }
    internal ExactSha256Digest CatalogDigest { get; }
    internal string ProfileName { get; }
    internal ExecutionProfile Profile { get; }
    internal CanonicalActivePolicyFrame ActivePolicy { get; }
    internal CanonicalTransitionFrame? Transition { get; }
    internal AcquisitionStatus AcquisitionStatus { get; }
    internal IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }
    internal IReadOnlyList<RuleEvaluation> BaselineEvaluations { get; }
    internal IReadOnlyList<ExtensionEvaluation> ExtensionEvaluations { get; }
    internal IReadOnlyList<CanonicalFindingDisposition> Dispositions { get; }
    internal bool HasKnownViolation { get; }
    internal bool HasUnresolvedRequiredEvaluation { get; }
    internal ExactSha256Digest EvidenceSetDigest { get; }
    internal ExactSha256Digest OutcomeSetDigest { get; }
    internal ConformanceVerdict Verdict { get; }
    internal EnforcementDecision Enforcement { get; }
    internal IReadOnlyDictionary<RuleFinding, ProtectedFindingIdentity>
        BaselineFindingIdentities
    { get; }
    internal IReadOnlyDictionary<ExtensionFinding, ProtectedFindingIdentity>
        ExtensionFindingIdentities
    { get; }

    private static IReadOnlyDictionary<TFinding, ProtectedFindingIdentity>
        SnapshotIdentities<TFinding>(
            IReadOnlyDictionary<TFinding, ProtectedFindingIdentity>? source)
        where TFinding : class
    {
        var copy = new Dictionary<TFinding, ProtectedFindingIdentity>(
            ReferenceEqualityComparer.Instance);
        if (source is not null)
        {
            foreach (var row in source)
            {
                copy.Add(row.Key, row.Value);
            }
        }

        return copy;
    }
}

internal sealed class CanonicalReportCore
{
    private CanonicalReportCore() { }
    private static readonly byte[] Prefix =
        Encoding.ASCII.GetBytes("protocol.conformance-report/1\n");
    private const int MaximumAcquisitions = 4_096;
    private const int MaximumEvaluations = 200_000;
    private const int MaximumDispositions = 100_000;
    private const int MaximumReferences = 1_000_000;
    private const long MaximumCanonicalBytes = 67_108_864;

    internal static byte[] Write(
        CanonicalReportFrame frame,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(frame);
        cancellationToken.ThrowIfCancellationRequested();
        ValidateResourceCounts(
            frame.Acquisitions.Count,
            checked((long)frame.BaselineEvaluations.Count +
                frame.ExtensionEvaluations.Count),
            frame.Dispositions.Count,
            0);
        var writer = new Writer(cancellationToken);
        writer.Raw(Prefix);
        WriteReport(writer, frame);
        return writer.ToArray();
    }

    internal static void ValidateDigest(
        IReadOnlyList<byte> canonicalBytes,
        ExactSha256Digest expectedDigest)
    {
        ArgumentNullException.ThrowIfNull(canonicalBytes);
        ArgumentNullException.ThrowIfNull(expectedDigest);
        ValidateByteCount(canonicalBytes.Count);
        var retained = new byte[canonicalBytes.Count];
        for (var index = 0; index < retained.Length; index++)
        {
            retained[index] = canonicalBytes[index];
        }

        var actual = ExactSha256Digest.FromHashBytes(SHA256.HashData(retained));
        if (!actual.Equals(expectedDigest))
        {
            throw Integrity(CanonicalReportIntegrityCode.DigestMismatch);
        }
    }

    internal static void ValidatePreflightCounts(
        long acquisitions,
        long evaluations,
        long dispositions,
        long references) => ValidateResourceCounts(
        acquisitions,
        evaluations,
        dispositions,
        references);

    private static void ValidateResourceCounts(
        long acquisitions,
        long evaluations,
        long dispositions,
        long references)
    {
        if (acquisitions < 0 || acquisitions > MaximumAcquisitions ||
            evaluations < 0 || evaluations > MaximumEvaluations ||
            dispositions < 0 || dispositions > MaximumDispositions ||
            references < 0 || references > MaximumReferences)
        {
            throw Integrity(CanonicalReportIntegrityCode.ResourceLimitExceeded);
        }
    }

    private static void ValidateByteCount(long count)
    {
        if (count < 0 || count > MaximumCanonicalBytes)
        {
            throw Integrity(CanonicalReportIntegrityCode.ResourceLimitExceeded);
        }
    }

    private static void WriteReport(Writer writer, CanonicalReportFrame frame)
    {
        writer.String("report");
        writer.String(frame.SchemaKey);
        writer.String(frame.SchemaVersion);
        WriteRuntime(writer, frame.Runtime);
        WriteTarget(writer, frame.SubjectRepository);
        WriteProfile(
            writer,
            frame.CatalogVersion,
            frame.CatalogDigest,
            frame.ProfileName,
            frame.Profile);
        WriteActivePolicy(writer, frame.ActivePolicy);
        writer.Optional(frame.Transition, WriteTransition);
        writer.String(frame.AcquisitionStatus.Value);
        writer.List(OrderAcquisitions(writer, frame.Acquisitions), WriteAcquisition);
        writer.List(OrderBaseline(writer, frame.BaselineEvaluations), (output, row) =>
            WriteBaselineRule(output, row, frame.BaselineFindingIdentities));
        writer.List(OrderExtensions(writer, frame.ExtensionEvaluations), (output, row) =>
            WriteExtensionRule(output, row, frame.ExtensionFindingIdentities));
        writer.List(OrderDispositions(writer, frame.Dispositions), WriteDisposition);
        writer.Bool(frame.HasKnownViolation);
        writer.Bool(frame.HasUnresolvedRequiredEvaluation);
        writer.Digest(frame.EvidenceSetDigest);
        writer.Digest(frame.OutcomeSetDigest);
        writer.String(frame.Verdict.Value);
        writer.String(frame.Enforcement.Value);
    }

    private static void WriteRuntime(Writer writer, CanonicalRuntimeFrame runtime)
    {
        writer.String("runtime");
        writer.String(runtime.ProtocolVersion);
        writer.String(runtime.SourceCommit);
        writer.Digest(runtime.ManifestDigest);
        writer.Digest(runtime.CatalogDigest);
        writer.Digest(runtime.PolicyPackBindingDigest);
        writer.Digest(runtime.RuntimeArtifactDigest);
        writer.Digest(runtime.TrustAnchorDigest);
        writer.Digest(runtime.BindingDigest);
    }

    private static void WriteTarget(Writer writer, AcquisitionTarget target)
    {
        writer.String("target");
        writer.String(target.SubjectIdentity);
        writer.String(target.SourceIdentity);
        writer.String(target.Surface.Value);
        writer.String(target.SnapshotKind.Value);
        writer.String(target.TargetIdentity);
    }

    private static void WriteProfile(
        Writer writer,
        CatalogVersion version,
        ExactSha256Digest catalogDigest,
        string profileName,
        ExecutionProfile profile)
    {
        writer.String("profile");
        writer.UInt32(checked((uint)version.Value));
        writer.Digest(catalogDigest);
        writer.String(profileName);
        writer.String(profile.SubjectRole.Value);
        writer.String(profile.Operation.Value);
        writer.String(profile.SnapshotKind.Value);
        writer.List(profile.Surfaces.Values, static (output, value) =>
            output.String(value.Value));
        writer.String(profile.EnforcementPhase.Value);
    }

    private static void WriteActivePolicy(
        Writer writer,
        CanonicalActivePolicyFrame active)
    {
        writer.String("active-policy");
        writer.Digest(active.SnapshotDigest);
        writer.Digest(active.AuthoritySetDigest);
        writer.Digest(active.ActivationRecordDigest);
        writer.Int64(active.ActivationEpoch);
        writer.Digest(active.DispositionAuthorityBindingDigest);
        writer.Digest(active.WaiverSnapshotDigest);
        writer.Digest(active.DebtSnapshotDigest);
        writer.Int64(UtcTicks(active.EvaluationUtc));
    }

    private static void WriteTransition(
        Writer writer,
        CanonicalTransitionFrame transition)
    {
        writer.String("transition");
        writer.Digest(transition.ActiveSnapshotDigest);
        writer.Digest(transition.ProposedSnapshotDigest);
        writer.String(transition.TargetCommit);
        writer.Digest(transition.RationaleDigest);
        writer.Digest(transition.TransitionDigest);
        writer.List(Ordered(writer, transition.Changes, () =>
            writer.Observe(transition.Changes).OrderBy(
                static row => row.ExtensionId.Value,
                writer.Comparer(StringComparer.Ordinal)).ToArray()),
            WriteChange);
    }

    private static void WriteChange(Writer writer, ProposedExtensionChange change)
    {
        writer.String(change.Kind.Equals(ExtensionTransitionKind.Added)
            ? "added"
            : change.Kind.Equals(ExtensionTransitionKind.Removed)
                ? "removed"
                : "revised");
        writer.String(change.ExtensionId.Value);
        writer.Optional(change.PreviousDefinitionDigest, static (output, value) =>
            output.Digest(value));
        writer.Optional(change.ProposedDefinitionDigest, static (output, value) =>
            output.Digest(value));
    }

    private static void WriteAcquisition(
        Writer writer,
        SealedAcquisitionOutcome acquisition)
    {
        writer.Tick();
        writer.String("acquisition");
        writer.String(acquisition.Slot.SlotKey);
        WriteTarget(writer, acquisition.Target);
        writer.String(acquisition.Status.Value);
        writer.Bool(acquisition.IsProjected);
        writer.Digest(acquisition.OutcomeDigest);
        writer.Optional(acquisition.Scope, WriteScope);
        writer.Optional(acquisition.RequirementAcquisition, WriteRequirementAcquisition);
        writer.Optional(acquisition.ContextProof, WriteReference);
        writer.List(OrderCanonical(writer, acquisition.Attempts, WriteAttempt), WriteAttempt);
        writer.List(OrderFailures(writer, acquisition.Failures), WriteAcquisitionFailure);
    }

    private static void WriteScope(Writer writer, EvidenceScope scope)
    {
        writer.String("scope");
        WriteTarget(writer, scope.Target);
        writer.String("boundary");
        writer.String(scope.Boundary.SnapshotKind.Value);
        writer.String(scope.Boundary.BoundaryIdentity);
        writer.Int64(UtcTicks(scope.Boundary.StartedAtUtc));
        writer.Int64(UtcTicks(scope.Boundary.CompletedAtUtc));
    }

    private static void WriteRequirementAcquisition(
        Writer writer,
        RequirementAcquisition acquisition)
    {
        writer.String("requirement-acquisition");
        WriteRequirement(writer, acquisition.Requirement);
        writer.String(acquisition.ConsistencyClass.Value);
        writer.String("redaction");
        writer.Bool(acquisition.Redaction.RequiredValuesOmitted);
        writer.Bool(acquisition.Redaction.NonRequiredValuesOmitted);
        writer.List(OrderFailures(writer, acquisition.Failures), WriteAcquisitionFailure);
        writer.String(acquisition.Status.Value);
    }

    private static void WriteRequirement(Writer writer, EvidenceRequirement requirement)
    {
        writer.String("requirement");
        writer.String(requirement.Key);
        writer.String(requirement.Surface.Value);
        writer.String(requirement.Kind);
        writer.String(requirement.CompletenessContract);
        writer.String(requirement.PayloadSchemaKey);
        writer.String(requirement.PayloadSchemaVersion);
        writer.List(requirement.AcceptedConsistencyClasses, static (output, value) =>
            output.String(value.Value));
    }

    private static void WriteAttempt(Writer writer, SealedAcquisitionAttempt attempt)
    {
        writer.String("attempt");
        writer.Digest(attempt.Instruction.InstructionDigest);
        writer.String(attempt.AdmissionKind.Value);
        writer.String(attempt.Status.Value);
        writer.Digest(attempt.ReceiptDigest);
        writer.Optional(attempt.Scope, WriteScope);
        writer.Optional(attempt.RequirementAcquisition, WriteRequirementAcquisition);
        writer.List(OrderFailures(writer, attempt.Failures), WriteAcquisitionFailure);
    }

    private static void WriteAcquisitionFailure(
        Writer writer,
        AcquisitionFailure failure)
    {
        writer.String("acquisition-failure");
        writer.String(failure.RequirementKey);
        writer.String(failure.Code);
    }

    private static void WriteBaselineRule(
        Writer writer,
        RuleEvaluation evaluation,
        IReadOnlyDictionary<RuleFinding, ProtectedFindingIdentity> identities)
    {
        writer.Tick();
        writer.String("baseline-rule");
        writer.String(evaluation.RuleId.Value);
        writer.UInt32(checked((uint)evaluation.RuleRevision.Value));
        writer.String(evaluation.Status.Value);
        writer.Bool(evaluation.IsApplicabilityUnresolved);
        writer.List(OrderReferences(writer, evaluation.ApplicabilityReferences), WriteReference);
        writer.List(OrderStrings(writer, evaluation.UnresolvedSlotKeys), static (output, value) =>
            output.String(value));
        writer.List(
            OrderBaselineFindings(writer, evaluation.Findings, identities),
            WriteBaselineFinding);
        writer.List(OrderBaselineFailures(writer, evaluation.Failures), WriteBaselineFailure);
    }

    private static void WriteExtensionRule(
        Writer writer,
        ExtensionEvaluation evaluation,
        IReadOnlyDictionary<ExtensionFinding, ProtectedFindingIdentity> identities)
    {
        writer.Tick();
        writer.String("extension-rule");
        writer.String(evaluation.ExtensionId.Value);
        writer.UInt32(checked((uint)evaluation.RuleRevision.Value));
        writer.String(evaluation.Status.Value);
        writer.Bool(evaluation.IsApplicabilityUnresolved);
        writer.List(OrderReferences(writer, evaluation.ApplicabilityReferences), WriteReference);
        writer.List(OrderStrings(writer, evaluation.UnresolvedSlotKeys), static (output, value) =>
            output.String(value));
        writer.List(
            OrderExtensionFindings(writer, evaluation.Findings, identities),
            WriteExtensionFinding);
        writer.List(OrderExtensionFailures(writer, evaluation.Failures), WriteExtensionFailure);
    }

    private static void WriteBaselineFinding(Writer writer, RuleFinding finding)
    {
        writer.String("baseline-finding");
        writer.String(finding.RuleId.Value);
        writer.UInt32(checked((uint)finding.RuleRevision.Value));
        writer.String(finding.Code.Value);
        writer.String(finding.Severity.Value);
        writer.String(finding.Remediation.Value);
        WriteReference(writer, finding.PrimaryReference);
        writer.List(OrderReferences(writer, finding.RelatedReferences), WriteReference);
    }

    private static void WriteExtensionFinding(Writer writer, ExtensionFinding finding)
    {
        writer.String("extension-finding");
        writer.String(finding.ExtensionId.Value);
        writer.UInt32(checked((uint)finding.RuleRevision.Value));
        writer.String(finding.Code.Value);
        writer.String(finding.Severity.Value);
        writer.String(finding.Remediation.Value);
        WriteReference(writer, finding.PrimaryReference);
        writer.List(OrderReferences(writer, finding.RelatedReferences), WriteReference);
        writer.String(finding.StableStateToken);
        writer.Optional(finding.StableStateValue, static (output, value) =>
            output.String(value));
    }

    private static void WriteBaselineFailure(
        Writer writer,
        RuleEvaluationFailure failure)
    {
        writer.String("baseline-failure");
        writer.String(failure.RuleId.Value);
        writer.UInt32(checked((uint)failure.RuleRevision.Value));
        writer.String(failure.Code.Value);
        WriteReference(writer, failure.PrimaryReference);
        writer.List(OrderReferences(writer, failure.RelatedReferences), WriteReference);
    }

    private static void WriteExtensionFailure(
        Writer writer,
        ExtensionEvaluationFailure failure)
    {
        writer.String("extension-failure");
        writer.String(failure.ExtensionId.Value);
        writer.UInt32(checked((uint)failure.RuleRevision.Value));
        writer.String(failure.Code.Value);
        WriteReference(writer, failure.PrimaryReference);
        writer.List(OrderReferences(writer, failure.RelatedReferences), WriteReference);
    }

    private static void WriteReference(Writer writer, QualifiedEvidenceReference reference)
    {
        writer.Reference();
        writer.String("reference");
        writer.String(reference.Kind.Value);
        writer.Digest(reference.ManifestDigest);
        writer.UInt32(checked((uint)reference.CatalogVersion.Value));
        writer.String(reference.SlotKey);
        writer.String(reference.RequirementKey);
        WriteScope(writer, reference.Scope);
        writer.Digest(reference.QualificationProofDigest);
        writer.Optional(reference.Root, WriteRootReference);
        writer.Optional(reference.Location, WriteLocation);
        writer.List(OrderDerivations(writer, reference.Derivations), WriteDerivation);
        writer.Optional(reference.ExpectedSelectorParentKind, static (output, value) =>
            output.String(value.Value));
        writer.Optional(reference.Selector, WriteSelector);
    }

    private static void WriteRootReference(Writer writer, RootEvidenceReference root)
    {
        writer.String("root-reference");
        WriteScope(writer, root.Scope);
        writer.String(root.SchemaKey);
        writer.String(root.SchemaVersion);
        writer.Digest(root.ContentDigest);
        WriteLocation(writer, root.Location);
        writer.List(OrderStrings(writer, root.RequirementKeys), static (output, value) =>
            output.String(value));
        writer.Int64(UtcTicks(root.CapturedAtUtc));
    }

    private static void WriteDerivation(
        Writer writer,
        QualifiedEvidenceDerivation derivation)
    {
        writer.String("derivation");
        WriteComponent(writer, derivation.Component);
        writer.String(derivation.ArtifactFileName);
        writer.Digest(derivation.ArtifactDigest);
        writer.Optional(derivation.OutputModel, WriteModel);
        writer.Optional(derivation.OutputCapability, WriteCapability);
        writer.String(derivation.TypedNodeKind);
        writer.String(derivation.TypedNodeIdentity);
        WriteLocation(writer, derivation.Location);
    }

    private static void WriteComponent(Writer writer, ComponentTypeIdentity component)
    {
        writer.String("component");
        writer.String(component.ComponentKey);
        writer.String(component.ComponentVersion);
        writer.String(component.AssemblyName);
        writer.String(component.TypeName);
    }

    private static void WriteModel(Writer writer, ModelContractIdentity model)
    {
        writer.String("model");
        writer.String(model.ModelKey);
        writer.String(model.ModelVersion);
        WriteComponent(writer, model.ImplementationType);
    }

    private static void WriteCapability(
        Writer writer,
        CapabilityContractIdentity capability)
    {
        writer.String("capability");
        writer.String(capability.CapabilityKey);
        writer.String(capability.CapabilityVersion);
        WriteComponent(writer, capability.InterfaceType);
    }

    private static void WriteSelector(Writer writer, QualifiedEvidenceSelector selector)
    {
        writer.String("selector");
        writer.String(selector.SelectorKey);
        writer.String(selector.SelectorSchemaKey);
        writer.String(selector.CanonicalValue);
    }

    private static void WriteLocation(Writer writer, EvidenceLocation location)
    {
        switch (location)
        {
            case RepositoryEvidenceLocation repository:
                writer.String("repository-location");
                WriteScope(writer, repository.Scope);
                writer.String(repository.RepositoryRelativePath);
                writer.Optional(repository.BlobIdentity, static (output, value) =>
                    output.String(value));
                writer.Optional(repository.Line, static (output, value) =>
                    output.UInt32(checked((uint)value)));
                writer.Optional(repository.Anchor, static (output, value) =>
                    output.String(value));
                writer.Optional(repository.Property, static (output, value) =>
                    output.String(value));
                return;
            case ProviderEvidenceLocation provider:
                writer.String("provider-location");
                WriteScope(writer, provider.Scope);
                writer.String(provider.ProviderServiceIdentity);
                writer.String(provider.ObjectType);
                writer.String(provider.StableObjectIdentity);
                writer.String(provider.VersionIdentity);
                writer.Optional(provider.Field, static (output, value) =>
                    output.String(value));
                writer.Optional(provider.Line, static (output, value) =>
                    output.UInt32(checked((uint)value)));
                writer.Optional(provider.Fragment, static (output, value) =>
                    output.String(value));
                return;
            case ReleaseAssetEvidenceLocation asset:
                writer.String("release-asset-location");
                WriteScope(writer, asset.Scope);
                writer.String(asset.ReleaseObjectIdentity);
                writer.String(asset.Tag);
                writer.String(asset.AssetName);
                writer.Digest(asset.AssetDigest);
                return;
            case SnapshotEvidenceLocation snapshot:
                writer.String("snapshot-location");
                WriteScope(writer, snapshot.Scope);
                return;
            default:
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }
    }

    private static void WriteDisposition(
        Writer writer,
        CanonicalFindingDisposition disposition)
    {
        writer.Tick();
        var tag = disposition.Disposition.Equals(FindingDisposition.ActiveViolation)
            ? "active"
            : disposition.Disposition.Equals(FindingDisposition.Waived)
                ? "waived"
                : "debt";
        writer.String(tag);
        WriteProtectedFinding(writer, disposition.Finding);
        writer.String(disposition.Disposition.Value);
        if (tag == "waived")
        {
            writer.Digest(disposition.WaiverDeclarationDigest!);
            writer.String(disposition.WaiverDecisionAuthority!.Value);
            writer.Int64(UtcTicks(disposition.WaiverExpiresUtc!.Value));
        }
        else if (tag == "debt")
        {
            writer.Digest(disposition.DebtEntryDigest!);
            writer.String(disposition.DebtAuthority!.Value);
            writer.Int64(UtcTicks(disposition.DebtExpiresUtc!.Value));
        }
    }

    private static void WriteProtectedFinding(
        Writer writer,
        ProtectedFindingIdentity finding)
    {
        writer.String("protected-finding");
        writer.String(finding.Rule.BaselineRuleId is not null
            ? "baseline-policy-rule"
            : "extension-policy-rule");
        writer.String(finding.Rule.BaselineRuleId?.Value ??
            finding.Rule.ExtensionId!.Value);
        writer.UInt32(checked((uint)finding.Rule.Revision.Value));
        writer.String(finding.FindingCode.Value);
        writer.Digest(finding.LocationDigest);
        writer.Digest(finding.EvidenceDigest);
        writer.Digest(finding.ExpectedValueDigest);
        writer.Digest(finding.StableKey.Value);
    }

    private static IReadOnlyList<SealedAcquisitionOutcome> OrderAcquisitions(
        Writer writer,
        IReadOnlyList<SealedAcquisitionOutcome> rows)
    {
        writer.Checkpoint(rows.Count);
        if (writer.Observe(rows).Select(static row => row.Slot.SlotKey)
            .Distinct(StringComparer.Ordinal).Count() != rows.Count)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return Ordered(writer, rows, () => writer.Observe(rows)
            .OrderBy(static row => row.Slot.SlotKey,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.Target.Surface.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.Target.SnapshotKind.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.Target.SubjectIdentity,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.Target.SourceIdentity,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.Target.TargetIdentity,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.OutcomeDigest.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ToArray());
    }

    private static IReadOnlyList<RuleEvaluation> OrderBaseline(
        Writer writer,
        IReadOnlyList<RuleEvaluation> rows) => Ordered(
        writer, rows, () => writer.Observe(rows)
            .OrderBy(static row => row.RuleId.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.RuleRevision.Value,
                writer.Comparer(Comparer<int>.Default))
            .ToArray());

    private static IReadOnlyList<ExtensionEvaluation> OrderExtensions(
        Writer writer,
        IReadOnlyList<ExtensionEvaluation> rows) => Ordered(
        writer, rows, () => writer.Observe(rows)
            .OrderBy(static row => row.ExtensionId.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.RuleRevision.Value,
                writer.Comparer(Comparer<int>.Default))
            .ToArray());

    private static IReadOnlyList<CanonicalFindingDisposition> OrderDispositions(
        Writer writer,
        IReadOnlyList<CanonicalFindingDisposition> rows) => Ordered(
        writer,
        rows,
        () => writer.Observe(rows).OrderBy(
            static row => row.Finding.StableKey.Value.Value,
            writer.Comparer(StringComparer.Ordinal)).ToArray());

    private static IReadOnlyList<RuleFinding> OrderBaselineFindings(
        Writer writer,
        IReadOnlyList<RuleFinding> rows,
        IReadOnlyDictionary<RuleFinding, ProtectedFindingIdentity> identities) =>
        OrderFindings(writer, rows, identities);

    private static IReadOnlyList<ExtensionFinding> OrderExtensionFindings(
        Writer writer,
        IReadOnlyList<ExtensionFinding> rows,
        IReadOnlyDictionary<ExtensionFinding, ProtectedFindingIdentity> identities) =>
        OrderFindings(writer, rows, identities);

    private static IReadOnlyList<TFinding> OrderFindings<TFinding>(
        Writer writer,
        IReadOnlyList<TFinding> rows,
        IReadOnlyDictionary<TFinding, ProtectedFindingIdentity> identities)
        where TFinding : class
    {
        if (writer.Observe(rows).Any(row => !identities.ContainsKey(row)))
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        var ordered = Ordered(writer, rows, () => writer.Observe(rows).OrderBy(
                row => identities[row].StableKey.Value.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ToArray());
        if (writer.Observe(ordered)
            .Select(row => identities[row].StableKey.Value.Value)
            .Distinct(StringComparer.Ordinal).Count() != ordered.Count)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return ordered;
    }

    private static IReadOnlyList<RuleEvaluationFailure> OrderBaselineFailures(
        Writer writer,
        IReadOnlyList<RuleEvaluationFailure> rows) => RequireUniqueCanonical(
        writer,
        Ordered(writer, rows, () => writer.Observe(rows)
            .OrderBy(static row => row.Code.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(row => ReferenceSortDigest(writer, row.PrimaryReference),
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(row => ReferenceSetSortDigest(writer, row.RelatedReferences),
                writer.Comparer(StringComparer.Ordinal))
            .ToArray()),
        WriteBaselineFailure);

    private static IReadOnlyList<ExtensionEvaluationFailure> OrderExtensionFailures(
        Writer writer,
        IReadOnlyList<ExtensionEvaluationFailure> rows) => RequireUniqueCanonical(
        writer,
        Ordered(writer, rows, () => writer.Observe(rows)
            .OrderBy(static row => row.Code.Value,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(row => ReferenceSortDigest(writer, row.PrimaryReference),
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(row => ReferenceSetSortDigest(writer, row.RelatedReferences),
                writer.Comparer(StringComparer.Ordinal))
            .ToArray()),
        WriteExtensionFailure);

    private static IReadOnlyList<QualifiedEvidenceReference> OrderReferences(
        Writer writer,
        IReadOnlyList<QualifiedEvidenceReference> rows) =>
        OrderCanonical(writer, rows, WriteReference);

    private static IReadOnlyList<QualifiedEvidenceDerivation> OrderDerivations(
        Writer writer,
        IReadOnlyList<QualifiedEvidenceDerivation> rows) =>
        OrderCanonical(writer, rows, WriteDerivation);

    private static IReadOnlyList<AcquisitionFailure> OrderFailures(
        Writer writer,
        IReadOnlyList<AcquisitionFailure> rows)
    {
        var ordered = Ordered(writer, rows, () => writer.Observe(rows).OrderBy(
                static row => row.RequirementKey,
                writer.Comparer(StringComparer.Ordinal))
            .ThenBy(static row => row.Code,
                writer.Comparer(StringComparer.Ordinal))
            .ToArray());
        if (writer.Observe(ordered)
            .Select(static row => $"{row.RequirementKey}\n{row.Code}")
            .Distinct(StringComparer.Ordinal).Count() != ordered.Count)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return ordered;
    }

    private static IReadOnlyList<string> OrderStrings(
        Writer writer,
        IReadOnlyList<string> rows)
    {
        var ordered = Ordered(
            writer,
            rows,
            () => writer.Observe(rows)
                .Order(writer.Comparer(StringComparer.Ordinal)).ToArray());
        if (writer.Observe(ordered).Distinct(StringComparer.Ordinal).Count() !=
            ordered.Count)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return ordered;
    }

    private static IReadOnlyList<T> OrderCanonical<T>(
        Writer writer,
        IReadOnlyList<T> rows,
        Action<Writer, T> write)
    {
        writer.Checkpoint(rows.Count);
        var keyed = writer.Observe(rows).Select(row =>
            (Row: row, Key: Convert.ToHexString(CanonicalRow(writer, row, write))))
            .OrderBy(static row => row.Key,
                writer.Comparer(StringComparer.Ordinal)).ToArray();
        writer.Checkpoint(rows.Count);
        if (writer.Observe(keyed).Select(static row => row.Key)
            .Distinct(StringComparer.Ordinal).Count() != keyed.Length)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return writer.Observe(keyed).Select(static row => row.Row).ToArray();
    }

    private static string ReferenceSortDigest(
        Writer writer,
        QualifiedEvidenceReference reference) => Convert.ToHexString(
        SHA256.HashData(CanonicalRow(writer, reference, WriteReference)));

    private static string ReferenceSetSortDigest(
        Writer owner,
        IReadOnlyList<QualifiedEvidenceReference> references)
    {
        var writer = owner.Fork();
        writer.List(OrderReferences(writer, references), WriteReference);
        return Convert.ToHexString(SHA256.HashData(writer.ToArray()));
    }

    private static byte[] CanonicalRow<T>(
        Writer owner,
        T row,
        Action<Writer, T> write)
    {
        owner.CancellationToken.ThrowIfCancellationRequested();
        var writer = owner.Fork();
        writer.Tick();
        write(writer, row);
        return writer.ToArray();
    }

    private static IReadOnlyList<T> RequireUniqueCanonical<T>(
        Writer writer,
        IReadOnlyList<T> rows,
        Action<Writer, T> write)
    {
        if (writer.Observe(rows)
            .Select(row => Convert.ToHexString(CanonicalRow(writer, row, write)))
            .Distinct(StringComparer.Ordinal).Count() != rows.Count)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return rows;
    }

    private static IReadOnlyList<T> Ordered<T>(
        Writer writer,
        IReadOnlyList<T> rows,
        Func<IReadOnlyList<T>> order)
    {
        writer.Checkpoint(rows.Count);
        IReadOnlyList<T> ordered;
        try
        {
            ordered = order();
        }
        catch (InvalidOperationException error)
            when (error.InnerException is OperationCanceledException canceled &&
                  canceled.CancellationToken == writer.CancellationToken)
        {
            ExceptionDispatchInfo.Capture(canceled).Throw();
            throw;
        }

        writer.Checkpoint(rows.Count);
        return ordered;
    }

    private static long UtcTicks(DateTimeOffset value)
    {
        if (value.Offset != TimeSpan.Zero)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return value.Ticks;
    }

    private static CanonicalReportIntegrityException Integrity(
        CanonicalReportIntegrityCode code) => new(code);

    private sealed class CancellationWalk
    {
        private readonly CancellationToken _token;
        private long _observed;

        internal CancellationWalk(CancellationToken token) => _token = token;

        internal CancellationToken Token => _token;

        internal void Tick()
        {
            _observed = checked(_observed + 1);
            if ((_observed & 1_023) == 0)
            {
                _token.ThrowIfCancellationRequested();
            }
        }
    }

    private sealed class Writer
    {
        private static readonly UTF8Encoding StrictUtf8 = new(false, true);
        private readonly MemoryStream _stream = new();
        private readonly CancellationWalk _walk;
        private long _references;

        internal Writer(CancellationToken cancellationToken) =>
            _walk = new CancellationWalk(cancellationToken);

        private Writer(CancellationWalk walk) => _walk = walk;

        internal CancellationToken CancellationToken => _walk.Token;

        internal Writer Fork() => new(_walk);

        internal IEnumerable<T> Observe<T>(IEnumerable<T> values)
        {
            foreach (var value in values)
            {
                Tick();
                yield return value;
            }
        }

        internal IComparer<T> Comparer<T>(IComparer<T> inner) =>
            new CancellationComparer<T>(_walk, inner);

        internal void Checkpoint(long count)
        {
            _ = count;
            CancellationToken.ThrowIfCancellationRequested();
        }

        internal void Tick() => _walk.Tick();

        internal void Reference()
        {
            Tick();
            _references = checked(_references + 1);
            ValidateResourceCounts(0, 0, 0, _references);
        }

        internal void Raw(ReadOnlySpan<byte> value)
        {
            Ensure(value.Length);
            _stream.Write(value);
        }

        internal void String(string value)
        {
            ArgumentNullException.ThrowIfNull(value);
            var bytes = StrictUtf8.GetBytes(value);
            UInt32(checked((uint)bytes.Length));
            Raw(bytes);
        }

        internal void Digest(ExactSha256Digest value)
        {
            ArgumentNullException.ThrowIfNull(value);
            Raw(Convert.FromHexString(value.Value));
        }

        internal void Bool(bool value) => Raw(value ? [1] : [0]);

        internal void UInt32(uint value)
        {
            Span<byte> bytes = stackalloc byte[sizeof(uint)];
            BinaryPrimitives.WriteUInt32BigEndian(bytes, value);
            Raw(bytes);
        }

        internal void Int64(long value)
        {
            Span<byte> bytes = stackalloc byte[sizeof(long)];
            BinaryPrimitives.WriteInt64BigEndian(bytes, value);
            Raw(bytes);
        }

        internal void Optional<T>(T? value, Action<Writer, T> write)
            where T : class
        {
            Bool(value is not null);
            if (value is not null)
            {
                write(this, value);
            }
        }

        internal void Optional<T>(T? value, Action<Writer, T> write)
            where T : struct
        {
            Bool(value.HasValue);
            if (value.HasValue)
            {
                write(this, value.Value);
            }
        }

        internal void List<T>(IReadOnlyList<T> values, Action<Writer, T> write)
        {
            UInt32(checked((uint)values.Count));
            foreach (var value in values)
            {
                Tick();
                write(this, value);
            }
        }

        internal byte[] ToArray() => _stream.ToArray();

        private void Ensure(int additional)
        {
            try
            {
                ValidateByteCount(checked(_stream.Length + additional));
            }
            catch (OverflowException)
            {
                throw Integrity(CanonicalReportIntegrityCode.ResourceLimitExceeded);
            }
        }

        private sealed class CancellationComparer<T> : IComparer<T>
        {
            private readonly CancellationWalk _walk;
            private readonly IComparer<T> _inner;

            internal CancellationComparer(
                CancellationWalk walk,
                IComparer<T> inner)
            {
                _walk = walk;
                _inner = inner;
            }

            public int Compare(T? left, T? right)
            {
                _walk.Tick();
                return _inner.Compare(left!, right!);
            }
        }
    }
}
