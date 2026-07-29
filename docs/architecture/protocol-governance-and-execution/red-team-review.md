# Architecture Red-Team Review

| Field | Value |
| --- | --- |
| Owner | [TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164) |
| Reviewed architecture | [Protocol Governance and Execution Architecture](README.md) |
| Review state | Closed at design level; maintainer acceptance still pending |
| Implementation authority | Withheld |

The review challenged the design against the committed default-branch baseline
and the exact preserved WIP commit. A closed result means the architecture
states a resolution; it does not mean the behavior is implemented or proven.

| # | Red-team concern | Architectural resolution | Contract location |
| --- | --- | --- | --- |
| 1 | Rule and test identity were conflated | Introduce immutable `RULE-NNNN`; preserve and map `TEST-NNNN` only as qualification evidence | [Rule and catalog model](README.md#9-rule-and-catalog-model) |
| 2 | Rule revisions and catalog transitions were absent | Snapshots classify transitions; canonical fragments plus qualification-observable expected outcomes define rule revisions | [Rule descriptor](README.md#92-rule-descriptor) |
| 3 | Catalog metadata could compete with normative prose | Catalog binds the canonical normative fragment and retains its blob/anchor as provenance; it cannot introduce independent normative text | [Compiled policy pack](README.md#93-compiled-policy-pack) |
| 4 | “Consumer runs common tests” could authorize copying | Separate requirement, evaluator, upstream qualification, subject evaluation, and consumer domain tests | [Four meanings of test](README.md#4-the-four-meanings-currently-hidden-by-test) |
| 5 | Authority/consumer profiles were policy forks | Use role, operation, snapshot, surface, and enforcement axes; keep acquisition capability and I/O grants outside applicability | [Profile model](README.md#12-profile-applicability-and-enforcement) |
| 6 | Pin-to-runtime authentication chain was incomplete | Require exact bootstrap reference, accepted attestation predicate, asset digest/runtime proof, and independent post-start C# verification | [C# boundary](README.md#8-c-implementation-boundary) and [release resolution](README.md#20-immutable-release-and-reference-resolution) |
| 7 | Repository-reference consumers were not operationally defined | Gitlink and repository-reference resolvers return the same typed immutable result | [Reference kinds](README.md#20-immutable-release-and-reference-resolution) |
| 8 | Resident hook could hide copied logic | Hook only resolves, verifies, invokes, and transports; stale content fails before invocation | [Managed hook](README.md#19-consumer-integration-and-managed-hook) |
| 9 | Private artifact access and fork PRs conflicted | Same-repo exact-SHA gating is supported; initial fork gating returns `UnsupportedForkExecution`; future App/service capability requires a separate proof | [Provider trust boundary](README.md#18-provider-acquisition-and-enforcement-reality) |
| 10 | Self-consumption was circular | Use previous trusted release, shadow differential, independent qualification, exact-predicate attestation, and explicit transfer | [Self-consumption](README.md#21-self-consumption-and-authority-bootstrap) |
| 11 | Acquisition and rule outcomes could collapse | Keep acquisition, evaluation, conformance, enforcement, debt, and waiver dimensions separate | [Outcomes and reports](README.md#13-outcomes-and-reports) |
| 12 | Provider event coverage was not finite | Release-declared surface catalog maps content kinds, events, reads, applicability, and audit routes | [Provider acquisition](README.md#18-provider-acquisition-and-enforcement-reality) |
| 13 | GitHub inventory is not atomic | Label it bounded non-atomic observation; atomicity-dependent rules stay unevaluated | [Provider consistency](README.md#18-provider-acquisition-and-enforcement-reality) |
| 14 | Policy blocking was confused with platform prevention | Separate preflight, commit-bound merge gates, mutable-provider detective controls, and optional remediation writes | [Enforcement reality](README.md#18-provider-acquisition-and-enforcement-reality) |
| 15 | Mutation authority was too broad | Protected authority snapshot authenticates roles; grant binds its revision/digest, approval, exact target/digest, actor, fence, and expiry | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 16 | A unified executable would couple privileges | One release contains physically separate evaluator, report publisher, adoption, update, and release-finalizer hosts | [Host separation](README.md#17-mutation-and-privilege-model) |
| 17 | Adoption/update state was not durable enough | Hash-chained intents/receipts, fenced CAS, recovery grants, live-state classification, and corruption fail-closed behavior | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 18 | Arbitrary migration cannot be wholly deterministic | Keep MIG deterministic; semantic capability work uses a separately reviewed adoption envelope and exact final plan | [Adoption](README.md#15-adoption-application) and [update](README.md#16-update-application) |
| 19 | Extensions and waivers could cross trust boundaries | Closed-schema extensions; rule-revision/base-authority-bound waivers; no candidate self-waiver | [Extensions and waivers](README.md#22-extensions-waivers-and-historical-debt) |
| 20 | Historical debt could be hidden, self-edited, or block forever | Scan only proposes debt; protected-base authority persists exact reviewed debt via its own plan/grant and remains separate from conformance | [Historical debt](README.md#223-historical-debt) |
| 21 | Legacy equivalence could copy test topology | Classify legacy tests first; compare normative rule/material variants on the same evidence | [Qualification](README.md#23-qualification-and-test-architecture) |
| 22 | C# mandate had a bootstrap loophole/paradox | Minimal Trust Bootstrap verifies only exact cryptographic/runtime identity, never installs runtime, and C# re-verifies the full chain | [C# boundary](README.md#8-c-implementation-boundary) |
| 23 | Implementation freeze was informal | State allowed/prohibited work, preserved exact commit, and explicit exit conditions | [Architecture freeze](README.md#2-architecture-freeze) |
| 24 | Workflow suspension could weaken later evidence | Keep workflow/rulesets unchanged, use no-run commits, and require one bounded final architecture validation | [Implementation gate](README.md#27-implementation-entry-gate) |
| 25 | Existing decisions needed surgical supersession | Retain valid C# and authority clauses; supersede CLI-as-product; preserve exact WIP separately | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) and [transition register](transition-register.md) |
| 26 | Semantic content could not have output hashes before it existed | Split reviewed mutation envelope, isolated candidate production, exact execution-plan sealing, and final-plan review | [Adoption](README.md#15-adoption-application) |
| 27 | A candidate could manufacture a syntactically valid grant | Resolve issuers/roles from protected `ApprovalAuthoritySetSnapshot` and bind its exact revision/epoch/digest into grants | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 28 | `RecoveryRequired` lacked durable reconstruction evidence | Persist hash-chained intents before effects and exact receipts afterward; query live state before classified recovery | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 29 | First adoption had no trusted pin from which to resolve code | Require an exact non-moving `AdoptionBootstrapReference`, which never grants mutation and must install a durable pin | [C# boundary](README.md#8-c-implementation-boundary) and [release resolution](README.md#20-immutable-release-and-reference-resolution) |
| 30 | Read-only governance still appeared to publish provider results | Separate physically read-only evaluator from exact-report publisher host and grant | [Governance application](README.md#14-governance-application) and [host separation](README.md#17-mutation-and-privilege-model) |
| 31 | Base-context fork runs could not prove an exact candidate required result | Declare initial fork gating unsupported; admit it only through a future separately qualified exact-merge App/service | [Provider trust boundary](README.md#18-provider-acquisition-and-enforcement-reality) |
| 32 | A candidate could alter the historical-debt authority used to judge itself | Read authoritative debt only from protected base; persist any change through a separate reviewed/granted plan | [Historical debt](README.md#223-historical-debt) |
| 33 | `AuthorityGrant` could change semantic rule applicability | Remove grants from applicability axes; missing permission yields I/O failure, never a different rule set | [Profile model](README.md#12-profile-applicability-and-enforcement) |
| 34 | Unrelated edits to a multi-rule document would revise every rule | Digest canonical per-rule normative fragments and retain whole blob only as provenance | [Rule descriptor](README.md#92-rule-descriptor) |
| 35 | Transition register called TEST identities rules | Preserve TESTs as qualification scenarios mapped to future RULE identities | [Transition register](transition-register.md#2-test-and-evidence-disposition) |
| 36 | A syntactically valid attestation could come from an untrusted build | Bind accepted issuer, repository, workflow/builder, ref/commit, predicate schema, subject name, and digest | [Release resolution](README.md#20-immutable-release-and-reference-resolution) |
| 37 | Red-team closure preceded resolution of second-pass blockers | Close only after every second-pass concern is represented in the architecture and this register | This register and [acceptance checklist](README.md#26-architecture-acceptance-checklist) |
| 38 | Publication grant inside its own report would create a digest cycle | Report binds evaluation authority only; a separate publication envelope binds sealed report plus later grant | [Outcomes and reports](README.md#13-outcomes-and-reports) |
| 39 | Missing provider capability could make an applicable rule disappear | Remove capability from semantic profile; missing required evidence yields `NotEvaluated` and `Indeterminate` | [Profile model](README.md#12-profile-applicability-and-enforcement) |
| 40 | Proposal publication was confused with final closure | Branch direct/provider routes; re-acquire exact sealed target or observed merge before closure/finalization | [Adoption](README.md#15-adoption-application) and [update](README.md#16-update-application) |
| 41 | Installing a target pin before target-owned planning created partial-state authority | Stage verified target runtime side-by-side under current pin; make durable target pin one final-plan effect | [Update](README.md#16-update-application) |
| 42 | `release.publish` had no least-authority owner | Add a fifth Protocol Release Finalizer Host with exact plan/grant/journal and protocol-authority-only effects | [Host separation](README.md#17-mutation-and-privilege-model) |
| 43 | Runtime setup action expanded the pre-C# TCB without proof | Bootstrap never installs runtime or invokes setup; mismatch stops as `RuntimeUnavailable` | [C# boundary](README.md#8-c-implementation-boundary) |
| 44 | Authority set could change between grant issuance and effect | Bind identity/revision/revocation epoch/digest and re-resolve immediately before effects | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 45 | Mutable PR/provider evidence could leave a stale successful check on the same SHA | Gate only commit-bound rules; pre-publish version-vector check; mutable provider rules remain report-only initially | [Provider enforcement](README.md#18-provider-acquisition-and-enforcement-reality) |
| 46 | Behavior-changing evaluator fix fit neither unchanged nor normative revision | Treat every qualification-observable outcome change as rule revision; isolate proven refactors in evaluator artifact revision | [Rule descriptor](README.md#92-rule-descriptor) |
| 47 | Expired grant/lease made recovery impossible | Current authority issues a plan/journal-bound `RecoveryGrant` with a strictly newer fencing generation | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 48 | Journal append recursed and corruption/first-adoption retention were undefined | Make authenticated CAS append the non-recursive control-plane primitive; external protected store, fail-closed corruption, explicit retention | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 49 | Semantic work leaked into deterministic migration ownership | Preserve DEC-0018 MIG catalog/ledger; sequence separately linked DEC-0022 capability adoption after deterministic update closure | [Update](README.md#16-update-application) |
| 50 | New authority/journal/debt/provider contracts were outside release identity | Bind all canonical schemas and catalog digests in release; bind instance digests in owning evidence | [Release resolution](README.md#20-immutable-release-and-reference-resolution) |
| 51 | “Independent review” had no machine-checkable identity predicate | Authority snapshot defines role separation and exact protected solo-maintainer exceptions | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 52 | Transition register omitted adoption recovery/finalization | Add journal, interruption recovery, direct/provider closure, and finalization to adoption successor boundary | [Transition register](transition-register.md#4-successor-capability-boundaries) |
| 53 | Third-pass findings made prior closure claim stale | Record every correction and require a fresh independent re-review before closing | This register |
| 54 | Immutable updater fallback created an unnamed partial state | Define `LegacyHandoffPending`, exact protected marker/trust root, and the sole permitted same-target reconciliation path | [Update](README.md#16-update-application) |
| 55 | A candidate could delete its own stricter extension policy to pass | Evaluate with protected-base active snapshot; treat candidate policy as separately approved proposed transition | [Consumer extensions](README.md#221-consumer-extensions) |
| 56 | Behavior-only rule fix could not link a “normative change” | Allow reviewed rule-change authority to be normative change or defect plus exact qualification/differential evidence | [Rule descriptor](README.md#92-rule-descriptor) |
| 57 | Decision summary made publication grant bind its future envelope | Publication grant binds sealed report/target/snapshot; later envelope binds grant digest in one direction | [Outcomes and reports](README.md#13-outcomes-and-reports) and [privilege model](README.md#17-mutation-and-privilege-model) |
| 58 | Direct target sealing/finalization had no explicit authorization states | Add `DirectSealAuthorized` and post-closure `FinalizationAuthorized` with distinct exact grants | [Adoption](README.md#15-adoption-application) and [update](README.md#16-update-application) |
| 59 | Candidate Release Finalizer could receive credentials before becoming trusted | Require predecessor-trusted finalizer or pre-authorized immutable broker; candidate finalizer is unprivileged until transfer | [Host separation](README.md#17-mutation-and-privilege-model) and [self-consumption](README.md#21-self-consumption-and-authority-bootstrap) |
| 60 | A journal could not safely record its own retention deletion | Use a separate retention grant and independently retained intent/receipt ledger | [Privilege model](README.md#17-mutation-and-privilege-model) |
| 61 | Release publication capability could implicitly mutate the trust anchor | Add distinct non-transitive `authority.transfer` capability/grant bound to verified publication and exact old/new anchors | [Privilege model](README.md#17-mutation-and-privilege-model) and [self-consumption](README.md#21-self-consumption-and-authority-bootstrap) |
| 62 | Cross-generation handoff/transfer and durable consumer state lacked named release-bound schemas | Bind handoff context/marker, publication-verification, authority-transfer, migration/capability ledger, and extension-transition schemas plus instance-owner digests | [Release resolution](README.md#20-immutable-release-and-reference-resolution) |
| 63 | Delivery boundaries could omit or duplicate journal/recovery foundations | Give authority/grant/lease/journal/recovery one shared successor boundary required by publisher, adoption, update, and release finalizer | [Transition register](transition-register.md#4-successor-capability-boundaries) |
| 64 | A merged/sealed extension policy could activate before its own closure | Resolve active policy through protected activation record; CAS it only after closure under distinct grant/journal | [Consumer extensions](README.md#221-consumer-extensions) |
| 65 | Result dimensions had no deterministic aggregation/enforcement truth table | Define unresolved/violation flags, verdict precedence, and Audit/Prospective/FullBlocking debt/waiver enforcement rows | [Outcomes and reports](README.md#13-outcomes-and-reports) |

## Review conclusion

No implementation-blocking architecture question remains open after independent
final re-review. The remaining unchecked conditions are external gates:

- maintainer acceptance of the proposed architecture and decision;
- one bounded validation on the exact approved documentation head; and
- a later, separate implementation directive after successor Definition of
  Ready and design review.
