# v0.8.6 Publication-Evidence Correction

- Work: [FEAT-0014](../../../docs/features/FEAT-0014-v085-convergence/README.md)
- Governing release decision: [DEC-0012](../../../docs/decisions/DEC-0012-bounded-correction-and-external-release-evidence.md)
- Delivery and post-publication authority: [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43)
- Initial delivery: [pull request #45](https://github.com/hasanmanzak/meAndAI/pull/45)
- Corrective review: [pull request #46](https://github.com/hasanmanzak/meAndAI/pull/46)
- Historical release: [v0.8.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.5)
- Target: `0.8.6`
- Status: Local correction and complete suite passed; pull request #46 owns the
  corrective review and exact future publication facts remain external.

The first post-publication preflight for immutable v0.8.5 found `FIND-0132`.
Its release-target FEAT-0014 record still said publication was pending and mixed
post-publication checks into the pre-merge Definition of Done, while the
existing `TEST-0065` verifier correctly requires a complete feature record.
The release and runtime checks themselves passed, but that immutable commit
cannot honestly satisfy the verifier.

The v0.8.6 correction does not weaken `TEST-0065` or change runtime behavior.
It separates the lifecycle gates, completes the feature's pre-merge projection,
and extends `TEST-0092` so the complete local suite rejects the same mismatch
before a future publication. The exact-tree focused quick-adoption suite passed
in 377.2 seconds and the complete PowerShell 5.1 suite passed in 561.6 seconds.
Corrective review, hosted checks, an immutable release, and one fresh
confirmation scan form the remaining bounded path.
