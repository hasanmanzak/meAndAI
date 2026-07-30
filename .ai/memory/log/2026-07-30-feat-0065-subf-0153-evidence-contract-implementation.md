# 2026-07-30 - Evidence-contract local activation candidate

## Authority and predecessor

- The maintainer's
  [activation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5135051435)
  authorizes the bounded Gate 3 implementation and atomic workflow/scenario-
  owner activation for
  [SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
  and
  [TEST-0221](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221).
- The local candidate is on
  `codex/subf-0153-evidence-contract-implementation` from predecessor
  `23d27478af09446363bcb299dee24957e3a206a7`.
- The accepted
  [evidence-contract design](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0153-evidence-contract-design.md)
  remains the exact implementation boundary.

## Local candidate evidence

- The valid red compiled the public-API reflection oracle, discovered its one selected
  test, and failed 1 of 1 solely because the normative 23-type slice inventory
  was absent.
- A separate `NETSDK1064` package-cache attempt is discarded. It is not valid
  red or regression evidence and must not be cited as such.
- Final focused
  [TEST-0221](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
  is `Passing`; its current owner is the existing
  `tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj`
  project, with 46 passed, zero failed, zero skipped.
- The combined
  [TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)/[TEST-0221](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
  run is 98 passed, zero failed, zero skipped.
- The explicit Release build completed with zero warnings and zero errors;
  format verification is clean.
- Gate 5 removed the private `CanonicalEvidencePayload` constructor reflection
  oracle and strengthened public-observable construction, bounded null/error/
  length/equality/order, and defensive-ownership coverage.
- Lock-file hashes are unchanged. Project, package, solution, and lock files are
  unchanged.
- These are local working-tree activation-candidate facts only. They do not
  establish or claim a candidate commit, pull request, hosted run, merge,
  committed exact tree, or exact-head validation.

## Activation boundary

- Workflow and scenario-owner activation authorized by the exact directive
  above is applied atomically to the candidate; local
  [TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  activation evidence is green.
- No project/package/solution/lock mutation, WIP extraction, consumer change,
  release/publication, authority transfer, or PowerShell retirement belongs to
  this slice.
- [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  Gate 2 is accepted, merged, and bounded on exact `main`
  `23d27478af09446363bcb299dee24957e3a206a7`, while
  [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned` with no executable source or run evidence.
- Gate 3 remains unauthorized until
  [SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
  is merged and validated on exact `main` and a separate implementation
  directive is issued.

## Pending closure

Review the complete candidate packet, then create and validate real commit,
pull-request, hosted, merge, and exact-main evidence in sequence. Record those
facts only after they exist.
