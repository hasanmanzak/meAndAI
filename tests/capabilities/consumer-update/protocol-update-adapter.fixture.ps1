[CmdletBinding()]
param(
    [switch]$NativeStderrOnly
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$adapterSource = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$moduleSource = Join-Path $root 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
$workflowSource = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$consumerMigrationModuleSource = Join-Path $root 'scripts/MeAndAI.ConsumerMigrations.psm1'
$consumerMigrationIndexSource = Join-Path $root 'migrations/index.json'
Import-Module $consumerMigrationModuleSource -Force
$consumerMigrationCatalog = Import-MeAndAIConsumerMigrationCatalog `
    -IndexPath $consumerMigrationIndexSource
$consumerMigrationBaseline = New-MeAndAIConsumerMigrationBaseline `
    -Catalog $consumerMigrationCatalog
$adapterContent = Get-Content -LiteralPath $adapterSource -Raw
$failures = [System.Collections.Generic.List[string]]::new()
$script:Scenario = $null

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Get-AdapterFunctionDefinition {
    param([Parameter(Mandatory)][string]$Name)

    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        $adapterSource, [ref]$tokens, [ref]$parseErrors
    )
    if (@($parseErrors).Count -ne 0) {
        throw "Cannot load focused adapter function '$Name' because the adapter does not parse."
    }
    $matches = @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            [string]$node.Name -ceq $Name
    }, $true))
    if ($matches.Count -ne 1) {
        throw "Expected one adapter function '$Name', found $($matches.Count)."
    }
    return [string]$matches[0].Extent.Text
}

# Load only the exact production helpers under test. Dot-sourcing the complete
# updater would execute its GitHub lifecycle, while copying their logic here
# would let the test drift away from production.
. ([scriptblock]::Create((Get-AdapterFunctionDefinition `
    -Name 'Assert-ContainedMigrationDestination')))
. ([scriptblock]::Create((Get-AdapterFunctionDefinition `
    -Name 'Apply-ConsumerMigrationPlan')))
Import-Module $moduleSource -Force
foreach ($helperName in @(
    'Invoke-Native',
    'Test-GitAncestor',
    'Get-LocalTreeEntry',
    'Get-StagedTreeEntry',
    'Get-OrdinalUniquePaths',
    'Get-ExpectedManagedPaths',
    'Assert-StagedManagedUpdate',
    'Stage-ManagedProposalTree',
    'Get-RemoteBranchHead',
    'Assert-RemoteDefaultBranchUnchanged',
    'Get-ExistingReplacementCandidates'
)) {
    . ([scriptblock]::Create((Get-AdapterFunctionDefinition -Name $helperName)))
}

$catalogImportDefinition = Get-AdapterFunctionDefinition `
    -Name 'Import-ConsumerMigrationCatalogAtCommit'
if (-not $catalogImportDefinition.Contains(
        "'checkout', '--quiet', '--detach', `$Commit")) {
    Add-Failure 'TEST-0126 target migration-catalog checkout is not quiet and detached.'
}
$remoteBranchDefinition = Get-AdapterFunctionDefinition `
    -Name 'Get-RemoteBranchHead'
if (-not $remoteBranchDefinition.Contains(
        '-AcceptedExitCodes @(0, 2) -PassThruResult')) {
    Add-Failure 'TEST-0126 missing remote-ref exit code 2 is not captured by the native wrapper.'
}
if ([regex]::IsMatch($adapterContent, '(?m)^\s*&\s+git\b')) {
    Add-Failure 'TEST-0126 target adapter bypasses the native exit-code wrapper.'
}

$nativeStderrRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-native-stderr-$([guid]::NewGuid().ToString('N'))"
try {
    $nativeStderrRepository = Join-Path $nativeStderrRoot 'consumer'
    [IO.Directory]::CreateDirectory($nativeStderrRepository) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'init', '--quiet', '--initial-branch=main'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'config', 'user.name', 'TEST-0126'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'config', 'user.email',
        'test-0126@example.invalid'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'config', 'commit.gpgsign', 'false'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'config', 'core.autocrlf', 'false'
    ) | Out-Null

    $nativeStderrFixture = Join-Path $nativeStderrRepository 'fixture.txt'
    [IO.File]::WriteAllText($nativeStderrFixture, "first`n",
        [Text.UTF8Encoding]::new($false))
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'add', '--', 'fixture.txt'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'commit', '--quiet', '-m', 'first'
    ) | Out-Null
    $firstCommit = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'rev-parse', 'HEAD'
    )) -join '').Trim()

    [IO.File]::WriteAllText($nativeStderrFixture, "second`n",
        [Text.UTF8Encoding]::new($false))
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'add', '--', 'fixture.txt'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'commit', '--quiet', '-m', 'second'
    ) | Out-Null
    $secondCommit = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'rev-parse', 'HEAD'
    )) -join '').Trim()

    $expectedPreference = [string]$ErrorActionPreference
    $checkoutOutput = @()
    try {
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $nativeStderrRepository, 'checkout', '--detach', $firstCommit
        ) | Out-Null
        $checkoutOutput = @(Invoke-Native -Command 'git' -Arguments @(
            '-C', $nativeStderrRepository, 'checkout', '--detach', $secondCommit
        ))
    }
    catch {
        Add-Failure "TEST-0126 successful native stderr was treated as failure: $($_.Exception.Message)"
    }
    if ($checkoutOutput.Count -eq 0) {
        Add-Failure 'TEST-0126 did not exercise the successful Git checkout stderr path.'
    }
    $checkedOutCommit = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'rev-parse', 'HEAD'
    )) -join '').Trim()
    if ($checkedOutCommit -cne $secondCommit) {
        Add-Failure 'TEST-0126 successful native stderr did not preserve the requested checkout result.'
    }
    if ([string]$ErrorActionPreference -cne $expectedPreference) {
        Add-Failure 'TEST-0126 native invocation did not restore ErrorActionPreference.'
    }

    if (-not (Test-GitAncestor -RepositoryPath $nativeStderrRepository `
            -Ancestor $firstCommit -Descendant $secondCommit)) {
        Add-Failure 'TEST-0126 rejected a valid Git ancestor relation.'
    }
    if (Test-GitAncestor -RepositoryPath $nativeStderrRepository `
            -Ancestor $secondCommit -Descendant $firstCommit) {
        Add-Failure 'TEST-0126 accepted exit code 1 as a valid Git ancestor relation.'
    }
    $invalidAncestorFailed = $false
    try {
        Test-GitAncestor -RepositoryPath $nativeStderrRepository `
            -Ancestor 'test-0126-missing' -Descendant $secondCommit | Out-Null
    }
    catch {
        $invalidAncestorFailed = $true
    }
    if (-not $invalidAncestorFailed) {
        Add-Failure 'TEST-0126 accepted an unexpected Git ancestor error.'
    }

    $nativeStderrRemote = Join-Path $nativeStderrRoot 'origin.git'
    Invoke-Native -Command 'git' -Arguments @(
        'clone', '--quiet', '--bare', $nativeStderrRepository,
        $nativeStderrRemote
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $nativeStderrRepository, 'remote', 'add', 'origin',
        $nativeStderrRemote
    ) | Out-Null
    Push-Location $nativeStderrRepository
    try {
        $actualRemoteHead = Get-RemoteBranchHead -Branch 'main'
        if ($actualRemoteHead -cne $secondCommit) {
            Add-Failure 'TEST-0126 did not return the exact remote branch head.'
        }
        $missingRemoteHead = Get-RemoteBranchHead `
            -Branch 'test-0126-missing'
        if ($null -ne $missingRemoteHead) {
            Add-Failure 'TEST-0126 did not preserve missing remote ref exit code 2.'
        }
        Invoke-Native -Command 'git' -Arguments @(
            'remote', 'set-url', 'origin',
            (Join-Path $nativeStderrRoot 'missing-origin.git')
        ) | Out-Null
        $invalidRemoteFailed = $false
        try {
            Get-RemoteBranchHead -Branch 'main' | Out-Null
        }
        catch {
            $invalidRemoteFailed = $true
        }
        if (-not $invalidRemoteFailed) {
            Add-Failure 'TEST-0126 accepted an unexpected remote inspection error.'
        }
    }
    finally {
        Pop-Location
    }

    $nativeHost = (Get-Process -Id $PID).Path
    $exitTwoResult = Invoke-Native -Command $nativeHost -Arguments @(
        '-NoProfile', '-Command', 'exit 2'
    ) -AcceptedExitCodes @(0, 2) -PassThruResult
    if ([int]$exitTwoResult.ExitCode -ne 2) {
        Add-Failure 'TEST-0126 did not preserve an accepted native exit code 2.'
    }

    $invalidCheckoutFailed = $false
    try {
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $nativeStderrRepository, 'checkout', '--detach',
            'refs/heads/test-0126-missing'
        ) | Out-Null
    }
    catch {
        $invalidCheckoutFailed = $true
    }
    if (-not $invalidCheckoutFailed) {
        Add-Failure 'TEST-0126 accepted a native command with a nonzero exit code.'
    }
}
catch {
    Add-Failure "TEST-0126 native stderr fixture failed unexpectedly: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $nativeStderrRoot) {
        Remove-Item -LiteralPath $nativeStderrRoot -Recurse -Force
    }
}

if ($NativeStderrOnly) {
    if ($failures.Count -gt 0) {
        foreach ($failure in $failures) {
            Write-Host "FAIL: $failure" -ForegroundColor Red
        }
        exit 1
    }
    Write-Host 'Protocol update native stderr regression passed.' -ForegroundColor Green
    exit 0
}

$script:FocusedRemoteDefaultHead = '0' * 40
$script:FocusedRepositoryMetadata = [pscustomobject]@{
    full_name = 'owner/consumer'
    default_branch = 'main'
}
function Invoke-GhJson {
    param([string[]]$Arguments)

    if (($Arguments -join ' ') -cne 'api repos/owner/consumer') {
        throw "Unexpected focused repository-metadata lookup: $($Arguments -join ' ')"
    }
    return $script:FocusedRepositoryMetadata
}
function Get-RemoteBranchHead {
    param([string]$Branch)

    if ($Branch -cne 'main') {
        throw "Unexpected focused default-branch ref lookup '$Branch'."
    }
    return $script:FocusedRemoteDefaultHead
}

$defaultRenameError = ''
$script:FocusedRepositoryMetadata = [pscustomobject]@{
    full_name = 'owner/consumer'
    default_branch = 'trunk'
}
try {
    Assert-RemoteDefaultBranchUnchanged -Repository 'owner/consumer' `
        -DefaultBranch 'main' -ExpectedHeadSha $script:FocusedRemoteDefaultHead
}
catch {
    $defaultRenameError = $_.Exception.Message
}
if ($defaultRenameError -notlike '*live default branch*') {
    Add-Failure "TEST-0126 a live default-branch rename with the old ref SHA intact did not fail closed: $defaultRenameError"
}

$repositoryIdentityError = ''
$script:FocusedRepositoryMetadata = [pscustomobject]@{
    full_name = 'owner/redirected-consumer'
    default_branch = 'main'
}
try {
    Assert-RemoteDefaultBranchUnchanged -Repository 'owner/consumer' `
        -DefaultBranch 'main' -ExpectedHeadSha $script:FocusedRemoteDefaultHead
}
catch {
    $repositoryIdentityError = $_.Exception.Message
}
if ($repositoryIdentityError -notlike '*live repository identity*') {
    Add-Failure "TEST-0126 a redirected live repository identity did not fail closed: $repositoryIdentityError"
}
$script:FocusedRepositoryMetadata = [pscustomobject]@{
    full_name = 'owner/consumer'
    default_branch = 'main'
}
try {
    Assert-RemoteDefaultBranchUnchanged -Repository 'owner/consumer' `
        -DefaultBranch 'main' -ExpectedHeadSha $script:FocusedRemoteDefaultHead
}
catch {
    Add-Failure "TEST-0126 unchanged live repository/default identity was rejected: $($_.Exception.Message)"
}

$legacyInterruptedCandidate = [pscustomobject]@{
    PullRequestNumber = 21; TargetTag = 'v0.10.4'; Kind = 'Update'
    HeadRef = 'automation/meandai-protocol-v0.10.4'
    MarkerSchema = 1; SupersedeOnly = $true; MigrationPlanSha = ''
}
$recoveryInterruptedCandidate = [pscustomobject]@{
    PullRequestNumber = 30; TargetTag = 'v0.10.4'; Kind = 'Update'
    HeadRef = 'automation/meandai-protocol-v0.10.4-recovery'
    MarkerSchema = 2; SupersedeOnly = $false; MigrationPlanSha = '4' * 64
}
$interruptedReplacement = @(Get-ExistingReplacementCandidates `
    -Candidates @($legacyInterruptedCandidate, $recoveryInterruptedCandidate) `
    -TargetTag 'v0.10.4' -ProposalKind Update `
    -CurrentLauncherMode $true)
if ($interruptedReplacement.Count -ne 1 -or
    [int]$interruptedReplacement[0].PullRequestNumber -ne 30) {
    Add-Failure 'TEST-0126 interrupted recovery rerun did not select only the verified schema-2 recovery replacement.'
}

$destinationGuardRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-migration-leaf-guard-$([guid]::NewGuid().ToString('N'))"
try {
    $consumerRoot = Join-Path $destinationGuardRoot 'consumer'
    $outsideRoot = Join-Path $destinationGuardRoot 'outside'
    [IO.Directory]::CreateDirectory($consumerRoot) | Out-Null
    [IO.Directory]::CreateDirectory($outsideRoot) | Out-Null

    $safePath = Join-Path $consumerRoot 'safe.txt'
    $safeBefore = [Text.UTF8Encoding]::new($false).GetBytes('safe-before')
    [IO.File]::WriteAllBytes($safePath, $safeBefore)
    $outsideSentinelPath = Join-Path $outsideRoot 'sentinel.txt'
    $outsideBefore = [Text.UTF8Encoding]::new($false).GetBytes('outside-before')
    [IO.File]::WriteAllBytes($outsideSentinelPath, $outsideBefore)

    $linkedLeaf = Join-Path $consumerRoot 'linked.txt'
    $linkedLeafType = if ([Environment]::OSVersion.Platform -eq
        [PlatformID]::Win32NT) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkedLeafType -Path $linkedLeaf `
        -Target $outsideRoot | Out-Null
    $linkedItem = Get-Item -LiteralPath $linkedLeaf -Force
    if (-not ($linkedItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Add-Failure 'TEST-0120 leaf-guard fixture is not a reparse point.'
    }

    $guardPlan = [pscustomobject]@{
        Paths = @(
            [pscustomobject]@{
                Path = 'safe.txt'; Changed = $true
                OriginalBytes = [byte[]]$safeBefore.Clone()
                ResultBytes = [Text.UTF8Encoding]::new($false).GetBytes('safe-after')
            },
            [pscustomobject]@{
                Path = 'linked.txt'; Changed = $true
                OriginalBytes = [byte[]]::new(0)
                ResultBytes = [Text.UTF8Encoding]::new($false).GetBytes('outside-write')
            }
        )
        Ledger = [pscustomobject]@{
            Path = '.ai/meandai-update-state.json'; Changed = $false
            OriginalBlob = ''; OriginalBytes = $null
            ResultBytes = [byte[]]::new(0)
        }
    }
    $guardError = ''
    try {
        Apply-ConsumerMigrationPlan -Plan $guardPlan -Workspace $consumerRoot
    }
    catch {
        $guardError = $_.Exception.Message
    }
    if ($guardError -notlike '*linked or non-file destination*') {
        Add-Failure "TEST-0120 linked migration leaf did not fail during destination preflight: $guardError"
    }
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($safePath)) -cne
        [Convert]::ToBase64String($safeBefore)) {
        Add-Failure 'TEST-0120 linked-leaf rejection did not preserve the preceding migration file.'
    }
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($outsideSentinelPath)) -cne
        [Convert]::ToBase64String($outsideBefore)) {
        Add-Failure 'TEST-0120 linked-leaf rejection wrote outside the consumer root.'
    }
}
catch {
    Add-Failure "TEST-0120 linked-leaf fixture failed: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $destinationGuardRoot) {
        Remove-Item -LiteralPath $destinationGuardRoot -Recurse -Force
    }
}

function Set-AtomicGateFixtureFile {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Content
    )

    $path = Join-Path $Root ($RelativePath -replace '/', `
        [IO.Path]::DirectorySeparatorChar)
    $parent = Split-Path -Parent $path
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function Copy-AtomicGateFixtureFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $path = Join-Path $Root ($RelativePath -replace '/', `
        [IO.Path]::DirectorySeparatorChar)
    $parent = Split-Path -Parent $path
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    [IO.File]::WriteAllBytes($path, [IO.File]::ReadAllBytes($Source))
}

# TEST-0133-LEGACY-CONSUMER-SURFACE-BEGIN
function Invoke-FrozenLegacyConsumerValidator {
    param([Parameter(Mandatory)][string]$ValidatorPath)

    $powerShellPath = $null
    foreach ($hostName in @('pwsh', 'pwsh.exe', 'powershell', 'powershell.exe')) {
        $candidatePath = Join-Path $PSHOME $hostName
        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            $powerShellPath = $candidatePath
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($powerShellPath)) {
        throw "No PowerShell host executable was found under PSHOME '$PSHOME'."
    }
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powerShellPath
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ValidatorPath`""
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw 'The frozen legacy-consumer validator child process did not start.'
        }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode = [int]$process.ExitCode
            Text = (($stdout.Result, $stderr.Result) -join "`n").Trim()
        }
    }
    finally {
        $process.Dispose()
    }
}

$atomicGateRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-legacy-consumer-atomic-gate-$([guid]::NewGuid().ToString('N'))"
try {
    $legacyConsumerValidatorFixture = Join-Path $root `
        'tests/capabilities/consumer-update/fixtures/legacy-pre-engine-consumer/Verify-MeAndAIAdoption.ps1'
    $fixtureText = Get-Content -Raw -LiteralPath $legacyConsumerValidatorFixture
    foreach ($requiredSyntheticLink in @(
        'https://example.invalid/legacy-consumer/issues/2',
        'https://example.invalid/legacy-consumer/pull/1'
    )) {
        if (-not $fixtureText.Contains($requiredSyntheticLink)) {
            throw "TEST-0133 frozen fixture lacks reserved synthetic link '$requiredSyntheticLink'."
        }
    }
    if ([regex]::Matches($fixtureText, 'https://github\.com/(?!hasanmanzak/meAndAI\.git)').Count -ne 0) {
        throw 'TEST-0133 frozen fixture contains a live consumer GitHub URL.'
    }
    $fixtureBlob = ((Invoke-Native -Command 'git' -Arguments @(
        'hash-object', '--', $legacyConsumerValidatorFixture
    )) -join '').Trim()
    if ($fixtureBlob -cne '1dffab9c6b6d6f22aedb83c313b95d7b0f275183') {
        throw "Frozen legacy-consumer validator blob differs: $fixtureBlob"
    }

    $sourceRoot = Join-Path $atomicGateRoot 'protocol'
    $consumerRoot = Join-Path $atomicGateRoot 'consumer'
    [IO.Directory]::CreateDirectory($sourceRoot) | Out-Null
    [IO.Directory]::CreateDirectory($consumerRoot) | Out-Null
    foreach ($repositoryPath in @($sourceRoot, $consumerRoot)) {
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $repositoryPath, 'init', '--initial-branch=main'
        ) | Out-Null
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $repositoryPath, 'config', 'user.name', 'TEST-0125'
        ) | Out-Null
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $repositoryPath, 'config', 'user.email',
            'test-0125@example.invalid'
        ) | Out-Null
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $repositoryPath, 'config', 'commit.gpgsign', 'false'
        ) | Out-Null
        Invoke-Native -Command 'git' -Arguments @(
            '-C', $repositoryPath, 'config', 'tag.gpgsign', 'false'
        ) | Out-Null
        Set-AtomicGateFixtureFile -Root $repositoryPath `
            -RelativePath '.gitattributes' -Content "* text=auto eol=lf`n"
    }

    $managedAssets = @(
        [pscustomobject]@{
            TemplatePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
            ConsumerPath = '.github/workflows/meandai-protocol-update.yml'
        },
        [pscustomobject]@{
            TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
            ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
        },
        [pscustomobject]@{
            TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
            ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        }
    )
    foreach ($asset in $managedAssets) {
        $source = switch ([string]$asset.ConsumerPath) {
            '.github/workflows/meandai-protocol-update.yml' { $workflowSource }
            '.github/scripts/MeAndAI.ProtocolUpdate.psm1' { $moduleSource }
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1' { $adapterSource }
        }
        Copy-AtomicGateFixtureFile -Source $source -Root $sourceRoot `
            -RelativePath ([string]$asset.TemplatePath)
        Set-AtomicGateFixtureFile -Root $consumerRoot `
            -RelativePath ([string]$asset.ConsumerPath) `
            -Content "legacy $([string]$asset.ConsumerPath)`n"
    }
    foreach ($sourceRecord in @(
        [pscustomobject]@{ Source = $consumerMigrationModuleSource; Path = 'scripts/MeAndAI.ConsumerMigrations.psm1' },
        [pscustomobject]@{ Source = $consumerMigrationIndexSource; Path = 'migrations/index.json' },
        [pscustomobject]@{ Source = (Join-Path $root 'migrations/MIG-0001.json'); Path = 'migrations/MIG-0001.json' }
    )) {
        Copy-AtomicGateFixtureFile -Source ([string]$sourceRecord.Source) `
            -Root $sourceRoot -RelativePath ([string]$sourceRecord.Path)
    }
    foreach ($sourceText in @(
        [pscustomobject]@{ Path = 'VERSION'; Content = "0.10.4`n" },
        [pscustomobject]@{ Path = 'PROTOCOL.md'; Content = "# Protocol`n" },
        [pscustomobject]@{ Path = 'templates/idea.md'; Content = "# Idea`n" },
        [pscustomobject]@{ Path = 'templates/feature/README.md'; Content = "# Feature`n" },
        [pscustomobject]@{ Path = 'templates/decision.md'; Content = "# Decision`n" }
    )) {
        Set-AtomicGateFixtureFile -Root $sourceRoot `
            -RelativePath ([string]$sourceText.Path) `
            -Content ([string]$sourceText.Content)
    }
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourceRoot, 'add', '--all'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourceRoot, 'commit', '--quiet', '-m', 'Target protocol fixture'
    ) | Out-Null
    $targetProtocolSha = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourceRoot, 'rev-parse', 'HEAD'
    )) -join '').Trim()

    $fixtureContentByPath = @{}
    foreach ($migration in @($consumerMigrationCatalog.Migrations)) {
        foreach ($operation in @($migration.Operations)) {
            $fixtureContentByPath[[string]$operation.Path] = `
                ([string]$operation.Before) + "`n"
        }
    }
    $fixtureContentByPath['AGENTS.md'] += @(
        '',
        '- Product purpose: Not yet established.',
        '- Runtime and stack: Not yet established.',
        '- Architecture: Not yet established.',
        '- Product build command: Not yet established.',
        '- Product test command: Not yet established.'
    ) -join "`n"
    $fixtureContentByPath['.ai/memory/project.md'] += @(
        '',
        '- Purpose: Not yet established.',
        '- Runtime and stack: Not yet established.',
        '- Build command: Not yet established.',
        '- Product test command: Not yet established.'
    ) -join "`n"
    foreach ($record in $fixtureContentByPath.GetEnumerator()) {
        if ([string]$record.Key -ceq 'tests/Verify-MeAndAIAdoption.ps1') {
            continue
        }
        Set-AtomicGateFixtureFile -Root $consumerRoot `
            -RelativePath ([string]$record.Key) -Content ([string]$record.Value)
    }
    Copy-AtomicGateFixtureFile -Source $legacyConsumerValidatorFixture `
        -Root $consumerRoot -RelativePath 'tests/Verify-MeAndAIAdoption.ps1'
    foreach ($consumerText in @(
        [pscustomobject]@{
            Path = '.gitmodules'
            Content = "[submodule `"meandai`"]`n`tpath = .ai/protocol`n`turl = https://github.com/hasanmanzak/meAndAI.git`n"
        },
        [pscustomobject]@{
            Path = '.ai/memory/log/2026-07-17-meandai-adoption.md'
            Content = "# Adoption log`n"
        },
        [pscustomobject]@{
            Path = 'docs/features/FEAT-0001-meandai-capabilities-adoption/README.md'
            Content = "# Adoption`n`nhttps://example.invalid/legacy-consumer/issues/2`nhttps://example.invalid/legacy-consumer/pull/1`n"
        },
        [pscustomobject]@{
            Path = 'docs/features/FEAT-0001-meandai-capabilities-adoption/test-cases.md'
            Content = "# Test cases`n"
        }
    )) {
        Set-AtomicGateFixtureFile -Root $consumerRoot `
            -RelativePath ([string]$consumerText.Path) `
            -Content ([string]$consumerText.Content)
    }

    $legacyProtocolSha = 'b56ea19adeb8b34848fdd5b1e70eaaed831bf81d'
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'add', '--all'
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'update-index', '--add', '--cacheinfo',
        "160000,$legacyProtocolSha,.ai/protocol"
    ) | Out-Null
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'commit', '--quiet', '-m',
        'Legacy pre-engine consumer fixture'
    ) | Out-Null
    $baseCommit = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'rev-parse', 'HEAD'
    )) -join '').Trim()
    $protocolCheckout = Join-Path $consumerRoot '.ai/protocol'
    Invoke-Native -Command 'git' -Arguments @(
        'clone', '--quiet', $sourceRoot, $protocolCheckout
    ) | Out-Null

    $validatorPath = Join-Path $consumerRoot 'tests/Verify-MeAndAIAdoption.ps1'
    $baselineValidation = Invoke-FrozenLegacyConsumerValidator `
        -ValidatorPath $validatorPath
    if ($baselineValidation.ExitCode -ne 0) {
        throw "Baseline legacy-consumer validator is not green: $($baselineValidation.Text)"
    }

    $targetCatalog = Import-MeAndAIConsumerMigrationCatalog `
        -IndexPath (Join-Path $sourceRoot 'migrations/index.json')
    $migrationInputs = [System.Collections.Generic.List[object]]::new()
    foreach ($path in @(Get-MeAndAIConsumerMigrationRequiredPaths `
        -Catalog $targetCatalog)) {
        $inputPath = Join-Path $consumerRoot ($path -replace '/', `
            [IO.Path]::DirectorySeparatorChar)
        $migrationInputs.Add([pscustomobject]@{
            Path = $path
            Bytes = [IO.File]::ReadAllBytes($inputPath)
        })
    }
    $migrationPlan = Resolve-MeAndAIConsumerMigrationPlan `
        -Catalog $targetCatalog -Files @($migrationInputs)

    Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'update-index', '--add', '--cacheinfo',
        "160000,$targetProtocolSha,.ai/protocol"
    ) | Out-Null
    $coreOnlyValidation = Invoke-FrozenLegacyConsumerValidator `
        -ValidatorPath $validatorPath
    $coreOnlyCompact = $coreOnlyValidation.Text.Replace("`r", '').Replace("`n", '')
    $coreOnlyMarkers = @([regex]::Matches(
        $coreOnlyCompact, 'TEST-[0-9]{4}'
    ) | ForEach-Object { [string]$_.Value } | Select-Object -Unique)
    if ($coreOnlyValidation.ExitCode -eq 0 -or
        $coreOnlyMarkers.Count -ne 1 -or
        [string]$coreOnlyMarkers[0] -cne 'TEST-0001') {
        throw "Core-only proposal did not fail only TEST-0001: $($coreOnlyValidation.Text)"
    }

    Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'reset', '--hard', $baseCommit
    ) | Out-Null
    Push-Location -LiteralPath $consumerRoot
    try {
        $stagedPaths = @(Stage-ManagedProposalTree -Workspace $consumerRoot `
            -BaseCommit $baseCommit -TargetProtocolSha $targetProtocolSha `
            -SourcePath $sourceRoot -ProtocolPath '.ai/protocol' `
            -Assets $managedAssets -MigrationPlan $migrationPlan `
            -ProposalKind 'Update')
    }
    finally {
        Pop-Location
    }
    $expectedPaths = @(
        '.ai/meandai-update-state.json',
        '.ai/memory/README.md',
        '.ai/memory/project.md',
        '.ai/protocol',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/workflows/meandai-protocol-update.yml',
        'AGENTS.md',
        'docs/decisions/DEC-0001-pinned-meandai-submodule.md',
        'docs/decisions/README.md',
        'docs/features/README.md',
        'docs/ideas/README.md',
        'tests/Verify-MeAndAIAdoption.ps1'
    )
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $stagedPaths -Expected $expectedPaths)) {
        throw "Production staging returned a non-atomic path set: $($stagedPaths -join ', ')"
    }
    $indexPaths = @(Invoke-Native -Command 'git' -Arguments @(
        '-C', $consumerRoot, 'diff', '--cached', '--name-only'
    ))
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $indexPaths -Expected $expectedPaths)) {
        throw "Atomic proposal index differs from the exact 13 paths: $($indexPaths -join ', ')"
    }
    $atomicValidation = Invoke-FrozenLegacyConsumerValidator `
        -ValidatorPath $validatorPath
    if ($atomicValidation.ExitCode -ne 0) {
        throw "Atomic proposal does not satisfy the frozen legacy-consumer validator: $($atomicValidation.Text)"
    }

    $appliedLedgerBytes = [IO.File]::ReadAllBytes(
        (Join-Path $consumerRoot '.ai/meandai-update-state.json')
    )
    $rerunPlan = Resolve-MeAndAIConsumerMigrationPlan `
        -Catalog $targetCatalog -Files @() -LedgerBytes $appliedLedgerBytes
    if ([string]$rerunPlan.State -cne 'Satisfied' -or
        [bool]$rerunPlan.LedgerWasMissing -or
        @($rerunPlan.ExpectedChangedPaths).Count -ne 0 -or
        @($rerunPlan.Migrations).Count -ne 0 -or
        @($rerunPlan.Paths).Count -ne 0 -or
        [bool]$rerunPlan.Ledger.Changed -or
        [string]$rerunPlan.Ledger.OriginalBlob -cne
            [string]$rerunPlan.Ledger.ResultBlob) {
        throw 'Atomic legacy-consumer migration rerun was not an exact no-op.'
    }
}
catch {
    Add-Failure "TEST-0125/TEST-0133 project-neutral atomic gate fixture failed: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $atomicGateRoot) {
        Remove-Item -LiteralPath $atomicGateRoot -Recurse -Force
    }
}
# TEST-0133-LEGACY-CONSUMER-SURFACE-END

