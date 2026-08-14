using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBQualifiedReferenceTests
{
    private const string Marker = "TEST-0210-B-BEHAVIOR-RED-0014";
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string TreeRequirement =
        "protocol.requirement.repository-tree";
    private const string TypedNodeKind =
        "protocol.codec-output.repository-tree";

    [Fact]
    [Trait("ContractSlice", "B")]
    [Trait("Scenario", "TEST-0210")]
    public void Seals_exact_codec_derived_reference_and_location_narrowing()
    {
        var fixture = CreateFixture();
        AssertNegativeMatrix(fixture);

        var callerFrames = fixture.Frames.ToArray();
        var references =
            ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                fixture.Manifest,
                fixture.Context,
                callerFrames);
        if (references is null)
        {
            Assert.Fail(Marker);
        }

        callerFrames[0] = callerFrames[1];
        AssertProjection(fixture, references);

        var clonedFrames = fixture.Frames
            .Select(CloneFrame)
            .ToArray();
        var repeated = Assert.IsAssignableFrom<
            IReadOnlyList<QualifiedEvidenceReference>>(
                ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                    fixture.Manifest,
                    fixture.Context,
                    clonedFrames));
        Assert.Equal(references.Count, repeated.Count);
        for (var index = 0; index < references.Count; index++)
        {
            AssertReferenceEqual(references[index], repeated[index]);
        }
    }

    private static Fixture CreateFixture()
    {
        var manifest =
            ContractSliceBAdmissionProofTests.CreateAdmissionManifest();
        var aggregate = Assert.IsType<AdmissionAggregateMirror>(
            ContractSliceBAdmissionProofTests.ExecuteContract());
        var context = Assert.IsType<SealedContextProjectionMirror>(
            ContractSliceBSealedContextCoordinatorMirror.Seal(
                manifest,
                aggregate));
        var parent = Assert.Single(context.Roots);
        var root = Assert.IsType<RootEvidenceReference>(parent.Root);
        var schema = manifest.SchemaRegistry.PayloadSchemas.Single(candidate =>
            string.Equals(
                candidate.SchemaKey,
                root.SchemaKey,
                StringComparison.Ordinal) &&
            string.Equals(
                candidate.SchemaVersion,
                root.SchemaVersion,
                StringComparison.Ordinal));
        var codec = manifest.Components.Single(binding =>
            ComponentEquals(binding.Component, schema.Codec));
        var artifact = manifest.ArtifactFiles.Single(binding =>
            string.Equals(
                binding.FileName,
                codec.ArtifactFileName,
                StringComparison.Ordinal));
        var baseIdentity =
            $"{schema.OutputModel.ModelKey}@{schema.OutputModel.ModelVersion}";
        var snapshot = SnapshotEvidenceLocation.Create(parent.Scope);
        var repository = RepositoryEvidenceLocation.Create(
            parent.Scope,
            "AGENTS.md",
            parent.Scope.Target.TargetIdentity,
            null,
            null,
            null);
        CodecDerivedReferenceFrameMirror[] frames =
        [
            new(
                CloneParent(parent),
                CloneCodec(codec),
                artifact.ArtifactDigest,
                CloneModel(schema.OutputModel),
                TypedNodeKind,
                baseIdentity,
                snapshot),
            new(
                CloneParent(parent),
                CloneCodec(codec),
                artifact.ArtifactDigest,
                CloneModel(schema.OutputModel),
                TypedNodeKind,
                $"{baseIdentity}#AGENTS.md",
                repository),
        ];

        return new Fixture(manifest, context, frames);
    }

    private static void AssertNegativeMatrix(Fixture fixture)
    {
        Assert.Equal(
            "manifest",
            Assert.Throws<ArgumentNullException>(() =>
                ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                    null!, fixture.Context, fixture.Frames)).ParamName);
        Assert.Equal(
            "context",
            Assert.Throws<ArgumentNullException>(() =>
                ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                    fixture.Manifest, null!, fixture.Frames)).ParamName);
        Assert.Equal(
            "frames",
            Assert.Throws<ArgumentNullException>(() =>
                ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                    fixture.Manifest, fixture.Context, null!)).ParamName);

        CodecDerivedReferenceFrameMirror[] nullRow =
            [fixture.Frames[0], null!];
        Assert.Equal(
            "frames",
            Assert.Throws<ArgumentException>(() => Seal(
                fixture,
                nullRow)).ParamName);

        Reject(
            CatalogIntegrityCode.ManifestInvalid,
            () => ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                ContractSliceBActivationTests.CreateManifest(),
                fixture.Context,
                fixture.Frames));
        Reject(
            CatalogIntegrityCode.ManifestInvalid,
            () => ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                fixture.Manifest,
                fixture.Context with
                {
                    Context = new SealedEvaluationContext(
                        CatalogAuthorityKind.CompleteProtocolSnapshot,
                        fixture.Context.Context.ManifestDigest,
                        fixture.Context.Context.CatalogVersion,
                        [TreeSlot],
                        fixture.Context.Context.Scopes),
                },
                fixture.Frames));
        Reject(
            CatalogIntegrityCode.ManifestInvalid,
            () => ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
                fixture.Manifest,
                fixture.Context with
                {
                    Context = new SealedEvaluationContext(
                        fixture.Context.Context.AuthorityKind,
                        fixture.Context.Context.ManifestDigest,
                        fixture.Context.Context.CatalogVersion,
                        [],
                        []),
                },
                fixture.Frames));

        RejectFrames(fixture, fixture.Frames[0] with
        {
            Parent = fixture.Context.ContextProof,
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            Parent = CloneParent(
                fixture.Frames[0].Parent,
                manifestDigest: ZeroDigest()),
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            Parent = CloneParent(
                fixture.Frames[0].Parent,
                derivations: [CreateDerivation(fixture.Frames[0])]),
        });

        RejectFrames(fixture, fixture.Frames[0] with { Codec = null! });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            Codec = ComponentArtifactBinding.Create(
                ForeignComponent(fixture.Frames[0].Codec.Component),
                fixture.Frames[0].Codec.ArtifactFileName),
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            Codec = ComponentArtifactBinding.Create(
                fixture.Frames[0].Codec.Component,
                "foreign.dll"),
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            ArtifactDigest = ZeroDigest(),
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            OutputModel = ModelContractIdentity.Create(
                fixture.Frames[0].OutputModel.ModelKey,
                fixture.Frames[0].OutputModel.ModelVersion,
                ForeignComponent(
                    fixture.Frames[0].OutputModel.ImplementationType)),
        });

        RejectFrames(fixture, fixture.Frames[0] with
        {
            TypedNodeKind = "",
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            TypedNodeIdentity = $"{fixture.Frames[0].TypedNodeIdentity}#drift",
        });
        RejectFrames(fixture, fixture.Frames[0] with
        {
            Location = RepositoryEvidenceLocation.Create(
                fixture.Frames[0].Parent.Scope,
                "AGENTS.md",
                fixture.Frames[0].Parent.Scope.Target.TargetIdentity,
                null,
                null,
                null),
        });
        RejectFrames(fixture, fixture.Frames[1] with
        {
            Location = RepositoryEvidenceLocation.Create(
                fixture.Frames[1].Parent.Scope,
                "README.md",
                fixture.Frames[1].Parent.Scope.Target.TargetIdentity,
                null,
                null,
                null),
        }, replaceIndex: 1);
        RejectFrames(fixture, fixture.Frames[1] with
        {
            Location = RepositoryEvidenceLocation.Create(
                fixture.Frames[1].Parent.Scope,
                "AGENTS.md",
                null,
                null,
                null,
                null),
        }, replaceIndex: 1);
        RejectFrames(fixture, fixture.Frames[1] with
        {
            Location = RepositoryEvidenceLocation.Create(
                fixture.Frames[1].Parent.Scope,
                "AGENTS.md",
                fixture.Frames[1].Parent.Scope.Target.TargetIdentity,
                1,
                null,
                null),
        }, replaceIndex: 1);

        Reject(
            CatalogIntegrityCode.ReferenceInvalid,
            () => Seal(fixture, [fixture.Frames[1], fixture.Frames[0]]));
        Reject(
            CatalogIntegrityCode.ReferenceInvalid,
            () => Seal(fixture, [fixture.Frames[0]]));
        Reject(
            CatalogIntegrityCode.ReferenceInvalid,
            () => Seal(
                fixture,
                [fixture.Frames[0], fixture.Frames[0]]));
    }

    private static void AssertProjection(
        Fixture fixture,
        IReadOnlyList<QualifiedEvidenceReference> references)
    {
        Assert.Equal(2, references.Count);
        for (var index = 0; index < references.Count; index++)
        {
            var frame = fixture.Frames[index];
            var reference = references[index];
            Assert.Equal(QualifiedEvidenceReferenceKind.Derived, reference.Kind);
            Assert.Equal(frame.Parent.ManifestDigest, reference.ManifestDigest);
            Assert.Equal(frame.Parent.CatalogVersion, reference.CatalogVersion);
            Assert.Equal(frame.Parent.SlotKey, reference.SlotKey);
            Assert.Equal(frame.Parent.RequirementKey, reference.RequirementKey);
            Assert.Equal(frame.Parent.Scope, reference.Scope);
            Assert.Equal(
                frame.Parent.QualificationProofDigest,
                reference.QualificationProofDigest);
            Assert.Same(frame.Parent.Root, reference.Root);
            Assert.Same(frame.Location, reference.Location);
            Assert.Null(reference.ExpectedSelectorParentKind);
            Assert.Null(reference.Selector);

            var derivation = Assert.Single(reference.Derivations);
            Assert.True(ComponentEquals(
                frame.Codec.Component,
                derivation.Component));
            Assert.Equal(
                frame.Codec.ArtifactFileName,
                derivation.ArtifactFileName);
            Assert.Equal(frame.ArtifactDigest, derivation.ArtifactDigest);
            Assert.Equal(frame.OutputModel, derivation.OutputModel);
            Assert.Null(derivation.OutputCapability);
            Assert.Equal(frame.TypedNodeKind, derivation.TypedNodeKind);
            Assert.Equal(frame.TypedNodeIdentity, derivation.TypedNodeIdentity);
            Assert.Same(frame.Location, derivation.Location);
        }

        var list = Assert.IsAssignableFrom<IList<QualifiedEvidenceReference>>(
            references);
        Assert.Throws<NotSupportedException>(() => list[0] = references[1]);
    }

    private static void AssertReferenceEqual(
        QualifiedEvidenceReference expected,
        QualifiedEvidenceReference actual)
    {
        Assert.True(ReferenceEqualsStructural(expected, actual));
        Assert.Equal(expected.Derivations.Count, actual.Derivations.Count);
        for (var index = 0; index < expected.Derivations.Count; index++)
        {
            var left = expected.Derivations[index];
            var right = actual.Derivations[index];
            Assert.True(ComponentEquals(left.Component, right.Component));
            Assert.Equal(left.ArtifactFileName, right.ArtifactFileName);
            Assert.Equal(left.ArtifactDigest, right.ArtifactDigest);
            Assert.Equal(left.OutputModel, right.OutputModel);
            Assert.Equal(left.OutputCapability, right.OutputCapability);
            Assert.Equal(left.TypedNodeKind, right.TypedNodeKind);
            Assert.Equal(left.TypedNodeIdentity, right.TypedNodeIdentity);
            Assert.Equal(left.Location, right.Location);
        }
    }

    private static void RejectFrames(
        Fixture fixture,
        CodecDerivedReferenceFrameMirror replacement,
        int replaceIndex = 0)
    {
        var frames = fixture.Frames.ToArray();
        frames[replaceIndex] = replacement;
        Reject(
            CatalogIntegrityCode.ReferenceInvalid,
            () => Seal(fixture, frames));
    }

    private static IReadOnlyList<QualifiedEvidenceReference>? Seal(
        Fixture fixture,
        IReadOnlyList<CodecDerivedReferenceFrameMirror> frames) =>
        ContractSliceBCodecDerivedReferenceCoordinatorMirror.Seal(
            fixture.Manifest,
            fixture.Context,
            frames);

    private static CodecDerivedReferenceFrameMirror CloneFrame(
        CodecDerivedReferenceFrameMirror frame) =>
        new(
            CloneParent(frame.Parent),
            CloneCodec(frame.Codec),
            frame.ArtifactDigest,
            CloneModel(frame.OutputModel),
            frame.TypedNodeKind,
            frame.TypedNodeIdentity,
            CloneLocation(frame.Location));

    private static QualifiedEvidenceReference CloneParent(
        QualifiedEvidenceReference source,
        ExactSha256Digest? manifestDigest = null,
        IEnumerable<QualifiedEvidenceDerivation>? derivations = null) =>
        new(
            source.Kind,
            manifestDigest ?? source.ManifestDigest,
            source.CatalogVersion,
            source.SlotKey,
            source.RequirementKey,
            source.Scope,
            source.QualificationProofDigest,
            source.Root,
            CloneLocation(source.Location!),
            derivations ?? source.Derivations,
            source.ExpectedSelectorParentKind,
            source.Selector);

    private static ComponentArtifactBinding CloneCodec(
        ComponentArtifactBinding source) =>
        ComponentArtifactBinding.Create(
            ComponentTypeIdentity.Create(
                source.Component.ComponentKey,
                source.Component.ComponentVersion,
                source.Component.AssemblyName,
                source.Component.TypeName),
            source.ArtifactFileName);

    private static ModelContractIdentity CloneModel(
        ModelContractIdentity source) =>
        ModelContractIdentity.Create(
            source.ModelKey,
            source.ModelVersion,
            ComponentTypeIdentity.Create(
                source.ImplementationType.ComponentKey,
                source.ImplementationType.ComponentVersion,
                source.ImplementationType.AssemblyName,
                source.ImplementationType.TypeName));

    private static ComponentTypeIdentity ForeignComponent(
        ComponentTypeIdentity source) =>
        ComponentTypeIdentity.Create(
            source.ComponentKey,
            source.ComponentVersion,
            source.AssemblyName,
            $"{source.TypeName}.Foreign");

    private static EvidenceLocation CloneLocation(EvidenceLocation source) =>
        source switch
        {
            SnapshotEvidenceLocation => SnapshotEvidenceLocation.Create(
                source.Scope),
            RepositoryEvidenceLocation repository =>
                RepositoryEvidenceLocation.Create(
                    repository.Scope,
                    repository.RepositoryRelativePath,
                    repository.BlobIdentity,
                    repository.Line,
                    repository.Anchor,
                    repository.Property),
            _ => throw new InvalidOperationException(),
        };

    private static QualifiedEvidenceDerivation CreateDerivation(
        CodecDerivedReferenceFrameMirror frame) =>
        new(
            frame.Codec.Component,
            frame.Codec.ArtifactFileName,
            frame.ArtifactDigest,
            frame.OutputModel,
            null,
            frame.TypedNodeKind,
            frame.TypedNodeIdentity,
            frame.Location);

    private static void Reject(CatalogIntegrityCode code, Action action)
    {
        var exception = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Same(code, exception.Code);
    }

    private static bool ComponentEquals(
        ComponentTypeIdentity? left,
        ComponentTypeIdentity? right) =>
        left is not null &&
        right is not null &&
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

    private static bool ReferenceEqualsStructural(
        QualifiedEvidenceReference left,
        QualifiedEvidenceReference right) =>
        left.Kind.Equals(right.Kind) &&
        left.ManifestDigest.Equals(right.ManifestDigest) &&
        left.CatalogVersion.Equals(right.CatalogVersion) &&
        string.Equals(left.SlotKey, right.SlotKey, StringComparison.Ordinal) &&
        string.Equals(
            left.RequirementKey,
            right.RequirementKey,
            StringComparison.Ordinal) &&
        left.Scope.Equals(right.Scope) &&
        left.QualificationProofDigest.Equals(
            right.QualificationProofDigest) &&
        Equals(left.Root, right.Root) &&
        Equals(left.Location, right.Location) &&
        left.ExpectedSelectorParentKind is null &&
        right.ExpectedSelectorParentKind is null &&
        left.Selector is null &&
        right.Selector is null;

    private static ExactSha256Digest ZeroDigest() =>
        ExactSha256Digest.Parse(new string('0', 64));

    private sealed record Fixture(
        FinalizedPolicyManifest Manifest,
        SealedContextProjectionMirror Context,
        IReadOnlyList<CodecDerivedReferenceFrameMirror> Frames);
}

