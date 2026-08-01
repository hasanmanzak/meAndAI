# ContractSlice A parser-record-slot activation handoff

- Date: 2026-08-01
- Branch: `codex/subf-0143-contract-slice-a-implementation`
- Pull request: draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174)
- Parent: [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
- State: `A-PARSER-RECORD-SLOT-01` `MaintainerActivated / PreRed`

## Exact predecessor and closure

- Remote-equal commit: [`25e26f908e1f123640c758e42e1db92d5eea6dde`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde)
- Git tree identity: `9a0dc5bb9b41c9509366ab92bc7de642724938b6`
- Hosted evidence: [run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833) passed Ubuntu and Windows; publication verification was correctly skipped; the [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) suite reports GitGuardian green.
- [FIND-0445](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0445) and [FIND-0446](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0446) are `Resolved`.
- Historical index-slot evidence remains immutable in the [index-slot handoff](2026-08-01-feat-0065-subf-0143-contractslice-a-index-slot.md).

## Strict redraw

- Never-activated `A-PARSER-INDEX-01` is `RetiredBeforeActivation`: a non-live, terminal, non-reactivatable routing tombstone with no FQN, marker, ordinal, R, G, or V.
- Live denominator: `18 - 1 + 3 = 20`; six packets remain `ReviewedLocalGreen`, so progress is `6/20 = 30%`. This is a denominator correction, not a delivery regression.
- `A-PARSER-RECORD-SLOT-01`: `MaintainerActivated / PreRed`; D/RT `0 Blocking / 0 Important / 0 Minor`.
- `A-GOVERNED-REFERENCE-SLOTS-01`: Candidate; FQN/marker/ordinal `None`.
- `A-TARGET-PARSER-INDEX-SLOT-01`: Candidate; FQN/marker/ordinal `None`.
- [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned`; cumulative A remains the historical `19/19` until this packet reaches green.

## Frozen contract

- FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceAParserRecordSlotManifestTests.Enforces_exact_markdown_parser_protocol_record_index_and_slot_capability_closure`
- Marker/TRX: `TEST-0210-A-BEHAVIOR-RED-0005`
- Natural R: exact `InvalidOperationException` / `This writer increment supports only the minimal qualification slice.` Writer runs first; only that exact catch may call `Assert.Fail(marker)`.
- Canonical order: schemas governed-text then repository-tree; parser Markdown; indexes protocol-record then repository-tree; slots repository-governed-text then repository-tree.
- The repository-governed-text slot is a test-owned partial qualification-slice fixture with only protocol-record-index capability. Provider-governed-text and governed-reference remain rejected for the next packet.
- Exact cumulative cache: `(512,67108864,128,2000000,8,4,retain-lowest-canonical-keys)`.
- Partial closure counts: schemas `2`, parsers `1`, indexes `2`, slots `2`, demand `0`, admission `0`.
- The index-slot fixture is preserved for every non-owned field; only governed schema/parser/record-index/component/artifact/slot/cache additions are permitted.

## Allowlist, budgets, and gates

- Production: `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`, `CatalogSliceDeclaration.cs`.
- Test: new `ContractSliceAParserRecordSlotManifestTests.cs` only.
- Reader `120-145`; writer `55-70`; Catalog `80-105`; production target `270-300`, redraw above `310`; test target `350-380`, stop above `380`; combined hard ceiling `690`.
- One locked restore; unchanged six lock fingerprints. P is `NotApplicable`; predecessor index-slot must pass `1/1`, cumulative A `19/19`.
- R is one exact-FQN invocation in a fresh external directory with `VSTEST_CONNECTION_TIMEOUT=300`, outer timeout `420` seconds, `--no-restore --no-build`, one TRX, and exactly one failed result. Valid R is never rerun.
- Green requires focused `1/1`, cumulative A `20/20`, zero-warning/error Release build, format/diff/lock/marker checks, fresh code/test review, record review, commit/push, and exact-head hosted green.

## Held scope and next action

- Only `ContractSlice=A`; no `Scenario` trait. Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D, merge, release, and publication remain held.
- Project/solution/package/lock/workflow changes, public API changes, provider/governed-reference/target/projector/admission/export work, and historical handoff edits are prohibited.
- Next: synchronize and review this activation cohort, then add the transient test, prove predecessor green, and execute the single canonical expected-red.
