[CmdletBinding()]
param(
    [switch]$StructureOnly
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestDiscovery.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestRuntime.psm1') -Force
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

function Get-MarkdownAnchorEvidence {
    param([string]$Markdown)

    $anchors = [System.Collections.Generic.List[object]]::new()
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

        $anchors.Add([pscustomobject]@{
            Name = $slug
            Kind = 'Heading'
            Index = $match.Index
            Length = $match.Length
        })
    }

    foreach ($match in [regex]::Matches(
        $Markdown,
        '<a[ \t]+name[ \t]*=[ \t]*"(?<name>[^"<>\s]+)"[ \t]*></a>'
    )) {
        $anchors.Add([pscustomobject]@{
            Name = [string]$match.Groups['name'].Value
            Kind = 'Custom'
            Index = $match.Index
            Length = $match.Length
        })
    }

    return @($anchors | Sort-Object Index)
}

function Get-MarkdownAnchors {
    param([string]$Markdown)

    $anchors = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($anchor in @(Get-MarkdownAnchorEvidence -Markdown $Markdown)) {
        [void]$anchors.Add([string]$anchor.Name)
    }
    return ,$anchors
}

function Test-CanonicalGitHubLineFragment {
    param(
        [Parameter(Mandatory)][string]$Fragment,
        [Parameter(Mandatory)][long]$LineCount
    )

    $lineMatch = [regex]::Match(
        $Fragment,
        '^L(?<start>[1-9][0-9]*)(?:-L(?<end>[1-9][0-9]*))?$'
    )
    if (-not $lineMatch.Success -or $LineCount -lt 1) { return $false }
    [long]$start = 0
    if (-not [long]::TryParse(
            [string]$lineMatch.Groups['start'].Value,
            [ref]$start
        )) { return $false }
    [long]$end = $start
    if ($lineMatch.Groups['end'].Success -and
        -not [long]::TryParse(
            [string]$lineMatch.Groups['end'].Value,
            [ref]$end
        )) { return $false }
    return $start -ge 1 -and $end -ge $start -and $end -le $LineCount
}

function Get-Utf8TextEvidence {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    try {
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        $text = $utf8.GetString($Bytes)
    }
    catch [Text.DecoderFallbackException] {
        return [pscustomobject]@{
            IsText = $false; Text = ''; LineCount = 0
        }
    }
    if ([regex]::IsMatch($text, '[\x00-\x08\x0B\x0C\x0E-\x1F]')) {
        return [pscustomobject]@{
            IsText = $false; Text = ''; LineCount = 0
        }
    }
    $lineCount = if ($text.Length -eq 0) {
        0
    }
    else {
        $breakCount = [regex]::Matches($text, "\r\n|\r|\n").Count
        if ($text -match "(?:\r\n|\r|\n)$") {
            $breakCount
        }
        else {
            $breakCount + 1
        }
    }
    return [pscustomobject]@{
        IsText = $true; Text = $text; LineCount = [long]$lineCount
    }
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
    'docs/agent-prompts/README.md',
    'docs/agent-prompts/stability-and-consistency-cycle.md',
    'docs/ideas/README.md',
    'docs/features/README.md',
    'docs/decisions/README.md',
    'capabilities/index.json',
    'capabilities/canonical-repository-evidence.json',
    'capabilities/test-architecture.json',
    'capabilities/test-runtime-efficiency.json',
    'scripts/MeAndAI.RepositoryEvidence.psm1',
    'scripts/MeAndAI.CapabilityCatalog.psm1',
    'scripts/MeAndAI.CapabilityReview.psm1',
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
    'tests/protocol.tests.ps1',
    'tests/scenario-ownership.psd1',
    'tests/execution-profiles.psd1',
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1',
    'tests/infrastructure/MeAndAI.TestDiscovery.psm1',
    'tests/infrastructure/MeAndAI.TestRuntime.psm1',
    'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.ps1',
    'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.cmd',
    'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.sh',
    'tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1',
    'tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1',
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
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0044'

$testSuites = @(Get-MeAndAITestSuite -RepositoryRoot $root)
if ($testSuites.Count -eq 0) {
    Add-Failure 'TEST-0059 no canonical child test suites were discovered.'
}
$adapterSuites = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests/capabilities') `
    -Recurse -File -Filter '*.fixture.ps1')
foreach ($adapterSuite in $adapterSuites) {
    $owners = @($testSuites | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw).Contains($adapterSuite.Name)
    })
    if ($owners.Count -ne 1) {
        Add-Failure "TEST-0059 adapter suite must have exactly one discovered parent: $($adapterSuite.Name)"
    }
}

$scenarioDeclarations = @{}
foreach ($testCaseFile in @(Get-ChildItem -LiteralPath (Join-Path $root 'docs/features') `
    -Recurse -File -Filter 'test-cases.md')) {
    $relativeTestCasePath = $testCaseFile.FullName.Substring($root.Length + 1).Replace('\', '/')
    $lineNumber = 0
    foreach ($line in @(Get-Content -LiteralPath $testCaseFile.FullName)) {
        $lineNumber++
        if ($line -notmatch '^\|\s*`(?<id>TEST-\d{4})`[^|]*\|') {
            continue
        }

        $testId = $Matches.id
        if (-not $scenarioDeclarations.ContainsKey($testId)) {
            $scenarioDeclarations[$testId] = [System.Collections.Generic.List[object]]::new()
        }
        $scenarioDeclarations[$testId].Add([pscustomobject]@{
            Path = $relativeTestCasePath
            LineNumber = $lineNumber
            Line = $line
        })
    }
}
foreach ($testId in @($scenarioDeclarations.Keys | Sort-Object)) {
    if ($scenarioDeclarations[$testId].Count -ne 1) {
        $locations = @($scenarioDeclarations[$testId] | ForEach-Object {
            "$($_.Path):$($_.LineNumber)"
        }) -join ', '
        Add-Failure "TEST-0074 scenario ID must have exactly one canonical declaration: $testId ($locations)"
    }
}

$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$scenarioAuthorityData = $null
if (Test-Path -LiteralPath $scenarioAuthorityPath -PathType Leaf) {
    try {
        $scenarioAuthorityData = Import-PowerShellDataFile -LiteralPath $scenarioAuthorityPath
    }
    catch {
        Add-Failure "TEST-0074 scenario authority data is invalid: $($_.Exception.Message)"
    }
}

$scenarioAuthorities = @()
$authorityByTestId = @{}
if ($null -ne $scenarioAuthorityData) {
    if ($scenarioAuthorityData.SchemaVersion -ne 1) {
        Add-Failure 'TEST-0074 scenario authority schema version must be 1.'
    }
    $scenarioAuthorities = @($scenarioAuthorityData.Authorities)
    $allowedEvidenceKinds = @(
        'ExecutableSuite', 'GitHubActionsSemantic',
        'ExternalPostPublication', 'HistoricalSuperseded'
    )
    $canonicalSuiteOwners = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($suite in $testSuites) {
        [void]$canonicalSuiteOwners.Add([string]$suite.Owner)
    }

    foreach ($authority in $scenarioAuthorities) {
        $evidence = [string]$authority.Evidence
        $owner = ([string]$authority.Owner).Replace('\', '/')
        $testIds = @($authority.TestIds)
        if ($allowedEvidenceKinds -cnotcontains $evidence) {
            Add-Failure "TEST-0074 unsupported scenario evidence kind '$evidence'."
            continue
        }
        if ($owner -notmatch '^[^/]+(?:/[^/]+)+$' -or
            $owner -match '(^|/)\.\.(/|$)' -or
            -not (Test-Path -LiteralPath (Join-Path $root $owner) -PathType Leaf)) {
            Add-Failure "TEST-0074 scenario authority owner is missing or unsafe: '$owner'."
            continue
        }
        if ($testIds.Count -eq 0) {
            Add-Failure "TEST-0074 scenario authority '$owner' has no test IDs."
            continue
        }

        switch ($evidence) {
            'ExecutableSuite' {
                if (-not $canonicalSuiteOwners.Contains($owner)) {
                    Add-Failure "TEST-0074 executable owner is not a discovered canonical suite: '$owner'."
                }
            }
            'GitHubActionsSemantic' {
                if ($owner -cne '.github/workflows/protocol-tests.yml') {
                    Add-Failure "TEST-0074 GitHub Actions evidence has an invalid owner: '$owner'."
                }
            }
            'ExternalPostPublication' {
                if ($owner -cne 'tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1') {
                    Add-Failure "TEST-0074 post-publication evidence has an invalid owner: '$owner'."
                }
            }
            'HistoricalSuperseded' {
                if ($owner -cnotmatch '^docs/features/FEAT-\d{4}-[^/]+/test-cases\.md$') {
                    Add-Failure "TEST-0074 superseded evidence has an invalid canonical owner: '$owner'."
                }
            }
        }

        foreach ($testIdValue in $testIds) {
            $testId = [string]$testIdValue
            if ($testId -cnotmatch '^TEST-\d{4}$') {
                Add-Failure "TEST-0074 malformed scenario identity '$testId' in '$owner'."
                continue
            }
            if ($authorityByTestId.ContainsKey($testId)) {
                Add-Failure "TEST-0074 scenario has multiple evidence authorities: $testId."
                continue
            }
            $authorityByTestId[$testId] = [pscustomobject]@{
                Evidence = $evidence
                Owner = $owner
            }
        }
    }
}

foreach ($testId in @($scenarioDeclarations.Keys | Sort-Object)) {
    if (-not $authorityByTestId.ContainsKey($testId)) {
        Add-Failure "TEST-0074 declared scenario has no canonical evidence authority: $testId."
    }
}
foreach ($testId in @($authorityByTestId.Keys | Sort-Object)) {
    if (-not $scenarioDeclarations.ContainsKey($testId)) {
        Add-Failure "TEST-0074 scenario authority has no canonical declaration: $testId."
        continue
    }

    $authority = $authorityByTestId[$testId]
    if ($authority.Evidence -ceq 'HistoricalSuperseded') {
        $declaration = $scenarioDeclarations[$testId][0]
        $replacementIds = @([regex]::Matches($declaration.Line, 'TEST-\d{4}') |
            ForEach-Object { $_.Value } | Where-Object { $_ -cne $testId })
        if ($declaration.Path -cne $authority.Owner -or
            $declaration.Line -cnotmatch '\|\s*Superseded(?:\s*\([^|]+\))?\s*\|' -or
            $replacementIds.Count -eq 0) {
            Add-Failure "TEST-0074 superseded scenario lacks its status or replacement identity: $testId."
        }

        foreach ($activeTestSource in @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') `
            -Recurse -File -Filter '*.ps1')) {
            $activeContent = Get-Content -LiteralPath $activeTestSource.FullName -Raw
            if ([regex]::IsMatch($activeContent, "(?<![A-Za-z0-9-])$testId(?![A-Za-z0-9-])")) {
                Add-Failure "TEST-0074 superseded scenario is still asserted by $($activeTestSource.Name): $testId."
            }
        }
    }
}

$suppressedSourcePath = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-suppressed-scenario-$([guid]::NewGuid().ToString('N')).ps1"
try {
    [IO.File]::WriteAllText(
        $suppressedSourcePath,
        @"
Add-Failure 'TEST-9000 executed assertion'
`$scenarioResult = [ordered]@{
    schema = 1
    owner = 'tests/synthetic.tests.ps1'
    passed = @('TEST-9000', 'TEST-9001')
}
"@,
        [Text.UTF8Encoding]::new($false)
    )
    $suppressedSourceIds = @(Get-MeAndAISourceBoundScenarioIds `
        -SourcePaths @($suppressedSourcePath))
    $suppressedComparison = Compare-MeAndAIExactScenarioId `
        -Expected @('TEST-9000', 'TEST-9001') -Observed $suppressedSourceIds
    if ($suppressedComparison.Valid -or
        -not $suppressedComparison.Message.Contains('missing=[TEST-9001]')) {
        Add-Failure 'TEST-0091 hard-coded output survived a removed scenario assertion.'
    }
}
finally {
    Remove-Item -LiteralPath $suppressedSourcePath -Force -ErrorAction SilentlyContinue
}

$versionNeutralConsumerFiles = @(
    'templates/project/.ai/memory/README.md',
    'templates/project/.ai/memory/project.md',
    'templates/project/AGENTS.submodule.md',
    'templates/project/docs/ideas/README.md',
    'templates/project/AGENTS.repository-reference.md'
)
foreach ($relativePath in $versionNeutralConsumerFiles) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure "TEST-0114 version-neutral consumer template is missing: $relativePath."
        continue
    }
    $templateContent = Get-Content -LiteralPath $fullPath -Raw
    if ($templateContent -match '(?i)pinned common protocol\s*:' -or
        $templateContent -match 'https://github\.com/hasanmanzak/meAndAI/(?:blob|tree)/v[0-9]+\.[0-9]+\.[0-9]+' -or
        $templateContent -match '(?im)^\s*(?:current protocol|immutable ref)\s*:\s*`?v[0-9]+\.[0-9]+\.[0-9]+') {
        Add-Failure "TEST-0114 consumer template retains a second live protocol pin: $relativePath."
    }
}
if (-not (Get-Content -LiteralPath (Join-Path $root 'PROTOCOL.md') -Raw).Contains(
    'sole current protocol-pin authority'
)) {
    Add-Failure 'TEST-0114 protocol does not define one live consumer pin authority.'
}

if ($failures.Count -gt 0) {
    Write-Host "Protocol validation failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

function Test-CanonicalProtocolVersion {
    param([AllowEmptyString()][string]$Value)

    return $Value -cmatch '^(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$'
}

foreach ($validVersion in @(
    '0.0.0', '0.8.4', '1.0.0', '10.20.300',
    '92233720368547758081234567890.2147483648.999999999999999999999999'
)) {
    if (-not (Test-CanonicalProtocolVersion -Value $validVersion)) {
        Add-Failure "TEST-0002/TEST-0088 canonical version fixture was rejected: '$validVersion'"
    }
}
foreach ($invalidVersion in @(
    '', 'v0.8.4', '01.0.0', '0.01.0', '0.0.01', '+1.0.0',
    '1.0', '1.0.0.0', '1.0.-1', ' 1.0.0', '1.0.0 ',
    ([string][char]0x0661 + '.0.0'), ([string][char]0xFF11 + '.0.0')
)) {
    if (Test-CanonicalProtocolVersion -Value $invalidVersion) {
        Add-Failure "TEST-0002/TEST-0088 noncanonical version fixture was accepted: '$invalidVersion'"
    }
}

$v084Memory = Get-Content -LiteralPath (
    Join-Path $root '.ai/memory/log/2026-07-16-v084-correction.md'
) -Raw
$v084Scenarios = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0013-v084-correction/test-cases.md'
) -Raw
$v084Feature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0013-v084-correction/README.md'
) -Raw
$protocolFeatureScenarios = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0001-common-development-protocol/test-cases.md'
) -Raw
$canonicalDisposition = 'nine `Blocking` findings, one `OptionalImprovement`, and one `ExternalOrLegacyFollowUp`'
$normalizedV084Memory = [regex]::Replace($v084Memory, '\s+', ' ')
$normalizedV084Scenarios = [regex]::Replace($v084Scenarios, '\s+', ' ')
if (-not $normalizedV084Memory.Contains($canonicalDisposition) -or
    -not $normalizedV084Scenarios.Contains("$canonicalDisposition remained")) {
    Add-Failure 'TEST-0092 v0.8.4 durable records do not use the canonical finding disposition counts.'
}
if ($protocolFeatureScenarios -notmatch [regex]::Escape(
    '| `TEST-0002` <a name="test-0002"></a> | [SUBF-0001](README.md#subf-0001) | `VERSION` is evaluated against `M.m.rev`. | Exactly three ASCII decimal components are accepted, with no leading zero unless the component is exactly `0`.'
)) {
    Add-Failure 'TEST-0088/TEST-0092 TEST-0002 does not state the canonical ASCII/no-leading-zero grammar.'
}
foreach ($stableProjection in @(
    '[#41](https://github.com/hasanmanzak/meAndAI/issues/41)',
    '[#42](https://github.com/hasanmanzak/meAndAI/pull/42)',
    '[DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md)',
    '[`FIND-0120` / #44](https://github.com/hasanmanzak/meAndAI/issues/44)',
    '`ExternalOrLegacyFollowUp` / Open; maintainer owned'
)) {
    if (-not $v084Feature.Contains($stableProjection)) {
        Add-Failure "TEST-0092 v0.8.4 canonical projection is missing '$stableProjection'."
    }
}

