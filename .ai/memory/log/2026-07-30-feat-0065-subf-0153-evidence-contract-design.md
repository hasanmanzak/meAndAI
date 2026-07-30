# 2026-07-30 - Evidence-Acquisition Design

## Scope and authority

The maintainer's
[design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
authorizes Gate 1/2 architecture and expected-red planning for
[SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
and [TEST-0221](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
only. The deliverable is the
[evidence-acquisition design](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0153-evidence-contract-design.md).

Production/test code, project/package/lock/workflow/scenario-owner mutation,
expected-red execution, WIP extraction, consumer mutation, release/publication,
authority transfer, and PowerShell retirement remain unauthorized.

The bounded red-team is clean. The continuation chain is: maintainer
acceptance, accepted
[SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
design merge, exact-main validation, separately authorized
[SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
typed-handoff Gate 2 acceptance/merge/exact-main validation, then a
separate implementation directive. No candidate commit, draft PR, validation
run, or “continue” skips a step.

## Verified predecessor

[SUBF-0152](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
and [TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
are complete. [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170)
merged exact main
[c31819487e77fc878fc40fae6445bfef582719da](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da).
[Run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506)
passed
[Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506/job/90771124477)
and
[Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506/job/90771124470).
The predecessor Domain inventory remains exact.

## Design decisions

- Keep the normative SliceInventory in the existing BCL-only
  MeAndAI.Protocol.Domain assembly. Type counts are derived from the
  PredecessorInventory/SliceInventory lists, never handwritten.
- Separate requested AcquisitionTarget, observed AcquisitionBoundary, and
  exact EvidenceScope. Subject and source may differ only through this explicit
  mapping; every location and binding owns the same scope.
- Validate SnapshotKind identities once across target/boundary/scope:
  ExactCommit is lowercase 40/64-hex; Candidate/CapturedEvidence use SHA-256;
  provider event/full inventory retain target identity plus an exact observed
  boundary digest.
- Carry schema-identified, defensively copied bytes asserted canonical by an
  untrusted carrier, derived ContentDigest, typed location, requirement keys,
  and structural binding/context values. Construction is never qualification;
  exact release-bound
  [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  source/codec/resource/coherence checks must
  qualify the result before the kernel seals it.
- EvidenceContext alone mints RootEvidenceReference values for member
  bindings.
  [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
  owns qualified zero-binding context-proof references and
  parser-derived references; raw Domain references are not finding authority.
- Require one pre-unioned binding per location+schema physical observation;
  reject every repeated observation and every same-schema/version/digest value
  whose bytes differ. EvidenceContext never silently merges partitions.
- Keep requirement/catalog tokens,
  [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  adapter/source/failure tokens, and
  release-bound payload-schema tokens under separate semantic owners.
- Attach consistency, redaction, and failures to an exact
  RequirementAcquisition. Required omission is never a scope-free global flag.
- Count source objects separately from schema projections/bindings. Support
  non-paged, exhausted paged, and interrupted paged contexts with unique
  adjacent cursor transitions and checked long counts.
- Use a closed result union: Observed carries a Complete/Incomplete context;
  Absent has no attempt and is Incomplete; Failed has no valid context, covers
  every requested requirement, and is Failed. There is no failure envelope.
- Seal result variants through distinct provenance:
  [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  qualifies Observed and issues an exact attempt/failure receipt for Failed, and
  the application/kernel alone synthesizes Absent from an expected request
  slot plus a no-input/no-attempt routing receipt.
- Do not put RuleFinding or RuleEvaluation into
  [SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153).
  [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)/[TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
  must design and own the immutable catalog, release-bound decoder/model keys,
  separate content decode and context/location index caches, the
  SealedEvaluationContext, applicability, typed evaluation failures, qualified
  context/member findings, status factories, and aggregation.
- Make applicability a catalog-declared first phase: false needs no
  evaluation-only evidence and yields referenced zero-finding/zero-failure
  NotApplicable; true activates evaluation requirements; unresolved yields
  NotEvaluated.
- Cache only deterministic byte/depth/count/complexity semantic-budget
  failures. Host wall-clock timeout/cancellation remains an uncached
  operational runtime failure.
- Evaluators never receive raw provider DTOs, arbitrary object/dynamic values,
  consumer executable registrations, or acquisition I/O.

## WIP and test routing

The WIP stays frozen at
[1873c98638ba4960734aadb188eb8c8d70b4bc52](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52)
on draft [PR #160](https://github.com/hasanmanzak/meAndAI/pull/160).
Requirement/location/snapshot ideas inform fresh
[SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
contracts. Finding/evaluation/parser ideas are deferred to
[SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143);
report/serializer ideas remain
[SUBF-0154](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0154).
No source, project, pass, or compatibility shim carries
forward.

After later implementation authority:

- [TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
  retains predecessor API plus project/package/lock/restore graph;
- [TEST-0221](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
  owns exact CumulativeInventory equality and SliceInventory API;
- focused expected red is the sole oracle on the transient red tree;
- StructureOnly/root/hosted validation is prohibited until focused green and
  atomic scenario-owner/workflow activation;
- each stable job keeps exactly one locked restore and one combined
  [TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)/[TEST-0221](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
  process; and
- [TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  counts all such commands and builds scenario IDs from split
  fragments in its own source.

The accepted PR-head
[Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30490879521/job/90708165290)
left about 1 minute 35 seconds in the existing timeout. No new process, job,
restore, trigger, path filter, or timeout increase is allowed.

## Continuation

1. Bounded red-team closed clean across design and linked records.
2. Commit the graph-reachable design packet with no implementation files.
3. Run design-appropriate exact-head structural validation.
4. Push and publish a draft design PR for maintainer review.
5. After acceptance, merge and validate exact main.
6. Under separate design authority, accept/merge/exact-main validate the
   [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
   typed-handoff Gate 2 packet.
7. Wait for a separate exact implementation directive before Gate 3.
