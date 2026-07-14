[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Assert-File {
    param([string]$RelativePath)

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "TEST-0001 missing required file: $RelativePath"
    }
}

function Get-MarkdownAnchors {
    param([string]$Markdown)

    $anchors = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $counts = @{}

    foreach ($match in [regex]::Matches($Markdown, '(?m)^#{1,6}\s+(.+?)\s*$')) {
        $heading = $match.Groups[1].Value
        $heading = [regex]::Replace($heading, '<[^>]+>', '')
        $heading = [regex]::Replace($heading, '\[([^\]]+)\]\([^)]+\)', '$1')
        $slug = $heading.ToLowerInvariant()
        $slug = [regex]::Replace($slug, '[^\p{L}\p{Nd}\s_-]', '')
        $slug = [regex]::Replace($slug, '\s', '-')

        if ($counts.ContainsKey($slug)) {
            $counts[$slug]++
            $slug = "$slug-$($counts[$slug])"
        }
        else {
            $counts[$slug] = 0
        }

        [void]$anchors.Add($slug)
    }

    return ,$anchors
}

$requiredFiles = @(
    'AGENTS.md',
    'CHANGELOG.md',
    'PROTOCOL.md',
    'README.md',
    'VERSION',
    '.ai/memory/README.md',
    '.ai/memory/project.md',
    '.ai/memory/log/README.md',
    '.ai/memory/log/2026-07-14-update-automation.md',
    '.ai/memory/log/2026-07-14-bounded-self-validation.md',
    '.ai/memory/log/2026-07-14-convergent-completion-scan.md',
    '.ai/memory/log/2026-07-14-urgent-gate-order.md',
    '.ai/memory/log/2026-07-14-cleanup-comment-clarity.md',
    '.ai/memory/log/2026-07-15-feat-0002-release-gate-evidence.md',
    'docs/adoption.md',
    'docs/features/README.md',
    'docs/features/FEAT-0001-common-development-protocol/README.md',
    'docs/features/FEAT-0001-common-development-protocol/test-cases.md',
    'docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md',
    'docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md',
    'docs/features/FEAT-0003-convergent-completion-scan/README.md',
    'docs/features/FEAT-0003-convergent-completion-scan/test-cases.md',
    'docs/decisions/README.md',
    'docs/decisions/DEC-0001-portable-protocol-reference.md',
    'docs/decisions/DEC-0002-project-local-memory.md',
    'docs/decisions/DEC-0003-reviewed-consumer-update-supersession.md',
    'docs/decisions/DEC-0004-bounded-completion-convergence.md',
    'templates/project/AGENTS.submodule.md',
    'templates/project/AGENTS.repository-reference.md',
    'templates/project/.ai/memory/README.md',
    'templates/project/.ai/memory/project.md',
    'templates/project/.ai/memory/log/README.md',
    'templates/feature/README.md',
    'templates/feature/test-cases.md',
    'templates/decision.md',
    'templates/project/.github/workflows/meandai-protocol-update.yml',
    'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/ISSUE_TEMPLATE/config.yml',
    '.github/ISSUE_TEMPLATE/epic.yml',
    '.github/ISSUE_TEMPLATE/feature.yml',
    '.github/ISSUE_TEMPLATE/subfeature.yml',
    '.github/ISSUE_TEMPLATE/task.yml',
    '.github/ISSUE_TEMPLATE/bug.yml',
    '.github/ISSUE_TEMPLATE/finding.yml',
    'tests/protocol-update-adapter.tests.ps1',
    'tests/protocol-update.tests.ps1',
    '.github/workflows/protocol-tests.yml'
)
$requiredFiles | ForEach-Object { Assert-File $_ }

