# ContractSlice A target parser/index/slot reviewed-local-green handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-02 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-TARGET-PARSER-INDEX-SLOT-01` is `ReviewedLocalGreen`; canonical R is immutable; local G/V/reviews are complete; the current green tree still awaits commit, push, and exact-head hosted validation |
| Activation baseline | [FIND-0449](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0449) is resolved by exact [`9180b1ff300534ab38d34d2227ab2f79878c9007`](https://github.com/hasanmanzak/meAndAI/commit/9180b1ff300534ab38d34d2227ab2f79878c9007), git tree identity: `1ebabf4091d9ee9d2a77ef9eb22fa7be1bc4c434`, and [run 30758284884](https://github.com/hasanmanzak/meAndAI/actions/runs/30758284884), which passed Ubuntu and Windows; publication verification was correctly skipped |
| Implementation predecessor | Exact [`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602), git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`, and [run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121) passed Ubuntu and Windows |
| Progress | Nine of twenty packets are `ReviewedLocalGreen` (`45%`); cumulative A is `22/22`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen identity and graph

- FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceATargetParserIndexSlotManifestTests.Enforces_exact_repository_target_schema_parser_index_and_slot_capability_closure`; marker/TRX `TEST-0210-A-BEHAVIOR-RED-0007`; one Fact; only `ContractSlice=A`; no `Scenario`.
- Exact topology is `3 schema / 2 parser / 4 index / 4 evaluation slot`, demand/admission `0/0`, `20` components, `3` artifacts, and unchanged cache `(512,67108864,128,2000000,8,4,retain-lowest-canonical-keys)`. Exact `2/1/2/2` and `2/1/3/3` predecessors remain valid; hybrid or partial target verticals fail closed.
- Orders remain schemas governed-text/target-resolution/repository-tree; parsers Markdown/target-Markdown; indexes governed-reference/protocol-record/target-resolution/repository-tree; slots provider-governed/repository-governed/target-resolution/repository-tree. The retained test owns exact identities, budgets, failures, input/cardinality order, lookups, component/artifact/cache closure, fourteen partial-removal negatives, the sole valid whole-target removal, and held-array rejection.
- Production owner is only `CatalogSliceDeclaration.cs`; Reader/Writer are regression-only. Catalog SHA-256 is `2F370175B36BACCC0D3F328F2E23991BC15D1E2A8F6F681C37A28189F93D397B`; retained test is `401` lines at SHA-256 `3F78C84F5E65CE956AB6D1615BEE35CC161A97CE59879E888A3506C7B1631C6B`. Gross size is production `96/180`, test `401/500`, combined `497/680`.

## Immutable red and green evidence

- Locked restore preserved all six package-lock hashes. Predecessor focused `1/1`: `C:\Users\hasan\AppData\Local\Temp\meandai-test-0210-a-predecessor-0007-9180b1f\TEST-0210-A-PREDECESSOR-FOCUSED-0007.trx`, SHA-256 `10B911AFD890CB37E5B8785A5FB30A6F3B45778E4816C46E5B44E5067F747757`; predecessor cumulative A `21/21`: sibling `TEST-0210-A-PREDECESSOR-CUMULATIVE-0007.trx`, SHA-256 `C008E18DD81E9781C983702C67802881C44757F0151583E82BBC7D2E8A0F13ED`.
- Canonical R ran exactly once and must not be retried: `C:\Users\hasan\AppData\Local\Temp\meandai-test-0210-a-red-0007-9180b1f-7f8c31\TEST-0210-A-BEHAVIOR-RED-0007.trx`, SHA-256 `DF598554D162561D09A08D9E83C35C145A0C981B35072D011C8430257D82E346`. The exact FQN failed `1/1` in `62.8409ms`; all sixteen counters, exact marker/message, marker-free standard stack and RunInfo, one allowed stdout marker echo, no attachments, and the single-file directory oracle passed.
- Transient green focused `1/1`: `C:\Users\hasan\AppData\Local\Temp\meandai-test-0210-a-green-transient-0007-9180b1f\TEST-0210-A-TRANSIENT-GREEN-0007.trx`, SHA-256 `75CCCA4AEFD6C38173CB45968BB8FE3BF5EA32311A6A4B903D9B1F31AE54643B`.
- Retained focused green `1/1`: `C:\Users\hasan\AppData\Local\Temp\meandai-test-0210-a-green-retained-0007-9180b1f\TEST-0210-A-RETAINED-FOCUSED-GREEN-0007.trx`, SHA-256 `ACF5938C7A6F8558C27A0387C570496B04781D283D4C5079B8346D303B3ECDED`; retained cumulative A `22/22`: sibling `TEST-0210-A-RETAINED-CUMULATIVE-GREEN-0007.trx`, SHA-256 `EC4CFB616A952DD3A796B4E3FBD0EF47D75933F92111A906647968C3F9B6F986`.

## Validation, review, and holds

- Full Domain is `98/98`; full Conformance is `22/22`; Release build is `0 warnings / 0 errors`; format, diff, allowlist, six locks, marker, trait, and retained-source checks are green. StructureOnly passed every discovered contract in `352.7` seconds (`elapsedMs=350665`).
- Independent code review, regression red-team, and evidence audit each closed `0 Blocking / 0 Important / 0 Minor`. The current tree may become the next predecessor only after commit, push, and exact-head Ubuntu/Windows green.
- `A-FINDING-01` and every later packet remain Candidate/inactive. Projector/DAG, finding, selector, admission, profile/predecessor/transition, lifecycle/resource, final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D, merge, release, publication, and consumer mutation remain held.
