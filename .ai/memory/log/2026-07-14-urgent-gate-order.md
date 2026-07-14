# 2026-07-14 - Urgent-Work Gate Order

- Finding: `FIND-0047`
- Tracking: [issue #9](https://github.com/hasanmanzak/meAndAI/issues/9)
- Owning feature:
  [FEAT-0001](../../../docs/features/FEAT-0001-common-development-protocol/README.md)
- Target protocol release: `v0.3.1`

## Durable rules

- Urgency may shorten elapsed time but does not reorder delivery gates.
- Gate 1 remains a pre-implementation requirement.
- Evidence may be concise and gates may run back-to-back, but evidence exists
  before the gate it supports is passed.
- A real deviation uses the existing numbered-decision process with an owner,
  risk, tests, deferred evidence, linked follow-up, and review or expiry
  condition.
- `TEST-0020` and the existing repository suite passed on Windows PowerShell 5.1.
- `FIND-0048` identified a line-wrap-sensitive TEST-0020 assertion; the test now
  normalizes Markdown whitespace before checking the contract.
- No separate emergency framework or retrospective-evidence path was added.
