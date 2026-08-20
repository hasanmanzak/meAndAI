using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicySurfaceTests
{
    private const BindingFlags DeclaredPublic =
        BindingFlags.Public |
        BindingFlags.Instance |
        BindingFlags.Static |
        BindingFlags.DeclaredOnly;

    private static readonly string[] AbstractionsTypes =
    [
        "BaselineRuleWaiverPolicy",
        "BaselineWaiverPolicySnapshot",
        "ExtensionApplicabilityInput",
        "ExtensionCatalogSnapshot",
        "ExtensionEvaluationInput",
        "ExtensionEvaluationIntent",
        "ExtensionEvaluatorKindDeclaration",
        "ExtensionFindingIntent",
        "ExtensionParameter",
        "ExtensionParameterDeclaration",
        "ExtensionPolicyPackExport",
        "ExtensionRuleDeclaration",
        "HistoricalDebtEntry",
        "HistoricalDebtSnapshot",
        "IExtensionEvaluator",
        "IPredecessorTrustVerifier",
        "IProtectedDispositionAuthorityVerifier",
        "IProtectedExtensionActivationVerifier",
        "IProtectedPolicyPackVerifier",
        "PolicyRuleIdentity",
        "PredecessorTrustBinding",
        "PredecessorTrustPayload",
        "ProposedExtensionChange",
        "ProposedExtensionTransition",
        "ProtectedAuthorityEnvelope",
        "ProtectedDispositionAuthority",
        "ProtectedDispositionAuthorityPayload",
        "ProtectedExtensionActivationPayload",
        "ProtectedFindingIdentity",
        "ProtectedOutcomeIdentity",
        "ProtectedOutcomeKind",
        "ProtectedPolicyArtifactBinding",
        "ProtectedPolicyPackBinding",
        "ReviewedOutcomeDifference",
        "RuntimeQualificationBinding",
        "StableFindingKey",
        "WaiverDeclaration",
        "WaiverScope",
        "WaiverSnapshot",
        "WaiverTargetSelector",
    ];

    private static readonly string[] ConformanceTypes =
    [
        "ActivatedExtensionPolicy",
        "CandidateIndependentQualification",
        "CandidateIndependentQualificationInput",
        "ExtensionEvaluation",
        "ExtensionEvaluationFailure",
        "ExtensionFinding",
        "FindingDispositionResult",
        "ProtectedFinding",
        "ProtectedPolicyEvaluation",
        "ProtectedPolicyIntegrityCode",
        "ProtectedPolicyIntegrityException",
        "SelfConsumptionQualification",
    ];

    internal static readonly string[] PredecessorDomainTypes =
    [
        "MeAndAI.Protocol.Domain.AbsentAcquisitionResult",
        "MeAndAI.Protocol.Domain.AcquisitionBoundary",
        "MeAndAI.Protocol.Domain.AcquisitionFailure",
        "MeAndAI.Protocol.Domain.AcquisitionPage",
        "MeAndAI.Protocol.Domain.AcquisitionRequest",
        "MeAndAI.Protocol.Domain.AcquisitionResult",
        "MeAndAI.Protocol.Domain.AcquisitionStatus",
        "MeAndAI.Protocol.Domain.AcquisitionTarget",
        "MeAndAI.Protocol.Domain.CanonicalEvidencePayload",
        "MeAndAI.Protocol.Domain.ConformanceVerdict",
        "MeAndAI.Protocol.Domain.EnforcementDecision",
        "MeAndAI.Protocol.Domain.EnforcementPhase",
        "MeAndAI.Protocol.Domain.EvidenceBinding",
        "MeAndAI.Protocol.Domain.EvidenceConsistencyClass",
        "MeAndAI.Protocol.Domain.EvidenceContext",
        "MeAndAI.Protocol.Domain.EvidenceLocation",
        "MeAndAI.Protocol.Domain.EvidenceRedaction",
        "MeAndAI.Protocol.Domain.EvidenceRequirement",
        "MeAndAI.Protocol.Domain.EvidenceScope",
        "MeAndAI.Protocol.Domain.ExactSha256Digest",
        "MeAndAI.Protocol.Domain.ExecutionProfile",
        "MeAndAI.Protocol.Domain.FailedAcquisitionResult",
        "MeAndAI.Protocol.Domain.ObservedAcquisitionResult",
        "MeAndAI.Protocol.Domain.ProtocolOperation",
        "MeAndAI.Protocol.Domain.ProviderEvidenceLocation",
        "MeAndAI.Protocol.Domain.ReleaseAssetEvidenceLocation",
        "MeAndAI.Protocol.Domain.RepositoryEvidenceLocation",
        "MeAndAI.Protocol.Domain.RequirementAcquisition",
        "MeAndAI.Protocol.Domain.RootEvidenceReference",
        "MeAndAI.Protocol.Domain.RuleEvaluationStatus",
        "MeAndAI.Protocol.Domain.RuleId",
        "MeAndAI.Protocol.Domain.RuleRevision",
        "MeAndAI.Protocol.Domain.SnapshotEvidenceLocation",
        "MeAndAI.Protocol.Domain.SnapshotKind",
        "MeAndAI.Protocol.Domain.SubjectRole",
        "MeAndAI.Protocol.Domain.SurfaceKind",
        "MeAndAI.Protocol.Domain.SurfaceSet",
    ];

    internal static readonly string[] PredecessorAbstractionsTypes =
    [
        "MeAndAI.Protocol.Conformance.Abstractions.AcquisitionDemandProjectorDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.ActivationProofContractDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.AdmissionProofContractDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.AdmissionProofKind",
        "MeAndAI.Protocol.Conformance.Abstractions.ApplicabilityIntent",
        "MeAndAI.Protocol.Conformance.Abstractions.ApplicabilityIntentKind",
        "MeAndAI.Protocol.Conformance.Abstractions.ArtifactFileBinding",
        "MeAndAI.Protocol.Conformance.Abstractions.CacheRetentionPolicy",
        "MeAndAI.Protocol.Conformance.Abstractions.CapabilityContractIdentity",
        "MeAndAI.Protocol.Conformance.Abstractions.CatalogAuthorityKind",
        "MeAndAI.Protocol.Conformance.Abstractions.CatalogIntegrityCode",
        "MeAndAI.Protocol.Conformance.Abstractions.CatalogPredecessorBinding",
        "MeAndAI.Protocol.Conformance.Abstractions.CatalogPredecessorKind",
        "MeAndAI.Protocol.Conformance.Abstractions.CatalogSliceDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.CatalogVersion",
        "MeAndAI.Protocol.Conformance.Abstractions.CompleteCatalogDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.CompletePolicyPackExport",
        "MeAndAI.Protocol.Conformance.Abstractions.ComponentArtifactBinding",
        "MeAndAI.Protocol.Conformance.Abstractions.ComponentInputDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.ComponentTypeIdentity",
        "MeAndAI.Protocol.Conformance.Abstractions.ContextIndexDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.EvaluationFailureCode",
        "MeAndAI.Protocol.Conformance.Abstractions.EvaluationFailureIntent",
        "MeAndAI.Protocol.Conformance.Abstractions.EvaluationIntent",
        "MeAndAI.Protocol.Conformance.Abstractions.EvidenceSlotDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.ExpectedSelectorDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.FinalizedPolicyManifest",
        "MeAndAI.Protocol.Conformance.Abstractions.FindingCode",
        "MeAndAI.Protocol.Conformance.Abstractions.FindingDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.FindingIntent",
        "MeAndAI.Protocol.Conformance.Abstractions.FindingSeverity",
        "MeAndAI.Protocol.Conformance.Abstractions.GovernedReferenceKind",
        "MeAndAI.Protocol.Conformance.Abstractions.GovernedReferenceResolution",
        "MeAndAI.Protocol.Conformance.Abstractions.GovernedReferenceSyntax",
        "MeAndAI.Protocol.Conformance.Abstractions.GovernedReferenceView",
        "MeAndAI.Protocol.Conformance.Abstractions.IAdmissionProofCandidate",
        "MeAndAI.Protocol.Conformance.Abstractions.IEvidenceCapability",
        "MeAndAI.Protocol.Conformance.Abstractions.IFailedAttemptProof",
        "MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex",
        "MeAndAI.Protocol.Conformance.Abstractions.IndexInvocationScope",
        "MeAndAI.Protocol.Conformance.Abstractions.INoInputRoutingProof",
        "MeAndAI.Protocol.Conformance.Abstractions.IObservedQualificationProof",
        "MeAndAI.Protocol.Conformance.Abstractions.IPolicyActivationProof",
        "MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex",
        "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex",
        "MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree",
        "MeAndAI.Protocol.Conformance.Abstractions.IRuleEvaluator",
        "MeAndAI.Protocol.Conformance.Abstractions.ModelContractIdentity",
        "MeAndAI.Protocol.Conformance.Abstractions.NamedProfileDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.NormativeFragmentDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.PayloadSchemaDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport",
        "MeAndAI.Protocol.Conformance.Abstractions.ProtocolRecordMemberView",
        "MeAndAI.Protocol.Conformance.Abstractions.ProtocolRecordView",
        "MeAndAI.Protocol.Conformance.Abstractions.QualifiedEvidenceHandle",
        "MeAndAI.Protocol.Conformance.Abstractions.QualifiedEvidenceReferenceKind",
        "MeAndAI.Protocol.Conformance.Abstractions.ReleaseSchemaRegistry",
        "MeAndAI.Protocol.Conformance.Abstractions.RemediationKey",
        "MeAndAI.Protocol.Conformance.Abstractions.RepositoryEntryKind",
        "MeAndAI.Protocol.Conformance.Abstractions.RepositoryEntryView",
        "MeAndAI.Protocol.Conformance.Abstractions.RepositoryTargetResolutionDemandItem",
        "MeAndAI.Protocol.Conformance.Abstractions.RepositoryTargetResolutionView",
        "MeAndAI.Protocol.Conformance.Abstractions.ReviewedAuthorityPermalink",
        "MeAndAI.Protocol.Conformance.Abstractions.RuleApplicabilityInput",
        "MeAndAI.Protocol.Conformance.Abstractions.RuleDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.RuleEvaluationInput",
        "MeAndAI.Protocol.Conformance.Abstractions.RuleTransitionDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.RuleTransitionKind",
        "MeAndAI.Protocol.Conformance.Abstractions.SemanticModelParserDeclaration",
        "MeAndAI.Protocol.Conformance.Abstractions.SemanticResourceBudget",
        "MeAndAI.Protocol.Conformance.Abstractions.SessionCacheBudget",
        "MeAndAI.Protocol.Conformance.Abstractions.TestScenarioId",
    ];

    internal static readonly string[] PredecessorConformanceTypes =
    [
        "MeAndAI.Protocol.Conformance.AcquisitionInstruction",
        "MeAndAI.Protocol.Conformance.AcquisitionProofSet",
        "MeAndAI.Protocol.Conformance.ApplicabilityClosure",
        "MeAndAI.Protocol.Conformance.ApplicabilityPlan",
        "MeAndAI.Protocol.Conformance.CatalogIntegrityException",
        "MeAndAI.Protocol.Conformance.CatalogSliceEvaluation",
        "MeAndAI.Protocol.Conformance.CatalogSliceKernel",
        "MeAndAI.Protocol.Conformance.CompleteCatalogEvaluation",
        "MeAndAI.Protocol.Conformance.CompleteCatalogSnapshot",
        "MeAndAI.Protocol.Conformance.ConformanceKernel",
        "MeAndAI.Protocol.Conformance.EvaluationAdvanceResult",
        "MeAndAI.Protocol.Conformance.EvaluationClosure",
        "MeAndAI.Protocol.Conformance.EvaluationPlan",
        "MeAndAI.Protocol.Conformance.NamedExecutionProfile",
        "MeAndAI.Protocol.Conformance.QualifiedEvidenceDerivation",
        "MeAndAI.Protocol.Conformance.QualifiedEvidenceReference",
        "MeAndAI.Protocol.Conformance.QualifiedEvidenceSelector",
        "MeAndAI.Protocol.Conformance.RuleEvaluation",
        "MeAndAI.Protocol.Conformance.RuleEvaluationFailure",
        "MeAndAI.Protocol.Conformance.RuleFinding",
        "MeAndAI.Protocol.Conformance.SealedAcquisitionAttempt",
        "MeAndAI.Protocol.Conformance.SealedAcquisitionOutcome",
        "MeAndAI.Protocol.Conformance.SealedEvaluationContext",
    ];

    internal static readonly string[] PredecessorPolicyTypes =
    [
        "MeAndAI.Protocol.Policy.InitialRuleQualificationPolicy",
    ];

    [Fact]
    public void Exposes_exact_extension_waiver_debt_and_self_consumption_surface()
    {
        AssertExactStageInventories();
        Assert.Equal(
            ["ExtensionId", "ExtensionTransitionKind", "FindingDisposition"],
            NewTypes(typeof(RuleId).Assembly, "MeAndAI.Protocol.Domain", [
                "ExtensionId", "ExtensionTransitionKind", "FindingDisposition"]));
        Assert.Equal(
            AbstractionsTypes,
            NewTypes(typeof(ExtensionRuleDeclaration).Assembly,
                "MeAndAI.Protocol.Conformance.Abstractions", AbstractionsTypes));
        Assert.Equal(
            ConformanceTypes,
            NewTypes(typeof(ProtectedPolicyEvaluation).Assembly,
                "MeAndAI.Protocol.Conformance", ConformanceTypes));
        Assert.Equal(40, typeof(RuleId).Assembly.GetExportedTypes().Length);
        Assert.Equal(112, typeof(ExtensionRuleDeclaration).Assembly.GetExportedTypes().Length);
        Assert.Equal(35, typeof(ProtectedPolicyEvaluation).Assembly.GetExportedTypes().Length);
        Assert.Single(typeof(InitialRuleQualificationPolicy).Assembly.GetExportedTypes());
        Assert.Equal(
            148,
            typeof(ExtensionRuleDeclaration).Assembly.GetExportedTypes().Length +
            typeof(ProtectedPolicyEvaluation).Assembly.GetExportedTypes().Length +
            typeof(InitialRuleQualificationPolicy).Assembly.GetExportedTypes().Length);

        AssertClosedValues();
        AssertCanonicalDeclarationAndSnapshots();
        AssertCanonicalWaiverDebtAndPredecessor();
        AssertAuthorityAndQualificationFrames();
        AssertBoundaryRejections();
        AssertAggregateParameterByteBoundary();
        AssertTransitionDigestPresence();
        AssertSnapshotFrameBoundaries();
        AssertCanonicalArtifactInputOrderRejection();
        AssertNoUnexpectedPublicConstruction();
        Assert.Equal(
            "ac0247c4af7b1654eb3d28600ec58224642adeb59b554be153698ebd89559767",
            PublicSignatureDigest());
    }

    private static void AssertClosedValues()
    {
        Assert.Equal("ext:repo:test", ExtensionId.Parse("ext:repo:test").Value);
        Assert.False(ExtensionId.TryParse("ext:test", out _));
        Assert.False(ExtensionId.TryParse("ext:Repo:test", out _));
        Assert.Equal(FindingDisposition.Waived, FindingDisposition.Parse("waived"));
        Assert.False(FindingDisposition.TryParse("Waived", out _));
        Assert.Equal(ExtensionTransitionKind.Revised, ExtensionTransitionKind.Parse("revised"));
        Assert.Equal(ProtectedOutcomeKind.Enforcement, ProtectedOutcomeKind.Parse("enforcement"));
        Assert.Equal(
            ProtectedPolicyIntegrityCode.ResourceLimitExceeded,
            ProtectedPolicyIntegrityCode.Parse("protocol.policy.resource-limit-exceeded"));
    }

    private static void AssertBoundaryRejections()
    {
        foreach (var key in new[] { ".key", "key.", "-key", "key-" })
        {
            Assert.Throws<ArgumentException>(() => ExtensionParameter.Create(key, string.Empty));
            Assert.Throws<ArgumentException>(() =>
                ExtensionParameterDeclaration.Create(key, "text", 1));
        }

        Assert.Throws<ArgumentException>(() => ExtensionParameter.Create("key", "\uD800"));
        Assert.Throws<FormatException>(() =>
            WaiverTargetSelector.Parse("repository:path/\uD800"));
        foreach (var selector in new[]
                 {
                     "repository:C:/absolute",
                     "repository:c:/absolute",
                     "repository:path/\u0001control",
                 })
        {
            Assert.Throws<FormatException>(() => WaiverTargetSelector.Parse(selector));
        }

        AssertFixedUtf8Boundary<ArgumentOutOfRangeException>(
            4096,
            value => ExtensionParameter.Create("key", value));
        AssertFixedUtf8Boundary<FormatException>(
            4096,
            value => WaiverTargetSelector.Parse($"repository:{value}"));

        var exactBytes = ProtectedPolicyFrame.ExactBytes(
            SingleUse(Enumerable.Repeat((byte)0x5a, 32).ToArray()),
            32,
            "bytes");
        Assert.Equal(32, exactBytes.Length);
        var firstByteOver = Assert.Throws<ArgumentOutOfRangeException>(() =>
            ProtectedPolicyFrame.ExactBytes(
                Enumerable.Repeat((byte)0x5a, 33),
                32,
                "bytes"));
        Assert.Equal("bytes", firstByteOver.ParamName);

        var signatureOver = Assert.Throws<ArgumentOutOfRangeException>(() =>
            ProtectedAuthorityEnvelope.Create(
                "protocol.authority.test",
                "ed25519",
                "protocol.extension-activation-proof",
                "1",
                RepeatDigest("11"),
                RepeatDigest("22"),
                1,
                Enumerable.Repeat((byte)0x5a, 65)));
        Assert.Equal("signature", signatureOver.ParamName);

        Assert.Throws<ArgumentNullException>(() =>
            new ProtectedPolicyIntegrityException(null!));
        var code = ProtectedPolicyIntegrityCode.PolicyPackBindingInvalid;
        var integrity = new ProtectedPolicyIntegrityException(code);
        Assert.Same(code, integrity.Code);
        Assert.Equal("protocol.policy.policy-pack-binding-invalid", integrity.Message);

        var unowned = new UnownedVerifier();
        var publicKeyOver = Assert.Throws<ArgumentOutOfRangeException>(() =>
            ExtensionPolicyPackExport.Create(
                "protocol.policy.extension-protected",
                "1",
                RepeatDigest("11"),
                "protocol.authority.unprovisioned.extension-policy.v1",
                "ed25519",
                Enumerable.Repeat((byte)1, 33),
                unowned,
                unowned,
                unowned,
                unowned,
                []));
        Assert.Equal("authorityPublicKeyBytes", publicKeyOver.ParamName);
        Assert.Throws<ArgumentException>(() => ExtensionPolicyPackExport.Create(
            "protocol.policy.extension-protected",
            "1",
            RepeatDigest("11"),
            "protocol.authority.unprovisioned.extension-policy.v1",
            "ed25519",
            Enumerable.Repeat((byte)1, 32),
            unowned,
            unowned,
            unowned,
            unowned,
            []));
    }

    private static void AssertFixedUtf8Boundary<TException>(
        int maximumBytes,
        Func<string, object> factory)
        where TException : Exception
    {
        var exact = new string('\u00e9', maximumBytes / 2);
        Assert.Equal(maximumBytes, Encoding.UTF8.GetByteCount(exact));
        Assert.NotNull(factory(exact));

        var firstOver = exact + "a";
        Assert.Equal(maximumBytes + 1, Encoding.UTF8.GetByteCount(firstOver));
        Assert.IsType<TException>(Record.Exception(() => factory(firstOver)));
    }

    private static void AssertCanonicalDeclarationAndSnapshots()
    {
        var definitionDigest = Digest("1E9E438CC697900F6CFF8448BEB15F091FD91E6BF9D9EC31560BCBBC15A2C802");
        var declaration = CreateDeclaration(
            SingleUse(
                ExtensionParameter.Create("kind", "file"),
                ExtensionParameter.Create("path", "AGENTS.md")),
            definitionDigest);
        Assert.Equal(definitionDigest, declaration.DefinitionDigest);
        Assert.Throws<ArgumentException>(() => CreateDeclaration(
            [ExtensionParameter.Create("path", "AGENTS.md"), ExtensionParameter.Create("kind", "file")],
            RepeatDigest("11")));
        Assert.Throws<ArgumentException>(() => CreateDeclaration(
            [ExtensionParameter.Create("kind", "file"), ExtensionParameter.Create("kind", "directory")],
            RepeatDigest("11")));
        Assert.Throws<ArgumentOutOfRangeException>(() => CreateDeclaration(
            Enumerable.Range(0, 65).Select(index =>
                ExtensionParameter.Create($"p{index:D2}", string.Empty)),
            RepeatDigest("11")));

        var emptyExtensionSnapshot = ExtensionCatalogSnapshot.Create(
            "repo", RepeatDigest("11"),
            Digest("C1E573C918A7FE198E6168EA0773D0814F83800EC75D2BA2FDB31071D8132E40"), []);
        Assert.Empty(emptyExtensionSnapshot.Extensions);

        var baselineWaiver = BaselineWaiverPolicySnapshot.Create(
            RepeatDigest("11"),
            Digest("FD3E642248F405BB948395B1C543275CD554810A2A479F7B65F216E2C881834A"), []);
        Assert.Empty(baselineWaiver.Rules);
        Assert.Empty(WaiverSnapshot.Create(
            Digest("B76E40F37E33A0392341301BB0D0C56FE3B0E2C911B48CD6427B5BF79C8FD02A"), []).Waivers);
        Assert.Empty(HistoricalDebtSnapshot.Create(
            Digest("20B8BFD02EBD0621C0E533851D943D8C98F552ACC014ECF6BE663123E3283A46"), []).Entries);

        var stable = StableFindingKey.Create(
            PolicyRuleIdentity.Baseline(RuleId.Parse("RULE-0001"), RuleRevision.Create(1)),
            FindingCode.Parse("protocol.test.finding"),
            RepeatDigest("11"), RepeatDigest("22"), RepeatDigest("33"));
        Assert.Equal(
            "a298841ec8ccfeb02c4192f8684b2432f99f2e9e69a8dc3000eaa8e5505e3791",
            stable.Value.Value);
    }

    private static void AssertAggregateParameterByteBoundary()
    {
        const int declarationCount = 32;
        const int parameterCount = 64;
        const long maximumAggregateBytes = 8_388_608;
        var exactValue = new string('x', 4093);
        var exactParameters = Enumerable.Range(0, parameterCount)
            .Select(index => ExtensionParameter.Create($"p{index:D2}", exactValue))
            .ToArray();
        var exactDeclarations = Enumerable.Range(0, declarationCount)
            .Select(index => CreateBoundedDeclaration($"e{index:D2}", exactParameters))
            .ToArray();

        Assert.Equal(maximumAggregateBytes, AggregateParameterBytes(exactDeclarations));
        var policyBlobDigest = RepeatDigest("11");
        var exactSnapshotDigest = ExtensionCatalogSnapshot.ComputeDigest(
            "repo", policyBlobDigest, exactDeclarations);
        var exactSnapshot = ExtensionCatalogSnapshot.Create(
            "repo", policyBlobDigest, exactSnapshotDigest, exactDeclarations);
        Assert.Equal(declarationCount, exactSnapshot.Extensions.Count);

        var firstOverParameters = exactParameters.ToArray();
        firstOverParameters[^1] = ExtensionParameter.Create("p63", exactValue + "x");
        var firstOverDeclarations = exactDeclarations.ToArray();
        firstOverDeclarations[^1] = CreateBoundedDeclaration("e31", firstOverParameters);
        Assert.Equal(
            maximumAggregateBytes + 1,
            AggregateParameterBytes(firstOverDeclarations));
        var exception = Assert.Throws<ArgumentException>(() =>
            ExtensionCatalogSnapshot.Create(
                "repo", policyBlobDigest, RepeatDigest("22"), firstOverDeclarations));
        Assert.Equal("extensions", exception.ParamName);
    }

    private static void AssertTransitionDigestPresence()
    {
        var id = ExtensionId.Parse("ext:repo:test");
        var zero = RepeatDigest("00");
        var nonzero = RepeatDigest("11");

        var added = Assert.Throws<ArgumentException>(() =>
            ProposedExtensionChange.Create(
                id, ExtensionTransitionKind.Added, null, zero));
        Assert.Equal("proposedDefinitionDigest", added.ParamName);

        var removed = Assert.Throws<ArgumentException>(() =>
            ProposedExtensionChange.Create(
                id, ExtensionTransitionKind.Removed, zero, null));
        Assert.Equal("previousDefinitionDigest", removed.ParamName);

        var revisedFromZero = Assert.Throws<ArgumentException>(() =>
            ProposedExtensionChange.Create(
                id, ExtensionTransitionKind.Revised, zero, nonzero));
        Assert.Equal("previousDefinitionDigest", revisedFromZero.ParamName);

        var revisedToZero = Assert.Throws<ArgumentException>(() =>
            ProposedExtensionChange.Create(
                id, ExtensionTransitionKind.Revised, nonzero, zero));
        Assert.Equal("proposedDefinitionDigest", revisedToZero.ParamName);

        var goldenAdded = ProposedExtensionChange.Create(
            id, ExtensionTransitionKind.Added, null, RepeatDigest("44"));
        Assert.Equal(
            "a589422aa3010e335a3730f280f19226dfb72e866d97b0adac99aa084d689d0c",
            ProposedExtensionTransition.ComputeDigest(
                RepeatDigest("11"),
                RepeatDigest("22"),
                new string('0', 40),
                RepeatDigest("33"),
                [goldenAdded]).Value);
    }

    private static void AssertSnapshotFrameBoundaries()
    {
        foreach (var separator in new[]
                 {
                     "protocol.waiver-snapshot/1\n",
                     "protocol.historical-debt-snapshot/1\n",
                 })
        {
            var expectedLength = checked(
                (long)Encoding.ASCII.GetByteCount(separator) +
                sizeof(uint) +
                (32L * WaiverSnapshot.MaximumSnapshotCount));
            Assert.Equal(
                expectedLength,
                WaiverSnapshot.ValidateSnapshotFrameLength(
                    separator,
                    WaiverSnapshot.MaximumSnapshotCount,
                    "count"));
            Assert.True(expectedLength < WaiverSnapshot.MaximumCanonicalFrameBytes);
            var exception = Assert.Throws<ArgumentOutOfRangeException>(() =>
                WaiverSnapshot.ValidateSnapshotFrameLength(
                    separator,
                    WaiverSnapshot.MaximumSnapshotCount + 1,
                    "count"));
            Assert.Equal("count", exception.ParamName);

            var completeFrameStart = WaiverSnapshot.BeginCompleteSnapshotFrame(separator);
            var equalityRowLength =
                WaiverSnapshot.MaximumCanonicalFrameBytes - completeFrameStart - 32;
            Assert.Equal(
                WaiverSnapshot.MaximumCanonicalFrameBytes,
                WaiverSnapshot.AddCompleteSnapshotRow(
                    completeFrameStart,
                    equalityRowLength,
                    "rows"));
            var byteOver = Assert.Throws<ArgumentException>(() =>
                WaiverSnapshot.AddCompleteSnapshotRow(
                    completeFrameStart,
                    equalityRowLength + 1,
                    "rows"));
            Assert.Equal("rows", byteOver.ParamName);
        }
    }

    private static void AssertCanonicalArtifactInputOrderRejection()
    {
        var baselineWaiver = BaselineWaiverPolicySnapshot.Create(
            RepeatDigest("11"),
            Digest("FD3E642248F405BB948395B1C543275CD554810A2A479F7B65F216E2C881834A"),
            []);
        var artifacts = new[]
        {
            CreateArtifact(
                "protocol.artifact.domain",
                "MeAndAI.Protocol.Domain.dll",
                1,
                RepeatDigest("44"),
                []),
            CreateArtifact(
                "protocol.artifact.conformance-abstractions",
                "MeAndAI.Protocol.Conformance.Abstractions.dll",
                2,
                RepeatDigest("55"),
                ["protocol.component.test.abstractions"]),
            CreateArtifact(
                "protocol.artifact.conformance-runtime",
                "MeAndAI.Protocol.Conformance.dll",
                3,
                RepeatDigest("66"),
                ["protocol.component.test.runtime"]),
            CreateArtifact(
                "protocol.artifact.policy",
                "MeAndAI.Protocol.Policy.dll",
                4,
                RepeatDigest("77"),
                ["protocol.component.test.policy"]),
        };
        var goldenBindingDigest = ProtectedPolicyPackBinding.ComputeDigest(
            RepeatDigest("11"),
            RepeatDigest("22"),
            RepeatDigest("33"),
            artifacts);
        Assert.Equal(
            "13822fd15f4931a6592cf0ec9fba2d68cb2d8d59d90d661b29961ca98546e534",
            goldenBindingDigest.Value);
        var bindingDigest = ProtectedPolicyPackBinding.ComputeDigest(
            RepeatDigest("11"),
            RepeatDigest("22"),
            baselineWaiver.SnapshotDigest,
            artifacts);
        var binding = ProtectedPolicyPackBinding.Create(
            RepeatDigest("11"),
            RepeatDigest("22"),
            baselineWaiver,
            artifacts,
            bindingDigest);
        Assert.Equal(artifacts, binding.Artifacts);

        var noncanonical = new[]
        {
            artifacts[1],
            artifacts[0],
            artifacts[2],
            artifacts[3],
        };

        var exception = Assert.Throws<ArgumentException>(() =>
            ProtectedPolicyPackBinding.Create(
                RepeatDigest("11"),
                RepeatDigest("22"),
                baselineWaiver,
                noncanonical,
                RepeatDigest("33")));
        Assert.Equal("artifacts", exception.ParamName);
    }

    private static void AssertAuthorityAndQualificationFrames()
    {
        var activation = ProtectedExtensionActivationPayload.Create(
            RepeatDigest("11"), "repo", RepeatDigest("22"), RepeatDigest("33"),
            RepeatDigest("44"), RepeatDigest("55"), RepeatDigest("66"), RepeatDigest("77"),
            new string('0', 40), 1);
        Assert.Equal(
            "6c0996ce7ad2d0b6193ed30186d3a5a8d2cfcb4e914673ea6c326429c8bd9ff3",
            activation.PayloadDigest.Value);

        var disposition = ProtectedDispositionAuthorityPayload.Create(
            RepeatDigest("11"), RepeatDigest("11"), RepeatDigest("33"),
            RepeatDigest("44"), RepeatDigest("55"), RepeatDigest("66"),
            RepeatDigest("77"), 1, new DateTimeOffset(0, TimeSpan.Zero));
        Assert.Equal(
            "cabd6ec11544becfcb99ebd980b6725414847c31c1e019f2f446c7909753c7ab",
            disposition.PayloadDigest.Value);

        var runtime = RuntimeQualificationBinding.Create(
            "1", new string('0', 40), RepeatDigest("11"), RepeatDigest("22"),
            RepeatDigest("33"), RepeatDigest("44"), RepeatDigest("55"));
        Assert.Equal(
            "e30958b738278eda4107ca6989fe35ed65a3183814e83dd1ec4234c66830dea5",
            runtime.BindingDigest.Value);

        var envelopeBytes = Convert.FromBase64String(
            "cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAI3Byb3RvY29sLmV4dGVuc2lvbi1hY3RpdmF0aW9uLXByb29mAAAAATERERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAAAAAAAAEETz6gphZl04yB9XScsKKG+RLcSMqHhh0bFdC/ssxacOFbLmpgdlE9y8Dfc2wSjz6DALqC7zAh4LlWseEcjqAE");
        var signature = envelopeBytes[^64..];
        var envelope = ProtectedAuthorityEnvelope.Create(
            "protocol.authority.test", "ed25519",
            "protocol.extension-activation-proof", "1",
            RepeatDigest("11"), RepeatDigest("22"), 1, signature);
        Assert.Equal(
            "574d2f7bc3eddb6652197da9a6b548477fa09a7fa9004e1efd5f2db2f95046e6",
            envelope.EnvelopeDigest.Value);
        signature[0] ^= 0xff;
        Assert.NotEqual(signature, envelope.GetSignatureCopy());
        var first = envelope.GetSignatureCopy();
        first[0] ^= 0xff;
        Assert.NotEqual(first, envelope.GetSignatureCopy());
    }

    private static void AssertCanonicalWaiverDebtAndPredecessor()
    {
        var identity = CreateStableIdentity();
        var authority = ReviewedAuthorityPermalink.Create(
            $"https://github.com/owner/repo/commit/{new string('0', 40)}");
        var waiver = WaiverDeclaration.Create(
            identity,
            WaiverTargetSelector.Parse($"evidence:{RepeatDigest("22").Value}"),
            WaiverScope.Parse("finding"),
            "test",
            "owner",
            authority,
            RepeatDigest("44"),
            new DateTimeOffset(0, TimeSpan.Zero),
            new DateTimeOffset(1, TimeSpan.Zero),
            RepeatDigest("55"));
        Assert.Equal(
            "d8a0f34b6820a19ff3584c09efb134472542eeddf4f575bbfe0312f0f04e7be1",
            waiver.DeclarationDigest.Value);
        Assert.Single(WaiverSnapshot.Create(
            SnapshotDigest("protocol.waiver-snapshot/1\n", waiver.DeclarationDigest),
            [waiver]).Waivers);

        var debt = HistoricalDebtEntry.Create(
            identity, "1", "owner", authority, "review", RepeatDigest("22"),
            RepeatDigest("66"), null, new DateTimeOffset(1, TimeSpan.Zero),
            RepeatDigest("44"));
        Assert.Equal(
            "08616f2ca31f056d8421c73b56688c2d415e3551083c5d808a2bb58eb26bbf5d",
            debt.EntryDigest.Value);
        Assert.Single(HistoricalDebtSnapshot.Create(
            SnapshotDigest("protocol.historical-debt-snapshot/1\n", debt.EntryDigest),
            [debt]).Entries);

        var runtime = RuntimeQualificationBinding.Create(
            "1", new string('0', 40), RepeatDigest("11"), RepeatDigest("22"),
            RepeatDigest("33"), RepeatDigest("44"), RepeatDigest("55"));
        var predecessor = PredecessorTrustPayload.Create(
            runtime, RepeatDigest("55"), RepeatDigest("66"), 1,
            "protocol.fixture.protected-policy-overlap", "1", RepeatDigest("77"),
            RepeatDigest("88"), RepeatDigest("99"), RepeatDigest("aa"),
            RepeatDigest("bb"), RepeatDigest("cc"),
            "protocol.fixture.protected-policy", "1", RepeatDigest("dd"),
            RepeatDigest("ee"), RepeatDigest("ff"));
        Assert.Equal(
            "35a596903394e0ad16fdc96addadef9135bbe9e1f7e11beabd9ca9e24ddbc3d9",
            predecessor.PayloadDigest.Value);
    }

    private static ProtectedFindingIdentity CreateStableIdentity()
    {
        var rule = PolicyRuleIdentity.Baseline(
            RuleId.Parse("RULE-0001"), RuleRevision.Create(1));
        var code = FindingCode.Parse("protocol.test.finding");
        var stable = StableFindingKey.Create(
            rule, code, RepeatDigest("11"), RepeatDigest("22"), RepeatDigest("33"));
        return ProtectedFindingIdentity.Create(
            rule, code, RepeatDigest("11"), RepeatDigest("22"), RepeatDigest("33"), stable);
    }

    private static void AssertExactStageInventories()
    {
        AssertExactInventory(
            typeof(RuleId).Assembly,
            PredecessorDomainTypes.Concat(
            [
                "MeAndAI.Protocol.Domain.ExtensionId",
                "MeAndAI.Protocol.Domain.ExtensionTransitionKind",
                "MeAndAI.Protocol.Domain.FindingDisposition",
            ]));
        AssertExactInventory(
            typeof(ExtensionRuleDeclaration).Assembly,
            PredecessorAbstractionsTypes.Concat(AbstractionsTypes.Select(static name =>
                $"MeAndAI.Protocol.Conformance.Abstractions.{name}")));
        AssertExactInventory(
            typeof(ProtectedPolicyEvaluation).Assembly,
            PredecessorConformanceTypes.Concat(ConformanceTypes.Select(static name =>
                $"MeAndAI.Protocol.Conformance.{name}")));
        AssertExactInventory(
            typeof(InitialRuleQualificationPolicy).Assembly,
            PredecessorPolicyTypes);
    }

    private static void AssertExactInventory(
        Assembly assembly,
        IEnumerable<string> expected)
    {
        var expectedRows = expected.Order(StringComparer.Ordinal).ToArray();
        Assert.Equal(expectedRows.Length, expectedRows.Distinct(StringComparer.Ordinal).Count());
        Assert.Equal(
            expectedRows,
            assembly.GetExportedTypes()
                .Select(static type => type.FullName!)
                .Order(StringComparer.Ordinal)
                .ToArray());
    }

    private static void AssertNoUnexpectedPublicConstruction()
    {
        var types = new[]
            {
                typeof(ExtensionId),
                typeof(ExtensionTransitionKind),
                typeof(FindingDisposition),
            }
            .Concat(AbstractionsTypes.Select(name =>
                typeof(ExtensionRuleDeclaration).Assembly.GetType(
                    $"MeAndAI.Protocol.Conformance.Abstractions.{name}", true)!))
            .Concat(ConformanceTypes.Select(name =>
                typeof(ProtectedPolicyEvaluation).Assembly.GetType(
                    $"MeAndAI.Protocol.Conformance.{name}", true)!));
        foreach (var type in types)
        {
            if (!type.IsInterface)
            {
                Assert.Empty(type.GetConstructors(BindingFlags.Public | BindingFlags.Instance));
            }

            Assert.Empty(type.GetFields(DeclaredPublic));
            Assert.Empty(type.GetEvents(DeclaredPublic));
            Assert.All(type.GetProperties(DeclaredPublic), property =>
            {
                Assert.Null(property.SetMethod);
                AssertNoSerializationAttributes(property);
            });
            Assert.DoesNotContain(type.GetMethods(DeclaredPublic), method =>
                method.Name == "Deconstruct" ||
                method.Name.StartsWith("op_", StringComparison.Ordinal));
            AssertNoSerializationAttributes(type);
            foreach (var method in type.GetMethods(DeclaredPublic).Cast<MethodBase>()
                         .Concat(type.GetConstructors(
                             BindingFlags.Public |
                             BindingFlags.Instance |
                             BindingFlags.Static |
                             BindingFlags.DeclaredOnly)))
            {
                AssertNoSerializationAttributes(method);
                if (method is MethodInfo methodInfo)
                {
                    AssertNoSerializationAttributes(methodInfo.ReturnParameter);
                }
                Assert.All(method.GetParameters(), AssertNoSerializationAttributes);
            }
        }
    }

    private static void AssertNoSerializationAttributes(MemberInfo member) =>
        Assert.DoesNotContain(member.CustomAttributes, IsSerializerAttribute);

    private static void AssertNoSerializationAttributes(ParameterInfo parameter) =>
        Assert.DoesNotContain(parameter.CustomAttributes, IsSerializerAttribute);

    private static bool IsSerializerAttribute(CustomAttributeData attribute) =>
        attribute.AttributeType.FullName == "System.SerializableAttribute" ||
        attribute.AttributeType.Namespace is
            "System.Runtime.Serialization" or
            "System.Text.Json.Serialization" or
            "System.Xml.Serialization";

    private static string[] NewTypes(Assembly assembly, string @namespace, IEnumerable<string> expected) =>
        assembly.GetExportedTypes()
            .Where(type => string.Equals(type.Namespace, @namespace, StringComparison.Ordinal))
            .Select(type => type.Name)
            .Where(name => expected.Contains(name, StringComparer.Ordinal))
            .Order(StringComparer.Ordinal)
            .ToArray();

    private static ExactSha256Digest RepeatDigest(string pair) => Digest(string.Concat(Enumerable.Repeat(pair, 32)));
    private static ExactSha256Digest Digest(string value) => ExactSha256Digest.Parse(value.ToLowerInvariant());

    private static ExtensionRuleDeclaration CreateDeclaration(
        IEnumerable<ExtensionParameter> parameters,
        ExactSha256Digest definitionDigest) =>
        ExtensionRuleDeclaration.Create(
            ExtensionId.Parse("ext:repo:required-agents"),
            RuleRevision.Create(1),
            "protocol.extension.repository-path-required",
            "1",
            parameters,
            [SubjectRole.Consumer],
            SurfaceSet.Create([SurfaceKind.Repository]),
            [SnapshotKind.ExactCommit],
            [ProtocolOperation.Conformance],
            definitionDigest);

    private static ExtensionRuleDeclaration CreateBoundedDeclaration(
        string stableName,
        IReadOnlyList<ExtensionParameter> parameters)
    {
        var id = ExtensionId.Parse($"ext:repo:{stableName}");
        var revision = RuleRevision.Create(1);
        const string evaluatorKind = "protocol.extension.repository-path-required";
        const string evaluatorVersion = "1";
        SubjectRole[] roles = [SubjectRole.Consumer];
        var surfaces = SurfaceSet.Create([SurfaceKind.Repository]);
        SnapshotKind[] snapshots = [SnapshotKind.ExactCommit];
        ProtocolOperation[] operations = [ProtocolOperation.Conformance];
        var digest = ExtensionRuleDeclaration.ComputeDefinition(
            id,
            revision,
            evaluatorKind,
            evaluatorVersion,
            parameters,
            roles,
            surfaces,
            snapshots,
            operations);
        return ExtensionRuleDeclaration.Create(
            id,
            revision,
            evaluatorKind,
            evaluatorVersion,
            parameters,
            roles,
            surfaces,
            snapshots,
            operations,
            digest);
    }

    private static long AggregateParameterBytes(
        IEnumerable<ExtensionRuleDeclaration> declarations) =>
        declarations.SelectMany(static declaration => declaration.Parameters)
            .Sum(static parameter => checked(
                (long)Encoding.UTF8.GetByteCount(parameter.Key) +
                Encoding.UTF8.GetByteCount(parameter.Value)));

    private static ProtectedPolicyArtifactBinding CreateArtifact(
        string artifactKey,
        string fileName,
        long fileLength,
        ExactSha256Digest fileDigest,
        IEnumerable<string> componentKeys) =>
        ProtectedPolicyArtifactBinding.Create(
            artifactKey,
            fileName,
            fileLength,
            fileDigest,
            componentKeys);

    private static ExactSha256Digest SnapshotDigest(string separator, ExactSha256Digest row)
    {
        using var stream = new MemoryStream();
        stream.Write(System.Text.Encoding.ASCII.GetBytes(separator));
        Span<byte> count = stackalloc byte[4];
        System.Buffers.Binary.BinaryPrimitives.WriteUInt32BigEndian(count, 1);
        stream.Write(count);
        stream.Write(Convert.FromHexString(row.Value));
        return ExactSha256Digest.FromHashBytes(SHA256.HashData(stream.ToArray()));
    }

    private static string PublicSignatureDigest()
    {
        var nullability = new NullabilityInfoContext();
        var types = new[]
            {
                typeof(RuleId).Assembly,
                typeof(ExtensionRuleDeclaration).Assembly,
                typeof(ProtectedPolicyEvaluation).Assembly,
                typeof(InitialRuleQualificationPolicy).Assembly,
            }
            .SelectMany(static assembly => assembly.GetExportedTypes())
            .OrderBy(type => type.FullName, StringComparer.Ordinal);
        var rows = new List<string>();
        foreach (var type in types)
        {
            rows.Add(SignatureRow(
                "T",
                type.FullName,
                TypeKind(type),
                ((int)type.Attributes).ToString(CultureInfo.InvariantCulture),
                TypeName(type.BaseType),
                SignatureList(type.GetInterfaces().Select(TypeName)),
                GenericParameters(type.GetGenericArguments()),
                CustomAttributes(type.CustomAttributes)));

            foreach (var field in type.GetFields(DeclaredPublic))
            {
                rows.Add(SignatureRow(
                    "F",
                    type.FullName,
                    field.Name,
                    ((int)field.Attributes).ToString(CultureInfo.InvariantCulture),
                    AnnotatedType(field.FieldType, nullability.Create(field)),
                    field.IsLiteral ? ConstantValue(field.GetRawConstantValue()) : "-",
                    CustomAttributes(field.CustomAttributes)));
            }

            foreach (var @event in type.GetEvents(DeclaredPublic))
            {
                rows.Add(SignatureRow(
                    "E",
                    type.FullName,
                    @event.Name,
                    ((int)@event.Attributes).ToString(CultureInfo.InvariantCulture),
                    AnnotatedType(
                        @event.EventHandlerType ?? typeof(void),
                        nullability.Create(@event)),
                    Accessor(@event.AddMethod),
                    Accessor(@event.RemoveMethod),
                    Accessor(@event.RaiseMethod),
                    SignatureList(@event.GetOtherMethods(nonPublic: false).Select(Accessor)),
                    CustomAttributes(@event.CustomAttributes)));
            }

            foreach (var property in type.GetProperties(DeclaredPublic))
            {
                rows.Add(SignatureRow(
                    "P",
                    type.FullName,
                    property.Name,
                    ((int)property.Attributes).ToString(CultureInfo.InvariantCulture),
                    AnnotatedType(property.PropertyType, nullability.Create(property)),
                    Parameters(property.GetIndexParameters(), nullability),
                    Accessor(property.GetMethod),
                    Accessor(property.SetMethod),
                    CustomAttributes(property.CustomAttributes)));
            }

            foreach (var constructor in type.GetConstructors(DeclaredPublic))
            {
                rows.Add(SignatureRow(
                    "C",
                    type.FullName,
                    ((int)constructor.Attributes).ToString(CultureInfo.InvariantCulture),
                    ((int)constructor.CallingConvention).ToString(CultureInfo.InvariantCulture),
                    Parameters(constructor.GetParameters(), nullability),
                    CustomAttributes(constructor.CustomAttributes)));
            }

            foreach (var method in type.GetMethods(DeclaredPublic))
            {
                rows.Add(SignatureRow(
                    "M",
                    type.FullName,
                    method.Name,
                    ((int)method.Attributes).ToString(CultureInfo.InvariantCulture),
                    ((int)method.CallingConvention).ToString(CultureInfo.InvariantCulture),
                    method.IsSpecialName.ToString(CultureInfo.InvariantCulture),
                    AnnotatedType(
                        method.ReturnType,
                        nullability.Create(method.ReturnParameter)),
                    CustomAttributes(method.ReturnParameter.CustomAttributes),
                    GenericParameters(method.GetGenericArguments()),
                    Parameters(method.GetParameters(), nullability),
                    CustomAttributes(method.CustomAttributes)));
            }
        }

        rows.Sort(StringComparer.Ordinal);
        return Convert.ToHexString(SHA256.HashData(
                Encoding.UTF8.GetBytes(string.Join('\n', rows))))
            .ToLowerInvariant();
    }

    private static string TypeKind(Type type) =>
        type.IsInterface ? "interface" :
        type.IsEnum ? "enum" :
        type.IsValueType ? "value" :
        typeof(Delegate).IsAssignableFrom(type) ? "delegate" :
        "class";

    private static string Accessor(MethodInfo? method) => method is null
        ? "-"
        : SignatureRow(
            method.Name,
            ((int)method.Attributes).ToString(CultureInfo.InvariantCulture),
            CustomAttributes(method.CustomAttributes));

    private static string Parameters(
        IEnumerable<ParameterInfo> parameters,
        NullabilityInfoContext nullability) =>
        OrderedSignatureList(parameters.Select(parameter => SignatureRow(
            parameter.Position.ToString(CultureInfo.InvariantCulture),
            parameter.Name,
            ((int)parameter.Attributes).ToString(CultureInfo.InvariantCulture),
            parameter.IsOut ? "out" : parameter.ParameterType.IsByRef ? "ref" : "value",
            AnnotatedType(parameter.ParameterType, nullability.Create(parameter)),
            parameter.HasDefaultValue ? ConstantValue(parameter.RawDefaultValue) : "-",
            CustomAttributes(parameter.CustomAttributes))));

    private static string GenericParameters(IEnumerable<Type> arguments) =>
        OrderedSignatureList(arguments.Where(static argument => argument.IsGenericParameter)
            .Select(argument => SignatureRow(
                argument.GenericParameterPosition.ToString(CultureInfo.InvariantCulture),
                argument.Name,
                ((int)argument.GenericParameterAttributes).ToString(CultureInfo.InvariantCulture),
                SignatureList(argument.GetGenericParameterConstraints().Select(TypeName)),
                CustomAttributes(argument.CustomAttributes))));

    private static string AnnotatedType(Type type, NullabilityInfo nullability)
    {
        if (type.IsByRef)
        {
            return SignatureRow(
                "byref",
                AnnotatedType(type.GetElementType()!, nullability));
        }

        if (type.IsPointer)
        {
            return SignatureRow(
                "pointer",
                AnnotatedType(type.GetElementType()!, nullability.ElementType ?? nullability));
        }

        if (type.IsArray)
        {
            return SignatureRow(
                "array",
                type.GetArrayRank().ToString(CultureInfo.InvariantCulture),
                NullabilityStateName(nullability.ReadState),
                NullabilityStateName(nullability.WriteState),
                AnnotatedType(
                    type.GetElementType()!,
                    nullability.ElementType ?? nullability));
        }

        var arguments = type.IsGenericType
            ? type.GetGenericArguments()
            : Type.EmptyTypes;
        return SignatureRow(
            TypeName(type.IsGenericType ? type.GetGenericTypeDefinition() : type),
            NullabilityStateName(nullability.ReadState),
            NullabilityStateName(nullability.WriteState),
            OrderedSignatureList(arguments.Select((argument, index) =>
                index < nullability.GenericTypeArguments.Length
                    ? AnnotatedType(argument, nullability.GenericTypeArguments[index])
                    : TypeName(argument))));
    }

    private static string NullabilityStateName(NullabilityState state) =>
        ((int)state).ToString(CultureInfo.InvariantCulture);

    private static string CustomAttributes(IEnumerable<CustomAttributeData> attributes) =>
        SignatureList(attributes.Select(attribute => SignatureRow(
            TypeName(attribute.AttributeType),
            OrderedSignatureList(attribute.ConstructorArguments.Select(AttributeArgument)),
            SignatureList(attribute.NamedArguments.Select(named => SignatureRow(
                named.MemberName,
                named.IsField.ToString(CultureInfo.InvariantCulture),
                AttributeArgument(named.TypedValue)))))));

    private static string AttributeArgument(CustomAttributeTypedArgument argument)
    {
        if (argument.Value is IList<CustomAttributeTypedArgument> values)
        {
            return SignatureRow(
                TypeName(argument.ArgumentType),
                OrderedSignatureList(values.Select(AttributeArgument)));
        }

        return SignatureRow(
            TypeName(argument.ArgumentType),
            argument.Value is Type type
                ? TypeName(type)
                : ConstantValue(argument.Value));
    }

    private static string ConstantValue(object? value) => value switch
    {
        null => "null",
        string text => SignatureRow("string", text),
        char character => SignatureRow(
            "char", ((int)character).ToString(CultureInfo.InvariantCulture)),
        Type type => SignatureRow("type", TypeName(type)),
        _ => SignatureRow(
            value.GetType().FullName,
            Convert.ToString(value, CultureInfo.InvariantCulture)),
    };

    private static string SignatureList(IEnumerable<string> values) =>
        SignatureRow(values.Order(StringComparer.Ordinal).ToArray());

    private static string OrderedSignatureList(IEnumerable<string> values) =>
        SignatureRow(values.ToArray());

    private static string SignatureRow(params string?[] values) =>
        string.Concat(values.Select(value =>
        {
            var normalized = value ?? "<null>";
            return string.Concat(
                Encoding.UTF8.GetByteCount(normalized).ToString(CultureInfo.InvariantCulture),
                ":",
                normalized,
                ";");
        }));

    internal static void AssertPredecessorInventory(
        Assembly assembly,
        IReadOnlyList<string> expected)
    {
        Assert.Equal(expected.Count, expected.Distinct(StringComparer.Ordinal).Count());
        var actual = assembly.GetExportedTypes()
            .Select(static type => type.FullName!)
            .Order(StringComparer.Ordinal)
            .ToArray();
        Assert.All(expected, name => Assert.Contains(name, actual));
    }

    private static IEnumerable<T> SingleUse<T>(params T[] values)
    {
        var consumed = false;
        return Iterate();

        IEnumerable<T> Iterate()
        {
            if (consumed)
            {
                throw new InvalidOperationException("The enumerable was consumed more than once.");
            }

            consumed = true;
            foreach (var value in values)
            {
                yield return value;
            }
        }
    }

    private static string TypeName(Type? type)
    {
        if (type is null)
        {
            return "null";
        }
        if (type.IsByRef)
        {
            return $"{TypeName(type.GetElementType())}&";
        }
        if (type.IsPointer)
        {
            return $"{TypeName(type.GetElementType())}*";
        }
        if (type.IsArray)
        {
            return $"{TypeName(type.GetElementType())}[{new string(',', type.GetArrayRank() - 1)}]";
        }
        if (type.IsGenericParameter)
        {
            return $"{(type.DeclaringMethod is null ? "!" : "!!")}" +
                $"{type.GenericParameterPosition}:{type.Name}";
        }
        if (!type.IsGenericType)
        {
            return type.FullName ?? type.Name;
        }

        var name = type.GetGenericTypeDefinition().FullName!;
        name = name[..name.IndexOf('`')];
        return $"{name}<{string.Join(',', type.GetGenericArguments().Select(TypeName))}>";
    }

    private sealed class UnownedVerifier :
        IProtectedExtensionActivationVerifier,
        IProtectedPolicyPackVerifier,
        IProtectedDispositionAuthorityVerifier,
        IPredecessorTrustVerifier
    {
        public bool Verify(
            ProtectedExtensionActivationPayload payload,
            ProtectedAuthorityEnvelope activationProof) => false;

        public bool Verify(
            ProtectedPolicyPackBinding protectedBinding,
            ProtectedAuthorityEnvelope packProof) => false;

        public bool Verify(
            ProtectedDispositionAuthorityPayload payload,
            ProtectedAuthorityEnvelope proof) => false;

        public bool Verify(
            PredecessorTrustPayload payload,
            ProtectedAuthorityEnvelope proof) => false;
    }
}
