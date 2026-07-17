# Project Agent Instructions

These instructions apply to the consuming repository.

1. If `.ai/adoption/meandai-capabilities.json` exists, treat it as an active
   adoption handoff. Complete its project-specific tasks and remove the
   manifest before the pull request becomes ready or merges.
2. Read the [local common protocol](.ai/protocol/PROTOCOL.md) from the pinned
   `.ai/protocol` gitlink. Resolve its current version from
   [the checkout's `VERSION`](.ai/protocol/VERSION); do not duplicate a literal
   current tag or commit in consumer-owned instructions or records.
3. Read this project's `.ai/memory/README.md`.
4. Read the relevant project-owned feature and decision documents before work.
5. Apply project-specific rules below. A relaxation of the common protocol
   requires a numbered project decision.

## Project-specific rules

Replace this section with the consuming repository's stack, architecture,
commands, constraints, and stricter quality gates. Keep project facts outside
the protocol submodule.
