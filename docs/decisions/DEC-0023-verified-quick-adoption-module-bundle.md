# DEC-0023 - Use a Thin Launcher with One Verified Immutable Module Bundle

- Classification: Decision
- Status: Accepted
- Date: 2026-07-20
- Decision owners: meAndAI release maintainers and consumer maintainers
- Related feature: [FEAT-0036](../features/FEAT-0036-modular-quick-adoption-reliability/README.md)
- Related decisions: [DEC-0007](DEC-0007-local-quick-adoption-boundary.md), [DEC-0013](DEC-0013-trusted-adoption-and-recoverable-evidence.md), [DEC-0019](DEC-0019-hosted-runner-efficiency.md), and [DEC-0020](DEC-0020-target-bound-current-launcher-recovery.md)
- Supersedes: [DEC-0007](DEC-0007-local-quick-adoption-boundary.md)'s prospective requirement that the complete quick-adoption implementation and sole adoption release asset be one monolithic source file; the one-command local trust and credential boundary remains authoritative

## Context

The launcher remains a useful one-command local authority, but concentrating
more than 6,000 lines, 100 functions, release verification, repository
reconciliation, credential handling, workflow dispatch, local agent execution,
and recovery in one file makes bounded review and context reuse needlessly
expensive. Downloading each source module separately would reduce source-file
size while multiplying network, identity, partial-download, and release-asset
failure states. Loading from a moving branch, an unverified cache, or downloaded
text would violate the existing supply-chain boundary.

The maintainer's selected consumer target can also differ from the runtime
release that supplied the current launcher. A launcher downloaded from the
latest release must remain able to adopt a compatible older `-ProtocolTag`;
therefore runtime and consumer-target identity cannot be conflated.

## Decision

Keep `Invoke-MeAndAIQuickAdoption.ps1` as the sole maintainer-invoked entry
point, but make it a small source-only bootstrapper. The tracked implementation
is split into cohesive PowerShell module files. Each new immutable release
publishes exactly two release assets: the reviewed thin launcher and one
deterministically built `MeAndAI.QuickAdoption.Bundle.zip`. The generated ZIP
is release output and is never committed.

The bootstrapper carries a canonical `RuntimeReleaseTag` identifying the
release that owns its code. `-ProtocolTag` retains its independent meaning as
the requested consumer protocol target. Before importing any downloaded code,
the bootstrapper verifies its exact published immutable runtime release,
tag-resolved commit, unique bundle asset, API digest, downloaded byte length
and digest, bounded archive inventory, canonical manifest, source commit,
entry point, and every payload length and SHA-256. It rejects missing, extra,
duplicate, case-colliding, absolute, traversal, backslash, linked/reparse, or
oversized entries. Extraction and module import occur only in a unique temporary
directory outside the consumer repository. The module exposes only the public
adoption entry point; module removal and exact temporary-root cleanup occur on
success and failure.

The bundle is fetched as one release asset, never as independent module
downloads. No moving-ref, unverified-cache, old-monolith, or partial-module
fallback exists. The first version adds no persistent cache. The builder
requires one clean exact source commit and reads one explicit ordered inventory
and every payload as exact regular Git blobs from that commit. Fixed ZIP
metadata and deterministic no-compression entries make repeated builds from one
exact source identity produce identical output. Publication and post-publication
verification cover both assets, their API and downloaded digests, and the
bundle manifest's exact release identity.

Existing credential, consumer-repository, semantic adoption, current-launcher
recovery, no-auto-merge, and maintainer-review boundaries remain unchanged.
No consumer mutation or write credential reaches downloaded code until the
complete runtime bundle has been verified and imported.

## Consequences

- Maintainers keep one download and one local invocation while reviewers and
  agents can load only the module relevant to a change.
- A release has one additional asset and a small deterministic build step, but
  avoids per-module network fan-out and partial runtime assembly.
- The bootstrapper necessarily contains a compact duplicate of the minimum
  release/download/archive trust code. That code may not delegate to the
  unverified bundle and receives its own focused negative test table.
- Runtime release and requested protocol release are explicit semantic types,
  preventing an older target selection from looking for a bundle in that older
  release.
- Historical v0.9.2 single-file releases and [TEST-0101](../features/FEAT-0017-v092-single-file-quick-adoption/test-cases.md#test-0101) remain truthful for the
  versions that used them. [FEAT-0036](../features/FEAT-0036-modular-quick-adoption-reliability/README.md)/[TEST-0147](../features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) own the new prospective contract.
- Publication must build and upload both exact assets before the GitHub Release
  becomes immutable and must record both digests externally.

## Alternatives considered

- Keep the monolith: rejected because it preserves the review, maintenance,
  context, and token cost that triggered this work.
- Download raw modules one by one: rejected because it multiplies authenticated
  requests, asset verification, incomplete state, and failure recovery.
- Commit the generated ZIP: rejected because release output would duplicate
  source, create noisy binary diffs, and invite stale artifacts.
- Use PowerShell Gallery or another package manager: rejected because it adds a
  second publication and trust authority without solving a current requirement.
- Fetch from `main` or execute a response string: rejected because source is
  movable and violates immutable-release and no-pipe-to-shell rules.
- Add a persistent cache immediately: rejected because cache identity,
  permissions, eviction, and poisoning are not needed for the first bounded
  correction.

## Review condition

Review if GitHub Release assets cannot provide immutable digest evidence, the
bundle becomes large enough that bounded extraction is no longer practical,
PowerShell's module/archive behavior changes across supported runtimes, or a
first-party signed package mechanism can preserve the same exact release,
consumer containment, and one-command guarantees with less custom code.