$implementedScenarioPaths = @(
    'docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md',
    'docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md',
    'docs/features/FEAT-0008-idea-incubation/test-cases.md',
    'docs/features/FEAT-0012-v082-correction/test-cases.md'
)
foreach ($relativePath in $implementedScenarioPaths) {
    $scenarioText = Get-Content -LiteralPath (Join-Path $root $relativePath) -Raw
    if ($scenarioText -match '(?im)^Planned (?:test )?implementations?:') {
        Add-Failure "TEST-0085 completed scenario record still describes its implementation as planned: $relativePath"
    }
}
$completedCorrection = Get-Content -LiteralPath `
    (Join-Path $root 'docs/features/FEAT-0012-v082-correction/README.md') -Raw
foreach ($stablePullRequest in @(
    'https://github.com/hasanmanzak/meAndAI/pull/39',
    'https://github.com/hasanmanzak/meAndAI/pull/40'
)) {
    if (-not $completedCorrection.Contains($stablePullRequest)) {
        Add-Failure "TEST-0085 FEAT-0012 is missing stable merged pull-request link '$stablePullRequest'."
    }
}

$versionPath = Join-Path $root 'VERSION'
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
    $version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
    if (-not (Test-CanonicalProtocolVersion -Value $version)) {
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

        foreach ($fixtureRoot in @('scripts', 'templates/project', 'tests')) {
            $absoluteFixtureRoot = Join-Path $root $fixtureRoot
            foreach ($file in @(Get-ChildItem -LiteralPath $absoluteFixtureRoot `
                -Recurse -File | Where-Object {
                    $_.Extension -cin @('.ps1', '.psm1', '.psd1', '.yml', '.yaml')
                })) {
                $relativePath = $file.FullName.Substring($root.Length + 1)
                $content = Get-Content -LiteralPath $file.FullName -Raw
                $escapedReferences = [regex]::Matches(
                    $content, 'v\d+\\\.\d+\\\.\d+'
                )
                foreach ($escapedReference in $escapedReferences) {
                    $normalizedReference = [string]$escapedReference.Value -replace '\\', ''
                    if ($normalizedReference -cne $currentReference) {
                        Add-Failure "TEST-0006 stale escaped protocol reference in $relativePath"
                        break
                    }
                }
            }
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
        $currentTargetFeatures = [System.Collections.Generic.List[string]]::new()
        foreach ($featureFile in $featureFiles) {
            $feature = Get-Content -LiteralPath $featureFile.FullName -Raw
            $featureMetadata = [regex]::Match(
                $feature,
                '(?ms)\A# [^\r\n]+\r?\n\r?\n(?<table>\| Field \| Value \|\r?\n\| --- \| --- \|\r?\n(?:\|[^\r\n]*\|\r?\n?)+)'
            )
            if (-not $featureMetadata.Success -or
                $featureMetadata.Groups['table'].Value -notmatch
                    '(?m)^\| Target version \| \d+\.\d+\.\d+ \|\s*$') {
                Add-Failure "TEST-0006 invalid historical target version in $($featureFile.FullName)"
            }
            $metadataTable = $featureMetadata.Groups['table'].Value
            if ($metadataTable -match
                ('(?m)^\| Target version \| {0} \|\s*$' -f [regex]::Escape($version))) {
                $currentTargetFeatures.Add($featureFile.FullName)
                if ($metadataTable -notmatch '(?m)^\| Status \| Complete \|\s*$') {
                    Add-Failure "TEST-0092 current release feature is not complete before publication: $($featureFile.FullName)"
                }

                $definitionOfDone = [regex]::Match(
                    $feature,
                    '(?ms)^## Definition of Done\s*(?<body>.*?)(?=^## |\z)'
                )
                if (-not $definitionOfDone.Success) {
                    Add-Failure "TEST-0092 current release feature has no Definition of Done: $($featureFile.FullName)"
                }
                elseif ($definitionOfDone.Groups['body'].Value -match
                    '(?im)^- \[[ x]\].*(?:post-publication|release evidence)') {
                    Add-Failure "TEST-0092 post-publication work is mixed into the pre-merge Definition of Done: $($featureFile.FullName)"
                }
            }
        }
        if ($currentTargetFeatures.Count -eq 0) {
            Add-Failure "TEST-0092 no feature targets current protocol version $version."
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
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0056'

$rootRunnerPath = Join-Path $root 'tests/protocol.tests.ps1'
$validatorSource = (Get-Content -LiteralPath $rootRunnerPath -Raw) + "`n" +
    (Get-Content -LiteralPath $PSCommandPath -Raw)
foreach ($requiredText in @(
    'Get-IndexedMarkdownTargets',
    'ls-files --cached --others',
    'Get-MeAndAITestSuite',
    'Import-MeAndAITestExecutionProfile',
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
    'persist-credentials: false', 'runs-on: ubuntu-latest', 'shell: pwsh',
    'runs-on: windows-latest', 'shell: powershell',
    'Parse consumer workflow YAML', "require 'yaml'"
)) {
    if (-not $ciWorkflow.Contains($requiredText)) {
        Add-Failure "TEST-0067 repository CI compatibility contract is missing '$requiredText'"
    }
}
if ($ciWorkflow.Contains('shell: ${{ matrix.shell }}')) {
    Add-Failure 'TEST-0067 repository CI uses matrix context where the shell field does not permit it.'
}
$protocolMandateSource = Get-Content -LiteralPath (Join-Path $root 'PROTOCOL.md') -Raw
$normalizedProtocolMandateSource = [regex]::Replace($protocolMandateSource, '\s+', ' ')
foreach ($requiredMandateText in @(
    'MUST minimize total hosted runner consumption',
    'MUST NOT create redundant job, matrix, setup, checkout, or fan-in load',
    'newer run wholly supersedes the same pull request',
    'wall-clock latency alone is not runner-efficiency evidence'
)) {
    if (-not $normalizedProtocolMandateSource.Contains($requiredMandateText)) {
        Add-Failure "TEST-0124 hosted runner-efficiency mandate is missing '$requiredMandateText'."
    }
}
foreach ($requiredEfficiencyText in @(
    'The `test-runtime-efficiency` semantic capability applies',
    'Equivalent immutable setup MUST build once at the narrowest safe lifecycle scope',
    'every mutable case MUST receive a distinct isolated derivative or overlay',
    'machine-readable fixture and operation evidence',
    'Increasing an expensive-operation budget or broadening fixture lifecycle scope requires explicit linked review and rationale',
    'Elapsed time remains observational'
)) {
    if (-not $normalizedProtocolMandateSource.Contains($requiredEfficiencyText)) {
        Add-Failure "TEST-0001 test-runtime-efficiency protocol contract is missing '$requiredEfficiencyText'."
    }
}

$quickAdoptionSuitePath = Join-Path $root `
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
$quickAdoptionSuiteSource = Get-Content -LiteralPath $quickAdoptionSuitePath -Raw
$streamingSuitePath = Join-Path $root `
    'tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1'
$streamingSuiteSource = Get-Content -LiteralPath $streamingSuitePath -Raw
$selectorPath = Join-Path $root `
    'tests/capabilities/windows-validation/Select-WindowsValidationProfile.ps1'
$selectorSource = if (Test-Path -LiteralPath $selectorPath -PathType Leaf) {
    Get-Content -LiteralPath $selectorPath -Raw
}
else { '' }
$validatorTokens = $null
$validatorParseErrors = $null
$validatorAst = [Management.Automation.Language.Parser]::ParseFile(
    $rootRunnerPath,
    [ref]$validatorTokens,
    [ref]$validatorParseErrors
)
$quickTokens = $null
$quickParseErrors = $null
$quickAst = [Management.Automation.Language.Parser]::ParseFile(
    $quickAdoptionSuitePath,
    [ref]$quickTokens,
    [ref]$quickParseErrors
)
$validatorParameterNames = @($validatorAst.ParamBlock.Parameters | ForEach-Object {
    $_.Name.VariablePath.UserPath
})
$quickParameterNames = @($quickAst.ParamBlock.Parameters | ForEach-Object {
    $_.Name.VariablePath.UserPath
})
if ($validatorParseErrors.Count -ne 0 -or
    $validatorParameterNames -cnotcontains 'ExecutionProfile') {
    Add-Failure 'TEST-0124 root validation lacks its constrained execution-profile contract.'
}
if ($quickParseErrors.Count -ne 0 -or $quickParameterNames -cnotcontains 'Shard') {
    Add-Failure 'TEST-0124 quick-adoption validation lacks its explicit shard contract.'
}
$diagnosticQuickAdoptionShards = @(
    'ContractsPreflight',
    'AdoptionLifecycle',
    'IntegrityCompletedGraph',
    'IntegrityManifestIssue',
    'IntegrityCodexFailure',
    'IntegrityMetadataCredential',
    'RepositoryRoutes'
)
foreach ($shardName in $diagnosticQuickAdoptionShards) {
    if (-not $quickAdoptionSuiteSource.Contains("'$shardName'")) {
        Add-Failure "TEST-0124 local diagnostic shard '$shardName' is no longer available."
    }
}
if ($ciWorkflow.Contains('- IntegrityFailures') -or
    $quickAdoptionSuiteSource.Contains("'IntegrityFailures'")) {
    Add-Failure 'TEST-0124 legacy monolithic IntegrityFailures routing is active.'
}
foreach ($requiredWorkflowText in @(
    'merge_group:',
    'concurrency:',
    "cancel-in-progress: `${{ github.event_name == 'pull_request' }}",
    'linux-validation:',
    'windows-validation:',
    'name: Validate on windows-latest',
    'fetch-depth: 0',
    'id: windows-profile',
    'tests/capabilities/windows-validation/Select-WindowsValidationProfile.ps1',
    'ExecutionProfile',
    'steps.windows-profile.outputs.profile'
)) {
    if (-not $ciWorkflow.Contains($requiredWorkflowText)) {
        Add-Failure "TEST-0124 efficient workflow is missing '$requiredWorkflowText'."
    }
}
foreach ($forbiddenWorkflowText in @(
    'windows-base:',
    'windows-quick-adoption:',
    'matrix:',
    'needs.windows-base.result',
    'needs.windows-quick-adoption.result'
)) {
    if ($ciWorkflow.Contains($forbiddenWorkflowText)) {
        Add-Failure "TEST-0124 obsolete hosted fan-out remains active: '$forbiddenWorkflowText'."
    }
}
if ([regex]::Matches($ciWorkflow, '(?m)^\s+runs-on:\s+windows-latest\s*$').Count -ne 1 -or
    [regex]::Matches($ciWorkflow, '(?m)^\s+name:\s+Validate on windows-latest\s*$').Count -ne 1) {
    Add-Failure 'TEST-0124 ordinary validation must expose exactly one real Windows runner and one stable Windows check identity.'
}
$linuxJobIndex = $ciWorkflow.IndexOf("`n  linux-validation:", [StringComparison]::Ordinal)
$windowsJobIndex = $ciWorkflow.IndexOf("`n  windows-validation:", [StringComparison]::Ordinal)
$postPublicationIndex = $ciWorkflow.IndexOf("`n  post-publication:", [StringComparison]::Ordinal)
if ($linuxJobIndex -lt 0 -or $windowsJobIndex -le $linuxJobIndex -or
    $postPublicationIndex -le $windowsJobIndex) {
    Add-Failure 'TEST-0124 Linux, Windows, and post-publication job boundaries are missing or unordered.'
}
else {
    $linuxJobSource = $ciWorkflow.Substring(
        $linuxJobIndex,
        $windowsJobIndex - $linuxJobIndex
    )
    $windowsJobSource = $ciWorkflow.Substring(
        $windowsJobIndex,
        $postPublicationIndex - $windowsJobIndex
    )
    $postPublicationJobSource = $ciWorkflow.Substring($postPublicationIndex)
    if (-not $windowsJobSource.Contains('runs-on: windows-latest') -or
        $windowsJobSource.Contains('needs:') -or
        $windowsJobSource.Contains('matrix:')) {
        Add-Failure 'TEST-0124 stable Windows check is not the single executing Windows job.'
    }
    if (-not [regex]::IsMatch(
        $windowsJobSource,
        '(?m)^ {4}timeout-minutes: 35\r?$'
    )) {
        Add-Failure 'TEST-0124 Windows full validation timeout does not cover the measured serial-suite budget.'
    }
    if (-not [regex]::IsMatch(
        $linuxJobSource,
        '(?m)^ {4}timeout-minutes: 20\r?$'
    ) -or -not [regex]::IsMatch(
        $postPublicationJobSource,
        '(?m)^ {4}timeout-minutes: 5\r?$'
    )) {
        Add-Failure 'TEST-0124 unchanged Linux and post-publication timeout bounds are not exact.'
    }
}
foreach ($requiredProfileText in @(
    "'WindowsNative'",
    'MEANDAI_COMPATIBILITY_SHARD_RESULT=',
    "if (`$Shard -ceq 'All')"
)) {
    if (-not $quickAdoptionSuiteSource.Contains($requiredProfileText)) {
        Add-Failure "TEST-0124 quick-adoption native profile is missing '$requiredProfileText'."
    }
}
foreach ($requiredStreamingText in @(
    "'WindowsNative'",
    'MEANDAI_COMPATIBILITY_SHARD_RESULT='
)) {
    if (-not $streamingSuiteSource.Contains($requiredStreamingText)) {
        Add-Failure "TEST-0124 streaming native profile is missing '$requiredStreamingText'."
    }
}
foreach ($requiredSelectorText in @(
    "[ValidateSet('pull_request', 'push', 'workflow_dispatch', 'merge_group')]",
    '--no-renames',
    'WindowsNative',
    'Full',
    '300'
)) {
    if (-not $selectorSource.Contains($requiredSelectorText)) {
        Add-Failure "TEST-0124 fail-safe selector is missing '$requiredSelectorText'."
    }
}
$normalValidationGuard = "if: `${{ !(github.event_name == 'workflow_dispatch' && inputs.verify_post_publication) }}"
if ([regex]::Matches(
    $ciWorkflow,
    [regex]::Escape($normalValidationGuard)
).Count -ne 2) {
    Add-Failure 'TEST-0118 Linux and Windows ordinary jobs do not share the exact release-only inverse guard.'
}
$postPublicationGuard = "if: github.event_name == 'workflow_dispatch' && inputs.verify_post_publication"
if (-not $ciWorkflow.Contains($postPublicationGuard)) {
    Add-Failure 'TEST-0118 the post-publication verifier lacks its positive release-only guard.'
}
$quickFunctionNames = @($quickAst.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst]
}, $true) | ForEach-Object { $_.Name })
foreach ($fixtureFunction in @(
    'Initialize-QuickAdoptionImmutableFixture',
    'Assert-QuickAdoptionImmutableFixture',
    'Copy-QuickAdoptionReleaseArchive'
)) {
    if ($quickFunctionNames -cnotcontains $fixtureFunction) {
        Add-Failure "TEST-0116 quick-adoption suite is missing fixture function '$fixtureFunction'."
    }
}
foreach ($requiredText in @(
    'Install checksummed actionlint v1.7.12',
    'ACTIONLINT_VERSION: 1.7.12',
    'ACTIONLINT_SHA256: 8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8',
    'actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz',
    'sha256sum --check --strict',
    'Run actionlint semantic workflow validation',
    '.github/workflows/protocol-tests.yml',
    'templates/project/.github/workflows/meandai-protocol-update.yml'
)) {
    if (-not $ciWorkflow.Contains($requiredText)) {
        Add-Failure "TEST-0075 recurring actionlint semantic gate is missing '$requiredText'."
    }
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
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0066'

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
    $display = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    $isConsumerTemplate = $display.StartsWith(
        'templates/project/', [StringComparison]::Ordinal
    )
    $consumerTemplateDestination = ''
    if ($isConsumerTemplate) {
        $templateRelative = $display.Substring('templates/project/'.Length)
        $consumerTemplateDestination = if ($templateRelative -cin @(
            'AGENTS.submodule.md', 'AGENTS.repository-reference.md'
        )) {
            'AGENTS.md'
        }
        else { $templateRelative }
    }
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
            if ($isConsumerTemplate) {
                $consumerDirectory = Split-Path -Parent (Join-Path $root `
                    ($consumerTemplateDestination -replace '/', [IO.Path]::DirectorySeparatorChar))
                $consumerTarget = [IO.Path]::GetFullPath((Join-Path $consumerDirectory `
                    ($relativeTarget -replace '/', [IO.Path]::DirectorySeparatorChar)))
                $consumerRelative = $consumerTarget.Substring($root.Length + 1).Replace('\', '/')
                if ($consumerRelative.StartsWith(
                    '.ai/protocol/', [StringComparison]::Ordinal
                )) {
                    $targetFile = Join-Path $root `
                        $consumerRelative.Substring('.ai/protocol/'.Length)
                }
                else {
                    $targetFile = Join-Path (Join-Path $root 'templates/project') `
                        ($consumerRelative -replace '/', [IO.Path]::DirectorySeparatorChar)
                }
            }
            else {
                $targetFile = [System.IO.Path]::GetFullPath(
                    (Join-Path $file.DirectoryName ($relativeTarget -replace '/', [System.IO.Path]::DirectorySeparatorChar))
                )
            }
            $rootPrefix = $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $targetFile.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                Add-Failure "TEST-0003 local link escapes repository in $display -> $target"
                continue
            }
            if (-not (Test-Path -LiteralPath $targetFile)) {
                Add-Failure "TEST-0003 broken local link in $display -> $target"
                continue
            }
        }

        if ($fragment) {
            if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf)) {
                Add-Failure "TEST-0003 unsupported fragment target in $display -> $target"
            }
            elseif ([System.IO.Path]::GetExtension($targetFile) -ieq '.md') {
                $targetMarkdown = Get-Content -LiteralPath $targetFile -Raw
                $anchors = Get-MarkdownAnchors $targetMarkdown
                if (-not $anchors.Contains($fragment)) {
                    Add-Failure "TEST-0003 missing anchor in $display -> $target"
                }
            }
            else {
                $targetTextEvidence = Get-Utf8TextEvidence `
                    -Bytes ([IO.File]::ReadAllBytes($targetFile))
                if (-not $targetTextEvidence.IsText -or
                    -not (Test-CanonicalGitHubLineFragment `
                        -Fragment $fragment `
                        -LineCount $targetTextEvidence.LineCount)) {
                    Add-Failure "TEST-0003 invalid non-Markdown line fragment in $display -> $target"
                }
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
    'finding.yml' = @('[FIND-NNNN]', 'type:finding', 'id: disposition', 'id: classification', 'id: category', 'id: severity', 'id: confidence')
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

$findingForm = Get-Content -LiteralPath (Join-Path $root '.github/ISSUE_TEMPLATE/finding.yml') -Raw
$dispositionBlock = [regex]::Match(
    $findingForm,
    '(?ms)^  - type: dropdown\r?\n    id: disposition\r?\n(?<body>.*?)(?=^  - type:|\z)'
)
$classificationBlock = [regex]::Match(
    $findingForm,
    '(?ms)^  - type: dropdown\r?\n    id: classification\r?\n(?<body>.*?)(?=^  - type:|\z)'
)
$expectedDispositions = @(
    'Blocking', 'AcceptedResidual', 'ExternalOrLegacyFollowUp', 'OptionalImprovement'
)
$actualDispositions = if ($dispositionBlock.Success) {
    @([regex]::Matches($dispositionBlock.Groups['body'].Value, '(?m)^        - (?<value>\S[^\r\n]*)$') |
        ForEach-Object { $_.Groups['value'].Value })
}
else { @() }
$expectedClassifications = @('Confirmed defect', 'Risk', 'Optional improvement')
$actualClassifications = if ($classificationBlock.Success) {
    @([regex]::Matches($classificationBlock.Groups['body'].Value, '(?m)^        - (?<value>\S[^\r\n]*)$') |
        ForEach-Object { $_.Groups['value'].Value })
}
else { @() }
if (($actualDispositions -join '|') -cne ($expectedDispositions -join '|') -or
    ($actualClassifications -join '|') -cne ($expectedClassifications -join '|')) {
    Add-Failure 'TEST-0084 finding form must keep the four exact review dispositions separate from defect/risk/improvement classification.'
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
Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0047'

$protocolContent = Get-Content -LiteralPath (Join-Path $root 'PROTOCOL.md') -Raw
$localInstructions = Get-Content -LiteralPath (Join-Path $root 'AGENTS.md') -Raw
$featureTemplate = Get-Content -LiteralPath (Join-Path $root 'templates/feature/README.md') -Raw
$normalizedProtocolContent = [regex]::Replace($protocolContent, '\s+', ' ')
$normalizedLocalInstructions = [regex]::Replace($localInstructions, '\s+', ' ')

# TEST-0173: a reusable defect exposed by one consumer remains owned by the
# common authority, and its canonical correction carries no external consumer
# repository identity or local-machine path.
foreach ($requiredText in @(
    'classify its owning layer before correction',
    'project-neutral regression',
    'MUST NOT be presented as generic closure',
    'MUST NOT encode a named consumer',
    'does not authorize scanning or mutating unrelated consumer repositories'
)) {
    if (-not $normalizedProtocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0173 common upstream-ownership mandate is missing '$requiredText'."
    }
}
foreach ($requiredText in @(
    'classify the owning layer',
    'corrected and proven in meAndAI',
    'project-neutral fixture and immutable release',
    'do not close common work with a named-consumer patch',
    'consumer recovery as a separate, linked operation'
)) {
    if (-not $normalizedLocalInstructions.Contains($requiredText)) {
        Add-Failure "TEST-0173 local upstream-ownership mandate is missing '$requiredText'."
    }
}
$canonicalEvidenceArtifacts = @(
    'capabilities/canonical-repository-evidence.json',
    'scripts/MeAndAI.RepositoryEvidence.psm1',
    'docs/decisions/DEC-0028-upstream-owned-reusable-corrections.md',
    'docs/features/FEAT-0045-v0140-canonical-repository-evidence/README.md',
    'docs/features/FEAT-0045-v0140-canonical-repository-evidence/test-cases.md'
)
foreach ($relativePath in $canonicalEvidenceArtifacts) {
    $artifactPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        Add-Failure "TEST-0173 missing canonical evidence artifact: $relativePath"
        continue
    }
    $artifactContent = Get-Content -LiteralPath $artifactPath -Raw
    if ($artifactContent -cmatch '(?i)(?<![a-z])[a-z]:[\\/]' -or
        $artifactContent -cmatch '(?i)/(?:home|users)/[^/\s]+/' -or
        @([regex]::Matches(
            $artifactContent,
            'https://github\.com/(?<repository>[^/\s)]+/[^/\s)#]+)'
        ) | Where-Object {
            $_.Groups['repository'].Value -cne 'hasanmanzak/meAndAI'
        }).Count -gt 0) {
        Add-Failure "TEST-0173 canonical evidence artifact is consumer- or machine-coupled: $relativePath"
    }
}

# TEST-0174: protocol-provided reusable assets remain single-owned upstream;
# consumers reuse the pinned authority and contain only project-specific work.
foreach ($requiredText in @(
    'Protocol-provided reusable assets include code, tests, fixtures, validators, workflows, templates, prompts, scripts, and documentation',
    'MUST reuse or reference those assets through the pinned protocol integration',
    'MUST NOT copy, reimplement, port, shadow, fork, or maintain consumer-local equivalents',
    'genuinely project-specific integration, configuration, domain behavior, or semantic evidence',
    'missing, defective, or insufficient common asset MUST be corrected and tested in meAndAI',
    'An exact protocol-declared managed projection is not a consumer-owned equivalent',
    'immutable-release-declared source path, canonical consumer target path, exact content digest or Git blob, and lifecycle',
    'MUST be installed and updated only by deterministic protocol automation',
    'does not authorize consumer-local tests, fixtures, validators, or shadow implementations'
)) {
    if (-not $normalizedProtocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0174 consumer non-duplication mandate is missing '$requiredText'."
    }
}
$upstreamDecisionPath = Join-Path $root `
    'docs/decisions/DEC-0028-upstream-owned-reusable-corrections.md'
$normalizedUpstreamDecision = [regex]::Replace(
    (Get-Content -LiteralPath $upstreamDecisionPath -Raw),
    '\s+',
    ' '
)
foreach ($requiredText in @(
    'Protocol-provided reusable assets are single-owned by meAndAI',
    'must not reproduce their implementation or generic regression evidence',
    'project-specific adapter, configuration, domain behavior, or semantic assessment',
    'immutable-release-declared source path, canonical consumer target path, exact content digest or Git blob, and lifecycle',
    'MUST be installed and updated only by deterministic protocol automation',
    'does not permit consumer-local tests, fixtures, validators, or shadow implementations'
)) {
    if (-not $normalizedUpstreamDecision.Contains($requiredText)) {
        Add-Failure "TEST-0174 DEC-0028 non-duplication boundary is missing '$requiredText'."
    }
}
foreach ($requiredText in @(
    'Protocol-provided reusable assets must not be copied, reimplemented, or retested in a consumer',
    'Consumer changes are limited to genuinely project-specific integration, configuration, domain behavior, and semantic evidence',
    'correct the common asset and its regression in meAndAI first'
)) {
    if (-not $normalizedLocalInstructions.Contains($requiredText)) {
        Add-Failure "TEST-0174 local non-duplication instruction is missing '$requiredText'."
    }
}
$managedProjectionContracts = @(
    [pscustomobject]@{
        Path = 'PROTOCOL.md'
        Required = 'consumer-resident, protocol-owned managed projection'
    },
    [pscustomobject]@{
        Path = 'docs/adoption.md'
        Required = 'consumer-resident, protocol-owned managed projection'
    },
    [pscustomobject]@{
        Path = 'docs/decisions/DEC-0003-reviewed-consumer-update-supersession.md'
        Required = 'consumer-resident, protocol-owned scheduled/manual workflow projection'
    },
    [pscustomobject]@{
        Path = 'docs/decisions/DEC-0006-seed-workflow-adoption-handoff.md'
        Required = 'consumer-resident, protocol-owned managed updater'
    },
    [pscustomobject]@{
        Path = 'docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md'
        Required = 'consumer-resident, protocol-owned workflow projection'
    }
)
foreach ($contract in $managedProjectionContracts) {
    $content = [regex]::Replace(
        (Get-Content -LiteralPath (Join-Path $root $contract.Path) -Raw),
        '\s+',
        ' '
    )
    if (-not $content.Contains($contract.Required)) {
        Add-Failure "TEST-0174 managed projection ownership is inconsistent in '$($contract.Path)'."
    }
    if ($content -match 'consumer-owned (?:update workflow|updater)' -or
        $content -match 'workflow is consumer-owned') {
        Add-Failure "TEST-0174 legacy consumer-owned updater terminology remains in '$($contract.Path)'."
    }
}
$adoptionContent = Get-Content -LiteralPath (
    Join-Path $root 'docs/adoption.md'
) -Raw
$managedAutomationSection = [regex]::Match(
    $adoptionContent,
    '(?ms)^Submodule consumers also materialize these submodule-only automation assets:\s+(?<table>.*?)(?:\r?\n){2}'
)
if (-not $managedAutomationSection.Success -or
    -not $managedAutomationSection.Groups['table'].Value.Contains(
        '| Pinned source | Consumer-resident managed target |'
    )) {
    Add-Failure 'TEST-0174 adoption guide does not classify exact updater assets as consumer-resident managed projections.'
}

# TEST-0175: every cross-record reference authored in a document or
# GitHub issue, pull request, or comment is a clickable link to its exact target.
$originalLinkValidationCulture =
    [Threading.Thread]::CurrentThread.CurrentCulture
[Threading.Thread]::CurrentThread.CurrentCulture =
    [Globalization.CultureInfo]::InvariantCulture
foreach ($requiredText in @(
    'document (repository-local or external), GitHub issue, pull request, or GitHub comment of any kind',
    'another document (repository-local or external), issue, pull request, GitHub comment, or commit',
    'MUST express each human-facing reference as a clickable link to the exact referenced target',
    'A free-text identifier, number, title, path, or commit hash does not satisfy this requirement',
    'Governed clickable references MUST use a renderer-active Markdown inline link, reference-style link, or absolute HTTP(S) autolink',
    'Raw HTML `href` elements are not a supported reference-authoring form'
)) {
    if (-not $normalizedProtocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0175 clickable cross-record reference rule is missing '$requiredText'."
    }
}
foreach ($requiredText in @(
    'the link MUST include a stable fragment that positions the reader at that record or location',
    'Every canonical embedded stable-ID record, including each `TEST-NNNN`, `SUBF-NNNN`, `FIND-NNNN`, and `RISK-NNNN` record',
    'MUST expose one unique, renderer-active custom anchor within its canonical declaration whose name is the exact lowercase identifier',
    'Cross-document references to that record MUST target that anchor',
    'A link authored in a repository file to a current canonical repository record or location MUST be repository-relative and include any required fragment',
    'A fragment on a Markdown document targets one unique renderer-active anchor',
    'A fragment on a non-Markdown repository blob uses GitHub''s exact `#Lstart` or `#Lstart-Lend` form and MUST identify lines within that blob'
)) {
    if (-not $normalizedProtocolContent.Contains($requiredText)) {
        Add-Failure "TEST-0177 embedded-record anchor/fragment rule is missing '$requiredText'."
    }
}
$referencePrompt = 'Use clickable links to the exact referenced records; free-text identifiers, numbers, titles, paths, or commit hashes do not satisfy a reference.'
foreach ($formName in $formExpectations.Keys) {
    $formContent = Get-Content -LiteralPath (
        Join-Path $root ".github/ISSUE_TEMPLATE/$formName"
    ) -Raw
    if (-not $formContent.Contains($referencePrompt)) {
        Add-Failure "TEST-0175 $formName does not require clickable exact-target references."
    }
}
if (-not $pullRequestTemplate.Contains($referencePrompt)) {
    Add-Failure 'TEST-0175 pull-request template does not require clickable exact-target references.'
}
foreach ($templatePath in @(
    'templates/feature/README.md',
    'templates/feature/test-cases.md',
    'templates/decision.md',
    'templates/idea.md'
)) {
    $templateContent = Get-Content -LiteralPath (Join-Path $root $templatePath) -Raw
    if (-not $templateContent.Contains($referencePrompt)) {
        Add-Failure "TEST-0175 $templatePath does not require clickable exact-target references."
    }
}
foreach ($embeddedTemplateExpectation in @(
    [pscustomobject]@{
        Path = 'templates/feature/README.md'
        Text = '| `SUBF-NNNN` <a name="subf-nnnn"></a> |'
    },
    [pscustomobject]@{
        Path = 'templates/feature/README.md'
        Text = '| `RISK-NNNN` <a name="risk-nnnn"></a> |'
    },
    [pscustomobject]@{
        Path = 'templates/feature/README.md'
        Text = '| `FIND-NNNN` <a name="find-nnnn"></a> |'
    },
    [pscustomobject]@{
        Path = 'templates/feature/test-cases.md'
        Text = '| `TEST-NNNN` <a name="test-nnnn"></a> |'
    },
    [pscustomobject]@{
        Path = 'templates/feature/test-cases.md'
        Text = '[SUBF-NNNN](README.md#subf-nnnn)'
    }
)) {
    $embeddedTemplate = Get-Content -LiteralPath (
        Join-Path $root $embeddedTemplateExpectation.Path
    ) -Raw
    if (-not $embeddedTemplate.Contains($embeddedTemplateExpectation.Text)) {
        Add-Failure "TEST-0177 $($embeddedTemplateExpectation.Path) is missing required embedded-record anchor/link structure '$($embeddedTemplateExpectation.Text)'."
    }
}
foreach ($requiredWorkflowText in @(
    'pull_request_number:',
    'pull-requests: read',
    'MEANDAI_PULL_REQUEST_NUMBER: ${{ inputs.pull_request_number }}',
    'PullRequestNumber = $env:MEANDAI_PULL_REQUEST_NUMBER'
)) {
    if (-not $ciWorkflow.Contains($requiredWorkflowText)) {
        Add-Failure "TEST-0175 post-publication workflow is missing '$requiredWorkflowText'."
    }
}
$proposalOwnershipSource = Get-Content -LiteralPath (Join-Path $root `
    'scripts/quick-adoption/Private/ProposalOwnership.ps1') -Raw
if (-not $proposalOwnershipSource.Contains(
        'Tracking issue: [#$IssueNumber](https://github.com/$Repository/issues/$IssueNumber)'
    )) {
    Add-Failure 'TEST-0175 quick-adoption proposal writer does not emit an exact linked tracking issue.'
}
$managedUpdaterSource = Get-Content -LiteralPath (Join-Path $root `
    'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1') -Raw
foreach ($requiredWriterText in @(
    'Tracking issue: $(New-GitHubIssueLink',
    'Managed protocol proposal: $(New-GitHubPullRequestLink',
    'Finalized managed $($Kind.ToLowerInvariant()) merge $(New-GitHubPullRequestLink',
    'Verified replacement proposal: $(New-GitHubPullRequestLink',
    'Superseded by $(New-GitHubPullRequestLink',
    '[meAndAI changelog entry](https://github.com/$ProtocolRepository/blob/$targetTag/CHANGELOG.md)'
)) {
    if (-not $managedUpdaterSource.Contains($requiredWriterText)) {
        Add-Failure "TEST-0175 protocol-update writer lacks linked artifact output '$requiredWriterText'."
    }
}
foreach ($forbiddenWriterText in @(
    '"Managed protocol proposal: #$PullRequestNumber"',
    '"Tracking issue: #$([int]$issue.number)"',
    '"Tracking issue: #$($updateIssue.Number)"',
    '"Verified replacement proposal: #$ReplacementPullRequestNumber"',
    '"Superseded by #$replacementPullRequestNumber',
    'Read every intervening meAndAI changelog entry.'
)) {
    if ($managedUpdaterSource.Contains($forbiddenWriterText)) {
        Add-Failure "TEST-0175 protocol-update writer retains free-text artifact output '$forbiddenWriterText'."
    }
}
$documentRecordTargets = @{}
$embeddedRecordDeclarations = [System.Collections.Generic.List[object]]::new()
$embeddedRecordDeclarationKeys = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
$embeddedFeatureTableRecordDeclarationPattern =
    '(?m)^\|\s*`(?<id>(?:SUBF|FIND|RISK)-\d{4})`[^|]*\|'
$embeddedTestTableRecordDeclarationPattern =
    '(?m)^\|\s*`(?<id>TEST-\d{4})`[^|]*\|'
$embeddedHeadingRecordDeclarationPattern =
    '(?m)^#{1,6}[ \t]+`?(?<id>(?:TEST|SUBF|FIND|RISK)-\d{4})`?(?=[ \t]|$)[^\r\n]*$'
$embeddedFeatureChecklistDeclarationPattern =
    '(?m)^-\s+(?:\[[ xX]\]\s+`(?<checklistId>(?:SUBF|FIND|RISK)-\d{4})`[^:\r\n]*:|(?:Fresh-diff review found|The first hosted PR run found)\s+`(?<reviewId>FIND-\d{4})`[^\r\n]*)'
function Add-EmbeddedRecordDeclarationKey {
    param(
        [Parameter(Mandatory)]$Registry,
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Path
    )

    return [bool]$Registry.Add("$Path`n$Id")
}
function Add-DocumentRecordTarget {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Path
    )

    if ($documentRecordTargets.ContainsKey($Id) -and
        [string]$documentRecordTargets[$Id] -cne $Path) {
        Add-Failure "TEST-0175 $Id is defined in both '$($documentRecordTargets[$Id])' and '$Path'."
        return
    }
    $documentRecordTargets[$Id] = $Path
}
function Get-DocumentRecordTargetPath {
    param([Parameter(Mandatory)][string]$Target)

    if ($Target.StartsWith('https://')) { return $Target }
    $fragmentIndex = $Target.IndexOf('#')
    if ($fragmentIndex -lt 0) { return $Target }
    return $Target.Substring(0, $fragmentIndex)
}
function Get-EmbeddedRecordAnchorProblems {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Markdown,
        [Parameter(Mandatory)][string]$DeclarationText,
        [AllowEmptyCollection()][object[]]$DocumentAnchors
    )

    $expectedAnchor = $Id.ToLowerInvariant()
    $problems = [System.Collections.Generic.List[string]]::new()
    $activeDocumentAnchors = if (
        $PSBoundParameters.ContainsKey('DocumentAnchors')
    ) { @($DocumentAnchors) } else {
        @(Get-RendererActiveMarkdownAnchorEvidence -Markdown $Markdown)
    }
    $matchingAnchors = @($activeDocumentAnchors | Where-Object {
        [string]$_.Name -ieq $expectedAnchor
    })
    $exactAnchors = @($matchingAnchors | Where-Object {
        [string]$_.Name -ceq $expectedAnchor
    })
    $declarationAnchors = @(
        Get-RendererActiveMarkdownAnchorEvidence `
            -Markdown $DeclarationText | Where-Object {
            [string]$_.Kind -ceq 'Custom'
        }
    )
    $exactDeclarationAnchors = @($declarationAnchors | Where-Object {
        [string]$_.Name -ceq $expectedAnchor
    })

    if ($declarationAnchors.Count -eq 0) {
        if ($exactAnchors.Count -gt 0) {
            $problems.Add('Wrong')
        }
        else {
            $problems.Add('Missing')
        }
    }
    elseif ($declarationAnchors.Count -ne 1 -or
        $exactDeclarationAnchors.Count -ne 1) {
        $problems.Add('Wrong')
    }

    if ($matchingAnchors.Count -gt 0 -and $exactAnchors.Count -eq 0) {
        $problems.Add('WrongCase')
    }
    if ($exactAnchors.Count -gt 1) {
        $problems.Add('Duplicate')
    }
    if (@($matchingAnchors | Where-Object {
            [string]$_.Name -cne $expectedAnchor
        }).Count -gt 0 -and $exactAnchors.Count -gt 0) {
        $problems.Add('CaseCollision')
    }

    return @($problems | Select-Object -Unique)
}
function Add-EmbeddedDocumentRecordTarget {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Markdown,
        [Parameter(Mandatory)][string]$DeclarationText
    )

    if (-not (Add-EmbeddedRecordDeclarationKey `
            -Registry $embeddedRecordDeclarationKeys -Id $Id -Path $Path)) {
        Add-Failure "TEST-0177 $Path contains more than one declaration-shaped plain occurrence of $Id. Secondary occurrences must be exact links to '#$($Id.ToLowerInvariant())'."
    }
    $embeddedRecordDeclarations.Add([pscustomobject]@{
        Id = $Id
        Path = $Path
        Markdown = $Markdown
        DeclarationText = $DeclarationText
    })
    Add-DocumentRecordTarget -Id $Id `
        -Path "$Path#$($Id.ToLowerInvariant())"
}
foreach ($featureDirectory in $featureDirectories) {
    $featureId = $featureDirectory.Name.Substring(0, 9)
    $featureReadmePath = "docs/features/$($featureDirectory.Name)/README.md"
    Add-DocumentRecordTarget -Id $featureId -Path $featureReadmePath
    $featureReadme = Get-Content -LiteralPath (
        Join-Path $featureDirectory.FullName 'README.md'
    ) -Raw
    foreach ($match in [regex]::Matches(
        $featureReadme,
        $embeddedFeatureTableRecordDeclarationPattern
    )) {
        Add-EmbeddedDocumentRecordTarget `
            -Id $match.Groups['id'].Value -Path $featureReadmePath `
            -Markdown $featureReadme -DeclarationText $match.Value
    }
    foreach ($match in [regex]::Matches(
        $featureReadme,
        $embeddedFeatureChecklistDeclarationPattern
    )) {
        $embeddedId = if ($match.Groups['checklistId'].Success) {
            $match.Groups['checklistId'].Value
        }
        else {
            $match.Groups['reviewId'].Value
        }
        Add-EmbeddedDocumentRecordTarget -Id $embeddedId `
            -Path $featureReadmePath -Markdown $featureReadme `
            -DeclarationText $match.Value
    }
    foreach ($match in [regex]::Matches(
        $featureReadme,
        $embeddedHeadingRecordDeclarationPattern
    )) {
        Add-EmbeddedDocumentRecordTarget `
            -Id $match.Groups['id'].Value -Path $featureReadmePath `
            -Markdown $featureReadme -DeclarationText $match.Value
    }
    foreach ($match in [regex]::Matches(
        $featureReadme,
        '(?m)^##\s+(?<id>BUG-\d{4})\b'
    )) {
        Add-DocumentRecordTarget -Id $match.Groups['id'].Value `
            -Path $featureReadmePath
    }
    $testCasesPath = "docs/features/$($featureDirectory.Name)/test-cases.md"
    $testCases = Get-Content -LiteralPath (
        Join-Path $featureDirectory.FullName 'test-cases.md'
    ) -Raw
    foreach ($match in [regex]::Matches(
        $testCases,
        $embeddedTestTableRecordDeclarationPattern
    )) {
        Add-EmbeddedDocumentRecordTarget `
            -Id $match.Groups['id'].Value -Path $testCasesPath `
            -Markdown $testCases -DeclarationText $match.Value
    }
    foreach ($match in [regex]::Matches(
        $testCases,
        $embeddedHeadingRecordDeclarationPattern
    )) {
        Add-EmbeddedDocumentRecordTarget `
            -Id $match.Groups['id'].Value -Path $testCasesPath `
            -Markdown $testCases -DeclarationText $match.Value
    }
}
foreach ($decisionFile in $decisionFiles) {
    Add-DocumentRecordTarget -Id $decisionFile.BaseName.Substring(0, 8) `
        -Path "docs/decisions/$($decisionFile.Name)"
}
Get-ChildItem -LiteralPath (Join-Path $root 'docs/ideas') -File `
    -Filter 'IDEA-*.md' | ForEach-Object {
        Add-DocumentRecordTarget -Id $_.BaseName.Substring(0, 9) `
            -Path "docs/ideas/$($_.Name)"
    }
Get-ChildItem -LiteralPath (Join-Path $root 'migrations') -File `
    -Filter 'MIG-*.json' | ForEach-Object {
        Add-DocumentRecordTarget -Id $_.BaseName.Substring(0, 8) `
            -Path "migrations/$($_.Name)"
    }
$documentRecordTargets['FIND-0047'] = 'https://github.com/hasanmanzak/meAndAI/issues/9'
$documentRecordTargets['FIND-0049'] = 'https://github.com/hasanmanzak/meAndAI/issues/11'
$documentRecordTargets['FIND-0050'] = 'https://github.com/hasanmanzak/meAndAI/issues/13'
$documentRecordTargets['FIND-0120'] = 'https://github.com/hasanmanzak/meAndAI/issues/44'
$documentRecordTargets['TASK-0001'] = 'https://github.com/hasanmanzak/meAndAI/issues/95'
$documentRecordTargets['TASK-0002'] = 'https://github.com/hasanmanzak/meAndAI/issues/98'
foreach ($entry in @{
    'BUG-0001' = 24; 'BUG-0002' = 27; 'BUG-0003' = 32
    'BUG-0005' = 49; 'BUG-0006' = 53; 'BUG-0007' = 55
    'BUG-0008' = 57; 'BUG-0009' = 59; 'BUG-0010' = 61
    'BUG-0011' = 63; 'BUG-0012' = 69; 'BUG-0013' = 74
    'BUG-0014' = 83; 'BUG-0015' = 85; 'BUG-0016' = 85
    'BUG-0017' = 87; 'BUG-0018' = 89; 'BUG-0019' = 89
    'BUG-0020' = 89; 'BUG-0021' = 89; 'BUG-0022' = 96
    'BUG-0023' = 102; 'BUG-0024' = 104; 'BUG-0025' = 106
    'BUG-0026' = 108; 'BUG-0027' = 110; 'BUG-0028' = 112
    'BUG-0029' = 114; 'BUG-0030' = 116; 'BUG-0031' = 117
    'BUG-0032' = 119
}.GetEnumerator()) {
    $documentRecordTargets[$entry.Key] =
        "https://github.com/hasanmanzak/meAndAI/issues/$($entry.Value)"
}
$recordIdPattern = '(?<![A-Za-z0-9_-])(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}(?![A-Za-z0-9_-])'
$githubNumberPattern = '(?i)(?<![A-Za-z0-9_])(?<source>(?:(?<kind>issue|pull request|PR)\s+#?|#)(?<number>\d+))(?![A-Za-z0-9_-])'
$commentPermalinkPattern = '^https://github\.com/[^/]+/[^/]+/(?:(?<parentKind>issues|pull)/(?<parentNumber>\d+)#(?:(?:issuecomment|pullrequestreview)-(?<id>\d+)|discussion_r(?<id>\d+))|commit/[0-9a-f]{40}#commitcomment-(?<id>\d+)|discussions/\d+#discussioncomment-(?<id>\d+))$'
$commentNumberedLabelPattern = '(?i)\b(?:comment|review)\s+#?\d+\b'
$commentGenericLabelPattern = '(?i)\bcomment\b|\b(?:submitted|inline)\s+review\b'
$commentNodeLabelPattern = '(?i)\b(?:comment|review)\s+#?(?<id>\d+)\b'
$commentParentLabelPattern = '(?i)\b(?<kind>issue|PR|pull request)\s+#?(?<number>\d+)\s+(?:comment|(?:submitted|inline)\s+review)\b'
function Get-DocumentCommentLinkStatus {
    param(
        [AllowEmptyString()][string]$Label,
        [AllowEmptyString()][string]$Target
    )

    $targetMatch = [regex]::Match($Target, $commentPermalinkPattern)
    $isGitHubRecordTarget = [regex]::IsMatch(
        $Target,
        '^https://github\.com/[^/]+/[^/]+/(?:issues|pull|commit|discussions)/'
    )
    [pscustomobject]@{
        IsReference = $targetMatch.Success -or
            [regex]::IsMatch($Label, $commentNumberedLabelPattern) -or
            ($isGitHubRecordTarget -and
                [regex]::IsMatch($Label, $commentGenericLabelPattern))
        Target = $targetMatch
        LabelId = [regex]::Match($Label, $commentNodeLabelPattern)
        Parent = [regex]::Match($Label, $commentParentLabelPattern)
    }
}
function Get-DocumentMarkdownCodeSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    $lines = @([regex]::Matches(
        $text,
        '(?m)^(?<content>[^\r\n]*)(?<eol>\r?\n|$)'
    ) | Where-Object { $_.Length -gt 0 })
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $openingLine = [string]$lines[$lineIndex].Groups['content'].Value
        $opening = [regex]::Match(
            $openingLine,
            '^(?: {0,3}>[ \t]?)*(?:[ \t]*(?:[-+*]|\d+[.)])[ \t]+)?[ \t]*(?<marker>`{3,}|~{3,})(?<info>.*)$'
        )
        if (-not $opening.Success) { continue }
        $marker = [string]$opening.Groups['marker'].Value
        $markerCharacter = [string]$marker[0]
        if ($markerCharacter -ceq '`' -and
            $opening.Groups['info'].Value.Contains('`')) { continue }
        $closingPattern =
            '^(?: {0,3}>[ \t]?)*[ \t]*(?:' +
            [regex]::Escape($markerCharacter) + '){' +
            $marker.Length + ',}[ \t]*$'
        $closingLineIndex = -1
        for ($candidateIndex = $lineIndex + 1;
            $candidateIndex -lt $lines.Count;
            $candidateIndex++) {
            if ([regex]::IsMatch(
                [string]$lines[$candidateIndex].Groups['content'].Value,
                $closingPattern
            )) {
                $closingLineIndex = $candidateIndex
                break
            }
        }
        $spanEnd = if ($closingLineIndex -ge 0) {
            $lines[$closingLineIndex].Index +
                $lines[$closingLineIndex].Length
        }
        else { $text.Length }
        $contentStart = $lines[$lineIndex].Index +
            $lines[$lineIndex].Length
        $contentEnd = if ($closingLineIndex -ge 0) {
            $lines[$closingLineIndex].Index
        }
        else { $text.Length }
        $spans.Add([pscustomobject]@{
            Index = $lines[$lineIndex].Index
            Length = $spanEnd - $lines[$lineIndex].Index
            Value = $text.Substring(
                $lines[$lineIndex].Index,
                $spanEnd - $lines[$lineIndex].Index
            )
            Content = $text.Substring(
                $contentStart,
                [Math]::Max(0, $contentEnd - $contentStart)
            )
            Kind = 'Fenced'
        })
        if ($closingLineIndex -ge 0) {
            $lineIndex = $closingLineIndex
        }
        else { break }
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?m)(?:\A|\r?\n\r?\n)(?<code>(?:(?: {4}|\t)[^\r\n]+(?:\r?\n|$))+)'
    )) {
        $codeGroup = $match.Groups['code']
        if (Test-DocumentMarkdownSpanOverlap `
            -Index $codeGroup.Index -Length 1 -Spans @($spans)) { continue }
        $spans.Add([pscustomobject]@{
            Index = $codeGroup.Index
            Length = $codeGroup.Length
            Value = $codeGroup.Value
            Content = [regex]::Replace(
                $codeGroup.Value, '(?m)^(?: {4}|\t)', ''
            )
            Kind = 'Indented'
        })
    }
    foreach ($line in [regex]::Matches(
        $text,
        '(?m)^(?<content>[^\r\n]*)(?<eol>\r?\n|$)'
    ) | Where-Object { $_.Length -gt 0 }) {
        $rawLine = [string]$line.Groups['content'].Value
        $containerCode = [regex]::Match(
            $rawLine,
            '^(?:(?: {0,3}>[ \t]?)+)(?<indent> {4}|\t)(?<content>[^\r\n]+)$'
        )
        if (-not $containerCode.Success) {
            $containerCode = [regex]::Match(
                $rawLine,
                '^(?:(?: {0,3}>[ \t]?)* {0,3}(?:[-+*]|\d{1,9}[.)]))(?<indent> {5,}|\t+)(?<content>[^\r\n]+)$'
            )
        }
        if (-not $containerCode.Success -or
            (Test-DocumentMarkdownSpanOverlap -Index $line.Index `
                -Length 1 -Spans @($spans))) { continue }
        $spans.Add([pscustomobject]@{
            Index = $line.Index
            Length = $line.Length
            Value = $line.Value
            Content = $containerCode.Groups['content'].Value
            Kind = 'Indented'
        })
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?s)(?<!`)(?<ticks>`+)(?!`)(?<content>.*?)(?<!`)\k<ticks>(?!`)'
    )) {
        if (Test-DocumentMarkdownSpanOverlap `
            -Index $match.Index -Length 1 -Spans @($spans)) { continue }
        $spans.Add([pscustomobject]@{
            Index = $match.Index
            Length = $match.Length
            Value = $match.Value
            Content = $match.Groups['content'].Value
            Kind = 'Inline'
        })
    }
    return @($spans | Sort-Object Index)
}
function Get-DocumentMarkdownHtmlCommentSpans {
    param([AllowEmptyString()][string]$Markdown)

    return @([regex]::Matches(
        [string]$Markdown,
        '(?s)<!--.*?(?:-->|\z)'
    ))
}
function Remove-DocumentMarkdownBlockContainerPrefix {
    param([AllowEmptyString()][string]$Line)

    $remaining = [string]$Line
    do {
        $before = $remaining
        $remaining = [regex]::Replace(
            $remaining,
            '^(?: {0,3}>[ \t]?)+',
            ''
        )
        $remaining = [regex]::Replace(
            $remaining,
            '^ {0,3}(?:[-+*]|\d{1,9}[.)])[ \t]+',
            ''
        )
    } while ($remaining -cne $before)
    return $remaining
}
function Get-DocumentMarkdownNonRenderingHtmlSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches(
        $text,
        '(?is)<(?<tag>pre|script|style|textarea)(?:\s[^>]*)?>.*?(?:</\k<tag>\s*>|\z)'
    )) {
        $spans.Add([pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Value = $match.Value; Kind = 'HtmlType1'
        })
    }
    $lines = @([regex]::Matches(
        $text,
        '(?m)^(?<content>[^\r\n]*)(?<eol>\r?\n|$)'
    ) | Where-Object { $_.Length -gt 0 })
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $containerLine = Remove-DocumentMarkdownBlockContainerPrefix `
            -Line ([string]$lines[$lineIndex].Groups['content'].Value)
        $htmlType = $null
        if ($containerLine -cmatch '^ {0,3}<\?') {
            $htmlType = [pscustomobject]@{ Kind = 'HtmlType3'; End = '\?>' }
        }
        elseif ($containerLine -cmatch '^ {0,3}<![A-Z]') {
            $htmlType = [pscustomobject]@{ Kind = 'HtmlType4'; End = '>' }
        }
        elseif ($containerLine -cmatch '^ {0,3}<!\[CDATA\[') {
            $htmlType = [pscustomobject]@{ Kind = 'HtmlType5'; End = '\]\]>' }
        }
        if ($null -eq $htmlType -or
            (Test-DocumentMarkdownSpanOverlap `
                -Index $lines[$lineIndex].Index -Length 1 `
                -Spans @($spans))) { continue }
        $lastLineIndex = $lineIndex
        $normalizedBlock = $containerLine
        while (-not [regex]::IsMatch($normalizedBlock, $htmlType.End) -and
            $lastLineIndex + 1 -lt $lines.Count) {
            $lastLineIndex++
            $normalizedBlock += "`n" +
                (Remove-DocumentMarkdownBlockContainerPrefix -Line `
                    ([string]$lines[$lastLineIndex].Groups['content'].Value))
        }
        $spanEnd = $lines[$lastLineIndex].Index +
            $lines[$lastLineIndex].Length
        $spans.Add([pscustomobject]@{
            Index = $lines[$lineIndex].Index
            Length = $spanEnd - $lines[$lineIndex].Index
            Value = $text.Substring(
                $lines[$lineIndex].Index,
                $spanEnd - $lines[$lineIndex].Index
            )
            Kind = [string]$htmlType.Kind
        })
        $lineIndex = $lastLineIndex
    }
    $blockTags =
        'address|article|aside|base|basefont|blockquote|body|caption|center|' +
        'col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|' +
        'figure|footer|form|frame|frameset|h[1-6]|head|header|hr|html|' +
        'iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|' +
        'optgroup|option|p|param|search|section|summary|table|tbody|td|' +
        'tfoot|th|thead|title|tr|track|ul'
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $line = [string]$lines[$lineIndex].Groups['content'].Value
        $containerLine = Remove-DocumentMarkdownBlockContainerPrefix `
            -Line $line
        $isType6Block = [regex]::IsMatch(
            $containerLine,
            '(?i)^ {0,3}</?(?:' + $blockTags + ')(?:[ \t]+|/?>|$)'
        )
        $isType7Block = [regex]::IsMatch(
            $containerLine,
            '^ {0,3}</?[A-Za-z]'
        ) -and [string]::IsNullOrWhiteSpace(
            (Remove-DocumentMarkdownInlineHtmlTags -Text $containerLine)
        )
        if (-not $isType6Block -and -not $isType7Block) { continue }
        if (Test-DocumentMarkdownSpanOverlap `
            -Index $lines[$lineIndex].Index -Length 1 `
            -Spans @($spans)) { continue }
        $lastLineIndex = $lineIndex
        for ($candidateIndex = $lineIndex + 1;
            $candidateIndex -lt $lines.Count;
            $candidateIndex++) {
            $candidateLine = Remove-DocumentMarkdownBlockContainerPrefix `
                -Line ([string]$lines[$candidateIndex].Groups['content'].Value)
            if ($candidateLine -match '^[ \t]*$') { break }
            $lastLineIndex = $candidateIndex
        }
        $spanEnd = $lines[$lastLineIndex].Index +
            $lines[$lastLineIndex].Length
        $spans.Add([pscustomobject]@{
            Index = $lines[$lineIndex].Index
            Length = $spanEnd - $lines[$lineIndex].Index
            Value = $text.Substring(
                $lines[$lineIndex].Index,
                $spanEnd - $lines[$lineIndex].Index
            )
            Kind = if ($isType6Block) { 'HtmlType6' } else { 'HtmlType7' }
        })
        $lineIndex = $lastLineIndex
    }
    return @($spans | Sort-Object Index)
}
function Test-DocumentMarkdownCharacterEscaped {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][int]$Index
    )

    $backslashes = 0
    for ($position = $Index - 1;
        $position -ge 0 -and $Text[$position] -ceq '\';
        $position--) {
        $backslashes++
    }
    return ($backslashes % 2) -eq 1
}
function Get-DocumentMarkdownEscapedLinkSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($match in @(Get-DocumentMarkdownInlineLinkEvidence `
        -Markdown $text -EscapedOpeningOnly)) {
        $spans.Add([pscustomobject]@{
            Index = $match.Index
            Length = $match.Length
            Value = $text.Substring($match.Index, $match.Length)
        })
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?<!\!)\[[^\]]+\][ \t]*\[[^\]]*\]'
    )) {
        if ((Test-DocumentMarkdownCharacterEscaped `
                -Text $text -Index $match.Index) -and
            @($spans | Where-Object {
                $_.Index -eq $match.Index -and $_.Length -eq $match.Length
            }).Count -eq 0) {
            $spans.Add([pscustomobject]@{
                Index = $match.Index
                Length = $match.Length
                Value = $match.Value
            })
        }
    }
    return @($spans)
}
function Test-DocumentMarkdownSpanOverlap {
    param(
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][int]$Length,
        [object[]]$Spans = @()
    )

    foreach ($span in $Spans) {
        if ($Index -lt ([int]$span.Index + [int]$span.Length) -and
            ($Index + $Length) -gt [int]$span.Index) {
            return $true
        }
    }
    return $false
}
function Test-DocumentMarkdownAsciiPunctuationCharacter {
    param([Parameter(Mandatory)][char]$Character)

    $code = [int]$Character
    return ($code -ge 33 -and $code -le 47) -or
        ($code -ge 58 -and $code -le 64) -or
        ($code -ge 91 -and $code -le 96) -or
        ($code -ge 123 -and $code -le 126)
}
function ConvertFrom-DocumentMarkdownLinkDestination {
    param([AllowEmptyString()][string]$Destination)

    $decoded = [Net.WebUtility]::HtmlDecode([string]$Destination)
    $result = [Text.StringBuilder]::new($decoded.Length)
    for ($index = 0; $index -lt $decoded.Length; $index++) {
        if ($decoded[$index] -ceq '\' -and
            $index + 1 -lt $decoded.Length -and
            (Test-DocumentMarkdownAsciiPunctuationCharacter `
                -Character $decoded[$index + 1])) {
            [void]$result.Append($decoded[$index + 1])
            $index++
            continue
        }
        [void]$result.Append($decoded[$index])
    }
    return $result.ToString()
}
function Get-DocumentMarkdownInlineLinkEvidence {
    param(
        [AllowEmptyString()][string]$Markdown,
        [object[]]$ProtectedSpans = @(),
        [switch]$EscapedOpeningOnly
    )

    $text = [string]$Markdown
    $links = [System.Collections.Generic.List[object]]::new()
    for ($start = 0; $start -lt $text.Length; $start++) {
        if ($text[$start] -cne '[') { continue }
        $openingEscaped = Test-DocumentMarkdownCharacterEscaped `
            -Text $text -Index $start
        if (($EscapedOpeningOnly -and -not $openingEscaped) -or
            (-not $EscapedOpeningOnly -and $openingEscaped)) { continue }
        $isImage = $start -gt 0 -and $text[$start - 1] -ceq '!' -and
            -not (Test-DocumentMarkdownCharacterEscaped `
                -Text $text -Index ($start - 1))
        if ($isImage -or (Test-DocumentMarkdownSpanOverlap `
                -Index $start -Length 1 -Spans $ProtectedSpans)) { continue }

        $depth = 1
        $cursor = $start + 1
        $labelEnd = -1
        while ($cursor -lt $text.Length) {
            $protected = @($ProtectedSpans | Where-Object {
                $cursor -ge [int]$_.Index -and
                    $cursor -lt ([int]$_.Index + [int]$_.Length)
            } | Sort-Object Index | Select-Object -First 1)
            if ($protected.Count -eq 1) {
                $cursor = [int]$protected[0].Index +
                    [int]$protected[0].Length
                continue
            }
            if ($text[$cursor] -ceq '\' -and
                $cursor + 1 -lt $text.Length -and
                (Test-DocumentMarkdownAsciiPunctuationCharacter `
                    -Character $text[$cursor + 1])) {
                $cursor += 2
                continue
            }
            if ($text[$cursor] -ceq '[') { $depth++ }
            elseif ($text[$cursor] -ceq ']') {
                $depth--
                if ($depth -eq 0) {
                    $labelEnd = $cursor
                    break
                }
            }
            $cursor++
        }
        if ($labelEnd -lt 0 -or $labelEnd + 1 -ge $text.Length -or
            $text[$labelEnd + 1] -cne '(') { continue }

        $cursor = $labelEnd + 2
        while ($cursor -lt $text.Length -and
            [char]::IsWhiteSpace($text[$cursor])) { $cursor++ }
        $destinationStart = $cursor
        $destinationEnd = -1
        if ($cursor -lt $text.Length -and $text[$cursor] -ceq '<') {
            $destinationStart = ++$cursor
            while ($cursor -lt $text.Length) {
                if ($text[$cursor] -ceq "`r" -or
                    $text[$cursor] -ceq "`n" -or
                    $text[$cursor] -ceq '<') { break }
                if ($text[$cursor] -ceq '\' -and
                    $cursor + 1 -lt $text.Length -and
                    (Test-DocumentMarkdownAsciiPunctuationCharacter `
                        -Character $text[$cursor + 1])) {
                    $cursor += 2
                    continue
                }
                if ($text[$cursor] -ceq '>') {
                    $destinationEnd = $cursor
                    $cursor++
                    break
                }
                $cursor++
            }
            if ($destinationEnd -lt 0) { continue }
        }
        else {
            $parenthesisDepth = 0
            while ($cursor -lt $text.Length) {
                if ([char]::IsWhiteSpace($text[$cursor])) { break }
                if ($text[$cursor] -ceq '\' -and
                    $cursor + 1 -lt $text.Length -and
                    (Test-DocumentMarkdownAsciiPunctuationCharacter `
                        -Character $text[$cursor + 1])) {
                    $cursor += 2
                    continue
                }
                if ($text[$cursor] -ceq '(') {
                    $parenthesisDepth++
                }
                elseif ($text[$cursor] -ceq ')') {
                    if ($parenthesisDepth -eq 0) { break }
                    $parenthesisDepth--
                }
                $cursor++
            }
            if ($parenthesisDepth -ne 0) { continue }
            $destinationEnd = $cursor
        }

        $whitespaceStart = $cursor
        while ($cursor -lt $text.Length -and
            [char]::IsWhiteSpace($text[$cursor])) { $cursor++ }
        if ($cursor -ge $text.Length) { continue }
        if ($text[$cursor] -cne ')') {
            if ($cursor -eq $whitespaceStart -or
                $text[$cursor] -notin @('"', "'", '(')) { continue }
            $titleCloser = if ($text[$cursor] -ceq '(') { ')' } else {
                $text[$cursor]
            }
            $cursor++
            $titleClosed = $false
            while ($cursor -lt $text.Length) {
                if ($text[$cursor] -ceq '\' -and
                    $cursor + 1 -lt $text.Length -and
                    (Test-DocumentMarkdownAsciiPunctuationCharacter `
                        -Character $text[$cursor + 1])) {
                    $cursor += 2
                    continue
                }
                if ($text[$cursor] -ceq $titleCloser) {
                    $titleClosed = $true
                    $cursor++
                    break
                }
                $cursor++
            }
            if (-not $titleClosed) { continue }
            while ($cursor -lt $text.Length -and
                [char]::IsWhiteSpace($text[$cursor])) { $cursor++ }
            if ($cursor -ge $text.Length -or
                $text[$cursor] -cne ')') { continue }
        }

        $rawDestination = $text.Substring(
            $destinationStart,
            $destinationEnd - $destinationStart
        )
        $links.Add([pscustomobject]@{
            Index = $start
            Length = $cursor - $start + 1
            Label = $text.Substring($start + 1, $labelEnd - $start - 1)
            Target = ConvertFrom-DocumentMarkdownLinkDestination `
                -Destination $rawDestination
            Style = 'Inline'
            ReferenceKey = ''
        })
        $start = $cursor
    }
    return @($links)
}
function Get-DocumentMarkdownHttpAutolinkSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($angle in [regex]::Matches(
        $text,
        '(?i)<(?<url>https?://[^\s<>]+)>'
    )) {
        $spans.Add([pscustomobject]@{
            Index = $angle.Index
            Length = $angle.Length
            Value = $angle.Groups['url'].Value
            RawValue = $angle.Groups['url'].Value
            IsAngle = $true
            HasMarkupContinuation = $false
        })
    }
    foreach ($scheme in [regex]::Matches($text, '(?i)https?://')) {
        $start = $scheme.Index
        if (@($spans | Where-Object {
            -not $_.IsAngle -and $start -ge [int]$_.Index -and
                $start -lt ([int]$_.Index + [int]$_.Length)
        }).Count -gt 0) { continue }
        if ($start -gt 0) {
            $previous = $text[$start - 1]
            if (-not [char]::IsWhiteSpace($previous) -and
                $previous -notin @('*', '_', '~', '(')) { continue }
        }
        $domainStart = $start + $scheme.Length
        $domainMatch = [regex]::Match(
            $text.Substring($domainStart),
            '^(?<domain>[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+)'
        )
        if (-not $domainMatch.Success) { continue }
        $segments = @($domainMatch.Groups['domain'].Value.Split('.'))
        if ($segments[-1].Contains('_') -or
            $segments[-2].Contains('_')) { continue }

        $domainEnd = $domainStart + $domainMatch.Length
        $maximumEnd = $domainEnd
        while ($maximumEnd -lt $text.Length -and
            -not [char]::IsWhiteSpace($text[$maximumEnd]) -and
            $text[$maximumEnd] -cne '<' -and
            $text[$maximumEnd] -cne '`') { $maximumEnd++ }
        $rawCandidate = $text.Substring($start, $maximumEnd - $start)
        $end = $maximumEnd
        while ($end -gt $domainEnd -and
            '?!. ,:*_~'.Replace(' ', '').Contains(
                [string]$text[$end - 1]
            )) { $end-- }
        while ($end -gt $domainEnd -and $text[$end - 1] -ceq ')') {
            $candidate = $text.Substring($start, $end - $start)
            $openCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq '('
            }).Count
            $closeCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq ')'
            }).Count
            if ($closeCount -le $openCount) { break }
            $end--
        }
        $candidate = $text.Substring($start, $end - $start)
        $entitySuffix = [regex]::Match($candidate, '&[A-Za-z0-9]+;$')
        if ($entitySuffix.Success) {
            $end = $start + $entitySuffix.Index
            $candidate = $text.Substring($start, $end - $start)
        }
        if ($end -lt $domainEnd) { continue }
        $continuation = if ($maximumEnd -lt $text.Length) {
            $text.Substring($maximumEnd)
        } else { '' }
        $spans.Add([pscustomobject]@{
            Index = $start
            Length = $end - $start
            Value = $candidate
            RawValue = $rawCandidate
            IsAngle = $false
            HasMarkupContinuation = $continuation -match
                '^(?:<!--|</?[A-Za-z]|`)'
        })
    }
    return @($spans | Sort-Object Index, Length -Unique)
}
function Get-DocumentRendererActiveHttpAutolinkSpans {
    param(
        [AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory)]$LinkEvidence
    )

    $ignoredSpans = @($LinkEvidence.Links) +
        @($LinkEvidence.Definitions) + @($LinkEvidence.CodeSpans) +
        @($LinkEvidence.HtmlComments) + @($LinkEvidence.NonRenderingHtml)
    $activeSpans = [System.Collections.Generic.List[object]]::new()
    foreach ($autolink in @(Get-DocumentMarkdownHttpAutolinkSpans `
        -Markdown ([string]$Markdown))) {
        if (Test-DocumentMarkdownSpanOverlap -Index $autolink.Index `
            -Length $autolink.Length -Spans $ignoredSpans) { continue }
        $hasDecoratedNumericSegment = -not $autolink.IsAngle -and
            [regex]::IsMatch(
                [string]$autolink.RawValue,
                '(?:\*{1,3}[0-9]+\*{1,3}|~~[0-9]+~~|_{1,2}[0-9]+_{1,2})(?=$|[(/?#&.,;:!])'
            )
        if ($autolink.HasMarkupContinuation -or
            $hasDecoratedNumericSegment) { continue }
        $activeSpans.Add($autolink)
    }
    return @($activeSpans)
}
function Get-DocumentMarkdownVisibleHttpUrlSpans {
    param([AllowEmptyString()][string]$Text)

    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($scheme in [regex]::Matches([string]$Text, '(?i)https?://')) {
        $start = $scheme.Index
        if (@($spans | Where-Object {
            $start -ge [int]$_.Index -and
                $start -lt ([int]$_.Index + [int]$_.Length)
        }).Count -gt 0) { continue }
        $end = $start + $scheme.Length
        while ($end -lt $Text.Length -and
            -not [char]::IsWhiteSpace($Text[$end]) -and
            $Text[$end] -notin @('<', '>', '[', ']', '{', '}', '"', "'", '`')) {
            $end++
        }
        while ($end -gt ($start + $scheme.Length) -and
            '.,;:!?'.Contains([string]$Text[$end - 1])) { $end-- }
        while ($end -gt ($start + $scheme.Length) -and
            $Text[$end - 1] -ceq ')') {
            $candidate = $Text.Substring($start, $end - $start)
            $openCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq '('
            }).Count
            $closeCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq ')'
            }).Count
            if ($closeCount -le $openCount) { break }
            $end--
        }
        $spans.Add([pscustomobject]@{
            Index = $start
            Length = $end - $start
            Value = $Text.Substring($start, $end - $start)
        })
    }
    return @($spans)
}
function Remove-DocumentMarkdownInlineHtmlTags {
    param([AllowEmptyString()][string]$Text)

    $result = [Text.StringBuilder]::new($Text.Length)
    for ($index = 0; $index -lt $Text.Length;) {
        if ($Text[$index] -cne '<') {
            [void]$result.Append($Text[$index])
            $index++
            continue
        }
        $cursor = $index + 1
        if ($cursor -lt $Text.Length -and $Text[$cursor] -ceq '/') {
            $cursor++
        }
        if ($cursor -ge $Text.Length -or
            -not [char]::IsLetter($Text[$cursor])) {
            [void]$result.Append('<')
            $index++
            continue
        }
        $cursor++
        while ($cursor -lt $Text.Length -and
            ([char]::IsLetterOrDigit($Text[$cursor]) -or
                $Text[$cursor] -ceq '-')) { $cursor++ }
        if ($cursor -ge $Text.Length -or
            (-not [char]::IsWhiteSpace($Text[$cursor]) -and
                $Text[$cursor] -cne '/' -and $Text[$cursor] -cne '>')) {
            [void]$result.Append('<')
            $index++
            continue
        }
        $quote = [char]0
        $tagEnd = -1
        for (; $cursor -lt $Text.Length; $cursor++) {
            $character = $Text[$cursor]
            if ($quote -ne [char]0) {
                if ($character -ceq $quote) { $quote = [char]0 }
                continue
            }
            if ($character -ceq '"' -or $character -ceq "'") {
                $quote = $character
                continue
            }
            if ($character -ceq '>') {
                $tagEnd = $cursor
                break
            }
        }
        if ($tagEnd -lt 0) {
            [void]$result.Append('<')
            $index++
            continue
        }
        $index = $tagEnd + 1
    }
    return $result.ToString()
}