$adapterTestText = [IO.File]::ReadAllText($PSCommandPath)
$surfaceStartMarker = '# TEST-0133-' + 'LEGACY-CONSUMER-SURFACE-BEGIN'
$surfaceEndMarker = '# TEST-0133-' + 'LEGACY-CONSUMER-SURFACE-END'
$surfaceStart = $adapterTestText.IndexOf(
    $surfaceStartMarker, [StringComparison]::Ordinal
)
$surfaceEnd = $adapterTestText.IndexOf(
    $surfaceEndMarker, [StringComparison]::Ordinal
)
if ($surfaceStart -lt 0 -or $surfaceEnd -le $surfaceStart -or
    $adapterTestText.IndexOf(
        $surfaceStartMarker, $surfaceStart + $surfaceStartMarker.Length,
        [StringComparison]::Ordinal
    ) -ge 0 -or
    $adapterTestText.IndexOf(
        $surfaceEndMarker, $surfaceEnd + $surfaceEndMarker.Length,
        [StringComparison]::Ordinal
    ) -ge 0) {
    Add-Failure 'TEST-0133 project-neutral adapter surface markers are missing or ambiguous.'
}
else {
    $adapterSurfaceText = $adapterTestText.Substring(
        $surfaceStart, $surfaceEnd - $surfaceStart
    )
    foreach ($requiredNeutralToken in @(
        'function Invoke-FrozenLegacyConsumerValidator',
        '$legacyConsumerValidatorFixture = Join-Path',
        'tests/capabilities/consumer-update/fixtures/legacy-pre-engine-consumer/Verify-MeAndAIAdoption.ps1',
        'meandai-legacy-consumer-atomic-gate-',
        'Legacy pre-engine consumer fixture',
        'Baseline legacy-consumer validator',
        'frozen legacy-consumer validator'
    )) {
        if (-not $adapterSurfaceText.Contains($requiredNeutralToken)) {
            Add-Failure "TEST-0133 adapter surface lacks neutral token '$requiredNeutralToken'."
        }
    }
    $nonCanonicalGitHubText = $adapterSurfaceText.Replace(
        'https://github.com/hasanmanzak/meAndAI.git', ''
    )
    if ($nonCanonicalGitHubText.Contains('https://github.com/')) {
        Add-Failure 'TEST-0133 adapter surface contains a live consumer GitHub URL.'
    }
}

function Add-ScenarioEvent {
    param([string]$Event)
    $script:Scenario.Events.Add($Event)
}

function ConvertTo-TestBase64Json {
    param($InputObject)
    $json = $InputObject | ConvertTo-Json -Depth 8 -Compress
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
}

function ConvertTo-TestPullJson {
    param(
        [int]$Number,
        [string]$Branch,
        [string]$HeadSha,
        [string]$Body,
        [string]$AuthorLogin = 'updater-owner',
        [bool]$Draft = $true,
        [ValidateSet('open', 'closed')]
        [string]$State = 'open'
    )

    [pscustomobject]@{
        number = $Number
        state = $State
        draft = $Draft
        body = $Body
        user = [pscustomobject]@{ login = $AuthorLogin }
        head = [pscustomobject]@{
            ref = $Branch
            sha = $HeadSha
            repo = [pscustomobject]@{ full_name = 'owner/consumer' }
        }
        base = [pscustomobject]@{ ref = 'main' }
    } | ConvertTo-Json -Depth 6 -Compress
}

function New-TestProtocolUpdateIssue {
    param(
        [int]$Number,
        [string]$TargetTag,
        [string]$ProtocolSha,
        [string]$Branch,
        [int]$PullRequestNumber,
        [string]$HeadSha,
        [string]$State = 'open'
    )
    $markerJson = [ordered]@{
        schema = 1; target = $TargetTag; protocolSha = $ProtocolSha
        repository = 'owner/consumer'
    } | ConvertTo-Json -Compress
    $body = @(
        "<!-- meandai-protocol-update-issue:$markerJson -->",
        '## Managed protocol update tracking', '',
        "- Target release: ``$TargetTag``",
        "- Protocol commit: ``$ProtocolSha``",
        "- Deterministic branch: ``$Branch``", '',
        'This issue is the canonical same-repository work record for the managed protocol proposal.',
        'The workflow creates or reuses it, the maintainer reviews and merges the draft, and post-merge finalization closes it only after exact branch convergence.'
    ) -join [Environment]::NewLine
    [pscustomobject]@{
        number = $Number; title = "Track meAndAI protocol update to $TargetTag"
        body = $body; state = $State
        labels = @(
            [pscustomobject]@{ name = 'type:task' },
            [pscustomobject]@{ name = 'priority:p1' },
            [pscustomobject]@{ name = 'status:needs-review' }
        )
        comments = [System.Collections.Generic.List[object]]@(
            [pscustomobject]@{ body = "<!-- meandai-protocol-update-proposal:pr-$PullRequestNumber`:head-$HeadSha -->`nManaged protocol proposal: #$PullRequestNumber" }
        )
    }
}

function global:git {

    $script:Scenario = $global:MeAndAITestScenario
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0

    if ($arguments[0] -eq 'config' -and $arguments -contains '.gitmodules') {
        if ($arguments -contains '--get-regexp') {
            $path = if ($script:Scenario.WrongCaseSubmodulePath) {
                '.AI/protocol'
            } else { '.ai/protocol' }
            "submodule.meandai.path`t$path"
            return
        }
        if ($arguments -contains '--get') {
            if ($script:Scenario.InvalidSubmoduleUrl) {
                'https://github.com/attacker/other-protocol.git'
            }
            else { 'https://github.com/hasanmanzak/meAndAI.git' }
            return
        }
    }
    if ($arguments[0] -eq '-C' -and $arguments[2] -eq 'ls-tree') {
        $commit = [string]$arguments[3]
        $path = [string]$arguments[-1]
        $key = "$commit|$path"
        if ($script:Scenario.SourceTreeEntries.ContainsKey($key)) {
            "100644 blob $($script:Scenario.SourceTreeEntries[$key])`t$path"
        }
        return
    }
    if ($arguments[0] -eq 'ls-tree') {
        $commit = [string]$arguments[1]
        $path = [string]$arguments[-1]
        $committedProposal = $commit -ceq $script:Scenario.NewHead
        if ($path -eq '.ai/protocol') {
            $protocolSha = if ($committedProposal) {
                $script:Scenario.TargetProtocolSha
            }
            else { $script:Scenario.CurrentProtocolSha }
            "160000 commit $protocolSha`t.ai/protocol"
        }
        elseif ($committedProposal -and
            $script:Scenario.TargetConsumerBlobs.ContainsKey($path)) {
            $blob = [string]$script:Scenario.TargetConsumerBlobs[$path]
            if ($script:Scenario.WrongCommittedAssetBlob -and
                $path -ceq '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1') {
                $blob = '8' * 40
            }
            if ($script:Scenario.WrongCommittedMigrationBlob -and
                $path -ceq 'AGENTS.md') {
                $blob = '9' * 40
            }
            "100644 blob $blob`t$path"
        }
        elseif ($script:Scenario.ConsumerTreeEntries.ContainsKey($path)) {
            "100644 blob $($script:Scenario.ConsumerTreeEntries[$path])`t$path"
        }
        return
    }
    if ($arguments[0] -eq '-C' -and $arguments[2] -eq 'tag') {
        @('v0.1.0', 'v0.2.0', 'v0.3.0')
        return
    }
    if ($arguments[0] -eq '-C' -and $arguments[2] -eq 'rev-list') {
        switch ($arguments[-1]) {
            'v0.1.0' { $script:Scenario.FirstProtocolSha }
            'v0.2.0' {
                if ($script:Scenario.AliasCurrentTag) { $script:Scenario.CurrentProtocolSha }
                else { $script:Scenario.MiddleProtocolSha }
            }
            'v0.3.0' { $script:Scenario.LocalTargetProtocolSha }
            default { throw "Unexpected tag lookup '$($arguments[-1])'." }
        }
        return
    }
    if ($arguments[0] -eq '-C' -and $arguments[2] -eq 'merge-base') {
        Add-ScenarioEvent 'verify-lineage'
        return
    }
    if ($arguments[0] -eq '-C' -and $arguments[2] -eq 'checkout') {
        if ($script:Scenario.Events -contains 'verify-immutable-release') {
            Add-ScenarioEvent 'checkout-target-assets'
        }
        else {
            Add-ScenarioEvent 'checkout-migration-catalog'
        }
        return
    }
    if ($arguments[0] -eq 'ls-remote') {
        if ([string]$arguments[-1] -ceq 'refs/heads/automation/meandai-protocol-*') {
            $script:Scenario.ReservedInventoryCalls++
            Add-ScenarioEvent "inventory-reserved-$($script:Scenario.ReservedInventoryCalls)"
            if ($script:Scenario.OldBranchExists) {
                "$($script:Scenario.OldHead)`trefs/heads/$($script:Scenario.OldBranch)"
            }
            if ($script:Scenario.NewBranchExists) {
                "$($script:Scenario.NewHead)`trefs/heads/$($script:Scenario.NewBranch)"
            }
            if ($script:Scenario.ReservedOrphanBranchExists -or
                ($script:Scenario.ReservedNamespaceRace -and
                 $script:Scenario.ReservedInventoryCalls -gt 1)) {
                "$($script:Scenario.ReservedOrphanHead)`trefs/heads/$($script:Scenario.ReservedOrphanBranch)"
            }
            return
        }
        $branch = ([string]$arguments[-1]).Substring('refs/heads/'.Length)
        Add-ScenarioEvent "probe-$branch"
        if ($branch -eq $script:Scenario.OldBranch) {
            $script:Scenario.OldProbeCalls++
            if ($script:Scenario.RemoveOldBeforeDelete -and $script:Scenario.OldProbeCalls -gt 2) {
                $script:Scenario.OldBranchExists = $false
                Add-ScenarioEvent 'remove-old-before-delete'
            }
            if ($script:Scenario.OldBranchExists) {
                "$($script:Scenario.OldHead)`trefs/heads/$branch"
                return
            }
        }
        if ($branch -eq $script:Scenario.NewBranch -and $script:Scenario.NewBranchExists) {
            "$($script:Scenario.NewHead)`trefs/heads/$branch"
            return
        }
        $global:LASTEXITCODE = 2
        return
    }
    if ($arguments[0] -eq 'diff') {
        if ($arguments -contains '--cached') {
            @($script:Scenario.ExpectedStagedPaths)
            return
        }
        if ($arguments -contains '--name-only' -and
            $arguments -contains '--no-renames') {
            Add-ScenarioEvent 'validate-committed-tree'
            @($script:Scenario.ExpectedStagedPaths)
            if ($script:Scenario.CommitExtraApplicationPath) {
                'src/injected-product-file.txt'
            }
            return
        }
    }
    if ($arguments[0] -eq 'ls-files' -and $arguments -contains '--stage') {
        $path = [string]$arguments[-1]
        if ($path -eq '.ai/protocol') {
            "160000 $($script:Scenario.TargetProtocolSha) 0`t$path"
        }
        elseif ($script:Scenario.TargetConsumerBlobs.ContainsKey($path)) {
            $stagedBlob = if ($script:Scenario.WrongStagedAssetBlob -and
                $path -eq '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1') {
                '0' * 40
            }
            else { $script:Scenario.TargetConsumerBlobs[$path] }
            "100644 $stagedBlob 0`t$path"
        }
        return
    }
    if ($arguments[0] -eq 'add') {
        Add-ScenarioEvent 'stage-target-assets'
        return
    }
    if ($arguments[0] -eq 'rev-list' -and $arguments -contains '--parents') {
        Add-ScenarioEvent 'validate-committed-parent'
        $parent = if ($script:Scenario.WrongCommittedParent) {
            '7' * 40
        }
        else { $script:Scenario.BaseHead }
        "$($script:Scenario.NewHead) $parent"
        return
    }
    if ($arguments[0] -eq 'rev-parse') {
        $script:Scenario.RevParseCalls++
        if ($script:Scenario.RevParseCalls -eq 1) {
            $script:Scenario.BaseHead
        }
        else {
            $script:Scenario.NewHead
        }
        return
    }
    if ($arguments[0] -eq 'push') {
        if ($arguments -contains '--set-upstream') {
            $newRef = "refs/heads/$($script:Scenario.NewBranch)"
            $newLease = "--force-with-lease=${newRef}:"
            if ($arguments -cnotcontains $newLease -or
                [string]$arguments[-1] -cne "$($script:Scenario.NewBranch):$newRef") {
                throw "New branch push omitted its exact expected-absent lease: $($arguments -join ' ')"
            }
            if ($script:Scenario.ConcurrentNewBranch) {
                $script:Scenario.NewBranchExists = $true
                Add-ScenarioEvent 'reject-new-branch-lease'
                $global:LASTEXITCODE = 1
                'stale info: remote branch appeared'
                return
            }
            $script:Scenario.NewBranchExists = $true
            Add-ScenarioEvent 'push-new'
        }
        elseif ([string]$arguments[-1] -ceq ":refs/heads/$($script:Scenario.OldBranch)") {
            $oldRef = "refs/heads/$($script:Scenario.OldBranch)"
            $oldLease = "--force-with-lease=${oldRef}:$($script:Scenario.ExpectedOldHead)"
            if ($arguments -cnotcontains $oldLease) {
                throw "Old branch deletion omitted its exact expected-head lease: $($arguments -join ' ')"
            }
            if ($script:Scenario.ChangeOldBeforeDelete) {
                $script:Scenario.OldHead = 'e' * 40
                Add-ScenarioEvent 'reject-old-branch-lease'
                $global:LASTEXITCODE = 1
                'stale info: old branch changed'
                return
            }
            $script:Scenario.OldBranchExists = $false
            Add-ScenarioEvent 'delete-old-branch'
        }
        elseif ([string]$arguments[-1] -ceq ":refs/heads/$($script:Scenario.NewBranch)") {
            $newRef = "refs/heads/$($script:Scenario.NewBranch)"
            $newLease = "--force-with-lease=${newRef}:$($script:Scenario.NewHead)"
            if ($arguments -cnotcontains $newLease) {
                throw "New branch deletion omitted its exact expected-head lease: $($arguments -join ' ')"
            }
            $script:Scenario.NewBranchExists = $false
            Add-ScenarioEvent 'delete-new-branch'
        }
        else {
            throw "Unexpected fake push command: $($arguments -join ' ')"
        }
        return
    }
    if ($arguments[0] -eq 'commit') {
        Add-ScenarioEvent 'commit-proposal'
        return
    }
    if ($arguments[0] -in @('switch', 'update-index', 'config')) {
        return
    }

    throw "Unexpected fake git command: $($arguments -join ' ')"
}

