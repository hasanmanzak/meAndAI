[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AdapterPath,
    [Parameter(Mandatory)][string]$Workspace,
    [Parameter(Mandatory)][string]$SourceGraphIdentityBase64,
    [switch]$ExpectSuccess
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath $AdapterPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $Workspace -PathType Container)) {
    throw 'The TEST-0153 isolated adapter-drift inputs are unavailable.'
}

try {
    $SourceGraphIdentityJson = [Text.UTF8Encoding]::new(
        $false, $true
    ).GetString([Convert]::FromBase64String($SourceGraphIdentityBase64))
}
catch {
    throw 'The TEST-0153 isolated adapter identity encoding is invalid.'
}

$global:Test0153CreatedPullRequest = $false
$global:Test0153CreatedPullRequestBody = ''
$global:Test0153CreatedPullRequestHead = ''

function global:gh {
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0
    if (($arguments -join ' ') -ceq 'api user --jq .login') {
        'owner'
        return
    }
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'repo' -and
        $arguments[1] -ceq 'view') {
        [ordered]@{
            nameWithOwner = 'owner/consumer'
            defaultBranchRef = [ordered]@{ name = 'main' }
        } | ConvertTo-Json -Compress
        return
    }
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'pr' -and
        $arguments[1] -ceq 'list') {
        if (-not $global:Test0153CreatedPullRequest) {
            '[]'
            return
        }
        @([ordered]@{
            number = 40
            url = 'https://github.com/owner/consumer/pull/40'
            headRefName = 'automation/meandai-capabilities-v0.5.0'
            headRefOid = $global:Test0153CreatedPullRequestHead
            baseRefName = 'main'
            headRepository = [ordered]@{ nameWithOwner = 'owner/consumer' }
            author = [ordered]@{ login = 'owner' }
            body = $global:Test0153CreatedPullRequestBody
            isDraft = $true
            state = 'OPEN'
        }) | ConvertTo-Json -Depth 8 -Compress
        return
    }
    if ($arguments.Count -ge 2 -and $arguments[0] -ceq 'pr' -and
        $arguments[1] -ceq 'create') {
        $bodyIndex = [Array]::IndexOf([object[]]$arguments, '--body')
        if ($bodyIndex -lt 0 -or $bodyIndex + 1 -ge $arguments.Count) {
            throw 'The TEST-0153 isolated adapter omitted its PR body.'
        }
        $remoteLine = @(& git -C $env:GITHUB_WORKSPACE ls-remote `
            --heads origin `
            refs/heads/automation/meandai-capabilities-v0.5.0 2>&1)
        if ($LASTEXITCODE -ne 0 -or $remoteLine.Count -ne 1 -or
            [string]$remoteLine[0] -notmatch '^(?<sha>[0-9a-f]{40})\s+') {
            throw 'The TEST-0153 isolated adapter could not bind its PR head.'
        }
        $global:Test0153CreatedPullRequestHead = [string]$Matches.sha
        $global:Test0153CreatedPullRequestBody = [string]$arguments[$bodyIndex + 1]
        $global:Test0153CreatedPullRequest = $true
        'https://github.com/owner/consumer/pull/40'
        return
    }
    throw "Unexpected TEST-0153 isolated gh call: $($arguments -join ' ')"
}

$savedEnvironment = @{}
foreach ($name in @(
    'GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN',
    'GITHUB_STEP_SUMMARY'
)) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
}
$savedLocation = Get-Location
try {
    $env:GITHUB_REPOSITORY = 'owner/consumer'
    $env:GITHUB_WORKSPACE = $Workspace
    $env:DEFAULT_BRANCH = 'main'
    $env:GH_TOKEN = 'redacted-test-token'
    $env:GITHUB_STEP_SUMMARY = $null
    try {
        & $AdapterPath -ProtocolSourcePath '.meandai-update-source' `
            -TargetTag 'v0.5.0' -AdoptionStrategy 'FullMigration' `
            -SourceGraphIdentityJson $SourceGraphIdentityJson
    }
    catch {
        if ($ExpectSuccess) { throw }
        Write-Output ('MEANDAI_TEST_GRAPH_REJECTION=' +
            $_.Exception.Message)
        exit 0
    }
    if (-not $ExpectSuccess) {
        throw 'The TEST-0153 hosted adapter accepted a drifted graph identity.'
    }
    if (-not $global:Test0153CreatedPullRequest) {
        throw 'The TEST-0153 hosted adapter did not create its exact proposal.'
    }
    Write-Output ('MEANDAI_TEST_PROPOSAL_BODY_BASE64=' +
        [Convert]::ToBase64String(
            [Text.UTF8Encoding]::new($false).GetBytes(
                $global:Test0153CreatedPullRequestBody
            )
        ))
}
finally {
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Variable -Name Test0153CreatedPullRequest `
        -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name Test0153CreatedPullRequestBody `
        -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name Test0153CreatedPullRequestHead `
        -Scope Global -ErrorAction SilentlyContinue
    Set-Location -LiteralPath $savedLocation
    foreach ($entry in $savedEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value)
    }
}
