# 2026-07-28 - [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md) [FIND-0365](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0365) [TEST-0106](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) readiness correction

## Directive and boundary

The maintainer separately authorized the focused correction after the
records-only [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
head exposed a canonical Windows validation failure. The owning behavior is
[FEAT-0020](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/README.md) /
[TEST-0106](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
test infrastructure. This authorization does not start
[FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
C# implementation or permit a production, workflow, consumer, timeout,
authority, adoption, update, or PowerShell-retirement change.

## Red evidence and cause

Exact head
[`9fa453b58a39817839beaff98927f7654419f950`](https://github.com/hasanmanzak/meAndAI/commit/9fa453b58a39817839beaff98927f7654419f950)
passed Ubuntu but failed only
[TEST-0106](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
in the Windows PowerShell 5.1 job of
[run `30358996927`](https://github.com/hasanmanzak/meAndAI/actions/runs/30358996927).
The test, fixture, and production bounded-process blobs were unchanged from a
prior passing exact head. A six-second delayed-child initialization then
reproduced the exact generic failure locally in 20.4 seconds.

The fixture child owned `child.pid` publication after script initialization,
its parent imposed a separate five-second file wait, and the outer harness
waited ten seconds without observing early async completion or calling
`EndInvoke` on the failed branch. This could reject the test before exercising
cancellation and conceal the actual pipeline result.

## Correction and current evidence

The fixture parent now publishes the exact child ID returned by
`Start-Process -PassThru`; the child no longer owns readiness publication. The
outer harness observes early pipeline completion, stops and drains a timed-out
pipeline, emits bounded detail, and requires both published processes to be
active before cancellation. The 10-second readiness, 120-second operation,
five-second exit confirmation, process-tree termination, and temporary-root
cleanup assertions remain unchanged.

The deterministic delayed-child Windows-native shard passes on PowerShell 7 /
Windows PowerShell 5.1 in 10.3 / 15.5 seconds. The canonical
[TEST-0105](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
and
[TEST-0106](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
owner emits its exact pass manifest on both runtimes in 16.6 / 14.9
seconds; the final atomic-publication and independent partial-PID review
repeated the pass in 10.1 / 14.7 seconds. Production and workflow files are
unchanged. Full-profile,
StructureOnly, exact-commit, and hosted evidence remain pending.

## Continuation

Complete the single PS5.1 `WindowsNative` profile that reproduces the old-head
failure, perform fresh-diff review, update the evidence records, run
StructureOnly on both supported runtimes, commit the complete packet, repeat
exact-commit validation, and push once. Accept closure only after a new exact
head passes both protected Ubuntu and Windows jobs; do not rerun the unchanged
failed head.
