$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$modulePath = Join-Path $root 'scripts/MeAndAI.CapabilityReview.psm1'
$catalogModulePath = Join-Path $root 'scripts/MeAndAI.CapabilityCatalog.psm1'
Import-Module $catalogModulePath -Force
Import-Module $modulePath -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) {
        throw "$Message Expected '$Expected', observed '$Actual'."
    }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)
    try {
        & $Action
    }
    catch {
        if ($_.Exception.Message -like $Pattern) { return }
        throw "$Message Unexpected error: $($_.Exception.Message)"
    }
    throw "$Message No error was thrown."
}

function Get-TestGitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $prefix = [Text.Encoding]::ASCII.GetBytes(
        "blob $($Bytes.Length)$([char]0)"
    )
    $payload = [byte[]]::new($prefix.Length + $Bytes.Length)
    [Array]::Copy($prefix, 0, $payload, 0, $prefix.Length)
    [Array]::Copy($Bytes, 0, $payload, $prefix.Length, $Bytes.Length)
    $algorithm = [Security.Cryptography.SHA1]::Create()
    try {
        return -join @($algorithm.ComputeHash($payload) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function Test-TestBytesEqual {
    param([AllowNull()][byte[]]$Left, [AllowNull()][byte[]]$Right)

    if ($null -eq $Left -or $null -eq $Right) {
        return $null -eq $Left -and $null -eq $Right
    }
    if ($Left.Length -ne $Right.Length) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }
    return $true
}

function New-TestCapabilityReviewBody {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][int]$LedgerPrefixCount,
        [Parameter(Mandatory)][long]$ProposalActorId,
        [Parameter(Mandatory)][string]$ProposalActorLogin,
        [Parameter(Mandatory)][long]$IssueActorId,
        [Parameter(Mandatory)][string]$IssueActorLogin,
        [ValidateRange(0, 2147483647)][int]$IssueNumber = 0,
        [string]$HandoffHead = 'pending',
        [string]$BaseLedgerDigest = 'missing'
    )

    $tick = [string][char]96
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add([string]$Plan.Marker)
    $lines.Add('')
    $lines.Add('This is a review-only meAndAI semantic capability handoff.')
    $lines.Add('Automation owns only the transient manifest; semantic consumer changes require maintainer review.')
    $lines.Add('')
    $lines.Add("Catalog digest: $tick$($Plan.CatalogDigest)$tick")
    $lines.Add("Batch digest: $tick$($Plan.BatchDigest)$tick")
    $lines.Add("Base branch: $tick$($Plan.BaseBranch)$tick")
    $lines.Add("Base head: $tick$($Plan.BaseHead)$tick")
    $lines.Add("Base ledger digest: $tick$BaseLedgerDigest$tick")
    $lines.Add("Review branch: $tick$($Plan.Branch)$tick")
    $lines.Add("Handoff head: $tick$HandoffHead$tick")
    $lines.Add("Ledger prefix count: $tick$LedgerPrefixCount$tick")
    $lines.Add("Proposal actor ID: $tick$ProposalActorId$tick")
    $lines.Add("Proposal actor login: $tick$ProposalActorLogin$tick")
    $lines.Add("Issue actor ID: $tick$IssueActorId$tick")
    $lines.Add("Issue actor login: $tick$IssueActorLogin$tick")
    if ($IssueNumber -gt 0) {
        $lines.Add("Tracking issue: $tick$IssueNumber$tick")
        $lines.Add('')
        $lines.Add("Tracking issue: #$IssueNumber")
    }
    $lines.Add('')
    $lines.Add('Capability batch:')
    foreach ($capability in @($Plan.CapabilityBatch)) {
        $lines.Add(
            "- $([string]$capability.Slug)@$([string]$capability.DefinitionBlob) ($([string]$capability.Outcome))"
        )
    }
    return ($lines -join "`n") + "`n"
}

$catalogDigest = 'a' * 64
$definitionBlob = 'b' * 40
$baseHead = 'c' * 40
$reviewHead = 'd' * 40
$mergeCommit = 'e' * 40
$catalog = [pscustomobject][ordered]@{
    CatalogDigest = $catalogDigest
    Capabilities = @(
        [pscustomobject][ordered]@{
            Slug = 'test-architecture'
            DefinitionBlob = $definitionBlob
            Type = 'Semantic'
        }
    )
}
$emptyLedger = [pscustomobject][ordered]@{ Entries = @() }
$terminalEntry = [pscustomobject][ordered]@{
    Slug = 'test-architecture'
    DefinitionBlob = $definitionBlob
    Outcome = 'Conforming'
    Evidence = 'Reviewed test topology at commit 0123456789abcdef.'
    ReviewIdentity = 'pull-request:87'
}
$terminalLedger = [pscustomobject][ordered]@{ Entries = @($terminalEntry) }
$reviewRequired = [pscustomobject][ordered]@{
    Slug = 'test-architecture'
    DefinitionBlob = $definitionBlob
    Outcome = 'ReviewRequired'
    Evidence = ''
    ReviewIdentity = ''
}
$adoptionRequired = [pscustomobject][ordered]@{
    Slug = 'test-architecture'
    DefinitionBlob = $definitionBlob
    Outcome = 'AdoptionRequired'
    Evidence = 'Root validation scripts require semantic reorganization.'
    ReviewIdentity = 'assessment:agent-1'
}

$common = @{
    Catalog = $catalog
    Ledger = $emptyLedger
    Repository = 'hasanmanzak/consumer'
    DefaultBranch = 'main'
    DefaultHead = $baseHead
    TargetVersion = 'v0.12.0'
    Assessments = @($reviewRequired)
}

# Verify the source-only lifecycle consumes the release catalog module's typed
# objects directly rather than maintaining another catalog or ledger parser.
$releaseCatalog = Import-MeAndAICapabilityCatalog `
    -IndexPath (Join-Path $root 'capabilities/index.json')
$missingReleaseLedger = Import-MeAndAICapabilityLedger `
    -Catalog $releaseCatalog -Bytes $null
$releaseAssessment = Resolve-MeAndAICapabilityAssessment `
    -Capability $releaseCatalog.Capabilities[0] `
    -Applicability Unknown -Conformance Unknown -AdoptionPlan Ambiguous
$releasePlan = Resolve-MeAndAICapabilityReview `
    -Catalog $releaseCatalog -Ledger $missingReleaseLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -DefaultHead $baseHead -TargetVersion v0.12.0 `
    -DiscoveryContext AlreadyCurrent -Assessments @($releaseAssessment)
Assert-Equal $releasePlan.CatalogDigest $releaseCatalog.CatalogDigest `
    'TEST-0140 lifecycle did not consume exact release-catalog identity.'
Assert-Equal $releasePlan.State 'CreateReviewHandoff' `
    'TEST-0140 release catalog did not enter semantic review discovery.'

$releaseEntry = New-MeAndAICapabilityLedgerEntry `
    -Capability $releaseCatalog.Capabilities[0] -Outcome Conforming `
    -Evidence @('Reviewed release-catalog topology evidence.') `
    -ReviewIdentity 'pull-request:87' `
    -ReviewAuthority 'https://github.com/hasanmanzak/consumer/pull/87' `
    -ReviewedAt '2026-07-19T00:00:00Z'
$releaseLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
    -Catalog $releaseCatalog -Entries @($releaseEntry)
$releaseLedger = Import-MeAndAICapabilityLedger `
    -Catalog $releaseCatalog -Bytes $releaseLedgerBytes
$releasePrefixPlan = Resolve-MeAndAICapabilityReview `
    -Catalog $releaseCatalog -Ledger $releaseLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -DefaultHead $baseHead -TargetVersion v0.12.0 `
    -DiscoveryContext AlreadyCurrent
Assert-Equal $releasePrefixPlan.State 'CreateReviewHandoff' `
    'TEST-0157 predecessor terminal ledger did not request appended capability review.'
Assert-Equal $releasePrefixPlan.CapabilityBatch.Count 1 `
    'TEST-0157 predecessor terminal ledger exposed the wrong pending suffix size.'
Assert-Equal $releasePrefixPlan.CapabilityBatch[0].Slug `
    'test-runtime-efficiency' `
    'TEST-0157 predecessor terminal ledger exposed the wrong pending capability.'

$releaseEfficiencyEntry = New-MeAndAICapabilityLedgerEntry `
    -Capability $releaseCatalog.Capabilities[1] -Outcome NotApplicable `
    -Evidence @('Reviewed repository has no repeated expensive deterministic setup.') `
    -ReviewIdentity 'pull-request:87' `
    -ReviewAuthority 'https://github.com/hasanmanzak/consumer/pull/87' `
    -ReviewedAt '2026-07-19T00:00:00Z'
$releaseCompleteLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
    -Catalog $releaseCatalog -Entries @($releaseEntry, $releaseEfficiencyEntry)
$releaseCompleteLedger = Import-MeAndAICapabilityLedger `
    -Catalog $releaseCatalog -Bytes $releaseCompleteLedgerBytes
$releaseCurrent = Resolve-MeAndAICapabilityReview `
    -Catalog $releaseCatalog -Ledger $releaseCompleteLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -DefaultHead $baseHead -TargetVersion v0.12.0 `
    -DiscoveryContext AlreadyCurrent
Assert-Equal $releaseCurrent.State 'Current' `
    'TEST-0157 exact imported two-entry terminal ledger was not current.'
Assert-Equal $releaseCurrent.Operations.Count 0 `
    'TEST-0157 exact imported two-entry terminal ledger was not a no-op.'

# TEST-0139: fresh adoption is followed by the same source-only semantic review
# boundary, without expanding the adoption envelope or writing product paths.
$freshPlan = Resolve-MeAndAICapabilityReview @common `
    -DiscoveryContext PostFreshAdoption
Assert-Equal $freshPlan.State 'CreateReviewHandoff' `
    'TEST-0139 fresh discovery did not create the separate review handoff.'
Assert-Equal ($freshPlan.Operations.Kind -join ',') `
    'CreateBranch,OpenIssue,WriteReviewManifest,OpenDraftPullRequest' `
    'TEST-0139 fresh handoff operation ordering changed.'
Assert-Equal $freshPlan.AutomationWritePaths.Count 1 `
    'TEST-0139 fresh handoff must expose one automation-owned state path.'
Assert-Equal $freshPlan.AutomationWritePaths[0] `
    '.ai/adoption/meandai-capability-review.json' `
    'TEST-0139 fresh handoff wrote outside its transient manifest boundary.'
Assert-Equal $freshPlan.SemanticWritePaths.Count 0 `
    'TEST-0139 automation claimed a semantic consumer path.'
Assert-True $freshPlan.InitialAdoptionEnvelopeUnchanged `
    'TEST-0139 fresh discovery broadened the initial-adoption envelope.'

$terminalAssessment = [pscustomobject][ordered]@{
    Slug = 'test-architecture'
    DefinitionBlob = $definitionBlob
    Outcome = 'Conforming'
    Evidence = 'Reviewed capability structure at commit 0123456789abcdef.'
    ReviewIdentity = 'pull-request:86'
}
$terminalPlan = Resolve-MeAndAICapabilityReview `
    -Catalog $catalog -Ledger $emptyLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -DefaultHead $baseHead -TargetVersion v0.12.0 `
    -DiscoveryContext PostFreshAdoption -Assessments @($terminalAssessment)
Assert-Equal $terminalPlan.State 'TerminalEvidenceReady' `
    'TEST-0139 reviewed conforming evidence was not kept proposal-free.'
Assert-Equal ($terminalPlan.Operations.Kind -join ',') 'AppendTerminalLedger' `
    'TEST-0139 terminal evidence created a semantic proposal.'
Assert-Equal $terminalPlan.AutomationWritePaths[0] `
    '.ai/meandai-capabilities-state.json' `
    'TEST-0139 terminal evidence targeted an unsupported state path.'
Assert-Equal $terminalPlan.SemanticWritePaths.Count 0 `
    'TEST-0139 terminal evidence claimed semantic consumer ownership.'

Assert-ThrowsLike -Action {
    Resolve-MeAndAICapabilityReview `
        -Catalog $catalog -Ledger $emptyLedger `
        -Repository 'hasanmanzak/consumer' -DefaultBranch main `
        -DefaultHead $baseHead -TargetVersion v0.12.0 `
        -DiscoveryContext PostFreshAdoption `
        -Assessments @($terminalAssessment) `
        -ExistingIssues @([pscustomobject]@{ Marker = 'occupied' })
} -Pattern '*Terminal assessment*inventory exists*' `
    -Message 'TEST-0139 terminal append bypassed canonical review inventory.'

$notApplicable = $terminalAssessment.PSObject.Copy()
$notApplicable.Outcome = 'NotApplicable'
$notApplicable.Evidence = 'Reviewed repository has no automated validation surface.'
$notApplicablePlan = Resolve-MeAndAICapabilityReview `
    -Catalog $catalog -Ledger $emptyLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -DefaultHead $baseHead -TargetVersion v0.12.0 `
    -DiscoveryContext PostFreshAdoption -Assessments @($notApplicable)
Assert-Equal $notApplicablePlan.State 'TerminalEvidenceReady' `
    'TEST-0139 reviewed NotApplicable evidence did not remain proposal-free.'

