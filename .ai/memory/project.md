# Project Snapshot

Last verified: **2026-07-16**

## Verified facts

- Repository: [hasanmanzak/meAndAI](https://github.com/hasanmanzak/meAndAI)
- Visibility: private
- Default branch: `main`
- Current protocol version: `0.9.4`. Exact publication state is authoritative
  in [GitHub Releases](https://github.com/hasanmanzak/meAndAI/releases) and
  [issue #55](https://github.com/hasanmanzak/meAndAI/issues/55) after
  publication, not predicted or duplicated in this repository snapshot.
- Current scope: [FEAT-0019](../../docs/features/FEAT-0019-v094-sandbox-progress-correction/README.md)
  corrects the launcher's native Windows sandbox carry-forward, empty-consumer
  semantics, and phase progress; [issue #55](https://github.com/hasanmanzak/meAndAI/issues/55)
  owns delivery and future publication evidence.
- Content language: English
- Purpose: provide a shared development protocol that other projects can pin
  while retaining independent project memory.
- Latest tracked work: the source-only `Invoke-MeAndAIQuickAdoption.ps1`
  performs a model-free workspace-write probe before local Codex, carries only
  the verified native Windows sandbox mode, records unavailable empty-project
  facts as `Not yet established`, and displays truthful phase progress.
  `TEST-0103` and `TEST-0104` own the regression. The retained
  [Derdini draft](https://github.com/hasanmanzak/Derdini/pull/1) remains the
  resumable consumer evidence; the launcher still never merges.
- Historical v0.9.0 delivery: [FEAT-0015](../../docs/features/FEAT-0015-stability-consistency-mandate/README.md)
  established the event-triggered stability and consistency mandate through
  [issue #47](https://github.com/hasanmanzak/meAndAI/issues/47) and
  [pull request #48](https://github.com/hasanmanzak/meAndAI/pull/48).
- Open external follow-up: `FIND-0120` / `RISK-0076` is tracked by
  [finding issue #44](https://github.com/hasanmanzak/meAndAI/issues/44). Issue
  #41 remains the historical FEAT-0013 delivery and publication authority.
- Historical v0.8.6 delivery: immutable release
  [`v0.8.6`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.6)
  targets commit `a3d58a9cee00b9914c40adcd8e93dff53bed235a` and closed
  `FIND-0132`; issue #43 remains its external publication authority.
- Historical v0.8.5 delivery: immutable release
  [`v0.8.5`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.5)
  targets merge commit `7c06dfad75ab7b327d46c7b8f8d7cb541bab3896`.
  Its failed completion projection is retained as `FIND-0132`, not rewritten.
- Historical v0.8.4 delivery: completed
  [FEAT-0013](../../docs/features/FEAT-0013-v084-correction/README.md) retains
  [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) as its delivery
  and post-publication authority.
- Historical v0.8.1 delivery: FEAT-0011 was published as immutable release
  [`v0.8.1`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.1).
  The release and issue retain the exact pull request, target commit, checks,
  and post-publication verification. The FEAT-0011 pre-merge commit had already
  described that release as published; [FEAT-0012](../../docs/features/FEAT-0012-v082-correction/README.md)
  records this premature claim as `FIND-0108` rather than treating later valid
  publication as retroactive evidence.

## Collaboration constraints

- When authorization and tooling are available, carry approved repository and
  GitHub work through validation and publication instead of stopping at advice.
- An explicit request to wait for future instructions is a hard stop for edits,
  implementation, and detailed planning until the next concrete directive.
- Treat continuity requirements as part of scope and answer the stated
  project/tool question directly.
- Do not invent implementation and claim completion without repository evidence.
- Large work is decomposed and reviewed slice by slice.
- Repository content is written in English; conversation language follows the
  user.

## Engineering direction

The canonical rules are in the [common protocol](../../PROTOCOL.md). Defaults
are Domain-Driven Design, Rich Entity Model, and Test-Driven Development, with a
documented project decision required when another approach better fits the
domain. Avoid a large universal bootstrapper or semantic AI-memory validator.

## Open context

- Existing consumers pinned to immutable `v0.1.0` require one manual upgrade
  and updater installation; consumers adopting `v0.2.0` receive the updater
  assets during initial collision-safe adoption.
- `v0.2.0` delivered the updater in
  [pull request #4](https://github.com/hasanmanzak/meAndAI/pull/4); `v0.2.1`
  refines validation bounds and documentation without changing updater behavior.
- `v0.3.0` adds the bounded post-development convergence scan in
  [FEAT-0003](../../docs/features/FEAT-0003-convergent-completion-scan/README.md).
- `v0.3.2` makes the updater's pre-cleanup audit comment conditional without
  changing cleanup ordering, safety gates, leases, or compensation behavior.
- `v0.4.0` uses consumer secret `MEANDAI_UPDATER_TOKEN` for repository-scoped
  writes and reconciles target-different updater assets in the same draft PR as
  the protocol pointer. Pre-v0.4 consumer copies need one reviewed migration.
- `v0.5.0` lets a submodule consumer seed only the canonical workflow. It
  proposes all absent deterministic adoption assets or a manifest-only semantic
  handoff on collision, then delegates later releases to the local updater.
- `v0.6.0` adds a source-only local launcher that creates or validates the
  consumer repository, provisions both fixed Actions secrets, and publishes
  only the exact seed workflow. It then runs the bounded lifecycle and places
  one idempotent Codex Cloud adoption task on the draft; it never merges.
- `v0.6.1` corrects that post-workflow boundary: no consumer Cloud connection
  or `@codex` comment is used. An authenticated local CLI works synchronously
  in a credential-free temporary clone under a finite timeout. The launcher
  owns labels, the marked adoption issue, verification, and the lease-protected
  push; Codex-spawned commands have network disabled. Secret creation remains
  deterministic and AI-free.
- `v0.6.2` preserves existing repository Actions secrets by name and creates
  only missing mappings. GitHub does not reveal stored values, so the launcher
  does not claim to validate an existing secret's value. `FG_PAT.txt` is not
  required or read when `MEANDAI_UPDATER_TOKEN` already exists.
- `v0.7.0` adds repository-native `IDEA-NNNN` incubation, a pinned consumer
  template, and absent-only idea-index installation for new collision-free
  adoption. Ideas do not authorize implementation or bypass delivery gates.
- `v0.7.1` makes both local credential files optional for an existing target
  when their mapped repository secrets already exist. With no protocol file,
  exact workflow and semantic-source retrieval uses the authenticated local
  `gh` identity; stored secret values remain unreadable. Missing secrets and
  new repositories still require their mapped local files.
- `v0.9.1` extends that rule to an accessible existing empty GitHub repository
  whose no-head local target has not yet connected `origin`; an absent derived
  repository still requires both files before creation.
- `v0.9.3` corrects the live adoption pull-request origin contract by using the
  repository name, repository owner, and Boolean cross-repository fields that
  GitHub CLI actually returns. Affected `v0.9.2` drafts remain retained and may
  be resumed with the corrected launcher.
- `v0.9.4` validates native Windows workspace writes without a model call,
  safely carries the verified sandbox implementation across isolated Codex
  configuration, distinguishes empty-project unknowns from adoption blockers,
  and makes launcher progress observable without inventing percentages.
- `v0.9.2` distributes that same reviewed launcher as one immutable-release
  asset and reduces normal user execution to one local script command. The
  launcher stays outside consumer repositories and retains its release,
  source, credential, lifecycle, Codex, and merge boundaries.
- `v0.7.2` binds adoption proposals to canonical repository, base, actor, head,
  and marker evidence; validates exact protocol pins regardless of diff shape;
  rejects updater rename provenance; and moves adoption issues to review only
  after verified readiness.
- `v0.7.3` clarifies that the quick command starts the network-enabled parent
  launcher, applicable credential files stay in the original target and are
  absent only from the isolated Codex clone, and only Codex-spawned commands
  lose network access. It changes documentation and structural coverage only.
- `v0.8.0` establishes immutable-release, exact proposal-state, rename,
  workflow-run, supersession, and canonical repository-evidence invariants.
- `v0.8.1` carries repository host, release credential/commit, complete path,
  dispatch session, finding disposition, test evidence, and cleanup ownership
  through every mutation and closure boundary. An existing v0.8.0 consumer's
  old adapter may propose the ordinary v0.8.1 review PR; that proposal installs
  the new workflow and adapter together. After merge, later runs pass the
  separate `PROTOCOL_TOKEN` without a manual seed replacement.
- `v0.8.2` closes `FIND-0102` through `FIND-0111` with exact issue ownership,
  repository-scoped secret serialization, completed-proposal retention, full
  reserved-branch inventory, contract-bearing test evidence, recurring
  actionlint, auditable scan records, external publication evidence, and the
  mandatory bounded consumer completion scan.
- `v0.8.3` corrects the post-publication verifier's repository-root URL after
  the immutable v0.8.2 external run exposed an invalid trailing slash. The
  focused mock now rejects that URL shape.
- `v0.8.4` is the bounded correction for `FIND-0112` through `FIND-0122`:
  trusted updater preflight, pre-mutation seed validation, recoverable
  completion publication, one exact manifest contract, honest and paginated
  evidence, stable traceability, finding taxonomy, and version boundaries.
  `RISK-0076` retains the unavailable private-repository `main` protection as a
  maintainer-owned external follow-up tracked by
  [finding issue #44](https://github.com/hasanmanzak/meAndAI/issues/44), with a
  visibility/plan review condition.
- The source-only bootstrap resolver and adapter are intentionally small and
  are not copied to consumers. GitHub Actions does not run an AI agent; an
  explicitly invoked agent or maintainer completes and removes the manifest.
- FEAT-0002's historical post-merge gate was reconciled on 2026-07-15 against
  merged [PR #4](https://github.com/hasanmanzak/meAndAI/pull/4) and remote tag
  [`v0.2.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.2.0); this evidence
  correction does not create a new protocol release.
