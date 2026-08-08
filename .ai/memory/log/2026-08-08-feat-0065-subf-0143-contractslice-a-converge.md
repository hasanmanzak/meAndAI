# ContractSlice A convergence evidence ledger

| Field | Value |
| --- | --- |
| Date | 2026-08-08 |
| Scope | ContractSlice A convergence audit |
| Contract | Corrected V3 audit contract in the owning typed design |
| State | V1 diagnostic; V2 `AttemptInvalidated/NoInvocation/NoSuccess`; V3 `FrozenDesign`/inactive, D/RT `0/0/0`, hosted gate pending |
| Progress | A `19/20` (`95%`); cumulative A `32/32`; Domain `98/98` |
| Scenario | Parent scenario remains `Planned` |
| Route | P/R/G `NotApplicable`; no `COHORT-SYNC-A-FINAL`; A stays `19/20` |
| Holds | Final Scenario/status/owner, both workflow filters, runtime-efficiency scenario, B/C/D, merge, release, and publication |

The owning typed design retains V1 head/run. Its hosted prerequisite passed;
the external script ran once at `2026-08-08T18:12:20Z`, exited `1`, and is never rerun.

| V1 evidence | Exact identity |
| --- | --- |
| Script | `C:\Users\hasan\AppData\Local\Temp\meandai-aconverge-v-7c698d7-20260808T1810Z.ps1`; `6,067` bytes; created `2026-08-08T18:11:42.9069938Z`; SHA-256 `72ED4127FB6C21016B17986E505D11B9B968A6AD3CD9D35DA5D977BCFAE344BD` |
| Evidence root | `D:\Temp\meandai-test-0210-a-converge-7430b916dbcb48479d1651995f3c1b3c`; exactly five TRXs |
| Results | Release build `0 warnings / 0 errors`; `1/1`, `32/32`, `11/11`, `32/32`, `98/98` passed |
| First failure | Exact `resource.trx/completed mismatch.`; actual `completed=0`; exit `1` |
| Later V1 gates | Format, StructureOnly, publication-evidence, locks, and final diff were not executed |
| Console custody | Output observed; independent stdout/stderr files and hashes not retained |
| TRX hashes | resource `7443774A4F12EB9AA1FD4598C01CADBE62CC657C454CD102F0BD8E365195D49B`; A `91514FDDE177F8C1AA0D876D833429C8F087F2517254A9B8A9AEC723A79150B3`; API/ownership `E3883B5DF1CFB3329AAC25A5C686B8EE04FE9EEC9ACC056D3FAEFBBB775DA18D`; Conformance `31D4BD4AE9C32C9C887039A4013E3BB26A7E76A4B682181DF14FFA119283B521`; Domain `935390C812898A3C2A7C54EB04AB887E3741E4C22000D117112306D24175B9F7` |
| V3 design checks | StructureOnly green `441.298s`; publication evidence `7/7` in `295.3s`, no publication claim; D/RT/content reviews `0/0/0` |

## V2 launcher diagnostic

The exact hosted V2 head/run are owned by the typed design: Ubuntu
passed `19m37s`, Windows `37m52s`, publication skipped. V2 script path is
`D:\Temp\meandai-aconverge-v2-7bf97ad-20260808T191642Z-83a78b49cc3d4ef9bfd63c0dfdc5d859.ps1`;
created `2026-08-08T19:54:58.4635350Z`, `6,068` bytes, SHA-256
`D28C16C76B5E1A171640FDEB7BF650BAF8482BFED6BAEB6C3A0B7A440EBDCD25`.
Its authorized launcher admission returned exact `CreateProcessAsUserW failed:
5` in `0.1s` before the outer shell existed. No child, root, exit code, or
stdout/stderr exists. V2 is immutable attempt-invalidated evidence and is never
retried. V3 freezes a predeclared root, entry marker, new script identity, and
one exact escalated launcher; D/RT is `0/0/0`, but activation remains held until
this exact synchronized design head is hosted green.
