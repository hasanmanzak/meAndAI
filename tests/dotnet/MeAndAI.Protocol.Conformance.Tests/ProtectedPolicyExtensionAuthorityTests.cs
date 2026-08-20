using System.Numerics;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;
using MeAndAI.Protocol.Policy.ProtectedPolicy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicyExtensionAuthorityTests
{
    [Fact]
    public void Keeps_active_extension_authority_separate_from_candidate_proposal()
    {
        var fixture = ProjectNeutralProtectedAuthorityFixture.CreateCanonicalEmpty();
        var validation = ExtensionAuthorityCore.Validate(
            fixture.Kernel.Catalog,
            fixture.Manifest,
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);

        Assert.Same(fixture.Snapshot, validation.Snapshot);
        Assert.Same(fixture.ActivationPayload, validation.ActivationPayload);
        Assert.Same(fixture.PackBinding, validation.PolicyPackBinding);
        Assert.Same(fixture.Policy, validation.Policy);
        Assert.Equal(fixture.AuthorityRecordDigest, validation.ActivationRecordDigest);
        Assert.Equal(1, validation.ActivationEpoch);
        ProjectNeutralProtectedAuthorityFixture.AssertKnownAnswerCorpus();

        var activated = fixture.Kernel.ActivateExtensions(
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        Assert.Same(fixture.Snapshot, activated.Snapshot);
        Assert.Same(fixture.ActivationPayload, activated.ActivationPayload);
        Assert.Same(fixture.PackBinding, activated.PolicyPackBinding);
        Assert.Same(fixture.Policy, activated.Policy);
        Assert.Equal(fixture.AuthorityRecordDigest, activated.ActivationRecordDigest);
        Assert.Equal(1, activated.ActivationEpoch);

        ProjectNeutralProtectedAuthorityFixture.AssertTypedProofRoutes(fixture);
        ProjectNeutralProtectedAuthorityFixture.AssertExactPackBinding(fixture);
        ProjectNeutralProtectedAuthorityFixture.AssertPublicNonemptyFailsClosed(fixture);
    }
}

internal static class ProjectNeutralProtectedAuthorityFixture
{
    private const string ExportKey = "protocol.policy.extension-protected.test-fixture";
    private const string ExportVersion = "1";
    private const string IssuerKeyId = "protocol.authority.test";
    private const string Algorithm = "ed25519";
    private const string SeedHex =
        "9D61B19DEFFD5A60BA844AF492EC2CC44449C5697B326919703BAC031CAE7F60";
    private const string PublicKeyHex =
        "D75A980182B10AB7D54BFED3C964073A0EE172F3DAA62325AF021A68F707511A";
    private const string RepositoryNamespace = "repo";
    private static readonly ExactSha256Digest AuthorityRecordDigest = Digest("authority-record");

    internal static EmptyAuthorityFixture CreateCanonicalEmpty() =>
        CreateCanonicalFixture(
            CreateTestPolicy(Array.Empty<ExtensionEvaluatorRegistration>()),
            Array.Empty<ExtensionRuleDeclaration>(),
            Digest("extension-policy-blob"));

    internal static EmptyAuthorityFixture CreateCanonicalNonempty(
        ExtensionPolicyPackExport policy,
        ExtensionRuleDeclaration declaration)
    {
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(declaration);
        var fixture = CreateCanonicalFixture(
            policy,
            [declaration],
            Digest("registered-extension-policy-blob"));
        _ = ExtensionAuthorityCore.Validate(
            fixture.Kernel.Catalog,
            fixture.Manifest,
            fixture.Snapshot,
            fixture.ActivationPayload,
            fixture.ActivationProof,
            fixture.PackBinding,
            fixture.PackProof,
            fixture.Policy);
        return fixture;
    }

    private static EmptyAuthorityFixture CreateCanonicalFixture(
        ExtensionPolicyPackExport policy,
        IReadOnlyList<ExtensionRuleDeclaration> declarations,
        ExactSha256Digest policyBlobDigest)
    {
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(declarations);
        ArgumentNullException.ThrowIfNull(policyBlobDigest);
        var baseline = ContractSliceCActivationTests.CreateFixture();
        var manifest = AddPolicyArtifact(baseline.Manifest);
        var kernel = ConformanceKernel.Activate(
            manifest,
            baseline.Export,
            new ContractSliceCActivationProof(manifest, baseline.Export),
            predecessor: null);
        var snapshotDigest = ExtensionCatalogSnapshot.ComputeDigest(
            RepositoryNamespace,
            policyBlobDigest,
            declarations);
        var snapshot = ExtensionCatalogSnapshot.Create(
            RepositoryNamespace,
            policyBlobDigest,
            snapshotDigest,
            declarations);
        var activationPayload = ProtectedExtensionActivationPayload.Create(
            manifest.ManifestDigest,
            RepositoryNamespace,
            policyBlobDigest,
            Digest("authority-set"),
            AuthorityRecordDigest,
            Digest("previous-activation-record"),
            Digest("closure-evidence"),
            snapshot.SnapshotDigest,
            manifest.SourceCommit,
            activationEpoch: 1);
        var waiverPolicy = CreateBaselineWaiverPolicy(kernel.Catalog, manifest.ManifestDigest);
        var packBinding = CreatePackBinding(manifest, policy, waiverPolicy);
        var activationProof = CreateActivationProof(activationPayload);
        var packProof = CreatePackProof(packBinding, activationPayload);

        Assert.True(policy.ActivationVerifier.Verify(activationPayload, activationProof));
        Assert.True(policy.PolicyPackVerifier.Verify(packBinding, packProof));
        return new EmptyAuthorityFixture(
            kernel,
            manifest,
            snapshot,
            activationPayload,
            activationProof,
            packBinding,
            packProof,
            policy,
            AuthorityRecordDigest);
    }

    internal static ProtectedAuthorityEnvelope CreateActivationProof(
        ProtectedExtensionActivationPayload payload)
    {
        ArgumentNullException.ThrowIfNull(payload);
        var proof = Sign(
            "protocol.extension-activation-proof",
            payload.PayloadDigest,
            payload.ExpectedAuthorityRecordDigest,
            payload.ActivationEpoch);
        Assert.True(CreateTestPolicy(Array.Empty<ExtensionEvaluatorRegistration>())
            .ActivationVerifier.Verify(payload, proof));
        return proof;
    }

    internal static ProtectedAuthorityEnvelope CreatePackProof(
        ProtectedPolicyPackBinding binding,
        ProtectedExtensionActivationPayload activationPayload)
    {
        ArgumentNullException.ThrowIfNull(binding);
        ArgumentNullException.ThrowIfNull(activationPayload);
        var proof = Sign(
            "protocol.protected-policy-pack-proof",
            binding.BindingDigest,
            activationPayload.ExpectedAuthorityRecordDigest,
            activationPayload.ActivationEpoch);
        Assert.True(CreateTestPolicy(Array.Empty<ExtensionEvaluatorRegistration>())
            .PolicyPackVerifier.Verify(binding, proof));
        return proof;
    }

    internal static ProtectedAuthorityEnvelope CreateDispositionProof(
        ProtectedDispositionAuthorityPayload payload)
    {
        ArgumentNullException.ThrowIfNull(payload);
        var proof = Sign(
            "protocol.protected-disposition-authority-proof",
            payload.PayloadDigest,
            payload.ExpectedAuthorityRecordDigest,
            payload.AuthorityEpoch);
        Assert.True(CreateTestPolicy(Array.Empty<ExtensionEvaluatorRegistration>())
            .DispositionVerifier.Verify(payload, proof));
        return proof;
    }

    internal static ProtectedAuthorityEnvelope CreatePredecessorProof(
        PredecessorTrustPayload payload)
    {
        ArgumentNullException.ThrowIfNull(payload);
        var proof = Sign(
            "protocol.predecessor-trust-proof",
            payload.PayloadDigest,
            payload.ExpectedAuthorityRecordDigest,
            payload.AuthorityEpoch);
        Assert.True(CreateTestPolicy(Array.Empty<ExtensionEvaluatorRegistration>())
            .PredecessorVerifier.Verify(payload, proof));
        return proof;
    }

    internal static void AssertTypedProofRoutes(EmptyAuthorityFixture fixture)
    {
        ArgumentNullException.ThrowIfNull(fixture);
        var disposition = ProtectedDispositionAuthorityPayload.Create(
            fixture.Manifest.ManifestDigest,
            fixture.Manifest.ManifestDigest,
            fixture.ActivationPayload.AuthoritySetDigest,
            fixture.PackBinding.BaselineWaiverPolicy.SnapshotDigest,
            Digest("debt-snapshot"),
            Digest("evidence-set"),
            fixture.AuthorityRecordDigest,
            authorityEpoch: 1,
            new DateTimeOffset(2026, 8, 20, 0, 0, 0, TimeSpan.Zero));
        var dispositionProof = CreateDispositionProof(disposition);
        Assert.Equal(disposition.PayloadDigest, dispositionProof.PayloadDigest);
        Assert.Equal(fixture.AuthorityRecordDigest, dispositionProof.AuthorityRecordDigest);

        var runtimeArtifact = fixture.Manifest.ArtifactFiles.Single(row =>
            string.Equals(
                row.FileName,
                "MeAndAI.Protocol.Conformance.dll",
                StringComparison.Ordinal));
        var predecessorBinding = RuntimeQualificationBinding.Create(
            fixture.Kernel.Catalog.ProtocolVersion,
            fixture.Manifest.SourceCommit,
            fixture.Manifest.ManifestDigest,
            fixture.Kernel.Catalog.CompleteInventoryDigest,
            fixture.PackBinding.BindingDigest,
            runtimeArtifact.ArtifactDigest,
            Digest("current-trust-anchor"));
        var predecessor = PredecessorTrustPayload.Create(
            predecessorBinding,
            predecessorBinding.TrustAnchorDigest,
            fixture.AuthorityRecordDigest,
            authorityEpoch: 1,
            "protocol.fixture.overlap",
            "1",
            Digest("overlap-fixture"),
            Digest("predecessor-overlap-evidence"),
            Digest("candidate-overlap-evidence"),
            Digest("predecessor-overlap-outcome"),
            Digest("expected-candidate-binding"),
            Digest("reviewed-differences"),
            "protocol.fixture.independent",
            "1",
            Digest("independent-fixture"),
            Digest("independent-evidence"),
            Digest("independent-outcome"));
        var predecessorProof = CreatePredecessorProof(predecessor);
        Assert.Equal(predecessor.PayloadDigest, predecessorProof.PayloadDigest);
        Assert.Equal(fixture.AuthorityRecordDigest, predecessorProof.AuthorityRecordDigest);
    }

    internal static void AssertExactPackBinding(EmptyAuthorityFixture fixture)
    {
        ArgumentNullException.ThrowIfNull(fixture);
        var policyRow = fixture.PackBinding.Artifacts.Single(row =>
            string.Equals(
                row.ArtifactKey,
                "protocol.artifact.policy",
                StringComparison.Ordinal));
        var wrongComponentRows = fixture.PackBinding.Artifacts.Select(row =>
            ReferenceEquals(row, policyRow)
                ? ProtectedPolicyArtifactBinding.Create(
                    row.ArtifactKey,
                    row.FileName,
                    row.FileLength,
                    row.FileDigest,
                    Array.Empty<string>())
                : row).ToArray();
        AssertPackRejected(
            fixture,
            CreatePackBindingFromArtifacts(
                fixture.Manifest,
                fixture.Policy,
                fixture.PackBinding.BaselineWaiverPolicy,
                wrongComponentRows),
            ProtectedPolicyIntegrityCode.PolicyPackBindingInvalid);

        var wrongDigestRows = fixture.PackBinding.Artifacts.Select(row =>
            ReferenceEquals(row, policyRow)
                ? ProtectedPolicyArtifactBinding.Create(
                    row.ArtifactKey,
                    row.FileName,
                    row.FileLength,
                    Digest("wrong-policy-artifact"),
                    row.ComponentKeys)
                : row).ToArray();
        AssertPackRejected(
            fixture,
            CreatePackBindingFromArtifacts(
                fixture.Manifest,
                fixture.Policy,
                fixture.PackBinding.BaselineWaiverPolicy,
                wrongDigestRows),
            ProtectedPolicyIntegrityCode.PolicyPackBindingInvalid);

        AssertPackRejected(
            fixture,
            fixture.PackBinding,
            ProtectedPolicyIntegrityCode.PolicyPackBindingInvalid,
            Sign(
                "protocol.protected-policy-pack-proof",
                fixture.PackBinding.BindingDigest,
                Digest("cross-record"),
                authorityEpoch: 1));
        AssertPackRejected(
            fixture,
            fixture.PackBinding,
            ProtectedPolicyIntegrityCode.PolicyPackBindingInvalid,
            Sign(
                "protocol.protected-policy-pack-proof",
                fixture.PackBinding.BindingDigest,
                fixture.AuthorityRecordDigest,
                authorityEpoch: 2));
    }

    internal static void AssertPublicNonemptyFailsClosed(EmptyAuthorityFixture fixture)
    {
        ArgumentNullException.ThrowIfNull(fixture);
        const string unprovisionedIssuer =
            "protocol.authority.unprovisioned.extension-policy.v1";
        var parameters = new[]
        {
            ExtensionParameter.Create("entry-kind", "file"),
            ExtensionParameter.Create("path", "AGENTS.md"),
        };
        var roles = new[] { SubjectRole.Consumer };
        var surfaces = SurfaceSet.Create([SurfaceKind.Repository]);
        var snapshots = new[] { SnapshotKind.ExactCommit };
        var operations = new[] { ProtocolOperation.Conformance };
        var extensionId = ExtensionId.Parse("ext:repo:required-agents");
        var revision = RuleRevision.Create(1);
        const string evaluatorKind = "protocol.extension.repository-path-required";
        const string evaluatorVersion = "1";
        var definitionDigest = ExtensionRuleDeclaration.ComputeDefinition(
            extensionId,
            revision,
            evaluatorKind,
            evaluatorVersion,
            parameters,
            roles,
            surfaces,
            snapshots,
            operations);
        var declaration = ExtensionRuleDeclaration.Create(
            extensionId,
            revision,
            evaluatorKind,
            evaluatorVersion,
            parameters,
            roles,
            surfaces,
            snapshots,
            operations,
            definitionDigest);
        var policyBlobDigest = Digest("unprovisioned-nonempty-policy");
        var snapshotDigest = ExtensionCatalogSnapshot.ComputeDigest(
            RepositoryNamespace,
            policyBlobDigest,
            [declaration]);
        var snapshot = ExtensionCatalogSnapshot.Create(
            RepositoryNamespace,
            policyBlobDigest,
            snapshotDigest,
            [declaration]);
        var payload = ProtectedExtensionActivationPayload.Create(
            fixture.Manifest.ManifestDigest,
            RepositoryNamespace,
            policyBlobDigest,
            fixture.ActivationPayload.AuthoritySetDigest,
            fixture.AuthorityRecordDigest,
            fixture.ActivationPayload.PreviousActivationRecordDigest,
            fixture.ActivationPayload.ClosureEvidenceDigest,
            snapshot.SnapshotDigest,
            fixture.Manifest.SourceCommit,
            activationEpoch: 1);
        var policy = CreateTestPolicy(
            unprovisionedIssuer,
            Array.Empty<ExtensionEvaluatorRegistration>());
        var pack = CreatePackBinding(
            fixture.Manifest,
            policy,
            fixture.PackBinding.BaselineWaiverPolicy);
        var activationProof = Sign(
            "protocol.extension-activation-proof",
            payload.PayloadDigest,
            fixture.AuthorityRecordDigest,
            authorityEpoch: 1,
            unprovisionedIssuer);
        var packProof = Sign(
            "protocol.protected-policy-pack-proof",
            pack.BindingDigest,
            fixture.AuthorityRecordDigest,
            authorityEpoch: 1,
            unprovisionedIssuer);

        var failure = Assert.Throws<ProtectedPolicyIntegrityException>(() =>
            fixture.Kernel.ActivateExtensions(
                snapshot,
                payload,
                activationProof,
                pack,
                packProof,
                policy));
        Assert.Equal(ProtectedPolicyIntegrityCode.ActivationProofInvalid, failure.Code);
    }

    internal static void AssertKnownAnswerCorpus()
    {
        var payload = ExactSha256Digest.Parse(new string('1', 64));
        var record = ExactSha256Digest.Parse(new string('2', 64));
        var publicKey = Convert.FromHexString(PublicKeyHex);
        (string ContractKey,
            int SigningLength,
            string SigningDigest,
            int EnvelopeLength,
            string EnvelopeDigest,
            string Base64)[] cases =
        {
            (ContractKey: "protocol.extension-activation-proof",
                SigningLength: 202,
                SigningDigest: "E261D35024A39F8A8D02514D786AF986482C773A4407E182A0276B54D3ED497C",
                EnvelopeLength: 258,
                EnvelopeDigest:
                "574D2F7BC3EDDB6652197DA9A6B548477FA09A7FA9004E1EFD5F2DB2F95046E6",
                Base64: "cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAI3Byb3RvY29sLmV4dGVuc2lvbi1hY3RpdmF0aW9uLXByb29mAAAAATERERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAAAAAAAAEETz6gphZl04yB9XScsKKG+RLcSMqHhh0bFdC/ssxacOFbLmpgdlE9y8Dfc2wSjz6DALqC7zAh4LlWseEcjqAE"),
            ("protocol.protected-policy-pack-proof",
                203,
                "3C3027F9540732A7D10AB906FCA4FBFC33D7B0F2A54019EFB523F3DD93B9C673",
                259,
                "15589E6295D4B61D75686CFC2B5A1F995398BA926895AB1745ABCA5E9F834AD5",
                "cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAJHByb3RvY29sLnByb3RlY3RlZC1wb2xpY3ktcGFjay1wcm9vZgAAAAExEREREREREREREREREREREREREREREREREREREREREREiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIgAAAAAAAAABPso6mNr9DGW1Z8Sz5+6VkfXjo7IzUGzmovEeVvIASgaUzo2OKOXhS2s4JkbFsJQPVQfQGwXc89r06bBA8KVPDA=="),
            ("protocol.protected-disposition-authority-proof",
                213,
                "91808B04E4D7C27E2115D0EDFECED28EE9EB1CB3531BDE753598F9698A8B600E",
                269,
                "7B037B204681A581B63FA16EC3C0148E3CF640C61159BFAE7E57AD18684118C0",
                "cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAALnByb3RvY29sLnByb3RlY3RlZC1kaXNwb3NpdGlvbi1hdXRob3JpdHktcHJvb2YAAAABMRERERERERERERERERERERERERERERERERERERERERERIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIAAAAAAAAAAXkLkGomjGxp/alANRgwgHd62PyrWeVMZujW+S5z/Mid0LGZgtsKIaOnHPlR0webx5KYNm+bhlk0d3y9mO0DygE="),
            ("protocol.predecessor-trust-proof",
                199,
                "FEA89ABBF9A34EA939B77DAAC3C7BA3D9B4406876E4C41D928027719E43E3DCA",
                255,
                "4670533144F7467A51D9A94356077C4B71073673F9571BC0ACEEDC8B4098390D",
                "cHJvdG9jb2wucHJvdGVjdGVkLWF1dGhvcml0eS1lbnZlbG9wZS8xCgAAABdwcm90b2NvbC5hdXRob3JpdHkudGVzdAAAAAdlZDI1NTE5AAAAIHByb3RvY29sLnByZWRlY2Vzc29yLXRydXN0LXByb29mAAAAATERERERERERERERERERERERERERERERERERERERERERESIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAAAAAAAAAAEA/fXwwvArk4VXYXXdxku0mcEf6a0JtPrwa23M5M2CXe65veSgzWM99zYDW7u/Yy0kTz/EJWUdenFvBFhg+QsO"),
        };

        for (var index = 0; index < cases.Length; index++)
        {
            var knownAnswer = cases[index];
            var bytes = Convert.FromBase64String(knownAnswer.Base64);
            Assert.Equal(knownAnswer.EnvelopeLength, bytes.Length);
            var signature = bytes[^64..];
            var envelope = KnownAnswerEnvelope(
                knownAnswer.ContractKey, payload, record, signature);
            var signingBytes = KnownAnswerSigningBytes(
                knownAnswer.ContractKey, payload, record);
            Assert.Equal(knownAnswer.SigningLength, signingBytes.Length);
            Assert.Equal(
                knownAnswer.SigningDigest,
                Convert.ToHexString(SHA256.HashData(signingBytes)));
            Assert.Equal(
                knownAnswer.EnvelopeDigest,
                envelope.EnvelopeDigest.Value.ToUpperInvariant());
            Assert.True(CreateVerifier(index, publicKey).VerifyKnownAnswer(payload, envelope));
            AssertKnownAnswerMutations(
                index, knownAnswer.ContractKey, payload, record, signature, publicKey);
        }
    }

    private static void AssertKnownAnswerMutations(
        int verifierIndex,
        string contractKey,
        ExactSha256Digest payload,
        ExactSha256Digest record,
        byte[] signature,
        byte[] publicKey)
    {
        var verifier = CreateVerifier(verifierIndex, publicKey);
        var changedPayload = ExactSha256Digest.Parse(new string('3', 64));
        var changedRecord = ExactSha256Digest.Parse(new string('4', 64));
        var fieldMutations = new[]
        {
            ProtectedAuthorityEnvelope.Create(
                $"{IssuerKeyId}.changed", Algorithm, contractKey, "1",
                payload, record, 1, signature),
            ProtectedAuthorityEnvelope.Create(
                IssuerKeyId, "ed25518", contractKey, "1",
                payload, record, 1, signature),
            ProtectedAuthorityEnvelope.Create(
                IssuerKeyId, Algorithm, $"{contractKey}.changed", "1",
                payload, record, 1, signature),
            ProtectedAuthorityEnvelope.Create(
                IssuerKeyId, Algorithm, contractKey, "2",
                payload, record, 1, signature),
            ProtectedAuthorityEnvelope.Create(
                IssuerKeyId, Algorithm, contractKey, "1",
                changedPayload, record, 1, signature),
            ProtectedAuthorityEnvelope.Create(
                IssuerKeyId, Algorithm, contractKey, "1",
                payload, changedRecord, 1, signature),
            ProtectedAuthorityEnvelope.Create(
                IssuerKeyId, Algorithm, contractKey, "1",
                payload, record, 2, signature),
        };
        Assert.All(fieldMutations, mutation =>
            Assert.False(verifier.VerifyKnownAnswer(payload, mutation)));

        for (var index = 0; index < signature.Length; index++)
        {
            var changedSignature = signature.ToArray();
            changedSignature[index] ^= 1;
            Assert.False(verifier.VerifyKnownAnswer(
                payload,
                KnownAnswerEnvelope(contractKey, payload, record, changedSignature)));
        }

        for (var index = 0; index < publicKey.Length; index++)
        {
            var changedKey = publicKey.ToArray();
            changedKey[index] ^= 1;
            Assert.False(CreateVerifier(verifierIndex, changedKey).VerifyKnownAnswer(
                payload,
                KnownAnswerEnvelope(contractKey, payload, record, signature)));
        }
    }

    private static ProtectedAuthorityEnvelopeVerifierBase CreateVerifier(
        int index,
        byte[] publicKey) => index switch
        {
            0 => new ExtensionActivationEnvelopeVerifier(IssuerKeyId, publicKey),
            1 => new ProtectedPolicyPackEnvelopeVerifier(IssuerKeyId, publicKey),
            2 => new ProtectedDispositionEnvelopeVerifier(IssuerKeyId, publicKey),
            3 => new PredecessorTrustEnvelopeVerifier(IssuerKeyId, publicKey),
            _ => throw new ArgumentOutOfRangeException(nameof(index)),
        };

    private static ProtectedAuthorityEnvelope KnownAnswerEnvelope(
        string contractKey,
        ExactSha256Digest payload,
        ExactSha256Digest record,
        byte[] signature) =>
        ProtectedAuthorityEnvelope.Create(
            IssuerKeyId,
            Algorithm,
            contractKey,
            "1",
            payload,
            record,
            authorityEpoch: 1,
            signature);

    private static byte[] KnownAnswerSigningBytes(
        string contractKey,
        ExactSha256Digest payload,
        ExactSha256Digest record)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes(
            "protocol.protected-authority-envelope-signing/1\n"));
        ProtectedPolicyFrame.String(stream, IssuerKeyId);
        ProtectedPolicyFrame.String(stream, Algorithm);
        ProtectedPolicyFrame.String(stream, contractKey);
        ProtectedPolicyFrame.String(stream, "1");
        ProtectedPolicyFrame.Digest(stream, payload);
        ProtectedPolicyFrame.Digest(stream, record);
        ProtectedPolicyFrame.Int64(stream, 1);
        return stream.ToArray();
    }

    internal static ExtensionPolicyPackExport CreateTestPolicy(
        IEnumerable<ExtensionEvaluatorRegistration> registrations) =>
        CreateTestPolicy(IssuerKeyId, registrations);

    private static ExtensionPolicyPackExport CreateTestPolicy(
        string issuerKeyId,
        IEnumerable<ExtensionEvaluatorRegistration> registrations)
    {
        ArgumentNullException.ThrowIfNull(registrations);
        var registrationRows = registrations
            .OrderBy(static row => row.Declaration.EvaluatorKind, StringComparer.Ordinal)
            .ToArray();
        var publicKey = Convert.FromHexString(PublicKeyHex);
        var activation = new ExtensionActivationEnvelopeVerifier(issuerKeyId, publicKey);
        var pack = new ProtectedPolicyPackEnvelopeVerifier(issuerKeyId, publicKey);
        var disposition = new ProtectedDispositionEnvelopeVerifier(issuerKeyId, publicKey);
        var predecessor = new PredecessorTrustEnvelopeVerifier(issuerKeyId, publicKey);
        var digest = ComputeExportDigest(publicKey, issuerKeyId, registrationRows);
        return ExtensionPolicyPackExport.Create(
            ExportKey,
            ExportVersion,
            digest,
            issuerKeyId,
            Algorithm,
            publicKey,
            activation,
            pack,
            disposition,
            predecessor,
            registrationRows);
    }

    private static ExactSha256Digest ComputeExportDigest(
        byte[] publicKey,
        string issuerKeyId,
        IReadOnlyList<ExtensionEvaluatorRegistration> registrations)
    {
        var components = new[]
        {
            Component("protocol.verifier.extension-activation", nameof(ExtensionActivationEnvelopeVerifier)),
            Component("protocol.verifier.protected-policy-pack", nameof(ProtectedPolicyPackEnvelopeVerifier)),
            Component("protocol.verifier.protected-disposition", nameof(ProtectedDispositionEnvelopeVerifier)),
            Component("protocol.verifier.predecessor-trust", nameof(PredecessorTrustEnvelopeVerifier)),
        };
        var publicKeyDigest = ExactSha256Digest.FromHashBytes(SHA256.HashData(publicKey));
        return ProtectedPolicyFrame.Hash("protocol.extension-policy-pack/1\n", stream =>
        {
            ProtectedPolicyFrame.String(stream, ExportKey);
            ProtectedPolicyFrame.String(stream, ExportVersion);
            ProtectedPolicyFrame.String(stream, issuerKeyId);
            ProtectedPolicyFrame.String(stream, Algorithm);
            ProtectedPolicyFrame.Digest(stream, publicKeyDigest);
            foreach (var component in components)
            {
                ProtectedPolicyFrame.String(stream, component.ComponentKey);
                ProtectedPolicyFrame.String(stream, component.ComponentVersion);
                ProtectedPolicyFrame.String(stream, component.AssemblyName);
                ProtectedPolicyFrame.String(stream, component.TypeName);
            }

            ProtectedPolicyFrame.UInt32(stream, checked((uint)registrations.Count));
            foreach (var registration in registrations)
            {
                var kind = registration.Declaration;
                ProtectedPolicyFrame.String(stream, kind.EvaluatorKind);
                ProtectedPolicyFrame.String(stream, kind.EvaluatorVersion);
                ProtectedPolicyFrame.String(stream, kind.Component.ComponentKey);
                ProtectedPolicyFrame.String(stream, kind.Component.ComponentVersion);
                ProtectedPolicyFrame.String(stream, kind.Component.AssemblyName);
                ProtectedPolicyFrame.String(stream, kind.Component.TypeName);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)kind.Parameters.Count));
                foreach (var parameter in kind.Parameters)
                {
                    ProtectedPolicyFrame.String(stream, parameter.Key);
                    ProtectedPolicyFrame.String(stream, parameter.ValueGrammar);
                    ProtectedPolicyFrame.UInt32(
                        stream,
                        checked((uint)parameter.MaximumUtf8Bytes));
                }

                WriteStrings(stream, kind.ApplicabilitySlotKeys);
                WriteStrings(stream, kind.EvaluationSlotKeys);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)kind.Findings.Count));
                foreach (var finding in kind.Findings)
                {
                    ProtectedPolicyFrame.String(stream, finding.Code.Value);
                    ProtectedPolicyFrame.String(stream, finding.Severity.Value);
                    ProtectedPolicyFrame.String(stream, finding.Remediation.Value);
                    WriteStrings(
                        stream,
                        finding.AllowedPrimaryReferenceKinds
                            .Select(static row => row.Value)
                            .ToArray());
                    WriteStrings(
                        stream,
                        finding.AllowedRelatedReferenceKinds
                            .Select(static row => row.Value)
                            .ToArray());
                }

                WriteStrings(
                    stream,
                    kind.FailureCodes.Select(static row => row.Value).ToArray());
                ProtectedPolicyFrame.Bool(stream, kind.WaiverAllowed);
            }
        });
    }

    private static void WriteStrings(
        MemoryStream stream,
        IReadOnlyList<string> values)
    {
        ProtectedPolicyFrame.UInt32(stream, checked((uint)values.Count));
        foreach (var value in values)
        {
            ProtectedPolicyFrame.String(stream, value);
        }
    }

    private static ComponentTypeIdentity Component(string key, string name) =>
        ComponentTypeIdentity.Create(
            key,
            "1",
            "MeAndAI.Protocol.Policy",
            $"MeAndAI.Protocol.Policy.ProtectedPolicy.{name}");

    private static FinalizedPolicyManifest AddPolicyArtifact(FinalizedPolicyManifest source)
    {
        var artifacts = source.ArtifactFiles
            .Append(ArtifactFileBinding.Create(
                "MeAndAI.Protocol.Policy.dll",
                1,
                Digest("policy-artifact")))
            .OrderBy(static row => row.FileName, StringComparer.Ordinal)
            .ToArray();
        return ContractSliceCActivationTests.CreateSyntheticManifest(
            source.AuthorityKind,
            source.SourceCommit,
            Digest("protected-authority-manifest"),
            source.SchemaRegistry,
            source.ActivationProofContract,
            artifacts,
            source.Components,
            source.Slice,
            source.CompleteCatalog);
    }

    private static BaselineWaiverPolicySnapshot CreateBaselineWaiverPolicy(
        CompleteCatalogSnapshot catalog,
        ExactSha256Digest manifestDigest)
    {
        var rows = catalog.Rules.Select(rule => BaselineRuleWaiverPolicy.Create(
            rule.RuleId,
            rule.RuleRevision,
            waiverAllowed: false)).ToArray();
        var digest = ProtectedPolicyFrame.Hash("protocol.baseline-waiver-policy/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, manifestDigest);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Length));
            foreach (var row in rows)
            {
                ProtectedPolicyFrame.String(stream, row.RuleId.Value);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)row.RuleRevision.Value));
                ProtectedPolicyFrame.Bool(stream, row.WaiverAllowed);
            }
        });
        return BaselineWaiverPolicySnapshot.Create(manifestDigest, digest, rows);
    }

    private static ProtectedPolicyPackBinding CreatePackBinding(
        FinalizedPolicyManifest manifest,
        ExtensionPolicyPackExport policy,
        BaselineWaiverPolicySnapshot waiverPolicy)
    {
        var keysByFile = policy.Components
            .GroupBy(component => $"{component.AssemblyName}.dll", StringComparer.Ordinal)
            .ToDictionary(
                static group => group.Key,
                static group => group.Select(component => component.ComponentKey)
                    .Order(StringComparer.Ordinal).ToArray(),
                StringComparer.Ordinal);
        var definitions = new[]
        {
            ("protocol.artifact.domain", "MeAndAI.Protocol.Domain.dll"),
            ("protocol.artifact.conformance-abstractions", "MeAndAI.Protocol.Conformance.Abstractions.dll"),
            ("protocol.artifact.conformance-runtime", "MeAndAI.Protocol.Conformance.dll"),
            ("protocol.artifact.policy", "MeAndAI.Protocol.Policy.dll"),
        };
        var artifacts = definitions.Select(definition =>
        {
            var manifestArtifact = manifest.ArtifactFiles.Single(
                row => string.Equals(row.FileName, definition.Item2, StringComparison.Ordinal));
            return ProtectedPolicyArtifactBinding.Create(
                definition.Item1,
                definition.Item2,
                manifestArtifact.ByteLength,
                manifestArtifact.ArtifactDigest,
                keysByFile.GetValueOrDefault(definition.Item2) ?? []);
        }).ToArray();
        return CreatePackBindingFromArtifacts(
            manifest,
            policy,
            waiverPolicy,
            artifacts);
    }

    private static ProtectedPolicyPackBinding CreatePackBindingFromArtifacts(
        FinalizedPolicyManifest manifest,
        ExtensionPolicyPackExport policy,
        BaselineWaiverPolicySnapshot waiverPolicy,
        IReadOnlyList<ProtectedPolicyArtifactBinding> artifacts)
    {
        var digest = ProtectedPolicyPackBinding.ComputeDigest(
            manifest.ManifestDigest,
            policy.ExportDigest,
            waiverPolicy.SnapshotDigest,
            artifacts);
        return ProtectedPolicyPackBinding.Create(
            manifest.ManifestDigest,
            policy.ExportDigest,
            waiverPolicy,
            artifacts,
            digest);
    }

    private static void AssertPackRejected(
        EmptyAuthorityFixture fixture,
        ProtectedPolicyPackBinding binding,
        ProtectedPolicyIntegrityCode expectedCode,
        ProtectedAuthorityEnvelope? proof = null)
    {
        var packProof = proof ?? CreatePackProof(binding, fixture.ActivationPayload);
        var failure = Assert.Throws<ProtectedPolicyIntegrityException>(() =>
            ExtensionAuthorityCore.Validate(
                fixture.Kernel.Catalog,
                fixture.Manifest,
                fixture.Snapshot,
                fixture.ActivationPayload,
                fixture.ActivationProof,
                binding,
                packProof,
                fixture.Policy));
        Assert.Equal(expectedCode, failure.Code);
    }

    private static ProtectedAuthorityEnvelope Sign(
        string contractKey,
        ExactSha256Digest payloadDigest,
        ExactSha256Digest recordDigest,
        long authorityEpoch,
        string issuerKeyId = IssuerKeyId)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes(
            "protocol.protected-authority-envelope-signing/1\n"));
        ProtectedPolicyFrame.String(stream, issuerKeyId);
        ProtectedPolicyFrame.String(stream, Algorithm);
        ProtectedPolicyFrame.String(stream, contractKey);
        ProtectedPolicyFrame.String(stream, "1");
        ProtectedPolicyFrame.Digest(stream, payloadDigest);
        ProtectedPolicyFrame.Digest(stream, recordDigest);
        ProtectedPolicyFrame.Int64(stream, authorityEpoch);
        var signature = TestEd25519Signer.Sign(
            stream.ToArray(),
            Convert.FromHexString(SeedHex));
        return ProtectedAuthorityEnvelope.Create(
            issuerKeyId,
            Algorithm,
            contractKey,
            "1",
            payloadDigest,
            recordDigest,
            authorityEpoch,
            signature);
    }

    private static ExactSha256Digest Digest(string value) =>
        ExactSha256Digest.FromHashBytes(SHA256.HashData(Encoding.UTF8.GetBytes(value)));

    internal sealed record EmptyAuthorityFixture(
        ConformanceKernel Kernel,
        FinalizedPolicyManifest Manifest,
        ExtensionCatalogSnapshot Snapshot,
        ProtectedExtensionActivationPayload ActivationPayload,
        ProtectedAuthorityEnvelope ActivationProof,
        ProtectedPolicyPackBinding PackBinding,
        ProtectedAuthorityEnvelope PackProof,
        ExtensionPolicyPackExport Policy,
        ExactSha256Digest AuthorityRecordDigest);
}

