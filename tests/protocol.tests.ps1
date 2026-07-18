[CmdletBinding()]
param(
    [switch]$StructureOnly,
    [ValidateSet('Full', 'WindowsNative')]
    [string]$ExecutionProfile = 'Full'
)

$ErrorActionPreference = 'Stop'
if ($StructureOnly -and $ExecutionProfile -cne 'Full') {
    throw 'StructureOnly cannot be combined with a partial execution profile.'
}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Compare-ExactScenarioIds {
    param(
        [Parameter(Mandatory)][object[]]$Expected,
        [Parameter(Mandatory)][object[]]$Observed
    )

    $expectedIds = @($Expected | ForEach-Object { [string]$_ })
    $observedIds = @($Observed | ForEach-Object { [string]$_ })
    $expectedSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $observedSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($testId in $expectedIds) {
        if ($testId -cnotmatch '^TEST-[0-9]{4}$' -or -not $expectedSet.Add($testId)) {
            return [pscustomobject]@{
                Valid = $false
                Message = "expected scenario set contains invalid or duplicate identity '$testId'"
            }
        }
    }
    foreach ($testId in $observedIds) {
        if ($testId -cnotmatch '^TEST-[0-9]{4}$' -or -not $observedSet.Add($testId)) {
            return [pscustomobject]@{
                Valid = $false
                Message = "observed scenario set contains invalid or duplicate identity '$testId'"
            }
        }
    }
    if ($expectedIds.Count -ne $observedIds.Count -or
        -not $expectedSet.SetEquals($observedSet)) {
        $missing = @($expectedIds | Where-Object { -not $observedSet.Contains($_) })
        $unexpected = @($observedIds | Where-Object { -not $expectedSet.Contains($_) })
        return [pscustomobject]@{
            Valid = $false
            Message = "scenario result mismatch; missing=[$($missing -join ', ')]; unexpected=[$($unexpected -join ', ')]"
        }
    }
    return [pscustomobject]@{ Valid = $true; Message = '' }
}

function Read-ScenarioResultRecord {
    param(
        [Parameter(Mandatory)][object[]]$Output,
        [Parameter(Mandatory)][string]$ExpectedOwner,
        [Parameter(Mandatory)][object[]]$ExpectedTestIds
    )

    $lines = @($Output | ForEach-Object { [string]$_ })
    $nonEmptyLines = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $resultLines = @($nonEmptyLines | Where-Object {
        $_.StartsWith('MEANDAI_SCENARIO_RESULTS=', [StringComparison]::Ordinal)
    })
    if ($resultLines.Count -ne 1) {
        return [pscustomobject]@{
            Valid = $false
            Message = "expected exactly one scenario result line, found $($resultLines.Count)"
        }
    }
    if ($nonEmptyLines[-1] -cne $resultLines[0]) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'scenario result line is not the final successful suite output'
        }
    }

    try {
        $json = $resultLines[0].Substring('MEANDAI_SCENARIO_RESULTS='.Length)
        $record = $json | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Valid = $false
            Message = "scenario result JSON is invalid: $($_.Exception.Message)"
        }
    }
    $properties = @($record.PSObject.Properties | ForEach-Object { $_.Name })
    if ($properties.Count -ne 3 -or
        $properties -cnotcontains 'schema' -or
        $properties -cnotcontains 'owner' -or
        $properties -cnotcontains 'passed' -or
        ($record.schema -isnot [int] -and $record.schema -isnot [long]) -or
        [long]$record.schema -ne 1 -or
        [string]$record.owner -cne $ExpectedOwner -or
        $record.passed -isnot [array]) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'scenario result record has the wrong schema, owner, or property types'
        }
    }

    $comparison = Compare-ExactScenarioIds -Expected $ExpectedTestIds `
        -Observed @($record.passed)
    if (-not $comparison.Valid) {
        return $comparison
    }
    return [pscustomobject]@{ Valid = $true; Message = '' }
}

function Read-CompatibilityShardResultRecord {
    param(
        [Parameter(Mandatory)][object[]]$Output,
        [Parameter(Mandatory)][string]$ExpectedSuite,
        [Parameter(Mandatory)][string]$ExpectedShard
    )

    $lines = @($Output | ForEach-Object { [string]$_ })
    $nonEmptyLines = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $canonicalLines = @($nonEmptyLines | Where-Object {
        $_.StartsWith('MEANDAI_SCENARIO_RESULTS=', [StringComparison]::Ordinal)
    })
    $resultLines = @($nonEmptyLines | Where-Object {
        $_.StartsWith(
            'MEANDAI_COMPATIBILITY_SHARD_RESULT=',
            [StringComparison]::Ordinal
        )
    })
    if ($canonicalLines.Count -ne 0 -or $resultLines.Count -ne 1 -or
        $nonEmptyLines[-1] -cne $resultLines[0]) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'partial execution must end with exactly one compatibility result and no canonical scenario result'
        }
    }
    try {
        $json = $resultLines[0].Substring(
            'MEANDAI_COMPATIBILITY_SHARD_RESULT='.Length
        )
        $record = $json | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Valid = $false
            Message = "compatibility result JSON is invalid: $($_.Exception.Message)"
        }
    }
    $properties = @($record.PSObject.Properties | ForEach-Object { $_.Name })
    if ($properties.Count -ne 4 -or
        $properties -cnotcontains 'schema' -or
        $properties -cnotcontains 'suite' -or
        $properties -cnotcontains 'shard' -or
        $properties -cnotcontains 'passed' -or
        ($record.schema -isnot [int] -and $record.schema -isnot [long]) -or
        [long]$record.schema -ne 1 -or
        [string]$record.suite -cne $ExpectedSuite -or
        [string]$record.shard -cne $ExpectedShard -or
        $record.passed -isnot [bool] -or -not [bool]$record.passed) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'compatibility result has the wrong schema, identity, or success value'
        }
    }
    return [pscustomobject]@{ Valid = $true; Message = '' }
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
    'docs/agent-prompts/README.md',
    'docs/agent-prompts/stability-and-consistency-cycle.md',
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
    'tests/scenario-ownership.psd1',
    'tests/MeAndAI.ScenarioEvidence.psm1',
    'tests/Verify-PostPublicationEvidence.ps1',
    'tests/post-publication-evidence.tests.ps1',
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

$testSuites = @(Get-ChildItem -LiteralPath (Join-Path $root 'tests') -File `
    -Filter '*.tests.ps1' | Where-Object {
        $_.Name -cne 'protocol.tests.ps1' -and
        $_.BaseName -cnotmatch '-adapter\.tests$'
    } | Sort-Object Name)
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

