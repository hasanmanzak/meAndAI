using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class PolicyRuleIdentity
{
    private PolicyRuleIdentity(
        RuleId? baselineRuleId,
        ExtensionId? extensionId,
        RuleRevision revision)
    {
        BaselineRuleId = baselineRuleId;
        ExtensionId = extensionId;
        Revision = revision;
    }

    public RuleId? BaselineRuleId { get; }
    public ExtensionId? ExtensionId { get; }
    public RuleRevision Revision { get; }

    public static PolicyRuleIdentity Baseline(RuleId ruleId, RuleRevision revision)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(revision);
        return new PolicyRuleIdentity(ruleId, null, revision);
    }

    public static PolicyRuleIdentity Extension(ExtensionId extensionId, RuleRevision revision)
    {
        ArgumentNullException.ThrowIfNull(extensionId);
        ArgumentNullException.ThrowIfNull(revision);
        return new PolicyRuleIdentity(null, extensionId, revision);
    }

    internal string CanonicalKey => BaselineRuleId is not null
        ? $"baseline:{BaselineRuleId.Value}:{Revision.Value}"
        : $"extension:{ExtensionId!.Value}:{Revision.Value}";

    internal void Write(MemoryStream stream)
    {
        var baseline = BaselineRuleId is not null;
        stream.WriteByte(baseline ? (byte)0 : (byte)1);
        ProtectedPolicyFrame.String(stream, baseline ? BaselineRuleId!.Value : ExtensionId!.Value);
        ProtectedPolicyFrame.UInt32(stream, checked((uint)Revision.Value));
    }
}

public sealed class StableFindingKey
{
    private StableFindingKey(ExactSha256Digest value) => Value = value;

    public ExactSha256Digest Value { get; }

    public static StableFindingKey Create(
        PolicyRuleIdentity rule,
        FindingCode findingCode,
        ExactSha256Digest locationDigest,
        ExactSha256Digest evidenceDigest,
        ExactSha256Digest expectedValueDigest)
    {
        ArgumentNullException.ThrowIfNull(rule);
        ArgumentNullException.ThrowIfNull(findingCode);
        ProtectedPolicyFrame.RequireDigest(locationDigest, nameof(locationDigest));
        ProtectedPolicyFrame.RequireDigest(evidenceDigest, nameof(evidenceDigest));
        ProtectedPolicyFrame.RequireDigest(expectedValueDigest, nameof(expectedValueDigest));
        var value = ProtectedPolicyFrame.Hash("protocol.stable-finding-key/1\n", stream =>
        {
            rule.Write(stream);
            ProtectedPolicyFrame.String(stream, findingCode.Value);
            ProtectedPolicyFrame.Digest(stream, locationDigest);
            ProtectedPolicyFrame.Digest(stream, evidenceDigest);
            ProtectedPolicyFrame.Digest(stream, expectedValueDigest);
        });
        return new StableFindingKey(value);
    }
}

public sealed class WaiverTargetSelector
{
    private WaiverTargetSelector(string value) => Value = value;

    public string Value { get; }

    public static WaiverTargetSelector Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (value.StartsWith("evidence:", StringComparison.Ordinal) &&
            ExactSha256Digest.TryParse(value[9..], out _))
        {
            return new WaiverTargetSelector(value);
        }

        if (value.StartsWith("repository:", StringComparison.Ordinal) &&
            IsNormalizedPath(value[11..]))
        {
            return new WaiverTargetSelector(value);
        }

        throw new FormatException("The value is not a waiver target selector.");
    }

    private static bool IsNormalizedPath(string value)
    {
        if (value.Length == 0 ||
            !ProtectedPolicyFrame.TryUtf8ByteCount(value, out var byteCount) || byteCount > 4096 ||
            value.StartsWith('/') || value.EndsWith('/') || value.Contains('\\') ||
            value.Contains("//", StringComparison.Ordinal) ||
            value.Any(static character => character == '\0' || char.IsControl(character)))
        {
            return false;
        }

        var segments = value.Split('/');
        return !(segments[0].Length >= 2 &&
                 IsAsciiLetter(segments[0][0]) &&
                 segments[0][1] == ':') &&
               segments.All(static segment =>
                   segment.Length > 0 && segment is not "." and not "..");
    }

    private static bool IsAsciiLetter(char value) =>
        value is (>= 'A' and <= 'Z') or (>= 'a' and <= 'z');
}

