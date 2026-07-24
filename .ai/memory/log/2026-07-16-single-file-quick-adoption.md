# 2026-07-16 - Single-File Quick Adoption

## Scope

- Work item: [FEAT-0017](../../../docs/features/FEAT-0017-v092-single-file-quick-adoption/README.md)
- Tracking and post-publication authority: [issue #51](https://github.com/hasanmanzak/meAndAI/issues/51)
- Delivery review: [pull request #52](https://github.com/hasanmanzak/meAndAI/pull/52)
- Test: [`TEST-0101`](../../../docs/features/FEAT-0017-v092-single-file-quick-adoption/test-cases.md)
- Target version: `0.9.2`

## Durable continuation

- `scripts/Invoke-MeAndAIQuickAdoption.ps1` remains the only quick-adoption
  launcher. Do not add a second bootstrap or installer merely to shorten the
  user command.
- Publish that exact tracked file as the named
  `Invoke-MeAndAIQuickAdoption.ps1` asset in the immutable `v0.9.2` release.
- Maintainers download the reusable asset outside consumer repositories, open
  PowerShell in the target directory, and run one explicit `-File` invocation
  with `-TargetPath .`.
- The launcher retains exact immutable-release validation before canonical
  source use. Moving refs, `Invoke-Expression`, and pipe-to-shell execution are
  outside the approved boundary.
- After publication, record the release asset name, API-reported SHA-256
  digest, merged-file SHA-256 digest, exact release commit, and hosted check in
  [issue #51](https://github.com/hasanmanzak/meAndAI/issues/51). Do not predict those values in repository documents.
- Local confirmation passed every discovered suite in 460 seconds, including
  the existing quick-adoption regressions and source-bound [TEST-0101](../../../docs/features/FEAT-0017-v092-single-file-quick-adoption/test-cases.md). No
  unresolved local `Blocking` finding remains.
