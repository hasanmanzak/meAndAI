[CmdletBinding()]
param(
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolPath = '.ai/protocol',
    [string]$ProtocolSourcePath = '.meandai-update-source',
    [string]$TargetTag = 'v0.10.4',
    [string]$BranchPrefix = 'automation/meandai-capabilities-',
    [switch]$ValidateLocalUpdaterOnly
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
$LocalUpdaterAssets = @($AdoptionAssets | Where-Object {
    [string]$_.ConsumerPath -cin @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    )
})
$ManifestPath = '.ai/adoption/meandai-capabilities.json'
$ConsumerMigrationModulePath = 'scripts/MeAndAI.ConsumerMigrations.psm1'
$ConsumerMigrationIndexPath = 'migrations/index.json'
$ConsumerMigrationLedgerPath = '.ai/meandai-update-state.json'

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

function Assert-ContainedManagedDestination {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath
    )

    if ([IO.Path]::IsPathRooted($RelativePath)) {
        throw "Managed destination '$RelativePath' must be relative to the repository root."
    }
    $segments = @($RelativePath -split '[\\/]')
    if ($segments.Count -eq 0 -or
        @($segments | Where-Object { $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..' }).Count -gt 0) {
        throw "Managed destination '$RelativePath' is not a canonical repository-relative path."
    }

    $rootPath = [IO.Path]::GetFullPath($Root)
    $relativePlatformPath = $segments -join [IO.Path]::DirectorySeparatorChar
    $destination = [IO.Path]::GetFullPath((Join-Path $rootPath $relativePlatformPath))
    $comparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        [StringComparison]::OrdinalIgnoreCase
    }
    else { [StringComparison]::Ordinal }
    $rootPrefix = if ($rootPath.EndsWith([string][IO.Path]::DirectorySeparatorChar) -or
        $rootPath.EndsWith([string][IO.Path]::AltDirectorySeparatorChar)) {
        $rootPath
    }
    else { $rootPath + [IO.Path]::DirectorySeparatorChar }
    if (-not $destination.StartsWith($rootPrefix, $comparison)) {
        throw "Managed destination '$RelativePath' escapes the repository root."
    }

    $current = $rootPath
    for ($index = 0; $index -lt $segments.Count; $index++) {
        $current = Join-Path $current $segments[$index]
        try {
            $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            continue
        }
        catch {
            throw "Managed destination '$RelativePath' could not be inspected safely: $($_.Exception.Message)"
        }

        $linkTypeProperty = $item.PSObject.Properties['LinkType']
        $isLink = $null -ne $linkTypeProperty -and
            -not [string]::IsNullOrEmpty([string]$linkTypeProperty.Value)
        $isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if ($isLink -or $isReparsePoint) {
            $component = @($segments[0..$index]) -join '/'
            throw "Managed destination '$RelativePath' traverses linked or reparse-point path '$component'."
        }
        if ($index -lt ($segments.Count - 1) -and -not $item.PSIsContainer) {
            $component = @($segments[0..$index]) -join '/'
            throw "Managed destination '$RelativePath' traverses non-directory path '$component'."
        }
    }

    return $destination
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

function Get-WorkingTreeBlobSha {
    param(
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$Path
    )

    $sha = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $RepositoryPath, 'hash-object', '--no-filters', '--', $Path
    )) -join '').Trim()
    if ($sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Unable to resolve the working-tree blob for '$Path'."
    }
    return $sha
}

