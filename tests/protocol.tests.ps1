[CmdletBinding()]
param([switch]$StructureOnly)

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

function Get-IndexedMarkdownTargets {
    param(
        [Parameter(Mandatory)][string]$IndexRelativePath,
        [Parameter(Mandatory)][string]$TargetPattern
    )

    $indexPath = Join-Path $root $IndexRelativePath
    if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
        return @()
    }
    $indexDirectory = Split-Path -Parent $indexPath
    $targets = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $content = Get-Content -LiteralPath $indexPath -Raw
    foreach ($match in [regex]::Matches(
        $content,
        '(?<!!)\[[^\]]+\]\((?<target>[^)#]+\.md)(?:#[^)]+)?\)'
    )) {
        $target = [uri]::UnescapeDataString($match.Groups['target'].Value)
        $absolute = [IO.Path]::GetFullPath((Join-Path $indexDirectory $target))
        $relative = $absolute.Substring($root.Length + 1).Replace('\', '/')
        if ($relative -cmatch $TargetPattern) {
            [void]$targets.Add($relative)
        }
    }
    return @($targets)
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
    'docs/adoption.md',
    'docs/quick-adoption.md',
    'docs/README.md',
    'docs/ideas/README.md',
    'docs/features/README.md',
    'docs/decisions/README.md',
    'scripts/Invoke-MeAndAIQuickAdoption.ps1',
    'templates/project/AGENTS.submodule.md',
    'templates/project/AGENTS.repository-reference.md',
    'templates/project/.ai/memory/README.md',
    'templates/project/.ai/memory/project.md',
    'templates/project/.ai/memory/log/README.md',
    'templates/feature/README.md',
    'templates/feature/test-cases.md',
    'templates/decision.md',
    'templates/idea.md',
    'templates/project/docs/ideas/README.md',
    'templates/project/.github/workflows/meandai-protocol-update.yml',
    'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
    'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1',
    'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/ISSUE_TEMPLATE/config.yml',
    '.github/ISSUE_TEMPLATE/epic.yml',
    '.github/ISSUE_TEMPLATE/feature.yml',
    '.github/ISSUE_TEMPLATE/subfeature.yml',
    '.github/ISSUE_TEMPLATE/task.yml',
    '.github/ISSUE_TEMPLATE/bug.yml',
    '.github/ISSUE_TEMPLATE/finding.yml',
    'tests/fixtures/Invoke-MockCodex.ps1',
    'tests/fixtures/Invoke-MockCodex.cmd',
    'tests/fixtures/Invoke-MockCodex.sh',
    '.github/workflows/protocol-tests.yml'
)
$requiredFiles | ForEach-Object { Assert-File $_ }

$indexedRecords = @(
    Get-IndexedMarkdownTargets -IndexRelativePath 'docs/features/README.md' `
        -TargetPattern '^docs/features/FEAT-\d{4}-[^/]+/README\.md$'
    Get-IndexedMarkdownTargets -IndexRelativePath 'docs/decisions/README.md' `
        -TargetPattern '^docs/decisions/DEC-\d{4}-.+\.md$'
    Get-IndexedMarkdownTargets -IndexRelativePath 'docs/ideas/README.md' `
        -TargetPattern '^docs/ideas/IDEA-\d{4}-.+\.md$'
    Get-IndexedMarkdownTargets -IndexRelativePath '.ai/memory/log/README.md' `
        -TargetPattern '^\.ai/memory/log/\d{4}-\d{2}-\d{2}-.+\.md$'
)
foreach ($relativePath in $indexedRecords) {
    Assert-File $relativePath
    if ($relativePath -cmatch '^docs/features/.+/README\.md$') {
        Assert-File ((Split-Path $relativePath -Parent) + '/test-cases.md')
    }
}

$indexedSet = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($relativePath in $indexedRecords) {
    [void]$indexedSet.Add($relativePath)
}
$recordPatterns = @(
    'docs/features/FEAT-*/README.md',
    'docs/decisions/DEC-*.md',
    'docs/ideas/IDEA-*.md',
    '.ai/memory/log/????-??-??-*.md'
)
foreach ($pattern in $recordPatterns) {
    foreach ($file in @(Get-ChildItem -Path (Join-Path $root $pattern) -File)) {
        $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
        if (-not $indexedSet.Contains($relative)) {
            Add-Failure "TEST-0059 canonical record is missing from its index: $relative"
        }
    }
}

