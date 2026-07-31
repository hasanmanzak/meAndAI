# 2026-07-31 - [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) ContractSlice A canonical-string exact-red packet

## Status

[SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
is complete through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173),
exact main
[`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd),
and [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256).
The corrected
[ContractSlice A directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228)
is the only active implementation authority. The first limited ParseCanonical
increment is green; the second A canonical-string exact-red design is reviewed
and frozen, but its source and execution are pending.

[TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`. ContractSlice B/C/D, workflow/scenario-owner/
[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
activation, WIP extraction, consumer, release, publication, authority transfer,
and PowerShell retirement remain held.

## Exact red identity

The increment remains `TEST-0210` with traits `Scenario=TEST-0210` and
`ContractSlice=A`. It allocates no stable ID or public API.

```text
MeAndAI.Protocol.Conformance.Tests.ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding
TEST-0210-A-BEHAVIOR-RED-0002
TEST-0210-A-BEHAVIOR-RED-0002.trx
```

It is one `[Fact]` and inherits the accepted first A one-invocation, fresh
external directory, one-TRX, exact failed-result message, optional exact summary
echo, optional exact marker-free same-FQN RunInfo, and 16-counter oracle. Only
the complete legacy codec output below may call `Assert.Fail` with the marker.
Every other wrong output, exception, extra result, diagnostic, restore/build/
environment failure, or partial behavior change is marker-free invalid red.

## Writer-owned codec and exact bytes

`CanonicalManifestWriter` remains the only serializer owner. The internal seam
is `CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)`. Its pre-red
extraction is behavior-preserving: retain the legacy
`UnsafeRelaxedJsonEscaping` output and pass its one quoted UTF-8 token to
`Utf8JsonWriter.WriteRawValue` with validation enabled. The original 1,222-byte
fixture/digest remains byte-identical. This is structural preparation, not the
semantic green.

Exact probe UTF-16 units:

```text
0051 0022 005C 0008 000C 000A 000D 0009 001F 007F 0085 009F 3000 D842 DF9F
```

Exact legacy quoted-byte hex, and the sole marker-producing absent behavior:

```text
22515C225C5C5C625C665C6E5C725C745C75303031465C75303037465C75303038355C75303039465C75333030305C75443834325C754446394622
```

Exact bounded-green quoted-byte hex:

```text
22515C225C5C5C625C665C6E5C725C745C75303031665C75303037665C75303038355C7530303966E38080F0A0AE9F22
```

Quote/backslash use exact short escapes and slash is raw. The five named C0
characters use `\b`, `\f`, `\n`, `\r`, and `\t`; remaining C0, `DEL`, and C1
use lowercase `\u00xx`; every other valid scalar is raw UTF-8 without
normalization. The exact non-normalization oracle keeps precomposed `é`
(`U+00E9`, raw value bytes `C3 A9`) distinct from decomposed `é`
(`U+0065 U+0301`, raw value bytes `65 CC 81`); neither form may be normalized
to the other. This contextual oracle does not change the marker probe above.

## Positive fixture and negative matrix

The positive fixture replaces only the minimal manifest's `assemblyName` with
`MeAndAI.Protocol.　Unicode.𠮟.Tests`. Its strict UTF-8 document including LF is
exactly 1,226 bytes and has SHA-256
`5195e1a4b36b8b57a96fbd774fb78c5d46878948f91ee597e66ef6f44821a928`.
Raw `E3 80 80` and `F0 A0 AE 9F` each occur exactly once; the parsed typed value
preserves both scalars.

The one test covers:

- exact quote, backslash, and raw slash;
- short named C0, lowercase remaining C0, and lowercase `DEL`/C1;
- raw/non-normalized printable scalars and the exact positive manifest;
- rejected escaped `U+3000` plus lower- and uppercase valid surrogate-pair
  alternatives;
- lowercase canonical control lexemes that pass lexical validation and reach
  the opaque factory, whose document-caused `ArgumentException` becomes public
  `FormatException`;
- uppercase hex, long-form named controls, and raw C1 rejected lexically before
  the factory;
- isolated-continuation, overlong, surrogate, truncated, and above-`U+10FFFF`
  raw UTF-8 rejected as `FormatException`;
- escaped lone high, lone low, reversed, and high-plus-ASCII surrogate forms
  rejected as `FormatException`; and
- malformed .NET UTF-16 passed directly to
  `CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)` rejected as
  `ArgumentException` because it is an internal argument boundary, not a parsed
  document.

`BoundedJsonReader.ReadString` captures the complete original quoted token as
the half-open byte slice `TokenStartIndex..BytesConsumed` from its private input.
It calls `Utf8JsonReader.GetString()` and catches only an
`InvalidOperationException` thrown by that call, translating that exception to
`FormatException`. It re-encodes the decoded value through the same
`CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)` used by the writer
and ordinal-compares all re-encoded bytes with the complete original quoted
token. A mismatch is `FormatException` before any typed factory. This comparison
is the only lexical-canonicality oracle; no second grammar, parser, escape
scanner, or allowlist is permitted.

`ParseCanonical` keeps the public taxonomy: malformed raw or escaped document
input is `FormatException`. A codec `ArgumentException` is translated only when
the codec call is processing a value decoded from that document; typed-factory
argument wrapping remains a separate document boundary. Direct malformed .NET
UTF-16 supplied to the codec remains `ArgumentException` and is never relabeled.
No exception-message or per-negative digest oracle is required.

## Continuation and holds

Proceed with each separately reviewed ContractSlice A increment one at a time:
create only that increment's reviewed source/preparation, capture and review its
exact filtered red, then implement the smallest bounded green for that exact
red. For this increment, that means the behavior-preserving codec extraction and
exact `0002` test first, followed only by the quoted-string codec and reader
canonicality comparison required by the matrix. Preserve the original fixture,
public export/friend/project/reference/package/lock graph, manifest schema/order/
resource/copy/digest behavior, and every earlier A green. No first-source
authorization survives as general authority; B/C/D remain held.

Transient red is not committed or pushed and receives no root, StructureOnly,
combined, hosted, workflow, or scenario-owner validation. After reviewed red,
the bounded green requires exact-FQN green, cumulative `ContractSlice=A`,
warning/error-free Release build, format, unchanged locks, and one fresh-diff
review. The unnumbered canonical-string coverage `Important` closes only when
the complete matrix and single-writer route are green. Preserve the user-owned
untracked `MeAndAI.Protocol.v3.ncrunchsolution.user` unchanged.

## Bounded green closure

The preceding sections preserve the packet's historical reviewed-red and
pending-continuation state. The increment subsequently completed without
broadening that contract. Its behavior-preserving seam predecessor retained the
exact old FQN and passed `1/1` at
`D:\Temp\meandai-test-0210-a-seam-1d7c48a903be4f31a6e2c59b708d4fa1\TEST-0210-A-SEAM-NOOP-0002.trx`.
The valid canonical BehaviorRed at
`D:\Temp\meandai-test-0210-a-8b7f24d6c19a4e03b5f1728a90c4d6e1\TEST-0210-A-BEHAVIOR-RED-0002.trx`
and the bounded production-source review each closed with `0 Blocking`,
`0 Important`, and `0 Minor`.

The original-oracle green, while the exact marker and legacy branch were still
present, passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-3c6d91a5e8f247b0a1c4d7e9f2b5a630\TEST-0210-A-GREEN-0002.trx`.
The marker and legacy branch were then removed; targeted source search confirmed
both absent. Final-source passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-5e2a7c91d4f84360b8e1a3c6f9072d54\TEST-0210-A-GREEN-FINAL-0002.trx`,
and cumulative `ContractSlice=A` passed `13/13` at
`D:\Temp\meandai-test-0210-a-cumulative-7a3e6d20f9514bc8a2d5e7f039c6b184\TEST-0210-A-GREEN-CUMULATIVE-0002.trx`.

Locked restore succeeded. The six lock SHA-256 fingerprints remain Domain
`03EEADC5...CB46`, Abstractions `D79FF118...F799`, Conformance
`20E6BA80...70E7`, Policy `C57F6AFA...4309`, Domain.Tests
`D2065F11...00BC`, and Conformance.Tests `BA8D8C65...16C0`. The standard
`dotnet format --verify-no-changes --no-restore`, `git diff --check`, and the
six-project Release build passed; the build reported zero warnings and zero
errors. A separate non-gating severity-info full scan exposed pre-existing flat-
namespace/informational backlog and suggestions, so no severity-info-clean claim
is made.

This bounded evidence closes the unnumbered canonical-string coverage and records
the completed `BASE-RECORDS` synchronization in this log.
`Important`. It does not complete ContractSlice A or [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210),
which remains `Planned`. No later A increment is active. Remaining A,
ContractSlice B/C/D, workflow/scenario-owner/
[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
root, combined, hosted, WIP extraction, consumer, release, publication,
authority-transfer, and PowerShell-retirement scopes remain held.
