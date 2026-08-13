using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal sealed class RepositoryTreePayloadEntry
{
    private RepositoryTreePayloadEntry(
        string repositoryRelativePath,
        RepositoryEntryKind kind)
    {
        RepositoryRelativePath = repositoryRelativePath;
        Kind = kind;
    }

    internal string RepositoryRelativePath { get; }
    internal RepositoryEntryKind Kind { get; }

    internal static RepositoryTreePayloadEntry Create(
        string repositoryRelativePath,
        RepositoryEntryKind kind)
    {
        ArgumentNullException.ThrowIfNull(repositoryRelativePath);
        ArgumentNullException.ThrowIfNull(kind);
        return new RepositoryTreePayloadEntry(repositoryRelativePath, kind);
    }
}

internal sealed class RepositoryTargetResolutionContent
{
    private RepositoryTargetResolutionContent(
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string observedContentIdentity,
        ReadOnlyMemory<byte> bytes)
    {
        OwningRepositoryIdentity = owningRepositoryIdentity;
        CommitObjectId = commitObjectId;
        CapturedSnapshotIdentity = capturedSnapshotIdentity;
        NormalizedRepositoryRelativePath = normalizedRepositoryRelativePath;
        ObservedContentIdentity = observedContentIdentity;
        Bytes = bytes.ToArray();
    }

    internal string OwningRepositoryIdentity { get; }
    internal string? CommitObjectId { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string NormalizedRepositoryRelativePath { get; }
    internal string ObservedContentIdentity { get; }
    internal ReadOnlyMemory<byte> Bytes { get; }

    internal static RepositoryTargetResolutionContent CommitObject(
        string owningRepositoryIdentity,
        string commitObjectId,
        string normalizedRepositoryRelativePath,
        string observedBlobObjectId,
        ReadOnlyMemory<byte> bytes) =>
        new(
            Token(owningRepositoryIdentity, nameof(owningRepositoryIdentity)),
            Token(commitObjectId, nameof(commitObjectId)),
            null,
            Token(normalizedRepositoryRelativePath, nameof(normalizedRepositoryRelativePath)),
            Token(observedBlobObjectId, nameof(observedBlobObjectId)),
            bytes);

    internal static RepositoryTargetResolutionContent CapturedSnapshotPath(
        string owningRepositoryIdentity,
        string capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string observedContentIdentity,
        ReadOnlyMemory<byte> bytes) =>
        new(
            Token(owningRepositoryIdentity, nameof(owningRepositoryIdentity)),
            null,
            Token(capturedSnapshotIdentity, nameof(capturedSnapshotIdentity)),
            Token(normalizedRepositoryRelativePath, nameof(normalizedRepositoryRelativePath)),
            Token(observedContentIdentity, nameof(observedContentIdentity)),
            bytes);

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;
}

internal abstract class RepositoryTargetResolutionPayloadRow
{
    private RepositoryTargetResolutionPayloadRow(
        RepositoryTargetResolutionDemandItem demandItem) =>
        DemandItem = demandItem;

    internal RepositoryTargetResolutionDemandItem DemandItem { get; }

    internal static RepositoryTargetResolutionPayloadRow MissingCommit(
        RepositoryTargetResolutionDemandItem demandItem) =>
        new MissingCommitCase(Required(demandItem));

    internal static RepositoryTargetResolutionPayloadRow PresentCommit(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedObjectType,
        string observedObjectIdentity) =>
        new PresentCommitCase(
            Required(demandItem),
            Token(observedOwningRepositoryIdentity, nameof(observedOwningRepositoryIdentity)),
            Token(observedObjectType, nameof(observedObjectType)),
            Token(observedObjectIdentity, nameof(observedObjectIdentity)));

    internal static RepositoryTargetResolutionPayloadRow PresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedObjectType,
        string observedObjectIdentity) =>
        new PresentCommitMissingPathCase(
            Required(demandItem),
            Token(observedOwningRepositoryIdentity, nameof(observedOwningRepositoryIdentity)),
            Token(observedObjectType, nameof(observedObjectType)),
            Token(observedObjectIdentity, nameof(observedObjectIdentity)));

