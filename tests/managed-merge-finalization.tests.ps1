[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function ConvertTo-TestBase64Json {
    param($InputObject)
    $json = $InputObject | ConvertTo-Json -Depth 10 -Compress
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
}

function Add-FinalizationEvent {
    param([string]$Event)
    $global:MeAndAIFinalizationScenario.Events.Add($Event)
}

function New-FinalizationScenario {
    param(
        [ValidateSet('Adoption', 'Update', 'Normal')]
        [string]$Kind = 'Adoption'
    )

    $head = 'a' * 40
    $protocolSha = 'b' * 40
    $target = 'v0.9.7'
    $branch = switch ($Kind) {
        'Adoption' { "automation/meandai-capabilities-$target" }
        'Update' { "automation/meandai-protocol-$target" }
        default { 'feature/ordinary-change' }
    }
    $marker = switch ($Kind) {
        'Adoption' {
            [ordered]@{
                schema = 3; phase = 'Completed'; state = 'BootstrapReady'
                target = $target; protocolSha = $protocolSha; head = $head
                repository = 'owner/consumer'; actor = 'updater-owner'
            } | ConvertTo-Json -Compress
        }
        'Update' {
            [ordered]@{
                schema = 1; target = $target; protocolSha = $protocolSha
                head = $head; repository = 'owner/consumer'
            } | ConvertTo-Json -Compress
        }
        default { '' }
    }
    $body = switch ($Kind) {
        'Adoption' { "<!-- meandai-capabilities-adoption:$marker -->`n## Adoption`n`nTracking issue: #9" }
        'Update' { "<!-- meandai-protocol-update:$marker -->`n## Update`n`nTracking issue: #9" }
        default { '## Ordinary pull request' }
    }
    $changedFiles = switch ($Kind) {
        'Adoption' {
            @(
                [pscustomobject]@{ filename = '.ai/protocol'; status = 'added' },
                [pscustomobject]@{ filename = 'AGENTS.md'; status = 'added' }
            )
        }
        'Update' {
            @(
                [pscustomobject]@{ filename = '.ai/protocol'; status = 'modified' },
                [pscustomobject]@{
                    filename = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
                    status = 'modified'
                }
            )
        }
        default { @([pscustomobject]@{ filename = 'README.md'; status = 'modified' }) }
    }
    $issueBody = if ($Kind -ceq 'Adoption') {
        "<!-- meandai-local-adoption:$target`:pr-42 -->`n## AI capabilities adoption tracking"
    }
    else { '## Project-owned protocol update tracking' }
    [pscustomobject]@{
        Kind = $Kind
        Repository = 'owner/consumer'
        DefaultBranch = 'main'
        PullRequestNumber = 42
        PullRequestState = 'closed'
        Merged = $true
        BaseBranch = 'main'
        HeadRepository = 'owner/consumer'
        HeadAuthor = 'updater-owner'
        Branch = $branch
        ExpectedHead = $head
        MergeCommitSha = 'd' * 40
        DefaultHead = 'e' * 40
        CompareStatus = 'ahead'
        LiveHead = $head
        BranchExists = $Kind -cne 'Normal'
        MoveBeforeDelete = $false
        ProbeCalls = 0
        Body = $body
        ChangedFiles = @($changedFiles)
        IssueNumber = 9
        IssueTitle = if ($Kind -ceq 'Adoption') {
            "Track meAndAI AI capabilities adoption from $target"
        } else { 'TASK-0042 - Review protocol update' }
        IssueBody = $issueBody
        IssueState = 'open'
        IssueIsPullRequest = $false
        IssueLabels = [System.Collections.Generic.List[string]]::new(
            [string[]]@('type:feature', 'priority:p1', 'status:needs-review')
        )
        AdoptionIssueCount = if ($Kind -ceq 'Adoption') { 1 } else { 0 }
        OpenBranchReuseCount = 0
        ExistingEvidenceComments = 0
        Events = [System.Collections.Generic.List[string]]::new()
    }
}

function global:git {
    $scenario = $global:MeAndAIFinalizationScenario
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0

    if ($arguments[0] -ceq 'ls-remote') {
        $scenario.ProbeCalls++
        Add-FinalizationEvent "probe-branch-$($scenario.ProbeCalls)"
        if ($scenario.MoveBeforeDelete -and $scenario.ProbeCalls -ge 2) {
            $scenario.LiveHead = 'c' * 40
        }
        if ($scenario.BranchExists) {
            "$($scenario.LiveHead)`trefs/heads/$($scenario.Branch)"
        }
        else {
            $global:LASTEXITCODE = 2
        }
        return
    }
    if ($arguments[0] -ceq 'push') {
        $ref = "refs/heads/$($scenario.Branch)"
        $lease = "--force-with-lease=${ref}:$($scenario.ExpectedHead)"
        if ($arguments -cnotcontains $lease -or
            [string]$arguments[-1] -cne ":$ref") {
            throw "Branch deletion omitted its exact expected-head lease: $($arguments -join ' ')"
        }
        if ($scenario.LiveHead -cne $scenario.ExpectedHead) {
            $global:LASTEXITCODE = 1
            'stale info: remote ref changed'
            return
        }
        $scenario.BranchExists = $false
        Add-FinalizationEvent 'delete-branch'
        return
    }
    throw "Unexpected fake git command: $($arguments -join ' ')"
}

function global:gh {
    $scenario = $global:MeAndAIFinalizationScenario
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0

    if ($arguments[0] -cne 'api') {
        throw "Unexpected fake gh command: $($arguments -join ' ')"
    }

    $endpoint = @($arguments | Where-Object { $_ -like 'repos/*' })[0]
    $method = 'GET'
    $methodIndex = [array]::IndexOf($arguments, '--method')
    if ($methodIndex -ge 0) {
        $method = [string]$arguments[$methodIndex + 1]
    }
    if ($endpoint -ceq 'repos/owner/consumer/pulls/42') {
        Add-FinalizationEvent 'read-pull-request'
        [ordered]@{
            number = 42
            state = $scenario.PullRequestState
            merged = [bool]$scenario.Merged
            merged_at = if ($scenario.Merged) { '2026-07-17T00:00:00Z' } else { $null }
            merge_commit_sha = $scenario.MergeCommitSha
            body = $scenario.Body
            user = [ordered]@{ login = $scenario.HeadAuthor }
            head = [ordered]@{
                ref = $scenario.Branch
                sha = $scenario.ExpectedHead
                repo = [ordered]@{ full_name = $scenario.HeadRepository }
            }
            base = [ordered]@{ ref = $scenario.BaseBranch }
        } | ConvertTo-Json -Depth 8 -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer') {
        Add-FinalizationEvent 'read-repository'
        [ordered]@{
            full_name = $scenario.Repository
            default_branch = $scenario.DefaultBranch
        } | ConvertTo-Json -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/git/ref/heads/main') {
        Add-FinalizationEvent 'read-default-head'
        [ordered]@{
            ref = 'refs/heads/main'
            object = [ordered]@{ type = 'commit'; sha = $scenario.DefaultHead }
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/compare/$($scenario.MergeCommitSha)...$($scenario.DefaultHead)") {
        Add-FinalizationEvent 'verify-merge-containment'
        [ordered]@{ status = $scenario.CompareStatus } |
            ConvertTo-Json -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/pulls/42/files?per_page=100') {
        Add-FinalizationEvent 'read-pull-request-files'
        foreach ($file in @($scenario.ChangedFiles)) {
            ConvertTo-TestBase64Json $file
        }
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/issues?state=all&per_page=100') {
        Add-FinalizationEvent 'inventory-adoption-issues'
        for ($index = 0; $index -lt $scenario.AdoptionIssueCount; $index++) {
            $issueRecord = [pscustomobject]@{
                number = $scenario.IssueNumber
                title = $scenario.IssueTitle
                body = $scenario.IssueBody
                state = $scenario.IssueState
                labels = @($scenario.IssueLabels | ForEach-Object {
                    [pscustomobject]@{ name = $_ }
                })
            }
            if ($scenario.IssueIsPullRequest) {
                $issueRecord | Add-Member -NotePropertyName pull_request `
                    -NotePropertyValue ([pscustomobject]@{ url = 'https://api.github.com/pulls/9' })
            }
            ConvertTo-TestBase64Json $issueRecord
        }
        return
    }
    if ($endpoint -like 'repos/owner/consumer/pulls?state=open&head=owner:*&per_page=100') {
        Add-FinalizationEvent 'check-open-branch-reuse'
        for ($index = 0; $index -lt $scenario.OpenBranchReuseCount; $index++) {
            ConvertTo-TestBase64Json ([pscustomobject]@{
                number = 100 + $index
                state = 'open'
                head = [pscustomobject]@{
                    ref = $scenario.Branch
                    sha = $scenario.ExpectedHead
                }
            })
        }
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)") {
        if ($method -ceq 'PATCH') {
            $scenario.IssueState = 'closed'
            Add-FinalizationEvent 'close-issue'
            '{}'
        }
        else {
            Add-FinalizationEvent 'read-issue'
            $issueRecord = [pscustomobject][ordered]@{
                number = $scenario.IssueNumber
                title = $scenario.IssueTitle
                body = $scenario.IssueBody
                state = $scenario.IssueState
                labels = @($scenario.IssueLabels | ForEach-Object {
                    [ordered]@{ name = $_ }
                })
            }
            if ($scenario.IssueIsPullRequest) {
                $issueRecord | Add-Member -NotePropertyName pull_request `
                    -NotePropertyValue ([pscustomobject]@{ url = 'https://api.github.com/pulls/9' })
            }
            $issueRecord | ConvertTo-Json -Depth 5 -Compress
        }
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)/comments?per_page=100") {
        Add-FinalizationEvent 'read-issue-comments'
        for ($index = 0; $index -lt $scenario.ExistingEvidenceComments; $index++) {
            ConvertTo-TestBase64Json ([pscustomobject]@{
                body = "<!-- meandai-managed-merge-finalization:pr-42:head-$($scenario.ExpectedHead) -->`nExisting evidence"
            })
        }
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)/comments" -and
        $method -ceq 'POST') {
        $scenario.ExistingEvidenceComments = 1
        Add-FinalizationEvent 'comment-issue'
        '{}'
        return
    }
    if ($endpoint -like "repos/owner/consumer/issues/$($scenario.IssueNumber)/labels/*" -and
        $method -ceq 'DELETE') {
        $encodedLabel = $endpoint.Substring($endpoint.LastIndexOf('/') + 1)
        $label = [Uri]::UnescapeDataString($encodedLabel)
        [void]$scenario.IssueLabels.Remove($label)
        Add-FinalizationEvent "remove-label-$label"
        return
    }
    throw "Unexpected fake gh API command: $($arguments -join ' ')"
}

