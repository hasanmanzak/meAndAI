# FEAT-0047 - Clickable Cross-Record References

| Field | Value |
| --- | --- |
| Classification | Backward-compatible protocol correction / [BUG-0029](https://github.com/hasanmanzak/meAndAI/issues/114) |
| Status | In progress |
| Target version | 0.14.2 |
| Issue | [#114](https://github.com/hasanmanzak/meAndAI/issues/114) |
| Pull request | To be recorded in [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) |
| Decisions | N/A - direct clarification of the existing clickable-link contract |
| Tests | [TEST-0175](test-cases.md), [TEST-0176](test-cases.md) |

## Problem and intended outcome

The protocol requires links to be clickable but does not state directly that a
cross-record reference must be created as a link. Documents, whether
repository-local or external, GitHub issues, pull requests, and comments can
therefore name another document, issue, pull request, or comment through a
free-text identifier, number, title, or path and still pass the current
completion checks.

The outcome is one direct rule: every such cross-record reference is a
clickable link to its exact target. The rule applies to every GitHub comment
kind, including issue comments, pull-request conversation comments, submitted
reviews, inline review comments, commit comments, and discussion comments. An
artifact's own identity is not a reference to another artifact; authored
evidence that identifies another governed artifact remains subject to the link
rule.

## Scope

- Add the direct normative rule to the common documentation graph.
- Update repository issue and pull-request prompts to request clickable exact-
  target references rather than free-text mentions.
- Update reusable adoption, protocol-update, and capability-review text
  generators so every new issue, pull-request, and comment reference is linked.
- Extend the existing compact governance and publication-evidence owners with
  focused positive and negative reference fixtures for IDs, numbers, titles,
  paths, ranges, exact targets, and every current delivery comment surface.
- Reconcile proven historical repository-document violations without changing
  their meaning.
- Reconcile proven historical GitHub issue, pull-request, and editable-comment
  violations without changing their meaning or reopening completed delivery.
- Publish the correction as immutable `v0.14.2`.

## Non-goals

- Add a reference matrix, second tracking ledger, universal crawler, or new
  validator framework.
- Require an artifact's own identifier to link to itself.
- Mutate a consumer repository.
- Weaken existing external-evidence, pagination, or exact-release checks.

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0213` | Semantic classification | An artifact's own identity is mistaken for a reference to another artifact | Protocol maintainers / allow only the source artifact's own identity while keeping authored references to every other governed artifact subject to the link rule |
| `RISK-0214` | Coverage drift | Documents pass while a generator or one GitHub comment kind keeps accepting free-text references | Protocol maintainers / static producer checks and one publication contract cover issue, PR, conversation, review, and inline-review fixtures |
| `RISK-0215` | Historical integrity | Reconciliation changes completed delivery meaning or hides prior state | Protocol maintainers / linkify only proven targets, preserve GitHub edit history, and do not reopen completed work solely for traceability repair |

## Decomposition and gate

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0089` | Direct rule, compact enforcement, and bounded historical reconciliation | [Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) | [TEST-0175](test-cases.md), [TEST-0176](test-cases.md) | Protocol, templates, validators, current delivery records, and historical corrections agree | In progress |

## Definition of Ready

- [x] [BUG-0029](https://github.com/hasanmanzak/meAndAI/issues/114),
  `FEAT-0047`, `SUBF-0089`, [TEST-0175](test-cases.md),
  [TEST-0176](test-cases.md), and risks exist.
- [x] [Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) is the delivery authority.
- [x] Problem, outcome, scope, non-goals, compatibility, and exact governed
  source/target surfaces are explicit.
- [x] No new architectural decision is required; this clarifies the existing
  mandatory clickable-link contract.
- [x] One focused scenario in existing test owners covers positive, negative,
  template, and live-evidence behavior.
- [x] Test code is not started; the unchanged `v0.14.1` baseline is expected to
  fail because it lacks the direct rule and exact negative fixtures.

## Acceptance criteria

1. A document, whether repository-local or external, GitHub issue, pull request,
   or GitHub comment of any kind that references another document,
   issue, pull request, or GitHub comment must express each reference as a
   clickable link to the exact referenced target.
2. A free-text identifier, number, title, or path does not satisfy the rule.
3. An artifact's own identity is not a reference to another artifact; authored
   evidence that identifies another governed artifact remains subject to the
   rule.
4. Existing issue and pull-request prompts request clickable exact-target
   references.
5. Focused fixtures accept valid Markdown links, including balanced, escaped,
   and angle-delimited destinations, and exact absolute-URL autolinks while
   rejecting free text, wrong targets, invalid bare-URL boundaries or domains,
   title-only references, referential code-formatted paths, cross-document
   aggregate ranges, and comment links that do not identify the referenced
   comment.
6. Targeted publication validation enforces the current delivery's governed
   issue, pull request, exact merge-commit comments, and pull-request comment
   kinds without creating a repository-wide runtime crawler.
7. Proven historical repository-document and GitHub violations are corrected
   without changing meaning, reopening completed delivery, or mutating a
   consumer.
8. Focused, structural, hosted, and review gates pass before merge; publication
   and owned-branch cleanup remain separate post-merge evidence under the
   delivery issue.

## Self-review findings

| ID | Finding | Resolution |
| --- | --- | --- |
| `FIND-0213` | [FEAT-0046](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md) had reused three finding IDs | The v0.14.1 record now owns unique [FIND-0210](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md), [FIND-0211](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md), and [FIND-0212](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md) identities |
| `FIND-0214` | Exact-target checks could be bypassed through descriptive labels, code formatting, shorthand, aggregate ranges, bare numbers, or one uninspected comment kind | [TEST-0175](test-cases.md) closes the repository-document routes and [TEST-0176](test-cases.md) closes the GitHub-surface routes |
| `FIND-0215` | Reusable adoption and protocol-update generators still emitted free-text tracking and supersession references after templates were corrected | Writers now emit exact links while readers retain bounded legacy compatibility |
| `FIND-0216` | Historical repository documents and GitHub records contained broader debt than the four reported examples | Bounded exact-target audits and hash-protected edits reconcile the proven set |
| `FIND-0217` | The first final scan found three code-formatted numeric shorthands after linked records, and the shorthand regression matched `link/0168` but not ``link/`0168` `` | The three references are individually linked and [TEST-0175](test-cases.md) now rejects both forms |
| `FIND-0218` | Fresh code review found an external-document scope omission, one free-text changelog producer, code-formatted path and title-only detector gaps, and uninspected commit comments | The direct rule covers local and external documents; the producer emits a target-tag changelog link; focused title/path fixtures fail closed; exact merge-commit comments are paginated and inspected |
| `FIND-0219` | Historical evidence used 21 cross-document `through` or `..` ranges whose implied records were not individually linked | The evidence now links the exact suite authority or each intended record; [TEST-0175](test-cases.md) resolves ranges through the canonical target registry and rejects cross-document shorthand, including adjacent endpoints |
| `FIND-0220` | Reusable update and adoption evidence retained pull-request identities or managed repository paths in opaque markers and plain text that could not satisfy the direct link rule | Current writers use opaque ownership markers plus exact pull-request and immutable blob links; bounded legacy readers remain compatible and malformed or displaced marker signals fail closed |
| `FIND-0221` | Fresh parser review found that flat inline-link and bare-URL regular expressions rejected valid balanced destinations while accepting non-rendering URL substrings, invalid boundaries, and bare localhost-style domains | Mirrored balanced Markdown parsers and GFM-compatible HTTP autolink recognition now cover nested labels, escaped or angle-delimited destinations, exact visible-URL targets, boundaries, domains, and punctuation |
| `FIND-0222` | A fully paginated confirmation audit found no remaining free-text GitHub reference, but found 21 clickable spans in 15 records whose combined, stale-branch, directory, or wrong-kind targets were not exact | Hash-protected corrections split every combined identity and replace every proven target; the two current-delivery links remain pending until an exact pushed commit exists |
| `FIND-0223` | Cross-runtime closure exposed helper-function scope loss and culture-dependent GitHub release timestamp parsing in existing update test paths | Required helpers are captured into isolated scopes and release evidence normalizes native date values without culture-dependent string round-tripping |

## Definition of Done

- [ ] Acceptance criteria, [TEST-0175](test-cases.md), and
  [TEST-0176](test-cases.md) pass.
- [ ] Focused protocol-governance and publication-evidence owners pass.
- [ ] Structural and required aggregate validation pass.
- [ ] One bounded fresh-diff review has no unresolved `Blocking` finding.
- [ ] Historical reconciliation evidence is recorded in [issue comment 5065074103](https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103).
- [x] Version, changelog, feature index, project memory, and links are current.
- [ ] [Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) and the delivery pull request link each other and this feature record.

## Post-merge release evidence

[Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) is the stable
external authority for the exact pull request, merged commit, immutable
`v0.14.2` release, two runtime assets, post-publication verification, and owned-
branch cleanup. Publication-dependent values remain `Pending` until they occur
and are recorded externally; they are not part of this pre-merge Definition of
Done.