    internal static RepositoryTargetResolutionPayloadRow PresentCommitPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedObjectType,
        string observedObjectIdentity,
        string observedRepositoryRelativePath,
        string observedPathObjectType,
        string observedPathObjectIdentity,
        RepositoryTargetResolutionContent? content) =>
        new PresentCommitPathCase(
            Required(demandItem),
            Token(observedOwningRepositoryIdentity, nameof(observedOwningRepositoryIdentity)),
            Token(observedObjectType, nameof(observedObjectType)),
            Token(observedObjectIdentity, nameof(observedObjectIdentity)),
            Token(observedRepositoryRelativePath, nameof(observedRepositoryRelativePath)),
            Token(observedPathObjectType, nameof(observedPathObjectType)),
            Token(observedPathObjectIdentity, nameof(observedPathObjectIdentity)),
            content);

    internal static RepositoryTargetResolutionPayloadRow MissingTag(
        RepositoryTargetResolutionDemandItem demandItem) =>
        new MissingTagCase(Required(demandItem));

    internal static RepositoryTargetResolutionPayloadRow PresentTag(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedRefName,
        string observedRefObjectType,
        string observedRefObjectIdentity,
        string observedPeeledObjectType,
        string observedPeeledObjectIdentity) =>
        new PresentTagCase(
            Required(demandItem),
            Token(observedOwningRepositoryIdentity, nameof(observedOwningRepositoryIdentity)),
            Token(observedRefName, nameof(observedRefName)),
            Token(observedRefObjectType, nameof(observedRefObjectType)),
            Token(observedRefObjectIdentity, nameof(observedRefObjectIdentity)),
            Token(observedPeeledObjectType, nameof(observedPeeledObjectType)),
            Token(observedPeeledObjectIdentity, nameof(observedPeeledObjectIdentity)));

    internal static RepositoryTargetResolutionPayloadRow MissingCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem) =>
        new MissingCapturedPathCase(Required(demandItem));

    internal static RepositoryTargetResolutionPayloadRow PresentCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedCapturedSnapshotIdentity,
        string observedRepositoryRelativePath,
        string observedEntryKind,
        string observedContentIdentity,
        RepositoryTargetResolutionContent content) =>
        new PresentCapturedPathCase(
            Required(demandItem),
            Token(observedOwningRepositoryIdentity, nameof(observedOwningRepositoryIdentity)),
            Token(observedCapturedSnapshotIdentity, nameof(observedCapturedSnapshotIdentity)),
            Token(observedRepositoryRelativePath, nameof(observedRepositoryRelativePath)),
            Token(observedEntryKind, nameof(observedEntryKind)),
            Token(observedContentIdentity, nameof(observedContentIdentity)),
            content ?? throw new ArgumentNullException(nameof(content)));

    internal abstract TResult Accept<TResult>(
        IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor);

    private static RepositoryTargetResolutionDemandItem Required(
        RepositoryTargetResolutionDemandItem demandItem) =>
        demandItem ?? throw new ArgumentNullException(nameof(demandItem));

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;

    private sealed class MissingCommitCase(RepositoryTargetResolutionDemandItem demandItem)
        : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitMissingCommit(DemandItem);
    }

    private sealed class PresentCommitCase(
        RepositoryTargetResolutionDemandItem demandItem,
        string owner,
        string type,
        string identity) : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitPresentCommit(DemandItem, owner, type, identity);
    }

    private sealed class PresentCommitMissingPathCase(
        RepositoryTargetResolutionDemandItem demandItem,
        string owner,
        string type,
        string identity) : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitPresentCommitMissingPath(DemandItem, owner, type, identity);
    }

    private sealed class PresentCommitPathCase(
        RepositoryTargetResolutionDemandItem demandItem,
        string owner,
        string type,
        string identity,
        string path,
        string pathType,
        string pathIdentity,
        RepositoryTargetResolutionContent? content)
        : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitPresentCommitPath(
                    DemandItem,
                    owner,
                    type,
                    identity,
                    path,
                    pathType,
                    pathIdentity,
                    content);
    }

    private sealed class MissingTagCase(RepositoryTargetResolutionDemandItem demandItem)
        : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitMissingTag(DemandItem);
    }

    private sealed class PresentTagCase(
        RepositoryTargetResolutionDemandItem demandItem,
        string owner,
        string refName,
        string refType,
        string refIdentity,
        string peeledType,
        string peeledIdentity) : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitPresentTag(
                DemandItem,
                owner,
                refName,
                refType,
                refIdentity,
                peeledType,
                peeledIdentity);
    }

    private sealed class MissingCapturedPathCase(RepositoryTargetResolutionDemandItem demandItem)
        : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitMissingCapturedPath(DemandItem);
    }

    private sealed class PresentCapturedPathCase(
        RepositoryTargetResolutionDemandItem demandItem,
        string owner,
        string capture,
        string path,
        string entryKind,
        string contentIdentity,
        RepositoryTargetResolutionContent content)
        : RepositoryTargetResolutionPayloadRow(demandItem)
    {
        internal override TResult Accept<TResult>(IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitPresentCapturedPath(
                    DemandItem,
                    owner,
                    capture,
                    path,
                    entryKind,
                    contentIdentity,
                    content);
    }
}

