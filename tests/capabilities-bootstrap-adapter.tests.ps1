[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$failures = [System.Collections.Generic.List[string]]::new()
$global:PullRequestExists = $false
$global:PullRequestCreateCalls = 0
$global:LastPullRequestBody = ''
$global:LastPullRequestHead = ''

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) {
    Write-Host 'AI capabilities bootstrap adapter tests failed:' -ForegroundColor Red
    Write-Host ' - TEST-0028 missing source-only bootstrap adapter.' -ForegroundColor Red
    exit 1
}

function Invoke-Git {
    param([string]$Repository, [string[]]$Arguments)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $Repository @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "git -C $Repository $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Copy-SourceFixture {
    param([string]$SourceRepository)

    $relativeFiles = @(
        'templates/project/AGENTS.submodule.md',
        'templates/project/.ai/memory/README.md',
        'templates/project/.ai/memory/project.md',
        'templates/project/.ai/memory/log/README.md',
        'templates/project/docs/ideas/README.md',
        'templates/project/.github/workflows/meandai-protocol-update.yml',
        'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1',
        'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1',
        '.github/PULL_REQUEST_TEMPLATE.md',
        '.github/ISSUE_TEMPLATE/bug.yml',
        '.github/ISSUE_TEMPLATE/epic.yml',
        '.github/ISSUE_TEMPLATE/feature.yml',
        '.github/ISSUE_TEMPLATE/finding.yml',
        '.github/ISSUE_TEMPLATE/subfeature.yml',
        '.github/ISSUE_TEMPLATE/task.yml'
    )
    foreach ($relativePath in $relativeFiles) {
        $source = Join-Path $root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $target = Join-Path $SourceRepository ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $parent = Split-Path -Parent $target
        New-Item -ItemType Directory -Force $parent | Out-Null
        Copy-Item -LiteralPath $source -Destination $target
    }
}

function global:gh {
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0
    if ($arguments[0] -eq 'pr' -and $arguments[1] -eq 'list') {
        if ($global:PullRequestExists) {
            '[{"number":40,"headRefName":"automation/meandai-capabilities-v0.5.0","isDraft":true,"state":"OPEN"}]'
        }
        else { '[]' }
        return
    }
    if ($arguments[0] -eq 'pr' -and $arguments[1] -eq 'create') {
        $global:PullRequestCreateCalls++
        $headIndex = [array]::IndexOf($arguments, '--head')
        $bodyIndex = [array]::IndexOf($arguments, '--body')
        $global:LastPullRequestHead = [string]$arguments[$headIndex + 1]
        $global:LastPullRequestBody = [string]$arguments[$bodyIndex + 1]
        $global:PullRequestExists = $true
        'https://github.com/owner/consumer/pull/40'
        return
    }
    throw "Unexpected fake gh command: $($arguments -join ' ')"
}

