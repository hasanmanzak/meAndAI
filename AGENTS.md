# Repository Instructions

These instructions apply to the entire `meAndAI` repository.

1. Read and follow the [common development protocol](PROTOCOL.md).
2. Load this repository's [project-local memory](.ai/memory/README.md).
3. Before changing a feature, read its record in
   [docs/features](docs/features/README.md) and all linked decisions in
   [docs/decisions](docs/decisions/README.md).
4. Do not begin implementation until the Definition of Ready is satisfied.
5. Implement large work as independently testable subfeatures and apply the
   review gate after every subfeature.
6. Do not declare work complete until its Definition of Done, test evidence,
   documentation, links, and memory update are complete.
7. Before correcting a defect exposed by a consumer, classify the owning
   layer. Reusable behavior must be corrected and proven in meAndAI with a
   project-neutral fixture and immutable release; do not close common work with
   a named-consumer patch. Treat later consumer recovery as a separate, linked
   operation.
8. Protocol-provided reusable assets must not be copied, reimplemented, or
   retested in a consumer. Consumer changes are limited to genuinely
   project-specific integration, configuration, domain behavior, and semantic
   evidence. If the common asset is absent or insufficient, correct the common
   asset and its regression in meAndAI first, publish it, and only then perform
   bounded consumer recovery.

The protocol is recursively applied to this repository. Project-specific facts
belong in `.ai/memory`; reusable rules belong in `PROTOCOL.md`. A project rule
may override a common default only through a numbered decision record that
explains the reason and scope.
