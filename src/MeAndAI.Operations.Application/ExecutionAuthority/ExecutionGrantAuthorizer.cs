using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Application.ExecutionAuthority;

public sealed class ExecutionGrantAuthorizer
{
    private readonly IExecutionAuthorityReadPort readPort;
    private readonly IExecutionAuthorityMutationPort mutationPort;
    private ExecutionGrantAuthorizer(
        IExecutionAuthorityReadPort readPort,
        IExecutionAuthorityMutationPort mutationPort) =>
        (this.readPort, this.mutationPort) = (readPort, mutationPort);
    public static ExecutionGrantAuthorizer Create(
        IExecutionAuthorityReadPort readPort,
        IExecutionAuthorityMutationPort mutationPort)
    {
        ArgumentNullException.ThrowIfNull(readPort);
        ArgumentNullException.ThrowIfNull(mutationPort);
        return new(readPort, mutationPort);
    }
    public async ValueTask<ExecutionGrantDecision> AuthorizeAndConsumeAsync(
        GrantValidationRequest request,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(request);
        cancellationToken.ThrowIfCancellationRequested();
        ExecutionGrant grant = request.Grant;
        ApprovalAuthoritySetSnapshot? snapshot =
            await readPort.ReadAuthoritySetAsync(
                grant.AuthoritySet.Id, cancellationToken).ConfigureAwait(false);
        if (snapshot is null)
            return Reject(ExecutionGrantRejection.SnapshotUnavailable);
        AuthoritySetBinding current = AuthoritySetBinding.From(snapshot);
        if (!current.Equals(grant.AuthoritySet))
            return Reject(ExecutionGrantRejection.SnapshotDrift);
        if (!HasRole(snapshot, grant.Issuer, AuthorityRole.GrantIssuer) ||
            !HasRole(snapshot, grant.Executor, AuthorityRole.Executor) ||
            !grant.Executor.Equals(request.ExecutingActor))
            return Reject(ExecutionGrantRejection.ActorMismatch);
        if (HasRoleConflict(snapshot, grant))
            return Reject(ExecutionGrantRejection.RoleConflict);
        if (!ApprovalsMatch(snapshot, grant))
            return Reject(ExecutionGrantRejection.ApprovalMismatch);
        if (!grant.Subject.Equals(request.ExpectedSubject))
            return Reject(ExecutionGrantRejection.SubjectMismatch);
        if (!grant.Target.Equals(request.ExpectedTarget))
            return Reject(ExecutionGrantRejection.TargetMismatch);
        if (!grant.Operation.Equals(request.ExpectedOperation))
            return Reject(ExecutionGrantRejection.OperationMismatch);
        if (grant.Generation != grant.LeaseFence.Generation ||
            grant.Generation != request.ExpectedGeneration ||
            grant.Generation != request.ExpectedLeaseFence.Generation)
            return Reject(ExecutionGrantRejection.GenerationMismatch);
        if (!StringComparer.Ordinal.Equals(
                grant.LeaseFence.OwnerIdentity,
                request.ExpectedLeaseFence.OwnerIdentity) ||
            !StringComparer.Ordinal.Equals(
                grant.LeaseFence.FencingToken,
                request.ExpectedLeaseFence.FencingToken))
            return Reject(ExecutionGrantRejection.LeaseFenceMismatch);
        if (!CapabilityMatches(request.RequiredCapability, grant))
            return Reject(ExecutionGrantRejection.CapabilityMismatch);
        if (!grant.Binding.Equals(request.ExpectedBinding))
            return Reject(ExecutionGrantRejection.BindingMismatch);
        if (request.ObservedAtUtc < grant.NotBeforeUtc)
            return Reject(ExecutionGrantRejection.NotYetValid);
        if (request.ObservedAtUtc >= grant.ExpiresAtUtc)
            return Reject(ExecutionGrantRejection.Expired);
        if (!snapshot.JournalStores.Contains(grant.JournalStore))
            return Reject(ExecutionGrantRejection.GrantStoreDrift);
        AuthorityDigest? head = await readPort.ReadGrantStoreHeadAsync(
            grant.JournalStore, cancellationToken).ConfigureAwait(false);
        if (head is null)
            return Reject(ExecutionGrantRejection.GrantStoreDrift);
        return await mutationPort.TryConsumeGrantAsync(
            GrantConsumptionRequest.Create(request, current, head),
            cancellationToken).ConfigureAwait(false);
    }
    private static ExecutionGrantDecision Reject(ExecutionGrantRejection value) =>
        ExecutionGrantDecision.Rejected(value);
    private static bool HasRole(
        ApprovalAuthoritySetSnapshot snapshot,
        AuthorityActorId actor,
        AuthorityRole role) => snapshot.Members.Any(member =>
            member.Actor.Equals(actor) && member.Roles.Contains(role));
    private static bool HasRoleConflict(
        ApprovalAuthoritySetSnapshot snapshot,
        ExecutionGrant grant)
    {
        List<(AuthorityActorId Actor, AuthorityRole Role)> assignments =
        [.. grant.Approvals.Select(static approval =>
            (approval.Approver, approval.Role)),
            (grant.Issuer, AuthorityRole.GrantIssuer),
            (grant.Executor, AuthorityRole.Executor)];
        foreach (IGrouping<AuthorityActorId, (AuthorityActorId Actor, AuthorityRole Role)> group
            in assignments.GroupBy(static assignment => assignment.Actor))
        {
            AuthorityRole[] roles =
                [.. group.Select(static assignment => assignment.Role).Distinct()
                    .OrderBy(static role => role.Value, StringComparer.Ordinal)];
            for (int left = 0; left < roles.Length; left++)
                for (int right = left + 1; right < roles.Length; right++)
                    if (!snapshot.SoloMaintainerExceptions.Any(exception =>
                        exception.Actor.Equals(group.Key) &&
                        exception.AllowedRoles.SequenceEqual(
                            new[] { roles[left], roles[right] }
                                .OrderBy(static role => role.Value,
                                    StringComparer.Ordinal))))
                        return true;
        }
        return false;
    }
    private static bool ApprovalsMatch(
        ApprovalAuthoritySetSnapshot snapshot,
        ExecutionGrant grant)
    {
        AuthorityApprovalPolicy? policy = snapshot.ApprovalPolicies.SingleOrDefault(
            value => StringComparer.Ordinal.Equals(
                value.GrantKind, grant.Binding.Kind));
        if (policy is null || !policy.RequiredApprovalRoles.SequenceEqual(
                grant.Binding.RequiredApprovalRoles) ||
            grant.Approvals.Count != policy.RequiredApprovalRoles.Count)
            return false;
        foreach (AuthorityRole role in policy.RequiredApprovalRoles)
        {
            GrantApprovalEvidence[] matches =
                [.. grant.Approvals.Where(approval => approval.Role == role)];
            if (matches.Length != 1 ||
                !HasRole(snapshot, matches[0].Approver, role))
                return false;
        }
        return grant.Approvals.All(approval =>
            policy.RequiredApprovalRoles.Contains(approval.Role));
    }
    private static bool CapabilityMatches(
        ExecutionCapability required,
        ExecutionGrant grant)
    {
        if (grant.Capability != required ||
            required == ExecutionCapability.ReleasePublish ||
            required == ExecutionCapability.AuthorityTransfer)
            return false;
        return required switch
        {
            var value when value == ExecutionCapability.RepositoryRead =>
                grant.Binding is ReadGrantBinding read &&
                read.AllowedRepositoryPaths.Count > 0,
            var value when value == ExecutionCapability.ProviderRead =>
                grant.Binding is ReadGrantBinding read &&
                read.AllowedProviderObjectIdentities.Count > 0,
            var value when value == ExecutionCapability.RepositoryMutate =>
                grant.Binding is PlanGrantBinding plan &&
                plan.AllowedRepositoryPaths.Count > 0,
            var value when value == ExecutionCapability.ProviderMutate =>
                grant.Binding is PlanGrantBinding plan &&
                plan.AllowedProviderObjectIdentities.Count > 0,
            var value when value == ExecutionCapability.ReportPublish =>
                grant.Binding is PublicationGrantBinding,
            var value when value == ExecutionCapability.ExtensionActivate =>
                grant.Binding is ExtensionActivationGrantBinding,
            _ => false
        };
    }
}