public sealed class WaiverScope
{
    private WaiverScope(string value) => Value = value;

    public string Value { get; }

    public static WaiverScope Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return value is "finding" or "path" or "repository"
            ? new WaiverScope(value)
            : throw new FormatException("The value is not a waiver scope.");
    }
}

public sealed class ProtectedFindingIdentity
{
    private ProtectedFindingIdentity(
        PolicyRuleIdentity rule,
        FindingCode findingCode,
        ExactSha256Digest locationDigest,
        ExactSha256Digest evidenceDigest,
        ExactSha256Digest expectedValueDigest,
        StableFindingKey stableKey)
    {
        Rule = rule;
        FindingCode = findingCode;
        LocationDigest = locationDigest;
        EvidenceDigest = evidenceDigest;
        ExpectedValueDigest = expectedValueDigest;
        StableKey = stableKey;
    }

    public PolicyRuleIdentity Rule { get; }
    public FindingCode FindingCode { get; }
    public ExactSha256Digest LocationDigest { get; }
    public ExactSha256Digest EvidenceDigest { get; }
    public ExactSha256Digest ExpectedValueDigest { get; }
    public StableFindingKey StableKey { get; }

    public static ProtectedFindingIdentity Create(
        PolicyRuleIdentity rule,
        FindingCode findingCode,
        ExactSha256Digest locationDigest,
        ExactSha256Digest evidenceDigest,
        ExactSha256Digest expectedValueDigest,
        StableFindingKey stableKey)
    {
        ArgumentNullException.ThrowIfNull(rule);
        ArgumentNullException.ThrowIfNull(findingCode);
        ArgumentNullException.ThrowIfNull(stableKey);
        var computed = StableFindingKey.Create(
            rule, findingCode, locationDigest, evidenceDigest, expectedValueDigest);
        if (!computed.Value.Equals(stableKey.Value))
        {
            throw new ArgumentException("The stable key does not match the protected finding.", nameof(stableKey));
        }

        return new ProtectedFindingIdentity(
            rule, findingCode, locationDigest, evidenceDigest, expectedValueDigest, computed);
    }

    internal void Write(MemoryStream stream)
    {
        Rule.Write(stream);
        ProtectedPolicyFrame.String(stream, FindingCode.Value);
        ProtectedPolicyFrame.Digest(stream, LocationDigest);
        ProtectedPolicyFrame.Digest(stream, EvidenceDigest);
        ProtectedPolicyFrame.Digest(stream, ExpectedValueDigest);
        ProtectedPolicyFrame.Digest(stream, StableKey.Value);
    }
}

public sealed class WaiverDeclaration
{
    private WaiverDeclaration(
        ProtectedFindingIdentity finding,
        WaiverTargetSelector targetSelector,
        WaiverScope scope,
        string rationale,
        string owner,
        ReviewedAuthorityPermalink decisionAuthority,
        ExactSha256Digest trustedBaseAuthorityDigest,
        DateTimeOffset createdUtc,
        DateTimeOffset expiresUtc,
        ExactSha256Digest evidenceDigest,
        ExactSha256Digest declarationDigest,
        long canonicalFrameLength)
    {
        Finding = finding;
        TargetSelector = targetSelector;
        Scope = scope;
        Rationale = rationale;
        Owner = owner;
        DecisionAuthority = decisionAuthority;
        TrustedBaseAuthorityDigest = trustedBaseAuthorityDigest;
        CreatedUtc = createdUtc;
        ExpiresUtc = expiresUtc;
        EvidenceDigest = evidenceDigest;
        DeclarationDigest = declarationDigest;
        CanonicalFrameLength = canonicalFrameLength;
    }

    public ProtectedFindingIdentity Finding { get; }
    public WaiverTargetSelector TargetSelector { get; }
    public WaiverScope Scope { get; }
    public string Rationale { get; }
    public string Owner { get; }
    public ReviewedAuthorityPermalink DecisionAuthority { get; }
    public ExactSha256Digest TrustedBaseAuthorityDigest { get; }
    public DateTimeOffset CreatedUtc { get; }
    public DateTimeOffset ExpiresUtc { get; }
    public ExactSha256Digest EvidenceDigest { get; }
    public ExactSha256Digest DeclarationDigest { get; }
    internal long CanonicalFrameLength { get; }