internal static class TestEd25519Signer
{
    private static readonly BigInteger Prime = (BigInteger.One << 255) - 19;
    private static readonly BigInteger Order =
        (BigInteger.One << 252) + BigInteger.Parse("27742317777372353535851937790883648493");
    private static readonly BigInteger D = Mod(-121665 * Invert(121666));
    private static readonly Point BasePoint = new(
        BigInteger.Parse("15112221349535400772501151409588531511454012693041857206046113283949847762202"),
        BigInteger.Parse("46316835694926478169428394003475163141307993866256225615783033603165251855960"));

    internal static byte[] Sign(ReadOnlySpan<byte> message, ReadOnlySpan<byte> seed)
    {
        var expanded = SHA512.HashData(seed);
        expanded[0] &= 248;
        expanded[31] &= 63;
        expanded[31] |= 64;
        var secretScalar = Scalar(expanded.AsSpan(0, 32));
        var publicKey = Encode(Multiply(BasePoint, secretScalar));
        Assert.Equal(
            "D75A980182B10AB7D54BFED3C964073A0EE172F3DAA62325AF021A68F707511A",
            Convert.ToHexString(publicKey));

        var nonceInput = new byte[32 + message.Length];
        expanded.AsSpan(32, 32).CopyTo(nonceInput);
        message.CopyTo(nonceInput.AsSpan(32));
        var nonce = Scalar(SHA512.HashData(nonceInput)) % Order;
        var encodedR = Encode(Multiply(BasePoint, nonce));
        var challengeInput = new byte[64 + message.Length];
        encodedR.CopyTo(challengeInput, 0);
        publicKey.CopyTo(challengeInput, 32);
        message.CopyTo(challengeInput.AsSpan(64));
        var challenge = Scalar(SHA512.HashData(challengeInput)) % Order;
        var scalar = (nonce + challenge * secretScalar) % Order;
        var signature = new byte[64];
        encodedR.CopyTo(signature, 0);
        WriteScalar(scalar, signature.AsSpan(32));
        return signature;
    }

