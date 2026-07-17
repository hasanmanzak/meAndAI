[CmdletBinding()]
param(
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolPath = '.ai/protocol',
    [string]$ProtocolSourcePath = '.meandai-update-source',
    [string]$BranchPrefix = 'automation/meandai-protocol-',
    [switch]$FinalizeMergedPullRequest,
    [int]$PullRequestNumber = 0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ManagedUpdaterAssets = @(
    [pscustomobject]@{
        ConsumerPath = '.github/workflows/meandai-protocol-update.yml'
        TemplatePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
        TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    }
)
$ManagedPaths = @($ProtocolPath) + @($ManagedUpdaterAssets | ForEach-Object {
    [string]$_.ConsumerPath
})

function Invoke-Native {
    param([string]$Command, [string[]]$Arguments)

    $output = @(& $Command @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    $output
}

function Invoke-GhJson {
    param(
        [string[]]$Arguments,
        [AllowNull()][string]$Token = $null
    )

    $previousToken = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')
    try {
        if ($PSBoundParameters.ContainsKey('Token')) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $Token, 'Process')
        }
        $text = (Invoke-Native -Command 'gh' -Arguments $Arguments) -join [Environment]::NewLine
    }
    finally {
        if ($PSBoundParameters.ContainsKey('Token')) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $previousToken, 'Process')
        }
    }
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

function Get-ImmutableProtocolReleaseEvidence {
    param(
        [string]$Repository,
        [string]$Tag,
        [string]$ProtocolToken
    )

    if (-not (Test-MeAndAIProtocolTag -Tag $Tag)) {
        throw "Selected protocol target '$Tag' is not a canonical release tag."
    }
    $release = Invoke-GhJson -Token $ProtocolToken -Arguments @(
        'api',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10',
        "repos/$Repository/releases/tags/$Tag"
    )
    foreach ($name in @('tag_name', 'draft', 'prerelease', 'immutable', 'published_at')) {
        if ($null -eq $release -or $null -eq $release.PSObject.Properties[$name]) {
            throw "Protocol release '$Tag' is missing required immutable-release metadata '$name'."
        }
    }
    $publishedAt = [DateTimeOffset]::MinValue
    if ([string]$release.tag_name -cne $Tag -or
        $release.draft -isnot [bool] -or [bool]$release.draft -or
        $release.prerelease -isnot [bool] -or [bool]$release.prerelease -or
        $release.immutable -isnot [bool] -or -not [bool]$release.immutable -or
        -not [DateTimeOffset]::TryParse(
            [string]$release.published_at, [ref]$publishedAt
        )) {
        throw "Protocol target '$Tag' is not an exact published, non-prerelease, immutable GitHub Release."
    }

    $reference = Invoke-GhJson -Token $ProtocolToken -Arguments @(
        'api',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10',
        "repos/$Repository/git/ref/tags/$Tag"
    )
    if ($null -eq $reference -or $null -eq $reference.PSObject.Properties['object'] -or
        $null -eq $reference.object -or
        $null -eq $reference.object.PSObject.Properties['type'] -or
        $null -eq $reference.object.PSObject.Properties['sha']) {
        throw "Protocol release '$Tag' is missing exact tag-reference evidence."
    }
    $objectType = [string]$reference.object.type
    $objectSha = [string]$reference.object.sha
    if ($objectSha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Protocol release '$Tag' has an invalid tag object identity."
    }
    if ($objectType -ceq 'tag') {
        $annotatedTag = Invoke-GhJson -Token $ProtocolToken -Arguments @(
            'api',
            '-H', 'Accept: application/vnd.github+json',
            '-H', 'X-GitHub-Api-Version: 2026-03-10',
            "repos/$Repository/git/tags/$objectSha"
        )
        if ($null -eq $annotatedTag -or
            $null -eq $annotatedTag.PSObject.Properties['object'] -or
            $null -eq $annotatedTag.object -or
            [string]$annotatedTag.object.type -cne 'commit' -or
            [string]$annotatedTag.object.sha -cnotmatch '^[0-9a-f]{40}$') {
            throw "Protocol release '$Tag' annotated tag does not resolve directly to one commit."
        }
        $objectSha = [string]$annotatedTag.object.sha
    }
    elseif ($objectType -cne 'commit') {
        throw "Protocol release '$Tag' tag reference does not resolve to a commit."
    }

    return [pscustomobject]@{
        Tag = $Tag
        CommitSha = $objectSha
    }
}

function Get-ValidatedPullRequestChangedPaths {
    param([object[]]$Files)

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $Files) {
        $filenameProperty = if ($null -ne $file) {
            $file.PSObject.Properties['filename']
        }
        else { $null }
        $statusProperty = if ($null -ne $file) {
            $file.PSObject.Properties['status']
        }
        else { $null }
        $previousProperty = if ($null -ne $file) {
            $file.PSObject.Properties['previous_filename']
        }
        else { $null }
        $filename = if ($null -ne $filenameProperty) {
            [string]$filenameProperty.Value
        }
        else { '' }
        $status = if ($null -ne $statusProperty) {
            [string]$statusProperty.Value
        }
        else { '' }
        $previousFilename = if ($null -ne $previousProperty) {
            [string]$previousProperty.Value
        }
        else { '' }
        if ($status -ceq 'renamed' -or
            -not [string]::IsNullOrWhiteSpace($previousFilename)) {
            throw 'Pull-request rename metadata is outside the managed update contract.'
        }
        if ([string]::IsNullOrWhiteSpace($filename) -or
            $status -cnotin @('added', 'modified', 'removed')) {
            throw 'Pull-request file metadata is outside the managed update contract.'
        }
        $paths.Add($filename)
    }
    return @($paths)
}

function Get-AuthenticatedUpdaterActor {
    $user = Invoke-GhJson -Arguments @('api', 'user')
    $loginProperty = if ($null -ne $user) { $user.PSObject.Properties['login'] } else { $null }
    $login = if ($null -ne $loginProperty) { [string]$loginProperty.Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($login)) {
        throw 'Unable to resolve the authenticated updater actor from MEANDAI_UPDATER_TOKEN.'
    }
    return $login
}

