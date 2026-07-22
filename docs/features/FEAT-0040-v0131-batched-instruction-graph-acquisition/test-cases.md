# FEAT-0040 Test Scenarios

Canonical executable ownership is singular: TEST-0161 belongs to the existing
instruction-graph-discovery suite and TEST-0162 belongs to the existing test-
runtime-efficiency suite. Initial-adoption and workflow capability surfaces
provide supporting evidence without becoming duplicate scenario owners; no new
parent-runner process is introduced merely for this feature.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0161` | `SUBF-0078` | Measure the exact v0.13.0 quick/hosted per-blob process boundary; exercise zero, one, many, cyclic, and duplicate-content graph reads through a lazy actor-local batch session; include LF, NUL, and header-like payload bytes plus process-start failure, broken stdin, stderr overflow, hung/unreapable child, wrong/missing OID, type, canonical length, hash, early EOF, trailer, extra output, non-zero exit, reentrant read, builder/validator fault, replace-object isolation, and header/per-blob/aggregate N/N+1 variants; inspect both production actor sources, inventory independent test readers separately, and run unhooked real-Git parity. | Zero parsed blobs start zero processes; any positive acquisition starts exactly one process and one request per parsed blob; exact ASCII-LF requests, raw responses, bounded concurrent stderr, immutable production deadlines, virtual-clock test execution, replace-ref isolation, and graph identity match the contract in both actors; malformed, drifted, over-budget, duplicate alternate transport, restored per-blob process, or leaked session blocks before success; the stable fixture observes exactly `4 -> 2` aggregate blob processes and `4 -> 4` requests without counting independent expected-evidence readers as production savings. | Binary transport / lifecycle / exact Git / boundary / operation ratchet / negative / cross-runtime | Focused PS5.1/PS7 and Windows Full green; hosted confirmation pending | `tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1` |
| `TEST-0162` | `SUBF-0079` | Execute the affected focused owners, quick-adoption and bootstrap integration routes, Windows PowerShell 5.1 and PowerShell 7, Linux PowerShell 7, `WindowsNative`, Full, structural/version/publication checks, and the existing hosted topology while comparing exact v0.13.0 and candidate operation observations, schema-2 provenance, and elapsed hotspots. | Every active scenario retains one canonical owner and faithful evidence level; deterministic process/request budgets, exact measurement bindings, and source/parity ratchets pass; one Windows and one Ubuntu job remain without fan-out; elapsed time is reported observationally; independent test-reader residual receives an explicit disposition; any missed goal receives an explicit owner and disposition. | Integration / compatibility / scenario authority / workflow / hosted performance observation | Focused PS5.1/PS7, supporting integrations, WindowsNative, Full, and post-review confirmation green; hosted pending | `tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1` |

## Required coverage

- Exact immutable-v0.13.0 process/request baseline and strictly lower reviewed
  process-start maximum.
- Lazy zero-process behavior and one-session behavior for one or many blobs.
- Binary payloads containing LF, NUL, header-like text, and non-text UTF-8 bytes.
- Canonical OID/type/decimal length, exact payload/trailer, Git blob hash, and
  graph request/byte parity.
- Missing, ambiguous, malformed, wrong-identity/type/size/hash, early EOF,
  extra output, non-zero exit, and reentrant/concurrent failures.
- Process-start failure, exact ASCII-plus-LF request bytes, broken stdin,
  bounded concurrent stderr overflow, common-deadline timeout, hung child, and
  abort-reap survivor failure.
- A private session-factory hook with exactly transport-factory and monotonic-
  clock callbacks; production entry points cannot accept it, production limits
  stay literal, and all time failures execute without real sleeps.
- Exact per-blob, aggregate-byte, request-count, header-size, stderr-size, and
  session-deadline N/N+1 limits.
- Builder, validator, UTF-8, depth, and graph-budget faults with process/pipe
  cleanup and no mutation-boundary leakage.
- Quick/hosted source and real-Git digest/count parity without moving process
  I/O into the pure graph module.
- A committed repository with an active replace ref proves the default
  production process ignores replacement objects and returns the original
  tree-addressed blob.
- Schema-2 ordered measurement preservation plus missing, unknown, duplicate,
  reordered, and valid-known-but-cross-work `MeasurementId` failures; exact
  owner/route/counter totals and per-actor assertions remain distinct from the
  175-blob external workload.
- Static and dynamic prevention of direct per-blob production `cat-file`
  restoration or an undeclared alternate Git transport.
- Separate inventory and retained-or-follow-up disposition for independent
  quick/bootstrap/instruction-graph expected-evidence readers.
- All existing graph, FullMigration closure, product protection, security,
  recovery, TOCTOU, link/reparse, credential, and Windows-native authorities.
- Windows PowerShell 5.1, Windows/Linux PowerShell 7, one Windows job, one Ubuntu
  job, exact-main reuse, and bounded post-publication topology.

## Baseline evidence

| Date | Commit | Environment | Command or run | Result |
| --- | --- | --- | --- | --- |
| 2026-07-22 | Candidate head `88005e5b7b0b095044197d2c5513f2cd708faeec`; tree-identical immutable v0.13.0 merge `299b8982cd57961e2b3a6136b07af3bfb49a16d1` | GitHub-hosted Ubuntu / PowerShell 7 and Windows / PowerShell 5.1 | [Run 29921546402](https://github.com/hasanmanzak/meAndAI/actions/runs/29921546402) plus exact-main [run 29923220827](https://github.com/hasanmanzak/meAndAI/actions/runs/29923220827) | Ubuntu 5:33 total, 5:22 validation, quick/bootstrap/graph 138.249/46.956/51.241s; Windows 20:33 total, 20:04 validation, quick/bootstrap/graph 723.326/202.782/130.214s; all v0.13.0 operation maxima matched |
| 2026-07-22 | Immutable v0.13.0 merge `299b8982cd57961e2b3a6136b07af3bfb49a16d1` | Isolated exact clone; Windows x64; Windows PowerShell 5.1.19041.7548; Git 2.55.0.windows.3 | Observer `meandai.task-0002.instruction-graph-blob-process-observer` schema 1, digest `sha256:1f0471fbe882ce959afe52f65713a4f3332c3ba0bc1616db0c5b256687fcf4a8`; Trace2 exact `start`/argv filter cross-checked with graph counts | Quick 52.440s and bootstrap 49.821s; each: 1 tree process, 175 blob processes/requests/unique OIDs, 1,332,781 parsed bytes, graph digest `685ad9b3797bc7406459986a4b5f28c771cea6acba8534dfdc891083857d3c99`; target is one blob process with 175 unchanged requests |
| 2026-07-22 | FEAT-0040 planning tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Expected red: exactly two `TEST-0074` findings report missing canonical authority for `TEST-0161` and `TEST-0162`; no unrelated structural problem |
| 2026-07-22 | FEAT-0040 expected-red tree | Windows PowerShell 5.1 | Focused instruction-graph-discovery owner | Expected red in 146.507s: exactly six TEST-0161 findings, three per actor (missing batch factory, retained per-blob path, missing literal-limit factory call); TEST-0151/0152 and parsing remain intact |
| 2026-07-22 | FEAT-0040 expected-red tree | Windows PowerShell 5.1 | Focused test-runtime-efficiency owner | Expected red in 8.3s: 25 controlled TEST-0162 findings for schema 2, measurements/bindings/route, and missing actor batch transport; no parse or null crash |
| 2026-07-22 | FEAT-0040 expected-red tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Pass in 6.0s; TEST-0161 and TEST-0162 each have one canonical executable owner |

## Implementation evidence

| Date | Commit | Environment / route | Result |
| --- | --- | --- | --- |
| 2026-07-22 | `78c8706e9d4d4f4c020d983b22114165687b475e` | PowerShell 7 / focused instruction-graph owner | TEST-0151, TEST-0152, and TEST-0161 passed in 84.1s; operation evidence was exactly 2/2 blob processes and 4/4 requests |
| 2026-07-22 | `78c8706e9d4d4f4c020d983b22114165687b475e` | Windows PowerShell 5.1 / focused instruction-graph owner | TEST-0151, TEST-0152, and TEST-0161 passed in 147.6s; operation evidence was exactly 2/2 blob processes and 4/4 requests |
| 2026-07-22 | Implementation tree through `55764442820c884e8c3115726bb010a0a9004d77` | PowerShell 7 and Windows PowerShell 5.1 / focused test-runtime owner | TEST-0158, TEST-0159, and TEST-0162 passed in 5.3s and 6.5s respectively |
| 2026-07-22 | Implementation tree through `55764442820c884e8c3115726bb010a0a9004d77` | Windows PowerShell 5.1 / structural and supporting integration routes | `StructureOnly` 4.8s; source dispatch 2.6s; bundle 23.0s; final quick instruction closure 38.2s; local hosted-bootstrap `VerticalSlices` 280.3s; all passed |
| 2026-07-22 | `55764442820c884e8c3115726bb010a0a9004d77` | Shared full-HEAD expected-graph fixture / PowerShell 7 and Windows PowerShell 5.1 | Passed in 22.2s and 34.8s with identical digest `d0a03bde53b7652706059b5faf74ad9f748da9c0a3401df44eeea6ee365fe091`, 178 parsed blobs, and 1,371,315 parsed bytes |
| 2026-07-22 | Candidate v0.13.1 working tree | Windows PowerShell 5.1 / `WindowsNative` profile | Passed in 343.0s; streaming owner 6.493s and quick-adoption owner 331.854s; canonical compatibility evidence emitted |
| 2026-07-22 | Candidate v0.13.1 working tree | Windows PowerShell 5.1 / Full profile | All discovered suites passed in 1,306.9s; quick adoption 742.281s, hosted bootstrap 253.297s, instruction graph 145.462s, and test-runtime owner 9.706s; TEST-0161 retained exact 2/2 process and 4/4 request observations |
| 2026-07-22 | Post-`FIND-0200` confirmation | Windows PowerShell 5.1 and PowerShell 7 / focused TEST-0162 plus structural owner | Focused TEST-0158/0159/0162 passed in 9.3s and 9.2s after the third independent expected reader gained exact one-batch/zero-per-blob regression ownership; `StructureOnly` passed in 7.8s |

The production actor boundary is now deterministically `175 processes / 175
requests -> 1 process / 175 requests` per positive acquisition. The separate
expected readers remain test-owned and do not import production transport.
Their batching is test-runtime evidence, not part of the production saving.
No wall-clock improvement is claimed. The local Windows PowerShell 5.1 Full
result was 1,306.9 seconds, including quick/bootstrap/graph observations of
742.281/253.297/145.462 seconds; those values are not directly comparable with
immutable hosted observations from a different environment. Hosted
Windows/Linux, pull-request, merge, and release evidence remain pending.
