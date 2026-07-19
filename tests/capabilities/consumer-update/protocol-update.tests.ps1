[CmdletBinding()]
param([switch]$PureResolverOnly)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
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
        [string]$Kind = 'Update',
        [string]$MigrationPlanSha = '',
        [bool]$MigrationPlanValid = $true,
        [string[]]$AllowedExpectedPaths = $null,
        [string]$MigrationBranchSuffix = '-migrations',
        [int]$MarkerSchema = 1,
        [bool]$BranchExists = $true,
        [string]$ProtocolSha = ('2' * 40),
        [string]$ProtocolEntryMode = '160000',
        [string]$ProtocolEntrySha = '',
        [string]$BaseRef = 'main',
        [bool]$Draft = $true,
        [bool]$SupersedeOnly = $false,
        [bool]$UnboundIssue = $false,
        [string]$UpdateBranchSuffix = ''
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

    $kindWasSupplied = $PSBoundParameters.ContainsKey('Kind')
    $isMigration = $Kind -ceq 'MigrationReconciliation'
    if ($isMigration -and -not $MigrationPlanSha) {
        $MigrationPlanSha = '3' * 64
    }
    if ($isMigration -and $null -eq $AllowedExpectedPaths) {
        $AllowedExpectedPaths = @($ExpectedChangedPaths)
    }
    $headRef = if ($isMigration) {
        "automation/meandai-protocol-$TargetTag$MigrationBranchSuffix"
    }
    else {
        $effectiveUpdateSuffix = if ($SupersedeOnly) { '' } else { $UpdateBranchSuffix }
        "automation/meandai-protocol-$TargetTag$effectiveUpdateSuffix"
    }

    $candidate = [pscustomobject]@{
        PullRequestNumber = $Number
        PullRequestState = 'Open'
        TargetTag = $TargetTag
        HeadRef = $headRef
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
    if ($kindWasSupplied) {
        $candidate | Add-Member -NotePropertyName Kind -NotePropertyValue $Kind
    }
    if ($isMigration -or $PSBoundParameters.ContainsKey('MigrationPlanSha')) {
        $candidate | Add-Member -NotePropertyName MigrationPlanSha `
            -NotePropertyValue $MigrationPlanSha
    }
    if ($isMigration -or $PSBoundParameters.ContainsKey('MigrationPlanValid')) {
        $candidate | Add-Member -NotePropertyName MigrationPlanValid `
            -NotePropertyValue $MigrationPlanValid
    }
    if ($isMigration -or $PSBoundParameters.ContainsKey('AllowedExpectedPaths')) {
        $candidate | Add-Member -NotePropertyName AllowedExpectedPaths `
            -NotePropertyValue @($AllowedExpectedPaths)
    }
    if ($PSBoundParameters.ContainsKey('SupersedeOnly')) {
        $candidate | Add-Member -NotePropertyName SupersedeOnly `
            -NotePropertyValue $SupersedeOnly
    }
    if ($PSBoundParameters.ContainsKey('UnboundIssue')) {
        $candidate | Add-Member -NotePropertyName UnboundIssue `
            -NotePropertyValue $UnboundIssue
    }
    return $candidate
}

function Invoke-Plan {
    param(
        [string]$CurrentTag,
        [string[]]$AvailableTags,
        [object[]]$Candidates = @(),
        [bool]$MigrationRequired = $false,
        [string]$CurrentMigrationPlanSha = '',
        [string]$MigrationBranchSuffix = '-migrations',
        [string]$RequestedTargetTag = '',
        [string]$UpdateBranchSuffix = ''
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

    if ($PSBoundParameters.ContainsKey('MigrationRequired')) {
        $snapshot | Add-Member -NotePropertyName MigrationRequired `
            -NotePropertyValue $MigrationRequired
    }
    if ($PSBoundParameters.ContainsKey('CurrentMigrationPlanSha')) {
        $snapshot | Add-Member -NotePropertyName CurrentMigrationPlanSha `
            -NotePropertyValue $CurrentMigrationPlanSha
    }
    if ($PSBoundParameters.ContainsKey('MigrationBranchSuffix')) {
        $snapshot | Add-Member -NotePropertyName MigrationBranchSuffix `
            -NotePropertyValue $MigrationBranchSuffix
    }
    if ($PSBoundParameters.ContainsKey('RequestedTargetTag')) {
        $snapshot | Add-Member -NotePropertyName RequestedTargetTag `
            -NotePropertyValue $RequestedTargetTag
    }
    if ($PSBoundParameters.ContainsKey('UpdateBranchSuffix')) {
        $snapshot | Add-Member -NotePropertyName UpdateBranchSuffix `
            -NotePropertyValue $UpdateBranchSuffix
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

$targetBoundPlan = Invoke-Plan -CurrentTag 'v0.1.0' `
    -AvailableTags @('v0.1.0', 'v0.2.0', 'v0.3.0', 'v0.4.0') `
    -RequestedTargetTag 'v0.3.0' -UpdateBranchSuffix '-recovery'
Assert-Equal 'OpenUpgrade' $targetBoundPlan.State `
    'TEST-0126 an explicit current-launcher target should still create an upgrade'
Assert-Equal 'v0.3.0' $targetBoundPlan.LatestCompatibleTag `
    'TEST-0126 a release published later must not move the explicit target ceiling'
Assert-Equal 'v0.3.0' $targetBoundPlan.Operations[0].TargetTag `
    'TEST-0126 the create operation must remain bound to the requested target'
Assert-Equal 'automation/meandai-protocol-v0.3.0-recovery' `
    $targetBoundPlan.Operations[0].Branch `
    'TEST-0126 a recovery proposal must not collide with a same-target legacy branch'

foreach ($invalidRequestedTarget in @('v0.0.9', 'v0.2', 'v1.0.0', 'v0.9.9')) {
    $invalidTargetPlan = Invoke-Plan -CurrentTag 'v0.1.0' `
        -AvailableTags @('v0.1.0', 'v0.3.0', 'v1.0.0') `
        -RequestedTargetTag $invalidRequestedTarget
    Assert-Equal 'BlockedManualReview' $invalidTargetPlan.State `
        "TEST-0126 invalid, absent, cross-major, or downgrade target '$invalidRequestedTarget' must block"
    Assert-Equal 0 @($invalidTargetPlan.Operations).Count `
        "TEST-0126 blocked target '$invalidRequestedTarget' must remain mutation-free"
}

$newerOpenCandidate = New-Candidate -Number 60 -TargetTag 'v0.4.0' `
    -ProtocolSha ('4' * 40)
$newerOpenTargetPlan = Invoke-Plan -CurrentTag 'v0.1.0' `
    -AvailableTags @('v0.1.0', 'v0.3.0', 'v0.4.0') `
    -RequestedTargetTag 'v0.3.0' -Candidates @($newerOpenCandidate)
Assert-Equal 'BlockedManualReview' $newerOpenTargetPlan.State `
    'TEST-0126 a current-launcher request must not retire a valid proposal newer than its target'
Assert-Equal 0 @($newerOpenTargetPlan.Operations).Count `
    'TEST-0126 a newer open proposal must remain untouched'

$legacyLatest = New-Candidate -Number 61 -TargetTag 'v0.3.0' `
    -ProtocolSha ('3' * 40) -SupersedeOnly $true -UnboundIssue $true
$legacyLatestPlan = Invoke-Plan -CurrentTag 'v0.1.0' `
    -AvailableTags @('v0.1.0', 'v0.3.0') `
    -RequestedTargetTag 'v0.3.0' -UpdateBranchSuffix '-recovery' `
    -Candidates @($legacyLatest)
Assert-Equal 'Supersede' $legacyLatestPlan.State `
    'TEST-0126 a same-target legacy unbound draft must never satisfy the requested proposal'
Assert-Equal 'CreateUpgrade,ClosePullRequest,DeleteBranch' `
    (@($legacyLatestPlan.Operations.Kind) -join ',') `
    'TEST-0126 a legacy unbound draft must be cleaned only after replacement creation'
Assert-Equal $true $legacyLatestPlan.Operations[1].UnboundIssue `
    'TEST-0126 issue-less legacy identity must reach cleanup without inventing an issue'

$currentReplacement = New-Candidate -Number 62 -TargetTag 'v0.3.0' `
    -ProtocolSha ('3' * 40) -MarkerHeadSha ('c' * 40) `
    -UpdateBranchSuffix '-recovery'
$legacyWithReplacementPlan = Invoke-Plan -CurrentTag 'v0.1.0' `
    -AvailableTags @('v0.1.0', 'v0.3.0') -RequestedTargetTag 'v0.3.0' `
    -UpdateBranchSuffix '-recovery' `
    -Candidates @($legacyLatest, $currentReplacement)
Assert-Equal 'Supersede' $legacyWithReplacementPlan.State `
    'TEST-0126 an exact replacement must allow legacy cleanup'
Assert-Equal 'ClosePullRequest,DeleteBranch' `
    (@($legacyWithReplacementPlan.Operations.Kind) -join ',') `
    'TEST-0126 an existing exact replacement must not be duplicated'
Assert-Equal 61 $legacyWithReplacementPlan.Operations[0].PullRequestNumber `
    'TEST-0126 only the SupersedeOnly draft should be retired'

$invalidSupersedeOnly = New-Candidate -Number 63 -TargetTag 'v0.2.0'
$invalidSupersedeOnly | Add-Member -NotePropertyName SupersedeOnly `
    -NotePropertyValue 'true'
$invalidSupersedePlan = Invoke-Plan -CurrentTag 'v0.1.0' `
    -AvailableTags @('v0.1.0', 'v0.2.0') `
    -RequestedTargetTag 'v0.2.0' -Candidates @($invalidSupersedeOnly)
Assert-Equal 'BlockedManualReview' $invalidSupersedePlan.State `
    'TEST-0126 SupersedeOnly must be an exact Boolean contract'

$invalidUnboundIssue = New-Candidate -Number 64 -TargetTag 'v0.2.0'
$invalidUnboundIssue | Add-Member -NotePropertyName UnboundIssue `
    -NotePropertyValue $true
$invalidUnboundIssuePlan = Invoke-Plan -CurrentTag 'v0.1.0' `
    -AvailableTags @('v0.1.0', 'v0.2.0') `
    -RequestedTargetTag 'v0.2.0' -Candidates @($invalidUnboundIssue)
Assert-Equal 'BlockedManualReview' $invalidUnboundIssuePlan.State `
    'TEST-0126 UnboundIssue must be restricted to SupersedeOnly recovery candidates'

$compatibleCatalogOrder = @(Get-MeAndAICompatibleProtocolTagsInOrder `
    -CurrentTag 'v0.10.3' `
    -Tags @('v0.11.0', 'v0.10.5', 'v1.0.0', 'v0.10.3', 'v0.10.4', 'v0.10.4-beta.1'))
Assert-Equal 'v0.10.3,v0.10.4,v0.10.5,v0.11.0' `
    ($compatibleCatalogOrder -join ',') `
    'TEST-0121 compatible catalogs must be visited in numeric release order so skipped intermediates remain part of the validation chain'

$hugeMinor = '92233720368547758081234567890'
$hugeRevision = '99999999999999999999999999999'
$hugeCurrentTag = "v0.2147483648.$hugeRevision"
$hugeLatestTag = "v0.$hugeMinor.0"
$hugePlan = Invoke-Plan -CurrentTag $hugeCurrentTag -AvailableTags @(
    $hugeCurrentTag,
    'v0.2147483649.0',
    $hugeLatestTag
)
Assert-Equal 'OpenUpgrade' $hugePlan.State `
    'TEST-0088 unbounded canonical components should remain upgradable'
Assert-Equal $hugeLatestTag $hugePlan.LatestCompatibleTag `
    'TEST-0088 unbounded canonical components were not sorted numerically'
Assert-Equal $hugeLatestTag $hugePlan.Operations[0].TargetTag `
    'TEST-0088 unbounded numeric ordering selected the wrong target'
foreach ($invalidTag in @(
    'v01.0.0', 'v1.00.0', 'v1.0.00',
    ('v' + [string][char]0x0661 + '.0.0'),
    ('v' + [string][char]0xFF11 + '.0.0')
)) {
    if (Test-MeAndAIProtocolTag -Tag $invalidTag) {
        Add-Failure "TEST-0088 noncanonical or Unicode-digit tag was accepted: '$invalidTag'"
    }
}

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

$migrationPlanSha = '4' * 64
$migrationPaths = @('.ai/meandai-update-state.json', 'AGENTS.md')
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -MigrationRequired $true -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'OpenMigration' $plan.State `
    'TEST-0121 a current consumer with an unsatisfied plan should open migration reconciliation'
Assert-Equal 'CreateMigration' $plan.Operations[0].Kind `
    'TEST-0121 should create a migration operation'
Assert-Equal 'MigrationReconciliation' $plan.Operations[0].ProposalKind `
    'TEST-0121 migration creation should carry proposal kind'
Assert-Equal 'automation/meandai-protocol-v0.2.0-migrations' $plan.Operations[0].Branch `
    'TEST-0121 migration branch should use the deterministic suffix'
Assert-Equal $migrationPlanSha $plan.Operations[0].MigrationPlanSha `
    'TEST-0121 migration creation should carry the exact plan SHA'

$pendingMigration = New-Candidate -Number 40 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths $migrationPaths
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -Candidates @($pendingMigration) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'PendingMigration' $plan.State `
    'TEST-0121 an exact migration candidate should remain pending'
Assert-Equal 0 @($plan.Operations).Count `
    'TEST-0121 an exact migration candidate should be idempotent'

$customSuffixMigration = New-Candidate -Number 41 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths $migrationPaths -MigrationBranchSuffix '-consumer-migrations'
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($customSuffixMigration) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha `
    -MigrationBranchSuffix '-consumer-migrations'
Assert-Equal 'PendingMigration' $plan.State `
    'TEST-0121 a supplied canonical migration branch suffix should be honored'

$outsideMigrationPath = New-Candidate -Number 42 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths @('.ai/meandai-update-state.json')
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($outsideMigrationPath) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'BlockedManualReview' $plan.State `
    'TEST-0121 a migration path outside its dynamic allowed set must block'

$invalidMigrationPlan = New-Candidate -Number 43 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -MigrationPlanValid $false -ChangedPaths $migrationPaths `
    -ExpectedChangedPaths $migrationPaths -AllowedExpectedPaths $migrationPaths
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($invalidMigrationPlan) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'BlockedManualReview' $plan.State `
    'TEST-0121 invalid immutable migration evidence must block'

$typedInvalidMigrationPlan = New-Candidate -Number 49 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths $migrationPaths
$typedInvalidMigrationPlan.MigrationPlanValid = 'false'
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($typedInvalidMigrationPlan) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'BlockedManualReview' $plan.State `
    'TEST-0121 non-Boolean migration validity must fail closed'

$wrongCurrentPlan = New-Candidate -Number 44 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha ('5' * 64) `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths $migrationPaths
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($wrongCurrentPlan) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'BlockedManualReview' $plan.State `
    'TEST-0121 a same-target candidate with another plan must block rather than reuse its branch'

$pendingLegacyMigration = New-Candidate -Number 45 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths $migrationPaths
$plan = Invoke-Plan -CurrentTag 'v0.2.0' `
    -AvailableTags @('v0.2.0', 'v0.3.0') `
    -Candidates @($pendingLegacyMigration) -MigrationRequired $true `
    -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'Supersede' $plan.State `
    'TEST-0122 a newer protocol target should supersede pending migration work'
Assert-Equal 'CreateUpgrade,ClosePullRequest,DeleteBranch' `
    (@($plan.Operations.Kind) -join ',') `
    'TEST-0122 migration supersession must remain replacement-first'
Assert-Equal 'Update' $plan.Operations[0].ProposalKind `
    'TEST-0122 replacement should be an update proposal'
Assert-Equal 'MigrationReconciliation' $plan.Operations[1].ProposalKind `
    'TEST-0122 cleanup should retain the superseded proposal kind'
Assert-Equal $migrationPlanSha $plan.Operations[1].MigrationPlanSha `
    'TEST-0122 cleanup should retain the superseded migration plan SHA'

$latestUpdate = New-Candidate -Number 46 -TargetTag 'v0.3.0' `
    -MarkerHeadSha ('6' * 40)
$plan = Invoke-Plan -CurrentTag 'v0.2.0' `
    -AvailableTags @('v0.2.0', 'v0.3.0') `
    -Candidates @($pendingLegacyMigration, $latestUpdate) `
    -MigrationRequired $true -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'Supersede' $plan.State `
    'TEST-0122 existing latest update should be retained while migration work is retired'
Assert-Equal 'ClosePullRequest,DeleteBranch' (@($plan.Operations.Kind) -join ',') `
    'TEST-0122 should not duplicate an existing latest update'
Assert-Equal 45 $plan.Operations[0].PullRequestNumber `
    'TEST-0122 only the pending migration should be retired'

$staleMigration = New-Candidate -Number 47 -TargetTag 'v0.2.0' `
    -Kind 'MigrationReconciliation' -MigrationPlanSha $migrationPlanSha `
    -MarkerSchema 2 `
    -ChangedPaths $migrationPaths -ExpectedChangedPaths $migrationPaths `
    -AllowedExpectedPaths $migrationPaths
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($staleMigration)
Assert-Equal 'CleanupStale' $plan.State `
    'TEST-0122 a satisfied default branch should clean a stale migration candidate'
Assert-Equal 'MigrationReconciliation' $plan.Operations[0].ProposalKind `
    'TEST-0122 stale migration cleanup should retain proposal identity'

$sameTargetUpdate = New-Candidate -Number 48 -TargetTag 'v0.2.0' `
    -MarkerHeadSha ('7' * 40)
$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -Candidates @($sameTargetUpdate, $pendingMigration) `
    -MigrationRequired $true -CurrentMigrationPlanSha $migrationPlanSha
Assert-Equal 'Supersede' $plan.State `
    'TEST-0121 update and migration candidates at one target are distinct proposal identities'
Assert-Equal 'ClosePullRequest,DeleteBranch' (@($plan.Operations.Kind) -join ',') `
    'TEST-0121 exact migration should remain while stale update state is cleaned'
Assert-Equal 48 $plan.Operations[0].PullRequestNumber `
    'TEST-0121 cleanup should select only the stale update candidate'

$invalidKind = New-Candidate -Number 50 -TargetTag 'v0.2.0' -Kind 'Migration'
$plan = Invoke-Plan -CurrentTag 'v0.1.0' -AvailableTags @('v0.1.0', 'v0.2.0') `
    -Candidates @($invalidKind)
Assert-Equal 'BlockedManualReview' $plan.State `
    'TEST-0121 unsupported proposal kinds must fail closed'

$plan = Invoke-Plan -CurrentTag 'v0.2.0' -AvailableTags @('v0.2.0') `
    -MigrationRequired $true -CurrentMigrationPlanSha ('A' * 64)
Assert-Equal 'BlockedManualReview' $plan.State `
    'TEST-0121 migration plan SHA must be canonical lowercase SHA-256'

$majorPlan = Invoke-Plan -CurrentTag 'v0.3.0' -AvailableTags @('v0.3.0', 'v1.0.0')
Assert-Equal 'MajorUpgradeRequired' $majorPlan.State 'TEST-0016 incompatible major releases require manual migration'
Assert-Equal 0 @($majorPlan.Operations).Count 'TEST-0016 major releases must not create an automatic PR'

if ($PureResolverOnly) {
    if ($failures.Count -gt 0) {
        Write-Host "Pure protocol update resolver tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
        $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host 'Pure protocol update resolver tests passed.' -ForegroundColor Green
    return
}

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
    foreach ($forbidden in @('pull_request_target:', 'gh pr merge', 'MEANDAI_PROTOCOL_TOKEN: gh', 'actions/checkout@v')) {
        if ($workflow.Contains($forbidden)) {
            Add-Failure "TEST-0017 workflow contains forbidden behavior '$forbidden'"
        }
    }
    $proposalJobStart = $workflow.IndexOf('  propose-update:', [StringComparison]::Ordinal)
    $finalizerJobStart = $workflow.IndexOf('  finalize-managed-merge:', [StringComparison]::Ordinal)
    $proposalJob = if ($proposalJobStart -ge 0 -and $finalizerJobStart -gt $proposalJobStart) {
        $workflow.Substring($proposalJobStart, $finalizerJobStart - $proposalJobStart)
    }
    else { '' }
    foreach ($forbidden in @('contents: write', 'GH_TOKEN: ${{ github.token }}')) {
        if (-not $proposalJob -or $proposalJob.Contains($forbidden)) {
            Add-Failure "TEST-0017 proposal job contains finalizer-only authority '$forbidden'"
        }
    }
    foreach ($required in @('issues: write', 'ISSUE_TOKEN: ${{ github.token }}')) {
        if (-not $proposalJob.Contains($required)) {
            Add-Failure "TEST-0111 proposal job is missing narrow issue authority '$required'"
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
    foreach ($required in @("'pr', 'create'", '--draft', 'meandai-protocol-update', 'ClosePullRequest', 'DeleteBranch', 'Assert-ManagedPullRequestSafe', 'Get-AuthenticatedUpdaterActor', 'Assert-CurrentManagedAssets', 'Get-ExpectedManagedPaths', 'Assert-StagedManagedUpdate', 'Assert-CommittedManagedUpdate', "'rev-list', '--parents'", 'Assert-RemoteDefaultBranchUnchanged', 'default_branch', 'full_name', 'ManagedAssetEntriesMatchTarget', 'Get-RemoteBranchHead', 'ExpectedProtocolSha', '--paginate', '--force-with-lease=', '-isnot [long]')) {
        if (-not $adapter.Contains($required)) {
            Add-Failure "TEST-0017 adapter is missing '$required'"
        }
    }
    foreach ($required in @('templates/project/.github/workflows/meandai-protocol-update.yml', '.github/workflows/meandai-protocol-update.yml', 'MEANDAI_UPDATER_TOKEN', 'meAndAI Protocol Update Token', 'MEANDAI_PROTOCOL_TOKEN', 'v0.4.0', 'one-time', 'collision', 'submodule-only', '$defaultBranch', '$targetTag', 'git ls-tree', '160000 -> 160000')) {
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

$adapterTestPath = Join-Path $root 'tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1'
if (-not (Test-Path -LiteralPath $adapterTestPath -PathType Leaf)) {
    Write-Host 'Protocol update tests failed: missing adapter integration tests.' -ForegroundColor Red
    exit 1
}
$engine = (Get-Process -Id $PID).Path
& $engine -NoProfile -ExecutionPolicy Bypass -File $adapterTestPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host 'Protocol update tests passed for all declared scenarios in this suite.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities/consumer-update/protocol-update.tests.ps1' `
    -SourcePaths @($PSCommandPath, $adapterTestPath) `
    -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
