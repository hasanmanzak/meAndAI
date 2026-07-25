[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/protocol-governance/recurrence-prevention.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $scenarioAuthorityPath
$failures = [System.Collections.Generic.List[string]]::new()

$surfacePaths = @(
    'PROTOCOL.md',
    'docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md',
    'docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md',
    'templates/feature/README.md',
    '.github/PULL_REQUEST_TEMPLATE.md',
    'docs/agent-prompts/stability-and-consistency-cycle.md',
    'templates/project/.ai/memory/README.md',
    'templates/project/.ai/memory/project.md',
    '.ai/memory/README.md',
    '.ai/memory/project.md'
)
$surfaces = @{}
foreach ($relativePath in $surfacePaths) {
    $path = Join-Path $root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "TEST-0183 missing recurrence-contract surface '$relativePath'."
    }
    $surfaces[$relativePath] = Get-Content -LiteralPath $path -Raw
}

$sectionCases = @(
    [pscustomobject]@{
        Label = 'PROTOCOL.md Gate 0'
        Path = 'PROTOCOL.md'
        Level = 3
        Heading = 'Gate 0 - Context and baseline'
        Required = @(
            'Before selecting a tool, planning a correction, or mutating the tree',
            'A matching `Active` entry routes the work to its required response.',
            'No matching entry is recorded as explicit `None` and is not evidence that the route is safe.',
            'A `Stale` entry requires renewed evidence',
            'a `Superseded` entry routes only to its replacement',
            'multiple applicable `Active` entries are ambiguous and block mutation.',
            'Before delegating repository work, the delegating owner MUST resolve the applicable active recurrence entries',
            'include their required safe responses and unsafe retry boundaries in the task brief.',
            'The delegated agent MUST re-read [repository instructions](AGENTS.md) and active recurrence knowledge before its first tool call.',
            'Inherited conversation context or a generic instruction to follow the protocol is not evidence that this handoff occurred.',
            'A repeat requires new evidence that changes the failed precondition, a materially different verified route, or an explicitly declared idempotent retry contract',
            'Otherwise stop as `Blocked` and preserve the failure evidence.'
        )
    },
    [pscustomobject]@{
        Label = 'PROTOCOL.md Gate 2'
        Path = 'PROTOCOL.md'
        Level = 3
        Heading = 'Gate 2 - Design and contract review'
        Required = @(
            'Inventory every same-contract sibling surface and identify one canonical owner before correcting a defect or adding a helper.',
            'Similar names or syntax alone do not establish shared semantics or justify consolidation.',
            'A correction MUST trace the affected contract through every inventoried sibling'
        )
    },
    [pscustomobject]@{
        Label = 'PROTOCOL.md Gate 5'
        Path = 'PROTOCOL.md'
        Level = 3
        Heading = 'Gate 5 - Self-review'
        Required = @(
            'A corrected defect or finding MUST close with an executable recurrence barrier owned by a numbered scenario, or with a reviewed `NotApplicable` rationale that names its authority and review condition.',
            'For a confirmed recurring failure, create or update its project-local recurrence entry and canonical links.',
            'Project memory is routing evidence, not regression evidence, and cannot satisfy this closure gate by itself.'
        )
    },
    [pscustomobject]@{
        Label = 'PROTOCOL.md recurrence knowledge contract'
        Path = 'PROTOCOL.md'
        Level = 3
        Heading = 'Recurrence knowledge contract'
        Required = @(
            'Status: `Active`, `Stale`, or `Superseded`;',
            'Observable signature;',
            'Applicability;',
            'Affected contract and cause;',
            'Canonical owner and evidence',
            'Fixed release or evidence',
            'Required safe response;',
            'Unsafe retry boundary;',
            'Freshness and review condition;',
            'Superseded-by link or explicit `None`.',
            'No matching entry is explicit `None` and continues through ordinary',
            'Missing replacement evidence, a supersession cycle, multiple applicable `Active` entries, or conflicting canonical owners is ambiguous and fails closed.',
            'Memory is routing evidence, not regression evidence; it never replaces an executable recurrence barrier or reviewed `NotApplicable` result.'
        )
    }
)

foreach ($case in $sectionCases) {
    $marker = '#' * $case.Level
    $pattern = '(?ms)^' + [regex]::Escape($marker) + ' ' +
        [regex]::Escape($case.Heading) +
        '\s*\r?\n(?<body>.*?)(?=^#{1,' + $case.Level + '} |\z)'
    $match = [regex]::Match([string]$surfaces[$case.Path], $pattern)
    if (-not $match.Success) {
        $failures.Add("$($case.Label) section is missing.")
        continue
    }
    $normalizedBody = [regex]::Replace([string]$match.Groups['body'].Value, '\s+', ' ')
    foreach ($requiredText in $case.Required) {
        $normalizedRequired = [regex]::Replace([string]$requiredText, '\s+', ' ')
        if (-not $normalizedBody.Contains($normalizedRequired)) {
            $failures.Add("$($case.Label) is missing authoritative clause '$requiredText'.")
        }
    }
}

