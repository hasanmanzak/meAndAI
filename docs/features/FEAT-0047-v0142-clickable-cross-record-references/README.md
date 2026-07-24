# FEAT-0047 - Clickable Cross-Record References

| Field | Value |
| --- | --- |
| Classification | Backward-compatible protocol correction / [BUG-0029](https://github.com/hasanmanzak/meAndAI/issues/114) and [BUG-0030](https://github.com/hasanmanzak/meAndAI/issues/116) |
| Status | Complete |
| Target version | 0.14.2 |
| Issues | [#114](https://github.com/hasanmanzak/meAndAI/issues/114) and [#116](https://github.com/hasanmanzak/meAndAI/issues/116) |
| Pull request | [#115](https://github.com/hasanmanzak/meAndAI/pull/115) |
| Decisions | Link rule: direct clarification; graph-parser conformance: [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) |
| Tests | [TEST-0175](test-cases.md#test-0175), [TEST-0176](test-cases.md#test-0176), [TEST-0177](test-cases.md#test-0177), [TEST-0178](test-cases.md#test-0178), [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) |

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
- Give every canonical embedded stable-ID record one unique lowercase custom
  anchor and require references to that record to include the exact fragment.
- Treat a human-facing commit reference as a governed reference whose visible
  label resolves to an absolute full-SHA commit permalink in the commit's
  owning repository.
- Reconcile proven historical repository-document violations without changing
  their meaning.
- Reconcile proven historical GitHub issue, pull-request, and editable-comment
  violations without changing their meaning or reopening completed delivery.
- Publish the correction as immutable `v0.14.2`.

## Non-goals

- Add a reference matrix, second tracking ledger, universal crawler, or new
  validator framework.
- Require an artifact's own identifier to link to itself.
- Treat command arguments, source examples, structured data, fixtures, Git
  object identities or inputs, digests, or opaque machine markers as commit references merely
  because they contain SHA-shaped text.
- Mutate a consumer repository.
- Weaken existing external-evidence, pagination, or exact-release checks.

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0213` <a name="risk-0213"></a> | Semantic classification | An artifact's own identity is mistaken for a reference to another artifact | Protocol maintainers / allow only the source artifact's own identity while keeping authored references to every other governed artifact subject to the link rule |
| `RISK-0214` <a name="risk-0214"></a> | Coverage drift | Documents pass while a generator or one GitHub comment kind keeps accepting free-text references | Protocol maintainers / static producer checks and one publication contract cover issue, PR, conversation, review, and inline-review fixtures |
| `RISK-0215` <a name="risk-0215"></a> | Historical integrity | Reconciliation changes completed delivery meaning or hides prior state | Protocol maintainers / linkify only proven targets, preserve GitHub edit history, and do not reopen completed work solely for traceability repair |
| `RISK-0216` <a name="risk-0216"></a> | Anchor integrity | A duplicate, malformed, case-colliding, or renderer-inert anchor makes a formally linked record unreachable | Protocol maintainers / canonical lowercase stable-ID anchors, unique rendered-target validation, and missing/wrong/collision negatives in [TEST-0177](test-cases.md#test-0177) |
| `RISK-0217` <a name="risk-0217"></a> | Commit classification | A digest, command, fixture, or machine payload is mistaken for a human-facing commit reference | Protocol maintainers / resolve intended commit evidence separately from declared literal contexts and retain explicit false-positive fixtures in [TEST-0178](test-cases.md#test-0178) |
| `RISK-0218` <a name="risk-0218"></a> | Historical target drift | A bulk correction binds an embedded record or commit to the wrong fragment, repository, or object | Protocol maintainers / deterministic canonical registry, Git-object resolution, complete preflight, body-hash leases, and post-apply verification |

## Decomposition and gate

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0089` <a name="subf-0089"></a> | Direct rule, compact enforcement, and bounded historical reconciliation | [Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) | [TEST-0175](test-cases.md#test-0175), [TEST-0176](test-cases.md#test-0176) | Protocol, templates, validators, current delivery records, and historical corrections agree | Complete |
| `SUBF-0090` <a name="subf-0090"></a> | Stable addressable embedded records and exact fragment navigation | [Issue #116](https://github.com/hasanmanzak/meAndAI/issues/116) | [TEST-0177](test-cases.md#test-0177); baseline and converged zero-change inventories recorded | Every canonical anchor and repository/GitHub record link resolves to the named sub-record | Complete |
| `SUBF-0091` <a name="subf-0091"></a> | Exact human-facing commit permalinks with literal exclusions | [Issue #116](https://github.com/hasanmanzak/meAndAI/issues/116) | [TEST-0178](test-cases.md#test-0178); Git-resolved, API-proven, and paginated inventories recorded | Repository and GitHub evidence link exact commits without rewriting literal data | Complete |

## Definition of Ready

- [x] [BUG-0029](https://github.com/hasanmanzak/meAndAI/issues/114),
  [BUG-0030](https://github.com/hasanmanzak/meAndAI/issues/116), `FEAT-0047`,
  [SUBF-0089](#subf-0089), [SUBF-0090](#subf-0090),
  [SUBF-0091](#subf-0091), [TEST-0175](test-cases.md#test-0175),
  [TEST-0176](test-cases.md#test-0176), [TEST-0177](test-cases.md#test-0177),
  [TEST-0178](test-cases.md#test-0178), and risks exist.
- [x] [Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) remains the delivery authority;
  [issue #116](https://github.com/hasanmanzak/meAndAI/issues/116) owns the pre-merge blocker and links the delivery issue and pull request.
- [x] Problem, outcome, scope, non-goals, compatibility, and exact governed
  source/target surfaces are explicit.
- [x] No new architectural decision is required; this clarifies the existing
  mandatory clickable-link contract.
- [x] Two independently reviewable slices extend the existing compact
  repository-governance and publication-evidence owners.
- [x] [TEST-0177](test-cases.md#test-0177) and [TEST-0178](test-cases.md#test-0178) define positive,
  negative, template, historical, and false-positive behavior before
  implementation; the read-only baseline proves both current false passes.

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
5. Governed references use renderer-active Markdown inline links,
   reference-style links, or absolute HTTP(S) autolinks; raw HTML `href`
   elements are not a supported authoring form. Focused fixtures accept valid
   Markdown links, including balanced, escaped, and angle-delimited
   destinations, and exact absolute-URL autolinks while rejecting free text,
   wrong targets, invalid bare-URL boundaries or domains, title-only
   references, referential code-formatted paths, cross-document aggregate
   ranges, and comment links that do not identify the referenced comment.
6. Targeted publication validation enforces the current delivery's governed
   issue, pull request, exact merge-commit comments, and pull-request comment
   kinds without creating a repository-wide runtime crawler.
7. Proven historical repository-document and GitHub violations are corrected
   without changing meaning, reopening completed delivery, or mutating a
   consumer.
8. Focused, structural, hosted, and review gates pass before merge; publication
   and owned-branch cleanup remain separate post-merge evidence under the
   delivery issue.
9. A cross-document reference to an embedded canonical record resolves through
    a unique, renderer-active lowercase stable-ID custom anchor inside the
    canonical declaration; reaching only the containing document is not exact.
    Canonical declarations and ordinary non-navigational prose repetitions
    inside their declaring document are not cross-document references, while
    duplicate declaration-shaped occurrences remain invalid.
10. Repository documents use relative path-plus-fragment links for embedded
     records, while GitHub surfaces use immutable absolute blob-plus-fragment
     targets; historical and GitHub blob links resolve to an existing blob and
     renderer-active Markdown fragment at the named commit, or to an in-bounds
     GitHub line fragment when the target blob is not Markdown.
11. A human-facing commit reference links an absolute commit URL in the
    commit's owning repository containing the full SHA; a short visible label
    is permitted when it resolves unambiguously, but plain, wrong-repository,
    wrong-SHA, branch, tree, or blob targets fail.
12. Commands, source examples, structured fields, fixtures, digests, Git object
    identities or inputs, and opaque machine markers retain literal SHA values without being
    misclassified as commit references.

## Self-review findings

| ID | Finding | Resolution |
| --- | --- | --- |
| `FIND-0213` <a name="find-0213"></a> | [FEAT-0046](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md) had reused three finding IDs | The v0.14.1 record now owns unique [FIND-0210](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md#find-0210), [FIND-0211](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md#find-0211), and [FIND-0212](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md#find-0212) identities |
| `FIND-0214` <a name="find-0214"></a> | Exact-target checks could be bypassed through descriptive labels, code formatting, shorthand, aggregate ranges, bare numbers, or one uninspected comment kind | [TEST-0175](test-cases.md#test-0175) closes the repository-document routes and [TEST-0176](test-cases.md#test-0176) closes the GitHub-surface routes |
| `FIND-0215` <a name="find-0215"></a> | Reusable adoption and protocol-update generators still emitted free-text tracking and supersession references after templates were corrected | Writers now emit exact links while readers retain bounded legacy compatibility |
| `FIND-0216` <a name="find-0216"></a> | Historical repository documents and GitHub records contained broader debt than the four reported examples | Bounded exact-target audits and hash-protected edits reconcile the proven set |
| `FIND-0217` <a name="find-0217"></a> | The first final scan found three code-formatted numeric shorthands after linked records, and the shorthand regression matched `link/0168` but not ``link/`0168` `` | The three references are individually linked and [TEST-0175](test-cases.md#test-0175) now rejects both forms |
| `FIND-0218` <a name="find-0218"></a> | Fresh code review found an external-document scope omission, one free-text changelog producer, code-formatted path and title-only detector gaps, and uninspected commit comments | The direct rule covers local and external documents; the producer emits a target-tag changelog link; focused title/path fixtures fail closed; exact merge-commit comments are paginated and inspected |
| `FIND-0219` <a name="find-0219"></a> | Historical evidence used 21 cross-document `through` or `..` ranges whose implied records were not individually linked | The evidence now links the exact suite authority or each intended record; [TEST-0175](test-cases.md#test-0175) resolves ranges through the canonical target registry and rejects cross-document shorthand, including adjacent endpoints |
| `FIND-0220` <a name="find-0220"></a> | Reusable update and adoption evidence retained pull-request identities or managed repository paths in opaque markers and plain text that could not satisfy the direct link rule | Current writers use opaque ownership markers plus exact pull-request and immutable blob links; bounded legacy readers remain compatible and malformed or displaced marker signals fail closed |
| `FIND-0221` <a name="find-0221"></a> | Fresh parser review found that flat inline-link and bare-URL regular expressions rejected valid balanced destinations while accepting non-rendering URL substrings, invalid boundaries, and bare localhost-style domains | Mirrored balanced Markdown parsers and GFM-compatible HTTP autolink recognition now cover nested labels, escaped or angle-delimited destinations, exact visible-URL targets, boundaries, domains, and punctuation |
| `FIND-0222` <a name="find-0222"></a> | A fully paginated confirmation audit found no remaining free-text GitHub reference, but found 21 clickable spans in 15 records whose combined, stale-branch, directory, or wrong-kind targets were not exact | Hash-protected corrections split every combined identity and replace every proven target; the final two current-delivery links were replaced with exact pushed-commit targets after the first branch publication |
| `FIND-0223` <a name="find-0223"></a> | Cross-runtime closure exposed helper-function scope loss and PowerShell 7 native date deserialization in updater, quick-adoption, and capability-review GitHub timestamp paths | Required helpers are captured into isolated scopes; native date values are normalized directly and string fallbacks use invariant exact formats with cross-runtime regressions |
| `FIND-0224` <a name="find-0224"></a> | The first hosted run found a stale runtime-invocation inventory and source-graph proposal links bound to the current base rather than the graph evidence base; three fixture assertions also mistook a nested counter name for a forbidden top-level marker property | The reviewed invocation inventory includes the new legacy-convergence slice, proposal links bind the proven graph base, and fixtures inspect the parsed top-level marker property set instead of raw substrings |
| `FIND-0225` <a name="find-0225"></a> | The final live audit found one Markdown pseudo-link hidden inside inline code and two secondary record IDs in GitHub title fields that cannot render links | The issue body now renders one exact path link; the issue and pull-request titles retain only their own identity while their bodies retain linked related records |
| `FIND-0226` <a name="find-0226"></a> | The second hosted aggregate run reached a local-completion route omitted by the earlier focused shards and found that its strategy-marker allowlist still stopped at the pre-link schema generation | Local completion accepts the canonical strategy schemas 5 through 12 and treats graph-aware schemas 7 through 10 consistently with the marker reader; the existing direct schema-9 closure regression and full hosted aggregate own the route |
| `FIND-0227` <a name="find-0227"></a> | After local completion advanced, the hosted route found that the immutable dynamic-policy import did not retain four canonical linked-evidence commands already used by proposal ownership | The import retains and verifies the canonical path, blob-link, linked-path-digest, and linked-section commands; [TEST-0130](../FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0130) asserts that command retention before lifecycle execution |
| `FIND-0228` <a name="find-0228"></a> | The last paginated live audit found an Actions run labelled like a pull-request number and one canonical idea-document title left as free text | The closed pull request now labels the exact hosted run without a false `#` identity and the closed issue links the immutable idea document; their states and delivery meaning remain unchanged |
| `FIND-0229` <a name="find-0229"></a> | A title-inclusive pass found eight secondary record IDs across closed issues [#87](https://github.com/hasanmanzak/meAndAI/issues/87), [#85](https://github.com/hasanmanzak/meAndAI/issues/85), [#83](https://github.com/hasanmanzak/meAndAI/issues/83), [#63](https://github.com/hasanmanzak/meAndAI/issues/63), and [#61](https://github.com/hasanmanzak/meAndAI/issues/61), plus closed pull requests [#62](https://github.com/hasanmanzak/meAndAI/pull/62) and [#2](https://github.com/hasanmanzak/meAndAI/pull/2); GitHub titles cannot render links | Each title retains only its leading owned feature identity, while linked related records remain in the body; all seven records kept their closed state and exact body hash |
| `FIND-0230` <a name="find-0230"></a> | The next hosted aggregate reached [TEST-0176](test-cases.md#test-0176) and found that its assertion fabricated an empty blob-link expectation when the fixture correctly detected no protocol surfaces | The assertion now snapshots graph identity before integrity-fixture resets, requires every detected surface link, requires `- None` for an empty surface set, and independently rejects an empty link label |
| `FIND-0231` <a name="find-0231"></a> | The following hosted aggregate passed the complete quick-adoption lifecycle and then found that Markdown and authority-shaped output payloads inside immutable [MIG-0001](../../../migrations/MIG-0001.json) were being interpreted relative to the migration-definition file as live instruction edges | Non-root JSON string scalars are masked from instruction semantics while JSON instruction roots retain the full grammar; focused [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) and [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) fixtures preserve root discovery, containment, unterminated/control-character masking failure, and the immutable migration bytes across PowerShell 5.1 and 7 |
| `FIND-0232` <a name="find-0232"></a> | A closure pass copied an exact pushed SHA and green hosted-run facts into repository records after convergence, conflicting with the [external-evidence boundary](../../../PROTOCOL.md#post-development-convergence-scan) | The live SHA/run facts are removed from repository records; [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) and [pull request #115](https://github.com/hasanmanzak/meAndAI/pull/115) remain their stable authority, and the final repository head still requires its own CI before draft promotion |
| `FIND-0233` <a name="find-0233"></a> | The pre-merge review proved that embedded stable-ID links could stop at a containing file and that human-facing commit SHAs were outside the governed target taxonomy | [BUG-0030 / issue #116](https://github.com/hasanmanzak/meAndAI/issues/116) reopens the feature; [SUBF-0090](#subf-0090) / [TEST-0177](test-cases.md#test-0177) own exact fragments and [SUBF-0091](#subf-0091) / [TEST-0178](test-cases.md#test-0178) own commit permalinks before merge |
| `FIND-0234` <a name="find-0234"></a> | Final validator review found case-insensitive fragment existence, a post-publication working-tree identity gap, a function-local scalar that defeated the external-commit request bound, and PowerShell 5.1 promotion of expected negative Git-probe stderr | Fragment existence is ordinal; post-publication checkout and validation require the clean exact expected commit with full history; a mutable counter and the 33-target negative fixture enforce the bound; expected native misses use a scoped non-terminating probe with immediate preference restoration |
| `FIND-0235` <a name="find-0235"></a> | GitHub validation treated every earlier immutable draft-head blob as stale even when its exact path and fragment still resolved | Required current feature and decision closure links remain bound to the pull-request head or expected commit, while historical full-SHA blobs are snapshot-validated; a prior-head [TEST-0175](test-cases.md#test-0175) fixture passes |
| `FIND-0236` <a name="find-0236"></a> | A generic tree-link rejection briefly rewrote 13 valid tag-root links to Release pages that do not exist for those historical tags | Live and local tag evidence restored all 13 `/tree/<tag>` roots; governance permits only an existing exact tag root and still rejects tree links to repository files, queries, or fragments |
| `FIND-0237` <a name="find-0237"></a> | The final exact-head live dry run failed closed on ten SHA-shaped values whose owning object or repository could not be inferred mechanically | Five Git blob/tree and structured-field values remain literals under focused fixtures; five Derdini commit occurrences use four API-proven owning-repository permalinks in the hash-protected live plan |
| `FIND-0238` <a name="find-0238"></a> | The first exact-head hosted validation after embedded-anchor convergence exposed [TEST-0082](../FEAT-0013-v084-correction/test-cases.md#test-0082) as still selecting the pre-anchor [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070) table syntax | `Blocking`, resolved: the selector now requires the canonical explicit anchor while retaining every serialization/recovery semantic assertion; its contracts preflight passes on PowerShell 7 and Windows PowerShell 5.1 |

## Definition of Done

- [x] Acceptance criteria and [TEST-0175](test-cases.md#test-0175),
      [TEST-0176](test-cases.md#test-0176),
      [TEST-0177](test-cases.md#test-0177), and
      [TEST-0178](test-cases.md#test-0178) pass.
- [x] Focused protocol-governance and publication-evidence owners pass after
      exact-fragment and commit-permalink enforcement.
- [x] Local focused and structural validation pass for the reopened tree.
- [ ] Candidate exact-head Ubuntu and Windows hosted validation passes; its
      result remains external merge evidence.
- [x] A new bounded fresh-diff review resolves [FIND-0233](#find-0233) with no
      unresolved `Blocking` finding.
- [ ] The original reconciliation evidence in [issue comment 5065074103](https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103)
      is supplemented by hash-protected exact-fragment and commit evidence.
- [x] Version, changelog, feature index, project memory, and links are current
      for the reopened tree.
- [x] [Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114),
      [issue #116](https://github.com/hasanmanzak/meAndAI/issues/116), and
      [pull request #115](https://github.com/hasanmanzak/meAndAI/pull/115) link the blocker and delivery surfaces.

## Post-merge release evidence

[Issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) is the stable
external authority for the exact pull request, merged commit, immutable
`v0.14.2` release, two runtime assets, post-publication verification, and owned-
branch cleanup. Publication-dependent values remain `Pending` until they occur
and are recorded externally; they are not part of this pre-merge Definition of
Done.
