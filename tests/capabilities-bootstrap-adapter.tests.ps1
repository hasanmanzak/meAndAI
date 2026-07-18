[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$consumerMigrationModulePath = Join-Path $root `
    'scripts/MeAndAI.ConsumerMigrations.psm1'
$consumerMigrationIndexPath = Join-Path $root 'migrations/index.json'
Import-Module $consumerMigrationModulePath -Force
$consumerMigrationCatalog = Import-MeAndAIConsumerMigrationCatalog `
    -IndexPath $consumerMigrationIndexPath
$consumerMigrationBaseline = New-MeAndAIConsumerMigrationBaseline `
    -Catalog $consumerMigrationCatalog
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
$global:AdvanceDefaultBranchOnCreate = $false
$global:RenameDefaultBranchOnCreate = $false
$global:PullRequestCloseCalls = 0
$global:LiveDefaultBranch = 'main'

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

function Install-ApplicationInjectingPreCommitHook {
    param([Parameter(Mandatory)][string]$Repository)

    $hookPath = (@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', '--git-path', 'hooks/pre-commit'
    )))[0]
    if (-not [IO.Path]::IsPathRooted($hookPath)) {
        $hookPath = Join-Path $Repository $hookPath
    }
    $hookText = @(
        '#!/bin/sh',
        'mkdir -p src',
        "printf 'hook injected\n' > src/hook-injected.txt",
        'git add -- src/hook-injected.txt',
        ''
    ) -join "`n"
    [IO.File]::WriteAllText(
        $hookPath, $hookText, [Text.UTF8Encoding]::new($false)
    )
    if ($env:OS -ne 'Windows_NT') {
        & chmod +x $hookPath
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to make the pre-commit regression hook executable.'
        }
    }
}

function global:gh {
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0
    if (($arguments -join ' ') -ceq 'api user --jq .login') {
        'owner'
        return
    }
    if ($arguments[0] -eq 'repo' -and $arguments[1] -eq 'view') {
        [ordered]@{
            nameWithOwner = 'owner/consumer'
            defaultBranchRef = [ordered]@{ name = $global:LiveDefaultBranch }
        } | ConvertTo-Json -Compress
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
        if ($global:RenameDefaultBranchOnCreate) {
            $global:LiveDefaultBranch = 'trunk'
        }
        if ($global:AdvanceDefaultBranchOnCreate) {
            $raceRoot = Join-Path ([IO.Path]::GetTempPath()) `
                "meandai-base-race-$([guid]::NewGuid().ToString('N'))"
            $tempRoots.Add($raceRoot)
            $raceClone = Join-Path $raceRoot 'clone'
            New-Item -ItemType Directory -Path $raceRoot -Force | Out-Null
            $remote = (@(Invoke-Git -Repository $env:GITHUB_WORKSPACE `
                -Arguments @('remote', 'get-url', 'origin')))[0]
            Invoke-Git -Repository $raceRoot -Arguments @(
                'clone', '--branch', 'main', $remote, $raceClone
            ) | Out-Null
            Invoke-Git -Repository $raceClone -Arguments @(
                'config', 'user.name', 'Base Race'
            ) | Out-Null
            Invoke-Git -Repository $raceClone -Arguments @(
                'config', 'user.email', 'base-race@example.invalid'
            ) | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $raceClone 'base-race.txt'), "advanced`n"
            )
            Invoke-Git -Repository $raceClone -Arguments @(
                'add', 'base-race.txt'
            ) | Out-Null
            Invoke-Git -Repository $raceClone -Arguments @(
                'commit', '-m', 'Advance default branch during PR creation'
            ) | Out-Null
            Invoke-Git -Repository $raceClone -Arguments @(
                'push', 'origin', 'main'
            ) | Out-Null
        }
        'https://github.com/owner/consumer/pull/40'
        return
    }
    if ($arguments[0] -eq 'pr' -and $arguments[1] -eq 'close') {
        $global:PullRequestCloseCalls++
        $global:PullRequestExists = $false
        'Closed adoption race fixture'
        return
    }
    throw "Unexpected fake gh command: $($arguments -join ' ')"
}