function Import-PinnedConsumerMigrationBaseline {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$TargetSha
    )

    $moduleEntry = Get-TreeEntry -RepositoryPath $SourcePath `
        -Commit $TargetSha -Path $ConsumerMigrationModulePath
    $indexEntry = Get-TreeEntry -RepositoryPath $SourcePath `
        -Commit $TargetSha -Path $ConsumerMigrationIndexPath
    if ($moduleEntry.Mode -cne '100644' -or $moduleEntry.Type -cne 'blob') {
        throw "Pinned release is missing consumer migration module '$ConsumerMigrationModulePath'."
    }
    if ($indexEntry.Mode -cne '100644' -or $indexEntry.Type -cne 'blob') {
        throw "Pinned release is missing consumer migration catalog '$ConsumerMigrationIndexPath'."
    }
    if ((Get-WorkingTreeBlobSha -RepositoryPath $SourcePath `
        -Path $ConsumerMigrationModulePath) -cne $moduleEntry.Sha -or
        (Get-WorkingTreeBlobSha -RepositoryPath $SourcePath `
        -Path $ConsumerMigrationIndexPath) -cne $indexEntry.Sha) {
        throw 'Pinned consumer migration module or catalog differs from the immutable target release.'
    }

    $moduleFile = Join-Path $SourcePath `
        ($ConsumerMigrationModulePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $indexFile = Join-Path $SourcePath `
        ($ConsumerMigrationIndexPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $module = @(Import-Module $moduleFile -Force -PassThru)
    if ($module.Count -ne 1) {
        throw 'Pinned consumer migration module could not be imported exactly once.'
    }
    $importCatalog = $module[0].ExportedCommands['Import-MeAndAIConsumerMigrationCatalog']
    $newBaseline = $module[0].ExportedCommands['New-MeAndAIConsumerMigrationBaseline']
    if ($null -eq $importCatalog -or $null -eq $newBaseline) {
        throw 'Pinned consumer migration module does not expose the required adoption contract.'
    }

    $catalog = & $importCatalog -IndexPath $indexFile
    if ([string]$catalog.IndexBlob -cne [string]$indexEntry.Sha) {
        throw 'Pinned consumer migration catalog differs from the immutable target release.'
    }
    foreach ($migration in @($catalog.Migrations)) {
        $definitionPath = "migrations/$([string]$migration.Definition)"
        $definitionEntry = Get-TreeEntry -RepositoryPath $SourcePath `
            -Commit $TargetSha -Path $definitionPath
        if ($definitionEntry.Mode -cne '100644' -or
            $definitionEntry.Type -cne 'blob' -or
            [string]$definitionEntry.Sha -cne [string]$migration.DefinitionBlob -or
            (Get-WorkingTreeBlobSha -RepositoryPath $SourcePath `
                -Path $definitionPath) -cne [string]$definitionEntry.Sha) {
            throw "Pinned consumer migration definition '$definitionPath' differs from the immutable target release."
        }
    }

    $baseline = & $newBaseline -Catalog $catalog
    if ([string]$baseline.Path -cne $ConsumerMigrationLedgerPath -or
        $baseline.Bytes -isnot [byte[]] -or
        [string]$baseline.Blob -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Pinned consumer migration module produced an invalid adoption baseline.'
    }
    return $baseline
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
        [string]$SourcePath,
        [Parameter(Mandatory)]$MigrationBaseline,
        [switch]$SkipRemoteFetch
    )

    if (-not $SkipRemoteFetch) {
        Invoke-Native -Command 'git' -Arguments @(
            'fetch', '--no-tags', 'origin', "refs/heads/$Branch"
        ) | Out-Null
        $fetchedHead = ((Invoke-Native -Command 'git' -Arguments @(
            'rev-parse', 'FETCH_HEAD'
        )) -join '').Trim()
        if ($fetchedHead -cne $RemoteHead) {
            return $false
        }
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
        }) + @([string]$MigrationBaseline.Path, $ManifestPath)
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
        $ledgerEntry = Get-TreeEntry -RepositoryPath $env:GITHUB_WORKSPACE `
            -Commit $RemoteHead -Path ([string]$MigrationBaseline.Path)
        if ($ledgerEntry.Mode -cne '100644' -or
            $ledgerEntry.Type -cne 'blob' -or
            $ledgerEntry.Sha -cne [string]$MigrationBaseline.Blob) {
            return $false
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
    return Test-MeAndAIExactAdoptionManifest -Manifest $manifest `
        -Repository $Repository -TargetTag $TargetTag -ProtocolSha $TargetSha `
        -ExpectedState $ExpectedState -ExpectedCollisions @($Collisions)
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
        [string]$SourcePath,
        [Parameter(Mandatory)]$MigrationBaseline
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
        -SourcePath $SourcePath -MigrationBaseline $MigrationBaseline)) {
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
        [string]$BaseHead,
        [string]$TargetTag,
        [string]$TargetSha,
        [string]$ExpectedActor,
        [string]$ExpectedState,
        [string]$ProposalMode,
        [string[]]$Collisions,
        [string[]]$TargetPaths,
        [string]$SourcePath,
        [Parameter(Mandatory)]$MigrationBaseline
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

    $ancestry = (((Invoke-Native -Command 'git' -Arguments @(
        'rev-list', '--parents', '-n', '1', $RemoteHead
    )) -join '').Trim() -split '\s+')
    if ($ancestry.Count -ne 2 -or $ancestry[0] -cne $RemoteHead -or
        $ancestry[1] -cnotmatch '^[0-9a-f]{40}$') {
        return $false
    }
    $proposalHead = [string]$ancestry[1]
    if (-not (Test-ExactAdoptionTree -RemoteHead $proposalHead -Branch $Branch `
        -BaseHead $BaseHead -TargetSha $TargetSha -ProposalMode $ProposalMode `
        -SourcePath $SourcePath -MigrationBaseline $MigrationBaseline `
        -SkipRemoteFetch)) {
        return $false
    }
    if (-not (Test-ExactAdoptionManifest -RemoteHead $proposalHead `
        -Repository $Repository -TargetTag $TargetTag -TargetSha $TargetSha `
        -ExpectedState $ExpectedState -Collisions $Collisions `
        -TargetPaths $TargetPaths)) {
        return $false
    }

    Invoke-Native -Command 'git' -Arguments @(
        'diff', '--check', $proposalHead, $RemoteHead, '--'
    ) | Out-Null
    $completedChangedPaths = @(Invoke-Native -Command 'git' -Arguments @(
        'diff', '--no-renames', '--name-only', '--diff-filter=ACMRTD',
        $proposalHead, $RemoteHead, '--'
    ) | ForEach-Object { [string]$_ })
    if ($completedChangedPaths.Count -eq 0) {
        return $false
    }
    $protectedPaths = @([string]$SeedWorkflow.ConsumerPath) + @(
        [string]$MigrationBaseline.Path, 'FG_PAT.txt', 'MEANDAI_RO_FG_PAT.txt'
    )
    if (@($protectedPaths | Where-Object {
        $completedChangedPaths -ccontains $_
    }).Count -gt 0 -or
        @($completedChangedPaths | Where-Object {
            $_ -clike "$ProtocolPath/*"
        }).Count -gt 0) {
        return $false
    }

    $manifestEntry = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path $ManifestPath
    $protocolEntry = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path $ProtocolPath
    $completedSeed = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path ([string]$SeedWorkflow.ConsumerPath)
    $completedLedger = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $RemoteHead -Path ([string]$MigrationBaseline.Path)
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
        $completedSeed.Sha -cne $sourceSeed.Sha -or
        $completedLedger.Mode -cne '100644' -or
        $completedLedger.Type -cne 'blob' -or
        $completedLedger.Sha -cne [string]$MigrationBaseline.Blob) {
        return $false
    }

    foreach ($credentialPath in @('FG_PAT.txt', 'MEANDAI_RO_FG_PAT.txt')) {
        $credentialEntry = Get-TreeEntry -RepositoryPath $workspace `
            -Commit $RemoteHead -Path $credentialPath
        if ($credentialEntry.Path) {
            return $false
        }
    }
    try {
        $gitmodulesBlob = "${RemoteHead}:.gitmodules"
        $protocolModulePath = @(Invoke-Native -Command 'git' -Arguments @(
            'config', '--blob', $gitmodulesBlob, '--get-all',
            "submodule.${ProtocolPath}.path"
        ) | ForEach-Object { [string]$_ })
        $protocolModuleUrl = @(Invoke-Native -Command 'git' -Arguments @(
            'config', '--blob', $gitmodulesBlob, '--get-all',
            "submodule.${ProtocolPath}.url"
        ) | ForEach-Object { [string]$_ })
        $protocolModuleEntries = @(Invoke-Native -Command 'git' -Arguments @(
            'config', '--blob', $gitmodulesBlob, '--get-regexp',
            ('^' + [regex]::Escape("submodule.$ProtocolPath."))
        ) | ForEach-Object { [string]$_ })
    }
    catch {
        return $false
    }
    if ($protocolModulePath.Count -ne 1 -or
        $protocolModulePath[0] -cne $ProtocolPath -or
        $protocolModuleUrl.Count -ne 1 -or
        $protocolModuleUrl[0] -cne "https://github.com/$ProtocolRepository.git" -or
        $protocolModuleEntries.Count -ne 2) {
        return $false
    }

    if ($LocalUpdaterAssets.Count -ne 2) {
        return $false
    }
    foreach ($asset in $LocalUpdaterAssets) {
        $sourceEntry = Get-TreeEntry -RepositoryPath $SourcePath `
            -Commit $TargetSha -Path ([string]$asset.TemplatePath)
        $completedEntry = Get-TreeEntry -RepositoryPath $workspace `
            -Commit $RemoteHead -Path ([string]$asset.ConsumerPath)
        if ($sourceEntry.Mode -cne '100644' -or
            $sourceEntry.Type -cne 'blob' -or
            $completedEntry.Mode -cne $sourceEntry.Mode -or
            $completedEntry.Type -cne $sourceEntry.Type -or
            $completedEntry.Sha -cne $sourceEntry.Sha) {
            return $false
        }
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
        [string]$TargetSha,
        [Parameter(Mandatory)]$MigrationBaseline
    )

    Invoke-Native -Command 'git' -Arguments @(
        'diff', '--cached', '--check'
    ) | Out-Null
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
    $ledgerEntry = Get-StagedEntry -Path ([string]$MigrationBaseline.Path)
    if ($ledgerEntry.Mode -cne '100644' -or
        $ledgerEntry.Sha -cne [string]$MigrationBaseline.Blob) {
        throw 'Staged consumer migration ledger does not match the pinned release baseline.'
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
$RequiredTasks = @(Get-MeAndAIRequiredAdoptionTasks)
$targetPaths = @(Get-MeAndAIAdoptionTargetPaths)
$proposedPaths = @(Get-MeAndAIAdoptionProposedPaths)
$mappedTargetPaths = @(
    '.gitmodules', $ProtocolPath, $ConsumerMigrationLedgerPath
) + @($AdoptionAssets | ForEach-Object {
    [string]$_.ConsumerPath
})
if (-not (Test-ExactOrdinalSequence -Actual $mappedTargetPaths -Expected $targetPaths) -or
    -not (Test-ExactOrdinalSequence `
        -Actual (@([string]$SeedWorkflow.ConsumerPath) + @($targetPaths)) `
        -Expected $proposedPaths)) {
    throw 'Bootstrap asset mapping does not match the canonical capabilities path contract.'
}
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
$migrationBaseline = Import-PinnedConsumerMigrationBaseline `
    -SourcePath $sourcePath -TargetSha $targetSha
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

$collisions = [System.Collections.Generic.List[string]]::new()
foreach ($path in $targetPaths) {
    if ($basePathLookup.ContainsKey($path)) {
        $collisions.Add([string]$basePathLookup[$path])
    }
}
$manifestExists = $basePathLookup.ContainsKey($ManifestPath)
$updaterPaths = @($LocalUpdaterAssets | ForEach-Object { [string]$_.ConsumerPath })
$updaterCount = @($updaterPaths | Where-Object {
    $basePathLookup.ContainsKey($_)
}).Count
$localUpdaterState = if ($updaterCount -eq 0) { 'Absent' }
elseif ($updaterCount -eq $updaterPaths.Count) { 'Complete' }
else { 'Partial' }

if ($ValidateLocalUpdaterOnly) {
    if ($seedWorkflowState -cne 'Exact') {
        throw "The committed seed workflow does not match '$TargetTag'; local updater validation failed."
    }
    if ($manifestExists) {
        throw 'The transient adoption manifest exists; local updater validation failed.'
    }
    $protocolEntry = Get-TreeEntry -RepositoryPath $workspace `
        -Commit $baseHead -Path $ProtocolPath
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cne $targetSha) {
        throw "The committed protocol gitlink does not match '$TargetTag'; local updater validation failed."
    }
    if ($LocalUpdaterAssets.Count -ne 2 -or $localUpdaterState -cne 'Complete') {
        throw 'The committed local updater inventory does not match the pinned release.'
    }
    foreach ($asset in $LocalUpdaterAssets) {
        $sourceEntry = Get-TreeEntry -RepositoryPath $sourcePath `
            -Commit $targetSha -Path ([string]$asset.TemplatePath)
        $consumerEntry = Get-TreeEntry -RepositoryPath $workspace `
            -Commit $baseHead -Path ([string]$asset.ConsumerPath)
        $workingPath = Join-Path $workspace `
            (([string]$asset.ConsumerPath) -replace '/', [IO.Path]::DirectorySeparatorChar)
        if ($sourceEntry.Mode -cne '100644' -or
            $sourceEntry.Type -cne 'blob' -or
            $consumerEntry.Mode -cne $sourceEntry.Mode -or
            $consumerEntry.Type -cne $sourceEntry.Type -or
            $consumerEntry.Sha -cne $sourceEntry.Sha -or
            -not (Test-Path -LiteralPath $workingPath -PathType Leaf)) {
            throw "The local updater asset '$($asset.ConsumerPath)' does not match the pinned release."
        }
        $workingSha = ((Invoke-Native -Command 'git' -Arguments @(
            'hash-object', '--', [string]$asset.ConsumerPath
        )) -join '').Trim()
        if ($workingSha -cne $sourceEntry.Sha) {
            throw "The local updater asset '$($asset.ConsumerPath)' does not match the pinned release."
        }
    }
    Write-Host "Validated the exact local updater against immutable release '$TargetTag'."
    return
}

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
        -Collisions @($collisions) -TargetPaths $targetPaths `
        -SourcePath $sourcePath -MigrationBaseline $migrationBaseline
    if ($proposedValid) {
        $true
    }
    else {
        Test-ExactCompletedAdoptionProposal -PullRequests $pullRequests `
            -RemoteHead $remoteBranchHead -Repository $env:GITHUB_REPOSITORY `
            -Branch $branch -BaseBranch $env:DEFAULT_BRANCH -BaseHead $baseHead `
            -TargetTag $TargetTag -TargetSha $targetSha -ExpectedActor $actor `
            -ExpectedState ([string]$proposalContract.State) `
            -ProposalMode ([string]$proposalContract.ProposalMode) `
            -Collisions @($collisions) -TargetPaths $targetPaths `
            -SourcePath $sourcePath -MigrationBaseline $migrationBaseline
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

$managedWritePaths = if ([string]$plan.ProposalMode -ceq 'Full') {
    @($targetPaths) + @($ManifestPath)
}
elseif ([string]$plan.ProposalMode -ceq 'ManifestOnly') {
    @($ManifestPath)
}
else {
    throw "Unsupported adoption proposal mode '$($plan.ProposalMode)'."
}
foreach ($managedWritePath in $managedWritePaths) {
    [void](Assert-ContainedManagedDestination `
        -Root $workspace -RelativePath ([string]$managedWritePath))
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
    $ledgerFile = Join-Path $workspace `
        (([string]$migrationBaseline.Path) -replace '/', [IO.Path]::DirectorySeparatorChar)
    $ledgerParent = Split-Path -Parent $ledgerFile
    New-Item -ItemType Directory -Force $ledgerParent | Out-Null
    [IO.File]::WriteAllBytes($ledgerFile, [byte[]]$migrationBaseline.Bytes)
    $stagedPaths.Add([string]$migrationBaseline.Path)
}

$manifest = [ordered]@{
    schema = 1
    operation = 'ai-capabilities-adoption'
    state = [string]$plan.State
    repository = [string]$env:GITHUB_REPOSITORY
    targetTag = $TargetTag
    protocolSha = $targetSha
    collisions = @($plan.Collisions)
    proposedPaths = $proposedPaths
    requiredTasks = $RequiredTasks
}
$manifestText = ($manifest | ConvertTo-Json -Depth 5 -Compress) + "`n"
Write-Utf8NoBom -Path (Join-Path $workspace $ManifestPath) -Content $manifestText
$stagedPaths.Add($ManifestPath)

$addPaths = @($stagedPaths | Where-Object { $_ -cne $ProtocolPath })
Invoke-Native -Command 'git' -Arguments (@('add', '--') + $addPaths) | Out-Null
Assert-StagedProposal -ExpectedPaths @($stagedPaths) `
    -ProposalMode ([string]$plan.ProposalMode) `
    -SourcePath $sourcePath -TargetSha $targetSha `
    -MigrationBaseline $migrationBaseline

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
    -SourcePath $sourcePath -MigrationBaseline $migrationBaseline
if (-not $publishedProposalValid -or
    $publishedPullRequests.Count -ne 1 -or
    [string]$publishedPullRequests[0].url -cne $url) {
    throw 'The created adoption proposal failed exact post-publication validation.'
}
Add-RunSummary "- Draft proposal: $url"
Write-Host "Created $($plan.State) draft: $url"