if ($failures.Count -gt 0) {
    Write-Host "Protocol validation failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$versionPath = Join-Path $root 'VERSION'
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
    $version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
    if ($version -notmatch '^\d+\.\d+\.\d+$') {
        Add-Failure "TEST-0002 VERSION must match M.m.rev; found '$version'"
    }
    else {
        $versionChecks = @{
            'README.md' = "Current protocol version: **$version**"
            'PROTOCOL.md' = "Protocol version: **$version**"
            'CHANGELOG.md' = "## $version -"
            '.ai/memory/README.md' = "Protocol version: **$version**"
            '.ai/memory/project.md' = ('Current protocol version: `{0}`' -f $version)
        }

        foreach ($entry in $versionChecks.GetEnumerator()) {
            $content = Get-Content -LiteralPath (Join-Path $root $entry.Key) -Raw
            if (-not $content.Contains($entry.Value)) {
                Add-Failure "TEST-0006 current-release metadata mismatch in $($entry.Key)"
            }
        }

        $currentReference = "v$version"
        $adoptionContent = Get-Content -LiteralPath (Join-Path $root 'docs/adoption.md') -Raw
        if (-not $adoptionContent.Contains($currentReference)) {
            Add-Failure 'TEST-0006 adoption guide is missing the current protocol reference'
        }

        foreach ($relativePath in @(
            'templates/project/AGENTS.submodule.md',
            'templates/project/AGENTS.repository-reference.md'
        )) {
            $content = Get-Content -LiteralPath (Join-Path $root $relativePath) -Raw
            $references = [regex]::Matches($content, 'v\d+\.\d+\.\d+')
            if ($references.Count -eq 0 -or @($references.Value | Where-Object { $_ -ne $currentReference }).Count -gt 0) {
                Add-Failure "TEST-0006 stale or missing protocol reference in $relativePath"
            }
        }

        $featureFiles = Get-ChildItem -LiteralPath (Join-Path $root 'docs/features') -Recurse -File -Filter 'README.md' |
            Where-Object { $_.Directory.Name -match '^FEAT-\d{4}-' }
        foreach ($featureFile in $featureFiles) {
            $feature = Get-Content -LiteralPath $featureFile.FullName -Raw
            if ($feature -notmatch '\| Target version \| \d+\.\d+\.\d+ \|') {
                Add-Failure "TEST-0006 invalid historical target version in $($featureFile.FullName)"
            }
        }
    }
}

$markdownFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

foreach ($file in $markdownFiles) {
    $markdown = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($match in [regex]::Matches($markdown, '(?<!!)\[[^\]]+\]\((?<target>[^)]+)\)')) {
        $target = $match.Groups['target'].Value.Trim().Trim('<', '>')
        if ($target -match '^(https?://|mailto:)' -or $target.StartsWith('{{')) {
            continue
        }

        $parts = $target.Split('#', 2)
        $relativeTarget = [uri]::UnescapeDataString($parts[0])
        $fragment = if ($parts.Count -eq 2) { $parts[1] } else { '' }
        $targetFile = $file.FullName

        if ($relativeTarget) {
            $targetFile = [System.IO.Path]::GetFullPath(
                (Join-Path $file.DirectoryName ($relativeTarget -replace '/', [System.IO.Path]::DirectorySeparatorChar))
            )
            $rootPrefix = $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $targetFile.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $display = $file.FullName.Substring($root.Length + 1)
                Add-Failure "TEST-0003 local link escapes repository in $display -> $target"
                continue
            }
            if (-not (Test-Path -LiteralPath $targetFile)) {
                $display = $file.FullName.Substring($root.Length + 1)
                Add-Failure "TEST-0003 broken local link in $display -> $target"
                continue
            }
        }

        if ($fragment -and (Test-Path -LiteralPath $targetFile -PathType Leaf) -and
            ([System.IO.Path]::GetExtension($targetFile) -ieq '.md')) {
            $targetMarkdown = Get-Content -LiteralPath $targetFile -Raw
            $anchors = Get-MarkdownAnchors $targetMarkdown
            if (-not $anchors.Contains($fragment)) {
                $display = $file.FullName.Substring($root.Length + 1)
                Add-Failure "TEST-0003 missing anchor in $display -> $target"
            }
        }
    }
}

$featureRoot = Join-Path $root 'docs/features'
$featureDirectories = Get-ChildItem -LiteralPath $featureRoot -Directory |
    Where-Object { $_.Name -match '^FEAT-\d{4}-' }

