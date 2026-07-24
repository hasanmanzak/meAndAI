# 2026-07-16 - v0.9.3 Live Adoption PR Metadata Correction

## Scope

- Work item: [FEAT-0018](../../../docs/features/FEAT-0018-v093-live-pr-metadata-correction/README.md)
- Defect and post-publication authority: [issue #53](https://github.com/hasanmanzak/meAndAI/issues/53)
- Test: [`TEST-0102`](../../../docs/features/FEAT-0018-v093-live-pr-metadata-correction/test-cases.md#test-0102)
- Target version: `0.9.3`
- Consumer reproduction: affected external proposal recorded in [issue #53](https://github.com/hasanmanzak/meAndAI/issues/53)

## Durable continuation

- The `v0.9.2` launcher expected the unavailable
  `headRepository.nameWithOwner` property after a successful lifecycle run.
- Live GitHub CLI evidence exposes `headRepository.name`,
  `headRepositoryOwner.login`, and Boolean `isCrossRepository`; the corrected
  launcher validates those fields as one canonical repository identity.
- [TEST-0102](../../../docs/features/FEAT-0018-v093-live-pr-metadata-correction/test-cases.md#test-0102) replaces the synthetic fixture shape, asserts the requested JSON
  fields, accepts the same-repository draft, and rejects name, owner,
  cross-repository, and type drift before local Codex or Git mutation.
- The affected consumer's secrets, seed, successful workflow run, adoption branch, and draft
  remain intact. Run the corrected `v0.9.3` launcher asset with
  `-ProtocolTag v0.9.2` to reuse that exact proposal; do not close, delete, or
  retarget it merely because the old launcher stopped. After maintainer merge,
  the installed updater may propose the ordinary `v0.9.3` upgrade.
- The launcher remains the sole quick-adoption script. No wrapper, workflow,
  bootstrap layer, credential change, or automatic merge is introduced.
- Exact `v0.9.3` release, commit, asset digest, hosted checks, and affected-consumer
  continuation evidence remain pending until publication and belong in [issue
  #53](https://github.com/hasanmanzak/meAndAI/issues/53) and the GitHub Release.
