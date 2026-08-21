using System.Diagnostics.CodeAnalysis;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RuntimeQualificationBinding
{
    private RuntimeQualificationBinding(
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

    public string ProtocolVersion { get; }
    public string SourceCommit { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest CatalogDigest { get; }
    public ExactSha256Digest PolicyPackBindingDigest { get; }
    public ExactSha256Digest RuntimeArtifactDigest { get; }
    public ExactSha256Digest TrustAnchorDigest { get; }
    public ExactSha256Digest BindingDigest { get; }

    public static RuntimeQualificationBinding Create(
        string protocolVersion,
        string sourceCommit,
        ExactSha256Digest manifestDigest,
        ExactSha256Digest catalogDigest,
        ExactSha256Digest policyPackBindingDigest,
        ExactSha256Digest runtimeArtifactDigest,
        ExactSha256Digest trustAnchorDigest)
    {
        var version = ProtectedPolicyFrame.Text(protocolVersion, nameof(protocolVersion), 64);
        var source = ProtectedPolicyFrame.GitObjectId(sourceCommit, nameof(sourceCommit));
        foreach (var (digest, name) in new[]
                 {
                     (manifestDigest, nameof(manifestDigest)),
                     (catalogDigest, nameof(catalogDigest)),
                     (policyPackBindingDigest, nameof(policyPackBindingDigest)),
                     (runtimeArtifactDigest, nameof(runtimeArtifactDigest)),
                     (trustAnchorDigest, nameof(trustAnchorDigest)),
                 })
        {
            ProtectedPolicyFrame.RequireDigest(digest, name);
        }

        var binding = ProtectedPolicyFrame.Hash("protocol.runtime-qualification-binding/1\n", stream =>
        {
            ProtectedPolicyFrame.String(stream, version);
            ProtectedPolicyFrame.String(stream, source);
            ProtectedPolicyFrame.Digest(stream, manifestDigest);
            ProtectedPolicyFrame.Digest(stream, catalogDigest);
            ProtectedPolicyFrame.Digest(stream, policyPackBindingDigest);
            ProtectedPolicyFrame.Digest(stream, runtimeArtifactDigest);
            ProtectedPolicyFrame.Digest(stream, trustAnchorDigest);
        });
        return new RuntimeQualificationBinding(
            version, source, manifestDigest, catalogDigest, policyPackBindingDigest,
            runtimeArtifactDigest, trustAnchorDigest, binding);
    }
}

public sealed class PredecessorTrustPayload
{
    private PredecessorTrustPayload(
        RuntimeQualificationBinding predecessor,
        ExactSha256Digest currentTrustAnchorDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        long authorityEpoch,
        string overlapFixtureSetKey,
        string overlapFixtureSetVersion,
        ExactSha256Digest overlapFixtureSetDigest,
        ExactSha256Digest predecessorOverlapEvidenceSetDigest,
        ExactSha256Digest candidateOverlapEvidenceSetDigest,
        ExactSha256Digest predecessorOverlapOutcomeSetDigest,
        ExactSha256Digest expectedCandidateBindingDigest,
        ExactSha256Digest reviewedDifferenceSetDigest,
        string independentFixtureSetKey,
        string independentFixtureSetVersion,
        ExactSha256Digest independentFixtureSetDigest,
        ExactSha256Digest independentEvidenceSetDigest,
        ExactSha256Digest independentExpectedOutcomeSetDigest,
        ExactSha256Digest payloadDigest)
    {
        Predecessor = predecessor;
        CurrentTrustAnchorDigest = currentTrustAnchorDigest;
        ExpectedAuthorityRecordDigest = expectedAuthorityRecordDigest;
        AuthorityEpoch = authorityEpoch;
        OverlapFixtureSetKey = overlapFixtureSetKey;
        OverlapFixtureSetVersion = overlapFixtureSetVersion;
        OverlapFixtureSetDigest = overlapFixtureSetDigest;
        PredecessorOverlapEvidenceSetDigest = predecessorOverlapEvidenceSetDigest;
        CandidateOverlapEvidenceSetDigest = candidateOverlapEvidenceSetDigest;
        PredecessorOverlapOutcomeSetDigest = predecessorOverlapOutcomeSetDigest;
        ExpectedCandidateBindingDigest = expectedCandidateBindingDigest;
        ReviewedDifferenceSetDigest = reviewedDifferenceSetDigest;
        IndependentFixtureSetKey = independentFixtureSetKey;
        IndependentFixtureSetVersion = independentFixtureSetVersion;
        IndependentFixtureSetDigest = independentFixtureSetDigest;
        IndependentEvidenceSetDigest = independentEvidenceSetDigest;
        IndependentExpectedOutcomeSetDigest = independentExpectedOutcomeSetDigest;
        PayloadDigest = payloadDigest;
    }

    public RuntimeQualificationBinding Predecessor { get; }
    public ExactSha256Digest CurrentTrustAnchorDigest { get; }
    public ExactSha256Digest ExpectedAuthorityRecordDigest { get; }
    public long AuthorityEpoch { get; }
    public string OverlapFixtureSetKey { get; }
    public string OverlapFixtureSetVersion { get; }
    public ExactSha256Digest OverlapFixtureSetDigest { get; }
    public ExactSha256Digest PredecessorOverlapEvidenceSetDigest { get; }
    public ExactSha256Digest CandidateOverlapEvidenceSetDigest { get; }
    public ExactSha256Digest PredecessorOverlapOutcomeSetDigest { get; }
    public ExactSha256Digest ExpectedCandidateBindingDigest { get; }
    public ExactSha256Digest ReviewedDifferenceSetDigest { get; }
    public string IndependentFixtureSetKey { get; }
    public string IndependentFixtureSetVersion { get; }
    public ExactSha256Digest IndependentFixtureSetDigest { get; }
    public ExactSha256Digest IndependentEvidenceSetDigest { get; }
    public ExactSha256Digest IndependentExpectedOutcomeSetDigest { get; }
    public ExactSha256Digest PayloadDigest { get; }

    public static PredecessorTrustPayload Create(
        RuntimeQualificationBinding predecessor,
        ExactSha256Digest currentTrustAnchorDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        long authorityEpoch,
        string overlapFixtureSetKey,
        string overlapFixtureSetVersion,
        ExactSha256Digest overlapFixtureSetDigest,
        ExactSha256Digest predecessorOverlapEvidenceSetDigest,
        ExactSha256Digest candidateOverlapEvidenceSetDigest,
        ExactSha256Digest predecessorOverlapOutcomeSetDigest,
        ExactSha256Digest expectedCandidateBindingDigest,
        ExactSha256Digest reviewedDifferenceSetDigest,
        string independentFixtureSetKey,
        string independentFixtureSetVersion,
        ExactSha256Digest independentFixtureSetDigest,
        ExactSha256Digest independentEvidenceSetDigest,
        ExactSha256Digest independentExpectedOutcomeSetDigest)
    {
        ArgumentNullException.ThrowIfNull(predecessor);
        foreach (var (digest, name) in new[]
                 {
                     (currentTrustAnchorDigest, nameof(currentTrustAnchorDigest)),
                     (expectedAuthorityRecordDigest, nameof(expectedAuthorityRecordDigest)),
                     (overlapFixtureSetDigest, nameof(overlapFixtureSetDigest)),
                     (predecessorOverlapEvidenceSetDigest, nameof(predecessorOverlapEvidenceSetDigest)),
                     (candidateOverlapEvidenceSetDigest, nameof(candidateOverlapEvidenceSetDigest)),
                     (predecessorOverlapOutcomeSetDigest, nameof(predecessorOverlapOutcomeSetDigest)),
                     (expectedCandidateBindingDigest, nameof(expectedCandidateBindingDigest)),
                     (reviewedDifferenceSetDigest, nameof(reviewedDifferenceSetDigest)),
                     (independentFixtureSetDigest, nameof(independentFixtureSetDigest)),
                     (independentEvidenceSetDigest, nameof(independentEvidenceSetDigest)),
                     (independentExpectedOutcomeSetDigest, nameof(independentExpectedOutcomeSetDigest)),
                 })
        {
            ProtectedPolicyFrame.RequireDigest(digest, name);
        }
        if (authorityEpoch <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(authorityEpoch));
        }

        var overlapKey = ProtectedPolicyFrame.Text(overlapFixtureSetKey, nameof(overlapFixtureSetKey), 128);
        var overlapVersion = ProtectedPolicyFrame.Text(overlapFixtureSetVersion, nameof(overlapFixtureSetVersion), 32);
        var independentKey = ProtectedPolicyFrame.Text(independentFixtureSetKey, nameof(independentFixtureSetKey), 128);
        var independentVersion = ProtectedPolicyFrame.Text(independentFixtureSetVersion, nameof(independentFixtureSetVersion), 32);
        var digestValue = ProtectedPolicyFrame.Hash("protocol.predecessor-trust-payload/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, predecessor.BindingDigest);
            ProtectedPolicyFrame.Digest(stream, currentTrustAnchorDigest);
            ProtectedPolicyFrame.Digest(stream, expectedAuthorityRecordDigest);
            ProtectedPolicyFrame.Int64(stream, authorityEpoch);
            ProtectedPolicyFrame.String(stream, overlapKey);
            ProtectedPolicyFrame.String(stream, overlapVersion);
            ProtectedPolicyFrame.Digest(stream, overlapFixtureSetDigest);
            ProtectedPolicyFrame.Digest(stream, predecessorOverlapEvidenceSetDigest);
            ProtectedPolicyFrame.Digest(stream, candidateOverlapEvidenceSetDigest);
            ProtectedPolicyFrame.Digest(stream, predecessorOverlapOutcomeSetDigest);
            ProtectedPolicyFrame.Digest(stream, expectedCandidateBindingDigest);
            ProtectedPolicyFrame.Digest(stream, reviewedDifferenceSetDigest);
            ProtectedPolicyFrame.String(stream, independentKey);
            ProtectedPolicyFrame.String(stream, independentVersion);
            ProtectedPolicyFrame.Digest(stream, independentFixtureSetDigest);
            ProtectedPolicyFrame.Digest(stream, independentEvidenceSetDigest);
            ProtectedPolicyFrame.Digest(stream, independentExpectedOutcomeSetDigest);
        });
        return new PredecessorTrustPayload(
            predecessor, currentTrustAnchorDigest, expectedAuthorityRecordDigest,
            authorityEpoch, overlapKey, overlapVersion, overlapFixtureSetDigest,
            predecessorOverlapEvidenceSetDigest, candidateOverlapEvidenceSetDigest,
            predecessorOverlapOutcomeSetDigest, expectedCandidateBindingDigest,
            reviewedDifferenceSetDigest, independentKey, independentVersion,
            independentFixtureSetDigest, independentEvidenceSetDigest,
            independentExpectedOutcomeSetDigest, digestValue);
    }
}