function New-BootstrapFixture {
    param(
        [string]$Name,
        [bool]$AddApplicationFile = $false,
        [bool]$AddAgentsCollision = $false,
        [bool]$AddClaudeCollision = $false,
        [ValidateSet('None', 'Cursor', 'Windsurf', 'CursorRootGitlink',
            'GithubInstructions', 'GithubInstructionsRootGitlink')]
        [string]$LegacyRuleSurface = 'None',
        [string[]]$NestedProtocolSurfaces = @(),
        [bool]$AddAgentsCaseVariantCollision = $false,
        [bool]$AddIdeasCollision = $false,
        [bool]$AddPullRequestTemplateCollision = $false,
        [bool]$AddManifestCollision = $false,
        [bool]$AddRenameSource = $false,
        [bool]$DriftSeedWorkflow = $false,
        [bool]$AddSeedWorkflowCaseVariant = $false,
        [bool]$AddProtocolTargetCaseVariant = $false,
        [bool]$AddReservedProtocolSubmoduleCollision = $false,
        [ValidateSet('None', 'AliasExactPath', 'CaseVariant', 'Ancestor',
            'Descendant')]
        [string]$ReservedProtocolSubmoduleCollision = 'None',
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

    $workflowRelativePath = if ($AddSeedWorkflowCaseVariant) {
        '.github/workflows/MeAndAI-protocol-update.yml'
    }
    else { '.github/workflows/meandai-protocol-update.yml' }
    $workflowTarget = Join-Path $consumer $workflowRelativePath
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
    if ($AddClaudeCollision) {
        [IO.File]::WriteAllText(
            (Join-Path $consumer 'CLAUDE.md'),
            "consumer-owned Claude directives`n"
        )
    }
    if ($LegacyRuleSurface -cin @(
        'Cursor', 'Windsurf', 'GithubInstructions'
    )) {
        $legacyRulePath = switch ($LegacyRuleSurface) {
            'Cursor' { '.cursor/rules/consumer.mdc' }
            'Windsurf' { '.windsurf/rules/consumer.md' }
            'GithubInstructions' {
                '.github/instructions/foo.instructions.md'
            }
        }
        $legacyRuleTarget = Join-Path $consumer `
            ($legacyRulePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Force `
            (Split-Path -Parent $legacyRuleTarget) | Out-Null
        [IO.File]::WriteAllText(
            $legacyRuleTarget,
            "consumer-owned legacy rule authority`n"
        )
    }
    foreach ($nestedProtocolSurface in @($NestedProtocolSurfaces)) {
        $nestedProtocolTarget = Join-Path $consumer `
            ($nestedProtocolSurface -replace '/',
                [IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Force `
            (Split-Path -Parent $nestedProtocolTarget) | Out-Null
        [IO.File]::WriteAllText(
            $nestedProtocolTarget,
            "consumer-owned nested protocol directive: $nestedProtocolSurface`n"
        )
    }

    if ($AddIdeasCollision) {
        $ideasPath = Join-Path $consumer 'docs/ideas/README.md'
        New-Item -ItemType Directory -Force (Split-Path -Parent $ideasPath) | Out-Null
        [IO.File]::WriteAllText($ideasPath, "# Consumer-owned ideas`n")
    }
    if ($AddPullRequestTemplateCollision) {
        $pullRequestTemplate = Join-Path $consumer '.github/PULL_REQUEST_TEMPLATE.md'
        New-Item -ItemType Directory -Force `
            (Split-Path -Parent $pullRequestTemplate) | Out-Null
        [IO.File]::WriteAllText(
            $pullRequestTemplate,
            "# Consumer pull request template`n"
        )
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
    if ($AddProtocolTargetCaseVariant) {
        $caseVariantPath = Join-Path $consumer '.AI/protocol'
        New-Item -ItemType Directory -Force `
            (Split-Path -Parent $caseVariantPath) | Out-Null
        [IO.File]::WriteAllText($caseVariantPath, "consumer case variant`n")
    }
    if ($AddReservedProtocolSubmoduleCollision -or
        $ReservedProtocolSubmoduleCollision -cne 'None') {
        $reservedGitmodules = if ($AddReservedProtocolSubmoduleCollision) {
            @(
                '[submodule ".ai/protocol"]',
                "`tpath = vendor/product",
                "`turl = https://example.invalid/product.git",
                ''
            ) -join "`n"
        }
        else {
            $subsection = if ($ReservedProtocolSubmoduleCollision -ceq
                'CaseVariant') { '.AI/Protocol' } else { 'consumer-alias' }
            $reservedPath = switch ($ReservedProtocolSubmoduleCollision) {
                'AliasExactPath' { '.ai/protocol' }
                'CaseVariant' { '.AI/Protocol' }
                'Ancestor' { '.ai' }
                'Descendant' { '.ai/protocol/vendor' }
            }
            @(
                "[submodule `"$subsection`"]",
                "`tpath = $reservedPath",
                "`turl = https://example.invalid/product.git",
                ''
            ) -join "`n"
        }
        [IO.File]::WriteAllText(
            (Join-Path $consumer '.gitmodules'), $reservedGitmodules,
            [Text.UTF8Encoding]::new($false)
        )
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
    if ($LegacyRuleSurface -cin @(
        'CursorRootGitlink', 'GithubInstructionsRootGitlink'
    )) {
        $gitlinkPath = if ($LegacyRuleSurface -ceq 'CursorRootGitlink') {
            '.cursor/rules'
        }
        else { '.github/instructions' }
        $gitlinkSourceFile = if ($LegacyRuleSurface -ceq
            'CursorRootGitlink') { 'consumer.mdc' }
        else { 'foo.instructions.md' }
        $legacyRuleSource = Join-Path $tempRoot `
            "legacy-$($LegacyRuleSurface.ToLowerInvariant())-source"
        New-Item -ItemType Directory -Force $legacyRuleSource | Out-Null
        Invoke-Git -Repository $legacyRuleSource -Arguments @(
            'init', '-b', 'main'
        ) | Out-Null
        Invoke-Git -Repository $legacyRuleSource -Arguments @(
            'config', 'user.name', 'Fixture'
        ) | Out-Null
        Invoke-Git -Repository $legacyRuleSource -Arguments @(
            'config', 'user.email', 'fixture@example.invalid'
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $legacyRuleSource $gitlinkSourceFile),
            "consumer-owned legacy rule authority`n"
        )
        Invoke-Git -Repository $legacyRuleSource -Arguments @(
            'add', $gitlinkSourceFile
        ) | Out-Null
        Invoke-Git -Repository $legacyRuleSource -Arguments @(
            'commit', '-m', 'Seed exact cursor rule root'
        ) | Out-Null
        $legacyRuleSha = (@(Invoke-Git -Repository $legacyRuleSource `
            -Arguments @('rev-parse', 'HEAD')))[0]
        Invoke-Git -Repository $consumer -Arguments @(
            'fetch', '--no-tags', $legacyRuleSource, 'refs/heads/main'
        ) | Out-Null
        Invoke-Git -Repository $consumer -Arguments @(
            'update-index', '--add', '--cacheinfo',
            "160000,$legacyRuleSha,$gitlinkPath"
        ) | Out-Null
        Invoke-Git -Repository $consumer -Arguments @(
            'commit', '--amend', '--no-edit'
        ) | Out-Null
    }
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
        [ValidateSet('Auto', 'FreshAdoption', 'FullMigration',
            'HybridReconciliation', 'CleanStart', 'Abort')]
        [string]$AdoptionStrategy = 'Auto',
        [switch]$AcknowledgeProtocolRecordLoss,
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
            if ($AcknowledgeProtocolRecordLoss) {
                & $adapterPath -ProtocolSourcePath '.meandai-update-source' `
                    -TargetTag 'v0.5.0' -AdoptionStrategy $AdoptionStrategy `
                    -AcknowledgeProtocolRecordLoss
            }
            else {
                & $adapterPath -ProtocolSourcePath '.meandai-update-source' `
                    -TargetTag 'v0.5.0' -AdoptionStrategy $AdoptionStrategy
            }
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

function Set-ExistingSchema5AdoptionMarker {
    param(
        [Parameter(Mandatory)][string]$Head,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [ValidateSet('Proposed', 'Completed')]
        [string]$Phase,
        [ValidateSet('BootstrapReady', 'AdoptionReviewRequired')]
        [string]$State,
        [ValidateSet('FullMigration', 'HybridReconciliation', 'CleanStart')]
        [string]$Strategy,
        [Parameter(Mandatory)][string[]]$ProtocolSurfaces,
        [bool]$ProtocolRecordLossAcknowledged
    )

    $marker = [ordered]@{
        schema = 5
        phase = $Phase
        state = $State
        target = 'v0.5.0'
        protocolSha = $ProtocolSha
        head = $Head
        adoptionStrategy = $Strategy
        protocolSurfaces = @($ProtocolSurfaces)
        protocolRecordLossAcknowledged = $ProtocolRecordLossAcknowledged
        repository = 'owner/consumer'
        actor = 'owner'
    } | ConvertTo-Json -Compress
    $global:PullRequestExists = $true
    $global:ExistingPullRequestHead = $Head
    $global:ExistingPullRequestProtocolSha = $ProtocolSha
    $global:ExistingPullRequestBody = `
        "<!-- meandai-capabilities-adoption:$marker -->"
    $global:ExistingPullRequestIsDraft = $Phase -ceq 'Proposed'
    return [string]$global:ExistingPullRequestBody
}

function Install-StrategyCompletionTree {
    param(
        [Parameter(Mandatory)]$Fixture,
        [ValidateSet('FullMigration', 'HybridReconciliation', 'CleanStart')]
        [string]$Strategy,
        [string]$LegacyRuleSurfacePath = '',
        [string[]]$NestedProtocolSurfacePaths = @(),
        [bool]$HasAgentsCollision = $true
    )

    $completionAssets = @(
        [pscustomobject]@{ Consumer = 'AGENTS.md'; Source = 'templates/project/AGENTS.submodule.md' },
        [pscustomobject]@{ Consumer = '.ai/memory/README.md'; Source = 'templates/project/.ai/memory/README.md' },
        [pscustomobject]@{ Consumer = '.ai/memory/project.md'; Source = 'templates/project/.ai/memory/project.md' },
        [pscustomobject]@{ Consumer = '.ai/memory/log/README.md'; Source = 'templates/project/.ai/memory/log/README.md' },
        [pscustomobject]@{ Consumer = 'docs/ideas/README.md'; Source = 'templates/project/docs/ideas/README.md' },
        [pscustomobject]@{ Consumer = '.github/ISSUE_TEMPLATE/bug.yml'; Source = '.github/ISSUE_TEMPLATE/bug.yml' },
        [pscustomobject]@{ Consumer = '.github/ISSUE_TEMPLATE/epic.yml'; Source = '.github/ISSUE_TEMPLATE/epic.yml' },
        [pscustomobject]@{ Consumer = '.github/ISSUE_TEMPLATE/feature.yml'; Source = '.github/ISSUE_TEMPLATE/feature.yml' },
        [pscustomobject]@{ Consumer = '.github/ISSUE_TEMPLATE/finding.yml'; Source = '.github/ISSUE_TEMPLATE/finding.yml' },
        [pscustomobject]@{ Consumer = '.github/ISSUE_TEMPLATE/subfeature.yml'; Source = '.github/ISSUE_TEMPLATE/subfeature.yml' },
        [pscustomobject]@{ Consumer = '.github/ISSUE_TEMPLATE/task.yml'; Source = '.github/ISSUE_TEMPLATE/task.yml' },
        [pscustomobject]@{ Consumer = '.github/PULL_REQUEST_TEMPLATE.md'; Source = '.github/PULL_REQUEST_TEMPLATE.md' },
        [pscustomobject]@{ Consumer = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'; Source = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1' },
        [pscustomobject]@{ Consumer = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'; Source = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1' }
    )
    $stagedPaths = [System.Collections.Generic.List[string]]::new()
    foreach ($asset in $completionAssets) {
        $source = Join-Path $Fixture.Source `
            (([string]$asset.Source) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $destination = Join-Path $Fixture.Consumer `
            (([string]$asset.Consumer) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Copy-Item -LiteralPath $source -Destination $destination -Force
        $stagedPaths.Add([string]$asset.Consumer)
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
    $stagedPaths.Add('.gitmodules')
    $ledgerPath = Join-Path $Fixture.Consumer `
        '.ai/meandai-update-state.json'
    $ledgerParent = Split-Path -Parent $ledgerPath
    if (-not (Test-Path -LiteralPath $ledgerParent -PathType Container)) {
        New-Item -ItemType Directory -Path $ledgerParent -Force | Out-Null
    }
    [IO.File]::WriteAllBytes(
        $ledgerPath, [byte[]]$consumerMigrationBaseline.Bytes
    )
    $stagedPaths.Add('.ai/meandai-update-state.json')

    $manifestPath = Join-Path $Fixture.Consumer `
        '.ai/adoption/meandai-capabilities.json'
    Remove-Item -LiteralPath $manifestPath -Force
    $stagedPaths.Add('.ai/adoption/meandai-capabilities.json')
    $stagedPaths.Add('CLAUDE.md')
    if (-not [string]::IsNullOrWhiteSpace($LegacyRuleSurfacePath)) {
        $stagedPaths.Add($LegacyRuleSurfacePath)
    }
    foreach ($nestedProtocolSurface in @($NestedProtocolSurfacePaths)) {
        $stagedPaths.Add($nestedProtocolSurface)
        $nestedProtocolTarget = Join-Path $Fixture.Consumer `
            ($nestedProtocolSurface -replace '/',
                [IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $nestedProtocolTarget) {
            Remove-Item -LiteralPath $nestedProtocolTarget -Force
        }
    }
    if ($Strategy -ceq 'HybridReconciliation') {
        [IO.File]::WriteAllText(
            (Join-Path $Fixture.Consumer 'CLAUDE.md'),
            "Project-specific directives retained: consumer-owned instructions; consumer-owned Claude directives. AGENTS.md and the pinned meAndAI protocol take precedence for common rules.`n"
        )
        $decisionPath = Join-Path $Fixture.Consumer `
            'docs/decisions/DEC-0001-hybrid-protocol-precedence.md'
        New-Item -ItemType Directory -Path (Split-Path -Parent $decisionPath) `
            -Force | Out-Null
        [IO.File]::WriteAllText(
            $decisionPath,
            "# DEC-0001 - Hybrid protocol precedence`n`nThe pinned meAndAI protocol owns common rules; CLAUDE.md owns project-specific directives only.`n"
        )
        $stagedPaths.Add(
            'docs/decisions/DEC-0001-hybrid-protocol-precedence.md'
        )
        if (-not [string]::IsNullOrWhiteSpace($LegacyRuleSurfacePath)) {
            $legacyRuleTarget = Join-Path $Fixture.Consumer `
                ($LegacyRuleSurfacePath -replace '/',
                    [IO.Path]::DirectorySeparatorChar)
            [IO.File]::WriteAllText(
                $legacyRuleTarget,
                "Project-specific directive retained: consumer-owned legacy rule authority. AGENTS.md and the pinned meAndAI protocol take precedence for common rules.`n"
            )
        }
    }
    else {
        Remove-Item -LiteralPath (Join-Path $Fixture.Consumer 'CLAUDE.md') `
            -Force
        $evidenceName = if ($Strategy -ceq 'FullMigration') {
            'full-migration.md'
        }
        else { 'clean-start.md' }
        $evidencePath = Join-Path $Fixture.Consumer `
            "docs/governance/$evidenceName"
        New-Item -ItemType Directory -Path (Split-Path -Parent $evidencePath) `
            -Force | Out-Null
        $evidenceText = if ($Strategy -ceq 'FullMigration') {
            $preservedDirectives = @('consumer-owned Claude directives')
            if ($HasAgentsCollision) {
                $preservedDirectives += 'consumer-owned instructions'
            }
            "# Full migration evidence`n`nPreserved repository directives: $($preservedDirectives -join '; '). They were reviewed and rehomed before the legacy common authority was retired.`n"
        }
        else {
            "# Clean-start evidence`n`nLegacy governance records were deliberately excluded under the acknowledged clean-start strategy.`n"
        }
        if ($Strategy -ceq 'FullMigration' -and
            -not [string]::IsNullOrWhiteSpace($LegacyRuleSurfacePath)) {
            $evidenceText += "Preserved legacy rule directive: consumer-owned legacy rule authority.`n"
        }
        if ($Strategy -ceq 'FullMigration' -and
            @($NestedProtocolSurfacePaths).Count -gt 0) {
            $evidenceText += "Preserved nested protocol directives: $(@($NestedProtocolSurfacePaths) -join '; ').`n"
        }
        [IO.File]::WriteAllText($evidencePath, $evidenceText)
        $stagedPaths.Add("docs/governance/$evidenceName")
        if (-not [string]::IsNullOrWhiteSpace($LegacyRuleSurfacePath)) {
            $legacyRuleTarget = Join-Path $Fixture.Consumer `
                ($LegacyRuleSurfacePath -replace '/',
                    [IO.Path]::DirectorySeparatorChar)
            if (Test-Path -LiteralPath $legacyRuleTarget) {
                Remove-Item -LiteralPath $legacyRuleTarget -Force
            }
        }
    }

    Invoke-Git -Repository $Fixture.Consumer -Arguments `
        (@('add', '--all', '--') + @($stagedPaths)) | Out-Null
    $targetSha = (@(Invoke-Git -Repository $Fixture.Source -Arguments @(
        'rev-parse', 'v0.5.0^{commit}'
    )))[0]
    Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'update-index', '--add', '--cacheinfo',
        "160000,$targetSha,.ai/protocol"
    ) | Out-Null
    Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'commit', '-m', "Complete $Strategy adoption fixture"
    ) | Out-Null
    Invoke-Git -Repository $Fixture.Consumer -Arguments @(
        'push', 'origin', 'automation/meandai-capabilities-v0.5.0'
    ) | Out-Null
    return [pscustomobject]@{
        Head = (@(Invoke-Git -Repository $Fixture.Consumer -Arguments @(
            'rev-parse', 'HEAD'
        )))[0]
        ProtocolSha = $targetSha
    }
}

function New-CompletedStrategyFixture {
    param(
        [ValidateSet('FullMigration', 'HybridReconciliation', 'CleanStart')]
        [string]$Strategy,
        [ValidateSet('None', 'Cursor', 'Windsurf', 'CursorRootGitlink',
            'GithubInstructions', 'GithubInstructionsRootGitlink')]
        [string]$LegacyRuleSurface = 'None',
        [string[]]$NestedProtocolSurfaces = @(),
        [bool]$AddAgentsCollision = $true,
        [switch]$ExercisePartitionSmuggling
    )

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $fixture = New-BootstrapFixture `
        -Name "completed-$($Strategy.ToLowerInvariant())" `
        -AddApplicationFile $true -AddAgentsCollision $AddAgentsCollision `
        -AddClaudeCollision $true -LegacyRuleSurface $LegacyRuleSurface `
        -NestedProtocolSurfaces @($NestedProtocolSurfaces)
    $acknowledged = $Strategy -ceq 'CleanStart'
    $initial = if ($acknowledged) {
        Invoke-BootstrapFixture -Fixture $fixture -AdoptionStrategy $Strategy `
            -AcknowledgeProtocolRecordLoss
    }
    else {
        Invoke-BootstrapFixture -Fixture $fixture -AdoptionStrategy $Strategy
    }
    if ($initial.Threw) {
        throw "$Strategy schema-5 proposal creation failed: $($initial.Error)"
    }
    $branch = 'automation/meandai-capabilities-v0.5.0'
    $proposalHead = [string]$global:ExistingPullRequestHead
    $protocolSha = (@(Invoke-Git -Repository $fixture.Source -Arguments @(
        'rev-parse', 'v0.5.0^{commit}'
    )))[0]
    $canonicalProposedBody = [string]$global:ExistingPullRequestBody
    $proposalMarkerMatch = [regex]::Match(
        $canonicalProposedBody,
        '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->'
    )
    if (-not $proposalMarkerMatch.Success) {
        throw "$Strategy schema-5 proposal marker could not be parsed."
    }
    $proposalMarker = $proposalMarkerMatch.Groups['json'].Value |
        ConvertFrom-Json
    $proposalState = [string]$proposalMarker.state
    $expectedProposalState = if ($AddAgentsCollision -or
        @($NestedProtocolSurfaces).Count -gt 0) {
        'AdoptionReviewRequired'
    }
    else { 'BootstrapReady' }
    if ([long]$proposalMarker.schema -ne 5 -or
        [string]$proposalMarker.phase -cne 'Proposed' -or
        $proposalState -cne $expectedProposalState -or
        [string]$proposalMarker.adoptionStrategy -cne $Strategy) {
        throw "$Strategy proposal did not publish the expected schema-5 $expectedProposalState state."
    }
    $legacyRuleSurfacePath = switch ($LegacyRuleSurface) {
        'Cursor' { '.cursor/rules/consumer.mdc' }
        'Windsurf' { '.windsurf/rules/consumer.md' }
        'CursorRootGitlink' { '.cursor/rules' }
        'GithubInstructions' {
            '.github/instructions/foo.instructions.md'
        }
        'GithubInstructionsRootGitlink' { '.github/instructions' }
        default { '' }
    }
    $surfaces = @('CLAUDE.md')
    if ($AddAgentsCollision) { $surfaces += 'AGENTS.md' }
    if (-not [string]::IsNullOrWhiteSpace($legacyRuleSurfacePath)) {
        $surfaces += $legacyRuleSurfacePath
    }
    $surfaces += @($NestedProtocolSurfaces)
    [Array]::Sort($surfaces, [StringComparer]::Ordinal)

    if ($ExercisePartitionSmuggling) {
        [void](Set-ExistingSchema5AdoptionMarker `
            -Head $proposalHead -ProtocolSha $protocolSha -Phase 'Proposed' `
            -State $proposalState `
            -Strategy $Strategy `
            -ProtocolSurfaces @("AGENTS.md`nCLAUDE.md") `
            -ProtocolRecordLossAcknowledged $acknowledged)
        Invoke-Git -Repository $fixture.Consumer -Arguments @(
            'switch', 'main'
        ) | Out-Null
        $createCallsBeforeSmuggling = $global:PullRequestCreateCalls
        $smuggled = if ($acknowledged) {
            Invoke-BootstrapFixture -Fixture $fixture `
                -AdoptionStrategy $Strategy -AcknowledgeProtocolRecordLoss
        }
        else {
            Invoke-BootstrapFixture -Fixture $fixture `
                -AdoptionStrategy $Strategy
        }
        $remoteProposal = (@(Invoke-Git -Repository $fixture.Consumer `
            -Arguments @(
                'ls-remote', '--heads', 'origin', "refs/heads/$branch"
            )))[0]
        if (-not $smuggled.Threw -or
            $smuggled.Error -notlike '*ownership*manual review*' -or
            $global:PullRequestCreateCalls -ne $createCallsBeforeSmuggling -or
            $remoteProposal -cnotmatch "^$proposalHead\s") {
            Add-Failure "TEST-0128 a newline-partitioned schema-5 surface marker was retained against two canonical expected surfaces: $($smuggled.Error)"
        }
        $global:ExistingPullRequestBody = $canonicalProposedBody
        $global:ExistingPullRequestIsDraft = $true
        $global:ExistingPullRequestHead = $proposalHead
    }

    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'switch', $branch
    ) | Out-Null
    $completion = Install-StrategyCompletionTree -Fixture $fixture `
        -Strategy $Strategy -LegacyRuleSurfacePath $legacyRuleSurfacePath `
        -NestedProtocolSurfacePaths @($NestedProtocolSurfaces) `
        -HasAgentsCollision $AddAgentsCollision
    $completedBody = Set-ExistingSchema5AdoptionMarker `
        -Head ([string]$completion.Head) `
        -ProtocolSha ([string]$completion.ProtocolSha) -Phase 'Completed' `
        -State $proposalState `
        -Strategy $Strategy -ProtocolSurfaces $surfaces `
        -ProtocolRecordLossAcknowledged $acknowledged
    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'switch', 'main'
    ) | Out-Null
    $createCallsBeforeCompletion = $global:PullRequestCreateCalls
    $completed = if ($acknowledged) {
        Invoke-BootstrapFixture -Fixture $fixture -AdoptionStrategy $Strategy `
            -AcknowledgeProtocolRecordLoss
    }
    else {
        Invoke-BootstrapFixture -Fixture $fixture -AdoptionStrategy $Strategy
    }
    if ($completed.Threw -or
        $global:PullRequestCreateCalls -ne $createCallsBeforeCompletion -or
        [string]$global:ExistingPullRequestBody -cne $completedBody) {
        Add-Failure "TEST-0128 valid schema-5 $Strategy Completed proposal was not retained: $($completed.Error)"
    }
    return [pscustomobject]@{
        Fixture = $fixture
        Strategy = $Strategy
        Acknowledged = $acknowledged
        Surfaces = $surfaces
        Branch = $branch
        Head = [string]$completion.Head
        ProtocolSha = [string]$completion.ProtocolSha
        State = $proposalState
        LegacyRuleSurfacePath = $legacyRuleSurfacePath
        NestedProtocolSurfacePaths = @($NestedProtocolSurfaces)
    }
}

function Assert-InvalidCompletedStrategyState {
    param(
        [Parameter(Mandatory)]$CompletedFixture,
        [ValidateSet('RetainedCommonAuthority', 'UnchangedRequiredSurface',
            'RetainedRuleAuthority', 'UnchangedRuleAuthority')]
        [string]$Variant
    )

    $fixture = $CompletedFixture.Fixture
    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'switch', [string]$CompletedFixture.Branch
    ) | Out-Null
    $path = switch ($Variant) {
        'UnchangedRequiredSurface' { 'AGENTS.md' }
        { $_ -cin @('RetainedRuleAuthority', 'UnchangedRuleAuthority') } {
            [string]$CompletedFixture.LegacyRuleSurfacePath
        }
        default { 'CLAUDE.md' }
    }
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "Completed strategy variant '$Variant' requires a legacy rule surface."
    }
    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'checkout', 'main', '--', $path
    ) | Out-Null
    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'commit', '--amend', '--no-edit'
    ) | Out-Null
    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'push', '--force', 'origin', [string]$CompletedFixture.Branch
    ) | Out-Null
    $variantHead = (@(Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'rev-parse', 'HEAD'
    )))[0]
    [void](Set-ExistingSchema5AdoptionMarker `
        -Head $variantHead -ProtocolSha ([string]$CompletedFixture.ProtocolSha) `
        -Phase 'Completed' -Strategy ([string]$CompletedFixture.Strategy) `
        -State ([string]$CompletedFixture.State) `
        -ProtocolSurfaces @($CompletedFixture.Surfaces) `
        -ProtocolRecordLossAcknowledged ([bool]$CompletedFixture.Acknowledged))
    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'switch', 'main'
    ) | Out-Null
    $createCallsBeforeVariant = $global:PullRequestCreateCalls
    $result = if ([bool]$CompletedFixture.Acknowledged) {
        Invoke-BootstrapFixture -Fixture $fixture `
            -AdoptionStrategy ([string]$CompletedFixture.Strategy) `
            -AcknowledgeProtocolRecordLoss
    }
    else {
        Invoke-BootstrapFixture -Fixture $fixture `
            -AdoptionStrategy ([string]$CompletedFixture.Strategy)
    }
    $remoteHead = (@(Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'ls-remote', '--heads', 'origin',
        "refs/heads/$([string]$CompletedFixture.Branch)"
    )))[0]
    if (-not $result.Threw -or
        $result.Error -notlike '*ownership*manual review*' -or
        $global:PullRequestCreateCalls -ne $createCallsBeforeVariant -or
        $remoteHead -cnotmatch "^$variantHead\s") {
        Add-Failure "TEST-0129 $($CompletedFixture.Strategy) Completed variant '$Variant' was not rejected without replacement publication: $($result.Error)"
    }
}

