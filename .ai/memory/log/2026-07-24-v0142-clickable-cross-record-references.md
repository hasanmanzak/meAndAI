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
  precondition and post-apply hashes. The remaining two links in
  [issue comment 5065074103](https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103)
  require this candidate's exact pushed commit and remain pending until the
  branch is published.
- A final repository scan found and corrected three code-formatted numeric
  shorthands that the first shorthand fixture did not reject; [TEST-0175](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md)
  now covers that combined form. Completed records stayed closed and consumer
  repositories remained outside this correction.
- Fresh diff review then closed the external-document wording, free-text
  changelog producer, title-only, referential code-path, merge-commit-comment,
  cross-document range, GFM autolink, and balanced Markdown-destination gaps.
  Twenty-one historical aggregate ranges now link their exact suite authority
  or each intended record.

## Continuation

1. Publish the candidate branch, replace the two current-delivery links with
   exact pushed-commit targets, and open one linked delivery pull request.
2. Complete hosted Ubuntu and Windows validation and one final fresh review.
3. After review and merge, publish immutable `v0.14.2`, write exact evidence to
   [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114), and remove
   only the owned delivery branch.