foreach ($directory in $featureDirectories) {
    foreach ($requiredName in @('README.md', 'test-cases.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $directory.FullName $requiredName) -PathType Leaf)) {
            Add-Failure "TEST-0004 $($directory.Name) is missing $requiredName"
        }
    }
}

$decisionFiles = Get-ChildItem -LiteralPath (Join-Path $root 'docs/decisions') -File -Filter 'DEC-*.md'
foreach ($file in $decisionFiles) {
    if ($file.BaseName -notmatch '^DEC-\d{4}-.+') {
        Add-Failure "TEST-0005 invalid decision filename: $($file.Name)"
        continue
    }

    $decision = Get-Content -LiteralPath $file.FullName -Raw
    $id = $file.BaseName.Substring(0, 8)
    foreach ($requiredText in @("# $id -", '- Classification: Decision', '- Status:', '## Context', '## Decision', '## Consequences', '## Alternatives considered')) {
        if (-not $decision.Contains($requiredText)) {
            Add-Failure "TEST-0005 $($file.Name) is missing '$requiredText'"
        }
    }
}

$formExpectations = @{
    'epic.yml' = @('[EPIC-NNNN]', 'type:epic')
    'feature.yml' = @('[FEAT-NNNN]', 'type:feature', 'test-code and baseline-run status')
    'subfeature.yml' = @('[SUBF-NNNN]', 'type:subfeature', 'Parent feature')
    'task.yml' = @('[TASK-NNNN]', 'type:task')
    'bug.yml' = @('[BUG-NNNN]', 'type:bug', 'never paste secrets')
    'finding.yml' = @('[FIND-NNNN]', 'type:finding', 'id: disposition', 'id: category', 'id: severity', 'id: confidence')
}

foreach ($entry in $formExpectations.GetEnumerator()) {
    $path = Join-Path $root ".github/ISSUE_TEMPLATE/$($entry.Key)"
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($requiredText in @('name:', 'description:', 'labels:', 'body:', 'Related records') + $entry.Value) {
        if (-not $content.Contains($requiredText)) {
            Add-Failure "TEST-0007 $($entry.Key) is missing '$requiredText'"
        }
    }
}

$config = Get-Content -LiteralPath (Join-Path $root '.github/ISSUE_TEMPLATE/config.yml') -Raw
foreach ($requiredText in @('blank_issues_enabled: false', 'contact_links:', 'https://')) {
    if (-not $config.Contains($requiredText)) {
        Add-Failure "TEST-0007 issue-form config is missing '$requiredText'"
    }
}

$pullRequestTemplate = Get-Content -LiteralPath (Join-Path $root '.github/PULL_REQUEST_TEMPLATE.md') -Raw
foreach ($requiredText in @('## Classification and links', '## Test evidence', 'Date/commit', 'Environment', '## Self-review', '## Definition of Ready', '## Definition of Done', 'redacted')) {
    if (-not $pullRequestTemplate.Contains($requiredText)) {
        Add-Failure "TEST-0007 pull request template is missing '$requiredText'"
    }
}

$submoduleAdapter = Get-Content -LiteralPath (Join-Path $root 'templates/project/AGENTS.submodule.md') -Raw
$referenceAdapter = Get-Content -LiteralPath (Join-Path $root 'templates/project/AGENTS.repository-reference.md') -Raw
$adoption = Get-Content -LiteralPath (Join-Path $root 'docs/adoption.md') -Raw
if (-not $submoduleAdapter.Contains('.ai/protocol/PROTOCOL.md') -or
    $referenceAdapter.Contains('.ai/protocol/PROTOCOL.md') -or
    -not $referenceAdapter.Contains('entry point: `PROTOCOL.md`') -or
    -not $submoduleAdapter.Contains('.ai/memory/README.md') -or
    -not $referenceAdapter.Contains('.ai/memory/README.md') -or
    $submoduleAdapter.Contains('.ai/protocol/.ai/memory') -or
    $referenceAdapter.Contains('.ai/protocol/.ai/memory') -or
    -not $adoption.Contains('AGENTS.submodule.md') -or
    -not $adoption.Contains('AGENTS.repository-reference.md') -or
    -not $adoption.Contains('templates/project/.ai/memory/') -or
    -not $adoption.Contains('`.ai/memory/`') -or
    -not $adoption.Contains('repository-reference consumer MUST request') -or
    -not $adoption.Contains('preflight before writing') -or
    -not $adoption.Contains('config.yml` is deliberately excluded')) {
    Add-Failure 'TEST-0008 adoption adapters do not preserve entry-point and memory isolation semantics'
}