    public static WaiverDeclaration Create(
        ProtectedFindingIdentity finding,
        WaiverTargetSelector targetSelector,
        WaiverScope scope,
        string rationale,
        string owner,
        ReviewedAuthorityPermalink decisionAuthority,
        ExactSha256Digest trustedBaseAuthorityDigest,
        DateTimeOffset createdUtc,
        DateTimeOffset expiresUtc,
        ExactSha256Digest evidenceDigest)
    {
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(targetSelector);
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(decisionAuthority);
        var rationaleValue = ProtectedPolicyFrame.Text(rationale, nameof(rationale), 4096);
        var ownerValue = ProtectedPolicyFrame.Text(owner, nameof(owner), 256);
        ProtectedPolicyFrame.RequireDigest(trustedBaseAuthorityDigest, nameof(trustedBaseAuthorityDigest));
        ProtectedPolicyFrame.RequireDigest(evidenceDigest, nameof(evidenceDigest));
        ValidateUtc(createdUtc, nameof(createdUtc));
        ValidateUtc(expiresUtc, nameof(expiresUtc));
        if (createdUtc >= expiresUtc)
        {
            throw new ArgumentException("A waiver must expire after it is created.", nameof(expiresUtc));
        }

        ValidateScope(scope, targetSelector, finding);
        var frame = ProtectedPolicyFrame.HashWithLength("protocol.waiver-declaration/1\n", stream =>
        {
            finding.Write(stream);
            ProtectedPolicyFrame.String(stream, targetSelector.Value);
            ProtectedPolicyFrame.String(stream, scope.Value);
            ProtectedPolicyFrame.String(stream, rationaleValue);
            ProtectedPolicyFrame.String(stream, ownerValue);
            ProtectedPolicyFrame.String(stream, decisionAuthority.Value);
            ProtectedPolicyFrame.Digest(stream, trustedBaseAuthorityDigest);
            ProtectedPolicyFrame.Int64(stream, createdUtc.Ticks);
            ProtectedPolicyFrame.Int64(stream, expiresUtc.Ticks);
            ProtectedPolicyFrame.Digest(stream, evidenceDigest);
        });
        return new WaiverDeclaration(
            finding, targetSelector, scope, rationaleValue, ownerValue,
            decisionAuthority, trustedBaseAuthorityDigest, createdUtc, expiresUtc,
            evidenceDigest, frame.Digest, frame.ByteLength);
    }

    private static void ValidateScope(
        WaiverScope scope,
        WaiverTargetSelector target,
        ProtectedFindingIdentity finding)
    {
        if (scope.Value == "finding")
        {
            if (!string.Equals(target.Value, $"evidence:{finding.EvidenceDigest.Value}", StringComparison.Ordinal))
            {
                throw new ArgumentException("Finding scope requires the exact evidence digest.", nameof(target));
            }
        }
        else if ((scope.Value == "path" &&
                  !target.Value.StartsWith("repository:", StringComparison.Ordinal)) ||
                 (scope.Value == "repository" &&
                  !target.Value.StartsWith("evidence:", StringComparison.Ordinal)))
        {
            throw new ArgumentException("The waiver scope and selector are incompatible.", nameof(target));
        }
    }

    internal static void ValidateUtc(DateTimeOffset value, string paramName)
    {
        if (value.Offset != TimeSpan.Zero)
        {
            throw new ArgumentException("The timestamp must use a zero UTC offset.", paramName);
        }
    }
}

public sealed class BaselineRuleWaiverPolicy
{
    private BaselineRuleWaiverPolicy(
        RuleId ruleId,
        RuleRevision ruleRevision,
        bool waiverAllowed)
    {
        RuleId = ruleId;
        RuleRevision = ruleRevision;
        WaiverAllowed = waiverAllowed;
    }

    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public bool WaiverAllowed { get; }

    public static BaselineRuleWaiverPolicy Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        bool waiverAllowed)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(ruleRevision);
        return new BaselineRuleWaiverPolicy(ruleId, ruleRevision, waiverAllowed);
    }
}