$adoptionPlan = Resolve-MeAndAICapabilityReview `
    -Catalog $catalog -Ledger $emptyLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -DefaultHead $baseHead -TargetVersion v0.12.0 `
    -DiscoveryContext PostFreshAdoption -Assessments @($adoptionRequired)
Assert-Equal $adoptionPlan.State 'CreateReviewHandoff' `
    'TEST-0139 AdoptionRequired did not create review-only work.'
Assert-Equal $adoptionPlan.Marker $freshPlan.Marker `
    'TEST-0139 open outcomes did not share canonical repository/catalog identity.'

# TEST-0140: current and post-update consumers use exactly the same target
# catalog identity; immutable pre-framework code can only request its ordinary
# update before the new same-target discovery runs.
$currentPlan = Resolve-MeAndAICapabilityReview @common `
    -DiscoveryContext AlreadyCurrent
$updatedPlan = Resolve-MeAndAICapabilityReview @common `
    -DiscoveryContext PostProtocolUpdate -SourceVersion v0.11.1
Assert-Equal $currentPlan.Marker $freshPlan.Marker `
    'TEST-0140 already-current discovery used another canonical marker.'
Assert-Equal $updatedPlan.Marker $freshPlan.Marker `
    'TEST-0140 post-update discovery used another canonical marker.'
Assert-Equal $updatedPlan.AssessmentTarget 'v0.12.0' `
    'TEST-0140 post-update discovery switched away from the installed target.'
Assert-Equal $updatedPlan.SourceVersionSwitch $false `
    'TEST-0140 post-update discovery introduced a source-version switch.'

$preFramework = Resolve-MeAndAICapabilityReview @common `
    -DiscoveryContext PostProtocolUpdate -SourceVersion v0.11.1 `
    -FrameworkInstalled:$false
Assert-Equal $preFramework.State 'ProtocolUpdateRequired' `
    'TEST-0140 pre-framework consumer skipped the ordinary updater handoff.'
Assert-Equal ($preFramework.Operations.Kind -join ',') 'RunOrdinaryProtocolUpdate' `
    'TEST-0140 pre-framework handoff performed semantic lifecycle work.'
Assert-Equal $preFramework.SemanticWritePaths.Count 0 `
    'TEST-0140 immutable pre-framework code claimed semantic paths.'

$issue = [pscustomobject][ordered]@{
    Number = 81
    State = 'Open'
    Marker = $freshPlan.Marker
}
$branch = [pscustomobject][ordered]@{
    Name = $freshPlan.Branch
    BaseHead = $baseHead
    HeadSha = $reviewHead
    Marker = $freshPlan.Marker
}
$manifest = [pscustomobject][ordered]@{
    Marker = $freshPlan.Marker
    CatalogDigest = $catalogDigest
    Repository = 'hasanmanzak/consumer'
    BaseBranch = 'main'
    BaseHead = $baseHead
    Branch = $freshPlan.Branch
    IssueNumber = 81
}
$pullRequest = [pscustomobject][ordered]@{
    Number = 88
    State = 'Open'
    IsDraft = $true
    Marker = $freshPlan.Marker
    HeadBranch = $freshPlan.Branch
    HeadSha = $reviewHead
    BaseBranch = 'main'
    BaseHead = $baseHead
    IssueNumber = 81
    MergeCommit = ''
}
$reused = Resolve-MeAndAICapabilityReview @common `
    -DiscoveryContext AlreadyCurrent -ExistingIssues @($issue) `
    -ExistingBranches @($branch) -ExistingManifests @($manifest) `
    -ExistingPullRequests @($pullRequest)
Assert-Equal $reused.State 'ReviewPending' `
    'TEST-0140 exact pending review was not reused.'
Assert-Equal $reused.Operations.Count 0 `
    'TEST-0140 exact pending rerun was not a no-op.'

$interrupted = Resolve-MeAndAICapabilityReview @common `
    -DiscoveryContext AlreadyCurrent -ExistingBranches @($branch)
Assert-Equal ($interrupted.Operations.Kind -join ',') `
    'OpenIssue,WriteReviewManifest,OpenDraftPullRequest' `
    'TEST-0140 interrupted branch-first creation did not resume deterministically.'

Assert-ThrowsLike -Action {
    Resolve-MeAndAICapabilityReview @common `
        -DiscoveryContext AlreadyCurrent -ExistingIssues @($issue, $issue) `
        -ExistingBranches @($branch)
} -Pattern '*duplicate*issue*' `
    -Message 'TEST-0140 duplicate canonical issues did not fail closed.'

$staleIssue = $issue.PSObject.Copy()
$staleIssue.Marker = '<!-- meandai-capability-review:v1:stale -->'
Assert-ThrowsLike -Action {
    Resolve-MeAndAICapabilityReview @common `
        -DiscoveryContext AlreadyCurrent -ExistingIssues @($staleIssue)
} -Pattern '*marker*' `
    -Message 'TEST-0140 stale catalog identity did not fail closed.'

$mergedPullRequest = $pullRequest.PSObject.Copy()
$mergedPullRequest.State = 'Merged'
$mergedPullRequest.IsDraft = $false
$mergedPullRequest.MergeCommit = $mergeCommit
$finalization = Resolve-MeAndAICapabilityReviewFinalization `
    -Catalog $catalog -Ledger $terminalLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -Marker $freshPlan.Marker -ExpectedBranch $freshPlan.Branch `
    -ExpectedBaseHead $baseHead `
    -ExpectedReviewHead $reviewHead -Issue $issue -Branch $branch `
    -PullRequest $mergedPullRequest -DefaultContainsMerge:$true `
    -ManifestPresentOnDefault:$false
Assert-Equal $finalization.State 'Finalize' `
    'TEST-0140 reviewed terminal state was not finalizable.'
Assert-Equal ($finalization.Operations.Kind -join ',') `
    'DeleteBranch,CloseIssue' `
    'TEST-0140 finalization did not preserve branch-first/issue-last order.'

$calls = [System.Collections.Generic.List[string]]::new()
$handlers = @{
    DeleteBranch = { param($Operation, $Plan) $calls.Add($Operation.Kind) }
    CloseIssue = { param($Operation, $Plan) $calls.Add($Operation.Kind) }
}
[void](Invoke-MeAndAICapabilityReviewPlan -Plan $finalization -Handlers $handlers)
Assert-Equal ($calls -join ',') 'DeleteBranch,CloseIssue' `
    'TEST-0140 injected side effects ran outside verified cleanup order.'
$calls.Clear()
[void](Invoke-MeAndAICapabilityReviewPlan -Plan $finalization `
    -Handlers $handlers -DryRun)
Assert-Equal $calls.Count 0 `
    'TEST-0140 dry-run executed a GitHub side effect.'

$closedIssue = $issue.PSObject.Copy()
$closedIssue.State = 'Closed'
$closedIssue | Add-Member -NotePropertyName ClosureMarker `
    -NotePropertyValue $finalization.ClosureMarker
$completed = Resolve-MeAndAICapabilityReviewFinalization `
    -Catalog $catalog -Ledger $terminalLedger `
    -Repository 'hasanmanzak/consumer' -DefaultBranch main `
    -Marker $freshPlan.Marker -ExpectedBranch $freshPlan.Branch `
    -ExpectedBaseHead $baseHead `
    -ExpectedReviewHead $reviewHead -Issue $closedIssue -Branch $null `
    -PullRequest $mergedPullRequest -DefaultContainsMerge:$true `
    -ManifestPresentOnDefault:$false
Assert-Equal $completed.State 'Completed' `
    'TEST-0140 exact completed state was not recognized.'
Assert-Equal $completed.Operations.Count 0 `
    'TEST-0140 completed rerun was not an exact no-op.'

Assert-ThrowsLike -Action {
    Resolve-MeAndAICapabilityReviewFinalization `
        -Catalog $catalog -Ledger $emptyLedger `
        -Repository 'hasanmanzak/consumer' -DefaultBranch main `
        -Marker $freshPlan.Marker -ExpectedBranch $freshPlan.Branch `
        -ExpectedBaseHead $baseHead `
        -ExpectedReviewHead $reviewHead -Issue $issue -Branch $branch `
        -PullRequest $mergedPullRequest -DefaultContainsMerge:$true `
        -ManifestPresentOnDefault:$false
} -Pattern '*terminal*ledger*' `
    -Message 'TEST-0140 finalization accepted missing terminal ledger evidence.'

$closedEarly = $closedIssue.PSObject.Copy()
$closedEarly.ClosureMarker = ''
Assert-ThrowsLike -Action {
    Resolve-MeAndAICapabilityReviewFinalization `
        -Catalog $catalog -Ledger $terminalLedger `
        -Repository 'hasanmanzak/consumer' -DefaultBranch main `
        -Marker $freshPlan.Marker -ExpectedBranch $freshPlan.Branch `
        -ExpectedBaseHead $baseHead `
        -ExpectedReviewHead $reviewHead -Issue $closedEarly -Branch $branch `
        -PullRequest $mergedPullRequest -DefaultContainsMerge:$true `
        -ManifestPresentOnDefault:$false
} -Pattern '*issue*closed*branch*' `
    -Message 'TEST-0140 issue-last ordering accepted an early issue close.'

$runnerPath = Join-Path $root 'scripts/Invoke-MeAndAICapabilityReview.ps1'
Assert-True (Test-Path -LiteralPath $runnerPath -PathType Leaf) `
    'TEST-0140 production capability-review runner is absent.'
$runnerTokens = $null
$runnerErrors = $null
$runnerAst = [Management.Automation.Language.Parser]::ParseFile(
    $runnerPath,
    [ref]$runnerTokens,
    [ref]$runnerErrors
)
Assert-Equal @($runnerErrors).Count 0 `
    'TEST-0140 production capability-review runner does not parse.'
$runnerParameterNames = @($runnerAst.ParamBlock.Parameters | ForEach-Object {
    [string]$_.Name.VariablePath.UserPath
})
foreach ($parameterName in @(
    'ConsumerRoot', 'ProtocolRoot', 'Repository', 'DefaultBranch',
    'DefaultHead', 'TargetVersion', 'IssueActorLogin', 'DiscoveryContext', 'SourceVersion',
    'FrameworkInstalled', 'Assessments', 'MaximumPages',
    'FinalizePullRequestNumber', 'Runtime', 'FixtureInventory', 'PlanOnly'
)) {
    Assert-True ($runnerParameterNames -ccontains $parameterName) `
        "TEST-0140 production runner lacks '$parameterName'."
}

$workflowPath = Join-Path $root `
    'templates/project/.github/workflows/meandai-protocol-update.yml'
$workflowText = [IO.File]::ReadAllText($workflowPath)
foreach ($requiredWorkflowText in @(
    'automation/meandai-capability-review-',
    "'PostFreshAdoption'",
    "'PostProtocolUpdate'",
    "'AlreadyCurrent'",
    '.meandai-update-source/scripts/Invoke-MeAndAICapabilityReview.ps1',
    '-TargetVersion $env:BOOTSTRAP_PROTOCOL_TAG',
    '-DiscoveryContext $discoveryContext',
    '-SourceVersion $sourceVersion',
    'The job-scoped capability review token is required.',
    '-FinalizePullRequestNumber ([int]$pullRequestNumber)',
    'Ordinary protocol update must merge before semantic capability discovery.',
    "the runner's completed-ledger path is an exact no-op."
)) {
    Assert-True $workflowText.Contains($requiredWorkflowText) `
        "TEST-0140 consumer workflow lacks '$requiredWorkflowText'."
}
Assert-True (
    [regex]::Matches(
        $workflowText,
        [regex]::Escape('automation/meandai-capability-review-')
    ).Count -ge 3
) 'TEST-0140 semantic review branch is not routed through proposal and finalization gates.'
$proposalJobStart = $workflowText.IndexOf(
    '  propose-update:', [StringComparison]::Ordinal
)
$finalizationJobStart = $workflowText.IndexOf(
    '  finalize-managed-merge:', [StringComparison]::Ordinal
)
$proposalJobText = if ($proposalJobStart -ge 0 -and
    $finalizationJobStart -gt $proposalJobStart) {
    $workflowText.Substring(
        $proposalJobStart,
        $finalizationJobStart - $proposalJobStart
    )
}
else {
    ''
}
Assert-True ($proposalJobText.Contains('contents: read') -and
    $proposalJobText.Contains('issues: write') -and
    -not $proposalJobText.Contains('pull-requests: write')) `
    'TEST-0140 proposal job broadened job-token authority beyond issue tracking.'
Assert-True $proposalJobText.Contains(
    "startsWith(github.event.pull_request.head.ref, 'automation/meandai-capability-review-')"
) 'TEST-0140 semantic merge does not idempotently re-enter discovery after finalization.'
$sourceEqualityGate = $workflowText.IndexOf(
    '$installedProtocolSha -cne $sourceHead',
    [StringComparison]::Ordinal
)
$discoveryRunnerCall = $workflowText.IndexOf(
    '-DiscoveryContext $discoveryContext',
    [StringComparison]::Ordinal
)
Assert-True ($sourceEqualityGate -ge 0 -and
    $sourceEqualityGate -lt $discoveryRunnerCall) `
    'TEST-0140 semantic discovery can run before the installed gitlink equals the release source.'
