# Project Snapshot

Last verified: **2026-07-15**

## Verified facts

- Repository: [hasanmanzak/meAndAI](https://github.com/hasanmanzak/meAndAI)
- Visibility: private
- Default branch: `main`
- Current protocol version: `0.6.3`
- Current scope: optional local credential-source files for configured existing
  targets, tracked by [issue #27](https://github.com/hasanmanzak/meAndAI/issues/27).
- Content language: English
- Purpose: provide a shared development protocol that other projects can pin
  while retaining independent project memory.
- Latest tracked work: [issue #27](https://github.com/hasanmanzak/meAndAI/issues/27).
- Current release candidate: implemented
  [BUG-0002](../../docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0002-correction-for-v063),
  targeting `v0.6.3`; pull-request publication and release verification remain.
- Latest released delivery before the current candidate: completed
  [BUG-0001](../../docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0001-correction-for-v062)
  in merged [pull request #25](https://github.com/hasanmanzak/meAndAI/pull/25),
  released at exact merge commit `334df5a4119e63549f8208700959ee77ec470241`
  by annotated tag [`v0.6.2`](https://github.com/hasanmanzak/meAndAI/tree/v0.6.2).

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
- `v0.6.3` makes both local credential files optional for an existing target
  when their mapped repository secrets already exist. With no protocol file,
  exact workflow and semantic-source retrieval uses the authenticated local
  `gh` identity; stored secret values remain unreadable. Missing secrets and
  new repositories still require their mapped local files.
- The source-only bootstrap resolver and adapter are intentionally small and
  are not copied to consumers. GitHub Actions does not run an AI agent; an
  explicitly invoked agent or maintainer completes and removes the manifest.
- FEAT-0002's historical post-merge gate was reconciled on 2026-07-15 against
  merged [PR #4](https://github.com/hasanmanzak/meAndAI/pull/4) and remote tag
  [`v0.2.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.2.0); this evidence
  correction does not create a new protocol release.