function Invoke-FinalizationScenario {
    param([Parameter(Mandatory)]$Scenario)

    $global:MeAndAIFinalizationScenario = $Scenario
    $previousRepository = $env:GITHUB_REPOSITORY
    $previousDefaultBranch = $env:DEFAULT_BRANCH
    $previousToken = $env:GH_TOKEN
    try {
        $env:GITHUB_REPOSITORY = $Scenario.Repository
        $env:DEFAULT_BRANCH = $Scenario.DefaultBranch
        $env:GH_TOKEN = 'test-finalizer-token'
        & $adapterPath -FinalizeMergedPullRequest `
            -PullRequestNumber $Scenario.PullRequestNumber
        [pscustomobject]@{ Threw = $false; Error = ''; Scenario = $Scenario }
    }
    catch {
        [pscustomobject]@{
            Threw = $true
            Error = $_.Exception.Message
            Scenario = $Scenario
        }
    }
    finally {
        $env:GITHUB_REPOSITORY = $previousRepository
        $env:DEFAULT_BRANCH = $previousDefaultBranch
        $env:GH_TOKEN = $previousToken
    }
}

function Test-NoFinalizationMutation {
    param([Parameter(Mandatory)]$Result, [Parameter(Mandatory)][string]$Name)

    $mutations = @($Result.Scenario.Events | Where-Object {
        $_ -ceq 'delete-branch' -or $_ -ceq 'comment-issue' -or
        $_ -ceq 'close-issue' -or $_ -like 'remove-label-*'
    })
    if ($mutations.Count -ne 0) {
        Add-Failure "TEST-0110 $Name mutated finalization state: $($mutations -join ', ')"
    }
}

try {
    $adoption = Invoke-FinalizationScenario -Scenario (New-FinalizationScenario -Kind Adoption)
    if ($adoption.Threw -or $adoption.Scenario.BranchExists -or
        $adoption.Scenario.IssueState -cne 'closed' -or
        $adoption.Scenario.ExistingEvidenceComments -ne 1 -or
        $adoption.Scenario.IssueLabels -contains 'status:needs-review' -or
        @($adoption.Scenario.Events | Where-Object { $_ -ceq 'delete-branch' }).Count -ne 1) {
        Add-Failure "TEST-0108 exact adoption merge did not converge: $($adoption.Error)"
    }
    $deleteIndex = [array]::IndexOf(@($adoption.Scenario.Events), 'delete-branch')
    $commentIndex = [array]::IndexOf(@($adoption.Scenario.Events), 'comment-issue')
    $closeIndex = [array]::IndexOf(@($adoption.Scenario.Events), 'close-issue')
    if ($deleteIndex -lt 0 -or $commentIndex -le $deleteIndex -or $closeIndex -le $commentIndex) {
        Add-Failure 'TEST-0108 issue finalization did not follow verified branch deletion.'
    }

    $adoption.Scenario.Events.Clear()
    $rerun = Invoke-FinalizationScenario -Scenario $adoption.Scenario
    if ($rerun.Threw -or @($rerun.Scenario.Events | Where-Object {
        $_ -ceq 'delete-branch' -or $_ -ceq 'comment-issue' -or $_ -ceq 'close-issue'
    }).Count -ne 0) {
        Add-Failure "TEST-0108 exact recovery rerun was not idempotent: $($rerun.Error)"
    }

    $update = Invoke-FinalizationScenario -Scenario (New-FinalizationScenario -Kind Update)
    if ($update.Threw -or $update.Scenario.BranchExists -or
        $update.Scenario.ExistingEvidenceComments -ne 1 -or
        $update.Scenario.IssueLabels -contains 'status:needs-review' -or
        $update.Scenario.IssueState -cne 'closed' -or
        @($update.Scenario.Events | Where-Object { $_ -ceq 'close-issue' }).Count -ne 1) {
        Add-Failure "TEST-0109 exact update merge did not converge through its tracking issue: $($update.Error)"
    }

    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($requiredText in @(
        'pull_request:', 'types: [closed]', 'finalize_pull_request:',
        'finalize-managed-merge:', 'pull-requests: read', 'issues: write',
        'contents: write', '-FinalizeMergedPullRequest', '-PullRequestNumber'
    )) {
        if (-not $workflow.Contains($requiredText)) {
            Add-Failure "TEST-0109 consumer workflow is missing '$requiredText'."
        }
    }
    if (-not $workflow.Contains("github.event.pull_request.merged == true") -or
        -not $workflow.Contains("inputs.finalize_pull_request == ''") -or
        -not $workflow.Contains("inputs.finalize_pull_request != ''")) {
        Add-Failure 'TEST-0109 consumer workflow does not separate update discovery from event/recovery finalization.'
    }

    $normal = Invoke-FinalizationScenario -Scenario (New-FinalizationScenario -Kind Normal)
    if ($normal.Threw) {
        Add-Failure "TEST-0110 ordinary pull request did not remain a no-op: $($normal.Error)"
    }
    Test-NoFinalizationMutation -Result $normal -Name 'ordinary pull request'

    $negativeScenarios = [System.Collections.Generic.List[object]]::new()

    $unmerged = New-FinalizationScenario -Kind Adoption
    $unmerged.Merged = $false
    $negativeScenarios.Add([pscustomobject]@{ Name = 'unmerged'; Scenario = $unmerged })

    $crossRepository = New-FinalizationScenario -Kind Adoption
    $crossRepository.HeadRepository = 'attacker/fork'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'cross-repository'; Scenario = $crossRepository })

    $wrongBase = New-FinalizationScenario -Kind Adoption
    $wrongBase.BaseBranch = 'release'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'wrong base'; Scenario = $wrongBase })

    $mergeNotContained = New-FinalizationScenario -Kind Adoption
    $mergeNotContained.CompareStatus = 'diverged'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'merge not on default'; Scenario = $mergeNotContained })

    $duplicateMarker = New-FinalizationScenario -Kind Adoption
    $duplicateMarker.Body += "`n$($duplicateMarker.Body.Split("`n")[0])"
    $negativeScenarios.Add([pscustomobject]@{ Name = 'duplicate marker'; Scenario = $duplicateMarker })

    $missingAdoptionIssue = New-FinalizationScenario -Kind Adoption
    $missingAdoptionIssue.AdoptionIssueCount = 0
    $negativeScenarios.Add([pscustomobject]@{ Name = 'missing adoption issue'; Scenario = $missingAdoptionIssue })

    $multipleUpdateIssues = New-FinalizationScenario -Kind Update
    $multipleUpdateIssues.Body += "`nTracking issue: #10"
    $negativeScenarios.Add([pscustomobject]@{ Name = 'multiple update issues'; Scenario = $multipleUpdateIssues })

    $malformedTracking = New-FinalizationScenario -Kind Update
    $malformedTracking.Body = $malformedTracking.Body.Replace(
        'Tracking issue: #9', 'tracking issue: #9'
    )
    $negativeScenarios.Add([pscustomobject]@{ Name = 'noncanonical tracking line'; Scenario = $malformedTracking })

    $preclosedIssue = New-FinalizationScenario -Kind Adoption
    $preclosedIssue.IssueState = 'closed'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'closed issue without evidence'; Scenario = $preclosedIssue })

    $pullRequestAsIssue = New-FinalizationScenario -Kind Update
    $pullRequestAsIssue.IssueIsPullRequest = $true
    $negativeScenarios.Add([pscustomobject]@{ Name = 'pull request as issue'; Scenario = $pullRequestAsIssue })

    $unexpectedUpdatePath = New-FinalizationScenario -Kind Update
    $unexpectedUpdatePath.ChangedFiles += [pscustomobject]@{
        filename = 'src/application.cs'; status = 'modified'
    }
    $negativeScenarios.Add([pscustomobject]@{ Name = 'unexpected update path'; Scenario = $unexpectedUpdatePath })

    $renamedPath = New-FinalizationScenario -Kind Update
    $renamedPath.ChangedFiles[0] = [pscustomobject]@{
        filename = '.ai/protocol'; previous_filename = '.ai/old-protocol'
        status = 'renamed'
    }
    $negativeScenarios.Add([pscustomobject]@{ Name = 'renamed path'; Scenario = $renamedPath })

    $markerHeadMismatch = New-FinalizationScenario -Kind Adoption
    $markerHeadMismatch.ExpectedHead = 'f' * 40
    $negativeScenarios.Add([pscustomobject]@{ Name = 'marker head mismatch'; Scenario = $markerHeadMismatch })

    $movedBranch = New-FinalizationScenario -Kind Adoption
    $movedBranch.MoveBeforeDelete = $true
    $negativeScenarios.Add([pscustomobject]@{ Name = 'moved branch'; Scenario = $movedBranch })

    $reusedBranch = New-FinalizationScenario -Kind Adoption
    $reusedBranch.OpenBranchReuseCount = 1
    $negativeScenarios.Add([pscustomobject]@{ Name = 'open branch reuse'; Scenario = $reusedBranch })

    foreach ($negative in $negativeScenarios) {
        $result = Invoke-FinalizationScenario -Scenario $negative.Scenario
        if (-not $result.Threw) {
            Add-Failure "TEST-0110 $($negative.Name) did not fail closed."
        }
        Test-NoFinalizationMutation -Result $result -Name $negative.Name
    }
}
finally {
    Remove-Item Function:\global:git -ErrorAction SilentlyContinue
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIFinalizationScenario -Scope Global -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host "Managed merge finalization tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Managed merge finalization tests passed.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/managed-merge-finalization.tests.ps1' `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
