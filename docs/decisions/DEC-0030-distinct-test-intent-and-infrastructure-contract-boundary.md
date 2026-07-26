# DEC-0030 - Require Distinct Test Intent and Direct Infrastructure Contracts

- Classification: Decision
- Status: Accepted
- Date: 2026-07-26
- Decision owners: meAndAI maintainer and protocol contributors
- Related feature: [FEAT-0053](../features/FEAT-0053-v0152-distinct-test-intent/README.md)
- Related decisions: [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md) and [DEC-0029](DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)

## Context

[DEC-0029](DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
establishes one canonical owner for generic test mechanics, exact runtime
scenario identity, and non-overlapping runner, harness, case, support, fixture,
and mock roles. Those controls prevent duplicate technical identities and
helper owners, but two different numbered scenarios can still restate the same
behavioral contract under different names.

The repository also needs to distinguish a legitimate direct test of test
infrastructure from a redundant validator whose only oracle is another test's
source or successful result. A universal semantic detector would be both
unreliable and contrary to the bounded validation model.

The released `test-harness-modularity` capability definition is immutable under
[DEC-0022](DEC-0022-release-declared-semantic-capabilities.md). This decision
therefore clarifies the prospective protocol and review contract without
mutating that released definition or invalidating an earlier terminal consumer
assessment.

## Decision

1. One behavioral contract has one canonical scenario family. Before adding or
   changing a numbered scenario, the author identifies its nearest
   same-contract sibling and reviews the tuple `contract`, `risk`, `evidence
   level`, and `exercised boundary`.
2. The reviewed relationship is exactly one of `Distinct`,
   `ParameterizedVariant`, `InfrastructureContract`, or
   `SupersededDuplicate`.
3. Separate active test identities are justified only by a materially distinct
   tuple member. A new fixture name, assertion style, or implementation route
   alone is insufficient. Ordinary input variants use one parameterized case
   or canonical scenario family when feasible.
4. A canonical suite does not invoke another canonical suite and does not use
   another test's source text, numbered-test constant, assertion wording, pass
   marker, or green result as proof of product behavior. Suite dispatch and
   exact execution aggregation remain owned by the existing root runner and
   scenario-evidence authority.
5. A direct infrastructure-contract test is legitimate when discovery,
   ownership, role, evidence, or lifecycle behavior is itself the contract
   under test. It has one canonical owner, uses synthetic or inert
   positive/negative inputs, asserts only that infrastructure invariant, and
   does not reassert another capability's product outcome.
6. No scenario requires a second scenario merely to prove that it exists or
   ran. Missing, duplicate, unexpected, failed, or unexecuted evidence remains
   the responsibility of the existing exact runtime-evidence contract.
7. The active portfolio is reviewed once through the existing executable-owner
   inventory. The feature record stores the finite disposition ledger; no
   second permanent scenario registry or semantic clone detector is created.
8. The clarification applies prospectively when a repository adopts the
   protocol release containing it and then adds or changes a numbered scenario.
   The immutable `test-harness-modularity` definition and terminal assessments
   for earlier releases remain byte-identical and valid.

## Consequences

- Scenario intent becomes reviewable without pretending semantic equivalence is
  mechanically decidable.
- Distinct security, recovery, integration, supported-runtime, and state
  boundaries remain separate evidence when their reviewed tuples differ.
- Legitimate framework-contract tests remain possible, while test-of-test
  chains and cross-suite execution ownership are prohibited.
- Feature and test templates carry the prospective review fields. The existing
  role-boundary suite owns one bounded structural and negative contract test.
- Existing capability definitions, consumer ledgers, runners, workflows, and
  scenario identities remain compatible.

## Alternatives considered

- Build a semantic clone detector: rejected because source similarity cannot
  establish behavioral equivalence and would create false positives and a new
  validator framework.
- Prohibit every test that inspects test infrastructure: rejected because
  discovery, authority, evidence, and role boundaries are real infrastructure
  contracts that require direct regression evidence.
- Add a verifier for every numbered scenario: rejected because it creates the
  validator chain this protocol explicitly prohibits.
- Rewrite or append a semantic capability solely for this clarification:
  rejected because the rule is prospective, the released definition is
  immutable, and no consumer ledger migration is required.
- Fold the policy into runtime optimization: rejected because semantic
  correctness and elapsed-time reduction have different owners and evidence.

## Review condition

Review this decision if two materially distinct evidence boundaries cannot be
represented by the intent tuple, if a legitimate infrastructure contract
requires another test's result as its only oracle, if enforcement requires a
second registry or broad source analysis, or if the clarification must change
already-terminal consumer capability assessments.