    private static byte[] Encode(Point point)
    {
        var bytes = new byte[32];
        WriteScalar(point.Y, bytes);
        if (!point.X.IsEven)
        {
            bytes[31] |= 0x80;
        }

        return bytes;
    }

    private static void WriteScalar(BigInteger value, Span<byte> destination)
    {
        destination.Clear();
        Assert.True(value.TryWriteBytes(
            destination,
            out var written,
            isUnsigned: true,
            isBigEndian: false));
        Assert.InRange(written, 1, destination.Length);
    }

    private static BigInteger Scalar(ReadOnlySpan<byte> value) =>
        new(value, isUnsigned: true, isBigEndian: false);

    private static Point Multiply(Point point, BigInteger scalar)
    {
        var result = Point.Identity;
        var addend = point;
        while (scalar > 0)
        {
            if (!scalar.IsEven)
            {
                result = Add(result, addend);
            }

            addend = Add(addend, addend);
            scalar >>= 1;
        }

        return result;
    }

    private static Point Add(Point left, Point right)
    {
        var product = D * left.X * right.X * left.Y * right.Y;
        return new Point(
            Mod((left.X * right.Y + left.Y * right.X) * Invert(1 + product)),
            Mod((left.Y * right.Y + left.X * right.X) * Invert(1 - product)));
    }

    private static BigInteger Invert(BigInteger value) =>
        BigInteger.ModPow(Mod(value), Prime - 2, Prime);

    private static BigInteger Mod(BigInteger value)
    {
        var result = value % Prime;
        return result.Sign < 0 ? result + Prime : result;
    }

    private readonly record struct Point(BigInteger X, BigInteger Y)
    {
        internal static Point Identity => new(BigInteger.Zero, BigInteger.One);
    }
}