public sealed class PredecessorTrustBinding
{
    private PredecessorTrustBinding(
        PredecessorTrustPayload payload,
        ExactSha256Digest authorityRecordDigest,
        ExactSha256Digest authorityEnvelopeDigest,
        ExactSha256Digest bindingDigest)
    {
        Payload = payload;
        AuthorityRecordDigest = authorityRecordDigest;
        AuthorityEnvelopeDigest = authorityEnvelopeDigest;
        BindingDigest = bindingDigest;
    }

    public PredecessorTrustPayload Payload { get; }
    public ExactSha256Digest AuthorityRecordDigest { get; }
    public ExactSha256Digest AuthorityEnvelopeDigest { get; }
    public ExactSha256Digest BindingDigest { get; }

    internal static PredecessorTrustBinding Create(
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof)
    {
        ArgumentNullException.ThrowIfNull(payload);
        ArgumentNullException.ThrowIfNull(proof);
        if (!payload.PayloadDigest.Equals(proof.PayloadDigest) ||
            !payload.ExpectedAuthorityRecordDigest.Equals(proof.AuthorityRecordDigest) ||
            payload.AuthorityEpoch != proof.AuthorityEpoch)
        {
            throw new ArgumentException("The predecessor proof does not match its payload.", nameof(proof));
        }

        var digest = ProtectedPolicyFrame.Hash("protocol.predecessor-trust-binding/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, payload.PayloadDigest);
            ProtectedPolicyFrame.Digest(stream, proof.EnvelopeDigest);
            ProtectedPolicyFrame.Digest(stream, proof.AuthorityRecordDigest);
        });
        return new PredecessorTrustBinding(
            payload, proof.AuthorityRecordDigest, proof.EnvelopeDigest, digest);
    }
}

