# 2026-07-28 - C# operational foundation portable packaging

## Directive and authority

The maintainer authorized sequential continuation after the second foundation
slice. [FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
/ [SUBF-0121](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0121)
/ [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) owns this
bounded slice. [DEC-0032](../../../docs/decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
retains the multi-application portable-JIT authority and
[DEC-0019](../../../docs/decisions/DEC-0019-hosted-runner-efficiency.md)
retains the two-runner workflow boundary.

This slice may add only the three non-behavioral entry shells, declarative
package inventory, C# packager/verifier, external release manifest, runtime
preflight, and same-byte Windows/Linux evidence. It does not implement
governance, adoption, or update behavior; publish a release; mutate a consumer;
transfer authority; or retire PowerShell.

## Delivered contract

- Exact assets are `maai-adoption.zip`, `maai-consumer-update.zip`, and
  `maai-governance.zip`, each framework-dependent `net10.0`, ordinary JIT,
  `UseAppHost=false`, non-self-contained, and RID-free.
- `packaging/operations-packages.json` declares project, asset, application,
  and entry-assembly identities independently. The active bundle-path
  recurrence prohibits deriving one path from another.
- `maai-operations-release-manifest.json` schema 1 binds source commit,
  `Microsoft.NETCore.App` `10.0.0` with `LatestPatch`, application schema
  interval `[1,1]`, asset length, and SHA-256.
- Verification rejects malformed/null/unknown/duplicate mappings, source or
  schema drift, digest/length mismatch, escaping or platform-specific archive
  content, and missing/incompatible runtime evidence before application work.
- Ubuntu constructs one clean exact-head package set and uploads it before its
  retained protocol suite. The independent existing Windows job completes its
  retained platform validation before downloading and executing those exact
  current-run bytes. No third runner, matrix axis, or job dependency is added;
  missing or late artifact evidence fails closed.

## Tests-first and local evidence

[TEST-0193](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193)
first failed only because the planned packaging project and contract types did
not exist. The focused Release compile reported `CS0246` in 4.1 seconds. An
earlier invalid `dotnet test --configfile` invocation did not reach the scenario
and is not evidence.

The bounded implementation passes 17 of 17 focused cases and 48 of 48 combined
C# cases. Locked restore passes; the complete Release solution builds with zero
warnings/errors; format/analyzer verification is clean. A real adoption publish
probe produced six flat managed/runtime files, no apphost/RID payload, and exact
`net10.0` / `Microsoft.NETCore.App` `10.0.0` / `LatestPatch` runtime config.
Fresh-diff review closed source/inventory binding, output containment and atomic
publication, null/ambiguous JSON, archive bounds, analyzer, workflow-topology,
and cross-record-link observations. Windows PowerShell 5.1 candidate-tree
StructureOnly passed in 211.2 seconds; the protocol-governance owner reported
208,942 ms. Local `actionlint` and Ruby are unavailable; no local success is
claimed for those tools.

## Completion and continuation

Exact implementation commit
[`956a2b8c3d0787b6133f5d7ed2eb2a1636294560`](https://github.com/hasanmanzak/meAndAI/commit/956a2b8c3d0787b6133f5d7ed2eb2a1636294560)
passed committed-tree StructureOnly in 208.8 seconds, built the clean exact-head
package set in 13.1 seconds, and verified/executed it locally in 2.6 seconds.
Exact-head [run `30329211045`](https://github.com/hasanmanzak/meAndAI/actions/runs/30329211045)
passed 48/48 compiled tests and the same uploaded bytes on
[Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30329211045/job/90180695565)
in 9 min 39 s and
[Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30329211045/job/90180695611)
in 31 min 23 s. A fresh download passed all digest/runtime checks and all three
Windows executions in 2.4 seconds. The slice is five of five gates and
[FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
is three of three subfeatures, or 100%. [Issue #154](https://github.com/hasanmanzak/meAndAI/issues/154)
and [draft PR #159](https://github.com/hasanmanzak/meAndAI/pull/159) remain the
external evidence authority. No merge, release, consumer mutation, authority
transfer, behavior implementation, or PowerShell retirement is authorized.