function Get-LocalTreeEntry {
    param(
        [string]$Commit,
        [string]$Path,
        [string]$RepositoryPath = ''
    )

    $arguments = if ($RepositoryPath) {
        @('-C', $RepositoryPath, 'ls-tree', $Commit, '--', $Path)
    }
    else {
        @('ls-tree', $Commit, '--', $Path)
    }
    $output = @(Invoke-Native -Command 'git' -Arguments $arguments)
    $empty = [pscustomobject]@{ Mode = ''; Type = ''; Sha = ''; Path = '' }
    if ($output.Count -ne 1) {
        return $empty
    }
    $match = [regex]::Match(
        [string]$output[0],
        '^(?<mode>[0-9]{6})\s+(?<type>[^\s]+)\s+(?<sha>[0-9a-f]{40})\t(?<path>.+)$'
    )
    if (-not $match.Success -or
        [string]$match.Groups['path'].Value -cne $Path) {
        return $empty
    }
    return [pscustomobject]@{
        Mode = [string]$match.Groups['mode'].Value
        Type = [string]$match.Groups['type'].Value
        Sha = [string]$match.Groups['sha'].Value
        Path = [string]$match.Groups['path'].Value
    }
}

function Get-StagedTreeEntry {
    param([string]$Path)

    $output = @(Invoke-Native -Command 'git' -Arguments @(
        'ls-files', '--stage', '--', $Path
    ))
    $empty = [pscustomobject]@{ Mode = ''; Sha = ''; Path = '' }
    if ($output.Count -ne 1) {
        return $empty
    }
    $match = [regex]::Match(
        [string]$output[0],
        '^(?<mode>[0-9]{6})\s+(?<sha>[0-9a-f]{40})\s+0\t(?<path>.+)$'
    )
    if (-not $match.Success -or
        [string]$match.Groups['path'].Value -cne $Path) {
        return $empty
    }
    return [pscustomobject]@{
        Mode = [string]$match.Groups['mode'].Value
        Sha = [string]$match.Groups['sha'].Value
        Path = [string]$match.Groups['path'].Value
    }
}

function Assert-CurrentManagedAssets {
    param(
        [string]$BaseCommit,
        [string]$CurrentProtocolSha,
        [string]$SourcePath,
        [object[]]$Assets
    )

    foreach ($asset in $Assets) {
        $consumerEntry = Get-LocalTreeEntry -Commit $BaseCommit `
            -Path ([string]$asset.ConsumerPath)
        $templateEntry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
            -Commit $CurrentProtocolSha -Path ([string]$asset.TemplatePath)
        $consumerValid = $consumerEntry.Mode -ceq '100644' -and
            $consumerEntry.Type -ceq 'blob' -and
            $consumerEntry.Sha -match '^[0-9a-f]{40}$'
        $templateValid = $templateEntry.Mode -ceq '100644' -and
            $templateEntry.Type -ceq 'blob' -and
            $templateEntry.Sha -match '^[0-9a-f]{40}$'
        if (-not $consumerValid -or -not $templateValid -or
            $consumerEntry.Sha -cne $templateEntry.Sha) {
            throw "Managed asset '$($asset.ConsumerPath)' does not match the current pinned updater template; manual review is required."
        }
    }
}

function Get-ExpectedManagedPaths {
    param(
        [string]$BaseCommit,
        [string]$TargetProtocolSha,
        [string]$SourcePath,
        [string]$ProtocolPath,
        [object[]]$Assets
    )

    $paths = [System.Collections.Generic.List[string]]::new()
    $paths.Add($ProtocolPath)
    foreach ($asset in $Assets) {
        $consumerEntry = Get-LocalTreeEntry -Commit $BaseCommit `
            -Path ([string]$asset.ConsumerPath)
        $targetEntry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
            -Commit $TargetProtocolSha -Path ([string]$asset.TemplatePath)
        if ($consumerEntry.Mode -cne '100644' -or
            $consumerEntry.Type -cne 'blob' -or
            $consumerEntry.Sha -notmatch '^[0-9a-f]{40}$') {
            throw "Managed consumer asset '$($asset.ConsumerPath)' is missing or invalid."
        }
        if ($targetEntry.Mode -cne '100644' -or
            $targetEntry.Type -cne 'blob' -or
            $targetEntry.Sha -notmatch '^[0-9a-f]{40}$') {
            throw "Target release is missing canonical updater template '$($asset.TemplatePath)'."
        }
        if ($consumerEntry.Mode -cne $targetEntry.Mode -or
            $consumerEntry.Sha -cne $targetEntry.Sha) {
            $paths.Add([string]$asset.ConsumerPath)
        }
    }
    return @($paths)
}

function Assert-StagedManagedUpdate {
    param(
        [string[]]$ExpectedPaths,
        [string]$TargetProtocolSha,
        [string]$SourcePath,
        [string]$ProtocolPath,
        [object[]]$Assets
    )

    $stagedPaths = @(Invoke-Native -Command 'git' -Arguments @(
        'diff', '--cached', '--name-only'
    ))
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $stagedPaths -Expected $ExpectedPaths)) {
        throw "Upgrade staging does not match the expected managed paths: $($stagedPaths -join ', ')."
    }

    $protocolEntry = Get-StagedTreeEntry -Path $ProtocolPath
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Sha -cne $TargetProtocolSha) {
        throw "Staged protocol gitlink does not match target commit '$TargetProtocolSha'."
    }
    foreach ($asset in $Assets) {
        if ([string]$asset.ConsumerPath -cnotin $ExpectedPaths) {
            continue
        }
        $targetEntry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
            -Commit $TargetProtocolSha -Path ([string]$asset.TemplatePath)
        $stagedEntry = Get-StagedTreeEntry -Path ([string]$asset.ConsumerPath)
        if ($targetEntry.Mode -cne '100644' -or
            $targetEntry.Type -cne 'blob' -or
            $stagedEntry.Mode -cne $targetEntry.Mode -or
            $stagedEntry.Sha -cne $targetEntry.Sha) {
            throw "Staged updater asset '$($asset.ConsumerPath)' does not match the target release blob."
        }
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

function Get-RemoteBranchesByPrefix {
    param([Parameter(Mandatory)][string]$Prefix)

    $refPrefix = "refs/heads/$Prefix"
    $output = @(Invoke-Native -Command 'git' -Arguments @(
        'ls-remote', '--heads', 'origin', "$refPrefix*"
    ))
    $branches = [System.Collections.Generic.List[object]]::new()
    $names = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($line in $output) {
        $match = [regex]::Match(
            [string]$line,
            '^(?<sha>[0-9a-f]{40})\s+(?<ref>refs/heads/.+)$'
        )
        if (-not $match.Success -or
            -not $match.Groups['ref'].Value.StartsWith(
                $refPrefix, [StringComparison]::Ordinal
            )) {
            throw 'The reserved updater branch inventory is invalid.'
        }
        $name = $match.Groups['ref'].Value.Substring('refs/heads/'.Length)
        if (-not $names.Add($name)) {
            throw "Reserved updater branch '$name' is ambiguous."
        }
        $branches.Add([pscustomobject]@{
            Name = $name
            Sha = [string]$match.Groups['sha'].Value
        })
    }
    return @($branches)
}

function Test-ExactRemoteBranchInventory {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Expected,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Actual
    )

    $expectedRows = @($Expected | ForEach-Object {
        "$([string]$_.Name)`t$([string]$_.Sha)"
    } | Sort-Object)
    $actualRows = @($Actual | ForEach-Object {
        "$([string]$_.Name)`t$([string]$_.Sha)"
    } | Sort-Object)
    if ($expectedRows.Count -ne $actualRows.Count) {
        return $false
    }
    for ($index = 0; $index -lt $expectedRows.Count; $index++) {
        if ($expectedRows[$index] -cne $actualRows[$index]) {
            return $false
        }
    }
    return $true
}

