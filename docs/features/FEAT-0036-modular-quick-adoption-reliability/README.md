# FEAT-0036 - Modular Quick-Adoption Runtime and Recovery Reliability

| Field | Value |
| --- | --- |
| Classification | Backward-compatible distribution architecture and correctness correction / `BUG-0018`, `BUG-0019`, `BUG-0020`, `BUG-0021` |
| Status | Complete |
| Target version | 0.12.5 |
| Issue | [#89](https://github.com/hasanmanzak/meAndAI/issues/89) |
| Pull request | [#90](https://github.com/hasanmanzak/meAndAI/pull/90), [#91](https://github.com/hasanmanzak/meAndAI/pull/91); v0.12.5 hotfix recorded through [issue #89](https://github.com/hasanmanzak/meAndAI/issues/89) after creation |
| Decision | [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md) |
| Tests | [TEST-0147 through TEST-0150](test-cases.md) |

## Problem and intended outcome

The quick-adoption launcher has grown to more than 6,000 lines in one release
asset. That shape increases review, maintenance, and agent-context cost even
though the maintainer-facing entry point should remain one command. A real
Windows PowerShell 5.1 recovery against a consumer also exposed two correctness
defects: one transient GitHub tree read terminates an otherwise recoverable run,
and structured managed-issue JSON can lose its quotes when it crosses the
native `gh.exe` argument boundary. The latter leaves a malformed issue that
correctly blocks every rerun.

Keep the one-command experience through a small, fail-closed bootstrapper that
loads one exact immutable module bundle outside the consumer repository. Then
make read-only GitHub transport resilient within a finite budget, prevent
structured-body argv corruption, and reconcile only the exact historical
malformed record that this defect could produce.

The first released v0.12.4 replay then exposed a separate convergence defect:
GitHub accepted and returned exact canonical issue #8, while the immediately
following all-issues inventory had not exposed it yet. v0.12.5 must bind the
successful creation response to its direct identity without weakening visible
duplicate/race detection.

## Scope

- Split the launcher source into cohesive PowerShell module files without
  changing its public adoption parameters or semantic ownership boundaries.
- Publish one thin `Invoke-MeAndAIQuickAdoption.ps1` bootstrapper and one
  deterministic `MeAndAI.QuickAdoption.Bundle.zip` per immutable release.
- Bind the bootstrapper to its own immutable runtime release while preserving
  `-ProtocolTag` as the independently selected consumer target.
- Verify release, asset digest, archive inventory, manifest identity, path
  safety, payload length, and payload digests before importing code.
- Retry explicitly classified read-only GitHub API calls only, with a bounded
  attempt count and delay; mutations remain single-attempt.
- Send structured or multiline GitHub bodies through a file/input boundary
  that preserves exact UTF-8 bytes on Windows PowerShell 5.1.
- Repair one exact quote-stripped managed update issue only after its complete
  generated contract, trusted author, repository identity, and absence of a
  related branch or pull request are proved; refetch and validate canonical
  state after repair.
- Validate one newly created issue from its positive POST identity and exact
  direct read; tolerate zero immediate canonical list matches, but reject more
  than one visible match or one match with a different issue identity.

## Non-goals

- Per-module network downloads, a package manager, persistent runtime cache,
  moving-source execution, `Invoke-Expression`, or pipe-to-shell execution.
- A second semantic adoption engine, recursive bootstrap chain, or fallback to
  an unverified local/older monolith when bundle verification fails.
- Retrying GitHub writes, authentication/authorization failures, semantic
  validation failures, or arbitrary native commands.
- Accepting pseudo-JSON as canonical ownership, repairing ambiguous records,
  auto-merging consumer proposals, or changing consumer application content.
- Re-running every expensive local suite after each slice; one converged push
  and one final hosted validation run own cross-suite evidence.

## Contracts and affected boundaries

### Runtime and archive identity

- The thin bootstrapper contains one canonical runtime repository, release tag,
  bundle asset name, and manifest schema. Runtime identity is independent of
  the requested protocol target so a current launcher can adopt a compatible
  older target.
- The immutable release API must report one non-draft, non-prerelease,
  immutable release, one exact tag-resolved commit, and one bundle asset with a
  canonical `sha256:` digest. Downloaded length and digest must match metadata.
- The archive contains exactly one canonical manifest plus its ordered payload.
  Absolute/traversal paths, backslashes, duplicates, case collisions, links,
  unexpected entries, oversized inventory, and expanded-size overflow block
  before extraction or import.
- Manifest repository, runtime tag, source commit, entry point, file inventory,
  length, and SHA-256 values must match the verified release and extracted
  regular files. Import occurs only from a unique temporary directory outside
  the consumer; the module exports only the intended entry point and is removed
  with its temporary root on every exit.

### GitHub read and body transport

- Only a call explicitly declared as an idempotent GitHub API read can retry.
  The policy is at most three total attempts with short capped delays for
  transport failures, HTTP 408/429, and 5xx responses. Authentication,
  authorization, not-found, validation, JSON, and contract failures do not
  retry. POST, PATCH, DELETE, branch publication, and generic native commands
  remain single-attempt.
- Structured/multiline request bodies are serialized as exact UTF-8 without a
  BOM and supplied through a temporary file or standard input, never embedded
  in native argv. Temporary material is owner-scoped and removed in `finally`.
- Legacy repair is not parser compatibility. It recognizes only the exact
  quote-stripped schema-2 line and exact generated issue title/body for the
  live repository/target/commit/plan, requires the authenticated trusted owner,
  proves no paired reserved branch or pull request exists, replaces the full
  body through safe transport, then refetches and validates the canonical
  contract. Every near-match blocks without mutation.
- Created-issue convergence does not retry the POST. The successful POST must
  return one positive issue number; a direct idempotent GET must preserve its
  exact marker, title, normalized body, open state, nonempty response author,
  and non-PR kind. The list inventory is then only a visible duplicate/race
  detector: zero matches may continue from the exact identity, while multiple
  matches or one different identity block before branch or PR publication.

## Consumers and dependencies

- Entry points: the release asset `Invoke-MeAndAIQuickAdoption.ps1`, its module
  entry point, the target-bound current-launcher recovery adapter, and managed
  issue/PR/comment GitHub calls.
- Consumers: new adopters, completed consumers using current-launcher recovery,
  release publication verification, quick-adoption tests, and consumer-update
  fixtures on Windows PowerShell 5.1 and PowerShell 7.
- Dependencies: [FEAT-0017](../FEAT-0017-v092-single-file-quick-adoption/README.md),
  [FEAT-0028](../FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md),
  [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md),
  and the test-runtime constraints from
  [FEAT-0035](../FEAT-0035-test-runtime-efficiency/README.md).

## Risks

| ID | Classification | Risk | Owner / response and evidence |
| --- | --- | --- | --- |
| `RISK-0163` | Supply chain | A small launcher loads a bundle that is movable, substituted, partial, or from the wrong release | Release maintainer / exact immutable release, API digest, archive manifest, per-file digest, and negative trust table in `TEST-0147` |
| `RISK-0164` | Compatibility | Mechanical splitting changes parameter binding, script state, execution order, or cleanup | Launcher maintainer / public-contract parity plus representative direct-module and thin-bootstrap slices in `TEST-0147` |
| `RISK-0165` | Archive safety | ZIP traversal, collision, link, or expansion abuse writes outside the owned temp root | Launcher maintainer / pre-extraction inventory and bounded archive negatives in `TEST-0147` |
| `RISK-0166` | Retry safety | A generic retry duplicates a mutation or conceals a permanent failure | Updater maintainer / explicit read-only declaration, three-attempt cap, non-retry matrix, and mutation sentinel in `TEST-0148` |
| `RISK-0167` | Native transport | PowerShell 5.1 corrupts another issue, comment, or pull-request body | Updater maintainer / real native executable boundary and byte-exact round trip in `TEST-0149` |
| `RISK-0168` | Ownership | Broad legacy repair claims or rewrites an ambiguous/foreign issue | Updater maintainer / exact contract, trusted actor, absent branch/PR proof, near-match negatives, refetch validation in `TEST-0149` |
| `RISK-0169` | Validation cost | Repeated full suites consume disproportionate local and hosted resources | Test maintainer / focused slice owners, one structure pass, one converged push, and one final hosted full run |
| `RISK-0170` | Eventual consistency | A successful issue creation is reported as failed because the all-issues list lags, or a visible concurrent duplicate is ignored | Updater maintainer / POST identity, direct read, zero-match success, different-identity and duplicate negatives in `TEST-0150` |

## Test readiness

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0147 through TEST-0150](test-cases.md) |
| Test code | Implemented / focused green | Expected-red evidence and Windows PowerShell 5.1 green runs are recorded in the scenario log |
| Baseline run | Green | Immutable v0.12.4 / `main` at `edf443744e3a72bcc951008bf1b3ba4727104a27`; PR #91 Ubuntu, Windows PowerShell 5.1, and GitGuardian evidence is green |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0067` | Mechanical module extraction, thin verified bootstrapper, deterministic bundle, and publication contract | [Issue #89](https://github.com/hasanmanzak/meAndAI/issues/89) | Final `TEST-0147` passed on PS5.1 in 17.7 seconds and again in 18.1 seconds after its Unix temp-environment correction; its direct-builder regression passed in 21.3 seconds; the affected `AdoptionLifecycle` shard passed in 170 seconds after current-version and native-clone fixture corrections; focused publication owner passed in 1.7 seconds | Public parity, exact Git-blob builder, trust order, archive containment, token environment, import, publication binding, cleanup, and cross-platform fixture parity reviewed; `FIND-0184` through `FIND-0190` and `FIND-0193` through `FIND-0196` resolved | Complete; hosted evidence pending externally |
| `SUBF-0068` | Explicit bounded retry for idempotent GitHub API reads | [Issue #89](https://github.com/hasanmanzak/meAndAI/issues/89) | `TEST-0148` passed with `TEST-0149` on PS5.1 in 23.4 seconds | GET-only declaration, classification, attempt cap, delay, paged-attempt reset, final diagnostics, and single-attempt mutations reviewed | Complete; hosted evidence pending externally |
| `SUBF-0069` | Safe structured-body transport and exact malformed-issue reconciliation | [Issue #89](https://github.com/hasanmanzak/meAndAI/issues/89) | `TEST-0149` passed with `TEST-0148` on PS5.1 in 23.5 seconds for v0.12.5; focused `TEST-0150` passed in 12.0 seconds; all 28 canonical updater behavior scenarios passed in 64.0 seconds and their registry binding passed in 0.7 seconds; the focused finalization owner passed in 11.1 seconds for v0.12.4 | Exact UTF-8 bytes, argv exclusion, temp cleanup, separate issue/updater actors, repository/duplicate/ref/PR/backlink proofs, exact created identity, true zero-list tolerance, different-identity race failure, ordinal near matches, and idempotency reviewed | Complete; hosted evidence pending externally |

## Definition of Ready

- [x] Stable IDs and linked issue #89 exist.
- [x] Problem, outcome, scope, and explicit non-goals are recorded.
- [x] Acceptance criteria are measurable.
- [x] Runtime, archive, retry, body, ownership, lifecycle, error, cleanup, and
      compatibility contracts identify affected consumers and dependencies.
- [x] `RISK-0163` through `RISK-0170` and DEC-0023 record the architectural
      and operational choices.
- [x] `SUBF-0067` through `SUBF-0069` preserve the requested implementation
      order and have independent review gates.
- [x] `TEST-0147` through `TEST-0150` cover success, failure, boundaries,
      regression, native-runtime behavior, and fail-closed near matches.
- [x] Test-first expected-red evidence, executable owners, and the bounded
      verification approach are explicit.

## Acceptance criteria

1. The maintainer still downloads and invokes one small PowerShell script with
   the existing public parameters, while the tracked implementation is split
   into cohesive modules and no generated bundle is committed.
2. The bootstrapper loads code only after one immutable runtime release, one
   exact bundle asset, archive/manifest identity, and every payload digest have
   been verified outside the consumer repository; all trust-table failures
   leave the mutation sentinel and consumer tree unchanged.
3. Two deterministic builds from the same exact source commit produce the same
   archive bytes and SHA-256; the release contract contains exactly the thin
   launcher and module bundle with externally verified digests.
4. The direct module entry point preserves the prior launcher's parameter,
   assessment, credential, repository, workflow, Codex, completion, recovery,
   and cleanup contracts; one real thin-bootstrap vertical slice proves the
   integration boundary on Windows PowerShell 5.1.
5. A retryable read that fails transiently can converge within three total
   attempts; exhausted transients fail clearly, permanent failures fail once,
   and no mutation is automatically retried.
6. Managed issue, comment, and pull-request bodies containing canonical JSON
   survive the Windows PowerShell 5.1 native boundary byte-for-byte and their
   temporary transport files are cleaned on success and failure.
7. The exact poisoned issue shape produced by the historical bug can be repaired
   once when all ownership and absence proofs hold, then converges through the
   canonical parser; every changed field, prose, actor, duplicate, branch, or PR
   blocks before mutation.
8. A successful issue POST plus exact direct identity read can continue when
   the immediate canonical list has zero matches; multiple visible matches or
   one different visible identity fail before branch or PR publication.
9. Focused test owners, one structure pass, the relevant consumer-update and
   launcher recovery slices, diff checks, fresh-diff self-review, and one local
   completion scan pass with no unresolved `Blocking` finding. The exact hosted
   validation remains a delivery gate after candidate completion and before
   merge.

## Implementation and verification approach

The slices were implemented in the user-required order. `TEST-0147` first
recorded the expected-red distribution/structure result, then the existing
behavior was mechanically moved into one module scope before the thin
bootstrap/builder was accepted. `TEST-0148` preceded the explicit read retry,
and `TEST-0149` preceded safe body transport and exact legacy repair. Focused
owners passed without intermediate publication. After convergence, run the
canonical consumer-update suite once, only the affected quick-adoption shards,
one structure pass, `git diff --check`, one fresh-diff review, and the single
project completion scan. Push once and use one hosted full run as cross-suite
authority unless focused evidence proves a wider local run is necessary.

## Relationships

- Distribution history: [FEAT-0017](../FEAT-0017-v092-single-file-quick-adoption/README.md)
- Local launcher boundary: [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md)
- Current-launcher recovery: [FEAT-0028](../FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md) / [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md)
- Runtime-cost policy: [FEAT-0035](../FEAT-0035-test-runtime-efficiency/README.md)
- Delivery and post-publication authority: [issue #89](https://github.com/hasanmanzak/meAndAI/issues/89)

## Self-review

The completed slice reviews found and resolved these in-scope blocking
observations before the focused green evidence:

| ID | Slice | Observation | Disposition |
| --- | --- | --- | --- |
| `FIND-0184` | `SUBF-0067` | Windows PowerShell 5.1 could not use the ZIP API until its compatibility assembly was loaded explicitly. | `Blocking` -> resolved by explicit runtime loading and retained PS5.1 bootstrap evidence. |
| `FIND-0185` | `SUBF-0067` | The first thin-launcher draft could reach GitHub before applying the existing minimum GitHub CLI version gate. | `Blocking` -> resolved by running the compact canonical version/auth preflight before release access. |
| `FIND-0186` | `SUBF-0067` | The bootstrapper and module entry point temporarily carried different default protocol targets. | `Blocking` -> resolved by one v0.12.4 default and executable public-parameter parity evidence. |
| `FIND-0187` | `SUBF-0067` | Runtime download initially depended only on the active `gh` identity, which would reject a private protocol repository readable only through the local read token. | `Blocking` -> resolved by revalidated invocation-scoped token use, pre-import environment restoration, and positive/negative token fixtures. |
| `FIND-0188` | `SUBF-0067` | Post-publication verification trusted the launcher's asset digest without binding those bytes to the launcher source at the released commit. | `Blocking` -> resolved by byte-for-byte released-source comparison and a stale-launcher negative. |
| `FIND-0189` | `SUBF-0067` | Post-publication bundle inspection was weaker than runtime inspection for non-regular entry kinds, canonical entry order, and pre-download asset size bounds. | `Blocking` -> resolved by parity checks, tight launcher and bundle bounds before download, and order/kind/oversize negatives. |
| `FIND-0190` | `SUBF-0067` | Builder tests could pass while comparing transformed worktree bytes, and their partial-output case failed before an output existed. | `Blocking` -> resolved by transform-sensitive Git-blob authority and an injected post-write failure proving partial-output removal. |
| `FIND-0191` | `SUBF-0069` | Stale-issue derivation compared its reserved branch allowlist case-insensitively, wider than the exact historical generator contract. | `Blocking` -> resolved by ordinal branch membership and a case-variant reserved-branch negative. |
| `FIND-0192` | `SUBF-0069` | The hosted finalization fake still assumed every API endpoint began with `repos/` and every body was inline, so the new authenticated-actor read and safe `body=@file` transport failed before exercising legacy repair. | `Blocking` -> resolved by exact `user` endpoint/token handling, UTF-8 body-file decoding at all affected fake mutations, and retained stack traces for actionable hosted diagnostics; the focused PS5.1 owner passed. |
| `FIND-0193` | `SUBF-0067` | The consumer-contained temp negative set only `TEMP` and `TMP`; Unix `.NET` resolves `GetTempPath()` through `TMPDIR`, so hosted Ubuntu never constructed the intended unsafe path and reported a false failure. | `Blocking` -> resolved by setting and restoring all three process temp variables; the focused PS5.1 owner remained green and hosted Ubuntu is the final Unix authority. |
| `FIND-0194` | `SUBF-0067` | The full adoption-lifecycle fixture still wrote `VERSION` as `0.12.3` while labeling its immutable mock snapshot `v0.12.4`, so the exact source-version gate correctly rejected it. | `Blocking` -> resolved by advancing the sole stale fixture value to `0.12.4` and confirming no current launcher/adoption fixture retains `v0.12.3`. |
| `FIND-0195` | `SUBF-0067` | After the version correction exposed the next path, the in-process mock `gh repo clone` invoked raw Git under stop-on-stderr semantics, so ordinary clone progress could be misclassified as failure on Windows PowerShell 5.1. | `Blocking` -> resolved by isolating the mock native call, restoring error preference, and deciding from the captured exit code; the exact `AdoptionLifecycle` shard passed. |
| `FIND-0196` | `SUBF-0067` | The builder computed its omitted `SourceRoot` from `$PSScriptRoot` inside the parameter-default expression, before Windows PowerShell 5.1 initialized that automatic variable, so the documented direct release-build command failed before execution. | `Blocking` -> resolved by computing the default after parameter binding only when the caller omitted it; the focused test now invokes the fixture builder through a real Windows PowerShell 5.1 `-File` process without `-SourceRoot` and compares its archive to explicit-root builds. |
| `FIND-0197` | `SUBF-0069` | The first released v0.12.4 Derdini replay repaired issue #7 and created exact canonical issue #8, but immediately re-read the eventually consistent all-issues inventory instead of binding the successful POST response; the list had not exposed #8 yet and produced a false convergence failure. | `Blocking` -> resolved for v0.12.5 by validating the created issue number, exact direct identity read, canonical body/title/state and nonempty response author independently of the updater PAT actor, then using list inventory only for visible duplicates; an intentionally lagging list must reach draft-PR creation while one different visible identity fails closed. |

Fresh-diff review for `SUBF-0067` also bound both release assets to the exact
released source commit, aligned publication archive checks with the runtime
bootstrapper, and corrected the Unix temp-variable fixture exposed by the
second hosted run. Its Windows peer exposed and resolved the remaining stale
snapshot version and raw mock-clone stderr assumptions; the affected lifecycle
shard then passed without a wider local suite. Fresh-diff review for `SUBF-0068` confirmed that retry is reachable only through
the explicit GET boundary, incomplete paginated attempts are discarded, and
mutations remain single-attempt. Fresh-diff review for `SUBF-0069` confirmed
that structured bodies never enter native argv and that exact legacy repair is
a pre-mutation, refetched, fail-closed exception rather than parser
compatibility, including ordinal reserved-branch identity. The first hosted run
then exposed `FIND-0192` in an older finalization fake rather than production;
the focused cross-scenario owner passed after the fake adopted the same actor and
body-file contracts. No unresolved `Blocking` observation remains in those focused
slice reviews.

The final feature review and local convergence scan completed across tracked
inventory, PowerShell ASTs, runtime/bundle trust, GitHub transport and ownership
surfaces, links/version/memory, affected focused suites, and one structure pass.
Hosted cross-runtime evidence remains external and pending. Unchanged full
local suites were excluded because no focused failure demonstrated a wider
cross-suite dependency.

## Definition of Done

- [x] Acceptance criteria met for the locally complete candidate.
- [x] Mandatory test code and scenario mapping complete.
- [x] Focused test commands and successful results recorded; final hosted and
      live replay evidence remains external and pending.
- [x] Every subfeature review gate and the bounded local final scan converge.
- [x] No unresolved `Blocking` finding; every other disposition has its
      required authority, owner, rationale, and link.
- [x] Candidate documentation, decision, changelog, version, links, and project
      memory are current without projecting external publication facts.

## Delivery gates

- [ ] The v0.12.5 hotfix PR and issue #89 cross-link the canonical records.
- [ ] Applicable hosted Windows and Ubuntu checks pass before merge.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #89](https://github.com/hasanmanzak/meAndAI/issues/89) |
| Release authority | `Pending`; immutable GitHub Release after merge |
| Release identifier | `Pending`; exact release link recorded externally after publication |
| Target commit | `Pending`; exact merged commit recorded externally after publication |
| Verification evidence | `Pending`; exact two-asset inventory, API/download digests, bundle manifest identity, checks, Derdini replay, and cleanup recorded externally |