internal sealed record CodecDerivedReferenceFrameMirror(
    QualifiedEvidenceReference Parent,
    ComponentArtifactBinding Codec,
    ExactSha256Digest ArtifactDigest,
    ModelContractIdentity OutputModel,
    string TypedNodeKind,
    string TypedNodeIdentity,
    EvidenceLocation Location);

internal static class ContractSliceBCodecDerivedReferenceCoordinatorMirror
{
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string TreeRequirement =
        "protocol.requirement.repository-tree";
    private const string TypedNodeKind =
        "protocol.codec-output.repository-tree";

    internal static IReadOnlyList<QualifiedEvidenceReference>? Seal(
        FinalizedPolicyManifest manifest,
        SealedContextProjectionMirror context,
        IReadOnlyList<CodecDerivedReferenceFrameMirror> frames)
    {
        ArgumentNullException.ThrowIfNull(manifest);
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(frames);

        var copiedFrames = frames.ToArray();
        if (copiedFrames.Any(frame => frame is null))
        {
            throw new ArgumentException(
                "A codec-derived reference frame cannot be null.",
                nameof(frames));
        }

        var roots = context.Roots?.ToArray();
        if (!manifest.AuthorityKind.Equals(
                CatalogAuthorityKind.QualificationSlice) ||
            manifest.Slice is not CatalogSliceDeclaration slice ||
            manifest.CompleteCatalog is not null ||
            context.Context is null ||
            !context.Context.AuthorityKind.Equals(manifest.AuthorityKind) ||
            !context.Context.ManifestDigest.Equals(manifest.ManifestDigest) ||
            !context.Context.CatalogVersion.Equals(slice.CatalogVersion) ||
            !context.Context.AdmittedSlotKeys.SequenceEqual(
                [TreeSlot],
                StringComparer.Ordinal) ||
            context.Context.Scopes.Count != 1 ||
            roots is null ||
            roots.Length != 1 ||
            !context.Context.Scopes[0].Equals(roots[0].Scope))
        {
            throw ManifestInvalid();
        }

        var root = roots[0];
        if (!IsCanonicalRoot(root))
        {
            throw ReferenceInvalid();
        }

        foreach (var frame in copiedFrames)
        {
            if (frame.Parent is null ||
                !IsCanonicalRoot(frame.Parent) ||
                !ReferenceEqualsStructural(frame.Parent, root))
            {
                throw ReferenceInvalid();
            }
        }

        var rootEvidence = root.Root!;
        var schemas = manifest.SchemaRegistry.PayloadSchemas
            .Where(candidate =>
                string.Equals(
                    candidate.SchemaKey,
                    rootEvidence.SchemaKey,
                    StringComparison.Ordinal) &&
                string.Equals(
                    candidate.SchemaVersion,
                    rootEvidence.SchemaVersion,
                    StringComparison.Ordinal))
            .ToArray();
        if (schemas.Length != 1)
        {
            throw ReferenceInvalid();
        }

        var schema = schemas[0];
        var codecs = manifest.Components
            .Where(binding => ComponentEquals(
                binding.Component,
                schema.Codec))
            .ToArray();
        if (codecs.Length != 1)
        {
            throw ReferenceInvalid();
        }

        var codec = codecs[0];
        var artifacts = manifest.ArtifactFiles
            .Where(binding => string.Equals(
                binding.FileName,
                codec.ArtifactFileName,
                StringComparison.Ordinal))
            .ToArray();
        if (artifacts.Length != 1)
        {
            throw ReferenceInvalid();
        }

        var artifact = artifacts[0];
        foreach (var frame in copiedFrames)
        {
            if (frame.Codec is null ||
                frame.ArtifactDigest is null ||
                frame.OutputModel is null ||
                !ComponentEquals(
                    frame.Codec.Component,
                    codec.Component) ||
                !string.Equals(
                    frame.Codec.ArtifactFileName,
                    codec.ArtifactFileName,
                    StringComparison.Ordinal) ||
                !frame.ArtifactDigest.Equals(artifact.ArtifactDigest) ||
                !frame.OutputModel.Equals(schema.OutputModel))
            {
                throw ReferenceInvalid();
            }
        }

        var baseIdentity =
            $"{schema.OutputModel.ModelKey}@{schema.OutputModel.ModelVersion}";
        foreach (var frame in copiedFrames)
        {
            if (!string.Equals(
                    frame.TypedNodeKind,
                    TypedNodeKind,
                    StringComparison.Ordinal) ||
                !IsValidLocation(frame, baseIdentity))
            {
                throw ReferenceInvalid();
            }
        }

        if (copiedFrames.Length != 2 ||
            CompareKey(copiedFrames[0], copiedFrames[1]) >= 0)
        {
            throw ReferenceInvalid();
        }

        var references = copiedFrames.Select(frame =>
        {
            var derivation = new QualifiedEvidenceDerivation(
                frame.Codec.Component,
                frame.Codec.ArtifactFileName,
                frame.ArtifactDigest,
                frame.OutputModel,
                null,
                frame.TypedNodeKind,
                frame.TypedNodeIdentity,
                frame.Location);
            return new QualifiedEvidenceReference(
                QualifiedEvidenceReferenceKind.Derived,
                frame.Parent.ManifestDigest,
                frame.Parent.CatalogVersion,
                frame.Parent.SlotKey,
                frame.Parent.RequirementKey,
                frame.Parent.Scope,
                frame.Parent.QualificationProofDigest,
                frame.Parent.Root,
                frame.Location,
                [derivation],
                null,
                null);
        }).ToArray();

        _ = Array.AsReadOnly(references);
        return Array.AsReadOnly(references);
    }

