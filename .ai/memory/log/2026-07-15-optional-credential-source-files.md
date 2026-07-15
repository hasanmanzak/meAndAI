# Optional Credential-Source Files

- Date: 2026-07-15
- Target release: `v0.7.1`
- Work item: [BUG-0002](../../../docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0002-correction-for-v071)
- Tracking: [issue #27](https://github.com/hasanmanzak/meAndAI/issues/27)
- Delivery: [pull request #29](https://github.com/hasanmanzak/meAndAI/pull/29)
- Test: [TEST-0045](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md)

## Durable behavior

For an existing connected consumer, the launcher lists repository Actions
secret names before deciding which local credential files are required. A file
is optional only when its exact mapped repository secret already exists. GitHub
does not expose the stored value, and the launcher never attempts to read it.

If `MEANDAI_PROTOCOL_TOKEN` exists while `MEANDAI_RO_FG_PAT.txt` is absent, the
launcher uses the authenticated local `gh` identity to retrieve the exact
tagged workflow and clone the exact protocol commit needed by semantic
adoption. Existing Git-blob, manifest-commit, credential-history, redaction,
and no-overwrite gates remain active. Failure of that local identity to read
the private protocol repository is an actionable source-access blocker.

A missing target secret still requires its mapped file because local `gh`
authentication is a source-transport fallback, not secret provisioning. A new
repository still requires both files before remote creation.

## Evidence and continuation

The focused red test proved the old unconditional protocol-file requirement.
The focused pre-integration green run covered a file-free semantic-adoption
snapshot, missing-secret failure/recovery, and the new-repository gate. Its
provisional `TEST-0043` ID became `TEST-0045` after merged v0.7.0 work claimed
`TEST-0043`, `TEST-0044`, and `RISK-0044` through `RISK-0047`; BUG-0002 moved
to `RISK-0048` and target `v0.7.1`. The implementation is published in pull
request #29. The integrated focused run passed `TEST-0033` through `TEST-0042`
and `TEST-0045` in 62.7 seconds; the complete suite passed `TEST-0001` through
`TEST-0045` in 111.2 seconds with no unresolved fresh-diff blocker. Pull request
#29 then merged at `42e653e23ccb11034a735b8c3c420accf5f19964`, and annotated tag
[`v0.7.1`](https://github.com/hasanmanzak/meAndAI/tree/v0.7.1) resolves to that
exact release commit. BUG-0002 is complete.
