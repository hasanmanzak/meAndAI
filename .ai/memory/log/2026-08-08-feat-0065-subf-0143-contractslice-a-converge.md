# ContractSlice A convergence evidence ledger

| Field | Value |
| --- | --- |
| Date | 2026-08-08 |
| Scope | ContractSlice A convergence audit |
| Contract | [Corrected V2 audit contract](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md#a-converge-02-freeze) |
| State | V1 immutable diagnostic/no success; V2 `FrozenDesign`/corrected-design hosted pending |
| Progress | A `19/20` (`95%`); cumulative A `32/32`; Domain `98/98` |
| Scenario | [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |
| Route | P/R/G `NotApplicable`; no `COHORT-SYNC-A-FINAL` |
| Holds | Final Scenario/status/owner, both workflow filters, runtime-efficiency scenario, B/C/D, merge, release, and publication |

The exact V1 frozen-design head and hosted run are retained in the corrected-V2
contract linked above. V1's hosted prerequisite passed Ubuntu `20m00s` and
Windows `47m15s`; publication verification was skipped. The external V1 script
was invoked once at `2026-08-08T18:12:20Z`, exited `1`, and must never be rerun.

| V1 evidence | Exact identity |
| --- | --- |
| Script | `C:\Users\hasan\AppData\Local\Temp\meandai-aconverge-v-7c698d7-20260808T1810Z.ps1`; `6,067` bytes; created `2026-08-08T18:11:42.9069938Z`; SHA-256 `72ED4127FB6C21016B17986E505D11B9B968A6AD3CD9D35DA5D977BCFAE344BD` |
| Evidence root | `D:\Temp\meandai-test-0210-a-converge-7430b916dbcb48479d1651995f3c1b3c`; exactly five TRXs |
| Results | Release build `0 warnings / 0 errors`; `1/1`, `32/32`, `11/11`, `32/32`, `98/98` passed |
| First failure | Exact `resource.trx/completed mismatch.`; actual `completed=0`; exit `1` |
| Later V1 gates | Format, StructureOnly, publication-evidence, locks, and final diff were not executed |
| Console custody | Output observed; independent stdout/stderr files and hashes not retained |
| TRX hashes | resource `7443774A4F12EB9AA1FD4598C01CADBE62CC657C454CD102F0BD8E365195D49B`; A `91514FDDE177F8C1AA0D876D833429C8F087F2517254A9B8A9AEC723A79150B3`; API/ownership `E3883B5DF1CFB3329AAC25A5C686B8EE04FE9EEC9ACC056D3FAEFBBB775DA18D`; Conformance `31D4BD4AE9C32C9C887039A4013E3BB26A7E76A4B682181DF14FFA119283B521`; Domain `935390C812898A3C2A7C54EB04AB887E3741E4C22000D117112306D24175B9F7` |
| Corrected-design checks | StructureOnly green `434.481s`; publication evidence `7/7` in `295.6s`, no publication claim; D/RT/content reviews `0/0/0` |

Renewed V2 D/RT closed `0/0/0`. V2 changes only the 16-counter partition:
`total`, `executed`, and `passed` equal the expected count; `completed` and the
other twelve terminal/non-success counters equal zero. Its canonical LF plus
terminal-LF script is `6,068` bytes with SHA-256
`D28C16C76B5E1A171640FDEB7BF650BAF8482BFED6BAEB6C3A0B7A440EBDCD25`.
V2 requires a fresh external script path/root and one invocation only after
this corrected-design records commit is exact-head hosted green.