function Get-RepositoryTreeEntry {
    param([string]$Repository, [string]$HeadSha, [string]$Path)

    $empty = [pscustomobject]@{ Mode = ''; Type = ''; Sha = '' }
    $segments = @($Path.Split('/', [StringSplitOptions]::RemoveEmptyEntries))
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
            return [pscustomobject]@{
                Mode = [string]$entry.mode
                Type = [string]$entry.type
                Sha = [string]$entry.sha
            }
        }
        if ([string]$entry.type -ne 'tree' -or [string]$entry.mode -ne '040000' -or
            [string]$entry.sha -notmatch '^[0-9a-f]{40}$') {
            return $empty
        }
        $treeSha = [string]$entry.sha
    }

    return $empty
}

function Test-ManagedAssetEntriesMatchTarget {
    param(
        [string]$Repository,
        [string]$HeadSha,
        [string[]]$ExpectedPaths,
        [string]$TargetProtocolSha,
        [string]$SourcePath,
        [object[]]$Assets
    )

    foreach ($asset in $Assets) {
        if ([string]$asset.ConsumerPath -cnotin $ExpectedPaths) {
            continue
        }
        $expected = Get-LocalTreeEntry -RepositoryPath $SourcePath `
            -Commit $TargetProtocolSha -Path ([string]$asset.TemplatePath)
        $observed = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha $HeadSha -Path ([string]$asset.ConsumerPath)
        if ($expected.Mode -cne '100644' -or
            $expected.Type -cne 'blob' -or
            $observed.Mode -cne $expected.Mode -or
            $observed.Type -cne $expected.Type -or
            $observed.Sha -cne $expected.Sha) {
            return $false
        }
    }
    return $true
}

function Assert-ManagedPullRequestSafe {
    param(
        [string]$Repository,
        $Operation,
        [string]$ProtocolPath,
        [string]$TrustedActor,
        [string]$SourcePath,
        [string]$BaseCommit,
        [object[]]$ManagedAssets,
        [string[]]$ManagedPaths,
        [ValidateSet('Open', 'Closed')]
        [string]$ExpectedPullRequestState = 'Open',
        [bool]$ExpectedBranchExists = $true
    )

    $number = [int]$Operation.PullRequestNumber
    $details = Invoke-GhJson -Arguments @('api', "repos/$Repository/pulls/$number")
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/pulls/$number/files?per_page=100")
    $marker = Get-ProtocolMarker ([string]$details.body)
    $protocolEntry = Get-RepositoryTreeEntry -Repository $Repository `
        -HeadSha ([string]$details.head.sha) -Path $ProtocolPath
    $remoteHead = Get-RemoteBranchHead -Branch ([string]$Operation.Branch)
    $changedPaths = @(Get-ValidatedPullRequestChangedPaths -Files $files)
    $expectedChangedPaths = @(Get-ExpectedManagedPaths -BaseCommit $BaseCommit `
        -TargetProtocolSha ([string]$Operation.ExpectedProtocolSha) `
        -SourcePath $SourcePath -ProtocolPath $ProtocolPath -Assets $ManagedAssets)
    $managedAssetsMatch = Test-ManagedAssetEntriesMatchTarget `
        -Repository $Repository -HeadSha ([string]$details.head.sha) `
        -ExpectedPaths $expectedChangedPaths `
        -TargetProtocolSha ([string]$Operation.ExpectedProtocolSha) `
        -SourcePath $SourcePath -Assets $ManagedAssets
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
        ExpectedChangedPaths = $expectedChangedPaths
        ManagedAssetEntriesMatchTarget = $managedAssetsMatch
    }
    $context = [pscustomobject]@{
        Repository = $Repository; DefaultBranch = [string]$env:DEFAULT_BRANCH
        BranchPrefix = [string]$script:BranchPrefix
        ProtocolPath = $ProtocolPath; ManagedPaths = $ManagedPaths
        TrustedActor = $TrustedActor
        ExpectedPullRequestState = $ExpectedPullRequestState
        ExpectedBranchExists = $ExpectedBranchExists
    }
    $problems = @(Get-MeAndAIProtocolCandidateProblems -Candidate $candidate -Context $context)

    if ($problems.Count -gt 0) {
        throw "Managed PR #$number changed after planning: $($problems -join '; ')."
    }
}

