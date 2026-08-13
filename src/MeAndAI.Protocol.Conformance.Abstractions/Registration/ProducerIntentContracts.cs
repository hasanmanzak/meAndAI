using System.Globalization;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal sealed class SemanticModelInput<TInput>
    where TInput : class, IComponentInput
{
    private SemanticModelInput(TInput value, SemanticResourceAllowance resourceAllowance)
    {
        Value = value;
        ResourceAllowance = resourceAllowance;
    }

    internal TInput Value { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }

    internal static SemanticModelInput<TInput> Create(
        TInput value,
        SemanticResourceAllowance resourceAllowance) =>
        new(
            value ?? throw new ArgumentNullException(nameof(value)),
            resourceAllowance ?? throw new ArgumentNullException(nameof(resourceAllowance)));
}

internal sealed class ContextIndexInput<TInput>
    where TInput : class, IComponentInput
{
    private ContextIndexInput(
        TInput value,
        SemanticResourceAllowance resourceAllowance,
        IQualifiedEvidenceDerivationFactory derivations)
    {
        Value = value;
        ResourceAllowance = resourceAllowance;
        Derivations = derivations;
    }

    internal TInput Value { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }
    internal IQualifiedEvidenceDerivationFactory Derivations { get; }

    internal static ContextIndexInput<TInput> Create(
        TInput value,
        SemanticResourceAllowance resourceAllowance,
        IQualifiedEvidenceDerivationFactory derivations) =>
        new(
            value ?? throw new ArgumentNullException(nameof(value)),
            resourceAllowance ?? throw new ArgumentNullException(nameof(resourceAllowance)),
            derivations ?? throw new ArgumentNullException(nameof(derivations)));
}

internal sealed class ExpectedSelectorInput
{
    private ExpectedSelectorInput(
        ExpectedSelectorDeclaration declaration,
        QualifiedEvidenceHandle parent,
        string parentCanonicalValue)
    {
        Declaration = declaration;
        Parent = parent;
        ParentCanonicalValue = parentCanonicalValue;
    }

    internal ExpectedSelectorDeclaration Declaration { get; }
    internal QualifiedEvidenceHandle Parent { get; }
    internal string ParentCanonicalValue { get; }

    internal static ExpectedSelectorInput Create(
        ExpectedSelectorDeclaration declaration,
        QualifiedEvidenceHandle parent,
        string parentCanonicalValue) =>
        new(
            declaration ?? throw new ArgumentNullException(nameof(declaration)),
            parent ?? throw new ArgumentNullException(nameof(parent)),
            string.IsNullOrWhiteSpace(parentCanonicalValue)
                ? throw new ArgumentException("A canonical value is required.", nameof(parentCanonicalValue))
                : parentCanonicalValue);
}

internal sealed class SemanticFailureIntent
{
    private SemanticFailureIntent(
        EvaluationFailureCode code,
        QualifiedEvidenceHandle primaryReference,
        IReadOnlyList<QualifiedEvidenceHandle> relatedReferences)
    {
        Code = code;
        PrimaryReference = primaryReference;
        RelatedReferences = relatedReferences;
    }

    internal EvaluationFailureCode Code { get; }
    internal QualifiedEvidenceHandle PrimaryReference { get; }
    internal IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }

    internal static SemanticFailureIntent Create(
        EvaluationFailureCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences) =>
        new(
            code ?? throw new ArgumentNullException(nameof(code)),
            primaryReference ?? throw new ArgumentNullException(nameof(primaryReference)),
            Snapshot(relatedReferences, nameof(relatedReferences)));

    private static IReadOnlyList<QualifiedEvidenceHandle> Snapshot(
        IEnumerable<QualifiedEvidenceHandle>? values,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        var snapshot = values.ToArray();
        if (snapshot.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", parameterName);
        }

        return Array.AsReadOnly(snapshot);
    }
}