public sealed class BaselineWaiverPolicySnapshot
{
    private BaselineWaiverPolicySnapshot(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest snapshotDigest,
        IReadOnlyList<BaselineRuleWaiverPolicy> rules)
    {
        ManifestDigest = manifestDigest;
        SnapshotDigest = snapshotDigest;
        Rules = rules;
    }

    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<BaselineRuleWaiverPolicy> Rules { get; }

    public static BaselineWaiverPolicySnapshot Create(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest snapshotDigest,
        IEnumerable<BaselineRuleWaiverPolicy> rules)
    {
        ProtectedPolicyFrame.RequireDigest(manifestDigest, nameof(manifestDigest));
        ProtectedPolicyFrame.RequireDigest(snapshotDigest, nameof(snapshotDigest));
        var rows = ProtectedPolicyFrame.SortedUnique(
            rules, static row => row.RuleId.Value, nameof(rules));
        var computed = ProtectedPolicyFrame.Hash("protocol.baseline-waiver-policy/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, manifestDigest);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Count));
            foreach (var row in rows)
            {
                ProtectedPolicyFrame.String(stream, row.RuleId.Value);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)row.RuleRevision.Value));
                ProtectedPolicyFrame.Bool(stream, row.WaiverAllowed);
            }
        });
        if (!computed.Equals(snapshotDigest))
        {
            throw new ArgumentException("The baseline waiver policy digest does not match.", nameof(snapshotDigest));
        }

        return new BaselineWaiverPolicySnapshot(manifestDigest, computed, rows);
    }
}

public sealed class HistoricalDebtEntry
{
    private HistoricalDebtEntry(
        ProtectedFindingIdentity finding,
        string protocolVersion,
        string accountableOwner,
        ReviewedAuthorityPermalink authority,
        string reviewCondition,
        ExactSha256Digest stableEvidenceDigest,
        ExactSha256Digest recurrenceRecordDigest,
        DateTimeOffset? closedUtc,
        DateTimeOffset? expiresUtc,
        ExactSha256Digest trustedBaseAuthorityDigest,
        ExactSha256Digest entryDigest,
        long canonicalFrameLength)
    {
        Finding = finding;
        ProtocolVersion = protocolVersion;
        AccountableOwner = accountableOwner;
        Authority = authority;
        ReviewCondition = reviewCondition;
        StableEvidenceDigest = stableEvidenceDigest;
        RecurrenceRecordDigest = recurrenceRecordDigest;
        ClosedUtc = closedUtc;
        ExpiresUtc = expiresUtc;
        TrustedBaseAuthorityDigest = trustedBaseAuthorityDigest;
        EntryDigest = entryDigest;
        CanonicalFrameLength = canonicalFrameLength;
    }

    public ProtectedFindingIdentity Finding { get; }
    public string ProtocolVersion { get; }
    public string AccountableOwner { get; }
    public ReviewedAuthorityPermalink Authority { get; }
    public string ReviewCondition { get; }
    public ExactSha256Digest StableEvidenceDigest { get; }
    public ExactSha256Digest RecurrenceRecordDigest { get; }
    public DateTimeOffset? ClosedUtc { get; }
    public DateTimeOffset? ExpiresUtc { get; }
    public ExactSha256Digest TrustedBaseAuthorityDigest { get; }
    public ExactSha256Digest EntryDigest { get; }
    internal long CanonicalFrameLength { get; }

