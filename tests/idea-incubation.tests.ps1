param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Read-RequiredFile {
    param([string]$RelativePath)
    $path = Join-Path $root ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "TEST-0043 missing required file: $RelativePath"
        return ''
    }
    return Get-Content -LiteralPath $path -Raw
}

$protocol = Read-RequiredFile 'PROTOCOL.md'
$index = Read-RequiredFile 'docs/ideas/README.md'
$firstIdea = Read-RequiredFile 'docs/ideas/IDEA-0001-role-based-multi-agent-protocol.md'
$template = Read-RequiredFile 'templates/idea.md'
$consumerIndex = Read-RequiredFile 'templates/project/docs/ideas/README.md'
$adoption = Read-RequiredFile 'docs/adoption.md'
$bootstrap = Read-RequiredFile 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'

foreach ($required in @(
    '| `IDEA-NNNN` | Idea |',
    '### Idea incubation',
    '`Exploring`', '`Parked`', '`Promoted`', '`Rejected`',
    'does not authorize implementation',
    'does not satisfy Definition of Ready',
    '`EPIC-NNNN`', '`FEAT-NNNN`', '`TASK-NNNN`', '`DEC-NNNN`'
)) {
    if (-not $protocol.Contains($required)) {
        Add-Failure "TEST-0043 protocol idea lifecycle is missing '$required'"
    }
}

foreach ($required in @(
    'IDEA-0001-role-based-multi-agent-protocol.md',
    'Exploring', 'Parked', 'Promoted', 'Rejected',
    '../../templates/idea.md'
)) {
    if (-not $index.Contains($required)) {
        Add-Failure "TEST-0043 idea index is missing '$required'"
    }
}

foreach ($required in @(
    '# IDEA-NNNN - Idea Title',
    '## Observation', '## Possibility', '## Potential value',
    '## Concerns', '## Promotion condition', '## Outcome',
    'does not authorize implementation'
)) {
    if (-not $template.Contains($required)) {
        Add-Failure "TEST-0043 reusable idea template is missing '$required'"
    }
}

foreach ($required in @(
    '# IDEA-0001 - Role-Based Multi-Agent Protocol',
    'Status: **Parked**',
    'analyst', 'developer', 'reviewer', 'tester',
    'does not authorize implementation'
)) {
    if (-not $firstIdea.Contains($required)) {
        Add-Failure "TEST-0043 first repository idea is missing '$required'"
    }
}

if (-not $consumerIndex.Contains('# Idea Index') -or
    -not $consumerIndex.Contains('IDEA-NNNN')) {
    Add-Failure 'TEST-0044 consumer idea index template is incomplete.'
}
if (-not $adoption.Contains('templates/project/docs/ideas/README.md') -or
    -not $adoption.Contains('templates/idea.md')) {
    Add-Failure 'TEST-0044 adoption guide does not expose both consumer idea assets.'
}
if (-not $bootstrap.Contains("ConsumerPath = 'docs/ideas/README.md'") -or
    -not $bootstrap.Contains("TemplatePath = 'templates/project/docs/ideas/README.md'")) {
    Add-Failure 'TEST-0044 bootstrap does not install the absent consumer idea index.'
}

foreach ($updaterPath in @(
    'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)) {
    $updater = Read-RequiredFile $updaterPath
    if ($updater.Contains('docs/ideas/README.md')) {
        Add-Failure "TEST-0044 compatible updater improperly manages consumer idea content in $updaterPath"
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Idea-incubation tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Idea-incubation tests passed for all declared scenarios in this suite.' -ForegroundColor Green