internal sealed class SemanticModelProduct<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private SemanticModelProduct(
        TModel value,
        QualifiedEvidenceHandle parent,
        string typedNodeKind,
        string typedNodeIdentity,
        EvidenceLocation location,
        SemanticResourceLocalUsage claimedLocalUsage)
    {
        Value = value;
        Parent = parent;
        TypedNodeKind = typedNodeKind;
        TypedNodeIdentity = typedNodeIdentity;
        Location = location;
        ClaimedLocalUsage = claimedLocalUsage;
    }

    internal TModel Value { get; }
    internal QualifiedEvidenceHandle Parent { get; }
    internal string TypedNodeKind { get; }
    internal string TypedNodeIdentity { get; }
    internal EvidenceLocation Location { get; }
    internal SemanticResourceLocalUsage ClaimedLocalUsage { get; }

    internal static SemanticModelProduct<TModel> Create(
        TModel value,
        QualifiedEvidenceHandle parent,
        string typedNodeKind,
        string typedNodeIdentity,
        EvidenceLocation location,
        SemanticResourceLocalUsage claimedLocalUsage) =>
        new(
            value ?? throw new ArgumentNullException(nameof(value)),
            parent ?? throw new ArgumentNullException(nameof(parent)),
            Token(typedNodeKind, nameof(typedNodeKind)),
            Token(typedNodeIdentity, nameof(typedNodeIdentity)),
            location ?? throw new ArgumentNullException(nameof(location)),
            claimedLocalUsage ?? throw new ArgumentNullException(nameof(claimedLocalUsage)));

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;
}