internal interface IRepositoryTargetResolutionPayloadRowVisitor<TResult>
{
    TResult VisitMissingCommit(RepositoryTargetResolutionDemandItem demandItem);
    TResult VisitPresentCommit(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedType,
        string observedIdentity);
    TResult VisitPresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedType,
        string observedIdentity);
    TResult VisitPresentCommitPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedType,
        string observedIdentity,
        string observedPath,
        string observedPathType,
        string observedPathIdentity,
        RepositoryTargetResolutionContent? content);
    TResult VisitMissingTag(RepositoryTargetResolutionDemandItem demandItem);
    TResult VisitPresentTag(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedRefName,
        string observedRefType,
        string observedRefIdentity,
        string observedPeeledType,
        string observedPeeledIdentity);
    TResult VisitMissingCapturedPath(RepositoryTargetResolutionDemandItem demandItem);
    TResult VisitPresentCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedCapture,
        string observedPath,
        string observedEntryKind,
        string observedContentIdentity,
        RepositoryTargetResolutionContent content);
}

internal abstract class CanonicalPayloadWriteSource
{
    private CanonicalPayloadWriteSource(
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest)
    {
        Scope = scope;
        Location = location;
        InstructionDigest = instructionDigest;
        DemandDigest = demandDigest;
    }

    internal EvidenceScope Scope { get; }
    internal EvidenceLocation Location { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }

    internal static CanonicalPayloadWriteSourceIntent RepositoryTree(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTreePayloadEntry> entries)
    {
        var values = Snapshot(entries, nameof(entries));
        return CanonicalPayloadWriteSourceIntent.Created(
            new RepositoryTreeCase(
                Required(scope, nameof(scope)),
                Required(location, nameof(location)),
                Required(instructionDigest, nameof(instructionDigest)),
                Required(demandDigest, nameof(demandDigest)),
                values));
    }

    internal static CanonicalPayloadWriteSourceIntent GovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ReadOnlyMemory<byte> body) =>
        CanonicalPayloadWriteSourceIntent.Created(
            new GovernedTextCase(
                Required(scope, nameof(scope)),
                Required(location, nameof(location)),
                Required(instructionDigest, nameof(instructionDigest)),
                Required(demandDigest, nameof(demandDigest)),
                body.ToArray()));

    internal static CanonicalPayloadWriteSourceIntent RepositoryTargetResolution(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents) =>
        CanonicalPayloadWriteSourceIntent.Created(
            new RepositoryTargetResolutionCase(
                Required(scope, nameof(scope)),
                Required(location, nameof(location)),
                Required(instructionDigest, nameof(instructionDigest)),
                Required(demandDigest, nameof(demandDigest)),
                Snapshot(rows, nameof(rows)),
                Snapshot(contents, nameof(contents))));

    internal abstract TResult Accept<TResult>(ICanonicalPayloadWriteSourceVisitor<TResult> visitor);

    private static T Required<T>(T? value, string parameterName) where T : class =>
        value ?? throw new ArgumentNullException(parameterName);

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

    private sealed class RepositoryTreeCase(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTreePayloadEntry> entries)
        : CanonicalPayloadWriteSource(scope, location, instructionDigest, demandDigest)
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteSourceVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitRepositoryTree(Scope, location, InstructionDigest, DemandDigest, entries);
    }

    private sealed class GovernedTextCase(
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ReadOnlyMemory<byte> body)
        : CanonicalPayloadWriteSource(scope, location, instructionDigest, demandDigest)
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteSourceVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitGovernedText(Scope, Location, InstructionDigest, DemandDigest, body);
    }

    private sealed class RepositoryTargetResolutionCase(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents)
        : CanonicalPayloadWriteSource(scope, location, instructionDigest, demandDigest)
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteSourceVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitRepositoryTargetResolution(
                Scope,
                location,
                InstructionDigest,
                DemandDigest,
                rows,
                contents);
    }
}