public interface IPredecessorTrustVerifier
{
    bool Verify(
        PredecessorTrustPayload payload,
        ProtectedAuthorityEnvelope proof);
}

public sealed class ProtectedOutcomeKind : IEquatable<ProtectedOutcomeKind>
{
    public static ProtectedOutcomeKind Rule { get; } = new("rule");
    public static ProtectedOutcomeKind Dispositions { get; } = new("dispositions");
    public static ProtectedOutcomeKind Verdict { get; } = new("verdict");
    public static ProtectedOutcomeKind Enforcement { get; } = new("enforcement");

    private ProtectedOutcomeKind(string value) => Value = value;

    public string Value { get; }

    public static ProtectedOutcomeKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return TryParse(value, out var result)
            ? result
            : throw new FormatException("The value is not a protected outcome kind.");
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ProtectedOutcomeKind? result)
    {
        result = value switch
        {
            "rule" => Rule,
            "dispositions" => Dispositions,
            "verdict" => Verdict,
            "enforcement" => Enforcement,
            _ => null,
        };
        return result is not null;
    }

    public bool Equals(ProtectedOutcomeKind? other) =>
        other is not null && string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as ProtectedOutcomeKind);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public override string ToString() => Value;
}

public sealed class ProtectedOutcomeIdentity
{
    private ProtectedOutcomeIdentity(ProtectedOutcomeKind kind, PolicyRuleIdentity? rule)
    {
        Kind = kind;
        Rule = rule;
    }