    private static bool IsCanonicalRoot(QualifiedEvidenceReference reference) =>
        reference.Kind.Equals(QualifiedEvidenceReferenceKind.Root) &&
        string.Equals(
            reference.SlotKey,
            TreeSlot,
            StringComparison.Ordinal) &&
        string.Equals(
            reference.RequirementKey,
            TreeRequirement,
            StringComparison.Ordinal) &&
        reference.Root is not null &&
        reference.Location is not null &&
        reference.Root.Scope.Equals(reference.Scope) &&
        reference.Root.Location.Equals(reference.Location) &&
        reference.Derivations.Count == 0 &&
        reference.ExpectedSelectorParentKind is null &&
        reference.Selector is null;

    private static bool IsValidLocation(
        CodecDerivedReferenceFrameMirror frame,
        string baseIdentity)
    {
        if (frame.Location is null)
        {
            return false;
        }

        if (string.Equals(
                frame.TypedNodeIdentity,
                baseIdentity,
                StringComparison.Ordinal))
        {
            return frame.Location is SnapshotEvidenceLocation &&
                frame.Location.Equals(frame.Parent.Location);
        }

        if (!string.Equals(
                frame.TypedNodeIdentity,
                $"{baseIdentity}#AGENTS.md",
                StringComparison.Ordinal) ||
            frame.Location is not RepositoryEvidenceLocation repository)
        {
            return false;
        }

        return repository.Scope.Equals(frame.Parent.Scope) &&
            string.Equals(
                repository.RepositoryRelativePath,
                "AGENTS.md",
                StringComparison.Ordinal) &&
            string.Equals(
                repository.BlobIdentity,
                frame.Parent.Scope.Target.TargetIdentity,
                StringComparison.Ordinal) &&
            repository.Line is null &&
            repository.Anchor is null &&
            repository.Property is null;
    }

