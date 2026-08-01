# SUBF-0143 ContractSlice A schema-slot packet

## Boundary

- Packet: `A-SCHEMA-SLOT-01`; packet-local `ReviewedLocalGreen` on local branch `codex/subf-0143-contract-slice-a-implementation`. Draft PR #174 is the authorized publication target and remains pending this packet's commit/push.
- Exact predecessor: [`c88beefee54f3f0d0e0e623807eb8a4c9bf48032`](https://github.com/hasanmanzak/meAndAI/commit/c88beefee54f3f0d0e0e623807eb8a4c9bf48032), tree `47a80b3c4c5301ac3937bcd12099940df74830b8`.
- FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceASchemaSlotManifestTests.Enforces_exact_schema_and_zero_capability_evidence_slot_closure`.
- Marker/TRX: `TEST-0210-A-BEHAVIOR-RED-0003`; frozen reviewed red-source SHA-256 `128C3CAF24BB029CBE3C85ABEB4434B54DC2D90B29EED436B8343990E91E57DB`.
- Final test source is 436 lines, SHA-256 `FC43FDDA4B273BFCBED442FB145E28BA207EE433A08A9D3E43BEA88574154480`, with only `ContractSlice=A`; TEST-0210 remains `Planned`.

## D, red-team, and predecessor proof

The positive owns schema `protocol.repository-tree` / `1` and slot
`protocol.slot.repository-tree` with zero capabilities. It closes codec/model, budget/failure,
bidirectional schema/slot closure, and equal SlotKey reuse. Nonempty capability stays fail-closed
until `A-PARSER-INDEX-01` supplies a producer.

Initial RT's one Blocking typed-boundary leak was dispositioned by reusing
`RuleDeclaration.SlotsEqual` from global `CatalogSliceDeclaration.CanonicalRules`, including
CompleteCatalog. Revised D passed `0/0/0`. The five-file code/test allowlist is reader, writer,
CatalogSliceDeclaration, RuleDeclaration, and the new test; final production `256` plus test
`436` is `692/700` changed lines, with the estimated `+2` still inside the hard cap.

The single locked restore passed with all six protocol lock SHA-256 values unchanged.
Release test-project build had zero warnings/errors; prior A-RULE passed `1/1` and
cumulative A passed `17/17`. P is `NotApplicable`; later build/test used `--no-restore`.

## Diagnostic red and FIND-0443

The first 0003 invocation at `D:\Temp\meandai-test-0210-a-cf51d3e38d6a41c1a45c30eb5edf6e94\TEST-0210-A-BEHAVIOR-RED-0003.trx`
remains diagnostic because the then-frozen micro plan incorrectly prohibited the locked
adapter's sibling StackTrace. [FIND-0443](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443)
and its [clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5150679793)
permit zero or one nonempty marker-free same-result StackTrace; no other ErrorInfo content,
independent diagnostic, or attachment is allowed.

The red source kept construction outside the exact runtime-type/message writer catch and covered
equal reuse, nested grammar, unambiguous component mutations, and exact typed conflict. After stale
indexes were corrected, renewed nine-record/source reviews closed `0/0/0`. The second run at
`D:\Temp\meandai-test-0210-a-9a39c31356614537b6a6f0eac0083c56\TEST-0210-A-BEHAVIOR-RED-0003.trx`
technically passed the corrected oracle but remains diagnostic because it preceded complete sync.

## Infrastructure diagnostic and canonical red

The new-empty `c96f8fa926734506b50d17637e4e2dbe` directory produced one TRX, SHA-256
`F4190734BC91DB6879DCCC92633BBCB6DF4B9400A8CD4D47A7C6DF9030358C3A`, but default-90-second
VSTest aborted before discovery. It has no UnitTestResult, all 16 counters zero, and one
infrastructure Error RunInfo naming exited PID 211000; it is not R.

The one authorized child-`300`/outer-`420s` replacement in new-empty `96ff2a5352c141f78f8bebbfc0f957f0`
exited `1` and produced only `TEST-0210-A-BEHAVIOR-RED-0003.trx`, SHA-256
`4B7B8398362E23B9364BBB7C11C4A538BA984B3474A52F2D95567CB340545FDE`. Its sole exact-FQN result,
marker, permitted stack/echo/RunInfo, 16 counters, and absence of attachment/independent diagnostic
passed; the parent timeout remained unset. Canonical R is accepted and no further red retry is authorized.

## Bounded green and local V

Original-oracle green passed `1/1` at `D:\Temp\meandai-test-0210-a-green-d223831945254a88b29b723f0a07f3e3\TEST-0210-A-GREEN-0003.trx`, SHA-256 `EF73BE838513986CA8FB9D41D1FC2B34D98CC3E31C650638B15158A7B115BB80`.
After marker/catch removal and the neutral `TEST-0001` fixture-data correction, topology-clean focused green passed `1/1` at `D:\Temp\meandai-test-0210-a-green-final-topology-64237a9f1c384c1fb5adef025948cfe0\TEST-0210-A-GREEN-FINAL-0003.trx`, SHA-256 `A8552AF906E45AFB22A85BF0F3B61DDFD8AFA813036AA78292180C1BC32A2ACD`.
Cumulative A passed `18/18` at `D:\Temp\meandai-test-0210-a-cumulative-topology-retry-c93d714f03894591b62e498df55931c3\TEST-0210-A-GREEN-CUMULATIVE-0003.trx`, SHA-256 `920BC60B161595E97D12544836D5B6E5B271C60931FFFB0860389F81F77B9DDC`. Release build was `0 warnings / 0 errors`, format passed, and all six locks stayed unchanged.

## Full-diff review passes 1 and 2

Semantic and budget/evidence reviews each closed `0 Blocking / 0 Important / 0 Minor`.
Scope/traceability review reported `0 Blocking / 1 Important / 0 Minor`: the boundary
line prematurely associated this uncommitted local packet with draft PR #174. The line now
separates the local branch state from PR #174 as the pending publication target. Fresh
full-diff review pass 2 then closed `0 Blocking / 0 Important / 0 Minor` after this
disposition.

## Infrastructure observation and held scope

[TEST-0074](../../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074) first exposed the fixture-data `TEST-0210` literal; it is now neutral `TEST-0001` with no Scenario trait. The corrected local StructureOnly route was inconclusive at the controlled 300-second active timeout with no orphan, and the earlier full suite was inconclusive at 600 seconds, below the official 20/35-minute budgets. Neither observation is red or green evidence. Full-diff review pass 2 is closed; no staged, pushed, or hosted evidence is claimed for this packet.

`A-PARSER-INDEX-01` is the next Candidate and remains inactive. No parser/index/projector/admission positive, capability producer, Policy/public API, project/package/lock/workflow change, later A/B/C/D, Scenario/status/owner/TEST-0146, consumer mutation, release/publication/authority transfer, or PowerShell retirement is authorized.
