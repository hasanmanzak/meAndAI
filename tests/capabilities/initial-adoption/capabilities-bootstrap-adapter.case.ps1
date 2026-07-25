[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$suiteOwner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
$caseOwner = 'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.case.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$caseTestIds = @(
    'TEST-0028', 'TEST-0029', 'TEST-0030', 'TEST-0031',
    'TEST-0057', 'TEST-0062', 'TEST-0068', 'TEST-0071',
    'TEST-0077', 'TEST-0093', 'TEST-0094', 'TEST-0095',
    'TEST-0127', 'TEST-0128', 'TEST-0153'
)
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$caseContext = New-MeAndAICaseEvidenceContext -SuiteOwner $suiteOwner `
    -CaseOwner $caseOwner -TestIds $caseTestIds `
    -AuthorityPath $scenarioAuthorityPath
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$capabilitiesModulePath = Join-Path $root `
    'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$graphIdentityFixturePath = Join-Path $PSScriptRoot `
    'capabilities-bootstrap-graph-identity.case.ps1'
$graphDriftFixturePath = Join-Path $PSScriptRoot `
    'capabilities-bootstrap-adapter-drift.case.ps1'
$consumerMigrationModulePath = Join-Path $root `
    'scripts/MeAndAI.ConsumerMigrations.psm1'
$consumerMigrationIndexPath = Join-Path $root 'migrations/index.json'
$testRuntimePath = Join-Path $root `
    'tests/infrastructure/MeAndAI.TestRuntime.psm1'
$testWorkspacePath = Join-Path $root `
    'tests/infrastructure/MeAndAI.TestWorkspace.psm1'
$operationContractPath = Join-Path $root `
    'tests/fixture-operation-budgets.psd1'
Import-Module $testRuntimePath -Force
Import-Module $testWorkspacePath -Force
$operationContract = Import-MeAndAITestOperationContract `
    -Path $operationContractPath
$operationExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $operationContract `
    -Owner 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1' `
    -SuiteArguments @()
Import-Module $consumerMigrationModulePath -Force
$consumerMigrationCatalog = Import-MeAndAIConsumerMigrationCatalog `
    -IndexPath $consumerMigrationIndexPath
$consumerMigrationBaseline = New-MeAndAIConsumerMigrationBaseline `
    -Catalog $consumerMigrationCatalog
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
$testContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $testContext
$failures = $testContext.Failures
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
$script:BootstrapImmutableBaseline = $null
$script:BootstrapPreparedOwner =
    'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
$script:BootstrapPreparedRoute = 'Adapter'
$script:BootstrapFixtureOperations = [pscustomobject]@{
    PreparedOwnerBuilds = 0
    PreparedOwnerReuses = 0
    PreparedConsumerCheckouts = 0
    PreparedProtocolCheckouts = 0
    PreparedBareRemotes = 0
    FixtureInit = 0
    FixtureClone = 0
    FixtureBundleCreate = 0
    FixturePublicationPush = 0
    GraphChildProcess = 0
    GraphIsolatedAcquisition = 0
    MutableDerivatives = 0
}
$script:BootstrapDerivativeRoots = [System.Collections.Generic.List[string]]::new()
$script:BootstrapModeSensitivityChecked = $false

if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) {
    Write-Host 'AI capabilities bootstrap adapter tests failed:' -ForegroundColor Red
    Write-Host ' - TEST-0028 missing source-only bootstrap adapter.' -ForegroundColor Red
    exit 1
}

function Invoke-Git {
    param([string]$Repository, [string[]]$Arguments)
    $fixtureConfiguration = @(
        '-c', 'user.name=Fixture',
        '-c', 'user.email=fixture@example.invalid',
        '-c', 'core.autocrlf=false',
        '-c', 'core.ignorecase=false',
        '-c', 'commit.gpgsign=false',
        '-c', 'tag.gpgSign=false'
    )
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git @fixtureConfiguration -C $Repository @Arguments 2>&1)
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