function ConvertTo-DocumentMarkdownRenderedText {
    param([AllowEmptyString()][string]$Text)

    $decoded = [Net.WebUtility]::HtmlDecode([string]$Text)
    $decoded = [regex]::Replace($decoded, '(?s)<!--.*?(?:-->|\z)', '')
    $decoded = Remove-DocumentMarkdownInlineHtmlTags -Text $decoded
    $decoded = $decoded -replace '[*~`]', ''
    $decoded = [regex]::Replace(
        $decoded,
        '(?<![A-Za-z0-9])_+|_+(?![A-Za-z0-9])',
        ''
    )
    $rendered = [Text.StringBuilder]::new($decoded.Length)
    for ($index = 0; $index -lt $decoded.Length;) {
        if ($decoded[$index] -cne '\') {
            [void]$rendered.Append($decoded[$index])
            $index++
            continue
        }
        $runStart = $index
        while ($index -lt $decoded.Length -and $decoded[$index] -ceq '\') {
            $index++
        }
        $runLength = $index - $runStart
        for ($pair = 0; $pair -lt [Math]::Floor($runLength / 2); $pair++) {
            [void]$rendered.Append('\')
        }
        $hasOddEscape = ($runLength % 2) -eq 1
        $nextIsAsciiPunctuation = $false
        if ($index -lt $decoded.Length) {
            $characterCode = [int][char]$decoded[$index]
            $nextIsAsciiPunctuation =
                ($characterCode -ge 33 -and $characterCode -le 47) -or
                ($characterCode -ge 58 -and $characterCode -le 64) -or
                ($characterCode -ge 91 -and $characterCode -le 96) -or
                ($characterCode -ge 123 -and $characterCode -le 126)
        }
        if ($hasOddEscape -and $nextIsAsciiPunctuation) {
            [void]$rendered.Append($decoded[$index])
            $index++
        }
        elseif ($hasOddEscape) {
            [void]$rendered.Append('\')
        }
    }
    return $rendered.ToString()
}
function Get-DocumentGitHubShorthandReferences {
    param([AllowEmptyString()][string]$Text)

    $references = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches(
        [string]$Text,
        '(?i)(?<![A-Za-z0-9_])(?<kind>GH|PR|issue|comment|review)-(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
    )) {
        $references.Add([pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Value = $match.Value
            Kind = $match.Groups['kind'].Value.ToLowerInvariant()
            Number = [long]$match.Groups['number'].Value
            Owner = ''; RepositoryName = ''
        })
    }
    foreach ($match in [regex]::Matches(
        [string]$Text,
        '(?i)(?<![A-Za-z0-9_./-])(?:(?<owner>[A-Za-z0-9_.-]+)/)?(?<repository>[A-Za-z0-9_.-]{2,})#(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
    )) {
        if (Test-DocumentMarkdownSpanOverlap -Index $match.Index `
            -Length $match.Length -Spans @($references)) { continue }
        $references.Add([pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Value = $match.Value; Kind = 'repository'
            Number = [long]$match.Groups['number'].Value
            Owner = $match.Groups['owner'].Value
            RepositoryName = $match.Groups['repository'].Value
        })
    }
    return @($references | Sort-Object Index)
}
function Test-DocumentExactGitHubShorthandTarget {
    param(
        [Parameter(Mandatory)]$Reference,
        [Parameter(Mandatory)][string]$Target
    )

    $currentOwner = 'hasanmanzak'
    $currentRepositoryName = 'meAndAI'
    $cleanTarget = $Target.Trim().Trim('<', '>')
    if ([string]$Reference.Kind -in @('comment', 'review')) {
        $commentTarget = [regex]::Match(
            $cleanTarget,
            '^https://github\.com/(?<owner>[^/]+)/(?<repository>[^/]+)/(?:(?:issues|pull)/\d+#(?:(?:issuecomment|pullrequestreview)-(?<id>\d+)|discussion_r(?<id>\d+))|commit/[0-9a-f]{40}#commitcomment-(?<id>\d+)|discussions/\d+#discussioncomment-(?<id>\d+))$'
        )
        return $commentTarget.Success -and
            [long]$commentTarget.Groups['id'].Value -eq
                [long]$Reference.Number -and
            $commentTarget.Groups['owner'].Value -ieq $currentOwner -and
            $commentTarget.Groups['repository'].Value -ieq
                $currentRepositoryName
    }
    $artifactTarget = [regex]::Match(
        $cleanTarget,
        '^https://github\.com/(?<owner>[^/]+)/(?<repository>[^/]+)/(?<kind>issues|pull)/(?<number>[1-9][0-9]*)$'
    )
    if (-not $artifactTarget.Success -or
        [long]$artifactTarget.Groups['number'].Value -ne
            [long]$Reference.Number) { return $false }
    switch ([string]$Reference.Kind) {
        'pr' {
            return $artifactTarget.Groups['kind'].Value -ceq 'pull' -and
                $artifactTarget.Groups['owner'].Value -ieq $currentOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    $currentRepositoryName
        }
        'issue' {
            return $artifactTarget.Groups['kind'].Value -ceq 'issues' -and
                $artifactTarget.Groups['owner'].Value -ieq $currentOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    $currentRepositoryName
        }
        'repository' {
            $expectedOwner = if ([string]::IsNullOrEmpty(
                [string]$Reference.Owner
            )) { $currentOwner } else { [string]$Reference.Owner }
            return $artifactTarget.Groups['owner'].Value -ieq $expectedOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    [string]$Reference.RepositoryName
        }
        default {
            return $artifactTarget.Groups['owner'].Value -ieq $currentOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    $currentRepositoryName
        }
    }
}
function Get-DocumentMarkdownLinkEvidence {
    param(
        [AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory)][string]$Path
    )

    $codeSpans = @(Get-DocumentMarkdownCodeSpans -Markdown $Markdown)
    $htmlCommentSpans = @(
        Get-DocumentMarkdownHtmlCommentSpans -Markdown $Markdown
    )
    $nonRenderingHtmlSpans = @(
        Get-DocumentMarkdownNonRenderingHtmlSpans `
            -Markdown $Markdown | Where-Object {
                -not (Test-DocumentMarkdownSpanOverlap `
                    -Index $_.Index -Length $_.Length `
                    -Spans (@($codeSpans) + @($htmlCommentSpans)))
            }
    )
    $escapedLinkSpans = @(
        Get-DocumentMarkdownEscapedLinkSpans -Markdown $Markdown
    )
    $ignoredSpans = @($codeSpans) + @($htmlCommentSpans) +
        @($nonRenderingHtmlSpans)
    $ignoredSpans += @($escapedLinkSpans)
    $definitions = [Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $definitionMatches = @([regex]::Matches(
        [string]$Markdown,
        '(?m)^[ \t]{0,3}\[(?<key>(?!\^)[^\]]+)\]:[ \t]*(?:<(?<angle>[^>]+)>|(?<plain>\S+))(?:[ \t]+(?:"[^"]*"|''[^'']*''|\([^)]*\)))?[ \t]*$'
    ) | Where-Object {
        -not (Test-DocumentMarkdownCharacterEscaped `
            -Text ([string]$Markdown) `
            -Index ($_.Groups['key'].Index - 1)) -and
        -not (Test-DocumentMarkdownSpanOverlap `
            -Index $_.Index -Length 1 -Spans $ignoredSpans)
    })
    foreach ($definition in $definitionMatches) {
        $key = $definition.Groups['key'].Value.Trim()
        $target = if ($definition.Groups['angle'].Success) {
            $definition.Groups['angle'].Value
        } else { $definition.Groups['plain'].Value }
        $target = ConvertFrom-DocumentMarkdownLinkDestination `
            -Destination $target
        if ([string]::IsNullOrWhiteSpace($key) -or
            [string]::IsNullOrWhiteSpace($target) -or
            $definitions.ContainsKey($key)) {
            Add-Failure "TEST-0175 $Path has an empty or duplicate reference-link definition."
            continue
        }
        $definitions.Add($key, [pscustomobject]@{ Target = $target })
    }
    $links = [System.Collections.Generic.List[object]]::new()
    $unresolvedReferences = [System.Collections.Generic.List[object]]::new()
    $occupied = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in $definitionMatches) {
        $occupied.Add([pscustomobject]@{
            Index = $definition.Index; Length = $definition.Length
        })
    }
    foreach ($link in @(Get-DocumentMarkdownInlineLinkEvidence `
        -Markdown ([string]$Markdown) -ProtectedSpans $ignoredSpans)) {
        if (Test-DocumentMarkdownSpanOverlap -Index $link.Index `
            -Length $link.Length -Spans @($occupied)) { continue }
        $links.Add($link); $occupied.Add($link)
    }
    foreach ($match in [regex]::Matches(
        [string]$Markdown,
        '(?<!\!)\[(?<label>[^\]]+)\][ \t]*\[(?<key>[^\]]*)\]'
    )) {
        if (Test-DocumentMarkdownCharacterEscaped `
            -Text ([string]$Markdown) -Index $match.Index) { continue }
        if (Test-DocumentMarkdownSpanOverlap `
            -Index $match.Index -Length 1 -Spans $ignoredSpans) {
            continue
        }
        if (@($occupied | Where-Object {
            $match.Index -lt ($_.Index + $_.Length) -and
                ($match.Index + $match.Length) -gt $_.Index
        }).Count -ne 0) { continue }
        $key = $match.Groups['key'].Value.Trim()
        if ([string]::IsNullOrEmpty($key)) { $key = $match.Groups['label'].Value.Trim() }
        if (-not $definitions.ContainsKey($key)) {
            $unresolvedReferences.Add([pscustomobject]@{
                Label = $match.Groups['label'].Value
                Key = $key
            })
            $occupied.Add([pscustomobject]@{
                Index = $match.Index; Length = $match.Length
            })
            continue
        }
        $link = [pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Label = $match.Groups['label'].Value
            Target = [string]$definitions[$key].Target
            Style = 'Reference'; ReferenceKey = $key
        }
        $links.Add($link); $occupied.Add($link)
    }
    foreach ($match in [regex]::Matches(
        [string]$Markdown, '(?<![!\]])\[(?<label>[^\]]+)\]'
    )) {
        if (Test-DocumentMarkdownCharacterEscaped `
            -Text ([string]$Markdown) -Index $match.Index) { continue }
        if (Test-DocumentMarkdownSpanOverlap `
            -Index $match.Index -Length 1 -Spans $ignoredSpans) {
            continue
        }
        if (@($occupied | Where-Object {
            $match.Index -lt ($_.Index + $_.Length) -and
                ($match.Index + $match.Length) -gt $_.Index
        }).Count -ne 0) { continue }
        $key = $match.Groups['label'].Value.Trim()
        if (-not $definitions.ContainsKey($key)) { continue }
        $link = [pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Label = $match.Groups['label'].Value
            Target = [string]$definitions[$key].Target
            Style = 'Reference'; ReferenceKey = $key
        }
        $links.Add($link); $occupied.Add($link)
    }
    [pscustomobject]@{
        Links = @($links)
        Definitions = @($definitionMatches)
        Unresolved = @($unresolvedReferences)
        CodeSpans = @($codeSpans)
        HtmlComments = @($htmlCommentSpans)
        NonRenderingHtml = @($nonRenderingHtmlSpans)
        EscapedLinks = @($escapedLinkSpans)
    }
}
function Get-RendererActiveMarkdownAnchorEvidence {
    param([AllowEmptyString()][string]$Markdown)

    $ignoredSpans = @(Get-DocumentMarkdownCodeSpans -Markdown $Markdown) +
        @(Get-DocumentMarkdownHtmlCommentSpans -Markdown $Markdown) +
        @(Get-DocumentMarkdownNonRenderingHtmlSpans -Markdown $Markdown)
    return @(Get-MarkdownAnchorEvidence -Markdown $Markdown | Where-Object {
        -not (Test-DocumentMarkdownSpanOverlap `
            -Index ([int]$_.Index) -Length ([int]$_.Length) `
            -Spans $ignoredSpans)
    })
}
$activeEmbeddedAnchorsByPath = @{}
$validatedEmbeddedRecordAnchors = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($declaration in $embeddedRecordDeclarations) {
    if (-not $validatedEmbeddedRecordAnchors.Add(
            [string]$declaration.Id
        )) { continue }
    $declarationPath = [string]$declaration.Path
    if (-not $activeEmbeddedAnchorsByPath.ContainsKey($declarationPath)) {
        $activeEmbeddedAnchorsByPath[$declarationPath] = @(
            Get-RendererActiveMarkdownAnchorEvidence `
                -Markdown ([string]$declaration.Markdown)
        )
    }
    $anchorProblems = @(Get-EmbeddedRecordAnchorProblems `
        -Id ([string]$declaration.Id) `
        -Markdown ([string]$declaration.Markdown) `
        -DeclarationText ([string]$declaration.DeclarationText) `
        -DocumentAnchors @($activeEmbeddedAnchorsByPath[$declarationPath]))
    foreach ($problem in $anchorProblems) {
        $id = [string]$declaration.Id
        switch ($problem) {
            'Missing' {
                Add-Failure "TEST-0177 $declarationPath is missing canonical anchor '<a name=`"$($id.ToLowerInvariant())`"></a>' for $id."
            }
            'Wrong' {
                Add-Failure "TEST-0177 $declarationPath does not place the exact canonical anchor for $id in its declaration."
            }
            'WrongCase' {
                Add-Failure "TEST-0177 $declarationPath uses a non-lowercase anchor for $id."
            }
            'Duplicate' {
                Add-Failure "TEST-0177 $declarationPath defines duplicate '$($id.ToLowerInvariant())' anchors for $id."
            }
            'CaseCollision' {
                Add-Failure "TEST-0177 $declarationPath defines case-colliding anchors for $id."
            }
        }
    }
}
function Test-DocumentRecordOwnIdentity {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$SourcePath
    )

    if (-not $documentRecordTargets.ContainsKey($Id)) { return $false }
    $target = [string]$documentRecordTargets[$Id]
    return (Get-DocumentRecordTargetPath -Target $target) -ceq $SourcePath
}
function Get-DocumentUnlinkedMarkdown {
    param(
        [AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory)]$LinkEvidence
    )

    $remaining = [string]$Markdown
    $spans = @($LinkEvidence.Links) + @($LinkEvidence.Definitions | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    }) + @($LinkEvidence.CodeSpans | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    }) + @($LinkEvidence.HtmlComments | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    }) + @($LinkEvidence.NonRenderingHtml | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    })
    foreach ($span in @($spans | Sort-Object Index -Descending)) {
        $remaining = $remaining.Remove([int]$span.Index, [int]$span.Length).Insert(
            [int]$span.Index, (' ' * [int]$span.Length)
        )
    }
    $withoutUris = [regex]::Replace($remaining, 'https?://[^\s)>]+', '')
    ConvertTo-DocumentMarkdownRenderedText -Text $withoutUris
}
$rawDocumentPathPattern = '(?i)(?<![A-Za-z0-9_./-])(?:\.{0,2}/)?(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.md(?:#[A-Za-z0-9_.:-]+)?(?![A-Za-z0-9_.-])'
$hiddenCrossRecordReferencePattern = $recordIdPattern + '|' +
    $rawDocumentPathPattern +
    '|(?i:https?://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/[1-9][0-9]*|blob/[^<>\s]+))' +
    '|(?i:(?<![A-Za-z0-9_])(?:issue|PR|pull request|comment|review)\s+#?[1-9][0-9]*)' +
    '|(?i:(?<![A-Za-z0-9_])(?:GH|issue|pr|comment|review)-[1-9][0-9]*(?![A-Za-z0-9_-]))'
