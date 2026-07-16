# FEAT-0017 - v0.9.2 Single-File Quick-Adoption Distribution

| Field | Value |
| --- | --- |
| Classification | Feature improvement |
| Status | Complete |
| Target version | 0.9.2 |
| Issue | [#51](https://github.com/hasanmanzak/meAndAI/issues/51) |
| Pull request | [#52](https://github.com/hasanmanzak/meAndAI/pull/52) |
| Decision | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md) |
| Tests | [TEST-0101](test-cases.md) |

## Problem and intended outcome

The canonical quick-adoption implementation is already one source-only
PowerShell file, but the quick guide asks maintainers to paste an inline
release-verification, download, persistence, and invocation command stack.
That presentation obscures the actual artifact, is awkward to retain and
reuse, and makes a simple launcher look like a collection of manual steps.

Publish the existing `scripts/Invoke-MeAndAIQuickAdoption.ps1` unchanged in
role as one named asset of the immutable protocol release. A maintainer
downloads that file outside the consumer repository, opens PowerShell in the
target directory, and runs one script invocation. The launcher continues to
verify the exact immutable protocol release before accepting or publishing
canonical source.

## Scope and non-goals

- Distribute the existing launcher as the single
  `Invoke-MeAndAIQuickAdoption.ps1` release asset.
- Replace the guide's inline command stack with an authenticated immutable
  release-asset link and one local `-File` invocation.
- Keep the downloaded launcher outside the consumer repository so an existing
  clean target does not gain an unrelated untracked file.
- Advance active protocol and adoption pins to `v0.9.2`.
- Record the exact asset name and digest in the external post-publication
  authority after the immutable release exists.

No second bootstrap script, installer framework, package-manager integration,
moving-`main` execution, `Invoke-Expression` or pipe-to-shell path, launcher
behavior expansion, or release automation service is in scope.

## Contracts and risks

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0086` | Distribution integrity | A downloaded file is presented as canonical while differing from the reviewed launcher | Mitigated by release maintainer | Upload the exact tracked launcher in the same immutable release operation; verify the asset name and SHA-256 digest against the merged file in issue #51 |
| `RISK-0087` | Consumer repository integrity | Saving the launcher inside an existing target makes its working tree non-clean | Mitigated by guide | Store the reusable launcher outside consumer repositories and pass the target explicitly as `-TargetPath .`; `TEST-0101` |

## Definition of Ready

- [x] Stable `FEAT-0017`, linked issue #51, target version, and owner exist.
- [x] Outcome, scope, non-goals, artifact identity, trust boundary, target path,
      errors, compatibility, and release evidence are explicit.
- [x] DEC-0007 remains the governing launcher boundary; no new architectural
      decision or runtime layer is required.
- [x] The change is one reviewable documentation/distribution slice.
- [x] `TEST-0101` covers the single-file asset and one-command guide contract.
- [x] Validation is bounded to one expected-red structure run, one focused
      green run, one fresh-diff review, one full suite, and the protocol's
      single completion scan.

## Acceptance criteria

1. The quick guide identifies the exact current-version release asset named
   `Invoke-MeAndAIQuickAdoption.ps1` and tells maintainers to download it
   outside the consumer repository.
2. Normal adoption is shown as one PowerShell `-File` invocation from the
   target directory; the quick section contains no inline API parsing,
   persistence command stack, `Invoke-Expression`, or pipe-to-shell execution.
3. The distributed artifact remains the existing source-only launcher rather
   than a new wrapper or installer, and it retains exact immutable-release
   validation before canonical-source use.
4. Active protocol pins use `v0.9.2`; historical release records remain
   unchanged.
5. The immutable `v0.9.2` release contains the exact reviewed launcher asset,
   and issue #51 records its API-reported digest and the merged-file digest.
6. Existing quick-adoption and repository validation scenarios remain green.

## Implementation and verification approach

Add `TEST-0101` to the structure suite first and demonstrate that the current
inline quick command fails it. Then update only the guide, active version pins,
DEC-0007 distribution wording, changelog, feature graph, and project memory.
The release operation uploads the merged launcher itself as the sole adoption
asset; no generated copy is committed.

## Verification and self-review

`TEST-0101` first failed on the six expected inline-bootstrap remnants in the
old quick section. After implementation, its distribution assertions passed;
the structure runner then reported only the intentional pre-completion feature
status gate. The fresh diff contains no second launcher, runtime behavior
change, credential value, moving-source execution path, pipe-to-shell command,
or consumer-owned file expansion.

After `FIND-0149` was corrected, the single budgeted confirmation suite passed
all discovered child suites and source-bound scenarios in 460 seconds,
including existing `TEST-0100` and new `TEST-0101`. The completion scan found
no unresolved `Blocking` observation, so validation stops without another
unchanged pass.

| ID | Classification / priority | Finding and resolution | Status |
| --- | --- | --- | --- |
| `FIND-0147` | Test boundary / P1 | The first green attempt counted owner/skip option examples because they were still inside the `Quick command` section. The normal one-command entry is now a bounded section and options have their own heading. | `Blocking` / Resolved before focused green evidence |
| `FIND-0148` | Test completeness / P1 | The first assertion relied on prose to say no second wrapper existed. `TEST-0101` now inventories `scripts/*QuickAdoption*.ps1` and requires the sole canonical launcher name. | `Blocking` / Resolved during fresh-diff review |
| `FIND-0149` | Documentation regression / P1 | The first complete suite showed that removing the inline command also removed the guide's existing `TEST-0041` supply-chain terms for the versioned release endpoint, API version, and published immutable state. Those facts are restored as launcher behavior outside the copy-ready command section. | `Blocking` / Resolved after failed complete-suite evidence |

The completion scan covers the tracked repository inventory, all PowerShell
ASTs, active and escaped version pins, guide and decision contracts, feature,
memory and changelog links, whitespace, scenario ownership, and the complete
test suite. External release/asset state does not exist before merge and is
owned by issue #51.

## Relationships

- Launcher feature: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Latest launcher correction: [FEAT-0016](../FEAT-0016-v091-quick-adoption-correction/README.md)
- Governing decision: [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking and post-publication authority: [issue #51](https://github.com/hasanmanzak/meAndAI/issues/51)
- Delivery: [pull request #52](https://github.com/hasanmanzak/meAndAI/pull/52)

## Definition of Done

- [x] Acceptance criteria and focused `TEST-0101` assertions pass.
- [x] Existing quick-adoption scenarios and the complete repository suite pass.
- [x] Fresh-diff review and the bounded project scan leave no unresolved
      `Blocking` finding.
- [x] Version, changelog, decisions, guide, links, and project memory agree.
- [x] Issue and pull request link the canonical records and validation evidence.

## Post-merge publication gate

Issue #51 is the external authority for the exact merged commit, immutable
`v0.9.2` release, single launcher asset name and digest, hosted checks, and
post-publication verification after those facts exist.