$surfaceCases = @(
    [pscustomobject]@{
        Path = 'docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md'
        Required = @(
            '- Status: Accepted',
            'A signature entry routes later work to canonical evidence',
            'same-contract sibling inventory',
            'Similar names alone are insufficient',
            'never substitutes for an executable regression'
        )
    },
    [pscustomobject]@{
        Path = 'docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md'
        Required = @(
            '### Gate 5 closure for the recurrence slice',
            '| [FIND-0243](#find-0243) | Barrier: [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) | Scenario-authority validation must continue rejecting dishonest planned/executable state. |',
            '| [FIND-0244](#find-0244) | Barrier: [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) | Reopen if planned and superseded scenario checks stop sharing one source inventory. |',
            '| [FIND-0245](#find-0245) | Reviewed `NotApplicable` | This slice''s self-review under [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md): the parameterized wrapper that caused the pre-evidence failure was removed rather than retained. Reopen if a parameterized surface reader returns. |',
            '| [FIND-0246](#find-0246) | Barrier: [TEST-0059](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0059) | Canonical structural validation must continue rejecting incomplete or non-clickable references. |',
            '| [FIND-0247](#find-0247) | Barrier: [TEST-0183](test-cases.md#test-0183) and [TEST-0059](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0059) | The recurrence scenario owns the schema/example and exact owner partition; the canonical structural scenario owns link/index integrity. |',
            '| [FIND-0248](#find-0248) | Barrier: [TEST-0183](test-cases.md#test-0183) | The exact recurrence field, required validation, and honest Structural / contract evidence remain mandatory. |',
            '| [FIND-0249](#find-0249) | Reviewed `NotApplicable` | This slice''s self-review under [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md): the draft local generic helpers were removed. Reopen during [SUBF-0096](#subf-0096) if any generic local helper survives canonical-owner classification. |',
            '| [FIND-0250](#find-0250) | `AcceptedResidual`; no corrected-defect barrier | Protocol maintainers review when GitHub issue forms support reusable components; until then the repeated declarative fields remain provider-required surfaces. |',
            '| [FIND-0251](#find-0251) | Barrier: [TEST-0059](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0059) | Every new canonical memory record must remain registered in its index. |',
            '| [FIND-0252](#find-0252) | Barrier: [TEST-0183](test-cases.md#test-0183) and [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177) | Every affected live GitHub work surface must retain both exact immutable authority URLs. |',
            '| [FIND-0253](#find-0253) | Barrier: [TEST-0183](test-cases.md#test-0183) | The exact recurrence-slice closure ledger and every numbered finding mapping must remain present. |',
            '| [FIND-0254](#find-0254) | Barrier: [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175), [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177), and [TEST-0183](test-cases.md#test-0183) | Visible identities must remain wholly linked, same-repository GitHub permalinks immutable, and required work-surface authorities exact. |'
        )
    },
    [pscustomobject]@{
        Path = 'templates/feature/README.md'
        Required = @(
            'Prior art and recurrence:',
            'Prior-art and recurrence evidence is recorded.'
        )
    },
    [pscustomobject]@{
        Path = '.github/PULL_REQUEST_TEMPLATE.md'
        Required = @(
            '## Prior-art and recurrence evidence',
            'https://github.com/hasanmanzak/meAndAI/blob/b55fc072caf96672a73f697002d2a2028c528da1/docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#readiness-evidence',
            'https://github.com/hasanmanzak/meAndAI/blob/b55fc072caf96672a73f697002d2a2028c528da1/docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md#decision',
            'Matching active entry or explicit `None`:',
            'Canonical owner and same-contract sibling inventory:',
            'Failed route, new evidence, or materially different route:',
            'Executable barrier or reviewed `NotApplicable`:',
            'Prior-art and recurrence evidence was recorded before implementation.'
        )
    },
    [pscustomobject]@{
        Path = 'docs/agent-prompts/stability-and-consistency-cycle.md'
        Required = @(
            'Prior-art and recurrence gate',
            'active project-memory recurrence knowledge',
            'same-contract sibling surface',
            'materially different verified route',
            'explicit retry contract',
            'executable recurrence barrier',
            'reviewed NotApplicable'
        )
    },
    [pscustomobject]@{
        Path = 'templates/project/.ai/memory/README.md'
        Required = @(
            'Active recurrence knowledge',
            'routing evidence',
            'executable regression evidence',
            'concise `Stale` or `Superseded` routing tombstone'
        )
    },
    [pscustomobject]@{
        Path = '.ai/memory/README.md'
        Required = @(
            'Active recurrence knowledge',
            'routing evidence',
            'executable regression evidence',
            'concise `Stale` or `Superseded` routing tombstone'
        )
    }
)

