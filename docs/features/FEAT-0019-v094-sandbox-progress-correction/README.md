# FEAT-0019 - v0.9.4 Windows Sandbox and Progress Correction

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.9.4 |
| Issue | [#55](https://github.com/hasanmanzak/meAndAI/issues/55) |
| Pull request | [#56](https://github.com/hasanmanzak/meAndAI/pull/56) |
| Decisions | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md), [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md) |
| Tests | [TEST-0103 and TEST-0104](test-cases.md) |

## Problem and intended outcome

The corrected `v0.9.3` launcher reaches local semantic completion for the
retained Derdini adoption draft, but its `codex exec --ignore-user-config`
boundary also discards the maintainer's native Windows sandbox implementation.
On the reproduced host, `unelevated` workspace access can create and remove a
probe file, while the ignored/default `elevated` setup fails to launch
`codex-windows-sandbox-setup.exe` with Access Denied. The model is invoked
before that mismatch is detected and reports a read-only workspace.

The same run has no durable phase indicator while waiting for GitHub Actions
or local Codex. It also treats an empty repository's not-yet-selected product
purpose, runtime, architecture, and test commands as blockers to installing
the development protocol itself.

Retain the isolated, network-disabled local execution boundary while carrying
only a validated Windows sandbox implementation across the ignored user
configuration. Verify workspace writes without a model call, distinguish
unknown product facts from adoption facts in a new repository, and expose
truthful bounded progress for the existing launcher phases.

## Scope and non-goals

- Parse only the exact `[windows].sandbox` selection from the active local
  Codex configuration and accept only `elevated` or `unelevated`.
- Pass the selected implementation explicitly after `--ignore-user-config`.
- Run a write/read/delete probe through `codex sandbox` before semantic model
  execution and leave no probe artifact.
- If the preferred elevated implementation cannot start, try the documented
  unelevated fallback and report that choice; never remove the sandbox.
- Clarify that a new empty consumer may record application facts as
  `Not yet established` and use structural adoption evidence without
  fabricating domain, build, or test facts.
- Add a default interactive progress bar for real phases, an elapsed-time
  child indicator for local Codex, and `-NoProgress` for noninteractive use.
- Update the existing launcher, guide, decision clarification, current release
  metadata, tests, and project memory as one bounded patch.

No `danger-full-access`, approval bypass, Codex Cloud connection, secret
exposure, second launcher, hosted service, general sandbox manager, automatic
approval or merge, Derdini branch reset, or retained-draft retargeting is in
scope. The corrected launcher continues to resume the original Derdini
`v0.9.2` proposal when invoked with `-ProtocolTag v0.9.2`.

## Contracts and risks

The configuration parser owns only one semantic value. It does not import the
maintainer's model, MCP, plugin, hook, notification, shell, or permission
settings. A missing setting uses the preferred native Windows implementation;
an unavailable elevated implementation may fall back only to the still
sandboxed unelevated implementation. The exact selected value is passed to
both the token-free probe and `codex exec`.

The probe operates only on one unpredictable file inside the isolated clone,
verifies its bytes, removes it, and blocks before a model call on any failure
or residue. It does not inspect credentials, GitHub state, or `.git`.

Progress reports completed phase boundaries rather than estimated work. A
long-running process reports elapsed time as indeterminate instead of deriving
a misleading percentage from its timeout. Progress records are completed in a
`finally` boundary on success or failure.

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0089` | Sandbox fidelity | Ignoring user config silently selects a Windows implementation that cannot provide workspace writes | Mitigating / launcher maintainer | Carry only a validated implementation, run `TEST-0103` probe variants before model execution, and retain `workspace-write` plus network denial |
| `RISK-0090` | Isolation regression | Recovery broadens local Codex to full host access | Prevented / launcher maintainer | Reject values outside `elevated` and `unelevated`; structural tests prohibit `danger-full-access` and sandbox bypass |
| `RISK-0091` | False progress | A timeout percentage is presented as actual work completion | Mitigating / launcher maintainer | Phase completion is discrete; long local Codex work is indeterminate with elapsed time; `TEST-0104` |
| `RISK-0092` | Empty-repository fabrication | Adoption invents product facts merely to satisfy project records | Mitigating / consumer maintainer | Record unknown product facts explicitly and limit evidence to adoption structure until product work defines them |

## Definition of Ready

- [x] Stable `FEAT-0019` and `BUG-0007` identifiers and linked issue #55 exist.
- [x] Problem, outcome, scope, non-goals, affected entry points, compatibility,
      platform, permission, timeout, cleanup, and error contracts are explicit.
- [x] Existing DEC-0007 and DEC-0008 remain authoritative; this work clarifies
      their Windows implementation and empty-consumer behavior without adding
      a new architectural boundary.
- [x] The change is one small independently testable launcher correction.
- [x] `TEST-0103` and `TEST-0104` define success, failure, fallback, cleanup,
      empty-repository, and progress variants before production changes.
- [x] Verification is bounded to one expected-red focused run, one focused
      green run, one fresh-diff review, one complete suite, and the protocol's
      single post-development scan.

## Acceptance criteria

1. Local Codex remains ephemeral, `workspace-write`, approval-free only inside
   that sandbox, and network-disabled for spawned commands.
2. On native Windows, the launcher carries one validated `elevated` or
   `unelevated` implementation across `--ignore-user-config`; unrelated user
   configuration is not loaded.
3. A token-free workspace probe succeeds before the model starts, removes its
   file, and provides an actionable failure before token consumption when no
   supported implementation can write.
4. An unavailable elevated implementation can fall back to unelevated with a
   visible status; neither path enables full access or network.
5. A new empty consumer may complete protocol adoption while product purpose,
   runtime, architecture, build, and test commands remain honestly
   `Not yet established`. No product fact or successful product test is
   fabricated.
6. Interactive execution shows repository, release, secret, seed, workflow,
   draft, local Codex, validation, and completion phases. `-NoProgress`
   suppresses the display, and every exit completes active progress records.
7. The retained Derdini draft is resumed with the corrected launcher and
   `-ProtocolTag v0.9.2`; it is not reset, duplicated, or retargeted.
8. Focused and complete repository suites pass, links and current release
   metadata agree, and fresh-diff self-review leaves no blocking finding.

## Implementation and verification approach

Add `TEST-0103` and `TEST-0104` assertions first and demonstrate the current
launcher lacks the sandbox selection/probe, empty-repository distinction, and
progress contract. Then change only the existing launcher and its governing
records. Use the live host's model-free `codex sandbox` evidence as the external
reproduction: `:workspace` with `unelevated` succeeds, while `elevated` fails
at setup with Access Denied.

## Relationships

- Local Codex feature: [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md)
- Single-file distribution: [FEAT-0017](../FEAT-0017-v092-single-file-quick-adoption/README.md)
- Latest metadata correction: [FEAT-0018](../FEAT-0018-v093-live-pr-metadata-correction/README.md)
- Governing decisions: [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md) and [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking and post-publication authority: [issue #55](https://github.com/hasanmanzak/meAndAI/issues/55)
- Delivery pull request: [#56](https://github.com/hasanmanzak/meAndAI/pull/56)
- Consumer evidence: [Derdini PR #1](https://github.com/hasanmanzak/Derdini/pull/1)

## Self-review and completion

The implementation preserves `workspace-write`, spawned-command network
denial, `--ignore-user-config`, credential isolation, bounded process timeout,
launcher-owned publication, and maintainer-owned merge. The new parser imports
only `[windows].sandbox`; the model-free probe uses one unpredictable file,
removes residue, and passes only a verified allowlisted mode to semantic Codex.

Fresh-diff review found and resolved two local defects before publication:
the probe command is one line so `.cmd`-based Codex and `npx` runners do not
truncate it, and the probe reports its actual bounded timeout rather than the
longer semantic limit. The same review found no full-access path, network
re-enable, stale active version pin, or unresolved blocking finding.

## Definition of Done

- [x] Acceptance criteria and `TEST-0103` / `TEST-0104` pass.
- [x] Existing quick-adoption scenarios and complete repository suite pass.
- [x] Fresh-diff review and bounded project scan leave no unresolved
      `Blocking` finding.
- [x] Version, changelog, guide, decisions, links, feature index, and project
      memory agree.
- [x] Issue and pull request link canonical records and validation evidence.

## Post-merge publication gate

Issue #55 is the external authority for the exact merged commit, immutable
`v0.9.4` release, launcher asset digest, hosted checks, and retained Derdini
continuation evidence after those facts exist.