internal abstract class CanonicalPayloadWriteSourceIntent
{
    private CanonicalPayloadWriteSourceIntent()
    {
    }

    internal static CanonicalPayloadWriteSourceIntent Created(CanonicalPayloadWriteSource source) =>
        new CreatedCase(source ?? throw new ArgumentNullException(nameof(source)));

    internal static CanonicalPayloadWriteSourceIntent Rejected(
        string schemaKey,
        string schemaVersion,
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        string codecFailureCode) =>
        new RejectedCase(
            Token(schemaKey, nameof(schemaKey)),
            Token(schemaVersion, nameof(schemaVersion)),
            scope ?? throw new ArgumentNullException(nameof(scope)),
            location ?? throw new ArgumentNullException(nameof(location)),
            instructionDigest ?? throw new ArgumentNullException(nameof(instructionDigest)),
            demandDigest ?? throw new ArgumentNullException(nameof(demandDigest)),
            Token(codecFailureCode, nameof(codecFailureCode)));

    internal abstract TResult Accept<TResult>(ICanonicalPayloadWriteSourceIntentVisitor<TResult> visitor);

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;

    private sealed class CreatedCase(CanonicalPayloadWriteSource source) : CanonicalPayloadWriteSourceIntent
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteSourceIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitCreated(source);
    }

    private sealed class RejectedCase(
        string schemaKey,
        string schemaVersion,
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        string codecFailureCode) : CanonicalPayloadWriteSourceIntent
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteSourceIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitRejected(
                schemaKey,
                schemaVersion,
                scope,
                location,
                instructionDigest,
                demandDigest,
                codecFailureCode);
    }
}

internal interface ICanonicalPayloadWriteSourceIntentVisitor<TResult>
{
    TResult VisitCreated(CanonicalPayloadWriteSource source);
    TResult VisitRejected(
        string schemaKey,
        string schemaVersion,
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        string codecFailureCode);
}

internal interface ICanonicalPayloadWriteSourceVisitor<TResult>
{
    TResult VisitRepositoryTree(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTreePayloadEntry> entries);
    TResult VisitGovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ReadOnlyMemory<byte> body);
    TResult VisitRepositoryTargetResolution(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents);
}

internal sealed class CanonicalPayloadWriteInput
{
    private CanonicalPayloadWriteInput(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        CanonicalPayloadWriteSource source,
        SemanticResourceBudget budget,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems)
    {
        Slot = slot;
        Target = target;
        Source = source;
        Budget = budget;
        InstructionDigest = instructionDigest;
        DemandDigest = demandDigest;
        DemandItems = demandItems;
    }

    internal EvidenceSlotDeclaration Slot { get; }
    internal AcquisitionTarget Target { get; }
    internal CanonicalPayloadWriteSource Source { get; }
    internal SemanticResourceBudget Budget { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }

    internal static CanonicalPayloadWriteInput Create(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        CanonicalPayloadWriteSource source,
        SemanticResourceBudget budget,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems) =>
        new(
            slot ?? throw new ArgumentNullException(nameof(slot)),
            target ?? throw new ArgumentNullException(nameof(target)),
            source ?? throw new ArgumentNullException(nameof(source)),
            budget ?? throw new ArgumentNullException(nameof(budget)),
            instructionDigest ?? throw new ArgumentNullException(nameof(instructionDigest)),
            demandDigest ?? throw new ArgumentNullException(nameof(demandDigest)),
            Snapshot(demandItems, nameof(demandItems)));