function Test-CodeFormattedDocumentReference {
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [Parameter(Mandatory)]$CodeSpan
    )

    if (-not [regex]::IsMatch([string]$CodeSpan.Value, $rawDocumentPathPattern)) {
        return $false
    }
    $beforeStart = [Math]::Max(0, [int]$CodeSpan.Index - 80)
    $before = $Markdown.Substring(
        $beforeStart,
        [int]$CodeSpan.Index - $beforeStart
    )
    $afterStart = [int]$CodeSpan.Index + [int]$CodeSpan.Length
    $after = $Markdown.Substring(
        $afterStart,
        [Math]::Min(80, $Markdown.Length - $afterStart)
    )
    return [regex]::IsMatch(
        $before,
        '(?i)\b(?:see|read|open|consult|reference(?:d)?(?:\s+to)?|recorded\s+in|documented\s+in|defined\s+in|described\s+in|according\s+to|details\s+in)\s*$'
    ) -or [regex]::IsMatch(
        $after,
        '(?i)^\s+for\s+(?:details|context|more\s+information)\b'
    )
}

function Get-RenderedDocumentReferenceText {
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [Parameter(Mandatory)]$LinkEvidence
    )

    $rendered = $Markdown
    $spans = @($LinkEvidence.Links | ForEach-Object {
        [pscustomobject]@{
            Index = $_.Index
            Length = $_.Length
            Replacement = [string]$_.Label
        }
    }) + @($LinkEvidence.Definitions | ForEach-Object {
        [pscustomobject]@{
            Index = $_.Index
            Length = $_.Length
            Replacement = ''
        }
    }) + @($LinkEvidence.CodeSpans | Where-Object {
        $codeSpan = $_
        @($LinkEvidence.Links | Where-Object {
            $codeSpan.Index -ge $_.Index -and
                ($codeSpan.Index + $codeSpan.Length) -le
                    ($_.Index + $_.Length)
        }).Count -eq 0
    } | ForEach-Object {
        [pscustomobject]@{
            Index = $_.Index
            Length = $_.Length
            Replacement = ''
        }
    }) + @($LinkEvidence.HtmlComments | ForEach-Object {
        [pscustomobject]@{
            Index = $_.Index
            Length = $_.Length
            Replacement = ''
        }
    }) + @($LinkEvidence.NonRenderingHtml | ForEach-Object {
        [pscustomobject]@{
            Index = $_.Index
            Length = $_.Length
            Replacement = ''
        }
    })
    foreach ($span in @($spans | Sort-Object Index -Descending)) {
        $rendered = $rendered.Remove([int]$span.Index, [int]$span.Length).Insert(
            [int]$span.Index, [string]$span.Replacement
        )
    }
    return ConvertTo-DocumentMarkdownRenderedText `
        -Text $rendered.Replace('`', '')
}

function Get-DocumentRenderedReferenceEvidence {
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [Parameter(Mandatory)]$LinkEvidence
    )

    $rendered = $Markdown
    $replacementSpans = [System.Collections.Generic.List[object]]::new()
    for ($linkIndex = 0; $linkIndex -lt @($LinkEvidence.Links).Count;
        $linkIndex++) {
        $link = @($LinkEvidence.Links)[$linkIndex]
        $replacementSpans.Add([pscustomobject]@{
            Index = [int]$link.Index
            Length = [int]$link.Length
            Replacement = ([string][char]0xE000) + $linkIndex +
                ([string][char]0xE001) + [string]$link.Label +
                ([string][char]0xE002)
        })
    }
    foreach ($span in @($LinkEvidence.Definitions) +
        @($LinkEvidence.CodeSpans) + @($LinkEvidence.HtmlComments) +
        @($LinkEvidence.NonRenderingHtml)) {
        if (Test-DocumentMarkdownSpanOverlap `
            -Index ([int]$span.Index) -Length ([int]$span.Length) `
            -Spans @($LinkEvidence.Links)) { continue }
        $replacementSpans.Add([pscustomobject]@{
            Index = [int]$span.Index
            Length = [int]$span.Length
            Replacement = ''
        })
    }
    foreach ($bareUrl in @(Get-DocumentRendererActiveHttpAutolinkSpans `
        -Markdown ([string]$Markdown) -LinkEvidence $LinkEvidence)) {
        $replacementSpans.Add([pscustomobject]@{
            Index = $bareUrl.Index
            Length = $bareUrl.Length
            Replacement = ''
        })
    }
    foreach ($span in @($replacementSpans | Sort-Object Index -Descending)) {
        $rendered = $rendered.Remove($span.Index, $span.Length).Insert(
            $span.Index,
            [string]$span.Replacement
        )
    }
    $rendered = ConvertTo-DocumentMarkdownRenderedText `
        -Text $rendered.Replace('`', '')

    $visible = [Text.StringBuilder]::new($rendered.Length)
    $linkSpans = [System.Collections.Generic.List[object]]::new()
    $activeLinkIndex = -1
    $activeStart = -1
    for ($index = 0; $index -lt $rendered.Length;) {
        if ([int][char]$rendered[$index] -eq 0xE000) {
            $markerEnd = $rendered.IndexOf([char]0xE001, $index + 1)
            if ($markerEnd -lt 0) {
                Add-Failure 'TEST-0175 rendered Markdown link marker is malformed.'
                break
            }
            $activeLinkIndex = [int]$rendered.Substring(
                $index + 1,
                $markerEnd - $index - 1
            )
            $activeStart = $visible.Length
            $index = $markerEnd + 1
            continue
        }
        if ([int][char]$rendered[$index] -eq 0xE002) {
            if ($activeLinkIndex -lt 0) {
                Add-Failure 'TEST-0175 rendered Markdown link marker is unbalanced.'
                $index++
                continue
            }
            $linkSpans.Add([pscustomobject]@{
                Index = $activeStart
                Length = $visible.Length - $activeStart
                Link = @($LinkEvidence.Links)[$activeLinkIndex]
            })
            $activeLinkIndex = -1
            $activeStart = -1
            $index++
            continue
        }
        [void]$visible.Append($rendered[$index])
        $index++
    }
    if ($activeLinkIndex -ge 0) {
        Add-Failure 'TEST-0175 rendered Markdown link marker is unclosed.'
    }
    return [pscustomobject]@{
        Text = $visible.ToString()
        Links = @($linkSpans)
    }
}

function Test-DocumentRenderedReferenceCoveredByLink {
    param(
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][int]$Length,
        [Parameter(Mandatory)]$RenderedEvidence
    )

    return @($RenderedEvidence.Links | Where-Object {
        $Index -ge [int]$_.Index -and
            ($Index + $Length) -le ([int]$_.Index + [int]$_.Length)
    }).Count -eq 1
}

function Test-ContainsExactDocumentTitle {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Title
    )

    return [regex]::IsMatch(
        $Text,
        '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($Title) +
            '(?![A-Za-z0-9])'
    )
}

function Test-DocumentHeadingOwnsTitle {
    param(
        [AllowEmptyString()][string]$Heading,
        [Parameter(Mandatory)][string]$Title
    )

    $escapedTitle = [regex]::Escape($Title)
    return [regex]::IsMatch(
        $Heading.Trim(),
        '(?i)^(?:\d{4}-\d{2}-\d{2}\s+-\s+)?' +
            '(?:(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}\s+-\s+|v(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\s+(?:-\s+)?)?' +
            $escapedTitle + '$'
    )
}