$tokenGuard = $workflowText.IndexOf(
    'The job-scoped capability review token is required.',
    [StringComparison]::Ordinal
)
Assert-True ($tokenGuard -gt $sourceEqualityGate -and
    $tokenGuard -lt $discoveryRunnerCall -and
    -not $workflowText.Contains('$env:GH_TOKEN = $env:ISSUE_TOKEN')) `
    'TEST-0140 capability review did not keep proposal and issue authorities separate.'
Assert-True ($workflowText.Contains(
    'GH_TOKEN: ${{ secrets.MEANDAI_UPDATER_TOKEN }}'
)) 'TEST-0140 semantic proposal lost updater-token PR authority.'
Assert-True ($workflowText.Contains(
    'Capability review finalization requires separate proposal and issue authorities.'
) -and $workflowText.Contains('$env:GH_TOKEN = $env:UPDATER_TOKEN')) `
    'TEST-0140 semantic finalization did not restore updater-token proposal authority.'
$semanticFinalizationGuard = $workflowText.IndexOf(
    '$semanticReview = $pullRequestHead.StartsWith(',
    [StringComparison]::Ordinal
)
$deterministicFinalizer = $workflowText.IndexOf(
    '-FinalizeMergedPullRequest',
    [StringComparison]::Ordinal
)
Assert-True ($semanticFinalizationGuard -ge 0 -and
    $semanticFinalizationGuard -lt $deterministicFinalizer) `
    'TEST-0140 semantic review can reach deterministic managed-asset finalization.'

$quickAdoptionTestPath = Join-Path $root `
    'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
