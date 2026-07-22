[CmdletBinding()]
param(
    [ValidateSet(
        'All',
        'WindowsNative',
        'ContractsPreflight',
        'AdoptionLifecycle',
        'IntegrityCompletedGraph',
        'IntegrityManifestIssue',
        'IntegrityCodexFailure',
        'IntegrityMetadataCredential',
        'InstructionGraphClosure',
        'RepositoryRoutes',
        'CurrentLauncherRecovery'
    )]
    [string]$Shard = 'All'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$bootstrapPath = Join-Path $root 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$launcherPath = Join-Path $root `
    'tests/capabilities/initial-adoption/fixtures/Invoke-QuickAdoptionSource.ps1'
$launcherSourcePaths = @(
    'scripts/quick-adoption/Private/Configuration.ps1',
    'scripts/quick-adoption/Private/OutputAndNativeProcess.ps1',
    'scripts/quick-adoption/Private/RepositoryAssessment.ps1',
    'scripts/quick-adoption/Private/ProtocolReleaseAndAssets.ps1',
    'scripts/quick-adoption/Private/ProposalOwnership.ps1',
    'scripts/quick-adoption/Private/CodexRuntime.ps1',
    'scripts/quick-adoption/Private/CompletionAndPublication.ps1',
    'scripts/quick-adoption/Public/Invoke-MeAndAIQuickAdoption.ps1'
) | ForEach-Object {
    Join-Path $root ($_ -replace '/', [IO.Path]::DirectorySeparatorChar)
}

function Get-QuickAdoptionLauncherSource {
    return @($launcherSourcePaths | ForEach-Object {
        Get-Content -LiteralPath $_ -Raw
    }) -join [Environment]::NewLine
}
$guidePath = Join-Path $root 'docs/quick-adoption.md'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$mockCodexScriptPath = Join-Path $root 'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.ps1'
$mockCodexWindowsPath = Join-Path $root 'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.cmd'
$mockCodexUnixPath = Join-Path $root 'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.sh'
$mockCodexPath = if ($env:OS -eq 'Windows_NT') {
    $mockCodexWindowsPath
}
else {
    $mockCodexUnixPath
}
$workflowRelativePath = '.github/workflows/meandai-protocol-update.yml'
$canonicalAdoptionAssets = @(
    [pscustomobject]@{ ConsumerPath = 'AGENTS.md'; TemplatePath = 'templates/project/AGENTS.submodule.md' },
    [pscustomobject]@{ ConsumerPath = '.ai/memory/README.md'; TemplatePath = 'templates/project/.ai/memory/README.md' },
    [pscustomobject]@{ ConsumerPath = '.ai/memory/project.md'; TemplatePath = 'templates/project/.ai/memory/project.md' },
    [pscustomobject]@{ ConsumerPath = '.ai/memory/log/README.md'; TemplatePath = 'templates/project/.ai/memory/log/README.md' },
    [pscustomobject]@{ ConsumerPath = 'docs/ideas/README.md'; TemplatePath = 'templates/project/docs/ideas/README.md' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/bug.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/bug.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/epic.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/epic.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/feature.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/feature.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/finding.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/finding.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/subfeature.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/subfeature.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/task.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/task.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/PULL_REQUEST_TEMPLATE.md'; TemplatePath = '.github/PULL_REQUEST_TEMPLATE.md' },
    [pscustomobject]@{ ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'; TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1' },
    [pscustomobject]@{ ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'; TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1' }
)
$canonicalManagedUpdaterAssets = @(
    [pscustomobject]@{
        ConsumerPath = $workflowRelativePath
        TemplatePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
    }
) + @($canonicalAdoptionAssets | Where-Object {
    [string]$_.ConsumerPath -cin @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    )
})
$canonicalInitialAdoptionPolicyAsset = [pscustomobject]@{
    TemplatePath =
        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
}
$canonicalProtocolSnapshotAssets = @($canonicalManagedUpdaterAssets) + @(
    $canonicalInitialAdoptionPolicyAsset
)
$canonicalAdoptionProposedPaths = @(
    $workflowRelativePath, '.gitmodules', '.ai/protocol',
    '.ai/meandai-update-state.json'
) + @($canonicalAdoptionAssets | ForEach-Object { [string]$_.ConsumerPath })
$canonicalAdoptionRequiredTasks = @(
    'Create or reconcile the repository labels required by the protocol.',
    'Create project-owned feature and decision records for adoption.',
    'Apply the manifest-selected adoption strategy; do not infer or change it.',
    'Tailor project-local memory without importing protocol-repository facts.',
    'Resolve every collision through semantic review; do not overwrite blindly.',
    'Create and run the project test evidence required by DoR and DoD.',
    'Verify all documentation links and traceability references.',
    'Remove the manifest before marking the pull request ready or merging it.'
)
$canonicalProtocolSurfaceFiles = @(
    'AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'PROTOCOL.md', 'CONTRIBUTING.md',
    '.cursorrules', '.windsurfrules', '.github/copilot-instructions.md',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
    '.ai/protocol', '.ai/meandai-update-state.json',
    'FEATURE_BACKLOG.md', 'ACTIVE_FINDINGS.md', 'DECISIONS.md',
    'WORK_INDEX.md', 'SESSION_HANDOFF.md', 'PROJECT_STATE.md',
    'PROJECT_METRICS.md', 'RELEASES.md',
    'ai/FEATURE_BACKLOG.md', 'ai/ACTIVE_FINDINGS.md', 'ai/DECISIONS.md',
    'ai/WORK_INDEX.md', 'ai/SESSION_HANDOFF.md', 'ai/PROJECT_STATE.md',
    'ai/PROJECT_METRICS.md', 'ai/RELEASES.md'
)
$canonicalProtocolSurfaceRoots = @(
    '.ai/memory/', '.ai/protocol/', '.cursor/rules/', '.windsurf/rules/',
    '.github/instructions/',
    'docs/features/', 'docs/decisions/', 'docs/findings/',
    'docs/governance/', 'docs/ideas/', 'docs/agent-prompts/'
)
$failures = [System.Collections.Generic.List[string]]::new()
$tempRoots = [System.Collections.Generic.List[string]]::new()
$originalGitHubHost = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')
$originalCodexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
$script:QuickAdoptionProtocolFixture = $null
$script:QuickAdoptionContractModule = $null

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Get-TestProtocolSurfaceInventory {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Paths)

    $surfaces = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($value in @($Paths)) {
        $path = [string]$value
        if ($path.Equals('AGENTS.md', [StringComparison]::OrdinalIgnoreCase) -or
            $path.EndsWith('/AGENTS.md', [StringComparison]::OrdinalIgnoreCase)) {
            [void]$surfaces.Add($path)
        }
        foreach ($candidate in $canonicalProtocolSurfaceFiles) {
            if ($path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
                [void]$surfaces.Add($path)
                break
            }
        }
        foreach ($rootPath in $canonicalProtocolSurfaceRoots) {
            $exactRootPath = $rootPath.TrimEnd('/')
            if ($path.Equals(
                    $exactRootPath,
                    [StringComparison]::OrdinalIgnoreCase
                ) -or
                $path.StartsWith(
                    $rootPath,
                    [StringComparison]::OrdinalIgnoreCase
                )) {
                [void]$surfaces.Add($path)
                break
            }
        }
    }
    $result = @($surfaces)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return @($result)
}

function Test-QuickAdoptionShard {
    param([Parameter(Mandatory)][string]$Name)

    $windowsNativeShards = @(
        'ContractsPreflight',
        'AdoptionLifecycle',
        'IntegrityCodexFailure'
    )
    return $Shard -ceq 'All' -or $Shard -ceq $Name -or
        ($Shard -ceq 'WindowsNative' -and $windowsNativeShards -ccontains $Name)
}

function Invoke-TestGit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $Repository @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Invoke-TestGitBinary {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Arguments
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = $Arguments
    $startInfo.WorkingDirectory = $Repository
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $output = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) {
            throw "git $Arguments did not start."
        }
        $process.StandardOutput.BaseStream.CopyTo($output)
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "git $Arguments failed: $errorText"
        }
        return ,([byte[]]$output.ToArray())
    }
    finally {
        $output.Dispose()
        $process.Dispose()
    }
}

function Get-TestCommittedInstructionGraph {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)]$Builder,
        [Parameter(Mandatory)]$Validator
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The TEST-0154 graph fixture requires one exact commit.'
    }
    $treeBytes = Invoke-TestGitBinary -Repository $Repository `
        -Arguments "ls-tree -r -t -z --full-tree $Commit --"
    $treeText = [Text.UTF8Encoding]::new($false, $true).GetString($treeBytes)
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($record in @($treeText.Split([char]0))) {
        if ([string]::IsNullOrEmpty($record)) { continue }
        $match = [regex]::Match(
            $record,
            '^(?<mode>[0-9]{6}) (?<type>blob|tree|commit) (?<sha>[0-9a-f]{40})\t(?<path>.+)$'
        )
        if (-not $match.Success) {
            throw "The TEST-0154 exact tree contains malformed record '$record'."
        }
        $entries.Add([pscustomobject]@{
            Path = [string]$match.Groups['path'].Value
            Mode = [string]$match.Groups['mode'].Value
            Type = [string]$match.Groups['type'].Value
            Sha = [string]$match.Groups['sha'].Value
        })
    }
    $gitBinary = ${function:Invoke-TestGitBinary}
    $reader = {
        param($entry)
        return ,(& $gitBinary -Repository $Repository `
            -Arguments "cat-file blob $([string]$entry.Sha)")
    }.GetNewClosure()
    $graph = & $Builder -BaseHead $Commit -TreeEntries @($entries) `
        -ReadBlob $reader
    if (-not (& $Validator -Graph $graph)) {
        throw 'The TEST-0154 exported policy returned a non-exact graph.'
    }
    return $graph
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    return Invoke-TestGit -Repository $Repository -Arguments $Arguments
}

function Test-RepositoryHasHead {
    param([Parameter(Mandatory)][string]$Repository)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $null = & git -C $Repository rev-parse --verify HEAD 2>&1
        return $LASTEXITCODE -eq 0
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

function New-MockRemoteEmptyCommit {
    param(
        [Parameter(Mandatory)][string]$Remote,
        [Parameter(Mandatory)][string]$Message
    )

    Invoke-TestGit -Repository $Remote -Arguments @(
        'config', 'user.name', 'meAndAI Test'
    ) | Out-Null
    Invoke-TestGit -Repository $Remote -Arguments @(
        'config', 'user.email', 'meandai-test@example.invalid'
    ) | Out-Null
    Invoke-TestGit -Repository $Remote -Arguments @(
        'read-tree', '--empty'
    ) | Out-Null
    $emptyTree = (@(Invoke-TestGit -Repository $Remote `
        -Arguments @('write-tree')))[0]
    return (@(Invoke-TestGit -Repository $Remote `
        -Arguments @('commit-tree', $emptyTree, '-m', $Message)))[0]
}

function Add-MockRemoteDevelopHead {
    param([Parameter(Mandatory)][string]$Remote)

    if ($global:QuickAdoptionDevelopRaceInjected) {
        return
    }
    $developCommit = New-MockRemoteEmptyCommit -Remote $Remote `
        -Message 'Concurrent develop'
    Invoke-TestGit -Repository $Remote -Arguments @(
        'update-ref', 'refs/heads/develop', $developCommit
    ) | Out-Null
    $global:QuickAdoptionDevelopRaceInjected = $true
}

function Add-MockRemoteTagRef {
    param([Parameter(Mandatory)][string]$Remote)

    if ($global:QuickAdoptionTagRaceInjected) {
        return
    }
    $tagCommit = New-MockRemoteEmptyCommit -Remote $Remote `
        -Message 'Concurrent tag'
    Invoke-TestGit -Repository $Remote -Arguments @(
        'update-ref', 'refs/tags/concurrent', $tagCommit
    ) | Out-Null
    $global:QuickAdoptionTagRaceInjected = $true
}

function Get-MockLiveDefaultBranch {
    if ($global:QuickAdoptionDefaultBranch) {
        return [string]$global:QuickAdoptionDefaultBranch
    }
    if (-not $global:QuickAdoptionRemotePath -or
        -not (Test-Path -LiteralPath $global:QuickAdoptionRemotePath `
            -PathType Container)) {
        return ''
    }
    $mainRefs = @(Invoke-TestGit -Repository $global:QuickAdoptionRemotePath `
        -Arguments @(
            'for-each-ref', '--format=%(refname)', 'refs/heads/main'
        ))
    if ($mainRefs.Count -eq 1 -and $mainRefs[0] -ceq 'refs/heads/main') {
        return 'main'
    }
    return ''
}

function New-TempRoot {
    param([string]$Name)

    $path = Join-Path ([IO.Path]::GetTempPath()) "meandai-quick-$Name-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    $tempRoots.Add($path)
    return $path
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

function New-TestFileLink {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Target
    )

    if ($env:OS -eq 'Windows_NT') {
        # File symlink creation still requires an elevated Windows token on
        # hosts without Developer Mode. A hard link remains a real linked file
        # and exercises the canonical token's non-link invariant.
        New-Item -ItemType HardLink -Path $Path -Target $Target | Out-Null
    }
    else {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
    }
}

function ConvertTo-TestFileUri {
    param([Parameter(Mandatory)][string]$Path)

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $builder = [UriBuilder]::new()
    $builder.Scheme = [Uri]::UriSchemeFile
    $builder.Host = ''
    $builder.Path = $resolvedPath
    $uri = $builder.Uri.AbsoluteUri
    if ([string]::IsNullOrWhiteSpace($uri)) {
        throw "Unable to create a file URI for test path '$resolvedPath'."
    }
    return $uri
}

function New-TestPostCommitIndexInjectionHook {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$OnlyAfterManifestRemoval
    )

    $hookRoot = New-TempRoot -Name "hook-$Name"
    $hookPath = Join-Path $hookRoot 'post-commit'
    $condition = if ($OnlyAfterManifestRemoval) {
        "if [ -f .ai/adoption/meandai-capabilities.json ]; then exit 0; fi`n"
    }
    else { '' }
    [IO.File]::WriteAllText(
        $hookPath,
        "#!/bin/sh`n${condition}printf 'hook index injection\n' > .meandai-hook-index-injection`ngit add -- .meandai-hook-index-injection`n",
        [Text.UTF8Encoding]::new($false)
    )
    if ($env:OS -ne 'Windows_NT') {
        & chmod +x $hookPath
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to make the post-commit test hook executable.'
        }
    }
    return $hookRoot
}

function New-TestBlockingGitHooks {
    param([Parameter(Mandatory)][string]$SentinelName)

    $hookRoot = New-TempRoot -Name 'blocking-hooks'
    foreach ($hookName in @('pre-commit', 'pre-push')) {
        $hookPath = Join-Path $hookRoot $hookName
        [IO.File]::WriteAllText(
            $hookPath,
            "#!/bin/sh`nprintf '$hookName executed\n' >> '$SentinelName'`nexit 1`n",
            [Text.UTF8Encoding]::new($false)
        )
        if ($env:OS -ne 'Windows_NT') {
            & chmod +x $hookPath
            if ($LASTEXITCODE -ne 0) {
                throw "Unable to make the $hookName test hook executable."
            }
        }
    }
    return $hookRoot
}

function Set-TestGitIdentity {
    param([string]$Repository)

    Invoke-TestGit -Repository $Repository -Arguments @('config', 'user.name', 'meAndAI Test') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'user.email', 'meandai-test@example.invalid') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
}

function Copy-CanonicalProtocolFixture {
    param(
        [Parameter(Mandatory)][string]$Destination,
        [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Tag = 'v0.12.7'
    )

    [IO.File]::WriteAllText(
        (Join-Path $Destination 'PROTOCOL.md'),
        "# Mock protocol source`n",
        [Text.UTF8Encoding]::new($false)
    )
    $capabilitiesModulePath = 'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
    foreach ($templatePath in @(
        '.gitattributes',
        $capabilitiesModulePath,
        'templates/project/.github/workflows/meandai-protocol-update.yml',
        'capabilities/index.json',
        'capabilities/test-architecture.json',
        'scripts/MeAndAI.CapabilityCatalog.psm1',
        'scripts/MeAndAI.CapabilityReview.psm1',
        'scripts/Invoke-MeAndAICapabilityReview.ps1',
        'scripts/MeAndAI.ConsumerMigrations.psm1',
        'migrations/index.json',
        'migrations/MIG-0001.json'
    ) + @(
        $canonicalAdoptionAssets | ForEach-Object { [string]$_.TemplatePath }
    )) {
        $sourcePath = Join-Path $root `
            ($templatePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $destinationPath = Join-Path $Destination `
            ($templatePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) `
            -Force | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
    }

    $fixtureWorkflowPath = Join-Path $Destination `
        'templates/project/.github/workflows/meandai-protocol-update.yml'
    $workflowText = [IO.File]::ReadAllText($fixtureWorkflowPath)
    $bootstrapTagPattern = '(?m)^[ ]*BOOTSTRAP_PROTOCOL_TAG: v[0-9]+\.[0-9]+\.[0-9]+[ ]*$'
    $bootstrapTagMatches = @([regex]::Matches(
        $workflowText,
        $bootstrapTagPattern,
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    ))
    if ($bootstrapTagMatches.Count -ne 1) {
        throw 'Canonical protocol workflow must declare exactly one bootstrap protocol tag.'
    }
    $normalizedWorkflow = [regex]::Replace(
        $workflowText,
        $bootstrapTagPattern,
        "  BOOTSTRAP_PROTOCOL_TAG: $Tag",
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    [IO.File]::WriteAllText(
        $fixtureWorkflowPath,
        $normalizedWorkflow,
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $Destination 'VERSION'),
        $Tag.Substring(1),
        [Text.UTF8Encoding]::new($false)
    )
}

function Get-GitBlobSha {
    param([byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-MockConsumerMigrationBaseline {
    $modulePath = Join-Path $global:QuickAdoptionProtocolRepository `
        'scripts/MeAndAI.ConsumerMigrations.psm1'
    $indexPath = Join-Path $global:QuickAdoptionProtocolRepository `
        'migrations/index.json'
    $module = @(Import-Module $modulePath -Force -PassThru)
    if ($module.Count -ne 1) {
        throw 'Mock consumer migration module could not be imported exactly once.'
    }
    try {
        $catalog = & $module[0].ExportedCommands[
            'Import-MeAndAIConsumerMigrationCatalog'
        ] -IndexPath $indexPath
        return & $module[0].ExportedCommands[
            'New-MeAndAIConsumerMigrationBaseline'
        ] -Catalog $catalog
    }
    finally {
        Remove-Module -Name ([string]$module[0].Name) -Force `
            -ErrorAction SilentlyContinue
    }
}

function Save-MockProtocolAssetSnapshot {
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]
        [System.Collections.Generic.Dictionary[string, object]]$Snapshots
    )

    foreach ($asset in $canonicalProtocolSnapshotAssets) {
        $path = Join-Path $Repository `
            (([string]$asset.TemplatePath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $bytes = [IO.File]::ReadAllBytes($path)
        $Snapshots["$Tag`n$($asset.TemplatePath)"] = `
            [pscustomobject]@{
                Bytes = $bytes
                Sha = Get-GitBlobSha -Bytes $bytes
            }
    }
}

function Initialize-QuickAdoptionImmutableFixture {
    if ($null -ne $script:QuickAdoptionProtocolFixture) {
        return
    }
    if (-not ('System.IO.Compression.ZipFile' -as [type])) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }

    $workflowBytes = [IO.File]::ReadAllBytes($workflowPath)
    $assetSnapshots = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $releaseCommits = [System.Collections.Generic.Dictionary[string, string]]::new(
        [StringComparer]::Ordinal
    )
    $protocolFixtureRoot = New-TempRoot -Name 'protocol-repository'
    $protocolRepository = Join-Path $protocolFixtureRoot 'source'
    New-Item -ItemType Directory -Path $protocolRepository -Force | Out-Null
    & git init -b main $protocolRepository 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the immutable mock protocol repository.'
    }
    Set-TestGitIdentity -Repository $protocolRepository
    Copy-CanonicalProtocolFixture -Destination $protocolRepository -Tag 'v0.9.2'
    $fixtureWorkflowPath = Join-Path $protocolRepository `
        'templates/project/.github/workflows/meandai-protocol-update.yml'
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'add', '--', '.'
    ) | Out-Null
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'commit', '-m', 'Create mock legacy protocol release'
    ) | Out-Null
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'tag', 'v0.9.2'
    ) | Out-Null
    $legacySha = (@(Invoke-TestGit -Repository $protocolRepository `
        -Arguments @('rev-parse', 'HEAD')))[0]
    $releaseCommits['v0.9.2'] = $legacySha
    Save-MockProtocolAssetSnapshot -Tag 'v0.9.2' `
        -Repository $protocolRepository -Snapshots $assetSnapshots

    Copy-CanonicalProtocolFixture -Destination $protocolRepository -Tag 'v0.12.7'
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'add', '--', '.'
    ) | Out-Null
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'commit', '-m', 'Create mock current protocol release'
    ) | Out-Null
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'tag', 'v0.12.7'
    ) | Out-Null
    $currentSha = (@(Invoke-TestGit -Repository $protocolRepository `
        -Arguments @('rev-parse', 'HEAD')))[0]
    $releaseCommits['v0.12.7'] = $currentSha
    Save-MockProtocolAssetSnapshot -Tag 'v0.12.7' `
        -Repository $protocolRepository -Snapshots $assetSnapshots

    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'switch', '--detach'
    ) | Out-Null
    foreach ($futureTag in @('v0.12.8', 'v1.0.0')) {
        Copy-CanonicalProtocolFixture -Destination $protocolRepository `
            -Tag $futureTag
        Invoke-TestGit -Repository $protocolRepository -Arguments @(
            'add', '--', '.'
        ) | Out-Null
        Invoke-TestGit -Repository $protocolRepository -Arguments @(
            'commit', '-m', "Create mock $futureTag protocol release"
        ) | Out-Null
        Invoke-TestGit -Repository $protocolRepository -Arguments @(
            'tag', $futureTag
        ) | Out-Null
        $futureSha = (@(Invoke-TestGit -Repository $protocolRepository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $releaseCommits[$futureTag] = $futureSha
        Save-MockProtocolAssetSnapshot -Tag $futureTag `
            -Repository $protocolRepository -Snapshots $assetSnapshots
    }
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'switch', 'main'
    ) | Out-Null

    $archivePath = Join-Path $protocolFixtureRoot 'protocol-v0.12.7.zip'
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'archive', '--format=zip', '--prefix=openai-mock-protocol/',
        '-o', $archivePath, 'v0.12.7'
    ) | Out-Null
    $status = @(Invoke-TestGit -Repository $protocolRepository `
        -Arguments @('status', '--porcelain'))
    if ($status.Count -ne 0) {
        throw 'The immutable mock protocol fixture was not clean after creation.'
    }
    $refFingerprint = @(
        Invoke-TestGit -Repository $protocolRepository -Arguments @(
            'for-each-ref', '--format=%(refname):%(objectname)',
            'refs/heads', 'refs/tags'
        ) | Sort-Object
    ) -join "`n"
    $archiveSha256 = (Get-FileHash -LiteralPath $archivePath `
        -Algorithm SHA256).Hash.ToLowerInvariant()

    $script:QuickAdoptionProtocolFixture = [pscustomobject]@{
        BuildCount = 1
        Repository = $protocolRepository
        LegacySha = $legacySha
        CurrentSha = $currentSha
        ReleaseCommits = [Collections.ObjectModel.ReadOnlyDictionary[string, string]]::new(
            $releaseCommits
        )
        AssetSnapshots = [Collections.ObjectModel.ReadOnlyDictionary[string, object]]::new(
            $assetSnapshots
        )
        WorkflowBytes = $workflowBytes
        WorkflowSha = Get-GitBlobSha -Bytes $workflowBytes
        RefFingerprint = $refFingerprint
        ArchivePath = $archivePath
        ArchiveSha256 = $archiveSha256
    }
}

function Assert-QuickAdoptionImmutableFixture {
    if ($null -eq $script:QuickAdoptionProtocolFixture -or
        [int]$script:QuickAdoptionProtocolFixture.BuildCount -ne 1) {
        throw 'The immutable quick-adoption fixture was not built exactly once.'
    }
    $fixture = $script:QuickAdoptionProtocolFixture
    $status = @(Invoke-TestGit -Repository $fixture.Repository `
        -Arguments @('status', '--porcelain'))
    $refs = @(
        Invoke-TestGit -Repository $fixture.Repository -Arguments @(
            'for-each-ref', '--format=%(refname):%(objectname)',
            'refs/heads', 'refs/tags'
        ) | Sort-Object
    ) -join "`n"
    $archiveSha256 = (Get-FileHash -LiteralPath $fixture.ArchivePath `
        -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($status.Count -ne 0 -or $refs -cne $fixture.RefFingerprint -or
        $archiveSha256 -cne $fixture.ArchiveSha256) {
        throw 'The immutable quick-adoption fixture changed during scenario execution.'
    }
}

function Copy-QuickAdoptionReleaseArchive {
    param([Parameter(Mandatory)][string]$OutFile)

    if ([string]::IsNullOrWhiteSpace(
            [string]$global:QuickAdoptionProtocolArchivePath
        )) {
        throw 'The immutable protocol archive has not been initialized.'
    }
    if (Test-Path -LiteralPath $OutFile) {
        [IO.File]::Delete($OutFile)
    }
    [IO.File]::Copy(
        $global:QuickAdoptionProtocolArchivePath,
        $OutFile,
        $false
    )
}

function Reset-Mocks {
    Initialize-QuickAdoptionImmutableFixture
    $fixture = $script:QuickAdoptionProtocolFixture
    [Environment]::SetEnvironmentVariable(
        'GH_HOST', 'ghe.example.invalid', 'Process'
    )
    $global:QuickAdoptionGhCalls = [System.Collections.Generic.List[object]]::new()
    $global:QuickAdoptionRestCalls = [System.Collections.Generic.List[object]]::new()
    $global:QuickAdoptionSecrets = [System.Collections.Generic.List[object]]::new()
    $global:QuickAdoptionExistingSecrets = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionExpectedUpdaterToken = 'write-token-value'
    $global:QuickAdoptionExpectedProtocolToken = 'read-token-value'
    $global:QuickAdoptionRepoName = ''
    $global:QuickAdoptionGhVersionOutput = 'gh version 2.82.1 (mock)'
    $global:QuickAdoptionRepositoryExists = $true
    $global:QuickAdoptionDefaultBranch = 'main'
    $global:QuickAdoptionRepoViewCalls = 0
    $global:QuickAdoptionRepoViewMode = 'Valid'
    $global:QuickAdoptionDevelopRaceInjected = $false
    $global:QuickAdoptionTagRaceInjected = $false
    $global:QuickAdoptionRepositoryWasCreated = $false
    $global:QuickAdoptionDelayedDefaultViews = 0
    $global:QuickAdoptionOwner = 'test-owner'
    $global:QuickAdoptionNewRemote = ''
    $global:QuickAdoptionTargetPath = ''
    $global:QuickAdoptionDenyTargetAccess = $false
    $global:QuickAdoptionReleaseMode = 'Immutable'
    $codexLogRoot = New-TempRoot -Name 'codex-log'
    $global:QuickAdoptionCodexLog = Join-Path $codexLogRoot 'calls.jsonl'
    New-Item -ItemType File -Path $global:QuickAdoptionCodexLog -Force | Out-Null
    $env:MEANDAI_TEST_CODEX_LOG = $global:QuickAdoptionCodexLog
    $env:MEANDAI_TEST_CODEX_MODE = 'Success'
    $env:MEANDAI_TEST_CODEX_SANDBOX_MODE = 'Success'
    $env:MEANDAI_TEST_CODEX_TARGET = ''
    $env:MEANDAI_TEST_CODEX_REMOTE = ''
    if ($env:OS -eq 'Windows_NT') {
        $testCodexHome = New-TempRoot -Name 'codex-home'
        [IO.File]::WriteAllText(
            (Join-Path $testCodexHome 'config.toml'),
            "[windows]`nsandbox = `"elevated`"`n",
            [Text.UTF8Encoding]::new($false)
        )
        [Environment]::SetEnvironmentVariable('CODEX_HOME', $testCodexHome, 'Process')
    }
    $global:QuickAdoptionPrReadyCalls = 0
    $global:QuickAdoptionPrReadyUndoCalls = 0
    $global:QuickAdoptionPrBodyEditCalls = 0
    $global:QuickAdoptionPrBodyEditMode = 'Normal'
    $global:QuickAdoptionCompletedEditFailures = 0
    $global:QuickAdoptionPrHead = ''
    $global:QuickAdoptionPrBody = ''
    $global:QuickAdoptionPrDraft = $true
    $global:QuickAdoptionPrState = 'OPEN'
    $global:QuickAdoptionRemotePath = ''
    $global:QuickAdoptionRunListCalls = 0
    $global:QuickAdoptionWorkflowDispatched = $false
    $global:QuickAdoptionPublishAdoptionProposal = $true
    $global:QuickAdoptionRunMode = 'Single'
    $global:QuickAdoptionCorrelationId = ''
    $global:QuickAdoptionExpectedPublishedHead = ''
    $global:QuickAdoptionDispatchRecord = $null
    $global:QuickAdoptionDispatchedStrategy = ''
    $global:QuickAdoptionDispatchedLossAcknowledgement = $false
    $global:QuickAdoptionDispatchedBaseSha = ''
    $global:QuickAdoptionDispatchedSourceGraphIdentity = $null
    $global:QuickAdoptionDispatchedSourceGraphRecord = $null
    $global:QuickAdoptionWorkflowSupportsSourceGraphIdentity = $null
    $global:QuickAdoptionExpectSourceGraphIdentity = $null
    $global:QuickAdoptionProposalSurfaces = @()
    $global:QuickAdoptionPrListCalls = 0
    $global:QuickAdoptionBaseAdvanceAtPrListCall = 0
    $global:QuickAdoptionBaseAdvanceCalls = 0
    $global:QuickAdoptionProposalMode = 'ValidFull'
    $global:QuickAdoptionManifestMode = 'Valid'
    $global:QuickAdoptionPrMetadataMode = 'Valid'
    $global:QuickAdoptionLabels = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionLabelRecords = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $global:QuickAdoptionSecretLockMode = 'Normal'
    $global:QuickAdoptionSecretLockViewCalls = 0
    $global:QuickAdoptionIssue = $null
    $global:QuickAdoptionIssues = [System.Collections.Generic.List[object]]::new()
    $global:QuickAdoptionIssueRace = $false
    $global:QuickAdoptionIssueEditMode = 'Normal'
    $global:QuickAdoptionIssueEditFailures = 0
    $global:QuickAdoptionIssueLabels = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionEvents = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionWorkflowBytes = [byte[]]$fixture.WorkflowBytes.Clone()
    $global:QuickAdoptionWorkflowSha = $fixture.WorkflowSha
    $global:QuickAdoptionProtocolAssetBytes = $fixture.AssetSnapshots
    $global:QuickAdoptionProtocolReleaseCommits = $fixture.ReleaseCommits
    $global:QuickAdoptionProtocolRepository = $fixture.Repository
    $env:MEANDAI_TEST_PROTOCOL_REPOSITORY = $fixture.Repository
    $global:QuickAdoptionProtocolLegacySha = $fixture.LegacySha
    $global:QuickAdoptionProtocolSha = $fixture.CurrentSha
    $global:QuickAdoptionProtocolArchivePath = $fixture.ArchivePath
    $global:QuickAdoptionProtocolArchiveSha256 = $fixture.ArchiveSha256
}

function New-MockConnectedManagedConsumer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$InstalledTag
    )

    if (-not $global:QuickAdoptionProtocolReleaseCommits.ContainsKey($InstalledTag)) {
        throw "Mock managed consumer requested unknown release '$InstalledTag'."
    }
    $rootPath = New-TempRoot -Name $Name
    $repositoryPath = Join-Path $rootPath 'consumer'
    $remotePath = Join-Path $rootPath 'consumer.git'
    New-Item -ItemType Directory -Path $repositoryPath -Force | Out-Null
    & git init --bare $remotePath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the mock managed-consumer remote.'
    }
    & git init -b main $repositoryPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the mock managed consumer.'
    }
    Set-TestGitIdentity -Repository $repositoryPath
    $slug = "test-owner/$Name"
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'config', "url.$($remotePath.Replace('\\', '/')).insteadOf",
        "https://github.com/$slug.git"
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'remote', 'add', 'origin', "https://github.com/$slug.git"
    ) | Out-Null

    [IO.File]::WriteAllText(
        (Join-Path $repositoryPath 'app.txt'),
        "managed consumer`n",
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $repositoryPath '.gitmodules'),
        "[submodule `".ai/protocol`"]`n`tpath = .ai/protocol`n`turl = https://github.com/hasanmanzak/meAndAI.git`n",
        [Text.UTF8Encoding]::new($false)
    )
    foreach ($asset in $canonicalManagedUpdaterAssets) {
        $key = "$InstalledTag`n$($asset.TemplatePath)"
        $snapshot = $global:QuickAdoptionProtocolAssetBytes[$key]
        if ($null -eq $snapshot) {
            throw "Mock managed asset snapshot is missing for '$key'."
        }
        $destination = Join-Path $repositoryPath `
            (([string]$asset.ConsumerPath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) `
            -Force | Out-Null
        [IO.File]::WriteAllBytes($destination, [byte[]]$snapshot.Bytes)
    }
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'add', '--', 'app.txt', '.gitmodules'
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments `
        (@('add', '--') + @($canonicalManagedUpdaterAssets | ForEach-Object {
            [string]$_.ConsumerPath
        })) | Out-Null
    $protocolSha = $global:QuickAdoptionProtocolReleaseCommits[$InstalledTag]
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'update-index', '--add', '--cacheinfo', "160000,$protocolSha,.ai/protocol"
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'commit', '-m', "Install managed adoption at $InstalledTag"
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'push', '-u', 'origin', 'main'
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'config', 'submodule..ai/protocol.url',
        $global:QuickAdoptionProtocolRepository.Replace('\\', '/')
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        '-c', 'protocol.file.allow=always',
        'submodule', 'update', '--init', '--', '.ai/protocol'
    ) | Out-Null

    $global:QuickAdoptionRepoName = $slug
    $global:QuickAdoptionTargetPath = $repositoryPath
    $global:QuickAdoptionRemotePath = $remotePath
    $global:QuickAdoptionDefaultBranch = 'main'
    $global:QuickAdoptionExistingSecrets.Clear()
    $global:QuickAdoptionExistingSecrets.Add('MEANDAI_UPDATER_TOKEN')
    $global:QuickAdoptionExistingSecrets.Add('MEANDAI_PROTOCOL_TOKEN')
    $global:QuickAdoptionPublishAdoptionProposal = $false
    return [pscustomobject]@{
        Repository = $repositoryPath
        Remote = $remotePath
        Slug = $slug
        Head = (@(Invoke-TestGit -Repository $repositoryPath `
            -Arguments @('rev-parse', 'HEAD')))[0]
    }
}

function New-MockConnectedSeedConsumer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$OmitWorkflowSeed
    )

    $consumerRoot = New-TempRoot -Name $Name
    $repositoryPath = Join-Path $consumerRoot 'consumer'
    $remotePath = Join-Path $consumerRoot 'consumer.git'
    New-Item -ItemType Directory -Path $repositoryPath -Force | Out-Null
    & git init --bare $remotePath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the mock seed-consumer remote.'
    }
    & git init -b main $repositoryPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the mock seed consumer.'
    }
    Set-TestGitIdentity -Repository $repositoryPath
    [IO.File]::WriteAllText(
        (Join-Path $repositoryPath 'app.txt'),
        "consumer app`n",
        [Text.UTF8Encoding]::new($false)
    )
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'add', '--', 'app.txt'
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'commit', '-m', 'Initial consumer'
    ) | Out-Null
    $slug = "test-owner/$Name"
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'config', "url.$($remotePath.Replace('\\', '/')).insteadOf",
        "https://github.com/$slug.git"
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'remote', 'add', 'origin', "https://github.com/$slug.git"
    ) | Out-Null
    Invoke-TestGit -Repository $repositoryPath -Arguments @(
        'push', '-u', 'origin', 'main'
    ) | Out-Null

    Set-Content -LiteralPath (Join-Path $repositoryPath 'FG_PAT.txt') `
        -Value 'write-token-value' -NoNewline
    Set-Content -LiteralPath (Join-Path $repositoryPath 'MEANDAI_RO_FG_PAT.txt') `
        -Value 'read-token-value' -NoNewline
    if (-not $OmitWorkflowSeed) {
        $seedPath = Join-Path $repositoryPath $workflowRelativePath
        New-Item -ItemType Directory -Path (Split-Path -Parent $seedPath) `
            -Force | Out-Null
        [IO.File]::WriteAllBytes($seedPath, $global:QuickAdoptionWorkflowBytes)
        Invoke-TestGit -Repository $repositoryPath -Arguments @(
            'add', '--', $workflowRelativePath
        ) | Out-Null
        Invoke-TestGit -Repository $repositoryPath -Arguments @(
            'commit', '-m', 'Install canonical adoption seed'
        ) | Out-Null
        Invoke-TestGit -Repository $repositoryPath -Arguments @(
            'push', 'origin', 'main'
        ) | Out-Null
    }

    $global:QuickAdoptionRepoName = $slug
    $global:QuickAdoptionTargetPath = $repositoryPath
    $global:QuickAdoptionRemotePath = $remotePath
    $env:MEANDAI_TEST_CODEX_TARGET = $repositoryPath
    $env:MEANDAI_TEST_CODEX_REMOTE = $remotePath
    return [pscustomobject]@{
        Repository = $repositoryPath
        Remote = $remotePath
    }
}

function Add-MockRootRuleGitlink {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [string]$Path = '.cursor/rules'
    )

    Invoke-TestGit -Repository $Repository -Arguments @(
        'update-index', '--add', '--cacheinfo',
        "160000,$global:QuickAdoptionProtocolSha,$Path"
    ) | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @(
        'commit', '-m', "Add exact-root authority gitlink at $Path"
    ) | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @(
        'push', 'origin', 'main'
    ) | Out-Null
    $ruleRoot = Join-Path $Repository $Path
    New-Item -ItemType Directory -Path (Split-Path -Parent $ruleRoot) `
        -Force | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @(
        'clone', '--no-checkout',
        $global:QuickAdoptionProtocolRepository, $ruleRoot
    ) | Out-Null
    Invoke-TestGit -Repository $ruleRoot -Arguments @(
        'checkout', '--detach', $global:QuickAdoptionProtocolSha
    ) | Out-Null
}

function New-MockEmptyRemoteConsumer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$CreateRepository
    )

    $consumerRoot = New-TempRoot -Name $Name
    $repositoryPath = Join-Path $consumerRoot 'consumer'
    $remotePath = Join-Path $consumerRoot 'consumer.git'
    New-Item -ItemType Directory -Path $repositoryPath -Force | Out-Null
    & git init -b main $repositoryPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the mock empty-remote consumer.'
    }
    Set-TestGitIdentity -Repository $repositoryPath
    $slug = "test-owner/$Name"
    $url = "https://github.com/$slug.git"
    if ($CreateRepository) {
        $global:QuickAdoptionRepositoryExists = $false
        $global:QuickAdoptionNewRemote = $remotePath
        [IO.File]::WriteAllText(
            (Join-Path $repositoryPath 'FG_PAT.txt'),
            [string]$global:QuickAdoptionExpectedUpdaterToken,
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $repositoryPath 'MEANDAI_RO_FG_PAT.txt'),
            [string]$global:QuickAdoptionExpectedProtocolToken,
            [Text.UTF8Encoding]::new($false)
        )
    }
    else {
        & git init --bare $remotePath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to initialize the mock existing empty remote.'
        }
        Invoke-TestGit -Repository $repositoryPath -Arguments @(
            'config', "url.$($remotePath.Replace('\', '/')).insteadOf", $url
        ) | Out-Null
    }
    $global:QuickAdoptionRepoName = $slug
    $global:QuickAdoptionDefaultBranch = ''
    $global:QuickAdoptionTargetPath = $repositoryPath
    $global:QuickAdoptionRemotePath = $remotePath
    $global:QuickAdoptionExistingSecrets.Add('MEANDAI_UPDATER_TOKEN')
    $global:QuickAdoptionExistingSecrets.Add('MEANDAI_PROTOCOL_TOKEN')
    return [pscustomobject]@{
        Repository = $repositoryPath
        Remote = $remotePath
        Slug = $slug
        Name = $Name
        Url = $url
        Created = [bool]$CreateRepository
    }
}

function New-MockCompletedAdoptionConsumer {
    param([Parameter(Mandatory)][string]$Name)

    $consumer = New-MockConnectedSeedConsumer -Name $Name
    $global:QuickAdoptionExistingSecrets.Add('MEANDAI_UPDATER_TOKEN')
    $global:QuickAdoptionExistingSecrets.Add('MEANDAI_PROTOCOL_TOKEN')
    Remove-Item -LiteralPath (Join-Path $consumer.Repository 'FG_PAT.txt') `
        -Force
    Remove-Item -LiteralPath (
        Join-Path $consumer.Repository 'MEANDAI_RO_FG_PAT.txt'
    ) -Force
    & $launcherPath -TargetPath $consumer.Repository `
        -CodexCommand $mockCodexPath | Out-Null
    $completedBranch = 'automation/meandai-capabilities-v0.12.7'
    $remoteHeadLine = @(Invoke-TestGit -Repository $consumer.Repository `
        -Arguments @('ls-remote', '--heads', 'origin', "refs/heads/$completedBranch"))
    if ($remoteHeadLine.Count -ne 1) {
        throw 'The independent completed-adoption baseline has no exact remote head.'
    }
    return [pscustomobject]@{
        Repository = $consumer.Repository
        Remote = $consumer.Remote
        CompletedHead = ([string]$remoteHeadLine[0]).Split("`t")[0]
        CompletedBody = [string]$global:QuickAdoptionPrBody
    }
}

function Initialize-MockAdoptionPullRequestBody {
    if ($global:QuickAdoptionPrBody) {
        return
    }
    $proposalState = if ($global:QuickAdoptionProposalMode -ceq 'ManifestOnly') {
        'AdoptionReviewRequired'
    }
    else {
        'BootstrapReady'
    }
    $markerStrategy = if ($global:QuickAdoptionDispatchedStrategy) {
        [string]$global:QuickAdoptionDispatchedStrategy
    }
    else { 'FreshAdoption' }
    $sourceGraphIdentity =
        $global:QuickAdoptionDispatchedSourceGraphIdentity
    $markerRecord = if ($null -ne $sourceGraphIdentity) {
        [ordered]@{
            schema = 7
            phase = 'Proposed'
            state = $proposalState
            target = 'v0.12.7'
            protocolSha = $global:QuickAdoptionProtocolSha
            head = $global:QuickAdoptionPrHead
            branch = 'automation/meandai-capabilities-v0.12.7'
            adoptionStrategy = $markerStrategy
            protocolSurfaces = @($sourceGraphIdentity.protocolSurfaces)
            protocolRecordLossAcknowledged =
                [bool]$global:QuickAdoptionDispatchedLossAcknowledgement
            graphBase = [string]$sourceGraphIdentity.graphBase
            graphDigest = [string]$sourceGraphIdentity.graphDigest
            graphCounts = $sourceGraphIdentity.graphCounts
            graphLimits = $sourceGraphIdentity.graphLimits
            repository = $global:QuickAdoptionRepoName
            actor = $global:QuickAdoptionOwner
        }
    }
    else {
        [ordered]@{
            schema = 5
            phase = 'Proposed'
            state = $proposalState
            target = 'v0.12.7'
            protocolSha = $global:QuickAdoptionProtocolSha
            head = $global:QuickAdoptionPrHead
            adoptionStrategy = $markerStrategy
            protocolSurfaces = @($global:QuickAdoptionProposalSurfaces)
            protocolRecordLossAcknowledged =
                [bool]$global:QuickAdoptionDispatchedLossAcknowledgement
            repository = $global:QuickAdoptionRepoName
            actor = $global:QuickAdoptionOwner
        }
    }
    $marker = $markerRecord | ConvertTo-Json -Depth 8 -Compress
    $global:QuickAdoptionPrBody = "<!-- meandai-capabilities-adoption:$marker -->`n`nMock adoption proposal."
}

function Get-MockCodexCallLog {
    if (-not (Test-Path -LiteralPath $global:QuickAdoptionCodexLog -PathType Leaf)) {
        return @()
    }
    $calls = [System.Collections.Generic.List[object]]::new()
    foreach ($line in [IO.File]::ReadAllLines($global:QuickAdoptionCodexLog)) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $calls.Add(($line | ConvertFrom-Json))
        }
    }
    return @($calls)
}

function Get-MockCodexCalls {
    return @(Get-MockCodexCallLog | Where-Object {
        $_.Arguments.Count -eq 0 -or $_.Arguments[0] -cne 'sandbox'
    })
}

function Get-MockCodexSandboxCalls {
    return @(Get-MockCodexCallLog | Where-Object {
        $_.Arguments.Count -gt 0 -and $_.Arguments[0] -ceq 'sandbox'
    })
}

function New-TestQuickAdoptionManifest {
    param(
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$State,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$Strategy,
        [AllowEmptyCollection()][object[]]$ProtocolSurfaces = @(),
        [bool]$ProtocolRecordLossAcknowledged = $false,
        [AllowEmptyCollection()][object[]]$Collisions = @(),
        [AllowNull()]$SourceGraphRecord = $null
    )

    $manifest = [ordered]@{
        schema = if ($null -eq $SourceGraphRecord) { 2 } else { 3 }
        operation = 'ai-capabilities-adoption'
        state = $State
        repository = $Repository
        targetTag = 'v0.12.7'
        protocolSha = $ProtocolSha
        adoptionStrategy = $Strategy
        protocolSurfaces = @($ProtocolSurfaces)
        protocolRecordLossAcknowledged = $ProtocolRecordLossAcknowledged
        collisions = @($Collisions)
        proposedPaths = @($canonicalAdoptionProposedPaths)
        requiredTasks = @($canonicalAdoptionRequiredTasks)
    }
    if ($null -ne $SourceGraphRecord) {
        $manifest['sourceGraph'] = $SourceGraphRecord
    }
    switch -CaseSensitive ($Mode) {
        'Valid' { }
        'AdditionalProperty' { $manifest['unexpected'] = $true }
        'MissingProperty' { $manifest.Remove('requiredTasks') }
        'WrongRequiredTasks' {
            $manifest['requiredTasks'] = @('Remove the manifest before readiness.')
        }
        'WrongProposedPaths' {
            $manifest['proposedPaths'] = @(
                $canonicalAdoptionProposedPaths | Select-Object -Skip 1
            )
        }
        'WrongCollisions' { $manifest['collisions'] = @('docs/ideas/README.md') }
        'WrongRepository' { $manifest['repository'] = 'other/consumer' }
        'WrongTargetTag' { $manifest['targetTag'] = 'v0.8.4' }
        'WrongProtocolSha' { $manifest['protocolSha'] = 'b' * 40 }
        'WrongStrategy' {
            $manifest['adoptionStrategy'] = if ($Strategy -ceq 'FreshAdoption') {
                'FullMigration'
            }
            else { 'FreshAdoption' }
        }
        'WrongSurfaces' {
            $manifest['protocolSurfaces'] = @(
                @($ProtocolSurfaces) + 'docs/governance/unobserved.md' |
                    Sort-Object -CaseSensitive
            )
        }
        'WrongLossAcknowledgement' {
            $manifest['protocolRecordLossAcknowledged'] =
                -not $ProtocolRecordLossAcknowledged
        }
        'WrongState' {
            $manifest['state'] = if ($State -ceq 'BootstrapReady') {
                'AdoptionReviewRequired'
            }
            else { 'BootstrapReady' }
        }
        'WrongOperation' { $manifest['operation'] = 'other-operation' }
        'WrongSchema' { $manifest['schema'] = 1 }
        'WrongSchemaType' { $manifest['schema'] = '2' }
        'WrongCollisionType' { $manifest['collisions'] = 'AGENTS.md' }
        'ArrayRoot' { return ,@([pscustomobject]$manifest, [pscustomobject]$manifest) }
        default { throw "Unknown mock adoption manifest mode '$Mode'." }
    }
    return [pscustomobject]$manifest
}

function New-TestQuickAdoptionPullRequestContractFixture {
    param(
        [Parameter(Mandatory)][string]$Mode,
        [string]$Strategy = 'FullMigration',
        [AllowEmptyCollection()][object[]]$ProtocolSurfaces = @('AGENTS.md')
    )

    $head = 'c' * 40
    $marker = [ordered]@{
        schema = 5
        phase = 'Proposed'
        state = 'AdoptionReviewRequired'
        target = 'v0.12.7'
        protocolSha = 'a' * 40
        head = $head
        adoptionStrategy = $Strategy
        protocolSurfaces = @($ProtocolSurfaces)
        protocolRecordLossAcknowledged = $false
        repository = 'test-owner/consumer'
        actor = 'test-owner'
    }
    $pullRequest = [pscustomobject][ordered]@{
        number = 42
        url = 'https://github.com/test-owner/consumer/pull/42'
        headRefName = 'automation/meandai-capabilities-v0.12.7'
        headRefOid = $head
        baseRefName = 'main'
        headRepository = [pscustomobject]@{
            nameWithOwner = 'test-owner/consumer'
        }
        author = [pscustomobject]@{ login = 'test-owner' }
        body = ''
        isDraft = $true
        state = 'OPEN'
    }
    switch -CaseSensitive ($Mode) {
        'Valid' { }
        'WrongBase' { $pullRequest.baseRefName = 'develop' }
        'WrongAuthor' {
            $pullRequest.author = [pscustomobject]@{ login = 'untrusted-actor' }
        }
        'NonDraft' { $pullRequest.isDraft = $false }
        'InvalidMarker' { $marker = [ordered]@{ schema = 1 } }
        'MarkerHeadMismatch' { $marker.head = '0' * 40 }
        'MarkerStrategyMismatch' { $marker.adoptionStrategy = 'FreshAdoption' }
        default { throw "Unknown pull-request contract mode '$Mode'." }
    }
    $markerJson = $marker | ConvertTo-Json -Compress
    $pullRequest.body =
        "<!-- meandai-capabilities-adoption:$markerJson -->"
    return @{
        PullRequest = $pullRequest
        RemoteHead = $head
        Repository = 'test-owner/consumer'
        Branch = 'automation/meandai-capabilities-v0.12.7'
        BaseBranch = 'main'
        TargetTag = 'v0.12.7'
        TargetSha = 'a' * 40
        ExpectedActor = 'test-owner'
        ExpectedState = 'AdoptionReviewRequired'
        ExpectedAdoptionStrategy = $Strategy
        ExpectedProtocolSurfaces = @($ProtocolSurfaces)
        ExpectedProtocolRecordLossAcknowledgement = $false
        ExpectedPhase = 'Proposed'
    }
}

function New-TestQuickAdoptionCompletionContractFixture {
    param(
        [Parameter(Mandatory)][string]$Strategy,
        [AllowEmptyCollection()][object[]]$ProtocolSurfaces = @(),
        [AllowEmptyCollection()][object[]]$Changes = @(),
        [AllowEmptyCollection()][object[]]$AdditionalEntries = @()
    )

    $targetCommand = Get-TestQuickAdoptionContractCommand `
        -Name 'Get-MeAndAIAdoptionTargetPaths'
    $targetPaths = @(& $targetCommand)
    $entryMap = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $targetPaths) {
        $value = [string]$path
        $entryMap[$value] = [pscustomobject]@{
            Path = $value
            Exists = $true
            Mode = if ($value -ceq '.ai/protocol') { '160000' } else { '100644' }
        }
    }
    foreach ($entry in @($AdditionalEntries)) {
        $entryMap[[string]$entry.Path] = $entry
    }
    foreach ($change in @($Changes)) {
        $path = [string]$change.Path
        if (-not $entryMap.ContainsKey($path)) {
            $exists = [string]$change.Status -cne 'D'
            $entryMap[$path] = [pscustomobject]@{
                Path = $path
                Exists = $exists
                Mode = if ($exists) { '100644' } else { '' }
            }
        }
    }
    return @{
        Changes = @(
            [pscustomobject]@{
                Status = 'D'
                Path = '.ai/adoption/meandai-capabilities.json'
            }
        ) + @($Changes)
        ExpectedAdoptionStrategy = $Strategy
        ProtocolSurfaces = @($ProtocolSurfaces)
        TargetPaths = @($targetPaths)
        FinalEntries = @($entryMap.Values)
    }
}

function Publish-MockAdoptionBranch {
    $branch = 'automation/meandai-capabilities-v0.12.7'
    if ($global:QuickAdoptionPrHead) {
        $remoteLine = @((Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'ls-remote', '--heads', 'origin', "refs/heads/$branch"
        )) | Select-Object -First 1)
        if ($remoteLine.Count -eq 1) {
            $global:QuickAdoptionPrHead = ([string]$remoteLine[0]).Split("`t")[0]
        }
        Initialize-MockAdoptionPullRequestBody
        return
    }

    $work = New-TempRoot -Name 'adoption-branch'
    $clone = Join-Path $work 'clone'
    Invoke-TestGit -Repository $work -Arguments @(
        'clone', $global:QuickAdoptionRemotePath, $clone
    ) | Out-Null
    Set-TestGitIdentity -Repository $clone
    Invoke-TestGit -Repository $clone -Arguments @('checkout', '-b', $branch, 'origin/main') | Out-Null

    $basePaths = @(Invoke-TestGit -Repository $clone -Arguments @(
        'ls-tree', '-r', '--name-only', 'origin/main'
    ))
    $global:QuickAdoptionProposalSurfaces = @(
        if ($null -ne $global:QuickAdoptionDispatchedSourceGraphIdentity) {
            $global:QuickAdoptionDispatchedSourceGraphIdentity.protocolSurfaces
        }
        else {
            Get-TestProtocolSurfaceInventory -Paths $basePaths
        }
    )
    $proposalStrategy = if ($global:QuickAdoptionDispatchedStrategy) {
        [string]$global:QuickAdoptionDispatchedStrategy
    }
    else { 'FreshAdoption' }

    $manifestPath = Join-Path $clone '.ai/adoption/meandai-capabilities.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $manifestPath) -Force | Out-Null
    $manifestOnly = $global:QuickAdoptionProposalMode -ceq 'ManifestOnly'
    $proposalProtocolSha = if ($global:QuickAdoptionProposalMode -ceq 'WrongProtocolSha') {
        (@(Invoke-TestGit -Repository $clone -Arguments @('rev-parse', 'origin/main')))[0]
    }
    else {
        $global:QuickAdoptionProtocolSha
    }
    [object[]]$manifestCollisions = [object[]]::new(0)
    if ($manifestOnly) {
        $manifestCollisions = @(
            foreach ($targetPath in @($canonicalAdoptionProposedPaths |
                    Where-Object { $_ -cne $workflowRelativePath })) {
                $collisionFound = @($basePaths | Where-Object {
                    $_.Equals(
                        $targetPath,
                        [StringComparison]::OrdinalIgnoreCase
                    ) -or
                    $_.StartsWith(
                        "$targetPath/",
                        [StringComparison]::OrdinalIgnoreCase
                    ) -or
                    $targetPath.StartsWith(
                        "$($_)/",
                        [StringComparison]::OrdinalIgnoreCase
                    )
                }).Count -gt 0
                if ($collisionFound) {
                    $targetPath
                }
            }
        )
    }
    $manifestState = if ($manifestOnly) {
        'AdoptionReviewRequired'
    }
    else { 'BootstrapReady' }
    $manifestData = New-TestQuickAdoptionManifest `
        -Mode $global:QuickAdoptionManifestMode `
        -Repository $global:QuickAdoptionRepoName `
        -State $manifestState `
        -ProtocolSha $global:QuickAdoptionProtocolSha `
        -Strategy $proposalStrategy `
        -ProtocolSurfaces $global:QuickAdoptionProposalSurfaces `
        -ProtocolRecordLossAcknowledged ([bool]$global:QuickAdoptionDispatchedLossAcknowledgement) `
        -Collisions $manifestCollisions `
        -SourceGraphRecord $global:QuickAdoptionDispatchedSourceGraphRecord
    $manifest = $manifestData | ConvertTo-Json -Depth 100 -Compress
    [IO.File]::WriteAllText(
        $manifestPath,
        $manifest + "`n",
        [Text.UTF8Encoding]::new($false)
    )
    if (-not $manifestOnly) {
        $gitmodules = @(
            '[submodule ".ai/protocol"]',
            "`tpath = .ai/protocol",
            "`turl = https://github.com/hasanmanzak/meAndAI.git",
            ''
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $clone '.gitmodules') -Value $gitmodules -NoNewline
        Invoke-TestGit -Repository $clone -Arguments @(
            'update-index', '--add', '--cacheinfo', "160000,$proposalProtocolSha,.ai/protocol"
        ) | Out-Null
        foreach ($asset in $canonicalAdoptionAssets) {
            $sourcePath = Join-Path $global:QuickAdoptionProtocolRepository `
                (([string]$asset.TemplatePath) -replace '/', [IO.Path]::DirectorySeparatorChar)
            $destinationPath = Join-Path $clone `
                (([string]$asset.ConsumerPath) -replace '/', [IO.Path]::DirectorySeparatorChar)
            New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) `
                -Force | Out-Null
            Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
        }
        $migrationBaseline = Get-MockConsumerMigrationBaseline
        $ledgerPath = Join-Path $clone ([string]$migrationBaseline.Path)
        New-Item -ItemType Directory -Path (Split-Path -Parent $ledgerPath) `
            -Force | Out-Null
        [IO.File]::WriteAllBytes(
            $ledgerPath, [byte[]]$migrationBaseline.Bytes
        )
        $proposalPaths = @('.gitmodules', '.ai/adoption/meandai-capabilities.json') + @(
            $canonicalAdoptionAssets | ForEach-Object { [string]$_.ConsumerPath }
        ) + @([string]$migrationBaseline.Path)
        Invoke-TestGit -Repository $clone `
            -Arguments (@('add', '--') + $proposalPaths) | Out-Null
    }
    else {
        Invoke-TestGit -Repository $clone -Arguments @(
            'add', '--', '.ai/adoption/meandai-capabilities.json'
        ) | Out-Null
    }
    Invoke-TestGit -Repository $clone -Arguments @('commit', '-m', 'Create mock adoption draft') | Out-Null
    Invoke-TestGit -Repository $clone -Arguments @('push', 'origin', $branch) | Out-Null
    $global:QuickAdoptionPrHead = (@(Invoke-TestGit -Repository $clone -Arguments @('rev-parse', 'HEAD')))[0]
    Initialize-MockAdoptionPullRequestBody
}

function Reset-MockAdoptionProposal {
    $branch = 'automation/meandai-capabilities-v0.12.7'
    $branchLines = @(Invoke-TestGit `
        -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'ls-remote', '--heads', 'origin', "refs/heads/$branch"
        ))
    if ($branchLines.Count -eq 1) {
        Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'push', 'origin', '--delete', $branch
        ) | Out-Null
    }
    $global:QuickAdoptionPrHead = ''
    $global:QuickAdoptionPrBody = ''
    $global:QuickAdoptionPrDraft = $true
    $global:QuickAdoptionPrState = 'OPEN'
    $global:QuickAdoptionPrReadyCalls = 0
    $global:QuickAdoptionPrReadyUndoCalls = 0
    $global:QuickAdoptionPrBodyEditCalls = 0
    $global:QuickAdoptionPrBodyEditMode = 'Normal'
    $global:QuickAdoptionCompletedEditFailures = 0
    $global:QuickAdoptionRunListCalls = 0
    $global:QuickAdoptionWorkflowDispatched = $false
    $global:QuickAdoptionExpectedPublishedHead = ''
    $global:QuickAdoptionDispatchRecord = $null
    $global:QuickAdoptionDispatchedStrategy = ''
    $global:QuickAdoptionDispatchedLossAcknowledgement = $false
    $global:QuickAdoptionDispatchedBaseSha = ''
    $global:QuickAdoptionDispatchedSourceGraphIdentity = $null
    $global:QuickAdoptionDispatchedSourceGraphRecord = $null
    $global:QuickAdoptionWorkflowSupportsSourceGraphIdentity = $null
    $global:QuickAdoptionProposalSurfaces = @()
    $global:QuickAdoptionPrListCalls = 0
    $global:QuickAdoptionRepoViewCalls = 0
    $global:QuickAdoptionRepoViewMode = 'Valid'
    $global:QuickAdoptionManifestMode = 'Valid'
    $global:QuickAdoptionIssueEditMode = 'Normal'
    $global:QuickAdoptionIssueEditFailures = 0
}

function global:Invoke-RestMethod {
    [CmdletBinding()]
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = 'Get'
    )

    $credentialBoundary = if ($Uri -match '/repos/hasanmanzak/meAndAI/') {
        'protocol-read'
    }
    else { 'consumer-write' }
    $expectedToken = if ($credentialBoundary -ceq 'protocol-read') {
        $global:QuickAdoptionExpectedProtocolToken
    }
    else { $global:QuickAdoptionExpectedUpdaterToken }
    if ($Method -cne 'Get' -or
        [string]$Headers.Accept -cne 'application/vnd.github+json' -or
        [string]$Headers.Authorization -cne "Bearer $expectedToken" -or
        [string]$Headers['X-GitHub-Api-Version'] -cne '2026-03-10' -or
        [string]$Headers['User-Agent'] -cne 'meAndAI-quick-adoption') {
        throw "TEST-0073 REST credential boundary '$credentialBoundary' used invalid method or headers."
    }
    $global:QuickAdoptionRestCalls.Add([pscustomobject]@{
        Method = $Method
        Uri = $Uri
        CredentialBoundary = $credentialBoundary
    })

    if ($Uri -match '/repos/hasanmanzak/meAndAI/releases/tags/(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        $tag = [string]$Matches.tag
        if ($global:QuickAdoptionReleaseMode -ceq 'Missing') {
            throw 'Mock release is missing.'
        }
        return [pscustomobject]@{
            id = 73
            tag_name = if ($global:QuickAdoptionReleaseMode -ceq 'WrongTag') { 'v0.7.2' } else { $tag }
            draft = $false
            prerelease = $false
            immutable = $global:QuickAdoptionReleaseMode -ceq 'Immutable'
            published_at = '2026-07-15T00:00:00Z'
        }
    }

    if ($Uri -match '/repos/hasanmanzak/meAndAI/commits/(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        $tag = [string]$Matches.tag
        if (-not $global:QuickAdoptionProtocolReleaseCommits.ContainsKey($tag)) {
            throw "Mock protocol commit is missing for '$tag'."
        }
        return [pscustomobject]@{ sha = $global:QuickAdoptionProtocolReleaseCommits[$tag] }
    }

    if ($Uri -match '/contents/(?<path>.+)\?ref=(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        $tag = [string]$Matches.tag
        $templatePath = [string]$Matches.path
        $key = "$tag`n$templatePath"
        if (-not $global:QuickAdoptionProtocolAssetBytes.ContainsKey($key)) {
            throw "Mock protocol asset is missing for '${tag}:$templatePath'."
        }
        $asset = $global:QuickAdoptionProtocolAssetBytes[$key]
        if ($templatePath -ceq
            'templates/project/.github/workflows/meandai-protocol-update.yml') {
            $workflowText = [Text.UTF8Encoding]::new(
                $false, $true
            ).GetString([byte[]]$asset.Bytes)
            $global:QuickAdoptionWorkflowSupportsSourceGraphIdentity =
                [regex]::Matches(
                    $workflowText,
                    '(?m)^ {6}source_graph_identity:[ \t]*\r?$'
                ).Count -eq 1
        }
        return [pscustomobject]@{
            content = [Convert]::ToBase64String([byte[]]$asset.Bytes)
            encoding = 'base64'
            sha = [string]$asset.Sha
        }
    }

    if ($Uri -match '/repos/[^/]+/[^/]+$') {
        if ($global:QuickAdoptionDenyTargetAccess) {
            throw 'Mock selected-repository grant does not include the target.'
        }
        return [pscustomobject]@{ full_name = $global:QuickAdoptionRepoName }
    }

    throw "Unexpected Invoke-RestMethod call: $Method $Uri"
}

function global:Invoke-WebRequest {
    [CmdletBinding()]
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$OutFile,
        [switch]$UseBasicParsing
    )

    if ($Uri -notmatch '/repos/hasanmanzak/meAndAI/zipball/[0-9a-f]{40}$') {
        throw "Unexpected Invoke-WebRequest call: $Uri"
    }
    if ([string]$Headers.Accept -cne 'application/vnd.github+json' -or
        [string]$Headers.Authorization -cne "Bearer $($global:QuickAdoptionExpectedProtocolToken)" -or
        [string]$Headers['X-GitHub-Api-Version'] -cne '2026-03-10' -or
        [string]$Headers['User-Agent'] -cne 'meAndAI-quick-adoption') {
        throw 'TEST-0073 protocol archive download used invalid authorization or API-version headers.'
    }
    # Archive the immutable synthetic release instead of re-reading the live
    # worktree, which may be changing while this integration suite is running.
    if (-not ('System.IO.Compression.ZipFile' -as [type])) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }
    Copy-QuickAdoptionReleaseArchive -OutFile $OutFile
    $archive = [IO.Compression.ZipFile]::OpenRead($OutFile)
    try {
        $capabilitiesEntry = @($archive.Entries | Where-Object {
            ([string]$_.FullName).Replace('\', '/') -ceq
                'openai-mock-protocol/templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
        })
        if ($capabilitiesEntry.Count -ne 1) {
            throw 'Mock protocol archive omitted the exact capabilities contract module.'
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Assert-MockGhApiHeaders {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $accept = @($Arguments | Where-Object { $_ -ceq 'Accept: application/vnd.github+json' })
    $version = @($Arguments | Where-Object { $_ -ceq 'X-GitHub-Api-Version: 2026-03-10' })
    if ($accept.Count -ne 1 -or $version.Count -ne 1) {
        throw 'TEST-0073 authenticated gh API call omitted its exact Accept or API-version header.'
    }
}

function Get-MockGhArgumentValue {
    param(
        [Parameter(Mandatory)][object[]]$Arguments,
        [Parameter(Mandatory)][string]$Name
    )

    $index = [Array]::IndexOf($Arguments, $Name)
    if ($index -lt 0 -or $index + 1 -ge $Arguments.Count) {
        return $null
    }
    return [string]$Arguments[$index + 1]
}

function Test-MockInitialPolicyAuthorityCall {
    param([Parameter(Mandatory)]$Call)

    $arguments = @($Call.Arguments)
    $joined = $arguments -join ' '
    if ($joined -cin @('--version', 'auth status')) {
        return $true
    }
    if ($arguments.Count -lt 2 -or $arguments[0] -cne 'api' -or
        $arguments -ccontains '--method' -or $arguments -ccontains '-X') {
        return $false
    }
    $endpoint = @($arguments | Where-Object {
        [string]$_ -like 'repos/hasanmanzak/meAndAI/*'
    } | Select-Object -Last 1)
    if ($endpoint.Count -ne 1) {
        return $false
    }
    return [string]$endpoint[0] -cin @(
        'repos/hasanmanzak/meAndAI/releases/tags/v0.12.7',
        'repos/hasanmanzak/meAndAI/commits/v0.12.7',
        'repos/hasanmanzak/meAndAI/contents/templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1?ref=v0.12.7'
    )
}

function Get-MockUnexpectedPreflightGhCalls {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Calls)

    return @($Calls | Where-Object {
        -not (Test-MockInitialPolicyAuthorityCall -Call $_)
    })
}

function Get-TestLoadedInitialAdoptionPolicyModules {
    return @(Get-Module | Where-Object {
        [string]$_.Name -like 'MeAndAI.InitialAdoptionPolicy.*'
    })
}

function Get-TestQuickAdoptionContractCommand {
    param([Parameter(Mandatory)][string]$Name)

    if ($null -eq $script:QuickAdoptionContractModule) {
        if ([string]::IsNullOrWhiteSpace(
                [string]$global:QuickAdoptionProtocolRepository
            )) {
            throw 'The immutable quick-adoption protocol fixture is unavailable.'
        }
        $modulePath = Join-Path $global:QuickAdoptionProtocolRepository `
            'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
        $loaded = @(Import-Module -Name $modulePath -Force -PassThru)
        if ($loaded.Count -ne 1) {
            throw 'The production quick-adoption contract module did not load exactly once.'
        }
        $script:QuickAdoptionContractModule = $loaded[0]
    }

    $command = $script:QuickAdoptionContractModule.ExportedCommands[$Name]
    if ($null -eq $command -or
        [string]$command.ModuleName -cne
            [string]$script:QuickAdoptionContractModule.Name) {
        throw "The production quick-adoption contract does not export '$Name'."
    }
    return $command
}

function Get-MockPublishedDefaultHead {
    $remoteLine = @((Invoke-TestGit -Repository $global:QuickAdoptionTargetPath `
        -Arguments @(
            'ls-remote', '--heads', 'origin',
            "refs/heads/$($global:QuickAdoptionDefaultBranch)"
        )) | Select-Object -First 1)
    if ($remoteLine.Count -ne 1) {
        throw 'Mock could not independently resolve the published default-branch head.'
    }
    $head = ([string]$remoteLine[0]).Split("`t")[0]
    if ($head -cnotmatch '^[0-9a-f]{40}$') {
        throw "Mock resolved an invalid published head '$head'."
    }
    return $head
}

function Advance-MockPublishedDefaultBranch {
    $advanceRoot = New-TempRoot -Name 'base-advance'
    $advanceClone = Join-Path $advanceRoot 'clone'
    Invoke-TestGit -Repository $advanceRoot -Arguments @(
        'clone', '--branch', $global:QuickAdoptionDefaultBranch,
        $global:QuickAdoptionRemotePath, $advanceClone
    ) | Out-Null
    Set-TestGitIdentity -Repository $advanceClone
    [IO.File]::WriteAllText(
        (Join-Path $advanceClone 'base-race.txt'),
        "advanced consumer base`n",
        [Text.UTF8Encoding]::new($false)
    )
    Invoke-TestGit -Repository $advanceClone -Arguments @(
        'add', '--', 'base-race.txt'
    ) | Out-Null
    Invoke-TestGit -Repository $advanceClone -Arguments @(
        'commit', '-m', 'Advance mock consumer base'
    ) | Out-Null
    Invoke-TestGit -Repository $advanceClone -Arguments @(
        'push', 'origin', "HEAD:$($global:QuickAdoptionDefaultBranch)"
    ) | Out-Null
    $global:QuickAdoptionBaseAdvanceCalls++
}

function global:gh {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline = $true)][string]$InputValue,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )

    $global:LASTEXITCODE = 0
    $stdin = if ($PSBoundParameters.ContainsKey('InputValue')) {
        $InputValue
    }
    else {
        (@($input) -join [Environment]::NewLine)
    }
    $global:QuickAdoptionGhCalls.Add([pscustomobject]@{
        Arguments = @($Arguments)
        Stdin = $stdin
        Host = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')
    })

    $joined = $Arguments -join ' '
    if ($joined -eq '--version') {
        return $global:QuickAdoptionGhVersionOutput
    }
    if ($joined -eq 'auth status') {
        return
    }
    if ($joined -eq 'api user --jq .login') {
        return $global:QuickAdoptionOwner
    }
    $secretLockEndpoint = "repos/$($global:QuickAdoptionRepoName)/labels/meandai%3Asecret-reconciliation-lock"
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'api' -and
        $Arguments -contains $secretLockEndpoint) {
        Assert-MockGhApiHeaders -Arguments $Arguments
        if ($Arguments -contains 'DELETE') {
            if (-not $global:QuickAdoptionLabelRecords.ContainsKey('meandai:secret-reconciliation-lock')) {
                throw 'Mock secret lock delete targeted an absent label.'
            }
            [void]$global:QuickAdoptionLabelRecords.Remove('meandai:secret-reconciliation-lock')
            return
        }
        $global:QuickAdoptionSecretLockViewCalls++
        $record = $global:QuickAdoptionLabelRecords['meandai:secret-reconciliation-lock']
        if ($null -eq $record) {
            throw 'Mock secret lock lookup targeted an absent label.'
        }
        if ($global:QuickAdoptionSecretLockMode -ceq 'OwnershipChanged' -and
            $global:QuickAdoptionSecretLockViewCalls -gt 1) {
            $record = [pscustomobject]@{
                name = 'meandai:secret-reconciliation-lock'
                description = 'foreign lock owner'
            }
            $global:QuickAdoptionLabelRecords['meandai:secret-reconciliation-lock'] = $record
        }
        return ($record | ConvertTo-Json -Compress)
    }
    $apiEndpoint = @(if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'api') {
        $Arguments | Where-Object {
            [string]$_ -like 'repos/hasanmanzak/meAndAI/*'
        } | Select-Object -Last 1
    }
    else { })
    if ($apiEndpoint.Count -eq 1 -and
        [string]$apiEndpoint[0] -match '^repos/hasanmanzak/meAndAI/releases/tags/(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        Assert-MockGhApiHeaders -Arguments $Arguments
        $tag = [string]$Matches.tag
        if ($global:QuickAdoptionReleaseMode -ceq 'Missing') {
            throw 'Mock release is missing.'
        }
        return (@{
            id = 73
            tag_name = if ($global:QuickAdoptionReleaseMode -ceq 'WrongTag') { 'v0.7.2' } else { $tag }
            draft = $false
            prerelease = $false
            immutable = $global:QuickAdoptionReleaseMode -ceq 'Immutable'
            published_at = '2026-07-15T00:00:00Z'
        } | ConvertTo-Json -Compress)
    }
    if ($apiEndpoint.Count -eq 1 -and
        [string]$apiEndpoint[0] -match '^repos/hasanmanzak/meAndAI/commits/(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        Assert-MockGhApiHeaders -Arguments $Arguments
        $tag = [string]$Matches.tag
        if (-not $global:QuickAdoptionProtocolReleaseCommits.ContainsKey($tag)) {
            throw "Mock protocol commit is missing for '$tag'."
        }
        return (@{ sha = $global:QuickAdoptionProtocolReleaseCommits[$tag] } |
            ConvertTo-Json -Compress)
    }
    if ($apiEndpoint.Count -eq 1 -and
        [string]$apiEndpoint[0] -match '^repos/hasanmanzak/meAndAI/contents/(?<path>.+)\?ref=(?<tag>v[0-9]+\.[0-9]+\.[0-9]+)$') {
        Assert-MockGhApiHeaders -Arguments $Arguments
        $tag = [string]$Matches.tag
        $templatePath = [string]$Matches.path
        $key = "$tag`n$templatePath"
        if (-not $global:QuickAdoptionProtocolAssetBytes.ContainsKey($key)) {
            throw "Mock protocol asset is missing for '${tag}:$templatePath'."
        }
        $asset = $global:QuickAdoptionProtocolAssetBytes[$key]
        if ($templatePath -ceq
            'templates/project/.github/workflows/meandai-protocol-update.yml') {
            $workflowText = [Text.UTF8Encoding]::new(
                $false, $true
            ).GetString([byte[]]$asset.Bytes)
            $global:QuickAdoptionWorkflowSupportsSourceGraphIdentity =
                [regex]::Matches(
                    $workflowText,
                    '(?m)^ {6}source_graph_identity:[ \t]*\r?$'
                ).Count -eq 1
        }
        return (@{
            content = [Convert]::ToBase64String([byte[]]$asset.Bytes)
            encoding = 'base64'
            sha = [string]$asset.Sha
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 4 -and $Arguments[0] -eq 'repo' -and
        $Arguments[1] -eq 'clone' -and $Arguments[2] -eq 'hasanmanzak/meAndAI') {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $cloneOutput = & git clone `
                $global:QuickAdoptionProtocolRepository $Arguments[3] 2>&1
            $cloneExitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousPreference
        }
        if ($cloneExitCode -ne 0) {
            throw "Unable to clone the mock protocol repository: $($cloneOutput -join [Environment]::NewLine)"
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'repo' -and $Arguments[1] -eq 'view') {
        if (-not $global:QuickAdoptionRepositoryExists) {
            $global:LASTEXITCODE = 1
            return 'GraphQL: Could not resolve to a Repository with the requested name.'
        }
        $global:QuickAdoptionRepoViewCalls++
        $liveDefaultBranch = Get-MockLiveDefaultBranch
        $reportedDefaultBranch = switch -CaseSensitive (
            [string]$global:QuickAdoptionRepoViewMode
        ) {
            'Valid' { $liveDefaultBranch }
            'WrongAfterFirst' {
                if ($global:QuickAdoptionRepoViewCalls -gt 1) { 'develop' }
                else { $liveDefaultBranch }
            }
            'WrongAfterSecond' {
                if ($global:QuickAdoptionRepoViewCalls -gt 2) { 'develop' }
                else { $liveDefaultBranch }
            }
            'WrongAfterThird' {
                if ($global:QuickAdoptionRepoViewCalls -gt 3) { 'develop' }
                else { $liveDefaultBranch }
            }
            'WrongAfterFourth' {
                if ($global:QuickAdoptionRepoViewCalls -gt 4) { 'develop' }
                else { $liveDefaultBranch }
            }
            'DevelopAfterFirst' {
                if ($global:QuickAdoptionRepoViewCalls -gt 1) {
                    Add-MockRemoteDevelopHead `
                        -Remote $global:QuickAdoptionRemotePath
                    'develop'
                }
                else { $liveDefaultBranch }
            }
            'TagBeforeRepositoryMutation' {
                $injectTag = if ($global:QuickAdoptionRepositoryWasCreated) {
                    $global:QuickAdoptionRepoViewCalls -ge 1
                }
                else {
                    $global:QuickAdoptionRepoViewCalls -ge 2
                }
                if ($injectTag) {
                    Add-MockRemoteTagRef -Remote $global:QuickAdoptionRemotePath
                }
                $liveDefaultBranch
            }
            'TagAfterMainPublished' {
                if ($liveDefaultBranch -ceq 'main') {
                    Add-MockRemoteTagRef -Remote $global:QuickAdoptionRemotePath
                }
                $liveDefaultBranch
            }
            'DelayedDefaultTagDuringRetry' {
                if ($liveDefaultBranch -ceq 'main') {
                    $global:QuickAdoptionDelayedDefaultViews++
                    if ($global:QuickAdoptionDelayedDefaultViews -eq 1) {
                        ''
                    }
                    else {
                        Add-MockRemoteTagRef `
                            -Remote $global:QuickAdoptionRemotePath
                        $liveDefaultBranch
                    }
                }
                else { $liveDefaultBranch }
            }
            'WrongAfterReady' {
                if ($global:QuickAdoptionPrReadyCalls -gt 0) { 'develop' }
                else { $liveDefaultBranch }
            }
            default {
                throw "Unknown mock repository-view mode '$($global:QuickAdoptionRepoViewMode)'."
            }
        }
        return (@{
            nameWithOwner = $global:QuickAdoptionRepoName
            defaultBranchRef = if ($reportedDefaultBranch) {
                @{ name = $reportedDefaultBranch }
            }
            else {
                $null
            }
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'repo' -and $Arguments[1] -eq 'create') {
        & git init --bare $global:QuickAdoptionNewRemote 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to create the fake bare GitHub remote.'
        }
        Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'config', "url.$($global:QuickAdoptionNewRemote.Replace('\\', '/')).insteadOf",
            "https://github.com/$($global:QuickAdoptionRepoName).git"
        ) | Out-Null
        Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'remote', 'add', 'origin', "https://github.com/$($global:QuickAdoptionRepoName).git"
        ) | Out-Null
        $global:QuickAdoptionRepositoryExists = $true
        $global:QuickAdoptionRepositoryWasCreated = $true
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'secret' -and $Arguments[1] -eq 'list') {
        $items = @($global:QuickAdoptionExistingSecrets | ForEach-Object {
            [ordered]@{ name = $_ }
        })
        return (ConvertTo-Json -InputObject $items -Compress)
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'secret' -and $Arguments[1] -eq 'set') {
        $expectedValue = switch -CaseSensitive ($Arguments[2]) {
            'MEANDAI_UPDATER_TOKEN' { $global:QuickAdoptionExpectedUpdaterToken }
            'MEANDAI_PROTOCOL_TOKEN' { $global:QuickAdoptionExpectedProtocolToken }
            default { throw "TEST-0073 unexpected repository secret mapping '$($Arguments[2])'." }
        }
        if ($Arguments.Count -ne 5 -or $Arguments[3] -cne '--repo' -or
            $Arguments[4] -cne $global:QuickAdoptionRepoName -or
            $stdin -cne $expectedValue) {
            throw "TEST-0073 repository secret '$($Arguments[2])' did not receive its exact stdin-only mapped value."
        }
        $global:QuickAdoptionSecrets.Add([pscustomobject]@{
            Name = $Arguments[2]
            InputValidated = $true
            Arguments = @($Arguments)
        })
        if ($global:QuickAdoptionExistingSecrets -notcontains $Arguments[2]) {
            $global:QuickAdoptionExistingSecrets.Add($Arguments[2])
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'label' -and $Arguments[1] -eq 'list') {
        return (@($global:QuickAdoptionLabels | ForEach-Object {
            [ordered]@{ name = $_ }
        }) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'label' -and $Arguments[1] -eq 'create') {
        $descriptionIndex = [Array]::IndexOf([object[]]$Arguments, '--description')
        $description = if ($descriptionIndex -ge 0 -and
            $descriptionIndex + 1 -lt $Arguments.Count) {
            [string]$Arguments[$descriptionIndex + 1]
        }
        else { '' }
        if ([string]$Arguments[2] -ceq 'meandai:secret-reconciliation-lock') {
            if ($global:QuickAdoptionLabelRecords.ContainsKey([string]$Arguments[2])) {
                $global:LASTEXITCODE = 1
                'label already exists'
                return
            }
            $global:QuickAdoptionLabelRecords.Add([string]$Arguments[2], [pscustomobject]@{
                name = [string]$Arguments[2]
                description = $description
            })
            return
        }
        if ($global:QuickAdoptionLabels -notcontains $Arguments[2]) {
            $global:QuickAdoptionLabels.Add($Arguments[2])
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'issue' -and $Arguments[1] -eq 'list') {
        if ($global:QuickAdoptionIssues.Count -eq 0) {
            return '[]'
        }
        return (ConvertTo-Json -InputObject @($global:QuickAdoptionIssues) -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'issue' -and $Arguments[1] -eq 'create') {
        $bodyIndex = [Array]::IndexOf([object[]]$Arguments, '--body-file')
        if ($bodyIndex -lt 0 -or $bodyIndex + 1 -ge $Arguments.Count) {
            throw 'Mock adoption issue was not created through a body file.'
        }
        $createdIssue = [pscustomobject]@{
            number = 84
            url = "https://github.com/$($global:QuickAdoptionRepoName)/issues/84"
            title = 'Track meAndAI AI capabilities adoption from v0.12.7'
            body = [IO.File]::ReadAllText($Arguments[$bodyIndex + 1])
            state = 'OPEN'
        }
        $global:QuickAdoptionIssues.Add($createdIssue)
        $global:QuickAdoptionIssue = $createdIssue
        if ($global:QuickAdoptionIssueRace) {
            $global:QuickAdoptionIssues.Add([pscustomobject]@{
                number = 83
                url = "https://github.com/$($global:QuickAdoptionRepoName)/issues/83"
                title = 'Track meAndAI AI capabilities adoption from v0.12.7'
                body = $createdIssue.body
                state = 'OPEN'
            })
            $global:QuickAdoptionIssues.Add([pscustomobject]@{
                number = 82
                url = "https://github.com/$($global:QuickAdoptionRepoName)/issues/82"
                title = 'Similar maintainer issue'
                body = "> $(([string]$createdIssue.body -split '\r?\n', 2)[0])`nQuoted ownership marker; this is not the canonical record."
                state = 'OPEN'
            })
        }
        for ($index = 0; $index -lt $Arguments.Count - 1; $index++) {
            if ($Arguments[$index] -ceq '--label') {
                $label = [string]$Arguments[$index + 1]
                if ($global:QuickAdoptionIssueLabels -notcontains $label) {
                    $global:QuickAdoptionIssueLabels.Add($label)
                }
                if ($label -ceq 'status:needs-review') {
                    $global:QuickAdoptionEvents.Add('issue-label:add:status:needs-review')
                }
            }
        }
        return $createdIssue.url
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'issue' -and
        $Arguments[1] -in @('edit', 'reopen', 'close')) {
        $issue = @($global:QuickAdoptionIssues | Where-Object {
            [string]$_.number -ceq [string]$Arguments[2]
        })
        if ($issue.Count -ne 1) {
            throw 'Mock adoption issue identity mismatch.'
        }
        $issue = $issue[0]
        if ($Arguments[1] -ceq 'close') {
            $issue.state = 'CLOSED'
            $global:QuickAdoptionEvents.Add("issue-close:$($issue.number)")
            return
        }
        $issue.state = 'OPEN'
        $global:QuickAdoptionIssue = $issue
        if ($Arguments[1] -ceq 'edit') {
            $addsReviewLabel = $false
            for ($index = 0; $index -lt $Arguments.Count - 1; $index++) {
                if ([string]$Arguments[$index] -ceq '--add-label' -and
                    [string]$Arguments[$index + 1] -ceq 'status:needs-review') {
                    $addsReviewLabel = $true
                    break
                }
            }
            if ($global:QuickAdoptionIssueEditMode -ceq 'FailNeedsReviewOnce' -and
                $addsReviewLabel -and
                $global:QuickAdoptionIssueEditFailures -eq 0) {
                $global:QuickAdoptionIssueEditFailures++
                $global:QuickAdoptionEvents.Add('issue-edit-failed:status:needs-review')
                $global:LASTEXITCODE = 1
                'Mock interruption after pull-request readiness and before issue reconciliation.'
                return
            }
            for ($index = 0; $index -lt $Arguments.Count - 1; $index++) {
                $operation = [string]$Arguments[$index]
                $label = [string]$Arguments[$index + 1]
                if ($operation -ceq '--add-label') {
                    if ($global:QuickAdoptionIssueLabels -notcontains $label) {
                        $global:QuickAdoptionIssueLabels.Add($label)
                    }
                    if ($label -ceq 'status:needs-review') {
                        $global:QuickAdoptionEvents.Add('issue-label:add:status:needs-review')
                    }
                }
                elseif ($operation -ceq '--remove-label') {
                    [void]$global:QuickAdoptionIssueLabels.Remove($label)
                }
            }
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'workflow' -and $Arguments[1] -eq 'run') {
        $workflowName = if ($Arguments.Count -ge 3) { [string]$Arguments[2] } else { '' }
        $dispatchRepository = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--repo'
        $dispatchRef = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--ref'
        $dispatchFields = [ordered]@{}
        for ($index = 0; $index -lt $Arguments.Count; $index++) {
            if ([string]$Arguments[$index] -cne '--field' -or
                $index + 1 -ge $Arguments.Count) {
                continue
            }
            $fieldMatch = [regex]::Match(
                [string]$Arguments[$index + 1],
                '^(?<name>[a-z_]+)=(?<value>.*)$'
            )
            if (-not $fieldMatch.Success -or
                $dispatchFields.Contains($fieldMatch.Groups['name'].Value)) {
                throw 'Mock workflow dispatch contains an invalid or duplicate field.'
            }
            $dispatchFields[$fieldMatch.Groups['name'].Value] =
                $fieldMatch.Groups['value'].Value
        }
        $correlationMatch = [regex]::Match(
            [string]$dispatchFields['correlation_id'],
            '^(?<id>[0-9a-f]{32})$'
        )
        $independentHead = Get-MockPublishedDefaultHead
        $sourceGraphIdentity = $null
        $sourceGraphRecord = $null
        $workflowSupportsSourceGraphIdentity =
            $global:QuickAdoptionWorkflowSupportsSourceGraphIdentity -is [bool] -and
            [bool]$global:QuickAdoptionWorkflowSupportsSourceGraphIdentity
        $sourceGraphIdentityExpected = if (
            $global:QuickAdoptionExpectSourceGraphIdentity -is [bool]
        ) {
            [bool]$global:QuickAdoptionExpectSourceGraphIdentity
        }
        else { $workflowSupportsSourceGraphIdentity }
        $sourceGraphIdentityValid = -not $sourceGraphIdentityExpected
        if ($sourceGraphIdentityExpected) {
            try {
                $sourceGraphIdentity =
                    [string]$dispatchFields['source_graph_identity'] |
                    ConvertFrom-Json
                $graphBuilder = Get-TestQuickAdoptionContractCommand `
                    -Name 'New-MeAndAIInstructionGraph'
                $graphValidator = Get-TestQuickAdoptionContractCommand `
                    -Name 'Test-MeAndAIExactInstructionGraph'
                $identityValidator = Get-TestQuickAdoptionContractCommand `
                    -Name 'Test-MeAndAIExactInstructionGraphIdentity'
                $independentGraph = Get-TestCommittedInstructionGraph `
                    -Repository $global:QuickAdoptionTargetPath `
                    -Commit ([string]$sourceGraphIdentity.graphBase) `
                    -Builder $graphBuilder -Validator $graphValidator
                $sourceGraphIdentityValid = & $identityValidator `
                    -Identity $sourceGraphIdentity -Graph $independentGraph
                $graphRecordConverter =
                    Get-TestQuickAdoptionContractCommand `
                        -Name 'ConvertTo-MeAndAIInstructionGraphRecord'
                $sourceGraphRecord = & $graphRecordConverter `
                    -Graph $independentGraph
            }
            catch {
                $sourceGraphIdentityValid = $false
            }
        }
        $expectedDispatchFieldCount = if (
            $sourceGraphIdentityExpected
        ) { 5 } else { 4 }
        if ($workflowName -cne 'meandai-protocol-update.yml' -or
            $dispatchRepository -cne $global:QuickAdoptionRepoName -or
            $dispatchRef -cne $global:QuickAdoptionDefaultBranch -or
            $dispatchFields.Count -ne $expectedDispatchFieldCount -or
            -not $correlationMatch.Success -or
            -not $sourceGraphIdentityValid -or
            [string]$dispatchFields['adoption_strategy'] -cnotin @(
                'Auto', 'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart'
            ) -or [string]$dispatchFields['acknowledge_protocol_record_loss'] -cnotin @(
                'true', 'false'
            ) -or [string]$dispatchFields['expected_base_sha'] -cnotmatch
                '^[0-9a-f]{40}$' -or
            [string]$dispatchFields['expected_base_sha'] -cne $independentHead) {
            throw 'Mock workflow dispatch identity is not exact.'
        }
        $global:QuickAdoptionCorrelationId =
            [string]$correlationMatch.Groups['id'].Value
        $global:QuickAdoptionDispatchedStrategy =
            [string]$dispatchFields['adoption_strategy']
        $global:QuickAdoptionDispatchedLossAcknowledgement =
            [string]$dispatchFields['acknowledge_protocol_record_loss'] -ceq 'true'
        $global:QuickAdoptionDispatchedBaseSha =
            [string]$dispatchFields['expected_base_sha']
        $global:QuickAdoptionDispatchedSourceGraphIdentity =
            $sourceGraphIdentity
        $global:QuickAdoptionDispatchedSourceGraphRecord =
            $sourceGraphRecord
        if ($global:QuickAdoptionExpectedPublishedHead -and
            $global:QuickAdoptionExpectedPublishedHead -cne $independentHead) {
            throw 'Mock published head changed between inventory and dispatch.'
        }
        $global:QuickAdoptionExpectedPublishedHead = $independentHead
        $global:QuickAdoptionDispatchRecord = [pscustomobject]@{
            Workflow = $workflowName
            Repository = $dispatchRepository
            Ref = $dispatchRef
            CorrelationId = $global:QuickAdoptionCorrelationId
            AdoptionStrategy = $global:QuickAdoptionDispatchedStrategy
            ProtocolRecordLossAcknowledged =
                [bool]$global:QuickAdoptionDispatchedLossAcknowledgement
            ExpectedBaseSha = $global:QuickAdoptionDispatchedBaseSha
            SourceGraphIdentity =
                $global:QuickAdoptionDispatchedSourceGraphIdentity
            WorkflowSupportsSourceGraphIdentity =
                [bool]$workflowSupportsSourceGraphIdentity
            Head = $independentHead
        }
        $global:QuickAdoptionWorkflowDispatched = $true
        if ($global:QuickAdoptionPublishAdoptionProposal) {
            Publish-MockAdoptionBranch
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'workflow' -and $Arguments[1] -eq 'view') {
        if ($Arguments.Count -lt 8 -or
            [string]$Arguments[2] -cne 'meandai-protocol-update.yml' -or
            (Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) -Name '--repo') -cne
                $global:QuickAdoptionRepoName -or
            (Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) -Name '--ref') -cne
                $global:QuickAdoptionDefaultBranch -or
            $Arguments -cnotcontains '--yaml') {
            throw 'Mock workflow discovery identity is not exact.'
        }
        return 'name: meAndAI AI Capabilities Lifecycle'
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'run' -and $Arguments[1] -eq 'list') {
        $global:QuickAdoptionRunListCalls++
        if ($global:QuickAdoptionRunListCalls -gt 2) {
            if ($global:QuickAdoptionRunMode -ceq 'Zero') {
                throw 'Mock zero-run wait budget exhausted after repeated polling.'
            }
            throw 'Mock completed workflow was polled more than twice.'
        }
        $listedRepository = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--repo'
        $listedWorkflow = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--workflow'
        $listedEvent = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--event'
        $listedBranch = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--branch'
        $listedCommit = Get-MockGhArgumentValue -Arguments ([object[]]$Arguments) `
            -Name '--commit'
        $independentHead = Get-MockPublishedDefaultHead
        if (-not $global:QuickAdoptionExpectedPublishedHead) {
            $global:QuickAdoptionExpectedPublishedHead = $independentHead
        }
        if ($listedRepository -cne $global:QuickAdoptionRepoName -or
            $listedWorkflow -cne 'meandai-protocol-update.yml' -or
            $listedEvent -cne 'workflow_dispatch' -or
            $listedBranch -cne $global:QuickAdoptionDefaultBranch -or
            $listedCommit -cne $global:QuickAdoptionExpectedPublishedHead -or
            $independentHead -cne $global:QuickAdoptionExpectedPublishedHead) {
            throw 'Mock workflow-run inventory identity is not exact.'
        }
        $head = $global:QuickAdoptionExpectedPublishedHead
        $runs = [System.Collections.Generic.List[object]]::new()
        $runs.Add([ordered]@{
            databaseId = 6999
            createdAt = [DateTimeOffset]::UtcNow.AddMinutes(-10).ToString('o')
            displayTitle = 'meAndAI AI capabilities lifecycle [historical]'
            headSha = $head
            status = 'completed'
            conclusion = 'success'
            url = 'https://github.com/test-owner/consumer/actions/runs/6999'
        })
        if ($global:QuickAdoptionWorkflowDispatched -and
            $global:QuickAdoptionRunMode -cne 'Zero') {
            $expectedTitle = "meAndAI AI capabilities lifecycle [$($global:QuickAdoptionCorrelationId)]"
            $runs.Add([ordered]@{
                databaseId = 7000
                createdAt = [DateTimeOffset]::UtcNow.ToString('o')
                displayTitle = 'meAndAI AI capabilities lifecycle [concurrent-session]'
                headSha = $head
                status = 'completed'
                conclusion = 'success'
                url = 'https://github.com/test-owner/consumer/actions/runs/7000'
            })
            $runs.Add([ordered]@{
                databaseId = 7001
                createdAt = [DateTimeOffset]::UtcNow.ToString('o')
                displayTitle = $expectedTitle
                headSha = $head
                status = 'completed'
                conclusion = 'success'
                url = 'https://github.com/test-owner/consumer/actions/runs/7001'
            })
            if ($global:QuickAdoptionRunMode -ceq 'Ambiguous') {
                $runs.Add([ordered]@{
                    databaseId = 7002
                    createdAt = [DateTimeOffset]::UtcNow.AddSeconds(1).ToString('o')
                    displayTitle = $expectedTitle
                    headSha = $head
                    status = 'completed'
                    conclusion = 'success'
                    url = 'https://github.com/test-owner/consumer/actions/runs/7002'
                })
            }
        }
        return (@($runs) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'run' -and $Arguments[1] -eq 'view') {
        if ([string]$Arguments[2] -cne '7001' -or
            $null -eq $global:QuickAdoptionDispatchRecord) {
            throw "Mock launcher followed unexpected workflow run '$($Arguments[2])'."
        }
        return ([ordered]@{
            databaseId = 7001
            displayTitle = "meAndAI AI capabilities lifecycle [$($global:QuickAdoptionDispatchRecord.CorrelationId)]"
            headSha = $global:QuickAdoptionDispatchRecord.Head
            status = 'completed'
            conclusion = 'success'
            url = 'https://github.com/test-owner/consumer/actions/runs/7001'
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'list') {
        $jsonIndex = [Array]::IndexOf([object[]]$Arguments, '--json')
        if ($jsonIndex -lt 0 -or $jsonIndex + 1 -ge $Arguments.Count) {
            throw 'TEST-0102 pull-request lookup omitted its JSON field contract.'
        }
        $requestedPrFields = @([string]$Arguments[$jsonIndex + 1] -split ',')
        foreach ($requiredPrField in @(
            'headRepository', 'headRepositoryOwner', 'isCrossRepository'
        )) {
            if ($requestedPrFields -cnotcontains $requiredPrField) {
                throw "TEST-0102 pull-request lookup omitted live GitHub field '$requiredPrField'."
            }
        }
        Publish-MockAdoptionBranch
        if ([string]$global:QuickAdoptionPrHead -notmatch '^[0-9a-f]{40}$') {
            throw "Mock adoption head is invalid: '$($global:QuickAdoptionPrHead)'"
        }
        $global:QuickAdoptionPrListCalls++
        if ($global:QuickAdoptionPrListCalls -gt 12) {
            throw 'Mock deterministic pull request was queried unexpectedly often.'
        }
        if ($global:QuickAdoptionPrMetadataMode -ceq
                'AdvanceBaseAtConfiguredRevalidation' -and
            $global:QuickAdoptionPrListCalls -eq
                $global:QuickAdoptionBaseAdvanceAtPrListCall) {
            Advance-MockPublishedDefaultBranch
        }
        $proposalState = if ($global:QuickAdoptionProposalMode -ceq 'ManifestOnly') {
            'AdoptionReviewRequired'
        }
        else {
            'BootstrapReady'
        }
        Initialize-MockAdoptionPullRequestBody
        $pullRequest = [ordered]@{
            number = 42
            url = "https://github.com/$($global:QuickAdoptionRepoName)/pull/42"
            isDraft = $global:QuickAdoptionPrDraft
            state = $global:QuickAdoptionPrState
            baseRefName = $global:QuickAdoptionDefaultBranch
            headRefName = 'automation/meandai-capabilities-v0.12.7'
            headRefOid = $global:QuickAdoptionPrHead
            headRepository = [ordered]@{
                id = 'R_mock_consumer'
                name = ([string]$global:QuickAdoptionRepoName -split '/', 2)[1]
            }
            headRepositoryOwner = [ordered]@{
                id = 'U_mock_owner'
                login = $global:QuickAdoptionOwner
            }
            isCrossRepository = $false
            author = [ordered]@{ login = $global:QuickAdoptionOwner }
            body = $global:QuickAdoptionPrBody
        }
        switch ($global:QuickAdoptionPrMetadataMode) {
            'WrongBase' { $pullRequest.baseRefName = 'develop' }
            'WrongBaseAfterFirst' {
                if ($global:QuickAdoptionPrListCalls -gt 1) {
                    $pullRequest.baseRefName = 'develop'
                }
            }
            'ForeignHead' {
                $pullRequest.headRepository.name = 'foreign-consumer'
            }
            'ForeignHeadOwner' { $pullRequest.headRepositoryOwner.login = 'foreign-owner' }
            'CrossRepository' { $pullRequest.isCrossRepository = $true }
            'InvalidCrossRepositoryType' { $pullRequest.isCrossRepository = 'false' }
            'InvalidMarker' {
                $pullRequest.body = '<!-- meandai-capabilities-adoption:{"schema":1} -->'
            }
            'WrongAuthor' { $pullRequest.author = [ordered]@{ login = 'untrusted-actor' } }
            'NonDraft' { $pullRequest.isDraft = $false }
            'MarkerHeadMismatch' {
                $badMarker = [ordered]@{
                    schema = 5
                    phase = 'Proposed'
                    state = $proposalState
                    target = 'v0.12.7'
                    protocolSha = $global:QuickAdoptionProtocolSha
                    head = ('0' * 40)
                    adoptionStrategy = $global:QuickAdoptionDispatchedStrategy
                    protocolSurfaces = @($global:QuickAdoptionProposalSurfaces)
                    protocolRecordLossAcknowledged = [bool]$global:QuickAdoptionDispatchedLossAcknowledgement
                    repository = $global:QuickAdoptionRepoName
                    actor = $global:QuickAdoptionOwner
                } | ConvertTo-Json -Compress
                $pullRequest.body = "<!-- meandai-capabilities-adoption:$badMarker -->"
            }
            'MarkerStrategyMismatch' {
                $badMarker = [ordered]@{
                    schema = 5
                    phase = 'Proposed'
                    state = $proposalState
                    target = 'v0.12.7'
                    protocolSha = $global:QuickAdoptionProtocolSha
                    head = $global:QuickAdoptionPrHead
                    adoptionStrategy = 'FreshAdoption'
                    protocolSurfaces = @($global:QuickAdoptionProposalSurfaces)
                    protocolRecordLossAcknowledged = [bool]$global:QuickAdoptionDispatchedLossAcknowledgement
                    repository = $global:QuickAdoptionRepoName
                    actor = $global:QuickAdoptionOwner
                } | ConvertTo-Json -Compress
                $pullRequest.body = "<!-- meandai-capabilities-adoption:$badMarker -->"
            }
            'MarkerSurfaceMismatch' {
                $badMarker = [ordered]@{
                    schema = 5
                    phase = 'Proposed'
                    state = $proposalState
                    target = 'v0.12.7'
                    protocolSha = $global:QuickAdoptionProtocolSha
                    head = $global:QuickAdoptionPrHead
                    adoptionStrategy = $global:QuickAdoptionDispatchedStrategy
                    protocolSurfaces = @(
                        @($global:QuickAdoptionProposalSurfaces) +
                        'docs/governance/unobserved.md' | Sort-Object -CaseSensitive
                    )
                    protocolRecordLossAcknowledged = [bool]$global:QuickAdoptionDispatchedLossAcknowledgement
                    repository = $global:QuickAdoptionRepoName
                    actor = $global:QuickAdoptionOwner
                } | ConvertTo-Json -Compress
                $pullRequest.body = "<!-- meandai-capabilities-adoption:$badMarker -->"
            }
            'AdvanceBaseAtConfiguredRevalidation' { }
            'Valid' { }
            default { throw "Unknown mock pull-request metadata mode '$($global:QuickAdoptionPrMetadataMode)'." }
        }
        return (@($pullRequest) | ConvertTo-Json -Depth 5 -Compress)
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'edit') {
        if ([string]$Arguments[2] -cne '42') {
            throw 'Mock pull-request edit identity mismatch.'
        }
        $bodyIndex = [Array]::IndexOf([object[]]$Arguments, '--body-file')
        if ($bodyIndex -lt 0 -or $bodyIndex + 1 -ge $Arguments.Count) {
            throw 'Mock pull-request edit did not use a body file.'
        }
        $editedBody = [IO.File]::ReadAllText($Arguments[$bodyIndex + 1])
        if ($global:QuickAdoptionPrBodyEditMode -ceq 'FailCompletedOnce' -and
            $editedBody.Contains('"phase":"Completed"') -and
            $global:QuickAdoptionCompletedEditFailures -eq 0) {
            $global:QuickAdoptionCompletedEditFailures++
            $global:QuickAdoptionEvents.Add('pr-body-edit-failed:completed')
            throw 'Mock interruption after completion push and before completed-marker persistence.'
        }
        $global:QuickAdoptionPrBody = $editedBody
        $global:QuickAdoptionPrBodyEditCalls++
        $global:QuickAdoptionEvents.Add('pr-body-edit')
        if ($editedBody.Contains('"phase":"Publishing"')) {
            $global:QuickAdoptionEvents.Add('pr-body-edit:publishing')
        }
        elseif ($editedBody.Contains('"phase":"Completed"')) {
            $global:QuickAdoptionEvents.Add('pr-body-edit:completed')
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'ready') {
        if ($Arguments -ccontains '--undo') {
            $global:QuickAdoptionEvents.Add('pr-ready-undo')
            $global:QuickAdoptionPrReadyUndoCalls++
            $global:QuickAdoptionPrDraft = $true
        }
        else {
            $global:QuickAdoptionEvents.Add('pr-ready')
            $global:QuickAdoptionPrReadyCalls++
            $global:QuickAdoptionPrDraft = $false
        }
        return
    }

    throw "Unexpected gh call: $joined"
}

try {
    foreach ($fixtureContractFunction in @(
        'Initialize-QuickAdoptionImmutableFixture',
        'Assert-QuickAdoptionImmutableFixture',
        'Copy-QuickAdoptionReleaseArchive'
    )) {
        if (-not (Get-Command -Name $fixtureContractFunction `
                -CommandType Function -ErrorAction SilentlyContinue)) {
            Add-Failure "TEST-0116 immutable fixture contract is missing function '$fixtureContractFunction'."
        }
    }

    if (Test-QuickAdoptionShard -Name 'ContractsPreflight') {
        Reset-Mocks
        $firstFixtureRepository = $global:QuickAdoptionProtocolRepository
        $firstFixtureArchive = $script:QuickAdoptionProtocolFixture.ArchivePath
        $firstMutableCalls = $global:QuickAdoptionGhCalls
        $firstCodexLog = $global:QuickAdoptionCodexLog
        $archiveProbeRoot = New-TempRoot -Name 'immutable-archive-probe'
        $firstArchiveCopy = Join-Path $archiveProbeRoot 'first.zip'
        $secondArchiveCopy = Join-Path $archiveProbeRoot 'second.zip'
        $transportArchiveCopy = Join-Path $archiveProbeRoot 'transport.zip'
        Copy-QuickAdoptionReleaseArchive -OutFile $firstArchiveCopy
        $firstArchiveSha = (Get-FileHash -LiteralPath $firstArchiveCopy `
            -Algorithm SHA256).Hash.ToLowerInvariant()
        [IO.File]::AppendAllText(
            $firstArchiveCopy,
            'caller mutation',
            [Text.UTF8Encoding]::new($false)
        )

        Reset-Mocks
        Copy-QuickAdoptionReleaseArchive -OutFile $secondArchiveCopy
        $secondArchiveSha = (Get-FileHash -LiteralPath $secondArchiveCopy `
            -Algorithm SHA256).Hash.ToLowerInvariant()
        $mutatedFirstArchiveSha = (Get-FileHash -LiteralPath $firstArchiveCopy `
            -Algorithm SHA256).Hash.ToLowerInvariant()
        $archiveExtractPath = Join-Path $archiveProbeRoot 'extracted'
        Expand-Archive -LiteralPath $secondArchiveCopy `
            -DestinationPath $archiveExtractPath -Force
        $archiveContractPath = Join-Path $archiveExtractPath `
            'openai-mock-protocol/templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
        Invoke-WebRequest -UseBasicParsing `
            -Uri "https://api.github.com/repos/hasanmanzak/meAndAI/zipball/$($global:QuickAdoptionProtocolSha)" `
            -Headers @{
                Accept = 'application/vnd.github+json'
                Authorization = "Bearer $($global:QuickAdoptionExpectedProtocolToken)"
                'X-GitHub-Api-Version' = '2026-03-10'
                'User-Agent' = 'meAndAI-quick-adoption'
            } `
            -OutFile $transportArchiveCopy
        $transportArchiveSha = (Get-FileHash -LiteralPath $transportArchiveCopy `
            -Algorithm SHA256).Hash.ToLowerInvariant()
        $transportExtractPath = Join-Path $archiveProbeRoot 'transport-extracted'
        Expand-Archive -LiteralPath $transportArchiveCopy `
            -DestinationPath $transportExtractPath -Force
        if ($global:QuickAdoptionProtocolRepository -cne $firstFixtureRepository -or
            $script:QuickAdoptionProtocolFixture.ArchivePath -cne $firstFixtureArchive -or
            [object]::ReferenceEquals($firstMutableCalls, $global:QuickAdoptionGhCalls) -or
            $global:QuickAdoptionCodexLog -ceq $firstCodexLog -or
            $firstArchiveSha -cne $script:QuickAdoptionProtocolFixture.ArchiveSha256 -or
            $secondArchiveSha -cne $script:QuickAdoptionProtocolFixture.ArchiveSha256 -or
            $transportArchiveSha -cne $script:QuickAdoptionProtocolFixture.ArchiveSha256 -or
            $mutatedFirstArchiveSha -ceq $secondArchiveSha -or
            -not (Test-Path -LiteralPath $archiveContractPath -PathType Leaf)) {
            Add-Failure 'TEST-0116 reset did not preserve one immutable fixture while isolating mutable state and archive outputs.'
        }

    foreach ($requiredPath in @(
        $bootstrapPath, $launcherPath, $guidePath, $workflowPath,
        $mockCodexScriptPath,
        $mockCodexWindowsPath, $mockCodexUnixPath
    ) + $launcherSourcePaths) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            Add-Failure "TEST-0033 missing required quick-adoption asset: $requiredPath"
        }
    }

    if (@($launcherSourcePaths | Where-Object {
        -not (Test-Path -LiteralPath $_ -PathType Leaf)
    }).Count -eq 0) {
        $launcher = Get-QuickAdoptionLauncherSource
        $tokens = $null
        $parseErrors = $null
        [void][Management.Automation.Language.Parser]::ParseInput(
            $launcher,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            Add-Failure "TEST-0033 launcher has PowerShell parse errors: $($parseErrors -join '; ')"
        }

        foreach ($required in @(
            'v0.12.7',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
            'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1',
            'templates/project/.github/workflows/meandai-protocol-update.yml',
            '.github/workflows/meandai-protocol-update.yml',
            'Invoke-RestMethod',
            'Get-RepositorySecretNames',
            'Enter-RepositorySecretReconciliationLock',
            'Exit-RepositorySecretReconciliationLock',
            'meandai:secret-reconciliation-lock',
            'gh secret list',
            'gh secret set',
            'already exists and was preserved',
            'info/exclude',
            '--private',
            'workflow run',
            'WorkflowTimeoutMinutes',
            'CodexTimeoutMinutes',
            'CodexTimeoutSeconds',
            'NoProgress',
            'SkipLifecycleDispatch',
            'SkipLocalCodex',
            "Alias('SkipCodexDelegation')",
            'codex exec',
            '@openai/codex@',
            '0.144.4',
            'headRefOid',
            '--ephemeral',
            '--ignore-user-config',
            '--sandbox',
            'workspace-write',
            'Get-ConfiguredWindowsSandboxMode',
            'Assert-LocalCodexWorkspaceWrite',
            'windows.sandbox=',
            "'sandbox'",
            "':workspace'",
            'sandbox_workspace_write.network_access=false',
            'Set-QuickAdoptionProgress',
            'Complete-QuickAdoptionProgress',
            'Write-QuickAdoptionLine',
            'Write-LocalCodexEvent',
            'ReadLineAsync',
            'Stop-ExternalProcessTree',
            '--json',
            'Validating prerequisites',
            'Waiting for lifecycle workflow',
            'Running local Codex',
            'Validating and publishing adoption',
            'Not yet established',
            'not a blocker to protocol adoption',
            'WaitForExit',
            'Ensure-AdoptionLabels',
            'Ensure-AdoptionIssue',
            'Set-AdoptionIssueReadyForReview',
            'Get-AdoptionPullRequestTrackingBody',
            'Tracking issue: #',
            'duplicate or conflicting tracking-issue lines',
            'native issue-closing reference',
            'Get-ValidatedAdoptionManifest',
            'Get-ValidatedAdoptionChangeSet',
            'Get-ValidatedImmutableProtocolRelease',
            'X-GitHub-Api-Version: 2026-03-10',
            'published immutable GitHub Release',
            'prior manifest removal has no launcher-owned validation evidence',
            '160000',
            '--force-with-lease'
        )) {
            if (-not $launcher.Contains($required)) {
                Add-Failure "TEST-0038 launcher execution contract is missing '$required'"
            }
        }
        if ($launcher -match '[''"]--body[''"]') {
            Add-Failure "TEST-0033 launcher contains forbidden secret body argument '--body'"
        }
        if ($launcher.Contains("'label', 'view'")) {
            Add-Failure 'TEST-0070 launcher relies on the unsupported gh label view subcommand.'
        }
        foreach ($forbidden in @(
            '@codex', 'Codex Cloud', 'gh pr merge', 'git add .',
            'sandbox_workspace_write.network_access=true',
            'danger-full-access', 'dangerously-bypass-approvals-and-sandbox'
        )) {
            if ($launcher.Contains($forbidden)) {
                Add-Failure "TEST-0033 launcher contains forbidden behavior '$forbidden'"
            }
        }
        $tokens = $null
        $parseErrors = $null
        $launcherAst = [System.Management.Automation.Language.Parser]::ParseInput(
            $launcher, [ref]$tokens, [ref]$parseErrors
        )
        $policyImportFunctions = @($launcherAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Import-CanonicalInitialAdoptionPolicy'
        }, $true))
        $policyResolverFunctions = @($launcherAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Resolve-QuickAdoptionStrategy'
        }, $true))
        if ($policyImportFunctions.Count -ne 1 -or
            $policyResolverFunctions.Count -ne 1) {
            Add-Failure 'TEST-0130 launcher lacks one canonical initial-policy import and one adapter resolver.'
        }
        else {
            $policyImportText = $policyImportFunctions[0].Extent.Text
            $policyResolverText = $policyResolverFunctions[0].Extent.Text
            if (-not $policyImportText.Contains('Get-CanonicalProtocolAsset') -or
                -not $policyImportText.Contains('$initialAdoptionPolicyTag') -or
                -not $policyImportText.Contains('$initialAdoptionPolicySourcePath') -or
                -not $policyImportText.Contains('New-Module') -or
                -not $policyImportText.Contains(
                    "[guid]::NewGuid().ToString('N')"
                ) -or
                -not $policyImportText.Contains(
                    'Import-Module -ModuleInfo $dynamicModule'
                ) -or
                -not $policyImportText.Contains('Get-MeAndAIProtocolAssessmentLimits')) {
                Add-Failure 'TEST-0130 initial policy is not imported from the verified canonical release asset with its bounded contract.'
            }
            if (-not $policyResolverText.Contains(
                    "-Name 'Resolve-MeAndAIAdoptionStrategy'"
                ) -or
                [regex]::Matches(
                    $policyResolverText,
                    'Resolve-MeAndAIAdoptionStrategy'
                ).Count -ne 1) {
                Add-Failure 'TEST-0130 launcher strategy adapter does not delegate exactly once to the canonical policy resolver.'
            }
        }
        foreach ($policyAdapter in @(
            [pscustomobject]@{
                Function = 'Assert-QuickAdoptionCanonicalPathCasing'
                Command = 'Assert-MeAndAIProtocolAssessmentPathCasing'
            },
            [pscustomobject]@{
                Function = 'Get-QuickAdoptionProtocolSurfaceInventory'
                Command = 'Get-MeAndAIProtocolSurfaceInventory'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionAssessmentRelevantPath'
                Command = 'Test-MeAndAIProtocolAssessmentRelevantPath'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionConsumerGovernancePath'
                Command = 'Test-MeAndAIConsumerGovernancePath'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionLegacyGovernancePath'
                Command = 'Test-MeAndAILegacyGovernancePath'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionLegacyCommonAuthorityPath'
                Command = 'Test-MeAndAILegacyCommonAuthorityPath'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionExactPullRequestMarker'
                Command = 'Test-MeAndAIExactAdoptionPullRequestMarker'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionCompletedChangeSet'
                Command = 'Test-MeAndAICompletedAdoptionChangeSet'
            },
            [pscustomobject]@{
                Function = 'Test-QuickAdoptionReservedSubmoduleContract'
                Command = 'Test-MeAndAIReservedProtocolSubmoduleContract'
            }
        )) {
            $adapterFunctions = @($launcherAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -ceq [string]$policyAdapter.Function
            }, $true))
            $adapterText = if ($adapterFunctions.Count -eq 1) {
                $adapterFunctions[0].Extent.Text
            }
            else { '' }
            if ($adapterFunctions.Count -ne 1 -or
                -not $adapterText.Contains('Get-InitialAdoptionPolicyCommand') -or
                -not $adapterText.Contains(
                    "-Name '$([string]$policyAdapter.Command)'"
                ) -or
                $adapterText -match '(?m)^\s*(?:foreach|switch)\b') {
                Add-Failure "TEST-0130 launcher policy adapter '$([string]$policyAdapter.Function)' is not a thin canonical-module delegation."
            }
        }
        foreach ($forbiddenLocalPolicy in @(
            '$canonicalProtocolSurfaceFiles',
            '$canonicalProtocolSurfaceRoots',
            'function Test-QuickAdoptionProtocolSurfacePath',
            'function Test-QuickAdoptionCleanStartSurfaceSupported'
        )) {
            if ($launcher.Contains($forbiddenLocalPolicy)) {
                Add-Failure "TEST-0130 launcher duplicates canonical classifier policy through '$forbiddenLocalPolicy'."
            }
        }
        foreach ($contractConsumer in @(
            [pscustomobject]@{
                Function = 'Get-ValidatedAdoptionMarker'
                Adapter = 'Test-QuickAdoptionExactPullRequestMarker'
            },
            [pscustomobject]@{
                Function = 'Assert-AdoptionCompletionEnvelope'
                Adapter = 'Test-QuickAdoptionCompletedChangeSet'
            },
            [pscustomobject]@{
                Function = 'Assert-AdoptionReservedProtocolSubmoduleAvailable'
                Adapter = 'Test-QuickAdoptionReservedSubmoduleContract'
            }
        )) {
            $consumerFunctions = @($launcherAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -ceq [string]$contractConsumer.Function
            }, $true))
            $consumerText = if ($consumerFunctions.Count -eq 1) {
                $consumerFunctions[0].Extent.Text
            }
            else { '' }
            if ($consumerFunctions.Count -ne 1 -or
                [regex]::Matches(
                    $consumerText,
                    [regex]::Escape([string]$contractConsumer.Adapter)
                ).Count -ne 1) {
                Add-Failure "TEST-0130 launcher contract consumer '$([string]$contractConsumer.Function)' does not delegate exactly once through '$([string]$contractConsumer.Adapter)'."
            }
        }
        $markerOwnershipFunctions = @($launcherAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Get-ValidatedAdoptionMarker'
        }, $true))
        if ($markerOwnershipFunctions.Count -ne 1) {
            Add-Failure 'TEST-0145 launcher must expose one parseable adoption-marker ownership boundary.'
        }
        else {
            $markerCultureModule = $null
            try {
                $markerCultureModule = New-Module `
                    -Name "MeAndAIMarkerCulture$([guid]::NewGuid().ToString('N'))" `
                    -ArgumentList @(
                        $markerOwnershipFunctions[0].Extent.Text
                    ) `
                    -ScriptBlock {
                        param([string]$FunctionDefinition)
                        $script:ProtocolTag = 'v0.12.7'

                        function Test-QuickAdoptionExactPullRequestMarker {
                            return $true
                        }

                        Invoke-Expression $FunctionDefinition
                    }
                $markerFixture =
                    New-TestQuickAdoptionPullRequestContractFixture `
                        -Mode 'Valid'
                $markerPullRequest = $markerFixture.PullRequest
                $markerPullRequest.headRepository = [pscustomobject]@{
                    name = 'consumer'
                }
                $markerPullRequest | Add-Member `
                    -NotePropertyName headRepositoryOwner `
                    -NotePropertyValue ([pscustomobject]@{
                        login = 'test-owner'
                    }) -Force
                $markerPullRequest | Add-Member `
                    -NotePropertyName isCrossRepository `
                    -NotePropertyValue $false -Force
                $canonicalMarkerBody = [string]$markerPullRequest.body
                $markerBodies = @(
                    [pscustomobject]@{
                        Name = 'Canonical'
                        Body = $canonicalMarkerBody
                        ExpectedValid = $true
                    },
                    [pscustomobject]@{
                        Name = 'UppercaseNearMarkerDuplicate'
                        Body = $canonicalMarkerBody + "`n" +
                            '<!-- MEANDAI-CAPABILITIES-ADOPTION:not-json -->'
                        ExpectedValid = $false
                    }
                )
                $originalCulture =
                    [Threading.Thread]::CurrentThread.CurrentCulture
                $originalUICulture =
                    [Threading.Thread]::CurrentThread.CurrentUICulture
                try {
                    foreach ($cultureName in @('en-US', 'tr-TR')) {
                        $culture = [Globalization.CultureInfo]::GetCultureInfo(
                            $cultureName
                        )
                        [Threading.Thread]::CurrentThread.CurrentCulture =
                            $culture
                        [Threading.Thread]::CurrentThread.CurrentUICulture =
                            $culture
                        foreach ($markerBody in $markerBodies) {
                            $markerPullRequest.body = [string]$markerBody.Body
                            $markerValid = $true
                            try {
                                & $markerCultureModule {
                                    param($PullRequest)
                                    Get-ValidatedAdoptionMarker `
                                        -PullRequest $PullRequest `
                                        -Repository 'test-owner/consumer' `
                                        -Branch 'automation/meandai-capabilities-v0.12.7' `
                                        -BaseBranch 'main' `
                                        -ExpectedActor 'test-owner' `
                                        -ExpectedMarkerHead ('c' * 40) `
                                        -ExpectedAdoptionStrategy 'FullMigration' `
                                        -ExpectedProtocolSurfaces @('AGENTS.md') `
                                        -ExpectedProtocolRecordLossAcknowledgement $false | Out-Null
                                } $markerPullRequest
                            }
                            catch {
                                $markerValid = $false
                            }
                            if ($markerValid -ne
                                [bool]$markerBody.ExpectedValid) {
                                Add-Failure "TEST-0145 adoption marker '$([string]$markerBody.Name)' produced a culture-dependent or unsafe result under '$cultureName'."
                            }
                        }
                    }
                }
                finally {
                    [Threading.Thread]::CurrentThread.CurrentCulture =
                        $originalCulture
                    [Threading.Thread]::CurrentThread.CurrentUICulture =
                        $originalUICulture
                    $markerPullRequest.body = $canonicalMarkerBody
                }
            }
            catch {
                Add-Failure "TEST-0145 adoption-marker culture fixture failed: $($_.Exception.Message)"
            }
            finally {
                if ($null -ne $markerCultureModule) {
                    Remove-Module -ModuleInfo $markerCultureModule -Force `
                        -ErrorAction SilentlyContinue
                }
            }
        }
        foreach ($canonicalPolicyFunctionName in @(
            'Get-MeAndAIProtocolSurfaceInventory',
            'Resolve-MeAndAIAdoptionStrategy',
            'Test-MeAndAIConsumerGovernancePath',
            'Test-MeAndAILegacyCommonAuthorityPath',
            'Test-MeAndAILegacyGovernancePath',
            'Test-MeAndAIProtocolAssessmentRelevantPath'
        )) {
            $localCanonicalDefinitions = @($launcherAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -ceq $canonicalPolicyFunctionName
            }, $true))
            if ($localCanonicalDefinitions.Count -ne 0) {
                Add-Failure "TEST-0130 launcher locally redefines canonical policy validator '$canonicalPolicyFunctionName'."
            }
        }
        $policyImportCleanupText = if ($policyImportFunctions.Count -eq 1) {
            $policyImportFunctions[0].Extent.Text
        }
        else { '' }
        if (-not $launcher.Contains(
                'Remove-Module -ModuleInfo $script:InitialAdoptionPolicy.Module'
            ) -or
            -not $policyImportCleanupText.Contains(
                'Remove-Module -ModuleInfo $module'
            )) {
            Add-Failure 'TEST-0130 dynamic initial-policy modules do not have exact ModuleInfo cleanup on success and import failure.'
        }
        $mainExecutionMarker =
            "Set-QuickAdoptionProgress -Status 'Validating prerequisites'"
        $mainExecutionIndex = $launcher.LastIndexOf(
            $mainExecutionMarker, [StringComparison]::Ordinal
        )
        $mainExecution = if ($mainExecutionIndex -ge 0) {
            $launcher.Substring($mainExecutionIndex)
        }
        else { '' }
        $tokenReadIndex = $mainExecution.IndexOf(
            'Read-ProtocolTokenForInitialPolicy', [StringComparison]::Ordinal
        )
        $authIndex = $mainExecution.IndexOf(
            "@('auth', 'status')", [StringComparison]::Ordinal
        )
        $policyImportIndex = $mainExecution.IndexOf(
            'Import-CanonicalInitialAdoptionPolicy',
            [StringComparison]::Ordinal
        )
        $assessmentIndex = $mainExecution.IndexOf(
            'Get-QuickAdoptionPreflightAssessment',
            [StringComparison]::Ordinal
        )
        if ($mainExecutionIndex -lt 0 -or $tokenReadIndex -lt 0 -or
            $authIndex -lt 0 -or $policyImportIndex -lt 0 -or
            $assessmentIndex -lt 0 -or $tokenReadIndex -gt $authIndex -or
            $authIndex -gt $policyImportIndex -or
            $policyImportIndex -gt $assessmentIndex) {
            Add-Failure 'TEST-0130 initial-policy token read, gh authentication, canonical module import, and assessment are not ordered at the mutation-free boundary.'
        }
        $completionFunctions = @($launcherAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Complete-AdoptionWithLocalCodex'
        }, $true))
        if ($parseErrors.Count -ne 0 -or $completionFunctions.Count -ne 1) {
            Add-Failure 'TEST-0050 local adoption completion responsibility seam is missing or invalid.'
        }
        $adoptionExecutionFunctions = @($launcherAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Invoke-AdoptionCodexCompletion'
        }, $true))
        $executionText = if ($adoptionExecutionFunctions.Count -eq 1) {
            $adoptionExecutionFunctions[0].Extent.Text
        }
        else { '' }
        $probeCall = $executionText.IndexOf(
            'Assert-LocalCodexWorkspaceWrite', [StringComparison]::Ordinal
        )
        $semanticCall = $executionText.IndexOf(
            'Invoke-LocalCodexExec', [StringComparison]::Ordinal
        )
        if ($adoptionExecutionFunctions.Count -ne 1 -or
            $probeCall -lt 0 -or $semanticCall -lt 0 -or
            $probeCall -gt $semanticCall) {
            Add-Failure 'TEST-0103 model-free workspace validation is not ordered before semantic Codex execution.'
        }
        if ($launcher -notmatch '(?s)finally\s*\{\s*Complete-QuickAdoptionProgress') {
            Add-Failure 'TEST-0104 launcher does not complete progress from a final cleanup boundary.'
        }
        if ($launcher -match '(?m)^\s*Write-Progress\b') {
            Add-Failure 'TEST-0105 launcher still uses the host-overlay progress renderer.'
        }
        if ($launcher -notmatch '(?s)Invoke-LocalCodexExec.+?''--json''.+?OutputLineHandler.+?Write-LocalCodexEvent') {
            Add-Failure 'TEST-0105 local Codex JSONL output is not connected to the live activity renderer.'
        }
        if ($launcher -notmatch '(?s)finally\s*\{.+?Stop-ExternalProcessTree.+?\.Dispose\(\)') {
            Add-Failure 'TEST-0106 bounded process cleanup does not stop an active child tree before disposal.'
        }
    }

    if (Test-Path -LiteralPath $mockCodexScriptPath -PathType Leaf) {
        $mockCodex = Get-Content -LiteralPath $mockCodexScriptPath -Raw
        if (-not $mockCodex.Contains('automation/meandai-capabilities-v0.12.7')) {
            Add-Failure 'TEST-0059 mock Codex remote-race fixture is not pinned to the current adoption branch.'
        }
        if (-not $mockCodex.Contains('$Arguments[0] -ceq ''sandbox''') -or
            -not $mockCodex.Contains('MEANDAI_TEST_CODEX_SANDBOX_MODE')) {
            Add-Failure 'TEST-0103 mock Codex does not model the token-free sandbox probe boundary.'
        }
    }

    $priorScenarioPath = Join-Path $root `
        'docs/features/FEAT-0012-v082-correction/test-cases.md'
    if (Test-Path -LiteralPath $priorScenarioPath -PathType Leaf) {
        $priorScenarios = Get-Content -LiteralPath $priorScenarioPath -Raw
        $test0070Row = [regex]::Match(
            $priorScenarios, '(?m)^\| `TEST-0070` \|[^\r\n]+$'
        )
        if (-not $test0070Row.Success -or
            $test0070Row.Value.IndexOf('concurrent', [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
            -not $test0070Row.Value.Contains('Serialization / recovery boundary') -or
            -not $test0070Row.Value.Contains('TEST-0082')) {
            Add-Failure 'TEST-0082 TEST-0070 must describe deterministic serialization/recovery rather than unexecuted process concurrency.'
        }
    }
    else {
        Add-Failure 'TEST-0082 FEAT-0012 scenario authority is missing.'
    }

    if (Test-Path -LiteralPath $guidePath -PathType Leaf) {
        $guide = Get-Content -LiteralPath $guidePath -Raw
        $normalizedGuide = [regex]::Replace($guide, '\s+', ' ')
        foreach ($required in @(
            'v0.12.7',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
            'Invoke-MeAndAIQuickAdoption.ps1',
            '.ai/adoption/meandai-capabilities.json',
            'dispatches the lifecycle workflow',
            'local Codex CLI',
            'temporary clone',
            'headRefOid',
            '@openai/codex@0.144.4',
            'CodexTimeoutMinutes',
            'NoProgress',
            'spawned-command network access disabled',
            'native Windows sandbox',
            'token-free workspace-write probe',
            'Not yet established',
            'progress',
            'canonically marked adoption issue',
            'preserves either canonical name that already exists',
            'does not validate value, scope, expiry, or usability',
            'selected-repository',
            'published immutable GitHub Release',
            'X-GitHub-Api-Version: 2026-03-10',
            'releases/tags/',
            'Codex prompt',
            'Quick command'
        )) {
            if (-not $normalizedGuide.Contains($required)) {
                Add-Failure "TEST-0041 quick guide is missing '$required'"
            }
        }
        foreach ($requiredBoundary in @(
            'The displayed prompt is not the adoption entry point.',
            'original target directory',
            'never copied into the isolated clone',
            'parent launcher retains network access',
            'configured model service remains reachable',
            'before and after this Codex step',
            'locally reachable Git refs and reflogs',
            'rejects shallow repositories',
            'cannot prove the absence of a credential path in remote commits'
        )) {
            if (-not $normalizedGuide.Contains($requiredBoundary)) {
                Add-Failure "TEST-0051 quick guide does not explain '$requiredBoundary'"
            }
        }
        foreach ($forbidden in @(
            'Codex Cloud', '@codex', 'sandbox_workspace_write.network_access=true'
        )) {
            if ($guide.Contains($forbidden)) {
                Add-Failure "TEST-0041 quick guide contains obsolete Cloud behavior '$forbidden'"
            }
        }
    }

    foreach ($versionCase in @(
        [pscustomobject]@{
            Name = 'older'
            Output = 'gh version 2.82.0 (mock)'
            Accepted = $false
        },
        [pscustomobject]@{
            Name = 'malformed'
            Output = 'GitHub CLI version is unknown'
            Accepted = $false
        },
        [pscustomobject]@{
            Name = 'ambiguous'
            Output = @(
                'gh version 2.82.1 (mock)',
                'gh version 2.83.0 (mock)'
            )
            Accepted = $false
        },
        [pscustomobject]@{
            Name = 'leading-zero'
            Output = 'gh version 02.82.1 (mock)'
            Accepted = $false
        },
        [pscustomobject]@{
            Name = 'exact-floor'
            Output = 'gh version 2.82.1 (mock)'
            Accepted = $true
        },
        [pscustomobject]@{
            Name = 'later'
            Output = 'gh version 2.83.0 (mock)'
            Accepted = $true
        },
        [pscustomobject]@{
            Name = 'multi-digit'
            Output = 'gh version 2.100.0 (mock)'
            Accepted = $true
        }
    )) {
        Reset-Mocks
        $global:QuickAdoptionGhVersionOutput = $versionCase.Output
        $versionRoot = New-TempRoot -Name "gh-version-$($versionCase.Name)"
        $missingTarget = Join-Path $versionRoot 'missing-target'
        $versionError = ''
        try {
            & $launcherPath -TargetPath $missingTarget -SkipLifecycleDispatch |
                Out-Null
        }
        catch {
            $versionError = $_.Exception.Message
        }
        $versionCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            ($_.Arguments -join ' ') -ceq '--version'
        })
        $nonVersionCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            ($_.Arguments -join ' ') -cne '--version'
        })
        if ($versionCalls.Count -ne 1 -or $nonVersionCalls.Count -ne 0 -or
            (Test-Path -LiteralPath $missingTarget)) {
            Add-Failure "TEST-0107 $($versionCase.Name) did not remain at the single version-query boundary."
            continue
        }
        if ([bool]$versionCase.Accepted) {
            if ($versionError -notlike '*TargetPath must identify an existing directory*') {
                Add-Failure "TEST-0107 $($versionCase.Name) did not continue to target validation: $versionError"
            }
        }
        elseif ($versionError -notlike '*GitHub CLI 2.82.1 or newer is required*' -or
            $versionError -notlike '*https://cli.github.com/*') {
            Add-Failure "TEST-0107 $($versionCase.Name) did not fail with actionable minimum-version guidance: $versionError"
        }
    }

    if ($failures.Count -eq 0) {
        Reset-Mocks
        $historyRoot = New-TempRoot -Name 'reflog-history'
        $historyRepo = Join-Path $historyRoot 'consumer'
        New-Item -ItemType Directory -Path $historyRepo -Force | Out-Null
        & git init -b main $historyRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $historyRepo
        Set-Content -LiteralPath (Join-Path $historyRepo 'app.txt') -Value 'app' -Encoding UTF8
        Invoke-TestGit -Repository $historyRepo -Arguments @('add', 'app.txt') | Out-Null
        Invoke-TestGit -Repository $historyRepo -Arguments @('commit', '-m', 'Initial') | Out-Null
        $cleanHead = (@(Invoke-TestGit -Repository $historyRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        Set-Content -LiteralPath (Join-Path $historyRepo 'FG_PAT.txt') -Value 'exposed' -NoNewline
        Invoke-TestGit -Repository $historyRepo -Arguments @('add', '-f', 'FG_PAT.txt') | Out-Null
        Invoke-TestGit -Repository $historyRepo -Arguments @('commit', '-m', 'Expose path') | Out-Null
        $exposedHead = (@(Invoke-TestGit -Repository $historyRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        Invoke-TestGit -Repository $historyRepo -Arguments @('checkout', '--detach', $cleanHead) | Out-Null
        Invoke-TestGit -Repository $historyRepo -Arguments @('branch', '-f', 'main', $cleanHead) | Out-Null
        Invoke-TestGit -Repository $historyRepo -Arguments @('checkout', 'main') | Out-Null
        Set-Content -LiteralPath (Join-Path $historyRepo 'FG_PAT.txt') -Value 'replacement' -NoNewline
        Set-Content -LiteralPath (Join-Path $historyRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'reader' -NoNewline
        $reflogFixtureEvidence = @(Invoke-TestGit -Repository $historyRepo -Arguments @(
            'log', '--all', '--reflog', '--format=%H', '--', 'FG_PAT.txt'
        ))
        $trackedFixturePath = @(Invoke-TestGit -Repository $historyRepo -Arguments @(
            'ls-files', '--', 'FG_PAT.txt'
        ))
        if ($reflogFixtureEvidence -cnotcontains $exposedHead -or
            $trackedFixturePath.Count -ne 0) {
            Add-Failure 'TEST-0055 reflog-only fixture did not establish its declared precondition.'
        }
        $reflogBlocked = $false
        $reflogMessage = ''
        try {
            & $launcherPath -TargetPath $historyRepo -SkipLifecycleDispatch | Out-Null
        }
        catch {
            $reflogBlocked = $true
            $reflogMessage = $_.Exception.Message
        }
        if (-not $reflogBlocked -or
            -not $reflogMessage.Contains('locally reachable ref or reflog history')) {
            Add-Failure "TEST-0055 a credential path reachable only through reflog evidence did not fail closed: $reflogMessage"
        }

        $unbornHistoryRoot = New-TempRoot -Name 'unborn-credential-history'
        $unbornHistoryRepo = Join-Path $unbornHistoryRoot 'consumer'
        New-Item -ItemType Directory -Path $unbornHistoryRepo -Force | Out-Null
        & git init -b exposed $unbornHistoryRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $unbornHistoryRepo
        Set-Content -LiteralPath (Join-Path $unbornHistoryRepo 'FG_PAT.txt') `
            -Value 'historically-exposed' -NoNewline
        Invoke-TestGit -Repository $unbornHistoryRepo -Arguments @(
            'add', '-f', '--', 'FG_PAT.txt'
        ) | Out-Null
        Invoke-TestGit -Repository $unbornHistoryRepo -Arguments @(
            'commit', '-m', 'Expose credential-shaped path'
        ) | Out-Null
        Invoke-TestGit -Repository $unbornHistoryRepo -Arguments @(
            'tag', 'credential-history'
        ) | Out-Null
        Invoke-TestGit -Repository $unbornHistoryRepo -Arguments @(
            'switch', '--orphan', 'unborn'
        ) | Out-Null
        if (Test-Path -LiteralPath (
                Join-Path $unbornHistoryRepo 'FG_PAT.txt'
            )) {
            Invoke-TestGit -Repository $unbornHistoryRepo -Arguments @(
                'rm', '-f', '--', 'FG_PAT.txt'
            ) | Out-Null
        }
        Set-Content -LiteralPath (Join-Path $unbornHistoryRepo 'FG_PAT.txt') `
            -Value 'replacement-writer' -NoNewline
        Set-Content -LiteralPath (
            Join-Path $unbornHistoryRepo 'MEANDAI_RO_FG_PAT.txt'
        ) -Value 'replacement-reader' -NoNewline
        $unbornHistoryEvidence = @(Invoke-TestGit `
            -Repository $unbornHistoryRepo -Arguments @(
                'log', '--all', '--reflog', '--format=%H', '--',
                ':(icase,glob)**/FG_PAT.txt'
            ))
        $unbornHasHead = Test-RepositoryHasHead `
            -Repository $unbornHistoryRepo
        if ($unbornHasHead -or $unbornHistoryEvidence.Count -eq 0) {
            Add-Failure 'TEST-0055 unborn-HEAD credential-history fixture did not establish its declared precondition.'
        }
        $unbornHistoryGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $unbornHistoryExcludePath = Join-Path `
            $unbornHistoryRepo '.git/info/exclude'
        $unbornHistoryExcludeBefore =
            [IO.File]::ReadAllText($unbornHistoryExcludePath)
        $unbornHistoryStatusBefore = @(Invoke-TestGit `
            -Repository $unbornHistoryRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        $unbornHistoryError = ''
        try {
            & $launcherPath -TargetPath $unbornHistoryRepo `
                -SkipLifecycleDispatch | Out-Null
        }
        catch {
            $unbornHistoryError = $_.Exception.Message
        }
        $unbornHistoryGhMutations = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $unbornHistoryGhCountBefore
            )
        )
        $unbornHistoryStatusAfter = @(Invoke-TestGit `
            -Repository $unbornHistoryRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        if ($unbornHistoryError -notlike
                '*locally reachable ref or reflog history*' -or
            $unbornHistoryGhMutations.Count -ne 0 -or
            [IO.File]::ReadAllText($unbornHistoryExcludePath) -cne
                $unbornHistoryExcludeBefore -or
            ($unbornHistoryStatusAfter -join "`n") -cne
                ($unbornHistoryStatusBefore -join "`n")) {
            Add-Failure "TEST-0055 unborn-HEAD credential history did not fail after canonical policy authority reads and before exclude or working-tree mutation: $unbornHistoryError"
        }

        $shallowRoot = New-TempRoot -Name 'shallow-history'
        $shallowSource = Join-Path $shallowRoot 'source'
        $shallowRepo = Join-Path $shallowRoot 'consumer'
        New-Item -ItemType Directory -Path $shallowSource -Force | Out-Null
        & git init -b main $shallowSource 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $shallowSource
        Set-Content -LiteralPath (Join-Path $shallowSource 'app.txt') -Value 'app' -Encoding UTF8
        Invoke-TestGit -Repository $shallowSource -Arguments @('add', 'app.txt') | Out-Null
        Invoke-TestGit -Repository $shallowSource -Arguments @('commit', '-m', 'Initial') | Out-Null
        $shallowSourceUri = ConvertTo-TestFileUri -Path $shallowSource
        Invoke-TestGit -Repository $shallowRoot -Arguments @(
            'clone', '--depth', '1', $shallowSourceUri, $shallowRepo
        ) | Out-Null
        $shallowGitHubUrl = 'https://github.com/test-owner/shallow-consumer.git'
        Invoke-TestGit -Repository $shallowRepo -Arguments @(
            'config', "url.$shallowSourceUri.insteadOf", $shallowGitHubUrl
        ) | Out-Null
        Invoke-TestGit -Repository $shallowRepo -Arguments @(
            'remote', 'set-url', 'origin', $shallowGitHubUrl
        ) | Out-Null
        Set-Content -LiteralPath (Join-Path $shallowRepo 'FG_PAT.txt') -Value 'writer' -NoNewline
        Set-Content -LiteralPath (Join-Path $shallowRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'reader' -NoNewline
        $shallowBlocked = $false
        $shallowMessage = ''
        try {
            & $launcherPath -TargetPath $shallowRepo -SkipLifecycleDispatch | Out-Null
        }
        catch {
            $shallowBlocked = $true
            $shallowMessage = $_.Exception.Message
        }
        if (-not $shallowBlocked -or -not $shallowMessage.Contains('non-shallow repository')) {
            Add-Failure 'TEST-0055 shallow history did not fail closed before credential or remote mutation.'
        }
    }

    if ($failures.Count -eq 0) {
        foreach ($releaseMode in @('Mutable', 'Missing')) {
            Reset-Mocks
            $releaseRoot = New-TempRoot -Name "release-$($releaseMode.ToLowerInvariant())"
            $releaseRepo = Join-Path $releaseRoot 'consumer'
            New-Item -ItemType Directory -Path $releaseRepo -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $releaseRepo 'FG_PAT.txt') `
                -Value 'write-token-value' -NoNewline
            Set-Content -LiteralPath (Join-Path $releaseRepo 'MEANDAI_RO_FG_PAT.txt') `
                -Value 'read-token-value' -NoNewline
            $global:QuickAdoptionTargetPath = $releaseRepo
            $global:QuickAdoptionRepoName = "test-owner/release-$($releaseMode.ToLowerInvariant())"
            $global:QuickAdoptionRepositoryExists = $false
            $global:QuickAdoptionReleaseMode = $releaseMode
            $releaseBlocked = $false
            try {
                & $launcherPath -TargetPath $releaseRepo -Owner test-owner `
                    -RepositoryName "release-$($releaseMode.ToLowerInvariant())" `
                    -SkipLifecycleDispatch | Out-Null
            }
            catch {
                $releaseBlocked = $true
            }
            $releaseCalls = @($global:QuickAdoptionRestCalls | Where-Object {
                $_.Uri -match '/repos/hasanmanzak/meAndAI/releases/tags/v0\.12\.7$'
            })
            $prematureMutations = @($global:QuickAdoptionGhCalls | Where-Object {
                $_.Arguments.Count -ge 2 -and
                (($_.Arguments[0] -eq 'repo' -and $_.Arguments[1] -eq 'create') -or
                 ($_.Arguments[0] -eq 'secret' -and $_.Arguments[1] -eq 'set'))
            })
            if (-not $releaseBlocked -or $releaseCalls.Count -ne 1 -or
                $prematureMutations.Count -ne 0) {
                Add-Failure "TEST-0056/TEST-0089 $releaseMode protocol release did not block before repository or secret mutation."
            }
        }

        Reset-Mocks
        $linkedRoot = New-TempRoot -Name 'linked-managed-ancestor'
        $linkedRepo = Join-Path $linkedRoot 'consumer'
        $linkedRemote = Join-Path $linkedRoot 'consumer.git'
        $linkedExternal = Join-Path $linkedRoot 'external-managed'
        New-Item -ItemType Directory -Path $linkedRepo, $linkedExternal -Force | Out-Null
        & git init --bare $linkedRemote 2>&1 | Out-Null
        & git init -b main $linkedRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $linkedRepo
        [IO.File]::WriteAllText((Join-Path $linkedRepo 'app.txt'), "consumer app`n")
        [IO.File]::WriteAllText((Join-Path $linkedExternal 'sentinel.txt'), "external sentinel`n")
        New-TestDirectoryLink -Path (Join-Path $linkedRepo '.github') `
            -Target $linkedExternal
        Invoke-Git -Repository $linkedRepo -Arguments @('add', '.') | Out-Null
        Invoke-Git -Repository $linkedRepo -Arguments @(
            'commit', '-m', 'Create linked managed ancestor fixture'
        ) | Out-Null
        Invoke-Git -Repository $linkedRepo -Arguments @(
            'config', "url.$($linkedRemote.Replace('\\', '/')).insteadOf",
            'https://github.com/test-owner/linked-consumer.git'
        ) | Out-Null
        Invoke-Git -Repository $linkedRepo -Arguments @(
            'remote', 'add', 'origin', 'https://github.com/test-owner/linked-consumer.git'
        ) | Out-Null
        Invoke-Git -Repository $linkedRepo -Arguments @(
            'push', '-u', 'origin', 'main'
        ) | Out-Null
        Set-Content -LiteralPath (Join-Path $linkedRepo 'FG_PAT.txt') `
            -Value 'write-token-value' -NoNewline
        Set-Content -LiteralPath (Join-Path $linkedRepo 'MEANDAI_RO_FG_PAT.txt') `
            -Value 'read-token-value' -NoNewline
        $global:QuickAdoptionRepoName = 'test-owner/linked-consumer'
        $global:QuickAdoptionTargetPath = $linkedRepo
        $global:QuickAdoptionRemotePath = $linkedRemote
        $externalBefore = @(
            Get-ChildItem -LiteralPath $linkedExternal -Recurse -File |
                ForEach-Object {
                    "$($_.FullName.Substring($linkedExternal.Length + 1))=$([IO.File]::ReadAllText($_.FullName))"
                }
        )
        $linkedBlocked = $false
        $linkedError = ''
        try {
            & $launcherPath -TargetPath $linkedRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $linkedBlocked = $true
            $linkedError = $_.Exception.Message
        }
        $externalAfter = @(
            Get-ChildItem -LiteralPath $linkedExternal -Recurse -File |
                ForEach-Object {
                    "$($_.FullName.Substring($linkedExternal.Length + 1))=$([IO.File]::ReadAllText($_.FullName))"
                }
        )
        $linkedMutations = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and
            (($_.Arguments[0] -ceq 'secret' -and $_.Arguments[1] -cin @('list', 'set')) -or
             ($_.Arguments[0] -ceq 'label' -and $_.Arguments[1] -ceq 'create'))
        })
        if (-not $linkedBlocked -or
            $linkedError -notlike '*traverses linked or reparse-point path*' -or
            $linkedMutations.Count -ne 0 -or
            ($externalBefore -join "`n") -cne ($externalAfter -join "`n")) {
            Add-Failure "TEST-0086 launcher did not block a linked managed ancestor before secret or external mutation: $linkedError"
        }
    }
    }

    if ((Test-QuickAdoptionShard -Name 'AdoptionLifecycle') -and
        $failures.Count -eq 0) {
        Reset-Mocks
        $existingRoot = New-TempRoot -Name 'existing'
        $existingRepo = Join-Path $existingRoot 'consumer'
        $existingRemote = Join-Path $existingRoot 'consumer.git'
        New-Item -ItemType Directory -Path $existingRepo | Out-Null
        & git init --bare $existingRemote 2>&1 | Out-Null
        & git init -b main $existingRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $existingRepo
        Set-Content -LiteralPath (Join-Path $existingRepo 'app.txt') -Value 'consumer-app' -Encoding UTF8
        Invoke-Git -Repository $existingRepo -Arguments @('add', 'app.txt') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('commit', '-m', 'Initial consumer') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'config', "url.$($existingRemote.Replace('\\', '/')).insteadOf",
            'https://github.com/test-owner/consumer.git'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'remote', 'add', 'origin', 'https://github.com/test-owner/consumer.git'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', '-u', 'origin', 'main') | Out-Null
        Set-Content -LiteralPath (Join-Path $existingRepo 'FG_PAT.txt') -Value 'write-token-value' -NoNewline
        Set-Content -LiteralPath (Join-Path $existingRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'read-token-value' -NoNewline
        $global:QuickAdoptionRepoName = 'test-owner/consumer'
        $global:QuickAdoptionTargetPath = $existingRepo
        $global:QuickAdoptionRemotePath = $existingRemote
        $env:MEANDAI_TEST_CODEX_TARGET = $existingRepo
        $env:MEANDAI_TEST_CODEX_REMOTE = $existingRemote

        $wrongDispatches = @(
            @('workflow', 'run', 'wrong-workflow.yml', '--repo', 'test-owner/consumer',
                '--ref', 'main', '--field', ('correlation_id=' + ('0' * 32))),
            @('workflow', 'run', 'meandai-protocol-update.yml', '--repo', 'other/consumer',
                '--ref', 'main', '--field', ('correlation_id=' + ('0' * 32))),
            @('workflow', 'run', 'meandai-protocol-update.yml', '--repo', 'test-owner/consumer',
                '--ref', 'develop', '--field', ('correlation_id=' + ('0' * 32))),
            @('workflow', 'run', 'meandai-protocol-update.yml', '--repo', 'test-owner/consumer',
                '--ref', 'main', '--field', 'correlation_id=not-canonical'),
            @('workflow', 'run', 'meandai-protocol-update.yml', '--repo', 'test-owner/consumer',
                '--ref', 'main', '--field', ('correlation_id=' + ('0' * 32)),
                '--field', 'adoption_strategy=FreshAdoption',
                '--field', 'acknowledge_protocol_record_loss=false',
                '--field', ('expected_base_sha=' + ('0' * 40)))
        )
        foreach ($wrongDispatch in $wrongDispatches) {
            $rejected = $false
            try {
                & gh @wrongDispatch | Out-Null
            }
            catch {
                $rejected = $true
            }
            if (-not $rejected) {
                Add-Failure "TEST-0090 mock accepted wrong workflow dispatch identity: $($wrongDispatch -join ' ')"
            }
        }
        $wrongCommitRejected = $false
        try {
            & gh 'run' 'list' '--repo' 'test-owner/consumer' `
                '--workflow' 'meandai-protocol-update.yml' `
                '--event' 'workflow_dispatch' '--branch' 'main' `
                '--commit' ('f' * 40) '--limit' '100' `
                '--json' 'databaseId,createdAt,displayTitle,headSha,status,conclusion,url' | Out-Null
        }
        catch {
            $wrongCommitRejected = $true
        }
        if (-not $wrongCommitRejected) {
            Add-Failure 'TEST-0090 mock accepted caller-supplied workflow head instead of its independently resolved head.'
        }
        $global:QuickAdoptionGhCalls.Clear()
        $global:QuickAdoptionRunListCalls = 0
        $global:QuickAdoptionExpectedPublishedHead = ''
        $global:QuickAdoptionDispatchRecord = $null

        foreach ($invalidProtocolTag in @(
            'v01.0.0', 'v1.00.0',
            ('v' + [string][char]0x0661 + '.0.0'),
            ('v' + [string][char]0xFF11 + '.0.0')
        )) {
            $tagRejected = $false
            $tagError = ''
            try {
                & $launcherPath -TargetPath $existingRepo `
                    -ProtocolTag $invalidProtocolTag -SkipLifecycleDispatch `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $tagRejected = $true
                $tagError = $_.Exception.Message
            }
            if (-not $tagRejected -or $tagError -notlike '*vM.m.rev*' -or
                $global:QuickAdoptionSecrets.Count -ne 0 -or
                $global:QuickAdoptionLabelRecords.ContainsKey(
                    'meandai:secret-reconciliation-lock'
                )) {
                Add-Failure "TEST-0088 launcher accepted noncanonical or Unicode-digit tag '$invalidProtocolTag': $tagError"
            }
        }
        $global:QuickAdoptionGhCalls.Clear()
        $global:QuickAdoptionRestCalls.Clear()
        $hugeProtocolTag = 'v0.92233720368547758081234567890.99999999999999999999999999999'
        $secretCountBeforeHugeTag = $global:QuickAdoptionSecrets.Count
        $hugeTagReachedReleaseBoundary = $false
        $hugeTagError = ''
        try {
            & $launcherPath -TargetPath $existingRepo `
                -ProtocolTag $hugeProtocolTag -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $hugeTagError = $_.Exception.Message
        }
        $hugeTagReleaseCalls = @($global:QuickAdoptionRestCalls | Where-Object {
            $_.Uri -ceq "https://api.github.com/repos/hasanmanzak/meAndAI/releases/tags/$hugeProtocolTag"
        })
        $hugeTagReachedReleaseBoundary = $hugeTagReleaseCalls.Count -eq 1
        if (-not $hugeTagReachedReleaseBoundary -or
            $hugeTagError -like '*vM.m.rev*' -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeHugeTag -or
            $global:QuickAdoptionLabelRecords.ContainsKey(
                'meandai:secret-reconciliation-lock'
            )) {
            Add-Failure "TEST-0088 launcher did not accept an unbounded canonical tag through its release-authority boundary: $hugeTagError"
        }
        $global:QuickAdoptionGhCalls.Clear()
        $global:QuickAdoptionRestCalls.Clear()

        $seedParent = Split-Path -Parent (Join-Path $existingRepo $workflowRelativePath)
        New-Item -ItemType Directory -Path $seedParent -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo $workflowRelativePath),
            "name: consumer-owned drift`n"
        )
        Invoke-Git -Repository $existingRepo -Arguments @(
            'add', '--', $workflowRelativePath
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Create noncanonical seed fixture'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $seedDriftBlocked = $false
        $seedDriftError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $seedDriftBlocked = $true
            $seedDriftError = $_.Exception.Message
        }
        $prematureSeedMutations = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and
            (($_.Arguments[0] -ceq 'label' -and $_.Arguments[1] -ceq 'create' -and
              $_.Arguments -ccontains 'meandai:secret-reconciliation-lock') -or
             ($_.Arguments[0] -ceq 'secret' -and $_.Arguments[1] -cin @('list', 'set')))
        })
        if (-not $seedDriftBlocked -or
            $seedDriftError.IndexOf('seed', [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
            $seedDriftError.IndexOf('workflow', [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
            $prematureSeedMutations.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure "TEST-0078 noncanonical seed workflow did not block before lock acquisition, secret inventory, and secret writes: $seedDriftError"
        }
        Invoke-Git -Repository $existingRepo -Arguments @(
            'rm', '--', $workflowRelativePath
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Remove noncanonical seed fixture'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $global:QuickAdoptionGhCalls.Clear()
        $global:QuickAdoptionRestCalls.Clear()
        $global:QuickAdoptionSecrets.Clear()
        $global:QuickAdoptionExistingSecrets.Clear()
        $global:QuickAdoptionLabelRecords.Clear()

        $global:QuickAdoptionIssueRace = $true
        $env:MEANDAI_TEST_CODEX_SANDBOX_MODE = if ($env:OS -eq 'Windows_NT') {
            'FailElevated'
        }
        else { 'Success' }
        $launcherAssessedGraphBase = (@(Invoke-Git `
            -Repository $existingRepo -Arguments @('rev-parse', 'HEAD')))[0]
        $runOutput = @(& $launcherPath -TargetPath $existingRepo `
            -CodexCommand $mockCodexPath *>&1) -join [Environment]::NewLine
        $env:MEANDAI_TEST_CODEX_SANDBOX_MODE = 'Success'
        if ($global:QuickAdoptionSecrets.Count -ne 2 -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_UPDATER_TOKEN' -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_PROTOCOL_TOKEN') {
            Add-Failure 'TEST-0034 existing adoption did not reconcile both required secrets.'
        }
        foreach ($secret in $global:QuickAdoptionSecrets) {
            if ($secret.Arguments -contains '--body' -or
                $secret.InputValidated -isnot [bool] -or
                -not $secret.InputValidated -or
                $null -ne $secret.PSObject.Properties['Value']) {
                Add-Failure 'TEST-0073 secret mapping was not asserted through redacted stdin-only evidence.'
            }
        }
        $restBoundaries = @($global:QuickAdoptionRestCalls.CredentialBoundary | Sort-Object -Unique)
        if ($restBoundaries -cnotcontains 'protocol-read' -or
            $restBoundaries -cnotcontains 'consumer-write' -or
            @($global:QuickAdoptionRestCalls | Where-Object {
                $null -ne $_.PSObject.Properties['Authorization']
            }).Count -ne 0) {
            Add-Failure 'TEST-0073 REST mocks did not prove both credential roles without retaining authorization values.'
        }
        $initialPolicyRestCalls = @($global:QuickAdoptionRestCalls |
            Where-Object {
                [string]$_.Uri -ceq
                    'https://api.github.com/repos/hasanmanzak/meAndAI/contents/templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1?ref=v0.12.7'
            })
        $workflowRestCalls = @($global:QuickAdoptionRestCalls |
            Where-Object {
                [string]$_.Uri -ceq
                    'https://api.github.com/repos/hasanmanzak/meAndAI/contents/templates/project/.github/workflows/meandai-protocol-update.yml?ref=v0.12.7'
            })
        if ($initialPolicyRestCalls.Count -ne 1 -or
            $workflowRestCalls.Count -ne 1) {
            Add-Failure 'TEST-0130 token-backed adoption did not retrieve exactly one canonical policy module and one canonical workflow asset.'
        }
        $lockCreateCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 3 -and $_.Arguments[0] -ceq 'label' -and
            $_.Arguments[1] -ceq 'create' -and
            $_.Arguments[2] -ceq 'meandai:secret-reconciliation-lock'
        })
        $lockDeleteCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'api' -and
            $_.Arguments -ccontains 'DELETE' -and
            $_.Arguments -ccontains 'repos/test-owner/consumer/labels/meandai%3Asecret-reconciliation-lock'
        })
        $firstSecretListCall = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
            $_.Arguments[1] -ceq 'list'
        } | Select-Object -First 1)
        $firstSecretSetCall = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
            $_.Arguments[1] -ceq 'set'
        } | Select-Object -First 1)
        if ($lockCreateCalls.Count -ne 1 -or $lockDeleteCalls.Count -ne 1 -or
            $firstSecretListCall.Count -ne 1 -or $firstSecretSetCall.Count -ne 1 -or
            $global:QuickAdoptionGhCalls.IndexOf($lockCreateCalls[0]) -ge
                $global:QuickAdoptionGhCalls.IndexOf($firstSecretListCall[0]) -or
            $global:QuickAdoptionGhCalls.IndexOf($firstSecretListCall[0]) -ge
                $global:QuickAdoptionGhCalls.IndexOf($firstSecretSetCall[0]) -or
            $global:QuickAdoptionGhCalls.IndexOf($firstSecretSetCall[0]) -ge
                $global:QuickAdoptionGhCalls.IndexOf($lockDeleteCalls[0]) -or
            $global:QuickAdoptionLabelRecords.ContainsKey('meandai:secret-reconciliation-lock')) {
            Add-Failure 'TEST-0070 secret inventory and writes were not enclosed by one owned atomic GitHub lock.'
        }
        if ($runOutput.Contains('write-token-value') -or $runOutput.Contains('read-token-value')) {
            Add-Failure 'TEST-0033 launcher output exposed a token value.'
        }
        if (-not $runOutput.Contains('meAndAI [') -or
            -not $runOutput.Contains('Codex | Inspecting project records.') -or
            -not $runOutput.Contains('Codex | Running command: git') -or
            $runOutput.Contains('MEANDAI_TEST_HIDDEN_COMMAND_OUTPUT')) {
            Add-Failure 'TEST-0105 launcher did not produce bounded line-oriented phase and live Codex activity output.'
        }
        $dispatchCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'workflow' -and $_.Arguments[1] -eq 'run'
        })
        $codexCalls = @(Get-MockCodexCalls)
        $execCalls = @($codexCalls | Where-Object {
            $_.Arguments.Count -gt 0 -and $_.Arguments[0] -eq 'exec'
        })
        $sandboxCalls = @(Get-MockCodexSandboxCalls)
        $sandboxModes = @($sandboxCalls | ForEach-Object {
            $joined = $_.Arguments -join "`n"
            if ($joined -match 'windows\.sandbox=[\"''](?<mode>elevated|unelevated)[\"'']') {
                $Matches['mode']
            }
        })
        if ($dispatchCalls.Count -ne 1 -or $execCalls.Count -ne 1 -or
            -not $execCalls[0].Stdin.Contains('.ai/adoption/meandai-capabilities.json') -or
            -not $execCalls[0].Stdin.Contains('/issues/83') -or
            $execCalls[0].Stdin.Contains('Use gh') -or
            $global:QuickAdoptionPrReadyCalls -ne 1) {
            Add-Failure 'TEST-0039 default adoption did not complete once through local Codex and mark the draft ready.'
        }
        if ($env:OS -eq 'Windows_NT') {
            if (($sandboxModes -join '|') -cne 'elevated|unelevated' -or
                ($execCalls[0].Arguments -join "`n") -notmatch
                    'windows\.sandbox=[\"'']unelevated[\"'']') {
                Add-Failure 'TEST-0103 failed elevated preflight did not fall back to the verified unelevated mode before semantic execution.'
            }
        }
        elseif ($sandboxCalls.Count -ne 0 -or
            ($execCalls[0].Arguments -join "`n").Contains('windows.sandbox=')) {
            Add-Failure 'TEST-0103 non-Windows execution attempted to select or probe a native Windows sandbox.'
        }
        $publishedMainHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin', 'refs/heads/main'
        )))[0].Split("`t")[0]
        $runViewCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 3 -and
            $_.Arguments[0] -ceq 'run' -and $_.Arguments[1] -ceq 'view'
        })
        if ($null -eq $global:QuickAdoptionDispatchRecord -or
            $global:QuickAdoptionDispatchRecord.Workflow -cne 'meandai-protocol-update.yml' -or
            $global:QuickAdoptionDispatchRecord.Repository -cne 'test-owner/consumer' -or
            $global:QuickAdoptionDispatchRecord.Ref -cne 'main' -or
            $global:QuickAdoptionDispatchRecord.CorrelationId -cnotmatch '^[0-9a-f]{32}$' -or
            $global:QuickAdoptionDispatchRecord.ExpectedBaseSha -cne $publishedMainHead -or
            $null -eq $global:QuickAdoptionDispatchRecord.SourceGraphIdentity -or
            [string]$global:QuickAdoptionDispatchRecord.SourceGraphIdentity.graphBase -cne
                $launcherAssessedGraphBase -or
            $global:QuickAdoptionDispatchRecord.Head -cne $publishedMainHead -or
            $runViewCalls.Count -ne 1 -or
            [string]$runViewCalls[0].Arguments[2] -cne '7001') {
            Add-Failure 'TEST-0090/TEST-0153 exact dispatch was not bound to its independently rebuilt pre-seed source graph, published repository head, and run identity.'
        }
        $unqualifiedGhCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            [string]$_.Host -cne 'github.com'
        })
        if ($unqualifiedGhCalls.Count -ne 0 -or
            [Environment]::GetEnvironmentVariable('GH_HOST', 'Process') -cne 'ghe.example.invalid') {
            Add-Failure 'TEST-0060 launcher GitHub operations were redirected by caller GH_HOST or did not restore it.'
        }
        $canonicalIssueMarker = '<!-- meandai-local-adoption:v0.12.7:pr-42 -->'
        $openMarkedIssues = @($global:QuickAdoptionIssues | Where-Object {
            [string]$_.state -ceq 'OPEN' -and
            [regex]::IsMatch(
                [string]$_.body,
                '\A' + [regex]::Escape($canonicalIssueMarker) + '(?:\r?\n|\z)'
            )
        })
        $quotedIssue = @($global:QuickAdoptionIssues | Where-Object {
            [int]$_.number -eq 82
        })
        if ($openMarkedIssues.Count -ne 1 -or [int]$openMarkedIssues[0].number -ne 83 -or
            $global:QuickAdoptionEvents -notcontains 'issue-close:84' -or
            $quotedIssue.Count -ne 1 -or [string]$quotedIssue[0].state -cne 'OPEN' -or
            -not ([string]$quotedIssue[0].body).StartsWith('> ', [StringComparison]::Ordinal)) {
            Add-Failure 'TEST-0069 exact issue ownership did not converge without claiming a quoted marker.'
        }
        if ($global:QuickAdoptionIssues.Count -ne 3 -or
            $openMarkedIssues.Count -ne 1 -or
            $global:QuickAdoptionEvents -notcontains 'issue-close:84' -or
            $null -eq $global:QuickAdoptionDispatchRecord -or
            $runViewCalls.Count -ne 1) {
            Add-Failure 'TEST-0063 concurrent workflow and issue identities did not converge to the correlated run and one canonical issue.'
        }
        if ($global:QuickAdoptionPrBodyEditCalls -ne 2 -or
            @($global:QuickAdoptionEvents | Where-Object {
                $_ -ceq 'pr-body-edit:publishing'
            }).Count -ne 1 -or
            @($global:QuickAdoptionEvents | Where-Object {
                $_ -ceq 'pr-body-edit:completed'
            }).Count -ne 1 -or
            $global:QuickAdoptionPrBody -notmatch [regex]::Escape($global:QuickAdoptionPrHead)) {
            Add-Failure 'TEST-0052 launcher did not persist exactly one publishing and one completed marker transition.'
        }
        $trackingLines = [regex]::Matches(
            [string]$global:QuickAdoptionPrBody,
            '^Tracking issue: #83\r?$',
            [Text.RegularExpressions.RegexOptions]::Multiline -bor
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        $closingIssueReferences = [regex]::Matches(
            [string]$global:QuickAdoptionPrBody,
            '\b(?:close(?:s|d)?|fix(?:es|ed)?|resolve(?:s|d)?)\b[^\r\n]*#83(?![0-9])',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if ($trackingLines.Count -ne 1 -or $closingIssueReferences.Count -ne 0) {
            Add-Failure 'TEST-0052 launcher did not bind the ready adoption proposal to exactly one non-closing canonical issue line.'
        }
        $reviewEvents = @($global:QuickAdoptionEvents | Where-Object {
            $_ -ceq 'issue-label:add:status:needs-review'
        })
        $readyEventIndex = $global:QuickAdoptionEvents.IndexOf('pr-ready')
        $reviewEventIndex = $global:QuickAdoptionEvents.IndexOf(
            'issue-label:add:status:needs-review'
        )
        if ($reviewEvents.Count -ne 1 -or $readyEventIndex -lt 0 -or
            $reviewEventIndex -le $readyEventIndex) {
            Add-Failure 'TEST-0049 adoption issue review status was not applied exactly once after pull-request readiness.'
        }
        $expectedLabels = @(
            'type:epic', 'type:feature', 'type:subfeature', 'type:task', 'type:bug',
            'type:finding', 'priority:p0', 'priority:p1', 'priority:p2', 'priority:p3',
            'status:blocked', 'status:in-progress', 'status:needs-review'
        )
        if ($global:QuickAdoptionLabels.Count -ne $expectedLabels.Count -or
            @($expectedLabels | Where-Object { $global:QuickAdoptionLabels -notcontains $_ }).Count -ne 0 -or
            $null -eq $global:QuickAdoptionIssue) {
            Add-Failure 'TEST-0039 launcher did not reconcile the deterministic Agile labels and adoption issue.'
        }

        $quotedIssueOriginalBody = [string]$quotedIssue[0].body
        $quotedIssueOriginalTitle = [string]$quotedIssue[0].title
        $quotedIssue[0].body = "$canonicalIssueMarker`n## Not the canonical adoption record"
        $quotedIssue[0].title = 'Drifted marked issue'
        $issueEventsBeforeDrift = $global:QuickAdoptionEvents.Count
        $codexCallsBeforeIssueDrift = @(Get-MockCodexCalls).Count
        $issueDriftBlocked = $false
        $issueDriftError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $issueDriftBlocked = $true
            $issueDriftError = $_.Exception.Message
        }
        if (-not $issueDriftBlocked -or
            $issueDriftError -notlike '*drifted from its exact owned record*' -or
            $global:QuickAdoptionEvents.Count -ne $issueEventsBeforeDrift -or
            @(Get-MockCodexCalls).Count -ne $codexCallsBeforeIssueDrift) {
            Add-Failure 'TEST-0069 first-line marker drift was normalized or mutated instead of blocking exact ownership.'
        }
        $quotedIssue[0].body = $quotedIssueOriginalBody
        $quotedIssue[0].title = $quotedIssueOriginalTitle

        $secretListsBeforeContention = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
            $_.Arguments[1] -ceq 'list'
        }).Count
        $secretWritesBeforeContention = $global:QuickAdoptionSecrets.Count
        $global:QuickAdoptionLabelRecords['meandai:secret-reconciliation-lock'] = [pscustomobject]@{
            name = 'meandai:secret-reconciliation-lock'
            description = 'stale or competing session'
        }
        $contentionBlocked = $false
        $contentionError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $contentionBlocked = $true
            $contentionError = $_.Exception.Message
        }
        $secretListsAfterContention = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
            $_.Arguments[1] -ceq 'list'
        }).Count
        if (-not $contentionBlocked -or
            $contentionError -notlike '*already locked or a stale*' -or
            $secretListsAfterContention -ne $secretListsBeforeContention -or
            $global:QuickAdoptionSecrets.Count -ne $secretWritesBeforeContention -or
            -not $global:QuickAdoptionLabelRecords.ContainsKey('meandai:secret-reconciliation-lock')) {
            Add-Failure 'TEST-0070/TEST-0082 deterministic preseeded contention state did not fail closed before secret inventory and writes.'
        }
        [void]$global:QuickAdoptionLabelRecords.Remove('meandai:secret-reconciliation-lock')

        $deleteCountBeforeOwnerChange = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'api' -and
            $_.Arguments -ccontains 'DELETE' -and
            $_.Arguments -ccontains 'repos/test-owner/consumer/labels/meandai%3Asecret-reconciliation-lock'
        }).Count
        $global:QuickAdoptionSecretLockMode = 'OwnershipChanged'
        $global:QuickAdoptionSecretLockViewCalls = 0
        $ownerChangeBlocked = $false
        $ownerChangeError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $ownerChangeBlocked = $true
            $ownerChangeError = $_.Exception.Message
        }
        $deleteCountAfterOwnerChange = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'api' -and
            $_.Arguments -ccontains 'DELETE' -and
            $_.Arguments -ccontains 'repos/test-owner/consumer/labels/meandai%3Asecret-reconciliation-lock'
        }).Count
        if (-not $ownerChangeBlocked -or
            $ownerChangeError -notlike '*lock ownership changed*' -or
            $deleteCountAfterOwnerChange -ne $deleteCountBeforeOwnerChange -or
            -not $global:QuickAdoptionLabelRecords.ContainsKey('meandai:secret-reconciliation-lock')) {
            Add-Failure 'TEST-0070/TEST-0082 deterministic ownership-change state was deleted or accepted instead of failing closed.'
        }
        [void]$global:QuickAdoptionLabelRecords.Remove('meandai:secret-reconciliation-lock')
        $global:QuickAdoptionSecretLockMode = 'Normal'
        $global:QuickAdoptionSecretLockViewCalls = 0
        $adoptionPaths = @(Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.12.7'
        ))
        if ($adoptionPaths -contains '.ai/adoption/meandai-capabilities.json' -or
            $adoptionPaths -notcontains 'docs/governance/ai-adoption.md') {
            Add-Failure 'TEST-0039 local Codex result was not published without the transient manifest.'
        }

        $remotePaths = @(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-tree', '-r', '--name-only', 'origin/main'
        ))
        $expectedPaths = @($workflowRelativePath, 'app.txt') | Sort-Object
        if ((@($remotePaths | Sort-Object) -join '|') -cne ($expectedPaths -join '|')) {
            Add-Failure "TEST-0034/TEST-0086 ordinary contained adoption has unexpected remote paths: $($remotePaths -join ', ')"
        }
        $status = @(Invoke-Git -Repository $existingRepo -Arguments @('status', '--short'))
        if ($status.Count -ne 0) {
            Add-Failure "TEST-0034 existing repository is not clean after adoption: $($status -join ', ')"
        }

        $global:QuickAdoptionRunListCalls = 0
        $global:QuickAdoptionPrListCalls = 0
        $secretCountBeforeRerun = $global:QuickAdoptionSecrets.Count
        [void]$global:QuickAdoptionExistingSecrets.Remove('MEANDAI_UPDATER_TOKEN')
        $global:QuickAdoptionExistingSecrets.Add('meandai_updater_token')
        Remove-Item -LiteralPath (Join-Path $existingRepo 'FG_PAT.txt') -Force
        Remove-Item -LiteralPath (Join-Path $existingRepo 'MEANDAI_RO_FG_PAT.txt') -Force
        $headBeforeRerun = (Invoke-Git -Repository $existingRepo -Arguments @('rev-parse', 'HEAD'))[0]
        $bodyEditsBeforeRerun = $global:QuickAdoptionPrBodyEditCalls
        & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        $headAfterRerun = (Invoke-Git -Repository $existingRepo -Arguments @('rev-parse', 'HEAD'))[0]
        if ($headBeforeRerun -cne $headAfterRerun) {
            Add-Failure 'TEST-0036 exact rerun created a duplicate commit.'
        }
        $rerunCodexCalls = @(Get-MockCodexCalls)
        $rerunExecCalls = @($rerunCodexCalls | Where-Object {
            $_.Arguments.Count -gt 0 -and $_.Arguments[0] -eq 'exec'
        })
        $rerunLoginCalls = @($rerunCodexCalls | Where-Object {
            ($_.Arguments -join ' ') -eq 'login status'
        })
        if ($rerunExecCalls.Count -ne 1 -or $rerunLoginCalls.Count -ne 1 -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionPrBodyEditCalls -ne $bodyEditsBeforeRerun) {
            Add-Failure 'TEST-0052 exact rerun repeated semantic work or the completed proposal transition.'
        }
        if ($global:QuickAdoptionSecrets.Count -ne $secretCountBeforeRerun) {
            Add-Failure 'TEST-0045 exact rerun overwrote an existing mapped Actions secret.'
        }
        $protocolSourceEndpoint = 'repos/hasanmanzak/meAndAI/contents/templates/project/.github/workflows/meandai-protocol-update.yml?ref=v0.12.7'
        $protocolSourceCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'api' -and
            $_.Arguments -contains $protocolSourceEndpoint
        })
        $initialPolicySourceEndpoint = 'repos/hasanmanzak/meAndAI/contents/templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1?ref=v0.12.7'
        $initialPolicySourceCalls = @($global:QuickAdoptionGhCalls |
            Where-Object {
                $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'api' -and
                $_.Arguments -contains $initialPolicySourceEndpoint
            })
        if ($protocolSourceCalls.Count -ne 1 -or
            $initialPolicySourceCalls.Count -ne 1) {
            Add-Failure 'TEST-0045/TEST-0130 file-free rerun did not retrieve exactly one canonical policy module and one workflow source through authenticated local gh.'
        }
        $secretListCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'secret' -and $_.Arguments[1] -eq 'list'
        })
        if ($secretListCalls.Count -lt 2) {
            Add-Failure 'TEST-0042 launcher did not inspect repository Actions secret names before reconciliation.'
        }
        foreach ($call in $secretListCalls) {
            $jsonIndex = [Array]::IndexOf([object[]]$call.Arguments, '--json')
            if ($jsonIndex -lt 0 -or $jsonIndex + 1 -ge $call.Arguments.Count -or
                $call.Arguments[$jsonIndex + 1] -cne 'name') {
                Add-Failure 'TEST-0042 launcher requested more than repository secret names during reconciliation.'
            }
        }

        Reset-MockAdoptionProposal
        $global:QuickAdoptionIssueRace = $false
        $global:QuickAdoptionIssues.Clear()
        $global:QuickAdoptionIssueLabels.Clear()
        $global:QuickAdoptionIssue = $null
        $global:QuickAdoptionPrBodyEditMode = 'FailCompletedOnce'
        $codexCountBeforeInterruptedCompletion = @(Get-MockCodexCalls).Count
        $interruptedCompletionBlocked = $false
        $interruptedCompletionError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $interruptedCompletionBlocked = $true
            $interruptedCompletionError = $_.Exception.Message
        }
        $interruptedRemoteHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        )))[0].Split("`t")[0]
        $codexCountAfterInterruptedCompletion = @(Get-MockCodexCalls).Count
        if (-not $interruptedCompletionBlocked -or
            $global:QuickAdoptionCompletedEditFailures -ne 1 -or
            $interruptedRemoteHead -cnotmatch '^[0-9a-f]{40}$' -or
            $codexCountAfterInterruptedCompletion -ne ($codexCountBeforeInterruptedCompletion + 2) -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure (
                'TEST-0079 completion interruption fixture did not stop after ' +
                'the push and before completed-marker persistence: ' +
                "blocked=$interruptedCompletionBlocked; " +
                "completedEditFailures=$($global:QuickAdoptionCompletedEditFailures); " +
                "remoteHeadValid=$($interruptedRemoteHead -cmatch '^[0-9a-f]{40}$'); " +
                "codexDelta=$($codexCountAfterInterruptedCompletion - $codexCountBeforeInterruptedCompletion); " +
                "readyCalls=$($global:QuickAdoptionPrReadyCalls); " +
                "error=$interruptedCompletionError"
            )
        }
        $global:QuickAdoptionPrBodyEditMode = 'Normal'
        $interruptedRecoveryThrew = $false
        $interruptedRecoveryError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $interruptedRecoveryThrew = $true
            $interruptedRecoveryError = $_.Exception.Message
        }
        $recoveredRemoteHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        )))[0].Split("`t")[0]
        if ($interruptedRecoveryThrew -or
            $recoveredRemoteHead -cne $interruptedRemoteHead -or
            @(Get-MockCodexCalls).Count -ne $codexCountAfterInterruptedCompletion -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            -not $global:QuickAdoptionPrBody.Contains('"phase":"Completed"')) {
            Add-Failure (
                'TEST-0079 exact rerun did not finalize the already-pushed ' +
                'completion without repeating semantic work or creating a commit: ' +
                "threw=$interruptedRecoveryThrew; " +
                "headStable=$($recoveredRemoteHead -ceq $interruptedRemoteHead); " +
                "codexStable=$(@(Get-MockCodexCalls).Count -eq $codexCountAfterInterruptedCompletion); " +
                "readyCalls=$($global:QuickAdoptionPrReadyCalls); " +
                "completedBody=$($global:QuickAdoptionPrBody.Contains('"phase":"Completed"')); " +
                "error=$interruptedRecoveryError"
            )
        }

        Reset-MockAdoptionProposal
        $global:QuickAdoptionIssueRace = $false
        $global:QuickAdoptionIssues.Clear()
        $global:QuickAdoptionIssueLabels.Clear()
        $global:QuickAdoptionIssueEditMode = 'FailNeedsReviewOnce'
        $codexCountBeforePostReadyFailure = @(Get-MockCodexCalls).Count
        $postReadyBlocked = $false
        $postReadyError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $postReadyBlocked = $true
            $postReadyError = $_.Exception.Message
        }
        $postReadyHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        )))[0].Split("`t")[0]
        $codexCountAfterPostReadyFailure = @(Get-MockCodexCalls).Count
        $bodyEditsAfterPostReadyFailure = $global:QuickAdoptionPrBodyEditCalls
        if (-not $postReadyBlocked -or
            $global:QuickAdoptionIssueEditFailures -ne 1 -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionPrDraft -or
            -not $global:QuickAdoptionPrBody.Contains('"phase":"Completed"') -or
            $codexCountAfterPostReadyFailure -ne ($codexCountBeforePostReadyFailure + 2)) {
            Add-Failure "TEST-0052/TEST-0089 interruption did not occur after readiness and before issue reconciliation: error='$postReadyError'; issueFailures=$($global:QuickAdoptionIssueEditFailures); readyCalls=$($global:QuickAdoptionPrReadyCalls); draft=$($global:QuickAdoptionPrDraft); codex=$codexCountBeforePostReadyFailure->$codexCountAfterPostReadyFailure."
        }
        $global:QuickAdoptionIssueEditMode = 'Normal'
        $postReadyRecoveryThrew = $false
        $postReadyRecoveryError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $postReadyRecoveryThrew = $true
            $postReadyRecoveryError = $_.Exception.Message
        }
        $postReadyRecoveredHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        )))[0].Split("`t")[0]
        if ($postReadyRecoveryThrew -or
            $postReadyRecoveredHead -cne $postReadyHead -or
            @(Get-MockCodexCalls).Count -ne $codexCountAfterPostReadyFailure -or
            $global:QuickAdoptionPrBodyEditCalls -ne $bodyEditsAfterPostReadyFailure -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionIssueLabels -cnotcontains 'status:needs-review') {
            Add-Failure "TEST-0052/TEST-0087/TEST-0089 rerun after readiness did not retain the exact Completed proposal and reconcile the issue without Codex or a new commit: error='$postReadyRecoveryError'; head=$postReadyHead->$postReadyRecoveredHead; readyCalls=$($global:QuickAdoptionPrReadyCalls); issueLabels=$($global:QuickAdoptionIssueLabels -join ',')."
        }

        $alreadyReadyBaseHead = (@(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'rev-parse', 'refs/heads/main'
            )))[0]
        $readyCallsBeforeCompletedBaseRace =
            $global:QuickAdoptionPrReadyCalls
        $undoCallsBeforeCompletedBaseRace =
            $global:QuickAdoptionPrReadyUndoCalls
        $baseAdvanceCallsBeforeCompletedBaseRace =
            $global:QuickAdoptionBaseAdvanceCalls
        $global:QuickAdoptionPrMetadataMode =
            'AdvanceBaseAtConfiguredRevalidation'
        $global:QuickAdoptionBaseAdvanceAtPrListCall =
            $global:QuickAdoptionPrListCalls + 2
        $completedBaseRaceError = ''
        try {
            & $launcherPath -TargetPath $existingRepo `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $completedBaseRaceError = $_.Exception.Message
        }
        finally {
            if ($global:QuickAdoptionBaseAdvanceCalls -gt
                    $baseAdvanceCallsBeforeCompletedBaseRace) {
                Invoke-TestGit -Repository $existingRepo -Arguments @(
                    'push', '--force', 'origin',
                    "$alreadyReadyBaseHead`:refs/heads/main"
                ) | Out-Null
            }
            $global:QuickAdoptionPrMetadataMode = 'Valid'
            $global:QuickAdoptionBaseAdvanceAtPrListCall = 0
            $global:QuickAdoptionExpectedPublishedHead =
                $alreadyReadyBaseHead
        }
        if ($completedBaseRaceError -notlike
                '*canonical consumer base changed while the adoption pull request became ready*No ready-state compensation was attempted because this invocation did not own a proven ready transition*' -or
            $global:QuickAdoptionBaseAdvanceCalls -ne
                ($baseAdvanceCallsBeforeCompletedBaseRace + 1) -or
            $global:QuickAdoptionPrReadyCalls -ne
                $readyCallsBeforeCompletedBaseRace -or
            $global:QuickAdoptionPrReadyUndoCalls -ne
                $undoCallsBeforeCompletedBaseRace -or
            $global:QuickAdoptionPrDraft) {
            Add-Failure "TEST-0052 completed/already-ready recovery compensated a base race it did not own, changed ready state, or missed the final base check: error='$completedBaseRaceError'; advances=$baseAdvanceCallsBeforeCompletedBaseRace->$($global:QuickAdoptionBaseAdvanceCalls); ready=$readyCallsBeforeCompletedBaseRace->$($global:QuickAdoptionPrReadyCalls); undo=$undoCallsBeforeCompletedBaseRace->$($global:QuickAdoptionPrReadyUndoCalls); draft=$($global:QuickAdoptionPrDraft)."
        }

        Reset-Mocks
        $readyMetadataConsumer = New-MockConnectedSeedConsumer `
            -Name 'ready-metadata-drift'
        $global:QuickAdoptionRepoViewMode = 'WrongAfterReady'
        $readyMetadataError = ''
        try {
            & $launcherPath -TargetPath $readyMetadataConsumer.Repository `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $readyMetadataError = $_.Exception.Message
        }
        if ($readyMetadataError -notlike
                '*canonical consumer base changed while the adoption pull request became ready*pull request was returned to draft for reassessment*' -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionPrReadyUndoCalls -ne 1 -or
            -not $global:QuickAdoptionPrDraft -or
            $global:QuickAdoptionIssueLabels -contains
                'status:needs-review') {
            Add-Failure "TEST-0052 ready-then-default-branch metadata drift was not compensated by the invocation-owned undo: error='$readyMetadataError'; ready=$($global:QuickAdoptionPrReadyCalls); undo=$($global:QuickAdoptionPrReadyUndoCalls); draft=$($global:QuickAdoptionPrDraft)."
        }

        Reset-Mocks
        $completionHookConsumer = New-MockConnectedSeedConsumer `
            -Name 'completion-hook-injection'
        $completionHookDirectory = New-TestPostCommitIndexInjectionHook `
            -Name 'completion' -OnlyAfterManifestRemoval
        $savedGitConfigCount = [Environment]::GetEnvironmentVariable(
            'GIT_CONFIG_COUNT', 'Process'
        )
        $savedGitConfigKey = [Environment]::GetEnvironmentVariable(
            'GIT_CONFIG_KEY_0', 'Process'
        )
        $savedGitConfigValue = [Environment]::GetEnvironmentVariable(
            'GIT_CONFIG_VALUE_0', 'Process'
        )
        $savedGitConfigInactiveKey = [Environment]::GetEnvironmentVariable(
            'GIT_CONFIG_KEY_1', 'Process'
        )
        $savedGitConfigInactiveValue = [Environment]::GetEnvironmentVariable(
            'GIT_CONFIG_VALUE_1', 'Process'
        )
        $completionHookError = ''
        $completionHookEnvironmentRestored = $false
        try {
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_COUNT', '1', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_KEY_0', 'core.hooksPath', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_VALUE_0',
                $completionHookDirectory.Replace(
                    [IO.Path]::DirectorySeparatorChar, '/'
                ),
                'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_KEY_1', 'meandai.inactiveSentinel', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_VALUE_1', 'restore-exactly', 'Process'
            )
            & $launcherPath -TargetPath $completionHookConsumer.Repository `
                -CodexCommand $mockCodexPath | Out-Null
            $completionHookEnvironmentRestored =
                [Environment]::GetEnvironmentVariable(
                    'GIT_CONFIG_COUNT', 'Process'
                ) -ceq '1' -and
                [Environment]::GetEnvironmentVariable(
                    'GIT_CONFIG_KEY_0', 'Process'
                ) -ceq 'core.hooksPath' -and
                [Environment]::GetEnvironmentVariable(
                    'GIT_CONFIG_VALUE_0', 'Process'
                ) -ceq $completionHookDirectory.Replace(
                    [IO.Path]::DirectorySeparatorChar, '/'
                ) -and
                [Environment]::GetEnvironmentVariable(
                    'GIT_CONFIG_KEY_1', 'Process'
                ) -ceq 'meandai.inactiveSentinel' -and
                [Environment]::GetEnvironmentVariable(
                    'GIT_CONFIG_VALUE_1', 'Process'
                ) -ceq 'restore-exactly'
        }
        catch {
            $completionHookError = $_.Exception.Message
        }
        finally {
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_COUNT', $savedGitConfigCount, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_KEY_0', $savedGitConfigKey, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_VALUE_0', $savedGitConfigValue, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_KEY_1', $savedGitConfigInactiveKey, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GIT_CONFIG_VALUE_1', $savedGitConfigInactiveValue, 'Process'
            )
        }
        $completionHookPaths = @(Invoke-TestGit `
            -Repository $completionHookConsumer.Remote -Arguments @(
                'ls-tree', '-r', '--name-only',
                'refs/heads/automation/meandai-capabilities-v0.12.7'
            ))
        if ($completionHookError -or
            -not $completionHookEnvironmentRestored -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $completionHookPaths -contains
                '.ai/adoption/meandai-capabilities.json' -or
            $completionHookPaths -contains
                '.meandai-hook-index-injection') {
            Add-Failure "TEST-0052 launcher-scoped hook suppression did not prevent post-commit adoption injection, publish readiness, and restore the exact preexisting GIT_CONFIG_* environment: $completionHookError"
        }
    }

    if (Test-QuickAdoptionShard -Name 'InstructionGraphClosure') {
        Reset-Mocks
        $graphBuilder = Get-TestQuickAdoptionContractCommand `
            -Name 'New-MeAndAIInstructionGraph'
        $graphValidator = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAIExactInstructionGraph'
        $closureResolver = Get-TestQuickAdoptionContractCommand `
            -Name 'Resolve-MeAndAIInstructionGraphClosure'
        $changeSetValidator = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAICompletedAdoptionChangeSet'
        $targetPathGetter = Get-TestQuickAdoptionContractCommand `
            -Name 'Get-MeAndAIAdoptionTargetPaths'

        $closureRoot = New-TempRoot -Name 'instruction-graph-closure'
        $closureRepository = Join-Path $closureRoot 'consumer'
        New-Item -ItemType Directory -Path $closureRepository -Force |
            Out-Null
        & git init -b main $closureRepository 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to initialize the TEST-0154 committed-tree fixture.'
        }
        Set-TestGitIdentity -Repository $closureRepository
        foreach ($directory in @(
            'docs', 'docs/product', 'docs/custom', 'docs/governance'
        )) {
            New-Item -ItemType Directory `
                -Path (Join-Path $closureRepository $directory) -Force |
                Out-Null
        }
        $sourceFiles = [ordered]@{
            'AGENTS.md' =
                'Required reading: [AI memory](docs/AI_MEMORY.md).'
            'docs/AI_MEMORY.md' =
                'Required reading: [development protocol](DEVELOPMENT_PROTOCOL.md).'
            'docs/DEVELOPMENT_PROTOCOL.md' =
                'Required reading: [project tracker](PROJECT_TRACKER.md).'
            'docs/PROJECT_TRACKER.md' =
                'Required reading: [test catalog](TEST_CATALOG.md).'
            'docs/TEST_CATALOG.md' =
                'Required reading: [AI memory](AI_MEMORY.md).'
            'docs/product/FEATURE_CATALOG.md' =
                '# Consumer-owned product catalog'
            'docs/custom/UNREACHABLE_NOTES.md' =
                '# Protected custom documentation'
            'docs/governance/source.pdf' =
                '%PDF-1.4 representative protected source evidence'
            'docs/governance/source.custom' =
                'Unknown-format protected governance evidence'
            'docs/governance/source' =
                'Extensionless protected governance evidence'
            'docs/governance/UNLINKED.md' =
                'Unlinked compatibility-seed governance text'
        }
        foreach ($sourceFile in $sourceFiles.GetEnumerator()) {
            [IO.File]::WriteAllText(
                (Join-Path $closureRepository ([string]$sourceFile.Key)),
                ([string]$sourceFile.Value + "`n"),
                [Text.UTF8Encoding]::new($false)
            )
        }
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', '.'
        ) | Out-Null
        $symlinkTargetPath = Join-Path $closureRoot 'governance-link-target.txt'
        [IO.File]::WriteAllText(
            $symlinkTargetPath,
            "protected-target`n",
            [Text.UTF8Encoding]::new($false)
        )
        $symlinkBlob = (@(Invoke-TestGit -Repository $closureRepository `
            -Arguments @('hash-object', '-w', '--', $symlinkTargetPath)))[0]
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'update-index', '--add', '--cacheinfo',
            "120000,$symlinkBlob,docs/governance/link.md"
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Create custom instruction authority topology'
        ) | Out-Null
        $sourceHead = (@(Invoke-TestGit -Repository $closureRepository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $protectedPdfBlob = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', "${sourceHead}:docs/governance/source.pdf"
            )))[0]
        $sourceGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $sourceHead `
            -Builder $graphBuilder -Validator $graphValidator
        $expectedSourceSurfaces = @(
            'AGENTS.md',
            'docs/AI_MEMORY.md',
            'docs/DEVELOPMENT_PROTOCOL.md',
            'docs/PROJECT_TRACKER.md',
            'docs/TEST_CATALOG.md',
            'docs/governance/UNLINKED.md',
            'docs/governance/link.md',
            'docs/governance/source',
            'docs/governance/source.custom',
            'docs/governance/source.pdf'
        )
        $protectedPdfNodes = @($sourceGraph.nodes | Where-Object {
            [string]$_.path -ceq 'docs/governance/source.pdf' -and
            [string]$_.mode -ceq '100644' -and
            [string]$_.type -ceq 'blob' -and
            [string]$_.blobSha -ceq $protectedPdfBlob -and
            [string]$_.role -ceq 'UnlinkedKnownSurfaceCandidate'
        })
        $protectedSpecialNodes = @($sourceGraph.nodes | Where-Object {
            [string]$_.path -ceq 'docs/governance/link.md' -and
            [string]$_.mode -ceq '120000' -and
            [string]$_.type -ceq 'blob' -and
            [string]$_.role -ceq 'UnlinkedKnownSurfaceCandidate'
        })
        if ([string]$sourceGraph.baseHead -cne $sourceHead -or
            (@($sourceGraph.protocolSurfaces) -join "`0") -cne
                ($expectedSourceSurfaces -join "`0") -or
            $protectedPdfNodes.Count -ne 1 -or
            $protectedSpecialNodes.Count -ne 1 -or
            @($sourceGraph.nodes.path) -ccontains
                'docs/product/FEATURE_CATALOG.md' -or
            @($sourceGraph.nodes.path) -ccontains
                'docs/custom/UNREACHABLE_NOTES.md') {
            Add-Failure 'TEST-0154 exact source graph did not isolate the four live custom authorities from protected unreachable Markdown.'
        }

        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            "Required reading: [common protocol](.ai/protocol/PROTOCOL.md).`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'update-index', '--add', '--cacheinfo',
            "160000,$sourceHead,.ai/protocol"
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Reconcile only the canonical instruction adapter'
        ) | Out-Null
        $finalHead = (@(Invoke-TestGit -Repository $closureRepository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $finalGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $finalHead `
            -Builder $graphBuilder -Validator $graphValidator
        $canonicalTerminal = @($finalGraph.edges | Where-Object {
            [string]$_.source -ceq 'AGENTS.md' -and
            [string]$_.target -ceq '.ai/protocol/PROTOCOL.md' -and
            [string]$_.reason -ceq 'MarkdownLink'
        })
        if ([string]$finalGraph.baseHead -cne $finalHead -or
            $canonicalTerminal.Count -ne 1 -or
            @($finalGraph.nodes | Where-Object {
                [string]$_.path -ceq '.ai/protocol' -and
                [string]$_.mode -ceq '160000' -and
                [string]$_.type -ceq 'commit'
            }).Count -ne 1) {
            Add-Failure 'TEST-0154 exact final graph did not preserve the canonical AGENTS-to-protocol terminal.'
        }

        $targetPaths = @(& $targetPathGetter)
        $actorChanges = @([pscustomobject]@{
            Status = 'M'
            Path = 'AGENTS.md'
        })
        $blockedClosure = & $closureResolver `
            -SourceGraph $sourceGraph -FinalGraph $finalGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $actorChanges -TargetPaths $targetPaths
        $expectedUnresolved = @(
            'docs/AI_MEMORY.md',
            'docs/DEVELOPMENT_PROTOCOL.md',
            'docs/PROJECT_TRACKER.md',
            'docs/TEST_CATALOG.md'
        )
        $blockedMessage =
            'MEANDAI_ADOPTION_BLOCKED: unresolved instruction authority: ' +
            (@($blockedClosure.UnresolvedPaths) -join ', ')
        $expectedBlockedMessage =
            'MEANDAI_ADOPTION_BLOCKED: unresolved instruction authority: ' +
            ($expectedUnresolved -join ', ')
        if ([string]$blockedClosure.State -cne 'Blocked' -or
            (@($blockedClosure.UnresolvedPaths) -join "`0") -cne
                ($expectedUnresolved -join "`0") -or
            $blockedMessage -cne $expectedBlockedMessage) {
            $sourceEdges = @($sourceGraph.edges | ForEach-Object {
                "$([string]$_.kind):$([string]$_.source)->$([string]$_.target)"
            }) -join '; '
            $sourceNodes = @($sourceGraph.nodes | ForEach-Object {
                "$([string]$_.role):$([string]$_.path)"
            }) -join '; '
            Add-Failure "TEST-0154 AGENTS-only reconciliation did not block with the exact four custom authority paths: state=$([string]$blockedClosure.State); $blockedMessage; diagnostics=$(@($blockedClosure.Diagnostics) -join ' | '); sourceEdges=$sourceEdges; sourceNodes=$sourceNodes; targets=$($targetPaths -join ', ')"
        }

        $readyClosure = & $closureResolver `
            -SourceGraph $finalGraph -FinalGraph $finalGraph `
            -ExpectedAdoptionStrategy 'FullMigration' -Changes @() `
            -TargetPaths $targetPaths
        if ([string]$readyClosure.State -cne 'Ready' -or
            @($readyClosure.UnresolvedPaths).Count -ne 0) {
            Add-Failure 'TEST-0154 canonical AGENTS-to-protocol topology did not satisfy the positive closure control.'
        }

        $authorityClosureRepository = Join-Path $closureRoot `
            'canonical-source-authority'
        New-Item -ItemType Directory -Path $authorityClosureRepository -Force |
            Out-Null
        & git init -b main $authorityClosureRepository 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to initialize the TEST-0154 canonical-source closure fixture.'
        }
        Set-TestGitIdentity -Repository $authorityClosureRepository
        [IO.File]::WriteAllText(
            (Join-Path $authorityClosureRepository 'seed.txt'),
            "protocol-object-seed`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $authorityClosureRepository -Arguments @(
            'add', '--', 'seed.txt'
        ) | Out-Null
        Invoke-TestGit -Repository $authorityClosureRepository -Arguments @(
            'commit', '-m', 'Create protocol object seed'
        ) | Out-Null
        $authorityProtocolCommit = (@(Invoke-TestGit `
            -Repository $authorityClosureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        New-Item -ItemType Directory `
            -Path (Join-Path $authorityClosureRepository 'docs') -Force |
            Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $authorityClosureRepository 'AGENTS.md'),
            "Required reading: [common protocol](.ai/protocol/PROTOCOL.md).`n" +
            "docs/CANONICAL_SOURCE.md is the canonical source.`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $authorityClosureRepository `
                'docs/CANONICAL_SOURCE.md'),
            "Legacy canonical source.`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $authorityClosureRepository -Arguments @(
            'add', '--', 'AGENTS.md', 'docs/CANONICAL_SOURCE.md'
        ) | Out-Null
        Invoke-TestGit -Repository $authorityClosureRepository -Arguments @(
            'update-index', '--add', '--cacheinfo',
            "160000,$authorityProtocolCommit,.ai/protocol"
        ) | Out-Null
        Invoke-TestGit -Repository $authorityClosureRepository -Arguments @(
            'commit', '-m', 'Retain a path-first canonical source authority'
        ) | Out-Null
        $authorityClosureHead = (@(Invoke-TestGit `
            -Repository $authorityClosureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $authorityClosureGraph = Get-TestCommittedInstructionGraph `
            -Repository $authorityClosureRepository `
            -Commit $authorityClosureHead -Builder $graphBuilder `
            -Validator $graphValidator
        $authorityClosureResult = & $closureResolver `
            -SourceGraph $authorityClosureGraph `
            -FinalGraph $authorityClosureGraph `
            -ExpectedAdoptionStrategy 'FullMigration' -Changes @() `
            -TargetPaths $targetPaths
        if (@($authorityClosureGraph.edges | Where-Object {
                [string]$_.target -ceq 'docs/CANONICAL_SOURCE.md' -and
                [string]$_.kind -ceq 'DeclaresAuthority'
            }).Count -ne 1 -or
            [string]$authorityClosureResult.State -cne 'Blocked' -or
            (@($authorityClosureResult.UnresolvedPaths) -join "`0") -cne
                'docs/CANONICAL_SOURCE.md') {
            Add-Failure 'TEST-0154 a path-first canonical source survived FullMigration closure.'
        }

        $scopedAgentPaths = @(
            'services/AGENTS.md',
            'services/api/AGENTS.md'
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $finalHead
        ) | Out-Null
        New-Item -ItemType Directory -Path (
            Join-Path $closureRepository 'services/api'
        ) -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'services/AGENTS.md'),
            @(
                '# Existing shared and project-specific service instructions',
                'Required reading: [common protocol](../.ai/protocol/PROTOCOL.md).'
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'services/api/AGENTS.md'),
            "# Existing project-specific API instructions`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments (
            @('add', '--') + $scopedAgentPaths
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Add nested instruction scopes'
        ) | Out-Null
        $scopedSourceHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $scopedSourceGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $scopedSourceHead `
            -Builder $graphBuilder -Validator $graphValidator
        $scopedSourceRoots = @($scopedSourceGraph.roots | Where-Object {
            [string]$_.kind -ceq 'ScopedAgents' -and
            [string]$_.path -cin $scopedAgentPaths
        })
        $scopedSourceEdges = @($scopedSourceGraph.edges | Where-Object {
            [string]$_.kind -ceq 'Scopes' -and
            [string]$_.target -cin $scopedAgentPaths
        })
        if ($scopedSourceRoots.Count -ne 2 -or
            $scopedSourceEdges.Count -ne 2) {
            Add-Failure 'TEST-0154 nested AGENTS fixture did not form one exact canonical scope chain.'
        }

        $unchangedScopedClosure = & $closureResolver `
            -SourceGraph $scopedSourceGraph -FinalGraph $scopedSourceGraph `
            -ExpectedAdoptionStrategy 'FullMigration' -Changes @() `
            -TargetPaths $targetPaths
        $hybridUnchangedScopedClosure = & $closureResolver `
            -SourceGraph $scopedSourceGraph -FinalGraph $scopedSourceGraph `
            -ExpectedAdoptionStrategy 'HybridReconciliation' `
            -Changes @([pscustomobject]@{
                Status = 'A'
                Path = 'docs/decisions/DEC-0001-scoped-precedence.md'
            }) -TargetPaths $targetPaths
        foreach ($unchangedScopedResult in @(
            $unchangedScopedClosure, $hybridUnchangedScopedClosure
        )) {
            if ([string]$unchangedScopedResult.State -cne 'Ready' -or
                @($unchangedScopedResult.UnresolvedPaths).Count -ne 0) {
                Add-Failure "TEST-0154 canonical consumer-owned nested AGENTS directives were treated as unresolved common authority: state=$([string]$unchangedScopedResult.State); paths=$(@($unchangedScopedResult.UnresolvedPaths) -join ', ')"
            }
        }

        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'services/AGENTS.md'),
            @(
                '# Reconciled project-specific service instructions',
                'Required reading: [common protocol](../.ai/protocol/PROTOCOL.md).'
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'services/AGENTS.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Reconcile parent instruction scope'
        ) | Out-Null
        $scopedPartialHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $scopedPartialGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $scopedPartialHead `
            -Builder $graphBuilder -Validator $graphValidator
        $scopedPartialClosure = & $closureResolver `
            -SourceGraph $scopedSourceGraph -FinalGraph $scopedPartialGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes @([pscustomobject]@{
                Status = 'M'; Path = 'services/AGENTS.md'
            }) -TargetPaths $targetPaths
        if ([string]$scopedPartialClosure.State -cne 'Ready' -or
            @($scopedPartialClosure.UnresolvedPaths).Count -ne 0) {
            Add-Failure "TEST-0154 a preserved project-specific child scope was treated as unresolved while its parent scope was reconciled: state=$([string]$scopedPartialClosure.State); paths=$(@($scopedPartialClosure.UnresolvedPaths) -join ', ')"
        }

        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'services/api/AGENTS.md'),
            "# Reconciled project-specific API instructions`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'services/api/AGENTS.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Reconcile child instruction scope'
        ) | Out-Null
        $scopedReconciledHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $scopedReconciledGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $scopedReconciledHead `
            -Builder $graphBuilder -Validator $graphValidator
        $scopedReconciledChanges = @($scopedAgentPaths | ForEach-Object {
            [pscustomobject]@{ Status = 'M'; Path = [string]$_ }
        })
        $scopedReconciledClosure = & $closureResolver `
            -SourceGraph $scopedSourceGraph -FinalGraph $scopedReconciledGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $scopedReconciledChanges -TargetPaths $targetPaths
        $hybridScopedClosure = & $closureResolver `
            -SourceGraph $scopedSourceGraph -FinalGraph $scopedReconciledGraph `
            -ExpectedAdoptionStrategy 'HybridReconciliation' `
            -Changes (@($scopedReconciledChanges) + @([pscustomobject]@{
                Status = 'A'
                Path = 'docs/decisions/DEC-0001-scoped-precedence.md'
            })) -TargetPaths $targetPaths
        if ([string]$scopedReconciledClosure.State -cne 'Ready' -or
            @($scopedReconciledClosure.UnresolvedPaths).Count -ne 0 -or
            [string]$hybridScopedClosure.State -cne 'Ready' -or
            @($hybridScopedClosure.UnresolvedPaths).Count -ne 0) {
            Add-Failure 'TEST-0154 reconciled nested AGENTS scope chain did not satisfy FullMigration and reviewed Hybrid closure.'
        }
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $scopedSourceHead
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments (
            @('rm', '--') + $scopedAgentPaths
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Retire nested instruction scopes'
        ) | Out-Null
        $scopedRetiredHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $scopedRetiredGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $scopedRetiredHead `
            -Builder $graphBuilder -Validator $graphValidator
        $scopedRetiredChanges = @($scopedAgentPaths | ForEach-Object {
            [pscustomobject]@{ Status = 'D'; Path = [string]$_ }
        })
        foreach ($scopedRetirementStrategy in @('FullMigration', 'CleanStart')) {
            $scopedRetiredClosure = & $closureResolver `
                -SourceGraph $scopedSourceGraph -FinalGraph $scopedRetiredGraph `
                -ExpectedAdoptionStrategy $scopedRetirementStrategy `
                -Changes $scopedRetiredChanges -TargetPaths $targetPaths
            if ([string]$scopedRetiredClosure.State -cne 'Ready' -or
                @($scopedRetiredClosure.UnresolvedPaths).Count -ne 0) {
                Add-Failure "TEST-0154 $scopedRetirementStrategy did not close exact nested AGENTS retirements."
            }
        }

        $newScopedClosure = & $closureResolver `
            -SourceGraph $finalGraph -FinalGraph $scopedSourceGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes @($scopedAgentPaths | ForEach-Object {
                [pscustomobject]@{ Status = 'A'; Path = [string]$_ }
            }) -TargetPaths $targetPaths
        if ([string]$newScopedClosure.State -cne 'Ready' -or
            @($newScopedClosure.UnresolvedPaths).Count -ne 0) {
            Add-Failure 'TEST-0154 an authorized new canonical scoped AGENTS topology was treated as unresolved common authority.'
        }
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $finalHead
        ) | Out-Null

        $finalEntries = @($targetPaths | ForEach-Object {
            [pscustomobject]@{
                Path = [string]$_
                Exists = $true
                Mode = if ([string]$_ -ceq '.ai/protocol') {
                    '160000'
                }
                else { '100644' }
            }
        })
        $completionChanges = @(
            [pscustomobject]@{
                Status = 'D'
                Path = '.ai/adoption/meandai-capabilities.json'
            },
            [pscustomobject]@{
                Status = 'M'
                Path = 'AGENTS.md'
            }
        )
        $validEnvelope = & $changeSetValidator `
            -Changes $completionChanges `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ProtocolSurfaces @($sourceGraph.protocolSurfaces) `
            -TargetPaths $targetPaths -FinalEntries $finalEntries `
            -SourceGraph $sourceGraph
        if (-not $validEnvelope) {
            Add-Failure 'TEST-0154 unchanged completion envelope rejected its valid bounded control before authority-closure evaluation.'
        }
        $adoptionTestPath = 'tests/meandai-adoption/adoption.tests.ps1'
        $adoptionTestEnvelope = & $changeSetValidator `
            -Changes (@($completionChanges) + @([pscustomobject]@{
                Status = 'A'; Path = $adoptionTestPath
            })) `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ProtocolSurfaces @($sourceGraph.protocolSurfaces) `
            -TargetPaths $targetPaths `
            -FinalEntries (@($finalEntries) + @([pscustomobject]@{
                Path = $adoptionTestPath; Exists = $true; Mode = '100644'
            })) `
            -SourceGraph $sourceGraph
        if (-not $adoptionTestEnvelope) {
            Add-Failure 'TEST-0154 source-graph protection rejected an adoption-owned executable test addition.'
        }
        $cleanStartCandidateEnvelope = & $changeSetValidator `
            -Changes (@($completionChanges) + @([pscustomobject]@{
                Status = 'D'; Path = 'docs/governance/UNLINKED.md'
            })) `
            -ExpectedAdoptionStrategy 'CleanStart' `
            -ProtocolSurfaces @($sourceGraph.protocolSurfaces) `
            -TargetPaths $targetPaths -FinalEntries $finalEntries `
            -SourceGraph $sourceGraph
        if (-not $cleanStartCandidateEnvelope) {
            Add-Failure 'TEST-0154 source-graph protection rejected a regular bounded compatibility-candidate deletion under CleanStart.'
        }
        $extensionlessCandidateEnvelope = & $changeSetValidator `
            -Changes (@($completionChanges) + @([pscustomobject]@{
                Status = 'D'; Path = 'docs/governance/source'
            })) `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ProtocolSurfaces @($sourceGraph.protocolSurfaces) `
            -TargetPaths $targetPaths -FinalEntries $finalEntries `
            -SourceGraph $sourceGraph
        if (-not $extensionlessCandidateEnvelope) {
            Add-Failure 'TEST-0154 source-graph protection narrowed the unchanged envelope for an extensionless regular-text compatibility candidate.'
        }
        foreach ($unauthorizedChange in @(
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/product/FEATURE_CATALOG.md'
            },
            [pscustomobject]@{
                Status = 'D'
                Path = 'docs/product/FEATURE_CATALOG.md'
            },
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/AI_MEMORY.md'
            },
            [pscustomobject]@{
                Status = 'D'
                Path = 'docs/AI_MEMORY.md'
            },
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/governance/source.pdf'
            },
            [pscustomobject]@{
                Status = 'D'
                Path = 'docs/governance/source.pdf'
            },
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/governance/source.custom'
            },
            [pscustomobject]@{
                Status = 'D'
                Path = 'docs/governance/source.custom'
            },
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/governance/link.md'
            },
            [pscustomobject]@{
                Status = 'D'
                Path = 'docs/governance/link.md'
            }
        )) {
            $expandedChanges = @($completionChanges) + @($unauthorizedChange)
            $unauthorizedFinalEntries = @($finalEntries)
            if ([string]$unauthorizedChange.Status -cne 'D') {
                $unauthorizedFinalEntries += [pscustomobject]@{
                    Path = [string]$unauthorizedChange.Path
                    Exists = $true
                    Mode = '100644'
                }
            }
            $unexpectedAuthority = & $changeSetValidator `
                -Changes $expandedChanges `
                -ExpectedAdoptionStrategy 'FullMigration' `
                -ProtocolSurfaces @($sourceGraph.protocolSurfaces) `
                -TargetPaths $targetPaths `
                -FinalEntries $unauthorizedFinalEntries `
                -SourceGraph $sourceGraph
            if ($unexpectedAuthority) {
                Add-Failure "TEST-0154 graph discovery granted $([string]$unauthorizedChange.Status) authority to protected path '$([string]$unauthorizedChange.Path)'."
            }
        }

        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            @(
                'Required reading: [common protocol](.ai/protocol/PROTOCOL.md).',
                'Required reading: [shadow authority](docs/custom/SHADOW.md).'
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        [void][IO.Directory]::CreateDirectory(
            (Join-Path $closureRepository '.ai')
        )
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'docs/custom/SHADOW.md'),
            "# Newly introduced live shadow authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md', 'docs/custom/SHADOW.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Introduce a new root-reachable shadow authority'
        ) | Out-Null
        $shadowHead = (@(Invoke-TestGit -Repository $closureRepository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $shadowGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $shadowHead `
            -Builder $graphBuilder -Validator $graphValidator
        $shadowAuthorityEdge = @($shadowGraph.edges | Where-Object {
            [string]$_.source -ceq 'AGENTS.md' -and
            [string]$_.target -ceq 'docs/custom/SHADOW.md' -and
            [string]$_.kind -ceq 'RequiresRead'
        })
        if ($shadowAuthorityEdge.Count -ne 1) {
            Add-Failure 'TEST-0154 shadow-authority fixture did not create one exact root-reachable RequiresRead edge.'
        }
        $shadowClosure = & $closureResolver `
            -SourceGraph $finalGraph -FinalGraph $shadowGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $actorChanges -TargetPaths $targetPaths
        if ([string]$shadowClosure.State -cne 'Blocked' -or
            (@($shadowClosure.UnresolvedPaths) -join "`0") -cne
                'docs/custom/SHADOW.md') {
            Add-Failure "TEST-0154 newly introduced root-reachable RequiresRead authority was not blocked with exact path 'docs/custom/SHADOW.md': state=$([string]$shadowClosure.State); paths=$(@($shadowClosure.UnresolvedPaths) -join ', ')"
        }

        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $finalHead
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            @(
                'Required reading: [common protocol](.ai/protocol/PROTOCOL.md).',
                'Required reading: [prefix collision](.ai/protocol-shadow.md).'
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository '.ai/protocol-shadow.md'),
            "# Noncanonical prefix-collision authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md', '.ai/protocol-shadow.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Introduce protocol-prefix collision authority'
        ) | Out-Null
        $prefixCollisionHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $prefixCollisionGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $prefixCollisionHead `
            -Builder $graphBuilder -Validator $graphValidator
        $prefixCollisionClosure = & $closureResolver `
            -SourceGraph $finalGraph -FinalGraph $prefixCollisionGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $actorChanges -TargetPaths $targetPaths
        if ([string]$prefixCollisionClosure.State -cne 'Blocked' -or
            (@($prefixCollisionClosure.UnresolvedPaths) -join "`0") -cne
                '.ai/protocol-shadow.md') {
            Add-Failure 'TEST-0154 final protocol-prefix collision authority escaped exact namespace closure.'
        }
        $sourcePrefixClosure = & $closureResolver `
            -SourceGraph $prefixCollisionGraph -FinalGraph $finalGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $actorChanges -TargetPaths $targetPaths
        if ([string]$sourcePrefixClosure.State -cne 'Blocked' -or
            (@($sourcePrefixClosure.UnresolvedPaths) -join "`0") -cne
                '.ai/protocol-shadow.md') {
            Add-Failure 'TEST-0154 source protocol-prefix collision authority escaped exact namespace closure.'
        }

        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $finalHead
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            'Required reading: [bogus protocol](.ai/protocol/DOES-NOT-EXIST.md).',
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Point adapter at a bogus protocol descendant'
        ) | Out-Null
        $bogusProtocolHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @('rev-parse', 'HEAD')))[0]
        $bogusProtocolError = ''
        try {
            Get-TestCommittedInstructionGraph `
                -Repository $closureRepository -Commit $bogusProtocolHead `
                -Builder $graphBuilder -Validator $graphValidator | Out-Null
        }
        catch { $bogusProtocolError = $_.Exception.Message }
        if ($bogusProtocolError -notlike
                '*not a canonical protocol authority*') {
            Add-Failure 'TEST-0154 bogus reserved-protocol descendant did not fail closed during final graph discovery.'
        }

        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $finalHead
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            @(
                'Required reading: [common protocol](.ai/protocol/PROTOCOL.md).',
                'Required reading: [legacy instructions](CLAUDE.md).'
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'CLAUDE.md'),
            "# Retirable legacy common authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md', 'CLAUDE.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Create deletable legacy common authority'
        ) | Out-Null
        $legacyDeleteSourceHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $legacyDeleteSourceGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $legacyDeleteSourceHead `
            -Builder $graphBuilder -Validator $graphValidator
        $legacyDeleteSourceEdge = @($legacyDeleteSourceGraph.edges |
            Where-Object {
                [string]$_.source -ceq 'AGENTS.md' -and
                [string]$_.target -ceq 'CLAUDE.md' -and
                [string]$_.kind -ceq 'RequiresRead'
            })
        [IO.File]::Delete((Join-Path $closureRepository 'CLAUDE.md'))
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            "Required reading: [common protocol](.ai/protocol/PROTOCOL.md).`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '-A', '--', 'AGENTS.md', 'CLAUDE.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Retire legacy common authority by deletion'
        ) | Out-Null
        $legacyDeleteFinalHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $legacyDeleteFinalGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $legacyDeleteFinalHead `
            -Builder $graphBuilder -Validator $graphValidator
        $legacyDeleteActorChanges = @(
            [pscustomobject]@{ Status = 'M'; Path = 'AGENTS.md' },
            [pscustomobject]@{ Status = 'D'; Path = 'CLAUDE.md' }
        )
        $legacyDeleteClosure = & $closureResolver `
            -SourceGraph $legacyDeleteSourceGraph `
            -FinalGraph $legacyDeleteFinalGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $legacyDeleteActorChanges -TargetPaths $targetPaths
        $legacyDeleteEnvelopeChanges = @($completionChanges) + @(
            [pscustomobject]@{ Status = 'D'; Path = 'CLAUDE.md' }
        )
        $legacyDeleteEnvelope = & $changeSetValidator `
            -Changes $legacyDeleteEnvelopeChanges `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ProtocolSurfaces @($legacyDeleteSourceGraph.protocolSurfaces) `
            -TargetPaths $targetPaths -FinalEntries $finalEntries `
            -SourceGraph $legacyDeleteSourceGraph
        if ([string]$legacyDeleteClosure.State -cne 'Ready' -or
            @($legacyDeleteClosure.UnresolvedPaths).Count -ne 0 -or
            -not $legacyDeleteEnvelope -or
            $legacyDeleteSourceEdge.Count -ne 1 -or
            @($legacyDeleteFinalGraph.nodes.path) -ccontains 'CLAUDE.md') {
            Add-Failure 'TEST-0154 exact current-envelope deletion and edge retirement did not satisfy the legacy-authority closure control.'
        }

        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $legacyDeleteSourceHead
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            "Required reading: [common protocol](.ai/protocol/PROTOCOL.md).`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'CLAUDE.md'),
            "# Modified but still-live generic instruction root`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md', 'CLAUDE.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Retain modified generic legacy authority'
        ) | Out-Null
        $legacyRootFinalHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $legacyRootFinalGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $legacyRootFinalHead `
            -Builder $graphBuilder -Validator $graphValidator
        $legacyRootActorChanges = @(
            [pscustomobject]@{ Status = 'M'; Path = 'AGENTS.md' },
            [pscustomobject]@{ Status = 'M'; Path = 'CLAUDE.md' }
        )
        $legacyRootClosure = & $closureResolver `
            -SourceGraph $legacyDeleteSourceGraph `
            -FinalGraph $legacyRootFinalGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $legacyRootActorChanges -TargetPaths $targetPaths
        $retainedGenericRoot = @($legacyRootFinalGraph.roots |
            Where-Object {
                [string]$_.path -ceq 'CLAUDE.md' -and
                [string]$_.kind -ceq 'GenericInstructionRoot'
            })
        if ([string]$legacyRootClosure.State -cne 'Blocked' -or
            (@($legacyRootClosure.UnresolvedPaths) -join "`0") -cne
                'CLAUDE.md' -or
            $retainedGenericRoot.Count -ne 1) {
            Add-Failure "TEST-0154 modified but retained GenericInstructionRoot was not blocked with exact path 'CLAUDE.md': state=$([string]$legacyRootClosure.State); paths=$(@($legacyRootClosure.UnresolvedPaths) -join ', ')"
        }
        $hybridRootActorChanges = @($legacyRootActorChanges) + @(
            [pscustomobject]@{
                Status = 'A'
                Path = 'docs/decisions/DEC-0001-hybrid-precedence.md'
            }
        )
        $hybridRootClosure = & $closureResolver `
            -SourceGraph $legacyDeleteSourceGraph `
            -FinalGraph $legacyRootFinalGraph `
            -ExpectedAdoptionStrategy 'HybridReconciliation' `
            -Changes $hybridRootActorChanges -TargetPaths $targetPaths
        if ([string]$hybridRootClosure.State -cne 'Ready' -or
            @($hybridRootClosure.UnresolvedPaths).Count -ne 0) {
            Add-Failure "TEST-0154 reviewed HybridReconciliation did not retain a modified pre-existing GenericInstructionRoot: state=$([string]$hybridRootClosure.State); paths=$(@($hybridRootClosure.UnresolvedPaths) -join ', ')"
        }

        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'switch', '--detach', $finalHead
        ) | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            @(
                'Required reading: [common protocol](.ai/protocol/PROTOCOL.md).',
                'Required reading: [legacy governance](docs/governance/LEGACY.md).'
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        New-Item -ItemType Directory -Path (
            Join-Path $closureRepository 'docs/governance'
        ) -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'docs/governance/LEGACY.md'),
            "# Live legacy governance authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md', 'docs/governance/LEGACY.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Create modifiable legacy governance authority'
        ) | Out-Null
        $legacyModifySourceHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $legacyModifySourceGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $legacyModifySourceHead `
            -Builder $graphBuilder -Validator $graphValidator
        $legacyModifySourceEdge = @($legacyModifySourceGraph.edges |
            Where-Object {
                [string]$_.source -ceq 'AGENTS.md' -and
                [string]$_.target -ceq 'docs/governance/LEGACY.md' -and
                [string]$_.kind -ceq 'RequiresRead'
            })
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'AGENTS.md'),
            "Required reading: [common protocol](.ai/protocol/PROTOCOL.md).`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $closureRepository 'docs/governance/LEGACY.md'),
            "# Retained historical governance evidence`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'add', '--', 'AGENTS.md', 'docs/governance/LEGACY.md'
        ) | Out-Null
        Invoke-TestGit -Repository $closureRepository -Arguments @(
            'commit', '-m', 'Retire legacy governance edge by modification'
        ) | Out-Null
        $legacyModifyFinalHead = (@(Invoke-TestGit `
            -Repository $closureRepository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $legacyModifyFinalGraph = Get-TestCommittedInstructionGraph `
            -Repository $closureRepository -Commit $legacyModifyFinalHead `
            -Builder $graphBuilder -Validator $graphValidator
        $legacyModifyActorChanges = @(
            [pscustomobject]@{ Status = 'M'; Path = 'AGENTS.md' },
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/governance/LEGACY.md'
            }
        )
        $legacyModifyClosure = & $closureResolver `
            -SourceGraph $legacyModifySourceGraph `
            -FinalGraph $legacyModifyFinalGraph `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -Changes $legacyModifyActorChanges -TargetPaths $targetPaths
        $legacyModifyEnvelopeChanges = @($completionChanges) + @(
            [pscustomobject]@{
                Status = 'M'
                Path = 'docs/governance/LEGACY.md'
            }
        )
        $legacyModifyFinalEntries = @($finalEntries) + @(
            [pscustomobject]@{
                Path = 'docs/governance/LEGACY.md'
                Exists = $true
                Mode = '100644'
            }
        )
        $legacyModifyEnvelope = & $changeSetValidator `
            -Changes $legacyModifyEnvelopeChanges `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ProtocolSurfaces @($legacyModifySourceGraph.protocolSurfaces) `
            -TargetPaths $targetPaths `
            -FinalEntries $legacyModifyFinalEntries `
            -SourceGraph $legacyModifySourceGraph
        $retainedLegacyNode = @($legacyModifyFinalGraph.nodes |
            Where-Object {
                [string]$_.path -ceq 'docs/governance/LEGACY.md' -and
                [string]$_.role -ceq 'UnlinkedKnownSurfaceCandidate'
            })
        $retiredLegacyEdge = @($legacyModifyFinalGraph.edges |
            Where-Object {
                [string]$_.target -ceq 'docs/governance/LEGACY.md'
            })
        if ([string]$legacyModifyClosure.State -cne 'Ready' -or
            @($legacyModifyClosure.UnresolvedPaths).Count -ne 0 -or
            -not $legacyModifyEnvelope -or
            $legacyModifySourceEdge.Count -ne 1 -or
            $retainedLegacyNode.Count -ne 1 -or
            $retiredLegacyEdge.Count -ne 0) {
            Add-Failure 'TEST-0154 exact current-envelope modification plus edge retirement did not satisfy the retained-evidence closure control.'
        }

        $graphRecordConverter = Get-TestQuickAdoptionContractCommand `
            -Name 'ConvertTo-MeAndAIInstructionGraphRecord'
        $graphIdentityGetter = Get-TestQuickAdoptionContractCommand `
            -Name 'Get-MeAndAIInstructionGraphIdentity'
        $markerValidator = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAIExactAdoptionPullRequestMarker'
        $sourceGraphRecord = & $graphRecordConverter -Graph $sourceGraph
        $sourceGraphIdentity = & $graphIdentityGetter -Graph $sourceGraph
        $graphAwareBranch = 'automation/meandai-capabilities-v0.12.7'
        $graphAwareState = 'AdoptionReviewRequired'
        $graphAwareRepository = 'test-owner/consumer'
        $graphAwareMarkerRecord = [ordered]@{
            schema = 7
            phase = 'Proposed'
            state = $graphAwareState
            target = 'v0.12.7'
            protocolSha = $global:QuickAdoptionProtocolSha
            head = $finalHead
            branch = $graphAwareBranch
            adoptionStrategy = 'FullMigration'
            protocolSurfaces = @($sourceGraph.protocolSurfaces)
            protocolRecordLossAcknowledged = $false
            graphBase = [string]$sourceGraphIdentity.graphBase
            graphDigest = [string]$sourceGraphIdentity.graphDigest
            graphCounts = $sourceGraphIdentity.graphCounts
            graphLimits = $sourceGraphIdentity.graphLimits
            repository = $graphAwareRepository
            actor = 'test-owner'
        }
        $graphAwareMarkerJson = $graphAwareMarkerRecord |
            ConvertTo-Json -Depth 20 -Compress
        $graphAwarePullRequest = [pscustomobject][ordered]@{
            number = 42
            url = 'https://github.com/test-owner/consumer/pull/42'
            headRefName = $graphAwareBranch
            headRefOid = $finalHead
            baseRefName = 'main'
            headRepository = [pscustomobject]@{
                nameWithOwner = $graphAwareRepository
            }
            author = [pscustomobject]@{ login = 'test-owner' }
            body =
                "<!-- meandai-capabilities-adoption:$graphAwareMarkerJson -->"
            isDraft = $true
            state = 'OPEN'
            meAndAIMarker = [pscustomobject]$graphAwareMarkerRecord
        }
        $graphAwareMarkerValid = & $markerValidator `
            -PullRequest $graphAwarePullRequest -RemoteHead $finalHead `
            -Repository $graphAwareRepository -Branch $graphAwareBranch `
            -BaseBranch 'main' -TargetTag 'v0.12.7' `
            -TargetSha $global:QuickAdoptionProtocolSha `
            -ExpectedActor 'test-owner' -ExpectedState $graphAwareState `
            -ExpectedAdoptionStrategy 'FullMigration' `
            -ExpectedProtocolSurfaces @($sourceGraph.protocolSurfaces) `
            -ExpectedProtocolRecordLossAcknowledgement $false `
            -ExpectedSourceGraph $sourceGraph `
            -ExpectedSourceGraphIdentity $sourceGraphIdentity `
            -ExpectedPhase 'Proposed'
        if (-not $graphAwareMarkerValid) {
            Add-Failure 'TEST-0154 graph-aware local-completion regression fixture did not start from one exact schema-7 source-graph marker.'
        }

        $graphAwareManifest = [pscustomobject][ordered]@{
            schema = 3
            operation = 'ai-capabilities-adoption'
            state = $graphAwareState
            repository = $graphAwareRepository
            targetTag = 'v0.12.7'
            protocolSha = $global:QuickAdoptionProtocolSha
            adoptionStrategy = 'FullMigration'
            protocolSurfaces = @($sourceGraph.protocolSurfaces)
            protocolRecordLossAcknowledged = $false
            collisions = @('AGENTS.md')
            proposedPaths = @($canonicalAdoptionProposedPaths)
            requiredTasks = @($canonicalAdoptionRequiredTasks)
            sourceGraph = $sourceGraphRecord
        }
        $graphAwareManifestPath = Join-Path $closureRoot `
            'graph-aware-manifest.json'
        [IO.File]::WriteAllText(
            $graphAwareManifestPath,
            ($graphAwareManifest | ConvertTo-Json -Depth 100 -Compress),
            [Text.UTF8Encoding]::new($false)
        )
        $completionSource = [IO.File]::ReadAllText((Join-Path $root `
            'scripts/quick-adoption/Private/CompletionAndPublication.ps1'))
        $completionTokens = $null
        $completionParseErrors = $null
        $completionAst =
            [Management.Automation.Language.Parser]::ParseInput(
                $completionSource,
                [ref]$completionTokens,
                [ref]$completionParseErrors
            )
        $manifestValidationFunctions = @($completionAst.FindAll({
            param($node)
            $node -is
                [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Get-ValidatedAdoptionManifest'
        }, $true))
        if (@($completionParseErrors).Count -ne 0 -or
            $manifestValidationFunctions.Count -ne 1) {
            Add-Failure 'TEST-0154 local completion does not expose one parseable Get-ValidatedAdoptionManifest boundary.'
        }
        else {
            $manifestValidationModule = $null
            $manifestValidationError = ''
            $manifestValidationResult = $null
            $testHarnessInvokeGit = ${function:Invoke-Git}
            try {
                $manifestValidationModule = New-Module `
                    -Name "MeAndAIGraphManifest$([guid]::NewGuid().ToString('N'))" `
                    -ArgumentList @(
                        $manifestValidationFunctions[0].Extent.Text,
                        $sourceGraph,
                        @('AGENTS.md'),
                        $sourceHead,
                        $workflowRelativePath
                    ) `
                    -ScriptBlock {
                        param(
                            [string]$FunctionDefinition,
                            $ExactSourceGraph,
                            [object[]]$LegacyProtocolSurfaces,
                            [string]$StructuralBaseHead,
                            [string]$WorkflowPath
                        )
                        $script:ProtocolTag = 'v0.12.7'
                        $script:workflowTargetPath = $WorkflowPath
                        $script:workflowBytes =
                            [Text.UTF8Encoding]::new($false).GetBytes(
                                "name: meAndAI AI capabilities lifecycle`n"
                            )
                        $script:ExactSourceGraph = $ExactSourceGraph
                        $script:LegacyProtocolSurfaces =
                            @($LegacyProtocolSurfaces)
                        $script:StructuralBaseHead = $StructuralBaseHead
                        $script:ProposalAssertionReached = $false
                        $script:GraphAcquisitionCount = 0

                        function Get-ExpectedAdoptionManifestContract {
                            param(
                                [string]$Repository,
                                [string]$ProposalHead,
                                [string[]]$TargetPaths
                            )
                            return [pscustomobject]@{
                                BaseHead = $script:StructuralBaseHead
                                BasePaths = @('AGENTS.md')
                                LocalUpdaterState = 'Absent'
                                Collisions = @('AGENTS.md')
                                ProtocolSurfaces =
                                    @($script:LegacyProtocolSurfaces)
                            }
                        }

                        function Get-GitBlobSha {
                            param([byte[]]$Bytes)
                            return 'f' * 40
                        }

                        function Get-AdoptionTreeEntry {
                            param(
                                [string]$Repository,
                                [string]$Commit,
                                [string]$Path
                            )
                            return [pscustomobject]@{
                                Path = $script:workflowTargetPath
                                Mode = '100644'
                                Type = 'blob'
                                Sha = 'f' * 40
                            }
                        }

                        function Get-QuickAdoptionInstructionGraph {
                            param([string]$Repository, [string]$Commit)
                            $script:GraphAcquisitionCount++
                            if ($Commit -cne
                                [string]$script:ExactSourceGraph.baseHead) {
                                throw 'Graph-aware manifest validation requested an unexpected commit.'
                            }
                            return $script:ExactSourceGraph
                        }

                        function Get-InitialAdoptionPolicyCommand {
                            param([string]$Name)
                            $commands = @(Get-Command -Name $Name `
                                -CommandType Function `
                                -ErrorAction SilentlyContinue | Where-Object {
                                    [string]$_.ModuleName -ceq
                                        'MeAndAI.CapabilitiesBootstrap'
                                })
                            if ($commands.Count -ne 1) {
                                throw "Expected one imported policy command '$Name'."
                            }
                            return $commands[0]
                        }

                        function Get-SingleCommitParent {
                            throw 'Graph-aware manifest validation unexpectedly requested a seed-parent fallback.'
                        }

                        function Invoke-Git {
                            throw 'Graph-aware manifest validation unexpectedly requested a seed diff fallback.'
                        }

                        function Assert-ExactAdoptionProposal {
                            param(
                                [string]$Repository,
                                [string]$ProposalHead,
                                [string]$CanonicalBaseHead,
                                [string]$ProposalMode,
                                [object[]]$TargetPaths,
                                [string]$ProtocolSource,
                                [string]$ProtocolSha
                            )
                            if ($ProposalMode -cne 'ManifestOnly') {
                                throw "Unexpected proposal mode '$ProposalMode'."
                            }
                            $script:ProposalAssertionReached = $true
                        }

                        Invoke-Expression $FunctionDefinition
                    }
                $manifestValidationResult = & $manifestValidationModule {
                    param(
                        [string]$Path,
                        [string]$ProtocolSource,
                        $PullRequest,
                        [string]$ProposalHead,
                        [string]$CanonicalBaseHead
                    )
                    $validatedManifest = Get-ValidatedAdoptionManifest `
                        -ManifestPath $Path `
                        -Repository 'test-owner/consumer' `
                        -PullRequest $PullRequest `
                        -ProtocolSource $ProtocolSource `
                        -ProposalRepository 'fixture-consumer' `
                        -ProposalHead $ProposalHead `
                        -CanonicalBaseHead $CanonicalBaseHead
                    return [pscustomobject]@{
                        Manifest = $validatedManifest
                        ProposalAssertionReached =
                            $script:ProposalAssertionReached
                        GraphAcquisitionCount =
                            $script:GraphAcquisitionCount
                        LegacyProtocolSurfaces =
                            @($script:LegacyProtocolSurfaces)
                    }
                } $graphAwareManifestPath `
                    $global:QuickAdoptionProtocolRepository `
                    $graphAwarePullRequest $finalHead $sourceHead
            }
            catch {
                $manifestValidationError = $_.Exception.Message
            }
            finally {
                if ($null -ne $manifestValidationModule) {
                    Remove-Module -ModuleInfo $manifestValidationModule `
                        -Force -ErrorAction SilentlyContinue
                }
                # Windows PowerShell 5.1 can project a same-named function from
                # an invoked dynamic module into the caller's function drive.
                # Restore the test harness wrapper before later All-shard
                # real-Git variants run.
                Set-Item -LiteralPath 'Function:\Invoke-Git' `
                    -Value $testHarnessInvokeGit -Force
            }
            if ($manifestValidationError -or
                $null -eq $manifestValidationResult -or
                -not [bool]$manifestValidationResult.ProposalAssertionReached -or
                [int]$manifestValidationResult.GraphAcquisitionCount -ne 1 -or
                [long]$manifestValidationResult.Manifest.schema -ne 3 -or
                (@($manifestValidationResult.Manifest.protocolSurfaces) `
                    -join "`0") -cne
                    (@($sourceGraph.protocolSurfaces) -join "`0") -or
                (@($manifestValidationResult.LegacyProtocolSurfaces) `
                    -join "`0") -cne 'AGENTS.md') {
                Add-Failure "TEST-0154 graph-aware local manifest/lifecycle validation rejected the exact sourceGraph projection before completion closure: $manifestValidationError"
            }
            else {
                if ($null -ne $script:QuickAdoptionContractModule) {
                    Remove-Module `
                        -ModuleInfo $script:QuickAdoptionContractModule `
                        -Force -ErrorAction SilentlyContinue
                    $script:QuickAdoptionContractModule = $null
                }
                $postValidationClosureResolver =
                    Get-TestQuickAdoptionContractCommand `
                        -Name 'Resolve-MeAndAIInstructionGraphClosure'
                $postValidationClosure = & $postValidationClosureResolver `
                    -SourceGraph $sourceGraph -FinalGraph $finalGraph `
                    -ExpectedAdoptionStrategy 'FullMigration' `
                    -Changes $actorChanges -TargetPaths $targetPaths
                if ([string]$postValidationClosure.State -cne 'Blocked' -or
                    (@($postValidationClosure.UnresolvedPaths) -join "`0") `
                        -cne ($expectedUnresolved -join "`0")) {
                    Add-Failure 'TEST-0154 graph-aware local completion did not reach exact instruction-authority closure after manifest validation.'
                }
            }
        }
        Reset-Mocks
        $liveAuthorityConsumer = New-MockConnectedSeedConsumer `
            -Name 'instruction-closure-live-authority'
        $liveAuthorityPaths = @(
            'docs/AI_MEMORY.md',
            'docs/DEVELOPMENT_PROTOCOL.md',
            'docs/PROJECT_TRACKER.md',
            'docs/TEST_CATALOG.md'
        )
        [IO.File]::WriteAllText(
            (Join-Path $liveAuthorityConsumer.Repository 'AGENTS.md'),
            @(
                '# Consumer instruction root',
                '',
                'Required reading:',
                '- [AI memory](docs/AI_MEMORY.md)',
                '- [development protocol](docs/DEVELOPMENT_PROTOCOL.md)',
                '- [project tracker](docs/PROJECT_TRACKER.md)',
                '- [test catalog](docs/TEST_CATALOG.md)',
                ''
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        foreach ($liveAuthorityPath in $liveAuthorityPaths) {
            $liveAuthorityTarget = Join-Path `
                $liveAuthorityConsumer.Repository $liveAuthorityPath
            New-Item -ItemType Directory -Path (
                Split-Path -Parent $liveAuthorityTarget
            ) -Force | Out-Null
            [IO.File]::WriteAllText(
                $liveAuthorityTarget,
                "# Active consumer authority: $liveAuthorityPath`n",
                [Text.UTF8Encoding]::new($false)
            )
        }
        Invoke-TestGit -Repository $liveAuthorityConsumer.Repository `
            -Arguments (@('add', '--', 'AGENTS.md') + $liveAuthorityPaths) |
            Out-Null
        Invoke-TestGit -Repository $liveAuthorityConsumer.Repository `
            -Arguments @(
                'commit', '-m',
                'Create custom instruction graph for closure regression'
            ) | Out-Null
        Invoke-TestGit -Repository $liveAuthorityConsumer.Repository `
            -Arguments @('push', 'origin', 'main') | Out-Null
        $liveAuthorityMainHead = (@(Invoke-TestGit `
            -Repository $liveAuthorityConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $global:QuickAdoptionProposalMode = 'ManifestOnly'
        $env:MEANDAI_TEST_CODEX_MODE = 'ReconcileCanonicalAgentsOnly'
        $liveAuthorityError = ''
        try {
            & $launcherPath `
                -TargetPath $liveAuthorityConsumer.Repository `
                -AdoptionStrategy FullMigration -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch { $liveAuthorityError = $_.Exception.Message }
        finally { $env:MEANDAI_TEST_CODEX_MODE = 'Success' }
        $liveAuthorityBranch =
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        $liveAuthorityBranchLines = @(Invoke-TestGit `
            -Repository $liveAuthorityConsumer.Repository -Arguments @(
                'ls-remote', '--heads', 'origin', $liveAuthorityBranch
            ))
        $liveAuthorityBranchHead = if (
            $liveAuthorityBranchLines.Count -eq 1
        ) {
            ([string]$liveAuthorityBranchLines[0]).Split("`t")[0]
        }
        else { '' }
        $liveAuthorityProposalPaths = if ($liveAuthorityBranchHead) {
            @(Invoke-TestGit -Repository $liveAuthorityConsumer.Remote `
                -Arguments @('ls-tree', '-r', '--name-only',
                    $liveAuthorityBranch))
        }
        else { @() }
        $liveAuthorityMainAfter = (@(Invoke-TestGit `
            -Repository $liveAuthorityConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $expectedLiveAuthorityError =
            'MEANDAI_ADOPTION_BLOCKED: unresolved instruction authority: ' +
            ($liveAuthorityPaths -join ', ')
        if ($liveAuthorityError -cne $expectedLiveAuthorityError -or
            $liveAuthorityBranchLines.Count -ne 1 -or
            $liveAuthorityBranchHead -cne
                [string]$global:QuickAdoptionPrHead -or
            $liveAuthorityMainAfter -cne $liveAuthorityMainHead -or
            $global:QuickAdoptionPrReadyCalls -ne 0 -or
            $global:QuickAdoptionPrBodyEditCalls -ne 0 -or
            -not $global:QuickAdoptionPrBody.Contains(
                '"phase":"Proposed"'
            ) -or
            $liveAuthorityProposalPaths -notcontains
                '.ai/adoption/meandai-capabilities.json' -or
            $liveAuthorityProposalPaths -contains
                'docs/governance/ai-adoption.md' -or
            @($liveAuthorityPaths | Where-Object {
                $liveAuthorityProposalPaths -notcontains $_
            }).Count -ne 0) {
            Add-Failure "TEST-0154 actual local completion did not block the exact four live custom authorities before marker, push, or readiness mutation: $liveAuthorityError"
        }

        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0154'
    }

    $integrityShardNames = @(
        'IntegrityCompletedGraph',
        'IntegrityManifestIssue',
        'IntegrityCodexFailure',
        'IntegrityMetadataCredential'
    )
    $runIntegrityShards = (
        ($Shard -cin @('All', 'WindowsNative') -or
         $integrityShardNames -ccontains $Shard) -and
        $failures.Count -eq 0
    )
    # Every integrity run owns a fresh completed-adoption context. In the All
    # shard, AdoptionLifecycle deliberately finishes on other consumer
    # fixtures, so reusing its local repository variables would pair them with
    # stale global GitHub metadata.
    if ($runIntegrityShards) {
        Reset-Mocks
        $integrityBaseline = New-MockCompletedAdoptionConsumer `
            -Name 'integrity-baseline'
        $policyModulesAfterSuccessfulAdoption = @(
            Get-TestLoadedInitialAdoptionPolicyModules
        )
        if ($policyModulesAfterSuccessfulAdoption.Count -ne 0) {
            Add-Failure "TEST-0130 successful adoption leaked dynamic initial-policy modules: $($policyModulesAfterSuccessfulAdoption.Name -join ', ')"
        }
        $existingRepo = $integrityBaseline.Repository
        $existingRemote = $integrityBaseline.Remote
        $postReadyRecoveredHead = $integrityBaseline.CompletedHead
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityCompletedGraph')) {
        $completedBranch = 'automation/meandai-capabilities-v0.12.7'
        $canonicalCompletedHead = $postReadyRecoveredHead
        $canonicalCompletedBody = [string]$global:QuickAdoptionPrBody
        # Credential, protected-workflow, and manifest policy combinations are
        # owned by the production completion-contract table in the bootstrap
        # suite. UpdaterModule is the representative immutable updater-asset
        # byte slice for both updater assets.
        $completedVariantEvidence = [ordered]@{
            Parent = 'RealGitGraph'
            ProposalTree = 'RealGitGraph'
            CheckedChangeSet = 'RealGitDiffCheck'
            Credential = 'ProductionCompletionContract'
            ProtectedWorkflow = 'ProductionCompletionContract'
            Protocol = 'RealProtocolGitlink'
            UpdaterModule = 'RealImmutableUpdaterAsset'
            UpdaterAdapter = 'RepresentativeImmutableUpdaterAsset'
            Manifest = 'ProductionCompletionContract'
        }
        $realCompletedVariants = @(
            $completedVariantEvidence.GetEnumerator() | Where-Object {
                [string]$_.Value -like 'Real*'
            } | ForEach-Object { [string]$_.Key }
        )
        foreach ($completedVariant in $realCompletedVariants) {
            $variantRoot = New-TempRoot `
                -Name "quick-completed-$($completedVariant.ToLowerInvariant())"
            $variantClone = Join-Path $variantRoot 'clone'
            Invoke-Git -Repository $variantRoot -Arguments @(
                'clone', $existingRemote, $variantClone
            ) | Out-Null
            Set-TestGitIdentity -Repository $variantClone
            Invoke-Git -Repository $variantClone -Arguments @(
                'switch', $completedBranch
            ) | Out-Null
            $proposalHead = (@(Invoke-Git -Repository $variantClone -Arguments @(
                'rev-parse', "$canonicalCompletedHead^"
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
                            'rev-parse', "$canonicalCompletedHead`^{tree}"
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
                        (Join-Path $variantClone $workflowRelativePath),
                        "name: protected workflow drift`n"
                    )
                    Invoke-Git -Repository $variantClone -Arguments @(
                        'add', '--', $workflowRelativePath
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
                target = 'v0.12.7'
                protocolSha = $global:QuickAdoptionProtocolSha
                head = $variantHead
                repository = 'test-owner/consumer'
                actor = 'test-owner'
            } | ConvertTo-Json -Compress
            $global:QuickAdoptionPrHead = $variantHead
            $global:QuickAdoptionPrBody = "<!-- meandai-capabilities-adoption:$variantMarker -->`n`nMock completed proposal."
            $global:QuickAdoptionPrDraft = $true
            $global:QuickAdoptionPrListCalls = 0
            $readyCallsBeforeVariant = $global:QuickAdoptionPrReadyCalls
            $codexCallsBeforeVariant = @(Get-MockCodexCalls).Count
            $variantBlocked = $false
            try {
                & $launcherPath -TargetPath $existingRepo `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $variantBlocked = $true
            }
            $remoteAfterVariant = (@(Invoke-Git -Repository $existingRepo -Arguments @(
                'ls-remote', '--heads', 'origin', "refs/heads/$completedBranch"
            )))[0].Split("`t")[0]
            if (-not $variantBlocked -or
                $global:QuickAdoptionPrReadyCalls -ne $readyCallsBeforeVariant -or
                @(Get-MockCodexCalls).Count -ne $codexCallsBeforeVariant -or
                $remoteAfterVariant -cne $variantHead) {
                Add-Failure "TEST-0087 launcher trusted drifted Completed variant '$completedVariant'."
            }
            Invoke-Git -Repository $variantClone -Arguments @(
                'push', '--force', 'origin',
                "$canonicalCompletedHead`:refs/heads/$completedBranch"
            ) | Out-Null
            $global:QuickAdoptionPrHead = $canonicalCompletedHead
            $global:QuickAdoptionPrBody = $canonicalCompletedBody
            $global:QuickAdoptionPrDraft = $false
        }
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityManifestIssue')) {
        $canonicalIssueMarker = '<!-- meandai-local-adoption:v0.12.7:pr-42 -->'
        $manifestContractModes = @(
            'AdditionalProperty', 'MissingProperty', 'WrongRequiredTasks',
            'WrongProposedPaths', 'WrongCollisions', 'WrongRepository',
            'WrongTargetTag', 'WrongProtocolSha', 'WrongState',
            'WrongOperation', 'WrongSchema', 'WrongSchemaType',
            'WrongCollisionType', 'ArrayRoot'
        )
        $manifestValidator = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAIExactAdoptionManifest'
        $validManifest = New-TestQuickAdoptionManifest -Mode 'Valid' `
            -Repository 'test-owner/consumer' -State 'BootstrapReady' `
            -ProtocolSha ('a' * 40) -Strategy 'FreshAdoption'
        $validManifestAccepted = & $manifestValidator `
            -Manifest $validManifest -Repository 'test-owner/consumer' `
            -TargetTag 'v0.12.7' -ProtocolSha ('a' * 40) `
            -ExpectedState 'BootstrapReady' `
            -ExpectedAdoptionStrategy 'FreshAdoption' `
            -ExpectedProtocolSurfaces @() `
            -ExpectedProtocolRecordLossAcknowledgement $false `
            -ExpectedCollisions @()
        if (-not $validManifestAccepted) {
            Add-Failure 'TEST-0080 production contract rejected the canonical adoption manifest control.'
        }
        foreach ($manifestMode in $manifestContractModes) {
            $contractManifest = New-TestQuickAdoptionManifest `
                -Mode $manifestMode -Repository 'test-owner/consumer' `
                -State 'BootstrapReady' -ProtocolSha ('a' * 40) `
                -Strategy 'FreshAdoption'
            $contractAccepted = & $manifestValidator `
                -Manifest $contractManifest -Repository 'test-owner/consumer' `
                -TargetTag 'v0.12.7' -ProtocolSha ('a' * 40) `
                -ExpectedState 'BootstrapReady' `
                -ExpectedAdoptionStrategy 'FreshAdoption' `
                -ExpectedProtocolSurfaces @() `
                -ExpectedProtocolRecordLossAcknowledgement $false `
                -ExpectedCollisions @()
            if ($contractAccepted) {
                Add-Failure "TEST-0080 production contract accepted adoption manifest mode '$manifestMode'."
            }
        }

        # The production contract table owns the malformed-manifest variants.
        # Keep one real launcher slice for JSON root parsing and fail-closed
        # translation at the adapter boundary.
        $representativeManifestMode = 'ArrayRoot'
        Reset-MockAdoptionProposal
        $global:QuickAdoptionManifestMode = $representativeManifestMode
        $codexCountBeforeInvalidManifest = @(Get-MockCodexCalls).Count
        $invalidManifestBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $invalidManifestBlocked = $true
        }
        if (-not $invalidManifestBlocked -or
            @(Get-MockCodexCalls).Count -ne $codexCountBeforeInvalidManifest -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure "TEST-0080 launcher accepted representative adoption manifest mode '$representativeManifestMode' before local Codex execution."
        }

        Reset-MockAdoptionProposal
        $savedIssues = @($global:QuickAdoptionIssues)
        $savedCanonicalIssue = $global:QuickAdoptionIssue
        $canonicalOwnedIssue = @($savedIssues | Where-Object {
            [string]$_.state -ceq 'OPEN' -and
            ([string]$_.body).StartsWith($canonicalIssueMarker, [StringComparison]::Ordinal)
        } | Select-Object -First 1)
        if ($canonicalOwnedIssue.Count -ne 1) {
            Add-Failure 'TEST-0081 marker-variant fixture could not locate its canonical adoption issue.'
        }
        else {
            $canonicalOwnedBody = [string]$canonicalOwnedIssue[0].body
            $markerVariants = [ordered]@{
                malformed = $canonicalOwnedBody.Replace(
                    $canonicalIssueMarker,
                    '<!-- meandai-local-adoption:v0.12.7:pr-42 --'
                )
                duplicate = "$canonicalOwnedBody`n$canonicalIssueMarker"
            }
            $markerVariantIndex = 0
            foreach ($variant in $markerVariants.GetEnumerator()) {
                if ($markerVariantIndex -gt 0) {
                    Reset-MockAdoptionProposal
                }
                $global:QuickAdoptionIssues.Clear()
                $variantIssue = [pscustomobject]@{
                    number = 83
                    url = "https://github.com/$($global:QuickAdoptionRepoName)/issues/83"
                    title = [string]$canonicalOwnedIssue[0].title
                    body = [string]$variant.Value
                    state = 'OPEN'
                }
                $global:QuickAdoptionIssues.Add($variantIssue)
                $global:QuickAdoptionIssue = $variantIssue
                $codexCountBeforeMarkerVariant = @(Get-MockCodexCalls).Count
                $issueCountBeforeMarkerVariant = $global:QuickAdoptionIssues.Count
                $markerVariantBlocked = $false
                try {
                    & $launcherPath -TargetPath $existingRepo `
                        -CodexCommand $mockCodexPath | Out-Null
                }
                catch {
                    $markerVariantBlocked = $true
                }
                if (-not $markerVariantBlocked -or
                    @(Get-MockCodexCalls).Count -ne $codexCountBeforeMarkerVariant -or
                    $global:QuickAdoptionIssues.Count -ne $issueCountBeforeMarkerVariant) {
                    Add-Failure "TEST-0069/TEST-0081 $($variant.Key) adoption-issue marker did not fail closed before issue mutation and Codex execution."
                }
                $markerVariantIndex++
            }
        }
        $global:QuickAdoptionIssues.Clear()
        foreach ($issue in $savedIssues) {
            $global:QuickAdoptionIssues.Add($issue)
        }
        $global:QuickAdoptionIssue = $savedCanonicalIssue
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityMetadataCredential')) {
        Reset-MockAdoptionProposal
        $secretCountBeforeFileFreeAdoption = $global:QuickAdoptionSecrets.Count
        $protocolCloneCountBeforeFileFreeAdoption = @(
            $global:QuickAdoptionGhCalls | Where-Object {
                $_.Arguments.Count -ge 4 -and $_.Arguments[0] -eq 'repo' -and
                $_.Arguments[1] -eq 'clone' -and
                $_.Arguments[2] -eq 'hasanmanzak/meAndAI'
            }
        ).Count
        & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        $protocolCloneCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 4 -and $_.Arguments[0] -eq 'repo' -and
            $_.Arguments[1] -eq 'clone' -and $_.Arguments[2] -eq 'hasanmanzak/meAndAI'
        })
        if (($protocolCloneCalls.Count - $protocolCloneCountBeforeFileFreeAdoption) -ne 1 -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeFileFreeAdoption) {
            Add-Failure 'TEST-0045 file-free semantic adoption did not use an exact authenticated local gh snapshot without rewriting secrets.'
        }

        $global:QuickAdoptionPrReadyCalls = 0
        $global:QuickAdoptionRunListCalls = 0
        $global:QuickAdoptionPrListCalls = 0
        [void]$global:QuickAdoptionExistingSecrets.Remove('MEANDAI_PROTOCOL_TOKEN')
        $secretCountBeforeMissingProtocolFile = $global:QuickAdoptionSecrets.Count
        $missingProtocolFileBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $missingProtocolFileBlocked = $true
        }
        if (-not $missingProtocolFileBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeMissingProtocolFile) {
            Add-Failure 'TEST-0045 a missing protocol secret did not require its mapped local credential file before mutation.'
        }

        Set-Content -LiteralPath (Join-Path $existingRepo 'MEANDAI_RO_FG_PAT.txt') `
            -Value 'read-token-value' -NoNewline
        $secretCountBeforePartialReconciliation = $global:QuickAdoptionSecrets.Count
        $codexCallsBeforeUnverifiedDraft = @(Get-MockCodexCalls)
        $codexCallCountBeforeUnverifiedDraft = $codexCallsBeforeUnverifiedDraft.Count
        & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        $codexCallsAfterUnverifiedDraft = @(Get-MockCodexCalls)
        $partialSecretWrites = @($global:QuickAdoptionSecrets |
            Select-Object -Skip $secretCountBeforePartialReconciliation)
        if ($partialSecretWrites.Count -ne 1 -or
            $partialSecretWrites[0].Name -cne 'MEANDAI_PROTOCOL_TOKEN') {
            Add-Failure 'TEST-0042 partial reconciliation did not create only the missing protocol secret.'
        }
        if ($global:QuickAdoptionPrReadyCalls -ne 0 -or
            $codexCallsAfterUnverifiedDraft.Count -ne $codexCallCountBeforeUnverifiedDraft) {
            Add-Failure "TEST-0040 an unverified manifest-free draft was promoted or reprocessed automatically (ready calls: $($global:QuickAdoptionPrReadyCalls); Codex calls: $codexCallCountBeforeUnverifiedDraft -> $($codexCallsAfterUnverifiedDraft.Count))."
        }
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityCodexFailure')) {
        if ($env:OS -eq 'Windows_NT') {
            foreach ($sandboxFailureMode in @('FailAll', 'Residue')) {
                Reset-MockAdoptionProposal
                $env:MEANDAI_TEST_CODEX_SANDBOX_MODE = $sandboxFailureMode
                $sandboxCallsBefore = @(Get-MockCodexSandboxCalls).Count
                $execCallsBefore = @(Get-MockCodexCalls | Where-Object {
                    $_.Arguments.Count -gt 0 -and $_.Arguments[0] -ceq 'exec'
                }).Count
                $sandboxBlocked = $false
                $sandboxError = ''
                try {
                    & $launcherPath -TargetPath $existingRepo `
                        -CodexCommand $mockCodexPath -NoProgress | Out-Null
                }
                catch {
                    $sandboxBlocked = $true
                    $sandboxError = $_.Exception.Message
                }
                $newSandboxCalls = @(
                    @(Get-MockCodexSandboxCalls) | Select-Object -Skip $sandboxCallsBefore
                )
                $execCallsAfter = @(Get-MockCodexCalls | Where-Object {
                    $_.Arguments.Count -gt 0 -and $_.Arguments[0] -ceq 'exec'
                }).Count
                $expectedError = if ($sandboxFailureMode -ceq 'Residue') {
                    'probe file'
                }
                else {
                    'cannot write'
                }
                if (-not $sandboxBlocked -or $newSandboxCalls.Count -ne 2 -or
                    $execCallsAfter -ne $execCallsBefore -or
                    $sandboxError.IndexOf(
                        $expectedError, [StringComparison]::OrdinalIgnoreCase
                    ) -lt 0) {
                    Add-Failure "TEST-0103 Windows sandbox mode '$sandboxFailureMode' did not block before semantic execution: $sandboxError"
                }
            }
        }
        $env:MEANDAI_TEST_CODEX_SANDBOX_MODE = 'Success'

        $completionContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAICompletedAdoptionChangeSet'
        foreach ($negativeContractCase in @(
            [pscustomobject]@{
                Mode = 'LeaveManifest'
                Change = [pscustomobject]@{
                    Status = 'M'
                    Path = '.ai/adoption/meandai-capabilities.json'
                }
                ReplaceManifestDeletion = $true
            },
            [pscustomobject]@{
                Mode = 'RenameWorkflowAway'
                Change = [pscustomobject]@{
                    Status = 'D'
                    Path = '.github/workflows/meandai-protocol-update.yml'
                }
                ReplaceManifestDeletion = $false
            },
            [pscustomobject]@{
                Mode = 'CaseVariantCredential'
                Change = [pscustomobject]@{
                    Status = 'A'; Path = 'fg_pat.txt'
                }
                ReplaceManifestDeletion = $false
            }
        )) {
            $fixture = New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FreshAdoption' `
                -Changes @($negativeContractCase.Change)
            if ([bool]$negativeContractCase.ReplaceManifestDeletion) {
                $fixture.Changes = @($negativeContractCase.Change)
            }
            if (& $completionContract @fixture) {
                Add-Failure "TEST-0040/TEST-0053 production completion contract accepted Codex negative mode '$($negativeContractCase.Mode)'."
            }
        }

        # Authentication, commit-graph, remote-race, and case-only Git move
        # semantics remain real process/repository slices.
        foreach ($negativeMode in @(
            'Unauthenticated', 'CreateCommit', 'RemoteRace', 'CaseMoveWorkflow'
        )) {
            Reset-MockAdoptionProposal
            $env:MEANDAI_TEST_CODEX_MODE = $negativeMode
            $reviewEventCountBeforeNegative = @($global:QuickAdoptionEvents | Where-Object {
                $_ -ceq 'issue-label:add:status:needs-review'
            }).Count
            $blocked = $false
            try {
                & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $blocked = $true
            }
            if (-not $blocked -or $global:QuickAdoptionPrReadyCalls -ne 0) {
                $testId = if ($negativeMode -cin @(
                    'RenameWorkflowAway', 'CaseMoveWorkflow', 'CaseVariantCredential'
                )) { 'TEST-0053' } else { 'TEST-0040' }
                Add-Failure "$testId local Codex negative mode '$negativeMode' did not block before readiness."
            }
            $reviewEventCountAfterNegative = @($global:QuickAdoptionEvents | Where-Object {
                $_ -ceq 'issue-label:add:status:needs-review'
            }).Count
            if ($reviewEventCountAfterNegative -ne $reviewEventCountBeforeNegative) {
                Add-Failure "TEST-0049 blocked local Codex mode '$negativeMode' assigned review-ready issue status."
            }
            $negativePaths = @(Invoke-TestGit -Repository $existingRemote -Arguments @(
                'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.12.7'
            ))
            if ($negativePaths -contains 'docs/governance/ai-adoption.md') {
                Add-Failure "TEST-0040 local Codex negative mode '$negativeMode' published the local completion."
            }
        }
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0053'
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'

        Reset-MockAdoptionProposal
        $global:QuickAdoptionIssueRace = $false
        $global:QuickAdoptionIssues.Clear()
        $global:QuickAdoptionIssueLabels.Clear()
        $global:QuickAdoptionIssue = $null
        Publish-MockAdoptionBranch
        $env:MEANDAI_TEST_CODEX_MODE = 'Sleep'
        $timeoutRemoteHeadBefore = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        )))[0].Split("`t")[0]
        $timeoutTempRootsBefore = @(Get-ChildItem -LiteralPath ([IO.Path]::GetTempPath()) `
            -Directory -Filter 'meandai-local-adoption-*' -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName })
        $timeoutBlocked = $false
        $timeoutMessage = ''
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath `
                -CodexTimeoutSeconds 1 | Out-Null
        }
        catch {
            $timeoutMessage = $_.Exception.Message
            $timeoutBlocked = $timeoutMessage -like '*exceeded the 1 second(s) limit*'
        }
        $timeoutRemoteHeadAfter = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        )))[0].Split("`t")[0]
        $timeoutTempRootsAfter = @(Get-ChildItem -LiteralPath ([IO.Path]::GetTempPath()) `
            -Directory -Filter 'meandai-local-adoption-*' -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName })
        $newTimeoutTempRoots = @($timeoutTempRootsAfter | Where-Object {
            $timeoutTempRootsBefore -cnotcontains $_
        })
        if (-not $timeoutBlocked -or $global:QuickAdoptionPrReadyCalls -ne 0 -or
            $timeoutRemoteHeadAfter -cne $timeoutRemoteHeadBefore -or
            $newTimeoutTempRoots.Count -ne 0) {
            Add-Failure "TEST-0066 local Codex timeout path was not executed and terminated before readiness (ready=$($global:QuickAdoptionPrReadyCalls); error=$timeoutMessage)."
        }
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'

        Reset-MockAdoptionProposal
        $global:QuickAdoptionRunMode = 'Zero'
        $zeroRunBlocked = $false
        $codexCountBeforeZeroRun = @(Get-MockCodexCalls).Count
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $zeroRunBlocked = $true
        }
        if (-not $zeroRunBlocked -or $global:QuickAdoptionRunListCalls -lt 3 -or
            @(Get-MockCodexCalls).Count -ne $codexCountBeforeZeroRun -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure 'TEST-0054 zero unseen workflow runs did not wait and block before semantic completion.'
        }
        $global:QuickAdoptionRunMode = 'Single'
        Reset-MockAdoptionProposal

        $global:QuickAdoptionRunMode = 'Ambiguous'
        $ambiguousRunBlocked = $false
        $codexCountBeforeAmbiguousRun = @(Get-MockCodexCalls).Count
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $ambiguousRunBlocked = $true
        }
        if (-not $ambiguousRunBlocked -or
            @(Get-MockCodexCalls).Count -ne $codexCountBeforeAmbiguousRun -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure 'TEST-0054 multiple unseen workflow runs did not block before semantic completion.'
        }

        $savedIntegrityContext = [pscustomobject]@{
            RepositoryName = $global:QuickAdoptionRepoName
            TargetPath = $global:QuickAdoptionTargetPath
            RemotePath = $global:QuickAdoptionRemotePath
            DefaultBranch = $global:QuickAdoptionDefaultBranch
            ExistingSecrets = @($global:QuickAdoptionExistingSecrets)
            CodexTarget = $env:MEANDAI_TEST_CODEX_TARGET
            CodexRemote = $env:MEANDAI_TEST_CODEX_REMOTE
        }
        $completionContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAICompletedAdoptionChangeSet'
        foreach ($applicationContractCase in @(
            [pscustomobject]@{
                Mode = 'DeleteApplication'
                Change = [pscustomobject]@{ Status = 'D'; Path = 'app.txt' }
            },
            [pscustomobject]@{
                Mode = 'AddProtocolSurface'
                Change = [pscustomobject]@{ Status = 'A'; Path = 'PROTOCOL.md' }
            },
            [pscustomobject]@{
                Mode = 'AddCursorRule'
                Change = [pscustomobject]@{
                    Status = 'A'; Path = '.cursor/rules/unauthorized.md'
                }
            }
        )) {
            $fixture = New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FreshAdoption' `
                -Changes @($applicationContractCase.Change)
            if (& $completionContract @fixture) {
                Add-Failure "TEST-0129 production completion contract accepted FreshAdoption application boundary '$($applicationContractCase.Mode)'."
            }
        }

        # The contract table owns addition/deletion policy shapes. Retain one
        # modification and one real non-protocol .gitmodules preservation
        # slice; deletion uses the same Gitmodules identity boundary.
        foreach ($applicationBoundaryCase in @(
            [pscustomobject]@{
                Mode = 'ModifyApplication'
                ExpectedError = '*violates the canonical capabilities contract*'
                HasProductSubmodule = $false
            },
            [pscustomobject]@{
                Mode = 'ModifyProductSubmodule'
                ExpectedError = '*Adoption completion changed non-protocol .gitmodules configuration*'
                HasProductSubmodule = $true
            }
        )) {
            Reset-Mocks
            $freshBoundaryConsumer = New-MockConnectedSeedConsumer `
                -Name "fresh-$(([string]$applicationBoundaryCase.Mode).ToLowerInvariant())" `
                -OmitWorkflowSeed
            $freshMainGitmodulesBlob = ''
            $freshGitmodulesHashBefore = ''
            if ([bool]$applicationBoundaryCase.HasProductSubmodule) {
                $productGitmodules = @(
                    '[submodule "vendor/product"]',
                    "`tpath = vendor/product",
                    "`turl = https://example.invalid/product.git",
                    "`tbranch = stable",
                    '[submodule "vendor/case-sensitive-product"]',
                    "`tpath = vendor/case-sensitive-product",
                    "`turl = https://example.invalid/case-sensitive-product.git",
                    ''
                ) -join "`n"
                $productGitmodulesPath = Join-Path `
                    $freshBoundaryConsumer.Repository '.gitmodules'
                [IO.File]::WriteAllText(
                    $productGitmodulesPath,
                    $productGitmodules,
                    [Text.UTF8Encoding]::new($false)
                )
                Invoke-TestGit -Repository $freshBoundaryConsumer.Repository `
                    -Arguments @('add', '--', '.gitmodules') | Out-Null
                Invoke-TestGit -Repository $freshBoundaryConsumer.Repository `
                    -Arguments @(
                        'commit', '-m',
                        'Add representative product submodule configuration'
                    ) | Out-Null
                Invoke-TestGit -Repository $freshBoundaryConsumer.Repository `
                    -Arguments @('push', 'origin', 'main') | Out-Null
                $freshMainGitmodulesBlob = (@(Invoke-TestGit `
                    -Repository $freshBoundaryConsumer.Remote -Arguments @(
                        'rev-parse', 'refs/heads/main:.gitmodules'
                    )))[0]
                $freshGitmodulesHashBefore = (Get-FileHash `
                    -LiteralPath $productGitmodulesPath -Algorithm SHA256).Hash
                $global:QuickAdoptionProposalMode = 'ManifestOnly'
            }
            $freshApplicationHashBefore = (Get-FileHash `
                -LiteralPath (Join-Path $freshBoundaryConsumer.Repository 'app.txt') `
                -Algorithm SHA256).Hash
            $freshMainApplicationBlob = (@(Invoke-TestGit `
                -Repository $freshBoundaryConsumer.Remote -Arguments @(
                    'rev-parse', 'refs/heads/main:app.txt'
                )))[0]
            $env:MEANDAI_TEST_CODEX_MODE = [string]$applicationBoundaryCase.Mode
            $freshBoundaryError = ''
            try {
                & $launcherPath -TargetPath $freshBoundaryConsumer.Repository `
                    -AdoptionStrategy FreshAdoption -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $freshBoundaryError = $_.Exception.Message
            }
            $freshApplicationHashAfter = (Get-FileHash `
                -LiteralPath (Join-Path $freshBoundaryConsumer.Repository 'app.txt') `
                -Algorithm SHA256).Hash
            $freshBranchRef =
                'refs/heads/automation/meandai-capabilities-v0.12.7'
            $freshBranchHeads = @(Invoke-TestGit `
                -Repository $freshBoundaryConsumer.Repository -Arguments @(
                    'ls-remote', '--heads', 'origin', $freshBranchRef
                ))
            $freshBranchApplicationBlob = ''
            if ($freshBranchHeads.Count -eq 1) {
                $freshBranchApplicationBlob = (@(Invoke-TestGit `
                    -Repository $freshBoundaryConsumer.Remote -Arguments @(
                        'rev-parse', "$freshBranchRef`:app.txt"
                    )))[0]
            }
            $freshBranchGitmodulesBlob = ''
            $freshGitmodulesHashAfter = ''
            if ([bool]$applicationBoundaryCase.HasProductSubmodule -and
                $freshBranchHeads.Count -eq 1) {
                $freshBranchGitmodulesBlob = (@(Invoke-TestGit `
                    -Repository $freshBoundaryConsumer.Remote -Arguments @(
                        'rev-parse', "$freshBranchRef`:.gitmodules"
                    )))[0]
            }
            if ([bool]$applicationBoundaryCase.HasProductSubmodule) {
                $freshGitmodulesHashAfter = (Get-FileHash `
                    -LiteralPath (
                        Join-Path $freshBoundaryConsumer.Repository '.gitmodules'
                    ) -Algorithm SHA256).Hash
            }
            if ($freshBoundaryError -notlike
                    [string]$applicationBoundaryCase.ExpectedError -or
                $freshBranchHeads.Count -ne 1 -or
                $global:QuickAdoptionPrReadyCalls -ne 0 -or
                $freshApplicationHashAfter -cne $freshApplicationHashBefore -or
                $freshBranchApplicationBlob -cne $freshMainApplicationBlob -or
                ([bool]$applicationBoundaryCase.HasProductSubmodule -and
                    ($freshBranchGitmodulesBlob -cne $freshMainGitmodulesBlob -or
                     $freshGitmodulesHashAfter -cne
                        $freshGitmodulesHashBefore)) -or
                (Test-Path -LiteralPath (
                    Join-Path $freshBoundaryConsumer.Repository `
                        'src/unauthorized-application.txt'
                )) -or
                (Test-Path -LiteralPath (
                    Join-Path $freshBoundaryConsumer.Repository 'PROTOCOL.md'
                )) -or
                (Test-Path -LiteralPath (
                    Join-Path $freshBoundaryConsumer.Repository `
                        '.cursor/rules/unauthorized.md'
                ))) {
                Add-Failure "TEST-0129 FreshAdoption application boundary accepted $($applicationBoundaryCase.Mode), published it, or mutated the representative app: $freshBoundaryError"
            }
            $env:MEANDAI_TEST_CODEX_MODE = 'Success'
        }

        Reset-Mocks
        $global:QuickAdoptionRepoName =
            [string]$savedIntegrityContext.RepositoryName
        $global:QuickAdoptionTargetPath =
            [string]$savedIntegrityContext.TargetPath
        $global:QuickAdoptionRemotePath =
            [string]$savedIntegrityContext.RemotePath
        $global:QuickAdoptionDefaultBranch =
            [string]$savedIntegrityContext.DefaultBranch
        $global:QuickAdoptionExistingSecrets.Clear()
        foreach ($secretName in @($savedIntegrityContext.ExistingSecrets)) {
            $global:QuickAdoptionExistingSecrets.Add([string]$secretName)
        }
        $env:MEANDAI_TEST_CODEX_TARGET = [string]$savedIntegrityContext.CodexTarget
        $env:MEANDAI_TEST_CODEX_REMOTE = [string]$savedIntegrityContext.CodexRemote
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityMetadataCredential')) {
        $completionContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAICompletedAdoptionChangeSet'
        $global:QuickAdoptionRunMode = 'Single'
        Reset-MockAdoptionProposal

        $global:QuickAdoptionPrMetadataMode = 'WrongBaseAfterFirst'
        $lateMetadataBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $lateMetadataBlocked = $true
        }
        if (-not $lateMetadataBlocked -or $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure 'TEST-0052 a pull-request identity change after initial resolution did not block publication.'
        }
        $global:QuickAdoptionPrMetadataMode = 'Valid'
        Reset-MockAdoptionProposal

        $defaultBranchNameHeadBefore = (@(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'rev-parse', 'refs/heads/main'
            )))[0]
        $defaultBranchNameCodexBefore = @(Get-MockCodexCalls).Count
        $global:QuickAdoptionRepoViewMode = 'WrongAfterFirst'
        $defaultBranchNameError = ''
        try {
            & $launcherPath -TargetPath $existingRepo `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $defaultBranchNameError = $_.Exception.Message
        }
        $defaultBranchNameHeadAfter = (@(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'rev-parse', 'refs/heads/main'
            )))[0]
        if ($defaultBranchNameError -notlike
                '*live repository/default branch changed after strategy assessment*' -or
            $defaultBranchNameHeadAfter -cne
                $defaultBranchNameHeadBefore -or
            @(Get-MockCodexCalls).Count -ne
                $defaultBranchNameCodexBefore -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure "TEST-0052 live default-branch name drift was not rejected while the old branch ref SHA remained unchanged: $defaultBranchNameError"
        }
        $policyModulesAfterPreflightFailure = @(
            Get-TestLoadedInitialAdoptionPolicyModules
        )
        if ($policyModulesAfterPreflightFailure.Count -ne 0) {
            Add-Failure "TEST-0130 failed preflight leaked dynamic initial-policy modules: $($policyModulesAfterPreflightFailure.Name -join ', ')"
        }
        $global:QuickAdoptionRepoViewMode = 'Valid'
        Reset-MockAdoptionProposal

        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'AGENTS.md'),
            "# Consumer-owned instructions`n"
        )
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'PROTOCOL.md'),
            "# Legacy common protocol authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        foreach ($migrationFixturePath in @(
            'ai/WORK_INDEX.md', 'ai/model.py',
            'docs/features/product.md'
        )) {
            New-Item -ItemType Directory -Path (
                Split-Path -Parent (Join-Path $existingRepo $migrationFixturePath)
            ) -Force | Out-Null
        }
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'ai/WORK_INDEX.md'),
            "# Legacy AI work index`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'ai/model.py'),
            "print('consumer product model')`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'RELEASES.md'),
            "# Product release history`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'docs/features/product.md'),
            "# Product feature record`n",
            [Text.UTF8Encoding]::new($false)
        )
        $legacyGovernancePath = 'docs/governance/legacy-protocol.md'
        New-Item -ItemType Directory -Path (
            Split-Path -Parent (Join-Path $existingRepo $legacyGovernancePath)
        ) -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo $legacyGovernancePath),
            "# Legacy protocol authority`n`nPreserve repository-specific review intent.`n",
            [Text.UTF8Encoding]::new($false)
        )
        $legacyCursorPath = '.cursor/rules/legacy.md'
        New-Item -ItemType Directory -Path (
            Split-Path -Parent (Join-Path $existingRepo $legacyCursorPath)
        ) -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo $legacyCursorPath),
            "# Legacy cursor authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        $legacyGitHubInstructionPath =
            '.github/instructions/legacy.instructions.md'
        New-Item -ItemType Directory -Path (
            Split-Path -Parent (
                Join-Path $existingRepo $legacyGitHubInstructionPath
            )
        ) -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $existingRepo $legacyGitHubInstructionPath),
            "# Legacy GitHub instruction authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-Git -Repository $existingRepo -Arguments @(
            'add', '--', 'AGENTS.md', 'PROTOCOL.md', 'RELEASES.md',
            'ai/WORK_INDEX.md', 'ai/model.py',
            'docs/features/product.md', $legacyGovernancePath,
            $legacyCursorPath, $legacyGitHubInstructionPath
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Create adoption collision fixture'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        # This strategy fixture is a new logical adoption proposal. Do not let
        # the completed baseline's mock issue identity leak into its issue-body
        # contract; real reruns retain and validate their own exact issue.
        $global:QuickAdoptionIssues.Clear()
        $global:QuickAdoptionIssue = $null
        $global:QuickAdoptionIssueLabels.Clear()
        $global:QuickAdoptionProposalMode = 'ManifestOnly'
        $expectedMigrationSurfaces = @(
            'AGENTS.md', 'PROTOCOL.md', 'RELEASES.md',
            'ai/WORK_INDEX.md', 'docs/features/product.md',
            $legacyGovernancePath, $legacyCursorPath,
            $legacyGitHubInstructionPath
        )
        [Array]::Sort(
            $expectedMigrationSurfaces, [StringComparer]::Ordinal
        )
        $migrationMainApplicationBlob = (@(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'rev-parse', 'refs/heads/main:app.txt'
            )))[0]
        $migrationPublishedBaseSha = (@(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'rev-parse', 'refs/heads/main'
            )))[0]

        $proposalMarkerContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAIExactAdoptionPullRequestMarker'
        $strategyMarkerFixture =
            New-TestQuickAdoptionPullRequestContractFixture `
                -Mode 'MarkerStrategyMismatch' -Strategy 'FullMigration' `
                -ProtocolSurfaces $expectedMigrationSurfaces
        if (& $proposalMarkerContract @strategyMarkerFixture) {
            Add-Failure "TEST-0130 production marker contract accepted strategy drift 'MarkerStrategyMismatch'."
        }

        # Surface drift is the representative real marker-adapter slice; the
        # production contract directly owns the strategy variant above.
        foreach ($markerDriftMode in @('MarkerSurfaceMismatch')) {
            $global:QuickAdoptionPrMetadataMode = $markerDriftMode
            $codexCallsBeforeMarkerDrift = @(Get-MockCodexCalls).Count
            $markerDriftError = ''
            try {
                & $launcherPath -TargetPath $existingRepo `
                    -AdoptionStrategy FullMigration -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $markerDriftError = $_.Exception.Message
            }
            if (-not $markerDriftError -or
                @(Get-MockCodexCalls).Count -ne $codexCallsBeforeMarkerDrift -or
                $global:QuickAdoptionPrReadyCalls -ne 0) {
                Add-Failure "TEST-0130 launcher accepted strategy/surface marker drift '$markerDriftMode' before semantic execution: $markerDriftError"
            }
            Reset-MockAdoptionProposal
        }
        $global:QuickAdoptionPrMetadataMode = 'Valid'

        $migrationManifestValidator = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAIExactAdoptionManifest'
        foreach ($manifestDriftMode in @(
            'WrongStrategy', 'WrongSurfaces', 'WrongLossAcknowledgement'
        )) {
            $contractManifest = New-TestQuickAdoptionManifest `
                -Mode $manifestDriftMode -Repository 'test-owner/consumer' `
                -State 'AdoptionReviewRequired' -ProtocolSha ('a' * 40) `
                -Strategy 'FullMigration' `
                -ProtocolSurfaces $expectedMigrationSurfaces
            $contractAccepted = & $migrationManifestValidator `
                -Manifest $contractManifest -Repository 'test-owner/consumer' `
                -TargetTag 'v0.12.7' -ProtocolSha ('a' * 40) `
                -ExpectedState 'AdoptionReviewRequired' `
                -ExpectedAdoptionStrategy 'FullMigration' `
                -ExpectedProtocolSurfaces $expectedMigrationSurfaces `
                -ExpectedProtocolRecordLossAcknowledgement $false `
                -ExpectedCollisions @()
            if ($contractAccepted) {
                Add-Failure "TEST-0130 production manifest contract accepted strategy identity drift '$manifestDriftMode'."
            }
        }

        # Strategy/surface/loss identity is exhaustively covered by the pure
        # contract above. Retain the surface variant as the real adapter slice.
        $representativeManifestDriftMode = 'WrongSurfaces'
        $global:QuickAdoptionManifestMode = $representativeManifestDriftMode
        $codexCallsBeforeManifestDrift = @(Get-MockCodexCalls).Count
        $manifestDriftError = ''
        try {
            & $launcherPath -TargetPath $existingRepo `
                -AdoptionStrategy FullMigration -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $manifestDriftError = $_.Exception.Message
        }
        if (-not $manifestDriftError -or
            @(Get-MockCodexCalls).Count -ne $codexCallsBeforeManifestDrift -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure "TEST-0130 launcher accepted representative strategy/surface/loss manifest drift '$representativeManifestDriftMode' before semantic execution: $manifestDriftError"
        }
        Reset-MockAdoptionProposal
        $global:QuickAdoptionManifestMode = 'Valid'
        foreach ($readOnlyContractCase in @(
            [pscustomobject]@{
                Mode = 'DeleteReadOnlyRelease'
                Path = 'RELEASES.md'
            },
            [pscustomobject]@{
                Mode = 'DeleteReadOnlyFeature'
                Path = 'docs/features/product.md'
            }
        )) {
            $fixture = New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FullMigration' `
                -ProtocolSurfaces @([string]$readOnlyContractCase.Path) `
                -Changes @([pscustomobject]@{
                    Status = 'D'; Path = [string]$readOnlyContractCase.Path
                })
            if (& $completionContract @fixture) {
                Add-Failure "TEST-0129 production completion contract accepted read-only boundary '$($readOnlyContractCase.Mode)'."
            }
        }

        # Keep one real product-code modification to prove the launcher-to-
        # contract boundary and candidate cleanup.
        foreach ($readOnlyBoundaryCase in @(
            [pscustomobject]@{
                Mode = 'ModifyAiModel'
                Path = 'ai/model.py'
            }
        )) {
            $env:MEANDAI_TEST_CODEX_MODE =
                [string]$readOnlyBoundaryCase.Mode
            $readOnlyBoundaryError = ''
            try {
                & $launcherPath -TargetPath $existingRepo `
                    -AdoptionStrategy FullMigration -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $readOnlyBoundaryError = $_.Exception.Message
            }
            $env:MEANDAI_TEST_CODEX_MODE = 'Success'
            if ($readOnlyBoundaryError -notlike
                    '*violates the canonical capabilities contract*' -or
                $global:QuickAdoptionPrReadyCalls -ne 0) {
                Add-Failure "TEST-0129 FullMigration changed read-only or product path '$($readOnlyBoundaryCase.Path)' or published it: $readOnlyBoundaryError"
            }
            Reset-MockAdoptionProposal
        }

        $unchangedAgentsFixture =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FullMigration' `
                -ProtocolSurfaces @('AGENTS.md')
        if (& $completionContract @unchangedAgentsFixture) {
            Add-Failure 'TEST-0129 production completion contract accepted RestoreRootAgents.'
        }
        $retainedCursorFixture =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FullMigration' `
                -ProtocolSurfaces @($legacyCursorPath) `
                -AdditionalEntries @([pscustomobject]@{
                    Path = $legacyCursorPath
                    Exists = $true
                    Mode = '100644'
                })
        if (& $completionContract @retainedCursorFixture) {
            Add-Failure 'TEST-0129 production completion contract accepted RetainCursorAuthority.'
        }

        # Retain one real common-authority case as the launcher adapter slice.
        $env:MEANDAI_TEST_CODEX_MODE = 'RetainLegacyCommonAuthority'
        $retainedAuthorityError = ''
        try {
            & $launcherPath -TargetPath $existingRepo `
                -AdoptionStrategy FullMigration -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $retainedAuthorityError = $_.Exception.Message
        }
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'
        if ($retainedAuthorityError -notlike
                '*violates the canonical capabilities contract*' -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure "TEST-0129 FullMigration accepted a retained legacy common authority or published it: $retainedAuthorityError"
        }
        Reset-MockAdoptionProposal

        $env:MEANDAI_TEST_CODEX_MODE = 'DeleteApprovedSurface'
        $codexCallsBeforeMigration = @(Get-MockCodexCalls).Count
        $collisionCompleted = $true
        $collisionError = ''
        try {
            & $launcherPath -TargetPath $existingRepo `
                -AdoptionStrategy FullMigration -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $collisionCompleted = $false
            $collisionError = $_.Exception.Message
        }
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'
        $collisionEntry = @((Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', 'refs/heads/automation/meandai-capabilities-v0.12.7', '--', '.ai/protocol'
        )))
        $collisionPaths = @(Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.12.7'
        ))
        $expectedCollisionEntry = "160000 commit $($global:QuickAdoptionProtocolSha)`t.ai/protocol"
        $migrationBranchApplicationBlob = (@(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'rev-parse',
                'refs/heads/automation/meandai-capabilities-v0.12.7:app.txt'
            )))[0]
        $migrationAgentsContent = @(Invoke-TestGit `
            -Repository $existingRemote -Arguments @(
                'show',
                'refs/heads/automation/meandai-capabilities-v0.12.7:AGENTS.md'
            )) -join "`n"
        $migrationCodexCalls = @(Get-MockCodexCalls |
            Select-Object -Skip $codexCallsBeforeMigration | Where-Object {
                $_.Arguments.Count -gt 0 -and $_.Arguments[0] -ceq 'exec'
            })
        $migrationPrompt = if ($migrationCodexCalls.Count -eq 1) {
            [string]$migrationCodexCalls[0].Stdin
        }
        else { '' }
        $completedMarkerMatch = [regex]::Match(
            [string]$global:QuickAdoptionPrBody,
            '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->'
        )
        $completedMigrationMarker = if ($completedMarkerMatch.Success) {
            $completedMarkerMatch.Groups['json'].Value | ConvertFrom-Json
        }
        else { $null }
        $migrationIssueBody = if ($null -ne $global:QuickAdoptionIssue) {
            [string]$global:QuickAdoptionIssue.body
        }
        else { '' }
        if (-not $collisionCompleted -or $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $collisionEntry.Count -ne 1 -or [string]$collisionEntry[0] -cne $expectedCollisionEntry -or
            $collisionPaths -contains '.ai/adoption/meandai-capabilities.json' -or
            $collisionPaths -notcontains 'AGENTS.md' -or
            $collisionPaths -contains 'PROTOCOL.md' -or
            $collisionPaths -contains 'ai/WORK_INDEX.md' -or
            $collisionPaths -notcontains 'ai/model.py' -or
            $collisionPaths -notcontains 'RELEASES.md' -or
            $collisionPaths -notcontains 'docs/features/product.md' -or
            $collisionPaths -contains $legacyGovernancePath -or
            $collisionPaths -contains $legacyCursorPath -or
            $collisionPaths -contains $legacyGitHubInstructionPath -or
            -not $migrationAgentsContent.Contains(
                '.ai/protocol/PROTOCOL.md'
            ) -or
            -not $migrationAgentsContent.Contains(
                'Preserve the consumer-specific mock directive.'
            ) -or
            $migrationBranchApplicationBlob -cne $migrationMainApplicationBlob) {
            Add-Failure "TEST-0046/TEST-0129 token-backed FullMigration did not publish the exact protocol gitlink, preserve required AGENTS.md, retire its approved legacy authorities, and preserve the representative app: $collisionError"
        }
        if ($null -eq $global:QuickAdoptionDispatchRecord -or
            [string]$global:QuickAdoptionDispatchRecord.AdoptionStrategy -cne
                'FullMigration' -or
            [string]$global:QuickAdoptionDispatchRecord.ExpectedBaseSha -cne
                $migrationPublishedBaseSha -or
            [bool]$global:QuickAdoptionDispatchRecord.ProtocolRecordLossAcknowledged -or
            (@($global:QuickAdoptionProposalSurfaces) -join "`n") -cne
                ($expectedMigrationSurfaces -join "`n") -or
            $migrationCodexCalls.Count -ne 1 -or
            -not $migrationPrompt.Contains(
                'The maintainer-selected adoption strategy is FullMigration.'
            ) -or
            -not $migrationPrompt.Contains(
                'Map and preserve every still-valid repository-specific directive'
            ) -or
            @($expectedMigrationSurfaces | Where-Object {
                -not $migrationPrompt.Contains("- $_")
            }).Count -ne 0 -or
            $null -eq $completedMigrationMarker -or
            [string]$completedMigrationMarker.adoptionStrategy -cne
                'FullMigration' -or
            (@($completedMigrationMarker.protocolSurfaces) -join "`n") -cne
                ($expectedMigrationSurfaces -join "`n") -or
            -not $migrationIssueBody.Contains(
                '- Adoption strategy: `FullMigration`'
            ) -or
            @($expectedMigrationSurfaces | Where-Object {
                -not $migrationIssueBody.Contains([string]$_)
            }).Count -ne 0) {
            Add-Failure "TEST-0129/TEST-0130 FullMigration dispatch, prompt, issue, marker, or exact protocol-surface identity was not preserved end to end (dispatch=$($global:QuickAdoptionDispatchRecord.AdoptionStrategy); expectedBase=$($global:QuickAdoptionDispatchRecord.ExpectedBaseSha)/$migrationPublishedBaseSha; loss=$($global:QuickAdoptionDispatchRecord.ProtocolRecordLossAcknowledged); dispatchedSurfaces=$(@($global:QuickAdoptionProposalSurfaces) -join ','); expectedSurfaces=$($expectedMigrationSurfaces -join ','); codexCalls=$($migrationCodexCalls.Count); promptStrategy=$($migrationPrompt.Contains('The maintainer-selected adoption strategy is FullMigration.')); promptContract=$($migrationPrompt.Contains('Map and preserve every still-valid repository-specific directive')); promptMissing=$(@($expectedMigrationSurfaces | Where-Object { -not $migrationPrompt.Contains("- $_") }).Count); marker=$([string]$completedMigrationMarker.adoptionStrategy)/$(@($completedMigrationMarker.protocolSurfaces) -join ','); issueStrategy=$($migrationIssueBody.Contains('- Adoption strategy: `FullMigration`')); issueMissing=$(@($expectedMigrationSurfaces | Where-Object { -not $migrationIssueBody.Contains([string]$_) }).Count))."
        }
        Invoke-Git -Repository $existingRepo -Arguments @(
            'rm', '--', 'AGENTS.md', 'PROTOCOL.md', 'RELEASES.md',
            'ai/WORK_INDEX.md', 'ai/model.py',
            'docs/features/product.md', $legacyGovernancePath,
            $legacyCursorPath, $legacyGitHubInstructionPath
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Remove adoption collision fixture'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        Reset-MockAdoptionProposal
        $global:QuickAdoptionIssues.Clear()
        $global:QuickAdoptionIssue = $null
        $global:QuickAdoptionIssueLabels.Clear()
        $global:QuickAdoptionProposalMode = 'ValidFull'

        foreach ($metadataContractMode in @(
            'WrongBase', 'InvalidMarker', 'WrongAuthor', 'NonDraft',
            'MarkerHeadMismatch'
        )) {
            $fixture = New-TestQuickAdoptionPullRequestContractFixture `
                -Mode $metadataContractMode -Strategy 'FreshAdoption' `
                -ProtocolSurfaces @()
            if (& $proposalMarkerContract @fixture) {
                Add-Failure "TEST-0047 production marker contract accepted pull-request metadata mode '$metadataContractMode'."
            }
        }

        # These cases depend on the raw GitHub envelope that precedes the pure
        # marker contract, so they remain real launcher slices.
        foreach ($metadataMode in @(
            'ForeignHead', 'ForeignHeadOwner', 'CrossRepository',
            'InvalidCrossRepositoryType'
        )) {
            $global:QuickAdoptionPrMetadataMode = $metadataMode
            $codexCallCountBeforeInvalidMetadata = @(Get-MockCodexCalls).Count
            $metadataBlocked = $false
            try {
                & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $metadataBlocked = $true
            }
            $codexCallCountAfterInvalidMetadata = @(Get-MockCodexCalls).Count
            if (-not $metadataBlocked -or $global:QuickAdoptionPrReadyCalls -ne 0 -or
                $codexCallCountAfterInvalidMetadata -ne $codexCallCountBeforeInvalidMetadata) {
                Add-Failure "TEST-0047 pull-request metadata mode '$metadataMode' did not block before Codex execution and readiness."
            }
            Reset-MockAdoptionProposal
        }
        $global:QuickAdoptionPrMetadataMode = 'Valid'
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0102'
        $global:QuickAdoptionProposalMode = 'WrongProtocolSha'
        $wrongPinBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $wrongPinBlocked = $true
        }
        if (-not $wrongPinBlocked -or $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure 'TEST-0047 a pre-existing protocol gitlink with the wrong SHA was promoted.'
        }
        Reset-MockAdoptionProposal
        $global:QuickAdoptionProposalMode = 'ValidFull'

        $secretCountBeforeDrift = $global:QuickAdoptionSecrets.Count
        Set-Content -LiteralPath (Join-Path $existingRepo $workflowRelativePath) -Value 'workflow-drift' -Encoding UTF8
        $driftBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $driftBlocked = $true
        }
        if (-not $driftBlocked -or $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeDrift) {
            Add-Failure 'TEST-0036 workflow drift did not block before secret mutation.'
        }
        Invoke-Git -Repository $existingRepo -Arguments @('restore', $workflowRelativePath) | Out-Null

        $trackedCredentialPath = 'nested/secrets/fg_pat.TXT'
        New-Item -ItemType Directory -Path (
            Split-Path -Parent (Join-Path $existingRepo $trackedCredentialPath)
        ) -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $existingRepo $trackedCredentialPath) `
            -Value 'write-token-value' -NoNewline
        Invoke-Git -Repository $existingRepo -Arguments @(
            'add', '-f', '--', $trackedCredentialPath
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('commit', '-m', 'Expose test credential path') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $secretCountBeforeTracked = $global:QuickAdoptionSecrets.Count
        $ghCallCountBeforeTracked = $global:QuickAdoptionGhCalls.Count
        $trackedExcludePath = Join-Path $existingRepo '.git/info/exclude'
        $trackedExcludeBefore = [IO.File]::ReadAllText($trackedExcludePath)
        $trackedHeadBefore = (@(Invoke-TestGit -Repository $existingRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $trackedTokenBlocked = $false
        $trackedTokenError = ''
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $trackedTokenBlocked = $true
            $trackedTokenError = $_.Exception.Message
        }
        $trackedPreflightGhCalls = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $ghCallCountBeforeTracked
            )
        )
        $trackedHeadAfter = (@(Invoke-TestGit -Repository $existingRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        if (-not $trackedTokenBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeTracked -or
            $trackedPreflightGhCalls.Count -ne 0 -or
            [IO.File]::ReadAllText($trackedExcludePath) -cne
                $trackedExcludeBefore -or
            $trackedHeadAfter -cne $trackedHeadBefore) {
            Add-Failure "TEST-0036/TEST-0130 tracked clean token file did not block after canonical policy authority reads and before .git/info/exclude, Git, or secret mutation: $trackedTokenError"
        }

        Invoke-Git -Repository $existingRepo -Arguments @(
            'rm', '--', $trackedCredentialPath
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Remove exposed test credential path'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $secretCountBeforeHistorical = $global:QuickAdoptionSecrets.Count
        $historicalTokenBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $historicalTokenBlocked = $true
        }
        if (-not $historicalTokenBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeHistorical) {
            Add-Failure 'TEST-0042 an absent optional token file in Git history did not block before secret mutation.'
        }

        Reset-Mocks
        $ruleGitlinkAutoConsumer = New-MockConnectedSeedConsumer `
            -Name 'rule-gitlink-auto' -OmitWorkflowSeed
        Add-MockRootRuleGitlink `
            -Repository $ruleGitlinkAutoConsumer.Repository
        $ruleGitlinkAutoHeadBefore = (@(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $ruleGitlinkAutoRemoteHeadBefore = (@(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Remote `
            -Arguments @('rev-parse', 'refs/heads/main')))[0]
        $ruleGitlinkAutoStatusBefore = @(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Repository `
            -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
        $ruleGitlinkAutoExcludePath = Join-Path `
            $ruleGitlinkAutoConsumer.Repository '.git/info/exclude'
        $ruleGitlinkAutoExcludeBefore =
            [IO.File]::ReadAllText($ruleGitlinkAutoExcludePath)
        $ruleGitlinkAutoGhBefore = $global:QuickAdoptionGhCalls.Count
        $ruleGitlinkAutoSecretBefore = $global:QuickAdoptionSecrets.Count
        $ruleGitlinkAutoCodexBefore = @(Get-MockCodexCalls).Count
        $ruleGitlinkAutoError = ''
        try {
            & $launcherPath -TargetPath $ruleGitlinkAutoConsumer.Repository `
                -AdoptionStrategy Auto -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $ruleGitlinkAutoError = $_.Exception.Message
        }
        $ruleGitlinkAutoRemoteOrAuthCalls = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $ruleGitlinkAutoGhBefore
            )
        )
        $ruleGitlinkAutoHeadAfter = (@(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $ruleGitlinkAutoRemoteHeadAfter = (@(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Remote `
            -Arguments @('rev-parse', 'refs/heads/main')))[0]
        $ruleGitlinkAutoStatusAfter = @(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Repository `
            -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
        $ruleGitlinkAutoAdoptionHeads = @(Invoke-TestGit `
            -Repository $ruleGitlinkAutoConsumer.Repository `
            -Arguments @(
                'ls-remote', '--heads', 'origin',
                'refs/heads/automation/meandai-capabilities-v0.12.7'
            ))
        if ($ruleGitlinkAutoError -notlike
                '*requires an explicit adoption strategy*' -or
            $ruleGitlinkAutoRemoteOrAuthCalls.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne
                $ruleGitlinkAutoSecretBefore -or
            @(Get-MockCodexCalls).Count -ne $ruleGitlinkAutoCodexBefore -or
            $ruleGitlinkAutoHeadAfter -cne $ruleGitlinkAutoHeadBefore -or
            $ruleGitlinkAutoRemoteHeadAfter -cne
                $ruleGitlinkAutoRemoteHeadBefore -or
            ($ruleGitlinkAutoStatusAfter -join "`n") -cne
                ($ruleGitlinkAutoStatusBefore -join "`n") -or
            [IO.File]::ReadAllText($ruleGitlinkAutoExcludePath) -cne
                $ruleGitlinkAutoExcludeBefore -or
            $ruleGitlinkAutoAdoptionHeads.Count -ne 0) {
            Add-Failure "TEST-0129/TEST-0130 exact-root .cursor/rules gitlink did not force explicit Auto strategy after canonical policy authority reads and before secret, seed, branch, or checkout mutation: $ruleGitlinkAutoError"
        }

        $rootSurfaceContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Get-MeAndAIProtocolSurfaceInventory'
        $rootStrategyContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Resolve-MeAndAIAdoptionStrategy'
        $githubInstructionRootSurfaces = @(& $rootSurfaceContract `
            -Paths @('.github/instructions'))
        $githubInstructionRootResolution = & $rootStrategyContract `
            -RequestedStrategy 'Auto' `
            -ProtocolSurfaces $githubInstructionRootSurfaces -Collisions @() `
            -AcknowledgeProtocolRecordLoss $false
        if (($githubInstructionRootSurfaces -join "`n") -cne
                '.github/instructions' -or
            [string]$githubInstructionRootResolution.State -cne
                'ProtocolMigrationReviewRequired') {
            Add-Failure 'TEST-0129/TEST-0130 production inventory/strategy contracts accepted exact-root .github/instructions false freshness.'
        }

        Reset-Mocks
        $ruleGitlinkCleanConsumer = New-MockConnectedSeedConsumer `
            -Name 'rule-gitlink-clean'
        Add-MockRootRuleGitlink `
            -Repository $ruleGitlinkCleanConsumer.Repository
        $ruleGitlinkSourceHead = (@(Invoke-TestGit `
            -Repository $ruleGitlinkCleanConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $ruleGraphBuilder = Get-TestQuickAdoptionContractCommand `
            -Name 'New-MeAndAIInstructionGraph'
        $ruleGraphValidator = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAIExactInstructionGraph'
        $ruleGitlinkSourceGraph = Get-TestCommittedInstructionGraph `
            -Repository $ruleGitlinkCleanConsumer.Repository `
            -Commit $ruleGitlinkSourceHead -Builder $ruleGraphBuilder `
            -Validator $ruleGraphValidator
        $ruleGitlinkNode = @($ruleGitlinkSourceGraph.nodes | Where-Object {
            [string]$_.path -ceq '.cursor/rules'
        })
        if ($ruleGitlinkNode.Count -ne 1 -or
            [string]$ruleGitlinkNode[0].role -cne
                'UnlinkedKnownSurfaceCandidate') {
            Add-Failure 'TEST-0129 source graph did not classify the exact-root governance gitlink as one bounded unlinked known-surface candidate.'
        }
        $ruleGitlinkDeletion = [pscustomobject]@{
            Status = 'D'; Path = '.cursor/rules'
        }
        $ruleGitlinkAbsentEntry = [pscustomobject]@{
            Path = '.cursor/rules'; Exists = $false; Mode = ''
        }
        $ruleGitlinkCleanContract =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'CleanStart' `
                -ProtocolSurfaces @($ruleGitlinkSourceGraph.protocolSurfaces) `
                -Changes @($ruleGitlinkDeletion) `
                -AdditionalEntries @($ruleGitlinkAbsentEntry)
        $ruleGitlinkCleanContract['SourceGraph'] = $ruleGitlinkSourceGraph
        if (-not (& $completionContract @ruleGitlinkCleanContract)) {
            Add-Failure 'TEST-0129 source-bound CleanStart contract rejected deletion of its exact approved governance gitlink.'
        }
        $ruleGitlinkFullContract =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FullMigration' `
                -ProtocolSurfaces @($ruleGitlinkSourceGraph.protocolSurfaces) `
                -Changes @($ruleGitlinkDeletion) `
                -AdditionalEntries @($ruleGitlinkAbsentEntry)
        $ruleGitlinkFullContract['SourceGraph'] = $ruleGitlinkSourceGraph
        if (& $completionContract @ruleGitlinkFullContract) {
            Add-Failure 'TEST-0129 source-bound FullMigration contract discarded an opaque governance gitlink without semantic migration evidence.'
        }
        $ruleGitlinkModifyContract =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'CleanStart' `
                -ProtocolSurfaces @($ruleGitlinkSourceGraph.protocolSurfaces) `
                -Changes @([pscustomobject]@{
                    Status = 'M'; Path = '.cursor/rules'
                }) `
                -AdditionalEntries @([pscustomobject]@{
                    Path = '.cursor/rules'; Exists = $true; Mode = '160000'
                })
        $ruleGitlinkModifyContract['SourceGraph'] = $ruleGitlinkSourceGraph
        if (& $completionContract @ruleGitlinkModifyContract) {
            Add-Failure 'TEST-0129 source-bound CleanStart contract accepted modification instead of deletion for an opaque governance gitlink.'
        }
        $ruleGitlinkUnapprovedContract =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'CleanStart' -ProtocolSurfaces @() `
                -Changes @($ruleGitlinkDeletion) `
                -AdditionalEntries @($ruleGitlinkAbsentEntry)
        $ruleGitlinkUnapprovedContract['SourceGraph'] = $ruleGitlinkSourceGraph
        if (& $completionContract @ruleGitlinkUnapprovedContract) {
            Add-Failure 'TEST-0129 source-bound CleanStart contract deleted a governance gitlink absent from approved surfaces.'
        }
        $ruleSymlinkSourceGraph = & $ruleGraphBuilder `
            -BaseHead ('d' * 40) -TreeEntries @([pscustomobject]@{
                Path = '.cursor/rules'
                Mode = '120000'
                Type = 'blob'
                Sha = 'e' * 40
            }) -ReadBlob { throw 'Terminal symlink evidence was dereferenced.' }
        $ruleSymlinkContract =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'CleanStart' `
                -ProtocolSurfaces @($ruleSymlinkSourceGraph.protocolSurfaces) `
                -Changes @($ruleGitlinkDeletion) `
                -AdditionalEntries @($ruleGitlinkAbsentEntry)
        $ruleSymlinkContract['SourceGraph'] = $ruleSymlinkSourceGraph
        if (& $completionContract @ruleSymlinkContract) {
            Add-Failure 'TEST-0129 source-bound CleanStart gitlink exception widened to a symlink.'
        }
        $ruleGitlinkCleanMainApp = (@(Invoke-TestGit `
            -Repository $ruleGitlinkCleanConsumer.Remote `
            -Arguments @('rev-parse', 'refs/heads/main:app.txt')))[0]
        $global:QuickAdoptionProposalMode = 'ValidFull'
        $env:MEANDAI_TEST_CODEX_MODE = 'CompleteCleanStartRuleGitlink'
        $ruleGitlinkCleanError = ''
        try {
            & $launcherPath -TargetPath $ruleGitlinkCleanConsumer.Repository `
                -AdoptionStrategy CleanStart -AcknowledgeProtocolRecordLoss `
                -NonInteractive -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $ruleGitlinkCleanError = $_.Exception.Message
        }
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'
        $ruleGitlinkCleanBranch =
            'refs/heads/automation/meandai-capabilities-v0.12.7'
        $ruleGitlinkCleanHeads = @(Invoke-TestGit `
            -Repository $ruleGitlinkCleanConsumer.Repository `
            -Arguments @('ls-remote', '--heads', 'origin', $ruleGitlinkCleanBranch))
        $ruleGitlinkCleanEntry = @()
        $ruleGitlinkCleanManifest = @()
        $ruleGitlinkCleanProtocolEntry = @()
        $ruleGitlinkCleanBranchApp = ''
        if ($ruleGitlinkCleanHeads.Count -eq 1) {
            $ruleGitlinkCleanEntry = @(Invoke-TestGit `
                -Repository $ruleGitlinkCleanConsumer.Remote `
                -Arguments @(
                    'ls-tree', $ruleGitlinkCleanBranch, '--', '.cursor/rules'
                ))
            $ruleGitlinkCleanManifest = @(Invoke-TestGit `
                -Repository $ruleGitlinkCleanConsumer.Remote `
                -Arguments @(
                    'ls-tree', $ruleGitlinkCleanBranch, '--',
                    '.ai/adoption/meandai-capabilities.json'
                ))
            $ruleGitlinkCleanProtocolEntry = @(Invoke-TestGit `
                -Repository $ruleGitlinkCleanConsumer.Remote `
                -Arguments @(
                    'ls-tree', $ruleGitlinkCleanBranch, '--', '.ai/protocol'
                ))
            $ruleGitlinkCleanBranchApp = (@(Invoke-TestGit `
                -Repository $ruleGitlinkCleanConsumer.Remote `
                -Arguments @(
                    'rev-parse', "$ruleGitlinkCleanBranch`:app.txt"
                )))[0]
        }
        if ($ruleGitlinkCleanError -or
            $ruleGitlinkCleanHeads.Count -ne 1 -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            @($global:QuickAdoptionProposalSurfaces) -cnotcontains
                '.cursor/rules' -or
            $ruleGitlinkCleanEntry.Count -ne 0 -or
            $ruleGitlinkCleanManifest.Count -ne 0 -or
            $ruleGitlinkCleanProtocolEntry.Count -ne 1 -or
            $ruleGitlinkCleanProtocolEntry[0] -cnotmatch
                "^160000 commit $global:QuickAdoptionProtocolSha`t\.ai/protocol$" -or
            $ruleGitlinkCleanBranchApp -cne $ruleGitlinkCleanMainApp) {
            Add-Failure "TEST-0129/TEST-0130 acknowledged CleanStart did not retire an exact-root .cursor/rules gitlink, preserve application content, and reach readiness: $ruleGitlinkCleanError"
        }

        $ruleGitlinkFullFixture =
            New-TestQuickAdoptionCompletionContractFixture `
                -Strategy 'FullMigration' `
                -ProtocolSurfaces @('.cursor/rules') `
                -AdditionalEntries @([pscustomobject]@{
                    Path = '.cursor/rules'; Exists = $true; Mode = '160000'
                })
        if (& $completionContract @ruleGitlinkFullFixture) {
            Add-Failure 'TEST-0129/TEST-0130 production completion contract accepted a retained exact-root .cursor/rules gitlink.'
        }
        }

    if ((Test-QuickAdoptionShard -Name 'RepositoryRoutes') -and
        $failures.Count -eq 0) {
        Reset-Mocks
        $completionContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Test-MeAndAICompletedAdoptionChangeSet'
        $strategyRoot = New-TempRoot -Name 'strategy-preflight'
        $strategyRepo = Join-Path $strategyRoot 'consumer'
        New-Item -ItemType Directory -Path $strategyRepo -Force | Out-Null
        & git init -b main $strategyRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $strategyRepo
        [IO.File]::WriteAllText(
            (Join-Path $strategyRepo 'app.txt'),
            "strategy consumer application`n",
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $strategyRepo 'AGENTS.md'),
            "# Existing consumer protocol`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $strategyRepo -Arguments @(
            'add', '--', 'app.txt', 'AGENTS.md'
        ) | Out-Null
        Invoke-TestGit -Repository $strategyRepo -Arguments @(
            'commit', '-m', 'Create protocol-aware adoption fixture'
        ) | Out-Null
        $strategyHead = (@(Invoke-TestGit -Repository $strategyRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $strategyApplicationHash = (Get-FileHash `
            -LiteralPath (Join-Path $strategyRepo 'app.txt') `
            -Algorithm SHA256).Hash
        $strategyExcludePath = Join-Path $strategyRepo '.git/info/exclude'
        $strategyExcludeBefore = [IO.File]::ReadAllText($strategyExcludePath)
        $strategyResolver = Get-TestQuickAdoptionContractCommand `
            -Name 'Resolve-MeAndAIAdoptionStrategy'

        $preflightCases = @(
            [pscustomobject]@{
                Name = 'Auto non-interactive ambiguity'
                Strategy = 'Auto'
                Acknowledge = $false
                ExpectedError = '*requires an explicit adoption strategy*'
            },
            [pscustomobject]@{
                Name = 'explicit fresh contradiction'
                Strategy = 'FreshAdoption'
                Acknowledge = $false
                ExpectedError = '*FreshAdoption contradicts detected*'
            },
            [pscustomobject]@{
                Name = 'unacknowledged clean start'
                Strategy = 'CleanStart'
                Acknowledge = $false
                ExpectedError = '*requires explicit acknowledgement*'
            }
        )
        foreach ($preflightCase in $preflightCases) {
            $contractStrategy = & $strategyResolver `
                -RequestedStrategy ([string]$preflightCase.Strategy) `
                -ProtocolSurfaces @('AGENTS.md') -Collisions @('AGENTS.md') `
                -AcknowledgeProtocolRecordLoss ([bool]$preflightCase.Acknowledge)
            $contractDiagnostic = @($contractStrategy.Diagnostics) -join ' '
            $expectedContractState = if (
                [string]$preflightCase.Strategy -ceq 'Auto'
            ) { 'ProtocolMigrationReviewRequired' } else { 'BlockedManualReview' }
            if ([string]$contractStrategy.State -cne $expectedContractState -or
                $contractDiagnostic -notlike
                    [string]$preflightCase.ExpectedError) {
                Add-Failure "TEST-0130 production strategy contract did not preserve '$($preflightCase.Name)': state=$($contractStrategy.State); diagnostic=$contractDiagnostic"
            }
        }

        # The pure table covers all policy outcomes. Auto ambiguity represents
        # the launcher authority-read and no-mutation adapter boundary.
        $representativePreflightCase = $preflightCases[0]
        $ghCallCountBefore = $global:QuickAdoptionGhCalls.Count
        $secretCountBefore = $global:QuickAdoptionSecrets.Count
        $preflightError = ''
        try {
            & $launcherPath -TargetPath $strategyRepo `
                -AdoptionStrategy ([string]$representativePreflightCase.Strategy) `
                -NonInteractive -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $preflightError = $_.Exception.Message
        }
        $newGhCalls = @($global:QuickAdoptionGhCalls |
            Select-Object -Skip $ghCallCountBefore)
        $preflightRemoteOrAuthMutation = @(
            Get-MockUnexpectedPreflightGhCalls -Calls $newGhCalls
        )
        $headAfterPreflight = (@(Invoke-TestGit -Repository $strategyRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $statusAfterPreflight = @(Invoke-TestGit -Repository $strategyRepo `
            -Arguments @('status', '--porcelain'))
        $applicationHashAfterPreflight = (Get-FileHash `
            -LiteralPath (Join-Path $strategyRepo 'app.txt') `
            -Algorithm SHA256).Hash
        if ($preflightError -notlike
                [string]$representativePreflightCase.ExpectedError -or
            $preflightRemoteOrAuthMutation.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBefore -or
            $headAfterPreflight -cne $strategyHead -or
            $statusAfterPreflight.Count -ne 0 -or
            $applicationHashAfterPreflight -cne $strategyApplicationHash -or
            (Test-Path -LiteralPath (
                Join-Path $strategyRepo $workflowRelativePath
            ))) {
            Add-Failure "TEST-0130 representative $($representativePreflightCase.Name) did not fail after canonical policy authority reads and before remote, secret, seed, or application mutation: $preflightError"
        }

        $noEvidenceRepo = Join-Path $strategyRoot 'no-protocol-evidence'
        New-Item -ItemType Directory -Path $noEvidenceRepo -Force | Out-Null
        & git init -b main $noEvidenceRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $noEvidenceRepo
        [IO.File]::WriteAllText(
            (Join-Path $noEvidenceRepo 'app.txt'),
            "evidence-free application`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $noEvidenceRepo -Arguments @(
            'add', '--', 'app.txt'
        ) | Out-Null
        Invoke-TestGit -Repository $noEvidenceRepo -Arguments @(
            'commit', '-m', 'Create evidence-free repository'
        ) | Out-Null
        $noEvidenceHead = (@(Invoke-TestGit -Repository $noEvidenceRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $noEvidenceStrategies = @(
            [pscustomobject]@{
                Name = 'FullMigration'
                Acknowledge = $false
            },
            [pscustomobject]@{
                Name = 'HybridReconciliation'
                Acknowledge = $false
            },
            [pscustomobject]@{
                Name = 'CleanStart'
                Acknowledge = $true
            }
        )
        foreach ($noEvidenceStrategy in $noEvidenceStrategies) {
            $noEvidenceContract = & $strategyResolver `
                -RequestedStrategy ([string]$noEvidenceStrategy.Name) `
                -ProtocolSurfaces @() -Collisions @() `
                -AcknowledgeProtocolRecordLoss ([bool]$noEvidenceStrategy.Acknowledge)
            $noEvidenceDiagnostic = @($noEvidenceContract.Diagnostics) -join ' '
            if ([string]$noEvidenceContract.State -cne 'BlockedManualReview' -or
                $noEvidenceDiagnostic -notlike
                    "$($noEvidenceStrategy.Name) requires detected protocol or governance evidence*") {
                Add-Failure "TEST-0130 production strategy contract did not preserve evidence-free $($noEvidenceStrategy.Name): state=$($noEvidenceContract.State); diagnostic=$noEvidenceDiagnostic"
            }
        }

        # FullMigration is the representative explicit-strategy wrapper slice;
        # the production contract table covers Hybrid and CleanStart variants.
        $representativeNoEvidenceStrategy = $noEvidenceStrategies[0]
        $noEvidenceGhBefore = $global:QuickAdoptionGhCalls.Count
        $noEvidenceSecretBefore = $global:QuickAdoptionSecrets.Count
        $noEvidenceParameters = @{
            TargetPath = $noEvidenceRepo
            AdoptionStrategy = [string]$representativeNoEvidenceStrategy.Name
            NonInteractive = $true
            CodexCommand = $mockCodexPath
        }
        $noEvidenceError = ''
        try {
            & $launcherPath @noEvidenceParameters | Out-Null
        }
        catch {
            $noEvidenceError = $_.Exception.Message
        }
        $noEvidenceGhMutations = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $noEvidenceGhBefore
            )
        )
        $noEvidenceHeadAfter = (@(Invoke-TestGit `
            -Repository $noEvidenceRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $noEvidenceStatusAfter = @(Invoke-TestGit `
            -Repository $noEvidenceRepo `
            -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
        if ($noEvidenceError -notlike
                "$($representativeNoEvidenceStrategy.Name) requires detected protocol or governance evidence*" -or
            $noEvidenceGhMutations.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne
                $noEvidenceSecretBefore -or
            $noEvidenceHeadAfter -cne $noEvidenceHead -or
            $noEvidenceStatusAfter.Count -ne 0 -or
            (Test-Path -LiteralPath (
                Join-Path $noEvidenceRepo $workflowRelativePath
            ))) {
            Add-Failure "TEST-0130 representative evidence-free explicit $($representativeNoEvidenceStrategy.Name) did not fail after canonical policy authority reads and before remote, secret, seed, or application mutation: $noEvidenceError"
        }

        $noHeadRepo = Join-Path $strategyRoot 'no-head-consumer'
        New-Item -ItemType Directory -Path (
            Join-Path $noHeadRepo 'src/module'
        ) -Force | Out-Null
        & git init -b main $noHeadRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $noHeadRepo
        [IO.File]::WriteAllText(
            (Join-Path $noHeadRepo 'src/module/AGENTS.md'),
            "# Uncommitted scoped protocol authority`n",
            [Text.UTF8Encoding]::new($false)
        )
        $noHeadGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $noHeadExcludePath = Join-Path $noHeadRepo '.git/info/exclude'
        $noHeadExcludeBefore = [IO.File]::ReadAllText($noHeadExcludePath)
        $noHeadStatusBefore = @(Invoke-TestGit -Repository $noHeadRepo `
            -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
        $noHeadError = ''
        try {
            & $launcherPath -TargetPath $noHeadRepo -AdoptionStrategy Auto `
                -NonInteractive -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $noHeadError = $_.Exception.Message
        }
        $noHeadPreAuthCalls = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $noHeadGhCountBefore
            )
        )
        $noHeadStatusAfter = @(Invoke-TestGit -Repository $noHeadRepo `
            -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
        if ($noHeadError -notlike
                "*repository without a committed HEAD*Unexpected path: 'src/module/AGENTS.md'*" -or
            $noHeadPreAuthCalls.Count -ne 0 -or
            [IO.File]::ReadAllText($noHeadExcludePath) -cne $noHeadExcludeBefore -or
            ($noHeadStatusAfter -join "`n") -cne ($noHeadStatusBefore -join "`n")) {
            Add-Failure "TEST-0130 bounded no-HEAD traversal did not detect an arbitrary scoped AGENTS.md after canonical policy authority reads and before exclude or working-tree mutation: $noHeadError"
        }

        $noHeadWorkflowRepo = Join-Path $strategyRoot 'no-head-workflow-case'
        New-Item -ItemType Directory -Path (
            Join-Path $noHeadWorkflowRepo '.github/workflows'
        ) -Force | Out-Null
        & git init -b main $noHeadWorkflowRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $noHeadWorkflowRepo
        $caseVariantWorkflowPath =
            '.github/workflows/MeAndAI-protocol-update.yml'
        [IO.File]::WriteAllBytes(
            (Join-Path $noHeadWorkflowRepo $caseVariantWorkflowPath),
            $global:QuickAdoptionWorkflowBytes
        )
        $noHeadWorkflowGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $noHeadWorkflowExcludePath =
            Join-Path $noHeadWorkflowRepo '.git/info/exclude'
        $noHeadWorkflowExcludeBefore =
            [IO.File]::ReadAllText($noHeadWorkflowExcludePath)
        $noHeadWorkflowStatusBefore = @(Invoke-TestGit `
            -Repository $noHeadWorkflowRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        $noHeadWorkflowError = ''
        try {
            & $launcherPath -TargetPath $noHeadWorkflowRepo `
                -AdoptionStrategy Auto -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $noHeadWorkflowError = $_.Exception.Message
        }
        $noHeadWorkflowPreAuthCalls = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $noHeadWorkflowGhCountBefore
            )
        )
        $noHeadWorkflowStatusAfter = @(Invoke-TestGit `
            -Repository $noHeadWorkflowRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        if ($noHeadWorkflowError -notlike
                "*uses noncanonical casing for adoption path '$workflowRelativePath'*" -or
            $noHeadWorkflowPreAuthCalls.Count -ne 0 -or
            [IO.File]::ReadAllText($noHeadWorkflowExcludePath) -cne
                $noHeadWorkflowExcludeBefore -or
            ($noHeadWorkflowStatusAfter -join "`n") -cne
                ($noHeadWorkflowStatusBefore -join "`n")) {
            Add-Failure "TEST-0129 no-HEAD case-variant lifecycle workflow was not rejected after canonical policy authority reads and before exclude or working-tree mutation: $noHeadWorkflowError"
        }

        $noHeadCanonicalCaseRepo = Join-Path `
            $strategyRoot 'no-head-canonical-case'
        New-Item -ItemType Directory -Path (
            Join-Path $noHeadCanonicalCaseRepo '.AI/memory'
        ) -Force | Out-Null
        & git init -b main $noHeadCanonicalCaseRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $noHeadCanonicalCaseRepo
        [IO.File]::WriteAllText(
            (Join-Path $noHeadCanonicalCaseRepo '.AI/memory/project.md'),
            "# Case-variant protocol memory`n",
            [Text.UTF8Encoding]::new($false)
        )
        $canonicalCaseGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $canonicalCaseExcludePath = Join-Path `
            $noHeadCanonicalCaseRepo '.git/info/exclude'
        $canonicalCaseExcludeBefore =
            [IO.File]::ReadAllText($canonicalCaseExcludePath)
        $canonicalCaseStatusBefore = @(Invoke-TestGit `
            -Repository $noHeadCanonicalCaseRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        $canonicalCaseError = ''
        try {
            & $launcherPath -TargetPath $noHeadCanonicalCaseRepo `
                -AdoptionStrategy Auto -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $canonicalCaseError = $_.Exception.Message
        }
        $canonicalCaseGhMutations = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $canonicalCaseGhCountBefore
            )
        )
        $canonicalCaseStatusAfter = @(Invoke-TestGit `
            -Repository $noHeadCanonicalCaseRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        if ($canonicalCaseError -notlike
                "*uses noncanonical casing for adoption path '.ai/*" -or
            $canonicalCaseGhMutations.Count -ne 0 -or
            [IO.File]::ReadAllText($canonicalCaseExcludePath) -cne
                $canonicalCaseExcludeBefore -or
            ($canonicalCaseStatusAfter -join "`n") -cne
                ($canonicalCaseStatusBefore -join "`n")) {
            Add-Failure "TEST-0129 generic canonical-target casing drift was not rejected after canonical policy authority reads and before exclude or working-tree mutation: $canonicalCaseError"
        }

        $noHeadLinkRepo = Join-Path $strategyRoot 'no-head-linked-app'
        $noHeadLinkTarget = Join-Path $strategyRoot 'linked-app-target'
        New-Item -ItemType Directory -Path $noHeadLinkRepo -Force |
            Out-Null
        New-Item -ItemType Directory -Path $noHeadLinkTarget -Force |
            Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $noHeadLinkTarget 'app.txt'),
            "linked application content`n",
            [Text.UTF8Encoding]::new($false)
        )
        & git init -b main $noHeadLinkRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $noHeadLinkRepo
        New-TestDirectoryLink -Path (Join-Path $noHeadLinkRepo 'src') `
            -Target $noHeadLinkTarget
        $noHeadLinkGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $noHeadLinkExcludePath = Join-Path `
            $noHeadLinkRepo '.git/info/exclude'
        $noHeadLinkExcludeBefore =
            [IO.File]::ReadAllText($noHeadLinkExcludePath)
        $noHeadLinkStatusBefore = @(Invoke-TestGit `
            -Repository $noHeadLinkRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        $noHeadLinkError = ''
        try {
            & $launcherPath -TargetPath $noHeadLinkRepo `
                -AdoptionStrategy Auto -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $noHeadLinkError = $_.Exception.Message
        }
        $noHeadLinkGhMutations = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $noHeadLinkGhCountBefore
            )
        )
        $noHeadLinkStatusAfter = @(Invoke-TestGit `
            -Repository $noHeadLinkRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        if ($noHeadLinkError -notlike
                "*linked directory 'src' must be removed*" -or
            $noHeadLinkGhMutations.Count -ne 0 -or
            [IO.File]::ReadAllText($noHeadLinkExcludePath) -cne
                $noHeadLinkExcludeBefore -or
            ($noHeadLinkStatusAfter -join "`n") -cne
                ($noHeadLinkStatusBefore -join "`n") -or
            (Test-Path -LiteralPath (
                Join-Path $noHeadLinkRepo $workflowRelativePath
            ))) {
            Add-Failure "TEST-0130 no-HEAD linked application directory did not fail after canonical policy authority reads and before repo, secret, seed, exclude, or working-tree mutation: $noHeadLinkError"
        }

        $tokenLinkRepo = Join-Path $strategyRoot 'linked-token-file'
        $tokenLinkTarget = Join-Path $strategyRoot 'linked-token-target'
        New-Item -ItemType Directory -Path $tokenLinkRepo -Force |
            Out-Null
        New-Item -ItemType Directory -Path $tokenLinkTarget -Force |
            Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $tokenLinkTarget 'value.txt'),
            "linked token placeholder`n",
            [Text.UTF8Encoding]::new($false)
        )
        & git init -b main $tokenLinkRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $tokenLinkRepo
        New-TestDirectoryLink -Path (Join-Path $tokenLinkRepo 'FG_PAT.txt') `
            -Target $tokenLinkTarget
        [IO.File]::WriteAllText(
            (Join-Path $tokenLinkRepo 'MEANDAI_RO_FG_PAT.txt'),
            'read-token-value',
            [Text.UTF8Encoding]::new($false)
        )
        $tokenLinkGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $tokenLinkExcludePath = Join-Path `
            $tokenLinkRepo '.git/info/exclude'
        $tokenLinkExcludeBefore =
            [IO.File]::ReadAllText($tokenLinkExcludePath)
        $tokenLinkStatusBefore = @(Invoke-TestGit `
            -Repository $tokenLinkRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        $tokenLinkError = ''
        try {
            & $launcherPath -TargetPath $tokenLinkRepo `
                -AdoptionStrategy Auto -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $tokenLinkError = $_.Exception.Message
        }
        $tokenLinkGhMutations = @(
            $global:QuickAdoptionGhCalls |
                Select-Object -Skip $tokenLinkGhCountBefore |
                Where-Object {
                    $_.Arguments.Count -ne 1 -or
                    $_.Arguments[0] -cne '--version'
                }
        )
        $tokenLinkStatusAfter = @(Invoke-TestGit `
            -Repository $tokenLinkRepo -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        if ($tokenLinkError -notlike
                "*Managed destination 'FG_PAT.txt' traverses linked or reparse-point path 'FG_PAT.txt'*" -or
            $tokenLinkGhMutations.Count -ne 0 -or
            [IO.File]::ReadAllText($tokenLinkExcludePath) -cne
                $tokenLinkExcludeBefore -or
            ($tokenLinkStatusAfter -join "`n") -cne
                ($tokenLinkStatusBefore -join "`n") -or
            (Test-Path -LiteralPath (
                Join-Path $tokenLinkRepo $workflowRelativePath
            ))) {
            Add-Failure "TEST-0130 linked credential root path did not fail before auth, repo, secret, seed, exclude, or working-tree mutation: $tokenLinkError"
        }

        foreach ($tokenFileLinkCase in @(
            [pscustomobject]@{
                Name = 'write-no-head'
                Token = 'FG_PAT.txt'
                OtherToken = 'MEANDAI_RO_FG_PAT.txt'
                WithHead = $false
            },
            [pscustomobject]@{
                Name = 'read-with-head'
                Token = 'MEANDAI_RO_FG_PAT.txt'
                OtherToken = 'FG_PAT.txt'
                WithHead = $true
            }
        )) {
            $tokenFileLinkRepo = Join-Path $strategyRoot `
                "token-file-link-$($tokenFileLinkCase.Name)"
            $tokenFileLinkTarget = Join-Path $strategyRoot `
                "token-file-link-$($tokenFileLinkCase.Name).txt"
            New-Item -ItemType Directory -Path $tokenFileLinkRepo -Force |
                Out-Null
            [IO.File]::WriteAllText(
                $tokenFileLinkTarget,
                "linked token placeholder`n",
                [Text.UTF8Encoding]::new($false)
            )
            & git init -b main $tokenFileLinkRepo 2>&1 | Out-Null
            Set-TestGitIdentity -Repository $tokenFileLinkRepo
            if ([bool]$tokenFileLinkCase.WithHead) {
                [IO.File]::WriteAllText(
                    (Join-Path $tokenFileLinkRepo 'app.txt'),
                    "consumer app`n",
                    [Text.UTF8Encoding]::new($false)
                )
                Invoke-TestGit -Repository $tokenFileLinkRepo -Arguments @(
                    'add', '--', 'app.txt'
                ) | Out-Null
                Invoke-TestGit -Repository $tokenFileLinkRepo -Arguments @(
                    'commit', '-m', 'Create token-link HEAD fixture'
                ) | Out-Null
            }
            [IO.File]::WriteAllText(
                (Join-Path $tokenFileLinkRepo `
                    ([string]$tokenFileLinkCase.OtherToken)),
                'regular-token-placeholder',
                [Text.UTF8Encoding]::new($false)
            )
            New-TestFileLink -Path (
                Join-Path $tokenFileLinkRepo `
                    ([string]$tokenFileLinkCase.Token)
            ) -Target $tokenFileLinkTarget
            $tokenFileLinkGhBefore = $global:QuickAdoptionGhCalls.Count
            $tokenFileLinkExcludePath = Join-Path `
                $tokenFileLinkRepo '.git/info/exclude'
            $tokenFileLinkExcludeBefore =
                [IO.File]::ReadAllText($tokenFileLinkExcludePath)
            $tokenFileLinkStatusBefore = @(Invoke-TestGit `
                -Repository $tokenFileLinkRepo -Arguments @(
                    'status', '--porcelain=v1', '--untracked-files=all'
                ))
            $tokenFileLinkError = ''
            try {
                & $launcherPath -TargetPath $tokenFileLinkRepo `
                    -AdoptionStrategy Auto -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $tokenFileLinkError = $_.Exception.Message
            }
            $tokenFileLinkGhMutations = @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $tokenFileLinkGhBefore |
                    Where-Object {
                        $_.Arguments.Count -ne 1 -or
                        $_.Arguments[0] -cne '--version'
                    }
            )
            $tokenFileLinkStatusAfter = @(Invoke-TestGit `
                -Repository $tokenFileLinkRepo -Arguments @(
                    'status', '--porcelain=v1', '--untracked-files=all'
                ))
            $tokenFileLinkContainmentError =
                "*Managed destination '$($tokenFileLinkCase.Token)' traverses linked or reparse-point path '$($tokenFileLinkCase.Token)'*"
            $tokenFileLinkRegularError =
                "*Credential path '$($tokenFileLinkCase.Token)' must be one regular root file*"
            $tokenFileLinkRejected =
                $tokenFileLinkError -like $tokenFileLinkContainmentError -or
                $tokenFileLinkError -like $tokenFileLinkRegularError
            if (-not $tokenFileLinkRejected -or
                $tokenFileLinkGhMutations.Count -ne 0 -or
                [IO.File]::ReadAllText($tokenFileLinkExcludePath) -cne
                    $tokenFileLinkExcludeBefore -or
                ($tokenFileLinkStatusAfter -join "`n") -cne
                    ($tokenFileLinkStatusBefore -join "`n") -or
                (Test-Path -LiteralPath (
                    Join-Path $tokenFileLinkRepo $workflowRelativePath
                ))) {
                Add-Failure "TEST-0130 $($tokenFileLinkCase.Name) canonical token file symlink was not rejected before auth, exclude, GitHub, seed, or checkout mutation: $tokenFileLinkError"
            }
        }

        Reset-Mocks
        $reservedSubmoduleConsumer = New-MockConnectedSeedConsumer `
            -Name 'reserved-product-submodule' -OmitWorkflowSeed
        $reservedGitmodulesPath = Join-Path `
            $reservedSubmoduleConsumer.Repository '.gitmodules'
        [IO.File]::WriteAllText(
            $reservedGitmodulesPath,
            @(
                '[submodule ".ai/protocol"]',
                "`tpath = vendor/product",
                "`turl = https://example.invalid/product.git",
                ''
            ) -join "`n",
            [Text.UTF8Encoding]::new($false)
        )
        Invoke-TestGit -Repository $reservedSubmoduleConsumer.Repository `
            -Arguments @('add', '--', '.gitmodules') | Out-Null
        Invoke-TestGit -Repository $reservedSubmoduleConsumer.Repository `
            -Arguments @(
                'commit', '-m', 'Reserve protocol subsection for product path'
            ) | Out-Null
        Invoke-TestGit -Repository $reservedSubmoduleConsumer.Repository `
            -Arguments @('push', 'origin', 'main') | Out-Null
        $reservedHeadBefore = (@(Invoke-TestGit `
            -Repository $reservedSubmoduleConsumer.Repository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $reservedGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $reservedSecretCountBefore = $global:QuickAdoptionSecrets.Count
        $reservedSubmoduleError = ''
        try {
            & $launcherPath `
                -TargetPath $reservedSubmoduleConsumer.Repository `
                -AdoptionStrategy FreshAdoption -NonInteractive `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $reservedSubmoduleError = $_.Exception.Message
        }
        $reservedGhMutations = @(
            Get-MockUnexpectedPreflightGhCalls -Calls @(
                $global:QuickAdoptionGhCalls |
                    Select-Object -Skip $reservedGhCountBefore
            )
        )
        $reservedHeadAfter = (@(Invoke-TestGit `
            -Repository $reservedSubmoduleConsumer.Repository -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        if ($reservedSubmoduleError -notlike
                "*reserved .gitmodules subsection '.ai/protocol'*" -or
            $reservedGhMutations.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne
                $reservedSecretCountBefore -or
            $reservedHeadAfter -cne $reservedHeadBefore) {
            Add-Failure "TEST-0129 reserved protocol subsection pointing at a product path did not fail after canonical policy authority reads and before Git or secret mutation: $reservedSubmoduleError"
        }

        # Case, ancestor, and descendant alias variants are exhaustively owned
        # by Test-MeAndAIReservedProtocolSubmoduleContract. Keep one real Git
        # config extraction and launcher translation slice.
        foreach ($reservedAliasCase in @(
            [pscustomobject]@{
                Name = 'alias-exact-path'
                Section = 'legacy'
                Path = '.ai/protocol'
            }
        )) {
            Reset-Mocks
            $reservedAliasConsumer = New-MockConnectedSeedConsumer `
                -Name "reserved-$($reservedAliasCase.Name)" `
                -OmitWorkflowSeed
            $reservedAliasGitmodules = Join-Path `
                $reservedAliasConsumer.Repository '.gitmodules'
            [IO.File]::WriteAllText(
                $reservedAliasGitmodules,
                @(
                    "[submodule `"$($reservedAliasCase.Section)`"]",
                    "`tpath = $($reservedAliasCase.Path)",
                    "`turl = https://example.invalid/product.git",
                    ''
                ) -join "`n",
                [Text.UTF8Encoding]::new($false)
            )
            Invoke-TestGit -Repository $reservedAliasConsumer.Repository `
                -Arguments @('add', '--', '.gitmodules') | Out-Null
            Invoke-TestGit -Repository $reservedAliasConsumer.Repository `
                -Arguments @(
                    'commit', '-m',
                    "Add $($reservedAliasCase.Name) submodule conflict"
                ) | Out-Null
            Invoke-TestGit -Repository $reservedAliasConsumer.Repository `
                -Arguments @('push', 'origin', 'main') | Out-Null
            $reservedAliasHeadBefore = (@(Invoke-TestGit `
                -Repository $reservedAliasConsumer.Repository `
                -Arguments @('rev-parse', 'HEAD')))[0]
            $reservedAliasGhCountBefore =
                $global:QuickAdoptionGhCalls.Count
            $reservedAliasSecretCountBefore =
                $global:QuickAdoptionSecrets.Count
            $reservedAliasError = ''
            try {
                & $launcherPath `
                    -TargetPath $reservedAliasConsumer.Repository `
                    -AdoptionStrategy FreshAdoption -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $reservedAliasError = $_.Exception.Message
            }
            $reservedAliasGhMutations = @(
                Get-MockUnexpectedPreflightGhCalls -Calls @(
                    $global:QuickAdoptionGhCalls |
                        Select-Object -Skip $reservedAliasGhCountBefore
                )
            )
            $reservedAliasHeadAfter = (@(Invoke-TestGit `
                -Repository $reservedAliasConsumer.Repository `
                -Arguments @('rev-parse', 'HEAD')))[0]
            if ($reservedAliasError -notlike
                    "*reserved .gitmodules subsection '.ai/protocol'*" -or
                $reservedAliasGhMutations.Count -ne 0 -or
                $global:QuickAdoptionSecrets.Count -ne
                    $reservedAliasSecretCountBefore -or
                $reservedAliasHeadAfter -cne
                    $reservedAliasHeadBefore) {
                Add-Failure "TEST-0129 reserved submodule conflict $($reservedAliasCase.Name) did not fail after canonical policy authority reads and before Git or secret mutation: $reservedAliasError"
            }
        }

        $reservedEvidenceCases = @(
            [pscustomobject]@{
                Name = 'protocol-directory'
                Path = '.ai/protocol/legacy.md'
            },
            [pscustomobject]@{
                Name = 'migration-ledger'
                Path = '.ai/meandai-update-state.json'
            },
            [pscustomobject]@{
                Name = 'github-instruction'
                Path = '.github/instructions/legacy.instructions.md'
            }
        )
        $surfaceInventoryContract = Get-TestQuickAdoptionContractCommand `
            -Name 'Get-MeAndAIProtocolSurfaceInventory'
        foreach ($reservedEvidenceContractCase in @(
            $reservedEvidenceCases | Select-Object -Skip 1
        )) {
            $contractSurfaces = @(& $surfaceInventoryContract `
                -Paths @([string]$reservedEvidenceContractCase.Path))
            $contractResolution = & $strategyResolver `
                -RequestedStrategy 'Auto' `
                -ProtocolSurfaces $contractSurfaces -Collisions @() `
                -AcknowledgeProtocolRecordLoss $false
            if (($contractSurfaces -join "`n") -cne
                    [string]$reservedEvidenceContractCase.Path -or
                [string]$contractResolution.State -cne
                    'ProtocolMigrationReviewRequired') {
                Add-Failure "TEST-0130 production inventory/strategy contracts accepted false freshness for '$($reservedEvidenceContractCase.Name)'."
            }
        }

        # Keep a nested protocol path as the real repository-inventory slice.
        foreach ($reservedEvidenceCase in @(
            $reservedEvidenceCases | Select-Object -First 1
        )) {
            Reset-Mocks
            $reservedEvidenceConsumer = New-MockConnectedSeedConsumer `
                -Name "reserved-$($reservedEvidenceCase.Name)" `
                -OmitWorkflowSeed
            $reservedEvidencePath = Join-Path `
                $reservedEvidenceConsumer.Repository `
                ([string]$reservedEvidenceCase.Path)
            New-Item -ItemType Directory -Path (
                Split-Path -Parent $reservedEvidencePath
            ) -Force | Out-Null
            [IO.File]::WriteAllText(
                $reservedEvidencePath,
                "reserved protocol evidence`n",
                [Text.UTF8Encoding]::new($false)
            )
            Invoke-TestGit -Repository $reservedEvidenceConsumer.Repository `
                -Arguments @(
                    'add', '--', [string]$reservedEvidenceCase.Path
                ) | Out-Null
            Invoke-TestGit -Repository $reservedEvidenceConsumer.Repository `
                -Arguments @(
                    'commit', '-m',
                    "Add $($reservedEvidenceCase.Name) evidence"
                ) | Out-Null
            Invoke-TestGit -Repository $reservedEvidenceConsumer.Repository `
                -Arguments @('push', 'origin', 'main') | Out-Null
            $reservedEvidenceHeadBefore = (@(Invoke-TestGit `
                -Repository $reservedEvidenceConsumer.Repository `
                -Arguments @('rev-parse', 'HEAD')))[0]
            $reservedEvidenceGhCountBefore =
                $global:QuickAdoptionGhCalls.Count
            $reservedEvidenceSecretCountBefore =
                $global:QuickAdoptionSecrets.Count
            $reservedEvidenceError = ''
            try {
                & $launcherPath `
                    -TargetPath $reservedEvidenceConsumer.Repository `
                    -AdoptionStrategy Auto -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $reservedEvidenceError = $_.Exception.Message
            }
            $reservedEvidenceGhMutations = @(
                Get-MockUnexpectedPreflightGhCalls -Calls @(
                    $global:QuickAdoptionGhCalls |
                        Select-Object -Skip $reservedEvidenceGhCountBefore
                )
            )
            $reservedEvidenceHeadAfter = (@(Invoke-TestGit `
                -Repository $reservedEvidenceConsumer.Repository `
                -Arguments @('rev-parse', 'HEAD')))[0]
            if ($reservedEvidenceError -notlike
                    '*requires an explicit adoption strategy in non-interactive mode*' -or
                $reservedEvidenceGhMutations.Count -ne 0 -or
                $global:QuickAdoptionSecrets.Count -ne
                    $reservedEvidenceSecretCountBefore -or
                $reservedEvidenceHeadAfter -cne
                    $reservedEvidenceHeadBefore -or
                (Test-Path -LiteralPath (
                    Join-Path $reservedEvidenceConsumer.Repository `
                        $workflowRelativePath
                ))) {
                Add-Failure "TEST-0130 Auto false-freshness accepted $($reservedEvidenceCase.Path) or mutated state before explicit migration selection: $reservedEvidenceError"
            }
        }

        $cleanProtocolPath = '.ai/protocol/legacy.md'
        $cleanProtocolSurfaces = @(& $surfaceInventoryContract `
            -Paths @($cleanProtocolPath))
        $cleanProtocolResolution = & $strategyResolver `
            -RequestedStrategy 'CleanStart' `
            -ProtocolSurfaces $cleanProtocolSurfaces -Collisions @() `
            -AcknowledgeProtocolRecordLoss $true
        if ([string]$cleanProtocolResolution.State -cne 'Resolved' -or
            [string]$cleanProtocolResolution.AdoptionStrategy -cne
                'CleanStart' -or
            (@($cleanProtocolResolution.ProtocolSurfaces) -join "`n") -cne
                $cleanProtocolPath -or
            -not [bool]$cleanProtocolResolution.ProtocolRecordLossAcknowledged) {
            Add-Failure 'TEST-0129 production inventory/strategy contracts did not preserve acknowledged CleanStart protocol-directory evidence.'
        }

        $abortGhCountBefore = $global:QuickAdoptionGhCalls.Count
        $abortSecretCountBefore = $global:QuickAdoptionSecrets.Count
        $abortError = ''
        try {
            & $launcherPath -TargetPath $strategyRepo -AdoptionStrategy Abort `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $abortError = $_.Exception.Message
        }
        $abortHeadAfter = (@(Invoke-TestGit -Repository $strategyRepo `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $abortStatusAfter = @(Invoke-TestGit -Repository $strategyRepo `
            -Arguments @('status', '--porcelain'))
        $abortApplicationHashAfter = (Get-FileHash `
            -LiteralPath (Join-Path $strategyRepo 'app.txt') `
            -Algorithm SHA256).Hash
        if ($abortError -or
            $global:QuickAdoptionGhCalls.Count -ne $abortGhCountBefore -or
            $global:QuickAdoptionSecrets.Count -ne $abortSecretCountBefore -or
            $abortHeadAfter -cne $strategyHead -or
            $abortStatusAfter.Count -ne 0 -or
            $abortApplicationHashAfter -cne $strategyApplicationHash -or
            [IO.File]::ReadAllText($strategyExcludePath) -cne
                $strategyExcludeBefore -or
            (Test-Path -LiteralPath (
                Join-Path $strategyRepo $workflowRelativePath
            ))) {
            Add-Failure "TEST-0130 Abort was not a no-op before Git and GitHub mutation: $abortError"
        }

        foreach ($strategyCase in @(
            [pscustomobject]@{
                Strategy = 'HybridReconciliation'
                Acknowledge = $false
                PromptContract = 'Reconcile selected existing structures under a consumer-owned decision'
            },
            [pscustomobject]@{
                Strategy = 'CleanStart'
                Acknowledge = $true
                PromptContract = 'Import no legacy governance semantics.'
            }
        )) {
            Reset-Mocks
            $strategyConsumer = New-MockConnectedSeedConsumer `
                -Name "strategy-$(([string]$strategyCase.Strategy).ToLowerInvariant())" `
                -OmitWorkflowSeed
            $strategyLegacyPath =
                "docs/governance/$(([string]$strategyCase.Strategy).ToLowerInvariant()).md"
            New-Item -ItemType Directory -Path (
                Split-Path -Parent (
                    Join-Path $strategyConsumer.Repository $strategyLegacyPath
                )
            ) -Force | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $strategyConsumer.Repository 'AGENTS.md'),
                "# Existing strategy authority`n",
                [Text.UTF8Encoding]::new($false)
            )
            [IO.File]::WriteAllText(
                (Join-Path $strategyConsumer.Repository 'PROTOCOL.md'),
                "# Existing common protocol authority`n",
                [Text.UTF8Encoding]::new($false)
            )
            [IO.File]::WriteAllText(
                (Join-Path $strategyConsumer.Repository $strategyLegacyPath),
                "# Existing repository governance`n",
                [Text.UTF8Encoding]::new($false)
            )
            $strategyGitHubInstructionPath =
                '.github/instructions/legacy.instructions.md'
            New-Item -ItemType Directory -Path (
                Split-Path -Parent (
                    Join-Path $strategyConsumer.Repository `
                        $strategyGitHubInstructionPath
                )
            ) -Force | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $strategyConsumer.Repository `
                    $strategyGitHubInstructionPath),
                "# Existing GitHub instruction authority`n",
                [Text.UTF8Encoding]::new($false)
            )
            $strategyTrackedPaths = @(
                'AGENTS.md', 'PROTOCOL.md', $strategyLegacyPath,
                $strategyGitHubInstructionPath
            )
            $strategyCleanBaseline = $null
            if ([string]$strategyCase.Strategy -ceq 'CleanStart') {
                $strategyMemoryPath = '.ai/memory/project.md'
                New-Item -ItemType Directory -Path (
                    Split-Path -Parent (
                        Join-Path $strategyConsumer.Repository $strategyMemoryPath
                    )
                ) -Force | Out-Null
                [IO.File]::WriteAllText(
                    (Join-Path $strategyConsumer.Repository $strategyMemoryPath),
                    "# Existing memory semantics that CleanStart must not retain`n",
                    [Text.UTF8Encoding]::new($false)
                )
                $strategyCleanBaseline = Get-MockConsumerMigrationBaseline
                $strategyLedgerPath = [string]$strategyCleanBaseline.Path
                New-Item -ItemType Directory -Path (
                    Split-Path -Parent (
                        Join-Path $strategyConsumer.Repository $strategyLedgerPath
                    )
                ) -Force | Out-Null
                [IO.File]::WriteAllBytes(
                    (Join-Path $strategyConsumer.Repository $strategyLedgerPath),
                    [byte[]]$strategyCleanBaseline.Bytes
                )
                $strategyAiWorkIndexPath = 'ai/WORK_INDEX.md'
                New-Item -ItemType Directory -Path (
                    Split-Path -Parent (
                        Join-Path $strategyConsumer.Repository `
                            $strategyAiWorkIndexPath
                    )
                ) -Force | Out-Null
                [IO.File]::WriteAllText(
                    (Join-Path $strategyConsumer.Repository `
                        $strategyAiWorkIndexPath),
                    "# Existing AI work index`n",
                    [Text.UTF8Encoding]::new($false)
                )
                $strategyTrackedPaths += @(
                    $strategyMemoryPath, $strategyLedgerPath,
                    $strategyAiWorkIndexPath
                )
            }
            Invoke-TestGit -Repository $strategyConsumer.Repository `
                -Arguments (@('add', '--') + $strategyTrackedPaths) | Out-Null
            Invoke-TestGit -Repository $strategyConsumer.Repository -Arguments @(
                'commit', '-m', "Add $($strategyCase.Strategy) evidence"
            ) | Out-Null
            Invoke-TestGit -Repository $strategyConsumer.Repository -Arguments @(
                'push', 'origin', 'main'
            ) | Out-Null
            $expectedStrategySurfaces = @(
                Get-TestProtocolSurfaceInventory -Paths $strategyTrackedPaths
            )
            $strategyApplicationHashBefore = (Get-FileHash `
                -LiteralPath (Join-Path $strategyConsumer.Repository 'app.txt') `
                -Algorithm SHA256).Hash
            $strategyMainApplicationBlob = (@(Invoke-TestGit `
                -Repository $strategyConsumer.Remote -Arguments @(
                    'rev-parse', 'refs/heads/main:app.txt'
                )))[0]
            $global:QuickAdoptionProposalMode = 'ManifestOnly'
            $env:MEANDAI_TEST_CODEX_MODE = 'LeaveManifest'
            $strategyParameters = @{
                TargetPath = $strategyConsumer.Repository
                AdoptionStrategy = [string]$strategyCase.Strategy
                NonInteractive = $true
                CodexCommand = $mockCodexPath
            }
            if ([bool]$strategyCase.Acknowledge) {
                $strategyParameters['AcknowledgeProtocolRecordLoss'] = $true
            }
            $strategyBoundError = ''
            $strategyBoundStack = ''
            try {
                & $launcherPath @strategyParameters | Out-Null
            }
            catch {
                $strategyBoundError = $_.Exception.Message
                $strategyBoundStack = $_.ScriptStackTrace
            }
            $env:MEANDAI_TEST_CODEX_MODE = 'Success'
            $strategyExecCalls = @(Get-MockCodexCalls | Where-Object {
                $_.Arguments.Count -gt 0 -and $_.Arguments[0] -ceq 'exec'
            })
            $strategyPrompt = if ($strategyExecCalls.Count -eq 1) {
                [string]$strategyExecCalls[0].Stdin
            }
            else { '' }
            $strategyIssueBody = if ($null -ne $global:QuickAdoptionIssue) {
                [string]$global:QuickAdoptionIssue.body
            }
            else { '' }
            $strategyApplicationHashAfter = (Get-FileHash `
                -LiteralPath (Join-Path $strategyConsumer.Repository 'app.txt') `
                -Algorithm SHA256).Hash
            $strategyPublishedBaseSha = (@(Invoke-TestGit `
                -Repository $strategyConsumer.Remote -Arguments @(
                    'rev-parse', 'refs/heads/main'
                )))[0]
            $strategyBranchApplicationBlob = (@(Invoke-TestGit `
                -Repository $strategyConsumer.Remote -Arguments @(
                    'rev-parse',
                    'refs/heads/automation/meandai-capabilities-v0.12.7:app.txt'
                )))[0]
            $strategyMissingIssueSurfaces = @(
                $expectedStrategySurfaces | Where-Object {
                    -not $strategyIssueBody.Contains([string]$_)
                }
            )
            if ($strategyBoundError -notlike
                    '*declared readiness but left the transient adoption manifest*' -or
                $null -eq $global:QuickAdoptionDispatchRecord -or
                [string]$global:QuickAdoptionDispatchRecord.AdoptionStrategy -cne
                    [string]$strategyCase.Strategy -or
                [string]$global:QuickAdoptionDispatchRecord.ExpectedBaseSha -cne
                    $strategyPublishedBaseSha -or
                [bool]$global:QuickAdoptionDispatchRecord.ProtocolRecordLossAcknowledged -ne
                    [bool]$strategyCase.Acknowledge -or
                (@($global:QuickAdoptionProposalSurfaces) -join "`n") -cne
                    ($expectedStrategySurfaces -join "`n") -or
                $strategyExecCalls.Count -ne 1 -or
                -not $strategyPrompt.Contains([string]$strategyCase.PromptContract) -or
                -not $strategyIssueBody.Contains(
                    "- Adoption strategy: ``$($strategyCase.Strategy)``"
                ) -or
                $strategyMissingIssueSurfaces.Count -ne 0 -or
                $strategyApplicationHashAfter -cne
                    $strategyApplicationHashBefore -or
                $strategyBranchApplicationBlob -cne
                    $strategyMainApplicationBlob -or
                $global:QuickAdoptionPrReadyCalls -ne 0) {
                $strategyBoundDiagnostics = @(
                    "dispatchStrategy='$([string]$global:QuickAdoptionDispatchRecord.AdoptionStrategy)'",
                    "expectedStrategy='$([string]$strategyCase.Strategy)'",
                    "dispatchBase='$([string]$global:QuickAdoptionDispatchRecord.ExpectedBaseSha)'",
                    "publishedBase='$strategyPublishedBaseSha'",
                    "dispatchLoss='$([string]$global:QuickAdoptionDispatchRecord.ProtocolRecordLossAcknowledged)'",
                    "expectedLoss='$([bool]$strategyCase.Acknowledge)'",
                    "surfaces='$(@($global:QuickAdoptionProposalSurfaces) -join '|')'",
                    "expectedSurfaces='$($expectedStrategySurfaces -join '|')'",
                    "execCalls=$($strategyExecCalls.Count)",
                    "promptContract=$($strategyPrompt.Contains([string]$strategyCase.PromptContract))",
                    "missingIssueSurfaces='$($strategyMissingIssueSurfaces -join '|')'",
                    "applicationHashPreserved=$($strategyApplicationHashAfter -ceq $strategyApplicationHashBefore)",
                    "applicationBlobPreserved=$($strategyBranchApplicationBlob -ceq $strategyMainApplicationBlob)",
                    "readyCalls=$($global:QuickAdoptionPrReadyCalls)"
                ) -join '; '
                Add-Failure "TEST-0129/TEST-0130 $($strategyCase.Strategy) did not reach an exact strategy/surface/loss-bound dispatch, prompt, and issue while preserving application content: $strategyBoundError [$strategyBoundStack] ($strategyBoundDiagnostics)"
            }

            $strategyContractCases = if (
                [string]$strategyCase.Strategy -ceq 'HybridReconciliation'
            ) {
                @(
                    [pscustomobject]@{
                        Mode = 'AddHybridDecisionRestoreRootAgents'
                        Surface = 'AGENTS.md'
                    }
                )
            }
            else {
                @(
                    [pscustomobject]@{
                        Mode = 'ReconcileMemoryRestoreAgents'
                        Surface = 'AGENTS.md'
                    },
                    [pscustomobject]@{
                        Mode = 'ReconcileAgentsOnly'
                        Surface = '.ai/memory/project.md'
                    },
                    [pscustomobject]@{
                        Mode = 'ReconcileRequiredSurfaces'
                        Surface = 'PROTOCOL.md'
                    }
                )
            }
            foreach ($strategyContractCase in $strategyContractCases) {
                $additionalEntries = if (
                    [string]$strategyContractCase.Surface -ceq 'PROTOCOL.md'
                ) {
                    @([pscustomobject]@{
                        Path = 'PROTOCOL.md'; Exists = $true; Mode = '100644'
                    })
                }
                else { @() }
                $fixture = New-TestQuickAdoptionCompletionContractFixture `
                    -Strategy ([string]$strategyCase.Strategy) `
                    -ProtocolSurfaces @([string]$strategyContractCase.Surface) `
                    -AdditionalEntries $additionalEntries
                if (& $completionContract @fixture) {
                    Add-Failure "TEST-0129 production completion contract accepted $($strategyCase.Strategy)/$($strategyContractCase.Mode)."
                }
            }

            $strategyEnvelopeCases = if (
                [string]$strategyCase.Strategy -ceq 'HybridReconciliation'
            ) {
                @([pscustomobject]@{
                    Mode = 'AddHybridDecision'
                    ExpectedError = '*violates the canonical capabilities contract*'
                    ShouldSucceed = $false
                })
            }
            else {
                @([pscustomobject]@{
                    Mode = 'CompleteCleanStart'
                    ExpectedError = ''
                    ShouldSucceed = $true
                })
            }
            foreach ($strategyEnvelopeCase in $strategyEnvelopeCases) {
                Reset-MockAdoptionProposal
                # The prior workflow-only seed changed main and therefore the
                # graph identity; this envelope is a new logical proposal.
                $global:QuickAdoptionIssueRace = $false
                $global:QuickAdoptionIssues.Clear()
                $global:QuickAdoptionIssueLabels.Clear()
                $global:QuickAdoptionIssue = $null
                $env:MEANDAI_TEST_CODEX_MODE =
                    [string]$strategyEnvelopeCase.Mode
                $strategyEnvelopeError = ''
                try {
                    & $launcherPath @strategyParameters | Out-Null
                }
                catch {
                    $strategyEnvelopeError = $_.Exception.Message
                }
                $env:MEANDAI_TEST_CODEX_MODE = 'Success'
                $strategyEnvelopeBranch =
                    'refs/heads/automation/meandai-capabilities-v0.12.7'
                $strategyEnvelopeHeads = @(Invoke-TestGit `
                    -Repository $strategyConsumer.Repository -Arguments @(
                        'ls-remote', '--heads', 'origin',
                        $strategyEnvelopeBranch
                    ))
                $strategyEnvelopeBranchApplicationBlob = ''
                if ($strategyEnvelopeHeads.Count -eq 1) {
                    $strategyEnvelopeBranchApplicationBlob = (@(Invoke-TestGit `
                        -Repository $strategyConsumer.Remote -Arguments @(
                            'rev-parse', "$strategyEnvelopeBranch`:app.txt"
                        )))[0]
                }
                if ([bool]$strategyEnvelopeCase.ShouldSucceed) {
                    $cleanStartLedgerBlob = ''
                    $cleanStartPaths = @()
                    if ($strategyEnvelopeHeads.Count -eq 1) {
                        $cleanStartLedgerBlob = (@(Invoke-TestGit `
                            -Repository $strategyConsumer.Remote -Arguments @(
                                'rev-parse',
                                "$strategyEnvelopeBranch`:$strategyLedgerPath"
                            )))[0]
                        $cleanStartPaths = @(Invoke-TestGit `
                            -Repository $strategyConsumer.Remote -Arguments @(
                                'ls-tree', '-r', '--name-only',
                                $strategyEnvelopeBranch
                            ))
                    }
                    if ($strategyEnvelopeError -or
                        $strategyEnvelopeHeads.Count -ne 1 -or
                        $global:QuickAdoptionPrReadyCalls -ne 1 -or
                        $strategyEnvelopeBranchApplicationBlob -cne
                            $strategyMainApplicationBlob -or
                        $cleanStartLedgerBlob -cne
                            [string]$strategyCleanBaseline.Blob -or
                        $cleanStartPaths -contains 'PROTOCOL.md' -or
                        $cleanStartPaths -contains 'ai/WORK_INDEX.md' -or
                        $cleanStartPaths -contains $strategyLegacyPath -or
                        $cleanStartPaths -contains
                            '.ai/adoption/meandai-capabilities.json') {
                        Add-Failure "TEST-0129 CleanStart did not reconcile detected required governance, retire detected legacy surfaces, preserve the exact pre-existing migration ledger, and publish without application mutation: $strategyEnvelopeError"
                    }
                }
                elseif ($strategyEnvelopeError -notlike
                            [string]$strategyEnvelopeCase.ExpectedError -or
                        $strategyEnvelopeHeads.Count -ne 1 -or
                        $global:QuickAdoptionPrReadyCalls -ne 0 -or
                        $strategyEnvelopeBranchApplicationBlob -cne
                            $strategyMainApplicationBlob) {
                    Add-Failure "TEST-0129 strategy completion envelope accepted $($strategyCase.Strategy)/$($strategyEnvelopeCase.Mode), published it, or changed the representative application: $strategyEnvelopeError"
                }
            }
        }

        foreach ($emptyTagRaceKind in @(
            [pscustomobject]@{ Name = 'discovered'; Create = $false },
            [pscustomobject]@{ Name = 'created'; Create = $true }
        )) {
            Reset-Mocks
            $emptyTagRace = New-MockEmptyRemoteConsumer `
                -Name "empty-tag-presecret-$($emptyTagRaceKind.Name)" `
                -CreateRepository:([bool]$emptyTagRaceKind.Create)
            $global:QuickAdoptionRepoViewMode =
                'TagBeforeRepositoryMutation'
            $emptyTagRaceError = ''
            try {
                & $launcherPath -TargetPath $emptyTagRace.Repository `
                    -Owner 'test-owner' -RepositoryName $emptyTagRace.Name `
                    -SkipLifecycleDispatch -CodexCommand $mockCodexPath |
                    Out-Null
            }
            catch {
                $emptyTagRaceError = $_.Exception.Message
            }
            $emptyTagRaceSecretWrites = @($global:QuickAdoptionGhCalls |
                Where-Object {
                    $_.Arguments.Count -ge 2 -and
                    $_.Arguments[0] -ceq 'secret' -and
                    $_.Arguments[1] -ceq 'set'
                })
            $emptyTagRaceCreateCalls = @($global:QuickAdoptionGhCalls |
                Where-Object {
                    $_.Arguments.Count -ge 2 -and
                    $_.Arguments[0] -ceq 'repo' -and
                    $_.Arguments[1] -ceq 'create'
                })
            $emptyTagRaceRefs = @(
                if (Test-Path -LiteralPath $emptyTagRace.Remote `
                        -PathType Container) {
                    Invoke-TestGit -Repository $emptyTagRace.Repository `
                        -Arguments @('ls-remote', $emptyTagRace.Remote)
                }
            )
            $emptyTagRaceHasLocalHead = Test-RepositoryHasHead `
                -Repository $emptyTagRace.Repository
            $emptyTagRaceExpectedCreates = if (
                [bool]$emptyTagRaceKind.Create
            ) { 1 } else { 0 }
            if ($emptyTagRaceError -notlike
                    '*repository assumed to be empty gained history or live identity before repository mutation*secrets and seed publication were not changed*' -or
                -not $global:QuickAdoptionTagRaceInjected -or
                $emptyTagRaceRefs.Count -ne 1 -or
                $emptyTagRaceRefs[0] -cnotmatch
                    "`trefs/tags/concurrent$" -or
                $emptyTagRaceHasLocalHead -or
                $emptyTagRaceSecretWrites.Count -ne 0 -or
                $global:QuickAdoptionSecrets.Count -ne 0 -or
                $emptyTagRaceCreateCalls.Count -ne
                    $emptyTagRaceExpectedCreates -or
                (Test-Path -LiteralPath (
                    Join-Path $emptyTagRace.Repository $workflowRelativePath
                )) -or
                $global:QuickAdoptionWorkflowDispatched) {
                Add-Failure "TEST-0052/TEST-0130 $($emptyTagRaceKind.Name) empty remote accepted a tag-only pre-secret race or mutated secrets/seed: error='$emptyTagRaceError'; injected=$($global:QuickAdoptionTagRaceInjected); refs='$($emptyTagRaceRefs -join '|')'; localHead=$emptyTagRaceHasLocalHead; secretWrites=$($emptyTagRaceSecretWrites.Count); secrets=$($global:QuickAdoptionSecrets.Count); creates=$($emptyTagRaceCreateCalls.Count)/$emptyTagRaceExpectedCreates; workflow=$([bool](Test-Path -LiteralPath (Join-Path $emptyTagRace.Repository $workflowRelativePath))); dispatched=$($global:QuickAdoptionWorkflowDispatched)."
            }
        }

        foreach ($emptyTagPushRaceKind in @(
            [pscustomobject]@{ Name = 'discovered'; Create = $false },
            [pscustomobject]@{ Name = 'created'; Create = $true }
        )) {
            Reset-Mocks
            $emptyTagPushRace = New-MockEmptyRemoteConsumer `
                -Name "empty-tag-postpush-$($emptyTagPushRaceKind.Name)" `
                -CreateRepository:([bool]$emptyTagPushRaceKind.Create)
            $global:QuickAdoptionRepoViewMode = 'TagAfterMainPublished'
            $emptyTagPushRaceError = ''
            try {
                & $launcherPath -TargetPath $emptyTagPushRace.Repository `
                    -Owner 'test-owner' -RepositoryName $emptyTagPushRace.Name `
                    -SkipLifecycleDispatch -CodexCommand $mockCodexPath |
                    Out-Null
            }
            catch {
                $emptyTagPushRaceError = $_.Exception.Message
            }
            $emptyTagPushRaceSecretWrites = @($global:QuickAdoptionGhCalls |
                Where-Object {
                    $_.Arguments.Count -ge 2 -and
                    $_.Arguments[0] -ceq 'secret' -and
                    $_.Arguments[1] -ceq 'set'
                })
            $emptyTagPushRaceCreateCalls = @($global:QuickAdoptionGhCalls |
                Where-Object {
                    $_.Arguments.Count -ge 2 -and
                    $_.Arguments[0] -ceq 'repo' -and
                    $_.Arguments[1] -ceq 'create'
                })
            $emptyTagPushRaceRefs = @(
                if (Test-Path -LiteralPath $emptyTagPushRace.Remote `
                        -PathType Container) {
                    Invoke-TestGit -Repository $emptyTagPushRace.Repository `
                        -Arguments @('ls-remote', $emptyTagPushRace.Remote)
                }
            )
            $emptyTagPushRaceHasLocalHead = Test-RepositoryHasHead `
                -Repository $emptyTagPushRace.Repository
            $emptyTagPushRaceExpectedCreates = if (
                [bool]$emptyTagPushRaceKind.Create
            ) { 1 } else { 0 }
            if ($emptyTagPushRaceError -notlike
                    '*repository assumed to be empty changed during seed push*exact seed ref was removed*local seed commit was retained for review*' -or
                -not $global:QuickAdoptionTagRaceInjected -or
                $emptyTagPushRaceRefs.Count -ne 1 -or
                $emptyTagPushRaceRefs[0] -cnotmatch
                    "`trefs/tags/concurrent$" -or
                -not $emptyTagPushRaceHasLocalHead -or
                $emptyTagPushRaceSecretWrites.Count -ne 0 -or
                $global:QuickAdoptionSecrets.Count -ne 0 -or
                $emptyTagPushRaceCreateCalls.Count -ne
                    $emptyTagPushRaceExpectedCreates -or
                -not (Test-Path -LiteralPath (
                    Join-Path $emptyTagPushRace.Repository $workflowRelativePath
                ) -PathType Leaf) -or
                $global:QuickAdoptionWorkflowDispatched) {
                Add-Failure "TEST-0052/TEST-0130 $($emptyTagPushRaceKind.Name) empty remote tag-only during-push race did not remove only launcher main and retain the local seed commit: error='$emptyTagPushRaceError'; injected=$($global:QuickAdoptionTagRaceInjected); refs='$($emptyTagPushRaceRefs -join '|')'; localHead=$emptyTagPushRaceHasLocalHead; secretWrites=$($emptyTagPushRaceSecretWrites.Count); secrets=$($global:QuickAdoptionSecrets.Count); creates=$($emptyTagPushRaceCreateCalls.Count)/$emptyTagPushRaceExpectedCreates; workflow=$([bool](Test-Path -LiteralPath (Join-Path $emptyTagPushRace.Repository $workflowRelativePath))); dispatched=$($global:QuickAdoptionWorkflowDispatched)."
            }
        }

        Reset-Mocks
        $delayedDefaultRace = New-MockEmptyRemoteConsumer `
            -Name 'delayed-default-tag-race' -CreateRepository
        $global:QuickAdoptionRepoViewMode = 'DelayedDefaultTagDuringRetry'
        $delayedDefaultRaceError = ''
        try {
            & $launcherPath -TargetPath $delayedDefaultRace.Repository `
                -Owner 'test-owner' -RepositoryName $delayedDefaultRace.Name `
                -SkipLifecycleDispatch -CodexCommand $mockCodexPath |
                Out-Null
        }
        catch {
            $delayedDefaultRaceError = $_.Exception.Message
        }
        $delayedDefaultRaceRefs = @(
            if (Test-Path -LiteralPath $delayedDefaultRace.Remote `
                    -PathType Container) {
                Invoke-TestGit -Repository $delayedDefaultRace.Repository `
                    -Arguments @('ls-remote', $delayedDefaultRace.Remote)
            }
        )
        $delayedDefaultHasLocalHead = Test-RepositoryHasHead `
            -Repository $delayedDefaultRace.Repository
        if ($delayedDefaultRaceError -notlike
                '*repository assumed to be empty changed during seed push*exact seed ref was removed*local seed commit was retained for review*' -or
            $global:QuickAdoptionDelayedDefaultViews -lt 2 -or
            -not $global:QuickAdoptionTagRaceInjected -or
            $delayedDefaultRaceRefs.Count -ne 1 -or
            $delayedDefaultRaceRefs[0] -cnotmatch
                "`trefs/tags/concurrent$" -or
            -not $delayedDefaultHasLocalHead -or
            $global:QuickAdoptionSecrets.Count -ne 0 -or
            $global:QuickAdoptionWorkflowDispatched) {
            Add-Failure "TEST-0052/TEST-0130 delayed defaultBranchRef retry accepted a newly advertised foreign tag instead of removing only launcher main: error='$delayedDefaultRaceError'; delayedViews=$($global:QuickAdoptionDelayedDefaultViews); injected=$($global:QuickAdoptionTagRaceInjected); refs='$($delayedDefaultRaceRefs -join '|')'; localHead=$delayedDefaultHasLocalHead; secrets=$($global:QuickAdoptionSecrets.Count); dispatched=$($global:QuickAdoptionWorkflowDispatched)."
        }

        Reset-Mocks
        $emptyRaceRoot = New-TempRoot -Name 'existing-empty-develop-race'
        $emptyRaceRepo = Join-Path $emptyRaceRoot 'consumer'
        $emptyRaceRemote = Join-Path $emptyRaceRoot 'consumer.git'
        New-Item -ItemType Directory -Path $emptyRaceRepo -Force | Out-Null
        & git init --bare $emptyRaceRemote 2>&1 | Out-Null
        & git init -b main $emptyRaceRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $emptyRaceRepo
        $emptyRaceUrl =
            'https://github.com/test-owner/existing-empty-develop-race.git'
        Invoke-TestGit -Repository $emptyRaceRepo -Arguments @(
            'config', "url.$($emptyRaceRemote.Replace('\', '/')).insteadOf",
            $emptyRaceUrl
        ) | Out-Null
        $global:QuickAdoptionRepoName =
            'test-owner/existing-empty-develop-race'
        $global:QuickAdoptionDefaultBranch = ''
        $global:QuickAdoptionTargetPath = $emptyRaceRepo
        $global:QuickAdoptionRemotePath = $emptyRaceRemote
        $global:QuickAdoptionExistingSecrets.Add('MEANDAI_UPDATER_TOKEN')
        $global:QuickAdoptionExistingSecrets.Add('MEANDAI_PROTOCOL_TOKEN')
        $global:QuickAdoptionRepoViewMode = 'DevelopAfterFirst'
        $emptyRaceSecretCountBefore = $global:QuickAdoptionSecrets.Count
        $emptyRaceCodexCountBefore = @(Get-MockCodexCalls).Count
        $emptyRaceError = ''
        try {
            & $launcherPath -TargetPath $emptyRaceRepo `
                -Owner 'test-owner' `
                -RepositoryName 'existing-empty-develop-race' `
                -SkipLifecycleDispatch -CodexCommand $mockCodexPath |
                Out-Null
        }
        catch {
            $emptyRaceError = $_.Exception.Message
        }
        $emptyRaceSecretWrites = @($global:QuickAdoptionGhCalls |
            Where-Object {
                $_.Arguments.Count -ge 2 -and
                $_.Arguments[0] -ceq 'secret' -and
                $_.Arguments[1] -ceq 'set'
            })
        $emptyRaceRemoteHeads = @(Invoke-TestGit `
            -Repository $emptyRaceRepo `
            -Arguments @('ls-remote', '--heads', $emptyRaceUrl))
        $emptyRaceHasLocalHead = Test-RepositoryHasHead `
            -Repository $emptyRaceRepo
        if ($emptyRaceError -notlike
                '*repository assumed to be empty gained history or live identity before repository mutation*secrets and seed publication were not changed*' -or
            -not $global:QuickAdoptionDevelopRaceInjected -or
            $emptyRaceRemoteHeads.Count -ne 1 -or
            $emptyRaceRemoteHeads[0] -cnotmatch
                "`trefs/heads/develop$" -or
            $emptyRaceHasLocalHead -or
            $emptyRaceSecretWrites.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne $emptyRaceSecretCountBefore -or
            @(Get-MockCodexCalls).Count -ne $emptyRaceCodexCountBefore -or
            (Test-Path -LiteralPath (
                Join-Path $emptyRaceRepo $workflowRelativePath
            )) -or
            $global:QuickAdoptionWorkflowDispatched) {
            Add-Failure "TEST-0052/TEST-0130 an existing empty remote that gained develop before secret reconciliation did not stop with zero secret, seed, main-ref, lifecycle, or Codex mutation: $emptyRaceError"
        }

        Reset-Mocks
        $unconnectedRoot = New-TempRoot -Name 'existing-unconnected'
        $unconnectedRepo = Join-Path $unconnectedRoot 'existing-unconnected'
        $unconnectedRemote = Join-Path $unconnectedRoot 'existing-unconnected.git'
        New-Item -ItemType Directory -Path $unconnectedRepo -Force | Out-Null
        & git init --bare $unconnectedRemote 2>&1 | Out-Null
        & git init -b main $unconnectedRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $unconnectedRepo
        $unconnectedUrl = 'https://github.com/test-owner/existing-unconnected.git'
        Invoke-TestGit -Repository $unconnectedRepo -Arguments @(
            'config', "url.$($unconnectedRemote.Replace('\\', '/')).insteadOf",
            $unconnectedUrl
        ) | Out-Null
        $global:QuickAdoptionRepoName = 'test-owner/existing-unconnected'
        $global:QuickAdoptionDefaultBranch = ''
        $global:QuickAdoptionTargetPath = $unconnectedRepo
        $global:QuickAdoptionRemotePath = $unconnectedRemote
        $global:QuickAdoptionExistingSecrets.Add('MEANDAI_UPDATER_TOKEN')
        $global:QuickAdoptionExistingSecrets.Add('MEANDAI_PROTOCOL_TOKEN')

        $unconnectedError = ''
        try {
            & $launcherPath -TargetPath $unconnectedRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $unconnectedError = $_.Exception.Message
        }
        $unconnectedCreateCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'repo' -and
            $_.Arguments[1] -ceq 'create'
        })
        $unconnectedSecretWrites = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
            $_.Arguments[1] -ceq 'set'
        })
        $unconnectedSecretLists = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
            $_.Arguments[1] -ceq 'list'
        })
        $unconnectedOrigin = @()
        $unconnectedRemotePaths = @()
        if (-not $unconnectedError) {
            $unconnectedOrigin = @(
                Invoke-TestGit -Repository $unconnectedRepo -Arguments @(
                    'config', '--get', 'remote.origin.url'
                )
            )
            $unconnectedRemotePaths = @(
                Invoke-TestGit -Repository $unconnectedRemote -Arguments @(
                    'ls-tree', '-r', '--name-only', 'refs/heads/main'
                )
            )
        }
        if ($unconnectedError -or $unconnectedCreateCalls.Count -ne 0 -or
            $unconnectedSecretLists.Count -ne 1 -or
            $unconnectedSecretWrites.Count -ne 0 -or
            $unconnectedOrigin.Count -ne 1 -or $unconnectedOrigin[0] -cne $unconnectedUrl -or
            $unconnectedRemotePaths.Count -ne 1 -or
            $unconnectedRemotePaths[0] -cne $workflowRelativePath -or
            (Test-Path -LiteralPath (Join-Path $unconnectedRepo 'FG_PAT.txt')) -or
            (Test-Path -LiteralPath (Join-Path $unconnectedRepo 'MEANDAI_RO_FG_PAT.txt'))) {
            Add-Failure "TEST-0100 existing empty repository with both mapped secrets did not adopt without local token files: $unconnectedError"
        }

        if (-not $unconnectedError) {
            # GitHub assigns the first pushed branch as the repository default.
            $global:QuickAdoptionDefaultBranch = 'main'
        }
        [void]$global:QuickAdoptionExistingSecrets.Remove('MEANDAI_UPDATER_TOKEN')
        $writesBeforeMissingUpdater = $global:QuickAdoptionSecrets.Count
        $missingUpdaterError = ''
        try {
            & $launcherPath -TargetPath $unconnectedRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $missingUpdaterError = $_.Exception.Message
        }
        if ($missingUpdaterError -notlike "*FG_PAT.txt*MEANDAI_UPDATER_TOKEN*does not exist*" -or
            $global:QuickAdoptionSecrets.Count -ne $writesBeforeMissingUpdater) {
            Add-Failure "TEST-0100 missing updater secret and missing mapped file did not fail before secret mutation: $missingUpdaterError"
        }

        $nonemptyProbeRepo = Join-Path $unconnectedRoot 'nonempty-probe'
        New-Item -ItemType Directory -Path $nonemptyProbeRepo -Force | Out-Null
        & git init -b main $nonemptyProbeRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $nonemptyProbeRepo
        Invoke-TestGit -Repository $nonemptyProbeRepo -Arguments @(
            'config', "url.$($unconnectedRemote.Replace('\\', '/')).insteadOf",
            $unconnectedUrl
        ) | Out-Null
        $global:QuickAdoptionTargetPath = $nonemptyProbeRepo
        $writesBeforeNonemptyProbe = $global:QuickAdoptionSecrets.Count
        $nonemptyProbeError = ''
        try {
            & $launcherPath -TargetPath $nonemptyProbeRepo -SkipLifecycleDispatch `
                -Owner 'test-owner' -RepositoryName 'existing-unconnected' `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $nonemptyProbeError = $_.Exception.Message
        }
        $nonemptyProbeRemotes = @(
            Invoke-TestGit -Repository $nonemptyProbeRepo -Arguments @('remote')
        )
        if ($nonemptyProbeError -notlike '*already contains history*' -or
            $nonemptyProbeRemotes -contains 'origin' -or
            $global:QuickAdoptionSecrets.Count -ne $writesBeforeNonemptyProbe) {
            Add-Failure "TEST-0100 existing non-empty derived repository did not fail before local remote or secret mutation: $nonemptyProbeError"
        }

        foreach ($seedBindingCase in @(
            [pscustomobject]@{
                Name = 'before-push'
                ViewMode = 'WrongAfterThird'
                ExpectedError =
                    '*live repository/default branch changed immediately before seed push*seed was not published*'
            },
            [pscustomobject]@{
                Name = 'during-push'
                ViewMode = 'WrongAfterFourth'
                ExpectedError =
                    '*live repository/default branch changed during seed push*exact seed push was reverted*'
            }
        )) {
            Reset-Mocks
            $seedBindingConsumer = New-MockConnectedSeedConsumer `
                -Name "seed-binding-$($seedBindingCase.Name)" `
                -OmitWorkflowSeed
            $global:QuickAdoptionExistingSecrets.Add(
                'MEANDAI_UPDATER_TOKEN'
            )
            $global:QuickAdoptionExistingSecrets.Add(
                'MEANDAI_PROTOCOL_TOKEN'
            )
            Remove-Item -LiteralPath (
                Join-Path $seedBindingConsumer.Repository 'FG_PAT.txt'
            ) -Force
            Remove-Item -LiteralPath (
                Join-Path $seedBindingConsumer.Repository `
                    'MEANDAI_RO_FG_PAT.txt'
            ) -Force
            $seedBindingBaseHead = (@(Invoke-TestGit `
                -Repository $seedBindingConsumer.Remote -Arguments @(
                    'rev-parse', 'refs/heads/main'
                )))[0]
            $global:QuickAdoptionRepoViewMode =
                [string]$seedBindingCase.ViewMode
            $seedBindingError = ''
            try {
                & $launcherPath `
                    -TargetPath $seedBindingConsumer.Repository `
                    -AdoptionStrategy FreshAdoption -NonInteractive `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $seedBindingError = $_.Exception.Message
            }
            $seedBindingRemoteHead = (@(Invoke-TestGit `
                -Repository $seedBindingConsumer.Remote -Arguments @(
                    'rev-parse', 'refs/heads/main'
                )))[0]
            $seedBindingLocalHead = (@(Invoke-TestGit `
                -Repository $seedBindingConsumer.Repository -Arguments @(
                    'rev-parse', 'HEAD'
                )))[0]
            if ($seedBindingError -notlike
                    [string]$seedBindingCase.ExpectedError -or
                $seedBindingRemoteHead -cne $seedBindingBaseHead -or
                $seedBindingLocalHead -ceq $seedBindingBaseHead -or
                $global:QuickAdoptionSecrets.Count -ne 0 -or
                $global:QuickAdoptionWorkflowDispatched) {
                Add-Failure "TEST-0052 seed default-branch rename $($seedBindingCase.Name) did not preserve/revert the old ref exactly before workflow or secret follow-on: error='$seedBindingError'; remote=$seedBindingBaseHead->$seedBindingRemoteHead; local=$seedBindingLocalHead."
            }
        }

        Reset-Mocks
        $modifiedSeedRoot = New-TempRoot -Name 'modified-seed'
        $modifiedSeedRepo = Join-Path $modifiedSeedRoot 'consumer'
        $modifiedSeedRemote = Join-Path $modifiedSeedRoot 'consumer.git'
        $modifiedSeedPath = Join-Path $modifiedSeedRepo $workflowRelativePath
        New-Item -ItemType Directory -Path (
            Split-Path -Parent $modifiedSeedPath
        ) -Force | Out-Null
        [IO.File]::WriteAllBytes(
            $modifiedSeedPath,
            [byte[]]($global:QuickAdoptionWorkflowBytes +
                [Text.Encoding]::UTF8.GetBytes("`n# recognizable byte drift`n"))
        )
        Set-Content -LiteralPath (Join-Path $modifiedSeedRepo 'FG_PAT.txt') `
            -Value 'write-token-value' -NoNewline
        Set-Content -LiteralPath (
            Join-Path $modifiedSeedRepo 'MEANDAI_RO_FG_PAT.txt'
        ) -Value 'read-token-value' -NoNewline
        $modifiedSeedHashBefore = (Get-FileHash `
            -LiteralPath $modifiedSeedPath -Algorithm SHA256).Hash
        $global:QuickAdoptionRepoName = 'test-owner/modified-seed'
        $global:QuickAdoptionTargetPath = $modifiedSeedRepo
        $global:QuickAdoptionNewRemote = $modifiedSeedRemote
        $global:QuickAdoptionRemotePath = $modifiedSeedRemote
        $global:QuickAdoptionRepositoryExists = $false
        $modifiedSeedError = ''
        try {
            & $launcherPath -TargetPath $modifiedSeedRepo `
                -Owner 'test-owner' -RepositoryName 'modified-seed' `
                -SkipLifecycleDispatch -CodexCommand $mockCodexPath |
                Out-Null
        }
        catch {
            $modifiedSeedError = $_.Exception.Message
        }
        $modifiedSeedCreateCalls = @(
            $global:QuickAdoptionGhCalls | Where-Object {
                $_.Arguments.Count -ge 2 -and
                $_.Arguments[0] -ceq 'repo' -and
                $_.Arguments[1] -ceq 'create'
            }
        )
        $modifiedSeedRemotes = @(Invoke-TestGit `
            -Repository $modifiedSeedRepo -Arguments @('remote'))
        $modifiedSeedHashAfter = (Get-FileHash `
            -LiteralPath $modifiedSeedPath -Algorithm SHA256).Hash
        if ($modifiedSeedError -notlike
                '*not the exact canonical v0.12.7 file*no GitHub repository or remote was changed*' -or
            $modifiedSeedCreateCalls.Count -ne 0 -or
            $modifiedSeedRemotes.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0 -or
            $modifiedSeedHashAfter -cne $modifiedSeedHashBefore) {
            Add-Failure "TEST-0078 recognizable but byte-modified seed did not fail before repository, remote, secret, or file mutation: $modifiedSeedError"
        }

        Reset-Mocks
        $seedHookRoot = New-TempRoot -Name 'seed-hook-injection'
        $seedHookRepo = Join-Path $seedHookRoot 'consumer'
        $seedHookRemote = Join-Path $seedHookRoot 'consumer.git'
        New-Item -ItemType Directory -Path $seedHookRepo -Force | Out-Null
        & git init --bare $seedHookRemote 2>&1 | Out-Null
        & git init -b main $seedHookRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $seedHookRepo
        $seedHookUrl =
            'https://github.com/test-owner/seed-hook-injection.git'
        Invoke-TestGit -Repository $seedHookRepo -Arguments @(
            'config',
            "url.$($seedHookRemote.Replace(
                [IO.Path]::DirectorySeparatorChar, '/'
            )).insteadOf",
            $seedHookUrl
        ) | Out-Null
        Invoke-TestGit -Repository $seedHookRepo -Arguments @(
            'remote', 'add', 'origin', $seedHookUrl
        ) | Out-Null
        $seedHookSentinel = '.meandai-blocking-hook-sentinel'
        $seedHookDirectory = New-TestBlockingGitHooks `
            -SentinelName $seedHookSentinel
        Invoke-TestGit -Repository $seedHookRepo -Arguments @(
            'config', 'core.hooksPath',
            $seedHookDirectory.Replace(
                [IO.Path]::DirectorySeparatorChar, '/'
            )
        ) | Out-Null
        $global:QuickAdoptionRepoName =
            'test-owner/seed-hook-injection'
        $global:QuickAdoptionTargetPath = $seedHookRepo
        $global:QuickAdoptionRemotePath = $seedHookRemote
        $global:QuickAdoptionDefaultBranch = ''
        $global:QuickAdoptionExistingSecrets.Add('MEANDAI_UPDATER_TOKEN')
        $global:QuickAdoptionExistingSecrets.Add('MEANDAI_PROTOCOL_TOKEN')
        $seedHookGitConfigCountBefore =
            [Environment]::GetEnvironmentVariable('GIT_CONFIG_COUNT', 'Process')
        $seedHookError = ''
        try {
            & $launcherPath -TargetPath $seedHookRepo `
                -SkipLifecycleDispatch -CodexCommand $mockCodexPath |
                Out-Null
        }
        catch {
            $seedHookError = $_.Exception.Message
        }
        $seedHookRemoteHeads = @(Invoke-TestGit `
            -Repository $seedHookRepo -Arguments @(
                'ls-remote', '--heads', 'origin'
            ))
        $seedHookRemotePaths = @(Invoke-TestGit `
            -Repository $seedHookRemote -Arguments @(
                'ls-tree', '-r', '--name-only', 'refs/heads/main'
            ))
        $seedHookSentinelPath = Join-Path $seedHookRepo $seedHookSentinel
        if ($seedHookError -or
            (Test-Path -LiteralPath $seedHookSentinelPath) -or
            $seedHookRemoteHeads.Count -ne 1 -or
            $seedHookRemoteHeads[0] -cnotmatch "`trefs/heads/main$" -or
            $seedHookRemotePaths.Count -ne 1 -or
            $seedHookRemotePaths[0] -cne $workflowRelativePath -or
            [Environment]::GetEnvironmentVariable(
                'GIT_CONFIG_COUNT', 'Process'
            ) -cne $seedHookGitConfigCountBefore -or
            $global:QuickAdoptionWorkflowDispatched) {
            Add-Failure "TEST-0078 launcher-scoped hook suppression did not bypass both blocking pre-commit/pre-push hooks, publish only the seed, and restore Git config environment: $seedHookError"
        }

        Reset-Mocks
        $newRoot = New-TempRoot -Name 'new'
        $newRepo = Join-Path $newRoot 'new-consumer'
        $newRemote = Join-Path $newRoot 'new-consumer.git'
        New-Item -ItemType Directory -Path (Join-Path $newRepo 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $newRepo 'src/app.txt') -Value 'local-only' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $newRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'new-read-token' -NoNewline
        $global:QuickAdoptionExpectedProtocolToken = 'new-read-token'
        $global:QuickAdoptionExpectedUpdaterToken = 'new-write-token'
        $global:QuickAdoptionRepoName = 'test-owner/new-consumer'
        $global:QuickAdoptionTargetPath = $newRepo
        $global:QuickAdoptionNewRemote = $newRemote
        $global:QuickAdoptionRemotePath = $newRemote
        $global:QuickAdoptionDefaultBranch = ''
        $global:QuickAdoptionRepositoryExists = $false

        $noHeadApplicationError = ''
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $noHeadApplicationError = $_.Exception.Message
        }
        $noHeadApplicationCreateCalls = @(
            $global:QuickAdoptionGhCalls | Where-Object {
                $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'repo' -and
                $_.Arguments[1] -eq 'create'
            }
        )
        if ($noHeadApplicationError -notlike
                '*repository without a committed HEAD*Unexpected path: ''src/app.txt''*' -or
            $noHeadApplicationCreateCalls.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure "TEST-0035 no-HEAD application content was not rejected before GitHub mutation: $noHeadApplicationError"
        }
        Remove-Item -LiteralPath (Join-Path $newRepo 'src/app.txt') -Force

        $missingNewCredentialBlocked = $false
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $missingNewCredentialBlocked = $true
        }
        $createCallsBeforeCredentials = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'repo' -and
            $_.Arguments[1] -eq 'create'
        })
        if (-not $missingNewCredentialBlocked -or $createCallsBeforeCredentials.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure 'TEST-0045 new-repository adoption did not require both local credential files before remote mutation.'
        }

        Set-Content -LiteralPath (Join-Path $newRepo 'FG_PAT.txt') -Value 'new-write-token' -NoNewline
        $global:QuickAdoptionDenyTargetAccess = $true
        $grantBlocked = $false
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $grantBlocked = $true
        }
        if (-not $grantBlocked -or $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure 'TEST-0036 missing selected-repository grant did not block before secret storage.'
        }
        $global:QuickAdoptionDenyTargetAccess = $false
        $newRefsBeforeFinal = if (Test-Path -LiteralPath $newRemote `
                -PathType Container) {
            @(Invoke-TestGit -Repository $newRepo `
                -Arguments @('ls-remote', $newRemote))
        }
        else { @() }
        $newFinalError = ''
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $newFinalError = $_.Exception.Message
        }
        $newRefsAfterFinal = if (Test-Path -LiteralPath $newRemote `
                -PathType Container) {
            @(Invoke-TestGit -Repository $newRepo `
                -Arguments @('ls-remote', $newRemote))
        }
        else { @() }
        if ($newFinalError) {
            Add-Failure "TEST-0035/TEST-0042 new-repository retry after selected-grant repair did not resume from its exact empty remote: error='$newFinalError'; before='$($newRefsBeforeFinal -join '|')'; after='$($newRefsAfterFinal -join '|')'; repoViewMode='$($global:QuickAdoptionRepoViewMode)'; repoViewCalls=$($global:QuickAdoptionRepoViewCalls)."
        }
        if ($global:QuickAdoptionSecrets.Count -ne 2 -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_UPDATER_TOKEN' -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_PROTOCOL_TOKEN') {
            Add-Failure 'TEST-0042 new-repository adoption did not create both missing Actions secrets.'
        }
        $createCall = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'repo' -and $_.Arguments[1] -eq 'create'
        })
        if ($createCall.Count -ne 1 -or $createCall[0].Arguments -notcontains '--private') {
            Add-Failure 'TEST-0035 new adoption did not create one private repository.'
        }
        $newRemotePaths = @(if (-not $newFinalError) {
            Invoke-Git -Repository $newRepo -Arguments @(
                'ls-tree', '-r', '--name-only', 'origin/main'
            )
        }
        else { @() })
        if ($newRemotePaths.Count -ne 1 -or
            $newRemotePaths[0] -cne $workflowRelativePath) {
            Add-Failure "TEST-0035 new remote published unrelated paths: $($newRemotePaths -join ', ')"
        }
        $newStatus = @(Invoke-Git -Repository $newRepo -Arguments @('status', '--short'))
        if ($newStatus.Count -ne 0) {
            Add-Failure "TEST-0035 committed local content was not preserved in a clean checkout: $($newStatus -join ', ')"
        }

        Reset-Mocks
        $currentConsumer = New-MockConnectedManagedConsumer `
            -Name 'managed-current' -InstalledTag 'v0.12.7'
        # Already-current capability review uses the optional-input workflow
        # without reopening prospective initial-adoption graph assessment.
        $global:QuickAdoptionExpectSourceGraphIdentity = $false
        $currentCodexCallsBefore = @(Get-MockCodexCalls).Count
        $currentError = ''
        try {
            & $launcherPath -TargetPath $currentConsumer.Repository `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $currentError = $_.Exception.Message
        }
        $currentHeadAfter = (@(Invoke-TestGit -Repository $currentConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $currentRemoteHeadAfter = (@(Invoke-TestGit -Repository $currentConsumer.Repository `
            -Arguments @('rev-parse', 'origin/main')))[0]
        $currentDispatches = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'workflow' -and
            $_.Arguments[1] -ceq 'run'
        })
        $currentPrLookups = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'pr' -and
            $_.Arguments[1] -ceq 'list'
        })
        if ($currentError -or $currentHeadAfter -cne $currentConsumer.Head -or
            $currentRemoteHeadAfter -cne $currentConsumer.Head -or
            $currentDispatches.Count -ne 1 -or
            -not $global:QuickAdoptionWorkflowDispatched -or
            $null -eq $global:QuickAdoptionDispatchRecord -or
            [string]$global:QuickAdoptionDispatchRecord.Workflow -cne
                'meandai-protocol-update.yml' -or
            [string]$global:QuickAdoptionDispatchRecord.Repository -cne
                $currentConsumer.Slug -or
            [string]$global:QuickAdoptionDispatchRecord.Ref -cne 'main' -or
            [string]$global:QuickAdoptionDispatchRecord.CorrelationId -cnotmatch
                '^[0-9a-f]{32}$' -or
            [string]$global:QuickAdoptionDispatchRecord.AdoptionStrategy -cne 'Auto' -or
            [bool]$global:QuickAdoptionDispatchRecord.ProtocolRecordLossAcknowledged -or
            [string]$global:QuickAdoptionDispatchRecord.ExpectedBaseSha -cne
                $currentConsumer.Head -or
            [string]$global:QuickAdoptionDispatchRecord.Head -cne
                $currentConsumer.Head -or
            $currentPrLookups.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0 -or
            @(Get-MockCodexCalls).Count -ne $currentCodexCallsBefore) {
            Add-Failure "TEST-0113/TEST-0130 exact current adoption did not dispatch one target-bound Auto capability review while bypassing initial selection as a Git/Codex no-op after secret-name reconciliation: $currentError"
        }

        Reset-Mocks
        $legacyConsumer = New-MockConnectedManagedConsumer `
            -Name 'managed-legacy' -InstalledTag 'v0.9.2'
        $legacyWorkflowPath = Join-Path $legacyConsumer.Repository $workflowRelativePath
        $legacyWorkflowShaBefore = Get-GitBlobSha `
            -Bytes ([IO.File]::ReadAllBytes($legacyWorkflowPath))
        $legacyCodexCallsBefore = @(Get-MockCodexCalls).Count
        $legacyError = ''
        try {
            & $launcherPath -TargetPath $legacyConsumer.Repository `
                -SkipLifecycleDispatch -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $legacyError = $_.Exception.Message
        }
        $legacyWorkflowShaAfter = Get-GitBlobSha `
            -Bytes ([IO.File]::ReadAllBytes($legacyWorkflowPath))
        $legacyHeadAfter = (@(Invoke-TestGit -Repository $legacyConsumer.Repository `
            -Arguments @('rev-parse', 'HEAD')))[0]
        $legacyDispatches = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'workflow' -and
            $_.Arguments[1] -ceq 'run'
        })
        $legacyPrLookups = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'pr' -and
            $_.Arguments[1] -ceq 'list'
        })
        if ($legacyError -or $legacyHeadAfter -cne $legacyConsumer.Head -or
            $legacyWorkflowShaAfter -cne $legacyWorkflowShaBefore -or
            $legacyDispatches.Count -ne 0 -or $global:QuickAdoptionWorkflowDispatched -or
            $legacyPrLookups.Count -ne 0 -or $global:QuickAdoptionSecrets.Count -ne 0 -or
            @(Get-MockCodexCalls).Count -ne $legacyCodexCallsBefore) {
            Add-Failure "TEST-0113 exact older same-major adoption did not preserve its checkout when current-launcher recovery was explicitly skipped: $legacyError"
        }

        foreach ($blockedRoute in @(
            [pscustomobject]@{ Name = 'manifest'; InstalledTag = 'v0.12.7'; TargetTag = 'v0.12.7'; Mutation = 'Manifest' },
            [pscustomobject]@{ Name = 'partial'; InstalledTag = 'v0.12.7'; TargetTag = 'v0.12.7'; Mutation = 'Partial' },
            [pscustomobject]@{ Name = 'missing-gitlink'; InstalledTag = 'v0.12.7'; TargetTag = 'v0.12.7'; Mutation = 'MissingGitlink' },
            [pscustomobject]@{ Name = 'drift'; InstalledTag = 'v0.12.7'; TargetTag = 'v0.12.7'; Mutation = 'Drift' },
            [pscustomobject]@{ Name = 'newer'; InstalledTag = 'v0.12.8'; TargetTag = 'v0.12.7'; Mutation = 'None' },
            [pscustomobject]@{ Name = 'cross-major'; InstalledTag = 'v0.12.7'; TargetTag = 'v1.0.0'; Mutation = 'None' }
        )) {
            Reset-Mocks
            $blockedConsumer = New-MockConnectedManagedConsumer `
                -Name "managed-$($blockedRoute.Name)" `
                -InstalledTag ([string]$blockedRoute.InstalledTag)
            switch -CaseSensitive ([string]$blockedRoute.Mutation) {
                'Manifest' {
                    $manifestPath = Join-Path $blockedConsumer.Repository `
                        '.ai/adoption/meandai-capabilities.json'
                    New-Item -ItemType Directory -Path (Split-Path -Parent $manifestPath) `
                        -Force | Out-Null
                    [IO.File]::WriteAllText(
                        $manifestPath, "{}`n", [Text.UTF8Encoding]::new($false)
                    )
                    Invoke-TestGit -Repository $blockedConsumer.Repository -Arguments @(
                        'add', '--', '.ai/adoption/meandai-capabilities.json'
                    ) | Out-Null
                }
                'Partial' {
                    Invoke-TestGit -Repository $blockedConsumer.Repository -Arguments @(
                        'rm', '--', '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
                    ) | Out-Null
                }
                'MissingGitlink' {
                    Invoke-TestGit -Repository $blockedConsumer.Repository -Arguments @(
                        'update-index', '--force-remove', '--', '.ai/protocol'
                    ) | Out-Null
                    Remove-Item -LiteralPath (Join-Path $blockedConsumer.Repository '.ai/protocol') `
                        -Recurse -Force
                }
                'Drift' {
                    [IO.File]::AppendAllText(
                        (Join-Path $blockedConsumer.Repository `
                            '.github/scripts/MeAndAI.ProtocolUpdate.psm1'),
                        "`n# committed drift`n",
                        [Text.UTF8Encoding]::new($false)
                    )
                    Invoke-TestGit -Repository $blockedConsumer.Repository -Arguments @(
                        'add', '--', '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
                    ) | Out-Null
                }
            }
            if ([string]$blockedRoute.Mutation -cne 'None') {
                Invoke-TestGit -Repository $blockedConsumer.Repository -Arguments @(
                    'commit', '-m', "Create $($blockedRoute.Name) routing fixture"
                ) | Out-Null
                Invoke-TestGit -Repository $blockedConsumer.Repository -Arguments @(
                    'push', 'origin', 'main'
                ) | Out-Null
            }
            $blockedError = ''
            try {
                & $launcherPath -TargetPath $blockedConsumer.Repository `
                    -ProtocolTag ([string]$blockedRoute.TargetTag) `
                    -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $blockedError = $_.Exception.Message
            }
            $blockedMutations = @($global:QuickAdoptionGhCalls | Where-Object {
                ($_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'secret' -and
                 $_.Arguments[1] -ceq 'set') -or
                ($_.Arguments.Count -ge 2 -and $_.Arguments[0] -ceq 'workflow' -and
                 $_.Arguments[1] -ceq 'run') -or
                ($_.Arguments.Count -ge 3 -and $_.Arguments[0] -ceq 'label' -and
                 $_.Arguments[1] -ceq 'create')
            })
            $wrongMissingGitlinkGate = (
                [string]$blockedRoute.Mutation -ceq 'MissingGitlink' -and
                $blockedError -cnotlike
                    '*requires an explicit adoption strategy*' -and
                $blockedError -cnotlike
                    "*reserved .gitmodules subsection '.ai/protocol'*"
            )
            if (-not $blockedError -or $blockedMutations.Count -ne 0 -or
                $wrongMissingGitlinkGate) {
                Add-Failure "TEST-0113/TEST-0130 $($blockedRoute.Name) adoption state did not fail at its exact route before secret/repository workflow mutation: $blockedError"
            }
        }
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0113'
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0129'
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0130'
    }
}
catch {
    Add-Failure "Quick-adoption test harness failed: $($_.Exception.Message) [$($_.ScriptStackTrace)]"
}
finally {
    if ($null -ne $script:QuickAdoptionProtocolFixture) {
        try {
            Assert-QuickAdoptionImmutableFixture
        }
        catch {
            Add-Failure "TEST-0116 immutable fixture teardown validation failed: $($_.Exception.Message)"
        }
    }
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Invoke-RestMethod -ErrorAction SilentlyContinue
    foreach ($name in @(
        'MEANDAI_TEST_CODEX_LOG', 'MEANDAI_TEST_CODEX_MODE',
        'MEANDAI_TEST_CODEX_SANDBOX_MODE',
        'MEANDAI_TEST_CODEX_TARGET', 'MEANDAI_TEST_CODEX_REMOTE',
        'MEANDAI_TEST_PROTOCOL_REPOSITORY'
    )) {
        [Environment]::SetEnvironmentVariable($name, $null)
    }
    [Environment]::SetEnvironmentVariable('GH_HOST', $originalGitHubHost, 'Process')
    [Environment]::SetEnvironmentVariable('CODEX_HOME', $originalCodexHome, 'Process')
    foreach ($path in $tempRoots) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if (Test-QuickAdoptionShard -Name 'CurrentLauncherRecovery') {
    $launcher = Get-QuickAdoptionLauncherSource
    foreach ($requiredRepeatRouteText in @(
        'Get-ExistingAdoptionRoute',
        'AlreadyCurrent',
        'CompatibleUpdate',
        'Invoke-LocalCurrentLauncherRecovery',
        'Running target-bound updater recovery',
        'The installed updater seed was preserved'
    )) {
        if (-not $launcher.Contains($requiredRepeatRouteText)) {
            Add-Failure "TEST-0113 launcher lacks repeat-adoption route '$requiredRepeatRouteText'."
        }
    }

    $launcherTokens = $null
    $launcherParseErrors = $null
    $launcherAst = [Management.Automation.Language.Parser]::ParseInput(
        $launcher,
        [ref]$launcherTokens,
        [ref]$launcherParseErrors
    )
    $recoveryFunctions = @($launcherAst.FindAll({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq 'Invoke-LocalCurrentLauncherRecovery'
    }, $true))
    if ($recoveryFunctions.Count -ne 1) {
        Add-Failure 'TEST-0126 launcher must define one current-launcher recovery boundary.'
    }
    else {
        $recoveryText = $recoveryFunctions[0].Extent.Text
        foreach ($requiredRecoveryContract in @(
            "'repo', 'clone', `$Repository, `$consumerClone",
            "'repo', 'clone', `$ProtocolRepository, `$protocolSource",
            'The consumer default branch changed before its isolated recovery clone was bound.',
            'The cloned protocol tag does not match the verified immutable release commit.',
            "'auth', 'token', '--hostname', 'github.com'",
            '-RecoverMergedPullRequests',
            '-CurrentLauncher',
            '-RequestedTargetTag $TargetTag',
            '-RequestedTargetCommit $TargetCommit',
            '-RequestedBaseSha $HeadSha',
            '-ProtocolSourcePath $protocolSource',
            'GITHUB_REPOSITORY',
            'GITHUB_WORKSPACE',
            'DEFAULT_BRANCH',
            'GH_TOKEN',
            'ISSUE_TOKEN',
            'PROTOCOL_TOKEN',
            'GH_HOST',
            'finally',
            'Remove-Item -LiteralPath $temporaryRoot -Recurse -Force',
            'The maintainer checkout changed during isolated current-launcher recovery.'
        )) {
            if (-not $recoveryText.Contains($requiredRecoveryContract)) {
                Add-Failure "TEST-0126 current-launcher recovery lacks '$requiredRecoveryContract'."
            }
        }
        $mergedRecoveryIndex = $recoveryText.IndexOf(
            '& $adapterPath -RecoverMergedPullRequests',
            [StringComparison]::Ordinal
        )
        $currentLauncherIndex = $recoveryText.IndexOf(
            '& $adapterPath -CurrentLauncher',
            [StringComparison]::Ordinal
        )
        if ($mergedRecoveryIndex -lt 0 -or $currentLauncherIndex -lt 0 -or
            $mergedRecoveryIndex -ge $currentLauncherIndex) {
            Add-Failure 'TEST-0156 target-bound launcher does not recover exact retained merged branches before current-update planning.'
        }
        if ($recoveryText.Contains('MEANDAI_UPDATER_TOKEN') -or
            $recoveryText.Contains('MEANDAI_PROTOCOL_TOKEN') -or
            $recoveryText.Contains('FG_PAT.txt') -or
            $recoveryText.Contains('MEANDAI_RO_FG_PAT.txt')) {
            Add-Failure 'TEST-0126 current-launcher recovery attempts to read or name stored credential material.'
        }
    }

    $compatibleRoute = [regex]::Match(
        $launcher,
        "(?s)if \(\[string\]\`$existingAdoptionRoute\.State -ceq 'CompatibleUpdate'\) \{(?<body>.*?)\r?\n\s*\}\r?\n\s*\r?\n\s*Set-QuickAdoptionProgress -Status 'Publishing canonical seed workflow'",
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if (-not $compatibleRoute.Success -or
        -not $compatibleRoute.Groups['body'].Value.Contains(
            'Invoke-LocalCurrentLauncherRecovery'
        ) -or
        $compatibleRoute.Groups['body'].Value.Contains('Invoke-LifecycleWorkflow') -or
        $compatibleRoute.Groups['body'].Value.IndexOf(
            'if ($SkipLifecycleDispatch)', [StringComparison]::Ordinal
        ) -gt $compatibleRoute.Groups['body'].Value.IndexOf(
            'Invoke-LocalCurrentLauncherRecovery', [StringComparison]::Ordinal
        )) {
        Add-Failure 'TEST-0126 CompatibleUpdate is not routed through the target-bound local launcher after its explicit skip gate.'
    }

    if ($recoveryFunctions.Count -eq 1) {
        $recoveryTestRoot = Join-Path ([IO.Path]::GetTempPath()) `
            "meandai-quick-current-launcher-$([guid]::NewGuid().ToString('N'))"
        $recoveryModule = $null
        $testLocation = (Get-Location).Path
        $savedRecoveryEnvironment = @{
            GITHUB_REPOSITORY = [Environment]::GetEnvironmentVariable(
                'GITHUB_REPOSITORY', 'Process'
            )
            GITHUB_WORKSPACE = [Environment]::GetEnvironmentVariable(
                'GITHUB_WORKSPACE', 'Process'
            )
            DEFAULT_BRANCH = [Environment]::GetEnvironmentVariable(
                'DEFAULT_BRANCH', 'Process'
            )
            GH_TOKEN = [Environment]::GetEnvironmentVariable(
                'GH_TOKEN', 'Process'
            )
            ISSUE_TOKEN = [Environment]::GetEnvironmentVariable(
                'ISSUE_TOKEN', 'Process'
            )
            PROTOCOL_TOKEN = [Environment]::GetEnvironmentVariable(
                'PROTOCOL_TOKEN', 'Process'
            )
            GH_HOST = [Environment]::GetEnvironmentVariable(
                'GH_HOST', 'Process'
            )
            MEANDAI_TEST_CURRENT_LAUNCHER_RECORD = `
                [Environment]::GetEnvironmentVariable(
                    'MEANDAI_TEST_CURRENT_LAUNCHER_RECORD', 'Process'
                )
            MEANDAI_TEST_CURRENT_LAUNCHER_FAIL = `
                [Environment]::GetEnvironmentVariable(
                    'MEANDAI_TEST_CURRENT_LAUNCHER_FAIL', 'Process'
                )
            MEANDAI_TEST_POP_LOCATION_FAIL = `
                [Environment]::GetEnvironmentVariable(
                    'MEANDAI_TEST_POP_LOCATION_FAIL', 'Process'
                )
        }
        try {
            [IO.Directory]::CreateDirectory($recoveryTestRoot) | Out-Null
            $consumerSeed = Join-Path $recoveryTestRoot 'consumer-seed'
            $consumerRemote = Join-Path $recoveryTestRoot 'consumer.git'
            $maintainerRepository = Join-Path $recoveryTestRoot 'maintainer'
            & git init -b main $consumerSeed 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw 'Unable to initialize the current-launcher consumer fixture.'
            }
            Set-TestGitIdentity -Repository $consumerSeed
            [IO.File]::WriteAllText(
                (Join-Path $consumerSeed 'app.txt'),
                "consumer`n",
                [Text.UTF8Encoding]::new($false)
            )
            Invoke-TestGit -Repository $consumerSeed -Arguments @(
                'add', '--', 'app.txt'
            ) | Out-Null
            Invoke-TestGit -Repository $consumerSeed -Arguments @(
                'commit', '-m', 'Create recovery consumer fixture'
            ) | Out-Null
            Invoke-TestGit -Repository $recoveryTestRoot -Arguments @(
                'clone', '--bare', $consumerSeed, $consumerRemote
            ) | Out-Null
            Invoke-TestGit -Repository $recoveryTestRoot -Arguments @(
                'clone', $consumerRemote, $maintainerRepository
            ) | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $maintainerRepository 'preserved.tmp'),
                "preserve me`n",
                [Text.UTF8Encoding]::new($false)
            )
            $consumerHead = (@(Invoke-TestGit `
                -Repository $maintainerRepository `
                -Arguments @('rev-parse', 'HEAD')))[0]
            $maintainerStatusBefore = @((Invoke-TestGit `
                -Repository $maintainerRepository `
                -Arguments @(
                    'status', '--porcelain=v1', '--untracked-files=all'
                ))) -join "`n"

            $protocolSeed = Join-Path $recoveryTestRoot 'protocol-seed'
            & git init -b main $protocolSeed 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw 'Unable to initialize the current-launcher protocol fixture.'
            }
            Set-TestGitIdentity -Repository $protocolSeed
            [IO.File]::WriteAllText(
                (Join-Path $protocolSeed 'VERSION'),
                '0.12.2',
                [Text.UTF8Encoding]::new($false)
            )
            $adapterPath = Join-Path $protocolSeed `
                'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $adapterPath)) |
                Out-Null
            $adapterFixture = @'
[CmdletBinding()]
param(
    [switch]$RecoverMergedPullRequests,
    [switch]$CurrentLauncher,
    [string]$RequestedTargetTag,
    [string]$RequestedTargetCommit,
    [string]$RequestedBaseSha,
    [string]$ProtocolSourcePath
)
$record = [ordered]@{
    RecoverMergedPullRequests = [bool]$RecoverMergedPullRequests
    CurrentLauncher = [bool]$CurrentLauncher
    TargetTag = $RequestedTargetTag
    TargetCommit = $RequestedTargetCommit
    BaseSha = $RequestedBaseSha
    Repository = $env:GITHUB_REPOSITORY
    Workspace = $env:GITHUB_WORKSPACE
    DefaultBranch = $env:DEFAULT_BRANCH
    ProtocolSourcePath = $ProtocolSourcePath
    GitHubHost = $env:GH_HOST
    TokensBound = -not [string]::IsNullOrWhiteSpace([string]$env:GH_TOKEN) -and
        [string]$env:GH_TOKEN -ceq [string]$env:ISSUE_TOKEN -and
        [string]$env:GH_TOKEN -ceq [string]$env:PROTOCOL_TOKEN
}
[IO.File]::AppendAllText(
    $env:MEANDAI_TEST_CURRENT_LAUNCHER_RECORD,
    (($record | ConvertTo-Json -Compress) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
)
Set-Location -LiteralPath $env:GITHUB_WORKSPACE
if ($env:MEANDAI_TEST_CURRENT_LAUNCHER_FAIL -ceq 'true' -and
    $CurrentLauncher) {
    throw 'simulated adapter interruption'
}
'@
            [IO.File]::WriteAllText(
                $adapterPath,
                $adapterFixture,
                [Text.UTF8Encoding]::new($false)
            )
            Invoke-TestGit -Repository $protocolSeed -Arguments @(
                'add', '--', 'VERSION',
                'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
            ) | Out-Null
            Invoke-TestGit -Repository $protocolSeed -Arguments @(
                'commit', '-m', 'Create current-launcher protocol fixture'
            ) | Out-Null
            Invoke-TestGit -Repository $protocolSeed -Arguments @(
                'tag', 'v0.12.2'
            ) | Out-Null
            $protocolCommit = (@(Invoke-TestGit -Repository $protocolSeed `
                -Arguments @('rev-parse', 'HEAD')))[0]

            $recoveryModule = New-Module `
                -Name "MeAndAIQuickRecovery$([guid]::NewGuid().ToString('N'))" `
                -ArgumentList @(
                    $recoveryFunctions[0].Extent.Text,
                    $consumerRemote,
                    $protocolSeed
                ) `
                -ScriptBlock {
                    param(
                        [string]$RecoveryDefinition,
                        [string]$ConsumerSource,
                        [string]$ProtocolRepositorySource
                    )
                    $script:ProtocolRepository = 'hasanmanzak/meAndAI'

                    function Invoke-Git {
                        param(
                            [Parameter(Mandatory)][string]$Repository,
                            [Parameter(Mandatory)][string[]]$Arguments,
                            [switch]$AllowFailure
                        )
                        $previousPreference = $ErrorActionPreference
                        $ErrorActionPreference = 'Continue'
                        try {
                            $output = @(& git -C $Repository @Arguments 2>&1)
                            $exitCode = $LASTEXITCODE
                        }
                        finally {
                            $ErrorActionPreference = $previousPreference
                        }
                        if ($exitCode -ne 0 -and -not $AllowFailure) {
                            throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
                        }
                        return [pscustomobject]@{
                            ExitCode = $exitCode
                            Output = @($output | ForEach-Object { [string]$_ })
                        }
                    }

                    function Invoke-External {
                        param(
                            [Parameter(Mandatory)][string]$Command,
                            [Parameter(Mandatory)][string[]]$Arguments,
                            [string]$InputText = '',
                            [switch]$AllowFailure
                        )
                        if ($Command -ceq 'gh' -and
                            ($Arguments -join ' ') -ceq
                                'auth token --hostname github.com') {
                            return [pscustomobject]@{
                                ExitCode = 0
                                Output = @('test-auth-token')
                            }
                        }
                        if ($Command -cne 'gh' -or $Arguments.Count -lt 4 -or
                            $Arguments[0] -cne 'repo' -or
                            $Arguments[1] -cne 'clone') {
                            throw 'Recovery orchestration invoked an unexpected external command.'
                        }
                        $cloneSource = switch -CaseSensitive ($Arguments[2]) {
                            'test-owner/recovery-consumer' { $ConsumerSource }
                            'hasanmanzak/meAndAI' { $ProtocolRepositorySource }
                            default {
                                throw "Recovery clone requested unexpected repository '$($Arguments[2])'."
                            }
                        }
                        $separator = [Array]::IndexOf(
                            [object[]]$Arguments,
                            '--'
                        )
                        $gitArguments = @('clone', $cloneSource, $Arguments[3])
                        if ($separator -ge 0 -and
                            $separator + 1 -lt $Arguments.Count) {
                            $gitArguments += @($Arguments[($separator + 1)..(
                                $Arguments.Count - 1
                            )])
                        }
                        $previousPreference = $ErrorActionPreference
                        $ErrorActionPreference = 'Continue'
                        try {
                            $output = @(& git @gitArguments 2>&1)
                            $exitCode = $LASTEXITCODE
                        }
                        finally {
                            $ErrorActionPreference = $previousPreference
                        }
                        if ($exitCode -ne 0 -and -not $AllowFailure) {
                            throw "git clone failed: $($output -join [Environment]::NewLine)"
                        }
                        if ($Arguments[2] -ceq 'hasanmanzak/meAndAI') {
                            $clonedTags = @(& git -C $Arguments[3] tag --list 2>&1)
                            if ($LASTEXITCODE -ne 0 -or
                                $clonedTags -cnotcontains 'v0.12.2') {
                                throw "Protocol clone '$cloneSource' omitted target tag; observed: $($clonedTags -join ', ')."
                            }
                        }
                        return [pscustomobject]@{
                            ExitCode = $exitCode
                            Output = @($output | ForEach-Object { [string]$_ })
                        }
                    }

                    function Assert-CredentialFilesAbsent {
                        param([Parameter(Mandatory)][string]$Repository)
                        $credentialFiles = @(Get-ChildItem -LiteralPath $Repository `
                            -Recurse -Force -File | Where-Object {
                                [string]$_.Name -cin @(
                                    'FG_PAT.txt', 'MEANDAI_RO_FG_PAT.txt'
                                )
                            })
                        if ($credentialFiles.Count -ne 0) {
                            throw 'Credential material entered the isolated recovery clone.'
                        }
                    }

                    function Pop-Location {
                        if ([Environment]::GetEnvironmentVariable(
                            'MEANDAI_TEST_POP_LOCATION_FAIL', 'Process'
                        ) -ceq 'true') {
                            throw 'simulated location-stack interruption'
                        }
                        Microsoft.PowerShell.Management\Pop-Location
                    }

                    Invoke-Expression $RecoveryDefinition
                }

            $recordPath = Join-Path $recoveryTestRoot 'adapter-record.json'
            [Environment]::SetEnvironmentVariable(
                'GITHUB_REPOSITORY', 'preserved/repository', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GITHUB_WORKSPACE', 'preserved-workspace', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'DEFAULT_BRANCH', 'preserved-branch', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GH_TOKEN', 'preserved-gh-token', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'ISSUE_TOKEN', 'preserved-issue-token', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'PROTOCOL_TOKEN', 'preserved-protocol-token', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'GH_HOST', 'preserved.example', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_CURRENT_LAUNCHER_RECORD', $recordPath, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_CURRENT_LAUNCHER_FAIL', $null, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_POP_LOCATION_FAIL', $null, 'Process'
            )
            $recoveryArguments = @{
                Repository = 'test-owner/recovery-consumer'
                Branch = 'main'
                HeadSha = $consumerHead
                TargetTag = 'v0.12.2'
                TargetCommit = $protocolCommit
                MaintainerRepository = $maintainerRepository
            }
            $recoveryRootsBefore = @(Get-ChildItem `
                -LiteralPath ([IO.Path]::GetTempPath()) -Directory `
                -Filter 'meandai-update-recovery-*' | ForEach-Object FullName)
            & $recoveryModule {
                param($Arguments)
                Invoke-LocalCurrentLauncherRecovery @Arguments
            } $recoveryArguments | Out-Null
            $recoveryRootsAfter = @(Get-ChildItem `
                -LiteralPath ([IO.Path]::GetTempPath()) -Directory `
                -Filter 'meandai-update-recovery-*' | ForEach-Object FullName)
            $records = @([IO.File]::ReadAllLines($recordPath) |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { $_ | ConvertFrom-Json })
            $mergedRecoveryRecord = if ($records.Count -ge 1) { $records[0] }
            else { $null }
            $record = if ($records.Count -ge 2) { $records[1] } else { $null }
            $maintainerStatusAfter = @((Invoke-TestGit `
                -Repository $maintainerRepository `
                -Arguments @(
                    'status', '--porcelain=v1', '--untracked-files=all'
                ))) -join "`n"
            if ($records.Count -ne 2 -or
                $mergedRecoveryRecord.RecoverMergedPullRequests -isnot [bool] -or
                -not [bool]$mergedRecoveryRecord.RecoverMergedPullRequests -or
                [bool]$mergedRecoveryRecord.CurrentLauncher -or
                -not [bool]$mergedRecoveryRecord.TokensBound -or
                [string]$mergedRecoveryRecord.GitHubHost -cne 'github.com' -or
                [bool]$record.RecoverMergedPullRequests -or
                -not [bool]$record.TokensBound -or
                [string]$record.GitHubHost -cne 'github.com' -or
                $record.CurrentLauncher -isnot [bool] -or
                -not [bool]$record.CurrentLauncher -or
                [string]$record.TargetTag -cne 'v0.12.2' -or
                [string]$record.TargetCommit -cne $protocolCommit -or
                [string]$record.BaseSha -cne $consumerHead -or
                [string]$record.Repository -cne 'test-owner/recovery-consumer' -or
                [string]$record.DefaultBranch -cne 'main' -or
                [string]$record.Workspace -cnotmatch 'meandai-update-recovery-[0-9a-f]{32}[\\/]consumer$' -or
                [string]$record.ProtocolSourcePath -cnotmatch 'meandai-update-recovery-[0-9a-f]{32}[\\/]protocol-source$' -or
                (Test-Path -LiteralPath ([string]$record.Workspace)) -or
                (Test-Path -LiteralPath ([string]$record.ProtocolSourcePath)) -or
                (Compare-Object $recoveryRootsBefore $recoveryRootsAfter) -or
                $maintainerStatusAfter -cne $maintainerStatusBefore -or
                [Environment]::GetEnvironmentVariable(
                    'GITHUB_REPOSITORY', 'Process'
                ) -cne 'preserved/repository' -or
                [Environment]::GetEnvironmentVariable(
                    'GITHUB_WORKSPACE', 'Process'
                ) -cne 'preserved-workspace' -or
                [Environment]::GetEnvironmentVariable(
                    'DEFAULT_BRANCH', 'Process'
                ) -cne 'preserved-branch' -or
                [Environment]::GetEnvironmentVariable(
                    'GH_TOKEN', 'Process'
                ) -cne 'preserved-gh-token' -or
                [Environment]::GetEnvironmentVariable(
                    'ISSUE_TOKEN', 'Process'
                ) -cne 'preserved-issue-token' -or
                [Environment]::GetEnvironmentVariable(
                    'PROTOCOL_TOKEN', 'Process'
                ) -cne 'preserved-protocol-token' -or
                [Environment]::GetEnvironmentVariable(
                    'GH_HOST', 'Process'
                ) -cne 'preserved.example' -or
                (Get-Location).Path -cne $testLocation) {
                Add-Failure 'TEST-0156 successful local recovery did not finalize retained merges before current planning while preserving exact bindings, environment, checkout, and temporary-root cleanup.'
            }

            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_CURRENT_LAUNCHER_FAIL', 'true', 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_POP_LOCATION_FAIL', 'true', 'Process'
            )
            Remove-Item -LiteralPath $recordPath -Force
            $interruptionError = ''
            $recoveryRootsBefore = @(Get-ChildItem `
                -LiteralPath ([IO.Path]::GetTempPath()) -Directory `
                -Filter 'meandai-update-recovery-*' | ForEach-Object FullName)
            try {
                & $recoveryModule {
                    param($Arguments)
                    Invoke-LocalCurrentLauncherRecovery @Arguments
                } $recoveryArguments | Out-Null
            }
            catch {
                $interruptionError = $_.Exception.Message
            }
            $recoveryRootsAfter = @(Get-ChildItem `
                -LiteralPath ([IO.Path]::GetTempPath()) -Directory `
                -Filter 'meandai-update-recovery-*' | ForEach-Object FullName)
            $interruptedRecords = @([IO.File]::ReadAllLines($recordPath) |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { $_ | ConvertFrom-Json })
            $maintainerStatusAfter = @((Invoke-TestGit `
                -Repository $maintainerRepository `
                -Arguments @(
                    'status', '--porcelain=v1', '--untracked-files=all'
                ))) -join "`n"
            if ($interruptionError -cnotlike '*simulated adapter interruption*' -or
                $interruptionError -cnotlike '*simulated location-stack interruption*' -or
                $interruptedRecords.Count -ne 2 -or
                -not [bool]$interruptedRecords[0].RecoverMergedPullRequests -or
                [bool]$interruptedRecords[0].CurrentLauncher -or
                [bool]$interruptedRecords[1].RecoverMergedPullRequests -or
                -not [bool]$interruptedRecords[1].CurrentLauncher -or
                -not [bool]$interruptedRecords[0].TokensBound -or
                -not [bool]$interruptedRecords[1].TokensBound -or
                [string]$interruptedRecords[0].GitHubHost -cne 'github.com' -or
                [string]$interruptedRecords[1].GitHubHost -cne 'github.com' -or
                (Compare-Object $recoveryRootsBefore $recoveryRootsAfter) -or
                $maintainerStatusAfter -cne $maintainerStatusBefore -or
                [Environment]::GetEnvironmentVariable(
                    'GITHUB_REPOSITORY', 'Process'
                ) -cne 'preserved/repository' -or
                [Environment]::GetEnvironmentVariable(
                    'GITHUB_WORKSPACE', 'Process'
                ) -cne 'preserved-workspace' -or
                [Environment]::GetEnvironmentVariable(
                    'DEFAULT_BRANCH', 'Process'
                ) -cne 'preserved-branch' -or
                [Environment]::GetEnvironmentVariable(
                    'GH_TOKEN', 'Process'
                ) -cne 'preserved-gh-token' -or
                [Environment]::GetEnvironmentVariable(
                    'ISSUE_TOKEN', 'Process'
                ) -cne 'preserved-issue-token' -or
                [Environment]::GetEnvironmentVariable(
                    'PROTOCOL_TOKEN', 'Process'
                ) -cne 'preserved-protocol-token' -or
                [Environment]::GetEnvironmentVariable(
                    'GH_HOST', 'Process'
                ) -cne 'preserved.example' -or
                (Get-Location).Path -cne $testLocation) {
                Add-Failure "TEST-0156 interrupted local recovery did not preserve ordered recovery, checkout/environment, and temp-root cleanup: $interruptionError"
            }
        }
        catch {
            Add-Failure "TEST-0126 current-launcher orchestration harness failed: $($_.Exception.Message)"
        }
        finally {
            Set-Location -LiteralPath $testLocation
            if ($null -ne $recoveryModule) {
                Remove-Module -ModuleInfo $recoveryModule -Force `
                    -ErrorAction SilentlyContinue
            }
            foreach ($entry in $savedRecoveryEnvironment.GetEnumerator()) {
                [Environment]::SetEnvironmentVariable(
                    [string]$entry.Key,
                    $entry.Value,
                    'Process'
                )
            }
            if (Test-Path -LiteralPath $recoveryTestRoot) {
                Remove-Item -LiteralPath $recoveryTestRoot -Recurse -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($null -ne $script:QuickAdoptionContractModule) {
    Remove-Module -ModuleInfo $script:QuickAdoptionContractModule -Force `
        -ErrorAction SilentlyContinue
    $script:QuickAdoptionContractModule = $null
}

$survivingInitialPolicyModules = @(
    Get-TestLoadedInitialAdoptionPolicyModules
)
if ($survivingInitialPolicyModules.Count -ne 0) {
    Add-Failure "TEST-0130 quick-adoption suite left dynamic initial-policy modules loaded: $($survivingInitialPolicyModules.Name -join ', ')"
}

if ($failures.Count -gt 0) {
    Write-Host "Quick-adoption tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

if ($Shard -ceq 'All') {
    Write-Host 'Quick-adoption tests passed for all declared scenarios in this suite.' -ForegroundColor Green
    $scenarioResult = New-MeAndAIScenarioResult `
        -Owner 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1' -SourcePaths @($PSCommandPath) `
        -AuthorityPath $scenarioAuthorityPath
    Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
}
else {
    Write-Host "Quick-adoption Windows compatibility shard '$Shard' passed." `
        -ForegroundColor Green
    $compatibilityResult = [ordered]@{
        schema = 1
        suite = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
        shard = $Shard
        passed = $true
    }
    Write-Host ('MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
        ($compatibilityResult | ConvertTo-Json -Compress))
}
