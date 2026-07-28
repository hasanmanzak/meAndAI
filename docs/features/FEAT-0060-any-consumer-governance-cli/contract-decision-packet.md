# [FEAT-0060](README.md) v1 Contract Decision Packet

> **Historical-input boundary (2026-07-29):** This packet is retained as
> FEAT-0060 planning and audit input. Under
> [DEC-0034](../../decisions/DEC-0034-bounded-reusable-governance-catalog.md),
> full `candidate` snapshot support, remaining governance coverage, and
> equivalence qualification belong to
> [FEAT-0064](../FEAT-0064-governance-coverage-equivalence/README.md), not the
> bounded FEAT-0060 release completion boundary.

Status: accepted by the maintainer on 2026-07-28; the original acceptance was
records-only. The later specification-first sequencing and bounded first-slice
authorization are recorded by
[DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md).

The repository evidence reached the first boundary that could not be resolved
by inspection alone. The accepted bundle keeps v1 finite, deterministic,
repository-only, and non-authoritative while C# remains a shadow engine.

## Accepted v1 bundle

### 1. Material-variant granularity

Assign a stable namespaced `variantKey` whenever an input branch changes the
expected outcome, finding code, profile applicability, evidence source,
snapshot mode, authority state, or disposition. Multiple inputs with the same
oracle may share one declared finite partition and case-list digest.
Generative spaces are represented by explicit boundary partitions and a fixed
seed/corpus, not by pretending every generated sample is a separate permanent
identity.

Each declaration packet records `Unexpanded`, `Partial`, or `Complete` plus its
proven cardinality. This creates an auditable denominator without allocating
new `TEST-*` identities for language ports.

### 2. Planned route versus evidenced disposition

Use separate fields:

- `plannedRoute` records the records-only analysis hypothesis; and
- `evidencedDisposition` remains empty until same-snapshot executable proof
  supports one closed disposition;
- `canonicalEvidenceOwner` preserves the current PowerShell suite, GitHub
  Actions semantic contract, external verifier, or .NET test project; and
- `operationalAuthorityState` exists only for rows that participate in the
  governance operational-capability migration.

Applicable current migration rows retain `PowerShellAuthority`; infrastructure,
provider, workflow-semantic, and existing-foundation rows do not receive that
state merely because they appear in the same inventory. Existing C# foundation
rows later receive reasoned `NotApplicable` /
`AlreadyOwnedByCSharpFoundation` evidence rather than a fabricated language
transfer. All analysis rows currently keep `evidencedDisposition` empty.
Missing or divergent evidence cannot be converted into an optimistic
disposition.

### 3. Policy/runtime support range

Treat the evaluated subject snapshot and the engine/policy bundle as separate
identities. v1 claims support only for an explicitly bound application/policy
pair; it does not claim compatibility across a semantic-version range. An
unreleased shadow bundle binds the exact engine source commit, exact policy
source commit, rule-catalog schema/digest, and application artifact digest.

A clean, exact-bound unreleased bundle may inspect a real consumer only through
an explicitly requested, repository-read-only, non-authoritative
`CSharpShadow` run. It cannot be installed as the managed consumer integration,
act as a required or merge-blocking check, perform adoption or update, replace
the PowerShell result, or authorize mutation. A dirty or ambiguous
engine/policy source cannot create a shadow result.

An immutable application release binds the same identities in its manifest.
Only a released bundle may be referenced by a persistent managed consumer
workflow and it is the minimum artifact eligibility for any future required
check. It initially emits only `CSharpReleasedNonAuthoritative`; release alone
does not grant blocking or primary authority. Required-check enforcement and
authority transfer remain separately reviewed work owned by
[FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md).
The consumer pin must equal the release manifest's exact policy commit.

If a subject candidate changes policy-owning files relative to the selected
released policy, its result is `incomplete`; candidate-policy evaluation
requires a separately bound unreleased shadow bundle.

