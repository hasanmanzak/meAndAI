# 2026-07-14 - Bounded Self-Validation

- Tracking: [issue #5](https://github.com/hasanmanzak/meAndAI/issues/5)
- Protocol release: `v0.2.1`

## Durable rules

- The normal default is one fresh-diff self-review pass and one final relevant
  verification command.
- Only a blocking finding reopens implementation scope. Non-blocking
  improvements become linked follow-up work instead of another review loop.
- Validation stops when acceptance and declared tests pass, no blocker remains,
  and evidence plus unreviewed scope are recorded.
- Validator-for-validator chains, recursive bootstrappers, and universal
  semantic or AI-memory validators require a concrete risk and numbered
  decision.
- Full-project scans remain explicit risk/onboarding/major-release operations;
  they are not implied by every feature or patch.
- Repository-reference adoption, orphan recovery, and workflow permissions were
  corrected without changing updater behavior.
