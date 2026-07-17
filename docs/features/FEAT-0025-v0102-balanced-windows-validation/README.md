# FEAT-0025 - v0.10.2 Balanced Windows Integrity Validation and Isolated Publication Verification

| Field | Value |
| --- | --- |
| Classification | Performance / test orchestration correction |
| Status | Complete |
| Target version | 0.10.2 |
| Issue | [#67](https://github.com/hasanmanzak/meAndAI/issues/67) |
| Pull request | Pending |
| Related decisions | [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md) |
| Tests | [TEST-0117 and TEST-0118](test-cases.md) |

## Problem and intended outcome

FEAT-0024 reduced the hosted Windows critical path from 558 seconds to between
251 and 326 seconds, but one `IntegrityFailures` shard still expands about 55
launcher executions and hundreds of local Git/process operations into a single
239-to-308-second test step. The Windows base and Linux full test steps were
otherwise close at 137-to-180 and 132-to-153 seconds.

The release-evidence dispatch also reruns the complete ordinary validation
matrix even though its authority is the dedicated read-only verifier. Balance
the Windows compatibility work across semantic process boundaries and isolate
publication verification from ordinary CI without reducing coverage.

## Scope

- Replace `IntegrityFailures` with four independently executable compatibility
  shards: `IntegrityCompletedGraph`, `IntegrityManifestIssue`,
  `IntegrityCodexFailure`, and `IntegrityMetadataCredential`.
- Give every partial integrity shard a fresh completed-adoption baseline while
  preserving the existing sequential state transitions for `Shard=All`.
- Keep Linux full execution as canonical scenario evidence and every partial
  Windows result compatibility-only.
- Skip ordinary Linux, Windows base, Windows shard, and aggregate jobs only for
  an explicit `verify_post_publication=true` workflow dispatch.

## Non-goals

- Reducing or moving Windows PowerShell 5.1 coverage.
- Sharing mutable proposal builders, consumer repositories, remotes, or mocks.
- Refactoring production launcher behavior or replacing integration cases with
  unit-only evidence.
- Adding a duration threshold, scheduler, persistent cache, or runner service.
- Splitting the Windows base profile in this correction.

## Contracts and risks

- `Shard=All` retains the exact canonical execution order and is the only mode
  that emits `MEANDAI_SCENARIO_RESULTS`.
- Each named partial shard initializes its own mutable completed-adoption
  baseline and emits only `MEANDAI_COMPATIBILITY_SHARD_RESULT`.
- The aggregate `Validate on windows-latest` check keeps its name and requires
  the Windows base job plus all seven matrix children.
- Pull-request, push, and ordinary manual-dispatch events retain normal CI.
  Only the explicit release-evidence dispatch skips it, and that dispatch must
  run the positive post-publication verifier without `needs` dependencies.

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0109` | State isolation | A new partial shard depends on mutable state produced by another shard | Mitigating / test maintainer | Independent completed baseline per partial shard and focused execution of all four groups; `TEST-0117` |
| `RISK-0110` | Evidence integrity | Sharding drops, duplicates, or falsely canonicalizes an existing scenario | Mitigating / test maintainer | Preserve `Shard=All`, compatibility-only partial results, exact seven-name structural contract, and full suite; `TEST-0117` |
| `RISK-0111` | Event routing | Release-only gating accidentally suppresses ordinary CI or revives the aggregate after skipped dependencies | Mitigating / workflow maintainer | Inverse guards on normal jobs, `always()` plus the same inverse guard on aggregate, positive verifier guard; `TEST-0118` |

## Definition of Ready

- [x] `FEAT-0025`, `SUBF-0044`, `SUBF-0045`, `TEST-0117`, `TEST-0118`,
      `RISK-0109` through `RISK-0111`, and linked issue #67 exist.
- [x] Problem, outcome, scope, non-goals, compatibility, isolation, event, and
      evidence contracts are explicit.
- [x] FEAT-0024 measurements identify the overloaded shard and establish a
      non-timing-sensitive baseline.
- [x] The work is decomposed into semantic sharding and dispatch isolation.
- [x] Expected-red, focused shard, complete suite, hosted, review, and
      post-publication evidence are planned.

## Acceptance criteria

1. The Windows matrix contains exactly seven names: the existing contracts,
   adoption, and repository shards plus four semantic integrity shards.
2. Every former integrity case runs in the same order under `Shard=All` and in
   exactly one independently runnable partial group.
3. Partial shards cannot claim canonical scenario completion; Linux full and
   local `Shard=All` retain the complete evidence contract.
4. The aggregate Windows check requires the base and complete matrix and keeps
   its stable check identity.
5. A release-evidence dispatch runs only the verifier; all ordinary repository
   events and ordinary dispatch retain recurring validation.
6. Focused Windows PowerShell 5.1 shards, the complete local suite, hosted CI,
   and the read-only post-publication verifier pass.

## Decomposition and review gates

| ID | Slice | Tracking | Tests | Self-review / findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0044` | Four semantic integrity shards with independent partial baselines and unchanged canonical order | [Issue #67](https://github.com/hasanmanzak/meAndAI/issues/67) | `TEST-0117` | Focused structure and all four partial modes passed; no blocking finding | Implemented |
| `SUBF-0045` | Mutually correct ordinary-validation and release-evidence dispatch routing | [Issue #67](https://github.com/hasanmanzak/meAndAI/issues/67) | `TEST-0118` | Exact inverse and positive guards passed structure review; hosted evidence pending | Implemented |

## Verification approach

Add the exact shard and event-routing assertions first and record their intended
failure. Implement the two slices without production-launcher refactoring. Run
the four new partial shards, structure validation, one complete Windows suite,
one bounded diff review/scan, hosted PR checks, and one release-only dispatch.
Durations are observations, never pass/fail gates.

## Relationships

- Previous layout and immutable fixture: [FEAT-0024](../FEAT-0024-v0101-parallel-windows-validation/README.md)
- Launcher capability: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Stable automation invariants: [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md)
- Tracking and post-publication authority: [issue #67](https://github.com/hasanmanzak/meAndAI/issues/67)

## Self-review

The review was bounded to the seven-name workflow matrix, inverse event guards,
partial-shard state ownership, canonical `Shard=All` order, compatibility-only
result authority, active version pins, and linked records. It did not expand
into launcher production behavior, shared mutable fixtures, timing gates, or a
general test scheduler.

No unresolved in-scope `Blocking` finding remains. Structure validation and all
four new PowerShell 5.1 partial modes passed; the complete local suite and
hosted evidence are the remaining delivery gates recorded below.

## Definition of Done

- [ ] Acceptance criteria and `TEST-0117` / `TEST-0118` pass.
- [ ] Focused and complete local suites pass.
- [ ] Hosted ordinary validation passes.
- [ ] Both subfeature reviews and the bounded completion scan have no unresolved
      `Blocking` finding.
- [ ] Documentation, links, version, changelog, and project memory agree.
- [ ] Issue and pull request link the canonical records and evidence.

## Post-merge publication gate

Issue #67 is the external authority for the exact merged commit, immutable
`v0.10.2` release, launcher asset digest, hosted durations, branch deletion,
and release-only post-publication verification.