function Assert-UndeclaredNestedProtocolDeletion {
    param([Parameter(Mandatory)]$CompletedFixture)

    $nestedSurfaces = @($CompletedFixture.NestedProtocolSurfacePaths)
    if ($nestedSurfaces.Count -lt 2) {
        throw 'Undeclared nested protocol coverage requires two assessed paths.'
    }
    $undeclaredPath = [string]$nestedSurfaces[-1]
    $declaredSurfaces = @($CompletedFixture.Surfaces | Where-Object {
        [string]$_ -cne $undeclaredPath
    })
    [void](Set-ExistingSchema5AdoptionMarker `
        -Head ([string]$CompletedFixture.Head) `
        -ProtocolSha ([string]$CompletedFixture.ProtocolSha) `
        -Phase 'Completed' -Strategy ([string]$CompletedFixture.Strategy) `
        -State ([string]$CompletedFixture.State) `
        -ProtocolSurfaces $declaredSurfaces `
        -ProtocolRecordLossAcknowledged ([bool]$CompletedFixture.Acknowledged))
    Invoke-Git -Repository $CompletedFixture.Fixture.Consumer -Arguments @(
        'switch', 'main'
    ) | Out-Null
    $createCallsBeforeVariant = $global:PullRequestCreateCalls
    $result = Invoke-BootstrapFixture `
        -Fixture $CompletedFixture.Fixture `
        -AdoptionStrategy ([string]$CompletedFixture.Strategy)
    $remoteHead = (@(Invoke-Git `
        -Repository $CompletedFixture.Fixture.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            "refs/heads/$([string]$CompletedFixture.Branch)"
        )))[0]
    if (-not $result.Threw -or
        $result.Error -notlike '*ownership*manual review*' -or
        $global:PullRequestCreateCalls -ne $createCallsBeforeVariant -or
        $remoteHead -cnotmatch "^$([string]$CompletedFixture.Head)\s") {
        Add-Failure "TEST-0129 undeclared nested protocol deletion '$undeclaredPath' was not rejected without replacement publication: $($result.Error)"
    }
}

try {
    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $seedCaseVariant = New-BootstrapFixture -Name 'seed-case-variant' `
        -AddSeedWorkflowCaseVariant $true
    $result = Invoke-BootstrapFixture -Fixture $seedCaseVariant `
        -AdoptionStrategy 'FullMigration'
    $unexpectedSeedCaseBranch = @(Invoke-Git `
        -Repository $seedCaseVariant.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*noncanonical casing*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedSeedCaseBranch.Count -ne 0) {
        Add-Failure "TEST-0128 case-variant lifecycle workflow was not rejected without proposal mutation: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $targetCaseVariant = New-BootstrapFixture -Name 'target-case-variant' `
        -AddProtocolTargetCaseVariant $true
    $result = Invoke-BootstrapFixture -Fixture $targetCaseVariant `
        -AdoptionStrategy 'FullMigration'
    $unexpectedTargetCaseBranch = @(Invoke-Git `
        -Repository $targetCaseVariant.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*noncanonical casing*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedTargetCaseBranch.Count -ne 0) {
        Add-Failure "TEST-0127 canonical target ancestor case variant was not rejected without proposal mutation: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $reservedSubmodule = New-BootstrapFixture -Name 'reserved-submodule' `
        -AddReservedProtocolSubmoduleCollision $true
    $result = Invoke-BootstrapFixture -Fixture $reservedSubmodule `
        -AdoptionStrategy 'FullMigration'
    $unexpectedReservedBranch = @(Invoke-Git `
        -Repository $reservedSubmodule.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*reserved .gitmodules subsection*consumer-owned*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedReservedBranch.Count -ne 0) {
        Add-Failure "TEST-0129 reserved protocol submodule collision was not rejected before proposal mutation: $($result.Error)"
    }

    foreach ($reservedVariant in @(
        'AliasExactPath', 'CaseVariant', 'Ancestor', 'Descendant'
    )) {
        $global:PullRequestExists = $false
        $global:PullRequestCreateCalls = 0
        $global:ExistingPullRequestBody = ''
        $global:ExistingPullRequestIsDraft = $true
        $inverseReserved = New-BootstrapFixture `
            -Name "reserved-$($reservedVariant.ToLowerInvariant())" `
            -ReservedProtocolSubmoduleCollision $reservedVariant
        $result = Invoke-BootstrapFixture -Fixture $inverseReserved `
            -AdoptionStrategy 'FullMigration'
        $inverseReservedBranch = @(Invoke-Git `
            -Repository $inverseReserved.Consumer -Arguments @(
                'ls-remote', '--heads', 'origin',
                'refs/heads/automation/meandai-capabilities-v0.5.0'
            ))
        if (-not $result.Threw -or
            $result.Error -notlike `
                '*reserved .gitmodules subsection*consumer-owned*' -or
            $global:PullRequestCreateCalls -ne 0 -or
            $inverseReservedBranch.Count -ne 0) {
            Add-Failure "TEST-0129 reserved protocol submodule inverse '$reservedVariant' was not rejected before branch/PR mutation: $($result.Error)"
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $hookInjection = New-BootstrapFixture -Name 'hook-injection'
    Install-ApplicationInjectingPreCommitHook `
        -Repository $hookInjection.Consumer
    $result = Invoke-BootstrapFixture -Fixture $hookInjection
    $unexpectedHookBranch = @(Invoke-Git `
        -Repository $hookInjection.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*committed adoption proposal escaped*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedHookBranch.Count -ne 0) {
        Add-Failure "TEST-0128 pre-commit application injection escaped committed-tree validation: $($result.Error)"
    }

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

    $evidenceFreeMigration = New-BootstrapFixture `
        -Name 'evidence-free-explicit-migration'
    $evidenceFreeHead = (@(Invoke-Git `
        -Repository $evidenceFreeMigration.Consumer `
        -Arguments @('rev-parse', 'HEAD')))[0]
    foreach ($evidenceFreeStrategy in @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )) {
        $global:PullRequestExists = $false
        $global:PullRequestCreateCalls = 0
        $result = if ($evidenceFreeStrategy -ceq 'CleanStart') {
            Invoke-BootstrapFixture -Fixture $evidenceFreeMigration `
                -AdoptionStrategy $evidenceFreeStrategy `
                -AcknowledgeProtocolRecordLoss
        }
        else {
            Invoke-BootstrapFixture -Fixture $evidenceFreeMigration `
                -AdoptionStrategy $evidenceFreeStrategy
        }
        $evidenceFreeHeadAfter = (@(Invoke-Git `
            -Repository $evidenceFreeMigration.Consumer `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $unexpectedEvidenceFreeBranch = @(Invoke-Git `
            -Repository $evidenceFreeMigration.Consumer -Arguments @(
                'ls-remote', '--heads', 'origin',
                'refs/heads/automation/meandai-capabilities-v0.5.0'
            ))
        if (-not $result.Threw -or
            $result.Error -notlike '*requires detected protocol or governance evidence*use FreshAdoption*' -or
            $global:PullRequestCreateCalls -ne 0 -or
            $unexpectedEvidenceFreeBranch.Count -ne 0 -or
            $evidenceFreeHeadAfter -cne $evidenceFreeHead) {
            Add-Failure "TEST-0128 evidence-free $evidenceFreeStrategy was not rejected before proposal mutation: $($result.Error)"
        }
    }

    foreach ($autoRuleCase in @(
        [pscustomobject]@{
            Name = 'exact-cursor-rule-root-auto'
            Surface = 'CursorRootGitlink'
            Label = '.cursor/rules gitlink'
            Path = '.cursor/rules'
        },
        [pscustomobject]@{
            Name = 'exact-github-instructions-root-auto'
            Surface = 'GithubInstructionsRootGitlink'
            Label = '.github/instructions gitlink'
            Path = '.github/instructions'
        },
        [pscustomobject]@{
            Name = 'github-instructions-descendant-auto'
            Surface = 'GithubInstructions'
            Label = '.github/instructions descendant'
            Path = '.github/instructions/foo.instructions.md'
        }
    )) {
        $global:PullRequestExists = $false
        $global:PullRequestCreateCalls = 0
        $autoRuleFixture = New-BootstrapFixture `
            -Name ([string]$autoRuleCase.Name) `
            -LegacyRuleSurface ([string]$autoRuleCase.Surface)
        $result = Invoke-BootstrapFixture -Fixture $autoRuleFixture
        $unexpectedAutoRuleBranch = @(Invoke-Git `
            -Repository $autoRuleFixture.Consumer -Arguments @(
                'ls-remote', '--heads', 'origin',
                'refs/heads/automation/meandai-capabilities-v0.5.0'
            ))
        if (-not $result.Threw -or
            $result.Error -notlike '*explicit adoption strategy*' -or
            $result.Error -notlike "*$([string]$autoRuleCase.Path)*" -or
            $global:PullRequestCreateCalls -ne 0 -or
            $unexpectedAutoRuleBranch.Count -ne 0) {
            Add-Failure "TEST-0128 $($autoRuleCase.Label) did not trigger the Auto migration gate before mutation: $($result.Error)"
        }
    }

    foreach ($strategy in @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )) {
        try {
            $completedStrategy = New-CompletedStrategyFixture `
                -Strategy $strategy `
                -ExercisePartitionSmuggling:($strategy -ceq 'FullMigration')
            $invalidVariant = if ($strategy -ceq 'HybridReconciliation') {
                'UnchangedRequiredSurface'
            }
            else { 'RetainedCommonAuthority' }
            Assert-InvalidCompletedStrategyState `
                -CompletedFixture $completedStrategy -Variant $invalidVariant
        }
        catch {
            Add-Failure "TEST-0128/TEST-0129 genuine schema-5 $strategy Completed fixture could not be constructed: $($_.Exception.Message)"
        }
    }
    foreach ($legacyRuleCase in @(
        [pscustomobject]@{
            Strategy = 'FullMigration'
            Surface = 'Cursor'
            Variant = 'RetainedRuleAuthority'
        },
        [pscustomobject]@{
            Strategy = 'HybridReconciliation'
            Surface = 'Windsurf'
            Variant = 'UnchangedRuleAuthority'
        },
        [pscustomobject]@{
            Strategy = 'FullMigration'
            Surface = 'CursorRootGitlink'
            Variant = 'RetainedRuleAuthority'
        },
        [pscustomobject]@{
            Strategy = 'CleanStart'
            Surface = 'CursorRootGitlink'
            Variant = ''
        },
        [pscustomobject]@{
            Strategy = 'FullMigration'
            Surface = 'GithubInstructionsRootGitlink'
            Variant = 'RetainedRuleAuthority'
        },
        [pscustomobject]@{
            Strategy = 'HybridReconciliation'
            Surface = 'GithubInstructions'
            Variant = 'UnchangedRuleAuthority'
        },
        [pscustomobject]@{
            Strategy = 'CleanStart'
            Surface = 'GithubInstructionsRootGitlink'
            Variant = ''
        }
    )) {
        try {
            $completedRuleStrategy = New-CompletedStrategyFixture `
                -Strategy ([string]$legacyRuleCase.Strategy) `
                -LegacyRuleSurface ([string]$legacyRuleCase.Surface)
            if (-not [string]::IsNullOrWhiteSpace(
                    [string]$legacyRuleCase.Variant)) {
                Assert-InvalidCompletedStrategyState `
                    -CompletedFixture $completedRuleStrategy `
                    -Variant ([string]$legacyRuleCase.Variant)
            }
        }
        catch {
            Add-Failure "TEST-0129 schema-5 $($legacyRuleCase.Strategy) legacy-rule fixture could not be constructed: $($_.Exception.Message)"
        }
    }
    try {
        [void](New-CompletedStrategyFixture -Strategy 'FullMigration' `
            -AddAgentsCollision $false)
    }
    catch {
        Add-Failure "TEST-0128 schema-5 BootstrapReady FullMigration completion fixture could not be constructed: $($_.Exception.Message)"
    }
    try {
        $nestedProtocolStrategy = New-CompletedStrategyFixture `
            -Strategy 'FullMigration' -NestedProtocolSurfaces @(
                '.ai/protocol/legacy-a.md',
                '.ai/protocol/legacy-b.md'
            )
        Assert-UndeclaredNestedProtocolDeletion `
            -CompletedFixture $nestedProtocolStrategy
    }
    catch {
        Add-Failure "TEST-0129 schema-5 nested .ai/protocol recovery fixture could not be constructed: $($_.Exception.Message)"
    }
    $global:PullRequestExists = $false
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $global:ExistingPullRequestMetadataMode = 'Valid'

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $linkedAncestor = New-BootstrapFixture -Name 'linked-ancestor' `
        -AddLinkedManagedAncestor $true -AddAgentsCollision $true
    $externalBefore = @(
        Get-ChildItem -LiteralPath $linkedAncestor.ExternalManaged -Recurse -File |
            ForEach-Object {
                "$($_.FullName.Substring($linkedAncestor.ExternalManaged.Length + 1))=$([IO.File]::ReadAllText($_.FullName))"
            }
    )
    $result = Invoke-BootstrapFixture -Fixture $linkedAncestor `
        -AdoptionStrategy 'FullMigration'
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
    $empty = New-BootstrapFixture -Name 'empty' -AddApplicationFile $true
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
        $manifest = (Invoke-Git -Repository $empty.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
        )) -join "`n" | ConvertFrom-Json
        if ([long]$manifest.schema -ne 2 -or
            [string]$manifest.adoptionStrategy -cne 'FreshAdoption' -or
            $manifest.protocolRecordLossAcknowledged -isnot [bool] -or
            [bool]$manifest.protocolRecordLossAcknowledged -or
            @($manifest.protocolSurfaces).Count -ne 0) {
            Add-Failure 'TEST-0128 fresh proposal did not bind the exact strategy, loss, and surface identity.'
        }
        if ($global:PullRequestCreateCalls -ne 1 -or
            -not $global:LastPullRequestBody.Contains('BootstrapReady') -or
            -not $global:LastPullRequestBody.Contains('"schema":5') -or
            -not $global:LastPullRequestBody.Contains('"phase":"Proposed"') -or
            -not $global:LastPullRequestBody.Contains('"adoptionStrategy":"FreshAdoption"') -or
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
        $completionEvidence = Join-Path $empty.Consumer `
            'docs/governance/adoption-complete.md'
        [IO.Directory]::CreateDirectory((Split-Path -Parent $completionEvidence)) | Out-Null
        [IO.File]::WriteAllText($completionEvidence, "# Reviewed adoption`n")
        Invoke-Git -Repository $empty.Consumer -Arguments @(
            'add', 'docs/governance/adoption-complete.md'
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
            schema = 5
            phase = 'Completed'
            state = 'BootstrapReady'
            target = 'v0.5.0'
            protocolSha = $completedProtocolSha
            head = $completedHead
            adoptionStrategy = 'FreshAdoption'
            protocolSurfaces = @()
            protocolRecordLossAcknowledged = $false
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
                'Manifest', 'ApplicationAdd', 'ApplicationModify',
                'ApplicationDelete', 'ApplicationType', 'ApplicationMode',
                'CredentialCase', 'CredentialNested', 'Gitmodules'
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
                    'CredentialCase' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone 'fg_pat.txt'),
                            "case-variant credential path`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'fg_pat.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'CredentialNested' {
                        $nestedCredential = Join-Path $variantClone `
                            'secrets/FG_PAT.txt'
                        New-Item -ItemType Directory `
                            -Path (Split-Path -Parent $nestedCredential) `
                            -Force | Out-Null
                        [IO.File]::WriteAllText(
                            $nestedCredential, "nested credential path`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'secrets/FG_PAT.txt'
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
                    'ApplicationAdd' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone 'src/completion-added.txt'),
                            "unauthorized application addition`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'src/completion-added.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'ApplicationModify' {
                        [IO.File]::WriteAllText(
                            (Join-Path $variantClone 'src/app.txt'),
                            "unauthorized application modification`n"
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', 'src/app.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'ApplicationDelete' {
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'rm', '--', 'src/app.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'ApplicationType' {
                        $applicationEntry = (@(Invoke-Git `
                            -Repository $variantClone -Arguments @(
                                'ls-tree', 'HEAD', '--', 'src/app.txt'
                            )))[0]
                        if ($applicationEntry -notmatch `
                            '^100644 blob (?<sha>[0-9a-f]{40})\tsrc/app\.txt$') {
                            throw "Cannot resolve Fresh application blob for type fixture: $applicationEntry"
                        }
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'update-index', '--cacheinfo',
                            "120000,$([string]$Matches.sha),src/app.txt"
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'ApplicationMode' {
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'update-index', '--chmod=+x', '--', 'src/app.txt'
                        ) | Out-Null
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'commit', '--amend', '--no-edit'
                        ) | Out-Null
                    }
                    'Gitmodules' {
                        $gitmodulesPath = Join-Path $variantClone '.gitmodules'
                        $gitmodulesText = [IO.File]::ReadAllText($gitmodulesPath) +
                            @(
                                '[submodule "consumer-product"]',
                                "`tpath = vendor/product",
                                "`turl = https://example.invalid/product.git",
                                ''
                            ) -join "`n"
                        [IO.File]::WriteAllText(
                            $gitmodulesPath, $gitmodulesText,
                            [Text.UTF8Encoding]::new($false)
                        )
                        Invoke-Git -Repository $variantClone -Arguments @(
                            'add', '--', '.gitmodules'
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
                    schema = 5
                    phase = 'Completed'
                    state = 'BootstrapReady'
                    target = 'v0.5.0'
                    protocolSha = $completedProtocolSha
                    head = $variantHead
                    adoptionStrategy = 'FreshAdoption'
                    protocolSurfaces = @()
                    protocolRecordLossAcknowledged = $false
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
    $result = Invoke-BootstrapFixture -Fixture $ideasCollision `
        -AdoptionStrategy 'HybridReconciliation'
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
    $genericCollision = New-BootstrapFixture -Name 'generic-collision' `
        -AddPullRequestTemplateCollision $true
    $result = Invoke-BootstrapFixture -Fixture $genericCollision
    if ($result.Threw) {
        Add-Failure "TEST-0127 protocol-free target collision incorrectly required a migration policy: $($result.Error)"
    }
    else {
        $paths = @(Get-RemoteChangedPaths -Fixture $genericCollision)
        $manifest = (Invoke-Git -Repository $genericCollision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
        )) -join "`n" | ConvertFrom-Json
        $template = (Invoke-Git -Repository $genericCollision.Consumer -Arguments @(
            'show', 'FETCH_HEAD:.github/PULL_REQUEST_TEMPLATE.md'
        )) -join "`n"
        if ($paths.Count -ne 1 -or
            [string]$paths[0] -cne '.ai/adoption/meandai-capabilities.json' -or
            [string]$manifest.state -cne 'AdoptionReviewRequired' -or
            [string]$manifest.adoptionStrategy -cne 'FreshAdoption' -or
            @($manifest.protocolSurfaces).Count -ne 0 -or
            @($manifest.collisions) -cnotcontains '.github/PULL_REQUEST_TEMPLATE.md' -or
            $template -cne '# Consumer pull request template') {
            Add-Failure 'TEST-0127 generic target collision did not retain FreshAdoption with manifest-only semantic review.'
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $moduleOwnedSurfacePath = 'docs/findings/FIND-9999-wrapper-prefilter.md'
    $moduleOwnedSurface = New-BootstrapFixture `
        -Name 'module-owned-surface-prefilter' `
        -NestedProtocolSurfaces @($moduleOwnedSurfacePath)
    $result = Invoke-BootstrapFixture -Fixture $moduleOwnedSurface
    $moduleOwnedUnselectedBranch = @(Invoke-Git `
        -Repository $moduleOwnedSurface.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or $global:PullRequestCreateCalls -ne 0 -or
        $moduleOwnedUnselectedBranch.Count -ne 0) {
        Add-Failure "TEST-0127 module-recognized assessment path was hidden before explicit strategy selection: $($result.Error)"
    }
    $result = Invoke-BootstrapFixture -Fixture $moduleOwnedSurface `
        -AdoptionStrategy 'FullMigration'
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 1) {
        Add-Failure "TEST-0127 module-recognized assessment path did not reach the strategy-bound proposal: $($result.Error)"
    }
    else {
        [void](Get-RemoteChangedPaths -Fixture $moduleOwnedSurface)
        $moduleOwnedManifest = (Invoke-Git `
            -Repository $moduleOwnedSurface.Consumer -Arguments @(
                'show', 'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
            )) -join "`n" | ConvertFrom-Json
        if (@($moduleOwnedManifest.protocolSurfaces) -cnotcontains
            $moduleOwnedSurfacePath) {
            Add-Failure 'TEST-0127 module-recognized assessment path was omitted by an adapter-side prefilter.'
        }
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $collision = New-BootstrapFixture -Name 'collision' -AddAgentsCollision $true
    $result = Invoke-BootstrapFixture -Fixture $collision
    $unselectedBranch = @(Invoke-Git -Repository $collision.Consumer -Arguments @(
        'ls-remote', '--heads', 'origin',
        'refs/heads/automation/meandai-capabilities-v0.5.0'
    ))
    if (-not $result.Threw -or
        $result.Error -notlike '*requires an explicit adoption strategy*' -or
        $global:PullRequestCreateCalls -ne 0 -or $unselectedBranch.Count -ne 0) {
        Add-Failure "TEST-0128 Auto with existing protocol evidence did not stop before proposal mutation: $($result.Error)"
    }
    $result = Invoke-BootstrapFixture -Fixture $collision `
        -AdoptionStrategy 'FullMigration'
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
            [string]$manifest.adoptionStrategy -cne 'FullMigration' -or
            @($manifest.protocolSurfaces) -cnotcontains 'AGENTS.md' -or
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
    $global:ExistingPullRequestBody = ''
    $cleanStart = New-BootstrapFixture -Name 'clean-start' `
        -AddAgentsCollision $true
    $result = Invoke-BootstrapFixture -Fixture $cleanStart `
        -AdoptionStrategy 'CleanStart'
    if (-not $result.Threw -or
        $result.Error -notlike '*requires explicit acknowledgement*' -or
        $global:PullRequestCreateCalls -ne 0) {
        Add-Failure "TEST-0128 unacknowledged CleanStart did not fail before proposal mutation: $($result.Error)"
    }
    $result = Invoke-BootstrapFixture -Fixture $cleanStart `
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 1 -or
        -not $global:LastPullRequestBody.Contains('"adoptionStrategy":"CleanStart"') -or
        -not $global:LastPullRequestBody.Contains('"protocolSurfaces":["AGENTS.md"]') -or
        -not $global:LastPullRequestBody.Contains('"protocolRecordLossAcknowledged":true')) {
        Add-Failure "TEST-0128 acknowledged CleanStart did not produce one strategy-bound draft: $($result.Error)"
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $caseCollision = New-BootstrapFixture -Name 'case-collision' `
        -AddAgentsCaseVariantCollision $true
    $result = Invoke-BootstrapFixture -Fixture $caseCollision `
        -AdoptionStrategy 'FullMigration'
    $caseCollisionBranch = @(Invoke-Git -Repository $caseCollision.Consumer `
        -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*noncanonical casing*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $caseCollisionBranch.Count -ne 0) {
        Add-Failure "TEST-0030/TEST-0095 case-variant managed target was not rejected without proposal mutation: $($result.Error)"
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
    $global:PullRequestCloseCalls = 0
    $global:ExistingPullRequestMetadataMode = 'Valid'
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $global:AdvanceDefaultBranchOnCreate = $true
    $baseRace = New-BootstrapFixture -Name 'base-race-on-create'
    $result = Invoke-BootstrapFixture -Fixture $baseRace
    $remainingBaseRaceBranch = @(Invoke-Git `
        -Repository $baseRace.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*exact draft and proposal branch were removed*' -or
        $global:PullRequestCreateCalls -ne 1 -or
        $global:PullRequestCloseCalls -ne 1 -or
        $global:PullRequestExists -or
        $remainingBaseRaceBranch.Count -ne 0) {
        Add-Failure "TEST-0128 default-branch race was not exactly compensated: $($result.Error)"
    }
    $global:AdvanceDefaultBranchOnCreate = $false

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
    $result = Invoke-BootstrapFixture -Fixture $manifestRename `
        -AdoptionStrategy 'FullMigration'
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
        $result = Invoke-BootstrapFixture -Fixture $manifestRename `
            -AdoptionStrategy 'FullMigration'
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
            $result = Invoke-BootstrapFixture -Fixture $manifestRename `
                -AdoptionStrategy 'FullMigration'
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
