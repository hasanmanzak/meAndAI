# 2026-07-27 - v0.16.0 Lifecycle and Backlog Governance Planning

## Status

Planning records only. [FEAT-0057](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/README.md),
[DEC-0032](../../../docs/decisions/DEC-0032-explicit-lifecycle-and-github-native-backlog.md),
and [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) are
`Proposed`. Protocol, test, automation, label, issue-form, consumer, version, and
release behavior is unchanged.

The work is selected for future delivery with planned release placement
`0.16.0`, but implementation has not started and is not authorized by these
records. Definition of Ready remains incomplete.

## Agreed scope

- [SUBF-0115](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/README.md#subf-0115):
  map the existing delivery gates into an explicit SDLC and define operation,
  maintenance, deprecation, retirement, and non-linear re-entry boundaries.
- [SUBF-0116](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/README.md#subf-0116):
  define work-item states, transitions, blocking/resumption, readiness versus
  authorization, completion versus publication, and feature-catalog semantics.
- [SUBF-0117](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/README.md#subf-0117):
  define GitHub-native backlog authority, refinement and ordering boundaries,
  tracking-surface consistency, and safe consumer adoption.

One feature and one proposed process decision own the combined contract. No
epic or separate canonical backlog file is introduced.

## Planned evidence

- [TEST-0191](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/test-cases.md#test-0191):
  SDLC and work-item state semantics.
- [TEST-0192](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/test-cases.md#test-0192):
  feature catalog and GitHub/repository backlog authority.
- [TEST-0193](../../../docs/features/FEAT-0057-v0160-lifecycle-backlog-governance/test-cases.md#test-0193):
  new/existing consumer ownership and transition behavior.

The scenarios use `PlannedDocumentation` authority only. No executable feature
test claims are made. Matching active recurrence for the lifecycle/backlog
contract is explicit `None`. The records packet separately matches the active
[untracked governance packet route](../project.md#untracked-governance-packet-is-absent-from-the-head-self-consumer-graph):
a dirty or staged structural pass can inspect filesystem paths that are absent
from the exact `HEAD` graph. Commit the complete packet and require focused
exact-commit graph evidence on both supported PowerShell runtimes; invalidate
that evidence after any later graph-reachable Markdown change.

## Remaining Definition of Ready

1. Refresh the complete current-main inventory of lifecycle, status, label,
   form, template, index, automation, and consumer projection surfaces.
2. Review and accept or revise the proposed state transitions, backlog ordering
   contract, and new-versus-existing consumer transition choice.
3. Select the narrowest existing executable owners and capture exact baseline
   plus expected-red evidence.
4. Reconfirm release placement against then-current delivery dependencies.
5. Obtain a separate explicit implementation directive.

## Continuation boundary

Future work starts from the canonical feature, proposed decision, and issue. It
must not infer implementation permission from their existence or from a Ready
state. [BUG-0036 / issue #139](https://github.com/hasanmanzak/meAndAI/issues/139)
and [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149)
remain separately owned; their release order is refreshed rather than absorbed.
