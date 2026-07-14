[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adapterSource = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$moduleSource = Join-Path $root 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
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
        [bool]$Draft = $true
    )

    [pscustomobject]@{
        number = $Number
        state = 'open'
        draft = $Draft
        body = $Body
        user = [pscustomobject]@{ login = 'github-actions[bot]' }
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
            "submodule.meandai.path`t.ai/protocol"
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
    if ($arguments[0] -eq 'ls-tree') {
        "160000 commit $($script:Scenario.CurrentProtocolSha)`t.ai/protocol"
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
            'v0.3.0' { $script:Scenario.TargetProtocolSha }
            default { throw "Unexpected tag lookup '$($arguments[-1])'." }
        }
        return
    }
    if ($arguments[0] -eq '-C' -and $arguments[2] -eq 'merge-base') {
        Add-ScenarioEvent 'verify-lineage'
        return
    }
    if ($arguments[0] -eq 'ls-remote') {
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
        '.ai/protocol'
        return
    }
    if ($arguments[0] -eq 'rev-parse') {
        $script:Scenario.NewHead
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

    if ($arguments[0] -eq 'pr' -and $arguments[1] -eq 'create') {
        $bodyIndex = [array]::IndexOf($arguments, '--body')
        $script:Scenario.NewBody = $arguments[$bodyIndex + 1]
        Add-ScenarioEvent 'create-new-pr'
        'https://github.com/owner/consumer/pull/30'
        return
    }
    if ($arguments[0] -ne 'api') {
        throw "Unexpected fake gh command: $($arguments -join ' ')"
    }

    $endpoint = @($arguments | Where-Object { $_ -like 'repos/*' })[0]
    $method = 'GET'
    $methodIndex = [array]::IndexOf($arguments, '--method')
    if ($methodIndex -ge 0) {
        $method = $arguments[$methodIndex + 1]
    }

    if ($method -eq 'POST' -and $endpoint -like '*/issues/21/comments') {
        Add-ScenarioEvent 'comment-old-pr'
        '{}'
        return
    }
    if ($method -eq 'PATCH' -and $endpoint -like '*/pulls/21') {
        if ($arguments -contains 'state=open') {
            Add-ScenarioEvent 'reopen-old-pr'
        }
        else {
            Add-ScenarioEvent 'close-old-pr'
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
            ConvertTo-TestBase64Json ([pscustomobject]@{
                number = 21; body = $script:Scenario.OldBody
                head = [pscustomobject]@{ ref = $script:Scenario.OldBranch }
            })
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
            -HeadSha $head -Body $script:Scenario.OldBody
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls/21/files?per_page=100') {
        ConvertTo-TestBase64Json ([pscustomobject]@{ filename = '.ai/protocol' })
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
            tree = @([pscustomobject]@{
                path = '.ai'; mode = '040000'; type = 'tree'; sha = 'e' * 40
            })
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -eq "repos/owner/consumer/git/trees/$('d' * 40)") {
        [pscustomobject]@{
            tree = @([pscustomobject]@{
                path = '.ai'; mode = '040000'; type = 'tree'; sha = 'f' * 40
            })
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
    if ($endpoint -eq 'repos/owner/consumer/pulls/30') {
        $script:Scenario.NewDetailCalls++
        Add-ScenarioEvent 'verify-new-pr'
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
        ConvertTo-TestPullJson -Number 30 -Branch $script:Scenario.NewBranch `
            -HeadSha $script:Scenario.NewHead -Body $script:Scenario.NewBody `
            -Draft $newDraft
        return
    }
    if ($endpoint -eq 'repos/owner/consumer/pulls/30/files?per_page=100') {
        ConvertTo-TestBase64Json ([pscustomobject]@{ filename = '.ai/protocol' })
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
        [bool]$MutateNewAfterSnapshot = $false,
        [bool]$CoordinateNewHeadMutation = $false,
        [bool]$ConcurrentNewBranch = $false,
        [bool]$OldBranchExists = $true,
        [bool]$RemoveOldBeforeDelete = $false,
        [bool]$ChangeOldBeforeDelete = $false,
        [bool]$AliasCurrentTag = $false,
        [bool]$DuplicateOldMarker = $false,
        [bool]$CaseVariantDuplicateMarker = $false,
        [bool]$NonCanonicalOldMarker = $false,
        [bool]$InvalidSubmoduleUrl = $false,
        [int]$LeadingUnmanagedCount = 0
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-adapter-$Name-$([guid]::NewGuid().ToString('N'))"
    $scriptsPath = Join-Path $tempRoot '.github/scripts'
    $sourceGitPath = Join-Path $tempRoot '.meandai-update-source/.git'
    New-Item -ItemType Directory -Force $scriptsPath, $sourceGitPath | Out-Null
    Copy-Item -LiteralPath $moduleSource -Destination (Join-Path $scriptsPath 'MeAndAI.ProtocolUpdate.psm1')
    Copy-Item -LiteralPath $adapterSource -Destination (Join-Path $scriptsPath 'Invoke-MeAndAIProtocolUpdate.ps1')

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
    $script:Scenario = [pscustomobject]@{
        Name = $Name
        Events = [System.Collections.Generic.List[string]]::new()
        CurrentProtocolSha = '1' * 40
        MiddleProtocolSha = '2' * 40
        TargetProtocolSha = '3' * 40
        OldProtocolSha = '2' * 40
        OldHead = $oldHead
        ExpectedOldHead = $oldHead
        NewHead = 'b' * 40
        OldBranchExists = $OldBranchExists
        NewBranchExists = $ExistingReplacement
        OldBranch = 'automation/meandai-protocol-v0.2.0'
        NewBranch = 'automation/meandai-protocol-v0.3.0'
        OldBody = $oldBody
        NewBody = $initialNewBody
        NewDraft = $NewDraft
        MutateOldAfterSnapshot = $MutateOldAfterSnapshot
        ConcurrentNewBranch = $ConcurrentNewBranch
        ChangeOldBeforeDelete = $ChangeOldBeforeDelete
        AliasCurrentTag = $AliasCurrentTag
        ExistingReplacement = $ExistingReplacement
        MutateNewAfterSnapshot = $MutateNewAfterSnapshot
        CoordinateNewHeadMutation = $CoordinateNewHeadMutation
        NewDetailCalls = 0
        InvalidSubmoduleUrl = $InvalidSubmoduleUrl
        LeadingUnmanagedCount = $LeadingUnmanagedCount
        RemoveOldBeforeDelete = $RemoveOldBeforeDelete
        OldProbeCalls = 0

        OldDetailCalls = 0
        Threw = $false
        Error = ''
    }
    $global:MeAndAITestScenario = $script:Scenario

    $savedEnvironment = @{}
    foreach ($nameKey in @('GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN', 'GITHUB_STEP_SUMMARY')) {
        $savedEnvironment[$nameKey] = [Environment]::GetEnvironmentVariable($nameKey)
    }
    $savedLocation = Get-Location

    try {
        $env:GITHUB_REPOSITORY = 'owner/consumer'
        $env:GITHUB_WORKSPACE = $tempRoot
        $env:DEFAULT_BRANCH = 'main'
        $env:GH_TOKEN = 'redacted-test-token'
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
$successOrder = @('create-new-pr', 'verify-new-pr', 'read-old-pr-2', 'close-old-pr', 'delete-old-branch')
$previous = -1
foreach ($event in $successOrder) {
    $index = Get-EventIndex -Scenario $success -Event $event
    if ($index -le $previous) {
        Add-Failure "TEST-0011 adapter event '$event' is missing or out of replacement-first order: $($success.Events -join ', ')"
        break
    }
    $previous = $index
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

Remove-Item Function:\git -ErrorAction SilentlyContinue
Remove-Item Function:\gh -ErrorAction SilentlyContinue
Remove-Variable MeAndAITestScenario -Scope Global -ErrorAction SilentlyContinue

if ($failures.Count -gt 0) {
    Write-Host "Protocol update adapter tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Protocol update adapter tests passed: TEST-0011 and TEST-0015.' -ForegroundColor Green
