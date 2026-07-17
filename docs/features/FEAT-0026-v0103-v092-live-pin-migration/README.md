# FEAT-0026 - v0.10.3 Bounded v0.9.2 Consumer Live-Pin Migration

| Field | Value |
| --- | --- |
| Classification | Compatibility correction / `BUG-0012` |
| Status | Complete |
| Target version | 0.10.3 |
| Issue | [#69](https://github.com/hasanmanzak/meAndAI/issues/69) |
| Pull request | Pending |
| Decision | [DEC-0018](../../decisions/DEC-0018-bounded-v092-live-pin-migration.md) |
| Tests | [TEST-0119 and TEST-0120](test-cases.md) |

## Problem and intended outcome

FEAT-0023 defined the consumer gitlink and its checked-out `VERSION` as the
sole live protocol identity, but `TEST-0114` inspected only current templates.
It did not instantiate the real consumer shape produced during the v0.9.2
adoption. That shape can retain a literal live tag or commit in instructions,
memory, indexes, a decision, and its verifier.

An immutable v0.9.2 updater cannot execute code added by a later release while
it creates its first update proposal. Repair the recognized legacy shape with
one explicit local launcher mode, then return the consumer to ordinary managed
updates. Prevent recurrence by making the actual adoption prompt state the
version-neutral authority rule that its guide already promises.

## Scope

- Add `-MigrateV092LivePins` to the existing single-file quick-adoption
  launcher.
- Activate it only after the launcher proves an exact immutable v0.9.2
  installation, including the gitlink and all three installed updater assets.
- Recognize exactly eight consumer-owned current-authority fragments and
  replace only those fragments with gitlink/`VERSION`-derived wording or logic.
- Precompute the complete change set before writing; reject missing,
  duplicated, drifted, mixed, or unsupported states with zero writes.
- Preserve UTF-8 BOM state, newline style, unrelated bytes, project-specific
  content, and dated historical evidence.
- Stop after the local migration without secret reconciliation, workflow
  dispatch, commit, push, issue, pull request, or merge operations.
- Strengthen the local-Codex adoption prompt and add a real v0.9.2-shaped
  regression fixture.

## Non-goals

- Changing or replacing the immutable v0.9.2 release.
- Granting the recurring updater permanent authority over consumer-owned
  instructions, memory, decisions, indexes, or tests.
- A generalized migration framework, arbitrary text repair, or repository-wide
  tag/SHA replacement.
- Bypassing maintainer review or combining the one-time local migration with an
  update proposal created by code that cannot know the new contract.

## Contracts and risks

| ID | Classification | Risk | Response and evidence |
| --- | --- | --- | --- |
| `RISK-0112` | Atomicity | A rejected or interrupted migration leaves a partial consumer tree | Build and validate all eight outputs before the first write; restore original bytes if a write fails; `TEST-0120` |
| `RISK-0113` | Ownership | A broad repair overwrites consumer-specific content or historical evidence | Exact ordinal fragments, exact path set, byte-preserving writer, and historical sentinels; `TEST-0119` |
| `RISK-0114` | Retroactivity | Documentation promises that new updater code changes the first immutable-v0.9.2 proposal | Explicit two-stage compatibility boundary in DEC-0018 and the guide; no same-PR claim |
| `RISK-0115` | Recurrence | A later adoption again copies a live tag/SHA into consumer-owned current state | Required sole-live-pin paragraph in the executable local-Codex prompt and `TEST-0119` |

## Definition of Ready

- [x] Stable `FEAT-0026`, `BUG-0012`, `SUBF-0046`, `SUBF-0047`,
      `TEST-0119`, `TEST-0120`, and issue #69 exist.
- [x] The immutable-old-updater limitation and the local/GitHub mutation
      boundary are explicit.
- [x] The eight recognized paths, all-legacy/all-neutral state model,
      atomicity, byte preservation, historical-evidence rule, and non-goals are
      defined.
- [x] Expected-red, focused migration, launcher routing, structure, complete
      suite, hosted, and post-publication evidence are planned.
- [x] Baseline is the green immutable v0.10.2 release.

## Acceptance criteria

1. Without the explicit switch, existing adoption and update behavior is
   unchanged.
2. With the switch, only an exact v0.9.2 installation in the recognized legacy
   state changes exactly eight files and stops before every GitHub mutation.
3. One missing, duplicate, mixed, or drifted fragment rejects the whole
   operation before the first write.
4. A second migration run is a successful no-op and an ordinary subsequent
   launcher run dispatches the installed updater without rewriting
   consumer-owned files.
5. New adoption instructions, memory, decisions, indexes, and tests must derive
   live identity from the gitlink and `VERSION`; exact tags/SHAs remain only in
   dated historical evidence.
6. Focused, complete, hosted, and post-publication verification pass with
   documentation, version, changelog, and memory aligned.

## Decomposition and review gates

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0046` | Exact, atomic, idempotent v0.9.2 local migration | [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) | `TEST-0119`, `TEST-0120` | The exact-byte positive route and fail-closed negative matrix passed; no unresolved blocking finding | Implemented |
| `SUBF-0047` | Prospective sole-live-pin prompt and evidence correction | [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) | `TEST-0119` | Prompt/template/guide agreement and correction of TEST-0114's overclaim passed focused review | Implemented |

## Verification approach

Add the historical fixture and expected assertions before implementation.
Exercise LF, CRLF, and unrelated consumer-tailored text; a one-byte drift;
partial state; idempotent rerun; preserved historical files; and the following
ordinary compatible-update route. Run the focused launcher and structure suites,
then one bounded diff review, one complete suite, hosted checks, and the exact
post-publication verifier.

## Relationships

- Introduced single-file launcher: [FEAT-0017](../FEAT-0017-v092-single-file-quick-adoption/README.md)
- Version-neutral authority contract being corrected: [FEAT-0023](../FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md) / [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
- Bounded compatibility decision: [DEC-0018](../../decisions/DEC-0018-bounded-v092-live-pin-migration.md)
- Tracking: [issue #69](https://github.com/hasanmanzak/meAndAI/issues/69)

## Self-review

The bounded review covered the explicit-mode entry point, exact v0.9.2
identity proof, eight-path state machine, byte preservation, rollback,
idempotency, local/GitHub mutation boundary, prospective prompt, and the
correction of TEST-0114's historical overclaim. It did not expand into a
general migration framework or recurring updater authority.

Review found that the migration branch was originally selected after generic
repository setup and that the first negative fixture was narrower than its
documented contract. The branch now fails before repository initialization or
local-exclude mutation, and TEST-0120 covers non-repositories, wrong gitlink or
updater identity, missing/duplicate/drifted/mixed fragments, unrelated dirty
paths, and rollback after a later write failure. TEST-0119 independently
compares every successful output byte array. The focused Windows PowerShell
5.1 run passed both scenarios in 55.8 seconds. The complete Windows PowerShell
5.1 repository suite then passed every discovered contract and scenario in
561.4 seconds. No unresolved in-scope `Blocking` finding remains.

## Definition of Done

- [x] Implementation acceptance criteria met.
- [x] Mandatory test code and executable local evidence complete.
- [x] Fresh diff review and bounded completion scan have no unresolved
      `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory agree.
- [ ] Pull request, hosted checks, merge, branch cleanup, immutable release,
      and post-publication evidence complete.

## Post-merge publication gate

[Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) is the external
authority for the exact merged commit, immutable `v0.10.3` release, launcher
asset digest, branch deletion, and post-publication verification.