function New-BootstrapFixture {
    param(
        [string]$Name,
        [bool]$AddApplicationFile = $false,
        [bool]$AddAgentsCollision = $false,
        [bool]$AddIdeasCollision = $false,
        [bool]$AddManifestCollision = $false,
        [bool]$DriftSeedWorkflow = $false
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-capabilities-$Name-$([guid]::NewGuid().ToString('N'))"
    $consumer = Join-Path $tempRoot 'consumer'
    $remote = Join-Path $tempRoot 'remote.git'
    $source = Join-Path $consumer '.meandai-update-source'
    New-Item -ItemType Directory -Force $consumer, $source | Out-Null

    Invoke-Git -Repository $tempRoot -Arguments @('init', '--bare', $remote) | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('init', '-b', 'main') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('config', 'user.name', 'Fixture') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('config', 'user.email', 'fixture@example.invalid') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('config', 'tag.gpgSign', 'false') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('remote', 'add', 'origin', $remote) | Out-Null

    $workflowTarget = Join-Path $consumer '.github/workflows/meandai-protocol-update.yml'
    New-Item -ItemType Directory -Force (Split-Path -Parent $workflowTarget) | Out-Null
    if ($DriftSeedWorkflow) {
        [IO.File]::WriteAllText($workflowTarget, "name: drifted`n")
    }
    else {
        Copy-Item -LiteralPath $workflowPath -Destination $workflowTarget
    }
    if ($AddApplicationFile) {
        $appPath = Join-Path $consumer 'src/app.txt'
        New-Item -ItemType Directory -Force (Split-Path -Parent $appPath) | Out-Null
        [IO.File]::WriteAllText($appPath, "consumer application`n")
    }
    if ($AddAgentsCollision) {
        [IO.File]::WriteAllText((Join-Path $consumer 'AGENTS.md'), "consumer-owned instructions`n")
    }
    if ($AddIdeasCollision) {
        $ideasPath = Join-Path $consumer 'docs/ideas/README.md'
        New-Item -ItemType Directory -Force (Split-Path -Parent $ideasPath) | Out-Null
        [IO.File]::WriteAllText($ideasPath, "# Consumer-owned ideas`n")
    }
    if ($AddManifestCollision) {
        $manifestPath = Join-Path $consumer '.ai/adoption/meandai-capabilities.json'
        New-Item -ItemType Directory -Force (Split-Path -Parent $manifestPath) | Out-Null
        [IO.File]::WriteAllText($manifestPath, "{}`n")
    }
    Invoke-Git -Repository $consumer -Arguments @('add', '.') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('commit', '-m', 'Seed consumer') | Out-Null
    Invoke-Git -Repository $consumer -Arguments @('push', '-u', 'origin', 'main') | Out-Null

    Copy-SourceFixture -SourceRepository $source
    Invoke-Git -Repository $source -Arguments @('init', '-b', 'main') | Out-Null
    Invoke-Git -Repository $source -Arguments @('config', 'user.name', 'Fixture') | Out-Null
    Invoke-Git -Repository $source -Arguments @('config', 'user.email', 'fixture@example.invalid') | Out-Null
    Invoke-Git -Repository $source -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
    Invoke-Git -Repository $source -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-Git -Repository $source -Arguments @('config', 'tag.gpgSign', 'false') | Out-Null
    Invoke-Git -Repository $source -Arguments @('add', '.') | Out-Null
    Invoke-Git -Repository $source -Arguments @('commit', '-m', 'Protocol v0.5.0') | Out-Null
    Invoke-Git -Repository $source -Arguments @('tag', 'v0.5.0') | Out-Null

    return [pscustomobject]@{
        Root = $tempRoot
        Consumer = $consumer
        Remote = $remote
        Source = $source
    }
}

function Invoke-BootstrapFixture {
    param($Fixture)

    $savedEnvironment = @{}
    foreach ($name in @('GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN', 'GITHUB_STEP_SUMMARY')) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
    }
    $savedLocation = Get-Location
    $result = [pscustomobject]@{ Threw = $false; Error = '' }
    try {
        $env:GITHUB_REPOSITORY = 'owner/consumer'
        $env:GITHUB_WORKSPACE = $Fixture.Consumer
        $env:DEFAULT_BRANCH = 'main'
        $env:GH_TOKEN = 'redacted-test-token'
        $env:GITHUB_STEP_SUMMARY = $null
        & $adapterPath -ProtocolSourcePath '.meandai-update-source' -TargetTag 'v0.5.0'
    }
    catch {
        $result.Threw = $true
        $result.Error = $_.Exception.Message
    }
    finally {
        Set-Location -LiteralPath $savedLocation
        foreach ($entry in $savedEnvironment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value)
        }
    }
    return $result
}

function Get-RemoteChangedPaths {
    param($Fixture)
    Invoke-Git -Repository $Fixture.Consumer -Arguments @('fetch', 'origin', 'automation/meandai-capabilities-v0.5.0') | Out-Null
    return @(Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'diff', '--name-only', 'main...FETCH_HEAD'
    ))
}

