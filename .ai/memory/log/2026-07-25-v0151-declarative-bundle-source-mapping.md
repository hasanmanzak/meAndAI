# v0.15.1 Declarative Bundle Source Mapping

Date: 2026-07-25
Status: In progress
Feature: [FEAT-0052](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/README.md)
Issue: [BUG-0034](https://github.com/hasanmanzak/meAndAI/issues/131) /
[issue #131](https://github.com/hasanmanzak/meAndAI/issues/131)

## Trigger

The immutable [v0.15.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.0)
bundle is internally valid, but current post-publication
[run 30176928208](https://github.com/hasanmanzak/meAndAI/actions/runs/30176928208)
requested a nonexistent repository source by deriving it from a runtime bundle
path. The builder already carried a separate path-specific exception, and its
test repeated that exception. The failure therefore belongs to the common
mapping contract, not to a consumer or to the immutable release payload.

## Accepted correction

- `bundle.sources.json` schema 2 declares an ordered `bundlePath` and
  `repositoryPath` for every payload.
- The builder reads exact tracked Git-blob bytes from `repositoryPath` and
  writes the unchanged runtime identity at `bundlePath`.
- The publication verifier fetches the declared repository path and compares
  it with the declared bundle payload.
- A narrow schema-1 adapter exists only for immutable releases `v0.12.4`
  through `v0.15.0`; `v0.15.1` and later require schema 2.
- [TEST-0189](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189)
  stays in the existing publication-evidence owner, while
  [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147)
  remains the existing builder/bundle owner. No new suite or consumer test is
  added.

## Continuation

1. Focused
   [TEST-0189](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189)
   / [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147)
   evidence is complete; retain the exact results in the feature record.
2. Bounded fresh-diff review and focused governance are complete; the one
   final canonical suite passed on Windows PowerShell 5.1 in 2,081.2 seconds.
3. Merge the owned pull request and publish immutable `v0.15.1` with the
   established two assets.
4. Verify both historical `v0.15.0` and new `v0.15.1` through current
   authority, then close
   [issue #131](https://github.com/hasanmanzak/meAndAI/issues/131) and clean the
   owned branch.
5. Reevaluate [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
   against the completed test architecture, including repeated tests and
   tests-that-test-tests.
