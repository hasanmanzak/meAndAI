# 2026-07-29 - [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md) Bounded Reusable Governance MVP

## Current authority and evidence

Development continues on `codex/feat-0060-dor-analysis` under
[issue #155](https://github.com/hasanmanzak/meAndAI/issues/155) and
[draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160).
[SUBF-0138](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0138)
has exact-head hosted evidence: [run `30394623671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30394623671)
passed both Ubuntu and Windows validation. The slice remains a read-only,
provider-free, non-authoritative `CSharpShadow` implementation of canonical
[TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004).
PowerShell remains production and compatibility authority; no workflow route,
consumer repository, required check, or retirement boundary changed.

## Accepted bounded allocation

[DEC-0034](../../../docs/decisions/DEC-0034-bounded-reusable-governance-catalog.md)
allocates the independently releasable `v0.17.0` MVP to
[FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md).
The bounded feature targets exact-commit evaluation, the two recorded
profiles, canonical
[TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004)
and
[TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005),
a deterministic typed catalog and report, and one framework-dependent
`maai-governance.zip`. Candidate-worktree evaluation, the remaining governance
families, exhaustive coverage, and equivalence are outside this release.

Repository and document analysis must be reusable by construction. One
immutable evaluation context reads and parses a repository artifact once;
rules consume its typed indexes instead of owning duplicate scanners, regular
expressions, parsers, snapshots, or catalog projections. Distinct rule classes
remain appropriate only for genuinely distinct invariants and change reasons.

## Follow-up ownership

[FEAT-0064](../../../docs/features/FEAT-0064-governance-coverage-equivalence/README.md)
/ [issue #161](https://github.com/hasanmanzak/meAndAI/issues/161) owns
candidate-worktree support, remaining rule families, complete catalog
qualification, and differential equivalence. Those gates remain fail-closed
for required-check enforcement, authority transfer, compatibility retirement,
or PowerShell source retirement.

## Progress and continuation

After the scope-record correction,
[FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
is one of seven subfeatures
complete, approximately 14.3%, with six pending. The next coherent development
gate is the shared parse-once repository/document context followed by canonical
[TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005)
through that same context. Keep the typed catalog, engine defaults,
and report metadata single-sourced as the rule set grows. Do not implement
[FEAT-0064](../../../docs/features/FEAT-0064-governance-coverage-equivalence/README.md),
widen authority, mutate a consumer, disable PowerShell, or claim
equivalence as part of this continuation.

## Structural record correction

The first committed scope packet exposed
[FIND-0367](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0367):
the planned-scenario authority still named its former owner, then exact-link
governance found moved and newly repeated identifiers. The owner and links were
corrected without restoring duplicate declarations; PowerShell 7
`StructureOnly` then passed in 184.6 seconds. Commit the correction before
counting dual-runtime exact-HEAD evidence.
