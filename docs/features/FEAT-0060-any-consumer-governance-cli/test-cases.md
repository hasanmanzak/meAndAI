# FEAT-0060 Test Scenarios

Test implementation: not started; development is not authorized.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0194` <a name="test-0194"></a> | [SUBF-0122](README.md#subf-0122), [SUBF-0123](README.md#subf-0123), and [SUBF-0135](README.md#subf-0135) | Build a closed governance request, capture permitted repository states, and resolve explicit `protocol-authority` and `consumer` profiles from canonical evidence. | Exactly one caller-selected profile is independently verified; unknown, ambiguous, mismatched, drifting, or unsafe repository state fails closed without writes. | Contract / Git / integration / security | `Distinct`; see the exact sibling tuple below. Existing snapshot byte precedence remains owned by [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171). | Planned | Future .NET tests |
| `TEST-0195` <a name="test-0195"></a> | [SUBF-0124](README.md#subf-0124), [SUBF-0134](README.md#subf-0134), and [SUBF-0135](README.md#subf-0135) | Serialize conforming, nonconforming, incomplete, rejected, failed, canceled, redacted, reordered, and cross-platform governance outcomes. | One typed report/process contract preserves canonical rule ownership and severity, deterministic bytes, redaction, and the distinction between execution outcome and governance verdict. | Unit / contract / security | `Distinct`; see the exact sibling tuple below. Existing rule semantics retain their canonical `TEST-*` identities. | Planned | Future .NET tests |
| `TEST-0196` <a name="test-0196"></a> | [SUBF-0136](README.md#subf-0136) and [SUBF-0137](README.md#subf-0137) | Compare one captured input across the C# engine and every applicable canonical PowerShell scenario plus declared positive/negative variant. | Each row has exactly one evidenced disposition; missing, duplicate, divergent, or unproved stronger evidence blocks `CSharpReleasedNonAuthoritative` qualification and every authority transfer. | Differential / compatibility / release | `Distinct`; see the exact sibling tuple below. | Planned | Future differential harness |

## Distinct-intent review

| Scenario | Nearest same-contract sibling | Contract difference | Risk difference | Evidence-level difference | Exercised-boundary difference |
| --- | --- | --- | --- | --- | --- |
| Profile/request scenario | [TEST-0171](../FEAT-0045-v0140-canonical-repository-evidence/test-cases.md#test-0171) and [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) | Owns the closed compiled request and explicit profile-resolution result; byte-source precedence and graph discovery remain with their existing owners. | Prevents named-repository, automatic-profile, or caller-supplied-policy authority rather than only selecting canonical bytes or graph nodes. | Compiled contract plus Git integration over project-neutral authority/consumer fixtures. | Request composition and profile verification around, not inside, the canonical snapshot and graph contracts. |
| Report-envelope scenario | [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192) | Owns the governance finding/report/process envelope; the foundation scenario owns closed operation results and port failures. | Prevents a false green, nondeterministic/redaction-unsafe report, or collapsed verdict/outcome state. | Byte-deterministic compiled serialization and security evidence. | Public governance report boundary after canonical rule evaluation. |
| Differential-authority scenario | [TEST-0145](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0145) | Owns finite cross-language scenario/variant disposition and release qualification; the sibling owns runtime-efficiency evidence. | Prevents silent semantic omission or premature authority transfer rather than runtime-cost regression. | Same-snapshot differential plus immutable-package qualification. | Authority ledger and qualification gate, not runner scheduling or elapsed performance. |

The relationship for all three rows is `Distinct` under
[DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md).
Porting an existing rule or snapshot behavior to C# does not allocate another
numbered scenario; the existing identity is cited by the differential ledger.

## Evidence

No feature implementation or executable scenario evidence exists; all three
scenarios remain planning records. The accepted pre-change baseline is exact-head
[run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744),
exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671),
and post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375).