$consumerRoot = [System.IO.Path]::GetFullPath((Join-Path $root '.consumer-layout-fixture'))
$protocolCheckout = [System.IO.Path]::GetFullPath((Join-Path $consumerRoot '.ai/protocol'))
$projectMemory = [System.IO.Path]::GetFullPath((Join-Path $consumerRoot '.ai/memory/README.md'))
$protocolPrefix = $protocolCheckout.TrimEnd([System.IO.Path]::DirectorySeparatorChar) +
    [System.IO.Path]::DirectorySeparatorChar
if ($projectMemory.StartsWith($protocolPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    Add-Failure 'TEST-0008 project memory resolves inside the protocol checkout'
}

$memoryTemplateRoot = Join-Path $root 'templates/project/.ai/memory'
$memoryTemplateFiles = @(Get-ChildItem -LiteralPath $memoryTemplateRoot -Recurse -File)
if ($memoryTemplateFiles.Count -lt 3) {
    Add-Failure 'TEST-0008 project-local memory template set is incomplete'
}

$updateTestPath = Join-Path $root 'tests/protocol-update.tests.ps1'
$protocolContent = Get-Content -LiteralPath (Join-Path $root 'PROTOCOL.md') -Raw
$featureTemplate = Get-Content -LiteralPath (Join-Path $root 'templates/feature/README.md') -Raw
$normalizedProtocolContent = [regex]::Replace($protocolContent, '\s+', ' ')
foreach ($requiredText in @(
    'one fresh-diff self-review pass',
    'one final relevant verification command',
    'Only a blocking finding',
    'Stop validation when',
    'validator-for-validator',
    'MUST NOT trigger another'
)) {
    if (-not $protocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0018 bounded self-validation contract is missing '$requiredText'"
    }
}
if (-not $featureTemplate.Contains('one bounded fresh-diff pass')) {
    Add-Failure 'TEST-0018 feature template is missing the bounded self-review default'
}

foreach ($requiredText in @(
    'After development is declared complete',
    'highest to lowest priority',
    'severity, impact, and',
    'no unresolved actionable in-scope finding',
    'finite validation budget',
    'unchanged scan MUST NOT be repeated',
    'stop as blocked',
    'Budget exhaustion is never a successful completion state'
)) {
    if (-not $protocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0019 post-development convergence contract is missing '$requiredText'"
    }
}
foreach ($requiredText in @(
    'post-development full-project scan',
    'finite validation budget',
    'non-blocking follow-ups are owned and linked'
)) {
    if (-not $featureTemplate.Contains($requiredText)) {
        Add-Failure "TEST-0019 feature template is missing '$requiredText'"
    }
}

foreach ($requiredText in @(
    'does not change gate order',
    'authorize implementation before Gate 1',
    'the evidence for a gate MUST exist before that gate is',
    'numbered-decision process in Section 1',
    'owner, risk, tests, deferred evidence',
    'linked follow-up',
    'review or expiry condition'
)) {
    if (-not $normalizedProtocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0020 urgent-work gate contract is missing '$requiredText'"
    }
}

if (Test-Path -LiteralPath $updateTestPath -PathType Leaf) {
    $engine = (Get-Process -Id $PID).Path
    & $engine -NoProfile -ExecutionPolicy Bypass -File $updateTestPath
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'TEST-0009 through TEST-0017 and TEST-0021 through TEST-0026 protocol update validation failed'
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Protocol validation failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Protocol validation passed: TEST-0001 through TEST-0026.' -ForegroundColor Green