$scenarioDeclarations = @{}
foreach ($testCaseFile in @(Get-ChildItem -LiteralPath (Join-Path $root 'docs/features') `
    -Recurse -File -Filter 'test-cases.md')) {
    $relativeTestCasePath = $testCaseFile.FullName.Substring($root.Length + 1).Replace('\', '/')
    $lineNumber = 0
    foreach ($line in @(Get-Content -LiteralPath $testCaseFile.FullName)) {
        $lineNumber++
        if ($line -notmatch '^\|\s*`(?<id>TEST-\d{4})`\s*\|') {
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
    [void]$canonicalSuiteOwners.Add('tests/protocol.tests.ps1')
    foreach ($suite in $testSuites) {
        [void]$canonicalSuiteOwners.Add("tests/$($suite.Name)")
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
                if ($owner -cne 'tests/Verify-PostPublicationEvidence.ps1') {
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
            -File -Filter '*.ps1')) {
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
    $suppressedComparison = Compare-ExactScenarioIds `
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
    '| `TEST-0002` | `SUBF-0001` | `VERSION` is evaluated against `M.m.rev`. | Exactly three ASCII decimal components are accepted, with no leading zero unless the component is exactly `0`.'
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

$quickAdoptionSuitePath = Join-Path $root 'tests/quick-adoption.tests.ps1'
$quickAdoptionSuiteSource = Get-Content -LiteralPath $quickAdoptionSuitePath -Raw
$streamingSuitePath = Join-Path $root 'tests/quick-adoption-streaming.tests.ps1'
$streamingSuiteSource = Get-Content -LiteralPath $streamingSuitePath -Raw
$selectorPath = Join-Path $root 'tests/Select-WindowsValidationProfile.ps1'
$selectorSource = if (Test-Path -LiteralPath $selectorPath -PathType Leaf) {
    Get-Content -LiteralPath $selectorPath -Raw
}
else { '' }
$validatorTokens = $null
$validatorParseErrors = $null
$validatorAst = [Management.Automation.Language.Parser]::ParseFile(
    $PSCommandPath,
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
    'tests/Select-WindowsValidationProfile.ps1',
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

        if ($fragment -and (Test-Path -LiteralPath $targetFile -PathType Leaf) -and
            ([System.IO.Path]::GetExtension($targetFile) -ieq '.md')) {
            $targetMarkdown = Get-Content -LiteralPath $targetFile -Raw
            $anchors = Get-MarkdownAnchors $targetMarkdown
            if (-not $anchors.Contains($fragment)) {
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
    'exact pinned PROTOCOL.md',
    'DEC-0015',
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
$quickAdoptionScripts = @(Get-ChildItem -LiteralPath (Join-Path $root 'scripts') `
    -Filter '*QuickAdoption*.ps1' -File)
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
    -not $launcherSource.Contains('Get-ValidatedImmutableProtocolRelease') -or
    -not $launcherSource.Contains('published immutable GitHub Release')) {
    Add-Failure 'TEST-0101 canonical launcher is not pinned to the current immutable-release validation contract.'
}
if ($quickAdoptionScripts.Count -ne 1 -or
    $quickAdoptionScripts[0].Name -cne 'Invoke-MeAndAIQuickAdoption.ps1') {
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
    Add-Failure 'TEST-0099 updater managed assets exceed or omit the exact three consumer-owned automation files.'
}
foreach ($testId in @('TEST-0096', 'TEST-0097', 'TEST-0098', 'TEST-0099')) {
    if (-not $mandateTestCases.Contains("``$testId``") -or
        -not $mandateFeature.Contains("``$testId")) {
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
    Join-Path $root 'tests/Verify-PostPublicationEvidence.ps1'
) -Raw
foreach ($requiredText in @(
    'releases/tags/', 'git/ref/tags/', 'compare/',
    'git/matching-refs/heads/', 'issues/', 'contents/',
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

if (-not $StructureOnly) {
    $completedSuiteOwners = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $engine = (Get-Process -Id $PID).Path
    $executionSuites = if ($ExecutionProfile -ceq 'WindowsNative') {
        @($testSuites | Where-Object {
            $_.Name -cin @(
                'quick-adoption.tests.ps1',
                'quick-adoption-streaming.tests.ps1'
            )
        })
    }
    else {
        @($testSuites)
    }
    foreach ($suite in $executionSuites) {
        $suiteArguments = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $suite.FullName
        )
        if ($ExecutionProfile -ceq 'WindowsNative') {
            $suiteArguments += @('-Shard', 'WindowsNative')
        }
        $suiteOutput = @(& $engine @suiteArguments 2>&1)
        $suiteExitCode = $LASTEXITCODE
        foreach ($line in $suiteOutput) {
            Write-Host ([string]$line)
        }
        $owner = "tests/$($suite.Name)"
        if ($suiteExitCode -ne 0) {
            Add-Failure "Child test suite failed: $($suite.Name)"
        }
        elseif ($ExecutionProfile -ceq 'Full') {
            $expectedTestIds = @($authorityByTestId.GetEnumerator() | Where-Object {
                $_.Value.Evidence -ceq 'ExecutableSuite' -and
                $_.Value.Owner -ceq $owner
            } | ForEach-Object { [string]$_.Key } | Sort-Object)
            $observedResult = Read-ScenarioResultRecord -Output $suiteOutput `
                -ExpectedOwner $owner -ExpectedTestIds $expectedTestIds
            if (-not $observedResult.Valid) {
                Add-Failure "TEST-0091 suite '$owner' has invalid observed scenario evidence: $($observedResult.Message)."
            }
            else {
                [void]$completedSuiteOwners.Add($owner)
            }
        }
        else {
            $observedResult = Read-CompatibilityShardResultRecord `
                -Output $suiteOutput -ExpectedSuite $owner `
                -ExpectedShard 'WindowsNative'
            if (-not $observedResult.Valid) {
                Add-Failure "TEST-0124 suite '$owner' has invalid compatibility evidence: $($observedResult.Message)."
            }
            else {
                [void]$completedSuiteOwners.Add($owner)
            }
        }
    }

    if ($ExecutionProfile -ceq 'Full') {
        try {
            $protocolScenarioResult = New-MeAndAIScenarioResult `
                -Owner 'tests/protocol.tests.ps1' -SourcePaths @($PSCommandPath) `
                -AuthorityPath $scenarioAuthorityPath
            [void]$completedSuiteOwners.Add('tests/protocol.tests.ps1')
        }
        catch {
            Add-Failure "TEST-0091 root suite has invalid source-bound scenario evidence: $($_.Exception.Message)"
        }
    }
    $requiredSuiteOwners = if ($ExecutionProfile -ceq 'Full') {
        @($authorityByTestId.Values | Where-Object {
            $_.Evidence -ceq 'ExecutableSuite'
        } | ForEach-Object { $_.Owner } | Sort-Object -Unique)
    }
    else {
        @(
            'tests/quick-adoption.tests.ps1',
            'tests/quick-adoption-streaming.tests.ps1'
        )
    }
    foreach ($owner in $requiredSuiteOwners) {
        if (-not $completedSuiteOwners.Contains($owner)) {
            Add-Failure "TEST-0074 canonical suite has no successful completion evidence: $owner."
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
    if ($ExecutionProfile -ceq 'Full') {
        Write-Host 'All discovered protocol test suites passed.' -ForegroundColor Green
        Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($protocolScenarioResult | ConvertTo-Json -Compress))
    }
    else {
        Write-Host 'Windows-native compatibility profile passed.' -ForegroundColor Green
        $compatibilityResult = [ordered]@{
            schema = 1
            suite = 'tests/protocol.tests.ps1'
            shard = 'WindowsNative'
            passed = $true
        }
        Write-Host ('MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
            ($compatibilityResult | ConvertTo-Json -Compress))
    }
}
