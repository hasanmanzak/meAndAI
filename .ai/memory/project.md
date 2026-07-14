# Project Snapshot

Last verified: **2026-07-14**

## Verified facts

- Repository: [hasanmanzak/meAndAI](https://github.com/hasanmanzak/meAndAI)
- Visibility: private
- Default branch: `main`
- Current protocol version: `0.2.0`
- Released baseline: `v0.1.0`; `v0.2.0` remains a release candidate until
  its delivery pull request, cross-platform CI, merge, and tag are complete.
- Content language: English
- Purpose: provide a shared development protocol that other projects can pin
  while retaining independent project memory.
- Current tracked feature:
  [FEAT-0002](../../docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md)
  / [issue #3](https://github.com/hasanmanzak/meAndAI/issues/3)

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
- The current release target is `v0.2.0`; publication evidence is pending.
  Prior delivery is recorded in
  [pull request #2](https://github.com/hasanmanzak/meAndAI/pull/2).
