[CmdletBinding()]
param(
    [ValidateSet(
        'All',
        'ContractsPreflight',
        'AdoptionLifecycle',
        'IntegrityCompletedGraph',
        'IntegrityManifestIssue',
        'IntegrityCodexFailure',
        'IntegrityMetadataCredential',
        'RepositoryRoutes'
    )]
    [string]$Shard = 'All'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force
$launcherPath = Join-Path $root 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$guidePath = Join-Path $root 'docs/quick-adoption.md'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$mockCodexScriptPath = Join-Path $root 'tests/fixtures/Invoke-MockCodex.ps1'
$mockCodexWindowsPath = Join-Path $root 'tests/fixtures/Invoke-MockCodex.cmd'
$mockCodexUnixPath = Join-Path $root 'tests/fixtures/Invoke-MockCodex.sh'
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
$canonicalAdoptionProposedPaths = @(
    $workflowRelativePath, '.gitmodules', '.ai/protocol'
) + @($canonicalAdoptionAssets | ForEach-Object { [string]$_.ConsumerPath })
$canonicalAdoptionRequiredTasks = @(
    'Create or reconcile the repository labels required by the protocol.',
    'Create project-owned feature and decision records for adoption.',
    'Tailor project-local memory without importing protocol-repository facts.',
    'Resolve every collision through semantic review; do not overwrite blindly.',
    'Create and run the project test evidence required by DoR and DoD.',
    'Verify all documentation links and traceability references.',
    'Remove the manifest before marking the pull request ready or merging it.'
)
$failures = [System.Collections.Generic.List[string]]::new()
$tempRoots = [System.Collections.Generic.List[string]]::new()
$originalGitHubHost = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')
$originalCodexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
$script:QuickAdoptionProtocolFixture = $null

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Test-QuickAdoptionShard {
    param([Parameter(Mandatory)][string]$Name)

    return $Shard -ceq 'All' -or $Shard -ceq $Name
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

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    return Invoke-TestGit -Repository $Repository -Arguments $Arguments
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

function Set-TestGitIdentity {
    param([string]$Repository)

    Invoke-TestGit -Repository $Repository -Arguments @('config', 'user.name', 'meAndAI Test') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'user.email', 'meandai-test@example.invalid') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
}

function Copy-CanonicalProtocolFixture {
    param([Parameter(Mandatory)][string]$Destination)

    [IO.File]::WriteAllText(
        (Join-Path $Destination 'PROTOCOL.md'),
        "# Mock protocol source`n",
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $Destination 'VERSION'),
        '0.10.2',
        [Text.UTF8Encoding]::new($false)
    )
    $capabilitiesModulePath = 'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
    foreach ($templatePath in @(
        $capabilitiesModulePath,
        'templates/project/.github/workflows/meandai-protocol-update.yml'
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

function Save-MockProtocolAssetSnapshot {
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]
        [System.Collections.Generic.Dictionary[string, object]]$Snapshots
    )

    foreach ($asset in $canonicalManagedUpdaterAssets) {
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
    Copy-CanonicalProtocolFixture -Destination $protocolRepository
    $fixtureWorkflowPath = Join-Path $protocolRepository `
        'templates/project/.github/workflows/meandai-protocol-update.yml'
    $legacyWorkflow = [IO.File]::ReadAllText($fixtureWorkflowPath).Replace(
        'BOOTSTRAP_PROTOCOL_TAG: v0.10.2',
        'BOOTSTRAP_PROTOCOL_TAG: v0.9.2'
    )
    [IO.File]::WriteAllText(
        $fixtureWorkflowPath, $legacyWorkflow, [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllText(
        (Join-Path $protocolRepository 'VERSION'),
        '0.9.2',
        [Text.UTF8Encoding]::new($false)
    )
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

    Copy-CanonicalProtocolFixture -Destination $protocolRepository
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'add', '--', '.'
    ) | Out-Null
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'commit', '-m', 'Create mock current protocol release'
    ) | Out-Null
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'tag', 'v0.10.2'
    ) | Out-Null
    $currentSha = (@(Invoke-TestGit -Repository $protocolRepository `
        -Arguments @('rev-parse', 'HEAD')))[0]
    $releaseCommits['v0.10.2'] = $currentSha
    Save-MockProtocolAssetSnapshot -Tag 'v0.10.2' `
        -Repository $protocolRepository -Snapshots $assetSnapshots

    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'switch', '--detach'
    ) | Out-Null
    foreach ($futureTag in @('v0.10.3', 'v1.0.0')) {
        $futureVersion = $futureTag.Substring(1)
        $futureWorkflow = [IO.File]::ReadAllText($workflowPath).Replace(
            'BOOTSTRAP_PROTOCOL_TAG: v0.10.2',
            "BOOTSTRAP_PROTOCOL_TAG: $futureTag"
        )
        [IO.File]::WriteAllText(
            $fixtureWorkflowPath, $futureWorkflow, [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $protocolRepository 'VERSION'),
            $futureVersion,
            [Text.UTF8Encoding]::new($false)
        )
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

    $archivePath = Join-Path $protocolFixtureRoot 'protocol-v0.10.2.zip'
    Invoke-TestGit -Repository $protocolRepository -Arguments @(
        'archive', '--format=zip', '--prefix=openai-mock-protocol/',
        '-o', $archivePath, 'v0.10.2'
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
    $global:QuickAdoptionPrListCalls = 0
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
    param([Parameter(Mandatory)][string]$Name)

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
    $completedBranch = 'automation/meandai-capabilities-v0.10.2'
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
    $marker = [ordered]@{
        schema = 2
        state = $proposalState
        target = 'v0.10.2'
        protocolSha = $global:QuickAdoptionProtocolSha
        head = $global:QuickAdoptionPrHead
        repository = $global:QuickAdoptionRepoName
        actor = $global:QuickAdoptionOwner
    } | ConvertTo-Json -Compress
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

function Publish-MockAdoptionBranch {
    $branch = 'automation/meandai-capabilities-v0.10.2'
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
        $manifestCollisions = @('AGENTS.md')
    }
    $manifestData = [ordered]@{
        schema = 1
        operation = 'ai-capabilities-adoption'
        state = if ($manifestOnly) { 'AdoptionReviewRequired' } else { 'BootstrapReady' }
        repository = $global:QuickAdoptionRepoName
        targetTag = 'v0.10.2'
        protocolSha = $global:QuickAdoptionProtocolSha
        collisions = $manifestCollisions
        proposedPaths = $canonicalAdoptionProposedPaths
        requiredTasks = $canonicalAdoptionRequiredTasks
    }
    switch -CaseSensitive ($global:QuickAdoptionManifestMode) {
        'Valid' { }
        'AdditionalProperty' { $manifestData['unexpected'] = $true }
        'MissingProperty' { $manifestData.Remove('requiredTasks') }
        'WrongRequiredTasks' {
            $manifestData['requiredTasks'] = @('Remove the manifest before readiness.')
        }
        'WrongProposedPaths' {
            $manifestData['proposedPaths'] = @($canonicalAdoptionProposedPaths | Select-Object -Skip 1)
        }
        'WrongCollisions' { $manifestData['collisions'] = @('docs/ideas/README.md') }
        'WrongRepository' { $manifestData['repository'] = 'other/consumer' }
        'WrongTargetTag' { $manifestData['targetTag'] = 'v0.8.4' }
        'WrongProtocolSha' { $manifestData['protocolSha'] = 'b' * 40 }
        'WrongState' { $manifestData['state'] = 'AdoptionReviewRequired' }
        'WrongOperation' { $manifestData['operation'] = 'other-operation' }
        'WrongSchema' { $manifestData['schema'] = 2 }
        'WrongSchemaType' { $manifestData['schema'] = '1' }
        'WrongCollisionType' { $manifestData['collisions'] = 'AGENTS.md' }
        'ArrayRoot' { }
        default {
            throw "Unknown mock adoption manifest mode '$($global:QuickAdoptionManifestMode)'."
        }
    }
    $manifest = if ($global:QuickAdoptionManifestMode -ceq 'ArrayRoot') {
        @($manifestData, $manifestData) | ConvertTo-Json -Depth 5 -Compress
    }
    else {
        $manifestData | ConvertTo-Json -Depth 5 -Compress
    }
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
        $proposalPaths = @('.gitmodules', '.ai/adoption/meandai-capabilities.json') + @(
            $canonicalAdoptionAssets | ForEach-Object { [string]$_.ConsumerPath }
        )
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
    $branch = 'automation/meandai-capabilities-v0.10.2'
    Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
        'push', 'origin', '--delete', $branch
    ) | Out-Null
    $global:QuickAdoptionPrHead = ''
    $global:QuickAdoptionPrBody = ''
    $global:QuickAdoptionPrDraft = $true
    $global:QuickAdoptionPrState = 'OPEN'
    $global:QuickAdoptionPrReadyCalls = 0
    $global:QuickAdoptionPrBodyEditCalls = 0
    $global:QuickAdoptionPrBodyEditMode = 'Normal'
    $global:QuickAdoptionCompletedEditFailures = 0
    $global:QuickAdoptionRunListCalls = 0
    $global:QuickAdoptionWorkflowDispatched = $false
    $global:QuickAdoptionExpectedPublishedHead = ''
    $global:QuickAdoptionDispatchRecord = $null
    $global:QuickAdoptionPrListCalls = 0
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
        return (@{
            content = [Convert]::ToBase64String([byte[]]$asset.Bytes)
            encoding = 'base64'
            sha = [string]$asset.Sha
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 4 -and $Arguments[0] -eq 'repo' -and
        $Arguments[1] -eq 'clone' -and $Arguments[2] -eq 'hasanmanzak/meAndAI') {
        & git clone $global:QuickAdoptionProtocolRepository $Arguments[3] 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to clone the mock protocol repository.'
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'repo' -and $Arguments[1] -eq 'view') {
        if (-not $global:QuickAdoptionRepositoryExists) {
            $global:LASTEXITCODE = 1
            return 'GraphQL: Could not resolve to a Repository with the requested name.'
        }
        return (@{
            nameWithOwner = $global:QuickAdoptionRepoName
            defaultBranchRef = if ($global:QuickAdoptionDefaultBranch) {
                @{ name = $global:QuickAdoptionDefaultBranch }
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
            title = 'Track meAndAI AI capabilities adoption from v0.10.2'
            body = [IO.File]::ReadAllText($Arguments[$bodyIndex + 1])
            state = 'OPEN'
        }
        $global:QuickAdoptionIssues.Add($createdIssue)
        $global:QuickAdoptionIssue = $createdIssue
        if ($global:QuickAdoptionIssueRace) {
            $global:QuickAdoptionIssues.Add([pscustomobject]@{
                number = 83
                url = "https://github.com/$($global:QuickAdoptionRepoName)/issues/83"
                title = 'Track meAndAI AI capabilities adoption from v0.10.2'
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
        $fieldIndex = [Array]::IndexOf([object[]]$Arguments, '--field')
        if ($workflowName -cne 'meandai-protocol-update.yml' -or
            $dispatchRepository -cne $global:QuickAdoptionRepoName -or
            $dispatchRef -cne $global:QuickAdoptionDefaultBranch -or
            $fieldIndex -lt 0 -or $fieldIndex + 1 -ge $Arguments.Count -or
            [string]$Arguments[$fieldIndex + 1] -cnotmatch '^correlation_id=(?<id>[0-9a-f]{32})$') {
            throw 'Mock workflow dispatch identity is not exact.'
        }
        $global:QuickAdoptionCorrelationId = [string]$Matches.id
        $independentHead = Get-MockPublishedDefaultHead
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
            headRefName = 'automation/meandai-capabilities-v0.10.2'
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
                    schema = 2
                    state = $proposalState
                    target = 'v0.10.2'
                    protocolSha = $global:QuickAdoptionProtocolSha
                    head = ('0' * 40)
                    repository = $global:QuickAdoptionRepoName
                    actor = $global:QuickAdoptionOwner
                } | ConvertTo-Json -Compress
                $pullRequest.body = "<!-- meandai-capabilities-adoption:$badMarker -->"
            }
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
        $global:QuickAdoptionEvents.Add('pr-ready')
        $global:QuickAdoptionPrReadyCalls++
        $global:QuickAdoptionPrDraft = $false
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
        $launcherPath, $guidePath, $workflowPath, $mockCodexScriptPath,
        $mockCodexWindowsPath, $mockCodexUnixPath
    )) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            Add-Failure "TEST-0033 missing required quick-adoption asset: $requiredPath"
        }
    }

    if (Test-Path -LiteralPath $launcherPath -PathType Leaf) {
        $launcher = Get-Content -LiteralPath $launcherPath -Raw
        $tokens = $null
        $parseErrors = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            $launcherPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            Add-Failure "TEST-0033 launcher has PowerShell parse errors: $($parseErrors -join '; ')"
        }

        foreach ($required in @(
            'v0.10.2',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
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
        if (-not $mockCodex.Contains('automation/meandai-capabilities-v0.10.2')) {
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
            'v0.10.2',
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
                $_.Uri -match '/repos/hasanmanzak/meAndAI/releases/tags/v0\.10\.2$'
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
                '--ref', 'main', '--field', 'correlation_id=not-canonical')
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
            $global:QuickAdoptionDispatchRecord.Head -cne $publishedMainHead -or
            $runViewCalls.Count -ne 1 -or
            [string]$runViewCalls[0].Arguments[2] -cne '7001') {
            Add-Failure 'TEST-0090 exact dispatch was not bound to its independently resolved repository head and run identity.'
        }
        $unqualifiedGhCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            [string]$_.Host -cne 'github.com'
        })
        if ($unqualifiedGhCalls.Count -ne 0 -or
            [Environment]::GetEnvironmentVariable('GH_HOST', 'Process') -cne 'ghe.example.invalid') {
            Add-Failure 'TEST-0060 launcher GitHub operations were redirected by caller GH_HOST or did not restore it.'
        }
        $canonicalIssueMarker = '<!-- meandai-local-adoption:v0.10.2:pr-42 -->'
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
            'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.10.2'
        ))
        if ($adoptionPaths -contains '.ai/adoption/meandai-capabilities.json' -or
            $adoptionPaths -notcontains 'docs/ai-adoption.md') {
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
        $protocolSourceEndpoint = 'repos/hasanmanzak/meAndAI/contents/templates/project/.github/workflows/meandai-protocol-update.yml?ref=v0.10.2'
        $protocolSourceCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'api' -and
            $_.Arguments -contains $protocolSourceEndpoint
        })
        if ($protocolSourceCalls.Count -ne 1) {
            Add-Failure 'TEST-0045 file-free rerun did not retrieve the exact protocol source through authenticated local gh.'
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
        $global:QuickAdoptionPrBodyEditMode = 'FailCompletedOnce'
        $codexCountBeforeInterruptedCompletion = @(Get-MockCodexCalls).Count
        $interruptedCompletionBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $interruptedCompletionBlocked = $true
        }
        $interruptedRemoteHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.10.2'
        )))[0].Split("`t")[0]
        $codexCountAfterInterruptedCompletion = @(Get-MockCodexCalls).Count
        if (-not $interruptedCompletionBlocked -or
            $global:QuickAdoptionCompletedEditFailures -ne 1 -or
            $interruptedRemoteHead -cnotmatch '^[0-9a-f]{40}$' -or
            $codexCountAfterInterruptedCompletion -ne ($codexCountBeforeInterruptedCompletion + 2) -or
            $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure 'TEST-0079 completion interruption fixture did not stop after the push and before completed-marker persistence.'
        }
        $global:QuickAdoptionPrBodyEditMode = 'Normal'
        $interruptedRecoveryThrew = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $interruptedRecoveryThrew = $true
        }
        $recoveredRemoteHead = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.10.2'
        )))[0].Split("`t")[0]
        if ($interruptedRecoveryThrew -or
            $recoveredRemoteHead -cne $interruptedRemoteHead -or
            @(Get-MockCodexCalls).Count -ne $codexCountAfterInterruptedCompletion -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            -not $global:QuickAdoptionPrBody.Contains('"phase":"Completed"')) {
            Add-Failure 'TEST-0079 exact rerun did not finalize the already-pushed completion without repeating semantic work or creating a commit.'
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
            'refs/heads/automation/meandai-capabilities-v0.10.2'
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
            'refs/heads/automation/meandai-capabilities-v0.10.2'
        )))[0].Split("`t")[0]
        if ($postReadyRecoveryThrew -or
            $postReadyRecoveredHead -cne $postReadyHead -or
            @(Get-MockCodexCalls).Count -ne $codexCountAfterPostReadyFailure -or
            $global:QuickAdoptionPrBodyEditCalls -ne $bodyEditsAfterPostReadyFailure -or
            $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionIssueLabels -cnotcontains 'status:needs-review') {
            Add-Failure "TEST-0052/TEST-0087/TEST-0089 rerun after readiness did not retain the exact Completed proposal and reconcile the issue without Codex or a new commit: error='$postReadyRecoveryError'; head=$postReadyHead->$postReadyRecoveredHead; readyCalls=$($global:QuickAdoptionPrReadyCalls); issueLabels=$($global:QuickAdoptionIssueLabels -join ',')."
        }
    }

    $integrityShardNames = @(
        'IntegrityCompletedGraph',
        'IntegrityManifestIssue',
        'IntegrityCodexFailure',
        'IntegrityMetadataCredential'
    )
    $runIntegrityShards = (
        ($Shard -ceq 'All' -or $integrityShardNames -ccontains $Shard) -and
        $failures.Count -eq 0
    )
    if ($runIntegrityShards -and $Shard -cne 'All') {
        Reset-Mocks
        $integrityBaseline = New-MockCompletedAdoptionConsumer `
            -Name 'integrity-baseline'
        $existingRepo = $integrityBaseline.Repository
        $existingRemote = $integrityBaseline.Remote
        $postReadyRecoveredHead = $integrityBaseline.CompletedHead
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityCompletedGraph')) {
        $completedBranch = 'automation/meandai-capabilities-v0.10.2'
        $canonicalCompletedHead = $postReadyRecoveredHead
        $canonicalCompletedBody = [string]$global:QuickAdoptionPrBody
        foreach ($completedVariant in @(
            'Parent', 'ProposalTree', 'CheckedChangeSet', 'Credential',
            'ProtectedWorkflow', 'Protocol', 'UpdaterModule', 'UpdaterAdapter',
            'Manifest'
        )) {
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
                target = 'v0.10.2'
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
        $canonicalIssueMarker = '<!-- meandai-local-adoption:v0.10.2:pr-42 -->'
        foreach ($manifestMode in @(
            'AdditionalProperty', 'MissingProperty', 'WrongRequiredTasks',
            'WrongProposedPaths', 'WrongCollisions', 'WrongRepository',
            'WrongTargetTag', 'WrongProtocolSha', 'WrongState',
            'WrongOperation', 'WrongSchema', 'WrongSchemaType',
            'WrongCollisionType', 'ArrayRoot'
        )) {
            Reset-MockAdoptionProposal
            $global:QuickAdoptionManifestMode = $manifestMode
            $codexCountBeforeInvalidManifest = @(Get-MockCodexCalls).Count
            $invalidManifestBlocked = $false
            try {
                & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $invalidManifestBlocked = $true
            }
            if (-not $invalidManifestBlocked -or
                @(Get-MockCodexCalls).Count -ne $codexCountBeforeInvalidManifest -or
                $global:QuickAdoptionPrReadyCalls -ne 0) {
                Add-Failure "TEST-0080 launcher accepted adoption manifest mode '$manifestMode' before local Codex execution."
            }
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
                    '<!-- meandai-local-adoption:v0.10.2:pr-42 --'
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

        foreach ($negativeMode in @(
            'Unauthenticated', 'LeaveManifest', 'CreateCommit', 'RemoteRace',
            'RenameWorkflowAway', 'CaseMoveWorkflow', 'CaseVariantCredential'
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
                'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.10.2'
            ))
            if ($negativePaths -contains 'docs/ai-adoption.md') {
                Add-Failure "TEST-0040 local Codex negative mode '$negativeMode' published the local completion."
            }
        }
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0053'
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'

        Reset-MockAdoptionProposal
        Publish-MockAdoptionBranch
        $env:MEANDAI_TEST_CODEX_MODE = 'Sleep'
        $timeoutRemoteHeadBefore = (@(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.10.2'
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
            'refs/heads/automation/meandai-capabilities-v0.10.2'
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
    }

    if ($runIntegrityShards -and
        (Test-QuickAdoptionShard -Name 'IntegrityMetadataCredential')) {
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

        [IO.File]::WriteAllText(
            (Join-Path $existingRepo 'AGENTS.md'),
            "# Consumer-owned instructions`n"
        )
        Invoke-Git -Repository $existingRepo -Arguments @('add', '--', 'AGENTS.md') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Create adoption collision fixture'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $global:QuickAdoptionProposalMode = 'ManifestOnly'
        $collisionCompleted = $true
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $collisionCompleted = $false
        }
        $collisionEntry = @((Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', 'refs/heads/automation/meandai-capabilities-v0.10.2', '--', '.ai/protocol'
        )))
        $collisionPaths = @(Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.10.2'
        ))
        $expectedCollisionEntry = "160000 commit $($global:QuickAdoptionProtocolSha)`t.ai/protocol"
        if (-not $collisionCompleted -or $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $collisionEntry.Count -ne 1 -or [string]$collisionEntry[0] -cne $expectedCollisionEntry -or
            $collisionPaths -contains '.ai/adoption/meandai-capabilities.json') {
            Add-Failure 'TEST-0046 token-backed manifest-only adoption did not publish the exact canonical protocol gitlink and remove the manifest.'
        }
        Invoke-Git -Repository $existingRepo -Arguments @('rm', '--', 'AGENTS.md') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Remove adoption collision fixture'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        Reset-MockAdoptionProposal
        $global:QuickAdoptionProposalMode = 'ValidFull'

        foreach ($metadataMode in @(
            'WrongBase', 'ForeignHead', 'ForeignHeadOwner', 'CrossRepository',
            'InvalidCrossRepositoryType', 'InvalidMarker', 'WrongAuthor',
            'NonDraft', 'MarkerHeadMismatch'
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

        Set-Content -LiteralPath (Join-Path $existingRepo 'FG_PAT.txt') -Value 'write-token-value' -NoNewline
        Invoke-Git -Repository $existingRepo -Arguments @('add', '-f', '--', 'FG_PAT.txt') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('commit', '-m', 'Expose test credential path') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $secretCountBeforeTracked = $global:QuickAdoptionSecrets.Count
        $trackedTokenBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $trackedTokenBlocked = $true
        }
        if (-not $trackedTokenBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeTracked) {
            Add-Failure 'TEST-0036 tracked token file did not block before secret mutation.'
        }

        Invoke-Git -Repository $existingRepo -Arguments @('rm', '--', 'FG_PAT.txt') | Out-Null
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
    }

    if ((Test-QuickAdoptionShard -Name 'RepositoryRoutes') -and
        $failures.Count -eq 0) {
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
        $global:QuickAdoptionRepositoryExists = $false

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
        & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
            -CodexCommand $mockCodexPath | Out-Null
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
        $newRemotePaths = @(Invoke-Git -Repository $newRepo -Arguments @(
            'ls-tree', '-r', '--name-only', 'origin/main'
        ))
        if ($newRemotePaths.Count -ne 1 -or $newRemotePaths[0] -cne $workflowRelativePath) {
            Add-Failure "TEST-0035 new remote published unrelated paths: $($newRemotePaths -join ', ')"
        }
        $newStatus = @(Invoke-Git -Repository $newRepo -Arguments @('status', '--short'))
        if ($newStatus.Count -ne 1 -or $newStatus[0] -notmatch '^\?\? src/') {
            Add-Failure "TEST-0035 unrelated local content was not preserved as untracked: $($newStatus -join ', ')"
        }

        Reset-Mocks
        $currentConsumer = New-MockConnectedManagedConsumer `
            -Name 'managed-current' -InstalledTag 'v0.10.2'
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
            $currentDispatches.Count -ne 0 -or $currentPrLookups.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0 -or
            @(Get-MockCodexCalls).Count -ne $currentCodexCallsBefore) {
            Add-Failure "TEST-0113 exact current adoption was not a Git/workflow/Codex no-op after secret-name reconciliation: $currentError"
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
                -CodexCommand $mockCodexPath | Out-Null
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
            $legacyDispatches.Count -ne 1 -or -not $global:QuickAdoptionWorkflowDispatched -or
            $legacyPrLookups.Count -ne 0 -or $global:QuickAdoptionSecrets.Count -ne 0 -or
            @(Get-MockCodexCalls).Count -ne $legacyCodexCallsBefore) {
            Add-Failure "TEST-0113 exact older same-major adoption did not dispatch only its preserved installed updater: $legacyError"
        }

        foreach ($blockedRoute in @(
            [pscustomobject]@{ Name = 'manifest'; InstalledTag = 'v0.10.2'; TargetTag = 'v0.10.2'; Mutation = 'Manifest' },
            [pscustomobject]@{ Name = 'partial'; InstalledTag = 'v0.10.2'; TargetTag = 'v0.10.2'; Mutation = 'Partial' },
            [pscustomobject]@{ Name = 'missing-gitlink'; InstalledTag = 'v0.10.2'; TargetTag = 'v0.10.2'; Mutation = 'MissingGitlink' },
            [pscustomobject]@{ Name = 'drift'; InstalledTag = 'v0.10.2'; TargetTag = 'v0.10.2'; Mutation = 'Drift' },
            [pscustomobject]@{ Name = 'newer'; InstalledTag = 'v0.10.3'; TargetTag = 'v0.10.2'; Mutation = 'None' },
            [pscustomobject]@{ Name = 'cross-major'; InstalledTag = 'v0.10.2'; TargetTag = 'v1.0.0'; Mutation = 'None' }
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
                $blockedError -cnotlike '*exists without the protocol gitlink*'
            )
            if (-not $blockedError -or $blockedMutations.Count -ne 0 -or
                $wrongMissingGitlinkGate) {
                Add-Failure "TEST-0113 $($blockedRoute.Name) completed-adoption state did not fail before secret/repository workflow mutation: $blockedError"
            }
        }
        Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0113'
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
        'MEANDAI_TEST_CODEX_TARGET', 'MEANDAI_TEST_CODEX_REMOTE'
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

if (Test-QuickAdoptionShard -Name 'RepositoryRoutes') {
    $launcher = Get-Content -LiteralPath $launcherPath -Raw
    foreach ($requiredRepeatRouteText in @(
        'Get-ExistingAdoptionRoute',
        'AlreadyCurrent',
        'CompatibleUpdate',
        'Dispatching installed updater',
        'The installed updater seed was preserved'
    )) {
        if (-not $launcher.Contains($requiredRepeatRouteText)) {
            Add-Failure "TEST-0113 launcher lacks repeat-adoption route '$requiredRepeatRouteText'."
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Quick-adoption tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

if ($Shard -ceq 'All') {
    Write-Host 'Quick-adoption tests passed for all declared scenarios in this suite.' -ForegroundColor Green
    $scenarioResult = New-MeAndAIScenarioResult `
        -Owner 'tests/quick-adoption.tests.ps1' -SourcePaths @($PSCommandPath) `
        -AuthorityPath $scenarioAuthorityPath
    Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
}
else {
    Write-Host "Quick-adoption Windows compatibility shard '$Shard' passed." `
        -ForegroundColor Green
    $compatibilityResult = [ordered]@{
        schema = 1
        suite = 'tests/quick-adoption.tests.ps1'
        shard = $Shard
        passed = $true
    }
    Write-Host ('MEANDAI_COMPATIBILITY_SHARD_RESULT=' +
        ($compatibilityResult | ConvertTo-Json -Compress))
}
