# DEC-0013 - Verify Trusted Adoption Before Mutation and Preserve Recoverable Evidence

- Classification: Decision
- Status: Accepted
- Date: 2026-07-16
- Decision owners: meAndAI maintainers
- Related feature: [FEAT-0013](../features/FEAT-0013-v084-correction/README.md)
- Tracking and publication authority: [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41)
- Related decisions: [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0008](DEC-0008-local-codex-execution.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), [DEC-0011](DEC-0011-qualified-evidence-and-closure.md), and [DEC-0012](DEC-0012-bounded-correction-and-external-release-evidence.md)

## Context

The v0.8.3 scan found that several individually strict checks were ordered or
shared incorrectly. Trusted source existed but consumer-local updater execution
could precede its asset check. Seed drift was rejected, but only after missing
secrets could be written. Completion had exact leases, but its remote push and
marker update were not one recoverable transition. Bootstrap had an exact
manifest contract while the launcher accepted only identity fields.

The same scan found evidence-boundary defects: named fixture variants were not
all exercised, one sequential state model was described as process concurrency,
comment evidence stopped after page one, and governance controls mixed finding
classification with disposition. Adding another validator or bootstrap layer
would duplicate ownership rather than repair these boundaries.

## Decision

1. The exact checked-out protocol source is the authority that validates the
   complete consumer-local updater asset set before the workflow passes either
   credential to local executable code.
2. The launcher validates any existing seed path and its exact canonical bytes
   before acquiring the secret-reconciliation lock or writing a repository
   secret; missing seed state remains eligible for later canonical creation.
3. Completion publication is an explicit recoverable transition. Before push,
   persisted intent binds the previous head, planned head, repository, actor,
   protocol, and lifecycle state. A rerun finalizes a live planned head without
   repeating semantic work; a still-live previous head is restored to the exact
   proposal state before retry, and every unrelated head blocks.
4. The existing pure capabilities module owns the exact adoption-manifest
   contract. Bootstrap and launcher consume that contract; neither maintains a
   weaker parallel validator.
5. Evidence descriptions are constrained by executed fixtures. External
   collection follows the provider's pagination contract under a finite bound,
   and page-after-first coverage is mandatory when later evidence is valid.
6. Finding classification and the four protocol dispositions remain separate
   fields. Version grammar is executable boundary evidence, not only a current
   literal match.
7. Exact release, commit, and hosted-check facts remain in [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) and the
   GitHub Release after publication. Canonical repository documents link stable
   merged PRs and do not depend on deleted work branches or predict their own
   release commit.

The implementation extends only the existing module, adapters, launcher,
workflow, tests, and governance records. It introduces no new persistent
validator, bootstrapper, service, or scan phase.

## Consequences

- Consumer credentials never cross into an unverified local updater copy.
- Rejected seed state is side-effect-free with respect to repository secrets.
- The launcher can resume the narrow push/marker interruption window exactly.
- Manifest schema drift is fixed once at its existing pure-contract boundary.
- Tests and external evidence state precisely what they prove, at the cost of a
  small number of focused negative and pagination fixtures.
- The private repository's currently unavailable `main` protection remains
  [RISK-0076](../features/FEAT-0013-v084-correction/README.md#risk-0076), classified
  `ExternalOrLegacyFollowUp`, owned by the maintainer, and reviewed if the
  repository becomes public or the account gains a supporting GitHub plan.
- Validation remains finite: the completed initial scan and one confirmation
  after remediation. Only changed evidence or a blocking result can reopen it.

## Alternatives considered

- Execute the local updater first and let it validate itself: rejected because
  untrusted code cannot establish its own identity after receiving credentials.
- Roll back a secret when later seed validation fails: rejected because secret
  values cannot be read back and rollback would create a second unsafe mutation.
- Retry the marker update without persisted intent: rejected because a rerun
  cannot distinguish the planned pushed head from unrelated drift.
- Keep launcher and bootstrap manifest validators separate: rejected because
  their prior semantic drift produced the finding.
- Search only the first 100 comments or allow issue-body evidence: rejected
  because either can produce false negative or false positive closure.
- Add a generalized self-validating bootstrap framework: rejected because the
  corrections have small existing ownership boundaries.

## Review condition

Review this decision if GitHub provides an atomic workflow/secret transaction,
signed immutable workflow artifacts directly executable by consumers, or an
atomic pull-request head-plus-metadata update. Review [RISK-0076](../features/FEAT-0013-v084-correction/README.md#risk-0076) separately
when repository visibility or plan capability changes.
