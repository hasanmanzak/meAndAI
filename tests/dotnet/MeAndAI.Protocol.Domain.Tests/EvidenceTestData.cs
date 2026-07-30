using System.Collections;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Domain.Tests;

internal static class EvidenceTestData
{
    internal const string GitObject40 =
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    internal const string GitObject64 =
        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    internal const string Sha256C =
        "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
    internal const string Sha256D =
        "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";

    internal static readonly DateTimeOffset StartedAtUtc =
        new(2026, 1, 2, 3, 4, 5, TimeSpan.Zero);

    internal static readonly DateTimeOffset CompletedAtUtc =
        StartedAtUtc.AddMinutes(1);

    internal static EvidenceRequirement Requirement(
        string key = "protocol.requirement.repository-tree",
        SurfaceKind? surface = null,
        string schemaKey = "protocol.schema.repository-tree",
        string schemaVersion = "1.0") =>
        EvidenceRequirement.Create(
            key,
            surface ?? SurfaceKind.Repository,
            "protocol.evidence.repository-tree",
            "protocol.completeness.exact",
            schemaKey,
            schemaVersion,
            [EvidenceConsistencyClass.ExactSnapshot]);

    internal static AcquisitionTarget Target(
        SurfaceKind? surface = null,
        SnapshotKind? snapshotKind = null,
        string? subjectIdentity = null,
        string? sourceIdentity = null,
        string? targetIdentity = null)
    {
        var selectedSnapshot = snapshotKind ?? SnapshotKind.ExactCommit;

        return AcquisitionTarget.Create(
            subjectIdentity ?? "example/subject",
            sourceIdentity ?? "example/source",
            surface ?? SurfaceKind.Repository,
            selectedSnapshot,
            targetIdentity ?? TargetIdentity(selectedSnapshot));
    }

    internal static AcquisitionBoundary Boundary(
        SnapshotKind? snapshotKind = null,
        string? boundaryIdentity = null,
        DateTimeOffset? startedAtUtc = null,
        DateTimeOffset? completedAtUtc = null)
    {
        var selectedSnapshot = snapshotKind ?? SnapshotKind.ExactCommit;

        return AcquisitionBoundary.Create(
            selectedSnapshot,
            boundaryIdentity ?? BoundaryIdentity(selectedSnapshot),
            startedAtUtc ?? StartedAtUtc,
            completedAtUtc ?? CompletedAtUtc);
    }

    internal static EvidenceScope Scope(
        SurfaceKind? surface = null,
        SnapshotKind? snapshotKind = null)
    {
        var selectedSnapshot = snapshotKind ?? SnapshotKind.ExactCommit;
        return EvidenceScope.Create(
            Target(surface, selectedSnapshot),
            Boundary(selectedSnapshot));
    }

    internal static AcquisitionRequest Request(
        EvidenceRequirement? requirement = null,
        AcquisitionTarget? target = null) =>
        AcquisitionRequest.Create(
            target ?? Target(),
            "protocol.adapter.git",
            "1.0",
            "protocol.source.git-tree",
            "2026-01-01",
            [requirement ?? Requirement()]);

    internal static CanonicalEvidencePayload Payload(
        string schemaKey = "protocol.schema.repository-tree",
        string schemaVersion = "1.0",
        IEnumerable<byte>? bytes = null) =>
        CanonicalEvidencePayload.Create(
            schemaKey,
            schemaVersion,
            bytes ?? [1, 2, 3]);

    internal static EvidenceBinding Binding(
        EvidenceScope? scope = null,
        CanonicalEvidencePayload? payload = null,
        IEnumerable<string>? requirementKeys = null,
        DateTimeOffset? capturedAtUtc = null) =>
        EvidenceBinding.Create(
            payload ?? Payload(),
            SnapshotEvidenceLocation.Create(scope ?? Scope()),
            requirementKeys ?? [Requirement().Key],
            capturedAtUtc ?? StartedAtUtc);

    internal static RequirementAcquisition RequirementAcquisition(
        EvidenceRequirement? requirement = null,
        EvidenceConsistencyClass? consistencyClass = null,
        EvidenceRedaction? redaction = null,
        IEnumerable<AcquisitionFailure>? failures = null) =>
        MeAndAI.Protocol.Domain.RequirementAcquisition.Create(
            requirement ?? Requirement(),
            consistencyClass ?? EvidenceConsistencyClass.ExactSnapshot,
            redaction ?? EvidenceRedaction.None,
            failures ?? []);

    internal static EvidenceContext Context(
        bool includeBinding = true,
        IEnumerable<AcquisitionPage>? pages = null,
        long sourceObjectCount = 0)
    {
        var requirement = Requirement();
        var target = Target();
        var request = Request(requirement, target);
        var scope = EvidenceScope.Create(target, Boundary());

        return EvidenceContext.Create(
            request,
            scope,
            [RequirementAcquisition(requirement)],
            includeBinding ? [Binding(scope)] : [],
            pages ?? [],
            sourceObjectCount);
    }

    private static string TargetIdentity(SnapshotKind snapshotKind)
    {
        if (snapshotKind.Equals(SnapshotKind.ExactCommit))
        {
            return GitObject40;
        }

        if (snapshotKind.Equals(SnapshotKind.Candidate) ||
            snapshotKind.Equals(SnapshotKind.CapturedEvidence))
        {
            return Sha256C;
        }

        return snapshotKind.Equals(SnapshotKind.ProviderEvent)
            ? "provider-delivery-1"
            : "provider-plan-1";
    }

    private static string BoundaryIdentity(SnapshotKind snapshotKind) =>
        snapshotKind.Equals(SnapshotKind.ExactCommit)
            ? GitObject40
            : snapshotKind.Equals(SnapshotKind.Candidate) ||
              snapshotKind.Equals(SnapshotKind.CapturedEvidence)
                ? Sha256C
                : Sha256D;
}

internal sealed class SingleUseEnumerable<T> : IEnumerable<T>
{
    private readonly IEnumerable<T> _values;
    private int _enumerationCount;

    internal SingleUseEnumerable(IEnumerable<T> values)
    {
        _values = values;
    }

    internal int EnumerationCount => _enumerationCount;

    public IEnumerator<T> GetEnumerator()
    {
        if (Interlocked.Increment(ref _enumerationCount) != 1)
        {
            throw new InvalidOperationException(
                "The enumerable was consumed more than once.");
        }

        return _values.GetEnumerator();
    }

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