Do not apply current policy to an older consumer pin and do not infer
compatibility from semantic version ranges. Historical support may be added
later only through an explicit finite application-release/policy-commit table
with executable evidence.

### 4. Severity and enforcement

Each catalog entry declares two independent fields:

- `severity` uses the closed vocabulary `critical`, `high`, `medium`, `low`,
  and `info`; and
- `enforcement` is exactly `blocking` or `advisory`.

Severity describes impact and never implies enforcement. All violations of
currently canonical governance requirements remain `blocking` in v1.
Additional `advisory` observations may be reported, but they do not change an
otherwise `conforming` verdict to `nonconforming`. The caller cannot override
or downgrade catalog enforcement. A rule missing its canonical severity or
enforcement makes the report `incomplete` rather than silently choosing a
default.

### 5. Report digest

Compute SHA-256 over the exact canonical UTF-8-without-BOM semantic payload,
excluding `reportDigest` itself and the transport LF. Bind schema,
application, stage, profile, snapshot, policy, verdict, engine/authority
states, counts, and sorted findings. Do not bind timestamps, durations,
absolute paths, host data, or presentation-only transport bytes.

### 6. Process exit codes

| Exit code | Meaning |
| ---: | --- |
| `0` | Completed and `conforming` |
| `1` | Completed and `nonconforming` |
| `2` | Completed but `incomplete` |
| `64` | Rejected input or undeclared capability |
| `70` | Dependency or internal failure; no authoritative verdict |
| `130` | Canceled; no authoritative verdict |

Both `nonconforming` and `incomplete` are nonzero so local and hosted callers
cannot mistake them for a successful governance gate.

### 7. Candidate snapshot authority

Keep both `exact-commit` and `candidate` subject-repository snapshot modes.
This mode does not select or loosen the independently bound engine/policy
bundle from the preceding decision. Candidate subject results may be
`conforming`, `nonconforming`, or `incomplete`, but remain provisional
`CSharpShadow` evidence and never establish authority. A graph-relevant or
released-policy-owning candidate change yields `incomplete`; ambiguity or
capture drift yields a failed operation with no verdict. Authority comparison
requires committed HEAD evidence.

### 8. Provider boundary

Keep [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) and the
other wholly provider-owned identities outside the repository-only v1 engine
with reasoned `NotApplicable` ledger rows; split mixed local/provider
identities by material variant and retain
their existing external authority. General enumeration and content governance
for all issues, pull requests, and comments remains excluded pending the
maintainer's separately reserved discussion and authorization.

## Effect of acceptance

The maintainer accepted this bundle, including the exact-pair shadow/release
boundary and the separate severity/enforcement model, on 2026-07-28. That
initial acceptance completed the maintainer-contract readiness item without
authorizing executable work.

Later on 2026-07-28, the maintainer accepted the
[DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
sequencing amendment and explicitly authorized only the bounded first
clean-room `CSharpShadow` vertical slice. Canonical protocol, decision,
feature, and numbered-scenario contracts now design C# behavior; project memory
supports context only, and PowerShell may be used only as a later legacy
black-box oracle after independent implementation.

That first slice is [SUBF-0138](README.md#subf-0138) and reuses canonical
[TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004),
selects only `protocol-authority`, reads repository state, registers no provider
or mutation port, and emits no authoritative result. Its test first failed to
compile before production governance types existed, then passed after the
smallest implementation. Its Definition of Ready is 10/10 (100%);
[SUBF-0138](README.md#subf-0138) is locally complete, so feature implementation
is 1/8 (12.5%) while exact-commit/hosted and all broader gates remain pending.

The material-variant ledger, the 16 mixed-identity splits, and the complete
rule/profile/evidence-source matrix are no longer prerequisites for that
bounded implementation or an explicitly non-authoritative portable package.
They remain mandatory before equivalence or stronger-evidence claims,
required-check enforcement, authority transfer, compatibility retirement, or
PowerShell source retirement. This amendment does not change any accepted v1
request, identity, severity/enforcement, digest, exit-code, snapshot, provider,
or authority-state contract.
