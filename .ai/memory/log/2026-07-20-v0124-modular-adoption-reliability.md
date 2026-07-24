# 2026-07-20 - v0.12.4 Modular Adoption Reliability Handoff

## Status

- Feature: [FEAT-0036](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md)
- Decision: [DEC-0023](../../../docs/decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
- Delivery and post-publication authority: [issue #89](https://github.com/hasanmanzak/meAndAI/issues/89)
- Candidate version: `0.12.4`
- State: [PR #90](https://github.com/hasanmanzak/meAndAI/pull/90) merged at `bb18a4ac697a9c1e07f26f9e26bfcc35643f9972`;
  the focused [BUG-0020](https://github.com/hasanmanzak/meAndAI/issues/89) release-builder hotfix is locally validated. Its
  hotfix PR, hosted checks, merge, immutable release, live Derdini replay,
  superseded [PR #6](https://github.com/hasanmanzak/Derdini/pull/6), stale [issue #7](https://github.com/hasanmanzak/Derdini/issues/7), and branch/issue cleanup evidence remain
  pending.

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
- [BUG-0018](https://github.com/hasanmanzak/meAndAI/issues/89) is corrected by bounded retry only for explicitly idempotent
  GitHub API GET reads. [BUG-0019](https://github.com/hasanmanzak/meAndAI/issues/89) is corrected by UTF-8-no-BOM body-file
  transport and a fail-closed repair for only the exact historical
  quote-stripped schema-2 issue.
- After [PR #90](https://github.com/hasanmanzak/meAndAI/pull/90) merged at `bb18a4ac697a9c1e07f26f9e26bfcc35643f9972`,
  the first exact release build exposed [BUG-0020](https://github.com/hasanmanzak/meAndAI/issues/89): Windows PowerShell 5.1
  evaluated the builder's `$PSScriptRoot` parameter default before initializing
  it. The default is now resolved after binding only when `SourceRoot` is
  omitted.

## Focused evidence

- Final [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md): Windows PowerShell 5.1 passed in 17.7 seconds.
- Post-[BUG-0020](https://github.com/hasanmanzak/meAndAI/issues/89) [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md): Windows PowerShell 5.1 passed in 21.3 seconds,
  including a real child `powershell.exe -File` builder invocation without
  `SourceRoot` and byte equality with explicit-root builds.
- [TEST-0148](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) and [TEST-0149](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md): Windows PowerShell 5.1 passed together in 23.4
  seconds, including repair of the stale v0.12.1 poisoned issue while targeting
  v0.12.4.
- Focused publication-evidence verification passed in 1.7 seconds. The
  canonical consumer-update suite, three affected quick-adoption shards, and
  final structure validation also passed.

## Continue from here

Create only the bounded [BUG-0020](https://github.com/hasanmanzak/meAndAI/issues/89) hotfix PR. After its required hosted checks
and review pass, merge, publish the exact two-asset immutable v0.12.4 release,
verify both downloads and bundle identity, replay adoption against Derdini,
reconcile the superseded [PR #6](https://github.com/hasanmanzak/Derdini/pull/6) and stale [issue #7](https://github.com/hasanmanzak/Derdini/issues/7) only through verified
lifecycle evidence, and record PR/release/live cleanup facts externally in
[issue #89](https://github.com/hasanmanzak/meAndAI/issues/89). Do not create a repository commit merely to copy those later
external facts.
