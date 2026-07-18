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

function Compare-ProtocolVersionRecord {
    param(
        [Parameter(Mandatory)]$Left,
        [Parameter(Mandatory)]$Right
    )

    foreach ($property in @('Major', 'Minor', 'Revision')) {
        if ($Left.$property -lt $Right.$property) { return -1 }
        if ($Left.$property -gt $Right.$property) { return 1 }
    }
    return 0
}

function Test-MeAndAIProtocolTag {
    [CmdletBinding()]
    param([string]$Tag)

    return $null -ne (ConvertTo-ProtocolVersionRecord $Tag)
}

function Get-MeAndAICompatibleProtocolTagsInOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Tags,
        [Parameter(Mandatory)][string]$CurrentTag
    )

    $current = ConvertTo-ProtocolVersionRecord $CurrentTag
    if ($null -eq $current) {
        throw "Current tag '$CurrentTag' is not canonical vM.m.rev."
    }

    $records = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($value in @($Tags)) {
        $tag = [string]$value
        $record = ConvertTo-ProtocolVersionRecord $tag
        if ($null -eq $record -or $record.Major -ne $current.Major) {
            continue
        }
        if (-not $seen.Add($tag)) {
            throw "Release inventory contains duplicate tag '$tag'."
        }
        $records.Add($record)
    }

    return @($records | Sort-Object Major, Minor, Revision | ForEach-Object {
        [string]$_.Tag
    })
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

    $kindProperty = $Candidate.PSObject.Properties['Kind']
    $candidateKind = if ($null -eq $kindProperty -or
        [string]::IsNullOrEmpty([string]$kindProperty.Value)) {
        'Update'
    }
    else { [string]$kindProperty.Value }
    $isMigration = $candidateKind -ceq 'MigrationReconciliation'

    $suffixProperty = $Context.PSObject.Properties['MigrationBranchSuffix']
    $migrationBranchSuffix = if ($null -eq $suffixProperty -or
        [string]::IsNullOrEmpty([string]$suffixProperty.Value)) {
        '-migrations'
    }
    else { [string]$suffixProperty.Value }
    $updateSuffixProperty = $Context.PSObject.Properties['UpdateBranchSuffix']
    $updateBranchSuffix = if ($null -eq $updateSuffixProperty) {
        ''
    }
    else { [string]$updateSuffixProperty.Value }
    $supersedeOnlyProperty = $Candidate.PSObject.Properties['SupersedeOnly']
    $supersedeOnly = $null -ne $supersedeOnlyProperty -and
        $supersedeOnlyProperty.Value -is [bool] -and
        [bool]$supersedeOnlyProperty.Value

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
    $expectedBranch = if ($isMigration) {
        "$($Context.BranchPrefix)$target$migrationBranchSuffix"
    }
    else {
        $effectiveUpdateSuffix = if ($supersedeOnly) { '' } else { $updateBranchSuffix }
        "$($Context.BranchPrefix)$target$effectiveUpdateSuffix"
    }
    if ([string]$Candidate.HeadRef -cne $expectedBranch) {
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
    $markerSchema = [int]$Candidate.MarkerSchema
    if ($markerSchema -notin @(1, 2) -or
        ($isMigration -and $markerSchema -ne 2) -or
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
    $allowedProperty = $Candidate.PSObject.Properties['AllowedExpectedPaths']
    $allowedPaths = @(if ($null -ne $allowedProperty) {
        $allowedProperty.Value | ForEach-Object { [string]$_ }
    }
    else { $managedPaths })
    $expectedChangedPaths = @($Candidate.ExpectedChangedPaths | ForEach-Object { [string]$_ })
    $expectedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $allowedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $expectedPathsValid = $true
    if ($allowedPaths.Count -eq 0 -or
        ($markerSchema -eq 2 -and $null -eq $allowedProperty)) {
        $expectedPathsValid = $false
    }
    foreach ($path in $allowedPaths) {
        if ([string]::IsNullOrEmpty($path) -or -not $allowedSet.Add($path)) {
            $expectedPathsValid = $false
        }
    }
    foreach ($path in $expectedChangedPaths) {
        if ([string]::IsNullOrEmpty($path) -or -not $expectedSet.Add($path) -or
            -not $allowedSet.Contains($path)) {
            $expectedPathsValid = $false
        }
    }
    if ($expectedSet.Count -eq 0 -or
        (-not $isMigration -and
            -not $expectedSet.Contains([string]$Context.ProtocolPath))) {
        $expectedPathsValid = $false
    }
    if (-not $expectedPathsValid) {
        $problems.Add('expected changed paths are outside the candidate path contract')
    }
    elseif (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual @($Candidate.ChangedPaths) -Expected $expectedChangedPaths)) {
        $problems.Add('changed paths do not match the expected managed update set')
    }
    if (-not [bool]$Candidate.ManagedAssetEntriesMatchTarget) {
        $problems.Add('managed updater assets do not match the target release')
    }
    if ($markerSchema -eq 2) {
        $planProperty = $Candidate.PSObject.Properties['MigrationPlanSha']
        $validProperty = $Candidate.PSObject.Properties['MigrationPlanValid']
        if ($null -eq $planProperty -or
            [string]$planProperty.Value -cnotmatch '^[0-9a-f]{64}$' -or
            $null -eq $validProperty -or
            $validProperty.Value -isnot [bool] -or
            -not [bool]$validProperty.Value) {
            $problems.Add('consumer migration plan is absent, invalid, or does not match its immutable evidence')
        }
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

    $migrationRequired = $false
    $migrationRequiredProperty = $Snapshot.PSObject.Properties['MigrationRequired']
    if ($null -ne $migrationRequiredProperty) {
        if ($migrationRequiredProperty.Value -isnot [bool]) {
            $diagnostics.Add('MigrationRequired must be Boolean when supplied.')
        }
        else { $migrationRequired = [bool]$migrationRequiredProperty.Value }
    }
    $migrationPlanProperty = $Snapshot.PSObject.Properties['CurrentMigrationPlanSha']
    $currentMigrationPlanSha = if ($null -eq $migrationPlanProperty) {
        ''
    }
    else { [string]$migrationPlanProperty.Value }
    if (($migrationRequired -and
            $currentMigrationPlanSha -cnotmatch '^[0-9a-f]{64}$') -or
        (-not [string]::IsNullOrEmpty($currentMigrationPlanSha) -and
            $currentMigrationPlanSha -cnotmatch '^[0-9a-f]{64}$')) {
        $diagnostics.Add('CurrentMigrationPlanSha must be one lowercase SHA-256 when migration reconciliation is required or supplied.')
    }
    $migrationSuffixProperty = $Snapshot.PSObject.Properties['MigrationBranchSuffix']
    $migrationBranchSuffix = if ($null -eq $migrationSuffixProperty -or
        [string]::IsNullOrEmpty([string]$migrationSuffixProperty.Value)) {
        '-migrations'
    }
    else { [string]$migrationSuffixProperty.Value }
    if ($migrationBranchSuffix -cnotmatch '^-[a-z0-9]+(?:-[a-z0-9]+)*$') {
        $diagnostics.Add('MigrationBranchSuffix must be one canonical lowercase hyphen-prefixed branch suffix.')
    }
    $updateSuffixProperty = $Snapshot.PSObject.Properties['UpdateBranchSuffix']
    $updateBranchSuffix = if ($null -eq $updateSuffixProperty) {
        ''
    }
    else { [string]$updateSuffixProperty.Value }
    if ($updateBranchSuffix -ne '' -and
        $updateBranchSuffix -cnotmatch '^-[a-z0-9]+(?:-[a-z0-9]+)*$') {
        $diagnostics.Add('UpdateBranchSuffix must be empty or one canonical lowercase hyphen-prefixed branch suffix.')
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

    $requestedTargetProperty = $Snapshot.PSObject.Properties['RequestedTargetTag']
    $requestedTargetTag = if ($null -ne $requestedTargetProperty) {
        [string]$requestedTargetProperty.Value
    }
    else { '' }
    $requestedTargetRecord = $null
    if ($null -ne $requestedTargetProperty) {
        $requestedTargetRecord = ConvertTo-ProtocolVersionRecord $requestedTargetTag
        if ($null -eq $requestedTargetRecord) {
            $diagnostics.Add("Requested target '$requestedTargetTag' is not canonical vM.m.rev.")
        }
        elseif (-not $seenTags.Contains($requestedTargetTag)) {
            $diagnostics.Add("Requested target '$requestedTargetTag' is absent from the release inventory.")
        }
        elseif ($null -ne $currentRecord -and
            $requestedTargetRecord.Major -ne $currentRecord.Major) {
            $diagnostics.Add("Requested target '$requestedTargetTag' crosses the current major version.")
        }
        elseif ($null -ne $currentRecord -and
            (Compare-ProtocolVersionRecord -Left $requestedTargetRecord `
                -Right $currentRecord) -lt 0) {
            $diagnostics.Add("Requested target '$requestedTargetTag' would downgrade the current release.")
        }
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
            $latestCompatible = if ($null -ne $requestedTargetRecord -and
                $requestedTargetRecord.Major -eq $currentRecord.Major -and
                $seenTags.Contains($requestedTargetTag)) {
                $requestedTargetRecord
            }
            else { $compatible[-1] }
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
        MigrationBranchSuffix = $migrationBranchSuffix
        UpdateBranchSuffix = $updateBranchSuffix
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
        $kindProperty = $candidate.PSObject.Properties['Kind']
        $proposalKind = if ($null -eq $kindProperty -or
            [string]::IsNullOrEmpty([string]$kindProperty.Value)) {
            'Update'
        }
        else { [string]$kindProperty.Value }
        if ($proposalKind -cnotin @('Update', 'MigrationReconciliation')) {
            $diagnostics.Add("Candidate PR #$number has unsupported proposal kind '$proposalKind'.")
            continue
        }
        $candidateMigrationPlanProperty = $candidate.PSObject.Properties['MigrationPlanSha']
        $candidateMigrationPlanSha = if ($null -eq $candidateMigrationPlanProperty) {
            ''
        }
        else { [string]$candidateMigrationPlanProperty.Value }
        $supersedeOnlyProperty = $candidate.PSObject.Properties['SupersedeOnly']
        $supersedeOnly = $false
        if ($null -ne $supersedeOnlyProperty) {
            if ($supersedeOnlyProperty.Value -isnot [bool]) {
                $diagnostics.Add("Candidate PR #$number SupersedeOnly must be Boolean when supplied.")
            }
            else { $supersedeOnly = [bool]$supersedeOnlyProperty.Value }
        }
        $unboundIssueProperty = $candidate.PSObject.Properties['UnboundIssue']
        $unboundIssue = $false
        if ($null -ne $unboundIssueProperty) {
            if ($unboundIssueProperty.Value -isnot [bool]) {
                $diagnostics.Add("Candidate PR #$number UnboundIssue must be Boolean when supplied.")
            }
            else { $unboundIssue = [bool]$unboundIssueProperty.Value }
        }

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
        elseif ($null -ne $requestedTargetRecord -and
            (Compare-ProtocolVersionRecord -Left $targetRecord `
                -Right $requestedTargetRecord) -gt 0) {
            $diagnostics.Add("Candidate PR #$number targets '$target', newer than requested target '$requestedTargetTag'.")
        }
        if ($supersedeOnly -and
            ($proposalKind -cne 'Update' -or [int]$candidate.MarkerSchema -ne 1)) {
            $diagnostics.Add("Candidate PR #$number has invalid SupersedeOnly proposal identity.")
        }
        if ($unboundIssue -and -not $supersedeOnly) {
            $diagnostics.Add("Candidate PR #$number cannot be UnboundIssue without SupersedeOnly.")
        }
        if ($proposalKind -ceq 'MigrationReconciliation' -and
            $migrationRequired -and
            $target -ceq [string]$Snapshot.CurrentTag -and
            $candidateMigrationPlanSha -cne $currentMigrationPlanSha) {
            $diagnostics.Add("Candidate PR #$number migration plan does not match the current required plan.")
        }
        foreach ($problem in @(Get-MeAndAIProtocolCandidateProblems `
            -Candidate $candidate -Context $candidateContext)) {
            $diagnostics.Add("Candidate PR #$number $problem.")
        }

        $candidateRecords.Add([pscustomobject]@{
            ProposalKind = $proposalKind
            PullRequestNumber = $number
            TargetTag = $target
            HeadRef = $headRef
            ExpectedHeadSha = [string]$candidate.MarkerHeadSha
            ExpectedProtocolSha = [string]$candidate.ExpectedProtocolSha
            MigrationPlanSha = $candidateMigrationPlanSha
            SupersedeOnly = $supersedeOnly
            UnboundIssue = $unboundIssue
        })
    }

    foreach ($group in @($candidateRecords | Where-Object {
        -not [bool]$_.SupersedeOnly
    } | Group-Object {
        "$($_.ProposalKind)`n$($_.TargetTag)"
    })) {
        if ($group.Count -gt 1) {
            $first = @($group.Group)[0]
            $diagnostics.Add("Multiple $($first.ProposalKind) PRs target '$($first.TargetTag)'.")
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
    $latestUpdateCandidates = @($candidateRecords | Where-Object {
        -not [bool]$_.SupersedeOnly -and $_.ProposalKind -ceq 'Update' -and
        [string]::Equals([string]$_.TargetTag, [string]$latestCompatible.Tag, [StringComparison]::Ordinal)
    })

    if ($currentIsLatest -and $migrationRequired) {
        $exactMigrationCandidates = @($candidateRecords | Where-Object {
            -not [bool]$_.SupersedeOnly -and
            $_.ProposalKind -ceq 'MigrationReconciliation' -and
            [string]::Equals([string]$_.TargetTag, [string]$latestCompatible.Tag, [StringComparison]::Ordinal) -and
            [string]::Equals([string]$_.MigrationPlanSha, $currentMigrationPlanSha, [StringComparison]::Ordinal)
        })
        if ($exactMigrationCandidates.Count -eq 0) {
            $operations.Add([pscustomobject]@{
                Kind = 'CreateMigration'
                ProposalKind = 'MigrationReconciliation'
                TargetTag = $latestCompatible.Tag
                PullRequestNumber = $null
                Branch = "$($Snapshot.BranchPrefix)$($latestCompatible.Tag)$migrationBranchSuffix"
                ExpectedHeadSha = $null
                MigrationPlanSha = $currentMigrationPlanSha
            })
        }

        $retainedMigrationNumber = if ($exactMigrationCandidates.Count -eq 1) {
            [int]$exactMigrationCandidates[0].PullRequestNumber
        }
        else { 0 }
        $staleCandidates = @($candidateRecords | Where-Object {
            $retainedMigrationNumber -eq 0 -or
            [int]$_.PullRequestNumber -ne $retainedMigrationNumber
        } | Sort-Object PullRequestNumber)
        foreach ($candidate in $staleCandidates) {
            $operations.Add([pscustomobject]@{
                Kind = 'ClosePullRequest'; ProposalKind = $candidate.ProposalKind
                TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                MigrationPlanSha = $candidate.MigrationPlanSha
                SupersedeOnly = [bool]$candidate.SupersedeOnly
                UnboundIssue = [bool]$candidate.UnboundIssue
            })
            $operations.Add([pscustomobject]@{
                Kind = 'DeleteBranch'; ProposalKind = $candidate.ProposalKind
                TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                MigrationPlanSha = $candidate.MigrationPlanSha
                SupersedeOnly = [bool]$candidate.SupersedeOnly
                UnboundIssue = [bool]$candidate.UnboundIssue
            })
        }

        $state = if ($staleCandidates.Count -gt 0) {
            'Supersede'
        }
        elseif ($exactMigrationCandidates.Count -eq 1) {
            'PendingMigration'
        }
        else { 'OpenMigration' }
    }
    elseif ($currentIsLatest) {
        foreach ($candidate in @($candidateRecords | Sort-Object PullRequestNumber)) {
            $operations.Add([pscustomobject]@{
                Kind = 'ClosePullRequest'; ProposalKind = $candidate.ProposalKind
                TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                MigrationPlanSha = $candidate.MigrationPlanSha
                SupersedeOnly = [bool]$candidate.SupersedeOnly
                UnboundIssue = [bool]$candidate.UnboundIssue
            })
            $operations.Add([pscustomobject]@{
                Kind = 'DeleteBranch'; ProposalKind = $candidate.ProposalKind
                TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                MigrationPlanSha = $candidate.MigrationPlanSha
                SupersedeOnly = [bool]$candidate.SupersedeOnly
                UnboundIssue = [bool]$candidate.UnboundIssue
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
        if ($latestUpdateCandidates.Count -eq 0) {
            $operations.Add([pscustomobject]@{
                Kind = 'CreateUpgrade'; ProposalKind = 'Update'
                TargetTag = $latestCompatible.Tag
                PullRequestNumber = $null
                Branch = "$($Snapshot.BranchPrefix)$($latestCompatible.Tag)$updateBranchSuffix"
                ExpectedHeadSha = $null; MigrationPlanSha = ''
            })
        }

        $supersededCandidates = @($candidateRecords | Where-Object {
            [bool]$_.SupersedeOnly -or
            -not ($_.ProposalKind -ceq 'Update' -and
                [string]::Equals([string]$_.TargetTag, [string]$latestCompatible.Tag, [StringComparison]::Ordinal))
        } | Sort-Object PullRequestNumber)
        foreach ($candidate in $supersededCandidates) {
            $operations.Add([pscustomobject]@{
                Kind = 'ClosePullRequest'; ProposalKind = $candidate.ProposalKind
                TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                MigrationPlanSha = $candidate.MigrationPlanSha
                SupersedeOnly = [bool]$candidate.SupersedeOnly
                UnboundIssue = [bool]$candidate.UnboundIssue
            })
            $operations.Add([pscustomobject]@{
                Kind = 'DeleteBranch'; ProposalKind = $candidate.ProposalKind
                TargetTag = $candidate.TargetTag
                PullRequestNumber = $candidate.PullRequestNumber; Branch = $candidate.HeadRef
                ExpectedProtocolSha = $candidate.ExpectedProtocolSha
                ExpectedHeadSha = $candidate.ExpectedHeadSha
                MigrationPlanSha = $candidate.MigrationPlanSha
                SupersedeOnly = [bool]$candidate.SupersedeOnly
                UnboundIssue = [bool]$candidate.UnboundIssue
            })
        }

        $state = if ($supersededCandidates.Count -gt 0) {
            'Supersede'
        }
        elseif ($latestUpdateCandidates.Count -gt 0) {
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
    'Test-MeAndAIProtocolTag', 'Test-MeAndAIExactOrdinalPathSet',
    'Get-MeAndAICompatibleProtocolTagsInOrder'
)
