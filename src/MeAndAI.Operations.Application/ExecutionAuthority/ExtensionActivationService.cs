using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Application.ExecutionAuthority;

public sealed class ExtensionActivationService
{
    private readonly IExecutionAuthorityReadPort readPort;
    private readonly IExecutionAuthorityMutationPort mutationPort;
    private ExtensionActivationService(IExecutionAuthorityReadPort readPort,
        IExecutionAuthorityMutationPort mutationPort) =>
        (this.readPort, this.mutationPort) = (readPort, mutationPort);
    public static ExtensionActivationService Create(
        IExecutionAuthorityReadPort readPort,
        IExecutionAuthorityMutationPort mutationPort)
    {
        ArgumentNullException.ThrowIfNull(readPort);
        ArgumentNullException.ThrowIfNull(mutationPort);
        return new(readPort, mutationPort);
    }
    public async ValueTask<ActivationCasDecision> ActivateAsync(
        ExtensionActivationCommand command, AuthorityActorId executingActor,
        DateTimeOffset observedAtUtc, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);
        ArgumentNullException.ThrowIfNull(executingActor);
        cancellationToken.ThrowIfCancellationRequested();
        if (observedAtUtc.Offset != TimeSpan.Zero)
            throw new ArgumentException("The timestamp must have UTC offset zero.",
                nameof(observedAtUtc));
        ExecutionGrant grant = command.Grant;
        ApprovalAuthoritySetSnapshot? snapshot = await readPort.ReadAuthoritySetAsync(
            grant.AuthoritySet.Id, cancellationToken).ConfigureAwait(false);
        if (snapshot is null) return Reject(ExecutionGrantRejection.SnapshotUnavailable);
        AuthoritySetBinding authority = AuthoritySetBinding.From(snapshot);
        if (!authority.Equals(grant.AuthoritySet) ||
            !authority.Equals(command.ExpectedCurrent.AuthoritySet))
            return Reject(ExecutionGrantRejection.SnapshotDrift);
        ExtensionActivationRecord? current = await readPort.ReadExtensionActivationAsync(
            command.ExpectedCurrent.Repository, cancellationToken).ConfigureAwait(false);
        if (current is null) return Reject(ExecutionGrantRejection.ActivationRecordUnavailable);
        if (!current.AuthoritySet.Equals(authority))
            return Reject(ExecutionGrantRejection.SnapshotDrift);
        if (!current.Equals(command.ExpectedCurrent))
            return Reject(ExecutionGrantRejection.ActivationRecordDrift);
        ExecutionGrantRejection? ordinary = ValidateOrdinary(
            snapshot, command, executingActor, observedAtUtc);
        if (ordinary is not null) return Reject(ordinary);
        if (!snapshot.JournalStores.Contains(grant.JournalStore))
            return Reject(ExecutionGrantRejection.GrantStoreDrift);
        AuthorityDigest? head = await readPort.ReadGrantStoreHeadAsync(
            grant.JournalStore, cancellationToken).ConfigureAwait(false);
        if (head is null) return Reject(ExecutionGrantRejection.GrantStoreDrift);
        if (!ProposedMatches(command, authority))
            return Reject(ExecutionGrantRejection.BindingMismatch);
        return await mutationPort.TryActivateExtensionAsync(
            ExtensionActivationMutationRequest.Create(command, authority, head,
                executingActor, observedAtUtc), cancellationToken).ConfigureAwait(false);
    }
    private static ExecutionGrantRejection? ValidateOrdinary(
        ApprovalAuthoritySetSnapshot snapshot, ExtensionActivationCommand command,
        AuthorityActorId executingActor, DateTimeOffset observedAtUtc)
    {
        ExecutionGrant grant = command.Grant;
        if (!HasRole(snapshot, grant.Issuer, AuthorityRole.GrantIssuer) ||
            !HasRole(snapshot, grant.Executor, AuthorityRole.Executor) ||
            !grant.Executor.Equals(executingActor)) return ExecutionGrantRejection.ActorMismatch;
        if (HasRoleConflict(snapshot, grant)) return ExecutionGrantRejection.RoleConflict;
        if (!ApprovalsMatch(snapshot, grant)) return ExecutionGrantRejection.ApprovalMismatch;
        if (!grant.Target.Equals(command.ExpectedCurrent.Repository))
            return ExecutionGrantRejection.TargetMismatch;
        if (grant.Generation != grant.LeaseFence.Generation ||
            grant.Generation != command.ExpectedLeaseFence.Generation)
            return ExecutionGrantRejection.GenerationMismatch;
        if (!StringComparer.Ordinal.Equals(grant.LeaseFence.OwnerIdentity,
                command.ExpectedLeaseFence.OwnerIdentity) ||
            !StringComparer.Ordinal.Equals(grant.LeaseFence.FencingToken,
                command.ExpectedLeaseFence.FencingToken))
            return ExecutionGrantRejection.LeaseFenceMismatch;
        if (grant.Capability != ExecutionCapability.ExtensionActivate ||
            grant.Binding is not ExtensionActivationGrantBinding binding)
            return ExecutionGrantRejection.CapabilityMismatch;
        ExtensionActivationRecord proposed = command.Proposed;
        ExtensionActivationGrantBinding expected = ExtensionActivationGrantBinding.Create(
            command.ExpectedCurrent.RecordDigest, proposed.ActiveSnapshotDigest,
            proposed.ActivePolicyIdentity, proposed.ActivePolicyDigest,
            proposed.ActivatingTargetCommit, command.TransitionEvidenceDigest,
            proposed.ClosureEvidenceDigest, proposed.Repository,
            command.ExpectedCurrent.CasVersion, binding.AllowedEffectIdentity,
            binding.RequiredApprovalRoles, binding.Digest);
        if (!grant.Binding.Equals(expected)) return ExecutionGrantRejection.BindingMismatch;
        if (observedAtUtc < grant.NotBeforeUtc) return ExecutionGrantRejection.NotYetValid;
        return observedAtUtc >= grant.ExpiresAtUtc ? ExecutionGrantRejection.Expired : null;
    }
    private static bool ProposedMatches(
        ExtensionActivationCommand command, AuthoritySetBinding authority)
    {
        ExtensionActivationRecord current = command.ExpectedCurrent;
        ExtensionActivationRecord proposed = command.Proposed;
        ExecutionGrant grant = command.Grant;
        if (current.ActivationEpoch.Value == long.MaxValue ||
            current.CasVersion.Value == long.MaxValue) return false;
        return proposed.Repository.Equals(current.Repository) &&
            proposed.PreviousRecordDigest?.Equals(current.RecordDigest) == true &&
            proposed.BootstrapEvidenceDigest is null &&
            proposed.ActivationEpoch.Value == current.ActivationEpoch.Value + 1 &&
            proposed.CasVersion.Value == current.CasVersion.Value + 1 &&
            proposed.AuthoritySet.Equals(authority) &&
            proposed.ActivationApprovals.SequenceEqual(grant.Approvals) &&
            proposed.ActivationGrantDigest.Equals(grant.Digest) &&
            proposed.TransitionEvidenceDigest.Equals(command.TransitionEvidenceDigest) &&
            HasCanonicalDigest(proposed);
    }
    private static bool HasCanonicalDigest(ExtensionActivationRecord record) =>
        ExtensionActivationRecord.CreateSuccessor(record.Repository,
            record.ActivationEpoch, record.CasVersion, record.ActivePolicyIdentity,
            record.ActivePolicyDigest, record.ActiveSnapshotDigest,
            record.ActivatingTargetCommit, record.PreviousRecordDigest!,
            record.ActivationApprovals, record.ActivationGrantDigest,
            record.TransitionEvidenceDigest, record.ClosureEvidenceDigest,
            record.AuthoritySet).RecordDigest.Equals(record.RecordDigest);
    private static ActivationCasDecision Reject(ExecutionGrantRejection rejection) =>
        ActivationCasDecision.Rejected(rejection);
    private static bool HasRole(ApprovalAuthoritySetSnapshot snapshot,
        AuthorityActorId actor, AuthorityRole role) => snapshot.Members.Any(member =>
            member.Actor.Equals(actor) && member.Roles.Contains(role));
    private static bool ApprovalsMatch(ApprovalAuthoritySetSnapshot snapshot,
        ExecutionGrant grant)
    {
        AuthorityApprovalPolicy? policy = snapshot.ApprovalPolicies.SingleOrDefault(
            value => StringComparer.Ordinal.Equals(value.GrantKind, grant.Binding.Kind));
        if (policy is null || !policy.RequiredApprovalRoles.SequenceEqual(
                grant.Binding.RequiredApprovalRoles) ||
            grant.Approvals.Count != policy.RequiredApprovalRoles.Count) return false;
        return policy.RequiredApprovalRoles.All(role =>
        {
            GrantApprovalEvidence[] matches =
                [.. grant.Approvals.Where(approval => approval.Role == role)];
            return matches.Length == 1 && HasRole(snapshot, matches[0].Approver, role);
        }) && grant.Approvals.All(approval =>
            policy.RequiredApprovalRoles.Contains(approval.Role));
    }
    private static bool HasRoleConflict(ApprovalAuthoritySetSnapshot snapshot,
        ExecutionGrant grant)
    {
        List<(AuthorityActorId Actor, AuthorityRole Role)> assignments =
            [.. grant.Approvals.Select(static approval =>
                (approval.Approver, approval.Role)),
                (grant.Issuer, AuthorityRole.GrantIssuer),
                (grant.Executor, AuthorityRole.Executor)];
        foreach (IGrouping<AuthorityActorId, (AuthorityActorId Actor, AuthorityRole Role)> group
            in assignments.GroupBy(static value => value.Actor))
        {
            AuthorityRole[] roles = [.. group.Select(static value => value.Role)
                .Distinct().OrderBy(static value => value.Value, StringComparer.Ordinal)];
            for (int left = 0; left < roles.Length; left++)
                for (int right = left + 1; right < roles.Length; right++)
                    if (!snapshot.SoloMaintainerExceptions.Any(exception =>
                        exception.Actor.Equals(group.Key) &&
                        exception.AllowedRoles.SequenceEqual(new[] { roles[left], roles[right] }
                            .OrderBy(static value => value.Value, StringComparer.Ordinal))))
                        return true;
        }
        return false;
    }
}
