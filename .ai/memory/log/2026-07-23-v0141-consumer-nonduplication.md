# 2026-07-23 - v0.14.1 Consumer Non-Duplication Mandate

## Context

[FEAT-0046](../../../docs/features/FEAT-0046-v0141-consumer-nonduplication-mandate/README.md),
`BUG-0028`, [issue #112](https://github.com/hasanmanzak/meAndAI/issues/112),
and `SUBF-0088` correct an ownership ambiguity left after v0.14.0. The common
upstream rule assigned reusable corrections to meAndAI but did not explicitly
prohibit recreating protocol-provided code or generic regression evidence in a
consumer.

## Durable boundary

- Protocol-provided code, tests, fixtures, validators, workflows, templates,
  prompts, scripts, and documentation remain single-owned by meAndAI.
- Consumers reuse or reference the pinned authority and do not copy,
  reimplement, port, shadow, fork, or maintain local equivalents.
- Consumers may own only genuinely project-specific integration,
  configuration, domain behavior, and semantic evidence.
- An exact release-declared managed hook may reside at its one canonical
  consumer path only when the execution platform requires it; its blob and
  lifecycle remain owned by meAndAI.
- A missing or defective common asset and its generic regression close in
  meAndAI and ship immutably before separately reviewed consumer recovery.
- This protocol change does not mutate any consumer.

## Verification and continuation

TEST-0174 owns the common protocol, DEC-0028, and local-instruction regression.
Publish the reviewed branch through one PR and immutable v0.14.1 release under
issue #112, including both required runtime assets and post-publication checks.
Only after that release may a consumer migration be evaluated, beginning with
a read-only proposal diff and no consumer-local copy of common assets.
