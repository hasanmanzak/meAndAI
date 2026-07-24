# FEAT-0027 - v0.10.4 Hosted Runner-Minute Efficiency

| Field | Value |
| --- | --- |
| Classification | Test infrastructure and protocol discipline feature |
| Status | Complete |
| Target version | 0.10.4 |
| Issue | [#72](https://github.com/hasanmanzak/meAndAI/issues/72) |
| Pull request | [#73](https://github.com/hasanmanzak/meAndAI/pull/73) |
| Decision | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md) |
| Tests | [TEST-0123](test-cases.md) and [TEST-0124](test-cases.md) |

## Problem and intended outcome

Ordinary validation currently starts one canonical Linux job, eight Windows
jobs, and a separate Ubuntu aggregate. The Windows matrix reduces wall-clock
latency, but duplicates checkout, fixture construction, and short-job overhead
while repeating platform-neutral behavior already owned by the Linux full
suite. Documentation-only and governance-only changes pay the same hosted cost
as launcher or PowerShell changes.

Retain canonical full evidence on Linux and the stable Windows required-check
identity, while using exactly one Windows runner per ordinary workflow run.
That runner must select a focused native-compatibility profile for
platform-neutral changes and the complete PowerShell 5.1 suite whenever the
actual diff can affect PowerShell, workflow, command-wrapper, or migration
behavior. Ambiguous classification must select the full suite.

## Scope

- Add a common-protocol mandate requiring hosted workflows to minimize total
  runner consumption without weakening declared risk coverage.
- Replace the Windows base job, seven-job matrix, and Ubuntu aggregate with one
  real Windows job named `Validate on windows-latest`.
- Select `WindowsNative` or `Full` from the checked-out Git diff, not from
  GitHub's bounded path-filter result.
- Treat PowerShell scripts/modules/data files, command wrappers, workflow
  definitions, and migration definitions as full-Windows-sensitive.
- Run full Windows validation for manual ordinary dispatch, merge-queue events,
  invalid or unavailable diff evidence, empty/oversized change sets, and every
  sensitive rename, deletion, or modification.
- Keep release-only post-publication dispatch isolated from ordinary Linux and
  Windows validation.
- Cancel only superseded runs for the same pull request; never let pull-request
  concurrency cancel main, manual, merge-queue, or publication evidence.
- Preserve the existing focused quick-adoption shards as local diagnostic
  entry points without expanding them into hosted matrix jobs.

## Non-goals

- Removing native Windows or Windows PowerShell 5.1 support.
- Making elapsed time a flaky pass/fail threshold.
- Adding a self-hosted runner, cache service, scheduler, or persistent fixture
  coordinator.
- Using workflow-level path filters for a required check.
- Treating a partial compatibility run as canonical full-suite evidence.
- Weakening immutable-release, migration, adoption, or post-publication gates.

## Contracts and risks

### Validation authority

- `Full` remains the only profile that emits canonical root scenario evidence.
- `WindowsNative` runs the existing contracts containing `.cmd`/`ComSpec`,
  native sandbox, process-tree cancellation, and linked/reparse behavior and
  emits compatibility-only evidence.
- `Validate on windows-latest` is the actual Windows job; no fan-in runner
  exists solely to rename another job's result.

### Diff classification

- Pull requests compare their exact base and head commits; pushes compare the
  event's exact before and after commits.
- Rename detection is disabled so both the removed path and added path are
  classified. Any `.ps1`, `.psm1`, `.psd1`, `.cmd`, workflow YAML, or migration
  JSON path requires `Full`.
- Manual ordinary dispatch and merge-queue validation require `Full`.
- Missing objects, malformed identities, diff failure, no observable paths, or
  more than 300 changed paths fail safe to `Full`.

| ID | Classification | Risk | Response and required evidence |
| --- | --- | --- | --- |
| `RISK-0119` | Coverage | A sensitive path is misclassified as native-only | Broad explicit sensitive extensions/directories, rename-disabled Git diff, fail-safe `Full`, [TEST-0123](test-cases.md) |
| `RISK-0120` | Evidence integrity | A partial Windows run claims the canonical scenario set | Compatibility-only result parser and profile boundary, [TEST-0124](test-cases.md) |
| `RISK-0121` | Required-check continuity | Conditional workflows or renamed jobs leave branch protection pending or ambiguous | One always-present job keeps the exact `Validate on windows-latest` name; no workflow-level path filter or duplicate name, [TEST-0124](test-cases.md) |
| `RISK-0122` | Cancellation | A newer PR run cancels main, manual, merge-queue, or publication evidence | Workflow-and-PR-scoped group with cancellation enabled only for pull requests, [TEST-0124](test-cases.md) |

## Definition of Ready

- [x] Stable `FEAT-0027`, `SUBF-0049`, `SUBF-0050`, [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md),
      [TEST-0123](test-cases.md), [TEST-0124](test-cases.md), and [issue #72](https://github.com/hasanmanzak/meAndAI/issues/72) exist.
- [x] Runner authority, semantic profile, diff identity, sensitive path,
      ambiguity, cancellation, evidence, and release-routing contracts are
      explicit.
- [x] Scope preserves native Windows coverage and excludes hosted framework or
      timing-gate expansion.
- [x] Prior [FEAT-0024](../FEAT-0024-v0101-parallel-windows-validation/README.md)/[FEAT-0025](../FEAT-0025-v0102-balanced-windows-validation/README.md) orchestration and current hosted durations were
      reviewed.
- [x] Work is decomposed into the protocol/routing slice and focused native
      compatibility slice.
- [x] Numbered success, negative, boundary, routing, and compatibility
      scenarios are defined.
- [x] Test code state is planned; immutable v0.10.3 is the green baseline.

## Acceptance criteria

1. The protocol requires workflows to minimize total hosted runner consumption
   while preserving declared platform, runtime, safety, and evidence coverage.
2. Ordinary validation contains one Linux canonical-full job, one actual
   Windows job named `Validate on windows-latest`, and no Windows matrix or
   aggregate-only runner.
3. A project-neutral change selects `WindowsNative`; a sensitive modification,
   deletion, or rename selects `Full`; malformed, unavailable, empty, or
   oversized diff evidence also selects `Full`.
4. Manual ordinary dispatch and merge-queue validation select `Full`, while an
   explicit post-publication dispatch runs only the release verifier.
5. `WindowsNative` proves PowerShell 5.1 launcher parsing/execution, `.cmd`
   command resolution, native sandbox fallback/failure/residue, child-process
   cancellation, and junction/reparse containment without canonical evidence
   leakage.
6. Only an older run for the same pull request may be cancelled automatically.
7. The full PowerShell 5.1 route executes every canonical suite serially once;
   focused diagnostic shards remain available locally but are not hosted
   matrix children.
8. Structure, selector, focused native, complete local, actionlint, hosted, and
   bounded review evidence pass with no unresolved blocking finding.

## Decomposition and review gates

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0049` | Runner-efficiency mandate, fail-safe profile selector, single-job workflow, and PR-only concurrency | [Issue #72](https://github.com/hasanmanzak/meAndAI/issues/72) | [TEST-0123](test-cases.md), [TEST-0124](test-cases.md) | Selector fixtures, structure validation, and the bounded fresh-diff review pass | Complete |
| `SUBF-0050` | Compatibility-only `WindowsNative` execution across launcher and streaming/process-tree evidence | [Issue #72](https://github.com/hasanmanzak/meAndAI/issues/72) | [TEST-0124](test-cases.md) | PowerShell 5.1 profile passed in 187.1 seconds with compatibility-only evidence; the complete suite passed in 577.7 seconds | Complete |

## Verification approach

Add selector and topology assertions first and record their expected failure on
the v0.10.3 matrix. Implement the pure selector and focused profiles, then run
selector fixtures, structure validation, both Windows-native partial suites,
one complete local suite, one bounded fresh-diff review, and the mandatory
post-development scan. Push only the converged branch so hosted CI is used as
external evidence rather than an iterative debugger. Hosted durations and
total job counts are observations, not timing gates.

## Relationships

- Previous parallel layout: [FEAT-0024](../FEAT-0024-v0101-parallel-windows-validation/README.md)
- Balanced shard layout: [FEAT-0025](../FEAT-0025-v0102-balanced-windows-validation/README.md)
- Stability mandate: [FEAT-0015](../FEAT-0015-stability-consistency-mandate/README.md)
- Decision: [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md)
- Tracking and post-publication authority: [issue #72](https://github.com/hasanmanzak/meAndAI/issues/72)

## Self-review state

The test-first structure contract removed the hosted fan-out and aggregate
topology, retained each local diagnostic shard, and rejected canonical
scenario output from both partial suites. The fail-safe selector uses exact
checked-out commits, disables rename detection, and sends every sensitive or
ambiguous case to `Full`. Focused native and complete PowerShell 5.1 evidence
passed, and the bounded fresh-diff review found no unresolved blocker.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario ownership complete.
- [x] Focused and complete test commands pass.
- [x] Both subfeature reviews and the bounded post-development scan converge
      with no unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory agree.
- [ ] Applicable hosted checks pass.
- [ ] Pull request, merge, exact branch cleanup, immutable release, and
      post-publication evidence complete.

## Publication authority

[Issue #72](https://github.com/hasanmanzak/meAndAI/issues/72) owns exact hosted
run, merge, branch-deletion, immutable v0.10.4 release, asset, and
post-publication facts after they exist. This record does not project them.
