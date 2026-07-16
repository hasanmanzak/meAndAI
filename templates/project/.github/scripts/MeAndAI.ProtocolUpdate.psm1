Set-StrictMode -Version Latest

function ConvertTo-ProtocolVersionRecord {
    param([string]$Tag)

    if ($Tag -cnotmatch '^v(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<revision>0|[1-9][0-9]*)$') {
        return $null
    }

    try {
        $major = [System.Numerics.BigInteger]::Parse(
            [string]$Matches.major,
            [Globalization.CultureInfo]::InvariantCulture
        )
        $minor = [System.Numerics.BigInteger]::Parse(
            [string]$Matches.minor,
            [Globalization.CultureInfo]::InvariantCulture
        )
        $revision = [System.Numerics.BigInteger]::Parse(
            [string]$Matches.revision,
            [Globalization.CultureInfo]::InvariantCulture
        )
    }
    catch {
        return $null
    }

    [pscustomobject]@{
        Tag = $Tag
        Major = $major
        Minor = $minor
        Revision = $revision
    }
}

function Test-MeAndAIProtocolTag {
    [CmdletBinding()]
    param([string]$Tag)

    return $null -ne (ConvertTo-ProtocolVersionRecord $Tag)
}

function Test-MeAndAIExactOrdinalPathSet {
    param([object[]]$Actual, [object[]]$Expected)

    $actualValues = @($Actual | ForEach-Object { [string]$_ })
    $expectedValues = @($Expected | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $expectedValues.Count) {
        return $false
    }

    $actualSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($path in $actualValues) {
        if (-not $actualSet.Add($path)) {
            return $false
        }
    }
    $expectedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($path in $expectedValues) {
        if (-not $expectedSet.Add($path)) {
            return $false
        }
    }
    return $actualSet.SetEquals($expectedSet)
}

