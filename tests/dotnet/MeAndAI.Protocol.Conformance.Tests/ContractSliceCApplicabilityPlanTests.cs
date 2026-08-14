using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCApplicabilityPlanTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0004";
    private const string ProfileName =
        "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string TargetIdentity =
        "0123456789abcdef0123456789abcdef01234567";

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Plans_exact_static_applicability_instructions()
    {
        var fixture = ContractSliceCActivationTests.CreateFixture();
        var completeKernel = ActivateComplete(fixture);
        var profile = completeKernel.ResolveNamedProfile(ProfileName);
        var repositoryTarget = Target("repo", SurfaceKind.Repository);
        var providerTarget = Target("github", SurfaceKind.Provider);

        ApplicabilityPlan? completePlan = completeKernel.PlanApplicability(
            profile,
            [providerTarget, repositoryTarget]);
        if (completePlan is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal(CatalogAuthorityKind.CompleteProtocolSnapshot, completePlan.AuthorityKind);
        Assert.Same(profile.Axes, completePlan.Profile);
        Assert.Equal(["RULE-0003", "RULE-0004", "RULE-0005"],
            completePlan.RuleIds.Select(ruleId => ruleId.Value));
        Assert.Equal([repositoryTarget, providerTarget], completePlan.Targets);
        Assert.Empty(completePlan.Slots);
        Assert.Empty(completePlan.Instructions);
        Assert.NotNull(completePlan.EvidenceSession);

        var sliceFixture = ContractSliceCActivationTests.CreateSliceFixture();
        var sliceKernel = CatalogSliceKernel.Activate(
            sliceFixture.Manifest,
            sliceFixture.Export,
            new ContractSliceCQualificationProof(
                sliceFixture.Manifest,
                sliceFixture.Export));
        var sliceProfile = ExecutionProfile.Create(
            SubjectRole.Consumer,
            ProtocolOperation.Conformance,
            SnapshotKind.ExactCommit,
            SurfaceSet.Create([SurfaceKind.Repository]),
            EnforcementPhase.Audit);
        var slicePlan = sliceKernel.PlanApplicability(
            sliceProfile,
            [repositoryTarget]);

        Assert.Equal(CatalogAuthorityKind.QualificationSlice, slicePlan.AuthorityKind);
        Assert.Same(sliceProfile, slicePlan.Profile);
        Assert.Equal(
            ["RULE-0001", "RULE-0002", "RULE-0003", "RULE-0004", "RULE-0005"],
            slicePlan.RuleIds.Select(ruleId => ruleId.Value));
        Assert.Equal([repositoryTarget], slicePlan.Targets);
        Assert.Empty(slicePlan.Slots);
        Assert.Empty(slicePlan.Instructions);
        Assert.NotSame(completePlan.EvidenceSession, slicePlan.EvidenceSession);

        AssertStaticInstruction(
            fixture.Manifest.ManifestDigest,
            fixture.Export.Catalog.Rules[0].EvaluationSlots.Single(),
            repositoryTarget);
        AssertInvalid(() => completeKernel.PlanApplicability(
            profile,
            [repositoryTarget]));
        AssertInvalid(() => completeKernel.PlanApplicability(
            profile,
            [repositoryTarget, providerTarget, providerTarget]));
        AssertInvalid(() => completeKernel.PlanApplicability(
            profile,
            [repositoryTarget, AcquisitionTarget.Create(
                "other",
                "github",
                SurfaceKind.Provider,
                SnapshotKind.ExactCommit,
                TargetIdentity)]));
        AssertInvalid(() => completeKernel.PlanApplicability(
            ActivateComplete(fixture).ResolveNamedProfile(ProfileName),
            [repositoryTarget, providerTarget]));
        AssertInvalid(() => sliceKernel.PlanApplicability(
            ExecutionProfile.Create(
                SubjectRole.Consumer,
                ProtocolOperation.Conformance,
                SnapshotKind.ProviderEvent,
                SurfaceSet.Create([SurfaceKind.Repository]),
                EnforcementPhase.Audit),
            [repositoryTarget]));
    }

    private static ConformanceKernel ActivateComplete(
        ContractSliceCActivationTests.CFixture fixture) =>
        ConformanceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            new ContractSliceCActivationProof(fixture.Manifest, fixture.Export),
            predecessor: null);

    private static AcquisitionTarget Target(
        string sourceIdentity,
        SurfaceKind surface) =>
        AcquisitionTarget.Create(
            "repo",
            sourceIdentity,
            surface,
            SnapshotKind.ExactCommit,
            TargetIdentity);

    private static void AssertStaticInstruction(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target)
    {
        var instruction = AcquisitionInstruction.CreateApplicability(
            manifestDigest,
            slot,
            target);
        var demandFrame = DemandFrame();
        var demandDigest = Digest(demandFrame);
        var instructionFrame = InstructionFrame(
            manifestDigest,
            slot,
            target,
            demandDigest);

        Assert.Same(slot, instruction.Slot);
        Assert.Same(target, instruction.Target);
        Assert.Equal(0, instruction.RoundOrdinal);
        Assert.Empty(instruction.DemandItems);
        Assert.Equal(demandDigest, instruction.DemandDigest);
        Assert.Equal(Digest(instructionFrame), instruction.InstructionDigest);
    }

    private static byte[] DemandFrame()
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-demand/1\n"));
        stream.WriteByte(0);
        WriteUInt32(stream, 0);
        return stream.ToArray();
    }

    private static byte[] InstructionFrame(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        ExactSha256Digest demandDigest)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-instruction/1\n"));
        stream.Write(Convert.FromHexString(manifestDigest.Value));
        stream.WriteByte(0);
        WriteUInt32(stream, 0);
        WriteText(stream, slot.SlotKey);
        WriteText(stream, target.SubjectIdentity);
        WriteText(stream, target.SourceIdentity);
        WriteText(stream, target.Surface.Value);
        WriteText(stream, target.SnapshotKind.Value);
        WriteText(stream, target.TargetIdentity);
        stream.Write(Convert.FromHexString(demandDigest.Value));
        return stream.ToArray();
    }

    private static void WriteText(Stream stream, string value)
    {
        var bytes = new UTF8Encoding(false, true).GetBytes(value);
        WriteUInt32(stream, checked((uint)bytes.Length));
        stream.Write(bytes);
    }

    private static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> bytes = stackalloc byte[sizeof(uint)];
        BinaryPrimitives.WriteUInt32BigEndian(bytes, value);
        stream.Write(bytes);
    }

    private static ExactSha256Digest Digest(byte[] frame) =>
        ExactSha256Digest.FromHashBytes(SHA256.HashData(frame));

    private static void AssertInvalid(Action action)
    {
        var exception = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, exception.Code);
    }
}
