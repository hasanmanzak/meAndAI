using MeAndAI.Protocol.Domain;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class EvidencePublicApiContractTests
{
    private static readonly string[] PredecessorInventory =
    [
        "AcquisitionStatus",
        "ConformanceVerdict",
        "EnforcementDecision",
        "EnforcementPhase",
        "ExactSha256Digest",
        "ExecutionProfile",
        "ProtocolOperation",
        "RuleEvaluationStatus",
        "RuleId",
        "RuleRevision",
        "SnapshotKind",
        "SubjectRole",
        "SurfaceKind",
        "SurfaceSet",
    ];

    private static readonly string[] SliceInventory =
    [
        "AbsentAcquisitionResult",
        "AcquisitionBoundary",
        "AcquisitionFailure",
        "AcquisitionPage",
        "AcquisitionRequest",
        "AcquisitionResult",
        "AcquisitionTarget",
        "CanonicalEvidencePayload",
        "EvidenceBinding",
        "EvidenceConsistencyClass",
        "EvidenceContext",
        "EvidenceLocation",
        "EvidenceRedaction",
        "EvidenceRequirement",
        "EvidenceScope",
        "FailedAcquisitionResult",
        "ObservedAcquisitionResult",
        "ProviderEvidenceLocation",
        "ReleaseAssetEvidenceLocation",
        "RepositoryEvidenceLocation",
        "RequirementAcquisition",
        "RootEvidenceReference",
        "SnapshotEvidenceLocation",
    ];

    [Fact]
    [Trait("Scenario", "TEST-0221")]
    public void DomainExportsEqualTheCumulativeInventory()
    {
        var expected = PredecessorInventory
            .Concat(SliceInventory)
            .Select(name => $"MeAndAI.Protocol.Domain.{name}")
            .Order(StringComparer.Ordinal)
            .ToArray();
        var actual = typeof(RuleId).Assembly
            .GetExportedTypes()
            .Select(type => type.FullName)
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expected, actual);
    }
}
