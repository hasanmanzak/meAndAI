# FEAT-0026 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0119` | [SUBF-0046](README.md), [SUBF-0048](README.md) | Load [MIG-0001](../../../migrations/MIG-0001.json) from the immutable catalog and reconcile the real duplicated-live-pin consumer state first at its original pin and then with the same stale files under a simulated intermediate pin. Exercise a direct version-neutral consumer and rerun every satisfied state. | Applicability depends on exact repository state, never the installed tag. Exactly eight active fragments become version-neutral when legacy; the direct-neutral case changes no unrelated file; dated memory and completed adoption evidence remain byte-identical; every rerun is a no-op; the prospective adoption prompt preserves the same rule. | Integration / compatibility / regression | Passed | `tests/capabilities/consumer-update/consumer-migrations.tests.ps1` and adoption fixtures passed with independent expected-byte and historical sentinels |
| `TEST-0120` | [SUBF-0046](README.md) | Exercise malformed catalog/definition/ledger schema, missing or duplicate IDs, changed or reordered definition blobs, catalog-order drift, path traversal, linked paths, mixed/partial/drifted fragments, unsupported encoding, unrelated dirty state, and an injected later-file write failure. | The pure engine rejects an invalid complete plan before remote mutation; the bounded adapter changes no path outside the exact definition set and restores every original byte array on write failure; ledger state is not advanced. | Unit / integration / negative / atomicity | Passed | Removal/rewrite of an intermediate catalog entry, leaf junction/reparse escape, partial state, and rollback fixtures all failed closed without sentinel drift |
| `TEST-0121` | [SUBF-0047](README.md) | Transition an engine-era consumer across one and several compatible releases, then introduce a newer target while an older proposal is open. Tamper independently with the proposal marker, catalog identity, ordered migrations, definition blobs, changed paths, output blobs, ledger, and plan digest. | One draft contains the exact gitlink, changed updater assets, catalog-derived consumer paths, and target ledger. Skipped migrations run once in order. Replacement is planned from unchanged default-branch state and exact older owned work is cleaned up. Candidate validation and finalization reject every evidence mismatch. | Integration / lifecycle / provenance | Passed | `tests/capabilities/consumer-update/protocol-update.tests.ps1` and `tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` passed, including independent immutable-base recomputation and fabricated output rejection |
| `TEST-0122` | [SUBF-0048](README.md) | Start from more than one immutable pre-engine updater version with no ledger. Merge its ordinary updater-installing proposal, then run the newly installed updater through reconciliation and a later compatible transition. | The old proposal contains only paths its immutable code can prove. The new engine detects capability/ledger absence without a tag-specific branch and creates one same-target reconciliation draft automatically. After that merge, the later transition uses the normal single-draft path and repeated events create no duplicate issue, branch, or pull request. | Integration / legacy handoff / idempotency | Passed | Protocol updater, capability-bootstrap, and quick-adoption lifecycle fixtures passed without a source-tag-specific switch |

## Required coverage

- Immutable `migrations/index.json` and `migrations/MIG-NNNN.json` source and
  Git blob identity.
- Exact append-only catalog and ordered `.ai/meandai-update-state.json`
  satisfied-prefix validation.
- Pure engine with no shell, network, credential, GitHub, commit, push, issue,
  pull-request, or merge authority.
- State-based legacy/satisfied classification independent of the current pin.
- Full-plan computation, exact path containment, UTF-8 BOM and LF/CRLF
  preservation, unrelated-byte preservation, and atomic rollback.
- Project-neutral [MIG-0001](../../../migrations/MIG-0001.json) eight active paths changed; dated memory log, completed
  adoption feature, and historical evidence unchanged.
- One-draft engine-era updates, cumulative skipped migrations, supersession,
  exact marker/issue evidence, candidate validation, and merge finalization.
- Generic pre-engine `MigrationRequired` behavior followed by normal
  single-draft updates.
- Version-neutral adoption prompt and corrected [TEST-0114](../FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md) relationship.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | v0.10.2 baseline | Hosted Ubuntu/Windows and local Windows PowerShell 5.1 | [FEAT-0025](../FEAT-0025-v0102-balanced-windows-validation/README.md) publication gates | Green immutable baseline |
| 2026-07-17 | Generic implementation branch | Windows PowerShell 5.1 | `tests/consumer-migrations.tests.ps1`; `tests/protocol-update.tests.ps1`; `tests/managed-merge-finalization.tests.ps1`; capability-bootstrap and quick-adoption focused suites | Passed; includes cumulative skipped-release, exact one-draft/handoff, independent schema-2 finalizer, and linked-leaf/rollback negatives |
| 2026-07-17 | Converged generic implementation | Local Windows PowerShell 5.1 | `tests/protocol.tests.ps1` | Passed in 531.5 seconds; all discovered child suites and root scenario aggregation passed |
| Pending | Published candidate | Hosted Ubuntu/Windows | Applicable workflow shards | External hosted evidence pending |