    public ProtectedOutcomeKind Kind { get; }
    public PolicyRuleIdentity? Rule { get; }

    public static ProtectedOutcomeIdentity ForRule(PolicyRuleIdentity rule)
    {
        ArgumentNullException.ThrowIfNull(rule);
        return new ProtectedOutcomeIdentity(ProtectedOutcomeKind.Rule, rule);
    }

    public static ProtectedOutcomeIdentity Global(ProtectedOutcomeKind kind)
    {
        ArgumentNullException.ThrowIfNull(kind);
        if (kind.Equals(ProtectedOutcomeKind.Rule))
        {
            throw new ArgumentException("A global outcome cannot use the rule kind.", nameof(kind));
        }

        return new ProtectedOutcomeIdentity(kind, null);
    }

    internal string RowKey => Rule is null
        ? $"global:{Kind.Value}"
        : $"rule:{Rule.CanonicalKey}";
}

public sealed class ReviewedOutcomeDifference
{
    private ReviewedOutcomeDifference(
        ProtectedOutcomeIdentity outcome,
        ExactSha256Digest predecessorOutcomeDigest,
        ExactSha256Digest candidateOutcomeDigest,
        ReviewedAuthorityPermalink changeAuthority,
        ExactSha256Digest qualificationEvidenceDigest)
    {
        Outcome = outcome;
        PredecessorOutcomeDigest = predecessorOutcomeDigest;
        CandidateOutcomeDigest = candidateOutcomeDigest;
        ChangeAuthority = changeAuthority;
        QualificationEvidenceDigest = qualificationEvidenceDigest;
    }

    public ProtectedOutcomeIdentity Outcome { get; }
    public ExactSha256Digest PredecessorOutcomeDigest { get; }
    public ExactSha256Digest CandidateOutcomeDigest { get; }
    public ReviewedAuthorityPermalink ChangeAuthority { get; }
    public ExactSha256Digest QualificationEvidenceDigest { get; }

    public static ReviewedOutcomeDifference Create(
        ProtectedOutcomeIdentity outcome,
        ExactSha256Digest predecessorOutcomeDigest,
        ExactSha256Digest candidateOutcomeDigest,
        ReviewedAuthorityPermalink changeAuthority,
        ExactSha256Digest qualificationEvidenceDigest)
    {
        ArgumentNullException.ThrowIfNull(outcome);
        ProtectedPolicyFrame.RequireDigest(predecessorOutcomeDigest, nameof(predecessorOutcomeDigest));
        ProtectedPolicyFrame.RequireDigest(candidateOutcomeDigest, nameof(candidateOutcomeDigest));
        if (predecessorOutcomeDigest.Equals(candidateOutcomeDigest))
        {
            throw new ArgumentException("A reviewed difference must contain distinct outcome digests.");
        }
        ArgumentNullException.ThrowIfNull(changeAuthority);
        ProtectedPolicyFrame.RequireDigest(qualificationEvidenceDigest, nameof(qualificationEvidenceDigest));
        return new ReviewedOutcomeDifference(
            outcome, predecessorOutcomeDigest, candidateOutcomeDigest,
            changeAuthority, qualificationEvidenceDigest);
    }
}
