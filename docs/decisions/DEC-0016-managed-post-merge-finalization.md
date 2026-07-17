# DEC-0016 - Finalize Exact Managed Merges in the Consumer Workflow

- Classification: Decision
- Status: Accepted
- Date: 2026-07-17
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0022](../features/FEAT-0022-v097-managed-merge-finalization/README.md)
- Related decisions: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md), [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0008](DEC-0008-local-codex-execution.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), [DEC-0011](DEC-0011-qualified-evidence-and-closure.md), and [DEC-0013](DEC-0013-trusted-adoption-and-recoverable-evidence.md)
- Supersedes: DEC-0006 only where it prohibits cleanup of an adoption proposal after that exact proposal has been completed, reviewed, and merged; and DEC-0005 only for the post-merge finalization job's job-scoped `GITHUB_TOKEN` writes; pre-merge retention, maintainer-owned merge, proposal creation, and workflow self-update remain unchanged

## Context

The adoption launcher ends after it marks a completed proposal ready and moves
its canonical issue to `status:needs-review`. The consumer workflow listens only
for scheduled and manual update discovery. When the maintainer merges, no actor
closes the issue or removes the deterministic branch unless a repository-wide
GitHub setting happens to do so.

The update adapter safely cleans an older open proposal when a verified newer
replacement exists. That supersession contract does not cover the branch of a
proposal that the maintainer already merged. A later updater run inventories
only open proposal ownership and therefore treats such a remaining reserved
branch as an orphan, correctly blocking rather than guessing.

Repository-wide automatic branch deletion is broader than meAndAI ownership and
does not reconcile issues. A central service or GitHub App is disproportionate.
The consumer already owns a pinned workflow and a mutation adapter with strict
marker and expected-head lease primitives.

## Decision

The canonical consumer workflow gains a bounded post-merge route. A merged
`pull_request.closed` event invokes the existing consumer mutation adapter in a
dedicated finalization mode. The same mode may be invoked for one explicit pull
request number through `workflow_dispatch` to recover a missed event. Schedule
and ordinary manual dispatch continue to run update discovery only.

The finalizer treats a pull request as managed only when its live GitHub record
proves all applicable evidence:

1. the pull request is merged into the current consumer default branch and its
   merge commit is still contained in the current default head;
2. its head is from the same repository and its deterministic branch exactly
   matches the canonical target tag;
3. its first body line contains exactly one canonical completed-adoption or
   protocol-update marker binding repository, protocol commit, and head SHA;
4. the API head, marker head, and live branch ref agree, when the ref exists;
5. changed paths satisfy the proposal class and expose no rename/copy
   provenance; and
6. there is exactly one same-repository tracking issue: the canonical
   adoption-marker issue for adoption, or the one issue named by an exact
   `Tracking issue: #N` pull-request body line for an update; and
7. no open pull request currently reuses the exact head branch.

A normal merged pull request with neither a reserved branch nor a canonical
first-line marker is a successful no-op. Managed-looking ambiguity fails closed.
All qualified state is revalidated before mutation. If the exact branch exists,
the finalizer deletes it through an expected-head Git lease and verifies remote
absence. An already absent exact branch is valid idempotent recovery; a moved or
ambiguous ref is not.

Only after branch convergence does the finalizer add one marker-protected issue
comment containing the pull request, exact head, and branch result, remove
transient meAndAI status labels that are actually present, and close an open
issue as completed. A rerun recognizes the evidence marker and closed issue
without duplicating the comment. This ordering accepts recoverable issue-only
work after branch deletion but never closes the issue before a failed
destructive operation.

Before the launcher marks an adoption pull request ready, it adds one exact
`Tracking issue: #N` line for the canonical adoption issue. Managed update pull
requests must similarly acquire exactly one same-repository tracking line during
their ordinary DoR work before merge. A native closing keyword is forbidden for
this managed lifecycle because GitHub would close the issue during merge, before
the finalizer proves branch convergence. Missing or multiple links are not
guessed after merge.

The finalization job uses a job-scoped consumer `GITHUB_TOKEN` with `contents:
write`, `pull-requests: read`, and `issues: write`. DEC-0005 remains unchanged
for proposal creation and workflow self-update: `MEANDAI_UPDATER_TOKEN` retains
that separate authority, and no source credential enters finalization.

## Consequences

- Conforming managed merges converge without leaving review-state issues or
  reserved branches for the next updater run.
- Maintainers still review and merge; the new automation reacts only after
  GitHub records the exact merge.
- Existing consumers receive the route and adapter through an ordinary reviewed
  same-major update. Earlier pins and past merge events are not rewritten.
- An explicit recovery dispatch handles missed events and partial issue
  finalization without adding polling or a background service.
- Organizations that restrict job-token writes receive a visible failed run and
  retain exact manual recovery evidence instead of unsafe fallback deletion.
- Update maintainers must supply one tracking issue before merge; this makes the
  existing issue/DoR requirement machine-observable at closure.

## Alternatives considered

- Enable repository-wide automatic head-branch deletion: rejected as too broad
  and insufficient for issue status and evidence.
- Let the next scheduled updater delete merged branches: rejected because the
  open-proposal ownership proof no longer exists and schedule latency leaves a
  known blocker.
- Delete by branch prefix after merge: rejected because names alone are not
  ownership evidence.
- Use the updater PAT for issue cleanup: rejected because job-scoped
  `GITHUB_TOKEN` can express the narrower same-repository authority and preserves
  DEC-0005 separation.
- Add another consumer script or hosted cleanup service: rejected because the
  existing mutation adapter owns the same marker/ref/lease responsibility and a
  new deployment surface is unnecessary.

## Review condition

Review if GitHub provides an atomic merged-PR issue/ref finalization primitive,
job-token policy prevents the bounded permissions in common consumers, or
managed proposals move to fork-based branches.
