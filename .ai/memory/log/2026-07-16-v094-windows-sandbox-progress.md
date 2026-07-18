# v0.9.4 Windows Sandbox and Progress Correction

- Date: 2026-07-16
- Status: Complete; publication pending
- Feature: [FEAT-0019](../../../docs/features/FEAT-0019-v094-sandbox-progress-correction/README.md)
- Tests: [TEST-0103 and TEST-0104](../../../docs/features/FEAT-0019-v094-sandbox-progress-correction/test-cases.md)
- Issue: [#55](https://github.com/hasanmanzak/meAndAI/issues/55)
- Pull request: [#56](https://github.com/hasanmanzak/meAndAI/pull/56)

## Durable continuation

The v0.9.3 launcher ignored the maintainer's working native Windows sandbox
selection when starting isolated semantic Codex execution. On the reproduced
host, `elevated` setup fails with Access Denied while `unelevated` passes a
model-free workspace write/read/delete probe. The v0.9.4 correction reads only
that sandbox selection, verifies it before a model call, safely falls back to
the still-sandboxed implementation, and passes only the verified mode to
`codex exec`; full-access bypass is prohibited.

Empty consumers may keep product purpose, runtime/stack, architecture, build
command, and product test command as `Not yet established`. That absence does
not block structural protocol adoption and does not authorize fabricated
facts. Launcher progress follows real phases, represents local Codex as
indeterminate elapsed work, and can be disabled with `-NoProgress`.

The retained affected-consumer proposal recorded in
[issue #55](https://github.com/hasanmanzak/meAndAI/issues/55)
remains pinned to `v0.9.2`. Resume it with the corrected launcher plus
`-ProtocolTag v0.9.2`; do not reset, duplicate, or retarget the proposal.

Local verification completed on 2026-07-16: the focused quick-adoption suite
passed all 34 owned scenarios in 359.1 seconds, and the complete protocol suite
passed every discovered suite and scenario-ownership gate in 526.4 seconds.

Merge, immutable release, asset digest, hosted checks, and consumer rerun
evidence remain external facts owned by issue #55 until they occur.