function Get-CanonicalAdoptionMarker {
    param([string]$Body)

    $empty = [pscustomobject]@{
        Schema = 0; Phase = ''; State = ''; Target = ''; ProtocolSha = ''
        Head = ''; Repository = ''; Actor = ''; CanonicalLine = ''
    }
    if ([string]::IsNullOrWhiteSpace($Body)) {
        return $empty
    }
    $markerPrefix = '<!-- meandai-capabilities-adoption:'
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
    $matches = [regex]::Matches(
        $Body,
        '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]+\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($matches.Count -ne 1) {
        return $empty
    }
    try {
        $json = [string]$matches[0].Groups['json'].Value
        $marker = $json | ConvertFrom-Json
        $expectedNames = @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'repository', 'actor'
        )
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
            [long]$marker.schema -ne 3 -or
            $marker.phase -isnot [string] -or
            [string]$marker.phase -cne 'Completed' -or
            $marker.state -isnot [string] -or
            [string]::IsNullOrWhiteSpace([string]$marker.state) -or
            $marker.target -isnot [string] -or
            $marker.protocolSha -isnot [string] -or
            $marker.head -isnot [string] -or
            $marker.repository -isnot [string] -or
            $marker.actor -isnot [string] -or
            [string]::IsNullOrWhiteSpace([string]$marker.actor)) {
            return $empty
        }
        $canonicalJson = [ordered]@{
            schema = 3
            phase = 'Completed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = [string]$marker.head
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        } | ConvertTo-Json -Compress
        if ($json -cne $canonicalJson) {
            return $empty
        }
        return [pscustomobject]@{
            Schema = 3
            Phase = 'Completed'
            State = [string]$marker.state
            Target = [string]$marker.target
            ProtocolSha = [string]$marker.protocolSha
            Head = [string]$marker.head
            Repository = [string]$marker.repository
            Actor = [string]$marker.actor
            CanonicalLine = "<!-- meandai-capabilities-adoption:$canonicalJson -->"
        }
    }
    catch {
        return $empty
    }
}

function Get-CanonicalTrackingIssueNumber {
    param([string]$Body)

    $normalized = ([string]$Body).Replace("`r`n", "`n").Replace("`r", "`n")
    $candidateLines = [regex]::Matches(
        $normalized,
        '(?im)^tracking[ \t]+issue[ \t]*:.*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $matches = [regex]::Matches(
        $normalized,
        '(?m)^Tracking issue: #(?<number>[1-9][0-9]*)$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($candidateLines.Count -ne 1 -or $matches.Count -ne 1 -or
        [string]$candidateLines[0].Value -cne [string]$matches[0].Value) {
        throw 'Managed pull request must contain exactly one canonical Tracking issue: #N line.'
    }
    if ([regex]::IsMatch(
        $normalized,
        '(?im)(?:^|\s)(close[sd]?|fix(e[sd])?|resolve[sd]?)\s+(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#\d+\b',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )) {
        throw 'Managed pull request must not use a native issue-closing keyword before post-merge finalization.'
    }
    $number = 0
    if (-not [int]::TryParse(
        [string]$matches[0].Groups['number'].Value, [ref]$number
    ) -or $number -lt 1) {
        throw 'Managed pull request tracking issue number is outside the supported range.'
    }
    return $number
}

function Get-FinalizationIssueEvidence {
    param(
        [object[]]$Comments,
        [string]$ExpectedMarker
    )

    $managed = @($Comments | Where-Object {
        $bodyProperty = if ($null -ne $_) { $_.PSObject.Properties['body'] } else { $null }
        $null -ne $bodyProperty -and
            ([string]$bodyProperty.Value).StartsWith(
                '<!-- meandai-managed-merge-finalization:',
                [StringComparison]::Ordinal
            )
    })
    $exact = @($managed | Where-Object {
        ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -ceq $ExpectedMarker
    })
    if ($managed.Count -ne $exact.Count -or $exact.Count -gt 1) {
        throw 'Tracking issue has ambiguous managed merge finalization evidence.'
    }
    return [pscustomobject]@{ Exists = $exact.Count -eq 1 }
}

