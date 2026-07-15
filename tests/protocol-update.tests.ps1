[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$modulePath = Join-Path $root 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
$failures = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    Write-Host 'Protocol update tests failed:' -ForegroundColor Red
    Write-Host ' - TEST-0009 missing pure update resolver module.' -ForegroundColor Red
    exit 1
}

Import-Module $modulePath -Force

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        Add-Failure "$Message; expected '$Expected', found '$Actual'"
    }
}

function New-Candidate {
    param(
        [int]$Number,
        [string]$TargetTag,
        [string]$MarkerHeadSha = ('a' * 40),
        [string]$ApiHeadSha = '',
        [string]$ObservedHeadSha = '',
        [bool]$SameRepository = $true,
        [string]$AuthorLogin = 'updater-owner',
        [string[]]$ChangedPaths = @('.ai/protocol'),
        [string[]]$ExpectedChangedPaths = $null,
        [bool]$ManagedAssetEntriesMatchTarget = $true,
        [int]$MarkerSchema = 1,
        [bool]$BranchExists = $true,
        [string]$ProtocolSha = ('2' * 40),
        [string]$ProtocolEntryMode = '160000',
        [string]$ProtocolEntrySha = '',
        [string]$BaseRef = 'main',
        [bool]$Draft = $true
    )

    if (-not $ApiHeadSha) {
        $ApiHeadSha = $MarkerHeadSha
    }
    if (-not $ObservedHeadSha) {
        $ObservedHeadSha = $MarkerHeadSha
    }
    if (-not $ProtocolEntrySha) {
        $ProtocolEntrySha = $ProtocolSha
    }
    if ($null -eq $ExpectedChangedPaths) {
        $ExpectedChangedPaths = @($ChangedPaths)
    }

    [pscustomobject]@{
        PullRequestNumber = $Number
        PullRequestState = 'Open'
        TargetTag = $TargetTag
        HeadRef = "automation/meandai-protocol-$TargetTag"
        BranchExists = $BranchExists
        ExpectedHeadSha = $MarkerHeadSha
        ApiHeadSha = $ApiHeadSha
        ObservedHeadSha = $ObservedHeadSha
        MarkerSchema = $MarkerSchema
        MarkerTargetTag = $TargetTag
        MarkerProtocolSha = $ProtocolSha
        MarkerHeadSha = $MarkerHeadSha
        MarkerRepository = 'owner/consumer'
        ExpectedProtocolSha = $ProtocolSha
        ProtocolEntryMode = $ProtocolEntryMode
        ProtocolEntrySha = $ProtocolEntrySha
        BaseRef = $BaseRef
        Draft = $Draft
        SameRepository = $SameRepository
        AuthorLogin = $AuthorLogin
        ChangedPaths = @($ChangedPaths)
        ExpectedChangedPaths = @($ExpectedChangedPaths)
        ManagedAssetEntriesMatchTarget = $ManagedAssetEntriesMatchTarget
    }
}