function Resolve-DocumentLinkTarget {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Target
    )

    $cleanTarget = $Target.Trim()
    if ($cleanTarget.StartsWith('<') -and $cleanTarget.EndsWith('>')) {
        $cleanTarget = $cleanTarget.Substring(1, $cleanTarget.Length - 2)
    }
    if ($cleanTarget -match '^https://github\.com/hasanmanzak/meAndAI/(?:blob|tree)/[^/]+/(?<path>[^#?]+)(?<fragment>#[^?]*)?$') {
        return [pscustomobject]@{
            Kind = 'Repository'
            Value = [uri]::UnescapeDataString($Matches['path']).Replace('\', '/')
            Fragment = [string]$Matches['fragment']
        }
    }
    if ($cleanTarget -match '^https?://') {
        return [pscustomobject]@{
            Kind = 'External'
            Value = $cleanTarget.TrimEnd('/')
            Fragment = ''
        }
    }
    $fragment = ''
    $pathPart = $cleanTarget
    $fragmentIndex = $pathPart.IndexOf('#')
    if ($fragmentIndex -ge 0) {
        $fragment = $pathPart.Substring($fragmentIndex)
        $pathPart = $pathPart.Substring(0, $fragmentIndex)
    }
    $queryIndex = $pathPart.IndexOf('?')
    if ($queryIndex -ge 0) {
        $pathPart = $pathPart.Substring(0, $queryIndex)
    }
    $sourceFullPath = Join-Path $root $SourcePath
    $targetFullPath = if ([string]::IsNullOrWhiteSpace($pathPart)) {
        [IO.Path]::GetFullPath($sourceFullPath)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path (
            Split-Path -Parent $sourceFullPath
        ) ([uri]::UnescapeDataString($pathPart))))
    }
    $rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) +
        [IO.Path]::DirectorySeparatorChar
    if ($targetFullPath -cne $root -and
        -not $targetFullPath.StartsWith(
            $rootPrefix,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        return [pscustomobject]@{
            Kind = 'Invalid'; Value = ''; Fragment = $fragment
        }
    }
    return [pscustomobject]@{
        Kind = 'Repository'
        Value = $targetFullPath.Substring($root.Length + 1).Replace('\', '/')
        Fragment = $fragment
    }
}
function Test-DocumentRecordLinkTarget {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$ExpectedTarget
    )

    $actual = Resolve-DocumentLinkTarget -SourcePath $SourcePath -Target $Target
    if (-not $ExpectedTarget.StartsWith('https://') -and
        $Target.Trim().Trim('<', '>') -match
            '^https://github\.com/hasanmanzak/meAndAI/(?:blob|tree)/') {
        return $false
    }
    if ($ExpectedTarget.StartsWith('https://')) {
        return $actual.Kind -ceq 'External' -and
            $actual.Value -ceq $ExpectedTarget.TrimEnd('/')
    }
    $expectedPath = $ExpectedTarget
    $expectedFragment = ''
    $fragmentIndex = $expectedPath.IndexOf('#')
    if ($fragmentIndex -ge 0) {
        $expectedFragment = $expectedPath.Substring($fragmentIndex)
        $expectedPath = $expectedPath.Substring(0, $fragmentIndex)
    }
    return $actual.Kind -ceq 'Repository' -and
        $actual.Value -ceq $expectedPath -and
        ([string]::IsNullOrEmpty($expectedFragment) -or
            $actual.Fragment -ceq $expectedFragment)
}
function Test-DocumentVisiblePathMatchesLinkTarget {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$VisiblePath,
        [Parameter(Mandatory)][string]$Target
    )

    $actual = Resolve-DocumentLinkTarget `
        -SourcePath $SourcePath -Target $Target
    if ($actual.Kind -cne 'Repository') { return $false }
    $visibleCandidates = [System.Collections.Generic.List[object]]::new()
    $sourceRelative = Resolve-DocumentLinkTarget `
        -SourcePath $SourcePath -Target $VisiblePath
    if ($sourceRelative.Kind -ceq 'Repository') {
        $sourceRelativeFile = Join-Path $root (
            [string]$sourceRelative.Value -replace '/',
                [IO.Path]::DirectorySeparatorChar
        )
        if (Test-Path -LiteralPath $sourceRelativeFile -PathType Leaf) {
            $visibleCandidates.Add($sourceRelative)
        }
    }
    $cleanVisible = $VisiblePath.Trim().Trim('<', '>')
    if ($cleanVisible -cnotmatch '^(?:\.\./|https?://)') {
        $visibleFragment = ''
        if ($cleanVisible.Contains('#')) {
            $visibleFragment = '#' + ($cleanVisible -split '#', 2)[1]
        }
        $rootRelativeValue = [uri]::UnescapeDataString(
            ($cleanVisible -replace '[?#].*$', '')
        ).Replace('\', '/').TrimStart([char[]]'./')
        $rootRelativeFile = Join-Path $root (
            $rootRelativeValue -replace '/', [IO.Path]::DirectorySeparatorChar
        )
        if (Test-Path -LiteralPath $rootRelativeFile -PathType Leaf) {
            $visibleCandidates.Add([pscustomobject]@{
                Kind = 'Repository'
                Value = $rootRelativeValue
                Fragment = $visibleFragment
            })
        }
    }
    if ($visibleCandidates.Count -eq 0) {
        return $true
    }
    return @($visibleCandidates | Where-Object {
        $_.Value -ceq $actual.Value -and
            ([string]::IsNullOrEmpty([string]$_.Fragment) -or
                $_.Fragment -ceq $actual.Fragment)
    }).Count -gt 0
}
function Test-DocumentResolvedTargetExists {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Target
    )

    $cleanTarget = $Target.Trim().Trim('<', '>')
    if ($cleanTarget -match '^(?:https?://|mailto:)' -or
        $cleanTarget.StartsWith('{{')) {
        return $true
    }
    $resolved = Resolve-DocumentLinkTarget `
        -SourcePath $SourcePath -Target $cleanTarget
    if ($resolved.Kind -cne 'Repository') { return $false }
    $targetFile = Join-Path $root (
        [string]$resolved.Value -replace '/', [IO.Path]::DirectorySeparatorChar
    )
    if (-not (Test-Path -LiteralPath $targetFile)) { return $false }
    if (-not [string]::IsNullOrEmpty([string]$resolved.Fragment)) {
        if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf)) {
            return $false
        }
        $fragment = ([string]$resolved.Fragment).TrimStart('#')
        if ([IO.Path]::GetExtension($targetFile) -ieq '.md') {
            $anchors = Get-MarkdownAnchors (
                Get-Content -LiteralPath $targetFile -Raw
            )
            if (-not $anchors.Contains($fragment)) { return $false }
        }
        else {
            $textEvidence = Get-Utf8TextEvidence `
                -Bytes ([IO.File]::ReadAllBytes($targetFile))
            if (-not $textEvidence.IsText -or
                -not (Test-CanonicalGitHubLineFragment `
                    -Fragment $fragment `
                    -LineCount $textEvidence.LineCount)) {
                return $false
            }
        }
    }
    return $true
}
$historicalRepositoryBlobTargetValidity = @{}
$historicalRepositoryFragmentValidity = @{}
$historicalRepositoryBlobContentEvidence = @{}
$repositoryTagRootValidity = @{}
$historicalRepositoryBlobFetchedBytes = [long]0
$historicalRepositoryBlobMaxUnique = 64
$historicalRepositoryBlobMaxBytes = 1MB
$historicalRepositoryBlobMaxAggregateBytes = 16MB
function Test-HistoricalBlobFetchWithinBudget {
    param(
        [Parameter(Mandatory)][long]$UniqueCount,
        [Parameter(Mandatory)][long]$AggregateBytes,
        [Parameter(Mandatory)][long]$BlobBytes
    )

    return $UniqueCount -lt $historicalRepositoryBlobMaxUnique -and
        $BlobBytes -ge 0 -and
        $BlobBytes -le $historicalRepositoryBlobMaxBytes -and
        $AggregateBytes -le
            ($historicalRepositoryBlobMaxAggregateBytes - $BlobBytes)
}
function Get-GitBlobBytes {
    param([Parameter(Mandatory)][string]$ObjectSpec)

    if ($root.Contains('"') -or $ObjectSpec.Contains('"')) {
        return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
    }
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = '-C "' + $root + '" cat-file blob "' +
        $ObjectSpec + '"'
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $memory = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) {
            return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
        }
        $standardError = $process.StandardError.ReadToEndAsync()
        $process.StandardOutput.BaseStream.CopyTo($memory)
        $process.WaitForExit()
        [void]$standardError.Result
        if ($process.ExitCode -ne 0) {
            return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
        }
        return [pscustomobject]@{
            Success = $true; Bytes = [byte[]]$memory.ToArray()
        }
    }
    catch {
        return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
    }
    finally {
        $memory.Dispose()
        $process.Dispose()
    }
}
function Get-HistoricalRepositoryBlobContentEvidence {
    param(
        [Parameter(Mandatory)][string]$Ref,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ValidityKey
    )

    if ($historicalRepositoryBlobContentEvidence.ContainsKey($ValidityKey)) {
        return $historicalRepositoryBlobContentEvidence[$ValidityKey]
    }
    $failedEvidence = [pscustomobject]@{
        Success = $false; IsText = $false; Text = ''; LineCount = 0
    }
    $sizeOutput = @(& git -C $root cat-file -s "$Ref`:$Path" 2>&1)
    $sizeExitCode = $LASTEXITCODE
    [long]$blobSize = -1
    if ($sizeExitCode -ne 0 -or
        -not [long]::TryParse(($sizeOutput -join '').Trim(), [ref]$blobSize) -or
        -not (Test-HistoricalBlobFetchWithinBudget `
            -UniqueCount $historicalRepositoryBlobContentEvidence.Count `
            -AggregateBytes $historicalRepositoryBlobFetchedBytes `
            -BlobBytes $blobSize)) {
        $historicalRepositoryBlobContentEvidence[$ValidityKey] = $failedEvidence
        return $failedEvidence
    }
    $blobResult = Get-GitBlobBytes -ObjectSpec "$Ref`:$Path"
    if (-not $blobResult.Success -or
        [long]$blobResult.Bytes.Length -ne $blobSize) {
        $historicalRepositoryBlobContentEvidence[$ValidityKey] = $failedEvidence
        return $failedEvidence
    }
    $script:historicalRepositoryBlobFetchedBytes += $blobSize
    $textEvidence = Get-Utf8TextEvidence -Bytes $blobResult.Bytes
    $evidence = [pscustomobject]@{
        Success = $true
        IsText = [bool]$textEvidence.IsText
        Text = [string]$textEvidence.Text
        LineCount = [long]$textEvidence.LineCount
    }
    $historicalRepositoryBlobContentEvidence[$ValidityKey] = $evidence
    return $evidence
}
function Test-DocumentNonCanonicalSameRepositoryTarget {
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)]$TrackedRepositoryPaths
    )

    $cleanTarget = $Target.Trim().Trim('<', '>')
    $targetMatch = [regex]::Match(
        $cleanTarget,
        '(?i)^https://github\.com/hasanmanzak/meAndAI/(?<kind>blob|tree)/(?<remainder>[^?#]+)(?<suffix>[?#].*)?$'
    )
    if (-not $targetMatch.Success) { return $false }
    $remainder = [uri]::UnescapeDataString(
        [string]$targetMatch.Groups['remainder'].Value
    ).Replace('\', '/')
    $targetKind = [string]$targetMatch.Groups['kind'].Value
    $ref = ''
    $path = ''
    $exactHistoricalBlob = [regex]::Match(
        $remainder,
        '^(?<ref>[0-9a-f]{40})/(?<path>.+)$'
    )
    if ($targetKind -ieq 'blob' -and $exactHistoricalBlob.Success) {
        $ref = [string]$exactHistoricalBlob.Groups['ref'].Value
        $path = [string]$exactHistoricalBlob.Groups['path'].Value
    }
    else {
        for ($separatorIndex = $remainder.IndexOf('/');
            $separatorIndex -ge 0;
            $separatorIndex = $remainder.IndexOf('/', $separatorIndex + 1)) {
            $candidatePath = $remainder.Substring($separatorIndex + 1)
            if (-not $TrackedRepositoryPaths.Contains($candidatePath)) {
                continue
            }
            $ref = $remainder.Substring(0, $separatorIndex)
            $path = $candidatePath
            break
        }
    }
    if ($targetKind -ieq 'tree') {
        if (-not [string]::IsNullOrEmpty($path) -or
            $targetMatch.Groups['suffix'].Success) {
            return $true
        }
        $tagRef = "refs/tags/$remainder"
        if (-not $repositoryTagRootValidity.ContainsKey($tagRef)) {
            & git -C $root show-ref --verify --quiet $tagRef 2>&1 | Out-Null
            $repositoryTagRootValidity[$tagRef] = $LASTEXITCODE -eq 0
        }
        return -not [bool]$repositoryTagRootValidity[$tagRef]
    }
    if ([string]::IsNullOrEmpty($path) -or
        $ref -cnotmatch '^[0-9a-f]{40}$') {
        return $true
    }
    $validityKey = "$ref`n$path"
    if (-not $historicalRepositoryBlobTargetValidity.ContainsKey(
            $validityKey
        )) {
        $previousProbeErrorPreference = $ErrorActionPreference
        $commitTypeOutput = @()
        $commitTypeExitCode = -1
        $pathTypeOutput = @()
        $pathTypeExitCode = -1
        try {
            $ErrorActionPreference = 'Continue'
            $commitTypeOutput = @(& git -C $root cat-file -t $ref 2>$null)
            $commitTypeExitCode = $LASTEXITCODE
            if ($commitTypeExitCode -eq 0 -and
                ($commitTypeOutput -join '').Trim() -ceq 'commit') {
                $pathTypeOutput = @(
                    & git -C $root cat-file -t "$ref`:$path" 2>$null
                )
                $pathTypeExitCode = $LASTEXITCODE
            }
        }
        finally {
            $ErrorActionPreference = $previousProbeErrorPreference
        }
        $historicalRepositoryBlobTargetValidity[$validityKey] =
            $commitTypeExitCode -eq 0 -and
            ($commitTypeOutput -join '').Trim() -ceq 'commit' -and
            $pathTypeExitCode -eq 0 -and
            ($pathTypeOutput -join '').Trim() -ceq 'blob'
    }
    if (-not [bool]$historicalRepositoryBlobTargetValidity[$validityKey]) {
        return $true
    }
    $fragmentMatch = [regex]::Match(
        $cleanTarget,
        '#(?<name>[^?]*)'
    )
    if (-not $fragmentMatch.Success) { return $false }
    $rawFragmentName = [string]$fragmentMatch.Groups['name'].Value
    $fragmentName = [uri]::UnescapeDataString($rawFragmentName)
    $fragmentValidityKey = "$validityKey`n$rawFragmentName"
    if (-not $historicalRepositoryFragmentValidity.ContainsKey(
            $fragmentValidityKey
        )) {
        $contentEvidence = Get-HistoricalRepositoryBlobContentEvidence `
            -Ref $ref -Path $path -ValidityKey $validityKey
        $isValidFragment = $false
        if ($contentEvidence.Success -and $contentEvidence.IsText) {
            if ([IO.Path]::GetExtension($path) -ieq '.md') {
                $matchingHistoricalAnchors = @(
                    Get-RendererActiveMarkdownAnchorEvidence `
                        -Markdown $contentEvidence.Text |
                        Where-Object {
                            [string]$_.Name -ceq $fragmentName
                        }
                )
                $isValidFragment = $matchingHistoricalAnchors.Count -eq 1
            }
            else {
                $isValidFragment = Test-CanonicalGitHubLineFragment `
                    -Fragment $rawFragmentName `
                    -LineCount $contentEvidence.LineCount
            }
        }
        $historicalRepositoryFragmentValidity[$fragmentValidityKey] =
            $isValidFragment
    }
    return -not [bool]$historicalRepositoryFragmentValidity[
        $fragmentValidityKey
    ]
}
$documentMarkdownPaths = @(& git -C $root ls-files --cached --others `
    --exclude-standard -- '*.md')
if ($LASTEXITCODE -ne 0) {
    Add-Failure 'TEST-0175 tracked Markdown inventory failed.'
    $documentMarkdownPaths = @()
}
$trackedRepositoryPaths = @(& git -C $root ls-files --cached)
if ($LASTEXITCODE -ne 0) {
    Add-Failure 'TEST-0177 tracked repository inventory failed.'
    $trackedRepositoryPaths = @()
}
$trackedRepositoryPathSet = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($trackedRepositoryPath in $trackedRepositoryPaths) {
    [void]$trackedRepositoryPathSet.Add([string]$trackedRepositoryPath)
}
$documentTitleCandidates = @{}
$documentHeadingTitles = @{}
$stableDocumentTitleNames = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
foreach ($relativeMarkdownPath in $documentMarkdownPaths) {
    $titleMarkdown = Get-Content -LiteralPath (
        Join-Path $root $relativeMarkdownPath
    ) -Raw
    $heading = [regex]::Match($titleMarkdown, '(?m)^#\s+(?<title>.+?)\s*$')
    if (-not $heading.Success) { continue }
    $headingTitle = $heading.Groups['title'].Value.Trim()
    $documentHeadingTitles[$relativeMarkdownPath] = $headingTitle
    $descriptive = [regex]::Match(
        $headingTitle,
        '^(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}\s+-\s+(?<title>.+)$'
    )
    $title = if ($descriptive.Success) {
        $descriptive.Groups['title'].Value.Trim()
    }
    else { $headingTitle }
    if ($descriptive.Success) {
        [void]$stableDocumentTitleNames.Add($title)
    }
    foreach ($title in @($title)) {
        if ($title.Length -lt 12) { continue }
        if (-not $documentTitleCandidates.ContainsKey($title)) {
            $documentTitleCandidates[$title] = [Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal
            )
        }
        [void]$documentTitleCandidates[$title].Add($relativeMarkdownPath)
    }
}
$documentTitleTargets = @{}
foreach ($title in $documentTitleCandidates.Keys) {
    if ($documentTitleCandidates[$title].Count -eq 1) {
        $documentTitleTargets[$title] = @($documentTitleCandidates[$title])[0]
    }
}
$allDocumentTitleAlternation = @($documentTitleTargets.Keys |
    Sort-Object Length -Descending |
    ForEach-Object { [regex]::Escape($_) }) -join '|'
$documentTitleReferenceParts = [Collections.Generic.List[string]]::new()
if (-not [string]::IsNullOrEmpty($allDocumentTitleAlternation)) {
    $documentTitleReferenceParts.Add(
        '\b(?:see|read|open|consult|reference(?:d)?(?:\s+to)?|according\s+to|described\s+in|documented\s+in)\s+(?:(?:the|a)\s+)?(?<title>' +
            $allDocumentTitleAlternation + ')(?![A-Za-z0-9])'
    )
    $documentTitleReferenceParts.Add(
        '(?<![A-Za-z0-9])(?:(?:the|a)\s+)?(?<title>' +
            $allDocumentTitleAlternation +
            ')\s+(?:guide|document|record|for\s+(?:details|context)|is\s+authoritative|governs|defines)\b'
    )
}
$documentTitleReferencePattern = if ($documentTitleReferenceParts.Count -eq 0) {
    '(?!)'
}
else { '(?i)(?:' + ($documentTitleReferenceParts -join '|') + ')' }
$documentTitleLinkPattern = if ([string]::IsNullOrEmpty(
    $allDocumentTitleAlternation
)) { '(?!)' }
else {
    '(?i)(?:' + ($documentTitleReferenceParts -join '|') + ')'
}
function Test-DocumentTitleIsOwnIdentity {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Title
    )

    if ($documentTitleTargets.ContainsKey($Title) -and
        [string]$documentTitleTargets[$Title] -ceq $SourcePath) {
        return $true
    }
    return $documentHeadingTitles.ContainsKey($SourcePath) -and
        (Test-DocumentHeadingOwnsTitle `
            -Heading ([string]$documentHeadingTitles[$SourcePath]) `
            -Title $Title)
}
function Get-CodeFormattedDocumentTitleReferences {
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [Parameter(Mandatory)]$CodeSpan,
        [Parameter(Mandatory)][string[]]$Titles
    )

    $beforeStart = [Math]::Max(0, [int]$CodeSpan.Index - 80)
    $before = $Markdown.Substring(
        $beforeStart,
        [int]$CodeSpan.Index - $beforeStart
    )
    $afterStart = [int]$CodeSpan.Index + [int]$CodeSpan.Length
    $after = $Markdown.Substring(
        $afterStart,
        [Math]::Min(80, $Markdown.Length - $afterStart)
    )
    $hasReferentialContext = [regex]::IsMatch(
        $before,
        '(?i)\b(?:see|read|open|consult|reference(?:d)?(?:\s+to)?|according\s+to|documented\s+in|described\s+in)\s*$'
    ) -or [regex]::IsMatch(
        $after,
        '(?i)^\s+(?:document|record|guide|is\s+authoritative|governs|defines|for\s+(?:details|context))\b'
    )
    $hasMarkdownLinkSyntax = [regex]::IsMatch(
        [string]$CodeSpan.Content,
        '(?i)(?<![!\\])\[[^\]]+\]\([^)]+\)'
    )
    if (-not $hasReferentialContext -and -not $hasMarkdownLinkSyntax) {
        return @()
    }
    $references = [System.Collections.Generic.List[string]]::new()
    foreach ($title in $Titles) {
        if ((Test-ContainsExactDocumentTitle `
                -Text ([string]$CodeSpan.Content) -Title $title) -and
            ($hasReferentialContext -or [regex]::IsMatch(
                [string]$CodeSpan.Content,
                '(?i)(?<![!\\])\[[^\]]*' + [regex]::Escape($title) +
                    '[^\]]*\]\([^)]+\)'
            ))) {
            $references.Add($title)
        }
    }
    return @($references)
}
function Get-CrossDocumentAggregateRanges {
    param(
        [Parameter(Mandatory)][string]$RenderedReferenceText,
        [Parameter(Mandatory)][string]$SourcePath
    )

    $results = [Collections.Generic.List[object]]::new()
    foreach ($range in [regex]::Matches(
        $RenderedReferenceText,
        '(?i)(?<prefix>EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-(?<first>\d{4})[ \t]*(?:through|to|\.\.|-|\u2013|\u2014)[ \t]*(?:(?<lastPrefix>EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-)?(?<last>\d{4})'
    )) {
        $beforeStart = [Math]::Max(0, $range.Index - 80)
        $beforeRange = $RenderedReferenceText.Substring(
            $beforeStart,
            $range.Index - $beforeStart
        )
        if ($range.Value -match '(?i)\s+to\s+' -and
            $beforeRange -match '(?i)\bfrom(?:\s+the\s+pre-existing)?\s*$') {
            continue
        }
        $prefix = $range.Groups['prefix'].Value.ToUpperInvariant()
        $lastPrefix = $range.Groups['lastPrefix'].Value
        if (-not [string]::IsNullOrEmpty($lastPrefix) -and
            $lastPrefix.ToUpperInvariant() -cne $prefix) { continue }
        $first = [int]$range.Groups['first'].Value
        $last = [int]$range.Groups['last'].Value
        if ($last -le $first -or $last -gt ($first + 1000)) { continue }
        for ($number = $first; $number -le $last; $number++) {
            $id = '{0}-{1:D4}' -f $prefix, $number
            if ($documentRecordTargets.ContainsKey($id) -and
                (Get-DocumentRecordTargetPath `
                    -Target ([string]$documentRecordTargets[$id])) -cne
                    $SourcePath) {
                $results.Add($range)
                break
            }
        }
    }
    return @($results)
}
foreach ($relativeMarkdownPath in $documentMarkdownPaths) {
    $markdownPath = Join-Path $root $relativeMarkdownPath
    $markdown = Get-Content -LiteralPath $markdownPath -Raw
    if ([regex]::IsMatch(
        $markdown,
        '(?i)https?://[^\s\[\]<>()]*\[[^\]]+\](?:\([^)]+\)|[ \t]*\[[^\]]*\])[^\s<>()]*'
    )) {
        Add-Failure "TEST-0175 $relativeMarkdownPath composes a visible URL across a partial Markdown link."
    }
    $linkEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $markdown -Path $relativeMarkdownPath
    foreach ($composedLink in @($linkEvidence.Links)) {
        $prefix = $markdown.Substring(0, [int]$composedLink.Index)
        if ([regex]::IsMatch(
            $prefix,
            '(?i)https?://[^\s<>()\[\]]*$'
        )) {
            Add-Failure "TEST-0175 $relativeMarkdownPath composes a visible URL across a partial Markdown link."
        }
    }
    foreach ($definition in @($linkEvidence.Definitions)) {
        $definitionKey = $definition.Groups['key'].Value.Trim()
        $isUsed = @($linkEvidence.Links | Where-Object {
            $_.Style -ceq 'Reference' -and
                $_.ReferenceKey -ieq $definitionKey
        }).Count -gt 0
        if ($isUsed) { continue }
        $definitionText = ConvertTo-DocumentMarkdownRenderedText `
            -Text ([string]$definition.Value)
        if ([regex]::IsMatch(
            $definitionText,
            $hiddenCrossRecordReferencePattern
        ) -or @(Get-DocumentGitHubShorthandReferences `
            -Text $definitionText).Count -gt 0) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains an unused reference-link definition with a non-clickable cross-record reference."
        }
    }
    $codeSpans = @($linkEvidence.CodeSpans)
    foreach ($unresolvedReference in @($linkEvidence.Unresolved)) {
        Add-Failure "TEST-0175 $relativeMarkdownPath contains unresolved reference-style link '$($unresolvedReference.Label)' -> '$($unresolvedReference.Key)'."
    }
    foreach ($htmlComment in @($linkEvidence.HtmlComments)) {
        $commentContent = [regex]::Replace(
            [string]$htmlComment.Value,
            '(?s)^<!--|-->$',
            ''
        )
        $hiddenText = ConvertTo-DocumentMarkdownRenderedText `
            -Text $commentContent
        if ([regex]::IsMatch(
            $hiddenText,
            $hiddenCrossRecordReferencePattern
        ) -or @(Get-DocumentGitHubShorthandReferences `
            -Text $hiddenText).Count -gt 0) {
            Add-Failure "TEST-0175 $relativeMarkdownPath hides a cross-record reference in a non-clickable HTML comment."
        }
    }
    foreach ($htmlBlock in @($linkEvidence.NonRenderingHtml)) {
        $literalHtmlText = ConvertTo-DocumentMarkdownRenderedText `
            -Text ([string]$htmlBlock.Value)
        if ([regex]::IsMatch(
            $literalHtmlText,
            $hiddenCrossRecordReferencePattern
        ) -or @(Get-DocumentGitHubShorthandReferences `
            -Text $literalHtmlText).Count -gt 0) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a cross-record reference inside non-rendering HTML."
        }
    }
    foreach ($codeSpan in $codeSpans) {
        $codeIsInsideClickableLink = @($linkEvidence.Links | Where-Object {
            $codeSpan.Index -ge $_.Index -and
                ($codeSpan.Index + $codeSpan.Length) -le
                    ($_.Index + $_.Length)
        }).Count -gt 0
        if ($codeIsInsideClickableLink) { continue }
        if (Test-CodeFormattedDocumentReference `
            -Markdown $markdown -CodeSpan $codeSpan) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a code-formatted repository-document reference that is not clickable."
        }
        if ([regex]::IsMatch(
            [string]$codeSpan.Content,
            '(?i)(?<![!\\])\[[^\]]+\]\((?:[^)\s]+\.md(?:#[A-Za-z0-9_.:-]+)?|https?://github\.com/[^/]+/[^/]+/blob/[^)\s]+)\)'
        )) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a code-formatted repository-document pseudo-link that is not clickable."
        }
        foreach ($knownTitle in Get-CodeFormattedDocumentTitleReferences `
            -Markdown $markdown -CodeSpan $codeSpan `
            -Titles @($documentTitleTargets.Keys)) {
            if (-not (Test-DocumentTitleIsOwnIdentity `
                    -SourcePath $relativeMarkdownPath `
                    -Title $knownTitle)) {
                Add-Failure "TEST-0175 $relativeMarkdownPath contains a code-formatted document-title reference '$knownTitle' that is not clickable."
            }
        }
        foreach ($codeId in @([regex]::Matches(
            [string]$codeSpan.Content,
            $recordIdPattern
        ) | ForEach-Object { $_.Value } | Select-Object -Unique)) {
            $isFeatureCompanionIdentity = $codeId.StartsWith('FEAT-') -and
                $relativeMarkdownPath -match
                    "^docs/features/$codeId-[^/]+/(?:README|test-cases)\.md$"
            $isCanonicalIdentity = Test-DocumentRecordOwnIdentity `
                -Id $codeId -SourcePath $relativeMarkdownPath
            if (-not $isFeatureCompanionIdentity -and
                -not $isCanonicalIdentity) {
                Add-Failure "TEST-0175 $relativeMarkdownPath contains a code-formatted cross-record identifier $codeId that is not clickable."
            }
        }
        $codeContainsGitHubReference = [regex]::IsMatch(
            [string]$codeSpan.Content,
            $githubNumberPattern
        ) -or [regex]::IsMatch(
            [string]$codeSpan.Content,
            '(?i)https?://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/[1-9][0-9]*|blob/[^<>\s]+)|\b(?:comment|review)\s+#?\d+\b'
        ) -or @(Get-DocumentGitHubShorthandReferences `
            -Text ([string]$codeSpan.Content)).Count -gt 0
        $isSyntheticFixture =
            $relativeMarkdownPath -ceq
                'docs/features/FEAT-0034-ci-evidence-hygiene/README.md' -and
            @([regex]::Matches(
                [string]$codeSpan.Content,
                $githubNumberPattern
            ) | Where-Object {
                [int]$_.Groups['number'].Value -in @(9, 42)
            }).Count -gt 0
        if ($codeContainsGitHubReference -and -not $isSyntheticFixture) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a code-formatted GitHub cross-record reference that is not clickable."
        }
    }
    foreach ($link in @($linkEvidence.Links)) {
        $label = ConvertTo-DocumentMarkdownRenderedText `
            -Text ([string]$link.Label)
        $target = [string]$link.Target
        if (Test-DocumentNonCanonicalSameRepositoryTarget `
                -Target $target `
                -TrackedRepositoryPaths $trackedRepositoryPathSet) {
            Add-Failure "TEST-0177 $relativeMarkdownPath links a current tracked repository path through a mutable or unverifiable same-repository blob/tree target '$target'."
        }
        foreach ($visibleUrl in @(
            Get-DocumentMarkdownVisibleHttpUrlSpans -Text $label
        )) {
            $expectedUrl = [string]$visibleUrl.Value
            if ($target.Trim().Trim('<', '>') -cne $expectedUrl) {
                Add-Failure "TEST-0175 $relativeMarkdownPath links visible URL '$expectedUrl' to a different target '$target'."
            }
        }
        foreach ($visiblePath in [regex]::Matches(
            $label,
            $rawDocumentPathPattern
        )) {
            if (-not (Test-DocumentVisiblePathMatchesLinkTarget `
                    -SourcePath $relativeMarkdownPath `
                    -VisiblePath ([string]$visiblePath.Value) `
                    -Target $target)) {
                Add-Failure "TEST-0175 $relativeMarkdownPath links visible repository-document path '$($visiblePath.Value)' to a different target '$target'."
            }
        }
        if ($link.Style -ceq 'Reference' -and
            -not (Test-DocumentResolvedTargetExists `
                -SourcePath $relativeMarkdownPath -Target $target)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a broken reference-style link target '$target'."
        }
        $commentStatus = Get-DocumentCommentLinkStatus `
            -Label $label -Target $target
        if ($commentStatus.IsReference) {
            if (-not $commentStatus.Target.Success) {
                Add-Failure "TEST-0175 $relativeMarkdownPath contains a comment link that is not an exact GitHub comment permalink."
            }
            if ($commentStatus.Target.Success -and
                $commentStatus.LabelId.Success -and
                $commentStatus.LabelId.Groups['id'].Value -cne
                    $commentStatus.Target.Groups['id'].Value) {
                Add-Failure "TEST-0175 $relativeMarkdownPath contains a comment label that does not match its permalink target."
            }
            if ($commentStatus.Target.Success -and
                $commentStatus.Parent.Success) {
                $expectedParentKind = if (
                    $commentStatus.Parent.Groups['kind'].Value -ieq 'issue'
                ) { 'issues' } else { 'pull' }
                if ($commentStatus.Target.Groups['parentKind'].Value -cne
                        $expectedParentKind -or
                    $commentStatus.Target.Groups['parentNumber'].Value -cne
                        $commentStatus.Parent.Groups['number'].Value) {
                    Add-Failure "TEST-0175 $relativeMarkdownPath contains a comment parent label that does not match its permalink target."
                }
            }
            $numericArtifactOrBareLabel = [regex]::Match(
                $label,
                '(?i)(?<![A-Za-z0-9_])(?:(?:issue|PR|pull request)\s+#?|#)[1-9][0-9]*(?![A-Za-z0-9_-])'
            )
            if ($numericArtifactOrBareLabel.Success -and
                -not $commentStatus.Parent.Success -and
                -not $commentStatus.LabelId.Success) {
                Add-Failure "TEST-0175 $relativeMarkdownPath uses an issue, pull-request, or bare numeric label for a comment target."
            }
        }
        else {
        $githubReferences = @([regex]::Matches(
            $label,
            $githubNumberPattern
        ))
        $numberOnlyReference = [regex]::Match(
            $label.Trim(), '^(?<source>(?<number>\d+))$'
        )
        if ($numberOnlyReference.Success -and [regex]::IsMatch(
            $target.Trim().Trim('<', '>'),
            '^https://github\.com/[^/]+/[^/]+/(?:issues|pull)/\d+$'
        )) {
            $githubReferences += $numberOnlyReference
        }
        foreach ($githubReference in $githubReferences) {
            $cleanTarget = $target.Trim().Trim('<', '>')
            if ($cleanTarget -notmatch '^https://github\.com/[^/]+/[^/]+/(?<kind>issues|pull)/(?<number>\d+)$') {
                Add-Failure "TEST-0175 $relativeMarkdownPath links '$($githubReference.Value)' to a non-record target '$target'."
                continue
            }
            $targetKind = [string]$Matches['kind']
            $targetNumber = [int]$Matches['number']
            if ($targetNumber -ne
                [int]$githubReference.Groups['number'].Value) {
                Add-Failure "TEST-0175 $relativeMarkdownPath links '$($githubReference.Value)' to the wrong GitHub number '$target'."
            }
            $declaredKind = $githubReference.Groups['kind'].Value
            if ($declaredKind -match '^(?i:PR|pull request)$' -and
                $targetKind -cne 'pull') {
                Add-Failure "TEST-0175 $relativeMarkdownPath links PR reference '$($githubReference.Value)' to an issue URL."
            }
            if ($declaredKind -match '^(?i:issue)$' -and
                $targetKind -cne 'issues') {
                Add-Failure "TEST-0175 $relativeMarkdownPath links issue reference '$($githubReference.Value)' to a pull-request URL."
            }
        }
        }
        $linkedTitles = @([regex]::Matches(
            $label,
            $documentTitleLinkPattern
        ) | ForEach-Object { $_.Groups['title'].Value } | Select-Object -Unique)
        foreach ($linkedTitle in $linkedTitles) {
            $matchesCanonicalTitleTarget = Test-DocumentRecordLinkTarget `
                    -SourcePath $relativeMarkdownPath -Target $target `
                    -ExpectedTarget ([string]$documentTitleTargets[$linkedTitle])
            $resolvedTitleTarget = Resolve-DocumentLinkTarget `
                -SourcePath $relativeMarkdownPath -Target $target
            $matchesTargetOwnTitle =
                $resolvedTitleTarget.Kind -ceq 'Repository' -and
                $documentHeadingTitles.ContainsKey(
                    [string]$resolvedTitleTarget.Value
                ) -and
                (Test-DocumentHeadingOwnsTitle `
                    -Heading ([string]$documentHeadingTitles[[string]$resolvedTitleTarget.Value]) `
                    -Title $linkedTitle)
            if (-not $matchesCanonicalTitleTarget -and
                -not $matchesTargetOwnTitle) {
                Add-Failure "TEST-0175 $relativeMarkdownPath links document title '$linkedTitle' to the wrong target '$target'."
            }
        }
        $shorthandReferences = @(
            Get-DocumentGitHubShorthandReferences -Text $label
        )
        if ($shorthandReferences.Count -gt 1) {
            Add-Failure "TEST-0175 $relativeMarkdownPath combines multiple GitHub shorthand references in one link."
        }
        foreach ($shorthandReference in $shorthandReferences) {
            if (-not (Test-DocumentExactGitHubShorthandTarget `
                    -Reference $shorthandReference -Target $target)) {
                Add-Failure "TEST-0175 $relativeMarkdownPath links GitHub shorthand '$($shorthandReference.Value)' to a target other than its exact GitHub record."
            }
        }
        $linkIds = @([regex]::Matches(
            $label,
            $recordIdPattern
        ) | ForEach-Object { $_.Value } | Select-Object -Unique)
        if ($linkIds.Count -eq 0) {
            continue
        }
        if (@($codeSpans | Where-Object {
            $link.Index -ge $_.Index -and $link.Index -lt ($_.Index + $_.Length)
        }).Count -gt 0) {
            Add-Failure "TEST-0175 $relativeMarkdownPath wraps a record link in code, so it is not clickable."
        }
        if ($linkIds.Count -ne 1) {
            Add-Failure "TEST-0175 $relativeMarkdownPath combines multiple record references in one link."
            continue
        }
        $id = $linkIds[0]
        if (-not $documentRecordTargets.ContainsKey($id)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath links unregistered record $id."
            continue
        }
        $expectedTargets = @([string]$documentRecordTargets[$id])
        if ($id.StartsWith('FEAT-') -and
            $expectedTargets[0].EndsWith('/README.md', [StringComparison]::Ordinal)) {
            $expectedTargets += $expectedTargets[0].Substring(
                0, $expectedTargets[0].Length - 'README.md'.Length
            ) + 'test-cases.md'
        }
        $matchesExpectedTarget = @($expectedTargets | Where-Object {
            Test-DocumentRecordLinkTarget -SourcePath $relativeMarkdownPath `
                -Target $target -ExpectedTarget $_
        }).Count -gt 0
        if (-not $matchesExpectedTarget) {
            $resolvedTarget = Resolve-DocumentLinkTarget `
                -SourcePath $relativeMarkdownPath -Target $target
            $matchesExpectedTarget =
                $relativeMarkdownPath -ceq '.ai/memory/log/README.md' -and
                $resolvedTarget.Kind -ceq 'Repository' -and
                ([string]$resolvedTarget.Value).StartsWith(
                    '.ai/memory/log/', [StringComparison]::Ordinal
                ) -and
                $label -match '^\d{4}-\d{2}-\d{2}\s+-\s+' -and
                [regex]::IsMatch(
                    [string]$resolvedTarget.Value,
                    '(?i)^\.ai/memory/log/\d{4}-\d{2}-\d{2}-.*(?<![A-Za-z0-9])' +
                        [regex]::Escape($id) + '(?![A-Za-z0-9]).*\.md$'
                )
        }
        if (-not $matchesExpectedTarget) {
            Add-Failure "TEST-0175 $relativeMarkdownPath links $id to '$target' instead of one of its exact canonical targets."
        }
    }
    foreach ($autolink in @(Get-DocumentRendererActiveHttpAutolinkSpans `
        -Markdown $markdown -LinkEvidence $linkEvidence)) {
        if (Test-DocumentNonCanonicalSameRepositoryTarget `
                -Target ([string]$autolink.Value) `
                -TrackedRepositoryPaths $trackedRepositoryPathSet) {
            Add-Failure "TEST-0177 $relativeMarkdownPath exposes a current tracked repository path through a mutable or unverifiable same-repository blob/tree autolink '$($autolink.Value)'."
        }
    }
    foreach ($shorthand in [regex]::Matches(
        $markdown,
        '\]\([^)]+\)(?:\s*/\s*`?(?:[A-Z]+-)?\d{4}`?)+'
    )) {
        Add-Failure "TEST-0175 $relativeMarkdownPath contains unlinked shorthand after a record link: '$($shorthand.Value)'."
    }
    $unlinkedMarkdown = Get-DocumentUnlinkedMarkdown `
        -Markdown $markdown -LinkEvidence $linkEvidence
    foreach ($titleReference in [regex]::Matches(
        $unlinkedMarkdown,
        $documentTitleReferencePattern
    )) {
        $title = $titleReference.Groups['title'].Value
        if (-not (Test-DocumentTitleIsOwnIdentity `
                -SourcePath $relativeMarkdownPath -Title $title)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains an unlinked document-title reference '$title'."
        }
    }
    $renderedReferenceText = Get-RenderedDocumentReferenceText `
        -Markdown $markdown -LinkEvidence $linkEvidence
    foreach ($range in Get-CrossDocumentAggregateRanges `
        -RenderedReferenceText $renderedReferenceText `
        -SourcePath $relativeMarkdownPath) {
        Add-Failure "TEST-0175 $relativeMarkdownPath contains a cross-document aggregate range '$($range.Value)' whose implied records are not individually linked."
    }
    foreach ($match in [regex]::Matches($unlinkedMarkdown, $recordIdPattern)) {
        $id = $match.Value
        $isFeatureCompanionIdentity = $id.StartsWith('FEAT-') -and
            $relativeMarkdownPath -match "^docs/features/$id-[^/]+/(?:README|test-cases)\.md$"
        $isCanonicalIdentity = Test-DocumentRecordOwnIdentity `
            -Id $id -SourcePath $relativeMarkdownPath
        if (-not $isFeatureCompanionIdentity -and -not $isCanonicalIdentity) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains unlinked cross-record identifier $id."
        }
    }
    foreach ($githubReference in [regex]::Matches(
        $unlinkedMarkdown,
        $githubNumberPattern
    )) {
        $number = [int]$githubReference.Groups['number'].Value
        $isSyntheticFixture =
            $relativeMarkdownPath -ceq 'docs/features/FEAT-0034-ci-evidence-hygiene/README.md' -and
            $number -in @(9, 42)
        if (-not $isSyntheticFixture) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains unlinked GitHub reference '$($githubReference.Value)'."
        }
    }
    foreach ($shorthandReference in @(
        Get-DocumentGitHubShorthandReferences -Text $unlinkedMarkdown
    )) {
        Add-Failure "TEST-0175 $relativeMarkdownPath contains unlinked GitHub shorthand '$($shorthandReference.Value)'."
    }
    $proseUnlinkedMarkdown = [regex]::Replace(
        $unlinkedMarkdown,
        '(?ms)^```[^\r\n]*\r?\n.*?^```\s*$|(?m)(?<!`)`[^`\r\n]+`(?!`)',
        ''
    )
    foreach ($rawPath in [regex]::Matches(
        $proseUnlinkedMarkdown, $rawDocumentPathPattern
    )) {
        $resolvedRawPath = Resolve-DocumentLinkTarget `
            -SourcePath $relativeMarkdownPath `
            -Target ([string]$rawPath.Value)
        if ($resolvedRawPath.Kind -ceq 'Repository' -and
            [string]$resolvedRawPath.Value -ceq $relativeMarkdownPath) {
            continue
        }
        Add-Failure "TEST-0175 $relativeMarkdownPath contains unlinked repository document path '$($rawPath.Value)'."
    }
    $renderedEvidence = Get-DocumentRenderedReferenceEvidence `
        -Markdown $markdown -LinkEvidence $linkEvidence
    foreach ($renderedUrl in [regex]::Matches(
        [string]$renderedEvidence.Text,
        '(?i)https?://[^\s<>()\[\]{}"''`]+'
    )) {
        $urlLength = ([string]$renderedUrl.Value).TrimEnd(
            [char[]]'.,;:!?'
        ).Length
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedUrl.Index -Length $urlLength `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a visible URL that is not wholly covered by one clickable link."
        }
    }
    foreach ($renderedId in [regex]::Matches(
        [string]$renderedEvidence.Text,
        $recordIdPattern
    )) {
        $id = [string]$renderedId.Value
        $isFeatureCompanionIdentity = $id.StartsWith('FEAT-') -and
            $relativeMarkdownPath -match
                "^docs/features/$id-[^/]+/(?:README|test-cases)\.md$"
        $isCanonicalIdentity = Test-DocumentRecordOwnIdentity `
            -Id $id -SourcePath $relativeMarkdownPath
        if ($isFeatureCompanionIdentity -or $isCanonicalIdentity) { continue }
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedId.Index -Length $renderedId.Length `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a visible cross-record identifier $id that is not wholly covered by one clickable link."
        }
    }
    foreach ($renderedGitHubReference in [regex]::Matches(
        [string]$renderedEvidence.Text,
        $githubNumberPattern
    )) {
        $number = [int]$renderedGitHubReference.Groups['number'].Value
        $isSyntheticFixture =
            $relativeMarkdownPath -ceq
                'docs/features/FEAT-0034-ci-evidence-hygiene/README.md' -and
            $number -in @(9, 42)
        if ($isSyntheticFixture) { continue }
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedGitHubReference.Index `
                -Length $renderedGitHubReference.Length `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains visible GitHub record '$($renderedGitHubReference.Value)' that is not wholly covered by one clickable link."
        }
    }
    foreach ($renderedComment in [regex]::Matches(
        [string]$renderedEvidence.Text,
        '(?i)\b(?:comment|review)\s+#?[1-9][0-9]*\b'
    )) {
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedComment.Index -Length $renderedComment.Length `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a visible GitHub comment reference that is not wholly covered by one clickable link."
        }
    }
    foreach ($renderedShorthand in @(
        Get-DocumentGitHubShorthandReferences `
            -Text ([string]$renderedEvidence.Text)
    )) {
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedShorthand.Index `
                -Length $renderedShorthand.Length `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a visible GitHub shorthand that is not wholly covered by one clickable link."
        }
    }
    foreach ($renderedTitle in [regex]::Matches(
        [string]$renderedEvidence.Text,
        $documentTitleReferencePattern
    )) {
        $title = [string]$renderedTitle.Groups['title'].Value
        if (Test-DocumentTitleIsOwnIdentity `
            -SourcePath $relativeMarkdownPath -Title $title) { continue }
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedTitle.Groups['title'].Index `
                -Length $renderedTitle.Groups['title'].Length `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a visible document-title reference '$title' that is not wholly covered by one clickable link."
        }
    }
    foreach ($renderedPath in [regex]::Matches(
        [string]$renderedEvidence.Text,
        $rawDocumentPathPattern
    )) {
        $resolvedRenderedPath = Resolve-DocumentLinkTarget `
            -SourcePath $relativeMarkdownPath `
            -Target ([string]$renderedPath.Value)
        if ($resolvedRenderedPath.Kind -ceq 'Repository' -and
            [string]$resolvedRenderedPath.Value -ceq
                $relativeMarkdownPath) { continue }
        if (-not (Test-DocumentRenderedReferenceCoveredByLink `
                -Index $renderedPath.Index -Length $renderedPath.Length `
                -RenderedEvidence $renderedEvidence)) {
            Add-Failure "TEST-0175 $relativeMarkdownPath contains a visible repository-document path that is not wholly covered by one clickable link."
        }
    }
}
if (-not (Test-CodeFormattedDocumentReference `
    -Markdown 'See `docs/notes/release-evidence.md` for details.' `
    -CodeSpan ([regex]::Match(
        'See `docs/notes/release-evidence.md` for details.',
        '(?<!`)`[^`\r\n]+`(?!`)'
    )))) {
    Add-Failure 'TEST-0175 code-formatted document-reference fixture was not rejected.'
}
foreach ($titleFixture in @(
    'Clickable Cross-Record References is authoritative.',
    'See Clickable Cross-Record References for context.',
    'Common Development Protocol is authoritative.'
)) {
    $expectedFixtureTitle = if ($titleFixture -match 'Common Development') {
        'Common Development Protocol'
    }
    else { 'Clickable Cross-Record References' }
    if (-not (Test-ContainsExactDocumentTitle `
            -Text $titleFixture -Title $expectedFixtureTitle) -or
        @([regex]::Matches(
            $titleFixture,
            $documentTitleReferencePattern
        )).Count -ne 1) {
        Add-Failure "TEST-0175 free-text document-title fixture was not rejected: '$titleFixture'."
    }
}
foreach ($ownHeadingFixture in @(
    [pscustomobject]@{
        Heading = 'FEAT-0047 - Clickable Cross-Record References'
        Title = 'Clickable Cross-Record References'
    },
    [pscustomobject]@{
        Heading = '2026-07-24 - v0.14.2 Clickable Cross-Record References'
        Title = 'Clickable Cross-Record References'
    }
)) {
    if (-not (Test-DocumentHeadingOwnsTitle `
            -Heading $ownHeadingFixture.Heading `
            -Title $ownHeadingFixture.Title)) {
        Add-Failure "TEST-0175 exact own-heading fixture was not recognized: '$($ownHeadingFixture.Heading)'."
    }
}
if (Test-DocumentHeadingOwnsTitle `
        -Heading 'Guide to Common Development Protocol' `
        -Title 'Common Development Protocol') {
    Add-Failure 'TEST-0175 a heading that merely contains another document title was treated as that document identity.'
}
if (-not (Test-DocumentTitleIsOwnIdentity `
        -SourcePath 'docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md' `
        -Title 'Clickable Cross-Record References') -or
    (Test-DocumentTitleIsOwnIdentity `
        -SourcePath 'CHANGELOG.md' `
        -Title 'Clickable Cross-Record References')) {
    Add-Failure 'TEST-0175 exact own-document title identity was not distinguished from a cross-document title reference.'
}
foreach ($rangeFixture in @(
    [pscustomobject]@{
        Text = 'TEST-0163 through TEST-0168'
        Source = 'docs/features/FEAT-0043-v0134-case-safe-review-authority/test-cases.md'
    },
    [pscustomobject]@{
        Text = 'RISK-0190..0192'
        Source = '.ai/memory/log/2026-07-22-v0131-batched-instruction-graph-planning.md'
    },
    [pscustomobject]@{
        Text = 'RISK-0190..0191'
        Source = '.ai/memory/log/2026-07-22-v0131-batched-instruction-graph-planning.md'
    },
    [pscustomobject]@{
        Text = 'TEST-0022-TEST-0026'
        Source = 'CHANGELOG.md'
    },
    [pscustomobject]@{
        Text = 'TEST-0096 to TEST-0099'
        Source = 'CHANGELOG.md'
    }
)) {
    if (@(Get-CrossDocumentAggregateRanges `
        -RenderedReferenceText $rangeFixture.Text `
        -SourcePath $rangeFixture.Source).Count -ne 1) {
        Add-Failure "TEST-0175 aggregate-range fixture '$($rangeFixture.Text)' was not rejected."
    }
}
if (@(Get-CrossDocumentAggregateRanges `
    -RenderedReferenceText 'TEST-0167 through TEST-0168' `
    -SourcePath 'docs/features/FEAT-0043-v0134-case-safe-review-authority/test-cases.md').Count -ne 0) {
    Add-Failure 'TEST-0175 same-document adjacent identity fixture was rejected as a cross-document range.'
}
foreach ($adjacentListFixture in @(
    "SUBF-0089`n- SUBF-0090",
    "TEST-0176`n- TEST-0177"
)) {
    if (@(Get-CrossDocumentAggregateRanges `
        -RenderedReferenceText $adjacentListFixture `
        -SourcePath '.ai/memory/SESSION_HANDOFF.md').Count -ne 0) {
        Add-Failure 'TEST-0175 adjacent list items were treated as a cross-document aggregate range.'
    }
}
if (-not (Test-DocumentRecordLinkTarget `
    -SourcePath 'CHANGELOG.md' `
    -Target 'docs/features/FEAT-0032-general-capability-test-architecture/README.md' `
    -ExpectedTarget 'docs/features/FEAT-0032-general-capability-test-architecture/README.md')) {
    Add-Failure 'TEST-0175 exact-target fixture rejected a valid local record link.'
}
if (Test-DocumentRecordLinkTarget `
    -SourcePath 'CHANGELOG.md' `
    -Target 'docs/features/FEAT-0001-common-development-protocol/README.md' `
    -ExpectedTarget 'docs/features/FEAT-0032-general-capability-test-architecture/README.md') {
    Add-Failure 'TEST-0175 exact-target fixture accepted a wrong local record link.'
}
if (Test-DocumentRecordLinkTarget `
    -SourcePath 'CHANGELOG.md' `
    -Target 'https://github.com/hasanmanzak/meAndAI/issues/1' `
    -ExpectedTarget 'https://github.com/hasanmanzak/meAndAI/issues/110') {
    Add-Failure 'TEST-0175 exact-target fixture accepted a wrong GitHub record link.'
}
foreach ($absoluteRepositoryFixture in @(
    [pscustomobject]@{
        Kind = 'FEAT'
        Target = 'https://github.com/hasanmanzak/meAndAI/blob/main/' +
            'docs/features/FEAT-0032-general-capability-test-architecture/README.md'
        Expected =
            'docs/features/FEAT-0032-general-capability-test-architecture/README.md'
    },
    [pscustomobject]@{
        Kind = 'DEC'
        Target = 'https://github.com/hasanmanzak/meAndAI/blob/main/' +
            'docs/decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md'
        Expected =
            'docs/decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md'
    }
)) {
    if (Test-DocumentRecordLinkTarget `
            -SourcePath 'CHANGELOG.md' `
            -Target $absoluteRepositoryFixture.Target `
            -ExpectedTarget $absoluteRepositoryFixture.Expected) {
        Add-Failure "TEST-0177 same-repository absolute $($absoluteRepositoryFixture.Kind) fixture was accepted as a current canonical record link."
    }
}
foreach ($embeddedAnchorId in @(
    'TEST-9991', 'SUBF-9991', 'FIND-9991', 'RISK-9991'
)) {
    $embeddedAnchorName = $embeddedAnchorId.ToLowerInvariant()
    $embeddedAnchorDeclaration =
        "| ``$embeddedAnchorId`` <a name=`"$embeddedAnchorName`"></a> | fixture |"
    $embeddedAnchorProblems = @(Get-EmbeddedRecordAnchorProblems `
        -Id $embeddedAnchorId -Markdown $embeddedAnchorDeclaration `
        -DeclarationText $embeddedAnchorDeclaration)
    $embeddedAnchors = Get-MarkdownAnchors `
        -Markdown $embeddedAnchorDeclaration
    if ($embeddedAnchorProblems.Count -ne 0 -or
        -not $embeddedAnchors.Contains($embeddedAnchorName)) {
        Add-Failure "TEST-0177 canonical $embeddedAnchorId custom-anchor fixture was not accepted."
    }
}
$canonicalAnchorDeclaration =
    '| `TEST-9991` <a name="test-9991"></a> | fixture |'
foreach ($anchorProblemFixture in @(
    [pscustomobject]@{
        Name = 'missing'; Declaration = '| `TEST-9991` | fixture |'
        Markdown = '| `TEST-9991` | fixture |'; Expected = 'Missing'
    },
    [pscustomobject]@{
        Name = 'wrong';
        Declaration = '| `TEST-9991` <a name="test-9992"></a> | fixture |'
        Markdown = '| `TEST-9991` <a name="test-9992"></a> | fixture |'
        Expected = 'Wrong'
    },
    [pscustomobject]@{
        Name = 'misplaced'; Declaration = '| `TEST-9991` | fixture |'
        Markdown = 'Extra <a name="test-9991"></a> anchor.' + "`n`n" +
            '| `TEST-9991` | fixture |'
        Expected = 'Wrong'
    },
    [pscustomobject]@{
        Name = 'duplicate'; Declaration = $canonicalAnchorDeclaration
        Markdown = "$canonicalAnchorDeclaration`n" +
            'Extra <a name="test-9991"></a> anchor.'
        Expected = 'Duplicate'
    },
    [pscustomobject]@{
        Name = 'non-lowercase'
        Declaration = '| `TEST-9991` <a name="TEST-9991"></a> | fixture |'
        Markdown = '| `TEST-9991` <a name="TEST-9991"></a> | fixture |'
        Expected = 'Wrong,WrongCase'
    },
    [pscustomobject]@{
        Name = 'case-colliding'; Declaration = $canonicalAnchorDeclaration
        Markdown = "$canonicalAnchorDeclaration`n" +
            'Extra <a name="TEST-9991"></a> anchor.'
        Expected = 'CaseCollision'
    },
    [pscustomobject]@{
        Name = 'inline-code';
        Declaration = '| `TEST-9991` ``<a name="test-9991"></a>`` | fixture |'
        Markdown = '| `TEST-9991` ``<a name="test-9991"></a>`` | fixture |'
        Expected = 'Missing'
    },
    [pscustomobject]@{
        Name = 'HTML-comment';
        Declaration = '| `TEST-9991` <!-- <a name="test-9991"></a> --> | fixture |'
        Markdown = '| `TEST-9991` <!-- <a name="test-9991"></a> --> | fixture |'
        Expected = 'Missing'
    },
    [pscustomobject]@{
        Name = 'fenced-code'; Declaration = '| `TEST-9991` | fixture |'
        Markdown = '| `TEST-9991` | fixture |' + "`n`n" +
            '```html' + "`n" + '<a name="test-9991"></a>' +
            "`n" + '```'
        Expected = 'Missing'
    },
    [pscustomobject]@{
        Name = 'non-rendering HTML'
        Declaration = '| `TEST-9991` | fixture |'
        Markdown = '| `TEST-9991` | fixture |' + "`n`n" +
            '<script><a name="test-9991"></a></script>'
        Expected = 'Missing'
    }
)) {
    $actualProblems = @(Get-EmbeddedRecordAnchorProblems `
        -Id 'TEST-9991' -Markdown $anchorProblemFixture.Markdown `
        -DeclarationText $anchorProblemFixture.Declaration | Sort-Object)
    if (($actualProblems -join ',') -cne $anchorProblemFixture.Expected) {
        Add-Failure "TEST-0177 $($anchorProblemFixture.Name) embedded-record anchor fixture was misclassified."
    }
}
$duplicateDeclarationFixturePath =
    'docs/features/FEAT-9991-fixture/test-cases.md'
$duplicateDeclarationFixtureDeclaration =
    '| `TEST-9991` <a name="test-9991"></a> | fixture |'
foreach ($duplicateDeclarationFixture in @(
    [pscustomobject]@{
        Name = 'linked secondary'
        Markdown = $duplicateDeclarationFixtureDeclaration + "`n" +
            '| [TEST-9991](#test-9991) | linked secondary |'
        ExpectedDuplicate = $false
    },
    [pscustomobject]@{
        Name = 'plain secondary declaration'
        Markdown = $duplicateDeclarationFixtureDeclaration + "`n" +
            '| `TEST-9991` | plain secondary |'
        ExpectedDuplicate = $true
    },
    [pscustomobject]@{
        Name = 'linked secondary heading'
        Markdown = $duplicateDeclarationFixtureDeclaration + "`n`n" +
            '## [TEST-9991](#test-9991) - linked secondary'
        ExpectedDuplicate = $false
    },
    [pscustomobject]@{
        Name = 'plain secondary heading'
        Markdown = $duplicateDeclarationFixtureDeclaration + "`n`n" +
            '## TEST-9991 - plain secondary'
        ExpectedDuplicate = $true
    }
)) {
    $fixtureDeclarationKeys =
        [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )
    $duplicateDetected = $false
    $fixtureDeclarations = @([regex]::Matches(
            [string]$duplicateDeclarationFixture.Markdown,
            $embeddedTestTableRecordDeclarationPattern
        )) + @([regex]::Matches(
            [string]$duplicateDeclarationFixture.Markdown,
            $embeddedHeadingRecordDeclarationPattern
        ))
    foreach ($fixtureDeclaration in $fixtureDeclarations) {
        if (-not (Add-EmbeddedRecordDeclarationKey `
                -Registry $fixtureDeclarationKeys `
                -Id $fixtureDeclaration.Groups['id'].Value `
                -Path $duplicateDeclarationFixturePath)) {
            $duplicateDetected = $true
        }
    }
    if ($duplicateDetected -ne
        [bool]$duplicateDeclarationFixture.ExpectedDuplicate) {
        Add-Failure "TEST-0177 $($duplicateDeclarationFixture.Name) declaration fixture was misclassified."
    }
}
if (-not (Test-DocumentRecordLinkTarget `
        -SourcePath $duplicateDeclarationFixturePath `
        -Target '#test-9991' `
        -ExpectedTarget "$duplicateDeclarationFixturePath#test-9991")) {
    Add-Failure 'TEST-0177 same-document linked secondary declaration fixture did not target its exact canonical fragment.'
}
$embeddedRecordTarget =
    'docs/features/FEAT-9991-fixture/test-cases.md#test-9991'
foreach ($fragmentFixture in @(
    [pscustomobject]@{ Target = $embeddedRecordTarget; Accepted = $true },
    [pscustomobject]@{
        Target = 'docs/features/FEAT-9991-fixture/test-cases.md'
        Accepted = $false
    },
    [pscustomobject]@{
        Target = 'docs/features/FEAT-9991-fixture/test-cases.md#test-9992'
        Accepted = $false
    },
    [pscustomobject]@{
        Target = 'docs/features/FEAT-9991-fixture/test-cases.md#TEST-9991'
        Accepted = $false
    },
    [pscustomobject]@{
        Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
            'abcdef0123456789abcdef0123456789abcdef01/' +
            'docs/features/FEAT-9991-fixture/test-cases.md#test-9991'
        Accepted = $false
    }
)) {
    $fragmentAccepted = Test-DocumentRecordLinkTarget `
        -SourcePath 'CHANGELOG.md' -Target $fragmentFixture.Target `
        -ExpectedTarget $embeddedRecordTarget
    if ($fragmentAccepted -ne [bool]$fragmentFixture.Accepted) {
        Add-Failure "TEST-0177 embedded-record fragment fixture '$($fragmentFixture.Target)' was misclassified."
    }
}
foreach ($numberFixture in @(
    'issue 110', 'Issue #110', 'issue #110', 'PR 113', 'pull request #113'
)) {
    if (@([regex]::Matches($numberFixture, $githubNumberPattern)).Count -ne 1) {
        Add-Failure "TEST-0175 free-text GitHub-number fixture was not detected: '$numberFixture'."
    }
}
$parentIssueCommentStatus = Get-DocumentCommentLinkStatus `
    -Label 'issue #114 comment' `
    -Target 'https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103'
if (-not $parentIssueCommentStatus.IsReference -or
    -not $parentIssueCommentStatus.Target.Success -or
    $parentIssueCommentStatus.LabelId.Success -or
    -not $parentIssueCommentStatus.Parent.Success -or
    $parentIssueCommentStatus.Parent.Groups['number'].Value -cne '114') {
    Add-Failure 'TEST-0175 valid parent-issue comment label was not accepted as an exact permalink.'
}
$wrongParentCommentStatus = Get-DocumentCommentLinkStatus `
    -Label 'issue #99 comment' `
    -Target 'https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103'
if (-not $wrongParentCommentStatus.Target.Success -or
    -not $wrongParentCommentStatus.Parent.Success -or
    ($wrongParentCommentStatus.Target.Groups['parentNumber'].Value -ceq
        $wrongParentCommentStatus.Parent.Groups['number'].Value)) {
    Add-Failure 'TEST-0175 wrong parent-issue comment label bypassed exact-parent validation.'
}
$artifactLabelCommentStatus = Get-DocumentCommentLinkStatus `
    -Label 'issue #114' `
    -Target 'https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103'
$artifactNumericLabel = [regex]::Match(
    'issue #114',
    '(?i)(?<![A-Za-z0-9_])(?:(?:issue|PR|pull request)\s+#?|#)[1-9][0-9]*(?![A-Za-z0-9_-])'
)
if (-not $artifactLabelCommentStatus.Target.Success -or
    -not $artifactNumericLabel.Success -or
    $artifactLabelCommentStatus.Parent.Success -or
    $artifactLabelCommentStatus.LabelId.Success) {
    Add-Failure 'TEST-0175 an issue-number label targeting a comment was not classified as a target-kind mismatch.'
}
if (Test-DocumentRecordLinkTarget `
        -SourcePath 'CHANGELOG.md' `
        -Target 'https://github.com/hasanmanzak/meAndAI/issues/114#issuecomment-5065074103' `
        -ExpectedTarget 'https://github.com/hasanmanzak/meAndAI/issues/114') {
    Add-Failure 'TEST-0175 a stable issue identity incorrectly accepted a comment permalink as its exact target.'
}
foreach ($invalidCommentFixture in @(
    [pscustomobject]@{
        Label = 'comment'
        Target = 'https://github.com/hasanmanzak/meAndAI/issues/114'
    },
    [pscustomobject]@{
        Label = 'review #123'
        Target = 'https://github.com/hasanmanzak/meAndAI/pull/114'
    },
    [pscustomobject]@{
        Label = 'inline review #456'
        Target = 'https://github.com/hasanmanzak/meAndAI/pull/114'
    }
)) {
    $invalidCommentStatus = Get-DocumentCommentLinkStatus `
        -Label $invalidCommentFixture.Label `
        -Target $invalidCommentFixture.Target
    if (-not $invalidCommentStatus.IsReference -or
        $invalidCommentStatus.Target.Success) {
        Add-Failure "TEST-0175 non-permalink comment fixture bypassed validation: '$($invalidCommentFixture.Label)'."
    }
}
$wrongTitleFixture = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[See Clickable Cross-Record References](PROTOCOL.md)' `
    -Path '<wrong-title-target-fixture>'
$wrongTitleMatches = @([regex]::Matches(
    [string]$wrongTitleFixture.Links[0].Label,
    $documentTitleLinkPattern
))
if (@($wrongTitleFixture.Links).Count -ne 1 -or
    $wrongTitleMatches.Count -ne 1 -or
    (Test-DocumentRecordLinkTarget `
        -SourcePath 'CHANGELOG.md' `
        -Target ([string]$wrongTitleFixture.Links[0].Target) `
        -ExpectedTarget 'docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md')) {
    Add-Failure 'TEST-0175 contextual document-title fixture bypassed exact-target validation.'
}
$wrongOrdinaryTitleFixture = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[read the Common Development Protocol](README.md)' `
    -Path '<wrong-ordinary-title-target-fixture>'
$wrongOrdinaryTitleMatches = @([regex]::Matches(
    [string]$wrongOrdinaryTitleFixture.Links[0].Label,
    $documentTitleLinkPattern
))
if (@($wrongOrdinaryTitleFixture.Links).Count -ne 1 -or
    $wrongOrdinaryTitleMatches.Count -ne 1 -or
    (Test-DocumentRecordLinkTarget `
        -SourcePath 'CHANGELOG.md' `
        -Target ([string]$wrongOrdinaryTitleFixture.Links[0].Target) `
        -ExpectedTarget 'PROTOCOL.md')) {
    Add-Failure 'TEST-0175 ordinary document-title fixture bypassed exact-target validation.'
}
$referenceStyleFixture = @"
[See FEAT-0032 architecture][feature]

[feature]: docs/features/FEAT-0032-general-capability-test-architecture/README.md
"@
$referenceStyleEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $referenceStyleFixture -Path '<reference-style-fixture>'
if (@($referenceStyleEvidence.Links).Count -ne 1 -or
    $referenceStyleEvidence.Links[0].Style -cne 'Reference' -or
    -not (Test-DocumentRecordLinkTarget -SourcePath 'CHANGELOG.md' `
        -Target ([string]$referenceStyleEvidence.Links[0].Target) `
        -ExpectedTarget 'docs/features/FEAT-0032-general-capability-test-architecture/README.md')) {
    Add-Failure 'TEST-0175 valid reference-style Markdown fixture did not resolve to its exact target.'
}
if (-not (Test-DocumentResolvedTargetExists `
        -SourcePath 'CHANGELOG.md' `
        -Target 'docs/features/FEAT-0032-general-capability-test-architecture/README.md') -or
    (Test-DocumentResolvedTargetExists `
        -SourcePath 'CHANGELOG.md' `
        -Target 'docs/features/FEAT-9999-missing/README.md')) {
    Add-Failure 'TEST-0175 broken generic reference-style target fixture did not fail closed.'
}
$genericFragmentFixture = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[protocol section](PROTOCOL.md#Common-development-protocol)' `
    -Path '<generic-wrong-case-fragment-fixture>'
if (@($genericFragmentFixture.Links).Count -ne 1 -or
    (Test-DocumentResolvedTargetExists `
        -SourcePath 'CHANGELOG.md' `
        -Target ([string]$genericFragmentFixture.Links[0].Target))) {
    Add-Failure 'TEST-0175 generic-label wrong-case relative Markdown fragment fixture did not fail closed.'
}
$unresolvedReferenceFixture = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[guide][missing-guide]' `
    -Path '<unresolved-reference-style-fixture>'
if (@($unresolvedReferenceFixture.Links).Count -ne 0 -or
    @($unresolvedReferenceFixture.Unresolved).Count -ne 1 -or
    $unresolvedReferenceFixture.Unresolved[0].Key -cne 'missing-guide') {
    Add-Failure 'TEST-0175 unresolved reference-style usage fixture did not fail closed.'
}
$codeLiteralMarkdown = @'
``[string][int] [label][key] [x](y)``

~~~text
[string][int] [label][key] [x](y)
~~~

    [string][int] [label][key] [x](y)
'@
$codeLiteralEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $codeLiteralMarkdown `
    -Path '<code-literal-fixture>'
if (@($codeLiteralEvidence.Links).Count -ne 0 -or
    @($codeLiteralEvidence.Unresolved).Count -ne 0 -or
    @($codeLiteralEvidence.CodeSpans).Count -ne 3) {
    Add-Failure 'TEST-0175 a non-reference code literal was parsed as Markdown link evidence.'
}
$codePseudoLinkMarkdown = @'
``[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)``

~~~text
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
~~~
'@
$codePseudoLinkEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $codePseudoLinkMarkdown `
    -Path '<code-pseudo-link-fixture>'
if (@($codePseudoLinkEvidence.Links).Count -ne 0 -or
    @($codePseudoLinkEvidence.CodeSpans).Count -ne 2 -or
    @($codePseudoLinkEvidence.CodeSpans | Where-Object {
        [regex]::IsMatch([string]$_.Content, $recordIdPattern)
    }).Count -ne 2) {
    Add-Failure 'TEST-0175 multi-backtick or tilde-fenced cross-record pseudo-link bypassed code classification.'
}
$contextualCodePseudoLinks = @'
   ```md
   [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
   ```

> ```md
> [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
> ```

- ```md
  [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
  ```

`[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
continued`
'@
$contextualCodeEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $contextualCodePseudoLinks `
    -Path '<contextual-code-pseudo-link-fixture>'
if (@($contextualCodeEvidence.Links).Count -ne 0 -or
    @($contextualCodeEvidence.CodeSpans).Count -ne 4 -or
    @($contextualCodeEvidence.CodeSpans | Where-Object {
        [regex]::IsMatch([string]$_.Content, $recordIdPattern)
    }).Count -ne 4) {
    Add-Failure 'TEST-0175 spaced, quoted, list-contained, or multiline-inline code pseudo-link bypassed code classification.'
}
$documentPseudoLinkMarkdown = '``[guide](docs/guide.md)``'
$documentPseudoLinkEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $documentPseudoLinkMarkdown `
    -Path '<document-pseudo-link-fixture>'
if (@($documentPseudoLinkEvidence.Links).Count -ne 0 -or
    @($documentPseudoLinkEvidence.CodeSpans).Count -ne 1 -or
    -not [regex]::IsMatch(
        [string]$documentPseudoLinkEvidence.CodeSpans[0].Content,
        '(?i)(?<!\!)\[[^\]]+\]\([^)\s]+\.md\)'
    )) {
    Add-Failure 'TEST-0175 a standalone code-formatted repository-document pseudo-link bypassed classification.'
}
$indentedPseudoLinkMarkdown = @'
Paragraph.

    [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
'@
$indentedPseudoLinkEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $indentedPseudoLinkMarkdown `
    -Path '<indented-pseudo-link-fixture>'
if (@($indentedPseudoLinkEvidence.Links).Count -ne 0 -or
    @($indentedPseudoLinkEvidence.CodeSpans).Count -ne 1 -or
    $indentedPseudoLinkEvidence.CodeSpans[0].Kind -cne 'Indented' -or
    -not [regex]::IsMatch(
        [string]$indentedPseudoLinkEvidence.CodeSpans[0].Content,
        $recordIdPattern
    )) {
    Add-Failure 'TEST-0175 an indented-code cross-record pseudo-link bypassed code classification.'
}
foreach ($containerIndentedMarkdown in @(
    '>     [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)',
    '-     [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)'
)) {
    $containerIndentedEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $containerIndentedMarkdown `
        -Path '<container-indented-pseudo-link-fixture>'
    if (@($containerIndentedEvidence.Links).Count -ne 0 -or
        @($containerIndentedEvidence.CodeSpans).Count -ne 1 -or
        $containerIndentedEvidence.CodeSpans[0].Kind -cne 'Indented' -or
        -not [regex]::IsMatch(
            [string]$containerIndentedEvidence.CodeSpans[0].Content,
            $recordIdPattern
        )) {
        Add-Failure 'TEST-0175 a blockquote- or list-contained indented-code cross-record pseudo-link bypassed classification.'
    }
}
$escapedLinkFixtures = @(
    '\[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)',
    '\\\[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)',
    "\[FEAT-0032][feature]`n`n[feature]: docs/features/FEAT-0032-general-capability-test-architecture/README.md",
    "\[FEAT-0032]`n`n[FEAT-0032]: docs/features/FEAT-0032-general-capability-test-architecture/README.md"
)
foreach ($escapedLinkFixture in $escapedLinkFixtures) {
    $escapedLinkEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $escapedLinkFixture `
        -Path '<escaped-link-fixture>'
    if (@($escapedLinkEvidence.Links).Count -ne 0) {
        Add-Failure 'TEST-0175 an odd-parity backslash-escaped pseudo-link was treated as clickable Markdown evidence.'
    }
}
$evenEscapeEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '\\[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)' `
    -Path '<even-escape-link-fixture>'
if (@($evenEscapeEvidence.Links).Count -ne 1) {
    Add-Failure 'TEST-0175 an even-parity backslash prefix incorrectly escaped a clickable Markdown link.'
}
$codeTitleMarkdown = 'See `Common Development Protocol` for context.'
$codeTitleEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $codeTitleMarkdown -Path '<code-title-fixture>'
if (@($codeTitleEvidence.CodeSpans).Count -ne 1 -or
    @(
        Get-CodeFormattedDocumentTitleReferences `
            -Markdown $codeTitleMarkdown `
            -CodeSpan $codeTitleEvidence.CodeSpans[0] `
            -Titles @('Common Development Protocol')
    ).Count -ne 1) {
    Add-Failure 'TEST-0175 a code-formatted known document-title reference bypassed classification.'
}
$hiddenReferenceEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '<!-- [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md) pr-42 -->' `
    -Path '<hidden-reference-fixture>'
if (@($hiddenReferenceEvidence.Links).Count -ne 0 -or
    @($hiddenReferenceEvidence.HtmlComments).Count -ne 1 -or
    -not [regex]::IsMatch(
        [string]$hiddenReferenceEvidence.HtmlComments[0].Value,
        $hiddenCrossRecordReferencePattern
    )) {
    Add-Failure 'TEST-0175 a hidden HTML-comment cross-record reference bypassed non-clickable classification.'
}
$rawHtmlHrefMarkdown = '<a href="docs/features/FEAT-0032-general-capability-test-architecture/README.md">FEAT-0032</a>'
$rawHtmlHrefEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $rawHtmlHrefMarkdown -Path '<raw-html-href-fixture>'
$rawHtmlHrefRendered = Get-DocumentRenderedReferenceEvidence `
    -Markdown $rawHtmlHrefMarkdown -LinkEvidence $rawHtmlHrefEvidence
$rawHtmlHrefId = [regex]::Match(
    [string]$rawHtmlHrefRendered.Text,
    $recordIdPattern
)
if (@($rawHtmlHrefEvidence.Links).Count -ne 0 -or
    -not $rawHtmlHrefId.Success -or
    (Test-DocumentRenderedReferenceCoveredByLink `
        -Index $rawHtmlHrefId.Index -Length $rawHtmlHrefId.Length `
        -RenderedEvidence $rawHtmlHrefRendered)) {
    Add-Failure 'TEST-0175 a raw HTML href was accepted as a governed clickable-reference authoring form.'
}
$benignCommentEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '<!-- lifecycle:v2:digest-abcdef -->' `
    -Path '<benign-html-comment-fixture>'
if (@($benignCommentEvidence.HtmlComments).Count -ne 1 -or
    [regex]::IsMatch(
        [string]$benignCommentEvidence.HtmlComments[0].Value,
        $hiddenCrossRecordReferencePattern
    )) {
    Add-Failure 'TEST-0175 a non-referential lifecycle marker was treated as a cross-record reference.'
}
$nonRenderingHtmlEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '<pre>[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)</pre>' `
    -Path '<non-rendering-html-fixture>'
if (@($nonRenderingHtmlEvidence.Links).Count -ne 0 -or
    @($nonRenderingHtmlEvidence.NonRenderingHtml).Count -ne 1 -or
    -not [regex]::IsMatch(
        [string]$nonRenderingHtmlEvidence.NonRenderingHtml[0].Value,
        $recordIdPattern
    )) {
    Add-Failure 'TEST-0175 a pseudo-link inside non-rendering HTML bypassed classification.'
}
$nonRenderingBlockHtml = @'
<table>
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
</table>
'@
$nonRenderingBlockHtmlEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $nonRenderingBlockHtml `
    -Path '<non-rendering-block-html-fixture>'
if (@($nonRenderingBlockHtmlEvidence.Links).Count -ne 0 -or
    @($nonRenderingBlockHtmlEvidence.NonRenderingHtml).Count -ne 1 -or
    -not [regex]::IsMatch(
        [string]$nonRenderingBlockHtmlEvidence.NonRenderingHtml[0].Value,
        $recordIdPattern
    )) {
    Add-Failure 'TEST-0175 a pseudo-link inside a block HTML tag bypassed classification.'
}
$containerHtmlFixtures = @(
    @'
> <x-panel>
> [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
> </x-panel>
'@,
    @'
- <div>
  [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
  </div>
'@,
    @'
> <?process
> [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
> ?>
'@,
    @'
- <!DECLARATION
  [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
  >
'@,
    @'
> <![CDATA[
> [FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
> ]]>
'@
)
foreach ($containerHtmlFixture in $containerHtmlFixtures) {
    $containerHtmlEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $containerHtmlFixture `
        -Path '<container-html-fixture>'
    if (@($containerHtmlEvidence.Links).Count -ne 0 -or
        @($containerHtmlEvidence.NonRenderingHtml).Count -ne 1 -or
        -not [regex]::IsMatch(
            [string]$containerHtmlEvidence.NonRenderingHtml[0].Value,
            $recordIdPattern
        )) {
        Add-Failure 'TEST-0175 a blockquote- or list-contained raw HTML cross-record pseudo-link bypassed classification.'
    }
}
foreach ($nonRenderingHtmlFixture in @(
    @'
<x-panel>
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
</x-panel>
'@,
    @'
<x-panel title=">">
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
</x-panel>
'@,
    @'
<?process
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
?>
'@,
    @'
<![CDATA[
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
]]>
'@,
    @'
<!DECLARATION
[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)
>
'@
)) {
    $remainingHtmlEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $nonRenderingHtmlFixture `
        -Path '<remaining-non-rendering-html-fixture>'
    if (@($remainingHtmlEvidence.Links).Count -ne 0 -or
        @($remainingHtmlEvidence.NonRenderingHtml).Count -ne 1 -or
        -not [regex]::IsMatch(
            [string]$remainingHtmlEvidence.NonRenderingHtml[0].Value,
            $recordIdPattern
        )) {
        Add-Failure 'TEST-0175 a type 3, 4, 5, or 7 HTML-block pseudo-link bypassed classification.'
    }
}
$renderedReferenceFixtures = @(
    'FEAT\-0032',
    'FEAT&#45;0032'
)
foreach ($renderedReferenceFixture in $renderedReferenceFixtures) {
    $normalizedReference = ConvertTo-DocumentMarkdownRenderedText `
        -Text $renderedReferenceFixture
    if (-not [regex]::IsMatch($normalizedReference, $recordIdPattern)) {
        Add-Failure "TEST-0175 rendered stable-ID fixture bypassed normalization: '$renderedReferenceFixture'."
    }
}
$escapedNumberReference = ConvertTo-DocumentMarkdownRenderedText `
    -Text 'issue \#110'
if (@([regex]::Matches(
        $escapedNumberReference,
        $githubNumberPattern
    )).Count -ne 1) {
    Add-Failure 'TEST-0175 a Markdown-escaped issue number bypassed rendered-text normalization.'
}
$encodedWrongLabelEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[FEAT&#45;0032](docs/features/FEAT-0001-common-development-protocol/README.md)' `
    -Path '<encoded-wrong-label-fixture>'
$encodedWrongLabel = ConvertTo-DocumentMarkdownRenderedText `
    -Text ([string]$encodedWrongLabelEvidence.Links[0].Label)
if (@($encodedWrongLabelEvidence.Links).Count -ne 1 -or
    -not [regex]::IsMatch($encodedWrongLabel, $recordIdPattern) -or
    (Test-DocumentRecordLinkTarget -SourcePath 'CHANGELOG.md' `
        -Target ([string]$encodedWrongLabelEvidence.Links[0].Target) `
        -ExpectedTarget 'docs/features/FEAT-0032-general-capability-test-architecture/README.md')) {
    Add-Failure 'TEST-0175 an HTML-entity record label bypassed exact-target classification.'
}
$escapedWrongLabelEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[FEAT\-0032](docs/features/FEAT-0001-common-development-protocol/README.md)' `
    -Path '<escaped-wrong-label-fixture>'
$escapedWrongLabel = ConvertTo-DocumentMarkdownRenderedText `
    -Text ([string]$escapedWrongLabelEvidence.Links[0].Label)
if (@($escapedWrongLabelEvidence.Links).Count -ne 1 -or
    -not [regex]::IsMatch($escapedWrongLabel, $recordIdPattern)) {
    Add-Failure 'TEST-0175 a Markdown-escaped record label bypassed exact-target classification.'
}
$currentCommitOutput = @(& git -C $root rev-parse --verify HEAD 2>&1)
$currentCommitExitCode = $LASTEXITCODE
$currentCommit = ($currentCommitOutput -join '').Trim()
if ($currentCommitExitCode -ne 0 -or
    $currentCommit -cnotmatch '^[0-9a-f]{40}$') {
    Add-Failure 'TEST-0177 historical snapshot fixtures could not resolve the current local commit.'
}
else {
    $missingHistoricalPath =
        'docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md'
    $introductionCommitOutput = @(
        & git -C $root log -1 --format=%H --diff-filter=A -- `
            $missingHistoricalPath 2>&1
    )
    $introductionCommitExitCode = $LASTEXITCODE
    $introductionCommit = ($introductionCommitOutput -join '').Trim()
    $preIntroductionCommitOutput = @()
    $preIntroductionCommitExitCode = -1
    if ($introductionCommitExitCode -eq 0 -and
        $introductionCommit -cmatch '^[0-9a-f]{40}$') {
        $preIntroductionCommitOutput = @(
            & git -C $root rev-parse --verify "$introductionCommit^" 2>&1
        )
        $preIntroductionCommitExitCode = $LASTEXITCODE
    }
    $preIntroductionCommit =
        ($preIntroductionCommitOutput -join '').Trim()
    if ($preIntroductionCommitExitCode -ne 0 -or
        $preIntroductionCommit -cnotmatch '^[0-9a-f]{40}$') {
        Add-Failure 'TEST-0177 missing historical path fixture could not resolve the feature pre-introduction commit.'
    }
    $deletedHistoricalPath = 'tests/v092-live-pin-migration.tests.ps1'
    $deletionCommitOutput = @(
        & git -C $root log --all --full-history -1 --format=%H `
            --diff-filter=D -- `
            $deletedHistoricalPath 2>&1
    )
    $deletionCommitExitCode = $LASTEXITCODE
    $deletionCommit = ($deletionCommitOutput -join '').Trim()
    $deletedPathCommitOutput = @()
    $deletedPathCommitExitCode = -1
    if ($deletionCommitExitCode -eq 0 -and
        $deletionCommit -cmatch '^[0-9a-f]{40}$') {
        $deletedPathCommitOutput = @(
            & git -C $root rev-parse --verify "$deletionCommit^" 2>&1
        )
        $deletedPathCommitExitCode = $LASTEXITCODE
    }
    $deletedPathCommit = ($deletedPathCommitOutput -join '').Trim()
    if ($trackedRepositoryPathSet.Contains($deletedHistoricalPath) -or
        $deletedPathCommitExitCode -ne 0 -or
        $deletedPathCommit -cnotmatch '^[0-9a-f]{40}$') {
        Add-Failure 'TEST-0177 deleted historical path fixture precondition failed.'
    }
    $nonMarkdownFixturePath =
        'scripts/Build-MeAndAIQuickAdoptionBundle.ps1'
    if (-not $trackedRepositoryPathSet.Contains($nonMarkdownFixturePath)) {
        Add-Failure 'TEST-0177 non-Markdown repository-target fixture path is not tracked.'
    }
    $historicalTargetFixtures = @(
        [pscustomobject]@{
            Name = 'verified tag root'
            Target = 'https://github.com/hasanmanzak/meAndAI/tree/v0.2.0'
            Rejected = $false
        },
        [pscustomobject]@{
            Name = 'tag tree with tracked file'
            Target = 'https://github.com/hasanmanzak/meAndAI/tree/' +
                'v0.2.0/PROTOCOL.md'
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'mutable branch'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/main/' +
                'PROTOCOL.md'
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'case-insensitive repository and kind'
            Target = 'https://github.com/HASANMANZAK/MEANDAI/BLOB/main/' +
                'PROTOCOL.md'
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'mutable non-Markdown branch target'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/main/' +
                $nonMarkdownFixturePath
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'slash-qualified mutable branch target'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                'codex/example/PROTOCOL.md'
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'tree full SHA'
            Target = 'https://github.com/hasanmanzak/meAndAI/tree/' +
                "$currentCommit/PROTOCOL.md"
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'uppercase full SHA'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$($currentCommit.ToUpperInvariant())/PROTOCOL.md"
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'unresolved full SHA'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$('0' * 40)/$nonMarkdownFixturePath"
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'untracked repository path'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/not-tracked.ps1"
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'verified historical blob'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/PROTOCOL.md"
            Rejected = $false
        },
        [pscustomobject]@{
            Name = 'verified historical fragment'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/PROTOCOL.md#common-development-protocol"
            Rejected = $false
        },
        [pscustomobject]@{
            Name = 'missing historical fragment'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/PROTOCOL.md#does-not-exist"
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'verified historical non-Markdown blob'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/$nonMarkdownFixturePath"
            Rejected = $false
        },
        [pscustomobject]@{
            Name = 'verified historical single line'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/$nonMarkdownFixturePath#L1"
            Rejected = $false
        },
        [pscustomobject]@{
            Name = 'verified historical line range'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/$nonMarkdownFixturePath#L1-L2"
            Rejected = $false
        },
        [pscustomobject]@{
            Name = 'out-of-range historical line'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/$nonMarkdownFixturePath#L999999"
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'malformed historical line range'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/$nonMarkdownFixturePath#L1-2"
            Rejected = $true
        }
    )
    if ($preIntroductionCommit -cmatch '^[0-9a-f]{40}$') {
        $historicalTargetFixtures += [pscustomobject]@{
            Name = 'path absent at historical commit'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$preIntroductionCommit/$missingHistoricalPath"
            Rejected = $true
        }
    }
    if ($deletedPathCommit -cmatch '^[0-9a-f]{40}$') {
        $historicalTargetFixtures += [pscustomobject]@{
            Name = 'historical path deleted at current HEAD'
            Target = 'https://github.com/hasanmanzak/meAndAI/blob/' +
                "$deletedPathCommit/$deletedHistoricalPath"
            Rejected = $false
        }
    }
    foreach ($historicalTargetFixture in $historicalTargetFixtures) {
        $fixtureEvidence = Get-DocumentMarkdownLinkEvidence `
            -Markdown "[Feature]($($historicalTargetFixture.Target))" `
            -Path '<same-repository-historical-target-fixture>'
        $actualRejected = @($fixtureEvidence.Links).Count -eq 1 -and
            (Test-DocumentNonCanonicalSameRepositoryTarget `
                -Target ([string]$fixtureEvidence.Links[0].Target) `
                -TrackedRepositoryPaths $trackedRepositoryPathSet)
        if (@($fixtureEvidence.Links).Count -ne 1 -or
            $actualRejected -ne [bool]$historicalTargetFixture.Rejected) {
            Add-Failure "TEST-0177 same-repository target fixture '$($historicalTargetFixture.Name)' was misclassified."
        }
    }
    foreach ($relativeLineFixture in @(
        [pscustomobject]@{
            Fragment = 'L1'; Accepted = $true
        },
        [pscustomobject]@{
            Fragment = 'L1-L2'; Accepted = $true
        },
        [pscustomobject]@{
            Fragment = 'L999999'; Accepted = $false
        },
        [pscustomobject]@{
            Fragment = 'L1-2'; Accepted = $false
        }
    )) {
        $relativeLineAccepted = Test-DocumentResolvedTargetExists `
            -SourcePath 'CHANGELOG.md' `
            -Target "$nonMarkdownFixturePath#$($relativeLineFixture.Fragment)"
        if ($relativeLineAccepted -ne [bool]$relativeLineFixture.Accepted) {
            Add-Failure "TEST-0177 current relative non-Markdown line fixture '$($relativeLineFixture.Fragment)' was misclassified."
        }
    }
    $validTextEvidence = Get-Utf8TextEvidence `
        -Bytes ([Text.Encoding]::UTF8.GetBytes("one`ntwo`n"))
    $invalidUtf8Evidence = Get-Utf8TextEvidence `
        -Bytes ([byte[]]@(0xFF, 0xFE, 0xFD))
    $binaryControlEvidence = Get-Utf8TextEvidence `
        -Bytes ([byte[]]@(0x61, 0x00, 0x62))
    if (-not $validTextEvidence.IsText -or
        $validTextEvidence.LineCount -ne 2 -or
        $invalidUtf8Evidence.IsText -or $binaryControlEvidence.IsText) {
        Add-Failure 'TEST-0177 UTF-8 text/blob classification fixtures were misclassified.'
    }
    foreach ($budgetFixture in @(
        [pscustomobject]@{
            Unique = 63; Aggregate = 0; Bytes = 1MB; Accepted = $true
        },
        [pscustomobject]@{
            Unique = 64; Aggregate = 0; Bytes = 1; Accepted = $false
        },
        [pscustomobject]@{
            Unique = 0; Aggregate = 0; Bytes = 1MB + 1; Accepted = $false
        },
        [pscustomobject]@{
            Unique = 0; Aggregate = 16MB - 1; Bytes = 2; Accepted = $false
        }
    )) {
        $withinBudget = Test-HistoricalBlobFetchWithinBudget `
            -UniqueCount $budgetFixture.Unique `
            -AggregateBytes $budgetFixture.Aggregate `
            -BlobBytes $budgetFixture.Bytes
        if ($withinBudget -ne [bool]$budgetFixture.Accepted) {
            Add-Failure 'TEST-0177 historical fragment fetch budget fixture was misclassified.'
        }
    }
    foreach ($repositoryAutolinkFixture in @(
        [pscustomobject]@{
            Name = 'mutable bare autolink'
            Markdown = 'https://github.com/hasanmanzak/meAndAI/blob/main/' +
                $nonMarkdownFixturePath
            Rejected = $true
        },
        [pscustomobject]@{
            Name = 'verified historical angle autolink with fragment'
            Markdown = '<https://github.com/hasanmanzak/meAndAI/blob/' +
                "$currentCommit/$nonMarkdownFixturePath#L1>"
            Rejected = $false
        }
    )) {
        $autolinkEvidence = Get-DocumentMarkdownLinkEvidence `
            -Markdown $repositoryAutolinkFixture.Markdown `
            -Path '<same-repository-autolink-fixture>'
        $activeAutolinks = @(
            Get-DocumentRendererActiveHttpAutolinkSpans `
                -Markdown $repositoryAutolinkFixture.Markdown `
                -LinkEvidence $autolinkEvidence
        )
        $actualRejected = $activeAutolinks.Count -eq 1 -and
            (Test-DocumentNonCanonicalSameRepositoryTarget `
                -Target ([string]$activeAutolinks[0].Value) `
                -TrackedRepositoryPaths $trackedRepositoryPathSet)
        if ($activeAutolinks.Count -ne 1 -or
            $actualRejected -ne [bool]$repositoryAutolinkFixture.Rejected) {
            Add-Failure "TEST-0177 same-repository autolink fixture '$($repositoryAutolinkFixture.Name)' was misclassified."
        }
    }
}
foreach ($presentationFixture in @(
    'FEAT-<em>0032</em>',
    'FEAT-<span title=''>''>0032</span>',
    'FEAT-**0032**',
    'FEAT-<!--x-->0032',
    'FEAT-`0032`',
    'issue **#110**'
)) {
    $normalizedPresentation = ConvertTo-DocumentMarkdownRenderedText `
        -Text $presentationFixture
    $detected = [regex]::IsMatch(
        $normalizedPresentation,
        $recordIdPattern
    ) -or [regex]::IsMatch(
        $normalizedPresentation,
        $githubNumberPattern
    )
    if (-not $detected) {
        Add-Failure "TEST-0175 inline HTML or presentation Markdown bypassed rendered-reference normalization: '$presentationFixture'."
    }
}
$formattedWrongLabelEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[FEAT-**0032**](docs/features/FEAT-0001-common-development-protocol/README.md)' `
    -Path '<formatted-wrong-label-fixture>'
$formattedWrongLabel = ConvertTo-DocumentMarkdownRenderedText `
    -Text ([string]$formattedWrongLabelEvidence.Links[0].Label)
if (@($formattedWrongLabelEvidence.Links).Count -ne 1 -or
    -not [regex]::IsMatch($formattedWrongLabel, $recordIdPattern)) {
    Add-Failure 'TEST-0175 a presentation-formatted record label bypassed exact-target classification.'
}
$splitStableIdMarkdown =
    'FEAT-[0032](docs/features/FEAT-0001-common-development-protocol/README.md)'
$splitStableIdEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $splitStableIdMarkdown -Path '<split-stable-id-fixture>'
$splitStableIdRendered = Get-DocumentRenderedReferenceEvidence `
    -Markdown $splitStableIdMarkdown -LinkEvidence $splitStableIdEvidence
$splitStableIdMatch = [regex]::Match(
    [string]$splitStableIdRendered.Text,
    $recordIdPattern
)
if (-not $splitStableIdMatch.Success -or
    (Test-DocumentRenderedReferenceCoveredByLink `
        -Index $splitStableIdMatch.Index -Length $splitStableIdMatch.Length `
        -RenderedEvidence $splitStableIdRendered)) {
    Add-Failure 'TEST-0175 a stable identifier assembled across a partial link bypassed rendered coverage.'
}
$splitIssueMarkdown =
    'issue [#110](https://github.com/hasanmanzak/meAndAI/issues/110)'
$splitIssueEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $splitIssueMarkdown -Path '<split-issue-number-fixture>'
$splitIssueRendered = Get-DocumentRenderedReferenceEvidence `
    -Markdown $splitIssueMarkdown -LinkEvidence $splitIssueEvidence
$splitIssueMatch = [regex]::Match(
    [string]$splitIssueRendered.Text,
    $githubNumberPattern
)
if (-not $splitIssueMatch.Success -or
    (Test-DocumentRenderedReferenceCoveredByLink `
        -Index $splitIssueMatch.Index -Length $splitIssueMatch.Length `
        -RenderedEvidence $splitIssueRendered)) {
    Add-Failure 'TEST-0175 a GitHub number assembled across a partial link bypassed rendered coverage.'
}
$visibleUrlWrongTarget = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[https://github.com/hasanmanzak/meAndAI/issues/42](https://github.com/evil/other/issues/99)' `
    -Path '<visible-url-wrong-target-fixture>'
if (@($visibleUrlWrongTarget.Links).Count -ne 1 -or
    [string]$visibleUrlWrongTarget.Links[0].Label -ceq
        [string]$visibleUrlWrongTarget.Links[0].Target) {
    Add-Failure 'TEST-0175 a visible GitHub URL wrong-target fixture was not classified.'
}
if (Test-DocumentVisiblePathMatchesLinkTarget `
        -SourcePath 'CHANGELOG.md' `
        -VisiblePath 'docs/adoption.md' `
        -Target 'PROTOCOL.md') {
    Add-Failure 'TEST-0175 a visible repository-document path accepted a different link target.'
}
$splitUrlFixtures = @(
    'https://github.com/hasanmanzak/meAndAI/issues/[42](https://github.com/evil/other/issues/99)',
    "https://github.com/hasanmanzak/meAndAI/issues/[42][wrong]`n`n[wrong]: https://github.com/evil/other/issues/99"
)
foreach ($splitUrlFixture in $splitUrlFixtures) {
    if (-not [regex]::IsMatch(
            $splitUrlFixture,
            '(?i)https?://[^\s\[\]<>()]*\[[^\]]+\](?:\([^)]+\)|[ \t]*\[[^\]]*\])[^\s<>()]*'
        )) {
        Add-Failure 'TEST-0175 a visible URL assembled across a partial inline or reference link bypassed classification.'
    }
}
$inlineMarkupUrlFixtures = @(
    'https://github.com/hasanmanzak/meAndAI/issues/<!-- -->42',
    'https://github.com/hasanmanzak/meAndAI/issues/<em>42</em>',
    'https<!-- -->://github.com/hasanmanzak/meAndAI/issues/42',
    'htt<em>ps</em>://github.com/hasanmanzak/meAndAI/issues/42',
    'https&#58;//github.com/hasanmanzak/meAndAI/issues/42',
    'https://github.com/hasanmanzak/meAndAI/issues/**42**',
    'https://github.com/hasanmanzak/meAndAI/issues/~~42~~',
    'https://github.com/hasanmanzak/meAndAI/issues/__42__',
    '&#104;ttps://github.com/hasanmanzak/meAndAI/issues/42',
    '&#x68;ttps://github.com/hasanmanzak/meAndAI/issues/42',
    'https://github.com/hasanmanzak/meAndAI/issues/<em>42</em>(https://github.com/hasanmanzak/meAndAI/issues/42)',
    'https<!-- -->://github.com/hasanmanzak/meAndAI/issues/42(https://github.com/hasanmanzak/meAndAI/issues/42)',
    'https://github.com/hasanmanzak/meAndAI/issues/**42**(https://github.com/hasanmanzak/meAndAI/issues/42)',
    'xhttps://github.com/hasanmanzak/meAndAI/issues/42',
    '-https://github.com/hasanmanzak/meAndAI/issues/42',
    ']https://github.com/hasanmanzak/meAndAI/issues/42',
    'https://localhost/doc.md',
    'https://example/doc.md',
    'https://foo.example_com/doc.md'
)
foreach ($inlineMarkupUrlFixture in $inlineMarkupUrlFixtures) {
    $inlineMarkupUrlEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $inlineMarkupUrlFixture `
        -Path '<inline-markup-url-fixture>'
    $inlineMarkupRenderedEvidence = Get-DocumentRenderedReferenceEvidence `
        -Markdown $inlineMarkupUrlFixture `
        -LinkEvidence $inlineMarkupUrlEvidence
    $inlineMarkupRenderedUrls = @([regex]::Matches(
        [string]$inlineMarkupRenderedEvidence.Text,
        '(?i)https?://[^\s<>()\[\]{}"''`]+'
    ))
    if ($inlineMarkupRenderedUrls.Count -eq 0 -or
        @($inlineMarkupRenderedUrls | Where-Object {
            Test-DocumentRenderedReferenceCoveredByLink `
                -Index $_.Index -Length $_.Length `
                -RenderedEvidence $inlineMarkupRenderedEvidence
        }).Count -ne 0) {
        Add-Failure 'TEST-0175 a visible URL assembled across inline markup bypassed rendered-link classification.'
    }
}
$exactVisibleUrlMarkdown = '[https://github.com/hasanmanzak/meAndAI/issues/42](https://github.com/hasanmanzak/meAndAI/issues/42)'
$exactVisibleUrlEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $exactVisibleUrlMarkdown `
    -Path '<exact-visible-url-link-fixture>'
$exactVisibleUrlRendered = Get-DocumentRenderedReferenceEvidence `
    -Markdown $exactVisibleUrlMarkdown -LinkEvidence $exactVisibleUrlEvidence
$exactVisibleUrlMatch = [regex]::Match(
    [string]$exactVisibleUrlRendered.Text,
    '(?i)https?://[^\s<>()\[\]{}"''`]+'
)
if (-not $exactVisibleUrlMatch.Success -or
    -not (Test-DocumentRenderedReferenceCoveredByLink `
        -Index $exactVisibleUrlMatch.Index `
        -Length $exactVisibleUrlMatch.Length `
        -RenderedEvidence $exactVisibleUrlRendered)) {
    Add-Failure 'TEST-0175 an exact visible-URL link was not preserved as one clickable rendered reference.'
}
foreach ($validSpecialCharacterAutolink in @(
    '<https://example.com/~user/doc.md>',
    '<https://github.com/hasanmanzak/meAndAI/blob/abcdef0123456789abcdef0123456789abcdef01/__init__.md>',
    'https://example.com/foo__bar.md',
    'https://example.com/doc.md?x=a*b'
)) {
    $specialAutolinkEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $validSpecialCharacterAutolink `
        -Path '<special-character-autolink-fixture>'
    $specialAutolinkRendered = Get-DocumentRenderedReferenceEvidence `
        -Markdown $validSpecialCharacterAutolink `
        -LinkEvidence $specialAutolinkEvidence
    if ([regex]::IsMatch(
            [string]$specialAutolinkRendered.Text,
            '(?i)https?://'
        )) {
        Add-Failure 'TEST-0175 a valid special-character bare or angle autolink was not suppressed as clickable evidence.'
    }
}
$validInlineDestinationFixtures = @(
    [pscustomobject]@{
        Markdown = '[doc](https://example.com/foo(and(bar)).md)'
        Target = 'https://example.com/foo(and(bar)).md'
    },
    [pscustomobject]@{
        Markdown = '[doc](<https://example.com/foo(bar).md>)'
        Target = 'https://example.com/foo(bar).md'
    },
    [pscustomobject]@{
        Markdown = '[doc](https://example.com/foo\(bar\).md)'
        Target = 'https://example.com/foo(bar).md'
    },
    [pscustomobject]@{
        Markdown = '[https://example.com/foo(bar).md](https://example.com/foo(bar).md)'
        Target = 'https://example.com/foo(bar).md'
    },
    [pscustomobject]@{
        Markdown = '[see [issue #42]](https://github.com/hasanmanzak/meAndAI/issues/42)'
        Target = 'https://github.com/hasanmanzak/meAndAI/issues/42'
    }
)
foreach ($validInlineDestinationFixture in $validInlineDestinationFixtures) {
    $inlineDestinationEvidence = Get-DocumentMarkdownLinkEvidence `
        -Markdown $validInlineDestinationFixture.Markdown `
        -Path '<inline-destination-fixture>'
    if (@($inlineDestinationEvidence.Links).Count -ne 1 -or
        [string]$inlineDestinationEvidence.Links[0].Target -cne
            [string]$validInlineDestinationFixture.Target) {
        Add-Failure "TEST-0175 a valid balanced, escaped, angle-delimited, or nested-label inline link was not parsed exactly: '$($validInlineDestinationFixture.Markdown)'."
    }
}
$unclosedCommentEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown "<!--`n[FEAT-0032](docs/features/FEAT-0032-general-capability-test-architecture/README.md)" `
    -Path '<unclosed-comment-fixture>'
if (@($unclosedCommentEvidence.Links).Count -ne 0 -or
    @($unclosedCommentEvidence.HtmlComments).Count -ne 1 -or
    -not [regex]::IsMatch(
        [string]$unclosedCommentEvidence.HtmlComments[0].Value,
        $recordIdPattern
    )) {
    Add-Failure 'TEST-0175 an unclosed HTML-comment pseudo-link bypassed classification.'
}
$footnoteMarkdown = "Text[^1]`n`n[^1]: FEAT-0032"
$footnoteEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $footnoteMarkdown -Path '<footnote-fixture>'
$footnoteUnlinked = Get-DocumentUnlinkedMarkdown `
    -Markdown $footnoteMarkdown -LinkEvidence $footnoteEvidence
if (@($footnoteEvidence.Definitions).Count -ne 0 -or
    -not [regex]::IsMatch($footnoteUnlinked, $recordIdPattern)) {
    Add-Failure 'TEST-0175 a GitHub footnote body was removed as a reference-link definition.'
}
$unusedDefinitionMarkdown =
    '[FEAT-0032]: docs/features/FEAT-0032-general-capability-test-architecture/README.md'
$unusedDefinitionEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $unusedDefinitionMarkdown -Path '<unused-definition-fixture>'
if (@($unusedDefinitionEvidence.Definitions).Count -ne 1 -or
    @($unusedDefinitionEvidence.Links).Count -ne 0 -or
    -not [regex]::IsMatch(
        [string]$unusedDefinitionEvidence.Definitions[0].Value,
        $recordIdPattern
    )) {
    Add-Failure 'TEST-0175 an unused cross-record reference definition bypassed classification.'
}
$shorthandFixtures = @(
    [pscustomobject]@{ Text = 'GH-110'; Target = 'https://github.com/hasanmanzak/meAndAI/issues/110'; Valid = $true },
    [pscustomobject]@{ Text = 'PR-110'; Target = 'https://github.com/hasanmanzak/meAndAI/pull/110'; Valid = $true },
    [pscustomobject]@{ Text = 'issue-110'; Target = 'https://github.com/hasanmanzak/meAndAI/issues/110'; Valid = $true },
    [pscustomobject]@{ Text = 'comment-9001'; Target = 'https://github.com/hasanmanzak/meAndAI/issues/110#issuecomment-9001'; Valid = $true },
    [pscustomobject]@{ Text = 'review-9001'; Target = 'https://github.com/hasanmanzak/meAndAI/pull/110#pullrequestreview-9001'; Valid = $true },
    [pscustomobject]@{ Text = 'meAndAI#110'; Target = 'https://github.com/hasanmanzak/meAndAI/issues/110'; Valid = $true },
    [pscustomobject]@{ Text = 'hasanmanzak/meAndAI#110'; Target = 'https://github.com/hasanmanzak/meAndAI/issues/110'; Valid = $true },
    [pscustomobject]@{ Text = 'GH-110'; Target = 'https://github.com/evil/other/issues/110'; Valid = $false },
    [pscustomobject]@{ Text = 'meAndAI#110'; Target = 'https://github.com/evil/meAndAI/issues/110'; Valid = $false }
)
foreach ($shorthandFixture in $shorthandFixtures) {
    $shorthandReferences = @(
        Get-DocumentGitHubShorthandReferences -Text $shorthandFixture.Text
    )
    $accepted = $shorthandReferences.Count -eq 1 -and
        (Test-DocumentExactGitHubShorthandTarget `
            -Reference $shorthandReferences[0] `
            -Target $shorthandFixture.Target)
    if ($accepted -ne [bool]$shorthandFixture.Valid) {
        Add-Failure "TEST-0175 GitHub shorthand exact-target fixture was misclassified: '$($shorthandFixture.Text)' -> '$($shorthandFixture.Target)'."
    }
}
$descriptiveFixture = Get-DocumentMarkdownLinkEvidence `
    -Markdown '[See FEAT-0032 architecture](docs/features/FEAT-0001-common-development-protocol/README.md)' `
    -Path '<descriptive-label-fixture>'
if (@($descriptiveFixture.Links).Count -ne 1 -or
    @([regex]::Matches(
        [string]$descriptiveFixture.Links[0].Label, $recordIdPattern
    )).Count -ne 1 -or
    (Test-DocumentRecordLinkTarget -SourcePath 'CHANGELOG.md' `
        -Target ([string]$descriptiveFixture.Links[0].Target) `
        -ExpectedTarget 'docs/features/FEAT-0032-general-capability-test-architecture/README.md')) {
    Add-Failure 'TEST-0175 descriptive stable-ID fixture bypassed exact-target validation.'
}
$rawPathFixture = 'See docs/notes/release-evidence.md for details.'
$rawPathEvidence = Get-DocumentMarkdownLinkEvidence `
    -Markdown $rawPathFixture -Path '<raw-path-fixture>'
$rawPathUnlinked = Get-DocumentUnlinkedMarkdown `
    -Markdown $rawPathFixture -LinkEvidence $rawPathEvidence
if (-not [regex]::IsMatch($rawPathUnlinked, $rawDocumentPathPattern)) {
    Add-Failure 'TEST-0175 raw repository document-path fixture was not detected.'
}
$ownPathResolution = Resolve-DocumentLinkTarget `
    -SourcePath 'docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md' `
    -Target 'README.md'
if ($ownPathResolution.Kind -cne 'Repository' -or
    [string]$ownPathResolution.Value -cne
        'docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md') {
    Add-Failure 'TEST-0175 a current document own-path fixture did not resolve to the source artifact.'
}
[Threading.Thread]::CurrentThread.CurrentCulture =
    $originalLinkValidationCulture
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
    'severity, impact rank, and',
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

$mandateFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0015-stability-consistency-mandate/README.md'
) -Raw
$mandateDecision = Get-Content -LiteralPath (
    Join-Path $root 'docs/decisions/DEC-0015-event-triggered-stability-cycles.md'
) -Raw
$mandateTestCases = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0015-stability-consistency-mandate/test-cases.md'
) -Raw
$mandateSectionMatch = [regex]::Match(
    $protocolContent,
    '(?ms)^### Stability and consistency mandate\r?\n(?<body>.*?)(?=^#{1,3} [^\r\n]+|\z)'
)
if (-not $mandateSectionMatch.Success) {
    Add-Failure 'TEST-0096 protocol has no bounded stability and consistency mandate section.'
    $normalizedMandateContract = ''
}
else {
    $normalizedMandateContract = [regex]::Replace(
        $mandateSectionMatch.Groups['body'].Value, '\s+', ' '
    )
}
foreach ($requiredText in @(
    'material development',
    'feature, bug, refactor, review, test, documentation, governance, and consistency',
    'zero unresolved `Blocking`',
    '`AcceptedResidual`',
    '`ExternalOrLegacyFollowUp`',
    '`OptionalImprovement`',
    'do not enter the active remediation queue',
    '`Waiting`',
    'new material development',
    'new failed evidence',
    'Correctable new failed evidence reopens the active cycle',
    'Failed evidence produces `Blocked` only when its required correction cannot be completed within the remaining authority and finite budget',
    'unchanged tree',
    'An unchanged scan MUST NOT be repeated',
    'If the initial scan finds zero unresolved `Blocking`, that initial scan is the convergence evidence',
    'A confirmation scan is required only after remediation changed the tree'
)) {
    if (-not $normalizedMandateContract.Contains($requiredText)) {
        Add-Failure "TEST-0096 mandate lifecycle contract is missing '$requiredText'."
    }
}
if (-not ([regex]::Replace($mandateDecision, '\s+', ' ')).Contains(
    'Distribution of v0.9.0 MUST use the immutable GitHub Release required by Gate 7'
)) {
    Add-Failure 'TEST-0099 DEC-0015 makes the mandatory v0.9.0 distribution release optional or ambiguous.'
}

foreach ($requiredText in @(
    'dependencies first',
    'ready set',
    'priority, severity, impact rank, and then stable identifier order',
    'dependency cycle',
    'A dependency cycle, missing required authority, or unavailable required input stops the cycle as `Blocked`',
    '`Blocked`',
    'smallest explicitly recorded dependency-coherent group'
)) {
    if (-not $normalizedMandateContract.Contains($requiredText)) {
        Add-Failure "TEST-0097 dependency and priority contract is missing '$requiredText'."
    }
}
foreach ($requiredText in @(
    'dependencies (`FIND-NNNN` identifiers or explicit `None`)',
    'priority (`p0`, `p1`, `p2`, or `p3`, where `p0` is highest)',
    'impact rank (`critical`, `high`, `medium`, `low`, or `info`)',
    'dependency, priority, severity, impact rank'
)) {
    if (-not $normalizedMandateContract.Contains($requiredText)) {
        Add-Failure "TEST-0097 canonical finding schema is missing '$requiredText'."
    }
}
foreach ($requiredText in @(
    'id: dependencies',
    'id: priority',
    'id: impact_rank'
)) {
    if (-not $findingForm.Contains($requiredText)) {
        Add-Failure "TEST-0097 finding form is missing '$requiredText'."
    }
}
if ($findingForm.Contains('labels: ["type:finding", "priority:p2"]')) {
    Add-Failure 'TEST-0097 finding form assigns a static priority that can contradict its recorded queue priority.'
}

foreach ($requiredText in @(
    'one `Blocking` finding at a time',
    'focused evidence',
    'fresh-diff self-review',
    'provide the solution, focused evidence, and a fresh-diff self-review before starting the next independent queue item',
    'caused or exposed',
    'active queue',
    'fix it in the current correction when coherent, or record its dependencies and priority before continuing',
    'cannot be deferred as legacy or optional work'
)) {
    if (-not $normalizedMandateContract.Contains($requiredText)) {
        Add-Failure "TEST-0098 per-finding correction contract is missing '$requiredText'."
    }
}

$normalizedMandatePublication = $normalizedMandateContract
foreach ($requiredText in @(
    'converged final push',
    'ordinary Git push',
    'does not create a tag or GitHub Release',
    'Hosted CI or review evidence',
    'reopens the same cycle',
    'Exact converged-push commit and ref evidence MUST be written to the issue or pull request after the push exists',
    'A repository document records local push eligibility and MUST NOT predict the commit that contains itself',
    'Local convergence is not full normative cycle completion',
    'cycle completes and enters `Waiting` only after the authorized converged final review-branch push exists',
    'stop as `Blocked` on missing final-push authority without claiming completion or `Waiting`',
    'Do not push a locally known non-converged tree'
)) {
    if (-not $normalizedMandatePublication.Contains($requiredText)) {
        Add-Failure "TEST-0099 convergence-push and consumer contract is missing '$requiredText'."
    }
}
$normalizedConsumerMandate = [regex]::Replace($adoption, '\s+', ' ')
foreach ($requiredText in @(
    'exact protocol pin',
    'consumer-owned instructions, memory, features, decisions, and tests remain under consumer ownership'
)) {
    if (-not $normalizedConsumerMandate.Contains($requiredText)) {
        Add-Failure "TEST-0099 consumer reachability contract is missing '$requiredText'."
    }
}

$agentPromptIndex = Get-Content -LiteralPath (
    Join-Path $root 'docs/agent-prompts/README.md'
) -Raw
$stabilityCyclePrompt = Get-Content -LiteralPath (
    Join-Path $root 'docs/agent-prompts/stability-and-consistency-cycle.md'
) -Raw
$normalizedStabilityCyclePrompt = [regex]::Replace($stabilityCyclePrompt, '\s+', ' ')
$copyReadyPromptBlocks = @([regex]::Matches(
    $stabilityCyclePrompt,
    '(?ms)^```text\r?\n.+?^```\s*$'
))
if ($copyReadyPromptBlocks.Count -ne 1) {
    Add-Failure 'TEST-0131 canonical stability-cycle guidance must contain exactly one copy-ready text prompt.'
}
foreach ($requiredText in @(
    'every normative source supplied by the invoking context',
    'Trigger context',
    'material development',
    'new failed evidence',
    'Scan scope and exclusions',
    'entire declared tracked-project scope',
    'Validation budget',
    'finite',
    'Blocking, AcceptedResidual, ExternalOrLegacyFollowUp, or OptionalImprovement',
    'dependencies (or None)',
    'priority, severity, impact rank, and then stable identifier',
    'one Blocking finding at a time',
    'smallest explicitly recorded dependency-coherent group',
    'focused tests',
    'fresh-diff self-review',
    'caused or exposed by the correction remains in this cycle',
    'Do not run an unchanged confirmation scan',
    'one budgeted confirmation scan',
    'zero unresolved Blocking findings',
    'report-only',
    'push-review-branch',
    'separately granted authority for the exact review branch',
    'ordinary converged final push',
    'report Waiting',
    'Blocked',
    'creating a tag',
    'creating a GitHub Release'
)) {
    if (-not $normalizedStabilityCyclePrompt.Contains($requiredText)) {
        Add-Failure "TEST-0131 canonical stability-cycle prompt is missing '$requiredText'."
    }
}
foreach ($requiredLink in @(
    '[PROTOCOL.md](../../PROTOCOL.md)',
    '[DEC-0015](../decisions/DEC-0015-event-triggered-stability-cycles.md)'
)) {
    if (-not $stabilityCyclePrompt.Contains($requiredLink)) {
        Add-Failure "TEST-0131 canonical stability-cycle guidance is missing '$requiredLink'."
    }
}
foreach ($requiredText in @(
    'The default is `report-only`',
    'In report-only mode, do not commit or push',
    'Local convergence is not full normative cycle completion',
    'Blocked` on missing final-push authority',
    'Do not report `Waiting` or full cycle completion',
    'The mode name alone grants no Git authority',
    'Neither publication mode authorizes'
)) {
    if (-not $normalizedStabilityCyclePrompt.Contains($requiredText)) {
        Add-Failure "TEST-0131 publication authority boundary is missing '$requiredText'."
    }
}

$docsIndexContent = Get-Content -LiteralPath (Join-Path $root 'docs/README.md') -Raw
$agentPromptMarkdownFiles = @(Get-ChildItem -LiteralPath (
    Join-Path $root 'docs/agent-prompts'
) -File -Filter '*.md' | Sort-Object Name)
$expectedAgentPromptFiles = @('README.md', 'stability-and-consistency-cycle.md')
if (($agentPromptMarkdownFiles.Name -join '|') -cne ($expectedAgentPromptFiles -join '|')) {
    Add-Failure 'TEST-0132 optional agent-prompt directory must contain only its index and one canonical prompt.'
}
foreach ($linkContract in @(
    [pscustomobject]@{
        Content = $docsIndexContent
        Text = 'agent-prompts/README.md'
        Location = 'documentation index'
    },
    [pscustomobject]@{
        Content = $protocolContent
        Text = 'docs/agent-prompts/stability-and-consistency-cycle.md'
        Location = 'protocol mandate'
    },
    [pscustomobject]@{
        Content = $adoption
        Text = 'agent-prompts/stability-and-consistency-cycle.md'
        Location = 'adoption guide'
    },
    [pscustomobject]@{
        Content = $agentPromptIndex
        Text = 'stability-and-consistency-cycle.md'
        Location = 'agent-prompt index'
    },
    [pscustomobject]@{
        Content = $adoption
        Text = '.ai/protocol/docs/agent-prompts/stability-and-consistency-cycle.md'
        Location = 'submodule consumer route'
    },
    [pscustomobject]@{
        Content = $adoption
        Text = 'provider-configured immutable ref'
        Location = 'repository-reference consumer route'
    }
)) {
    if (-not $linkContract.Content.Contains($linkContract.Text)) {
        Add-Failure "TEST-0132 $($linkContract.Location) is missing '$($linkContract.Text)'."
    }
}
foreach ($requiredText in @(
    'copy or reference',
    'does not install, create, schedule, or activate a goal, recurring task, automation, workflow, scheduler, background loop, or next invocation',
    'Consumers do not need a consumer-owned copy'
)) {
    if (-not ([regex]::Replace($agentPromptIndex, '\s+', ' ')).Contains($requiredText)) {
        Add-Failure "TEST-0132 opt-in prompt index is missing '$requiredText'."
    }
}
$automaticPromptInstallRoots = @(
    'templates/project',
    '.github/workflows',
    'migrations'
)
foreach ($relativeRoot in $automaticPromptInstallRoots) {
    $candidateRoot = Join-Path $root $relativeRoot
    if (-not (Test-Path -LiteralPath $candidateRoot -PathType Container)) {
        continue
    }
    foreach ($candidateFile in @(Get-ChildItem -LiteralPath $candidateRoot -Recurse -File)) {
        $candidateContent = Get-Content -LiteralPath $candidateFile.FullName -Raw
        if ($candidateContent.Contains('stability-and-consistency-cycle.md')) {
            $relativeCandidate = $candidateFile.FullName.Substring($root.Length + 1).Replace('\', '/')
            Add-Failure "TEST-0132 optional prompt is automatically installed or scheduled by '$relativeCandidate'."
        }
    }
}
if (Test-Path -LiteralPath (Join-Path $root 'templates/project/docs/agent-prompts')) {
    Add-Failure 'TEST-0132 optional prompt must not have a consumer-owned template copy.'
}
$currentProtocolVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$currentProtocolTag = "v$currentProtocolVersion"
$submoduleLivePinSignals = @(
    '[local common protocol](.ai/protocol/PROTOCOL.md)',
    "[the checkout's ``VERSION``](.ai/protocol/VERSION)",
    'do not duplicate a literal'
)
if (@($submoduleLivePinSignals | Where-Object {
    -not $submoduleAdapter.Contains($_)
}).Count -ne 0 -or $submoduleAdapter -match 'v\d+\.\d+\.\d+') {
    Add-Failure 'TEST-0099 submodule adapter does not resolve the live pin from its gitlink and VERSION authority.'
}
if (-not $referenceAdapter.Contains(
        'immutable ref: resolve from the repository-owned provider configuration'
    ) -or
    -not $referenceAdapter.Contains('entry point: `PROTOCOL.md`') -or
    $referenceAdapter.Contains('.ai/protocol/PROTOCOL.md') -or
    $referenceAdapter -match 'ref:\s*`?v\d+\.\d+\.\d+') {
    Add-Failure 'TEST-0099 repository-reference adapter duplicates or bypasses its configured immutable-ref authority.'
}

$quickAdoptionGuide = Get-Content -LiteralPath (
    Join-Path $root 'docs/quick-adoption.md'
) -Raw
$quickCommandMatch = [regex]::Match(
    $quickAdoptionGuide,
    '(?ms)^## Quick command\s+(?<body>.*?)(?=^## )'
)
$singleFileFeature = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0017-v092-single-file-quick-adoption/README.md'
) -Raw
$singleFileScenarios = Get-Content -LiteralPath (
    Join-Path $root 'docs/features/FEAT-0017-v092-single-file-quick-adoption/test-cases.md'
) -Raw
$launcherSource = Get-Content -LiteralPath (
    Join-Path $root 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
) -Raw
$quickAdoptionLaunchers = @(Get-ChildItem -LiteralPath (Join-Path $root 'scripts') `
    -Filter 'Invoke-*QuickAdoption*.ps1' -File)
$expectedAssetUrl = "https://github.com/hasanmanzak/meAndAI/releases/download/$currentProtocolTag/Invoke-MeAndAIQuickAdoption.ps1"
$expectedInvocation = 'powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath .'
if (-not $quickCommandMatch.Success) {
    Add-Failure 'TEST-0101 quick guide has no bounded Quick command section.'
}
else {
    $quickCommand = $quickCommandMatch.Groups['body'].Value
    $invocations = @([regex]::Matches(
        $quickCommand,
        '(?im)^\s*powershell\s+-NoProfile\s+-ExecutionPolicy\s+Bypass\s+-File\s+[^\r\n]*Invoke-MeAndAIQuickAdoption\.ps1[^\r\n]*$'
    ))
    if (-not $quickCommand.Contains($expectedAssetUrl) -or
        -not $quickCommand.Contains($expectedInvocation) -or
        $invocations.Count -ne 1 -or
        -not ([regex]::Replace($quickCommand, '\s+', ' ')).Contains(
            'outside the consumer repository'
        )) {
        Add-Failure 'TEST-0101 quick guide does not expose one exact immutable-release asset and one outside-target script invocation.'
    }
    foreach ($forbidden in @(
        'gh api', 'ConvertFrom-Json', 'Set-Content', 'Invoke-Expression',
        'Invoke-WebRequest', '| powershell', '| pwsh', '$launcher =', '$t='
    )) {
        if ($quickCommand.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Add-Failure "TEST-0101 quick command retains forbidden inline bootstrap text '$forbidden'."
        }
    }
}
if (-not $launcherSource.Contains("[string]`$ProtocolTag = '$currentProtocolTag'") -or
    -not $launcherSource.Contains("`$runtimeReleaseTag = '$currentProtocolTag'") -or
    -not $launcherSource.Contains('Get-QuickAdoptionBootstrapRuntimeEvidence') -or
    -not $launcherSource.Contains('published immutable GitHub Release')) {
    Add-Failure 'TEST-0101 canonical launcher is not pinned to the current immutable-release validation contract.'
}
if ($quickAdoptionLaunchers.Count -ne 1 -or
    $quickAdoptionLaunchers[0].Name -cne 'Invoke-MeAndAIQuickAdoption.ps1') {
    Add-Failure 'TEST-0101 quick adoption has more than the one canonical launcher script.'
}
foreach ($requiredText in @(
    '`TEST-0101`', '`Invoke-MeAndAIQuickAdoption.ps1` release asset',
    'No second bootstrap script', 'issue #51'
)) {
    if (-not $singleFileFeature.Contains($requiredText) -and
        -not $singleFileScenarios.Contains($requiredText)) {
        Add-Failure "TEST-0101 canonical FEAT-0017 records are missing '$requiredText'."
    }
}
$updaterScript = Get-Content -LiteralPath (
    Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
) -Raw
$managedAssetBlock = [regex]::Match(
    $updaterScript,
    '(?ms)^\$ManagedUpdaterAssets = @\((?<body>.*?)^\)\r?\n\$ManagedPaths ='
)
$actualManagedAssets = if ($managedAssetBlock.Success) {
    @([regex]::Matches(
        $managedAssetBlock.Groups['body'].Value,
        "(?m)^\s*ConsumerPath = '(?<path>[^']+)'$"
    ) | ForEach-Object { $_.Groups['path'].Value })
}
else { @() }
$expectedManagedAssets = @(
    '.github/workflows/meandai-protocol-update.yml',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)
if (($actualManagedAssets -join '|') -cne ($expectedManagedAssets -join '|')) {
    Add-Failure 'TEST-0099 updater managed assets exceed or omit the exact three consumer-resident, protocol-owned automation projections.'
}
foreach ($testId in @('TEST-0096', 'TEST-0097', 'TEST-0098', 'TEST-0099')) {
    if (-not $mandateTestCases.Contains("``$testId``") -or
        -not $mandateFeature.Contains(
            "[$testId](test-cases.md#$($testId.ToLowerInvariant()))"
        )) {
        Add-Failure "TEST-0099 canonical FEAT-0015 records do not link $testId."
    }
}
foreach ($requiredText in @(
    '## Converged final push evidence',
    'External evidence authority',
    'Local convergence eligibility'
)) {
    if (-not $mandateFeature.Contains($requiredText)) {
        Add-Failure "TEST-0099 FEAT-0015 push-evidence boundary is missing '$requiredText'."
    }
}
foreach ($requiredText in @(
    'dependency-first',
    'per-finding correction evidence',
    'converged final push',
    'waiting state'
)) {
    if (-not $featureTemplate.Contains($requiredText)) {
        Add-Failure "TEST-0099 feature template is missing mandate evidence '$requiredText'."
    }
}
foreach ($requiredText in @(
    'Converged final push',
    'Waiting or blocked outcome'
)) {
    if (-not $pullRequestTemplate.Contains($requiredText)) {
        Add-Failure "TEST-0099 pull request template is missing mandate evidence '$requiredText'."
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

$postPublicationVerifier = Get-Content -LiteralPath (
    Join-Path $root 'tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1'
) -Raw
foreach ($requiredText in @(
    'releases/tags/', 'git/ref/tags/', 'compare/',
    'git/matching-refs/heads/', 'issues/',
    'commits/$ExpectedCommit/comments', 'contents/',
    "'immutable'", 'ExternalPostPublication'
)) {
    $combinedEvidenceContract = $postPublicationVerifier + "`n" +
        (Get-Content -LiteralPath (Join-Path $root 'tests/scenario-ownership.psd1') -Raw)
    if (-not $combinedEvidenceContract.Contains($requiredText)) {
        Add-Failure "TEST-0076 post-publication evidence contract is missing '$requiredText'."
    }
}
$postPublicationJobIndex = $ciWorkflow.IndexOf(
    "`n  post-publication:", [StringComparison]::Ordinal
)
if ($postPublicationJobIndex -lt 0) {
    Add-Failure 'TEST-0076 CI has no separate post-publication evidence job.'
}
else {
    $preMergeWorkflow = $ciWorkflow.Substring(0, $postPublicationJobIndex)
    $postPublicationWorkflow = $ciWorkflow.Substring($postPublicationJobIndex)
    if ($preMergeWorkflow.Contains('Verify-PostPublicationEvidence.ps1') -or
        -not $postPublicationWorkflow.Contains(
            "if: github.event_name == 'workflow_dispatch' && inputs.verify_post_publication"
        ) -or
        -not $postPublicationWorkflow.Contains('Verify-PostPublicationEvidence.ps1')) {
        Add-Failure 'TEST-0076 post-publication authority is mixed into the pre-merge validation gate.'
    }
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

if ($failures.Count -gt 0) {
    Write-Host "Protocol validation failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

if ($StructureOnly) {
    Write-Host 'Protocol-governance structure assertions passed.' -ForegroundColor Green
}
else {
    $protocolScenarioResult = New-MeAndAIScenarioResult `
        -Owner 'tests/capabilities/protocol-governance/protocol-governance.tests.ps1' `
        -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
    Write-Host 'Protocol-governance assertions passed.' -ForegroundColor Green
    Write-Host ('MEANDAI_SCENARIO_RESULTS=' +
        ($protocolScenarioResult | ConvertTo-Json -Compress))
}