function global:gh {

    $script:Scenario = $global:MeAndAITestScenario
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0
    $isPaginated = $arguments -contains '--paginate'
    $script:Scenario.GhCalls.Add([pscustomobject]@{
        Arguments = @($arguments)
        Token = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')
    })

    if ($arguments[0] -eq 'pr' -and $arguments[1] -eq 'create') {
        if ($env:GH_TOKEN -cne 'updater-write-token') {
            throw 'Consumer pull-request creation used the wrong credential.'
        }
        $bodyIndex = [array]::IndexOf($arguments, '--body')
        $script:Scenario.NewBody = $arguments[$bodyIndex + 1]
        Add-ScenarioEvent 'create-new-pr'
        'https://github.com/owner/consumer/pull/30'
        return
    }
    if ($arguments[0] -ne 'api') {
        throw "Unexpected fake gh command: $($arguments -join ' ')"
    }

    if ($arguments.Count -eq 2 -and $arguments[1] -eq 'user') {
        Add-ScenarioEvent 'resolve-updater-actor'
        if ($script:Scenario.InvalidAuthenticatedActor) {
            '{}'
        }
        else {
            [pscustomobject]@{ login = $script:Scenario.AuthenticatedActor } |
                ConvertTo-Json -Compress
        }
        return
    }

    $endpoint = @($arguments | Where-Object { $_ -like 'repos/*' })[0]
    $method = 'GET'
    $methodIndex = [array]::IndexOf($arguments, '--method')
    if ($methodIndex -ge 0) {
        $method = $arguments[$methodIndex + 1]
    }

    if ($method -eq 'POST' -and $endpoint -like '*/issues/21/comments') {
        $bodyArgument = @($arguments | Where-Object { $_ -like 'body=*' })[0]
        $script:Scenario.OldPullRequestComment = $bodyArgument.Substring('body='.Length)
        Add-ScenarioEvent 'comment-old-pr'
        '{}'
        return
    }
    if ($method -eq 'PATCH' -and $endpoint -like '*/pulls/21') {
        if ($arguments -contains 'state=open') {
            Add-ScenarioEvent 'reopen-old-pr'
            if (-not $script:Scenario.ReopenOldNoOp) {
                $script:Scenario.OldPullRequestState = 'open'
            }
        }
        else {
            Add-ScenarioEvent 'close-old-pr'
            if (-not $script:Scenario.CloseOldNoOp) {
                $script:Scenario.OldPullRequestState = 'closed'
            }
        }
        '{}'
        return
    }
    if ($method -eq 'PATCH' -and $endpoint -like '*/pulls/30') {
        if ($arguments -contains 'state=open') {
            Add-ScenarioEvent 'reopen-new-pr'
        }
        else {
            Add-ScenarioEvent 'close-new-pr'
        }
        '{}'
        return
    }
    $isIssueAuthorityEndpoint = $endpoint -eq 'repos/owner/consumer/labels' -or
        $endpoint -eq 'repos/owner/consumer/labels?per_page=100' -or
        $endpoint -eq 'repos/owner/consumer/issues' -or
        $endpoint -eq 'repos/owner/consumer/issues?state=all&per_page=100' -or
        $endpoint -match '^repos/owner/consumer/issues/[0-9]+(?:/.*)?$'
    if ($isIssueAuthorityEndpoint) {
        if ($env:GH_TOKEN -cne 'issue-write-token') {
            throw 'Consumer issue lifecycle used the wrong credential.'
        }
        if ($endpoint -eq 'repos/owner/consumer/labels?per_page=100') {
            foreach ($name in $script:Scenario.RepositoryLabels) {
                ConvertTo-TestBase64Json ([pscustomobject]@{ name = $name })
            }
            return
        }
        if ($endpoint -eq 'repos/owner/consumer/labels' -and $method -eq 'POST') {
            $nameArgument = @($arguments | Where-Object { $_ -like 'name=*' })[0]
            $name = $nameArgument.Substring('name='.Length)
            if ($script:Scenario.RepositoryLabels -notcontains $name) {
                $script:Scenario.RepositoryLabels.Add($name)
            }
            Add-ScenarioEvent "create-label-$name"
            [pscustomobject]@{ name = $name } | ConvertTo-Json -Compress
            return
        }
        if ($endpoint -eq 'repos/owner/consumer/issues?state=all&per_page=100') {
            foreach ($issue in $script:Scenario.Issues) {
                ConvertTo-TestBase64Json $issue
            }
            return
        }
        if ($endpoint -eq 'repos/owner/consumer/issues' -and $method -eq 'POST') {
            $title = (@($arguments | Where-Object { $_ -like 'title=*' })[0]).Substring('title='.Length)
            $body = (@($arguments | Where-Object { $_ -like 'body=*' })[0]).Substring('body='.Length)
            $issue = [pscustomobject]@{
                number = 130; title = $title; body = $body; state = 'open'
                labels = @(
                    [pscustomobject]@{ name = 'type:task' },
                    [pscustomobject]@{ name = 'priority:p1' },
                    [pscustomobject]@{ name = 'status:needs-review' }
                )
                comments = [System.Collections.Generic.List[object]]::new()
            }
            $script:Scenario.Issues.Add($issue)
            Add-ScenarioEvent 'create-update-issue'
            $issue | ConvertTo-Json -Depth 6 -Compress
            return
        }
        if ($endpoint -match '^repos/owner/consumer/issues/(?<number>[0-9]+)$') {
            $number = [int]$Matches.number
            $issue = @($script:Scenario.Issues | Where-Object { [int]$_.number -eq $number })
            if ($issue.Count -ne 1) { throw "Mock issue #$number is not exact." }
            $issue = $issue[0]
            if ($method -eq 'PATCH') {
                if ($arguments -contains 'state=closed') {
                    $issue.state = 'closed'
                    Add-ScenarioEvent "close-update-issue-$number"
                }
                elseif ($arguments -contains 'state=open') {
                    $issue.state = 'open'
                    Add-ScenarioEvent "reopen-update-issue-$number"
                }
            }
            $issue | ConvertTo-Json -Depth 6 -Compress
            return
        }
        if ($endpoint -match '^repos/owner/consumer/issues/(?<number>[0-9]+)/labels$' -and
            $method -eq 'POST') {
            $number = [int]$Matches.number
            $issue = @($script:Scenario.Issues | Where-Object { [int]$_.number -eq $number })[0]
            foreach ($argument in @($arguments | Where-Object {
                ([string]$_).StartsWith('labels[]=', [StringComparison]::Ordinal)
            })) {
                $name = $argument.Substring('labels[]='.Length)
                if (@($issue.labels | Where-Object { [string]$_.name -ceq $name }).Count -eq 0) {
                    $issue.labels += [pscustomobject]@{ name = $name }
                }
            }
            '{}'
            return
        }
        if ($endpoint -match '^repos/owner/consumer/issues/(?<number>[0-9]+)/labels/.+$' -and
            $method -eq 'DELETE') {
            $number = [int]$Matches.number
            $issue = @($script:Scenario.Issues | Where-Object { [int]$_.number -eq $number })[0]
            $encoded = $endpoint.Substring($endpoint.LastIndexOf('/') + 1)
            $label = [Uri]::UnescapeDataString($encoded)
            $issue.labels = @($issue.labels | Where-Object { [string]$_.name -cne $label })
            Add-ScenarioEvent "remove-issue-label-$number-$label"
            return
        }
        if ($endpoint -match '^repos/owner/consumer/issues/(?<number>[0-9]+)/comments\?per_page=100$') {
            $number = [int]$Matches.number
            $issue = @($script:Scenario.Issues | Where-Object { [int]$_.number -eq $number })[0]
            foreach ($comment in $issue.comments) { ConvertTo-TestBase64Json $comment }
            return
        }
        if ($endpoint -match '^repos/owner/consumer/issues/(?<number>[0-9]+)/comments$' -and
            $method -eq 'POST') {
            $number = [int]$Matches.number
            $issue = @($script:Scenario.Issues | Where-Object { [int]$_.number -eq $number })[0]
            $bodyArgument = @($arguments | Where-Object { $_ -like 'body=*' })[0]
            $issue.comments.Add([pscustomobject]@{ body = $bodyArgument.Substring('body='.Length) })
            Add-ScenarioEvent "comment-update-issue-$number"
            '{}'
            return
        }
        throw "Unexpected fake issue-authority call: $($arguments -join ' ')"
    }
    $protocolEndpoint = $endpoint -like 'repos/hasanmanzak/meAndAI/*'
    if ($protocolEndpoint -and $env:GH_TOKEN -cne 'protocol-read-token') {
        throw 'Protocol source metadata used the consumer mutation credential.'
    }
    if (-not $protocolEndpoint -and $env:GH_TOKEN -cne 'updater-write-token') {
        throw 'Consumer repository metadata used the protocol source credential.'
    }
    if ($endpoint -eq 'repos/hasanmanzak/meAndAI/releases/tags/v0.3.0') {
        Add-ScenarioEvent 'verify-immutable-release'
        if ($arguments -cnotcontains 'X-GitHub-Api-Version: 2026-03-10') {
            throw 'Immutable release lookup omitted the required GitHub API version.'
        }
        if ($script:Scenario.ReleaseMode -ceq 'Missing') {
            $global:LASTEXITCODE = 1
            'HTTP 404: release not found'
            return
        }
        $release = [ordered]@{
            tag_name = if ($script:Scenario.ReleaseMode -ceq 'WrongTag') { 'v0.2.0' } else { 'v0.3.0' }
            draft = $script:Scenario.ReleaseMode -ceq 'Draft'
            prerelease = $script:Scenario.ReleaseMode -ceq 'Prerelease'
            immutable = $script:Scenario.ReleaseMode -cne 'Mutable'
            published_at = if ($script:Scenario.ReleaseMode -ceq 'Unpublished') { $null } else { '2026-07-15T00:00:00Z' }
        }
        $release | ConvertTo-Json -Compress
        return
    }
    if ($endpoint -eq 'repos/hasanmanzak/meAndAI/git/ref/tags/v0.3.0') {
        Add-ScenarioEvent 'verify-release-tag-ref'
        $objectType = if ($script:Scenario.ReleaseTagMode -cin @('Annotated', 'Nested')) {
            'tag'
        }
        else { 'commit' }
        $objectSha = if ($objectType -ceq 'tag') {
            '4' * 40
        }
        else { $script:Scenario.ReleaseCommitSha }
        [ordered]@{
            object = [ordered]@{ type = $objectType; sha = $objectSha }
        } | ConvertTo-Json -Depth 3 -Compress
        return
    }
    if ($endpoint -eq "repos/hasanmanzak/meAndAI/git/tags/$('4' * 40)") {
        Add-ScenarioEvent 'verify-annotated-release-tag'
        $resolvedType = if ($script:Scenario.ReleaseTagMode -ceq 'Nested') {
            'tag'
        }
        else { 'commit' }
        [ordered]@{
            object = [ordered]@{
                type = $resolvedType
                sha = $script:Scenario.ReleaseCommitSha
            }
        } | ConvertTo-Json -Depth 3 -Compress
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls?state=open&per_page=100') {
        $visibleUnmanaged = if ($isPaginated) {
            $script:Scenario.LeadingUnmanagedCount
        } else { [Math]::Min($script:Scenario.LeadingUnmanagedCount, 100) }
        for ($index = 0; $index -lt $visibleUnmanaged; $index++) {
            ConvertTo-TestBase64Json ([pscustomobject]@{
                number = 1000 + $index; body = ''
                head = [pscustomobject]@{ ref = "feature/unmanaged-$index" }
            })
        }
        if ($isPaginated -or $script:Scenario.LeadingUnmanagedCount -lt 100) {
            if ($script:Scenario.OldCandidateExists) {
                ConvertTo-TestBase64Json ([pscustomobject]@{
                    number = 21; body = $script:Scenario.OldBody
                    head = [pscustomobject]@{ ref = $script:Scenario.OldBranch }
                })
            }
            if ($script:Scenario.ExistingReplacement) {
                ConvertTo-TestBase64Json ([pscustomobject]@{
                    number = 30; body = $script:Scenario.NewBody
                    head = [pscustomobject]@{ ref = $script:Scenario.NewBranch }
                })
            }
        }
        return
    }
    if ($endpoint -like 'repos/owner/consumer/pulls?state=*&head=owner:*') {
        if ($script:Scenario.NewBranchExists -and $script:Scenario.NewBody) {
            ConvertTo-TestBase64Json ([pscustomobject]@{ number = 30 })
        }
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls/21') {
        $script:Scenario.OldDetailCalls++
        Add-ScenarioEvent "read-old-pr-$($script:Scenario.OldDetailCalls)"
        $head = if ($script:Scenario.MutateOldAfterSnapshot -and
            $script:Scenario.OldDetailCalls -gt 1) { 'd' * 40 } else { $script:Scenario.OldHead }
        ConvertTo-TestPullJson -Number 21 -Branch $script:Scenario.OldBranch `
            -HeadSha $head -Body $script:Scenario.OldBody `
            -AuthorLogin $script:Scenario.OldAuthorLogin `
            -State $script:Scenario.OldPullRequestState
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls/21/files?per_page=100') {
        ConvertTo-TestBase64Json ([pscustomobject]@{
            filename = '.ai/protocol'; status = 'modified'
        })
        return
    }
    if ($endpoint -like 'repos/owner/consumer/git/commits/*') {
        $rootTreeSha = if ($endpoint -like "*$($script:Scenario.NewHead)") {
            if ($script:Scenario.NewRootTreeSha) {
                [string]$script:Scenario.NewRootTreeSha
            }
            else { 'c' * 40 }
        }
        else { 'd' * 40 }
        [pscustomobject]@{ tree = [pscustomobject]@{ sha = $rootTreeSha } } |
            ConvertTo-Json -Depth 3 -Compress
        return
    }
    if ($endpoint -match '^repos/owner/consumer/git/trees/(?<sha>[0-9a-f]{40})$' -and
        $script:Scenario.RemoteTrees.ContainsKey([string]$Matches.sha)) {
        [pscustomobject]@{
            tree = @($script:Scenario.RemoteTrees[[string]$Matches.sha])
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('c' * 40)") {
        [pscustomobject]@{
            tree = @(
                [pscustomobject]@{ path = '.ai'; mode = '040000'; type = 'tree'; sha = 'e' * 40 },
                [pscustomobject]@{ path = '.github'; mode = '040000'; type = 'tree'; sha = '6' * 40 }
            )
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('d' * 40)") {
        [pscustomobject]@{
            tree = @(
                [pscustomobject]@{ path = '.ai'; mode = '040000'; type = 'tree'; sha = 'f' * 40 },
                [pscustomobject]@{ path = '.github'; mode = '040000'; type = 'tree'; sha = '7' * 40 }
            )
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('e' * 40)" -or
        $endpoint -eq "repos/owner/consumer/git/trees/$('f' * 40)") {
        $protocolSha = if ($endpoint -like "*$('e' * 40)") {
            $script:Scenario.TargetProtocolSha
        } else { $script:Scenario.OldProtocolSha }
        [pscustomobject]@{
            tree = @([pscustomobject]@{
                path = 'protocol'; mode = '160000'; type = 'commit'; sha = $protocolSha
            })
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('6' * 40)" -or
        $endpoint -eq "repos/owner/consumer/git/trees/$('7' * 40)") {
        $isNew = $endpoint -like "*$('6' * 40)"
        [pscustomobject]@{
            tree = @(
                [pscustomobject]@{
                    path = 'workflows'; mode = '040000'; type = 'tree'
                    sha = if ($isNew) { '8' * 40 } else { '9' * 40 }
                },
                [pscustomobject]@{
                    path = 'scripts'; mode = '040000'; type = 'tree'
                    sha = if ($isNew) { 'a' * 40 } else { 'b' * 40 }
                }
            )
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('8' * 40)" -or
        $endpoint -eq "repos/owner/consumer/git/trees/$('9' * 40)") {
        $workflowBlob = if ($endpoint -like "*$('8' * 40)") {
            $script:Scenario.TargetWorkflowBlob
        }
        else { $script:Scenario.CurrentWorkflowBlob }
        [pscustomobject]@{
            tree = @([pscustomobject]@{
                path = 'meandai-protocol-update.yml'; mode = '100644'; type = 'blob'
                sha = $workflowBlob
            })
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('a' * 40)" -or
        $endpoint -eq "repos/owner/consumer/git/trees/$('b' * 40)") {
        $isNew = $endpoint -like "*$('a' * 40)"
        [pscustomobject]@{
            tree = @(
                [pscustomobject]@{
                    path = 'MeAndAI.ProtocolUpdate.psm1'; mode = '100644'; type = 'blob'
                    sha = $script:Scenario.CurrentModuleBlob
                },
                [pscustomobject]@{
                    path = 'Invoke-MeAndAIProtocolUpdate.ps1'; mode = '100644'; type = 'blob'
                    sha = if ($isNew) {
                        if ($script:Scenario.WrongTargetAssetBlob) { '0' * 40 }
                        else { $script:Scenario.TargetAdapterBlob }
                    }
                    else { $script:Scenario.CurrentAdapterBlob }
                }
            )
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls/30') {
        $script:Scenario.NewDetailCalls++
        Add-ScenarioEvent 'verify-new-pr'
        Add-ScenarioEvent "verify-new-pr-$($script:Scenario.NewDetailCalls)"
        $newDraft = $script:Scenario.NewDraft
        if ($script:Scenario.CoordinateNewHeadMutation -and
            $script:Scenario.NewDetailCalls -gt 1) {
            $script:Scenario.NewHead = '9' * 40
            $changedMarker = [ordered]@{
                schema = 1; target = 'v0.3.0'; protocolSha = '3' * 40
                head = $script:Scenario.NewHead; repository = 'owner/consumer'
            } | ConvertTo-Json -Compress
            $script:Scenario.NewBody = "<!-- meandai-protocol-update:$changedMarker -->"
        }
        if ($script:Scenario.MutateNewAfterSnapshot -and
            $script:Scenario.NewDetailCalls -gt 1) {
            $newDraft = $false
        }
        if ($script:Scenario.MutateReplacementAfterOldClose -and
            $script:Scenario.OldPullRequestState -ceq 'closed') {
            $newDraft = $false
        }
        ConvertTo-TestPullJson -Number 30 -Branch $script:Scenario.NewBranch `
            -HeadSha $script:Scenario.NewHead -Body $script:Scenario.NewBody `
            -AuthorLogin $script:Scenario.AuthenticatedActor -Draft $newDraft
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls/30/files?per_page=100') {
        $script:Scenario.NewFilesCalls++
        foreach ($path in $script:Scenario.ExpectedStagedPaths) {
            $renameRecord = (
                $script:Scenario.RenameMode -ceq 'InventoryRename' -and
                $script:Scenario.NewFilesCalls -eq 1 -and $path -ceq '.ai/protocol'
            ) -or (
                $script:Scenario.RenameMode -ceq 'RevalidationRename' -and
                $script:Scenario.NewFilesCalls -gt 1 -and $path -ceq '.ai/protocol'
            )
            if ($renameRecord) {
                ConvertTo-TestBase64Json ([pscustomobject]@{
                    filename = $path
                    status = 'renamed'
                    previous_filename = 'docs/unmanaged-source.ps1'
                })
            }
            else {
                ConvertTo-TestBase64Json ([pscustomobject]@{
                    filename = $path; status = 'modified'
                })
            }
        }
        return
    }

    throw "Unexpected fake gh API call: $($arguments -join ' ')"
}

function Invoke-AdapterScenario {
    param(
        [string]$Name,
        [bool]$NewDraft = $true,
        [bool]$MutateOldAfterSnapshot = $false,
        [bool]$ExistingReplacement = $false,
        [bool]$OldCandidateExists = $true,
        [bool]$MutateNewAfterSnapshot = $false,
        [bool]$MutateReplacementAfterOldClose = $false,
        [bool]$CoordinateNewHeadMutation = $false,
        [bool]$ConcurrentNewBranch = $false,
        [bool]$OldBranchExists = $true,
        [bool]$RemoveOldBeforeDelete = $false,
        [bool]$ChangeOldBeforeDelete = $false,
        [bool]$CloseOldNoOp = $false,
        [bool]$ReopenOldNoOp = $false,
        [bool]$AliasCurrentTag = $false,
        [bool]$DuplicateOldMarker = $false,
        [bool]$CaseVariantDuplicateMarker = $false,
        [bool]$NonCanonicalOldMarker = $false,
        [bool]$InvalidSubmoduleUrl = $false,
        [bool]$WrongCaseSubmodulePath = $false,
        [bool]$MissingUpdaterToken = $false,
        [bool]$MissingProtocolToken = $false,
        [bool]$InvalidAuthenticatedActor = $false,
        [string]$AuthenticatedActor = 'updater-owner',
        [string]$OldAuthorLogin = 'updater-owner',
        [bool]$DriftCurrentAsset = $false,
        [bool]$WrongStagedAssetBlob = $false,
        [bool]$CommitExtraApplicationPath = $false,
        [bool]$WrongCommittedParent = $false,
        [bool]$WrongCommittedAssetBlob = $false,
        [bool]$WrongCommittedMigrationBlob = $false,
        [bool]$WrongTargetAssetBlob = $false,
        [bool]$MissingManagedLabels = $false,
        [bool]$ReservedOrphanBranchExists = $false,
        [bool]$ReservedNamespaceRace = $false,
        [int]$LeadingUnmanagedCount = 0,
        [ValidateSet('Valid', 'Missing', 'Mutable', 'Draft', 'Prerelease', 'Unpublished', 'WrongTag')]
        [string]$ReleaseMode = 'Valid',
        [ValidateSet('Lightweight', 'Annotated', 'Nested')]
        [string]$ReleaseTagMode = 'Lightweight',
        [bool]$MismatchedReleaseCommit = $false,
        [bool]$MigrationRequired = $false,
        [bool]$MigrationWithUpgrade = $false,
        [ValidateSet('None', 'InventoryRename', 'RevalidationRename')]
        [string]$RenameMode = 'None'
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-adapter-$Name-$([guid]::NewGuid().ToString('N'))"
    $scriptsPath = Join-Path $tempRoot '.github/scripts'
    $workflowsPath = Join-Path $tempRoot '.github/workflows'
    $sourceGitPath = Join-Path $tempRoot '.meandai-update-source/.git'
    $sourceScriptsPath = Join-Path $tempRoot '.meandai-update-source/templates/project/.github/scripts'
    $sourceWorkflowsPath = Join-Path $tempRoot '.meandai-update-source/templates/project/.github/workflows'
    $sourceMigrationModulePath = Join-Path $tempRoot '.meandai-update-source/scripts'
    $sourceMigrationsPath = Join-Path $tempRoot '.meandai-update-source/migrations'
    $consumerStatePath = Join-Path $tempRoot '.ai'
    New-Item -ItemType Directory -Force $scriptsPath, $workflowsPath, $sourceGitPath, `
        $sourceScriptsPath, $sourceWorkflowsPath, $sourceMigrationModulePath, `
        $sourceMigrationsPath, $consumerStatePath | Out-Null
    Copy-Item -LiteralPath $moduleSource -Destination (Join-Path $scriptsPath 'MeAndAI.ProtocolUpdate.psm1')
    Copy-Item -LiteralPath $adapterSource -Destination (Join-Path $scriptsPath 'Invoke-MeAndAIProtocolUpdate.ps1')
    Copy-Item -LiteralPath $workflowSource -Destination (Join-Path $workflowsPath 'meandai-protocol-update.yml')
    Copy-Item -LiteralPath $moduleSource -Destination (Join-Path $sourceScriptsPath 'MeAndAI.ProtocolUpdate.psm1')
    Copy-Item -LiteralPath $adapterSource -Destination (Join-Path $sourceScriptsPath 'Invoke-MeAndAIProtocolUpdate.ps1')
    Copy-Item -LiteralPath $workflowSource -Destination (Join-Path $sourceWorkflowsPath 'meandai-protocol-update.yml')
    Copy-Item -LiteralPath $consumerMigrationModuleSource -Destination (
        Join-Path $sourceMigrationModulePath 'MeAndAI.ConsumerMigrations.psm1'
    )
    Copy-Item -LiteralPath $consumerMigrationIndexSource -Destination (
        Join-Path $sourceMigrationsPath 'index.json'
    )
    foreach ($migration in @($consumerMigrationCatalog.Migrations)) {
        Copy-Item -LiteralPath (Join-Path (Split-Path -Parent $consumerMigrationIndexSource) `
            ([string]$migration.Definition)) -Destination (
            Join-Path $sourceMigrationsPath ([string]$migration.Definition)
        )
    }
    $migrationPlan = $null
    if ($MigrationRequired) {
        $migrationFiles = [System.Collections.Generic.List[object]]::new()
        foreach ($migration in @($consumerMigrationCatalog.Migrations)) {
            foreach ($operation in @($migration.Operations)) {
                $bytes = [Text.UTF8Encoding]::new($false).GetBytes(
                    "fixture prefix`n$([string]$operation.Before)`nfixture suffix`n"
                )
                $relative = ([string]$operation.Path) -replace '/', `
                    [IO.Path]::DirectorySeparatorChar
                $destination = Join-Path $tempRoot $relative
                $parent = Split-Path -Parent $destination
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                [IO.File]::WriteAllBytes($destination, $bytes)
                $migrationFiles.Add([pscustomobject]@{
                    Path = [string]$operation.Path
                    Bytes = [byte[]]$bytes
                })
            }
        }
        $migrationPlan = Resolve-MeAndAIConsumerMigrationPlan `
            -Catalog $consumerMigrationCatalog -Files @($migrationFiles)
    }
    else {
        [IO.File]::WriteAllBytes(
            (Join-Path $consumerStatePath 'meandai-update-state.json'),
            [byte[]]$consumerMigrationBaseline.Bytes
        )
    }

    $oldHead = 'a' * 40
    $oldMarker = [ordered]@{
        schema = 1
        target = 'v0.2.0'
        protocolSha = '2' * 40
        head = $oldHead
        repository = 'owner/consumer'
    } | ConvertTo-Json -Compress
    $oldBody = "<!-- meandai-protocol-update:$oldMarker -->"
    if ($DuplicateOldMarker) {
        $oldBody += [Environment]::NewLine + "<!-- meandai-protocol-update:$oldMarker -->"
    }
    if ($CaseVariantDuplicateMarker) {
        $oldBody += [Environment]::NewLine + "<!-- MeAndAI-protocol-update:$oldMarker -->"
    }
    if ($NonCanonicalOldMarker) {
        $nonCanonicalMarker = [ordered]@{
            Schema = '1'
            target = 'v0.2.0'; protocolSha = '2' * 40; head = $oldHead
            repository = 'owner/consumer'; extra = $true
        } | ConvertTo-Json -Compress
        $oldBody = "<!-- meandai-protocol-update:$nonCanonicalMarker -->"
    }
    $oldBody += [Environment]::NewLine + [Environment]::NewLine + 'Tracking issue: #121'
    $newMarker = [ordered]@{
        schema = 1; target = 'v0.3.0'; protocolSha = '3' * 40
        head = 'b' * 40; repository = 'owner/consumer'
    } | ConvertTo-Json -Compress
    $initialNewBody = if ($ExistingReplacement) {
        "<!-- meandai-protocol-update:$newMarker -->`n`nTracking issue: #130"
    } else { '' }
    $currentWorkflowBlob = '1' * 40
    $currentModuleBlob = '2' * 40
    $currentAdapterBlob = '3' * 40
    $targetWorkflowBlob = '4' * 40
    $targetAdapterBlob = '5' * 40
    $consumerTreeEntries = @{
        '.github/workflows/meandai-protocol-update.yml' = if ($DriftCurrentAsset) { '0' * 40 } else { $currentWorkflowBlob }
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1' = $currentModuleBlob
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1' = $currentAdapterBlob
    }
    $targetConsumerBlobs = @{
        '.github/workflows/meandai-protocol-update.yml' = $targetWorkflowBlob
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1' = $currentModuleBlob
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1' = $targetAdapterBlob
    }
    if ($MigrationRequired) {
        if (-not $MigrationWithUpgrade) {
        $consumerTreeEntries['.github/workflows/meandai-protocol-update.yml'] = `
            $targetWorkflowBlob
        $consumerTreeEntries['.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'] = `
            $targetAdapterBlob
        }
        foreach ($pathResult in @($migrationPlan.Paths)) {
            $consumerTreeEntries[[string]$pathResult.Path] = `
                [string]$pathResult.OriginalBlob
            $targetConsumerBlobs[[string]$pathResult.Path] = `
                [string]$pathResult.ResultBlob
        }
        $targetConsumerBlobs[[string]$migrationPlan.Ledger.Path] = `
            [string]$migrationPlan.Ledger.ResultBlob
    }
    else {
        $consumerTreeEntries['.ai/meandai-update-state.json'] = `
            [string]$consumerMigrationBaseline.Blob
    }
    $sourceTreeEntries = @{}
    foreach ($sha in @(('1' * 40), ('2' * 40))) {
        $sourceTreeEntries["$sha|templates/project/.github/workflows/meandai-protocol-update.yml"] = $currentWorkflowBlob
        $sourceTreeEntries["$sha|templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1"] = $currentModuleBlob
        $sourceTreeEntries["$sha|templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1"] = $currentAdapterBlob
        $sourceTreeEntries["$sha|scripts/MeAndAI.ConsumerMigrations.psm1"] = '6' * 40
        $sourceTreeEntries["$sha|migrations/index.json"] = [string]$consumerMigrationCatalog.IndexBlob
        foreach ($migration in @($consumerMigrationCatalog.Migrations)) {
            $sourceTreeEntries["$sha|migrations/$([string]$migration.Definition)"] = `
                [string]$migration.DefinitionBlob
        }
    }
    $sourceTreeEntries["$('3' * 40)|templates/project/.github/workflows/meandai-protocol-update.yml"] = $targetWorkflowBlob
    $sourceTreeEntries["$('3' * 40)|templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1"] = $currentModuleBlob
    $sourceTreeEntries["$('3' * 40)|templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1"] = $targetAdapterBlob
    $sourceTreeEntries["$('3' * 40)|scripts/MeAndAI.ConsumerMigrations.psm1"] = '6' * 40
    $sourceTreeEntries["$('3' * 40)|migrations/index.json"] = [string]$consumerMigrationCatalog.IndexBlob
    foreach ($migration in @($consumerMigrationCatalog.Migrations)) {
        $sourceTreeEntries["$('3' * 40)|migrations/$([string]$migration.Definition)"] = `
            [string]$migration.DefinitionBlob
    }
    $sourceTreeEntries["$('6' * 40)|scripts/MeAndAI.ConsumerMigrations.psm1"] = '6' * 40
    $sourceTreeEntries["$('6' * 40)|migrations/index.json"] = [string]$consumerMigrationCatalog.IndexBlob
    foreach ($migration in @($consumerMigrationCatalog.Migrations)) {
        $sourceTreeEntries["$('6' * 40)|migrations/$([string]$migration.Definition)"] = `
            [string]$migration.DefinitionBlob
    }
    $newRootTreeSha = ''
    $remoteTrees = @{}
    if ($MigrationRequired) {
        $newRootTreeSha = 'c1' * 20
        $aiTreeSha = 'c2' * 20
        $memoryTreeSha = 'c3' * 20
        $docsTreeSha = 'c4' * 20
        $ideasTreeSha = 'c5' * 20
        $featuresTreeSha = 'c6' * 20
        $decisionsTreeSha = 'c7' * 20
        $testsTreeSha = 'c8' * 20
        $remoteTrees[$newRootTreeSha] = @(
            [pscustomobject]@{ path = '.ai'; mode = '040000'; type = 'tree'; sha = $aiTreeSha },
            [pscustomobject]@{ path = '.github'; mode = '040000'; type = 'tree'; sha = '6' * 40 },
            [pscustomobject]@{ path = 'AGENTS.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['AGENTS.md'] },
            [pscustomobject]@{ path = 'docs'; mode = '040000'; type = 'tree'; sha = $docsTreeSha },
            [pscustomobject]@{ path = 'tests'; mode = '040000'; type = 'tree'; sha = $testsTreeSha }
        )
        $remoteTrees[$aiTreeSha] = @(
            [pscustomobject]@{ path = 'protocol'; mode = '160000'; type = 'commit'; sha = '3' * 40 },
            [pscustomobject]@{ path = 'meandai-update-state.json'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['.ai/meandai-update-state.json'] },
            [pscustomobject]@{ path = 'memory'; mode = '040000'; type = 'tree'; sha = $memoryTreeSha }
        )
        $remoteTrees[$memoryTreeSha] = @(
            [pscustomobject]@{ path = 'README.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['.ai/memory/README.md'] },
            [pscustomobject]@{ path = 'project.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['.ai/memory/project.md'] }
        )
        $remoteTrees[$docsTreeSha] = @(
            [pscustomobject]@{ path = 'ideas'; mode = '040000'; type = 'tree'; sha = $ideasTreeSha },
            [pscustomobject]@{ path = 'features'; mode = '040000'; type = 'tree'; sha = $featuresTreeSha },
            [pscustomobject]@{ path = 'decisions'; mode = '040000'; type = 'tree'; sha = $decisionsTreeSha }
        )
        $remoteTrees[$ideasTreeSha] = @(
            [pscustomobject]@{ path = 'README.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['docs/ideas/README.md'] }
        )
        $remoteTrees[$featuresTreeSha] = @(
            [pscustomobject]@{ path = 'README.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['docs/features/README.md'] }
        )
        $remoteTrees[$decisionsTreeSha] = @(
            [pscustomobject]@{ path = 'README.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['docs/decisions/README.md'] },
            [pscustomobject]@{ path = 'DEC-0001-pinned-meandai-submodule.md'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['docs/decisions/DEC-0001-pinned-meandai-submodule.md'] }
        )
        $remoteTrees[$testsTreeSha] = @(
            [pscustomobject]@{ path = 'Verify-MeAndAIAdoption.ps1'; mode = '100644'; type = 'blob'; sha = $targetConsumerBlobs['tests/Verify-MeAndAIAdoption.ps1'] }
        )
    }
    $expectedStagedPaths = if ($MigrationRequired) {
        [string[]]$paths = @($migrationPlan.ExpectedChangedPaths)
        if ($MigrationWithUpgrade) {
            $paths = [string[]]@(
                $paths + @(
                    '.ai/protocol',
                    '.github/workflows/meandai-protocol-update.yml',
                    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
                )
            )
        }
        [Array]::Sort($paths, [StringComparer]::Ordinal)
        $paths
    }
    else {
        @(
            '.ai/protocol',
            '.github/workflows/meandai-protocol-update.yml',
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        )
    }
    $issues = [System.Collections.Generic.List[object]]::new()
    if ($OldCandidateExists) {
        $issues.Add((New-TestProtocolUpdateIssue -Number 121 -TargetTag 'v0.2.0' `
            -ProtocolSha ('2' * 40) -Branch 'automation/meandai-protocol-v0.2.0' `
            -PullRequestNumber 21 -HeadSha $oldHead))
    }
    if ($ExistingReplacement) {
        $issues.Add((New-TestProtocolUpdateIssue -Number 130 -TargetTag 'v0.3.0' `
            -ProtocolSha ('3' * 40) -Branch 'automation/meandai-protocol-v0.3.0' `
            -PullRequestNumber 30 -HeadSha ('b' * 40)))
    }
    $script:Scenario = [pscustomobject]@{
        Name = $Name
        Events = [System.Collections.Generic.List[string]]::new()
        GhCalls = [System.Collections.Generic.List[object]]::new()
        Issues = $issues
        RepositoryLabels = [System.Collections.Generic.List[string]]@($(if ($MissingManagedLabels) {
            @()
        } else {
            @('type:task', 'priority:p1', 'status:in-progress',
              'status:needs-review', 'status:blocked')
        }))
        FirstProtocolSha = '1' * 40
        CurrentProtocolSha = if ($MigrationRequired -and -not $MigrationWithUpgrade) {
            '3' * 40
        }
        else { '1' * 40 }
        MiddleProtocolSha = '2' * 40
        TargetProtocolSha = '3' * 40
        LocalTargetProtocolSha = if ($MismatchedReleaseCommit) { '6' * 40 } else { '3' * 40 }
        ReleaseCommitSha = '3' * 40
        OldProtocolSha = '2' * 40
        OldHead = $oldHead
        ExpectedOldHead = $oldHead
        NewHead = 'b' * 40
        BaseHead = '0' * 40
        RevParseCalls = 0
        CurrentWorkflowBlob = $currentWorkflowBlob
        CurrentModuleBlob = $currentModuleBlob
        CurrentAdapterBlob = $currentAdapterBlob
        TargetWorkflowBlob = $targetWorkflowBlob
        TargetAdapterBlob = $targetAdapterBlob
        ConsumerTreeEntries = $consumerTreeEntries
        TargetConsumerBlobs = $targetConsumerBlobs
        SourceTreeEntries = $sourceTreeEntries
        ExpectedStagedPaths = @($expectedStagedPaths)
        MigrationPlanSha = if ($MigrationRequired) {
            [string]$migrationPlan.PlanSha256
        }
        else { '' }
        NewRootTreeSha = $newRootTreeSha
        RemoteTrees = $remoteTrees
        OldBranchExists = $OldBranchExists
        NewBranchExists = $ExistingReplacement
        OldBranch = 'automation/meandai-protocol-v0.2.0'
        NewBranch = if ($MigrationRequired -and -not $MigrationWithUpgrade) {
            'automation/meandai-protocol-v0.3.0-migrations'
        }
        else { 'automation/meandai-protocol-v0.3.0' }
        ReservedOrphanBranch = 'automation/meandai-protocol-v0.2.5'
        ReservedOrphanHead = '7' * 40
        ReservedOrphanBranchExists = $ReservedOrphanBranchExists
        ReservedNamespaceRace = $ReservedNamespaceRace
        ReservedInventoryCalls = 0
        OldBody = $oldBody
        OldPullRequestComment = ''
        NewBody = $initialNewBody
        NewDraft = $NewDraft
        MutateOldAfterSnapshot = $MutateOldAfterSnapshot
        ConcurrentNewBranch = $ConcurrentNewBranch
        ChangeOldBeforeDelete = $ChangeOldBeforeDelete
        CloseOldNoOp = $CloseOldNoOp
        ReopenOldNoOp = $ReopenOldNoOp
        AliasCurrentTag = $AliasCurrentTag
        ExistingReplacement = $ExistingReplacement
        OldCandidateExists = $OldCandidateExists
        MutateNewAfterSnapshot = $MutateNewAfterSnapshot
        MutateReplacementAfterOldClose = $MutateReplacementAfterOldClose
        CoordinateNewHeadMutation = $CoordinateNewHeadMutation
        NewDetailCalls = 0
        InvalidSubmoduleUrl = $InvalidSubmoduleUrl
        WrongCaseSubmodulePath = $WrongCaseSubmodulePath
        InvalidAuthenticatedActor = $InvalidAuthenticatedActor
        AuthenticatedActor = $AuthenticatedActor
        OldAuthorLogin = $OldAuthorLogin
        WrongStagedAssetBlob = $WrongStagedAssetBlob
        CommitExtraApplicationPath = $CommitExtraApplicationPath
        WrongCommittedParent = $WrongCommittedParent
        WrongCommittedAssetBlob = $WrongCommittedAssetBlob
        WrongCommittedMigrationBlob = $WrongCommittedMigrationBlob
        WrongTargetAssetBlob = $WrongTargetAssetBlob
        LeadingUnmanagedCount = $LeadingUnmanagedCount
        ReleaseMode = $ReleaseMode
        ReleaseTagMode = $ReleaseTagMode
        RenameMode = $RenameMode
        NewFilesCalls = 0
        RemoveOldBeforeDelete = $RemoveOldBeforeDelete
        OldProbeCalls = 0

        OldDetailCalls = 0
        OldPullRequestState = 'open'
        Threw = $false
        Error = ''
    }
    $global:MeAndAITestScenario = $script:Scenario

    $savedEnvironment = @{}
    foreach ($nameKey in @(
        'GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN',
        'PROTOCOL_TOKEN', 'ISSUE_TOKEN', 'GITHUB_STEP_SUMMARY'
    )) {
        $savedEnvironment[$nameKey] = [Environment]::GetEnvironmentVariable($nameKey)
    }
    $savedLocation = Get-Location

    try {
        $env:GITHUB_REPOSITORY = 'owner/consumer'
        $env:GITHUB_WORKSPACE = $tempRoot
        $env:DEFAULT_BRANCH = 'main'
        $env:GH_TOKEN = if ($MissingUpdaterToken) { $null } else { 'updater-write-token' }
        $env:PROTOCOL_TOKEN = if ($MissingProtocolToken) { $null } else { 'protocol-read-token' }
        $env:ISSUE_TOKEN = 'issue-write-token'
        $env:GITHUB_STEP_SUMMARY = $null
        & (Join-Path $scriptsPath 'Invoke-MeAndAIProtocolUpdate.ps1')
    }
    catch {
        $script:Scenario.Threw = $true
        $script:Scenario.Error = $_.Exception.Message
    }
    finally {
        Set-Location -LiteralPath $savedLocation
        foreach ($entry in $savedEnvironment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value)
        }
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }

    return $script:Scenario
}

function Get-EventIndex {
    param($Scenario, [string]$Event)
    return $Scenario.Events.IndexOf($Event)
}

$success = Invoke-AdapterScenario -Name 'success'
if ($success.Threw) {
    Add-Failure "TEST-0011 replacement scenario failed: $($success.Error)"
}
$successOldIssue = @($success.Issues | Where-Object { [int]$_.number -eq 121 })
$successNewIssue = @($success.Issues | Where-Object { [int]$_.number -eq 130 })
if ($successOldIssue.Count -ne 1 -or [string]$successOldIssue[0].state -cne 'closed' -or
    $successNewIssue.Count -ne 1 -or [string]$successNewIssue[0].state -cne 'open' -or
    $success.NewBody -cnotmatch '(?m)^Tracking issue: #130$' -or
    $success.NewBody.Contains('Tracking issue: #REQUIRED') -or
    @($successNewIssue[0].comments | Where-Object {
        ([string]$_.body).StartsWith(
            "<!-- meandai-protocol-update-proposal:pr-30`:head-$('b' * 40) -->",
            [StringComparison]::Ordinal
        )
    }).Count -ne 1 -or
    (Get-EventIndex $success 'close-update-issue-121') -le
        (Get-EventIndex $success 'delete-old-branch')) {
    Add-Failure 'TEST-0111 automatic issue/link/supersession lifecycle did not converge in branch-first order.'
}
$engineEraMigration = Invoke-AdapterScenario -Name 'generic-update-with-migration' `
    -MigrationRequired $true -MigrationWithUpgrade $true `
    -OldCandidateExists $false -OldBranchExists $false