function Get-MeAndAIProtocolCandidateProblems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Candidate,
        [Parameter(Mandatory)]$Context
    )

    $problems = [System.Collections.Generic.List[string]]::new()
    $target = [string]$Candidate.TargetTag

    $stateProperty = $Context.PSObject.Properties['ExpectedPullRequestState']
    $expectedState = if ($null -ne $stateProperty) {
        [string]$stateProperty.Value
    }
    else { 'Open' }
    $branchProperty = $Context.PSObject.Properties['ExpectedBranchExists']
    $expectedBranchExists = if ($null -ne $branchProperty) {
        [bool]$branchProperty.Value
    }
    else { $true }

    if ([string]$Candidate.PullRequestState -cne $expectedState) {
        $problems.Add("state is not $($expectedState.ToLowerInvariant())")
    }
    if ([string]$Candidate.HeadRef -cne "$($Context.BranchPrefix)$target") {
        $problems.Add('head branch is not the deterministic target branch')
    }
    if ([bool]$Candidate.BranchExists -ne $expectedBranchExists) {
        $branchProblem = if ($expectedBranchExists) {
            'remote branch is missing'
        } else { 'remote branch still exists' }
        $problems.Add($branchProblem)
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
    $headChanged = [string]$Candidate.ExpectedHeadSha -cnotmatch '^[0-9a-f]{40}$' -or
        [string]$Candidate.MarkerHeadSha -cne [string]$Candidate.ExpectedHeadSha -or
        [string]$Candidate.ApiHeadSha -cne [string]$Candidate.ExpectedHeadSha
    if ($expectedBranchExists) {
        $headChanged = $headChanged -or
            [string]$Candidate.ObservedHeadSha -cne [string]$Candidate.ExpectedHeadSha
    }
    else {
        $headChanged = $headChanged -or
            -not [string]::IsNullOrEmpty([string]$Candidate.ObservedHeadSha)
    }
    if ($headChanged) {
        $problems.Add('head SHA changed')
    }
    $managedPaths = @($Context.ManagedPaths | ForEach-Object { [string]$_ })
    $expectedChangedPaths = @($Candidate.ExpectedChangedPaths | ForEach-Object { [string]$_ })
    $expectedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $managedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $expectedPathsValid = $true
    foreach ($path in $managedPaths) {
        if (-not $managedSet.Add($path)) {
            $expectedPathsValid = $false
        }
    }
    foreach ($path in $expectedChangedPaths) {
        if (-not $expectedSet.Add($path) -or -not $managedSet.Contains($path)) {
            $expectedPathsValid = $false
        }
    }
    if (-not $expectedSet.Contains([string]$Context.ProtocolPath)) {
        $expectedPathsValid = $false
    }
    if (-not $expectedPathsValid) {
        $problems.Add('expected changed paths are outside the managed update contract')
    }
    elseif (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual @($Candidate.ChangedPaths) -Expected $expectedChangedPaths)) {
        $problems.Add('changed paths do not match the expected managed update set')
    }
    if (-not [bool]$Candidate.ManagedAssetEntriesMatchTarget) {
        $problems.Add('managed updater assets do not match the target release')
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
        'DefaultBranch', 'BranchPrefix', 'ProtocolPath', 'ManagedPaths',
        'TrustedActor', 'Candidates'
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
        $latestAvailable = @($records | Sort-Object Major, Minor, Revision | Select-Object -Last 1)[0]
    }
    if ($null -ne $currentRecord) {
        if (-not $seenTags.Contains($currentRecord.Tag)) {
            $diagnostics.Add("Current tag '$($currentRecord.Tag)' is absent from the release inventory.")
        }
        $compatible = @($records | Where-Object {
            $_.Major -eq $currentRecord.Major
        } | Sort-Object Major, Minor, Revision)
        if ($compatible.Count -eq 0) {
            $diagnostics.Add("No release exists for current major '$($currentRecord.Major)'.")
        }
        else {
            $latestCompatible = $compatible[-1]
        }
        $majorUpgradeAvailable = @($records | Where-Object {
            $_.Major -gt $currentRecord.Major
        }).Count -gt 0
    }

    $candidateRecords = [System.Collections.Generic.List[object]]::new()
    $seenNumbers = [System.Collections.Generic.HashSet[int]]::new()
    $seenBranches = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $candidateContext = [pscustomobject]@{
        Repository = [string]$Snapshot.Repository
        DefaultBranch = [string]$Snapshot.DefaultBranch
        BranchPrefix = [string]$Snapshot.BranchPrefix
        ProtocolPath = [string]$Snapshot.ProtocolPath
        ManagedPaths = @($Snapshot.ManagedPaths)
        TrustedActor = [string]$Snapshot.TrustedActor
    }
    foreach ($candidate in @($Snapshot.Candidates)) {
        $requiredCandidateProperties = @(
            'PullRequestNumber', 'PullRequestState', 'TargetTag', 'HeadRef',
            'BranchExists', 'ExpectedHeadSha', 'ApiHeadSha', 'ObservedHeadSha', 'MarkerSchema', 'MarkerTargetTag',
            'MarkerProtocolSha', 'MarkerHeadSha', 'MarkerRepository',
            'ExpectedProtocolSha', 'ProtocolEntryMode', 'ProtocolEntrySha',
            'BaseRef', 'Draft', 'SameRepository', 'AuthorLogin', 'ChangedPaths',
            'ExpectedChangedPaths', 'ManagedAssetEntriesMatchTarget'
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
        elseif ($null -ne $currentRecord -and $targetRecord.Major -ne $currentRecord.Major) {
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
    $currentIsLatest = $currentRecord.Major -eq $latestCompatible.Major -and
        $currentRecord.Minor -eq $latestCompatible.Minor -and
        $currentRecord.Revision -eq $latestCompatible.Revision
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
    'Test-MeAndAIProtocolTag', 'Test-MeAndAIExactOrdinalPathSet'
)