    public static HistoricalDebtEntry Create(
        ProtectedFindingIdentity finding,
        string protocolVersion,
        string accountableOwner,
        ReviewedAuthorityPermalink authority,
        string reviewCondition,
        ExactSha256Digest stableEvidenceDigest,
        ExactSha256Digest recurrenceRecordDigest,
        DateTimeOffset? closedUtc,
        DateTimeOffset? expiresUtc,
        ExactSha256Digest trustedBaseAuthorityDigest)
    {
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(authority);
        var version = ProtectedPolicyFrame.Text(protocolVersion, nameof(protocolVersion), 64);
        var owner = ProtectedPolicyFrame.Text(accountableOwner, nameof(accountableOwner), 256);
        var condition = ProtectedPolicyFrame.Text(reviewCondition, nameof(reviewCondition), 4096);
        ProtectedPolicyFrame.RequireDigest(stableEvidenceDigest, nameof(stableEvidenceDigest));
        ProtectedPolicyFrame.RequireDigest(recurrenceRecordDigest, nameof(recurrenceRecordDigest));
        ProtectedPolicyFrame.RequireDigest(trustedBaseAuthorityDigest, nameof(trustedBaseAuthorityDigest));
        if (closedUtc.HasValue)
        {
            WaiverDeclaration.ValidateUtc(closedUtc.Value, nameof(closedUtc));
        }
        if (expiresUtc.HasValue)
        {
            WaiverDeclaration.ValidateUtc(expiresUtc.Value, nameof(expiresUtc));
        }

        var frame = ProtectedPolicyFrame.HashWithLength("protocol.historical-debt-entry/1\n", stream =>
        {
            finding.Write(stream);
            ProtectedPolicyFrame.String(stream, version);
            ProtectedPolicyFrame.String(stream, owner);
            ProtectedPolicyFrame.String(stream, authority.Value);
            ProtectedPolicyFrame.String(stream, condition);
            ProtectedPolicyFrame.Digest(stream, stableEvidenceDigest);
            ProtectedPolicyFrame.Digest(stream, recurrenceRecordDigest);
            ProtectedPolicyFrame.OptionalTicks(stream, closedUtc);
            ProtectedPolicyFrame.OptionalTicks(stream, expiresUtc);
            ProtectedPolicyFrame.Digest(stream, trustedBaseAuthorityDigest);
        });
        return new HistoricalDebtEntry(
            finding, version, owner, authority, condition, stableEvidenceDigest,
            recurrenceRecordDigest, closedUtc, expiresUtc, trustedBaseAuthorityDigest,
            frame.Digest, frame.ByteLength);
    }
}

public sealed class WaiverSnapshot
{
    internal const int MaximumSnapshotCount = 100_000;
    internal const long MaximumCanonicalFrameBytes = 67_108_864;

    private WaiverSnapshot(
        ExactSha256Digest snapshotDigest,
        IReadOnlyList<WaiverDeclaration> waivers)
    {
        SnapshotDigest = snapshotDigest;
        Waivers = waivers;
    }

    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<WaiverDeclaration> Waivers { get; }

    public static WaiverSnapshot Create(
        ExactSha256Digest snapshotDigest,
        IEnumerable<WaiverDeclaration> waivers)
    {
        ProtectedPolicyFrame.RequireDigest(snapshotDigest, nameof(snapshotDigest));
        const string separator = "protocol.waiver-snapshot/1\n";
        var completeFrameBytes = BeginCompleteSnapshotFrame(separator);
        var rows = ProtectedPolicyFrame.SortedUnique(
            waivers, static row => row.Finding.StableKey.Value.Value,
            nameof(waivers), MaximumSnapshotCount,
            beforeRetain: row => completeFrameBytes = AddCompleteSnapshotRow(
                completeFrameBytes,
                row.CanonicalFrameLength,
                nameof(waivers)));
        var computed = Snapshot(separator, rows.Select(static row => row.DeclarationDigest).ToArray());
        if (!computed.Equals(snapshotDigest))
        {
            throw new ArgumentException("The waiver snapshot digest does not match.", nameof(snapshotDigest));
        }

        return new WaiverSnapshot(computed, rows);
    }

    internal static ExactSha256Digest Snapshot(string separator, IReadOnlyList<ExactSha256Digest> digests) =>
        ProtectedPolicyFrame.Hash(separator, stream =>
        {
            ValidateSnapshotFrameLength(separator, digests.Count, nameof(digests));
            ProtectedPolicyFrame.UInt32(stream, checked((uint)digests.Count));
            foreach (var digest in digests)
            {
                ProtectedPolicyFrame.Digest(stream, digest);
            }
        });

    internal static long ValidateSnapshotFrameLength(
        string separator,
        int count,
        string paramName)
    {
        if (count < 0 || count > MaximumSnapshotCount)
        {
            throw new ArgumentOutOfRangeException(paramName);
        }

        var byteLength = checked(
            (long)System.Text.Encoding.ASCII.GetByteCount(separator) +
            sizeof(uint) +
            (32L * count));
        if (byteLength > MaximumCanonicalFrameBytes)
        {
            throw new ArgumentOutOfRangeException(paramName);
        }

        return byteLength;
    }

    internal static long BeginCompleteSnapshotFrame(string separator) =>
        checked((long)System.Text.Encoding.ASCII.GetByteCount(separator) + sizeof(uint));