    private static IReadOnlyList<RepositoryTargetResolutionDemandItem> Snapshot(
        IEnumerable<RepositoryTargetResolutionDemandItem>? values,
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

internal sealed class CanonicalPayloadWriteProduct
{
    private CanonicalPayloadWriteProduct(CanonicalEvidencePayload payload) => Payload = payload;

    internal CanonicalEvidencePayload Payload { get; }

    internal static CanonicalPayloadWriteProduct Create(CanonicalEvidencePayload payload) =>
        new(payload ?? throw new ArgumentNullException(nameof(payload)));
}

internal abstract class CanonicalPayloadWriteIntent
{
    private CanonicalPayloadWriteIntent()
    {
    }

    internal static CanonicalPayloadWriteIntent Written(CanonicalPayloadWriteProduct product) =>
        new WrittenCase(product ?? throw new ArgumentNullException(nameof(product)));

    internal static CanonicalPayloadWriteIntent Rejected(IEnumerable<AcquisitionFailure> failures) =>
        new RejectedCase(Snapshot(failures));

    internal abstract TResult Accept<TResult>(ICanonicalPayloadWriteIntentVisitor<TResult> visitor);

    private static IReadOnlyList<AcquisitionFailure> Snapshot(IEnumerable<AcquisitionFailure>? failures)
    {
        ArgumentNullException.ThrowIfNull(failures);
        var values = failures.ToArray();
        if (values.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", nameof(failures));
        }

        return Array.AsReadOnly(values);
    }

    private sealed class WrittenCase(CanonicalPayloadWriteProduct product) : CanonicalPayloadWriteIntent
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitWritten(product);
    }

    private sealed class RejectedCase(IReadOnlyList<AcquisitionFailure> failures) : CanonicalPayloadWriteIntent
    {
        internal override TResult Accept<TResult>(ICanonicalPayloadWriteIntentVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitRejected(failures);
    }
}

internal interface ICanonicalPayloadWriteIntentVisitor<TResult>
{
    TResult VisitWritten(CanonicalPayloadWriteProduct product);
    TResult VisitRejected(IReadOnlyList<AcquisitionFailure> failures);
}

internal interface ISemanticResourceMeter<TInput, TValue>
{
    SemanticResourceLocalUsage MeasureLocal(
        TInput input,
        TValue value,
        CancellationToken cancellationToken);
}

internal sealed class CodecQualificationInput
{
    private CodecQualificationInput(
        EvidenceBinding binding,
        SemanticResourceAllowance resourceAllowance,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems)
    {
        Binding = binding;
        ResourceAllowance = resourceAllowance;
        InstructionDigest = instructionDigest;
        DemandDigest = demandDigest;
        DemandItems = demandItems;
    }

    internal EvidenceBinding Binding { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }

    internal static CodecQualificationInput Create(
        EvidenceBinding binding,
        SemanticResourceAllowance resourceAllowance,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems) =>
        new(
            binding ?? throw new ArgumentNullException(nameof(binding)),
            resourceAllowance ?? throw new ArgumentNullException(nameof(resourceAllowance)),
            instructionDigest ?? throw new ArgumentNullException(nameof(instructionDigest)),
            demandDigest ?? throw new ArgumentNullException(nameof(demandDigest)),
            Snapshot(demandItems));

    private static IReadOnlyList<RepositoryTargetResolutionDemandItem> Snapshot(
        IEnumerable<RepositoryTargetResolutionDemandItem>? values)
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

internal abstract class CodecQualificationIntent<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private CodecQualificationIntent()
    {
    }

    internal static CodecQualificationIntent<TModel> Qualified(CodecModelHandle<TModel> model) =>
        new QualifiedCase(model ?? throw new ArgumentNullException(nameof(model)));

    internal static CodecQualificationIntent<TModel> Rejected(IEnumerable<AcquisitionFailure> failures) =>
        new RejectedCase(Snapshot(failures));

    internal abstract TResult Accept<TResult>(ICodecQualificationIntentVisitor<TModel, TResult> visitor);

    private static IReadOnlyList<AcquisitionFailure> Snapshot(IEnumerable<AcquisitionFailure>? failures)
    {
        ArgumentNullException.ThrowIfNull(failures);
        var values = failures.ToArray();
        if (values.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", nameof(failures));
        }

        return Array.AsReadOnly(values);
    }

    private sealed class QualifiedCase(CodecModelHandle<TModel> model) : CodecQualificationIntent<TModel>
    {
        internal override TResult Accept<TResult>(ICodecQualificationIntentVisitor<TModel, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitQualified(model);
    }

    private sealed class RejectedCase(IReadOnlyList<AcquisitionFailure> failures) : CodecQualificationIntent<TModel>
    {
        internal override TResult Accept<TResult>(ICodecQualificationIntentVisitor<TModel, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor))).VisitRejected(failures);
    }
}

internal interface ICodecQualificationIntentVisitor<TModel, TResult>
    where TModel : class, IProtocolSemanticModel
{
    TResult VisitQualified(CodecModelHandle<TModel> model);
    TResult VisitRejected(IReadOnlyList<AcquisitionFailure> failures);
}
