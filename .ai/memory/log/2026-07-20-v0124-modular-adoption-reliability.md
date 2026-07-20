# 2026-07-20 - v0.12.4 Modular Adoption Reliability Handoff

## Status

- Feature: [FEAT-0036](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md)
- Decision: [DEC-0023](../../../docs/decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
- Delivery and post-publication authority: [issue #89](https://github.com/hasanmanzak/meAndAI/issues/89)
- Candidate version: `0.12.4`
- State: local pre-merge candidate complete; PR, hosted checks, merge, immutable release, live Derdini
  replay, superseded PR #6, stale issue #7, and branch/issue cleanup evidence
  remain pending.

## Implemented candidate

- The maintainer still downloads and invokes one thin
  `Invoke-MeAndAIQuickAdoption.ps1`. The release contract contains exactly two
  assets: that launcher and one internal
  `MeAndAI.QuickAdoption.Bundle.zip`.
- The deterministic builder requires one clean exact source commit and reads
  its ordered inventory and payloads as exact regular Git blobs. The generated
  ZIP is not committed.
- The launcher verifies its immutable `RuntimeReleaseTag`, tag commit, unique
  asset and digest, archive inventory, manifest, entry point, and every payload
  before importing outside the consumer. `-ProtocolTag` independently selects
  the compatible consumer target.
- A present `MEANDAI_RO_FG_PAT.txt` may authenticate only the exact runtime
  read through invocation-scoped `GH_TOKEN`; the previous environment is
  restored and the value cleared before imported code runs.
- `BUG-0018` is corrected by bounded retry only for explicitly idempotent
  GitHub API GET reads. `BUG-0019` is corrected by UTF-8-no-BOM body-file
  transport and a fail-closed repair for only the exact historical
  quote-stripped schema-2 issue.

## Focused evidence

- Final `TEST-0147`: Windows PowerShell 5.1 passed in 17.7 seconds.
- `TEST-0148` and `TEST-0149`: Windows PowerShell 5.1 passed together in 23.4
  seconds, including repair of the stale v0.12.1 poisoned issue while targeting
  v0.12.4.
- Focused publication-evidence verification passed in 1.7 seconds. The
  canonical consumer-update suite, three affected quick-adoption shards, and
  final structure validation also passed.

## Continue from here

Run only the remaining bounded convergence evidence, then create one converged
push and PR. After required hosted checks and review pass, merge, publish the
exact two-asset immutable v0.12.4 release, verify both downloads and bundle
identity, replay adoption against Derdini, reconcile the superseded PR #6 and
stale issue #7 only through verified lifecycle evidence, and record
PR/release/live cleanup facts externally in issue #89. Do not create a
repository commit merely to copy those later external facts.
