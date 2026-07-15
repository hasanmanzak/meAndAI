# DEC-0008 - Complete Semantic Adoption with Local Codex CLI

- Classification: Decision
- Status: Accepted
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer maintainers
- Related features: [FEAT-0007](../features/FEAT-0007-local-codex-adoption/README.md), [FEAT-0006](../features/FEAT-0006-quick-adoption-launcher/README.md)
- Related decisions: [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0007](DEC-0007-local-quick-adoption-boundary.md)
- Supersedes: [DEC-0007](DEC-0007-local-quick-adoption-boundary.md) only for the post-workflow Codex Cloud handoff

## Context

Secret provisioning and seed publication are deterministic local operations.
They need GitHub and Git credentials but no AI model. The v0.6.0 launcher
nevertheless completes semantic adoption by posting an `@codex` task through a
configured Codex Cloud GitHub connection. A maintainer who already uses Codex
CLI locally should not need to connect a private consumer repository to Codex
Cloud.

The semantic step still needs an explicitly invoked agent: the lifecycle may
produce collision-only state, and project records, memory, tests, links, and
labels cannot be copied safely without project review. That step begins only
after the workflow creates its deterministic draft and transient manifest.

## Decision

Keep repository creation, credential reconciliation, seed publication,
lifecycle dispatch, and exact-run waiting as deterministic launcher work. Do
not invoke Codex for those operations and do not place token values in any
prompt.

When the lifecycle produces a single draft with the expected deterministic
branch, resolve both its branch and immutable `headRefOid`. Clone that branch
into a new operating-system temporary directory, verify the head and absence of
`FG_PAT.txt` and `MEANDAI_RO_FG_PAT.txt`, and invoke Codex CLI there through
`codex exec`. Use the maintainer's saved local Codex authentication, an
ephemeral session, `workspace-write`, a reduced spawned-process environment,
disabled spawned-command network access, and a finite synchronous process
limit. The prompt states that the two fixed Actions secrets already exist and
that their source files and values are out of scope.

Prefer an installed `codex` command. If it is absent, `npx` may run one pinned
`@openai/codex` package version without installing it globally. Authentication
must still be present and is never bootstrapped from repository content.

Before Codex starts, the launcher uses its existing authenticated `gh` boundary
to create any missing common Agile labels and reconcile one canonically marked
adoption issue. The prompt supplies that issue URL; Codex performs no GitHub
operation. Codex must not commit, push, approve, or merge. After it exits, the launcher
requires the clone's head to remain the captured PR head, the transient manifest
to be removed, a non-empty change set to exist, credential files to remain
absent, and `git diff --check` to pass. It then rechecks the live remote branch,
creates one launcher-owned commit, and pushes with an exact expected-head lease.
Any ambiguity blocks. The maintainer owns final review and merge.
If the manifest was already absent when the launcher cloned a draft, the
launcher cannot prove who completed it and therefore neither reruns Codex nor
marks the draft ready.

## Consequences

- Consumer repositories need no Codex Cloud GitHub connection and receive no
  `@codex` comment.
- Local execution still sends the prompt and relevant repository context to the
  model service configured by the authenticated Codex CLI; it is local
  orchestration, not offline inference.
- The source credential files are not cloned or referenced by value. The
  temporary clone is a practical repository isolation boundary, not a claim
  that every host filesystem read is impossible on every Codex platform.
- A missing CLI may cause one pinned npm download when `npx` is installed. A
  missing login, package manager, submodule credential, or semantic fact blocks
  with an actionable handoff rather than falling back to Cloud.
- The model service remains reachable by the Codex CLI itself, but commands
  spawned by the agent cannot reach GitHub or another network service. The
  launcher never supplies the two protocol PAT values to that process.
- A finite process timeout terminates stalled local authentication or semantic
  execution instead of allowing an unbounded adoption loop.
- Existing v0.6.0 consumers and the manual workflow-only path remain valid.

## Alternatives considered

- Keep Codex Cloud optional: rejected because the requested default is an
  entirely local GitHub handoff and two execution models complicate safety and
  documentation.
- Use Codex to provision the secrets: rejected because `gh secret set` is
  deterministic and exposing secret values to an AI process adds no value.
- Run Codex before the lifecycle: rejected because the authoritative adoption
  manifest and deterministic branch do not exist until the lifecycle succeeds.
- Run Codex in the consumer's original checkout: rejected because the local
  credential files are present there and the draft branch must not disturb the
  maintainer's default-branch workspace.
- Add a consumer Codex workflow or API-key secret: rejected because it recreates
  hosted execution, adds a third credential, and broadens the bootstrap.
- Automatically merge: rejected because agent completion does not replace the
  maintainer's final evidence and merge gate.

## Review condition

Revisit if Codex CLI removes non-interactive local execution, GitHub provides a
safer first-party semantic-adoption primitive, or a consumer requires a stronger
host-level isolation boundary than a temporary clone plus Codex sandbox.
