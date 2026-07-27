# 2026-07-27 - C# operational foundation first slice

## Directive and authority

The maintainer authorized the first development gate after the C# migration
plan was made explicit. [FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
/ [SUBF-0119](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0119)
/ [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) owns this
bounded slice. The [planning handoff](2026-07-27-csharp-operational-platform-planning.md)
and [DEC-0032](../../../docs/decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
remain the transition authority.

This slice may create only the solution, Domain and Application boundaries,
closed application/stage/capability identities, immutable authority grants,
and compiled architecture tests. It does not implement consumer behavior,
mutate a consumer, transfer production authority, publish a release, or retire
PowerShell.

## Implemented candidate

- `MeAndAI.Operations.slnx` contains Domain, Application, and one architecture-
  test project; Infrastructure and executable projects remain later slices.
- `global.json`, central build/package policy, locked restore, and repository-
  scoped `NuGet.Config` make the source build deterministic and independent of
  undeclared user feeds.
- Application identities are exactly governance, adoption, and consumer
  update. Stages and capabilities are closed, ordinal, duplicate-free, and
  fail closed. Mutation grants require the matching read capability.
- The workflow installs the reviewed .NET SDK explicitly on Ubuntu and Windows,
  performs locked restore, and runs [TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191).
- No PowerShell production command or authority path changed.

## Tests-first and review evidence

The initial focused test failed as intended because the authorized Domain and
Application types did not exist. The first implementation exposed two assertion
failures in exception parameter identity; the implementation was corrected to
name the caller-owned capability collection. Fresh-diff review then added exact
identity/null rejection, exact stage and mutation-capability composition,
solution inventory, and production dependency/package boundaries. Serializable
theory data and all analyzer information findings were also corrected.

The final local Release run passed 17 of 17 [TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191)
tests with zero build warnings and errors. Locked restore passed, format/analyzer
verification reported no changes, diff whitespace validation passed, and the
candidate-tree protocol structure route passed. The repository-local feed
policy also resolved the initial restore wait without changing system or user
configuration.

## Continuation

Progress uses five observable gates: readiness/authorization, tests-first red,
minimal green, local self-review/evidence, and exact committed-tree plus hosted
evidence. The first four are complete, so this candidate is four of five gates
(80%). [SUBF-0119](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0119)
is not complete until the fifth gate passes. Feature completion remains zero of
three completed subfeatures. The checkpoint estimate for gate 5 is 45 to 90
minutes, mainly dependent on hosted queue time.

After a commit makes the governance packet part of the HEAD instruction graph,
rerun exact-tree structure validation, push the bounded branch, open or update
the draft pull request, update [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154)
through a multiline-safe body route,
and require Ubuntu/Windows checks on the exact head. Later foundation slices
remain unauthorized.