    private static int CompareKey(
        CodecDerivedReferenceFrameMirror left,
        CodecDerivedReferenceFrameMirror right)
    {
        var kind = string.CompareOrdinal(
            left.TypedNodeKind,
            right.TypedNodeKind);
        return kind != 0
            ? kind
            : string.CompareOrdinal(
                left.TypedNodeIdentity,
                right.TypedNodeIdentity);
    }

    private static bool ComponentEquals(
        ComponentTypeIdentity? left,
        ComponentTypeIdentity? right) =>
        left is not null &&
        right is not null &&
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

    private static bool ReferenceEqualsStructural(
        QualifiedEvidenceReference left,
        QualifiedEvidenceReference right) =>
        left.Kind.Equals(right.Kind) &&
        left.ManifestDigest.Equals(right.ManifestDigest) &&
        left.CatalogVersion.Equals(right.CatalogVersion) &&
        string.Equals(left.SlotKey, right.SlotKey, StringComparison.Ordinal) &&
        string.Equals(
            left.RequirementKey,
            right.RequirementKey,
            StringComparison.Ordinal) &&
        left.Scope.Equals(right.Scope) &&
        left.QualificationProofDigest.Equals(
            right.QualificationProofDigest) &&
        Equals(left.Root, right.Root) &&
        Equals(left.Location, right.Location) &&
        left.Derivations.Count == right.Derivations.Count &&
        left.Derivations.Zip(right.Derivations)
            .All(pair => DerivationEquals(pair.First, pair.Second)) &&
        left.ExpectedSelectorParentKind is null &&
        right.ExpectedSelectorParentKind is null &&
        left.Selector is null &&
        right.Selector is null;

    private static bool DerivationEquals(
        QualifiedEvidenceDerivation left,
        QualifiedEvidenceDerivation right) =>
        ComponentEquals(left.Component, right.Component) &&
        string.Equals(
            left.ArtifactFileName,
            right.ArtifactFileName,
            StringComparison.Ordinal) &&
        left.ArtifactDigest.Equals(right.ArtifactDigest) &&
        Equals(left.OutputModel, right.OutputModel) &&
        Equals(left.OutputCapability, right.OutputCapability) &&
        string.Equals(
            left.TypedNodeKind,
            right.TypedNodeKind,
            StringComparison.Ordinal) &&
        string.Equals(
            left.TypedNodeIdentity,
            right.TypedNodeIdentity,
            StringComparison.Ordinal) &&
        left.Location.Equals(right.Location);

    private static CatalogIntegrityException ManifestInvalid() =>
        new(CatalogIntegrityCode.ManifestInvalid);

    private static CatalogIntegrityException ReferenceInvalid() =>
        new(CatalogIntegrityCode.ReferenceInvalid);
}
