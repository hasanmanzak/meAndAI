# 2026-07-16 - No-Origin Existing-Secret Reuse

- Work: `BUG-0005`
- Feature: [FEAT-0016](../../../docs/features/FEAT-0016-v091-quick-adoption-correction/README.md)
- Test: [`TEST-0100`](../../../docs/features/FEAT-0016-v091-quick-adoption-correction/test-cases.md)
- Issue: [#49](https://github.com/hasanmanzak/meAndAI/issues/49)
- Pull request: [#50](https://github.com/hasanmanzak/meAndAI/pull/50)
- Target version: `0.9.1`

The launcher previously required both local token files whenever the selected
local remote was absent. That happened before it could discover that the exact
derived GitHub repository already existed and already owned the two mapped
repository Actions secrets.

The correction performs a read-only exact owner/name lookup. It connects the
repository only when it is empty and only after canonical protocol source
verification. Present repository secret names keep their mapped files optional;
a missing secret plus missing mapped file still fails before secret mutation,
and a genuinely absent repository still requires both files before creation.
Credential tracked/history checks remain unconditional and precede repository
classification.

Focused `TEST-0100` and all existing quick-adoption scenarios passed locally in
351.3 seconds after the bounded red/green and review corrections. The first
complete run exposed and corrected three escaped legacy pin matchers; the
confirmation then passed every discovered suite in 473.8 seconds and reported
`TEST-0100` through machine-readable scenario evidence. Pull request #50 owns
review; merge, hosted-check, and immutable-release facts remain pending until
they exist and are authoritative in issue #49.