$testSuites = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') -File `
    -Filter '*.tests.ps1' | Where-Object {
        $_.Name -cne 'protocol.tests.ps1' -and
        $_.BaseName -cnotmatch '-adapter\.tests$'
    })
if ($testSuites.Count -eq 0) {
    Add-Failure 'TEST-0059 no canonical child test suites were discovered.'
}
$adapterSuites = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') -File `
    -Filter '*-adapter.tests.ps1')
foreach ($adapterSuite in $adapterSuites) {
    $owners = @($testSuites | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw).Contains($adapterSuite.Name)
    })
    if ($owners.Count -ne 1) {
        Add-Failure "TEST-0059 adapter suite must have exactly one discovered parent: $($adapterSuite.Name)"
    }
}

$declaredTestIds = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($testCaseFile in @(Get-ChildItem -LiteralPath (Join-Path $root 'docs/features') `
    -Recurse -File -Filter 'test-cases.md')) {
    $testCaseContent = Get-Content -LiteralPath $testCaseFile.FullName -Raw
    foreach ($match in [regex]::Matches($testCaseContent, 'TEST-\d{4}')) {
        [void]$declaredTestIds.Add($match.Value)
    }
}
$executableTestSource = (@(Get-ChildItem -LiteralPath (Join-Path $root 'tests') `
    -File -Filter '*.ps1' | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw
    }) -join [Environment]::NewLine)
foreach ($testId in @($declaredTestIds | Sort-Object)) {
    if (-not $executableTestSource.Contains($testId)) {
        Add-Failure "TEST-0066 declared scenario has no executable test identity: $testId"
    }
}

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

        $projectTemplateRoot = Join-Path $root 'templates/project'
        foreach ($file in @(Get-ChildItem -LiteralPath $projectTemplateRoot -Recurse -File)) {
            $relativePath = $file.FullName.Substring($root.Length + 1)
            $content = Get-Content -LiteralPath $file.FullName -Raw
            $references = [regex]::Matches($content, 'v\d+\.\d+\.\d+')
            foreach ($reference in $references) {
                $lineStart = $content.LastIndexOf("`n", $reference.Index)
                $lineEnd = $content.IndexOf("`n", $reference.Index)
                if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart++ }
                if ($lineEnd -lt 0) { $lineEnd = $content.Length }
                $line = $content.Substring($lineStart, $lineEnd - $lineStart)

                # A pinned action's release comment identifies that dependency,
                # not the meAndAI protocol version carried by the template.
                if ($line -match '^\s*uses:\s*[^#]+#\s*v\d+\.\d+\.\d+\s*$') {
                    continue
                }

                if ($reference.Value -ne $currentReference) {
                    Add-Failure "TEST-0006 stale protocol reference in $relativePath"
                    break
                }
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

$releaseMetadataChecks = [ordered]@{
    'docs/features/FEAT-0007-local-codex-adoption/README.md' = @(
        '| Status | Complete |',
        '`v0.7.1` tag'
    )
    'docs/features/FEAT-0008-idea-incubation/README.md' = @(
        '| Status | Complete |',
        '`v0.7.0` tag'
    )
    'docs/decisions/README.md' = @(
        'Partially superseded by [DEC-0008]'
    )
    '.ai/memory/log/README.md' = @(
        '2026-07-15-adoption-integrity.md'
    )
    'PROTOCOL.md' = @(
        'Each mapped local credential file is required only',
        'authenticated local `gh` identity',
        'MUST NOT substitute for provisioning'
    )
}
foreach ($entry in $releaseMetadataChecks.GetEnumerator()) {
    $content = Get-Content -LiteralPath (Join-Path $root $entry.Key) -Raw
    $normalizedContent = [regex]::Replace($content, '\s+', ' ')
    foreach ($requiredText in $entry.Value) {
        if (-not $normalizedContent.Contains($requiredText)) {
            Add-Failure "TEST-0050 release metadata in $($entry.Key) is missing '$requiredText'"
        }
    }
}

$validatorSource = Get-Content -LiteralPath (Join-Path $root 'tests/protocol.tests.ps1') -Raw
foreach ($requiredText in @(
    'Get-IndexedMarkdownTargets',
    'ls-files --cached --others',
    "-Filter '*.tests.ps1'",
    'StructureOnly'
)) {
    if (-not ([regex]::Replace($validatorSource, '\s+', ' ')).Contains($requiredText)) {
        Add-Failure "TEST-0059 repository validator is missing '$requiredText'"
    }
}

$ciWorkflow = Get-Content -LiteralPath (Join-Path $root '.github/workflows/protocol-tests.yml') -Raw
if (-not $ciWorkflow.Contains('timeout-minutes:')) {
    Add-Failure 'TEST-0059 repository CI has no explicit job timeout.'
}
foreach ($requiredText in @(
    'persist-credentials: false', 'os: ubuntu-latest', 'shell: pwsh',
    'os: windows-latest', 'shell: powershell', 'Parse consumer workflow YAML',
    "require 'yaml'", "if: runner.os == 'Linux'", "if: runner.os == 'Windows'"
)) {
    if (-not $ciWorkflow.Contains($requiredText)) {
        Add-Failure "TEST-0067 repository CI compatibility contract is missing '$requiredText'"
    }
}
if ($ciWorkflow.Contains('shell: ${{ matrix.shell }}')) {
    Add-Failure 'TEST-0067 repository CI uses matrix context where the shell field does not permit it.'
}

$docsIndex = Get-Content -LiteralPath (Join-Path $root 'docs/README.md') -Raw
foreach ($requiredText in @(
    '[Quick adoption](quick-adoption.md)',
    '[Idea index](ideas/README.md)',
    '[Project memory](../.ai/memory/README.md)',
    '[Changelog](../CHANGELOG.md)'
)) {
    if (-not $docsIndex.Contains($requiredText)) {
        Add-Failure "TEST-0059 documentation router is missing '$requiredText'"
    }
}

$featureTemplate = Get-Content -LiteralPath (Join-Path $root 'templates/feature/README.md') -Raw
foreach ($requiredText in @(
    '## Post-merge release evidence',
    'Release authority',
    'Release identifier',
    'Target commit',
    'Verification evidence',
    'external post-publication record'
)) {
    if (-not $featureTemplate.Contains($requiredText)) {
        Add-Failure "TEST-0059 feature template release schema is missing '$requiredText'"
    }
}

$initialFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0001-common-development-protocol/README.md'
) -Raw
if (-not $initialFeature.Contains('`FIND-0048`')) {
    Add-Failure 'TEST-0059 FIND-0048 is missing from its canonical feature finding register.'
}

$localCodexFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0007-local-codex-adoption/README.md'
) -Raw
foreach ($requiredText in @(
    '45afd8c15c155fb3f7cb0e5abb4876a3d44b27af',
    '2f74f1f4b28bd63bb04a1b9f9f30b1603d0b164e',
    '[Pull request #33](https://github.com/hasanmanzak/meAndAI/pull/33)'
)) {
    if (-not $localCodexFeature.Contains($requiredText)) {
        Add-Failure "TEST-0059 v0.7.3 release record is missing '$requiredText'"
    }
}

$integrityFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0009-adoption-integrity/README.md'
) -Raw
if (-not $integrityFeature.Contains('historical annotated tag') -or
    $integrityFeature.Contains('is the immutable release authority')) {
    Add-Failure 'TEST-0059 v0.7.2 release evidence overstates annotated-tag authority.'
}

$bootstrapAdapterPath = Join-Path $root `
    'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$bootstrapTokens = $null
$bootstrapParseErrors = $null
$bootstrapAst = [Management.Automation.Language.Parser]::ParseFile(
    $bootstrapAdapterPath, [ref]$bootstrapTokens, [ref]$bootstrapParseErrors
)
$expectedBootstrapFunctions = @(
    'Test-ExactAdoptionPullRequestMarker', 'Test-ExactAdoptionTree',
    'Test-ExactAdoptionManifest', 'Test-ExactAdoptionContinuity',
    'Test-ExactAdoptionProposal'
)
$bootstrapFunctionNames = @($bootstrapAst.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst]
}, $true) | ForEach-Object { $_.Name })
if (@($bootstrapParseErrors).Count -gt 0 -or
    @($expectedBootstrapFunctions | Where-Object {
        $bootstrapFunctionNames -cnotcontains $_
    }).Count -ne 0) {
    Add-Failure 'TEST-0059 bootstrap exact-state responsibility seams are missing or invalid.'
}

$protocolDecision = Get-Content -LiteralPath (
    Join-Path $root 'docs/decisions/DEC-0010-stable-automation-invariants.md'
) -Raw
foreach ($requiredText in @(
    '**Bounded responsibility seams.**',
    'external post-publication release'
)) {
    if (-not $protocolDecision.Contains($requiredText)) {
        Add-Failure "TEST-0059 stable-invariant decision is missing '$requiredText'"
    }
}

$trackedMarkdownOutput = @(& git -C $root ls-files --cached --others `
    --exclude-standard -- '*.md' 2>&1)
