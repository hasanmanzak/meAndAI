[CmdletBinding()]
param(
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolPath = '.ai/protocol',
    [string]$ProtocolSourcePath = '.meandai-update-source',
    [string]$TargetTag = 'v0.8.2',
    [string]$BranchPrefix = 'automation/meandai-capabilities-'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$SeedWorkflow = [pscustomobject]@{
    ConsumerPath = '.github/workflows/meandai-protocol-update.yml'
    TemplatePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
}
$AdoptionAssets = @(
    [pscustomobject]@{
        ConsumerPath = 'AGENTS.md'
        TemplatePath = 'templates/project/AGENTS.submodule.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/README.md'
        TemplatePath = 'templates/project/.ai/memory/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/project.md'
        TemplatePath = 'templates/project/.ai/memory/project.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/log/README.md'
        TemplatePath = 'templates/project/.ai/memory/log/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = 'docs/ideas/README.md'
        TemplatePath = 'templates/project/docs/ideas/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/bug.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/bug.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/epic.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/epic.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/feature.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/feature.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/finding.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/finding.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/subfeature.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/subfeature.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/task.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/task.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/PULL_REQUEST_TEMPLATE.md'
        TemplatePath = '.github/PULL_REQUEST_TEMPLATE.md'
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
$ManifestPath = '.ai/adoption/meandai-capabilities.json'
$RequiredTasks = @(
    'Create or reconcile the repository labels required by the protocol.',
    'Create project-owned feature and decision records for adoption.',
    'Tailor project-local memory without importing protocol-repository facts.',
    'Resolve every collision through semantic review; do not overwrite blindly.',
    'Create and run the project test evidence required by DoR and DoD.',
    'Verify all documentation links and traceability references.',
    'Remove the manifest before marking the pull request ready or merging it.'
)

function Invoke-Native {
    param([string]$Command, [string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $Command @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Test-ExactOrdinalSequence {
    param([object[]]$Actual, [object[]]$Expected)

    $actualValues = @($Actual | ForEach-Object { [string]$_ })
    $expectedValues = @($Expected | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $expectedValues.Count) {
        return $false
    }
    for ($index = 0; $index -lt $actualValues.Count; $index++) {
        if ($actualValues[$index] -cne $expectedValues[$index]) {
            return $false
        }
    }
    return $true
}

function Get-TreeEntry {
    param(
        [string]$RepositoryPath,
        [string]$Commit,
        [string]$Path
    )

    $output = @(Invoke-Native -Command 'git' -Arguments @(
        '-C', $RepositoryPath, 'ls-tree', $Commit, '--', $Path
    ))
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

function Get-StagedEntry {
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

function Get-RemoteBranchHead {
    param([string]$Branch)

    $ref = "refs/heads/$Branch"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git ls-remote --exit-code --heads origin $ref 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -eq 2) {
        return ''
    }
    if ($exitCode -ne 0) {
        throw "git ls-remote failed: $($output -join [Environment]::NewLine)"
    }
    if ($output.Count -ne 1 -or
        [string]$output[0] -notmatch "^[0-9a-f]{40}\s+$([regex]::Escape($ref))$") {
        throw "Remote adoption branch '$Branch' is ambiguous."
    }
    return ([string]$output[0]).Split("`t")[0]
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
            throw 'The reserved adoption branch inventory is invalid.'
        }
        $name = $match.Groups['ref'].Value.Substring('refs/heads/'.Length)
        if (-not $names.Add($name)) {
            throw "Reserved adoption branch '$name' is ambiguous."
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
    return Test-ExactOrdinalSequence -Actual $actualRows -Expected $expectedRows
}

function Get-OpenAdoptionPullRequests {
    param([string]$Repository, [string]$Branch)

    $text = (Invoke-Native -Command 'gh' -Arguments @(
        'pr', 'list', '--repo', $Repository, '--state', 'open',
        '--head', $Branch, '--json',
        'number,url,headRefName,headRefOid,baseRefName,headRepository,author,body,isDraft,state'
    )) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($text)) {
        return @()
    }
    $parsed = $text | ConvertFrom-Json
    if ($null -eq $parsed -or
        ($parsed -is [array] -and $parsed.Count -eq 0)) {
        return @()
    }
    return @($parsed)
}

function Test-ExactAdoptionPullRequestMarker {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [string]$RemoteHead,
        [string]$Repository,
        [string]$Branch,
        [string]$BaseBranch,
        [string]$TargetTag,
        [string]$TargetSha,
        [string]$ExpectedActor,
        [string]$ExpectedState,
        [ValidateSet('Proposed', 'Completed')]
        [string]$ExpectedPhase = 'Proposed'
    )

    foreach ($property in @(
        'number', 'url', 'headRefName', 'headRefOid', 'baseRefName',
        'headRepository', 'author', 'body', 'isDraft', 'state'
    )) {
        if ($null -eq $PullRequest.PSObject.Properties[$property]) {
            return $false
        }
    }
    $expectedDraft = $ExpectedPhase -ceq 'Proposed'
    if ([string]$PullRequest.state -cne 'OPEN' -or
        [string]$PullRequest.headRefName -cne $Branch -or
        [string]$PullRequest.headRefOid -cne $RemoteHead -or
        [string]$PullRequest.baseRefName -cne $BaseBranch -or
        $PullRequest.isDraft -isnot [bool] -or
        [bool]$PullRequest.isDraft -ne $expectedDraft -or
        [string]$PullRequest.number -cnotmatch '^[1-9][0-9]*$' -or
        [string]$PullRequest.url -cnotmatch "/pull/$([regex]::Escape([string]$PullRequest.number))/?$") {
        return $false
    }
    if ($null -eq $PullRequest.headRepository -or
        $null -eq $PullRequest.headRepository.PSObject.Properties['nameWithOwner'] -or
        -not ([string]$PullRequest.headRepository.nameWithOwner).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        $null -eq $PullRequest.author -or
        $null -eq $PullRequest.author.PSObject.Properties['login'] -or
        -not ([string]$PullRequest.author.login).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        )) {
        return $false
    }

    $body = [string]$PullRequest.body
    $markerStarts = [regex]::Matches(
        $body, '<!--\s*meandai-capabilities-adoption:',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    $markerMatches = [regex]::Matches(
        $body, '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($markerStarts.Count -ne 1 -or $markerMatches.Count -ne 1) {
        return $false
    }
    try {
        $marker = $markerMatches[0].Groups['json'].Value | ConvertFrom-Json
    }
    catch {
        return $false
    }
    $schemaProperty = $marker.PSObject.Properties['schema']
    if ($null -eq $schemaProperty -or
        ($schemaProperty.Value -isnot [int] -and
         $schemaProperty.Value -isnot [long])) {
        return $false
    }
    $schema = [long]$schemaProperty.Value
    # Schema 2 is retained only as the explicit legacy Proposed representation.
    # Every proposal created by this adapter uses schema 3 and an explicit phase.
    $expectedProperties = if ($schema -eq 2) {
        @('schema', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 3) {
        @('schema', 'phase', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    else {
        return $false
    }
    $actualProperties = @($marker.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualProperties.Count -ne $expectedProperties.Count -or
        @($expectedProperties | Where-Object { $actualProperties -cnotcontains $_ }).Count -ne 0) {
        return $false
    }
    $phase = if ($schema -eq 2) { 'Proposed' } else { [string]$marker.phase }
    if (-not (
        $phase -ceq $ExpectedPhase -and
        ($ExpectedPhase -ceq 'Proposed' -or $schema -eq 3) -and
        [string]$marker.state -ceq $ExpectedState -and
        [string]$marker.target -ceq $TargetTag -and
        [string]$marker.protocolSha -ceq $TargetSha -and
        [string]$marker.head -ceq $RemoteHead -and
        ([string]$marker.repository).Equals($Repository, [StringComparison]::OrdinalIgnoreCase) -and
        ([string]$marker.actor).Equals($ExpectedActor, [StringComparison]::OrdinalIgnoreCase)
    )) {
        return $false
    }

    return $true
}

function Test-ExactAdoptionTree {
    param(
        [string]$RemoteHead,
        [string]$Branch,
        [string]$BaseHead,
        [string]$TargetSha,
        [string]$ProposalMode,
        [string]$SourcePath
    )

    Invoke-Native -Command 'git' -Arguments @(
        'fetch', '--no-tags', 'origin', "refs/heads/$Branch"
    ) | Out-Null
    $fetchedHead = ((Invoke-Native -Command 'git' -Arguments @(
        'rev-parse', 'FETCH_HEAD'
    )) -join '').Trim()
    if ($fetchedHead -cne $RemoteHead) {
        return $false
    }
    $ancestry = (((Invoke-Native -Command 'git' -Arguments @(
        'rev-list', '--parents', '-n', '1', $RemoteHead
    )) -join '').Trim() -split '\s+')
    if ($ancestry.Count -ne 2 -or
        $ancestry[0] -cne $RemoteHead -or
        $ancestry[1] -cne $BaseHead) {
        return $false
    }

    $expectedChangedPaths = if ($ProposalMode -ceq 'Full') {
        @('.gitmodules', $ProtocolPath) + @($AdoptionAssets | ForEach-Object {
            [string]$_.ConsumerPath
        }) + @($ManifestPath)
    }
    elseif ($ProposalMode -ceq 'ManifestOnly') {
        @($ManifestPath)
    }
    else {
        return $false
    }
    $actualChangedPaths = @(Invoke-Native -Command 'git' -Arguments @(
        'diff', '--no-renames', '--name-only', $BaseHead, $RemoteHead, '--'
    ) | ForEach-Object { [string]$_ })
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $actualChangedPaths -Expected $expectedChangedPaths)) {
        return $false
    }

    if ($ProposalMode -ceq 'Full') {
        $gitmodulesText = ((Invoke-Native -Command 'git' -Arguments @(
            'show', "${RemoteHead}:.gitmodules"
        )) -join "`n")
        $expectedGitmodulesText = @(
            "[submodule `"$ProtocolPath`"]",
            "`tpath = $ProtocolPath",
            "`turl = https://github.com/$ProtocolRepository.git"
        ) -join "`n"
        if ($gitmodulesText -cne $expectedGitmodulesText) {
            return $false
        }
        $protocolEntry = Get-TreeEntry -RepositoryPath $env:GITHUB_WORKSPACE `
            -Commit $RemoteHead -Path $ProtocolPath
        if ($protocolEntry.Mode -cne '160000' -or
            $protocolEntry.Type -cne 'commit' -or
            $protocolEntry.Sha -cne $TargetSha) {
            return $false
        }
        foreach ($asset in $AdoptionAssets) {
            $sourceEntry = Get-TreeEntry -RepositoryPath $SourcePath `
                -Commit $TargetSha -Path ([string]$asset.TemplatePath)
            $proposalEntry = Get-TreeEntry -RepositoryPath $env:GITHUB_WORKSPACE `
                -Commit $RemoteHead -Path ([string]$asset.ConsumerPath)
            if ($sourceEntry.Mode -cne '100644' -or
                $sourceEntry.Type -cne 'blob' -or
                $proposalEntry.Mode -cne $sourceEntry.Mode -or
                $proposalEntry.Type -cne $sourceEntry.Type -or
                $proposalEntry.Sha -cne $sourceEntry.Sha) {
                return $false
            }
        }
    }

    return $true
}

function Test-ExactAdoptionManifest {
    param(
        [string]$RemoteHead,
        [string]$Repository,
        [string]$TargetTag,
        [string]$TargetSha,
        [string]$ExpectedState,
        [string[]]$Collisions,
        [string[]]$TargetPaths
    )

    $manifestText = ((Invoke-Native -Command 'git' -Arguments @(
        'show', "${RemoteHead}:$ManifestPath"
    )) -join "`n")
    try {
        $manifest = $manifestText | ConvertFrom-Json
    }
    catch {
        return $false
    }
    $manifestProperties = @(
        'schema', 'operation', 'state', 'repository', 'targetTag', 'protocolSha',
        'collisions', 'proposedPaths', 'requiredTasks'
    )
    $actualManifestProperties = @($manifest.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualManifestProperties.Count -ne $manifestProperties.Count -or
        @($manifestProperties | Where-Object {
            $actualManifestProperties -cnotcontains $_
        }).Count -ne 0 -or
        ($manifest.schema -isnot [int] -and $manifest.schema -isnot [long]) -or
        [long]$manifest.schema -ne 1 -or
        [string]$manifest.operation -cne 'ai-capabilities-adoption' -or
        [string]$manifest.state -cne $ExpectedState -or
        -not ([string]$manifest.repository).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$manifest.targetTag -cne $TargetTag -or
        [string]$manifest.protocolSha -cne $TargetSha -or
        -not (Test-ExactOrdinalSequence `
            -Actual @($manifest.collisions | ForEach-Object { [string]$_ }) `
            -Expected @($Collisions)) -or
        -not (Test-ExactOrdinalSequence `
            -Actual @($manifest.proposedPaths | ForEach-Object { [string]$_ }) `
            -Expected (@([string]$SeedWorkflow.ConsumerPath) + @($TargetPaths))) -or
        -not (Test-ExactOrdinalSequence `
            -Actual @($manifest.requiredTasks | ForEach-Object { [string]$_ }) `
            -Expected $RequiredTasks)) {
        return $false
    }

    return $true
}

function Test-ExactAdoptionContinuity {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [string]$RemoteHead,
        [string]$Repository,
        [string]$Branch
    )

    $confirmedRemoteHead = Get-RemoteBranchHead -Branch $Branch
    $confirmedPullRequests = @(Get-OpenAdoptionPullRequests `
        -Repository $Repository -Branch $Branch)
    if ($confirmedRemoteHead -cne $RemoteHead -or
        $confirmedPullRequests.Count -ne 1 -or
        (($confirmedPullRequests[0] | ConvertTo-Json -Depth 8 -Compress) -cne
         ($pullRequest | ConvertTo-Json -Depth 8 -Compress))) {
        return $false
    }

    return $true
}

function Test-ExactAdoptionProposal {
    param(
        [object[]]$PullRequests,
        [string]$RemoteHead,
        [string]$Repository,
        [string]$Branch,
        [string]$BaseBranch,
        [string]$BaseHead,
        [string]$TargetTag,
        [string]$TargetSha,
        [string]$ExpectedActor,
        [string]$ExpectedState,
        [string]$ProposalMode,
        [string[]]$Collisions,
        [string[]]$TargetPaths,
        [string]$SourcePath
    )

    if ($PullRequests.Count -ne 1 -or $RemoteHead -notmatch '^[0-9a-f]{40}$') {
        return $false
    }
    $pullRequest = $PullRequests[0]
    if (-not (Test-ExactAdoptionPullRequestMarker -PullRequest $pullRequest `
        -RemoteHead $RemoteHead -Repository $Repository -Branch $Branch `
        -BaseBranch $BaseBranch -TargetTag $TargetTag -TargetSha $TargetSha `
        -ExpectedActor $ExpectedActor -ExpectedState $ExpectedState)) {
        return $false
    }
    if (-not (Test-ExactAdoptionTree -RemoteHead $RemoteHead -Branch $Branch `
        -BaseHead $BaseHead -TargetSha $TargetSha -ProposalMode $ProposalMode `
        -SourcePath $SourcePath)) {
        return $false
    }
    if (-not (Test-ExactAdoptionManifest -RemoteHead $RemoteHead `
        -Repository $Repository -TargetTag $TargetTag -TargetSha $TargetSha `
        -ExpectedState $ExpectedState -Collisions $Collisions `
        -TargetPaths $TargetPaths)) {
        return $false
    }
    return Test-ExactAdoptionContinuity -PullRequest $pullRequest `
        -RemoteHead $RemoteHead -Repository $Repository -Branch $Branch
}

function Test-ExactCompletedAdoptionProposal {
    param(
        [object[]]$PullRequests,
        [string]$RemoteHead,
        [string]$Repository,
        [string]$Branch,
        [string]$BaseBranch,
        [string]$TargetTag,
        [string]$TargetSha,
        [string]$ExpectedActor,
        [string]$ExpectedState,
        [string]$SourcePath
    )

    if ($PullRequests.Count -ne 1 -or $RemoteHead -notmatch '^[0-9a-f]{40}$') {
        return $false
    }
    $pullRequest = $PullRequests[0]
    if (-not (Test-ExactAdoptionPullRequestMarker -PullRequest $pullRequest `
        -RemoteHead $RemoteHead -Repository $Repository -Branch $Branch `
        -BaseBranch $BaseBranch -TargetTag $TargetTag -TargetSha $TargetSha `
        -ExpectedActor $ExpectedActor -ExpectedState $ExpectedState `
        -ExpectedPhase 'Completed')) {
        return $false
    }

    Invoke-Native -Command 'git' -Arguments @(
        'fetch', '--no-tags', 'origin', "refs/heads/$Branch"
    ) | Out-Null
    $fetchedHead = ((Invoke-Native -Command 'git' -Arguments @(
        'rev-parse', 'FETCH_HEAD'
    )) -join '').Trim()
    if ($fetchedHead -cne $RemoteHead) {
        return $false
    }
    $manifestEntry = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path $ManifestPath
    $protocolEntry = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path $ProtocolPath
    $completedSeed = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path ([string]$SeedWorkflow.ConsumerPath)
    $sourceSeed = Get-TreeEntry -RepositoryPath $SourcePath `
        -Commit $TargetSha -Path ([string]$SeedWorkflow.TemplatePath)
    if ($manifestEntry.Path -or
        $protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cne $TargetSha -or
        $completedSeed.Mode -cne '100644' -or
        $completedSeed.Type -cne 'blob' -or
        $sourceSeed.Mode -cne '100644' -or
        $sourceSeed.Type -cne 'blob' -or
        $completedSeed.Sha -cne $sourceSeed.Sha) {
        return $false
    }
    return Test-ExactAdoptionContinuity -PullRequest $pullRequest `
        -RemoteHead $RemoteHead -Repository $Repository -Branch $Branch
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Add-RunSummary {
    param([string]$Text)

    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

function Assert-StagedProposal {
    param(
        [string[]]$ExpectedPaths,
        [string]$ProposalMode,
        [string]$SourcePath,
        [string]$TargetSha
    )

    $stagedPaths = @(Invoke-Native -Command 'git' -Arguments @(
        'diff', '--cached', '--no-renames', '--name-only'
    ))
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $stagedPaths -Expected $ExpectedPaths)) {
        throw "Adoption staging escaped the expected path set: $($stagedPaths -join ', ')."
    }
    if ($ProposalMode -cne 'Full') {
        return
    }

    $protocolEntry = Get-StagedEntry -Path $ProtocolPath
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Sha -cne $TargetSha) {
        throw "Staged protocol gitlink does not match '$TargetSha'."
    }
    foreach ($asset in $AdoptionAssets) {
        $sourceEntry = Get-TreeEntry -RepositoryPath $SourcePath `
            -Commit $TargetSha -Path ([string]$asset.TemplatePath)
        $stagedEntry = Get-StagedEntry -Path ([string]$asset.ConsumerPath)
        if ($sourceEntry.Mode -cne '100644' -or
            $sourceEntry.Type -cne 'blob' -or
            $stagedEntry.Mode -cne $sourceEntry.Mode -or
            $stagedEntry.Sha -cne $sourceEntry.Sha) {
            throw "Staged adoption asset '$($asset.ConsumerPath)' does not match the pinned release."
        }
    }
}

foreach ($name in @('GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN')) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Required environment variable '$name' is missing."
    }
}
$workspace = [IO.Path]::GetFullPath($env:GITHUB_WORKSPACE)
$sourcePath = [IO.Path]::GetFullPath((Join-Path $workspace $ProtocolSourcePath))
$lifecycleModulePath = Join-Path $sourcePath 'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$updateModulePath = Join-Path $sourcePath 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath '.git'))) {
    throw "Pinned protocol source checkout is missing: $sourcePath"
}
if (-not (Test-Path -LiteralPath $lifecycleModulePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $updateModulePath -PathType Leaf)) {
    throw 'Pinned protocol source is missing a bootstrap resolver module.'
}
Import-Module $updateModulePath -Force
Import-Module $lifecycleModulePath -Force
if (-not (Test-MeAndAIProtocolTag -Tag $TargetTag)) {
    throw "Target tag '$TargetTag' is not canonical vM.m.rev."
}
Set-Location -LiteralPath $workspace

$targetSha = ((Invoke-Native -Command 'git' -Arguments @(
    '-C', $sourcePath, 'rev-parse', "$TargetTag^{commit}"
)) -join '').Trim()
$sourceHead = ((Invoke-Native -Command 'git' -Arguments @(
    '-C', $sourcePath, 'rev-parse', 'HEAD'
)) -join '').Trim()
if ($targetSha -notmatch '^[0-9a-f]{40}$' -or $sourceHead -cne $targetSha) {
    throw "Pinned protocol source does not exactly match '$TargetTag'; manual review is required."
}
$baseHead = ((Invoke-Native -Command 'git' -Arguments @(
    'rev-parse', 'HEAD'
)) -join '').Trim()
if ($baseHead -notmatch '^[0-9a-f]{40}$') {
    throw 'Unable to resolve the consumer default-branch head.'
}

$seedConsumerEntry = Get-TreeEntry -RepositoryPath $workspace `
    -Commit $baseHead -Path ([string]$SeedWorkflow.ConsumerPath)
$seedSourceEntry = Get-TreeEntry -RepositoryPath $sourcePath `
    -Commit $targetSha -Path ([string]$SeedWorkflow.TemplatePath)
$seedWorkflowState = if (
    $seedConsumerEntry.Mode -ceq '100644' -and
    $seedConsumerEntry.Type -ceq 'blob' -and
    $seedSourceEntry.Mode -ceq '100644' -and
    $seedSourceEntry.Type -ceq 'blob' -and
    $seedConsumerEntry.Sha -ceq $seedSourceEntry.Sha
) { 'Exact' }
elseif (-not $seedConsumerEntry.Path) { 'Missing' }
else { 'Drifted' }

$basePaths = @(Invoke-Native -Command 'git' -Arguments @(
    'ls-tree', '-r', '--name-only', $baseHead
) | ForEach-Object { [string]$_ })
$basePathLookup = [System.Collections.Generic.Dictionary[string, string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($path in $basePaths) {
    if ($basePathLookup.ContainsKey($path)) {
        throw "Consumer tree contains case-ambiguous path '$path'; manual review is required."
    }
    $basePathLookup.Add($path, $path)
}

$targetPaths = @('.gitmodules', $ProtocolPath) + @($AdoptionAssets | ForEach-Object {
    [string]$_.ConsumerPath
})
$collisions = [System.Collections.Generic.List[string]]::new()
foreach ($path in $targetPaths) {
    if ($basePathLookup.ContainsKey($path)) {
        $collisions.Add([string]$basePathLookup[$path])
    }
}
$manifestExists = $basePathLookup.ContainsKey($ManifestPath)
$updaterPaths = @(
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)
$updaterCount = @($updaterPaths | Where-Object {
    $basePathLookup.ContainsKey($_)
}).Count
$localUpdaterState = if ($updaterCount -eq 0) { 'Absent' }
elseif ($updaterCount -eq $updaterPaths.Count) { 'Complete' }
else { 'Partial' }

$branch = "$BranchPrefix$TargetTag"
$actor = ((Invoke-Native -Command 'gh' -Arguments @(
    'api', 'user', '--jq', '.login'
)) -join '').Trim()
if ($actor -notmatch '^[A-Za-z0-9_.-]+$') {
    throw 'The authenticated updater identity is invalid.'
}
$reservedBranches = @(Get-RemoteBranchesByPrefix -Prefix $BranchPrefix)
$unexpectedReservedBranches = @($reservedBranches | Where-Object {
    [string]$_.Name -cne $branch
})
if ($unexpectedReservedBranches.Count -gt 0) {
    throw "The reserved adoption branch namespace contains unowned or stale state: $(@($unexpectedReservedBranches.Name) -join ', '). Manual review is required."
}
$inventoriedTarget = @($reservedBranches | Where-Object {
    [string]$_.Name -ceq $branch
})
if ($inventoriedTarget.Count -gt 1) {
    throw "Remote adoption branch '$branch' is ambiguous."
}
$remoteBranchHead = Get-RemoteBranchHead -Branch $branch
if (($inventoriedTarget.Count -eq 0 -and $remoteBranchHead) -or
    ($inventoriedTarget.Count -eq 1 -and
     [string]$inventoriedTarget[0].Sha -cne $remoteBranchHead)) {
    throw 'The reserved adoption branch namespace changed during inventory.'
}
$pullRequests = @(Get-OpenAdoptionPullRequests `
    -Repository $env:GITHUB_REPOSITORY -Branch $branch)
$proposalContract = Resolve-MeAndAICapabilitiesLifecycle -Snapshot ([pscustomobject]@{
    SchemaVersion = 1
    LocalUpdaterState = $localUpdaterState
    SeedWorkflowState = $seedWorkflowState
    Collisions = @($collisions)
    ManifestExists = $manifestExists
    RemoteBranchExists = $false
    OpenPullRequestCount = 0
    ExistingProposalValid = $false
})
$existingProposalValid = if ($proposalContract.State -cin @(
    'BootstrapReady', 'AdoptionReviewRequired'
)) {
    $proposedValid = Test-ExactAdoptionProposal -PullRequests $pullRequests `
        -RemoteHead $remoteBranchHead -Repository $env:GITHUB_REPOSITORY `
        -Branch $branch -BaseBranch $env:DEFAULT_BRANCH -BaseHead $baseHead `
        -TargetTag $TargetTag -TargetSha $targetSha -ExpectedActor $actor `
        -ExpectedState ([string]$proposalContract.State) `
        -ProposalMode ([string]$proposalContract.ProposalMode) `
        -Collisions @($collisions) -TargetPaths $targetPaths -SourcePath $sourcePath
    if ($proposedValid) {
        $true
    }
    else {
        Test-ExactCompletedAdoptionProposal -PullRequests $pullRequests `
            -RemoteHead $remoteBranchHead -Repository $env:GITHUB_REPOSITORY `
            -Branch $branch -BaseBranch $env:DEFAULT_BRANCH `
            -TargetTag $TargetTag -TargetSha $targetSha -ExpectedActor $actor `
            -ExpectedState ([string]$proposalContract.State) `
            -SourcePath $sourcePath
    }
}
else { $false }
$snapshot = [pscustomobject]@{
    SchemaVersion = 1
    LocalUpdaterState = $localUpdaterState
    SeedWorkflowState = $seedWorkflowState
    Collisions = @($collisions)
    ManifestExists = $manifestExists
    RemoteBranchExists = [bool]$remoteBranchHead
    OpenPullRequestCount = $pullRequests.Count
    ExistingProposalValid = $existingProposalValid
}
$plan = Resolve-MeAndAICapabilitiesLifecycle -Snapshot $snapshot
Add-RunSummary "## meAndAI AI capabilities lifecycle`n`n- Target: ``$TargetTag```n- State: ``$($plan.State)```n- Proposal: ``$($plan.ProposalMode)``"

if ($plan.State -ceq 'PendingAdoption') {
    Write-Host 'AI capabilities lifecycle state: PendingAdoption. Existing maintainer-review proposal retained without mutation.'
    return
}
if ($plan.State -ceq 'Update') {
    throw 'Bootstrap adapter reached Update unexpectedly; use the local updater.'
}
if ($plan.State -ceq 'BlockedManualReview') {
    if ($manifestExists) {
        throw "The transient adoption manifest already exists; manual review is required."
    }
    if ($seedWorkflowState -cne 'Exact') {
        throw "The committed seed workflow does not match '$TargetTag'; manual review is required."
    }
    if ([bool]$remoteBranchHead -and $pullRequests.Count -eq 1 -and
        -not $existingProposalValid) {
        throw 'The existing adoption proposal failed ownership validation; manual review is required.'
    }
    if ([bool]$remoteBranchHead -and $pullRequests.Count -eq 0) {
        throw "An orphan adoption branch '$branch' exists; manual review is required."
    }
    throw "AI capabilities adoption requires manual review (remote branch: $([bool]$remoteBranchHead); open PRs: $($pullRequests.Count)): $($plan.Diagnostics -join '; ')"
}
if ($plan.State -cnotin @('BootstrapReady', 'AdoptionReviewRequired')) {
    throw "Unsupported lifecycle state '$($plan.State)'."
}

foreach ($asset in $AdoptionAssets) {
    $entry = Get-TreeEntry -RepositoryPath $sourcePath `
        -Commit $targetSha -Path ([string]$asset.TemplatePath)
    if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob') {
        throw "Pinned release is missing adoption template '$($asset.TemplatePath)'."
    }
}

Invoke-Native -Command 'git' -Arguments @('switch', '-c', $branch) | Out-Null
$stagedPaths = [System.Collections.Generic.List[string]]::new()
if ($plan.State -ceq 'BootstrapReady') {
    $gitmodules = @(
        "[submodule `"$ProtocolPath`"]",
        "`tpath = $ProtocolPath",
        "`turl = https://github.com/$ProtocolRepository.git",
        ''
    ) -join "`n"
    Write-Utf8NoBom -Path (Join-Path $workspace '.gitmodules') -Content $gitmodules
    Invoke-Native -Command 'git' -Arguments @(
        'update-index', '--add', '--cacheinfo', "160000,$targetSha,$ProtocolPath"
    ) | Out-Null
    $stagedPaths.Add('.gitmodules')
    $stagedPaths.Add($ProtocolPath)

    foreach ($asset in $AdoptionAssets) {
        $sourceFile = Join-Path $sourcePath `
            (([string]$asset.TemplatePath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $targetFile = Join-Path $workspace `
            (([string]$asset.ConsumerPath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $parent = Split-Path -Parent $targetFile
        New-Item -ItemType Directory -Force $parent | Out-Null
        Copy-Item -LiteralPath $sourceFile -Destination $targetFile
        $stagedPaths.Add([string]$asset.ConsumerPath)
    }
}

$manifest = [ordered]@{
    schema = 1
    operation = 'ai-capabilities-adoption'
    state = [string]$plan.State
    repository = [string]$env:GITHUB_REPOSITORY
    targetTag = $TargetTag
    protocolSha = $targetSha
    collisions = @($plan.Collisions)
    proposedPaths = @([string]$SeedWorkflow.ConsumerPath) + @($targetPaths)
    requiredTasks = $RequiredTasks
}
$manifestText = ($manifest | ConvertTo-Json -Depth 5) + "`n"
Write-Utf8NoBom -Path (Join-Path $workspace $ManifestPath) -Content $manifestText
$stagedPaths.Add($ManifestPath)

$addPaths = @($stagedPaths | Where-Object { $_ -cne $ProtocolPath })
Invoke-Native -Command 'git' -Arguments (@('add', '--') + $addPaths) | Out-Null
Assert-StagedProposal -ExpectedPaths @($stagedPaths) `
    -ProposalMode ([string]$plan.ProposalMode) `
    -SourcePath $sourcePath -TargetSha $targetSha

Invoke-Native -Command 'git' -Arguments @(
    'config', 'user.name', 'github-actions[bot]'
) | Out-Null
Invoke-Native -Command 'git' -Arguments @(
    'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com'
) | Out-Null
Invoke-Native -Command 'git' -Arguments @(
    'commit', '-m', "Propose AI capabilities adoption from $TargetTag"
) | Out-Null
$headSha = ((Invoke-Native -Command 'git' -Arguments @(
    'rev-parse', 'HEAD'
)) -join '').Trim()
$ref = "refs/heads/$branch"
$confirmedReservedBranches = @(Get-RemoteBranchesByPrefix -Prefix $BranchPrefix)
if (-not (Test-ExactRemoteBranchInventory -Expected $reservedBranches `
    -Actual $confirmedReservedBranches)) {
    throw 'The reserved adoption branch namespace changed before proposal publication.'
}
Invoke-Native -Command 'git' -Arguments @(
    'push', '--set-upstream', "--force-with-lease=${ref}:",
    'origin', "$branch`:$ref"
) | Out-Null

$marker = [ordered]@{
    schema = 3
    phase = 'Proposed'
    state = [string]$plan.State
    target = $TargetTag
    protocolSha = $targetSha
    head = $headSha
    repository = [string]$env:GITHUB_REPOSITORY
    actor = $actor
} | ConvertTo-Json -Compress
$collisionText = if (@($plan.Collisions).Count -gt 0) {
    @($plan.Collisions | ForEach-Object { "- ``$_``" }) -join [Environment]::NewLine
}
else { '- None' }
$body = @(
    "<!-- meandai-capabilities-adoption:$marker -->",
    '## AI capabilities adoption proposal', '',
    "- Lifecycle state: ``$($plan.State)``",
    "- Protocol release: ``$TargetTag``",
    "- Protocol commit: ``$targetSha``", '',
    '### Detected collisions', '', $collisionText, '',
    'This workflow does not start an AI agent. It creates a review-only draft handoff.',
    "An agent or maintainer must complete the tasks in ``$ManifestPath`` and remove the manifest before this pull request can become ready or merge.", '',
    'The proposal never merges itself.'
) -join [Environment]::NewLine
$url = (Invoke-Native -Command 'gh' -Arguments @(
    'pr', 'create', '--draft', '--base', $env:DEFAULT_BRANCH,
    '--head', $branch, '--title', "Adopt meAndAI capabilities from $TargetTag",
    '--body', $body
) | Select-Object -Last 1).Trim()
if ($url -notmatch '/pull/\d+/?$') {
    throw 'Created adoption PR returned an unrecognized URL.'
}
$publishedRemoteHead = Get-RemoteBranchHead -Branch $branch
$publishedPullRequests = @(Get-OpenAdoptionPullRequests `
    -Repository $env:GITHUB_REPOSITORY -Branch $branch)
$publishedProposalValid = Test-ExactAdoptionProposal `
    -PullRequests $publishedPullRequests -RemoteHead $publishedRemoteHead `
    -Repository $env:GITHUB_REPOSITORY -Branch $branch `
    -BaseBranch $env:DEFAULT_BRANCH -BaseHead $baseHead -TargetTag $TargetTag `
    -TargetSha $targetSha -ExpectedActor $actor `
    -ExpectedState ([string]$plan.State) `
    -ProposalMode ([string]$plan.ProposalMode) `
    -Collisions @($plan.Collisions) -TargetPaths $targetPaths `
    -SourcePath $sourcePath
if (-not $publishedProposalValid -or
    $publishedPullRequests.Count -ne 1 -or
    [string]$publishedPullRequests[0].url -cne $url) {
    throw 'The created adoption proposal failed exact post-publication validation.'
}
Add-RunSummary "- Draft proposal: $url"
Write-Host "Created $($plan.State) draft: $url"
