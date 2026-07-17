[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$launcherPath = Join-Path $root 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force

$legacyTag = 'v0.9.2'
$legacySha = 'b56ea19adeb8b34848fdd5b1e70eaaed831bf81d'
$futureTag = 'v0.9.3'
$futureSha = 'c' * 40
$migrationPaths = @(
    'AGENTS.md',
    '.ai/memory/README.md',
    '.ai/memory/project.md',
    'docs/ideas/README.md',
    'docs/features/README.md',
    'docs/decisions/README.md',
    'docs/decisions/DEC-0001-pinned-meandai-submodule.md',
    'tests/Verify-MeAndAIAdoption.ps1'
)
$managedAssets = @(
    [pscustomobject]@{
        ConsumerPath = '.github/workflows/meandai-protocol-update.yml'
        TemplatePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
        TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    }
)
$failures = [System.Collections.Generic.List[string]]::new()
$tempRoots = [System.Collections.Generic.List[string]]::new()
$originalGitHubHost = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Get-GitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Test-ByteArrayEqual {
    param(
        [Parameter(Mandatory)][byte[]]$Left,
        [Parameter(Mandatory)][byte[]]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }
    return $true
}

function New-TempRoot {
    param([Parameter(Mandatory)][string]$Name)

    $path = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-v092-$Name-$([guid]::NewGuid().ToString('N'))"
    [IO.Directory]::CreateDirectory($path) | Out-Null
    $tempRoots.Add($path)
    return $path
}

function Invoke-TestGit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $Repository @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) }
}

