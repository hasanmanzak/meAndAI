# FEAT-0004 - Self-Updating Consumer Updater

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.4.0 |
| Issue | [#15](https://github.com/hasanmanzak/meAndAI/issues/15) |
| Pull request | [#16](https://github.com/hasanmanzak/meAndAI/pull/16) |
| Decision | [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md) |
| Tests | [Test scenarios](test-cases.md) |
| Successor | [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md) adds workflow-seeded adoption while preserving this updater |

## Problem

Consumer repositories copy the updater workflow and scripts during adoption,
but the updater delivered through `v0.3.2` changes only the `.ai/protocol`
gitlink. The copied updater therefore cannot receive later fixes automatically.
Writing its own workflow file also requires a consumer credential with explicit
`Workflows` permission, which is outside the current `GITHUB_TOKEN` contract.

## Outcome

After one reviewed `v0.4.0` migration, each compatible protocol proposal uses a
consumer-scoped fine-grained personal access token and updates the protocol
pointer together with the deterministic subset of three managed updater assets
that changed in the target release. Current consumer copies are verified
against the pinned release before mutation, so customization or drift stops for
manual review instead of being overwritten.

## Scope

- Introduce `MEANDAI_UPDATER_TOKEN` as the consumer mutation credential while
  keeping private-source reads separate through `MEANDAI_PROTOCOL_TOKEN`.
- Resolve the trusted pull-request actor from the authenticated updater token.
- Reduce the job `GITHUB_TOKEN` to read-only use.
- Reconcile the canonical workflow and two updater scripts from the exact
  target release commit.
- Require exact current-template equality, expected changed paths, target blob
  content, and existing live ownership gates before creation or cleanup.
- Preserve draft-only, same-major, replacement-first supersession, Git leases,
  and reopen compensation.
- Document the one-time transition for pre-`v0.4.0` consumers.

## Non-goals

- A GitHub App, hosted token broker, webhook service, or central credential
  distribution.
- Automatic approval, merge, or incompatible-major migration.
- Overwriting consumer-customized updater files.
- Making the `meAndAI` repository public in this feature.
- Replacing the existing resolver, marker, lease, or compensation architecture.

## Managed contracts

The write credential is a fine-grained PAT named
`meAndAI Updater - <repo>` and stored only as the consumer Actions
secret `MEANDAI_UPDATER_TOKEN`. It selects only that consumer repository and has
`Contents`, `Pull requests`, and `Workflows` read/write permission; `Metadata`
read access is implicit. Expiry, revocation, permission loss, or actor rotation
stops mutation and requires consumer-maintainer action.

The managed consumer paths are exactly:

1. `.ai/protocol`;
2. `.github/workflows/meandai-protocol-update.yml`;
3. `.github/scripts/MeAndAI.ProtocolUpdate.psm1`; and
4. `.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1`.

The gitlink is always changed for an upgrade. An updater asset appears in the
proposal only when its target-release blob differs from the current pinned
template. Candidate validation compares the pull request with that exact
expected set and verifies target blob identity; an allowlist alone is
insufficient.

## Readiness evidence

- Domain and boundaries: source-read and consumer-write credentials have
  separate ownership and permission semantics; the updater receives only
  `GH_TOKEN`, while workflow wiring selects the credential implementation.
- Consumers and compatibility: new `v0.4.0` adopters receive the complete
  contract. Earlier exact pins remain valid, but their copied updater needs
  one reviewed migration because old code cannot retroactively update itself.
- Error behavior: absent credentials, identity ambiguity, current-asset drift,
  missing target blobs, and unexpected paths fail before destructive cleanup.
- Verification: numbered structural, resolver, adapter, migration, AST, link,
  and cross-platform CI checks plus the bounded feature review.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0017` | Availability | PAT expiry, revocation, or permission loss interrupts updates | Managed; consumer admin | Explicit prerequisite, fail-closed validation, and documented rotation |
| `RISK-0018` | Identity | PAT activity shares its human owner's GitHub identity | Accepted; consumer admin | Runtime `/user` resolution, exact candidate invariants, and App reconsideration trigger in [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md) |
| `RISK-0019` | Integrity | Automatic reconciliation overwrites consumer customization | Mitigated; maintainers | All current managed assets must equal the pinned templates before mutation |
| `RISK-0020` | Migration | Pre-v0.4 updater cannot bootstrap this capability | Accepted transition; maintainers | One-time reviewed migration with no automatic ownership transfer |
| `RISK-0021` | Credential scope | Workflow-write credential can change executable automation | Mitigated; consumer admin | One-repository selection, minimum permissions, secret isolation, draft-only output, and branch review |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0022](test-cases.md), [TEST-0023](test-cases.md), [TEST-0024](test-cases.md), [TEST-0025](test-cases.md), and [TEST-0026](test-cases.md) |
| Test code | Green | [TEST-0022](test-cases.md), [TEST-0023](test-cases.md), [TEST-0024](test-cases.md), [TEST-0025](test-cases.md), and [TEST-0026](test-cases.md) pass in the repository suite |
| Baseline run | Passed | Windows PowerShell 5.1 repository suite on 2026-07-15 before feature changes |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0007` | Fine-grained PAT and authenticated-actor boundary | [Issue #15](https://github.com/hasanmanzak/meAndAI/issues/15) | [TEST-0022](test-cases.md), [TEST-0023](test-cases.md); red/green evidence recorded | Fresh-diff review complete; no unresolved finding | Complete |
| `SUBF-0008` | Deterministic updater-asset reconciliation and migration | [Issue #15](https://github.com/hasanmanzak/meAndAI/issues/15) | [TEST-0024](test-cases.md), [TEST-0025](test-cases.md), and [TEST-0026](test-cases.md); red/green evidence recorded | Fresh-diff review complete; `FIND-0051` resolved | Complete |

## Decisions and relationships

- Decision: [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md)
- Predecessor feature: [FEAT-0002](../FEAT-0002-semi-automatic-consumer-updates/README.md)
- Preserved decision: [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Adoption guide: [Consumer adoption](../../adoption.md)
- Tracking: [issue #15](https://github.com/hasanmanzak/meAndAI/issues/15)
- Delivery: [pull request #16](https://github.com/hasanmanzak/meAndAI/pull/16)

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Credential, actor, path, blob, lifecycle, failure, consumer, and
  compatibility contracts identified.
- [x] Numbered risks and [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md).
- [x] Two independently reviewable slices with a gate ledger.
- [x] Numbered test scenarios and verification approach.
- [x] Test-code next state and successful pre-change baseline recorded.

## Acceptance criteria

1. Consumer mutations use only `MEANDAI_UPDATER_TOKEN`; the workflow's own
   `GITHUB_TOKEN` has no write permission.
2. `MEANDAI_PROTOCOL_TOKEN` is a separate read-only private-source credential
   and public protocol sources can use the read-only workflow token.
3. The trusted proposal actor is derived from the updater token, and ambiguous
   or rotated ownership blocks automatic cleanup.
4. Current consumer updater assets must exactly match the pinned release before
   any branch or pull-request mutation.
5. A proposal changes only the gitlink plus the exact target-different updater
   assets, whose modes and blobs match the target release.
6. Existing same-major, review-only, replacement-first, lease, and compensation
   behavior continues to pass regression tests.
7. Existing consumers receive an explicit one-time `v0.4.0` migration path;
   later compatible proposals self-update without another workflow.

## Self-review

Completed on 2026-07-15. The review covered both slice diffs and the complete
tracked repository through diff-hygiene and version/credential searches,
PowerShell AST parsing, structural/link validation, pure resolver tests, and
adapter mutation/race fixtures. `.git`, generated temporary fixtures, and live
GitHub implementation were excluded from file review. The declared finite
budget was one slice review, one full convergence pass, and one confirmation
test after a blocking fix.

| ID | Classification / severity / confidence | Evidence and action | Status |
| --- | --- | --- | --- |
| `FIND-0051` | Test gap / Medium / High | Staged target-blob validation had success coverage but no negative fixture; added a wrong-staged-blob scenario that proves failure occurs before push or PR creation. | Resolved |

No unresolved actionable in-scope finding remains. PAT expiry, human actor
attribution, and the one-time pre-v0.4 migration remain explicitly owned risks
`RISK-0017`, `RISK-0018`, and `RISK-0020`, not hidden completion findings.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Slice reviews and bounded convergence scan complete.
- [x] No unresolved blocking finding; residual risks are explicit and owned.
- [x] Documentation, links, version, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked.
- [x] Local review gates pass; merge remains conditional on configured PR CI.

## Post-merge release gate

After the delivery pull request merges, tag the merged `main` commit as
`v0.4.0`, push the tag, and verify the remote reference.