function Get-FixtureInstructionGraphIdentity {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    if (-not (Test-Path -LiteralPath $graphIdentityFixturePath `
            -PathType Leaf)) {
        throw 'The TEST-0153 isolated graph-identity fixture is missing.'
    }
    $execution = Invoke-BootstrapChildCase `
        -CasePath $graphIdentityFixturePath `
        -CaseOwner 'tests/capabilities/initial-adoption/capabilities-bootstrap-graph-identity.case.ps1' `
        -Arguments @(
            '-Repository', $Repository,
            '-Commit', $Commit,
            '-ModulePath', $capabilitiesModulePath
        )
    $output = @($execution.Output)
    $records = @($output | Where-Object {
        [string]$_ -like 'MEANDAI_TEST_GRAPH_IDENTITY=*'
    })
    if ($records.Count -ne 1) {
        throw 'The TEST-0153 isolated graph-identity fixture returned ambiguous evidence.'
    }
    return ([string]$records[0]).Substring(
        'MEANDAI_TEST_GRAPH_IDENTITY='.Length
    ) | ConvertFrom-Json
}

function Invoke-BootstrapChildCase {
    param(
        [Parameter(Mandatory)][string]$CasePath,
        [Parameter(Mandatory)][string]$CaseOwner,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $engine = (Get-Process -Id $PID).Path
    $script:BootstrapFixtureOperations.GraphChildProcess++
    $process = Invoke-MeAndAITestCaseProcess -EnginePath $engine `
        -CasePath $CasePath -Arguments $Arguments
    if ([int]$process.ExitCode -ne 0) {
        throw "Bootstrap child Case '$CaseOwner' failed: $(@($process.Output) -join [Environment]::NewLine)"
    }
    $record = Read-MeAndAICaseResultRecord -Output @($process.Output) `
        -ExpectedSuite $suiteOwner -ExpectedCase $CaseOwner `
        -ExpectedTestIds @('TEST-0153')
    if (-not $record.Valid) {
        throw "Bootstrap child Case '$CaseOwner' returned invalid evidence: $($record.Message)"
    }
    return [pscustomobject]@{
        Output = @($process.Output | Where-Object {
            -not ([string]$_).StartsWith(
                'MEANDAI_CASE_RESULTS=', [StringComparison]::Ordinal
            )
        })
        Record = $record.Record
    }
}

function Invoke-IsolatedGraphDriftFixture {
    param(
        [Parameter(Mandatory)]$Fixture,
        [Parameter(Mandatory)][string]$SourceGraphIdentityJson
    )

    if (-not (Test-Path -LiteralPath $graphDriftFixturePath -PathType Leaf)) {
        throw 'The TEST-0153 isolated adapter-drift fixture is missing.'
    }
    $encodedIdentity = [Convert]::ToBase64String(
        [Text.UTF8Encoding]::new($false).GetBytes(
            $SourceGraphIdentityJson
        )
    )
    try {
        $script:BootstrapFixtureOperations.GraphIsolatedAcquisition++
        $execution = Invoke-BootstrapChildCase `
            -CasePath $graphDriftFixturePath `
            -CaseOwner 'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter-drift.case.ps1' `
            -Arguments @(
                '-AdapterPath', $adapterPath,
                '-Workspace', ([string]$Fixture.Consumer),
                '-SourceGraphIdentityBase64', $encodedIdentity
            )
        $output = @($execution.Output)
    }
    catch {
        return [pscustomobject]@{
            Threw = $false
            Error = $_.Exception.Message
        }
    }
    $records = @($output | Where-Object {
        [string]$_ -like 'MEANDAI_TEST_GRAPH_REJECTION=*'
    })
    if ($records.Count -ne 1) {
        return [pscustomobject]@{
            Threw = $false
            Error = 'The isolated drift fixture returned ambiguous evidence.'
        }
    }
    return [pscustomobject]@{
        Threw = $true
        Error = ([string]$records[0]).Substring(
            'MEANDAI_TEST_GRAPH_REJECTION='.Length
        )
    }
}

function Invoke-IsolatedGraphSuccessFixture {
    param(
        [Parameter(Mandatory)]$Fixture,
        [Parameter(Mandatory)][string]$SourceGraphIdentityJson
    )

    $encodedIdentity = [Convert]::ToBase64String(
        [Text.UTF8Encoding]::new($false).GetBytes(
            $SourceGraphIdentityJson
        )
    )
    try {
        $script:BootstrapFixtureOperations.GraphIsolatedAcquisition++
        $execution = Invoke-BootstrapChildCase `
            -CasePath $graphDriftFixturePath `
            -CaseOwner 'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter-drift.case.ps1' `
            -Arguments @(
                '-AdapterPath', $adapterPath,
                '-Workspace', ([string]$Fixture.Consumer),
                '-SourceGraphIdentityBase64', $encodedIdentity,
                '-ExpectSuccess'
            )
        $output = @($execution.Output)
    }
    catch {
        return [pscustomobject]@{
            Threw = $true
            Error = $_.Exception.Message
            PullRequestBody = ''
        }
    }
    $records = @($output | Where-Object {
        [string]$_ -like 'MEANDAI_TEST_PROPOSAL_BODY_BASE64=*'
    })
    if ($records.Count -ne 1) {
        return [pscustomobject]@{
            Threw = $true
            Error = 'The isolated success fixture returned ambiguous evidence.'
            PullRequestBody = ''
        }
    }
    try {
        $body = [Text.UTF8Encoding]::new($false, $true).GetString(
            [Convert]::FromBase64String(
                ([string]$records[0]).Substring(
                    'MEANDAI_TEST_PROPOSAL_BODY_BASE64='.Length
                )
            )
        )
    }
    catch {
        return [pscustomobject]@{
            Threw = $true
            Error = 'The isolated success fixture returned invalid body evidence.'
            PullRequestBody = ''
        }
    }
    return [pscustomobject]@{
        Threw = $false
        Error = ''
        PullRequestBody = $body
    }
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
        'scripts/MeAndAI.ContentIdentity.psm1',
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

function Get-FixtureFileSha256 {
    param([Parameter(Mandatory)][string]$Path)

    return [string](Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-BootstrapFixtureStringSha256 {
    param([Parameter(Mandatory)][string]$Value)

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Value)
        return 'sha256:' + (([BitConverter]::ToString(
            $algorithm.ComputeHash($bytes)
        )) -replace '-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Get-BootstrapFixtureEntryMode {
    param([Parameter(Mandatory)][IO.FileSystemInfo]$Item)

    if ($env:OS -ne 'Windows_NT') {
        $method = @([IO.File].GetMethods() | Where-Object {
            $_.Name -ceq 'GetUnixFileMode' -and
            $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType -eq [string]
        }) | Select-Object -First 1
        if ($null -eq $method) {
            throw 'Unix bootstrap fixture-mode evidence is unavailable on this runtime.'
        }
        $mode = $method.Invoke($null, [object[]]@([string]$Item.FullName))
        return 'unix:' + [int]$mode
    }
    return 'attributes:' + [int]$Item.Attributes
}

function Get-BootstrapFixtureTreeFingerprint {
    param([Parameter(Mandatory)][string]$Path)

    $rootItem = Get-Item -LiteralPath $Path -Force
    if (-not $rootItem.PSIsContainer -or
        ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Bootstrap fixture tree is not a regular owned directory: $Path"
    }
    $resolvedRoot = [IO.Path]::GetFullPath([string]$rootItem.FullName).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $records = [System.Collections.Generic.List[string]]::new()
    $records.Add(
        "ROOT`t$(Get-BootstrapFixtureEntryMode -Item $rootItem)"
    )
    foreach ($item in @(Get-ChildItem -LiteralPath $resolvedRoot -Force `
            -Recurse | Sort-Object FullName)) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Bootstrap fixture tree contains a link or reparse point: $($item.FullName)"
        }
        $relativePath = ([string]$item.FullName).Substring(
            $resolvedRoot.Length
        ) -replace '^[\\/]+', ''
        $relativePath = $relativePath.Replace(
            [IO.Path]::DirectorySeparatorChar, '/'
        )
        $entryMode = Get-BootstrapFixtureEntryMode -Item $item
        if ($item.PSIsContainer) {
            $records.Add("D`t$relativePath`t$entryMode")
        }
        else {
            $records.Add(
                "F`t$relativePath`t$entryMode`t$($item.Length)`t$(Get-FixtureFileSha256 -Path $item.FullName)"
            )
        }
    }
    return Get-BootstrapFixtureStringSha256 -Value ($records -join "`n")
}

function Assert-BootstrapFingerprintModeSensitivity {
    if ($script:BootstrapModeSensitivityChecked) { return }
    if ($env:OS -eq 'Windows_NT') {
        $script:BootstrapModeSensitivityChecked = $true
        return
    }

    $probeRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-bootstrap-mode-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $probeRoot -Force | Out-Null
    $tempRoots.Add($probeRoot)
    $probePath = Join-Path $probeRoot 'mode-probe.txt'
    [IO.File]::WriteAllText(
        $probePath, "mode probe`n", [Text.UTF8Encoding]::new($false)
    )
    $before = Get-BootstrapFixtureTreeFingerprint -Path $probeRoot
    try {
        & chmod u+x -- $probePath
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to create the bootstrap mode-only mutation.'
        }
        $changed = Get-BootstrapFixtureTreeFingerprint -Path $probeRoot
        if ($changed -ceq $before) {
            throw 'TEST-0158 bootstrap fingerprint ignored a mode-only mutation.'
        }
    }
    finally {
        & chmod u-x -- $probePath
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to restore the bootstrap mode-only mutation.'
        }
    }
    $restored = Get-BootstrapFixtureTreeFingerprint -Path $probeRoot
    if ($restored -cne $before) {
        throw 'TEST-0158 bootstrap mode-only mutation did not restore exactly.'
    }
    $script:BootstrapModeSensitivityChecked = $true
}

function Copy-BootstrapFixtureTree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (Test-Path -LiteralPath $Destination) {
        throw "Bootstrap mutable derivative already exists: $Destination"
    }
    $sourceItem = Get-Item -LiteralPath $Source -Force
    if (-not $sourceItem.PSIsContainer -or
        ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Bootstrap prepared source is not a regular directory: $Source"
    }
    foreach ($item in @(Get-ChildItem -LiteralPath $Source -Force -Recurse)) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Bootstrap prepared source contains a link or reparse point: $($item.FullName)"
        }
    }

    New-Item -ItemType Directory -Path $Destination | Out-Null
    foreach ($child in @(Get-ChildItem -LiteralPath $Source -Force)) {
        Copy-Item -LiteralPath $child.FullName -Destination $Destination `
            -Recurse -Force
    }
    foreach ($item in @(Get-ChildItem -LiteralPath $Destination -Force `
            -Recurse)) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Bootstrap mutable derivative contains a link or reparse point: $($item.FullName)"
        }
    }
    $sharedGitState = @(
        (Join-Path $Destination '.git/objects/info/alternates'),
        (Join-Path $Destination 'objects/info/alternates'),
        (Join-Path $Destination '.git/commondir'),
        (Join-Path $Destination 'commondir')
    )
    if (@($sharedGitState | Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
    }).Count -gt 0) {
        throw 'Bootstrap mutable derivatives must not use Git alternates or shared worktree state.'
    }
}