function Set-TestGitIdentity {
    param([Parameter(Mandatory)][string]$Repository)

    foreach ($setting in @(
        @('user.name', 'meAndAI Test'),
        @('user.email', 'meandai-test@example.invalid'),
        @('commit.gpgsign', 'false'),
        @('core.autocrlf', 'false')
    )) {
        Invoke-TestGit -Repository $Repository -Arguments `
            @('config', $setting[0], $setting[1]) | Out-Null
    }
}

function Write-FixtureText {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][ValidateSet('LF', 'CRLF')][string]$Newline,
        [Parameter(Mandatory)][bool]$Bom
    )

    $path = Join-Path $Repository `
        ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    $normalized = $Text -replace "`r`n", "`n"
    if ($Newline -ceq 'CRLF') {
        $normalized = $normalized -replace "`n", "`r`n"
    }
    [IO.File]::WriteAllText($path, $normalized, [Text.UTF8Encoding]::new($Bom))
}

function Get-FixtureDefinitions {
    $definitions = [ordered]@{}
    $definitions['AGENTS.md'] = [pscustomobject]@{
        Newline = 'CRLF'; Bom = $false
        Text = @'
# Project Agent Instructions

These instructions apply to the consuming repository.

1. If `.ai/adoption/meandai-capabilities.json` exists, treat it as an active
   adoption handoff. Complete its project-specific tasks and remove the
   manifest before the pull request becomes ready or merges.
2. Read the local common protocol at `.ai/protocol/PROTOCOL.md`, pinned from
   [meAndAI v0.9.2](https://github.com/hasanmanzak/meAndAI/blob/v0.9.2/PROTOCOL.md).
3. Read this project's `.ai/memory/README.md`.
4. Read the relevant project-owned feature and decision documents before work.
5. Apply project-specific rules below. A relaxation of the common protocol
   requires a numbered project decision.

## Project-specific rules

- Product purpose: Not yet established.
- Runtime and stack: Not yet established.
- Architecture: Not yet established.
- Product build command: Not yet established.
- Product test command: Not yet established.
- Keep Derdini-specific facts outside the protocol checkout.
'@
        Required = @('.ai/protocol', 'gitlink', 'VERSION')
        Preserved = @('Product purpose: Not yet established.', 'Keep Derdini-specific facts outside the protocol checkout.')
    }
    $definitions['.ai/memory/README.md'] = [pscustomobject]@{
        Newline = 'LF'; Bom = $true
        Text = @'
# Project-local AI Memory

Scope: **Derdini**<br>
Last reviewed: **2026-07-17**<br>
Pinned common protocol: **0.9.2**

This memory belongs only to this consuming project. Read
[project.md](project.md), then the newest relevant record in
[log](log/README.md).

## Rules

- Store verified durable facts, explicit collaboration constraints, and concise
  dated handoffs.
- Link to canonical project features, decisions, issues, pull requests, tests,
  and evidence.
- Mark assumptions and stale facts.
- Never store secrets, raw chat, or unrelated project details.
'@
        Required = @('.ai/protocol', 'VERSION', 'separately maintained live fact')
        Preserved = @('Scope: **Derdini**', 'Never store secrets, raw chat, or unrelated project details.')
    }
    $definitions['.ai/memory/project.md'] = [pscustomobject]@{
        Newline = 'CRLF'; Bom = $true
        Text = @'
# Project Snapshot

Last verified: **2026-07-17**

## Verified facts

- Repository: [hasanmanzak/Derdini](https://github.com/hasanmanzak/Derdini)
- Purpose: Not yet established.
- Runtime and stack: Not yet established.
- Default branch: `main` (verified from the local repository baseline).
- Pinned common protocol: [meAndAI 0.9.2 at `b56ea19adeb8b34848fdd5b1e70eaaed831bf81d`](https://github.com/hasanmanzak/meAndAI/tree/b56ea19adeb8b34848fdd5b1e70eaaed831bf81d)
- Build command: Not yet established.
- Product test command: Not yet established.
- Adoption verification: `powershell -NoProfile -File tests/Verify-MeAndAIAdoption.ps1`

## Collaboration constraints

- Keep credentials and secret values out of repository content and memory.
- Preserve Derdini's unknown product facts until a reviewed decision establishes them.
'@
        Required = @('.ai/protocol', 'VERSION', 'Do not copy')
        Preserved = @('Repository: [hasanmanzak/Derdini]', 'Preserve Derdini''s unknown product facts')
    }
    $definitions['docs/ideas/README.md'] = [pscustomobject]@{
        Newline = 'LF'; Bom = $false
        Text = @'
# Idea Index

Ideas preserve worthwhile possibilities before maintainers authorize delivery.
They are not work items and do not satisfy Definition of Ready.

| ID | Idea | Status | Promoted record |
| --- | --- | --- | --- |

Allowed statuses are `Exploring`, `Parked`, `Promoted`, and `Rejected`.
Terminal records remain in this index with their rationale and links.

For a submodule consumer, create records from
`.ai/protocol/templates/idea.md`; the pinned canonical source is the
[meAndAI v0.9.2 idea template](https://github.com/hasanmanzak/meAndAI/blob/v0.9.2/templates/idea.md).
A repository-reference consumer resolves the same template from its configured
immutable protocol ref. Allocate each new record as repository-local
`IDEA-NNNN`.
'@
        Required = @('../../.ai/protocol/templates/idea.md', 'gitlink')
        Preserved = @('Ideas preserve worthwhile possibilities', 'Allocate each new record as repository-local')
    }
    $definitions['docs/features/README.md'] = [pscustomobject]@{
        Newline = 'CRLF'; Bom = $false
        Text = @'
# Feature Index

| ID | Feature | Status | Version |
| --- | --- | --- | --- |
| [FEAT-0001](FEAT-0001-meandai-capabilities-adoption/README.md) | Adopt meAndAI AI capabilities | Complete | Not yet established |

Create future feature records from the pinned protocol's
[feature template](https://github.com/hasanmanzak/meAndAI/blob/b56ea19adeb8b34848fdd5b1e70eaaed831bf81d/templates/feature/README.md).
'@
        Required = @('../../.ai/protocol/templates/feature/README.md', 'gitlink')
        Preserved = @('[FEAT-0001](FEAT-0001-meandai-capabilities-adoption/README.md)', 'Not yet established')
    }
    $definitions['docs/decisions/README.md'] = [pscustomobject]@{
        Newline = 'LF'; Bom = $true
        Text = @'
# Decision Index

| ID | Decision | Status | Date |
| --- | --- | --- | --- |
| [DEC-0001](DEC-0001-pinned-meandai-submodule.md) | Pin meAndAI as a Git submodule | Accepted | 2026-07-17 |

Create future decision records from the pinned protocol's
[decision template](https://github.com/hasanmanzak/meAndAI/blob/b56ea19adeb8b34848fdd5b1e70eaaed831bf81d/templates/decision.md).
'@
        Required = @('../../.ai/protocol/templates/decision.md', 'gitlink')
        Preserved = @('[DEC-0001](DEC-0001-pinned-meandai-submodule.md)', 'Accepted | 2026-07-17')
    }
    $definitions['docs/decisions/DEC-0001-pinned-meandai-submodule.md'] = [pscustomobject]@{
        Newline = 'CRLF'; Bom = $false
        Text = @'
# DEC-0001 - Pin meAndAI as a Git submodule

- Classification: Decision
- Status: Accepted
- Date: 2026-07-17
- Decision owners: Derdini maintainers
- Related features: [FEAT-0001](../features/FEAT-0001-meandai-capabilities-adoption/README.md)
- Related decisions: None

## Context

Derdini needs an immutable common development protocol while retaining
project-owned instructions, memory, planning records, and evidence. The
repository currently has no established product stack or architecture, so the
integration must not imply product choices.

## Decision

Reference `hasanmanzak/meAndAI` at exactly
`b56ea19adeb8b34848fdd5b1e70eaaed831bf81d` as the `.ai/protocol` Git
submodule. Keep consumer memory, feature and decision records, tests, and
tracking templates outside that submodule. Use the installed, consumer-owned
lifecycle workflow for reviewed compatible update proposals.

## Consequences

- The common protocol is immutable for a given consumer revision.
- A clone must initialize submodules to read `.ai/protocol/PROTOCOL.md` locally.
- Project facts remain independently maintainable and cannot be overwritten by
  the protocol updater.
- Product technology and behavior remain undecided.

## Review condition

Review if the hosting platform can no longer initialize the pinned submodule.
'@
        Required = @('.ai/protocol', 'VERSION', 'gitlink')
        Preserved = @('Derdini needs an immutable common development protocol', 'Product technology and behavior remain undecided.')
    }
    $definitions['tests/Verify-MeAndAIAdoption.ps1'] = [pscustomobject]@{
        Newline = 'LF'; Bom = $false
        Text = @'
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSha = 'b56ea19adeb8b34848fdd5b1e70eaaed831bf81d'
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { $failures.Add($Message) }
}

$stage = & git -C $root ls-files --stage -- .ai/protocol
Assert-True ($LASTEXITCODE -eq 0) 'TEST-0001: git index inspection failed.'
Assert-True ($stage -match "^160000 $expectedSha 0\s+\.ai/protocol$") 'TEST-0001: protocol gitlink mode or commit differs.'
$modules = Get-Content -Raw (Join-Path $root '.gitmodules')
Assert-True ($modules -match '(?m)^\s*path = \.ai/protocol\s*$') 'TEST-0001: submodule path is missing.'
Assert-True ($modules -match '(?m)^\s*url = https://github\.com/hasanmanzak/meAndAI\.git\s*$') 'TEST-0001: canonical submodule URL is missing.'

$instructions = Get-Content -Raw (Join-Path $root 'AGENTS.md')
$memory = Get-Content -Raw (Join-Path $root '.ai/memory/project.md')
$lineEndingVariants = @(
    [pscustomobject]@{ Name = 'LF'; Value = "`n" }
    [pscustomobject]@{ Name = 'CRLF'; Value = "`r`n" }
)
foreach ($label in @('Product purpose', 'Runtime and stack', 'Architecture', 'Product build command', 'Product test command')) {
    $pattern = "(?m)^- $([regex]::Escape($label)):\s+Not yet established\.\r?$"
    foreach ($variant in $lineEndingVariants) {
        $fixture = "- ${label}: Not yet established.$($variant.Value)"
        Assert-True ($fixture -match $pattern) "TEST-0003: AGENTS.md pattern rejects the $($variant.Name) variant for '$label'."
    }
    Assert-True ($instructions -match $pattern) "TEST-0003: AGENTS.md does not preserve unknown '$label'."
}
foreach ($label in @('Purpose', 'Runtime and stack', 'Build command', 'Product test command')) {
    $pattern = "(?m)^- $([regex]::Escape($label)):\s+Not yet established\.\r?$"
    foreach ($variant in $lineEndingVariants) {
        $fixture = "- ${label}: Not yet established.$($variant.Value)"
        Assert-True ($fixture -match $pattern) "TEST-0003: project-memory pattern rejects the $($variant.Name) variant for '$label'."
    }
    Assert-True ($memory -match $pattern) "TEST-0003: project memory does not preserve unknown '$label'."
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'PASS: TEST-0001 protocol identity'
Write-Output 'PASS: TEST-0003 unknown product facts remain explicit'
'@
        Required = @('.ai/protocol/VERSION', 'ls-files', '160000')
        Forbidden = @('$expectedSha')
        Preserved = @('lineEndingVariants', 'unknown product facts remain explicit')
    }
    return $definitions
}

function Get-ExpectedMigrationFragments {
    # This is an independent black-box oracle. It deliberately does not parse
    # or invoke the launcher's private migration definitions.
    $fragments = [ordered]@{}
    $fragments['AGENTS.md'] = [pscustomobject]@{
        Legacy = @'
2. Read the local common protocol at `.ai/protocol/PROTOCOL.md`, pinned from
   [meAndAI v0.9.2](https://github.com/hasanmanzak/meAndAI/blob/v0.9.2/PROTOCOL.md).
'@
        Neutral = @'
2. Read the [local common protocol](.ai/protocol/PROTOCOL.md) from the pinned
   `.ai/protocol` gitlink. Resolve its current version from
   [the checkout's `VERSION`](.ai/protocol/VERSION); do not duplicate a literal
   current tag or commit in consumer-owned instructions or records.
'@
    }
    $fragments['.ai/memory/README.md'] = [pscustomobject]@{
        Legacy = 'Pinned common protocol: **0.9.2**'
        Neutral = @'
The common-protocol authority is the repository's `.ai/protocol` gitlink and
the `VERSION` inside that exact checkout. Do not copy either value into memory
as a separately maintained live fact.
'@
    }
    $fragments['.ai/memory/project.md'] = [pscustomobject]@{
        Legacy = "- Pinned common protocol: [meAndAI 0.9.2 at ``$legacySha``](https://github.com/hasanmanzak/meAndAI/tree/$legacySha)"
        Neutral = @'
- Common protocol integration authority: the `.ai/protocol` gitlink supplies
  the current commit and the `VERSION` inside that exact checkout supplies its
  canonical version. Do not copy a live tag or SHA.
'@
    }
    $fragments['docs/ideas/README.md'] = [pscustomobject]@{
        Legacy = @'
For a submodule consumer, create records from
`.ai/protocol/templates/idea.md`; the pinned canonical source is the
[meAndAI v0.9.2 idea template](https://github.com/hasanmanzak/meAndAI/blob/v0.9.2/templates/idea.md).
'@
        Neutral = @'
For a submodule consumer, create records from the
[pinned canonical idea template](../../.ai/protocol/templates/idea.md). The
consumer's gitlink selects its exact version; do not copy that tag or commit
into this index as a live fact.
'@
    }
    $fragments['docs/features/README.md'] = [pscustomobject]@{
        Legacy = @"
Create future feature records from the pinned protocol's
[feature template](https://github.com/hasanmanzak/meAndAI/blob/$legacySha/templates/feature/README.md).
"@
        Neutral = @'
Create future feature records from the pinned protocol's
[feature template](../../.ai/protocol/templates/feature/README.md). The
consumer gitlink and its checked-out `VERSION` select the current identity.
'@
    }
    $fragments['docs/decisions/README.md'] = [pscustomobject]@{
        Legacy = @"
Create future decision records from the pinned protocol's
[decision template](https://github.com/hasanmanzak/meAndAI/blob/$legacySha/templates/decision.md).
"@
        Neutral = @'
Create future decision records from the pinned protocol's
[decision template](../../.ai/protocol/templates/decision.md). The consumer
gitlink and its checked-out `VERSION` select the current identity.
'@
    }
    $fragments['docs/decisions/DEC-0001-pinned-meandai-submodule.md'] = [pscustomobject]@{
        Legacy = @"
Reference ``hasanmanzak/meAndAI`` at exactly
``$legacySha`` as the ``.ai/protocol`` Git
submodule. Keep consumer memory, feature and decision records, tests, and
tracking templates outside that submodule. Use the installed, consumer-owned
lifecycle workflow for reviewed compatible update proposals.
"@
        Neutral = @'
Reference `hasanmanzak/meAndAI` through the `.ai/protocol` Git submodule. In
each consumer revision, the `160000` gitlink supplies the exact protocol commit
and the `VERSION` file inside that checkout supplies its canonical version.
Keep consumer memory, feature and decision records, tests, and tracking
templates outside that submodule. Use the installed, consumer-owned lifecycle
workflow for reviewed compatible update proposals.
'@
    }
    $fragments['tests/Verify-MeAndAIAdoption.ps1'] = [pscustomobject]@{
        Legacy = @"
`$expectedSha = '$legacySha'
`$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]`$Condition, [string]`$Message) {
    if (-not `$Condition) { `$failures.Add(`$Message) }
}

`$stage = & git -C `$root ls-files --stage -- .ai/protocol
Assert-True (`$LASTEXITCODE -eq 0) 'TEST-0001: git index inspection failed.'
Assert-True (`$stage -match "^160000 `$expectedSha 0\s+\.ai/protocol`$") 'TEST-0001: protocol gitlink mode or commit differs.'
"@
        Neutral = @'
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { $failures.Add($Message) }
}

$stage = & git -C $root ls-files --stage -- .ai/protocol
Assert-True ($LASTEXITCODE -eq 0) 'TEST-0001: git index inspection failed.'
$stageMatch = [regex]::Match(
    (@($stage) -join "`n"),
    '^160000 (?<sha>[0-9a-f]{40}) 0\s+\.ai/protocol$',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
Assert-True $stageMatch.Success 'TEST-0001: protocol gitlink mode or commit differs.'
$protocolSha = if ($stageMatch.Success) {
    [string]$stageMatch.Groups['sha'].Value
}
else { '' }

$protocolVersionPath = Join-Path $root '.ai/protocol/VERSION'
$protocolVersionExists = Test-Path -LiteralPath $protocolVersionPath -PathType Leaf
Assert-True $protocolVersionExists 'TEST-0001: protocol VERSION is missing.'
if ($protocolVersionExists) {
    $protocolVersion = [IO.File]::ReadAllText($protocolVersionPath).Trim()
    Assert-True ($protocolVersion -match '^(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$') 'TEST-0001: protocol VERSION is not canonical M.m.rev.'
}

$protocolCheckout = Join-Path $root '.ai/protocol'
if (Test-Path -LiteralPath $protocolCheckout -PathType Container) {
    $protocolHead = & git -C $protocolCheckout rev-parse HEAD
    Assert-True ($LASTEXITCODE -eq 0) 'TEST-0001: initialized protocol checkout could not be inspected.'
    if ($LASTEXITCODE -eq 0 -and $protocolSha) {
        Assert-True (((@($protocolHead) -join '').Trim()) -ceq $protocolSha) 'TEST-0001: initialized protocol checkout differs from the gitlink.'
    }
}
'@
    }

    foreach ($fragment in $fragments.Values) {
        $fragment.Legacy = ([string]$fragment.Legacy).TrimEnd("`r", "`n").Replace("`r`n", "`n")
        $fragment.Neutral = ([string]$fragment.Neutral).TrimEnd("`r", "`n").Replace("`r`n", "`n")
    }
    return $fragments
}

function ConvertFrom-TestUtf8Bytes {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $hasBom = $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and
        $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF
    $offset = if ($hasBom) { 3 } else { 0 }
    $text = [Text.UTF8Encoding]::new($false, $true).GetString(
        $Bytes, $offset, $Bytes.Length - $offset
    )
    $hasCrLf = $text.Contains("`r`n")
    return [pscustomobject]@{
        HasBom = $hasBom
        NewLine = if ($hasCrLf) { "`r`n" } else { "`n" }
        NormalizedText = $text.Replace("`r`n", "`n")
    }
}

function ConvertTo-TestUtf8Bytes {
    param(
        [Parameter(Mandatory)][string]$NormalizedText,
        [Parameter(Mandatory)][string]$NewLine,
        [Parameter(Mandatory)][bool]$HasBom
    )

    $text = if ($NewLine -ceq "`r`n") {
        $NormalizedText.Replace("`n", "`r`n")
    }
    else { $NormalizedText }
    $body = [Text.UTF8Encoding]::new($false, $true).GetBytes($text)
    if (-not $HasBom) { return $body }
    $bytes = [byte[]]::new($body.Length + 3)
    $bytes[0] = 0xEF; $bytes[1] = 0xBB; $bytes[2] = 0xBF
    [Array]::Copy($body, 0, $bytes, 3, $body.Length)
    return $bytes
}

function Get-ExpectedMigratedBytes {
    param(
        [Parameter(Mandatory)][byte[]]$OriginalBytes,
        [Parameter(Mandatory)]$Fragment
    )

    $decoded = ConvertFrom-TestUtf8Bytes -Bytes $OriginalBytes
    $legacy = [string]$Fragment.Legacy
    $firstIndex = $decoded.NormalizedText.IndexOf(
        $legacy, [StringComparison]::Ordinal
    )
    $secondIndex = if ($firstIndex -ge 0) {
        $decoded.NormalizedText.IndexOf(
            $legacy, $firstIndex + $legacy.Length, [StringComparison]::Ordinal
        )
    }
    else { -1 }
    if ($firstIndex -lt 0 -or $secondIndex -ge 0) {
        throw 'Independent migration oracle did not find exactly one legacy fragment.'
    }
    $updated = $decoded.NormalizedText.Replace($legacy, [string]$Fragment.Neutral)
    return ConvertTo-TestUtf8Bytes -NormalizedText $updated `
        -NewLine $decoded.NewLine -HasBom ([bool]$decoded.HasBom)
}

function Set-NormalizedFixtureText {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$Transform
    )

    $original = [IO.File]::ReadAllBytes($Path)
    $decoded = ConvertFrom-TestUtf8Bytes -Bytes $original
    $updated = & $Transform ([string]$decoded.NormalizedText)
    $bytes = ConvertTo-TestUtf8Bytes -NormalizedText ([string]$updated) `
        -NewLine $decoded.NewLine -HasBom ([bool]$decoded.HasBom)
    [IO.File]::WriteAllBytes($Path, $bytes)
}

function Get-HistoricalDefinitions {
    return [ordered]@{
        '.ai/memory/log/2026-07-17-meandai-adoption.md' = @'
# 2026-07-17 - meAndAI capabilities adoption

The repository adopted meAndAI protocol 0.9.2 through the exact Git submodule
commit `b56ea19adeb8b34848fdd5b1e70eaaed831bf81d`. This dated evidence must remain.
'@
        'docs/features/FEAT-0001-meandai-capabilities-adoption/README.md' = @'
# FEAT-0001 - Adopt meAndAI AI capabilities

The completed historical outcome was adoption of the exact meAndAI 0.9.2 pin
at `b56ea19adeb8b34848fdd5b1e70eaaed831bf81d` without invented product facts.
'@
    }
}

function Initialize-ProtocolSnapshots {
    $snapshotRoot = New-TempRoot -Name 'protocol-snapshots'
    $archivePath = Join-Path $snapshotRoot 'v0.9.2.zip'
    $extractPath = Join-Path $snapshotRoot 'v0.9.2'
    [IO.Directory]::CreateDirectory($extractPath) | Out-Null
    $paths = @($managedAssets | ForEach-Object { [string]$_.TemplatePath })
    $archive = Invoke-TestGit -Repository $root -Arguments `
        (@('archive', '--format=zip', "--output=$archivePath", $legacyTag, '--') + $paths) `
        -AllowFailure
    if ($archive.ExitCode -ne 0) {
        throw "Unable to archive the immutable $legacyTag test fixture."
    }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force

    $global:V092ProtocolAssets = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($asset in $managedAssets) {
        $path = Join-Path $extractPath `
            (([string]$asset.TemplatePath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $bytes = [IO.File]::ReadAllBytes($path)
        $global:V092ProtocolAssets.Add(
            "$legacyTag`n$($asset.TemplatePath)",
            [pscustomobject]@{ Bytes = $bytes; Sha = Get-GitBlobSha -Bytes $bytes }
        )
    }

    $futureWorkflow = Join-Path $root `
        'templates/project/.github/workflows/meandai-protocol-update.yml'
    $futureBytes = [IO.File]::ReadAllBytes($futureWorkflow)
    $global:V092ProtocolAssets.Add(
        "$futureTag`ntemplates/project/.github/workflows/meandai-protocol-update.yml",
        [pscustomobject]@{
            Bytes = $futureBytes
            Sha = Get-GitBlobSha -Bytes $futureBytes
        }
    )
    $global:V092ProtocolCommits = @{
        $legacyTag = $legacySha
        $futureTag = $futureSha
    }
}

function New-LegacyConsumerFixture {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$DriftOneFragment
    )

    $fixtureRoot = New-TempRoot -Name $Name
    $repository = Join-Path $fixtureRoot 'consumer'
    $remote = Join-Path $fixtureRoot 'consumer.git'
    [IO.Directory]::CreateDirectory($repository) | Out-Null
    & git init --bare $remote 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Unable to initialize fixture remote.' }
    & git init -b main $repository 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Unable to initialize fixture consumer.' }
    Set-TestGitIdentity -Repository $repository

    $slug = "test-owner/$Name"
    Invoke-TestGit -Repository $repository -Arguments @(
        'config', "url.$($remote.Replace('\', '/')).insteadOf",
        "https://github.com/$slug.git"
    ) | Out-Null
    Invoke-TestGit -Repository $repository -Arguments @(
        'remote', 'add', 'origin', "https://github.com/$slug.git"
    ) | Out-Null

    Write-FixtureText -Repository $repository -RelativePath '.gitattributes' `
        -Text "* -text`n" -Newline LF -Bom $false
    Write-FixtureText -Repository $repository -RelativePath '.gitmodules' `
        -Text @'
[submodule ".ai/protocol"]
	path = .ai/protocol
	url = https://github.com/hasanmanzak/meAndAI.git
'@ -Newline LF -Bom $false

    $definitions = Get-FixtureDefinitions
    foreach ($path in $migrationPaths) {
        $definition = $definitions[$path]
        $text = [string]$definition.Text
        if ($DriftOneFragment -and $path -ceq 'AGENTS.md') {
            $text = $text.Replace(
                '[meAndAI v0.9.2](https://github.com/hasanmanzak/meAndAI/blob/v0.9.2/PROTOCOL.md)',
                '[meAndAI v0.9.2 drifted](https://github.com/hasanmanzak/meAndAI/blob/v0.9.2/PROTOCOL.md)'
            )
        }
        $commentPrefix = if ($path.EndsWith('.ps1', [StringComparison]::Ordinal)) {
            '#'
        }
        else { '<!--' }
        $commentSuffix = if ($commentPrefix -ceq '#') { '' } else { ' -->' }
        $sentinel = "$commentPrefix meandai-v092-unrelated:$path:cafe$commentSuffix"
        $text = $text.TrimEnd("`r", "`n") + "`n`n$sentinel`n"
        Write-FixtureText -Repository $repository -RelativePath $path `
            -Text $text -Newline ([string]$definition.Newline) `
            -Bom ([bool]$definition.Bom)
    }

    $historical = Get-HistoricalDefinitions
    foreach ($entry in $historical.GetEnumerator()) {
        Write-FixtureText -Repository $repository -RelativePath ([string]$entry.Key) `
            -Text ([string]$entry.Value) -Newline LF -Bom $false
    }

    foreach ($asset in $managedAssets) {
        $snapshot = $global:V092ProtocolAssets["$legacyTag`n$($asset.TemplatePath)"]
        $destination = Join-Path $repository `
            (([string]$asset.ConsumerPath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
        [IO.File]::WriteAllBytes($destination, [byte[]]$snapshot.Bytes)
    }

    Invoke-TestGit -Repository $repository -Arguments @('add', '--', '.') | Out-Null
    Invoke-TestGit -Repository $repository -Arguments @(
        'update-index', '--add', '--cacheinfo', "160000,$legacySha,.ai/protocol"
    ) | Out-Null
    Invoke-TestGit -Repository $repository -Arguments @(
        'commit', '-m', "Install real-shaped meAndAI $legacyTag consumer"
    ) | Out-Null
    Invoke-TestGit -Repository $repository -Arguments @('push', '-u', 'origin', 'main') | Out-Null
    Invoke-TestGit -Repository $repository -Arguments @(
        'config', 'submodule..ai/protocol.url', $root.Replace('\', '/')
    ) | Out-Null
    Invoke-TestGit -Repository $repository -Arguments @(
        '-c', 'protocol.file.allow=always',
        'submodule', 'update', '--init', '--', '.ai/protocol'
    ) | Out-Null

    $status = @(Invoke-TestGit -Repository $repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ }
    if ($status.Count -ne 0) {
        throw "Legacy consumer fixture is not clean: $($status -join ', ')"
    }

    return [pscustomobject]@{
        Repository = $repository
        Remote = $remote
        Slug = $slug
        Definitions = $definitions
        HistoricalPaths = @($historical.Keys)
    }
}

function Publish-FixtureChange {
    param(
        [Parameter(Mandatory)]$Fixture,
        [Parameter(Mandatory)][string[]]$Paths,
        [Parameter(Mandatory)][string]$Message
    )

    Invoke-TestGit -Repository $Fixture.Repository `
        -Arguments (@('add', '--') + $Paths) | Out-Null
    Invoke-TestGit -Repository $Fixture.Repository -Arguments @(
        'commit', '-m', $Message
    ) | Out-Null
    Invoke-TestGit -Repository $Fixture.Repository -Arguments @(
        'push', 'origin', 'main'
    ) | Out-Null
}

function Set-TestWriteDenied {
    param([Parameter(Mandatory)][string]$Path)

    if ($env:OS -eq 'Windows_NT') {
        $attributes = [IO.File]::GetAttributes($Path)
        [IO.File]::SetAttributes($Path, $attributes -bor [IO.FileAttributes]::ReadOnly)
        return [pscustomobject]@{
            Supported = $true
            Kind = 'WindowsAttributes'
            Value = $attributes
        }
    }

    $modeResult = & chmod a-w -- $Path 2>&1
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{ Supported = $false; Kind = ''; Value = $null }
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $denied = $false
    try { [IO.File]::WriteAllBytes($Path, $bytes) }
    catch [UnauthorizedAccessException] { $denied = $true }
    if (-not $denied) {
        & chmod u+w -- $Path 2>&1 | Out-Null
        return [pscustomobject]@{ Supported = $false; Kind = ''; Value = $null }
    }
    return [pscustomobject]@{
        Supported = $true
        Kind = 'UnixPermission'
        Value = $null
    }
}

function Restore-TestWritePermission {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$State
    )

    if (-not [bool]$State.Supported) { return }
    if ([string]$State.Kind -ceq 'WindowsAttributes') {
        [IO.File]::SetAttributes($Path, [IO.FileAttributes]$State.Value)
    }
    else {
        & chmod u+w -- $Path 2>&1 | Out-Null
    }
}

function Get-PathBytes {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Paths
    )

    $snapshot = [ordered]@{}
    foreach ($path in $Paths) {
        $fullPath = Join-Path $Repository `
            ($path -replace '/', [IO.Path]::DirectorySeparatorChar)
        $snapshot[$path] = [IO.File]::ReadAllBytes($fullPath)
    }
    return $snapshot
}

function Get-PathHashes {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Paths
    )

    $snapshot = Get-PathBytes -Repository $Repository -Paths $Paths
    $hashes = [ordered]@{}
    foreach ($path in $Paths) {
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $hashes[$path] = ([BitConverter]::ToString(
                $sha.ComputeHash([byte[]]$snapshot[$path])
            )).Replace('-', '').ToLowerInvariant()
        }
        finally { $sha.Dispose() }
    }
    return $hashes
}

function Test-ExactPathSet {
    param([object[]]$Actual, [object[]]$Expected)

    if ($Actual.Count -ne $Expected.Count) { return $false }
    $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($path in $Expected) {
        if (-not $set.Add([string]$path)) { return $false }
    }
    foreach ($path in $Actual) {
        if (-not $set.Remove([string]$path)) { return $false }
    }
    return $set.Count -eq 0
}

function Test-EnvelopePreserved {
    param(
        [Parameter(Mandatory)][byte[]]$Before,
        [Parameter(Mandatory)][byte[]]$After,
        [Parameter(Mandatory)][ValidateSet('LF', 'CRLF')][string]$Newline,
        [Parameter(Mandatory)][bool]$Bom
    )

    $beforeBom = $Before.Length -ge 3 -and $Before[0] -eq 0xEF -and
        $Before[1] -eq 0xBB -and $Before[2] -eq 0xBF
    $afterBom = $After.Length -ge 3 -and $After[0] -eq 0xEF -and
        $After[1] -eq 0xBB -and $After[2] -eq 0xBF
    if ($beforeBom -ne $Bom -or $afterBom -ne $Bom) { return $false }

    $text = [Text.UTF8Encoding]::new($false, $true).GetString($After)
    if ($Newline -ceq 'CRLF') {
        return -not [regex]::IsMatch($text, '(?<!\r)\n')
    }
    return -not $text.Contains("`r`n")
}

function Invoke-MigrationLauncher {
    param([Parameter(Mandatory)][string]$Repository)

    try {
        & $launcherPath -TargetPath $Repository -ProtocolTag $legacyTag `
            -MigrateV092LivePins -NoProgress 6>&1 | Out-Null
        return [pscustomobject]@{ Succeeded = $true; Message = '' }
    }
    catch {
        return [pscustomobject]@{
            Succeeded = $false
            Message = [string]$_.Exception.Message
        }
    }
}

function Invoke-CompatibleUpdateLauncher {
    param([Parameter(Mandatory)][string]$Repository)

    try {
        & $launcherPath -TargetPath $Repository -ProtocolTag $futureTag `
            -NoProgress -WorkflowTimeoutMinutes 1 6>&1 | Out-Null
        return [pscustomobject]@{ Succeeded = $true; Message = '' }
    }
    catch {
        return [pscustomobject]@{
            Succeeded = $false
            Message = [string]$_.Exception.Message
        }
    }
}

function Test-GhMutationCall {
    param([Parameter(Mandatory)]$Call)

    $arguments = @($Call.Arguments)
    if ($arguments.Count -eq 0) { return $false }
    if ($arguments[0] -cin @('label', 'secret', 'workflow', 'issue', 'pr')) {
        return $true
    }
    return $arguments[0] -ceq 'api' -and $arguments -ccontains '--method'
}

function global:gh {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline = $true)][string]$InputValue,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )

    $global:LASTEXITCODE = 0
    $global:V092GhCalls.Add([pscustomobject]@{
        Phase = $global:V092Phase
        Arguments = @($Arguments)
    })
    $joined = $Arguments -join ' '
    if ($joined -ceq '--version') { return 'gh version 2.82.1 (mock)' }
    if ($joined -ceq 'auth status') { return }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'repo' -and
        $Arguments[1] -ceq 'view') {
        return (@{
            nameWithOwner = $global:V092ConsumerSlug
            defaultBranchRef = @{ name = 'main' }
        } | ConvertTo-Json -Compress)
    }

    $endpoint = @($Arguments | Where-Object {
        [string]$_ -clike 'repos/*'
    } | Select-Object -Last 1)
    if ($endpoint.Count -eq 1 -and
        [string]$endpoint[0] -match '^repos/hasanmanzak/meAndAI/releases/tags/(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        $tag = [string]$Matches.tag
        return (@{
            tag_name = $tag
            draft = $false
            prerelease = $false
            immutable = $true
            published_at = '2026-07-17T00:00:00Z'
        } | ConvertTo-Json -Compress)
    }
    if ($endpoint.Count -eq 1 -and
        [string]$endpoint[0] -match '^repos/hasanmanzak/meAndAI/commits/(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        $tag = [string]$Matches.tag
        if (-not $global:V092ProtocolCommits.ContainsKey($tag)) {
            throw "Unexpected mock protocol tag '$tag'."
        }
        return (@{ sha = [string]$global:V092ProtocolCommits[$tag] } |
            ConvertTo-Json -Compress)
    }
    if ($endpoint.Count -eq 1 -and
        [string]$endpoint[0] -match '^repos/hasanmanzak/meAndAI/contents/(?<path>.+)\?ref=(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        $key = "$([string]$Matches.tag)`n$([string]$Matches.path)"
        if (-not $global:V092ProtocolAssets.ContainsKey($key)) {
            throw "Unexpected mock protocol asset '$key'."
        }
        $asset = $global:V092ProtocolAssets[$key]
        return (@{
            content = [Convert]::ToBase64String([byte[]]$asset.Bytes)
            encoding = 'base64'
            sha = [string]$asset.Sha
        } | ConvertTo-Json -Compress)
    }

    if ($global:V092Phase -ceq 'migration') {
        throw "TEST-0119 migration crossed its local-only boundary: gh $joined"
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -ceq 'label' -and
        $Arguments[1] -ceq 'create') {
        $descriptionIndex = [Array]::IndexOf([object[]]$Arguments, '--description')
        $global:V092Lock = [pscustomobject]@{
            name = [string]$Arguments[2]
            description = [string]$Arguments[$descriptionIndex + 1]
        }
        return
    }
    if ($endpoint.Count -eq 1 -and
        [string]$endpoint[0] -clike "repos/$($global:V092ConsumerSlug)/labels/*") {
        if ($Arguments -ccontains '--method') {
            $global:V092Lock = $null
            return
        }
        return ($global:V092Lock | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'secret' -and
        $Arguments[1] -ceq 'list') {
        return (@(
            @{ name = 'MEANDAI_UPDATER_TOKEN' },
            @{ name = 'MEANDAI_PROTOCOL_TOKEN' }
        ) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'workflow' -and
        $Arguments[1] -ceq 'view') {
        return 'name: meAndAI AI Capabilities Lifecycle'
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'run' -and
        $Arguments[1] -ceq 'list') {
        if (-not $global:V092CorrelationId) { return '[]' }
        return (@{
            databaseId = 902
            createdAt = [DateTimeOffset]::UtcNow.ToString('o')
            displayTitle = "meAndAI AI capabilities lifecycle [$($global:V092CorrelationId)]"
            headSha = $global:V092ConsumerHead
            status = 'completed'
            conclusion = 'success'
            url = 'https://example.invalid/actions/runs/902'
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'workflow' -and
        $Arguments[1] -ceq 'run') {
        $fieldIndex = [Array]::IndexOf([object[]]$Arguments, '--field')
        if ($fieldIndex -lt 0 -or
            [string]$Arguments[$fieldIndex + 1] -cnotmatch '^correlation_id=(?<id>[0-9a-f]{32})$') {
            throw 'Workflow dispatch omitted its exact correlation ID.'
        }
        $global:V092CorrelationId = [string]$Matches.id
        $global:V092DispatchCount++
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'run' -and
        $Arguments[1] -ceq 'view') {
        return (@{
            databaseId = 902
            displayTitle = "meAndAI AI capabilities lifecycle [$($global:V092CorrelationId)]"
            headSha = $global:V092ConsumerHead
            status = 'completed'
            conclusion = 'success'
            url = 'https://example.invalid/actions/runs/902'
        } | ConvertTo-Json -Compress)
    }
    throw "Unexpected gh call: gh $joined"
}

try {
    if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
        Add-Failure 'TEST-0119 quick-adoption launcher is missing.'
    }
    else {
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $launcherPath, [ref]$tokens, [ref]$parseErrors
        )
        if ($parseErrors.Count -gt 0) {
            Add-Failure "TEST-0119 launcher does not parse: $($parseErrors[0].Message)"
        }
        $parameter = @($ast.ParamBlock.Parameters | Where-Object {
            $_.Name.VariablePath.UserPath -ceq 'MigrateV092LivePins'
        })
        if ($parameter.Count -ne 1 -or
            $parameter[0].StaticType.FullName -cne 'System.Management.Automation.SwitchParameter') {
            Add-Failure 'TEST-0119 launcher lacks one exact -MigrateV092LivePins switch.'
        }

        $adoptionPrompts = @($ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.ExpandableStringExpressionAst] -and
            $node.Extent.Text.Contains('Complete the meAndAI AI-capabilities adoption')
        }, $true))
        if ($adoptionPrompts.Count -ne 1) {
            Add-Failure 'TEST-0119 launcher has no single executable local-Codex adoption prompt.'
        }
        else {
            $prompt = [string]$adoptionPrompts[0].Extent.Text
            foreach ($required in @(
                'sole live protocol identity',
                'gitlink',
                'VERSION',
                'consumer-owned instructions, memory, decisions, features, indexes, and tests',
                'literal current tag or commit'
            )) {
                if ($prompt.IndexOf(
                    $required, [StringComparison]::OrdinalIgnoreCase
                ) -lt 0) {
                    Add-Failure "TEST-0119 executable adoption prompt is missing '$required'."
                }
            }
        }

        if ($parameter.Count -eq 1 -and $parseErrors.Count -eq 0) {
            Initialize-ProtocolSnapshots
            $global:V092GhCalls = [System.Collections.Generic.List[object]]::new()
            $global:V092Phase = 'migration'
            $global:V092Lock = $null
            $global:V092CorrelationId = ''
            $global:V092DispatchCount = 0
            $expectedFragments = Get-ExpectedMigrationFragments

            $consumer = New-LegacyConsumerFixture -Name 'success'
            $global:V092ConsumerSlug = $consumer.Slug
            $before = Get-PathBytes -Repository $consumer.Repository `
                -Paths $migrationPaths
            $historicalBefore = Get-PathBytes -Repository $consumer.Repository `
                -Paths $consumer.HistoricalPaths
            $callStart = $global:V092GhCalls.Count
            $first = Invoke-MigrationLauncher -Repository $consumer.Repository
            if (-not $first.Succeeded) {
                Add-Failure "TEST-0119 recognized v0.9.2 migration failed: $($first.Message)"
            }
            else {
                $changedPaths = @((Invoke-TestGit -Repository $consumer.Repository `
                    -Arguments @('diff', '--name-only', '--')).Output | Where-Object { $_ })
                if (-not (Test-ExactPathSet -Actual $changedPaths -Expected $migrationPaths)) {
                    Add-Failure "TEST-0119 migration changed the wrong path set: $($changedPaths -join ', ')."
                }
                $after = Get-PathBytes -Repository $consumer.Repository `
                    -Paths $migrationPaths
                foreach ($path in $migrationPaths) {
                    $definition = $consumer.Definitions[$path]
                    $expectedBytes = Get-ExpectedMigratedBytes `
                        -OriginalBytes ([byte[]]$before[$path]) `
                        -Fragment $expectedFragments[$path]
                    if (-not (Test-ByteArrayEqual -Left $expectedBytes `
                        -Right ([byte[]]$after[$path]))) {
                        Add-Failure "TEST-0119 migrated bytes differ from the independent exact oracle for $path."
                    }
                    if (Test-ByteArrayEqual -Left ([byte[]]$before[$path]) `
                        -Right ([byte[]]$after[$path])) {
                        Add-Failure "TEST-0119 recognized live pin was not changed in $path."
                        continue
                    }
                    if (-not (Test-EnvelopePreserved -Before ([byte[]]$before[$path]) `
                        -After ([byte[]]$after[$path]) `
                        -Newline ([string]$definition.Newline) -Bom ([bool]$definition.Bom))) {
                        Add-Failure "TEST-0119 UTF-8 BOM or newline style changed in $path."
                    }
                    $text = [Text.UTF8Encoding]::new($false, $true).GetString(
                        [byte[]]$after[$path]
                    )
                    if ($text.Contains($legacySha) -or $text.Contains('v0.9.2')) {
                        Add-Failure "TEST-0119 active live-pin literal survived in $path."
                    }
                    foreach ($required in @($definition.Required)) {
                        if (-not $text.Contains([string]$required)) {
                            Add-Failure "TEST-0119 version-neutral authority '$required' is missing from $path."
                        }
                    }
                    foreach ($preserved in @($definition.Preserved) + @(
                        "meandai-v092-unrelated:$path:cafe"
                    )) {
                        if (-not $text.Contains([string]$preserved)) {
                            Add-Failure "TEST-0119 unrelated content '$preserved' changed in $path."
                        }
                    }
                    if ($null -ne $definition.PSObject.Properties['Forbidden']) {
                        foreach ($forbidden in @($definition.Forbidden)) {
                            if ($text.Contains([string]$forbidden)) {
                                Add-Failure "TEST-0119 forbidden live verifier token '$forbidden' survived in $path."
                            }
                        }
                    }
                }
                $historicalAfter = Get-PathBytes -Repository $consumer.Repository `
                    -Paths $consumer.HistoricalPaths
                foreach ($path in $consumer.HistoricalPaths) {
                    if (-not (Test-ByteArrayEqual -Left ([byte[]]$historicalBefore[$path]) `
                        -Right ([byte[]]$historicalAfter[$path]))) {
                        Add-Failure "TEST-0119 dated historical evidence changed in $path."
                    }
                }
                $migrationCalls = @($global:V092GhCalls | Select-Object -Skip $callStart)
                if (@($migrationCalls | Where-Object { Test-GhMutationCall -Call $_ }).Count -ne 0) {
                    Add-Failure 'TEST-0119 migration reached a secret, workflow, issue, pull-request, or other GitHub mutation.'
                }

                $afterFirstRun = Get-PathBytes -Repository $consumer.Repository `
                    -Paths $migrationPaths
                $second = Invoke-MigrationLauncher -Repository $consumer.Repository
                if (-not $second.Succeeded) {
                    Add-Failure "TEST-0119 idempotent migration rerun failed: $($second.Message)"
                }
                $afterSecondRun = Get-PathBytes -Repository $consumer.Repository `
                    -Paths $migrationPaths
                foreach ($path in $migrationPaths) {
                    if (-not (Test-ByteArrayEqual -Left ([byte[]]$afterFirstRun[$path]) `
                        -Right ([byte[]]$afterSecondRun[$path]))) {
                        Add-Failure "TEST-0119 idempotent rerun changed $path."
                    }
                }

                if ($second.Succeeded) {
                    Invoke-TestGit -Repository $consumer.Repository `
                        -Arguments (@('add', '--') + $migrationPaths) | Out-Null
                    Invoke-TestGit -Repository $consumer.Repository -Arguments @(
                        'commit', '-m', 'Migrate v0.9.2 live pins'
                    ) | Out-Null
                    Invoke-TestGit -Repository $consumer.Repository -Arguments @(
                        'push', 'origin', 'main'
                    ) | Out-Null
                    $consumerHashes = Get-PathHashes -Repository $consumer.Repository `
                        -Paths $migrationPaths
                    $global:V092ConsumerHead = (@(Invoke-TestGit `
                        -Repository $consumer.Repository -Arguments @('rev-parse', 'HEAD')).Output -join '').Trim()
                    $global:V092Phase = 'update'
                    $ordinary = Invoke-CompatibleUpdateLauncher `
                        -Repository $consumer.Repository
                    if (-not $ordinary.Succeeded) {
                        Add-Failure "TEST-0119 ordinary compatible-update route failed after migration: $($ordinary.Message)"
                    }
                    if ($global:V092DispatchCount -ne 1) {
                        Add-Failure "TEST-0119 ordinary route dispatched $($global:V092DispatchCount) workflows instead of one."
                    }
                    $afterUpdateHashes = Get-PathHashes -Repository $consumer.Repository `
                        -Paths $migrationPaths
                    foreach ($path in $migrationPaths) {
                        if ([string]$consumerHashes[$path] -cne [string]$afterUpdateHashes[$path]) {
                            Add-Failure "TEST-0119 ordinary compatible update rewrote consumer-owned $path."
                        }
                    }
                }
            }

            $negativeCases = @(
                [pscustomobject]@{
                    Name = 'non-repository'
                    Kind = 'NonRepository'
                    DriftOnCreate = $false
                    Expected = '(existing connected Git repository|no repository was initialized)'
                    AdditionalPaths = @()
                    Setup = { param($fixture, $fragments) return $null }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'wrong-gitlink'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = ('(does not match immutable release|exact immutable {0})' -f `
                        [regex]::Escape($legacyTag))
                    AdditionalPaths = @()
                    Setup = {
                        param($fixture, $fragments)
                        $wrongSha = (@(Invoke-TestGit -Repository $root `
                            -Arguments @('rev-parse', 'HEAD')).Output -join '').Trim()
                        Invoke-TestGit -Repository (Join-Path $fixture.Repository '.ai/protocol') `
                            -Arguments @('checkout', '--detach', $wrongSha) | Out-Null
                        Publish-FixtureChange -Fixture $fixture -Paths @('.ai/protocol') `
                            -Message 'Install wrong protocol gitlink'
                        return $null
                    }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'drifted-updater-asset'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = 'drifted from immutable release'
                    AdditionalPaths = @()
                    Setup = {
                        param($fixture, $fragments)
                        $path = Join-Path $fixture.Repository `
                            '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
                        [IO.File]::AppendAllText(
                            $path, "`n# fixture updater drift`n",
                            [Text.UTF8Encoding]::new($false)
                        )
                        Publish-FixtureChange -Fixture $fixture `
                            -Paths @('.github/scripts/MeAndAI.ProtocolUpdate.psm1') `
                            -Message 'Drift installed updater asset'
                        return $null
                    }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'missing-fragment'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = 'unsupported'
                    AdditionalPaths = @()
                    Setup = {
                        param($fixture, $fragments)
                        $path = Join-Path $fixture.Repository 'AGENTS.md'
                        $legacy = [string]$fragments['AGENTS.md'].Legacy
                        Set-NormalizedFixtureText -Path $path -Transform {
                            param($text)
                            $text.Replace($legacy, '2. Unrecognized legacy authority fragment.')
                        }
                        Publish-FixtureChange -Fixture $fixture -Paths @('AGENTS.md') `
                            -Message 'Remove recognized legacy fragment'
                        return $null
                    }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'duplicate-fragment'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = 'unsupported'
                    AdditionalPaths = @()
                    Setup = {
                        param($fixture, $fragments)
                        $path = Join-Path $fixture.Repository 'AGENTS.md'
                        $legacy = [string]$fragments['AGENTS.md'].Legacy
                        Set-NormalizedFixtureText -Path $path -Transform {
                            param($text)
                            $text.TrimEnd("`n") + "`n`n$legacy`n"
                        }
                        Publish-FixtureChange -Fixture $fixture -Paths @('AGENTS.md') `
                            -Message 'Duplicate recognized legacy fragment'
                        return $null
                    }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'mixed-fragments'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = 'partial'
                    AdditionalPaths = @()
                    Setup = {
                        param($fixture, $fragments)
                        $path = Join-Path $fixture.Repository 'AGENTS.md'
                        $legacy = [string]$fragments['AGENTS.md'].Legacy
                        $neutral = [string]$fragments['AGENTS.md'].Neutral
                        Set-NormalizedFixtureText -Path $path -Transform {
                            param($text)
                            $text.Replace($legacy, $neutral)
                        }
                        Publish-FixtureChange -Fixture $fixture -Paths @('AGENTS.md') `
                            -Message 'Create mixed migration state'
                        return $null
                    }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'unrelated-dirty-path'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = '(clean apart from|clean tree)'
                    AdditionalPaths = @('UNRELATED.tmp')
                    Setup = {
                        param($fixture, $fragments)
                        [IO.File]::WriteAllText(
                            (Join-Path $fixture.Repository 'UNRELATED.tmp'),
                            'unrelated dirty sentinel',
                            [Text.UTF8Encoding]::new($false)
                        )
                        return $null
                    }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'drifted-fragment'
                    Kind = 'Consumer'
                    DriftOnCreate = $true
                    Expected = '(fragment|drift|legacy|recognized|unsupported)'
                    AdditionalPaths = @()
                    Setup = { param($fixture, $fragments) return $null }
                    Cleanup = { param($fixture, $state) }
                },
                [pscustomobject]@{
                    Name = 'second-file-write-failure'
                    Kind = 'Consumer'
                    DriftOnCreate = $false
                    Expected = 'all written files were restored'
                    AdditionalPaths = @()
                    Setup = {
                        param($fixture, $fragments)
                        $path = Join-Path $fixture.Repository '.ai/memory/README.md'
                        return Set-TestWriteDenied -Path $path
                    }
                    Cleanup = {
                        param($fixture, $state)
                        if ($null -ne $state) {
                            Restore-TestWritePermission `
                                -Path (Join-Path $fixture.Repository '.ai/memory/README.md') `
                                -State $state
                        }
                    }
                }
            )

            foreach ($case in $negativeCases) {
                $global:V092Phase = 'migration'
                $global:V092CorrelationId = ''
                $global:V092DispatchCount = 0
                if ([string]$case.Kind -ceq 'NonRepository') {
                    $caseRoot = New-TempRoot -Name 'non-repository'
                    [IO.File]::WriteAllText(
                        (Join-Path $caseRoot 'plain.txt'), 'plain sentinel',
                        [Text.UTF8Encoding]::new($false)
                    )
                    $fixture = [pscustomobject]@{
                        Repository = $caseRoot
                        Slug = 'test-owner/non-repository'
                    }
                    $casePaths = @('plain.txt')
                }
                else {
                    $fixture = New-LegacyConsumerFixture `
                        -Name ([string]$case.Name) `
                        -DriftOneFragment:([bool]$case.DriftOnCreate)
                    $casePaths = @($migrationPaths) + @($case.AdditionalPaths)
                }
                $global:V092ConsumerSlug = $fixture.Slug
                $caseState = & $case.Setup $fixture $expectedFragments
                if ($null -ne $caseState -and
                    $null -ne $caseState.PSObject.Properties['Supported'] -and
                    -not [bool]$caseState.Supported) {
                    & $case.Cleanup $fixture $caseState
                    continue
                }
                $caseBefore = Get-PathBytes -Repository $fixture.Repository `
                    -Paths $casePaths
                $caseCallStart = $global:V092GhCalls.Count
                $rejected = Invoke-MigrationLauncher -Repository $fixture.Repository
                & $case.Cleanup $fixture $caseState
                if ($rejected.Succeeded) {
                    Add-Failure "TEST-0120 '$($case.Name)' was accepted."
                }
                elseif ($rejected.Message -cnotmatch ([string]$case.Expected)) {
                    Add-Failure "TEST-0120 '$($case.Name)' rejection was not specific: $($rejected.Message)"
                }
                $caseAfter = Get-PathBytes -Repository $fixture.Repository `
                    -Paths $casePaths
                foreach ($path in $casePaths) {
                    if (-not (Test-ByteArrayEqual -Left ([byte[]]$caseBefore[$path]) `
                        -Right ([byte[]]$caseAfter[$path]))) {
                        Add-Failure "TEST-0120 '$($case.Name)' wrote $path."
                    }
                }
                if ([string]$case.Kind -ceq 'NonRepository' -and
                    (Test-Path -LiteralPath (Join-Path $fixture.Repository '.git'))) {
                    Add-Failure 'TEST-0120 non-repository migration initialized .git.'
                }
                $caseCalls = @($global:V092GhCalls | Select-Object -Skip $caseCallStart)
                if (@($caseCalls | Where-Object {
                    Test-GhMutationCall -Call $_
                }).Count -ne 0) {
                    Add-Failure "TEST-0120 '$($case.Name)' crossed the GitHub mutation boundary."
                }
            }
        }
    }
}
finally {
    [Environment]::SetEnvironmentVariable('GH_HOST', $originalGitHubHost, 'Process')
    Remove-Item Function:\gh -Force -ErrorAction SilentlyContinue
    foreach ($path in $tempRoots) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "v0.9.2 live-pin migration tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'v0.9.2 live-pin migration tests passed.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/v092-live-pin-migration.tests.ps1' `
    -SourcePaths @($PSCommandPath) `
    -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
