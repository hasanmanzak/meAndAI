[CmdletBinding()]
param(
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolPath = '.ai/protocol',
    [string]$ProtocolSourcePath = '.meandai-update-source',
    [string]$BranchPrefix = 'automation/meandai-protocol-',
    [string]$TrustedActor = 'github-actions[bot]'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Native {
    param([string]$Command, [string[]]$Arguments)

    $output = @(& $Command @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    $output
}

function Invoke-GhJson {
    param([string[]]$Arguments)
    $text = (Invoke-Native -Command 'gh' -Arguments $Arguments) -join [Environment]::NewLine
    if (-not $text) {
        return $null
    }
    $text | ConvertFrom-Json
}

function Invoke-GhPagedJson {
    param([string]$Endpoint)

    $encodedItems = @(Invoke-Native -Command 'gh' -Arguments @(
        'api', '--paginate', '--jq', '.[] | @base64', $Endpoint
    ))
    foreach ($encodedItem in $encodedItems) {
        $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]$encodedItem).Trim()))
        $json | ConvertFrom-Json
    }
}

function Add-RunSummary {
    param([string]$Text)
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

function Get-ProtocolMarker {
    param([string]$Body)

    $empty = [pscustomobject]@{
        Schema = 0; Target = ''; ProtocolSha = ''; Head = ''; Repository = ''
    }
    if (-not $Body) {
        return $empty
    }

    $markerPrefix = '<!-- meandai-protocol-update:'
    $prefixCount = 0
    $searchIndex = 0
    while ($searchIndex -lt $Body.Length) {
        $foundIndex = $Body.IndexOf(
            $markerPrefix, $searchIndex, [StringComparison]::OrdinalIgnoreCase
        )
        if ($foundIndex -lt 0) {
            break
        }
        $prefixCount++
        $searchIndex = $foundIndex + $markerPrefix.Length
    }
    if ($prefixCount -ne 1) {
        return $empty
    }

    $markerMatches = [regex]::Matches(
        $Body, '<!-- meandai-protocol-update:(?<json>\{[^\r\n]+\}) -->'
    )
    if ($markerMatches.Count -ne 1) {
        return $empty
    }
    $match = $markerMatches[0]
    try {
        $json = $match.Groups['json'].Value
        $marker = $json | ConvertFrom-Json
        $expectedNames = @('schema', 'target', 'protocolSha', 'head', 'repository')
        $properties = @($marker.PSObject.Properties)
        if ($properties.Count -ne $expectedNames.Count) {
            return $empty
        }
        for ($index = 0; $index -lt $expectedNames.Count; $index++) {
            if (-not [string]::Equals(
                [string]$properties[$index].Name,
                [string]$expectedNames[$index],
                [StringComparison]::Ordinal
            )) {
                return $empty
            }
        }
        if (($marker.schema -isnot [int] -and $marker.schema -isnot [long]) -or
            [long]$marker.schema -ne 1 -or
            $marker.target -isnot [string] -or
            $marker.protocolSha -isnot [string] -or
            $marker.head -isnot [string] -or
            $marker.repository -isnot [string]) {
            return $empty
        }
        $canonicalJson = [ordered]@{
            schema = 1
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = [string]$marker.head
            repository = [string]$marker.repository
        } | ConvertTo-Json -Compress
        if ($json -cne $canonicalJson) {
            return $empty
        }
        [pscustomobject]@{
            Schema = 1
            Target = [string]$marker.target
            Head = [string]$marker.head
            ProtocolSha = [string]$marker.protocolSha
            Repository = [string]$marker.repository
        }
    }
    catch {
        $empty
    }
}

function Remove-RemoteBranch {
    param([string]$Branch, [string]$ExpectedHeadSha)

    if ($ExpectedHeadSha -notmatch '^[0-9a-f]{40}$') {
        throw "Refusing to delete '$Branch' without an exact expected head SHA."
    }
    $ref = "refs/heads/$Branch"
    Invoke-Native -Command 'git' -Arguments @(
        'push', "--force-with-lease=${ref}:$ExpectedHeadSha", 'origin', ":$ref"
    ) | Out-Null
}

function Get-RemoteBranchHead {
    param([string]$Branch)

    $output = @(& git ls-remote --exit-code --heads origin "refs/heads/$Branch" 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 2) {
        return $null
    }
    if ($exitCode -ne 0) {
        throw "Unable to inspect remote branch '$Branch'; git exited with $exitCode."
    }
    if ($output.Count -ne 1) {
        throw "Remote branch '$Branch' returned an ambiguous ref result."
    }

    $parts = ([string]$output[0]).Trim() -split '\s+', 2
    if ($parts.Count -ne 2 -or $parts[0] -notmatch '^[0-9a-f]{40}$' -or
        $parts[1] -ne "refs/heads/$Branch") {
        throw "Remote branch '$Branch' returned an invalid ref result."
    }
    return $parts[0]
}

function Get-ProtocolTreeEntry {
    param([string]$Repository, [string]$HeadSha, [string]$ProtocolPath)

    $empty = [pscustomobject]@{ Mode = ''; Sha = '' }
    $segments = @($ProtocolPath.Split('/', [StringSplitOptions]::RemoveEmptyEntries))
    if ($segments.Count -eq 0) {
        return $empty
    }

    $commit = Invoke-GhJson -Arguments @(
        'api', "repos/$Repository/git/commits/$HeadSha"
    )
    $treeSha = [string]$commit.tree.sha
    if ($treeSha -notmatch '^[0-9a-f]{40}$') {
        return $empty
    }

    for ($index = 0; $index -lt $segments.Count; $index++) {
        $tree = Invoke-GhJson -Arguments @('api', "repos/$Repository/git/trees/$treeSha")
        $matches = @($tree.tree | Where-Object {
            [string]::Equals([string]$_.path, [string]$segments[$index], [StringComparison]::Ordinal)
        })
        if ($matches.Count -ne 1) {
            return $empty
        }
        $entry = $matches[0]
        if ($index -eq $segments.Count - 1) {
            return [pscustomobject]@{ Mode = [string]$entry.mode; Sha = [string]$entry.sha }
        }
        if ([string]$entry.type -ne 'tree' -or [string]$entry.mode -ne '040000' -or
            [string]$entry.sha -notmatch '^[0-9a-f]{40}$') {
            return $empty
        }
        $treeSha = [string]$entry.sha
    }

    return $empty
}

function Assert-ManagedPullRequestSafe {
    param(
        [string]$Repository,
        $Operation,
        [string]$ProtocolPath,
        [string]$TrustedActor
    )

    $number = [int]$Operation.PullRequestNumber
    $details = Invoke-GhJson -Arguments @('api', "repos/$Repository/pulls/$number")
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/pulls/$number/files?per_page=100")
    $marker = Get-ProtocolMarker ([string]$details.body)
    $protocolEntry = Get-ProtocolTreeEntry -Repository $Repository `
        -HeadSha ([string]$details.head.sha) -ProtocolPath $ProtocolPath
    $remoteHead = Get-RemoteBranchHead -Branch ([string]$Operation.Branch)
    $changedPaths = @($files | ForEach-Object { [string]$_.filename })
    $state = [string]$details.state
    $candidate = [pscustomobject]@{
        PullRequestState = if ($state) {
            $state.Substring(0, 1).ToUpperInvariant() + $state.Substring(1)
        } else { '' }
        TargetTag = [string]$Operation.TargetTag
        HeadRef = [string]$details.head.ref
        BranchExists = $null -ne $remoteHead
        ExpectedHeadSha = [string]$Operation.ExpectedHeadSha
        ApiHeadSha = [string]$details.head.sha
        ObservedHeadSha = if ($null -ne $remoteHead) { [string]$remoteHead } else { '' }
        MarkerSchema = $marker.Schema
        MarkerTargetTag = $marker.Target
        MarkerProtocolSha = $marker.ProtocolSha
        MarkerHeadSha = $marker.Head
        MarkerRepository = $marker.Repository
        ExpectedProtocolSha = [string]$Operation.ExpectedProtocolSha
        ProtocolEntryMode = $protocolEntry.Mode
        ProtocolEntrySha = $protocolEntry.Sha
        BaseRef = [string]$details.base.ref
        Draft = [bool]$details.draft
        SameRepository = $null -ne $details.head.repo -and
            [string]$details.head.repo.full_name -ceq $Repository
        AuthorLogin = [string]$details.user.login
        ChangedPaths = $changedPaths
    }
    $context = [pscustomobject]@{
        Repository = $Repository; DefaultBranch = [string]$env:DEFAULT_BRANCH
        BranchPrefix = [string]$script:BranchPrefix
        ProtocolPath = $ProtocolPath; TrustedActor = $TrustedActor
    }
    $problems = @(Get-MeAndAIProtocolCandidateProblems -Candidate $candidate -Context $context)

    if ($problems.Count -gt 0) {
        throw "Managed PR #$number changed after planning: $($problems -join '; ')."
    }
}

foreach ($name in @('GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN')) {
    if (-not [Environment]::GetEnvironmentVariable($name)) {
        throw "Required workflow environment '$name' is missing."
    }
}

$workspace = [IO.Path]::GetFullPath($env:GITHUB_WORKSPACE)
Set-Location -LiteralPath $workspace
$modulePath = Join-Path $workspace '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
$sourcePath = [IO.Path]::GetFullPath((Join-Path $workspace $ProtocolSourcePath))
if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Pure resolver is missing: $modulePath"
}
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath '.git'))) {
    throw "Pinned protocol source checkout is missing: $sourcePath"
}
Import-Module $modulePath -Force

$submodulePaths = @(Invoke-Native -Command 'git' -Arguments @(
    'config', '-f', '.gitmodules', '--get-regexp', '^submodule\..*\.path$'
))
$matchingSubmodules = @($submodulePaths | Where-Object {
    ([string]$_) -match '^(?<key>submodule\..+\.path)\s+(?<path>.+)$' -and
    $Matches.path -eq $ProtocolPath
})
if ($matchingSubmodules.Count -ne 1) {
    throw "'$ProtocolPath' must have exactly one .gitmodules entry."
}
$submoduleMatch = [regex]::Match([string]$matchingSubmodules[0], '^(?<key>submodule\..+\.path)\s+')
if (-not $submoduleMatch.Success) { throw 'Protocol submodule metadata is malformed.' }
$pathKey = $submoduleMatch.Groups['key'].Value
$urlKey = $pathKey.Substring(0, $pathKey.Length - '.path'.Length) + '.url'
$submoduleUrl = ((Invoke-Native -Command 'git' -Arguments @(
    'config', '-f', '.gitmodules', '--get', $urlKey
)) -join '').Trim()
$allowedUrls = @(
    "https://github.com/$ProtocolRepository", "https://github.com/$ProtocolRepository.git",
    "git@github.com:$ProtocolRepository", "git@github.com:$ProtocolRepository.git",
    "ssh://git@github.com/$ProtocolRepository", "ssh://git@github.com/$ProtocolRepository.git"
)
if ($submoduleUrl -notin $allowedUrls) {
    throw "Protocol submodule URL does not match '$ProtocolRepository'."
}

$treeEntry = (Invoke-Native -Command 'git' -Arguments @('ls-tree', 'HEAD', '--', $ProtocolPath)) -join ''
if ($treeEntry -notmatch '^160000\s+commit\s+(?<sha>[0-9a-f]{40})\s+') {
    throw "'$ProtocolPath' is not a protocol submodule gitlink."
}
$currentProtocolSha = $Matches.sha

$availableTags = @(
    Invoke-Native -Command 'git' -Arguments @('-C', $sourcePath, 'tag', '--list', 'v*') |
        ForEach-Object { [string]$_ }
)
$currentTags = [System.Collections.Generic.List[string]]::new()
foreach ($tag in $availableTags) {
    if (-not (Test-MeAndAIProtocolTag -Tag $tag)) {
        continue
    }
    $tagSha = ((Invoke-Native -Command 'git' -Arguments @('-C', $sourcePath, 'rev-list', '-n', '1', $tag)) -join '').Trim()
    if ($tagSha -eq $currentProtocolSha) {
        $currentTags.Add($tag)
    }
}
if ($currentTags.Count -ne 1) {
    throw "Current protocol gitlink $currentProtocolSha must resolve to exactly one canonical stable release tag; found $($currentTags.Count)."
}
$currentTag = $currentTags[0]

$repository = $env:GITHUB_REPOSITORY
$pulls = @(Invoke-GhPagedJson -Endpoint "repos/$repository/pulls?state=open&per_page=100")
$candidates = [System.Collections.Generic.List[object]]::new()
foreach ($pull in $pulls) {
    $summaryHeadRef = [string]$pull.head.ref
    $summaryBody = if ('body' -in $pull.PSObject.Properties.Name) {
        [string]$pull.body
    }
    else { '' }
    $hasReservedPrefix = $summaryHeadRef.StartsWith($BranchPrefix, [StringComparison]::Ordinal)
    $hasMarkerPrefix = $summaryBody.IndexOf(
        '<!-- meandai-protocol-update:', [StringComparison]::OrdinalIgnoreCase
    ) -ge 0
    if (-not $hasReservedPrefix -and -not $hasMarkerPrefix) {
        continue
    }

    $details = Invoke-GhJson -Arguments @('api', "repos/$repository/pulls/$($pull.number)")
    $marker = Get-ProtocolMarker ([string]$details.body)
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$repository/pulls/$($pull.number)/files?per_page=100")
    $headRef = [string]$details.head.ref
    $target = if ($headRef.StartsWith($BranchPrefix, [StringComparison]::Ordinal)) {
        $headRef.Substring($BranchPrefix.Length)
    }
    else { '' }
    $expectedProtocolSha = ''
    if ((Test-MeAndAIProtocolTag -Tag $target) -and $availableTags -ccontains $target) {
        $expectedProtocolSha = ((Invoke-Native -Command 'git' -Arguments @(
            '-C', $sourcePath, 'rev-list', '-n', '1', $target
        )) -join '').Trim()
    }
    $protocolEntry = Get-ProtocolTreeEntry -Repository $repository `
        -HeadSha ([string]$details.head.sha) -ProtocolPath $ProtocolPath
    $observedRemoteHead = Get-RemoteBranchHead -Branch ([string]$details.head.ref)
    $candidates.Add([pscustomobject]@{
        PullRequestNumber = [int]$details.number
        PullRequestState = [string]$details.state.Substring(0, 1).ToUpperInvariant() + [string]$details.state.Substring(1)
        TargetTag = $target
        HeadRef = $headRef
        BranchExists = $null -ne $observedRemoteHead
        ExpectedHeadSha = $marker.Head
        ApiHeadSha = [string]$details.head.sha
        ObservedHeadSha = if ($null -ne $observedRemoteHead) { [string]$observedRemoteHead } else { '' }
        MarkerSchema = $marker.Schema
        MarkerTargetTag = $marker.Target
        MarkerProtocolSha = $marker.ProtocolSha
        MarkerHeadSha = $marker.Head
        MarkerRepository = $marker.Repository
        ExpectedProtocolSha = $expectedProtocolSha
        ProtocolEntryMode = $protocolEntry.Mode
        ProtocolEntrySha = $protocolEntry.Sha
        BaseRef = [string]$details.base.ref
        Draft = [bool]$details.draft
        SameRepository = $null -ne $details.head.repo -and [string]$details.head.repo.full_name -ceq $repository
        AuthorLogin = [string]$details.user.login
        ChangedPaths = @($files | ForEach-Object { [string]$_.filename })
    })
}

$snapshot = [pscustomobject]@{
    SchemaVersion = 1
    CurrentTag = $currentTag
    AvailableTags = $availableTags
    Repository = $repository
    DefaultBranch = $env:DEFAULT_BRANCH
    BranchPrefix = $BranchPrefix
    ProtocolPath = $ProtocolPath
    TrustedActor = $TrustedActor
    Candidates = @($candidates)
}
$plan = Resolve-MeAndAIProtocolUpdatePlan -Snapshot $snapshot
Add-RunSummary "## meAndAI protocol update`n`n- Current: ``$($plan.CurrentTag)```n- Latest compatible: ``$($plan.LatestCompatibleTag)```n- State: ``$($plan.State)``"

if ($plan.State -eq 'BlockedManualReview') {
    throw "Protocol update requires manual review: $($plan.Diagnostics -join '; ')"
}
if ($plan.State -eq 'MajorUpgradeRequired') {
    throw "A new protocol major '$($plan.LatestAvailableTag)' requires a manual migration."
}
if (@($plan.Operations).Count -eq 0) {
    Write-Host "Protocol update state: $($plan.State). No mutation required."
    exit 0
}

$create = @($plan.Operations | Where-Object Kind -eq 'CreateUpgrade')
if ($create.Count -gt 1) {
    throw 'Resolver produced more than one replacement creation.'
}

$createdPullRequest = $null
$createdBranch = $null
$createdOperation = $null
if ($create.Count -eq 1) {
    $targetTag = [string]$create[0].TargetTag
    $targetSha = ((Invoke-Native -Command 'git' -Arguments @('-C', $sourcePath, 'rev-list', '-n', '1', $targetTag)) -join '').Trim()
    & git -C $sourcePath merge-base --is-ancestor $currentProtocolSha $targetSha
    if ($LASTEXITCODE -ne 0) {
        throw "Target '$targetTag' is not a descendant of current protocol '$currentTag'."
    }

    $createdBranch = [string]$create[0].Branch
    if ($null -ne (Get-RemoteBranchHead -Branch $createdBranch)) {
        throw "Reserved target branch '$createdBranch' already exists without a valid managed PR."
    }

    Invoke-Native -Command 'git' -Arguments @('switch', '-c', $createdBranch) | Out-Null
    Invoke-Native -Command 'git' -Arguments @('update-index', '--add', '--cacheinfo', "160000,$targetSha,$ProtocolPath") | Out-Null
    $stagedPaths = @(Invoke-Native -Command 'git' -Arguments @('diff', '--cached', '--name-only'))
    if ($stagedPaths.Count -ne 1 -or [string]$stagedPaths[0] -ne $ProtocolPath) {
        throw "Upgrade staging escaped the protocol gitlink: $($stagedPaths -join ', ')."
    }

    Invoke-Native -Command 'git' -Arguments @('config', 'user.name', 'github-actions[bot]') | Out-Null
    Invoke-Native -Command 'git' -Arguments @('config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com') | Out-Null
    Invoke-Native -Command 'git' -Arguments @('commit', '-m', "Upgrade common protocol to $targetTag") | Out-Null
    $headSha = ((Invoke-Native -Command 'git' -Arguments @('rev-parse', 'HEAD')) -join '').Trim()

    $pushSucceeded = $false
    $marker = ''
    try {
        $createdRef = "refs/heads/$createdBranch"
        Invoke-Native -Command 'git' -Arguments @(
            'push', '--set-upstream', "--force-with-lease=${createdRef}:",
            'origin', "$createdBranch`:$createdRef"
        ) | Out-Null
        $pushSucceeded = $true
        $marker = [ordered]@{
            schema = 1; target = $targetTag; protocolSha = $targetSha
            head = $headSha; repository = $repository
        } | ConvertTo-Json -Compress
        $supersededNumbers = @($plan.Operations | Where-Object Kind -eq 'ClosePullRequest' |
            ForEach-Object { "#$($_.PullRequestNumber)" })
        $supersedes = if ($supersededNumbers.Count -gt 0) { $supersededNumbers -join ', ' } else { 'none' }
        $body = @(
            "<!-- meandai-protocol-update:$marker -->",
            '## Automated protocol dependency update', '',
            "- Current pin: ``$currentTag``", "- Proposed pin: ``$targetTag``",
            "- Protocol commit: ``$targetSha``", "- Supersedes: $supersedes", '',
            'This draft is review-only and will never merge itself.', '',
            '## Maintainer gates', '',
            '- [ ] Create or link the tracked issue and allocate its stable work ID.',
            '- [ ] Read every intervening meAndAI changelog entry.',
            '- [ ] Review incompatible or newly mandatory rules.',
            '- [ ] Reconcile copied templates without overwriting project customizations.',
            '- [ ] Update the consumer project memory pinned-version fact.',
            '- [ ] Run project tests and complete DoR/DoD review.'
        ) -join [Environment]::NewLine
        $url = (Invoke-Native -Command 'gh' -Arguments @(
            'pr', 'create', '--draft', '--base', $env:DEFAULT_BRANCH,
            '--head', $createdBranch, '--title', "Upgrade common protocol to $targetTag",
            '--body', $body
        ) | Select-Object -Last 1).Trim()
        $urlMatch = [regex]::Match($url, '/pull/(?<number>\d+)/?$')
        if (-not $urlMatch.Success) {
            throw "Created replacement PR returned an unrecognized URL."
        }
        $createdPullRequest = [pscustomobject]@{ number = [int]$urlMatch.Groups['number'].Value }
        $createdOperation = [pscustomobject]@{
            PullRequestNumber = [int]$createdPullRequest.number
            Branch = $createdBranch
            ExpectedHeadSha = $headSha
            TargetTag = $targetTag
            ExpectedProtocolSha = $targetSha
        }
        Assert-ManagedPullRequestSafe -Repository $repository -Operation $createdOperation `
            -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor
        $createdPullRequest = [pscustomobject]@{ number = [int]$createdPullRequest.number }
        Write-Host "Created replacement draft PR: $url"
    }
    catch {
        $creationError = $_.Exception
        $safeToDeleteBranch = $false
        $rollbackClosedPullRequestNumber = $null
        if ($pushSucceeded) {
            try {
                $owner = $repository.Split('/')[0]
                $replacementPulls = @(Invoke-GhPagedJson -Endpoint "repos/$repository/pulls?state=all&head=$owner`:$createdBranch&per_page=100")
                if ($replacementPulls.Count -eq 0) {
                    $safeToDeleteBranch = $true
                }
                elseif ($replacementPulls.Count -eq 1) {
                    if ($null -eq $createdOperation -or
                        [int]$replacementPulls[0].number -ne [int]$createdOperation.PullRequestNumber) {
                        throw 'Replacement PR identity is ambiguous during rollback.'
                    }
                    Assert-ManagedPullRequestSafe -Repository $repository -Operation $createdOperation `
                        -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor
                    Invoke-Native -Command 'gh' -Arguments @(
                        'api', '--method', 'PATCH', "repos/$repository/pulls/$($createdOperation.PullRequestNumber)",
                        '-f', 'state=closed'
                    ) | Out-Null
                    $rollbackClosedPullRequestNumber = [int]$createdOperation.PullRequestNumber
                    $safeToDeleteBranch = $true
                }
            }
            catch {
                Write-Warning "Unable to establish safe replacement rollback ownership; preserving PR and branch '$createdBranch'."
            }
        }
        if ($safeToDeleteBranch) {
            try {
                $remoteHead = Get-RemoteBranchHead -Branch $createdBranch
                if ($null -eq $remoteHead -and $null -ne $rollbackClosedPullRequestNumber) {
                    throw "Replacement branch '$createdBranch' disappeared after its PR was closed."
                }
                if ($null -ne $remoteHead -and $remoteHead -ne $headSha) {
                    throw "Replacement branch '$createdBranch' changed before rollback deletion."
                }
                if ($null -ne $remoteHead) {
                    Remove-RemoteBranch -Branch $createdBranch -ExpectedHeadSha $headSha
                }
            }
            catch {
                $rollbackError = $_.Exception.Message
                if ($null -ne $rollbackClosedPullRequestNumber) {
                    try {
                        Invoke-Native -Command 'gh' -Arguments @(
                            'api', '--method', 'PATCH', "repos/$repository/pulls/$rollbackClosedPullRequestNumber",
                            '-f', 'state=open'
                        ) | Out-Null
                    }
                    catch {
                        Write-Warning "Replacement rollback failed and PR #$rollbackClosedPullRequestNumber could not be reopened; manual recovery is required."
                    }
                }
                Write-Warning "Unable to roll back replacement branch '$createdBranch' with its expected-head lease: $rollbackError"
            }
        }
        throw $creationError
    }
}

$replacementPullRequestNumber = $null
$replacementOperation = $null
if ($plan.State -eq 'Supersede') {
    if ($null -ne $createdPullRequest) {
        $replacementPullRequestNumber = [int]$createdPullRequest.number
        $replacementOperation = $createdOperation
    }
    else {
        $existingReplacements = @($candidates | Where-Object {
            $_.TargetTag -eq $plan.LatestCompatibleTag
        })
        if ($existingReplacements.Count -ne 1) {
            throw 'Unable to identify exactly one verified replacement PR before cleanup.'
        }
        $replacement = $existingReplacements[0]
        $replacementPullRequestNumber = [int]$replacement.PullRequestNumber
        $replacementOperation = [pscustomobject]@{
            PullRequestNumber = [int]$replacement.PullRequestNumber
            Branch = [string]$replacement.HeadRef
            ExpectedHeadSha = [string]$replacement.ObservedHeadSha
            TargetTag = [string]$replacement.TargetTag
            ExpectedProtocolSha = [string]$replacement.ExpectedProtocolSha
        }
    }
}

$deleteOperations = @($plan.Operations | Where-Object Kind -eq 'DeleteBranch')
foreach ($operation in @($plan.Operations | Where-Object Kind -eq 'ClosePullRequest')) {
    $deleteOperation = @($deleteOperations | Where-Object {
        $_.PullRequestNumber -eq $operation.PullRequestNumber -and $_.Branch -eq $operation.Branch
    })
    if ($deleteOperation.Count -ne 1) {
        throw "Resolver did not provide exactly one paired branch cleanup for PR #$($operation.PullRequestNumber)."
    }
    Assert-ManagedPullRequestSafe -Repository $repository -Operation $operation `
        -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor
    if ($null -ne $replacementOperation) {
        Assert-ManagedPullRequestSafe -Repository $repository -Operation $replacementOperation `
            -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor
    }
    $comment = if ($null -ne $replacementPullRequestNumber) {
        "Superseded by #$replacementPullRequestNumber, the verified ``$($plan.LatestCompatibleTag)`` protocol proposal. Automated cleanup will attempt to close this PR and delete its unchanged branch. If branch deletion fails, the workflow will try to reopen the PR and preserve the branch."
    }
    else {
        "The default branch already contains ``$($operation.TargetTag)``. Automated cleanup will attempt to close this PR and delete its unchanged branch. If branch deletion fails, the workflow will try to reopen the PR and preserve the branch."
    }
    Invoke-Native -Command 'gh' -Arguments @('api', '--method', 'POST', "repos/$repository/issues/$($operation.PullRequestNumber)/comments", '-f', "body=$comment") | Out-Null
    Invoke-Native -Command 'gh' -Arguments @('api', '--method', 'PATCH', "repos/$repository/pulls/$($operation.PullRequestNumber)", '-f', 'state=closed') | Out-Null

    try {
        $remoteHead = Get-RemoteBranchHead -Branch ([string]$operation.Branch)
        if ($null -eq $remoteHead) {
            throw "Managed branch '$($operation.Branch)' disappeared before deletion."
        }
        if ($remoteHead -ne [string]$operation.ExpectedHeadSha) {
            throw "Managed branch '$($operation.Branch)' changed before deletion."
        }
        Remove-RemoteBranch -Branch ([string]$operation.Branch) `
            -ExpectedHeadSha ([string]$operation.ExpectedHeadSha)
    }
    catch {
        $cleanupError = $_.Exception.Message
        try {
            Invoke-Native -Command 'gh' -Arguments @(
                'api', '--method', 'PATCH', "repos/$repository/pulls/$($operation.PullRequestNumber)",
                '-f', 'state=open'
            ) | Out-Null
        }
        catch {
            throw "Branch cleanup failed for PR #$($operation.PullRequestNumber), and the PR could not be reopened. Manual recovery is required. Original error: $cleanupError"
        }
        throw "Branch cleanup failed for PR #$($operation.PullRequestNumber); the PR was reopened and the branch preserved. $cleanupError"
    }
}

Write-Host "Protocol update reconciliation completed: $($plan.State)."
