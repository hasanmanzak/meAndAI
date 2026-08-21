using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal static class WaiverDispositionCore
{
    private const string RequiredPathEvaluator =
        "protocol.extension.repository-path-required";

    internal static ProtectedFinding Protect(
        RuleFinding finding,
        RuleDeclaration declaration)
    {
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(declaration);
        var findingDeclaration = declaration.Findings.SingleOrDefault(candidate =>
            candidate.Code.Equals(finding.Code)) ?? throw AuthorityInvalid();
        ValidateFinding(
            finding.Code,
            finding.Severity,
            finding.Remediation,
            finding.PrimaryReference,
            finding.RelatedReferences,
            findingDeclaration);
        var rule = PolicyRuleIdentity.Baseline(
            finding.RuleId,
            finding.RuleRevision);
        var location = StableLocation(finding.PrimaryReference, null);
        var evidence = StableEvidence(finding.PrimaryReference);
        var expected = ExpectedBaseline(declaration, findingDeclaration);
        var stable = StableFindingKey.Create(
            rule,
            finding.Code,
            location,
            evidence,
            expected);
        var identity = ProtectedFindingIdentity.Create(
            rule,
            finding.Code,
            location,
            evidence,
            expected,
            stable);
        return ProtectedFinding.Baseline(identity, finding, declaration);
    }

    internal static ProtectedFinding Protect(
        ExtensionFinding finding,
        ExtensionRuleDeclaration declaration,
        ExtensionEvaluatorKindDeclaration evaluatorKind)
    {
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(evaluatorKind);
        var findingDeclaration = evaluatorKind.Findings.SingleOrDefault(candidate =>
            candidate.Code.Equals(finding.Code)) ?? throw AuthorityInvalid();
        ValidateFinding(
            finding.Code,
            finding.Severity,
            finding.Remediation,
            finding.PrimaryReference,
            finding.RelatedReferences,
            findingDeclaration);
        var rule = PolicyRuleIdentity.Extension(
            finding.ExtensionId,
            finding.RuleRevision);
        ExactSha256Digest location;
        ExactSha256Digest evidence;
        if (string.Equals(
                evaluatorKind.EvaluatorKind,
                RequiredPathEvaluator,
                StringComparison.Ordinal))
        {
            var (path, expectedKind) = RequiredPath(declaration, finding);
            location = StableLocation(finding.PrimaryReference, path);
            evidence = ProtectedPolicyFrame.Hash(
                "protocol.extension.required-path-state/1\n",
                stream =>
                {
                    ProtectedPolicyFrame.String(stream, path);
                    ProtectedPolicyFrame.String(stream, expectedKind.Value);
                    ProtectedPolicyFrame.String(stream, finding.StableStateToken);
                    OptionalString(stream, finding.StableStateValue);
                });
        }
        else
        {
            location = StableLocation(finding.PrimaryReference, null);
            evidence = StableEvidence(finding.PrimaryReference);
        }

        var expected = ExpectedExtension(
            declaration,
            evaluatorKind,
            findingDeclaration);
        var stable = StableFindingKey.Create(
            rule,
            finding.Code,
            location,
            evidence,
            expected);
        var identity = ProtectedFindingIdentity.Create(
            rule,
            finding.Code,
            location,
            evidence,
            expected,
            stable);
        return ProtectedFinding.Extension(
            identity,
            finding,
            declaration,
            evaluatorKind);
    }

    internal static WaiverDispositionOutcome Apply(
        ActivatedExtensionPolicy activePolicy,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof,
        ExactSha256Digest evidenceSetDigest,
        IEnumerable<ProtectedFinding> findings)
    {
        ArgumentNullException.ThrowIfNull(activePolicy);
        ArgumentNullException.ThrowIfNull(waivers);
        ArgumentNullException.ThrowIfNull(historicalDebt);
        ArgumentNullException.ThrowIfNull(payload);
        ArgumentNullException.ThrowIfNull(proof);
        ArgumentNullException.ThrowIfNull(evidenceSetDigest);
        ArgumentNullException.ThrowIfNull(findings);
        ValidateAuthority(
            activePolicy,
            waivers,
            historicalDebt,
            payload,
            proof,
            evidenceSetDigest);
        var rows = findings.ToArray();
        if (rows.Any(static row => row is null) ||
            rows.Select(static row => row.Identity.StableKey.Value.Value)
                .Distinct(StringComparer.Ordinal).Count() != rows.Length)
        {
            throw AuthorityInvalid();
        }

        var authority = ProtectedDispositionAuthority.Create(payload, proof);
        var waiversByFinding = waivers.Waivers.ToDictionary(
            static row => row.Finding.StableKey.Value.Value,
            StringComparer.Ordinal);
        var results = rows
            .OrderBy(
                static row => row.Identity.StableKey.Value.Value,
                StringComparer.Ordinal)
            .Select(finding =>
            {
                waiversByFinding.TryGetValue(
                    finding.Identity.StableKey.Value.Value,
                    out var waiver);
                var applicable = IsApplicable(
                    activePolicy,
                    finding,
                    waiver,
                    payload.EvaluationUtc);
                return applicable is null
                    ? new FindingDispositionResult(
                        finding,
                        FindingDisposition.ActiveViolation,
                        null,
                        null)
                    : new FindingDispositionResult(
                        finding,
                        FindingDisposition.Waived,
                        applicable,
                        null);
            })
            .ToArray();
        return new WaiverDispositionOutcome(authority, Array.AsReadOnly(results));
    }

    private static void ValidateAuthority(
        ActivatedExtensionPolicy activePolicy,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof,
        ExactSha256Digest evidenceSetDigest)
    {
        var activation = activePolicy.ActivationPayload;
        if (!payload.ManifestDigest.Equals(activation.ManifestDigest) ||
            !payload.TrustedBaseAuthorityDigest.Equals(activation.ManifestDigest) ||
            !payload.AuthoritySetDigest.Equals(activePolicy.AuthoritySetDigest) ||
            !payload.EvidenceSetDigest.Equals(evidenceSetDigest) ||
            !payload.ExpectedAuthorityRecordDigest.Equals(
                activePolicy.ActivationRecordDigest) ||
            payload.AuthorityEpoch != activePolicy.ActivationEpoch ||
            !activePolicy.Policy.DispositionVerifier.Verify(payload, proof))
        {
            throw AuthorityInvalid();
        }

        if (!waivers.SnapshotDigest.Equals(payload.WaiverSnapshotDigest) ||
            waivers.Waivers.Any(row =>
                !row.TrustedBaseAuthorityDigest.Equals(
                    payload.TrustedBaseAuthorityDigest)))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.WaiverInvalid);
        }

        if (!historicalDebt.SnapshotDigest.Equals(payload.DebtSnapshotDigest) ||
            historicalDebt.Entries.Any(row =>
                !row.TrustedBaseAuthorityDigest.Equals(
                    payload.TrustedBaseAuthorityDigest) ||
                row.ClosedUtc > payload.EvaluationUtc))
        {
            throw new ProtectedPolicyIntegrityException(
                ProtectedPolicyIntegrityCode.DebtInvalid);
        }
    }

    private static WaiverDeclaration? IsApplicable(
        ActivatedExtensionPolicy activePolicy,
        ProtectedFinding finding,
        WaiverDeclaration? waiver,
        DateTimeOffset evaluationUtc)
    {
        if (waiver is null ||
            !SameIdentity(waiver.Finding, finding.Identity) ||
            !waiver.EvidenceDigest.Equals(finding.Identity.EvidenceDigest) ||
            !waiver.TrustedBaseAuthorityDigest.Equals(
                activePolicy.ActivationPayload.ManifestDigest) ||
            evaluationUtc < waiver.CreatedUtc ||
            evaluationUtc >= waiver.ExpiresUtc ||
            !IsWaiverAllowed(activePolicy, finding) ||
            !MatchesScope(activePolicy, finding, waiver))
        {
            return null;
        }

        return waiver;
    }

    private static bool IsWaiverAllowed(
        ActivatedExtensionPolicy activePolicy,
        ProtectedFinding finding)
    {
        if (finding.Identity.Rule.BaselineRuleId is { } ruleId)
        {
            return activePolicy.PolicyPackBinding.BaselineWaiverPolicy.Rules
                .Any(row =>
                    row.RuleId.Equals(ruleId) &&
                    row.RuleRevision.Equals(finding.Identity.Rule.Revision) &&
                    row.WaiverAllowed);
        }

        var extensionId = finding.Identity.Rule.ExtensionId!;
        var declaration = activePolicy.Snapshot.Extensions.SingleOrDefault(row =>
            row.ExtensionId.Equals(extensionId) &&
            row.Revision.Equals(finding.Identity.Rule.Revision));
        if (declaration is null)
        {
            return false;
        }

        return activePolicy.Policy.Registrations.Any(row =>
            string.Equals(
                row.Declaration.EvaluatorKind,
                declaration.EvaluatorKind,
                StringComparison.Ordinal) &&
            string.Equals(
                row.Declaration.EvaluatorVersion,
                declaration.EvaluatorVersion,
                StringComparison.Ordinal) &&
            row.Declaration.WaiverAllowed);
    }

    private static bool MatchesScope(
        ActivatedExtensionPolicy activePolicy,
        ProtectedFinding finding,
        WaiverDeclaration waiver)
    {
        var reference = finding.BaselineFinding?.PrimaryReference ??
            finding.ExtensionFinding!.PrimaryReference;
        return waiver.Scope.Value switch
        {
            "finding" => string.Equals(
                waiver.TargetSelector.Value,
                $"evidence:{finding.Identity.EvidenceDigest.Value}",
                StringComparison.Ordinal),
            "repository" => string.Equals(
                waiver.TargetSelector.Value,
                $"evidence:{StableScope(reference.Scope).Value}",
                StringComparison.Ordinal),
            "path" => TryPath(activePolicy, finding, reference, out var path) &&
                string.Equals(
                    waiver.TargetSelector.Value,
                    $"repository:{path}",
                    StringComparison.Ordinal),
            _ => false,
        };
    }

    private static bool TryPath(
        ActivatedExtensionPolicy activePolicy,
        ProtectedFinding finding,
        QualifiedEvidenceReference reference,
        out string path)
    {
        var location = reference.Location ?? reference.Root?.Location;
        if (location is RepositoryEvidenceLocation repository)
        {
            path = repository.RepositoryRelativePath;
            return true;
        }

        if (finding.Identity.Rule.ExtensionId is { } extensionId)
        {
            var declaration = activePolicy.Snapshot.Extensions.SingleOrDefault(row =>
                row.ExtensionId.Equals(extensionId) &&
                row.Revision.Equals(finding.Identity.Rule.Revision));
            var parameter = declaration?.Parameters.SingleOrDefault(row =>
                string.Equals(row.Key, "path", StringComparison.Ordinal));
            if (parameter is not null)
            {
                path = parameter.Value;
                return true;
            }
        }

        path = string.Empty;
        return false;
    }

    private static bool SameIdentity(
        ProtectedFindingIdentity left,
        ProtectedFindingIdentity right) =>
        string.Equals(
            left.Rule.CanonicalKey,
            right.Rule.CanonicalKey,
            StringComparison.Ordinal) &&
        left.FindingCode.Equals(right.FindingCode) &&
        left.LocationDigest.Equals(right.LocationDigest) &&
        left.EvidenceDigest.Equals(right.EvidenceDigest) &&
        left.ExpectedValueDigest.Equals(right.ExpectedValueDigest) &&
        left.StableKey.Value.Equals(right.StableKey.Value);

    private static void ValidateFinding(
        FindingCode code,
        FindingSeverity severity,
        RemediationKey remediation,
        QualifiedEvidenceReference primary,
        IReadOnlyList<QualifiedEvidenceReference> related,
        FindingDeclaration declaration)
    {
        if (!declaration.Code.Equals(code) ||
            !declaration.Severity.Equals(severity) ||
            !declaration.Remediation.Equals(remediation) ||
            !declaration.AllowedPrimaryReferenceKinds.Contains(primary.Kind) ||
            related.Any(reference =>
                !declaration.AllowedRelatedReferenceKinds.Contains(reference.Kind)))
        {
            throw AuthorityInvalid();
        }
    }

    private static (string Path, RepositoryEntryKind ExpectedKind) RequiredPath(
        ExtensionRuleDeclaration declaration,
        ExtensionFinding finding)
    {
        if (declaration.Parameters.Count != 2 ||
            !string.Equals(declaration.Parameters[0].Key, "kind", StringComparison.Ordinal) ||
            !string.Equals(declaration.Parameters[1].Key, "path", StringComparison.Ordinal) ||
            !RepositoryEntryKind.TryParse(
                declaration.Parameters[0].Value,
                out var expectedKind) ||
            (string.Equals(finding.StableStateToken, "missing", StringComparison.Ordinal)
                ? finding.StableStateValue is not null
                : !string.Equals(
                        finding.StableStateToken,
                        "kind-mismatch",
                        StringComparison.Ordinal) ||
                    !RepositoryEntryKind.TryParse(
                        finding.StableStateValue,
                        out var actualKind) ||
                    actualKind.Equals(expectedKind)))
        {
            throw AuthorityInvalid();
        }

        return (declaration.Parameters[1].Value, expectedKind);
    }

    internal static ExactSha256Digest StableScope(EvidenceScope scope) =>
        ProtectedPolicyFrame.Hash(
            "protocol.stable-evidence-scope/1\n",
            stream => WriteStableScope(stream, scope));

    internal static ExactSha256Digest ScopeDigest(EvidenceScope scope)
    {
        ArgumentNullException.ThrowIfNull(scope);
        return ProtectedPolicyFrame.Hash(
            "protocol.protected-evidence-scope/1\n",
            stream => WriteFullScope(stream, scope));
    }

    internal static byte[] ScopeFrame(EvidenceScope scope)
    {
        ArgumentNullException.ThrowIfNull(scope);
        using var stream = new MemoryStream();
        stream.Write("protocol.protected-evidence-scope/1\n"u8);
        WriteFullScope(stream, scope);
        return stream.ToArray();
    }

    internal static ExactSha256Digest ReferenceDigest(
        QualifiedEvidenceReference reference)
    {
        ArgumentNullException.ThrowIfNull(reference);
        return ProtectedPolicyFrame.Hash(
            "protocol.qualified-evidence-reference/1\n",
            stream => WriteReference(stream, reference));
    }

    internal static byte[] ReferenceFrame(QualifiedEvidenceReference reference)
    {
        ArgumentNullException.ThrowIfNull(reference);
        using var stream = new MemoryStream();
        stream.Write("protocol.qualified-evidence-reference/1\n"u8);
        WriteReference(stream, reference);
        return stream.ToArray();
    }

    private static void WriteReference(
        MemoryStream stream,
        QualifiedEvidenceReference reference)
    {
        ProtectedPolicyFrame.String(stream, reference.Kind.Value);
        ProtectedPolicyFrame.Digest(stream, reference.ManifestDigest);
        ProtectedPolicyFrame.UInt32(
            stream,
            checked((uint)reference.CatalogVersion.Value));
        ProtectedPolicyFrame.String(stream, reference.SlotKey);
        ProtectedPolicyFrame.String(stream, reference.RequirementKey);
        WriteFullScope(stream, reference.Scope);
        ProtectedPolicyFrame.Digest(
            stream,
            reference.QualificationProofDigest);
        WriteRoot(stream, reference.Root);
        WriteLocation(stream, reference.Location);
        ProtectedPolicyFrame.UInt32(
            stream,
            checked((uint)reference.Derivations.Count));
        foreach (var derivation in reference.Derivations)
        {
            WriteComponent(stream, derivation.Component);
            ProtectedPolicyFrame.String(stream, derivation.ArtifactFileName);
            ProtectedPolicyFrame.Digest(stream, derivation.ArtifactDigest);
            OptionalModel(stream, derivation.OutputModel);
            OptionalCapability(stream, derivation.OutputCapability);
            ProtectedPolicyFrame.String(stream, derivation.TypedNodeKind);
            ProtectedPolicyFrame.String(stream, derivation.TypedNodeIdentity);
            WriteFullLocation(stream, derivation.Location);
        }

        OptionalString(stream, reference.ExpectedSelectorParentKind?.Value);
        OptionalSelector(stream, reference.Selector);
    }

    private static ExactSha256Digest StableLocation(
        QualifiedEvidenceReference reference,
        string? requiredPath) => ProtectedPolicyFrame.Hash(
        "protocol.stable-evidence-location/1\n",
        stream =>
        {
            WriteStableScope(stream, reference.Scope);
            if (requiredPath is not null)
            {
                stream.WriteByte(1);
                ProtectedPolicyFrame.String(stream, requiredPath);
                return;
            }

            WriteStableLocation(
                stream,
                reference.Location ?? reference.Root?.Location ??
                SnapshotEvidenceLocation.Create(reference.Scope));
        });

    private static ExactSha256Digest StableEvidence(
        QualifiedEvidenceReference reference) => ProtectedPolicyFrame.Hash(
        "protocol.stable-evidence-identity/1\n",
        stream =>
        {
            ProtectedPolicyFrame.String(stream, reference.Kind.Value);
            ProtectedPolicyFrame.Digest(stream, reference.ManifestDigest);
            ProtectedPolicyFrame.UInt32(
                stream,
                checked((uint)reference.CatalogVersion.Value));
            ProtectedPolicyFrame.String(stream, reference.SlotKey);
            ProtectedPolicyFrame.String(stream, reference.RequirementKey);
            WriteStableScope(stream, reference.Scope);
            WriteStableRoot(stream, reference.Root);
            WriteStableEvidenceLocation(stream, reference.Location);
            ProtectedPolicyFrame.UInt32(
                stream,
                checked((uint)reference.Derivations.Count));
            foreach (var derivation in reference.Derivations)
            {
                WriteComponent(stream, derivation.Component);
                ProtectedPolicyFrame.String(stream, derivation.ArtifactFileName);
                ProtectedPolicyFrame.Digest(stream, derivation.ArtifactDigest);
                OptionalModel(stream, derivation.OutputModel);
                OptionalCapability(stream, derivation.OutputCapability);
                ProtectedPolicyFrame.String(stream, derivation.TypedNodeKind);
                ProtectedPolicyFrame.String(stream, derivation.TypedNodeIdentity);
                WriteStableLocation(stream, derivation.Location);
            }

            OptionalString(stream, reference.ExpectedSelectorParentKind?.Value);
            OptionalSelector(stream, reference.Selector);
        });

    private static ExactSha256Digest ExpectedBaseline(
        RuleDeclaration declaration,
        FindingDeclaration finding) => ProtectedPolicyFrame.Hash(
        "protocol.finding-expected-value/1\n",
        stream =>
        {
            stream.WriteByte(0);
            ProtectedPolicyFrame.String(stream, declaration.RuleId.Value);
            ProtectedPolicyFrame.UInt32(
                stream,
                checked((uint)declaration.RuleRevision.Value));
            WriteFinding(stream, finding);
        });

    private static ExactSha256Digest ExpectedExtension(
        ExtensionRuleDeclaration declaration,
        ExtensionEvaluatorKindDeclaration evaluatorKind,
        FindingDeclaration finding) => ProtectedPolicyFrame.Hash(
        "protocol.finding-expected-value/1\n",
        stream =>
        {
            stream.WriteByte(1);
            ProtectedPolicyFrame.Digest(stream, declaration.DefinitionDigest);
            ProtectedPolicyFrame.String(stream, evaluatorKind.EvaluatorKind);
            ProtectedPolicyFrame.String(stream, evaluatorKind.EvaluatorVersion);
            WriteFinding(stream, finding);
        });

    private static void WriteFinding(
        MemoryStream stream,
        FindingDeclaration finding)
    {
        ProtectedPolicyFrame.String(stream, finding.Code.Value);
        ProtectedPolicyFrame.String(stream, finding.Severity.Value);
        ProtectedPolicyFrame.String(stream, finding.Remediation.Value);
        WriteStrings(
            stream,
            finding.AllowedPrimaryReferenceKinds.Select(static row => row.Value));
        WriteStrings(
            stream,
            finding.AllowedRelatedReferenceKinds.Select(static row => row.Value));
    }

    private static void WriteStableScope(MemoryStream stream, EvidenceScope scope)
    {
        ProtectedPolicyFrame.String(stream, scope.Target.SubjectIdentity);
        ProtectedPolicyFrame.String(stream, scope.Target.SourceIdentity);
        ProtectedPolicyFrame.String(stream, scope.Target.Surface.Value);
        ProtectedPolicyFrame.String(stream, scope.Target.SnapshotKind.Value);
    }

    private static void WriteFullScope(MemoryStream stream, EvidenceScope scope)
    {
        WriteStableScope(stream, scope);
        ProtectedPolicyFrame.String(stream, scope.Target.TargetIdentity);
        ProtectedPolicyFrame.String(
            stream,
            scope.Boundary.SnapshotKind.Value);
        ProtectedPolicyFrame.String(stream, scope.Boundary.BoundaryIdentity);
        ProtectedPolicyFrame.Int64(stream, scope.Boundary.StartedAtUtc.Ticks);
        ProtectedPolicyFrame.Int64(stream, scope.Boundary.CompletedAtUtc.Ticks);
    }

    private static void WriteStableLocation(
        MemoryStream stream,
        EvidenceLocation location)
    {
        switch (location)
        {
            case SnapshotEvidenceLocation:
                stream.WriteByte(0);
                break;
            case RepositoryEvidenceLocation repository:
                stream.WriteByte(1);
                ProtectedPolicyFrame.String(
                    stream,
                    repository.RepositoryRelativePath);
                OptionalInt32(stream, repository.Line);
                OptionalString(stream, repository.Anchor);
                OptionalString(stream, repository.Property);
                break;
            case ProviderEvidenceLocation provider:
                stream.WriteByte(2);
                ProtectedPolicyFrame.String(
                    stream,
                    provider.ProviderServiceIdentity);
                ProtectedPolicyFrame.String(stream, provider.ObjectType);
                ProtectedPolicyFrame.String(
                    stream,
                    provider.StableObjectIdentity);
                OptionalString(stream, provider.Field);
                OptionalInt32(stream, provider.Line);
                OptionalString(stream, provider.Fragment);
                break;
            case ReleaseAssetEvidenceLocation release:
                stream.WriteByte(3);
                ProtectedPolicyFrame.String(stream, release.Tag);
                ProtectedPolicyFrame.String(stream, release.AssetName);
                break;
            default:
                throw AuthorityInvalid();
        }
    }

    private static void WriteRoot(
        MemoryStream stream,
        RootEvidenceReference? root)
    {
        stream.WriteByte(root is null ? (byte)0 : (byte)1);
        if (root is null)
        {
            return;
        }

        WriteFullScope(stream, root.Scope);
        ProtectedPolicyFrame.String(stream, root.SchemaKey);
        ProtectedPolicyFrame.String(stream, root.SchemaVersion);
        ProtectedPolicyFrame.Digest(stream, root.ContentDigest);
        WriteFullLocation(stream, root.Location);
        WriteStrings(stream, root.RequirementKeys);
        ProtectedPolicyFrame.Int64(stream, root.CapturedAtUtc.Ticks);
    }

    private static void WriteStableRoot(
        MemoryStream stream,
        RootEvidenceReference? root)
    {
        stream.WriteByte(root is null ? (byte)0 : (byte)1);
        if (root is null)
        {
            return;
        }

        ProtectedPolicyFrame.String(stream, root.SchemaKey);
        ProtectedPolicyFrame.String(stream, root.SchemaVersion);
        ProtectedPolicyFrame.Digest(stream, root.ContentDigest);
        WriteStableLocation(stream, root.Location);
        WriteStrings(stream, root.RequirementKeys);
    }

    private static void WriteLocation(
        MemoryStream stream,
        EvidenceLocation? location)
    {
        stream.WriteByte(location is null ? (byte)0 : (byte)1);
        if (location is null)
        {
            return;
        }

        WriteFullLocation(stream, location);
    }

    private static void WriteStableEvidenceLocation(
        MemoryStream stream,
        EvidenceLocation? location)
    {
        stream.WriteByte(location is null ? (byte)0 : (byte)1);
        if (location is null)
        {
            return;
        }

        WriteStableLocation(stream, location);
        switch (location)
        {
            case SnapshotEvidenceLocation:
                break;
            case RepositoryEvidenceLocation repository:
                OptionalString(stream, repository.BlobIdentity);
                break;
            case ProviderEvidenceLocation provider:
                ProtectedPolicyFrame.String(stream, provider.VersionIdentity);
                break;
            case ReleaseAssetEvidenceLocation release:
                ProtectedPolicyFrame.String(stream, release.ReleaseObjectIdentity);
                ProtectedPolicyFrame.Digest(stream, release.AssetDigest);
                break;
            default:
                throw AuthorityInvalid();
        }
    }

    private static void WriteFullLocation(
        MemoryStream stream,
        EvidenceLocation location)
    {
        switch (location)
        {
            case SnapshotEvidenceLocation:
                stream.WriteByte(0);
                WriteFullScope(stream, location.Scope);
                break;
            case RepositoryEvidenceLocation repository:
                stream.WriteByte(1);
                WriteFullScope(stream, repository.Scope);
                ProtectedPolicyFrame.String(
                    stream,
                    repository.RepositoryRelativePath);
                OptionalString(stream, repository.BlobIdentity);
                OptionalInt32(stream, repository.Line);
                OptionalString(stream, repository.Anchor);
                OptionalString(stream, repository.Property);
                break;
            case ProviderEvidenceLocation provider:
                stream.WriteByte(2);
                WriteFullScope(stream, provider.Scope);
                ProtectedPolicyFrame.String(
                    stream,
                    provider.ProviderServiceIdentity);
                ProtectedPolicyFrame.String(stream, provider.ObjectType);
                ProtectedPolicyFrame.String(
                    stream,
                    provider.StableObjectIdentity);
                ProtectedPolicyFrame.String(stream, provider.VersionIdentity);
                OptionalString(stream, provider.Field);
                OptionalInt32(stream, provider.Line);
                OptionalString(stream, provider.Fragment);
                break;
            case ReleaseAssetEvidenceLocation release:
                stream.WriteByte(3);
                WriteFullScope(stream, release.Scope);
                ProtectedPolicyFrame.String(stream, release.ReleaseObjectIdentity);
                ProtectedPolicyFrame.String(stream, release.Tag);
                ProtectedPolicyFrame.String(stream, release.AssetName);
                ProtectedPolicyFrame.Digest(stream, release.AssetDigest);
                break;
            default:
                throw AuthorityInvalid();
        }
    }

    private static void WriteComponent(
        MemoryStream stream,
        ComponentTypeIdentity component)
    {
        ProtectedPolicyFrame.String(stream, component.ComponentKey);
        ProtectedPolicyFrame.String(stream, component.ComponentVersion);
        ProtectedPolicyFrame.String(stream, component.AssemblyName);
        ProtectedPolicyFrame.String(stream, component.TypeName);
    }

    private static void OptionalModel(
        MemoryStream stream,
        ModelContractIdentity? model)
    {
        stream.WriteByte(model is null ? (byte)0 : (byte)1);
        if (model is null)
        {
            return;
        }

        ProtectedPolicyFrame.String(stream, model.ModelKey);
        ProtectedPolicyFrame.String(stream, model.ModelVersion);
        WriteComponent(stream, model.ImplementationType);
    }

    private static void OptionalCapability(
        MemoryStream stream,
        CapabilityContractIdentity? capability)
    {
        stream.WriteByte(capability is null ? (byte)0 : (byte)1);
        if (capability is null)
        {
            return;
        }

        ProtectedPolicyFrame.String(stream, capability.CapabilityKey);
        ProtectedPolicyFrame.String(stream, capability.CapabilityVersion);
        WriteComponent(stream, capability.InterfaceType);
    }

    private static void OptionalSelector(
        MemoryStream stream,
        QualifiedEvidenceSelector? selector)
    {
        stream.WriteByte(selector is null ? (byte)0 : (byte)1);
        if (selector is null)
        {
            return;
        }

        ProtectedPolicyFrame.String(stream, selector.SelectorKey);
        ProtectedPolicyFrame.String(stream, selector.SelectorSchemaKey);
        ProtectedPolicyFrame.String(stream, selector.CanonicalValue);
    }

    private static void OptionalString(MemoryStream stream, string? value)
    {
        stream.WriteByte(value is null ? (byte)0 : (byte)1);
        if (value is not null)
        {
            ProtectedPolicyFrame.String(stream, value);
        }
    }

    private static void OptionalInt32(MemoryStream stream, int? value)
    {
        stream.WriteByte(value.HasValue ? (byte)1 : (byte)0);
        if (value.HasValue)
        {
            ProtectedPolicyFrame.UInt32(stream, checked((uint)value.Value));
        }
    }

    private static void WriteStrings(
        MemoryStream stream,
        IEnumerable<string> values)
    {
        var rows = values.ToArray();
        ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Length));
        foreach (var value in rows)
        {
            ProtectedPolicyFrame.String(stream, value);
        }
    }

    private static ProtectedPolicyIntegrityException AuthorityInvalid() =>
        new(ProtectedPolicyIntegrityCode.DispositionAuthorityInvalid);
}

internal sealed record WaiverDispositionOutcome(
    ProtectedDispositionAuthority Authority,
    IReadOnlyList<FindingDispositionResult> Results);
