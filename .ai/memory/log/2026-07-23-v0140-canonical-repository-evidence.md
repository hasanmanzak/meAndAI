# 2026-07-23 - v0.14.0 Canonical Repository Evidence

## Scope

[FEAT-0045](../../../docs/features/FEAT-0045-v0140-canonical-repository-evidence/README.md),
`BUG-0027`, [issue #110](https://github.com/hasanmanzak/meAndAI/issues/110),
and [DEC-0028](../../../docs/decisions/DEC-0028-upstream-owned-reusable-corrections.md)
own this bounded capability addition.

## Durable decisions

- Reusable consumer-exposed failures are classified and corrected at their
  common upstream authority; a consumer-only patch cannot close common work.
- Byte-sensitive clean evidence comes from exact verified HEAD blobs, staged-
  only evidence from the stage-zero index, and unstaged/untracked evidence from
  contained ordinary worktree files. Bytes are never normalized.
- The released capability catalog remains immutable. The new rule is one
  appended Semantic capability, so predecessor consumers review only the new
  suffix and automation does not rewrite semantic consumer files.
- Canonical code, tests, fixtures, and normative records remain project-neutral.

## Completed candidate

- TEST-0171 through TEST-0173 remain in their existing capability owners and
  are green for the focused v0.14.0 candidate.
- The shared reader and production runner integration use exact Git authorities;
  injected lifecycle fixtures use the existing runtime seam instead of copying
  the production algorithm.
- One bounded fresh-diff review has no unresolved `Blocking` finding.
- PR #111's first hosted Windows run exposed an unnecessary matched-process
  termination in the bounded rename/copy scan; the correction drains the
  process and focused TEST-0171 passes without changing evidence authority.
- Derdini-specific PR #24, issue #23, and its owned branch were closed or
  deleted without merging consumer code; issue #110 owns the common correction.

## Continuation

Wait for PR #111's exact-head hosted validation, publish the reviewed pull
request, and release exactly the merged commit as immutable v0.14.0. Record PR,
commit, release, asset, and branch-cleanup evidence in FEAT-0045 and issue #110.