function New-ImmutableBootstrapBaseline {
    if ([int]$script:BootstrapFixtureOperations.PreparedOwnerBuilds -ne 0) {
        throw 'TEST-0158 bootstrap prepared owner was requested more than once.'
    }
    $script:BootstrapFixtureOperations.PreparedOwnerBuilds++
    $baselineRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-capabilities-baseline-$([guid]::NewGuid().ToString('N'))"
    $tempRoots.Add($baselineRoot)
    $consumerSeed = Join-Path $baselineRoot 'consumer-seed'
    $protocolSeed = Join-Path $baselineRoot 'protocol-seed'
    $consumerBundle = Join-Path $baselineRoot 'consumer.bundle'
    $protocolBundle = Join-Path $baselineRoot 'protocol.bundle'
    $preparedConsumer = Join-Path $baselineRoot 'prepared-consumer'
    $preparedProtocol = Join-Path $baselineRoot 'prepared-protocol'
    $preparedBareRemote = Join-Path $baselineRoot 'prepared-empty-remote.git'
    New-Item -ItemType Directory -Path $consumerSeed, $protocolSeed -Force |
        Out-Null

    $script:BootstrapFixtureOperations.FixtureInit++
    Invoke-Git -Repository $consumerSeed -Arguments @(
        'init', '-b', 'main'
    ) | Out-Null
    $consumerWorkflow = Join-Path $consumerSeed `
        '.github/workflows/meandai-protocol-update.yml'
    New-Item -ItemType Directory -Path (Split-Path -Parent $consumerWorkflow) `
        -Force | Out-Null
    Copy-Item -LiteralPath $workflowPath -Destination $consumerWorkflow
    Invoke-Git -Repository $consumerSeed -Arguments @('add', '.') | Out-Null
    Invoke-Git -Repository $consumerSeed -Arguments @(
        'commit', '-m', 'Seed immutable consumer baseline'
    ) | Out-Null
    $consumerHead = (@(Invoke-Git -Repository $consumerSeed -Arguments @(
        'rev-parse', 'HEAD'
    )))[0]
    $script:BootstrapFixtureOperations.FixtureBundleCreate++
    Invoke-Git -Repository $consumerSeed -Arguments @(
        'bundle', 'create', $consumerBundle, 'main'
    ) | Out-Null
    Invoke-Git -Repository $consumerSeed -Arguments @(
        'bundle', 'verify', $consumerBundle
    ) | Out-Null

    Copy-SourceFixture -SourceRepository $protocolSeed
    $script:BootstrapFixtureOperations.FixtureInit++
    Invoke-Git -Repository $protocolSeed -Arguments @(
        'init', '-b', 'main'
    ) | Out-Null
    Invoke-Git -Repository $protocolSeed -Arguments @('add', '.') | Out-Null
    Invoke-Git -Repository $protocolSeed -Arguments @(
        'commit', '-m', 'Protocol v0.5.0'
    ) | Out-Null
    Invoke-Git -Repository $protocolSeed -Arguments @(
        'tag', 'v0.5.0'
    ) | Out-Null
    $protocolHead = (@(Invoke-Git -Repository $protocolSeed -Arguments @(
        'rev-parse', 'v0.5.0^{commit}'
    )))[0]
    $script:BootstrapFixtureOperations.FixtureBundleCreate++
    Invoke-Git -Repository $protocolSeed -Arguments @(
        'bundle', 'create', $protocolBundle, '--all'
    ) | Out-Null
    Invoke-Git -Repository $protocolSeed -Arguments @(
        'bundle', 'verify', $protocolBundle
    ) | Out-Null

    $script:BootstrapFixtureOperations.FixtureInit++
    Invoke-Git -Repository $baselineRoot -Arguments @(
        'init', '--bare', $preparedBareRemote
    ) | Out-Null
    $script:BootstrapFixtureOperations.PreparedBareRemotes++

    $script:BootstrapFixtureOperations.FixtureClone++
    Invoke-Git -Repository $baselineRoot -Arguments @(
        'clone', '--branch', 'main', '--single-branch',
        $consumerBundle, $preparedConsumer
    ) | Out-Null
    $script:BootstrapFixtureOperations.PreparedConsumerCheckouts++

    $script:BootstrapFixtureOperations.FixtureClone++
    Invoke-Git -Repository $baselineRoot -Arguments @(
        'clone', '--branch', 'v0.5.0', '--single-branch',
        $protocolBundle, $preparedProtocol
    ) | Out-Null
    $script:BootstrapFixtureOperations.PreparedProtocolCheckouts++

    $preparedConsumerHead = (@(Invoke-Git -Repository $preparedConsumer `
        -Arguments @('rev-parse', 'HEAD')))[0]
    $preparedProtocolHead = (@(Invoke-Git -Repository $preparedProtocol `
        -Arguments @('rev-parse', 'v0.5.0^{commit}')))[0]
    if ([string]$preparedConsumerHead -cne [string]$consumerHead -or
        [string]$preparedProtocolHead -cne [string]$protocolHead -or
        @(Invoke-Git -Repository $preparedBareRemote -Arguments @(
            'for-each-ref', '--format=%(refname)'
        )).Count -ne 0 -or
        @(Invoke-Git -Repository $preparedConsumer -Arguments @(
            'status', '--porcelain'
        )).Count -ne 0 -or
        @(Invoke-Git -Repository $preparedProtocol -Arguments @(
            'status', '--porcelain'
        )).Count -ne 0) {
        throw 'TEST-0158 bootstrap prepared checkouts do not match their clean immutable seeds.'
    }

    $consumerBundleSha256 = Get-FixtureFileSha256 -Path $consumerBundle
    $protocolBundleSha256 = Get-FixtureFileSha256 -Path $protocolBundle
    $builder = 'capabilities-bootstrap-adapter.prepared-seeds.v1'
    $inputDigest = Get-BootstrapFixtureStringSha256 -Value (@(
        'schema=1',
        "owner=$script:BootstrapPreparedOwner",
        "route=$script:BootstrapPreparedRoute",
        'key=initial-adoption/bootstrap/prepared-seeds',
        "builder=$builder",
        "consumerHead=$consumerHead",
        "consumerBundle=$consumerBundleSha256",
        "protocolHead=$protocolHead",
        "protocolBundle=$protocolBundleSha256"
    ) -join "`n")

    return [pscustomobject]@{
        Root = $baselineRoot
        Owner = $script:BootstrapPreparedOwner
        Route = $script:BootstrapPreparedRoute
        Runtime = 'Any'
        Key = 'initial-adoption/bootstrap/prepared-seeds'
        Builder = $builder
        Scope = 'SuiteProcess'
        InputDigest = $inputDigest
        PreparedConsumerCheckoutCount = 1
        PreparedProtocolCheckoutCount = 1
        PreparedBareRemoteCount = 1
        PreparedConsumer = $preparedConsumer
        PreparedConsumerFingerprint = Get-BootstrapFixtureTreeFingerprint `
            -Path $preparedConsumer
        PreparedProtocol = $preparedProtocol
        PreparedProtocolFingerprint = Get-BootstrapFixtureTreeFingerprint `
            -Path $preparedProtocol
        PreparedBareRemote = $preparedBareRemote
        PreparedBareRemoteFingerprint = Get-BootstrapFixtureTreeFingerprint `
            -Path $preparedBareRemote
        ConsumerBundle = $consumerBundle
        ConsumerBundleSha256 = $consumerBundleSha256
        ConsumerHead = [string]$consumerHead
        ProtocolBundle = $protocolBundle
        ProtocolBundleSha256 = $protocolBundleSha256
        ProtocolHead = [string]$protocolHead
    }
}

function Assert-ImmutableBootstrapBaseline {
    param(
        [Parameter(Mandatory)]$Baseline,
        [switch]$Complete
    )

    $requiredPaths = @(
        [string]$Baseline.ConsumerBundle,
        [string]$Baseline.ProtocolBundle,
        [string]$Baseline.PreparedConsumer,
        [string]$Baseline.PreparedProtocol,
        [string]$Baseline.PreparedBareRemote
    )
    if (@($requiredPaths | Where-Object {
        -not (Test-Path -LiteralPath $_)
    }).Count -gt 0) {
        throw 'The capability-local immutable fixture baseline was mutated.'
    }
    if ($Complete -and (
        (Get-FixtureFileSha256 -Path ([string]$Baseline.ConsumerBundle)) `
            -cne [string]$Baseline.ConsumerBundleSha256 -or
        (Get-FixtureFileSha256 -Path ([string]$Baseline.ProtocolBundle)) `
            -cne [string]$Baseline.ProtocolBundleSha256 -or
        (Get-BootstrapFixtureTreeFingerprint `
            -Path ([string]$Baseline.PreparedConsumer)) `
            -cne [string]$Baseline.PreparedConsumerFingerprint -or
        (Get-BootstrapFixtureTreeFingerprint `
            -Path ([string]$Baseline.PreparedProtocol)) `
            -cne [string]$Baseline.PreparedProtocolFingerprint -or
        (Get-BootstrapFixtureTreeFingerprint `
            -Path ([string]$Baseline.PreparedBareRemote)) `
            -cne [string]$Baseline.PreparedBareRemoteFingerprint)) {
        throw 'TEST-0158 bootstrap prepared baseline fingerprints changed during the suite.'
    }
}

function Assert-BootstrapPreparedSeedContract {
    param([Parameter(Mandatory)]$Baseline)

    $expectedOwner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
    if ([string]$Baseline.Owner -cne $expectedOwner -or
        [string]$Baseline.Route -cne 'Adapter' -or
        [string]$Baseline.Runtime -cne 'Any' -or
        [string]$Baseline.Key -cne
            'initial-adoption/bootstrap/prepared-seeds' -or
        [string]$Baseline.Builder -cne
            'capabilities-bootstrap-adapter.prepared-seeds.v1' -or
        [string]$Baseline.Scope -cne 'SuiteProcess' -or
        [string]$Baseline.InputDigest -cnotmatch '^sha256:[0-9a-f]{64}$') {
        throw 'TEST-0158 bootstrap prepared seeds do not have one canonical SuiteProcess owner.'
    }
    if ([int]$Baseline.PreparedConsumerCheckoutCount -ne 1 -or
        [int]$Baseline.PreparedProtocolCheckoutCount -ne 1 -or
        [int]$Baseline.PreparedBareRemoteCount -ne 1) {
        throw 'TEST-0158 bootstrap prepared consumer, protocol, and bare-remote owners must each build exactly once.'
    }
    $preparedPaths = @(
        [string]$Baseline.PreparedConsumer,
        [string]$Baseline.PreparedProtocol,
        [string]$Baseline.PreparedBareRemote
    )
    if (@($preparedPaths | Sort-Object -Unique).Count -ne 3 -or
        @($preparedPaths | Where-Object {
            -not (Test-Path -LiteralPath $_ -PathType Container)
        }).Count -gt 0 -or
        [int]$script:BootstrapFixtureOperations.PreparedOwnerBuilds -ne 1 -or
        [int]$script:BootstrapFixtureOperations.PreparedConsumerCheckouts -ne 1 -or
        [int]$script:BootstrapFixtureOperations.PreparedProtocolCheckouts -ne 1 -or
        [int]$script:BootstrapFixtureOperations.PreparedBareRemotes -ne 1) {
        throw 'TEST-0158 bootstrap prepared resource identities are ambiguous or were rebuilt.'
    }
    Assert-BootstrapFingerprintModeSensitivity
}

function Assert-BootstrapFixtureOperationClosure {
    $operations = $script:BootstrapFixtureOperations
    if ([int]$operations.PreparedOwnerBuilds -ne 1 -or
        [int]$operations.PreparedOwnerReuses -ne 36 -or
        [int]$operations.FixtureInit -ne 3 -or
        [int]$operations.FixtureClone -ne 2 -or
        [int]$operations.FixtureBundleCreate -ne 2 -or
        [int]$operations.FixturePublicationPush -ne 36 -or
        [int]$operations.GraphChildProcess -ne 4 -or
        [int]$operations.GraphIsolatedAcquisition -ne 3 -or
        [int]$operations.MutableDerivatives -ne 36) {
        throw ("TEST-0158 bootstrap operation closure was not " +
            "init=3, clone=2, bundle-create=2, publication-push=36, " +
            "graph-child-process=4, graph-isolated-acquisition=3, " +
            "derivatives=36, owner-build=1/reuse=36. Observed " +
            "init=$($operations.FixtureInit), " +
            "clone=$($operations.FixtureClone), " +
            "bundle-create=$($operations.FixtureBundleCreate), " +
            "publication-push=$($operations.FixturePublicationPush), " +
            "graph-child-process=$($operations.GraphChildProcess), " +
            "graph-isolated-acquisition=$($operations.GraphIsolatedAcquisition), " +
            "derivatives=$($operations.MutableDerivatives), " +
            "owner-build=$($operations.PreparedOwnerBuilds), " +
            "reuse=$($operations.PreparedOwnerReuses).")
    }
    $roots = @($script:BootstrapDerivativeRoots)
    if ($roots.Count -ne 36 -or
        @($roots | Sort-Object -Unique).Count -ne 36 -or
        @($roots | Where-Object {
            [IO.Path]::GetFullPath($_) -ceq
                [IO.Path]::GetFullPath(
                    [string]$script:BootstrapImmutableBaseline.Root
                )
        }).Count -gt 0) {
        throw 'TEST-0158 bootstrap mutable derivative roots were not fresh and distinct.'
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

    if ($null -eq $script:BootstrapImmutableBaseline) {
        throw 'The capability-local immutable fixture baseline is unavailable.'
    }
    Assert-ImmutableBootstrapBaseline -Baseline $script:BootstrapImmutableBaseline
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-capabilities-$Name-$([guid]::NewGuid().ToString('N'))"
    $tempRoots.Add($tempRoot)
    $consumer = Join-Path $tempRoot 'consumer'
    $remote = Join-Path $tempRoot 'remote.git'
    $source = Join-Path $consumer '.meandai-update-source'
    New-Item -ItemType Directory -Force $tempRoot | Out-Null

    $script:BootstrapFixtureOperations.PreparedOwnerReuses++
    $script:BootstrapFixtureOperations.MutableDerivatives++
    $script:BootstrapDerivativeRoots.Add([IO.Path]::GetFullPath($tempRoot))
    Copy-BootstrapFixtureTree `
        -Source ([string]$script:BootstrapImmutableBaseline.PreparedConsumer) `
        -Destination $consumer
    Copy-BootstrapFixtureTree `
        -Source ([string]$script:BootstrapImmutableBaseline.PreparedBareRemote) `
        -Destination $remote
    if (-not (Test-Path -LiteralPath (Join-Path $consumer '.git') `
            -PathType Container)) {
        throw 'TEST-0158 bootstrap mutable derivative lost consumer-checkout semantics.'
    }
    Invoke-Git -Repository $consumer -Arguments @(
        'remote', 'set-url', 'origin', $remote
    ) | Out-Null
    $derivativeOrigin = (@(Invoke-Git -Repository $consumer -Arguments @(
        'remote', 'get-url', 'origin'
    )))[0]
    if ([IO.Path]::GetFullPath([string]$derivativeOrigin) -cne
            [IO.Path]::GetFullPath($remote) -or
        @(Invoke-Git -Repository $remote -Arguments @(
            'for-each-ref', '--format=%(refname)'
        )).Count -ne 0) {
        throw 'TEST-0158 bootstrap derivative origin is not its fresh empty remote.'
    }
    $consumerMutated = $AddApplicationFile -or $AddAgentsCollision -or
        $AddClaudeCollision -or $LegacyRuleSurface -cne 'None' -or
        @($NestedProtocolSurfaces).Count -gt 0 -or
        $AddAgentsCaseVariantCollision -or $AddIdeasCollision -or
        $AddPullRequestTemplateCollision -or $AddManifestCollision -or
        $AddRenameSource -or $DriftSeedWorkflow -or
        $AddSeedWorkflowCaseVariant -or $AddProtocolTargetCaseVariant -or
        $AddReservedProtocolSubmoduleCollision -or
        $ReservedProtocolSubmoduleCollision -cne 'None' -or
        $AddLinkedManagedAncestor

    $workflowRelativePath = if ($AddSeedWorkflowCaseVariant) {
        '.github/workflows/MeAndAI-protocol-update.yml'
    }
    else { '.github/workflows/meandai-protocol-update.yml' }
    $workflowTarget = Join-Path $consumer $workflowRelativePath
    if ($AddSeedWorkflowCaseVariant) {
        Invoke-Git -Repository $consumer -Arguments @(
            'rm', '--cached', '--',
            '.github/workflows/meandai-protocol-update.yml'
        ) | Out-Null
        Remove-Item -LiteralPath (Join-Path $consumer `
            '.github/workflows/meandai-protocol-update.yml') -Force
    }
    if ($DriftSeedWorkflow) {
        [IO.File]::WriteAllText($workflowTarget, "name: drifted`n")
    }
    elseif ($AddSeedWorkflowCaseVariant) {
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
        New-MeAndAITestDirectoryLink -Path (Join-Path $consumer '.ai') `
            -Target $externalManaged
    }
    if ($consumerMutated) {
        Invoke-Git -Repository $consumer -Arguments @('add', '.') | Out-Null
    }
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
    }
    if ($consumerMutated) {
        Invoke-Git -Repository $consumer -Arguments @(
            'commit', '--amend', '--no-edit'
        ) | Out-Null
    }
    $script:BootstrapFixtureOperations.FixturePublicationPush++
    Invoke-Git -Repository $consumer -Arguments @(
        'push', '-u', 'origin', 'main'
    ) | Out-Null
    Copy-BootstrapFixtureTree `
        -Source ([string]$script:BootstrapImmutableBaseline.PreparedProtocol) `
        -Destination $source
    if (-not (Test-Path -LiteralPath (Join-Path $source '.git') `
            -PathType Container) -or
        [IO.Path]::GetFullPath($source) -cne [IO.Path]::GetFullPath(
            (Join-Path $consumer '.meandai-update-source')
        )) {
        throw 'TEST-0158 bootstrap mutable derivative lost protocol-source path semantics.'
    }

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
        [string]$SourceGraphIdentityJson = '',
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
            $bootstrapParameters = @{
                ProtocolSourcePath = '.meandai-update-source'
                TargetTag = 'v0.5.0'
                AdoptionStrategy = $AdoptionStrategy
            }
            if ($AcknowledgeProtocolRecordLoss) {
                $bootstrapParameters.AcknowledgeProtocolRecordLoss = $true
            }
            if ($SourceGraphIdentityJson) {
                $bootstrapParameters.SourceGraphIdentityJson =
                    $SourceGraphIdentityJson
            }
            & $adapterPath @bootstrapParameters
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