$quickAdoptionTestText = [IO.File]::ReadAllText($quickAdoptionTestPath)
$fixtureCopyStart = $quickAdoptionTestText.IndexOf(
    'function Copy-CanonicalProtocolFixture',
    [StringComparison]::Ordinal
)
$fixtureCopyEnd = $quickAdoptionTestText.IndexOf(
    'function Get-GitBlobSha',
    [StringComparison]::Ordinal
)
Assert-True ($fixtureCopyStart -ge 0 -and $fixtureCopyEnd -gt $fixtureCopyStart) `
    'TEST-0140 quick-adoption fixture copy boundary is absent.'
$fixtureCopyText = $quickAdoptionTestText.Substring(
    $fixtureCopyStart,
    $fixtureCopyEnd - $fixtureCopyStart
)
$managedEnvelopeText = $quickAdoptionTestText.Substring(0, $fixtureCopyStart)
foreach ($sourceOnlyPath in @(
    'capabilities/index.json',
    'capabilities/test-architecture.json',
    'capabilities/test-runtime-efficiency.json',
    'scripts/MeAndAI.CapabilityCatalog.psm1',
    'scripts/MeAndAI.CapabilityReview.psm1',
    'scripts/Invoke-MeAndAICapabilityReview.ps1'
)) {
    Assert-True $fixtureCopyText.Contains("'$sourceOnlyPath'") `
        "TEST-0140 quick-adoption source fixture omits '$sourceOnlyPath'."
    Assert-True (-not $managedEnvelopeText.Contains("'$sourceOnlyPath'")) `
        "TEST-0140 source-only capability asset entered the managed adoption envelope: '$sourceOnlyPath'."
}

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'meandai-capability-review-' + [Guid]::NewGuid().ToString('N')
)
[void](New-Item -ItemType Directory -Path $fixtureRoot)
try {
    $fixtureHead = 'f' * 40
    $fixtureInventory = [pscustomobject][ordered]@{
        CurrentDefaultHead = $fixtureHead
        ReviewBaseHead = $fixtureHead
        Issues = @()
        Branches = @()
        PullRequests = @()
        Manifests = @()
        Binding = $null
        DefaultContainsMerge = $false
        ManifestPresentOnDefault = $false
        Reviewed = $false
    }
    $forbiddenRuntime = @{
        Git = {
            throw 'TEST-0140 PlanOnly fixture invoked Git.'
        }
        GitHub = {
            throw 'TEST-0140 PlanOnly fixture invoked GitHub.'
        }
    }
    $runnerResult = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -DefaultHead $fixtureHead `
        -TargetVersion v0.12.0 -DiscoveryContext AlreadyCurrent `
        -Runtime $forbiddenRuntime -FixtureInventory $fixtureInventory `
        -PlanOnly
    Assert-Equal $runnerResult.Mode 'PlanOnly' `
        'TEST-0140 fixture-safe runner did not stay plan-only.'
    Assert-Equal $runnerResult.State 'CreateReviewHandoff' `
        'TEST-0140 fixture-safe runner did not resolve production handoff.'
    Assert-Equal ($runnerResult.Plan.Operations.Kind -join ',') `
        'CreateBranch,OpenIssue,WriteReviewManifest,OpenDraftPullRequest' `
        'TEST-0140 production runner changed branch-first operation order.'
    Assert-Equal $runnerResult.Plan.SemanticWritePaths.Count 0 `
        'TEST-0140 production runner claimed a semantic consumer path.'
    Assert-True (-not (Test-Path -LiteralPath (
        Join-Path $fixtureRoot '.ai'
    ))) 'TEST-0140 PlanOnly fixture wrote consumer state.'

    $apiState = [pscustomobject][ordered]@{
        Calls = [System.Collections.Generic.List[string]]::new()
        DefaultHead = $fixtureHead
        BranchHead = $fixtureHead
        BranchCreated = $false
        IssueCreated = $false
        IssueClosed = $false
        PullCreated = $false
        PullMerged = $false
        MergeCommit = '5' * 40
        ClosureComments = [System.Collections.Generic.List[object]]::new()
        AttestationComments = [System.Collections.Generic.List[object]]::new()
        Reviews = [System.Collections.Generic.List[object]]::new()
        IssueBody = ''
        BlobBody = $null
        TreeBody = $null
        CommitBody = $null
        PullBody = $null
        FinalLedgerBytes = $null
        ReviewerPermission = 'write'
        OwnerPermission = 'admin'
        DefaultHeadReadCount = 0
        DriftDefaultHeadAfterReadCount = 0
        ProposalActor = [pscustomobject]@{
            id = 101
            login = 'meandai-bot'
        }
        IssueActor = [pscustomobject]@{
            id = 41898282
            login = 'github-actions[bot]'
        }
        ReviewerActor = [pscustomobject]@{
            id = 202
            login = 'consumer-maintainer'
        }
        PermissionActor = [pscustomobject]@{
            id = 202
            login = 'consumer-maintainer'
        }
        RepositoryOwner = [pscustomobject]@{
            id = 101
            login = 'meandai-bot'
            type = 'User'
        }
        OwnerPermissionActor = [pscustomobject]@{
            id = 101
            login = 'meandai-bot'
        }
        ForeignIssues = [System.Collections.Generic.List[object]]::new()
        ForceManifestOnReviewedTree = $false
        ForceLedgerMismatch = $false
        DirtyManagedPaths = $false
        PullHeadRepository = 'hasanmanzak/consumer'
        HistoricalReview = $null
        HistoricalMutationCalls = [System.Collections.Generic.List[string]]::new()
        HistoricalEvidenceCalls = [System.Collections.Generic.List[string]]::new()
    }
    $apiState.Reviews.Add([pscustomobject]@{
        state = 'APPROVED'
        commit_id = [string]$apiState.BranchHead
        submitted_at = '2026-07-19T00:00:30Z'
        user = $apiState.ReviewerActor
    })
    $gitRuntime = {
        param([string[]]$Arguments, [int[]]$AllowedExitCodes)
        $commandText = $Arguments -join ' '
        $workingRoot = if ($Arguments.Count -ge 2 -and
            $Arguments[0] -ceq '-C') {
            [string]$Arguments[1]
        }
        else {
            ''
        }
        $text = if ($Arguments -contains '--show-toplevel') {
            $fixtureRoot
        }
        elseif ($Arguments -contains 'get-url') {
            if ($workingRoot -ceq $root) {
                if ($null -ne $apiState.HistoricalReview) {
                    $apiState.HistoricalEvidenceCalls.Add('protocol-origin')
                }
                'https://github.com/hasanmanzak/meAndAI.git'
            }
            else {
                'https://github.com/hasanmanzak/consumer.git'
            }
        }
        elseif ($Arguments -contains 'status') {
            if ($apiState.DirtyManagedPaths) {
                ' M .ai/meandai-capabilities-state.json'
            }
            else {
                ''
            }
        }
        elseif ($workingRoot -ceq $fixtureRoot -and
            $Arguments -contains 'rev-parse' -and
            $Arguments[-1] -ceq 'HEAD') {
            [string]$apiState.DefaultHead
        }
        elseif ($null -ne $apiState.HistoricalReview -and
            $workingRoot -ceq $fixtureRoot -and
            $Arguments -contains 'ls-tree' -and
            $Arguments -contains '.ai/protocol') {
            if ($Arguments -cnotcontains
                [string]$apiState.HistoricalReview.BaseHead) {
                throw 'TEST-0166 historical catalog was not resolved from the exact review BaseHead.'
            }
            $apiState.HistoricalEvidenceCalls.Add('base-gitlink')
            if ($apiState.HistoricalReview.MissingBaseGitlink) {
                ''
            }
            else {
                "160000 commit $($apiState.HistoricalReview.ProtocolCommit)`t.ai/protocol"
            }
        }
        elseif ($null -ne $apiState.HistoricalReview -and
            $workingRoot -ceq $root -and
            $Arguments -contains 'rev-parse' -and
            $commandText.Contains('refs/tags/')) {
            $apiState.HistoricalEvidenceCalls.Add('tag-peel')
            if ($apiState.HistoricalReview.MissingReleaseTag) {
                return [pscustomobject][ordered]@{
                    ExitCode = 1
                    Output = @()
                    Text = ''
                }
            }
            [string]$apiState.HistoricalReview.ProtocolCommit
        }
        elseif ($null -ne $apiState.HistoricalReview -and
            $workingRoot -ceq $root -and
            $Arguments -contains 'cat-file' -and
            $Arguments -contains '-e') {
            $apiState.HistoricalEvidenceCalls.Add('protocol-commit')
            ''
        }
        elseif ($null -ne $apiState.HistoricalReview -and
            $workingRoot -ceq $root -and
            $Arguments -contains 'merge-base' -and
            $Arguments -contains '--is-ancestor' -and
            $Arguments -contains $apiState.HistoricalReview.ProtocolCommit) {
            $apiState.HistoricalEvidenceCalls.Add('protocol-ancestor')
            if ($apiState.HistoricalReview.ProtocolCommitNotAncestor) {
                return [pscustomobject][ordered]@{
                    ExitCode = 1
                    Output = @()
                    Text = ''
                }
            }
            ''
        }
        elseif ($null -ne $apiState.HistoricalReview -and
            $workingRoot -ceq $fixtureRoot -and
            $Arguments -contains 'push' -and
            $commandText.Contains(
                ":refs/heads/$($apiState.HistoricalReview.Branch)"
            )) {
            $apiState.HistoricalEvidenceCalls.Add('branch-delete-lease')
            if (-not $commandText.Contains(
                "--force-with-lease=refs/heads/$($apiState.HistoricalReview.Branch):$($apiState.HistoricalReview.ReviewHead)"
            )) {
                throw 'TEST-0166 historical branch deletion omitted the exact expected-head lease.'
            }
            if ($apiState.HistoricalReview.BranchLeaseRace) {
                return [pscustomobject][ordered]@{
                    ExitCode = 1
                    Output = @('stale info')
                    Text = 'stale info'
                }
            }
            $apiState.HistoricalReview.BranchExists = $false
            $apiState.HistoricalMutationCalls.Add('DeleteHistoricalBranch')
            ''
        }
        elseif ($workingRoot -ceq $fixtureRoot -and
            $Arguments -contains 'push' -and
            $commandText.Contains(
                ':refs/heads/automation/meandai-capability-review-'
            )) {
            $currentBranch = 'automation/meandai-capability-review-' +
                $releaseCatalog.CatalogDigest.Substring(0, 16)
            if (-not $commandText.Contains(
                "--force-with-lease=refs/heads/$currentBranch`:$($apiState.BranchHead)"
            )) {
                throw 'TEST-0140 capability branch deletion omitted the exact expected-head lease.'
            }
            $apiState.BranchCreated = $false
            ''
        }
        elseif ($Arguments -contains 'merge-base') {
            if ($null -ne $apiState.HistoricalReview -and
                ($Arguments -contains $apiState.HistoricalReview.MergeCommit) -and
                $apiState.HistoricalReview.DefaultContainmentFailure) {
                return [pscustomobject][ordered]@{
                    ExitCode = 1
                    Output = @()
                    Text = ''
                }
            }
            return [pscustomobject][ordered]@{
                ExitCode = 0
                Output = @()
                Text = ''
            }
        }
        else {
            throw "TEST-0140 unexpected fixture Git call: $($Arguments -join ' ')"
        }
        return [pscustomobject][ordered]@{
            ExitCode = 0
            Output = @($text)
            Text = $text
        }
    }.GetNewClosure()
    $githubRuntime = {
        param(
            [string]$Method,
            [string]$Endpoint,
            $Body,
            [bool]$AcceptNotFound,
            [string]$Authority
        )
        $apiState.Calls.Add("$Authority $Method $Endpoint")
        $issueEndpoint = $Endpoint -match '^repos/hasanmanzak/consumer/issues(?:[/?]|$)'
        $protocolEndpoint =
            $Endpoint -match '^repos/hasanmanzak/meAndAI/(?:releases|commits)(?:[/?]|$)'
        if ($protocolEndpoint -and $Authority -cne 'Protocol') {
            throw "TEST-0166 protocol endpoint used '$Authority' authority: $Endpoint"
        }
        if (-not $protocolEndpoint -and
            $issueEndpoint -and $Authority -cne 'Issue') {
            throw "TEST-0140 issue endpoint used '$Authority' authority: $Endpoint"
        }
        if (-not $protocolEndpoint -and -not $issueEndpoint -and
            $Authority -cne 'Proposal') {
            throw "TEST-0140 proposal endpoint used '$Authority' authority: $Endpoint"
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/hasanmanzak/meAndAI/releases/tags/') {
            if ($null -eq $apiState.HistoricalReview) {
                throw 'TEST-0166 historical release evidence was requested without a scenario.'
            }
            $apiState.HistoricalEvidenceCalls.Add('immutable-release')
            return [pscustomobject]@{
                tag_name = [string]$apiState.HistoricalReview.ProtocolTag
                draft = $false
                prerelease = $false
                immutable = -not $apiState.HistoricalReview.ReleaseNotImmutable
                published_at = '2026-07-19T00:00:00Z'
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -ceq 'repos/hasanmanzak/consumer') {
            return [pscustomobject]@{
                id = 100
                full_name = 'hasanmanzak/consumer'
                default_branch = 'main'
                owner = $apiState.RepositoryOwner
            }
        }
        if ($Method -ceq 'GET' -and $Endpoint -ceq 'user') {
            return $apiState.ProposalActor
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -ceq 'users/github-actions%5Bbot%5D') {
            return $apiState.IssueActor
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/branches/main$') {
            $apiState.DefaultHeadReadCount++
            $reportedHead = if (
                $apiState.DriftDefaultHeadAfterReadCount -gt 0 -and
                $apiState.DefaultHeadReadCount -gt
                    $apiState.DriftDefaultHeadAfterReadCount
            ) {
                '9' * 40
            }
            else {
                [string]$apiState.DefaultHead
            }
            return [pscustomobject]@{
                commit = [pscustomobject]@{ sha = $reportedHead }
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/issues\?state=all') {
            $items = [System.Collections.Generic.List[object]]::new()
            foreach ($foreignIssue in @($apiState.ForeignIssues)) {
                $items.Add($foreignIssue)
            }
            if ($apiState.IssueCreated) {
                $items.Add([pscustomobject]@{
                    number = 91
                    state = if ($apiState.IssueClosed) {
                        'closed'
                    } else {
                        'open'
                    }
                    body = $apiState.IssueBody
                    user = $apiState.IssueActor
                })
            }
            if ($null -ne $apiState.HistoricalReview) {
                for ($copy = 0; $copy -lt
                    $apiState.HistoricalReview.IssueCopies; $copy++) {
                    $items.Add([pscustomobject]@{
                        number = [long]$apiState.HistoricalReview.IssueNumber +
                            $copy
                        state = if ($apiState.HistoricalReview.IssueClosed) {
                            'closed'
                        } else {
                            'open'
                        }
                        body = [string]$apiState.HistoricalReview.IssueBody
                        user = $apiState.IssueActor
                    })
                }
            }
            return @($items)
        }
        if ($Method -ceq 'GET' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/issues/$($apiState.HistoricalReview.IssueNumber)/comments\?") {
            return @($apiState.HistoricalReview.ClosureComments)
        }
        if ($Method -ceq 'GET' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/issues/$($apiState.HistoricalReview.IssueNumber)$") {
            return [pscustomobject]@{
                number = [long]$apiState.HistoricalReview.IssueNumber
                state = if ($apiState.HistoricalReview.IssueClosed) {
                    'closed'
                } else {
                    'open'
                }
                body = [string]$apiState.HistoricalReview.IssueBody
                user = $apiState.IssueActor
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/issues/91/comments\?') {
            return @($apiState.ClosureComments)
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/issues/91$') {
            return [pscustomobject]@{
                number = 91
                state = if ($apiState.IssueClosed) { 'closed' } else { 'open' }
                body = $apiState.IssueBody
                user = $apiState.IssueActor
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/git/ref/heads/') {
            if ($null -ne $apiState.HistoricalReview -and
                $Endpoint.EndsWith(
                    [Uri]::EscapeDataString(
                        [string]$apiState.HistoricalReview.Branch
                    )
                )) {
                if ($apiState.HistoricalReview.BranchExists) {
                    return [pscustomobject]@{
                        object = [pscustomobject]@{
                            sha = [string]$apiState.HistoricalReview.ReviewHead
                        }
                    }
                }
                return $null
            }
            if ($apiState.BranchCreated) {
                return [pscustomobject]@{
                    object = [pscustomobject]@{
                        sha = $apiState.BranchHead
                    }
                }
            }
            return $null
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/pulls\?state=all') {
            $pullItems = [System.Collections.Generic.List[object]]::new()
            if ($null -ne $apiState.HistoricalReview) {
                for ($copy = 0; $copy -lt
                    $apiState.HistoricalReview.PullCopies; $copy++) {
                    $historicalState =
                        [string]$apiState.HistoricalReview.PullState
                    $pullItems.Add([pscustomobject]@{
                        number = [long]$apiState.HistoricalReview.PullNumber +
                            $copy
                        state = if ($historicalState -ceq 'Open') {
                            'open'
                        } else {
                            'closed'
                        }
                        merged_at = if ($historicalState -ceq 'Merged') {
                            '2026-07-19T00:01:00Z'
                        } else {
                            $null
                        }
                        merge_commit_sha = if (
                            $historicalState -ceq 'Merged'
                        ) {
                            [string]$apiState.HistoricalReview.MergeCommit
                        } else {
                            $null
                        }
                        draft = $historicalState -ceq 'Open'
                        body = [string]$apiState.HistoricalReview.PullBody
                        head = [pscustomobject]@{
                            ref = [string]$apiState.HistoricalReview.Branch
                            sha = [string]$apiState.HistoricalReview.ReviewHead
                            repo = [pscustomobject]@{
                                full_name = 'hasanmanzak/consumer'
                            }
                        }
                        base = [pscustomobject]@{ ref = 'main' }
                        user = $apiState.ProposalActor
                    })
                }
            }
            if ($apiState.PullCreated) {
                $pullItems.Add([pscustomobject]@{
                    number = 92
                    state = if ($apiState.PullMerged) { 'closed' } else { 'open' }
                    merged_at = if ($apiState.PullMerged) {
                        '2026-07-19T00:01:00Z'
                    } else {
                        $null
                    }
                    merge_commit_sha = if ($apiState.PullMerged) {
                        [string]$apiState.MergeCommit
                    } else {
                        $null
                    }
                    draft = -not $apiState.PullMerged
                    body = $apiState.PullBody.body
                    head = [pscustomobject]@{
                        ref = [string]$apiState.PullBody.head
                        sha = $apiState.BranchHead
                        repo = [pscustomobject]@{
                            full_name = [string]$apiState.PullHeadRepository
                        }
                    }
                    base = [pscustomobject]@{
                        ref = [string]$apiState.PullBody.base
                    }
                    user = $apiState.ProposalActor
                })
            }
            return @($pullItems)
        }
        if ($Method -ceq 'GET' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/pulls/$($apiState.HistoricalReview.PullNumber)/reviews\?") {
            return @($apiState.HistoricalReview.Reviews)
        }
        if ($Method -ceq 'GET' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/issues/$($apiState.HistoricalReview.PullNumber)/comments\?") {
            return @($apiState.HistoricalReview.AttestationComments)
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/pulls/92/reviews\?') {
            return @($apiState.Reviews)
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/issues/92/comments\?') {
            $page = if ($Endpoint -match '[?&]page=(?<page>[1-9][0-9]*)') {
                [int]$Matches.page
            }
            else {
                1
            }
            $start = ($page - 1) * 100
            if ($start -ge $apiState.AttestationComments.Count) {
                return @()
            }
            $end = [Math]::Min(
                $start + 99,
                $apiState.AttestationComments.Count - 1
            )
            return @($apiState.AttestationComments[$start..$end])
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/collaborators/consumer-maintainer/permission$') {
            return [pscustomobject]@{
                permission = [string]$apiState.ReviewerPermission
                user = $apiState.PermissionActor
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/collaborators/meandai-bot/permission$') {
            return [pscustomobject]@{
                permission = [string]$apiState.OwnerPermission
                user = $apiState.OwnerPermissionActor
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/pulls/92/commits\?') {
            return @(
                [pscustomobject]@{ sha = ('4' * 40) },
                [pscustomobject]@{ sha = [string]$apiState.BranchHead }
            )
        }
        if ($Method -ceq 'GET' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/pulls/$($apiState.HistoricalReview.PullNumber)/commits\?") {
            return @(
                [pscustomobject]@{
                    sha = [string]$apiState.HistoricalReview.HandoffHead
                },
                [pscustomobject]@{
                    sha = [string]$apiState.HistoricalReview.ReviewHead
                }
            )
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/contents/(?<path>[^?]+)\?ref=(?<ref>[0-9a-f]{40})$') {
            $path = [string]$Matches.path
            $ref = [string]$Matches.ref
            if ($null -ne $apiState.HistoricalReview) {
                $historical = $apiState.HistoricalReview
                if ($path -ceq '.ai/adoption/meandai-capability-review.json') {
                    if ($ref -ceq [string]$historical.HandoffHead) {
                        return [pscustomobject]@{
                            type = 'file'
                            sha = ('8' * 40)
                            encoding = 'base64'
                            content = [Convert]::ToBase64String(
                                [byte[]]$historical.ManifestBytes
                            )
                        }
                    }
                    if ($historical.ManifestOnReviewedTree -and
                        ($ref -ceq [string]$historical.ReviewHead -or
                         $ref -ceq [string]$historical.MergeCommit -or
                         $ref -ceq [string]$apiState.DefaultHead)) {
                        return [pscustomobject]@{
                            type = 'file'
                            sha = ('8' * 40)
                            encoding = 'base64'
                            content = [Convert]::ToBase64String(
                                [byte[]]$historical.ManifestBytes
                            )
                        }
                    }
                    if (@(
                        [string]$historical.BaseHead,
                        [string]$historical.ReviewHead,
                        [string]$historical.MergeCommit,
                        [string]$apiState.DefaultHead
                    ) -ccontains $ref) {
                        return $null
                    }
                }
                if ($path -ceq '.ai/meandai-capabilities-state.json') {
                    if ($ref -ceq [string]$historical.BaseHead -or
                        $ref -ceq [string]$historical.HandoffHead) {
                        return $null
                    }
                    if (@(
                        [string]$historical.ReviewHead,
                        [string]$historical.MergeCommit,
                        [string]$apiState.DefaultHead
                    ) -ccontains $ref) {
                        $historicalLedger = if (
                            $historical.ReviewTreeLedgerMismatch -and
                            $ref -ceq [string]$historical.ReviewHead
                        ) {
                            [Text.UTF8Encoding]::new($false).GetBytes(
                                '{"schema":1,"assessments":[]}' + "`n"
                            )
                        }
                        elseif ($ref -ceq [string]$apiState.DefaultHead) {
                            [byte[]]$historical.CurrentLedgerBytes
                        }
                        else {
                            [byte[]]$historical.HistoricalLedgerBytes
                        }
                        return [pscustomobject]@{
                            type = 'file'
                            sha = ('7' * 40)
                            encoding = 'base64'
                            content = [Convert]::ToBase64String(
                                $historicalLedger
                            )
                        }
                    }
                }
            }
            $handoffHead = '4' * 40
            $reviewedTree = $ref -ceq [string]$apiState.BranchHead -and
                $apiState.PullMerged
            if ($path -ceq '.ai/adoption/meandai-capability-review.json') {
                $manifestExists = $ref -ceq $handoffHead -or
                    ($apiState.ForceManifestOnReviewedTree -and $reviewedTree)
                if ($manifestExists -and $null -ne $apiState.BlobBody) {
                    return [pscustomobject]@{
                        type = 'file'
                        sha = ('1' * 40)
                        encoding = 'base64'
                        content = [string]$apiState.BlobBody.content
                    }
                }
                return $null
            }
            if ($path -ceq '.ai/meandai-capabilities-state.json') {
                if ($ref -ceq $fixtureHead -or $ref -ceq $handoffHead) {
                    return $null
                }
                if ($null -eq $apiState.FinalLedgerBytes) {
                    return $null
                }
                $ledgerContent = if ($apiState.ForceLedgerMismatch -and
                    $reviewedTree) {
                    [Text.UTF8Encoding]::new($false).GetBytes(
                        '{"schema":1,"assessments":[]}' + "`n"
                    )
                }
                else {
                    [byte[]]$apiState.FinalLedgerBytes
                }
                return [pscustomobject]@{
                    type = 'file'
                    sha = ('7' * 40)
                    encoding = 'base64'
                    content = [Convert]::ToBase64String($ledgerContent)
                }
            }
            throw "TEST-0140 unexpected fixture content path: $path"
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/git/refs$') {
            $apiState.BranchCreated = $true
            return [pscustomobject]@{
                ref = "refs/heads/automation/meandai-capability-review-$($releaseCatalog.CatalogDigest.Substring(0, 16))"
                object = [pscustomobject]@{ sha = $fixtureHead }
            }
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/issues$') {
            $apiState.IssueCreated = $true
            $apiState.IssueBody = [string]$Body.body
            return [pscustomobject]@{
                number = 91
                body = [string]$Body.body
                user = $apiState.IssueActor
            }
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/git/blobs$') {
            $apiState.BlobBody = $Body
            return [pscustomobject]@{ sha = ('1' * 40) }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/git/commits/') {
            if ($null -ne $apiState.HistoricalReview -and
                $Endpoint.EndsWith(
                    [string]$apiState.HistoricalReview.HandoffHead
                )) {
                return [pscustomobject]@{
                    tree = [pscustomobject]@{ sha = ('2' * 40) }
                    parents = @(
                        [pscustomobject]@{
                            sha = [string]$apiState.HistoricalReview.BaseHead
                        }
                    )
                }
            }
            return [pscustomobject]@{
                tree = [pscustomobject]@{ sha = ('2' * 40) }
                parents = @(
                    [pscustomobject]@{ sha = $fixtureHead }
                )
            }
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/git/trees$') {
            $apiState.TreeBody = $Body
            return [pscustomobject]@{ sha = ('3' * 40) }
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/git/commits$') {
            $apiState.CommitBody = $Body
            return [pscustomobject]@{
                sha = ('4' * 40)
                parents = @(
                    [pscustomobject]@{ sha = [string]$Body.parents[0] }
                )
            }
        }
        if ($Method -ceq 'PATCH' -and
            $Endpoint -match '^repos/.+/git/refs/heads/') {
            $apiState.BranchHead = [string]$Body.sha
            return [pscustomobject]@{
                object = [pscustomobject]@{ sha = [string]$Body.sha }
            }
        }
        if ($Method -ceq 'GET' -and
            $Endpoint -match '^repos/.+/compare/') {
            return [pscustomobject]@{
                files = @(
                    [pscustomobject]@{
                        filename = '.ai/adoption/meandai-capability-review.json'
                    }
                )
            }
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/pulls$') {
            $apiState.PullCreated = $true
            $apiState.PullBody = $Body
            return [pscustomobject]@{
                number = 92
                draft = $true
                body = [string]$Body.body
                user = $apiState.ProposalActor
                head = [pscustomobject]@{
                    sha = ('4' * 40)
                    ref = [string]$Body.head
                    repo = [pscustomobject]@{
                        full_name = 'hasanmanzak/consumer'
                    }
                }
                base = [pscustomobject]@{
                    ref = [string]$Body.base
                }
            }
        }
        if ($Method -ceq 'DELETE' -and
            $Endpoint -match '^repos/.+/git/ref/heads/') {
            if ($null -ne $apiState.HistoricalReview -and
                $Endpoint.EndsWith(
                    [Uri]::EscapeDataString(
                        [string]$apiState.HistoricalReview.Branch
                    )
                )) {
                throw 'TEST-0166 historical branch deletion bypassed the Git expected-head lease.'
            }
            $apiState.BranchCreated = $false
            return $null
        }
        if ($Method -ceq 'POST' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/issues/$($apiState.HistoricalReview.IssueNumber)/comments$") {
            $comment = [pscustomobject]@{
                body = [string]$Body.body
                user = $apiState.IssueActor
            }
            $apiState.HistoricalReview.ClosureComments.Add($comment)
            $apiState.HistoricalMutationCalls.Add('CommentHistoricalIssue')
            return $comment
        }
        if ($Method -ceq 'PATCH' -and
            $null -ne $apiState.HistoricalReview -and
            $Endpoint -match "^repos/.+/issues/$($apiState.HistoricalReview.IssueNumber)$") {
            $apiState.HistoricalReview.IssueClosed =
                [string]$Body.state -ceq 'closed'
            $apiState.HistoricalMutationCalls.Add('CloseHistoricalIssue')
            return [pscustomobject]@{
                number = [long]$apiState.HistoricalReview.IssueNumber
                state = [string]$Body.state
                body = [string]$apiState.HistoricalReview.IssueBody
            }
        }
        if ($Method -ceq 'POST' -and
            $Endpoint -match '^repos/.+/issues/91/comments$') {
            $comment = [pscustomobject]@{
                body = [string]$Body.body
                user = $apiState.IssueActor
            }
            $apiState.ClosureComments.Add($comment)
            return $comment
        }
        if ($Method -ceq 'PATCH' -and
            $Endpoint -match '^repos/.+/issues/91$') {
            $apiState.IssueClosed = [string]$Body.state -ceq 'closed'
            return [pscustomobject]@{
                number = 91
                state = [string]$Body.state
                body = $apiState.IssueBody
            }
        }
        throw "TEST-0140 unexpected fixture GitHub call: $Method $Endpoint"
    }.GetNewClosure()
    $executeResult = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    Assert-Equal $executeResult.Mode 'Execute' `
        'TEST-0140 injected production runner did not execute.'
    Assert-Equal ($executeResult.Execution.Executed -join ',') `
        'CreateBranch,OpenIssue,WriteReviewManifest,OpenDraftPullRequest' `
        'TEST-0140 injected production effects changed branch-first order.'
    Assert-Equal @($apiState.TreeBody.tree).Count 1 `
        'TEST-0140 production manifest commit contained multiple tree entries.'
    Assert-Equal ([string]$apiState.TreeBody.tree[0].path) `
        '.ai/adoption/meandai-capability-review.json' `
        'TEST-0140 production manifest commit targeted another path.'
    Assert-True ([bool]$apiState.PullBody.draft) `
        'TEST-0140 production handoff did not open a draft pull request.'
    Assert-True ($apiState.IssueBody.Contains('Proposal actor ID: `101`') -and
        $apiState.IssueBody.Contains('Issue actor ID: `41898282`') -and
        $apiState.PullBody.body.Contains('Proposal actor login: `meandai-bot`') -and
        $apiState.PullBody.body.Contains('Issue actor login: `github-actions[bot]`')) `
        'TEST-0140 canonical handoff did not bind distinct proposal and issue actors.'
    $createdManifest = (
        [Text.UTF8Encoding]::new($false, $true).GetString(
            [Convert]::FromBase64String([string]$apiState.BlobBody.content)
        ) | ConvertFrom-Json
    )
    Assert-True ([long]$createdManifest.proposalActorId -eq 101 -and
        [long]$createdManifest.issueActorId -eq 41898282) `
        'TEST-0140 transient manifest lost dual-actor provenance.'
    Assert-True (-not (Test-Path -LiteralPath (
        Join-Path $fixtureRoot '.ai'
    ))) 'TEST-0140 production handoff wrote the local consumer checkout.'

    $rerunResult = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
        -PlanOnly
    Assert-Equal $rerunResult.State 'ReviewPending' `
        'TEST-0140 production inventory did not reuse the exact pending review.'
    Assert-Equal $rerunResult.Plan.Operations.Count 0 `
        'TEST-0140 production pending rerun planned duplicate work.'

    $apiState.ForeignIssues.Add([pscustomobject]@{
        number = 666
        state = 'open'
        body = $apiState.IssueBody
        user = [pscustomobject]@{ id = 999; login = 'public-forger' }
    })
    $forgedMarkerResult = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
        -PlanOnly
    Assert-Equal $forgedMarkerResult.State 'ReviewPending' `
        'TEST-0140 an untrusted public issue marker displaced canonical inventory.'
    $apiState.ForeignIssues.Clear()

    $apiState.ClosureComments.Add([pscustomobject]@{
        body = "<!-- meandai-capability-review-closed:v1:hasanmanzak/consumer:$($releaseCatalog.CatalogDigest):pr-92:merge-$('5' * 40) -->"
        user = [pscustomobject]@{ id = 999; login = 'public-forger' }
    })
    $forgedCommentResult = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
        -PlanOnly
    Assert-Equal $forgedCommentResult.State 'ReviewPending' `
        'TEST-0140 an untrusted public closure marker changed lifecycle state.'
    $apiState.ClosureComments.Clear()

    $canonicalIssueBody = [string]$apiState.IssueBody
    $apiState.IssueBody = $canonicalIssueBody + "unexpected`n"
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*exact canonical handoff content*' `
        -Message 'TEST-0140 reused issue body accepted noncanonical drift.'
    $apiState.IssueBody = $canonicalIssueBody

    $canonicalManifestContent = [string]$apiState.BlobBody.content
    $apiState.BlobBody.content = [Convert]::ToBase64String(
        [Text.UTF8Encoding]::new($false).GetBytes("{}`n")
    )
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*unsupported property set*' `
        -Message 'TEST-0140 reused manifest accepted noncanonical drift.'
    $apiState.BlobBody.content = $canonicalManifestContent

    $apiState.PullHeadRepository = 'public-forger/fork'
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*noncanonical branch*' `
        -Message 'TEST-0140 canonical PR accepted another head repository.'
    $apiState.PullHeadRepository = 'hasanmanzak/consumer'

    $apiState.DirtyManagedPaths = $true
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*dirty outside exact HEAD*' `
        -Message 'TEST-0140 dirty managed checkout reached remote review state.'
    $apiState.DirtyManagedPaths = $false

    $finalPullNumber = 92
    $handoffHead = '4' * 40
    $finalReviewHead = '6' * 40
    $finalMergeCommit = '5' * 40
    $finalEntry = New-MeAndAICapabilityLedgerEntry `
        -Capability $releaseCatalog.Capabilities[0] -Outcome Conforming `
        -Evidence @('Reviewed fixture-safe production runner evidence.') `
        -ReviewIdentity "pull-request:$finalPullNumber" `
        -ReviewAuthority "https://github.com/hasanmanzak/consumer/pull/$finalPullNumber" `
        -ReviewedAt '2026-07-19T00:00:00Z'
    $finalEfficiencyEntry = New-MeAndAICapabilityLedgerEntry `
        -Capability $releaseCatalog.Capabilities[1] -Outcome Conforming `
        -Evidence @('Reviewed reuse-first fixture and operation-budget evidence.') `
        -ReviewIdentity "pull-request:$finalPullNumber" `
        -ReviewAuthority "https://github.com/hasanmanzak/consumer/pull/$finalPullNumber" `
        -ReviewedAt '2026-07-19T00:00:00Z'
    $finalLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
        -Catalog $releaseCatalog -Entries @($finalEntry, $finalEfficiencyEntry)
    $apiState.FinalLedgerBytes = [byte[]]$finalLedgerBytes
    $fixtureAiRoot = Join-Path $fixtureRoot '.ai'
    [void](New-Item -ItemType Directory -Path $fixtureAiRoot)
    [IO.File]::WriteAllBytes(
        (Join-Path $fixtureAiRoot 'meandai-capabilities-state.json'),
        $finalLedgerBytes
    )
    $finalMarker = Get-MeAndAICapabilityReviewMarker `
        -Repository 'hasanmanzak/consumer' `
        -CatalogDigest $releaseCatalog.CatalogDigest
    $finalBranch = 'automation/meandai-capability-review-' +
        $releaseCatalog.CatalogDigest.Substring(0, 16)
    $finalBinding = [pscustomobject][ordered]@{
        CatalogDigest = $releaseCatalog.CatalogDigest
        BatchDigest = $runnerResult.Plan.BatchDigest
        BaseBranch = 'main'
        BaseHead = $fixtureHead
        BaseLedgerDigest = 'missing'
        Branch = $finalBranch
        HandoffHead = $handoffHead
        LedgerPrefixCount = 0
        ProposalActorId = 1
        ProposalActorLogin = 'fixture-proposal'
        IssueActorId = 2
        IssueActorLogin = 'fixture-issue'
        IssueNumber = 91
    }
    $finalIssue = [pscustomobject][ordered]@{
        Number = 91
        State = 'Open'
        Marker = $finalMarker
        ClosureMarker = ''
        Binding = $finalBinding
    }
    $finalBranchRecord = [pscustomobject][ordered]@{
        Name = $finalBranch
        BaseHead = $fixtureHead
        HeadSha = $finalReviewHead
        Marker = $finalMarker
    }
    $finalPull = [pscustomobject][ordered]@{
        Number = $finalPullNumber
        State = 'Merged'
        IsDraft = $false
        Marker = $finalMarker
        HeadBranch = $finalBranch
        HeadSha = $finalReviewHead
        BaseBranch = 'main'
        BaseHead = $fixtureHead
        IssueNumber = 91
        MergeCommit = $finalMergeCommit
        Binding = $finalBinding
    }
    $finalFixture = [pscustomobject][ordered]@{
        CurrentDefaultHead = $fixtureHead
        ReviewBaseHead = $fixtureHead
        Issues = @($finalIssue)
        Branches = @($finalBranchRecord)
        PullRequests = @($finalPull)
        Manifests = @()
        Binding = $finalBinding
        DefaultContainsMerge = $true
        ManifestPresentOnDefault = $false
        Reviewed = $true
    }
    $finalResult = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -DefaultHead $fixtureHead `
        -TargetVersion v0.12.0 -DiscoveryContext AlreadyCurrent `
        -Runtime $forbiddenRuntime -FixtureInventory $finalFixture `
        -PlanOnly
    Assert-Equal $finalResult.State 'Finalize' `
        'TEST-0140 fixture-safe runner did not verify merged finalization.'
    Assert-Equal ($finalResult.Plan.Operations.Kind -join ',') `
        'DeleteBranch,CloseIssue' `
        'TEST-0140 production finalization changed branch-first/issue-last order.'

    $apiState.PullMerged = $true
    $apiState.BranchHead = $finalReviewHead
    $apiState.DefaultHead = $finalMergeCommit
    $apiState.Reviews[0].commit_id = $finalReviewHead
    $apiState.PermissionActor = [pscustomobject]@{
        id = 203
        login = 'consumer-maintainer'
    }
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    } -Pattern '*permission resolved another actor*' `
        -Message 'TEST-0140 reviewer permission identity was not bound to approval actor ID.'
    $apiState.PermissionActor = $apiState.ReviewerActor

    $apiState.ReviewerPermission = 'read'
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    } -Pattern '*trusted maintainer approval*' `
        -Message 'TEST-0140 read-only approval authorized merged finalization.'
    $apiState.ReviewerPermission = 'write'

    $apiState.Calls.Clear()
    $approvedPlan = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -FinalizePullRequestNumber $finalPullNumber `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
        -PlanOnly
    Assert-Equal $approvedPlan.State 'Finalize' `
        'TEST-0163 independent exact-head approval no longer finalizes.'
    Assert-Equal @($apiState.Calls | Where-Object {
        $_ -match 'issues/92/comments'
    }).Count 0 `
        'TEST-0163 independent approval unnecessarily read owner attestations.'

    $ownerAttestationMarker =
        "<!-- meandai-capability-review-attestation:v1:hasanmanzak/consumer:pr-92:head-$finalReviewHead -->"
    $ownerAttestationBody = $ownerAttestationMarker + ' ' +
        'I reviewed the semantic capability changes at this exact pull-request head and attest that they are ready for finalization.'

    $apiState.Reviews[0].commit_id = '7' * 40
    $apiState.AttestationComments.Add([pscustomobject]@{
        body = $ownerAttestationBody
        user = $apiState.ProposalActor
    })
    $apiState.Calls.Clear()
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*approval for the exact review head*' `
        -Message 'TEST-0163 stale review submission fell through to owner attestation.'
    Assert-Equal @($apiState.Calls | Where-Object {
        $_ -match 'issues/92/comments'
    }).Count 0 `
        'TEST-0163 nonempty review collection read owner attestations.'
    $apiState.Reviews[0].commit_id = $finalReviewHead
    $apiState.Reviews[0].user = $apiState.ProposalActor
    $apiState.Calls.Clear()
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*trusted maintainer approval*' `
        -Message 'TEST-0163 creator-authored review fell through to owner attestation.'
    Assert-Equal @($apiState.Calls | Where-Object {
        $_ -match 'issues/92/comments'
    }).Count 0 `
        'TEST-0163 creator-authored review read owner attestations.'
    $apiState.Reviews[0].user = $apiState.ReviewerActor
    $apiState.AttestationComments.Clear()

    $apiState.Reviews.Clear()
    for ($index = 0; $index -lt 100; $index++) {
        $apiState.AttestationComments.Add([pscustomobject]@{
            body = "Ordinary review discussion $index"
            user = $apiState.ProposalActor
        })
    }
    $apiState.AttestationComments.Add([pscustomobject]@{
        body = $ownerAttestationBody
        user = $apiState.ProposalActor
    })
    $attestedPlan = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -FinalizePullRequestNumber $finalPullNumber `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
        -PlanOnly
    Assert-Equal $attestedPlan.State 'Finalize' `
        'TEST-0163 canonical personal-owner attestation did not authorize the exact merged head.'
    Assert-True @($apiState.Calls | Where-Object {
        $_ -match 'issues/92/comments.*page=2'
    }).Count -gt 0 `
        'TEST-0163 exact owner attestation was not discovered after a full first page.'

    $apiState.AttestationComments.Clear()
    $apiState.AttestationComments.Add([pscustomobject]@{
        body = $ownerAttestationBody
        user = $apiState.ProposalActor
    })

    $apiState.AttestationComments[0].body =
        $ownerAttestationBody.Replace($finalReviewHead, ('7' * 40))
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*exact-head personal-owner attestation*' `
        -Message 'TEST-0163 stale owner attestation authorized another review head.'
    foreach ($wrongBinding in @(
        $ownerAttestationBody.Replace(
            'hasanmanzak/consumer',
            'hasanmanzak/another-consumer'
        ),
        $ownerAttestationBody.Replace(':pr-92:', ':pr-93:')
    )) {
        $apiState.AttestationComments[0].body = $wrongBinding
        Assert-ThrowsLike -Action {
            & $runnerPath -ConsumerRoot $fixtureRoot `
                -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
                -DefaultBranch main -TargetVersion v0.12.0 `
                -DiscoveryContext AlreadyCurrent `
                -FinalizePullRequestNumber $finalPullNumber `
                -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
                -PlanOnly
        } -Pattern '*exact-head personal-owner attestation*' `
            -Message 'TEST-0163 wrong repository or pull-request attestation binding was accepted.'
    }
    $apiState.AttestationComments[0].body =
        $ownerAttestationMarker + "`nnoncanonical trusted content`n"
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*not exact canonical evidence*' `
        -Message 'TEST-0163 trusted owner marker accepted noncanonical comment bytes.'
    $apiState.AttestationComments[0].body = $ownerAttestationBody
    $apiState.AttestationComments.Add([pscustomobject]@{
        body = $ownerAttestationBody
        user = $apiState.ProposalActor
    })
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*duplicate or conflicting*' `
        -Message 'TEST-0163 duplicate trusted owner attestations were accepted.'
    $apiState.AttestationComments.RemoveAt(1)

    $apiState.OwnerPermission = 'write'
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*exact-head personal-owner attestation*' `
        -Message 'TEST-0163 non-admin owner attestation authorized finalization.'
    $apiState.OwnerPermission = 'admin'

    $apiState.RepositoryOwner.type = 'Organization'
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*exact-head personal-owner attestation*' `
        -Message 'TEST-0163 organization-owned repository accepted personal-owner fallback.'
    $apiState.RepositoryOwner.type = 'User'

    $apiState.RepositoryOwner = [pscustomobject]@{
        id = 404
        login = 'another-owner'
        type = 'User'
    }
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*exact-head personal-owner attestation*' `
        -Message 'TEST-0163 repository owner and pull-request creator mismatch authorized fallback.'
    $apiState.RepositoryOwner = [pscustomobject]@{
        id = 101
        login = 'meandai-bot'
        type = 'User'
    }

    $apiState.OwnerPermissionActor = [pscustomobject]@{
        id = 303
        login = 'meandai-bot'
    }
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*permission resolved another actor*' `
        -Message 'TEST-0163 owner permission identity drift authorized finalization.'
    $apiState.OwnerPermissionActor = $apiState.ProposalActor

    $apiState.AttestationComments[0].user = [pscustomobject]@{
        id = 999
        login = 'public-forger'
    }
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
            -PlanOnly
    } -Pattern '*exact-head personal-owner attestation*' `
        -Message 'TEST-0163 untrusted comment author authorized owner attestation.'
    $apiState.AttestationComments[0].user = $apiState.ProposalActor

    $apiState.Reviews.Add([pscustomobject]@{
        state = 'APPROVED'
        commit_id = [string]$apiState.BranchHead
        submitted_at = '2026-07-19T00:00:30Z'
        user = $apiState.ReviewerActor
    })
    $apiState.AttestationComments.Clear()

    $apiState.ForceLedgerMismatch = $true
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    } -Pattern '*review head capability ledger*' `
        -Message 'TEST-0140 out-of-band ledger replacement passed reviewed-tree proof.'
    $apiState.ForceLedgerMismatch = $false

    $trustedClosureMarker = [string]$finalResult.Plan.ClosureMarker
    $apiState.ClosureComments.Add([pscustomobject]@{
        body = "$trustedClosureMarker`nnoncanonical trusted content`n"
        user = $apiState.IssueActor
    })
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    } -Pattern '*not exact canonical evidence*' `
        -Message 'TEST-0140 trusted closure marker accepted noncanonical comment bytes.'
    $apiState.ClosureComments.Clear()

    $apiState.DriftDefaultHeadAfterReadCount =
        $apiState.DefaultHeadReadCount + 1
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot `
            -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
            -DefaultBranch main -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -FinalizePullRequestNumber $finalPullNumber `
            -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    } -Pattern '*Default branch changed after capability finalization proof*' `
        -Message 'TEST-0140 default-head race reached branch or issue mutation.'
    Assert-True $apiState.BranchCreated `
        'TEST-0140 default-head race deleted the reviewed branch.'
    Assert-True (-not $apiState.IssueClosed) `
        'TEST-0140 default-head race closed the capability issue.'
    $apiState.DriftDefaultHeadAfterReadCount = 0

    $apiState.Reviews.Clear()
    $apiState.AttestationComments.Add([pscustomobject]@{
        body = $ownerAttestationBody
        user = $apiState.ProposalActor
    })
    $finalizeExecution = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -FinalizePullRequestNumber $finalPullNumber `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime }
    Assert-Equal $finalizeExecution.State 'Finalize' `
        'TEST-0140 production runner did not enter verified finalization.'
    Assert-Equal ($finalizeExecution.Execution.Executed -join ',') `
        'DeleteBranch,CloseIssue' `
        'TEST-0140 production finalization executed out of order.'
    Assert-True (-not $apiState.BranchCreated) `
        'TEST-0140 production finalization left its exact branch.'
    Assert-True $apiState.IssueClosed `
        'TEST-0140 production finalization did not close its issue last.'
    Assert-Equal $apiState.ClosureComments.Count 1 `
        'TEST-0140 production finalization did not write one closure marker.'
    Assert-Equal (@($apiState.Calls | Where-Object {
        $_ -match 'issues/92/comments'
    }).Count -gt 0) $true `
        'TEST-0164 merged recovery did not use exact-head owner attestation evidence.'

    $completedExecution = & $runnerPath -ConsumerRoot $fixtureRoot `
        -ProtocolRoot $root -Repository 'hasanmanzak/consumer' `
        -DefaultBranch main -TargetVersion v0.12.0 `
        -DiscoveryContext AlreadyCurrent `
        -FinalizePullRequestNumber $finalPullNumber `
        -Runtime @{ Git = $gitRuntime; GitHub = $githubRuntime } `
        -PlanOnly
    Assert-Equal $completedExecution.State 'Completed' `
        'TEST-0140 production completed rerun was not recognized.'
    Assert-Equal $completedExecution.Plan.Operations.Count 0 `
        'TEST-0140 production completed rerun was not an exact no-op.'
    Assert-Equal $apiState.ClosureComments.Count 1 `
        'TEST-0140 completed rerun duplicated closure evidence.'

    # TEST-0165: a trusted historical review may be retired only after its
    # original release catalog is reconstructed from immutable repository
    # evidence. Recovery then performs one fresh current-catalog discovery.
    $historicalCatalogRoot = Join-Path $fixtureRoot 'historical-capabilities'
    [void](New-Item -ItemType Directory -Path $historicalCatalogRoot)
    $historicalDefinitionBytes = [IO.File]::ReadAllBytes(
        (Join-Path $root 'capabilities/test-architecture.json')
    )
    $historicalIndex = [ordered]@{
        schema = 1
        capabilities = @(
            [ordered]@{
                slug = 'test-architecture'
                definition = 'test-architecture.json'
                type = 'Semantic'
                definitionBlob = [string]$releaseCatalog.Capabilities[0].DefinitionBlob
            }
        )
    }
    $historicalCatalogBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        (($historicalIndex | ConvertTo-Json -Depth 10).Replace(
            "`r`n",
            "`n"
        ) + "`n")
    )
    [IO.File]::WriteAllBytes(
        (Join-Path $historicalCatalogRoot 'index.json'),
        $historicalCatalogBytes
    )
    [IO.File]::WriteAllBytes(
        (Join-Path $historicalCatalogRoot 'test-architecture.json'),
        $historicalDefinitionBytes
    )
    $historicalCatalog = Import-MeAndAICapabilityCatalog -IndexPath (
        Join-Path $historicalCatalogRoot 'index.json'
    )

    $alternateDefinitionText = (
        [Text.UTF8Encoding]::new($false, $true).GetString(
            $historicalDefinitionBytes
        )
    ).Replace(
        'Capability-based test architecture',
        'Incompatible historical test architecture'
    )
    $alternateDefinitionBytes =
        [Text.UTF8Encoding]::new($false).GetBytes($alternateDefinitionText)
    $alternateDefinitionBlob = Get-TestGitBlobSha -Bytes (
        $alternateDefinitionBytes
    )
    $alternateIndex = [ordered]@{
        schema = 1
        capabilities = @(
            [ordered]@{
                slug = 'test-architecture'
                definition = 'test-architecture.json'
                type = 'Semantic'
                definitionBlob = $alternateDefinitionBlob
            }
        )
    }
    $alternateCatalogBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        (($alternateIndex | ConvertTo-Json -Depth 10).Replace(
            "`r`n",
            "`n"
        ) + "`n")
    )
    $alternateCatalogRoot = Join-Path $fixtureRoot 'alternate-capabilities'
    [void](New-Item -ItemType Directory -Path $alternateCatalogRoot)
    [IO.File]::WriteAllBytes(
        (Join-Path $alternateCatalogRoot 'index.json'),
        $alternateCatalogBytes
    )
    [IO.File]::WriteAllBytes(
        (Join-Path $alternateCatalogRoot 'test-architecture.json'),
        $alternateDefinitionBytes
    )
    $alternateCatalog = Import-MeAndAICapabilityCatalog -IndexPath (
        Join-Path $alternateCatalogRoot 'index.json'
    )

    $historicalBaseHead = 'f' * 40
    $historicalHandoffHead = '8' * 40
    $historicalReviewHead = '9' * 40
    $historicalMergeCommit = 'a' * 40
    $historicalDefaultHead = 'b' * 40
    $historicalProtocolCommit = 'c' * 40
    $historicalIssueNumber = 93
    $historicalPullNumber = 94

    $newHistoricalReviewState = {
        param(
            [Parameter(Mandatory)]$SourceCatalog,
            [Parameter(Mandatory)][byte[]]$SourceCatalogBytes,
            [Parameter(Mandatory)][byte[]]$SourceDefinitionBytes
        )

        $sourceAssessment = Resolve-MeAndAICapabilityAssessment `
            -Capability $SourceCatalog.Capabilities[0] `
            -Applicability Unknown -Conformance Unknown `
            -AdoptionPlan Ambiguous
        $sourcePlan = Resolve-MeAndAICapabilityReview `
            -Catalog $SourceCatalog `
            -Ledger (Import-MeAndAICapabilityLedger `
                -Catalog $SourceCatalog -Bytes $null) `
            -Repository 'hasanmanzak/consumer' -DefaultBranch main `
            -DefaultHead $historicalBaseHead -TargetVersion v0.12.0 `
            -DiscoveryContext AlreadyCurrent `
            -Assessments @($sourceAssessment)
        $sourceIssueBody = New-TestCapabilityReviewBody `
            -Plan $sourcePlan -LedgerPrefixCount 0 `
            -ProposalActorId 101 -ProposalActorLogin 'meandai-bot' `
            -IssueActorId 41898282 `
            -IssueActorLogin 'github-actions[bot]'
        $sourcePullBody = New-TestCapabilityReviewBody `
            -Plan $sourcePlan -LedgerPrefixCount 0 `
            -ProposalActorId 101 -ProposalActorLogin 'meandai-bot' `
            -IssueActorId 41898282 `
            -IssueActorLogin 'github-actions[bot]' `
            -IssueNumber $historicalIssueNumber `
            -HandoffHead $historicalHandoffHead
        $manifest = [ordered]@{
            schema = 1
            marker = [string]$sourcePlan.Marker
            catalogDigest = [string]$sourcePlan.CatalogDigest
            batchDigest = [string]$sourcePlan.BatchDigest
            repository = 'hasanmanzak/consumer'
            baseBranch = 'main'
            baseHead = $historicalBaseHead
            baseLedgerDigest = 'missing'
            branch = [string]$sourcePlan.Branch
            issueNumber = $historicalIssueNumber
            ledgerPrefixCount = 0
            proposalActorId = 101
            proposalActorLogin = 'meandai-bot'
            issueActorId = 41898282
            issueActorLogin = 'github-actions[bot]'
            capabilities = @(
                [ordered]@{
                    slug = [string]$sourcePlan.CapabilityBatch[0].Slug
                    definitionBlob =
                        [string]$sourcePlan.CapabilityBatch[0].DefinitionBlob
                    type = [string]$sourcePlan.CapabilityBatch[0].Type
                    outcome = [string]$sourcePlan.CapabilityBatch[0].Outcome
                }
            )
        }
        $sourceManifestBytes = [Text.UTF8Encoding]::new($false).GetBytes(
            (($manifest | ConvertTo-Json -Compress -Depth 30) + "`n")
        )
        $sourceEntry = New-MeAndAICapabilityLedgerEntry `
            -Capability $SourceCatalog.Capabilities[0] -Outcome Conforming `
            -Evidence @('Reviewed project-neutral historical topology evidence.') `
            -ReviewIdentity "pull-request:$historicalPullNumber" `
            -ReviewAuthority "https://github.com/hasanmanzak/consumer/pull/$historicalPullNumber" `
            -ReviewedAt '2026-07-19T00:00:00Z'
        $sourceLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
            -Catalog $SourceCatalog -Entries @($sourceEntry)
        $currentPrefixEntry = New-MeAndAICapabilityLedgerEntry `
            -Capability $releaseCatalog.Capabilities[0] -Outcome Conforming `
            -Evidence @('Reviewed project-neutral historical topology evidence.') `
            -ReviewIdentity "pull-request:$historicalPullNumber" `
            -ReviewAuthority "https://github.com/hasanmanzak/consumer/pull/$historicalPullNumber" `
            -ReviewedAt '2026-07-19T00:00:00Z'
        $currentSuffixEntry = New-MeAndAICapabilityLedgerEntry `
            -Capability $releaseCatalog.Capabilities[1] -Outcome Conforming `
            -Evidence @('Reviewed appended current capability evidence.') `
            -ReviewIdentity 'pull-request:95' `
            -ReviewAuthority 'https://github.com/hasanmanzak/consumer/pull/95' `
            -ReviewedAt '2026-07-20T00:00:00Z'
        $currentLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
            -Catalog $releaseCatalog -Entries @(
                $currentPrefixEntry,
                $currentSuffixEntry
            )
        return [pscustomobject][ordered]@{
            CatalogBytes = $SourceCatalogBytes
            DefinitionBytes = $SourceDefinitionBytes
            VersionBytes = [Text.UTF8Encoding]::new($false).GetBytes(
                "0.12.0`n"
            )
            ProtocolCommit = $historicalProtocolCommit
            ProtocolTag = 'v0.12.0'
            BaseHead = $historicalBaseHead
            HandoffHead = $historicalHandoffHead
            ReviewHead = $historicalReviewHead
            MergeCommit = $historicalMergeCommit
            Branch = [string]$sourcePlan.Branch
            IssueNumber = $historicalIssueNumber
            PullNumber = $historicalPullNumber
            IssueBody = $sourceIssueBody
            PullBody = $sourcePullBody
            ManifestBytes = $sourceManifestBytes
            HistoricalLedgerBytes = [byte[]]$sourceLedgerBytes
            CurrentLedgerBytes = [byte[]]$currentLedgerBytes
            IssueCopies = 1
            PullCopies = 1
            IssueClosed = $false
            PullState = 'Merged'
            BranchExists = $true
            ClosureComments = [System.Collections.Generic.List[object]]::new()
            AttestationComments = [System.Collections.Generic.List[object]]::new()
            Reviews = [System.Collections.Generic.List[object]]::new()
            MissingBaseGitlink = $false
            MissingReleaseTag = $false
            ProtocolCommitNotAncestor = $false
            ReleaseNotImmutable = $false
            ManifestOnReviewedTree = $false
            ReviewTreeLedgerMismatch = $false
            DefaultContainmentFailure = $false
            BranchLeaseRace = $false
        }
    }.GetNewClosure()

    $resetHistoricalProductionState = {
        param(
            $SourceCatalog = $historicalCatalog,
            [byte[]]$SourceCatalogBytes = $historicalCatalogBytes,
            [byte[]]$SourceDefinitionBytes = $historicalDefinitionBytes
        )
        Import-Module $catalogModulePath -Force -Global
        Import-Module $modulePath -Force -Global
        $apiState.HistoricalReview = & $newHistoricalReviewState `
            $SourceCatalog $SourceCatalogBytes $SourceDefinitionBytes
        $apiState.HistoricalReview.Reviews.Add([pscustomobject]@{
            state = 'APPROVED'
            commit_id = $historicalReviewHead
            submitted_at = '2026-07-19T00:00:30Z'
            user = $apiState.ReviewerActor
        })
        $apiState.IssueCreated = $false
        $apiState.IssueClosed = $false
        $apiState.PullCreated = $false
        $apiState.PullMerged = $false
        $apiState.BranchCreated = $false
        $apiState.BranchHead = $historicalDefaultHead
        $apiState.DefaultHead = $historicalDefaultHead
        $apiState.PullBody = $null
        $apiState.BlobBody = $null
        $apiState.TreeBody = $null
        $apiState.CommitBody = $null
        $apiState.DefaultHeadReadCount = 0
        $apiState.DriftDefaultHeadAfterReadCount = 0
        $apiState.Calls.Clear()
        $apiState.HistoricalMutationCalls.Clear()
        $apiState.HistoricalEvidenceCalls.Clear()
        $apiState.ClosureComments.Clear()
        $apiState.AttestationComments.Clear()
        $apiState.Reviews.Clear()
        [IO.File]::WriteAllBytes(
            (Join-Path $fixtureAiRoot 'meandai-capabilities-state.json'),
            [byte[]]$apiState.HistoricalReview.CurrentLedgerBytes
        )
    }.GetNewClosure()
    $protocolGitBlobRuntime = {
        param([string]$CommitSha, [string]$RelativePath)
        if ($null -eq $apiState.HistoricalReview -or
            $CommitSha -cne
                [string]$apiState.HistoricalReview.ProtocolCommit) {
            throw 'TEST-0166 historical protocol blob used another commit.'
        }
        $apiState.HistoricalEvidenceCalls.Add("blob:$RelativePath")
        switch -CaseSensitive ($RelativePath) {
            'VERSION' {
                return ,([byte[]]$apiState.HistoricalReview.VersionBytes)
            }
            'capabilities/index.json' {
                return ,([byte[]]$apiState.HistoricalReview.CatalogBytes)
            }
            'capabilities/test-architecture.json' {
                return ,([byte[]]$apiState.HistoricalReview.DefinitionBytes)
            }
            default {
                throw "TEST-0166 unexpected historical protocol blob '$RelativePath'."
            }
        }
    }.GetNewClosure()
    $historicalRuntime = @{
        Git = $gitRuntime
        GitHub = $githubRuntime
        ProtocolGitBlob = $protocolGitBlobRuntime
    }

    & $resetHistoricalProductionState
    $currentLedgerBefore = [IO.File]::ReadAllBytes(
        (Join-Path $fixtureAiRoot 'meandai-capabilities-state.json')
    )
    $currentLedgerBeforeObject = Import-MeAndAICapabilityLedger `
        -Catalog $releaseCatalog -Bytes $currentLedgerBefore
    Assert-Equal @($currentLedgerBeforeObject.Entries).Count 2 `
        'TEST-0165 fixture did not start with a historical prefix plus current suffix.'
    $currentSuffixBefore = @($currentLedgerBeforeObject.Entries)[1]
    $historicalRecovery = & $runnerPath `
        -ConsumerRoot $fixtureRoot -ProtocolRoot $root `
        -Repository 'hasanmanzak/consumer' -DefaultBranch main `
        -TargetVersion v0.13.3 -DiscoveryContext AlreadyCurrent `
        -FinalizePullRequestNumber $historicalPullNumber `
        -Runtime $historicalRuntime
    Assert-Equal $historicalRecovery.State 'Current' `
        'TEST-0165 merged historical review did not continue into fresh current discovery.'
    Assert-Equal (
        $apiState.HistoricalMutationCalls -join ','
    ) 'DeleteHistoricalBranch,CommentHistoricalIssue,CloseHistoricalIssue' `
        'TEST-0165 historical recovery did not preserve branch-first/issue-last order.'
    Assert-True (-not $apiState.HistoricalReview.BranchExists) `
        'TEST-0165 historical recovery retained its exact branch.'
    Assert-True $apiState.HistoricalReview.IssueClosed `
        'TEST-0165 historical recovery retained its canonical issue.'
    Assert-True (-not $apiState.IssueCreated -and
        -not $apiState.BranchCreated -and -not $apiState.PullCreated) `
        'TEST-0165 complete current ledger created duplicate capability work.'
    Assert-Equal @($apiState.Calls | Where-Object {
        $_ -match '^Proposal POST repos/.+/git/refs$'
    }).Count 0 `
        'TEST-0165 recovery created a duplicate current review branch.'
    Assert-Equal @($apiState.Calls | Where-Object {
        $_ -match '^Issue POST repos/.+/issues$'
    }).Count 0 `
        'TEST-0165 recovery created a duplicate current tracking issue.'
    Assert-Equal @($apiState.Calls | Where-Object {
        $_ -match '^Proposal POST repos/.+/pulls$'
    }).Count 0 `
        'TEST-0165 recovery created a duplicate current review pull request.'
    foreach ($evidenceCall in @(
        'base-gitlink',
        'protocol-origin',
        'protocol-commit',
        'protocol-ancestor',
        'tag-peel',
        'blob:VERSION',
        'blob:capabilities/index.json',
        'blob:capabilities/test-architecture.json',
        'immutable-release',
        'branch-delete-lease'
    )) {
        Assert-True (
            $apiState.HistoricalEvidenceCalls -ccontains $evidenceCall
        ) "TEST-0165 historical recovery omitted '$evidenceCall' evidence."
    }
    $currentLedgerAfter = [IO.File]::ReadAllBytes(
        (Join-Path $fixtureAiRoot 'meandai-capabilities-state.json')
    )
    Assert-True (Test-TestBytesEqual -Left $currentLedgerBefore -Right (
        $currentLedgerAfter
    )) 'TEST-0165 historical recovery rewrote current ledger content.'
    $currentLedgerAfterObject = Import-MeAndAICapabilityLedger `
        -Catalog $releaseCatalog -Bytes $currentLedgerAfter
    $currentSuffixAfter = @($currentLedgerAfterObject.Entries)[1]
    Assert-True (
        [string]$currentSuffixAfter.Slug -ceq [string]$currentSuffixBefore.Slug -and
        [string]$currentSuffixAfter.DefinitionBlob -ceq
            [string]$currentSuffixBefore.DefinitionBlob -and
        [string]$currentSuffixAfter.ReviewIdentity -ceq
            [string]$currentSuffixBefore.ReviewIdentity
    ) 'TEST-0165 historical recovery did not preserve the appended current entry.'
    Assert-True (Test-TestBytesEqual `
        -Left ([byte[]]$apiState.HistoricalReview.CurrentLedgerBytes) `
        -Right (
        [IO.File]::ReadAllBytes(
            (Join-Path $fixtureAiRoot 'meandai-capabilities-state.json')
        )
    )) 'TEST-0165 historical recovery performed an unplanned ledger write.'
    Assert-True @($apiState.Calls | Where-Object {
        $_ -match 'GET repos/.+/issues\?state=all'
    }).Count -eq 2 `
        'TEST-0165 recovery did not use exactly one initial and one fresh issue inventory.'

    $historicalMutationCount =
        $apiState.HistoricalMutationCalls.Count
    $historicalRerun = & $runnerPath `
        -ConsumerRoot $fixtureRoot -ProtocolRoot $root `
        -Repository 'hasanmanzak/consumer' -DefaultBranch main `
        -TargetVersion v0.13.3 -DiscoveryContext AlreadyCurrent `
        -Runtime $historicalRuntime -PlanOnly
    Assert-Equal $historicalRerun.State 'Current' `
        'TEST-0165 completed historical recovery rerun was not current.'
    Assert-Equal $historicalRerun.Plan.Operations.Count 0 `
        'TEST-0165 completed recovery rerun planned duplicate work.'
    Assert-Equal $apiState.HistoricalMutationCalls.Count `
        $historicalMutationCount `
        'TEST-0165 completed recovery rerun repeated historical cleanup.'

    & $resetHistoricalProductionState
    $apiState.HistoricalReview.BranchExists = $false
    $partialRecovery = & $runnerPath `
        -ConsumerRoot $fixtureRoot -ProtocolRoot $root `
        -Repository 'hasanmanzak/consumer' -DefaultBranch main `
        -TargetVersion v0.13.3 -DiscoveryContext AlreadyCurrent `
        -FinalizePullRequestNumber $historicalPullNumber `
        -Runtime $historicalRuntime
    Assert-Equal $partialRecovery.State 'Current' `
        'TEST-0165 proven branch-absent recovery did not continue current discovery.'
    Assert-Equal ($apiState.HistoricalMutationCalls -join ',') `
        'CommentHistoricalIssue,CloseHistoricalIssue' `
        'TEST-0165 proven branch absence did not perform issue-last recovery only.'
    Assert-True (-not ($apiState.HistoricalEvidenceCalls -ccontains
        'branch-delete-lease')) `
        'TEST-0165 proven absent branch attempted a duplicate delete push.'
    Assert-True ($apiState.HistoricalReview.IssueClosed -and
        -not $apiState.IssueCreated -and -not $apiState.PullCreated) `
        'TEST-0165 branch-absent partial recovery did not converge exactly once.'

    # TEST-0166: anything other than one provable immutable historical merge
    # blocks before successful branch, issue, or current-catalog mutation.
    $assertHistoricalBlock = {
        param(
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)][scriptblock]$Arrange,
            [Parameter(Mandatory)][string]$Pattern
        )
        & $resetHistoricalProductionState
        & $Arrange $apiState.HistoricalReview
        $beforeBranch = [bool]$apiState.HistoricalReview.BranchExists
        $beforeIssue = [bool]$apiState.HistoricalReview.IssueClosed
        Assert-ThrowsLike -Action {
            & $runnerPath -ConsumerRoot $fixtureRoot -ProtocolRoot $root `
                -Repository 'hasanmanzak/consumer' -DefaultBranch main `
                -TargetVersion v0.13.3 -DiscoveryContext AlreadyCurrent `
                -Runtime $historicalRuntime
        } -Pattern $Pattern -Message "TEST-0166 $Name did not fail closed."
        Assert-Equal $apiState.HistoricalMutationCalls.Count 0 `
            "TEST-0166 $Name mutated historical state before proof."
        Assert-Equal @($apiState.Calls | Where-Object {
            $_ -match '^(?:Proposal|Issue|Protocol) (?:POST|PATCH|DELETE) '
        }).Count 0 `
            "TEST-0166 $Name reached a GitHub mutation request."
        Assert-Equal $apiState.HistoricalReview.BranchExists $beforeBranch `
            "TEST-0166 $Name changed the historical branch."
        Assert-Equal $apiState.HistoricalReview.IssueClosed $beforeIssue `
            "TEST-0166 $Name changed the historical issue."
        Assert-True (-not $apiState.IssueCreated -and
            -not $apiState.PullCreated) `
            "TEST-0166 $Name created current work after failed recovery."
    }.GetNewClosure()

    & $assertHistoricalBlock 'active stale review' {
        param($state)
        $state.PullState = 'Open'
    } '*active*historical*'
    & $assertHistoricalBlock 'closed-unmerged stale review' {
        param($state)
        $state.PullState = 'Closed'
    } '*closed*without merge*'
    & $assertHistoricalBlock 'duplicate stale issue inventory' {
        param($state)
        $state.IssueCopies = 2
    } '*duplicate*issue*'
    & $assertHistoricalBlock 'duplicate stale pull-request inventory' {
        param($state)
        $state.PullCopies = 2
    } '*duplicate*pull request*'
    & $assertHistoricalBlock 'malformed stale issue binding' {
        param($state)
        $state.IssueBody = $state.IssueBody.Replace(
            'Catalog digest:',
            'Broken catalog digest:'
        )
    } '*canonical*binding*'
    & $assertHistoricalBlock 'missing exact BaseHead gitlink' {
        param($state)
        $state.MissingBaseGitlink = $true
    } '*gitlink*'
    & $assertHistoricalBlock 'unverifiable historical protocol tag' {
        param($state)
        $state.MissingReleaseTag = $true
    } '*tag*'
    & $assertHistoricalBlock 'non-immutable historical release' {
        param($state)
        $state.ReleaseNotImmutable = $true
    } '*immutable*release*'
    & $assertHistoricalBlock 'historical protocol outside current ancestry' {
        param($state)
        $state.ProtocolCommitNotAncestor = $true
    } '*ancestor*'
    & $assertHistoricalBlock 'malformed historical catalog blob' {
        param($state)
        $state.CatalogBytes =
            [Text.UTF8Encoding]::new($false).GetBytes("{`n")
    } '*catalog*'

    & $resetHistoricalProductionState `
        $alternateCatalog $alternateCatalogBytes $alternateDefinitionBytes
    Assert-ThrowsLike -Action {
        & $runnerPath -ConsumerRoot $fixtureRoot -ProtocolRoot $root `
            -Repository 'hasanmanzak/consumer' -DefaultBranch main `
            -TargetVersion v0.13.3 -DiscoveryContext AlreadyCurrent `
            -Runtime $historicalRuntime
    } -Pattern '*prefix*' `
        -Message 'TEST-0166 non-prefix historical catalog did not fail closed.'
    Assert-Equal $apiState.HistoricalMutationCalls.Count 0 `
        'TEST-0166 non-prefix historical catalog mutated repository state.'

    & $assertHistoricalBlock 'review-tree ledger drift' {
        param($state)
        $state.ReviewTreeLedgerMismatch = $true
    } '*review head capability ledger*'
    & $assertHistoricalBlock 'transient manifest on reviewed tree' {
        param($state)
        $state.ManifestOnReviewedTree = $true
    } '*manifest remains*'
    & $assertHistoricalBlock 'missing exact-head review authority' {
        param($state)
        $state.Reviews.Clear()
    } '*approval*'
    & $assertHistoricalBlock 'default missing merged review' {
        param($state)
        $state.DefaultContainmentFailure = $true
    } '*contained*default*'
    & $assertHistoricalBlock 'default-head verification race' {
        param($state)
        $apiState.DriftDefaultHeadAfterReadCount = 1
    } '*Default branch changed*'
    & $assertHistoricalBlock 'branch expected-head lease race' {
        param($state)
        $state.BranchLeaseRace = $true
    } '*branch*'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Write-Host 'Capability review lifecycle tests passed.' -ForegroundColor Green

$evidenceModule = Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
if ((Test-Path -LiteralPath $evidenceModule -PathType Leaf) -and
    (Test-Path -LiteralPath $authorityPath -PathType Leaf)) {
    $authority = Import-PowerShellDataFile -LiteralPath $authorityPath
    $owner = 'tests/capabilities/capability-adoption/capability-review.tests.ps1'
    if (@($authority.Authorities | Where-Object {
        [string]$_.Owner -ceq $owner
    }).Count -eq 1) {
        Import-Module $evidenceModule -Force
        $scenarioResult = New-MeAndAIScenarioResult `
            -Owner $owner -SourcePaths @($PSCommandPath) `
            -AuthorityPath $authorityPath
        Write-Host ('MEANDAI_SCENARIO_RESULTS=' + `
            ($scenarioResult | ConvertTo-Json -Compress))
    }
}
