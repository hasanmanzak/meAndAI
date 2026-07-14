Set-StrictMode -Version Latest

function ConvertTo-ProtocolVersionRecord {
    param([string]$Tag)

    if ($Tag -cnotmatch '^v(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<revision>0|[1-9]\d*)$') {
        return $null
    }

    try {
        $version = [version]('{0}.{1}.{2}' -f $Matches.major, $Matches.minor, $Matches.revision)
    }
    catch {
        return $null
    }

    [pscustomobject]@{
        Tag = $Tag
        Version = $version
    }
}

function Test-MeAndAIProtocolTag {
    [CmdletBinding()]
    param([string]$Tag)

    return $null -ne (ConvertTo-ProtocolVersionRecord $Tag)
}

function Get-MeAndAIProtocolCandidateProblems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Candidate,
        [Parameter(Mandatory)]$Context
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    $target = [string]$Candidate.TargetTag

    if ([string]$Candidate.PullRequestState -cne 'Open') {
        $problems.Add('state is not open')
    }
    if ([string]$Candidate.HeadRef -cne "$($Context.BranchPrefix)$target") {
        $problems.Add('head branch is not the deterministic target branch')
    }
    if (-not [bool]$Candidate.BranchExists) {
        $problems.Add('remote branch is missing')
    }
    if (-not [bool]$Candidate.SameRepository) {
        $problems.Add('head repository is not the consumer repository')
    }
    if ([string]$Candidate.AuthorLogin -cne [string]$Context.TrustedActor) {
        $problems.Add('author is not the trusted automation actor')
    }
    if ([string]$Candidate.BaseRef -cne [string]$Context.DefaultBranch) {
        $problems.Add('base branch changed')
    }
    if (-not [bool]$Candidate.Draft) {
        $problems.Add('pull request is no longer draft')
    }
    if ([int]$Candidate.MarkerSchema -ne 1 -or
        [string]$Candidate.MarkerTargetTag -cne $target -or
        [string]$Candidate.MarkerRepository -cne [string]$Context.Repository) {
        $problems.Add('ownership marker metadata changed')
    }
    if ([string]$Candidate.ExpectedProtocolSha -cnotmatch '^[0-9a-f]{40}$' -or
        [string]$Candidate.MarkerProtocolSha -cne [string]$Candidate.ExpectedProtocolSha -or
        [string]$Candidate.ProtocolEntryMode -cne '160000' -or
        [string]$Candidate.ProtocolEntrySha -cne [string]$Candidate.ExpectedProtocolSha) {
        $problems.Add('protocol gitlink does not match the declared release')
    }
    if ([string]$Candidate.ExpectedHeadSha -cnotmatch '^[0-9a-f]{40}$' -or
        [string]$Candidate.MarkerHeadSha -cne [string]$Candidate.ExpectedHeadSha -or
        [string]$Candidate.ApiHeadSha -cne [string]$Candidate.ExpectedHeadSha -or
        [string]$Candidate.ObservedHeadSha -cne [string]$Candidate.ExpectedHeadSha) {
        $problems.Add('head SHA changed')
    }
    $changedPaths = @($Candidate.ChangedPaths)
    if ($changedPaths.Count -ne 1 -or
        [string]$changedPaths[0] -cne [string]$Context.ProtocolPath) {
        $problems.Add('changed paths are no longer protocol-only')
    }

    return @($problems)
}

function New-BlockedProtocolUpdatePlan {
    param(
        [string]$CurrentTag,
        [string]$LatestCompatibleTag,
        [string]$LatestAvailableTag,
        [string[]]$IgnoredTags,
        [string[]]$Diagnostics
    )

    [pscustomobject]@{
        SchemaVersion = 1
        State = 'BlockedManualReview'
        CurrentTag = $CurrentTag
        LatestCompatibleTag = $LatestCompatibleTag
        LatestAvailableTag = $LatestAvailableTag
        MajorUpgradeAvailable = $false
        IgnoredTags = @($IgnoredTags)
        Diagnostics = @($Diagnostics)
        Operations = @()
    }
}

