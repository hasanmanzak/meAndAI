# 2026-07-15 - Existing Actions-secret preservation

- Work: `BUG-0001`
- Target release: `v0.6.2`
- Tracking: [issue #24](https://github.com/hasanmanzak/meAndAI/issues/24)
- Delivery: [pull request #25](https://github.com/hasanmanzak/meAndAI/pull/25)
- Canonical record:
  [FEAT-0007 correction](../../../docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0001-correction-for-v062)
- Executable contract:
  [`TEST-0042`](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md)

The quick-adoption launcher now treats repository Actions-secret
reconciliation as create-missing, not replace-existing. It lists names only,
compares the canonical mappings case-insensitively, and never calls
`gh secret set` for an existing mapped name. GitHub does not reveal stored
values, so the launcher does not claim that presence proves value, permission,
expiry, or usability.

`MEANDAI_RO_FG_PAT.txt` remains required locally because the launcher uses it
to fetch and verify the exact private protocol source. `FG_PAT.txt` is required
and read only when `MEANDAI_UPDATER_TOKEN` is absent. Tracked-file and
Git-history gates still apply to both credential paths when an optional source
file is absent. New repositories continue to create both missing repository
secrets before seed publication.

Executable evidence: the complete Windows PowerShell 5.1 protocol suite passed
`TEST-0001` through `TEST-0042`; the post-review focused confirmation passed
`TEST-0033` through `TEST-0042`. The bounded review findings `FIND-0060` and
`FIND-0061` are resolved in the canonical feature correction.
