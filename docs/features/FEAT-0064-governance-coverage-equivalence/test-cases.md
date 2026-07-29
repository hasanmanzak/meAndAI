# FEAT-0064 Test Scenarios

Test implementation: [FEAT-0064](README.md) is records-only and development is
not authorized.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0196` <a name="test-0196"></a> | [SUBF-0136](README.md#subf-0136) | Compare one captured input across the independently implemented C# engine and every applicable canonical PowerShell scenario plus declared positive/negative variant. | Each row has exactly one evidenced disposition; missing, duplicate, divergent, or unproved stronger evidence blocks equivalence and stronger-evidence claims, required-check enforcement, authority transfer, and retirement. It does not block an explicitly non-authoritative package whose partial coverage is declared. Only an immutable exact-pair artifact can become eligible for persistent managed consumer use or future required-check consideration, and artifact eligibility alone does not grant equivalence, enforcement, or authority. | Differential / compatibility / authority | Nearest sibling: [TEST-0145](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0145); `Distinct` because this scenario owns same-snapshot semantic equivalence and authority eligibility rather than runtime-efficiency evidence. | Planned | Future differential harness |

## Required coverage

- Every applicable supported base identity and material positive/negative
  variant.
- Exact same-snapshot C# and PowerShell observations.
- Missing, duplicate, divergent, retained, not-applicable, infrastructure,
  provider, and stronger-evidence dispositions.
- Catalog, policy, application, artifact, profile, snapshot, and authority
  identity binding.
- Fail-closed behavior before required-check eligibility, authority transfer,
  compatibility retirement, or source retirement.

## Evidence

No executable evidence exists. The historical
[FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md)
[differential inventory](../FEAT-0060-any-consumer-governance-cli/differential-ledger-analysis.md)
and
[rule/profile matrix](../FEAT-0060-any-consumer-governance-cli/rule-profile-matrix-analysis.md)
are records-only inputs, not equivalence proof.