if ($engineEraMigration.Threw -or
    [string]$engineEraMigration.NewBranch -cne `
        'automation/meandai-protocol-v0.3.0' -or
    $engineEraMigration.ExpectedStagedPaths -cnotcontains '.ai/protocol' -or
    $engineEraMigration.ExpectedStagedPaths -cnotcontains `
        '.ai/meandai-update-state.json' -or
    $engineEraMigration.ExpectedStagedPaths -cnotcontains 'AGENTS.md' -or
    $engineEraMigration.NewBody -cnotmatch '"kind":"update"' -or
    (Get-EventIndex $engineEraMigration 'create-new-pr') -lt 0) {
    Add-Failure "TEST-0121 engine-era compatible update did not publish one exact protocol-plus-migration draft: $($engineEraMigration.Error)"
}
$legacyHandoff = Invoke-AdapterScenario -Name 'generic-legacy-handoff' `
    -MigrationRequired $true -OldCandidateExists $false -OldBranchExists $false
$handoffIssue = @($legacyHandoff.Issues | Where-Object { [int]$_.number -eq 130 })
if ($legacyHandoff.Threw -or
    [string]$legacyHandoff.NewBranch -cne `
        'automation/meandai-protocol-v0.3.0-migrations' -or
    $legacyHandoff.ExpectedStagedPaths -ccontains '.ai/protocol' -or
    $legacyHandoff.ExpectedStagedPaths -cnotcontains '.ai/meandai-update-state.json' -or
    $legacyHandoff.NewBody -cnotmatch '"kind":"migration-reconciliation"' -or
    -not $legacyHandoff.NewBody.Contains(
        '"migrationPlanSha":"' + [string]$legacyHandoff.MigrationPlanSha + '"'
    ) -or
    $handoffIssue.Count -ne 1 -or
    [string]$handoffIssue[0].title -cne `
        'Track meAndAI consumer reconciliation for v0.3.0' -or
    (Get-EventIndex $legacyHandoff 'create-new-pr') -lt 0) {
    Add-Failure "TEST-0122 generic missing-ledger handoff did not create one exact same-target reconciliation draft: $($legacyHandoff.Error)"
}
$missingLabels = Invoke-AdapterScenario -Name 'missing-managed-labels' `
    -MissingManagedLabels $true