    internal static long AddCompleteSnapshotRow(
        long currentByteLength,
        long canonicalRowFrameLength,
        string paramName)
    {
        const long RawDigestBytes = 32;
        if (currentByteLength < 0 || canonicalRowFrameLength < 0 ||
            canonicalRowFrameLength > MaximumCanonicalFrameBytes - RawDigestBytes ||
            currentByteLength >
            MaximumCanonicalFrameBytes - RawDigestBytes - canonicalRowFrameLength)
        {
            throw new ArgumentException(
                "The complete canonical snapshot frame exceeds its aggregate byte bound.",
                paramName);
        }

        return currentByteLength + RawDigestBytes + canonicalRowFrameLength;
    }
}

public sealed class HistoricalDebtSnapshot
{
    private HistoricalDebtSnapshot(
        ExactSha256Digest snapshotDigest,
        IReadOnlyList<HistoricalDebtEntry> entries)
    {
        SnapshotDigest = snapshotDigest;
        Entries = entries;
    }

    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<HistoricalDebtEntry> Entries { get; }

    public static HistoricalDebtSnapshot Create(
        ExactSha256Digest snapshotDigest,
        IEnumerable<HistoricalDebtEntry> entries)
    {
        ProtectedPolicyFrame.RequireDigest(snapshotDigest, nameof(snapshotDigest));
        const string separator = "protocol.historical-debt-snapshot/1\n";
        var completeFrameBytes = WaiverSnapshot.BeginCompleteSnapshotFrame(separator);
        var rows = ProtectedPolicyFrame.SortedUnique(
            entries, static row => row.Finding.StableKey.Value.Value,
            nameof(entries), WaiverSnapshot.MaximumSnapshotCount,
            beforeRetain: row => completeFrameBytes = WaiverSnapshot.AddCompleteSnapshotRow(
                completeFrameBytes,
                row.CanonicalFrameLength,
                nameof(entries)));
        var computed = WaiverSnapshot.Snapshot(
            separator,
            rows.Select(static row => row.EntryDigest).ToArray());
        if (!computed.Equals(snapshotDigest))
        {
            throw new ArgumentException("The debt snapshot digest does not match.", nameof(snapshotDigest));
        }

        return new HistoricalDebtSnapshot(computed, rows);
    }
}

public sealed class ProtectedDispositionAuthorityPayload
{
    private ProtectedDispositionAuthorityPayload(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest trustedBaseAuthorityDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest waiverSnapshotDigest,
        ExactSha256Digest debtSnapshotDigest,
        ExactSha256Digest evidenceSetDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        long authorityEpoch,
        DateTimeOffset evaluationUtc,
        ExactSha256Digest payloadDigest)
    {
        ManifestDigest = manifestDigest;
        TrustedBaseAuthorityDigest = trustedBaseAuthorityDigest;
        AuthoritySetDigest = authoritySetDigest;
        WaiverSnapshotDigest = waiverSnapshotDigest;
        DebtSnapshotDigest = debtSnapshotDigest;
        EvidenceSetDigest = evidenceSetDigest;
        ExpectedAuthorityRecordDigest = expectedAuthorityRecordDigest;
        AuthorityEpoch = authorityEpoch;
        EvaluationUtc = evaluationUtc;
        PayloadDigest = payloadDigest;
    }

    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest TrustedBaseAuthorityDigest { get; }
    public ExactSha256Digest AuthoritySetDigest { get; }
    public ExactSha256Digest WaiverSnapshotDigest { get; }
    public ExactSha256Digest DebtSnapshotDigest { get; }
    public ExactSha256Digest EvidenceSetDigest { get; }
    public ExactSha256Digest ExpectedAuthorityRecordDigest { get; }
    public long AuthorityEpoch { get; }
    public DateTimeOffset EvaluationUtc { get; }
    public ExactSha256Digest PayloadDigest { get; }

