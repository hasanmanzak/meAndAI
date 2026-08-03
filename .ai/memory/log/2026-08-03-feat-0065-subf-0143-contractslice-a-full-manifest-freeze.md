# ContractSlice A full-manifest frozen-design handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-03 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| State | `A-FULL-MANIFEST-01` `FrozenDesign`; renewed records-only review is `0 Blocking / 0 Important / 0 Minor`; inactive until records-only commit/push and exact-head hosted validation close |
| Activation base | Exact projector record-sync successor [`e05671d8d977abaf33b86eddddfdbf3d36e4274b`](https://github.com/hasanmanzak/meAndAI/commit/e05671d8d977abaf33b86eddddfdbf3d36e4274b), git tree identity `9b9026ce5de5b974653988b644c752796b656e38`, passed Windows and Ubuntu in [run 30803483210](https://github.com/hasanmanzak/meAndAI/actions/runs/30803483210); publication verification was skipped as expected |
| Progress | Thirteen of twenty live packets are `ReviewedLocalGreen` (`65%`); cumulative A is `26/26`; the parent scenario remains `Planned` |
| Routing correction | Never-activated `A-CONVERGE-01` retires and is excluded from the denominator; `A-FULL-MANIFEST-01` replaces it one-for-one. `A-CONVERGE-02` remains the no-new-Fact final A audit. |

## Owned semantic correction

- The accepted five-rule snapshot cannot currently reach Writer/Reader. `CatalogSliceDeclaration` assumes one rule, four evaluation-slot occurrences, two selectors, two findings, and one shared admission contract identity. The accepted manifest has five rules, twelve slot occurrences over four structurally equal reusable slots, three selectors, sixteen findings, and three distinct admission contract identities.
- Green generalizes closure without hard-coding the initial catalog counts: canonical rules still require byte-for-byte structural equality for a repeated SlotKey; schema/parser/index/projector closure uses exact SlotKey lookup over structurally unique slots rather than flattened occurrence positions; applicability and evaluation slot sets remain separate. Admission closure requires all three kinds, three distinct proof components, and exact surfaces/material roles derived from the complete slot union, but imposes no admission contract-key cardinality and no zero-applicability rule.
- Initial-catalog exactness remains test-owned. Production does not hard-code five rules, twelve occurrences, three selectors, sixteen findings, twenty-seven logical rows, thirty-five component rows, or six artifacts.
- Exact proof identities are frozen as activation contract/component `protocol.activation.release-envelope` / `protocol.activation-proof.release-envelope` and admission contract/component pairs `protocol.admission.observed` / `protocol.admission-proof.observed`, `protocol.admission.failed` / `protocol.admission-proof.failed`, and `protocol.admission.no-input` / `protocol.admission-proof.no-input`; every component version is `1`.
- The six-artifact snapshot is declaration topology only. Deterministic test sentinel lengths/digests bind manifest rows; A does not load CLR types, hash first-party binaries, construct an executable export, invoke activation proof, or prove typed registrations.

## P/R/G and exact oracle

- `P=NotApplicable`. After one locked restore, unchanged-source evidence is exactly projector focused `1/1` and cumulative A `26/26`; all six lock fingerprints remain equal.
- R owns exact marker and TRX stem `TEST-0210-A-BEHAVIOR-RED-0011` and one exact Fact/FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceAFullManifestGraphTests.Full_declaration_graph_equals_the_exact_five_rule_six_artifact_thirty_five_component_snapshot`. Its only trait is `ContractSlice=A`; no `Scenario` exists.
- R constructs the registry, rules, artifacts, components, successful `CatalogSliceDeclaration.Create` result, and validation-free `ParsedCanonicalManifest` outside the guard. The sole guarded missing-behavior call is `CanonicalManifestWriter.Write(parsed)`. Only exact runtime type `ArgumentException`, parameter `rules`, and message equal to `new ArgumentException("Admission-proof contracts require the exact selector topology.", "rules").Message` may execute the sole direct `Assert.Fail(exactMarker)`. Setup, type/message mismatch, Reader, and all other failures remain marker-free. R runs once and is never rerun. The TRX contains the marker only in the sole failed result ErrorInfo/Message plus at most one byte-identical summary echo; permitted stack and RunInfo are marker-free, and no other result, diagnostic, or attachment contains it.
- Green removes the transient marker/catch, applies only the bounded generic closure correction, constructs the exact manifest, and proves Writer -> Reader -> Writer byte identity plus digest and typed projections. Focused green must be `1/1`; cumulative A must be `27/27`.
- The positive oracle freezes five ordered rules, ten normative fragments, registry `3/2/4/1`, zero applicability occurrences, four distinct slots with twelve occurrences distributed `2/4/3/3`, three selectors, sixteen findings distributed `2/2/4/4/4`, three admission proofs, the exact cache and declaration budgets/failure codes, twenty-seven logical Policy rows, four runtime anchors, one activation proof, three admission proofs, thirty-five components, and six artifacts.
- The Fact compares exact ordered projections, partition disjointness, exact component-key-to-artifact bindings, the named distribution Policy `23`, Conformance.Abstractions `5`, Application `4`, Domain `1`, Conformance `1`, and Markdig `1`, producer roots/reachability, and every-artifact-used closure. Its bounded closure negatives prove structurally equal repeated SlotKeys are accepted, a divergent repeated SlotKey is rejected, a missing admission kind is rejected, a reused proof component is rejected, and derived surface/material-role mismatch is rejected; shared admission contract keys across kinds remain valid. It does not consume sibling test results or duplicate their wire mutation matrices.

## Allowlist, caps, and holds

- Production allowlist is only `src/MeAndAI.Protocol.Conformance.Abstractions/Catalog/CatalogSliceDeclaration.cs`; target gross delta is `40-60`, hard cap `80`.
- Test allowlist is only `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceAFullManifestGraphTests.cs`; target is `450-550` lines, hard cap `620`. Combined hard cap is `700`; any larger result redraws before acceptance.
- Exactly one new Fact is allowed. No project, solution, package, lock, workflow, public/friend API, sibling test, or other production file changes.
- Final verification requires focused and cumulative greens, full Domain and Conformance suites, zero-warning/error Release build, default-severity format, unchanged locks, clean diff, StructureOnly, the bounded publication-evidence suite without a published-state claim, and independent code/evidence/record review.
- Later A packets, B/C/D, final scenario/status/owner/workflow/efficiency activation, merge, release, publication, consumer mutation, WIP extraction, authority transfer, and PowerShell retirement remain held.

## Review disposition

- Pre-freeze red-team exposed two Blocking, two Important, and one Minor issue: the current production single-rule closure, undefined proof component keys, insufficient count-only oracle, missing caps/matrix, and ambiguous FQN. The corrected route then exposed Writer-seam, generic-contract-cardinality, slot-lookup, marker-purity, activation-base, and ledger issues. After the Writer-first and generic-closure corrections above, renewed independent code/design, evidence/gate, and records/link-graph reviews each closed `0 Blocking / 0 Important / 0 Minor`.
- No implementation is active and no completion claim is made.