internal abstract class SemanticModelIntent<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private SemanticModelIntent()
    {
    }

    internal static SemanticModelIntent<TModel> Produced(SemanticModelProduct<TModel> product) =>
        new ProducedCase(product ?? throw new ArgumentNullException(nameof(product)));

    internal static SemanticModelIntent<TModel> Failed(SemanticFailureIntent failure) =>
        new FailedCase(failure ?? throw new ArgumentNullException(nameof(failure)));

    internal abstract TResult Accept<TResult>(ISemanticModelIntentVisitor<TModel, TResult> visitor);

    private sealed class ProducedCase(SemanticModelProduct<TModel> product) : SemanticModelIntent<TModel>
    {
        internal override TResult Accept<TResult>(ISemanticModelIntentVisitor<TModel, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitProduced(product);
    }

    private sealed class FailedCase(SemanticFailureIntent failure) : SemanticModelIntent<TModel>
    {
        internal override TResult Accept<TResult>(ISemanticModelIntentVisitor<TModel, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitFailed(failure);
    }
}

internal interface ISemanticModelIntentVisitor<TModel, TResult>
    where TModel : class, IProtocolSemanticModel
{
    TResult VisitProduced(SemanticModelProduct<TModel> product);
    TResult VisitFailed(SemanticFailureIntent failure);
}

internal sealed class CapabilityProduct<TCapability>
    where TCapability : class, IEvidenceCapability
{
    private CapabilityProduct(
        TCapability value,
        IReadOnlyList<QualifiedEvidenceHandle> evidence,
        SemanticResourceLocalUsage claimedLocalUsage)
    {
        Value = value;
        Evidence = evidence;
        ClaimedLocalUsage = claimedLocalUsage;
    }

    internal TCapability Value { get; }
    internal IReadOnlyList<QualifiedEvidenceHandle> Evidence { get; }
    internal SemanticResourceLocalUsage ClaimedLocalUsage { get; }

    internal static CapabilityProduct<TCapability> Create(
        TCapability value,
        IEnumerable<QualifiedEvidenceHandle> evidence,
        SemanticResourceLocalUsage claimedLocalUsage) =>
        new(
            value ?? throw new ArgumentNullException(nameof(value)),
            Snapshot(evidence),
            claimedLocalUsage ?? throw new ArgumentNullException(nameof(claimedLocalUsage)));

    private static IReadOnlyList<QualifiedEvidenceHandle> Snapshot(
        IEnumerable<QualifiedEvidenceHandle>? values)
    {
        ArgumentNullException.ThrowIfNull(values);
        var snapshot = values.ToArray();
        if (snapshot.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", nameof(values));
        }

        return Array.AsReadOnly(snapshot);
    }
}

internal abstract class CapabilityIntent<TCapability>
    where TCapability : class, IEvidenceCapability
{
    private CapabilityIntent()
    {
    }

    internal static CapabilityIntent<TCapability> Produced(CapabilityProduct<TCapability> product) =>
        new ProducedCase(product ?? throw new ArgumentNullException(nameof(product)));

    internal static CapabilityIntent<TCapability> Failed(SemanticFailureIntent failure) =>
        new FailedCase(failure ?? throw new ArgumentNullException(nameof(failure)));

    internal abstract TResult Accept<TResult>(ICapabilityIntentVisitor<TCapability, TResult> visitor);

    private sealed class ProducedCase(CapabilityProduct<TCapability> product) : CapabilityIntent<TCapability>
    {
        internal override TResult Accept<TResult>(ICapabilityIntentVisitor<TCapability, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitProduced(product);
    }

    private sealed class FailedCase(SemanticFailureIntent failure) : CapabilityIntent<TCapability>
    {
        internal override TResult Accept<TResult>(ICapabilityIntentVisitor<TCapability, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitFailed(failure);
    }
}

internal interface ICapabilityIntentVisitor<TCapability, TResult>
    where TCapability : class, IEvidenceCapability
{
    TResult VisitProduced(CapabilityProduct<TCapability> product);
    TResult VisitFailed(SemanticFailureIntent failure);
}

internal sealed class SelectorProduct
{
    private SelectorProduct(QualifiedEvidenceHandle parent, string canonicalValue)
    {
        Parent = parent;
        CanonicalValue = canonicalValue;
    }

    internal QualifiedEvidenceHandle Parent { get; }
    internal string CanonicalValue { get; }

    internal static SelectorProduct Create(
        QualifiedEvidenceHandle parent,
        string canonicalValue) =>
        new(
            parent ?? throw new ArgumentNullException(nameof(parent)),
            string.IsNullOrWhiteSpace(canonicalValue)
                ? throw new ArgumentException("A canonical value is required.", nameof(canonicalValue))
                : canonicalValue);
}

internal abstract class SelectorIntent
{
    private SelectorIntent()
    {
    }

    internal static SelectorIntent Resolved(SelectorProduct product) =>
        new ResolvedCase(product ?? throw new ArgumentNullException(nameof(product)));

    internal static SelectorIntent Invalid(CatalogIntegrityCode code) =>
        new InvalidCase(code ?? throw new ArgumentNullException(nameof(code)));

    internal abstract TResult Accept<TResult>(ISelectorIntentVisitor<TResult> visitor);

    private sealed class ResolvedCase(SelectorProduct product) : SelectorIntent
    {
        internal override TResult Accept<TResult>(ISelectorIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitResolved(product);
    }

    private sealed class InvalidCase(CatalogIntegrityCode code) : SelectorIntent
    {
        internal override TResult Accept<TResult>(ISelectorIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitInvalid(code);
    }
}

internal interface ISelectorIntentVisitor<TResult>
{
    TResult VisitResolved(SelectorProduct product);
    TResult VisitInvalid(CatalogIntegrityCode code);
}

internal sealed class SourceReferenceResolutionAuthority
{
    private SourceReferenceResolutionAuthority(
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle authorityProof,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? capturedManifestRepositoryRelativePath,
        string? capturedManifestContentIdentity)
    {
        SourceReference = sourceReference;
        AuthorityProof = authorityProof;
        OwningRepositoryIdentity = owningRepositoryIdentity;
        CommitObjectId = commitObjectId;
        NormalizedTagName = normalizedTagName;
        CapturedSnapshotIdentity = capturedSnapshotIdentity;
        CapturedManifestRepositoryRelativePath = capturedManifestRepositoryRelativePath;
        CapturedManifestContentIdentity = capturedManifestContentIdentity;
    }

    internal QualifiedEvidenceHandle SourceReference { get; }
    internal QualifiedEvidenceHandle AuthorityProof { get; }
    internal string OwningRepositoryIdentity { get; }
    internal string? CommitObjectId { get; }
    internal string? NormalizedTagName { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string? CapturedManifestRepositoryRelativePath { get; }
    internal string? CapturedManifestContentIdentity { get; }

    internal static SourceReferenceResolutionAuthority Create(
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle authorityProof,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? capturedManifestRepositoryRelativePath,
        string? capturedManifestContentIdentity) =>
        new(
            sourceReference ?? throw new ArgumentNullException(nameof(sourceReference)),
            authorityProof ?? throw new ArgumentNullException(nameof(authorityProof)),
            Token(owningRepositoryIdentity, nameof(owningRepositoryIdentity)),
            commitObjectId,
            normalizedTagName,
            capturedSnapshotIdentity,
            capturedManifestRepositoryRelativePath,
            capturedManifestContentIdentity);

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;
}

internal sealed class DemandProjectionInput<TCapability>
    where TCapability : class, IEvidenceCapability
{
    private DemandProjectionInput(
        EvidenceSlotDeclaration outputSlot,
        AcquisitionTarget target,
        IReadOnlyList<TCapability> inputs,
        IReadOnlyList<int> sourceReferenceDerivationDepths,
        IReadOnlyList<SourceReferenceResolutionAuthority> sourceReferenceAuthorities,
        IReadOnlyList<int> sourceAuthorityDerivationDepths,
        SemanticResourceAllowance resourceAllowance)
    {
        OutputSlot = outputSlot;
        Target = target;
        Inputs = inputs;
        SourceReferenceDerivationDepths = sourceReferenceDerivationDepths;
        SourceReferenceAuthorities = sourceReferenceAuthorities;
        SourceAuthorityDerivationDepths = sourceAuthorityDerivationDepths;
        ResourceAllowance = resourceAllowance;
    }

    internal EvidenceSlotDeclaration OutputSlot { get; }
    internal AcquisitionTarget Target { get; }
    internal IReadOnlyList<TCapability> Inputs { get; }
    internal IReadOnlyList<int> SourceReferenceDerivationDepths { get; }
    internal IReadOnlyList<SourceReferenceResolutionAuthority> SourceReferenceAuthorities { get; }
    internal IReadOnlyList<int> SourceAuthorityDerivationDepths { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }

    internal static DemandProjectionInput<TCapability> Create(
        EvidenceSlotDeclaration outputSlot,
        AcquisitionTarget target,
        IEnumerable<TCapability> inputs,
        IEnumerable<int> sourceReferenceDerivationDepths,
        IEnumerable<SourceReferenceResolutionAuthority> sourceReferenceAuthorities,
        IEnumerable<int> sourceAuthorityDerivationDepths,
        SemanticResourceAllowance resourceAllowance)
    {
        var inputValues = Snapshot(inputs, nameof(inputs));
        var referenceDepths = SnapshotDepths(sourceReferenceDerivationDepths, nameof(sourceReferenceDerivationDepths));
        var authorities = Snapshot(sourceReferenceAuthorities, nameof(sourceReferenceAuthorities));
        var authorityDepths = SnapshotDepths(sourceAuthorityDerivationDepths, nameof(sourceAuthorityDerivationDepths));
        if (inputValues.Count != referenceDepths.Count ||
            inputValues.Count != authorities.Count ||
            inputValues.Count != authorityDepths.Count)
        {
            throw new ArgumentException("Projection input cardinalities must match.", nameof(inputs));
        }

        return new DemandProjectionInput<TCapability>(
            outputSlot ?? throw new ArgumentNullException(nameof(outputSlot)),
            target ?? throw new ArgumentNullException(nameof(target)),
            inputValues,
            referenceDepths,
            authorities,
            authorityDepths,
            resourceAllowance ?? throw new ArgumentNullException(nameof(resourceAllowance)));
    }

    private static IReadOnlyList<T> Snapshot<T>(IEnumerable<T>? values, string parameterName)
        where T : class
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        var snapshot = values.ToArray();
        if (snapshot.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", parameterName);
        }

        return Array.AsReadOnly(snapshot);
    }

    private static IReadOnlyList<int> SnapshotDepths(IEnumerable<int>? values, string parameterName)
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        var snapshot = values.ToArray();
        if (snapshot.Any(value => value < 0))
        {
            throw new ArgumentOutOfRangeException(parameterName);
        }

        return Array.AsReadOnly(snapshot);
    }
}

internal sealed class RepositoryTargetResolutionDemandCandidate
{
    private readonly CandidateKind _kind;

    private RepositoryTargetResolutionDemandCandidate(
        CandidateKind kind,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        string? expectedCapturedContentIdentity,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority)
    {
        _kind = kind;
        OwningRepositoryIdentity = owningRepositoryIdentity;
        CommitObjectId = commitObjectId;
        NormalizedTagName = normalizedTagName;
        CapturedSnapshotIdentity = capturedSnapshotIdentity;
        NormalizedRepositoryRelativePath = normalizedRepositoryRelativePath;
        NormalizedFragment = normalizedFragment;
        ExpectedCapturedContentIdentity = expectedCapturedContentIdentity;
        SourceReference = sourceReference;
        SourceAuthority = sourceAuthority;
    }

    internal string OwningRepositoryIdentity { get; }
    internal string? CommitObjectId { get; }
    internal string? NormalizedTagName { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string? NormalizedRepositoryRelativePath { get; }
    internal string? NormalizedFragment { get; }
    internal string? ExpectedCapturedContentIdentity { get; }
    internal QualifiedEvidenceHandle SourceReference { get; }
    internal QualifiedEvidenceHandle SourceAuthority { get; }

    internal static RepositoryTargetResolutionDemandCandidate CommitObject(
        string owningRepositoryIdentity,
        string commitObjectId,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority) =>
        Create(
            CandidateKind.CommitObject,
            owningRepositoryIdentity,
            commitObjectId,
            null,
            null,
            normalizedRepositoryRelativePath,
            normalizedFragment,
            null,
            sourceReference,
            sourceAuthority);

    internal static RepositoryTargetResolutionDemandCandidate TagRoot(
        string owningRepositoryIdentity,
        string normalizedTagName,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority) =>
        Create(
            CandidateKind.TagRoot,
            owningRepositoryIdentity,
            null,
            normalizedTagName,
            null,
            null,
            null,
            null,
            sourceReference,
            sourceAuthority);

    internal static RepositoryTargetResolutionDemandCandidate CapturedSnapshotPath(
        string owningRepositoryIdentity,
        string capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string normalizedFragment,
        string expectedCapturedContentIdentity,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority) =>
        Create(
            CandidateKind.CapturedSnapshotPath,
            owningRepositoryIdentity,
            null,
            null,
            capturedSnapshotIdentity,
            normalizedRepositoryRelativePath,
            normalizedFragment,
            expectedCapturedContentIdentity,
            sourceReference,
            sourceAuthority);

    internal TResult Accept<TResult>(IRepositoryTargetResolutionDemandCandidateVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return _kind switch
        {
            CandidateKind.CommitObject => visitor.VisitCommitObject(
                OwningRepositoryIdentity,
                CommitObjectId!,
                NormalizedRepositoryRelativePath,
                NormalizedFragment,
                SourceReference,
                SourceAuthority),
            CandidateKind.TagRoot => visitor.VisitTagRoot(
                OwningRepositoryIdentity,
                NormalizedTagName!,
                SourceReference,
                SourceAuthority),
            _ => visitor.VisitCapturedSnapshotPath(
                OwningRepositoryIdentity,
                CapturedSnapshotIdentity!,
                NormalizedRepositoryRelativePath!,
                NormalizedFragment!,
                ExpectedCapturedContentIdentity!,
                SourceReference,
                SourceAuthority)
        };
    }

    private static RepositoryTargetResolutionDemandCandidate Create(
        CandidateKind kind,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        string? expectedCapturedContentIdentity,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority) =>
        new(
            kind,
            Token(owningRepositoryIdentity, nameof(owningRepositoryIdentity)),
            commitObjectId,
            normalizedTagName,
            capturedSnapshotIdentity,
            normalizedRepositoryRelativePath,
            normalizedFragment,
            expectedCapturedContentIdentity,
            sourceReference ?? throw new ArgumentNullException(nameof(sourceReference)),
            sourceAuthority ?? throw new ArgumentNullException(nameof(sourceAuthority)));

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;

    private enum CandidateKind
    {
        CommitObject,
        TagRoot,
        CapturedSnapshotPath
    }
}

internal interface IRepositoryTargetResolutionDemandCandidateVisitor<TResult>
{
    TResult VisitCommitObject(
        string owner,
        string commit,
        string? path,
        string? fragment,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    TResult VisitTagRoot(
        string owner,
        string tag,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    TResult VisitCapturedSnapshotPath(
        string owner,
        string capture,
        string path,
        string fragment,
        string expectedContentIdentity,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
}

internal sealed class DemandProjectionProduct
{
    private DemandProjectionProduct(
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate> candidates,
        SemanticResourceLocalUsage claimedLocalUsage)
    {
        Candidates = candidates;
        ClaimedLocalUsage = claimedLocalUsage;
    }

    internal IReadOnlyList<RepositoryTargetResolutionDemandCandidate> Candidates { get; }
    internal SemanticResourceLocalUsage ClaimedLocalUsage { get; }

    internal static DemandProjectionProduct Create(
        IEnumerable<RepositoryTargetResolutionDemandCandidate> candidates,
        SemanticResourceLocalUsage claimedLocalUsage) =>
        new(
            Snapshot(candidates),
            claimedLocalUsage ?? throw new ArgumentNullException(nameof(claimedLocalUsage)));

    private static IReadOnlyList<RepositoryTargetResolutionDemandCandidate> Snapshot(
        IEnumerable<RepositoryTargetResolutionDemandCandidate>? candidates)
    {
        ArgumentNullException.ThrowIfNull(candidates);
        var snapshot = candidates.ToArray();
        if (snapshot.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", nameof(candidates));
        }

        return Array.AsReadOnly(snapshot);
    }
}

internal abstract class DemandProjectionIntent
{
    private DemandProjectionIntent()
    {
    }

    internal static DemandProjectionIntent Projected(DemandProjectionProduct product) =>
        new ProjectedCase(product ?? throw new ArgumentNullException(nameof(product)));

    internal static DemandProjectionIntent Failed(SemanticFailureIntent failure) =>
        new FailedCase(failure ?? throw new ArgumentNullException(nameof(failure)));

    internal abstract TResult Accept<TResult>(IDemandProjectionIntentVisitor<TResult> visitor);

    private sealed class ProjectedCase(DemandProjectionProduct product) : DemandProjectionIntent
    {
        internal override TResult Accept<TResult>(IDemandProjectionIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitProjected(product);
    }

    private sealed class FailedCase(SemanticFailureIntent failure) : DemandProjectionIntent
    {
        internal override TResult Accept<TResult>(IDemandProjectionIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitFailed(failure);
    }
}

internal interface IDemandProjectionIntentVisitor<TResult>
{
    TResult VisitProjected(DemandProjectionProduct product);
    TResult VisitFailed(SemanticFailureIntent failure);
}
