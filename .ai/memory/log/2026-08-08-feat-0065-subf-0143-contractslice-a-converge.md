# ContractSlice A convergence evidence ledger

| Field | Value |
| --- | --- |
| Date | 2026-08-08 |
| Scope | ContractSlice A convergence audit |
| Contract | Corrected V4 audit contract in the owning typed design |
| State | V1/V2/V3 diagnostic; V4 fully green; A `CompletionRecommended` locally; final-sync head hosted pending |
| Progress | A audit `20/20` (`100%`); cumulative A `32/32`; Domain `98/98` |
| Scenario | Parent scenario remains `Planned` |
| Route | P/R/G `NotApplicable`; `COHORT-SYNC-A-FINAL` applied locally; no activation |
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
retried.

## V3 final-sealing diagnostic

V3 design head
[`4f332a8321e911e78b02df82eab817de681f7ed6`](https://github.com/hasanmanzak/meAndAI/commit/4f332a8321e911e78b02df82eab817de681f7ed6)
passed Ubuntu `19m34s` and Windows `48m04s` in run `31277744559`; publication
was skipped. Its sole invocation exited `1` after `780.5s` and is never rerun.

| V3 evidence | Exact identity |
| --- | --- |
| Script | `D:\Temp\meandai-aconverge-v3-2f34c958ccd74d51ad3da23ac17e50b4.ps1`; `9,244` bytes; SHA-256 `D03FD93432FA3BAF53338ADD7CF71A222F49BE84432C801A945D8B41ED29E48E`; created/write `2026-08-08T21:39:15.3406702Z` / `2026-08-08T21:39:15.3433062Z` |
| Evidence root | `D:\Temp\meandai-test-0210-a-converge-v3-2f34c958ccd74d51ad3da23ac17e50b4`; exactly six regular files |
| Entry | `151` bytes / `04EA801C57139664BC273BD85AE1A24E3A120D4AECA7700BCF0243DB055269CE`; schema `1`, attempt `V3`, state `Completed`, entered/completed `2026-08-08T21:41:02.3857958Z` / `2026-08-08T21:54:01.4468830Z`, PID `209224`; no terminal COMPLETED marker |
| Results | Release build `0 warnings / 0 errors`; `1/1`, `32/32`, `11/11`, `32/32`, `98/98`; format, StructureOnly `442.072s`, publication evidence `7/7`, locks, diff, source and both inventory gates green |
| TRX hashes | resource `27E148E007FA8097A15CBF6612BB70FD9487F5B2AFC14D4E18BA256D8E82A914`; A `A14088BF251C640168244282315C17D1B4CB173A8731A52D3A44BFDC605A9C75`; API/ownership `2441EDA86787CD37936435E0381440223D99DEB2762EC5FBE72124E2DE599A5A`; Conformance `3E49441CFA9E96397A021B86A26F15FB89B2BAB535046EA51F438EB5B8138014`; Domain `1710A761000E24449988BF2E270A1F60A61FF6AFBEEF42B227EC9B21FFC6912F` |
| First failure | Default `ConvertFrom-Json` coerced ISO strings to `DateTime`; culture text `08/08/2026 21:41:02` failed invariant `ParseExact('O')`; chronology and terminal success marker were not reached |

V3 is immutable `InScriptFailure/NoSuccess`. V4 changes only final timestamp
sealing to preserve exact strings; all other audit oracles and holds remain.

| V4 fully-green evidence | Exact identity/result |
| --- | --- |
| Design gate | Exact [`56954d4fb2bb783e14619bd8ab6cffc3e578271d`](https://github.com/hasanmanzak/meAndAI/commit/56954d4fb2bb783e14619bd8ab6cffc3e578271d); [run 31282194746](https://github.com/hasanmanzak/meAndAI/actions/runs/31282194746): Ubuntu `19m23s`, Windows `47m21s`, publication skipped |
| Script/invocation | `D:\Temp\meandai-aconverge-v4-91a7c6e4c5e349a0b22e3f37d5d0f84a.ps1`; created/written `2026-08-08T23:33:00.6476850Z` / `2026-08-08T23:33:00.6515131Z`; `10,338` bytes / `2232F691F8671CD256A79D2AE381423469CB046B4FC43F0F5DDEB289816C5019`; AST `1774/69/0`; exact PS `7.6.4`; sole attempt exit `0` in `786.8s` |
| Root/entry | `D:\Temp\meandai-test-0210-a-converge-v4-91a7c6e4c5e349a0b22e3f37d5d0f84a`; six regular files; entry `209` bytes / `9E491FB1749C4A9A7741E08ED2BF7BFCB48687B8AAA9C1A3276C1FA67D47879A`; exact V4/head/Completed/PID `144728`; UTC interval `785.9280248s`; strict UTF-8/LF/property/chronology gates green |
| Artifact hashes | resource `334FCD57299AAC347CB1FA44597C8D616E4C3CA635718B1149ACA993390C214A`; A `AC532EBAE1E92E35907E49CE28C3C2A0DA237B8F5E2C4EF0A9CE4BAEEC51F57E`; API `707F89187F2839F36871385D23FD4229ADFE1F572BBF45D088479C3691C01C1E`; Conformance `D145082BF2AC0674AA2CDCA3DEF3670FD1F3F95D860411B66B321FD98A5E7564`; Domain `1462473D5AFCD7FC3E5960BBA9D50278E05D4E3B5B4D34C60943E22EEB28B086` |
| Oracles/gates | Result-definition-entry `1/32/11/32/98`; frozen FQN digests and bijections exact; all Passed; exact 16 counters; no diagnostics/attachments; build `0/0`, format, StructureOnly `438.333s`, publication `7/7` without publication claim, locks/diff/source/inventory/sealing green; reviews `0/0/0` |
| Result | `FullyGreen`; A `CompletionRecommended`; A audit `20/20`, cumulative A `32/32`; local final-sync StructureOnly `435.809s`, publication `7/7`, graph `356/4096/311/4192113`; parent scenario remains `Planned`; all activation/B/C/D/merge/release/publication holds retained |