    public static ProtectedDispositionAuthorityPayload Create(
        ExactSha256Digest manifestDigest,
        ExactSha256Digest trustedBaseAuthorityDigest,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest waiverSnapshotDigest,
        ExactSha256Digest debtSnapshotDigest,
        ExactSha256Digest evidenceSetDigest,
        ExactSha256Digest expectedAuthorityRecordDigest,
        long authorityEpoch,
        DateTimeOffset evaluationUtc)
    {
        foreach (var (candidateDigest, name) in new[]
                 {
                     (manifestDigest, nameof(manifestDigest)),
                     (trustedBaseAuthorityDigest, nameof(trustedBaseAuthorityDigest)),
                     (authoritySetDigest, nameof(authoritySetDigest)),
                     (waiverSnapshotDigest, nameof(waiverSnapshotDigest)),
                     (debtSnapshotDigest, nameof(debtSnapshotDigest)),
                     (evidenceSetDigest, nameof(evidenceSetDigest)),
                     (expectedAuthorityRecordDigest, nameof(expectedAuthorityRecordDigest)),
                 })
        {
            ProtectedPolicyFrame.RequireDigest(candidateDigest, name);
        }

        if (!manifestDigest.Equals(trustedBaseAuthorityDigest))
        {
            throw new ArgumentException("Trusted base authority is the raw manifest digest.", nameof(trustedBaseAuthorityDigest));
        }
        if (authorityEpoch <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(authorityEpoch));
        }
        WaiverDeclaration.ValidateUtc(evaluationUtc, nameof(evaluationUtc));
        var digest = ProtectedPolicyFrame.Hash("protocol.protected-disposition-authority-payload/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, manifestDigest);
            ProtectedPolicyFrame.Digest(stream, trustedBaseAuthorityDigest);
            ProtectedPolicyFrame.Digest(stream, authoritySetDigest);
            ProtectedPolicyFrame.Digest(stream, waiverSnapshotDigest);
            ProtectedPolicyFrame.Digest(stream, debtSnapshotDigest);
            ProtectedPolicyFrame.Digest(stream, evidenceSetDigest);
            ProtectedPolicyFrame.Digest(stream, expectedAuthorityRecordDigest);
            ProtectedPolicyFrame.Int64(stream, authorityEpoch);
            ProtectedPolicyFrame.Int64(stream, evaluationUtc.Ticks);
        });
        return new ProtectedDispositionAuthorityPayload(
            manifestDigest, trustedBaseAuthorityDigest, authoritySetDigest,
            waiverSnapshotDigest, debtSnapshotDigest, evidenceSetDigest,
            expectedAuthorityRecordDigest, authorityEpoch, evaluationUtc, digest);
    }
}

public sealed class ProtectedDispositionAuthority
{
    private ProtectedDispositionAuthority(
        ProtectedDispositionAuthorityPayload payload,
        ExactSha256Digest authorityRecordDigest,
        ExactSha256Digest authorityEnvelopeDigest,
        ExactSha256Digest bindingDigest)
    {
        Payload = payload;
        AuthorityRecordDigest = authorityRecordDigest;
        AuthorityEnvelopeDigest = authorityEnvelopeDigest;
        BindingDigest = bindingDigest;
    }

    public ProtectedDispositionAuthorityPayload Payload { get; }
    public ExactSha256Digest AuthorityRecordDigest { get; }
    public ExactSha256Digest AuthorityEnvelopeDigest { get; }
    public ExactSha256Digest BindingDigest { get; }

    internal static ProtectedDispositionAuthority Create(
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof)
    {
        ArgumentNullException.ThrowIfNull(payload);
        ArgumentNullException.ThrowIfNull(proof);
        if (!payload.PayloadDigest.Equals(proof.PayloadDigest) ||
            !payload.ExpectedAuthorityRecordDigest.Equals(proof.AuthorityRecordDigest) ||
            payload.AuthorityEpoch != proof.AuthorityEpoch)
        {
            throw new ArgumentException("The disposition proof does not match its payload.", nameof(proof));
        }

        var digest = ProtectedPolicyFrame.Hash("protocol.protected-disposition-authority-binding/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, payload.PayloadDigest);
            ProtectedPolicyFrame.Digest(stream, proof.EnvelopeDigest);
            ProtectedPolicyFrame.Digest(stream, proof.AuthorityRecordDigest);
        });
        return new ProtectedDispositionAuthority(
            payload, proof.AuthorityRecordDigest, proof.EnvelopeDigest, digest);
    }
}

public interface IProtectedDispositionAuthorityVerifier
{
    bool Verify(
        ProtectedDispositionAuthorityPayload payload,
        ProtectedAuthorityEnvelope proof);
}