foreach ($case in $surfaceCases) {
    $normalizedContent = [regex]::Replace([string]$surfaces[$case.Path], '\s+', ' ')
    foreach ($requiredText in $case.Required) {
        $normalizedRequired = [regex]::Replace([string]$requiredText, '\s+', ' ')
        if (-not $normalizedContent.Contains($normalizedRequired)) {
            $failures.Add("$($case.Path) is missing recurrence contract '$requiredText'.")
        }
    }
}

foreach ($issueTemplatePath in @(
    '.github/ISSUE_TEMPLATE/feature.yml',
    '.github/ISSUE_TEMPLATE/subfeature.yml',
    '.github/ISSUE_TEMPLATE/task.yml',
    '.github/ISSUE_TEMPLATE/bug.yml',
    '.github/ISSUE_TEMPLATE/finding.yml'
)) {
    $path = Join-Path $root ($issueTemplatePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "TEST-0183 missing issue-form surface '$issueTemplatePath'."
    }
    $issueTemplate = Get-Content -LiteralPath $path -Raw
    $fieldMatches = [regex]::Matches(
        $issueTemplate,
        '(?ms)^  - type: textarea\r?\n    id: prior_art_recurrence\r?\n(?<body>.*?)(?=^  - type: |\z)'
    )
    if ($fieldMatches.Count -ne 1) {
        $failures.Add("$issueTemplatePath must declare exactly one prior-art recurrence field.")
        continue
    }
    $field = [string]$fieldMatches[0].Value
    foreach ($requiredText in @(
        'label: Prior-art and recurrence evidence',
        'https://github.com/hasanmanzak/meAndAI/blob/b55fc072caf96672a73f697002d2a2028c528da1/docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#readiness-evidence',
        'https://github.com/hasanmanzak/meAndAI/blob/b55fc072caf96672a73f697002d2a2028c528da1/docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md#decision',
        'Matching active entry or explicit None',
        'canonical owner',
        'sibling',
        'failed route'
    )) {
        if (-not $field.Contains($requiredText)) {
            $failures.Add("$issueTemplatePath recurrence field is missing '$requiredText'.")
        }
    }
    if (-not [regex]::IsMatch(
            $field,
            '(?ms)^    validations:\r?\n      required: true\s*$'
        )) {
        $failures.Add("$issueTemplatePath recurrence field is not explicitly required.")
    }
}

foreach ($projectPath in @(
    'templates/project/.ai/memory/project.md',
    '.ai/memory/project.md'
)) {
    $content = [string]$surfaces[$projectPath]
    $sectionMatch = [regex]::Match(
        $content,
        '(?ms)^## Active recurrence knowledge\s*\r?\n(?<body>.*?)(?=^## |\z)'
    )
    if (-not $sectionMatch.Success) {
        $failures.Add("$projectPath has no active recurrence knowledge section.")
        continue
    }
    $section = [regex]::Replace([string]$sectionMatch.Groups['body'].Value, '\s+', ' ')
    foreach ($requiredText in @(
        'Status:',
        'Observable signature:',
        'Applicability:',
        'Affected contract and cause:',
        'Canonical owner and evidence:',
        'Fixed release or evidence:',
        'Required safe response:',
        'Unsafe retry boundary:',
        'Freshness and review condition:',
        'Superseded by:'
    )) {
        if (-not $section.Contains($requiredText)) {
            $failures.Add("$projectPath active recurrence section is missing '$requiredText'.")
        }
    }
}

$activeMatch = [regex]::Match(
    [string]$surfaces['.ai/memory/project.md'],
    '(?ms)^## Active recurrence knowledge\s*\r?\n(?<body>.*?)(?=^## |\z)'
)
$activeSection = if ($activeMatch.Success) {
    [string]$activeMatch.Groups['body'].Value
}
else {
    ''
}
$normalizedActiveSection = [regex]::Replace($activeSection, '\s+', ' ')
foreach ($requiredText in @(
    'Git for Windows cannot create local clone signal pipes (`Win32 error 5`)',
    'Status: `Active`',
    'outside the restricted workspace sandbox',
    'log/2026-07-19-v0122-ci-evidence-hygiene.md#current-evidence',
    'Do not repeat the unchanged sandboxed Git command',
    'issue #128',
    'owns the project-local routing entry',
    'defines the entry schema, not the host restriction'
)) {
    if (-not $normalizedActiveSection.Contains($requiredText)) {
        $failures.Add(".ai/memory/project.md active recurrence knowledge is missing '$requiredText'.")
    }
}
foreach ($secretPattern in @('github_pat_', 'gho_', 'Bearer ', 'FG_PAT.txt')) {
    if ($activeSection.Contains($secretPattern)) {
        $failures.Add(".ai/memory/project.md active recurrence knowledge contains forbidden secret-shaped text '$secretPattern'.")
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Recurrence-prevention tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
    -TestId 'TEST-0183'
Write-Host 'Recurrence-prevention structural contract passed for TEST-0183.' `
    -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
