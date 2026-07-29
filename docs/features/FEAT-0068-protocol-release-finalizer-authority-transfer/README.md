# FEAT-0068 - Protocol Release Finalizer and Authority Transfer

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed under accepted architecture; implementation not authorized |
| Target version | 0.17.0 |
| Issue | [#168](https://github.com/hasanmanzak/meAndAI/issues/168) |
| Pull request | Not created; development not authorized |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md), [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md), and [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md) |
| Tests | [TEST-0217](test-cases.md#test-0217), [TEST-0218](test-cases.md#test-0218), and [TEST-0219](test-cases.md#test-0219) |

## Implementation hold

This record owns boundary 6 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
No C# implementation, WIP extraction, release publication, tag change,
trust-anchor mutation, authority transfer, or recovery operation is authorized.

## Problem

A candidate protocol runtime cannot safely certify and publish itself. Package
creation, external publication, fresh-download verification, and trust-anchor
transfer require different evidence and privileges, while interrupted
publication must not be mistaken for active authority.

## Outcome

A least-authority C# release finalizer builds a reviewed release plan, invokes
the predecessor trusted runtime or broker, publishes one immutable protocol
distribution, verifies fresh external assets, and performs a distinct,
journaled, recoverable authority transfer only after every exact predicate is
satisfied.

## Scope

- Reviewed release plan binding source commit, policy catalog, evaluators,
  hosts, schemas, projections, migrations, compatibility declarations,
  manifests, digests, and old/new trust anchors.
- Predecessor-trusted executor/broker selection and candidate shadow
  qualification without circular self-certification.
- Deterministic distribution building and verification over reusable packaging
  primitives.
- Separate least-authority publication, post-publication fresh-download
  verification, and authority-transfer capabilities and grants.
- Publication, verification, handoff, activation, transfer, receipt, journal,
  interruption, compensation, and recovery evidence.
- Idempotent reconciliation when assets exist but verification or transfer is
  incomplete.

## Non-goals

- Governance rule semantics or repository/provider acquisition adapters.
- Adoption or consumer-update planning and mutation.
- Treating a tag, release, uploaded asset, successful candidate self-test, or
  installed assembly as active authority.
- Combining publication and authority-transfer credentials or roles.
- Publishing separate product releases for each process host.

## Readiness evidence

- Dependencies: completed [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md),
  [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md),
  [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md), and
  [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
- WIP input: deterministic packaging, strict manifest/JSON, executor, and
  provenance seeds are classified in the
  [extraction ledger](../../architecture/protocol-governance-and-execution/wip-extraction-ledger.md);
  release planning, publication, verification, transfer, and recovery remain
  new work.
- Existing immutable-release and post-publication evidence remains historical
  prior art; it does not prove this finalizer.
- Verification approach: pure release-plan/envelope tests, deterministic
  cross-OS packaging, local fake registry/provider interruption tests, then one
  separately authorized immutable publication and fresh external verification.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0306` <a name="risk-0306"></a> | A candidate runtime, policy, or package authorizes itself or changes the predicate used to approve it. | Release owner / predecessor-trusted execution, immutable accepted predicate, independent qualification, exact plan, and distinct transfer authority. |
| `RISK-0307` <a name="risk-0307"></a> | Partial publication, stale verification, duplicate delivery, or failed transfer leaves ambiguous active authority. | Transfer owner / separated grants, fresh-download verification, append-only journal and receipts, compare-and-swap anchor transition, idempotent reconciliation, and explicit recovery. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Implementation is not authorized |
| Baseline run | Not run | Expected-red finalizer and provider fixtures do not exist |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0150` <a name="subf-0150"></a> | Reviewed release plan, complete envelope, predecessor-trusted execution, deterministic build, and least-authority publication | [#168](https://github.com/hasanmanzak/meAndAI/issues/168) | [TEST-0217](test-cases.md#test-0217) / not started | Pending | Proposed |
| `SUBF-0151` <a name="subf-0151"></a> | Fresh post-publication verification, handoff, distinct authority transfer, reconciliation, and recovery | [#168](https://github.com/hasanmanzak/meAndAI/issues/168) | [TEST-0218](test-cases.md#test-0218), [TEST-0219](test-cases.md#test-0219) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md), [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md), [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md), and [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
- Later application artifacts: [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md) and [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md) enter one protocol distribution only after their own qualification.

## Definition of Ready

- [x] Stable ID, linked issue, accepted decision, problem, outcome, scope, non-goals, dependencies, risks, and reviewable decomposition.
- [x] Numbered planning scenarios and exact packaging/provenance WIP disposition.
- [ ] Exact release-envelope, predecessor-broker, publication-provider, trust-anchor, and recovery schemas for the selected slice.
- [ ] Expected-red circularity, tamper, interruption, replay, and transfer fixtures.
- [ ] Gate 2 security and authority-boundary review.
- [ ] Separate maintainer implementation directive.

## Acceptance criteria

1. One reviewed release plan binds every shipped component and accepted predicate to exact source, digest, schema, transition, compatibility, and old/new authority identities.
2. The candidate cannot be the sole executor, verifier, or authority for its own publication and transfer.
3. Distribution bytes and manifests are deterministic, strict, complete, tamper-evident, and freshly verified after external publication.
4. Publish, verify, and transfer are separate least-authority operations with fresh exact grants and durable receipts.
5. Asset or tag presence never implies active authority; the trust anchor moves only through the accepted compare-and-swap transfer predicate.
6. Every interrupted or duplicate path reconstructs deterministically as complete, no-op, or recovery-required without automatic fallback.
7. The result remains one protocol distribution with shared libraries and least-authority thin hosts, not separate CLI products.

## Definition of Done

All implementation, expected-red, review, exact-head and cross-OS test,
publication, fresh-download verification, authority-transfer, documentation,
and external evidence gates remain pending.