if ($missingLabels.Threw -or @(
    'type:task', 'priority:p1', 'status:in-progress', 'status:needs-review', 'status:blocked' |
        Where-Object { $missingLabels.RepositoryLabels -cnotcontains $_ }
).Count -ne 0) {
    Add-Failure "TEST-0111 missing Agile labels were not created without blocking the managed proposal: $($missingLabels.Error)"
}
foreach ($event in @('checkout-target-assets', 'stage-target-assets')) {
    if ((Get-EventIndex $success $event) -lt 0 -or
        (Get-EventIndex $success $event) -gt (Get-EventIndex $success 'push-new')) {
        Add-Failure "TEST-0024 '$event' must occur before the replacement branch is pushed."
    }
}
if ((Get-EventIndex $success 'verify-immutable-release') -lt 0 -or
    (Get-EventIndex $success 'verify-immutable-release') -gt
        (Get-EventIndex $success 'checkout-target-assets')) {
    Add-Failure 'TEST-0056 the selected target release must be verified before target checkout.'
}
if ((Get-EventIndex $success 'verify-release-tag-ref') -lt 0) {
    Add-Failure 'TEST-0061 lightweight release commit evidence was not resolved.'
}
$protocolCalls = @($success.GhCalls | Where-Object {
    @($_.Arguments | Where-Object {
        [string]$_ -like 'repos/hasanmanzak/meAndAI/*'
    }).Count -gt 0
})
$issueCalls = @($success.GhCalls | Where-Object {
    @($_.Arguments | Where-Object {
        ([string]$_ -like 'repos/owner/consumer/issues*' -or
         [string]$_ -like 'repos/owner/consumer/labels*') -and
        [string]$_ -cne 'repos/owner/consumer/issues/21/comments'
    }).Count -gt 0
})
$consumerCalls = @($success.GhCalls | Where-Object {
    @($_.Arguments | Where-Object {
        [string]$_ -like 'repos/hasanmanzak/meAndAI/*'
    }).Count -eq 0 -and $_ -notin $issueCalls
})
if (@($protocolCalls | Where-Object { $_.Token -cne 'protocol-read-token' }).Count -ne 0 -or
    @($issueCalls | Where-Object { $_.Token -cne 'issue-write-token' }).Count -ne 0 -or
    @($consumerCalls | Where-Object { $_.Token -cne 'updater-write-token' }).Count -ne 0) {
    Add-Failure 'TEST-0061 protocol-read and consumer-write credentials crossed authority boundaries.'
}