function Resolve-MeAndAIProtocolUpdatePlan {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)

    $diagnostics = [System.Collections.Generic.List[string]]::new()
    $ignoredTags = [System.Collections.Generic.List[string]]::new()
    $requiredSnapshotProperties = @(
        'SchemaVersion', 'CurrentTag', 'AvailableTags', 'Repository',
        'DefaultBranch', 'BranchPrefix', 'ProtocolPath', 'TrustedActor', 'Candidates'
    )

    foreach ($property in $requiredSnapshotProperties) {
        if ($property -notin $Snapshot.PSObject.Properties.Name) {
            $diagnostics.Add("Snapshot is missing '$property'.")
        }
    }

    if ($diagnostics.Count -gt 0) {
        return New-BlockedProtocolUpdatePlan -CurrentTag '' -LatestCompatibleTag '' -LatestAvailableTag '' -IgnoredTags @() -Diagnostics $diagnostics
    }

    if ($Snapshot.SchemaVersion -ne 1) {
        $diagnostics.Add("Unsupported snapshot schema '$($Snapshot.SchemaVersion)'.")
    }

    $currentRecord = ConvertTo-ProtocolVersionRecord ([string]$Snapshot.CurrentTag)
    if ($null -eq $currentRecord) {
        $diagnostics.Add("Current tag '$($Snapshot.CurrentTag)' is not canonical vM.m.rev.")
    }

    $records = [System.Collections.Generic.List[object]]::new()
    $seenTags = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($tagValue in @($Snapshot.AvailableTags)) {
        $tag = [string]$tagValue
        $record = ConvertTo-ProtocolVersionRecord $tag
        if ($null -eq $record) {
            $ignoredTags.Add($tag)
            continue
        }
        if (-not $seenTags.Add($tag)) {
            $diagnostics.Add("Release inventory contains duplicate tag '$tag'.")
            continue
        }
        $records.Add($record)
    }

    if ($records.Count -eq 0) {
        $diagnostics.Add('Release inventory contains no exact stable vM.m.rev tag.')
    }

    $latestAvailable = $null
    $latestCompatible = $null
    $majorUpgradeAvailable = $false
    if ($records.Count -gt 0) {
        $latestAvailable = @($records | Sort-Object Version | Select-Object -Last 1)[0]
    }
    if ($null -ne $currentRecord) {
        if (-not $seenTags.Contains($currentRecord.Tag)) {
            $diagnostics.Add("Current tag '$($currentRecord.Tag)' is absent from the release inventory.")
        }
        $compatible = @($records | Where-Object { $_.Version.Major -eq $currentRecord.Version.Major } | Sort-Object Version)
        if ($compatible.Count -eq 0) {
            $diagnostics.Add("No release exists for current major '$($currentRecord.Version.Major)'.")
        }
        else {
            $latestCompatible = $compatible[-1]
        }
        $majorUpgradeAvailable = @($records | Where-Object { $_.Version.Major -gt $currentRecord.Version.Major }).Count -gt 0
    }

    $candidateRecords = [System.Collections.Generic.List[object]]::new()
    $seenNumbers = [System.Collections.Generic.HashSet[int]]::new()
    $seenBranches = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $candidateContext = [pscustomobject]@{
        Repository = [string]$Snapshot.Repository
        DefaultBranch = [string]$Snapshot.DefaultBranch
        BranchPrefix = [string]$Snapshot.BranchPrefix
        ProtocolPath = [string]$Snapshot.ProtocolPath
        TrustedActor = [string]$Snapshot.TrustedActor
    }
    foreach ($candidate in @($Snapshot.Candidates)) {
        $requiredCandidateProperties = @(
            'PullRequestNumber', 'PullRequestState', 'TargetTag', 'HeadRef',
            'BranchExists', 'ExpectedHeadSha', 'ApiHeadSha', 'ObservedHeadSha', 'MarkerSchema', 'MarkerTargetTag',
            'MarkerProtocolSha', 'MarkerHeadSha', 'MarkerRepository',
            'ExpectedProtocolSha', 'ProtocolEntryMode', 'ProtocolEntrySha',
            'BaseRef', 'Draft', 'SameRepository', 'AuthorLogin', 'ChangedPaths'
        )
        $missing = @($requiredCandidateProperties | Where-Object { $_ -notin $candidate.PSObject.Properties.Name })
        if ($missing.Count -gt 0) {
            $diagnostics.Add("Candidate is missing: $($missing -join ', ').")
            continue
        }

        $number = [int]$candidate.PullRequestNumber
        $target = [string]$candidate.TargetTag
        $headRef = [string]$candidate.HeadRef
        $targetRecord = ConvertTo-ProtocolVersionRecord $target

        if (-not $seenNumbers.Add($number)) {
            $diagnostics.Add("Duplicate managed PR number '$number'.")
        }
        if (-not $seenBranches.Add($headRef)) {
            $diagnostics.Add("Duplicate managed branch '$headRef'.")
        }
        if ($null -eq $targetRecord -or -not $seenTags.Contains($target)) {
            $diagnostics.Add("Candidate PR #$number targets an unknown release '$target'.")
        }
        elseif ($null -ne $currentRecord -and $targetRecord.Version.Major -ne $currentRecord.Version.Major) {
            $diagnostics.Add("Candidate PR #$number targets a different major '$target'.")
        }
        foreach ($problem in @(Get-MeAndAIProtocolCandidateProblems `
            -Candidate $candidate -Context $candidateContext)) {
            $diagnostics.Add("Candidate PR #$number $problem.")
        }

        $candidateRecords.Add([pscustomobject]@{
            PullRequestNumber = $number
            TargetTag = $target
            HeadRef = $headRef
            ExpectedHeadSha = [string]$candidate.MarkerHeadSha
            ExpectedProtocolSha = [string]$candidate.ExpectedProtocolSha
        })
    }

    foreach ($group in @($candidateRecords | Group-Object TargetTag)) {
        if ($group.Count -gt 1) {
            $diagnostics.Add("Multiple managed PRs target '$($group.Name)'.")
        }
    }

    $latestCompatibleTag = if ($null -ne $latestCompatible) { $latestCompatible.Tag } else { '' }
    $latestAvailableTag = if ($null -ne $latestAvailable) { $latestAvailable.Tag } else { '' }
    if ($diagnostics.Count -gt 0) {
        return New-BlockedProtocolUpdatePlan -CurrentTag ([string]$Snapshot.CurrentTag) -LatestCompatibleTag $latestCompatibleTag -LatestAvailableTag $latestAvailableTag -IgnoredTags $ignoredTags -Diagnostics $diagnostics
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    $currentIsLatest = $currentRecord.Version -eq $latestCompatible.Version
    $latestCandidates = @($candidateRecords | Where-Object {
        [string]::Equals([string]$_.TargetTag, [string]$latestCompatible.Tag, [StringComparison]::Ordinal)
    })

    if ($currentIsLatest) {
        foreach ($candidate in @($candidateRecords | Sort-Object PullRequestNumber)) {
            $operations.Add([pscustomobject]@{
                Kind = 'ClosePullRequest'; TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
            })
            $operations.Add([pscustomobject]@{
                Kind = 'DeleteBranch'; TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                ExpectedHeadSha = $candidate.ExpectedHeadSha
            })
        }

        $state = if ($operations.Count -gt 0) {
            'CleanupStale'
        }
        elseif ($majorUpgradeAvailable) {
            'MajorUpgradeRequired'
        }
        else {
            'UpToDate'
        }
    }
    else {
        if ($latestCandidates.Count -eq 0) {
            $operations.Add([pscustomobject]@{
                Kind = 'CreateUpgrade'; TargetTag = $latestCompatible.Tag
                PullRequestNumber = $null; Branch = "$($Snapshot.BranchPrefix)$($latestCompatible.Tag)"
                ExpectedHeadSha = $null
            })
        }

        $olderCandidates = @($candidateRecords | Where-Object {
            -not [string]::Equals([string]$_.TargetTag, [string]$latestCompatible.Tag, [StringComparison]::Ordinal)
        } | Sort-Object PullRequestNumber)
        foreach ($candidate in $olderCandidates) {
            $operations.Add([pscustomobject]@{
                Kind = 'ClosePullRequest'; TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
            })
            $operations.Add([pscustomobject]@{
                Kind = 'DeleteBranch'; TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                ExpectedHeadSha = $candidate.ExpectedHeadSha
            })
        }

        $state = if ($olderCandidates.Count -gt 0) {
            'Supersede'
        }
        elseif ($latestCandidates.Count -gt 0) {
            'PendingLatest'
        }
        else {
            'OpenUpgrade'
        }
    }

    [pscustomobject]@{
        SchemaVersion = 1
        State = $state
        CurrentTag = $currentRecord.Tag
        LatestCompatibleTag = $latestCompatible.Tag
        LatestAvailableTag = $latestAvailable.Tag
        MajorUpgradeAvailable = $majorUpgradeAvailable
        IgnoredTags = @($ignoredTags)
        Diagnostics = @()
        Operations = @($operations)
    }
}

Export-ModuleMember -Function @(
    'Resolve-MeAndAIProtocolUpdatePlan', 'Get-MeAndAIProtocolCandidateProblems',
    'Test-MeAndAIProtocolTag'
)
