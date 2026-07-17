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
        'scripts/MeAndAI.ConsumerMigrations.psm1',
        'migrations/index.json',
        'migrations/MIG-0001.json',
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

function New-TestDirectoryLink {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Target
    )

    if ($env:OS -eq 'Windows_NT') {
        New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
    }
    else {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
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
        [bool]$AddAgentsCaseVariantCollision = $false,
        [bool]$AddIdeasCollision = $false,
        [bool]$AddManifestCollision = $false,
        [bool]$AddRenameSource = $false,
        [bool]$DriftSeedWorkflow = $false,
        [bool]$AddLinkedManagedAncestor = $false
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
    if ($AddAgentsCollision -or $AddAgentsCaseVariantCollision) {
        $agentsName = if ($AddAgentsCaseVariantCollision) { 'agents.md' } else { 'AGENTS.md' }
        [IO.File]::WriteAllText(
            (Join-Path $consumer $agentsName),
            "consumer-owned instructions`n"
        )
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
    $externalManaged = ''
    if ($AddLinkedManagedAncestor) {
        $externalManaged = Join-Path $tempRoot 'external-managed'
        New-Item -ItemType Directory -Path $externalManaged -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $externalManaged 'sentinel.txt'),
            "external sentinel`n"
        )
        New-TestDirectoryLink -Path (Join-Path $consumer '.ai') `
            -Target $externalManaged
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
        ExternalManaged = $externalManaged
    }
}

function Invoke-BootstrapFixture {
    param(
        $Fixture,
        [switch]$ValidateLocalUpdaterOnly
    )

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
        if ($ValidateLocalUpdaterOnly) {
            & $adapterPath -ProtocolSourcePath '.meandai-update-source' `
                -TargetTag 'v0.5.0' -ValidateLocalUpdaterOnly
        }
        else {
            & $adapterPath -ProtocolSourcePath '.meandai-update-source' `
                -TargetTag 'v0.5.0'
        }
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

function Install-CompleteLocalUpdaterFixture {
    param([Parameter(Mandatory)]$Fixture)

    $sourceSha = (@(Invoke-Git -Repository $Fixture.Source -Arguments @(
        'rev-parse', 'v0.5.0^{commit}'
    )))[0]
    $scriptsPath = Join-Path $Fixture.Consumer '.github/scripts'
    New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
    foreach ($name in @(
        'MeAndAI.ProtocolUpdate.psm1',
        'Invoke-MeAndAIProtocolUpdate.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $Fixture.Source `
            "templates/project/.github/scripts/$name") -Destination (Join-Path $scriptsPath $name)
    }
    $gitmodules = @(
        '[submodule ".ai/protocol"]',
        "`tpath = .ai/protocol",
        "`turl = https://github.com/hasanmanzak/meAndAI.git",
        ''
    ) -join "`n"
    [IO.File]::WriteAllText(
        (Join-Path $Fixture.Consumer '.gitmodules'), $gitmodules,
        [Text.UTF8Encoding]::new($false)
    )
    Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'update-index', '--add', '--cacheinfo', "160000,$sourceSha,.ai/protocol"
    ) | Out-Null
    Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'add', '--', '.gitmodules',
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    ) | Out-Null
    Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'commit', '-m', 'Install exact local updater fixture'
    ) | Out-Null
    Invoke-Git -Repository $Fixture.Consumer -Arguments @('push', 'origin', 'main') | Out-Null
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
    $trustedUpdater = New-BootstrapFixture -Name 'trusted-updater'
    Install-CompleteLocalUpdaterFixture -Fixture $trustedUpdater
    $result = Invoke-BootstrapFixture -Fixture $trustedUpdater -ValidateLocalUpdaterOnly
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 0) {
        Add-Failure "TEST-0077 exact local updater did not pass source-only preflight without mutation: $($result.Error)"
    }

    foreach ($assetName in @(
        'MeAndAI.ProtocolUpdate.psm1',
        'Invoke-MeAndAIProtocolUpdate.ps1'
    )) {
        foreach ($assetState in @('Missing', 'Drifted')) {
            $global:PullRequestExists = $false
            $global:PullRequestCreateCalls = 0
            $fixtureName = (($assetName -replace '[^A-Za-z0-9]', '-').ToLowerInvariant())
            $assetFixture = New-BootstrapFixture `
                -Name "updater-$fixtureName-$($assetState.ToLowerInvariant())"
            Install-CompleteLocalUpdaterFixture -Fixture $assetFixture
            $relativeAssetPath = ".github/scripts/$assetName"
            $assetPath = Join-Path $assetFixture.Consumer `
                ($relativeAssetPath -replace '/', [IO.Path]::DirectorySeparatorChar)
            if ($assetState -ceq 'Missing') {
                Invoke-Git -Repository $assetFixture.Consumer -Arguments @(
                    'rm', '--', $relativeAssetPath
                ) | Out-Null
            }
            else {
                [IO.File]::WriteAllText($assetPath, "# drifted updater asset`n")
                Invoke-Git -Repository $assetFixture.Consumer -Arguments @(
                    'add', '--', $relativeAssetPath
                ) | Out-Null
            }
            Invoke-Git -Repository $assetFixture.Consumer -Arguments @(
                'commit', '-m', "$assetState local updater asset $assetName"
            ) | Out-Null
            Invoke-Git -Repository $assetFixture.Consumer -Arguments @(
                'push', 'origin', 'main'
            ) | Out-Null
            $headBeforeValidation = (@(Invoke-Git -Repository $assetFixture.Consumer `
                -Arguments @('rev-parse', 'HEAD')))[0]
            $result = Invoke-BootstrapFixture -Fixture $assetFixture `
                -ValidateLocalUpdaterOnly
            $headAfterValidation = (@(Invoke-Git -Repository $assetFixture.Consumer `
                -Arguments @('rev-parse', 'HEAD')))[0]
            if (-not $result.Threw -or
                $result.Error -notlike '*local updater*match*pinned release*' -or
                $global:PullRequestCreateCalls -ne 0 -or
                $headAfterValidation -cne $headBeforeValidation) {
                Add-Failure "TEST-0077/TEST-0095 $assetState asset '$assetName' was not rejected without mutation: $($result.Error)"
            }
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $linkedAncestor = New-BootstrapFixture -Name 'linked-ancestor' `
        -AddLinkedManagedAncestor $true
    $externalBefore = @(
        Get-ChildItem -LiteralPath $linkedAncestor.ExternalManaged -Recurse -File |
            ForEach-Object {
                "$($_.FullName.Substring($linkedAncestor.ExternalManaged.Length + 1))=$([IO.File]::ReadAllText($_.FullName))"
            }
    )
    $result = Invoke-BootstrapFixture -Fixture $linkedAncestor
    $externalAfter = @(
        Get-ChildItem -LiteralPath $linkedAncestor.ExternalManaged -Recurse -File |
            ForEach-Object {
                "$($_.FullName.Substring($linkedAncestor.ExternalManaged.Length + 1))=$([IO.File]::ReadAllText($_.FullName))"
            }
    )
    if (-not $result.Threw -or
        $result.Error -notlike '*traverses linked or reparse-point path*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        ($externalBefore -join "`n") -cne ($externalAfter -join "`n")) {
        Add-Failure "TEST-0093 bootstrap did not block a linked managed ancestor before external mutation: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $missingMigrationModule = New-BootstrapFixture -Name 'missing-migration-module'
    Invoke-Git -Repository $missingMigrationModule.Source -Arguments @(
        'rm', '--', 'scripts/MeAndAI.ConsumerMigrations.psm1'
    ) | Out-Null
    Invoke-Git -Repository $missingMigrationModule.Source -Arguments @(
        'commit', '-m', 'Remove consumer migration module'
    ) | Out-Null
    Invoke-Git -Repository $missingMigrationModule.Source -Arguments @(
        'tag', '-f', 'v0.5.0'
    ) | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $missingMigrationModule
    $unexpectedMigrationModuleBranch = @(Invoke-Git `
        -Repository $missingMigrationModule.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*missing consumer migration module*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedMigrationModuleBranch.Count -ne 0) {
        Add-Failure "TEST-0028 full adoption did not fail closed on a missing migration module: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $invalidMigrationCatalog = New-BootstrapFixture -Name 'invalid-migration-catalog'
    [IO.File]::WriteAllText(
        (Join-Path $invalidMigrationCatalog.Source 'migrations/index.json'),
        "{`"schema`":99,`"migrations`":[]}`n",
        [Text.UTF8Encoding]::new($false)
    )
    Invoke-Git -Repository $invalidMigrationCatalog.Source -Arguments @(
        'add', '--', 'migrations/index.json'
    ) | Out-Null
    Invoke-Git -Repository $invalidMigrationCatalog.Source -Arguments @(
        'commit', '-m', 'Invalidate consumer migration catalog'
    ) | Out-Null
    Invoke-Git -Repository $invalidMigrationCatalog.Source -Arguments @(
        'tag', '-f', 'v0.5.0'
    ) | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $invalidMigrationCatalog
    $unexpectedMigrationCatalogBranch = @(Invoke-Git `
        -Repository $invalidMigrationCatalog.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*migration catalog index*unsupported schema*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedMigrationCatalogBranch.Count -ne 0) {
        Add-Failure "TEST-0028 full adoption did not fail closed on an invalid migration catalog: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $empty = New-BootstrapFixture -Name 'empty'
    $result = Invoke-BootstrapFixture -Fixture $empty
    if ($result.Threw) {
        Add-Failure "TEST-0028/TEST-0093 ordinary contained bootstrap failed: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $empty | Sort-Object)
        $expectedPaths = @(
            '.ai/adoption/meandai-capabilities.json', '.ai/memory/log/README.md',
            '.ai/meandai-update-state.json', '.ai/memory/project.md',
            '.ai/memory/README.md', '.ai/protocol',
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
        $ledger = (Invoke-Git -Repository $empty.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/meandai-update-state.json'
        )) -join "`n" | ConvertFrom-Json
        $definitionEntry = (Invoke-Git -Repository $empty.Source -Arguments @(
            'ls-tree', 'v0.5.0', '--', 'migrations/MIG-0001.json'
        )) -join ''
        $definitionBlob = if ($definitionEntry -match `
            '^100644 blob (?<sha>[0-9a-f]{40})\tmigrations/MIG-0001\.json$') {
            [string]$Matches.sha
        }
        else { '' }
        if (($ledger.schema -isnot [int] -and $ledger.schema -isnot [long]) -or
            [long]$ledger.schema -ne 1 -or
            $ledger.satisfied -isnot [array] -or
            @($ledger.satisfied).Count -ne 1 -or
            [string]$ledger.satisfied[0].id -cne 'MIG-0001' -or
            [string]$ledger.satisfied[0].definitionBlob -cne $definitionBlob) {
            Add-Failure 'TEST-0028 full adoption did not create the exact target-catalog migration baseline.'
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

    if (-not $result.Threw) {
        $completedBranch = 'automation/meandai-capabilities-v0.5.0'
        Invoke-Git -Repository $empty.Consumer -Arguments @(
            'switch', $completedBranch
        ) | Out-Null
        Invoke-Git -Repository $empty.Consumer -Arguments @(
            'rm', '.ai/adoption/meandai-capabilities.json'
        ) | Out-Null
        $completionEvidence = Join-Path $empty.Consumer 'docs/adoption-complete.md'
        [IO.Directory]::CreateDirectory((Split-Path -Parent $completionEvidence)) | Out-Null
        [IO.File]::WriteAllText($completionEvidence, "# Reviewed adoption`n")
        Invoke-Git -Repository $empty.Consumer -Arguments @(
            'add', 'docs/adoption-complete.md'
        ) | Out-Null
        Invoke-Git -Repository $empty.Consumer -Arguments @(
            'commit', '-m', 'Complete reviewed adoption proposal'
        ) | Out-Null
        Invoke-Git -Repository $empty.Consumer -Arguments @(
            'push', 'origin', $completedBranch
        ) | Out-Null
        $completedHead = (@(Invoke-Git -Repository $empty.Consumer -Arguments @(
            'rev-parse', 'HEAD'
        )))[0]
        $completedProtocolSha = (@(Invoke-Git -Repository $empty.Source -Arguments @(
            'rev-parse', 'v0.5.0^{commit}'
        )))[0]
        $completedMarker = [ordered]@{
            schema = 3
            phase = 'Completed'
            state = 'BootstrapReady'
            target = 'v0.5.0'
            protocolSha = $completedProtocolSha
            head = $completedHead
            repository = 'owner/consumer'
            actor = 'owner'
        } | ConvertTo-Json -Compress
        $global:PullRequestExists = $true
        $global:ExistingPullRequestHead = $completedHead
        $global:ExistingPullRequestProtocolSha = $completedProtocolSha
        $global:ExistingPullRequestBody = "<!-- meandai-capabilities-adoption:$completedMarker -->"
        $global:ExistingPullRequestIsDraft = $false
        $createCallsBeforeCompletedRerun = $global:PullRequestCreateCalls
        Invoke-Git -Repository $empty.Consumer -Arguments @('switch', 'main') | Out-Null
        $result = Invoke-BootstrapFixture -Fixture $empty
        $retainedHead = (@(Invoke-Git -Repository $empty.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin', "refs/heads/$completedBranch"
        )))[0]
        if ($result.Threw -or
            $global:PullRequestCreateCalls -ne $createCallsBeforeCompletedRerun -or
            $retainedHead -cnotmatch "^$completedHead\s+refs/heads/$([regex]::Escape($completedBranch))$" -or
            [string]$global:ExistingPullRequestBody -cne "<!-- meandai-capabilities-adoption:$completedMarker -->") {
            Add-Failure "TEST-0071 exact completed non-draft proposal was not retained without mutation: $($result.Error)"
        }

        if (-not $result.Threw) {
            $canonicalCompletedBody = [string]$global:ExistingPullRequestBody
            foreach ($completedVariant in @(
                'Parent', 'ProposalTree', 'CheckedChangeSet', 'Credential',
                'ProtectedWorkflow', 'Protocol', 'UpdaterModule', 'UpdaterAdapter',
                'Manifest'
            )) {
                $variantRoot = Join-Path $empty.Root `
                    "completed-$($completedVariant.ToLowerInvariant())-$([guid]::NewGuid().ToString('N'))"
                $variantClone = Join-Path $variantRoot 'clone'
                New-Item -ItemType Directory -Path $variantRoot -Force | Out-Null
                Invoke-Git -Repository $variantRoot -Arguments @(
                    'clone', $empty.Remote, $variantClone
                ) | Out-Null
                Invoke-Git -Repository $variantClone -Arguments @(
                    'config', 'user.name', 'Fixture'
                ) | Out-Null
                Invoke-Git -Repository $variantClone -Arguments @(
                    'config', 'user.email', 'fixture@example.invalid'
                ) | Out-Null
                Invoke-Git -Repository $variantClone -Arguments @(
                    'switch', $completedBranch
                ) | Out-Null
                $proposalHead = (@(Invoke-Git -Repository $variantClone -Arguments @(
                    'rev-parse', "$completedHead^"
                )))[0]
                switch ($completedVariant) {
                    'Parent' {
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--allow-empty', '-m', 'Drift completed parent'
                        ) | Out-Null
                    }
                    'ProposalTree' {
                        $canonicalCompletedTree = (@(Invoke-Git `
                            -Repository $variantClone -Arguments @(
                                'rev-parse', "$completedHead`^{tree}"
                            )))[0]
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'switch', '--detach', $proposalHead
                        ) | Out-Null
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone 'unexpected-proposal.txt'),
                            "unexpected proposal tree drift`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'unexpected-proposal.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                        $rewrittenProposalHead = (@(Invoke-Git `
                            -Repository $variantClone -Arguments @(
                                'rev-parse', 'HEAD'
                            )))[0]
                        $rewrittenCompletedHead = (@(Invoke-Git `
                            -Repository $variantClone -Arguments @(
                                'commit-tree', $canonicalCompletedTree,
                                '-p', $rewrittenProposalHead,
                                '-m', 'Complete rewritten proposal fixture'
                            )))[0]
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'switch', '-C', $completedBranch, $rewrittenCompletedHead
                        ) | Out-Null
                    }
                    'CheckedChangeSet' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone 'completion-whitespace.txt'),
                            "checked change-set drift   `n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'completion-whitespace.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'Credential' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone 'FG_PAT.txt'),
                            "credential-path-drift`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'FG_PAT.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'ProtectedWorkflow' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone '.github/workflows/meandai-protocol-update.yml'),
                            "name: protected drift`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', '.github/workflows/meandai-protocol-update.yml'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'Protocol' {
                        $wrongProtocolSha = (@(Invoke-Git -Repository $variantClone -Arguments @(
                            'rev-parse', 'origin/main'
                        )))[0]
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'update-index', '--add', '--cacheinfo',
                            "160000,$wrongProtocolSha,.ai/protocol"
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'UpdaterModule' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone '.github/scripts/MeAndAI.ProtocolUpdate.psm1'),
                            "# completed updater module drift`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'UpdaterAdapter' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'),
                            "# completed updater adapter drift`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'Manifest' {
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'checkout', $proposalHead, '--',
                            '.ai/adoption/meandai-capabilities.json'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                }
                Invoke-Git -Repository $variantClone -Arguments @(
                    'push', '--force', 'origin', $completedBranch
                ) | Out-Null
                $variantHead = (@(Invoke-Git -Repository $variantClone -Arguments @(
                    'rev-parse', 'HEAD'
                )))[0]
                $variantMarker = [ordered]@{
                    schema = 3
                    phase = 'Completed'
                    state = 'BootstrapReady'
                    target = 'v0.5.0'
                    protocolSha = $completedProtocolSha
                    head = $variantHead
                    repository = 'owner/consumer'
                    actor = 'owner'
                } | ConvertTo-Json -Compress
                $global:ExistingPullRequestHead = $variantHead
                $global:ExistingPullRequestBody = "<!-- meandai-capabilities-adoption:$variantMarker -->"
                $global:ExistingPullRequestIsDraft = $false
                $createCallsBeforeVariant = $global:PullRequestCreateCalls
                $variantResult = Invoke-BootstrapFixture -Fixture $empty
                $remoteAfterVariant = (@(Invoke-Git -Repository $empty.Consumer -Arguments @(
                    'ls-remote', '--heads', 'origin', "refs/heads/$completedBranch"
                )))[0]
                if (-not $variantResult.Threw -or
                    $global:PullRequestCreateCalls -ne $createCallsBeforeVariant -or
                    $remoteAfterVariant -cnotmatch "^$variantHead\s") {
                    Add-Failure "TEST-0094 bootstrap retained drifted Completed variant '$completedVariant': $($variantResult.Error)"
                }
                Invoke-Git -Repository $variantClone -Arguments @(
                    'push', '--force', 'origin',
                    "$completedHead`:refs/heads/$completedBranch"
                ) | Out-Null
                $global:ExistingPullRequestHead = $completedHead
                $global:ExistingPullRequestBody = $canonicalCompletedBody
            }
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
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
    $global:PullRequestCreateCalls = 0
    $caseCollision = New-BootstrapFixture -Name 'case-collision' `
        -AddAgentsCaseVariantCollision $true
    $result = Invoke-BootstrapFixture -Fixture $caseCollision
    if ($result.Threw) {
        Add-Failure "TEST-0030/TEST-0095 case-variant collision handoff failed: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $caseCollision)
        $manifest = (Invoke-Git -Repository $caseCollision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
        )) -join "`n" | ConvertFrom-Json
        $caseAgents = (Invoke-Git -Repository $caseCollision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:agents.md'
        )) -join "`n"
        if ($paths.Count -ne 1 -or
            [string]$paths[0] -cne '.ai/adoption/meandai-capabilities.json' -or
            @($manifest.collisions) -cnotcontains 'agents.md' -or
            $caseAgents -cne 'consumer-owned instructions') {
            Add-Failure 'TEST-0030/TEST-0095 case-variant collision was not preserved as a manifest-only proposal.'
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
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $manifestRename = New-BootstrapFixture -Name 'manifest-rename-source' `
        -AddAgentsCollision $true -AddRenameSource $true
    $result = Invoke-BootstrapFixture -Fixture $manifestRename
    if ($result.Threw) {
        Add-Failure "TEST-0062 manifest-only rename fixture could not create its first proposal: $($result.Error)"
    }
    else {
        $manifestBranch = 'automation/meandai-capabilities-v0.5.0'
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'fetch', 'origin', $manifestBranch
        ) | Out-Null
        $manifestText = (@(Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
        )) -join "`n") + "`n"
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @('switch', 'main') | Out-Null
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'push', 'origin', '--delete', $manifestBranch
        ) | Out-Null
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'branch', '-D', $manifestBranch
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $manifestRename.Consumer 'legacy-agents.md'),
            $manifestText,
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'add', 'legacy-agents.md'
        ) | Out-Null
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'commit', '-m', 'Prepare manifest rename source'
        ) | Out-Null
        Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
            'push', 'origin', 'main'
        ) | Out-Null
        $global:PullRequestExists = $false
        $global:ExistingPullRequestBody = ''
        $result = Invoke-BootstrapFixture -Fixture $manifestRename
        if ($result.Threw) {
            Add-Failure "TEST-0062 manifest-only rename fixture could not recreate its proposal: $($result.Error)"
        }
        else {
            Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
                'switch', $manifestBranch
            ) | Out-Null
            Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
                'rm', 'legacy-agents.md'
            ) | Out-Null
            Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
                'commit', '--amend', '--no-edit'
            ) | Out-Null
            Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
                'push', '--force', 'origin', $manifestBranch
            ) | Out-Null
            $global:ExistingPullRequestHead = (@(Invoke-Git `
                -Repository $manifestRename.Consumer -Arguments @('rev-parse', 'HEAD')))[0]
            $global:ExistingPullRequestProtocolSha = (@(Invoke-Git `
                -Repository $manifestRename.Source -Arguments @(
                    'rev-parse', 'v0.5.0^{commit}'
                )))[0]
            $global:ExistingPullRequestBody = ''
            $global:PullRequestExists = $true
            Invoke-Git -Repository $manifestRename.Consumer -Arguments @('switch', 'main') | Out-Null
            Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
                'fetch', 'origin', $manifestBranch
            ) | Out-Null
            $manifestRenameStatus = @(Invoke-Git -Repository $manifestRename.Consumer -Arguments @(
                'diff', '--no-renames', '--name-status', 'main', 'FETCH_HEAD', '--'
            ))
            if ($manifestRenameStatus -cnotcontains "D`tlegacy-agents.md" -or
                $manifestRenameStatus -cnotcontains "A`t.ai/adoption/meandai-capabilities.json") {
                Add-Failure 'TEST-0062 real Git fixture did not expose both sides of the manifest-only rename provenance.'
            }
            $result = Invoke-BootstrapFixture -Fixture $manifestRename
            if (-not $result.Threw -or $result.Error -notlike '*ownership*manual review*') {
                Add-Failure "TEST-0062 manifest-only rename-away proposal was retained: $($result.Error)"
            }
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $reservedNamespace = New-BootstrapFixture -Name 'reserved-namespace'
    $staleReservedBranch = 'automation/meandai-capabilities-v0.4.0'
    Invoke-Git -Repository $reservedNamespace.Consumer -Arguments @(
        'switch', '-c', $staleReservedBranch
    ) | Out-Null
    [IO.File]::WriteAllText(
        (Join-Path $reservedNamespace.Consumer 'stale-adoption.txt'),
        "stale`n"
    )
    Invoke-Git -Repository $reservedNamespace.Consumer -Arguments @(
        'add', 'stale-adoption.txt'
    ) | Out-Null
    Invoke-Git -Repository $reservedNamespace.Consumer -Arguments @(
        'commit', '-m', 'Create stale reserved adoption branch'
    ) | Out-Null
    Invoke-Git -Repository $reservedNamespace.Consumer -Arguments @(
        'push', 'origin', $staleReservedBranch
    ) | Out-Null
    Invoke-Git -Repository $reservedNamespace.Consumer -Arguments @('switch', 'main') | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $reservedNamespace
    $unexpectedTarget = @(Invoke-Git -Repository $reservedNamespace.Consumer -Arguments @(
        'ls-remote', '--heads', 'origin', 'refs/heads/automation/meandai-capabilities-v0.5.0'
    ))
    if (-not $result.Threw -or
        $result.Error -notlike '*reserved adoption branch namespace*unowned or stale*' -or
        $global:PullRequestCreateCalls -ne 0 -or $unexpectedTarget.Count -ne 0) {
        Add-Failure "TEST-0072 stale branch outside the current adoption target did not block before mutation: $($result.Error)"
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
