# Project Snapshot

Last verified: **2026-08-02**

## Verified facts

- Current ContractSlice A continuation: strict-redraw base
  [`25e26f908e1f123640c758e42e1db92d5eea6dde`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde),
  git tree identity `9a0dc5bb9b41c9509366ab92bc7de642724938b6`, passed
  [run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833).
  Exact implementation predecessor
  [`fca0778663238b83bb2ede7cba5ab52012414689`](https://github.com/hasanmanzak/meAndAI/commit/fca0778663238b83bb2ede7cba5ab52012414689),
  git tree identity `05c7591565d965966285cd51226446b2f54c81bc`, passed Ubuntu and Windows in
  [run 30722890590](https://github.com/hasanmanzak/meAndAI/actions/runs/30722890590);
  publication verification was correctly skipped and the
  [draft PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) suite reports
  GitGuardian green.
  [FIND-0445](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0445)
  and [FIND-0446](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0446)
  are resolved. `A-INDEX-SLOT-01` remains `ReviewedLocalGreen`; its canonical R,
  focused greens, cumulative A `19/19`, `642/690` size, locks/build/format/diff,
  and three final `0/0/0` reviews remain immutable. Strict D/RT retired
  never-activated `A-PARSER-INDEX-01` as a non-live, non-reactivatable
  `RetiredBeforeActivation` tombstone and partitioned it into three ordered
  packets. `A-PARSER-RECORD-SLOT-01` is exact-head `ReviewedLocalGreen`:
  canonical R is immutable, final focused green is `1/1`, cumulative A is
  `20/20`, exact packet size is `666/690`, reviews closed `0/0/0`, and exact-head
  hosted checks are green. Renewed Writer-first D/RT closed `0/0/0` in three
  independent current-tree reviews and StructureOnly is green.
  [FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447)
  is resolved by exact correction head
  [`3fa66695eb978954b321545e2d226c1effa6ead4`](https://github.com/hasanmanzak/meAndAI/commit/3fa66695eb978954b321545e2d226c1effa6ead4),
  git tree identity: `5ed8c3eef36cfab99490c514b0a23ca99b681ad0`, and green
  [run 30746985780](https://github.com/hasanmanzak/meAndAI/actions/runs/30746985780).
  [FIND-0448](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0448)
  is resolved by exact
  [`561a760401cf7312a15cadea3e6bf9f56b488d5d`](https://github.com/hasanmanzak/meAndAI/commit/561a760401cf7312a15cadea3e6bf9f56b488d5d),
  git tree identity: `8f120c396bd531e7b33d9c00a1265e0a7be6d1ba`, and successful
  [run 30748757145](https://github.com/hasanmanzak/meAndAI/actions/runs/30748757145).
  `A-GOVERNED-REFERENCE-SLOTS-01` is `ReviewedLocalGreen`. Exact remote-equal
  [`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602),
  git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`,
  passed Ubuntu and Windows in
  [run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121).
  Its exact R/G evidence plus focused `1/1`, cumulative A `21/21`, validation,
  and reviews are retained in the
  [governed-reference-slots handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-governed-reference-slots.md).
  The live denominator is `18 - 1 + 3 = 20`; eight packets are
  `ReviewedLocalGreen` (`40%`). `A-TARGET-PARSER-INDEX-SLOT-01` is a
  `FrozenDesign`, and every later packet remains Candidate/inactive.
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned`; no final scenario/status/owner/workflow activation is
  claimed, and [TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  plus B/C/D remain held. The umbrella directive still covers ordered remaining A through
  `A-CONVERGE-02` without bypassing predecessor, D/RT, evidence, or one-mutating-
  packet gates. Follow the current
  [target parser/index/slot freeze handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-target-parser-index-slot-freeze.md);
  the [parser-record-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-parser-record-slot.md)
  and [index-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-index-slot.md)
  are historical.
- Repository: [hasanmanzak/meAndAI](https://github.com/hasanmanzak/meAndAI)
- Visibility: public temporarily for hosted-CI continuity; the maintainer
  intends to return the repository to private after outstanding hosted and
  adoption-recovery work complete.
- Default branch: `main`
- Current protocol version: `0.16.0`. The latest immutable release is
  [v0.16.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.16.0) at
  [`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
  [PR #159](https://github.com/hasanmanzak/meAndAI/pull/159) and
  [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) retain its
  delivery and immutable publication evidence.
- Most recently completed and published implementation scope:
  [FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
  provides the typed C# operational foundation and portable verified package
  prerequisite. Its release grants no successor implementation authority.
- Historical ContractSlice A cumulative `13/13` content is committed at
  [`5fa7f7d`](https://github.com/hasanmanzak/meAndAI/commit/5fa7f7d02e64032e867d7c84d42662ba080b3c90)
  (`[skip ci]`), with BASE records synchronized by
  [`9107a49`](https://github.com/hasanmanzak/meAndAI/commit/9107a4936449048a057156e4714a99165ba1f24f).
  Exact pushed
  [`7f60e0c`](https://github.com/hasanmanzak/meAndAI/commit/7f60e0c66a49056b9e9854ccc353acfe67f65ed5)
  is a recovery input rather than an accepted green
  predecessor: it contained 18 static A facts and no valid build or per-packet
  red/RT/review evidence. Bounded
  [FIND-0441](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0441)
  recovery retains four facts; each
  exact focused filter passes `1/1` and cumulative A passes `17/17` locally.
  Final local V passes locked restore with unchanged relevant lock fingerprints,
  zero-warning/error Release build, format, diff/marker checks, and fresh
  full-diff review `0/0/0`; status is `ReviewedLocalGreen`. Audited
  git tree: `4ca02623e1f14233e847ebf64bc52d3cfe8869b8` is pushed at exact content
  checkpoint
  [`f64860ef456380232c23dfc4729a0d87f257483d`](https://github.com/hasanmanzak/meAndAI/commit/f64860ef456380232c23dfc4729a0d87f257483d)
  on draft
  [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174). Hosted
  [TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074)
  then exposed [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442):
  the still-`Planned` A-D scenario carried 17 premature final `Scenario` traits.
  The bounded correction retains every `ContractSlice=A` fact/FQN and defers
  the [Scenario trait for TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  to atomic final activation. Local review, push, and exact-head hosted
  [run 30659970794](https://github.com/hasanmanzak/meAndAI/actions/runs/30659970794)
  are green; remote-equal
  [`c88beefee54f3f0d0e0e623807eb8a4c9bf48032`](https://github.com/hasanmanzak/meAndAI/commit/c88beefee54f3f0d0e0e623807eb8a4c9bf48032)
  was the frozen predecessor used to activate `A-SCHEMA-SLOT-01`; it is
  historical now that the schema-slot packet has closed.
- `A-SCHEMA-SLOT-01` is packet-local `ReviewedLocalGreen` with exact FQN
  `ContractSliceASchemaSlotManifestTests.Enforces_exact_schema_and_zero_capability_evidence_slot_closure`
  and marker `TEST-0210-A-BEHAVIOR-RED-0003`. D/RT owns the exact
  reviewed red-source SHA-256
  `128C3CAF24BB029CBE3C85ABEB4434B54DC2D90B29EED436B8343990E91E57DB`,
  repository-tree schema, a producer-free zero-capability slot, schema/slot and
  component closure, and global equal SlotKey reuse. All three prior 0003
  attempts remain diagnostic. The first TRX at
  `D:\Temp\meandai-test-0210-a-cf51d3e38d6a41c1a45c30eb5edf6e94\TEST-0210-A-BEHAVIOR-RED-0003.trx`
  and the technically conforming rerun at
  `D:\Temp\meandai-test-0210-a-9a39c31356614537b6a6f0eac0083c56\TEST-0210-A-BEHAVIOR-RED-0003.trx`
  are exactly the diagnostic recurrence set for
  [FIND-0443](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443)
  and its append-only
  [evidence clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5150679793)
  respectively because the lower-level micro oracle contradicted the accepted
  locked-adapter marker-free assertion StackTrace and because the second run
  preceded complete repository-record synchronization. The third TRX at
  `D:\Temp\meandai-test-0210-a-c96f8fa926734506b50d17637e4e2dbe\TEST-0210-A-BEHAVIOR-RED-0003.trx`,
  SHA-256
  `F4190734BC91DB6879DCCC92633BBCB6DF4B9400A8CD4D47A7C6DF9030358C3A`,
  is separately a zero-discovery VSTest infrastructure abort and is neither
  [FIND-0443](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443)
  nor R. Canonical R is accepted at
  `D:\Temp\meandai-test-0210-a-96ff2a5352c141f78f8bebbfc0f957f0\TEST-0210-A-BEHAVIOR-RED-0003.trx`,
  SHA-256
  `4B7B8398362E23B9364BBB7C11C4A538BA984B3474A52F2D95567CB340545FDE`.
  The frozen red-source hash remained exact; the complete oracle passed in one
  process-scoped 300-second-child / exact-420-second-outer invocation, and the
  parent environment remained unset. No further red retry is authorized.
  Original-oracle green passed `1/1` at
  `D:\Temp\meandai-test-0210-a-green-d223831945254a88b29b723f0a07f3e3\TEST-0210-A-GREEN-0003.trx`,
  SHA-256
  `EF73BE838513986CA8FB9D41D1FC2B34D98CC3E31C650638B15158A7B115BB80`.
  Final topology-clean focused green passed `1/1` at
  `D:\Temp\meandai-test-0210-a-green-final-topology-64237a9f1c384c1fb5adef025948cfe0\TEST-0210-A-GREEN-FINAL-0003.trx`,
  SHA-256
  `A8552AF906E45AFB22A85BF0F3B61DDFD8AFA813036AA78292180C1BC32A2ACD`;
  cumulative A passed `18/18` at
  `D:\Temp\meandai-test-0210-a-cumulative-topology-retry-c93d714f03894591b62e498df55931c3\TEST-0210-A-GREEN-CUMULATIVE-0003.trx`,
  SHA-256
  `920BC60B161595E97D12544836D5B6E5B271C60931FFFB0860389F81F77B9DDC`.
  Final test source is 436 lines, SHA-256
  `FC43FDDA4B273BFCBED442FB145E28BA207EE433A08A9D3E43BEA88574154480`;
  production `256` plus test `436` is `692/700`, and estimated `+2` remains
  inside the hard cap. Release build passed with zero warnings/errors, format
  passed, and all six locks remained unchanged.
  [TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074)
  first exposed a fixture-data
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  literal; it is neutral
  [TEST-0001](../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001)
  now, with no Scenario trait. Corrected local StructureOnly was inconclusive
  at a controlled 300-second active timeout with no orphan; the earlier full
  suite was inconclusive at 600 seconds, below official 20/35-minute budgets.
  They are infrastructure observations, not red/green evidence. Fresh full-
  diff review pass 2, after the pass-1 traceability correction, closed
  `0 Blocking / 0 Important / 0 Minor`. [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned`; the index-slot handoff is historical and current routing
  is the parser-record-slot handoff above.
- The schema-slot packet was pushed at
  [`3b93c9e4...`](https://github.com/hasanmanzak/meAndAI/commit/3b93c9e4b93e19baa150b57d8a2c99c4038689d8)
  on draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174). Both stable
  jobs in hosted [run 30699069580](https://github.com/hasanmanzak/meAndAI/actions/runs/30699069580)
  failed only clickable-reference
  [TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175).
  [FIND-0444](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0444)
  is resolved by record-only corrections at remote-equal
  [`c73977d...`](https://github.com/hasanmanzak/meAndAI/commit/c73977d4af922aa66c464f6caced0d1aae473665)
  and exact-head hosted [run 30704338972](https://github.com/hasanmanzak/meAndAI/actions/runs/30704338972);
  the schema-slot C# evidence is unchanged.
- Previous C# operational-foundation checkpoint:
  [FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
  / [SUBF-0120](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0120)
  / [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) /
  [draft PR #159](https://github.com/hasanmanzak/meAndAI/pull/159) has completed
  the typed C# solution and application-authority first slice. The authorized
  second slice is adding only closed deterministic results, single-capability
  port contracts, a grant-checked infrastructure scope, and a redacting async
  dependency boundary. Its DoR, executable missing-contract red run, 16 of 16
  focused green tests, exact-tree validation, and exact-head hosted evidence
  complete five of five gates; combined
  [TEST-0191](../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191)
  and [TEST-0192](../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
  pass 31 of 31 with locked restore, zero-warning Release build, clean
  format/analyzer evidence, and a 203.3-second Windows PowerShell 5.1
  StructureOnly evidence. First hosted head
  [`c5fa78dc71a6106beac8461acd950efa44c55976`](https://github.com/hasanmanzak/meAndAI/commit/c5fa78dc71a6106beac8461acd950efa44c55976)
  passed Ubuntu and both-host C# tests but exposed
  [FIND-0362](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0362)
  in the retained Windows streaming oracle. Exact correction head
  [`4b10fc9314157e83cd36ae8d3b45162459bd547a`](https://github.com/hasanmanzak/meAndAI/commit/4b10fc9314157e83cd36ae8d3b45162459bd547a)
  removed the independent PID reopen, but [run `30309863827`](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827)
  proved that retaining OS liveness remained over-constrained and also exposed
  one short commit-link hygiene failure. Exact correction commit
  [`26b126858cd4a6612a8c19909bd4fd3958fb82f1`](https://github.com/hasanmanzak/meAndAI/commit/26b126858cd4a6612a8c19909bd4fd3958fb82f1)
  closes [FIND-0363](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0363),
  passes exact committed-tree StructureOnly in 206.6 seconds, and passes
  [run `30312104364`](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364)
  on [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779014)
  in 12 min 04 s and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779066)
  in 32 min 09 s. At that checkpoint the feature was two of three completed
  subfeatures, or 67%.
  [SUBF-0121](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0121)
  remained gated. PowerShell production authority was unchanged.
- Current C# foundation completion:
  [FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
  / [SUBF-0121](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0121)
  / [TEST-0193](../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0193)
  / [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) /
  [PR #159](https://github.com/hasanmanzak/meAndAI/pull/159) is complete in
  immutable [v0.16.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.16.0)
  at exact commit
  [`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
  The release retains the portable verified package and completed foundation
  evidence. No consumer, PowerShell route, or successor product authority was
  changed by that release.
- Content language: English
- Purpose: provide a shared development protocol that other projects can pin
  while retaining independent project memory.
- Recent historical work: immutable v0.13.4 completed [FEAT-0043](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/README.md), [SUBF-0082](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/README.md#subf-0082),
  [TEST-0167](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/test-cases.md#test-0167), [TEST-0168](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/test-cases.md#test-0168), [RISK-0201](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/README.md#risk-0201), and [RISK-0202](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/README.md#risk-0202). [FEAT-0044](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md) defines
  [SUBF-0083](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md#subf-0083), [SUBF-0084](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md#subf-0084), [TEST-0169](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/test-cases.md#test-0169), [TEST-0170](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/test-cases.md#test-0170), [RISK-0203](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md#risk-0203), [RISK-0204](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md#risk-0204), [RISK-0205](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md#risk-0205), and [RISK-0206](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md#risk-0206).
  The external failures are retained by Derdini runs 30011058590,
  30011059451, and 30011271796.
- Historical v0.9.0 delivery: [FEAT-0015](../../docs/features/FEAT-0015-stability-consistency-mandate/README.md)
  established the event-triggered stability and consistency mandate through
  [issue #47](https://github.com/hasanmanzak/meAndAI/issues/47) and
  [pull request #48](https://github.com/hasanmanzak/meAndAI/pull/48).
- Completed external follow-up: [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44) / [RISK-0076](../../docs/features/FEAT-0013-v084-correction/README.md#risk-0076) is closed by
  [finding issue #44](https://github.com/hasanmanzak/meAndAI/issues/44). Main
  requires the canonical Ubuntu and Windows validation checks, administrator
  enforcement, and resolved conversations; force pushes and deletion are
  disabled. [Issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) remains the historical [FEAT-0013](../../docs/features/FEAT-0013-v084-correction/README.md) delivery and publication authority.
- Historical v0.8.6 delivery: immutable release
  [`v0.8.6`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.6)
  targets commit [`a3d58a9cee00b9914c40adcd8e93dff53bed235a`](https://github.com/hasanmanzak/meAndAI/commit/a3d58a9cee00b9914c40adcd8e93dff53bed235a) and closed
  [FIND-0132](../../docs/features/FEAT-0014-v085-convergence/README.md#find-0132); [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) remains its external publication authority.
- Historical v0.8.5 delivery: immutable release
  [`v0.8.5`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.5)
  targets merge commit [`7c06dfad75ab7b327d46c7b8f8d7cb541bab3896`](https://github.com/hasanmanzak/meAndAI/commit/7c06dfad75ab7b327d46c7b8f8d7cb541bab3896).
  Its failed completion projection is retained as [FIND-0132](../../docs/features/FEAT-0014-v085-convergence/README.md#find-0132), not rewritten.
- Historical v0.8.4 delivery: completed
  [FEAT-0013](../../docs/features/FEAT-0013-v084-correction/README.md) retains
  [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) as its delivery
  and post-publication authority.
- Historical v0.8.1 delivery: [FEAT-0011](../../docs/features/FEAT-0011-stability-closure/README.md) was published as immutable release
  [`v0.8.1`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.1).
  The release and issue retain the exact pull request, target commit, checks,
  and post-publication verification. The [FEAT-0011](../../docs/features/FEAT-0011-stability-closure/README.md) pre-merge commit had already
  described that release as published; [FEAT-0012](../../docs/features/FEAT-0012-v082-correction/README.md)
  records this premature claim as [FIND-0108](../../docs/features/FEAT-0012-v082-correction/README.md#find-0108) rather than treating later valid
  publication as retroactive evidence.

## Collaboration constraints

- When authorization and tooling are available, carry approved repository and
  GitHub work through validation and publication instead of stopping at advice.
- An explicit request to wait for future instructions is a hard stop for edits,
  implementation, and detailed planning until the next concrete directive.
- Treat continuity requirements as part of scope and answer the stated
  project/tool question directly.
- Do not invent implementation and claim completion without repository evidence.
- Large work is decomposed and reviewed slice by slice.
- Repository content is written in English; conversation language follows the
  user.

## Engineering direction

The canonical rules are in the [common protocol](../../PROTOCOL.md). Defaults
are Domain-Driven Design, Rich Entity Model, and Test-Driven Development, with a
documented project decision required when another approach better fits the
domain. Avoid a large universal bootstrapper or semantic AI-memory validator.

## Active recurrence knowledge

### Record synchronization reintroduces noncanonical cross-record links

- Status: `Active`
- Observable signature: an exact pushed documentation/memory synchronization
  head makes hosted
  [TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  report a pull-request label targeting `/pull/<number>/checks` as a non-record
  target, or report a rendered stable identifier as not wholly covered by one
  canonical link.
- Applicability: current [SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  packet/cohort record synchronization and later repository Markdown changes
  that describe packet, pull-request, scenario, finding, commit, or hosted-run
  evidence.
- Affected contract and cause: record synchronization used a GitHub checks UI
  subroute as the identity of [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174)
  and left the exact readiness prose "Full
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  green is not claimed" outside a canonical link. This was plain readiness
  prose, not the earlier Scenario-trait defect. The prior bounded
  [FIND-0444](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0444)
  correction had no active pre-push recurrence route for the next record cohort.
- Canonical owner and evidence:
  [FIND-0445](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0445),
  [FEAT-0065](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md),
  existing
  [TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175),
  the historical
  [index-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-index-slot.md),
  the current
  [parser-record-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-parser-record-slot.md),
  failed head
  [`bfa961d...`](https://github.com/hasanmanzak/meAndAI/commit/bfa961d1f661588dc48f337720cae2ef741887a7),
  and [run 30712296217](https://github.com/hasanmanzak/meAndAI/actions/runs/30712296217).
  [DEC-0029](../../docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  owns this recurrence-entry schema.
- Fixed release or evidence: no release. The bounded twelve-record correction
  is resolved at exact remote-equal
  [`25e26f908e1f123640c758e42e1db92d5eea6dde`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde),
  git tree identity: `9a0dc5bb9b41c9509366ab92bc7de642724938b6`,
  with both stable jobs green in
  [run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833).
  The correction and later packet-denominator redraw remain separate commit
  boundaries.
- Required safe response: preserve the packet-local C#/test/lock evidence;
  inventory only the authorized record cohort; target every pull-request label
  at canonical [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174);
  wholly link every rendered stable identifier to its canonical record; run the
  existing [TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  barrier and fresh record review; then commit, push, and require remote-equal
  exact-head hosted green before activating a successor.
- Unsafe retry boundary: do not treat `/checks` as a pull-request identity, do
  not partially link or code-format a governed stable identifier, do not use an
  unchanged rerun of [`bfa961d...`](https://github.com/hasanmanzak/meAndAI/commit/bfa961d1f661588dc48f337720cae2ef741887a7)
  as correction evidence, do not create a derivative test/validator, and do not
  combine the separate packet-denominator redraw with this hosted correction.
- Freshness and review condition: confirmed 2026-08-01; review after the
  [TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  parsing/exact-target contract or the A-cohort record-synchronization process
  changes.
- Superseded by: `None`

### Planned multi-slice scenario is asserted before final activation

- Status: `Active`
- Observable signature: [TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074)
  reports `planned scenario is already asserted` while only a partial
  ContractSlice is implemented and the canonical scenario remains `Planned`.
- Applicability: a canonical scenario decomposed into partial .NET traits whose
  scenario-status, scenario-owner, workflow filters, and full executable route activate later.
- Affected contract and cause: partial [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  A facts received the final
  [Scenario trait for TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  even though A-D and the
  combined route were incomplete.
- Canonical owner and evidence: [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442),
  the [typed design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md),
  the historical [trait-correction handoff](log/2026-07-31-feat-0065-subf-0143-planned-scenario-trait-correction.md),
  the historical [schema-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-schema-slot.md),
  the historical [index-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-index-slot.md),
  the historical [parser-record-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-parser-record-slot.md),
  the hosted-green [governed-reference-slots handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-governed-reference-slots.md),
  and the current [target parser/index/slot freeze handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-target-parser-index-slot-freeze.md).
- Fixed release or evidence: no release. Partial facts retain exact FQN and
  `ContractSlice`; final `Scenario` traits are deferred to the same atomic
  scenario-status/scenario-owner/workflow-test-step target-and-filter/[TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  activation after all A-D focused and combined green.
  [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442)
  correction is reviewed and pushed at exact
  [`c88beefee54f3f0d0e0e623807eb8a4c9bf48032`](https://github.com/hasanmanzak/meAndAI/commit/c88beefee54f3f0d0e0e623807eb8a4c9bf48032);
  hosted [run 30659970794](https://github.com/hasanmanzak/meAndAI/actions/runs/30659970794)
  is green. During `A-SCHEMA-SLOT-01`,
  [TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074)
  then exposed only a fixture-data
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  literal; the correction is neutral
  [TEST-0001](../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001)
  and retains no
  Scenario trait. The corrected 300-second StructureOnly and earlier 600-second
  full-suite attempts expired below the official 20/35-minute budgets with no
  orphan; both are infrastructure observations, not scenario red/green evidence.
- Required safe response: keep `PlannedDocumentation` strict, remove premature
  final scenario traits, preserve partial-slice filters, and rerun StructureOnly
  plus the unchanged cumulative ContractSlice filter; require exact-head hosted
  green before accepting the correction head as a predecessor.
- Unsafe retry boundary: do not mark a partial scenario `Passing`, weaken
  [TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074),
  add a scenario-ID-specific bypass, or activate scenario-owner/workflow scope early.
- Freshness and review condition: confirmed 2026-07-31; review when partial
  trait topology or final scenario activation changes.
- Superseded by: `None`

### Frozen delivery oracle contradicts locked adapter serialization

- Status: `Active`
- Observable signature: an otherwise exact BehaviorRed TRX includes the locked
  xUnit/VSTest adapter's marker-free assertion `StackTrace`, while a lower-level
  packet record prohibits every sibling `ErrorInfo` child.
- Applicability: expected-red evidence that uses direct `Assert.Fail` with the
  immutable xUnit package and standard TRX logger.
- Affected contract and cause: the active micro plan drifted from the accepted
  typed design and canonical 0001/0002 evidence by calling the standard same-
  result StackTrace an invalid sibling.
- Canonical owner and evidence:
  [FIND-0443](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443),
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210),
  the [typed design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md),
  the historical [schema-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-schema-slot.md),
  the historical [index-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-index-slot.md),
  the historical [parser-record-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-parser-record-slot.md),
  the hosted-green [governed-reference-slots handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-governed-reference-slots.md),
  and the current [target parser/index/slot freeze handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-target-parser-index-slot-freeze.md).
- Fixed release or evidence: no release. The
  [FIND-0443](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443)
  recurrence set is
  exactly the diagnostic `cf51...` and `9a39...` 0003 TRX observations: the
  first exposed the oracle contradiction; the second passed the technical
  shape but preceded complete repository-record sync. The separate `c96...`
  zero-discovery infrastructure abort is excluded and governed below. The
  corrected oracle now has accepted canonical R at the exact `96ff...` TRX and
  SHA-256 recorded in the verified facts above.
- Required safe response: preserve the corrected lower-level wording and
  accepted R; permit zero or one nonempty marker-free standard
  `ErrorInfo/StackTrace` and validate it when present. Stop before green if any
  record/source or locked-adapter contract diverges; do not rerun accepted R.
- Unsafe retry boundary: do not suppress/wrap the assertion stack, relabel it as
  infrastructure failure, retroactively promote the exposing run, or allocate a
  new marker ordinal.
- Freshness and review condition: confirmed 2026-08-01; review when the locked
  adapter, logger, or BehaviorRed evidence contract changes.
- Superseded by: `None`

### VSTest testhost connection aborts before discovery

- Status: `Active`
- Observable signature: VSTest aborts its testhost connection at the default
  90 seconds before discovery; the TRX has no `UnitTestResult`, all 16 counters
  are zero, and one infrastructure Error RunInfo.
- Applicability: the current single-test ContractSlice A expected-red
  invocation when `VSTEST_CONNECTION_TIMEOUT` is unset.
- Affected contract and cause: the host connection window expired before the
  test ran, so the invocation is infrastructure evidence rather than R.
- Canonical owner and evidence: the historical
  [schema-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-schema-slot.md)
  and exact TRX
  `D:\Temp\meandai-test-0210-a-c96f8fa926734506b50d17637e4e2dbe\TEST-0210-A-BEHAVIOR-RED-0003.trx`,
  SHA-256
  `F4190734BC91DB6879DCCC92633BBCB6DF4B9400A8CD4D47A7C6DF9030358C3A`.
- Fixed release or evidence: no release. Accepted canonical R is
  `D:\Temp\meandai-test-0210-a-96ff2a5352c141f78f8bebbfc0f957f0\TEST-0210-A-BEHAVIOR-RED-0003.trx`,
  SHA-256
  `4B7B8398362E23B9364BBB7C11C4A538BA984B3474A52F2D95567CB340545FDE`.
  One child-process `VSTEST_CONNECTION_TIMEOUT=300` / exact 420-second outer
  invocation passed every oracle; its parent environment remained unset, and
  reviewed red-source SHA-256 remained
  `128C3CAF24BB029CBE3C85ABEB4434B54DC2D90B29EED436B8343990E91E57DB`.
- Required safe response: retain the diagnostic `c96...` evidence and accepted
  `96ff...` R separately. Bounded green is now complete; do not reclassify the
  later controlled protocol-suite timeouts as red or green evidence.
- Unsafe retry boundary: do not pre-discover, loop, reuse evidence, persist or
  raise either timeout, or auto-retry any further failure.
- Freshness and review condition: confirmed 2026-08-01; review when the locked
  VSTest/TestHost route or host execution environment changes.
- Superseded by: `None`

### Small-context packet advancement outruns the canonical ledger

- Status: `Active`
- Observable signature: an agent reports completion or pushes a successor tree
  while the micro ledger still shows candidate/no-later-A state, recorded counts
  lag the static test inventory, or the exact pushed head does not build.
- Applicability: [SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  micro-delivery work and later small-context agents
  operating under a frozen packet brief.
- Affected contract and cause: multiple semantic packets were combined without
  retained D/RT/R/V evidence; exact pushed
  [`7f60e0c`](https://github.com/hasanmanzak/meAndAI/commit/7f60e0c66a49056b9e9854ccc353acfe67f65ed5)
  contained 18 A facts while
  canonical records still reported `13/13` and the tree did not build.
- Canonical owner and evidence: [FIND-0441](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0441),
  [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442),
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210),
  the [micro plan](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-micro-delivery-plan.md),
  the historical [planned-scenario-trait correction handoff](log/2026-07-31-feat-0065-subf-0143-planned-scenario-trait-correction.md),
  the historical [schema-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-schema-slot.md),
  the historical [index-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-index-slot.md),
  the historical [parser-record-slot handoff](log/2026-08-01-feat-0065-subf-0143-contractslice-a-parser-record-slot.md),
  the hosted-green [governed-reference-slots handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-governed-reference-slots.md),
  and the current [target parser/index/slot freeze handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-target-parser-index-slot-freeze.md).
- Fixed release or evidence: no release. Four retained exact filters pass `1/1`
  and cumulative A passes `17/17` locally; final local V and fresh full-diff
  review `0/0/0` establish `ReviewedLocalGreen`. Audited tree `4ca02623...` is
  pushed at content checkpoint
  [`f64860ef...`](https://github.com/hasanmanzak/meAndAI/commit/f64860ef456380232c23dfc4729a0d87f257483d)
  on draft
  [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174); the later
  remote-equal [`c88beef...`](https://github.com/hasanmanzak/meAndAI/commit/c88beefee54f3f0d0e0e623807eb8a4c9bf48032)
  [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442)
  correction head passed local review, push, and exact-head hosted green in
  [run 30659970794](https://github.com/hasanmanzak/meAndAI/actions/runs/30659970794),
  so it was the `A-SCHEMA-SLOT-01` activation predecessor. That packet is now packet-local
  `ReviewedLocalGreen` with focused `1/1`, cumulative A `18/18`, build/format/
  lock evidence. Fresh full-diff review pass 2, after the pass-1 traceability
  correction, closed `0 Blocking / 0 Important / 0 Minor`.
- Required safe response: the historical pushed head was recovery input and
  required exact diff/test/review/record reconciliation before any successor
  activation. That recovery is complete at exact remote-equal
  [`c73977d...`](https://github.com/hasanmanzak/meAndAI/commit/c73977d4af922aa66c464f6caced0d1aae473665)
  with hosted [run 30704338972](https://github.com/hasanmanzak/meAndAI/actions/runs/30704338972)
  green. The oversized next vertical was redrawn without semantic expansion;
  `A-INDEX-SLOT-01` is now `ReviewedLocalGreen`. A later strict D/RT retired
  residual `A-PARSER-INDEX-01` before activation and replaced it with three
  ordered live packets; `A-PARSER-RECORD-SLOT-01` and
  `A-GOVERNED-REFERENCE-SLOTS-01` are `ReviewedLocalGreen`. The governed packet
  is exact remote-equal hosted green at
  [`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602),
  git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`,
  and [run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121);
  its exact R/G evidence is retained in the governed-reference handoff.
  [FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447)
  is resolved at exact [`3fa66695eb978954b321545e2d226c1effa6ead4`](https://github.com/hasanmanzak/meAndAI/commit/3fa66695eb978954b321545e2d226c1effa6ead4) /
  [run 30746985780](https://github.com/hasanmanzak/meAndAI/actions/runs/30746985780).
  [FIND-0448](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0448)
  is resolved at exact [`561a760401cf7312a15cadea3e6bf9f56b488d5d`](https://github.com/hasanmanzak/meAndAI/commit/561a760401cf7312a15cadea3e6bf9f56b488d5d) /
  [run 30748757145](https://github.com/hasanmanzak/meAndAI/actions/runs/30748757145).
  `A-TARGET-PARSER-INDEX-SLOT-01` is a `FrozenDesign`; later packets
  remain Candidate/inactive.
- Unsafe retry boundary: do not trust completion wording or commit messages,
  reconstruct missing red/review evidence, allocate retrospective markers, or
  call a broken or unreviewed pushed head the next predecessor.
- Freshness and review condition: refreshed 2026-08-02 for the exact recovery,
  strict redraw, exact parser-record hosted-green head, governed-reference
  freeze, and umbrella authority; review when the micro state machine, packet
  brief, or checkpoint authority changes.
- Superseded by: `None`

### Completed historical adoption issue is misclassified as malformed

- Status: `Active`
- Observable signature: a later clean quick adoption reports a valid closed,
  completed historical adoption issue as `A project-owned adoption issue
  contains a malformed ownership marker; manual review is required.`
- Applicability: current-launcher adoption when an exact supported legacy
  profile-A issue from `v0.8.0` through `v0.10.4` remains alongside its merged
  schema-3 terminal pull request and absent reserved branch.
- Affected contract and cause: current ownership classification recognized only
  the opaque current marker or current-target legacy marker, so complete older
  immutable lifecycle evidence fell through to the malformed reserved-prefix
  path.
- Canonical owner and evidence: [FEAT-0058](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md) /
  [SUBF-0118](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md#subf-0118) /
  [BUG-0045](https://github.com/hasanmanzak/meAndAI/issues/149) /
  [TEST-0069](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0069)
  owns the project-neutral executable barrier.
- Fixed release or evidence: target release `0.15.6`; the focused
  `IntegrityManifestIssue` owner passes on PowerShell 7 / Windows PowerShell
  5.1 in 141.9 / 147.7 seconds, with bounded provider proof, fail-closed
  provider collection shapes, frozen-evidence drift rejection, zero-mutation
  negatives, and idempotent positive rerun.
  Exact candidate commit
  [`7856697dc8733449bf907dfb47af77486dd8dee6`](https://github.com/hasanmanzak/meAndAI/commit/7856697dc8733449bf907dfb47af77486dd8dee6)
  passes the canonical full local suite in 1732.8 seconds.
- Required safe response: classify strict local grammar before provider reads,
  prove the exact immutable release, issue, merged pull request, terminal
  marker, actor, absent open pull request, and absent reserved branch within
  the declared ceilings, require exact JSON collection roots and complete
  non-null rows for provider absence evidence, freeze the metadata fingerprint
  before mutation, and leave the historical issue unchanged while reconciling
  only current state.
- Unsafe retry boundary: do not edit or delete the historical issue, suppress
  malformed-marker rejection, retry provider proof, patch a named consumer, or
  proceed after any ambiguous, unsupported, live, drifting, or failed proof.
- Freshness and review condition: last confirmed 2026-07-27; review whenever
  adoption issue marker families, terminal pull-request evidence, issue
  inventory bounds, or mutation ordering changes.
- Superseded by: `None`

### Hosted streaming fixture stops after the first JSONL event

- Status: `Active`
- Observable signature: a hosted Windows PowerShell 5.1 full profile renders
  `Codex | Session started`, then canonical
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  reports that JSONL stdout was not acknowledged while every later expected
  activity line is absent.
- Applicability: hosted or local execution of the pre-correction streaming
  fixture whose child waits for a parent-created acknowledgment file before
  emitting the remaining JSONL events.
- Affected contract and cause: the bidirectional filesystem handshake coupled
  incremental stdout evidence to the child's observation of a test-only file.
  A failed run proves that the child did not observe the acknowledgment within
  five seconds, but does not prove whether the parent wrote it or whether
  production consumption was buffered.
- Canonical owner and evidence: [FEAT-0020](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/README.md) /
  [BUG-0008](https://github.com/hasanmanzak/meAndAI/issues/57) /
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  owns the streaming contract; [FIND-0360](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md#find-0360)
  records the v0.15.6 delivery recurrence.
  [DEC-0029](../../docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  owns the recurrence-entry schema and
  [DEC-0030](../../docs/decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md)
  retains the existing canonical test identity for this infrastructure-only
  correction.
- Fixed release or evidence: target release `0.15.6`; exact correction commit
  [`120b04f6d724a1c01971d59332f3c54b2ada789c`](https://github.com/hasanmanzak/meAndAI/commit/120b04f6d724a1c01971d59332f3c54b2ada789c)
  removes the acknowledgment file and first replaced it with PID plus process-
  start ticks. [FIND-0361](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md#find-0361)
  records the separate portability correction completed by
  [`345647fbd2affaba787b3b1db3a8c295a9eae49d`](https://github.com/hasanmanzak/meAndAI/commit/345647fbd2affaba787b3b1db3a8c295a9eae49d).
- Required safe response: remove the bidirectional handshake, use one parent-
  generated run identity plus bounded live PID, run the canonical focused owner
  on both supported runtimes, then require structure, committed-HEAD graph, and
  a new-head hosted Ubuntu/Windows pass.
- Unsafe retry boundary: do not accept an unchanged old-head rerun as the
  correction, weaken production streaming, infer parent-write absence from the
  combined failure, or create a duplicate scenario ID.
- Freshness and review condition: last confirmed 2026-07-27; review whenever
  the bounded-process stdout reader, mock event process, or hosted Windows
  runtime changes.
- Superseded by: `None`

### Cross-platform fixture identity needs portable run correlation

- Status: `Active`
- Observable signature: an exact hosted head reports only the aggregate
  canonical
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  live-consumption failure, with no separate required-event or safe-
  presentation failure. The hosted log does not expose which aggregate operand
  failed.
- Applicability: the first file-free streaming fixture, which serialized its
  own process-start ticks and required an independently opened process object
  to reproduce that exact value while the first event was handled.
- Affected contract and cause: code-path diagnosis identifies exact process-
  start timestamp equality as the remaining platform-sensitive correlation
  discriminator. Independently opening process objects and requiring exact
  timestamp equality is not an appropriate portable oracle, so PID/start-time
  equality must not be the sole run-correlation boundary.
- Canonical owner and evidence: [FEAT-0020](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/README.md) /
  [BUG-0008](https://github.com/hasanmanzak/meAndAI/issues/57) /
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  owns the streaming contract; [FIND-0361](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md#find-0361)
  records the v0.15.6 delivery recurrence.
  [DEC-0029](../../docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  owns the recurrence-entry schema and
  [DEC-0030](../../docs/decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md)
  retains the existing canonical test identity for this infrastructure-only
  correction.
- Fixed release or evidence: target release `0.15.6`; exact evidence head
  [`aa8c9f479fe902972fcd4b103e0e2353dc6ba5e0`](https://github.com/hasanmanzak/meAndAI/commit/aa8c9f479fe902972fcd4b103e0e2353dc6ba5e0)
  reproduced the false negative on Ubuntu
  [run `30278228996`](https://github.com/hasanmanzak/meAndAI/actions/runs/30278228996).
  Exact correction commit
  [`345647fbd2affaba787b3b1db3a8c295a9eae49d`](https://github.com/hasanmanzak/meAndAI/commit/345647fbd2affaba787b3b1db3a8c295a9eae49d)
  uses one parent-generated lowercase 32-hex run identity plus bounded live PID;
  the focused owner passes on PowerShell 7 / Windows PowerShell 5.1 in 10.1 /
  12.8 seconds, and an independent review run repeats the pass in 9.5 / 11.8
  seconds with the same canonical scenario manifest. Final protected hosted
  confirmation remains required.
- Required safe response: preserve exit zero, all expected events, safe
  presentation, final-result authority, and cancellation assertions; replace
  exact timestamp equality with a parent-generated run identity plus bounded
  live PID, then validate a new exact head on both hosted platforms.
- Unsafe retry boundary: do not add timestamp tolerance or retry loops, accept
  an unchanged old-head rerun, weaken production streaming, or create a new
  scenario ID for the same retained infrastructure contract.
- Freshness and review condition: last confirmed 2026-07-27; review whenever
  process identity, mock event startup, or hosted runtime behavior changes.
- Superseded by: `None`

### Independent PID reopen can falsify streaming liveness

- Status: `Superseded`
- Observable signature: an exact hosted Windows PowerShell 5.1 head passes
  every required JSONL event and separate presentation assertion, but canonical
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  reports only `JSONL stdout was not consumed while the fixture process
  remained active.`
- Applicability: the file-free streaming fixture after the run-identity
  correction when its output callback independently reopens the child by PID
  to infer liveness.
- Affected contract and cause: the callback has exact parent-generated stream
  identity but derives process state from a separately opened process wrapper.
  A false liveness observation can therefore reject an otherwise complete
  incremental stream without identifying a missing event, unsafe presentation,
  nonzero exit, or production-source regression.
- Canonical owner and evidence:
  [FIND-0362](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0362)
  / [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  / [run `30307649690`](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690)
  own the current recurrence. [DEC-0030](../../docs/decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md)
  retains the existing scenario identity.
- Fixed release or evidence: exact correction commit
  [`4b10fc9314157e83cd36ae8d3b45162459bd547a`](https://github.com/hasanmanzak/meAndAI/commit/4b10fc9314157e83cd36ae8d3b45162459bd547a)
  removed the independent PID reopen and passed the canonical owner on
  PowerShell 7 / Windows PowerShell 5.1 in 9.7 / 11.7 seconds. Exact-head
  [run `30309863827`](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827)
  then failed only the same Windows aggregate oracle, proving that OS process
  liveness itself remained an unsuitable consumption boundary.
  [FIND-0363](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0363)
  owns the successor correction.
- Required safe response: retain the exact stream identity and all event,
  redaction, exit, final-result, and cancellation assertions, then follow
  [FIND-0363](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0363)
  instead of reopening a PID or inferring consumption from OS process liveness.
- Unsafe retry boundary: do not rerun the unchanged head as correction, reopen
  the PID again, add timing tolerance or retries, weaken required events, or
  create a duplicate scenario.
- Freshness and review condition: last confirmed 2026-07-28; review whenever
  the bounded-process line callback, process observation, or hosted runtime
  changes.
- Superseded by: [FIND-0363](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0363)

### OS process liveness is not a streaming-consumption boundary

- Status: `Active`
- Observable signature: an exact hosted Windows PowerShell 5.1 head renders
  every required JSONL event and passes every separate presentation assertion,
  but canonical
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  still reports only that stdout was not consumed while the fixture remained
  active.
- Applicability: the streaming fixture and bounded-process callback when the
  behavioral oracle correlates a parent-generated stream identity with PID or
  OS process-liveness state instead of the reader's own control-flow stage.
- Affected contract and cause: OS process identity and `HasExited` are not the
  streaming-consumption contract. The production reader already distinguishes
  the asynchronous active read loop from its post-exit drain; retaining an OS
  liveness predicate can reject complete incremental output without identifying
  a missing event, unsafe presentation, nonzero exit, or source regression.
- Canonical owner and evidence:
  [FIND-0363](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0363)
  / [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  / [run `30309863827`](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827)
  own the current recurrence. [DEC-0030](../../docs/decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md)
  retains the existing scenario identity.
- Fixed release or evidence: the first exact evidence head passed 31 of 31 C#
  tests on both hosts but retained the aggregate Windows oracle failure, while
  Ubuntu failed later on one non-navigable short commit reference. The reviewed
  working-tree
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  contract first failed
  alone on PowerShell 7 / Windows PowerShell 5.1 in 9.7 / 11.5 seconds when the
  consumption stage was absent, then
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
  and [TEST-0106](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
  passed in 10.0 / 12.4 seconds after adding distinct active-read and post-exit-
  drain stages. Exact correction commit
  [`26b126858cd4a6612a8c19909bd4fd3958fb82f1`](https://github.com/hasanmanzak/meAndAI/commit/26b126858cd4a6612a8c19909bd4fd3958fb82f1)
  passes candidate/exact-tree Windows PowerShell 5.1 StructureOnly in 208.5 /
  206.6 seconds. Exact-head [run `30312104364`](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364)
  passes Ubuntu and Windows; Windows emits the exact
  [TEST-0105](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)/[TEST-0106](../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
  manifest, and Ubuntu passes the
  [TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
  commit-link verifier.
- Required safe response: require the exact parent-generated stream identity
  and `ConsumptionStage=ActiveReadLoop` for the first fixture event; label only
  the post-exit drain as `PostExitDrain`; retain exit, event, redaction, final-
  result, and cancellation assertions; validate both supported local runtimes
  and a new exact hosted head.
- Unsafe retry boundary: do not infer streaming from PID, `HasExited`, process-
  start timestamps, timing tolerances, or retries; do not rerun an unchanged
  failed head, weaken required events, or create a duplicate scenario.
- Freshness and review condition: last confirmed 2026-07-28; review whenever
  the bounded-process read-loop boundary, callback observation, fixture startup,
  or hosted runtime changes.
- Superseded by: `None`

### Restricted-sandbox Git signal-pipe failure

- Status: `Active`
- Observable signature: Git for Windows cannot create local clone signal pipes (`Win32 error 5`).
- Applicability: Git-heavy local validation or fixture setup running inside a restricted Windows workspace sandbox.
- Affected contract and cause: the sandbox denies the Git helper's required local signal-pipe operation; the repository content and test assertion are not the failing contract.
- Canonical owner and evidence: [SUBF-0095](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0095) / [issue #128](https://github.com/hasanmanzak/meAndAI/issues/128) owns the project-local routing entry; the [recorded current evidence](log/2026-07-19-v0122-ci-evidence-hygiene.md#current-evidence) proves the host condition. [DEC-0029](../../docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md) defines the entry schema, not the host restriction.
- Fixed release or evidence: no protocol release owns the host restriction; use the linked environment evidence.
- Required safe response: if the command is still required and authority exists, run it once outside the restricted workspace sandbox; otherwise stop as `Blocked`.
- Unsafe retry boundary: Do not repeat the unchanged sandboxed Git command after this signature; a retry requires a materially different authorized execution boundary.
- Freshness and review condition: last confirmed 2026-07-19; review after a Codex sandbox or Git for Windows execution-model change, or when the restricted route succeeds with equivalent coverage.
- Superseded by: `None`

### GitHub CLI multiline issue-body argument splitting

- Status: `Active`
- Observable signature: `gh issue edit --body $body` reports an option or
  shorthand-flag error whose apparent argument is a line from the multiline
  Markdown body.
- Applicability: Windows PowerShell GitHub issue or pull-request updates that
  pass a multiline body value directly to a native `gh` argument.
- Affected contract and cause: the multiline body is not preserved as one
  native argument on this route, so body lines are interpreted as additional
  CLI arguments; the GitHub issue content is not the failing contract.
- Canonical owner and evidence: [SUBF-0096](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096)
  / [issue #125](https://github.com/hasanmanzak/meAndAI/issues/125) records the
  failed route and the successful transport replacement.
- Fixed release or evidence: project-local tooling-route evidence confirmed on
  2026-07-25; immutable
  [v0.15.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.0)
  publishes the durable routing record.
- Required safe response: pipe the body to
  `gh issue edit --body-file -`; verify the resulting work-surface content.
- Unsafe retry boundary: do not repeat the direct multiline `--body $body`
  route after this signature. Retry only with stdin/`--body-file -` or another
  materially different body transport.
- Freshness and review condition: last confirmed 2026-07-25; review after a
  GitHub CLI or Windows PowerShell native-argument transport change, or when the
  direct route succeeds with an exact multiline-body regression.
- Superseded by: `None`

### Windows native stdin framing and structured workflow dispatch

- Status: `Active`
- Observable signature: a repository-owned Windows native process receives a
  BOM-prefixed or non-UTF-8 stdin document, or a workflow receives quote-
  stripped `source_graph_identity` text and rejects it as invalid JSON.
- Applicability: PowerShell 5.1/7 native-process calls that carry structured
  repository input through stdin or `gh workflow run`, including instruction-
  graph identities and other JSON workflow input maps.
- Affected contract and cause: ambient `$OutputEncoding` or
  `[Console]::InputEncoding` can add a preamble or use a legacy code page,
  while native `--field`/`--raw-field` argument parsing is not a lossless
  structured-JSON transport. The source JSON and downstream validator are not
  the failing contracts. A local environment with a BOM-free console input
  encoding can mask the second dependency until a hosted Windows runner sets a
  preamble-bearing value.
- Canonical owner and evidence: the
  [v0.13.1 stdin correction](log/2026-07-23-v0131-hosted-windows-stdin-encoding-correction.md)
  owns batch-reader framing; [SUBF-0106](../../docs/features/FEAT-0055-v0154-utf8-workflow-dispatch/README.md#subf-0106)
  / [TEST-0153](../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  / [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) owns lifecycle
  workflow input transport.
- Fixed release or evidence: immutable `v0.13.1` carries the batch framing
  correction; target `v0.15.4` carries the shared quick-adoption stdin encoder
  and workflow JSON dispatch correction.
- Required safe response: bind both `$OutputEncoding` and
  `[Console]::InputEncoding` to UTF-8 without a BOM for the bounded stdin call,
  restore both caller values in `finally`, and send workflow input maps as one
  outer JSON object through `gh workflow run --json`. Keep nested JSON as the
  workflow's declared string value. Regression evidence must first install a
  preamble-bearing ambient console input encoding so local defaults cannot
  mask the failure.
- Unsafe retry boundary: do not retry the same structured value through native
  `--field`, `--raw-field`, or an ambient stdin encoding. Retry only after
  moving to the canonical UTF-8/no-BOM stdin route and validating exact bytes.
- Freshness and review condition: last confirmed 2026-07-26; review after a
  Windows PowerShell, GitHub CLI, or workflow-dispatch input-model change, or
  when an equivalent direct-argument route passes exact Unicode/byte evidence.
- Superseded by: `None`

### PowerShell interpolated variable followed by a colon

- Status: `Active`
- Observable signature: PowerShell reports `Variable reference is not valid`
  and points at a double-quoted fragment shaped like `$name:`.
- Applicability: PowerShell commands or source that interpolate a variable
  immediately before a colon, including generated path/line diagnostics.
- Affected contract and cause: the parser treats the colon as part of a scoped
  variable reference; the value being formatted is not the failing contract.
- Canonical owner and evidence: [SUBF-0096](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096)
  / [TEST-0184](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0184)
  owns the canonical helper/AST evidence that exposed and corrected this route.
- Fixed release or evidence: the changed-source AST parse passed on 2026-07-25;
  target release `0.15.0` carries the corrected `${name}:` form.
- Required safe response: use `${name}:` for interpolation or a format
  expression such as `'{0}:{1}' -f $name, $line`.
- Unsafe retry boundary: do not repeat the unchanged `$name:` form after this
  parser signature; retry only with explicit variable delimiting or formatting.
- Freshness and review condition: last confirmed 2026-07-25, including a
  delegated review recurrence; the applicable safe route must be copied into
  delegated task briefs. Review after a PowerShell parser-language change or
  equivalent syntax succeeds in every supported runtime.
- Superseded by: `None`

### Displayed full-file output used as rewrite authority

- Status: `Active`
- Observable signature: a rewritten large file contains a literal truncation
  marker, a missing middle range, or content that was visible only in a
  clipped tool response; a failed multi-file patch may also have changed only
  some earlier targets.
- Applicability: repository maintenance that reads a large file through
  bounded tool output and then reconstructs or patches one or more files.
- Affected contract and cause: display output is a lossy transport and patch
  failure is not an atomicity guarantee; neither is canonical file content.
- Canonical owner and evidence: [SUBF-0096](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096)
  / [FIND-0260](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0260)
  records the bounded restoration and per-target verification.
- Fixed release or evidence: the damaged ranges were restored from clean HEAD
  in bounded slices and changed-source AST parsing passed on 2026-07-25;
  target release `0.15.0` carries the durable route.
- Required safe response: use the filesystem file or bounded exact ranges as
  rewrite authority; after any patch error, inspect every intended target
  before retrying or continuing.
- Unsafe retry boundary: do not feed displayed full-file output back into a
  rewrite and do not assume a failed multi-file patch changed no files.
- Freshness and review condition: last confirmed 2026-07-25; review only when
  the tool transport proves complete byte-preserving output and patch
  atomicity through an executable regression.
- Superseded by: `None`

### PowerShell diagnostic parser and search expansion hazards

- Status: `Active`
- Observable signature: a diagnostic command fails because `$Error` was used
  as a loop variable, a double-quoted search pattern containing `$` expands
  into an empty or unexpectedly broad pattern, or `rg` receives a positional
  wildcard path such as `*.ps1` that PowerShell did not expand.
- Applicability: Windows PowerShell diagnostics, AST checks, and repository
  searches assembled interactively or inside maintenance scripts.
- Affected contract and cause: PowerShell automatic variables, string
  interpolation, and non-expansion of native-command wildcard arguments alter
  diagnostic control or search input before the intended tool receives it; the
  inspected repository content is not the failure.
- Canonical owner and evidence: [SUBF-0096](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096)
  / [FIND-0261](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0261)
  records the corrected routes.
- Fixed release or evidence: corrected diagnostic routes and changed-source
  parsing passed on 2026-07-25; target release `0.15.0` carries this record.
- Required safe response: use a non-reserved loop variable such as
  `$parseError`; pass literal search patterns with single quotes or explicitly
  escape `$` when interpolation is required; use `rg --glob '*.ps1'` for file
  filtering instead of a positional wildcard path.
- Unsafe retry boundary: do not repeat the unchanged automatic-variable,
  double-quoted literal-search, or positional-wildcard form after this
  signature.
- Freshness and review condition: last confirmed 2026-07-25; review after a
  supported PowerShell parsing or interpolation change, or an exact
  executable equivalence proof.
- Superseded by: `None`

### Native command output arrays combined through comma nesting

- Status: `Active`
- Observable signature: later path processing receives one nested or
  concatenated-looking value after multiple native command results were
  grouped with a comma.
- Applicability: PowerShell maintenance commands that combine path or result
  streams from two or more native invocations.
- Affected contract and cause: comma grouping preserves nested result shape
  instead of forming the intended flat array, so downstream joins or path
  validation observe false input.
- Canonical owner and evidence: [SUBF-0096](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096)
  / [FIND-0261](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0261)
  records the corrected composition.
- Fixed release or evidence: the flat-array route was confirmed on
  2026-07-25; target release `0.15.0` carries this record.
- Required safe response: materialize and concatenate explicit arrays, for
  example `@(command1) + @(command2)`, before downstream enumeration.
- Unsafe retry boundary: do not repeat comma-nested native-output grouping
  after this signature without a shape-equivalence regression.
- Freshness and review condition: last confirmed 2026-07-25; review after a
  supported PowerShell native-output shape change.
- Superseded by: `None`

### Bare fixture repository rejected through implicit working-tree routing

- Status: `Active`
- Observable signature: Git reports `fatal: cannot use bare repository` and
  names `safe.bareRepository=explicit` after a fixture command uses `git -C`.
- Applicability: test infrastructure or maintenance helpers that receive a
  bare repository path, including local remote fixtures.
- Affected contract and cause: `git -C` requests implicit bare-repository
  discovery, which the safe Git setting rejects; the repository data and test
  scenario are not the failing contracts.
- Canonical owner and evidence: [FIND-0280](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0280)
  / [TEST-0184](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0184)
  owns explicit and inferred bare-repository execution.
- Fixed release or evidence: the canonical utility, full bootstrap owner, and
  quick-adoption repository-route shard passed on 2026-07-25; target release
  `0.15.0` carries the correction.
- Required safe response: call the canonical test-repository command and let it
  detect the bare structure, or declare `-BareRepository`; use `--git-dir`, not
  `-C`, for a direct native Git call.
- Unsafe retry boundary: do not repeat unchanged `git -C <bare-path>` after
  this signature and do not copy the routing logic into individual fixtures.
- Freshness and review condition: last confirmed 2026-07-25; review after a Git
  safe-bare execution-model change or an equivalent supported-runtime proof.
- Superseded by: `None`

### Detached exported command loses its owning module lifetime

- Status: `Active`
- Observable signature: a captured exported command later reports that a
  `$script:` dependency cannot be retrieved because it has not been set.
- Applicability: PowerShell test suites that capture a module export as a
  ScriptBlock, remove the module, and invoke the detached command later or
  across a nested script lifecycle.
- Affected contract and cause: the exported function still depends on its
  owning module scope; detaching code text does not preserve that scope or its
  exact cleanup lifetime.
- Canonical owner and evidence: [FIND-0279](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0279)
  and [FIND-0281](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0281)
  own the lifetime rule and its bootstrap recurrence barrier.
- Fixed release or evidence: mixed quick-adoption sequencing and the full
  bootstrap owner passed on 2026-07-25; target release `0.15.0` carries the
  durable route.
- Required safe response: retain the exact ModuleInfo through the last use,
  invoke the module-qualified exported command, then remove only that ModuleInfo.
  Fail before any dependent fixture mutation when the prerequisite fails.
- Unsafe retry boundary: do not remove the owner and retry the same detached
  ScriptBlock, and do not continue a dependent mutation with an empty identity.
- Freshness and review condition: last confirmed 2026-07-25; review after a
  PowerShell module-scope semantic change or exact supported-runtime proof.
- Superseded by: `None`

### Dynamic PSCommandPath changes reusable fixture identity

- Status: `Active`
- Observable signature: one suite-process fixture key reports a canonical
  builder or input-digest conflict only after a nested or mixed script sequence.
- Applicability: PowerShell fixture caches that recompute owner identity inside
  a function from `$PSCommandPath`.
- Affected contract and cause: `$PSCommandPath` is an execution-context
  automatic variable, not a durable lexical owner identity across every nested
  script lifecycle; the fixture content is not necessarily drifting.
- Canonical owner and evidence: [FIND-0282](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0282)
  / [TEST-0116](../../docs/features/FEAT-0024-v0101-parallel-windows-validation/test-cases.md#test-0116)
  owns stable suite-process fixture identity.
- Fixed release or evidence: the exact owner path/digest is captured once and
  fixture closure requires it; target release `0.15.0` carries the correction.
- Required safe response: capture the lexical owner path and digest at suite
  startup, then reuse that immutable value for all cache requests.
- Unsafe retry boundary: do not recompute owner identity from dynamic
  `$PSCommandPath` after a nested script call and do not weaken drift rejection.
- Freshness and review condition: last confirmed 2026-07-25; review after a
  PowerShell automatic-variable semantic change or exact mixed-sequence proof.
- Superseded by: `None`

### Isolated production function omits a canonical sibling dependency

- Status: `Active`
- Observable signature: an isolated AST-extracted production function fails
  because a called canonical sibling function is not recognized.
- Applicability: test harnesses that execute one extracted FunctionDefinition
  outside its production module or composed source.
- Affected contract and cause: extracting one function does not carry its call
  graph; the isolated harness silently retains an obsolete inline assumption
  or omits the real sibling dependency.
- Canonical owner and evidence: [FIND-0277](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0277)
  and [FIND-0283](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0283)
  / [TEST-0126](../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0126)
  own explicit canonical dependency binding.
- Fixed release or evidence: the focused current-launcher recovery shard passed
  on 2026-07-25; target release `0.15.0` carries the durable route.
- Required safe response: inventory the extracted function's direct production
  calls, resolve each exact canonical owner from the same source AST or module,
  and inject those definitions before the function under test.
- Unsafe retry boundary: do not retry a single-function extraction after an
  unrecognized sibling error, and do not copy the sibling implementation into
  the harness.
- Freshness and review condition: last confirmed 2026-07-25; review whenever
  the extracted production call graph changes.
- Superseded by: `None`

### Human-facing commit reference lacks an exact commit permalink

- Status: `Active`
- Observable signature: [TEST-0065](../../docs/features/FEAT-0011-stability-closure/test-cases.md#test-0065)
  or its repository-wide [TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
  owner reports an `UnlinkedCommitReference` for a short SHA or for a
  commit-like hexadecimal object identity in Markdown.
- Applicability: tracked Markdown and GitHub-facing evidence that names commits,
  checkpoints, blobs, or other Git objects.
- Affected contract and cause: a human-facing commit identity is not navigable
  or a non-commit object is syntactically indistinguishable from a commit; the
  referenced implementation evidence is not itself invalid.
- Canonical owner and evidence: [FIND-0284](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0284)
  / [TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
  owns the exact reference contract. Historical
  [FIND-0446](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0446)
  remains resolved at exact head
  [`25e26f908e1f123640c758e42e1db92d5eea6dde`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde),
  git tree identity: `9a0dc5bb9b41c9509366ab92bc7de642724938b6`, and
  [run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833).
  The later delivery occurrence was
  [FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447):
  exact activation head
  [`cf8920e6a42b9118761c30599f8fcb9f87f5335f`](https://github.com/hasanmanzak/meAndAI/commit/cf8920e6a42b9118761c30599f8fcb9f87f5335f),
  git tree identity: `1c9fc67f666a7e972ed034cdcf5ba21cb98becf5`, and
  [run 30744358545](https://github.com/hasanmanzak/meAndAI/actions/runs/30744358545),
  with thirteen ambiguous Git tree labels. It is resolved by exact correction
  head [`3fa66695eb978954b321545e2d226c1effa6ead4`](https://github.com/hasanmanzak/meAndAI/commit/3fa66695eb978954b321545e2d226c1effa6ead4),
  git tree identity: `5ed8c3eef36cfab99490c514b0a23ca99b681ad0`, and green
  [run 30746985780](https://github.com/hasanmanzak/meAndAI/actions/runs/30746985780).
- Fixed release or evidence: repository-only Markdown verification is the
  focused barrier; release `0.15.0` carries the historical corrected evidence.
  The historical twenty-three-occurrence correction remains resolved. The later
  thirteen-occurrence correction remains resolved by exact
  [`3fa66695eb978954b321545e2d226c1effa6ead4`](https://github.com/hasanmanzak/meAndAI/commit/3fa66695eb978954b321545e2d226c1effa6ead4) /
  [run 30746985780](https://github.com/hasanmanzak/meAndAI/actions/runs/30746985780) under
  [FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447).
  The separate Writer-first activation hold is resolved by exact
  [`561a760401cf7312a15cadea3e6bf9f56b488d5d`](https://github.com/hasanmanzak/meAndAI/commit/561a760401cf7312a15cadea3e6bf9f56b488d5d),
  git tree identity: `8f120c396bd531e7b33d9c00a1265e0a7be6d1ba`, and successful
  [run 30748757145](https://github.com/hasanmanzak/meAndAI/actions/runs/30748757145),
  which resolves [FIND-0448](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0448).
  The recurrence remains `Active`; delivery evidence does not replace the canonical
  executable owner.
- Required safe response: resolve a commit to its exact full SHA and link the
  label to `https://github.com/<owner>/<repo>/commit/<full-sha>`; classify a
  non-commit tree object with the explicit `git tree identity:` prefix without
  changing its bytes or creating a false commit permalink, or use an exact
  content permalink when navigation is required.
- Unsafe retry boundary: do not leave a short SHA in code formatting, do not
  treat an arbitrary 40-hex object as a commit, and do not split one validator
  count into derivative findings.
- Freshness and review condition: confirmed 2026-08-02 by the exact current
  occurrence; review after the canonical commit-reference validator contract
  or record-authoring process changes.
- Superseded by: `None`

### Executable Case rename leaves a retired fixture path in a structural consumer

- Status: `Active`
- Observable signature: a structural test opens a retired `.fixture.ps1` path
  while the exact owner inventory contains the corresponding `.case.ps1`, or a
  literal search reports no match because the path is statically concatenated.
- Applicability: executable test-role renames and every PowerShell test-code or
  contract consumer of the renamed owner.
- Affected contract and cause: the Case inventory changed atomically, but a
  separate AST consumer retained its hand-written path and escaped literal-only
  review by splitting the string.
- Canonical owner and evidence: [FIND-0285](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0285)
  / [TEST-0187](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0187)
  owns the role-transition barrier.
- Fixed release or evidence: focused role-boundary, canonical-helper, and
  runtime-efficiency owners pass; target release `0.15.0` carries the route.
- Required safe response: derive retired names from the exact current Case
  inventory, fold static PowerShell string concatenations, update every code and
  contract consumer in the same change, and run the structural consumer.
- Unsafe retry boundary: do not rerun the missing path, patch only the first
  call site, or accept a raw literal search as complete rename evidence.
- Freshness and review condition: last confirmed 2026-07-25; review whenever an
  executable test-role suffix or owner path changes.
- Superseded by: `None`

### Canonical helper refactor leaves a stale reviewed AST operation inventory

- Status: `Active`
- Observable signature: [TEST-0159](../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)
  reports unreviewed or absent dynamic invocations, escaped owners, or static
  counter-site differences immediately after a helper or process owner moves.
- Applicability: test refactors that centralize dynamic commands, native-process
  dispatch, Git splats, or operation-counter ownership.
- Affected contract and cause: runtime behavior and maxima may remain correct,
  while the review-only AST inventory still describes the pre-refactor call
  graph.
- Canonical owner and evidence: [FIND-0286](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0286)
  / [FIND-0342](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0342)
  / [TEST-0159](../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)
  owns structural operation review independently from runtime maxima.
- Fixed release or evidence: release `0.15.0` carried the original reconciled
  inventory. The v0.15.5 exact immutable-policy fixture helper added four
  reviewed launcher invocations and one helper-owned recursive cleanup identity;
  after exact reconciliation the focused runtime-efficiency owner passed on
  PowerShell 7 / Windows PowerShell 5.1 in 7.0 / 7.7 seconds. The declared
  runtime-budget file stayed byte-identical. The frozen-tree canonical full
  suite then passed every discovered owner in 1745.3 seconds; the runtime-
  efficiency owner passed in 6.586 seconds with `contract.self-check` 1/1.
- Required safe response: classify each diagnostic against the intended
  canonical owner, update the reviewed identities and centralized call-site
  assertions in the same slice, then prove runtime budgets remain unchanged.
- Unsafe retry boundary: do not blindly copy observed counts, suppress the AST
  gate, or treat derivative diagnostics as separate runtime defects.
- Freshness and review condition: last confirmed 2026-07-27; review whenever a
  reviewed dynamic/helper/process call graph changes.
- Superseded by: `None`

### Untracked governance packet is absent from the HEAD self-consumer graph

- Status: `Active`
- Observable signature: [TEST-0152](../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152)
  passes in a dirty worktree, then hosted validation rejects a path-like token
  from the newly committed packet as a missing required instruction target.
- Applicability: new feature, decision, memory, or other governance packets that
  are untracked while the canonical suite builds the repository's exact graph
  from `HEAD`.
- Affected contract and cause: filesystem-oriented owners can inspect the new
  packet, but the exact self-consumer graph intentionally reads committed Git
  objects and cannot inspect a path absent from the HEAD tree.
- Canonical owner and evidence: [FIND-0343](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0343)
  / [TEST-0152](../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152)
  / [run 30225563133](https://github.com/hasanmanzak/meAndAI/actions/runs/30225563133)
  own the exact committed-tree boundary.
- Fixed release or evidence: target release `0.15.5`; all three slash-joined
  command shorthands are distinct inline-code commands in
  [commit a0ed721](https://github.com/hasanmanzak/meAndAI/commit/a0ed7218175b7e1783c9db56174518eef4b344b0).
  The exact committed-tree owner passed on PowerShell 7 / Windows PowerShell
  5.1 in 136.2 / 236.5 seconds with 2/2 process starts and 4/4 blob requests,
  and the committed-tree full suite passed in 1805.3 seconds. Hosted
  confirmation remains pending.
- Required safe response: classify the hosted diagnostic against committed
  bytes, search the entire candidate packet for the same token family, correct
  only ambiguous documentation syntax, commit the full graph-reachable packet,
  then require exact-commit focused evidence on both runtimes and invalidate it
  after any later graph-reachable Markdown change.
- Unsafe retry boundary: do not weaken significant missing-path safety, ignore a
  hosted-only exact-tree failure, or claim a dirty-worktree full-suite pass as
  proof for a packet that was not yet in HEAD.
- Freshness and review condition: last confirmed 2026-07-27; review whenever a
  final local suite includes new untracked governance packets.
- Superseded by: `None`

### Runtime bundle path is inferred as a repository source path

- Status: `Active`
- Observable signature: current post-publication verification receives `404`
  for a GitHub Contents request formed by prefixing a valid runtime bundle path,
  while the immutable bundle and its manifest remain internally valid.
- Applicability: deterministic release archives whose runtime layout differs
  from the tracked source layout for one or more payloads.
- Affected contract and cause: the builder, verifier, or a fixture recreates an
  archive-to-repository mapping instead of consuming the release-owned ordered
  source inventory.
- Canonical owner and evidence:
  [FIND-0287](../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/README.md#find-0287)
  / [TEST-0189](../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189)
  / [issue #131](https://github.com/hasanmanzak/meAndAI/issues/131).
- Fixed release or evidence: immutable
  [v0.15.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.1);
  immutable `v0.15.0` remains the historical schema-1 compatibility boundary.
- Required safe response: read the declared `bundlePath` and `repositoryPath`
  pair from the canonical inventory, validate both independently, and compare
  exact tracked Git-blob bytes with the declared archive payload.
- Unsafe retry boundary: do not infer repository paths from archive paths, add
  another path-specific conditional, or retry a failed inferred request with a
  heuristic alternate path.
- Freshness and review condition: last confirmed 2026-07-25; review whenever
  the source-inventory schema or bundle payload set changes.
- Superseded by: `None`

### URI suffix or raw token shape changes a decoded instruction reference

- Status: `Active`
- Observable signature: a local literal-hash/query reference is redirected by
  suffix dot segments, a second literal/decoded delimiter reopens a prior opaque
  suffix, or an encoded extensionless file/drive/external target is discarded
  before the decoded spelling reaches safety classification.
- Applicability: instruction-reference code spans and Markdown targets whose
  decoded value contains `#`, `?`, an encoded scheme/drive prefix, or no normal
  path-shaped extension or slash.
- Affected contract and cause: fragment/query suffix text was allowed to enter
  repository dot-segment normalization; scanning backward from a later
  delimiter could normalize an earlier suffix again; and a raw token-shape
  prefilter ran before URI decoding and scheme classification.
- Canonical owner and evidence:
  [FIND-0331](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0331)
  / [FIND-0335](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0335)
  / [FIND-0336](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0336)
  / [FIND-0339](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0339)
  / [TEST-0152](../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152)
  / [issue #140](https://github.com/hasanmanzak/meAndAI/issues/140).
- Fixed release or evidence: immutable release `0.15.5` decodes before shape
  filtering, classifies decoded unsafe/external schemes first, selects the
  longest canonical exact-tree prefix for local hash/query targets, and keeps
  every later literal/decoded delimiter inside the opaque suffix. The final
  Windows PowerShell 5.1 / PowerShell 7 canonical owner passed in 248.3 / 143.5
  seconds with exact 2/2 process starts and 4/4 blob requests on both runtimes;
  the parser-focused bounded audit found no new `Blocking` or `Important`
  finding and both runtime AST parses plus diff-check were clean.
- Required safe response: strictly decode first. Reject decoded `file:` and
  drive targets, retain decoded external schemes as external, then resolve a
  local target against the longest canonical exact-tree prefix. Once the first
  valid boundary establishes identity, never allow suffix fragment/query text
  or a later literal/decoded delimiter to reopen dot-segment normalization.
- Unsafe retry boundary: do not run a raw shape filter before decoding, treat
  URI suffix text as a repository path, re-normalize a candidate through a
  later delimiter, or prefer a shorter/literal candidate over the longest
  exact-tree prefix.
- Freshness and review condition: last confirmed 2026-07-27; review whenever
  token extraction, URI decoding, scheme classification, exact-tree lookup, or
  query/fragment handling changes.
- Superseded by: `None`

### Authority negation masks a positive mixed-line declaration

- Status: `Active`
- Observable signature: negative qualified-authority wording followed by a
  positive declaration after `but`, a semicolon, a period, or `however` yields
  no authority; alternatively, qualifier `and` splits the negative mask and
  exposes a false authority tail, a missing direct/reverse negative form becomes
  live authority, or ordinary extensionless-path negation crosses a connective
  and masks a later positive designation.
- Applicability: bounded `single canonical ... source/authority` declarations
  containing direct/reverse modal, contraction, `no longer`, or `never`
  predicates, qualifier conjunctions, or multiple clauses on one semantic line.
- Affected contract and cause: the negative grammar omitted reviewed forms; a
  broad 160-character mask could consume a later positive designation without
  requiring an exact authority complement; and treating every conjunction as a
  clause boundary split `product and domain` inside the same predicate.
- Canonical owner and evidence:
  [FIND-0332](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0332)
  / [FIND-0337](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0337)
  / [FIND-0338](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0338)
  / [FIND-0340](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0340)
  / [FIND-0341](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0341)
  / [TEST-0151](../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151)
  / [issue #146](https://github.com/hasanmanzak/meAndAI/issues/146).
- Fixed release or evidence: immutable release `0.15.5` covers bounded direct and
  reverse modal, contraction, `no longer`, and `never` forms; binds negation to
  the same exact authority-designation complement as the positive grammar;
  keeps qualifier conjunctions intact; and preserves a positive mixed-line
  declaration conservatively. The final Windows PowerShell 5.1 / PowerShell 7
  canonical owner passed in 248.3 / 143.5 seconds with exact 2/2 process starts
  and 4/4 blob requests on both runtimes; the parser-focused bounded audit found
  no new `Blocking` or `Important` finding and both runtime AST parses plus
  diff-check were clean.
- Required safe response: require the exact positive authority-designation
  complement after a reviewed negative predicate and keep allowed qualifier
  conjunctions within that match. If any separate positive authority
  declaration remains on the line and exact path-to-clause ownership is
  unavailable, classify the line conservatively as authority so protected
  evidence fails closed.
- Unsafe retry boundary: do not suppress the entire line from one negative
  predicate, use a generic character-width mask across ordinary prose, omit a
  reviewed direct/reverse negative form, split qualifier `and` as though it
  always starts a new clause, or infer that a path belongs only to the negative
  clause.
- Freshness and review condition: last confirmed 2026-07-27; review whenever
  authority grammar, negation masks, qualifier bounds, or semantic-line
  reference ownership changes.
- Superseded by: `None`

### Runtime graph policy or marker semantics replace an immutable target contract

- Status: `Active`
- Observable signature: a newer quick-adoption runtime targets an older
  immutable workflow and imports runtime graph semantics, accepts only broad
  limit bounds, mixes target commands with a partial helper family, rewrites a
  schema-7/8 marker as schema 9/10, or grants runtime-policy fallback to an
  unreviewed graph-unaware tag.
- Applicability: quick-adoption runtime/target pairs from the first bundled
  runtime through the current candidate, including graph-unaware v0.12.4-
  v0.12.5 and graph-aware v0.12.6-v0.16.0 workflows.
- Affected contract and cause: workflow capability, exact target profile,
  target-semantic command ownership, ancillary-helper composition, and marker
  family were not treated as one immutable compatibility contract. Release-
  owned graph or transition evidence could therefore be reinterpreted across
  a target boundary.
- Canonical owner and evidence:
  [FIND-0319](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0319)
  / [FIND-0321](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0321)
  / [FIND-0327](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0327)
  / [FIND-0333](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0333)
  / [FIND-0334](../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0334)
  / [TEST-0153](../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  / [issue #147](https://github.com/hasanmanzak/meAndAI/issues/147).
- Fixed release or evidence: immutable release `0.15.5`, retained through `0.16.0`, binds every supported
  graph-aware tag to its reviewed exact profile, keeps all target-semantic
  commands target-owned, composes the three linked-path helpers atomically,
  preserves schema 7/8 for v0.12.6-v0.14.1 and schema 9/10 thereafter, and
  limits graph-unaware runtime fallback to exactly v0.12.4-v0.12.5. Focused
  PowerShell 5.1/7 and affected integration evidence is green; immutable
  publication remains pending.
- Required safe response: retrieve and verify the exact target workflow before
  assessment. For a supported graph-aware tag, import the exact target policy,
  require its exact reviewed profile and every target-semantic command, compose
  either all three target ancillary helpers or all three runtime helpers, and
  preserve the target marker family through every transition. Use runtime
  policy for a graph-unaware target only when its exact tag is v0.12.4 or
  v0.12.5. Fail closed for a partial helper family, an unknown profile, a
  too-old tag, or a future tag.
- Unsafe retry boundary: do not infer schema or marker family from a broad
  upper bound, convert graph identity between schemas, mix target and runtime
  helpers, rewrite schema-7/8 evidence as schema 9/10, extend fallback to an
  unreviewed tag, or force runtime policy onto a graph-aware target.
- Freshness and review condition: last confirmed 2026-07-27; review whenever
  workflow graph inputs, exact target profiles, policy exports, ancillary
  helpers, marker schemas, or dispatch identity changes.
- Superseded by: `None`

## Open context

- The maintainer accepted
  [DEC-0035](../../docs/decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
  on 2026-07-29 under
  [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
  and [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164).
  The accepted
  [architecture](../../docs/architecture/protocol-governance-and-execution/README.md)
  makes one versioned executable protocol platform the product: shared
  conformance, shared execution authority, evidence/integration, adoption,
  update, release finalization, and compatibility/migration are capability
  boundaries; CLI processes are thin hosts only. C# is the implementation
  language. [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169) merged
  the accepted architecture at
  [`a2be672b91cb41b88597c5123a0d5b0e9a54d34e`](https://github.com/hasanmanzak/meAndAI/commit/a2be672b91cb41b88597c5123a0d5b0e9a54d34e),
  whose exact tree passed [main run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).
  The historical [implementation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932)
  and [infrastructure clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847)
  authorized only [SUBF-0152](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
  and [TEST-0220](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220).
  Expected-red checkpoint
  [`9a48c02266d9690e14240de0fac3c57d54d12fa6`](https://github.com/hasanmanzak/meAndAI/commit/9a48c02266d9690e14240de0fac3c57d54d12fa6)
  failed only for deliberately absent contracts; 52 focused tests, Release
  build, format,
  [TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
  cross-runtime StructureOnly, and Gate 5 reviews
  later passed. [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170)
  merged the completed implementation at exact main
  [`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
  whose [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506)
  passed Ubuntu and Windows.

  The historical
  [SUBF-0153](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
  [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
  produced the accepted
  [evidence-acquisition design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0153-evidence-contract-design.md).
  [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) merged it at exact
  main
  [`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f),
  with bounded [closure evidence](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520).
  That historical directive granted no implementation authority. The later
  [activation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5135051435)
  authorizes bounded Gate 3 implementation and atomic workflow/scenario-owner
  activation for
  [SUBF-0153](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
  and
  [TEST-0221](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221).
  The historical activation candidate was developed on
  `codex/subf-0153-evidence-contract-implementation` from predecessor
  [`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7).

  The valid red compiled the public-API reflection oracle and failed its one
  selected test solely because the normative 23-type slice inventory was
  absent. Discard the
  separate `NETSDK1064` package-cache attempt; it is not red or regression
  evidence. Historical local evidence was 46 of 46 focused tests and 98 of 98
  combined predecessor/slice tests passing, a Release build with zero warnings
  and zero errors, and clean format verification. Lock-file hashes are
  unchanged, and project/package/solution/lock files are unchanged.
  [TEST-0221](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
  is `Passing` and its current owner is the existing
  `tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj`.
  The authorized workflow/scenario-owner activation is applied, and the
  [TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  activation implementation is green. Gate 5 removed the private
  `CanonicalEvidencePayload` constructor reflection oracle and strengthened
  public-observable validation, equality, and defensive-ownership cases. This
  bounded packet subsequently completed through
  [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173), exact main
  [`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd),
  and [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256).
  The [implementation handoff](log/2026-07-30-feat-0065-subf-0153-evidence-contract-implementation.md)
  is retained as historical pre-publication evidence.

  The separate [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584)
  produced the Gate 1/2 design and expected-red planning for
  [SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  and [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210).
  Follow the exact
  [typed-evaluation-kernel design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md).
  That Gate 2 packet is accepted, merged, and bounded exact-main validated at
  [`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7).
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned`. Its local Gate 3 working tree now has the six-project
  scaffold, exact SurfaceRed, cumulative-A 48-type surface, and `11/11`
  structural checkpoint. BehaviorRed observations made before their applicable
  [message/echo](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
  and [RunInfo](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
  clarifications remain diagnostic. The fresh post-synchronization same-FQN run
  passed the complete corrected oracle as canonical BehaviorRed. The first
  limited ParseCanonical increment then passed original-oracle and final-source
  exact-FQN checks `1/1`, cumulative A `12/12`, format verification, a warning/
  error-free final six-project Release build, and private-byte implementation
  review. That first-green support review had `0 Blocking`, one unnumbered
  remaining-A coverage `Important`, and no unresolved `Minor`. The historical
  [canonical-string bounded-green closure handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-canonical-string.md)
  preserves FQN
  `MeAndAI.Protocol.Conformance.Tests.ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding`,
  marker/TRX `TEST-0210-A-BEHAVIOR-RED-0002`, writer-owned internal
  `CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)`, exact
  legacy/green quoted bytes, the 1,226-byte Unicode fixture and digest, exact
  composed `C3 A9` versus decomposed `65 CC 81` non-normalization oracle,
  complete lexical/malformed matrix, and narrow green topology. The reader must
  canonicalize through that same codec and compare the complete quoted token at
  `TokenStartIndex..BytesConsumed`; it catches only `GetString()`-originated
  `InvalidOperationException` at the decode boundary. Direct malformed .NET
  UTF-16 is codec-argument `ArgumentException`; malformed raw/escaped public
  documents remain `FormatException`. Seam predecessor and both exact-FQN greens
  passed `1/1`; the exact red and bounded source review closed `0 Blocking`/
  `0 Important`/`0 Minor`; cumulative A passed `13/13`. Locked restore,
  unchanged six lock fingerprints, standard format, clean diff check, and the
  zero-warning/error six-project Release build passed. The non-gating severity-
  info scan exposed pre-existing informational backlog/suggestions and is not
  claimed clean. Canonical-string coverage `Important` is closed at the
  historical `13/13` checkpoint; current grammar/number/graph/rule routing is
  the [FIND-0441](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0441)
  recovery described below, and
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned`.
  It separates qualification slices from complete catalogs, uses an acyclic
  artifact/manifest/release graph, and fixes the cumulative public inventories
  at `48/72/95/96`, ending with `72` Abstractions, `23` Conformance, and one
  Policy export. Its manifest closes six typed registration lists, the
  `27`-row Policy registration/type-contract partition, and the `35`-row full
  component union.

  [FEAT-0067](../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  owns routing/I/O and constructs an instruction-bound structural
  observed result, but it does not invoke a Policy codec or own a semantic
  cache. The exact plan-bound Conformance qualification session resolves the
  manifest codec, invokes it once per binding/cache miss, verifies exact
  byte/depth/node/complexity usage, and returns qualified model handles or a
  declared rejection. Application copies those handles into its proof
  candidate; the Conformance admission coordinator validates them without a
  codec rerun.

  The mandatory state sequence is `PlanApplicability -> CloseApplicability ->
  PlanEvaluation -> zero-to-N AdvanceEvaluation -> EvaluationClosure ->
  Evaluate`. Evaluation plans are non-empty, predecessor/session-stamped, and
  single-use; Evaluate is proof-free and runs no acquisition, codec, parser,
  index, or demand projector. Repository-tree, one governed body, and
  repository-target-resolution use exact protocol-owned persistent binary
  wires. Target demand is projected only after the one per-plan governed-
  reference index, retains the internal ItemId-to-source-and-authority map, and
  is sharded by owning repository while preserving the governed subject target.
  CommitObject, TagRoot, and CapturedSnapshotPath cover immutable/current target
  evidence. Captured paths are qualified against the exact
  [FEAT-0067](../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  manifest
  identity/path/expected-content tuple retained with the private source-
  authority binding; an opaque capture digest cannot decide Exact/WrongObject.
  Target-derived resolution/object/anchor/line proofs use canonical framed
  identities, and external-owner custody remains Snapshot rather than being
  mislabeled as the subject repository. A paired target-Markdown model owns
  historical anchors. Its successful output must pair exactly with its target
  model, while a declared parser failure produces no set model/index invocation
  and terminalizes dependent rules as NotEvaluated. Empty demand
  emits no external instruction/I/O/payload/codec, but the registered target
  index still runs once over zero target/target-Markdown models plus the
  qualified reference capability.

  Semantic producers report local generated bytes/layer nodes/additional
  complexity only; selected rank-0 payload bytes are never counted again. The
  target-Markdown parser admits the full 33,554,432-byte parent boundary in its
  byte/complexity budget. Plan-global target retention is closed by a distinct
  `projected-resource-failed` aggregate outcome at the 64-key/16,777,216-content-
  byte/67,108,864-full-payload limits; it retains valid individual attempts but
  mints no aggregate proof or partial parser/index product.

  Qualified references/findings/evaluations remain in Conformance rather than
  Domain; Policy contains no provider DTO, route, credential, filesystem,
  network, or I/O surface.
  For
  [SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143),
  Gate 2 review, maintainer acceptance, merge, and bounded exact-main
  validation are complete. The prerequisite
  [SUBF-0153](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
  completed through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173)
  at exact main
  [`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd),
  and [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256)
  passed. The corrected
  [ContractSlice A directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228)
  authorizes a ParseCanonical-only A topology correction, bounded correction
  red-team, exact project/reference/lock and predecessor-ownership transition,
  exact A expected reds, and cumulative-A C# green. A constructs no executable
  export, validates no typed registration list, and declares no kernel; first
  executable activation and registration-mismatch ownership begin in C.
  The append-only
  [BehaviorRed evidence clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
  makes the exact failed-result message authoritative, permits no marker outside
  that node except at most one byte-identical run-summary adapter echo, and
  derives `Xunit.Sdk.FailException` from the reviewed direct `Assert.Fail`
  source plus immutable xUnit `2.9.3` lock rather than TRX.
  The later [RunInfo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
  permits at most one exact-shape marker-free same-FQN `[FAIL]` bookkeeping node
  only with the sole Failed result, exact message, all 16 counters including
  `error=0`, and no other diagnostic.
  [FIND-0439](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0439)
  fixes the remaining parser boundary: exact byte/depth/token ceilings,
  exhaustive document-local `FormatException`, post-parse-only
  `CatalogIncomplete`, role-reachable components with four exact runtime-anchor
  exemptions, and trusted-envelope ownership of real commit/blob/content proof.
  [FIND-0440](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0440)
  records the RunInfo evidence-contract correction; its mandatory fresh rerun
  is now satisfied by the accepted canonical A BehaviorRed.
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned`. Correction red-team closed with no Blocking, Important,
  or Minor finding and canonical StructureOnly passed. Project/lock ownership,
  exact SurfaceRed, the 48-type structural surface, and focused `11/11` are
  locally complete. Renewed architecture review of the topology/parser
  corrections and
  [FIND-0440](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0440)
  passed with `0 Blocking`, `0 Important`, and
  `0 Minor`. Pre-applicable-clarification BehaviorRed
  observations remain diagnostic only. The fresh post-synchronization exact-FQN
  invocation produced one reviewed canonical TRX with the sole Failed result,
  exact marker message, one permitted `StdOut` echo, exact marker-free RunInfo,
  Failed summary, and complete 16-counter inventory including `error=0`. The
  first limited ParseCanonical implementation replaced the sentinel, passed the
  original-oracle and final-source exact-FQN checks `1/1`, cumulative A `12/12`,
  format verification, and the warning/error-free final six-project Release
  build, and satisfied private-copy/canonical-reserialization/no-retained-raw-
  byte source review. Equality now precedes digest/object construction. The
  private input and writer-returned arrays are zeroed in `finally`; the
  unretained `ArrayBufferWriter` internal buffer becomes unreachable but is not
  explicitly zeroed. That first-green support review had `0 Blocking`, one
  unnumbered remaining-A coverage `Important`, and no unresolved `Minor`. The
  second A canonical-string exact-red packet and bounded-green closure are in the historical
  [handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-canonical-string.md):
  exact `0002` FQN/marker, behavior-preserving writer-owned codec extraction,
  exact legacy/green bytes, raw Unicode, exact composed `C3 A9` versus decomposed
  `65 CC 81` non-normalization, lowercase C0/DEL/C1, positive 1,226-byte fixture/
  digest, and malformed raw/escaped input taxonomy. The reader reuses the same
  codec for complete quoted-token comparison and narrowly maps only decode-boundary
  `GetString()` `InvalidOperationException`. Internal malformed .NET UTF-16 remains
  `ArgumentException`; public malformed documents are `FormatException`. Seam
  predecessor and original-oracle/final-source greens passed `1/1`; exact red
  and bounded source review closed `0 Blocking`/`0 Important`/`0 Minor`;
  cumulative A passed `13/13`. Locked restore, unchanged lock fingerprints,
  standard format, clean diff check, and the zero-warning/error six-project
  Release build passed; the non-gating severity-info scan is not claimed clean.
  Canonical-string coverage `Important` is closed at the historical `13/13`
  checkpoint. Later pushed input
  [`7f60e0c`](https://github.com/hasanmanzak/meAndAI/commit/7f60e0c66a49056b9e9854ccc353acfe67f65ed5)
  is under
  [FIND-0441](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0441)
  recovery: four retained focused filters pass `1/1`, cumulative A passes
  `17/17`, and final local V plus fresh full-diff review `0/0/0` establish
  `ReviewedLocalGreen`. Audited tree `4ca02623...` is pushed at exact content
  checkpoint
  [`f64860ef...`](https://github.com/hasanmanzak/meAndAI/commit/f64860ef456380232c23dfc4729a0d87f257483d)
  on draft
  [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174); the
  [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442)
  correction is reviewed, pushed, and exact-head hosted green. Remote-equal
  [`c88beefee54f3f0d0e0e623807eb8a4c9bf48032`](https://github.com/hasanmanzak/meAndAI/commit/c88beefee54f3f0d0e0e623807eb8a4c9bf48032)
  is the frozen predecessor for packet-local `ReviewedLocalGreen`
  `A-SCHEMA-SLOT-01`. Its
  [FIND-0443](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443)
  recurrence is exactly the diagnostic `cf51...` and `9a39...` runs. The third
  `c96...` observation is a separate zero-discovery VSTest infrastructure
  abort. Canonical 0003 BehaviorRed is accepted at the exact `96ff...` TRX:
  one process-scoped 300-second-child / exact-420-second-outer invocation passed
  the complete oracle, the parent environment remained unset, and no retry is
  authorized. Original-oracle and topology-clean focused greens passed `1/1`,
  cumulative A passed `18/18`, final source is 436 lines at SHA-256
  `FC43FDDA4B273BFCBED442FB145E28BA207EE433A08A9D3E43BEA88574154480`,
  code/test is `692/700`, build is zero-warning/error, format passed, and locks
  are unchanged.
  [TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074)'s
  fixture-data literal is neutral
  [TEST-0001](../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001)
  with
  no Scenario trait. The 300-second StructureOnly and earlier 600-second full-
  suite expirations are infrastructure observations below official budgets,
  not red/green evidence. Fresh full-diff review pass 2, after the pass-1
  traceability correction, closed `0 Blocking / 0 Important / 0 Minor`.
  [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  remains `Planned`. The later umbrella checkpoint authorized the strictly
  redrawn `A-INDEX-SLOT-01`, whose corrected renewed RT closed `0/0/0` and whose
  current state is `ReviewedLocalGreen`. Subsequent strict D/RT retired
  never-activated `A-PARSER-INDEX-01`; `A-PARSER-RECORD-SLOT-01` and
  `A-GOVERNED-REFERENCE-SLOTS-01` are `ReviewedLocalGreen`. The latter is exact
  remote-equal hosted green at
  [`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602),
  git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`,
  and [run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121);
  its exact R/G evidence is retained in the current governed-reference handoff.
  [FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447)
  is resolved at exact [`3fa66695eb978954b321545e2d226c1effa6ead4`](https://github.com/hasanmanzak/meAndAI/commit/3fa66695eb978954b321545e2d226c1effa6ead4) /
  [run 30746985780](https://github.com/hasanmanzak/meAndAI/actions/runs/30746985780).
  [FIND-0448](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0448)
  is resolved at exact [`561a760401cf7312a15cadea3e6bf9f56b488d5d`](https://github.com/hasanmanzak/meAndAI/commit/561a760401cf7312a15cadea3e6bf9f56b488d5d),
  git tree identity: `8f120c396bd531e7b33d9c00a1265e0a7be6d1ba`, and successful
  [run 30748757145](https://github.com/hasanmanzak/meAndAI/actions/runs/30748757145).
  `A-TARGET-PARSER-INDEX-SLOT-01` is a `FrozenDesign` at the current
  [target freeze handoff](log/2026-08-02-feat-0065-subf-0143-contractslice-a-target-parser-index-slot-freeze.md);
  every later packet remains Candidate/inactive. The live denominator is twenty
  and current `ReviewedLocalGreen` progress is eight (`40%`), with cumulative A
  green `21/21`.
  Partial facts retain `ContractSlice` only; their final `Scenario`
  traits are deferred. B/C/D, workflow/scenario-trait/scenario-owner/
  [TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  activation, WIP extraction, consumer/release/publication/authority-transfer,
  and PowerShell-retirement changes remain held. A's canonical first BehaviorRed
  used only the exact warning-free `FinalizedPolicyManifest.ParseCanonical => null!`
  sentinel and positive minimal-manifest null predicate; the stable green source
  now contains neither that sentinel nor the marker/null branch. B/C/D retain their
  activation/export sentinels. C first activates an executable export; D first proves the real
  export graph. RULE-0001 is deliberately later: the real D writer/codec/parser/
  index/projector/kernel vectors must be green before the D session can mint its
  fresh Conformance-registered input from immutable fixture data; no C runtime
  handle/result may be consumed.
- The accepted
  [successor plan](../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md)
  allocates shared conformance to
  [FEAT-0065](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md)
  / [issue #165](https://github.com/hasanmanzak/meAndAI/issues/165),
  shared execution authority to
  [FEAT-0066](../../docs/features/FEAT-0066-shared-execution-authority-foundation/README.md)
  / [issue #166](https://github.com/hasanmanzak/meAndAI/issues/166),
  evidence/managed integration to
  [FEAT-0067](../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  / [issue #167](https://github.com/hasanmanzak/meAndAI/issues/167),
  adoption to rescoped
  [FEAT-0061](../../docs/features/FEAT-0061-consumer-adoption-cli/README.md)
  / [issue #156](https://github.com/hasanmanzak/meAndAI/issues/156),
  update to rescoped
  [FEAT-0062](../../docs/features/FEAT-0062-consumer-protocol-update-cli/README.md)
  / [issue #157](https://github.com/hasanmanzak/meAndAI/issues/157),
  release finalization/transfer to
  [FEAT-0068](../../docs/features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
  / [issue #168](https://github.com/hasanmanzak/meAndAI/issues/168),
  and parked compatibility/migration/retirement to
  [FEAT-0063](../../docs/features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
  / [issue #158](https://github.com/hasanmanzak/meAndAI/issues/158).
  Stable [RULE-0001](../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001)
  through [RULE-0005](../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005)
  start the first shared semantics matrix across documents, links, anchors,
  commit evidence, repository evidence, and provider evidence; this is not the
  complete catalog.
- [FEAT-0060](../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
  and [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160)
  remain frozen at exact preserved commit
  [1873c98638ba4960734aadb188eb8c8d70b4bc52](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52).
  The [WIP extraction ledger](../../docs/architecture/protocol-governance-and-execution/wip-extraction-ledger.md)
  classifies all 158 changed paths as reusable, refactor, preserve-only, or
  reject. Four of seven WIP slices have historical exact-branch evidence, the
  parent is incomplete, and no successor inherits a passing state. Do not push
  implementation to [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160)
  or extract its code. The bounded [TEST-0220](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
  stable-job route is complete. The historical
  [SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584)
  authorized no workflow, scenario-owner, project, lock, test, or implementation
  change. It is superseded for the bounded ContractSlice A operation by the
  corrected [exact-A directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228),
  which authorized the reviewed A project/lock/test transition and only the C#
  implementation needed for reviewed A red-to-green increments. That authority
  does not extend to B/C/D, workflow/scenario-owner/[TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  activation, WIP extraction, consumer mutation, release/publication, authority
  transfer, or PowerShell retirement; those scopes still require their later
  dependency-closed Definition of Ready and explicit maintainer directive.

- Immutable [v0.15.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.5)
  is published at
  [`11c56aac369767202835c4e9d6cc83aa321f4070`](https://github.com/hasanmanzak/meAndAI/commit/11c56aac369767202835c4e9d6cc83aa321f4070).
  [PR #148](https://github.com/hasanmanzak/meAndAI/pull/148) merged after
  [hosted run 30230496137](https://github.com/hasanmanzak/meAndAI/actions/runs/30230496137)
  passed both canonical checks; the release API reports non-draft,
  non-prerelease, immutable state and the exact two assets. Its owned remote
  branch is absent.
- [FEAT-0058](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md)
  / [BUG-0045](https://github.com/hasanmanzak/meAndAI/issues/149) /
  [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) is the
  completed historical `0.15.6` delivery. [PR #152](https://github.com/hasanmanzak/meAndAI/pull/152)
  merged at
  [`5321f1f1aa5966114c69b46bf6ed9191df109e6b`](https://github.com/hasanmanzak/meAndAI/commit/5321f1f1aa5966114c69b46bf6ed9191df109e6b),
  immutable [v0.15.6](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.6)
  publishes the exact two canonical assets, and final post-publication
  [run `30285030427`](https://github.com/hasanmanzak/meAndAI/actions/runs/30285030427)
  passed. Bounded historical proof still runs before the first relevant
  mutation, freezes metadata for later inventory reads, never edits completed
  historical issues, and preserves the current convergence owner. Keep every
  reusable regression upstream and do not mutate a consumer.
- Latest-byte read-only consumer resimulation kept pre/post remote HEADs exact
  and every clone clean. Derdini `e7b10ef` retained its existing older seed,
  which v0.15.5 does not recognize. TravelOS `6ee1191` returned assessment schema
  3 for graph `0cd369f4...` with 9 nodes / 74 edges: `Auto` required explicit
  strategy and hypothetical `FullMigration` was `Resolved`; assessment/summary
  SHA-256 values were `cf5f3609931cda8ba51cfb5b9f2325d777c82a7278ffd9ef36251ac509536c16`
  / `b180143e125fdff13d24d3f717aeca4333fd0b6098be8c96cabb0a1ce2177d73`.
  HAnchor `0281b39` failed closed for maintainer review because protected
  `HAnchor.mq5` is live canonical authority. No consumer was modified and no
  GitHub simulation repository was created.
- [FEAT-0035](../../docs/features/FEAT-0035-test-runtime-efficiency/README.md) / [BUG-0017](https://github.com/hasanmanzak/meAndAI/issues/87) completed in v0.12.3 under [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87). Its focused and
  hosted evidence retains the representative security, recovery, TOCTOU,
  credential, link/reparse, process, Codex, and native-Windows vertical slices.
  Linux 2 minutes and Windows 3 minutes remain non-gating optimization goals;
  do not encode them as timeouts or restore hosted fan-out.
- The v0.12.4-and-later runtime release contract contains exactly two assets: the thin
  launcher downloaded by the maintainer and one internal verified module
  bundle. `RuntimeReleaseTag` identifies the executable runtime independently
  of the compatible consumer target selected by `-ProtocolTag`.
- `v0.12.2` keeps `push: main` because private-main protection remains
  unavailable. Both stable jobs may run `StructureOnly` only when local Git
  and paginated GitHub evidence prove an exact successful merge-queue commit
  or one exact merged PR whose merge tree equals its already-green head tree.
  Direct, squash, rebase, forced, mismatched, duplicate, failed, canceled, or
  unavailable evidence stays on `Full`.
- Managed-merge finalization fixtures replace and restore
  `GITHUB_STEP_SUMMARY` per invocation, capture exact summary lines for test
  assertions, and cannot write synthetic identities into an inherited outer
  summary. Live PR/push/check/merge/release facts use [issue #85](https://github.com/hasanmanzak/meAndAI/issues/85) as external
  authority and do not create metadata-only candidate commits.
- `v0.12.1` corrects the local/current-launcher migration planner's committed-
  state input boundary. Required inputs and the optional ledger come from
  exact validated base-commit Git blobs; worktree presence and containment
  remain write-safety evidence but checkout-filtered bytes are never used as
  committed-state evidence.
- `v0.12.0` declares typed immutable capabilities separately from deterministic
  migrations. The first semantic capability, `test-architecture`, keeps
  canonical suites under `tests/capabilities/<capability>`, preserves one
  feature-owned `TEST-NNNN` authority, discovers suites recursively, runs them
  in separate processes, and keeps mutable fixtures capability-local.
- Freshly adopted, already-current, and normally updated consumers evaluate
  the same target catalog. A pre-framework updater first completes its normal
  protocol update; only the installed same-target workflow may open the
  semantic handoff. One canonical issue, branch, transient manifest, and draft
  review are reused until reviewed terminal ledger evidence permits exact
  branch-first, issue-last finalization.
- `v0.11.0` adds explicit `FreshAdoption`, `FullMigration`,
  `HybridReconciliation`, acknowledged `CleanStart`, and `Abort` strategy
  handling. `Auto` selects only protocol-evidence-free fresh adoption;
  ambiguous non-interactive state fails closed.
- The immutable capabilities contract module is the only pure classifier and
  strategy-policy authority. Launcher and workflow actors keep separate
  evidence/mutation guards but do not embed or cross-check policy copies.
- The optional stability-cycle prompt remains inside the immutable protocol
  source. Adoption and updates do not copy it into consumer-owned files or
  create a goal, recurring task, automation, workflow, schedule, background
  loop, or next invocation.
- Existing consumers pinned to immutable `v0.1.0` require one manual upgrade
  and updater installation; consumers adopting `v0.2.0` receive the updater
  assets during initial collision-safe adoption.
- `v0.2.0` delivered the updater in
  [pull request #4](https://github.com/hasanmanzak/meAndAI/pull/4); `v0.2.1`
  refines validation bounds and documentation without changing updater behavior.
- `v0.3.0` adds the bounded post-development convergence scan in
  [FEAT-0003](../../docs/features/FEAT-0003-convergent-completion-scan/README.md).
- `v0.3.2` makes the updater's pre-cleanup audit comment conditional without
  changing cleanup ordering, safety gates, leases, or compensation behavior.
- `v0.4.0` uses consumer secret `MEANDAI_UPDATER_TOKEN` for repository-scoped
  writes and reconciles target-different updater assets in the same draft PR as
  the protocol pointer. Pre-v0.4 consumer copies need one reviewed migration.
- `v0.5.0` lets a submodule consumer seed only the canonical workflow. It
  proposes all absent deterministic adoption assets or a manifest-only semantic
  handoff on collision, then delegates later releases to the local updater.
- `v0.6.0` adds a source-only local launcher that creates or validates the
  consumer repository, provisions both fixed Actions secrets, and publishes
  only the exact seed workflow. It then runs the bounded lifecycle and places
  one idempotent Codex Cloud adoption task on the draft; it never merges.
- `v0.6.1` corrects that post-workflow boundary: no consumer Cloud connection
  or `@codex` comment is used. An authenticated local CLI works synchronously
  in a credential-free temporary clone under a finite timeout. The launcher
  owns labels, the marked adoption issue, verification, and the lease-protected
  push; Codex-spawned commands have network disabled. Secret creation remains
  deterministic and AI-free.
- `v0.6.2` preserves existing repository Actions secrets by name and creates
  only missing mappings. GitHub does not reveal stored values, so the launcher
  does not claim to validate an existing secret's value. `FG_PAT.txt` is not
  required or read when `MEANDAI_UPDATER_TOKEN` already exists.
- `v0.7.0` adds repository-native `IDEA-NNNN` incubation, a pinned consumer
  template, and absent-only idea-index installation for new collision-free
  adoption. Ideas do not authorize implementation or bypass delivery gates.
- `v0.7.1` makes both local credential files optional for an existing target
  when their mapped repository secrets already exist. With no protocol file,
  exact workflow and semantic-source retrieval uses the authenticated local
  `gh` identity; stored secret values remain unreadable. Missing secrets and
  new repositories still require their mapped local files.
- `v0.9.1` extends that rule to an accessible existing empty GitHub repository
  whose no-head local target has not yet connected `origin`; an absent derived
  repository still requires both files before creation.
- `v0.9.3` corrects the live adoption pull-request origin contract by using the
  repository name, repository owner, and Boolean cross-repository fields that
  GitHub CLI actually returns. Affected `v0.9.2` drafts remain retained and may
  be resumed with the corrected launcher.
- `v0.9.4` validates native Windows workspace writes without a model call,
  safely carries the verified sandbox implementation across isolated Codex
  configuration, distinguishes empty-project unknowns from adoption blockers,
  and makes launcher progress observable without inventing percentages.
- `v0.9.5` replaces the host-managed progress overlay with normal lines,
  presents bounded safe JSONL activity while local Codex runs, and terminates
  the contained process tree before cancellation cleanup. Streamed output is
  never readiness authority; interrupted publication retains [DEC-0013](../../docs/decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md) recovery.
- `v0.9.6` adds an initial GitHub CLI `2.82.1` compatibility gate with strict,
  unbounded decimal-component comparison. Older, malformed, leading-zero, or
  ambiguous version output blocks before authentication or state mutation.
- `v0.9.7` adds consumer-owned managed merge finalization after maintainer
  merge. It uses one non-closing tracking line, current-default containment,
  open-branch-reuse and exact-head checks, a leased branch deletion, and an
  idempotent manual recovery route before issue completion.
- `v0.10.0` completes the managed proposal lifecycle by creating/reusing its
  exact issue and labels, makes repeat adoption current/no-op or compatible
  installed-updater dispatch, establishes one live gitlink/`VERSION` pin, and
  supplies a bounded verified bridge for the update that installs this
  lifecycle over a legacy workflow.
- `v0.10.1` reduces Windows validation critical-path time without narrowing
  PowerShell 5.1 coverage: Linux retains canonical full-suite evidence, Windows
  uses four compatibility shards, and repeated mock resets reuse only one
  fingerprinted immutable protocol fixture and archive per process.
- `v0.10.2` replaces the overloaded integrity shard with four semantic,
  independently initialized compatibility shards and keeps release-only
  verification outside the ordinary validation matrix.
- `v0.10.3` targets generic consumer transition reconciliation. An immutable,
  append-only release catalog and exact consumer ledger let an engine-era
  updater include required consumer-state changes in the same reviewed draft
  as the protocol pin and updater assets. A pre-engine updater first installs
  that capability through its ordinary immutable path, after which the new
  engine opens one same-target reconciliation draft and the normal finalizer
  cleans its branch and issue after maintainer merge. Fresh adoption records
  the catalog as satisfied. [MIG-0001](../../migrations/MIG-0001.json) captures the duplicated-live-pin legacy-consumer shape
  without a source-version switch.
- `v0.10.4` adds the target-bound recovery path required when an immutable
  pre-engine updater cannot produce a validator-green transition. The latest
  launcher uses isolated exact-base and exact-target clones and the target
  release's production updater to create one schema-2 proposal containing the
  pin, changed updater assets, required migrations, and ledger. Exact legacy
  schema-1 drafts are cleanup-only and are retired replacement-first; no
  issue is invented for an unbound historical draft.
- Compatible catalogs are checked as a complete numeric descendant chain, not
  only as a current-to-latest pair. Schema-2 finalization independently
  rebuilds the target plan from immutable release and pull-request base blobs;
  exact head outputs, ledger, updater assets, and gitlink must match before
  branch/issue cleanup. Migration leaf links/reparse points fail before writes.
- `v0.9.2` distributes that same reviewed launcher as one immutable-release
  asset and reduces normal user execution to one local script command. The
  launcher stays outside consumer repositories and retains its release,
  source, credential, lifecycle, Codex, and merge boundaries.
- `v0.7.2` binds adoption proposals to canonical repository, base, actor, head,
  and marker evidence; validates exact protocol pins regardless of diff shape;
  rejects updater rename provenance; and moves adoption issues to review only
  after verified readiness.
- `v0.7.3` clarifies that the quick command starts the network-enabled parent
  launcher, applicable credential files stay in the original target and are
  absent only from the isolated Codex clone, and only Codex-spawned commands
  lose network access. It changes documentation and structural coverage only.
- `v0.8.0` establishes immutable-release, exact proposal-state, rename,
  workflow-run, supersession, and canonical repository-evidence invariants.
- `v0.8.1` carries repository host, release credential/commit, complete path,
  dispatch session, finding disposition, test evidence, and cleanup ownership
  through every mutation and closure boundary. An existing v0.8.0 consumer's
  old adapter may propose the ordinary v0.8.1 review PR; that proposal installs
  the new workflow and adapter together. After merge, later runs pass the
  separate `PROTOCOL_TOKEN` without a manual seed replacement.
- `v0.8.2` closes [FIND-0102](../../docs/features/FEAT-0012-v082-correction/README.md#find-0102), [FIND-0103](../../docs/features/FEAT-0012-v082-correction/README.md#find-0103), [FIND-0104](../../docs/features/FEAT-0012-v082-correction/README.md#find-0104), [FIND-0105](../../docs/features/FEAT-0012-v082-correction/README.md#find-0105), [FIND-0106](../../docs/features/FEAT-0012-v082-correction/README.md#find-0106), [FIND-0107](../../docs/features/FEAT-0012-v082-correction/README.md#find-0107), [FIND-0108](../../docs/features/FEAT-0012-v082-correction/README.md#find-0108), [FIND-0109](../../docs/features/FEAT-0012-v082-correction/README.md#find-0109), [FIND-0110](../../docs/features/FEAT-0012-v082-correction/README.md#find-0110), and [FIND-0111](../../docs/features/FEAT-0012-v082-correction/README.md#find-0111) with exact issue ownership,
  repository-scoped secret serialization, completed-proposal retention, full
  reserved-branch inventory, contract-bearing test evidence, recurring
  actionlint, auditable scan records, external publication evidence, and the
  mandatory bounded consumer completion scan.
- `v0.8.3` corrects the post-publication verifier's repository-root URL after
  the immutable v0.8.2 external run exposed an invalid trailing slash. The
  focused mock now rejects that URL shape.
- `v0.8.4` is the bounded correction for [FIND-0112](../../docs/features/FEAT-0013-v084-correction/README.md#find-0112), [FIND-0113](../../docs/features/FEAT-0013-v084-correction/README.md#find-0113), [FIND-0114](../../docs/features/FEAT-0013-v084-correction/README.md#find-0114), [FIND-0115](../../docs/features/FEAT-0013-v084-correction/README.md#find-0115), [FIND-0116](../../docs/features/FEAT-0013-v084-correction/README.md#find-0116), [FIND-0117](../../docs/features/FEAT-0013-v084-correction/README.md#find-0117), [FIND-0118](../../docs/features/FEAT-0013-v084-correction/README.md#find-0118), [FIND-0119](../../docs/features/FEAT-0013-v084-correction/README.md#find-0119), [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44), [FIND-0121](../../docs/features/FEAT-0013-v084-correction/README.md#find-0121), and [FIND-0122](../../docs/features/FEAT-0013-v084-correction/README.md#find-0122):
  trusted updater preflight, pre-mutation seed validation, recoverable
  completion publication, one exact manifest contract, honest and paginated
  evidence, stable traceability, finding taxonomy, and version boundaries.
  [RISK-0076](../../docs/features/FEAT-0013-v084-correction/README.md#risk-0076) retains the unavailable private-repository `main` protection as a
  maintainer-owned external follow-up tracked by
  [finding issue #44](https://github.com/hasanmanzak/meAndAI/issues/44), with a
  visibility/plan review condition.
- The source-only bootstrap resolver and adapter are intentionally small and
  are not copied to consumers. GitHub Actions does not run an AI agent; an
  explicitly invoked agent or maintainer completes and removes the manifest.
- [FEAT-0002](../../docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md)'s historical post-merge gate was reconciled on 2026-07-15 against
  merged [PR #4](https://github.com/hasanmanzak/meAndAI/pull/4) and remote tag
[`v0.2.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.2.0); this evidence
  correction does not create a new protocol release.