function Invoke-Plan {
    param(
        [string]$CurrentTag,
        [string[]]$AvailableTags,
        [object[]]$Candidates = @()
    )

    $snapshot = [pscustomobject]@{
        SchemaVersion = 1
        CurrentTag = $CurrentTag
        AvailableTags = @($AvailableTags)
        Repository = 'owner/consumer'
        DefaultBranch = 'main'
        BranchPrefix = 'automation/meandai-protocol-'
        ProtocolPath = '.ai/protocol'
        ManagedPaths = @(
            '.ai/protocol',
            '.github/workflows/meandai-protocol-update.yml',
            '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        )
        TrustedActor = 'updater-owner'
        Candidates = @($Candidates)
    }

    Resolve-MeAndAIProtocolUpdatePlan -Snapshot $snapshot
}

$plan = Invoke-Plan -CurrentTag 'v0.9.0' -AvailableTags @(
    'v0.9.0', 'v0.10.0', 'V0.12.0', 'v0.02.0', 'v0.2', 'v0.11.0-beta.1', 'notes'
)
Assert-Equal 'OpenUpgrade' $plan.State 'TEST-0009 should open the numerically latest compatible release'
Assert-Equal 'v0.10.0' $plan.LatestCompatibleTag 'TEST-0009 numeric tag ordering is wrong'
Assert-Equal 'CreateUpgrade' $plan.Operations[0].Kind 'TEST-0009 should create an upgrade'
Assert-Equal 'v0.10.0' $plan.Operations[0].TargetTag 'TEST-0009 selected the wrong target'
Assert-Equal 5 @($plan.IgnoredTags).Count 'TEST-0009 should report case-variant, noncanonical, malformed, or prerelease tags'

$pendingLatest = New-Candidate -Number 20 -TargetTag 'v0.2.0'
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($pendingLatest)
Assert-Equal 'PendingLatest' $plan.State 'TEST-0010 should retain the existing latest PR'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0010 repeated runs must be idempotent'

$oldPending = New-Candidate -Number 21 -TargetTag 'v0.2.0'
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0', 'v0.3.0') -Candidates @($oldPending)
Assert-Equal 'Supersede' $plan.State 'TEST-0011 should supersede the older pending update'
Assert-Equal 'CreateUpgrade,ClosePullRequest,DeleteBranch' (@($plan.Operations.Kind) -join ',') 'TEST-0011 operation order must be replacement-first'
Assert-Equal 'v0.3.0' $plan.Operations[0].TargetTag 'TEST-0011 replacement target is wrong'
Assert-Equal 21 $plan.Operations[1].PullRequestNumber 'TEST-0011 should close the old PR'

$newPending = New-Candidate -Number 22 -TargetTag 'v0.3.0' -MarkerHeadSha ('b' * 40)
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0', 'v0.3.0') -Candidates @($oldPending, $newPending)
Assert-Equal 'Supersede' $plan.State 'TEST-0011 should retire only the older PR when the replacement exists'
Assert-Equal 'ClosePullRequest,DeleteBranch' (@($plan.Operations.Kind) -join ',') 'TEST-0011 must not create a duplicate latest PR'

$stale = New-Candidate -Number 23 -TargetTag 'v0.2.0'
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($stale)
Assert-Equal 'CleanupStale' $plan.State 'TEST-0012 should clean a stale open PR after merge'
Assert-Equal 'ClosePullRequest,DeleteBranch' (@($plan.Operations.Kind) -join ',') 'TEST-0012 cleanup order is wrong'

$plan = Invoke-Plan -CurrentTag '0.1.0' -AvailableTags @('v0.1.0')
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0013 malformed current tags must block'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0013 blocked plans must be mutation-free'

$duplicateA = New-Candidate -Number 24 -TargetTag 'v0.2.0'
$duplicateB = New-Candidate -Number 25 -TargetTag 'v0.2.0' -MarkerHeadSha ('c' * 40)
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($duplicateA, $duplicateB)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0014 duplicate managed targets must block'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0014 duplicate targets must not be resolved heuristically'

$humanChanged = New-Candidate -Number 26 -TargetTag 'v0.2.0' -ObservedHeadSha ('d' * 40)
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0', 'v0.3.0') -Candidates @($humanChanged)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 human branch changes must block supersession'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 blocked human work must remain untouched'

$foreignAuthor = New-Candidate -Number 27 -TargetTag 'v0.2.0' -AuthorLogin 'maintainer'
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($foreignAuthor)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 non-automation authors must block cleanup'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 non-automation branches must remain untouched'

$extraPath = New-Candidate -Number 28 -TargetTag 'v0.2.0' -ChangedPaths @('.ai/protocol', 'README.md')
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($extraPath)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 non-protocol changes must block cleanup'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 consumer changes must remain untouched'

$managedPaths = @(
    '.ai/protocol',
    '.github/workflows/meandai-protocol-update.yml',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)
$managedUpdate = New-Candidate -Number 33 -TargetTag 'v0.2.0' `
    -ChangedPaths $managedPaths -ExpectedChangedPaths $managedPaths
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -Candidates @($managedUpdate)
Assert-Equal 'PendingLatest' $plan.State 'TEST-0026 exact managed updater paths should remain idempotent'

$missingManagedPath = New-Candidate -Number 34 -TargetTag 'v0.2.0' `
    -ChangedPaths @('.ai/protocol') -ExpectedChangedPaths $managedPaths
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -Candidates @($missingManagedPath)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0026 missing expected updater paths must block cleanup'

$wrongManagedBlob = New-Candidate -Number 35 -TargetTag 'v0.2.0' `
    -ChangedPaths $managedPaths -ExpectedChangedPaths $managedPaths `
    -ManagedAssetEntriesMatchTarget $false
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -Candidates @($wrongManagedBlob)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0026 wrong updater target blobs must block cleanup'

$caseDriftedManagedPath = New-Candidate -Number 36 -TargetTag 'v0.2.0' `
    -ChangedPaths @('.ai/protocol', '.github/Workflows/meandai-protocol-update.yml') `
    -ExpectedChangedPaths @('.ai/protocol', '.github/Workflows/meandai-protocol-update.yml')
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -Candidates @($caseDriftedManagedPath)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0026 case-drifted managed paths must block cleanup'

$wrongGitlink = New-Candidate -Number 29 -TargetTag 'v0.2.0' -ProtocolEntrySha ('9' * 40)
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($wrongGitlink)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 wrong protocol gitlink SHA must block cleanup'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 wrong dependency content must remain untouched'

$wrongBase = New-Candidate -Number 30 -TargetTag 'v0.2.0' -BaseRef 'release'
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($wrongBase)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 wrong base branch must block cleanup'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 wrong-base work must remain untouched'

$readyForReview = New-Candidate -Number 31 -TargetTag 'v0.2.0' -Draft $false
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($readyForReview)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 non-draft PR must block automation cleanup'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 maintainer-touched PR must remain untouched'

$caseChangedBranch = New-Candidate -Number 32 -TargetTag 'v0.2.0'
$caseChangedBranch.HeadRef = 'Automation/meandai-protocol-v0.2.0'
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') -Candidates @($caseChangedBranch)
Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0015 case-only branch changes must block'
Assert-Equal 0 @($plan.Operations).Count 'TEST-0015 case-only branch changes must remain untouched'

$majorPlan = Invoke-Plan -CurrentTag 'v0.3.0' -AvailableTags @('v0.3.0', 'v1.0.0')
Assert-Equal 'MajorUpgradeRequired' $majorPlan.State 'TEST-0016 incompatible major releases require manual migration'
Assert-Equal 0 @($majorPlan.Operations).Count 'TEST-0016 major releases must not create an automatic PR'

$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$adoptionPath = Join-Path $root 'docs/adoption.md'
$ciPath = Join-Path $root '.github/workflows/protocol-tests.yml'
foreach ($path in @($workflowPath, $adapterPath, $adoptionPath, $ciPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "TEST-0017 missing required automation asset: $path"
    }
}

if ($failures.Count -eq 0) {
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    $resolver = Get-Content -LiteralPath $modulePath -Raw
    $adapter = Get-Content -LiteralPath $adapterPath -Raw
    $adoption = Get-Content -LiteralPath $adoptionPath -Raw

    $ci = Get-Content -LiteralPath $ciPath -Raw
    foreach ($required in @('schedule:', 'workflow_dispatch:', 'contents: read', 'concurrency:', 'cancel-in-progress: false', 'actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0', 'MEANDAI_UPDATER_TOKEN', 'token: ${{ secrets.MEANDAI_UPDATER_TOKEN }}', 'token: ${{ secrets.MEANDAI_PROTOCOL_TOKEN || github.token }}', 'persist-credentials: false', 'GH_TOKEN: ${{ secrets.MEANDAI_UPDATER_TOKEN }}', 'Invoke-MeAndAIProtocolUpdate.ps1')) {
        if (-not $workflow.Contains($required)) {
            Add-Failure "TEST-0017 workflow is missing '$required'"
        }
    }
    foreach ($forbidden in @('pull_request_target:', 'gh pr merge', 'issues: write', 'contents: write', 'pull-requests: write', 'GH_TOKEN: ${{ github.token }}', 'MEANDAI_PROTOCOL_TOKEN: gh', 'actions/checkout@v')) {
        if ($workflow.Contains($forbidden)) {
            Add-Failure "TEST-0017 workflow contains forbidden behavior '$forbidden'"
        }
    }
    foreach ($forbidden in @('Invoke-Native', 'Invoke-RestMethod', 'Invoke-WebRequest')) {
        if ($resolver.Contains($forbidden)) {
            Add-Failure "TEST-0017 pure resolver contains live-operation token '$forbidden'"
        }
    }
    foreach ($required in @('pull_request:', 'push:', 'workflow_dispatch:', 'contents: read', 'ubuntu-latest', 'windows-latest', 'shell: pwsh', './tests/protocol.tests.ps1', 'actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0')) {
        if (-not $ci.Contains($required)) {
            Add-Failure "TEST-0017 repository CI is missing '$required'"
        }
    }
    foreach ($forbidden in @('contents: write', 'actions/checkout@v')) {
        if ($ci.Contains($forbidden)) {
            Add-Failure "TEST-0017 repository CI contains forbidden behavior '$forbidden'"
        }
    }
    foreach ($required in @("'pr', 'create'", '--draft', 'meandai-protocol-update', 'ClosePullRequest', 'DeleteBranch', 'Assert-ManagedPullRequestSafe', 'Get-AuthenticatedUpdaterActor', 'Assert-CurrentManagedAssets', 'Get-ExpectedManagedPaths', 'Assert-StagedManagedUpdate', 'ManagedAssetEntriesMatchTarget', 'Get-RemoteBranchHead', 'ExpectedProtocolSha', '--paginate', '--force-with-lease=', '-isnot [long]')) {
        if (-not $adapter.Contains($required)) {
            Add-Failure "TEST-0017 adapter is missing '$required'"
        }
    }
    foreach ($required in @('templates/project/.github/workflows/meandai-protocol-update.yml', '.github/workflows/meandai-protocol-update.yml', 'MEANDAI_UPDATER_TOKEN', 'meAndAI Updater - <repo>', 'MEANDAI_PROTOCOL_TOKEN', 'v0.4.0', 'one-time', 'collision', 'submodule-only', '$defaultBranch', '$targetTag', 'git ls-tree', '160000 -> 160000')) {
        if (-not $adoption.Contains($required)) {
            Add-Failure "TEST-0017 adoption guidance is missing '$required'"
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Protocol update tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$adapterTestPath = Join-Path $root 'tests/protocol-update-adapter.tests.ps1'
if (-not (Test-Path -LiteralPath $adapterTestPath -PathType Leaf)) {
    Write-Host 'Protocol update tests failed: missing adapter integration tests.' -ForegroundColor Red
    exit 1
}
$engine = (Get-Process -Id $PID).Path
& $engine -NoProfile -ExecutionPolicy Bypass -File $adapterTestPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host 'Protocol update tests passed: TEST-0009 through TEST-0017, TEST-0021 through TEST-0026, TEST-0048, TEST-0056, and TEST-0058.' -ForegroundColor Green
