# v0.14.5 Bare Document Basename Links

## Scope

- [FEAT-0050](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/README.md)
- [BUG-0033 / issue #121](https://github.com/hasanmanzak/meAndAI/issues/121)
- [SUBF-0094](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/README.md#subf-0094)
- [TEST-0182](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182)

## Current state

- Immutable [v0.14.4](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.4)
  targets exact commit
  [`edf4c5d496df239aeb3f14c03b7109215af9128f`](https://github.com/hasanmanzak/meAndAI/commit/edf4c5d496df239aeb3f14c03b7109215af9128f).
- A retained `v0.14.3` decision uses a valid nested link to
  [AGENTS.md](../../../AGENTS.md). Current publication authority rejected it by
  interpreting the visible basename as a source-relative full path.
- The project-neutral [TEST-0182](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182)
  reproduces the false positive and rejects a same-label link to
  [PROTOCOL.md](../../../PROTOCOL.md). The correction is limited to the shared
  publication verifier.
- Directory-bearing labels, target resolution, case, fragments, consumers,
  historical releases, and release-asset topology remain unchanged.

## Continuation

1. Complete bounded structure and aggregate validation.
2. Publish one reviewed pull request and immutable `v0.14.5` under
   [issue #121](https://github.com/hasanmanzak/meAndAI/issues/121).
3. Run `v0.14.5`, then rerun `v0.14.4`, `v0.14.3`, and `v0.14.2` publication
   evidence with current verifier authority; close retained issues only after
   exact green evidence.
4. Delete only the exact owned delivery branch after merge and verification.

## Boundaries

- Do not add another parser, validator, fixture framework, or consumer patch.
- Do not edit an immutable historical release merely to satisfy the verifier.
- Do not relax directory-bearing visible paths or fragment matching.
