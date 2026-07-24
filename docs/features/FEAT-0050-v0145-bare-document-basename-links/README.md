# FEAT-0050 - Exact Bare Document Basename Links

| Field | Value |
| --- | --- |
| Classification | Backward-compatible verifier false-positive correction / [BUG-0033](https://github.com/hasanmanzak/meAndAI/issues/121) |
| Status | Complete |
| Target version | 0.14.5 |
| Issue | [#121](https://github.com/hasanmanzak/meAndAI/issues/121) |
| Pull request | [#122](https://github.com/hasanmanzak/meAndAI/pull/122) |
| Decisions | Clarifies [FEAT-0047](../FEAT-0047-v0142-clickable-cross-record-references/README.md) under the upstream ownership boundary in [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md); no new architecture |
| Tests | [TEST-0182](test-cases.md#test-0182) |

## Problem and outcome

The current publication verifier treats every visible Markdown document label
that looks like a path as a path relative to its source document. That is
correct for labels containing directory or dot-segment syntax, but it is too
strict for a bare filename label. The valid canonical link to
[AGENTS.md](../../../AGENTS.md) resolves unambiguously to the repository-root
document while the verifier incorrectly compares its bare visible label with
a synthetic source-directory-relative path.

The outcome is one narrow distinction inside the existing path-target helper:
a bare filename label may describe the exact basename of its resolved document
target. Labels that express any directory syntax retain exact resolved-path
equality. Link existence, case, fragments, absolute GitHub-surface targets, and
every cross-record rule remain unchanged.

## Prior art and current-main classification

- Classification: `VerifierSemanticFalsePositive`, not a new Markdown parser or
  reference policy.
- Canonical link rule: [FEAT-0047](../FEAT-0047-v0142-clickable-cross-record-references/README.md).
- Owning layer: common publication-evidence verifier and its project-neutral
  fixture under [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md).
- Exposed retained evidence: [issue #117](https://github.com/hasanmanzak/meAndAI/issues/117)
  and [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114).

## Scope

- Distinguish a decoded, separator-free visible document basename from a
  visible repository path.
- Accept the basename form only when it equals the case-sensitive basename of
  the resolved target and the existing fragment predicate passes.
- Add one positive project-neutral basename fixture and one wrong-basename
  negative while retaining the existing full-path wrong-target negative.
- Publish immutable `v0.14.5`, then rerun the retained publication gates with
  current verifier authority.

## Non-goals

- No change to Markdown parsing, link discovery, record IDs, anchors, or
  external-commit validation.
- No basename-based target discovery or ambiguity resolver.
- No relaxation for labels containing `/`, `\`, `./`, `../`, or an encoded
  separator.
- No consumer mutation, named-consumer fixture, or historical-release rewrite.
- No unrelated validator hardening or test-harness refactor.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0226` <a name="risk-0226"></a> | A path-bearing label is accidentally admitted through basename comparison | Protocol maintainers / decode and normalize the visible path component first; basename fallback is available only when no forward or backward separator remains |
| `RISK-0227` <a name="risk-0227"></a> | A basename label hides a wrong document, case difference, or fragment | Protocol maintainers / require ordinal basename equality, a resolved document target, and the unchanged visible-fragment predicate; cover the wrong-basename case in [TEST-0182](test-cases.md#test-0182) |

## Decomposition and gate

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0094` <a name="subf-0094"></a> | Distinguish exact basename labels from full visible paths | [Issue #121](https://github.com/hasanmanzak/meAndAI/issues/121) | [TEST-0182](test-cases.md#test-0182) and existing [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176) | Exact basename links pass while wrong basename and full-path mismatch remain fail closed | Complete |

## Definition of Ready

- [x] [BUG-0033](https://github.com/hasanmanzak/meAndAI/issues/121),
      `FEAT-0050`, [SUBF-0094](#subf-0094),
      [TEST-0182](test-cases.md#test-0182), and risks are assigned.
- [x] The retained `v0.14.3` gate reproduces the false positive against an
      immutable canonical decision document.
- [x] [FEAT-0047](../FEAT-0047-v0142-clickable-cross-record-references/README.md),
      its linked [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md),
      and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md)
      establish the exact owning rule and upstream boundary.
- [x] Scope, non-goals, compatibility boundary, one reviewable slice, risks,
      acceptance criteria, test intent, and release placement are explicit.
- [x] No new architectural decision is required; the change resolves one
      previously undefined label-semantics case in the existing helper.

## Acceptance criteria

1. A bare [AGENTS.md](../../../AGENTS.md) label passes when authored inside a
   nested canonical document and its href resolves to the exact repository-root
   file.
2. A bare visible filename is eligible for basename comparison only after URI
   decoding and slash normalization prove that it contains no directory
   separator.
3. The visible basename and resolved target basename compare ordinally; a
   different or case-mismatched basename fails closed.
4. Directory-bearing visible paths retain the existing exact resolved-path
   comparison, so the existing wrong-target fixture remains red.
5. The existing fragment predicate remains unchanged: an expressed visible
   fragment must equal the target fragment.
6. Current and retained publication gates pass without modifying an immutable
   historical release or any consumer.

## Self-review

- Exact resolved-path equality remains the first acceptance path.
- Basename fallback is available only after URI decoding and slash
  normalization prove that the visible label has no directory separator.
- The fallback requires a non-empty resolved target and ordinal basename
  equality; the existing visible-fragment predicate is unchanged.
- [TEST-0182](test-cases.md#test-0182) owns one isolated positive and one
  wrong-basename negative inside the existing publication-evidence fixture;
  the directory-bearing [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176)
  negative remains green.
- Fresh diff review found no consumer mutation, duplicate validator, parser
  expansion, historical-release edit, or unrelated scope.

## Definition of Done

- [x] [TEST-0182](test-cases.md#test-0182) establishes the expected red and
      passes with existing publication scenarios on PowerShell 7 and Windows
      PowerShell 5.1.
- [x] Focused and bounded aggregate gates pass without a new unrelated finding.
- [x] Fresh-diff self-review confirms that the full-path and fragment contracts
      remain fail closed.
- [x] Version, changelog, feature index, project memory, and GitHub evidence are
      current and correctly linked.

## Post-merge publication closure

- Publish one reviewed pull request and immutable `v0.14.5` release under
  [issue #121](https://github.com/hasanmanzak/meAndAI/issues/121).
- Run exact `v0.14.5` publication evidence, then rerun `v0.14.4`, retained
  `v0.14.3`, and retained `v0.14.2` evidence with current verifier authority.
- Close linked issues only after their exact gates pass, then remove only the
  exact owned delivery branch.