$annotatedRelease = Invoke-AdapterScenario -Name 'annotated-release' `
    -ReleaseTagMode 'Annotated'
if ($annotatedRelease.Threw -or
    (Get-EventIndex $annotatedRelease 'verify-annotated-release-tag') -lt 0) {
    Add-Failure "TEST-0061 annotated release tag did not resolve to its exact commit: $($annotatedRelease.Error)"
}

$nestedRelease = Invoke-AdapterScenario -Name 'nested-release' `
    -ReleaseTagMode 'Nested'
if (-not $nestedRelease.Threw -or
    $nestedRelease.Error -notlike '*does not resolve directly to one commit*') {
    Add-Failure "TEST-0061 nested annotated release tag did not fail closed: $($nestedRelease.Error)"
}

$mismatchedRelease = Invoke-AdapterScenario -Name 'mismatched-release-commit' `
    -MismatchedReleaseCommit $true
if (-not $mismatchedRelease.Threw -or
    $mismatchedRelease.Error -notlike '*does not match the checked-out exact tag commit*') {
    Add-Failure "TEST-0061 moved release commit did not fail closed: $($mismatchedRelease.Error)"
}
foreach ($forbiddenEvent in @(
    'checkout-target-assets', 'push-new', 'create-new-pr',
    'close-old-pr', 'delete-old-branch'
)) {
    if ((Get-EventIndex $mismatchedRelease $forbiddenEvent) -ge 0) {
        Add-Failure "TEST-0061 mismatched release commit reached mutation '$forbiddenEvent'."
    }
}

$pendingLatest = Invoke-AdapterScenario -Name 'pending-latest' `
    -ExistingReplacement $true -OldCandidateExists $false -OldBranchExists $false