function Test-Schema9MarkerOmitsProtocolSurfacePaths {
    param([Parameter(Mandatory)][string]$Body)

    $markerMatches = [regex]::Matches(
        $Body,
        '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->'
    )
    if ($markerMatches.Count -ne 1) {
        return $false
    }
    try {
        $marker = $markerMatches[0].Groups['json'].Value | ConvertFrom-Json
    }
    catch {
        return $false
    }
    return [long]$marker.schema -eq 9 -and
        @($marker.PSObject.Properties.Name) -cnotcontains 'protocolSurfaces'
}

function Set-ExistingSchema9AdoptionMarker {
    param(
        [Parameter(Mandatory)][string]$Head,
        [Parameter(Mandatory)]$SourceMarker
    )

    if ([long]$SourceMarker.schema -ne 9 -or
        [string]$SourceMarker.phase -cne 'Proposed') {
        throw 'A schema-9 Proposed marker is required to construct current completion evidence.'
    }
    $marker = [ordered]@{
        schema = 9
        phase = 'Completed'
        state = [string]$SourceMarker.state
        target = [string]$SourceMarker.target
        protocolSha = [string]$SourceMarker.protocolSha
        head = $Head
        branch = [string]$SourceMarker.branch
        adoptionStrategy = [string]$SourceMarker.adoptionStrategy
        protocolRecordLossAcknowledged =
            [bool]$SourceMarker.protocolRecordLossAcknowledged
        graphBase = [string]$SourceMarker.graphBase
        graphDigest = [string]$SourceMarker.graphDigest
        graphCounts = $SourceMarker.graphCounts
        graphLimits = $SourceMarker.graphLimits
        repository = [string]$SourceMarker.repository
        actor = [string]$SourceMarker.actor
    } | ConvertTo-Json -Depth 8 -Compress
    $global:PullRequestExists = $true
    $global:ExistingPullRequestHead = $Head
    $global:ExistingPullRequestProtocolSha = [string]$SourceMarker.protocolSha
    $replacement = "<!-- meandai-capabilities-adoption:$marker -->"
    $matches = [regex]::Matches(
        [string]$global:ExistingPullRequestBody,
        '<!-- meandai-capabilities-adoption:\{[^\r\n]*\} -->'
    )
    if ($matches.Count -ne 1) {
        throw 'The current schema-9 proposal body has no single replaceable marker.'
    }
    $match = $matches[0]
    $global:ExistingPullRequestBody =
        $global:ExistingPullRequestBody.Substring(0, $match.Index) +
        $replacement + $global:ExistingPullRequestBody.Substring(
            $match.Index + $match.Length
        )
    $global:ExistingPullRequestIsDraft = $false
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
        [bool]$AddAgentsCollision = $true
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
        throw "$Strategy schema-9 proposal creation failed: $($initial.Error)"
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
        throw "$Strategy schema-9 proposal marker could not be parsed."
    }
    $proposalMarker = $proposalMarkerMatch.Groups['json'].Value |
        ConvertFrom-Json
    $proposalState = [string]$proposalMarker.state
    $expectedProposalState = if ($AddAgentsCollision -or
        @($NestedProtocolSurfaces).Count -gt 0) {
        'AdoptionReviewRequired'
    }
    else { 'BootstrapReady' }
    if ([long]$proposalMarker.schema -ne 9 -or
        [string]$proposalMarker.phase -cne 'Proposed' -or
        $proposalState -cne $expectedProposalState -or
        [string]$proposalMarker.adoptionStrategy -cne $Strategy -or
        [string]$proposalMarker.branch -cne $branch -or
        [string]$proposalMarker.graphBase -cnotmatch '^[0-9a-f]{40}$' -or
        [string]$proposalMarker.graphDigest -cnotmatch '^[0-9a-f]{64}$' -or
        $null -eq $proposalMarker.graphCounts -or
        $null -eq $proposalMarker.graphLimits) {
        throw "$Strategy proposal did not publish the expected graph-aware schema-9 $expectedProposalState state."
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

    Invoke-Git -Repository $fixture.Consumer -Arguments @(
        'switch', $branch
    ) | Out-Null
    $completion = Install-StrategyCompletionTree -Fixture $fixture `
        -Strategy $Strategy -LegacyRuleSurfacePath $legacyRuleSurfacePath `
        -NestedProtocolSurfacePaths @($NestedProtocolSurfaces) `
        -HasAgentsCollision $AddAgentsCollision
    if ([string]$completion.ProtocolSha -cne
        [string]$proposalMarker.protocolSha) {
        throw "$Strategy completion changed the proposal's protocol identity."
    }
    $completedBody = Set-ExistingSchema9AdoptionMarker `
        -Head ([string]$completion.Head) -SourceMarker $proposalMarker
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
        Add-Failure "TEST-0128 valid schema-9 $Strategy Completed proposal was not retained: $($completed.Error)"
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

try {
    $script:BootstrapImmutableBaseline = New-ImmutableBootstrapBaseline
    Assert-BootstrapPreparedSeedContract `
        -Baseline $script:BootstrapImmutableBaseline
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

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $graphBound = New-BootstrapFixture -Name 'graph-bound-dispatch' `
        -AddAgentsCollision $true
    Invoke-Git -Repository $graphBound.Consumer -Arguments @(
        'rm', '--', '.github/workflows/meandai-protocol-update.yml'
    ) | Out-Null
    Invoke-Git -Repository $graphBound.Consumer -Arguments @(
        'commit', '-m', 'Prepare launcher-assessed graph base'
    ) | Out-Null
    $graphAssessedBase = (@(Invoke-Git -Repository $graphBound.Consumer `
        -Arguments @('rev-parse', 'HEAD')))[0]
    $graphWorkflowTarget = Join-Path $graphBound.Consumer `
        '.github/workflows/meandai-protocol-update.yml'
    New-Item -ItemType Directory -Path (Split-Path -Parent $graphWorkflowTarget) `
        -Force | Out-Null
    Copy-Item -LiteralPath $workflowPath -Destination $graphWorkflowTarget
    Invoke-Git -Repository $graphBound.Consumer -Arguments @(
        'add', '--', '.github/workflows/meandai-protocol-update.yml'
    ) | Out-Null
    Invoke-Git -Repository $graphBound.Consumer -Arguments @(
        'commit', '-m', 'Publish exact launcher workflow seed'
    ) | Out-Null
    $graphEventHead = (@(Invoke-Git -Repository $graphBound.Consumer `
        -Arguments @('rev-parse', 'HEAD')))[0]
    Invoke-Git -Repository $graphBound.Consumer -Arguments @(
        'push', 'origin', 'main'
    ) | Out-Null
    $graphIdentity = Get-FixtureInstructionGraphIdentity `
        -Repository $graphBound.Consumer -Commit $graphAssessedBase
    $graphIdentityJson = $graphIdentity | ConvertTo-Json -Depth 30 -Compress
    $graphStatusBaseline = @(Invoke-Git `
        -Repository $graphBound.Consumer -Arguments @(
            'status', '--porcelain=v1', '--untracked-files=all'
        ))

    $result = Invoke-IsolatedGraphSuccessFixture -Fixture $graphBound `
        -SourceGraphIdentityJson $graphIdentityJson
    if ($result.Threw) {
        Add-Failure "TEST-0153 hosted adapter rejected the exact launcher-authorized source graph: $($result.Error)"
    }
    else {
        Invoke-Git -Repository $graphBound.Consumer -Arguments @(
            'fetch', 'origin',
            'automation/meandai-capabilities-v0.5.0'
        ) | Out-Null
        $graphManifest = (Invoke-Git -Repository $graphBound.Consumer `
            -Arguments @(
                'show',
                'FETCH_HEAD:.ai/adoption/meandai-capabilities.json'
            )) -join "`n" | ConvertFrom-Json
        $graphChangedPaths = @(Invoke-Git `
            -Repository $graphBound.Consumer -Arguments @(
                'diff', '--name-only', 'main...FETCH_HEAD'
            ))
        $graphMarkerMatch = [regex]::Match(
            [string]$result.PullRequestBody,
            '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->'
        )
        $graphMarker = if ($graphMarkerMatch.Success) {
            $graphMarkerMatch.Groups['json'].Value | ConvertFrom-Json
        }
        else { $null }
        if ([long]$graphManifest.schema -ne 3 -or
            [string]$graphManifest.sourceGraph.baseHead -cne
                $graphAssessedBase -or
            [string]$graphManifest.sourceGraph.digest -cne
                [string]$graphIdentity.graphDigest -or
            $graphChangedPaths.Count -ne 1 -or
            [string]$graphChangedPaths[0] -cne
                '.ai/adoption/meandai-capabilities.json' -or
            $null -eq $graphMarker -or [long]$graphMarker.schema -ne 9 -or
            [string]$graphMarker.graphBase -cne $graphAssessedBase -or
            [string]$graphMarker.graphDigest -cne
                [string]$graphIdentity.graphDigest) {
            Add-Failure 'TEST-0153 exact hosted-adapter proposal did not preserve the independently rebuilt parent-base graph in its schema-3 manifest and path-free schema-9 marker.'
        }
        Invoke-Git -Repository $graphBound.Consumer -Arguments @(
            'push', 'origin', '--delete',
            'automation/meandai-capabilities-v0.5.0'
        ) | Out-Null
    }
    Invoke-Git -Repository $graphBound.Consumer -Arguments @(
        'switch', 'main'
    ) | Out-Null
    $graphRestoredHead = (@(Invoke-Git -Repository $graphBound.Consumer `
        -Arguments @('rev-parse', 'HEAD')))[0]
    if ($graphRestoredHead -cne $graphEventHead) {
        Add-Failure 'TEST-0153 exact hosted-adapter success did not restore the fixture to the workflow event head.'
        Invoke-Git -Repository $graphBound.Consumer -Arguments @(
            'switch', '-C', 'main', $graphEventHead
        ) | Out-Null
    }
    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true

    $graphIdentityDrifts = [ordered]@{}
    $graphBaseDrift = $graphIdentityJson | ConvertFrom-Json
    $graphBaseDrift.graphBase = ('f' * 40)
    $graphIdentityDrifts['base drift'] = $graphBaseDrift
    $graphDigestDrift = $graphIdentityJson | ConvertFrom-Json
    $graphDigestDrift.graphDigest = ('f' * 64)
    $graphIdentityDrifts['digest drift'] = $graphDigestDrift

    foreach ($entry in $graphIdentityDrifts.GetEnumerator()) {
        $global:PullRequestExists = $false
        $global:PullRequestCreateCalls = 0
        $global:ExistingPullRequestBody = ''
        $headBeforeGraphDrift = (@(Invoke-Git `
            -Repository $graphBound.Consumer -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $result = Invoke-IsolatedGraphDriftFixture -Fixture $graphBound `
            -SourceGraphIdentityJson ($entry.Value |
                ConvertTo-Json -Depth 30 -Compress)
        $headAfterGraphDrift = (@(Invoke-Git `
            -Repository $graphBound.Consumer -Arguments @(
                'rev-parse', 'HEAD'
            )))[0]
        $statusAfterGraphDrift = @(Invoke-Git `
            -Repository $graphBound.Consumer -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            ))
        $unexpectedGraphBranch = @(Invoke-Git `
            -Repository $graphBound.Consumer -Arguments @(
                'ls-remote', '--heads', 'origin',
                'refs/heads/automation/meandai-capabilities-v0.5.0'
            ))
        $expectedGraphDriftError = if ([string]$entry.Key -ceq
            'base drift') {
            '*workflow event is not one exact child*'
        }
        else {
            '*independently rebuilt instruction graph does not match*'
        }
        if (-not $result.Threw -or
            $result.Error -notlike $expectedGraphDriftError -or
            $global:PullRequestCreateCalls -ne 0 -or
            $unexpectedGraphBranch.Count -ne 0 -or
            $headBeforeGraphDrift -cne $graphEventHead -or
            $headAfterGraphDrift -cne $graphEventHead -or
            ($statusAfterGraphDrift -join "`n") -cne
                ($graphStatusBaseline -join "`n")) {
            Add-Failure "TEST-0153 hosted adapter accepted $($entry.Key) or mutated proposal state before rejecting it: $($result.Error)"
        }
    }
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0153'

    $global:PullRequestExists = $false
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true

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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0077'

    foreach ($autoRuleCase in @(
        [pscustomobject]@{
            Name = 'exact-cursor-rule-root-auto'
            Surface = 'CursorRootGitlink'
            Label = '.cursor/rules gitlink'
            Path = '.cursor/rules'
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

    $fullMigrationClosureControl = $null
    foreach ($strategy in @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )) {
        try {
            $completedStrategyFixture = New-CompletedStrategyFixture `
                -Strategy $strategy
            if ($strategy -ceq 'FullMigration') {
                $fullMigrationClosureControl = $completedStrategyFixture
            }
        }
        catch {
            Add-Failure "TEST-0128/TEST-0129 current schema-9 $strategy Completed fixture could not be constructed: $($_.Exception.Message)"
        }
    }
    if ($null -eq $fullMigrationClosureControl) {
        Add-Failure 'TEST-0154 hosted completion has no positive current-envelope retirement control.'
    }

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $global:ExistingPullRequestBody = ''
    $global:ExistingPullRequestIsDraft = $true
    $partialClosure = New-BootstrapFixture `
        -Name 'completed-partial-instruction-closure' `
        -AddApplicationFile $true -AddAgentsCollision $true `
        -AddClaudeCollision $true
    $partialAuthorityPaths = @(
        'docs/AI_MEMORY.md',
        'docs/DEVELOPMENT_PROTOCOL.md',
        'docs/PROJECT_TRACKER.md',
        'docs/TEST_CATALOG.md'
    )
    [IO.File]::WriteAllText(
        (Join-Path $partialClosure.Consumer 'AGENTS.md'),
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
    foreach ($partialAuthorityPath in $partialAuthorityPaths) {
        $partialAuthorityTarget = Join-Path `
            $partialClosure.Consumer $partialAuthorityPath
        New-Item -ItemType Directory -Path (
            Split-Path -Parent $partialAuthorityTarget
        ) -Force | Out-Null
        [IO.File]::WriteAllText(
            $partialAuthorityTarget,
            "# Active consumer authority: $partialAuthorityPath`n",
            [Text.UTF8Encoding]::new($false)
        )
    }
    Invoke-Git -Repository $partialClosure.Consumer `
        -Arguments (@('add', '--', 'AGENTS.md') + $partialAuthorityPaths) |
        Out-Null
    Invoke-Git -Repository $partialClosure.Consumer -Arguments @(
        'commit', '-m', 'Create custom instruction closure fixture'
    ) | Out-Null
    Invoke-Git -Repository $partialClosure.Consumer `
        -Arguments @('push', 'origin', 'main') | Out-Null
    $partialInitial = Invoke-BootstrapFixture -Fixture $partialClosure `
        -AdoptionStrategy 'FullMigration'
    if ($partialInitial.Threw) {
        Add-Failure "TEST-0154 hosted partial-completion proposal could not be created: $($partialInitial.Error)"
    }
    else {
        $partialMarkerMatch = [regex]::Match(
            [string]$global:ExistingPullRequestBody,
            '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->'
        )
        $partialProposedMarker = if ($partialMarkerMatch.Success) {
            $partialMarkerMatch.Groups['json'].Value | ConvertFrom-Json
        }
        else { $null }
        $partialBranch = 'automation/meandai-capabilities-v0.5.0'
        if ($null -eq $partialProposedMarker -or
            [long]$partialProposedMarker.schema -ne 9 -or
            [string]$partialProposedMarker.phase -cne 'Proposed') {
            Add-Failure 'TEST-0154 hosted partial-completion proposal did not publish one graph-aware path-free schema-9 marker.'
        }
        else {
            Invoke-Git -Repository $partialClosure.Consumer `
                -Arguments @('switch', $partialBranch) | Out-Null
            $partialCompletion = Install-StrategyCompletionTree `
                -Fixture $partialClosure -Strategy 'FullMigration' `
                -HasAgentsCollision $true
            $partialCompletedBody = Set-ExistingSchema9AdoptionMarker `
                -Head ([string]$partialCompletion.Head) `
                -SourceMarker $partialProposedMarker
            Invoke-Git -Repository $partialClosure.Consumer `
                -Arguments @('switch', 'main') | Out-Null
            $partialMainHead = (@(Invoke-Git `
                -Repository $partialClosure.Consumer `
                -Arguments @('rev-parse', 'HEAD')))[0]
            $partialRemoteHeadBefore = (@(Invoke-Git `
                -Repository $partialClosure.Consumer -Arguments @(
                    'ls-remote', '--heads', 'origin',
                    "refs/heads/$partialBranch"
                )))[0]
            $partialCreateCallsBefore = $global:PullRequestCreateCalls
            $partialResult = Invoke-BootstrapFixture `
                -Fixture $partialClosure -AdoptionStrategy 'FullMigration'
            $partialRemoteHeadAfter = (@(Invoke-Git `
                -Repository $partialClosure.Consumer -Arguments @(
                    'ls-remote', '--heads', 'origin',
                    "refs/heads/$partialBranch"
                )))[0]
            $partialMainHeadAfter = (@(Invoke-Git `
                -Repository $partialClosure.Consumer `
                -Arguments @('rev-parse', 'HEAD')))[0]
            $expectedPartialError =
                'MEANDAI_ADOPTION_BLOCKED: unresolved instruction authority: ' +
                ($partialAuthorityPaths -join ', ')
            if (-not $partialResult.Threw -or
                $partialResult.Error -cne $expectedPartialError -or
                $global:PullRequestCreateCalls -ne
                    $partialCreateCallsBefore -or
                [string]$global:ExistingPullRequestBody -cne
                    $partialCompletedBody -or
                $partialRemoteHeadAfter -cne $partialRemoteHeadBefore -or
                $partialMainHeadAfter -cne $partialMainHead) {
                Add-Failure "TEST-0154 actual hosted Completed validation did not block the exact four live custom authorities before proposal or branch mutation: $($partialResult.Error)"
            }
        }
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
    $missingMigrationIdentity = $missingMigrationModule
    Copy-Item -LiteralPath $consumerMigrationModulePath -Destination (
        Join-Path $missingMigrationIdentity.Source `
            'scripts/MeAndAI.ConsumerMigrations.psm1'
    ) -Force
    Invoke-Git -Repository $missingMigrationIdentity.Source -Arguments @(
        'add', '--', 'scripts/MeAndAI.ConsumerMigrations.psm1'
    ) | Out-Null
    Invoke-Git -Repository $missingMigrationIdentity.Source -Arguments @(
        'rm', '--', 'scripts/MeAndAI.ContentIdentity.psm1'
    ) | Out-Null
    Invoke-Git -Repository $missingMigrationIdentity.Source -Arguments @(
        'commit', '-m', 'Remove consumer migration identity dependency'
    ) | Out-Null
    Invoke-Git -Repository $missingMigrationIdentity.Source -Arguments @(
        'tag', '-f', 'v0.5.0'
    ) | Out-Null
    $result = Invoke-BootstrapFixture -Fixture $missingMigrationIdentity
    $unexpectedMigrationIdentityBranch = @(Invoke-Git `
        -Repository $missingMigrationIdentity.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin',
            'refs/heads/automation/meandai-capabilities-v0.5.0'
        ))
    if (-not $result.Threw -or
        $result.Error -notlike '*missing consumer migration identity dependency*' -or
        $global:PullRequestCreateCalls -ne 0 -or
        $unexpectedMigrationIdentityBranch.Count -ne 0) {
        Add-Failure "TEST-0028 full adoption did not fail closed on a missing migration identity dependency: $($result.Error)"
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
    $freshProposedMarker = $null
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
        $freshMarkerMatch = [regex]::Match(
            [string]$global:LastPullRequestBody,
            '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->'
        )
        if ($freshMarkerMatch.Success) {
            $freshProposedMarker =
                $freshMarkerMatch.Groups['json'].Value | ConvertFrom-Json
        }
        $manifestGraphCounts = $manifest.sourceGraph.counts |
            ConvertTo-Json -Depth 8 -Compress
        $markerGraphCounts = $freshProposedMarker.graphCounts |
            ConvertTo-Json -Depth 8 -Compress
        $manifestGraphLimits = $manifest.sourceGraph.limits |
            ConvertTo-Json -Depth 8 -Compress
        $markerGraphLimits = $freshProposedMarker.graphLimits |
            ConvertTo-Json -Depth 8 -Compress
        if ([long]$manifest.schema -ne 3 -or
            [string]$manifest.adoptionStrategy -cne 'FreshAdoption' -or
            $manifest.protocolRecordLossAcknowledged -isnot [bool] -or
            [bool]$manifest.protocolRecordLossAcknowledged -or
            @($manifest.protocolSurfaces).Count -ne 0 -or
            $null -eq $manifest.sourceGraph -or
            $null -eq $freshProposedMarker -or
            [long]$freshProposedMarker.schema -ne 9 -or
            [string]$freshProposedMarker.phase -cne 'Proposed' -or
            [string]$freshProposedMarker.branch -cne
                'automation/meandai-capabilities-v0.5.0' -or
            [string]$manifest.sourceGraph.baseHead -cne
                [string]$freshProposedMarker.graphBase -or
            [string]$manifest.sourceGraph.digest -cne
                [string]$freshProposedMarker.graphDigest -or
            [string]$manifestGraphCounts -cne [string]$markerGraphCounts -or
            [string]$manifestGraphLimits -cne [string]$markerGraphLimits) {
            Add-Failure 'TEST-0128 fresh proposal did not bind the exact strategy and source graph through its schema-3 manifest and path-free schema-9 marker.'
        }
        if ($global:PullRequestCreateCalls -ne 1 -or
            -not $global:LastPullRequestBody.Contains('BootstrapReady') -or
            -not $global:LastPullRequestBody.Contains('"schema":9') -or
            -not (Test-Schema9MarkerOmitsProtocolSurfacePaths `
                -Body $global:LastPullRequestBody) -or
            -not $global:LastPullRequestBody.Contains('"phase":"Proposed"') -or
            -not $global:LastPullRequestBody.Contains('"adoptionStrategy":"FreshAdoption"') -or
            -not $global:LastPullRequestBody.Contains('"actor":"owner"') -or
            $global:LastPullRequestHead -cne 'automation/meandai-capabilities-v0.5.0') {
            Add-Failure 'TEST-0028 bootstrap did not create the deterministic draft proposal.'
        }
        $freshBaseHead = (@(Invoke-Git -Repository $empty.Consumer `
            -Arguments @('rev-parse', 'main')))[0]
        $expectedManifestLink =
            "[``.ai/adoption/meandai-capabilities.json``](https://github.com/owner/consumer/blob/$($global:ExistingPullRequestHead)/.ai/adoption/meandai-capabilities.json)"
        if (-not $global:LastPullRequestBody.Contains($expectedManifestLink) -or
            -not $global:LastPullRequestBody.Contains(
                "[${freshBaseHead}](https://github.com/owner/consumer/commit/$freshBaseHead)"
            )) {
            Add-Failure 'TEST-0176 fresh hosted proposal did not link its source commit and transient manifest to exact immutable targets.'
        }
    }
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0028'
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0093'

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
        if ($completedProtocolSha -cne
            [string]$freshProposedMarker.protocolSha) {
            throw 'Fresh completion changed the proposal protocol identity.'
        }
        $completedBody = Set-ExistingSchema9AdoptionMarker `
            -Head $completedHead -SourceMarker $freshProposedMarker
        $createCallsBeforeCompletedRerun = $global:PullRequestCreateCalls
        Invoke-Git -Repository $empty.Consumer -Arguments @('switch', 'main') | Out-Null
        $result = Invoke-BootstrapFixture -Fixture $empty
        $retainedHead = (@(Invoke-Git -Repository $empty.Consumer -Arguments @(
            'ls-remote', '--heads', 'origin', "refs/heads/$completedBranch"
        )))[0]
        if ($result.Threw -or
            $global:PullRequestCreateCalls -ne $createCallsBeforeCompletedRerun -or
            $retainedHead -cnotmatch "^$completedHead\s+refs/heads/$([regex]::Escape($completedBranch))$" -or
            [string]$global:ExistingPullRequestBody -cne $completedBody) {
            Add-Failure "TEST-0071 exact completed non-draft proposal was not retained without mutation: $($result.Error)"
        }
        Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0071'

        if (-not $result.Threw) {
            $canonicalCompletedBody = [string]$global:ExistingPullRequestBody
            foreach ($completedVariant in @(
                'Parent', 'ProposalTree', 'CheckedChangeSet', 'Protocol',
                'UpdaterModule', 'UpdaterAdapter', 'ApplicationType',
                'Gitmodules', 'CredentialNested'
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
                [void](Set-ExistingSchema9AdoptionMarker `
                    -Head $variantHead -SourceMarker $freshProposedMarker)
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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0094'

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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0029'

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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0127'

    $global:PullRequestExists = $false
    $global:PullRequestCreateCalls = 0
    $collision = New-BootstrapFixture -Name 'collision' -AddAgentsCollision $true
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
        $collisionBaseHead = (@(Invoke-Git `
            -Repository $collision.Consumer -Arguments @(
                'rev-parse', 'main'
            )))[0]
        $expectedCollisionLink =
            "[``AGENTS.md``](https://github.com/owner/consumer/blob/$collisionBaseHead/AGENTS.md)"
        if (-not $global:LastPullRequestBody.Contains(
                $expectedCollisionLink
            ) -or
            -not (Test-Schema9MarkerOmitsProtocolSurfacePaths `
                -Body $global:LastPullRequestBody)) {
            Add-Failure 'TEST-0176 hosted collision proposal did not expose its surface and collision as exact immutable blob links outside the marker.'
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
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss
    if ($result.Threw -or $global:PullRequestCreateCalls -ne 1 -or
        -not $global:LastPullRequestBody.Contains('"adoptionStrategy":"CleanStart"') -or
        -not (Test-Schema9MarkerOmitsProtocolSurfacePaths `
            -Body $global:LastPullRequestBody) -or
        -not $global:LastPullRequestBody.Contains(
            '[`AGENTS.md`](https://github.com/owner/consumer/blob/'
        ) -or
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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0030'
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0095'

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

    $pendingProposalHead = [string]$global:ExistingPullRequestHead
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
        'push',
        "--force-with-lease=refs/heads/automation/meandai-capabilities-v0.5.0:$pendingProposalHead",
        'origin',
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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0057'
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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0128'
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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0062'

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
    Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0031'
}
finally {
    Remove-Item Function:\gh -ErrorAction SilentlyContinue
    if ($null -ne $script:BootstrapImmutableBaseline) {
        try {
            Assert-ImmutableBootstrapBaseline `
                -Baseline $script:BootstrapImmutableBaseline -Complete
        }
        catch {
            Add-Failure $_.Exception.Message
        }
        try {
            Assert-BootstrapPreparedSeedContract `
                -Baseline $script:BootstrapImmutableBaseline
            Assert-BootstrapFixtureOperationClosure
        }
        catch {
            Add-Failure $_.Exception.Message
        }
    }
    foreach ($path in $tempRoots) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $survivingBootstrapRoots = @($tempRoots | Where-Object {
        Test-Path -LiteralPath $_
    })
    if ($survivingBootstrapRoots.Count -ne 0) {
        Add-Failure ("TEST-0158 bootstrap fixture cleanup leaked roots: " +
            ($survivingBootstrapRoots -join ', '))
    }
    if (-not (Test-Path -LiteralPath $cleanupSentinel -PathType Container)) {
        Add-Failure 'TEST-0068 cleanup removed an unowned same-prefix temporary directory.'
    }
    elseif (Test-Path -LiteralPath $cleanupSentinel) {
        Remove-Item -LiteralPath $cleanupSentinel -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $cleanupSentinel) {
            Add-Failure 'TEST-0158 bootstrap cleanup sentinel could not be removed.'
        }
    }
}
Confirm-MeAndAICaseEvidence -Context $caseContext -TestId 'TEST-0068'

if ($failures.Count -gt 0) {
    Write-Host "AI capabilities bootstrap adapter tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$operationActuals =
    [System.Collections.Generic.Dictionary[string,long]]::new(
        [StringComparer]::Ordinal
    )
$operationActuals.Add('graph.acquisition',
    [long]$script:BootstrapFixtureOperations.GraphIsolatedAcquisition)
$operationActuals.Add('process.child',
    [long]$script:BootstrapFixtureOperations.GraphChildProcess)
$operationActuals.Add('reusable-fixture-family.bundle',
    [long]$script:BootstrapFixtureOperations.FixtureBundleCreate)
$operationActuals.Add('reusable-fixture-family.clone',
    [long]$script:BootstrapFixtureOperations.FixtureClone)
$operationActuals.Add('reusable-fixture-family.init',
    [long]$script:BootstrapFixtureOperations.FixtureInit)
$operationActuals.Add('reusable-fixture-family.push',
    [long]$script:BootstrapFixtureOperations.FixturePublicationPush)
if (@($operationExpectation.Counters).Count -ne $operationActuals.Count) {
    throw 'Bootstrap operation contract does not match the owner counters.'
}
$operationCounters = @($operationExpectation.Counters | ForEach-Object {
    if (-not $operationActuals.ContainsKey([string]$_.Name)) {
        throw "Bootstrap operation contract contains unknown counter '$($_.Name)'."
    }
    [ordered]@{
        name = [string]$_.Name
        actual = [long]$operationActuals[[string]$_.Name]
        maximum = [long]$_.Maximum
    }
})
$operationLine = Format-MeAndAITestOperationObservation `
    -Owner $operationExpectation.Owner -Route $operationExpectation.Route `
    -Runtime $operationExpectation.Runtime -Counters $operationCounters
Write-Host 'AI capabilities bootstrap adapter tests passed for all declared scenarios in this suite.' -ForegroundColor Green
Write-Host $operationLine
$caseResult = New-MeAndAICaseResult -Context $caseContext
Write-Host ('MEANDAI_CASE_RESULTS=' +
    ($caseResult | ConvertTo-Json -Compress))
