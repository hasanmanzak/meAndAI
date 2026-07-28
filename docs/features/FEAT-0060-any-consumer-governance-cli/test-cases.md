# FEAT-0060 Test Scenarios

Test implementation: [SUBF-0138](README.md#subf-0138) is complete with
exact-head hosted evidence; the six remaining bounded-MVP subfeatures are
pending.

## Authorized bounded clean-room catalog

The first compiled C# vertical slice is [SUBF-0138](README.md#subf-0138) and
reuses canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
rather than allocating another numbered scenario. For the explicit
`protocol-authority` profile, a conforming fixture contains `README.md` and
`test-cases.md` in every `FEAT-NNNN-*` directory; a fixture missing either file
produces the deterministic nonconforming result for that canonical rule.

The slice is repository-read-only, provider-free, `CSharpShadow`, and
non-authoritative. Its test first failed to compile because the governance
domain/core types did not exist, then passed the conforming and each
missing-file boundary after the smallest coherent implementation. PowerShell
source was not inspected or translated to design the rule; later differential
work may compare the independently produced results as black-box observations.

The next rule reuses canonical
[TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005).
It validates the decision-record identity, classification, status, and exact
required sections through the same repository/document indexes as
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004);
it does not allocate a language-specific test identity or a second parser.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0194` <a name="test-0194"></a> | [SUBF-0122](README.md#subf-0122), [SUBF-0123](README.md#subf-0123), and [SUBF-0135](README.md#subf-0135) | Build a closed exact-commit governance request, resolve explicit `protocol-authority` and canonical gitlink `consumer` profiles, and bind one exact application/policy pair from canonical evidence. | Exactly one caller-selected profile, 40-character commit, catalog, and application/policy pair are independently verified; unknown, ambiguous, range-inferred, mismatched, drifting, unsafe, candidate-overlay, or unsupported repository-reference state fails closed. An exact-bound unreleased bundle may inspect only as read-only `CSharpShadow`. Persistent managed use requires the immutable package and still grants neither mutation nor primary authority. | Contract / Git / integration / security | `Distinct`; see the exact sibling tuple below. Existing canonical-byte selection remains owned by [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171). | Planned | Future .NET tests |
| `TEST-0195` <a name="test-0195"></a> | [SUBF-0124](README.md#subf-0124), [SUBF-0134](README.md#subf-0134), and [SUBF-0135](README.md#subf-0135) | Serialize conforming, nonconforming, incomplete, rejected, failed, canceled, redacted, reordered, and cross-platform governance outcomes. | One typed report/process contract preserves canonical rule ownership, independent severity/enforcement, deterministic bytes, redaction, and the distinction between execution outcome and governance verdict. Current canonical violations remain blocking, advisory observations do not fail the verdict, caller downgrade is rejected, and missing canonical metadata yields `incomplete`. | Unit / contract / security | `Distinct`; see the exact sibling tuple below. Existing rule semantics retain their canonical `TEST-*` identities. | Planned | Future .NET tests |

[SUBF-0138](README.md#subf-0138) contributes bounded implementation experience
to the future request/report design, but it does not activate or pass
[TEST-0194](#test-0194) or [TEST-0195](#test-0195). Both remain canonical
`PlannedDocumentation` scenarios with literal `Planned` status and no active
C# source ownership.

## Distinct-intent review

| Scenario | Nearest same-contract sibling | Contract difference | Risk difference | Evidence-level difference | Exercised-boundary difference |
| --- | --- | --- | --- | --- | --- |
| Profile/request scenario | [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) and [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) | Owns the closed compiled request and explicit profile-resolution result; byte-source precedence and graph discovery remain with their existing owners. | Prevents named-repository, automatic-profile, or caller-supplied-policy authority rather than only selecting canonical bytes or graph nodes. | Compiled contract plus Git integration over project-neutral authority/consumer fixtures. | Request composition and profile verification around, not inside, the canonical snapshot and graph contracts. |
| Report-envelope scenario | [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192) | Owns the governance finding/report/process envelope; the foundation scenario owns closed operation results and port failures. | Prevents a false green, nondeterministic/redaction-unsafe report, or collapsed verdict/outcome state. | Byte-deterministic compiled serialization and security evidence. | Public governance report boundary after canonical rule evaluation. |

The relationship for both rows is `Distinct` under
[DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md).
Porting an existing rule or snapshot behavior to C# does not allocate another
numbered scenario; the existing identity is cited by the differential ledger.

Canonical [TEST-0196](../FEAT-0064-governance-coverage-equivalence/test-cases.md#test-0196)
and its distinct-intent review moved to
[FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md). This link
is navigation only;
FEAT-0060 no longer declares that scenario.

## Evidence

[SUBF-0138](README.md#subf-0138) local test-first evidence, from the repository
root on 2026-07-28:

- `dotnet test tests/dotnet/MeAndAI.Operations.Governance.Tests/MeAndAI.Operations.Governance.Tests.csproj --no-restore --configuration Release`
  first failed to compile in 7.9 seconds because the new domain/core types were
  absent. The same command first passed 12/12 in 6.1 seconds after production
  implementation. Fresh review then added wrong-case filename and fail-closed
  root, feature-directory, required-file, exact `docs` / `docs/features`
  dangling/non-directory link, and drive-relative `C:outside` cases; the final
  focused command passed 28/28 in 5.5 seconds.
- `dotnet test tests/dotnet/MeAndAI.Operations.Architecture.Tests/MeAndAI.Operations.Architecture.Tests.csproj --configuration Release --no-restore`
  passed 31/31 in 4.7 seconds after correcting one expected dependency-order
  assertion to the canonical solution order.
- `dotnet restore MeAndAI.Operations.slnx --locked-mode` passed in 2.5 seconds.
- `dotnet test MeAndAI.Operations.slnx --configuration Release --no-restore`
  finally passed governance 28/28, architecture 31/31, and packaging 17/17 in
  6.4 seconds. Report contracts distinguish
  `evidenceDigest` from `catalogMetadataDigest`, declare
  `coverage=bounded-first-slice`, and centralize repository-relative finding
  paths.
- `dotnet format MeAndAI.Operations.slnx --verify-no-changes --no-restore`
  passed in 14.1 seconds.
- The first PowerShell 7 `tests/protocol.tests.ps1 -StructureOnly` run exposed
  15 canonical
  [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  link defects only in the new records. After canonical-target corrections,
  final PowerShell 7 and Windows PowerShell 5.1 `StructureOnly` passed in
  159.3 and 236.9 seconds.
- `dotnet publish src/MeAndAI.Operations.Governance/MeAndAI.Operations.Governance.csproj --configuration Release --no-restore --output .codex-tmp/feat0060-first-slice/publish`
  passed in 2.5 seconds and produced the portable framework-dependent output
  without an apphost.
- `dotnet .codex-tmp/feat0060-first-slice/publish/MeAndAI.Operations.Governance.dll validate --repository . --profile protocol-authority`
  completed in 0.5 seconds with exit `0`, `conforming`, one evaluated rule,
  zero findings, `csharp-shadow`, `powershell-authority`, deterministic digest,
  and no absolute path in the report.

This evidence completes the canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004)
C# vertical slice. It does not activate [TEST-0194](#test-0194) or
[TEST-0195](#test-0195), which remain `Planned`. Exact head
[`393aaa561d0133aba7522083617564e1dca76fe2`](https://github.com/hasanmanzak/meAndAI/commit/393aaa561d0133aba7522083617564e1dca76fe2)
passed hosted [run `30394623671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30394623671)
on Ubuntu and Windows. Exact-commit package behavior remains pending. The historical
[differential-ledger inventory](differential-ledger-analysis.md),
[rule/profile matrix](rule-profile-matrix-analysis.md), and
[accepted v1 decision packet](contract-decision-packet.md) refine later
equivalence boundaries without claiming executable completion. The accepted pre-change baseline is exact-head
[run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744),
exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671),
and post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375).
The final pre-slice exact head
[`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186)
passed [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016)
on Ubuntu and Windows.