function Get-ManagedMergedPullRequestState {
    param(
        [string]$Repository,
        [string]$DefaultBranch,
        [int]$Number
    )

    $pull = Invoke-GhJson -Arguments @('api', "repos/$Repository/pulls/$Number")
    if ($null -eq $pull -or [int]$pull.number -ne $Number) {
        throw "Pull request #$Number could not be resolved exactly."
    }
    $body = [string]$pull.body
    $headRef = [string]$pull.head.ref
    $adoptionPrefix = 'automation/meandai-capabilities-'
    $hasReservedBranch = $headRef.StartsWith(
        $adoptionPrefix, [StringComparison]::Ordinal
    ) -or $headRef.StartsWith($BranchPrefix, [StringComparison]::Ordinal)
    $hasMarkerSignal = $body.IndexOf(
        '<!-- meandai-capabilities-adoption:',
        [StringComparison]::OrdinalIgnoreCase
    ) -ge 0 -or $body.IndexOf(
        '<!-- meandai-protocol-update:',
        [StringComparison]::OrdinalIgnoreCase
    ) -ge 0
    if (-not $hasReservedBranch -and -not $hasMarkerSignal) {
        return [pscustomobject]@{ Managed = $false; PullRequest = $pull }
    }

    $normalizedBody = $body.Replace("`r`n", "`n").Replace("`r", "`n")
    $firstLine = $normalizedBody.Split("`n")[0]
    $adoptionMarker = Get-CanonicalAdoptionMarker -Body $body
    $updateMarker = Get-ProtocolMarker -Body $body
    $kind = ''
    $marker = $null
    $canonicalLine = ''
    if ($adoptionMarker.Schema -eq 3) {
        $kind = 'Adoption'
        $marker = $adoptionMarker
        $canonicalLine = [string]$adoptionMarker.CanonicalLine
    }
    elseif ($updateMarker.Schema -eq 1) {
        $kind = 'Update'
        $marker = $updateMarker
        $canonicalJson = [ordered]@{
            schema = 1
            target = [string]$updateMarker.Target
            protocolSha = [string]$updateMarker.ProtocolSha
            head = [string]$updateMarker.Head
            repository = [string]$updateMarker.Repository
        } | ConvertTo-Json -Compress
        $canonicalLine = "<!-- meandai-protocol-update:$canonicalJson -->"
    }
    else {
        throw "Managed-looking pull request #$Number has no single canonical ownership marker."
    }
    if ($firstLine -cne $canonicalLine) {
        throw "Managed pull request #$Number ownership marker is not its exact first line."
    }

    $expectedPrefix = if ($kind -ceq 'Adoption') {
        $adoptionPrefix
    }
    else { $BranchPrefix }
    $target = [string]$marker.Target
    if ($target -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or
        $headRef -cne "$expectedPrefix$target" -or
        [string]$marker.Repository -cne $Repository -or
        [string]$marker.ProtocolSha -cnotmatch '^[0-9a-f]{40}$' -or
        [string]$marker.Head -cnotmatch '^[0-9a-f]{40}$') {
        throw "Managed pull request #$Number marker, target, or deterministic branch is invalid."
    }
    if ([string]$pull.state -cne 'closed' -or
        $pull.merged -isnot [bool] -or -not [bool]$pull.merged -or
        [string]::IsNullOrWhiteSpace([string]$pull.merged_at) -or
        [string]$pull.base.ref -cne $DefaultBranch -or
        $null -eq $pull.head.repo -or
        [string]$pull.head.repo.full_name -cne $Repository -or
        [string]$pull.head.sha -cne [string]$marker.Head -or
        [string]$pull.merge_commit_sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Managed pull request #$Number is not an exact same-repository merge into the current default branch."
    }
    if ($kind -ceq 'Adoption' -and
        [string]$pull.user.login -cne [string]$marker.Actor) {
        throw "Managed adoption pull request #$Number author does not match its canonical actor."
    }

    $trackingIssueNumber = Get-CanonicalTrackingIssueNumber -Body $body
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/pulls/$Number/files?per_page=100")
    $changedPaths = @(Get-ValidatedPullRequestChangedPaths -Files $files)
    if ($changedPaths.Count -eq 0 -or $changedPaths -cnotcontains $ProtocolPath) {
        throw "Managed pull request #$Number does not contain the protocol dependency path."
    }
    if ($kind -ceq 'Update') {
        foreach ($path in $changedPaths) {
            if ($path -cnotin $ManagedPaths) {
                throw "Managed update pull request #$Number changed unexpected path '$path'."
            }
        }
    }
    else {
        foreach ($forbiddenPath in @(
            '.ai/adoption/meandai-capabilities.json', 'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt'
        )) {
            if ($changedPaths -ccontains $forbiddenPath) {
                throw "Managed adoption pull request #$Number contains forbidden transient path '$forbiddenPath'."
            }
        }
    }

    $repositoryRecord = Invoke-GhJson -Arguments @('api', "repos/$Repository")
    if ([string]$repositoryRecord.full_name -cne $Repository -or
        [string]$repositoryRecord.default_branch -cne $DefaultBranch) {
        throw 'Consumer default branch changed; explicit maintainer review is required.'
    }
    $defaultRef = Invoke-GhJson -Arguments @(
        'api', "repos/$Repository/git/ref/heads/$DefaultBranch"
    )
    $defaultHead = [string]$defaultRef.object.sha
    if ([string]$defaultRef.ref -cne "refs/heads/$DefaultBranch" -or
        [string]$defaultRef.object.type -cne 'commit' -or
        $defaultHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Consumer default branch head could not be resolved exactly.'
    }
    $comparison = Invoke-GhJson -Arguments @(
        'api', "repos/$Repository/compare/$([string]$pull.merge_commit_sha)...$defaultHead"
    )
    if ([string]$comparison.status -cnotin @('identical', 'ahead')) {
        throw "Managed pull request #$Number merge is no longer contained in the current default branch."
    }

    $issue = $null
    if ($kind -ceq 'Adoption') {
        $issueMarker = "<!-- meandai-local-adoption:$target`:pr-$Number -->"
        $issueTitle = "Track meAndAI AI capabilities adoption from $target"
        $matches = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/issues?state=all&per_page=100" |
            Where-Object {
                $null -eq $_.PSObject.Properties['pull_request'] -and
                [int]$_.number -eq $trackingIssueNumber -and
                [string]$_.title -ceq $issueTitle -and
                ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -ceq $issueMarker
            })
        if ($matches.Count -ne 1) {
            throw "Managed adoption pull request #$Number has no single canonical tracking issue."
        }
        $issue = $matches[0]
    }
    else {
        $issue = Invoke-GhJson -Arguments @(
            'api', "repos/$Repository/issues/$trackingIssueNumber"
        )
        if ($null -eq $issue -or [int]$issue.number -ne $trackingIssueNumber -or
            $null -ne $issue.PSObject.Properties['pull_request']) {
            throw "Managed update pull request #$Number tracking reference is not one same-repository issue."
        }
    }

    $comments = @(Invoke-GhPagedJson -Endpoint (
        "repos/$Repository/issues/$trackingIssueNumber/comments?per_page=100"
    ))
    $evidenceMarker = "<!-- meandai-managed-merge-finalization:pr-$Number`:head-$([string]$marker.Head) -->"
    $evidence = Get-FinalizationIssueEvidence -Comments $comments `
        -ExpectedMarker $evidenceMarker
    $branchHead = Get-RemoteBranchHead -Branch $headRef
    if ([string]$issue.state -cnotin @('open', 'closed')) {
        throw "Managed tracking issue #$trackingIssueNumber has an invalid state."
    }
    if ([string]$issue.state -ceq 'closed' -and -not $evidence.Exists) {
        throw "Managed tracking issue #$trackingIssueNumber closed without exact finalization evidence."
    }
    if ($evidence.Exists -and $null -ne $branchHead) {
        throw "Managed branch '$headRef' exists after issue finalization evidence was recorded."
    }

    $owner = $Repository.Split('/')[0]
    $openReuse = @(Invoke-GhPagedJson -Endpoint (
        "repos/$Repository/pulls?state=open&head=$owner`:$headRef&per_page=100"
    ))
    if ($openReuse.Count -ne 0) {
        throw "Managed branch '$headRef' is reused by an open pull request."
    }

    return [pscustomobject]@{
        Managed = $true
        Kind = $kind
        PullRequest = $pull
        Branch = $headRef
        Head = [string]$marker.Head
        BranchHead = $branchHead
        Issue = $issue
        IssueNumber = $trackingIssueNumber
        EvidenceMarker = $evidenceMarker
        EvidenceExists = [bool]$evidence.Exists
    }
}

