using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RuleTransitionDeclaration
{
    private RuleTransitionDeclaration(
        RuleId ruleId,
        RuleTransitionKind kind,
        RuleRevision? previousRevision,
        RuleRevision? currentRevision,
        ReviewedAuthorityPermalink? reviewedAuthority)
    {
        RuleId = ruleId;
        Kind = kind;
        PreviousRevision = previousRevision;
        CurrentRevision = currentRevision;
        ReviewedAuthority = reviewedAuthority;
    }

    public RuleId RuleId { get; }

    public RuleTransitionKind Kind { get; }

    public RuleRevision? PreviousRevision { get; }

    public RuleRevision? CurrentRevision { get; }

    public ReviewedAuthorityPermalink? ReviewedAuthority { get; }

    public static RuleTransitionDeclaration Unchanged(
        RuleId ruleId,
        RuleRevision revision,
        ReviewedAuthorityPermalink? reviewedAuthority)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(revision);
        return new RuleTransitionDeclaration(
            ruleId,
            RuleTransitionKind.Unchanged,
            revision,
            revision,
            reviewedAuthority);
    }

    public static RuleTransitionDeclaration Added(
        RuleId ruleId,
        RuleRevision currentRevision,
        ReviewedAuthorityPermalink reviewedAuthority)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(currentRevision);
        ArgumentNullException.ThrowIfNull(reviewedAuthority);
        return new RuleTransitionDeclaration(
            ruleId,
            RuleTransitionKind.Added,
            previousRevision: null,
            currentRevision,
            reviewedAuthority);
    }

    public static RuleTransitionDeclaration Revised(
        RuleId ruleId,
        RuleRevision previousRevision,
        RuleRevision currentRevision,
        ReviewedAuthorityPermalink reviewedAuthority)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(previousRevision);
        ArgumentNullException.ThrowIfNull(currentRevision);
        ArgumentNullException.ThrowIfNull(reviewedAuthority);
        if (currentRevision.Value <= previousRevision.Value)
        {
            throw new ArgumentException(
                "A revised transition must increase the rule revision.",
                nameof(currentRevision));
        }

        return new RuleTransitionDeclaration(
            ruleId,
            RuleTransitionKind.Revised,
            previousRevision,
            currentRevision,
            reviewedAuthority);
    }

    public static RuleTransitionDeclaration Retired(
        RuleId ruleId,
        RuleRevision previousRevision,
        ReviewedAuthorityPermalink reviewedAuthority)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(previousRevision);
        ArgumentNullException.ThrowIfNull(reviewedAuthority);
        return new RuleTransitionDeclaration(
            ruleId,
            RuleTransitionKind.Retired,
            previousRevision,
            currentRevision: null,
            reviewedAuthority);
    }
}
