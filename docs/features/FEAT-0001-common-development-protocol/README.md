# FEAT-0001 - Portable Common Development Protocol

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.1.0 |
| Issue | [#1](https://github.com/hasanmanzak/meAndAI/issues/1) |
| Pull request | [#2](https://github.com/hasanmanzak/meAndAI/pull/2) |
| Protocol | [Common Development Protocol](../../../PROTOCOL.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

Shared AI-assisted development needs durable quality gates and portable context,
but a shared repository must not mix the domain memory of unrelated projects.
The solution must be strict enough to prevent shallow implementation and small
enough to remain inspectable.

## Outcome

A consuming repository can pin this protocol by submodule or repository
reference, load it through a root adapter, and maintain independent project
memory. Work is decomposed, numbered, tested, self-reviewed, documented, and
linked through GitHub.

## Scope

- Delivery gates from context review through merge.
- Definition of Ready and Definition of Done with test state.
- Type and semantic-contract review.
- Full-project scan and classified finding rules.
- DDD, Rich Entity Model, TDD, SOLID, and duplication defaults.
- `M.m.rev` versioning.
- GitHub issue, label, branch, pull request, and merge conventions.
- Portable adoption and isolated repository-local memory.
- Feature, decision, issue, pull request, memory, and test templates.
- A small executable structural test.

## Non-goals

- A universal project bootstrapper.
- A semantic AI-memory validator.
- A replacement for each project's architecture or test framework.
- Central storage of unrelated project memory.
- Automatic generation of application code.

## Readiness evidence

- Contracts: this feature defines documentation contracts rather than runtime
  parameters. Its semantic boundaries are `M.m.rev`, immutable
  repository/ref/entry-point triples, root instruction loading, and the rule
  that project memory remains outside the protocol checkout.
- Consumers and dependencies: authenticated Git/GitHub environments, a
  consuming repository root, a compatible instruction loader, and either Git
  submodule support or a repository-reference resolver.
- Risks are classified and owned in the table below.
- Verification: the [structural test](../../../tests/protocol.tests.ps1), manual
  GitHub form-schema and external-link review, three independent self-reviews,
  and a full staged-repository scan.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0001` | Adoption | An adapter resolves the wrong protocol entry point | Mitigated; maintainers | Separate adapters in [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md) and [TEST-0008](test-cases.md) |
| `RISK-0002` | Privacy/context | Memory leaks across consuming projects | Mitigated; maintainers | Isolation boundary in [DEC-0002](../../decisions/DEC-0002-project-local-memory.md) and [TEST-0008](test-cases.md) |
| `RISK-0003` | Maintainability | Protocol grows into a universal framework | Accepted with control; maintainers | Explicit non-goals and [minimalism rule](../../../PROTOCOL.md#10-minimalism-and-exceptions) |

| Test readiness | Gate 1 state | Current evidence |
| --- | --- | --- |
| Scenarios | Defined before the test implementation | [TEST-0001](test-cases.md), [TEST-0002](test-cases.md), [TEST-0003](test-cases.md), [TEST-0004](test-cases.md), [TEST-0005](test-cases.md), [TEST-0006](test-cases.md), [TEST-0007](test-cases.md), and [TEST-0008](test-cases.md) |
| Test code | Planned; not started at DoR | [Implemented structural test](../../../tests/protocol.tests.ps1) |
| Baseline run | Reproduced against commit `a6e3064`; failed at [TEST-0001](test-cases.md) because protocol files were absent | Windows PowerShell 5.1 run passes |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/latest run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0001` | Core lifecycle, quality, scan, and version rules | [Issue #1](https://github.com/hasanmanzak/meAndAI/issues/1) | [TEST-0002](test-cases.md), [TEST-0006](test-cases.md); passed 2026-07-14 | Reviewed; `FIND-0003`, `FIND-0005`, `FIND-0011`, `FIND-0012` resolved or release-gated | Complete |
| `SUBF-0002` | Portable reference and isolated project memory | [Issue #1](https://github.com/hasanmanzak/meAndAI/issues/1) | [TEST-0001](test-cases.md), [TEST-0003](test-cases.md), [TEST-0008](test-cases.md); passed 2026-07-14 | Reviewed; `FIND-0001`, `FIND-0002`, `FIND-0010`, `FIND-0014`, `FIND-0015`, `FIND-0017`, `FIND-0018` fixed | Complete |
| `SUBF-0003` | Templates and executable structural validation | [Issue #1](https://github.com/hasanmanzak/meAndAI/issues/1) | [TEST-0004](test-cases.md), [TEST-0005](test-cases.md), [TEST-0007](test-cases.md); passed 2026-07-14 | Reviewed; `FIND-0004`, `FIND-0006` through `FIND-0009`, `FIND-0013`, `FIND-0016` fixed | Complete |

## Decisions

- [DEC-0001 - Portable protocol reference](../../decisions/DEC-0001-portable-protocol-reference.md)
- [DEC-0002 - Project-local AI memory](../../decisions/DEC-0002-project-local-memory.md)

## Definition of Ready

- [x] Stable feature ID and [linked issue](https://github.com/hasanmanzak/meAndAI/issues/1).
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Adoption boundary, semantic contracts, consumers, and dependencies are identified.
- [x] Work is split into three reviewable subfeatures with a gate ledger.
- [x] Numbered risks and decisions covering portability, memory ownership, and minimalism are recorded.
- [x] Numbered [test scenarios](test-cases.md) and verification approach are defined.
- [x] Test-code and baseline-run states are recorded.
- [x] Compatibility target and version are defined.

## Acceptance criteria

1. Another project can pin the protocol without storing its memory in the
   protocol repository.
2. The protocol explicitly enforces decomposition, contract review, TDD,
   self-review, mandatory test code, and full-project scans.
3. Work, decisions, findings, and tests have stable classifications and IDs.
4. Feature, decision, issue, and pull request records form a clickable graph.
5. The repository validates its own structure and local documentation links.
6. The implementation remains compact and does not introduce a large
   bootstrapper or AI-memory validator.

## Self-review

Reviewed on 2026-07-14. Scope was every staged repository file, the complete
baseline history, GitHub issue/label state, all local links/anchors, templates,
and the PowerShell validator. There is no runtime code, generated artifact,
binary, dependency graph, or deployment surface in this release. Three
independent read-only reviews covered semantics, technical correctness, and the
full repository. All implementation and traceability blockers were fixed in
this feature.

| ID | Classification / severity / confidence | Scope and impact | Resolution and status |
| --- | --- | --- | --- |
| `FIND-0001` | Defect / High / High | Repo-ref consumers could not load the protocol | Added distinct [submodule](../../../templates/project/AGENTS.submodule.md) and [repository-reference](../../../templates/project/AGENTS.repository-reference.md) adapters; fixed. |
| `FIND-0002` | Defect / High / High | Consumers missed root GitHub assets and labels | Adoption now copies assets and lists labels; fixed. |
| `FIND-0003` | Defect / High / High | Future releases could rewrite historical feature versions | Current and historical version checks separated; fixed. |
| `FIND-0004` | Process defect / Medium / High | Subfeatures lacked independent gate evidence | Added the subfeature ledger above; fixed. |
| `FIND-0005` | Process defect / Medium / High | DoR omitted contract, risk, and test-state evidence | Added readiness and risk tables; fixed. |
| `FIND-0006` | Defect / Medium / High | Subfeatures received feature title/label semantics | Added the [subfeature form](../../../.github/ISSUE_TEMPLATE/subfeature.yml); fixed. |
| `FIND-0007` | Defect / Medium / High | Finding categories mixed independent axes | Split disposition, category, severity, and confidence; fixed. |
| `FIND-0008` | Test gap / Medium / High | Core adapter isolation was not tested | Added [TEST-0008](test-cases.md); fixed. |
| `FIND-0009` | Test gap / Medium / High | Generic checks missed consumer/template semantics | Added required paths and targeted assertions; fixed. |
| `FIND-0010` | Test/risk / Medium / High | Links could escape the repo or external links remain unverified | Enforced root containment and separated external evidence; fixed/release-gated. |
| `FIND-0011` | Release blocker / Medium / High | Documented `pwsh` command was unavailable and CI was unconditional | Added Windows PowerShell 5.1 evidence and CI N/A rationale; fixed. |
| `FIND-0012` | Release blocker / Medium / High | Pre-merge DoD depended on a post-merge tag | Added a separate post-merge release gate; fixed. |
| `FIND-0013` | Privacy risk / Low / High | Evidence prompts could invite sensitive logs | Added general and form-level redaction rules; fixed. |
| `FIND-0014` | Documentation defect / Low / High | Memory log reference was not clickable | Linked [the memory log](../../../.ai/memory/log/README.md); fixed. |
| `FIND-0015` | Adoption defect / Medium / High | Repo-ref consumers lacked safe template/materialization guidance and copy commands could overwrite project assets | Scoped commands to empty submodule targets and added provider/manual alternatives; fixed. |
| `FIND-0016` | Process defect / High / High | TDD red-phase evidence was inferred instead of executed | Made missing-file failure deterministic and reproduced [TEST-0001](test-cases.md) against baseline commit `a6e3064`; fixed. |
| `FIND-0017` | Test gap / High / High | [TEST-0008](test-cases.md) named memory isolation without checking memory ownership and placement | Added adapter, adoption mapping, template-set, and consumer-layout assertions; fixed. |
| `FIND-0018` | Adoption defect / Medium / High | Copied issue configuration followed moving `main`, and copy commands could replace consumer files | Excluded repository-specific config and made submodule/repository-reference initialization collision-safe; fixed. |
| `FIND-0019` | Traceability gate / High / High | Acceptance and DoD cannot close before the delivery PR exists | Published [PR #2](https://github.com/hasanmanzak/meAndAI/pull/2) and linked it to [issue #1](https://github.com/hasanmanzak/meAndAI/issues/1) plus the canonical records; fixed. |
| `FIND-0048` | Test reliability / Medium / High | [TEST-0020](test-cases.md) matched an exact phrase across a Markdown line wrap and failed after an otherwise clean confirmation | Normalized insignificant whitespace in the assertion and reran the bounded confirmation; fixed. |

No unresolved blocking finding or known new debt remains. The issue, pull
request, feature, decisions, and tests form a clickable graph. External tag
links that require `v0.1.0` are verified in the post-merge release gate.

## Definition of Done

- [x] Acceptance criteria verified after PR publication.
- [x] Executable test code implemented and all scenarios passed.
- [x] Fresh-diff feature and subfeature self-reviews completed.
- [x] Full repository scan completed with scope and limitations stated.
- [x] Documentation and local links validated.
- [x] Issue and [pull request #2](https://github.com/hasanmanzak/meAndAI/pull/2) cross-linked.
- [x] Project memory and changelog updated.
- [x] Applicable review gates passed. CI is N/A for this compact first release;
  the single dependency-free test is run locally and CI can be added when change
  frequency or additional contributors justify a recurring workflow.

## Post-merge release gate

After the delivery pull request merges, tag the merged `main` commit as
`v0.1.0`, push the tag, and verify the remote tag plus external release links.
Tag publication is not a pre-merge Definition of Done item.