function Invoke-ManagedMergedPullRequestFinalization {
    param([int]$Number)

    if ($Number -lt 1) {
        throw 'FinalizeMergedPullRequest requires a positive PullRequestNumber.'
    }
    foreach ($name in @('GITHUB_REPOSITORY', 'DEFAULT_BRANCH', 'GH_TOKEN')) {
        if (-not [Environment]::GetEnvironmentVariable($name)) {
            throw "Required finalization environment '$name' is missing."
        }
    }
    $repository = [string]$env:GITHUB_REPOSITORY
    if ($repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'GITHUB_REPOSITORY is not a canonical owner/repository identity.'
    }
    $defaultBranch = [string]$env:DEFAULT_BRANCH
    $state = Get-ManagedMergedPullRequestState -Repository $repository `
        -DefaultBranch $defaultBranch -Number $Number
    if (-not [bool]$state.Managed) {
        Write-Host "Pull request #$Number is not meAndAI-managed; no finalization was required."
        return
    }

    $fresh = Get-ManagedMergedPullRequestState -Repository $repository `
        -DefaultBranch $defaultBranch -Number $Number
    foreach ($property in @('Kind', 'Branch', 'Head', 'IssueNumber', 'EvidenceMarker')) {
        if ([string]$fresh.$property -cne [string]$state.$property) {
            throw "Managed pull request #$Number changed before finalization mutation."
        }
    }
    if ($null -ne $fresh.BranchHead) {
        if ([string]$fresh.BranchHead -cne [string]$fresh.Head) {
            throw "Managed branch '$($fresh.Branch)' moved before finalization."
        }
        Remove-RemoteBranch -Branch ([string]$fresh.Branch) `
            -ExpectedHeadSha ([string]$fresh.Head)
        if ($null -ne (Get-RemoteBranchHead -Branch ([string]$fresh.Branch))) {
            throw "Managed branch '$($fresh.Branch)' still exists after exact-head deletion."
        }
    }

    $afterBranch = Get-ManagedMergedPullRequestState -Repository $repository `
        -DefaultBranch $defaultBranch -Number $Number
    if ($null -ne $afterBranch.BranchHead -or
        [int]$afterBranch.IssueNumber -ne [int]$fresh.IssueNumber) {
        throw "Managed pull request #$Number did not remain stable after branch convergence."
    }

    if (-not [bool]$afterBranch.EvidenceExists) {
        $comment = @(
            [string]$afterBranch.EvidenceMarker,
            "Finalized managed $($afterBranch.Kind.ToLowerInvariant()) merge #$Number at head ``$($afterBranch.Head)``.",
            "The deterministic branch ``$($afterBranch.Branch)`` is absent and the tracking issue can close as completed."
        ) -join [Environment]::NewLine
        Invoke-Native -Command 'gh' -Arguments @(
            'api', '--method', 'POST',
            "repos/$repository/issues/$($afterBranch.IssueNumber)/comments",
            '-f', "body=$comment"
        ) | Out-Null
    }

    $liveIssue = Invoke-GhJson -Arguments @(
        'api', "repos/$repository/issues/$($afterBranch.IssueNumber)"
    )
    $labels = @($liveIssue.labels | ForEach-Object { [string]$_.name })
    foreach ($label in @(
        'status:in-progress', 'status:needs-review', 'status:blocked'
    )) {
        if ($labels -ccontains $label) {
            $escaped = [Uri]::EscapeDataString($label)
            Invoke-Native -Command 'gh' -Arguments @(
                'api', '--method', 'DELETE',
                "repos/$repository/issues/$($afterBranch.IssueNumber)/labels/$escaped"
            ) | Out-Null
        }
    }
    if ([string]$liveIssue.state -ceq 'open') {
        Invoke-Native -Command 'gh' -Arguments @(
            'api', '--method', 'PATCH',
            "repos/$repository/issues/$($afterBranch.IssueNumber)",
            '-f', 'state=closed', '-f', 'state_reason=completed'
        ) | Out-Null
    }

    $complete = Get-ManagedMergedPullRequestState -Repository $repository `
        -DefaultBranch $defaultBranch -Number $Number
    $remainingTransient = @($complete.Issue.labels | ForEach-Object {
        [string]$_.name
    } | Where-Object { $_ -cin @(
        'status:in-progress', 'status:needs-review', 'status:blocked'
    ) })
    if ($null -ne $complete.BranchHead -or
        -not [bool]$complete.EvidenceExists -or
        [string]$complete.Issue.state -cne 'closed' -or
        $remainingTransient.Count -ne 0) {
        throw "Managed pull request #$Number finalization postcondition failed."
    }
    Add-RunSummary "Managed merge #$Number finalized at ``$($complete.Head)``; exact branch absent and issue #$($complete.IssueNumber) closed."
    Write-Host "Managed merge #$Number finalized; issue #$($complete.IssueNumber) closed and exact branch absent."
}

if ($FinalizeMergedPullRequest) {
    Invoke-ManagedMergedPullRequestFinalization -Number $PullRequestNumber
    return
}

foreach ($name in @(
    'GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN',
    'PROTOCOL_TOKEN'
)) {
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
$TrustedActor = Get-AuthenticatedUpdaterActor

$submodulePaths = @(Invoke-Native -Command 'git' -Arguments @(
    'config', '-f', '.gitmodules', '--get-regexp', '^submodule\..*\.path$'
))
$matchingSubmodules = @($submodulePaths | Where-Object {
    ([string]$_) -match '^(?<key>submodule\..+\.path)\s+(?<path>.+)$' -and
    [string]$Matches.path -ceq $ProtocolPath
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

$baseHeadSha = ((Invoke-Native -Command 'git' -Arguments @(
    'rev-parse', 'HEAD'
)) -join '').Trim()
if ($baseHeadSha -notmatch '^[0-9a-f]{40}$') {
    throw 'Unable to resolve the consumer default-branch head.'
}
$protocolBaseEntry = Get-LocalTreeEntry -Commit $baseHeadSha -Path $ProtocolPath
if ($protocolBaseEntry.Mode -cne '160000' -or
    $protocolBaseEntry.Type -cne 'commit' -or
    $protocolBaseEntry.Sha -notmatch '^[0-9a-f]{40}$') {
    throw "'$ProtocolPath' is not a protocol submodule gitlink."
}
$currentProtocolSha = $protocolBaseEntry.Sha

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
Assert-CurrentManagedAssets -BaseCommit $baseHeadSha `
    -CurrentProtocolSha $currentProtocolSha -SourcePath $sourcePath `
    -Assets $ManagedUpdaterAssets

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
    $protocolEntry = Get-RepositoryTreeEntry -Repository $repository `
        -HeadSha ([string]$details.head.sha) -Path $ProtocolPath
    $observedRemoteHead = Get-RemoteBranchHead -Branch ([string]$details.head.ref)
    $expectedChangedPaths = @($ProtocolPath)
    $managedAssetsMatchTarget = $false
    if ($expectedProtocolSha -match '^[0-9a-f]{40}$') {
        $expectedChangedPaths = @(Get-ExpectedManagedPaths `
            -BaseCommit $baseHeadSha -TargetProtocolSha $expectedProtocolSha `
            -SourcePath $sourcePath -ProtocolPath $ProtocolPath `
            -Assets $ManagedUpdaterAssets)
        $managedAssetsMatchTarget = Test-ManagedAssetEntriesMatchTarget `
            -Repository $repository -HeadSha ([string]$details.head.sha) `
            -ExpectedPaths $expectedChangedPaths `
            -TargetProtocolSha $expectedProtocolSha -SourcePath $sourcePath `
            -Assets $ManagedUpdaterAssets
    }
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
        ChangedPaths = @(Get-ValidatedPullRequestChangedPaths -Files $files)
        ExpectedChangedPaths = $expectedChangedPaths
        ManagedAssetEntriesMatchTarget = $managedAssetsMatchTarget
    })
}

$reservedBranches = @(Get-RemoteBranchesByPrefix -Prefix $BranchPrefix)
foreach ($reservedBranch in $reservedBranches) {
    $owners = @($candidates | Where-Object {
        [string]$_.HeadRef -ceq [string]$reservedBranch.Name -and
        [bool]$_.BranchExists -and
        [string]$_.ObservedHeadSha -ceq [string]$reservedBranch.Sha
    })
    if ($owners.Count -ne 1) {
        throw "Reserved updater branch '$($reservedBranch.Name)' has no single open proposal with matching live ownership; manual review is required."
    }
}
foreach ($candidate in @($candidates | Where-Object {
    [bool]$_.BranchExists -and
    ([string]$_.HeadRef).StartsWith($BranchPrefix, [StringComparison]::Ordinal)
})) {
    $inventoried = @($reservedBranches | Where-Object {
        [string]$_.Name -ceq [string]$candidate.HeadRef -and
        [string]$_.Sha -ceq [string]$candidate.ObservedHeadSha
    })
    if ($inventoried.Count -ne 1) {
        throw "Reserved updater branch '$($candidate.HeadRef)' changed during namespace inventory; manual review is required."
    }
}

$snapshot = [pscustomobject]@{
    SchemaVersion = 1
    CurrentTag = $currentTag
    AvailableTags = $availableTags
    Repository = $repository
    DefaultBranch = $env:DEFAULT_BRANCH
    BranchPrefix = $BranchPrefix
    ProtocolPath = $ProtocolPath
    ManagedPaths = $ManagedPaths
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
$releaseEvidence = $null
if ([string]$plan.LatestCompatibleTag -cne [string]$plan.CurrentTag) {
    $releaseEvidence = Get-ImmutableProtocolReleaseEvidence `
        -Repository $ProtocolRepository `
        -Tag ([string]$plan.LatestCompatibleTag) `
        -ProtocolToken $env:PROTOCOL_TOKEN
    $localTargetSha = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourcePath, 'rev-list', '-n', '1', [string]$plan.LatestCompatibleTag
    )) -join '').Trim()
    if ($localTargetSha -cne [string]$releaseEvidence.CommitSha) {
        throw "Protocol release '$($plan.LatestCompatibleTag)' does not match the checked-out exact tag commit."
    }
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
$reservedNamespaceRevalidated = $false
if ($create.Count -eq 1) {
    $targetTag = [string]$create[0].TargetTag
    if ($null -eq $releaseEvidence -or
        [string]$releaseEvidence.Tag -cne $targetTag) {
        throw "Resolver target '$targetTag' lacks matching immutable release evidence."
    }
    $targetSha = [string]$releaseEvidence.CommitSha
    & git -C $sourcePath merge-base --is-ancestor $currentProtocolSha $targetSha
    if ($LASTEXITCODE -ne 0) {
        throw "Target '$targetTag' is not a descendant of current protocol '$currentTag'."
    }
    $expectedManagedPaths = @(Get-ExpectedManagedPaths `
        -BaseCommit $baseHeadSha -TargetProtocolSha $targetSha `
        -SourcePath $sourcePath -ProtocolPath $ProtocolPath `
        -Assets $ManagedUpdaterAssets)
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourcePath, 'checkout', '--detach', $targetSha
    ) | Out-Null
    foreach ($asset in $ManagedUpdaterAssets) {
        $relativeTemplatePath = [string]$asset.TemplatePath -replace '/', [IO.Path]::DirectorySeparatorChar
        $templateFile = Join-Path $sourcePath $relativeTemplatePath
        if (-not (Test-Path -LiteralPath $templateFile -PathType Leaf)) {
            throw "Target release checkout is missing updater template '$($asset.TemplatePath)'."
        }
    }

    $createdBranch = [string]$create[0].Branch
    if ($null -ne (Get-RemoteBranchHead -Branch $createdBranch)) {
        throw "Reserved target branch '$createdBranch' already exists without a valid managed PR."
    }

    Invoke-Native -Command 'git' -Arguments @('switch', '-c', $createdBranch) | Out-Null
    Invoke-Native -Command 'git' -Arguments @('update-index', '--add', '--cacheinfo', "160000,$targetSha,$ProtocolPath") | Out-Null
    foreach ($asset in $ManagedUpdaterAssets) {
        $relativeTemplatePath = [string]$asset.TemplatePath -replace '/', [IO.Path]::DirectorySeparatorChar
        $relativeConsumerPath = [string]$asset.ConsumerPath -replace '/', [IO.Path]::DirectorySeparatorChar
        Copy-Item -LiteralPath (Join-Path $sourcePath $relativeTemplatePath) `
            -Destination (Join-Path $workspace $relativeConsumerPath) -Force
    }
    $addArguments = @('add', '--') + @($ManagedUpdaterAssets | ForEach-Object {
        [string]$_.ConsumerPath
    })
    Invoke-Native -Command 'git' -Arguments $addArguments | Out-Null
    Assert-StagedManagedUpdate -ExpectedPaths $expectedManagedPaths `
        -TargetProtocolSha $targetSha -SourcePath $sourcePath `
        -ProtocolPath $ProtocolPath -Assets $ManagedUpdaterAssets

    Invoke-Native -Command 'git' -Arguments @('config', 'user.name', 'github-actions[bot]') | Out-Null
    Invoke-Native -Command 'git' -Arguments @('config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com') | Out-Null
    Invoke-Native -Command 'git' -Arguments @('commit', '-m', "Upgrade common protocol to $targetTag") | Out-Null
    $headSha = ((Invoke-Native -Command 'git' -Arguments @('rev-parse', 'HEAD')) -join '').Trim()

    $pushSucceeded = $false
    $marker = ''
    try {
        $confirmedReservedBranches = @(Get-RemoteBranchesByPrefix -Prefix $BranchPrefix)
        if (-not (Test-ExactRemoteBranchInventory -Expected $reservedBranches `
            -Actual $confirmedReservedBranches)) {
            throw 'The reserved updater branch namespace changed before replacement publication.'
        }
        $reservedNamespaceRevalidated = $true
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
            '- [ ] Create or link the tracked issue, allocate its stable work ID, and replace the placeholder below with exactly `Tracking issue: #N`.',
            '- [ ] Read every intervening meAndAI changelog entry.',
            '- [ ] Review incompatible or newly mandatory rules.',
            '- [ ] Review the managed updater asset changes included in this proposal.',
            '- [ ] Update the consumer project memory pinned-version fact.',
            '- [ ] Run project tests and complete DoR/DoD review.', '',
            'Tracking issue: #REQUIRED'
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
            -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
            -SourcePath $sourcePath -BaseCommit $baseHeadSha `
            -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths
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
                        -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
                        -SourcePath $sourcePath -BaseCommit $baseHeadSha `
                        -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths
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
$closeOperations = @($plan.Operations | Where-Object Kind -eq 'ClosePullRequest')
if (-not $reservedNamespaceRevalidated -and $closeOperations.Count -gt 0) {
    $confirmedReservedBranches = @(Get-RemoteBranchesByPrefix -Prefix $BranchPrefix)
    if (-not (Test-ExactRemoteBranchInventory -Expected $reservedBranches `
        -Actual $confirmedReservedBranches)) {
        throw 'The reserved updater branch namespace changed before proposal cleanup.'
    }
    $reservedNamespaceRevalidated = $true
}
foreach ($operation in $closeOperations) {
    $deleteOperation = @($deleteOperations | Where-Object {
        $_.PullRequestNumber -eq $operation.PullRequestNumber -and $_.Branch -eq $operation.Branch
    })
    if ($deleteOperation.Count -ne 1) {
        throw "Resolver did not provide exactly one paired branch cleanup for PR #$($operation.PullRequestNumber)."
    }
    Assert-ManagedPullRequestSafe -Repository $repository -Operation $operation `
        -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
        -SourcePath $sourcePath -BaseCommit $baseHeadSha `
        -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths
    if ($null -ne $replacementOperation) {
        Assert-ManagedPullRequestSafe -Repository $repository -Operation $replacementOperation `
            -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
            -SourcePath $sourcePath -BaseCommit $baseHeadSha `
            -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths
    }
    Invoke-Native -Command 'gh' -Arguments @('api', '--method', 'PATCH', "repos/$repository/pulls/$($operation.PullRequestNumber)", '-f', 'state=closed') | Out-Null

    try {
        Assert-ManagedPullRequestSafe -Repository $repository -Operation $operation `
            -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
            -SourcePath $sourcePath -BaseCommit $baseHeadSha `
            -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths `
            -ExpectedPullRequestState Closed -ExpectedBranchExists $true
        if ($null -ne $replacementOperation) {
            Assert-ManagedPullRequestSafe -Repository $repository -Operation $replacementOperation `
                -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
                -SourcePath $sourcePath -BaseCommit $baseHeadSha `
                -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths
        }
        Remove-RemoteBranch -Branch ([string]$operation.Branch) `
            -ExpectedHeadSha ([string]$operation.ExpectedHeadSha)
        Assert-ManagedPullRequestSafe -Repository $repository -Operation $operation `
            -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
            -SourcePath $sourcePath -BaseCommit $baseHeadSha `
            -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths `
            -ExpectedPullRequestState Closed -ExpectedBranchExists $false
        if ($null -ne $replacementOperation) {
            Assert-ManagedPullRequestSafe -Repository $repository -Operation $replacementOperation `
                -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
                -SourcePath $sourcePath -BaseCommit $baseHeadSha `
                -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths
        }
    }
    catch {
        $cleanupError = $_.Exception.Message
        try {
            Invoke-Native -Command 'gh' -Arguments @(
                'api', '--method', 'PATCH', "repos/$repository/pulls/$($operation.PullRequestNumber)",
                '-f', 'state=open'
            ) | Out-Null
            Assert-ManagedPullRequestSafe -Repository $repository -Operation $operation `
                -ProtocolPath $ProtocolPath -TrustedActor $TrustedActor `
                -SourcePath $sourcePath -BaseCommit $baseHeadSha `
                -ManagedAssets $ManagedUpdaterAssets -ManagedPaths $ManagedPaths `
                -ExpectedPullRequestState Open -ExpectedBranchExists $true
        }
        catch {
            throw "Branch cleanup failed for PR #$($operation.PullRequestNumber), and the PR could not be reopened. Manual recovery is required. Original error: $cleanupError"
        }
        throw "Branch cleanup failed for PR #$($operation.PullRequestNumber); the PR was reopened and the branch preserved. $cleanupError"
    }
    $comment = if ($null -ne $replacementPullRequestNumber) {
        "Superseded by #$replacementPullRequestNumber, the verified ``$($plan.LatestCompatibleTag)`` protocol proposal. Automated cleanup closed this PR and deleted its unchanged branch using an exact-head lease."
    }
    else {
        "The default branch already contains ``$($operation.TargetTag)``. Automated cleanup closed this PR and deleted its unchanged branch using an exact-head lease."
    }
    Invoke-Native -Command 'gh' -Arguments @(
        'api', '--method', 'POST',
        "repos/$repository/issues/$($operation.PullRequestNumber)/comments",
        '-f', "body=$comment"
    ) | Out-Null
}

Write-Host "Protocol update reconciliation completed: $($plan.State)."
