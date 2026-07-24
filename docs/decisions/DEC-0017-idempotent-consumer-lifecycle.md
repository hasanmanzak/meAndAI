# DEC-0017 - Reconcile Consumer Lifecycle from Repository-Owned Evidence

- Classification: Decision
- Status: Accepted
- Date: 2026-07-17
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0023](../features/FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md)
- Related decisions: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md), [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0007](DEC-0007-local-quick-adoption-boundary.md), [DEC-0008](DEC-0008-local-codex-execution.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), [DEC-0011](DEC-0011-qualified-evidence-and-closure.md), [DEC-0013](DEC-0013-trusted-adoption-and-recoverable-evidence.md), and [DEC-0016](DEC-0016-managed-post-merge-finalization.md)
- Supersedes: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md) only where an update issue was prepared manually; [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md) only where a repeat launcher invocation could not route an already adopted repository; and [DEC-0016](DEC-0016-managed-post-merge-finalization.md) only where a qualifying installing legacy update lacks machine-created tracking evidence. Maintainer review and merge, replacement-first ordering, exact ownership checks, and fail-closed mutation remain unchanged.

## Context

The consumer updater already discovers immutable releases, prepares a
deterministic branch, creates a draft pull request, supersedes an older open
proposal, and finalizes an exact managed merge. It nevertheless leaves the
tracking issue and one pull-request body field to a maintainer. A scheduled run
therefore cannot complete the same lifecycle that a manual run is meant to
automate.

The quick-adoption launcher has a separate collision rule: any installed seed
that differs from the requested release blocks. That is correct for an
ambiguous partial adoption, but not for a complete older same-major installation
whose installed updater is precisely the authority designed to propose an
upgrade.

Finally, reusable consumer memory and test templates can record the current
protocol tag/SHA as consumer-owned facts. Those copies become stale after the
managed submodule update and cause an unnecessary second reconciliation change.

## Decision

### Automatic update work item

The updater adapter owns update issue reconciliation. For each verified target
it selects exactly one open or closed same-repository issue whose first line is
a canonical marker binding schema version, target tag, protocol commit, and
consumer repository. It creates the issue when absent, reuses it when exact,
and rejects duplicates or conflicting ownership. It creates only missing
standard labels and preserves existing label definitions.

The proposal job grants its job-scoped consumer `GITHUB_TOKEN` `issues: write`.
That token owns issue and label mutations. `MEANDAI_UPDATER_TOKEN` remains the
separate credential for contents, pull-request, and workflow mutations, so no
new fine-grained PAT permission is required. The adapter writes exactly one
non-closing
`Tracking issue: [#N](https://github.com/<owner>/<repository>/issues/N)` line
into the draft pull request and records an idempotent pull-request backlink on
the issue.

When a newer verified release supersedes an older open managed proposal, the
adapter closes the old pull request and deletes the unchanged old branch first.
Only then does it record supersession evidence and close the exact old issue as
not planned. A failure before branch convergence leaves the issue open and
recoverable.

### Repeat-launch classification

Before secret or repository mutation, the launcher classifies the consumer
footprint. An unadopted repository follows initial adoption. A complete adopted
repository must prove one exact submodule gitlink, canonical `.gitmodules`, an
installed release whose immutable commit maps to that gitlink, installed
workflow and script blobs equal to that release, no transient adoption
manifest, and no partial footprint.

If the complete installed tag equals the requested tag, the launcher reconciles
only missing secrets and exits successfully as already current. If it is older
within the same major version, the launcher reconciles missing secrets and
dispatches the installed updater with correlation evidence; it never overwrites
the seed or runs the adoption Codex prompt. A newer installed version, a major
boundary, drift, partial state, or unverifiable release fails before mutation.

### Live protocol pin authority

The submodule gitlink and the matching `.ai/protocol/VERSION` file are the sole
current protocol pin authority. Consumer-owned memory, tests, prompts, and
reusable documentation link to or read that authority dynamically. They may
record an immutable tag/SHA only as dated historical evidence, never as a second
live setting. Consequently a normal compatible update changes only managed
protocol/updater surfaces and does not require a separate consumer-owned
reconciliation pull request.

### Bounded legacy transition

A newer installed updater may repair one legacy installing proposal only when
live repository evidence proves the same-repository merged pull request,
deterministic branch, canonical marker, default base and containment, exact
head, allowed paths, installed gitlink, and missing or placeholder tracking
state. It creates or reuses the target issue, patches the pull request body, and
runs the existing finalizer. Ordinary scheduled/manual update discovery also
checks this exact recoverable state so a missed old event does not require a
separate maintainer operation. Any ambiguity fails closed.

## Consequences

- A scheduled or manually rerun consumer workflow owns issue creation,
  tracking, pull-request proposal, supersession, and post-merge cleanup; the
  maintainer's normal remaining action is review and merge.
- Re-running the latest launcher is idempotent for a current installation and
  is a safe entry point to a compatible installed updater.
- The first qualifying upgrade from a legacy updater can enter the managed
  finalization lifecycle without a permanent migration framework.
- Consumer-owned files remain stable across compatible protocol updates, while
  dated historical evidence remains possible.
- Unsupported or ambiguous states stop before mutation and report the exact
  classifier or ownership failure.

## Alternatives considered

- Require the maintainer to create every update issue: rejected because it
  defeats scheduled end-to-end proposal automation.
- Give the updater PAT issue permission: rejected because the job-scoped
  same-repository token expresses the narrower authority.
- Re-run initial adoption over an existing installation: rejected because it
  can overwrite a seed and bypass the installed updater's immutable contract.
- Keep live version copies in consumer memory and reconcile them separately:
  rejected because they are derived state and create avoidable drift.
- Accept any old merged branch as legacy evidence: rejected because branch
  names alone cannot prove ownership.
- Add a central service or generalized migration engine: rejected as
  disproportionate to one bounded compatibility transition.

## Review condition

Review if GitHub supplies a safer atomic issue/branch/pull-request lifecycle
primitive, protocol major-version migration is defined, the consumer update
surface expands beyond the current managed paths, or job-token policy prevents
same-repository issue reconciliation in common consumers.