try {
    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $empty = New-BootstrapFixture -Name 'empty'
    $result = Invoke-BootstrapFixture -Fixture $empty
    if ($result.Threw) {
        Add-Failure "TEST-0028 collision-free bootstrap failed: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $empty)
        foreach ($required in @(
            '.ai/adoption/meandai-capabilities.json', '.ai/protocol', '.gitmodules',
            'AGENTS.md', '.ai/memory/README.md', 'docs/ideas/README.md',
            '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        )) {
            if ($paths -cnotcontains $required) {
                Add-Failure "TEST-0028 bootstrap proposal is missing '$required'"
            }
        }
        $protocolEntry = (Invoke-Git -Repository $empty.Consumer -Arguments @(
            'ls-tree', 'FETCH_HEAD', '--', '.ai/protocol'
        )) -join ''
        if ($protocolEntry -notmatch '^160000 commit [0-9a-f]{40}\t\.ai/protocol$') {
            Add-Failure 'TEST-0028 bootstrap proposal does not contain a protocol gitlink.'
        }
        if ($global:PullRequestCreateCalls -ne 1 -or
            -not $global:LastPullRequestBody.Contains('BootstrapReady') -or
            $global:LastPullRequestHead -cne 'automation/meandai-capabilities-v0.5.0') {
            Add-Failure 'TEST-0028 bootstrap did not create the deterministic draft proposal.'
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $ideasCollision = New-BootstrapFixture -Name 'ideas-collision' -AddIdeasCollision $true
    $result = Invoke-BootstrapFixture -Fixture $ideasCollision
    if ($result.Threw) {
        Add-Failure "TEST-0044 idea-index collision handoff failed: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $ideasCollision)
        if ($paths.Count -ne 1 -or
            [string]$paths[0] -cne '.ai/adoption/meandai-capabilities.json') {
            Add-Failure "TEST-0044 idea-index collision escaped manifest-only scope: $($paths -join ', ')."
        }
        $manifest = (Invoke-Git -Repository $ideasCollision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
        )) -join "`n" | ConvertFrom-Json
        if (@($manifest.collisions) -cnotcontains 'docs/ideas/README.md') {
            Add-Failure 'TEST-0044 manifest did not record the consumer idea-index collision.'
        }
        $consumerIdeas = (Invoke-Git -Repository $ideasCollision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:docs/ideas/README.md'
        )) -join "`n"
        if ($consumerIdeas -cne '# Consumer-owned ideas') {
            Add-Failure 'TEST-0044 collision proposal overwrote the consumer idea index.'
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $populated = New-BootstrapFixture -Name 'populated' -AddApplicationFile $true
    $result = Invoke-BootstrapFixture -Fixture $populated
    if ($result.Threw) {
        Add-Failure "TEST-0029 populated collision-free bootstrap failed: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $populated)
        if ($paths -ccontains 'src/app.txt') {
            Add-Failure 'TEST-0029 bootstrap modified unrelated application content.'
        }
        $app = (Invoke-Git -Repository $populated.Consumer -Arguments @(
            'show', 'FETCH_HEAD:src/app.txt'
        )) -join "`n"
        if ($app -cne 'consumer application') {
            Add-Failure 'TEST-0029 application content changed in the bootstrap branch.'
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $collision = New-BootstrapFixture -Name 'collision' -AddAgentsCollision $true
    $result = Invoke-BootstrapFixture -Fixture $collision
    if ($result.Threw) {
        Add-Failure "TEST-0030 collision handoff failed: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $collision)
        if ($paths.Count -ne 1 -or
            [string]$paths[0] -cne '.ai/adoption/meandai-capabilities.json') {
            Add-Failure "TEST-0030 collision proposal escaped manifest-only scope: $($paths -join ', ')."
        }
        $manifest = (Invoke-Git -Repository $collision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
        )) -join "`n" | ConvertFrom-Json
        if ([string]$manifest.state -cne 'AdoptionReviewRequired' -or
            @($manifest.collisions) -cnotcontains 'AGENTS.md') {
            Add-Failure 'TEST-0030 manifest did not record the exact adoption collision.'
        }
        $agents = (Invoke-Git -Repository $collision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:AGENTS.md'
        )) -join "`n"
        if ($agents -cne 'consumer-owned instructions') {
            Add-Failure 'TEST-0030 collision proposal overwrote consumer AGENTS.md.'
        }
    }

    $global:PullRequestExists = $false
    $manifestCollision = New-BootstrapFixture -Name 'manifest-collision' -AddManifestCollision $true
    $result = Invoke-BootstrapFixture -Fixture $manifestCollision
    if (-not $result.Threw -or $result.Error -notlike '*manifest*manual review*') {
        Add-Failure "TEST-0031 existing handoff manifest must block: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $seedDrift = New-BootstrapFixture -Name 'seed-drift' -DriftSeedWorkflow $true
    $result = Invoke-BootstrapFixture -Fixture $seedDrift
    if (-not $result.Threw -or $result.Error -notlike '*seed workflow*manual review*') {
        Add-Failure "TEST-0031 drifted seed workflow must block: $($result.Error)"
    }

    $global:PullRequestExists = $true
    $global:PullRequestCreateCalls = 0
    $pending = New-BootstrapFixture -Name 'pending'
    Invoke-Git -Repository $pending.Consumer -Arguments @('switch', '-c', 'automation/meandai-capabilities-v0.5.0') | Out-Null
    [IO.File]::WriteAllText((Join-Path $pending.Consumer 'pending.txt'), "pending`n")
    Invoke-Git -Repository $pending.Consumer -Arguments @('add', 'pending.txt') | Out-Null
    Invoke-Git -Repository $pending.Consumer -Arguments @('commit', '-m', 'Pending adoption') | Out-Null
    Invoke-Git -Repository $pending.Consumer -Arguments @('push', 'origin', 'automation/meandai-capabilities-v0.5.0') | Out-Null
    Invoke-Git -Repository $pending.Consumer -Arguments @('switch', 'main') | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $pending
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 0) {
        Add-Failure "TEST-0031 pending adoption should be retained without duplication: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $orphan = New-BootstrapFixture -Name 'orphan'
    Invoke-Git -Repository $orphan.Consumer -Arguments @('switch', '-c', 'automation/meandai-capabilities-v0.5.0') | Out-Null
    [IO.File]::WriteAllText((Join-Path $orphan.Consumer 'orphan.txt'), "orphan`n")
    Invoke-Git -Repository $orphan.Consumer -Arguments @('add', 'orphan.txt') | Out-Null
    Invoke-Git -Repository $orphan.Consumer -Arguments @('commit', '-m', 'Orphan adoption') | Out-Null
    Invoke-Git -Repository $orphan.Consumer -Arguments @('push', 'origin', 'automation/meandai-capabilities-v0.5.0') | Out-Null
    Invoke-Git -Repository $orphan.Consumer -Arguments @('switch', 'main') | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $orphan
    if (-not $result.Threw -or $result.Error -notlike '*orphan*manual review*') {
        Add-Failure "TEST-0031 orphan adoption branch must block: $($result.Error)"
    }
}
finally {
    Remove-Item Function:\gh -ErrorAction SilentlyContinue
    Get-ChildItem ([IO.Path]::GetTempPath()) -Directory -Filter 'meandai-capabilities-*' |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host "AI capabilities bootstrap adapter tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'AI capabilities bootstrap adapter tests passed: TEST-0028 through TEST-0031 and TEST-0044.' -ForegroundColor Green
