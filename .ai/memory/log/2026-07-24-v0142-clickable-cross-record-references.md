# v0.14.2 Clickable Cross-Record References

## Scope

- [FEAT-0047](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md)
- [BUG-0029 / issue #114](https://github.com/hasanmanzak/meAndAI/issues/114)
- [SUBF-0089](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md)
- [TEST-0175](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md)

## Current state

- The candidate protocol version is `0.14.2`; the latest immutable release is
  [v0.14.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.1) at
  commit `f153e21a3098945a1b669563046f875ef6fb8b60`.
- The common rule directly requires every cross-record reference created in a
  repository-local or external document, GitHub issue, pull request, or GitHub
  comment to be a clickable link to its exact target.
- Repository templates, production text generators, static governance checks,
  and publication-evidence fixtures now agree on that one rule.
- The bounded repository-document audit and initial hash-protected GitHub
  reconciliation updated 190 editable GitHub records through 922 exact
  replacement spans; independent post-apply hashes matched every planned
  record. A fully paginated confirmation audit then inspected 220 GitHub text
  records and found no free-text reference, but found 21 clickable spans in 15
  records whose combined, stale-branch, directory, or wrong-kind targets were
  not exact. Fourteen records and 19 spans were corrected through fresh
  precondition and post-apply hashes. After the first branch publication, the
  final two links in
  [issue comment 5065074103](https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103)
  were replaced with exact pushed-commit targets and verified by post-apply
  hash.
- After [pull request #115](https://github.com/hasanmanzak/meAndAI/pull/115)
  expanded the inventory to 221 GitHub text records, the final audit found and
  corrected one inline-code-hidden migration link plus two secondary record
  identities in title fields that cannot render links. The only expected live
  drift is the current-candidate blob pin, which must be rebound once to the
  final pull-request head after all code fixes are committed.
- A final repository scan found and corrected three code-formatted numeric
  shorthands that the first shorthand fixture did not reject; [TEST-0175](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md)
  now covers that combined form. Completed records stayed closed and consumer
  repositories remained outside this correction.
- Fresh diff review then closed the external-document wording, free-text
  changelog producer, title-only, referential code-path, merge-commit-comment,
  cross-document range, GFM autolink, and balanced Markdown-destination gaps.
  Twenty-one historical aggregate ranges now link their exact suite authority
  or each intended record.
- The first hosted run exposed a stale dynamic-invocation inventory,
  source-graph links bound to the wrong base, and raw-substring fixture checks.
  It also confirmed PowerShell 7 native date deserialization in updater,
  quick-adoption, and capability-review GitHub timestamp paths; all are routed
  through semantic or invariant cross-runtime checks before the hosted rerun.

## Continuation

1. Complete the remaining local and hosted validation under
   [pull request #115](https://github.com/hasanmanzak/meAndAI/pull/115).
2. Complete one final fresh review and promote the draft only after all gates
   pass.
3. After review and merge, publish immutable `v0.14.2`, write exact evidence to
   [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114), and remove
   only the owned delivery branch.
