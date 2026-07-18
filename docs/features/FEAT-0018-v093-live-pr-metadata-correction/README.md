# FEAT-0018 - v0.9.3 Live Adoption PR Metadata Correction

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.9.3 |
| Issue | [#53](https://github.com/hasanmanzak/meAndAI/issues/53) |
| Pull request | [#54](https://github.com/hasanmanzak/meAndAI/pull/54) |
| Decisions | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md), [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md), [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md) |
| Tests | [TEST-0102](test-cases.md) |

## Problem and intended outcome

The immutable `v0.9.2` launcher creates a valid deterministic adoption draft
and then rejects it before local Codex execution. The launcher expects
`headRepository.nameWithOwner`, but the live GitHub CLI pull-request shape
exposes `headRepository.name`, `headRepositoryOwner.login`, and
`isCrossRepository`. The test double invented the unavailable property and
therefore hid the integration-contract defect.

Correct the existing validation boundary so the launcher accepts only the
same-repository draft represented by the real GitHub CLI contract and can
resume the retained proposal. Foreign, cross-repository, malformed, or
ambiguously typed metadata must still fail before local semantic work.
An incomplete `v0.9.2` adoption uses the corrected `v0.9.3` launcher code with
`-ProtocolTag v0.9.2`; changing the retained proposal's target is not part of
recovery.

## Scope and non-goals

- Request the real repository-name, repository-owner, and cross-repository
  fields from `gh pr list`.
- Reconstruct and compare the canonical `owner/repository` identity from those
  fields using ordinal case-insensitive comparison.
- Require `isCrossRepository` to be a Boolean `false` and retain the existing
  branch, actor, marker, head, base, draft, and state checks.
- Replace the convenient PR mock shape with the observed GitHub CLI shape and
  cover repository-name, owner, cross-repository, and type failures.
- Advance current protocol and adoption pins to corrective release `0.9.3`
  while leaving historical release records unchanged.

No new launcher, wrapper, workflow, bootstrap layer, credential behavior,
Codex execution behavior, adoption content, automatic merge, or destructive
consumer cleanup is in scope. The retained affected-consumer draft is continuation
evidence, not content owned by this repository change.

## Contracts, risks, and verification

The input contract is the JSON emitted by `gh pr list`: repository name and
owner are distinct objects, and cross-repository state is a Boolean. Missing
properties, null objects, invalid types, identity mismatches, and a true
cross-repository flag fail closed. The canonical target repository remains the
already authenticated `nameWithOwner` returned by `gh repo view`.

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0088` | External contract fidelity | A test double can drift from the GitHub CLI JSON contract and produce another false green | Mitigated by launcher maintainer | `TEST-0102` uses the observed object shape, asserts the requested fields, and removes `nameWithOwner` from the PR fixture |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0102](test-cases.md) |
| Test code | Planned before production change | Real-shape fixture and negative variants in `tests/quick-adoption.tests.ps1` |
| Baseline run | Reproduced externally | The successful run and falsely rejected same-repository draft are recorded in [issue #53](https://github.com/hasanmanzak/meAndAI/issues/53) |

The correction is one small reviewable slice; subfeature decomposition would
add no independent value. Verification is bounded to one expected-red focused
run, one focused green run, one fresh-diff review, one complete repository
gate, and the protocol's single post-development convergence scan. A
confirmation scan is used only if remediation changes the tree.

## Definition of Ready

- [x] Stable `FEAT-0018` and `BUG-0006` identifiers and linked issue #53 exist.
- [x] Problem, outcome, scope, non-goals, consumers, compatibility, errors,
      ownership, lifecycle, and external JSON type contracts are explicit.
- [x] Existing decisions remain sufficient; no architecture change is needed.
- [x] The change is one bounded independently testable slice.
- [x] `TEST-0102` covers live-shape success and identity/type failures.
- [x] Test-code and baseline states and the finite validation budget are
      recorded before production implementation.

## Acceptance criteria

1. The launcher requests and validates `headRepository.name`,
   `headRepositoryOwner.login`, and Boolean `isCrossRepository` from the real
   GitHub CLI pull-request contract.
2. The retained same-repository affected-consumer draft passes repository-origin
   validation when the corrected launcher retains `-ProtocolTag v0.9.2`,
   without weakening the existing branch, head, actor, marker, draft, base, or
   state gates.
3. Repository-name mismatch, owner mismatch, cross-repository state, and a
   non-Boolean cross-repository value fail before local Codex or Git mutation.
4. The executable test fixture contains no synthetic
   `headRepository.nameWithOwner` property and verifies the production JSON
   field request.
5. Current pins and the published launcher advance to immutable `v0.9.3`, and
   existing quick-adoption and repository tests remain green.

## Implementation and verification approach

First replace the pull-request test double with the observed GitHub CLI shape
and demonstrate the existing launcher fails `TEST-0102`. Then update only the
existing PR metadata validator and requested field list, advance active pins,
and update canonical records. No generalized GitHub model or validator is
introduced.

## Self-review and convergence

The 2026-07-16 fresh-diff review covered the changed PR-resolution flow and its
callers for exact field and type semantics, fail-closed ordering, duplication,
compatibility, test realism, version pins, links, memory, and release evidence.
PowerShell AST parsing and `git diff --check` passed. The live GitHub CLI output
was compared with the fixture: the PR projection has distinct repository name
and owner objects plus a Boolean cross-repository field, while `gh repo view`
legitimately retains its separate `nameWithOwner` contract.

| ID | Classification / priority | Finding and resolution | Status |
| --- | --- | --- | --- |
| `FIND-0150` | Recovery compatibility / P1 | A corrected launcher using its new default `v0.9.3` target would reject the exact retained `v0.9.2` seed before reaching its draft. Recovery now explicitly runs the corrected asset with `-ProtocolTag v0.9.2`, preserves the original proposal, and leaves the later upgrade to the installed updater. | `Blocking` / Resolved in the guide, feature, and memory continuation |
| `FIND-0151` | Test pin consistency / P1 | Three regex-escaped release/source matchers retained `v0\.9\.2` after the ordinary active-pin change. They now target `v0\.9\.3`, and a focused escaped-pin search is clean before the complete suite. | `Blocking` / Resolved before final verification |

The project scan scope is the complete tracked repository: inventory and Git
hygiene, architecture and decisions, launcher correctness and state flow,
duplication, test realism and scenario ownership, documentation and links,
version and memory consistency, and relevant credential/supply-chain controls.
Generated Git internals, GitHub's service implementation, and consumer-owned
content are excluded. The finite budget is one initial scan and one
confirmation only after remediation. Candidate completion is reopened by any
failed complete-suite, hosted-CI, or review evidence.

The complete repository suite passed all discovered suites in 474.6 seconds,
including machine-readable `TEST-0102` evidence. The post-development scan
found no unresolved `Blocking` observation after the two pre-scan corrections.
That clean initial scan is the convergence evidence; an unchanged confirmation
scan is prohibited. Hosted CI and publication remain external delivery gates.

## Relationships

- Corrects launcher behavior from [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Corrects the distributed `v0.9.2` artifact from [FEAT-0017](../FEAT-0017-v092-single-file-quick-adoption/README.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking and post-publication authority: [issue #53](https://github.com/hasanmanzak/meAndAI/issues/53)
- Delivery: [pull request #54](https://github.com/hasanmanzak/meAndAI/pull/54)
- External consumer reproduction: [issue #53](https://github.com/hasanmanzak/meAndAI/issues/53)

## Definition of Done

- [x] Acceptance criteria and `TEST-0102` pass.
- [x] Existing quick-adoption scenarios and the complete repository suite pass.
- [x] Fresh-diff review and the bounded project scan leave no unresolved
      `Blocking` finding.
- [x] Version, changelog, guide, links, feature index, and project memory agree.
- [x] Issue and pull request link the canonical records and validation evidence.

## Post-merge publication gate

Issue #53 is the external authority for the exact merged commit, immutable
`v0.9.3` release, launcher asset digest, hosted checks, and the affected-consumer
continuation result after those facts exist.
