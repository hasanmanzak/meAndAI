# Optional Credential-Source Files

- Date: 2026-07-15
- Target release: `v0.6.3`
- Work item: [BUG-0002](../../../docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0002-correction-for-v063)
- Tracking: [issue #27](https://github.com/hasanmanzak/meAndAI/issues/27)
- Test: [TEST-0043](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md)

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
The focused green run passed `TEST-0033` through `TEST-0043`, including a
file-free semantic-adoption snapshot, missing-secret failure/recovery, and the
new-repository gate. The bounded fresh-diff review left no unresolved blocker,
and the final complete run passed `TEST-0001` through `TEST-0043` in 103.8
seconds. Pull-request, merge, and tag evidence remain to be recorded before
release closure.