if ($LASTEXITCODE -ne 0) {
    Add-Failure "TEST-0059 root Git Markdown inventory failed: $($trackedMarkdownOutput -join ' ')"
    $markdownFiles = @()
}
else {
    $markdownFiles = @($trackedMarkdownOutput | Where-Object { $_ } | ForEach-Object {
        Get-Item -LiteralPath (Join-Path $root ([string]$_))
    })
}

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

$protocolContent = Get-Content -LiteralPath (Join-Path $root 'PROTOCOL.md') -Raw
$featureTemplate = Get-Content -LiteralPath (Join-Path $root 'templates/feature/README.md') -Raw
$normalizedProtocolContent = [regex]::Replace($protocolContent, '\s+', ' ')
foreach ($requiredText in @(
    'one fresh-diff self-review pass',
    'one final relevant verification command',
    '`Blocking`',
    '`AcceptedResidual`',
    '`ExternalOrLegacyFollowUp`',
    '`OptionalImprovement`',
    'These dispositions are mutually exclusive',
    'Actionable in-scope finding',
    'Stop validation when',
    'validator-for-validator',
    'MUST NOT trigger another'
)) {
    if (-not $protocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0064 bounded disposition contract is missing '$requiredText'"
    }
}
if (-not $featureTemplate.Contains('one bounded fresh-diff pass')) {
    Add-Failure 'TEST-0018 feature template is missing the bounded self-review default'
}

foreach ($requiredText in @(
    'After development is declared complete',
    'highest to lowest priority',
    'severity, impact, and',
    'no unresolved `Blocking` finding',
    'finite validation budget',
    'unchanged scan MUST NOT be repeated',
    'stop as blocked',
    'Budget exhaustion is never a successful completion state'
)) {
    if (-not $protocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0019 post-development convergence contract is missing '$requiredText'"
    }
}

$stabilityDecision = Get-Content -LiteralPath (
    Join-Path $root 'docs/decisions/DEC-0011-qualified-evidence-and-closure.md'
) -Raw
foreach ($requiredText in @(
    'repository, tag, locked commit', 'source credential boundary',
    'unique correlation ID', 'post-create convergence check',
    'executable scenario identity'
)) {
    if (-not $stabilityDecision.Contains($requiredText)) {
        Add-Failure "TEST-0064 qualified-evidence decision is missing '$requiredText'"
    }
}

$stabilityFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0010-protocol-stability-invariants/README.md'
) -Raw
$localCodexFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0007-local-codex-adoption/README.md'
) -Raw
$projectMemory = Get-Content -LiteralPath (Join-Path $root '.ai/memory/project.md') -Raw
$overview = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw
$overviewNormalized = [regex]::Replace($overview, '\s+', ' ')
if (-not $stabilityFeature.Contains('| Status | Complete |') -or
    -not $stabilityFeature.Contains('releases/tag/v0.8.0') -or
    -not $stabilityFeature.Contains('a6a25b4e2a4dad5b0d09c0dddaf777f730c6a821') -or
    -not $localCodexFeature.Contains('| Status | Complete |') -or
    $projectMemory.Contains('v0.8.0` is in progress') -or
    -not $projectMemory.Contains('[issue #36]') -or
    -not $overviewNormalized.Contains('deliberately does not duplicate that changing inventory')) {
    Add-Failure 'TEST-0065 published feature, memory, and canonical routing projections are not reconciled.'
}
foreach ($requiredText in @(
    'post-development full-project scan',
    'finite validation budget',
    'every other disposition has its required authority'
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

if (-not $StructureOnly) {
    $engine = (Get-Process -Id $PID).Path
    foreach ($suite in $testSuites) {
        & $engine -NoProfile -ExecutionPolicy Bypass -File $suite.FullName
        if ($LASTEXITCODE -ne 0) {
            Add-Failure "Child test suite failed: $($suite.Name)"
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Protocol validation failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

if ($StructureOnly) {
    Write-Host 'Protocol structure validation passed for all discovered contracts.' -ForegroundColor Green
}
else {
    Write-Host 'All discovered protocol test suites passed.' -ForegroundColor Green
}
