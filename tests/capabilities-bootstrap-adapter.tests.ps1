[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$failures = [System.Collections.Generic.List[string]]::new()
$tempRoots = [System.Collections.Generic.List[string]]::new()
$cleanupSentinel = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-capabilities-foreign-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $cleanupSentinel -Force | Out-Null
$global:PullRequestExists = $false
$global:PullRequestCreateCalls = 0
$global:LastPullRequestBody = ''
$global:LastPullRequestHead = ''
$global:ExistingPullRequestMetadataMode = 'Valid'
$global:ExistingPullRequestHead = ''
$global:ExistingPullRequestProtocolSha = ''
$global:ExistingPullRequestBody = ''
$global:ExistingPullRequestIsDraft = $true
$global:PostCreateRaceApplied = $false

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
    if (($arguments -join ' ') -ceq 'api user --jq .login') {
        'owner'
        return
    }
    if ($arguments[0] -eq 'pr' -and $arguments[1] -eq 'list') {
        if ($global:PullRequestExists) {
            if ($global:ExistingPullRequestMetadataMode -ceq 'PostCreateRace' -and
                -not $global:PostCreateRaceApplied) {
                $racePath = Join-Path $env:GITHUB_WORKSPACE 'post-create-race.txt'
                [IO.File]::WriteAllText($racePath, "race`n")
                Invoke-Git -Repository $env:GITHUB_WORKSPACE -Arguments @(
                    'add', 'post-create-race.txt'
                ) | Out-Null
                Invoke-Git -Repository $env:GITHUB_WORKSPACE -Arguments @(
                    'commit', '-m', 'Simulate post-create race'
                ) | Out-Null
                Invoke-Git -Repository $env:GITHUB_WORKSPACE -Arguments @(
                    'push', 'origin', 'automation/meandai-capabilities-v0.5.0'
                ) | Out-Null
                $global:ExistingPullRequestHead = (@(Invoke-Git `
                    -Repository $env:GITHUB_WORKSPACE -Arguments @(
                        'rev-parse', 'HEAD'
                    )))[0]
                $global:PostCreateRaceApplied = $true
            }
            $body = $global:ExistingPullRequestBody
            if ([string]::IsNullOrWhiteSpace($body)) {
                $marker = [ordered]@{
                    schema = 2
                    state = 'BootstrapReady'
                    target = 'v0.5.0'
                    protocolSha = $global:ExistingPullRequestProtocolSha
                    head = $global:ExistingPullRequestHead
                    repository = 'owner/consumer'
                    actor = 'owner'
                } | ConvertTo-Json -Compress
                $body = "<!-- meandai-capabilities-adoption:$marker -->"
            }
            $pullRequest = [ordered]@{
                number = 40
                url = 'https://github.com/owner/consumer/pull/40'
                headRefName = 'automation/meandai-capabilities-v0.5.0'
                headRefOid = $global:ExistingPullRequestHead
                baseRefName = 'main'
                headRepository = [ordered]@{ nameWithOwner = 'owner/consumer' }
                author = [ordered]@{ login = 'owner' }
                body = $body
                isDraft = $global:ExistingPullRequestIsDraft
                state = 'OPEN'
            }
            if ($global:ExistingPullRequestMetadataMode -ceq 'WrongAuthor') {
                $pullRequest.author = [ordered]@{ login = 'untrusted-actor' }
            }
            if ($global:ExistingPullRequestMetadataMode -ceq 'MovedHead') {
                $pullRequest.headRefOid = 'ffffffffffffffffffffffffffffffffffffffff'
            }
            @($pullRequest) | ConvertTo-Json -Depth 5 -Compress
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
        $global:ExistingPullRequestBody = $global:LastPullRequestBody
        $global:ExistingPullRequestHead = (@(Invoke-Git `
            -Repository $env:GITHUB_WORKSPACE -Arguments @('rev-parse', 'HEAD')))[0]
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
        [bool]$AddRenameSource = $false,
        [bool]$DriftSeedWorkflow = $false
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-capabilities-$Name-$([guid]::NewGuid().ToString('N'))"
    $tempRoots.Add($tempRoot)
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
    if ($AddRenameSource) {
        Copy-Item -LiteralPath (Join-Path $root 'templates/project/AGENTS.submodule.md') `
            -Destination (Join-Path $consumer 'legacy-agents.md')
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
        $paths = @(Get-RemoteChangedPaths -Fixture $empty | Sort-Object)
        $expectedPaths = @(
            '.ai/adoption/meandai-capabilities.json', '.ai/memory/log/README.md',
            '.ai/memory/project.md', '.ai/memory/README.md', '.ai/protocol',
            '.github/ISSUE_TEMPLATE/bug.yml', '.github/ISSUE_TEMPLATE/epic.yml',
            '.github/ISSUE_TEMPLATE/feature.yml', '.github/ISSUE_TEMPLATE/finding.yml',
            '.github/ISSUE_TEMPLATE/subfeature.yml', '.github/ISSUE_TEMPLATE/task.yml',
            '.github/PULL_REQUEST_TEMPLATE.md',
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
            '.github/scripts/MeAndAI.ProtocolUpdate.psm1', '.gitmodules',
            'AGENTS.md', 'docs/ideas/README.md'
        ) | Sort-Object
        if (($paths -join '|') -cne ($expectedPaths -join '|')) {
            Add-Failure "TEST-0066 bootstrap proposal asset inventory is not exact: $($paths -join ', ')."
        }
        $protocolEntry = (Invoke-Git -Repository $empty.Consumer -Arguments @(
            'ls-tree', 'FETCH_HEAD', '--', '.ai/protocol'
        )) -join ''
        if ($protocolEntry -notmatch '^160000 commit [0-9a-f]{40}\t\.ai/protocol$') {
            Add-Failure 'TEST-0028 bootstrap proposal does not contain a protocol gitlink.'
        }
        if ($global:PullRequestCreateCalls -ne 1 -or
            -not $global:LastPullRequestBody.Contains('BootstrapReady') -or
            -not $global:LastPullRequestBody.Contains('"schema":3') -or
            -not $global:LastPullRequestBody.Contains('"phase":"Proposed"') -or
            -not $global:LastPullRequestBody.Contains('"actor":"owner"') -or
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

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestMetadataMode = 'Valid'
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $global:PostCreateRaceApplied = $false
    $pending = New-BootstrapFixture -Name 'pending'
    $global:ExistingPullRequestProtocolSha = (@(Invoke-Git -Repository $pending.Source -Arguments @(
        'rev-parse', 'v0.5.0^{commit}'
    )))[0]
    $result = Invoke-BootstrapFixture -Fixture $pending
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 1) {
        Add-Failure "TEST-0057 exact pending-adoption fixture creation failed: $($result.Error)"
    }
    Invoke-Git -Repository $pending.Consumer -Arguments @('switch', 'main') | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $pending
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 1) {
        Add-Failure "TEST-0057 exact pending draft should be retained without duplication: $($result.Error)"
    }

    $schema3Body = $global:ExistingPullRequestBody
    $legacyMarker = [ordered]@{
        schema = 2
        state = 'BootstrapReady'
        target = 'v0.5.0'
        protocolSha = $global:ExistingPullRequestProtocolSha
        head = $global:ExistingPullRequestHead
        repository = 'owner/consumer'
        actor = 'owner'
    } | ConvertTo-Json -Compress
    $global:ExistingPullRequestBody = "<!-- meandai-capabilities-adoption:$legacyMarker -->"
    $result = Invoke-BootstrapFixture -Fixture $pending
    if ($result.Threw) {
        Add-Failure "TEST-0057 exact legacy schema-2 proposal should remain retainable: $($result.Error)"
    }
    $global:ExistingPullRequestBody = $schema3Body

    $global:ExistingPullRequestIsDraft = $false
    $result = Invoke-BootstrapFixture -Fixture $pending
    if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
        Add-Failure "TEST-0057 non-draft proposal must block: $($result.Error)"
    }
    $global:ExistingPullRequestIsDraft = $true

    $global:ExistingPullRequestMetadataMode = 'MovedHead'
    $result = Invoke-BootstrapFixture -Fixture $pending
    if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
        Add-Failure "TEST-0057 moved proposal head must block: $($result.Error)"
    }

    $global:ExistingPullRequestMetadataMode = 'WrongAuthor'
    $result = Invoke-BootstrapFixture -Fixture $pending
    if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
        Add-Failure "TEST-0047 untrusted existing proposal ownership must block: $($result.Error)"
    }
    $global:ExistingPullRequestMetadataMode = 'Valid'

    Invoke-Git -Repository $pending.Consumer -Arguments @(
        'switch', 'automation/meandai-capabilities-v0.5.0'
    ) | Out-Null
    Invoke-Git -Repository $pending.Consumer -Arguments @(
        'rm', '.ai/adoption/meandai-capabilities.json'
    ) | Out-Null
    Invoke-Git -Repository $pending.Consumer -Arguments @(
        'commit', '--amend', '--no-edit'
    ) | Out-Null
    Invoke-Git -Repository $pending.Consumer -Arguments @(
        'push', '--force-with-lease', 'origin',
        'automation/meandai-capabilities-v0.5.0'
    ) | Out-Null
    $global:ExistingPullRequestHead = (@(Invoke-Git `
        -Repository $pending.Consumer -Arguments @('rev-parse', 'HEAD')))[0]
    $global:ExistingPullRequestBody = ''
    Invoke-Git -Repository $pending.Consumer -Arguments @('switch', 'main') | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $pending
    if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
        Add-Failure "TEST-0057 proposal missing its manifest must block: $($result.Error)"
    }

    $global:PullRequestExists = $true
    $global:ExistingPullRequestMetadataMode = 'Valid'
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $arbitrary = New-BootstrapFixture -Name 'arbitrary-pending'
    Invoke-Git -Repository $arbitrary.Consumer -Arguments @(
        'switch', '-c', 'automation/meandai-capabilities-v0.5.0'
    ) | Out-Null
    [IO.File]::WriteAllText((Join-Path $arbitrary.Consumer 'pending.txt'), "pending`n")
    Invoke-Git -Repository $arbitrary.Consumer -Arguments @('add', 'pending.txt') | Out-Null
    Invoke-Git -Repository $arbitrary.Consumer -Arguments @(
        'commit', '-m', 'Arbitrary pending content'
    ) | Out-Null
    Invoke-Git -Repository $arbitrary.Consumer -Arguments @(
        'push', 'origin', 'automation/meandai-capabilities-v0.5.0'
    ) | Out-Null
    $global:ExistingPullRequestHead = (@(Invoke-Git `
        -Repository $arbitrary.Consumer -Arguments @('rev-parse', 'HEAD')))[0]
    $global:ExistingPullRequestProtocolSha = (@(Invoke-Git `
        -Repository $arbitrary.Source -Arguments @('rev-parse', 'v0.5.0^{commit}')))[0]
    Invoke-Git -Repository $arbitrary.Consumer -Arguments @('switch', 'main') | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $arbitrary
    if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
        Add-Failure "TEST-0057 arbitrary branch content must not be retained: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestMetadataMode = 'PostCreateRace'
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $global:PostCreateRaceApplied = $false
    $race = New-BootstrapFixture -Name 'post-create-race'
    $result = Invoke-BootstrapFixture -Fixture $race
    if (-not $result.Threw -or
        $result.Error -notlike '*post-publication validation*') {
        Add-Failure "TEST-0057 post-create head race must block: $($result.Error)"
    }
    $global:ExistingPullRequestMetadataMode = 'Valid'

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestMetadataMode = 'Valid'
    $global:ExistingPullRequestBody = ''
    $rename = New-BootstrapFixture -Name 'rename-source' -AddRenameSource $true
    $result = Invoke-BootstrapFixture -Fixture $rename
    if ($result.Threw) {
        Add-Failure "TEST-0062 rename provenance fixture could not create its baseline proposal: $($result.Error)"
    }
    else {
        Invoke-Git -Repository $rename.Consumer -Arguments @(
            'switch', 'automation/meandai-capabilities-v0.5.0'
        ) | Out-Null
        Invoke-Git -Repository $rename.Consumer -Arguments @('rm', 'legacy-agents.md') | Out-Null
        Invoke-Git -Repository $rename.Consumer -Arguments @(
            'commit', '--amend', '--no-edit'
        ) | Out-Null
        Invoke-Git -Repository $rename.Consumer -Arguments @(
            'push', '--force', 'origin', 'automation/meandai-capabilities-v0.5.0'
        ) | Out-Null
        $global:ExistingPullRequestHead = (@(Invoke-Git `
            -Repository $rename.Consumer -Arguments @('rev-parse', 'HEAD')))[0]
        $global:ExistingPullRequestProtocolSha = (@(Invoke-Git `
            -Repository $rename.Source -Arguments @('rev-parse', 'v0.5.0^{commit}')))[0]
        $global:ExistingPullRequestBody = ''
        Invoke-Git -Repository $rename.Consumer -Arguments @('switch', 'main') | Out-Null
        Invoke-Git -Repository $rename.Consumer -Arguments @(
            'fetch', 'origin', 'automation/meandai-capabilities-v0.5.0'
        ) | Out-Null
        $renameStatus = @(Invoke-Git -Repository $rename.Consumer -Arguments @(
            'diff', '--name-status', '--find-renames', 'main', 'FETCH_HEAD', '--'
        ))
        if (@($renameStatus | Where-Object {
            [string]$_ -match '^R100\s+legacy-agents\.md\s+AGENTS\.md$'
        }).Count -ne 1) {
            Add-Failure 'TEST-0062 real Git fixture did not form the intended rename-away provenance.'
        }
        $result = Invoke-BootstrapFixture -Fixture $rename
        if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
            Add-Failure "TEST-0062 rename-away proposal was retained: $($result.Error)"
        }
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
    foreach ($path in $tempRoots) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    if (-not (Test-Path -LiteralPath $cleanupSentinel -PathType Container)) {
        Add-Failure 'TEST-0068 cleanup removed an unowned same-prefix temporary directory.'
    }
    elseif (Test-Path -LiteralPath $cleanupSentinel) {
        Remove-Item -LiteralPath $cleanupSentinel -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failures.Count -gt 0) {
    Write-Host "AI capabilities bootstrap adapter tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'AI capabilities bootstrap adapter tests passed for all declared scenarios in this suite.' -ForegroundColor Green