if ($pendingLatest.Threw -or
    (Get-EventIndex $pendingLatest 'verify-release-tag-ref') -lt 0 -or
    (Get-EventIndex $pendingLatest 'checkout-target-assets') -ge 0 -or
    (Get-EventIndex $pendingLatest 'create-update-issue') -ge 0 -or
    @($pendingLatest.Issues | Where-Object { [int]$_.number -eq 130 }).Count -ne 1) {
    Add-Failure "TEST-0061 zero-operation latest proposal skipped release proof or mutated state: $($pendingLatest.Error)"
}
foreach ($releaseMode in @('Missing', 'Mutable', 'Draft', 'Prerelease', 'Unpublished', 'WrongTag')) {
    $invalidRelease = Invoke-AdapterScenario -Name "release-$releaseMode" `
        -ReleaseMode $releaseMode
    $expectedReleaseError = if ($releaseMode -ceq 'Missing') {
        '*HTTP 404: release not found*'
    }
    else { '*published, non-prerelease, immutable GitHub Release*' }
    if (-not $invalidRelease.Threw -or
        $invalidRelease.Error -notlike $expectedReleaseError) {
        Add-Failure "TEST-0056 $releaseMode target release did not fail closed: $($invalidRelease.Error)"
    }
    foreach ($forbiddenEvent in @(
        'checkout-target-assets', 'push-new', 'create-new-pr',
        'close-old-pr', 'delete-old-branch'
    )) {
        if ((Get-EventIndex $invalidRelease $forbiddenEvent) -ge 0) {
            Add-Failure "TEST-0056 $releaseMode target release reached mutation '$forbiddenEvent'."
        }
    }
}

$missingUpdaterToken = Invoke-AdapterScenario -Name 'missing-updater-token' `
    -MissingUpdaterToken $true
if (-not $missingUpdaterToken.Threw -or
    $missingUpdaterToken.Error -notlike "*Required workflow environment 'GH_TOKEN' is missing*") {
    Add-Failure 'TEST-0022 missing updater token must fail before authentication or mutation.'
}
if ((Get-EventIndex $missingUpdaterToken 'resolve-updater-actor') -ge 0 -or
    (Get-EventIndex $missingUpdaterToken 'push-new') -ge 0 -or
    (Get-EventIndex $missingUpdaterToken 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0022 missing updater token reached authentication or mutation.'
}

$missingProtocolToken = Invoke-AdapterScenario -Name 'missing-protocol-token' `
    -MissingProtocolToken $true
if (-not $missingProtocolToken.Threw -or
    $missingProtocolToken.Error -notlike "*Required workflow environment 'PROTOCOL_TOKEN' is missing*") {
    Add-Failure 'TEST-0061 missing protocol token must fail before authentication or mutation.'
}
if ((Get-EventIndex $missingProtocolToken 'resolve-updater-actor') -ge 0 -or
    (Get-EventIndex $missingProtocolToken 'push-new') -ge 0 -or
    (Get-EventIndex $missingProtocolToken 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0061 missing protocol token reached authentication or mutation.'
}

$invalidAuthenticatedActor = Invoke-AdapterScenario -Name 'invalid-authenticated-actor' `
    -InvalidAuthenticatedActor $true
if (-not $invalidAuthenticatedActor.Threw -or
    $invalidAuthenticatedActor.Error -notlike '*authenticated updater actor*') {
    Add-Failure "TEST-0023 an empty authenticated PAT identity must fail closed: $($invalidAuthenticatedActor.Error)"
}
if ((Get-EventIndex $invalidAuthenticatedActor 'push-new') -ge 0 -or
    (Get-EventIndex $invalidAuthenticatedActor 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0023 invalid authenticated identity caused mutation.'
}

$rotatedActor = Invoke-AdapterScenario -Name 'rotated-actor' `
    -OldAuthorLogin 'previous-owner'
if (-not $rotatedActor.Threw -or $rotatedActor.Error -notlike '*manual review*') {
    Add-Failure 'TEST-0023 PAT-owner rotation must not adopt an older managed proposal.'
}
if ((Get-EventIndex $rotatedActor 'push-new') -ge 0 -or
    (Get-EventIndex $rotatedActor 'close-old-pr') -ge 0 -or
    (Get-EventIndex $rotatedActor 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0023 actor rotation mutated an ambiguously owned proposal.'
}

$driftedCurrentAsset = Invoke-AdapterScenario -Name 'drifted-current-asset' `
    -DriftCurrentAsset $true
if (-not $driftedCurrentAsset.Threw -or
    $driftedCurrentAsset.Error -notlike '*current pinned updater template*') {
    Add-Failure "TEST-0025 current managed asset drift must fail closed: $($driftedCurrentAsset.Error)"
}
if ((Get-EventIndex $driftedCurrentAsset 'push-new') -ge 0 -or
    (Get-EventIndex $driftedCurrentAsset 'create-new-pr') -ge 0 -or
    (Get-EventIndex $driftedCurrentAsset 'close-old-pr') -ge 0) {
    Add-Failure 'TEST-0025 current managed asset drift caused a remote mutation.'
}

$wrongStagedAsset = Invoke-AdapterScenario -Name 'wrong-staged-asset' `
    -WrongStagedAssetBlob $true
if (-not $wrongStagedAsset.Threw -or
    $wrongStagedAsset.Error -notlike '*Staged updater asset*target release blob*') {
    Add-Failure "TEST-0024 wrong staged updater blob must fail before push: $($wrongStagedAsset.Error)"
}
if ((Get-EventIndex $wrongStagedAsset 'push-new') -ge 0 -or
    (Get-EventIndex $wrongStagedAsset 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0024 wrong staged updater blob reached remote mutation.'
}

$extraCommittedPath = Invoke-AdapterScenario -Name 'extra-committed-path' `
    -CommitExtraApplicationPath $true
if (-not $extraCommittedPath.Threw -or
    $extraCommittedPath.Error -notlike '*Committed proposal paths*') {
    Add-Failure "TEST-0024 a commit-hook application-path injection did not fail at the committed-tree gate: $($extraCommittedPath.Error)"
}
foreach ($forbiddenEvent in @('create-update-issue', 'push-new', 'create-new-pr')) {
    if ((Get-EventIndex $extraCommittedPath $forbiddenEvent) -ge 0) {
        Add-Failure "TEST-0024 a commit-hook application-path injection reached remote mutation '$forbiddenEvent'."
    }
}

$wrongCommittedParent = Invoke-AdapterScenario -Name 'wrong-committed-parent' `
    -WrongCommittedParent $true
if (-not $wrongCommittedParent.Threw -or
    $wrongCommittedParent.Error -notlike '*exact captured base*') {
    Add-Failure "TEST-0024 a proposal commit not parented by the captured base did not fail closed: $($wrongCommittedParent.Error)"
}
foreach ($forbiddenEvent in @('create-update-issue', 'push-new', 'create-new-pr')) {
    if ((Get-EventIndex $wrongCommittedParent $forbiddenEvent) -ge 0) {
        Add-Failure "TEST-0024 a wrong-parent proposal commit reached remote mutation '$forbiddenEvent'."
    }
}

$wrongCommittedAsset = Invoke-AdapterScenario -Name 'wrong-committed-asset' `
    -WrongCommittedAssetBlob $true
if (-not $wrongCommittedAsset.Threw -or
    $wrongCommittedAsset.Error -notlike '*Committed updater asset*target release blob*') {
    Add-Failure "TEST-0024 committed updater-asset substitution did not fail closed: $($wrongCommittedAsset.Error)"
}
foreach ($forbiddenEvent in @('create-update-issue', 'push-new', 'create-new-pr')) {
    if ((Get-EventIndex $wrongCommittedAsset $forbiddenEvent) -ge 0) {
        Add-Failure "TEST-0024 committed updater-asset substitution reached remote mutation '$forbiddenEvent'."
    }
}

$wrongCommittedMigration = Invoke-AdapterScenario `
    -Name 'wrong-committed-migration-result' -MigrationRequired $true `
    -MigrationWithUpgrade $true -OldCandidateExists $false `
    -OldBranchExists $false -WrongCommittedMigrationBlob $true
if (-not $wrongCommittedMigration.Threw -or
    $wrongCommittedMigration.Error -notlike "*Committed migration result 'AGENTS.md'*deterministic plan*") {
    Add-Failure "TEST-0121 committed migration-result substitution did not fail closed: $($wrongCommittedMigration.Error)"
}
foreach ($forbiddenEvent in @('create-update-issue', 'push-new', 'create-new-pr')) {
    if ((Get-EventIndex $wrongCommittedMigration $forbiddenEvent) -ge 0) {
        Add-Failure "TEST-0121 committed migration-result substitution reached remote mutation '$forbiddenEvent'."
    }
}

$wrongTargetAsset = Invoke-AdapterScenario -Name 'wrong-target-asset' `
    -ExistingReplacement $true -WrongTargetAssetBlob $true
if (-not $wrongTargetAsset.Threw -or $wrongTargetAsset.Error -notlike '*manual review*') {
    Add-Failure "TEST-0026 wrong target asset blob must block reconciliation: $($wrongTargetAsset.Error)"
}
if ((Get-EventIndex $wrongTargetAsset 'close-old-pr') -ge 0 -or
    (Get-EventIndex $wrongTargetAsset 'delete-old-branch') -ge 0 -or
    (Get-EventIndex $wrongTargetAsset 'close-new-pr') -ge 0) {
    Add-Failure 'TEST-0026 wrong target asset blob allowed destructive cleanup.'
}
$successOrder = @(
    'create-new-pr', 'verify-new-pr-1', 'read-old-pr-2', 'verify-new-pr-2',
    'close-old-pr', 'read-old-pr-3', 'verify-new-pr-3',
    'delete-old-branch', 'read-old-pr-4', 'verify-new-pr-4', 'comment-old-pr'
)
$previous = -1
foreach ($event in $successOrder) {
    $index = Get-EventIndex -Scenario $success -Event $event
    if ($index -le $previous) {
        Add-Failure "TEST-0011 adapter event '$event' is missing or out of replacement-first order: $($success.Events -join ', ')"
        break
    }
    $previous = $index
}

$cleanupCompletedText = 'Automated cleanup closed this PR and deleted its unchanged branch using an exact-head lease.'
if (-not $success.OldPullRequestComment.Contains($cleanupCompletedText)) {
    Add-Failure "TEST-0021 emitted cleanup comment is missing '$cleanupCompletedText'"
}
if ([regex]::Matches($adapterContent, [regex]::Escape($cleanupCompletedText)).Count -ne 2) {
    Add-Failure "TEST-0021 both cleanup comment paths must contain '$cleanupCompletedText'"
}
if ((Get-EventIndex $success 'comment-old-pr') -lt
    (Get-EventIndex $success 'delete-old-branch')) {
    Add-Failure 'TEST-0021 cleanup completion must not be announced before branch deletion is verified.'
}
if ($success.OldPullRequestComment.Contains('will be removed') -or
    $adapterContent.Contains('automation branch will be removed')) {
    Add-Failure 'TEST-0021 cleanup comments must not promise branch removal before it succeeds.'
}

$verificationFailure = Invoke-AdapterScenario -Name 'verification-failure' -NewDraft $false
if (-not $verificationFailure.Threw) {
    Add-Failure 'TEST-0011 invalid replacement verification should fail.'
}
if ((Get-EventIndex $verificationFailure 'close-new-pr') -ge 0 -or
    (Get-EventIndex $verificationFailure 'delete-new-branch') -ge 0) {
    Add-Failure 'TEST-0015 ambiguous failed replacement was closed or deleted during rollback.'
}
if ((Get-EventIndex $verificationFailure 'close-old-pr') -ge 0 -or
    (Get-EventIndex $verificationFailure 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0011 failed replacement mutated the older proposal.'
}

$humanRace = Invoke-AdapterScenario -Name 'human-race' -MutateOldAfterSnapshot $true
if (-not $humanRace.Threw -or $humanRace.Error -notlike '*changed after planning*') {
    Add-Failure 'TEST-0015 post-snapshot human change should fail closed.'
}
if ((Get-EventIndex $humanRace 'close-old-pr') -ge 0 -or
    (Get-EventIndex $humanRace 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0015 post-snapshot human change was closed or deleted.'
}

$replacementRace = Invoke-AdapterScenario -Name 'replacement-race' `
    -ExistingReplacement $true -MutateNewAfterSnapshot $true
if (-not $replacementRace.Threw -or $replacementRace.Error -notlike '*changed after planning*') {
    Add-Failure 'TEST-0015 changed existing replacement should fail closed before supersession.'
}
if ((Get-EventIndex $replacementRace 'close-old-pr') -ge 0 -or
    (Get-EventIndex $replacementRace 'delete-old-branch') -ge 0 -or
    (Get-EventIndex $replacementRace 'close-new-pr') -ge 0) {
    Add-Failure 'TEST-0015 changed replacement allowed destructive supersession.'
}

$postCloseReplacementRace = Invoke-AdapterScenario `
    -Name 'post-close-replacement-race' -ExistingReplacement $true `
    -MutateReplacementAfterOldClose $true
if (-not $postCloseReplacementRace.Threw -or
    $postCloseReplacementRace.Error -notlike '*reopened and the branch preserved*') {
    Add-Failure "TEST-0058 post-close replacement mutation was not compensated: $($postCloseReplacementRace.Error)"
}
if ((Get-EventIndex $postCloseReplacementRace 'close-old-pr') -lt 0 -or
    (Get-EventIndex $postCloseReplacementRace 'reopen-old-pr') -lt 0 -or
    (Get-EventIndex $postCloseReplacementRace 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0058 post-close replacement mutation must reopen the old PR and preserve its branch.'
}

$closeNoOp = Invoke-AdapterScenario -Name 'close-no-op' -CloseOldNoOp $true
if (-not $closeNoOp.Threw -or
    $closeNoOp.Error -notlike '*reopened and the branch preserved*') {
    Add-Failure "TEST-0058 a no-op close was not detected and compensated: $($closeNoOp.Error)"
}
if ((Get-EventIndex $closeNoOp 'reopen-old-pr') -lt 0 -or
    (Get-EventIndex $closeNoOp 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0058 a no-op close must not permit branch deletion.'
}

foreach ($renameMode in @('InventoryRename', 'RevalidationRename')) {
    $renameScenario = Invoke-AdapterScenario -Name "rename-$renameMode" `
        -ExistingReplacement $true -RenameMode $renameMode
    if (-not $renameScenario.Threw -or
        $renameScenario.Error -notlike '*rename metadata is outside the managed update contract*') {
        Add-Failure "TEST-0048 $renameMode did not fail closed on unmanaged rename provenance: $($renameScenario.Error)"
    }
    foreach ($forbiddenEvent in @(
        'close-old-pr', 'delete-old-branch', 'close-new-pr', 'delete-new-branch'
    )) {
        if ((Get-EventIndex $renameScenario $forbiddenEvent) -ge 0) {
            Add-Failure "TEST-0048 $renameMode reached forbidden mutation '$forbiddenEvent'."
        }
    }
}

$coordinatedHeadRace = Invoke-AdapterScenario -Name 'coordinated-head-race' `
    -ExistingReplacement $true -CoordinateNewHeadMutation $true
if (-not $coordinatedHeadRace.Threw -or $coordinatedHeadRace.Error -notlike '*head SHA changed*') {
    Add-Failure 'TEST-0015 coordinated marker/API/remote head mutation must remain bound to the planned SHA.'
}
if ((Get-EventIndex $coordinatedHeadRace 'close-old-pr') -ge 0 -or
    (Get-EventIndex $coordinatedHeadRace 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0015 coordinated replacement mutation allowed older cleanup.'
}

$creationRace = Invoke-AdapterScenario -Name 'creation-race' -ConcurrentNewBranch $true
if (-not $creationRace.Threw -or (Get-EventIndex $creationRace 'reject-new-branch-lease') -lt 0) {
    Add-Failure 'TEST-0015 concurrent reserved-branch creation should fail its expected-absent lease.'
}
if ((Get-EventIndex $creationRace 'delete-new-branch') -ge 0 -or
    (Get-EventIndex $creationRace 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0015 a foreign concurrently-created branch was mutated.'
}

$reservedOrphan = Invoke-AdapterScenario -Name 'reserved-orphan' `
    -OldCandidateExists $false -OldBranchExists $false `
    -ReservedOrphanBranchExists $true
if (-not $reservedOrphan.Threw -or
    $reservedOrphan.Error -notlike '*no single open proposal with matching live ownership*' -or
    (Get-EventIndex $reservedOrphan 'push-new') -ge 0) {
    Add-Failure 'TEST-0072 an orphan in the full reserved updater namespace did not block before mutation.'
}

$reservedNamespaceRace = Invoke-AdapterScenario -Name 'reserved-namespace-race' `
    -ReservedNamespaceRace $true
if (-not $reservedNamespaceRace.Threw -or
    $reservedNamespaceRace.Error -notlike '*namespace changed before replacement publication*' -or
    (Get-EventIndex $reservedNamespaceRace 'push-new') -ge 0 -or
    (Get-EventIndex $reservedNamespaceRace 'close-old-pr') -ge 0) {
    Add-Failure 'TEST-0072 a reserved updater branch appearing after inventory did not block before publication.'
}

$missingBranch = Invoke-AdapterScenario -Name 'missing-branch' -OldBranchExists $false
if (-not $missingBranch.Threw -or $missingBranch.Error -notlike '*manual review*') {
    Add-Failure 'TEST-0015 missing managed branch should block during the pre-mutation snapshot.'
}
if ((Get-EventIndex $missingBranch 'create-new-pr') -ge 0 -or
    (Get-EventIndex $missingBranch 'close-old-pr') -ge 0 -or
    (Get-EventIndex $missingBranch 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0015 missing managed branch caused a mutation.'
}

$branchDisappeared = Invoke-AdapterScenario -Name 'branch-disappeared' `
    -RemoveOldBeforeDelete $true
if (-not $branchDisappeared.Threw -or
    (Get-EventIndex $branchDisappeared 'remove-old-before-delete') -lt 0) {
    Add-Failure 'TEST-0015 branch disappearance after PR close should fail cleanup.'
}
if ((Get-EventIndex $branchDisappeared 'reopen-old-pr') -lt 0 -or
    (Get-EventIndex $branchDisappeared 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0015 disappeared branch must trigger PR reopen compensation.'
}

$deleteRace = Invoke-AdapterScenario -Name 'delete-race' -ChangeOldBeforeDelete $true
if (-not $deleteRace.Threw -or (Get-EventIndex $deleteRace 'reject-old-branch-lease') -lt 0) {
    Add-Failure 'TEST-0015 changed old branch should reject expected-head deletion.'
}
if ((Get-EventIndex $deleteRace 'reopen-old-pr') -lt 0 -or
    (Get-EventIndex $deleteRace 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0015 failed branch cleanup must reopen the old PR and preserve the branch.'
}

$compensationFailure = Invoke-AdapterScenario -Name 'compensation-failure' `
    -ChangeOldBeforeDelete $true -ReopenOldNoOp $true
if (-not $compensationFailure.Threw -or
    $compensationFailure.Error -notlike '*could not be reopened*Manual recovery is required*') {
    Add-Failure "TEST-0058 compensation failure did not require manual recovery: $($compensationFailure.Error)"
}
if ((Get-EventIndex $compensationFailure 'reopen-old-pr') -lt 0 -or
    (Get-EventIndex $compensationFailure 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0058 compensation failure must preserve the unchanged old branch.'
}

$pagination = Invoke-AdapterScenario -Name 'pagination' -LeadingUnmanagedCount 101
if ($pagination.Threw -or (Get-EventIndex $pagination 'close-old-pr') -lt 0) {
    Add-Failure "TEST-0017 paged PR inventory did not find the managed PR after 101 unrelated PRs: $($pagination.Error)"
}

$aliasTag = Invoke-AdapterScenario -Name 'alias-tag' -AliasCurrentTag $true
if (-not $aliasTag.Threw -or $aliasTag.Error -notlike '*exactly one canonical stable release tag*') {
    Add-Failure 'TEST-0013 multiple canonical tags for the current gitlink must block.'
}
if ((Get-EventIndex $aliasTag 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0013 ambiguous current tag caused a mutation.'
}

$duplicateMarker = Invoke-AdapterScenario -Name 'duplicate-marker' -DuplicateOldMarker $true
if (-not $duplicateMarker.Threw -or $duplicateMarker.Error -notlike '*manual review*') {
    Add-Failure 'TEST-0015 duplicate ownership markers should block during planning.'
}
if ((Get-EventIndex $duplicateMarker 'create-new-pr') -ge 0 -or
    (Get-EventIndex $duplicateMarker 'close-old-pr') -ge 0 -or
    (Get-EventIndex $duplicateMarker 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0015 duplicate ownership markers caused a mutation.'
}

$caseDuplicateMarker = Invoke-AdapterScenario -Name 'case-duplicate-marker' `
    -CaseVariantDuplicateMarker $true
if (-not $caseDuplicateMarker.Threw -or $caseDuplicateMarker.Error -notlike '*manual review*') {
    Add-Failure 'TEST-0015 case-variant duplicate ownership marker should block planning.'
}
if ((Get-EventIndex $caseDuplicateMarker 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0015 case-variant duplicate ownership marker caused a mutation.'
}

$nonCanonicalMarker = Invoke-AdapterScenario -Name 'noncanonical-marker' `
    -NonCanonicalOldMarker $true
if (-not $nonCanonicalMarker.Threw -or $nonCanonicalMarker.Error -notlike '*manual review*') {
    Add-Failure 'TEST-0015 noncanonical ownership marker shape should block planning.'
}
if ((Get-EventIndex $nonCanonicalMarker 'create-new-pr') -ge 0) {
    Add-Failure 'TEST-0015 noncanonical ownership marker caused a mutation.'
}

$invalidOrigin = Invoke-AdapterScenario -Name 'invalid-origin' -InvalidSubmoduleUrl $true
if (-not $invalidOrigin.Threw -or $invalidOrigin.Error -notlike '*does not match*') {
    Add-Failure 'TEST-0017 mismatched protocol submodule origin should fail adoption validation.'
}
if ((Get-EventIndex $invalidOrigin 'create-new-pr') -ge 0 -or
    (Get-EventIndex $invalidOrigin 'close-old-pr') -ge 0 -or
    (Get-EventIndex $invalidOrigin 'delete-old-branch') -ge 0) {
    Add-Failure 'TEST-0017 mismatched protocol origin caused a mutation.'
}

$wrongCaseSubmodulePath = Invoke-AdapterScenario -Name 'wrong-case-submodule-path' `
    -WrongCaseSubmodulePath $true
if (-not $wrongCaseSubmodulePath.Threw -or
    $wrongCaseSubmodulePath.Error -notlike "*'.ai/protocol' must have exactly one .gitmodules entry*") {
    Add-Failure "TEST-0058 case-variant protocol path did not fail closed: $($wrongCaseSubmodulePath.Error)"
}
foreach ($forbiddenEvent in @(
    'verify-immutable-release', 'push-new', 'create-new-pr',
    'close-old-pr', 'delete-old-branch'
)) {
    if ((Get-EventIndex $wrongCaseSubmodulePath $forbiddenEvent) -ge 0) {
        Add-Failure "TEST-0058 case-variant protocol path reached '$forbiddenEvent'."
    }
}

foreach ($requiredLifecycleText in @(
    'meandai-protocol-update-issue:',
    'Ensure-ProtocolUpdateIssue',
    'Set-ProtocolUpdateIssuePullRequestLink',
    'Complete-SupersededProtocolUpdateIssue',
    'ISSUE_TOKEN',
    'Tracking issue: #$($updateIssue.Number)'
)) {
    if (-not $adapterContent.Contains($requiredLifecycleText)) {
        Add-Failure "TEST-0111 adapter lacks automatic update lifecycle contract '$requiredLifecycleText'."
    }
}
if ($adapterContent.Contains('Update the consumer project memory pinned-version fact') -or
    $adapterContent.Contains('Create or link the tracked issue')) {
    Add-Failure 'TEST-0111 adapter still delegates managed issue or derived pin reconciliation to the maintainer.'
}
$workflowContent = Get-Content -LiteralPath $workflowSource -Raw
if (-not $workflowContent.Contains('ISSUE_TOKEN: ${{ github.token }}') -or
    -not $workflowContent.Contains('issues: write')) {
    Add-Failure 'TEST-0111 proposal workflow does not grant the job-scoped token its narrow issue authority.'
}

Remove-Item Function:\git -ErrorAction SilentlyContinue
Remove-Item Function:\gh -ErrorAction SilentlyContinue
Remove-Variable MeAndAITestScenario -Scope Global -ErrorAction SilentlyContinue

if ($failures.Count -gt 0) {
    Write-Host "Protocol update adapter tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Protocol update adapter tests passed for all declared scenarios in this suite.' -ForegroundColor Green
