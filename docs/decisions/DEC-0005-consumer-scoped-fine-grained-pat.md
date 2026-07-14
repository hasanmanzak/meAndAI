# DEC-0005 - Use a Consumer-Scoped Fine-Grained PAT for Updater Mutations

- Classification: Decision
- Status: Accepted
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer administrators
- Related features: [FEAT-0004](../features/FEAT-0004-self-updating-consumer-updater/README.md), [FEAT-0002](../features/FEAT-0002-semi-automatic-consumer-updates/README.md)
- Related decisions: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md)
- Supersedes: DEC-0003 only where it assigns consumer mutation to `GITHUB_TOKEN`, restricts managed proposals to one `.ai/protocol` path, or leaves copied updater reconciliation manual

## Context

The updater must be able to propose changes to its own workflow. GitHub requires
an explicit `Workflows` write permission for that operation, while the Actions
`GITHUB_TOKEN` permission surface does not provide the required updater
credential contract. A consumer-owned GitHub App would provide short-lived
installation tokens and a bot identity, but requires every adopter to register,
install, and protect a long-lived App private key. A centrally hosted App would
also require a service and credential broker outside this repository.

The current project needs a small, inspectable, backend-free updater that can be
used whether `meAndAI` is private or later becomes open source.

## Decision

Consumer mutations use a fine-grained personal access token stored as the
Actions secret `MEANDAI_UPDATER_TOKEN`. Its display name is
`meAndAI Updater - <repo>`. It selects only the consumer
repository and grants repository permissions `Contents: read/write`,
`Pull requests: read/write`, and `Workflows: read/write`; `Metadata: read` is
implicit.

The consumer workflow supplies this credential to its checkout and as
`GH_TOKEN`. Updater scripts remain credential-type agnostic. The workflow's
`GITHUB_TOKEN` is read-only and may read a public protocol source. A private
protocol source uses a separate read-only `MEANDAI_PROTOCOL_TOKEN`; one token
must not combine source-read and consumer-write authority.

The updater resolves the trusted pull-request actor from the authenticated
write token. Rotating to a token owned by another user does not transfer old
proposal ownership automatically. Consumer administrators must merge or close
the old proposal before rotation completes.

The same reviewed proposal may change `.ai/protocol` and the deterministic
target-different subset of the three canonical updater assets. Before mutation,
all current copies must equal the current pinned templates. Creation and live
validation require exact expected paths plus target modes and blobs. All other
DEC-0003 review-only, same-major, marker, replacement-first, lease,
revalidation, and compensation controls remain in force.

## Consequences

- Adoption needs one repository-scoped PAT and one Actions secret.
- PAT expiry, revocation, owner access loss, or organization policy can stop the
  updater and requires explicit rotation.
- GitHub activity is attributed to the PAT owner rather than a dedicated bot.
- Public `meAndAI` sources need no read secret; private sources keep a separate
  least-privilege credential.
- Pre-v0.4 copied updater code cannot gain this behavior retroactively and needs
  one reviewed migration. Later compatible releases update their own managed
  assets in the ordinary draft proposal.
- Consumer customization is preserved by failing closed rather than being
  merged or overwritten automatically.
- Credential acquisition can move to a GitHub App later without changing the
  updater scripts because both implementations terminate at `GH_TOKEN`.

## Alternatives considered

- Continue using `GITHUB_TOKEN`: rejected because the self-update contract needs
  workflow-file write authority not available through the required job-token
  permission model.
- Consumer-owned GitHub App: deferred because App registration, installation,
  private-key distribution, and actor lifecycle are disproportionate for the
  current backend-free scope.
- Centrally hosted public GitHub App: rejected for this feature because it
  requires hosting, a key vault or signing service, operational monitoring, and
  a multi-tenant security boundary.
- Fine-grained PAT shared across many unrelated repositories: rejected because
  it increases blast radius and couples independent consumer lifecycles.
- Keep updater assets manual: rejected because copied security and correctness
  fixes would continue to drift after protocol upgrades.

## Review condition

Revisit the credential choice when automation must be independent of a human
account, span multiple owners or organizations under centralized governance,
use a dedicated bot identity, or offer a hosted one-click installation. At that
point, prefer a GitHub App while preserving the `GH_TOKEN` script boundary.
