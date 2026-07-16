[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adapterSource = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$moduleSource = Join-Path $root 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
$workflowSource = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$adapterContent = Get-Content -LiteralPath $adapterSource -Raw
$failures = [System.Collections.Generic.List[string]]::new()
$script:Scenario = $null

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
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
        $path = [string]$arguments[-1]
        if ($path -eq '.ai/protocol') {
            "160000 commit $($script:Scenario.CurrentProtocolSha)`t.ai/protocol"
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
            'v0.1.0' { $script:Scenario.CurrentProtocolSha }
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
        Add-ScenarioEvent 'checkout-target-assets'
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
    if ($arguments[0] -eq 'diff' -and $arguments -contains '--cached') {
        @($script:Scenario.ExpectedStagedPaths)
        return
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
    if ($arguments[0] -in @('switch', 'update-index', 'config', 'commit')) {
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
        $rootTreeSha = if ($endpoint -like "*$($script:Scenario.NewHead)") { 'c' * 40 } else { 'd' * 40 }
        [pscustomobject]@{ tree = [pscustomobject]@{ sha = $rootTreeSha } } |
            ConvertTo-Json -Depth 3 -Compress
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
        [bool]$WrongTargetAssetBlob = $false,
        [bool]$ReservedOrphanBranchExists = $false,
        [bool]$ReservedNamespaceRace = $false,
        [int]$LeadingUnmanagedCount = 0,
        [ValidateSet('Valid', 'Missing', 'Mutable', 'Draft', 'Prerelease', 'Unpublished', 'WrongTag')]
        [string]$ReleaseMode = 'Valid',
        [ValidateSet('Lightweight', 'Annotated', 'Nested')]
        [string]$ReleaseTagMode = 'Lightweight',
        [bool]$MismatchedReleaseCommit = $false,
        [ValidateSet('None', 'InventoryRename', 'RevalidationRename')]
        [string]$RenameMode = 'None'
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-adapter-$Name-$([guid]::NewGuid().ToString('N'))"
    $scriptsPath = Join-Path $tempRoot '.github/scripts'
    $workflowsPath = Join-Path $tempRoot '.github/workflows'
    $sourceGitPath = Join-Path $tempRoot '.meandai-update-source/.git'
    $sourceScriptsPath = Join-Path $tempRoot '.meandai-update-source/templates/project/.github/scripts'
    $sourceWorkflowsPath = Join-Path $tempRoot '.meandai-update-source/templates/project/.github/workflows'
    New-Item -ItemType Directory -Force $scriptsPath, $workflowsPath, $sourceGitPath, `
        $sourceScriptsPath, $sourceWorkflowsPath | Out-Null
    Copy-Item -LiteralPath $moduleSource -Destination (Join-Path $scriptsPath 'MeAndAI.ProtocolUpdate.psm1')
    Copy-Item -LiteralPath $adapterSource -Destination (Join-Path $scriptsPath 'Invoke-MeAndAIProtocolUpdate.ps1')
    Copy-Item -LiteralPath $workflowSource -Destination (Join-Path $workflowsPath 'meandai-protocol-update.yml')
    Copy-Item -LiteralPath $moduleSource -Destination (Join-Path $sourceScriptsPath 'MeAndAI.ProtocolUpdate.psm1')
    Copy-Item -LiteralPath $adapterSource -Destination (Join-Path $sourceScriptsPath 'Invoke-MeAndAIProtocolUpdate.ps1')
    Copy-Item -LiteralPath $workflowSource -Destination (Join-Path $sourceWorkflowsPath 'meandai-protocol-update.yml')

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
    $newMarker = [ordered]@{
        schema = 1; target = 'v0.3.0'; protocolSha = '3' * 40
        head = 'b' * 40; repository = 'owner/consumer'
    } | ConvertTo-Json -Compress
    $initialNewBody = if ($ExistingReplacement) { "<!-- meandai-protocol-update:$newMarker -->" } else { '' }
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
    $sourceTreeEntries = @{}
    foreach ($sha in @(('1' * 40), ('2' * 40))) {
        $sourceTreeEntries["$sha|templates/project/.github/workflows/meandai-protocol-update.yml"] = $currentWorkflowBlob
        $sourceTreeEntries["$sha|templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1"] = $currentModuleBlob
        $sourceTreeEntries["$sha|templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1"] = $currentAdapterBlob
    }
    $sourceTreeEntries["$('3' * 40)|templates/project/.github/workflows/meandai-protocol-update.yml"] = $targetWorkflowBlob
    $sourceTreeEntries["$('3' * 40)|templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1"] = $currentModuleBlob
    $sourceTreeEntries["$('3' * 40)|templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1"] = $targetAdapterBlob
    $script:Scenario = [pscustomobject]@{
        Name = $Name
        Events = [System.Collections.Generic.List[string]]::new()
        GhCalls = [System.Collections.Generic.List[object]]::new()
        CurrentProtocolSha = '1' * 40
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
        ExpectedStagedPaths = @(
            '.ai/protocol',
            '.github/workflows/meandai-protocol-update.yml',
            '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        )
        OldBranchExists = $OldBranchExists
        NewBranchExists = $ExistingReplacement
        OldBranch = 'automation/meandai-protocol-v0.2.0'
        NewBranch = 'automation/meandai-protocol-v0.3.0'
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
        'PROTOCOL_TOKEN', 'GITHUB_STEP_SUMMARY'
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
$consumerCalls = @($success.GhCalls | Where-Object {
    @($_.Arguments | Where-Object {
        [string]$_ -like 'repos/hasanmanzak/meAndAI/*'
    }).Count -eq 0
})
if (@($protocolCalls | Where-Object { $_.Token -cne 'protocol-read-token' }).Count -ne 0 -or
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
    (Get-EventIndex $pendingLatest 'checkout-target-assets') -ge 0) {
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

Remove-Item Function:\git -ErrorAction SilentlyContinue
Remove-Item Function:\gh -ErrorAction SilentlyContinue
Remove-Variable MeAndAITestScenario -Scope Global -ErrorAction SilentlyContinue

if ($failures.Count -gt 0) {
    Write-Host "Protocol update adapter tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Protocol update adapter tests passed for all declared scenarios in this suite.' -ForegroundColor Green
